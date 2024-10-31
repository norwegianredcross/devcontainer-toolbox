# DevContainer Toolbox

The toolbox contains the tools for working in our Azure environment. It includes configurations and tools for working with Azure infrastructure, data platforms, security operations, development and monitoring.

It gives everyone a common startingpoint. The base install sets up the tools everyone needs.
You can tailor the tolbox so that it fits your role by running scripts after the initial toolbox is set up.

The toolbox works on Mac and Windows and contains a base system and a set of extensions.

## All software you need is in a devcontainer.

The base system is a development container that runs all sw so that you dont need to install any of it on your machine. It is a good idea to have basic understanding of what a [development container](https://code.visualstudio.com/docs/devcontainers/containers) is.

The beauty of using a devcontainer is that you will have the same tools and setup on all your machines. And you can try out new tools without affecting your machine. If you install something that you dont like, you can just delete the container and reinstall it. Deleting the container will not affect your machine or the files you are working on.

## Base system

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

## Install and uninstall

The system works on Windows and Mac. Read the [setup-windows](./setup/setup-windows.md) and [setup-mac.md](./setup/setup-mac.md) for how to set it up.

The setup installs the two tools that are needed to run the devcontainer.
* [Podman Desktop](https://podman-desktop.io/)
* [VSCode](https://code.visualstudio.com/)

We have chosen to use [Podman Desktop](https://podman-desktop.io/) as it is a good container tool and it is free. You can also use Docker Desktop, but that is not free.

### Delete and rebuild the devcontainer (optional)

If you want to start over, you can delete the devcontainer and then just start vscode as usual. vscode will then automatically build and start the container again.
This is usefull if you have tested stuff and just want to start over.

First exit vscode, then run the script below.

On Mac:
```bash
.devcontainer/setup/uninstall-mac.sh
```

On Windows:
TODO: Add windows uninstall script

### Post-creation setup (optional)

After the container is created the script [post-create.sh](post-create.sh) is run. By default it just verifies that the base tools are installed. But you can extend it to install additional tools. Eg like the install-powershell.sh script.

You can also manually tailor the container by editing the [devcontainer.local.json](devcontainer.local.json) file and the [Dockerfile.local](Dockerfile.local) file.
TODO: test the .local files in a project

## Extending the toolbox for your use

We have prepared some scripts that will install additional software and extensions that you might need.
These scripts are run inside the devcontainer after it is started. To open a container terminal in vscode select Terminal -> New Terminal.
Then change to the directory where the script is located and run it.
eg:
```bash
cd .devcontainer/additions
./install-powershell.sh
```


### For PowerShell wrangling

The script [install-powerscript.sh](./additions/install-powershell.sh) installs sw and extensions for developing with PowerShell.

See howto for tips here [howto-powershell](./howto/howto-powershell.md)

Installs the following modules:
| Module | Purpose | Description |
|-----------|---------|-------------|
| [Az PowerShell Module](https://learn.microsoft.com/powershell/azure) | ??? | PowerShell module for managing Azure resources |
| [Microsoft Graph PowerShell Module](https://learn.microsoft.com/powershell/microsoftgraph) | ??? | PowerShell module for managing Microsoft Graph resources |
| [PSScriptAnalyzer](https://learn.microsoft.com/powershell/utility-modules/psscriptanalyzer) | ??? | Static code analysis tool for PowerShell scripts and modules |


Installs the following VS Code extensions:
| Extension | Purpose | Description |
|-----------|---------|-------------|
| [Azure Resources](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azureresourcegroups) | ??? | An extension for viewing and managing Azure resources. |
| [PowerShell](https://marketplace.visualstudio.com/items?itemName=ms-vscode.powershell) | ??? | PowerShell language support and debugging |
| [Azure Account](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azure-account) | ??? | Azure account management and subscriptions |




### For managing configuration files

The script [install-conf-script.sh](./additions/install-conf-script.sh) installs extensions for editing various config files (bicep, ansible etc.).

See howto for tips here [howto-conf-script](./howto/howto-conf-script.md)

Installs the following VS Code extensions:
| Extension | Purpose | Description |
|-----------|---------|-------------|
| [Bicep](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep) | Infrastructure as Code | Bicep authoring and deployment |
| [Ansible](https://marketplace.visualstudio.com/items?itemName=redhat.ansible) | Configuration Management | Ansible development |

### For Integrating AI into vscode

The script [install-cline-ai.sh](./additions/install-cline-ai.sh) installs Cline (prev. Claude Dev) extension that integrates the [Cline AI](https://www.cline.ai/) into vscode. Enabeling you to use AI to write code, fix bugs, write documentation etc.

See howto for tips here [howto-cline-ai](./howto/howto-cline-ai.md)

Installs the following VS Code extensions:
| Extension | Purpose | Description |
|-----------|---------|-------------|
| [Cline (prev. Claude Dev)](https://marketplace.visualstudio.com/items?itemName=saoudrizwan.claude-dev) | AI | Enabeling you to use AI to write code, fix bugs, write documentation etc. |


### For Data & Analytics

The script [install-data-analytics.sh](./additions/install-data-analytics.sh) installs several extensions and Python packages for working with data and analytics workloads. Below are the components that are automatically installed and configured in your development environment.

See howto for tips here [howto-data-analytics](./howto/howto-data-analytics.md)

Installs the following VS Code extensions:
| Extension | Purpose | Description |
|-----------|---------|-------------|
| Python | Language Support | Python language support and development tools |
| Jupyter | Notebook Support | Interactive Python notebook support and execution |
| Pylance | Language Server | Advanced Python language server with type checking and IntelliSense |
| DBT | Data Transformation | DBT (Data Build Tool) language support for SQL transformations |
| DBT Power User | Data Transformation | Enhanced features for DBT development and testing |
| Databricks | Integration | Databricks workspace and notebook integration |


Installs the following Python Packages:
| Package | Category | Description |
|---------|----------|-------------|
| pandas | Data Processing & Analysis | Data manipulation and analysis library with DataFrame support |
| numpy | Data Processing & Analysis | Fundamental package for numerical computing and array operations |
| matplotlib | Data Visualization | Comprehensive library for creating static, animated, and interactive visualizations |
| seaborn | Data Visualization | Statistical data visualization library built on matplotlib |
| scikit-learn | Machine Learning | Machine learning library featuring various algorithms and tools |
| jupyter | Development Tools | Interactive computing environment for creating and sharing documents |
| dbt-core | Development Tools | Core functionality for DBT data transformations |
| dbt-postgres | Development Tools | PostgreSQL adapter for DBT implementations |




### For development

We support the following in our Azure installation.

* Azure Functions
* Azure Logic Apps
* Azure Container Apps

We support development in C-Sharp, Python and JavaScript/TypeScript


#### For development in C-Sharp

The script [install-dev-csharp.sh](./additions/install-dev-csharp.sh) installs extensions for developing in c-sharp.

See howto for tips here [howto-functions-csharp](./howto/howto-functions-csharp.md)

| Extension | Purpose | Description |
|-----------|---------|-------------|
| [Azure Developer CLI](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.azure-dev) | Development Tools | Project scaffolding and management |
| [C# Dev Kit](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.csdevkit) | Development Tools | Installs .Net and C# dev tools |




#### For development in JavaScript/TypeScript

The script [install-dev-javascript.sh](./additions/install-dev-javascript.sh) installs extensions for developing in JavaScript/TypeScript

| Extension | Purpose | Description |
|-----------|---------|-------------|
| [Azure Developer CLI](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.azure-dev) | Development Tools | Project scaffolding and management |


#### For development in Python

The script [install-dev-python.sh](./additions/install-dev-csharp.sh) installs extensions for developing in Python.

| Extension | Purpose | Description |
|-----------|---------|-------------|
| [Azure Developer CLI](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.azure-dev) | Development Tools | Project scaffolding and management |
| [Python](https://marketplace.visualstudio.com/items?itemName=ms-python.python) | Python extension | IntelliSense (Pylance), debugging (Python Debugger), formatting, linting, code navigation.... etc |




## ------------------- TODO stuff ------------


### For Azure Infrastructure (TODO)

The script [install-azure-infra.sh](./additions/install-azure-infra.sh) installs extensions for working with Azure infrastructure.

| Extension | Purpose | Description |
|-----------|---------|-------------|
| [Azure API Management](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-apimanagement) | API Management | APIM policy and API management |
| [Azure Firewall](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurefirewall) | Network Security | Firewall rules and configurations |
| [Azure Resource Groups](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azure-resource-groups) | Resource Management | Resource group operations |
| [Azure Storage](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurestorage) | Storage Management | Storage account operations |
| [Azure Key Vault](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurekeyvault) | Secret Management | Key Vault operations |
| [Azure Networks](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurenetworks) | Network Management | Virtual network operations |

### For Monitoring & Logging (TODO)

The script [install-mon-log.sh](./additions/install-mon-log.sh) installs extensions for working with Azure Monitoring & Logging.

| Extension | Purpose | Description |
|-----------|---------|-------------|
| [Azure Monitor](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azuremonitor) | Monitoring | Metrics and monitoring |
| [Kusto (KQL)](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azure-kusto) | Log Analytics | KQL query development |
| [Log Analytics Tools](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azureloganalyticstools) | Log Management | Log Analytics operations |
| [Application Insights](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azureappinsights) | Application Monitoring | Application performance monitoring |

### For Security Operations (TODO)

The script [install-sec-ops.sh](./additions/install-sec-ops.sh) installs extensions for working with Azure Security Operations.

| Extension | Purpose | Description |
|-----------|---------|-------------|
| [Azure Sentinel](https://marketplace.visualstudio.com/items?itemName=ms-azure-sentinel.azure-sentinel) | SIEM | Security operations |
| [Sentinel Tools](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azure-sentinel-tools) | Security Analysis | Security query development |
| [Microsoft Defender](https://marketplace.visualstudio.com/items?itemName=ms-defender.defender-for-cloud) | Security | Threat protection |
| [Azure Policy](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azure-policy) | Compliance | Policy management |
