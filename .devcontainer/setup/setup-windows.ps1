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
        # Create a more specific temp directory
        if ($script:CONFIG.RunningFromWeb) {
            $scriptPath = Join-Path $env:TEMP "devcontainer-toolbox-setup-$(Get-Date -Format 'yyyyMMddHHmmss')"
            if (Test-Path $scriptPath) {
                Remove-Item -Path $scriptPath -Recurse -Force
            }
            New-Item -ItemType Directory -Path $scriptPath -Force | Out-Null
        }
        else {
            # Use the actual setup directory path
            $scriptPath = Join-Path $PSScriptRoot "setup"
            if (-not (Test-Path $scriptPath)) {
                throw "Setup directory not found at: $scriptPath"
            }
        }

        # Validate setup directory structure
        $requiredDirs = @(
            $scriptPath,
            (Join-Path $scriptPath "logs")
        )

        foreach ($dir in $requiredDirs) {
            if (-not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            }
        }

        return $scriptPath
    }
    catch {
        Write-Error "Failed to initialize setup environment: $_"
        exit 1
    }
}

function Import-RequiredModules {
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
        foreach ($module in $modules) {
            $modulePath = Join-Path $ScriptPath $module
            if (-not (Test-Path $modulePath)) {
                throw "Required module not found: $module at $modulePath"
            }

            try {
                . $modulePath
            }
            catch {
                throw "Failed to import module $module from $modulePath`: $_"
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

function Start-ErrorRecovery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    try {
        Write-Log "Starting error recovery..." -Level Warn

        # Create error report
        $errorReport = @{
            Timestamp = Get-Date
            ErrorMessage = $ErrorRecord.Exception.Message
            ErrorType = $ErrorRecord.Exception.GetType().Name
            ScriptName = $ErrorRecord.InvocationInfo.ScriptName
            LineNumber = $ErrorRecord.InvocationInfo.ScriptLineNumber
            StackTrace = $ErrorRecord.ScriptStackTrace
            Category = $ErrorRecord.CategoryInfo.Category
        }

        # Save error report
        $errorReportPath = Join-Path $PSScriptRoot "logs" "error-report-$(Get-Date -Format 'yyyyMMddHHmmss').json"
        $errorReport | ConvertTo-Json | Set-Content $errorReportPath

        # Attempt cleanup
        if ($script:installationSteps.Count -gt 0) {
            Write-Log "Rolling back installation steps..." -Level Warn
            
            while ($script:installationSteps.Count -gt 0) {
                $step = $script:installationSteps.Pop()
                try {
                    Write-Log "Rolling back: $($step.Name)" -Level Warn
                    & $step.Rollback
                }
                catch {
                    Write-Log "Failed to rollback step '$($step.Name)': $_" -Level Error
                }
            }
        }

        Write-Log "Error recovery completed" -Level Warn
        return $errorReportPath
    }
    catch {
        Write-Log "Error recovery failed: $_" -Level Error
    }
}

# At the start of the script
function Write-BasicError {
    param(
        [string]$Message
    )
    Write-Host "Error: $Message" -ForegroundColor Red
    Write-Host "Please check the setup requirements and try again." -ForegroundColor Yellow
}

# Main execution
try {
    $scriptPath = Initialize-SetupEnvironment
    # Import modules first
    Import-RequiredModules -ScriptPath $scriptPath
    
    if (-not (Start-Installation)) {
        exit 1
    }
}
catch {
    if (Get-Command Write-ErrorReport -ErrorAction SilentlyContinue) {
        Write-ErrorReport -ErrorRecord $_
    }
    else {
        Write-BasicError -Message $_.Exception.Message
    }
    exit 1
}
finally {
    if ($script:CONFIG.RunningFromWeb -and (Test-Path $scriptPath)) {
        Remove-Item -Path $scriptPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}