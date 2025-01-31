# Define the URL and temporary file path
$url = "https://github.com/norwegianredcross/devcontainer-toolbox/releases/download/latest/dev_containers.zip"
$tempZipPath = Join-Path $env:TEMP "dev_containers_temp.zip"
$currentLocation = Get-Location

try {
    # Download the zip file
    Write-Host "Downloading zip file from $url..."
    Invoke-WebRequest -Uri $url -OutFile $tempZipPath

    # Create a temporary extraction directory
    $tempExtractPath = Join-Path $env:TEMP "dev_containers_extract"
    if (Test-Path $tempExtractPath) {
        Remove-Item $tempExtractPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempExtractPath | Out-Null

    # Extract the zip file to temporary location
    Write-Host "Extracting zip file..."
    Expand-Archive -Path $tempZipPath -DestinationPath $tempExtractPath

    # Handle .devcontainer folder
    $sourceDevContainer = Join-Path $tempExtractPath ".devcontainer"
    $targetDevContainer = Join-Path $currentLocation ".devcontainer"
    if (Test-Path $sourceDevContainer) {
        if (Test-Path $targetDevContainer) {
            Remove-Item $targetDevContainer -Recurse -Force
        }
        Write-Host "Copying .devcontainer folder..."
        Copy-Item -Path $sourceDevContainer -Destination $currentLocation -Recurse
    }

    # Handle .devcontainer.extend folder
    $sourceDevContainerExtend = Join-Path $tempExtractPath ".devcontainer.extend"
    $targetDevContainerExtend = Join-Path $currentLocation ".devcontainer.extend"
    if (Test-Path $sourceDevContainerExtend) {
        if (-not (Test-Path $targetDevContainerExtend)) {
            Write-Host "Copying .devcontainer.extend folder..."
            Copy-Item -Path $sourceDevContainerExtend -Destination $currentLocation -Recurse
        }
        else {
            Write-Host ".devcontainer.extend folder already exists, skipping..."
        }
    }

    Write-Host "Operation completed successfully!"
}
catch {
    Write-Error "An error occurred: $_"
}
finally {
    # Cleanup
    if (Test-Path $tempZipPath) {
        Remove-Item $tempZipPath -Force
    }
    if (Test-Path $tempExtractPath) {
        Remove-Item $tempExtractPath -Recurse -Force
    }
}
