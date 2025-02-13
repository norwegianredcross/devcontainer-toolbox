#!/bin/bash
# File: netdata-start.sh
#
# Purpose:
#   Installs and configures Netdata with cloud integration, handling both initial
#   installation and subsequent runs idempotently. Uses environment variables if
#   available, falls back to command line arguments.
#
# Environment Variables:
#   NETDATA_CLAIM_TOKEN : Cloud claiming token
#   NETDATA_CLAIM_ROOMS : Comma-separated list of room IDs
#   NETDATA_CLAIM_URL  : Cloud URL (defaults to https://app.netdata.cloud)
#   ROOTCMD           : Command to use for privilege escalation (optional)
#
# Arguments (fallback if env vars not set):
#   $1: Claim token
#   $2: Room IDs (comma-separated)
#
# Usage:
#   With environment variables:
#     export NETDATA_CLAIM_TOKEN="your_token"
#     export NETDATA_CLAIM_ROOMS="room1,room2"
#     ./netdata-start.sh
#
#   With command line arguments:
#     ./netdata-start.sh "your_token" "room1,room2"
#
# Exit Codes:
#   0: Success
#   1: Missing credentials
#   2: Installation failed
#   3: Configuration failed
#   4: Service start failed
#   5: Verification failed

set -euo pipefail

# Constants
KICKSTART_URL="https://get.netdata.cloud/kickstart.sh"
CLOUD_BASE_URL="https://app.netdata.cloud"

# Logging functions
log_info() {
    echo "[INFO] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

# Root privilege management
confirm_root_support() {
    if [ "$(id -u)" -ne "0" ]; then
        if [ -z "${ROOTCMD:-}" ] && command -v sudo > /dev/null; then
            if [ "${INTERACTIVE:-0}" -eq 0 ]; then
                ROOTCMD="sudo -n"
            else
                ROOTCMD="sudo"
            fi
        fi

        if [ -z "${ROOTCMD:-}" ] && command -v doas > /dev/null; then
            if [ "${INTERACTIVE:-0}" -eq 0 ]; then
                ROOTCMD="doas -n"
            else
                ROOTCMD="doas"
            fi
        fi

        if [ -z "${ROOTCMD:-}" ] && command -v pkexec > /dev/null; then
            ROOTCMD="pkexec"
        fi

        if [ -z "${ROOTCMD:-}" ]; then
            log_error "This script needs root privileges to operate, but cannot find a way to gain them (we support sudo, doas, and pkexec)."
            log_error "Either run with root privileges or set \$ROOTCMD to a command that can be used to gain root privileges."
            return 1
        fi
    fi
    return 0
}

# Run command as root if needed
run_as_root() {
    if [ "$(id -u)" -eq "0" ]; then
        "${@}"
    else
        ${ROOTCMD:-} "${@}"
    fi
}

# Check if Netdata is already installed
is_netdata_installed() {
    if command -v netdata >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# Check if Netdata service is running
is_netdata_running() {
    if run_as_root service netdata status >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# Get ACLK state
get_aclk_state() {
    run_as_root netdatacli aclk-state
}

# Check if ACLK is online
is_aclk_online() {
    get_aclk_state | grep -q "Online: Yes"
    return $?
}

# Check if already claimed based on ACLK state
is_already_claimed() {
    local state
    state=$(get_aclk_state)
    if echo "$state" | grep -q '"agent-claimed":true'; then
        return 0
    fi
    return 1
}

# Set up directories with correct permissions
setup_directories() {
    log_info "Creating necessary directories..."
    run_as_root mkdir -p /var/log/netdata
    run_as_root mkdir -p /var/lib/netdata/cloud.d
    
    log_info "Setting directory permissions..."
    run_as_root chown -R netdata:netdata /var/log/netdata
    run_as_root chown -R netdata:netdata /var/lib/netdata
    run_as_root chmod 0750 /var/log/netdata
    run_as_root chmod 0750 /var/lib/netdata/cloud.d
}

# Configure cloud integration
configure_cloud() {
    local token="$1"
    local rooms="$2"
    local config_file="/var/lib/netdata/cloud.d/cloud.conf"
    local tmp_file
    
    log_info "Creating cloud configuration..."
    
    # Create a secure temporary file
    tmp_file="$(mktemp)"
    
    # Write config to temp file
    cat > "${tmp_file}" << EOF
[global]
    enabled = yes
    cloud base url = ${CLOUD_BASE_URL}

[agent_cloud_link]
    enabled = yes
    claim token = ${token}
    rooms = ${rooms}
EOF

    # Move the file into place with proper ownership and permissions
    run_as_root sh -c "cat '${tmp_file}' > '${config_file}'"
    run_as_root chmod 0640 "${config_file}"
    run_as_root chown netdata:netdata "${config_file}"
    
    # Clean up
    rm -f "${tmp_file}"
}

# Install Netdata using kickstart script
install_netdata() {
    local token="$1"
    local rooms="$2"
    
    log_info "Downloading Netdata kickstart script..."
    if ! wget -O /tmp/netdata-kickstart.sh "$KICKSTART_URL"; then
        log_error "Failed to download kickstart script"
        return 1
    fi

    log_info "Installing Netdata..."
    if ! sh /tmp/netdata-kickstart.sh \
        --non-interactive \
        --stable-channel \
        --claim-token "$token" \
        --claim-rooms "$rooms" \
        --claim-url "$CLOUD_BASE_URL"; then
        log_error "Netdata installation failed"
        return 1
    fi

    return 0
}

# Verify installation and configuration
verify_installation() {
    log_info "Verifying Netdata status..."
    
    # Check service status
    if ! is_netdata_running; then
        log_error "Netdata service is not running"
        return 1
    fi

    # Give ACLK time to establish connection with retries
    log_info "Waiting for ACLK connection..."
    local retries=12  # 60 seconds total
    local success=0
    
    while [ $retries -gt 0 ]; do
        if run_as_root netdatacli aclk-state | grep -q "Online: Yes"; then
            log_info "Successfully connected to Netdata Cloud"
            success=1
            break
        fi
        log_info "Waiting for cloud connection... ($retries attempts left)"
        sleep 5
        retries=$((retries - 1))
    done

    if [ $success -eq 0 ]; then
        log_error "Failed to establish cloud connection within timeout"
        # Show current ACLK state for debugging
        run_as_root netdatacli aclk-state || true
        return 1
    fi

    return 0
}

main() {
    # Get credentials from env vars or arguments
    local token rooms
    token="${NETDATA_CLAIM_TOKEN:-${1:-}}"
    rooms="${NETDATA_CLAIM_ROOMS:-${2:-}}"

    if [[ -z "$token" || -z "$rooms" ]]; then
        log_error "Missing required credentials"
        log_error "Set NETDATA_CLAIM_TOKEN and NETDATA_CLAIM_ROOMS or provide as arguments"
        exit 1
    fi

    # Verify root access is available
    if ! confirm_root_support; then
        exit 1
    fi

    # Check if already installed and claimed
    if is_netdata_installed && is_netdata_running && is_already_claimed; then
        log_info "Netdata is already installed, running, and claimed"
        exit 0
    fi

    # Install if needed
    if ! is_netdata_installed; then
        if ! install_netdata "$token" "$rooms"; then
            exit 2
        fi
    fi

    # Setup directories and configuration
    if ! setup_directories; then
        log_error "Failed to set up directories"
        exit 3
    fi

    if ! configure_cloud "$token" "$rooms"; then
        log_error "Failed to configure cloud integration"
        exit 3
    fi

    # Always restart the service after configuration
    log_info "Restarting Netdata service..."
    if ! run_as_root service netdata restart; then
        log_error "Failed to restart Netdata service"
        exit 4
    fi

    # Give the service time to start up
    sleep 5
    if ! is_netdata_running; then
        log_info "Starting Netdata service..."
        if ! run_as_root service netdata start; then
            log_error "Failed to start Netdata service"
            exit 4
        fi
    else
        log_info "Restarting Netdata service..."
        if ! run_as_root service netdata restart; then
            log_error "Failed to restart Netdata service"
            exit 4
        fi
    fi

    # Verify everything is working
    if ! verify_installation; then
        log_error "Installation verification failed"
        exit 5
    fi

    log_info "Netdata installation and configuration completed successfully"
    log_info "To view your dashboard, visit: http://localhost:19999"
    log_info "To view in Netdata Cloud, visit: ${CLOUD_BASE_URL}"
    exit 0
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi