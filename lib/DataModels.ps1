#Requires -Version 5.1
<#
.SYNOPSIS
    Core data structures and models for LLM Environment Manager
.DESCRIPTION
    Defines PowerShell classes and data structures for provider data,
    configuration management, and data validation functions.
.NOTES
    Compatible with PowerShell 5.1+ and 7+
#>

# Provider data model class (compatible with both PS 5.1 and 7+)
if ($PSVersionTable.PSVersion.Major -ge 5) {
    class LLMProvider {
        [string]$Name
        [string]$BaseUrl
        [string]$ApiKeyVar
        [string]$DefaultModel
        [string]$Description
        [bool]$Enabled
        [hashtable]$AdditionalProperties
        
        LLMProvider() {
            $this.AdditionalProperties = @{}
            $this.Enabled = $true
        }
        
        LLMProvider([hashtable]$Properties) {
            $this.AdditionalProperties = @{}
            $this.Enabled = $true
            
            foreach ($key in $Properties.Keys) {
                switch ($key.ToLower()) {
                    'name' { $this.Name = $Properties[$key] }
                    'base_url' { $this.BaseUrl = $Properties[$key] }
                    'api_key_var' { $this.ApiKeyVar = $Properties[$key] }  
                    'default_model' { $this.DefaultModel = $Properties[$key] }
                    'description' { $this.Description = $Properties[$key] }
                    'enabled' { 
                        $this.Enabled = if ($Properties[$key] -is [string]) {
                            $Properties[$key] -eq 'true'
                        } else {
                            [bool]$Properties[$key]
                        }
                    }
                    default { 
                        $this.AdditionalProperties[$key] = $Properties[$key] 
                    }
                }
            }
        }
        
        [hashtable] ToHashtable() {
            $result = @{
                'name' = $this.Name
                'base_url' = $this.BaseUrl
                'api_key_var' = $this.ApiKeyVar
                'default_model' = $this.DefaultModel  
                'description' = $this.Description
                'enabled' = $this.Enabled.ToString().ToLower()
            }
            
            foreach ($key in $this.AdditionalProperties.Keys) {
                $result[$key] = $this.AdditionalProperties[$key]
            }
            
            return $result
        }
        
        [bool] IsValid() {
            return -not [string]::IsNullOrWhiteSpace($this.Name) -and
                   -not [string]::IsNullOrWhiteSpace($this.BaseUrl) -and
                   -not [string]::IsNullOrWhiteSpace($this.ApiKeyVar)
        }
        
        [string] ToString() {
            $status = if ($this.Enabled) { 'enabled' } else { 'disabled' }
            return "$($this.Name) ($status): $($this.BaseUrl)"
        }
    }
}

# Configuration data structure for PS 5.1 compatibility
class LLMConfiguration {
    [hashtable]$Providers
    [string]$ConfigPath
    [datetime]$LastModified
    [hashtable]$Metadata
    
    LLMConfiguration() {
        $this.Providers = @{}
        $this.Metadata = @{}
        $this.LastModified = Get-Date
    }
    
    LLMConfiguration([string]$ConfigPath) {
        $this.Providers = @{}
        $this.Metadata = @{}
        $this.ConfigPath = $ConfigPath
        if (Test-Path $ConfigPath) {
            $this.LastModified = (Get-Item $ConfigPath).LastWriteTime
        } else {
            $this.LastModified = Get-Date
        }
    }
    
    [void] AddProvider([LLMProvider]$Provider) {
        if ($Provider.IsValid()) {
            $this.Providers[$Provider.Name] = $Provider
        } else {
            throw "Invalid provider: $($Provider.Name)"
        }
    }
    
    [void] AddProvider([string]$Name, [hashtable]$Properties) {
        $Properties['name'] = $Name
        $provider = [LLMProvider]::new($Properties)
        $this.AddProvider($provider)
    }
    
    [LLMProvider] GetProvider([string]$Name) {
        if ($this.Providers.ContainsKey($Name)) {
            return $this.Providers[$Name]
        }
        return $null
    }
    
    [LLMProvider[]] GetEnabledProviders() {
        return $this.Providers.Values | Where-Object { $_.Enabled }
    }
    
    [LLMProvider[]] GetAllProviders() {
        return $this.Providers.Values
    }
    
    [bool] HasProvider([string]$Name) {
        return $this.Providers.ContainsKey($Name)
    }
    
    [void] RemoveProvider([string]$Name) {
        if ($this.Providers.ContainsKey($Name)) {
            $this.Providers.Remove($Name)
        }
    }
    
    [hashtable] ToHashtable() {
        $result = @{}
        foreach ($providerName in $this.Providers.Keys) {
            $result[$providerName] = $this.Providers[$providerName].ToHashtable()
        }
        return $result
    }
    
    [int] Count() {
        return $this.Providers.Count
    }
}

# Environment variable data structure
class LLMEnvironmentVariable {
    [string]$Name
    [string]$Value
    [string]$OriginalValue
    [bool]$WasSet
    
    LLMEnvironmentVariable([string]$Name, [string]$Value) {
        $this.Name = $Name
        $this.Value = $Value
        $this.OriginalValue = [System.Environment]::GetEnvironmentVariable($Name)
        $this.WasSet = -not [string]::IsNullOrEmpty($this.OriginalValue)
    }
    
    [void] Set() {
        [System.Environment]::SetEnvironmentVariable($this.Name, $this.Value, [System.EnvironmentVariableTarget]::Process)
    }
    
    [void] Restore() {
        if ($this.WasSet) {
            [System.Environment]::SetEnvironmentVariable($this.Name, $this.OriginalValue, [System.EnvironmentVariableTarget]::Process)
        } else {
            [System.Environment]::SetEnvironmentVariable($this.Name, $null, [System.EnvironmentVariableTarget]::Process)
        }
    }
    
    [string] ToString() {
        return "$($this.Name)=$($this.Value)"
    }
}

# Data validation functions
function Test-LLMProviderData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ProviderData
    )
    
    $requiredFields = @('name', 'base_url', 'api_key_var')
    $missingFields = @()
    
    foreach ($field in $requiredFields) {
        if (-not $ProviderData.ContainsKey($field) -or [string]::IsNullOrWhiteSpace($ProviderData[$field])) {
            $missingFields += $field
        }
    }
    
    if ($missingFields.Count -gt 0) {
        throw "Provider data missing required fields: $($missingFields -join ', ')"
    }
    
    # Validate URL format
    try {
        $null = [System.Uri]::new($ProviderData.base_url)
    }
    catch {
        throw "Invalid base_url format: $($ProviderData.base_url)"
    }
    
    # Validate API key variable name
    if ($ProviderData.api_key_var -notmatch '^[A-Z][A-Z0-9_]*$') {
        Write-Warning "API key variable name should follow convention: uppercase letters, numbers, and underscores"
    }
    
    return $true
}

function ConvertTo-LLMProvider {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Properties
    )
    
    $Properties['name'] = $Name
    
    try {
        Test-LLMProviderData -ProviderData $Properties
        return [LLMProvider]::new($Properties)
    }
    catch {
        Write-Error "Failed to create provider '$Name': $_"
        throw
    }
}

function New-LLMConfiguration {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ConfigPath
    )
    
    if ($ConfigPath) {
        return [LLMConfiguration]::new($ConfigPath)
    } else {
        return [LLMConfiguration]::new()
    }
}

# Export functions and classes
Export-ModuleMember -Function @(
    'Test-LLMProviderData',
    'ConvertTo-LLMProvider', 
    'New-LLMConfiguration'
)