#Requires -Version 5.1
<#
.SYNOPSIS
    Creates a backup of the LLM configuration
.DESCRIPTION
    Equivalent to 'llm-env config backup'. Creates timestamped backups
    of configuration files for safe keeping.
.PARAMETER Path
    Custom configuration file to backup
.PARAMETER BackupPath
    Custom backup file path (auto-generated if not specified)
.PARAMETER Compress
    Create compressed backup (zip file)
.OUTPUTS
    [string] Path to created backup file
.EXAMPLE
    Backup-LLMConfig
.EXAMPLE
    Backup-LLMConfig -Compress
.EXAMPLE
    Backup-LLMConfig -Path "C:\config\llm-env.conf" -BackupPath "C:\backups\my-backup.conf"
#>
function Backup-LLMConfig {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter()]
        [string]$Path,
        
        [Parameter()]
        [string]$BackupPath,
        
        [Parameter()]
        [switch]$Compress
    )
    
    try {
        # Determine source configuration file
        $configFile = if ($Path) { 
            Resolve-LLMPath $Path 
        } else { 
            Get-LLMConfigFilePath 
        }
        
        if (-not (Test-Path $configFile)) {
            throw "Configuration file not found: $configFile"
        }
        
        Write-Verbose "Creating backup of configuration: $configFile"
        
        # Generate backup path if not specified
        if (-not $BackupPath) {
            $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            $configDir = Split-Path $configFile -Parent
            $configName = [System.IO.Path]::GetFileNameWithoutExtension($configFile)
            $configExt = [System.IO.Path]::GetExtension($configFile)
            
            if ($Compress) {
                $BackupPath = Join-Path $configDir "backup-$configName-$timestamp.zip"
            } else {
                $BackupPath = Join-Path $configDir "backup-$configName-$timestamp$configExt"
            }
        } else {
            $BackupPath = Resolve-LLMPath $BackupPath
        }
        
        # Ensure backup directory exists
        $backupDir = Split-Path $BackupPath -Parent
        if (-not (Test-Path $backupDir)) {
            New-LLMDirectory -Path $backupDir -Force | Out-Null
        }
        
        # Create backup
        if ($Compress) {
            # Create zip backup
            if (Get-Command Compress-Archive -ErrorAction SilentlyContinue) {
                Compress-Archive -Path $configFile -DestinationPath $BackupPath -Force
                Write-Verbose "Created compressed backup using Compress-Archive"
            } else {
                # Fallback for older PowerShell versions
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                $zip = [System.IO.Compression.ZipFile]::Open($BackupPath, 'Create')
                try {
                    $fileName = Split-Path $configFile -Leaf
                    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $configFile, $fileName) | Out-Null
                    Write-Verbose "Created compressed backup using .NET methods"
                }
                finally {
                    $zip.Dispose()
                }
            }
        } else {
            # Simple file copy
            Copy-Item -Path $configFile -Destination $BackupPath -Force
            Write-Verbose "Created backup copy"
        }
        
        # Verify backup was created
        if (-not (Test-Path $BackupPath)) {
            throw "Backup file was not created successfully"
        }
        
        # Get file sizes for reporting
        $originalSize = (Get-Item $configFile).Length
        $backupSize = (Get-Item $BackupPath).Length
        
        Write-Host "✓ Configuration backup created successfully" -ForegroundColor Green
        Write-Host "  Source: " -NoNewline -ForegroundColor Gray
        Write-Host "$configFile" -ForegroundColor White
        Write-Host "  Backup: " -NoNewline -ForegroundColor Gray
        Write-Host "$BackupPath" -ForegroundColor Cyan
        Write-Host "  Original size: " -NoNewline -ForegroundColor Gray
        Write-Host "$originalSize bytes" -ForegroundColor White
        Write-Host "  Backup size: " -NoNewline -ForegroundColor Gray
        Write-Host "$backupSize bytes" -ForegroundColor White
        
        if ($Compress -and $backupSize -lt $originalSize) {
            $compressionRatio = [math]::Round((1 - ($backupSize / $originalSize)) * 100, 1)
            Write-Host "  Compression: " -NoNewline -ForegroundColor Gray
            Write-Host "$compressionRatio% saved" -ForegroundColor Green
        }
        
        return $BackupPath
    }
    catch {
        Write-Error "Failed to backup LLM configuration: $_"
        throw
    }
}