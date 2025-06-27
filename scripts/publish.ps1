# Gnos Braille System - Manual Publishing Script (PowerShell)
# Usage: .\scripts\publish.ps1 [version] [environment]

param(
    [string]$Version = "v1.0.0",
    [string]$Environment = "production"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Publishing Gnos Braille System $Version to $Environment" -ForegroundColor Green

# Validate inputs
if ($Version -notmatch "^v\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?$") {
    Write-Host "❌ Invalid version format. Use format: v1.0.0 or v1.0.0-beta.1" -ForegroundColor Red
    exit 1
}

if ($Environment -notmatch "^(production|staging)$") {
    Write-Host "❌ Invalid environment. Use 'production' or 'staging'" -ForegroundColor Red
    exit 1
}

# Check if tag already exists
try {
    git rev-parse $Version 2>$null | Out-Null
    Write-Host "❌ Tag $Version already exists!" -ForegroundColor Red
    Write-Host "Existing tags:" -ForegroundColor Yellow
    git tag -l | Select-Object -Last 5
    exit 1
} catch {
    # Tag doesn't exist, which is what we want
}

# Ensure we're on main branch for production
if ($Environment -eq "production") {
    $CurrentBranch = git rev-parse --abbrev-ref HEAD
    if ($CurrentBranch -ne "main") {
        Write-Host "❌ Production releases must be from main branch (currently on $CurrentBranch)" -ForegroundColor Red
        exit 1
    }
}

# Check if working directory is clean
$GitStatus = git status --porcelain
if ($GitStatus) {
    Write-Host "❌ Working directory is not clean. Commit or stash changes first." -ForegroundColor Red
    git status --short
    exit 1
}

# Update version in pubspec.yaml
Write-Host "📝 Updating version in pubspec.yaml..." -ForegroundColor Blue
$PubspecContent = Get-Content pubspec.yaml
$NewVersion = $Version.TrimStart('v')
$Timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$PubspecContent = $PubspecContent -replace "^version: .*", "version: $NewVersion+$Timestamp"
$PubspecContent | Set-Content pubspec.yaml

# Commit version update
git add pubspec.yaml
git commit -m "Bump version to $Version"

# Create and push tag
Write-Host "🏷️  Creating tag $Version..." -ForegroundColor Blue
$TagMessage = @"
Release $Version

Environment: $Environment
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')
Commit: $(git rev-parse HEAD)
"@

git tag -a $Version -m $TagMessage

Write-Host "⬆️  Pushing to remote..." -ForegroundColor Blue
git push origin main
git push origin $Version

Write-Host "✅ Release $Version initiated!" -ForegroundColor Green
Write-Host ""
Write-Host "🔗 Monitor progress at:" -ForegroundColor Cyan
Write-Host "   https://github.com/Kabbalist-sys/gnos-braille-system/actions"
Write-Host ""
Write-Host "📦 Release will be available at:" -ForegroundColor Cyan
Write-Host "   https://github.com/Kabbalist-sys/gnos-braille-system/releases/tag/$Version"

if ($Environment -eq "production") {
    Write-Host ""
    Write-Host "🤖 Google Play Store publishing will begin automatically" -ForegroundColor Yellow
    Write-Host "🌐 Web app will be deployed to production" -ForegroundColor Yellow
}
