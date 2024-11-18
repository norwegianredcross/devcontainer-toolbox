#!/bin/bash
# file: .devcontainer/additions/install-dev-csharp.sh

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
    "dotnet-sdk-8.0"
)

# Define Node.js packages array
NODE_PACKAGES=(
    "azure-functions-core-tools@4"
)

# Source the core installation scripts
source "$(dirname "$0")/core-install-apt.sh"
source "$(dirname "$0")/core-install-node.sh"
source "$(dirname "$0")/core-install-extensions.sh"

# Declare the VS Code extensions array
declare -A CSHARP_EXTENSIONS
CSHARP_EXTENSIONS["ms-dotnettools.csdevkit"]="C# Dev Kit|Complete C# development experience"
CSHARP_EXTENSIONS["ms-dotnettools.csharp"]="C#|C# language support"
CSHARP_EXTENSIONS["ms-azuretools.vscode-azurefunctions"]="Azure Functions|Azure Functions development"
CSHARP_EXTENSIONS["ms-azuretools.azure-dev"]="Azure Developer CLI|Project scaffolding and management"
CSHARP_EXTENSIONS["ms-dotnettools.vscode-dotnet-runtime"]=".NET Runtime|.NET runtime support"
CSHARP_EXTENSIONS["ms-azuretools.vscode-bicep"]="Bicep|Azure Bicep language support for IaC"

if [ "${UNINSTALL_MODE}" -eq 1 ]; then
    echo "🔄 Starting uninstallation process..."
    
    # First uninstall VS Code extensions
    process_extensions "CSHARP_EXTENSIONS"
    
    # Then uninstall Node.js packages
    process_packages "NODE_PACKAGES"
    
    # Finally uninstall system packages
    process_packages "SYSTEM_PACKAGES"
    
    echo "🏁 Uninstallation process complete!"
else
    echo "🔄 Starting installation process..."
    
    # First install .NET SDK
    process_packages "SYSTEM_PACKAGES"
    
    # Then install Node.js packages
    process_packages "NODE_PACKAGES"
    
    # Finally install VS Code extensions
    process_extensions "CSHARP_EXTENSIONS"
    
    # Post-installation message
    echo
    echo "🎉 Installation process complete!"
    echo
    echo "Important Notes:"
    echo "1. .NET SDK $(dotnet --version) has been installed"
    echo "2. Azure Functions Core Tools v4 has been installed"
    echo "3. C# Dev Kit and Azure Functions extensions are ready to use"
    echo
    echo "Documentation Links:"
    echo "- Azure Functions: https://learn.microsoft.com/azure/azure-functions/"
    echo "- C# Dev Kit: https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.csdevkit"
    echo "- Azure Functions Core Tools: https://github.com/Azure/azure-functions-core-tools"
    echo "- .NET 8 Documentation: https://learn.microsoft.com/dotnet/core/whats-new/dotnet-8"
fi