# Exit instantly if any command fails
$ErrorActionPreference = "Stop"

Write-Host "🔄 Switching to main branch..." -ForegroundColor Cyan
git checkout main

Write-Host "📥 Pulling latest changes from GitHub main..." -ForegroundColor Cyan
git pull origin main

Write-Host "🔄 Switching to BlogDrafts branch..." -ForegroundColor Cyan
git checkout BlogDrafts

Write-Host "💥 Resetting BlogDrafts to match main perfectly..." -ForegroundColor Cyan
git reset --hard main

Write-Host "🚀 Force pushing clean state up to GitHub..." -ForegroundColor Cyan
git push origin BlogDrafts --force-with-lease

Write-Host "✅ Sync complete! BlogDrafts is now identical to main." -ForegroundColor Green
