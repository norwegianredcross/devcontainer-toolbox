#!/bin/bash
# file: .devcontainer/additions/install-extensions.sh
# Description: This script provides helper functions for installing VS Code extensions
#
# Usage:
#   Source this script from other installation scripts:
#   source "$(dirname "$0")/install-extensions.sh"
#
# Components managed:
# 1. Extension Downloads:
#    - Downloads extensions from VS Code Marketplace
#    - Handles versioning and updates
#    - Manages HTTP headers and authentication
#
# 2. Installation Process:
#    - Verifies downloads
#    - Installs extensions using VS Code CLI
#    - Handles installation verification
#
# 3. User Interface:
#    - Provides status updates and confirmations
#    - Displays color-coded success/failure messages
#    - Shows installation progress
#
# Dependencies:
#   - curl: For downloading extensions
#   - code: VS Code CLI for extension management
#   - grep, cut: For parsing version information
#   - Standard Unix tools (rm, test, etc.)

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

display_header() {
    echo "=== $1 ==="
    echo "Operation: Install extensions"
    echo "=========================================="
}

fetch_latest_extension_version() {
    local url=$1
    local response
    response=$(curl -s \
        -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
        -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" \
        "$url")
    echo "$response" | grep -o '"version":"[^"]*' | head -1 | cut -d'"' -f4
}

download_extension() {
    local extension_id=$1
    local marketplace_url=$2
    local version
    
    version=$(fetch_latest_extension_version "$marketplace_url")
    if [ -z "$version" ]; then
        echo "Failed to fetch version"
        return 1
    fi
    
    echo "Found version: $version"
    
    local publisher="${extension_id%%.*}"
    local extension="${extension_id#*.}"
    local download_url="https://marketplace.visualstudio.com/_apis/public/gallery/publishers/${publisher}/vsextensions/${extension}/${version}/vspackage"
    
    echo "Downloading $extension_id..."
    if ! curl -s -L \
         -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
         -H "Accept: application/octet-stream;api-version=7.1-preview.1" \
         -H "Connection: keep-alive" \
         -H "X-Market-User-Id: 7b22686f737450617468223a222f686f6d652f766963746f722f636f6465227d" \
         --compressed \
         -o "extension.vsix" \
         "$download_url"; then
        echo "Download failed"
        return 1
    fi

    if [ ! -f "extension.vsix" ] || [ ! -s "extension.vsix" ]; then
        echo "Downloaded file is empty or missing"
        return 1
    fi
    
    echo "Installing extension directly..."
    if code --install-extension "extension.vsix"; then
        rm -f extension.vsix
        return 0
    else
        rm -f extension.vsix
        return 1
    fi
}

get_extensions_to_process() {
    local -n extensions_ref=$1
    local -n extensions_to_process_ref=$2
    
    for ext_id in "${!extensions_ref[@]}"; do
        if ! code --list-extensions | grep -q "^${ext_id}$"; then
            extensions_to_process_ref+=("$ext_id")
        fi
    done
}

display_extensions_status() {
    local -n extensions_ref=$1
    local -n extensions_to_process_ref=$2
    
    if [ ${#extensions_to_process_ref[@]} -eq 0 ]; then
        echo "All extensions are already installed."
        return 1
    fi
    
    echo "The following extensions will be installed:"
    echo
    for ext_id in "${extensions_to_process_ref[@]}"; do
        IFS='|' read -r name description url headers <<< "${extensions_ref[$ext_id]}"
        echo "- $name"
        echo "  $description"
    done
    echo
    return 0
}

get_user_confirmation() {
    read -p "Do you want to proceed with the installation? (y/N) " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

process_extensions() {
    local -n extensions_ref=$1
    local -n extensions_to_process_ref=$2
    local -n failed_extensions_ref=$3
    
    for ext_id in "${extensions_to_process_ref[@]}"; do
        IFS='|' read -r name description url headers <<< "${extensions_ref[$ext_id]}"
        echo "Installing $name..."
        
        if ! download_extension "$ext_id" "$url"; then
            failed_extensions_ref+=("$ext_id")
        fi
    done
}

verify_installations() {
    local -n extensions_ref=$1
    
    echo "Verifying installations..."
    for ext_id in "${!extensions_ref[@]}"; do
        if code --list-extensions | grep -q "^${ext_id}$"; then
            echo -e "${GREEN}✓${NC} $ext_id is installed"
        else
            echo -e "${RED}✗${NC} $ext_id is not installed"
        fi
    done
}

display_final_status() {
    local -n extensions_ref=$1
    local -n failed_extensions_ref=$2
    
    echo "----------------------------------------"
    if [ ${#failed_extensions_ref[@]} -eq 0 ]; then
        echo "All components installed successfully!"
        exit 0
    else
        echo "Operation completed with some issues:"
        echo "Failed to process:"
        for ext_id in "${failed_extensions_ref[@]}"; do
            IFS='|' read -r name description url headers <<< "${extensions_ref[$ext_id]}"
            echo "- $name"
        done
        exit 1
    fi
}