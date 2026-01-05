# Publishing to PowerShell Gallery

## Prerequisites

1. **PowerShell Gallery Account**
   - Sign in at https://www.powershellgallery.com with your Microsoft account
   - Navigate to **API Keys** section
   - Create a new API key with push permissions

2. **Build the Module**
   ```powershell
   .\tools\Build.ps1
   ```

## Steps to Publish

### 1. Set API Key

```powershell
$env:PSGALLERY_API_KEY = "your-api-key-here"
```

**Security Note:** Never commit API keys to git. Use environment variables or secure vaults.

### 2. Bump Version (if needed)

```powershell
# Increment patch version (0.1.0 -> 0.1.1)
.\tools\Bump-Version.ps1 -Patch

# Or minor version (0.1.0 -> 0.2.0)
.\tools\Bump-Version.ps1 -Minor

# Or major version (0.1.0 -> 1.0.0)
.\tools\Bump-Version.ps1 -Major
```

### 3. Rebuild with New Version

```powershell
.\tools\Build.ps1
```

### 4. Test Locally

```powershell
.\tools\InstallLocal.ps1
Import-Module AzLocalTSGTool -Force
Get-Command -Module AzLocalTSGTool
```

### 5. Publish to Gallery

```powershell
.\tools\Publish-ToPSGallery.ps1
```

### 6. Verify Publication

After a few minutes, check:
- https://www.powershellgallery.com/packages/AzLocalTSGTool
- Test installation: `Install-Module -Name AzLocalTSGTool -Repository PSGallery -Scope CurrentUser`

## Troubleshooting

### "Version already exists"
You cannot republish the same version. Bump the version number first.

### "API key invalid"
Regenerate the API key in PowerShell Gallery and update `$env:PSGALLERY_API_KEY`.

### "Module validation failed"
Ensure the manifest (`.psd1`) is valid:
```powershell
Test-ModuleManifest -Path .\out\AzLocalTSGTool\AzLocalTSGTool.psd1
```

## After Publishing

1. **Create Git Tag**
   ```powershell
   git tag -a v0.1.0 -m "Release v0.1.0"
   git push origin v0.1.0
   ```

2. **Update README**
   - Change "Coming Soon" to the actual Install-Module command
   - Update installation instructions

3. **Create GitHub Release**
   - GitHub Actions will automatically create a release on `v*` tags
   - Or manually create at https://github.com/smitzlroy/azlocaltsgtool/releases
