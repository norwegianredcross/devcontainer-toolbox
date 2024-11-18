# Data & Analytics Tools Guide

This guide covers the usage of data and analytics tools installed in your development container.

## Available Tools

### Database Management
- SQL Server/Azure SQL extension
- Azure Data Studio
- SQL formatting tools (sql-formatter, sqlfluff)

### Data Platform Tools
- Azure Data Factory
- Azure Synapse
- Databricks
- DBT (Data Build Tool)

### Python Data Analysis Libraries
- pandas
- numpy
- matplotlib
- seaborn
- scikit-learn
- jupyter

## Getting Started

### Database Connections

1. SQL Server/Azure SQL:
   ```sql
   -- Connect to SQL Server
   Server: your-server.database.windows.net
   Authentication: Azure Active Directory
   ```

2. Azure Data Studio:
   - Open Command Palette (Ctrl+Shift+P)
   - Type "Azure Data Studio: New Connection"
   - Follow the connection wizard

### Data Factory & Synapse

1. Azure Data Factory:
   - Open Command Palette
   - Search for "Azure Data Factory: New Factory"
   - Follow setup wizard

2. Azure Synapse:
   - Use Command Palette
   - Search for "Azure Synapse: Open Workspace"

### Databricks Development

1. Connect to Databricks:
   ```bash
   # Configure connection
   databricks configure --token
   ```

2. Create new notebook:
   - Command Palette > "Databricks: Create Notebook"

### DBT Development

1. Initialize DBT project:
   ```bash
   dbt init [project_name]
   ```

2. Configure profiles.yml:
   ```yaml
   [project_name]:
     target: dev
     outputs:
       dev:
         type: [postgres/snowflake/bigquery]
         # Add connection details
   ```

3. Run DBT commands:
   ```bash
   dbt run
   dbt test
   dbt docs generate
   ```

## Best Practices

### SQL Development
- Use sql-formatter for consistent formatting:
  ```bash
  sql-formatter -c config.json query.sql
  ```
- Validate SQL with sqlfluff:
  ```bash
  sqlfluff lint query.sql
  ```

### Python Data Analysis
```python
# Standard imports
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# Load data
df = pd.read_csv('data.csv')

# Basic analysis
df.describe()
df.info()

# Visualization
plt.figure(figsize=(10, 6))
sns.scatterplot(data=df, x='column1', y='column2')
plt.show()
```

### Jupyter Notebooks
1. Start Jupyter:
   ```bash
   jupyter notebook
   ```
2. Access via browser at localhost:8888

## Troubleshooting

### Common Issues

1. Database Connection Issues:
   - Verify network connectivity
   - Check firewall settings
   - Ensure Azure AD token is valid

2. DBT Problems:
   - Validate profiles.yml configuration
   - Check target schema permissions
   - Run `dbt debug` for diagnostics

3. Python Package Issues:
   - Update packages: `pip install --upgrade [package]`
   - Check compatibility: `pip check`

### Getting Help

- SQL Server/Azure SQL: [Documentation](https://docs.microsoft.com/en-us/sql/)
- Databricks: [Documentation](https://docs.databricks.com/)
- DBT: [Documentation](https://docs.getdbt.com/)
- Azure Data Factory: [Documentation](https://docs.microsoft.com/en-us/azure/data-factory/)
- Azure Synapse: [Documentation](https://docs.microsoft.com/en-us/azure/synapse-analytics/)
