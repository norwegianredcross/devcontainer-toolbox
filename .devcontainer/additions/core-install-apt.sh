#!/bin/bash
# file: .devcontainer/additions/core-install-apt.sh
#
# Core functionality for managing system packages via apt
# To be sourced by installation scripts, not executed directly.

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
    if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "^install ok installed$"; then
        return 0  # Package is installed
    else
        return 1  # Package is not installed
    fi
}

# Function to get installed package version
get_package_version() {
    local package=$1
    dpkg -l "$package" 2>/dev/null | grep "^ii" | awk '{print $3}'
}

# Function to install apt packages
process_system_packages_install() {
    debug "=== Starting package installation ==="
    
    # Get array reference
    declare -n arr=$1
    
    log "Installing ${#arr[@]} system packages..."
    echo
    printf "%-25s %-20s %s\n" "Package" "Status" "Version"
    printf "%s\n" "----------------------------------------------------"
    
    local installed=0
    local updated=0
    local failed=0
    declare -A successful_ops
    
    # First update package lists with error handling
    debug "Running apt update..."
    local update_output
    update_output=$(sudo DEBIAN_FRONTEND=noninteractive apt-get update 2>&1)
    if [ $? -ne 0 ]; then
        error "Failed to update package lists:"
        error "$update_output"
        return 1
    fi
    
    for package in "${arr[@]}"; do
        printf "%-25s " "$package"
        
        # Try to install/upgrade the package
        local install_output
        install_output=$(sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$package" 2>&1)
        local exit_code=$?
        
        # Verify installation regardless of apt-get output
        if command -v "$package" >/dev/null 2>&1 || dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "^install ok installed$"; then
            local version
            version=$(dpkg-query -W -f='${Version}' "$package" 2>/dev/null)
            if [ $exit_code -eq 0 ]; then
                if echo "$install_output" | grep -q "is already the newest version"; then
                    printf "%-20s %s\n" "Up to date" "v$version"
                    installed=$((installed + 1))
                else
                    printf "%-20s %s\n" "Installed" "v$version"
                    installed=$((installed + 1))
                fi
                successful_ops["$package"]=$version
            else
                printf "%-20s\n" "Verification failed"
                error "Package installed but exit code was non-zero:"
                error "$install_output"
                failed=$((failed + 1))
            fi
        else
            printf "%-20s\n" "Installation failed"
            error "Failed to install $package:"
            error "$install_output"
            failed=$((failed + 1))
        fi
    done
    
    echo
    echo "Current Status:"
    if [ ${#successful_ops[@]} -gt 0 ]; then
        while IFS= read -r package; do
            printf "* ✅ %s (v%s)\n" "$package" "${successful_ops[$package]}"
        done < <(printf '%s\n' "${!successful_ops[@]}" | sort)
    else
        echo "No packages were successfully installed or updated"
    fi
    
    echo
    echo "----------------------------------------"
    log "Package Installation Summary"
    echo "Total packages: ${#arr[@]}"
    echo "  Installed/Up to date: $installed"
    echo "  Updated: $updated"
    echo "  Failed: $failed"
    
    # Return failure if any package failed to install
    [ $failed -eq 0 ] || return 1
}

# Function to uninstall apt packages
process_system_packages_uninstall() {
    debug "=== Starting package uninstallation ==="
    
    # Get array reference
    declare -n arr=$1
    
    log "Uninstalling ${#arr[@]} system packages..."
    echo "⚠️  Note: This will also remove dependent packages that are no longer needed"
    echo
    printf "%-25s %-20s %s\n" "Package" "Status" "Previous Version"
    printf "%s\n" "----------------------------------------------------"
    
    local uninstalled=0
    local skipped=0
    local failed=0
    declare -A successful_ops
    
    for package in "${arr[@]}"; do
        printf "%-25s " "$package"
        
        # Check if package exists first
        if dpkg -l "$package" >/dev/null 2>&1; then
            local version
            version=$(dpkg -l "$package" 2>/dev/null | grep "^ii" | awk '{print $3}')
            debug "Uninstalling package '$package' (v$version)..."
            
            # Show what will be removed
            echo "Packages that will be removed with $package:"
            apt-get -s remove "$package" | grep "^Remv" || true
            
            # Try to uninstall the package
            if sudo DEBIAN_FRONTEND=noninteractive apt-get remove -y "$package"; then
                printf "%-20s %s\n" "Uninstalled" "was v$version"
                uninstalled=$((uninstalled + 1))
                successful_ops["$package"]=$version
            else
                printf "%-20s %s\n" "Failed" "v$version"
                error "Failed to uninstall $package"
                failed=$((failed + 1))
            fi
        else
            printf "%-20s\n" "Not installed"
            skipped=$((skipped + 1))
        fi
    done
    
    # Run autoremove to clean up dependencies
    if [ $uninstalled -gt 0 ]; then
        echo
        echo "🧹 Cleaning up unused dependencies..."
        echo "The following packages are no longer needed and will be removed:"
        sudo DEBIAN_FRONTEND=noninteractive apt-get autoremove -y
    fi
    
    echo
    echo "Current Status:"
    if [ ${#successful_ops[@]} -gt 0 ]; then
        while IFS= read -r package; do
            printf "* 🗑️  %s (was v%s)\n" "$package" "${successful_ops[$package]}"
        done < <(printf '%s\n' "${!successful_ops[@]}" | sort)
    else
        echo "No packages were successfully uninstalled"
    fi
    
    echo
    echo "----------------------------------------"
    log "Package Uninstallation Summary"
    echo "Total packages: ${#arr[@]}"
    echo "  Successfully uninstalled: $uninstalled"
    echo "  Skipped/Not installed: $skipped"
    echo "  Failed: $failed"
    echo
    echo "Note: Dependencies that were automatically installed with these packages"
    echo "      have also been removed to keep the system clean."
    
    # Return failure if any package failed to uninstall
    [ $failed -eq 0 ] || return 1
}

# Function to process packages (install or uninstall)
process_system_packages() {
    if [ "${UNINSTALL_MODE:-0}" -eq 1 ]; then
        process_system_packages_uninstall "$@"
    else
        process_system_packages_install "$@"
    fi
}