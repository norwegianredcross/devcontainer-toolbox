#!/bin/bash
# file: .devcontainer/additions/install-powershell.sh

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

# Define PowerShell modules array
PWSH_MODULES=(
    "Az"
    "Microsoft.Graph"
    "PSScriptAnalyzer"
)

# Source the core installation scripts
source "$(dirname "$0")/core-install-pwsh.sh"
source "$(dirname "$0")/core-install-extensions.sh"

# Declare the VS Code extensions array
declare -A PWSH_EXTENSIONS
PWSH_EXTENSIONS["ms-vscode.powershell"]="PowerShell|PowerShell language support and debugging"
PWSH_EXTENSIONS["ms-vscode.azure-account"]="Azure Account|Azure account management and subscriptions"


if [ "${UNINSTALL_MODE}" -eq 1 ]; then
    echo "🔄 Starting uninstallation process..."
    
    # First uninstall VS Code extensions
    process_extensions "PWSH_EXTENSIONS"
    
    # Then uninstall PowerShell modules
    process_modules "PWSH_MODULES"
    
    echo "🏁 Uninstallation process complete!"
else
    echo "🔄 Starting installation process..."
    
    # First install PowerShell modules
    process_modules "PWSH_MODULES"
    
    # Then install VS Code extensions
    process_extensions "PWSH_EXTENSIONS"
    
    # Post-installation message
    echo
    echo "🎉 Installation process complete!"
    echo
    echo "Important Notes:"
    echo "1. PowerShell modules installed for current user"
    echo "2. Use 'Connect-AzAccount' to authenticate with Azure"
    echo "3. Use 'Connect-MgGraph' to authenticate with Microsoft Graph"
    echo
    echo "Documentation Links:"
    echo "- Az PowerShell: https://learn.microsoft.com/powershell/azure"
    echo "- Microsoft Graph: https://learn.microsoft.com/powershell/microsoftgraph"
    echo "- PSScriptAnalyzer: https://learn.microsoft.com/powershell/utility-modules/psscriptanalyzer"
fi