#!/bin/bash
# AgentYK — Generate DKIM keys and configure OpenDKIM
# Usage: bash setup-dkim.sh <domain>

set -euo pipefail
DOMAIN="${1:?domain required}"
SELECTOR="mail"
KEY_DIR="/etc/opendkim/keys/$DOMAIN"

mkdir -p "$KEY_DIR"
opendkim-genkey -D "$KEY_DIR" -d "$DOMAIN" -s "$SELECTOR"
chown -R opendkim:opendkim /etc/opendkim/keys

# OpenDKIM main config
cat > /etc/opendkim.conf << EOF
Syslog            yes
UMask             002
UserID            opendkim
Socket            inet:8891@localhost
Canonicalization  relaxed/simple
Domain            $DOMAIN
Selector          $SELECTOR
KeyFile           $KEY_DIR/$SELECTOR.private
SignatureAlgorithm rsa-sha256
AutoRestart       yes
AutoRestartRate   10/1h
EOF

# Key table + signing table
echo "$SELECTOR._domainkey.$DOMAIN $DOMAIN:$SELECTOR:$KEY_DIR/$SELECTOR.private" \
    > /etc/opendkim/KeyTable
echo "*@$DOMAIN $SELECTOR._domainkey.$DOMAIN" \
    > /etc/opendkim/SigningTable

systemctl enable opendkim
systemctl restart opendkim

echo "=== DKIM DNS Record ==="
echo "Add this TXT record to DNS:"
echo "Name: ${SELECTOR}._domainkey.${DOMAIN}"
cat "$KEY_DIR/$SELECTOR.txt"
echo "========================"
