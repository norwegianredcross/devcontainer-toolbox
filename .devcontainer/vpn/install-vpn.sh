#!/bin/bash
# Path: .devcontainer/vpn/install-vpn.sh
# Purpose: Install VPN related software
# Author: Your Organization
# Date: 2024-11-05

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

echo "VPN software installation complete"