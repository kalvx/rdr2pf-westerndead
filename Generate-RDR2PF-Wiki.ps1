<#
.SYNOPSIS
    RDR2PF Wiki Generator v2

.DESCRIPTION
    Idempotent wiki generator for H:\rdr2pf-westerndead.

    Current managed output:
      - Removes Hunting from the main index navigation.
      - Keeps Hunting under Jobs & Professions.
      - Generates a searchable complete item registry from data\item-ids.txt.
      - Links the registry from the existing Items page.
      - Keeps Character progression information on the Character page.
      - Validates local HTML links after generation.
      - Creates a timestamped backup before changing existing files.

    IMPORTANT:
      Run this file with PowerShell's -File option.
      Do not paste it into the console line by line.
#>

[CmdletBinding()]
param(
    [string]$Root = "H:\rdr2pf-westerndead",
    [switch]$SkipLinkCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupRoot = Join-Path $Root "wiki-update-backups\$Timestamp"

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content
    )

    $Parent = Split-Path -Parent $Path
    if ($Parent -and -not (Test-Path -LiteralPath $Parent)) {
        New-Item -ItemType Directory -Path $Parent -Force | Out-Null
    }

    $Encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $Encoding)
}

function Backup-WikiFile {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $Relative = $Path.Substring($Root.Length).TrimStart("\")
    $Destination = Join-Path $BackupRoot $Relative
    $DestinationFolder = Split-Path -Parent $Destination

    New-Item -ItemType Directory -Path $DestinationFolder -Force | Out-Null
    Copy-Item -LiteralPath $Path -Destination $Destination -Force
}

function Save-WikiFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content
    )

    $Existing = if (Test-Path -LiteralPath $Path) {
        Get-Content -LiteralPath $Path -Raw
    }
    else {
        $null
    }

    if ($Existing -ceq $Content) {
        Write-Host "[UNCHANGED] $Path" -ForegroundColor DarkGray
        return $false
    }

    Backup-WikiFile -Path $Path
    Write-Utf8NoBom -Path $Path -Content $Content
    Write-Host "[UPDATED]   $Path" -ForegroundColor Green
    return $true
}

function HtmlEncode {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) {
        return ""
    }

    return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function Get-FirstExistingPath {
    param([Parameter(Mandatory)][string[]]$Candidates)

    foreach ($Candidate in $Candidates) {
        if (Test-Path -LiteralPath $Candidate) {
            return $Candidate
        }
    }

    return $null
}

function Get-RelativeHref {
    param(
        [Parameter(Mandatory)][string]$FromFile,
        [Parameter(Mandatory)][string]$ToFile
    )

    $FromDirectory = Split-Path -Parent $FromFile
    $FromUri = New-Object System.Uri(($FromDirectory.TrimEnd("\") + "\"))
    $ToUri = New-Object System.Uri($ToFile)
    return [System.Uri]::UnescapeDataString(
        $FromUri.MakeRelativeUri($ToUri).ToString()
    ).Replace("\", "/")
}

function Add-BeforeClosingTag {
    param(
        [Parameter(Mandatory)][string]$Html,
        [Parameter(Mandatory)][string]$Block
    )

    if ($Html -match "(?i)</main>") {
        return [regex]::Replace(
            $Html,
            "(?i)</main>",
            ($Block + "`r`n    </main>"),
            1
        )
    }

    if ($Html -match "(?i)</body>") {
        return [regex]::Replace(
            $Html,
            "(?i)</body>",
            ($Block + "`r`n</body>"),
            1
        )
    }

    return $Html + "`r`n" + $Block
}

function Replace-ManagedBlock {
    param(
        [Parameter(Mandatory)][string]$Html,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Block
    )

    $Start = "<!-- RDR2PF-GENERATOR:$Name:START -->"
    $End = "<!-- RDR2PF-GENERATOR:$Name:END -->"
    $Wrapped = "$Start`r`n$Block`r`n$End"
    $Pattern = "(?s)" + [regex]::Escape($Start) + ".*?" + [regex]::Escape($End)

    if ([regex]::IsMatch($Html, $Pattern)) {
        return [regex]::Replace($Html, $Pattern, [System.Text.RegularExpressions.MatchEvaluator]{
            param($Match)
            return $Wrapped
        }, 1)
    }

    return Add-BeforeClosingTag -Html $Html -Block $Wrapped
}

function Remove-HuntingFromIndex {
    param([Parameter(Mandatory)][string]$IndexPath)

    if (-not (Test-Path -LiteralPath $IndexPath)) {
        Write-Warning "Main index was not found: $IndexPath"
        return
    }

    $Html = Get-Content -LiteralPath $IndexPath -Raw
    $Original = $Html

    # Remove list items containing a link to player/hunting.html or hunting.html.
    $Html = [regex]::Replace(
        $Html,
        '(?ims)^[ \t]*<li\b[^>]*>\s*<a\b[^>]*href=["''](?:\./)?(?:player/)?hunting\.html(?:#[^"'']*)?["''][^>]*>.*?</a>\s*</li>[ \t]*\r?\n?',
        ''
    )

    # Remove standalone anchor rows.
    $Html = [regex]::Replace(
        $Html,
        '(?ims)^[ \t]*<a\b[^>]*href=["''](?:\./)?(?:player/)?hunting\.html(?:#[^"'']*)?["''][^>]*>.*?</a>[ \t]*\r?\n?',
        ''
    )

    if ($Html -ceq $Original) {
        Write-Host "[INFO] Hunting was not present as a top-level index link." -ForegroundColor Yellow
        return
    }

    Save-WikiFile -Path $IndexPath -Content $Html | Out-Null
    Write-Host "[OK] Hunting removed from the main index." -ForegroundColor Cyan
}

function Ensure-JobsPage {
    param(
        [Parameter(Mandatory)][string]$JobsPath,
        [Parameter(Mandatory)][string]$HuntingPath
    )

    $HuntingHref = Get-RelativeHref -FromFile $JobsPath -ToFile $HuntingPath

    if (Test-Path -LiteralPath $JobsPath) {
        $Html = Get-Content -LiteralPath $JobsPath -Raw
    }
    else {
        $StylePath = Join-Path $Root "assets\style.css"
        $StyleHref = Get-RelativeHref -FromFile $JobsPath -ToFile $StylePath

        $Html = @"
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Jobs &amp; Professions | RDR2PF Western Dead</title>
    <link rel="stylesheet" href="$StyleHref">
</head>
<body>
    <main class="page-shell">
        <header class="page-header">
            <p class="eyebrow">RDR2PF Western Dead</p>
            <h1>Jobs &amp; Professions</h1>
            <p>Implemented professions and the game systems that supply their progression.</p>
        </header>
    </main>
</body>
</html>
"@
    }

    $Block = @"
        <section class="content-card" id="implemented-professions">
            <h2>Implemented professions</h2>
            <p>
                Profession titles and lifetime statistics are displayed through the Character
                progression system. Each job page documents the implemented gameplay system
                that supplies those statistics.
            </p>
            <ul>
                <li>
                    <a href="$HuntingHref">Hunting</a>
                    &mdash; tracked through hunting statistics including
                    <code>animals_skinned</code>.
                </li>
            </ul>
        </section>
"@

    $Html = Replace-ManagedBlock -Html $Html -Name "JOBS-PROFESSIONS" -Block $Block
    Save-WikiFile -Path $JobsPath -Content $Html | Out-Null
}

function Ensure-CharacterProgression {
    param([Parameter(Mandatory)][string]$CharacterPath)

    if (-not (Test-Path -LiteralPath $CharacterPath)) {
        Write-Warning "Character page was not found: $CharacterPath"
        return
    }

    $Html = Get-Content -LiteralPath $CharacterPath -Raw

    $Block = @'
        <section class="content-card" id="character-progression">
            <h2>Character progression</h2>
            <p>
                The implemented <code>rdr2pf_character-progress</code> resource stores
                lifetime statistics per character. The Character page is the home for
                progression, statistics, and profession titles.
            </p>

            <h3>Default title</h3>
            <p><code>Drifter</code></p>

            <h3>Implemented profession titles</h3>
            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>Profession</th>
                            <th>Displayed title</th>
                            <th>Controlling metric</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr><td>Fishing</td><td>Fisherman</td><td><code>fish_caught</code></td></tr>
                        <tr><td>Hunting</td><td>Hunter</td><td><code>animals_skinned</code></td></tr>
                        <tr><td>Cooking</td><td>Cook</td><td><code>meals_cooked</code></td></tr>
                        <tr><td>Mining</td><td>Miner</td><td><code>ore_mined</code></td></tr>
                        <tr><td>Lumberjack</td><td>Lumberjack</td><td><code>logs_cut</code></td></tr>
                        <tr><td>Medic</td><td>Medic</td><td><code>patients_helped</code></td></tr>
                        <tr><td>Outlaw</td><td>Outlaw</td><td><code>outlaw_actions</code></td></tr>
                    </tbody>
                </table>
            </div>

            <h3>Tracked lifetime statistics</h3>
            <p>
                <strong>Fishing:</strong>
                <code>fish_caught</code>, <code>fish_weight</code>,
                <code>largest_fish</code>, and <code>fish_sold</code>.
            </p>
            <p>
                <strong>Hunting:</strong>
                <code>animals_killed</code>, <code>animals_skinned</code>,
                <code>legendary_animals_killed</code>, <code>pelts_sold</code>,
                and <code>meat_harvested</code>.
            </p>
            <p>
                <strong>Cooking:</strong>
                <code>meals_cooked</code>, <code>stews_cooked</code>,
                <code>coffee_brewed</code>, and <code>tonics_crafted</code>.
            </p>
            <p>
                <strong>Mining:</strong>
                <code>rocks_mined</code>, <code>ore_mined</code>,
                <code>coal_mined</code>, <code>iron_mined</code>,
                <code>gold_found</code>, and <code>gems_found</code>.
            </p>
            <p>
                <strong>Lumberjack:</strong>
                <code>trees_chopped</code>, <code>logs_cut</code>,
                and <code>firewood_produced</code>.
            </p>
            <p>
                <strong>Medic:</strong>
                <code>patients_helped</code>, <code>players_revived</code>,
                and <code>bandages_applied</code>.
            </p>
            <p>
                <strong>Outlaw and combat:</strong>
                <code>outlaw_actions</code>, <code>ambushes_survived</code>,
                <code>zombies_killed</code>, <code>humans_killed</code>,
                <code>headshots</code>, <code>melee_kills</code>, and
                <code>deaths</code>.
            </p>

            <p>
                When profession totals are tied, the current profession remains selected
                when <code>Config.KeepCurrentTitleOnTie</code> is enabled.
            </p>
        </section>
'@

    $Html = Replace-ManagedBlock -Html $Html -Name "CHARACTER-PROGRESSION" -Block $Block
    Save-WikiFile -Path $CharacterPath -Content $Html | Out-Null
}

function Read-ItemRegistry {
    param([Parameter(Mandatory)][string]$DataPath)

    if (-not (Test-Path -LiteralPath $DataPath)) {
        throw "Item export not found: $DataPath"
    }

    $Items = New-Object System.Collections.Generic.List[object]
    $Seen = @{}

    foreach ($Line in Get-Content -LiteralPath $DataPath) {
        if ([string]::IsNullOrWhiteSpace($Line)) {
            continue
        }

        $Raw = $Line.Trim()

        if (
            $Raw -match '^\s*[+\-=]+\s*$' -or
            $Raw -match '^\|\s*item\s*\|\s*label\s*\|' -or
            $Raw -match '^\s*FILE:'
        ) {
            continue
        }

        $NumericId = ""
        $ItemName = ""
        $Label = ""
        $Description = ""

        if ($Raw -match '^\|\s*(?<item>[^|]+?)\s*\|\s*(?<label>[^|]*?)\s*\|\s*(?<description>.*?)\s*\|$') {
            $ItemName = $Matches.item.Trim()
            $Label = $Matches.label.Trim()
            $Description = $Matches.description.Trim()
        }
        elseif ($Raw -match '^(?<id>\d+)\s*[\t,|]\s*(?<item>[^,\t|]+)(?:[\t,|]\s*(?<label>[^,\t|]*))?(?:[\t,|]\s*(?<description>.*))?$') {
            $NumericId = $Matches.id.Trim()
            $ItemName = $Matches.item.Trim()
            $Label = $Matches.label.Trim()
            $Description = $Matches.description.Trim()
        }
        elseif ($Raw -match '^(?<item>[A-Za-z0-9_:\.-]+)\s*[\t,|]\s*(?<label>[^,\t|]*)(?:[\t,|]\s*(?<description>.*))?$') {
            $ItemName = $Matches.item.Trim()
            $Label = $Matches.label.Trim()
            $Description = $Matches.description.Trim()
        }
        elseif ($Raw -match '^[A-Za-z0-9_:\.-]+$') {
            $ItemName = $Raw
        }

        if (-not $ItemName -or $Seen.ContainsKey($ItemName)) {
            continue
        }

        $Seen[$ItemName] = $true

        $Items.Add([pscustomobject]@{
            NumericId   = $NumericId
            ItemName    = $ItemName
            Label       = $Label
            Description = $Description
        })
    }

    return @($Items | Sort-Object ItemName)
}

function Generate-ItemRegistry {
    param(
        [Parameter(Mandatory)][string]$RegistryPath,
        [Parameter(Mandatory)][object[]]$Items
    )

    $StylePath = Join-Path $Root "assets\style.css"
    $StyleHref = Get-RelativeHref -FromFile $RegistryPath -ToFile $StylePath
    $ItemCount = $Items.Count

    $Rows = foreach ($Item in $Items) {
        $Search = (
            @(
                $Item.NumericId,
                $Item.ItemName,
                $Item.Label,
                $Item.Description
            ) -join " "
        ).ToLowerInvariant()

        @"
                    <tr data-search="$(HtmlEncode $Search)">
                        <td>$(HtmlEncode $Item.NumericId)</td>
                        <td><code>$(HtmlEncode $Item.ItemName)</code></td>
                        <td>$(HtmlEncode $Item.Label)</td>
                        <td>$(HtmlEncode $Item.Description)</td>
                    </tr>
"@
    }

    $Html = @"
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Complete Item Registry | RDR2PF Western Dead</title>
    <link rel="stylesheet" href="$StyleHref">
    <style>
        .registry-controls {
            display: grid;
            gap: .75rem;
            margin: 1rem 0;
        }

        .registry-controls input {
            box-sizing: border-box;
            width: 100%;
            padding: .8rem;
        }

        .registry-table-wrap {
            overflow-x: auto;
        }

        .registry-table {
            width: 100%;
            border-collapse: collapse;
        }

        .registry-table th,
        .registry-table td {
            padding: .65rem;
            text-align: left;
            vertical-align: top;
            border-bottom: 1px solid rgba(255, 255, 255, .12);
        }

        .registry-table code {
            white-space: nowrap;
        }
    </style>
</head>
<body>
    <main class="page-shell">
        <header class="page-header">
            <p class="eyebrow">Inventory and crafting reference</p>
            <h1>Complete Item Registry</h1>
            <p>
                Search every unique item exported to <code>data/item-ids.txt</code>.
                Internal names are the IDs used by inventory, crafting, harvesting,
                looting, stores, and related resources.
            </p>
        </header>

        <section class="content-card">
            <div class="registry-controls">
                <label for="item-search">Search all $ItemCount items</label>
                <input
                    id="item-search"
                    type="search"
                    placeholder="Search item ID, numeric ID, label, or description"
                    autocomplete="off"
                >
                <p id="item-count" aria-live="polite">
                    Showing $ItemCount of $ItemCount items.
                </p>
            </div>

            <div class="registry-table-wrap">
                <table class="registry-table">
                    <thead>
                        <tr>
                            <th scope="col">Numeric ID</th>
                            <th scope="col">Item ID / name</th>
                            <th scope="col">Label</th>
                            <th scope="col">Description</th>
                        </tr>
                    </thead>
                    <tbody id="item-rows">
$($Rows -join "`r`n")
                    </tbody>
                </table>
            </div>
        </section>
    </main>

    <script>
        const input = document.getElementById("item-search");
        const rows = Array.from(document.querySelectorAll("#item-rows tr"));
        const count = document.getElementById("item-count");
        const total = rows.length;

        function filterItems() {
            const query = input.value.trim().toLowerCase();
            let visible = 0;

            for (const row of rows) {
                const matches = !query || row.dataset.search.includes(query);
                row.hidden = !matches;

                if (matches) {
                    visible += 1;
                }
            }

            count.textContent = "Showing " + visible + " of " + total + " items.";
        }

        input.addEventListener("input", filterItems);
    </script>
</body>
</html>
"@

    Save-WikiFile -Path $RegistryPath -Content $Html | Out-Null
    Write-Host "[OK] Generated item registry with $ItemCount unique items." -ForegroundColor Cyan
}

function Ensure-RegistryLink {
    param(
        [Parameter(Mandatory)][string]$ItemsPage,
        [Parameter(Mandatory)][string]$RegistryPath
    )

    if (-not (Test-Path -LiteralPath $ItemsPage)) {
        Write-Warning "Items page was not found: $ItemsPage"
        return
    }

    $Href = Get-RelativeHref -FromFile $ItemsPage -ToFile $RegistryPath
    $Html = Get-Content -LiteralPath $ItemsPage -Raw

    $Block = @"
        <section class="content-card" id="complete-item-registry">
            <h2>Complete item registry</h2>
            <p>
                Browse the full exported item database by internal item name,
                label, description, and numeric ID where available.
            </p>
            <p><a href="$Href">Open the complete item registry</a></p>
        </section>
"@

    $Html = Replace-ManagedBlock -Html $Html -Name "ITEM-REGISTRY-LINK" -Block $Block
    Save-WikiFile -Path $ItemsPage -Content $Html | Out-Null
}

function Test-WikiLinks {
    param([Parameter(Mandatory)][string]$WikiRoot)

    $Broken = New-Object System.Collections.Generic.List[object]

    foreach ($File in Get-ChildItem -LiteralPath $WikiRoot -Recurse -Filter *.html) {
        if ($File.FullName -match '\\wiki-update-backups\\') {
            continue
        }

        $Html = Get-Content -LiteralPath $File.FullName -Raw
        $Matches = [regex]::Matches(
            $Html,
            '(?i)\bhref\s*=\s*["''](?<href>[^"'']+)["'']'
        )

        foreach ($Match in $Matches) {
            $Href = $Match.Groups["href"].Value.Trim()

            if (
                [string]::IsNullOrWhiteSpace($Href) -or
                $Href.StartsWith("#") -or
                $Href -match '^(?i)(https?:|mailto:|tel:|javascript:)'
            ) {
                continue
            }

            $WithoutFragment = ($Href -split '#', 2)[0]
            $WithoutQuery = ($WithoutFragment -split '\?', 2)[0]

            if ([string]::IsNullOrWhiteSpace($WithoutQuery)) {
                continue
            }

            $Decoded = [System.Uri]::UnescapeDataString($WithoutQuery).Replace("/", "\")
            $Target = [System.IO.Path]::GetFullPath(
                (Join-Path $File.DirectoryName $Decoded)
            )

            if (-not (Test-Path -LiteralPath $Target)) {
                $Broken.Add([pscustomobject]@{
                    Page = $File.FullName.Substring($WikiRoot.Length).TrimStart("\")
                    Href = $Href
                })
            }
        }
    }

    if ($Broken.Count -eq 0) {
        Write-Host "[OK] Local HTML link check passed." -ForegroundColor Green
        return
    }

    Write-Host ""
    Write-Host "[WARN] Broken local links found:" -ForegroundColor Yellow

    foreach ($Entry in $Broken) {
        Write-Host "  $($Entry.Page) -> $($Entry.Href)" -ForegroundColor Yellow
    }

    $ReportPath = Join-Path $WikiRoot "data\broken-links.txt"
    $Report = $Broken |
        ForEach-Object { "$($_.Page) -> $($_.Href)" }

    Write-Utf8NoBom -Path $ReportPath -Content ($Report -join "`r`n")
    Write-Host "[INFO] Broken-link report written to: $ReportPath" -ForegroundColor Yellow
}

if (-not (Test-Path -LiteralPath $Root)) {
    throw "Wiki root was not found: $Root"
}

Write-Host ""
Write-Host "RDR2PF WIKI GENERATOR V2" -ForegroundColor Cyan
Write-Host "Root: $Root"
Write-Host ""

$IndexPath = Join-Path $Root "index.html"

$JobsPath = Get-FirstExistingPath -Candidates @(
    (Join-Path $Root "player\jobs.html"),
    (Join-Path $Root "development\jobs.html"),
    (Join-Path $Root "developer\jobs.html"),
    (Join-Path $Root "admin\jobs.html")
)

if (-not $JobsPath) {
    $JobsPath = Join-Path $Root "player\jobs.html"
}

$HuntingPath = Get-FirstExistingPath -Candidates @(
    (Join-Path $Root "player\hunting.html"),
    (Join-Path $Root "development\hunting.html"),
    (Join-Path $Root "developer\hunting.html"),
    (Join-Path $Root "hunting.html")
)

if (-not $HuntingPath) {
    $HuntingPath = Join-Path $Root "player\hunting.html"
    Write-Warning "Hunting page was not found. Jobs will link to expected path: $HuntingPath"
}

$CharacterPath = Get-FirstExistingPath -Candidates @(
    (Join-Path $Root "player\character.html"),
    (Join-Path $Root "character.html")
)

$ItemsPage = Get-FirstExistingPath -Candidates @(
    (Join-Path $Root "player\items.html"),
    (Join-Path $Root "admin\items.html"),
    (Join-Path $Root "items.html"),
    (Join-Path $Root "admin\item-validation.html")
)

$ItemDataPath = Join-Path $Root "data\item-ids.txt"
$RegistryPath = Join-Path $Root "admin\item-registry.html"

Remove-HuntingFromIndex -IndexPath $IndexPath
Ensure-JobsPage -JobsPath $JobsPath -HuntingPath $HuntingPath

if ($CharacterPath) {
    Ensure-CharacterProgression -CharacterPath $CharacterPath
}
else {
    Write-Warning "No Character page was found. Character progression was not written."
}

$Items = Read-ItemRegistry -DataPath $ItemDataPath
Generate-ItemRegistry -RegistryPath $RegistryPath -Items $Items

if ($ItemsPage) {
    Ensure-RegistryLink -ItemsPage $ItemsPage -RegistryPath $RegistryPath
}
else {
    Write-Warning "No Items page was found. Registry page was generated without adding a page link."
}

if (-not $SkipLinkCheck) {
    Test-WikiLinks -WikiRoot $Root
}

Write-Host ""
Write-Host "GENERATION COMPLETE" -ForegroundColor Cyan
Write-Host "Backup folder: $BackupRoot"
Write-Host ""
Write-Host "Review the wiki locally, then run your existing GitHub push .bat."
