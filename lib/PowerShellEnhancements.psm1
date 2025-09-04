#Requires -Version 5.1
<#
.SYNOPSIS
    PowerShell-native enhancements for LLM Environment Manager
.DESCRIPTION
    Provides PowerShell-specific features including tab completion,
    help integration, pipeline support, and enhanced user experience.
.NOTES
    Compatible with PowerShell 5.1+ and 7+
#>

Set-StrictMode -Version Latest

# Tab completion for provider names
Register-ArgumentCompleter -CommandName 'Set-LLMProvider', 'Get-LLMProvider', 'Test-LLMProvider', 'Remove-LLMProvider', 'Enable-LLMProvider', 'Disable-LLMProvider' -ParameterName 'Name' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    try {
        # Get all providers for tab completion
        $providers = Get-LLMProviders -ErrorAction SilentlyContinue
        
        $providers | Where-Object { $_.Name -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new(
                $_.Name,
                $_.Name,
                'ParameterValue',
                "$($_.Name) - $($_.Description)"
            )
        }
    }
    catch {
        # Fallback to empty results if providers can't be loaded
        @()
    }
}

# Tab completion for configuration file paths
Register-ArgumentCompleter -CommandName 'Initialize-LLMConfig', 'Edit-LLMConfig', 'Backup-LLMConfig', 'Restore-LLMConfig' -ParameterName 'Path' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    try {
        # Complete file paths
        $path = if ([string]::IsNullOrWhiteSpace($wordToComplete)) { '.' } else { $wordToComplete }
        
        # Get files and directories matching the pattern
        Get-ChildItem -Path "$path*" -ErrorAction SilentlyContinue | ForEach-Object {
            $completionText = if ($_.PSIsContainer) { "$($_.Name)/" } else { $_.Name }
            $listItemText = if ($_.PSIsContainer) { "$($_.Name) (directory)" } else { "$($_.Name) ($($_.Length) bytes)" }
            
            [System.Management.Automation.CompletionResult]::new(
                $completionText,
                $completionText,
                $(if ($_.PSIsContainer) { 'ParameterValue' } else { 'ParameterValue' }),
                $listItemText
            )
        }
    }
    catch {
        @()
    }
}

# Tab completion for backup files
Register-ArgumentCompleter -CommandName 'Restore-LLMConfig' -ParameterName 'BackupPath' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    try {
        # Look for backup files in current directory and config directory
        $searchPaths = @('.', (Get-LLMConfigDirectory -ErrorAction SilentlyContinue))
        $backupFiles = @()
        
        foreach ($searchPath in $searchPaths) {
            if (Test-Path $searchPath) {
                $backupFiles += Get-ChildItem -Path $searchPath -Filter "*backup*" -ErrorAction SilentlyContinue
                $backupFiles += Get-ChildItem -Path $searchPath -Filter "*.zip" -ErrorAction SilentlyContinue
            }
        }
        
        $backupFiles | Where-Object { $_.Name -like "*$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new(
                $_.Name,
                $_.Name,
                'ParameterValue',
                "$($_.Name) - $($_.LastWriteTime)"
            )
        }
    }
    catch {
        @()
    }
}

# Enhanced pipeline support functions
function ConvertTo-LLMProviderObject {
    <#
    .SYNOPSIS
        Converts provider data to standardized PowerShell objects for pipeline operations
    .DESCRIPTION
        Transforms provider information into objects optimized for PowerShell pipeline processing
    .PARAMETER Provider
        Provider object to convert
    .OUTPUTS
        [PSCustomObject] Standardized provider object
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [LLMProvider]$Provider
    )
    
    process {
        $currentProvider = Get-LLMEnvironmentVariable -Name 'LLM_PROVIDER'
        $apiKey = Get-LLMEnvironmentVariable -Name $Provider.ApiKeyVar
        
        [PSCustomObject]@{
            PSTypeName = 'LLMEnvironment.Provider'
            Name = $Provider.Name
            BaseUrl = $Provider.BaseUrl
            ApiKeyVar = $Provider.ApiKeyVar
            DefaultModel = $Provider.DefaultModel
            Description = $Provider.Description
            Enabled = $Provider.Enabled
            Valid = $Provider.IsValid()
            Current = ($Provider.Name -eq $currentProvider)
            HasApiKey = (-not [string]::IsNullOrWhiteSpace($apiKey))
            Provider = $Provider  # Keep reference to original object
        }
    }
}

# Format data for PowerShell formatting system
function Format-LLMProviderList {
    <#
    .SYNOPSIS
        Formats provider list for optimal PowerShell display
    .DESCRIPTION
        Provides custom formatting for provider objects in PowerShell console
    .PARAMETER InputObject
        Provider objects to format
    .OUTPUTS
        [string] Formatted output
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject[]]$InputObject
    )
    
    begin {
        $providers = @()
    }
    
    process {
        $providers += $InputObject
    }
    
    end {
        if ($providers.Count -eq 0) {
            return "No providers found."
        }
        
        # Create table format
        $table = @()
        $table += "Name".PadRight(15) + "Status".PadRight(10) + "Valid".PadRight(8) + "API Key".PadRight(10) + "Description"
        $table += "-" * 15 + "-" * 10 + "-" * 8 + "-" * 10 + "-" * 30
        
        foreach ($provider in $providers) {
            $status = if ($provider.Current) { "Current" } 
                     elseif ($provider.Enabled) { "Enabled" } 
                     else { "Disabled" }
            
            $valid = if ($provider.Valid) { "Yes" } else { "No" }
            $apiKey = if ($provider.HasApiKey) { "Set" } else { "Missing" }
            $description = if ($provider.Description.Length -gt 30) { 
                $provider.Description.Substring(0, 27) + "..." 
            } else { 
                $provider.Description 
            }
            
            $table += $provider.Name.PadRight(15) + $status.PadRight(10) + $valid.PadRight(8) + $apiKey.PadRight(10) + $description
        }
        
        return $table -join "`n"
    }
}

# Provider validation pipeline function
function Test-LLMProviderPipeline {
    <#
    .SYNOPSIS
        Pipeline-optimized provider validation
    .DESCRIPTION
        Validates providers received through PowerShell pipeline
    .PARAMETER InputObject
        Provider objects from pipeline
    .PARAMETER TestConnectivity
        Test API connectivity
    .OUTPUTS
        [PSCustomObject] Validation results
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$InputObject,
        
        [Parameter()]
        [switch]$TestConnectivity
    )
    
    process {
        try {
            $testResult = Test-LLMProvider -Name $InputObject.Name -TestConnectivity:$TestConnectivity
            
            # Enhance with pipeline-friendly properties
            $result = [PSCustomObject]@{
                PSTypeName = 'LLMEnvironment.TestResult'
                ProviderName = $testResult.ProviderName
                IsValid = $testResult.IsValid
                IsEnabled = $testResult.IsEnabled
                HasApiKey = $testResult.HasApiKey
                IsConnectable = $testResult.IsConnectable
                Status = if ($testResult.IsValid -and $testResult.IsEnabled -and $testResult.HasApiKey) { 'Ready' }
                        elseif ($testResult.IsValid -and $testResult.IsEnabled) { 'NeedsApiKey' }
                        elseif ($testResult.IsValid) { 'Disabled' }
                        else { 'Invalid' }
                Errors = $testResult.Errors
                Warnings = $testResult.Warnings
                Details = $testResult.Details
            }
            
            return $result
        }
        catch {
            return [PSCustomObject]@{
                PSTypeName = 'LLMEnvironment.TestResult'
                ProviderName = $InputObject.Name
                IsValid = $false
                Status = 'Error'
                Errors = @($_.Exception.Message)
                Warnings = @()
            }
        }
    }
}

# Help system integration
function Get-LLMHelp {
    <#
    .SYNOPSIS
        Displays comprehensive help for LLM Environment Manager
    .DESCRIPTION
        Provides context-aware help for LLM environment management commands
    .PARAMETER Topic
        Specific help topic (optional)
    .OUTPUTS
        [void]
    .EXAMPLE
        Get-LLMHelp
    .EXAMPLE
        Get-LLMHelp -Topic "getting-started"
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('getting-started', 'providers', 'configuration', 'troubleshooting', 'examples')]
        [string]$Topic
    )
    
    if (-not $Topic) {
        Write-Host "LLM Environment Manager - PowerShell Edition" -ForegroundColor Green
        Write-Host "==========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Available Commands:" -ForegroundColor Yellow
        Write-Host "  Set-LLMProvider      Set active provider" -ForegroundColor Cyan
        Write-Host "  Clear-LLMProvider    Clear active provider" -ForegroundColor Cyan
        Write-Host "  Get-LLMProviders     List all providers" -ForegroundColor Cyan
        Write-Host "  Show-LLMProvider     Show current provider status" -ForegroundColor Cyan
        Write-Host "  Test-LLMProvider     Test provider configuration" -ForegroundColor Cyan
        Write-Host "  Add-LLMProvider      Add new provider" -ForegroundColor Cyan
        Write-Host "  Remove-LLMProvider   Remove provider" -ForegroundColor Cyan
        Write-Host "  Enable-LLMProvider   Enable provider(s)" -ForegroundColor Cyan
        Write-Host "  Disable-LLMProvider  Disable provider(s)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Configuration:" -ForegroundColor Yellow
        Write-Host "  Initialize-LLMConfig Create new configuration" -ForegroundColor Cyan
        Write-Host "  Edit-LLMConfig       Edit configuration file" -ForegroundColor Cyan
        Write-Host "  Backup-LLMConfig     Backup configuration" -ForegroundColor Cyan
        Write-Host "  Restore-LLMConfig    Restore from backup" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Help Topics:" -ForegroundColor Yellow
        Write-Host "  Get-LLMHelp -Topic getting-started" -ForegroundColor Gray
        Write-Host "  Get-LLMHelp -Topic providers" -ForegroundColor Gray
        Write-Host "  Get-LLMHelp -Topic configuration" -ForegroundColor Gray
        Write-Host "  Get-LLMHelp -Topic troubleshooting" -ForegroundColor Gray
        Write-Host "  Get-LLMHelp -Topic examples" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Quick Start:" -ForegroundColor Yellow
        Write-Host "  1. Get-LLMProviders              # List available providers" -ForegroundColor Gray
        Write-Host "  2. Set-LLMProvider -Name openai  # Set a provider" -ForegroundColor Gray
        Write-Host "  3. Show-LLMProvider              # Verify configuration" -ForegroundColor Gray
        return
    }
    
    switch ($Topic) {
        'getting-started' {
            Write-Host "Getting Started with LLM Environment Manager" -ForegroundColor Green
            Write-Host "===========================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "1. Check available providers:" -ForegroundColor Yellow
            Write-Host "   Get-LLMProviders" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "2. Set up API keys (example for OpenAI):" -ForegroundColor Yellow
            Write-Host "   `$env:LLM_OPENAI_API_KEY = 'your-api-key-here'" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "3. Set active provider:" -ForegroundColor Yellow
            Write-Host "   Set-LLMProvider -Name openai" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "4. Verify setup:" -ForegroundColor Yellow
            Write-Host "   Show-LLMProvider" -ForegroundColor Cyan
            Write-Host "   Test-LLMProvider -TestConnectivity" -ForegroundColor Cyan
        }
        'providers' {
            Write-Host "Working with Providers" -ForegroundColor Green
            Write-Host "=====================" -ForegroundColor Green
            Write-Host ""
            Write-Host "List providers:" -ForegroundColor Yellow
            Write-Host "  Get-LLMProviders                    # All providers" -ForegroundColor Cyan
            Write-Host "  Get-LLMProviders -EnabledOnly       # Only enabled" -ForegroundColor Cyan
            Write-Host "  Get-LLMProviders -NamePattern 'ai*' # Filter by name" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Manage providers:" -ForegroundColor Yellow
            Write-Host "  Add-LLMProvider -Interactive        # Add new provider" -ForegroundColor Cyan
            Write-Host "  Enable-LLMProvider -Name myapi      # Enable provider" -ForegroundColor Cyan
            Write-Host "  Disable-LLMProvider -Name oldapi    # Disable provider" -ForegroundColor Cyan
            Write-Host "  Remove-LLMProvider -Name badapi     # Remove provider" -ForegroundColor Cyan
        }
        'configuration' {
            Write-Host "Configuration Management" -ForegroundColor Green
            Write-Host "======================" -ForegroundColor Green
            Write-Host ""
            Write-Host "Configuration files are stored at:" -ForegroundColor Yellow
            Write-Host "  Windows: %APPDATA%\\llm-env\\config.conf" -ForegroundColor Gray
            Write-Host "  macOS/Linux: ~/.config/llm-env/config.conf" -ForegroundColor Gray
            Write-Host ""
            Write-Host "Common operations:" -ForegroundColor Yellow
            Write-Host "  Initialize-LLMConfig                 # Create new config" -ForegroundColor Cyan
            Write-Host "  Edit-LLMConfig                       # Edit in default editor" -ForegroundColor Cyan
            Write-Host "  Backup-LLMConfig                     # Create backup" -ForegroundColor Cyan
            Write-Host "  Restore-LLMConfig -BackupPath file   # Restore from backup" -ForegroundColor Cyan
        }
        'troubleshooting' {
            Write-Host "Troubleshooting" -ForegroundColor Green
            Write-Host "==============" -ForegroundColor Green
            Write-Host ""
            Write-Host "Common issues and solutions:" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "• No providers found:" -ForegroundColor Red
            Write-Host "  Initialize-LLMConfig -IncludeDefaults" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "• API key not working:" -ForegroundColor Red
            Write-Host "  Test-LLMProvider -Name provider -TestConnectivity" -ForegroundColor Cyan
            Write-Host "  Show-LLMProvider -IncludeApiKey" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "• Configuration issues:" -ForegroundColor Red
            Write-Host "  Get-LLMProviders -ValidOnly" -ForegroundColor Cyan
            Write-Host "  Test-LLMProvider -All" -ForegroundColor Cyan
        }
        'examples' {
            Write-Host "Usage Examples" -ForegroundColor Green
            Write-Host "=============" -ForegroundColor Green
            Write-Host ""
            Write-Host "Pipeline operations:" -ForegroundColor Yellow
            Write-Host "  Get-LLMProviders | Where Enabled | Test-LLMProviderPipeline" -ForegroundColor Cyan
            Write-Host "  Get-LLMProviders -EnabledOnly | Select Name, Description" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Batch operations:" -ForegroundColor Yellow
            Write-Host "  Enable-LLMProvider -Name 'openai', 'anthropic'" -ForegroundColor Cyan
            Write-Host "  Test-LLMProvider -All -EnabledOnly" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Advanced usage:" -ForegroundColor Yellow
            Write-Host "  Set-LLMProvider -Name openai -Model gpt-4" -ForegroundColor Cyan
            Write-Host "  Get-LLMProviders -Format Json | Out-File providers.json" -ForegroundColor Cyan
        }
    }
    
    Write-Host ""
    Write-Host "For detailed help on any command, use: Get-Help <command> -Full" -ForegroundColor Gray
}

# Create custom PowerShell aliases beyond the basic ones
New-Alias -Name 'llm-help' -Value 'Get-LLMHelp' -Force -ErrorAction SilentlyContinue
New-Alias -Name 'llm-test' -Value 'Test-LLMProvider' -Force -ErrorAction SilentlyContinue
New-Alias -Name 'llm-config' -Value 'Edit-LLMConfig' -Force -ErrorAction SilentlyContinue

# Export functions
Export-ModuleMember -Function @(
    'ConvertTo-LLMProviderObject',
    'Format-LLMProviderList',
    'Test-LLMProviderPipeline',
    'Get-LLMHelp'
) -Alias @(
    'llm-help',
    'llm-test',
    'llm-config'
)