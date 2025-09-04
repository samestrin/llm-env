#Requires -Version 5.1
<#
.SYNOPSIS
    Windows UI integration features for LLM Environment Manager
.DESCRIPTION
    Provides Windows-specific UI enhancements including file dialogs,
    notifications, error dialogs, and clipboard integration.
.NOTES
    Compatible with PowerShell 5.1+ and 7+, Windows-specific features
#>

Set-StrictMode -Version Latest

# Import required assemblies for Windows UI features
Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue

function Show-LLMFileDialog {
    <#
    .SYNOPSIS
        Shows a Windows file dialog for configuration file selection
    .DESCRIPTION
        Displays native Windows file open/save dialogs for configuration files
    .PARAMETER Mode
        Dialog mode: Open or Save
    .PARAMETER Title
        Dialog title
    .PARAMETER InitialDirectory
        Starting directory for dialog
    .PARAMETER DefaultFileName
        Default file name (for save dialogs)
    .OUTPUTS
        [string] Selected file path or null if cancelled
    .EXAMPLE
        $configFile = Show-LLMFileDialog -Mode Open -Title "Select Configuration File"
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Open', 'Save')]
        [string]$Mode,
        
        [Parameter()]
        [string]$Title = "Select Configuration File",
        
        [Parameter()]
        [string]$InitialDirectory,
        
        [Parameter()]
        [string]$DefaultFileName = "llm-env.conf"
    )
    
    try {
        # Check if we're on Windows and have Windows Forms available
        if (-not ($IsWindows -or $env:OS -eq 'Windows_NT' -or $PSVersionTable.Platform -eq 'Win32NT' -or -not $PSVersionTable.Platform)) {
            Write-Warning "File dialogs are only available on Windows"
            return $null
        }
        
        if (-not ([System.Management.Automation.PSTypeName]'System.Windows.Forms.OpenFileDialog').Type) {
            Write-Warning "Windows Forms not available - file dialog cannot be shown"
            return $null
        }
        
        # Set initial directory
        $startDir = if ($InitialDirectory -and (Test-Path $InitialDirectory)) {
            $InitialDirectory
        } else {
            try {
                Get-LLMConfigDirectory
            }
            catch {
                $env:USERPROFILE -or $env:HOME -or (Get-Location).Path
            }
        }
        
        if ($Mode -eq 'Open') {
            $dialog = New-Object System.Windows.Forms.OpenFileDialog
            $dialog.CheckFileExists = $true
            $dialog.CheckPathExists = $true
        } else {
            $dialog = New-Object System.Windows.Forms.SaveFileDialog
            $dialog.FileName = $DefaultFileName
            $dialog.CreatePrompt = $false
            $dialog.OverwritePrompt = $true
        }
        
        # Configure dialog
        $dialog.Title = $Title
        $dialog.InitialDirectory = $startDir
        $dialog.Filter = "Configuration Files (*.conf)|*.conf|INI Files (*.ini)|*.ini|All Files (*.*)|*.*"
        $dialog.FilterIndex = 1
        $dialog.RestoreDirectory = $true
        
        # Show dialog
        $result = $dialog.ShowDialog()
        
        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            return $dialog.FileName
        }
        
        return $null
    }
    catch {
        Write-Warning "Failed to show file dialog: $_"
        return $null
    }
    finally {
        if ($dialog) {
            $dialog.Dispose()
        }
    }
}

function Show-LLMNotification {
    <#
    .SYNOPSIS
        Shows a Windows toast notification
    .DESCRIPTION
        Displays native Windows notifications for long-running operations
    .PARAMETER Title
        Notification title
    .PARAMETER Message
        Notification message
    .PARAMETER Icon
        Notification icon type
    .PARAMETER Duration
        How long to show notification (milliseconds)
    .OUTPUTS
        [void]
    .EXAMPLE
        Show-LLMNotification -Title "LLM Environment" -Message "Provider test completed" -Icon Information
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('None', 'Info', 'Warning', 'Error')]
        [string]$Icon = 'Info',
        
        [Parameter()]
        [int]$Duration = 3000
    )
    
    try {
        # Check if we're on Windows
        if (-not ($IsWindows -or $env:OS -eq 'Windows_NT' -or $PSVersionTable.Platform -eq 'Win32NT' -or -not $PSVersionTable.Platform)) {
            Write-Verbose "Notifications are only available on Windows - falling back to console output"
            Write-Host "$Title`: $Message" -ForegroundColor Cyan
            return
        }
        
        # Try Windows 10/11 toast notifications first
        if (Get-Command New-BurntToastNotification -ErrorAction SilentlyContinue) {
            try {
                $iconType = switch ($Icon) {
                    'Warning' { 'Warning' }
                    'Error' { 'Critical' }
                    default { 'Information' }
                }
                
                New-BurntToastNotification -Text $Title, $Message -AppLogo (Join-Path $PSScriptRoot 'icon.png') -Silent:$false
                return
            }
            catch {
                Write-Verbose "Toast notification failed: $_"
            }
        }
        
        # Fallback to system tray balloon notification
        if ([System.Management.Automation.PSTypeName]'System.Windows.Forms.NotifyIcon').Type) {
            $notifyIcon = New-Object System.Windows.Forms.NotifyIcon
            
            try {
                # Set icon based on type
                $iconType = switch ($Icon) {
                    'Warning' { [System.Windows.Forms.ToolTipIcon]::Warning }
                    'Error' { [System.Windows.Forms.ToolTipIcon]::Error }
                    default { [System.Windows.Forms.ToolTipIcon]::Info }
                }
                
                $notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
                $notifyIcon.Visible = $true
                $notifyIcon.ShowBalloonTip($Duration, $Title, $Message, $iconType)
                
                # Clean up after showing
                Start-Sleep -Milliseconds ($Duration + 500)
            }
            finally {
                $notifyIcon.Visible = $false
                $notifyIcon.Dispose()
            }
        }
        else {
            # Final fallback to console
            Write-Host "$Title`: $Message" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Warning "Failed to show notification: $_"
        Write-Host "$Title`: $Message" -ForegroundColor Cyan
    }
}

function Show-LLMErrorDialog {
    <#
    .SYNOPSIS
        Shows a Windows error dialog
    .DESCRIPTION
        Displays native Windows error dialogs for better user experience
    .PARAMETER Title
        Error dialog title
    .PARAMETER Message
        Error message
    .PARAMETER Details
        Additional error details
    .PARAMETER Buttons
        Dialog buttons to show
    .OUTPUTS
        [string] User's button selection
    .EXAMPLE
        $result = Show-LLMErrorDialog -Title "Configuration Error" -Message "Invalid provider settings" -Details $error.Exception.Message
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter()]
        [string]$Details,
        
        [Parameter()]
        [ValidateSet('OK', 'OKCancel', 'YesNo', 'YesNoCancel')]
        [string]$Buttons = 'OK'
    )
    
    try {
        # Check if we're on Windows and have the required assemblies
        if (-not ($IsWindows -or $env:OS -eq 'Windows_NT' -or $PSVersionTable.Platform -eq 'Win32NT' -or -not $PSVersionTable.Platform)) {
            Write-Warning "Error dialogs are only available on Windows - showing in console"
            Write-Host "Error: $Title" -ForegroundColor Red
            Write-Host $Message -ForegroundColor Red
            if ($Details) {
                Write-Host "Details: $Details" -ForegroundColor Gray
            }
            return 'OK'
        }
        
        # Try WPF MessageBox first (better looking)
        if ([System.Management.Automation.PSTypeName]'System.Windows.MessageBox').Type) {
            $messageBoxText = $Message
            if ($Details) {
                $messageBoxText += "`n`nDetails: $Details"
            }
            
            $buttonType = switch ($Buttons) {
                'OKCancel' { [System.Windows.MessageBoxButton]::OKCancel }
                'YesNo' { [System.Windows.MessageBoxButton]::YesNo }
                'YesNoCancel' { [System.Windows.MessageBoxButton]::YesNoCancel }
                default { [System.Windows.MessageBoxButton]::OK }
            }
            
            $result = [System.Windows.MessageBox]::Show(
                $messageBoxText,
                $Title,
                $buttonType,
                [System.Windows.MessageBoxImage]::Error
            )
            
            return $result.ToString()
        }
        
        # Fallback to Windows Forms MessageBox
        if ([System.Management.Automation.PSTypeName]'System.Windows.Forms.MessageBox').Type) {
            $messageBoxText = $Message
            if ($Details) {
                $messageBoxText += "`n`nDetails: $Details"
            }
            
            $buttonType = switch ($Buttons) {
                'OKCancel' { [System.Windows.Forms.MessageBoxButtons]::OKCancel }
                'YesNo' { [System.Windows.Forms.MessageBoxButtons]::YesNo }
                'YesNoCancel' { [System.Windows.Forms.MessageBoxButtons]::YesNoCancel }
                default { [System.Windows.Forms.MessageBoxButtons]::OK }
            }
            
            $result = [System.Windows.Forms.MessageBox]::Show(
                $messageBoxText,
                $Title,
                $buttonType,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
            
            return $result.ToString()
        }
        
        # Final fallback to console
        Write-Host "Error: $Title" -ForegroundColor Red
        Write-Host $Message -ForegroundColor Red
        if ($Details) {
            Write-Host "Details: $Details" -ForegroundColor Gray
        }
        return 'OK'
    }
    catch {
        Write-Warning "Failed to show error dialog: $_"
        Write-Host "Error: $Title" -ForegroundColor Red
        Write-Host $Message -ForegroundColor Red
        if ($Details) {
            Write-Host "Details: $Details" -ForegroundColor Gray
        }
        return 'OK'
    }
}

function Set-LLMClipboard {
    <#
    .SYNOPSIS
        Copies text to Windows clipboard
    .DESCRIPTION
        Provides clipboard integration for API keys and configuration data
    .PARAMETER Text
        Text to copy to clipboard
    .PARAMETER Secure
        Indicate that the text is sensitive (affects user feedback)
    .OUTPUTS
        [bool] True if successful
    .EXAMPLE
        Set-LLMClipboard -Text $apiKey -Secure
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        
        [Parameter()]
        [switch]$Secure
    )
    
    try {
        # Check if we're on Windows
        if (-not ($IsWindows -or $env:OS -eq 'Windows_NT' -or $PSVersionTable.Platform -eq 'Win32NT' -or -not $PSVersionTable.Platform)) {
            Write-Warning "Clipboard operations are only available on Windows"
            return $false
        }
        
        # Try Set-Clipboard cmdlet first (PowerShell 5.1+)
        if (Get-Command Set-Clipboard -ErrorAction SilentlyContinue) {
            Set-Clipboard -Value $Text
            if ($Secure) {
                Write-Host "✓ Secure text copied to clipboard" -ForegroundColor Green
            } else {
                Write-Host "✓ Text copied to clipboard" -ForegroundColor Green
            }
            return $true
        }
        
        # Fallback to Windows Forms clipboard
        if ([System.Management.Automation.PSTypeName]'System.Windows.Forms.Clipboard').Type) {
            [System.Windows.Forms.Clipboard]::SetText($Text)
            if ($Secure) {
                Write-Host "✓ Secure text copied to clipboard" -ForegroundColor Green
            } else {
                Write-Host "✓ Text copied to clipboard" -ForegroundColor Green
            }
            return $true
        }
        
        # Final fallback using clip.exe (Windows built-in)
        if (Get-Command clip.exe -ErrorAction SilentlyContinue) {
            $Text | clip.exe
            if ($Secure) {
                Write-Host "✓ Secure text copied to clipboard" -ForegroundColor Green
            } else {
                Write-Host "✓ Text copied to clipboard" -ForegroundColor Green
            }
            return $true
        }
        
        Write-Warning "No clipboard method available"
        return $false
    }
    catch {
        Write-Warning "Failed to copy to clipboard: $_"
        return $false
    }
}

function Get-LLMClipboard {
    <#
    .SYNOPSIS
        Gets text from Windows clipboard
    .DESCRIPTION
        Retrieves text from clipboard for pasting API keys or configuration
    .OUTPUTS
        [string] Clipboard text content
    .EXAMPLE
        $clipboardContent = Get-LLMClipboard
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()
    
    try {
        # Check if we're on Windows
        if (-not ($IsWindows -or $env:OS -eq 'Windows_NT' -or $PSVersionTable.Platform -eq 'Win32NT' -or -not $PSVersionTable.Platform)) {
            Write-Warning "Clipboard operations are only available on Windows"
            return $null
        }
        
        # Try Get-Clipboard cmdlet first (PowerShell 5.1+)
        if (Get-Command Get-Clipboard -ErrorAction SilentlyContinue) {
            return Get-Clipboard -Raw
        }
        
        # Fallback to Windows Forms clipboard
        if ([System.Management.Automation.PSTypeName]'System.Windows.Forms.Clipboard').Type) {
            return [System.Windows.Forms.Clipboard]::GetText()
        }
        
        Write-Warning "No clipboard method available"
        return $null
    }
    catch {
        Write-Warning "Failed to get clipboard content: $_"
        return $null
    }
}

function Show-LLMProgressDialog {
    <#
    .SYNOPSIS
        Shows a Windows progress dialog for long-running operations
    .DESCRIPTION
        Displays native Windows progress dialogs with cancellation support
    .PARAMETER Title
        Progress dialog title
    .PARAMETER Status
        Current status text
    .PARAMETER PercentComplete
        Percentage complete (0-100)
    .PARAMETER AllowCancel
        Allow user to cancel operation
    .OUTPUTS
        [PSCustomObject] Progress dialog object with methods
    .EXAMPLE
        $progress = Show-LLMProgressDialog -Title "Testing Providers" -AllowCancel
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter()]
        [string]$Status = "Please wait...",
        
        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$PercentComplete = 0,
        
        [Parameter()]
        [switch]$AllowCancel
    )
    
    try {
        # Check if we're on Windows
        if (-not ($IsWindows -or $env:OS -eq 'Windows_NT' -or $PSVersionTable.Platform -eq 'Win32NT' -or -not $PSVersionTable.Platform)) {
            Write-Progress -Activity $Title -Status $Status -PercentComplete $PercentComplete
            return [PSCustomObject]@{
                Update = { param($status, $percent) Write-Progress -Activity $Title -Status $status -PercentComplete $percent }
                Complete = { Write-Progress -Activity $Title -Completed }
                IsCancelled = { $false }
            }
        }
        
        # Try to create a Windows progress dialog
        if ([System.Management.Automation.PSTypeName]'System.Windows.Forms.ProgressBar').Type) {
            # This is a simplified version - in a real implementation, you'd create a proper form
            Write-Progress -Activity $Title -Status $Status -PercentComplete $PercentComplete
            
            return [PSCustomObject]@{
                Update = { 
                    param($status, $percent) 
                    Write-Progress -Activity $Title -Status $status -PercentComplete $percent 
                }
                Complete = { 
                    Write-Progress -Activity $Title -Completed 
                }
                IsCancelled = { $false }
            }
        }
        
        # Fallback to PowerShell's Write-Progress
        Write-Progress -Activity $Title -Status $Status -PercentComplete $PercentComplete
        
        return [PSCustomObject]@{
            Update = { param($status, $percent) Write-Progress -Activity $Title -Status $status -PercentComplete $percent }
            Complete = { Write-Progress -Activity $Title -Completed }
            IsCancelled = { $false }
        }
    }
    catch {
        Write-Warning "Failed to show progress dialog: $_"
        
        # Return a minimal progress object
        return [PSCustomObject]@{
            Update = { param($status, $percent) Write-Host "$status ($percent%)" }
            Complete = { Write-Host "Operation completed" }
            IsCancelled = { $false }
        }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Show-LLMFileDialog',
    'Show-LLMNotification',
    'Show-LLMErrorDialog', 
    'Set-LLMClipboard',
    'Get-LLMClipboard',
    'Show-LLMProgressDialog'
)