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
        - PowerShell code blocks with commands
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
        FixSteps   = @()
    }

    if ([string]::IsNullOrWhiteSpace($MarkdownContent)) {
        return $result
    }

    # Look for sections with fix-related keywords
    $fixKeywords = @('fix', 'resolution', 'mitigation', 'workaround', 'solution', 'steps', 'remediation', 'repair', 'command')
    
    $lines = $MarkdownContent -split "`r?`n"
    $inFixSection = $false
    $inCodeBlock = $false
    $currentSection = @()
    $fixSectionContent = @()
    $codeBlockLines = @()
    $codeBlockMarker = '```'

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # Check for code block markers
        if ($line.Trim() -match '^```') {
            if ($inCodeBlock) {
                # End of code block - save it if we're in a fix section
                if ($inFixSection -and @($codeBlockLines).Count -gt 0) {
                    $currentSection += $codeBlockMarker
                    $currentSection += $codeBlockLines
                    $currentSection += $codeBlockMarker
                }
                $codeBlockLines = @()
                $inCodeBlock = $false
            } else {
                # Start of code block
                $inCodeBlock = $true
                $codeBlockLines = @()
            }
            continue
        }

        # Collect code block content
        if ($inCodeBlock) {
            $codeBlockLines += $line
            continue
        }
        
        # Check if this is a heading with fix keywords
        if ($line -match '^#{1,6}\s+(.+)$') {
            $heading = $matches[1].ToLowerInvariant()
            
            # If we were in a fix section, save it
            if ($inFixSection -and @($currentSection).Count -gt 0) {
                $fixSectionContent += $currentSection
                $currentSection = @()
            }

            # Check if this heading indicates a fix section
            $inFixSection = $false
            foreach ($keyword in $fixKeywords) {
                if ($heading -like "*$keyword*") {
                    $inFixSection = $true
                    $currentSection += $line
                    break
                }
            }
        } elseif ($inFixSection) {
            # Collect content within fix section
            $currentSection += $line
        }
    }

    # Add final section if we were in one
    if ($inFixSection -and @($currentSection).Count -gt 0) {
        $fixSectionContent += $currentSection
    }

    # Extract steps from fix section content - prioritize code blocks as complete steps
    $steps = @()
    $inExtractCodeBlock = $false
    $currentCodeBlock = @()
    $stepCounter = 0
    
    foreach ($line in $fixSectionContent) {
        # Handle code blocks
        if ($line.Trim() -match '^```') {
            if ($inExtractCodeBlock) {
                # End of code block - process it
                if (@($currentCodeBlock).Count -gt 0) {
                    # Clean up code: remove comments, empty lines, join into logical commands
                    $cleanedCode = $currentCodeBlock | Where-Object { 
                        $_.Trim() -ne '' -and 
                        -not ($_.TrimStart() -match '^#[^!]') 
                    }
                    
                    if (@($cleanedCode).Count -gt 0) {
                        $stepCounter++
                        # Create a structured step with the full code block
                        $codeStep = [PSCustomObject]@{
                            Number  = $stepCounter
                            Type    = 'Code'
                            Content = $cleanedCode -join "`n"
                        }
                        $steps += $codeStep
                    }
                }
                $currentCodeBlock = @()
                $inExtractCodeBlock = $false
            } else {
                $inExtractCodeBlock = $true
            }
            continue
        }

        if ($inExtractCodeBlock) {
            $currentCodeBlock += $line
            continue
        }

        # Look for narrative instructions between code blocks
        # Lines starting with "Then" or "Next" or "Now" - these are important transitions
        if ($line -match '^\s*(Then|Next|Now|After|Finally)\s+(.+)$') {
            $stepCounter++
            $textStep = [PSCustomObject]@{
                Number  = $stepCounter
                Type    = 'Text'
                Content = $matches[2].Trim()
            }
            $steps += $textStep
        }
        # Numbered list item (e.g., "1. Step one")
        elseif ($line -match '^\s*\d+\.\s+(.+)$') {
            $stepCounter++
            $textStep = [PSCustomObject]@{
                Number  = $stepCounter
                Type    = 'Text'
                Content = $matches[1].Trim()
            }
            $steps += $textStep
        }
        # Bullet list item (e.g., "- Step one" or "* Step one")
        elseif ($line -match '^\s*[-*]\s+(.+)$') {
            $stepCounter++
            $textStep = [PSCustomObject]@{
                Number  = $stepCounter
                Type    = 'Text'
                Content = $matches[1].Trim()
            }
            $steps += $textStep
        }
    }

    # Create fix summary (first non-empty paragraph in fix section)
    $summary = ''
    foreach ($line in $fixSectionContent) {
        if (-not [string]::IsNullOrWhiteSpace($line) -and 
            $line -notmatch '^\s*[-*\d]' -and 
            $line -notmatch '^#{1,6}\s' -and 
            $line.Trim() -notmatch '^```') {
            $summary = $line.Trim()
            if ($summary.Length -gt 200) {
                $summary = $summary.Substring(0, 197) + '...'
            }
            break
        }
    }

    $result.FixSummary = $summary
    $result.FixSteps = $steps

    return $result
}
