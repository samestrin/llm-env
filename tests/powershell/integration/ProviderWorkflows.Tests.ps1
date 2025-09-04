#Requires -Version 5.1
<#
.SYNOPSIS
    Integration tests for LLM Environment Manager provider workflows
.DESCRIPTION
    Tests complete provider switching workflows, configuration file compatibility,
    cross-version PowerShell compatibility, and environment variable management
.NOTES
    Run with: Invoke-Pester -Path tests/powershell/integration/ProviderWorkflows.Tests.ps1
#>

# Import the module being tested
BeforeAll {
    $ModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    Import-Module (Join-Path $ModuleRoot 'llm-env.psd1') -Force
    
    # Create temporary directory for integration tests
    $script:TestDir = Join-Path ([System.IO.Path]::GetTempPath()) "LLMEnvIntegrationTests-$([System.Guid]::NewGuid())"
    New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
    
    # Store original environment state
    $script:OriginalEnvVars = @{}
    $envVarsToPreserve = @(
        'LLM_PROVIDER', 'LLM_BASE_URL', 'LLM_MODEL', 'LLM_API_KEY_VAR',
        'OPENAI_BASE_URL', 'OPENAI_API_KEY', 'LLM_PREVIOUS_PROVIDER'
    )
    
    foreach ($envVar in $envVarsToPreserve) {
        $script:OriginalEnvVars[$envVar] = [System.Environment]::GetEnvironmentVariable($envVar, 'Process')
    }
}

AfterAll {
    # Restore original environment state
    foreach ($envVar in $script:OriginalEnvVars.Keys) {
        [System.Environment]::SetEnvironmentVariable($envVar, $script:OriginalEnvVars[$envVar], 'Process')
    }
    
    # Clean up temporary test directory
    if (Test-Path $script:TestDir) {
        Remove-Item $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

BeforeEach {
    # Clear environment variables before each test
    $envVarsToClean = @(
        'LLM_PROVIDER', 'LLM_BASE_URL', 'LLM_MODEL', 'LLM_API_KEY_VAR',
        'OPENAI_BASE_URL', 'OPENAI_API_KEY', 'LLM_PREVIOUS_PROVIDER',
        'TEST_PROVIDER1_KEY', 'TEST_PROVIDER2_KEY'
    )
    
    foreach ($envVar in $envVarsToClean) {
        [System.Environment]::SetEnvironmentVariable($envVar, $null, 'Process')
    }
    
    # Clear configuration cache
    Clear-LLMConfigurationCache
}

Describe "Complete Provider Switching Workflow" -Tag "Integration", "Workflows" {
    
    BeforeEach {
        # Create a test configuration file
        $script:TestConfigFile = Join-Path $script:TestDir "test-config.conf"
        $configContent = @"
[provider1]
base_url=https://api.provider1.com/v1
api_key_var=TEST_PROVIDER1_KEY
default_model=provider1-model
description=Test Provider 1
enabled=true

[provider2]
base_url=https://api.provider2.com/v1
api_key_var=TEST_PROVIDER2_KEY
default_model=provider2-model
description=Test Provider 2
enabled=true

[disabled_provider]
base_url=https://api.disabled.com/v1
api_key_var=DISABLED_KEY
default_model=disabled-model
description=Disabled Test Provider
enabled=false
"@
        $configContent | Out-File -FilePath $script:TestConfigFile -Encoding UTF8
        
        # Set test API keys
        [System.Environment]::SetEnvironmentVariable('TEST_PROVIDER1_KEY', 'test-key-1', 'Process')
        [System.Environment]::SetEnvironmentVariable('TEST_PROVIDER2_KEY', 'test-key-2', 'Process')
    }
    
    Context "Basic Provider Operations" {
        It "Should switch between providers successfully" {
            # Load configuration from test file
            $config = ConvertFrom-IniFile -Path $script:TestConfigFile | ConvertTo-LLMConfiguration
            
            # Mock the config loading to use our test config
            Mock Get-LLMConfiguration { return $config } -ModuleName Config
            
            # Set first provider
            Set-LLMProvider -Name 'provider1'
            
            [System.Environment]::GetEnvironmentVariable('LLM_PROVIDER', 'Process') | Should -Be 'provider1'
            [System.Environment]::GetEnvironmentVariable('LLM_BASE_URL', 'Process') | Should -Be 'https://api.provider1.com/v1'
            [System.Environment]::GetEnvironmentVariable('LLM_MODEL', 'Process') | Should -Be 'provider1-model'
            [System.Environment]::GetEnvironmentVariable('LLM_API_KEY_VAR', 'Process') | Should -Be 'TEST_PROVIDER1_KEY'
            [System.Environment]::GetEnvironmentVariable('OPENAI_API_KEY', 'Process') | Should -Be 'test-key-1'
            
            # Switch to second provider
            Set-LLMProvider -Name 'provider2'
            
            [System.Environment]::GetEnvironmentVariable('LLM_PROVIDER', 'Process') | Should -Be 'provider2'
            [System.Environment]::GetEnvironmentVariable('LLM_BASE_URL', 'Process') | Should -Be 'https://api.provider2.com/v1'
            [System.Environment]::GetEnvironmentVariable('LLM_MODEL', 'Process') | Should -Be 'provider2-model'
            [System.Environment]::GetEnvironmentVariable('LLM_API_KEY_VAR', 'Process') | Should -Be 'TEST_PROVIDER2_KEY'
            [System.Environment]::GetEnvironmentVariable('OPENAI_API_KEY', 'Process') | Should -Be 'test-key-2'
            [System.Environment]::GetEnvironmentVariable('LLM_PREVIOUS_PROVIDER', 'Process') | Should -Be 'provider1'
        }
        
        It "Should clear provider environment successfully" {
            # Load configuration from test file
            $config = ConvertFrom-IniFile -Path $script:TestConfigFile | ConvertTo-LLMConfiguration
            Mock Get-LLMConfiguration { return $config } -ModuleName Config
            
            # Set a provider first
            Set-LLMProvider -Name 'provider1'
            [System.Environment]::GetEnvironmentVariable('LLM_PROVIDER', 'Process') | Should -Not -BeNullOrEmpty
            
            # Clear the provider
            Clear-LLMProvider
            
            [System.Environment]::GetEnvironmentVariable('LLM_PROVIDER', 'Process') | Should -BeNullOrEmpty
            [System.Environment]::GetEnvironmentVariable('LLM_BASE_URL', 'Process') | Should -BeNullOrEmpty
            [System.Environment]::GetEnvironmentVariable('LLM_MODEL', 'Process') | Should -BeNullOrEmpty
            [System.Environment]::GetEnvironmentVariable('OPENAI_API_KEY', 'Process') | Should -BeNullOrEmpty
        }
        
        It "Should restore previous provider successfully" {
            # Load configuration from test file
            $config = ConvertFrom-IniFile -Path $script:TestConfigFile | ConvertTo-LLMConfiguration
            Mock Get-LLMConfiguration { return $config } -ModuleName Config
            
            # Set first provider, then second
            Set-LLMProvider -Name 'provider1'
            Set-LLMProvider -Name 'provider2'
            
            [System.Environment]::GetEnvironmentVariable('LLM_PROVIDER', 'Process') | Should -Be 'provider2'
            [System.Environment]::GetEnvironmentVariable('LLM_PREVIOUS_PROVIDER', 'Process') | Should -Be 'provider1'
            
            # Restore previous
            Clear-LLMProvider -RestorePrevious
            
            [System.Environment]::GetEnvironmentVariable('LLM_PROVIDER', 'Process') | Should -Be 'provider1'
            [System.Environment]::GetEnvironmentVariable('LLM_BASE_URL', 'Process') | Should -Be 'https://api.provider1.com/v1'
        }
        
        It "Should handle disabled provider appropriately" {
            # Load configuration from test file
            $config = ConvertFrom-IniFile -Path $script:TestConfigFile | ConvertTo-LLMConfiguration
            Mock Get-LLMConfiguration { return $config } -ModuleName Config
            
            # Attempt to set disabled provider should fail without -Force
            { Set-LLMProvider -Name 'disabled_provider' } | Should -Throw -ExpectedMessage "*disabled*"
            
            # Should work with -Force
            Set-LLMProvider -Name 'disabled_provider' -Force
            [System.Environment]::GetEnvironmentVariable('LLM_PROVIDER', 'Process') | Should -Be 'disabled_provider'
        }
    }
    
    Context "Provider Listing and Information" {
        It "Should list providers correctly" {
            # Load configuration from test file
            $config = ConvertFrom-IniFile -Path $script:TestConfigFile | ConvertTo-LLMConfiguration
            Mock Get-LLMConfiguration { return $config } -ModuleName Config
            
            $providers = Get-LLMProviders
            
            $providers.Count | Should -Be 3
            $providerNames = $providers | ForEach-Object { $_.Name }
            $providerNames | Should -Contain 'provider1'
            $providerNames | Should -Contain 'provider2'
            $providerNames | Should -Contain 'disabled_provider'
        }
        
        It "Should filter enabled providers correctly" {
            # Load configuration from test file
            $config = ConvertFrom-IniFile -Path $script:TestConfigFile | ConvertTo-LLMConfiguration
            Mock Get-LLMConfiguration { return $config } -ModuleName Config
            
            $enabledProviders = Get-LLMProviders -EnabledOnly
            
            $enabledProviders.Count | Should -Be 2
            $enabledNames = $enabledProviders | ForEach-Object { $_.Name }
            $enabledNames | Should -Contain 'provider1'
            $enabledNames | Should -Contain 'provider2'
            $enabledNames | Should -Not -Contain 'disabled_provider'
        }
        
        It "Should show current provider status correctly" {
            # Load configuration from test file
            $config = ConvertFrom-IniFile -Path $script:TestConfigFile | ConvertTo-LLMConfiguration
            Mock Get-LLMConfiguration { return $config } -ModuleName Config
            
            # No provider set initially
            $currentProvider = Get-LLMEnvironmentVariable -Name 'LLM_PROVIDER'
            $currentProvider | Should -BeNullOrEmpty
            
            # Set a provider
            Set-LLMProvider -Name 'provider1'
            
            $currentProvider = Get-LLMEnvironmentVariable -Name 'LLM_PROVIDER'
            $currentProvider | Should -Be 'provider1'
            
            # The Show-LLMProvider function should work without throwing
            { Show-LLMProvider } | Should -Not -Throw
        }
    }
    
    Context "Provider Validation and Testing" {
        It "Should validate provider configuration" {
            # Load configuration from test file
            $config = ConvertFrom-IniFile -Path $script:TestConfigFile | ConvertTo-LLMConfiguration
            Mock Get-LLMConfiguration { return $config } -ModuleName Config
            
            # Test valid provider
            $result = Test-LLMProvider -Name 'provider1'
            
            $result.ProviderName | Should -Be 'provider1'
            $result.IsValid | Should -Be $true
            $result.IsEnabled | Should -Be $true
            $result.HasApiKey | Should -Be $true
        }
        
        It "Should detect missing API keys" {
            # Remove one of the test API keys
            [System.Environment]::SetEnvironmentVariable('TEST_PROVIDER1_KEY', $null, 'Process')
            
            # Load configuration from test file
            $config = ConvertFrom-IniFile -Path $script:TestConfigFile | ConvertTo-LLMConfiguration
            Mock Get-LLMConfiguration { return $config } -ModuleName Config
            
            $result = Test-LLMProvider -Name 'provider1'
            
            $result.HasApiKey | Should -Be $false
            $result.Warnings | Should -Not -BeNullOrEmpty
        }
        
        It "Should test all providers in batch" {
            # Load configuration from test file
            $config = ConvertFrom-IniFile -Path $script:TestConfigFile | ConvertTo-LLMConfiguration
            Mock Get-LLMConfiguration { return $config } -ModuleName Config
            
            $results = Test-LLMProvider -All
            
            $results.Count | Should -Be 3
            
            $provider1Result = $results | Where-Object { $_.ProviderName -eq 'provider1' }
            $provider1Result.IsValid | Should -Be $true
            $provider1Result.HasApiKey | Should -Be $true
            
            $disabledResult = $results | Where-Object { $_.ProviderName -eq 'disabled_provider' }
            $disabledResult.IsEnabled | Should -Be $false
        }
    }
}

Describe "Configuration File Compatibility" -Tag "Integration", "Configuration" {
    
    Context "Real Configuration File Processing" {
        It "Should process bash-compatible configuration file" {
            # Create a configuration file that matches the bash version format
            $bashCompatConfig = Join-Path $script:TestDir "bash-compat.conf"
            $bashConfigContent = @"
# LLM Environment Manager Configuration
# This file defines available providers, their API endpoints, and default models

[openai]
base_url=https://api.openai.com/v1
api_key_var=LLM_OPENAI_API_KEY
default_model=gpt-4
description=Industry standard GPT models, highest quality
enabled=true

[anthropic]
base_url=https://api.anthropic.com/v1
api_key_var=LLM_ANTHROPIC_API_KEY
default_model=claude-3-5-sonnet-20241022
description=Anthropic Claude models with advanced reasoning
enabled=true

[gemini]
base_url=https://generativelanguage.googleapis.com/v1beta/openai
api_key_var=LLM_GEMINI_API_KEY
default_model=gemini-1.5-flash
description=Google Gemini models with native OpenAI compatibility
enabled=false

# Custom provider example
[custom_provider]
base_url=https://api.custom.com/v1
api_key_var=CUSTOM_API_KEY
default_model=custom-model-v1
description=Custom provider for testing
enabled=true
custom_property=custom_value
timeout=30
"@
            $bashConfigContent | Out-File -FilePath $bashCompatConfig -Encoding UTF8
            
            # Parse the configuration
            $parsedConfig = ConvertFrom-IniFile -Path $bashCompatConfig
            $config = ConvertTo-LLMConfiguration -ConfigData $parsedConfig
            
            # Verify all providers are loaded
            $config.Count() | Should -Be 4
            $config.HasProvider('openai') | Should -Be $true
            $config.HasProvider('anthropic') | Should -Be $true
            $config.HasProvider('gemini') | Should -Be $true
            $config.HasProvider('custom_provider') | Should -Be $true
            
            # Verify provider details
            $openaiProvider = $config.GetProvider('openai')
            $openaiProvider.BaseUrl | Should -Be 'https://api.openai.com/v1'
            $openaiProvider.ApiKeyVar | Should -Be 'LLM_OPENAI_API_KEY'
            $openaiProvider.DefaultModel | Should -Be 'gpt-4'
            $openaiProvider.Enabled | Should -Be $true
            
            $geminiProvider = $config.GetProvider('gemini')
            $geminiProvider.Enabled | Should -Be $false
            
            # Verify custom properties
            $customProvider = $config.GetProvider('custom_provider')
            $customProvider.AdditionalProperties['custom_property'] | Should -Be 'custom_value'
            $customProvider.AdditionalProperties['timeout'] | Should -Be '30'
        }
        
        It "Should handle configuration with various edge cases" {
            $edgeCaseConfig = Join-Path $script:TestDir "edge-case.conf"
            $edgeCaseContent = @"
# Configuration with edge cases

[quoted_values]
base_url="https://api.quoted.com/v1"
api_key_var='QUOTED_KEY'
default_model="model with spaces"
description=Unquoted description with spaces
enabled=true

[boolean_variations]
base_url=https://api.bool.com/v1
api_key_var=BOOL_KEY
enabled_true=true
enabled_false=false
enabled_yes=yes
enabled_no=no
enabled_on=on
enabled_off=off
enabled_1=1
enabled_0=0

[empty_and_special]
base_url=https://api.special.com/v1
api_key_var=SPECIAL_KEY
empty_value=
equals_in_value=key=value
enabled=true
"@
            $edgeCaseContent | Out-File -FilePath $edgeCaseConfig -Encoding UTF8
            
            # Parse and validate
            $parsedConfig = ConvertFrom-IniFile -Path $edgeCaseConfig
            $config = ConvertTo-LLMConfiguration -ConfigData $parsedConfig
            
            # Verify quoted values are handled correctly
            $quotedProvider = $config.GetProvider('quoted_values')
            $quotedProvider.BaseUrl | Should -Be 'https://api.quoted.com/v1'
            $quotedProvider.ApiKeyVar | Should -Be 'QUOTED_KEY'
            $quotedProvider.DefaultModel | Should -Be 'model with spaces'
            $quotedProvider.Description | Should -Be 'Unquoted description with spaces'
            
            # Verify boolean handling
            $boolProvider = $config.GetProvider('boolean_variations')
            $boolProvider.AdditionalProperties['enabled_true'] | Should -Be 'true'
            $boolProvider.AdditionalProperties['enabled_false'] | Should -Be 'false'
            $boolProvider.AdditionalProperties['enabled_yes'] | Should -Be 'true'
            $boolProvider.AdditionalProperties['enabled_no'] | Should -Be 'false'
            
            # Verify special cases
            $specialProvider = $config.GetProvider('empty_and_special')
            $specialProvider.AdditionalProperties['empty_value'] | Should -Be ''
            $specialProvider.AdditionalProperties['equals_in_value'] | Should -Be 'key=value'
        }
    }
    
    Context "Configuration Precedence and Merging" {
        It "Should handle configuration precedence correctly" {
            # Create base configuration
            $baseConfig = Join-Path $script:TestDir "base.conf"
            $baseContent = @"
[provider1]
base_url=https://base.provider1.com/v1
api_key_var=BASE_PROVIDER1_KEY
default_model=base-model
description=Base Provider 1
enabled=true
priority=low

[provider2]
base_url=https://base.provider2.com/v1
api_key_var=BASE_PROVIDER2_KEY
default_model=base-model-2
enabled=false
"@
            $baseContent | Out-File -FilePath $baseConfig -Encoding UTF8
            
            # Create override configuration
            $overrideConfig = Join-Path $script:TestDir "override.conf"
            $overrideContent = @"
[provider1]
base_url=https://override.provider1.com/v1
default_model=override-model
description=Override Provider 1
priority=high

[provider3]
base_url=https://override.provider3.com/v1
api_key_var=OVERRIDE_PROVIDER3_KEY
default_model=new-model
description=New Provider 3
enabled=true
"@
            $overrideContent | Out-File -FilePath $overrideConfig -Encoding UTF8
            
            # Load and merge configurations
            $baseConfigData = ConvertFrom-IniFile -Path $baseConfig
            $overrideConfigData = ConvertFrom-IniFile -Path $overrideConfig
            $baseConfigObj = ConvertTo-LLMConfiguration -ConfigData $baseConfigData
            $overrideConfigObj = ConvertTo-LLMConfiguration -ConfigData $overrideConfigData
            
            $mergedConfig = Merge-LLMConfiguration -BaseConfiguration $baseConfigObj -OverrideConfiguration $overrideConfigObj
            
            # Verify merged results
            $mergedConfig.Count() | Should -Be 3
            
            # Provider1 should be overridden but retain some base values
            $mergedProvider1 = $mergedConfig.GetProvider('provider1')
            $mergedProvider1.BaseUrl | Should -Be 'https://override.provider1.com/v1'  # Overridden
            $mergedProvider1.ApiKeyVar | Should -Be 'BASE_PROVIDER1_KEY'  # From base (not in override)
            $mergedProvider1.DefaultModel | Should -Be 'override-model'  # Overridden
            $mergedProvider1.AdditionalProperties['priority'] | Should -Be 'high'  # Overridden
            
            # Provider2 should remain from base
            $mergedProvider2 = $mergedConfig.GetProvider('provider2')
            $mergedProvider2.BaseUrl | Should -Be 'https://base.provider2.com/v1'
            $mergedProvider2.Enabled | Should -Be $false
            
            # Provider3 should be new from override
            $mergedProvider3 = $mergedConfig.GetProvider('provider3')
            $mergedProvider3.BaseUrl | Should -Be 'https://override.provider3.com/v1'
            $mergedProvider3.Description | Should -Be 'New Provider 3'
        }
    }
}

Describe "Environment Variable Management" -Tag "Integration", "Environment" {
    
    Context "Complete Environment Setup and Cleanup" {
        It "Should manage environment variables correctly throughout workflow" {
            # Create test configuration
            $testConfig = New-LLMConfiguration
            $provider = [LLMProvider]::new(@{
                name = 'env_test_provider'
                base_url = 'https://api.envtest.com/v1'
                api_key_var = 'ENV_TEST_KEY'
                default_model = 'env-test-model'
                enabled = 'true'
            })
            $testConfig.AddProvider($provider)
            
            # Set test API key
            [System.Environment]::SetEnvironmentVariable('ENV_TEST_KEY', 'test-api-key-value', 'Process')
            
            Mock Get-LLMConfiguration { return $testConfig } -ModuleName Config
            
            # Verify clean state
            [System.Environment]::GetEnvironmentVariable('LLM_PROVIDER', 'Process') | Should -BeNullOrEmpty
            [System.Environment]::GetEnvironmentVariable('LLM_BASE_URL', 'Process') | Should -BeNullOrEmpty
            
            # Set provider
            Set-LLMProvider -Name 'env_test_provider'
            
            # Verify all expected environment variables are set
            [System.Environment]::GetEnvironmentVariable('LLM_PROVIDER', 'Process') | Should -Be 'env_test_provider'
            [System.Environment]::GetEnvironmentVariable('LLM_BASE_URL', 'Process') | Should -Be 'https://api.envtest.com/v1'
            [System.Environment]::GetEnvironmentVariable('LLM_MODEL', 'Process') | Should -Be 'env-test-model'
            [System.Environment]::GetEnvironmentVariable('LLM_API_KEY_VAR', 'Process') | Should -Be 'ENV_TEST_KEY'
            [System.Environment]::GetEnvironmentVariable('OPENAI_BASE_URL', 'Process') | Should -Be 'https://api.envtest.com/v1'
            [System.Environment]::GetEnvironmentVariable('OPENAI_API_KEY', 'Process') | Should -Be 'test-api-key-value'
            
            # Clear provider
            Clear-LLMProvider
            
            # Verify all LLM environment variables are cleared
            [System.Environment]::GetEnvironmentVariable('LLM_PROVIDER', 'Process') | Should -BeNullOrEmpty
            [System.Environment]::GetEnvironmentVariable('LLM_BASE_URL', 'Process') | Should -BeNullOrEmpty
            [System.Environment]::GetEnvironmentVariable('LLM_MODEL', 'Process') | Should -BeNullOrEmpty
            [System.Environment]::GetEnvironmentVariable('LLM_API_KEY_VAR', 'Process') | Should -BeNullOrEmpty
            [System.Environment]::GetEnvironmentVariable('OPENAI_BASE_URL', 'Process') | Should -BeNullOrEmpty
            [System.Environment]::GetEnvironmentVariable('OPENAI_API_KEY', 'Process') | Should -BeNullOrEmpty
            
            # But original API key should remain untouched
            [System.Environment]::GetEnvironmentVariable('ENV_TEST_KEY', 'Process') | Should -Be 'test-api-key-value'
        }
        
        It "Should handle model override correctly" {
            # Create test configuration
            $testConfig = New-LLMConfiguration
            $provider = [LLMProvider]::new(@{
                name = 'model_test_provider'
                base_url = 'https://api.modeltest.com/v1'
                api_key_var = 'MODEL_TEST_KEY'
                default_model = 'default-model'
                enabled = 'true'
            })
            $testConfig.AddProvider($provider)
            
            [System.Environment]::SetEnvironmentVariable('MODEL_TEST_KEY', 'test-key', 'Process')
            Mock Get-LLMConfiguration { return $testConfig } -ModuleName Config
            
            # Set provider with model override
            Set-LLMProvider -Name 'model_test_provider' -Model 'custom-override-model'
            
            [System.Environment]::GetEnvironmentVariable('LLM_MODEL', 'Process') | Should -Be 'custom-override-model'
            [System.Environment]::GetEnvironmentVariable('LLM_PROVIDER', 'Process') | Should -Be 'model_test_provider'
            [System.Environment]::GetEnvironmentVariable('LLM_BASE_URL', 'Process') | Should -Be 'https://api.modeltest.com/v1'
        }
    }
    
    Context "Provider History Management" {
        It "Should track provider history correctly" {
            # Create test configuration with multiple providers
            $testConfig = New-LLMConfiguration
            
            $provider1 = [LLMProvider]::new(@{
                name = 'history_provider1'
                base_url = 'https://api.history1.com/v1'
                api_key_var = 'HISTORY1_KEY'
                enabled = 'true'
            })
            
            $provider2 = [LLMProvider]::new(@{
                name = 'history_provider2'
                base_url = 'https://api.history2.com/v1'
                api_key_var = 'HISTORY2_KEY'
                enabled = 'true'
            })
            
            $provider3 = [LLMProvider]::new(@{
                name = 'history_provider3'
                base_url = 'https://api.history3.com/v1'
                api_key_var = 'HISTORY3_KEY'
                enabled = 'true'
            })
            
            $testConfig.AddProvider($provider1)
            $testConfig.AddProvider($provider2)
            $testConfig.AddProvider($provider3)
            
            Mock Get-LLMConfiguration { return $testConfig } -ModuleName Config
            
            # Set API keys
            [System.Environment]::SetEnvironmentVariable('HISTORY1_KEY', 'key1', 'Process')
            [System.Environment]::SetEnvironmentVariable('HISTORY2_KEY', 'key2', 'Process')
            [System.Environment]::SetEnvironmentVariable('HISTORY3_KEY', 'key3', 'Process')
            
            # Switch through providers and verify history tracking
            Set-LLMProvider -Name 'history_provider1'
            [System.Environment]::GetEnvironmentVariable('LLM_PROVIDER', 'Process') | Should -Be 'history_provider1'
            [System.Environment]::GetEnvironmentVariable('LLM_PREVIOUS_PROVIDER', 'Process') | Should -BeNullOrEmpty
            
            Set-LLMProvider -Name 'history_provider2'
            [System.Environment]::GetEnvironmentVariable('LLM_PROVIDER', 'Process') | Should -Be 'history_provider2'
            [System.Environment]::GetEnvironmentVariable('LLM_PREVIOUS_PROVIDER', 'Process') | Should -Be 'history_provider1'
            
            Set-LLMProvider -Name 'history_provider3'
            [System.Environment]::GetEnvironmentVariable('LLM_PROVIDER', 'Process') | Should -Be 'history_provider3'
            [System.Environment]::GetEnvironmentVariable('LLM_PREVIOUS_PROVIDER', 'Process') | Should -Be 'history_provider2'
            
            # Test restore previous
            Clear-LLMProvider -RestorePrevious
            [System.Environment]::GetEnvironmentVariable('LLM_PROVIDER', 'Process') | Should -Be 'history_provider2'
            [System.Environment]::GetEnvironmentVariable('LLM_BASE_URL', 'Process') | Should -Be 'https://api.history2.com/v1'
        }
    }
}