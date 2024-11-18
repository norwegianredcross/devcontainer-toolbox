#!/bin/bash
# file: .devcontainer/additions/install-conf-script.sh
#
# Usage: ./install-conf-script.sh [options]
# 
# Options:
#   --debug     : Enable debug output for troubleshooting
#   --uninstall : Remove installed components instead of installing them
#   --force     : Force installation/uninstallation even if there are dependencies
#
#------------------------------------------------------------------------------
# CONFIGURATION - Modify this section for each new script
#------------------------------------------------------------------------------

# Script metadata - must be at the very top of the configuration section
SCRIPT_NAME="Configuration Tools"
SCRIPT_DESCRIPTION="Installs tools and extensions for Infrastructure as Code (Bicep) and configuration management (Ansible)"

# Before running installation, we need to add any required repositories
pre_installation_setup() {
    if [ "${UNINSTALL_MODE}" -eq 1 ]; then
        echo "🔧 Preparing for uninstallation..."
    else
        echo "🔧 Performing pre-installation setup..."
        echo "No additional setup required for this script"
    fi
}

# Define system packages
SYSTEM_PACKAGES=(
    "ansible"
    "ansible-lint"
)

# Define Python packages for pip installation
PYTHON_PACKAGES=()

# Define VS Code extensions
declare -A EXTENSIONS
EXTENSIONS["ms-azuretools.vscode-bicep"]="Bicep|Azure Bicep language support for IaC"
EXTENSIONS["redhat.ansible"]="Ansible|Ansible language support and tools"

# Define verification commands to run after installation
VERIFY_COMMANDS=(
    "command -v ansible >/dev/null && ansible --version | head -n1 || echo '❌ ansible not found'"
    "command -v ansible-lint >/dev/null && ansible-lint --version || echo '❌ ansible-lint not found'"
    "code --list-extensions | grep -q ms-azuretools.vscode-bicep && echo '✅ Bicep extension is installed' || echo '❌ Bicep extension is not installed'"
    "code --list-extensions | grep -q redhat.ansible && echo '✅ Ansible extension is installed' || echo '❌ Ansible extension is not installed'"
)

# Post-installation notes
post_installation_message() {
    local ansible_version
    local lint_version
    
    if command -v ansible >/dev/null 2>&1; then
        ansible_version=$(ansible --version | head -n1)
    else
        ansible_version="not installed"
    fi

    if command -v ansible-lint >/dev/null 2>&1; then
        lint_version=$(ansible-lint --version 2>/dev/null)
    else
        lint_version="not installed"
    fi

    echo
    echo "🎉 Installation process complete for: $SCRIPT_NAME!"
    echo "Purpose: $SCRIPT_DESCRIPTION"
    echo
    echo "Important Notes:"
    echo "1. Bicep CLI is installed and configured with the extension"
    echo "2. Ansible $ansible_version"
    echo "3. ansible-lint $lint_version"
    echo
    echo "Documentation Links:"
    echo "- Local Guide: .devcontainer/howto/howto-conf-script.md"
    echo "- Bicep: https://docs.microsoft.com/azure/azure-resource-manager/bicep"
    echo "- Ansible: https://docs.ansible.com"
    echo "- VS Code Bicep Extension: https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep"
    echo "- VS Code Ansible Extension: https://marketplace.visualstudio.com/items?itemName=redhat.ansible"
}

# Post-uninstallation notes
post_uninstallation_message() {
    echo
    echo "🏁 Uninstallation process complete for: $SCRIPT_NAME!"
    echo
    echo "Additional Notes:"
    echo "1. Configuration files (.bicep, .yaml, etc.) remain unchanged"
    echo "2. Any custom Ansible configurations in ~/.ansible remain in place"
    echo "3. See the local guide for additional cleanup steps if needed:"
    echo "   .devcontainer/howto/howto-conf-script.md"
    
    # Verify uninstallation
    if command -v ansible >/dev/null || command -v ansible-lint >/dev/null; then
        echo
        echo "⚠️  Warning: Some components may still be installed:"
        command -v ansible >/dev/null && echo "- ansible is still present"
        command -v ansible-lint >/dev/null && echo "- ansible-lint is still present"
        echo "You may need to run with sudo or check package manager settings."
    fi
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
    if [ ${#EXTENSIONS[@]} -gt 0 ]; then
        for ext_id in "${!EXTENSIONS[@]}"; do
            IFS='|' read -r name description _ <<< "${EXTENSIONS[$ext_id]}"
            check_extension_state "$ext_id" "uninstall" "$name"
        done
    fi
    post_uninstallation_message
else
    echo "🔄 Starting installation process for: $SCRIPT_NAME"
    echo "Purpose: $SCRIPT_DESCRIPTION"
    pre_installation_setup
    process_installations
    verify_installations
    if [ ${#EXTENSIONS[@]} -gt 0 ]; then
        for ext_id in "${!EXTENSIONS[@]}"; do
            IFS='|' read -r name description _ <<< "${EXTENSIONS[$ext_id]}"
            check_extension_state "$ext_id" "install" "$name"
        done
    fi
    post_installation_message
fi