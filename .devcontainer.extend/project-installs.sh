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
    
    # Configure Git user identity
    configure_git_identity

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

# Configure Git user identity from repository or default values
configure_git_identity() {
    echo "🔑 Setting up Git identity..."

    # First try to extract Git identity from repository configuration
    REPO_USER_NAME=""
    REPO_USER_EMAIL=""
    
    # Check if .git/config exists and is readable
    if [ -f "/workspace/.git/config" ] && [ -r "/workspace/.git/config" ]; then
        echo "📚 Attempting to read Git identity from repository..."
        
        # Try to extract user.name from repository config
        if grep -q "name = " "/workspace/.git/config"; then
            REPO_USER_NAME=$(grep "name = " "/workspace/.git/config" | head -n 1 | cut -d= -f2 | tr -d '[:space:]')
            echo "   Found name in repo: ${REPO_USER_NAME}"
        fi
        
        # Try to extract user.email from repository config
        if grep -q "email = " "/workspace/.git/config"; then
            REPO_USER_EMAIL=$(grep "email = " "/workspace/.git/config" | head -n 1 | cut -d= -f2 | tr -d '[:space:]')
            echo "   Found email in repo: ${REPO_USER_EMAIL}"
        fi
    fi
    
    # Alternative approach - check repository's commit history
    if [ -z "$REPO_USER_NAME" ] || [ -z "$REPO_USER_EMAIL" ]; then
        echo "🔍 Checking repository commit history..."
        
        # Check for user info in last commit (if available)
        if git log -1 --pretty=format:"%an:%ae" > /dev/null 2>&1; then
            COMMIT_INFO=$(git log -1 --pretty=format:"%an:%ae")
            COMMIT_NAME=$(echo "$COMMIT_INFO" | cut -d: -f1)
            COMMIT_EMAIL=$(echo "$COMMIT_INFO" | cut -d: -f2)
            
            # Use commit info if available
            if [ -n "$COMMIT_NAME" ] && [ -z "$REPO_USER_NAME" ]; then
                REPO_USER_NAME="$COMMIT_NAME"
                echo "   Found name in commit: ${REPO_USER_NAME}"
            fi
            
            if [ -n "$COMMIT_EMAIL" ] && [ -z "$REPO_USER_EMAIL" ]; then
                REPO_USER_EMAIL="$COMMIT_EMAIL"
                echo "   Found email in commit: ${REPO_USER_EMAIL}"
            fi
        fi
    fi
    
    # If we found both name and email from repo, use them
    if [ -n "$REPO_USER_NAME" ] && [ -n "$REPO_USER_EMAIL" ]; then
        GIT_USER_NAME="$REPO_USER_NAME"
        GIT_USER_EMAIL="$REPO_USER_EMAIL"
        echo "✅ Using Git identity from repository"
    else
        # Fallback to environment variables as before
        echo "⚠️ Could not find complete Git identity in repository"
        echo "   Using default values based on system username"
        
        # For Mac users
        if [ -n "$DEV_MAC_USER" ]; then
            GIT_USER_NAME="${DEV_MAC_USER}"
            GIT_USER_EMAIL="${DEV_MAC_USER}@example.com"
        # For Windows users
        elif [ -n "$DEV_WIN_USERNAME" ]; then
            GIT_USER_NAME="${DEV_WIN_USERNAME}"
            GIT_USER_EMAIL="${DEV_WIN_USERNAME}@example.com"
        else
            # Last resort fallback values
            GIT_USER_NAME="VSCode User"
            GIT_USER_EMAIL="vscode@container"
        fi
    fi

    # Set Git user configuration
    git config --global user.name "${GIT_USER_NAME}"
    git config --global user.email "${GIT_USER_EMAIL}"
    
    # Verify configuration
    echo "✅ Git identity configured:"
    echo "   Name: $(git config --global user.name)"
    echo "   Email: $(git config --global user.email)"
    
    # Remind user to update if needed
    echo "📝 Note: You can update your Git identity by running:"
    echo "   git config --global user.name \"Your Name\""
    echo "   git config --global user.email \"your.email@example.com\""
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