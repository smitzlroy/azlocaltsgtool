<#
.SYNOPSIS
    Find known issues and fixes for Azure Local and AKS Arc errors.
.DESCRIPTION
    Searches the local TSG index for matching known issues and fixes.
    Accepts error messages directly or from log files.
.PARAMETER ErrorText
    Error message text to search for.
.PARAMETER Path
    Path to a log file containing errors.
.PARAMETER Top
    Number of top results to return (default: 5).
.PARAMETER Source
    Filter results by source: GitHub, AzureDevOpsWiki, or All (default: All).
.PARAMETER UpdateCache
    Update the index before searching.
.PARAMETER Json
    Output results as JSON.
.EXAMPLE
    Get-AzLocalTSGFix -ErrorText "Microsoft.Health.FaultType.Cluster.ValidationReport.Failed"
    Searches for fixes related to cluster validation failures.
.EXAMPLE
    Get-AzLocalTSGFix -Path ".\deployment.log" -Top 3 -UpdateCache
    Searches the log file contents and updates cache first.
.EXAMPLE
    Get-AzLocalTSGFix -ErrorText "AKS node NotReady" -Json | Out-File results.json
    Outputs results as JSON to a file.
#>
function Get-AzLocalTSGFix {
    [CmdletBinding(DefaultParameterSetName = 'Text')]
    param(
        [Parameter(ParameterSetName = 'Text', Mandatory, Position = 0)]
        [string]$ErrorText,

        [Parameter(ParameterSetName = 'File', Mandatory)]
        [string]$Path,

        [Parameter()]
        [int]$Top = 5,

        [Parameter()]
        [ValidateSet('GitHub', 'AzureDevOpsWiki', 'All')]
        [string]$Source = 'All',

        [Parameter()]
        [switch]$UpdateCache,

        [Parameter()]
        [switch]$Json
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    # Update cache if requested
    if ($UpdateCache) {
        Write-Host "==> Updating index..." -ForegroundColor Cyan
        Update-AzLocalTSGIndex -Source $Source
        Write-Host ""
    }

    # Read input
    $inputText = if ($PSCmdlet.ParameterSetName -eq 'File') {
        Read-LogInput -Path $Path
    }
    else {
        Read-LogInput -ErrorText $ErrorText
    }

    Write-Verbose "Input text length: $($inputText.Length) characters"

    # Normalize input to tokens
    $queryTokens = ConvertTo-NormalizedTokens -InputText $inputText
    Write-Verbose "Query tokens: $($queryTokens -join ', ')"

    if ($queryTokens.Count -eq 0) {
        Write-Warning "No meaningful tokens extracted from input. Try providing more specific error details."
        return
    }

    # Load index
    Write-Verbose "Loading index..."
    $indexEntries = Load-Index

    if ($indexEntries.Count -eq 0) {
        Write-Warning "Index is empty. Run 'Update-AzLocalTSGIndex' first to build the index."
        Write-Host ""
        Write-Host "Quick start:" -ForegroundColor Cyan
        Write-Host "  Update-AzLocalTSGIndex -Source GitHub" -ForegroundColor Gray
        return
    }

    # Filter by source if specified
    if ($Source -ne 'All') {
        $indexEntries = $indexEntries | Where-Object { $_.Source -eq $Source }
        if ($indexEntries.Count -eq 0) {
            Write-Warning "No documents found for source: $Source"
            return
        }
    }

    Write-Verbose "Searching $($indexEntries.Count) indexed documents..."

    # Score and rank candidates
    $results = Invoke-ScoreCandidates -QueryTokens $queryTokens -IndexEntries $indexEntries -Top $Top

    if ($results.Count -eq 0) {
        Write-Warning "No matching issues found."
        Write-Host ""
        Write-Host "Suggestions:" -ForegroundColor Cyan
        Write-Host "  - Try different keywords or error codes" -ForegroundColor Gray
        Write-Host "  - Update the index: Update-AzLocalTSGIndex -Force" -ForegroundColor Gray
        Write-Host "  - Check if AZDO_PAT is set for Azure DevOps Wiki content" -ForegroundColor Gray
        return
    }

    # Output results
    if ($Json) {
        return $results | ConvertTo-Json -Depth 10
    }
    else {
        Write-Host ""
        Write-Host "==> Found $($results.Count) matching issue(s):" -ForegroundColor Green
        Write-Host ""

        for ($i = 0; $i -lt $results.Count; $i++) {
            $result = $results[$i]
            $rank = $i + 1

            Write-Host "[$rank] " -NoNewline -ForegroundColor Cyan
            Write-Host $result.Title -ForegroundColor White
            Write-Host "    Source:     $($result.Source)" -ForegroundColor Gray
            Write-Host "    Confidence: $($result.Confidence)%" -ForegroundColor $(if ($result.Confidence -ge 70) { 'Green' } elseif ($result.Confidence -ge 40) { 'Yellow' } else { 'Red' })
            Write-Host "    Match:      $($result.MatchReason)" -ForegroundColor Gray
            Write-Host "    URL:        $($result.Url)" -ForegroundColor Cyan

            if ($result.FixSummary) {
                Write-Host "    Fix:        $($result.FixSummary)" -ForegroundColor Yellow
            }

            if ($result.FixSteps -and $result.FixSteps.Count -gt 0) {
                Write-Host "    Steps:" -ForegroundColor Yellow
                $stepsToShow = [Math]::Min(3, $result.FixSteps.Count)
                for ($j = 0; $j -lt $stepsToShow; $j++) {
                    Write-Host "      $($j + 1). $($result.FixSteps[$j])" -ForegroundColor Gray
                }
                if ($result.FixSteps.Count -gt 3) {
                    Write-Host "      ... ($($result.FixSteps.Count - 3) more steps, see URL)" -ForegroundColor DarkGray
                }
            }

            Write-Host ""
        }

        return $results
    }
}
