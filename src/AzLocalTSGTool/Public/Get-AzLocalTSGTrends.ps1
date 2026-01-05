<#
.SYNOPSIS
    Get search analytics and trends for Azure Local TSG searches.

.DESCRIPTION
    Displays analytics about your TSG searches including:
    - Total searches and success rate
    - Most frequently searched errors
    - Most commonly matched TSGs
    - Potential documentation gaps (searches with no/poor results)

.PARAMETER DaysBack
    Number of days to look back for analytics. Default is 30 days.

.PARAMETER ExportPath
    Optional path to export analytics as JSON.

.EXAMPLE
    Get-AzLocalTSGTrends
    Shows analytics for the last 30 days.

.EXAMPLE
    Get-AzLocalTSGTrends -DaysBack 7
    Shows analytics for the last 7 days.

.EXAMPLE
    Get-AzLocalTSGTrends -DaysBack 90 -ExportPath ".\analytics-report.json"
    Shows 90-day analytics and exports to JSON file.

.NOTES
    Analytics are collected automatically when you use Get-AzLocalTSGFix.
    Data is stored locally and never leaves your machine.
#>
function Get-AzLocalTSGTrends {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateRange(1, 365)]
        [int]$DaysBack = 30,

        [Parameter()]
        [string]$ExportPath
    )

    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Azure Local TSG Search Analytics" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    $analytics = Get-SearchAnalytics -DaysBack $DaysBack

    if (-not $analytics) {
        return
    }

    # Overview
    Write-Host "📊 Overview (Last $DaysBack days)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Total Searches:        $($analytics.TotalSearches)" -ForegroundColor White
    Write-Host "  No Results:            $($analytics.NoResultsCount) ($($analytics.NoResultsPercentage)%)" -ForegroundColor $(if ($analytics.NoResultsPercentage -gt 30) { 'Red' } else { 'White' })
    Write-Host "  Low Confidence (<20%): $($analytics.LowConfidenceCount)" -ForegroundColor White
    Write-Host ""

    # Top Errors
    if ($analytics.TopErrors -and $analytics.TopErrors.Count -gt 0) {
        Write-Host "🔥 Top Searched Errors" -ForegroundColor Yellow
        Write-Host ""
        foreach ($error in $analytics.TopErrors) {
            $bar = "█" * [Math]::Max(1, [Math]::Floor($error.Percentage / 2))
            Write-Host "  $bar $($error.Percentage)% " -ForegroundColor Green -NoNewline
            Write-Host "($($error.Count)x)" -ForegroundColor DarkGray -NoNewline
            Write-Host " $($error.ErrorText.Substring(0, [Math]::Min(70, $error.ErrorText.Length)))" -ForegroundColor White
        }
        Write-Host ""
    }

    # Top TSGs
    if ($analytics.TopMatchedTSGs -and $analytics.TopMatchedTSGs.Count -gt 0) {
        Write-Host "📖 Most Matched TSGs" -ForegroundColor Yellow
        Write-Host ""
        foreach ($tsg in $analytics.TopMatchedTSGs) {
            Write-Host "  • " -ForegroundColor Cyan -NoNewline
            Write-Host "$($tsg.TSG) " -ForegroundColor White -NoNewline
            Write-Host "($($tsg.MatchCount)x, avg $($tsg.AvgConfidence)% confidence)" -ForegroundColor DarkGray
        }
        Write-Host ""
    }

    # Gaps
    if ($analytics.PotentialGaps -and $analytics.PotentialGaps.Count -gt 0) {
        Write-Host "❗ Potential Documentation Gaps" -ForegroundColor Yellow
        Write-Host "   (Errors with no/poor matches - consider reporting to Microsoft)" -ForegroundColor DarkGray
        Write-Host ""
        foreach ($gap in $analytics.PotentialGaps) {
            Write-Host "  • " -ForegroundColor Red -NoNewline
            Write-Host "$($gap.ErrorText.Substring(0, [Math]::Min(70, $gap.ErrorText.Length))) " -ForegroundColor White -NoNewline
            Write-Host "($($gap.SearchCount)x searches" -ForegroundColor DarkGray -NoNewline
            if ($gap.BestConfidence -gt 0) {
                Write-Host ", best match: $($gap.BestConfidence)%)" -ForegroundColor DarkGray
            } else {
                Write-Host ", no matches)" -ForegroundColor DarkGray
            }
        }
        Write-Host ""
    }

    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "💡 Tip: Share documentation gaps with Microsoft via GitHub Issues" -ForegroundColor Gray
    Write-Host "   https://github.com/Azure/AzureLocal-Supportability/issues/new" -ForegroundColor Gray
    Write-Host ""

    # Export if requested
    if ($ExportPath) {
        $analytics | ConvertTo-Json -Depth 10 | Set-Content -Path $ExportPath -Force
        Write-Host "✓ Analytics exported to: $ExportPath" -ForegroundColor Green
        Write-Host ""
    }

    # Return the analytics object for programmatic use
    return $analytics
}
