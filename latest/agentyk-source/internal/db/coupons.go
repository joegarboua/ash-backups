package db

import (
	"context"
	"fmt"
	"time"
)

type Coupon struct {
	ID           int
	Code         string
	DurationDays int
	CreatedBy    string
	UsedBy       *int
	UsedAt       *time.Time
	CreatedAt    time.Time
}

func ValidateCoupon(ctx context.Context, code string) (*Coupon, error) {
	c := &Coupon{}
	err := Pool.QueryRow(ctx,
		`SELECT id, code, duration_days, created_by, used_by, used_at, created_at
		 FROM coupons WHERE code = $1 AND used_by IS NULL`, code,
	).Scan(&c.ID, &c.Code, &c.DurationDays, &c.CreatedBy, &c.UsedBy, &c.UsedAt, &c.CreatedAt)
	if err != nil {
		return nil, err
	}
	return c, nil
}

func RedeemCouponAtomic(ctx context.Context, couponID, accountID, durationDays int, invoiceID string) error {
	tx, err := Pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	// Mark coupon used (AND used_by IS NULL prevents race condition)
	tag, err := tx.Exec(ctx,
		`UPDATE coupons SET used_by = $1, used_at = NOW() WHERE id = $2 AND used_by IS NULL`,
		accountID, couponID)
	if err != nil {
		return fmt.Errorf("redeem coupon: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return fmt.Errorf("coupon already used")
	}

	// Activate account
	_, err = tx.Exec(ctx,
		`UPDATE accounts SET status = 'active', expires_at = NOW() + make_interval(days => $1), updated_at = NOW()
		 WHERE id = $2`,
		durationDays, accountID)
	if err != nil {
		return fmt.Errorf("activate account: %w", err)
	}

	// Mark payment paid
	_, err = tx.Exec(ctx,
		`UPDATE payments SET status = 'paid', paid_at = NOW() WHERE invoice_id = $1`,
		invoiceID)
	if err != nil {
		return fmt.Errorf("mark payment: %w", err)
	}

	return tx.Commit(ctx)
}

func CreateCoupon(ctx context.Context, code, createdBy string, durationDays int) error {
	_, err := Pool.Exec(ctx,
		`INSERT INTO coupons (code, duration_days, created_by) VALUES ($1, $2, $3)`,
		code, durationDays, createdBy,
	)
	return err
}
