# C# Azure Functions Development Guide

This guide covers developing Azure Functions using C# in the development container.

TODO: finish this howto

## Available Tools

### Development Environment

- .NET 8 SDK
- Azure Functions Core Tools v4
- C# Dev Kit
- Azure Functions extension
- Azure Developer CLI

## Getting Started

### Creating a New Function App

1. Using Command Palette (Ctrl+Shift+P):

   ```
   > Azure Functions: Create New Project...
   ```

   Then follow the prompts to:
   - Select directory
   - Choose language (C#)
   - Select .NET runtime (.NET 8)
   - Choose first function trigger type

2. Using Command Line:

   ```bash
   # Create new Functions project
   func init MyFunctionApp --dotnet

   cd MyFunctionApp

   # Add a new function to the project
   func new --name MyHttpFunction --template "HTTP trigger"
   ```

### Project Structure

```
MyFunctionApp/
├── .vscode/                    # VS Code settings
├── Properties/
├── host.json                   # Functions host configuration
├── local.settings.json         # Local app settings & connection strings
├── MyFunctionApp.csproj        # Project file
└── MyHttpFunction.cs           # Function implementation
```

### Function Implementation Example

```csharp
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using System.Net;

public class MyHttpFunction
{
    [Function("MyHttpFunction")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequestData req)
    {
        var response = req.CreateResponse(HttpStatusCode.OK);
        await response.WriteAsJsonAsync(new { message = "Hello from Azure Functions" });
        return response;
    }
}
```

## Local Development

### Running Functions Locally

1. Start the Functions host:

   ```bash
   func start
   ```

   Or use VS Code's debugger (F5)

2. Default endpoints:
   - Http functions: `http://localhost:7071/api/{function-name}`
   - Other triggers: Will process based on configured trigger (queue, timer, etc.)

### Debug Configuration

`.vscode/launch.json` is automatically configured, but you can customize:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Attach to .NET Functions",
            "type": "coreclr",
            "request": "attach",
            "processId": "${command:azureFunctions.pickProcess}"
        }
    ]
}
```

## Common Trigger Types

### HTTP Trigger

```csharp
[Function("HttpExample")]
public async Task<HttpResponseData> Run(
    [HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequestData req)
{
    // Function implementation
}
```

### Timer Trigger

```csharp
[Function("TimerExample")]
public void Run([TimerTrigger("0 */5 * * * *")] TimerInfo timer)
{
    // Runs every 5 minutes
}
```

### Queue Trigger

```csharp
[Function("QueueExample")]
public void Run(
    [QueueTrigger("myqueue-items")] string myQueueItem)
{
    // Processes queue messages
}
```

## Configuration

### Local Settings

`local.settings.json`:

```json
{
    "IsEncrypted": false,
    "Values": {
        "AzureWebJobsStorage": "UseDevelopmentStorage=true",
        "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
        "CustomSetting": "Value"
    }
}
```

### Application Settings

Access settings in code:

```csharp
var config = Environment.GetEnvironmentVariable("CustomSetting");
```

## Dependency Injection

1. Program.cs setup:

```csharp
var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices(services =>
    {
        services.AddSingleton<IMyService, MyService>();
    })
    .Build();
```

2. Usage in functions:

```csharp
public class MyFunction
{
    private readonly IMyService _myService;

    public MyFunction(IMyService myService)
    {
        _myService = myService;
    }
}
```

## Best Practices

1. Error Handling

```csharp
try
{
    // Function logic
}
catch (Exception ex)
{
    log.LogError(ex, "Error processing request");
    response = req.CreateResponse(HttpStatusCode.InternalServerError);
    await response.WriteAsJsonAsync(new { error = "Internal server error" });
}
```

2. Logging

```csharp
public class MyFunction
{
    private readonly ILogger _logger;

    public MyFunction(ILoggerFactory loggerFactory)
    {
        _logger = loggerFactory.CreateLogger<MyFunction>();
    }

    [Function("MyFunction")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Function, "get")] HttpRequestData req)
    {
        _logger.LogInformation("Processing request at {Time}", DateTime.UtcNow);
        // Function implementation
    }
}
```

3. Input Validation

```csharp
public class RequestModel
{
    public string Name { required; get; }
}

[Function("ValidatedFunction")]
public async Task<HttpResponseData> Run(
    [HttpTrigger(AuthorizationLevel.Function, "post")] HttpRequestData req)
{
    var data = await req.ReadFromJsonAsync<RequestModel>();

    if (data?.Name == null)
    {
        var response = req.CreateResponse(HttpStatusCode.BadRequest);
        await response.WriteAsJsonAsync(new { error = "Name is required" });
        return response;
    }
}
```

## Deployment

### Using VS Code

1. Click on Azure icon in Activity Bar
2. Sign in to Azure if needed
3. Right-click on function app
4. Select "Deploy to Function App..."

### Using Azure Functions Core Tools

```bash
# Login to Azure
az login

# Deploy function app
func azure functionapp publish <app-name>
```

## Troubleshooting

### Common Issues

1. Missing Azure Storage Connection:
   - Ensure local.settings.json has valid storage connection
   - For local development, use Azurite: `azurite --silent`

2. Runtime Version Mismatch:
   - Check function app's FUNCTIONS_WORKER_RUNTIME setting
   - Verify .NET version in host.json and project file

3. Dependencies Not Found:
   - Run `dotnet restore`
   - Check package references in .csproj file

### Getting Help

- Azure Functions documentation: <https://learn.microsoft.com/azure/azure-functions/>
- C# Dev Kit documentation: <https://learn.microsoft.com/dotnet/core/tools/>
- Azure Functions Core Tools: <https://github.com/Azure/azure-functions-core-tools>
- .NET 8 documentation: <https://learn.microsoft.com/dotnet/core/whats-new/dotnet-8>
