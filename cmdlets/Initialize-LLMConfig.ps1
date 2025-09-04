#Requires -Version 5.1
<#
.SYNOPSIS
    Initializes LLM environment configuration
.DESCRIPTION
    Equivalent to 'llm-env config init'. Creates a new configuration file
    with default providers or copies from system configuration.
.PARAMETER Path
    Custom path for configuration file (optional)
.PARAMETER Force
    Overwrite existing configuration file
.PARAMETER IncludeDefaults
    Include built-in default providers in new configuration
.OUTPUTS
    [void]
.EXAMPLE
    Initialize-LLMConfig
.EXAMPLE
    Initialize-LLMConfig -Force -IncludeDefaults
.EXAMPLE
    Initialize-LLMConfig -Path "C:\MyConfig\llm-env.conf"
#>
function Initialize-LLMConfig {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [string]$Path,
        
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [switch]$IncludeDefaults
    )
    
    try {
        # Determine configuration file path
        $configPath = if ($Path) { 
            Resolve-LLMPath $Path 
        } else { 
            Get-LLMConfigFilePath 
        }
        
        Write-Verbose "Initializing LLM configuration at: $configPath"
        
        # Check if file already exists
        if ((Test-Path $configPath) -and -not $Force) {
            throw "Configuration file already exists at '$configPath'. Use -Force to overwrite."
        }
        
        # Ensure directory exists
        $configDir = Split-Path $configPath -Parent
        if (-not (Test-Path $configDir)) {
            if ($PSCmdlet.ShouldProcess($configDir, 'Create Configuration Directory')) {
                New-LLMDirectory -Path $configDir -Force | Out-Null
                Write-Verbose "Created configuration directory: $configDir"
            }
        }
        
        if ($PSCmdlet.ShouldProcess($configPath, 'Initialize LLM Configuration')) {
            # Create new configuration
            $config = New-LLMConfiguration -ConfigPath $configPath
            
            if ($IncludeDefaults) {
                # Load built-in defaults
                $builtinConfig = Get-LLMBuiltinConfiguration
                foreach ($provider in $builtinConfig.GetAllProviders()) {
                    $config.AddProvider($provider)
                }
                Write-Verbose "Added $($builtinConfig.Count()) default providers"
            } else {
                # Add minimal example provider
                $exampleProvider = @{
                    base_url = 'https://api.example.com/v1'
                    api_key_var = 'LLM_EXAMPLE_API_KEY'
                    default_model = 'example-model'
                    description = 'Example provider configuration - replace with your actual provider'
                    enabled = 'false'
                }
                $config.AddProvider('example', $exampleProvider)
                Write-Verbose "Added example provider template"
            }
            
            # Save configuration
            Save-LLMConfiguration -Configuration $config -Path $configPath
            
            Write-Host "✓ LLM configuration initialized successfully" -ForegroundColor Green
            Write-Host "  Configuration file: " -NoNewline -ForegroundColor Gray
            Write-Host "$configPath" -ForegroundColor Cyan
            Write-Host "  Providers configured: " -NoNewline -ForegroundColor Gray
            Write-Host "$($config.Count())" -ForegroundColor White
            
            if (-not $IncludeDefaults) {
                Write-Host ""
                Write-Host "Next steps:" -ForegroundColor Yellow
                Write-Host "1. Edit configuration: " -NoNewline -ForegroundColor Gray
                Write-Host "Edit-LLMConfig" -ForegroundColor Cyan
                Write-Host "2. Add providers: " -NoNewline -ForegroundColor Gray
                Write-Host "Add-LLMProvider" -ForegroundColor Cyan
                Write-Host "3. Set API keys in environment variables" -ForegroundColor Gray
            } else {
                Write-Host ""
                Write-Host "Configuration ready to use!" -ForegroundColor Green
                Write-Host "Set API keys and use: " -NoNewline -ForegroundColor Gray
                Write-Host "Set-LLMProvider -Name <provider>" -ForegroundColor Cyan
            }
        }
    }
    catch {
        Write-Error "Failed to initialize LLM configuration: $_"
        throw
    }
}