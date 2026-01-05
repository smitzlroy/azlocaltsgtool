<#
.SYNOPSIS
    Convert input text to normalized tokens for searching.
#>

function ConvertTo-NormalizedTokens {
    <#
    .SYNOPSIS
        Normalize input text into searchable tokens.
    .DESCRIPTION
        - Lowercases text
        - Preserves dot-delimited identifiers (e.g., Microsoft.Health.FaultType.Cluster.ValidationReport.Failed)
        - Splits camel-case words
        - Removes punctuation except dots in identifiers
        - Splits on whitespace
        - Removes common stopwords
    .PARAMETER InputText
        The text to normalize.
    .OUTPUTS
        Array of normalized tokens.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$InputText
    )

    if ([string]::IsNullOrWhiteSpace($InputText)) {
        return @()
    }

    # Lowercase
    $text = $InputText.ToLowerInvariant()

    # Extract dot-delimited identifiers (like Microsoft.Health.FaultType.Cluster.ValidationReport.Failed)
    # These are high-value signals
    $dotIdentifiers = [regex]::Matches($text, '\b[a-z0-9]+(?:\.[a-z0-9]+){2,}\b') | 
        ForEach-Object { $_.Value }

    # Split camel-case (e.g., ValidationReport -> validation report)
    $text = $text -creplace '([a-z])([A-Z])', '$1 $2'

    # Remove punctuation except within dot identifiers (already extracted)
    # Replace non-alphanumeric with spaces
    $text = $text -replace '[^a-z0-9\s]', ' '

    # Split on whitespace
    $tokens = $text -split '\s+' | Where-Object { $_.Length -gt 0 }

    # Remove common stopwords
    $stopwords = @('the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by', 'from', 'is', 'was', 'are', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'should', 'could', 'may', 'might', 'must', 'can', 'this', 'that', 'these', 'those')
    $tokens = $tokens | Where-Object { $_ -notin $stopwords -and $_.Length -gt 2 }

    # Combine tokens with dot identifiers (higher value)
    $allTokens = @($dotIdentifiers) + @($tokens) | Select-Object -Unique

    return $allTokens
}
