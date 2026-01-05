# AzLocalTSGTool

PowerShell module for rapidly troubleshooting Azure Local and AKS enabled by Azure Arc issues. Searches known issues and fixes from GitHub supportability content.

## Why AzLocalTSGTool?

Manual searching through documentation is slow and error-prone. AzLocalTSGTool:

- ✅ **Normalizes messy input** into high-signal tokens (fault types, error codes, component names)
- ✅ **Uses local cache/index** for instant offline search
- ✅ **Ranks candidates** with confidence scores and match explanations
- ✅ **Extracts fix steps** automatically - not just links

## Prerequisites

- PowerShell 7.0+ (pwsh) recommended
- Internet connection for initial index update
- Optional: `GITHUB_TOKEN` for higher GitHub API rate limits

## Quick Start

### 1. Open in VS Code

Clone and open this repository in VS Code:

```powershell
git clone https://github.com/smitzlroy/azlocaltsgtool.git
cd azlocaltsgtool
code .
```

### 2. Bootstrap Development Environment

Run the **Bootstrap** task in VS Code (Terminal → Run Task → Bootstrap) or manually:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File ./tools/Bootstrap.ps1
```

This installs Pester and PSScriptAnalyzer to your user profile.

### 3. Build and Install Locally

Run the **Build** and **InstallLocal** tasks, or manually:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File ./tools/Build.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File ./tools/InstallLocal.ps1
```

### 4. Set Environment Variables (Optional)

For higher GitHub API rate limits:

```powershell
$env:GITHUB_TOKEN = "ghp_your_token_here"
```

### 5. Update Index

First time (or to refresh):

```powershell
Import-Module AzLocalTSGTool -Force
Update-AzLocalTSGIndex
```

### 6. Search for Fixes

```powershell
Get-AzLocalTSGFix -ErrorText "Microsoft.Health.FaultType.Cluster.ValidationReport.Failed"
```

Or from a log file:

```powershell
Get-AzLocalTSGFix -Path "C:\logs\deployment.log" -Top 5
```

## Usage Examples

### Basic Search

```powershell
Get-AzLocalTSGFix -ErrorText "AKS node not ready timeout"
```

### Search with Cache Update

```powershell
Get-AzLocalTSGFix -ErrorText "cluster validation failed" -UpdateCache
```

### Search from Log File

```powershell
Get-AzLocalTSGFix -Path ".\error.log" -Top 10
```



### JSON Output for Automation

```powershell
Get-AzLocalTSGFix -ErrorText "deployment timeout" -Json | Out-File results.json
```

### Update Index with Force Refresh

```powershell
Update-AzLocalTSGIndex -Force
```

## VS Code Tasks

This repository includes pre-configured VS Code tasks for one-click workflows:

| Task | Description |
|------|-------------|
| **Bootstrap** | Install Pester + PSScriptAnalyzer |
| **Lint** | Run PSScriptAnalyzer on src/ |
| **Test** | Run Pester tests |
| **Build** | Package module to /out |
| **InstallLocal** | Install module from /out to CurrentUser |

Access via: `Terminal → Run Task → [Task Name]`

## Development Workflow

### Make Changes

1. Edit files in `src/AzLocalTSGTool/`
2. Run **Lint** task to check code quality
3. Run **Test** task to validate changes

### Test Locally

1. Run **Build** task
2. Run **InstallLocal** task
3. Test in a new PowerShell session:

```powershell
Import-Module AzLocalTSGTool -Force
Get-Command -Module AzLocalTSGTool
```

### Create a Release

1. Bump version:

```powershell
pwsh ./tools/Bump-Version.ps1 -Patch  # or -Minor, -Major
```

2. Commit changes:

```powershell
git add .
git commit -m "Bump version to X.Y.Z"
git push
```

3. Create and push tag:

```powershell
git tag -a v0.1.0 -m "Release v0.1.0"
git push origin v0.1.0
```

4. GitHub Actions automatically creates a release with a zip artifact attached

## Repository Structure

```
azlocaltsgtool/
├── .github/
│   └── workflows/
│       ├── ci.yml            # CI: lint + test on PR/push
│       └── release.yml       # Release: build + GitHub Release on v* tags
├── .vscode/
│   ├── extensions.json       # Recommended extensions
│   ├── settings.json         # PowerShell settings
│   └── tasks.json            # One-click tasks
├── src/
│   └── AzLocalTSGTool/
│       ├── AzLocalTSGTool.psd1
│       ├── AzLocalTSGTool.psm1
│       ├── Public/
│       │   ├── Get-AzLocalTSGFix.ps1
│       │   └── Update-AzLocalTSGIndex.ps1
│       └── Private/
│           ├── Cache.ps1
│           ├── ConvertTo-NormalizedTokens.ps1
│           ├── Get-FixFromMarkdown.ps1
│           ├── Invoke-FuzzyScore.ps1
│           ├── Invoke-GitHubFetch.ps1
│           ├── Invoke-ScoreCandidates.ps1
│           └── Read-LogInput.ps1
├── tests/
│   ├── Get-AzLocalTSGFix.Tests.ps1
│   └── Update-AzLocalTSGIndex.Tests.ps1
├── tools/
│   ├── Bootstrap.ps1
│   ├── Build.ps1
│   ├── Bump-Version.ps1
│   └── InstallLocal.ps1
├── CHANGELOG.md
├── LICENSE
├── README.md
└── .gitignore
```

## Cache Location

The module caches downloaded documents and the search index locally:

- **Windows**: `%LOCALAPPDATA%\AzLocalTSGTool`
- **Linux/macOS**: `~/.azlocaltsgtool`

Cache contains:
- `index.json` - Searchable index with tokens, metadata, and extracted fix steps

## How It Works

1. **Index Building** (`Update-AzLocalTSGIndex`)
   - Fetches markdown docs from GitHub and/or Azure DevOps Wiki
   - Extracts tokens, headings, and fix sections
   - Builds a local JSON index

2. **Searching** (`Get-AzLocalTSGFix`)
   - Normalizes your input (preserves dot-delimited identifiers like `Microsoft.Health.FaultType.X`)
   - Scores index entries using:
     - Exact identifier match (highest weight)
     - Token overlap (Jaccard similarity)
     - Fuzzy title matching (Jaro-Winkler)
   - Returns ranked results with confidence scores and extracted fix steps

## Security

- **No credentials hardcoded** - Use environment variables only
- **Tokens never cached** - Only document content is stored
- **HTTPS only** - All network requests use secure connections

## CI/CD

### CI Workflow (`.github/workflows/ci.yml`)

Triggers on PR and push to main:
- Bootstrap dependencies
- Run PSScriptAnalyzer (lint)
- Run Pester tests
- Upload test results

### Release Workflow (`.github/workflows/release.yml`)

Triggers on `v*` tags:
- Bootstrap dependencies
- Run tests
- Build module
- Create zip package
- Create GitHub Release with zip artifact

**Note**: This module is distributed via GitHub Releases ONLY (not PowerShell Gallery).

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test locally
4. Run lint and tests
5. Submit a pull request

## Troubleshooting

### "Index is empty"

Run `Update-AzLocalTSGIndex` first.

### GitHub API rate limit errors

Set `$env:GITHUB_TOKEN` with a GitHub personal access token.

### PSScriptAnalyzer errors

Run the **Lint** task to see issues, or manually:

```powershell
Invoke-ScriptAnalyzer -Path ./src -Recurse
```

## License

See [LICENSE](LICENSE) file.

## Links

- **Repository**: https://github.com/smitzlroy/azlocaltsgtool
- **Releases**: https://github.com/smitzlroy/azlocaltsgtool/releases
- **Issues**: https://github.com/smitzlroy/azlocaltsgtool/issues
