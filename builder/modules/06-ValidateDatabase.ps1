param(
    [Parameter(Mandatory)]
    [psobject]$BuilderConfig
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor Cyan
Write-Host " VALIDATING DATABASE" -ForegroundColor Cyan
Write-Host "--------------------------------------------" -ForegroundColor Cyan

$Database = [string]$BuilderConfig.output.database
$Reports  = [string]$BuilderConfig.output.reports

if ([string]::IsNullOrWhiteSpace($Database)) {
    $Database = "H:\rdr2pf-westerndead\database"
}

if ([string]::IsNullOrWhiteSpace($Reports)) {
    $Reports = "H:\rdr2pf-westerndead\build-reports"
}

New-Item -Path $Reports -ItemType Directory -Force | Out-Null

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

$ItemIds = @{}
foreach ($Item in $Items) {
    $Id = [string]$Item.id

    if (-not [string]::IsNullOrWhiteSpace($Id)) {
        $ItemIds[$Id] = $true
    }
}

$MissingIngredients = [System.Collections.Generic.List[object]]::new()
$MissingRewards     = [System.Collections.Generic.List[object]]::new()
$InvalidItems       = [System.Collections.Generic.List[object]]::new()
$InvalidRecipes     = [System.Collections.Generic.List[object]]::new()
$DuplicateItemIds   = [System.Collections.Generic.List[string]]::new()
$SeenItemIds        = @{}

foreach ($Item in $Items) {
    $Id    = [string]$Item.id
    $Label = [string]$Item.label

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $InvalidItems.Add([pscustomobject]@{
            issue = "Missing item ID"
            id    = $Id
            label = $Label
        })

        continue
    }

    if ($SeenItemIds.ContainsKey($Id)) {
        $DuplicateItemIds.Add($Id)
    }
    else {
        $SeenItemIds[$Id] = $true
    }

    if ([string]::IsNullOrWhiteSpace($Label)) {
        $InvalidItems.Add([pscustomobject]@{
            issue = "Missing item label"
            id    = $Id
            label = $Label
        })
    }
}

foreach ($Recipe in $Recipes) {
    $RecipeId   = [string]$Recipe.id
    $RecipeName = [string]$Recipe.name

    if ([string]::IsNullOrWhiteSpace($RecipeId)) {
        $InvalidRecipes.Add([pscustomobject]@{
            issue = "Missing recipe ID"
            id    = $RecipeId
            name  = $RecipeName
        })

        continue
    }

    if (@($Recipe.ingredients).Count -eq 0) {
        $InvalidRecipes.Add([pscustomobject]@{
            issue = "Recipe has no ingredients"
            id    = $RecipeId
            name  = $RecipeName
        })
    }

    foreach ($Ingredient in @($Recipe.ingredients)) {
        $IngredientId = [string]$Ingredient.item

        if (
            -not [string]::IsNullOrWhiteSpace($IngredientId) -and
            -not $ItemIds.ContainsKey($IngredientId)
        ) {
            $MissingIngredients.Add([pscustomobject]@{
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

    if (@($Recipe.rewards).Count -eq 0) {
        $InvalidRecipes.Add([pscustomobject]@{
            issue = "Recipe has no rewards"
            id    = $RecipeId
            name  = $RecipeName
        })
    }

    foreach ($Reward in @($Recipe.rewards)) {
        $RewardId = [string]$Reward.item

        if (
            -not [string]::IsNullOrWhiteSpace($RewardId) -and
            -not $ItemIds.ContainsKey($RewardId)
        ) {
            $MissingRewards.Add([pscustomobject]@{
                recipe_id   = $RecipeId
                recipe_name = $RecipeName
                item_id     = $RewardId
            })
        }
    }
}

$Report = [pscustomobject][ordered]@{
    generated_at         = (Get-Date).ToString("s")
    items                = $Items.Count
    recipes              = $Recipes.Count
    relationships        = $Relationships.Count
    invalid_items        = @($InvalidItems).Count
    invalid_recipes      = @($InvalidRecipes).Count
    duplicate_item_ids   = @(
        $DuplicateItemIds |
            Sort-Object -Unique
    ).Count
    missing_ingredients  = @($MissingIngredients).Count
    missing_rewards      = @($MissingRewards).Count
}

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$ReportFile = Join-Path $Reports "database-validation-$Timestamp.json"

$Report |
    ConvertTo-Json -Depth 6 |
    Set-Content -LiteralPath $ReportFile -Encoding UTF8

$InvalidItems |
    ConvertTo-Json -Depth 6 |
    Set-Content `
        -LiteralPath (Join-Path $Reports "invalid-items.json") `
        -Encoding UTF8

$InvalidRecipes |
    ConvertTo-Json -Depth 6 |
    Set-Content `
        -LiteralPath (Join-Path $Reports "invalid-recipes.json") `
        -Encoding UTF8

$MissingIngredients |
    ConvertTo-Json -Depth 6 |
    Set-Content `
        -LiteralPath (Join-Path $Reports "validation-missing-ingredients.json") `
        -Encoding UTF8

$MissingRewards |
    ConvertTo-Json -Depth 6 |
    Set-Content `
        -LiteralPath (Join-Path $Reports "validation-missing-rewards.json") `
        -Encoding UTF8

@(
    $DuplicateItemIds |
        Sort-Object -Unique
) |
    Set-Content `
        -LiteralPath (Join-Path $Reports "duplicate-item-ids.txt") `
        -Encoding UTF8

Write-Host ""
Write-Host ("Items validated       : {0}" -f $Items.Count)
Write-Host ("Recipes validated     : {0}" -f $Recipes.Count)
Write-Host ("Relationships checked : {0}" -f $Relationships.Count)
Write-Host ("Invalid items         : {0}" -f $InvalidItems.Count)
Write-Host ("Invalid recipes       : {0}" -f $InvalidRecipes.Count)
Write-Host ("Duplicate item IDs    : {0}" -f @(
    $DuplicateItemIds | Sort-Object -Unique
).Count)
Write-Host ("Missing ingredients   : {0}" -f $MissingIngredients.Count)
Write-Host ("Missing rewards       : {0}" -f $MissingRewards.Count)

Write-Host ""
Write-Host "Validation report: $ReportFile" -ForegroundColor Green
