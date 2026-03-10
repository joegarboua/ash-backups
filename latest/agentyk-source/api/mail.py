"""AgentYK — Maildir read/send operations."""

import os
import smtplib
import mailbox
import email.utils
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import List

DOMAIN = os.environ.get("AGENTYK_DOMAIN", "agentyk.ru")
MAILDIR_BASE = f"/var/mail/vhosts/{DOMAIN}"
SMTP_HOST = "localhost"
SMTP_PORT = 25


def _maildir_path(address: str) -> str:
    local = address.split("@")[0]
    return os.path.join(MAILDIR_BASE, local, "Maildir")


def list_inbox(address: str) -> List[dict]:
    path = _maildir_path(address)
    if not os.path.exists(path):
        return []
    md = mailbox.Maildir(path, factory=None, create=False)
    messages = []
    for key, msg in md.items():
        messages.append({
            "id": key,
            "from": msg.get("From", ""),
            "to": msg.get("To", ""),
            "subject": msg.get("Subject", ""),
            "date": msg.get("Date", ""),
            "size": len(msg.as_bytes()),
        })
    messages.sort(key=lambda m: m.get("date", ""), reverse=True)
    return messages


def read_message(address: str, msg_id: str) -> dict | None:
    path = _maildir_path(address)
    if not os.path.exists(path):
        return None
    md = mailbox.Maildir(path, factory=None, create=False)
    try:
        msg = md[msg_id]
    except KeyError:
        return None

    body = ""
    if msg.is_multipart():
        for part in msg.walk():
            if part.get_content_type() == "text/plain":
                body = part.get_payload(decode=True).decode("utf-8", errors="replace")
                break
    else:
        body = msg.get_payload(decode=True).decode("utf-8", errors="replace")

    return {
        "id": msg_id,
        "from": msg.get("From", ""),
        "to": msg.get("To", ""),
        "subject": msg.get("Subject", ""),
        "date": msg.get("Date", ""),
        "body": body,
    }


def delete_message(address: str, msg_id: str) -> bool:
    path = _maildir_path(address)
    if not os.path.exists(path):
        return False
    md = mailbox.Maildir(path, factory=None, create=False)
    try:
        md.remove(msg_id)
        md.flush()
        return True
    except KeyError:
        return False


def send_email(from_addr: str, to_addr: str, subject: str, body: str) -> bool:
    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = from_addr
    msg["To"] = to_addr
    msg["Date"] = email.utils.formatdate()
    msg.attach(MIMEText(body, "plain"))
    try:
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as smtp:
            smtp.sendmail(from_addr, [to_addr], msg.as_string())
        return True
    except Exception:
        return False
