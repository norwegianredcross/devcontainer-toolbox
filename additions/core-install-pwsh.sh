#!/bin/bash
# file: .devcontainer/additions/core-install-pwsh.sh

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

# Function to check if a PowerShell module is installed
is_module_installed() {
    local module=$1
    debug "Checking if module '$module' is installed..."
    pwsh -NoProfile -Command "
        if (Get-Module -ListAvailable -Name '$module' -ErrorAction SilentlyContinue) {
            exit 0
        } else {
            exit 1
        }
    "
}

# Function to get installed module version
get_module_version() {
    local module=$1
    pwsh -NoProfile -Command "
        try {
            (Get-Module -ListAvailable -Name '$module' | 
             Sort-Object Version -Descending | 
             Select-Object -First 1).Version.ToString()
        } catch {
            Write-Error \$_.Exception.Message
            exit 1
        }
    "
}

# Function to install PowerShell modules
install_modules() {
    debug "=== Starting module installation ==="
    
    # Get array reference
    declare -n arr=$1
    
    log "Installing ${#arr[@]} PowerShell modules..."
    echo
    printf "%-25s %-20s %s\n" "Module" "Status" "Version"
    printf "%s\n" "----------------------------------------------------"
    
    local installed=0
    local updated=0
    local failed=0
    declare -A successful_ops

    # Set PSGallery as trusted
    debug "Setting PSGallery as trusted..."
    pwsh -NoProfile -Command "Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted" >/dev/null 2>&1
    
    for module in "${arr[@]}"; do
        printf "%-25s " "$module"
        
        if is_module_installed "$module"; then
            local old_version
            old_version=$(get_module_version "$module")
            debug "Module '$module' is already installed (v$old_version)"
            
            # Try to update the module
            if pwsh -NoProfile -Command "
                try {
                    Update-Module -Name '$module' -Force -ErrorAction Stop
                    exit 0
                } catch {
                    Write-Error \$_.Exception.Message
                    exit 1
                }
            " >/dev/null 2>&1; then
                local new_version
                new_version=$(get_module_version "$module")
                if [ "$old_version" != "$new_version" ]; then
                    printf "%-20s %s\n" "Updated" "v$new_version"
                    updated=$((updated + 1))
                else
                    printf "%-20s %s\n" "Up to date" "v$new_version"
                    installed=$((installed + 1))
                fi
                successful_ops["$module"]=$new_version
            else
                printf "%-20s\n" "Update failed"
                failed=$((failed + 1))
            fi
        else
            debug "Installing module '$module'..."
            if pwsh -NoProfile -Command "
                try {
                    Install-Module -Name '$module' -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
                    exit 0
                } catch {
                    Write-Error \$_.Exception.Message
                    exit 1
                }
            " >/dev/null 2>&1; then
                local version
                version=$(get_module_version "$module")
                printf "%-20s %s\n" "Installed" "v$version"
                installed=$((installed + 1))
                successful_ops["$module"]=$version
            else
                printf "%-20s\n" "Installation failed"
                failed=$((failed + 1))
            fi
        fi
    done
    
    echo
    echo "Current Status:"
    while IFS= read -r module; do
        printf "* ✅ %s (v%s)\n" "$module" "${successful_ops[$module]}"
    done < <(printf '%s\n' "${!successful_ops[@]}" | sort)
    
    echo
    echo "----------------------------------------"
    log "Module Installation Summary"
    echo "Total modules: ${#arr[@]}"
    echo "  Installed/Up to date: $installed"
    echo "  Updated: $updated"
    echo "  Failed: $failed"
}

# Function to uninstall PowerShell modules
uninstall_modules() {
    debug "=== Starting module uninstallation ==="
    
    # Get array reference
    declare -n arr=$1
    
    log "Uninstalling ${#arr[@]} PowerShell modules..."
    echo
    printf "%-25s %-20s %s\n" "Module" "Status" "Previous Version"
    printf "%s\n" "----------------------------------------------------"
    
    local uninstalled=0
    local skipped=0
    local failed=0
    declare -A successful_ops
    
    for module in "${arr[@]}"; do
        printf "%-25s " "$module"
        
        if is_module_installed "$module"; then
            local version
            version=$(get_module_version "$module")
            debug "Uninstalling module '$module' (v$version)..."
            
            if pwsh -NoProfile -Command "
                try {
                    Remove-Module -Name '$module' -Force -ErrorAction SilentlyContinue
                    Uninstall-Module -Name '$module' -AllVersions -Force -ErrorAction Stop
                    exit 0
                } catch {
                    Write-Error \$_.Exception.Message
                    exit 1
                }
            " >/dev/null 2>&1; then
                printf "%-20s %s\n" "Uninstalled" "was v$version"
                uninstalled=$((uninstalled + 1))
                successful_ops["$module"]=$version
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
    while IFS= read -r module; do
        printf "* 🗑️  %s (was v%s)\n" "$module" "${successful_ops[$module]}"
    done < <(printf '%s\n' "${!successful_ops[@]}" | sort)
    
    echo
    echo "----------------------------------------"
    log "Module Uninstallation Summary"
    echo "Total modules: ${#arr[@]}"
    echo "  Successfully uninstalled: $uninstalled"
    echo "  Skipped/Not installed: $skipped"
    echo "  Failed: $failed"
}

# Process PowerShell modules based on mode
process_modules() {
    if [ "${UNINSTALL_MODE:-0}" -eq 1 ]; then
        uninstall_modules "$1"
    else
        install_modules "$1"
    fi
}