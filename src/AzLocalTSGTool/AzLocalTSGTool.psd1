@{
    RootModule        = 'AzLocalTSGTool.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '7a3e5c8f-9d1b-4e2a-8f7c-6b5d4a3e2f1c'
    Author            = 'AzLocalTSGTool Contributors'
    CompanyName       = 'Community'
    Copyright         = '(c) 2026 AzLocalTSGTool Contributors. All rights reserved.'
    Description       = 'PowerShell module for troubleshooting Azure Local and AKS enabled by Azure Arc issues. Searches known issues and fixes from Azure DevOps Wiki TSG pages and GitHub supportability content.'
    PowerShellVersion = '7.0'
    
    FunctionsToExport = @(
        'Get-AzLocalTSGFix'
        'Update-AzLocalTSGIndex'
    )
    
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    
    PrivateData       = @{
        PSData = @{
            Tags         = @('Azure', 'AzureLocal', 'AKS', 'AzureArc', 'Troubleshooting', 'TSG', 'Supportability')
            LicenseUri   = 'https://github.com/smitzlroy/azlocaltsgtool/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/smitzlroy/azlocaltsgtool'
            ReleaseNotes = 'See CHANGELOG.md for release notes.'
        }
    }
}
