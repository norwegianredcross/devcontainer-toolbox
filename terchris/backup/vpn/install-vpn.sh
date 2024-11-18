#!/bin/bash
# Path: .devcontainer/vpn/install-vpn.sh
# Purpose: Install VPN related software and setup TUN device

set -e  # Exit on any error

echo "Installing VPN related software..."

# Update package list
apt-get update

# Install required packages
apt-get install -y \
    openvpn \
    xmlstarlet

# Clean up
apt-get clean
rm -rf /var/lib/apt/lists/*

# Setup TUN device and required directories
echo "Setting up TUN device..."
mkdir -p /dev/net
if [ ! -c /dev/net/tun ]; then
    mknod /dev/net/tun c 10 200
    chmod 666 /dev/net/tun
fi

echo "VPN software installation complete"