package db

import (
	"context"
	"time"
)

type Payment struct {
	ID        int
	AccountID int
	InvoiceID string
	AmountEUR float64
	AmountBTC *string
	Status    string
	BtcpayURL *string
	PaidAt    *time.Time
	CreatedAt time.Time
}

func CreatePayment(ctx context.Context, accountID int, invoiceID string, amountEUR float64, amountBTC, btcpayURL string) error {
	_, err := Pool.Exec(ctx,
		`INSERT INTO payments (account_id, invoice_id, amount_eur, amount_btc, status, btcpay_url)
		 VALUES ($1, $2, $3, $4, 'pending', $5)`,
		accountID, invoiceID, amountEUR, amountBTC, btcpayURL,
	)
	return err
}

func MarkPaymentPaid(ctx context.Context, invoiceID string) error {
	_, err := Pool.Exec(ctx,
		`UPDATE payments SET status = 'paid', paid_at = NOW() WHERE invoice_id = $1`,
		invoiceID,
	)
	return err
}

// CreatePaymentAndUpdateInvoice creates a payment record and updates the account's invoice_id atomically.
func CreatePaymentAndUpdateInvoice(ctx context.Context, accountID int, invoiceID string, amountEUR float64, amountBTC, btcpayURL string) error {
	tx, err := Pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	_, err = tx.Exec(ctx,
		`INSERT INTO payments (account_id, invoice_id, amount_eur, amount_btc, status, btcpay_url)
		 VALUES ($1, $2, $3, $4, 'pending', $5)`,
		accountID, invoiceID, amountEUR, amountBTC, btcpayURL)
	if err != nil {
		return err
	}

	_, err = tx.Exec(ctx,
		`UPDATE accounts SET invoice_id = $1, updated_at = NOW() WHERE id = $2`,
		invoiceID, accountID)
	if err != nil {
		return err
	}

	return tx.Commit(ctx)
}

func GetPaymentByInvoice(ctx context.Context, invoiceID string) (*Payment, error) {
	p := &Payment{}
	err := Pool.QueryRow(ctx,
		`SELECT id, account_id, invoice_id, amount_eur, amount_btc, status, btcpay_url, paid_at, created_at
		 FROM payments WHERE invoice_id = $1`, invoiceID,
	).Scan(&p.ID, &p.AccountID, &p.InvoiceID, &p.AmountEUR, &p.AmountBTC, &p.Status, &p.BtcpayURL, &p.PaidAt, &p.CreatedAt)
	if err != nil {
		return nil, err
	}
	return p, nil
}

func SaveHelpRequest(ctx context.Context, email, invoiceID, message string) error {
	_, err := Pool.Exec(ctx,
		`INSERT INTO help_requests (email, invoice_id, message) VALUES ($1, $2, $3)`,
		email, invoiceID, message,
	)
	return err
}
