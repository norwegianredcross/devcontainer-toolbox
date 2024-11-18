#!/bin/bash
# file: .devcontainer/setup/update-vscode-podman.sh
# Description: This script detects the Podman socket path and exports it.

echo "🔍 Starting Podman socket detection..."

# Check if Podman is installed
if ! command -v podman >/dev/null 2>&1; then
    echo "❌ Podman is not installed"
    exit 1
fi

# Define Podman machine name
PODMAN_MACHINE_NAME="podman-machine-default"

# Verify the Podman machine is running
if ! podman machine list | grep -q "$PODMAN_MACHINE_NAME.*Currently running"; then
    echo "❌ Podman machine is not running"
    exit 1
fi

# Get the socket path from `podman machine inspect`
echo "📋 Running: podman machine inspect ${PODMAN_MACHINE_NAME}"
INSPECT_OUTPUT=$(podman machine inspect "${PODMAN_MACHINE_NAME}")
echo "🔍 Inspect output: $INSPECT_OUTPUT"

# Extract the socket path
DOCKER_HOST=$(echo "$INSPECT_OUTPUT" | grep -o '"Path": "[^"]*"' | grep "podman-machine-default-api.sock" | cut -d'"' -f4)
echo "🔌 Found socket path: $DOCKER_HOST"

# Validate the socket path
if [ -z "$DOCKER_HOST" ] || [ ! -S "$DOCKER_HOST" ]; then
    echo "❌ Could not find Podman socket path or socket does not exist"
    exit 1
fi

# Format Docker host URI
if [[ "$DOCKER_HOST" != unix://* ]]; then
    DOCKER_HOST_URI="unix://${DOCKER_HOST}"
else
    DOCKER_HOST_URI="$DOCKER_HOST"
fi

# Export the socket path and Docker host URI
export DOCKER_HOST=$DOCKER_HOST_URI
export PODMAN_SOCKET=$DOCKER_HOST

# Also write the variable to the .podman_env file at the root
PODMAN_ENV_FILE="$(pwd)/.podman_env"
# Remove file if it exists
if [ -f "$PODMAN_ENV_FILE" ]; then
    rm "$PODMAN_ENV_FILE"
fi
touch "$PODMAN_ENV_FILE"
echo "DOCKER_HOST_URI=$DOCKER_HOST_URI" > "$PODMAN_ENV_FILE"
echo "DOCKER_HOST=$DOCKER_HOST" >> "$PODMAN_ENV_FILE"
echo "PODMAN_SOCKET=$PODMAN_SOCKET" >> "$PODMAN_ENV_FILE"

echo "✅ Podman socket and Docker Host URI set"
