# PowerShell Module Loading Refactor Design

## Current Problems
1. `-Global` flag causing scope pollution and conflicts
2. Circular dependencies between modules
3. Functions not available when needed
4. Duplicate cache systems

## New Design

### 1. Loading Strategy
Instead of using `Import-Module -Global`, use dot-sourcing for all modules to ensure functions are available in the correct scope:

```powershell
# New approach - dot-source everything
foreach ($module in $moduleLoadOrder) {
    $modulePath = Join-Path $libPath $module
    if (Test-Path $modulePath) {
        . $modulePath  # Dot-source all modules
    }
}
```

### 2. Dependency Resolution Order
Change loading order to resolve dependencies:

```powershell
$moduleLoadOrder = @(
    'DataModels.ps1',          # Base classes (no dependencies)
    'WindowsIntegration.psm1', # Path functions (no dependencies)  
    'IniParser.psm1',          # INI parsing (no dependencies)
    'Config.psm1',             # Needs WindowsIntegration + IniParser
    'Providers.psm1',          # Needs Config
    'PowerShellEnhancements.psm1', # Needs Config + Providers
    'WindowsUI.psm1'           # UI components (no dependencies)
)
```

### 3. Function Availability
By dot-sourcing all modules, functions will be available in the main module scope and accessible to cmdlets.

### 4. Cache Consolidation
Remove duplicate cache variables:
- Keep only the cache in Config.psm1 
- Remove cache from main module
- Make Providers.psm1 use Config cache directly

### 5. Module Structure Changes
- Remove Export-ModuleMember from modules that will be dot-sourced
- Keep Export-ModuleMember only in main llm-env.psm1
- Ensure proper function scoping

## Implementation Steps

1. **Update llm-env.psm1**:
   - Remove `-Global` flag
   - Change all modules to dot-sourcing
   - Remove duplicate cache variables
   - Move initialization to end

2. **Update module files**:
   - Remove Export-ModuleMember from library modules
   - Ensure functions work when dot-sourced

3. **Test function availability**:
   - Verify cmdlets can access library functions
   - Test end-to-end workflows

## Expected Benefits
- Eliminates circular dependency issues
- Ensures all functions are available when needed
- Removes scope pollution from -Global flag
- Consolidates caching system
- Maintains cross-platform compatibility