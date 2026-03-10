package handlers

import (
	"crypto/rand"
	"crypto/sha512"
	"crypto/subtle"
	"encoding/hex"
	"fmt"
	"log"
	"net"
	"net/http"
	"net/smtp"
	"os"
	"regexp"
	"strings"
	"time"

	"github.com/agentyk/agentyk/internal/btcpay"
	"github.com/agentyk/agentyk/internal/config"
	"github.com/agentyk/agentyk/internal/db"
	"github.com/agentyk/agentyk/internal/mailops"
	"github.com/agentyk/agentyk/internal/notify"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

var emailRe = regexp.MustCompile(`^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$`)

func PageLogin(c *gin.Context) {
	domain := config.Domain()
	c.Header("Content-Type", "text/html; charset=utf-8")
	if err := templates.ExecuteTemplate(c.Writer, "login.html", map[string]string{
		"domain": domain,
	}); err != nil {
		log.Printf("template error: %v", err)
	}
}

type LoginReq struct {
	Email    string `json:"email" binding:"required"`
	Password string `json:"password" binding:"required"`
}

func Login(c *gin.Context) {
	var req LoginReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "email and password are required"})
		return
	}

	account, err := authenticateLogin(c, req.Email, req.Password)
	if err != nil {
		return // already sent error response
	}

	expiresAt := ""
	if account.ExpiresAt != nil {
		expiresAt = account.ExpiresAt.Format("2006-01-02")
	}

	recoveryEmail := ""
	if account.RecoveryEmail != nil {
		recoveryEmail = *account.RecoveryEmail
	}
	forwardEmail := ""
	if account.ForwardEmail != nil {
		forwardEmail = *account.ForwardEmail
	}

	c.JSON(http.StatusOK, gin.H{
		"email":          account.Email,
		"username":       account.Username,
		"status":         account.Status,
		"api_key":        account.APIKey,
		"expires_at":     expiresAt,
		"quota_used":     account.QuotaUsed,
		"recovery_email": recoveryEmail,
		"forward_email":  forwardEmail,
	})
}

// authenticateLogin validates email+password and returns the account, or sends an error response.
// Enforces per-account lockout after 10 failed attempts (30-minute lock).
func authenticateLogin(c *gin.Context, rawEmail, password string) (*db.Account, error) {
	email := strings.ToLower(strings.TrimSpace(rawEmail))
	domain := config.Domain()
	if !strings.Contains(email, "@") {
		email = email + "@" + domain
	}
	ip := c.ClientIP()

	account, err := db.GetAccountByEmail(c.Request.Context(), email)
	if err != nil {
		db.LogAudit(c.Request.Context(), nil, db.AuditLoginFailed, ip, fmt.Sprintf("unknown email: %s", email))
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid credentials"})
		return nil, err
	}

	// Check lockout — fail closed on DB error
	locked, lockedUntil, lockErr := db.IsAccountLocked(c.Request.Context(), account.ID)
	if lockErr != nil {
		log.Printf("ERROR: lockout check failed for account %d: %v", account.ID, lockErr)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal error"})
		return nil, lockErr
	}
	if locked {
		db.LogAudit(c.Request.Context(), &account.ID, db.AuditLoginFailed, ip, fmt.Sprintf("account locked until %s", lockedUntil.Format(time.RFC3339)))
		c.JSON(http.StatusTooManyRequests, gin.H{"error": "account temporarily locked due to too many failed login attempts", "locked_until": lockedUntil.Format(time.RFC3339)})
		return nil, fmt.Errorf("account locked")
	}

	if !verifySha512(password, account.PasswordHash) {
		nowLocked, _ := db.IncrementFailedLogins(c.Request.Context(), account.ID)
		if nowLocked {
			db.LogAudit(c.Request.Context(), &account.ID, db.AuditAccountLocked, ip, "locked after 10 failed attempts")
			_ = notify.TelegramAdmin(fmt.Sprintf("Account locked: %s (10 failed login attempts from %s)", email, ip))
		}
		db.LogAudit(c.Request.Context(), &account.ID, db.AuditLoginFailed, ip, "bad password")
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid credentials"})
		return nil, fmt.Errorf("bad password")
	}

	// Success — reset failed attempts counter
	_ = db.ResetFailedLogins(c.Request.Context(), account.ID)
	db.LogAudit(c.Request.Context(), &account.ID, db.AuditLoginSuccess, ip, "")

	return account, nil
}

type LoginChangePasswordReq struct {
	Email       string `json:"email" binding:"required"`
	Password    string `json:"password" binding:"required"`
	NewPassword string `json:"new_password" binding:"required"`
}

func ChangePasswordLogin(c *gin.Context) {
	var req LoginChangePasswordReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "email, password, and new_password are required"})
		return
	}

	if err := validatePassword(req.NewPassword); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	account, err := authenticateLogin(c, req.Email, req.Password)
	if err != nil {
		return
	}

	newHash, err := hashPassword(req.NewPassword)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal error"})
		return
	}
	if err := db.UpdatePassword(c.Request.Context(), account.ID, newHash); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update password"})
		return
	}

	// Sync to Stalwart
	if err := mailops.UpdateMailboxPassword(account.Email, req.NewPassword); err != nil {
		log.Printf("WARNING: Stalwart password sync failed for %s: %v", account.Email, err)
		db.LogAudit(c.Request.Context(), &account.ID, db.AuditPasswordChanged, c.ClientIP(), "via login (mail sync failed)")
		c.JSON(http.StatusOK, gin.H{"message": "password changed but mail server sync failed — please change password again or contact support"})
		return
	}

	db.LogAudit(c.Request.Context(), &account.ID, db.AuditPasswordChanged, c.ClientIP(), "via login")
	c.JSON(http.StatusOK, gin.H{"message": "password changed"})
}

type RecoveryEmailReq struct {
	Email         string `json:"email" binding:"required"`
	Password      string `json:"password" binding:"required"`
	RecoveryEmail string `json:"recovery_email" binding:"required"`
}

func SetRecoveryEmail(c *gin.Context) {
	var req RecoveryEmailReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "email, password, and recovery_email are required"})
		return
	}

	if !emailRe.MatchString(req.RecoveryEmail) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid recovery email format"})
		return
	}

	account, err := authenticateLogin(c, req.Email, req.Password)
	if err != nil {
		return
	}

	if err := db.SetRecoveryEmail(c.Request.Context(), account.ID, req.RecoveryEmail); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to set recovery email"})
		return
	}

	db.LogAudit(c.Request.Context(), &account.ID, db.AuditRecoveryEmailSet, c.ClientIP(), fmt.Sprintf("set to %s", req.RecoveryEmail))
	c.JSON(http.StatusOK, gin.H{"message": "recovery email set", "recovery_email": req.RecoveryEmail})
}

type ForwardEmailReq struct {
	Email        string `json:"email" binding:"required"`
	Password     string `json:"password" binding:"required"`
	ForwardEmail string `json:"forward_email"`
}

func SetForwardEmail(c *gin.Context) {
	var req ForwardEmailReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "email and password are required"})
		return
	}

	account, err := authenticateLogin(c, req.Email, req.Password)
	if err != nil {
		return
	}

	fwd := strings.TrimSpace(req.ForwardEmail)

	if fwd != "" {
		if !emailRe.MatchString(fwd) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid forwarding email format"})
			return
		}

		if err := db.SetForwardEmail(c.Request.Context(), account.ID, &fwd); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to set forwarding"})
			return
		}

		if err := mailops.SetForwardingSieve(account.Email, fwd); err != nil {
			// DB updated but Sieve failed — log but don't fail the request
			_ = notify.TelegramAdmin(fmt.Sprintf("Sieve forwarding failed for %s -> %s: %v", account.Email, fwd, err))
		}

		db.LogAudit(c.Request.Context(), &account.ID, db.AuditForwardEmailSet, c.ClientIP(), fmt.Sprintf("forward to %s", fwd))
		c.JSON(http.StatusOK, gin.H{"message": "forwarding enabled", "forward_email": fwd})
	} else {
		if err := db.SetForwardEmail(c.Request.Context(), account.ID, nil); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to disable forwarding"})
			return
		}

		if err := mailops.SetForwardingSieve(account.Email, ""); err != nil {
			_ = notify.TelegramAdmin(fmt.Sprintf("Sieve forwarding removal failed for %s: %v", account.Email, err))
		}

		db.LogAudit(c.Request.Context(), &account.ID, db.AuditForwardEmailSet, c.ClientIP(), "forwarding disabled")
		c.JSON(http.StatusOK, gin.H{"message": "forwarding disabled", "forward_email": ""})
	}
}

type ExtendReq struct {
	Email    string `json:"email" binding:"required"`
	Password string `json:"password" binding:"required"`
}

func ExtendAccount(btcClient *btcpay.Client) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req ExtendReq
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "email and password are required"})
			return
		}

		account, err := authenticateLogin(c, req.Email, req.Password)
		if err != nil {
			return
		}

		amountEUR := 60.0
		var invoiceID, checkoutURL, amountBTC string

		if btcClient.IsConfigured() {
			redirectURL := fmt.Sprintf("https://%s/login", config.Domain())
			inv, err := btcClient.CreateInvoice(account.Username, account.Email, amountEUR, redirectURL)
			if err != nil {
				invoiceID = "inv_" + uuid.New().String()
			} else {
				invoiceID = inv.ID
				checkoutURL = inv.CheckoutURL
				amountBTC = inv.Amount
			}
		} else {
			invoiceID = "inv_" + uuid.New().String()
		}

		if err := db.CreatePaymentAndUpdateInvoice(c.Request.Context(), account.ID, invoiceID, amountEUR, amountBTC, checkoutURL); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create payment"})
			return
		}

		_ = notify.TelegramAdmin(fmt.Sprintf("Extension request: %s — invoice %s", account.Email, invoiceID))

		btcWallet := os.Getenv("BTC_WALLET")
		if btcWallet == "" {
			log.Printf("WARNING: BTC_WALLET env var not set, payment page will not show wallet address")
		}

		c.JSON(http.StatusOK, gin.H{
			"invoice_id":  invoiceID,
			"btcpay_url":  checkoutURL,
			"amount_eur":  amountEUR,
			"amount_btc":  amountBTC,
			"btc_wallet":  btcWallet,
			"status":      "pending_payment",
		})
	}
}

type ExtendRedeemReq struct {
	Email    string `json:"email" binding:"required"`
	Password string `json:"password" binding:"required"`
	Coupon   string `json:"coupon" binding:"required"`
}

func ExtendRedeem(c *gin.Context) {
	var req ExtendRedeemReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "email, password, and coupon are required"})
		return
	}

	account, err := authenticateLogin(c, req.Email, req.Password)
	if err != nil {
		return
	}

	coupon, err := db.ValidateCoupon(c.Request.Context(), strings.TrimSpace(req.Coupon))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid or already used coupon"})
		return
	}

	if err := db.ExtendWithCouponAtomic(c.Request.Context(), account.ID, coupon.ID, coupon.DurationDays); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to extend account"})
		return
	}

	// Re-enable SMTP if account was expired
	if account.Status == "expired" {
		if err := mailops.RestoreFullAccess(account.Email); err != nil {
			log.Printf("WARNING: Stalwart access restore failed for %s: %v", account.Email, err)
			// Account extended in DB but mail access not restored — user should retry or contact support
		}
	}

	db.LogAudit(c.Request.Context(), &account.ID, db.AuditCouponRedeemed, c.ClientIP(), fmt.Sprintf("extension coupon %s (%dd)", req.Coupon, coupon.DurationDays))
	_ = notify.TelegramAdmin(fmt.Sprintf("Extension coupon: %s used %s (%dd)", account.Email, req.Coupon, coupon.DurationDays))

	// Fetch updated account for new expiry
	updated, _ := db.GetAccountByEmail(c.Request.Context(), account.Email)
	expiresAt := ""
	if updated != nil && updated.ExpiresAt != nil {
		expiresAt = updated.ExpiresAt.Format("2006-01-02")
	}

	c.JSON(http.StatusOK, gin.H{
		"message":    "account extended",
		"status":     "active",
		"expires_at": expiresAt,
	})
}

type DeleteReq struct {
	Email    string `json:"email" binding:"required"`
	Password string `json:"password" binding:"required"`
	Confirm  string `json:"confirm" binding:"required"`
}

func DeleteAccount(c *gin.Context) {
	var req DeleteReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "email, password, and confirm are required"})
		return
	}

	if req.Confirm != "DELETE" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "type DELETE to confirm"})
		return
	}

	account, err := authenticateLogin(c, req.Email, req.Password)
	if err != nil {
		return
	}


	// Audit BEFORE delete so the FK constraint is satisfied
	db.LogAudit(c.Request.Context(), &account.ID, db.AuditAccountDeleted, c.ClientIP(), account.Email)
	if err := db.DeleteAccount(c.Request.Context(), account.ID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to delete account"})
		return
	}

	// Remove mailbox from Stalwart
	if err := mailops.DeleteMailbox(account.Email); err != nil {
		log.Printf("WARNING: Stalwart mailbox deletion failed for %s: %v", account.Email, err)
	}

	_ = notify.TelegramAdmin(fmt.Sprintf("Account deleted: %s (%s)", account.Email, account.Username))

	c.JSON(http.StatusOK, gin.H{"message": "account deleted"})
}

type RequestResetReq struct {
	Email string `json:"email" binding:"required"`
}

func RequestPasswordReset(c *gin.Context) {
	var req RequestResetReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "email is required"})
		return
	}

	email := strings.ToLower(strings.TrimSpace(req.Email))
	domain := config.Domain()
	if !strings.Contains(email, "@") {
		email = email + "@" + domain
	}

	// Always return success to prevent email enumeration
	account, err := db.GetAccountByEmail(c.Request.Context(), email)
	if err != nil || account.RecoveryEmail == nil || *account.RecoveryEmail == "" {
		c.JSON(http.StatusOK, gin.H{"message": "if a recovery email is set, a reset link has been sent"})
		return
	}

	// Generate token
	tokenBytes := make([]byte, 32)
	if _, err := rand.Read(tokenBytes); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal error"})
		return
	}
	token := hex.EncodeToString(tokenBytes)

	expiresAt := time.Now().Add(1 * time.Hour)
	if err := db.CreatePasswordReset(c.Request.Context(), account.ID, token, expiresAt); err != nil {
		c.JSON(http.StatusOK, gin.H{"message": "if a recovery email is set, a reset link has been sent"})
		return
	}

	host := c.Request.Host
	scheme := "https"
	resetURL := fmt.Sprintf("%s://%s/login/reset?token=%s", scheme, host, token)

	// Send reset email via Stalwart SMTP
	go sendResetEmail(*account.RecoveryEmail, account.Email, resetURL)

	_ = notify.TelegramAdmin(fmt.Sprintf("Password reset requested: %s → %s", account.Email, *account.RecoveryEmail))

	c.JSON(http.StatusOK, gin.H{"message": "if a recovery email is set, a reset link has been sent"})
}

func sendResetEmail(to, accountEmail, resetURL string) {
	// Sanitize inputs against SMTP header injection (CRLF + null bytes)
	sanitize := func(s string) string {
		s = strings.ReplaceAll(s, "\r", "")
		s = strings.ReplaceAll(s, "\n", "")
		s = strings.ReplaceAll(s, "\x00", "")
		return s
	}
	to = sanitize(to)
	accountEmail = sanitize(accountEmail)
	resetURL = sanitize(resetURL)

	smtpHost := os.Getenv("SMTP_HOST")
	if smtpHost == "" {
		smtpHost = "stalwart"
	}

	d := config.Domain()
	msg := fmt.Sprintf("From: noreply@%s\r\nTo: %s\r\nSubject: Password Reset - %s\r\n\r\nA password reset was requested for your account: %s\r\n\r\nClick here to reset your password:\r\n%s\r\n\r\nThis link expires in 1 hour.\r\n\r\nIf you did not request this, ignore this email.\r\n",
		d, to, d, accountEmail, resetURL)

	err := smtpSendMail(smtpHost+":25", "noreply@"+d, to, []byte(msg))
	if err != nil {
		_ = notify.TelegramAdmin(fmt.Sprintf("Reset email send failed to %s: %v", to, err))
	}
}

func smtpSendMail(addr, from, to string, msg []byte) error {
	conn, err := net.Dial("tcp", addr)
	if err != nil {
		return err
	}
	defer conn.Close()

	c, err := smtp.NewClient(conn, config.Domain())
	if err != nil {
		return err
	}
	defer c.Close()

	if err := c.Mail(from); err != nil {
		return err
	}
	if err := c.Rcpt(to); err != nil {
		return err
	}
	w, err := c.Data()
	if err != nil {
		return err
	}
	_, err = w.Write(msg)
	if err != nil {
		return err
	}
	if err := w.Close(); err != nil {
		return err
	}
	return c.Quit()
}

type ResetPasswordReq struct {
	Token       string `json:"token" binding:"required"`
	NewPassword string `json:"new_password" binding:"required"`
}

func ResetPassword(c *gin.Context) {
	var req ResetPasswordReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "token and new_password are required"})
		return
	}

	if err := validatePassword(req.NewPassword); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	account, err := db.ValidateResetToken(c.Request.Context(), req.Token)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid or expired reset token"})
		return
	}

	newHash, err := hashPassword(req.NewPassword)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal error"})
		return
	}
	if err := db.ResetPasswordAtomic(c.Request.Context(), account.ID, newHash, req.Token); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update password"})
		return
	}
	if err := mailops.UpdateMailboxPassword(account.Email, req.NewPassword); err != nil {
		log.Printf("WARNING: Stalwart password sync failed for %s (reset): %v", account.Email, err)
	}

	db.LogAudit(c.Request.Context(), &account.ID, db.AuditPasswordReset, c.ClientIP(), "via reset token")
	c.JSON(http.StatusOK, gin.H{"message": "password reset successful"})
}

func PageReset(c *gin.Context) {
	c.Header("Content-Type", "text/html; charset=utf-8")
	_ = templates.ExecuteTemplate(c.Writer, "reset.html", nil)
}

// === ACCOUNT RECOVERY ===

type RecoverSeedReq struct {
	Email       string `json:"email" binding:"required"`
	Seed        string `json:"seed" binding:"required"`
	NewPassword string `json:"new_password" binding:"required"`
}

func RecoverBySeed(c *gin.Context) {
	var req RecoverSeedReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "email, seed, and new_password are required"})
		return
	}

	if err := validatePassword(req.NewPassword); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	email := strings.ToLower(strings.TrimSpace(req.Email))
	domain := config.Domain()
	if !strings.Contains(email, "@") {
		email = email + "@" + domain
	}

	account, err := db.GetAccountByEmail(c.Request.Context(), email)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid credentials"})
		return
	}

	if account.RecoverySeedHash == "" || !verifySha512(strings.TrimSpace(req.Seed), account.RecoverySeedHash) {
		db.LogAudit(c.Request.Context(), &account.ID, db.AuditLoginFailed, c.ClientIP(), "seed recovery failed")
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid credentials"})
		return
	}

	newHash, err := hashPassword(req.NewPassword)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to hash password"})
		return
	}
	if err := db.UpdatePassword(c.Request.Context(), account.ID, newHash); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update password"})
		return
	}
	if err := mailops.UpdateMailboxPassword(account.Email, req.NewPassword); err != nil {
		log.Printf("WARNING: Stalwart password sync failed for %s (seed recovery): %v", account.Email, err)
	}

	_ = notify.TelegramAdmin(fmt.Sprintf("Account recovered via seed: %s", account.Email))
	db.LogAudit(c.Request.Context(), &account.ID, db.AuditRecoveryUsed, c.ClientIP(), "via seed phrase")

	c.JSON(http.StatusOK, gin.H{
		"message": "password reset successful",
		"email":   account.Email,
		"api_key": account.APIKey,
	})
}

type RecoverInvoiceReq struct {
	Email       string `json:"email" binding:"required"`
	InvoiceID   string `json:"invoice_id" binding:"required"`
	NewPassword string `json:"new_password" binding:"required"`
}

func RecoverByInvoice(c *gin.Context) {
	var req RecoverInvoiceReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "email, invoice_id, and new_password are required"})
		return
	}

	if err := validatePassword(req.NewPassword); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	email := strings.ToLower(strings.TrimSpace(req.Email))
	domain := config.Domain()
	if !strings.Contains(email, "@") {
		email = email + "@" + domain
	}

	account, err := db.GetAccountByInvoicePayment(c.Request.Context(), email, strings.TrimSpace(req.InvoiceID))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid email or invoice ID"})
		return
	}

	newHash, err := hashPassword(req.NewPassword)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to hash password"})
		return
	}
	if err := db.UpdatePassword(c.Request.Context(), account.ID, newHash); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update password"})
		return
	}
	if err := mailops.UpdateMailboxPassword(account.Email, req.NewPassword); err != nil {
		log.Printf("WARNING: Stalwart password sync failed for %s (invoice recovery): %v", account.Email, err)
	}

	_ = notify.TelegramAdmin(fmt.Sprintf("Account recovered via invoice: %s (invoice %s)", account.Email, req.InvoiceID))
	db.LogAudit(c.Request.Context(), &account.ID, db.AuditRecoveryUsed, c.ClientIP(), fmt.Sprintf("via invoice %s", req.InvoiceID))

	c.JSON(http.StatusOK, gin.H{
		"message": "password reset successful",
		"email":   account.Email,
		"api_key": account.APIKey,
	})
}

func validatePassword(pw string) error {
	if len(pw) < 8 {
		return fmt.Errorf("password must be at least 8 characters")
	}
	if len(pw) > 128 {
		return fmt.Errorf("password must be at most 128 characters")
	}
	hasUpper, hasDigit, hasSpecial := false, false, false
	for _, c := range pw {
		switch {
		case c >= 'A' && c <= 'Z':
			hasUpper = true
		case c >= '0' && c <= '9':
			hasDigit = true
		case !((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')):
			hasSpecial = true
		}
	}
	if !hasUpper {
		return fmt.Errorf("password must contain at least one uppercase letter")
	}
	if !hasDigit {
		return fmt.Errorf("password must contain at least one number")
	}
	if !hasSpecial {
		return fmt.Errorf("password must contain at least one special character (e.g. $ ! @ #)")
	}
	return nil
}

// verifyPassword checks a password against a hash.
// Supports both bcrypt ($2a$/$2b$) and legacy SHA512 ($6$) formats.
func verifyPassword(password, hash string) bool {
	// bcrypt hashes start with $2a$ or $2b$
	if strings.HasPrefix(hash, "$2a$") || strings.HasPrefix(hash, "$2b$") {
		return bcrypt.CompareHashAndPassword([]byte(hash), []byte(password)) == nil
	}
	// Legacy SHA512: $6$<salt_hex>$<hash_hex>
	parts := strings.Split(hash, "$")
	if len(parts) != 4 || parts[1] != "6" {
		return false
	}
	salt := parts[2]
	h := sha512.Sum512([]byte(password + salt))
	computed := hex.EncodeToString(h[:])
	return subtle.ConstantTimeCompare([]byte(computed), []byte(parts[3])) == 1
}

// verifySha512 is an alias for backward compatibility.
func verifySha512(password, hash string) bool {
	return verifyPassword(password, hash)
}

