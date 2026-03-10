package handlers

import (
	"crypto/rand"
	"crypto/subtle"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"log"
	"net/http"
	"os"
	"regexp"
	"strings"

	"github.com/agentyk/agentyk/internal/btcpay"
	"github.com/agentyk/agentyk/internal/config"
	"github.com/agentyk/agentyk/internal/db"
	"github.com/agentyk/agentyk/internal/mailops"
	"github.com/agentyk/agentyk/internal/notify"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

var usernameRe = regexp.MustCompile(`^[a-z0-9](?:[a-z0-9._-]*[a-z0-9])?$`)

func validUsername(u string) bool {
	return len(u) >= 3 && len(u) <= 32 && usernameRe.MatchString(u) &&
		!strings.Contains(u, "..") && !strings.Contains(u, "--") && !strings.Contains(u, "__")
}

type RegisterReq struct {
	Username string `json:"username" binding:"required"`
}

func Register(btcClient *btcpay.Client) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req RegisterReq
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "username is required"})
			return
		}

		username := strings.ToLower(strings.TrimSpace(req.Username))
		if !validUsername(username) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "username must be 3-32 chars, lowercase alphanumeric/dots/hyphens, no consecutive special chars"})
			return
		}

		exists, err := db.UsernameExists(c.Request.Context(), username)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "database error"})
			return
		}
		if exists {
			c.JSON(http.StatusConflict, gin.H{"error": "registration failed, please try a different username"})
			return
		}

		domain := config.Domain()
		email := username + "@" + domain

		tempPassword, err := generatePassword(16)
		if err != nil {
			log.Printf("CRITICAL: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal error"})
			return
		}
		passwordHashStr, err := hashPassword(tempPassword)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal error"})
			return
		}
		apiKey := uuid.New().String()
		seedPhrase, err := generateSeedPhrase()
		if err != nil {
			log.Printf("CRITICAL: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal error"})
			return
		}
		seedHashStr, err := hashPassword(seedPhrase)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal error"})
			return
		}

		amountEUR := 60.0
		var invoiceID, checkoutURL, amountBTC string

		if btcClient.IsConfigured() {
			redirectURL := fmt.Sprintf("https://%s/register/status-page/{InvoiceId}", config.Domain())
			inv, err := btcClient.CreateInvoice(username, email, amountEUR, redirectURL)
			if err != nil {
				// BTCPay failed — fall back to static wallet mode
				_ = notify.TelegramAdmin(fmt.Sprintf("BTCPay down, fallback for %s: %v", email, err))
				invoiceID = "inv_" + uuid.New().String()
			} else {
				invoiceID = inv.ID
				checkoutURL = inv.CheckoutURL
				amountBTC = inv.Amount
			}
		} else {
			invoiceID = "inv_" + uuid.New().String()
		}

		account, err := db.CreateAccount(c.Request.Context(), username, email, passwordHashStr, apiKey, invoiceID)
		if err != nil {
			if strings.Contains(err.Error(), "unique") || strings.Contains(err.Error(), "duplicate") {
				c.JSON(http.StatusConflict, gin.H{"error": "username or email already exists"})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create account"})
			return
		}

		// Store recovery seed hash
		if err := db.SetRecoverySeedHash(c.Request.Context(), account.ID, seedHashStr); err != nil {
			log.Printf("WARNING: failed to store recovery seed hash for account %d: %v", account.ID, err)
		}

		// Create mailbox in Stalwart before payment record — avoids orphaned payments on failure
		if err := mailops.CreateMailbox(email, tempPassword); err != nil {
			_ = notify.TelegramAdmin(fmt.Sprintf("Stalwart mailbox creation failed for %s: %v", email, err))
			log.Printf("CRITICAL: mailbox creation failed for %s: %v", email, err)
			// Roll back: delete orphaned account from DB
			if delErr := db.DeleteAccount(c.Request.Context(), account.ID); delErr != nil {
				log.Printf("CRITICAL: failed to rollback account %d after mailbox failure: %v", account.ID, delErr)
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": "mail server unavailable, please try again later"})
			return
		}

		if err := db.CreatePayment(c.Request.Context(), account.ID, invoiceID, amountEUR, amountBTC, checkoutURL); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create payment record"})
			return
		}

		db.LogAudit(c.Request.Context(), &account.ID, db.AuditAccountCreated, c.ClientIP(), email)
		_ = notify.TelegramAdmin(fmt.Sprintf("New registration: %s (%s) — invoice %s", username, email, invoiceID))

		btcWallet := os.Getenv("BTC_WALLET")
		if btcWallet == "" {
			log.Printf("WARNING: BTC_WALLET env var not set, payment page will not show wallet address")
		}

		// Generate BIP21 QR code for terminal display
		btcURI := "bitcoin:" + btcWallet + "?amount=" + amountBTC
		qrText, _ := GenerateUnicodeQR(btcURI)

		c.JSON(http.StatusOK, gin.H{
			"email":          email,
			"temp_password":  tempPassword,
			"api_key":        apiKey,
			"recovery_seed":  seedPhrase,
			"invoice_id":     invoiceID,
			"btcpay_url":     checkoutURL,
			"amount_eur":     amountEUR,
			"amount_btc":     amountBTC,
			"btc_wallet":     btcWallet,
			"btc_uri":        btcURI,
			"qr_code":        qrText,
			"status":         "pending_payment",
		})
	}
}

type RedeemReq struct {
	InvoiceID string `json:"invoice_id" binding:"required"`
	Coupon    string `json:"coupon" binding:"required"`
}

func RedeemCoupon(c *gin.Context) {
	var req RedeemReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invoice_id and coupon are required"})
		return
	}

	code := strings.TrimSpace(req.Coupon)
	if code == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "coupon code is required"})
		return
	}

	coupon, err := db.ValidateCoupon(c.Request.Context(), code)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid or already used coupon"})
		return
	}

	account, err := db.GetAccountByInvoice(c.Request.Context(), req.InvoiceID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "invoice not found"})
		return
	}

	if account.Status == "active" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "account already active"})
		return
	}

	if err := db.RedeemCouponAtomic(c.Request.Context(), coupon.ID, account.ID, coupon.DurationDays, req.InvoiceID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to redeem coupon"})
		return
	}

	db.LogAudit(c.Request.Context(), &account.ID, db.AuditCouponRedeemed, c.ClientIP(), fmt.Sprintf("coupon %s (%dd)", code, coupon.DurationDays))
	_ = notify.TelegramAdmin(fmt.Sprintf("Coupon redeemed: %s used coupon %s (%dd) for %s",
		account.Email, code, coupon.DurationDays, req.InvoiceID))

	c.JSON(http.StatusOK, gin.H{
		"status":  "active",
		"email":   account.Email,
		"expires": fmt.Sprintf("%d days", coupon.DurationDays),
		"message": "Account activated successfully",
	})
}

func RegisterStatus(c *gin.Context) {
	invoiceID := c.Param("invoice_id")
	if invoiceID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invoice_id required"})
		return
	}

	// Reject obviously invalid invoice IDs to reduce enumeration surface
	if len(invoiceID) < 10 {
		c.JSON(http.StatusNotFound, gin.H{"error": "invoice not found"})
		return
	}

	account, err := db.GetAccountByInvoice(c.Request.Context(), invoiceID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "invoice not found"})
		return
	}

	// Only return payment status — no account details
	c.JSON(http.StatusOK, gin.H{
		"status":      account.Status,
		"login_ready": account.Status == "active",
	})
}

func GenerateCoupon(c *gin.Context) {
	secret := os.Getenv("COUPON_SECRET")
	key := c.GetHeader("X-Coupon-Key")
	if secret == "" || key == "" || subtle.ConstantTimeCompare([]byte(key), []byte(secret)) != 1 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid key"})
		return
	}

	days := 365
	rb1, err1 := randomBytes(2)
	rb2, err2 := randomBytes(2)
	rb3, err3 := randomBytes(2)
	if err1 != nil || err2 != nil || err3 != nil {
		log.Printf("CRITICAL: crypto/rand failure in coupon generation")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal error"})
		return
	}
	code := fmt.Sprintf("AYK-%s-%s-%s",
		strings.ToUpper(hex.EncodeToString(rb1)),
		strings.ToUpper(hex.EncodeToString(rb2)),
		strings.ToUpper(hex.EncodeToString(rb3)))

	if err := db.CreateCoupon(c.Request.Context(), code, "father", days); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create coupon"})
		return
	}

	_ = notify.TelegramAdmin(fmt.Sprintf("Coupon generated: %s (%d days)", code, days))

	c.JSON(http.StatusOK, gin.H{
		"coupon":   code,
		"days":     days,
		"message":  "Coupon ready to use at agentyk.ru",
	})
}

// seedWords is a compact wordlist for recovery phrases
var seedWords = []string{
	"alpha", "amber", "angel", "anvil", "arena", "atlas", "blade", "blaze",
	"brick", "brook", "cedar", "chain", "chase", "chief", "cloud", "cobra",
	"coral", "crane", "crown", "dance", "delta", "dense", "depth", "drift",
	"eagle", "ember", "epoch", "exile", "fable", "faith", "flame", "fleet",
	"forge", "frost", "ghost", "globe", "grace", "grain", "guard", "haven",
	"honor", "ivory", "jewel", "karma", "lance", "laser", "lunar", "maple",
	"marsh", "medal", "mercy", "nerve", "nexus", "noble", "ocean", "onset",
	"orbit", "panel", "pearl", "phase", "pilot", "pixel", "plant", "plume",
	"polar", "prism", "pulse", "quake", "quest", "radar", "reign", "ridge",
	"rival", "rover", "royal", "saint", "scale", "shade", "sharp", "shell",
	"sigma", "silk", "solar", "spark", "spike", "spine", "spoke", "steel",
	"stern", "stone", "storm", "surge", "swift", "thorn", "tiger", "token",
	"torch", "tower", "trace", "trend", "tribe", "truce", "ultra", "unity",
	"vapor", "vault", "vigor", "vivid", "watch", "whale", "wheat", "winds",
	"world", "wrath", "youth", "zebra", "zero", "zone", "bliss", "brisk",
	"cache", "cliff", "dwarf", "flint", "frame", "glyph", "knack", "plank",
}

func generateSeedPhrase() (string, error) {
	words := make([]string, 12)
	wordCount := len(seedWords)
	for i := range words {
		// Use 4 bytes for uniform distribution via rejection sampling
		for {
			b := make([]byte, 4)
			if _, err := rand.Read(b); err != nil {
				return "", fmt.Errorf("crypto/rand unavailable: %w", err)
			}
			val := uint32(b[0])<<24 | uint32(b[1])<<16 | uint32(b[2])<<8 | uint32(b[3])
			// Reject values that would cause modulo bias
			limit := uint32(0xFFFFFFFF) - uint32(0xFFFFFFFF)%uint32(wordCount)
			if val < limit {
				words[i] = seedWords[val%uint32(wordCount)]
				break
			}
		}
	}
	return strings.Join(words, " "), nil
}

func randomBytes(n int) ([]byte, error) {
	b := make([]byte, n)
	if _, err := rand.Read(b); err != nil {
		return nil, fmt.Errorf("crypto/rand unavailable: %w", err)
	}
	return b, nil
}

func generatePassword(length int) (string, error) {
	b := make([]byte, length)
	if _, err := rand.Read(b); err != nil {
		return "", fmt.Errorf("crypto/rand unavailable: %w", err)
	}
	s := base64.URLEncoding.EncodeToString(b)
	return s[:length], nil
}

// hashPassword creates a bcrypt hash for new passwords.
func hashPassword(password string) (string, error) {
	h, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		log.Printf("CRITICAL: bcrypt hash failed: %v", err)
		return "", fmt.Errorf("bcrypt hash generation failed: %w", err)
	}
	return string(h), nil
}
