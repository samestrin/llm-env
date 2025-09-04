#Requires -Modules @{ModuleName='Pester'; ModuleVersion='5.0.0'}

<#
.SYNOPSIS
    Integration tests for PowerShell LLM Environment Manager
.DESCRIPTION
    Tests individual components and their integration where possible
    Note: Full module integration is currently blocked by architectural issues
#>

Describe "PowerShell DataModels Integration" {
    BeforeAll {
        # Load DataModels directly
        . "$PSScriptRoot/../../lib/DataModels.ps1"
    }

    Context "LLMProvider Class" {
        It "Should create LLMProvider instance" {
            $provider = [LLMProvider]::new()
            $provider | Should -Not -BeNullOrEmpty
            $provider.GetType().Name | Should -Be "LLMProvider"
        }

        It "Should validate provider data correctly" {
            $provider = [LLMProvider]::new()
            $provider.Name = "test"
            $provider.BaseUrl = "https://api.test.com/v1"
            $provider.ApiKeyVar = "TEST_API_KEY"
            $provider.DefaultModel = "test-model"
            $provider.Enabled = $true

            $provider.IsValid() | Should -Be $true
        }

        It "Should detect invalid provider data" {
            $provider = [LLMProvider]::new()
            # Missing required fields
            $provider.IsValid() | Should -Be $false
        }
    }

    Context "LLMConfiguration Class" {
        It "Should create configuration instance" {
            $config = [LLMConfiguration]::new()
            $config | Should -Not -BeNullOrEmpty
            $config.GetType().Name | Should -Be "LLMConfiguration"
        }

        It "Should add and retrieve providers" {
            $config = [LLMConfiguration]::new()
            
            $provider = [LLMProvider]::new()
            $provider.Name = "test"
            $provider.BaseUrl = "https://api.test.com/v1"
            $provider.ApiKeyVar = "TEST_API_KEY"
            $provider.DefaultModel = "test-model"
            $provider.Enabled = $true

            $config.AddProvider($provider)
            
            $retrieved = $config.GetProvider("test")
            $retrieved | Should -Not -BeNullOrEmpty
            $retrieved.Name | Should -Be "test"
        }

        It "Should list all providers" {
            $config = [LLMConfiguration]::new()
            
            # Add test providers
            for ($i = 1; $i -le 3; $i++) {
                $provider = [LLMProvider]::new()
                $provider.Name = "test$i"
                $provider.BaseUrl = "https://api.test$i.com/v1"
                $provider.ApiKeyVar = "TEST${i}_API_KEY"
                $provider.DefaultModel = "test-model-$i"
                $provider.Enabled = $true
                $config.AddProvider($provider)
            }

            $providers = $config.GetAllProviders()
            $providers.Count | Should -Be 3
        }
    }
}

Describe "PowerShell Module Dependencies" {
    Context "Individual Module Loading" {
        It "Should load DataModels without errors" {
            { . "$PSScriptRoot/../../lib/DataModels.ps1" } | Should -Not -Throw
        }

        It "Should load WindowsIntegration module" {
            { Import-Module "$PSScriptRoot/../../lib/WindowsIntegration.psm1" -Force } | Should -Not -Throw
        }

        It "Should load IniParser module" {
            { Import-Module "$PSScriptRoot/../../lib/IniParser.psm1" -Force } | Should -Not -Throw
        }
    }

    Context "Dependency Chain Loading" {
        BeforeAll {
            # Load in dependency order
            . "$PSScriptRoot/../../lib/DataModels.ps1"
            Import-Module "$PSScriptRoot/../../lib/WindowsIntegration.psm1" -Force
            Import-Module "$PSScriptRoot/../../lib/IniParser.psm1" -Force
            Import-Module "$PSScriptRoot/../../lib/Config.psm1" -Force
        }

        It "Should have configuration functions available" {
            Get-Command "Get-LLMConfiguration" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Should load configuration successfully" {
            { $config = Get-LLMConfiguration } | Should -Not -Throw
        }

        It "Should return configuration with providers" {
            $config = Get-LLMConfiguration
            $providers = $config.GetAllProviders()
            $providers.Count | Should -BeGreaterThan 0
        }
    }
}

Describe "PowerShell Configuration System" {
    BeforeAll {
        # Load dependencies
        . "$PSScriptRoot/../../lib/DataModels.ps1"
        Import-Module "$PSScriptRoot/../../lib/WindowsIntegration.psm1" -Force
        Import-Module "$PSScriptRoot/../../lib/IniParser.psm1" -Force
        Import-Module "$PSScriptRoot/../../lib/Config.psm1" -Force
    }

    Context "Configuration Loading" {
        It "Should load built-in configuration" {
            $config = Get-LLMConfiguration
            $config | Should -Not -BeNullOrEmpty
            $config.GetType().Name | Should -Be "LLMConfiguration"
        }

        It "Should contain expected providers" {
            $config = Get-LLMConfiguration
            $providers = $config.GetAllProviders()
            
            # Check for common providers
            $providerNames = $providers | ForEach-Object { $_.Name }
            $providerNames | Should -Contain "openai"
            $providerNames | Should -Contain "anthropic"
        }

        It "Should cache configuration correctly" {
            # First load
            $config1 = Get-LLMConfiguration
            
            # Second load (should be cached)
            $config2 = Get-LLMConfiguration
            
            # Should return same instance or equivalent data
            $config1.GetAllProviders().Count | Should -Be $config2.GetAllProviders().Count
        }
    }

    Context "Configuration Caching" {
        It "Should clear cache when requested" {
            $config1 = Get-LLMConfiguration
            Clear-LLMConfigurationCache
            $config2 = Get-LLMConfiguration
            
            # Both should work (cache clearing shouldn't break functionality)
            $config1 | Should -Not -BeNullOrEmpty
            $config2 | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "PowerShell Path Functions" {
    BeforeAll {
        Import-Module "$PSScriptRoot/../../lib/WindowsIntegration.psm1" -Force
    }

    Context "Configuration Path Functions" {
        It "Should return valid config directory" {
            $configDir = Get-LLMConfigDirectory
            $configDir | Should -Not -BeNullOrEmpty
            [System.IO.Path]::IsPathRooted($configDir) | Should -Be $true
        }

        It "Should return valid config file path" {
            $configFile = Get-LLMConfigFilePath
            $configFile | Should -Not -BeNullOrEmpty
            $configFile | Should -BeLike "*config.conf"
        }

        It "Should return search paths array" {
            $searchPaths = Get-LLMConfigSearchPaths
            $searchPaths | Should -Not -BeNullOrEmpty
            $searchPaths.Count | Should -BeGreaterThan 0
        }
    }

    Context "Environment Variable Functions" {
        It "Should set and get environment variables" {
            Set-LLMEnvironmentVariable -Name "TEST_VAR" -Value "test_value"
            $value = Get-LLMEnvironmentVariable -Name "TEST_VAR"
            $value | Should -Be "test_value"
        }

        It "Should return default value for missing variables" {
            $value = Get-LLMEnvironmentVariable -Name "NONEXISTENT_VAR" -DefaultValue "default"
            $value | Should -Be "default"
        }
    }
}