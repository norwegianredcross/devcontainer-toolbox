# ./.devcontainer/setup/setup-windows.ps1
#
# Setup script for Devcontainer Toolbox environment on Windows
# This script installs and configures all necessary components for running devcontainers with Podman
#
# Author: Terje Christensen
# Repository: https://github.com/terchris/devcontainer-toolbox
#
# Usage: Run in PowerShell as Administrator:
# irm https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/.devcontainer/setup/setup-windows.ps1 | iex

# Script version
$script:VERSION = "1.1.0"

# Enable TLS 1.2 for downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Script variables
$script:useDocker = $false
$script:toolboxDir = $null
$script:progress = @{
    Total = 6  # Total number of major steps
    Current = 0
}

# Function to display progress
function Show-Progress {
    param(
        [string]$Status
    )
    $script:progress.Current++
    $percentage = [math]::Round(($script:progress.Current / $script:progress.Total) * 100)
    Write-Progress -Activity "Setting up Devcontainer Toolbox" -Status $Status -PercentComplete $percentage
    Write-Log $Status
}

# Function to log messages
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "Info"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    switch ($Level) {
        "Error" { Write-Host "[$timestamp] ERROR: $Message" -ForegroundColor Red }
        "Warn"  { Write-Host "[$timestamp] WARNING: $Message" -ForegroundColor Yellow }
        default { Write-Host "[$timestamp] INFO: $Message" -ForegroundColor Green }
    }
}

# Function to validate system requirements
function Test-SystemRequirements {
    Show-Progress "Checking system requirements..."
    
    # Check Windows version
    $minWindowsVersion = "10.0.19041.0"
    $windowsVersion = [System.Environment]::OSVersion.Version
    if ($windowsVersion -lt [System.Version]$minWindowsVersion) {
        throw "Windows version $windowsVersion is not supported. Minimum required: $minWindowsVersion"
    }

    # Check available disk space (minimum 10GB)
    $minimumSpace = 10GB
    $systemDrive = (Get-Item $env:SystemDrive)
    $freeSpace = $systemDrive.Free
    if ($freeSpace -lt $minimumSpace) {
        throw "Insufficient disk space. Required: $([math]::Round($minimumSpace/1GB))GB, Available: $([math]::Round($freeSpace/1GB))GB"
    }

    # Check memory
    $minimumMemoryGB = 8
    $systemMemory = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
    $systemMemoryGB = [math]::Round($systemMemory/1GB)
    if ($systemMemoryGB -lt $minimumMemoryGB) {
        throw "Insufficient memory. Required: ${minimumMemoryGB}GB, Available: ${systemMemoryGB}GB"
    }

    # Check internet connectivity
    try {
        $testConnection = Test-NetConnection -ComputerName "github.com" -Port 443
        if (-not $testConnection.TcpTestSucceeded) {
            throw "No internet connection to GitHub"
        }
    }
    catch {
        throw "Failed to verify internet connection: $_"
    }
}

# Function to check if a command exists
function Test-Command {
    param($Command)
    try {
        if (Get-Command $Command -ErrorAction Stop) { return $true }
    }
    catch { return $false }
}

# Function to show welcome message
function Show-Welcome {
    Clear-Host
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "     Devcontainer Toolbox Environment Setup v$script:VERSION" -ForegroundColor Cyan
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host
    Write-Host "This script will install and configure:"
    Write-Host "1. WSL 2 (Windows Subsystem for Linux)" -ForegroundColor Yellow
    Write-Host "2. Container Runtime (Podman Desktop or Docker)" -ForegroundColor Yellow
    Write-Host "3. Visual Studio Code" -ForegroundColor Yellow
    Write-Host "4. VS Code Dev Containers extension" -ForegroundColor Yellow
    Write-Host
    Write-Host "System Requirements:" -ForegroundColor Yellow
    Write-Host "- Windows 10 version 2004 or higher"
    Write-Host "- 8GB RAM minimum"
    Write-Host "- 10GB free disk space"
    Write-Host "- Internet connection"
    Write-Host
    Write-Host "Important:" -ForegroundColor Red
    Write-Host "- Administrator privileges required"
    Write-Host "- WSL installation requires a restart"
    Write-Host
    Write-Host "Press Enter to continue or Ctrl+C to exit..."
    Read-Host
}

# Function to validate project directory
function Test-ProjectDirectory {
    param(
        [string]$Path
    )
    
    # Check if path is valid
    if (-not [System.IO.Path]::IsPathRooted($Path)) {
        throw "Invalid path: Must be an absolute path"
    }

    # Check path length
    if ($Path.Length -gt 260) {
        throw "Path too long: Must be less than 260 characters"
    }

    # Check for invalid characters
    $invalidChars = [System.IO.Path]::GetInvalidPathChars()
    $invalidCharsFound = $Path.IndexOfAny($invalidChars)
    if ($invalidCharsFound -ge 0) {
        throw "Path contains invalid characters"
    }

    # Check write permissions
    try {
        if (-not (Test-Path $Path)) {
            New-Item -ItemType Directory -Path $Path -Force -ErrorAction Stop | Out-Null
        }
        $testFile = Join-Path $Path "write_test.tmp"
        [IO.File]::WriteAllText($testFile, "test")
        Remove-Item $testFile -Force
    }
    catch {
        throw "Cannot write to directory: $_"
    }

    return $true
}

# Function to check WSL
function Test-WSL {
    try {
        $wslStatus = wsl --status 2>&1
        return ($wslStatus -match "WSL 2")
    }
    catch {
        return $false
    }
}

# Function to check Docker
function Test-Docker {
    try {
        if (-not (Test-Command "docker")) { return $false }
        $version = docker version --format '{{.Client.Version}}' 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Docker version $version found"
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
}

# Function to check Podman
function Test-Podman {
    try {
        if (-not (Test-Command "podman")) { return $false }
        $version = podman version --format '{{.Client.Version}}' 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Podman version $version found"
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
}

# Function to handle container runtime choice
function Get-ContainerChoice {
    $hasDocker = Test-Docker
    
    if ($hasDocker) {
        Write-Host "`nDocker is installed on your system." -ForegroundColor Yellow
        Write-Host "Choose your container runtime:"
        Write-Host "1. Use existing Docker installation"
        Write-Host "2. Install Podman (recommended)"
        Write-Host "3. Exit to uninstall Docker first"
        
        $choice = Read-Host "Enter choice (1-3)"
        
        switch ($choice) {
            "1" {
                $script:useDocker = $true
                return $true
            }
            "2" {
                Write-Log "Will install Podman alongside Docker" -Level "Warn"
                return $true
            }
            "3" {
                Write-Host "Please uninstall Docker Desktop and restart your computer before running this script again."
                return $false
            }
            default {
                Write-Log "Invalid choice" -Level "Error"
                return $false
            }
        }
    }
    return $true
}

# Main installation script
try {
    Show-Welcome
    
    # Check administrator privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        throw "This script must be run as Administrator"
    }

    # Validate system requirements
    Test-SystemRequirements

    # Check WSL
    Show-Progress "Checking WSL installation..."
    $hasWSL = Test-WSL
    if (-not $hasWSL) {
        Write-Log "Installing WSL..." -Level "Warn"
        wsl --install --no-distribution
        Write-Host "`nWSL installation started. Your computer needs to restart."
        $restart = Read-Host "Would you like to restart now? (Y/N)"
        if ($restart -eq 'Y' -or $restart -eq 'y') {
            Restart-Computer -Force
        }
        exit 0
    }

    # Handle container runtime
    Show-Progress "Checking container runtime..."
    if (-not (Get-ContainerChoice)) {
        exit 0
    }

    # Get and validate project directory
    Show-Progress "Setting up project directory..."
    $defaultDir = Join-Path $env:USERPROFILE "Projects"
    Write-Host "`nChoose project directory:"
    Write-Host "1. Use default ($defaultDir)"
    Write-Host "2. Specify custom path"
    
    $dirChoice = Read-Host "Enter choice (1-2)"
    if ($dirChoice -eq "1") {
        $projectDir = $defaultDir
    }
    else {
        $projectDir = Read-Host "Enter full path for project directory"
    }

    # Validate project directory
    try {
        Test-ProjectDirectory $projectDir
    }
    catch {
        throw "Project directory validation failed: $_"
    }

    # Clone repository
    Show-Progress "Cloning repository..."
    $script:toolboxDir = Join-Path $projectDir "devcontainer-toolbox"
    if (Test-Path $script:toolboxDir) {
        $replace = Read-Host "Directory exists. Replace? (Y/N)"
        if ($replace -eq 'Y' -or $replace -eq 'y') {
            Remove-Item -Path $script:toolboxDir -Recurse -Force
        }
        else {
            throw "Installation cancelled - directory exists"
        }
    }

    try {
        git clone https://github.com/terchris/devcontainer-toolbox.git $script:toolboxDir
        if (-not $?) {
            throw "Git clone failed with exit code $LASTEXITCODE"
        }
    }
    catch {
        throw "Failed to clone repository: $_"
    }

    Show-Progress "Setup completed successfully!"

    # Final message
    Write-Progress -Activity "Setting up Devcontainer Toolbox" -Completed
    Write-Host "`n====================================================" -ForegroundColor Green
    Write-Host "Setup Complete!" -ForegroundColor Green
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host "Version: $script:VERSION"
    Write-Host "Location: $script:toolboxDir"
    Write-Host "`nNext Steps:"
    Write-Host "1. Open VS Code"
    Write-Host "2. Install Dev Containers extension"
    Write-Host "3. Open the toolbox folder"
    Write-Host "4. Click 'Reopen in Container' when prompted"

    # Offer to open VS Code
    $openVSCode = Read-Host "`nWould you like to open VS Code now? (Y/N)"
    if ($openVSCode -eq 'Y' -or $openVSCode -eq 'y') {
        Start-Process "code" -ArgumentList $script:toolboxDir
    }
}
catch {
    Write-Progress -Activity "Setting up Devcontainer Toolbox" -Completed
    Write-Log $_.Exception.Message -Level "Error"
    
    # Provide more context for the error
    Write-Host "`nError Details:" -ForegroundColor Red
    Write-Host "Line Number: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host "Command: $($_.InvocationInfo.MyCommand)" -ForegroundColor Red
    Write-Host "`nFor support, please report this issue at: https://github.com/terchris/devcontainer-toolbox/issues"
    Write-Host "Include the error message and script version ($script:VERSION) in your report."
    
    exit 1
}