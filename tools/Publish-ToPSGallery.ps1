<#
.SYNOPSIS
    Publish AzLocalTSGTool module to PowerShell Gallery.
.DESCRIPTION
    Publishes the built module from /out to PowerShell Gallery.
    Requires a PSGallery API key set in $env:PSGALLERY_API_KEY.
.PARAMETER WhatIf
    Show what would be published without actually publishing.
.EXAMPLE
    $env:PSGALLERY_API_KEY = "your-api-key-here"
    .\tools\Publish-ToPSGallery.ps1
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path $PSScriptRoot -Parent
$modulePath = Join-Path $repoRoot 'out' 'AzLocalTSGTool'

Write-Host "==> Publishing AzLocalTSGTool to PowerShell Gallery..." -ForegroundColor Cyan
Write-Host ""

# Verify module is built
if (-not (Test-Path $modulePath)) {
    Write-Error "Module not found at $modulePath. Run Build.ps1 first."
    exit 1
}

# Verify API key
$apiKey = $env:PSGALLERY_API_KEY
if (-not $apiKey) {
    Write-Error "PSGALLERY_API_KEY environment variable not set."
    Write-Host ""
    Write-Host "To publish, you need a PowerShell Gallery API key:" -ForegroundColor Yellow
    Write-Host "  1. Go to https://www.powershellgallery.com" -ForegroundColor Gray
    Write-Host "  2. Sign in with Microsoft account" -ForegroundColor Gray
    Write-Host "  3. Navigate to API Keys section" -ForegroundColor Gray
    Write-Host "  4. Create a new API key" -ForegroundColor Gray
    Write-Host "  5. Set: `$env:PSGALLERY_API_KEY = 'your-key-here'" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

# Read version from manifest
$manifestPath = Join-Path $modulePath 'AzLocalTSGTool.psd1'
$manifest = Import-PowerShellDataFile -Path $manifestPath
$version = $manifest.ModuleVersion

Write-Host "  → Module path: $modulePath" -ForegroundColor Gray
Write-Host "  → Version: $version" -ForegroundColor Gray
Write-Host ""

# Check if version already exists
try {
    $existingModule = Find-Module -Name AzLocalTSGTool -RequiredVersion $version -ErrorAction SilentlyContinue
    if ($existingModule) {
        Write-Error "Version $version already exists in PowerShell Gallery. Bump version first using Bump-Version.ps1"
        exit 1
    }
} catch {
    # Version doesn't exist, which is good
}

# Publish
if ($WhatIf) {
    Write-Host "==> WhatIf: Would publish version $version" -ForegroundColor Yellow
    Write-Host ""
} else {
    if ($PSCmdlet.ShouldProcess("AzLocalTSGTool v$version", "Publish to PowerShell Gallery")) {
        Write-Host "  → Publishing to PSGallery..." -ForegroundColor Yellow
        
        try {
            Publish-Module -Path $modulePath -NuGetApiKey $apiKey -Repository PSGallery -Verbose
            
            Write-Host ""
            Write-Host "==> Successfully published!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Module will be available shortly at:" -ForegroundColor Cyan
            Write-Host "  https://www.powershellgallery.com/packages/AzLocalTSGTool/$version" -ForegroundColor Gray
            Write-Host ""
            Write-Host "Users can now install with:" -ForegroundColor Cyan
            Write-Host "  Install-Module -Name AzLocalTSGTool -Repository PSGallery" -ForegroundColor Gray
            Write-Host ""
        } catch {
            Write-Error "Failed to publish: $_"
            exit 1
        }
    }
}
