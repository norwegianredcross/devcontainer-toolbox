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

1. Download the repository zip file from: <https://github.com/norwegianredcross/devcontainer-toolbox/releases/download/latest/dev_containers.zip>
2. In your development repository, copy the following folders:
   - `.devcontainer`
   - `.devcontainer.extend`
   - `.vscode/settings.json` (if you don't already have one)
3. Open your repository in VS Code by running `code .`
4. When prompted, click "Reopen in Container"

( More detailed if you want [Copy the devcontainer-toolbox](.devcontainer/copy-devcontainer-toolbox.md) folder to your repository. )

Setting up the devcontainer:

- Windows users: See [setup-windows.md](.devcontainer/setup/setup-windows.md)
- Mac/Linux users: See [setup-vscode.md](.devcontainer/setup/setup-mac.md)

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
