#Requires -Version 5.1
<#
.SYNOPSIS
    Opens LLM configuration file for editing
.DESCRIPTION
    Equivalent to 'llm-env config edit'. Opens the configuration file
    in the default editor or specified editor.
.PARAMETER Path
    Custom configuration file path to edit
.PARAMETER Editor
    Specific editor to use (default: system default)
.PARAMETER Wait
    Wait for editor to close before continuing
.OUTPUTS
    [void]
.EXAMPLE
    Edit-LLMConfig
.EXAMPLE
    Edit-LLMConfig -Editor "code"
.EXAMPLE
    Edit-LLMConfig -Path "C:\MyConfig\llm-env.conf" -Wait
#>
function Edit-LLMConfig {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path,
        
        [Parameter()]
        [string]$Editor,
        
        [Parameter()]
        [switch]$Wait
    )
    
    try {
        # Determine configuration file path
        $configPath = if ($Path) { 
            Resolve-LLMPath $Path 
        } else { 
            Get-LLMConfigFilePath 
        }
        
        Write-Verbose "Editing LLM configuration: $configPath"
        
        # Check if file exists
        if (-not (Test-Path $configPath)) {
            Write-Warning "Configuration file not found: $configPath"
            $response = Read-Host "Would you like to create a new configuration file? (y/N)"
            if ($response -match '^[Yy]') {
                Initialize-LLMConfig -Path $configPath -IncludeDefaults
            } else {
                return
            }
        }
        
        # Clear configuration cache since file will be modified
        Clear-LLMConfigurationCache
        
        # Determine editor to use
        $editorCmd = $null
        
        if ($Editor) {
            $editorCmd = $Editor
        }
        elseif ($env:EDITOR) {
            $editorCmd = $env:EDITOR
        }
        elseif ($IsWindows -or $env:OS -eq 'Windows_NT' -or $PSVersionTable.Platform -eq 'Win32NT' -or -not $PSVersionTable.Platform) {
            # Windows - try common editors
            $windowsEditors = @('code', 'notepad++', 'notepad')
            foreach ($editor in $windowsEditors) {
                if (Get-Command $editor -ErrorAction SilentlyContinue) {
                    $editorCmd = $editor
                    break
                }
            }
            if (-not $editorCmd) {
                $editorCmd = 'notepad'  # Always available on Windows
            }
        }
        elseif ($IsMacOS) {
            # macOS
            $macEditors = @('code', 'open -t', 'nano', 'vim')
            foreach ($editor in $macEditors) {
                $cmd = $editor.Split()[0]
                if (Get-Command $cmd -ErrorAction SilentlyContinue) {
                    $editorCmd = $editor
                    break
                }
            }
            if (-not $editorCmd) {
                $editorCmd = 'open -t'  # Default text editor on macOS
            }
        }
        else {
            # Linux/Unix
            $linuxEditors = @('code', 'gedit', 'nano', 'vim')
            foreach ($editor in $linuxEditors) {
                if (Get-Command $editor -ErrorAction SilentlyContinue) {
                    $editorCmd = $editor
                    break
                }
            }
            if (-not $editorCmd) {
                $editorCmd = 'nano'  # Common default
            }
        }
        
        Write-Host "Opening configuration file with: " -NoNewline -ForegroundColor Gray
        Write-Host "$editorCmd" -ForegroundColor Cyan
        Write-Host "File: " -NoNewline -ForegroundColor Gray
        Write-Host "$configPath" -ForegroundColor White
        
        try {
            # Launch editor
            if ($Wait -or $editorCmd -in @('nano', 'vim', 'emacs')) {
                # Console editors or explicit wait request
                $process = Start-Process -FilePath $editorCmd.Split()[0] -ArgumentList ($editorCmd.Split()[1..99] + @("`"$configPath`"")) -Wait -NoNewWindow -PassThru
                if ($process.ExitCode -ne 0) {
                    Write-Warning "Editor exited with code: $($process.ExitCode)"
                }
            } else {
                # GUI editors - launch without waiting
                $editorParts = $editorCmd.Split()
                if ($editorParts.Count -gt 1) {
                    Start-Process -FilePath $editorParts[0] -ArgumentList ($editorParts[1..99] + @("`"$configPath`"")) -ErrorAction Stop
                } else {
                    Start-Process -FilePath $editorCmd -ArgumentList @("`"$configPath`"") -ErrorAction Stop
                }
            }
            
            Write-Host "Configuration file opened for editing." -ForegroundColor Green
            Write-Host ""
            Write-Host "After editing:" -ForegroundColor Yellow
            Write-Host "- Changes take effect immediately" -ForegroundColor Gray
            Write-Host "- Use 'Get-LLMProviders' to verify your changes" -ForegroundColor Gray
            Write-Host "- Use 'Test-LLMProvider' to validate configurations" -ForegroundColor Gray
        }
        catch {
            Write-Warning "Failed to launch editor '$editorCmd': $_"
            Write-Host ""
            Write-Host "You can manually edit the file at: " -NoNewline -ForegroundColor Gray
            Write-Host "$configPath" -ForegroundColor Cyan
            
            # Try to open file location instead
            try {
                if ($IsWindows -or $env:OS -eq 'Windows_NT' -or $PSVersionTable.Platform -eq 'Win32NT' -or -not $PSVersionTable.Platform) {
                    explorer.exe /select,"`"$configPath`""
                } elseif ($IsMacOS) {
                    open (Split-Path $configPath -Parent)
                } else {
                    # Linux - try to open file manager
                    if (Get-Command nautilus -ErrorAction SilentlyContinue) {
                        nautilus (Split-Path $configPath -Parent) &
                    }
                }
            }
            catch {
                Write-Verbose "Could not open file location: $_"
            }
        }
    }
    catch {
        Write-Error "Failed to edit LLM configuration: $_"
        throw
    }
}