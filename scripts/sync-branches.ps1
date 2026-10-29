param(
    # Workflow polling settings
    [int]$WorkflowPollIntervalSeconds = 10,
    [int]$WorkflowTimeoutMinutes = 5,
    # How long to wait for a run to appear before assuming none was triggered
    [int]$WorkflowStartGraceSeconds = 60
)

# Exit instantly if any command fails
$ErrorActionPreference = "Stop"

function Sync-BlogDrafts {
    Write-Host "🔄 Switching to BlogDrafts branch..." -ForegroundColor Cyan
    git checkout BlogDrafts

    Write-Host "💥 Resetting BlogDrafts to match main perfectly..." -ForegroundColor Cyan
    git reset --hard main

    Write-Host "🚀 Force pushing clean state up to GitHub..." -ForegroundColor Cyan
    git push origin BlogDrafts --force-with-lease
}

Write-Host "🔄 Switching to main branch..." -ForegroundColor Cyan
git checkout main

Write-Host "📥 Pulling latest changes from GitHub main..." -ForegroundColor Cyan
git pull origin main

$Sha = (git rev-parse main).Trim()
$SyncedSha = $Sha

Sync-BlogDrafts
Write-Host "✅ Branches synced. BlogDrafts is now identical to main." -ForegroundColor Green

Write-Host "⏳ Waiting for GitHub workflows on main (blog post publish)..." -ForegroundColor Cyan
$Deadline = (Get-Date).AddMinutes($WorkflowTimeoutMinutes)
$ShaSeen = Get-Date

while ($true) {
    if ((Get-Date) -gt $Deadline) {
        throw "Timed out after $WorkflowTimeoutMinutes minutes waiting for workflows on $Sha."
    }

    $Runs = @(gh run list --branch main --commit $Sha --json "name,status,conclusion" | ConvertFrom-Json)
    if ($LASTEXITCODE -ne 0) { throw "gh run list failed." }

    if ($Runs.Count -eq 0) {
        if (((Get-Date) - $ShaSeen).TotalSeconds -ge $WorkflowStartGraceSeconds) {
            Write-Host "ℹ️ No workflow runs found for $($Sha.Substring(0, 7)); nothing to wait for." -ForegroundColor Yellow
            break
        }
        Start-Sleep -Seconds $WorkflowPollIntervalSeconds
        continue
    }

    if ($Runs | Where-Object { $_.status -ne "completed" }) {
        Start-Sleep -Seconds $WorkflowPollIntervalSeconds
        continue
    }

    $Failed = @($Runs | Where-Object { $_.conclusion -notin @("success", "skipped") })
    if ($Failed.Count -gt 0) {
        throw "Workflow failed on $($Sha.Substring(0, 7)): $(($Failed | ForEach-Object { "$($_.name) [$($_.conclusion)]" }) -join ', ')"
    }

    # The publish workflow commits published.json back to main; fast-forward local main (not checked out) and wait on that commit's runs too
    git fetch origin main:main
    $NewSha = (git rev-parse main).Trim()
    if ($NewSha -eq $Sha) {
        Write-Host "✅ Workflows succeeded; blog post published." -ForegroundColor Green
        break
    }

    Write-Host "📥 main moved to $($NewSha.Substring(0, 7)); checking its workflows..." -ForegroundColor Cyan
    $Sha = $NewSha
    $ShaSeen = Get-Date
}

# main moved while we waited (e.g. the published-index commit), so BlogDrafts is behind again
if ((git rev-parse main).Trim() -ne $SyncedSha) {
    Write-Host "🔁 main changed after the first sync; syncing BlogDrafts again..." -ForegroundColor Cyan
    Sync-BlogDrafts
    Write-Host "✅ Sync complete! BlogDrafts is now identical to main." -ForegroundColor Green
}
