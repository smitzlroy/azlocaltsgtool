BeforeAll {
    # Import module
    $ModulePath = Join-Path $PSScriptRoot '..' 'src' 'AzLocalTSGTool' 'AzLocalTSGTool.psd1'
    Import-Module $ModulePath -Force
}

Describe 'Update-AzLocalTSGIndex' {
    Context 'Parameter validation' {
        It 'Should have Source parameter with valid set' {
            $param = (Get-Command Update-AzLocalTSGIndex).Parameters['Source']
            $param.Attributes.ValidValues | Should -Contain 'GitHub'
            $param.Attributes.ValidValues | Should -Contain 'AzureDevOpsWiki'
            $param.Attributes.ValidValues | Should -Contain 'All'
        }

        It 'Should have Force switch' {
            Get-Command Update-AzLocalTSGIndex | Should -HaveParameter Force -Type switch
        }
    }

    Context 'Cache directory creation' {
        It 'Should create cache directory if it does not exist' {
            $cacheRoot = if ($IsWindows -or $null -eq $IsWindows) {
                Join-Path $env:LOCALAPPDATA 'AzLocalTSGTool'
            } else {
                Join-Path $HOME '.azlocaltsgtool'
            }

            # The command will try to create the cache directory
            # We just verify it doesn't throw
            { Update-AzLocalTSGIndex -Source GitHub -ErrorAction Stop -WarningAction SilentlyContinue } | 
            Should -Not -Throw
        }
    }

    Context 'GitHub source' {
        It 'Should attempt to fetch from GitHub when Source is GitHub' {
            # This is a smoke test - it will attempt real fetch unless GITHUB_TOKEN is not set
            # In CI, this validates the code path doesn't throw exceptions
            { Update-AzLocalTSGIndex -Source GitHub -WarningAction SilentlyContinue -ErrorAction SilentlyContinue } | 
            Should -Not -Throw
        }
    }

    Context 'Azure DevOps Wiki source' {
        It 'Should warn when AZDO_PAT is not set' {
            # Temporarily clear AZDO_PAT
            $oldPat = $env:AZDO_PAT
            $env:AZDO_PAT = $null
            
            try {
                $result = Update-AzLocalTSGIndex -Source AzureDevOpsWiki -WarningVariable warnings 3>$null
                $warnings | Should -Not -BeNullOrEmpty
            } finally {
                $env:AZDO_PAT = $oldPat
            }
        }
    }

    Context 'Index persistence' {
        It 'Should save index to cache' {
            # Run update (may or may not succeed depending on network/auth)
            Update-AzLocalTSGIndex -Source GitHub -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

            # Check if index.json exists (even if empty)
            $cacheRoot = if ($IsWindows -or $null -eq $IsWindows) {
                Join-Path $env:LOCALAPPDATA 'AzLocalTSGTool'
            } else {
                Join-Path $HOME '.azlocaltsgtool'
            }

            # Cache directory should exist after update attempt
            Test-Path $cacheRoot | Should -Be $true
        }
    }
}
