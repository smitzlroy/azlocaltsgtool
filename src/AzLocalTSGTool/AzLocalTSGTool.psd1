@{
    RootModule        = 'AzLocalTSGTool.psm1'
    ModuleVersion     = '0.3.1'
    GUID              = '7a3e5c8f-9d1b-4e2a-8f7c-6b5d4a3e2f1c'
    Author            = 'AzLocalTSGTool Contributors'
    CompanyName       = 'Community'
    Copyright         = '(c) 2026 AzLocalTSGTool Contributors. All rights reserved.'
    Description       = 'PowerShell module for troubleshooting Azure Local and AKS enabled by Azure Arc issues. Searches known issues and fixes from GitHub supportability content.'
    PowerShellVersion = '7.0'
    
    FunctionsToExport = @(
        'Get-AzLocalTSGFix'
        'Update-AzLocalTSGIndex'
        'Get-AzLocalTSGTrends'
        'Test-AzLocalTSGIndexFreshness'
    )
    
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    
    PrivateData       = @{
        PSData = @{
            Tags         = @('Azure', 'AzureLocal', 'AKS', 'AzureArc', 'Troubleshooting', 'TSG', 'Supportability')
            LicenseUri   = 'https://github.com/smitzlroy/azlocaltsgtool/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/smitzlroy/azlocaltsgtool'
            ReleaseNotes = 'v0.3.1: Added index freshness checking. Module now warns on import if TSG index is stale (>7 days old). Use Test-AzLocalTSGIndexFreshness to manually check.'
        }
    }
}
