<#
.SYNOPSIS
    Check if the local TSG index is up to date.
.DESCRIPTION
    Checks when the local index was last updated and warns if it's stale.
    Helps ensure you're searching against current troubleshooting documentation.
.PARAMETER DaysStale
    Number of days before the index is considered stale. Default is 7 days.
.PARAMETER Quiet
    Suppress output and only return true/false.
.EXAMPLE
    Test-AzLocalTSGIndexFreshness
    Checks if index is fresh and displays a warning if stale.
.EXAMPLE
    Test-AzLocalTSGIndexFreshness -DaysStale 14
    Use a 14-day threshold for staleness.
.EXAMPLE
    if (-not (Test-AzLocalTSGIndexFreshness -Quiet)) {
        Update-AzLocalTSGIndex
    }
    Silently check and update if stale.
#>
function Test-AzLocalTSGIndexFreshness {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter()]
        [int]$DaysStale = 7,

        [Parameter()]
        [switch]$Quiet
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    try {
        $cacheRoot = Get-CacheRoot
        $indexPath = Join-Path $cacheRoot 'index.json'

        # Check if index exists
        if (-not (Test-Path $indexPath)) {
            if (-not $Quiet) {
                Write-Host ""
                Write-Host "⚠️  No local index found." -ForegroundColor Yellow
                Write-Host "   Run 'Update-AzLocalTSGIndex' to download the latest TSG documents." -ForegroundColor Gray
                Write-Host ""
            }
            return $false
        }

        # Get last modified time
        $indexFile = Get-Item $indexPath
        $lastUpdated = $indexFile.LastWriteTime
        $age = (Get-Date) - $lastUpdated
        $daysOld = [Math]::Floor($age.TotalDays)

        # Check if stale
        $isStale = $age.TotalDays -gt $DaysStale

        if (-not $Quiet) {
            Write-Host ""
            if ($isStale) {
                Write-Host "⚠️  Your TSG index is $daysOld days old (last updated: $($lastUpdated.ToString('yyyy-MM-dd HH:mm')))" -ForegroundColor Yellow
                Write-Host "   Run 'Update-AzLocalTSGIndex' to refresh with the latest documentation." -ForegroundColor Gray
                Write-Host ""
            } else {
                Write-Host "✓ TSG index is up to date ($daysOld days old, last updated: $($lastUpdated.ToString('yyyy-MM-dd HH:mm')))" -ForegroundColor Green
                Write-Host ""
            }
        }

        return -not $isStale

    } catch {
        if (-not $Quiet) {
            Write-Warning "Failed to check index freshness: $_"
        }
        return $false
    }
}
