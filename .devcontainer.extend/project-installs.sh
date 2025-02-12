#!/bin/bash
# File: .devcontainer.extend/project-installs.sh
# Purpose: Post-creation setup script for development container
# Called after the devcontainer is created and installs the sw needed for a spesiffic project.
# So add you stuff here and they will go into your development container.

set -e

# Main execution flow
main() {
    echo "🚀 Starting project-installs setup..."

    # Set container ID and change hostname
    # shellcheck source=/dev/null
    source "$(dirname "$(dirname "$(realpath "$0")")")/.devcontainer/additions/set-hostname.sh"
    set_container_id || {
        echo "❌ Failed to set container ID"
        return 1
    }


    # Mark the git folder as safe
    mark_git_folder_as_safe

    # Version checks
    echo "🔍 Verifying installed versions..."
    check_node_version
    check_python_version
    check_powershell_version
    check_azure_cli_version
    check_npm_packages



    # Run project-specific installations
    install_project_tools

    echo "🎉 Post-creation setup complete!"
}

# Check Node.js version
check_node_version() {
    echo "Checking Node.js installation..."
    if command -v node >/dev/null 2>&1; then
        NODE_VERSION=$(node --version)
        echo "✅ Node.js is installed (version: $NODE_VERSION)"
    else
        echo "❌ Node.js is not installed"
        exit 1
    fi
}

# Check Python version
check_python_version() {
    echo "Checking Python installation..."
    if command -v python >/dev/null 2>&1; then
        PYTHON_VERSION=$(python --version)
        echo "✅ Python is installed (version: $PYTHON_VERSION)"
    else
        echo "❌ Python is not installed"
        exit 1
    fi
}

# Check PowerShell version
check_powershell_version() {
    echo "PowerShell version:"
    pwsh -Version
}

# Check Azure CLI version
check_azure_cli_version() {
    echo "Azure CLI version:"
    az version
}

# Check global npm packages versions
check_npm_packages() {
    echo "📦 Installed npm global packages:"
    npm list -g --depth=0
}



mark_git_folder_as_safe() {
    echo "🔒 Setting up Git repository safety..."

    # Check current ownership
    local repo_owner=$(stat -c '%u' /workspace/.git)
    local container_user=$(id -u)
    echo "👤 Repository ownership:"
    echo "   Repository owner ID: $repo_owner"
    echo "   Container user ID: $container_user"
    ls -l /workspace/.git

    # Mark workspace as safe globally
    git config --global --add safe.directory /workspace
    git config --global --add safe.directory '*'

    # Additional git configurations for mounted volumes
    git config --global core.fileMode false  # Ignore file mode changes
    git config --global core.hideDotFiles false  # Show dotfiles

    # Verify the configuration
    if git config --global --get-all safe.directory | grep -q "/workspace"; then
        echo "✅ Git folder marked as safe: /workspace"
    else
        echo "❌ Failed to mark Git folder as safe"
        return 1
    fi

    # Test Git status to verify it works
    if git status &>/dev/null; then
        echo "✅ Git commands working correctly"
    else
        echo "❌ Git commands still having issues"
        return 1
    fi

    # Show final git config for verification
    echo "🔧 Current Git configuration:"
    git config --global --list | grep -E "safe|core"
}



# Run project-specific installations
install_project_tools() {
    echo "🛠️ Installing project-specific tools..."

    # === ADD YOUR PROJECT-SPECIFIC INSTALLATIONS BELOW ===

    # Example: Installing Azure Functions Core Tools
    # npm install -g azure-functions-core-tools@4

    # Example: Installing specific Python packages
    # pip install pandas numpy

    # === END PROJECT-SPECIFIC INSTALLATIONS ===
}


main
