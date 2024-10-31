#!/bin/bash
# file: .devcontainer/additions/install-data-analytics.sh

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

# Define Python packages array
PYTHON_PACKAGES=(
    "pandas"
    "numpy"
    "matplotlib"
    "seaborn"
    "scikit-learn"
    "jupyter"
    "dbt-core"
    "dbt-postgres"
)

# Source the core installation scripts
source "$(dirname "$0")/install-python-packages-core.sh"
source "$(dirname "$0")/install-extensions-core.sh"

# Declare the VS Code extensions array
declare -A DATA_ANALYTICS_EXTENSIONS
DATA_ANALYTICS_EXTENSIONS["ms-python.python"]="Python|Python language support"
DATA_ANALYTICS_EXTENSIONS["ms-toolsai.jupyter"]="Jupyter|Jupyter notebook support"
DATA_ANALYTICS_EXTENSIONS["ms-python.vscode-pylance"]="Pylance|Python language server"
DATA_ANALYTICS_EXTENSIONS["bastienboutonnet.vscode-dbt"]="DBT|DBT language support"
DATA_ANALYTICS_EXTENSIONS["innoverio.vscode-dbt-power-user"]="DBT Power User|Enhanced DBT support"
DATA_ANALYTICS_EXTENSIONS["databricks.databricks"]="Databricks|Databricks integration"

if [ "${UNINSTALL_MODE}" -eq 1 ]; then
    echo "🔄 Starting uninstallation process..."
    
    # First uninstall VS Code extensions (they depend on the packages)
    process_extensions "DATA_ANALYTICS_EXTENSIONS"
    
    # Then uninstall Python packages
    process_packages "PYTHON_PACKAGES"
    
    echo "🏁 Uninstallation process complete!"
else
    echo "🔄 Starting installation process..."
    
    # First install Python packages
    process_packages "PYTHON_PACKAGES"
    
    # Then install VS Code extensions
    process_extensions "DATA_ANALYTICS_EXTENSIONS"
    
    echo "🏁 Installation process complete!"
fi