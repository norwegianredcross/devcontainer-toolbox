#!/bin/bash
# File: .devcontainer/additions/set-hostname.sh
#
# Purpose:
#   Generates and sets container hostnames for devcontainers.
#   Can be both sourced and executed directly.
#   Only runs once - if hostname is already set, exits cleanly.
#   Format: dev-[platform]-[user]-[original_hostname]
#   
# Usage:
#   Direct execution:
#     ./set-hostname.sh
#   
#   When sourced:
#     source ./set-hostname.sh
#     set_container_id

set -o errexit
set -o pipefail
set -o nounset

# Debug mode support
DEBUG=${DEBUG:-0}
debug_log() {
    if [[ "$DEBUG" -eq 1 ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

##### is_hostname_already_set
# Checks if hostname is already in our format
# Returns: 0 if already set, 1 if not
is_hostname_already_set() {
    local current_hostname
    current_hostname=$(hostname)
    
    if [[ "$current_hostname" =~ ^dev-[^-]+-[^-]+-[[:alnum:]]+$ ]]; then
        debug_log "Hostname already in correct format: $current_hostname"
        return 0
    fi
    return 1
}

##### check_sudo_access
# Verifies sudo is available and can be used
check_sudo_access() {
    if ! command -v sudo >/dev/null 2>&1; then
        echo "❌ Error: 'sudo' is not available"
        return 1
    fi
    return 0
}

##### sanitize_id_component
# Sanitizes any component of the container ID
sanitize_id_component() {
    local input="${1:-}"
    
    if [[ -z "$input" ]]; then
        echo "unknown"
        return
    fi
    
    local sanitized
    sanitized=$(echo "$input" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]-')
    sanitized=$(echo "$sanitized" | sed 's/^-\+//;s/-\+$//;s/-\+/-/g')
    
    if [[ -z "$sanitized" ]]; then
        echo "unknown"
    else
        echo "$sanitized"
    fi
}

##### get_platform_identifier
# Determines if running on Windows or Mac
get_platform_identifier() {
    if [[ -n "${DEV_MAC_USER:-}" ]]; then
        echo "mac"
    elif [[ -n "${DEV_WIN_USERDOMAIN:-}" ]]; then
        echo "win"
    else
        echo "unknown"
    fi
}

##### get_user_identifier
# Gets user identifier based on platform
get_user_identifier() {
    local platform="${1:-unknown}"
    local user_id=""
    
    case "$platform" in
        "win")
            local domain username
            domain="${DEV_WIN_USERDOMAIN:-}"
            username="${DEV_WIN_USERNAME:-}"
            
            if [[ -n "$domain" && -n "$username" ]]; then
                domain=$(sanitize_id_component "$domain")
                username=$(sanitize_id_component "$username")
                user_id="${domain}-${username}"
            elif [[ -n "$username" ]]; then
                user_id=$(sanitize_id_component "$username")
            fi
            ;;
        "mac")
            if [[ -n "${DEV_MAC_USER:-}" ]]; then
                user_id=$(sanitize_id_component "${DEV_MAC_USER}")
            fi
            ;;
    esac
    
    if [[ -z "$user_id" ]]; then
        echo "unknown-user"
    else
        echo "$user_id"
    fi
}

##### generate_container_id
# Generates container ID while preserving original hostname
generate_container_id() {
    local platform user_id original_hostname
    
    platform=$(get_platform_identifier)
    [[ "$platform" == "unknown" ]] && platform="unknown-platform"
    
    user_id=$(get_user_identifier "$platform")
    [[ -z "$user_id" ]] && user_id="unknown-user"
    
    # Use original container hostname
    original_hostname=$(hostname)
    if [[ ! "$original_hostname" =~ ^[[:alnum:]]+$ ]]; then
        original_hostname="unknown-host"
    fi
    
    echo "dev-${platform}-${user_id}-${original_hostname}"
}

##### modify_etc_hosts
# Updates /etc/hosts with new hostname
modify_etc_hosts() {
    local new_hostname="$1"

    # In a container, /etc/hosts might be mounted and busy
    # Just skip if we can't modify it
    if ! grep -q "^127\.0\.0\.1[[:space:]]*${new_hostname}[[:space:]]*$" /etc/hosts; then
        debug_log "hostname entry not found in /etc/hosts, will try to add it"
        if ! echo "127.0.0.1 ${new_hostname}" | sudo tee -a /etc/hosts >/dev/null 2>&1; then
            debug_log "Failed to update /etc/hosts, but this is not critical"
        fi
    fi

    if ! grep -q "^::1[[:space:]]*${new_hostname}[[:space:]]*$" /etc/hosts; then
        debug_log "IPv6 hostname entry not found in /etc/hosts, will try to add it"
        if ! echo "::1 ${new_hostname}" | sudo tee -a /etc/hosts >/dev/null 2>&1; then
            debug_log "Failed to update IPv6 in /etc/hosts, but this is not critical"
        fi
    fi

    return 0
}

##### set_container_id
# Sets the container ID and updates hostname configuration
set_container_id() {
    echo "🏷️ Checking hostname configuration..."

    # Check if already set up
    if is_hostname_already_set; then
        echo "✨ Hostname already configured: $(hostname)"
        return 0
    fi

    # Check sudo access
    if ! check_sudo_access; then
        echo "❌ Cannot proceed without sudo access"
        return 1
    fi

    # Generate and store the container ID
    local NETDATA_CONTAINER_ID
    NETDATA_CONTAINER_ID=$(generate_container_id)

    # Export for current session
    export NETDATA_CONTAINER_ID

    # Add to .bashrc if not present
    if ! grep -q "export NETDATA_CONTAINER_ID='${NETDATA_CONTAINER_ID}'" ~/.bashrc; then
        echo "export NETDATA_CONTAINER_ID='${NETDATA_CONTAINER_ID}'" >> ~/.bashrc
    fi

    echo "✅ Container ID: ${NETDATA_CONTAINER_ID}"

    # Attempt to update /etc/hosts (but don't fail if we can't)
    modify_etc_hosts "$NETDATA_CONTAINER_ID"
    
    # Set hostname
    if ! sudo hostname "$NETDATA_CONTAINER_ID"; then
        echo "❌ Failed to set hostname"
        return 1
    fi

    echo "✅ Hostname set successfully"
    return 0
}

# Handle both direct execution and sourcing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being run directly
    debug_log "Script is being run directly - executing set_container_id"
    set_container_id
else
    # Script is being sourced
    debug_log "Script is being sourced - making functions available"
    # Export functions for use in other scripts
    export -f debug_log is_hostname_already_set sanitize_id_component \
        get_platform_identifier get_user_identifier generate_container_id \
        check_sudo_access modify_etc_hosts set_container_id
fi