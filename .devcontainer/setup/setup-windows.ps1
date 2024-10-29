<#
.SYNOPSIS
Main entry point for the Devcontainer Toolbox installation on Windows.

.DESCRIPTION
This script orchestrates the installation of the Devcontainer Toolbox environment,
managing the installation flow and coordinating between different modules.

.NOTES
Version: 1.1.0
Author: Terje Christensen
Repository: https://github.com/terchris/devcontainer-toolbox

.EXAMPLE
# Run from web:
irm https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/.devcontainer/setup/setup-windows.ps1 | iex

.EXAMPLE
# Run locally:
.\setup-windows.ps1
#>

[CmdletBinding()]
param()

# Script execution settings
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Initialize configuration if not exists
if (-not (Get-Variable -Name CONFIG -Scope Script -ErrorAction SilentlyContinue)) {
    $script:CONFIG = @{
        Version = "1.1.0"
        ToolboxDir = $null
        UseDocker = $false
        RunningFromWeb = $MyInvocation.InvocationName -eq "&"
        Progress = @{
            Total = 6
            Current = 0
            StartTime = $null
        }
        Requirements = @{
            MinWindowsVersion = "10.0.19041.0"
            MinMemoryGB = 8
            MinDiskSpaceGB = 10
        }
        Logging = @{
            Enabled = $true
            Level = "Info"
            TimestampFormat = "yyyy-MM-dd HH:mm:ss"
            Path = $null
            MaxSize = 10MB
        }
        RestartNeeded = $false
    }
}

# Installation rollback support
$script:installationSteps = New-Object System.Collections.Stack

function Initialize-SetupEnvironment {
    <#
    .SYNOPSIS
    Initializes the setup environment and validates prerequisites.
    #>
    try {
        # Validate PowerShell version
        $minPowerShellVersion = [Version]"5.1"
        if ($PSVersionTable.PSVersion -lt $minPowerShellVersion) {
            throw "PowerShell version $($PSVersionTable.PSVersion) is not supported. Minimum required: $minPowerShellVersion"
        }

        # Create temp directory for web installation
        if ($script:CONFIG.RunningFromWeb) {
            $scriptPath = Join-Path $env:TEMP "devcontainer-toolbox-setup"
            if (Test-Path $scriptPath) {
                Remove-Item -Path $scriptPath -Recurse -Force
            }
            New-Item -ItemType Directory -Path $scriptPath -Force | Out-Null

            # Register cleanup
            Register-InstallationStep -StepName "Temp Directory Creation" -RollbackAction {
                if (Test-Path $scriptPath) {
                    Remove-Item -Path $scriptPath -Recurse -Force
                }
            }
        }
        else {
            $scriptPath = $PSScriptRoot
        }

        return $scriptPath
    }
    catch {
        Write-Error "Failed to initialize setup environment: $_"
        exit 1
    }
}

function Import-RequiredModules {
    <#
    .SYNOPSIS
    Downloads and imports required setup modules.
    
    .PARAMETER ScriptPath
    The path where modules should be downloaded or found.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )

    $modules = @(
        "setup-windows-1-tests.ps1",
        "setup-windows-2-logging.ps1",
        "setup-windows-3-system.ps1",
        "setup-windows-4-containers.ps1",
        "setup-windows-5-project.ps1"
    )

    try {
        # Download modules if running from web
        if ($script:CONFIG.RunningFromWeb) {
            foreach ($module in $modules) {
                $url = "https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/.devcontainer/setup/$module"
                $outFile = Join-Path $ScriptPath $module

                try {
                    $webClient = New-Object System.Net.WebClient
                    $webClient.Headers.Add("User-Agent", "PowerShell Script")
                    $webClient.DownloadFile($url, $outFile)
                }
                catch {
                    throw "Failed to download module $module`: $_"
                }
            }
        }

        # Import modules
        foreach ($module in $modules) {
            $modulePath = Join-Path $ScriptPath $module
            if (-not (Test-Path $modulePath)) {
                throw "Required module not found: $module"
            }

            try {
                . $modulePath
            }
            catch {
                throw "Failed to import module $module`: $_"
            }
        }
    }
    catch {
        Write-Error "Failed to process required modules: $_"
        exit 1
    }
}

function Register-InstallationStep {
    <#
    .SYNOPSIS
    Registers an installation step with its rollback action.
    
    .PARAMETER StepName
    The name of the installation step.
    
    .PARAMETER RollbackAction
    The script block to execute for rollback.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$StepName,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$RollbackAction
    )
    
    $script:installationSteps.Push(@{
        Name = $StepName
        Rollback = $RollbackAction
        Timestamp = Get-Date
    })
}

function Start-Installation {
    <#
    .SYNOPSIS
    Initiates the installation process with proper sequencing and error handling.
    #>
    try {
        # Initialize logging and show welcome
        Initialize-Logging
        Show-Welcome
        
        # Validate environment
        Test-Prerequisites
        Test-ExecutionPolicy
        Test-InternetConnection
        
        # Install core components
        Install-WSLIfNeeded
        Install-ContainerRuntime
        
        # Setup project environment
        Initialize-ProjectEnvironment
        Install-RequiredExtensions
        
        # Verify and complete
        Test-Installation
        Complete-Setup
        
        return $true
    }
    catch {
        Write-ErrorReport -ErrorRecord $_
        if ($script:CONFIG.RunningFromWeb) {
            Invoke-Rollback
        }
        return $false
    }
}

# Main execution
try {
    $scriptPath = Initialize-SetupEnvironment
    Import-RequiredModules -ScriptPath $scriptPath
    
    if (-not (Start-Installation)) {
        exit 1
    }
}
catch {
    if ($script:CONFIG.Logging.Enabled) {
        Write-ErrorReport -ErrorRecord $_
    }
    else {
        Write-Error $_.Exception.Message
    }
    exit 1
}
finally {
    if ($script:CONFIG.RunningFromWeb -and (Test-Path $scriptPath)) {
        Remove-Item -Path $scriptPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}