"""AgentYK — FastAPI application.

Email for silicon & carbon life forms.
Auth: X-API-Key header. No passwords. No CAPTCHA. No KYC.
Payment: Bitcoin via BTCPay Server.

Registration flow:
  1. POST /register -> account created, temp_password returned, Dovecot entry disabled (! prefix)
  2. User pays BTC invoice
  3. BTCPay calls POST /internal/btcpay-webhook -> account activated (! prefix removed from Dovecot)
"""

import os
import httpx
from contextlib import asynccontextmanager
from fastapi import FastAPI, Header, HTTPException, Depends, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel
from typing import Optional

from models import (
    init_db, create_account, get_account_by_key,
    set_webhook, activate_account, get_account_by_invoice, DB_PATH,
)
import mail as mail_ops

DOMAIN = os.environ.get("AGENTYK_DOMAIN", "agentyk.ru")
BTCPAY_URL = os.environ.get("BTCPAY_URL", "")
BTCPAY_KEY = os.environ.get("BTCPAY_KEY", "")
BTCPAY_STORE_ID = os.environ.get("BTCPAY_STORE_ID", "default")
PRICE_EUR = float(os.environ.get("AGENTYK_PRICE_EUR", "10"))

templates = Jinja2Templates(directory=os.path.join(os.path.dirname(__file__), "../web/templates"))


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield


app = FastAPI(
    title="AgentYK",
    description="Email for silicon & carbon life forms. API-first. Bitcoin payments.",
    version="1.0.0",
    lifespan=lifespan,
)


# --- Auth dependency ---

async def require_auth(x_api_key: str = Header(...)) -> dict:
    account = await get_account_by_key(x_api_key)
    if not account:
        raise HTTPException(status_code=401, detail="Invalid API key")
    if not account["active"]:
        raise HTTPException(status_code=402, detail="Account not active — payment required")
    return account


# --- Request/Response models ---

class RegisterRequest(BaseModel):
    username: str

class RegisterResponse(BaseModel):
    email: str
    temp_password: str
    api_key: str
    invoice_id: Optional[str] = None
    btcpay_url: Optional[str] = None
    amount_btc: Optional[float] = None
    amount_eur: float

class SendRequest(BaseModel):
    to: str
    subject: str
    body: str

class WebhookRequest(BaseModel):
    url: Optional[str] = None


# --- Pages ---

@app.get("/", response_class=HTMLResponse)
async def landing(request: Request):
    return templates.TemplateResponse("register.html", {"request": request, "domain": DOMAIN})

@app.get("/help", response_class=HTMLResponse)
async def help_page(request: Request):
    return templates.TemplateResponse("help.html", {"request": request, "domain": DOMAIN})

@app.get("/register/status-page/{invoice_id}", response_class=HTMLResponse)
async def status_page(request: Request, invoice_id: str):
    email_addr = ""
    status = "pending_payment"
    login_ready = False

    if BTCPAY_URL and BTCPAY_KEY:
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                r = await client.get(
                    f"{BTCPAY_URL}/api/v1/stores/{BTCPAY_STORE_ID}/invoices/{invoice_id}",
                    headers={"Authorization": f"token {BTCPAY_KEY}"},
                )
                inv = r.json()
                email_addr = (inv.get("metadata") or {}).get("email", "")
                inv_status = inv.get("status", "")
                if inv_status in ("Settled", "Complete"):
                    status = "active"
                    login_ready = True
                elif inv_status == "Expired":
                    status = "expired"
        except Exception:
            pass

    return templates.TemplateResponse("status.html", {
        "request": request,
        "invoice_id": invoice_id,
        "email": email_addr,
        "status": status,
        "login_ready": login_ready,
        "domain": DOMAIN,
    })


# --- Health ---

@app.get("/health")
async def health():
    return {"status": "ok", "domain": DOMAIN}


# --- Registration ---

@app.post("/register", response_model=RegisterResponse)
async def register(req: RegisterRequest):
    """Create account. Returns temp_password + BTC invoice. Login enabled after payment."""
    username = req.username.lower().strip()
    if not username or not username.replace("-", "").replace("_", "").replace(".", "").isalnum():
        raise HTTPException(status_code=400, detail="Invalid username — alphanumeric, hyphens, underscores only")
    if len(username) < 2 or len(username) > 32:
        raise HTTPException(status_code=400, detail="Username must be 2-32 characters")

    acc = await create_account(username, DOMAIN)

    # Get BTC amount from CoinGecko
    btc_amount = None
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            r = await client.get(
                "https://api.coingecko.com/api/v3/simple/price",
                params={"ids": "bitcoin", "vs_currencies": "eur"},
            )
            btc_eur = r.json()["bitcoin"]["eur"]
            btc_amount = round(PRICE_EUR / btc_eur, 8)
    except Exception:
        pass

    # Create BTCPay invoice
    invoice_id = None
    btcpay_url = None
    if BTCPAY_URL and BTCPAY_KEY:
        try:
            async with httpx.AsyncClient(timeout=15) as client:
                r = await client.post(
                    f"{BTCPAY_URL}/api/v1/stores/{BTCPAY_STORE_ID}/invoices",
                    headers={"Authorization": f"token {BTCPAY_KEY}"},
                    json={
                        "amount": str(PRICE_EUR),
                        "currency": "EUR",
                        "metadata": {"email": acc["address"], "account_id": acc["id"]},
                        "checkout": {
                            "expirationMinutes": 60,
                            "redirectURL": f"https://{DOMAIN}/register/status-page/{{InvoiceId}}",
                        },
                    },
                )
                inv = r.json()
                invoice_id = inv.get("id")
                btcpay_url = inv.get("checkoutLink")
        except Exception:
            pass

    return RegisterResponse(
        email=acc["address"],
        temp_password=acc["temp_password"],
        api_key=acc["api_key"],
        invoice_id=invoice_id,
        btcpay_url=btcpay_url,
        amount_btc=btc_amount,
        amount_eur=PRICE_EUR,
    )


# --- Account status ---

@app.get("/account/status")
async def account_status(account: dict = Depends(require_auth)):
    return {
        "address": account["address"],
        "active": bool(account["active"]),
        "expires": account["expires"],
        "quota_total": account["quota_total"],
        "quota_remaining": account["quota_total"] - account["quota_used"],
    }


# --- Mail ---

@app.get("/mail")
async def list_mail(account: dict = Depends(require_auth)):
    messages = mail_ops.list_inbox(account["address"])
    return {"messages": messages, "count": len(messages)}


@app.get("/mail/{msg_id}")
async def read_mail(msg_id: str, account: dict = Depends(require_auth)):
    msg = mail_ops.read_message(account["address"], msg_id)
    if not msg:
        raise HTTPException(status_code=404, detail="Message not found")
    return msg


@app.delete("/mail/{msg_id}")
async def delete_mail(msg_id: str, account: dict = Depends(require_auth)):
    ok = mail_ops.delete_message(account["address"], msg_id)
    if not ok:
        raise HTTPException(status_code=404, detail="Message not found")
    return {"deleted": msg_id}


@app.post("/mail/send")
async def send_mail(req: SendRequest, account: dict = Depends(require_auth)):
    remaining = account["quota_total"] - account["quota_used"]
    if remaining <= 0:
        raise HTTPException(status_code=429, detail="Monthly quota exhausted")

    ok = mail_ops.send_email(
        from_addr=account["address"],
        to_addr=req.to,
        subject=req.subject,
        body=req.body,
    )
    if not ok:
        raise HTTPException(status_code=502, detail="Mail delivery failed")

    import aiosqlite
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute(
            "UPDATE accounts SET quota_used = quota_used + 1 WHERE id = ?",
            (account["id"],),
        )
        await db.commit()

    return {"sent": True, "to": req.to, "quota_remaining": remaining - 1}


# --- Webhooks ---

@app.post("/mail/webhook")
async def set_webhook_url(req: WebhookRequest, account: dict = Depends(require_auth)):
    await set_webhook(account["id"], req.url)
    return {"webhook": req.url}

@app.delete("/mail/webhook")
async def delete_webhook(account: dict = Depends(require_auth)):
    await set_webhook(account["id"], None)
    return {"webhook": None}


# --- Invoice status poll (for status.html page) ---

@app.get("/register/invoice/{invoice_id}")
async def invoice_status(invoice_id: str):
    """Poll BTCPay for invoice status. Used by status.html JS."""
    if not BTCPAY_URL or not BTCPAY_KEY:
        return {"status": "unknown", "error": "BTCPay not configured"}
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            r = await client.get(
                f"{BTCPAY_URL}/api/v1/stores/{BTCPAY_STORE_ID}/invoices/{invoice_id}",
                headers={"Authorization": f"token {BTCPAY_KEY}"},
            )
            inv = r.json()
            return {"status": inv.get("status"), "additional_status": inv.get("additionalStatus")}
    except Exception as e:
        return {"status": "error", "error": str(e)}


# --- BTCPay webhook (activates account on payment) ---

@app.post("/internal/btcpay-webhook")
async def btcpay_webhook(payload: dict):
    """Called by BTCPay Server when invoice is settled. Activates the account."""
    if payload.get("type") not in ("InvoiceSettled", "InvoicePaymentSettled"):
        return {"ok": True}

    email_addr = (payload.get("metadata") or {}).get("email")
    if not email_addr:
        return {"ok": True}

    acc = await get_account_by_invoice(email_addr)
    if acc:
        await activate_account(acc["id"], acc["address"])

    return {"ok": True, "activated": email_addr}
