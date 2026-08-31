$ErrorActionPreference = "Stop"

$CurrentBranch = (git branch --show-current).Trim()

if ($CurrentBranch -eq "main") {
    Write-Host "⚠️ You are on 'main'. Switch branches first." -ForegroundColor Yellow
    Exit
}

Write-Host "🚀 Pushing current commits to GitHub..." -ForegroundColor Cyan
git push origin $CurrentBranch --force-with-lease

# Grab the latest commit message dynamically from your history
$LatestCommitMessage = (git log -1 --pretty=%s).Trim()

Write-Host "📝 Generating Pull Request on GitHub..." -ForegroundColor Cyan

# Execute the CLI command and catch any text output or hidden error codes
try {
    # 2>&1 redirects hidden CLI error streams so PowerShell can read them
    $PrOutput = gh pr create --base main --head $CurrentBranch --title "$LatestCommitMessage" --body "Automated submission from BlogDrafts pipeline." 2>&1
    
    # Check if the output contains a web URL link (proving success)
    if ($PrOutput -match "https://github.com") {
        Write-Host "✅ Pull Request created successfully!" -ForegroundColor Green
        Write-Host "🔗 Link: $PrOutput" -ForegroundColor Cyan
    } else {
        # If no link was generated, it failed (e.g., Not logged in / Outage)
        Write-Host "❌ GitHub CLI failed to create the PR:" -ForegroundColor Red
        Write-Host "$PrOutput" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "❌ Script encountered a critical error processing the PR." -ForegroundColor Red
}
