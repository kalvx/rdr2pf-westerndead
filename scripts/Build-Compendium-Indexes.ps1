param([string]$WikiRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = "Stop"
Write-Host "RDR2PF Compendium index structure is installed at:" -ForegroundColor Cyan
Write-Host $WikiRoot -ForegroundColor Yellow
Write-Host "Use the future server-data sweep to rebuild items, recipes, and cross-links." -ForegroundColor Green
Start-Process (Join-Path $WikiRoot "index.html")
