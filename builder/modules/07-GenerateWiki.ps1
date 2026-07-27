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
# Final output
# ------------------------------------------------------------

Write-Host ""
Write-Host ("Item pages generated   : {0}" -f $GeneratedItemPages)
Write-Host ("Recipe pages generated : {0}" -f $GeneratedRecipePages)
Write-Host ("Missing ingredients    : {0}" -f $MissingIngredientRows.Count)
Write-Host ("Missing rewards        : {0}" -f $MissingRewardRows.Count)

Write-Host ""
Write-Host "Wiki root: $WikiRoot" -ForegroundColor Green
Write-Host "Wiki home: $(Join-Path $WikiRoot 'index.md')" -ForegroundColor Green
