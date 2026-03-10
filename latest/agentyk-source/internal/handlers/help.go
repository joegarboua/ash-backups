package handlers

import (
	"fmt"
	"net/http"

	"github.com/agentyk/agentyk/internal/db"
	"github.com/agentyk/agentyk/internal/notify"
	"github.com/gin-gonic/gin"
)

type HelpReq struct {
	Email     string `json:"email"`
	InvoiceID string `json:"invoice_id"`
	Message   string `json:"message" binding:"required"`
}

func SubmitHelp(c *gin.Context) {
	var req HelpReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "message is required"})
		return
	}

	// Sanitize optional fields — limit lengths to prevent DB pollution
	if len(req.Email) > 255 {
		req.Email = req.Email[:255]
	}
	if len(req.InvoiceID) > 64 {
		req.InvoiceID = req.InvoiceID[:64]
	}
	if len(req.Message) > 2000 {
		req.Message = req.Message[:2000]
	}

	if err := db.SaveHelpRequest(c.Request.Context(), req.Email, req.InvoiceID, req.Message); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to save request"})
		return
	}

	_ = notify.TelegramAdmin(fmt.Sprintf("Help request from %s (invoice: %s):\n%s", req.Email, req.InvoiceID, req.Message))

	c.JSON(http.StatusOK, gin.H{"status": "received"})
}
