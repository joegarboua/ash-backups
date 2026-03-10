#!/bin/bash
# AgentYK — Master Deploy Script (Go + PostgreSQL)
# Run on VPS as root.
# Usage: bash deploy.sh <server_ip> [domain]
# Example: bash deploy.sh 91.92.109.84
# Example: bash deploy.sh 91.92.109.84 agentyk.ru

set -euo pipefail

SERVER_IP="${1:?Usage: $0 <server_ip> [domain]}"
DOMAIN="${2:-}"
API_DIR="/opt/agentyk"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
DB_USER="agentyk"
DB_NAME="agentyk"
DB_PASS="$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 24)"

echo "=== AgentYK Deploy ==="
echo "Server IP: $SERVER_IP"
echo "Domain:    ${DOMAIN:-none (IP-only mode)}"
echo "========================"

# --- System packages ---
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    postgresql postgresql-client \
    nginx \
    ufw

echo "[1/7] Packages installed."

# --- Firewall ---
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
echo "[2/7] Firewall configured."

# --- PostgreSQL ---
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
fi
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1; then
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
fi

# Save credentials
mkdir -p "$API_DIR"
cat > "$API_DIR/.env" << EOF
DATABASE_URL=postgres://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME?sslmode=disable
AGENTYK_DOMAIN=${DOMAIN:-agentyk.ru}
PORT=8000
# Set these after BTCPay install:
# BTCPAY_URL=http://127.0.0.1:49392
# BTCPAY_KEY=your_api_key
# BTCPAY_STORE_ID=your_store_id
# BTCPAY_WEBHOOK_SECRET=your_webhook_secret
# TELEGRAM_BOT_TOKEN=your_bot_token
# TELEGRAM_ADMIN_CHAT_ID=your_chat_id
EOF
chmod 600 "$API_DIR/.env"

echo "[3/7] PostgreSQL configured. Credentials in $API_DIR/.env"

# --- Deploy Go binary + templates ---
cp "$SRC_DIR/agentyk" "$API_DIR/agentyk"
chmod +x "$API_DIR/agentyk"
cp -r "$SRC_DIR/web" "$API_DIR/"

echo "[4/7] Binary and templates deployed."

# --- Systemd service ---
cat > /etc/systemd/system/agentyk.service << EOF
[Unit]
Description=AgentYK API
After=network.target postgresql.service

[Service]
User=root
WorkingDirectory=$API_DIR
EnvironmentFile=$API_DIR/.env
ExecStart=$API_DIR/agentyk
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable agentyk
systemctl start agentyk
echo "[5/7] AgentYK service running on :8000"

# --- Nginx reverse proxy ---
if [ -n "$DOMAIN" ]; then
    SERVER_NAME="$DOMAIN $SERVER_IP"
else
    SERVER_NAME="$SERVER_IP"
fi

cat > /etc/nginx/sites-available/agentyk << NGINX
server {
    listen 80;
    server_name $SERVER_NAME;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/agentyk /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx
echo "[6/7] Nginx reverse proxy configured."

# --- BTCPay Server (optional) ---
if [ -f "$SRC_DIR/../tools/install-btcpay.sh" ]; then
    echo "[7/7] BTCPay installer available at: bash $SRC_DIR/../tools/install-btcpay.sh"
else
    echo "[7/7] Install BTCPay Server separately."
fi

echo ""
echo "=== AgentYK Deploy COMPLETE ==="
echo ""
echo "API:       http://$SERVER_IP/"
echo "Health:    http://$SERVER_IP/health"
echo "Register:  curl -X POST http://$SERVER_IP/register -H 'Content-Type: application/json' -d '{\"username\":\"test\"}'"
echo ""
echo "Next steps:"
echo "  1. Install BTCPay Server"
echo "  2. Update $API_DIR/.env with BTCPay + Telegram credentials"
echo "  3. systemctl restart agentyk"
if [ -n "$DOMAIN" ]; then
    echo "  4. Add DNS A record: $DOMAIN -> $SERVER_IP"
    echo "  5. Install TLS: certbot --nginx -d $DOMAIN"
    echo "  6. Deploy mail stack (Postfix + Dovecot) when ready"
fi
echo ""
