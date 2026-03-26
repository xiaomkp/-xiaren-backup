# Robust skill installer - handles errors and rate limits
param(
    [int]$DelayMs = 2000,
    [int]$MaxRetries = 3
)

$skillsDir = "C:\Users\admin\.openclaw\workspace\skills"
$logFile = "$env:TEMP\clawhub_install_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

$alreadyInstalled = @()
if (Test-Path "$skillsDir\.clawhublock.json") {
    $lock = Get-Content "$skillsDir\.clawhublock.json" -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($lock) {
        $alreadyInstalled = $lock.installed
    }
}

$skillsToInstall = @(
    "a2a-shib-payments","abstract-onboard","abstract-toolkit","acedatacloud-google-search",
    "activity-log-detector","adb-android","adb-claw","adb-controller","afrexai-automation-strategy",
    "agent-browser-cli","browser-automation","ecommerce-openclaw-skills","openclaw-cli",
    "openclaw-docs-cn","openclaw-healthcheck","openclaw-ops-guardrails","openclaw-power-ops",
    "openclaw-troubleshoot-cn","playwright-npx","web-search-free"
)

# Add more skills from search
$queries = @("a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","0","1","2","3","4","5","6","7","8","9",
    "openclaw","web","search","skill","api","data","file","code","ai","chat","message","browser","automation","script","tool",
    "amazon","google","microsoft","apple","twitter","telegram","discord","notion","github","git","image","video","audio",
    "ecommerce","shop","store","pay","payment","bank","money","card","ebay","aliexpress","taobao","jd","pinduoduo","wechat","feishu","slack","zoom",
    "crypto","btc","eth","trading","invest","stock","market","blockchain","defi","nft","gaming","social","content","writing","marketing",
    "cloud","aws","azure","docker","linux","windows","mac","ios","android","phone","sms","email","mail","calendar","reminder","weather","news",
    "database","sql","nosql","mysql","postgres","mongodb","redis","analytics","bi","dashboard","ml","nlp","cv","ocr","translation","voice",
    "devops","kubernetes","terraform","ansible","monitoring","logging","ci","cd","security","privacy","encryption","vpn","proxy","dns",
    "serverless","function","lambda","edge","cdn","cache","hosting","domain","server","client","protocol","api","gateway","proxy",
    "blockchain","defi","crypto","wallet","staking","mining","trading","exchange","forex","commodity","gold","oil","futures","options",
    "realestate","property","travel","hotel","flight","restaurant","food","delivery","health","medical","fitness","sports",
    "music","podcast","streaming","movie","tv","game","video","audio","image","photo","camera","gallery",
    "social","community","forum","blog","cms","website","landing","page","seo","ads","affiliate","marketing",
    "crm","erp","hr","finance","accounting","invoice","payment","stripe","paypal","alipay","wechatpay","banking",
    "ecommerce"," Dropshipping","logistics","shipping","delivery","inventory","warehouse","supply","chain"
)

$allSkills = @{}
Write-Host "Searching for skills..."
foreach ($q in $queries) {
    Write-Host "  Searching: $q"
    try {
        $output = npx clawhub@latest search $q --limit 30 2>&1 | Out-String
        $lines = $output -split "`n"
        foreach ($line in $lines) {
            if ($line -match '^([a-z0-9][a-z0-9-]+)\s+[A-Z]') {
                $slug = $Matches[1]
                $allSkills[$slug] = $true
            }
        }
    } catch {
        Write-Host "    Search error: $_"
    }
    Start-Sleep -Milliseconds 300
}

$skillList = $allSkills.Keys | Sort-Object
$total = $skillList.Count
Write-Host "Total unique skills found: $total"

$installed = $alreadyInstalled.Count
$failed = 0
$failedList = @()
$retryCount = @{}

$counter = 0
foreach ($skill in $skillList) {
    $counter++
    if ($alreadyInstalled -contains $skill) {
        continue
    }
    
    if ($skill -eq "a2a-market-stripe-payment") {
        Write-Host "[$counter/$total] [$skill] SKIP (known bad)"
        continue
    }
    
    Write-Host "[$counter/$total] [$installed installed, $failed failed] Installing: $skill"
    
    $success = $false
    $retry = 0
    
    while (-not $success -and $retry -lt $MaxRetries) {
        try {
            $errLog = "$env:TEMP\install_err.log"
            $outLog = "$env:TEMP\install_out.log"
            
            $process = Start-Process -FilePath "npx" -ArgumentList "clawhub@latest","install","$skill","--force" -NoNewWindow -Wait -PassThru -RedirectStandardError $errLog -RedirectStandardOutput $outLog -ErrorAction Stop
            
            if ($process.ExitCode -eq 0) {
                $success = $true
                $installed++
                Write-Host "  [OK]"
            } else {
                $errContent = Get-Content $errLog -Raw -ErrorAction SilentlyContinue
                if ($errContent -match "already exists" -or $errContent -match "already installed") {
                    $success = $true
                    $installed++
                    Write-Host "  [EXISTS]"
                } elseif ($errContent -match "Rate limit") {
                    Write-Host "  [RATE LIMIT - waiting 10s]"
                    Start-Sleep -Seconds 10
                    $retry++
                } else {
                    throw "Exit code $($process.ExitCode)"
                }
            }
        } catch {
            $retry++
            if ($retry -lt $MaxRetries) {
                Write-Host "  [RETRY $retry/$MaxRetries]"
                Start-Sleep -Seconds 3
            }
        } finally {
            Remove-Item $errLog,$outLog -ErrorAction SilentlyContinue
        }
    }
    
    if (-not $success) {
        $failed++
        $failedList += $skill
        Write-Host "  [FAILED after $MaxRetries retries]"
    }
    
    # Progress log
    "$counter|$total|$installed|$failed|$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Add-Content $logFile
    
    # Save lock file periodically
    if ($counter % 100 -eq 0) {
        @{installed = $alreadyInstalled + @($skillList[0..($counter-1)])} | ConvertTo-Json | Set-Content "$skillsDir\.clawhublock.json"
    }
    
    Start-Sleep -Milliseconds $DelayMs
}

# Final save
@{installed = $skillList} | ConvertTo-Json | Set-Content "$skillsDir\.clawhublock.json"

$summary = @"
========================================
INSTALL COMPLETE
Total found: $total
Installed: $installed
Failed: $failed
Log: $logFile
========================================
"@
Write-Host $summary
