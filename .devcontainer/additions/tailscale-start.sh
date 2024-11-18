#!/bin/bash
# File: .devcontainer/additions/tailscale-start.sh
#
# Usage: sudo .devcontainer/additions/tailscale-start.sh
# Purpose:
#   Starts and configures Tailscale in a devcontainer environment with proper
#   sequencing, status tracking, and comprehensive network verification.
#
# Author: Terje Christensen
# Created: November 2024
#

set -euo pipefail

# Source all library files
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
readonly SCRIPT_DIR
readonly LIB_DIR="${SCRIPT_DIR}/tailscale"

# List of required library files
readonly REQUIRED_LIBS=(
    "common"     # Common utilities and logging
    "network"    # Network testing and verification
    "status"     # Tailscale status management
    "exitnode"   # Exit node configuration
    "config"     # Configuration management
    "report"     # Status reporting and display
)

# Source library files
for lib in "${REQUIRED_LIBS[@]}"; do
    lib_file="${LIB_DIR}/tailscale-lib-${lib}.sh"
    if [[ ! -f "$lib_file" ]]; then
        echo "Error: Required library file not found: $lib_file"
        exit 1
    fi
    # shellcheck source=/dev/null
    source "$lib_file"
done


# Initialize Tailscale service
initialize_tailscale() {
    log_info "Initializing Tailscale..."

    # Generate unique hostname
    local hostname
    hostname=$(generate_unique_hostname)

    # Stop daemon
    stop_tailscale_daemon || return 1


    # Start daemon
    start_tailscale_daemon || return 1

    # Connect with unique hostname
    establish_tailscale_connection "$hostname" || return 1

    return 0
}

# Configure routing and exit node
configure_routing() {
    log_info "Configuring Tailscale routing..."

    # find the exit node and make sure we can reach it
    local exit_node_info
    exit_node_info=$(find_exit_node) || return 1

    # Setup exit node routing
    setup_exit_node "$exit_node_info" || return 1

    return 0
}

# Final verification and documentation
finalize_setup() {
    log_info "Finalizing Tailscale setup..."

    # Collect final state
    TAILSCALE_CONF_JSON=$(collect_final_state) || return 1


    # Save the configuration
    if ! save_tailscale_conf; then
        log_error "Failed to save Tailscale configuration"
        return 1
    fi

    return 0
}

# Main process
main() {
    log_info "Starting Tailscale setup process..."

    # Check root access immediately
    if ! check_root; then
        return "$EXIT_ENV_ERROR"
    fi

    # Check if Tailscale is already running and properly configured
    log_info "Checking for existing Tailscale configuration..."
    local trace_data
    local test_url="${TAILSCALE_TEST_URL:-www.sol.no}"
    trace_data=$(trace_route "$test_url")
    if verify_exit_node_routing "$trace_data" "$TAILSCALE_DEFAULT_PROXY_HOST"; then
        log_info "Success! Configuration verified"
        exit 0
    else
        log_warn "Exit node routing verification failed"
        # Handle the error case as needed
    fi

    # Record start time for duration calculation
    local start_time
    start_time=$(date +%s)

    # Phase 1: Environment preparation
    if ! prepare_environment; then
        log_error "Failed to prepare environment"
        return "$EXIT_ENV_ERROR"
    fi

    log_info "Environment preparation completed successfully"


    # Phase 2: Tailscale initialization
    if ! initialize_tailscale; then
        log_error "Failed to initialize Tailscale"
        return "$EXIT_TAILSCALE_ERROR"
    fi


    # Phase 3: Routing configuration
    if ! configure_routing; then
        log_error "Failed to configure routing"
        return "$EXIT_EXITNODE_ERROR"
    fi


    # Phase 4: Finalization
    if ! finalize_setup; then
        log_error "Failed to finalize setup"
        return "$EXIT_VERIFY_ERROR"
    fi


    # Record end time
    local end_time
    end_time=$(date +%s)

    # Display completion summary with timing information
    display_completion_summary  "$start_time" "$end_time"
    return "$EXIT_SUCCESS"
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi

