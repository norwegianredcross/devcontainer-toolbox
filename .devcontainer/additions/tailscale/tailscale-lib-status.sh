#!/bin/bash
# File: .devcontainer/additions/tailscale-lib-status.sh
#
# Purpose:
#   Manages Tailscale status information, including status caching,
#   parsing, and validation. Provides centralized status management
#   to reduce redundant status calls.
#
# Dependencies:
#   - tailscale-lib-common.sh : Common utilities and logging
#   - jq : JSON processing
#
# Author: Terje Christensen
# Created: November 2024

# Ensure script is being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This script should be sourced, not executed directly"
    exit 1
fi

# containers hostname will have this prefix
readonly DEVCONTAINER_PREFIX="devcontainer"


# Get Tailscale status
get_tailscale_status() {
    local force_refresh="${1:-false}"
    local current_time
    current_time=$(date +%s)



    # Get fresh status
    local status_output
    if ! status_output=$(tailscale status --json 2>&1); then
        # Check if the error message indicates tailscaled is not running
        if [[ "$status_output" == *"failed to connect to local tailscaled"* ]]; then
            log_error "Tailscaled is not running. Try: sudo systemctl start tailscaled"
            return 2
        fi
        log_error "Failed to get Tailscale status: $status_output"
        return 1
    fi

    # Validate that the output is valid JSON
    if ! echo "$status_output" | jq '.' >/dev/null 2>&1; then
        log_error "Invalid JSON output from tailscale status"
        return 1
    fi


    echo "$status_output"
    return 0
}

# Parse status for specific information
parse_status_field() {
    local status_json="$1"
    local field="$2"
    local default="${3:-}"

    local value
    value=$(echo "$status_json" | jq -r "$field")

    if [[ "$value" == "null" || -z "$value" ]]; then
        if [[ -n "$default" ]]; then
            echo "$default"
            return 0
        fi
        return 1
    fi

    echo "$value"
    return 0
}

# Check if Tailscale is running
check_tailscale_running() {
    local status_json
    status_json=$(get_tailscale_status)

    if [[ -z "$status_json" ]]; then
        return 1
    fi

    local backend_state
    backend_state=$(parse_status_field "$status_json" '.BackendState')

    if [[ "$backend_state" != "Running" ]]; then
        return 1
    fi

    return 0
}

generate_unique_hostname() {
    # Extract username part from email and clean it
    local username="${TAILSCALE_USER_EMAIL%@*}"
    # Replace dots and special chars with hyphen
    username=$(echo "$username" | tr '.' '-' | tr -c '[:alnum:]-' '-' | sed 's/-*$//')

    local base_hostname="$DEVCONTAINER_PREFIX-$username"

    echo "$base_hostname"
    return 0
}


# Export required functions
export -f get_tailscale_status parse_status_field check_tailscale_running
export -f generate_unique_hostname
