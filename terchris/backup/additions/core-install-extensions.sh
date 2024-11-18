#!/bin/bash
# file: .devcontainer/additions/core-install-extensions.sh
#
# Core functionality for managing VS Code extensions
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

# Find VS Code server installation
find_vscode_server() {
    debug "=== Finding VS Code server installation ==="
    
    local vscode_dir server_path
    
    # Try common locations for the VS Code server
    for dir in "/home/vscode/.vscode-server/bin" "/vscode/vscode-server/bin"; do
        if [ -d "$dir" ]; then
            vscode_dir=$(ls -t "$dir" 2>/dev/null | head -n 1)
            if [ -n "$vscode_dir" ]; then
                server_path="$dir/$vscode_dir/bin/code-server"
                if [ -x "$server_path" ]; then
                    debug "Found VS Code server at: $server_path"
                    echo "$server_path"
                    return 0
                fi
            fi
        fi
    done
    
    error "VS Code server binary not found"
    return 1
}

# Get installed extension version
get_extension_version() {
    local ext_id="$1"
    local code_server="$2"
    
    "$code_server" --accept-server-license-terms --list-extensions --show-versions 2>/dev/null | grep "^${ext_id}@" | cut -d'@' -f2 || echo "Not installed"
}

# Check if extension is installed
is_extension_installed() {
    local ext_id="$1"
    local code_server="$2"
    
    "$code_server" --accept-server-license-terms --list-extensions 2>/dev/null | grep -q "^$ext_id$"
}

# Function to check extension state
check_extension_state() {
    local extension_id=$1
    local action=$2
    local extension_name=$3
    
    debug "=== Checking state for extension: $extension_id ==="
    echo
    echo "🔍 Checking extension state for $extension_name..."
    
    # Initialize states
    local server_state="not installed"
    local client_state="not installed"
    
    # Check in VS Code server (devcontainer)
    if [ -n "$CODE_SERVER" ]; then
        if "$CODE_SERVER" --accept-server-license-terms --list-extensions 2>/dev/null | grep -q "^$extension_id$"; then
            server_state="installed"
        fi
    else
        server_state="unknown (server not found)"
    fi
    
    # Multiple checks for client-side installation
    if command -v code >/dev/null 2>&1; then
        # Check using VS Code CLI
        if code --list-extensions 2>/dev/null | grep -q "^$extension_id$"; then
            client_state="installed"
        else
            # Check common extension installation locations
            local extension_paths=(
                "$HOME/.vscode/extensions/${extension_id}-*"
                "$HOME/.vscode-server/extensions/${extension_id}-*"
                "/usr/share/code/resources/app/extensions/${extension_id}-*"
            )
            
            for path in "${extension_paths[@]}"; do
                if compgen -G "$path" > /dev/null; then
                    client_state="installed (found in $path)"
                    break
                fi
            done
        fi
    else
        client_state="unknown (code command not found)"
    fi
    
    echo "Extension state:"
    echo "- VS Code Server (devcontainer): $server_state"
    echo "- VS Code Client: $client_state"
    
    if [[ "$client_state" == *"installed"* ]]; then
        echo
        echo "⚠️  Action needed:"
        if [ "$action" = "install" ]; then
            echo "To complete the installation, please:"
        else
            echo "To complete the uninstallation, please:"
        fi
        echo "1. Open Command Palette (Ctrl+Shift+P or Cmd+Shift+P)"
        echo "2. Run 'Developer: Reload Window'"
        echo "3. If extension still appears after reload, try:"
        echo "   - Close all VS Code windows"
        echo "   - Kill any running VS Code processes: 'pkill code'"
        echo "   - Start VS Code again"
        echo
        echo "If the extension still persists, you may need to manually remove it from:"
        echo "- Windows: %USERPROFILE%\\.vscode\\extensions"
        echo "- Mac/Linux: ~/.vscode/extensions"
    fi
}

# Function to install VS Code extensions
process_extensions() {
    debug "=== Starting process_extensions ==="
    
    # Get array reference
    declare -n arr=$1
    
    debug "Array contents:"
    debug "Array size: ${#arr[@]}"
    debug "Array keys: '${!arr[@]}'"
    
    # Find VS Code server
    local CODE_SERVER
    CODE_SERVER=$(find_vscode_server) || return 1
    export CODE_SERVER
    
    # Print header based on mode
    if [ "${UNINSTALL_MODE:-0}" -eq 1 ]; then
        if [ "${FORCE_MODE:-0}" -eq 1 ]; then
            log "Force uninstalling ${#arr[@]} extensions..."
        else
            log "Uninstalling ${#arr[@]} extensions..."
        fi
    else
        log "Installing ${#arr[@]} extensions..."
    fi
    
    echo
    printf "%-25s %-35s %-30s %s\n" "Extension" "Description" "ID" "Status"
    printf "%s\n" "----------------------------------------------------------------------------------------------------"
    
    # Track results
    local installed=0
    local uninstalled=0
    local failed=0
    local skipped=0
    
    # Array to store successful operations for summary
    declare -A successful_ops
    
    # Process each extension
    for ext_id in ${!arr[@]}; do
        debug "=== Processing extension ==="
        debug "ext_id: '$ext_id'"
        debug "Raw value: '${arr[$ext_id]}'"
        
        # Split name and description
        IFS='|' read -r name description _ <<< "${arr[$ext_id]}"
        
        debug "After splitting:"
        debug "  name: '$name'"
        debug "  description: '$description'"
        debug "  ext_id: '$ext_id'"
        
        printf "%-25s %-35s %-30s " "$name" "$description" "$ext_id"
        
        if [ "${UNINSTALL_MODE:-0}" -eq 1 ]; then
            if is_extension_installed "$ext_id" "$CODE_SERVER"; then
                version=$(get_extension_version "$ext_id" "$CODE_SERVER")
                if [ "${FORCE_MODE:-0}" -eq 1 ]; then
                    cmd_options="--force"
                else
                    cmd_options=""
                fi
                if "$CODE_SERVER" --accept-server-license-terms $cmd_options --uninstall-extension "$ext_id" >/dev/null 2>&1; then
                    printf "Uninstalled (was v%s)\n" "$version"
                    uninstalled=$((uninstalled + 1))
                    successful_ops["$name"]=$version
                else
                    printf "Failed to uninstall v%s\n" "$version"
                    failed=$((failed + 1))
                fi
            else
                printf "Not installed\n"
                skipped=$((skipped + 1))
            fi
        else
            if is_extension_installed "$ext_id" "$CODE_SERVER"; then
                version=$(get_extension_version "$ext_id" "$CODE_SERVER")
                printf "v%s\n" "$version"
                skipped=$((skipped + 1))
                successful_ops["$name"]=$version
            else
                if "$CODE_SERVER" --accept-server-license-terms --install-extension "$ext_id" >/dev/null 2>&1; then
                    version=$(get_extension_version "$ext_id" "$CODE_SERVER")
                    printf "Installed v%s\n" "$version"
                    installed=$((installed + 1))
                    successful_ops["$name"]=$version
                else
                    printf "Installation failed\n"
                    failed=$((failed + 1))
                fi
            fi
        fi
    done
    
    echo
    echo "Current Status:"
    # Only show successful operations if there are any
    if [ ${#successful_ops[@]} -gt 0 ]; then
        while IFS= read -r name; do
            if [ "${UNINSTALL_MODE:-0}" -eq 1 ]; then
                printf "* 🗑️  %s (was v%s)\n" "$name" "${successful_ops[$name]}"
            else
                printf "* ✅ %s (v%s)\n" "$name" "${successful_ops[$name]}"
            fi
        done < <(printf '%s\n' "${!successful_ops[@]}" | sort)
    else
        echo "No operations completed successfully"
    fi
    
    echo
    echo "----------------------------------------"
    log "Extension Status Summary"
    echo "Total extensions: ${#arr[@]}"
    if [ "${UNINSTALL_MODE:-0}" -eq 1 ]; then
        echo "  Successfully uninstalled: $uninstalled"
        echo "  Not installed: $skipped"
        echo "  Failed to uninstall: $failed"
    else
        echo "  Already installed: $skipped"
        echo "  Newly installed: $installed"
        echo "  Failed to install: $failed"
    fi
}