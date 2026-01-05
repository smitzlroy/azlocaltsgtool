<#
.SYNOPSIS
    Fetch content from GitHub Azure/AzureLocal-Supportability repository.
#>

function Invoke-GitHubFetch {
    <#
    .SYNOPSIS
        Enumerate and download relevant markdown documents from Azure/AzureLocal-Supportability repository.
    .DESCRIPTION
        Uses GitHub REST API to:
        1. Get repository tree
        2. Filter for markdown files (*.md)
        3. Download content
        Supports GITHUB_TOKEN environment variable for higher rate limits.
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

    Write-Verbose "Fetching from GitHub Azure/AzureLocal-Supportability..."

    $owner = 'Azure'
    $repo = 'AzureLocal-Supportability'
    $baseApiUrl = 'https://api.github.com'

    # Check for GitHub token
    $headers = @{
        'Accept'     = 'application/vnd.github+json'
        'User-Agent' = 'AzLocalTSGTool-PowerShell'
    }

    if ($env:GITHUB_TOKEN) {
        $headers['Authorization'] = "Bearer $env:GITHUB_TOKEN"
        Write-Verbose "Using GITHUB_TOKEN for authentication"
    } else {
        Write-Warning "GITHUB_TOKEN not set. GitHub API rate limits will be lower (60 req/hour vs 5000 req/hour)."
    }

    try {
        # Get default branch
        Write-Verbose "Getting repository information..."
        $repoUrl = "$baseApiUrl/repos/$owner/$repo"
        $repoInfo = Invoke-RestMethod -Uri $repoUrl -Headers $headers -Method Get
        $defaultBranch = $repoInfo.default_branch

        # Get repository tree recursively
        Write-Verbose "Fetching repository tree for branch '$defaultBranch'..."
        $treeUrl = "$baseApiUrl/repos/$owner/$repo/git/trees/${defaultBranch}?recursive=1"
        $treeResponse = Invoke-RestMethod -Uri $treeUrl -Headers $headers -Method Get

        # Filter for markdown files
        $markdownFiles = $treeResponse.tree | Where-Object { 
            $_.type -eq 'blob' -and $_.path -like '*.md' 
        }

        Write-Verbose "Found $($markdownFiles.Count) markdown files"

        $documents = @()

        foreach ($file in $markdownFiles) {
            Write-Verbose "Downloading: $($file.path)"

            try {
                # Download file content (raw)
                $rawUrl = "https://raw.githubusercontent.com/$owner/$repo/$defaultBranch/$($file.path)"
                $content = Invoke-RestMethod -Uri $rawUrl -Headers $headers -Method Get

                $documents += [PSCustomObject]@{
                    Source      = 'GitHub'
                    Title       = [System.IO.Path]::GetFileNameWithoutExtension($file.path)
                    Path        = $file.path
                    Url         = "https://github.com/$owner/$repo/blob/$defaultBranch/$($file.path)"
                    Content     = $content
                    LastUpdated = (Get-Date).ToString('o')
                }
            } catch {
                Write-Warning "Failed to download $($file.path): $_"
            }
        }

        Write-Verbose "Successfully fetched $($documents.Count) documents from GitHub"
        return $documents
    } catch {
        Write-Error "Failed to fetch from GitHub: $_"
        throw
    }
}
