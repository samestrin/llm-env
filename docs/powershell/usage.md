# Usage Guide - PowerShell Edition

Comprehensive usage examples and workflows for the LLM Environment Manager PowerShell edition.

## Basic Workflows

### Getting Started

```powershell
# 1. Check what providers are available
Get-LLMProviders

# 2. Set up your API key (example with OpenAI)
$env:LLM_OPENAI_API_KEY = "sk-your-api-key-here"

# 3. Set the active provider
Set-LLMProvider -Name openai

# 4. Verify everything is working
Show-LLMProvider
Test-LLMProvider -TestConnectivity
```

### Daily Usage Patterns

```powershell
# Quick provider switch
Set-LLMProvider -Name anthropic

# Check current status
Show-LLMProvider

# Switch back to previous provider
Clear-LLMProvider -RestorePrevious

# Test all your configured providers
Test-LLMProvider -All -EnabledOnly
```

## Provider Management

### Listing and Filtering Providers

```powershell
# List all providers
Get-LLMProviders

# Show only enabled providers
Get-LLMProviders -EnabledOnly

# Show only providers with valid configurations
Get-LLMProviders -ValidOnly

# Filter by name pattern
Get-LLMProviders -NamePattern "*ai*"

# Different output formats
Get-LLMProviders -Format Table    # Default table format
Get-LLMProviders -Format List     # Detailed list format
Get-LLMProviders -Format Json     # JSON output
Get-LLMProviders -Format CSV      # CSV format

# Include API key status
Get-LLMProviders -IncludeApiKeyStatus
```

### Setting Providers

```powershell
# Basic provider setting
Set-LLMProvider -Name openai

# Set provider with custom model
Set-LLMProvider -Name openai -Model "gpt-4-turbo"

# Force setting a disabled provider
Set-LLMProvider -Name disabled_provider -Force

# Set provider without API key validation
Set-LLMProvider -Name test_provider -Force
```

### Provider Information

```powershell
# Show current provider status
Show-LLMProvider

# Show with API key details (masked for security)
Show-LLMProvider -IncludeApiKey

# Show with connectivity test
Show-LLMProvider -TestConnectivity
```

## Configuration Management

### Creating and Initializing Configuration

```powershell
# Create new configuration with built-in defaults
Initialize-LLMConfig -IncludeDefaults

# Create minimal configuration
Initialize-LLMConfig

# Create configuration at custom location
Initialize-LLMConfig -Path "C:\MyConfig\llm.conf"

# Force overwrite existing configuration
Initialize-LLMConfig -Force -IncludeDefaults
```

### Editing Configuration

```powershell
# Edit configuration in default editor
Edit-LLMConfig

# Edit specific configuration file
Edit-LLMConfig -Path "C:\MyConfig\llm.conf"

# Edit with specific editor
Edit-LLMConfig -Editor "notepad"
Edit-LLMConfig -Editor "code"  # VS Code

# Wait for editor to close
Edit-LLMConfig -Wait
```

### Adding and Removing Providers

```powershell
# Add provider interactively
Add-LLMProvider -Interactive

# Add provider programmatically
Add-LLMProvider -Name "myapi" -BaseUrl "https://api.myservice.com/v1" -ApiKeyVar "MY_API_KEY"

# Add provider with full details
Add-LLMProvider -Name "custom" `
    -BaseUrl "https://api.custom.com/v1" `
    -ApiKeyVar "CUSTOM_API_KEY" `
    -DefaultModel "custom-model-v1" `
    -Description "My custom LLM provider" `
    -Enabled $true

# Remove provider (with confirmation)
Remove-LLMProvider -Name "oldapi"

# Remove provider without confirmation
Remove-LLMProvider -Name "oldapi" -Force
```

### Backup and Restore

```powershell
# Create backup
Backup-LLMConfig

# Create compressed backup
Backup-LLMConfig -Compress

# Backup to specific location
Backup-LLMConfig -BackupPath "C:\Backups\llm-config-backup.conf"

# Restore from backup
Restore-LLMConfig -BackupPath "backup-llm-env-20241204-143022.conf"

# Restore with backup of current config
Restore-LLMConfig -BackupPath "backup.conf" -CreateBackup

# Force restore without confirmation
Restore-LLMConfig -BackupPath "backup.conf" -Force
```

## Provider Testing and Validation

### Basic Testing

```powershell
# Test current provider
Test-LLMProvider

# Test specific provider
Test-LLMProvider -Name openai

# Test with connectivity check
Test-LLMProvider -Name openai -TestConnectivity

# Test with detailed output
Test-LLMProvider -Name openai -Detailed
```

### Batch Testing

```powershell
# Test all providers
Test-LLMProvider -All

# Test only enabled providers
Test-LLMProvider -All -EnabledOnly

# Test all with connectivity (may take time)
Test-LLMProvider -All -EnabledOnly -TestConnectivity

# Skip connectivity tests for speed
Test-LLMProvider -All -SkipConnectivity
```

## Bulk Operations

### Enabling and Disabling Providers

```powershell
# Enable single provider
Enable-LLMProvider -Name "anthropic"

# Enable multiple providers
Enable-LLMProvider -Name "openai", "anthropic", "gemini"

# Enable all providers
Enable-LLMProvider -All

# Disable providers
Disable-LLMProvider -Name "old_provider"

# Disable multiple providers
Disable-LLMProvider -Name "provider1", "provider2"

# Disable all providers (dangerous!)
Disable-LLMProvider -All -Force
```

## Advanced PowerShell Features

### Pipeline Operations

```powershell
# Filter providers and get details
Get-LLMProviders | Where-Object { $_.Enabled -eq $true } | Format-Table Name, BaseUrl

# Test enabled providers through pipeline
Get-LLMProviders -EnabledOnly | ForEach-Object { Test-LLMProvider -Name $_.Name }

# Convert provider list to custom objects
Get-LLMProviders | Select-Object Name, BaseUrl, @{Name='HasApiKey'; Expression={
    $apiKey = [System.Environment]::GetEnvironmentVariable($_.ApiKeyVar)
    -not [string]::IsNullOrEmpty($apiKey)
}}

# Export provider list to CSV
Get-LLMProviders | Export-Csv -Path "providers.csv" -NoTypeInformation

# Pipeline testing with custom output
Get-LLMProviders -EnabledOnly | Test-LLMProviderPipeline | Where-Object { $_.Status -eq 'Ready' }
```

### Advanced Filtering and Sorting

```powershell
# Get providers by API availability
Get-LLMProviders -IncludeApiKeyStatus | Where-Object { $_.ApiKeySet -eq $true }

# Sort providers by name
Get-LLMProviders | Sort-Object Name

# Group providers by enabled status
Get-LLMProviders | Group-Object Enabled

# Find providers with specific base URL patterns
Get-LLMProviders | Where-Object { $_.BaseUrl -like "*openai*" }
```

### Custom Objects and Formatting

```powershell
# Create custom provider summary
$summary = Get-LLMProviders | ForEach-Object {
    [PSCustomObject]@{
        Name = $_.Name
        Status = if ($_.Enabled) { "✓" } else { "✗" }
        ApiKey = if ([System.Environment]::GetEnvironmentVariable($_.ApiKeyVar)) { "Set" } else { "Missing" }
        Url = $_.BaseUrl
    }
}
$summary | Format-Table

# Custom formatting with calculated properties
Get-LLMProviders | Select-Object Name, 
    @{Name='Status'; Expression={if ($_.Enabled) {'Enabled'} else {'Disabled'}}},
    @{Name='Domain'; Expression={([uri]$_.BaseUrl).Host}}
```

## Environment Management

### Environment Variable Handling

```powershell
# Set environment variables for session
$env:LLM_OPENAI_API_KEY = "your-key"
$env:LLM_ANTHROPIC_API_KEY = "your-key"

# Set environment variables persistently (current user)
[System.Environment]::SetEnvironmentVariable("LLM_OPENAI_API_KEY", "your-key", "User")

# Check current environment
Show-LLMProvider -IncludeApiKey

# Clear specific environment variables
$env:LLM_OPENAI_API_KEY = $null
```

### Working with Multiple Configurations

```powershell
# Use different configuration files
$env:LLM_CONFIG_PATH = "C:\Work\work-config.conf"
Get-LLMProviders

# Load specific configuration
$config = Get-LLMConfiguration -ConfigPath "C:\Personal\personal-config.conf"

# Switch between configurations
function Switch-LLMConfig {
    param([string]$ConfigName)
    
    $configPath = "C:\Configs\$ConfigName.conf"
    if (Test-Path $configPath) {
        $env:LLM_CONFIG_PATH = $configPath
        Clear-LLMConfigurationCache
        Write-Host "Switched to configuration: $ConfigName"
        Get-LLMProviders
    }
}

# Usage: Switch-LLMConfig -ConfigName "work"
```

## Integration with Other Tools

### PowerShell Profile Integration

Add to your PowerShell profile (`$PROFILE`):

```powershell
# Auto-load LLM Environment Manager
Import-Module llm-env

# Custom functions
function Quick-LLM {
    param([string]$Provider = "openai")
    Set-LLMProvider -Name $Provider
    Show-LLMProvider
}

function LLM-Status {
    $current = [System.Environment]::GetEnvironmentVariable('LLM_PROVIDER')
    if ($current) {
        Write-Host "Current LLM Provider: " -NoNewline
        Write-Host $current -ForegroundColor Green
    } else {
        Write-Host "No LLM provider set" -ForegroundColor Yellow
    }
}

# Add to prompt
function Prompt {
    $provider = [System.Environment]::GetEnvironmentVariable('LLM_PROVIDER')
    $location = Get-Location
    
    if ($provider) {
        Write-Host "[$provider]" -ForegroundColor Cyan -NoNewline
        Write-Host " $location>" -NoNewline
    } else {
        Write-Host "$location>" -NoNewline
    }
    
    return " "
}
```

### Integration with Development Tools

```powershell
# VS Code integration - open config in VS Code
function Edit-LLMConfigVSCode {
    $configPath = Get-LLMConfigFilePath
    if (Test-Path $configPath) {
        code $configPath
    } else {
        Write-Host "Configuration file not found. Run Initialize-LLMConfig first."
    }
}

# Git integration - track configuration changes
function Backup-LLMConfigGit {
    $configPath = Get-LLMConfigFilePath
    $gitDir = Split-Path $configPath -Parent
    
    Push-Location $gitDir
    try {
        git add (Split-Path $configPath -Leaf)
        git commit -m "Update LLM configuration - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    }
    finally {
        Pop-Location
    }
}
```

## Troubleshooting Workflows

### Diagnostic Commands

```powershell
# Full system diagnostic
function Test-LLMEnvironment {
    Write-Host "=== LLM Environment Diagnostic ===" -ForegroundColor Green
    
    # Check module
    $module = Get-Module llm-env
    Write-Host "Module Version: $($module.Version)" -ForegroundColor Cyan
    
    # Check configuration
    try {
        $providers = Get-LLMProviders
        Write-Host "Providers Found: $($providers.Count)" -ForegroundColor Cyan
    } catch {
        Write-Host "Configuration Error: $_" -ForegroundColor Red
    }
    
    # Check current provider
    $current = [System.Environment]::GetEnvironmentVariable('LLM_PROVIDER')
    if ($current) {
        Write-Host "Current Provider: $current" -ForegroundColor Green
        Test-LLMProvider -Name $current -Detailed
    } else {
        Write-Host "No provider currently set" -ForegroundColor Yellow
    }
    
    # Check API keys
    Write-Host "`nAPI Key Status:" -ForegroundColor Yellow
    Get-LLMProviders | ForEach-Object {
        $hasKey = -not [string]::IsNullOrEmpty([System.Environment]::GetEnvironmentVariable($_.ApiKeyVar))
        $status = if ($hasKey) { "✓" } else { "✗" }
        Write-Host "  $($_.Name): $status" -ForegroundColor $(if ($hasKey) { "Green" } else { "Red" })
    }
}
```

### Common Issue Resolution

```powershell
# Fix common configuration issues
function Repair-LLMConfig {
    Write-Host "Repairing LLM configuration..." -ForegroundColor Yellow
    
    # Clear cache
    Clear-LLMConfigurationCache
    
    # Verify configuration file
    $configPath = Get-LLMConfigFilePath
    if (-not (Test-Path $configPath)) {
        Write-Host "Creating missing configuration..." -ForegroundColor Green
        Initialize-LLMConfig -IncludeDefaults
    }
    
    # Test configuration
    try {
        $result = Test-LLMConfiguration -Configuration (Get-LLMConfiguration)
        if (-not $result.IsValid) {
            Write-Host "Configuration issues found:" -ForegroundColor Red
            $result.Errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        } else {
            Write-Host "Configuration is valid" -ForegroundColor Green
        }
    } catch {
        Write-Host "Configuration test failed: $_" -ForegroundColor Red
    }
}

# Reset environment to clean state
function Reset-LLMEnvironment {
    Write-Host "Resetting LLM environment..." -ForegroundColor Yellow
    
    # Clear all LLM environment variables
    $llmVars = @('LLM_PROVIDER', 'LLM_BASE_URL', 'LLM_MODEL', 'LLM_API_KEY_VAR', 
                 'OPENAI_BASE_URL', 'OPENAI_API_KEY', 'LLM_PREVIOUS_PROVIDER')
    
    foreach ($var in $llmVars) {
        [System.Environment]::SetEnvironmentVariable($var, $null, 'Process')
    }
    
    Clear-LLMConfigurationCache
    Write-Host "Environment reset complete" -ForegroundColor Green
}
```

## Performance Optimization Tips

### Efficient Usage Patterns

```powershell
# Cache provider list for repeated use
$providers = Get-LLMProviders
# Use $providers for multiple operations instead of calling Get-LLMProviders repeatedly

# Use pipeline for bulk operations
Get-LLMProviders -EnabledOnly | Test-LLMProviderPipeline

# Pre-filter before expensive operations
Get-LLMProviders -EnabledOnly -ValidOnly | Test-LLMProvider -SkipConnectivity
```

### Configuration Optimization

```powershell
# Keep configuration files small and focused
# Enable only the providers you actively use
# Use descriptive names for easy identification
# Regular cleanup of unused providers
```

For more advanced scenarios and troubleshooting, see the [Migration Guide](migration.md) and main [README](README.md).