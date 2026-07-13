param([Parameter(Mandatory=$true)][string]$Location,[Parameter(Mandatory=$true)][double]$X,[Parameter(Mandatory=$true)][double]$Y,[Parameter(Mandatory=$true)][double]$Z,[string]$Status="Reference",[string]$Notes="")
$Root=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$File=Join-Path $Root "data\coordinates.json"
$Rows=@(Get-Content -LiteralPath $File -Raw|ConvertFrom-Json)
$Rows += [pscustomobject]@{location=$Location;x=$X;y=$Y;z=$Z;status=$Status;notes=$Notes}
$Rows|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $File -Encoding UTF8
Write-Host "Added coordinate: $Location" -ForegroundColor Green
