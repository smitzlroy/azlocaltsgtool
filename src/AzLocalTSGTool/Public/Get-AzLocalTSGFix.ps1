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

    # Record analytics
    $topMatch = if ($results.Count -gt 0) { $results[0].Title } else { $null }
    $topConfidence = if ($results.Count -gt 0) { $results[0].Confidence } else { 0 }
    Add-SearchAnalytics -ErrorText $ErrorText -ResultCount $results.Count -TopMatch $topMatch -TopConfidence $topConfidence

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
        Write-Host "Found $($results.Count) potential fix(es)" -ForegroundColor Green
        Write-Host ""

        for ($i = 0; $i -lt $results.Count; $i++) {
            $result = $results[$i]
            $rank = $i + 1

            # Simple header
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
            Write-Host "FIX #$rank" -ForegroundColor Cyan -NoNewline
            Write-Host " - $($result.Title)" -ForegroundColor White
            
            # Traffic light system for match confidence
            $matchColor = 'Red'
            if ($rank -eq 1) {
                $matchColor = 'Green'  # Best match
            } elseif ($rank -eq 2) {
                $matchColor = 'Yellow'  # Second best
            }
            # Third and beyond stay Red
            
            Write-Host "Match: " -ForegroundColor Gray -NoNewline
            Write-Host "$($result.Confidence)%" -ForegroundColor $matchColor
            Write-Host ""
            
            # Show clickable URL first
            $esc = [char]27
            $url = $result.Url
            $clickableUrl = "$esc]8;;$url$esc\Full guide: $url$esc]8;;$esc\"
            Write-Host $clickableUrl -ForegroundColor Cyan
            
            # Show brief summary if available
            if ($result.FixSummary) {
                Write-Host ""
                Write-Host "$($result.FixSummary)" -ForegroundColor Gray
            }
            Write-Host ""

            # Show fix steps if available
            if ($result.FixSteps -and $result.FixSteps.Count -gt 0) {
                
                # Show ALL steps completely
                foreach ($step in $result.FixSteps) {
                    
                    if ($step.Type -eq 'Code') {
                        Write-Host "STEP $($step.Number): Run these commands" -ForegroundColor Yellow
                        Write-Host ""
                        
                        # Show all commands with bullet points
                        $codeLines = $step.Content -split "`n"
                        
                        foreach ($line in $codeLines) {
                            if ($line.Trim() -ne '') {
                                Write-Host "  • $line" -ForegroundColor White
                            }
                        }
                        Write-Host ""
                    } elseif ($step.Type -eq 'Text') {
                        Write-Host "STEP $($step.Number): " -ForegroundColor Yellow -NoNewline
                        Write-Host "$($step.Content)" -ForegroundColor White
                        Write-Host ""
                    }
                }
            } else {
                Write-Host "No automated fix steps found." -ForegroundColor DarkGray
                Write-Host "See full guide above for manual troubleshooting." -ForegroundColor DarkGray
                Write-Host ""
            }
        }

        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "💡 Tip: Copy each step and run it in PowerShell | Use -Top 5 for more results" -ForegroundColor Gray
        Write-Host ""

        # Return nothing to avoid duplicate output
        return
    }
}
