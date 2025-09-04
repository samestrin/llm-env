#Requires -Version 5.1
<#
.SYNOPSIS
    Windows-specific integration components for LLM Environment Manager
.DESCRIPTION
    Provides Windows-standard path handling, configuration file location logic,
    environment variable management, and Windows file system integration.
.NOTES
    Compatible with PowerShell 5.1+ and 7+, Windows and cross-platform
#>

Set-StrictMode -Version Latest

# Windows-specific path constants
$script:WindowsConfigPaths = @{
    UserConfig = Join-Path $env:APPDATA 'llm-env'
    SystemConfig = Join-Path $env:PROGRAMDATA 'llm-env'
    LocalConfig = Join-Path $env:LOCALAPPDATA 'llm-env'
}

# Cross-platform path resolution
function Get-LLMConfigDirectory {
    <#
    .SYNOPSIS
        Gets the appropriate configuration directory for the current platform
    .DESCRIPTION
        Returns platform-specific configuration directory following standard conventions
    .OUTPUTS
        [string] Path to configuration directory
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()
    
    if ($IsWindows -or $env:OS -eq 'Windows_NT' -or $PSVersionTable.Platform -eq 'Win32NT' -or -not $PSVersionTable.Platform) {
        # Windows path - use APPDATA
        $configDir = $script:WindowsConfigPaths.UserConfig
    }
    elseif ($IsMacOS -or ($env:HOME -and (Test-Path '/Users'))) {
        # macOS path
        $configDir = Join-Path $env:HOME '.config/llm-env'
    }
    elseif ($IsLinux -or $env:HOME) {
        # Linux path
        $xdgConfigHome = $env:XDG_CONFIG_HOME
        if ($xdgConfigHome) {
            $configDir = Join-Path $xdgConfigHome 'llm-env'
        } else {
            $configDir = Join-Path $env:HOME '.config/llm-env'
        }
    }
    else {
        # Fallback
        $configDir = Join-Path (Get-Location) '.llm-env'
        Write-Warning "Could not determine appropriate config directory, using: $configDir"
    }
    
    return $configDir
}

function Get-LLMConfigFilePath {
    <#
    .SYNOPSIS
        Gets the full path to the configuration file
    .DESCRIPTION  
        Returns the path where the llm-env configuration file should be located
    .OUTPUTS
        [string] Path to configuration file
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()
    
    $configDir = Get-LLMConfigDirectory
    return Join-Path $configDir 'config.conf'
}

function Get-LLMConfigSearchPaths {
    <#
    .SYNOPSIS
        Gets all possible configuration file locations in search order
    .DESCRIPTION
        Returns an array of paths where configuration files might be found,
        in order of precedence (user config, system config, bundled config)
    .OUTPUTS
        [string[]] Array of configuration file paths
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param()
    
    $searchPaths = @()
    
    # User-specific config (highest priority)  
    $searchPaths += Get-LLMConfigFilePath
    
    if ($IsWindows -or $env:OS -eq 'Windows_NT' -or $PSVersionTable.Platform -eq 'Win32NT' -or -not $PSVersionTable.Platform) {
        # Windows system paths
        $searchPaths += Join-Path $script:WindowsConfigPaths.SystemConfig 'config.conf'
        $searchPaths += Join-Path $script:WindowsConfigPaths.LocalConfig 'config.conf'
    }
    else {
        # Unix-like system paths
        $searchPaths += '/etc/llm-env/config.conf'
        $searchPaths += '/usr/local/etc/llm-env/config.conf'
    }
    
    # Module bundled config (lowest priority)
    $moduleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent  # Go up from lib/ to module root
    if ($moduleRoot -and (Test-Path $moduleRoot)) {
        $searchPaths += Join-Path $moduleRoot 'config/llm-env.conf'
    }
    
    return $searchPaths
}

function Resolve-LLMPath {
    <#
    .SYNOPSIS
        Resolves a path using platform-appropriate methods
    .DESCRIPTION
        Resolves paths with proper handling of environment variables,
        relative paths, and platform-specific path separators
    .PARAMETER Path
        The path to resolve
    .OUTPUTS
        [string] Resolved absolute path
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "Path cannot be null or empty"
    }
    
    try {
        # Expand environment variables
        $expandedPath = [System.Environment]::ExpandEnvironmentVariables($Path)
        
        # Convert to absolute path
        if ([System.IO.Path]::IsPathRooted($expandedPath)) {
            $resolvedPath = $expandedPath
        } else {
            $resolvedPath = Join-Path (Get-Location) $expandedPath
        }
        
        # Normalize path separators for current platform
        $resolvedPath = [System.IO.Path]::GetFullPath($resolvedPath)
        
        return $resolvedPath
    }
    catch {
        Write-Error "Failed to resolve path '$Path': $_"
        throw
    }
}

function Set-LLMEnvironmentVariable {
    <#
    .SYNOPSIS
        Sets an environment variable with proper scoping
    .DESCRIPTION
        Sets environment variables for the current process with optional
        persistence to user or machine level on Windows
    .PARAMETER Name
        Environment variable name
    .PARAMETER Value
        Environment variable value
    .PARAMETER Scope
        Scope for the environment variable (Process, User, Machine)
    .OUTPUTS
        [void]
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value,
        
        [Parameter()]
        [System.EnvironmentVariableTarget]$Scope = [System.EnvironmentVariableTarget]::Process
    )
    
    try {
        [System.Environment]::SetEnvironmentVariable($Name, $Value, $Scope)
        Write-Verbose "Set environment variable '$Name' in scope '$Scope'"
    }
    catch {
        Write-Error "Failed to set environment variable '$Name': $_"
        throw
    }
}

function Get-LLMEnvironmentVariable {
    <#
    .SYNOPSIS
        Gets an environment variable value with fallback options
    .DESCRIPTION
        Retrieves environment variable values with support for fallback values
        and different scopes
    .PARAMETER Name
        Environment variable name
    .PARAMETER DefaultValue
        Default value if variable is not set
    .PARAMETER Scope
        Scope to search for the variable
    .OUTPUTS
        [string] Environment variable value or default
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter()]
        [string]$DefaultValue = '',
        
        [Parameter()]
        [System.EnvironmentVariableTarget]$Scope = [System.EnvironmentVariableTarget]::Process
    )
    
    try {
        $value = [System.Environment]::GetEnvironmentVariable($Name, $Scope)
        if ([string]::IsNullOrEmpty($value)) {
            return $DefaultValue
        }
        return $value
    }
    catch {
        Write-Warning "Failed to get environment variable '$Name': $_"
        return $DefaultValue
    }
}

function Remove-LLMEnvironmentVariable {
    <#
    .SYNOPSIS
        Removes an environment variable
    .DESCRIPTION
        Removes environment variables from specified scope
    .PARAMETER Name
        Environment variable name
    .PARAMETER Scope
        Scope from which to remove the variable
    .OUTPUTS
        [void]
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter()]
        [System.EnvironmentVariableTarget]$Scope = [System.EnvironmentVariableTarget]::Process
    )
    
    try {
        [System.Environment]::SetEnvironmentVariable($Name, $null, $Scope)
        Write-Verbose "Removed environment variable '$Name' from scope '$Scope'"
    }
    catch {
        Write-Error "Failed to remove environment variable '$Name': $_"
        throw
    }
}

function Test-LLMPathPermissions {
    <#
    .SYNOPSIS
        Tests if the current user has appropriate permissions for a path
    .DESCRIPTION
        Checks read/write permissions for files and directories
    .PARAMETER Path
        Path to test
    .PARAMETER RequireWrite
        Whether write access is required
    .OUTPUTS
        [bool] True if permissions are adequate
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter()]
        [switch]$RequireWrite
    )
    
    try {
        if (Test-Path $Path) {
            $item = Get-Item $Path
            
            # Test read access
            try {
                if ($item.PSIsContainer) {
                    $null = Get-ChildItem $Path -ErrorAction Stop
                } else {
                    $null = Get-Content $Path -TotalCount 1 -ErrorAction Stop
                }
            }
            catch {
                Write-Verbose "No read access to '$Path'"
                return $false
            }
            
            # Test write access if required
            if ($RequireWrite) {
                try {
                    if ($item.PSIsContainer) {
                        $testFile = Join-Path $Path '.llm-env-test'
                        $null = New-Item $testFile -ItemType File -Force -ErrorAction Stop
                        Remove-Item $testFile -Force -ErrorAction SilentlyContinue
                    } else {
                        $testContent = Get-Content $Path -Raw
                        $testContent | Set-Content $Path -ErrorAction Stop
                    }
                }
                catch {
                    Write-Verbose "No write access to '$Path'"
                    return $false
                }
            }
            
            return $true
        }
        else {
            # Test if we can create the path
            if ($RequireWrite) {
                try {
                    $parentPath = Split-Path $Path -Parent
                    if ($parentPath -and -not (Test-Path $parentPath)) {
                        $null = New-Item $parentPath -ItemType Directory -Force -ErrorAction Stop
                    }
                    $null = New-Item $Path -ItemType File -Force -ErrorAction Stop
                    Remove-Item $Path -Force -ErrorAction SilentlyContinue
                    return $true
                }
                catch {
                    Write-Verbose "Cannot create '$Path'"
                    return $false
                }
            }
            return $false
        }
    }
    catch {
        Write-Warning "Error testing permissions for '$Path': $_"
        return $false
    }
}

function New-LLMDirectory {
    <#
    .SYNOPSIS
        Creates a directory with proper error handling
    .DESCRIPTION
        Creates directories with appropriate permissions and error handling
    .PARAMETER Path
        Directory path to create
    .PARAMETER Force
        Force creation even if directory exists
    .OUTPUTS
        [System.IO.DirectoryInfo] Created directory info
    #>
    [CmdletBinding()]
    [OutputType([System.IO.DirectoryInfo])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter()]
        [switch]$Force
    )
    
    try {
        $resolvedPath = Resolve-LLMPath $Path
        
        if (Test-Path $resolvedPath) {
            if ($Force) {
                Write-Verbose "Directory already exists: $resolvedPath"
                return Get-Item $resolvedPath
            } else {
                throw "Directory already exists: $resolvedPath"
            }
        }
        
        $directory = New-Item -Path $resolvedPath -ItemType Directory -Force:$Force
        Write-Verbose "Created directory: $resolvedPath"
        return $directory
    }
    catch {
        Write-Error "Failed to create directory '$Path': $_"
        throw
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-LLMConfigDirectory',
    'Get-LLMConfigFilePath', 
    'Get-LLMConfigSearchPaths',
    'Resolve-LLMPath',
    'Set-LLMEnvironmentVariable',
    'Get-LLMEnvironmentVariable', 
    'Remove-LLMEnvironmentVariable',
    'Test-LLMPathPermissions',
    'New-LLMDirectory'
)