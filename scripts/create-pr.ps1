Clear-Host
$ErrorActionPreference = "Stop"

# PR merge polling settings
$PrPollIntervalSeconds = 5
$PrTimeoutMinutes = 5

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

        Write-Host "🔄 Enabling auto-merge (rebase) for the PR..." -ForegroundColor Cyan
        $MergeOutput = gh pr merge $CurrentBranch --rebase --auto 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Auto-merge enabled. PR will rebase & merge automatically once checks pass and there are no conflicts." -ForegroundColor Green

            Write-Host "⏳ Waiting for the PR to merge..." -ForegroundColor Cyan
            $Deadline = (Get-Date).AddMinutes($PrTimeoutMinutes)
            $PrState = ""

            while ((Get-Date) -lt $Deadline) {
                $PrState = (gh pr view $CurrentBranch --json state --jq ".state" 2>&1 | Out-String).Trim()
                if ($PrState -eq "MERGED" -or $PrState -eq "CLOSED") { break }
                Start-Sleep -Seconds $PrPollIntervalSeconds
            }

            if ($PrState -eq "MERGED") {
                Write-Host "✅ PR merged. Syncing branches..." -ForegroundColor Green
                . "$PSScriptRoot\sync-branches.ps1"
            }
            elseif ($PrState -eq "CLOSED") {
                Write-Host "❌ PR was closed without merging. Skipping branch sync." -ForegroundColor Red
            }
            else {
                Write-Host "⚠️ PR not merged after $PrTimeoutMinutes minutes (state: $PrState). Skipping branch sync." -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "⚠️ Could not enable auto-merge:" -ForegroundColor Yellow
            Write-Host "$MergeOutput" -ForegroundColor Yellow
        }
    }
    else {
        # If no link was generated, it failed (e.g., Not logged in / Outage)
        Write-Host "❌ GitHub CLI failed to create the PR:" -ForegroundColor Red
        Write-Host "$PrOutput" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "❌ Script encountered a critical error processing the PR." -ForegroundColor Red
    Write-Host "$($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "$($_.InvocationInfo.PositionMessage)" -ForegroundColor DarkGray
}
