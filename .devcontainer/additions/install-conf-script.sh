#!/bin/bash
# file: .devcontainer/additions/install-conf-script.sh
# Description: Script to install VS Code extensions for configuration management and Infrastructure as Code
#
# Usage:
#   ./install-conf-script.sh              # Interactive installation with confirmation
#   ./install-conf-script.sh -y           # Automatic installation without confirmation
#   ./install-conf-script.sh --uninstall  # Interactive uninstallation with confirmation
#   ./install-conf-script.sh -y --uninstall # Automatic uninstallation without confirmation
#
# Components managed:
# 1. Infrastructure as Code:
#    a. Bicep (ms-azuretools.vscode-bicep)
#       - Azure Bicep language support for Infrastructure as Code
#       - Enables authoring and deploying Bicep templates
#       - Documentation: https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep
#
# 2. Configuration Management:
#    a. Ansible (redhat.ansible)
#       - Ansible language support and development tools
#       - Provides syntax highlighting, validation, and snippets
#       - Documentation: https://marketplace.visualstudio.com/items?itemName=redhat.ansible

source "$(dirname "$0")/install-extensions.sh"

declare -A EXTENSIONS
EXTENSIONS=(
    ["ms-azuretools.vscode-bicep"]="Bicep|Azure Bicep language support for Infrastructure as Code|https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep|"
    ["redhat.ansible"]="Ansible|Ansible language support and development tools|https://marketplace.visualstudio.com/items?itemName=redhat.ansible|"
)

display_header "Configuration Tools Extension Manager"

EXTENSIONS_TO_PROCESS=()
get_extensions_to_process EXTENSIONS EXTENSIONS_TO_PROCESS

if ! display_extensions_status EXTENSIONS EXTENSIONS_TO_PROCESS; then
    exit 0
fi

if ! get_user_confirmation; then
    exit 1
fi

FAILED_EXTENSIONS=()
process_extensions EXTENSIONS EXTENSIONS_TO_PROCESS FAILED_EXTENSIONS

verify_installations EXTENSIONS

display_final_status EXTENSIONS FAILED_EXTENSIONS