package mailops

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/agentyk/agentyk/internal/config"
)

type MessageAttachment struct {
	BlobID   string `json:"blobId"`
	Filename string `json:"filename"`
	Type     string `json:"type"`
	Size     int    `json:"size"`
}

type Message struct {
	ID          string              `json:"id"`
	From        string              `json:"from"`
	To          string              `json:"to"`
	Subject     string              `json:"subject"`
	Date        string              `json:"date"`
	Size        int                 `json:"size,omitempty"`
	Body        string              `json:"body,omitempty"`
	Attachments []MessageAttachment `json:"attachments,omitempty"`
}

type SearchFilter struct {
	Search  string // full-text search
	From    string // filter by sender
	To      string // filter by recipient
	Subject string // filter by subject
	Since   string // messages after this date (RFC3339 or YYYY-MM-DD)
	Before  string // messages before this date (RFC3339 or YYYY-MM-DD)
}

// ListMessages lists messages in a user's mailbox via Stalwart JMAP.
func ListMessages(email, folder string, filter SearchFilter) ([]Message, error) {
	accountID, err := getJMAPAccountID(email)
	if err != nil {
		return nil, fmt.Errorf("get account: %w", err)
	}

	mailboxID, err := getMailboxID(email, accountID, folder)
	if err != nil {
		return nil, fmt.Errorf("get mailbox: %w", err)
	}

	// Build JMAP filter
	conditions := []map[string]interface{}{
		{"inMailbox": mailboxID},
	}
	if filter.Search != "" {
		conditions = append(conditions, map[string]interface{}{"text": filter.Search})
	}
	if filter.From != "" {
		conditions = append(conditions, map[string]interface{}{"from": filter.From})
	}
	if filter.To != "" {
		conditions = append(conditions, map[string]interface{}{"to": filter.To})
	}
	if filter.Subject != "" {
		conditions = append(conditions, map[string]interface{}{"subject": filter.Subject})
	}
	if filter.Since != "" {
		conditions = append(conditions, map[string]interface{}{"after": normalizeDate(filter.Since)})
	}
	if filter.Before != "" {
		conditions = append(conditions, map[string]interface{}{"before": normalizeDate(filter.Before)})
	}

	var jmapFilter interface{}
	if len(conditions) == 1 {
		jmapFilter = conditions[0]
	} else {
		jmapFilter = map[string]interface{}{
			"operator":   "AND",
			"conditions": conditions,
		}
	}

	// Query + Get in one call
	jmapReq := map[string]interface{}{
		"using": []string{"urn:ietf:params:jmap:core", "urn:ietf:params:jmap:mail"},
		"methodCalls": []interface{}{
			[]interface{}{
				"Email/query",
				map[string]interface{}{
					"accountId": accountID,
					"filter":    jmapFilter,
					"sort":      []map[string]interface{}{{"property": "receivedAt", "isAscending": false}},
					"limit":     50,
				},
				"q0",
			},
			[]interface{}{
				"Email/get",
				map[string]interface{}{
					"accountId":  accountID,
					"properties": []string{"id", "from", "to", "subject", "receivedAt", "size"},
					"#ids": map[string]interface{}{
						"resultOf": "q0",
						"name":     "Email/query",
						"path":     "/ids",
					},
				},
				"g0",
			},
		},
	}

	data, err := jmapCall(email, jmapReq)
	if err != nil {
		return nil, err
	}

	var resp struct {
		MethodResponses [][]json.RawMessage `json:"methodResponses"`
	}
	if err := json.Unmarshal(data, &resp); err != nil {
		return nil, err
	}

	var messages []Message
	for _, mr := range resp.MethodResponses {
		if len(mr) < 2 {
			continue
		}
		var name string
		json.Unmarshal(mr[0], &name)
		if name != "Email/get" {
			continue
		}
		var getResp struct {
			List []struct {
				ID         string `json:"id"`
				From       []struct{ Email string `json:"email"` } `json:"from"`
				To         []struct{ Email string `json:"email"` } `json:"to"`
				Subject    string `json:"subject"`
				ReceivedAt string `json:"receivedAt"`
				Size       int    `json:"size"`
			} `json:"list"`
		}
		if err := json.Unmarshal(mr[1], &getResp); err != nil {
			continue
		}
		for _, e := range getResp.List {
			m := Message{
				ID:      e.ID,
				Subject: e.Subject,
				Date:    e.ReceivedAt,
				Size:    e.Size,
			}
			if len(e.From) > 0 {
				m.From = e.From[0].Email
			}
			if len(e.To) > 0 {
				m.To = e.To[0].Email
			}
			messages = append(messages, m)
		}
	}

	return messages, nil
}

// ReadMessage reads a single message by JMAP ID.
func ReadMessage(email, folder, msgID string) (*Message, error) {
	accountID, err := getJMAPAccountID(email)
	if err != nil {
		return nil, err
	}

	jmapReq := map[string]interface{}{
		"using": []string{"urn:ietf:params:jmap:core", "urn:ietf:params:jmap:mail"},
		"methodCalls": []interface{}{
			[]interface{}{
				"Email/get",
				map[string]interface{}{
					"accountId":  accountID,
					"ids":        []string{msgID},
					"properties": []string{"id", "from", "to", "subject", "receivedAt", "size", "bodyValues", "textBody", "attachments"},
					"fetchTextBodyValues": true,
				},
				"g0",
			},
		},
	}

	data, err := jmapCall(email, jmapReq)
	if err != nil {
		return nil, err
	}

	var resp struct {
		MethodResponses [][]json.RawMessage `json:"methodResponses"`
	}
	if err := json.Unmarshal(data, &resp); err != nil {
		return nil, err
	}

	for _, mr := range resp.MethodResponses {
		if len(mr) < 2 {
			continue
		}
		var name string
		json.Unmarshal(mr[0], &name)
		if name != "Email/get" {
			continue
		}
		var getResp struct {
			List []struct {
				ID         string                                      `json:"id"`
				From       []struct{ Email string `json:"email"` }     `json:"from"`
				To         []struct{ Email string `json:"email"` }     `json:"to"`
				Subject    string                                      `json:"subject"`
				ReceivedAt string                                      `json:"receivedAt"`
				Size       int                                         `json:"size"`
				BodyValues map[string]struct{ Value string `json:"value"` } `json:"bodyValues"`
				TextBody   []struct{ PartID string `json:"partId"` }   `json:"textBody"`
				Attachments []struct {
					BlobID string `json:"blobId"`
					Name   string `json:"name"`
					Type   string `json:"type"`
					Size   int    `json:"size"`
				} `json:"attachments"`
			} `json:"list"`
		}
		if err := json.Unmarshal(mr[1], &getResp); err != nil {
			continue
		}
		if len(getResp.List) == 0 {
			return nil, fmt.Errorf("message not found")
		}
		e := getResp.List[0]
		m := &Message{
			ID:      e.ID,
			Subject: e.Subject,
			Date:    e.ReceivedAt,
			Size:    e.Size,
		}
		if len(e.From) > 0 {
			m.From = e.From[0].Email
		}
		if len(e.To) > 0 {
			m.To = e.To[0].Email
		}
		if len(e.TextBody) > 0 {
			if bv, ok := e.BodyValues[e.TextBody[0].PartID]; ok {
				m.Body = bv.Value
			}
		}
		for _, att := range e.Attachments {
			m.Attachments = append(m.Attachments, MessageAttachment{
				BlobID:   att.BlobID,
				Filename: att.Name,
				Type:     att.Type,
				Size:     att.Size,
			})
		}
		return m, nil
	}

	return nil, fmt.Errorf("message not found")
}

// DeleteMessage deletes a message by JMAP ID.
func DeleteMessage(email, folder, msgID string) error {
	accountID, err := getJMAPAccountID(email)
	if err != nil {
		return err
	}

	jmapReq := map[string]interface{}{
		"using": []string{"urn:ietf:params:jmap:core", "urn:ietf:params:jmap:mail"},
		"methodCalls": []interface{}{
			[]interface{}{
				"Email/set",
				map[string]interface{}{
					"accountId": accountID,
					"destroy":   []string{msgID},
				},
				"d0",
			},
		},
	}

	_, err = jmapCall(email, jmapReq)
	return err
}

type Attachment struct {
	Filename string
	Data     []byte
	MIMEType string
}

// SendMessage sends an email via Stalwart JMAP EmailSubmission.
func SendMessage(from, to, subject, body string, attachments []Attachment) error {
	accountID, err := getJMAPAccountID(from)
	if err != nil {
		return fmt.Errorf("get account: %w", err)
	}

	// Get identity ID and drafts mailbox ID
	identityID, err := getIdentityID(from, accountID)
	if err != nil {
		return fmt.Errorf("get identity: %w", err)
	}

	draftsID, err := getMailboxID(from, accountID, "Drafts")
	if err != nil {
		return fmt.Errorf("get drafts: %w", err)
	}

	// Upload attachment blobs
	var attachmentParts []map[string]interface{}
	for _, att := range attachments {
		blobID, err := uploadBlob(from, accountID, att.Data)
		if err != nil {
			return fmt.Errorf("upload attachment %s: %w", att.Filename, err)
		}
		attachmentParts = append(attachmentParts, map[string]interface{}{
			
			"blobId":      blobID,
			"type":        att.MIMEType,
			"name":        att.Filename,
			"disposition": "attachment",
			"size":        len(att.Data),
		})
	}

	// Step 1: Create draft email
	draft := map[string]interface{}{
		"from":       []map[string]string{{"email": from}},
		"to":         []map[string]string{{"email": to}},
		"subject":    subject,
		"mailboxIds": map[string]bool{draftsID: true},
		"keywords":   map[string]bool{"$draft": true},
		"bodyValues": map[string]interface{}{
			"body": map[string]string{"value": body, "charset": "utf-8"},
		},
		"textBody": []map[string]string{{"partId": "body", "type": "text/plain"}},
	}
	if len(attachmentParts) > 0 {
		draft["attachments"] = attachmentParts
	}

	createReq := map[string]interface{}{
		"using": []string{"urn:ietf:params:jmap:core", "urn:ietf:params:jmap:mail"},
		"methodCalls": []interface{}{
			[]interface{}{
				"Email/set",
				map[string]interface{}{
					"accountId": accountID,
					"create": map[string]interface{}{
						"draft": draft,
					},
				},
				"c0",
			},
		},
	}

	data, err := jmapCall(from, createReq)
	if err != nil {
		return fmt.Errorf("create draft: %w", err)
	}

	// Extract created email ID
	var createResp struct {
		MethodResponses [][]json.RawMessage `json:"methodResponses"`
	}
	if err := json.Unmarshal(data, &createResp); err != nil {
		return fmt.Errorf("parse create response: %w", err)
	}

	var emailID string
	for _, mr := range createResp.MethodResponses {
		if len(mr) < 2 {
			continue
		}
		var setResp struct {
			Created map[string]struct {
				ID string `json:"id"`
			} `json:"created"`
			NotCreated map[string]interface{} `json:"notCreated"`
		}
		if err := json.Unmarshal(mr[1], &setResp); err != nil {
			continue
		}
		if d, ok := setResp.Created["draft"]; ok {
			emailID = d.ID
		}
		if len(setResp.NotCreated) > 0 {
			return fmt.Errorf("failed to create draft: %v", setResp.NotCreated)
		}
	}
	if emailID == "" {
		return fmt.Errorf("no email ID returned from draft creation")
	}

	// Step 2: Submit the email
	submitReq := map[string]interface{}{
		"using": []string{"urn:ietf:params:jmap:core", "urn:ietf:params:jmap:mail", "urn:ietf:params:jmap:submission"},
		"methodCalls": []interface{}{
			[]interface{}{
				"EmailSubmission/set",
				map[string]interface{}{
					"accountId": accountID,
					"create": map[string]interface{}{
						"sub": map[string]interface{}{
							"emailId":    emailID,
							"identityId": identityID,
						},
					},
				},
				"s0",
			},
		},
	}

	data, err = jmapCall(from, submitReq)
	if err != nil {
		return fmt.Errorf("submit email: %w", err)
	}

	// Check for submission errors
	if err := json.Unmarshal(data, &createResp); err != nil {
		return fmt.Errorf("parse submit response: %w", err)
	}

	for _, mr := range createResp.MethodResponses {
		if len(mr) < 2 {
			continue
		}
		var name string
		json.Unmarshal(mr[0], &name)
		if name == "error" {
			return fmt.Errorf("JMAP error: %s", string(mr[1]))
		}
		var setResp struct {
			NotCreated map[string]interface{} `json:"notCreated"`
		}
		if json.Unmarshal(mr[1], &setResp) == nil && len(setResp.NotCreated) > 0 {
			return fmt.Errorf("submission failed: %v", setResp.NotCreated)
		}
	}

	// Step 3: Move from Drafts to Sent
	sentID, _ := getMailboxID(from, accountID, "Sent")
	if sentID != "" {
		moveReq := map[string]interface{}{
			"using": []string{"urn:ietf:params:jmap:core", "urn:ietf:params:jmap:mail"},
			"methodCalls": []interface{}{
				[]interface{}{
					"Email/set",
					map[string]interface{}{
						"accountId": accountID,
						"update": map[string]interface{}{
							emailID: map[string]interface{}{
								"mailboxIds":      map[string]bool{sentID: true},
								"keywords/$draft": nil,
							},
						},
					},
					"mv0",
				},
			},
		}
		_, _ = jmapCall(from, moveReq)
	}

	// Step 4: Local delivery — if recipient is on this server, copy to their INBOX.
	// JMAP EmailSubmission may not trigger local delivery in Stalwart for same-domain messages.
	if isLocalAddress(to) {
		if to == from {
			// Self-delivery: create INBOX copy in same account
			inboxID, _ := getMailboxID(from, accountID, "INBOX")
			if inboxID != "" {
				selfMsg := map[string]interface{}{
					"from":       []map[string]string{{"email": from}},
					"to":         []map[string]string{{"email": to}},
					"subject":    subject,
					"mailboxIds": map[string]bool{inboxID: true},
					"bodyValues": map[string]interface{}{
						"body": map[string]string{"value": body, "charset": "utf-8"},
					},
					"textBody": []map[string]string{{"partId": "body", "type": "text/plain"}},
				}
				selfReq := map[string]interface{}{
					"using": []string{"urn:ietf:params:jmap:core", "urn:ietf:params:jmap:mail"},
					"methodCalls": []interface{}{
						[]interface{}{
							"Email/set",
							map[string]interface{}{
								"accountId": accountID,
								"create":    map[string]interface{}{"deliver": selfMsg},
							},
							"sd0",
						},
					},
				}
				_, _ = jmapCall(from, selfReq)
			}
		} else {
			localDeliver(from, to, subject, body, attachments)
		}
	}

	return nil
}

// isLocalAddress checks if the email address belongs to agentyk.ru.
func isLocalAddress(email string) bool {
	return strings.HasSuffix(strings.ToLower(email), "@"+config.Domain())
}

// localDeliver creates a copy of a message in a local recipient's INBOX via JMAP.
func localDeliver(from, to, subject, body string, attachments []Attachment) {
	recipAccountID, err := getJMAPAccountID(to)
	if err != nil {
		return // recipient doesn't exist or JMAP session failed — silently skip
	}

	inboxID, err := getMailboxID(to, recipAccountID, "INBOX")
	if err != nil {
		return
	}

	// Upload attachment blobs to recipient's account
	var attachmentParts []map[string]interface{}
	for _, att := range attachments {
		blobID, err := uploadBlob(to, recipAccountID, att.Data)
		if err != nil {
			continue
		}
		attachmentParts = append(attachmentParts, map[string]interface{}{
			
			"blobId":      blobID,
			"type":        att.MIMEType,
			"name":        att.Filename,
			"disposition": "attachment",
			"size":        len(att.Data),
		})
	}

	msg := map[string]interface{}{
		"from":       []map[string]string{{"email": from}},
		"to":         []map[string]string{{"email": to}},
		"subject":    subject,
		"mailboxIds": map[string]bool{inboxID: true},
		"bodyValues": map[string]interface{}{
			"body": map[string]string{"value": body, "charset": "utf-8"},
		},
		"textBody": []map[string]string{{"partId": "body", "type": "text/plain"}},
	}
	if len(attachmentParts) > 0 {
		msg["attachments"] = attachmentParts
	}

	deliverReq := map[string]interface{}{
		"using": []string{"urn:ietf:params:jmap:core", "urn:ietf:params:jmap:mail"},
		"methodCalls": []interface{}{
			[]interface{}{
				"Email/set",
				map[string]interface{}{
					"accountId": recipAccountID,
					"create": map[string]interface{}{
						"deliver": msg,
					},
				},
				"ld0",
			},
		},
	}

	_, _ = jmapCall(to, deliverReq)
}

// getIdentityID retrieves the user's JMAP identity ID for EmailSubmission.
func getIdentityID(userEmail, accountID string) (string, error) {
	jmapReq := map[string]interface{}{
		"using": []string{"urn:ietf:params:jmap:core", "urn:ietf:params:jmap:submission"},
		"methodCalls": []interface{}{
			[]interface{}{
				"Identity/get",
				map[string]interface{}{"accountId": accountID},
				"i0",
			},
		},
	}

	data, err := jmapCall(userEmail, jmapReq)
	if err != nil {
		return "", err
	}

	var resp struct {
		MethodResponses [][]json.RawMessage `json:"methodResponses"`
	}
	if err := json.Unmarshal(data, &resp); err != nil {
		return "", err
	}

	for _, mr := range resp.MethodResponses {
		if len(mr) < 2 {
			continue
		}
		var getResp struct {
			List []struct {
				ID string `json:"id"`
			} `json:"list"`
		}
		if err := json.Unmarshal(mr[1], &getResp); err != nil {
			continue
		}
		if len(getResp.List) > 0 {
			return getResp.List[0].ID, nil
		}
	}

	return "", fmt.Errorf("no identity found for %s", userEmail)
}

// getMailboxID finds the JMAP mailbox ID for a folder name (e.g. "INBOX").
func getMailboxID(email, accountID, folder string) (string, error) {
	if folder == "" {
		folder = "INBOX"
	}

	jmapReq := map[string]interface{}{
		"using": []string{"urn:ietf:params:jmap:core", "urn:ietf:params:jmap:mail"},
		"methodCalls": []interface{}{
			[]interface{}{
				"Mailbox/get",
				map[string]interface{}{
					"accountId":  accountID,
					"properties": []string{"id", "name", "role"},
				},
				"m0",
			},
		},
	}

	data, err := jmapCall(email, jmapReq)
	if err != nil {
		return "", err
	}

	var resp struct {
		MethodResponses [][]json.RawMessage `json:"methodResponses"`
	}
	if err := json.Unmarshal(data, &resp); err != nil {
		return "", err
	}

	// Map folder names to JMAP standard roles for fallback matching
	folderRoles := map[string]string{
		"inbox":      "inbox",
		"drafts":     "drafts",
		"sent":       "sent",
		"sent items": "sent",
		"trash":      "trash",
		"junk":       "junk",
		"spam":       "junk",
		"archive":    "archive",
	}

	for _, mr := range resp.MethodResponses {
		if len(mr) < 2 {
			continue
		}
		var getResp struct {
			List []struct {
				ID   string  `json:"id"`
				Name string  `json:"name"`
				Role *string `json:"role"`
			} `json:"list"`
		}
		if err := json.Unmarshal(mr[1], &getResp); err != nil {
			continue
		}
		// First pass: exact name match
		for _, mb := range getResp.List {
			if strings.EqualFold(mb.Name, folder) {
				return mb.ID, nil
			}
		}
		// Second pass: match by JMAP role
		expectedRole := folderRoles[strings.ToLower(folder)]
		if expectedRole == "" {
			expectedRole = strings.ToLower(folder)
		}
		for _, mb := range getResp.List {
			if mb.Role != nil && strings.EqualFold(*mb.Role, expectedRole) {
				return mb.ID, nil
			}
		}
	}

	return "", fmt.Errorf("mailbox %s not found", folder)
}

// DownloadBlob fetches an attachment blob by its JMAP blobId.
func DownloadBlob(email, blobID string) ([]byte, string, error) {
	accountID, err := getJMAPAccountID(email)
	if err != nil {
		return nil, "", err
	}

	auth, err := userAuth(email)
	if err != nil {
		return nil, "", err
	}

	url := fmt.Sprintf("%s/jmap/download/%s/%s/attachment", stalwartAPI, accountID, blobID)
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, "", err
	}
	req.Header.Set("Authorization", auth)

	resp, err := stalwartClient.Do(req)
	if err != nil {
		return nil, "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		return nil, "", fmt.Errorf("download failed: %d", resp.StatusCode)
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, "", err
	}

	contentType := resp.Header.Get("Content-Type")
	if contentType == "" {
		contentType = "application/octet-stream"
	}

	return data, contentType, nil
}

// normalizeDate converts YYYY-MM-DD to RFC3339, passes through if already RFC3339.
func normalizeDate(s string) string {
	if t, err := time.Parse("2006-01-02", s); err == nil {
		return t.UTC().Format(time.RFC3339)
	}
	return s
}
