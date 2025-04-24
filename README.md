# DevContainer Toolbox

A comprehensive development container setup that provides a consistent development environment across Windows, Mac, and Linux. This toolbox includes configurations and tools for working with Azure infrastructure, data platforms, security operations, development, and monitoring.

## About

The DevContainer Toolbox provides:

- A pre-configured development environment using Debian 12 Bookworm
- Essential base tools including Azure CLI, Python, Node.js, and common command-line utilities
- Core VS Code extensions for Azure development, PowerShell, Markdown, and YAML support
- Extensible architecture allowing easy addition of role-specific tools
- Consistent environment across all development machines

## Problem Solved

- Eliminates "it works on my machine" issues by providing a standardized development environment
- Simplifies onboarding of new developers with a ready-to-use development setup
- Allows safe experimentation with new tools without affecting your local machine
- Provides a modular approach to adding role-specific development tools
- Ensures consistent tooling across team members regardless of their operating system

## What are DevContainers, and why is everyone talking about it?

- [Developing inside a Container](https://code.visualstudio.com/docs/devcontainers/containers)
- [Youtube: Get Started with Dev Containers in VS Code](https://www.youtube.com/watch?v=b1RavPr_878&t=38s)

## Installation requirements

### Prerequisites

- Install Docker preferably via Rancher Desktop instead of Docker Desktop ([Read more about why here.](https://developer.ibm.com/blogs/awb-rancher-desktop-alternative-to-docker-desktop)). The [installation of Rancher Desktop is defined here](.devcontainer/setup/setup-windows.md).

### How to set it up in your project

For windows users the recommended approach for developing is to clone the project
inside your WSL distribution. The described method below works for testing but will
drastically decrease the overall perfomance of your machine. Read more about how
to run containers on Windows inside WSL [here](.devcontainer/wsl-readme.md).

1. Open the directory where you would like to store the devcontainers repository.
2. Open a terminal window and execute the following command to fetch and execute the download script. The script will download 2 folders into your current working folder, .devcontainer and .devcontainer.extend.

If you are using windows

```powershell
wget https://raw.githubusercontent.com/norwegianredcross/devcontainer-toolbox/refs/heads/main/update-devcontainer.ps1 -O update-devcontainer.ps1; .\update-devcontainer.ps1
```

If you are using Mac/Linux

```bash
wget https://raw.githubusercontent.com/norwegianredcross/devcontainer-toolbox/refs/heads/main/update-devcontainer.sh -O update-devcontainer.sh && chmod +x update-devcontainer.sh && ./update-devcontainer.sh
```

3. Open your repository in VS Code by running `code .`
4. When prompted, click "Reopen in Container"

(More detailed if you want [Copy the devcontainer-toolbox](.devcontainer/copy-devcontainer-toolbox.md) folder to your repository)

Setting up the devcontainer:

- Windows users: See [setup-windows.md](.devcontainer/setup/setup-windows.md)
- Mac/Linux users: See [setup-mac.md](.devcontainer/setup/setup-mac.md)

- How to use a devcontainer: See [setup-vscode.md](.devcontainer/setup/setup-vscode.md)

## How to use dev container when developing

| What                                                             | Description                                               |
| ---------------------------------------------------------------- | --------------------------------------------------------- |
| [Azure Functions](.devcontainer/howto/howto-functions-csharp.md) | Developing Azure Functions in C-sharp                     |
| Azure Functions                                                  | TODO: Developing Azure Functions in Python                |
| Azure Functions                                                  | TODO: Developing Azure Functions in TypeScript/Javascript |
| Azure Logic Apps                                                 | TODO: Developing Azure Logic Apps                         |
| Azure Container Apps                                             | TODO: Developing Azure Container Apps                     |
| PowerShell                                                       | TODO: Developing powerShell scripts                       |
| bash shell                                                       | TODO: Developing bash scripts                             |

## How to extend the devcontainer

Add project dependencies to the script [project-installs.sh](.devcontainer.extend/project-installs.sh) and the next developer will thank you.
See [readme-devcontainer-extend.md](.devcontainer.extend/readme-devcontainer-extend.md)

## Alternate IDEs

This howto uses vscode. But you can use other IDEs.

| Extension                                                           | Description           |
| ------------------------------------------------------------------- | --------------------- |
| [JetBrains Rider](.devcontainer/howto/howto-ide-jetbrains-rider.md) | JetBrains Rider setup |
| [Visual Studio](.devcontainer/howto/howto-ide-visual-studio.md)     | Visual Studio setup   |

## Contribute

Follow the [instructions](.devcontainer/git-readme.md) here on how to contribute to the project.
