#Requires -Version 5.1
<#
.SYNOPSIS
    Installation script for LLM Environment Manager PowerShell edition
.DESCRIPTION
    Installs the LLM Environment Manager PowerShell module with automatic
    detection of PowerShell version and platform-specific installation paths
.PARAMETER InstallPath
    Custom installation path (optional)
.PARAMETER Force
    Force installation even if module already exists
.PARAMETER SkipProfileUpdate
    Skip updating PowerShell profile
.PARAMETER Uninstall
    Uninstall the module instead of installing
.EXAMPLE
    Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/samestrin/llm-env/main/install.ps1" -UseBasicParsing).Content
.EXAMPLE
    .\install.ps1 -Force
.EXAMPLE  
    .\install.ps1 -Uninstall
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$InstallPath,
    
    [Parameter()]
    [switch]$Force,
    
    [Parameter()]
    [switch]$SkipProfileUpdate,
    
    [Parameter()]
    [switch]$Uninstall
)

# Set strict mode for better error handling
Set-StrictMode -Version Latest

# Installation constants
$ModuleName = "llm-env"
$ModuleVersion = "1.1.0"
$RepositoryUrl = "https://github.com/samestrin/llm-env"
$BranchName = "feature/powershell-port"  # Will be 'main' after merge

# Colors for output
$Colors = @{
    Success = 'Green'
    Warning = 'Yellow'
    Error = 'Red'
    Info = 'Cyan'
    Header = 'Magenta'
}

function Write-InstallMessage {
    param(
        [string]$Message,
        [string]$Type = 'Info'
    )
    
    $color = $Colors[$Type]
    Write-Host $Message -ForegroundColor $color
}

function Write-InstallHeader {
    param([string]$Title)
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor $Colors.Header
    Write-Host " $Title" -ForegroundColor $Colors.Header
    Write-Host "═══════════════════════════════════════" -ForegroundColor $Colors.Header
    Write-Host ""
}

function Get-PowerShellInfo {
    $psVersion = $PSVersionTable.PSVersion
    $psEdition = $PSVersionTable.PSEdition
    $platform = if ($PSVersionTable.Platform) { $PSVersionTable.Platform } else { "Win32NT" }
    
    return @{
        Version = $psVersion
        Edition = $psEdition
        Platform = $platform
        IsWindows = ($platform -eq "Win32NT") -or ($IsWindows -eq $true) -or (-not $PSVersionTable.Platform)
        IsMacOS = ($platform -eq "Darwin") -or ($IsMacOS -eq $true)
        IsLinux = ($platform -eq "Linux") -or ($IsLinux -eq $true)
    }
}

function Get-ModuleInstallPath {
    param([hashtable]$PSInfo)
    
    if ($InstallPath) {
        return $InstallPath
    }
    
    # Determine appropriate module path based on PowerShell version and platform
    if ($PSInfo.IsWindows) {
        if ($PSInfo.Edition -eq "Desktop") {
            # PowerShell 5.1 (Windows PowerShell)
            return Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Modules\$ModuleName"
        } else {
            # PowerShell 7+ (PowerShell Core)
            return Join-Path $env:USERPROFILE "Documents\PowerShell\Modules\$ModuleName"
        }
    } elseif ($PSInfo.IsMacOS) {
        return Join-Path $env:HOME ".local/share/powershell/Modules/$ModuleName"
    } else {
        # Linux
        return Join-Path $env:HOME ".local/share/powershell/Modules/$ModuleName"
    }
}

function Get-PowerShellProfilePath {
    param([hashtable]$PSInfo)
    
    if ($PSInfo.IsWindows) {
        if ($PSInfo.Edition -eq "Desktop") {
            return Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
        } else {
            return Join-Path $env:USERPROFILE "Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
        }
    } else {
        return $PROFILE
    }
}

function Test-Prerequisites {
    param([hashtable]$PSInfo)
    
    Write-InstallMessage "Checking prerequisites..." -Type Info
    
    # Check PowerShell version
    if ($PSInfo.Version -lt [version]"5.1") {
        Write-InstallMessage "ERROR: PowerShell 5.1 or higher is required. Current version: $($PSInfo.Version)" -Type Error
        return $false
    }
    
    Write-InstallMessage "✓ PowerShell version: $($PSInfo.Version) ($($PSInfo.Edition))" -Type Success
    
    # Check platform
    $platformName = if ($PSInfo.IsWindows) { "Windows" } elseif ($PSInfo.IsMacOS) { "macOS" } else { "Linux" }
    Write-InstallMessage "✓ Platform: $platformName" -Type Success
    
    # Check execution policy (Windows only)
    if ($PSInfo.IsWindows) {
        $executionPolicy = Get-ExecutionPolicy -Scope CurrentUser
        if ($executionPolicy -eq "Restricted") {
            Write-InstallMessage "WARNING: Execution policy is Restricted. You may need to change it." -Type Warning
            Write-InstallMessage "Run: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -Type Info
        } else {
            Write-InstallMessage "✓ Execution policy: $executionPolicy" -Type Success
        }
    }
    
    # Check internet connectivity
    try {
        $null = Invoke-WebRequest -Uri "https://github.com" -Method Head -TimeoutSec 10 -UseBasicParsing
        Write-InstallMessage "✓ Internet connectivity" -Type Success
    } catch {
        Write-InstallMessage "WARNING: Limited internet connectivity. Installation may fail." -Type Warning
    }
    
    return $true
}

function Get-GitHubContent {
    param(
        [string]$Path,
        [string]$Branch = $BranchName
    )
    
    $url = "$RepositoryUrl/raw/$Branch/$Path"
    
    try {
        Write-InstallMessage "Downloading: $Path" -Type Info
        $content = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30
        return $content.Content
    } catch {
        Write-InstallMessage "Failed to download $Path`: $_" -Type Error
        throw
    }
}

function Install-LLMEnvironmentModule {
    param(
        [string]$ModulePath,
        [hashtable]$PSInfo
    )
    
    Write-InstallMessage "Installing to: $ModulePath" -Type Info
    
    # Create module directory
    if (-not (Test-Path $ModulePath)) {
        New-Item -Path $ModulePath -ItemType Directory -Force | Out-Null
        Write-InstallMessage "✓ Created module directory" -Type Success
    }
    
    # Create subdirectories
    $subDirs = @('lib', 'cmdlets', 'tests\powershell\unit', 'tests\powershell\integration', 'tests\powershell\performance', 'docs\powershell')
    foreach ($dir in $subDirs) {
        $fullPath = Join-Path $ModulePath $dir
        if (-not (Test-Path $fullPath)) {
            New-Item -Path $fullPath -ItemType Directory -Force | Out-Null
        }
    }
    
    # Download and save core module files
    $coreFiles = @{
        'llm-env.psd1' = 'llm-env.psd1'
        'llm-env.psm1' = 'llm-env.psm1'
    }
    
    foreach ($file in $coreFiles.Keys) {
        $content = Get-GitHubContent -Path $file
        $content | Out-File -FilePath (Join-Path $ModulePath $coreFiles[$file]) -Encoding UTF8 -Force
    }
    
    # Download lib files
    $libFiles = @(
        'lib/DataModels.ps1',
        'lib/WindowsIntegration.psm1', 
        'lib/IniParser.psm1',
        'lib/Config.psm1',
        'lib/Providers.psm1',
        'lib/PowerShellEnhancements.psm1',
        'lib/WindowsUI.psm1'
    )
    
    foreach ($file in $libFiles) {
        $content = Get-GitHubContent -Path $file
        $content | Out-File -FilePath (Join-Path $ModulePath $file) -Encoding UTF8 -Force
    }
    
    # Download cmdlet files
    $cmdletFiles = @(
        'cmdlets/Set-LLMProvider.ps1',
        'cmdlets/Clear-LLMProvider.ps1',
        'cmdlets/Get-LLMProviders.ps1',
        'cmdlets/Show-LLMProvider.ps1',
        'cmdlets/Initialize-LLMConfig.ps1',
        'cmdlets/Edit-LLMConfig.ps1',
        'cmdlets/Add-LLMProvider.ps1',
        'cmdlets/Remove-LLMProvider.ps1',
        'cmdlets/Test-LLMProvider.ps1',
        'cmdlets/Backup-LLMConfig.ps1',
        'cmdlets/Restore-LLMConfig.ps1',
        'cmdlets/Enable-LLMProvider.ps1',
        'cmdlets/Disable-LLMProvider.ps1'
    )
    
    foreach ($file in $cmdletFiles) {
        $content = Get-GitHubContent -Path $file
        $content | Out-File -FilePath (Join-Path $ModulePath $file) -Encoding UTF8 -Force
    }
    
    # Download configuration file
    try {
        $configContent = Get-GitHubContent -Path "config/llm-env.conf"
        $configDir = Join-Path $ModulePath "config"
        if (-not (Test-Path $configDir)) {
            New-Item -Path $configDir -ItemType Directory -Force | Out-Null
        }
        $configContent | Out-File -FilePath (Join-Path $configDir "llm-env.conf") -Encoding UTF8 -Force
    } catch {
        Write-InstallMessage "Warning: Could not download default configuration" -Type Warning
    }
    
    Write-InstallMessage "✓ Module files downloaded and installed" -Type Success
}

function Update-PowerShellProfile {
    param(
        [string]$ProfilePath,
        [hashtable]$PSInfo
    )
    
    if ($SkipProfileUpdate) {
        Write-InstallMessage "Skipping PowerShell profile update" -Type Info
        return
    }
    
    Write-InstallMessage "Updating PowerShell profile..." -Type Info
    
    # Create profile directory if it doesn't exist
    $profileDir = Split-Path $ProfilePath -Parent
    if (-not (Test-Path $profileDir)) {
        New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
    }
    
    # Check if profile already imports the module
    $profileContent = ""
    if (Test-Path $ProfilePath) {
        $profileContent = Get-Content $ProfilePath -Raw -ErrorAction SilentlyContinue
    }
    
    $importStatement = "Import-Module llm-env -ErrorAction SilentlyContinue"
    
    if ($profileContent -notlike "*Import-Module llm-env*") {
        # Add import statement
        $newContent = @"
# LLM Environment Manager - Added by installer $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
$importStatement

$profileContent
"@
        $newContent | Out-File -FilePath $ProfilePath -Encoding UTF8 -Force
        Write-InstallMessage "✓ PowerShell profile updated" -Type Success
    } else {
        Write-InstallMessage "✓ PowerShell profile already configured" -Type Info
    }
}

function Test-Installation {
    param([string]$ModulePath)
    
    Write-InstallMessage "Testing installation..." -Type Info
    
    try {
        # Import the module
        Import-Module $ModulePath -Force -ErrorAction Stop
        
        # Test basic functionality
        $module = Get-Module llm-env
        if (-not $module) {
            throw "Module not loaded properly"
        }
        
        Write-InstallMessage "✓ Module version: $($module.Version)" -Type Success
        
        # Test core commands
        $providers = Get-LLMProviders -ErrorAction Stop
        Write-InstallMessage "✓ Found $($providers.Count) built-in providers" -Type Success
        
        # Test help system
        $help = Get-LLMHelp -ErrorAction Stop
        Write-InstallMessage "✓ Help system working" -Type Success
        
        Write-InstallMessage "✓ Installation test passed" -Type Success
        return $true
        
    } catch {
        Write-InstallMessage "✗ Installation test failed: $_" -Type Error
        return $false
    }
}

function Uninstall-LLMEnvironmentModule {
    param([hashtable]$PSInfo)
    
    Write-InstallHeader "Uninstalling LLM Environment Manager"
    
    # Remove from current session
    Remove-Module llm-env -Force -ErrorAction SilentlyContinue
    
    # Find and remove module directories
    $possiblePaths = @()
    
    if ($PSInfo.IsWindows) {
        $possiblePaths += Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Modules\$ModuleName"
        $possiblePaths += Join-Path $env:USERPROFILE "Documents\PowerShell\Modules\$ModuleName"
    } else {
        $possiblePaths += Join-Path $env:HOME ".local/share/powershell/Modules/$ModuleName"
    }
    
    if ($InstallPath) {
        $possiblePaths += $InstallPath
    }
    
    $removedPaths = @()
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            try {
                Remove-Item $path -Recurse -Force -ErrorAction Stop
                $removedPaths += $path
                Write-InstallMessage "✓ Removed: $path" -Type Success
            } catch {
                Write-InstallMessage "✗ Failed to remove: $path - $_" -Type Error
            }
        }
    }
    
    if ($removedPaths.Count -eq 0) {
        Write-InstallMessage "No installation found to remove" -Type Warning
    } else {
        Write-InstallMessage "✓ Uninstallation completed" -Type Success
    }
    
    # Optionally clean up profile
    if (-not $SkipProfileUpdate) {
        $profilePath = Get-PowerShellProfilePath -PSInfo $PSInfo
        if (Test-Path $profilePath) {
            $profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
            if ($profileContent -like "*Import-Module llm-env*") {
                Write-InstallMessage "Note: PowerShell profile still contains llm-env import statement" -Type Warning
                Write-InstallMessage "You may want to manually edit: $profilePath" -Type Info
            }
        }
    }
}

function Show-PostInstallInstructions {
    Write-InstallHeader "Installation Complete!"
    
    Write-InstallMessage "🎉 LLM Environment Manager PowerShell edition has been successfully installed!" -Type Success
    Write-Host ""
    
    Write-InstallMessage "Next Steps:" -Type Header
    Write-InstallMessage "1. Restart PowerShell or run: Import-Module llm-env" -Type Info
    Write-InstallMessage "2. Initialize configuration: Initialize-LLMConfig -IncludeDefaults" -Type Info
    Write-InstallMessage "3. Set your API keys:" -Type Info
    Write-InstallMessage "   `$env:LLM_OPENAI_API_KEY = 'your-api-key'" -Type Info
    Write-InstallMessage "4. Set a provider: Set-LLMProvider -Name openai" -Type Info
    Write-InstallMessage "5. Test connectivity: Test-LLMProvider -TestConnectivity" -Type Info
    Write-Host ""
    
    Write-InstallMessage "Quick Commands:" -Type Header
    Write-InstallMessage "• Get-LLMProviders          - List all providers" -Type Info
    Write-InstallMessage "• Set-LLMProvider -Name X   - Set active provider" -Type Info
    Write-InstallMessage "• Show-LLMProvider          - Show current status" -Type Info
    Write-InstallMessage "• Get-LLMHelp               - Interactive help" -Type Info
    Write-Host ""
    
    Write-InstallMessage "Documentation:" -Type Header
    Write-InstallMessage "• GitHub: $RepositoryUrl" -Type Info
    Write-InstallMessage "• PowerShell docs: $RepositoryUrl/tree/main/docs/powershell" -Type Info
    Write-Host ""
    
    Write-InstallMessage "Happy prompting! 🚀" -Type Success
}

# Main installation logic
try {
    Write-InstallHeader "LLM Environment Manager PowerShell Installer v$ModuleVersion"
    
    # Get PowerShell information
    $psInfo = Get-PowerShellInfo
    Write-InstallMessage "Detected: PowerShell $($psInfo.Version) ($($psInfo.Edition)) on $($psInfo.Platform)" -Type Info
    
    if ($Uninstall) {
        Uninstall-LLMEnvironmentModule -PSInfo $psInfo
        exit 0
    }
    
    # Check prerequisites
    if (-not (Test-Prerequisites -PSInfo $psInfo)) {
        Write-InstallMessage "Prerequisites check failed. Installation aborted." -Type Error
        exit 1
    }
    
    # Determine installation path
    $modulePath = Get-ModuleInstallPath -PSInfo $psInfo
    Write-InstallMessage "Module will be installed to: $modulePath" -Type Info
    
    # Check if already installed
    if ((Test-Path $modulePath) -and -not $Force) {
        Write-InstallMessage "Module already installed at: $modulePath" -Type Warning
        Write-InstallMessage "Use -Force to reinstall or -Uninstall to remove" -Type Info
        exit 0
    }
    
    # Remove existing installation if forcing
    if ($Force -and (Test-Path $modulePath)) {
        Write-InstallMessage "Removing existing installation..." -Type Warning
        Remove-Item $modulePath -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Install the module
    Write-InstallHeader "Installing Module Files"
    Install-LLMEnvironmentModule -ModulePath $modulePath -PSInfo $psInfo
    
    # Update PowerShell profile
    Write-InstallHeader "Configuring PowerShell Profile"
    $profilePath = Get-PowerShellProfilePath -PSInfo $psInfo
    Update-PowerShellProfile -ProfilePath $profilePath -PSInfo $psInfo
    
    # Test installation
    Write-InstallHeader "Testing Installation"
    $testResult = Test-Installation -ModulePath $modulePath
    
    if ($testResult) {
        Show-PostInstallInstructions
    } else {
        Write-InstallMessage "Installation completed but tests failed. Please check the installation manually." -Type Warning
    }
    
} catch {
    Write-InstallMessage "Installation failed: $_" -Type Error
    Write-InstallMessage "Please report this issue at: $RepositoryUrl/issues" -Type Info
    exit 1
}