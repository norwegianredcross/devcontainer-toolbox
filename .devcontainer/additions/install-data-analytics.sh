#!/bin/bash
# file: .devcontainer/additions/install-data-analytics.sh
#
# Usage: ./install-data-analytics.sh [options]
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
SCRIPT_NAME="Data & Analytics Tools"
SCRIPT_DESCRIPTION="Installs Python data analysis libraries, Jupyter notebooks, and related VS Code extensions"

# Before running installation, we need to add any required repositories
pre_installation_setup() {
    if [ "${UNINSTALL_MODE}" -eq 1 ]; then
        echo "🔧 Preparing for uninstallation..."
    else
        echo "🔧 Performing pre-installation setup..."
        
        # Verify Python is installed
        if ! command -v python >/dev/null 2>&1; then
            echo "⚠️  Warning: Python not found. It should have been installed in the Dockerfile."
            echo "Please verify the container was built correctly."
            exit 1
        fi
        
        # Check pip is installed and working
        if ! command -v pip >/dev/null 2>&1; then
            echo "⚠️  Warning: pip not found. Installing pip..."
            python -m ensurepip --default-pip
        fi
        
        # Display Python and pip versions
        echo "Python configuration:"
        python --version
        pip --version
        
        # Upgrade pip to latest version
        echo "Upgrading pip to latest version..."
        python -m pip install --upgrade pip
    fi
}

# Define Python packages
PYTHON_PACKAGES=(
    "pandas"
    "numpy"
    "matplotlib"
    "seaborn"
    "scikit-learn"
    "jupyter"
    "jupyterlab"
    "notebook"
    "dbt-core"
    "dbt-postgres"
)

# Define VS Code extensions
declare -A EXTENSIONS
EXTENSIONS["ms-python.python"]="Python|Python language support"
EXTENSIONS["ms-toolsai.jupyter"]="Jupyter|Jupyter notebook support"
EXTENSIONS["ms-python.vscode-pylance"]="Pylance|Python language server"
EXTENSIONS["bastienboutonnet.vscode-dbt"]="DBT|DBT language support"
EXTENSIONS["innoverio.vscode-dbt-power-user"]="DBT Power User|Enhanced DBT support"
EXTENSIONS["databricks.databricks"]="Databricks|Databricks integration"

# Define verification commands
VERIFY_COMMANDS=(
    "python --version || echo '❌ Python not found'"
    "pip --version || echo '❌ pip not found'"
    "python -c 'import pandas' 2>/dev/null && echo '✅ pandas is installed' || echo '❌ pandas not found'"
    "python -c 'import numpy' 2>/dev/null && echo '✅ numpy is installed' || echo '❌ numpy not found'"
    "python -c 'import matplotlib' 2>/dev/null && echo '✅ matplotlib is installed' || echo '❌ matplotlib not found'"
    "python -c 'import seaborn' 2>/dev/null && echo '✅ seaborn is installed' || echo '❌ seaborn not found'"
    "python -c 'import sklearn' 2>/dev/null && echo '✅ scikit-learn is installed' || echo '❌ scikit-learn not found'"
    "jupyter --version >/dev/null 2>&1 && echo '✅ jupyter is installed' || echo '❌ jupyter not found'"
    "dbt --version >/dev/null 2>&1 && echo '✅ dbt is installed' || echo '❌ dbt not found'"
)

# Post-installation notes
post_installation_message() {
    local python_version
    local jupyter_version
    local dbt_version
    
    if command -v python >/dev/null 2>&1; then
        python_version=$(python --version 2>&1)
    else
        python_version="not installed"
    fi

    if command -v jupyter >/dev/null 2>&1; then
        jupyter_version=$(jupyter --version | head -n1)
    else
        jupyter_version="not installed"
    fi

    if command -v dbt >/dev/null 2>&1; then
        dbt_version=$(dbt --version | head -n1)
    else
        dbt_version="not installed"
    fi

    echo
    echo "🎉 Installation process complete for: $SCRIPT_NAME!"
    echo "Purpose: $SCRIPT_DESCRIPTION"
    echo
    echo "Important Notes:"
    echo "1. Python: $python_version"
    echo "2. Jupyter: $jupyter_version"
    echo "3. DBT: $dbt_version"
    echo "4. All data science packages are installed in the Python environment"
    echo "5. Jupyter notebooks can be created and run directly in VS Code"
    echo
    echo "Quick Start Commands:"
    echo "- Start Jupyter Lab: jupyter lab"
    echo "- Start Jupyter Notebook: jupyter notebook"
    echo "- Initialize DBT project: dbt init [project_name]"
    echo "- Python data analysis example:"
    echo "    import pandas as pd"
    echo "    import matplotlib.pyplot as plt"
    echo "    import seaborn as sns"
    echo
    echo "Documentation Links:"
    echo "- Local Guide: .devcontainer/howto/howto-data-analytics.md"
    echo "- pandas: https://pandas.pydata.org/docs/"
    echo "- scikit-learn: https://scikit-learn.org/stable/"
    echo "- Jupyter: https://jupyter.org/documentation"
    echo "- DBT: https://docs.getdbt.com/"
    
    # Show installed package versions
    echo
    echo "Installation Status:"
    echo "Installed Python Packages:"
    pip list | grep -E "pandas|numpy|matplotlib|seaborn|scikit-learn|jupyter|dbt"
}

# Post-uninstallation notes
post_uninstallation_message() {
    echo
    echo "🏁 Uninstallation process complete for: $SCRIPT_NAME!"
    echo
    echo "Additional Notes:"
    echo "1. Python remains installed as it's part of the base container"
    echo "2. Some configuration files may remain in ~/.jupyter/"
    echo "3. DBT project files and configurations remain unchanged"
    echo "4. See the local guide for additional cleanup steps:"
    echo "   .devcontainer/howto/howto-data-analytics.md"
    
    # Check for remaining components
    echo
    echo "Checking for remaining components..."
    
    local remaining=0
    for package in pandas numpy matplotlib seaborn sklearn jupyter dbt; do
        if python -c "import $package" 2>/dev/null; then
            if [ $remaining -eq 0 ]; then
                echo "⚠️  Warning: Some Python packages may still be installed:"
                remaining=1
            fi
            echo "- $package"
        fi
    done
    
    if [ $remaining -eq 1 ]; then
        echo
        echo "To completely remove remaining packages, run:"
        echo "pip uninstall -y pandas numpy matplotlib seaborn scikit-learn jupyter dbt-core dbt-postgres"
    fi
    
    # Check for remaining VS Code extensions
    if code --list-extensions | grep -qE "ms-python|ms-toolsai|bastienboutonnet|innoverio|databricks"; then
        echo
        echo "⚠️  Note: Some VS Code extensions are still installed"
        echo "To remove them, run:"
        echo "code --uninstall-extension ms-python.python"
        echo "code --uninstall-extension ms-toolsai.jupyter"
        echo "code --uninstall-extension ms-python.vscode-pylance"
        echo "code --uninstall-extension bastienboutonnet.vscode-dbt"
        echo "code --uninstall-extension innoverio.vscode-dbt-power-user"
        echo "code --uninstall-extension databricks.databricks"
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