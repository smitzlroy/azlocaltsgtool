<#
.SYNOPSIS
    Update the local TSG index from GitHub and/or Azure DevOps Wiki sources.
.DESCRIPTION
    Fetches troubleshooting guides from configured sources and builds a local
    searchable index for fast offline queries.
.PARAMETER Source
    The source(s) to update from: GitHub, AzureDevOpsWiki, or All.
.PARAMETER Force
    Force refresh even if cache is recent.
.EXAMPLE
    Update-AzLocalTSGIndex -Source GitHub
    Updates index from GitHub Azure/AzureLocal-Supportability repository only.
.EXAMPLE
    Update-AzLocalTSGIndex -Source All -Force
    Forces a full refresh from all sources.
#>
function Update-AzLocalTSGIndex {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('GitHub', 'AzureDevOpsWiki', 'All')]
        [string]$Source = 'All',

        [Parameter()]
        [switch]$Force
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    Write-Host "==> Updating AzLocalTSG Index from $Source..." -ForegroundColor Cyan

    $allDocuments = @()

    # Fetch from GitHub
    if ($Source -in @('GitHub', 'All')) {
        Write-Host "  → Fetching from GitHub..." -ForegroundColor Yellow
        try {
            $githubDocs = Invoke-GitHubFetch -Force:$Force
            $allDocuments += $githubDocs
            Write-Host "    ✓ Fetched $($githubDocs.Count) documents from GitHub" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to fetch from GitHub: $_"
        }
    }

    # Fetch from Azure DevOps Wiki
    if ($Source -in @('AzureDevOpsWiki', 'All')) {
        Write-Host "  → Fetching from Azure DevOps Wiki..." -ForegroundColor Yellow
        try {
            $azdoDocs = Invoke-AzDoWikiFetch -Force:$Force
            $allDocuments += $azdoDocs
            Write-Host "    ✓ Fetched $($azdoDocs.Count) documents from Azure DevOps Wiki" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to fetch from Azure DevOps Wiki: $_"
        }
    }

    if ($allDocuments.Count -eq 0) {
        Write-Warning "No documents fetched. Index will be empty."
        return
    }

    Write-Host "  → Building search index..." -ForegroundColor Yellow

    # Build index entries
    $indexEntries = @()

    foreach ($doc in $allDocuments) {
        Write-Verbose "Indexing: $($doc.Title)"

        # Normalize tokens from content
        $tokens = ConvertTo-NormalizedTokens -InputText $doc.Content

        # Extract fix information
        $fixInfo = Get-FixFromMarkdown -MarkdownContent $doc.Content

        $indexEntries += [PSCustomObject]@{
            Source      = $doc.Source
            Title       = $doc.Title
            Path        = $doc.Path
            Url         = $doc.Url
            Tokens      = $tokens
            Content     = $doc.Content
            FixSummary  = $fixInfo.FixSummary
            FixSteps    = $fixInfo.FixSteps
            LastUpdated = $doc.LastUpdated
        }
    }

    # Save index
    Write-Host "  → Saving index to cache..." -ForegroundColor Yellow
    Save-Index -IndexEntries $indexEntries

    $cacheRoot = Get-CacheRoot
    Write-Host ""
    Write-Host "==> Index updated successfully!" -ForegroundColor Green
    Write-Host "  Documents indexed: $($indexEntries.Count)" -ForegroundColor Gray
    Write-Host "  Cache location:    $cacheRoot" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Try it now:" -ForegroundColor Cyan
    Write-Host "    Get-AzLocalTSGFix -ErrorText 'your error message'" -ForegroundColor Gray
}
