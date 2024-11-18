#!/bin/bash
# File: .devcontainer/additions/tailscale-lib-network.sh
#
# Purpose:
#   Provides comprehensive network testing, tracing, and connectivity verification.
#   Handles both pre-Tailscale and post-Tailscale network state analysis.
#
# Dependencies:
#   - tailscale-lib-common.sh : Common utilities and logging
#   - Required tools: ping, traceroute, ip, nc, host, jq, jc
#
# Author: Terje Christensen
# Created: November 2024

# Ensure script is being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_error "Error: This script should be sourced, not executed directly"
    exit 1
fi

# Network test configuration

readonly DEFAULT_PING_TIMEOUT=5
readonly DEFAULT_PING_RETRIES=3



readonly DEFAULT_DNS_SERVERS=(
    "8.8.8.8"      # Google DNS
    "1.1.1.1"      # Cloudflare DNS
    "208.67.222.222" # OpenDNS
)

##### print_connectivity_check
# Prints connectivity check results in a standardized format
#
# Arguments:
#   $1 - result (string): JSON result from connectivity check
#   $2 - success (int): Success status code
#
# Returns:
#   Returns the success status code passed as argument
print_connectivity_check() {
    local result="$1"
    local success=$2
    local reachable=$(echo "$result" | jq -r '.reachable')
    local latency=$(echo "$result" | jq -r '.latency')
    local host=$(echo "$result" | jq -r '.host')
    log_info "Ping to ${host}: Reachable:${reachable} (${latency}ms)"
    return $success
}

##### verify_network_state
# Verifies network state based on specified test type
#
# Arguments:
#   $1 - test_type (string): Type of test to perform (basic, full, or pre-tailscale)
#   $2 - options (string): Optional parameters for the test
#
# Returns:
#   0: Success
#   EXIT_NETWORK_ERROR: Network verification failed
verify_network_state() {
    local test_type="$1"  # basic, full, or pre-tailscale
    local options="${2:-}"

    log_info "Verifying network state (type: ${test_type})"

    case "$test_type" in
        basic)
            result=$(check_basic_connectivity)
            print_connectivity_check "$result" $?
            ;;
        full)
            result=$(check_basic_connectivity)
            print_connectivity_check "$result" $?
            ;;
        pre-tailscale)
            result=$(check_basic_connectivity)
            local success=$?
            print_connectivity_check "$result" $success
            [ $success -eq 0 ] && verify_tun_device
            return $success
            ;;
        *)
            log_error "Unknown test type: $test_type"
            return "$EXIT_NETWORK_ERROR"
            ;;
    esac
}

##### check_basic_connectivity
# Checks basic internet connectivity using ping
#
# Arguments:
#   $1 - target (string): Target host to ping (default: first DNS server)
#   $2 - timeout (int): Ping timeout in seconds
#   $3 - attempts (int): Number of attempts to try
#
# Returns:
#   JSON object with connectivity results
check_basic_connectivity() {
    local target="${1:-${DEFAULT_DNS_SERVERS[0]}}"
    local timeout="${2:-$DEFAULT_PING_TIMEOUT}"
    local attempts="${3:-$DEFAULT_PING_RETRIES}"

    local ping_status=1
    local rtt=""
    local attempt=1

    while [[ $attempt -le $attempts && $ping_status -ne 0 ]]; do
        local ping_data
        ping_data=$(ping -c 1 -W "$timeout" "$target" 2>&1)
        ping_status=$?

        if [[ $ping_status -eq 0 ]]; then
            rtt=$(echo "$ping_data" | grep -oP 'time=\K[0-9.]+')
            break
        fi

        ((attempt++))
        [[ $attempt -le $attempts ]] && sleep 1  # Wait 1 second between retries
    done

    # Return structured JSON data
    jq -n \
        --arg host "$target" \
        --arg reachable "$([ $ping_status -eq 0 ] && echo true || echo false)" \
        --arg latency "${rtt:-0}" \
        '{
            host: $host,
            reachable: $reachable,
            latency: ($latency | tonumber)
        }'
}

##### verify_tun_device
# Verifies TUN device existence and permissions
#
# Returns:
#   0: Success
#   EXIT_NETWORK_ERROR: TUN device verification failed
verify_tun_device() {
    log_info "Verifying TUN device..."

    if [[ ! -c /dev/net/tun ]]; then
        log_error "TUN device not found at /dev/net/tun"
        return "$EXIT_NETWORK_ERROR"
    fi

    # Check permissions
    local tun_perms
    tun_perms=$(stat -c "%a" /dev/net/tun)
    if [[ "$tun_perms" != "666" && "$tun_perms" != "660" ]]; then
        log_warn "TUN device has unexpected permissions: $tun_perms"
    fi

    log_info "TUN device verification successful"
    return 0
}

##### collect_network_state
# Collects comprehensive network state information
#
# Returns:
#   JSON object containing network state information
#   1: If any tests fail
collect_network_state() {
    local test_url="${TAILSCALE_TEST_URL:-www.sol.no}"
    local test_dns="${TEST_DNS:-${DEFAULT_DNS_SERVERS[0]}}"

    # DNS test using check_basic_connectivity
    local dns_test
    dns_test=$(check_basic_connectivity "$test_dns")
    local dns_reachable=$(echo "$dns_test" | jq -r '.reachable')
    local dns_latency=$(echo "$dns_test" | jq -r '.latency')
    log_info "Ping to central DNS (${test_dns}): Reachable:${dns_reachable} (${dns_latency}ms)"

    # URL test using check_basic_connectivity
    local url_test
    url_test=$(check_basic_connectivity "$test_url")
    local url_reachable=$(echo "$url_test" | jq -r '.reachable')
    local url_latency=$(echo "$url_test" | jq -r '.latency')
    log_info "Ping to test URL (${test_url}): Reachable:${url_reachable} (${url_latency}ms)"

    # Traceroute with jc
    local trace_data
    trace_data=$(trace_route "$test_url")

    # Check if any of the tests failed
    if [[ "$dns_reachable" != "true" ]] || [[ "$url_reachable" != "true" ]]; then
        return 1
    fi

    # Build and output the JSON response
    jq -n \
        --arg timestamp "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
        --argjson dns "$dns_test" \
        --argjson url "$url_test" \
        --argjson trace "$trace_data" \
        '{
            timestamp: $timestamp,
            testDNS: $dns,
            testUrl: $url,
            traceroute: $trace
        }'

    return 0
}

##### trace_route
# Performs traceroute to target and returns JSON formatted results
# Prints hop information in a human-readable format
#
# Arguments:
#   $1 - target (string): Target host for traceroute (default: DEFAULT_TEST_DOMAIN)
#
# Returns:
#   JSON object containing traceroute data
trace_route() {
    local target="${1:-$DEFAULT_TEST_DOMAIN}"
    local max_hops=10
    local timeout=2

    # First check if we get any valid response
    local trace_output
    trace_output=$(LANG=C traceroute -w "$timeout" -m "$max_hops" "$target" 2>/dev/null)

    # Check if we got any valid hops (lines that don't contain only asterisks)
    if ! echo "$trace_output" | grep -v '^\s*[0-9]*\s\*\s\*\s\*$' > /dev/null; then
        log_warn "No valid traceroute path found - all hops timed out"
        return 1
    fi

    local trace_json
    trace_json=$(echo "$trace_output" | jc --traceroute)

    # Print hop information - only process if we have valid JSON
    if [[ -n "$trace_json" ]] && echo "$trace_json" | jq -e '.hops[] | select(.probes[0].ip != null)' >/dev/null 2>&1; then
        local hop_path=""
        local successful_hops=0

        # Process each hop from the JSON data
        while IFS= read -r line; do
            local hop_num hostname ip has_probes
            read -r hop_num hostname ip has_probes <<< "$line"

            if [[ "$has_probes" == "true" && "$ip" != "null" ]]; then
                [[ -n "$hop_path" ]] && hop_path+=" -> "
                if [[ "$hostname" != "$ip" && -n "$hostname" && "$hostname" != "null" ]]; then
                    hop_path+="$hostname"
                else
                    hop_path+="$ip"
                fi
                ((successful_hops++))
            fi
        done < <(echo "$trace_json" | jq -r '.hops[] | "\(.hop) \(.probes[0].name // "_gateway") \(.probes[0].ip // "null") \(if .probes[0].ip then "true" else "false" end)"')

        # Add destination if not in the path
        local destination
        destination=$(echo "$trace_json" | jq -r '.destination_name')
        if [[ -n "$destination" && "$destination" != "null" && ! "$hop_path" =~ $destination$ ]]; then
            hop_path+=" -> $destination"
        fi

        # Only print if we have a valid path with more than just the first hop
        if [[ -n "$hop_path" && "$successful_hops" -gt 1 ]]; then
            log_info "Trace path: ${hop_path}"
            log_info "Successful hops: ${successful_hops}"
        else
            log_warn "No valid trace path found - insufficient successful hops"
        fi
    else
        log_warn "No valid traceroute data received"
    fi

    # Return the JSON data
    echo "$trace_json"
}


##### collect_initial_state
# Collects initial network state information
#
# Environment Variables:
#   NETWORK_INITIAL_ROUTING_JSON: Stores the collected network state
#
# Returns:
#   0: Success
#   1: Collection failed
collect_initial_state() {
    log_info "Collecting initial network state..."

    # Capture both the output and the return status
    NETWORK_INITIAL_ROUTING_JSON=$(collect_network_state) || return $?

    return 0
}

##### start_tailscale_daemon
# Starts the Tailscale daemon with proper configuration
#
# Environment Variables:
#   TAILSCALE_STATE_DIR: Directory for Tailscale state
#   TAILSCALE_DAEMON_LOG: Log file location
#
# Returns:
#   0: Success
#   1: Failed to start daemon
start_tailscale_daemon() {
    log_info "Checking Tailscale daemon status..."

    if pidof tailscaled >/dev/null; then
        log_info "Stopping existing Tailscale daemon..."
        pkill tailscaled || true
        sleep 2
    fi

    log_info "Starting Tailscale daemon..."
    # Redirect verbose output to log file
    tailscaled --verbose=1 --statedir="${TAILSCALE_STATE_DIR}" > "${TAILSCALE_DAEMON_LOG}" 2>&1 &

    local retries=5
    while ((retries > 0)); do
        if pidof tailscaled >/dev/null; then
            log_info "Daemon started successfully"
            return 0
        fi
        retries=$((retries - 1))
        sleep 1
    done

    log_error "Failed to start Tailscale daemon"
    return 1
}

##### stop_tailscale_daemon
# Stops the Tailscale daemon if running
#
# Returns:
#   0: Always returns success
stop_tailscale_daemon() {
    log_info "Checking Tailscale daemon status..."
    if pidof tailscaled >/dev/null; then
        log_info "Stopping existing Tailscale daemon..."
        pkill tailscaled || true
        sleep 2
    fi
    return 0
}

##### establish_tailscale_connection
# Establishes connection to Tailscale network
#
# Arguments:
#   $1 - hostname (string): Desired hostname for the connection
#
# Returns:
#   0: Success
#   1: Connection failed
establish_tailscale_connection() {
    local hostname="${1:-}"

    # Validate input
    if [[ -z "$hostname" ]]; then
        log_error "hostname parameter is required"
        return 1
    fi

    local max_retries=3
    local retry_count=0
    local connected=false

    log_info "Connecting to Tailscale network as '${hostname}'..."

    # Check existing connections and clean up if needed
    if tailscale status >/dev/null 2>&1; then
        log_info "Found existing Tailscale connection, logging out..."
        tailscale logout
        sleep 2
    fi

    # Attempt connection with retries
    while ((retry_count < max_retries)) && [[ "$connected" != "true" ]]; do
        retry_count=$((retry_count + 1))

        # Force the hostname we want
        if ! tailscale up --reset --force-reauth --hostname="$hostname"; then
            log_error "Connection attempt ${retry_count} failed"
            sleep 2
            continue
        fi

        # Wait for connection to stabilize
        sleep 3

        # Verify connection and hostname
        local status_json
        if ! status_json=$(tailscale status --json); then
            log_error "Failed to get Tailscale status"
            continue
        fi

        # Check if we're actually connected
        if ! echo "$status_json" | jq -e '.BackendState == "Running"' >/dev/null; then
            log_error "Tailscale backend is not running"
            continue
        fi

        # Verify hostname
        local assigned_hostname
        assigned_hostname=$(echo "$status_json" | jq -r '.Self.HostName')
        if [[ "$assigned_hostname" != "$hostname" ]]; then
            log_error "Got unexpected hostname: ${assigned_hostname} (wanted: ${hostname})"
            continue
        fi

        # Get our assigned IP
        local ip
        ip=$(echo "$status_json" | jq -r '.Self.TailscaleIPs[0]')
        if [[ -z "$ip" || "$ip" == "null" ]]; then
            log_error "No Tailscale IP assigned"
            continue
        fi

        log_info "Connected successfully as '${hostname}' with IP: ${ip}"
        connected=true
    done

    if [[ "$connected" != "true" ]]; then
        log_error "Failed to establish connection after ${max_retries} attempts"
        return 1
    fi

    return 0
}

# Export required functions
export -f verify_network_state check_basic_connectivity
export -f verify_tun_device
export -f collect_network_state
export -f trace_route collect_initial_state start_tailscale_daemon stop_tailscale_daemon establish_tailscale_connection
