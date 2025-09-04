#Requires -Version 5.1
<#
.SYNOPSIS
    Unit tests for LLM Environment Manager data models
.DESCRIPTION
    Comprehensive unit tests for LLMProvider and LLMConfiguration classes
    using Pester testing framework
.NOTES
    Run with: Invoke-Pester -Path tests/powershell/unit/DataModels.Tests.ps1
#>

# Import the module being tested
BeforeAll {
    $ModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    Import-Module (Join-Path $ModuleRoot 'llm-env.psd1') -Force
    
    # Also import the data models directly
    Import-Module (Join-Path $ModuleRoot 'lib/Config.psm1') -Force
}

Describe "LLMProvider Class Tests" -Tag "Unit", "DataModels" {
    
    Context "Constructor Tests" {
        It "Should create empty provider with default constructor" {
            $provider = [LLMProvider]::new()
            
            $provider.Name | Should -BeNullOrEmpty
            $provider.BaseUrl | Should -BeNullOrEmpty
            $provider.ApiKeyVar | Should -BeNullOrEmpty
            $provider.DefaultModel | Should -BeNullOrEmpty
            $provider.Description | Should -BeNullOrEmpty
            $provider.Enabled | Should -Be $true
            $provider.AdditionalProperties | Should -Not -BeNullOrEmpty
            $provider.AdditionalProperties.Count | Should -Be 0
        }
        
        It "Should create provider from hashtable" {
            $properties = @{
                name = 'test-provider'
                base_url = 'https://api.test.com/v1'
                api_key_var = 'TEST_API_KEY'
                default_model = 'test-model'
                description = 'Test provider'
                enabled = 'true'
                custom_property = 'custom_value'
            }
            
            $provider = [LLMProvider]::new($properties)
            
            $provider.Name | Should -Be 'test-provider'
            $provider.BaseUrl | Should -Be 'https://api.test.com/v1'
            $provider.ApiKeyVar | Should -Be 'TEST_API_KEY'
            $provider.DefaultModel | Should -Be 'test-model'
            $provider.Description | Should -Be 'Test provider'
            $provider.Enabled | Should -Be $true
            $provider.AdditionalProperties['custom_property'] | Should -Be 'custom_value'
        }
        
        It "Should handle boolean enabled values correctly" {
            $testCases = @(
                @{ enabled = 'true'; expected = $true }
                @{ enabled = 'false'; expected = $false }
                @{ enabled = $true; expected = $true }
                @{ enabled = $false; expected = $false }
                @{ enabled = 'yes'; expected = $false }  # Only 'true' string is treated as true
            )
            
            foreach ($case in $testCases) {
                $properties = @{ enabled = $case.enabled }
                $provider = [LLMProvider]::new($properties)
                $provider.Enabled | Should -Be $case.expected -Because "enabled='$($case.enabled)' should be $($case.expected)"
            }
        }
    }
    
    Context "Validation Tests" {
        It "Should validate complete provider as valid" {
            $provider = [LLMProvider]::new(@{
                name = 'valid-provider'
                base_url = 'https://api.valid.com/v1'
                api_key_var = 'VALID_API_KEY'
                default_model = 'valid-model'
            })
            
            $provider.IsValid() | Should -Be $true
        }
        
        It "Should invalidate provider with missing required fields" {
            $testCases = @(
                @{ name = $null; base_url = 'https://api.test.com'; api_key_var = 'TEST_KEY' }
                @{ name = 'test'; base_url = $null; api_key_var = 'TEST_KEY' }
                @{ name = 'test'; base_url = 'https://api.test.com'; api_key_var = $null }
                @{ name = ''; base_url = 'https://api.test.com'; api_key_var = 'TEST_KEY' }
                @{ name = 'test'; base_url = ''; api_key_var = 'TEST_KEY' }
                @{ name = 'test'; base_url = 'https://api.test.com'; api_key_var = '' }
            )
            
            foreach ($case in $testCases) {
                $provider = [LLMProvider]::new()
                $provider.Name = $case.name
                $provider.BaseUrl = $case.base_url
                $provider.ApiKeyVar = $case.api_key_var
                
                $provider.IsValid() | Should -Be $false -Because "Provider with Name='$($case.name)', BaseUrl='$($case.base_url)', ApiKeyVar='$($case.api_key_var)' should be invalid"
            }
        }
    }
    
    Context "Hashtable Conversion Tests" {
        It "Should convert to hashtable correctly" {
            $provider = [LLMProvider]::new(@{
                name = 'test-provider'
                base_url = 'https://api.test.com/v1'
                api_key_var = 'TEST_API_KEY'
                default_model = 'test-model'
                description = 'Test provider'
                enabled = 'true'
                custom_property = 'custom_value'
            })
            
            $hashtable = $provider.ToHashtable()
            
            $hashtable['name'] | Should -Be 'test-provider'
            $hashtable['base_url'] | Should -Be 'https://api.test.com/v1'
            $hashtable['api_key_var'] | Should -Be 'TEST_API_KEY'
            $hashtable['default_model'] | Should -Be 'test-model'
            $hashtable['description'] | Should -Be 'Test provider'
            $hashtable['enabled'] | Should -Be 'true'
            $hashtable['custom_property'] | Should -Be 'custom_value'
        }
        
        It "Should handle boolean enabled in hashtable conversion" {
            $provider = [LLMProvider]::new()
            $provider.Enabled = $false
            
            $hashtable = $provider.ToHashtable()
            $hashtable['enabled'] | Should -Be 'false'
        }
    }
    
    Context "String Representation Tests" {
        It "Should provide meaningful string representation" {
            $provider = [LLMProvider]::new(@{
                name = 'test-provider'
                base_url = 'https://api.test.com/v1'
                enabled = 'true'
            })
            
            $string = $provider.ToString()
            $string | Should -Match 'test-provider'
            $string | Should -Match 'enabled'
            $string | Should -Match 'https://api.test.com/v1'
        }
        
        It "Should show disabled status in string representation" {
            $provider = [LLMProvider]::new(@{
                name = 'disabled-provider'
                base_url = 'https://api.test.com/v1'
                enabled = 'false'
            })
            
            $string = $provider.ToString()
            $string | Should -Match 'disabled-provider'
            $string | Should -Match 'disabled'
        }
    }
}

Describe "LLMConfiguration Class Tests" -Tag "Unit", "DataModels" {
    
    Context "Constructor Tests" {
        It "Should create empty configuration with default constructor" {
            $config = [LLMConfiguration]::new()
            
            $config.Providers | Should -Not -BeNullOrEmpty
            $config.Providers.Count | Should -Be 0
            $config.ConfigPath | Should -BeNullOrEmpty
            $config.LastModified | Should -Not -BeNullOrEmpty
            $config.Metadata | Should -Not -BeNullOrEmpty
            $config.Metadata.Count | Should -Be 0
        }
        
        It "Should create configuration with config path" {
            $testPath = "/test/path/config.conf"
            $config = [LLMConfiguration]::new($testPath)
            
            $config.ConfigPath | Should -Be $testPath
            $config.LastModified | Should -Not -BeNullOrEmpty
        }
        
        It "Should set LastModified from file if path exists" {
            # Create a temporary test file
            $tempFile = [System.IO.Path]::GetTempFileName()
            try {
                "test content" | Out-File -FilePath $tempFile -Encoding UTF8
                Start-Sleep -Milliseconds 100  # Ensure file is written
                
                $config = [LLMConfiguration]::new($tempFile)
                
                $config.ConfigPath | Should -Be $tempFile
                $config.LastModified | Should -BeOfType [datetime]
                $config.LastModified | Should -BeLessThan (Get-Date)
            }
            finally {
                Remove-Item $tempFile -ErrorAction SilentlyContinue
            }
        }
    }
    
    Context "Provider Management Tests" {
        BeforeEach {
            $config = [LLMConfiguration]::new()
            $testProvider = [LLMProvider]::new(@{
                name = 'test-provider'
                base_url = 'https://api.test.com/v1'
                api_key_var = 'TEST_API_KEY'
                default_model = 'test-model'
            })
        }
        
        It "Should add provider successfully" {
            $config.AddProvider($testProvider)
            
            $config.Count() | Should -Be 1
            $config.HasProvider('test-provider') | Should -Be $true
        }
        
        It "Should add provider by name and properties" {
            $properties = @{
                base_url = 'https://api.test2.com/v1'
                api_key_var = 'TEST2_API_KEY'
                default_model = 'test2-model'
            }
            
            $config.AddProvider('test2-provider', $properties)
            
            $config.Count() | Should -Be 1
            $config.HasProvider('test2-provider') | Should -Be $true
            
            $addedProvider = $config.GetProvider('test2-provider')
            $addedProvider.Name | Should -Be 'test2-provider'
            $addedProvider.BaseUrl | Should -Be 'https://api.test2.com/v1'
        }
        
        It "Should throw on invalid provider" {
            $invalidProvider = [LLMProvider]::new(@{
                name = 'invalid-provider'
                # Missing required fields
            })
            
            { $config.AddProvider($invalidProvider) } | Should -Throw -ExpectedMessage "*Invalid provider*"
        }
        
        It "Should retrieve provider by name" {
            $config.AddProvider($testProvider)
            
            $retrieved = $config.GetProvider('test-provider')
            $retrieved | Should -Not -BeNullOrEmpty
            $retrieved.Name | Should -Be 'test-provider'
        }
        
        It "Should return null for non-existent provider" {
            $retrieved = $config.GetProvider('non-existent')
            $retrieved | Should -BeNullOrEmpty
        }
        
        It "Should remove provider successfully" {
            $config.AddProvider($testProvider)
            $config.HasProvider('test-provider') | Should -Be $true
            
            $config.RemoveProvider('test-provider')
            
            $config.HasProvider('test-provider') | Should -Be $false
            $config.Count() | Should -Be 0
        }
        
        It "Should handle removing non-existent provider gracefully" {
            $config.RemoveProvider('non-existent')
            $config.Count() | Should -Be 0  # Should not crash
        }
    }
    
    Context "Provider Filtering Tests" {
        BeforeEach {
            $config = [LLMConfiguration]::new()
            
            # Add enabled provider
            $enabledProvider = [LLMProvider]::new(@{
                name = 'enabled-provider'
                base_url = 'https://api.enabled.com/v1'
                api_key_var = 'ENABLED_API_KEY'
                enabled = 'true'
            })
            $config.AddProvider($enabledProvider)
            
            # Add disabled provider
            $disabledProvider = [LLMProvider]::new(@{
                name = 'disabled-provider'
                base_url = 'https://api.disabled.com/v1'
                api_key_var = 'DISABLED_API_KEY'
                enabled = 'false'
            })
            $config.AddProvider($disabledProvider)
        }
        
        It "Should get all providers" {
            $allProviders = $config.GetAllProviders()
            $allProviders.Count | Should -Be 2
            
            $names = $allProviders | ForEach-Object { $_.Name }
            $names | Should -Contain 'enabled-provider'
            $names | Should -Contain 'disabled-provider'
        }
        
        It "Should get only enabled providers" {
            $enabledProviders = $config.GetEnabledProviders()
            $enabledProviders.Count | Should -Be 1
            $enabledProviders[0].Name | Should -Be 'enabled-provider'
            $enabledProviders[0].Enabled | Should -Be $true
        }
    }
    
    Context "Configuration Conversion Tests" {
        It "Should convert to hashtable correctly" {
            $config = [LLMConfiguration]::new()
            
            $provider1 = [LLMProvider]::new(@{
                name = 'provider1'
                base_url = 'https://api1.com'
                api_key_var = 'API1_KEY'
            })
            $provider2 = [LLMProvider]::new(@{
                name = 'provider2'
                base_url = 'https://api2.com'
                api_key_var = 'API2_KEY'
            })
            
            $config.AddProvider($provider1)
            $config.AddProvider($provider2)
            
            $hashtable = $config.ToHashtable()
            
            $hashtable.Keys.Count | Should -Be 2
            $hashtable.ContainsKey('provider1') | Should -Be $true
            $hashtable.ContainsKey('provider2') | Should -Be $true
            
            $hashtable['provider1']['base_url'] | Should -Be 'https://api1.com'
            $hashtable['provider2']['base_url'] | Should -Be 'https://api2.com'
        }
    }
    
    Context "Provider Count Tests" {
        It "Should return correct count for empty configuration" {
            $config = [LLMConfiguration]::new()
            $config.Count() | Should -Be 0
        }
        
        It "Should return correct count with providers" {
            $config = [LLMConfiguration]::new()
            
            for ($i = 1; $i -le 5; $i++) {
                $provider = [LLMProvider]::new(@{
                    name = "provider$i"
                    base_url = "https://api$i.com"
                    api_key_var = "API${i}_KEY"
                })
                $config.AddProvider($provider)
            }
            
            $config.Count() | Should -Be 5
        }
    }
}

Describe "Data Validation Functions Tests" -Tag "Unit", "DataModels" {
    
    Context "Test-LLMProviderData Tests" {
        It "Should validate complete provider data" {
            $validData = @{
                name = 'valid-provider'
                base_url = 'https://api.valid.com/v1'
                api_key_var = 'VALID_API_KEY'
                default_model = 'valid-model'
                description = 'Valid provider'
                enabled = 'true'
            }
            
            { Test-LLMProviderData -ProviderData $validData } | Should -Not -Throw
        }
        
        It "Should throw for missing required fields" {
            $testCases = @(
                @{ base_url = 'https://api.test.com'; api_key_var = 'TEST_KEY' }  # Missing name
                @{ name = 'test'; api_key_var = 'TEST_KEY' }  # Missing base_url
                @{ name = 'test'; base_url = 'https://api.test.com' }  # Missing api_key_var
            )
            
            foreach ($case in $testCases) {
                { Test-LLMProviderData -ProviderData $case } | Should -Throw -ExpectedMessage "*missing required fields*"
            }
        }
        
        It "Should throw for invalid URL format" {
            $invalidData = @{
                name = 'test'
                base_url = 'not-a-valid-url'
                api_key_var = 'TEST_KEY'
            }
            
            { Test-LLMProviderData -ProviderData $invalidData } | Should -Throw -ExpectedMessage "*Invalid base_url format*"
        }
        
        It "Should warn for non-standard API key variable names" {
            $warningData = @{
                name = 'test'
                base_url = 'https://api.test.com'
                api_key_var = 'lowercase_key'  # Should be uppercase
            }
            
            $warnings = @()
            Test-LLMProviderData -ProviderData $warningData -WarningAction SilentlyContinue -WarningVariable warnings
            $warnings | Should -Not -BeNullOrEmpty
            $warnings[0] | Should -Match "*uppercase letters*"
        }
    }
    
    Context "ConvertTo-LLMProvider Tests" {
        It "Should convert valid data to LLMProvider" {
            $validData = @{
                base_url = 'https://api.test.com/v1'
                api_key_var = 'TEST_API_KEY'
                default_model = 'test-model'
                description = 'Test provider'
                enabled = 'true'
            }
            
            $provider = ConvertTo-LLMProvider -Name 'test-provider' -Properties $validData
            
            $provider | Should -BeOfType [LLMProvider]
            $provider.Name | Should -Be 'test-provider'
            $provider.BaseUrl | Should -Be 'https://api.test.com/v1'
            $provider.ApiKeyVar | Should -Be 'TEST_API_KEY'
            $provider.IsValid() | Should -Be $true
        }
        
        It "Should throw for invalid provider data" {
            $invalidData = @{
                base_url = 'invalid-url'
                api_key_var = 'TEST_KEY'
            }
            
            { ConvertTo-LLMProvider -Name 'invalid-provider' -Properties $invalidData } | Should -Throw
        }
    }
    
    Context "New-LLMConfiguration Tests" {
        It "Should create configuration without path" {
            $config = New-LLMConfiguration
            
            $config | Should -BeOfType [LLMConfiguration]
            $config.ConfigPath | Should -BeNullOrEmpty
        }
        
        It "Should create configuration with path" {
            $testPath = "/test/config.conf"
            $config = New-LLMConfiguration -ConfigPath $testPath
            
            $config | Should -BeOfType [LLMConfiguration]
            $config.ConfigPath | Should -Be $testPath
        }
    }
}

Describe "Environment Variable Management Tests" -Tag "Unit", "DataModels" {
    
    Context "LLMEnvironmentVariable Tests" {
        BeforeEach {
            # Clean up any existing test environment variables
            [System.Environment]::SetEnvironmentVariable('TEST_LLM_VAR', $null, 'Process')
        }
        
        AfterEach {
            # Clean up test environment variables
            [System.Environment]::SetEnvironmentVariable('TEST_LLM_VAR', $null, 'Process')
        }
        
        It "Should create environment variable object correctly" {
            # Set a test value first
            [System.Environment]::SetEnvironmentVariable('TEST_LLM_VAR', 'original_value', 'Process')
            
            $envVar = [LLMEnvironmentVariable]::new('TEST_LLM_VAR', 'new_value')
            
            $envVar.Name | Should -Be 'TEST_LLM_VAR'
            $envVar.Value | Should -Be 'new_value'
            $envVar.OriginalValue | Should -Be 'original_value'
            $envVar.WasSet | Should -Be $true
        }
        
        It "Should handle unset environment variable" {
            $envVar = [LLMEnvironmentVariable]::new('TEST_LLM_VAR', 'new_value')
            
            $envVar.Name | Should -Be 'TEST_LLM_VAR'
            $envVar.Value | Should -Be 'new_value'
            $envVar.OriginalValue | Should -BeNullOrEmpty
            $envVar.WasSet | Should -Be $false
        }
        
        It "Should set environment variable" {
            $envVar = [LLMEnvironmentVariable]::new('TEST_LLM_VAR', 'test_value')
            
            $envVar.Set()
            
            [System.Environment]::GetEnvironmentVariable('TEST_LLM_VAR', 'Process') | Should -Be 'test_value'
        }
        
        It "Should restore original environment variable" {
            # Set original value
            [System.Environment]::SetEnvironmentVariable('TEST_LLM_VAR', 'original_value', 'Process')
            
            $envVar = [LLMEnvironmentVariable]::new('TEST_LLM_VAR', 'new_value')
            $envVar.Set()
            
            # Verify new value is set
            [System.Environment]::GetEnvironmentVariable('TEST_LLM_VAR', 'Process') | Should -Be 'new_value'
            
            # Restore original
            $envVar.Restore()
            
            [System.Environment]::GetEnvironmentVariable('TEST_LLM_VAR', 'Process') | Should -Be 'original_value'
        }
        
        It "Should clear environment variable when restoring unset variable" {
            $envVar = [LLMEnvironmentVariable]::new('TEST_LLM_VAR', 'new_value')
            $envVar.Set()
            
            # Verify value is set
            [System.Environment]::GetEnvironmentVariable('TEST_LLM_VAR', 'Process') | Should -Be 'new_value'
            
            # Restore (should clear since it wasn't originally set)
            $envVar.Restore()
            
            [System.Environment]::GetEnvironmentVariable('TEST_LLM_VAR', 'Process') | Should -BeNullOrEmpty
        }
        
        It "Should provide correct string representation" {
            $envVar = [LLMEnvironmentVariable]::new('TEST_VAR', 'test_value')
            
            $string = $envVar.ToString()
            $string | Should -Be 'TEST_VAR=test_value'
        }
    }
}