# Readme for devcontainer.extend

This folder describes how to extend the devcontainer with additional tools and extensions.

When the devcontainer is built, the script [project-installs.sh](project-installs.sh) in this folder will be executed.

Add tools you find in the `devcontainer/additions`folder to the script or write your own. installs that your project needs.

Remember to add any dependencies in the script so that the next developer you onboard will not have do a investigation to figure it out.
