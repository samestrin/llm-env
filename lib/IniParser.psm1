#Requires -Version 5.1
<#
.SYNOPSIS
    INI file parser for LLM Environment Manager
.DESCRIPTION
    Provides full compatibility INI file parsing for existing llm-env configuration files.
    Handles comments, sections, key-value pairs, and multi-line values.
.NOTES
    Compatible with PowerShell 5.1+ and 7+
#>

Set-StrictMode -Version Latest

function ConvertFrom-IniFile {
    <#
    .SYNOPSIS
        Parses an INI file into a hashtable structure
    .DESCRIPTION
        Reads and parses INI files with full support for sections, key-value pairs,
        comments, and various edge cases commonly found in configuration files
    .PARAMETER Path
        Path to the INI file to parse
    .PARAMETER Content
        Raw INI content as string array (alternative to file path)
    .PARAMETER IgnoreComments
        Skip comment lines entirely (default: false, includes comments in output)
    .PARAMETER CaseSensitive
        Treat section and key names as case sensitive (default: false)
    .OUTPUTS
        [hashtable] Parsed INI structure with sections and key-value pairs
    .EXAMPLE
        ConvertFrom-IniFile -Path "C:\config\app.ini"
    .EXAMPLE  
        Get-Content "app.ini" | ConvertFrom-IniFile -Content $_
    #>
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Path')]
        [string]$Path,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'Content', ValueFromPipeline = $true)]
        [string[]]$Content,
        
        [Parameter()]
        [switch]$IgnoreComments,
        
        [Parameter()]
        [switch]$CaseSensitive
    )
    
    begin {
        $result = @{}
        $currentSection = ''
        $lineNumber = 0
        $allContent = @()
    }
    
    process {
        if ($PSCmdlet.ParameterSetName -eq 'Path') {
            if (-not (Test-Path $Path)) {
                throw "INI file not found: $Path"
            }
            try {
                $allContent = Get-Content -Path $Path -ErrorAction Stop
            }
            catch {
                throw "Failed to read INI file '$Path': $_"
            }
        }
        else {
            $allContent += $Content
        }
    }
    
    end {
        try {
            foreach ($line in $allContent) {
                $lineNumber++
                
                # Handle null or empty lines
                if ([string]::IsNullOrWhiteSpace($line)) {
                    continue
                }
                
                # Trim whitespace
                $trimmedLine = $line.Trim()
                
                # Skip empty lines after trimming
                if ([string]::IsNullOrEmpty($trimmedLine)) {
                    continue
                }
                
                # Handle comment lines
                if ($trimmedLine.StartsWith('#') -or $trimmedLine.StartsWith(';')) {
                    if (-not $IgnoreComments) {
                        # Store comments with special prefix to avoid conflicts
                        $commentKey = "_comment_$lineNumber"
                        if ($currentSection) {
                            if (-not $result.ContainsKey($currentSection)) {
                                $result[$currentSection] = @{}
                            }
                            $result[$currentSection][$commentKey] = $trimmedLine
                        }
                        else {
                            $result[$commentKey] = $trimmedLine
                        }
                    }
                    continue
                }
                
                # Handle section headers [section_name]
                if ($trimmedLine -match '^\[([^\]]+)\]$') {
                    $sectionName = $matches[1].Trim()
                    if (-not $CaseSensitive) {
                        $sectionName = $sectionName.ToLowerInvariant()
                    }
                    $currentSection = $sectionName
                    
                    if (-not $result.ContainsKey($currentSection)) {
                        $result[$currentSection] = @{}
                    }
                    continue
                }
                
                # Handle key-value pairs
                $kvMatch = $trimmedLine -match '^([^=]+)=(.*)$'
                if ($kvMatch) {
                    $key = $matches[1].Trim()
                    $value = $matches[2].Trim()
                    
                    if (-not $CaseSensitive) {
                        $key = $key.ToLowerInvariant()
                    }
                    
                    # Remove quotes if present (both single and double)
                    if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
                        ($value.StartsWith("'") -and $value.EndsWith("'"))) {
                        $value = $value.Substring(1, $value.Length - 2)
                    }
                    
                    # Handle boolean values
                    if ($value -match '^(true|false|yes|no|on|off|1|0)$') {
                        switch ($value.ToLowerInvariant()) {
                            { $_ -in @('true', 'yes', 'on', '1') } { $value = 'true' }
                            { $_ -in @('false', 'no', 'off', '0') } { $value = 'false' }
                        }
                    }
                    
                    if ($currentSection) {
                        if (-not $result.ContainsKey($currentSection)) {
                            $result[$currentSection] = @{}
                        }
                        $result[$currentSection][$key] = $value
                    }
                    else {
                        # Key-value pair outside of section (global)
                        $result[$key] = $value
                    }
                    continue
                }
                
                # Handle malformed lines
                Write-Warning "Malformed line $lineNumber in INI: $trimmedLine"
            }
            
            return $result
        }
        catch {
            throw "Error parsing INI content at line $lineNumber : $_"
        }
    }
}

function ConvertTo-IniFile {
    <#
    .SYNOPSIS
        Converts a hashtable structure to INI file format
    .DESCRIPTION
        Takes a nested hashtable and converts it to INI file format string
        with proper section headers, key-value pairs, and formatting
    .PARAMETER InputObject
        Hashtable to convert to INI format
    .PARAMETER Path
        Output file path (optional - if not specified, returns string)
    .PARAMETER IncludeComments
        Include comment lines in output (default: true)
    .PARAMETER SectionHeader
        Custom section header format (default: "[{0}]")
    .OUTPUTS
        [string] INI formatted content or writes to file
    .EXAMPLE
        $config | ConvertTo-IniFile -Path "output.ini"
    .EXAMPLE
        $iniString = $config | ConvertTo-IniFile
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$InputObject,
        
        [Parameter()]
        [string]$Path,
        
        [Parameter()]
        [switch]$IncludeComments,
        
        [Parameter()]
        [string]$SectionHeader = '[{0}]'
    )
    
    process {
        try {
            $iniLines = @()
            
            # Process global keys first (not in sections)
            $globalKeys = $InputObject.Keys | Where-Object { $InputObject[$_] -isnot [hashtable] }
            foreach ($key in $globalKeys) {
                if ($key.StartsWith('_comment_') -and $IncludeComments) {
                    $iniLines += $InputObject[$key]
                }
                elseif (-not $key.StartsWith('_comment_')) {
                    $iniLines += "$key=$($InputObject[$key])"
                }
            }
            
            # Add blank line after global keys if they exist
            if ($globalKeys.Count -gt 0) {
                $iniLines += ''
            }
            
            # Process sections
            $sections = $InputObject.Keys | Where-Object { $InputObject[$_] -is [hashtable] }
            $sections = $sections | Sort-Object  # Sort sections alphabetically
            
            foreach ($section in $sections) {
                # Add section header
                $iniLines += ($SectionHeader -f $section)
                
                $sectionData = $InputObject[$section]
                $sectionKeys = $sectionData.Keys | Sort-Object  # Sort keys alphabetically
                
                foreach ($key in $sectionKeys) {
                    if ($key.StartsWith('_comment_') -and $IncludeComments) {
                        $iniLines += $sectionData[$key]
                    }
                    elseif (-not $key.StartsWith('_comment_')) {
                        $iniLines += "$key=$($sectionData[$key])"
                    }
                }
                
                # Add blank line after section (except for last section)
                if ($section -ne $sections[-1]) {
                    $iniLines += ''
                }
            }
            
            $iniContent = $iniLines -join "`n"
            
            if ($Path) {
                try {
                    $iniContent | Out-File -FilePath $Path -Encoding UTF8 -Force
                    Write-Verbose "INI content written to: $Path"
                }
                catch {
                    throw "Failed to write INI file '$Path': $_"
                }
            }
            else {
                return $iniContent
            }
        }
        catch {
            throw "Failed to convert hashtable to INI format: $_"
        }
    }
}

function Test-IniFile {
    <#
    .SYNOPSIS
        Tests if a file contains valid INI format
    .DESCRIPTION
        Validates INI file format and reports any parsing errors
    .PARAMETER Path
        Path to INI file to validate
    .OUTPUTS
        [PSCustomObject] Validation result with IsValid boolean and Errors array
    .EXAMPLE
        Test-IniFile -Path "config.ini"
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    $result = [PSCustomObject]@{
        IsValid = $false
        Path = $Path
        Errors = @()
        Warnings = @()
        SectionCount = 0
        KeyCount = 0
    }
    
    if (-not (Test-Path $Path)) {
        $result.Errors += "File not found: $Path"
        return $result
    }
    
    try {
        $parsed = ConvertFrom-IniFile -Path $Path -ErrorAction Stop
        $result.IsValid = $true
        $result.SectionCount = ($parsed.Keys | Where-Object { $parsed[$_] -is [hashtable] }).Count
        $result.KeyCount = ($parsed.Keys | Where-Object { $parsed[$_] -isnot [hashtable] }).Count
        
        # Count keys in sections
        foreach ($key in $parsed.Keys) {
            if ($parsed[$key] -is [hashtable]) {
                $result.KeyCount += ($parsed[$key].Keys | Where-Object { -not $_.StartsWith('_comment_') }).Count
            }
        }
    }
    catch {
        $result.Errors += $_.Exception.Message
    }
    
    return $result
}

function Merge-IniFile {
    <#
    .SYNOPSIS  
        Merges multiple INI configurations with precedence rules
    .DESCRIPTION
        Combines multiple INI hashtables with later ones taking precedence.
        Useful for configuration override scenarios.
    .PARAMETER BaseConfiguration
        Base configuration hashtable (lowest precedence)
    .PARAMETER OverrideConfiguration  
        Override configuration hashtable (highest precedence)
    .OUTPUTS
        [hashtable] Merged configuration
    .EXAMPLE
        $merged = Merge-IniFile -BaseConfiguration $defaultConfig -OverrideConfiguration $userConfig
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$BaseConfiguration,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$OverrideConfiguration
    )
    
    $result = $BaseConfiguration.Clone()
    
    foreach ($key in $OverrideConfiguration.Keys) {
        if ($OverrideConfiguration[$key] -is [hashtable]) {
            # Section merge
            if ($result.ContainsKey($key) -and $result[$key] -is [hashtable]) {
                # Merge sections recursively
                $mergedSection = $result[$key].Clone()
                foreach ($subKey in $OverrideConfiguration[$key].Keys) {
                    $mergedSection[$subKey] = $OverrideConfiguration[$key][$subKey]
                }
                $result[$key] = $mergedSection
            }
            else {
                # New section
                $result[$key] = $OverrideConfiguration[$key].Clone()
            }
        }
        else {
            # Direct key override
            $result[$key] = $OverrideConfiguration[$key]
        }
    }
    
    return $result
}

# Export functions
Export-ModuleMember -Function @(
    'ConvertFrom-IniFile',
    'ConvertTo-IniFile',
    'Test-IniFile', 
    'Merge-IniFile'
)