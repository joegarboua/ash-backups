"""AgentYK — Database models and Dovecot passwd-file management."""

import aiosqlite
import os
import secrets
import string
from datetime import datetime, timedelta

DB_PATH = os.environ.get("AGENTYK_DB", "/opt/agentyk/agentyk.db")
DOVECOT_PASSWD = os.environ.get("DOVECOT_PASSWD", "/etc/dovecot/users")
POSTFIX_VMAILBOX = os.environ.get("POSTFIX_VMAILBOX", "/etc/postfix/virtual_mailbox_maps")

SCHEMA = """
CREATE TABLE IF NOT EXISTS accounts (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    address       TEXT UNIQUE NOT NULL,
    api_key       TEXT UNIQUE NOT NULL,
    temp_password TEXT NOT NULL,
    active        INTEGER NOT NULL DEFAULT 0,
    expires       TEXT,
    quota_total   INTEGER NOT NULL DEFAULT 1000,
    quota_used    INTEGER NOT NULL DEFAULT 0,
    webhook_url   TEXT,
    created_at    TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS payments (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id  INTEGER NOT NULL REFERENCES accounts(id),
    invoice_id  TEXT UNIQUE NOT NULL,
    amount_btc  REAL,
    amount_eur  REAL,
    status      TEXT NOT NULL DEFAULT 'pending',
    created_at  TEXT NOT NULL,
    paid_at     TEXT
);
"""

_PW_CHARS = string.ascii_letters + string.digits + "-_"


def _gen_password(length: int = 16) -> str:
    return "".join(secrets.choice(_PW_CHARS) for _ in range(length))


def _dovecot_line(address: str, password: str, enabled: bool) -> str:
    """Produce a Dovecot passwd-file line.

    Disabled (pre-payment): !localpart@domain:{PLAIN}password
    Enabled (post-payment):  localpart@domain:{PLAIN}password
    """
    prefix = "" if enabled else "!"
    return f"{prefix}{address}:{{PLAIN}}{password}\n"


def _update_dovecot(address: str, password: str, enabled: bool) -> None:
    """Add or update one entry in the Dovecot passwd file."""
    lines = []
    updated = False
    try:
        with open(DOVECOT_PASSWD, "r") as f:
            for line in f:
                # Match both enabled and disabled variants of this address
                stripped = line.lstrip("!")
                if stripped.startswith(address + ":"):
                    lines.append(_dovecot_line(address, password, enabled))
                    updated = True
                else:
                    lines.append(line)
    except FileNotFoundError:
        pass

    if not updated:
        lines.append(_dovecot_line(address, password, enabled))

    with open(DOVECOT_PASSWD, "w") as f:
        f.writelines(lines)


def _add_postfix_vmailbox(address: str) -> None:
    """Add mailbox entry to Postfix virtual mailbox maps."""
    local = address.split("@")[0]
    domain = address.split("@")[1]
    entry = f"{address} {domain}/{local}/Maildir/\n"
    try:
        with open(POSTFIX_VMAILBOX, "r") as f:
            if address in f.read():
                return
    except FileNotFoundError:
        pass
    with open(POSTFIX_VMAILBOX, "a") as f:
        f.write(entry)
    os.system(f"postmap {POSTFIX_VMAILBOX} 2>/dev/null || true")


async def init_db():
    async with aiosqlite.connect(DB_PATH) as db:
        await db.executescript(SCHEMA)
        await db.commit()


async def create_account(local_part: str, domain: str) -> dict:
    address = f"{local_part}@{domain}"
    api_key = secrets.token_urlsafe(32)
    temp_password = _gen_password(16)
    now = datetime.utcnow().isoformat()

    async with aiosqlite.connect(DB_PATH) as db:
        try:
            await db.execute(
                "INSERT INTO accounts (address, api_key, temp_password, created_at) VALUES (?, ?, ?, ?)",
                (address, api_key, temp_password, now),
            )
            await db.commit()
        except Exception as e:
            if "UNIQUE constraint failed" in str(e):
                raise ValueError(f"Username already taken: {local_part}")
            raise

    # Register in Dovecot (disabled — ! prefix until payment)
    try:
        _update_dovecot(address, temp_password, enabled=False)
    except Exception:
        pass  # Non-fatal during pre-build/testing

    # Register in Postfix virtual mailbox maps
    try:
        _add_postfix_vmailbox(address)
    except Exception:
        pass  # Non-fatal during pre-build/testing

    return {"id": None, "address": address, "api_key": api_key, "temp_password": temp_password}


async def get_account_by_key(api_key: str) -> dict | None:
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute(
            "SELECT * FROM accounts WHERE api_key = ?", (api_key,)
        ) as cur:
            row = await cur.fetchone()
            return dict(row) if row else None


async def get_account_by_invoice(email_addr: str) -> dict | None:
    """Get account by email address (used in BTCPay webhook)."""
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute(
            "SELECT * FROM accounts WHERE address = ?", (email_addr,)
        ) as cur:
            row = await cur.fetchone()
            return dict(row) if row else None


async def activate_account(account_id: int, address: str, days: int = 30):
    """Activate account: update DB, enable Dovecot entry (remove ! prefix)."""
    expires = (datetime.utcnow() + timedelta(days=days)).isoformat()

    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute(
            "SELECT temp_password FROM accounts WHERE id = ?", (account_id,)
        ) as cur:
            row = await cur.fetchone()
        if not row:
            return

        temp_password = row["temp_password"]
        await db.execute(
            "UPDATE accounts SET active = 1, expires = ? WHERE id = ?",
            (expires, account_id),
        )
        await db.commit()

    # Enable Dovecot entry (remove ! prefix)
    try:
        _update_dovecot(address, temp_password, enabled=True)
        os.system("doveadm reload 2>/dev/null || true")
    except Exception:
        pass


async def set_webhook(account_id: int, url: str | None):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute(
            "UPDATE accounts SET webhook_url = ? WHERE id = ?",
            (url, account_id),
        )
        await db.commit()
