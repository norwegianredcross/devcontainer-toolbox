#!/bin/bash
# File: .devcontainer/additions/tailscale-lib-report.sh
#
# Purpose:
#   Handles all reporting and display functions for Tailscale status,
#   configuration, and network state.
#
# Dependencies:
#   - tailscale-lib-common.sh : Common utilities and logging
#   - tailscale-lib-status.sh : Status management
#   - tailscale-lib-network.sh : Network information
#   - jq : JSON processing
#
# Author: Terje Christensen
# Created: November 2024
#

# Ensure script is being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This script should be sourced, not executed directly"
    exit 1
fi

# Display setup progress
display_setup_progress() {
    local phase="$1"
    local status="$2"
    local progress="$3"
    local total="${4:-100}"

    # Calculate percentage
    local percentage=$((progress * 100 / total))

    # Create progress bar
    local width=50
    local completed=$((width * progress / total))
    local remaining=$((width - completed))

    local progress_bar="["
    for ((i=0; i<completed; i++)); do progress_bar+="="; done
    if ((completed < width)); then progress_bar+=">"; fi
    for ((i=0; i<remaining-1; i++)); do progress_bar+=" "; done
    progress_bar+="]"

    log_info "Phase: $phase"
    log_info "Status: $status"
    log_info "$progress_bar $percentage%"
    log_info ""
}


##### display_completion_summary
# Displays a summary of the Tailscale setup completion including duration,
# container configuration, and exit node details.
#
# Arguments:
#   $1 - start_time (int): Setup start time in Unix epoch
#   $2 - end_time (int): Setup end time in Unix epoch
#
# Environment Variables:
#   TAILSCALE_CONF_JSON: Global configuration JSON
#
# Returns:
#   0: Success
#   1: If TAILSCALE_CONF_JSON is not available
display_completion_summary() {
   local start_time="$1"
   local end_time="$2"

   # Verify we have configuration
   if [[ -z "$TAILSCALE_CONF_JSON" ]]; then
       log_error "No configuration available for summary display"
       return 1
   fi

   # Calculate duration
   local duration=$((end_time - start_time))
   local minutes=$((duration / 60))
   local seconds=$((duration % 60))

   log_info "===================================="
   log_info "Tailscale Setup Complete"
   log_info "===================================="
   log_info ""
   log_info "Setup Duration: ${minutes}m ${seconds}s"
   log_info ""

   # Show key information
   log_info "Container Configuration:"
   log_info "- Hostname: $(echo "$TAILSCALE_CONF_JSON" | jq -r '.Self.HostName')"
   log_info "- IP: $(echo "$TAILSCALE_CONF_JSON" | jq -r '.Self.TailscaleIPs[0]')"
   log_info "- Network: $(echo "$TAILSCALE_CONF_JSON" | jq -r '.CurrentTailnet.Name')"
   log_info ""

   if [[ "$(echo "$TAILSCALE_CONF_JSON" | jq -r '.exitNode != null')" == "true" ]]; then
       log_info "Exit Node:"
       log_info "- Host: $(echo "$TAILSCALE_CONF_JSON" | jq -r '.exitNode.HostName')"
       log_info "- IP: $(echo "$TAILSCALE_CONF_JSON" | jq -r '.exitNode.TailscaleIPs[0]')"
       local connection
       connection=$(echo "$TAILSCALE_CONF_JSON" | jq -r '.network.tailscale.traceroute.hops[0].probes[0].name')
       log_info "- Connection: ${connection:-relay}"
   fi

   log_info "===================================="

   return 0
}
# Export required functions
export -f display_setup_progress display_completion_summary

