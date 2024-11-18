<#
.SYNOPSIS
Core testing and validation functions for the Devcontainer Toolbox installation.

.DESCRIPTION
Provides comprehensive validation and testing functionality with improved error handling
and detailed system checks.

.NOTES
Version: 1.1.0
Author: Terje Christensen
#>

function Test-Command {
    <#
    .SYNOPSIS
    Tests if a command exists with enhanced validation.

    .PARAMETER Command
    The name of the command to test.

    .PARAMETER MinimumVersion
    Optional minimum version requirement.

    .EXAMPLE
    Test-Command -Command "docker" -MinimumVersion "20.10.0"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Command,
        
        [Parameter(Mandatory = $false)]
        [ValidatePattern('^\d+\.\d+(\.\d+)?$')]
        [string]$MinimumVersion
    )

    try {
        $cmdInfo = Get-Command -Name $Command -ErrorAction Stop
        if ($MinimumVersion -and $cmdInfo.Version) {
            if ($cmdInfo.Version -lt [Version]$MinimumVersion) {
                Write-Log -Message "$Command version $($cmdInfo.Version) is below minimum required version $MinimumVersion" -Level Warn
                return $false
            }
        }
        return $true
    }
    catch {
        Write-Log -Message "Command '$Command' not found" -Level Debug
        return $false
    }
}

function Test-AdminPrivileges {
    <#
    .SYNOPSIS
    Verifies administrative privileges with detailed feedback.

    .EXAMPLE
    Test-AdminPrivileges
    #>
    [CmdletBinding()]
    param()

    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal $identity
        $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        if (-not $isAdmin) {
            $currentUser = $identity.Name
            $elevationScript = @"
Start-Process powershell -Verb RunAs -ArgumentList "-File `"$($MyInvocation.PSCommandPath)`""
"@
            
            Write-Log -Message "Script requires administrative privileges." -Level Error
            Write-Log -Message "Current user: $currentUser" -Level Error
            Write-Log -Message "Please run the script as administrator or use the following command:" -Level Error
            Write-Log -Message $elevationScript -Level Error
            
            throw "Administrative privileges required"
        }
        return $true
    }
    catch {
        throw "Failed to verify administrative privileges: $_"
    }
}

function Test-ExecutionPolicy {
    <#
    .SYNOPSIS
    Validates PowerShell execution policy.

    .EXAMPLE
    Test-ExecutionPolicy
    #>
    [CmdletBinding()]
    param()

    try {
        $policy = Get-ExecutionPolicy
        
        if ($policy -eq "Restricted") {
            $msg = @"
PowerShell execution policy is set to Restricted.
To change the execution policy, run the following command as administrator:
Set-ExecutionPolicy RemoteSigned -Force
"@
            throw $msg
        }
        
        if ($policy -eq "AllSigned") {
            Write-Log -Message "Execution policy is set to AllSigned. Script must be signed." -Level Warn
        }
        
        Write-Log -Message "Execution policy check passed: $policy" -Level Debug
        return $true
    }
    catch {
        throw "Failed to verify execution policy: $_"
    }
}

function Test-InternetConnection {
    <#
    .SYNOPSIS
    Verifies network connectivity to required resources.

    .EXAMPLE
    Test-InternetConnection
    #>
    [CmdletBinding()]
    param()

    $endpoints = @(
        @{
            Host = "github.com"
            Port = 443
            Description = "GitHub (required for repository access)"
            Timeout = 10000  # milliseconds
        },
        @{
            Host = "raw.githubusercontent.com"
            Port = 443
            Description = "GitHub Raw Content (required for script downloads)"
            Timeout = 10000
        }
    )
    
    foreach ($endpoint in $endpoints) {
        try {
            Write-Log -Message "Testing connection to $($endpoint.Description)..."
            
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $connection = $tcpClient.BeginConnect($endpoint.Host, $endpoint.Port, $null, $null)
            $wait = $connection.AsyncWaitHandle.WaitOne($endpoint.Timeout)
            
            if (-not $wait) {
                throw "Connection timed out"
            }
            
            try {
                $tcpClient.EndConnect($connection)
            }
            catch {
                throw "Connection failed"
            }
            finally {
                $tcpClient.Close()
            }

            # Test HTTPS certificate
            try {
                $req = [System.Net.HttpWebRequest]::Create("https://$($endpoint.Host)")
                $req.Timeout = $endpoint.Timeout
                $req.GetResponse().Dispose()
            }
            catch {
                Write-Log -Message "SSL/TLS certificate validation failed for $($endpoint.Host)" -Level Warn
            }
            
            Write-Log -Message "Successfully connected to $($endpoint.Description)"
        }
        catch {
            throw "Failed to connect to $($endpoint.Description): $_"
        }
    }
    return $true
}

function Test-Prerequisites {
    <#
    .SYNOPSIS
    Validates all prerequisites before installation.

    .EXAMPLE
    Test-Prerequisites
    #>
    [CmdletBinding()]
    param()

    Write-Log -Message "Validating prerequisites..."
    
    $validations = @(
        @{
            Name = "Administrative Privileges"
            Test = { Test-AdminPrivileges }
        },
        @{
            Name = "Execution Policy"
            Test = { Test-ExecutionPolicy }
        },
        @{
            Name = "Internet Connectivity"
            Test = { Test-InternetConnection }
        },
        @{
            Name = "System Requirements"
            Test = { Test-SystemRequirements }
        },
        @{
            Name = "PowerShell Version"
            Test = { 
                if ($PSVersionTable.PSVersion.Major -lt 5) {
                    throw "PowerShell 5 or higher is required"
                }
                $true 
            }
        }
    )
    
    foreach ($validation in $validations) {
        try {
            Write-Log -Message "Checking $($validation.Name)..."
            $result = & $validation.Test
            if ($result) {
                Write-Log -Message "$($validation.Name) validation passed" -Level Debug
            }
        }
        catch {
            Write-Log -Message "$($validation.Name) validation failed: $_" -Level Error
            throw $_
        }
    }
}

function Test-Installation {
    <#
    .SYNOPSIS
    Verifies the complete installation.

    .EXAMPLE
    Test-Installation
    #>
    [CmdletBinding()]
    param()

    Write-Log -Message "Verifying installation..."
    
    $checks = @(
        @{
            Name = "Project Directory"
            Test = { Test-Path $script:CONFIG.ToolboxDir }
            Message = "Project directory not found"
        },
        @{
            Name = "Git Repository"
            Test = { 
                Test-Path (Join-Path $script:CONFIG.ToolboxDir ".git")
            }
            Message = "Git repository not properly initialized"
        },
        @{
            Name = "VS Code"
            Test = { Test-Command -Command "code" }
            Message = "VS Code not found in PATH"
        },
        @{
            Name = "Container Runtime"
            Test = { 
                if ($script:CONFIG.UseDocker) {
                    Test-Command -Command "docker"
                }
                else {
                    Test-Command -Command "podman"
                }
            }
            Message = "Container runtime not properly installed"
        }
    )
    
    $failed = @()
    foreach ($check in $checks) {
        try {
            Write-Log -Message "Verifying $($check.Name)..."
            if (-not (& $check.Test)) {
                $failed += "$($check.Name): $($check.Message)"
            }
        }
        catch {
            $failed += "$($check.Name): $_"
        }
    }
    
    if ($failed.Count -gt 0) {
        throw "Installation verification failed:`n" + ($failed -join "`n")
    }
    
    Write-Log -Message "Installation verified successfully"
    return $true
}

function Test-SetupPrerequisites {
    [CmdletBinding()]
    param()
    
    try {
        # Validate PowerShell version
        $minPowerShellVersion = [Version]"5.1"
        if ($PSVersionTable.PSVersion -lt $minPowerShellVersion) {
            throw "PowerShell version $($PSVersionTable.PSVersion) is not supported. Minimum required: $minPowerShellVersion"
        }

        # Validate setup directory structure
        $setupRoot = $PSScriptRoot
        $requiredFiles = @(
            "setup-windows.ps1",
            "setup-windows-1-tests.ps1",
            "setup-windows-2-logging.ps1",
            "setup-windows-3-system.ps1",
            "setup-windows-4-containers.ps1",
            "setup-windows-5-project.ps1"
        )

        foreach ($file in $requiredFiles) {
            $filePath = Join-Path $setupRoot $file
            if (-not (Test-Path $filePath)) {
                throw "Required setup file missing: $file"
            }
        }

        # Validate write permissions in setup directory
        $testFile = Join-Path $setupRoot "write_test.tmp"
        try {
            [IO.File]::WriteAllText($testFile, "test")
            Remove-Item -Path $testFile -Force
        }
        catch {
            throw "Insufficient permissions in setup directory: $_"
        }

        return $true
    }
    catch {
        Write-Log -Message "Setup prerequisites check failed: $_" -Level Error
        return $false
    }
}

Export-ModuleMember -Function @(
    'Test-Command',
    'Test-AdminPrivileges',
    'Test-ExecutionPolicy',
    'Test-InternetConnection',
    'Test-Prerequisites',
    'Test-Installation',
    'Test-SetupPrerequisites'
)