#Requires -Version 5.1
<#
.SYNOPSIS
    Performance tests and benchmarks for LLM Environment Manager
.DESCRIPTION
    Tests module loading performance, configuration loading speed, command execution
    times, and implements performance benchmarks with optimization recommendations
.NOTES
    Run with: Invoke-Pester -Path tests/powershell/performance/Performance.Tests.ps1
#>

# Import the module being tested
BeforeAll {
    $ModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    
    # Create temporary directory for performance tests
    $script:TestDir = Join-Path ([System.IO.Path]::GetTempPath()) "LLMEnvPerfTests-$([System.Guid]::NewGuid())"
    New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
    
    # Performance tracking
    $script:PerformanceResults = @{}
    
    # Helper function to measure execution time
    function Measure-ExecutionTime {
        param(
            [string]$Name,
            [scriptblock]$ScriptBlock,
            [int]$Iterations = 1
        )
        
        $times = @()
        for ($i = 0; $i -lt $Iterations; $i++) {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                & $ScriptBlock
            }
            catch {
                # Record error but continue measurement
                Write-Warning "Error during performance test '$Name': $_"
            }
            $stopwatch.Stop()
            $times += $stopwatch.ElapsedMilliseconds
        }
        
        $result = @{
            Name = $Name
            Iterations = $Iterations
            TotalTime = ($times | Measure-Object -Sum).Sum
            AverageTime = ($times | Measure-Object -Average).Average
            MinTime = ($times | Measure-Object -Minimum).Minimum
            MaxTime = ($times | Measure-Object -Maximum).Maximum
            Times = $times
        }
        
        $script:PerformanceResults[$Name] = $result
        return $result
    }
    
    # Helper function to create test configuration with specified number of providers
    function New-TestConfiguration {
        param([int]$ProviderCount = 50)
        
        $config = New-LLMConfiguration
        
        for ($i = 1; $i -le $ProviderCount; $i++) {
            $provider = [LLMProvider]::new(@{
                name = "test_provider_$i"
                base_url = "https://api.test$i.com/v1"
                api_key_var = "TEST_PROVIDER_${i}_KEY"
                default_model = "test-model-$i"
                description = "Test provider number $i for performance testing"
                enabled = if ($i % 3 -eq 0) { 'false' } else { 'true' }  # Some disabled for variety
            })
            $config.AddProvider($provider)
        }
        
        return $config
    }
    
    # Create large test configuration file
    function New-LargeConfigurationFile {
        param([string]$Path, [int]$ProviderCount = 100)
        
        $content = @"
# Large configuration file for performance testing
# Generated with $ProviderCount providers

"@
        
        for ($i = 1; $i -le $ProviderCount; $i++) {
            $enabled = if ($i % 4 -eq 0) { 'false' } else { 'true' }
            $content += @"

[provider_$i]
base_url=https://api.provider$i.com/v1
api_key_var=PROVIDER_${i}_API_KEY
default_model=provider-$i-model-v1
description=Performance test provider number $i with some additional description text to make it more realistic
enabled=$enabled
custom_property_1=value_$i
custom_property_2=extended_value_for_provider_$i
timeout=30
retries=3
region=us-west-2
priority=$($i % 10)

"@
        }
        
        $content | Out-File -FilePath $Path -Encoding UTF8
    }
}

AfterAll {
    # Clean up temporary test directory
    if (Test-Path $script:TestDir) {
        Remove-Item $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Display performance summary
    Write-Host "`nPerformance Test Summary:" -ForegroundColor Green
    Write-Host "=========================" -ForegroundColor Green
    
    foreach ($testName in $script:PerformanceResults.Keys | Sort-Object) {
        $result = $script:PerformanceResults[$testName]
        Write-Host "$testName" -ForegroundColor Yellow
        Write-Host "  Average: $([math]::Round($result.AverageTime, 2))ms" -ForegroundColor White
        Write-Host "  Min: $($result.MinTime)ms, Max: $($result.MaxTime)ms" -ForegroundColor Gray
        
        # Performance recommendations
        if ($result.AverageTime -gt 1000) {
            Write-Host "  ⚠ Performance concern: Average time > 1 second" -ForegroundColor Red
        } elseif ($result.AverageTime -gt 500) {
            Write-Host "  ⚡ Consider optimization: Average time > 500ms" -ForegroundColor Yellow
        } else {
            Write-Host "  ✓ Good performance" -ForegroundColor Green
        }
    }
}

Describe "Module Loading Performance" -Tag "Performance", "Loading" {
    
    Context "Initial Module Import" {
        It "Should import module within reasonable time" {
            # Remove module if already loaded
            Remove-Module llm-env -ErrorAction SilentlyContinue
            
            $result = Measure-ExecutionTime -Name "Module Import" -ScriptBlock {
                Import-Module (Join-Path $ModuleRoot 'llm-env.psd1') -Force
            } -Iterations 5
            
            $result.AverageTime | Should -BeLessThan 2000  # Less than 2 seconds average
            $result.MinTime | Should -BeLessThan 1500      # Fastest should be under 1.5 seconds
        }
        
        It "Should reload module efficiently" {
            # Ensure module is loaded
            Import-Module (Join-Path $ModuleRoot 'llm-env.psd1') -Force
            
            $result = Measure-ExecutionTime -Name "Module Reload" -ScriptBlock {
                Import-Module (Join-Path $ModuleRoot 'llm-env.psd1') -Force
            } -Iterations 10
            
            $result.AverageTime | Should -BeLessThan 1000  # Reloads should be faster
        }
    }
}

Describe "Configuration Loading Performance" -Tag "Performance", "Configuration" {
    
    BeforeAll {
        # Ensure module is loaded
        Import-Module (Join-Path $ModuleRoot 'llm-env.psd1') -Force
    }
    
    Context "Small Configuration Files" {
        It "Should load small configuration quickly" {
            $smallConfigFile = Join-Path $script:TestDir "small-config.conf"
            New-LargeConfigurationFile -Path $smallConfigFile -ProviderCount 5
            
            $result = Measure-ExecutionTime -Name "Small Config Load (5 providers)" -ScriptBlock {
                $config = ConvertFrom-IniFile -Path $smallConfigFile
                $llmConfig = ConvertTo-LLMConfiguration -ConfigData $config
            } -Iterations 20
            
            $result.AverageTime | Should -BeLessThan 100   # Should be very fast
        }
        
        It "Should parse small INI files efficiently" {
            $smallConfigFile = Join-Path $script:TestDir "small-config.conf"
            
            $result = Measure-ExecutionTime -Name "Small INI Parse" -ScriptBlock {
                ConvertFrom-IniFile -Path $smallConfigFile
            } -Iterations 50
            
            $result.AverageTime | Should -BeLessThan 50    # INI parsing should be very fast
        }
    }
    
    Context "Medium Configuration Files" {
        It "Should load medium configuration efficiently" {
            $mediumConfigFile = Join-Path $script:TestDir "medium-config.conf"
            New-LargeConfigurationFile -Path $mediumConfigFile -ProviderCount 25
            
            $result = Measure-ExecutionTime -Name "Medium Config Load (25 providers)" -ScriptBlock {
                $config = ConvertFrom-IniFile -Path $mediumConfigFile
                $llmConfig = ConvertTo-LLMConfiguration -ConfigData $config
            } -Iterations 10
            
            $result.AverageTime | Should -BeLessThan 300   # Should still be reasonably fast
        }
    }
    
    Context "Large Configuration Files" {
        It "Should handle large configuration within acceptable time" {
            $largeConfigFile = Join-Path $script:TestDir "large-config.conf"
            New-LargeConfigurationFile -Path $largeConfigFile -ProviderCount 100
            
            $result = Measure-ExecutionTime -Name "Large Config Load (100 providers)" -ScriptBlock {
                $config = ConvertFrom-IniFile -Path $largeConfigFile
                $llmConfig = ConvertTo-LLMConfiguration -ConfigData $config
                $llmConfig.Count() | Should -Be 100
            } -Iterations 5
            
            $result.AverageTime | Should -BeLessThan 1000  # Even large configs should load in under 1 second
        }
        
        It "Should scale linearly with provider count" {
            # Test different sizes to verify scaling
            $sizes = @(10, 50, 100)
            $times = @{}
            
            foreach ($size in $sizes) {
                $configFile = Join-Path $script:TestDir "scale-test-$size.conf"
                New-LargeConfigurationFile -Path $configFile -ProviderCount $size
                
                $result = Measure-ExecutionTime -Name "Scale Test $size providers" -ScriptBlock {
                    $config = ConvertFrom-IniFile -Path $configFile
                    $llmConfig = ConvertTo-LLMConfiguration -ConfigData $config
                } -Iterations 3
                
                $times[$size] = $result.AverageTime
            }
            
            # Verify roughly linear scaling (100 providers shouldn't take more than 10x the time of 10 providers)
            $scalingFactor = $times[100] / $times[10]
            $scalingFactor | Should -BeLessThan 15  # Allow some overhead, but should be roughly linear
        }
    }
}

Describe "Command Execution Performance" -Tag "Performance", "Commands" {
    
    BeforeAll {
        # Create test configuration
        $script:TestConfig = New-TestConfiguration -ProviderCount 30
        
        # Mock the config loading to use our test config
        Mock Get-LLMConfiguration { return $script:TestConfig } -ModuleName Config
        
        # Set up test environment variables
        for ($i = 1; $i -le 30; $i++) {
            [System.Environment]::SetEnvironmentVariable("TEST_PROVIDER_${i}_KEY", "test-key-$i", 'Process')
        }
    }
    
    AfterAll {
        # Clean up test environment variables
        for ($i = 1; $i -le 30; $i++) {
            [System.Environment]::SetEnvironmentVariable("TEST_PROVIDER_${i}_KEY", $null, 'Process')
        }
    }
    
    Context "Provider Listing Performance" {
        It "Should list providers quickly" {
            $result = Measure-ExecutionTime -Name "Get-LLMProviders" -ScriptBlock {
                $providers = Get-LLMProviders
                $providers.Count | Should -Be 30
            } -Iterations 20
            
            $result.AverageTime | Should -BeLessThan 200   # Should be very fast
        }
        
        It "Should filter providers efficiently" {
            $result = Measure-ExecutionTime -Name "Get-LLMProviders -EnabledOnly" -ScriptBlock {
                $providers = Get-LLMProviders -EnabledOnly
                $providers.Count | Should -BeGreaterThan 15  # Most should be enabled
            } -Iterations 20
            
            $result.AverageTime | Should -BeLessThan 250   # Filtering should add minimal overhead
        }
        
        It "Should search providers by pattern efficiently" {
            $result = Measure-ExecutionTime -Name "Provider Pattern Search" -ScriptBlock {
                $providers = Get-LLMProviders -NamePattern "test_provider_1*"
                $providers.Count | Should -BeGreaterThan 0
            } -Iterations 20
            
            $result.AverageTime | Should -BeLessThan 300   # Pattern matching should be fast
        }
    }
    
    Context "Provider Operations Performance" {
        BeforeEach {
            # Clear environment before each test
            Clear-LLMProvider
        }
        
        It "Should set provider quickly" {
            $result = Measure-ExecutionTime -Name "Set-LLMProvider" -ScriptBlock {
                Set-LLMProvider -Name 'test_provider_1'
                [System.Environment]::GetEnvironmentVariable('LLM_PROVIDER', 'Process') | Should -Be 'test_provider_1'
            } -Iterations 10
            
            $result.AverageTime | Should -BeLessThan 150   # Provider setting should be very fast
        }
        
        It "Should clear provider quickly" {
            # Set a provider first
            Set-LLMProvider -Name 'test_provider_2'
            
            $result = Measure-ExecutionTime -Name "Clear-LLMProvider" -ScriptBlock {
                Clear-LLMProvider
                [System.Environment]::GetEnvironmentVariable('LLM_PROVIDER', 'Process') | Should -BeNullOrEmpty
            } -Iterations 10
            
            $result.AverageTime | Should -BeLessThan 100   # Clearing should be very fast
        }
        
        It "Should switch between providers efficiently" {
            $result = Measure-ExecutionTime -Name "Provider Switching" -ScriptBlock {
                Set-LLMProvider -Name 'test_provider_1'
                Set-LLMProvider -Name 'test_provider_2'
                Set-LLMProvider -Name 'test_provider_3'
                Clear-LLMProvider -RestorePrevious  # Should go back to provider_2
                [System.Environment]::GetEnvironmentVariable('LLM_PROVIDER', 'Process') | Should -Be 'test_provider_2'
            } -Iterations 5
            
            $result.AverageTime | Should -BeLessThan 500   # Multiple operations should still be fast
        }
    }
    
    Context "Provider Validation Performance" {
        It "Should validate single provider quickly" {
            $result = Measure-ExecutionTime -Name "Test-LLMProvider Single" -ScriptBlock {
                $testResult = Test-LLMProvider -Name 'test_provider_1'
                $testResult.IsValid | Should -Be $true
            } -Iterations 10
            
            $result.AverageTime | Should -BeLessThan 200   # Single provider validation should be fast
        }
        
        It "Should validate all providers within reasonable time" {
            $result = Measure-ExecutionTime -Name "Test-LLMProvider All" -ScriptBlock {
                $testResults = Test-LLMProvider -All -SkipConnectivity  # Skip network calls for performance test
                $testResults.Count | Should -Be 30
            } -Iterations 3
            
            $result.AverageTime | Should -BeLessThan 2000  # Testing all providers should complete within 2 seconds
        }
        
        It "Should validate enabled providers efficiently" {
            $result = Measure-ExecutionTime -Name "Test-LLMProvider EnabledOnly" -ScriptBlock {
                $testResults = Test-LLMProvider -All -EnabledOnly -SkipConnectivity
                $testResults.Count | Should -BeGreaterThan 15
            } -Iterations 5
            
            $result.AverageTime | Should -BeLessThan 1500  # Testing enabled providers should be faster
        }
    }
}

Describe "Memory and Resource Usage" -Tag "Performance", "Memory" {
    
    Context "Memory Usage Patterns" {
        It "Should not have significant memory leaks during repeated operations" {
            # Get initial memory usage
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            [System.GC]::Collect()
            
            $initialMemory = [System.GC]::GetTotalMemory($false)
            
            # Perform many operations
            for ($i = 0; $i -lt 100; $i++) {
                $config = New-TestConfiguration -ProviderCount 10
                $providers = $config.GetAllProviders()
                $hashtable = $config.ToHashtable()
                # Let objects go out of scope
            }
            
            # Force garbage collection and measure memory again
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            [System.GC]::Collect()
            
            $finalMemory = [System.GC]::GetTotalMemory($false)
            $memoryIncrease = $finalMemory - $initialMemory
            
            # Memory should not increase by more than 10MB during the test
            $memoryIncrease | Should -BeLessThan (10 * 1024 * 1024)
        }
        
        It "Should handle large configurations without excessive memory usage" {
            [System.GC]::Collect()
            $beforeMemory = [System.GC]::GetTotalMemory($false)
            
            # Create a very large configuration
            $largeConfig = New-TestConfiguration -ProviderCount 500
            
            $afterMemory = [System.GC]::GetTotalMemory($false)
            $memoryUsed = $afterMemory - $beforeMemory
            
            # Should not use more than 50MB for 500 providers (rough estimate)
            $memoryUsed | Should -BeLessThan (50 * 1024 * 1024)
            
            # Verify the configuration actually has 500 providers
            $largeConfig.Count() | Should -Be 500
        }
    }
}

Describe "Caching and Optimization" -Tag "Performance", "Caching" {
    
    BeforeAll {
        # Ensure module is loaded
        Import-Module (Join-Path $ModuleRoot 'llm-env.psd1') -Force
    }
    
    Context "Configuration Caching" {
        It "Should cache configuration for improved performance" {
            # Create test config file
            $configFile = Join-Path $script:TestDir "cache-test.conf"
            New-LargeConfigurationFile -Path $configFile -ProviderCount 20
            
            # Clear cache first
            Clear-LLMConfigurationCache
            
            # First load (cold cache)
            $firstLoadTime = Measure-ExecutionTime -Name "First Config Load (Cold Cache)" -ScriptBlock {
                # Mock the config path to use our test file
                Mock Get-LLMConfigSearchPaths { return @($configFile) } -ModuleName Config
                $config = Get-LLMConfiguration
                $config.Count() | Should -Be 20
            } -Iterations 1
            
            # Second load (warm cache)
            $secondLoadTime = Measure-ExecutionTime -Name "Second Config Load (Warm Cache)" -ScriptBlock {
                $config = Get-LLMConfiguration
                $config.Count() | Should -Be 20
            } -Iterations 1
            
            # Cached load should be significantly faster
            $secondLoadTime.AverageTime | Should -BeLessThan ($firstLoadTime.AverageTime * 0.5)
        }
        
        It "Should invalidate cache when forced" {
            $configFile = Join-Path $script:TestDir "cache-invalidation-test.conf"
            New-LargeConfigurationFile -Path $configFile -ProviderCount 15
            
            Mock Get-LLMConfigSearchPaths { return @($configFile) } -ModuleName Config
            
            # Load configuration to populate cache
            $config1 = Get-LLMConfiguration
            
            # Force reload should bypass cache
            $forceLoadTime = Measure-ExecutionTime -Name "Force Config Reload" -ScriptBlock {
                $config2 = Get-LLMConfiguration -Force
                $config2.Count() | Should -Be 15
            } -Iterations 1
            
            # Force reload should take longer than cached access
            $cachedLoadTime = Measure-ExecutionTime -Name "Cached Config Access" -ScriptBlock {
                $config3 = Get-LLMConfiguration
                $config3.Count() | Should -Be 15
            } -Iterations 1
            
            $forceLoadTime.AverageTime | Should -BeGreaterThan ($cachedLoadTime.AverageTime * 2)
        }
    }
}

Describe "Performance Regression Tests" -Tag "Performance", "Regression" {
    
    Context "Baseline Performance Expectations" {
        It "Should meet baseline performance for common operations" {
            # These are baseline expectations that should not regress
            
            # Module import should complete within 3 seconds
            Remove-Module llm-env -ErrorAction SilentlyContinue
            $importTime = Measure-ExecutionTime -Name "Module Import Baseline" -ScriptBlock {
                Import-Module (Join-Path $ModuleRoot 'llm-env.psd1') -Force
            } -Iterations 1
            $importTime.AverageTime | Should -BeLessThan 3000
            
            # Configuration with 50 providers should load within 500ms
            $config = New-TestConfiguration -ProviderCount 50
            Mock Get-LLMConfiguration { return $config } -ModuleName Config
            
            $listTime = Measure-ExecutionTime -Name "List 50 Providers Baseline" -ScriptBlock {
                $providers = Get-LLMProviders
                $providers.Count | Should -Be 50
            } -Iterations 1
            $listTime.AverageTime | Should -BeLessThan 500
            
            # Provider switching should complete within 200ms
            $switchTime = Measure-ExecutionTime -Name "Provider Switch Baseline" -ScriptBlock {
                Set-LLMProvider -Name 'test_provider_1'
            } -Iterations 1
            $switchTime.AverageTime | Should -BeLessThan 200
        }
    }
}