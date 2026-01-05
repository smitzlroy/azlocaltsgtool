# AzLocalTSGTool

[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/AzLocalTSGTool)](https://www.powershellgallery.com/packages/AzLocalTSGTool)
[![PowerShell Gallery Downloads](https://img.shields.io/powershellgallery/dt/AzLocalTSGTool)](https://www.powershellgallery.com/packages/AzLocalTSGTool)

> **Fast, intelligent troubleshooting for Azure Local and AKS enabled by Azure Arc**

Stop manually searching through docs. Get instant, ranked fixes for Azure Local and AKS Arc errors using fuzzy search and local caching.

## Why Use This?

When you hit an error during Azure Local deployment or AKS Arc operations, you need answers **fast**. This tool:

- 🔍 **Searches 147 TSG documents** from Azure/AzureLocal-Supportability in seconds
- 🎯 **Ranks results by relevance** with confidence scores
- 📋 **Shows complete fix steps** - all PowerShell commands displayed in full, no truncation
- 💡 **Meaningful context** - displays Overview/Symptoms summaries, not filler text
- 🔗 **Clickable links** - direct access to full GitHub guides
- 💾 **Works offline** after initial index build - no repeated API calls

## Installation

**Prerequisites:** PowerShell 7.0+

```powershell
Install-Module -Name AzLocalTSGTool -Repository PSGallery -Scope CurrentUser
Import-Module AzLocalTSGTool
```

That's it! The module is now available from [PowerShell Gallery](https://www.powershellgallery.com/packages/AzLocalTSGTool).

## Quick Start

### 1. Build the Search Index

First time only - fetch TSG documents from GitHub:

```powershell
Update-AzLocalTSGIndex
```

**Tip:** Set `$env:GITHUB_TOKEN` for higher API rate limits (optional)

### 2. Search for Fixes

```powershell
# Search by error text
Get-AzLocalTSGFix -ErrorText "Test-Cluster validation failed"

# Search log files
Get-AzLocalTSGFix -Path ".\deployment.log" -Top 5

# Output as JSON
Get-AzLocalTSGFix -ErrorText "AKS node NotReady" -Json
```

### 3. View Search Trends & Analytics

```powershell
# View analytics for last 30 days
Get-AzLocalTSGTrends

# Last 7 days
Get-AzLocalTSGTrends -DaysBack 7

# Export analytics to JSON
Get-AzLocalTSGTrends -DaysBack 90 -ExportPath ".\analytics.json"
```

**Analytics show:**
- 📊 Total searches and success rate
- 🔥 Most frequently searched errors  
- 📖 Most commonly matched TSGs
- ❗ Documentation gaps (errors with no/poor matches)

Use analytics to identify patterns and report documentation gaps to Microsoft!

### 4. Check Index Freshness

The module automatically checks if your index is stale when you import it. You can also manually check:

```powershell
# Check if index is up to date
Test-AzLocalTSGIndexFreshness

# Use custom staleness threshold (default is 7 days)
Test-AzLocalTSGIndexFreshness -DaysStale 14

# Silent check (returns true/false)
if (-not (Test-AzLocalTSGIndexFreshness -Quiet)) {
    Update-AzLocalTSGIndex
}
```

**The module will warn you automatically on import if your index is more than 7 days old.**

## Example Output

```powershell
PS> Get-AzLocalTSGFix -ErrorText "Test-Cluster validation failed" -Top 1

Found 1 potential fix(es)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FIX #1 - Test-ServicesVersion-Failure-Mitigation-In-HealthCheck
Match: 16%

STEP 1

  Import-Module ECEClient
  $eceClient = Create-ECEClusterServiceClient
  $stampInformation = Get-StampInformation
  ...

STEP 2
  you will need to do the following:

STEP 3

  $stampInformation = Get-StampInformation
  $stampInformation.StampVersion

... 3 more steps (see full guide)

Full guide: https://github.com/Azure/AzureLocal-Supportability/...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 Tip: Copy each step and run it in PowerShell | Use -Top 5 for more results
```

**Simple, clean output - just copy and run each step!**

## How It Works

1. **Index Building** - Fetches markdown files from Azure/AzureLocal-Supportability repo
2. **Token Normalization** - Extracts meaningful tokens (preserves dot-delimited identifiers)
3. **Fuzzy Scoring** - Uses Jaro-Winkler algorithm + Jaccard similarity for ranking
4. **Local Caching** - Stores index in `%LOCALAPPDATA%\AzLocalTSGTool` (Windows) or `~/.azlocaltsgtool` (Linux/macOS)

## Commands

| Command | Description |
|---------|-------------|
| `Update-AzLocalTSGIndex` | Fetch and index TSG documents from GitHub |
| `Get-AzLocalTSGFix` | Search for fixes by error text or log file |
| `Get-AzLocalTSGTrends` | View search analytics and identify documentation gaps |
| `Test-AzLocalTSGIndexFreshness` | Check if the local index is up to date |

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Index is empty" | Run `Update-AzLocalTSGIndex` first |
| GitHub rate limits | Set `$env:GITHUB_TOKEN` with a personal access token |
| No results found | Try different keywords or update index with `-Force` |
| Need PowerShell 7? | Install with: `winget install Microsoft.PowerShell` |

## Contributing

Contributions welcome! For development setup:

```powershell
# Clone the repository
git clone https://github.com/smitzlroy/azlocaltsgtool.git
cd azlocaltsgtool

# Install dev dependencies
.\tools\Bootstrap.ps1

# Build and test locally
.\tools\Build.ps1
.\tools\InstallLocal.ps1
Invoke-Pester -Path src/AzLocalTSGTool/Tests/
```

This repo includes Pester tests, PSScriptAnalyzer linting, and GitHub Actions CI/CD.

## License

MIT License - see [LICENSE](LICENSE) file

## Links

- **Source Repository**: [Azure/AzureLocal-Supportability](https://github.com/Azure/AzureLocal-Supportability)
- **Issues**: [Report bugs or request features](https://github.com/smitzlroy/azlocaltsgtool/issues)

---

**Built with ❤️ for Azure Local and AKS Arc operators**
