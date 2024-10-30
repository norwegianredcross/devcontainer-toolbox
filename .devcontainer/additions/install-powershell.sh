#!/bin/bash
# file: .devcontainer/additions/install-powershell.sh
# Description: This script installs or uninstalls PowerShell modules for Azure and Microsoft Graph development
#
# Usage:
#   ./install-powershell.sh              # Interactive installation with confirmation
#   ./install-powershell.sh -y           # Automatic installation without confirmation
#   ./install-powershell.sh --uninstall  # Interactive uninstallation with confirmation
#   ./install-powershell.sh -y --uninstall # Automatic uninstallation without confirmation
#
# Components managed:
# 1. PowerShell Modules:
#    a. Az PowerShell Module
#       - Official Azure PowerShell module for managing Azure resources
#       - Includes cmdlets for creating, updating, and managing Azure services
#       - Documentation: https://learn.microsoft.com/powershell/azure
#
#    b. Microsoft.Graph PowerShell Module
#       - Official Microsoft Graph PowerShell SDK
#       - Provides cmdlets for interacting with Microsoft 365 services
#       - Documentation: https://learn.microsoft.com/powershell/microsoftgraph
#
#    c. PSScriptAnalyzer
#       - Static code analysis tool for PowerShell scripts and modules
#       - Documentation: https://learn.microsoft.com/powershell/utility-modules/psscriptanalyzer
#
# 2. VS Code Extensions:
#    a. PowerShell (ms-vscode.powershell)
#       - PowerShell language support and debugging
#       - Syntax highlighting, IntelliSense, and debugging capabilities
#
#    b. Azure Account (ms-vscode.azure-account)
#       - Azure account management and subscriptions
#       - Common Azure authentication provider
#
#    c. Azure CLI Tools (ms-vscode.azurecli)
#       - Azure CLI integration and snippets
#       - Command completion and syntax highlighting for Azure CLI

# Source the extension management script
source "$(dirname "$0")/install-extensions.sh"

# Define extensions array with all details
declare -A EXTENSIONS
# Format: [extension_id]="name|description|download_url|additional_headers"
EXTENSIONS=(
    ["ms-vscode.powershell"]="PowerShell|PowerShell language support and debugging|https://ms-vscode.gallery.vsassets.io/_apis/public/gallery/publisher/ms-vscode/extension/powershell/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage|"
    ["ms-vscode.azure-account"]="Azure Account|Azure account management and subscriptions|https://ms-vscode.gallery.vsassets.io/_apis/public/gallery/publisher/ms-vscode/extension/azure-account/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage|"
    ["ms-vscode.azurecli"]="Azure CLI Tools|Azure CLI integration and snippets|https://ms-vscode.gallery.vsassets.io/_apis/public/gallery/publisher/ms-vscode/extension/azurecli/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage|"
)

# Function to check if a PowerShell module is installed
check_module() {
    local module_name=$1
    pwsh -Command "
        if (Get-Module -ListAvailable -Name '$module_name' -ErrorAction SilentlyContinue) {
            exit 0
        } else {
            exit 1
        }
    "
    return $?
}

# Function to install PowerShell module
install_module() {
    local module_name=$1
    echo "Installing $module_name module..."
    pwsh -Command '
        try {
            Install-Module -Name '"'$module_name'"' -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
            Write-Host "'"'$module_name'"' installed successfully!"
            exit 0
        } catch {
            Write-Host ("Error: " + $_.Exception.Message)
            exit 1
        }
    '
    return $?
}

# Function to uninstall PowerShell module
uninstall_module() {
    local module_name=$1
    echo "Uninstalling $module_name module..."
    pwsh -Command '
        try {
            Remove-Module -Name '"'$module_name'"' -Force -ErrorAction SilentlyContinue
            Uninstall-Module -Name '"'$module_name'"' -AllVersions -Force -ErrorAction Stop
            Write-Host "'"'$module_name'"' uninstalled successfully!"
            exit 0
        } catch {
            Write-Host ("Error: " + $_.Exception.Message)
            exit 1
        }
    '
    return $?
}

# Main execution
display_header "PowerShell Tools Manager"

# Set PSGallery as trusted if installing
if [ "$UNINSTALL_MODE" = false ]; then
    echo "Setting PSGallery as trusted..."
    pwsh -Command "Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted"
fi

# Process PowerShell modules
MODULES=("Az" "Microsoft.Graph" "PSScriptAnalyzer")
MODULES_TO_PROCESS=()
FAILED_MODULES=()

# Get modules that need processing
for module in "${MODULES[@]}"; do
    if [ "$UNINSTALL_MODE" = true ]; then
        if check_module "$module"; then
            MODULES_TO_PROCESS+=("$module")
        fi
    else
        if ! check_module "$module"; then
            MODULES_TO_PROCESS+=("$module")
        fi
    fi
done

# Display module status
if [ ${#MODULES_TO_PROCESS[@]} -gt 0 ]; then
    if [ "$UNINSTALL_MODE" = true ]; then
        echo "The following PowerShell modules will be uninstalled:"
    else
        echo "The following PowerShell modules will be installed:"
    fi
    echo
    for module in "${MODULES_TO_PROCESS[@]}"; do
        echo "- $module"
    done
    echo
else
    if [ "$UNINSTALL_MODE" = true ]; then
        echo "No PowerShell modules were found to uninstall."
    else
        echo "All PowerShell modules are already installed."
    fi
    echo
fi

# Process VS Code extensions
EXTENSIONS_TO_PROCESS=()
get_extensions_to_process EXTENSIONS EXTENSIONS_TO_PROCESS

# Display what will be processed
if [ ${#MODULES_TO_PROCESS[@]} -eq 0 ] && ! display_extensions_status EXTENSIONS EXTENSIONS_TO_PROCESS; then
    exit 0
fi

# Get user confirmation
if ! get_user_confirmation; then
    exit 1
fi

# Process PowerShell modules
for module in "${MODULES_TO_PROCESS[@]}"; do
    if [ "$UNINSTALL_MODE" = true ]; then
        if ! uninstall_module "$module"; then
            FAILED_MODULES+=("$module")
        fi
    else
        if ! install_module "$module"; then
            FAILED_MODULES+=("$module")
        fi
    fi
done

# Process VS Code extensions
FAILED_EXTENSIONS=()
process_extensions EXTENSIONS EXTENSIONS_TO_PROCESS FAILED_EXTENSIONS

# Verify installations
echo "Verifying PowerShell modules..."
for module in "${MODULES[@]}"; do
    if check_module "$module"; then
        echo "✓ $module is installed"
    else
        echo "✗ $module is not installed"
    fi
done

echo
verify_installations EXTENSIONS

# Final status report
echo "----------------------------------------"
if [ ${#FAILED_MODULES[@]} -eq 0 ] && [ ${#FAILED_EXTENSIONS[@]} -eq 0 ]; then
    if [ "$UNINSTALL_MODE" = true ]; then
        echo "All components uninstalled successfully!"
    else
        echo "All components installed successfully!"
    fi
    exit 0
else
    if [ "$UNINSTALL_MODE" = true ]; then
        echo "Operation completed with some issues:"
    else
        echo "Operation completed with some issues:"
    fi
    if [ ${#FAILED_MODULES[@]} -gt 0 ]; then
        echo "Failed PowerShell modules:"
        for module in "${FAILED_MODULES[@]}"; do
            echo "- $module"
        done
    fi
    if [ ${#FAILED_EXTENSIONS[@]} -gt 0 ]; then
        echo "Failed VS Code extensions:"
        for ext_id in "${FAILED_EXTENSIONS[@]}"; do
            IFS='|' read -r name description url headers <<< "${EXTENSIONS[$ext_id]}"
            echo "- $name"
        done
    fi
    exit 1
fi