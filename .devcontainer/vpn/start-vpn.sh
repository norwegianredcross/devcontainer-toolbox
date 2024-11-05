#!/bin/bash
# Path: .devcontainer/vpn/start-vpn.sh
# Purpose: Start VPN connection using Azure AD auth
# Author: Your Organization
# Date: 2024-11-05

set -e  # Exit on any error

# Function for logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Check for required files
for file in "azure.ovpn" "azure-ca.crt"; do
    if [ ! -f "$file" ]; then
        log "Error: $file not found"
        exit 1
    fi
done

# Check OpenVPN installation
if ! command -v openvpn &> /dev/null; then
    log "Error: OpenVPN is not installed"
    exit 1
fi

# Get Azure token
log "Getting Azure authentication token..."
TOKEN=$(az account get-access-token --query accessToken -o tsv)
if [ -z "$TOKEN" ]; then
    log "Error: Failed to get Azure token"
    exit 1
fi

# Extract VPN config parameters
log "Extracting VPN configuration..."
TENANT=$(xmlstarlet sel -N a="http://schemas.datacontract.org/2004/07/" -t -v "//a:clientauth/a:aad/a:tenant" azurevpnconfig.xml)

# Create credentials file
log "Preparing VPN credentials..."
echo "$TENANT" > /tmp/vpn-creds
echo "$TOKEN" >> /tmp/vpn-creds
chmod 600 /tmp/vpn-creds

# Verify TUN device
if [ ! -c /dev/net/tun ]; then
    log "Error: TUN device not available"
    exit 1
fi

# Start VPN with error capture
log "Starting VPN connection..."
openvpn \
    --config azure.ovpn \
    --auth-user-pass /tmp/vpn-creds \
    --verb 4 2>&1 | tee /tmp/vpn.log

# If OpenVPN exits, check the log
if [ $? -ne 0 ]; then
    log "Error: OpenVPN failed. Last 10 lines of log:"
    tail -n 10 /tmp/vpn.log
    exit 1
fi