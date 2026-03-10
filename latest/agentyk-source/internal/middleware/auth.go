package middleware

import (
	"net/http"

	"github.com/agentyk/agentyk/internal/db"
	"github.com/gin-gonic/gin"
)

func APIKeyAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		apiKey := c.GetHeader("X-API-Key")
		if apiKey == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "missing X-API-Key header"})
			c.Abort()
			return
		}

		account, err := db.GetAccountByAPIKey(c.Request.Context(), apiKey)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid API key"})
			c.Abort()
			return
		}

		if account.Status != "active" && account.Status != "expired" {
			c.JSON(http.StatusForbidden, gin.H{"error": "account suspended — renew via POST /login/extend to restore access", "status": account.Status})
			c.Abort()
			return
		}

		c.Set("account", account)
		c.Next()
	}
}
