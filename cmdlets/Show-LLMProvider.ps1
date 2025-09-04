#Requires -Version 5.1
<#
.SYNOPSIS
    Shows the current LLM provider environment configuration
.DESCRIPTION
    Equivalent to 'llm-env show'. Displays the currently active provider
    and all relevant environment variables and their values.
.PARAMETER IncludeApiKey
    Show the actual API key value (masked by default for security)
.PARAMETER TestConnectivity
    Test API connectivity for the current provider
.OUTPUTS
    [void]
.EXAMPLE
    Show-LLMProvider
.EXAMPLE
    Show-LLMProvider -TestConnectivity
.EXAMPLE
    llm-show
#>
function Show-LLMProvider {
    [CmdletBinding()]
    [Alias('llm-show')]
    param(
        [Parameter()]
        [switch]$IncludeApiKey,
        
        [Parameter()]
        [switch]$TestConnectivity
    )
    
    try {
        $currentProviderName = Get-LLMEnvironmentVariable -Name 'LLM_PROVIDER'
        
        if ([string]::IsNullOrWhiteSpace($currentProviderName)) {
            Write-Host "No LLM provider is currently set." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "To set a provider, use: " -NoNewline -ForegroundColor Gray
            Write-Host "Set-LLMProvider -Name <provider>" -ForegroundColor Cyan
            Write-Host "To list providers, use: " -NoNewline -ForegroundColor Gray
            Write-Host "Get-LLMProviders" -ForegroundColor Cyan
            return
        }
        
        # Get current provider details
        $provider = Get-LLMProvider -Name $currentProviderName
        if (-not $provider) {
            Write-Warning "Current provider '$currentProviderName' not found in configuration"
            return
        }
        
        # Display current provider information
        Write-Host ""
        Write-Host "Current LLM Provider Configuration" -ForegroundColor Green
        Write-Host "=================================" -ForegroundColor Green
        Write-Host ""
        
        Write-Host "Provider: " -NoNewline -ForegroundColor Gray
        Write-Host "$($provider.Name)" -ForegroundColor Cyan
        
        Write-Host "Status: " -NoNewline -ForegroundColor Gray
        if ($provider.Enabled) {
            Write-Host "Enabled" -ForegroundColor Green
        } else {
            Write-Host "Disabled" -ForegroundColor Red
        }
        
        Write-Host "Valid: " -NoNewline -ForegroundColor Gray
        if ($provider.IsValid()) {
            Write-Host "Yes" -ForegroundColor Green
        } else {
            Write-Host "No" -ForegroundColor Red
        }
        
        if ($provider.Description) {
            Write-Host "Description: " -NoNewline -ForegroundColor Gray
            Write-Host "$($provider.Description)" -ForegroundColor White
        }
        
        Write-Host ""
        Write-Host "Environment Variables:" -ForegroundColor Yellow
        Write-Host "---------------------" -ForegroundColor Yellow
        
        # Show environment variables
        $envVars = @{
            'LLM_PROVIDER' = Get-LLMEnvironmentVariable -Name 'LLM_PROVIDER'
            'LLM_BASE_URL' = Get-LLMEnvironmentVariable -Name 'LLM_BASE_URL' 
            'LLM_MODEL' = Get-LLMEnvironmentVariable -Name 'LLM_MODEL'
            'LLM_API_KEY_VAR' = Get-LLMEnvironmentVariable -Name 'LLM_API_KEY_VAR'
            'OPENAI_BASE_URL' = Get-LLMEnvironmentVariable -Name 'OPENAI_BASE_URL'
            'OPENAI_API_KEY' = Get-LLMEnvironmentVariable -Name 'OPENAI_API_KEY'
        }
        
        # Add the actual API key variable
        $apiKeyVar = $provider.ApiKeyVar
        if ($apiKeyVar) {
            $envVars[$apiKeyVar] = Get-LLMEnvironmentVariable -Name $apiKeyVar
        }
        
        foreach ($envVar in $envVars.GetEnumerator() | Sort-Object Key) {
            $value = $envVar.Value
            Write-Host "  $($envVar.Key): " -NoNewline -ForegroundColor Gray
            
            if ([string]::IsNullOrWhiteSpace($value)) {
                Write-Host "(not set)" -ForegroundColor Red
            }
            elseif ($envVar.Key -like "*API_KEY*" -or $envVar.Key -eq $apiKeyVar) {
                if ($IncludeApiKey) {
                    Write-Host "$value" -ForegroundColor Green
                } else {
                    # Mask API key for security
                    $maskedValue = if ($value.Length -gt 8) {
                        $value.Substring(0, 4) + "*" * ($value.Length - 8) + $value.Substring($value.Length - 4)
                    } else {
                        "*" * $value.Length
                    }
                    Write-Host "$maskedValue" -ForegroundColor Green
                    Write-Host "    (use -IncludeApiKey to show full value)" -ForegroundColor DarkGray
                }
            }
            else {
                Write-Host "$value" -ForegroundColor White
            }
        }
        
        # Show previous provider if available
        $previousProvider = Get-LLMEnvironmentVariable -Name 'LLM_PREVIOUS_PROVIDER'
        if (-not [string]::IsNullOrWhiteSpace($previousProvider)) {
            Write-Host ""
            Write-Host "Previous Provider: " -NoNewline -ForegroundColor Gray
            Write-Host "$previousProvider" -ForegroundColor Cyan
            Write-Host "  (use Clear-LLMProvider -RestorePrevious to restore)" -ForegroundColor DarkGray
        }
        
        # Test connectivity if requested
        if ($TestConnectivity) {
            Write-Host ""
            Write-Host "Connectivity Test:" -ForegroundColor Yellow
            Write-Host "-----------------" -ForegroundColor Yellow
            
            $apiKey = Get-LLMEnvironmentVariable -Name $provider.ApiKeyVar
            if ([string]::IsNullOrWhiteSpace($apiKey)) {
                Write-Host "  ✗ Cannot test connectivity: API key not set" -ForegroundColor Red
            } else {
                Write-Host "  Testing connection to $($provider.BaseUrl)..." -ForegroundColor Gray
                
                try {
                    $testResult = Test-LLMProviderConnectivity -Provider $provider -TimeoutSeconds 10
                    
                    if ($testResult.Success) {
                        Write-Host "  ✓ Connection successful" -ForegroundColor Green
                        Write-Host "    Response time: $($testResult.ResponseTime)ms" -ForegroundColor Gray
                        if ($testResult.Details.ModelsCount) {
                            Write-Host "    Available models: $($testResult.Details.ModelsCount)" -ForegroundColor Gray
                        }
                    } else {
                        Write-Host "  ✗ Connection failed" -ForegroundColor Red
                        if ($testResult.StatusCode) {
                            Write-Host "    HTTP Status: $($testResult.StatusCode)" -ForegroundColor Red
                        }
                        if ($testResult.Error) {
                            Write-Host "    Error: $($testResult.Error)" -ForegroundColor Red
                        }
                    }
                }
                catch {
                    Write-Host "  ✗ Connectivity test error: $_" -ForegroundColor Red
                }
            }
        }
        
        Write-Host ""
        
        # Show usage examples
        Write-Host "Usage Examples:" -ForegroundColor Yellow
        Write-Host "--------------" -ForegroundColor Yellow
        Write-Host "  Switch provider:    " -NoNewline -ForegroundColor Gray
        Write-Host "Set-LLMProvider -Name <provider>" -ForegroundColor Cyan
        Write-Host "  Clear provider:     " -NoNewline -ForegroundColor Gray  
        Write-Host "Clear-LLMProvider" -ForegroundColor Cyan
        Write-Host "  List all providers: " -NoNewline -ForegroundColor Gray
        Write-Host "Get-LLMProviders" -ForegroundColor Cyan
        Write-Host ""
    }
    catch {
        Write-Error "Failed to show LLM provider information: $_"
        throw
    }
}