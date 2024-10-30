#!/bin/bash
# file: .devcontainer/additions/install-extensions.sh
# Description: General script for VS Code extension management

# Set error handling
set -e

# Parse command line arguments
AUTO_MODE=false
UNINSTALL_MODE=false

for arg in "$@"; do
    case $arg in
        -y)
            AUTO_MODE=true
            ;;
        --uninstall)
            UNINSTALL_MODE=true
            ;;
    esac
done

# Function to check if an extension is installed
check_extension() {
    local extension_id=$1
    local extension_dir="$HOME/.vscode-server/extensions/${extension_id}"
    
    # Check if directory exists and contains required files
    if [ -d "$extension_dir" ] && \
       [ -f "$extension_dir/extension.vsixmanifest" ] && \
       [ -d "$extension_dir/extension" ]; then
        return 0  # Extension is properly installed
    else
        return 1  # Extension is not installed or incomplete
    fi
}

# Function to install extension
install_extension() {
    local ext_id=$1
    local name=$2
    local description=$3
    local url=$4
    local headers=$5

    echo "Installing $name..."
    temp_dir=$(mktemp -d)
    cd "$temp_dir"

    # Clean up any existing failed installations
    rm -rf "$HOME/.vscode-server/extensions/${ext_id}"*

    echo "Downloading $name..."
    if ! curl -L -s \
        -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)" \
        -H "Accept: application/octet-stream" \
        $headers \
        "$url" --output extension.vsix; then
        echo "Failed to download $name"
        return 1
    fi

    # Verify the download
    if [ ! -s extension.vsix ]; then
        echo "Downloaded file is empty"
        return 1
    fi

    echo "Extracting $name..."
    target_dir="$HOME/.vscode-server/extensions/${ext_id}"
    mkdir -p "$target_dir"

    # Try to extract using 7z first, then fallback to unzip
    if command -v 7z >/dev/null 2>&1; then
        if ! 7z x -y extension.vsix -o"$target_dir" > /dev/null 2>&1; then
            echo "Failed to extract using 7z, trying unzip..."
            if ! unzip -q -o extension.vsix -d "$target_dir"; then
                echo "Failed to extract $name"
                rm -rf "$target_dir"
                return 1
            fi
        fi
    else
        if ! unzip -q -o extension.vsix -d "$target_dir"; then
            echo "Failed to extract $name"
            rm -rf "$target_dir"
            return 1
        fi
    fi

    rm extension.vsix
    cd - > /dev/null
    rm -rf "$temp_dir"
    echo "Successfully installed $name"
    return 0
}

# Function to uninstall extension
uninstall_extension() {
    local ext_id=$1
    local name=$2
    
    echo "Uninstalling ${ext_id}..."
    extension_dirs=$(find "$HOME/.vscode-server/extensions" -maxdepth 1 -type d -name "${ext_id}*" 2>/dev/null)
    if [ -n "$extension_dirs" ]; then
        if ! rm -rf $extension_dirs; then
            echo "Failed to remove $name"
            return 1
        else
            echo "Successfully removed $name"
            return 0
        fi
    else
        echo "No installation found for $name"
        return 0
    fi
}

# Function to verify installations
verify_installations() {
    local -n extensions=$1
    echo "Verifying installations..."
    for ext_id in "${!extensions[@]}"; do
        IFS='|' read -r name description url headers <<< "${extensions[$ext_id]}"
        if check_extension "$ext_id"; then
            echo "✓ $name is installed"
        else
            echo "✗ $name is not installed"
        fi
    done
}

# Function to display header
display_header() {
    local title=$1
    echo "=== $title ==="
    if [ "$UNINSTALL_MODE" = true ]; then
        echo "Operation: Uninstall extensions"
    else
        echo "Operation: Install extensions"
    fi
    echo "=========================================="
    echo
}

# Function to get extensions that need processing
get_extensions_to_process() {
    local -n extensions=$1
    local -n process_array=$2
    
    for ext_id in "${!extensions[@]}"; do
        IFS='|' read -r name description url headers <<< "${extensions[$ext_id]}"
        if [ "$UNINSTALL_MODE" = true ]; then
            if check_extension "$ext_id"; then
                process_array+=("$ext_id")
            fi
        else
            if ! check_extension "$ext_id"; then
                process_array+=("$ext_id")
            fi
        fi
    done
}

# Function to display extensions status
display_extensions_status() {
    local -n extensions=$1
    local -n process_array=$2

    if [ ${#process_array[@]} -eq 0 ]; then
        if [ "$UNINSTALL_MODE" = true ]; then
            echo "Status: No extensions were found to uninstall."
        else
            echo "Status: All extensions are already installed."
        fi
        echo "Current extension status:"
        for ext_id in "${!extensions[@]}"; do
            IFS='|' read -r name description url headers <<< "${extensions[$ext_id]}"
            if check_extension "$ext_id"; then
                echo "- $name (installed)"
            else
                echo "- $name (not installed)"
            fi
        done
        return 1
    fi

    if [ "$UNINSTALL_MODE" = true ]; then
        echo "The following extensions will be uninstalled:"
    else
        echo "The following extensions will be installed:"
    fi
    echo

    for ext_id in "${process_array[@]}"; do
        IFS='|' read -r name description url headers <<< "${extensions[$ext_id]}"
        echo "- $name"
        echo "  $description"
    done
    echo
    return 0
}

# Function to get user confirmation
get_user_confirmation() {
    if [ "$AUTO_MODE" = false ]; then
        if [ "$UNINSTALL_MODE" = true ]; then
            read -p "Do you want to proceed with the uninstallation? (y/N) " -n 1 -r
        else
            read -p "Do you want to proceed with the installation? (y/N) " -n 1 -r
        fi
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Operation cancelled."
            return 1
        fi
    fi
    return 0
}

# Function to process extensions
process_extensions() {
    local -n extensions=$1
    local -n process_array=$2
    local -n failed_array=$3

    for ext_id in "${process_array[@]}"; do
        IFS='|' read -r name description url headers <<< "${extensions[$ext_id]}"
        if [ "$UNINSTALL_MODE" = true ]; then
            if ! uninstall_extension "$ext_id" "$name"; then
                failed_array+=("$ext_id")
            fi
        else
            if ! install_extension "$ext_id" "$name" "$description" "$url" "$headers"; then
                failed_array+=("$ext_id")
            fi
        fi
    done
}

# Function to display final status
display_final_status() {
    local -n extensions=$1
    local -n failed_array=$2

    echo "----------------------------------------"
    if [ ${#failed_array[@]} -eq 0 ]; then
        if [ "$UNINSTALL_MODE" = true ]; then
            echo "Extension uninstallation completed successfully!"
        else
            echo "Extension installation completed successfully!"
        fi
        return 0
    else
        if [ "$UNINSTALL_MODE" = true ]; then
            echo "Extension uninstallation completed with some issues:"
        else
            echo "Extension installation completed with some issues:"
        fi
        for ext_id in "${failed_array[@]}"; do
            IFS='|' read -r name description url headers <<< "${extensions[$ext_id]}"
            echo "- Failed to process: $name"
        done
        return 1
    fi
} 