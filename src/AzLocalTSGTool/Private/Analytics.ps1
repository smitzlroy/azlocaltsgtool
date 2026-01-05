<#
.SYNOPSIS
    Analytics and trend tracking functions for TSG searches.
#>

function Get-AnalyticsPath {
    <#
    .SYNOPSIS
        Get the path to the analytics data file.
    #>
    $cachePath = Get-CacheRoot
    return Join-Path $cachePath "analytics.json"
}

function Add-SearchAnalytics {
    <#
    .SYNOPSIS
        Record a search query for analytics tracking.
    .PARAMETER ErrorText
        The error text that was searched for.
    .PARAMETER ResultCount
        Number of results returned.
    .PARAMETER TopMatch
        Title of the top matching TSG (if any).
    .PARAMETER TopConfidence
        Confidence score of the top match.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorText,
        
        [Parameter(Mandatory)]
        [int]$ResultCount,
        
        [Parameter()]
        [string]$TopMatch,
        
        [Parameter()]
        [int]$TopConfidence
    )

    try {
        $analyticsPath = Get-AnalyticsPath
        
        # Load existing analytics or create new
        $analytics = @{
            Searches = @()
        }
        
        if (Test-Path $analyticsPath) {
            $existingData = Get-Content $analyticsPath -Raw -ErrorAction SilentlyContinue
            if ($existingData) {
                $analytics = $existingData | ConvertFrom-Json -AsHashtable
            }
        }
        
        # Create search record
        $searchRecord = @{
            Timestamp     = (Get-Date).ToString('o')
            ErrorText     = $ErrorText.Substring(0, [Math]::Min(200, $ErrorText.Length))  # Truncate long errors
            ResultCount   = $ResultCount
            TopMatch      = $TopMatch
            TopConfidence = $TopConfidence
        }
        
        # Add to searches array
        $analytics.Searches += $searchRecord
        
        # Keep only last 1000 searches to prevent file from growing too large
        if ($analytics.Searches.Count -gt 1000) {
            $analytics.Searches = $analytics.Searches | Select-Object -Last 1000
        }
        
        # Save analytics
        $analytics | ConvertTo-Json -Depth 10 | Set-Content -Path $analyticsPath -Force
    } catch {
        # Silently fail - analytics shouldn't break the main tool
        Write-Verbose "Failed to record analytics: $_"
    }
}

function Get-SearchAnalytics {
    <#
    .SYNOPSIS
        Retrieve search analytics data.
    .PARAMETER DaysBack
        Number of days to look back. Default is 30.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [int]$DaysBack = 30
    )

    $analyticsPath = Get-AnalyticsPath
    
    if (-not (Test-Path $analyticsPath)) {
        Write-Warning "No analytics data found. Start using Get-AzLocalTSGFix to collect data."
        return $null
    }
    
    $analytics = Get-Content $analyticsPath -Raw | ConvertFrom-Json
    
    # Filter by date range
    $cutoffDate = (Get-Date).AddDays(-$DaysBack)
    $recentSearches = @($analytics.Searches | Where-Object {
            try {
                [DateTime]::Parse($_.Timestamp) -gt $cutoffDate
            } catch {
                $false
            }
        })
    
    if ($recentSearches.Count -eq 0) {
        Write-Warning "No searches found in the last $DaysBack days."
        return $null
    }
    
    # Calculate statistics
    $totalSearches = $recentSearches.Count
    $noResultsCount = @($recentSearches | Where-Object { $_.ResultCount -eq 0 }).Count
    $lowConfidenceCount = @($recentSearches | Where-Object { $_.ResultCount -gt 0 -and $_.TopConfidence -lt 20 }).Count
    
    # Top errors (by frequency)
    $errorFrequency = $recentSearches | Group-Object ErrorText | 
    Sort-Object Count -Descending | 
    Select-Object -First 10 | 
    ForEach-Object {
        [PSCustomObject]@{
            ErrorText  = $_.Name
            Count      = $_.Count
            Percentage = [math]::Round(($_.Count / $totalSearches * 100), 1)
        }
    }
    
    # Top matched TSGs
    $tsgFrequency = $recentSearches | 
    Where-Object { $_.TopMatch } | 
    Group-Object TopMatch | 
    Sort-Object Count -Descending | 
    Select-Object -First 10 | 
    ForEach-Object {
        [PSCustomObject]@{
            TSG           = $_.Name
            MatchCount    = $_.Count
            AvgConfidence = [math]::Round(($_.Group | Measure-Object -Property TopConfidence -Average).Average, 1)
        }
    }
    
    # Searches with no/poor results (potential gaps)
    $gaps = $recentSearches | 
    Where-Object { $_.ResultCount -eq 0 -or ($_.ResultCount -gt 0 -and $_.TopConfidence -lt 15) } |
    Group-Object ErrorText |
    Sort-Object Count -Descending |
    Select-Object -First 10 |
    ForEach-Object {
        [PSCustomObject]@{
            ErrorText      = $_.Name
            SearchCount    = $_.Count
            BestConfidence = ($_.Group | Measure-Object -Property TopConfidence -Maximum).Maximum
        }
    }
    
    # Return analytics summary
    return [PSCustomObject]@{
        Period              = "$DaysBack days"
        TotalSearches       = $totalSearches
        NoResultsCount      = $noResultsCount
        LowConfidenceCount  = $lowConfidenceCount
        NoResultsPercentage = [math]::Round(($noResultsCount / $totalSearches * 100), 1)
        TopErrors           = $errorFrequency
        TopMatchedTSGs      = $tsgFrequency
        PotentialGaps       = $gaps
    }
}
