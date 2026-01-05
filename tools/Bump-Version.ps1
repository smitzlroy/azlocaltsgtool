<#
.SYNOPSIS
    Bump the module version in the manifest.
.DESCRIPTION
    Increments the patch version by default. Supports -Major, -Minor, or -Patch switches.
.PARAMETER Major
    Increment the major version (x.0.0).
.PARAMETER Minor
    Increment the minor version (0.x.0).
.PARAMETER Patch
    Increment the patch version (0.0.x). This is the default.
#>
[CmdletBinding()]
param(
    [switch]$Major,
    [switch]$Minor,
    [switch]$Patch
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path $PSScriptRoot -Parent
$manifestPath = Join-Path $repoRoot 'src' 'AzLocalTSGTool' 'AzLocalTSGTool.psd1'

if (-not (Test-Path $manifestPath)) {
    Write-Error "Manifest not found at: $manifestPath"
    exit 1
}

# Read current version
$manifest = Import-PowerShellDataFile -Path $manifestPath
$currentVersion = [version]$manifest.ModuleVersion

# Determine which component to bump (default to Patch)
if (-not $Major -and -not $Minor -and -not $Patch) {
    $Patch = $true
}

if ($Major) {
    $newVersion = [version]::new($currentVersion.Major + 1, 0, 0)
}
elseif ($Minor) {
    $newVersion = [version]::new($currentVersion.Major, $currentVersion.Minor + 1, 0)
}
else {
    $newVersion = [version]::new($currentVersion.Major, $currentVersion.Minor, $currentVersion.Build + 1)
}

Write-Host "Bumping version: $currentVersion → $newVersion" -ForegroundColor Cyan

# Update manifest file
$content = Get-Content -Path $manifestPath -Raw
$content = $content -replace "ModuleVersion\s*=\s*'[^']*'", "ModuleVersion = '$newVersion'"
Set-Content -Path $manifestPath -Value $content -NoNewline

Write-Host "✓ Updated $manifestPath" -ForegroundColor Green
