<#
.SYNOPSIS
    Cache management functions for AzLocalTSGTool.
.DESCRIPTION
    Provides cache root location, read/write operations, and index management.
#>

function Get-CacheRoot {
    <#
    .SYNOPSIS
        Get the cache root directory path.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if ($IsWindows -or $null -eq $IsWindows) {
        $cacheRoot = Join-Path $env:LOCALAPPDATA 'AzLocalTSGTool'
    } else {
        $cacheRoot = Join-Path $HOME '.azlocaltsgtool'
    }

    if (-not (Test-Path $cacheRoot)) {
        New-Item -Path $cacheRoot -ItemType Directory -Force | Out-Null
    }

    return $cacheRoot
}

function Read-Cache {
    <#
    .SYNOPSIS
        Read a cached file.
    .PARAMETER Name
        Name of the cache file (without path).
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $cacheRoot = Get-CacheRoot
    $cachePath = Join-Path $cacheRoot $Name

    if (Test-Path $cachePath) {
        return Get-Content -Path $cachePath -Raw -Encoding UTF8
    }

    return $null
}

function Write-Cache {
    <#
    .SYNOPSIS
        Write content to cache.
    .PARAMETER Name
        Name of the cache file.
    .PARAMETER Content
        Content to write.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Content
    )

    $cacheRoot = Get-CacheRoot
    $cachePath = Join-Path $cacheRoot $Name

    Set-Content -Path $cachePath -Value $Content -Encoding UTF8 -Force
}

function Load-Index {
    <#
    .SYNOPSIS
        Load the search index from cache.
    .OUTPUTS
        Array of index entries or empty array if not found.
    #>
    [CmdletBinding()]
    [OutputType([array])]
    param()

    $indexJson = Read-Cache -Name 'index.json'
    if ($indexJson) {
        try {
            return ConvertFrom-Json -InputObject $indexJson -AsHashtable:$false
        } catch {
            Write-Warning "Failed to parse index.json: $_"
            return @()
        }
    }

    return @()
}

function Save-Index {
    <#
    .SYNOPSIS
        Save the search index to cache.
    .PARAMETER IndexEntries
        Array of index entries to save.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$IndexEntries
    )

    $indexJson = ConvertTo-Json -InputObject $IndexEntries -Depth 10 -Compress:$false
    Write-Cache -Name 'index.json' -Content $indexJson
}
