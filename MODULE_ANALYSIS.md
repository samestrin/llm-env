# PowerShell Module Loading Analysis

## Current Issues Identified

### 1. Circular Dependencies
- **Config.psm1** calls `Get-LLMConfigSearchPaths` which is in **WindowsIntegration.psm1**
- **Providers.psm1** calls `Get-LLMConfiguration` which is in **Config.psm1**  
- **WindowsIntegration.psm1** loads first but **Config.psm1** may not be loaded when it tries to use Config functions

### 2. Module Loading Problems
- Using `-Global` flag in Import-Module causes scope pollution
- Module files not properly structured as PowerShell modules (.psm1 files need proper manifests or alternative loading)
- **DataModels.ps1** is dot-sourced but other files use Import-Module

### 3. Function Resolution Failures
- `Get-LLMConfigDirectory` not available to initialization function
- `Get-LLMConfiguration` not available to initialization function
- Cmdlets calling functions that aren't properly exported

## Dependency Mapping

```
llm-env.psm1 (Main Module)
├── DataModels.ps1 (dot-sourced, provides classes)
├── WindowsIntegration.psm1 (provides path functions)
├── IniParser.psm1 (provides INI parsing)
├── Config.psm1 (needs WindowsIntegration, provides Get-LLMConfiguration)
├── Providers.psm1 (needs Config, provides provider registry)
├── PowerShellEnhancements.psm1 (provides tab completion)
└── WindowsUI.psm1 (provides UI components)
```

## Specific Error Points
1. **Line 41 in llm-env.psm1**: `-Global` flag causing scope issues
2. **Config.psm1**: Calls `Get-LLMConfigSearchPaths` before WindowsIntegration is properly loaded
3. **Get-LLMProviders cmdlet**: Recursive call to itself instead of library function
4. **Initialization function**: Called before dependencies are loaded

## Circular Dependencies Identified
- Config → WindowsIntegration (for path functions)
- Providers → Config (for configuration)  
- Cmdlets → All modules (for various functions)

## Function Export Issues
- WindowsIntegration functions not available when Config tries to use them
- Configuration functions not available when Providers tries to use them
- Library functions not available when cmdlets try to use them

## Configuration Caching Problems
1. **Duplicate Cache Variables**: Both main module and Config.psm1 have their own cache variables
2. **Cache Synchronization**: No coordination between main module cache and Config module cache
3. **Provider Registry Cache**: Separate cache in Providers.psm1 that doesn't sync with Config cache
4. **Cache Invalidation**: Inconsistent cache clearing between modules

## Integration Point Dependencies
### Cmdlets requiring library functions:
- **Set-LLMProvider.ps1**: Needs `Get-LLMProvider`, `Get-LLMConfiguration`, `Set-LLMEnvironmentVariable`
- **Get-LLMProviders.ps1**: Needs `Get-LLMConfiguration`, provider filtering functions
- **Show-LLMProvider.ps1**: Needs `Get-LLMEnvironmentVariable`, `Get-LLMProvider`
- **Initialize-LLMConfig.ps1**: Needs `Get-LLMConfigFilePath`
- **Test-LLMProvider.ps1**: Needs `Get-LLMProviders`, `Get-LLMProvider`, `Get-LLMEnvironmentVariable`

### Missing Functions in Cmdlets:
- `Get-LLMProvider` (used by Set-LLMProvider, Show-LLMProvider, Test-LLMProvider)
- `Get-LLMEnvironmentVariable` (used by Show-LLMProvider, Test-LLMProvider)
- `Set-LLMEnvironmentVariable` (used by Set-LLMProvider)
- `Get-LLMConfigFilePath` (used by Initialize-LLMConfig, Restore-LLMConfig)