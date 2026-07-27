param(
    [Parameter(Mandatory)]
    [psobject]$BuilderConfig
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor Cyan
Write-Host " BUILDING ITEM RELATIONSHIPS" -ForegroundColor Cyan
Write-Host "--------------------------------------------" -ForegroundColor Cyan

# Resolve output directories from builder-config.json.
$Database = [string]$BuilderConfig.output.database
$Reports  = [string]$BuilderConfig.output.reports

# Safe fallbacks for the current RDR2PF builder layout.
if ([string]::IsNullOrWhiteSpace($Database)) {
    $Database = "H:\rdr2pf-westerndead\database"
}

if ([string]::IsNullOrWhiteSpace($Reports)) {
    $Reports = "H:\rdr2pf-westerndead\build-reports"
}

$ItemsFile         = Join-Path $Database "items.json"
$RecipesFile       = Join-Path $Database "recipes.json"
$RelationshipsFile = Join-Path $Database "item-relationships.json"

if (-not (Test-Path -LiteralPath $ItemsFile)) {
    throw "Items file not found: $ItemsFile"
}

if (-not (Test-Path -LiteralPath $RecipesFile)) {
    throw "Recipes file not found: $RecipesFile"
}

New-Item -Path $Database -ItemType Directory -Force | Out-Null
New-Item -Path $Reports -ItemType Directory -Force | Out-Null

$Items = Get-Content -LiteralPath $ItemsFile -Raw |
    ConvertFrom-Json

$Recipes = Get-Content -LiteralPath $RecipesFile -Raw |
    ConvertFrom-Json

$Index = @{}

foreach ($Item in $Items) {
    $ItemId = [string]$Item.id

    if ([string]::IsNullOrWhiteSpace($ItemId)) {
        continue
    }

    $Index[$ItemId] = [ordered]@{
        id                 = $ItemId
        label              = [string]$Item.label
        used_in            = [System.Collections.Generic.List[string]]::new()
        crafted_from       = [System.Collections.Generic.List[string]]::new()
        crafted_into       = [System.Collections.Generic.List[string]]::new()
        ingredient_recipes = [System.Collections.Generic.List[string]]::new()
        reward_recipes     = [System.Collections.Generic.List[string]]::new()
    }
}

$MissingIngredients = [System.Collections.Generic.List[string]]::new()
$MissingRewards     = [System.Collections.Generic.List[string]]::new()
$CurrencyRecipes    = [System.Collections.Generic.List[object]]::new()
$WeaponRecipes      = [System.Collections.Generic.List[object]]::new()

foreach ($Recipe in $Recipes) {
    $RecipeId   = [string]$Recipe.id
    $RecipeName = [string]$Recipe.name

    foreach ($Ingredient in @($Recipe.ingredients)) {
        $IngredientId = [string]$Ingredient.item

        if ([string]::IsNullOrWhiteSpace($IngredientId)) {
            continue
        }

        if ($Index.ContainsKey($IngredientId)) {
            $Index[$IngredientId].used_in.Add($RecipeId)
            $Index[$IngredientId].ingredient_recipes.Add($RecipeId)
        }
        else {
            $MissingIngredients.Add(
                "$RecipeId -> $IngredientId"
            )
        }
    }

    if ($Recipe.use_currency_mode -eq $true) {
        $CurrencyRecipes.Add([pscustomobject][ordered]@{
            recipe_id      = $RecipeId
            recipe_name    = $RecipeName
            currency_type  = $Recipe.currency_type
            currency_reward = $Recipe.currency_reward
        })

        continue
    }

    $IsWeaponRecipe = (
        [string]$Recipe.type -eq "weapon"
    )

    foreach ($Reward in @($Recipe.rewards)) {
        $RewardId = [string]$Reward.item

        if ([string]::IsNullOrWhiteSpace($RewardId)) {
            continue
        }

        if ($IsWeaponRecipe) {
            $WeaponRecipes.Add([pscustomobject][ordered]@{
                recipe_id   = $RecipeId
                recipe_name = $RecipeName
                weapon_id   = $RewardId
                count       = $Reward.count
            })

            continue
        }

        if ($Index.ContainsKey($RewardId)) {
            $Index[$RewardId].crafted_from.Add($RecipeId)
            $Index[$RewardId].reward_recipes.Add($RecipeId)
        }
        else {
            $MissingRewards.Add(
                "$RecipeId -> $RewardId"
            )
        }

        foreach ($Ingredient in @($Recipe.ingredients)) {
            $IngredientId = [string]$Ingredient.item

            if (
                -not [string]::IsNullOrWhiteSpace($IngredientId) -and
                $Index.ContainsKey($IngredientId)
            ) {
                $Index[$IngredientId].crafted_into.Add($RewardId)
            }
        }
    }
}

$Relationships = foreach ($Entry in $Index.Values) {
    [pscustomobject][ordered]@{
        id                 = $Entry.id
        label              = $Entry.label
        used_in            = @($Entry.used_in | Sort-Object -Unique)
        crafted_from       = @($Entry.crafted_from | Sort-Object -Unique)
        crafted_into       = @($Entry.crafted_into | Sort-Object -Unique)
        ingredient_recipes = @($Entry.ingredient_recipes | Sort-Object -Unique)
        reward_recipes     = @($Entry.reward_recipes | Sort-Object -Unique)
    }
}

$Relationships = @(
    $Relationships |
        Sort-Object label, id
)

$Relationships |
    ConvertTo-Json -Depth 10 |
    Set-Content -LiteralPath $RelationshipsFile -Encoding UTF8

$MissingIngredients |
    Sort-Object -Unique |
    Set-Content -LiteralPath (
        Join-Path $Reports "missing-ingredients.txt"
    ) -Encoding UTF8

$MissingRewards |
    Sort-Object -Unique |
    Set-Content -LiteralPath (
        Join-Path $Reports "missing-rewards.txt"
    ) -Encoding UTF8

$CurrencyRecipes |
    ConvertTo-Json -Depth 6 |
    Set-Content -LiteralPath (
        Join-Path $Reports "currency-recipes.json"
    ) -Encoding UTF8

$WeaponRecipes |
    ConvertTo-Json -Depth 6 |
    Set-Content -LiteralPath (
        Join-Path $Reports "weapon-recipes.json"
    ) -Encoding UTF8

$LinkedIngredients = @(
    $Relationships |
        Where-Object { $_.used_in.Count -gt 0 }
).Count

$CraftedItems = @(
    $Relationships |
        Where-Object { $_.crafted_from.Count -gt 0 }
).Count

Write-Host ""
Write-Host ("Items indexed       : {0}" -f $Relationships.Count)
Write-Host ("Ingredients linked  : {0}" -f $LinkedIngredients)
Write-Host ("Crafted items linked: {0}" -f $CraftedItems)
Write-Host ("Currency recipes    : {0}" -f $CurrencyRecipes.Count)
Write-Host ("Weapon recipes      : {0}" -f $WeaponRecipes.Count)
Write-Host ("Missing ingredients : {0}" -f @(
    $MissingIngredients | Sort-Object -Unique
).Count)
Write-Host ("Missing rewards     : {0}" -f @(
    $MissingRewards | Sort-Object -Unique
).Count)

Write-Host ""
Write-Host "Relationships: $RelationshipsFile" -ForegroundColor Green

