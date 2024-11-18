#!/bin/bash
# File: setup/setup-mac.sh
# Purpose: Automated setup script for DevContainer Toolbox on macOS
# Requirements: macOS 10.15 or higher


# Exit on any error
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log_message() {
    local timestamp=$(date '+%H:%M:%S')
    echo -e "[$timestamp] ${1}${2}${NC}"
}

# Function to check if a command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        log_message ${RED} "Missing required software: $1"
        log_message ${YELLOW} "Please install using Homebrew:"
        log_message ${YELLOW} "brew install --cask $2"
        exit 1
    fi
}

# Main setup process
main() {
    log_message ${GREEN} "Starting DevContainer Toolbox setup..."

    # Check for required software
    log_message ${BLUE} "Checking prerequisites..."
    check_command "code" "visual-studio-code"
    check_command "podman" "podman-desktop"

    # Initialize Podman
    log_message ${BLUE} "Initializing Podman..."
    podman machine init
    podman machine start

    # Clone repository
    log_message ${BLUE} "Cloning repository..."
    REPO_URL="https://github.com/your-org/operation-toolbox.git"
    REPO_PATH="$HOME/operation-toolbox"

    # Backup existing repository if it exists
    if [ -d "$REPO_PATH" ]; then
        log_message ${YELLOW} "Repository directory already exists. Backing up..."
        mv "$REPO_PATH" "$REPO_PATH.backup"
    fi

    git clone "$REPO_URL" "$REPO_PATH"

    # Configure VS Code
    log_message ${BLUE} "Configuring VS Code..."
    code --install-extension ms-vscode-remote.remote-containers

    # Create VS Code settings directory if it doesn't exist
    VSCODE_SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
    mkdir -p "$VSCODE_SETTINGS_DIR"

    # Configure VS Code settings
    VSCODE_SETTINGS="$VSCODE_SETTINGS_DIR/settings.json"
    echo '{
        "dev.containers.dockerPath": "podman",
        "terminal.integrated.defaultProfile.osx": "bash"
    }' > "$VSCODE_SETTINGS"

    # Open project in VS Code
    log_message ${BLUE} "Opening project in VS Code..."
    code "$REPO_PATH"

    # Success message and next steps
    log_message ${GREEN} "Setup completed successfully!"
    log_message ${GREEN} "Next steps:"
    log_message ${NC} "1. Wait for VS Code to open"
    log_message ${NC} "2. Click 'Reopen in Container' when prompted"
    log_message ${NC} "3. Sign in to Azure when the container is ready"
}

# Catch errors and provide helpful message
trap 'log_message ${RED} "Error: Setup failed! Please check the error message above or contact support."' ERR

# Run main setup
main