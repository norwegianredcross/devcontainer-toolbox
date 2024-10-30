#!/bin/bash
# File: .devcontainer/additions/install-data-analyt.sh
# Purpose: Install Data & Analytics tools and extensions

set -e

echo "🚀 Installing Data & Analytics tools..."

# Install VS Code extensions
code --install-extension ms-mssql.mssql  # SQL Server/Azure SQL
code --install-extension ms-azuredatastudio.ads  # Azure Data Studio
code --install-extension ms-azuretools.vscode-azuredatafactory  # Azure Data Factory
code --install-extension ms-azuretools.vscode-azuresynapse  # Azure Synapse
code --install-extension bastienboutonnet.vscode-dbt  # DBT
code --install-extension innoverio.vscode-dbt-power-user  # DBT Power User
code --install-extension databricks.databricks  # Databricks
code --install-extension databricks.vscode-databricks  # Databricks Connect

# Install Python packages for data analysis
pip install --no-cache-dir \
    pandas \
    numpy \
    matplotlib \
    seaborn \
    scikit-learn \
    jupyter \
    dbt-core \
    dbt-postgres

# Install additional database tools
npm install -g \
    sql-formatter \
    sqlfluff

echo "✅ Data & Analytics tools installation complete!"

# Verify installations
echo "🔍 Verifying installations..."

# Check Python packages
python -c "import pandas; print(f'pandas version: {pandas.__version__}')"
python -c "import numpy; print(f'numpy version: {numpy.__version__}')"
python -c "import matplotlib; print(f'matplotlib version: {matplotlib.__version__}')"
python -c "import seaborn; print(f'seaborn version: {seaborn.__version__}')"
python -c "import sklearn; print(f'scikit-learn version: {sklearn.__version__}')"

# Check DBT installation
dbt --version

# Check SQL formatting tools
sql-formatter --version
sqlfluff --version

echo "🎉 All Data & Analytics tools have been installed and verified!"
