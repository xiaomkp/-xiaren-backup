# Curated skill installation for 虾仁

$curatedSkills = @(
    # OpenClaw core
    "openclaw-cli", "openclaw-healthcheck", "openclaw-power-ops", "openclaw-ops-guardrails",
    "openclaw-docs-cn", "openclaw-troubleshoot-cn", "openclaw-quick-start", "openclaw-update-check",
    
    # Browser automation (critical for 闲鱼)
    "browser-automation", "browser-automation-1", "browser-automation-v2", "agent-browser-cli",
    "playwright-npx", "web-automation-helper", "web-browsing", "web-scraping",
    
    # Web search
    "web-search-free", "web-search-minimax", "bailian-web-search", "tavily-search-yourname",
    "google-search", "baidu-search-1-1-0",
    
    # Ecommerce - 闲鱼/淘宝/京东/拼多多
    "ecommerce-manager-claw", "ecommerce-product-picker", "ecommerce-scraper",
    "taobao-query", "taobao-price-monitor", "jd-shopping", "pinduoduo", "pinduoduo-deal-finder",
    "amazon-product-fetcher", "amazon-scraper",
    
    # Crypto trading
    "crypto-trading-bot-automaton", "binance-spot-trader", "okx-cex-trade",
    "crypto-price-checker", "crypto-market-data", "crypto-arbitrage",
    
    # Feishu tools
    "feishu-doc-extended", "feishu-card-sender", "feishu-file-sender", "feishu-meeting",
    "feishu-agent", "feishu-toolkit", "feishu-calendar",
    
    # Productivity
    "calendar-manager", "reminder-agent", "meeting-notes-pro", "email-marketing",
    "notion-api", "notion-manager",
    
    # Image/Video
    "image-process", "image-read", "video-download-archive", "video-translator",
    
    # AI tools
    "ai-automation-consulting", "self-evolving-skill", "skill-creator"
)

$installed = 0
$failed = 0
$failList = @()

foreach ($skill in $curatedSkills) {
    Write-Host "Installing: $skill"
    $errLog = "$env:TEMP\install_err_$PID.log"
    npx clawhub@latest install $skill --force 2> $errLog > $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK]"
        $installed++
    } else {
        Write-Host "  [FAILED]"
        $failed++
        $failList += $skill
    }
    Remove-Item $errLog -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}

Write-Host "`n========================================"
Write-Host "Installed: $installed"
Write-Host "Failed: $failed"
if ($failList.Count -gt 0) {
    Write-Host "Failed skills: $($failList -join ', ')"
}
Write-Host "========================================"
