#!/bin/bash
# file: .devcontainer/additions/core-install-pwsh.sh
#
# Core functionality for managing PowerShell modules
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

# Function to check if PowerShell is available
check_pwsh_available() {
    if ! command -v pwsh >/dev/null 2>&1; then
        error "PowerShell (pwsh) is not installed or not in PATH"
        return 1
    fi
    return 0
}

# Function to check if a PowerShell module is installed
is_module_installed() {
    local module=$1
    debug "Checking if module '$module' is installed..."
    pwsh -NoProfile -NonInteractive -Command "if (Get-Module -ListAvailable -Name '$module') { exit 0 } else { exit 1 }" 2>/dev/null
}

# Function to get installed module version
get_module_version() {
    local module=$1
    pwsh -NoProfile -NonInteractive -Command "(Get-Module -ListAvailable -Name '$module' | Sort-Object Version -Descending | Select-Object -First 1).Version.ToString()" 2>/dev/null
}

# Function to try update module
try_update_module() {
    local module=$1
    pwsh -NoProfile -NonInteractive -Command "Update-Module -Name '$module' -Force" 2>/dev/null
}

# Function to try install module
try_install_module() {
    local module=$1
    pwsh -NoProfile -NonInteractive -Command "Install-Module -Name '$module' -Force -AllowClobber -Scope CurrentUser" 2>/dev/null
}

# Function to try uninstall module
try_uninstall_module() {
    local module=$1
    pwsh -NoProfile -NonInteractive -Command "Remove-Module -Name '$module' -Force -ErrorAction SilentlyContinue; Uninstall-Module -Name '$module' -AllVersions -Force" 2>/dev/null
}

# Function to verify PSGallery
verify_psgallery() {
    pwsh -NoProfile -NonInteractive -Command "Get-PSRepository -Name PSGallery" >/dev/null 2>&1
}

# Function to set PSGallery trusted
set_psgallery_trusted() {
    pwsh -NoProfile -NonInteractive -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted" >/dev/null 2>&1
}

# Function to install PowerShell modules
process_pwsh_modules() {
    debug "=== Starting PowerShell module installation ==="
    
    # Verify PowerShell is available
    if ! check_pwsh_available; then
        error "Cannot proceed with PowerShell module installation"
        return 1
    fi
    
    # Get array reference
    declare -n arr=$1
    
    # Skip if no modules to process
    if [ ${#arr[@]} -eq 0 ]; then
        debug "No PowerShell modules to process"
        return 0
    fi
    
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
    if ! set_psgallery_trusted; then
        error "Failed to set PSGallery as trusted"
        return 1
    fi
    
    for module in "${arr[@]}"; do
        printf "%-25s " "$module"
        
        if is_module_installed "$module"; then
            local old_version
            old_version=$(get_module_version "$module")
            debug "Module '$module' is already installed (v$old_version)"
            
            # Try to update the module
            if try_update_module "$module"; then
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
            if try_install_module "$module"; then
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
    if [ ${#successful_ops[@]} -gt 0 ]; then
        while IFS= read -r module; do
            printf "* ✅ %s (v%s)\n" "$module" "${successful_ops[$module]}"
        done < <(printf '%s\n' "${!successful_ops[@]}" | sort)
    else
        echo "No modules were successfully installed or updated"
    fi
    
    echo
    echo "----------------------------------------"
    log "Module Installation Summary"
    echo "Total modules: ${#arr[@]}"
    echo "  Installed/Up to date: $installed"
    echo "  Updated: $updated"
    echo "  Failed: $failed"
    
    # Return failure if any module failed
    [ $failed -eq 0 ] || return 1
}

# Function to uninstall PowerShell modules
process_pwsh_modules_uninstall() {
    debug "=== Starting PowerShell module uninstallation ==="
    
    # Verify PowerShell is available
    if ! check_pwsh_available; then
        error "Cannot proceed with PowerShell module uninstallation"
        return 1
    fi
    
    # Get array reference
    declare -n arr=$1
    
    # Skip if no modules to process
    if [ ${#arr[@]} -eq 0 ]; then
        debug "No PowerShell modules to process"
        return 0
    fi
    
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
            
            if try_uninstall_module "$module"; then
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
    if [ ${#successful_ops[@]} -gt 0 ]; then
        while IFS= read -r module; do
            printf "* 🗑️  %s (was v%s)\n" "$module" "${successful_ops[$module]}"
        done < <(printf '%s\n' "${!successful_ops[@]}" | sort)
    else
        echo "No modules were successfully uninstalled"
    fi
    
    echo
    echo "----------------------------------------"
    log "Module Uninstallation Summary"
    echo "Total modules: ${#arr[@]}"
    echo "  Successfully uninstalled: $uninstalled"
    echo "  Skipped/Not installed: $skipped"
    echo "  Failed: $failed"
    
    # Return failure if any module failed
    [ $failed -eq 0 ] || return 1
}

# Handle install or uninstall based on mode
if [ "${UNINSTALL_MODE:-0}" -eq 1 ]; then
    process_pwsh_modules=process_pwsh_modules_uninstall
fi