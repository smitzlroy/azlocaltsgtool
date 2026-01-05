<#
.SYNOPSIS
    Install the built module to the CurrentUser scope for local testing.
.DESCRIPTION
    Installs the module from out/ to the user's PowerShell module path.
    This allows immediate testing without publishing to a repository.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path $PSScriptRoot -Parent
$outPath = Join-Path $repoRoot 'out' 'AzLocalTSGTool'

Write-Host "==> Installing AzLocalTSGTool to CurrentUser scope..." -ForegroundColor Cyan

# Verify build output exists
if (-not (Test-Path $outPath)) {
    Write-Error "Build output not found at: $outPath`nRun 'Build' task first."
    exit 1
}

# Find CurrentUser module path
$userModulePath = $env:PSModulePath -split [IO.Path]::PathSeparator | 
    Where-Object { $_ -like "*$env:USERNAME*" -or $_ -like "*Documents*" } | 
    Select-Object -First 1

if (-not $userModulePath) {
    Write-Error "Could not find CurrentUser module path in PSModulePath"
    exit 1
}

$targetPath = Join-Path $userModulePath 'AzLocalTSGTool'

# Remove existing installation
if (Test-Path $targetPath) {
    Write-Host "  → Removing existing installation..." -ForegroundColor Yellow
    Remove-Item -Path $targetPath -Recurse -Force
}

# Copy module
Write-Host "  → Copying module to $targetPath..." -ForegroundColor Yellow
Copy-Item -Path $outPath -Destination $targetPath -Recurse -Force

# Read version
$manifestPath = Join-Path $targetPath 'AzLocalTSGTool.psd1'
$manifest = Import-PowerShellDataFile -Path $manifestPath
$version = $manifest.ModuleVersion

Write-Host ""
Write-Host "==> Installation complete!" -ForegroundColor Green
Write-Host "  Version: $version" -ForegroundColor Gray
Write-Host "  Path:    $targetPath" -ForegroundColor Gray
Write-Host ""
Write-Host "  Try it now:" -ForegroundColor Cyan
Write-Host "    Import-Module AzLocalTSGTool -Force" -ForegroundColor Gray
Write-Host "    Get-Command -Module AzLocalTSGTool" -ForegroundColor Gray
