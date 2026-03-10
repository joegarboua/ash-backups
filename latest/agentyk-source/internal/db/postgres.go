package db

import (
	"context"
	"fmt"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
)

var Pool *pgxpool.Pool

func Connect() error {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		return fmt.Errorf("DATABASE_URL environment variable is required")
	}

	var err error
	Pool, err = pgxpool.New(context.Background(), dsn)
	if err != nil {
		return fmt.Errorf("db connect: %w", err)
	}

	return Pool.Ping(context.Background())
}

func Migrate() error {
	schema := `
	CREATE TABLE IF NOT EXISTS accounts (
		id              SERIAL PRIMARY KEY,
		username        TEXT UNIQUE NOT NULL,
		email           TEXT UNIQUE NOT NULL,
		password_hash   TEXT NOT NULL,
		api_key         TEXT UNIQUE NOT NULL,
		status          TEXT NOT NULL DEFAULT 'pending_payment',
		invoice_id      TEXT,
		expires_at      TIMESTAMPTZ,
		webhook_url     TEXT,
		quota_used      INTEGER DEFAULT 0,
		created_at      TIMESTAMPTZ DEFAULT NOW(),
		updated_at      TIMESTAMPTZ DEFAULT NOW()
	);

	CREATE TABLE IF NOT EXISTS payments (
		id              SERIAL PRIMARY KEY,
		account_id      INTEGER REFERENCES accounts(id),
		invoice_id      TEXT UNIQUE NOT NULL,
		amount_eur      NUMERIC(10,2) NOT NULL,
		amount_btc      TEXT,
		status          TEXT NOT NULL DEFAULT 'pending',
		btcpay_url      TEXT,
		paid_at         TIMESTAMPTZ,
		created_at      TIMESTAMPTZ DEFAULT NOW()
	);

	CREATE TABLE IF NOT EXISTS help_requests (
		id              SERIAL PRIMARY KEY,
		email           TEXT,
		invoice_id      TEXT,
		message         TEXT NOT NULL,
		created_at      TIMESTAMPTZ DEFAULT NOW()
	);

	CREATE TABLE IF NOT EXISTS mail_log (
		id              SERIAL PRIMARY KEY,
		account_id      INTEGER REFERENCES accounts(id),
		direction       TEXT NOT NULL,
		from_addr       TEXT,
		to_addr         TEXT,
		subject         TEXT,
		created_at      TIMESTAMPTZ DEFAULT NOW()
	);

	CREATE TABLE IF NOT EXISTS coupons (
		id              SERIAL PRIMARY KEY,
		code            TEXT UNIQUE NOT NULL,
		duration_days   INTEGER NOT NULL DEFAULT 365,
		created_by      TEXT NOT NULL DEFAULT 'system',
		used_by         INTEGER REFERENCES accounts(id),
		used_at         TIMESTAMPTZ,
		created_at      TIMESTAMPTZ DEFAULT NOW()
	);

	CREATE INDEX IF NOT EXISTS idx_accounts_api_key ON accounts(api_key);
	CREATE INDEX IF NOT EXISTS idx_accounts_invoice ON accounts(invoice_id);
	CREATE INDEX IF NOT EXISTS idx_accounts_email ON accounts(email);
	CREATE INDEX IF NOT EXISTS idx_payments_invoice ON payments(invoice_id);
	CREATE INDEX IF NOT EXISTS idx_coupons_code ON coupons(code);

	ALTER TABLE accounts ADD COLUMN IF NOT EXISTS recovery_email TEXT;
	ALTER TABLE accounts ADD COLUMN IF NOT EXISTS forward_email TEXT;

	CREATE TABLE IF NOT EXISTS password_resets (
		id              SERIAL PRIMARY KEY,
		account_id      INTEGER REFERENCES accounts(id),
		token           TEXT UNIQUE NOT NULL,
		expires_at      TIMESTAMPTZ NOT NULL,
		used            BOOLEAN DEFAULT FALSE,
		created_at      TIMESTAMPTZ DEFAULT NOW()
	);
	CREATE INDEX IF NOT EXISTS idx_resets_token ON password_resets(token);

	ALTER TABLE accounts ADD COLUMN IF NOT EXISTS whitelist_enabled BOOLEAN DEFAULT FALSE;
	ALTER TABLE accounts ADD COLUMN IF NOT EXISTS whitelist_emails TEXT DEFAULT '';
	ALTER TABLE accounts ADD COLUMN IF NOT EXISTS recovery_seed_hash TEXT DEFAULT '';

	CREATE INDEX IF NOT EXISTS idx_accounts_status ON accounts(status);
	CREATE INDEX IF NOT EXISTS idx_accounts_expires_at ON accounts(expires_at);

	ALTER TABLE accounts ADD COLUMN IF NOT EXISTS failed_login_attempts INTEGER DEFAULT 0;
	ALTER TABLE accounts ADD COLUMN IF NOT EXISTS locked_until TIMESTAMPTZ;

	CREATE TABLE IF NOT EXISTS audit_log (
		id              SERIAL PRIMARY KEY,
		account_id      INTEGER REFERENCES accounts(id) ON DELETE SET NULL,
		event_type      TEXT NOT NULL,
		ip_address      TEXT,
		details         TEXT,
		created_at      TIMESTAMPTZ DEFAULT NOW()
	);
	CREATE INDEX IF NOT EXISTS idx_audit_log_account_id ON audit_log(account_id);
	CREATE INDEX IF NOT EXISTS idx_audit_log_event_type ON audit_log(event_type);
	CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON audit_log(created_at);
	`

	_, err := Pool.Exec(context.Background(), schema)
	return err
}

func Close() {
	if Pool != nil {
		Pool.Close()
	}
}
