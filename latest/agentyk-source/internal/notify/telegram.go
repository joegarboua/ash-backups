package notify

import (
	"fmt"
	"net/http"
	"net/url"
	"os"
)

var (
	botToken string
	chatID   string
)

func Init() {
	botToken = os.Getenv("TELEGRAM_BOT_TOKEN")
	chatID = os.Getenv("TELEGRAM_ADMIN_CHAT_ID")
}

func TelegramAdmin(msg string) error {
	if botToken == "" || chatID == "" {
		return nil // silently skip if not configured
	}

	apiURL := fmt.Sprintf("https://api.telegram.org/bot%s/sendMessage", botToken)
	resp, err := http.PostForm(apiURL, url.Values{
		"chat_id":    {chatID},
		"text":       {msg},
		"parse_mode": {"HTML"},
	})
	if err != nil {
		return err
	}
	resp.Body.Close()
	return nil
}
