param(
    [Parameter(Mandatory = $true)]
    $BuilderConfig
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor DarkRed
Write-Host " PARSING CRAFTING RECIPES" -ForegroundColor Red
Write-Host "--------------------------------------------" -ForegroundColor DarkRed

$SourcePath = [string]$BuilderConfig.crafting_config_path
$Database   = [string]$BuilderConfig.database_path
$Reports    = [string]$BuilderConfig.reports_path

if (-not (Test-Path -LiteralPath $SourcePath)) {
    throw "Crafting source not found: $SourcePath"
}

New-Item -ItemType Directory -Path $Database -Force | Out-Null
New-Item -ItemType Directory -Path $Reports -Force | Out-Null

$RecipesJson = Join-Path $Database "recipes.json"
$RecipesCsv  = Join-Path $Database "recipes.csv"
$Timestamp   = Get-Date -Format "yyyyMMdd-HHmmss"
$ReportPath  = Join-Path $Reports "crafting-parse-$Timestamp.txt"

$Text = Get-Content -LiteralPath $SourcePath -Raw

function Remove-LuaComments {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $Content = [regex]::Replace(
        $Content,
        '--\[\[.*?\]\]',
        '',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )

    $Lines = $Content -split "`r?`n"

    $CleanLines = foreach ($Line in $Lines) {
        $InsideSingle = $false
        $InsideDouble = $false
        $EscapeNext   = $false
        $CutIndex     = -1

        for ($i = 0; $i -lt $Line.Length - 1; $i++) {
            $Char = $Line[$i]
            $Next = $Line[$i + 1]

            if ($EscapeNext) {
                $EscapeNext = $false
                continue
            }

            if ($Char -eq '\') {
                $EscapeNext = $true
                continue
            }

            if ($Char -eq "'" -and -not $InsideDouble) {
                $InsideSingle = -not $InsideSingle
                continue
            }

            if ($Char -eq '"' -and -not $InsideSingle) {
                $InsideDouble = -not $InsideDouble
                continue
            }

            if (
                -not $InsideSingle -and
                -not $InsideDouble -and
                $Char -eq '-' -and
                $Next -eq '-'
            ) {
                $CutIndex = $i
                break
            }
        }

        if ($CutIndex -ge 0) {
            $Line.Substring(0, $CutIndex)
        }
        else {
            $Line
        }
    }

    return ($CleanLines -join "`n")
}

function Get-LuaAssignedTableBody {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$AssignmentName
    )

    $Pattern = [regex]::Escape($AssignmentName) + '\s*=\s*\{'
    $Match = [regex]::Match($Content, $Pattern)

    if (-not $Match.Success) {
        throw "Could not find Lua table assignment: $AssignmentName"
    }

    $OpenIndex = $Content.IndexOf('{', $Match.Index)

    if ($OpenIndex -lt 0) {
        throw "Opening brace not found for: $AssignmentName"
    }

    $Depth        = 0
    $InsideSingle = $false
    $InsideDouble = $false
    $EscapeNext   = $false

    for ($i = $OpenIndex; $i -lt $Content.Length; $i++) {
        $Char = $Content[$i]

        if ($EscapeNext) {
            $EscapeNext = $false
            continue
        }

        if ($Char -eq '\') {
            $EscapeNext = $true
            continue
        }

        if ($Char -eq "'" -and -not $InsideDouble) {
            $InsideSingle = -not $InsideSingle
            continue
        }

        if ($Char -eq '"' -and -not $InsideSingle) {
            $InsideDouble = -not $InsideDouble
            continue
        }

        if ($InsideSingle -or $InsideDouble) {
            continue
        }

        if ($Char -eq '{') {
            $Depth++
        }
        elseif ($Char -eq '}') {
            $Depth--

            if ($Depth -eq 0) {
                return $Content.Substring(
                    $OpenIndex + 1,
                    $i - $OpenIndex - 1
                )
            }
        }
    }

    throw "Closing brace not found for: $AssignmentName"
}

function Split-LuaTopLevelEntries {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TableBody
    )

    $Entries      = [System.Collections.Generic.List[string]]::new()
    $Depth        = 0
    $InsideSingle = $false
    $InsideDouble = $false
    $EscapeNext   = $false
    $EntryStart   = -1

    for ($i = 0; $i -lt $TableBody.Length; $i++) {
        $Char = $TableBody[$i]

        if ($EscapeNext) {
            $EscapeNext = $false
            continue
        }

        if ($Char -eq '\') {
            $EscapeNext = $true
            continue
        }

        if ($Char -eq "'" -and -not $InsideDouble) {
            $InsideSingle = -not $InsideSingle
            continue
        }

        if ($Char -eq '"' -and -not $InsideSingle) {
            $InsideDouble = -not $InsideDouble
            continue
        }

        if ($InsideSingle -or $InsideDouble) {
            continue
        }

        if ($Char -eq '{') {
            if ($Depth -eq 0) {
                $EntryStart = $i
            }

            $Depth++
        }
        elseif ($Char -eq '}') {
            $Depth--

            if ($Depth -eq 0 -and $EntryStart -ge 0) {
                $Entries.Add(
                    $TableBody.Substring(
                        $EntryStart,
                        $i - $EntryStart + 1
                    )
                )

                $EntryStart = -1
            }
        }
    }

    return @($Entries)
}

function Get-LuaScalar {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Block,

        [Parameter(Mandatory = $true)]
        [string]$Property
    )

    $Pattern = '(?m)^\s*' +
        [regex]::Escape($Property) +
        '\s*=\s*(.+?)(?:,\s*)?$'

    $Match = [regex]::Match($Block, $Pattern)

    if (-not $Match.Success) {
        return $null
    }

    $Value = $Match.Groups[1].Value.Trim()

    if (
        ($Value.StartsWith('"') -and $Value.EndsWith('"')) -or
        ($Value.StartsWith("'") -and $Value.EndsWith("'"))
    ) {
        return $Value.Substring(1, $Value.Length - 2)
    }

    if ($Value -eq "true") {
        return $true
    }

    if ($Value -eq "false") {
        return $false
    }

    if ($Value -match '^-?\d+(?:\.\d+)?$') {
        return [decimal]$Value
    }

    return $Value
}

function Get-LuaPropertyTable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Block,

        [Parameter(Mandatory = $true)]
        [string]$Property
    )

    $Pattern = '(?m)^\s*' +
        [regex]::Escape($Property) +
        '\s*=\s*\{'

    $Match = [regex]::Match($Block, $Pattern)

    if (-not $Match.Success) {
        return $null
    }

    $OpenIndex = $Block.IndexOf('{', $Match.Index)
    $Depth        = 0
    $InsideSingle = $false
    $InsideDouble = $false
    $EscapeNext   = $false

    for ($i = $OpenIndex; $i -lt $Block.Length; $i++) {
        $Char = $Block[$i]

        if ($EscapeNext) {
            $EscapeNext = $false
            continue
        }

        if ($Char -eq '\') {
            $EscapeNext = $true
            continue
        }

        if ($Char -eq "'" -and -not $InsideDouble) {
            $InsideSingle = -not $InsideSingle
            continue
        }

        if ($Char -eq '"' -and -not $InsideSingle) {
            $InsideDouble = -not $InsideDouble
            continue
        }

        if ($InsideSingle -or $InsideDouble) {
            continue
        }

        if ($Char -eq '{') {
            $Depth++
        }
        elseif ($Char -eq '}') {
            $Depth--

            if ($Depth -eq 0) {
                return $Block.Substring(
                    $OpenIndex + 1,
                    $i - $OpenIndex - 1
                )
            }
        }
    }

    return $null
}

function Convert-LuaItemTable {
    param(
        [string]$TableBody
    )

    if ([string]::IsNullOrWhiteSpace($TableBody)) {
        return @()
    }

    $ItemBlocks = Split-LuaTopLevelEntries -TableBody $TableBody

    $Items = foreach ($ItemBlock in $ItemBlocks) {
        $Name  = Get-LuaScalar -Block $ItemBlock -Property "name"
        $Count = Get-LuaScalar -Block $ItemBlock -Property "count"
        $Take  = Get-LuaScalar -Block $ItemBlock -Property "take"
        $Decay = Get-LuaScalar -Block $ItemBlock -Property "canUseDecay"

        if ([string]::IsNullOrWhiteSpace([string]$Name)) {
            continue
        }

        [PSCustomObject][ordered]@{
            item          = [string]$Name
            count         = if ($null -eq $Count) { 1 } else { $Count }
            take          = $Take
            can_use_decay = $Decay
        }
    }

    return @($Items)
}

function Convert-ToSlug {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $Slug = $Value.Trim().ToLowerInvariant()
    $Slug = [regex]::Replace($Slug, '[^a-z0-9]+', '_')
    $Slug = $Slug.Trim('_')

    if ([string]::IsNullOrWhiteSpace($Slug)) {
        return "recipe"
    }

    return $Slug
}

$CleanText = Remove-LuaComments -Content $Text
$CraftingBody = Get-LuaAssignedTableBody `
    -Content $CleanText `
    -AssignmentName "Config.Crafting"

$RecipeBlocks = Split-LuaTopLevelEntries -TableBody $CraftingBody

Write-Host "Recipe blocks found: $($RecipeBlocks.Count)" -ForegroundColor Cyan

$Recipes = [System.Collections.Generic.List[object]]::new()
$SlugCounts = @{}
$Index = 0

foreach ($RecipeBlock in $RecipeBlocks) {
    $Index++

    $Name      = Get-LuaScalar -Block $RecipeBlock -Property "Text"
    $SubText   = Get-LuaScalar -Block $RecipeBlock -Property "SubText"
    $Desc      = Get-LuaScalar -Block $RecipeBlock -Property "Desc"
    $Type      = Get-LuaScalar -Block $RecipeBlock -Property "Type"
    $Job       = Get-LuaScalar -Block $RecipeBlock -Property "Job"
    $Location  = Get-LuaScalar -Block $RecipeBlock -Property "Location"
    $Currency  = Get-LuaScalar -Block $RecipeBlock -Property "UseCurrencyMode"
    $CurrencyType = Get-LuaScalar -Block $RecipeBlock -Property "CurrencyType"
    $Category  = Get-LuaScalar -Block $RecipeBlock -Property "Category"
    $Animation = Get-LuaScalar -Block $RecipeBlock -Property "Animation"
    $TakeItems = Get-LuaScalar -Block $RecipeBlock -Property "TakeItems"

    if ([string]::IsNullOrWhiteSpace([string]$Name)) {
        Write-Warning "Skipping block $Index because Text was not found."
        continue
    }

    $IngredientsBody = Get-LuaPropertyTable `
        -Block $RecipeBlock `
        -Property "Items"

    $RewardsBody = Get-LuaPropertyTable `
        -Block $RecipeBlock `
        -Property "Reward"

    $Ingredients = Convert-LuaItemTable -TableBody $IngredientsBody
    $Rewards     = Convert-LuaItemTable -TableBody $RewardsBody

    $CurrencyReward = $null

    if ($Currency -eq $true -and -not [string]::IsNullOrWhiteSpace($RewardsBody)) {
        $CurrencyReward = Get-LuaScalar `
            -Block $RewardsBody `
            -Property "count"
    }

    $BaseSlug = Convert-ToSlug -Value ([string]$Name)

    if (-not $SlugCounts.ContainsKey($BaseSlug)) {
        $SlugCounts[$BaseSlug] = 1
        $RecipeId = $BaseSlug
    }
    else {
        $SlugCounts[$BaseSlug]++
        $RecipeId = "{0}_{1}" -f $BaseSlug, $SlugCounts[$BaseSlug]
    }

    $Recipes.Add(
        [PSCustomObject][ordered]@{
            id                = $RecipeId
            name              = ([string]$Name).Trim()
            subtext           = $SubText
            description       = $Desc
            type              = $Type
            category          = $Category
            job               = $Job
            location          = $Location
            animation         = $Animation
            use_currency_mode = $Currency
            currency_type     = $CurrencyType
            currency_reward   = $CurrencyReward
            take_items        = $TakeItems
            ingredients       = @($Ingredients)
            rewards           = @($Rewards)
            source            = [PSCustomObject][ordered]@{
                file         = $SourcePath
                recipe_index = $Index
            }
        }
    )
}

$RecipesArray = @($Recipes)

$RecipesArray |
    ConvertTo-Json -Depth 12 |
    Set-Content -LiteralPath $RecipesJson -Encoding UTF8

$CsvRows = foreach ($Recipe in $RecipesArray) {
    [PSCustomObject][ordered]@{
        id          = $Recipe.id
        name        = $Recipe.name
        category    = $Recipe.category
        type        = $Recipe.type
        job         = $Recipe.job
        location    = $Recipe.location
        animation   = $Recipe.animation
        ingredients = (
            $Recipe.ingredients |
                ForEach-Object {
                    "{0} x{1}" -f $_.item, $_.count
                }
        ) -join "; "
        rewards = (
            $Recipe.rewards |
                ForEach-Object {
                    "{0} x{1}" -f $_.item, $_.count
                }
        ) -join "; "
    }
}

$CsvRows |
    Export-Csv -LiteralPath $RecipesCsv -NoTypeInformation -Encoding UTF8

$IngredientCount = @(
    $RecipesArray |
        ForEach-Object { $_.ingredients }
).Count

$RewardCount = @(
    $RecipesArray |
        ForEach-Object { $_.rewards }
).Count

$CategorySummary = @(
    $RecipesArray |
        Group-Object category |
        Sort-Object Name
)

$ReportLines = [System.Collections.Generic.List[string]]::new()

$ReportLines.Add("RDR2PF Crafting Parse Report")
$ReportLines.Add("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$ReportLines.Add("")
$ReportLines.Add("Source: $SourcePath")
$ReportLines.Add("Recipes: $($RecipesArray.Count)")
$ReportLines.Add("Ingredient entries: $IngredientCount")
$ReportLines.Add("Reward entries: $RewardCount")
$ReportLines.Add("")
$ReportLines.Add("Categories:")

foreach ($Group in $CategorySummary) {
    $Name = if ([string]::IsNullOrWhiteSpace($Group.Name)) {
        "(none)"
    }
    else {
        $Group.Name
    }

    $ReportLines.Add("  $Name : $($Group.Count)")
}

$ReportLines |
    Set-Content -LiteralPath $ReportPath -Encoding UTF8

Write-Host ""
Write-Host "Recipes imported:    $($RecipesArray.Count)" -ForegroundColor Green
Write-Host "Ingredient entries:  $IngredientCount"
Write-Host "Reward entries:      $RewardCount"
Write-Host ""
Write-Host "Recipes JSON: $RecipesJson" -ForegroundColor Yellow
Write-Host "Recipes CSV:  $RecipesCsv" -ForegroundColor Yellow
Write-Host "Parse report: $ReportPath" -ForegroundColor Yellow


