package mailops

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"
)

var (
	stalwartAPI    string
	stalwartUser   string
	stalwartPass   string
	stalwartClient = &http.Client{Timeout: 15 * time.Second}
)

func init() {
	stalwartAPI = os.Getenv("STALWART_API")
	if stalwartAPI == "" {
		stalwartAPI = "http://stalwart:8080"
	}
	stalwartUser = os.Getenv("STALWART_ADMIN_USER")
	if stalwartUser == "" {
		stalwartUser = "admin"
	}
	stalwartPass = os.Getenv("STALWART_ADMIN_PASS")
	if stalwartPass == "" {
		log.Fatal("FATAL: STALWART_ADMIN_PASS environment variable is required")
	}
}

// sieveEscape sanitizes a string for safe inclusion in a Sieve script quoted string.
// Removes characters that could break out of Sieve string literals.
func sieveEscape(s string) string {
	s = strings.ReplaceAll(s, `\`, `\\`)
	s = strings.ReplaceAll(s, `"`, `\"`)
	s = strings.ReplaceAll(s, "\r", "")
	s = strings.ReplaceAll(s, "\n", "")
	return s
}

func stalwartAuth() string {
	return "Basic " + base64.StdEncoding.EncodeToString([]byte(stalwartUser+":"+stalwartPass))
}

func stalwartRequest(method, path string, body interface{}) ([]byte, error) {
	var bodyReader io.Reader
	if body != nil {
		b, err := json.Marshal(body)
		if err != nil {
			return nil, err
		}
		bodyReader = bytes.NewReader(b)
	}
	req, err := http.NewRequest(method, stalwartAPI+path, bodyReader)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", stalwartAuth())
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	resp, err := stalwartClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("stalwart API %s %s: read body: %w", method, path, err)
	}
	if resp.StatusCode >= 400 {
		return data, fmt.Errorf("stalwart API %s %s: %d %s", method, path, resp.StatusCode, string(data))
	}
	return data, nil
}

// hashForStalwart bcrypt-hashes a password so Stalwart never stores plaintext.
func hashForStalwart(password string) string {
	h, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		log.Printf("CRITICAL: bcrypt hash failed: %v — refusing plaintext storage", err)
		return "{INVALID}" // never store plaintext
	}
	return string(h)
}

// CreateMailbox creates a user account in Stalwart with the given email and password.
func CreateMailbox(email, password string) error {
	name := email
	if idx := strings.Index(email, "@"); idx >= 0 {
		name = email[:idx]
	}

	principal := map[string]interface{}{
		"type":    "individual",
		"name":    name,
		"secrets": []string{hashForStalwart(password)},
		"emails":  []string{email},
		"quota":   545259520, // 520 MB
		"roles":   []string{"user"},
	}

	_, err := stalwartRequest("POST", "/api/principal", principal)
	return err
}

// UpdateMailboxPassword updates a user's password in Stalwart.
func UpdateMailboxPassword(email, newPassword string) error {
	name := emailToName(email)

	update := []map[string]interface{}{
		{"action": "set", "field": "secrets", "value": []string{hashForStalwart(newPassword)}},
	}

	_, err := stalwartRequest("PATCH", "/api/principal/"+name, update)
	return err
}

// DeleteMailbox removes a user account from Stalwart.
func DeleteMailbox(email string) error {
	name := emailToName(email)
	_, err := stalwartRequest("DELETE", "/api/principal/"+name, nil)
	return err
}

func emailToName(email string) string {
	for i, c := range email {
		if c == '@' {
			return email[:i]
		}
	}
	return email
}

// SetForwardingSieve sets or removes a forwarding Sieve script for a user via JMAP.
// If forwardEmail is empty, it removes the active script (disables forwarding).
func SetForwardingSieve(userEmail, forwardEmail string) error {
	// We need the user's JMAP account ID. For Stalwart, we use master auth
	// and impersonate the user to manage their Sieve scripts.
	// Simpler approach: use ManageSieve-like calls via Stalwart's JMAP endpoint.

	if forwardEmail == "" {
		return clearSieveScript(userEmail)
	}

	// Sieve script: redirect a copy to forward address, keep local
	script := fmt.Sprintf(`require ["copy"];
redirect :copy "%s";
keep;
`, sieveEscape(forwardEmail))

	return setSieveScript(userEmail, "forwarding", script)
}

func setSieveScript(userEmail, scriptName, scriptBody string) error {
	// Use JMAP SieveScript/set to create and activate the script
	// First, get the user's account ID by querying as master
	accountID, err := getJMAPAccountID(userEmail)
	if err != nil {
		return fmt.Errorf("get account ID for %s: %w", userEmail, err)
	}

	// Create/update the sieve script via JMAP
	jmapReq := map[string]interface{}{
		"using": []string{
			"urn:ietf:params:jmap:core",
			"urn:ietf:params:jmap:sieve",
		},
		"methodCalls": []interface{}{
			[]interface{}{
				"SieveScript/set",
				map[string]interface{}{
					"accountId": accountID,
					"create": map[string]interface{}{
						"fwd": map[string]interface{}{
							"name":     scriptName,
							"blobId":   nil,
							"isActive": true,
						},
					},
				},
				"0",
			},
		},
	}

	// Upload the script blob first
	blobID, err := uploadBlob(userEmail, accountID, []byte(scriptBody))
	if err != nil {
		return fmt.Errorf("upload sieve blob: %w", err)
	}

	// Now set with the blob ID
	jmapReq = map[string]interface{}{
		"using": []string{
			"urn:ietf:params:jmap:core",
			"urn:ietf:params:jmap:sieve",
		},
		"methodCalls": []interface{}{
			// First, query existing scripts to find and destroy old ones
			[]interface{}{
				"SieveScript/query",
				map[string]interface{}{
					"accountId": accountID,
				},
				"q0",
			},
			// Then get their details
			[]interface{}{
				"SieveScript/get",
				map[string]interface{}{
					"accountId": accountID,
					"#ids": map[string]interface{}{
						"resultOf": "q0",
						"name":     "SieveScript/query",
						"path":     "/ids",
					},
				},
				"g0",
			},
		},
	}

	data, err := jmapCall(userEmail, jmapReq)
	if err != nil {
		return fmt.Errorf("query sieve scripts: %w", err)
	}

	// Parse existing script IDs to destroy them
	var destroyIDs []string
	var jmapResp struct {
		MethodResponses [][]json.RawMessage `json:"methodResponses"`
	}
	if err := json.Unmarshal(data, &jmapResp); err == nil {
		for _, resp := range jmapResp.MethodResponses {
			if len(resp) >= 2 {
				var getResp struct {
					List []struct {
						ID string `json:"id"`
					} `json:"list"`
				}
				if json.Unmarshal(resp[1], &getResp) == nil {
					for _, s := range getResp.List {
						destroyIDs = append(destroyIDs, s.ID)
					}
				}
			}
		}
	}

	// Create new script and destroy old ones
	setReq := map[string]interface{}{
		"accountId": accountID,
		"create": map[string]interface{}{
			"fwd": map[string]interface{}{
				"name":     scriptName,
				"blobId":   blobID,
				"isActive": true,
			},
		},
	}
	if len(destroyIDs) > 0 {
		setReq["destroy"] = destroyIDs
	}

	jmapReq = map[string]interface{}{
		"using": []string{
			"urn:ietf:params:jmap:core",
			"urn:ietf:params:jmap:sieve",
		},
		"methodCalls": []interface{}{
			[]interface{}{
				"SieveScript/set",
				setReq,
				"s0",
			},
		},
	}

	data, err = jmapCall(userEmail, jmapReq)
	if err != nil {
		return fmt.Errorf("set sieve script: %w", err)
	}

	return nil
}

func clearSieveScript(userEmail string) error {
	accountID, err := getJMAPAccountID(userEmail)
	if err != nil {
		return err
	}

	// Query all scripts
	jmapReq := map[string]interface{}{
		"using": []string{
			"urn:ietf:params:jmap:core",
			"urn:ietf:params:jmap:sieve",
		},
		"methodCalls": []interface{}{
			[]interface{}{
				"SieveScript/query",
				map[string]interface{}{
					"accountId": accountID,
				},
				"q0",
			},
		},
	}

	data, err := jmapCall(userEmail, jmapReq)
	if err != nil {
		return err
	}

	var jmapResp struct {
		MethodResponses [][]json.RawMessage `json:"methodResponses"`
	}
	if err := json.Unmarshal(data, &jmapResp); err != nil {
		return err
	}

	var ids []string
	for _, resp := range jmapResp.MethodResponses {
		if len(resp) >= 2 {
			var qResp struct {
				IDs []string `json:"ids"`
			}
			if json.Unmarshal(resp[1], &qResp) == nil {
				ids = qResp.IDs
			}
		}
	}

	if len(ids) == 0 {
		return nil
	}

	// Destroy all scripts
	jmapReq = map[string]interface{}{
		"using": []string{
			"urn:ietf:params:jmap:core",
			"urn:ietf:params:jmap:sieve",
		},
		"methodCalls": []interface{}{
			[]interface{}{
				"SieveScript/set",
				map[string]interface{}{
					"accountId": accountID,
					"destroy":   ids,
				},
				"d0",
			},
		},
	}

	_, err = jmapCall(userEmail, jmapReq)
	return err
}


// SetWhitelistSieve sets or removes a whitelist Sieve script for a user.
// When enabled, only emails from whitelisted addresses are accepted; others are rejected.
// When disabled (empty list), the whitelist script is removed.
func SetWhitelistSieve(userEmail string, enabled bool, emails []string) error {
	if !enabled || len(emails) == 0 {
		return removeSieveScript(userEmail, "whitelist")
	}

	// Separate exact addresses from domain wildcards (*@domain)
	var exactAddrs []string
	var domainPatterns []string
	for _, e := range emails {
		if strings.HasPrefix(e, "*@") {
			domainPatterns = append(domainPatterns, e[2:]) // strip *@
		} else {
			exactAddrs = append(exactAddrs, e)
		}
	}

	// Build sieve script with anyof (OR) for exact + domain matches
	var conditions []string

	if len(exactAddrs) > 0 {
		var quoted []string
		for _, a := range exactAddrs {
			quoted = append(quoted, fmt.Sprintf(`"%s"`, sieveEscape(a)))
		}
		conditions = append(conditions, fmt.Sprintf(`address :is "from" [%s]`, strings.Join(quoted, ", ")))
	}

	for _, d := range domainPatterns {
		conditions = append(conditions, fmt.Sprintf(`address :matches "from" "*@%s"`, sieveEscape(d)))
	}

	var testExpr string
	if len(conditions) == 1 {
		testExpr = conditions[0]
	} else {
		testExpr = "anyof (" + strings.Join(conditions, ", ") + ")"
	}

	script := fmt.Sprintf(`require ["reject", "envelope"];
if not %s {
  reject "Sender not in whitelist";
  stop;
}
`, testExpr)

	return setSieveScriptNamed(userEmail, "whitelist", script)
}

// setSieveScriptNamed creates/replaces a named sieve script without destroying other scripts.
func setSieveScriptNamed(userEmail, scriptName, scriptBody string) error {
	accountID, err := getJMAPAccountID(userEmail)
	if err != nil {
		return fmt.Errorf("get account ID for %s: %w", userEmail, err)
	}

	blobID, err := uploadBlob(userEmail, accountID, []byte(scriptBody))
	if err != nil {
		return fmt.Errorf("upload sieve blob: %w", err)
	}

	// Query existing scripts to find old one with same name
	qReq := map[string]interface{}{
		"using": []string{"urn:ietf:params:jmap:core", "urn:ietf:params:jmap:sieve"},
		"methodCalls": []interface{}{
			[]interface{}{
				"SieveScript/get",
				map[string]interface{}{
					"accountId": accountID,
				},
				"g0",
			},
		},
	}

	data, err := jmapCall(userEmail, qReq)
	if err != nil {
		return fmt.Errorf("query sieve scripts: %w", err)
	}

	var jmapResp struct {
		MethodResponses [][]json.RawMessage `json:"methodResponses"`
	}
	if err := json.Unmarshal(data, &jmapResp); err != nil {
		return fmt.Errorf("unmarshal sieve query response: %w", err)
	}

	var destroyIDs []string
	for _, resp := range jmapResp.MethodResponses {
		if len(resp) < 2 {
			continue
		}
		var getResp struct {
			List []struct {
				ID   string `json:"id"`
				Name string `json:"name"`
			} `json:"list"`
		}
		if json.Unmarshal(resp[1], &getResp) == nil {
			for _, s := range getResp.List {
				if s.Name == scriptName {
					destroyIDs = append(destroyIDs, s.ID)
				}
			}
		}
	}

	setReq := map[string]interface{}{
		"accountId": accountID,
		"create": map[string]interface{}{
			"wl": map[string]interface{}{
				"name":     scriptName,
				"blobId":   blobID,
				"isActive": true,
			},
		},
	}
	if len(destroyIDs) > 0 {
		setReq["destroy"] = destroyIDs
	}

	jmapReq := map[string]interface{}{
		"using": []string{"urn:ietf:params:jmap:core", "urn:ietf:params:jmap:sieve"},
		"methodCalls": []interface{}{
			[]interface{}{
				"SieveScript/set",
				setReq,
				"s0",
			},
		},
	}

	_, err = jmapCall(userEmail, jmapReq)
	return err
}

// removeSieveScript removes a named sieve script.
func removeSieveScript(userEmail, scriptName string) error {
	accountID, err := getJMAPAccountID(userEmail)
	if err != nil {
		return err
	}

	qReq := map[string]interface{}{
		"using": []string{"urn:ietf:params:jmap:core", "urn:ietf:params:jmap:sieve"},
		"methodCalls": []interface{}{
			[]interface{}{
				"SieveScript/get",
				map[string]interface{}{"accountId": accountID},
				"g0",
			},
		},
	}

	data, err := jmapCall(userEmail, qReq)
	if err != nil {
		return err
	}

	var jmapResp struct {
		MethodResponses [][]json.RawMessage `json:"methodResponses"`
	}
	if err := json.Unmarshal(data, &jmapResp); err != nil {
		return fmt.Errorf("unmarshal sieve query response: %w", err)
	}

	var destroyIDs []string
	for _, resp := range jmapResp.MethodResponses {
		if len(resp) < 2 {
			continue
		}
		var getResp struct {
			List []struct {
				ID   string `json:"id"`
				Name string `json:"name"`
			} `json:"list"`
		}
		if json.Unmarshal(resp[1], &getResp) == nil {
			for _, s := range getResp.List {
				if s.Name == scriptName {
					destroyIDs = append(destroyIDs, s.ID)
				}
			}
		}
	}

	if len(destroyIDs) == 0 {
		return nil
	}

	jmapReq := map[string]interface{}{
		"using": []string{"urn:ietf:params:jmap:core", "urn:ietf:params:jmap:sieve"},
		"methodCalls": []interface{}{
			[]interface{}{
				"SieveScript/set",
				map[string]interface{}{
					"accountId": accountID,
					"destroy":   destroyIDs,
				},
				"d0",
			},
		},
	}

	_, err = jmapCall(userEmail, jmapReq)
	return err
}

// RestoreFullAccess re-enables all services (IMAP, SMTP, JMAP) for a user after renewal.
func RestoreFullAccess(email string) error {
	name := emailToName(email)
	// Clear enabledServices so Stalwart uses the default (all services)
	update := []map[string]interface{}{
		{"action": "set", "field": "enabledServices", "value": []string{}},
	}
	_, err := stalwartRequest("PATCH", "/api/principal/"+name, update)
	return err
}

// userAuth returns a Basic auth header to impersonate a user via Stalwart's master auth.
// Format: "user%master_user:master_password" — Stalwart authenticates as master, acts as user.
func userAuth(userEmail string) (string, error) {
	name := emailToName(userEmail)
	cred := name + "%" + stalwartUser + ":" + stalwartPass
	return "Basic " + base64.StdEncoding.EncodeToString([]byte(cred)), nil
}

func getJMAPAccountID(userEmail string) (string, error) {
	auth, err := userAuth(userEmail)
	if err != nil {
		return "", err
	}

	req, err := http.NewRequest("GET", stalwartAPI+"/jmap/session", nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("Authorization", auth)

	resp, err := stalwartClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("JMAP session read: %w", err)
	}

	if resp.StatusCode != 200 {
		return "", fmt.Errorf("JMAP session failed: %d %s", resp.StatusCode, string(data))
	}

	var session struct {
		PrimaryAccounts map[string]string `json:"primaryAccounts"`
	}
	if err := json.Unmarshal(data, &session); err != nil {
		return "", fmt.Errorf("parse session: %w (%s)", err, string(data))
	}

	if id, ok := session.PrimaryAccounts["urn:ietf:params:jmap:mail"]; ok {
		return id, nil
	}

	return "", fmt.Errorf("no mail account found for %s", userEmail)
}

func uploadBlob(userEmail, accountID string, data []byte) (string, error) {
	url := fmt.Sprintf("%s/jmap/upload/%s/", stalwartAPI, accountID)
	req, err := http.NewRequest("POST", url, bytes.NewReader(data))
	if err != nil {
		return "", err
	}
	uAuth, err := userAuth(userEmail)
	if err != nil {
		return "", err
	}
	req.Header.Set("Authorization", uAuth)
	req.Header.Set("Content-Type", "application/octet-stream")

	resp, err := stalwartClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("blob upload read: %w", err)
	}

	var result struct {
		BlobID string `json:"blobId"`
	}
	if err := json.Unmarshal(body, &result); err != nil {
		return "", fmt.Errorf("parse upload response: %w (%s)", err, string(body))
	}
	if result.BlobID == "" {
		return "", fmt.Errorf("no blobId in response: %s", string(body))
	}
	return result.BlobID, nil
}

func jmapCall(userEmail string, req interface{}) ([]byte, error) {
	auth, err := userAuth(userEmail)
	if err != nil {
		return nil, fmt.Errorf("user auth: %w", err)
	}

	b, err := json.Marshal(req)
	if err != nil {
		return nil, err
	}

	httpReq, err := http.NewRequest("POST", stalwartAPI+"/jmap/", bytes.NewReader(b))
	if err != nil {
		return nil, err
	}
	httpReq.Header.Set("Authorization", auth)
	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := stalwartClient.Do(httpReq)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("JMAP read body: %w", err)
	}
	if resp.StatusCode >= 400 {
		return data, fmt.Errorf("JMAP call failed: %d %s", resp.StatusCode, string(data))
	}
	return data, nil
}

// SetEncryptionKey uploads an OpenPGP public key to Stalwart for encryption at rest.
// Once set, all incoming emails for this user are encrypted before being written to disk.
func SetEncryptionKey(userEmail, pgpPublicKey string) error {
	auth, err := userAuth(userEmail)
	if err != nil {
		return fmt.Errorf("user auth: %w", err)
	}

	payload := map[string]interface{}{
		"type":  "pGP",
		"algo":  "Aes256",
		"certs": pgpPublicKey,
		"allow_spam_training": true,
	}

	b, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("marshal crypto payload: %w", err)
	}

	req, err := http.NewRequest("POST", stalwartAPI+"/api/account/crypto", bytes.NewReader(b))
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", auth)
	req.Header.Set("Content-Type", "application/json")

	resp, err := stalwartClient.Do(req)
	if err != nil {
		return fmt.Errorf("stalwart crypto API: %w", err)
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)

	if resp.StatusCode >= 400 {
		return fmt.Errorf("stalwart crypto API: %d %s", resp.StatusCode, string(body))
	}
	return nil
}

// DisableEncryption removes encryption at rest for a user by sending an empty crypto config.
func DisableEncryption(userEmail string) error {
	auth, err := userAuth(userEmail)
	if err != nil {
		return fmt.Errorf("user auth: %w", err)
	}

	payload := map[string]interface{}{
		"type":  "disabled",
		"algo":  "Aes256",
		"certs": "",
		"allow_spam_training": true,
	}

	b, err := json.Marshal(payload)
	if err != nil {
		return err
	}

	req, err := http.NewRequest("POST", stalwartAPI+"/api/account/crypto", bytes.NewReader(b))
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", auth)
	req.Header.Set("Content-Type", "application/json")

	resp, err := stalwartClient.Do(req)
	if err != nil {
		return fmt.Errorf("stalwart crypto API: %w", err)
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)

	if resp.StatusCode >= 400 {
		return fmt.Errorf("stalwart crypto disable: %d %s", resp.StatusCode, string(body))
	}
	return nil
}
