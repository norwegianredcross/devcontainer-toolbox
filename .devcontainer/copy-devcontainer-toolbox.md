# Copy devcontainer toolbox

This document describes how to copy the devcontainer toolbox to your project repository.

## How to use it in your project

1. Download the zip file That contains this repository: <https://github.com/terchris/devcontainer-toolbox/archive/refs/heads/main.zip>
You will get a file named `devcontainer-toolbox-main.zip` that you unpack to `devcontainer-toolbox-main`
2. In your development repo (eg development/my-project) copy the folders:
    - `.devcontainer`
    - `.devcontainer.extend`
    - If you dont have a `.vscode/settings.json` file, you can copy the one from the `devcontainer-toolbox-main/.vscode/settings.json`
3. Start vscode in your development repo by opening a command line/cmd and typing `code .`
4. vscode will start up and you will get a question "". Here you click on the open in devcontainer.
5. The first time you start vscode the container will be built and it takes some time, just wait it is a one time job.

The first time you use the devcontainer you must install the it If you use Windows then you read the [setup-windows.md](./setup-windows.md) file. If you use Mac or Linux then you read the [setup-vscode.md](./setup-vscode.md) file.
