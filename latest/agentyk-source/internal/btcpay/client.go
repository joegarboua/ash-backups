package btcpay

import (
	"bytes"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
)

type Client struct {
	URL           string
	APIKey        string
	StoreID       string
	WebhookSecret string
}

type Invoice struct {
	ID          string `json:"id"`
	CheckoutURL string `json:"checkoutLink"`
	Amount      string `json:"amount"`
	Currency    string `json:"currency"`
}

type CreateInvoiceReq struct {
	Amount   float64                `json:"amount"`
	Currency string                 `json:"currency"`
	Metadata map[string]interface{} `json:"metadata,omitempty"`
	Checkout *CheckoutOpts          `json:"checkout,omitempty"`
}

type CheckoutOpts struct {
	RedirectURL string `json:"redirectURL,omitempty"`
}

func NewClient() *Client {
	url := os.Getenv("BTCPAY_URL")
	if url == "" {
		url = "http://btcpay:49392"
	}
	return &Client{
		URL:           url,
		APIKey:        os.Getenv("BTCPAY_KEY"),
		StoreID:       os.Getenv("BTCPAY_STORE_ID"),
		WebhookSecret: os.Getenv("BTCPAY_WEBHOOK_SECRET"),
	}
}

func (c *Client) CreateInvoice(username, email string, amountEUR float64, redirectURL string) (*Invoice, error) {
	reqBody := CreateInvoiceReq{
		Amount:   amountEUR,
		Currency: "EUR",
		Metadata: map[string]interface{}{
			"username": username,
			"email":    email,
		},
	}
	if redirectURL != "" {
		reqBody.Checkout = &CheckoutOpts{RedirectURL: redirectURL}
	}

	body, err := json.Marshal(reqBody)
	if err != nil {
		return nil, err
	}

	url := fmt.Sprintf("%s/api/v1/stores/%s/invoices", c.URL, c.StoreID)
	req, err := http.NewRequest("POST", url, bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "token "+c.APIKey)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("btcpay request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("btcpay read response: %w", err)
	}
	if resp.StatusCode != 200 {
		log.Printf("BTCPay error %d: %s", resp.StatusCode, string(respBody))
		return nil, fmt.Errorf("btcpay returned status %d", resp.StatusCode)
	}

	var inv Invoice
	if err := json.Unmarshal(respBody, &inv); err != nil {
		return nil, err
	}
	return &inv, nil
}

func (c *Client) VerifyWebhookSignature(body []byte, sigHeader string) bool {
	if c.WebhookSecret == "" {
		return false
	}
	mac := hmac.New(sha256.New, []byte(c.WebhookSecret))
	mac.Write(body)
	expected := hex.EncodeToString(mac.Sum(nil))

	// BTCPay sends "sha256=HEXDIGEST"
	if len(sigHeader) > 7 && sigHeader[:7] == "sha256=" {
		sigHeader = sigHeader[7:]
	}
	return hmac.Equal([]byte(expected), []byte(sigHeader))
}

func (c *Client) IsConfigured() bool {
	return c.APIKey != "" && c.StoreID != ""
}
