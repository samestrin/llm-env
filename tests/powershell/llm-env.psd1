#
# Module manifest for LLM Environment Manager PowerShell Module
# Generated for test compliance and proper module loading
#

@{
    # Script module or binary module file associated with this manifest.
    RootModule = '../../llm-env.psm1'

    # Version number of this module.
    ModuleVersion = '1.1.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    # ID used to uniquely identify this module
    GUID = '12345678-1234-5678-9abc-123456789012'

    # Author of this module
    Author = 'Sam Estrin'

    # Company or vendor of this module
    CompanyName = 'Open Source'

    # Copyright statement for this module
    Copyright = '(c) 2024 Sam Estrin. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'PowerShell module for managing LLM environment variables and provider configurations. Provides full feature parity with the bash version while integrating seamlessly with Windows environments.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Name of the PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    DotNetFrameworkVersion = '4.5'

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # ClrVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        # Main cmdlets
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
        'Disable-LLMProvider',
        
        # Essential library functions needed by cmdlets
        'Get-LLMConfiguration',
        'Get-LLMConfigDirectory',
        'Get-LLMConfigFilePath',
        'Get-LLMProvider',
        'Get-LLMEnvironmentVariable',
        'Set-LLMEnvironmentVariable',
        'Clear-LLMConfigurationCache',
        'New-LLMConfiguration',
        'Get-LLMConfigSearchPaths',
        'Test-LLMProviderData',
        'ConvertTo-LLMProvider',
        'ConvertTo-LLMConfiguration',
        'ConvertFrom-IniFile'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @(
        'llm-set',
        'llm-unset', 
        'llm-list',
        'llm-show'
    )

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('LLM', 'Environment', 'Configuration', 'AI', 'OpenAI', 'Anthropic', 'Provider')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/samestrin/llm-env/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/samestrin/llm-env'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = 'PowerShell port with full feature parity to bash version. Supports cross-platform operation and seamless Windows integration.'

            # Prerelease string of this module
            # Prerelease = ''

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            # RequireLicenseAcceptance = $false

            # External dependent modules of this module
            # ExternalModuleDependencies = @()

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}