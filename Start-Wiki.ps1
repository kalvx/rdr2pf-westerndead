param([int]$Port = 8123)
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root
Write-Host "Western Dead Wiki - RDR2PF Release" -ForegroundColor Yellow
Write-Host "URL: http://localhost:$Port" -ForegroundColor Green
Start-Process "http://localhost:$Port"
python -m http.server $Port
