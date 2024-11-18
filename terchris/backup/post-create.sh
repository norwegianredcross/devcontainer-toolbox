#!/bin/bash
# File: .devcontainer/post-create.sh
# Purpose: Post-creation setup script for development container
# Installs core development tools and verifies versions
# If you always need to install the addition tools than you can add them at the ned of this script.

set -e

echo "🚀 Starting post-creation setup..."

# Version requirements
REQUIRED_NODE_MAJOR=20
REQUIRED_PYTHON_MAJOR=3
REQUIRED_PYTHON_MINOR=11

# Function to check version requirements
check_version() {
    local name=$1
    local current=$2
    local required=$3
    if [[ "$current" == "$required" ]]; then
        echo "✅ $name version $current (matches required $required)"
    else
        echo "❌ $name version $current does not match required $required"
        exit 1
    fi
}


# Version Verification
echo "🔍 Verifying installed versions..."

# Check Node.js version
NODE_VERSION=$(node --version | cut -d 'v' -f2)
NODE_MAJOR=$(echo $NODE_VERSION | cut -d '.' -f1)
echo "Node.js version: $NODE_VERSION"
check_version "Node.js major" $NODE_MAJOR $REQUIRED_NODE_MAJOR

# Check Python version
PYTHON_VERSION=$(python --version | cut -d ' ' -f2)
PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d '.' -f1)
PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d '.' -f2)
echo "Python version: $PYTHON_VERSION"
check_version "Python major" $PYTHON_MAJOR $REQUIRED_PYTHON_MAJOR
check_version "Python minor" $PYTHON_MINOR $REQUIRED_PYTHON_MINOR

# Check PowerShell version
echo "PowerShell version:"
pwsh -Version

# Check Azure CLI version
echo "Azure CLI version:"
az version

# Check global npm packages versions
echo "📦 Installed npm global packages:"
npm list -g --depth=0

echo "🎉 Post-creation setup complete!"

# Final check - verify all core tools are accessible
echo "🔍 Verifying core tools accessibility..."
command -v node >/dev/null 2>&1 || { echo "❌ node not found"; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "❌ npm not found"; exit 1; }
command -v python >/dev/null 2>&1 || { echo "❌ python not found"; exit 1; }
command -v pwsh >/dev/null 2>&1 || { echo "❌ pwsh not found"; exit 1; }
command -v az >/dev/null 2>&1 || { echo "❌ az not found"; exit 1; }
echo "✅ All core tools are accessible"

# Additions: Add your tools here
# Example adding the install-powershell.sh script
#echo "START: Installing the PowerShell module"
#./.devcontainer/additions/install-powershell.sh
#echo "END: Installing the PowerShell module"
