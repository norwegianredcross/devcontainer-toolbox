#!/bin/bash
# file: .devcontainer/additions/install-dev-csharp.sh
#
# Usage: ./install-dev-csharp.sh [options]
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
SCRIPT_NAME="C# Development Tools"
SCRIPT_DESCRIPTION="Installs .NET SDK 8.0, Azure Functions Core Tools, and C# development extensions for VS Code"

# Before running installation, we need to add any required repositories
pre_installation_setup() {
    if [ "${UNINSTALL_MODE}" -eq 1 ]; then
        echo "🔧 Preparing for uninstallation..."
    else
        echo "🔧 Performing pre-installation setup..."
        
        # Verify Microsoft repository is configured (from Dockerfile)
        if [ ! -f /etc/apt/sources.list.d/microsoft.list ]; then
            echo "⚠️  Warning: Microsoft repository not found. It should have been configured in the Dockerfile."
            echo "Please verify the container was built correctly."
            exit 1
        fi
        
        # Ensure package lists are up to date
        echo "Updating package lists..."
        sudo apt-get update
        
        # Display current .NET version if installed
        if command -v dotnet >/dev/null 2>&1; then
            echo ".NET SDK version:"
            dotnet --info | grep -E "Version|OS|RID"
        fi
    fi
}

# Define system packages
SYSTEM_PACKAGES=(
    "dotnet-sdk-8.0"
    "aspnetcore-runtime-8.0"
)

# Define Node.js packages (for Azure Functions Core Tools)
NODE_PACKAGES=(
    "azure-functions-core-tools@4"
)

# Define VS Code extensions
declare -A EXTENSIONS
EXTENSIONS["ms-dotnettools.csdevkit"]="C# Dev Kit|Complete C# development experience"
EXTENSIONS["ms-dotnettools.csharp"]="C#|C# language support"
EXTENSIONS["ms-dotnettools.vscode-dotnet-runtime"]="NET Runtime|.NET runtime support"
EXTENSIONS["ms-azuretools.vscode-azurefunctions"]="Azure Functions|Azure Functions development"
EXTENSIONS["ms-azuretools.azure-dev"]="Azure Developer CLI|Project scaffolding and management"
EXTENSIONS["ms-azuretools.vscode-bicep"]="Bicep|Azure Bicep language support for IaC"

# Define verification commands
VERIFY_COMMANDS=(
    "command -v dotnet >/dev/null && dotnet --version || echo '❌ .NET SDK not found'"
    "dotnet --list-sdks | grep -q '8.0' && echo '✅ .NET SDK 8.0 is installed' || echo '❌ .NET SDK 8.0 not found'"
    "command -v func >/dev/null && func --version || echo '❌ Azure Functions Core Tools not found'"
    "code --list-extensions | grep -q ms-dotnettools.csdevkit && echo '✅ C# Dev Kit is installed' || echo '❌ C# Dev Kit not installed'"
    "code --list-extensions | grep -q ms-azuretools.vscode-azurefunctions && echo '✅ Azure Functions extension is installed' || echo '❌ Azure Functions extension not installed'"
)

# Post-installation notes
post_installation_message() {
    local dotnet_version
    local func_version
    
    if command -v dotnet >/dev/null 2>&1; then
        dotnet_version=$(dotnet --version)
    else
        dotnet_version="not installed"
    fi

    if command -v func >/dev/null 2>&1; then
        func_version=$(func --version)
    else
        func_version="not installed"
    fi

    echo
    echo "🎉 Installation process complete for: $SCRIPT_NAME!"
    echo "Purpose: $SCRIPT_DESCRIPTION"
    echo
    echo "Important Notes:"
    echo "1. .NET SDK $dotnet_version is installed"
    echo "2. Azure Functions Core Tools $func_version is installed"
    echo "3. C# Dev Kit and required extensions are ready to use"
    echo "4. ASP.NET Core Runtime 8.0 is installed for hosting web apps"
    echo
    echo "Quick Start Commands:"
    echo "- Create new console app: dotnet new console"
    echo "- Create new web API: dotnet new webapi"
    echo "- Create new Azure Function: func new"
    echo "- Run project: dotnet run"
    echo "- Build project: dotnet build"
    echo "- Run tests: dotnet test"
    echo
    echo "Documentation Links:"
    echo "- Local Guide: .devcontainer/howto/howto-dev-csharp.md"
    echo "- .NET Documentation: https://learn.microsoft.com/dotnet/"
    echo "- Azure Functions: https://learn.microsoft.com/azure/azure-functions/"
    echo "- C# Dev Kit: https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.csdevkit"
    echo "- Azure Functions Core Tools: https://github.com/Azure/azure-functions-core-tools"
    
    # Show detailed installation status
    echo
    echo "Installation Status:"
    echo "1. .NET Information:"
    dotnet --info | grep -E "Version|OS|RID"
    echo
    echo "2. Installed SDKs:"
    dotnet --list-sdks
    echo
    echo "3. Installed Runtimes:"
    dotnet --list-runtimes
    echo
    echo "4. Azure Functions Core Tools:"
    func --version
}

# Post-uninstallation notes
post_uninstallation_message() {
    echo
    echo "🏁 Uninstallation process complete for: $SCRIPT_NAME!"
    echo
    echo "Additional Notes:"
    echo "1. Global .NET tools remain in ~/.dotnet/tools"
    echo "2. NuGet package cache remains in ~/.nuget"
    echo "3. User settings and configurations remain unchanged"
    echo "4. See the local guide for additional cleanup steps:"
    echo "   .devcontainer/howto/howto-dev-csharp.md"
    
    # Check for remaining components
    echo
    echo "Checking for remaining components..."
    
    if command -v dotnet >/dev/null 2>&1; then
        echo
        echo "⚠️  Warning: .NET SDK is still installed"
        echo "To completely remove .NET, run:"
        echo "  sudo apt-get remove dotnet* aspnetcore*"
        echo "  sudo apt-get autoremove"
        echo "Optional: remove user directories:"
        echo "  rm -rf ~/.dotnet"
        echo "  rm -rf ~/.nuget"
    fi
    
    if command -v func >/dev/null 2>&1; then
        echo
        echo "⚠️  Warning: Azure Functions Core Tools is still installed"
        echo "To remove it, run: npm uninstall -g azure-functions-core-tools"
    fi
    
    # Check for remaining VS Code extensions
    local extensions=(
        "ms-dotnettools.csdevkit"
        "ms-dotnettools.csharp"
        "ms-dotnettools.vscode-dotnet-runtime"
        "ms-azuretools.vscode-azurefunctions"
        "ms-azuretools.azure-dev"
    )
    
    local has_extensions=0
    for ext in "${extensions[@]}"; do
        if code --list-extensions | grep -q "$ext"; then
            if [ $has_extensions -eq 0 ]; then
                echo
                echo "⚠️  Note: Some VS Code extensions are still installed:"
                has_extensions=1
            fi
            echo "- $ext"
        fi
    done
    
    if [ $has_extensions -eq 1 ]; then
        echo "To remove them, run:"
        for ext in "${extensions[@]}"; do
            echo "code --uninstall-extension $ext"
        done
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