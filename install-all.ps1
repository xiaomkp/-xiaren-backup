# Install ALL skills from clawhub (1267 total)
# Will skip already installed ones

$queries = @("a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","0","1","2","3","4","5","6","7","8","9","openclaw","web","search","skill","api","data","file","code","ai","chat","message","browser","automation","script","tool","amazon","google","microsoft","apple","twitter","telegram","discord","notion","github","git","image","video","audio","text","pdf","doc","server","cloud","aws","azure","docker","linux","windows","mac","ios","android","phone","sms","email","mail","calendar","reminder","weather","news","crypto","btc","eth","trading","invest","stock","market","ecommerce","shop","store","pay","payment","bank","money","card","ebay","aliexpress","taobao","jd","pinduoduo","wechat","feishu","slack","zoom","meeting","blockchain","defi","nft","gaming","social","content","writing","marketing","seo","ads","affiliate"," Dropshipping","logistics","erp","crm","hr","finance","accounting","invoice","stripe","paypal","alipay","wechatpay","exchange","forex","commodity","gold","oil","futures","options","mutualfund","bond","credit","loan","insurance","realestate","property","travel","hotel","flight","restaurant","food","delivery","health","medical","fitness","sports","music","podcast","streaming","movie","tv","game","wallet","mining","staking","yield","farming","dao","governance","identity","auth","security","privacy","encryption","vpn","proxy","dns","domain","hosting","serverless","function","lambda","edge","cdn","cache","database","sql","nosql","mysql","postgres","mongodb","redis","elasticsearch","analytics","bi","dashboard","report","chart","graph","visualization","ml","dl","nlp","cv","ocr","tts","stt","translation","voice","automation","flow","workflow","pipeline","ci","cd","devops","gitops","kubernetes","terraform","ansible","monitoring","logging","alerting","incident","oncall","sre","platform","infra","lowcode","saas","paas","iaas","b2b","b2c","c2c","marketplace","ecosystem","integration","webhook","event","stream","realtime","websocket","graphql","rest","grpc","sdk","cli","gui","desktop","mobile","pwa")
$allSkills = @{}
$logFile = "$env:TEMP\clawhub_install_log.txt"

foreach ($q in $queries) {
    Write-Host "Searching: $q"
    $output = npx clawhub@latest search $q --limit 30 2>&1 | Out-String
    $lines = $output -split "`n"
    foreach ($line in $lines) {
        if ($line -match '^([a-z0-9][a-z0-9-]+)\s+[A-Z]') {
            $slug = $Matches[1]
            $allSkills[$slug] = $true
        }
    }
    "$q`: $($allSkills.Count) skills found" | Add-Content $logFile
    Start-Sleep -Milliseconds 500
}

$skillList = $allSkills.Keys | Sort-Object
$total = $skillList.Count
Write-Host "Total unique skills found: $total"
"$total skills found" | Add-Content $logFile

# Install all
$installed = 0
$failed = 0
$alreadyExists = 0
$skipList = @("a2a-market-stripe-payment")

$counter = 0
foreach ($skill in $skillList) {
    $counter++
    if ($skipList -contains $skill) {
        Write-Host "[SKIP] $skill (known bad)"
        continue
    }
    
    Write-Host "[$counter/$total] Installing: $skill"
    $errLog = "$env:TEMP\install_err_$PID.log"
    $outLog = "$env:TEMP\install_out_$PID.log"
    npx clawhub@latest install $skill --force 2> $errLog > $outLog
    if ($LASTEXITCODE -eq 0) {
        $installed++
        Write-Host "  [OK]"
    } else {
        $errContent = Get-Content $errLog -Raw -ErrorAction SilentlyContinue
        if ($errContent -match "already exists" -or $errContent -match "already installed") {
            $alreadyExists++
            Write-Host "  [EXISTS]"
        } else {
            $failed++
            Write-Host "  [FAILED]"
            "$skill`: $errContent" | Add-Content $logFile
        }
    }
    Remove-Item $errLog,$outLog -ErrorAction SilentlyContinue
    
    if ($counter % 50 -eq 0) {
        "Progress: $counter/$total, Installed: $installed, Failed: $failed, Existed: $alreadyExists" | Add-Content $logFile
    }
    
    Start-Sleep -Milliseconds 1500
}

$summary = "========================================
INSTALL COMPLETE
Total found: $total
Installed: $installed
Already existed: $alreadyExists
Failed: $failed
========================================"
Write-Host $summary
$summary | Add-Content $logFile
