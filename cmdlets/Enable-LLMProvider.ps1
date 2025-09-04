#Requires -Version 5.1
<#
.SYNOPSIS
    Enables one or more LLM providers
.DESCRIPTION
    Enables specified providers in the configuration, making them available
    for use with Set-LLMProvider.
.PARAMETER Name
    Provider name(s) to enable
.PARAMETER All
    Enable all providers
.PARAMETER SaveToConfig
    Save changes to configuration file (default: true)
.OUTPUTS
    [void]
.EXAMPLE
    Enable-LLMProvider -Name "openai"
.EXAMPLE
    Enable-LLMProvider -Name "openai", "anthropic"
.EXAMPLE
    Enable-LLMProvider -All
#>
function Enable-LLMProvider {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ByName', Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'All')]
        [switch]$All,
        
        [Parameter()]
        [bool]$SaveToConfig = $true
    )
    
    try {
        $providersToEnable = @()
        
        if ($All) {
            Write-Verbose "Enabling all providers"
            $allProviders = Get-LLMProviders
            $providersToEnable = $allProviders | Where-Object { -not $_.Enabled }
            
            if ($providersToEnable.Count -eq 0) {
                Write-Host "All providers are already enabled." -ForegroundColor Green
                return
            }
            
            Write-Host "Found $($providersToEnable.Count) disabled providers to enable" -ForegroundColor Gray
        } else {
            foreach ($providerName in $Name) {
                $provider = Get-LLMProvider -Name $providerName
                if (-not $provider) {
                    Write-Warning "Provider '$providerName' not found. Skipping."
                    continue
                }
                
                if ($provider.Enabled) {
                    Write-Host "Provider '$providerName' is already enabled." -ForegroundColor Yellow
                } else {
                    $providersToEnable += $provider
                }
            }
        }
        
        if ($providersToEnable.Count -eq 0) {
            Write-Host "No providers to enable." -ForegroundColor Yellow
            return
        }
        
        # Show what will be enabled
        Write-Host "Providers to enable:" -ForegroundColor Green
        foreach ($provider in $providersToEnable) {
            Write-Host "  - $($provider.Name)" -ForegroundColor Cyan
            Write-Host "    $($provider.BaseUrl)" -ForegroundColor Gray
            if ($provider.Description) {
                Write-Host "    $($provider.Description)" -ForegroundColor Gray
            }
        }
        
        if ($PSCmdlet.ShouldProcess(($providersToEnable.Name -join ', '), 'Enable LLM Provider(s)')) {
            $enabledCount = 0
            $errors = @()
            
            foreach ($provider in $providersToEnable) {
                try {
                    Set-LLMProviderEnabled -Name $provider.Name -Enabled $true -SaveToConfig:$false
                    $enabledCount++
                    Write-Verbose "Enabled provider: $($provider.Name)"
                }
                catch {
                    $errors += "Failed to enable provider '$($provider.Name)': $_"
                    Write-Warning "Failed to enable provider '$($provider.Name)': $_"
                }
            }
            
            # Save to configuration file if requested and any providers were enabled
            if ($SaveToConfig -and $enabledCount -gt 0) {
                try {
                    $configPath = Get-LLMConfigFilePath
                    $config = Get-LLMConfiguration -Force
                    Save-LLMConfiguration -Configuration $config -Path $configPath -Backup
                    Write-Verbose "Configuration saved to: $configPath"
                }
                catch {
                    Write-Warning "Providers enabled but failed to save configuration: $_"
                }
            }
            
            # Report results
            if ($enabledCount -gt 0) {
                Write-Host ""
                Write-Host "✓ Successfully enabled $enabledCount provider(s)" -ForegroundColor Green
                
                if ($SaveToConfig) {
                    Write-Host "  Configuration saved to file" -ForegroundColor Gray
                }
                
                # Show next steps
                Write-Host ""
                Write-Host "Next steps:" -ForegroundColor Yellow
                foreach ($provider in $providersToEnable[0..2]) {  # Show first 3
                    $apiKey = Get-LLMEnvironmentVariable -Name $provider.ApiKeyVar
                    if ([string]::IsNullOrWhiteSpace($apiKey)) {
                        Write-Host "  Set API key for $($provider.Name): " -NoNewline -ForegroundColor Gray
                        Write-Host "`$env:$($provider.ApiKeyVar) = 'your-key'" -ForegroundColor Cyan
                    } else {
                        Write-Host "  Use $($provider.Name): " -NoNewline -ForegroundColor Gray
                        Write-Host "Set-LLMProvider -Name '$($provider.Name)'" -ForegroundColor Cyan
                    }
                }
                if ($providersToEnable.Count -gt 3) {
                    Write-Host "  ... and $($providersToEnable.Count - 3) more" -ForegroundColor Gray
                }
            }
            
            if ($errors.Count -gt 0) {
                Write-Host ""
                Write-Host "Errors occurred:" -ForegroundColor Red
                foreach ($error in $errors) {
                    Write-Host "  $error" -ForegroundColor Red
                }
            }
        }
    }
    catch {
        Write-Error "Failed to enable LLM provider(s): $_"
        throw
    }
}