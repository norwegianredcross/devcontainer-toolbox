#!/bin/bash

# Define the URL and temporary paths
URL="https://github.com/norwegianredcross/devcontainer-toolbox/releases/download/latest/dev_containers.zip"
TEMP_DIR=$(mktemp -d)
TEMP_ZIP="$TEMP_DIR/dev_containers.zip"
CURRENT_DIR=$(pwd)

# Function for cleanup
cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
}

# Function to handle errors
handle_error() {
    echo "Error: $1"
    cleanup
    exit 1
}

# Set up trap for cleanup on script exit
trap cleanup EXIT

# Download the zip file
echo "Downloading zip file from $URL..."
if ! curl -L "$URL" -o "$TEMP_ZIP"; then
    handle_error "Failed to download the zip file"
fi

# Create temporary extraction directory
EXTRACT_DIR="$TEMP_DIR/extract"
mkdir -p "$EXTRACT_DIR"

# Extract the zip file
echo "Extracting zip file..."
if ! unzip -q "$TEMP_ZIP" -d "$EXTRACT_DIR"; then
    handle_error "Failed to extract the zip file"
fi

# Handle .devcontainer folder
if [ -d "$EXTRACT_DIR/.devcontainer" ]; then
    echo "Processing .devcontainer folder..."
    if [ -d "$CURRENT_DIR/.devcontainer" ]; then
        echo "Removing existing .devcontainer folder..."
        rm -rf "$CURRENT_DIR/.devcontainer"
    fi
    echo "Copying new .devcontainer folder..."
    cp -r "$EXTRACT_DIR/.devcontainer" "$CURRENT_DIR/"
else
    echo "Warning: .devcontainer folder not found in the zip file"
fi

# Handle .devcontainer.extend folder
if [ -d "$EXTRACT_DIR/.devcontainer.extend" ]; then
    if [ -d "$CURRENT_DIR/.devcontainer.extend" ]; then
        echo ".devcontainer.extend folder already exists, skipping..."
    else
        echo "Copying .devcontainer.extend folder..."
        cp -r "$EXTRACT_DIR/.devcontainer.extend" "$CURRENT_DIR/"
    fi
else
    echo "Warning: .devcontainer.extend folder not found in the zip file"
fi

echo "Operation completed successfully!"
