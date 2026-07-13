param([Parameter(Mandatory=$true)][string]$Name,[Parameter(Mandatory=$true)][string]$ConsoleId,[string]$Category="Unknown",[string]$Status="Untested",[string]$Purpose="",[string]$Notes="")
$Root=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$File=Join-Path $Root "data\items.json"
$Rows=@(Get-Content -LiteralPath $File -Raw|ConvertFrom-Json)
$Rows += [pscustomobject]@{name=$Name;console_id=$ConsoleId;category=$Category;status=$Status;purpose=$Purpose;notes=$Notes}
$Rows|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $File -Encoding UTF8
Write-Host "Added $Name ($ConsoleId)" -ForegroundColor Green
