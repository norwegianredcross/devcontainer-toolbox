<#
.SYNOPSIS
Enhanced system requirements validation and WSL setup functionality.

.DESCRIPTION
Provides comprehensive system validation and Windows Subsystem for Linux management
with improved error handling and detailed progress tracking.

.NOTES
Version: 1.1.0
Author: Terje Christensen
#>

function Test-SystemRequirements {
    <#
    .SYNOPSIS
    Validates system requirements with detailed checking.

    .EXAMPLE
    Test-SystemRequirements
    #>
    [CmdletBinding()]
    param()

    try {
        Show-Progress -Status "Checking system requirements..."

        # Windows version check
        $windowsVersion = [System.Environment]::OSVersion.Version
        $minVersion = [Version]$script:CONFIG.Requirements.MinWindowsVersion
        
        if ($windowsVersion -lt $minVersion) {
            throw "Windows version $windowsVersion is not supported.`nMinimum required: $minVersion"
        }
        Write-Log -Message "Windows version check passed: $windowsVersion"

        # CPU Architecture and Virtualization
        try {
            $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop | 
                   Select-Object -First 1
            
            if (-not $cpu) {
                throw "Unable to retrieve processor information"
            }

            if ($cpu.AddressWidth -ne 64) {
                throw "64-bit processor required. Found: $($cpu.AddressWidth)-bit"
            }
            Write-Log -Message "CPU architecture check passed: $($cpu.AddressWidth)-bit"
        }
        catch {
            throw "Failed to verify CPU architecture: $_"
        }

        # Virtualization check
        try {
            $virtualizationEnabled = $false
            $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
            
            if ($computerSystem.HypervisorPresent) {
                $virtualizationEnabled = $true
            }
            else {
                # Check BIOS settings if hypervisor is not present
                $biosSettings = Get-CimInstance -ClassName Win32_BIOS -ErrorAction Stop
                $systemInfo = systeminfo.exe | Select-String "Virtualization Enabled In Firmware"
                if ($systemInfo -match "Yes") {
                    $virtualizationEnabled = $true
                }
            }

            if (-not $virtualizationEnabled) {
                Write-Log -Message "Hardware virtualization is not enabled in BIOS/UEFI" -Level Warn
                Write-Log -Message "Please enable virtualization in your system BIOS/UEFI settings" -Level Warn
            }
            else {
                Write-Log -Message "Virtualization check passed"
            }
        }
        catch {
            Write-Log -Message "Unable to verify virtualization status: $_" -Level Warn
        }

        # Memory check
        try {
            $systemMemory = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
            $totalMemoryGB = [math]::Round($systemMemory.TotalPhysicalMemory/1GB, 2)
            $minMemoryGB = $script:CONFIG.Requirements.MinMemoryGB
            
            if ($totalMemoryGB -lt $minMemoryGB) {
                throw "Insufficient memory. Required: ${minMemoryGB}GB, Available: ${totalMemoryGB}GB"
            }
            Write-Log -Message "Memory check passed: ${totalMemoryGB}GB available"
        }
        catch {
            throw "Failed to verify system memory: $_"
        }

        # Disk space check
        try {
            $systemDrive = Get-PSDrive -Name $env:SystemDrive[0] -ErrorAction Stop
            $freeSpaceGB = [math]::Round($systemDrive.Free/1GB, 2)
            $minSpaceGB = $script:CONFIG.Requirements.MinDiskSpaceGB
            
            if ($freeSpaceGB -lt $minSpaceGB) {
                throw "Insufficient disk space on $($systemDrive.Name). Required: ${minSpaceGB}GB, Available: ${freeSpaceGB}GB"
            }
            Write-Log -Message "Disk space check passed: ${freeSpaceGB}GB available"
        }
        catch {
            throw "Failed to verify disk space: $_"
        }

        # Windows features check
        try {
            $requiredFeatures = @(
                @{
                    Name = "Microsoft-Windows-Subsystem-Linux"
                    DisplayName = "Windows Subsystem for Linux"
                },
                @{
                    Name = "VirtualMachinePlatform"
                    DisplayName = "Virtual Machine Platform"
                }
            )

            foreach ($feature in $requiredFeatures) {
                $featureState = Get-WindowsOptionalFeature -Online -FeatureName $feature.Name -ErrorAction Stop
                if (-not $featureState -or $featureState.State -ne "Enabled") {
                    Write-Log -Message "Windows feature '$($feature.DisplayName)' is not enabled" -Level Warn
                }
                else {
                    Write-Log -Message "Windows feature '$($feature.DisplayName)' is enabled"
                }
            }
        }
        catch {
            Write-Log -Message "Failed to verify Windows features: $_" -Level Warn
        }

        return $true
    }
    catch {
        Write-Log -Message $_.Exception.Message -Level Error
        throw
    }
}

function Test-WSL {
    <#
    .SYNOPSIS
    Enhanced WSL validation with version checking.

    .EXAMPLE
    if (Test-WSL) { Write-Host "WSL is properly configured" }
    #>
    [CmdletBinding()]
    param()

    try {
        Write-Log -Message "Checking WSL status..."
        
        # Check if WSL command exists
        if (-not (Test-Command -Command "wsl")) {
            Write-Log -Message "WSL command not found" -Level Debug
            return $false
        }

        # Get WSL status and version
        $wslOutput = wsl --status 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Log -Message "WSL status check failed" -Level Debug
            return $false
        }

        # Parse WSL version
        $wslVersion = if ($wslOutput -match "Default Version: (\d+)") {
            [int]$matches[1]
        }
        else {
            0
        }

        if ($wslVersion -lt 2) {
            Write-Log -Message "WSL version $wslVersion detected, version 2 required" -Level Debug
            return $false
        }

        # Check kernel version
        try {
            $kernelVersion = wsl --exec uname -r 2>$null
            if ($kernelVersion) {
                Write-Log -Message "WSL kernel version: $kernelVersion"
            }
            else {
                Write-Log -Message "Could not determine WSL kernel version" -Level Warn
                return $false
            }
        }
        catch {
            Write-Log -Message "Failed to check WSL kernel version: $_" -Level Debug
            return $false
        }

        Write-Log -Message "WSL 2 is installed and configured correctly"
        return $true
    }
    catch {
        Write-Log -Message "Error checking WSL: $_" -Level Debug
        return $false
    }
}

function Install-WSLComponent {
    <#
    .SYNOPSIS
    Installs a specific WSL component with error handling.

    .PARAMETER ComponentName
    The name of the component to install.

    .PARAMETER DisplayName
    The display name of the component.

    .EXAMPLE
    Install-WSLComponent -ComponentName "Microsoft-Windows-Subsystem-Linux" -DisplayName "WSL"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComponentName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName
    )

    try {
        Write-Log -Message "Installing $DisplayName..."
        $feature = Get-WindowsOptionalFeature -Online -FeatureName $ComponentName -ErrorAction Stop

        if ($feature.State -ne "Enabled") {
            $result = Enable-WindowsOptionalFeature -Online -FeatureName $ComponentName -NoRestart -ErrorAction Stop
            
            if ($result.RestartNeeded) {
                $script:CONFIG.RestartNeeded = $true
                Write-Log -Message "System restart required after enabling $DisplayName" -Level Warn
            }
            
            Write-Log -Message "$DisplayName installation completed"
            return $true
        }
        else {
            Write-Log -Message "$DisplayName is already installed"
            return $true
        }
    }
    catch {
        Write-Log -Message "Failed to install $DisplayName`: $_" -Level Error
        throw
    }
}

function Install-WSLIfNeeded {
    <#
    .SYNOPSIS
    Manages WSL installation and configuration.

    .EXAMPLE
    Install-WSLIfNeeded
    #>
    [CmdletBinding()]
    param()

    if (Test-WSL) {
        Write-Log -Message "WSL is already properly configured"
        return $true
    }

    Show-Progress -Status "Installing WSL..."
    
    try {
        # Install required Windows features
        $components = @(
            @{
                Name = "Microsoft-Windows-Subsystem-Linux"
                DisplayName = "Windows Subsystem for Linux"
            },
            @{
                Name = "VirtualMachinePlatform"
                DisplayName = "Virtual Machine Platform"
            }
        )

        foreach ($component in $components) {
            Install-WSLComponent -ComponentName $component.Name -DisplayName $component.DisplayName
        }

        # Install WSL
        Write-Log -Message "Installing WSL core components..."
        $result = wsl --install --no-distribution 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "WSL installation failed: $result"
        }

        # Update WSL kernel
        Write-Log -Message "Updating WSL kernel..."
        wsl --update
        if ($LASTEXITCODE -ne 0) {
            Write-Log -Message "WSL kernel update warning - may need manual update" -Level Warn
        }

        # Set WSL default version
        Write-Log -Message "Setting WSL default version to 2..."
        wsl --set-default-version 2
        if ($LASTEXITCODE -ne 0) {
            Write-Log -Message "Failed to set WSL default version" -Level Warn
        }

        # Register cleanup/rollback
        Register-InstallationStep -StepName "WSL Installation" -RollbackAction {
            Write-Log -Message "Rolling back WSL installation..." -Level Warn
            foreach ($component in $components) {
                try {
                    Disable-WindowsOptionalFeature -Online -FeatureName $component.Name -NoRestart
                }
                catch {
                    Write-Log -Message "Failed to rollback $($component.DisplayName)" -Level Error
                }
            }
        }

        if ($script:CONFIG.RestartNeeded) {
            Write-Host "`nSystem restart required to complete WSL installation."
            $restart = Read-Host "Would you like to restart now? (Y/N)"
            if ($restart -eq 'Y' -or $restart -eq 'y') {
                Restart-Computer -Force
            }
            else {
                Write-Log -Message "Please restart your computer to complete the installation" -Level Warn
            }
            return $false
        }

        # Verify installation
        if (-not (Test-WSL)) {
            throw "WSL installation completed but verification failed"
        }

        Write-Log -Message "WSL installation completed successfully"
        return $true
    }
    catch {
        Write-Log -Message "Failed to install WSL: $_" -Level Error
        throw
    }
}

Export-ModuleMember -Function @(
    'Test-SystemRequirements',
    'Test-WSL',
    'Install-WSLIfNeeded'
)