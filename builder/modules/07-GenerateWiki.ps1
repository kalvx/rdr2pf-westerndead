param(
    [Parameter(Mandatory)]
    [psobject]$BuilderConfig
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor Cyan
Write-Host " GENERATING COMPENDIUM WIKI" -ForegroundColor Cyan
Write-Host "--------------------------------------------" -ForegroundColor Cyan

# ------------------------------------------------------------
# Resolve folders
# ------------------------------------------------------------

$Database = [string]$BuilderConfig.output.database
$Reports  = [string]$BuilderConfig.output.reports

if ([string]::IsNullOrWhiteSpace($Database)) {
    $Database = "H:\rdr2pf-westerndead\database"
}

if ([string]::IsNullOrWhiteSpace($Reports)) {
    $Reports = "H:\rdr2pf-westerndead\build-reports"
}

$CompendiumRoot = Split-Path -Parent $Database
$WikiRoot       = Join-Path $CompendiumRoot "wiki"
$ItemPages      = Join-Path $WikiRoot "items"
$RecipePages    = Join-Path $WikiRoot "recipes"
$ReportPages    = Join-Path $WikiRoot "reports"

foreach ($Directory in @(
    $WikiRoot
    $ItemPages
    $RecipePages
    $ReportPages
)) {
    New-Item -Path $Directory -ItemType Directory -Force | Out-Null
}

# ------------------------------------------------------------
# Required database files
# ------------------------------------------------------------

$ItemsFile         = Join-Path $Database "items.json"
$RecipesFile       = Join-Path $Database "recipes.json"
$RelationshipsFile = Join-Path $Database "item-relationships.json"

foreach ($RequiredFile in @(
    $ItemsFile
    $RecipesFile
    $RelationshipsFile
)) {
    if (-not (Test-Path -LiteralPath $RequiredFile)) {
        throw "Required database file not found: $RequiredFile"
    }
}

$Items = Get-Content -LiteralPath $ItemsFile -Raw |
    ConvertFrom-Json

$Recipes = Get-Content -LiteralPath $RecipesFile -Raw |
    ConvertFrom-Json

$Relationships = Get-Content -LiteralPath $RelationshipsFile -Raw |
    ConvertFrom-Json

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

function Write-Utf8File {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Content
    )

    $Utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)

    [System.IO.File]::WriteAllText(
        $Path,
        $Content,
        $Utf8WithoutBom
    )
}

function Get-SafeFileName {
    param(
        [Parameter(Mandatory)]
        [string]$Value
    )

    $Safe = $Value.Trim().ToLowerInvariant()
    $Safe = $Safe -replace '[^a-z0-9_\-]+', '-'
    $Safe = $Safe -replace '-+', '-'
    $Safe = $Safe.Trim('-')

    if ([string]::IsNullOrWhiteSpace($Safe)) {
        return "unnamed"
    }

    return $Safe
}

function Escape-Markdown {
    param(
        [AllowNull()]
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ""
    }

    return (
        $Value `
            -replace '\|', '\|' `
            -replace "`r?`n", " "
    )
}

function Get-ItemLabel {
    param(
        [string]$ItemId
    )

    if (
        -not [string]::IsNullOrWhiteSpace($ItemId) -and
        $ItemIndex.ContainsKey($ItemId)
    ) {
        return [string]$ItemIndex[$ItemId].label
    }

    return $ItemId
}

function Get-RecipeLabel {
    param(
        [string]$RecipeId
    )

    if (
        -not [string]::IsNullOrWhiteSpace($RecipeId) -and
        $RecipeIndex.ContainsKey($RecipeId)
    ) {
        return [string]$RecipeIndex[$RecipeId].name
    }

    return $RecipeId
}

function Get-ItemLink {
    param(
        [string]$ItemId,
        [string]$Prefix = "../items"
    )

    $Label = Get-ItemLabel -ItemId $ItemId
    $Safe  = Get-SafeFileName -Value $ItemId

    if ($ItemIndex.ContainsKey($ItemId)) {
        return "[$Label]($Prefix/$Safe.md)"
    }

    return "$Label *(missing item definition)*"
}

function Get-RecipeLink {
    param(
        [string]$RecipeId,
        [string]$Prefix = "../recipes"
    )

    $Label = Get-RecipeLabel -RecipeId $RecipeId
    $Safe  = Get-SafeFileName -Value $RecipeId

    if ($RecipeIndex.ContainsKey($RecipeId)) {
        return "[$Label]($Prefix/$Safe.md)"
    }

    return "$Label *(missing recipe definition)*"
}



function Escape-Html {
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return ""
    }

    return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function Get-ItemHtmlLink {
    param(
        [string]$ItemId,
        [string]$Prefix = "../items"
    )

    $Label = Get-ItemLabel -ItemId $ItemId
    $Safe  = Get-SafeFileName -Value $ItemId

    if ($ItemIndex.ContainsKey($ItemId)) {
        return '<a href="' + $Prefix + '/' + $Safe + '.html">' + (Escape-Html $Label) + '</a>'
    }

    return (Escape-Html $Label) + ' <span class="missing">(missing item definition)</span>'
}

function Get-RecipeHtmlLink {
    param(
        [string]$RecipeId,
        [string]$Prefix = "../recipes"
    )

    $Label = Get-RecipeLabel -RecipeId $RecipeId
    $Safe  = Get-SafeFileName -Value $RecipeId

    if ($RecipeIndex.ContainsKey($RecipeId)) {
        return '<a href="' + $Prefix + '/' + $Safe + '.html">' + (Escape-Html $Label) + '</a>'
    }

    return (Escape-Html $Label) + ' <span class="missing">(missing recipe definition)</span>'
}

function Get-HtmlDocument {
    param(
        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter(Mandatory)]
        [string]$Body,

        [string]$RootPrefix = ".."
    )

    $SafeTitle = Escape-Html $Title

    return @"
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>$SafeTitle | RDR2PF Compendium</title>
    <style>
        :root { color-scheme: dark; --bg:#110f0d; --panel:#1b1713; --line:#514234; --text:#eee5d8; --muted:#bcae9b; --link:#e0aa62; --danger:#e7786d; }
        * { box-sizing:border-box; }
        body { margin:0; background:var(--bg); color:var(--text); font-family:Georgia, "Times New Roman", serif; line-height:1.55; }
        header { border-bottom:1px solid var(--line); background:#0c0a09; padding:16px 24px; position:sticky; top:0; z-index:2; }
        nav { display:flex; gap:18px; flex-wrap:wrap; }
        a { color:var(--link); text-decoration:none; }
        a:hover { text-decoration:underline; }
        main { width:min(1100px, calc(100% - 32px)); margin:28px auto 64px; }
        h1,h2 { line-height:1.15; }
        h1 { margin-bottom:8px; }
        h2 { margin-top:32px; border-bottom:1px solid var(--line); padding-bottom:8px; }
        .subtitle,.muted { color:var(--muted); }
        .card { background:var(--panel); border:1px solid var(--line); border-radius:8px; padding:18px; margin:16px 0; }
        table { width:100%; border-collapse:collapse; background:var(--panel); }
        th,td { border:1px solid var(--line); padding:10px; text-align:left; vertical-align:top; }
        th { background:#251f19; }
        code { color:#f0c98c; }
        ul { padding-left:22px; }
        .missing { color:var(--danger); }
        .grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(280px,1fr)); gap:14px; }
        .search { width:100%; padding:12px; margin:12px 0 18px; background:#0d0b0a; color:var(--text); border:1px solid var(--line); border-radius:6px; }
    </style>
</head>
<body>
<header>
    <nav>
        <a href="$RootPrefix/index.html">Compendium Home</a>
        <a href="$RootPrefix/items.html">Every Item A–Z</a>
        <a href="$RootPrefix/recipes.html">Recipes</a>
    </nav>
</header>
<main>
$Body
</main>
</body>
</html>
"@
}

# ------------------------------------------------------------
# Build indexes
# ------------------------------------------------------------

$ItemIndex         = @{}
$RecipeIndex       = @{}
$RelationshipIndex = @{}

foreach ($Item in $Items) {
    $Id = [string]$Item.id

    if (-not [string]::IsNullOrWhiteSpace($Id)) {
        $ItemIndex[$Id] = $Item
    }
}

foreach ($Recipe in $Recipes) {
    $Id = [string]$Recipe.id

    if (-not [string]::IsNullOrWhiteSpace($Id)) {
        $RecipeIndex[$Id] = $Recipe
    }
}

foreach ($Relationship in $Relationships) {
    $Id = [string]$Relationship.id

    if (-not [string]::IsNullOrWhiteSpace($Id)) {
        $RelationshipIndex[$Id] = $Relationship
    }
}

# ------------------------------------------------------------
# Clear only previously generated Markdown
# ------------------------------------------------------------

foreach ($GeneratedFolder in @(
    $ItemPages
    $RecipePages
    $ReportPages
)) {
    Get-ChildItem `
        -LiteralPath $GeneratedFolder `
        -Filter "*.md" `
        -File `
        -ErrorAction SilentlyContinue |
        Remove-Item -Force
}

# ------------------------------------------------------------
# Generate item pages
# ------------------------------------------------------------

$GeneratedItemPages = 0

foreach ($Item in ($Items | Sort-Object label, id)) {
    $ItemId = [string]$Item.id

    if ([string]::IsNullOrWhiteSpace($ItemId)) {
        continue
    }

    $Label = [string]$Item.label

    if ([string]::IsNullOrWhiteSpace($Label)) {
        $Label = $ItemId
    }

    $Description = [string]$Item.description

    if ([string]::IsNullOrWhiteSpace($Description)) {
        $Description = "No description is currently available."
    }

    $Relationship = $null

    if ($RelationshipIndex.ContainsKey($ItemId)) {
        $Relationship = $RelationshipIndex[$ItemId]
    }

    $Lines = [System.Collections.Generic.List[string]]::new()

    $Lines.Add("# $(Escape-Markdown $Label)")
    $Lines.Add("")
    $Lines.Add("> RDR2PF: Western Dead Compendium")
    $Lines.Add("")
    $Lines.Add("| Property | Value |")
    $Lines.Add("|---|---|")
    $Lines.Add("| Item ID | ``$(Escape-Markdown $ItemId)`` |")

    if ($Item.PSObject.Properties.Name -contains "limit") {
        $Lines.Add("| Inventory limit | $(Escape-Markdown ([string]$Item.limit)) |")
    }

    if ($Item.PSObject.Properties.Name -contains "type") {
        $Lines.Add("| Item type | $(Escape-Markdown ([string]$Item.type)) |")
    }

    if ($Item.PSObject.Properties.Name -contains "can_use") {
        $Lines.Add("| Usable | $(Escape-Markdown ([string]$Item.can_use)) |")
    }

    if ($Item.PSObject.Properties.Name -contains "can_remove") {
        $Lines.Add("| Removable | $(Escape-Markdown ([string]$Item.can_remove)) |")
    }

    $Lines.Add("")
    $Lines.Add("## Description")
    $Lines.Add("")
    $Lines.Add((Escape-Markdown $Description))
    $Lines.Add("")

    $UsedIn      = @()
    $CraftedFrom = @()
    $CraftedInto = @()

    if ($null -ne $Relationship) {
        $UsedIn      = @($Relationship.used_in)
        $CraftedFrom = @($Relationship.crafted_from)
        $CraftedInto = @($Relationship.crafted_into)
    }

    $Lines.Add("## Used in Recipes")
    $Lines.Add("")

    if ($UsedIn.Count -gt 0) {
        foreach ($RecipeId in ($UsedIn | Sort-Object -Unique)) {
            $Lines.Add("- $(Get-RecipeLink -RecipeId $RecipeId)")
        }
    }
    else {
        $Lines.Add("This item is not currently used as an ingredient in an imported recipe.")
    }

    $Lines.Add("")
    $Lines.Add("## Produced by Recipes")
    $Lines.Add("")

    if ($CraftedFrom.Count -gt 0) {
        foreach ($RecipeId in ($CraftedFrom | Sort-Object -Unique)) {
            $Lines.Add("- $(Get-RecipeLink -RecipeId $RecipeId)")
        }
    }
    else {
        $Lines.Add("This item is not currently produced by an imported recipe.")
    }

    $Lines.Add("")
    $Lines.Add("## Can Craft Into")
    $Lines.Add("")

    if ($CraftedInto.Count -gt 0) {
        foreach ($CraftedItemId in ($CraftedInto | Sort-Object -Unique)) {
            $Lines.Add("- $(Get-ItemLink -ItemId $CraftedItemId)")
        }
    }
    else {
        $Lines.Add("No linked crafted item is currently recorded.")
    }

    $Lines.Add("")
    $Lines.Add("---")
    $Lines.Add("")
    $Lines.Add("[Back to Item Index](../items.md)")

    $FileName = "$(Get-SafeFileName -Value $ItemId).md"
    $FilePath = Join-Path $ItemPages $FileName

    Write-Utf8File `
        -Path $FilePath `
        -Content ($Lines -join "`r`n")

    $GeneratedItemPages++
}

# ------------------------------------------------------------
# Generate recipe pages
# ------------------------------------------------------------

$GeneratedRecipePages = 0

foreach ($Recipe in ($Recipes | Sort-Object name, id)) {
    $RecipeId = [string]$Recipe.id

    if ([string]::IsNullOrWhiteSpace($RecipeId)) {
        continue
    }

    $RecipeName = [string]$Recipe.name

    if ([string]::IsNullOrWhiteSpace($RecipeName)) {
        $RecipeName = $RecipeId
    }

    $RecipeType = [string]$Recipe.type

    if ([string]::IsNullOrWhiteSpace($RecipeType)) {
        $RecipeType = "standard"
    }

    $Lines = [System.Collections.Generic.List[string]]::new()

    $Lines.Add("# $(Escape-Markdown $RecipeName)")
    $Lines.Add("")
    $Lines.Add("> RDR2PF: Western Dead Crafting Recipe")
    $Lines.Add("")
    $Lines.Add("| Property | Value |")
    $Lines.Add("|---|---|")
    $Lines.Add("| Recipe ID | ``$(Escape-Markdown $RecipeId)`` |")
    $Lines.Add("| Recipe type | $(Escape-Markdown $RecipeType) |")
    $Lines.Add("| Currency mode | $([bool]$Recipe.use_currency_mode) |")
    $Lines.Add("")

    $Lines.Add("## Ingredients")
    $Lines.Add("")

    $Ingredients = @($Recipe.ingredients)

    if ($Ingredients.Count -gt 0) {
        $Lines.Add("| Item | Item ID | Count | Status |")
        $Lines.Add("|---|---|---:|---|")

        foreach ($Ingredient in $Ingredients) {
            $IngredientId = [string]$Ingredient.item
            $Count        = $Ingredient.count

            if ($ItemIndex.ContainsKey($IngredientId)) {
                $Link   = Get-ItemLink -ItemId $IngredientId
                $Status = "Linked"
            }
            else {
                $Link   = Escape-Markdown (Get-ItemLabel -ItemId $IngredientId)
                $Status = "Missing item definition"
            }

            $Lines.Add(
                "| $Link | ``$(Escape-Markdown $IngredientId)`` | $Count | $Status |"
            )
        }
    }
    else {
        $Lines.Add("No ingredients were recorded.")
    }

    $Lines.Add("")
    $Lines.Add("## Reward")
    $Lines.Add("")

    if ($Recipe.use_currency_mode -eq $true) {
        $Lines.Add("| Reward type | Currency type | Amount |")
        $Lines.Add("|---|---:|---:|")
        $Lines.Add(
            "| Currency | $($Recipe.currency_type) | $($Recipe.currency_reward) |"
        )
    }
    else {
        $Rewards = @($Recipe.rewards)

        if ($Rewards.Count -gt 0) {
            $Lines.Add("| Reward | Reward ID | Count | Status |")
            $Lines.Add("|---|---|---:|---|")

            foreach ($Reward in $Rewards) {
                $RewardId = [string]$Reward.item
                $Count    = $Reward.count

                if ([string]$Recipe.type -eq "weapon") {
                    $Display = Escape-Markdown $RewardId
                    $Status  = "Weapon reward"
                }
                elseif ($ItemIndex.ContainsKey($RewardId)) {
                    $Display = Get-ItemLink -ItemId $RewardId
                    $Status  = "Linked"
                }
                else {
                    $Display = Escape-Markdown (Get-ItemLabel -ItemId $RewardId)
                    $Status  = "Missing item definition"
                }

                $Lines.Add(
                    "| $Display | ``$(Escape-Markdown $RewardId)`` | $Count | $Status |"
                )
            }
        }
        else {
            $Lines.Add("No reward was recorded.")
        }
    }

    $Lines.Add("")
    $Lines.Add("---")
    $Lines.Add("")
    $Lines.Add("[Back to Recipe Index](../recipes.md)")

    $FileName = "$(Get-SafeFileName -Value $RecipeId).md"
    $FilePath = Join-Path $RecipePages $FileName

    Write-Utf8File `
        -Path $FilePath `
        -Content ($Lines -join "`r`n")

    $GeneratedRecipePages++
}

# ------------------------------------------------------------
# Item index page
# ------------------------------------------------------------

$ItemIndexLines = [System.Collections.Generic.List[string]]::new()

$ItemIndexLines.Add("# Item Index")
$ItemIndexLines.Add("")
$ItemIndexLines.Add("Generated from the current RDR2PF item database.")
$ItemIndexLines.Add("")
$ItemIndexLines.Add("**Items:** $($Items.Count)")
$ItemIndexLines.Add("")
$ItemIndexLines.Add("| Item | Item ID | Description |")
$ItemIndexLines.Add("|---|---|---|")

foreach ($Item in ($Items | Sort-Object label, id)) {
    $ItemId = [string]$Item.id
    $Label  = [string]$Item.label
    $Desc   = Escape-Markdown ([string]$Item.description)
    $Safe   = Get-SafeFileName -Value $ItemId

    if ([string]::IsNullOrWhiteSpace($Label)) {
        $Label = $ItemId
    }

    if ([string]::IsNullOrWhiteSpace($Desc)) {
        $Desc = "No description available."
    }

    $ItemIndexLines.Add(
        "| [$Label](items/$Safe.md) | ``$(Escape-Markdown $ItemId)`` | $Desc |"
    )
}

Write-Utf8File `
    -Path (Join-Path $WikiRoot "items.md") `
    -Content ($ItemIndexLines -join "`r`n")

# ------------------------------------------------------------
# Recipe index page
# ------------------------------------------------------------

$RecipeIndexLines = [System.Collections.Generic.List[string]]::new()

$RecipeIndexLines.Add("# Recipe Index")
$RecipeIndexLines.Add("")
$RecipeIndexLines.Add("Generated from the current RDR2PF crafting configuration.")
$RecipeIndexLines.Add("")
$RecipeIndexLines.Add("**Recipes:** $($Recipes.Count)")
$RecipeIndexLines.Add("")
$RecipeIndexLines.Add("| Recipe | Recipe ID | Type | Ingredients |")
$RecipeIndexLines.Add("|---|---|---|---:|")

foreach ($Recipe in ($Recipes | Sort-Object name, id)) {
    $RecipeId   = [string]$Recipe.id
    $RecipeName = [string]$Recipe.name
    $RecipeType = [string]$Recipe.type
    $Safe       = Get-SafeFileName -Value $RecipeId

    if ([string]::IsNullOrWhiteSpace($RecipeName)) {
        $RecipeName = $RecipeId
    }

    if ([string]::IsNullOrWhiteSpace($RecipeType)) {
        $RecipeType = "standard"
    }

    $RecipeIndexLines.Add(
        "| [$RecipeName](recipes/$Safe.md) | ``$(Escape-Markdown $RecipeId)`` | $(Escape-Markdown $RecipeType) | $(@($Recipe.ingredients).Count) |"
    )
}

Write-Utf8File `
    -Path (Join-Path $WikiRoot "recipes.md") `
    -Content ($RecipeIndexLines -join "`r`n")

# ------------------------------------------------------------
# Missing references report
# ------------------------------------------------------------

$MissingIngredientRows = [System.Collections.Generic.List[object]]::new()
$MissingRewardRows     = [System.Collections.Generic.List[object]]::new()

foreach ($Recipe in $Recipes) {
    $RecipeId   = [string]$Recipe.id
    $RecipeName = [string]$Recipe.name

    foreach ($Ingredient in @($Recipe.ingredients)) {
        $IngredientId = [string]$Ingredient.item

        if (
            -not [string]::IsNullOrWhiteSpace($IngredientId) -and
            -not $ItemIndex.ContainsKey($IngredientId)
        ) {
            $MissingIngredientRows.Add([pscustomobject]@{
                recipe_id   = $RecipeId
                recipe_name = $RecipeName
                item_id     = $IngredientId
            })
        }
    }

    if (
        $Recipe.use_currency_mode -eq $true -or
        [string]$Recipe.type -eq "weapon"
    ) {
        continue
    }

    foreach ($Reward in @($Recipe.rewards)) {
        $RewardId = [string]$Reward.item

        if (
            -not [string]::IsNullOrWhiteSpace($RewardId) -and
            -not $ItemIndex.ContainsKey($RewardId)
        ) {
            $MissingRewardRows.Add([pscustomobject]@{
                recipe_id   = $RecipeId
                recipe_name = $RecipeName
                item_id     = $RewardId
            })
        }
    }
}

$MissingLines = [System.Collections.Generic.List[string]]::new()

$MissingLines.Add("# Missing Item References")
$MissingLines.Add("")
$MissingLines.Add("These references exist in crafting recipes but do not currently match an imported item ID.")
$MissingLines.Add("")
$MissingLines.Add("## Missing Ingredients")
$MissingLines.Add("")

if ($MissingIngredientRows.Count -gt 0) {
    $MissingLines.Add("| Recipe | Recipe ID | Missing item ID |")
    $MissingLines.Add("|---|---|---|")

    foreach ($Row in $MissingIngredientRows) {
        $SafeRecipe = Get-SafeFileName -Value $Row.recipe_id

        $MissingLines.Add(
            "| [$($Row.recipe_name)](../recipes/$SafeRecipe.md) | ``$($Row.recipe_id)`` | ``$($Row.item_id)`` |"
        )
    }
}
else {
    $MissingLines.Add("No missing ingredient definitions were found.")
}

$MissingLines.Add("")
$MissingLines.Add("## Missing Rewards")
$MissingLines.Add("")

if ($MissingRewardRows.Count -gt 0) {
    $MissingLines.Add("| Recipe | Recipe ID | Missing reward ID |")
    $MissingLines.Add("|---|---|---|")

    foreach ($Row in $MissingRewardRows) {
        $SafeRecipe = Get-SafeFileName -Value $Row.recipe_id

        $MissingLines.Add(
            "| [$($Row.recipe_name)](../recipes/$SafeRecipe.md) | ``$($Row.recipe_id)`` | ``$($Row.item_id)`` |"
        )
    }
}
else {
    $MissingLines.Add("No missing reward definitions were found.")
}

Write-Utf8File `
    -Path (Join-Path $ReportPages "missing-item-references.md") `
    -Content ($MissingLines -join "`r`n")

# ------------------------------------------------------------
# Project health report
# ------------------------------------------------------------

$LinkedIngredientItems = @(
    $Relationships |
        Where-Object { @($_.used_in).Count -gt 0 }
).Count

$CraftedItems = @(
    $Relationships |
        Where-Object { @($_.crafted_from).Count -gt 0 }
).Count

$CurrencyRecipes = @(
    $Recipes |
        Where-Object { $_.use_currency_mode -eq $true }
).Count

$WeaponRecipes = @(
    $Recipes |
        Where-Object { [string]$_.type -eq "weapon" }
).Count

$HealthLines = @(
    "# RDR2PF Compendium Project Health"
    ""
    "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    ""
    "| Metric | Count |"
    "|---|---:|"
    "| Items | $($Items.Count) |"
    "| Recipes | $($Recipes.Count) |"
    "| Relationships | $($Relationships.Count) |"
    "| Ingredient items linked | $LinkedIngredientItems |"
    "| Crafted items linked | $CraftedItems |"
    "| Currency recipes | $CurrencyRecipes |"
    "| Weapon recipes | $WeaponRecipes |"
    "| Missing ingredients | $($MissingIngredientRows.Count) |"
    "| Missing rewards | $($MissingRewardRows.Count) |"
    ""
    "## Status"
    ""
    "- Item database loaded successfully."
    "- Recipe database loaded successfully."
    "- Relationship database loaded successfully."
    "- Missing references are documented rather than silently discarded."
)

Write-Utf8File `
    -Path (Join-Path $ReportPages "project-health.md") `
    -Content ($HealthLines -join "`r`n")

# ------------------------------------------------------------
# Main wiki index
# ------------------------------------------------------------

$HomeLines = @(
    "# RDR2PF: Western Dead Compendium"
    ""
    "Automatically generated from the current RDR2PF server data."
    ""
    "## Compendium"
    ""
    "- [Items](items.md) — $($Items.Count) indexed items"
    "- [Recipes](recipes.md) — $($Recipes.Count) imported recipes"
    "- [Project Health](reports/project-health.md)"
    "- [Missing Item References](reports/missing-item-references.md)"
    ""
    "## Build Summary"
    ""
    "| Database | Records |"
    "|---|---:|"
    "| Items | $($Items.Count) |"
    "| Recipes | $($Recipes.Count) |"
    "| Relationships | $($Relationships.Count) |"
    ""
    "> These pages are generated. Update the source server data and rerun the builder instead of manually editing generated pages."
)

Write-Utf8File `
    -Path (Join-Path $WikiRoot "index.md") `
    -Content ($HomeLines -join "`r`n")



# ------------------------------------------------------------
# Generate clickable HTML Compendium pages
# Markdown generation above is intentionally preserved.
# ------------------------------------------------------------

$GeneratedHtmlItemPages   = 0
$GeneratedHtmlRecipePages = 0

Get-ChildItem -LiteralPath $ItemPages -Filter "*.html" -File -ErrorAction SilentlyContinue |
    Remove-Item -Force

Get-ChildItem -LiteralPath $RecipePages -Filter "*.html" -File -ErrorAction SilentlyContinue |
    Remove-Item -Force

foreach ($Item in ($Items | Sort-Object label, id)) {
    $ItemId = [string]$Item.id

    if ([string]::IsNullOrWhiteSpace($ItemId)) {
        continue
    }

    $Label = [string]$Item.label
    if ([string]::IsNullOrWhiteSpace($Label)) { $Label = $ItemId }

    $Description = [string]$Item.description
    if ([string]::IsNullOrWhiteSpace($Description)) {
        $Description = "No description is currently available."
    }

    $Relationship = $null
    if ($RelationshipIndex.ContainsKey($ItemId)) {
        $Relationship = $RelationshipIndex[$ItemId]
    }

    $UsedIn      = @()
    $CraftedFrom = @()
    $CraftedInto = @()

    if ($null -ne $Relationship) {
        $UsedIn      = @($Relationship.used_in)
        $CraftedFrom = @($Relationship.crafted_from)
        $CraftedInto = @($Relationship.crafted_into)
    }

    $Properties = [System.Collections.Generic.List[string]]::new()
    $Properties.Add('<tr><th>Item ID</th><td><code>' + (Escape-Html $ItemId) + '</code></td></tr>')

    foreach ($PropertyName in @('limit','type','can_use','can_remove','weight','category','group','job','metadata')) {
        if ($Item.PSObject.Properties.Name -contains $PropertyName) {
            $Value = $Item.$PropertyName
            if ($null -ne $Value -and -not [string]::IsNullOrWhiteSpace([string]$Value)) {
                $Properties.Add('<tr><th>' + (Escape-Html $PropertyName) + '</th><td>' + (Escape-Html $Value) + '</td></tr>')
            }
        }
    }

    $UsedInHtml = if ($UsedIn.Count -gt 0) {
        '<ul>' + (($UsedIn | Sort-Object -Unique | ForEach-Object { '<li>' + (Get-RecipeHtmlLink -RecipeId ([string]$_)) + '</li>' }) -join '') + '</ul>'
    } else {
        '<p class="muted">This item is not currently used as an ingredient in an imported recipe.</p>'
    }

    $ProducedByHtml = if ($CraftedFrom.Count -gt 0) {
        '<ul>' + (($CraftedFrom | Sort-Object -Unique | ForEach-Object { '<li>' + (Get-RecipeHtmlLink -RecipeId ([string]$_)) + '</li>' }) -join '') + '</ul>'
    } else {
        '<p class="muted">This item is not currently produced by an imported recipe.</p>'
    }

    $CraftedIntoHtml = if ($CraftedInto.Count -gt 0) {
        '<ul>' + (($CraftedInto | Sort-Object -Unique | ForEach-Object { '<li>' + (Get-ItemHtmlLink -ItemId ([string]$_)) + '</li>' }) -join '') + '</ul>'
    } else {
        '<p class="muted">No linked crafted item is currently recorded.</p>'
    }

    $MarkdownName = "$(Get-SafeFileName -Value $ItemId).md"

    $Body = @"
<h1>$(Escape-Html $Label)</h1>
<p class="subtitle">RDR2PF: Western Dead Compendium item page</p>
<div class="card"><p>$(Escape-Html $Description)</p></div>
<h2>Item Data</h2>
<table><tbody>$($Properties -join "")</tbody></table>
<h2>Used in Recipes</h2>
$UsedInHtml
<h2>Produced by Recipes</h2>
$ProducedByHtml
<h2>Can Craft Into</h2>
$CraftedIntoHtml
<p class="muted">Expanded source: <a href="./$MarkdownName">view generated Markdown page</a></p>
"@

    $FileName = "$(Get-SafeFileName -Value $ItemId).html"
    Write-Utf8File -Path (Join-Path $ItemPages $FileName) -Content (Get-HtmlDocument -Title $Label -Body $Body -RootPrefix "..")
    $GeneratedHtmlItemPages++
}

foreach ($Recipe in ($Recipes | Sort-Object name, id)) {
    $RecipeId = [string]$Recipe.id
    if ([string]::IsNullOrWhiteSpace($RecipeId)) { continue }

    $RecipeName = [string]$Recipe.name
    if ([string]::IsNullOrWhiteSpace($RecipeName)) { $RecipeName = $RecipeId }

    $RecipeType = [string]$Recipe.type
    if ([string]::IsNullOrWhiteSpace($RecipeType)) { $RecipeType = "standard" }

    $IngredientRows = [System.Collections.Generic.List[string]]::new()
    foreach ($Ingredient in @($Recipe.ingredients)) {
        $IngredientId = [string]$Ingredient.item
        $IngredientRows.Add(
            '<tr><td>' + (Get-ItemHtmlLink -ItemId $IngredientId) + '</td><td><code>' +
            (Escape-Html $IngredientId) + '</code></td><td>' + (Escape-Html $Ingredient.count) + '</td></tr>'
        )
    }

    if ($IngredientRows.Count -eq 0) {
        $IngredientRows.Add('<tr><td colspan="3" class="muted">No ingredients were recorded.</td></tr>')
    }

    $RewardRows = [System.Collections.Generic.List[string]]::new()
    if ($Recipe.use_currency_mode -eq $true) {
        $RewardRows.Add('<tr><td>Currency</td><td>' + (Escape-Html $Recipe.currency_type) + '</td><td>' + (Escape-Html $Recipe.currency_reward) + '</td></tr>')
    }
    else {
        foreach ($Reward in @($Recipe.rewards)) {
            $RewardId = [string]$Reward.item
            $Display = if ([string]$Recipe.type -eq 'weapon') {
                Escape-Html $RewardId
            } else {
                Get-ItemHtmlLink -ItemId $RewardId
            }
            $RewardRows.Add('<tr><td>' + $Display + '</td><td><code>' + (Escape-Html $RewardId) + '</code></td><td>' + (Escape-Html $Reward.count) + '</td></tr>')
        }
    }

    if ($RewardRows.Count -eq 0) {
        $RewardRows.Add('<tr><td colspan="3" class="muted">No reward was recorded.</td></tr>')
    }

    $MarkdownName = "$(Get-SafeFileName -Value $RecipeId).md"

    $Body = @"
<h1>$(Escape-Html $RecipeName)</h1>
<p class="subtitle">RDR2PF recipe page</p>
<table><tbody>
<tr><th>Recipe ID</th><td><code>$(Escape-Html $RecipeId)</code></td></tr>
<tr><th>Recipe type</th><td>$(Escape-Html $RecipeType)</td></tr>
<tr><th>Currency mode</th><td>$(Escape-Html ([bool]$Recipe.use_currency_mode))</td></tr>
</tbody></table>
<h2>Ingredients</h2>
<table><thead><tr><th>Item</th><th>Item ID</th><th>Count</th></tr></thead><tbody>$($IngredientRows -join "")</tbody></table>
<h2>Reward</h2>
<table><thead><tr><th>Reward</th><th>ID / Type</th><th>Count / Amount</th></tr></thead><tbody>$($RewardRows -join "")</tbody></table>
<p class="muted">Expanded source: <a href="./$MarkdownName">view generated Markdown page</a></p>
"@

    $FileName = "$(Get-SafeFileName -Value $RecipeId).html"
    Write-Utf8File -Path (Join-Path $RecipePages $FileName) -Content (Get-HtmlDocument -Title $RecipeName -Body $Body -RootPrefix "..")
    $GeneratedHtmlRecipePages++
}

$ItemCards = [System.Collections.Generic.List[string]]::new()
foreach ($Item in ($Items | Sort-Object label, id)) {
    $ItemId = [string]$Item.id
    if ([string]::IsNullOrWhiteSpace($ItemId)) { continue }
    $Label = [string]$Item.label
    if ([string]::IsNullOrWhiteSpace($Label)) { $Label = $ItemId }
    $Safe = Get-SafeFileName -Value $ItemId
    $Description = [string]$Item.description
    if ([string]::IsNullOrWhiteSpace($Description)) { $Description = "No description available." }
    $ItemCards.Add('<article class="card entry" data-search="' + (Escape-Html ($Label + ' ' + $ItemId + ' ' + $Description)) + '"><h2><a href="items/' + $Safe + '.html">' + (Escape-Html $Label) + '</a></h2><p><code>' + (Escape-Html $ItemId) + '</code></p><p>' + (Escape-Html $Description) + '</p></article>')
}

$ItemsBody = @"
<h1>Every Item A–Z</h1>
<p class="subtitle">$($Items.Count) parsed items. Click any item to open its full page.</p>
<input class="search" id="filter" type="search" placeholder="Search items..." aria-label="Search items">
<div class="grid" id="entries">$($ItemCards -join "`r`n")</div>
<script>
const filter = document.getElementById('filter');
const entries = [...document.querySelectorAll('.entry')];
filter.addEventListener('input', () => {
  const q = filter.value.toLowerCase().trim();
  entries.forEach(entry => entry.hidden = !entry.dataset.search.toLowerCase().includes(q));
});
</script>
"@
Write-Utf8File -Path (Join-Path $WikiRoot 'items.html') -Content (Get-HtmlDocument -Title 'Every Item A–Z' -Body $ItemsBody -RootPrefix '.')

$RecipeCards = [System.Collections.Generic.List[string]]::new()
foreach ($Recipe in ($Recipes | Sort-Object name, id)) {
    $RecipeId = [string]$Recipe.id
    if ([string]::IsNullOrWhiteSpace($RecipeId)) { continue }
    $RecipeName = [string]$Recipe.name
    if ([string]::IsNullOrWhiteSpace($RecipeName)) { $RecipeName = $RecipeId }
    $Safe = Get-SafeFileName -Value $RecipeId
    $RecipeCards.Add('<article class="card entry" data-search="' + (Escape-Html ($RecipeName + ' ' + $RecipeId + ' ' + [string]$Recipe.type)) + '"><h2><a href="recipes/' + $Safe + '.html">' + (Escape-Html $RecipeName) + '</a></h2><p><code>' + (Escape-Html $RecipeId) + '</code></p><p>' + (Escape-Html ([string]$Recipe.type)) + ' · ' + @($Recipe.ingredients).Count + ' ingredient(s)</p></article>')
}

$RecipesBody = @"
<h1>Recipes</h1>
<p class="subtitle">$($Recipes.Count) parsed recipes. Click any recipe to open its full page.</p>
<input class="search" id="filter" type="search" placeholder="Search recipes..." aria-label="Search recipes">
<div class="grid" id="entries">$($RecipeCards -join "`r`n")</div>
<script>
const filter = document.getElementById('filter');
const entries = [...document.querySelectorAll('.entry')];
filter.addEventListener('input', () => {
  const q = filter.value.toLowerCase().trim();
  entries.forEach(entry => entry.hidden = !entry.dataset.search.toLowerCase().includes(q));
});
</script>
"@
Write-Utf8File -Path (Join-Path $WikiRoot 'recipes.html') -Content (Get-HtmlDocument -Title 'Recipes' -Body $RecipesBody -RootPrefix '.')

$HomeBody = @"
<h1>RDR2PF: Western Dead Compendium</h1>
<div class="grid">
<article class="card"><h2><a href="items.html">Every Item A–Z</a></h2><p>$($Items.Count) clickable item pages generated from the parsed Markdown/database content.</p></article>
<article class="card"><h2><a href="recipes.html">Recipes</a></h2><p>$($Recipes.Count) clickable recipe pages with linked ingredients and rewards.</p></article>
</div>
<p class="muted">The existing Markdown pages are preserved and linked from every HTML detail page.</p>
"@
Write-Utf8File -Path (Join-Path $WikiRoot 'index.html') -Content (Get-HtmlDocument -Title 'RDR2PF Compendium' -Body $HomeBody -RootPrefix '.')


# ------------------------------------------------------------
# Final output
# ------------------------------------------------------------

Write-Host ""
Write-Host ("Item pages generated   : {0}" -f $GeneratedItemPages)
Write-Host ("Recipe pages generated : {0}" -f $GeneratedRecipePages)
Write-Host ("HTML item pages generated   : {0}" -f $GeneratedHtmlItemPages)
Write-Host ("HTML recipe pages generated : {0}" -f $GeneratedHtmlRecipePages)
Write-Host ("Missing ingredients    : {0}" -f $MissingIngredientRows.Count)
Write-Host ("Missing rewards        : {0}" -f $MissingRewardRows.Count)

Write-Host ""
Write-Host "Wiki root: $WikiRoot" -ForegroundColor Green
Write-Host "Markdown home: $(Join-Path $WikiRoot 'index.md')" -ForegroundColor Green
Write-Host "HTML home    : $(Join-Path $WikiRoot 'index.html')" -ForegroundColor Green
