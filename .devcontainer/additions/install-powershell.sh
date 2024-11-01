#!/bin/bash
# file: .devcontainer/additions/install-powershell.sh
#
# Usage: ./install-powershell.sh [options]
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
SCRIPT_NAME="PowerShell Development Tools"
SCRIPT_DESCRIPTION="Installs PowerShell modules and extensions for Azure and Microsoft Graph development"

# Before running installation, we need to add any required repositories
pre_installation_setup() {
    if [ "${UNINSTALL_MODE}" -eq 1 ]; then
        echo "🔧 Preparing for uninstallation..."
    else
        echo "🔧 Performing pre-installation setup..."
        
        # Verify PowerShell is installed (should be from Dockerfile)
        if ! command -v pwsh >/dev/null 2>&1; then
            echo "⚠️  Warning: PowerShell not found. It should have been installed in the Dockerfile."
            echo "Please verify the container was built correctly."
            exit 1
        fi
        
        # Check PowerShell version and configuration
        echo "PowerShell configuration:"
        pwsh -Version
        
        # Ensure PSGallery is available
        if ! pwsh -NoProfile -NonInteractive -Command "Get-PSRepository -Name PSGallery" >/dev/null 2>&1; then
            echo "⚠️  Warning: PSGallery not accessible. Checking network connectivity..."
            exit 1
        fi
    fi
}

# Define PowerShell modules
PWSH_MODULES=(
    "Az"
    "Microsoft.Graph"
    "PSScriptAnalyzer"
)

# Define VS Code extensions
declare -A EXTENSIONS
EXTENSIONS["ms-vscode.powershell"]="PowerShell|PowerShell language support and debugging"
EXTENSIONS["ms-vscode.azure-account"]="Azure Account|Azure account management and subscriptions"
EXTENSIONS["ms-azuretools.vscode-azureresourcegroups"]="Azure Resources|An extension for viewing and managing Azure resources"

# Define verification commands
VERIFY_COMMANDS=(
    "command -v pwsh >/dev/null && pwsh -Version || echo '❌ PowerShell not found'"
    "pwsh -NoProfile -NonInteractive -Command \"Get-Module -ListAvailable Az* | Select-Object Name, Version\" || echo '❌ Az module not found'"
    "pwsh -NoProfile -NonInteractive -Command \"Get-Module -ListAvailable Microsoft.Graph | Select-Object Name, Version\" || echo '❌ Microsoft.Graph module not found'"
    "pwsh -NoProfile -NonInteractive -Command \"Get-Module -ListAvailable PSScriptAnalyzer | Select-Object Name, Version\" || echo '❌ PSScriptAnalyzer not found'"
    "code --list-extensions | grep -q ms-vscode.powershell && echo '✅ PowerShell extension is installed' || echo '❌ PowerShell extension is not installed'"
)

# Post-installation notes
post_installation_message() {
    local pwsh_version
    
    if command -v pwsh >/dev/null 2>&1; then
        pwsh_version=$(pwsh -Version)
    else
        pwsh_version="not installed"
    fi

    echo
    echo "🎉 Installation process complete for: $SCRIPT_NAME!"
    echo "Purpose: $SCRIPT_DESCRIPTION"
    echo
    echo "Important Notes:"
    echo "1. PowerShell $pwsh_version"
    echo "2. PowerShell modules installed for current user"
    echo "3. Use 'Connect-AzAccount' to authenticate with Azure"
    echo "4. Use 'Connect-MgGraph' to authenticate with Microsoft Graph"
    echo "5. PSScriptAnalyzer is configured for code analysis"
    echo
    echo "Quick Start Commands:"
    echo "- Connect to Azure: Connect-AzAccount"
    echo "- Connect to Microsoft Graph: Connect-MgGraph"
    echo "- Check module versions: Get-Module -ListAvailable"
    echo "- Run code analysis: Invoke-ScriptAnalyzer <script-path>"
    echo
    echo "Documentation Links:"
    echo "- Local Guide: .devcontainer/howto/howto-powershell.md"
    echo "- Az PowerShell: https://learn.microsoft.com/powershell/azure"
    echo "- Microsoft Graph: https://learn.microsoft.com/powershell/microsoftgraph"
    echo "- PSScriptAnalyzer: https://learn.microsoft.com/powershell/utility-modules/psscriptanalyzer"
    
    # Show current PowerShell version and module versions
    echo
    echo "Installation Status:"
    pwsh -NoProfile -NonInteractive -Command "
Write-Host \"PowerShell Version: \$(\$PSVersionTable.PSVersion)\"
Write-Host \"\nInstalled Modules:\"
Get-Module -ListAvailable Az*, Microsoft.Graph, PSScriptAnalyzer | 
    Sort-Object Name | 
    Format-Table Name, Version, Author -AutoSize"
}

# Post-uninstallation notes
post_uninstallation_message() {
    echo
    echo "🏁 Uninstallation process complete for: $SCRIPT_NAME!"
    echo
    echo "Additional Notes:"
    echo "1. PowerShell profile and configuration files remain unchanged"
    echo "2. Module configurations may remain in ~/.local/share/powershell"
    echo "3. VS Code settings for PowerShell extension remain unchanged"
    echo "4. See the local guide for additional cleanup steps:"
    echo "   .devcontainer/howto/howto-powershell.md"
    
    # Check for remaining components
    echo
    echo "Checking for remaining components..."
    
    if pwsh -NoProfile -NonInteractive -Command "Get-Module -ListAvailable Az*, Microsoft.Graph, PSScriptAnalyzer" 2>/dev/null; then
        echo
        echo "⚠️  Warning: Some PowerShell modules may still be installed"
        echo "To completely remove them, start PowerShell and run:"
        echo "  Uninstall-Module -Name Az -AllVersions -Force"
        echo "  Uninstall-Module -Name Microsoft.Graph -AllVersions -Force"
        echo "  Uninstall-Module -Name PSScriptAnalyzer -AllVersions -Force"
    fi
    
    # Check for remaining VS Code extensions
    if code --list-extensions | grep -q "ms-vscode.powershell"; then
        echo
        echo "⚠️  Note: PowerShell VS Code extension is still installed"
        echo "To remove it, run: code --uninstall-extension ms-vscode.powershell"
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

    if [ ${#PYTHON_PACKAGES[@]} -gt 0 ]; then
        process_python_packages "PYTHON_PACKAGES"
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
    pre_installation_setup
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