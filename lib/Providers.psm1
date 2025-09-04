#Requires -Version 5.1
<#
.SYNOPSIS
    Provider registry and management for LLM Environment Manager
.DESCRIPTION
    Provides provider registry functionality with validation, filtering,
    lookup functions, and provider lifecycle management.
.NOTES
    Compatible with PowerShell 5.1+ and 7+
#>

Set-StrictMode -Version Latest

# Provider registry cache
$script:ProviderRegistry = $null
$script:RegistryLastUpdate = $null

function Get-LLMProviderRegistry {
    <#
    .SYNOPSIS
        Gets the current provider registry
    .DESCRIPTION
        Returns the provider registry, loading from configuration if needed
    .PARAMETER Force
        Force reload from configuration
    .OUTPUTS
        [LLMConfiguration] Provider registry configuration
    #>
    [CmdletBinding()]
    [OutputType([LLMConfiguration])]
    param(
        [Parameter()]
        [switch]$Force
    )
    
    if ($Force -or -not $script:ProviderRegistry) {
        $script:ProviderRegistry = Get-LLMConfiguration -Force:$Force
        $script:RegistryLastUpdate = Get-Date
        Write-Verbose "Provider registry loaded/refreshed"
    }
    
    return $script:ProviderRegistry
}

function Get-LLMProvider {
    <#
    .SYNOPSIS
        Gets a specific provider by name
    .DESCRIPTION
        Retrieves a provider from the registry by name with optional validation
    .PARAMETER Name
        Provider name to retrieve
    .PARAMETER ValidateOnly
        Only return if provider is valid and enabled
    .OUTPUTS
        [LLMProvider] Provider object or null if not found
    .EXAMPLE
        $provider = Get-LLMProvider -Name "openai"
    #>
    [CmdletBinding()]
    [OutputType([LLMProvider])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter()]
        [switch]$ValidateOnly
    )
    
    $registry = Get-LLMProviderRegistry
    $provider = $registry.GetProvider($Name)
    
    if (-not $provider) {
        Write-Verbose "Provider not found: $Name"
        return $null
    }
    
    if ($ValidateOnly) {
        if (-not $provider.IsValid()) {
            Write-Warning "Provider '$Name' is not valid"
            return $null
        }
        
        if (-not $provider.Enabled) {
            Write-Verbose "Provider '$Name' is disabled"
            return $null
        }
    }
    
    return $provider
}

function Get-LLMProviders {
    <#
    .SYNOPSIS
        Gets all providers with optional filtering
    .DESCRIPTION
        Retrieves all providers from the registry with various filtering options
    .PARAMETER EnabledOnly
        Return only enabled providers
    .PARAMETER ValidOnly
        Return only valid providers
    .PARAMETER NamePattern
        Filter by name pattern (wildcard supported)
    .PARAMETER SortBy
        Sort results by property (Name, Description, Enabled)
    .OUTPUTS
        [LLMProvider[]] Array of provider objects
    .EXAMPLE
        $providers = Get-LLMProviders -EnabledOnly
    .EXAMPLE
        $providers = Get-LLMProviders -NamePattern "openai*" -ValidOnly
    #>
    [CmdletBinding()]
    [OutputType([LLMProvider[]])]
    param(
        [Parameter()]
        [switch]$EnabledOnly,
        
        [Parameter()]
        [switch]$ValidOnly,
        
        [Parameter()]
        [string]$NamePattern,
        
        [Parameter()]
        [ValidateSet('Name', 'Description', 'Enabled')]
        [string]$SortBy = 'Name'
    )
    
    $registry = Get-LLMProviderRegistry
    $providers = $registry.GetAllProviders()
    
    # Apply filters
    if ($EnabledOnly) {
        $providers = $providers | Where-Object { $_.Enabled }
    }
    
    if ($ValidOnly) {
        $providers = $providers | Where-Object { $_.IsValid() }
    }
    
    if ($NamePattern) {
        $providers = $providers | Where-Object { $_.Name -like $NamePattern }
    }
    
    # Sort results
    switch ($SortBy) {
        'Name' { $providers = $providers | Sort-Object Name }
        'Description' { $providers = $providers | Sort-Object Description }
        'Enabled' { $providers = $providers | Sort-Object Enabled -Descending, Name }
    }
    
    return $providers
}

function Test-LLMProvider {
    <#
    .SYNOPSIS
        Tests a provider for validity and API connectivity
    .DESCRIPTION
        Performs comprehensive testing of a provider including configuration
        validation, API key availability, and optional connectivity testing
    .PARAMETER Name
        Provider name to test
    .PARAMETER TestConnectivity
        Test actual API connectivity (requires API key)
    .PARAMETER TimeoutSeconds
        Timeout for connectivity tests
    .OUTPUTS
        [PSCustomObject] Test results with detailed information
    .EXAMPLE
        $result = Test-LLMProvider -Name "openai"
    .EXAMPLE
        $result = Test-LLMProvider -Name "openai" -TestConnectivity
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter()]
        [switch]$TestConnectivity,
        
        [Parameter()]
        [int]$TimeoutSeconds = 30
    )
    
    $result = [PSCustomObject]@{
        ProviderName = $Name
        IsValid = $false
        IsEnabled = $false
        HasApiKey = $false
        IsConnectable = $null
        Errors = @()
        Warnings = @()
        Details = @{}
    }
    
    try {
        # Get provider
        $provider = Get-LLMProvider -Name $Name
        if (-not $provider) {
            $result.Errors += "Provider '$Name' not found"
            return $result
        }
        
        # Test basic validity
        $result.IsValid = $provider.IsValid()
        $result.IsEnabled = $provider.Enabled
        $result.Details['BaseUrl'] = $provider.BaseUrl
        $result.Details['ApiKeyVar'] = $provider.ApiKeyVar
        $result.Details['DefaultModel'] = $provider.DefaultModel
        
        if (-not $result.IsValid) {
            $result.Errors += "Provider configuration is invalid"
        }
        
        if (-not $result.IsEnabled) {
            $result.Warnings += "Provider is disabled"
        }
        
        # Test API key availability
        $apiKey = Get-LLMEnvironmentVariable -Name $provider.ApiKeyVar
        $result.HasApiKey = -not [string]::IsNullOrWhiteSpace($apiKey)
        
        if (-not $result.HasApiKey) {
            $result.Warnings += "API key not found in environment variable: $($provider.ApiKeyVar)"
        }
        
        # Test connectivity if requested and API key is available
        if ($TestConnectivity -and $result.HasApiKey) {
            try {
                $connectivityResult = Test-LLMProviderConnectivity -Provider $provider -TimeoutSeconds $TimeoutSeconds
                $result.IsConnectable = $connectivityResult.Success
                $result.Details['ConnectivityTest'] = $connectivityResult
                
                if (-not $connectivityResult.Success) {
                    $result.Errors += "Connectivity test failed: $($connectivityResult.Error)"
                }
            }
            catch {
                $result.IsConnectable = $false
                $result.Errors += "Connectivity test error: $_"
            }
        }
        elseif ($TestConnectivity) {
            $result.IsConnectable = $false
            $result.Warnings += "Cannot test connectivity without API key"
        }
        
    }
    catch {
        $result.Errors += "Provider test error: $_"
    }
    
    return $result
}

function Test-LLMProviderConnectivity {
    <#
    .SYNOPSIS
        Tests actual API connectivity for a provider
    .DESCRIPTION
        Attempts to make a minimal API request to test connectivity
    .PARAMETER Provider
        Provider object to test
    .PARAMETER TimeoutSeconds
        Request timeout in seconds
    .OUTPUTS
        [PSCustomObject] Connectivity test result
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [LLMProvider]$Provider,
        
        [Parameter()]
        [int]$TimeoutSeconds = 30
    )
    
    $result = [PSCustomObject]@{
        Success = $false
        ResponseTime = $null
        StatusCode = $null
        Error = $null
        Details = @{}
    }
    
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $apiKey = Get-LLMEnvironmentVariable -Name $Provider.ApiKeyVar
        
        # Prepare headers
        $headers = @{
            'Authorization' = "Bearer $apiKey"
            'Content-Type' = 'application/json'
            'User-Agent' = 'llm-env-powershell/1.1.0'
        }
        
        # Try to get models endpoint (most providers support this)
        $modelsUrl = $Provider.BaseUrl.TrimEnd('/') + '/models'
        
        $response = Invoke-RestMethod -Uri $modelsUrl -Headers $headers -Method GET -TimeoutSec $TimeoutSeconds -ErrorAction Stop
        
        $stopwatch.Stop()
        $result.Success = $true
        $result.ResponseTime = $stopwatch.ElapsedMilliseconds
        $result.StatusCode = 200
        $result.Details['ModelsCount'] = if ($response.data) { $response.data.Count } else { 'Unknown' }
        
    }
    catch [System.Net.WebException] {
        $stopwatch.Stop()
        $result.ResponseTime = $stopwatch.ElapsedMilliseconds
        $result.Error = $_.Exception.Message
        
        if ($_.Exception.Response) {
            $result.StatusCode = [int]$_.Exception.Response.StatusCode
        }
    }
    catch {
        $stopwatch.Stop()
        $result.ResponseTime = $stopwatch.ElapsedMilliseconds
        $result.Error = $_.Exception.Message
    }
    
    return $result
}

function Add-LLMProvider {
    <#
    .SYNOPSIS
        Adds a new provider to the registry
    .DESCRIPTION
        Creates and adds a new provider to the configuration registry
    .PARAMETER Name
        Provider name (must be unique)
    .PARAMETER BaseUrl
        API base URL
    .PARAMETER ApiKeyVar
        Environment variable name for API key
    .PARAMETER DefaultModel
        Default model name
    .PARAMETER Description
        Provider description
    .PARAMETER Enabled
        Whether provider is enabled (default: true)
    .PARAMETER AdditionalProperties
        Additional provider properties as hashtable
    .PARAMETER SaveToConfig
        Save changes to configuration file
    .OUTPUTS
        [LLMProvider] Created provider object
    .EXAMPLE
        Add-LLMProvider -Name "myapi" -BaseUrl "https://api.example.com/v1" -ApiKeyVar "MY_API_KEY"
    #>
    [CmdletBinding()]
    [OutputType([LLMProvider])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl,
        
        [Parameter(Mandatory = $true)]
        [string]$ApiKeyVar,
        
        [Parameter()]
        [string]$DefaultModel,
        
        [Parameter()]
        [string]$Description,
        
        [Parameter()]
        [bool]$Enabled = $true,
        
        [Parameter()]
        [hashtable]$AdditionalProperties = @{},
        
        [Parameter()]
        [switch]$SaveToConfig
    )
    
    try {
        $registry = Get-LLMProviderRegistry
        
        # Check if provider already exists
        if ($registry.HasProvider($Name)) {
            throw "Provider '$Name' already exists"
        }
        
        # Create provider data
        $providerData = @{
            base_url = $BaseUrl
            api_key_var = $ApiKeyVar
            enabled = $Enabled.ToString().ToLower()
        }
        
        if ($DefaultModel) { $providerData['default_model'] = $DefaultModel }
        if ($Description) { $providerData['description'] = $Description }
        
        # Add additional properties
        foreach ($key in $AdditionalProperties.Keys) {
            $providerData[$key] = $AdditionalProperties[$key]
        }
        
        # Add to registry
        $registry.AddProvider($Name, $providerData)
        $provider = $registry.GetProvider($Name)
        
        # Save to configuration file if requested
        if ($SaveToConfig) {
            $configPath = Get-LLMConfigFilePath
            Save-LLMConfiguration -Configuration $registry -Path $configPath -Backup
            Write-Verbose "Provider '$Name' saved to configuration file"
        }
        
        # Clear cache to ensure fresh data
        $script:ProviderRegistry = $registry
        Clear-LLMConfigurationCache
        
        Write-Verbose "Provider '$Name' added successfully"
        return $provider
    }
    catch {
        throw "Failed to add provider '$Name': $_"
    }
}

function Remove-LLMProvider {
    <#
    .SYNOPSIS
        Removes a provider from the registry
    .DESCRIPTION
        Removes a provider from the configuration registry
    .PARAMETER Name
        Provider name to remove
    .PARAMETER SaveToConfig
        Save changes to configuration file
    .PARAMETER Force
        Remove without confirmation
    .OUTPUTS
        [void]
    .EXAMPLE
        Remove-LLMProvider -Name "oldapi" -SaveToConfig
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter()]
        [switch]$SaveToConfig,
        
        [Parameter()]
        [switch]$Force
    )
    
    try {
        $registry = Get-LLMProviderRegistry
        
        # Check if provider exists
        if (-not $registry.HasProvider($Name)) {
            throw "Provider '$Name' not found"
        }
        
        if ($PSCmdlet.ShouldProcess($Name, 'Remove LLM Provider')) {
            # Remove from registry
            $registry.RemoveProvider($Name)
            
            # Save to configuration file if requested
            if ($SaveToConfig) {
                $configPath = Get-LLMConfigFilePath
                Save-LLMConfiguration -Configuration $registry -Path $configPath -Backup
                Write-Verbose "Provider '$Name' removed from configuration file"
            }
            
            # Clear cache
            $script:ProviderRegistry = $registry
            Clear-LLMConfigurationCache
            
            Write-Verbose "Provider '$Name' removed successfully"
        }
    }
    catch {
        throw "Failed to remove provider '$Name': $_"
    }
}

function Set-LLMProviderEnabled {
    <#
    .SYNOPSIS
        Enables or disables a provider
    .DESCRIPTION
        Changes the enabled status of a provider in the registry
    .PARAMETER Name
        Provider name
    .PARAMETER Enabled
        Whether to enable (true) or disable (false) the provider
    .PARAMETER SaveToConfig
        Save changes to configuration file
    .OUTPUTS
        [void]
    .EXAMPLE
        Set-LLMProviderEnabled -Name "openai" -Enabled $false
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [bool]$Enabled,
        
        [Parameter()]
        [switch]$SaveToConfig
    )
    
    try {
        $registry = Get-LLMProviderRegistry
        $provider = $registry.GetProvider($Name)
        
        if (-not $provider) {
            throw "Provider '$Name' not found"
        }
        
        $provider.Enabled = $Enabled
        $status = if ($Enabled) { 'enabled' } else { 'disabled' }
        
        # Save to configuration file if requested
        if ($SaveToConfig) {
            $configPath = Get-LLMConfigFilePath
            Save-LLMConfiguration -Configuration $registry -Path $configPath -Backup
            Write-Verbose "Provider '$Name' $status and saved to configuration file"
        }
        
        # Update cache
        $script:ProviderRegistry = $registry
        
        Write-Verbose "Provider '$Name' $status"
    }
    catch {
        throw "Failed to set provider '$Name' enabled status: $_"
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-LLMProviderRegistry',
    'Get-LLMProvider',
    'Get-LLMProviders',
    'Test-LLMProvider',
    'Test-LLMProviderConnectivity',
    'Add-LLMProvider',
    'Remove-LLMProvider', 
    'Set-LLMProviderEnabled'
)