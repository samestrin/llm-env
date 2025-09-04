#Requires -Version 5.1
<#
.SYNOPSIS
    Restores LLM configuration from a backup file
.DESCRIPTION
    Equivalent to 'llm-env config restore'. Restores configuration
    from previously created backup files.
.PARAMETER BackupPath
    Path to backup file to restore from
.PARAMETER DestinationPath
    Destination path for restored configuration (defaults to standard location)
.PARAMETER Force
    Overwrite existing configuration without confirmation
.PARAMETER CreateBackup
    Create backup of current configuration before restoring
.OUTPUTS
    [void]
.EXAMPLE
    Restore-LLMConfig -BackupPath "backup-llm-env-20241201-143022.conf"
.EXAMPLE
    Restore-LLMConfig -BackupPath "backup.zip" -CreateBackup -Force
#>
function Restore-LLMConfig {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupPath,
        
        [Parameter()]
        [string]$DestinationPath,
        
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [switch]$CreateBackup
    )
    
    try {
        # Resolve backup file path
        $backupFile = Resolve-LLMPath $BackupPath
        if (-not (Test-Path $backupFile)) {
            throw "Backup file not found: $backupFile"
        }
        
        # Determine destination path
        $destinationFile = if ($DestinationPath) { 
            Resolve-LLMPath $DestinationPath 
        } else { 
            Get-LLMConfigFilePath 
        }
        
        Write-Verbose "Restoring configuration from backup: $backupFile"
        Write-Verbose "Destination: $destinationFile"
        
        # Check if destination exists and handle accordingly
        $destinationExists = Test-Path $destinationFile
        if ($destinationExists -and -not $Force) {
            Write-Host "Current configuration:" -ForegroundColor Yellow
            Write-Host "  File: $destinationFile" -ForegroundColor White
            Write-Host "  Size: $((Get-Item $destinationFile).Length) bytes" -ForegroundColor White
            Write-Host "  Modified: $((Get-Item $destinationFile).LastWriteTime)" -ForegroundColor White
            Write-Host ""
            
            $response = Read-Host "Configuration file exists. Overwrite? (y/N)"
            if ($response -notmatch '^[Yy]') {
                Write-Host "Restore cancelled." -ForegroundColor Yellow
                return
            }
        }
        
        if ($PSCmdlet.ShouldProcess($destinationFile, 'Restore LLM Configuration')) {
            # Create backup of current config if requested
            if ($CreateBackup -and $destinationExists) {
                try {
                    $currentBackup = Backup-LLMConfig -Path $destinationFile
                    Write-Host "✓ Current configuration backed up to: $currentBackup" -ForegroundColor Green
                }
                catch {
                    Write-Warning "Failed to backup current configuration: $_"
                    if (-not $Force) {
                        throw "Restore cancelled due to backup failure"
                    }
                }
            }
            
            # Ensure destination directory exists
            $destinationDir = Split-Path $destinationFile -Parent
            if (-not (Test-Path $destinationDir)) {
                New-LLMDirectory -Path $destinationDir -Force | Out-Null
            }
            
            # Determine if backup is compressed
            $backupExt = [System.IO.Path]::GetExtension($backupFile).ToLower()
            $isCompressed = $backupExt -eq '.zip'
            
            if ($isCompressed) {
                # Extract from zip file
                Write-Verbose "Extracting from compressed backup"
                
                if (Get-Command Expand-Archive -ErrorAction SilentlyContinue) {
                    # Use built-in cmdlet (PowerShell 5.0+)
                    $tempDir = Join-Path $env:TEMP "llm-env-restore-$(Get-Random)"
                    try {
                        Expand-Archive -Path $backupFile -DestinationPath $tempDir -Force
                        
                        # Find the configuration file in the extracted content
                        $extractedFiles = Get-ChildItem $tempDir -File
                        $configFile = $extractedFiles | Where-Object { 
                            $_.Name -match '\.(conf|ini)$' -or 
                            $_.Name -eq 'llm-env.conf' -or
                            $_.Name -eq 'config.conf'
                        } | Select-Object -First 1
                        
                        if (-not $configFile) {
                            throw "No configuration file found in backup archive"
                        }
                        
                        Copy-Item -Path $configFile.FullName -Destination $destinationFile -Force
                        Write-Verbose "Extracted and copied: $($configFile.Name)"
                    }
                    finally {
                        if (Test-Path $tempDir) {
                            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
                        }
                    }
                } else {
                    # Fallback for older PowerShell versions
                    Add-Type -AssemblyName System.IO.Compression.FileSystem
                    $zip = [System.IO.Compression.ZipFile]::OpenRead($backupFile)
                    try {
                        $entry = $zip.Entries | Where-Object { 
                            $_.Name -match '\.(conf|ini)$' -or 
                            $_.Name -eq 'llm-env.conf' -or
                            $_.Name -eq 'config.conf'
                        } | Select-Object -First 1
                        
                        if (-not $entry) {
                            throw "No configuration file found in backup archive"
                        }
                        
                        $stream = $entry.Open()
                        try {
                            $fileStream = [System.IO.File]::Create($destinationFile)
                            try {
                                $stream.CopyTo($fileStream)
                                Write-Verbose "Extracted and copied: $($entry.Name)"
                            }
                            finally {
                                $fileStream.Close()
                            }
                        }
                        finally {
                            $stream.Close()
                        }
                    }
                    finally {
                        $zip.Dispose()
                    }
                }
            } else {
                # Simple file copy
                Copy-Item -Path $backupFile -Destination $destinationFile -Force
                Write-Verbose "Copied backup file to destination"
            }
            
            # Verify restoration
            if (-not (Test-Path $destinationFile)) {
                throw "Configuration file was not restored successfully"
            }
            
            # Clear configuration cache to force reload
            Clear-LLMConfigurationCache
            
            # Validate restored configuration
            try {
                $restoredConfig = Get-LLMConfiguration -Force
                $validationResult = Test-LLMConfiguration -Configuration $restoredConfig
                
                Write-Host "✓ Configuration restored successfully" -ForegroundColor Green
                Write-Host "  Source backup: " -NoNewline -ForegroundColor Gray
                Write-Host "$backupFile" -ForegroundColor Cyan
                Write-Host "  Destination: " -NoNewline -ForegroundColor Gray
                Write-Host "$destinationFile" -ForegroundColor White
                Write-Host "  Providers: " -NoNewline -ForegroundColor Gray
                Write-Host "$($restoredConfig.Count())" -ForegroundColor White
                Write-Host "  Valid providers: " -NoNewline -ForegroundColor Gray
                Write-Host "$($validationResult.ProviderCount)" -ForegroundColor White
                
                if ($validationResult.Errors.Count -gt 0) {
                    Write-Host ""
                    Write-Host "Configuration validation warnings:" -ForegroundColor Yellow
                    foreach ($error in $validationResult.Errors) {
                        Write-Host "  - $error" -ForegroundColor Yellow
                    }
                }
                
                Write-Host ""
                Write-Host "Configuration is ready to use!" -ForegroundColor Green
                Write-Host "Use 'Get-LLMProviders' to see available providers" -ForegroundColor Gray
            }
            catch {
                Write-Warning "Configuration restored but validation failed: $_"
                Write-Host "You may need to review the configuration file manually." -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Error "Failed to restore LLM configuration: $_"
        throw
    }
}