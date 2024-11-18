# Additions readme

This folder contains additional tools that you can install in the devcontainer.

You can ofcorse also install additional sw yourself. But here we have prepared some usefull tools.

You install the tools by running the scripts from the root of your project repository.

```bash
.devcontainer/additions/install-<tool>.sh
```

The idea is that you can add the tools you need for your development by just running one of these scripts.

If you want to add the scripts to your project repository you can do that by just adding them to the script [/workspace/.devcontainer.extend/project-installs.sh](/workspace/.devcontainer.extend/project-installs.sh) script.

This script is run every time the container is rebuilt. So if there are project dependencies you add them to this script.
This ensures that all tools are available for the next developer you onboard in the project.

Read more about it in the [.devcontainer.extend/readme-devcontainer-extend.md](../../.devcontainer.extend/readme-devcontainer-extend.md) file.
