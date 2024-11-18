# Setting up JetBrains Rider with Dev Container

TODO: Who knows JetBrains Rider and can finish this howto?

A guide to connect JetBrains Rider to your existing Dev Container environment.

## Prerequisites

- JetBrains Rider installed
- JetBrains Gateway installed
- Rancher Desktop/Docker/Podman running

## Connection Steps

### 1. Initial Setup

1. Open JetBrains Gateway
2. Click "Connect to Dev Container"
3. Browse to your project directory (containing .devcontainer)
4. Gateway will detect the Dev Container configuration

### 2. First Connection

1. Gateway will:
   - Connect to container
   - Install required backend components
   - Start Rider instance
2. Wait for initial indexing to complete

### 3. Working with Rider

#### IDE Features

- Full IntelliSense works inside container
- Debugging attaches to container processes
- Terminal opens inside container
- NuGet operates within container

#### Debugging

1. Run/Debug configurations automatically target container
2. Breakpoints work as normal
3. Debug tools (watches, immediate window) operate in container context

## Common Issues

1. Gateway can't find Dev Container
   - Solution: Ensure Docker/Podman daemon is running
   - Verify .devcontainer folder exists

2. Slow Performance
   - Increase Gateway memory allocation in Help -> Change Memory Settings
   - Consider adjusting volume mount consistency in devcontainer.json

3. Lost Connection
   - Use "Reconnect" option in Gateway
   - Container keeps running, work is preserved

## Tips

1. Use JetBrains Toolbox for easier Gateway updates
2. Keep Gateway and Rider versions in sync
3. First connection is slower - backend installation is one-time
4. Container processes persist even if Gateway disconnects

## Keyboard Shortcuts

- Reconnect to container: Ctrl+Alt+R (Win/Linux), Cmd+Alt+R (Mac)
- Open container terminal: Alt+F12
- Attach debugger: Ctrl+Alt+D (Win/Linux), Cmd+Alt+D (Mac)
