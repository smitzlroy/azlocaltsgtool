BeforeAll {
    # Import module
    $ModulePath = Join-Path $PSScriptRoot '..' 'src' 'AzLocalTSGTool' 'AzLocalTSGTool.psd1'
    Import-Module $ModulePath -Force
}

Describe 'Get-AzLocalTSGFix' {
    Context 'Parameter validation' {
        It 'Should have ErrorText parameter' {
            Get-Command Get-AzLocalTSGFix | Should -HaveParameter ErrorText -Type string
        }

        It 'Should have Path parameter' {
            Get-Command Get-AzLocalTSGFix | Should -HaveParameter Path -Type string
        }

        It 'Should have Top parameter with default value' {
            $param = (Get-Command Get-AzLocalTSGFix).Parameters['Top']
            $param | Should -Not -BeNullOrEmpty
            $param.ParameterType | Should -Be ([int])
        }

        It 'Should have Source parameter with valid set' {
            $param = (Get-Command Get-AzLocalTSGFix).Parameters['Source']
            $param.Attributes.ValidValues | Should -Contain 'GitHub'
            $param.Attributes.ValidValues | Should -Contain 'AzureDevOpsWiki'
            $param.Attributes.ValidValues | Should -Contain 'All'
        }

        It 'Should have UpdateCache switch' {
            Get-Command Get-AzLocalTSGFix | Should -HaveParameter UpdateCache -Type switch
        }

        It 'Should have Json switch' {
            Get-Command Get-AzLocalTSGFix | Should -HaveParameter Json -Type switch
        }
    }

    Context 'Empty index handling' {
        BeforeAll {
            # Clear cache for this test
            $cacheRoot = if ($IsWindows -or $null -eq $IsWindows) {
                Join-Path $env:LOCALAPPDATA 'AzLocalTSGTool'
            }
            else {
                Join-Path $HOME '.azlocaltsgtool'
            }
            
            if (Test-Path $cacheRoot) {
                $indexPath = Join-Path $cacheRoot 'index.json'
                if (Test-Path $indexPath) {
                    Remove-Item $indexPath -Force
                }
            }
        }

        It 'Should warn when index is empty' {
            $result = Get-AzLocalTSGFix -ErrorText "test error" -WarningVariable warnings 3>$null
            $warnings | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Token normalization' {
        It 'Should extract tokens from error text' {
            # This is an indirect test - if the command doesn't throw, tokens were extracted
            Mock -ModuleName AzLocalTSGTool Load-Index { return @() }
            
            { Get-AzLocalTSGFix -ErrorText "Microsoft.Health.FaultType.Cluster.ValidationReport.Failed" -WarningAction SilentlyContinue } | 
                Should -Not -Throw
        }
    }
}
