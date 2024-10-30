#!/bin/bash
# file: .devcontainer/additions/install-cline-ai.sh
# Description: Script to install VS Code AI development and coding assistance extensions
#
# Usage:
#   ./install-cline-ai.sh              # Interactive installation with confirmation
#   ./install-cline-ai.sh -y           # Automatic installation without confirmation
#   ./install-cline-ai.sh --uninstall  # Interactive uninstallation with confirmation
#   ./install-cline-ai.sh -y --uninstall # Automatic uninstallation without confirmation
#
# Components managed:
# 1. AI Development Tools:
#    a. Cline (prev. Claude Dev) (saoudrizwan.claude-dev)
#       - AI assistant for coding, debugging, and documentation
#       - Features:
#         - Creates and edits files with approval
#         - Executes terminal commands with permission
#         - Browser integration for testing and debugging
#         - AST and code structure analysis
#       - Documentation: https://marketplace.visualstudio.com/items?itemName=saoudrizwan.claude-dev
#       - Requires:
#         - VS Code version ^1.84.0
#         - API key from supported providers (OpenRouter, Anthropic, etc.)

source "$(dirname "$0")/install-extensions.sh"

declare -A EXTENSIONS
EXTENSIONS=(
    ["saoudrizwan.claude-dev"]="Cline|AI assistant for writing code, fixing bugs, and documentation|https://marketplace.visualstudio.com/items?itemName=saoudrizwan.claude-dev|"
)

display_header "AI Tools Extension Manager"

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