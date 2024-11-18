#!/bin/bash
# File: setup/uninstall-mac.sh
# Purpose: Clean up DevContainer Toolbox development container and related resources
# Platform: macOS
# Usage: ./uninstall-mac.sh
# Last Updated: 2024-10-28

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Container identifier
CONTAINER_NAME="devcontainer-toolbox"
WORKSPACE_PATH=$(pwd)

# Logging function
log_message() {
    local timestamp=$(date '+%H:%M:%S')
    echo -e "[$timestamp] ${1}${2}${NC}"
}

# Function to check if a command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        log_message ${RED} "Missing required command: $1"
        exit 1
    fi
}

# Check for required commands
check_command "podman"

# Main cleanup process
main() {
    log_message ${BLUE} "Starting cleanup process for DevContainer Toolbox container..."

    # Stop and remove the specific dev container
    log_message ${YELLOW} "Looking for DevContainer Toolbox container..."
    local container_ids=$(podman ps -a --filter "label=devcontainer.local_folder=${WORKSPACE_PATH}" --quiet)

    if [ -n "$container_ids" ]; then
        log_message ${YELLOW} "Stopping and removing DevContainer Toolbox container..."
        podman stop $container_ids 2>/dev/null || true
        podman rm -f $container_ids 2>/dev/null || true
        log_message ${GREEN} "Container removed successfully."
    else
        log_message ${BLUE} "No DevContainer Toolbox container found running."
    fi

    # Remove the specific dev container image
    log_message ${YELLOW} "Removing DevContainer Toolbox container image..."
    local image_ids=$(podman images "vsc-devcontainer-toolbox*" -q)
    if [ -n "$image_ids" ]; then
        podman image rm -f $image_ids 2>/dev/null || true
        log_message ${GREEN} "Container image removed successfully."
    else
        log_message ${BLUE} "No DevContainer Toolbox image found."
    fi

    # Clean up VS Code dev containers cache for this specific container
    local cache_path="$HOME/Library/Application Support/Code/User/globalStorage/ms-vscode-remote.remote-containers/data/${WORKSPACE_PATH//\//-}"
    if [ -d "$cache_path" ]; then
        log_message ${YELLOW} "Cleaning VS Code cache for DevContainer Toolbox..."
        rm -rf "$cache_path" 2>/dev/null || true
        log_message ${GREEN} "Cache cleaned successfully."
    fi

    # Remove temporary files if they exist
    local temp_dir="/tmp/devcontainers-*"
    if ls $temp_dir 1> /dev/null 2>&1; then
        log_message ${YELLOW} "Cleaning temporary files..."
        rm -rf $temp_dir 2>/dev/null || true
        log_message ${GREEN} "Temporary files cleaned successfully."
    fi

    # Success message
    log_message ${GREEN} "Cleanup completed successfully!"
    log_message ${BLUE} "To restart the development container:"
    log_message ${NC} "1. Ensure Podman is running: 'podman machine start'"
    log_message ${NC} "2. Open VS Code"
    log_message ${NC} "3. Use 'Rebuild Container' command"
}

# Confirmation prompt
log_message ${YELLOW} "⚠️  This will remove the DevContainer Toolbox container and its related resources."
log_message ${YELLOW} "Other containers and images will not be affected."
log_message ${YELLOW} "Continue? (y/N)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    log_message ${BLUE} "Operation cancelled."
    exit 0
fi

# Run main cleanup with error handling
if ! main; then
    log_message ${RED} "Error during cleanup process!"
    exit 1
fi
