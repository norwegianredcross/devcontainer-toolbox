#!/bin/bash
# file: .devcontainer/additions/install-conf-script.sh

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

# Define system packages array
SYSTEM_PACKAGES=(
    "ansible"
    "ansible-lint"
)

# Source the core installation scripts
source "$(dirname "$0")/core-install-apt.sh"
source "$(dirname "$0")/core-install-extensions.sh"

# Declare the VS Code extensions array
declare -A CONF_EXTENSIONS
CONF_EXTENSIONS["ms-azuretools.vscode-bicep"]="Bicep|Azure Bicep language support for IaC"
CONF_EXTENSIONS["redhat.ansible"]="Ansible|Ansible language support and tools"


if [ "${UNINSTALL_MODE}" -eq 1 ]; then
    echo "🔄 Starting uninstallation process..."
    
    # First uninstall VS Code extensions
    process_extensions "CONF_EXTENSIONS"
    
    # Then uninstall system packages
    process_packages "SYSTEM_PACKAGES"
    
    echo "🏁 Uninstallation process complete!"
else
    echo "🔄 Starting installation process..."
    
    # First install system packages
    process_packages "SYSTEM_PACKAGES"
    
    # Then install VS Code extensions
    process_extensions "CONF_EXTENSIONS"
    
    # Post-installation message
    echo
    echo "🎉 Installation process complete!"
    echo
    echo "Important Notes:"
    echo "1. Bicep CLI is required for full functionality of the Bicep extension"
    echo "   - It should be automatically installed with the extension"
    echo "2. Ansible $(ansible --version | head -n1) has been installed"
    echo
    echo "Documentation Links:"
    echo "- Bicep: https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep"
    echo "- Ansible: https://marketplace.visualstudio.com/items?itemName=redhat.ansible"
fi