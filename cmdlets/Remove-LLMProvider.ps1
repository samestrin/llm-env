#Requires -Version 5.1
<#
.SYNOPSIS
    Removes an LLM provider from the configuration
.DESCRIPTION
    Equivalent to 'llm-env config remove'. Removes the specified provider
    from the configuration file.
.PARAMETER Name
    Provider name to remove
.PARAMETER Force
    Remove without confirmation prompt
.PARAMETER ConfigPath
    Custom configuration file path
.OUTPUTS
    [void]
.EXAMPLE
    Remove-LLMProvider -Name "oldapi"
.EXAMPLE
    Remove-LLMProvider -Name "myapi" -Force
#>
function Remove-LLMProvider {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [string]$ConfigPath
    )
    
    try {
        Write-Verbose "Removing LLM provider: $Name"
        
        # Get the provider to verify it exists
        $provider = Get-LLMProvider -Name $Name
        if (-not $provider) {
            throw "Provider '$Name' not found. Use 'Get-LLMProviders' to see available providers."
        }
        
        # Check if this is the currently active provider
        $currentProvider = Get-LLMEnvironmentVariable -Name 'LLM_PROVIDER'
        $isCurrentProvider = ($currentProvider -eq $Name)
        
        # Show provider information
        Write-Host "Provider to remove:" -ForegroundColor Yellow
        Write-Host "  Name: " -NoNewline -ForegroundColor Gray
        Write-Host "$($provider.Name)" -ForegroundColor White
        Write-Host "  Base URL: " -NoNewline -ForegroundColor Gray
        Write-Host "$($provider.BaseUrl)" -ForegroundColor White
        Write-Host "  Status: " -NoNewline -ForegroundColor Gray
        if ($provider.Enabled) {
            Write-Host "Enabled" -ForegroundColor Green
        } else {
            Write-Host "Disabled" -ForegroundColor Red  
        }
        
        if ($isCurrentProvider) {
            Write-Host "  ⚠ This is the currently active provider" -ForegroundColor Yellow
        }
        
        # Confirmation prompt (unless forced or using -Confirm:$false)
        if (-not $Force -and $PSCmdlet.ShouldProcess($Name, 'Remove LLM Provider')) {
            $confirm = Read-Host "`nAre you sure you want to remove provider '$Name'? (y/N)"
            if ($confirm -notmatch '^[Yy]') {
                Write-Host "Provider removal cancelled." -ForegroundColor Yellow
                return
            }
        }
        
        if ($PSCmdlet.ShouldProcess($Name, 'Remove LLM Provider')) {
            # Determine configuration file path
            $configFile = if ($ConfigPath) { 
                Resolve-LLMPath $ConfigPath 
            } else { 
                Get-LLMConfigFilePath 
            }
            
            # Remove provider using the registry function
            Remove-LLMProvider -Name $Name -SaveToConfig -Force:$Force
            
            Write-Host "✓ Provider '$Name' removed successfully" -ForegroundColor Green
            Write-Host "  Configuration updated: " -NoNewline -ForegroundColor Gray
            Write-Host "$configFile" -ForegroundColor Cyan
            
            # Handle currently active provider
            if ($isCurrentProvider) {
                Write-Host ""
                Write-Host "The removed provider was currently active." -ForegroundColor Yellow
                Write-Host "Your environment has been cleared." -ForegroundColor Yellow
                
                # Clear the environment
                Clear-LLMProvider
                
                # Suggest alternatives
                $remainingProviders = Get-LLMProviders -EnabledOnly
                if ($remainingProviders.Count -gt 0) {
                    Write-Host ""
                    Write-Host "Available providers:" -ForegroundColor Green
                    foreach ($p in $remainingProviders) {
                        Write-Host "  - $($p.Name)" -ForegroundColor Cyan
                    }
                    Write-Host ""
                    Write-Host "Set a new provider: " -NoNewline -ForegroundColor Gray
                    Write-Host "Set-LLMProvider -Name <provider>" -ForegroundColor Cyan
                }
            }
            
            Write-Verbose "Provider '$Name' removed from configuration"
        }
    }
    catch {
        Write-Error "Failed to remove LLM provider '$Name': $_"
        throw
    }
}