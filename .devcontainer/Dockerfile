# Start with Python 3.11 image based on Debian 12 (Bookworm)
FROM --platform=linux/amd64 mcr.microsoft.com/devcontainers/python:1-3.11-bookworm

# Update and install packages as root
USER root
ENV DEBIAN_FRONTEND=noninteractive

# Update to Node.js 20.x
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

# Install only nodejs as other required packages are in base image
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Azure CLI (updated method for Debian 12)
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install TypeScript globally
RUN npm install -g typescript && npm cache clean --force

# Create and set permissions for VS Code directories
RUN mkdir -p /home/vscode/.vscode-server/extensions \
    /home/vscode/.vscode-server/data \
    /home/vscode/.vscode-server/bin && \
    chown -R vscode:vscode /home/vscode/.vscode-server

# Final system update and cleanup
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    # Clean up
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Switch back to the vscode user for security
USER vscode