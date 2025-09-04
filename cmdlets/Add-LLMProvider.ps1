#Requires -Version 5.1
<#
.SYNOPSIS
    Adds a new LLM provider to the configuration
.DESCRIPTION
    Equivalent to 'llm-env config add'. Interactively or programmatically
    adds a new provider to the configuration file.
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
.PARAMETER Interactive
    Use interactive mode to collect provider information
.PARAMETER ConfigPath
    Custom configuration file path
.OUTPUTS
    [void]
.EXAMPLE
    Add-LLMProvider -Interactive
.EXAMPLE
    Add-LLMProvider -Name "myapi" -BaseUrl "https://api.example.com/v1" -ApiKeyVar "MY_API_KEY"
.EXAMPLE
    Add-LLMProvider -Name "claude" -BaseUrl "https://api.anthropic.com/v1" -ApiKeyVar "ANTHROPIC_API_KEY" -DefaultModel "claude-3-5-sonnet-20241022"
#>
function Add-LLMProvider {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [string]$Name,
        
        [Parameter()]
        [string]$BaseUrl,
        
        [Parameter()]
        [string]$ApiKeyVar,
        
        [Parameter()]
        [string]$DefaultModel,
        
        [Parameter()]
        [string]$Description,
        
        [Parameter()]
        [bool]$Enabled = $true,
        
        [Parameter()]
        [switch]$Interactive,
        
        [Parameter()]
        [string]$ConfigPath
    )
    
    try {
        # Use interactive mode if requested or if required parameters are missing
        if ($Interactive -or -not ($Name -and $BaseUrl -and $ApiKeyVar)) {
            Write-Host "Adding new LLM provider interactively..." -ForegroundColor Green
            Write-Host ""
            
            # Collect provider information interactively
            if (-not $Name) {
                do {
                    $Name = Read-Host "Provider name (e.g., 'myapi', 'claude', 'gemini')"
                    if ([string]::IsNullOrWhiteSpace($Name)) {
                        Write-Host "Provider name is required." -ForegroundColor Red
                    }
                    elseif ($Name -notmatch '^[a-z][a-z0-9_-]*$') {
                        Write-Host "Provider name should start with a letter and contain only lowercase letters, numbers, underscores, and hyphens." -ForegroundColor Red
                        $Name = $null
                    }
                } while (-not $Name)
            }
            
            # Check if provider already exists
            $existingProvider = Get-LLMProvider -Name $Name
            if ($existingProvider) {
                throw "Provider '$Name' already exists. Use Remove-LLMProvider first if you want to replace it."
            }
            
            if (-not $BaseUrl) {
                do {
                    $BaseUrl = Read-Host "Base URL (e.g., 'https://api.example.com/v1')"
                    if ([string]::IsNullOrWhiteSpace($BaseUrl)) {
                        Write-Host "Base URL is required." -ForegroundColor Red
                    }
                    else {
                        try {
                            $null = [System.Uri]::new($BaseUrl)
                        }
                        catch {
                            Write-Host "Invalid URL format. Please enter a valid HTTP/HTTPS URL." -ForegroundColor Red
                            $BaseUrl = $null
                        }
                    }
                } while (-not $BaseUrl)
            }
            
            if (-not $ApiKeyVar) {
                $suggestedVar = "LLM_$($Name.ToUpper().Replace('-', '_'))_API_KEY"
                $defaultResponse = Read-Host "API key environment variable (default: '$suggestedVar')"
                $ApiKeyVar = if ([string]::IsNullOrWhiteSpace($defaultResponse)) { $suggestedVar } else { $defaultResponse }
                
                if ($ApiKeyVar -notmatch '^[A-Z][A-Z0-9_]*$') {
                    Write-Host "Converting to standard format..." -ForegroundColor Yellow
                    $ApiKeyVar = $ApiKeyVar.ToUpper().Replace('-', '_').Replace(' ', '_')
                    Write-Host "Using: $ApiKeyVar" -ForegroundColor Cyan
                }
            }
            
            if (-not $DefaultModel) {
                $DefaultModel = Read-Host "Default model name (optional)"
            }
            
            if (-not $Description) {
                $Description = Read-Host "Description (optional)"
            }
            
            $enabledResponse = Read-Host "Enable provider? (Y/n)"
            $Enabled = $enabledResponse -notmatch '^[Nn]'
            
            Write-Host ""
            Write-Host "Provider Summary:" -ForegroundColor Yellow
            Write-Host "  Name: $Name" -ForegroundColor White
            Write-Host "  Base URL: $BaseUrl" -ForegroundColor White
            Write-Host "  API Key Variable: $ApiKeyVar" -ForegroundColor White
            if ($DefaultModel) { Write-Host "  Default Model: $DefaultModel" -ForegroundColor White }
            if ($Description) { Write-Host "  Description: $Description" -ForegroundColor White }
            Write-Host "  Enabled: $Enabled" -ForegroundColor White
            Write-Host ""
            
            $confirm = Read-Host "Add this provider? (Y/n)"
            if ($confirm -match '^[Nn]') {
                Write-Host "Provider addition cancelled." -ForegroundColor Yellow
                return
            }
        }
        
        # Validate required parameters
        if (-not $Name) { throw "Provider name is required" }
        if (-not $BaseUrl) { throw "Base URL is required" }
        if (-not $ApiKeyVar) { throw "API key variable name is required" }
        
        if ($PSCmdlet.ShouldProcess($Name, 'Add LLM Provider')) {
            # Determine configuration file path
            $configFile = if ($ConfigPath) { 
                Resolve-LLMPath $ConfigPath 
            } else { 
                Get-LLMConfigFilePath 
            }
            
            # Check if configuration exists
            if (-not (Test-Path $configFile)) {
                Write-Warning "Configuration file not found. Creating new configuration..."
                Initialize-LLMConfig -Path $configFile -IncludeDefaults:$false
            }
            
            # Build additional properties
            $additionalProps = @{}
            
            # Add provider using the registry function
            $provider = Add-LLMProvider -Name $Name -BaseUrl $BaseUrl -ApiKeyVar $ApiKeyVar -DefaultModel $DefaultModel -Description $Description -Enabled $Enabled -AdditionalProperties $additionalProps -SaveToConfig
            
            Write-Host "✓ Provider '$Name' added successfully" -ForegroundColor Green
            Write-Host "  Configuration saved to: " -NoNewline -ForegroundColor Gray
            Write-Host "$configFile" -ForegroundColor Cyan
            
            # Check if API key is set
            $apiKey = Get-LLMEnvironmentVariable -Name $ApiKeyVar
            if ([string]::IsNullOrWhiteSpace($apiKey)) {
                Write-Host ""
                Write-Host "Next steps:" -ForegroundColor Yellow
                Write-Host "1. Set your API key:" -ForegroundColor Gray
                Write-Host "   `$env:$ApiKeyVar = 'your-api-key-here'" -ForegroundColor Cyan
                Write-Host "2. Test the provider:" -ForegroundColor Gray
                Write-Host "   Test-LLMProvider -Name '$Name'" -ForegroundColor Cyan
                Write-Host "3. Use the provider:" -ForegroundColor Gray
                Write-Host "   Set-LLMProvider -Name '$Name'" -ForegroundColor Cyan
            } else {
                Write-Host ""
                Write-Host "Provider is ready to use!" -ForegroundColor Green
                Write-Host "Set as active: " -NoNewline -ForegroundColor Gray
                Write-Host "Set-LLMProvider -Name '$Name'" -ForegroundColor Cyan
            }
        }
    }
    catch {
        Write-Error "Failed to add LLM provider: $_"
        throw
    }
}