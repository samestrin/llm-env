#Requires -Version 5.1
<#
.SYNOPSIS
    Unit tests for LLM Environment Manager configuration system
.DESCRIPTION
    Comprehensive unit tests for configuration loading, INI parsing, and provider registry
    using Pester testing framework
.NOTES
    Run with: Invoke-Pester -Path tests/powershell/unit/Config.Tests.ps1
#>

# Import the module being tested
BeforeAll {
    $ModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    Import-Module (Join-Path $ModuleRoot 'llm-env.psd1') -Force
    
    # Import individual modules for testing
    . (Join-Path $ModuleRoot 'lib/DataModels.ps1')
    Import-Module (Join-Path $ModuleRoot 'lib/IniParser.psm1') -Force
    Import-Module (Join-Path $ModuleRoot 'lib/Config.psm1') -Force
    
    # Create temporary directory for test files
    $script:TestDir = Join-Path ([System.IO.Path]::GetTempPath()) "LLMEnvTests-$([System.Guid]::NewGuid())"
    New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
}

AfterAll {
    # Clean up temporary test directory
    if (Test-Path $script:TestDir) {
        Remove-Item $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe "INI Parser Tests" -Tag "Unit", "Config", "INIParser" {
    
    Context "ConvertFrom-IniFile Tests" {
        BeforeEach {
            $script:TestFile = Join-Path $script:TestDir "test.ini"
        }
        
        AfterEach {
            if (Test-Path $script:TestFile) {
                Remove-Item $script:TestFile -Force -ErrorAction SilentlyContinue
            }
        }
        
        It "Should parse simple INI file correctly" {
            $iniContent = @"
[section1]
key1=value1
key2=value2

[section2]
key3=value3
key4=value4
"@
            $iniContent | Out-File -FilePath $script:TestFile -Encoding UTF8
            
            $result = ConvertFrom-IniFile -Path $script:TestFile
            
            $result.Keys.Count | Should -Be 2
            $result.ContainsKey('section1') | Should -Be $true
            $result.ContainsKey('section2') | Should -Be $true
            
            $result['section1']['key1'] | Should -Be 'value1'
            $result['section1']['key2'] | Should -Be 'value2'
            $result['section2']['key3'] | Should -Be 'value3'
            $result['section2']['key4'] | Should -Be 'value4'
        }
        
        It "Should handle comments correctly" {
            $iniContent = @"
# Global comment
[section1]
# Section comment
key1=value1
key2=value2  # Inline comment (not supported, becomes part of value)

; Another comment style
[section2]
key3=value3
"@
            $iniContent | Out-File -FilePath $script:TestFile -Encoding UTF8
            
            $result = ConvertFrom-IniFile -Path $script:TestFile
            
            # Comments should be preserved with special keys
            $commentKeys = $result.Keys | Where-Object { $_ -like '_comment_*' }
            $commentKeys.Count | Should -BeGreaterThan 0
        }
        
        It "Should handle quoted values correctly" {
            $iniContent = @"
[section1]
quoted_double="double quoted value"
quoted_single='single quoted value'
unquoted=unquoted value
empty_quotes=""
"@
            $iniContent | Out-File -FilePath $script:TestFile -Encoding UTF8
            
            $result = ConvertFrom-IniFile -Path $script:TestFile
            
            $result['section1']['quoted_double'] | Should -Be 'double quoted value'
            $result['section1']['quoted_single'] | Should -Be 'single quoted value'
            $result['section1']['unquoted'] | Should -Be 'unquoted value'
            $result['section1']['empty_quotes'] | Should -Be ''
        }
        
        It "Should handle boolean values correctly" {
            $iniContent = @"
[section1]
bool_true=true
bool_false=false
bool_yes=yes
bool_no=no
bool_on=on
bool_off=off
bool_1=1
bool_0=0
"@
            $iniContent | Out-File -FilePath $script:TestFile -Encoding UTF8
            
            $result = ConvertFrom-IniFile -Path $script:TestFile
            
            $result['section1']['bool_true'] | Should -Be 'true'
            $result['section1']['bool_false'] | Should -Be 'false'
            $result['section1']['bool_yes'] | Should -Be 'true'
            $result['section1']['bool_no'] | Should -Be 'false'
            $result['section1']['bool_on'] | Should -Be 'true'
            $result['section1']['bool_off'] | Should -Be 'false'
            $result['section1']['bool_1'] | Should -Be 'true'
            $result['section1']['bool_0'] | Should -Be 'false'
        }
        
        It "Should handle malformed lines gracefully" {
            $iniContent = @"
[section1]
valid_key=valid_value
malformed line without equals
another=valid
= empty key
"@
            $iniContent | Out-File -FilePath $script:TestFile -Encoding UTF8
            
            $warnings = @()
            $result = ConvertFrom-IniFile -Path $script:TestFile -WarningAction SilentlyContinue -WarningVariable warnings
            
            $result['section1']['valid_key'] | Should -Be 'valid_value'
            $result['section1']['another'] | Should -Be 'valid'
            $warnings | Should -Not -BeNullOrEmpty
        }
        
        It "Should parse from content array" {
            $content = @(
                '[section1]',
                'key1=value1',
                'key2=value2'
            )
            
            $result = ConvertFrom-IniFile -Content $content
            
            $result['section1']['key1'] | Should -Be 'value1'
            $result['section1']['key2'] | Should -Be 'value2'
        }
        
        It "Should handle case sensitivity option" {
            $iniContent = @"
[SECTION1]
KEY1=value1
key1=value2
"@
            $iniContent | Out-File -FilePath $script:TestFile -Encoding UTF8
            
            # Case insensitive (default)
            $result = ConvertFrom-IniFile -Path $script:TestFile
            $result.ContainsKey('section1') | Should -Be $true
            $result['section1'].ContainsKey('key1') | Should -Be $true
            
            # Case sensitive
            $resultSensitive = ConvertFrom-IniFile -Path $script:TestFile -CaseSensitive
            $resultSensitive.ContainsKey('SECTION1') | Should -Be $true
            $resultSensitive['SECTION1'].ContainsKey('KEY1') | Should -Be $true
            $resultSensitive['SECTION1'].ContainsKey('key1') | Should -Be $true
        }
        
        It "Should throw error for non-existent file" {
            { ConvertFrom-IniFile -Path "C:\NonExistent\File.ini" } | Should -Throw -ExpectedMessage "*not found*"
        }
    }
    
    Context "ConvertTo-IniFile Tests" {
        It "Should convert hashtable to INI format" {
            $hashtable = @{
                'section1' = @{
                    'key1' = 'value1'
                    'key2' = 'value2'
                }
                'section2' = @{
                    'key3' = 'value3'
                    'key4' = 'value4'
                }
            }
            
            $iniContent = ConvertTo-IniFile -InputObject $hashtable
            
            $iniContent | Should -Match '\[section1\]'
            $iniContent | Should -Match '\[section2\]'
            $iniContent | Should -Match 'key1=value1'
            $iniContent | Should -Match 'key2=value2'
            $iniContent | Should -Match 'key3=value3'
            $iniContent | Should -Match 'key4=value4'
        }
        
        It "Should write INI file to path" {
            $hashtable = @{
                'section1' = @{
                    'key1' = 'value1'
                    'key2' = 'value2'
                }
            }
            
            $testFile = Join-Path $script:TestDir "output.ini"
            ConvertTo-IniFile -InputObject $hashtable -Path $testFile
            
            Test-Path $testFile | Should -Be $true
            $content = Get-Content $testFile -Raw
            $content | Should -Match '\[section1\]'
            $content | Should -Match 'key1=value1'
        }
        
        It "Should include comments when requested" {
            $hashtable = @{
                '_comment_1' = '# Global comment'
                'section1' = @{
                    '_comment_2' = '# Section comment'
                    'key1' = 'value1'
                }
            }
            
            $iniContent = ConvertTo-IniFile -InputObject $hashtable -IncludeComments
            
            $iniContent | Should -Match '# Global comment'
            $iniContent | Should -Match '# Section comment'
            $iniContent | Should -Match 'key1=value1'
        }
    }
    
    Context "Test-IniFile Tests" {
        It "Should validate correct INI file" {
            $iniContent = @"
[section1]
key1=value1
key2=value2
"@
            $testFile = Join-Path $script:TestDir "valid.ini"
            $iniContent | Out-File -FilePath $testFile -Encoding UTF8
            
            $result = Test-IniFile -Path $testFile
            
            $result.IsValid | Should -Be $true
            $result.Errors.Count | Should -Be 0
            $result.SectionCount | Should -Be 1
            $result.KeyCount | Should -BeGreaterThan 0
        }
        
        It "Should report error for non-existent file" {
            $result = Test-IniFile -Path "C:\NonExistent\File.ini"
            
            $result.IsValid | Should -Be $false
            $result.Errors.Count | Should -BeGreaterThan 0
            $result.Errors[0] | Should -Match "*not found*"
        }
    }
    
    Context "Merge-IniFile Tests" {
        It "Should merge configurations with override precedence" {
            $baseConfig = @{
                'section1' = @{
                    'key1' = 'base_value1'
                    'key2' = 'base_value2'
                }
                'section2' = @{
                    'key3' = 'base_value3'
                }
            }
            
            $overrideConfig = @{
                'section1' = @{
                    'key1' = 'override_value1'  # This should override
                    'key3' = 'override_value3'  # This should be added
                }
                'section3' = @{
                    'key4' = 'override_value4'  # New section
                }
            }
            
            $merged = Merge-IniFile -BaseConfiguration $baseConfig -OverrideConfiguration $overrideConfig
            
            # Check overrides
            $merged['section1']['key1'] | Should -Be 'override_value1'
            $merged['section1']['key2'] | Should -Be 'base_value2'
            $merged['section1']['key3'] | Should -Be 'override_value3'
            
            # Check preserved sections
            $merged['section2']['key3'] | Should -Be 'base_value3'
            
            # Check new sections
            $merged['section3']['key4'] | Should -Be 'override_value4'
        }
    }
}

Describe "Configuration System Tests" -Tag "Unit", "Config" {
    
    BeforeEach {
        # Clear configuration cache
        Clear-LLMConfigurationCache
    }
    
    Context "Get-LLMBuiltinConfiguration Tests" {
        It "Should return built-in configuration" {
            $config = Get-LLMBuiltinConfiguration
            
            $config | Should -BeOfType [LLMConfiguration]
            $config.Count() | Should -BeGreaterThan 0
        }
        
        It "Should include common providers in built-in config" {
            $config = Get-LLMBuiltinConfiguration
            
            $providerNames = $config.GetAllProviders() | ForEach-Object { $_.Name }
            $providerNames | Should -Contain 'openai'
            $providerNames | Should -Contain 'anthropic'
        }
    }
    
    Context "ConvertTo-LLMConfiguration Tests" {
        It "Should convert INI data to LLMConfiguration" {
            $iniData = @{
                'provider1' = @{
                    'base_url' = 'https://api1.com/v1'
                    'api_key_var' = 'API1_KEY'
                    'default_model' = 'model1'
                    'description' = 'Provider 1'
                    'enabled' = 'true'
                }
                'provider2' = @{
                    'base_url' = 'https://api2.com/v1'
                    'api_key_var' = 'API2_KEY'
                    'default_model' = 'model2'
                    'enabled' = 'false'
                }
            }
            
            $config = ConvertTo-LLMConfiguration -ConfigData $iniData
            
            $config | Should -BeOfType [LLMConfiguration]
            $config.Count() | Should -Be 2
            $config.HasProvider('provider1') | Should -Be $true
            $config.HasProvider('provider2') | Should -Be $true
            
            $provider1 = $config.GetProvider('provider1')
            $provider1.BaseUrl | Should -Be 'https://api1.com/v1'
            $provider1.Enabled | Should -Be $true
            
            $provider2 = $config.GetProvider('provider2')
            $provider2.Enabled | Should -Be $false
        }
        
        It "Should skip invalid provider sections" {
            $iniData = @{
                'valid_provider' = @{
                    'base_url' = 'https://api.valid.com/v1'
                    'api_key_var' = 'VALID_KEY'
                }
                'invalid_provider' = @{
                    # Missing required fields
                    'description' = 'Invalid provider'
                }
                '_comment_1' = '# This is a comment'
                'non_section_data' = 'scalar value'
            }
            
            $warnings = @()
            $config = ConvertTo-LLMConfiguration -ConfigData $iniData -WarningAction SilentlyContinue -WarningVariable warnings
            
            $config.Count() | Should -Be 1
            $config.HasProvider('valid_provider') | Should -Be $true
            $config.HasProvider('invalid_provider') | Should -Be $false
            
            $warnings | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Merge-LLMConfiguration Tests" {
        It "Should merge configurations correctly" {
            $baseConfig = New-LLMConfiguration
            $baseProvider1 = [LLMProvider]::new(@{
                name = 'provider1'
                base_url = 'https://base1.com'
                api_key_var = 'BASE1_KEY'
                enabled = 'true'
            })
            $baseProvider2 = [LLMProvider]::new(@{
                name = 'provider2'
                base_url = 'https://base2.com'
                api_key_var = 'BASE2_KEY'
                enabled = 'true'
            })
            $baseConfig.AddProvider($baseProvider1)
            $baseConfig.AddProvider($baseProvider2)
            
            $overrideConfig = New-LLMConfiguration
            $overrideProvider1 = [LLMProvider]::new(@{
                name = 'provider1'  # Same name - should override
                base_url = 'https://override1.com'
                api_key_var = 'OVERRIDE1_KEY'
                enabled = 'false'
            })
            $overrideProvider3 = [LLMProvider]::new(@{
                name = 'provider3'  # New provider
                base_url = 'https://override3.com'
                api_key_var = 'OVERRIDE3_KEY'
                enabled = 'true'
            })
            $overrideConfig.AddProvider($overrideProvider1)
            $overrideConfig.AddProvider($overrideProvider3)
            
            $merged = Merge-LLMConfiguration -BaseConfiguration $baseConfig -OverrideConfiguration $overrideConfig
            
            $merged.Count() | Should -Be 3
            
            # Provider1 should be overridden
            $mergedProvider1 = $merged.GetProvider('provider1')
            $mergedProvider1.BaseUrl | Should -Be 'https://override1.com'
            $mergedProvider1.Enabled | Should -Be $false
            
            # Provider2 should remain from base
            $mergedProvider2 = $merged.GetProvider('provider2')
            $mergedProvider2.BaseUrl | Should -Be 'https://base2.com'
            
            # Provider3 should be added from override
            $mergedProvider3 = $merged.GetProvider('provider3')
            $mergedProvider3.BaseUrl | Should -Be 'https://override3.com'
        }
    }
    
    Context "Save-LLMConfiguration Tests" {
        It "Should save configuration to file" {
            $config = New-LLMConfiguration
            $provider = [LLMProvider]::new(@{
                name = 'test_provider'
                base_url = 'https://api.test.com'
                api_key_var = 'TEST_KEY'
                default_model = 'test-model'
                description = 'Test provider'
                enabled = 'true'
            })
            $config.AddProvider($provider)
            
            $testFile = Join-Path $script:TestDir "saved_config.conf"
            Save-LLMConfiguration -Configuration $config -Path $testFile
            
            Test-Path $testFile | Should -Be $true
            
            # Verify content
            $content = Get-Content $testFile -Raw
            $content | Should -Match '\[test_provider\]'
            $content | Should -Match 'base_url=https://api.test.com'
            $content | Should -Match 'api_key_var=TEST_KEY'
        }
        
        It "Should create backup when requested" {
            $config = New-LLMConfiguration
            $provider = [LLMProvider]::new(@{
                name = 'backup_test'
                base_url = 'https://api.backup.com'
                api_key_var = 'BACKUP_KEY'
            })
            $config.AddProvider($provider)
            
            $testFile = Join-Path $script:TestDir "backup_test.conf"
            
            # Create initial file
            "initial content" | Out-File -FilePath $testFile -Encoding UTF8
            
            # Save with backup
            Save-LLMConfiguration -Configuration $config -Path $testFile -Backup
            
            # Check that backup was created
            $backupFiles = Get-ChildItem -Path $script:TestDir -Filter "backup_test.conf.backup.*"
            $backupFiles.Count | Should -Be 1
        }
    }
    
    Context "Test-LLMConfiguration Tests" {
        It "Should validate correct configuration" {
            $config = New-LLMConfiguration
            $validProvider = [LLMProvider]::new(@{
                name = 'valid_provider'
                base_url = 'https://api.valid.com'
                api_key_var = 'VALID_KEY'
                enabled = 'true'
            })
            $config.AddProvider($validProvider)
            
            $result = Test-LLMConfiguration -Configuration $config
            
            $result.IsValid | Should -Be $true
            $result.Errors.Count | Should -Be 0
            $result.ProviderCount | Should -Be 1
            $result.EnabledProviderCount | Should -Be 1
        }
        
        It "Should detect configuration issues" {
            $config = New-LLMConfiguration
            
            # Add invalid provider
            $invalidProvider = [LLMProvider]::new()
            $invalidProvider.Name = 'invalid'
            # Missing required fields
            $config.Providers['invalid'] = $invalidProvider  # Bypass validation in AddProvider
            
            $result = Test-LLMConfiguration -Configuration $config
            
            $result.IsValid | Should -Be $false
            $result.Errors.Count | Should -BeGreaterThan 0
        }
        
        It "Should warn about missing API keys" {
            # Clean up any existing test environment variable
            [System.Environment]::SetEnvironmentVariable('TEST_MISSING_KEY', $null, 'Process')
            
            $config = New-LLMConfiguration
            $provider = [LLMProvider]::new(@{
                name = 'test_provider'
                base_url = 'https://api.test.com'
                api_key_var = 'TEST_MISSING_KEY'  # This env var doesn't exist
                enabled = 'true'
            })
            $config.AddProvider($provider)
            
            $result = Test-LLMConfiguration -Configuration $config
            
            $result.Warnings.Count | Should -BeGreaterThan 0
            $result.Warnings | Should -Match "*API key not set*"
        }
        
        It "Should detect empty configuration" {
            $emptyConfig = New-LLMConfiguration
            
            $result = Test-LLMConfiguration -Configuration $emptyConfig
            
            $result.IsValid | Should -Be $false
            $result.Errors | Should -Contain "No providers defined in configuration"
            $result.ProviderCount | Should -Be 0
        }
    }
    
    Context "Configuration Cache Tests" {
        It "Should clear cache successfully" {
            # This is mainly to ensure the function doesn't throw
            { Clear-LLMConfigurationCache } | Should -Not -Throw
        }
    }
}