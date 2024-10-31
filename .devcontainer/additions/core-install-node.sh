#!/bin/bash
# file: .devcontainer/additions/core-install-node.sh

set -e

# Debug function
debug() {
    if [ "${DEBUG_MODE:-0}" -eq 1 ]; then
        echo "DEBUG: $*" >&2
    fi
}

# Simple logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Error logging function
error() {
    echo "ERROR: $*" >&2
}

# Function to check if a package is installed globally
is_package_installed() {
    local package=$1
    debug "Checking if package '$package' is installed..."
    npm list -g "$package" >/dev/null 2>&1
}

# Function to get installed package version
get_package_version() {
    local package=$1
    npm list -g "$package" 2>/dev/null | grep "$package" | cut -d'@' -f2
}

# Function to install npm packages
install_packages() {
    debug "=== Starting package installation ==="
    
    # Get array reference
    declare -n arr=$1
    
    log "Installing ${#arr[@]} Node.js packages..."
    echo
    printf "%-35s %-20s %s\n" "Package" "Status" "Version"
    printf "%s\n" "----------------------------------------------------"
    
    local installed=0
    local updated=0
    local failed=0
    declare -A successful_ops
    
    for package in "${arr[@]}"; do
        printf "%-35s " "$package"
        
        if is_package_installed "$package"; then
            local old_version
            old_version=$(get_package_version "$package")
            debug "Package '$package' is already installed (v$old_version)"
            
            # Try to update the package
            if [ "$EUID" -ne 0 ]; then
                sudo npm install -g "$package@latest" >/dev/null 2>&1
            else
                npm install -g "$package@latest" >/dev/null 2>&1
            fi
            
            local new_version
            new_version=$(get_package_version "$package")
            if [ "$old_version" != "$new_version" ]; then
                printf "%-20s %s\n" "Updated" "v$new_version"
                updated=$((updated + 1))
            else
                printf "%-20s %s\n" "Up to date" "v$new_version"
                installed=$((installed + 1))
            fi
            successful_ops["$package"]=$new_version
        else
            debug "Installing package '$package'..."
            if [ "$EUID" -ne 0 ]; then
                if sudo npm install -g "$package" >/dev/null 2>&1; then
                    local version
                    version=$(get_package_version "$package")
                    printf "%-20s %s\n" "Installed" "v$version"
                    installed=$((installed + 1))
                    successful_ops["$package"]=$version
                else
                    printf "%-20s\n" "Installation failed"
                    failed=$((failed + 1))
                fi
            else
                if npm install -g "$package" >/dev/null 2>&1; then
                    local version
                    version=$(get_package_version "$package")
                    printf "%-20s %s\n" "Installed" "v$version"
                    installed=$((installed + 1))
                    successful_ops["$package"]=$version
                else
                    printf "%-20s\n" "Installation failed"
                    failed=$((failed + 1))
                fi
            fi
        fi
    done
    
    echo
    echo "Current Status:"
    while IFS= read -r package; do
        printf "* ✅ %s (v%s)\n" "$package" "${successful_ops[$package]}"
    done < <(printf '%s\n' "${!successful_ops[@]}" | sort)
    
    echo
    echo "----------------------------------------"
    log "Package Installation Summary"
    echo "Total packages: ${#arr[@]}"
    echo "  Installed/Up to date: $installed"
    echo "  Updated: $updated"
    echo "  Failed: $failed"
}

# Function to uninstall npm packages
uninstall_packages() {
    debug "=== Starting package uninstallation ==="
    
    # Get array reference
    declare -n arr=$1
    
    log "Uninstalling ${#arr[@]} Node.js packages..."
    echo
    printf "%-35s %-20s %s\n" "Package" "Status" "Previous Version"
    printf "%s\n" "----------------------------------------------------"
    
    local uninstalled=0
    local skipped=0
    local failed=0
    declare -A successful_ops
    
    for package in "${arr[@]}"; do
        printf "%-35s " "$package"
        
        if is_package_installed "$package"; then
            local version
            version=$(get_package_version "$package")
            debug "Uninstalling package '$package' (v$version)..."
            
            if [ "$EUID" -ne 0 ]; then
                if sudo npm uninstall -g "$package" >/dev/null 2>&1; then
                    printf "%-20s %s\n" "Uninstalled" "was v$version"
                    uninstalled=$((uninstalled + 1))
                    successful_ops["$package"]=$version
                else
                    printf "%-20s %s\n" "Failed" "v$version"
                    failed=$((failed + 1))
                fi
            else
                if npm uninstall -g "$package" >/dev/null 2>&1; then
                    printf "%-20s %s\n" "Uninstalled" "was v$version"
                    uninstalled=$((uninstalled + 1))
                    successful_ops["$package"]=$version
                else
                    printf "%-20s %s\n" "Failed" "v$version"
                    failed=$((failed + 1))
                fi
            fi
        else
            printf "%-20s\n" "Not installed"
            skipped=$((skipped + 1))
        fi
    done
    
    echo
    echo "Current Status:"
    while IFS= read -r package; do
        printf "* 🗑️  %s (was v%s)\n" "$package" "${successful_ops[$package]}"
    done < <(printf '%s\n' "${!successful_ops[@]}" | sort)
    
    echo
    echo "----------------------------------------"
    log "Package Uninstallation Summary"
    echo "Total packages: ${#arr[@]}"
    echo "  Successfully uninstalled: $uninstalled"
    echo "  Skipped/Not installed: $skipped"
    echo "  Failed: $failed"
}

# Process npm packages based on mode
process_packages() {
    if [ "${UNINSTALL_MODE:-0}" -eq 1 ]; then
        uninstall_packages "$1"
    else
        install_packages "$1"
    fi
}