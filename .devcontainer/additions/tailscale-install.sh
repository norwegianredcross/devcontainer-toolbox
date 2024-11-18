#!/bin/bash
# File: .devcontainer/additions/tailscale-install.sh
#
# Purpose: Installs Tailscale and sets up required directories in a devcontainer
# Usage: sudo .devcontainer/additions/tailscale-install.sh
#
# Author: Terje Christensen
# Created: November 2024

set -euo pipefail

# Source all library files
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
readonly SCRIPT_DIR
readonly LIB_DIR="${SCRIPT_DIR}/tailscale"

# List of required library files
readonly REQUIRED_LIBS=(
    "common"     # Common utilities and logging
    "network"    # Network testing and verification
    "config"     # Configuration management
    "status"     # Status tracking and progress display
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

# Check if Tailscale is already installed
check_existing_installation() {
    if command -v tailscale >/dev/null; then
        local version
        version=$(tailscale version 2>/dev/null | head -n1 | cut -d' ' -f1 || echo "unknown")
        log_info "Tailscale is already installed (version: ${version})"
        return 0
    fi
    return 1
}

# Install Tailscale
install_tailscale() {
    log_info "Installing Tailscale..."

    # Install Tailscale
    curl -fsSL https://tailscale.com/install.sh | sh

    # Verify installation
    if ! command -v tailscale >/dev/null; then
        log_error "Tailscale installation failed"
        return 1
    fi

    log_info "Tailscale installed successfully"

    return "$EXIT_SUCCESS"
}

# Verify Tailscale installation
verify_installation() {
    log_info "Verifying Tailscale installation..."

    # Check if tailscale binary exists and is executable
    if ! command -v tailscale >/dev/null; then
        log_error "Tailscale binary not found"
        return "$EXIT_ENV_ERROR"
    fi

    # Check version
    local version
    if ! version=$(tailscale version); then
        log_error "Failed to get Tailscale version"
        return "$EXIT_ENV_ERROR"
    fi
    log_info "Installed Tailscale version: $version"

    return "$EXIT_SUCCESS"
}

# Main installation process
main() {
    log_info "Starting Tailscale installation..."

    # Check root access immediately
    if ! check_root; then
        return "$EXIT_ENV_ERROR"
    fi

    # Check if already installed first
    if check_existing_installation; then
        log_info "No installation needed"
        log_info "To start using Tailscale, please run:"
        log_info "    sudo .devcontainer/additions/tailscale-start2.sh"
        return "$EXIT_SUCCESS"
    fi

    # Load environment first
    if ! load_environment; then
        log_error "Failed to load environment configuration"
        return "$EXIT_ENV_ERROR"
    fi

    # Phase 1: Environment preparation
    if ! prepare_environment "skip-tailscale"; then
        log_error "Failed to prepare environment"
        return "$EXIT_ENV_ERROR"
    fi

    log_info "Environment preparation completed successfully"

    # Check capabilities
    if ! check_capabilities; then
        log_error "Missing required capabilities"
        return "$EXIT_ENV_ERROR"
    fi

    # Verify networking requirements
    if ! verify_tun_device; then
        log_error "Network verification failed"
        return "$EXIT_NETWORK_ERROR"
    fi

    # Create required directories
    if ! create_directory "$TAILSCALE_BASE_DIR" "$TAILSCALE_DIR_MODE"; then
        log_error "Failed to create required directories"
        return "$EXIT_ENV_ERROR"
    fi

    # Install Tailscale
    if ! install_tailscale; then
        log_error "Tailscale installation failed"
        return "$EXIT_ENV_ERROR"
    fi

    # Verify installation
    if ! verify_installation; then
        log_error "Installation verification failed"
        return "$EXIT_ENV_ERROR"
    fi

    log_info "Installation completed successfully"
    return "$EXIT_SUCCESS"
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
