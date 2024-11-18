# Setting up Visual Studio with Dev Container

TODO: Who knows Visual Studio and can finish this howto?

A guide to connect Visual Studio to your existing Dev Container environment.

## Prerequisites

- Visual Studio 2022 installed
- Container Tools workload installed in Visual Studio
- Existing Dev Container with VPN configured
- Docker/Podman running

## Connection Steps

### 1. Initial Setup

1. Open Visual Studio
2. Tools -> Options -> Container Tools -> Docker Compose
   - Enable "Use Docker Compose"
   - Set "Docker Compose file" to your docker-compose.yml

### 2. Project Configuration

1. Right-click your project/solution in Solution Explorer
2. Select "Add" -> "Container Orchestrator Support"
3. Choose "Docker Compose"
4. In launchSettings.json, ensure Docker profile exists:

```json
{
  "profiles": {
    "Docker": {
      "commandName": "Docker",
      "dockerDebugging": true,
      "dockerLaunchAction": "LaunchBrowser",
      "containerCommandLine": "dotnet watch run"
    }
  }
}
```

### 3. Working with Visual Studio

#### Container Integration

- Container Tools window (View -> Other Windows -> Containers)
- Docker Compose launch profile
- Integrated terminal runs in container context
- NuGet operates within container

#### Debugging

1. Select "Docker" from debug target dropdown
2. Debug as normal - breakpoints work in container
3. Debug windows show container process information
4. Container Console available in Debug window

## Common Issues

1. Debug Profile Missing
   - Solution: Recreate Docker launch profile
   - Verify Container Tools workload is installed

2. Container Not Starting
   - Check Container Tools window for errors
   - Verify docker-compose.yml path in settings
   - Ensure Docker/Podman daemon is running

3. IntelliSense Issues
   - Rebuild container
   - Clean solution
   - Delete .vs folder and restart VS

## Tips

1. Use Container Tools window to:
   - Monitor container status
   - View logs
   - Manage container lifecycle
   - Access container shell

2. Performance Optimization:
   - Enable Fast Mode in Container Tools settings
   - Use volume mounts for packages folder
   - Keep container running between sessions

3. Debugging Features:
   - Live code updates with hot reload
   - Container process list in Debug window
   - Exception handling works as normal

## Keyboard Shortcuts

- Build container: Ctrl+Shift+B
- Start debugging: F5
- Container Tools window: Ctrl+Q then search "container"
- Attach to container process: Ctrl+Alt+P

## Visual Studio Settings

### Recommended Container Tools Settings

Tools -> Options -> Container Tools:

```
- Enable Fast Mode: Yes
- Keep containers running on solution close: Yes
- Automatic container refresh: Yes
- Pull updated images on open: No (faster startup)
```

### Launch Profile Properties

Properties to customize in launchSettings.json:

```json
{
  "Docker": {
    "useSSL": true,
    "sslPort": 44301,
    "httpPort": 5000,
    "dockerDebugging": true,
    "environmentVariables": {
      "ASPNETCORE_ENVIRONMENT": "Development"
    }
  }
}
```

## Integration Features

1. Solution Explorer:
   - Shows container status indicators
   - Right-click options for container operations
   - Dockerfile editing with IntelliSense

2. Error List:
   - Container-specific errors shown
   - Links to container logs
   - Build errors from container context

3. Package Management:
   - NuGet works within container
   - Package restore uses container environment
   - References resolve to container paths

4. Source Control:
   - Git operations work normally
   - Container status ignored by default
   - Dockerfile changes tracked
