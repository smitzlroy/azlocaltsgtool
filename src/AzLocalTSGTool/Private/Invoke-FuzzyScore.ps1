<#
.SYNOPSIS
    Calculate fuzzy string similarity score.
#>

function Invoke-FuzzyScore {
    <#
    .SYNOPSIS
        Calculate Jaro-Winkler similarity between two strings.
    .DESCRIPTION
        Returns a score between 0.0 (no match) and 1.0 (exact match).
        Uses simplified Jaro-Winkler algorithm for fuzzy matching.
    .PARAMETER String1
        First string to compare.
    .PARAMETER String2
        Second string to compare.
    .OUTPUTS
        Double between 0.0 and 1.0.
    #>
    [CmdletBinding()]
    [OutputType([double])]
    param(
        [Parameter(Mandatory)]
        [string]$String1,

        [Parameter(Mandatory)]
        [string]$String2
    )

    if ($String1 -eq $String2) {
        return 1.0
    }

    $len1 = $String1.Length
    $len2 = $String2.Length

    if ($len1 -eq 0 -or $len2 -eq 0) {
        return 0.0
    }

    # Simplified Jaro distance
    $matchWindow = [Math]::Max($len1, $len2) / 2 - 1
    $matchWindow = [Math]::Max(0, $matchWindow)

    $matches1 = New-Object bool[] $len1
    $matches2 = New-Object bool[] $len2

    $matches = 0
    $transpositions = 0

    # Find matches
    for ($i = 0; $i -lt $len1; $i++) {
        $start = [Math]::Max(0, $i - $matchWindow)
        $end = [Math]::Min($i + $matchWindow + 1, $len2)

        for ($j = $start; $j -lt $end; $j++) {
            if ($matches2[$j] -or $String1[$i] -ne $String2[$j]) {
                continue
            }
            $matches1[$i] = $true
            $matches2[$j] = $true
            $matches++
            break
        }
    }

    if ($matches -eq 0) {
        return 0.0
    }

    # Count transpositions
    $k = 0
    for ($i = 0; $i -lt $len1; $i++) {
        if (-not $matches1[$i]) {
            continue
        }
        while (-not $matches2[$k]) {
            $k++
        }
        if ($String1[$i] -ne $String2[$k]) {
            $transpositions++
        }
        $k++
    }

    $jaro = (($matches / $len1) + ($matches / $len2) + (($matches - $transpositions / 2) / $matches)) / 3.0

    # Jaro-Winkler prefix bonus
    $prefix = 0
    $maxPrefix = 4
    for ($i = 0; $i -lt [Math]::Min($len1, $len2, $maxPrefix); $i++) {
        if ($String1[$i] -eq $String2[$i]) {
            $prefix++
        }
        else {
            break
        }
    }

    $jaroWinkler = $jaro + ($prefix * 0.1 * (1.0 - $jaro))

    return $jaroWinkler
}
