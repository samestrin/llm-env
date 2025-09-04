#Requires -Version 5.1
<#
.SYNOPSIS
    Disables one or more LLM providers
.DESCRIPTION
    Disables specified providers in the configuration, preventing them
    from being used with Set-LLMProvider unless forced.
.PARAMETER Name
    Provider name(s) to disable
.PARAMETER All
    Disable all providers (dangerous - use with caution)
.PARAMETER SaveToConfig
    Save changes to configuration file (default: true)
.PARAMETER Force
    Force disable even if provider is currently active
.OUTPUTS
    [void]
.EXAMPLE
    Disable-LLMProvider -Name "oldapi"
.EXAMPLE
    Disable-LLMProvider -Name "openai", "anthropic"
.EXAMPLE
    Disable-LLMProvider -All -Force
#>
function Disable-LLMProvider {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ByName', Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'All')]
        [switch]$All,
        
        [Parameter()]
        [bool]$SaveToConfig = $true,
        
        [Parameter()]
        [switch]$Force
    )
    
    try {
        $providersToDisable = @()
        $currentProvider = Get-LLMEnvironmentVariable -Name 'LLM_PROVIDER'
        
        if ($All) {
            Write-Warning "Disabling ALL providers - this will leave no providers available!"
            $allProviders = Get-LLMProviders
            $providersToDisable = $allProviders | Where-Object { $_.Enabled }
            
            if ($providersToDisable.Count -eq 0) {
                Write-Host "All providers are already disabled." -ForegroundColor Yellow
                return
            }
            
            # Extra confirmation for disabling all providers
            if (-not $Force) {
                $confirm = Read-Host "This will disable ALL $($providersToDisable.Count) providers. Are you sure? (type 'yes' to confirm)"
                if ($confirm -ne 'yes') {
                    Write-Host "Operation cancelled." -ForegroundColor Yellow
                    return
                }
            }
        } else {
            foreach ($providerName in $Name) {
                $provider = Get-LLMProvider -Name $providerName
                if (-not $provider) {
                    Write-Warning "Provider '$providerName' not found. Skipping."
                    continue
                }
                
                if (-not $provider.Enabled) {
                    Write-Host "Provider '$providerName' is already disabled." -ForegroundColor Yellow
                } else {
                    $providersToDisable += $provider
                }
            }
        }
        
        if ($providersToDisable.Count -eq 0) {
            Write-Host "No providers to disable." -ForegroundColor Yellow
            return
        }
        
        # Check if any providers to disable are currently active
        $activeProviders = $providersToDisable | Where-Object { $_.Name -eq $currentProvider }
        if ($activeProviders.Count -gt 0 -and -not $Force) {
            Write-Host "The following providers are currently active:" -ForegroundColor Yellow
            foreach ($activeProvider in $activeProviders) {
                Write-Host "  - $($activeProvider.Name)" -ForegroundColor Red
            }
            Write-Host ""
            
            $confirm = Read-Host "Disabling active providers will clear your environment. Continue? (y/N)"
            if ($confirm -notmatch '^[Yy]') {
                Write-Host "Operation cancelled." -ForegroundColor Yellow
                return
            }
        }
        
        # Show what will be disabled
        Write-Host "Providers to disable:" -ForegroundColor Yellow
        foreach ($provider in $providersToDisable) {
            $status = if ($provider.Name -eq $currentProvider) { " (currently active)" } else { "" }
            Write-Host "  - $($provider.Name)$status" -ForegroundColor Red
            Write-Host "    $($provider.BaseUrl)" -ForegroundColor Gray
            if ($provider.Description) {
                Write-Host "    $($provider.Description)" -ForegroundColor Gray
            }
        }
        
        if ($PSCmdlet.ShouldProcess(($providersToDisable.Name -join ', '), 'Disable LLM Provider(s)')) {
            $disabledCount = 0
            $errors = @()
            $clearedEnvironment = $false
            
            foreach ($provider in $providersToDisable) {
                try {
                    # Clear environment if this provider is currently active
                    if ($provider.Name -eq $currentProvider -and -not $clearedEnvironment) {
                        Clear-LLMProvider
                        $clearedEnvironment = $true
                        Write-Verbose "Cleared environment for active provider: $($provider.Name)"
                    }
                    
                    Set-LLMProviderEnabled -Name $provider.Name -Enabled $false -SaveToConfig:$false
                    $disabledCount++
                    Write-Verbose "Disabled provider: $($provider.Name)"
                }
                catch {
                    $errors += "Failed to disable provider '$($provider.Name)': $_"
                    Write-Warning "Failed to disable provider '$($provider.Name)': $_"
                }
            }
            
            # Save to configuration file if requested and any providers were disabled
            if ($SaveToConfig -and $disabledCount -gt 0) {
                try {
                    $configPath = Get-LLMConfigFilePath
                    $config = Get-LLMConfiguration -Force
                    Save-LLMConfiguration -Configuration $config -Path $configPath -Backup
                    Write-Verbose "Configuration saved to: $configPath"
                }
                catch {
                    Write-Warning "Providers disabled but failed to save configuration: $_"
                }
            }
            
            # Report results
            if ($disabledCount -gt 0) {
                Write-Host ""
                Write-Host "✓ Successfully disabled $disabledCount provider(s)" -ForegroundColor Green
                
                if ($SaveToConfig) {
                    Write-Host "  Configuration saved to file" -ForegroundColor Gray
                }
                
                if ($clearedEnvironment) {
                    Write-Host "  Environment cleared (active provider was disabled)" -ForegroundColor Yellow
                }
                
                # Show remaining enabled providers
                $remainingProviders = Get-LLMProviders -EnabledOnly
                if ($remainingProviders.Count -gt 0) {
                    Write-Host ""
                    Write-Host "Remaining enabled providers:" -ForegroundColor Green
                    foreach ($remaining in $remainingProviders[0..4]) {  # Show first 5
                        Write-Host "  - $($remaining.Name)" -ForegroundColor Cyan
                    }
                    if ($remainingProviders.Count -gt 5) {
                        Write-Host "  ... and $($remainingProviders.Count - 5) more" -ForegroundColor Gray
                    }
                    Write-Host ""
                    Write-Host "Use any enabled provider: " -NoNewline -ForegroundColor Gray
                    Write-Host "Set-LLMProvider -Name <provider>" -ForegroundColor Cyan
                } else {
                    Write-Host ""
                    Write-Host "⚠ No providers are currently enabled!" -ForegroundColor Red
                    Write-Host "Enable providers with: " -NoNewline -ForegroundColor Gray
                    Write-Host "Enable-LLMProvider -Name <provider>" -ForegroundColor Cyan
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
        Write-Error "Failed to disable LLM provider(s): $_"
        throw
    }
}