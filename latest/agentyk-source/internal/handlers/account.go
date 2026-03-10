package handlers

import (
	"net/http"
	"strings"

	"github.com/agentyk/agentyk/internal/db"
	"github.com/agentyk/agentyk/internal/mailops"
	"github.com/gin-gonic/gin"
)

func AccountStatus(c *gin.Context) {
	account := c.MustGet("account").(*db.Account)
	c.JSON(http.StatusOK, gin.H{
		"email":      account.Email,
		"status":     account.Status,
		"expires_at": account.ExpiresAt,
		"quota_used": account.QuotaUsed,
		"created_at": account.CreatedAt,
	})
}

type ChangePasswordReq struct {
	NewPassword string `json:"new_password" binding:"required"`
}

func ChangePassword(c *gin.Context) {
	account := c.MustGet("account").(*db.Account)

	if account.Status != "active" {
		c.JSON(http.StatusForbidden, gin.H{"error": "account is not active"})
		return
	}

	var req ChangePasswordReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "new_password is required"})
		return
	}

	if err := validatePassword(req.NewPassword); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
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

	// Sync password to Stalwart
	_ = mailops.UpdateMailboxPassword(account.Email, req.NewPassword)

	db.LogAudit(c.Request.Context(), &account.ID, db.AuditPasswordChanged, c.ClientIP(), "via API key")
	c.JSON(http.StatusOK, gin.H{"status": "password_updated"})
}

type EncryptionKeyReq struct {
	PGPPublicKey string `json:"pgp_public_key" binding:"required"`
}

func UploadEncryptionKey(c *gin.Context) {
	account := c.MustGet("account").(*db.Account)

	if account.Status != "active" {
		c.JSON(http.StatusForbidden, gin.H{"error": "account is not active"})
		return
	}

	var req EncryptionKeyReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "pgp_public_key is required (ASCII-armored OpenPGP public key)"})
		return
	}

	// Basic validation: must look like a PGP public key
	if !strings.Contains(req.PGPPublicKey, "-----BEGIN PGP PUBLIC KEY BLOCK-----") {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid PGP public key format — must be ASCII-armored (BEGIN PGP PUBLIC KEY BLOCK)"})
		return
	}

	if err := mailops.SetEncryptionKey(account.Email, req.PGPPublicKey); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to set encryption key: " + err.Error()})
		return
	}

	db.LogAudit(c.Request.Context(), &account.ID, "encryption_key_uploaded", c.ClientIP(), "PGP key uploaded for encryption at rest")
	c.JSON(http.StatusOK, gin.H{
		"status":  "encryption_enabled",
		"message": "All future incoming emails will be encrypted at rest with your PGP public key. Only you can decrypt them with your private key.",
	})
}

func DisableEncryptionHandler(c *gin.Context) {
	account := c.MustGet("account").(*db.Account)

	if account.Status != "active" {
		c.JSON(http.StatusForbidden, gin.H{"error": "account is not active"})
		return
	}

	if err := mailops.DisableEncryption(account.Email); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to disable encryption: " + err.Error()})
		return
	}

	db.LogAudit(c.Request.Context(), &account.ID, "encryption_disabled", c.ClientIP(), "Encryption at rest disabled")
	c.JSON(http.StatusOK, gin.H{
		"status":  "encryption_disabled",
		"message": "Encryption at rest has been disabled. New incoming emails will be stored in plaintext.",
	})
}
