# Install all clawhub skills
$queries = @("openclaw","web","search","skill","api","data","file","code","ai","chat","message","browser","automation","script","tool","amazon","google","microsoft","apple","twitter","telegram","discord","notion","github","git","image","video","audio","text","pdf","doc","server","cloud","aws","azure","docker","linux","windows","mac","ios","android","phone","sms","email","mail","calendar","reminder","weather","news","crypto","btc","eth","trading","invest","stock","market","ecommerce","shop","store","pay","payment","bank","money","card","amazon","ebay","aliexpress","taobao","jd","pinduoduo","wechat","feishu","slack","zoom","meeting","zoom","video")

$skills = @{}

foreach ($q in $queries) {
    Write-Host "Searching: $q"
    $output = npx clawhub@latest search $q --limit 20 2>&1 | Out-String
    $lines = $output -split "`n"
    foreach ($line in $lines) {
        if ($line -match '^([a-z0-9][a-z0-9-]+)\s+[A-Z]') {
            $slug = $Matches[1]
            $skills[$slug] = $true
        }
    }
}

$skillList = $skills.Keys | Sort-Object
Write-Host "Found $($skillList.Count) unique skills"
Write-Host ($skillList -join ", ")

# Install with delay to avoid rate limiting
$installed = 0
$failed = 0
foreach ($skill in $skillList) {
    Write-Host "Installing: $skill"
    $errLog = "$env:TEMP\install_err_$PID.log"
    npx clawhub@latest install $skill --force 2> $errLog > $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK]"
        $installed++
    } else {
        Write-Host "  [FAILED]"
        $failed++
        if ((Get-Item $errLog -ErrorAction SilentlyContinue).Length -gt 0) {
            Get-Content $errLog | Select-Object -First 3
        }
    }
    Remove-Item $errLog -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

Write-Host "`n========================================"
Write-Host "Total found: $($skillList.Count)"
Write-Host "Installed: $installed"
Write-Host "Failed: $failed"
Write-Host "========================================"
