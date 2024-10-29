<#
.SYNOPSIS
Project directory and repository setup functionality.

.DESCRIPTION
Handles project directory setup, repository cloning, and basic VS Code configuration.

.NOTES
Version: 1.1.0
Author: Terje Christensen
#>

function Test-ProjectDirectory {
    <#
    .SYNOPSIS
    Validates and prepares the project directory.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    try {
        Write-Log -Message "Validating project directory: $Path"

        # Basic path validation
        if (-not [System.IO.Path]::IsPathRooted($Path)) {
            throw "Invalid path: Must be an absolute path"
        }

        # Create directory if needed
        if (-not (Test-Path $Path)) {
            New-Item -ItemType Directory -Path $Path -Force -ErrorAction Stop | Out-Null
            Write-Log -Message "Created directory: $Path"
        }

        # Test write permissions
        $testFile = Join-Path $Path "write_test.tmp"
        try {
            [IO.File]::WriteAllText($testFile, "test")
            Remove-Item -Path $testFile -Force
            Write-Log -Message "Write permission test passed"
        }
        catch {
            throw "Cannot write to directory: $_"
        }

        return $true
    }
    catch {
        Write-Log -Message "Project directory validation failed: $_" -Level Error
        throw
    }
}

function Initialize-ProjectEnvironment {
    <#
    .SYNOPSIS
    Sets up the project environment and repository.
    #>
    [CmdletBinding()]
    param()

    try {
        Show-Progress -Status "Initializing project environment..."

        # Get project directory
        $defaultDir = Join-Path $env:USERPROFILE "Projects"
        Write-Host "`nChoose project directory:"
        Write-Host "1. Use default ($defaultDir)"
        Write-Host "2. Specify custom path"
        
        $projectDir = if ((Read-Host "Enter choice (1-2)") -eq "1") {
            $defaultDir
        }
        else {
            Read-Host "Enter full path for project directory"
        }

        # Validate directory
        Test-ProjectDirectory -Path $projectDir

        # Setup toolbox directory
        $script:CONFIG.ToolboxDir = Join-Path $projectDir "devcontainer-toolbox"
        
        # Handle existing installation
        if (Test-Path $script:CONFIG.ToolboxDir) {
            if ((Read-Host "Directory exists. Replace? (Y/N)") -eq 'Y') {
                Remove-Item -Path $script:CONFIG.ToolboxDir -Recurse -Force
            }
            else {
                throw "Installation cancelled - directory exists"
            }
        }

        # Clone repository
        Write-Log -Message "Cloning repository..."
        $env:GIT_TERMINAL_PROMPT = "0"
        $cloneResult = git clone https://github.com/terchris/devcontainer-toolbox.git $script:CONFIG.ToolboxDir 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Git clone failed: $cloneResult"
        }

        # Setup VS Code
        Initialize-VSCodeSetup
        return $true
    }
    catch {
        Write-Log -Message "Failed to initialize project environment: $_" -Level Error
        throw
    }
}

function Initialize-VSCodeSetup {
    <#
    .SYNOPSIS
    Configures VS Code and installs required extensions.
    #>
    [CmdletBinding()]
    param()

    try {
        Show-Progress -Status "Setting up VS Code configuration..."

        # Check VS Code installation
        if (-not (Test-Command -Command "code")) {
            Write-Log -Message "VS Code not found. Please install from: https://code.visualstudio.com/" -Level Warn
            return
        }

        # Install required extensions
        $extensions = @(
            "ms-vscode-remote.remote-containers",
            "ms-vscode-remote.remote-wsl"
        )

        foreach ($extension in $extensions) {
            Write-Log -Message "Installing VS Code extension: $extension"
            code --install-extension $extension --force
        }

        # Create basic settings
        $settingsDir = Join-Path $script:CONFIG.ToolboxDir ".vscode"
        if (-not (Test-Path $settingsDir)) {
            New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
        }

        $settings = @{
            "remote.containers.defaultExtensions" = $extensions
        }

        $settings | ConvertTo-Json | Set-Content (Join-Path $settingsDir "settings.json")
        Write-Log -Message "VS Code configuration completed"
    }
    catch {
        Write-Log -Message "VS Code setup warning: $_" -Level Warn
    }
}

Export-ModuleMember -Function @(
    'Test-ProjectDirectory',
    'Initialize-ProjectEnvironment'
)