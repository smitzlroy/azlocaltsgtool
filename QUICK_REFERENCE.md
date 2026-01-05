# Quick Reference - AzLocalTSGTool

## Installation

### From GitHub Release (Recommended)
1. Download `AzLocalTSGTool-X.Y.Z.zip` from [Releases](https://github.com/smitzlroy/azlocaltsgtool/releases)
2. Extract to PowerShell modules directory:
   - Windows: `$env:USERPROFILE\Documents\PowerShell\Modules\AzLocalTSGTool`
   - Linux/macOS: `~/.local/share/powershell/Modules/AzLocalTSGTool`
3. Import: `Import-Module AzLocalTSGTool`

### From Source (Development)
```powershell
git clone https://github.com/smitzlroy/azlocaltsgtool.git
cd azlocaltsgtool
.\tools\Bootstrap.ps1        # Install dependencies
.\tools\Build.ps1            # Build module
.\tools\InstallLocal.ps1     # Install to CurrentUser
```

## Commands

### Update-AzLocalTSGIndex
Build/refresh the local search index.

```powershell
# Build/refresh the index
Update-AzLocalTSGIndex

# Force refresh
Update-AzLocalTSGIndex -Force
```

### Get-AzLocalTSGFix
Search for known issues and fixes.

```powershell
# Search by error text
Get-AzLocalTSGFix -ErrorText "cluster validation failed"

# Search from log file
Get-AzLocalTSGFix -Path ".\deployment.log"

# Return more results
Get-AzLocalTSGFix -ErrorText "AKS node not ready" -Top 10

# Update cache before searching
Get-AzLocalTSGFix -ErrorText "storage error" -UpdateCache

# JSON output
Get-AzLocalTSGFix -ErrorText "timeout" -Json
```

## Environment Variables

```powershell
# Optional: Higher GitHub API rate limits (60/hr → 5000/hr)
$env:GITHUB_TOKEN = "ghp_your_personal_access_token"
```

## VS Code Tasks

| Task | Shortcut | Description |
|------|----------|-------------|
| **Bootstrap** | Ctrl+Shift+P → Run Task | Install Pester + PSScriptAnalyzer |
| **Lint** | Ctrl+Shift+P → Run Task | Check code quality |
| **Test** | Ctrl+Shift+B | Run Pester tests (default build) |
| **Build** | Ctrl+Shift+P → Run Task | Package module to /out |
| **InstallLocal** | Ctrl+Shift+P → Run Task | Install to CurrentUser scope |

## Common Workflows

### First-Time Setup
```powershell
# 1. Set environment variables (optional)
$env:GITHUB_TOKEN = "ghp_..."

# 2. Import module
Import-Module AzLocalTSGTool -Force

# 3. Build index
Update-AzLocalTSGIndex

# 4. Search
Get-AzLocalTSGFix -ErrorText "your error here"
```

### Troubleshooting an Error
```powershell
# Quick search
Get-AzLocalTSGFix -ErrorText "Microsoft.Health.FaultType.Cluster.ValidationReport.Failed"

# From log file with more results
Get-AzLocalTSGFix -Path "C:\logs\error.log" -Top 10

# With fresh cache
Get-AzLocalTSGFix -ErrorText "deployment failed" -UpdateCache
```

### Development Workflow
```powershell
# 1. Make changes to src/AzLocalTSGTool/
# 2. Run Lint task
# 3. Run Test task
# 4. Run Build task
# 5. Run InstallLocal task
# 6. Test: Import-Module AzLocalTSGTool -Force
```

### Create a Release
```powershell
# 1. Bump version
.\tools\Bump-Version.ps1 -Patch  # or -Minor, -Major

# 2. Commit and push
git add .
git commit -m "Bump version to X.Y.Z"
git push

# 3. Tag and push
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin vX.Y.Z

# GitHub Actions creates release automatically
```

## Example Output

```powershell
PS> Get-AzLocalTSGFix -ErrorText "validation failed"

==> Found 3 matching issue(s):

[1] Cluster-Validation-Failures
    Source:     GitHub
    Confidence: 85%
    Match:      Exact identifier match: validation | Token overlap: 3/5 query tokens matched
    URL:        https://github.com/Azure/AzureLocal-Supportability/blob/main/docs/validation-failures.md
    Fix:        Run validation with verbose output to identify specific failures
    Steps:
      1. Run Test-Cluster -Verbose to see detailed validation results
      2. Review failed validation items in the report
      3. Address each failure per TSG guidance
      ... (2 more steps, see URL)

[2] Storage-Validation-Issues
    Source:     GitHub
    Confidence: 72%
    Match:      Token overlap: 2/5 query tokens matched
    URL:        https://github.com/Azure/AzureLocal-Supportability/blob/main/docs/storage.md
    Fix:        Verify storage configuration meets requirements
    Steps:
      1. Check disk configuration and capacity
      2. Validate storage pool health
      3. Review event logs for disk errors
```

## Cache Location

- **Windows**: `%LOCALAPPDATA%\AzLocalTSGTool`
- **Linux/macOS**: `~/.azlocaltsgtool`

Contains:
- `index.json` - Searchable index with tokens and extracted fixes

## Troubleshooting

### "Index is empty"
```powershell
Update-AzLocalTSGIndex
```

### GitHub API rate limit
```powershell
$env:GITHUB_TOKEN = "ghp_your_token"
Update-AzLocalTSGIndex -Force
```

### Module not found after install
```powershell
# Reimport
Import-Module AzLocalTSGTool -Force

# Or check module path
$env:PSModulePath -split ';'
```

## Links

- **GitHub**: https://github.com/smitzlroy/azlocaltsgtool
- **Releases**: https://github.com/smitzlroy/azlocaltsgtool/releases
- **Issues**: https://github.com/smitzlroy/azlocaltsgtool/issues
- **Full Documentation**: [README.md](README.md)
