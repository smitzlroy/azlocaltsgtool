# Changelog

All notable changes to AzLocalTSGTool will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-01-05

### Added
- Initial release of AzLocalTSGTool
- `Update-AzLocalTSGIndex` cmdlet for building local search index
  - Support for GitHub source (Azure/AzureLocal-Supportability)
  - Local caching for offline access
- `Get-AzLocalTSGFix` cmdlet for searching known issues
  - Text input via `-ErrorText` parameter
  - Log file input via `-Path` parameter
  - Confidence scoring with match explanations
  - Automatic fix step extraction from markdown
  - JSON output support for automation
- Token normalization with support for dot-delimited identifiers
- Fuzzy matching using Jaro-Winkler algorithm
- VS Code workspace configuration
  - Recommended extensions
  - PowerShell settings
  - One-click tasks (Bootstrap, Lint, Test, Build, InstallLocal)
- Development automation scripts
  - `tools/Bootstrap.ps1` - Install dependencies
  - `tools/Build.ps1` - Package module
  - `tools/InstallLocal.ps1` - Install to user profile
  - `tools/Bump-Version.ps1` - Version management
- CI/CD workflows
  - `ci.yml` - Automated lint and test on PR/push
  - `release.yml` - Automated GitHub Releases on version tags
- Pester tests for public cmdlets
- Comprehensive README documentation

[Unreleased]: https://github.com/smitzlroy/azlocaltsgtool/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/smitzlroy/azlocaltsgtool/releases/tag/v0.1.0
