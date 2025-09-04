#Requires -Version 5.1
<#
.SYNOPSIS
    Sets the current LLM provider by configuring environment variables
.DESCRIPTION
    Equivalent to 'llm-env set <provider>'. Sets up environment variables
    for the specified provider to make it active for LLM tools.
.PARAMETER Name
    Name of the provider to set as active
.PARAMETER Model
    Override the default model for this session (optional)
.PARAMETER Force
    Force setting even if provider is disabled or API key is missing
.OUTPUTS
    [void]
.EXAMPLE
    Set-LLMProvider -Name "openai"
.EXAMPLE
    Set-LLMProvider -Name "anthropic" -Model "claude-3-5-sonnet-20241022"
.EXAMPLE
    llm-set openai
#>
function Set-LLMProvider {
    [CmdletBinding(SupportsShouldProcess)]
    [Alias('llm-set')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        
        [Parameter()]
        [string]$Model,
        
        [Parameter()]
        [switch]$Force
    )
    
    try {
        Write-Verbose "Setting LLM provider to: $Name"
        
        # Get the provider from registry
        $provider = Get-LLMProvider -Name $Name
        if (-not $provider) {
            throw "Provider '$Name' not found. Use 'Get-LLMProviders' to see available providers."
        }
        
        # Check if provider is enabled (unless forced)
        if (-not $Force -and -not $provider.Enabled) {
            throw "Provider '$Name' is disabled. Use -Force to set anyway, or enable with 'Enable-LLMProvider -Name $Name'."
        }
        
        # Check if provider is valid
        if (-not $provider.IsValid()) {
            throw "Provider '$Name' configuration is invalid. Check base_url and api_key_var settings."
        }
        
        # Check if API key is available (unless forced)
        $apiKey = Get-LLMEnvironmentVariable -Name $provider.ApiKeyVar
        if (-not $Force -and [string]::IsNullOrWhiteSpace($apiKey)) {
            Write-Warning "API key not found in environment variable: $($provider.ApiKeyVar)"
            Write-Warning "Set the API key with: `$env:$($provider.ApiKeyVar) = 'your-api-key'"
            if (-not $Force) {
                throw "API key required. Use -Force to set provider anyway."
            }
        }
        
        if ($PSCmdlet.ShouldProcess($Name, 'Set LLM Provider')) {
            # Set standard environment variables
            Set-LLMEnvironmentVariable -Name 'LLM_BASE_URL' -Value $provider.BaseUrl
            Set-LLMEnvironmentVariable -Name 'LLM_API_KEY_VAR' -Value $provider.ApiKeyVar
            Set-LLMEnvironmentVariable -Name 'LLM_MODEL' -Value ($Model -or $provider.DefaultModel)
            Set-LLMEnvironmentVariable -Name 'LLM_PROVIDER' -Value $provider.Name
            
            # Set OpenAI-compatible environment variables for maximum compatibility
            Set-LLMEnvironmentVariable -Name 'OPENAI_BASE_URL' -Value $provider.BaseUrl
            Set-LLMEnvironmentVariable -Name 'OPENAI_API_KEY' -Value $apiKey
            
            # Store previous provider for potential rollback
            $currentProvider = Get-LLMEnvironmentVariable -Name 'LLM_PROVIDER'
            if ($currentProvider -and $currentProvider -ne $Name) {
                Set-LLMEnvironmentVariable -Name 'LLM_PREVIOUS_PROVIDER' -Value $currentProvider
            }
            
            Write-Host "✓ LLM provider set to: " -NoNewline -ForegroundColor Green
            Write-Host "$Name" -ForegroundColor Cyan
            Write-Host "  Base URL: " -NoNewline -ForegroundColor Gray
            Write-Host "$($provider.BaseUrl)" -ForegroundColor White
            Write-Host "  Model: " -NoNewline -ForegroundColor Gray  
            Write-Host "$(($Model -or $provider.DefaultModel))" -ForegroundColor White
            Write-Host "  API Key: " -NoNewline -ForegroundColor Gray
            if (-not [string]::IsNullOrWhiteSpace($apiKey)) {
                Write-Host "✓ Available" -ForegroundColor Green
            } else {
                Write-Host "⚠ Not set" -ForegroundColor Yellow
            }
            
            Write-Verbose "Environment variables configured for provider: $Name"
        }
    }
    catch {
        Write-Error "Failed to set LLM provider '$Name': $_"
        throw
    }
}