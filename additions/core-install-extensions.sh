#!/bin/bash
# file: .devcontainer/additions/core-install-extensions.sh

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

# Uninstall extension
uninstall_extension() {
    local ext_id="$1"
    local code_server="$2"
    local uninstall_output
    
    debug "Uninstalling extension: $ext_id"
    
    # Capture the uninstall output
    if [ "${FORCE_MODE:-0}" -eq 1 ]; then
        uninstall_output=$("$code_server" --accept-server-license-terms --force --uninstall-extension "$ext_id" 2>&1)
    else
        uninstall_output=$("$code_server" --accept-server-license-terms --uninstall-extension "$ext_id" 2>&1)
    fi
    
    local status=$?
    if [ $status -ne 0 ]; then
        debug "Uninstall output: $uninstall_output"
        # Check if it's a dependency error
        if [[ $uninstall_output == *"depends on"* ]]; then
            error "Extension is a dependency of other extensions. Use --force to override."
        fi
    fi
    return $status
}

# Install extension with retries
install_extension() {
    local ext_id="$1"
    local code_server="$2"
    local max_retries=3
    local retry=0
    local install_output
    
    while [ $retry -lt $max_retries ]; do
        debug "Installing extension: $ext_id (attempt $((retry + 1))/$max_retries)"
        install_output=$("$code_server" --accept-server-license-terms --install-extension "$ext_id" 2>&1)
        
        if [ $? -eq 0 ]; then
            debug "Installation successful"
            return 0
        else
            error "Installation attempt $((retry + 1)) failed:"
            error "$install_output"
            retry=$((retry + 1))
            [ $retry -lt $max_retries ] && sleep 2
        fi
    done
    
    error "Failed to install extension after $max_retries attempts"
    return 1
}

# Process extensions
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
    
    # Save original IFS
    local SAVE_IFS=$IFS
    debug "Original IFS: '$SAVE_IFS'"
    
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
        
        # Set IFS to | for splitting
        IFS='|'
        read -r name description _ <<< "${arr[$ext_id]}"
        IFS=$SAVE_IFS
        
        debug "After splitting:"
        debug "  name: '$name'"
        debug "  description: '$description'"
        debug "  ext_id: '$ext_id'"
        
        printf "%-25s %-35s %-30s " "$name" "$description" "$ext_id"
        
        if [ "${UNINSTALL_MODE:-0}" -eq 1 ]; then
            if is_extension_installed "$ext_id" "$CODE_SERVER"; then
                version=$(get_extension_version "$ext_id" "$CODE_SERVER")
                if uninstall_extension "$ext_id" "$CODE_SERVER"; then
                    printf "Uninstalled (was v%s)\n" "$version"
                    uninstalled=$((uninstalled + 1))
                    successful_ops["$name"]="$version"
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
                successful_ops["$name"]="$version"
            else
                if install_extension "$ext_id" "$CODE_SERVER"; then
                    version=$(get_extension_version "$ext_id" "$CODE_SERVER")
                    printf "Installed v%s\n" "$version"
                    installed=$((installed + 1))
                    successful_ops["$name"]="$version"
                else
                    printf "Installation failed\n"
                    failed=$((failed + 1))
                fi
            fi
        fi
        
        debug "=== Finished processing this extension ==="
    done
    
    debug "=== All extensions processed ==="
    
    echo
    echo "Current Status:"
    # Sort the successful operations by name and display them
    while IFS= read -r name; do
        if [ "${UNINSTALL_MODE:-0}" -eq 1 ]; then
            printf "* 🗑️  %s (was v%s)\n" "$name" "${successful_ops[$name]}"
        else
            printf "* ✅ %s (v%s)\n" "$name" "${successful_ops[$name]}"
        fi
    done < <(printf '%s\n' "${!successful_ops[@]}" | sort)
    
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