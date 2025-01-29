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

## How to set it up

1. Download the repository zip file from: <https://github.com/terchris/devcontainer-toolbox/archive/refs/heads/main.zip>
2. In your development repository, copy the following folders:
   - `.devcontainer`
   - `.devcontainer.extend`
   - `.vscode/settings.json` (if you don't already have one)
3. Open your repository in VS Code by running `code .`
4. When prompted, click "Reopen in Container"

Or

1. git clone https://github.com/terchris/devcontainer-toolbox.git
2. Make sure you checkout the repo with LF line endings otherwise the shell scripts will return an error.

For detailed setup instructions:

- [Copy the devcontainer-toolbox](copy-devcontainer-toolbox.md) folder to your repository.
- Windows users: See [setup-windows.md](./setup/setup-windows.md)
- Mac/Linux users: See [setup-vscode.md](./setup/setup-mac.md)

- How to use a devcontainer: See [setup-vscode.md](./setup/setup-vscode.md)

## How to use dev container when developing

| What | Description |
|-----------|-------------|
| [Azure Functions](.devcontainer/howto/howto-functions-csharp.md) | Developing Azure Functions in C-sharp |
| Azure Functions | TODO: Developing Azure Functions in Python |
| Azure Functions | TODO: Developing Azure Functions in TypeScript/Javascript |
| Azure Logic Apps | TODO: Developing Azure Logic Apps |
| Azure Container Apps | TODO: Developing Azure Container Apps |
| PowerShell | TODO: Developing powerShell scripts |
| bash shell | TODO: Developing bash scripts |

## How to extend the devcontainer

Add project dependencies to the script [project-installs.sh](.devcontainer.extend/project-installs.sh) and the next developer will thank you.
See [readme-devcontainer-extend.md](.devcontainer.extend/readme-devcontainer-extend.md)

## Alternate IDEs

This howto uses vscode. But you can use other IDEs.

| Extension | Description |
|-----------|-------------|
| [JetBrains Rider](.devcontainer/howto/howto-ide-jetbrains-rider.md) | JetBrains Rider setup |
| [Visual Studio](.devcontainer/howto/howto-ide-visual-studio.md) | Visual Studio setup |
