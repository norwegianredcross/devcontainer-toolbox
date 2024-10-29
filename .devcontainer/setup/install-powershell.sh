#!/bin/bash
# file: .devcontainer/setup/install-powershell.sh
# deescription: Install PowerShell realted sw and vscode extensions

pwsh -Command Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted; 
pwsh -Command Install-Module -Name Az -Force -AllowClobber -Scope AllUsers;

#    Install-Module -Name Microsoft.Graph -Force -AllowClobber -Scope AllUsers; \
#    Install-Module -Name PSScriptAnalyzer -Force -Scope AllUsers"

# Install PowerShell related vscode extensions