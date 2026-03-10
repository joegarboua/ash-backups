package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"

	"github.com/agentyk/agentyk/internal/btcpay"
	"github.com/agentyk/agentyk/internal/db"
	"github.com/agentyk/agentyk/internal/notify"
	"github.com/gin-gonic/gin"
)

type WebhookPayload struct {
	Type      string `json:"type"`
	InvoiceID string `json:"invoiceId"`
	StoreID   string `json:"storeId"`
}

func BTCPayWebhook(btcClient *btcpay.Client) gin.HandlerFunc {
	return func(c *gin.Context) {
		body, err := io.ReadAll(c.Request.Body)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "cannot read body"})
			return
		}

		clientIP := c.ClientIP()
		sig := c.GetHeader("BTCPay-Sig")
		if !btcClient.VerifyWebhookSignature(body, sig) {
			log.Printf("WEBHOOK: bad signature from %s", clientIP)
			db.LogAudit(c.Request.Context(), nil, db.AuditWebhookBadSig, clientIP, "invalid BTCPay-Sig header")
			c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid signature"})
			return
		}

		var payload WebhookPayload
		if err := json.Unmarshal(body, &payload); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid payload"})
			return
		}

		if payload.Type != "InvoiceSettled" && payload.Type != "InvoicePaymentSettled" {
			c.JSON(http.StatusOK, gin.H{"status": "ignored", "type": payload.Type})
			return
		}

		// Idempotency: skip if account already active for this invoice
		existing, err := db.GetAccountByInvoice(c.Request.Context(), payload.InvoiceID)
		if err == nil && existing.Status == "active" {
			c.JSON(http.StatusOK, gin.H{"status": "already_active"})
			return
		}

		if err := db.ActivateWithPaymentAtomic(c.Request.Context(), payload.InvoiceID); err != nil {
			log.Printf("WEBHOOK: activation failed for invoice %s: %v", payload.InvoiceID, err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to activate account"})
			return
		}

		db.LogAudit(c.Request.Context(), nil, db.AuditPaymentActivated, clientIP,
			fmt.Sprintf("invoice=%s type=%s", payload.InvoiceID, payload.Type))
		_ = notify.TelegramAdmin(fmt.Sprintf("Payment received! Invoice %s — account activated", payload.InvoiceID))

		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	}
}
