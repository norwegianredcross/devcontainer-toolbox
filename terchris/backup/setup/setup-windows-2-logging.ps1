<#
.SYNOPSIS
Enhanced logging and progress tracking functionality.

.DESCRIPTION
Provides comprehensive logging capabilities with multiple output targets,
detailed progress tracking, and structured error handling.

.NOTES
Version: 1.1.0
Author: Terje Christensen
#>

function Initialize-Logging {
    <#
    .SYNOPSIS
    Initializes the logging system with file rotation and error handling.

    .EXAMPLE
    Initialize-Logging
    #>
    [CmdletBinding()]
    param()

    try {
        if ($script:CONFIG.Logging.Enabled) {
            # Create logs directory in setup folder
            $logDir = Join-Path $PSScriptRoot "logs"
            if (-not (Test-Path -Path $logDir)) {
                New-Item -ItemType Directory -Path $logDir -Force | Out-Null
            }

            # Set up log file with proper naming
            $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            $script:CONFIG.Logging.Path = Join-Path $logDir "setup-$timestamp.log"

            # Implement log rotation
            $maxLogFiles = 5
            Get-ChildItem -Path $logDir -Filter "setup-*.log" | 
                Sort-Object CreationTime -Descending | 
                Select-Object -Skip $maxLogFiles | 
                Remove-Item -Force

            # Initialize log file with header
            $headerText = @"
Devcontainer Toolbox Setup Log
Version: $($script:CONFIG.Version)
Date: $(Get-Date)
System: $([System.Environment]::OSVersion.VersionString)
PowerShell: $($PSVersionTable.PSVersion)
User: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
-------------------------------------------

"@
            [IO.File]::WriteAllText($script:CONFIG.Logging.Path, $headerText)

            Write-Host "Logging initialized. Log file: $($script:CONFIG.Logging.Path)" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Warning "Failed to initialize logging: $_"
        $script:CONFIG.Logging.Enabled = $false
        return $false
    }
}

function Write-Log {
    <#
    .SYNOPSIS
    Writes a log message with timestamp and color coding.

    .PARAMETER Message
    The message to log.

    .PARAMETER Level
    The log level (Info, Warn, Error, Debug).

    .PARAMETER NoConsole
    If set, suppresses console output.

    .EXAMPLE
    Write-Log -Message "Starting installation" -Level Info
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warn", "Error", "Debug")]
        [string]$Level = "Info",
        
        [Parameter(Mandatory = $false)]
        [switch]$NoConsole
    )
    
    try {
        # Create thread-safe logging using mutex
        $mutexName = "Global\DevcontainerToolboxLog"
        $mutex = New-Object System.Threading.Mutex($false, $mutexName)

        try {
            [void]$mutex.WaitOne()
            
            $timestamp = Get-Date -Format $script:CONFIG.Logging.TimestampFormat
            $logMessage = "[$timestamp] $Level`: $Message"

            if ($script:CONFIG.Logging.Enabled -and $script:CONFIG.Logging.Path) {
                Add-Content -Path $script:CONFIG.Logging.Path -Value $logMessage
            }

            if (-not $NoConsole) {
                $color = switch ($Level) {
                    "Error" { "Red" }
                    "Warn"  { "Yellow" }
                    "Debug" { "Gray" }
                    default { "Green" }
                }
                Write-Host $logMessage -ForegroundColor $color
            }
        }
        finally {
            $mutex.ReleaseMutex()
        }
    }
    catch {
        Write-Warning "Logging failed: $_"
    }
}

function Show-Progress {
    <#
    .SYNOPSIS
    Updates and displays installation progress with time estimation.

    .PARAMETER Status
    Current status message to display.

    .PARAMETER CurrentOperation
    Optional current operation details.

    .EXAMPLE
    Show-Progress -Status "Installing WSL" -CurrentOperation "Downloading components"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Status,
        
        [Parameter(Mandatory = $false)]
        [string]$CurrentOperation
    )
    
    try {
        # Initialize start time if not set
        if (-not $script:CONFIG.Progress.StartTime) {
            $script:CONFIG.Progress.StartTime = Get-Date
        }

        # Update progress counter
        $script:CONFIG.Progress.Current++
        $percentage = [math]::Round(($script:CONFIG.Progress.Current / $script:CONFIG.Progress.Total) * 100)
        
        # Calculate time estimates
        $elapsed = (Get-Date) - $script:CONFIG.Progress.StartTime
        if ($script:CONFIG.Progress.Current -gt 0) {
            $estimatedTotal = $elapsed.TotalSeconds / ($script:CONFIG.Progress.Current / $script:CONFIG.Progress.Total)
            $remaining = $estimatedTotal - $elapsed.TotalSeconds
            
            $timeRemaining = if ($remaining -gt 0) {
                "Estimated time remaining: $([math]::Round($remaining/60,1)) minutes"
            }
            else {
                "Completing..."
            }
        }
        else {
            $timeRemaining = "Calculating..."
        }
        
        # Display progress
        Write-Progress -Activity "Setting up Devcontainer Toolbox" `
                      -Status $Status `
                      -PercentComplete $percentage `
                      -CurrentOperation $timeRemaining
        
        # Log progress
        Write-Log -Message $Status
        if ($CurrentOperation) {
            Write-Log -Message $CurrentOperation -Level Debug -NoConsole
        }
    }
    catch {
        Write-Warning "Failed to update progress: $_"
    }
}

function Show-Welcome {
    <#
    .SYNOPSIS
    Displays the welcome message and initial setup information.

    .EXAMPLE
    Show-Welcome
    #>
    [CmdletBinding()]
    param()

    try {
        Clear-Host
        Write-Host "====================================================" -ForegroundColor Cyan
        Write-Host "     Devcontainer Toolbox Environment Setup v$($script:CONFIG.Version)" -ForegroundColor Cyan
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
        $null = Read-Host
    }
    catch {
        Write-Log -Message "Failed to display welcome message: $_" -Level Error
        throw
    }
}

function Write-ErrorReport {
    <#
    .SYNOPSIS
    Reports installation errors and logs detailed information.

    .PARAMETER ErrorRecord
    The PowerShell error record to process.

    .EXAMPLE
    try { ... } catch { Write-ErrorReport -ErrorRecord $_ }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    
    try {
        Write-Progress -Activity "Setting up Devcontainer Toolbox" -Completed
        
        # Extract error details
        $errorType = $ErrorRecord.Exception.GetType().Name
        $errorMessage = $ErrorRecord.Exception.Message
        $errorLine = $ErrorRecord.InvocationInfo.ScriptLineNumber
        $errorScript = $ErrorRecord.InvocationInfo.ScriptName ?? "Unknown"
        $errorPosition = $ErrorRecord.InvocationInfo.PositionMessage
        
        # Log error details
        Write-Log -Message "An error occurred during setup" -Level Error
        Write-Log -Message "Error Type: $errorType" -Level Error
        Write-Log -Message "Error Message: $errorMessage" -Level Error
        Write-Log -Message "Script: $errorScript" -Level Debug
        Write-Log -Message "Line Number: $errorLine" -Level Debug
        Write-Log -Message "Position: $errorPosition" -Level Debug
        
        # Display user-friendly message
        Write-Host "`nError Details:" -ForegroundColor Red
        Write-Host "Type: $errorType" -ForegroundColor Red
        Write-Host "Message: $errorMessage" -ForegroundColor Red
        Write-Host "`nFor support, please report this issue at: https://github.com/terchris/devcontainer-toolbox/issues"
        Write-Host "Include the error message and script version ($($script:CONFIG.Version)) in your report."
        
        if ($script:CONFIG.Logging.Enabled) {
            Write-Host "`nFull error details have been logged to: $($script:CONFIG.Logging.Path)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Warning "Failed to process error report: $_"
        Write-Host $ErrorRecord.Exception.Message -ForegroundColor Red
    }
}

Export-ModuleMember -Function @(
    'Initialize-Logging',
    'Write-Log',
    'Show-Progress',
    'Show-Welcome',
    'Write-ErrorReport'
)