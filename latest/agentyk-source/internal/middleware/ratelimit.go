package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

type ipEntry struct {
	count    int
	windowAt time.Time
}

// RateLimit returns middleware that limits requests per IP.
// maxRequests per window duration. Uses IP from X-Forwarded-For or RemoteAddr.
func RateLimit(maxRequests int, window time.Duration) gin.HandlerFunc {
	var mu sync.Mutex
	clients := make(map[string]*ipEntry)

	// Cleanup stale entries every 5 minutes
	go func() {
		for {
			time.Sleep(5 * time.Minute)
			mu.Lock()
			now := time.Now()
			for ip, e := range clients {
				if now.Sub(e.windowAt) > window {
					delete(clients, ip)
				}
			}
			mu.Unlock()
		}
	}()

	return func(c *gin.Context) {
		ip := c.ClientIP()

		mu.Lock()
		e, exists := clients[ip]
		now := time.Now()

		if !exists || now.Sub(e.windowAt) > window {
			clients[ip] = &ipEntry{count: 1, windowAt: now}
			mu.Unlock()
			c.Next()
			return
		}

		e.count++
		if e.count > maxRequests {
			mu.Unlock()
			c.JSON(http.StatusTooManyRequests, gin.H{"error": "too many requests, try again later"})
			c.Abort()
			return
		}
		mu.Unlock()
		c.Next()
	}
}
