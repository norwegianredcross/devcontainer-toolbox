#!/bin/bash
# File: .devcontainer/additions/tailscale-lib-exitnode.sh
#
# Purpose:
#   Manages Tailscale exit node configuration, verification, and monitoring.
#   Handles setup, verification, and routing checks for exit nodes.
#
# Dependencies:
#   - tailscale-lib-common.sh : Common utilities and logging
#   - tailscale-lib-status.sh : Status management
#   - tailscale-lib-network.sh : Network verification
#   - jq : JSON processing
#
# Author: Terje Christensen
# Created: November 2024

# Ensure script is being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This script should be sourced, not executed directly"
    exit 1
fi

# Configuration with defaults
SETUP_RETRY_COUNT="${SETUP_RETRY_COUNT:-3}"
SETUP_RETRY_DELAY="${SETUP_RETRY_DELAY:-2}"

##### find_exit_node
# Find and verify connectivity to a Tailscale exit node with retries
# Prints: Progress of connection attempts and any error messages
#
# This function attempts to locate a specified exit node and verify that it's
# accessible with multiple retry attempts.
#
# Environment Variables:
#   TAILSCALE_DEFAULT_PROXY_HOST (string): Default proxy hostname (default: "devcontainerproxy")
#
# Returns:
#   0: Success, outputs JSON object with the following structure:
#      {
#        "id": "string",         # Unique identifier of the exit node
#        "hostname": "string",   # Host name of the exit node
#        "ip": "string",        # Tailscale IP address
#        "online": boolean,     # Whether the node is currently online
#        "connection": "string", # Current connection address
#        "exitNode": boolean,   # Whether this is currently set as exit node
#        "exitNodeOption": boolean # Whether this node can be an exit node
#      }
#   EXIT_EXITNODE_ERROR: Failure, with error message and troubleshooting steps
find_exit_node() {
    local proxy_host="${TAILSCALE_DEFAULT_PROXY_HOST:-devcontainerproxy}"
    local max_retries=3
    local retry_delay=5
    local attempt=1

    log_info "Looking for exit node: ${proxy_host}"

    local exit_node_info
    exit_node_info=$(get_valid_exit_node "$proxy_host") || return 1

    local exit_node_ip
    exit_node_ip=$(echo "$exit_node_info" | jq -r '.ip' | tr -d '\n')

    while ((attempt <= max_retries)); do
        log_info "Attempt $attempt/$max_retries: Verifying connectivity to exit node..."

        local result
        result=$(check_basic_connectivity "$exit_node_ip" 5 1)
        local connect_status=$?

        if [[ $connect_status -eq 0 ]]; then
            print_connectivity_check "$result" 0
            printf '%s' "$exit_node_info"  # Use printf to avoid adding newline
            return 0
        fi

        attempt=$((attempt + 1))
        if ((attempt <= max_retries)); then
            log_info "Waiting ${retry_delay}s before retry..."
            sleep "$retry_delay"

            # Re-verify exit node status
            exit_node_info=$(get_valid_exit_node "$proxy_host") || return 1
            exit_node_ip=$(echo "$exit_node_info" | jq -r '.ip' | tr -d '\n')
        fi
    done

    log_error "Could not establish reliable connection to exit node after $max_retries attempts"
    log_info "Troubleshooting steps:"
    log_info "1. Check if exit node '${proxy_host}' is running and accessible"
    log_info "2. Verify network connectivity between container and exit node"
    log_info "3. Check Tailscale status on exit node: tailscale status"
    return "$EXIT_EXITNODE_ERROR"
}

##### get_valid_exit_node
# Get information about a specific Tailscale exit node
# Prints: Info about the exit node found or error messages when not found
#
# Arguments:
#   $1 - proxy_host (string): The hostname of the exit node to look for
#
# Returns:
#   0: Success, outputs JSON object with the following structure:
#      {
#        "id": "string",         # Unique identifier of the exit node
#        "hostname": "string",   # Host name of the exit node
#        "ip": "string",        # Tailscale IP address
#        "online": boolean,     # Whether the node is currently online
#        "connection": "string", # Current connection address
#        "exitNode": boolean,   # Whether this is currently set as exit node
#        "exitNodeOption": boolean # Whether this node can be an exit node
#      }
#   1: Failure, with error message
get_valid_exit_node() {
    local proxy_host="$1"
    local status_json

    if ! status_json=$(get_tailscale_status); then
        log_error "Failed to get Tailscale status"
        return 1
    fi

    local exit_node_info
    exit_node_info=$(echo "$status_json" | jq -r --arg name "$proxy_host" '
        .Peer | to_entries[] |
        select(.value.HostName == $name and .value.ExitNodeOption == true) |
        {
            id: .key,
            hostname: .value.HostName,
            ip: .value.TailscaleIPs[0],
            online: .value.Online,
            connection: .value.CurAddr,
            exitNode: .value.ExitNode,
            exitNodeOption: .value.ExitNodeOption
        }
    ')

    if [[ -z "$exit_node_info" || "$exit_node_info" == "null" ]]; then
        log_error "No suitable exit node found with name: ${proxy_host}"
        show_available_exit_nodes "$status_json"
        return 1
    fi

    local online_status=$(echo "$exit_node_info" | jq -r '.online')
    local node_ip=$(echo "$exit_node_info" | jq -r '.ip')

    if [[ "$online_status" != "true" ]]; then
        log_error "Exit node '${proxy_host}' exists but is offline"
        return 1
    fi

    log_info "Found exit node: ${proxy_host} (${node_ip}) status: ${online_status}"
    echo "$exit_node_info"
    return 0
}

##### show_available_exit_nodes
# Display a list of all available Tailscale exit nodes and their status
# Prints: Formatted list of exit nodes with their details
#
# This function parses Tailscale status JSON and displays all nodes that can
# act as exit nodes, showing their connection details and status.
#
# Arguments:
#   $1 - status_json (string): JSON output from Tailscale status command
#
# Output format:
#   hostname:
#     IP: <tailscale_ip>
#     Online: <true|false>
#     Connection: <direct_ip|relay>
#
# Returns:
#   0: Always succeeds
show_available_exit_nodes() {
    local status_json="$1"

    log_info "Available exit nodes:"
    echo "$status_json" | jq -r '
        .Peer | to_entries[] |
        select(.value.ExitNodeOption == true) |
        "  \(.value.HostName):\n    IP: \(.value.TailscaleIPs[0])\n    Online: \(.value.Online)\n    Connection: \(.value.CurAddr // "relay")"
    '
}

##### setup_exit_node
# Configure a Tailscale node as an exit node with retry mechanism
# Prints: Progress of configuration steps and status updates
#
# This function configures Tailscale to use a specific node as an exit node,
# with support for LAN access control and automatic retries on failure.
#
# Arguments:
#   $1 - exit_node_info (string): JSON object containing exit node details:
#      {
#        "hostname": "string",   # Host name of the exit node
#        "ip": "string"         # Tailscale IP address
#      }
#
# Environment Variables:
#   TAILSCALE_EXIT_NODE_ALLOW_LAN (string): Whether to allow LAN access (default: "true")
#   SETUP_RETRY_COUNT (integer): Number of setup attempts to make
#   SETUP_RETRY_DELAY (integer): Seconds to wait between retries
#
# Returns:
#   0: Success, exit node configured and verified
#   EXIT_EXITNODE_ERROR: Failure to configure or verify exit node
setup_exit_node() {
    local exit_node_info="$1"
    local allow_lan="${TAILSCALE_EXIT_NODE_ALLOW_LAN:-true}"
    local retry_count=0

    local proxy_host
    proxy_host=$(echo "$exit_node_info" | jq -r '.hostname')
    local exit_node_ip
    exit_node_ip=$(echo "$exit_node_info" | jq -r '.ip')

    log_info "Configuring exit node '${proxy_host}' (${exit_node_ip})..."

    # Prepare configuration options
    local config_options=(
        "--reset"
        "--exit-node=$exit_node_ip"
        "--exit-node-allow-lan-access=$allow_lan"
    )

    # Configure exit node with retries
    while ((retry_count < SETUP_RETRY_COUNT)); do
        log_info "Configuring exit node (attempt $((retry_count + 1))/${SETUP_RETRY_COUNT})..."

        if ! tailscale up "${config_options[@]}"; then
            retry_count=$((retry_count + 1))
            if ((retry_count < SETUP_RETRY_COUNT)); then
                log_warn "Exit node configuration failed, retrying in ${SETUP_RETRY_DELAY} seconds..."
                sleep "$SETUP_RETRY_DELAY"
                continue
            fi
            log_error "Failed to configure exit node after ${SETUP_RETRY_COUNT} attempts"
            return "$EXIT_EXITNODE_ERROR"
        fi

        # Wait for configuration to apply
        log_info "Waiting for exit node configuration to apply..."
        local verification_attempts=10
        local verification_count=0
        while ((verification_count < verification_attempts)); do
            # Get current status
            local status_json
            status_json=$(get_tailscale_status)

            # Check if exit node is configured
            if echo "$status_json" | jq -e --arg ip "$exit_node_ip" \
                '.ExitNodeStatus.TailscaleIPs[] | select(. | startswith($ip))' >/dev/null; then
                log_info "Exit node success. Traffic will now go through '${proxy_host}' (${exit_node_ip})"
                return 0
            fi

            # If not configured yet, wait and retry
            verification_count=$((verification_count + 1))
            if ((verification_count < verification_attempts)); then
                log_debug "Waiting for exit node configuration... ($verification_count/$verification_attempts)"
                sleep 2
            fi
        done

        # If verification failed, retry complete setup
        retry_count=$((retry_count + 1))
        if ((retry_count < SETUP_RETRY_COUNT)); then
            log_warn "Exit node verification failed, retrying complete setup..."
            sleep "$SETUP_RETRY_DELAY"
            continue
        fi
    done

    log_error "Failed to verify exit node configuration"
    return "$EXIT_EXITNODE_ERROR"
}

##### verify_exit_node_routing
# Verify that traffic is being routed through the specified exit node
# by checking if it appears in the traceroute output
#
# Arguments:
#   $1 - trace_data (string): JSON traceroute data
#   $2 - proxy_host (string): Hostname of the exit node to verify
#
# Returns:
#   0: Success, exit node found in traceroute
#   1: Failure, exit node not found in traceroute
verify_exit_node_routing() {
    local trace_data="$1"
    local proxy_host="${2:-devcontainerproxy}"

    # Check first hop for exit node
    local first_hop
    first_hop=$(echo "$trace_data" | jq -r '.hops[0].probes[0].name // empty')

    if [[ -z "$first_hop" ]]; then
        log_error "No valid traceroute data found"
        return 1
    fi

    # Check if the first hop matches our exit node
    if [[ "$first_hop" == *"$proxy_host"* ]]; then
        log_info "Traffic is correctly routing through exit node: $proxy_host"
        return 0
    else
        log_error "Traffic is not routing through exit node. First hop: $first_hop"
        return 1
    fi
}


# Export required functions
export -f find_exit_node setup_exit_node verify_exit_node_routing

