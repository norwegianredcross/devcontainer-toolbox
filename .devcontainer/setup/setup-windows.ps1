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
# - Podman Desktop (unless Docker is chosen)
# - Visual Studio Code
# - VS Code Dev Containers extension
# 
# Usage:
# 1. Open PowerShell as Administrator
# 2. Run this one-liner:
#    irm https://raw.githubusercontent.com/terchris/devcontaner-toolbox/main/.devcontainer/setup/setup-windows.ps1 | iex
#
# Note: If WSL is not installed, the script will install it and prompt for a restart.
#       After restarting, run the script again to complete the installation.

# Script-wide variables
$script:useDocker = $false
$script:toolboxDir = $null

# Progress bar configuration
$ProgressPreference = 'Continue'
# Define stages as custom objects to ensure properties are accessible
$stages = @(
    [PSCustomObject]@{Name = "Checking prerequisites"; Weight = 5}
    [PSCustomObject]@{Name = "Installing WSL"; Weight = 15}
    [PSCustomObject]@{Name = "Installing Container Runtime"; Weight = 25}
    [PSCustomObject]@{Name = "Installing VS Code"; Weight = 15}
    [PSCustomObject]@{Name = "Configuring environment"; Weight = 20}
    [PSCustomObject]@{Name = "Setting up toolbox"; Weight = 20}
)

# Calculate total weight
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

function Log-Message($message, $severity = "INFO") {
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    switch ($severity) {
        "ERROR" { Write-Host "[$timestamp] ERROR: $message" -ForegroundColor Red }
        "WARN"  { Write-Host "[$timestamp] WARNING: $message" -ForegroundColor Yellow }
        default { Write-Host "[$timestamp] INFO: $message" -ForegroundColor Green }
    }
}

function Show-WelcomeMessage {
    Clear-Host
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "     Devcontainer Toolbox Environment Setup" -ForegroundColor Cyan
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host
    Write-Host "This script will install and configure the following components:"
    Write-Host "1. WSL 2 (Windows Subsystem for Linux)" -ForegroundColor Yellow
    Write-Host "2. Container Runtime (Podman Desktop or Docker)" -ForegroundColor Yellow
    Write-Host "3. Visual Studio Code" -ForegroundColor Yellow
    Write-Host "4. VS Code Dev Containers extension" -ForegroundColor Yellow
    Write-Host "5. Devcontainer Toolbox environment" -ForegroundColor Yellow
    Write-Host
    Write-Host "Important Notes:" -ForegroundColor Red
    Write-Host "- If WSL is not installed, you will need to restart your computer"
    Write-Host "  during the installation process."
    Write-Host "- If Docker is detected, you'll be given options for container runtime"
    Write-Host "- Please ensure you have a stable internet connection."
    Write-Host "- The script requires administrator privileges."
    Write-Host
    Write-Host "Press Enter to continue or Ctrl+C to exit..."
    Read-Host
}

# System verification functions

function Test-WSLInstallation {
    try {
        $wslStatus = wsl --status 2>&1
        return ($wslStatus -match "WSL 2")
    }
    catch {
        return $false
    }
}

function Test-DockerInstallation {
    param (
        [switch]$Detailed
    )
    
    try {
        # Check Docker Desktop
        $dockerDesktopProcess = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
        $dockerExists = Test-Command "docker"
        
        if (-not $dockerExists) {
            if ($Detailed) {
                Log-Message "Docker is not installed" -severity "INFO"
            }
            return $false
        }

        # Get Docker version
        $dockerVersion = (docker version --format '{{.Client.Version}}') 2>&1
        if ($Detailed) {
            Log-Message "Found Docker version: $dockerVersion" -severity "INFO"
            if ($dockerDesktopProcess) {
                Log-Message "Docker Desktop is running" -severity "INFO"
            }
        }

        # Test Docker functionality
        $testResult = docker run --rm hello-world 2>&1
        if ($testResult -match "Hello from Docker!") {
            if ($Detailed) {
                Log-Message "Docker is installed and working correctly" -severity "INFO"
            }
            return $true
        }
        
        if ($Detailed) {
            Log-Message "Docker is installed but not functioning correctly" -severity "WARN"
        }
        return $false
    }
    catch {
        if ($Detailed) {
            Log-Message "Error checking Docker: $_" -severity "ERROR"
        }
        return $false
    }
}

function Test-PodmanInstallation {
    param (
        [switch]$Detailed
    )
    
    try {
        # Check if Podman is installed
        $podmanExists = Test-Command "podman"
        if (-not $podmanExists) {
            if ($Detailed) {
                Log-Message "Podman is not installed" -severity "WARN"
            }
            return $false
        }

        # Get Podman version
        $podmanVersion = (podman version --format "{{.Client.Version}}") 2>&1
        if ($Detailed) {
            Log-Message "Found Podman version: $podmanVersion" -severity "INFO"
        }

        # Test Podman functionality
        $testResult = podman run --rm hello-world 2>&1
        if ($testResult -match "Hello from Docker!") {
            if ($Detailed) {
                Log-Message "Podman is installed and working correctly" -severity "INFO"
            }
            return $true
        }
        
        if ($Detailed) {
            Log-Message "Podman is installed but not functioning correctly" -severity "WARN"
        }
        return $false
    }
    catch {
        if ($Detailed) {
            Log-Message "Error checking Podman: $_" -severity "ERROR"
        }
        return $false
    }
}

function Show-ContainerRuntimeChoice {
    $dockerInstalled = Test-DockerInstallation -Detailed
    $podmanInstalled = Test-PodmanInstallation -Detailed
    
    if ($dockerInstalled) {
        Write-Host "`nDocker Installation Detected!" -ForegroundColor Yellow
        Write-Host "=========================" -ForegroundColor Yellow
        
        $dockerVersion = (docker version --format '{{.Client.Version}}') 2>&1
        Write-Host "Docker version: $dockerVersion"
        
        Write-Host "`nYou have the following options:"
        Write-Host "1. Use existing Docker installation"
        Write-Host "2. Install Podman (recommended for this toolbox)"
        Write-Host "3. Uninstall Docker first, then install Podman"
        Write-Host "4. Exit and decide later"
        
        do {
            $choice = Read-Host "`nPlease enter your choice (1-4)"
            switch ($choice) {
                "1" {
                    Log-Message "Proceeding with existing Docker installation" -severity "INFO"
                    Write-Host "`nNote: While Docker should work, this toolbox is optimized for Podman."
                    Write-Host "Some features might need adjustment for Docker compatibility."
                    $script:useDocker = $true
                    return $true
                }
                "2" {
                    Log-Message "Will install Podman alongside Docker" -severity "INFO"
                    Write-Host "`nNote: Having both Docker and Podman installed might cause conflicts."
                    Write-Host "Make sure to not run both at the same time."
                    return $true
                }
                "3" {
                    Log-Message "Please follow these steps:" -severity "WARN"
                    Write-Host "`n1. Exit this script (Ctrl+C)"
                    Write-Host "2. Uninstall Docker Desktop from Windows Settings"
                    Write-Host "3. Restart your computer"
                    Write-Host "4. Run this script again"
                    Write-Host "`nWould you like to exit now? (Y/N): " -NoNewline
                    $exit = Read-Host
                    if ($exit -eq 'Y' -or $exit -eq 'y') {
                        exit 0
                    }
                }
                "4" {
                    Log-Message "Installation cancelled by user" -severity "INFO"
                    exit 0
                }
            }
        } while ($choice -notin '1','2','3','4')
    }
    return $true
}

function Show-SystemStatus {
    Write-Host "`nCurrent System Status:" -ForegroundColor Cyan
    Write-Host "=====================" -ForegroundColor Cyan

    # Check WSL
    $wslStatus = Test-WSLInstallation
    Write-Host "WSL 2: " -NoNewline
    if ($wslStatus) {
        Write-Host "Installed" -ForegroundColor Green
    } else {
        Write-Host "Not installed" -ForegroundColor Red
    }

    # Check Docker
    Write-Host "Docker: " -NoNewline
    $dockerStatus = Test-DockerInstallation
    if ($dockerStatus) {
        $dockerVersion = (docker version --format '{{.Client.Version}}') 2>&1
        Write-Host "Installed (Version $dockerVersion)" -ForegroundColor Yellow
        Write-Host "  Note: Docker installation detected. You'll be asked about container runtime preference." -ForegroundColor Yellow
    } else {
        Write-Host "Not installed" -ForegroundColor Green
    }

    # Check Podman
    Write-Host "Podman: " -NoNewline
    $podmanStatus = Test-PodmanInstallation
    if ($podmanStatus) {
        $podmanVersion = (podman version --format "{{.Client.Version}}") 2>&1
        Write-Host "Installed (Version $podmanVersion)" -ForegroundColor Green
    } else {
        Write-Host "Not installed or not working" -ForegroundColor Red
    }

    # Check VS Code
    Write-Host "VS Code: " -NoNewline
    if (Test-Command "code") {
        $vsCodeVersion = (code --version)[0]
        Write-Host "Installed (Version $vsCodeVersion)" -ForegroundColor Green
    } else {
        Write-Host "Not installed" -ForegroundColor Red
    }

    Write-Host "`nInstallation Plan:" -ForegroundColor Yellow
    
    if (-not $wslStatus) {
        Write-Host "- Will install WSL 2 (requires restart)" -ForegroundColor Yellow
    }
    
    if (-not $podmanStatus -and -not $script:useDocker) {
        Write-Host "- Will install Podman Desktop" -ForegroundColor Yellow
    }
    
    if (-not (Test-Command "code")) {
        Write-Host "- Will install VS Code" -ForegroundColor Yellow
    }

    Write-Host "`nDo you want to proceed with the installation? (Y/N): " -NoNewline -ForegroundColor Cyan
    $response = Read-Host
    if ($response -ne "Y" -and $response -ne "y") {
        throw "Installation cancelled by user"
    }
}

# Installation and setup functions

function Install-VSCode {
    Log-Message "Installing Visual Studio Code..."
    try {
        $vscodePath = "$env:TEMP\vscode_installer.exe"
        # Download VS Code
        Log-Message "Downloading VS Code installer..."
        Invoke-WebRequest -Uri "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64" -OutFile $vscodePath
        
        # Install VS Code
        Log-Message "Running VS Code installer..."
        $process = Start-Process -FilePath $vscodePath -Args "/VERYSILENT /NORESTART /MERGETASKS=!runcode" -Wait -PassThru
        
        if ($process.ExitCode -ne 0) {
            throw "VS Code installation failed with exit code: $($process.ExitCode)"
        }
        
        # Cleanup
        Remove-Item $vscodePath -Force -ErrorAction SilentlyContinue
        
        # Verify installation
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        if (-not (Test-Command "code")) {
            throw "VS Code installation completed but 'code' command is not available"
        }
        
        Log-Message "VS Code installed successfully"
        return $true
    }
    catch {
        Log-Message "Error installing VS Code: $_" -severity "ERROR"
        return $false
    }
}

function Install-PodmanDesktop {
    Log-Message "Installing Podman Desktop..."
    try {
        $podmanPath = "$env:TEMP\podman_installer.exe"
        
        # Download Podman Desktop
        Log-Message "Downloading Podman Desktop installer..."
        Invoke-WebRequest -Uri "https://github.com/containers/podman-desktop/releases/latest/download/podman-desktop-setup.exe" -OutFile $podmanPath
        
        # Install Podman Desktop
        Log-Message "Running Podman Desktop installer..."
        $process = Start-Process -FilePath $podmanPath -Args "/S" -Wait -PassThru
        
        if ($process.ExitCode -ne 0) {
            throw "Podman Desktop installation failed with exit code: $($process.ExitCode)"
        }
        
        # Cleanup
        Remove-Item $podmanPath -Force -ErrorAction SilentlyContinue
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        Log-Message "Podman Desktop installed successfully"
        Log-Message "Waiting for services to initialize..." -severity "WARN"
        Start-Sleep -Seconds 10
        
        return $true
    }
    catch {
        Log-Message "Error installing Podman Desktop: $_" -severity "ERROR"
        return $false
    }
}

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
            Log-Message "Created directory: $defaultPath"
        }
        return $defaultPath
    }
    else {
        do {
            $customPath = Read-Host "Enter full path for project directory"
            if (!(Test-Path $customPath)) {
                $create = Read-Host "Directory doesn't exist. Create it? (Y/N)"
                if ($create -eq 'Y' -or $create -eq 'y') {
                    New-Item -ItemType Directory -Path $customPath -Force | Out-Null
                    Log-Message "Created directory: $customPath"
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

function Install-DevContainersExtension {
    Log-Message "Installing Dev Containers extension..."
    try {
        $process = Start-Process -FilePath "code" -ArgumentList "--install-extension ms-vscode-remote.remote-containers" -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -ne 0) {
            throw "Extension installation failed with exit code: $($process.ExitCode)"
        }
        Log-Message "Dev Containers extension installed successfully"
        return $true
    }
    catch {
        Log-Message "Error installing Dev Containers extension: $_" -severity "ERROR"
        return $false
    }
}

function Setup-Toolbox {
    param (
        [string]$ProjectDir
    )
    
    try {
        $script:toolboxDir = Join-Path $ProjectDir "devcontainer-toolbox"
        
        # Check if directory exists
        if (Test-Path $script:toolboxDir) {
            $replace = Read-Host "Toolbox directory already exists at $script:toolboxDir. Replace it? (Y/N)"
            if ($replace -eq 'Y' -or $replace -eq 'y') {
                Remove-Item -Path $script:toolboxDir -Recurse -Force
                Log-Message "Removed existing toolbox directory"
            }
            else {
                throw "Installation cancelled - directory exists"
            }
        }
        
        # Clone repository
        Log-Message "Cloning devcontainer-toolbox repository..."
        $process = Start-Process -FilePath "git" -ArgumentList "clone", "https://github.com/terchris/devcontaner-toolbox.git", $script:toolboxDir -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -ne 0) {
            throw "Git clone failed with exit code: $($process.ExitCode)"
        }
        
        # Verify .devcontainer directory exists
        if (-not (Test-Path (Join-Path $script:toolboxDir ".devcontainer"))) {
            throw "Repository cloned but .devcontainer directory is missing"
        }
        
        # Create helpful README in project directory
        $readmePath = Join-Path $ProjectDir "README.md"
        Set-Content -Path $readmePath -Value @"
# Development Projects Directory

This directory contains your development projects.

## Devcontainer Toolbox
The devcontainer-toolbox is located in: $script:toolboxDir

To use the toolbox:
1. Open VS Code
2. File -> Open Folder -> Navigate to $script:toolboxDir
3. When prompted, click "Reopen in Container"

If not prompted automatically:
1. Press F1 or Ctrl + Shift + P
2. Type "Reopen in Container"
3. Select "Dev Containers: Reopen in Container"
"@
        
        Log-Message "Toolbox setup completed successfully"
        return $true
    }
    catch {
        Log-Message "Error setting up toolbox: $_" -severity "ERROR"
        return $false
    }
}

# Main execution logic
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

    # Check for required commands
    if (-not (Test-Command "git")) {
        throw "Git is not installed. Please install Git from https://git-scm.com/download/win"
    }

    # Show current system status and get confirmation
    Show-SystemStatus

    # Check WSL installation
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

    # Handle container runtime choice
    Update-InstallProgress $stages[2].Name 2
    $proceedWithInstall = Show-ContainerRuntimeChoice
    if (-not $proceedWithInstall) {
        exit 0
    }

    # Install appropriate container runtime
    if (-not $script:useDocker) {
        if (-not (Test-PodmanInstallation)) {
            if (-not (Install-PodmanDesktop)) {
                throw "Failed to install Podman Desktop"
            }
            
            # Verify Podman installation
            if (-not (Test-PodmanInstallation -Detailed)) {
                Log-Message "Podman installation needs configuration." -severity "WARN"
                Log-Message "Please complete these steps:" -severity "WARN"
                Log-Message "1. Launch Podman Desktop from the Start menu" -severity "WARN"
                Log-Message "2. Complete the initial setup wizard" -severity "WARN"
                Log-Message "3. Press Enter once Podman is configured" -severity "WARN"
                Read-Host
            }
        }
    }

    # Install VS Code if needed
    Update-InstallProgress $stages[3].Name 3
    if (-not (Test-Command "code")) {
        if (-not (Install-VSCode)) {
            throw "Failed to install Visual Studio Code"
        }
        Log-Message "Waiting for VS Code installation to complete..." -severity "INFO"
        Start-Sleep -Seconds 5
    }

    # Install Dev Containers extension
    if (-not (Install-DevContainersExtension)) {
        throw "Failed to install Dev Containers extension"
    }

    # Configure environment
    Update-InstallProgress $stages[4].Name 4
    $projectDir = Get-ProjectDirectory

    # Set up toolbox
    Update-InstallProgress $stages[5].Name 5
    if (-not (Setup-Toolbox -ProjectDir $projectDir)) {
        throw "Failed to set up toolbox"
    }

    # Final success message
    Write-Progress -Activity "Installing Devcontainer Toolbox" -Completed
    Write-Host "`n====================================================" -ForegroundColor Green
    Write-Host "Installation Complete!" -ForegroundColor Green
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host "The development environment has been set up successfully."
    Write-Host "Project Location: $script:toolboxDir"
    Write-Host "`nNext Steps:"
    Write-Host "1. VS Code will open automatically"
    Write-Host "2. When prompted, click 'Reopen in Container'"
    Write-Host "3. Wait for the container to build (this may take a few minutes)"
    
    if ($script:useDocker) {
        Write-Host "`nDocker-specific notes:" -ForegroundColor Yellow
        Write-Host "- Make sure Docker Desktop is running"
        Write-Host "- You may need to adjust Docker settings for best performance"
    } else {
        Write-Host "`nPodman-specific notes:" -ForegroundColor Yellow
        Write-Host "- Make sure Podman Desktop is running"
        Write-Host "- If you encounter any issues, check Podman Desktop settings"
    }
    
    Write-Host "`nEnjoy your development environment!"

    # Offer to open VS Code
    $openVSCode = Read-Host "`nWould you like to open the project in VS Code now? (Y/N)"
    if ($openVSCode -eq 'Y' -or $openVSCode -eq 'y') {
        Start-Process "code" -ArgumentList $script:toolboxDir
    }
}
catch {
    Write-Progress -Activity "Installing Devcontainer Toolbox" -Completed
    Log-Message "A critical error occurred: $_" -severity "ERROR"
    
    # Provide helpful error context
    switch -Regex ($_) {
        "Access.*denied" {
            Log-Message "This might be a permissions issue. Make sure you're running as Administrator." -severity "WARN"
        }
        "git" {
            Log-Message "Git related error. Make sure Git is installed and in your PATH." -severity "WARN"
        }
        "network|connection|download" {
            Log-Message "Network error. Check your internet connection and try again." -severity "WARN"
        }
        "docker|podman" {
            Log-Message "Container runtime error. Try restarting Docker/Podman and run the script again." -severity "WARN"
        }
        default {
            Log-Message "If the error persists, please report this issue on GitHub." -severity "WARN"
        }
    }
    
    exit 1
}
