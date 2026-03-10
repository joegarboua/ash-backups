package handlers

import (
	"html/template"
	"log"
	"net/http"
	"path/filepath"
	"strings"

	"github.com/agentyk/agentyk/internal/config"
	"github.com/agentyk/agentyk/internal/db"
	"github.com/gin-gonic/gin"
)

var templates *template.Template

func LoadTemplates(templateDir string) error {
	var err error
	templates, err = template.ParseGlob(filepath.Join(templateDir, "*.html"))
	return err
}

func PageLanding(c *gin.Context) {
	c.Header("Content-Type", "text/html; charset=utf-8")
	if err := templates.ExecuteTemplate(c.Writer, "landing.html", nil); err != nil {
		log.Printf("template error: %v", err)
		c.String(http.StatusInternalServerError, "Internal server error")
	}
}

func PageRegister(c *gin.Context) {
	domain := config.Domain()
	c.Header("Content-Type", "text/html; charset=utf-8")
	if err := templates.ExecuteTemplate(c.Writer, "register.html", map[string]string{
		"domain": domain,
	}); err != nil {
		log.Printf("template error: %v", err)
		c.String(http.StatusInternalServerError, "Internal server error")
	}
}

func PageAPI(c *gin.Context) {
	c.Header("Content-Type", "text/html; charset=utf-8")
	if err := templates.ExecuteTemplate(c.Writer, "api.html", nil); err != nil {
		log.Printf("template error: %v", err)
		c.String(http.StatusInternalServerError, "Internal server error")
	}
}

func PageTerms(c *gin.Context) {
	c.Header("Content-Type", "text/html; charset=utf-8")
	if err := templates.ExecuteTemplate(c.Writer, "terms.html", nil); err != nil {
		log.Printf("template error: %v", err)
		c.String(http.StatusInternalServerError, "Internal server error")
	}
}

func PagePrivacy(c *gin.Context) {
	c.Header("Content-Type", "text/html; charset=utf-8")
	if err := templates.ExecuteTemplate(c.Writer, "privacy.html", nil); err != nil {
		log.Printf("template error: %v", err)
		c.String(http.StatusInternalServerError, "Internal server error")
	}
}
func PageDocs(c *gin.Context) {
	c.Header("Content-Type", "text/html; charset=utf-8")
	if err := templates.ExecuteTemplate(c.Writer, "docs.html", nil); err != nil {
		log.Printf("template error: %v", err)
		c.String(http.StatusInternalServerError, "Internal server error")
	}
}

func PageHelp(c *gin.Context) {
	domain := config.Domain()
	c.Header("Content-Type", "text/html; charset=utf-8")
	if err := templates.ExecuteTemplate(c.Writer, "help.html", map[string]string{
		"domain": domain,
	}); err != nil {
		log.Printf("template error: %v", err)
		c.String(http.StatusInternalServerError, "Internal server error")
	}
}

func PageStatus(c *gin.Context) {
	invoiceID := c.Param("invoice_id")
	domain := config.Domain()

	account, err := db.GetAccountByInvoice(c.Request.Context(), invoiceID)
	if err != nil {
		c.String(http.StatusNotFound, "Invoice not found")
		return
	}

	// Mask email for public display: show first 2 chars + ***@domain
	maskedEmail := account.Email
	if at := strings.Index(account.Email, "@"); at > 2 {
		maskedEmail = account.Email[:2] + "***" + account.Email[at:]
	}

	data := map[string]interface{}{
		"domain":      domain,
		"email":       maskedEmail,
		"invoice_id":  invoiceID,
		"status":      account.Status,
		"login_ready": account.Status == "active",
	}

	c.Header("Content-Type", "text/html; charset=utf-8")
	if err := templates.ExecuteTemplate(c.Writer, "status.html", data); err != nil {
		log.Printf("template error: %v", err)
		c.String(http.StatusInternalServerError, "Internal server error")
	}
}
