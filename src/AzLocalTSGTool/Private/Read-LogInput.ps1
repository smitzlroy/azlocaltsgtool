<#
.SYNOPSIS
    Read log input from file or text.
#>

function Read-LogInput {
    <#
    .SYNOPSIS
        Read log input from a file path or directly from text.
    .PARAMETER ErrorText
        Direct error text input.
    .PARAMETER Path
        Path to a log file.
    .OUTPUTS
        String containing the log content.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Text')]
    [OutputType([string])]
    param(
        [Parameter(ParameterSetName = 'Text', Mandatory)]
        [string]$ErrorText,

        [Parameter(ParameterSetName = 'File', Mandatory)]
        [string]$Path
    )

    if ($PSCmdlet.ParameterSetName -eq 'File') {
        if (-not (Test-Path $Path)) {
            throw "File not found: $Path"
        }

        try {
            return Get-Content -Path $Path -Raw -ErrorAction Stop
        }
        catch {
            throw "Failed to read file '$Path': $_"
        }
    }
    else {
        return $ErrorText
    }
}
