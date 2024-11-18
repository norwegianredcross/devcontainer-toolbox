#!/bin/bash
# File: .devcontainer/additions/tailscale-lib-config.sh
#
# Purpose:
#   Manages Tailscale configuration generation, saving, and loading.
#   Handles configuration file management and state tracking.
#
# Dependencies:
#   - tailscale-lib-common.sh : Common utilities and logging
#   - tailscale-lib-status.sh : Status management
#   - tailscale-lib-network.sh : Network information
#   - jq : JSON processing
#
# Author: Terje Christensen
# Created: November 2024

# Ensure script is being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_error "Error: This script should be sourced, not executed directly"
    exit 1
fi

# Configuration state tracking
declare -g NETWORK_INITIAL_ROUTING_JSON=""
declare -g NETWORK_TAILSCALE_ROUTING_JSON=""
declare -g NETWORK_TAILSCALE_STATUS_JSON=""
declare -g TAILSCALE_CONF_JSON=""
declare -g TAILSCALE_STATUS_JSON=""
declare -g CONFIG_VERSION="1.0.0"

# Configuration schema version
readonly CONFIG_SCHEMA_VERSION="1.0.0"




##### collect_final_state
# Collects and combines network state, Tailscale status and routing information
# to create a complete Tailscale configuration.
#
# This function orchestrates the collection of all necessary information:
# 1. Network state (DNS tests, URL connectivity, traceroute)
# 2. Tailscale status information
# 3. Filtered and formatted Tailscale network status
# 4. Creates final configuration JSON
#
# The function uses several global variables to store and pass state:
# - NETWORK_TAILSCALE_ROUTING_JSON: Current network routing state
# - TAILSCALE_STATUS_JSON: Raw Tailscale status
# - NETWORK_TAILSCALE_STATUS_JSON: Processed Tailscale status
# - TAILSCALE_CONF_JSON: Final configuration
#
# Dependencies:
#   - collect_network_state: Collects current network state
#   - get_tailscale_status: Gets raw Tailscale status
#   - convert_tailscale_status2network_tailscale_status: Processes Tailscale status
#   - create_tailscale_conf: Creates final configuration
#
# Returns:
#   - On success: Outputs final configuration JSON
#   - On failure: Returns error code from failed operation
#
# Exit codes:
#   0: Success
#   1: Network state collection failed
#   2: Tailscale status retrieval failed
#   3: Status conversion failed
#   4: Configuration creation failed
collect_final_state() {
   log_info "Collecting final network state..."

   # Collect current network routing state
   NETWORK_TAILSCALE_ROUTING_JSON=$(collect_network_state)
   if [[ $? -ne 0 ]]; then
       log_error "Failed to collect network state"
       return 1
   fi

   # Get current Tailscale status
   TAILSCALE_STATUS_JSON=$(get_tailscale_status true)
   if [[ $? -ne 0 ]]; then
       log_error "Failed to get Tailscale status"
       return 2
   fi


   # Convert Tailscale status to network configuration format
   NETWORK_TAILSCALE_STATUS_JSON=$(convert_tailscale_status2network_tailscale_status)
   if [[ $? -ne 0 ]]; then
       log_error "Failed to convert Tailscale status"
       return 3
   fi


   # Create final configuration
   TAILSCALE_CONF_JSON=$(create_tailscale_conf)
   if [[ $? -ne 0 ]]; then
       log_error "Failed to create configuration"
       return 4
   fi


   # Output the final configuration
   echo "$TAILSCALE_CONF_JSON"
   return 0
}





##### convert_tailscale_status2network_tailscale_status
# Extracts required fields from full Tailscale status JSON
#
# Environment Variables:
#   TAILSCALE_STATUS_JSON: Full Tailscale status JSON
#
# Returns:
#   0: Success, outputs filtered JSON
#   1: Failure
convert_tailscale_status2network_tailscale_status() {
    # Input validation
    if [[ -z "$TAILSCALE_STATUS_JSON" ]]; then
        log_error "No Tailscale status JSON provided"
        return 1
    fi

    # Extract and restructure the status information
    jq -n --argjson status "$TAILSCALE_STATUS_JSON" '{
        Self: {
            ID: $status.Self.ID,
            HostName: $status.Self.HostName,
            DNSName: $status.Self.DNSName,
            UserID: $status.Self.UserID,
            TailscaleIPs: $status.Self.TailscaleIPs,
            AllowedIPs: $status.Self.AllowedIPs,
            Created: $status.Self.Created,
            CapMap: $status.Self.CapMap
        },
        CurrentTailnet: {
            Name: $status.CurrentTailnet.Name,
            MagicDNSSuffix: $status.MagicDNSSuffix,
            MagicDNSEnabled: $status.CurrentTailnet.MagicDNSEnabled
        },
        exitNode: (
            if $status.ExitNodeStatus != null then
            {
                ID: $status.ExitNodeStatus.ID,
                Online: $status.ExitNodeStatus.Online,
                TailscaleIPs: $status.ExitNodeStatus.TailscaleIPs,
                HostName: ($status.Peer[] | select(.ExitNode == true) | .HostName),
                DNSName: ($status.Peer[] | select(.ExitNode == true) | .DNSName)
            }
            else null end
        ),
        userInfo: ($status.User | to_entries[] |
            select(.value.LoginName != "tagged-devices") |
            .value | {
                ID: .ID,
                LoginName: .LoginName,
                DisplayName: .DisplayName,
                ProfilePicURL: .ProfilePicURL,
                Roles: .Roles
            }
        )
    }'
}

##### save_tailscale_conf
# Saves the Tailscale configuration JSON to the specified configuration file
# with proper permissions and ownership.
#
# Environment Variables:
#   TAILSCALE_CONF_JSON: The configuration JSON to save
#   TAILSCALE_CONF_FILE: The target file path (from tailscale-lib-common.sh)
#   TAILSCALE_FILE_MODE: File permission mode (from environment)
#
# Returns:
#   0: Success
#   1: Failed to create directory or save file
save_tailscale_conf() {
    # Input validation
    if [[ -z "$TAILSCALE_CONF_JSON" ]]; then
        log_error "No configuration JSON available to save"
        return 1
    fi

    if [[ -z "$TAILSCALE_CONF_FILE" ]]; then
        log_error "No configuration file path specified"
        return 1
    fi

    # Ensure the directory exists
    local config_dir
    config_dir="$(dirname "$TAILSCALE_CONF_FILE")"
    if ! create_directory "$config_dir" "${TAILSCALE_DIR_MODE:-0750}"; then
        log_error "Failed to create configuration directory: $config_dir"
        return 1
    fi

    # Save the configuration with proper formatting
    if ! echo "$TAILSCALE_CONF_JSON" | jq '.' > "$TAILSCALE_CONF_FILE"; then
        log_error "Failed to save configuration to $TAILSCALE_CONF_FILE"
        return 1
    fi

    # Set file permissions
    if ! chmod "${TAILSCALE_FILE_MODE:-0640}" "$TAILSCALE_CONF_FILE"; then
        log_error "Failed to set permissions on $TAILSCALE_CONF_FILE"
        return 1
    fi

    log_info "Configuration saved to: $TAILSCALE_CONF_FILE"
    return 0
}


##### create_tailscale_conf
# Creates a comprehensive Tailscale configuration JSON object combining
# initial and current network state, Tailscale status, and additional metadata.
#
# This function merges and structures data from multiple sources:
# 1. Schema version and timestamp metadata
# 2. Container identity from Tailscale status
# 3. Tailnet information including DNS settings
# 4. User information
# 5. Exit node configuration and status
# 6. Network state (both initial and current)
#
# Environment Variables Required:
#   NETWORK_INITIAL_ROUTING_JSON: Initial network routing state
#   NETWORK_TAILSCALE_ROUTING_JSON: Current network routing state
#   NETWORK_TAILSCALE_STATUS_JSON: Processed Tailscale status information
#   CONFIG_SCHEMA_VERSION: Schema version for configuration format
#
# Example Output Structure:
# {
#   "schemaVersion": "1.0.0",
#   "configGenerated": "2024-11-14T12:35:23Z",
#   "Self": {
#     "ID": "...",
#     "PublicKey": "...",
#     "HostName": "devcontainer-user",
#     "DNSName": "devcontainer-user.example.com",
#     "UserID": "...",
#     "TailscaleIPs": ["100.x.y.z", "fd7a:..."],
#     "AllowedIPs": ["100.x.y.z/32", "fd7a:.../128"],
#     "Created": "2024-11-14T12:23:03Z",
#     "CapMap": {...}
#   },
#   "CurrentTailnet": {
#     "Name": "example.com",
#     "MagicDNSSuffix": "example.com",
#     "MagicDNSEnabled": true
#   },
#   "exitNode": {
#     "ID": "...",
#     "hostname": "exit-node",
#     "ip": "100.x.y.z",
#     "online": true,
#     "connection": "direct",
#     "exitNode": true,
#     "exitNodeOption": true
#   },
#   "userInfo": {
#     "ID": "...",
#     "LoginName": "user@example.com",
#     "DisplayName": "User Name",
#     "Roles": []
#   },
#   "network": {
#     "initial": {...},
#     "tailscale": {...}
#   }
# }
#
# Returns:
#   - On success: Outputs the complete configuration JSON
#   - On failure: Returns 1 and logs error
#
# Usage Example:
#   config_json=$(create_tailscale_conf)
#   if [[ $? -eq 0 ]]; then
#     echo "$config_json" > config.json
#   fi
create_tailscale_conf() {
    # Input validation
    if [[ -z "$NETWORK_INITIAL_ROUTING_JSON" ]] ||
       [[ -z "$NETWORK_TAILSCALE_ROUTING_JSON" ]] ||
       [[ -z "$NETWORK_TAILSCALE_STATUS_JSON" ]]; then
        log_error "Missing required state information"
        return 1
    fi

    # Create the configuration JSON using jq
    jq -n \
        --arg schemaVersion "$CONFIG_SCHEMA_VERSION" \
        --arg timestamp "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
        --argjson status "$NETWORK_TAILSCALE_STATUS_JSON" \
        --argjson initial "$NETWORK_INITIAL_ROUTING_JSON" \
        --argjson tailscale "$NETWORK_TAILSCALE_ROUTING_JSON" \
        '{
            schemaVersion: $schemaVersion,
            configGenerated: $timestamp,
            Self: $status.Self,
            CurrentTailnet: $status.CurrentTailnet,
            exitNode: $status.exitNode,
            userInfo: $status.userInfo,
            network: {
                initial: $initial,
                tailscale: $tailscale
            }
        }'

    # jq will return non-zero on failure
    return $?
}


# Pre-connection setup and verification
# @param $1 - Optional: Set to "skip-tailscale" to skip Tailscale dependency check
prepare_environment() {
    local skip_tailscale=${1:-""}
    log_info "Preparing environment..."

    # Load environment configuration
    display_setup_progress "Environment" "Loading configuration..." 0 4
    if ! load_environment; then
        log_error "Failed to load environment configuration"
        return "$EXIT_ENV_ERROR"
    fi


    # create and initialize and create folders and files

    display_setup_progress "Environment" "Initalize and create folders..." 1 4
    if ! initialize_tailscale_directories; then
        log_error "Failed to load environment configuration"
        return "$EXIT_ENV_ERROR"
    fi

    # Verify required capabilities
    display_setup_progress "Environment" "Checking capabilities..." 2 4
    if ! check_capabilities; then
        log_error "Failed to verify required capabilities"
        return "$EXIT_ENV_ERROR"
    fi

    # Check required tools
    display_setup_progress "Environment" "Checking dependencies..." 3 4
    if [[ "$skip_tailscale" != "skip-tailscale" ]]; then
        if ! check_dependencies; then
            log_error "Failed to verify required tools"
            return "$EXIT_ENV_ERROR"
        fi
    fi

    # Collect initial network state
    display_setup_progress "Environment" "Collecting initial state..." 4 4
    if ! collect_initial_state; then
        log_error "Failed to collect initial network state"
        return "$EXIT_NETWORK_ERROR"
    fi

    display_setup_progress "Environment" "Environment prepared successfully" 4 4
    return "$EXIT_SUCCESS"
}


##### initialize_tailscale_directories
# Creates all required Tailscale directories with proper permissions
#
# Environment Variables Used:
#   TAILSCALE_BASE_DIR: Base directory for Tailscale
#   TAILSCALE_STATE_DIR: State directory
#   TAILSCALE_RUNTIME_DIR: Runtime directory
#   TAILSCALE_LOG_BASE: Base log directory
#   TAILSCALE_LOG_DAEMON_DIR: Daemon log directory
#   TAILSCALE_LOG_AUDIT_DIR: Audit log directory
#   TAILSCALE_DIR_MODE: Directory permission mode
#
# Returns:
#   0: Success
#   1: Failed to create one or more directories
initialize_tailscale_directories() {
    log_info "Creating required Tailscale directories..."

    # List of required directories with their purpose
    declare -A directories=(
        ["$TAILSCALE_BASE_DIR"]="Base directory"
        ["$TAILSCALE_STATE_DIR"]="State directory"
        ["$TAILSCALE_RUNTIME_DIR"]="Runtime directory"
        ["$TAILSCALE_LOG_BASE"]="Log base directory"
        ["$TAILSCALE_LOG_DAEMON_DIR"]="Daemon logs"
        ["$TAILSCALE_LOG_AUDIT_DIR"]="Audit logs"
    )

    local success=true

    # Create each directory with proper permissions
    for dir in "${!directories[@]}"; do
        log_debug "Creating ${directories[$dir]}: $dir"
        if ! create_directory "$dir" "$TAILSCALE_DIR_MODE"; then
            log_error "Failed to create ${directories[$dir]}: $dir"
            success=false
        fi
    done

    # If any directory creation failed, return error
    if [[ "$success" != "true" ]]; then
        return 1
    fi

    log_info "All required Tailscale directories created successfully"
    return 0
}

# Export required functions
export -f collect_final_state save_tailscale_conf prepare_environment
export -f initialize_tailscale_directories
