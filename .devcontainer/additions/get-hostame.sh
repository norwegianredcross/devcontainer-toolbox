#!/bin/bash
# File: .devcontainer/additions/get-hostname.sh
#
# Purpose:
#   Generates and outputs a container ID. Can be used in three ways:
#   1. Run directly to get the ID: 
#      ./get-hostname.sh
#   2. Source to set NETDATA_CONTAINER_ID: 
#      source get-hostname.sh
#   3. Use with eval to set NETDATA_CONTAINER_ID:
#      eval "$(./get-hostname.sh --export)"
#
# Container ID Format:
#   Pattern: dev-[platform]-[user]-[host]
#
#   Components:
#   1. Platform Identifier [platform]:
#      - 'mac': When DEV_MAC_USER is set
#      - 'win': When DEV_WIN_USERDOMAIN is set
#      - 'unknown-platform': When platform cannot be determined
#
#   2. User Identifier [user]:
#      Windows format: [domain]-[username] or [username]
#        - Domain from DEV_WIN_USERDOMAIN
#        - Username from DEV_WIN_USERNAME
#        Example: z94-105010erfl
#
#      Mac format: [username]
#        - Username from DEV_MAC_USER
#        Example: terje-christensen
#
#      Email handling:
#        Input:  first.last@example.com
#        Output: firstlast-examplecom
#
#   3. Host Identifier [host]:
#      Container hostname from 'hostname' command
#      Example: 0d0709da06c9
#
#   Sanitization Rules:
#   - Converted to lowercase
#   - Only alphanumeric and hyphens allowed
#   - Multiple hyphens compressed to single hyphen
#   - Leading/trailing hyphens removed
#   - Empty/invalid values become 'unknown'
#
#   Example IDs:
#   Windows: dev-win-z94-105010erfl-0d0709da06c9
#   Mac:     dev-mac-terje-christensen-0d0709da06c9
#   Email:   dev-win-z94-firstlast-examplecom-0d0709da06c9

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

sanitize_user_id() {
    local user_id="${1:-}"
    
    if [[ -z "$user_id" ]]; then
        echo "unknown-user"
        return
    fi
    
    if [[ "$user_id" == *"@"* ]]; then
        local local_part domain
        local_part=$(echo "$user_id" | cut -d'@' -f1 | sanitize_id_component)
        domain=$(echo "$user_id" | cut -d'@' -f2 | sanitize_id_component)
        
        [[ -z "$local_part" || "$local_part" == "unknown" ]] && local_part="unknown"
        [[ -z "$domain" || "$domain" == "unknown" ]] && domain="unknown"
        
        echo "${local_part}-${domain}"
    else
        sanitize_id_component "$user_id"
    fi
}

get_platform_identifier() {
    if [[ -n "${DEV_MAC_USER:-}" ]]; then
        echo "mac"
    elif [[ -n "${DEV_WIN_USERDOMAIN:-}" ]]; then
        echo "win"
    else
        echo "unknown"
    fi
}

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
                username=$(sanitize_user_id "$username")
                user_id="${domain}-${username}"
            elif [[ -n "$username" ]]; then
                user_id=$(sanitize_user_id "$username")
            fi
            ;;
        "mac")
            if [[ -n "${DEV_MAC_USER:-}" ]]; then
                user_id=$(sanitize_user_id "${DEV_MAC_USER}")
            fi
            ;;
    esac
    
    if [[ -z "$user_id" || "$user_id" == "unknown" ]]; then
        echo "unknown-user"
    else
        echo "$user_id"
    fi
}

get_container_hostname() {
    local host
    host=$(hostname 2>/dev/null || echo "unknown-host")
    sanitize_id_component "$host"
}

generate_container_id() {
    local platform user_id host_id
    
    platform=$(get_platform_identifier)
    [[ "$platform" == "unknown" ]] && platform="unknown-platform"
    
    user_id=$(get_user_identifier "$platform")
    [[ -z "$user_id" ]] && user_id="unknown-user"
    
    host_id=$(get_container_hostname)
    [[ -z "$host_id" ]] && host_id="unknown-host"
    
    local container_id="dev-${platform}-${user_id}-${host_id}"
    container_id=$(echo "$container_id" | sed 's/-\+/-/g' | sed 's/^-\+//;s/-\+$//')
    
    echo "$container_id"
}

# Generate the container ID
NETDATA_CONTAINER_ID=$(generate_container_id)

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being run directly
    if [[ "${1:-}" == "--export" ]]; then
        # Output export command for eval
        echo "export NETDATA_CONTAINER_ID='${NETDATA_CONTAINER_ID}'"
    else
        # Just output the ID
        echo "$NETDATA_CONTAINER_ID"
    fi
else
    # Script is being sourced
    export NETDATA_CONTAINER_ID
    if [[ "${DEBUG:-0}" == "1" ]]; then
        debug_log "Container ID set: ${NETDATA_CONTAINER_ID}"
        debug_log "Environment variables:"
        env | grep -E "^(DEV_|NETDATA_)" >&2
    fi
fi