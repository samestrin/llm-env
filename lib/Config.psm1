#Requires -Version 5.1
<#
.SYNOPSIS
    Configuration loading system for LLM Environment Manager
.DESCRIPTION
    Implements configuration loading with proper precedence, caching,
    and fallback to built-in defaults. Handles multiple configuration sources.
.NOTES
    Compatible with PowerShell 5.1+ and 7+
#>

Set-StrictMode -Version Latest

# Import required modules
if (Get-Module -ListAvailable -Name IniParser) {
    Import-Module IniParser
} else {
    # Load local module
    $iniParserPath = Join-Path $PSScriptRoot 'IniParser.psm1'
    if (Test-Path $iniParserPath) {
        Import-Module $iniParserPath -Force
    }
}

# Configuration cache variables
$script:ConfigCache = $null
$script:ConfigCacheTime = $null  
$script:ConfigCacheTimeout = 300  # 5 minutes in seconds
$script:ConfigWatcher = $null

function Get-LLMConfiguration {
    <#
    .SYNOPSIS
        Gets the complete LLM configuration with proper precedence
    .DESCRIPTION
        Loads configuration from multiple sources in precedence order:
        1. User configuration file (highest precedence)
        2. System configuration files
        3. Built-in defaults (lowest precedence)
    .PARAMETER Force
        Force reload from disk, ignoring cache
    .PARAMETER ConfigPath
        Specific configuration file path to load
    .OUTPUTS
        [LLMConfiguration] Complete configuration object
    .EXAMPLE
        $config = Get-LLMConfiguration
    .EXAMPLE
        $config = Get-LLMConfiguration -Force
    #>
    [CmdletBinding()]
    [OutputType([LLMConfiguration])]
    param(
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [string]$ConfigPath
    )
    
    # Check cache validity
    if (-not $Force -and $script:ConfigCache -and $script:ConfigCacheTime) {
        $cacheAge = (Get-Date) - $script:ConfigCacheTime
        if ($cacheAge.TotalSeconds -lt $script:ConfigCacheTimeout) {
            Write-Verbose "Returning cached configuration (age: $([math]::Round($cacheAge.TotalSeconds, 1))s)"
            return $script:ConfigCache
        }
    }
    
    try {
        Write-Verbose "Loading LLM configuration..."
        
        # Start with built-in defaults
        $baseConfig = Get-LLMBuiltinConfiguration
        Write-Verbose "Loaded built-in configuration with $($baseConfig.Count()) providers"
        
        # Load configuration files in precedence order
        $searchPaths = if ($ConfigPath) { @($ConfigPath) } else { Get-LLMConfigSearchPaths }
        $loadedConfigs = @()
        
        foreach ($path in $searchPaths) {
            if (Test-Path $path) {
                try {
                    Write-Verbose "Loading configuration from: $path"
                    $configData = ConvertFrom-IniFile -Path $path
                    $config = ConvertTo-LLMConfiguration -ConfigData $configData -ConfigPath $path
                    $loadedConfigs += $config
                    Write-Verbose "Loaded configuration from $path with $($config.Count()) providers"
                }
                catch {
                    Write-Warning "Failed to load configuration from '$path': $_"
                }
            }
            else {
                Write-Verbose "Configuration file not found: $path"
            }
        }
        
        # Merge configurations with precedence (later configs override earlier ones)
        $finalConfig = $baseConfig
        foreach ($config in $loadedConfigs) {
            $finalConfig = Merge-LLMConfiguration -BaseConfiguration $finalConfig -OverrideConfiguration $config
        }
        
        # Update cache
        $script:ConfigCache = $finalConfig
        $script:ConfigCacheTime = Get-Date
        
        Write-Verbose "Final configuration loaded with $($finalConfig.Count()) providers"
        return $finalConfig
    }
    catch {
        Write-Error "Failed to load LLM configuration: $_"
        throw
    }
}

function Get-LLMBuiltinConfiguration {
    <#
    .SYNOPSIS
        Gets the built-in default configuration
    .DESCRIPTION
        Returns the default configuration bundled with the module.
        This serves as the fallback when no user configuration is found.
    .OUTPUTS
        [LLMConfiguration] Built-in default configuration
    #>
    [CmdletBinding()]
    [OutputType([LLMConfiguration])]
    param()
    
    try {
        # Try to load bundled configuration file first
        $builtinConfigPath = Join-Path $script:ModuleRoot 'config/llm-env.conf'
        if (Test-Path $builtinConfigPath) {
            Write-Verbose "Loading built-in configuration from: $builtinConfigPath"
            $configData = ConvertFrom-IniFile -Path $builtinConfigPath
            return ConvertTo-LLMConfiguration -ConfigData $configData -ConfigPath $builtinConfigPath
        }
        
        # Fallback to hardcoded defaults if bundled file is missing
        Write-Verbose "Using hardcoded built-in configuration"
        return Get-LLMHardcodedDefaults
    }
    catch {
        Write-Warning "Failed to load built-in configuration, using hardcoded defaults: $_"
        return Get-LLMHardcodedDefaults
    }
}

function Get-LLMHardcodedDefaults {
    <#
    .SYNOPSIS
        Gets hardcoded default configuration as absolute fallback
    .DESCRIPTION
        Returns a minimal hardcoded configuration when all other sources fail
    .OUTPUTS
        [LLMConfiguration] Hardcoded default configuration
    #>
    [CmdletBinding()]
    [OutputType([LLMConfiguration])]
    param()
    
    $config = New-LLMConfiguration
    
    # Add essential providers with hardcoded defaults
    $defaultProviders = @{
        'openai' = @{
            base_url = 'https://api.openai.com/v1'
            api_key_var = 'LLM_OPENAI_API_KEY'
            default_model = 'gpt-4'
            description = 'OpenAI GPT models'
            enabled = 'true'
        }
        'anthropic' = @{
            base_url = 'https://api.anthropic.com/v1'
            api_key_var = 'LLM_ANTHROPIC_API_KEY'  
            default_model = 'claude-3-5-sonnet-20241022'
            description = 'Anthropic Claude models'
            enabled = 'false'
        }
    }
    
    foreach ($providerName in $defaultProviders.Keys) {
        try {
            $config.AddProvider($providerName, $defaultProviders[$providerName])
            Write-Verbose "Added hardcoded default provider: $providerName"
        }
        catch {
            Write-Warning "Failed to add hardcoded provider '$providerName': $_"
        }
    }
    
    return $config
}

function ConvertTo-LLMConfiguration {
    <#
    .SYNOPSIS
        Converts INI configuration data to LLMConfiguration object
    .DESCRIPTION
        Takes hashtable data from INI parsing and converts it to structured
        LLMConfiguration object with validated providers
    .PARAMETER ConfigData
        Hashtable from INI file parsing
    .PARAMETER ConfigPath
        Path to the source configuration file
    .OUTPUTS
        [LLMConfiguration] Configuration object
    #>
    [CmdletBinding()]
    [OutputType([LLMConfiguration])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ConfigData,
        
        [Parameter()]
        [string]$ConfigPath
    )
    
    try {
        $config = if ($ConfigPath) { 
            New-LLMConfiguration -ConfigPath $ConfigPath 
        } else { 
            New-LLMConfiguration 
        }
        
        # Process each section as a provider
        foreach ($sectionName in $ConfigData.Keys) {
            $sectionData = $ConfigData[$sectionName]
            
            # Skip non-hashtable entries (global settings, comments)
            if ($sectionData -isnot [hashtable]) {
                Write-Verbose "Skipping non-section entry: $sectionName"
                continue
            }
            
            # Skip comment sections
            if ($sectionName.StartsWith('_comment_')) {
                continue
            }
            
            try {
                # Validate required provider fields
                $providerData = @{}
                foreach ($key in $sectionData.Keys) {
                    if (-not $key.StartsWith('_comment_')) {
                        $providerData[$key] = $sectionData[$key]
                    }
                }
                
                if ($providerData.Count -eq 0) {
                    Write-Warning "Empty provider section: $sectionName"
                    continue
                }
                
                # Add provider to configuration
                $config.AddProvider($sectionName, $providerData)
                Write-Verbose "Added provider: $sectionName"
            }
            catch {
                Write-Warning "Failed to add provider '$sectionName': $_"
            }
        }
        
        return $config
    }
    catch {
        throw "Failed to convert configuration data: $_"
    }
}

function Merge-LLMConfiguration {
    <#
    .SYNOPSIS
        Merges two LLMConfiguration objects with precedence
    .DESCRIPTION
        Combines configurations with the override configuration taking precedence.
        Providers in the override config will replace those in the base config.
    .PARAMETER BaseConfiguration
        Base configuration (lower precedence)
    .PARAMETER OverrideConfiguration  
        Override configuration (higher precedence)
    .OUTPUTS
        [LLMConfiguration] Merged configuration
    #>
    [CmdletBinding()]
    [OutputType([LLMConfiguration])]
    param(
        [Parameter(Mandatory = $true)]
        [LLMConfiguration]$BaseConfiguration,
        
        [Parameter(Mandatory = $true)]
        [LLMConfiguration]$OverrideConfiguration
    )
    
    try {
        # Start with base configuration
        $merged = New-LLMConfiguration
        
        # Copy all providers from base
        foreach ($provider in $BaseConfiguration.GetAllProviders()) {
            $merged.AddProvider($provider)
        }
        
        # Override with providers from override configuration
        foreach ($provider in $OverrideConfiguration.GetAllProviders()) {
            if ($merged.HasProvider($provider.Name)) {
                Write-Verbose "Overriding provider: $($provider.Name)"
                $merged.RemoveProvider($provider.Name)
            } else {
                Write-Verbose "Adding new provider: $($provider.Name)"  
            }
            $merged.AddProvider($provider)
        }
        
        # Use the most recent configuration path
        if ($OverrideConfiguration.ConfigPath) {
            $merged.ConfigPath = $OverrideConfiguration.ConfigPath
        } elseif ($BaseConfiguration.ConfigPath) {
            $merged.ConfigPath = $BaseConfiguration.ConfigPath
        }
        
        return $merged
    }
    catch {
        throw "Failed to merge configurations: $_"
    }
}

function Save-LLMConfiguration {
    <#
    .SYNOPSIS
        Saves LLMConfiguration to file
    .DESCRIPTION
        Converts LLMConfiguration object to INI format and saves to file
    .PARAMETER Configuration
        Configuration object to save
    .PARAMETER Path
        Output file path
    .PARAMETER Backup
        Create backup of existing file before overwriting
    .OUTPUTS
        [void]
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [LLMConfiguration]$Configuration,
        
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter()]
        [switch]$Backup
    )
    
    try {
        # Ensure directory exists
        $directory = Split-Path $Path -Parent
        if ($directory -and -not (Test-Path $directory)) {
            New-LLMDirectory -Path $directory -Force | Out-Null
        }
        
        # Create backup if requested and file exists
        if ($Backup -and (Test-Path $Path)) {
            $backupPath = "$Path.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Copy-Item $Path $backupPath
            Write-Verbose "Created backup: $backupPath"
        }
        
        # Convert configuration to hashtable
        $configHash = @{}
        foreach ($provider in $Configuration.GetAllProviders()) {
            $configHash[$provider.Name] = $provider.ToHashtable()
            # Remove the 'name' key as it's redundant in INI sections
            $configHash[$provider.Name].Remove('name')
        }
        
        # Convert to INI and save
        ConvertTo-IniFile -InputObject $configHash -Path $Path
        
        # Clear cache to force reload
        $script:ConfigCache = $null
        $script:ConfigCacheTime = $null
        
        Write-Verbose "Configuration saved to: $Path"
    }
    catch {
        throw "Failed to save configuration to '$Path': $_"
    }
}

function Clear-LLMConfigurationCache {
    <#
    .SYNOPSIS
        Clears the configuration cache
    .DESCRIPTION
        Forces the next configuration request to reload from disk
    .OUTPUTS
        [void]
    #>
    [CmdletBinding()]
    param()
    
    $script:ConfigCache = $null
    $script:ConfigCacheTime = $null
    Write-Verbose "Configuration cache cleared"
}

function Test-LLMConfiguration {
    <#
    .SYNOPSIS
        Validates LLM configuration for correctness
    .DESCRIPTION
        Performs comprehensive validation of configuration object
    .PARAMETER Configuration
        Configuration object to validate
    .OUTPUTS
        [PSCustomObject] Validation results
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [LLMConfiguration]$Configuration
    )
    
    $result = [PSCustomObject]@{
        IsValid = $true
        Errors = @()
        Warnings = @()
        ProviderCount = $Configuration.Count()
        EnabledProviderCount = ($Configuration.GetEnabledProviders()).Count
    }
    
    try {
        # Check for at least one provider
        if ($Configuration.Count() -eq 0) {
            $result.Errors += "No providers defined in configuration"
            $result.IsValid = $false
        }
        
        # Check for at least one enabled provider
        if (($Configuration.GetEnabledProviders()).Count -eq 0) {
            $result.Warnings += "No providers are enabled"
        }
        
        # Validate each provider
        foreach ($provider in $Configuration.GetAllProviders()) {
            if (-not $provider.IsValid()) {
                $result.Errors += "Invalid provider: $($provider.Name)"
                $result.IsValid = $false
            }
            
            # Check for API key availability
            $apiKey = Get-LLMEnvironmentVariable -Name $provider.ApiKeyVar
            if ([string]::IsNullOrWhiteSpace($apiKey)) {
                $result.Warnings += "API key not set for provider: $($provider.Name) (expected: $($provider.ApiKeyVar))"
            }
        }
    }
    catch {
        $result.Errors += "Validation error: $_"
        $result.IsValid = $false
    }
    
    return $result
}

# Export functions
Export-ModuleMember -Function @(
    'Get-LLMConfiguration',
    'Get-LLMBuiltinConfiguration',
    'ConvertTo-LLMConfiguration',
    'Merge-LLMConfiguration', 
    'Save-LLMConfiguration',
    'Clear-LLMConfigurationCache',
    'Test-LLMConfiguration'
)