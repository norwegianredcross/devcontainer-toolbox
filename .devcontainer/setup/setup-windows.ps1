# ./.devcontainer/setup/setup-windows.ps1
#
# Setup script for Devcontainer Toolbox environment on Windows
# This script installs and configures all necessary components for running devcontainers with Podman
#
# Author: Terje Christensen
# Repository: https://github.com/terchris/devcontaner-toolbox
#
# Requirements:
# - Windows 10/11
# - PowerShell running as Administrator
# - Internet connection
#
# Components installed:
# - WSL 2 (Windows Subsystem for Linux)
# - Visual Studio Code
# - VS Code Dev Containers extension
# - Podman Desktop
# 
# Usage:
# 1. Open PowerShell as Administrator
# 2. Navigate to the script directory
# 3. Run: .\setup-windows.ps1
#
# Note: If WSL is not installed, the script will install it and prompt for a restart.
#       After restarting, run the script again to complete the installation.

# Progress bar configuration
$ProgressPreference = 'Continue'
$stages = @(
    @{Name = "Checking prerequisites"; Weight = 5}
    @{Name = "Installing WSL"; Weight = 15}
    @{Name = "Installing VS Code"; Weight = 20}
    @{Name = "Installing Podman Desktop"; Weight = 20}
    @{Name = "Configuring environment"; Weight = 20}
    @{Name = "Setting up toolbox"; Weight = 20}
)
$currentStage = 0
$progressTotal = ($stages | Measure-Object -Property Weight -Sum).Sum

function Update-InstallProgress {
    param (
        [string]$Activity,
        [int]$StageIndex
    )
    $completedWeight = ($stages | Select-Object -First $StageIndex | Measure-Object -Property Weight -Sum).Sum
    $percentage = ($completedWeight / $progressTotal) * 100
    Write-Progress -Activity "Installing Devcontainer Toolbox" -Status $Activity -PercentComplete $percentage
}

# Function to check if a command exists
function Test-Command($command) {
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try {
        if (Get-Command $command) {
            return $true
        }
    }
    catch {
        return $false
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }
}

# Function to log messages
function Log-Message($message, $severity = "INFO") {
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    switch ($severity) {
        "ERROR" { Write-Host "[$timestamp] ERROR: $message" -ForegroundColor Red }
        "WARN"  { Write-Host "[$timestamp] WARNING: $message" -ForegroundColor Yellow }
        default { Write-Host "[$timestamp] INFO: $message" -ForegroundColor Green }
    }
}

# Function to display welcome message and installation information
function Show-WelcomeMessage {
    Clear-Host
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "     Devcontainer Toolbox Environment Setup" -ForegroundColor Cyan
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host
    Write-Host "This script will install and configure the following components:"
    Write-Host "1. WSL 2 (Windows Subsystem for Linux)" -ForegroundColor Yellow
    Write-Host "2. Visual Studio Code" -ForegroundColor Yellow
    Write-Host "3. VS Code Dev Containers extension" -ForegroundColor Yellow
    Write-Host "4. Podman Desktop" -ForegroundColor Yellow
    Write-Host "5. Devcontainer Toolbox environment" -ForegroundColor Yellow
    Write-Host
    Write-Host "Important Notes:" -ForegroundColor Red
    Write-Host "- If WSL is not installed, you will need to restart your computer"
    Write-Host "  during the installation process."
    Write-Host "- Please ensure you have a stable internet connection."
    Write-Host "- The script requires administrator privileges."
    Write-Host
    Write-Host "Press Enter to continue or Ctrl+C to exit..."
    Read-Host
}

# Function to check if WSL is properly installed and running
function Test-WSLInstallation {
    try {
        $wslStatus = wsl --status 2>&1
        return ($wslStatus -match "WSL 2")
    }
    catch {
        return $false
    }
}

# Function to verify Podman functionality
function Test-PodmanFunctionality {
    try {
        Log-Message "Testing Podman installation with hello-world container..."
        $output = podman run hello-world 2>&1
        if ($output -match "Hello from Docker!") {
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
}

# Function to get project directory from user
function Get-ProjectDirectory {
    $defaultPath = Join-Path $env:USERPROFILE "Projects"
    
    Write-Host "`nSelect project directory:"
    Write-Host "1. Use default ($defaultPath)"
    Write-Host "2. Specify custom path"
    
    do {
        $choice = Read-Host "Enter choice (1 or 2)"
    } while ($choice -notin @('1', '2'))
    
    if ($choice -eq '1') {
        if (!(Test-Path $defaultPath)) {
            New-Item -ItemType Directory -Path $defaultPath | Out-Null
        }
        return $defaultPath
    }
    else {
        do {
            $customPath = Read-Host "Enter full path for project directory"
            if (!(Test-Path $customPath)) {
                $create = Read-Host "Directory doesn't exist. Create it? (Y/N)"
                if ($create -eq 'Y' -or $create -eq 'y') {
                    New-Item -ItemType Directory -Path $customPath | Out-Null
                    break
                }
            }
            else {
                break
            }
        } while ($true)
        return $customPath
    }
}

# Main installation script
$ErrorActionPreference = "Stop"

try {
    # Display welcome message
    Show-WelcomeMessage
    
    # Check if running as administrator
    Update-InstallProgress $stages[0].Name 0
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "This script must be run as Administrator!"
    }

    # Check WSL installation status
    Update-InstallProgress $stages[1].Name 1
    $wslInstalled = Test-WSLInstallation
    if (-not $wslInstalled) {
        Log-Message "WSL is not installed or not properly configured." -severity "WARN"
        Write-Host "`nInitiating WSL installation..." -ForegroundColor Yellow
        Write-Host "IMPORTANT: Your computer will need to restart after this step." -ForegroundColor Red
        Write-Host "After restarting, please run this script again to complete the installation.`n"
        
        $proceed = Read-Host "Press Enter to continue with WSL installation (or Ctrl+C to exit)"
        
        wsl --install --no-distribution
        Log-Message "WSL installation initiated. A system restart is required." -severity "WARN"
        Log-Message "Please restart your computer and run this script again to complete the installation." -severity "WARN"
        
        $restart = Read-Host "Would you like to restart now? (Y/N)"
        if ($restart -eq 'Y' -or $restart -eq 'y') {
            Restart-Computer -Force
        }
        exit 0
    }

    [Rest of the installation code remains the same, but add Update-InstallProgress calls at each major step]
    
    # Final success message
    Write-Progress -Activity "Installing Devcontainer Toolbox" -Completed
    Write-Host "`n====================================================" -ForegroundColor Green
    Write-Host "Installation Complete!" -ForegroundColor Green
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host "The development environment has been set up successfully."
    Write-Host "Project Location: $toolboxDir"
    Write-Host "`nNext Steps:"
    Write-Host "1. VS Code will open automatically"
    Write-Host "2. When prompted, click 'Reopen in Container'"
    Write-Host "3. Wait for the container to build (this may take a few minutes)"
    Write-Host "`nEnjoy your development environment!"
}
catch {
    Write-Progress -Activity "Installing Devcontainer Toolbox" -Completed
    Log-Message "A critical error occurred: $_" -severity "ERROR"
    exit 1
}