<#
.SYNOPSIS
    Bootstrap the development environment by installing required dependencies.
.DESCRIPTION
    Installs Pester and PSScriptAnalyzer modules if they are not already present.
    Installs to CurrentUser scope to avoid requiring admin privileges.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "==> Bootstrapping AzLocalTSGTool development environment..." -ForegroundColor Cyan

# Required modules
$requiredModules = @(
    @{ Name = 'Pester'; MinVersion = '5.3.0' }
    @{ Name = 'PSScriptAnalyzer'; MinVersion = '1.21.0' }
)

foreach ($module in $requiredModules) {
    $installed = Get-Module -ListAvailable -Name $module.Name | 
    Where-Object { $_.Version -ge [version]$module.MinVersion } |
    Select-Object -First 1

    if ($installed) {
        Write-Host "  ✓ $($module.Name) $($installed.Version) already installed" -ForegroundColor Green
    } else {
        Write-Host "  → Installing $($module.Name) >= $($module.MinVersion)..." -ForegroundColor Yellow
        try {
            Install-Module -Name $module.Name -MinimumVersion $module.MinVersion -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck
            Write-Host "  ✓ $($module.Name) installed successfully" -ForegroundColor Green
        } catch {
            Write-Error "Failed to install $($module.Name): $_"
            exit 1
        }
    }
}

Write-Host ""
Write-Host "==> Bootstrap complete! You can now:" -ForegroundColor Green
Write-Host "  - Run 'Lint' task to check code quality" -ForegroundColor Gray
Write-Host "  - Run 'Test' task to execute Pester tests" -ForegroundColor Gray
Write-Host "  - Run 'Build' task to package the module" -ForegroundColor Gray
Write-Host "  - Run 'InstallLocal' task to install to your user profile" -ForegroundColor Gray
