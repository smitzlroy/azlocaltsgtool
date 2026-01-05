<#
.SYNOPSIS
    Extract fix/resolution steps from markdown content.
#>

function Get-FixFromMarkdown {
    <#
    .SYNOPSIS
        Extract fix, resolution, mitigation, or workaround sections from markdown.
    .DESCRIPTION
        Heuristically identifies sections containing fix steps by looking for:
        - Headings containing: fix, resolution, mitigation, workaround, steps, solution
        - Numbered lists or bullet lists following such headings
    .PARAMETER MarkdownContent
        The markdown content to parse.
    .OUTPUTS
        PSCustomObject with FixSummary and FixSteps properties.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$MarkdownContent
    )

    $result = [PSCustomObject]@{
        FixSummary = ''
        FixSteps = @()
    }

    if ([string]::IsNullOrWhiteSpace($MarkdownContent)) {
        return $result
    }

    # Look for sections with fix-related keywords
    $fixKeywords = @('fix', 'resolution', 'mitigation', 'workaround', 'solution', 'steps', 'remediation', 'repair')
    
    $lines = $MarkdownContent -split "`r?`n"
    $inFixSection = $false
    $currentSection = @()
    $fixSectionContent = @()

    foreach ($line in $lines) {
        # Check if this is a heading with fix keywords
        if ($line -match '^#{1,6}\s+(.+)$') {
            $heading = $matches[1].ToLowerInvariant()
            
            # If we were in a fix section, save it
            if ($inFixSection -and $currentSection.Count -gt 0) {
                $fixSectionContent += $currentSection
                $currentSection = @()
            }

            # Check if this heading indicates a fix section
            $inFixSection = $false
            foreach ($keyword in $fixKeywords) {
                if ($heading -like "*$keyword*") {
                    $inFixSection = $true
                    break
                }
            }
        }
        elseif ($inFixSection) {
            # Collect content within fix section
            $currentSection += $line
        }
    }

    # Add final section if we were in one
    if ($inFixSection -and $currentSection.Count -gt 0) {
        $fixSectionContent += $currentSection
    }

    # Extract steps from fix section content
    $steps = @()
    foreach ($line in $fixSectionContent) {
        # Numbered list item (e.g., "1. Step one")
        if ($line -match '^\s*\d+\.\s+(.+)$') {
            $steps += $matches[1].Trim()
        }
        # Bullet list item (e.g., "- Step one" or "* Step one")
        elseif ($line -match '^\s*[-*]\s+(.+)$') {
            $steps += $matches[1].Trim()
        }
    }

    # Create fix summary (first non-empty paragraph in fix section)
    $summary = ''
    foreach ($line in $fixSectionContent) {
        if (-not [string]::IsNullOrWhiteSpace($line) -and $line -notmatch '^\s*[-*\d]' -and $line -notmatch '^#{1,6}\s') {
            $summary = $line.Trim()
            break
        }
    }

    $result.FixSummary = $summary
    $result.FixSteps = $steps

    return $result
}
