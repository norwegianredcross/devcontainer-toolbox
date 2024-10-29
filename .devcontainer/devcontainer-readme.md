# Operations Toolbox

The toolbox contains the tools for working in our Azure environment. It includes configurations and tools for working with Azure infrastructure, data platforms, security operations, development and monitoring.

It gives everyone a common startingpoint. The base install sets up the tools everyone needs.
You can tailor the tolbox so that it fits your role by running scripts after the initial toolbox is set up.

The toolbox works on Max and Windows and contains the following:

## Base system

The base system is a [development container](https://code.visualstudio.com/docs/devcontainers/containers) that runs all sw so that you dont need to install any of it on your machine.

| What | Purpose | Description |
|-----------|---------|-------------|
| Dev container | OS that runs it all | [Debian 12 Bookworm](https://www.debian.org/releases/bookworm/) linux/amd64 (emulated in a mac) |
| [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/) | Azure command line | For interacting with Azure |
| [Python 3.11](https://www.python.org/downloads/release/python-3110/) | dev and scripts | To run scripts and do development |
| [Node.js 20.x](https://nodejs.org/en/blog/announcements/v20-release-announce) | dev and scripts | including Typescript |
| command line tools | various | git, curl, wget, zsh, apt-transport-https, gnupg2, software-properties-common |

The base sw is set up by the [Dockerfile](Dockerfile) in the `.devcontailer` folder.

## Base vscode Extensions

| Extension | Purpose | Description |
|-----------|---------|-------------|
| [Azure Account](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azure-account) | Authentication & Account Management | Unified login experience for Azure extensions |
| [Azure CLI Tools](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azurecli) | Command Line Interface | Azure CLI integration with IntelliSense |
| [PowerShell](https://marketplace.visualstudio.com/items?itemName=ms-vscode.powershell) | Scripting | PowerShell development |
| [Markdown All in One](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one) | Documentation | Write and preview Markdown|
| [Markdown Mermaid](https://marketplace.visualstudio.com/items?itemName=bierner.markdown-mermaid) | Diagramming / documentation | Diagram support in markdown |
| [Markdown PDF](https://marketplace.visualstudio.com/items?itemName=yzane.markdown-pdf) | Documentation | Export Markdown documentation to pdf|
| [YAML](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml) | YAML Support | For editing YAML files with syntax checking |
| [Thunder Client](https://marketplace.visualstudio.com/items?itemName=rangav.vscode-thunder-client) | API Testing | API testing and management |
| [ftp-simple](https://marketplace.visualstudio.com/items?itemName=humy2833.ftp-simple) | FTP | For file transfer |
| [Git History](https://marketplace.visualstudio.com/items?itemName=donjayamanne.githistory) | Source Control | Visualization of git changes |

The base extensions is set up by the [devcontainer.json](devcontainer.json) in the `.devcontailer` folder.

## Extending the toolbox for your use

### For PowerShell wrangling

The script [install-powerscript.sh](./setup/install-powershell.sh) installs sw and extensions for developing with PowerShell.

### For managing configuration files

The script [install-conf-script.sh](./setup/install-conf-script.sh) installs extensions for editing various config files (bicep, ansible etc.).

### For Data & Analytics

The script [install-data-analyt.sh](./setup/install-data-analyt.sh) installs extensions for working with data and analytics.

| Extension | Purpose | Description |
|-----------|---------|-------------|
| [SQL Server/Azure SQL](https://marketplace.visualstudio.com/items?itemName=ms-mssql.mssql) | SQL Development | Query editor and database management |
| [Azure Data Studio](https://marketplace.visualstudio.com/items?itemName=ms-azuredatastudio.ads) | Data Platform | Data platform management |
| [Azure Data Factory](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azuredatafactory) | ETL/ELT | Pipeline development |
| [Azure Synapse](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azuresynapse) | Analytics | Synapse workspace management |
| [DBT](https://marketplace.visualstudio.com/items?itemName=bastienboutonnet.vscode-dbt) | Data Transformation | DBT development support |
| [DBT Power User](https://marketplace.visualstudio.com/items?itemName=innoverio.vscode-dbt-power-user) | Data Transformation | Enhanced DBT features |
| [Databricks](https://marketplace.visualstudio.com/items?itemName=databricks.databricks) | Spark Development | Databricks workspace management |
| [Databricks Connect](https://marketplace.visualstudio.com/items?itemName=databricks.vscode-databricks) | Spark Development | Direct cluster interaction |

### For Azure Infrastructure

The script [install-azure-infra.sh](./setup/install-azure-infra.sh) installs extensions for working with Azure infrastructure.

| Extension | Purpose | Description |
|-----------|---------|-------------|
| [Azure API Management](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-apimanagement) | API Management | APIM policy and API management |
| [Azure Firewall](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurefirewall) | Network Security | Firewall rules and configurations |
| [Azure Resource Groups](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azure-resource-groups) | Resource Management | Resource group operations |
| [Azure Storage](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurestorage) | Storage Management | Storage account operations |
| [Azure Key Vault](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurekeyvault) | Secret Management | Key Vault operations |
| [Azure Networks](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurenetworks) | Network Management | Virtual network operations |

### For Monitoring & Logging

The script [install-mon-log.sh](./setup/install-mon-log.sh) installs extensions for working with Azure Monitoring & Logging.

| Extension | Purpose | Description |
|-----------|---------|-------------|
| [Azure Monitor](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azuremonitor) | Monitoring | Metrics and monitoring |
| [Kusto (KQL)](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azure-kusto) | Log Analytics | KQL query development |
| [Log Analytics Tools](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azureloganalyticstools) | Log Management | Log Analytics operations |
| [Application Insights](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azureappinsights) | Application Monitoring | Application performance monitoring |

### For Security Operations

The script [install-sec-ops.sh](./setup/install-sec-ops.sh) installs extensions for working with Azure Security Operations.

| Extension | Purpose | Description |
|-----------|---------|-------------|
| [Azure Sentinel](https://marketplace.visualstudio.com/items?itemName=ms-azure-sentinel.azure-sentinel) | SIEM | Security operations |
| [Sentinel Tools](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azure-sentinel-tools) | Security Analysis | Security query development |
| [Microsoft Defender](https://marketplace.visualstudio.com/items?itemName=ms-defender.defender-for-cloud) | Security | Threat protection |
| [Azure Policy](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azure-policy) | Compliance | Policy management |

### For development

We support the following in our Azure installation.

* Azure Functions
* Azure Logic Apps
* Azure Container Apps

We support development in C-Sharp, Python and JavaScript/TypeScript

#### For development in JavaScript/TypeScript

The script [install-dev-javascript.sh](./setup/install-dev-javascript.sh) installs extensions for developing in JavaScript/TypeScript

| Extension | Purpose | Description |
|-----------|---------|-------------|
| [Azure Developer CLI](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.azure-dev) | Development Tools | Project scaffolding and management |

#### For development in C-Sharp

The script [install-dev-csharp.sh](./setup/install-dev-csharp.sh) installs extensions for developing in c-sharp.

| Extension | Purpose | Description |
|-----------|---------|-------------|
| [Azure Developer CLI](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.azure-dev) | Development Tools | Project scaffolding and management |
| [C# Dev Kit](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.csdevkit) | Development Tools | Installs .Net and C# dev tools |

#### For development in Python

The script [install-dev-python.sh](./setup/install-dev-csharp.sh) installs extensions for developing in Python.

| Extension | Purpose | Description |
|-----------|---------|-------------|
| [Azure Developer CLI](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.azure-dev) | Development Tools | Project scaffolding and management |
| [Python](https://marketplace.visualstudio.com/items?itemName=ms-python.python) | Python extension | IntelliSense (Pylance), debugging (Python Debugger), formatting, linting, code navigation.... etc |
