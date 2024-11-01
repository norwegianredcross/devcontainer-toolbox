#!/bin/bash
# file: .devcontainer/additions/install-cline-ai.sh
#
# Usage: ./install-cline-ai.sh [options]
# 
# Options:
#   --debug     : Enable debug output for troubleshooting
#   --uninstall : Remove installed components instead of installing them
#   --force     : Force installation/uninstallation even if there are dependencies
#
#------------------------------------------------------------------------------
# CONFIGURATION - Modify this section for each new script
#------------------------------------------------------------------------------

# Script metadata
SCRIPT_NAME="Cline AI Assistant"
SCRIPT_DESCRIPTION="Installs Cline (previously Claude Dev) extension for AI assistance in VS Code"

# Define VS Code extensions
declare -A EXTENSIONS
EXTENSIONS["saoudrizwan.claude-dev"]="Cline|AI assistant for coding and documentation"

# Define verification commands to run after installation
VERIFY_COMMANDS=(
    # The grep -q makes it silent but returns status
    "code --list-extensions | grep -q saoudrizwan.claude-dev && echo '✅ Extension is installed' || echo '❌ Extension is not installed'"
)

# Post-installation notes
post_installation_message() {
    echo
    echo "🎉 Installation process complete for: $SCRIPT_NAME!"
    echo "Purpose: $SCRIPT_DESCRIPTION"
    echo
    echo "Important Notes:"
    echo "1. You will need to configure your API key from a supported provider (OpenRouter, Anthropic, etc.)"
    echo "2. If you haven't already, authorize VS Code with your chosen provider"
    echo "3. You may need to reload VS Code for changes to take effect (Ctrl+Shift+P > 'Developer: Reload Window')"
    echo
    echo "Documentation Links:"
    echo "- Local Guide: .devcontainer/howto/howto-cline-ai.md"
    echo "- Cline Extension: https://marketplace.visualstudio.com/items?itemName=saoudrizwan.claude-dev"
    echo "- Cline Documentation: https://cline.ai/docs"
}

# Post-uninstallation notes
post_uninstallation_message() {
    echo
    echo "🏁 Uninstallation process complete for: $SCRIPT_NAME!"
    echo
    echo "If you still see the Cline icon in VS Code:"
    echo "1. Try reloading the VS Code window (Ctrl+Shift+P > 'Developer: Reload Window')"
    echo "2. If the icon persists, close VS Code completely and start it again"
    echo "3. See the local guide for additional troubleshooting steps:"
    echo "   .devcontainer/howto/howto-cline-ai.md"
}

#------------------------------------------------------------------------------
# STANDARD SCRIPT LOGIC - Do not modify anything below this line
#------------------------------------------------------------------------------

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
            echo "Description: $SCRIPT_DESCRIPTION"
            exit 1
            ;;
    esac
done

# Export mode flags for core scripts
export DEBUG_MODE
export UNINSTALL_MODE
export FORCE_MODE

# Source all core installation scripts
source "$(dirname "$0")/core-install-apt.sh"
source "$(dirname "$0")/core-install-node.sh"
source "$(dirname "$0")/core-install-extensions.sh"
source "$(dirname "$0")/core-install-pwsh.sh"
source "$(dirname "$0")/core-install-python-packages.sh"

# Function to process installations
process_installations() {
    # Process each type of package if array is not empty
    if [ ${#SYSTEM_PACKAGES[@]} -gt 0 ]; then
        process_system_packages "SYSTEM_PACKAGES"
    fi

    if [ ${#NODE_PACKAGES[@]} -gt 0 ]; then
        process_node_packages "NODE_PACKAGES"
    fi

    if [ ${#PWSH_MODULES[@]} -gt 0 ]; then
        process_pwsh_modules "PWSH_MODULES"
    fi

    if [ ${#EXTENSIONS[@]} -gt 0 ]; then
        process_extensions "EXTENSIONS"
    fi
}

# Function to verify installations
verify_installations() {
    if [ ${#VERIFY_COMMANDS[@]} -gt 0 ]; then
        echo
        echo "🔍 Verifying installations..."
        for cmd in "${VERIFY_COMMANDS[@]}"; do
            echo "Running: $cmd"
            if ! eval "$cmd"; then
                echo "❌ Verification failed for: $cmd"
            fi
        done
    fi
}

# Main execution
if [ "${UNINSTALL_MODE}" -eq 1 ]; then
    echo "🔄 Starting uninstallation process for: $SCRIPT_NAME"
    echo "Purpose: $SCRIPT_DESCRIPTION"
    process_installations
    check_extension_state "saoudrizwan.claude-dev" "uninstall" "Cline"
    post_uninstallation_message
else
    echo "🔄 Starting installation process for: $SCRIPT_NAME"
    echo "Purpose: $SCRIPT_DESCRIPTION"
    process_installations
    verify_installations
    check_extension_state "saoudrizwan.claude-dev" "install" "Cline"
    post_installation_message
fi