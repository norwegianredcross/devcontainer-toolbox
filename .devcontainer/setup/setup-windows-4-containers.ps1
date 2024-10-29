<#
.SYNOPSIS
Enhanced container runtime management functionality.

.DESCRIPTION
Provides comprehensive container runtime handling including Docker and Podman
management with improved detection, installation, and configuration.

.NOTES
Version: 1.1.0
Author: Terje Christensen
#>

function Test-Docker {
    <#
    .SYNOPSIS
    Enhanced Docker installation and functionality check.

    .EXAMPLE
    if (Test-Docker) { Write-Host "Docker is ready" }
    #>
    [CmdletBinding()]
    param()

    try {
        if (-not (Test-Command -Command "docker")) { 
            Write-Log -Message "Docker command not found" -Level Debug
            return $false 
        }
        
        # Create timeout token
        $timeoutSeconds = 10
        $cancelToken = New-Object System.Threading.CancellationTokenSource
        $cancelToken.CancelAfter([TimeSpan]::FromSeconds($timeoutSeconds))

        # Check Docker version
        try {
            $job = Start-Job -ScriptBlock { 
                docker version --format '{{.Client.Version}}' 2>&1 
            }
            
            $completed = Wait-Job -Job $job -Timeout $timeoutSeconds
            if (-not $completed) {
                $cancelToken.Cancel()
                throw "Docker version check timed out after $timeoutSeconds seconds"
            }

            $version = Receive-Job -Job $job -ErrorAction Stop
            if ($LASTEXITCODE -eq 0) {
                Write-Log -Message "Docker version $version found"
                
                # Test Docker daemon
                $daemonJob = Start-Job -ScriptBlock { docker info }
                $daemonCompleted = Wait-Job -Job $daemonJob -Timeout $timeoutSeconds
                
                if (-not $daemonCompleted) {
                    throw "Docker daemon check timed out"
                }

                $daemonInfo = Receive-Job -Job $daemonJob -ErrorAction Stop
                if ($LASTEXITCODE -eq 0) {
                    Write-Log -Message "Docker daemon is running and responsive"
                    return $true
                }
                Write-Log -Message "Docker daemon not responding" -Level Debug
            }
        }
        finally {
            $cancelToken.Dispose()
            Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue
        }
        return $false
    }
    catch {
        Write-Log -Message "Error checking Docker: $_" -Level Debug
        return $false
    }
}

function Test-Podman {
    <#
    .SYNOPSIS
    Enhanced Podman installation and functionality check.

    .EXAMPLE
    if (Test-Podman) { Write-Host "Podman is ready" }
    #>
    [CmdletBinding()]
    param()

    try {
        if (-not (Test-Command -Command "podman")) { 
            Write-Log -Message "Podman command not found" -Level Debug
            return $false 
        }
        
        # Create timeout token
        $timeoutSeconds = 10
        $cancelToken = New-Object System.Threading.CancellationTokenSource
        $cancelToken.CancelAfter([TimeSpan]::FromSeconds($timeoutSeconds))

        try {
            # Check Podman version with timeout
            $job = Start-Job -ScriptBlock { 
                podman version --format '{{.Client.Version}}' 2>&1 
            }
            
            if (-not (Wait-Job $job -Timeout $timeoutSeconds)) {
                Stop-Job $job
                throw "Podman version check timed out after $timeoutSeconds seconds"
            }

            $version = Receive-Job $job -ErrorAction Stop
            if ($LASTEXITCODE -eq 0) {
                Write-Log -Message "Podman version $version found"
                
                # Test Podman machine with timeout
                $machineJob = Start-Job -ScriptBlock { podman machine inspect }
                if (-not (Wait-Job $machineJob -Timeout $timeoutSeconds)) {
                    Stop-Job $machineJob
                    throw "Podman machine check timed out"
                }

                $machineInfo = Receive-Job $machineJob -ErrorAction Stop
                if ($LASTEXITCODE -eq 0) {
                    Write-Log -Message "Podman machine is configured"
                    return $true
                }
                Write-Log -Message "Podman machine not properly configured" -Level Debug
            }
        }
        finally {
            $cancelToken.Dispose()
            Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue
        }
        return $false
    }
    catch {
        Write-Log -Message "Error checking Podman: $_" -Level Debug
        return $false
    }
}

function Install-ContainerRuntime {
    <#
    .SYNOPSIS
    Manages container runtime installation and configuration.

    .EXAMPLE
    Install-ContainerRuntime
    #>
    [CmdletBinding()]
    param()

    Show-Progress -Status "Setting up container runtime..."
    
    try {
        # Check existing installations
        $hasDocker = Test-Docker
        $hasPodman = Test-Podman
        
        if ($hasDocker -or $hasPodman) {
            Write-Host "`nExisting container runtime(s) detected:"
            if ($hasDocker) { Write-Host "- Docker Desktop" }
            if ($hasPodman) { Write-Host "- Podman Desktop" }
            
            Write-Host "`nChoose your container runtime:"
            if ($hasDocker) { Write-Host "1. Use existing Docker installation" }
            Write-Host "$($hasDocker ? '2' : '1'). $(if ($hasPodman) { 'Use existing' } else { 'Install' }) Podman (recommended)"
            if ($hasDocker) { Write-Host "3. Exit to uninstall Docker first" }
            
            $maxChoice = if ($hasDocker) { 3 } else { 1 }
            do {
                $choice = Read-Host "Enter choice (1-$maxChoice)"
            } until ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $maxChoice)
            
            switch ($choice) {
                "1" {
                    if ($hasDocker) {
                        $script:CONFIG.UseDocker = $true
                        Write-Log -Message "Using existing Docker installation"
                        return $true
                    }
                    # Fall through to Podman installation
                }
                "2" {
                    if ($hasDocker) {
                        if ($hasPodman) {
                            Write-Log -Message "Using existing Podman installation"
                            return $true
                        }
                        Write-Log -Message "Will install Podman alongside Docker" -Level Warn
                    }
                }
                "3" {
                    Write-Host "Please uninstall Docker Desktop and restart your computer before running this script again."
                    return $false
                }
            }
        }
        
        # Install Podman if not already installed
        if (-not $hasPodman) {
            return Install-Podman
        }
        
        return $true
    }
    catch {
        Write-Log -Message "Failed to configure container runtime: $_" -Level Error
        throw
    }
}

function Install-Podman {
    <#
    .SYNOPSIS
    Handles Podman installation and configuration.

    .EXAMPLE
    Install-Podman
    #>
    [CmdletBinding()]
    param()

    Show-Progress -Status "Installing Podman..."
    
    try {
        # Check winget availability
        if (-not (Test-Command -Command "winget")) {
            throw "Winget is required for Podman installation. Please install App Installer from the Microsoft Store."
        }

        # Check and install VCLibs dependency
        $vcLibs = Get-AppxPackage -Name "Microsoft.VCLibs.140.00.UWPDesktop" -ErrorAction SilentlyContinue
        if (-not $vcLibs) {
            Write-Log -Message "Installing VCLibs dependency..."
            try {
                $vcLibsUrl = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
                $vcLibsPath = Join-Path $env:TEMP "Microsoft.VCLibs.x64.14.00.Desktop.appx"
                
                $webClient = New-Object System.Net.WebClient
                $webClient.DownloadFile($vcLibsUrl, $vcLibsPath)
                
                Add-AppxPackage -Path $vcLibsPath -ErrorAction Stop
                Remove-Item $vcLibsPath -Force
            }
            catch {
                throw "Failed to install VCLibs dependency: $_"
            }
        }

        # Install Podman
        Write-Log -Message "Installing Podman via winget..."
        $process = Start-Process -FilePath "winget" -ArgumentList "install", "-e", "--id", "RedHat.Podman-Desktop" `
                                -NoNewWindow -Wait -PassThru
        
        if ($process.ExitCode -ne 0) {
            throw "Podman installation failed with exit code: $($process.ExitCode)"
        }

        # Register cleanup/rollback
        Register-InstallationStep -StepName "Podman Installation" -RollbackAction {
            Write-Log -Message "Rolling back Podman installation..." -Level Warn
            Start-Process -FilePath "winget" -ArgumentList "uninstall", "-e", "--id", "RedHat.Podman-Desktop" `
                         -NoNewWindow -Wait
        }

        # Verify installation with retry
        $retryCount = 0
        $maxRetries = 3
        $installed = $false
        
        do {
            Start-Sleep -Seconds 2
            $installed = Test-Podman
            $retryCount++
        } until ($installed -or $retryCount -ge $maxRetries)

        if (-not $installed) {
            throw "Podman installation completed but verification failed"
        }

        # Configure Podman
        Write-Log -Message "Configuring Podman..."
        
        # Reset Podman configuration
        $resetProcess = Start-Process -FilePath "podman" -ArgumentList "system", "reset", "--force" `
                                    -NoNewWindow -Wait -PassThru
        if ($resetProcess.ExitCode -ne 0) {
            Write-Log -Message "Warning: Podman system reset failed" -Level Warn
        }

        # Initialize Podman machine
        $initProcess = Start-Process -FilePath "podman" -ArgumentList "machine", "init", "--cpus", "2", "--memory", "2048" `
                                   -NoNewWindow -Wait -PassThru
        if ($initProcess.ExitCode -ne 0) {
            Write-Log -Message "Warning: Podman machine initialization failed" -Level Warn
        }

        # Start Podman machine
        $startProcess = Start-Process -FilePath "podman" -ArgumentList "machine", "start" `
                                    -NoNewWindow -Wait -PassThru
        if ($startProcess.ExitCode -ne 0) {
            Write-Log -Message "Warning: Podman machine start failed" -Level Warn
        }

        Write-Log -Message "Podman installation and configuration completed"
        return $true
    }
    catch {
        Write-Log -Message "Failed to install Podman: $_" -Level Error
        throw
    }
}

Export-ModuleMember -Function @(
    'Test-Docker',
    'Test-Podman',
    'Install-ContainerRuntime',
    'Install-Podman'
)