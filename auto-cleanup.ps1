# auto-cleanup.ps1 - Xiaren System Cleanup Script

$repo = "C:\Users\admin\.openclaw\workspace"
$cutoff = (Get-Date).AddDays(-1)

Write-Host "=== Xiaren Cleanup ==="
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Write-Host ""

# 1. Windows temp files (keep files from last 24 hours)
$tempFiles = Get-ChildItem $env:TEMP -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $cutoff }
$tempSize = ($tempFiles | Measure-Object -Property Length -Sum).Sum / 1MB
$tempCount = $tempFiles.Count
Write-Host "[TEMP] Removing $tempCount files (~$([math]::Round($tempSize, 1)) MB)"
$tempFiles | Remove-Item -Force -ErrorAction SilentlyContinue
Write-Host "[TEMP] Done"

# 2. npm cache
Write-Host "[npm] Verifying cache..."
npm cache verify 2>$null | Out-Null
Write-Host "[npm] Done"

# 3. OpenClaw logs (keep last 7 days only)
$logCutoff = (Get-Date).AddDays(-7)
$logFiles = Get-ChildItem "$env:LOCALAPPDATA\Temp\openclaw" -Filter "*.log" -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $logCutoff }
$logSize = ($logFiles | Measure-Object -Property Length -Sum).Sum / 1MB
$logCount = $logFiles.Count
if ($logCount -gt 0) {
    Write-Host "[OpenClaw Logs] Removing $logCount old logs (~$([math]::Round($logSize, 1)) MB)"
    $logFiles | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "[OpenClaw Logs] Done"
} else {
    Write-Host "[OpenClaw Logs] Nothing to clean"
}

# 4. Auto backup memory
Set-Location $repo
$status = git status --porcelain
if ($status) {
    git add .
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    git commit -m "Auto backup - $timestamp"
    git push origin master
    Write-Host "[Backup] Pushed"
} else {
    Write-Host "[Backup] No changes"
}

Write-Host ""
Write-Host "=== Cleanup Complete ==="
