#Requires -Version 5.1
<#
.SYNOPSIS
    LLM Environment Manager PowerShell Module
.DESCRIPTION
    PowerShell module for managing LLM environment variables and provider configurations.
    Provides full feature parity with the bash version while integrating seamlessly with Windows environments.
.NOTES
    Version: 1.1.0
    Author: Sam Estrin
#>

# Set strict mode for better error handling
Set-StrictMode -Version Latest

# Module-level variables
$script:ModuleRoot = $PSScriptRoot
# Note: Configuration caching is handled by Config.psm1

# Import required modules and functions
$libPath = Join-Path $script:ModuleRoot 'lib'

# Load core modules in dependency order (classes now in Config.psm1)
$moduleLoadOrder = @(
    'WindowsIntegration.psm1', 
    'IniParser.psm1',
    'Config.psm1',           # Contains PowerShell classes  
    'Providers.psm1',
    'PowerShellEnhancements.psm1',
    'WindowsUI.psm1'
)

foreach ($module in $moduleLoadOrder) {
    $modulePath = Join-Path $libPath $module
    if (Test-Path $modulePath) {
        try {
            # Import all modules using the module approach
            Import-Module $modulePath -Force -DisableNameChecking
            Write-Verbose "Loaded module: $module"
        }
        catch {
            Write-Error "Failed to load module $module`: $_"
            throw
        }
    }
    else {
        Write-Warning "Module file not found: $modulePath"
    }
}

# Load cmdlet functions
$cmdletPath = Join-Path $script:ModuleRoot 'cmdlets'
if (Test-Path $cmdletPath) {
    Get-ChildItem -Path $cmdletPath -Filter '*.ps1' | ForEach-Object {
        try {
            . $_.FullName
            Write-Verbose "Loaded cmdlet: $($_.Name)"
        }
        catch {
            Write-Error "Failed to load cmdlet $($_.Name): $_"
            throw
        }
    }
}

# Module initialization
function Initialize-LLMEnvironmentModule {
    [CmdletBinding()]
    param()
    
    Write-Verbose "Initializing LLM Environment Manager PowerShell Module v1.1.0"
    
    # Ensure required directories exist
    try {
        if (Get-Command Get-LLMConfigDirectory -ErrorAction SilentlyContinue) {
            $configDir = Get-LLMConfigDirectory
            if (-not (Test-Path $configDir)) {
                New-Item -Path $configDir -ItemType Directory -Force | Out-Null
                Write-Verbose "Created configuration directory: $configDir"
            }
        }
    }
    catch {
        Write-Warning "Could not create configuration directory: $_"
    }
    
    # Load initial configuration to cache
    try {
        if (Get-Command Get-LLMConfiguration -ErrorAction SilentlyContinue) {
            $null = Get-LLMConfiguration  # Load to cache in Config.psm1
            Write-Verbose "Configuration loaded successfully"
        }
    }
    catch {
        Write-Warning "Could not load initial configuration: $_"
    }
}

# Initialize module after all functions are loaded
# This will be called at the end of the module

# Create aliases for bash compatibility
New-Alias -Name 'llm-set' -Value 'Set-LLMProvider' -Force
New-Alias -Name 'llm-unset' -Value 'Clear-LLMProvider' -Force  
New-Alias -Name 'llm-list' -Value 'Get-LLMProviders' -Force
New-Alias -Name 'llm-show' -Value 'Show-LLMProvider' -Force

# Export module members - cmdlets and essential library functions
Export-ModuleMember -Function @(
    # Main cmdlets
    'Set-LLMProvider',
    'Clear-LLMProvider',
    'Get-LLMProviders', 
    'Show-LLMProvider',
    'Initialize-LLMConfig',
    'Edit-LLMConfig',
    'Add-LLMProvider',
    'Remove-LLMProvider',
    'Test-LLMProvider',
    'Backup-LLMConfig',
    'Restore-LLMConfig',
    'Enable-LLMProvider',
    'Disable-LLMProvider',
    
    # Essential library functions needed by cmdlets
    'Get-LLMConfiguration',
    'Get-LLMConfigDirectory',
    'Get-LLMConfigFilePath',
    'Get-LLMProvider',
    'Get-LLMEnvironmentVariable',
    'Set-LLMEnvironmentVariable',
    'Clear-LLMConfigurationCache',
    'New-LLMConfiguration',
    'Get-LLMConfigSearchPaths'
) -Alias @(
    'llm-set',
    'llm-unset', 
    'llm-list',
    'llm-show'
)

# Initialize module after all components are loaded
Initialize-LLMEnvironmentModule

Write-Verbose "LLM Environment Manager PowerShell Module loaded successfully"