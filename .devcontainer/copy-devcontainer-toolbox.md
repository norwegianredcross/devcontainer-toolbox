# Copy devcontainer toolbox

This document describes how to copy the devcontainer toolbox to your project repository.

## How to use it in your project

We have several options for downloading the project.

### Method 1 - Fetch and execute a script which will download the project for you

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

### Method 2 - Clone the project repository using git

1. git clone https://github.com/norwegianredcross/devcontainer-toolbox.git
2. Make sure you checkout the repo with LF line endings otherwise the shell scripts will return an error.
3. Open your repository in VS Code by running `code .`
4. When prompted, click "Reopen in Container"

### Method 3 - Manually fetch the zipped project and extract it in your current folder

1. Download the repository zip file from: <https://github.com/norwegianredcross/devcontainer-toolbox/releases/download/latest/dev_containers.zip>
2. In your development repository, copy the following folders:
   - `.devcontainer`
   - `.devcontainer.extend`
   - `.vscode/settings.json` (if you don't already have one)
3. Open your repository in VS Code by running `code .`
4. When prompted, click "Reopen in Container"

The first time you use the devcontainer you must install the it If you use Windows then you read the [setup-windows.md](./setup/setup-windows.md) file. If you use Mac or Linux then you read the [setup-vscode.md](./setup/setup-vscode.md) file.
