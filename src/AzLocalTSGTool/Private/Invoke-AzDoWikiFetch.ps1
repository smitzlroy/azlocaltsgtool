<#
.SYNOPSIS
    Fetch content from Azure DevOps Wiki.
#>

function Invoke-AzDoWikiFetch {
    <#
    .SYNOPSIS
        Fetch TSG pages from Azure DevOps Wiki using REST API.
    .DESCRIPTION
        Uses Azure DevOps REST API Pages - Get with includeContent=true.
        Requires AZDO_PAT environment variable containing a Personal Access Token.
    .PARAMETER Force
        Force refresh even if cache is recent.
    .OUTPUTS
        Array of document objects with metadata.
    #>
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [switch]$Force
    )

    Write-Verbose "Fetching from Azure DevOps Wiki..."

    # Check for PAT
    if (-not $env:AZDO_PAT) {
        Write-Warning "AZDO_PAT environment variable not set. Skipping Azure DevOps Wiki fetch."
        Write-Warning "Set AZDO_PAT to enable: `$env:AZDO_PAT = 'your-personal-access-token'"
        return @()
    }

    $organization = 'supportability'
    $project = 'WindowsCloud'
    $wikiIdentifier = 'WindowsCloud.wiki'
    $baseUrl = "https://dev.azure.com/$organization/$project/_apis/wiki/wikis/$wikiIdentifier"
    
    # Base64 encode PAT for basic auth (format: :PAT)
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($env:AZDO_PAT)"))
    
    $headers = @{
        'Authorization' = "Basic $base64AuthInfo"
        'Content-Type' = 'application/json'
    }

    try {
        # List all pages recursively
        Write-Verbose "Fetching wiki pages list..."
        $pagesUrl = "$baseUrl/pages?recursionLevel=full&api-version=7.0"
        
        try {
            $pagesResponse = Invoke-RestMethod -Uri $pagesUrl -Headers $headers -Method Get
        }
        catch {
            if ($_.Exception.Response.StatusCode -eq 401) {
                Write-Error "Authentication failed. Please verify AZDO_PAT is valid and has 'Read' permissions for Wiki."
            }
            else {
                Write-Error "Failed to fetch wiki pages: $_"
            }
            return @()
        }

        # Filter for TSG-related pages (looking for path containing TSG or troubleshooting keywords)
        $tsgPages = @()
        
        function Get-TsgPagesRecursive {
            param($page)
            
            if ($page.path -match '(tsg|troubleshoot|issue|fix|known|problem)' -or 
                $page.path -match '2331194') {  # Specific TSG path ID from requirements
                $tsgPages += $page
            }
            
            if ($page.subPages) {
                foreach ($subPage in $page.subPages) {
                    Get-TsgPagesRecursive -page $subPage
                }
            }
        }

        if ($pagesResponse.subPages) {
            foreach ($page in $pagesResponse.subPages) {
                Get-TsgPagesRecursive -page $page
            }
        }

        Write-Verbose "Found $($tsgPages.Count) TSG-related pages"

        $documents = @()

        foreach ($page in $tsgPages) {
            Write-Verbose "Downloading: $($page.path)"

            try {
                # Fetch page content
                $pageUrl = "$baseUrl/pages?path=$($page.path)&includeContent=true&api-version=7.0"
                $pageContent = Invoke-RestMethod -Uri $pageUrl -Headers $headers -Method Get

                $documents += [PSCustomObject]@{
                    Source = 'AzureDevOpsWiki'
                    Title = $page.path -replace '^/', '' -replace '/', ' > '
                    Path = $page.path
                    Url = $page.remoteUrl
                    Content = $pageContent.content
                    LastUpdated = (Get-Date).ToString('o')
                }
            }
            catch {
                Write-Warning "Failed to download page $($page.path): $_"
            }
        }

        Write-Verbose "Successfully fetched $($documents.Count) documents from Azure DevOps Wiki"
        return $documents
    }
    catch {
        Write-Error "Failed to fetch from Azure DevOps Wiki: $_"
        throw
    }
}
