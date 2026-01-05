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
        [switch]$UpdateCache,

        [Parameter()]
        [switch]$Json
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    # Update cache if requested
    if ($UpdateCache) {
        Write-Host "==> Updating index..." -ForegroundColor Cyan
        Update-AzLocalTSGIndex -Force:$Force
        Write-Host ""
    }

    # Read input
    $inputText = if ($PSCmdlet.ParameterSetName -eq 'File') {
        Read-LogInput -Path $Path
    } else {
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
        Write-Host "  Update-AzLocalTSGIndex" -ForegroundColor Gray
        return
    }

    Write-Verbose "Searching $($indexEntries.Count) indexed documents..."

    # Score and rank candidates
    $results = @(Invoke-ScoreCandidates -QueryTokens $queryTokens -IndexEntries $indexEntries -Top $Top)

    if ($results.Count -eq 0) {
        Write-Warning "No matching issues found."
        Write-Host ""
        Write-Host "Suggestions:" -ForegroundColor Cyan
        Write-Host "  - Try different keywords or error codes" -ForegroundColor Gray
        Write-Host "  - Update the index: Update-AzLocalTSGIndex -Force" -ForegroundColor Gray
        return
    }

    # Output results
    if ($Json) {
        return $results | ConvertTo-Json -Depth 10
    } else {
        Write-Host ""
        Write-Host "==> Found $($results.Count) matching issue(s):" -ForegroundColor Green
        Write-Host ""

        for ($i = 0; $i -lt $results.Count; $i++) {
            $result = $results[$i]
            $rank = $i + 1

            Write-Host "[$rank] " -NoNewline -ForegroundColor Cyan
            Write-Host $result.Title -ForegroundColor White
            Write-Host "    Confidence: $($result.Confidence)%" -ForegroundColor $(if ($result.Confidence -ge 70) { 'Green' } elseif ($result.Confidence -ge 40) { 'Yellow' } else { 'Red' })
            Write-Host "    Match:      $($result.MatchReason)" -ForegroundColor Gray

            if ($result.FixSummary) {
                Write-Host ""
                Write-Host "    Summary:" -ForegroundColor Yellow
                Write-Host "    $($result.FixSummary)" -ForegroundColor Gray
            }

            if ($result.FixSteps -and $result.FixSteps.Count -gt 0) {
                Write-Host ""
                Write-Host "    Fix Steps:" -ForegroundColor Yellow
                Write-Host "    ==========" -ForegroundColor Yellow
                
                $stepsToShow = [Math]::Min(5, $result.FixSteps.Count)
                for ($j = 0; $j -lt $stepsToShow; $j++) {
                    $step = $result.FixSteps[$j]
                    
                    if ($step.Type -eq 'Code') {
                        Write-Host ""
                        Write-Host "    Step $($step.Number): Run this PowerShell code" -ForegroundColor Cyan
                        Write-Host ("    " + ("-" * 60)) -ForegroundColor DarkGray
                        
                        # Display code with proper formatting
                        $codeLines = $step.Content -split "`n"
                        $linesToShow = [Math]::Min(15, $codeLines.Count)
                        
                        for ($k = 0; $k -lt $linesToShow; $k++) {
                            Write-Host "    $($codeLines[$k])" -ForegroundColor White
                        }
                        
                        if ($codeLines.Count -gt 15) {
                            Write-Host "    ... ($($codeLines.Count - 15) more lines)" -ForegroundColor DarkGray
                        }
                        Write-Host ("    " + ("-" * 60)) -ForegroundColor DarkGray
                    } elseif ($step.Type -eq 'Text') {
                        Write-Host ""
                        Write-Host "    Step $($step.Number): $($step.Content)" -ForegroundColor White
                    }
                }
                
                if ($result.FixSteps.Count -gt 5) {
                    Write-Host ""
                    Write-Host "    ... ($($result.FixSteps.Count - 5) more steps - see full TSG)" -ForegroundColor DarkGray
                }
            }

            Write-Host ""
            Write-Host "    Full TSG: " -NoNewline -ForegroundColor Cyan
            Write-Host $result.Url -ForegroundColor Blue
            Write-Host ""
            Write-Host "    " + ("=" * 80) -ForegroundColor DarkGray
            Write-Host ""
        }

        Write-Host "==> Action Required:" -ForegroundColor Yellow
        Write-Host "  1. Review the fix steps above (start with highest confidence match)" -ForegroundColor Gray
        Write-Host "  2. Copy and run the PowerShell code blocks in order" -ForegroundColor Gray
        Write-Host "  3. For complete details, open the 'Full TSG' link" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Tip: Use -Top 5 to see more results, or refine your error text for better matches" -ForegroundColor DarkGray
        Write-Host ""

        # Return nothing to avoid duplicate output
        return
    }
}
