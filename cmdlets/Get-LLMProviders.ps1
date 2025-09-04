#Requires -Version 5.1
<#
.SYNOPSIS
    Lists available LLM providers with filtering options
.DESCRIPTION
    Equivalent to 'llm-env list'. Shows all configured providers with their
    status, configuration, and availability information.
.PARAMETER EnabledOnly
    Show only enabled providers
.PARAMETER ValidOnly
    Show only providers with valid configurations
.PARAMETER NamePattern
    Filter providers by name pattern (supports wildcards)
.PARAMETER Format
    Output format: Table (default), List, Json, or CSV
.PARAMETER IncludeApiKeyStatus
    Include API key availability status in output
.OUTPUTS
    [PSCustomObject[]] Array of provider information objects
.EXAMPLE
    Get-LLMProviders
.EXAMPLE
    Get-LLMProviders -EnabledOnly -IncludeApiKeyStatus
.EXAMPLE
    Get-LLMProviders -NamePattern "openai*" -Format List
.EXAMPLE
    llm-list
#>
function Get-LLMProviders {
    [CmdletBinding()]
    [Alias('llm-list')]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter()]
        [switch]$EnabledOnly,
        
        [Parameter()]
        [switch]$ValidOnly,
        
        [Parameter()]
        [string]$NamePattern,
        
        [Parameter()]
        [ValidateSet('Table', 'List', 'Json', 'CSV')]
        [string]$Format = 'Table',
        
        [Parameter()]
        [switch]$IncludeApiKeyStatus
    )
    
    try {
        Write-Verbose "Retrieving LLM providers with filters - EnabledOnly: $EnabledOnly, ValidOnly: $ValidOnly"
        
        # Get providers from registry
        $configuration = Get-LLMConfiguration
        $allProviders = $configuration.GetAllProviders()
        
        # Apply filters
        $providers = $allProviders
        if ($EnabledOnly) {
            $providers = $providers | Where-Object { $_.Enabled }
        }
        
        if ($ValidOnly) {
            $providers = $providers | Where-Object { $_.IsValid() }
        }
        
        if ($NamePattern) {
            $providers = $providers | Where-Object { $_.Name -like $NamePattern }
        }
        
        if ($providers.Count -eq 0) {
            Write-Warning "No providers found matching the specified criteria"
            return @()
        }
        
        # Build output objects
        $outputObjects = @()
        $currentProvider = Get-LLMEnvironmentVariable -Name 'LLM_PROVIDER'
        
        foreach ($provider in $providers) {
            $obj = [PSCustomObject]@{
                Name = $provider.Name
                Status = if ($provider.Enabled) { 'Enabled' } else { 'Disabled' }
                BaseUrl = $provider.BaseUrl
                DefaultModel = $provider.DefaultModel
                Description = $provider.Description
                Current = ($provider.Name -eq $currentProvider)
                Valid = $provider.IsValid()
            }
            
            # Add API key status if requested
            if ($IncludeApiKeyStatus) {
                $apiKey = Get-LLMEnvironmentVariable -Name $provider.ApiKeyVar
                $obj | Add-Member -NotePropertyName 'ApiKeyVar' -NotePropertyValue $provider.ApiKeyVar
                $obj | Add-Member -NotePropertyName 'ApiKeySet' -NotePropertyValue (-not [string]::IsNullOrWhiteSpace($apiKey))
            }
            
            # Add additional properties
            if ($provider.AdditionalProperties -and $provider.AdditionalProperties.Count -gt 0) {
                foreach ($key in $provider.AdditionalProperties.Keys) {
                    if ($key -notin @('name', 'base_url', 'api_key_var', 'default_model', 'description', 'enabled')) {
                        $obj | Add-Member -NotePropertyName $key -NotePropertyValue $provider.AdditionalProperties[$key]
                    }
                }
            }
            
            $outputObjects += $obj
        }
        
        # Output based on format
        switch ($Format) {
            'Table' {
                if ($IncludeApiKeyStatus) {
                    $outputObjects | Format-Table -Property Name, 
                        @{Label='Status'; Expression={
                            if ($_.Current) { "Current" } 
                            elseif ($_.Status -eq 'Enabled') { "✓" } 
                            else { "✗" }
                        }; Width=8},
                        @{Label='Valid'; Expression={if ($_.Valid) { "✓" } else { "✗" }}; Width=6},
                        BaseUrl,
                        DefaultModel,
                        @{Label='API Key'; Expression={
                            if ($_.ApiKeySet) { "✓ Set" } else { "✗ Missing" }
                        }; Width=10},
                        Description -AutoSize
                } else {
                    $outputObjects | Format-Table -Property Name,
                        @{Label='Status'; Expression={
                            if ($_.Current) { "Current" } 
                            elseif ($_.Status -eq 'Enabled') { "✓" } 
                            else { "✗" }
                        }; Width=8},
                        @{Label='Valid'; Expression={if ($_.Valid) { "✓" } else { "✗" }}; Width=6},
                        BaseUrl,
                        DefaultModel,
                        Description -AutoSize
                }
            }
            'List' {
                foreach ($obj in $outputObjects) {
                    Write-Host ""
                    Write-Host "Provider: " -NoNewline -ForegroundColor Gray
                    if ($obj.Current) {
                        Write-Host "$($obj.Name) " -NoNewline -ForegroundColor Cyan
                        Write-Host "(Current)" -ForegroundColor Green
                    } else {
                        Write-Host "$($obj.Name)" -ForegroundColor White
                    }
                    Write-Host "  Status: " -NoNewline -ForegroundColor Gray
                    if ($obj.Status -eq 'Enabled') {
                        Write-Host "Enabled" -ForegroundColor Green
                    } else {
                        Write-Host "Disabled" -ForegroundColor Red
                    }
                    Write-Host "  Valid: " -NoNewline -ForegroundColor Gray
                    if ($obj.Valid) {
                        Write-Host "Yes" -ForegroundColor Green  
                    } else {
                        Write-Host "No" -ForegroundColor Red
                    }
                    Write-Host "  Base URL: " -NoNewline -ForegroundColor Gray
                    Write-Host "$($obj.BaseUrl)" -ForegroundColor White
                    Write-Host "  Default Model: " -NoNewline -ForegroundColor Gray
                    Write-Host "$($obj.DefaultModel)" -ForegroundColor White
                    if ($IncludeApiKeyStatus) {
                        Write-Host "  API Key Var: " -NoNewline -ForegroundColor Gray
                        Write-Host "$($obj.ApiKeyVar)" -ForegroundColor White
                        Write-Host "  API Key Set: " -NoNewline -ForegroundColor Gray
                        if ($obj.ApiKeySet) {
                            Write-Host "Yes" -ForegroundColor Green
                        } else {
                            Write-Host "No" -ForegroundColor Red
                        }
                    }
                    if ($obj.Description) {
                        Write-Host "  Description: " -NoNewline -ForegroundColor Gray
                        Write-Host "$($obj.Description)" -ForegroundColor White
                    }
                }
                Write-Host ""
            }
            'Json' {
                $outputObjects | ConvertTo-Json -Depth 3
            }
            'CSV' {
                $outputObjects | ConvertTo-Csv -NoTypeInformation
            }
        }
        
        # Summary information
        if ($Format -eq 'Table' -or $Format -eq 'List') {
            $enabledCount = ($outputObjects | Where-Object { $_.Status -eq 'Enabled' }).Count
            $validCount = ($outputObjects | Where-Object { $_.Valid }).Count
            $currentCount = ($outputObjects | Where-Object { $_.Current }).Count
            
            Write-Host "Summary: " -NoNewline -ForegroundColor Gray
            Write-Host "$($outputObjects.Count) total" -NoNewline -ForegroundColor White
            Write-Host ", " -NoNewline
            Write-Host "$enabledCount enabled" -NoNewline -ForegroundColor Green
            Write-Host ", " -NoNewline
            Write-Host "$validCount valid" -NoNewline -ForegroundColor Cyan
            if ($currentCount -gt 0) {
                Write-Host ", " -NoNewline
                Write-Host "$currentCount current" -NoNewline -ForegroundColor Magenta
            }
            Write-Host ""
        }
        
        return $outputObjects
    }
    catch {
        Write-Error "Failed to retrieve LLM providers: $_"
        throw
    }
}