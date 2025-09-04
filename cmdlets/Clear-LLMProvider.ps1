#Requires -Version 5.1
<#
.SYNOPSIS
    Clears the current LLM provider configuration
.DESCRIPTION
    Equivalent to 'llm-env unset'. Removes all LLM-related environment variables
    and restores the environment to a clean state.
.PARAMETER RestorePrevious  
    Restore the previous provider instead of clearing completely
.OUTPUTS
    [void]
.EXAMPLE
    Clear-LLMProvider
.EXAMPLE
    Clear-LLMProvider -RestorePrevious
.EXAMPLE  
    llm-unset
#>
function Clear-LLMProvider {
    [CmdletBinding(SupportsShouldProcess)]
    [Alias('llm-unset')]
    param(
        [Parameter()]
        [switch]$RestorePrevious
    )
    
    try {
        $currentProvider = Get-LLMEnvironmentVariable -Name 'LLM_PROVIDER'
        
        if ([string]::IsNullOrWhiteSpace($currentProvider)) {
            Write-Host "No LLM provider is currently set." -ForegroundColor Yellow
            return
        }
        
        if ($RestorePrevious) {
            $previousProvider = Get-LLMEnvironmentVariable -Name 'LLM_PREVIOUS_PROVIDER'
            if (-not [string]::IsNullOrWhiteSpace($previousProvider)) {
                if ($PSCmdlet.ShouldProcess($previousProvider, 'Restore Previous LLM Provider')) {
                    Write-Host "Restoring previous provider: " -NoNewline -ForegroundColor Green
                    Write-Host "$previousProvider" -ForegroundColor Cyan
                    Set-LLMProvider -Name $previousProvider
                    return
                }
            } else {
                Write-Warning "No previous provider found to restore"
            }
        }
        
        if ($PSCmdlet.ShouldProcess($currentProvider, 'Clear LLM Provider')) {
            # List of environment variables to clear
            $envVarsToRemove = @(
                'LLM_BASE_URL',
                'LLM_API_KEY_VAR', 
                'LLM_MODEL',
                'LLM_PROVIDER',
                'LLM_PREVIOUS_PROVIDER',
                'OPENAI_BASE_URL',
                'OPENAI_API_KEY'
            )
            
            Write-Verbose "Clearing LLM environment variables"
            
            foreach ($envVar in $envVarsToRemove) {
                try {
                    Remove-LLMEnvironmentVariable -Name $envVar
                    Write-Verbose "Cleared environment variable: $envVar"
                }
                catch {
                    Write-Warning "Failed to clear environment variable '$envVar': $_"
                }
            }
            
            Write-Host "✓ LLM provider configuration cleared" -ForegroundColor Green
            Write-Host "  Previously set: " -NoNewline -ForegroundColor Gray
            Write-Host "$currentProvider" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Error "Failed to clear LLM provider: $_"
        throw
    }
}