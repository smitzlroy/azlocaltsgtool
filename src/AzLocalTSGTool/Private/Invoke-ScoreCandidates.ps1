<#
.SYNOPSIS
    Score and rank candidate documents against query tokens.
#>

function Invoke-ScoreCandidates {
    <#
    .SYNOPSIS
        Score index entries against query tokens and return ranked results.
    .PARAMETER QueryTokens
        Array of normalized query tokens.
    .PARAMETER IndexEntries
        Array of index entries to score.
    .PARAMETER Top
        Number of top results to return.
    .OUTPUTS
        Array of scored results with confidence and match explanation.
    #>
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [Parameter(Mandatory)]
        [string[]]$QueryTokens,

        [Parameter(Mandatory)]
        [array]$IndexEntries,

        [Parameter()]
        [int]$Top = 5
    )

    if ($QueryTokens.Count -eq 0) {
        Write-Warning "No query tokens provided for scoring."
        return @()
    }

    if ($IndexEntries.Count -eq 0) {
        Write-Warning "No index entries to score."
        return @()
    }

    $scoredResults = @()

    foreach ($entry in $IndexEntries) {
        $score = 0.0
        $matchedTokens = @()
        $matchReasons = @()

        # High-value: exact substring match in full content (especially dot-delimited identifiers)
        foreach ($token in $QueryTokens) {
            if ($token -like '*.*' -and $entry.Content -like "*$token*") {
                $score += 10.0
                $matchedTokens += $token
                $matchReasons += "Exact identifier match: $token"
            }
        }

        # Medium-value: token overlap (Jaccard)
        $entryTokens = $entry.Tokens
        if ($entryTokens) {
            $intersection = @($QueryTokens | Where-Object { $_ -in $entryTokens })
            $union = @(($QueryTokens + $entryTokens) | Select-Object -Unique)
            
            if ($union.Count -gt 0) {
                $jaccard = $intersection.Count / $union.Count
                $score += $jaccard * 5.0
                
                if ($intersection.Count -gt 0) {
                    $matchedTokens += $intersection
                    $matchReasons += "Token overlap: $($intersection.Count)/$($QueryTokens.Count) query tokens matched"
                }
            }
        }

        # Lower-value: fuzzy match on title
        if ($entry.Title) {
            $queryString = $QueryTokens -join ' '
            $fuzzyScore = Invoke-FuzzyScore -String1 $queryString -String2 $entry.Title.ToLowerInvariant()
            
            if ($fuzzyScore -gt 0.6) {
                $score += $fuzzyScore * 2.0
                $matchReasons += "Fuzzy title match: $([math]::Round($fuzzyScore * 100))%"
            }
        }

        # Only include candidates with non-zero score
        if ($score -gt 0) {
            $confidence = [math]::Min(100, [math]::Round($score * 10))
            
            $scoredResults += [PSCustomObject]@{
                Title         = $entry.Title
                Source        = $entry.Source
                Url           = $entry.Url
                Confidence    = $confidence
                MatchedTokens = ($matchedTokens | Select-Object -Unique) -join ', '
                MatchReason   = $matchReasons -join ' | '
                FixSummary    = $entry.FixSummary
                FixSteps      = $entry.FixSteps
                Snippet       = if ($entry.Content.Length -gt 300) { $entry.Content.Substring(0, 300) + '...' } else { $entry.Content }
                RawScore      = $score
            }
        }
    }

    # Sort by score descending and return top N
    $rankedResults = @($scoredResults | Sort-Object -Property RawScore -Descending | Select-Object -First $Top)
    
    # Remove RawScore from output
    foreach ($result in $rankedResults) {
        $result.PSObject.Properties.Remove('RawScore')
    }

    return $rankedResults
}
