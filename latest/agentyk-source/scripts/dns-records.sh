#!/bin/bash
# AgentYK — Print all DNS records required
# Usage: bash dns-records.sh <domain> <server_ip>

DOMAIN="${1:?Usage: $0 <domain> <server_ip>}"
SERVER_IP="${2:?Usage: $0 <domain> <server_ip>}"

echo "=== AgentYK DNS Records for $DOMAIN ==="
echo ""
echo "Add ALL of these in your DNS registrar:"
echo ""
echo "Type    Name                    Value"
echo "------  ----------------------  -----------------------------------------------"
echo "A       @                       $SERVER_IP"
echo "A       mail                    $SERVER_IP"
echo "MX      @                       mail.$DOMAIN  (priority: 10)"
echo "TXT     @                       v=spf1 mx ~all"
echo "TXT     _dmarc                  v=DMARC1; p=quarantine; rua=mailto:postmaster@$DOMAIN"
echo "TXT     mail._domainkey         [run setup-dkim.sh to get this value]"
echo ""
echo "After adding records, verify propagation:"
echo "  dig MX $DOMAIN"
echo "  dig TXT $DOMAIN"
echo "  dig A mail.$DOMAIN"
echo ""
echo "SPF/DKIM/DMARC verification:"
echo "  Send a test email to: check-auth@verifier.port25.com"
echo ""
