<#
.SYNOPSIS
    Build the AzLocalTSGTool module for distribution.
.DESCRIPTION
    Packages the module from src/ into out/ ready for installation or release.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path $PSScriptRoot -Parent
$srcPath = Join-Path $repoRoot 'src' 'AzLocalTSGTool'
$outPath = Join-Path $repoRoot 'out' 'AzLocalTSGTool'

Write-Host "==> Building AzLocalTSGTool module..." -ForegroundColor Cyan

# Clean and create output directory
if (Test-Path $outPath) {
    Write-Host "  → Cleaning existing output..." -ForegroundColor Yellow
    Remove-Item -Path $outPath -Recurse -Force
}
New-Item -Path $outPath -ItemType Directory -Force | Out-Null

# Copy module files
Write-Host "  → Copying module files..." -ForegroundColor Yellow
Copy-Item -Path "$srcPath\*" -Destination $outPath -Recurse -Force

# Read version from manifest
$manifestPath = Join-Path $outPath 'AzLocalTSGTool.psd1'
$manifest = Import-PowerShellDataFile -Path $manifestPath
$version = $manifest.ModuleVersion

Write-Host ""
Write-Host "==> Build complete!" -ForegroundColor Green
Write-Host "  Version: $version" -ForegroundColor Gray
Write-Host "  Output:  $outPath" -ForegroundColor Gray
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Cyan
Write-Host "  - Run 'InstallLocal' task to install locally" -ForegroundColor Gray
Write-Host "  - Or create a release: git tag -a v$version -m 'Release v$version' && git push origin v$version" -ForegroundColor Gray
