#Requires -Version 7.0

<#
.SYNOPSIS
    AzLocalTSGTool module root.
.DESCRIPTION
    Loads public and private functions for the AzLocalTSGTool module.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Get module root
$ModuleRoot = $PSScriptRoot

# Import private functions
$PrivatePath = Join-Path $ModuleRoot 'Private'
if (Test-Path $PrivatePath) {
    Get-ChildItem -Path $PrivatePath -Filter '*.ps1' -Recurse | ForEach-Object {
        . $_.FullName
    }
}

# Import public functions
$PublicPath = Join-Path $ModuleRoot 'Public'
if (Test-Path $PublicPath) {
    Get-ChildItem -Path $PublicPath -Filter '*.ps1' -Recurse | ForEach-Object {
        . $_.FullName
    }
}

# Export public functions (defined in manifest)
Export-ModuleMember -Function 'Get-AzLocalTSGFix', 'Update-AzLocalTSGIndex', 'Get-AzLocalTSGTrends'
