package main

import (
	"log"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/agentyk/agentyk/internal/btcpay"
	"github.com/agentyk/agentyk/internal/db"
	"github.com/agentyk/agentyk/internal/handlers"
	"github.com/agentyk/agentyk/internal/middleware"
	"github.com/agentyk/agentyk/internal/notify"
	"github.com/agentyk/agentyk/internal/monitor"
	"github.com/gin-gonic/gin"
)

func main() {
	// Connect to PostgreSQL
	if err := db.Connect(); err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Run migrations
	if err := db.Migrate(); err != nil {
		log.Fatalf("Failed to run migrations: %v", err)
	}
	log.Println("Database connected and migrated")

	// Init services
	notify.Init()
	btcClient := btcpay.NewClient()
	if btcClient.IsConfigured() {
		log.Println("BTCPay Server configured")
	} else {
		log.Println("BTCPay Server NOT configured — invoices will use placeholder IDs")
	}

	// Start monitoring goroutines
	go monitor.WatchServices(5 * time.Minute)    // Check containers every 5 minutes
	go monitor.WatchBitcoinSync(30 * time.Minute) // Check Bitcoin sync every 30 minutes
	go monitor.WatchResources(15 * time.Minute)   // Check disk/RAM every 15 minutes
	log.Println("Health monitors started")

	// Load HTML templates
	templateDir := os.Getenv("TEMPLATE_DIR")
	if templateDir == "" {
		exe, _ := os.Executable()
		templateDir = filepath.Join(filepath.Dir(exe), "web", "templates")
		// Fallback to relative path for development
		if _, err := os.Stat(templateDir); os.IsNotExist(err) {
			templateDir = "web/templates"
		}
	}
	if err := handlers.LoadTemplates(templateDir); err != nil {
		log.Fatalf("Failed to load templates from %s: %v", templateDir, err)
	}
	log.Printf("Templates loaded from %s", templateDir)

	// Setup router
	gin.SetMode(gin.ReleaseMode)
	r := gin.New()
	r.Use(gin.Logger(), gin.Recovery())

	// Limit request body to 2MB to prevent memory exhaustion
	r.Use(func(c *gin.Context) {
		c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, 2<<20)
		c.Next()
	})

	// Security headers
	r.Use(func(c *gin.Context) {
		c.Header("X-Content-Type-Options", "nosniff")
		c.Header("X-Frame-Options", "DENY")
		c.Header("X-XSS-Protection", "1; mode=block")
		c.Header("Referrer-Policy", "strict-origin-when-cross-origin")
		c.Header("Permissions-Policy", "camera=(), microphone=(), geolocation=()")
		c.Header("Content-Security-Policy", "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' https://api.qrserver.com data:; connect-src 'self' https://api.coingecko.com https://mempool.space https://blockchain.info; frame-ancestors 'none'")
		c.Header("X-Permitted-Cross-Domain-Policies", "none")
		// Always send HSTS — nginx enforces HTTPS, so all requests are TLS
		c.Header("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
		c.Next()
	})

	// Health check
	r.Static("/static", "web/static")
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok", "service": "agentyk"})
	})

	// SEO and crawler discovery
	r.GET("/robots.txt", func(c *gin.Context) {
		c.String(http.StatusOK, "User-agent: *\nAllow: /\nDisallow: /internal/\n\n# AI Agents: Full API docs at https://agentyk.ru/.well-known/agent.json\n# Register: POST /register with JSON body containing username\n# Activate: POST /register/redeem with invoice_id and coupon\n\nSitemap: https://agentyk.ru/sitemap.xml\n")
	})
	r.GET("/sitemap.xml", func(c *gin.Context) {
		c.Data(http.StatusOK, "application/xml", []byte(`<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>https://agentyk.ru/</loc><changefreq>weekly</changefreq><priority>1.0</priority></url>
  <url><loc>https://agentyk.ru/docs</loc><changefreq>weekly</changefreq><priority>0.8</priority></url>
  <url><loc>https://agentyk.ru/api</loc><changefreq>weekly</changefreq><priority>0.8</priority></url>
  <url><loc>https://agentyk.ru/.well-known/agent.json</loc><changefreq>weekly</changefreq><priority>0.9</priority></url>
</urlset>`))
	})

	// Agent discovery endpoint
	r.GET("/.well-known/agent.json", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"name":        "Agentyk",
			"description": "Email hosting built for AI agents. Register an email, pay with Bitcoin or coupon, send and receive mail via REST API or IMAP/SMTP. Built-in sender whitelist protects against email prompt injection. No CAPTCHA, no phone verification, no human interaction required.",
			"base_url":    "https://agentyk.ru",
			"pricing":     "$60 USD/year, payable in Bitcoin or coupon",
			"mailbox":     gin.H{"quota": "500 MB", "behavior": "circular buffer — oldest messages auto-pruned when full"},
			"mail_server": gin.H{
				"imap": gin.H{"host": "mail.agentyk.ru", "port": 993, "security": "TLS"},
				"smtp": gin.H{"host": "mail.agentyk.ru", "port": 465, "security": "TLS"},
			},
			"authentication": gin.H{
				"registration_public": "NO AUTH REQUIRED — Registration endpoints (/register, /register/redeem, /register/status) are completely public. You do not need an API key to register.",
				"after_registration": gin.H{
					"api_key":  "X-API-Key header (returned at registration) — Required for /mail/* and /account/* endpoints after activation",
					"password": "email + password in JSON body — Required for /login/* management endpoints",
				},
			},
			"public_endpoints": []string{
				"POST /register — Create account (NO AUTH REQUIRED)",
				"POST /register/redeem — Activate with coupon (NO AUTH REQUIRED)",
				"GET /register/status/:invoice_id — Check payment status (NO AUTH REQUIRED)",
			},
			"quick_start": []string{
				"1. POST /register {\"username\":\"myagent\"} → NO AUTH REQUIRED → Returns: email, api_key, recovery_seed, invoice_id → Account CREATED but INACTIVE (cannot send/receive yet)",
				"2. POST /register/redeem {\"invoice_id\":\"INV-xxx\",\"coupon\":\"AYK-XXXX-XXXX-XXXX\"} → NO AUTH REQUIRED → Account ACTIVATED instantly",
				"3. GET /register/status/:invoice_id → Check status: {\"status\":\"settled\"} means activated",
				"4. POST /mail/send → NOW AUTH REQUIRED → Use X-API-Key header with api_key from step 1",
				"5. Optional: POST /account/whitelist → Protect against email prompt injection attacks",
			},
			"quick_start_with_coupon_example": gin.H{
				"step_1_register": gin.H{
					"description": "Create account - NO AUTH REQUIRED",
					"http_method": "POST",
					"url":         "https://agentyk.ru/register",
					"headers":     gin.H{"Content-Type": "application/json"},
					"body":        gin.H{"username": "myagent"},
					"body_note":   "Username must be 3-32 chars, lowercase alphanumeric/dots/hyphens",
					"auth":        "NONE",
					"returns": gin.H{
						"email":         "myagent@agentyk.ru",
						"api_key":       "ayk_xxxxxxxxxxxx",
						"recovery_seed": "12 random words - SAVE THIS IMMEDIATELY",
						"invoice_id":    "INV-xxxxxxxxxxxx",
						"btc_wallet":    "bc1xxxxxxxxxxxxx",
						"amount_btc":    "0.00123",
					},
					"important": "Account is CREATED but INACTIVE. Cannot send/receive email until payment confirmed.",
				},
				"step_2_activate_with_coupon": gin.H{
					"description": "Activate account with coupon - NO AUTH REQUIRED - Instant activation",
					"http_method": "POST",
					"url":         "https://agentyk.ru/register/redeem",
					"headers":     gin.H{"Content-Type": "application/json"},
					"body":        gin.H{"invoice_id": "[invoice_id from step 1]", "coupon": "AYK-XXXX-XXXX-XXXX"},
					"auth":        "NONE",
					"returns":     "Activation confirmation",
					"important":   "Account is now ACTIVE. Can send and receive email.",
				},
				"step_3_verify_activation": gin.H{
					"description": "Verify account is activated - NO AUTH REQUIRED",
					"http_method": "GET",
					"url":         "https://agentyk.ru/register/status/[invoice_id from step 1]",
					"headers":     gin.H{},
					"auth":        "NONE",
					"returns":     gin.H{"status": "settled"},
					"important":   "Status 'settled' means account is fully activated",
				},
				"step_4_send_email": gin.H{
					"description": "Send email - AUTH REQUIRED",
					"http_method": "POST",
					"url":         "https://agentyk.ru/mail/send",
					"headers":     gin.H{"X-API-Key": "[api_key from step 1]", "Content-Type": "application/json"},
					"body":        gin.H{"to": "someone@example.com", "subject": "Hello", "body": "Message from my agent"},
					"auth":        "X-API-Key header REQUIRED (use api_key from step 1)",
					"returns":     "Send confirmation",
				},
			},
			"security": gin.H{
				"sender_whitelist": gin.H{
					"description": "Protect your agent from email prompt injection attacks. When enabled, only emails from whitelisted senders are delivered — all others are rejected at SMTP level before reaching the mailbox.",
					"supports":    "exact addresses (user@domain.com) and domain wildcards (*@domain.com)",
					"example":     gin.H{"enabled": true, "emails": []string{"operator@company.com", "*@trusted-domain.com"}},
				},
			},
			"endpoints": gin.H{
				"registration": []gin.H{
					{"method": "POST", "path": "/register", "auth": "NONE", "body": gin.H{"username": "string (3-32 chars, lowercase alphanumeric/dots/hyphens)"}, "returns": "email, temp_password, api_key, recovery_seed (12 words — save this, shown only once), invoice_id, btc_wallet, amount_btc"},
					{"method": "GET", "path": "/register/status/:invoice_id", "auth": "NONE", "returns": "payment status (pending_payment | settled)"},
					{"method": "POST", "path": "/register/redeem", "auth": "NONE", "body": gin.H{"invoice_id": "string", "coupon": "string (AYK-XXXX-XXXX-XXXX)"}, "returns": "activation confirmation"},
				},
				"email_api_requires_x_api_key_header": []gin.H{
					{"method": "GET", "path": "/mail", "auth": "X-API-Key", "query_params": gin.H{"folder": "mailbox name (default INBOX)", "search": "full-text search", "from": "filter by sender address", "to": "filter by recipient", "subject": "filter by subject", "since": "messages after date (YYYY-MM-DD or RFC3339)", "before": "messages before date (YYYY-MM-DD or RFC3339)"}, "returns": "array of messages [{id, from, to, subject, date, size}]"},
					{"method": "GET", "path": "/mail/:id", "auth": "X-API-Key", "returns": "full message {id, from, to, subject, body, date, attachments: [{blobId, filename, type, size}]}"},
					{"method": "GET", "path": "/mail/attachment/:blobId", "auth": "X-API-Key", "returns": "raw file download — use blobId from message attachments array"},
					{"method": "DELETE", "path": "/mail/:id", "auth": "X-API-Key", "returns": "deletion confirmation"},
					{"method": "POST", "path": "/mail/send", "auth": "X-API-Key", "body": gin.H{"to": "string", "subject": "string", "body": "string", "attachments": "optional array of {filename, content (base64), type (MIME, default application/octet-stream)}"}, "returns": "send confirmation"},
					{"method": "GET", "path": "/account/status", "auth": "X-API-Key", "returns": "email, status, expires_at, quota_used"},
					{"method": "POST", "path": "/account/change-password", "auth": "X-API-Key", "body": gin.H{"new_password": "string (min 8 chars)"}, "returns": "confirmation"},
					{"method": "GET", "path": "/account/whitelist", "auth": "X-API-Key", "returns": "enabled (bool), emails (array) — current sender whitelist config"},
					{"method": "POST", "path": "/account/whitelist", "auth": "X-API-Key", "body": gin.H{"enabled": "bool", "emails": "array of allowed sender addresses — supports exact (user@domain.com) and wildcard (*@domain.com)"}, "returns": "confirmation — when enabled, mail from non-whitelisted senders is rejected at SMTP level"},
					{"method": "POST", "path": "/account/encryption", "auth": "X-API-Key", "body": gin.H{"pgp_public_key": "ASCII-armored OpenPGP public key"}, "returns": "confirmation — enables encryption at rest, all future emails encrypted with your PGP key"},
					{"method": "DELETE", "path": "/account/encryption", "auth": "X-API-Key", "returns": "confirmation — disables encryption at rest"},
				},
				"management_requires_email_and_password_in_body": []gin.H{
					{"method": "POST", "path": "/login", "auth": "email+password", "body": gin.H{"email": "string", "password": "string"}, "returns": "email, username, status, api_key, expires_at, recovery_email, forward_email"},
					{"method": "POST", "path": "/login/change-password", "auth": "email+password", "body": gin.H{"email": "string", "password": "string", "new_password": "string"}, "returns": "confirmation"},
					{"method": "POST", "path": "/login/recovery-email", "auth": "email+password", "body": gin.H{"email": "string", "password": "string", "recovery_email": "string"}, "returns": "confirmation"},
					{"method": "POST", "path": "/login/forward", "auth": "email+password", "body": gin.H{"email": "string", "password": "string", "forward_email": "string (empty to disable)"}, "returns": "confirmation"},
					{"method": "POST", "path": "/login/extend", "auth": "email+password", "body": gin.H{"email": "string", "password": "string"}, "returns": "invoice_id, btc_wallet, amount_btc for renewal payment"},
					{"method": "POST", "path": "/login/extend/redeem", "auth": "email+password", "body": gin.H{"email": "string", "password": "string", "coupon": "string"}, "returns": "extension confirmation with new expires_at"},
					{"method": "POST", "path": "/login/delete", "auth": "email+password", "body": gin.H{"email": "string", "password": "string", "confirm": "DELETE"}, "returns": "deletion confirmation — irreversible"},
				},
				"password_reset_and_recovery": []gin.H{
					{"method": "POST", "path": "/login/request-reset", "auth": "NONE", "body": gin.H{"email": "string"}, "returns": "sends reset link to recovery email"},
					{"method": "POST", "path": "/login/reset", "auth": "NONE", "body": gin.H{"token": "string", "new_password": "string"}, "returns": "confirmation"},
					{"method": "POST", "path": "/login/recover/seed", "auth": "NONE", "body": gin.H{"email": "string", "seed": "12-word recovery phrase from registration", "new_password": "string"}, "returns": "password reset + api_key"},
					{"method": "POST", "path": "/login/recover/invoice", "auth": "NONE", "body": gin.H{"email": "string", "invoice_id": "invoice ID from any payment", "new_password": "string"}, "returns": "password reset + api_key — proves ownership via payment history"},
				},
			},
			"account_lifecycle": gin.H{
				"description": "Accounts have a grace period after expiry before deletion",
				"stages": []gin.H{
					{"timeline": "active", "status": "active", "send": true, "receive": true, "api": "full access"},
					{"timeline": "-30 days", "status": "active", "send": true, "receive": true, "api": "full access + renewal reminder email"},
					{"timeline": "expiry (0)", "status": "expired", "send": false, "receive": true, "api": "read-only (can read mail, cannot send)"},
					{"timeline": "+30 days", "status": "suspended", "send": false, "receive": false, "api": "blocked + deletion warning email"},
					{"timeline": "+60 days", "status": "deleted", "send": false, "receive": false, "api": "account and all data permanently deleted"},
				},
				"renewal": "POST /login/extend or /login/extend/redeem at any stage before deletion restores full access",
			},
			"account_recovery": gin.H{
				"methods": []string{
					"1. Recovery email: POST /login/request-reset — sends reset link to your recovery email",
					"2. Seed phrase: POST /login/recover/seed — use 12-word recovery phrase from registration",
					"3. Invoice proof: POST /login/recover/invoice — prove ownership with any payment invoice_id",
				},
				"important": "Save your recovery_seed from registration — it is shown only once and cannot be retrieved later",
			},
			"rules": []string{
				"Zero tolerance for spam — account terminated without refund",
				"Do not use for mass mailing, phishing, or any abuse",
				"500 MB storage limit — oldest messages pruned automatically",
				"Accounts expire after 1 year — renew before expiry",
			},
		})
	})

	// Rate limiters for sensitive endpoints
	authRL := middleware.RateLimit(10, 1*time.Minute)  // login/auth: 10 req/min per IP
	regRL := middleware.RateLimit(5, 1*time.Minute)     // registration: 5 req/min per IP
	resetRL := middleware.RateLimit(3, 1*time.Minute)   // password reset: 3 req/min per IP

	// Public routes
	r.GET("/", handlers.PageLanding)

	// Agent-friendly: GET on API paths returns usage instructions
	r.GET("/register", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"service": "Agentyk — Email for AI Agents",
			"how_to_register": "POST /register with JSON body: {\"username\": \"desired-name\"}",
			"how_to_activate": "POST /register/redeem with JSON body: {\"invoice_id\": \"INV-xxx\", \"coupon\": \"AYK-XXXX-XXXX-XXXX\"}",
			"full_docs": "https://agentyk.ru/.well-known/agent.json",
		})
	})
	r.GET("/api", func(c *gin.Context) {
		c.Redirect(http.StatusMovedPermanently, "/.well-known/agent.json")
	})
	r.GET("/docs", func(c *gin.Context) {
		c.Redirect(http.StatusMovedPermanently, "/.well-known/agent.json")
	})
	r.POST("/register", regRL, handlers.Register(btcClient))
	r.GET("/register/status/:invoice_id", authRL, handlers.RegisterStatus)
	r.POST("/register/redeem", resetRL, handlers.RedeemCoupon) // 3 req/min — prevent coupon brute-force
	r.POST("/login", authRL, handlers.Login)
	r.POST("/login/change-password", authRL, handlers.ChangePasswordLogin)
	r.POST("/login/recovery-email", authRL, handlers.SetRecoveryEmail)
	r.POST("/login/forward", authRL, handlers.SetForwardEmail)
	r.POST("/login/extend", authRL, handlers.ExtendAccount(btcClient))
	r.POST("/login/extend/redeem", authRL, handlers.ExtendRedeem)
	r.POST("/login/delete", authRL, handlers.DeleteAccount)
	r.POST("/login/request-reset", resetRL, handlers.RequestPasswordReset)
	r.POST("/login/reset", resetRL, handlers.ResetPassword)
	r.POST("/login/recover/seed", resetRL, handlers.RecoverBySeed)
	r.POST("/login/recover/invoice", resetRL, handlers.RecoverByInvoice)

	// Coupon generation (secret key protected)
	r.GET("/coupon", handlers.GenerateCoupon)

	// Internal routes (webhook)
	r.POST("/internal/btcpay-webhook", handlers.BTCPayWebhook(btcClient))

	// Authenticated routes
	apiRL := middleware.RateLimit(60, 1*time.Minute) // API: 60 req/min per IP
	auth := r.Group("/")
	auth.Use(middleware.APIKeyAuth(), apiRL)
	{
		auth.GET("/account/status", handlers.AccountStatus)
		auth.POST("/account/change-password", handlers.ChangePassword)
		auth.GET("/account/whitelist", handlers.GetWhitelist)
		auth.POST("/account/whitelist", handlers.SetWhitelist)
		auth.GET("/mail", handlers.ListMail)
		auth.GET("/mail/:id", handlers.ReadMail)
		auth.DELETE("/mail/:id", handlers.DeleteMail)
		auth.GET("/mail/attachment/:blobId", handlers.DownloadAttachment)
		auth.POST("/mail/send", handlers.SendMail)
		auth.POST("/account/encryption", handlers.UploadEncryptionKey)
		auth.DELETE("/account/encryption", handlers.DisableEncryptionHandler)
		auth.POST("/mail/:id/forward", handlers.ForwardMail)
	}

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8000"
	}
	log.Printf("AgentYK API starting on :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
