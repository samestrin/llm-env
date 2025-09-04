# PowerShell Installation Guide

Complete installation instructions for the LLM Environment Manager PowerShell edition.

## System Requirements

### PowerShell Versions
- **PowerShell 5.1** (Windows PowerShell) - Included with Windows 10/11
- **PowerShell 7.0+** (PowerShell Core) - Cross-platform version

### Operating Systems
- ✅ **Windows 10/11** (Primary target)
- ✅ **Windows Server 2016+**  
- ✅ **macOS 10.13+** (with PowerShell 7)
- ✅ **Linux** (with PowerShell 7)

### Dependencies
- No external dependencies required
- Optional: [Pester](https://pester.dev/) for running tests

## Installation Methods

### Method 1: Automated Installation Script (Recommended)

The easiest way to install is using the automated installation script:

```powershell
# Download and run installation script
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/samestrin/llm-env/main/install.ps1" -UseBasicParsing).Content
```

This script will:
- Detect your PowerShell version
- Install the module to the appropriate location
- Set up the PowerShell profile integration
- Verify the installation

### Method 2: Manual Installation

#### Step 1: Download the Module

```powershell
# Clone the repository
git clone https://github.com/samestrin/llm-env.git
cd llm-env

# Or download ZIP and extract
```

#### Step 2: Copy Module Files

**For PowerShell 5.1 (Windows PowerShell):**
```powershell
# Get module path
$modulePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\llm-env"

# Create directory
New-Item -Path $modulePath -ItemType Directory -Force

# Copy module files
Copy-Item -Path "llm-env.psd1", "llm-env.psm1" -Destination $modulePath
Copy-Item -Path "lib", "cmdlets" -Destination $modulePath -Recurse
```

**For PowerShell 7+:**
```powershell
# Get module path  
$modulePath = "$env:USERPROFILE\Documents\PowerShell\Modules\llm-env"

# Create directory
New-Item -Path $modulePath -ItemType Directory -Force

# Copy module files
Copy-Item -Path "llm-env.psd1", "llm-env.psm1" -Destination $modulePath
Copy-Item -Path "lib", "cmdlets" -Destination $modulePath -Recurse
```

#### Step 3: Import the Module

```powershell
# Import module
Import-Module llm-env

# Verify installation
Get-Module llm-env
```

### Method 3: PowerShell Gallery (Future)

*Note: PowerShell Gallery distribution is planned for a future release.*

```powershell
# Install from PowerShell Gallery (coming soon)
Install-Module -Name llm-env -Scope CurrentUser
```

## Installation Verification

After installation, verify everything is working:

```powershell
# Check module is loaded
Get-Module llm-env

# Test basic functionality
Get-LLMProviders

# Check help system
Get-LLMHelp

# Verify aliases are available
Get-Alias llm-*
```

Expected output:
```
ModuleType Version    Name      ExportedCommands
---------- -------    ----      ----------------
Script     1.1.0      llm-env   {Add-LLMProvider, Backup-LLMConfig, Clear-LLMProvider...}
```

## Configuration Setup

### Initial Configuration

```powershell
# Initialize configuration with defaults
Initialize-LLMConfig -IncludeDefaults

# Or create minimal configuration
Initialize-LLMConfig

# Edit configuration
Edit-LLMConfig
```

### Set Up API Keys

```powershell
# Set API keys as environment variables
$env:LLM_OPENAI_API_KEY = "your-openai-key"
$env:LLM_ANTHROPIC_API_KEY = "your-anthropic-key"
$env:LLM_GEMINI_API_KEY = "your-gemini-key"

# Persist in PowerShell profile (optional)
Add-Content $PROFILE "`$env:LLM_OPENAI_API_KEY = 'your-openai-key'"
```

### Test Your Setup

```powershell
# List available providers
Get-LLMProviders

# Set a provider
Set-LLMProvider -Name openai

# Test connectivity
Test-LLMProvider -TestConnectivity

# Show current setup
Show-LLMProvider
```

## Advanced Installation Options

### Custom Installation Paths

```powershell
# Install to custom location
$customPath = "C:\Tools\PowerShell\Modules\llm-env"
New-Item -Path $customPath -ItemType Directory -Force
Copy-Item -Path "llm-env.psd1", "llm-env.psm1", "lib", "cmdlets" -Destination $customPath -Recurse

# Add to PSModulePath
$env:PSModulePath += ";$customPath"
```

### System-Wide Installation

*Note: Requires Administrator privileges*

```powershell
# Install for all users (requires admin)
$systemPath = "$env:PROGRAMFILES\PowerShell\Modules\llm-env"
New-Item -Path $systemPath -ItemType Directory -Force
Copy-Item -Path "llm-env.psd1", "llm-env.psm1", "lib", "cmdlets" -Destination $systemPath -Recurse
```

### Development Installation

For developers who want to work with the source:

```powershell
# Clone repository
git clone https://github.com/samestrin/llm-env.git
cd llm-env

# Create symbolic link to module path
$modulePath = "$env:USERPROFILE\Documents\PowerShell\Modules\llm-env"
New-Item -ItemType SymbolicLink -Path $modulePath -Target (Get-Location)

# Import in development mode
Import-Module llm-env -Force
```

## PowerShell Profile Integration

### Automatic Loading

To have the module load automatically in every PowerShell session:

```powershell
# Add to PowerShell profile
Add-Content $PROFILE "Import-Module llm-env"

# Or create profile if it doesn't exist
if (!(Test-Path $PROFILE)) {
    New-Item -Path $PROFILE -ItemType File -Force
}
Add-Content $PROFILE "Import-Module llm-env"
```

### Custom Aliases

Add custom aliases to your profile:

```powershell
# Add to $PROFILE
Add-Content $PROFILE @"
# LLM Environment Manager aliases
New-Alias -Name llm -Value Set-LLMProvider
New-Alias -Name llm-current -Value Show-LLMProvider
New-Alias -Name llm-check -Value Test-LLMProvider
"@
```

## Troubleshooting Installation

### Common Issues

**"Execution policy restricts script execution"**
```powershell
# Check current policy
Get-ExecutionPolicy

# Set policy for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or bypass for single session
PowerShell -ExecutionPolicy Bypass
```

**"Module not found after installation"**
```powershell
# Check module paths
$env:PSModulePath -split ';'

# Refresh module cache
Remove-Module llm-env -ErrorAction SilentlyContinue
Import-Module llm-env -Force
```

**"Access denied when copying files"**
```powershell
# Ensure you have write permissions
# Run PowerShell as Administrator if needed
# Or install to user directory instead of system
```

**"Git not available"**
```powershell
# Download ZIP instead
$zipUrl = "https://github.com/samestrin/llm-env/archive/refs/heads/main.zip"
Invoke-WebRequest -Uri $zipUrl -OutFile "llm-env.zip"
Expand-Archive "llm-env.zip" -DestinationPath "."
```

### Verification Commands

```powershell
# Check PowerShell version
$PSVersionTable

# Check module location
(Get-Module llm-env).Path

# Check exported commands
(Get-Module llm-env).ExportedCommands.Keys

# Test basic functionality
Get-LLMProviders | Measure-Object
```

### Clean Installation

To completely remove and reinstall:

```powershell
# Remove module
Remove-Module llm-env -Force -ErrorAction SilentlyContinue

# Delete module files
$modulePaths = @(
    "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\llm-env",
    "$env:USERPROFILE\Documents\PowerShell\Modules\llm-env"
)

foreach ($path in $modulePaths) {
    if (Test-Path $path) {
        Remove-Item $path -Recurse -Force
    }
}

# Reinstall
# (Run installation method again)
```

## Docker Installation

For containerized environments:

```dockerfile
# Dockerfile
FROM mcr.microsoft.com/powershell:latest

# Install llm-env
RUN pwsh -c "Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/samestrin/llm-env/main/install.ps1' -UseBasicParsing).Content"

# Set up configuration
COPY config.conf /root/.config/llm-env/config.conf

ENTRYPOINT ["pwsh"]
```

## Uninstallation

To completely remove the PowerShell module:

```powershell
# Remove from current session
Remove-Module llm-env -Force

# Delete module files
$modulePaths = @(
    "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\llm-env",
    "$env:USERPROFILE\Documents\PowerShell\Modules\llm-env",
    "$env:PROGRAMFILES\PowerShell\Modules\llm-env"
)

foreach ($path in $modulePaths) {
    if (Test-Path $path) {
        Remove-Item $path -Recurse -Force
        Write-Host "Removed: $path"
    }
}

# Remove from PowerShell profile (optional)
$profileContent = Get-Content $PROFILE -ErrorAction SilentlyContinue
if ($profileContent) {
    $filteredContent = $profileContent | Where-Object { $_ -notmatch "llm-env" }
    $filteredContent | Set-Content $PROFILE
}

Write-Host "LLM Environment Manager PowerShell module uninstalled successfully."
```

## Next Steps

After successful installation:

1. **Configure providers**: See [Usage Guide](usage.md)
2. **Set up API keys**: Add your API keys to environment variables
3. **Test connectivity**: Use `Test-LLMProvider -TestConnectivity`
4. **Explore features**: Try `Get-LLMHelp` for interactive help

For more information, see the [main documentation](README.md).