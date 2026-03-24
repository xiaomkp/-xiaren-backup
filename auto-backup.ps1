# auto-backup.ps1 - 虾仁记忆自动备份脚本
# 每次运行自动 commit 并 push 到 GitHub

$repo = "C:\Users\admin\.openclaw\workspace"

Set-Location $repo

# 检查是否有变更
$status = git status --porcelain
if ($status) {
    git add .
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    git commit -m "自动备份记忆 - $timestamp"
    git push origin master
    Write-Host "[$timestamp] 备份成功"
} else {
    Write-Host "没有变更，无需备份"
}
