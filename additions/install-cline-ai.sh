#!/bin/bash
# file: .devcontainer/additions/install-cline-ai.sh

# Initialize mode flags
DEBUG_MODE=0
UNINSTALL_MODE=0
FORCE_MODE=0

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            DEBUG_MODE=1
            shift
            ;;
        --uninstall)
            UNINSTALL_MODE=1
            shift
            ;;
        --force)
            FORCE_MODE=1
            shift
            ;;
        *)
            echo "ERROR: Unknown option: $1" >&2
            echo "Usage: $0 [--debug] [--uninstall] [--force]" >&2
            exit 1
            ;;
    esac
done

# Export mode flags for the core scripts
export DEBUG_MODE
export UNINSTALL_MODE
export FORCE_MODE

# Define Python packages array for potential AI-related packages
# Note: Currently empty as Cline doesn't require specific Python packages,
# but maintained for future expansion
PYTHON_PACKAGES=(
)

# Source the core installation scripts
source "$(dirname "$0")/core-install-python-packages.sh"
source "$(dirname "$0")/core-install-extensions.sh"

# Declare the VS Code extensions array
declare -A AI_EXTENSIONS
AI_EXTENSIONS["saoudrizwan.claude-dev"]="Cline|AI assistant for coding and documentation"


if [ "${UNINSTALL_MODE}" -eq 1 ]; then
    echo "🔄 Starting uninstallation process..."
    
    # First uninstall VS Code extensions
    process_extensions "AI_EXTENSIONS"
    
    # Then uninstall Python packages (if any in the future)
    if [ ${#PYTHON_PACKAGES[@]} -gt 0 ]; then
        process_packages "PYTHON_PACKAGES"
    fi
    
    echo "🏁 Uninstallation process complete!"
else
    echo "🔄 Starting installation process..."
    
    # First install Python packages (if any in the future)
    if [ ${#PYTHON_PACKAGES[@]} -gt 0 ]; then
        process_packages "PYTHON_PACKAGES"
    fi
    
    # Then install VS Code extensions
    process_extensions "AI_EXTENSIONS"
    
    # Post-installation message
    echo
    echo "🎉 Installation process complete!"
    echo
    echo "Important Notes:"
    echo "1. You will need to configure your API key from a supported provider (OpenRouter, Anthropic, etc.)"
    echo "2. For detailed setup instructions, visit: https://marketplace.visualstudio.com/items?itemName=saoudrizwan.claude-dev"
fi