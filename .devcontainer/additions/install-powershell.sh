#!/bin/bash
# file: .devcontainer/setup/install-powershell.sh
# Description: This script installs or uninstalls PowerShell modules for Azure and Microsoft Graph development
#
# Usage:
#   ./install-powershell.sh              # Interactive installation with confirmation
#   ./install-powershell.sh -y           # Automatic installation without confirmation
#   ./install-powershell.sh --uninstall  # Interactive uninstallation with confirmation
#   ./install-powershell.sh -y --uninstall # Automatic uninstallation without confirmation
#
# Components managed:
# 1. Az PowerShell Module
#    - Official Azure PowerShell module for managing Azure resources
#    - Includes cmdlets for creating, updating, and managing Azure services
#    - Documentation: https://learn.microsoft.com/powershell/azure
#
# 2. Microsoft.Graph PowerShell Module
#    - Official Microsoft Graph PowerShell SDK
#    - Provides cmdlets for interacting with Microsoft 365 services
#    - Documentation: https://learn.microsoft.com/powershell/microsoftgraph
#
# 3. PSScriptAnalyzer
#    - Static code analysis tool for PowerShell scripts and modules
#    - Documentation: https://learn.microsoft.com/powershell/utility-modules/psscriptanalyzer

# Set error handling
set -e

# Parse command line arguments
AUTO_MODE=false
UNINSTALL_MODE=false

for arg in "$@"; do
    case $arg in
        -y)
            AUTO_MODE=true
            ;;
        --uninstall)
            UNINSTALL_MODE=true
            ;;
    esac
done

# Always display the header first
echo "=== PowerShell Module Manager ==="
if [ "$UNINSTALL_MODE" = true ]; then
    echo "Operation: Uninstall PowerShell modules"
else
    echo "Operation: Install PowerShell modules and extensions"
fi
echo "==============================="
echo

# Function to check if a module is installed
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

# Check what modules need to be processed and show status
MODULES_TO_PROCESS=()
for module in "Az" "Microsoft.Graph" "PSScriptAnalyzer"; do
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

# If nothing to process, exit with status
if [ ${#MODULES_TO_PROCESS[@]} -eq 0 ]; then
    if [ "$UNINSTALL_MODE" = true ]; then
        echo "Status: No PowerShell modules were found to uninstall."
        echo "The following modules are not installed:"
        for module in "Az" "Microsoft.Graph" "PSScriptAnalyzer"; do
            if ! check_module "$module"; then
                echo "- $module"
            fi
        done
    else
        echo "Status: All PowerShell modules are already installed."
        echo "The following modules are present:"
        for module in "Az" "Microsoft.Graph" "PSScriptAnalyzer"; do
            if check_module "$module"; then
                echo "- $module"
            fi
        done
    fi
    exit 0
fi

# Show what will be processed
if [ "$UNINSTALL_MODE" = true ]; then
    echo "The following components will be uninstalled:"
    echo
    if [ ${#MODULES_TO_PROCESS[@]} -gt 0 ]; then
        echo "PowerShell Modules:"
        for module in "${MODULES_TO_PROCESS[@]}"; do
            case $module in
                "Az")
                    echo "- Az (Azure PowerShell module for managing Azure resources)"
                    ;;
                "Microsoft.Graph")
                    echo "- Microsoft.Graph (Microsoft Graph SDK for Microsoft 365 services)"
                    ;;
                "PSScriptAnalyzer")
                    echo "- PSScriptAnalyzer (PowerShell code analysis and best practices tool)"
                    ;;
            esac
        done
        echo
    fi

    # Only show extensions that we added (not in devcontainer.json)
    if command -v code > /dev/null; then
        echo "VS Code Extensions:"
        echo "- Azure Resources (ms-azuretools.vscode-azureresourcegroups)"
        echo "- Microsoft Graph Toolkit (ms-graph.microsoft-graph-toolkit)"
        echo
        echo "Note: Extensions managed by devcontainer.json will not be uninstalled:"
        echo "- PowerShell (ms-vscode.powershell)"
        echo "- Azure Account (ms-vscode.azure-account)"
        echo "- Azure CLI Tools (ms-vscode.azurecli)"
    fi
else
    echo "The following components will be installed:"
    echo
    echo "PowerShell Modules:"
    echo "- Az (Azure PowerShell module for managing Azure resources)"
    echo "- Microsoft.Graph (Microsoft Graph SDK for Microsoft 365 services)"
    echo "- PSScriptAnalyzer (PowerShell code analysis and best practices tool)"
    echo
    echo "VS Code Extensions:"
    echo "- Azure Resources (ms-azuretools.vscode-azureresourcegroups)"
    echo "  Azure resource management and visualization"
    echo "- Microsoft Graph Toolkit (ms-graph.microsoft-graph-toolkit)"
    echo "  Microsoft Graph development tools and explorer"
    echo
    echo "Note: Some VS Code extensions are already configured in devcontainer.json:"
    echo "- PowerShell (ms-vscode.powershell)"
    echo "- Azure Account (ms-vscode.azure-account)"
    echo "- Azure CLI Tools (ms-vscode.azurecli)"
fi
echo

# Ask for confirmation if not auto mode
if [ "$AUTO_MODE" = false ]; then
    if [ "$UNINSTALL_MODE" = true ]; then
        read -p "Do you want to proceed with the uninstallation? (y/N) " -n 1 -r
    else
        read -p "Do you want to proceed with the installation? (y/N) " -n 1 -r
    fi
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 1
    fi
fi

# Set PSGallery as trusted if installing
if [ "$UNINSTALL_MODE" = false ]; then
    echo "Setting PSGallery as trusted..."
    pwsh -Command "Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted"
fi

# Function to process module uninstallation
process_module_uninstall() {
    local module_name=$1
    echo "Processing $module_name..."
    if check_module "$module_name"; then
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
        if [ $? -eq 0 ]; then
            echo "$module_name uninstallation completed!"
            return 0
        else
            echo "Failed to uninstall $module_name."
            return 1
        fi
    else
        echo "$module_name is not installed."
        return 0
    fi
}

# Function to process module installation
process_module_install() {
    local module_name=$1
    echo "Processing $module_name..."
    if ! check_module "$module_name"; then
        echo "Installing $module_name module..."
        
        # Run the installation with native progress display
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
        RESULT=$?
        
        if [ $RESULT -eq 0 ]; then
            echo "$module_name installation completed!"
            return 0
        else
            echo "Failed to install $module_name."
            return 1
        fi
    else
        echo "$module_name is already installed."
        return 0
    fi
}

# Process each module with error handling
FAILED_MODULES=()
for module in "${MODULES_TO_PROCESS[@]}"; do
    if [ "$UNINSTALL_MODE" = true ]; then
        if ! process_module_uninstall "$module"; then
            FAILED_MODULES+=("$module")
        fi
    else
        if ! process_module_install "$module"; then
            FAILED_MODULES+=("$module")
        fi
    fi
done

# Final status report
echo "----------------------------------------"
if [ ${#FAILED_MODULES[@]} -eq 0 ]; then
    if [ "$UNINSTALL_MODE" = true ]; then
        echo "PowerShell module uninstallation completed successfully!"
    else
        echo "PowerShell module installation completed successfully!"
    fi
else
    if [ "$UNINSTALL_MODE" = true ]; then
        echo "PowerShell module uninstallation completed with some issues:"
    else
        echo "PowerShell module installation completed with some issues:"
    fi
    for module in "${FAILED_MODULES[@]}"; do
        echo "- Failed to process: $module"
    done
    exit 1
fi