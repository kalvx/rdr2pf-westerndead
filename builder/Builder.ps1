param()

$ErrorActionPreference = "Stop"

$BuilderRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $BuilderRoot "builder-config.json"

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw "Builder configuration missing: $ConfigPath"
}

$BuilderConfig = Get-Content -LiteralPath $ConfigPath -Raw |
    ConvertFrom-Json

Write-Host ""
Write-Host "============================================" -ForegroundColor DarkRed
Write-Host " RDR2PF COMPENDIUM BUILDER" -ForegroundColor Red
Write-Host "============================================" -ForegroundColor DarkRed
Write-Host ""

Write-Host "Compendium: $($BuilderConfig.compendium_path)"
Write-Host "Database:   $($BuilderConfig.database_path)"
Write-Host "Reports:    $($BuilderConfig.reports_path)"
Write-Host ""

$Modules = @(
    "01-ScanIcons.ps1",
    "02-ImportItems.ps1",
    "03-ParseCrafting.ps1",
    "04-ParseStores.ps1",
    "05-BuildRelationships.ps1",
    "06-ValidateDatabase.ps1",
    "07-GenerateWiki.ps1",
    "08-BuildSearch.ps1"
)

foreach ($ModuleName in $Modules) {
    $ModulePath = Join-Path $BuilderRoot "modules\$ModuleName"

    if (Test-Path -LiteralPath $ModulePath) {
        Write-Host "[RUN] $ModuleName" -ForegroundColor Cyan
        & $ModulePath -BuilderConfig $BuilderConfig
    }
    else {
        Write-Host "[SKIP] $ModuleName has not been created yet." -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "Builder finished." -ForegroundColor Green
