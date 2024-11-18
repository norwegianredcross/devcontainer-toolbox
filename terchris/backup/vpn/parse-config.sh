#!/bin/bash
# Path: .devcontainer/vpn/parse-config.sh
# Purpose: Convert Azure XML config to OpenVPN format

set -e  # Exit on any error

# Function for logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Check for xmlstarlet
if ! command -v xmlstarlet &> /dev/null; then
    log "Error: xmlstarlet is not installed"
    exit 1
fi

# Check for input file
if [ ! -f "azurevpnconfig.xml" ]; then
    log "Error: azurevpnconfig.xml not found"
    exit 1
fi

# Extract values from XML
log "Parsing Azure VPN configuration..."
SERVER=$(xmlstarlet sel -N a="http://schemas.datacontract.org/2004/07/" -t -v "//a:serverlist/a:ServerEntry/a:fqdn" azurevpnconfig.xml)
CA_HASH=$(xmlstarlet sel -N a="http://schemas.datacontract.org/2004/07/" -t -v "//a:servervalidation/a:Cert/a:hash" azurevpnconfig.xml)

# Create CA certificate
log "Creating CA certificate..."
echo "-----BEGIN CERTIFICATE-----" > azure-ca.crt
echo "$CA_HASH" | fold -w 64 >> azure-ca.crt
echo "-----END CERTIFICATE-----" >> azure-ca.crt
chmod 600 azure-ca.crt

# Create OpenVPN config
log "Creating OpenVPN configuration..."
cat > azure.ovpn << EOF
client
dev tun
proto tcp
remote $SERVER 443
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
auth SHA256
key-direction 1
verb 4

# Certificate configuration
ca azure-ca.crt

# Authentication
auth-user-pass
auth-retry interact

# Connection settings
connect-retry 2 6
connect-retry-max 3
resolv-retry 15

# Data compression
compress
EOF

chmod 600 azure.ovpn

log "Configuration created successfully:"
log "- OpenVPN config: azure.ovpn"
log "- CA certificate: azure-ca.crt"