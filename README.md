# AzLocalTSGTool

> **Fast, intelligent troubleshooting for Azure Local and AKS enabled by Azure Arc**

Stop manually searching through docs. Get instant, ranked fixes for Azure Local and AKS Arc errors using fuzzy search and local caching.

## Why Use This?

When you hit an error during Azure Local deployment or AKS Arc operations, you need answers **fast**. This tool:

- 🔍 **Searches 167+ TSG documents** from Azure/AzureLocal-Supportability in seconds
- 🎯 **Ranks results by relevance** with confidence scores and match explanations  
- 💾 **Works offline** after initial index build - no repeated API calls
- 🧠 **Smart token matching** - handles error codes, fault types, and technical identifiers
- ⚡ **Extracts actual fix commands** - shows PowerShell commands from code blocks, not just links

## Installation

**Prerequisites:** PowerShell 7.0+

### Install from PowerShell Gallery

```powershell
Install-Module -Name AzLocalTSGTool -Repository PSGallery -Scope CurrentUser
Import-Module AzLocalTSGTool
```

### Install from Source

```powershell
# Clone the repo
git clone https://github.com/smitzlroy/azlocaltsgtool.git
cd azlocaltsgtool

# Build and install
.\tools\Build.ps1
.\tools\InstallLocal.ps1

# Load the module
Import-Module AzLocalTSGTool
```

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

## Example Output

```powershell
PS> Get-AzLocalTSGFix -ErrorText "Test-Cluster validation failed" -Top 1

==> Found 1 matching issue(s):

[1] Test-ServicesVersion-Failure-Mitigation-In-HealthCheck
    Confidence: 16%
    Match:      Token overlap: 2/4 query tokens matched | Fuzzy title match: 77%
    Fix:        We will need to run this command
    Steps:
      1. Run PowerShell: Import-Module ECEClient
         $eceClient = Create-ECEClusterServiceClient
         $stampInformation = Get-StampInformation...
      2. you will need to do the following:
      3. Run PowerShell: $stampInformation = Get-StampInformation
         $stampInformation.StampVersion...
         ... (3 more steps, see URL)
    Read more:  https://github.com/Azure/AzureLocal-Supportability/blob/main/TSG/...

==> Next Steps:
  1. Review the results above (highest confidence = best match)
  2. Click the blue 'Read more' URLs for full troubleshooting steps
  3. Follow the documented fixes
```

**Key Feature:** The tool extracts actual PowerShell commands from TSG articles, not just links!

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

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Index is empty" | Run `Update-AzLocalTSGIndex` first |
| GitHub rate limits | Set `$env:GITHUB_TOKEN` with a personal access token |
| No results found | Try different keywords or update index with `-Force` |

## Development

Contributions welcome! This repo includes:

- ✅ Pester tests in `src/AzLocalTSGTool/Tests/`
- ✅ CI/CD via GitHub Actions  
- ✅ VS Code tasks for quick workflows

```powershell
# Clone and setup
git clone https://github.com/smitzlroy/azlocaltsgtool.git
cd azlocaltsgtool
code .

# Install dev dependencies
.\tools\Bootstrap.ps1

# Build and test
.\tools\Build.ps1
.\tools\InstallLocal.ps1

# Run tests
Invoke-Pester -Path src/AzLocalTSGTool/Tests/
```

## License

MIT License - see [LICENSE](LICENSE) file

## Links

- **Source Repository**: [Azure/AzureLocal-Supportability](https://github.com/Azure/AzureLocal-Supportability)
- **Issues**: [Report bugs or request features](https://github.com/smitzlroy/azlocaltsgtool/issues)

---

**Built with ❤️ for Azure Local and AKS Arc operators**
