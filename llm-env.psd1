@{
    # Module manifest for LLM Environment Manager PowerShell version
    
    RootModule = 'llm-env.psm1'
    ModuleVersion = '1.1.0'
    GUID = 'e4d8c8a6-7b2f-4c9a-8f1d-3e5a9c7b2f4e'
    Author = 'Sam Estrin'
    Description = 'PowerShell module for managing LLM environment variables and provider configurations'
    PowerShellVersion = '5.1'
    
    # Functions to export from this module
    FunctionsToExport = @(
        'Set-LLMProvider',
        'Clear-LLMProvider', 
        'Get-LLMProviders',
        'Show-LLMProvider',
        'Initialize-LLMConfig',
        'Edit-LLMConfig',
        'Add-LLMProvider',
        'Remove-LLMProvider',
        'Test-LLMProvider',
        'Backup-LLMConfig',
        'Restore-LLMConfig',
        'Enable-LLMProvider',
        'Disable-LLMProvider'
    )
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @(
        'llm-set',
        'llm-unset',
        'llm-list',
        'llm-show'
    )
    
    # Private data to pass to the module
    PrivateData = @{
        PSData = @{
            Tags = @('LLM', 'AI', 'Environment', 'Configuration', 'PowerShell')
            ProjectUri = 'https://github.com/samestrin/llm-env'
            RequireLicenseAcceptance = $false
        }
    }
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellHostName = ''
    PowerShellHostVersion = ''
    
    # Processor architecture required by this module
    ProcessorArchitecture = 'None'
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()
    
    # Script files (.ps1) that are run in the caller's environment prior to importing this module
    ScriptsToProcess = @()
    
    # Type files (.ps1xml) to be loaded when importing this module
    TypesToProcess = @()
    
    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @()
    
    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules = @()
    
    # DSC resources to export from this module
    DscResourcesToExport = @()
    
    # List of all modules packaged with this module
    ModuleList = @()
    
    # List of all files packaged with this module
    FileList = @()
    
    # HelpInfo URI of this module
    HelpInfoURI = ''
    
    # Default prefix for commands exported from this module
    DefaultCommandPrefix = ''
}