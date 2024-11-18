#!/bin/bash
# file: .devcontainer/additions/core-install-python-packages.sh

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

# Function to check if a package is installed
is_package_installed() {
    local package=$1
    debug "Checking if package '$package' is installed..."
    pip show "$package" >/dev/null 2>&1
}

# Function to get installed package version
get_package_version() {
    local package=$1
    pip show "$package" 2>/dev/null | grep "Version" | cut -d " " -f 2
}

# Function to install Python packages
install_packages() {
    debug "=== Starting package installation ==="
    
    # Get array reference
    declare -n arr=$1
    
    log "Installing ${#arr[@]} Python packages..."
    echo
    printf "%-25s %-20s %s\n" "Package" "Status" "Version"
    printf "%s\n" "----------------------------------------------------"
    
    local installed=0
    local updated=0
    local failed=0
    declare -A successful_ops
    
    for package in "${arr[@]}"; do
        printf "%-25s " "$package"
        
        if is_package_installed "$package"; then
            local old_version
            old_version=$(get_package_version "$package")
            debug "Package '$package' is already installed (v$old_version)"
            
            if pip install --no-cache-dir -U "$package" >/dev/null 2>&1; then
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
                printf "%-20s\n" "Update failed"
                failed=$((failed + 1))
            fi
        else
            debug "Installing package '$package'..."
            if pip install --no-cache-dir "$package" >/dev/null 2>&1; then
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

# Function to uninstall Python packages
uninstall_packages() {
    debug "=== Starting package uninstallation ==="
    
    # Get array reference
    declare -n arr=$1
    
    log "Uninstalling ${#arr[@]} Python packages..."
    echo
    printf "%-25s %-20s %s\n" "Package" "Status" "Previous Version"
    printf "%s\n" "----------------------------------------------------"
    
    local uninstalled=0
    local skipped=0
    local failed=0
    declare -A successful_ops
    
    for package in "${arr[@]}"; do
        printf "%-25s " "$package"
        
        if is_package_installed "$package"; then
            local version
            version=$(get_package_version "$package")
            debug "Uninstalling package '$package' (v$version)..."
            
            if pip uninstall -y "$package" >/dev/null 2>&1; then
                printf "%-20s %s\n" "Uninstalled" "was v$version"
                uninstalled=$((uninstalled + 1))
                successful_ops["$package"]=$version
            else
                printf "%-20s %s\n" "Failed" "v$version"
                failed=$((failed + 1))
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

# Process Python packages based on mode
process_packages() {
    if [ "${UNINSTALL_MODE:-0}" -eq 1 ]; then
        uninstall_packages "$1"
    else
        install_packages "$1"
    fi
}