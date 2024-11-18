#!/bin/bash
# File: .devcontainer/additions/tailscale-lib-common.sh
#
# Purpose:
#   Common utilities and functions used across all Tailscale scripts.
#   Includes logging, error handling, environment loading, and basic validations.
#
# Used by:
#   - tailscale-start2.sh
#   - Other tailscale-lib-*.sh libraries
#
# Functions:
#   - Logging (info, error, debug)
#   - Environment loading and validation
#   - Capability checking
#   - Common utilities
#
# Environment requirements:
#   Reads from .devcontainer.extend/tailscale.env
#
# Dependencies:
#   - capsh (from libcap2-bin) for capability checking
#
# Author: Terje Christensen
# Created: November 2024
#

# Ensure script is being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This script should be sourced, not executed directly"
    exit 1
fi

readonly TAILSCALE_DEFAULT_PROXY_HOST="devcontainerproxy"

# Global configuration
readonly TAILSCALE_ENV_FILE="/workspace/.devcontainer.extend/tailscale.env"
readonly TAILSCALE_CONF_FILE="/workspace/.devcontainer.extend/tailscale.conf"

# Optional configuration with defaults
TAILSCALE_LOG_TO_CONSOLE="${TAILSCALE_LOG_TO_CONSOLE:-false}"
TAILSCALE_LOG_LEVEL="${TAILSCALE_LOG_LEVEL:-info}"

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_ENV_ERROR=1
readonly EXIT_NETWORK_ERROR=2
readonly EXIT_TAILSCALE_ERROR=3
readonly EXIT_EXITNODE_ERROR=4
readonly EXIT_VERIFY_ERROR=5

# Logging functions
log_info() {
    echo "[INFO] $*" >&2
    return 0
}

log_error() {
    echo "[ERROR] $*" >&2
    return 0
}

log_debug() {
    if [[ "${TAILSCALE_LOG_TO_CONSOLE:-false}" == "true" ]]; then
        echo "[DEBUG] $*" >&2
    fi
    return 0
}

log_warn() {
    echo "[WARN] $*" >&2
    return 0
}

# Load and validate environment
# Enhanced load_environment function
load_environment() {
    if [[ ! -f "$TAILSCALE_ENV_FILE" ]]; then
        log_error "Environment file not found: $TAILSCALE_ENV_FILE"
        return 1
    fi

    log_debug "Loading environment from: $TAILSCALE_ENV_FILE"

    # shellcheck source=/dev/null
    source "$TAILSCALE_ENV_FILE"

    # Required variables categorized by purpose
    declare -A required_vars=(
        # User Configuration
        ["TAILSCALE_USER_EMAIL"]="Email for container hostname generation"

        # Exit Node Configuration
        ["TAILSCALE_DEFAULT_PROXY_HOST"]="Default exit node hostname"
        ["TAILSCALE_EXIT_NODE_ENABLED"]="Exit node enablement flag"
        ["TAILSCALE_EXIT_NODE_ALLOW_LAN"]="LAN access configuration"

        # Connection Settings
        ["TAILSCALE_CONNECT_TIMEOUT"]="Connection timeout in seconds"
        ["TAILSCALE_MAX_RETRIES"]="Maximum connection retry attempts"

        # Directory Structure
        ["TAILSCALE_BASE_DIR"]="Base directory for Tailscale"
        ["TAILSCALE_STATE_DIR"]="State directory"
        ["TAILSCALE_RUNTIME_DIR"]="Runtime directory"
        ["TAILSCALE_LOG_BASE"]="Base log directory"
        ["TAILSCALE_LOG_DAEMON_DIR"]="Daemon log directory"
        ["TAILSCALE_LOG_AUDIT_DIR"]="Audit log directory"

        # Logging Configuration
        ["TAILSCALE_LOG_LEVEL"]="Log level (debug|info|warn|error)"
        ["TAILSCALE_VERBOSE_LEVEL"]="Daemon verbosity level (0-2)"
    )

    # Optional variables with defaults
    declare -A optional_vars=(
        ["TAILSCALE_LOG_TO_CONSOLE"]="false"
        ["TAILSCALE_TEST_URL"]="www.sol.no"
        ["TAILSCALE_TAGS"]="dev,container"
        ["TAILSCALE_DIR_MODE"]="0750"
        ["TAILSCALE_FILE_MODE"]="0640"
    )

    # Check required variables
    local missing_vars=()
    local invalid_vars=()

    for var in "${!required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        else
            # Validate specific variables
            case "$var" in
                TAILSCALE_LOG_LEVEL)
                    if [[ ! "${!var}" =~ ^(debug|info|warn|error)$ ]]; then
                        invalid_vars+=("$var (must be debug|info|warn|error)")
                    fi
                    ;;
                TAILSCALE_VERBOSE_LEVEL)
                    if [[ ! "${!var}" =~ ^[0-2]$ ]]; then
                        invalid_vars+=("$var (must be 0-2)")
                    fi
                    ;;
                TAILSCALE_EXIT_NODE_ENABLED|TAILSCALE_EXIT_NODE_ALLOW_LAN)
                    if [[ ! "${!var}" =~ ^(true|false)$ ]]; then
                        invalid_vars+=("$var (must be true|false)")
                    fi
                    ;;
                TAILSCALE_CONNECT_TIMEOUT|TAILSCALE_MAX_RETRIES)
                    if [[ ! "${!var}" =~ ^[0-9]+$ ]]; then
                        invalid_vars+=("$var (must be a number)")
                    fi
                    ;;
            esac
        fi
    done

    # Set defaults for optional variables if not set
    for var in "${!optional_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            # Using declare to set the variable in the parent scope
            declare -g "$var=${optional_vars[$var]}"
            log_debug "Setting default for $var: ${optional_vars[$var]}"
        fi
    done

    # Report any issues
    if ((${#missing_vars[@]} > 0)) || ((${#invalid_vars[@]} > 0)); then
        if ((${#missing_vars[@]} > 0)); then
            log_error "Missing required environment variables:"
            for var in "${missing_vars[@]}"; do
                log_error "- $var (${required_vars[$var]})"
            done
        fi
        if ((${#invalid_vars[@]} > 0)); then
            log_error "Invalid environment variable values:"
            for var in "${invalid_vars[@]}"; do
                log_error "- $var"
            done
        fi
        return 1
    fi

    # Verify directory permissions if directories exist
    local dir_vars=(
        "TAILSCALE_BASE_DIR"
        "TAILSCALE_STATE_DIR"
        "TAILSCALE_RUNTIME_DIR"
        "TAILSCALE_LOG_BASE"
        "TAILSCALE_LOG_DAEMON_DIR"
        "TAILSCALE_LOG_AUDIT_DIR"
    )

    for dir_var in "${dir_vars[@]}"; do
        if [[ -d "${!dir_var}" ]]; then
            if ! [[ -r "${!dir_var}" && -w "${!dir_var}" ]]; then
                log_warn "Directory ${!dir_var} exists but has incorrect permissions"
            fi
        fi
    done

    log_info "Environment loaded successfully"
    log_debug "Using email: $TAILSCALE_USER_EMAIL"
    log_debug "Exit node: $TAILSCALE_DEFAULT_PROXY_HOST (enabled: $TAILSCALE_EXIT_NODE_ENABLED)"

    return 0
}


# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        return 1
    fi
    return 0
}

# Check container capabilities
check_capabilities() {
    log_info "Checking container capabilities..."

    # Use existing check_root function
    if ! check_root; then
        return "$EXIT_ENV_ERROR"
    fi

    # Track verification status
    local verification_results=()

    # 1. Check and install capsh
    if ! command -v capsh >/dev/null; then
        log_info "Installing libcap2-bin for capability checking..."
        if ! apt-get update -qq && apt-get install -y libcap2-bin >/dev/null 2>&1; then
            log_error "Failed to install libcap2-bin"
            return "$EXIT_ENV_ERROR"
        fi
    fi

    # 2. Check required capabilities
    local current_caps
    current_caps=$(capsh --print 2>/dev/null | grep "Current:" || echo "")

    # Required capabilities with descriptions
    local -A required_caps=(
        ["cap_net_admin"]="Required for network interface management"
        ["cap_net_raw"]="Required for raw network access"
        ["cap_sys_admin"]="Required for system administration tasks"
        ["cap_audit_write"]="Required for audit logging"
    )

    local missing_caps=()
    for cap in "${!required_caps[@]}"; do
        if ! echo "$current_caps" | grep -q "$cap"; then
            missing_caps+=("$cap")
            verification_results+=("✗ Missing $cap - ${required_caps[$cap]}")
        else
            verification_results+=("✓ Found $cap")
        fi
    done

    # 3. Verify TUN device
    if [[ ! -c /dev/net/tun ]]; then
        verification_results+=("✗ TUN device not available at /dev/net/tun")
        missing_caps+=("TUN")
    else
        verification_results+=("✓ TUN device available")
    fi

    # Display verification results
    log_info "Capability Verification Results:"
    for result in "${verification_results[@]}"; do
        if [[ $result == "✓"* ]]; then
            log_info "$result"
        else
            log_error "$result"
        fi
    done

    # If any checks failed, provide guidance
    if ((${#missing_caps[@]} > 0)); then
        log_error "Missing required capabilities"
        log_info "Please ensure your devcontainer.json includes:"
        cat << EOF
"runArgs": [
    "--cap-add=NET_ADMIN",
    "--cap-add=NET_RAW",
    "--cap-add=SYS_ADMIN",
    "--cap-add=AUDIT_WRITE",
    "--device=/dev/net/tun:/dev/net/tun",
    "--privileged"
]
EOF
        return "$EXIT_ENV_ERROR"
    fi

    log_info "All required capabilities are present"
    return "$EXIT_SUCCESS"
}

# Utility function to check command availability
check_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null; then
        log_error "Required command not found: $cmd"
        return 1
    fi
    return 0
}

# Verify required commands are available
check_dependencies() {
    # Define commands and their installation methods
    declare -A required_cmds=(
        ["jq"]="apt-get install -y jq"
        ["traceroute"]="apt-get install -y traceroute"
        ["ip"]="apt-get install -y iproute2"
        ["tailscale"]=""  # Special handling for tailscale
    )

    local missing_cmds=()
    for cmd in "${!required_cmds[@]}"; do
        if ! check_command "$cmd"; then
            if [[ "$cmd" == "tailscale" ]]; then
                log_error "Tailscale not found. Please install it first by running:"
                log_error "sudo .devcontainer/additions/tailscale-install.sh"
                return "$EXIT_ENV_ERROR"
            fi

            log_info "Installing missing command: $cmd"
            if ! eval "${required_cmds[$cmd]}"; then
                log_error "Failed to install $cmd"
                return "$EXIT_ENV_ERROR"
            fi
            # Verify installation
            if ! check_command "$cmd"; then
                log_error "Command $cmd still not available after installation"
                return "$EXIT_ENV_ERROR"
            fi
            log_info "Successfully installed $cmd"
        fi
    done

    return "$EXIT_SUCCESS"
}

# Function to safely create directories
create_directory() {
    local dir="$1"
    local mode="${2:-0750}"  # Default mode if not specified

    if [[ ! -d "$dir" ]]; then
        if ! mkdir -p "$dir"; then
            log_error "Failed to create directory: $dir"
            return 1
        fi
        if ! chmod "$mode" "$dir"; then
            log_error "Failed to set permissions on directory: $dir"
            return 1
        fi
    fi
    return 0
}

# Cleanup function for trap
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Script failed with exit code: $exit_code"
    fi
    return "$exit_code"
}

# Set trap for cleanup
trap cleanup EXIT

# Export required functions and variables
export -f log_info log_error log_debug log_warn
export -f check_root check_capabilities check_dependencies
export -f load_environment create_directory
export EXIT_SUCCESS EXIT_ENV_ERROR EXIT_NETWORK_ERROR
export EXIT_TAILSCALE_ERROR EXIT_EXITNODE_ERROR EXIT_VERIFY_ERROR
