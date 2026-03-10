package db

import (
	"context"
	"log"
	"time"
)

// AuditEvent types
const (
	AuditLoginSuccess     = "login_success"
	AuditLoginFailed      = "login_failed"
	AuditAccountLocked    = "account_locked"
	AuditPasswordChanged  = "password_changed"
	AuditPasswordReset    = "password_reset"
	AuditRecoveryUsed     = "recovery_used"
	AuditAccountCreated   = "account_created"
	AuditAccountDeleted   = "account_deleted"
	AuditAccountExtended  = "account_extended"
	AuditCouponRedeemed   = "coupon_redeemed"
	AuditRecoveryEmailSet = "recovery_email_set"
	AuditForwardEmailSet  = "forward_email_set"
	AuditWhitelistChanged = "whitelist_changed"
	AuditAPIKeyUsed       = "api_key_used"
	AuditWebhookReceived  = "webhook_received"
	AuditWebhookBadSig    = "webhook_bad_signature"
	AuditPaymentActivated = "payment_activated"
)

func LogAudit(ctx context.Context, accountID *int, eventType, ipAddr, details string) {
	_, err := Pool.Exec(ctx,
		`INSERT INTO audit_log (account_id, event_type, ip_address, details) VALUES ($1, $2, $3, $4)`,
		accountID, eventType, ipAddr, details,
	)
	if err != nil {
		log.Printf("AUDIT LOG FAILED [%s] account=%v ip=%s: %v", eventType, accountID, ipAddr, err)
	}
}

// IncrementFailedLogins atomically bumps the counter and locks the account if threshold reached.
// Returns (isNowLocked, error).
func IncrementFailedLogins(ctx context.Context, accountID int) (bool, error) {
	const maxAttempts = 10
	const lockDuration = 30 * time.Minute

	lockUntil := time.Now().Add(lockDuration)

	// Single atomic query: increment counter (reset if lock expired),
	// then lock if threshold reached — all in one UPDATE + RETURNING.
	var attempts int
	err := Pool.QueryRow(ctx,
		`UPDATE accounts SET
			failed_login_attempts = CASE
				WHEN locked_until IS NOT NULL AND locked_until < NOW() THEN 1
				ELSE COALESCE(failed_login_attempts, 0) + 1
			END,
			locked_until = CASE
				WHEN locked_until IS NOT NULL AND locked_until < NOW() THEN NULL
				WHEN COALESCE(failed_login_attempts, 0) + 1 >= $2 THEN $3
				ELSE locked_until
			END,
			updated_at = NOW()
		 WHERE id = $1
		 RETURNING failed_login_attempts`, accountID, maxAttempts, lockUntil,
	).Scan(&attempts)
	if err != nil {
		return false, err
	}

	return attempts >= maxAttempts, nil
}

// ResetFailedLogins clears the counter on successful login.
func ResetFailedLogins(ctx context.Context, accountID int) error {
	_, err := Pool.Exec(ctx,
		`UPDATE accounts SET failed_login_attempts = 0, locked_until = NULL, updated_at = NOW() WHERE id = $1`,
		accountID)
	return err
}

// IsAccountLocked checks if an account is currently locked out.
func IsAccountLocked(ctx context.Context, accountID int) (bool, *time.Time, error) {
	var lockedUntil *time.Time
	err := Pool.QueryRow(ctx,
		`SELECT locked_until FROM accounts WHERE id = $1`, accountID,
	).Scan(&lockedUntil)
	if err != nil {
		return false, nil, err
	}

	if lockedUntil != nil && lockedUntil.After(time.Now()) {
		return true, lockedUntil, nil
	}
	return false, nil, nil
}
