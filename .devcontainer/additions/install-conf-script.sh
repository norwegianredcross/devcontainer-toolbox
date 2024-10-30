#!/bin/bash
# file: .devcontainer/additions/install-conf-script.sh
# Description: Script to install configuration file management extensions

# Source the extension management script
source "$(dirname "$0")/install-extensions.sh"

# Define extensions array with all details
declare -A EXTENSIONS
# Format: [extension_id]="name|description|download_url|additional_headers"
EXTENSIONS=(
    ["ms-azuretools.vscode-bicep"]="Bicep|Azure Bicep language support for Infrastructure as Code|https://ms-azuretools.gallerycdn.vsassets.io/extensions/ms-azuretools/vscode-bicep/0.30.23/1727200063555/Microsoft.VisualStudio.Services.VSIXPackage|"
    ["redhat.ansible"]="Ansible|Ansible language support and development tools|https://redhat.gallerycdn.vsassets.io/extensions/redhat/ansible/24.10.0/1727890833264/Microsoft.VisualStudio.Services.VSIXPackage|"
)

# Main execution
display_header "Configuration Tools Extension Manager"

# Get extensions that need processing
EXTENSIONS_TO_PROCESS=()
get_extensions_to_process EXTENSIONS EXTENSIONS_TO_PROCESS

# Display what will be processed
if ! display_extensions_status EXTENSIONS EXTENSIONS_TO_PROCESS; then
    exit 0
fi

# Get user confirmation
if ! get_user_confirmation; then
    exit 1
fi

# Process extensions
FAILED_EXTENSIONS=()
process_extensions EXTENSIONS EXTENSIONS_TO_PROCESS FAILED_EXTENSIONS

# Verify installations
verify_installations EXTENSIONS

# Final status report
display_final_status EXTENSIONS FAILED_EXTENSIONS 