package handlers

import (
	"encoding/base64"
	"fmt"
	"log"
	"net/http"
	"strings"

	"github.com/agentyk/agentyk/internal/db"
	"github.com/agentyk/agentyk/internal/mailops"
	"github.com/gin-gonic/gin"
)

func ListMail(c *gin.Context) {
	account := c.MustGet("account").(*db.Account)
	folder := c.DefaultQuery("folder", "INBOX")

	filter := mailops.SearchFilter{
		Search:  c.Query("search"),
		From:    c.Query("from"),
		To:      c.Query("to"),
		Subject: c.Query("subject"),
		Since:   c.Query("since"),
		Before:  c.Query("before"),
	}

	messages, err := mailops.ListMessages(account.Email, folder, filter)
	if err != nil {
		log.Printf("ListMail error for %s: %v", account.Email, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list messages"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"messages": messages, "count": len(messages)})
}

func ReadMail(c *gin.Context) {
	account := c.MustGet("account").(*db.Account)
	msgID := c.Param("id")
	folder := c.DefaultQuery("folder", "INBOX")

	msg, err := mailops.ReadMessage(account.Email, folder, msgID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "message not found"})
		return
	}

	c.JSON(http.StatusOK, msg)
}

func DeleteMail(c *gin.Context) {
	account := c.MustGet("account").(*db.Account)
	msgID := c.Param("id")
	folder := c.DefaultQuery("folder", "INBOX")

	if err := mailops.DeleteMessage(account.Email, folder, msgID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to delete message"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "deleted"})
}

func DownloadAttachment(c *gin.Context) {
	account := c.MustGet("account").(*db.Account)
	blobID := c.Param("blobId")

	data, contentType, err := mailops.DownloadBlob(account.Email, blobID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "attachment not found"})
		return
	}

	c.Data(http.StatusOK, contentType, data)
}

// GetWhitelist returns the current whitelist configuration.
func GetWhitelist(c *gin.Context) {
	account := c.MustGet("account").(*db.Account)

	var emails []string
	if account.WhitelistEmails != "" {
		for _, e := range strings.Split(account.WhitelistEmails, ",") {
			e = strings.TrimSpace(e)
			if e != "" {
				emails = append(emails, e)
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"enabled": account.WhitelistEnabled,
		"emails":  emails,
	})
}

type SetWhitelistReq struct {
	Enabled bool     `json:"enabled"`
	Emails  []string `json:"emails"`
}

// SetWhitelist enables/disables the sender whitelist and pushes a Sieve script.
func SetWhitelist(c *gin.Context) {
	account := c.MustGet("account").(*db.Account)

	var req SetWhitelistReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "enabled (bool) and emails (array) are required"})
		return
	}

	// Normalize and validate emails (allow *@domain.tld for domain wildcards)
	var cleaned []string
	for _, e := range req.Emails {
		e = strings.ToLower(strings.TrimSpace(e))
		if e == "" {
			continue
		}
		// Allow exact emails or *@domain wildcards
		if strings.HasPrefix(e, "*@") {
			domain := e[2:]
			if !strings.Contains(domain, ".") || len(domain) < 4 {
				c.JSON(http.StatusBadRequest, gin.H{"error": "invalid domain wildcard: " + e})
				return
			}
		} else if !strings.Contains(e, "@") || !strings.Contains(e, ".") {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid email address: " + e})
			return
		}
		cleaned = append(cleaned, e)
	}

	if req.Enabled && len(cleaned) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "whitelist enabled but no emails provided — this would reject all mail"})
		return
	}

	emailsStr := strings.Join(cleaned, ",")

	// Save to DB
	if err := db.SetWhitelist(c.Request.Context(), account.ID, req.Enabled, emailsStr); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to save whitelist"})
		return
	}

	// Push Sieve script to Stalwart
	if err := mailops.SetWhitelistSieve(account.Email, req.Enabled, cleaned); err != nil {
		log.Printf("SetWhitelistSieve error for %s: %v", account.Email, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "whitelist saved but sieve filter failed"})
		return
	}

	db.LogAudit(c.Request.Context(), &account.ID, db.AuditWhitelistChanged, c.ClientIP(), fmt.Sprintf("enabled=%v count=%d", req.Enabled, len(cleaned)))
	c.JSON(http.StatusOK, gin.H{
		"message": "whitelist updated",
		"enabled": req.Enabled,
		"emails":  cleaned,
	})
}

type AttachmentReq struct {
	Filename string `json:"filename" binding:"required"`
	Content  string `json:"content" binding:"required"` // base64-encoded
	Type     string `json:"type"`                       // MIME type, default application/octet-stream
}

type SendMailReq struct {
	To          string          `json:"to" binding:"required"`
	Subject     string          `json:"subject" binding:"required"`
	Body        string          `json:"body" binding:"required"`
	Attachments []AttachmentReq `json:"attachments"`
}

func SendMail(c *gin.Context) {
	account := c.MustGet("account").(*db.Account)

	if account.Status == "expired" {
		c.JSON(http.StatusForbidden, gin.H{"error": "account expired — sending is disabled. Renew via POST /login/extend to restore full access."})
		return
	}

	var req SendMailReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "to, subject, and body are required"})
		return
	}

	// Limit body size to prevent abuse
	if len(req.Body) > 512*1024 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "message body too large (max 512 KB)"})
		return
	}

	// Decode attachments (max 25 MB per attachment, max 5 attachments)
	if len(req.Attachments) > 5 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "maximum 5 attachments allowed"})
		return
	}
	const maxAttachmentSize = 25 * 1024 * 1024 // 25 MB
	var attachments []mailops.Attachment
	for _, a := range req.Attachments {
		if len(a.Content) > maxAttachmentSize*4/3+4 { // base64 overhead
			c.JSON(http.StatusBadRequest, gin.H{"error": "attachment too large (max 25 MB): " + a.Filename})
			return
		}
		data, err := base64.StdEncoding.DecodeString(a.Content)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid base64 in attachment: " + a.Filename})
			return
		}
		if len(data) > maxAttachmentSize {
			c.JSON(http.StatusBadRequest, gin.H{"error": "attachment too large (max 25 MB): " + a.Filename})
			return
		}
		mimeType := a.Type
		if mimeType == "" {
			mimeType = "application/octet-stream"
		}
		// Sanitize filename — strip path components, reject null bytes
		safeName := a.Filename
		if i := strings.LastIndex(safeName, "/"); i >= 0 {
			safeName = safeName[i+1:]
		}
		if i := strings.LastIndex(safeName, "\\"); i >= 0 {
			safeName = safeName[i+1:]
		}
		safeName = strings.ReplaceAll(safeName, "\x00", "")
		if safeName == "" {
			safeName = "attachment"
		}
		attachments = append(attachments, mailops.Attachment{
			Filename: safeName,
			Data:     data,
			MIMEType: mimeType,
		})
	}

	if err := mailops.SendMessage(account.Email, req.To, req.Subject, req.Body, attachments); err != nil {
		log.Printf("SendMail error for %s: %v", account.Email, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to send message"})
		return
	}

	if err := db.IncrementQuota(c.Request.Context(), account.ID); err != nil {
		log.Printf("quota increment failed for account %d: %v", account.ID, err)
	}

	c.JSON(http.StatusOK, gin.H{"status": "sent"})
}

type ForwardMailReq struct {
	To      string `json:"to" binding:"required"`
	Comment string `json:"comment"` // optional note above forwarded content
}

func ForwardMail(c *gin.Context) {
	account := c.MustGet("account").(*db.Account)
	msgID := c.Param("id")
	folder := c.DefaultQuery("folder", "INBOX")

	if account.Status == "expired" {
		c.JSON(http.StatusForbidden, gin.H{"error": "account expired — sending is disabled"})
		return
	}

	var req ForwardMailReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "to is required"})
		return
	}

	// Read the original message
	msg, err := mailops.ReadMessage(account.Email, folder, msgID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "message not found"})
		return
	}

	// Build forwarded body
	fwdBody := ""
	if req.Comment != "" {
		fwdBody = req.Comment + "\n\n"
	}
	fwdBody += "---------- Forwarded message ----------\n"
	fwdBody += "From: " + msg.From + "\n"
	fwdBody += "Date: " + msg.Date + "\n"
	fwdBody += "Subject: " + msg.Subject + "\n"
	fwdBody += "To: " + msg.To + "\n"
	fwdBody += "----------------------------------------\n\n"
	fwdBody += msg.Body

	// Forward subject
	subject := msg.Subject
	if !strings.HasPrefix(strings.ToLower(subject), "fwd:") {
		subject = "Fwd: " + subject
	}

	// Download and forward attachments
	var attachments []mailops.Attachment
	for _, att := range msg.Attachments {
		data, contentType, err := mailops.DownloadBlob(account.Email, att.BlobID)
		if err != nil {
			log.Printf("ForwardMail: failed to download attachment %s: %v", att.Filename, err)
			continue
		}
		mimeType := att.Type
		if mimeType == "" {
			mimeType = contentType
		}
		attachments = append(attachments, mailops.Attachment{
			Filename: att.Filename,
			Data:     data,
			MIMEType: mimeType,
		})
	}

	if err := mailops.SendMessage(account.Email, req.To, subject, fwdBody, attachments); err != nil {
		log.Printf("ForwardMail error for %s: %v", account.Email, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to forward message"})
		return
	}

	if err := db.IncrementQuota(c.Request.Context(), account.ID); err != nil {
		log.Printf("quota increment failed for account %d: %v", account.ID, err)
	}

	c.JSON(http.StatusOK, gin.H{"status": "forwarded", "to": req.To, "subject": subject})
}
