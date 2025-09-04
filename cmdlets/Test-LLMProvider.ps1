#Requires -Version 5.1
<#
.SYNOPSIS
    Tests an LLM provider for configuration validity and API connectivity
.DESCRIPTION
    Equivalent to 'llm-env test'. Performs comprehensive testing of a provider
    including configuration validation, API key availability, and connectivity.
.PARAMETER Name
    Provider name to test (defaults to current provider)
.PARAMETER All
    Test all providers
.PARAMETER EnabledOnly
    When testing all providers, only test enabled ones
.PARAMETER SkipConnectivity
    Skip API connectivity tests (only validate configuration)
.PARAMETER TimeoutSeconds
    Timeout for connectivity tests (default: 30)
.PARAMETER Detailed
    Show detailed test results
.OUTPUTS
    [PSCustomObject] Test results
.EXAMPLE
    Test-LLMProvider
.EXAMPLE
    Test-LLMProvider -Name "openai" -Detailed
.EXAMPLE
    Test-LLMProvider -All -EnabledOnly
#>
function Test-LLMProvider {
    [CmdletBinding(DefaultParameterSetName = 'Single')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'Single', Position = 0)]
        [string]$Name,
        
        [Parameter(ParameterSetName = 'All')]
        [switch]$All,
        
        [Parameter()]
        [switch]$EnabledOnly,
        
        [Parameter()]
        [switch]$SkipConnectivity,
        
        [Parameter()]
        [int]$TimeoutSeconds = 30,
        
        [Parameter()]
        [switch]$Detailed
    )
    
    try {
        $results = @()
        
        if ($All) {
            Write-Host "Testing all LLM providers..." -ForegroundColor Green
            $providers = Get-LLMProviders -EnabledOnly:$EnabledOnly
            
            if ($providers.Count -eq 0) {
                Write-Warning "No providers found matching criteria"
                return @()
            }
            
            Write-Host "Found $($providers.Count) providers to test" -ForegroundColor Gray
            Write-Host ""
        } else {
            # Single provider test
            if (-not $Name) {
                $Name = Get-LLMEnvironmentVariable -Name 'LLM_PROVIDER'
                if ([string]::IsNullOrWhiteSpace($Name)) {
                    throw "No provider specified and no current provider set. Use -Name parameter or set a provider first."
                }
                Write-Verbose "Testing current provider: $Name"
            }
            
            $provider = Get-LLMProvider -Name $Name
            if (-not $provider) {
                throw "Provider '$Name' not found"
            }
            
            $providers = @($provider)
        }
        
        foreach ($provider in $providers) {
            Write-Host "Testing provider: " -NoNewline -ForegroundColor Gray
            Write-Host "$($provider.Name)" -ForegroundColor Cyan
            
            # Test using the registry function
            $testResult = Test-LLMProvider -Name $provider.Name -TestConnectivity:(-not $SkipConnectivity) -TimeoutSeconds $TimeoutSeconds
            
            # Display results
            Write-Host "  Configuration: " -NoNewline -ForegroundColor Gray
            if ($testResult.IsValid) {
                Write-Host "✓ Valid" -ForegroundColor Green
            } else {
                Write-Host "✗ Invalid" -ForegroundColor Red
            }
            
            Write-Host "  Status: " -NoNewline -ForegroundColor Gray
            if ($testResult.IsEnabled) {
                Write-Host "✓ Enabled" -ForegroundColor Green
            } else {
                Write-Host "✗ Disabled" -ForegroundColor Yellow
            }
            
            Write-Host "  API Key: " -NoNewline -ForegroundColor Gray
            if ($testResult.HasApiKey) {
                Write-Host "✓ Available" -ForegroundColor Green
            } else {
                Write-Host "✗ Missing" -ForegroundColor Red
            }
            
            if (-not $SkipConnectivity) {
                Write-Host "  Connectivity: " -NoNewline -ForegroundColor Gray
                if ($testResult.IsConnectable -eq $true) {
                    Write-Host "✓ Success" -ForegroundColor Green
                    if ($testResult.Details.ConnectivityTest -and $testResult.Details.ConnectivityTest.ResponseTime) {
                        Write-Host "    Response time: $($testResult.Details.ConnectivityTest.ResponseTime)ms" -ForegroundColor Gray
                    }
                } elseif ($testResult.IsConnectable -eq $false) {
                    Write-Host "✗ Failed" -ForegroundColor Red
                } else {
                    Write-Host "- Skipped" -ForegroundColor Yellow
                }
            }
            
            # Show detailed information if requested
            if ($Detailed) {
                Write-Host "  Details:" -ForegroundColor Yellow
                Write-Host "    Base URL: $($testResult.Details.BaseUrl)" -ForegroundColor Gray
                Write-Host "    API Key Var: $($testResult.Details.ApiKeyVar)" -ForegroundColor Gray
                Write-Host "    Default Model: $($testResult.Details.DefaultModel)" -ForegroundColor Gray
                
                if ($testResult.Errors.Count -gt 0) {
                    Write-Host "    Errors:" -ForegroundColor Red
                    foreach ($error in $testResult.Errors) {
                        Write-Host "      - $error" -ForegroundColor Red
                    }
                }
                
                if ($testResult.Warnings.Count -gt 0) {
                    Write-Host "    Warnings:" -ForegroundColor Yellow
                    foreach ($warning in $testResult.Warnings) {
                        Write-Host "      - $warning" -ForegroundColor Yellow
                    }
                }
            }
            
            $results += $testResult
            Write-Host ""
        }
        
        # Summary
        if ($All) {
            $validCount = ($results | Where-Object { $_.IsValid }).Count
            $enabledCount = ($results | Where-Object { $_.IsEnabled }).Count
            $withApiKeyCount = ($results | Where-Object { $_.HasApiKey }).Count
            $connectableCount = ($results | Where-Object { $_.IsConnectable -eq $true }).Count
            
            Write-Host "Test Summary:" -ForegroundColor Green
            Write-Host "  Total providers: $($results.Count)" -ForegroundColor White
            Write-Host "  Valid configurations: $validCount" -ForegroundColor White
            Write-Host "  Enabled: $enabledCount" -ForegroundColor White
            Write-Host "  With API keys: $withApiKeyCount" -ForegroundColor White
            if (-not $SkipConnectivity) {
                Write-Host "  Connectable: $connectableCount" -ForegroundColor White
            }
            
            # Show failed providers
            $failedProviders = $results | Where-Object { -not $_.IsValid -or $_.IsConnectable -eq $false }
            if ($failedProviders.Count -gt 0) {
                Write-Host ""
                Write-Host "Providers with issues:" -ForegroundColor Yellow
                foreach ($failed in $failedProviders) {
                    Write-Host "  - $($failed.ProviderName): " -NoNewline -ForegroundColor Red
                    $issues = @()
                    if (-not $failed.IsValid) { $issues += "invalid config" }
                    if (-not $failed.HasApiKey) { $issues += "no API key" }
                    if ($failed.IsConnectable -eq $false) { $issues += "connection failed" }
                    Write-Host ($issues -join ", ") -ForegroundColor Gray
                }
            }
        }
        
        return $results
    }
    catch {
        Write-Error "Failed to test LLM provider(s): $_"
        throw
    }
}