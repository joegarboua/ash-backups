package db

import (
	"context"
	"fmt"
	"time"
)

type Account struct {
	ID            int
	Username      string
	Email         string
	PasswordHash  string
	APIKey        string
	Status        string
	InvoiceID     *string
	ExpiresAt     *time.Time
	WebhookURL    *string
	RecoveryEmail *string
	ForwardEmail     *string
	WhitelistEnabled bool
	WhitelistEmails  string
	RecoverySeedHash string
	QuotaUsed        int
	CreatedAt        time.Time
	UpdatedAt        time.Time
}

func CreateAccount(ctx context.Context, username, email, passwordHash, apiKey, invoiceID string) (*Account, error) {
	a := &Account{}
	err := Pool.QueryRow(ctx,
		`INSERT INTO accounts (username, email, password_hash, api_key, invoice_id, status)
		 VALUES ($1, $2, $3, $4, $5, 'pending_payment')
		 RETURNING id, username, email, password_hash, api_key, status, invoice_id, created_at`,
		username, email, passwordHash, apiKey, invoiceID,
	).Scan(&a.ID, &a.Username, &a.Email, &a.PasswordHash, &a.APIKey, &a.Status, &a.InvoiceID, &a.CreatedAt)
	if err != nil {
		return nil, err
	}
	return a, nil
}

func UsernameExists(ctx context.Context, username string) (bool, error) {
	var exists bool
	err := Pool.QueryRow(ctx,
		`SELECT EXISTS(SELECT 1 FROM accounts WHERE username = $1)`, username,
	).Scan(&exists)
	return exists, err
}

func GetAccountByAPIKey(ctx context.Context, apiKey string) (*Account, error) {
	a := &Account{}
	err := Pool.QueryRow(ctx,
		`SELECT id, username, email, password_hash, api_key, status, invoice_id, expires_at, webhook_url, recovery_email, forward_email, whitelist_enabled, whitelist_emails, recovery_seed_hash, quota_used, created_at, updated_at
		 FROM accounts WHERE api_key = $1`, apiKey,
	).Scan(&a.ID, &a.Username, &a.Email, &a.PasswordHash, &a.APIKey, &a.Status, &a.InvoiceID, &a.ExpiresAt, &a.WebhookURL, &a.RecoveryEmail, &a.ForwardEmail, &a.WhitelistEnabled, &a.WhitelistEmails, &a.RecoverySeedHash, &a.QuotaUsed, &a.CreatedAt, &a.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return a, nil
}

func GetAccountByEmail(ctx context.Context, email string) (*Account, error) {
	a := &Account{}
	err := Pool.QueryRow(ctx,
		`SELECT id, username, email, password_hash, api_key, status, invoice_id, expires_at, webhook_url, recovery_email, forward_email, whitelist_enabled, whitelist_emails, recovery_seed_hash, quota_used, created_at, updated_at
		 FROM accounts WHERE email = $1`, email,
	).Scan(&a.ID, &a.Username, &a.Email, &a.PasswordHash, &a.APIKey, &a.Status, &a.InvoiceID, &a.ExpiresAt, &a.WebhookURL, &a.RecoveryEmail, &a.ForwardEmail, &a.WhitelistEnabled, &a.WhitelistEmails, &a.RecoverySeedHash, &a.QuotaUsed, &a.CreatedAt, &a.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return a, nil
}

func GetAccountByInvoice(ctx context.Context, invoiceID string) (*Account, error) {
	a := &Account{}
	err := Pool.QueryRow(ctx,
		`SELECT id, username, email, password_hash, api_key, status, invoice_id, expires_at, webhook_url, recovery_email, forward_email, whitelist_enabled, whitelist_emails, recovery_seed_hash, quota_used, created_at, updated_at
		 FROM accounts WHERE invoice_id = $1`, invoiceID,
	).Scan(&a.ID, &a.Username, &a.Email, &a.PasswordHash, &a.APIKey, &a.Status, &a.InvoiceID, &a.ExpiresAt, &a.WebhookURL, &a.RecoveryEmail, &a.ForwardEmail, &a.WhitelistEnabled, &a.WhitelistEmails, &a.RecoverySeedHash, &a.QuotaUsed, &a.CreatedAt, &a.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return a, nil
}

func UpdatePassword(ctx context.Context, accountID int, newHash string) error {
	_, err := Pool.Exec(ctx,
		`UPDATE accounts SET password_hash = $1, updated_at = NOW() WHERE id = $2`,
		newHash, accountID,
	)
	return err
}

func SetWebhook(ctx context.Context, accountID int, url string) error {
	_, err := Pool.Exec(ctx,
		`UPDATE accounts SET webhook_url = $1, updated_at = NOW() WHERE id = $2`,
		url, accountID,
	)
	return err
}

func IncrementQuota(ctx context.Context, accountID int) error {
	_, err := Pool.Exec(ctx,
		`UPDATE accounts SET quota_used = quota_used + 1, updated_at = NOW() WHERE id = $1`,
		accountID,
	)
	return err
}

func CreatePasswordReset(ctx context.Context, accountID int, token string, expiresAt time.Time) error {
	_, err := Pool.Exec(ctx,
		`INSERT INTO password_resets (account_id, token, expires_at) VALUES ($1, $2, $3)`,
		accountID, token, expiresAt,
	)
	return err
}

func ValidateResetToken(ctx context.Context, token string) (*Account, error) {
	a := &Account{}
	err := Pool.QueryRow(ctx,
		`SELECT a.id, a.username, a.email, a.password_hash, a.api_key, a.status, a.invoice_id, a.expires_at, a.webhook_url, a.recovery_email, a.forward_email, a.whitelist_enabled, a.whitelist_emails, a.recovery_seed_hash, a.quota_used, a.created_at, a.updated_at
		 FROM password_resets r JOIN accounts a ON r.account_id = a.id
		 WHERE r.token = $1 AND r.used = FALSE AND r.expires_at > NOW()`, token,
	).Scan(&a.ID, &a.Username, &a.Email, &a.PasswordHash, &a.APIKey, &a.Status, &a.InvoiceID, &a.ExpiresAt, &a.WebhookURL, &a.RecoveryEmail, &a.ForwardEmail, &a.WhitelistEnabled, &a.WhitelistEmails, &a.RecoverySeedHash, &a.QuotaUsed, &a.CreatedAt, &a.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return a, nil
}

func MarkResetUsed(ctx context.Context, token string) error {
	_, err := Pool.Exec(ctx,
		`UPDATE password_resets SET used = TRUE WHERE token = $1`, token,
	)
	return err
}

// ResetPasswordAtomic marks token used and updates password in one transaction.
// Uses RowsAffected check to prevent race condition where two concurrent requests
// both pass ValidateResetToken and attempt to use the same token.
func ResetPasswordAtomic(ctx context.Context, accountID int, newHash, token string) error {
	tx, err := Pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	// Mark token used FIRST — the AND used = FALSE + RowsAffected check
	// ensures only one concurrent request succeeds
	tag, err := tx.Exec(ctx,
		`UPDATE password_resets SET used = TRUE WHERE token = $1 AND used = FALSE`, token)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return fmt.Errorf("reset token already used")
	}

	_, err = tx.Exec(ctx,
		`UPDATE accounts SET password_hash = $1, updated_at = NOW() WHERE id = $2`,
		newHash, accountID)
	if err != nil {
		return err
	}

	return tx.Commit(ctx)
}

func SetForwardEmail(ctx context.Context, accountID int, forwardEmail *string) error {
	_, err := Pool.Exec(ctx,
		`UPDATE accounts SET forward_email = $1, updated_at = NOW() WHERE id = $2`,
		forwardEmail, accountID,
	)
	return err
}

func SetRecoveryEmail(ctx context.Context, accountID int, recoveryEmail string) error {
	_, err := Pool.Exec(ctx,
		`UPDATE accounts SET recovery_email = $1, updated_at = NOW() WHERE id = $2`,
		recoveryEmail, accountID,
	)
	return err
}

func ExtendAccount(ctx context.Context, accountID int, days int) error {
	_, err := Pool.Exec(ctx,
		`UPDATE accounts SET
			status = 'active',
			expires_at = CASE
				WHEN expires_at IS NOT NULL AND expires_at > NOW() THEN expires_at + make_interval(days => $1)
				ELSE NOW() + make_interval(days => $1)
			END,
			updated_at = NOW()
		 WHERE id = $2`,
		days, accountID,
	)
	return err
}

// ExtendWithCouponAtomic extends account and marks coupon used in one transaction.
func ExtendWithCouponAtomic(ctx context.Context, accountID, couponID, durationDays int) error {
	tx, err := Pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	// Mark coupon used (AND used_by IS NULL prevents race condition)
	tag, err := tx.Exec(ctx,
		`UPDATE coupons SET used_by = $1, used_at = NOW() WHERE id = $2 AND used_by IS NULL`,
		accountID, couponID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return fmt.Errorf("coupon already used")
	}

	// Extend account
	_, err = tx.Exec(ctx,
		`UPDATE accounts SET
			status = 'active',
			expires_at = CASE
				WHEN expires_at IS NOT NULL AND expires_at > NOW() THEN expires_at + make_interval(days => $1)
				ELSE NOW() + make_interval(days => $1)
			END,
			updated_at = NOW()
		 WHERE id = $2`,
		durationDays, accountID)
	if err != nil {
		return err
	}

	return tx.Commit(ctx)
}

// ActivateWithPaymentAtomic activates account and marks payment paid in one transaction.
func ActivateWithPaymentAtomic(ctx context.Context, invoiceID string) error {
	tx, err := Pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	tag, err := tx.Exec(ctx,
		`UPDATE accounts SET status = 'active', expires_at = NOW() + INTERVAL '365 days', updated_at = NOW()
		 WHERE invoice_id = $1 AND status != 'active'`, invoiceID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return fmt.Errorf("account not found or already active for invoice %s", invoiceID)
	}

	_, err = tx.Exec(ctx,
		`UPDATE payments SET status = 'paid', paid_at = NOW() WHERE invoice_id = $1`, invoiceID)
	if err != nil {
		return err
	}

	return tx.Commit(ctx)
}

func SetRecoverySeedHash(ctx context.Context, accountID int, hash string) error {
	_, err := Pool.Exec(ctx,
		`UPDATE accounts SET recovery_seed_hash = $1, updated_at = NOW() WHERE id = $2`,
		hash, accountID,
	)
	return err
}

func GetAccountByInvoicePayment(ctx context.Context, email, invoiceID string) (*Account, error) {
	a := &Account{}
	err := Pool.QueryRow(ctx,
		`SELECT a.id, a.username, a.email, a.password_hash, a.api_key, a.status, a.invoice_id, a.expires_at, a.webhook_url, a.recovery_email, a.forward_email, a.whitelist_enabled, a.whitelist_emails, a.recovery_seed_hash, a.quota_used, a.created_at, a.updated_at
		 FROM accounts a JOIN payments p ON p.account_id = a.id
		 WHERE a.email = $1 AND p.invoice_id = $2 AND p.status = 'paid'`, email, invoiceID,
	).Scan(&a.ID, &a.Username, &a.Email, &a.PasswordHash, &a.APIKey, &a.Status, &a.InvoiceID, &a.ExpiresAt, &a.WebhookURL, &a.RecoveryEmail, &a.ForwardEmail, &a.WhitelistEnabled, &a.WhitelistEmails, &a.RecoverySeedHash, &a.QuotaUsed, &a.CreatedAt, &a.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return a, nil
}

func SetWhitelist(ctx context.Context, accountID int, enabled bool, emails string) error {
	_, err := Pool.Exec(ctx,
		`UPDATE accounts SET whitelist_enabled = $1, whitelist_emails = $2, updated_at = NOW() WHERE id = $3`,
		enabled, emails, accountID,
	)
	return err
}

func DeleteAccount(ctx context.Context, accountID int) error {
	tx, err := Pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	_, err = tx.Exec(ctx, `DELETE FROM mail_log WHERE account_id = $1`, accountID)
	if err != nil {
		return err
	}
	_, err = tx.Exec(ctx, `UPDATE coupons SET used_by = NULL, used_at = NULL WHERE used_by = $1`, accountID)
	if err != nil {
		return err
	}
	_, err = tx.Exec(ctx, `DELETE FROM password_resets WHERE account_id = $1`, accountID)
	if err != nil {
		return err
	}
	_, err = tx.Exec(ctx, `DELETE FROM payments WHERE account_id = $1`, accountID)
	if err != nil {
		return err
	}
	_, err = tx.Exec(ctx, `DELETE FROM accounts WHERE id = $1`, accountID)
	if err != nil {
		return err
	}

	return tx.Commit(ctx)
}
