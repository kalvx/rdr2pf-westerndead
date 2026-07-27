param(
    [Parameter(Mandatory)]
    [psobject]$BuilderConfig
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor Cyan
Write-Host " BUILDING SEARCH INDEX" -ForegroundColor Cyan
Write-Host "--------------------------------------------" -ForegroundColor Cyan

# ------------------------------------------------------------
# Resolve folders
# ------------------------------------------------------------

$Database = [string]$BuilderConfig.output.database

if ([string]::IsNullOrWhiteSpace($Database)) {
    $Database = "H:\rdr2pf-westerndead\database"
}

$CompendiumRoot = Split-Path -Parent $Database
$WikiRoot       = Join-Path $CompendiumRoot "wiki"

New-Item -Path $Database -ItemType Directory -Force | Out-Null
New-Item -Path $WikiRoot -ItemType Directory -Force | Out-Null

# ------------------------------------------------------------
# Required files
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
        [AllowNull()]
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return "unnamed"
    }

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

function Get-UniqueWords {
    param(
        [AllowNull()]
        [object[]]$Values
    )

    $Words = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )

    foreach ($Value in @($Values)) {
        if ($null -eq $Value) {
            continue
        }

        $Text = [string]$Value

        if ([string]::IsNullOrWhiteSpace($Text)) {
            continue
        }

        $Normalized = $Text.ToLowerInvariant()
        $Normalized = $Normalized -replace '[_\-]', ' '
        $Normalized = $Normalized -replace '[^a-z0-9\s]', ' '

        foreach ($Word in ($Normalized -split '\s+')) {
            if (
                -not [string]::IsNullOrWhiteSpace($Word) -and
                $Word.Length -ge 2
            ) {
                [void]$Words.Add($Word)
            }
        }
    }

    return @($Words | Sort-Object)
}

# ------------------------------------------------------------
# Build lookup indexes
# ------------------------------------------------------------

$ItemIndex         = @{}
$RecipeIndex       = @{}
$RelationshipIndex = @{}

foreach ($Item in $Items) {
    $ItemId = [string]$Item.id

    if (-not [string]::IsNullOrWhiteSpace($ItemId)) {
        $ItemIndex[$ItemId] = $Item
    }
}

foreach ($Recipe in $Recipes) {
    $RecipeId = [string]$Recipe.id

    if (-not [string]::IsNullOrWhiteSpace($RecipeId)) {
        $RecipeIndex[$RecipeId] = $Recipe
    }
}

foreach ($Relationship in $Relationships) {
    $ItemId = [string]$Relationship.id

    if (-not [string]::IsNullOrWhiteSpace($ItemId)) {
        $RelationshipIndex[$ItemId] = $Relationship
    }
}

# ------------------------------------------------------------
# Create search entries
# ------------------------------------------------------------

$SearchEntries = [System.Collections.Generic.List[object]]::new()

$ItemEntryCount   = 0
$RecipeEntryCount = 0

foreach ($Item in $Items) {
    $ItemId = [string]$Item.id

    if ([string]::IsNullOrWhiteSpace($ItemId)) {
        continue
    }

    $Label = [string]$Item.label

    if ([string]::IsNullOrWhiteSpace($Label)) {
        $Label = $ItemId
    }

    $Description = [string]$Item.description
    $Relationship = $null

    if ($RelationshipIndex.ContainsKey($ItemId)) {
        $Relationship = $RelationshipIndex[$ItemId]
    }

    $UsedIn      = @()
    $CraftedFrom = @()
    $CraftedInto = @()

    if ($null -ne $Relationship) {
        $UsedIn      = @($Relationship.used_in | Where-Object { $_ })
        $CraftedFrom = @($Relationship.crafted_from | Where-Object { $_ })
        $CraftedInto = @($Relationship.crafted_into | Where-Object { $_ })
    }

    $RelatedRecipeNames = @()

    foreach ($RecipeId in @($UsedIn + $CraftedFrom)) {
        if ($RecipeIndex.ContainsKey([string]$RecipeId)) {
            $RelatedRecipeNames += [string]$RecipeIndex[[string]$RecipeId].name
        }
    }

    $RelatedItemNames = @()

    foreach ($RelatedItemId in $CraftedInto) {
        if ($ItemIndex.ContainsKey([string]$RelatedItemId)) {
            $RelatedItemNames += [string]$ItemIndex[[string]$RelatedItemId].label
        }
    }

    $KeywordSources = @(
        $ItemId
        $Label
        $Description
        [string]$Item.type
        [string]$Item.category
        [string]$Item.icon
    ) + $UsedIn + $CraftedFrom + $CraftedInto +
        $RelatedRecipeNames + $RelatedItemNames

    $Keywords = Get-UniqueWords -Values $KeywordSources

    $Aliases = @(
        $ItemId
        ($ItemId -replace '_', ' ')
        ($ItemId -replace '-', ' ')
        $Label
    ) |
        Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } |
        Sort-Object -Unique

    $SearchText = @(
        $ItemId
        $Label
        $Description
        [string]$Item.type
        [string]$Item.category
        [string]$Item.icon
        $Aliases
        $Keywords
        $UsedIn
        $CraftedFrom
        $CraftedInto
        $RelatedRecipeNames
        $RelatedItemNames
    ) -join " "

    $Entry = [ordered]@{
        type               = "item"
        id                 = $ItemId
        title              = $Label
        label              = $Label
        description        = $Description
        item_type          = [string]$Item.type
        category           = [string]$Item.category
        icon               = [string]$Item.icon
        aliases            = @($Aliases)
        keywords           = @($Keywords)
        recipes_used_in    = @($UsedIn | Sort-Object -Unique)
        recipes_created_by = @($CraftedFrom | Sort-Object -Unique)
        crafted_into       = @($CraftedInto | Sort-Object -Unique)
        wiki_path          = "items/$(Get-SafeFileName -Value $ItemId).md"
        search_text        = $SearchText.ToLowerInvariant()
    }

    $SearchEntries.Add([pscustomobject]$Entry)
    $ItemEntryCount++
}

foreach ($Recipe in $Recipes) {
    $RecipeId = [string]$Recipe.id

    if ([string]::IsNullOrWhiteSpace($RecipeId)) {
        continue
    }

    $RecipeName = [string]$Recipe.name

    if ([string]::IsNullOrWhiteSpace($RecipeName)) {
        $RecipeName = $RecipeId
    }

    $IngredientIds    = @()
    $IngredientLabels = @()
    $RewardIds        = @()
    $RewardLabels     = @()

    foreach ($Ingredient in @($Recipe.ingredients)) {
        $IngredientId = [string]$Ingredient.item

        if ([string]::IsNullOrWhiteSpace($IngredientId)) {
            continue
        }

        $IngredientIds += $IngredientId

        if ($ItemIndex.ContainsKey($IngredientId)) {
            $IngredientLabels += [string]$ItemIndex[$IngredientId].label
        }
        else {
            $IngredientLabels += $IngredientId
        }
    }

    foreach ($Reward in @($Recipe.rewards)) {
        $RewardId = [string]$Reward.item

        if ([string]::IsNullOrWhiteSpace($RewardId)) {
            continue
        }

        $RewardIds += $RewardId

        if ($ItemIndex.ContainsKey($RewardId)) {
            $RewardLabels += [string]$ItemIndex[$RewardId].label
        }
        else {
            $RewardLabels += $RewardId
        }
    }

    $KeywordSources = @(
        $RecipeId
        $RecipeName
        [string]$Recipe.type
        [string]$Recipe.category
        [string]$Recipe.currency_type
        [string]$Recipe.currency_reward
    ) + $IngredientIds + $IngredientLabels +
        $RewardIds + $RewardLabels

    $Keywords = Get-UniqueWords -Values $KeywordSources

    $Aliases = @(
        $RecipeId
        ($RecipeId -replace '_', ' ')
        ($RecipeId -replace '-', ' ')
        $RecipeName
    ) |
        Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } |
        Sort-Object -Unique

    $SearchText = @(
        $RecipeId
        $RecipeName
        [string]$Recipe.type
        [string]$Recipe.category
        [string]$Recipe.currency_type
        [string]$Recipe.currency_reward
        $Aliases
        $Keywords
        $IngredientIds
        $IngredientLabels
        $RewardIds
        $RewardLabels
    ) -join " "

    $Entry = [ordered]@{
        type               = "recipe"
        id                 = $RecipeId
        title              = $RecipeName
        name               = $RecipeName
        recipe_type        = [string]$Recipe.type
        category           = [string]$Recipe.category
        ingredients        = @($IngredientIds)
        ingredient_labels  = @($IngredientLabels)
        rewards            = @($RewardIds)
        reward_labels      = @($RewardLabels)
        use_currency_mode  = [bool]$Recipe.use_currency_mode
        currency_type      = $Recipe.currency_type
        currency_reward    = $Recipe.currency_reward
        aliases            = @($Aliases)
        keywords           = @($Keywords)
        wiki_path          = "recipes/$(Get-SafeFileName -Value $RecipeId).md"
        search_text        = $SearchText.ToLowerInvariant()
    }

    $SearchEntries.Add([pscustomobject]$Entry)
    $RecipeEntryCount++
}

# ------------------------------------------------------------
# Write JSON database
# ------------------------------------------------------------

$SearchDatabase = [ordered]@{
    generated_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
    version      = 1
    counts       = [ordered]@{
        total   = $SearchEntries.Count
        items   = $ItemEntryCount
        recipes = $RecipeEntryCount
    }
    entries      = @(
        $SearchEntries |
            Sort-Object type, title, id
    )
}

$SearchJsonFile = Join-Path $Database "search-index.json"

$SearchJson = $SearchDatabase |
    ConvertTo-Json -Depth 15

Write-Utf8File `
    -Path $SearchJsonFile `
    -Content $SearchJson

# ------------------------------------------------------------
# Write flat CSV for inspection
# ------------------------------------------------------------

$SearchCsvFile = Join-Path $Database "search-index.csv"

$SearchEntries |
    Sort-Object type, title, id |
    Select-Object `
        type,
        id,
        title,
        description,
        recipe_type,
        item_type,
        category,
        @{
            Name       = "ingredients"
            Expression = { @($_.ingredients) -join "; " }
        },
        @{
            Name       = "rewards"
            Expression = { @($_.rewards) -join "; " }
        },
        @{
            Name       = "recipes_used_in"
            Expression = { @($_.recipes_used_in) -join "; " }
        },
        @{
            Name       = "recipes_created_by"
            Expression = { @($_.recipes_created_by) -join "; " }
        },
        @{
            Name       = "keywords"
            Expression = { @($_.keywords) -join "; " }
        },
        wiki_path |
    Export-Csv `
        -LiteralPath $SearchCsvFile `
        -NoTypeInformation `
        -Encoding UTF8

# ------------------------------------------------------------
# Generate wiki search catalog
# ------------------------------------------------------------

$SearchWikiFile = Join-Path $WikiRoot "search.md"
$WikiLines      = [System.Collections.Generic.List[string]]::new()

$WikiLines.Add("# Search Index")
$WikiLines.Add("")
$WikiLines.Add("This catalog contains every indexed item and recipe currently imported into the RDR2PF compendium.")
$WikiLines.Add("")
$WikiLines.Add("| Indexed record | Count |")
$WikiLines.Add("|---|---:|")
$WikiLines.Add("| Items | $ItemEntryCount |")
$WikiLines.Add("| Recipes | $RecipeEntryCount |")
$WikiLines.Add("| Total searchable records | $($SearchEntries.Count) |")
$WikiLines.Add("")
$WikiLines.Add("> Use your browser's page search with **Ctrl+F** to locate an item ID, item name, recipe, ingredient, reward, weapon ID, or keyword.")
$WikiLines.Add("")
$WikiLines.Add("## Items")
$WikiLines.Add("")
$WikiLines.Add("| Item | Item ID | Used in | Created by | Keywords |")
$WikiLines.Add("|---|---|---:|---:|---|")

foreach ($Entry in (
    $SearchEntries |
        Where-Object { $_.type -eq "item" } |
        Sort-Object title, id
)) {
    $Title    = Escape-Markdown ([string]$Entry.title)
    $Id       = Escape-Markdown ([string]$Entry.id)
    $UsedIn   = @($Entry.recipes_used_in).Count
    $Created  = @($Entry.recipes_created_by).Count
    $Keywords = Escape-Markdown ((@($Entry.keywords) | Select-Object -First 12) -join ", ")

    $WikiLines.Add(
        "| [$Title]($($Entry.wiki_path)) | ``$Id`` | $UsedIn | $Created | $Keywords |"
    )
}

$WikiLines.Add("")
$WikiLines.Add("## Recipes")
$WikiLines.Add("")
$WikiLines.Add("| Recipe | Recipe ID | Type | Ingredients | Rewards |")
$WikiLines.Add("|---|---|---|---|---|")

foreach ($Entry in (
    $SearchEntries |
        Where-Object { $_.type -eq "recipe" } |
        Sort-Object title, id
)) {
    $Title       = Escape-Markdown ([string]$Entry.title)
    $Id          = Escape-Markdown ([string]$Entry.id)
    $RecipeType  = Escape-Markdown ([string]$Entry.recipe_type)
    $Ingredients = Escape-Markdown (@($Entry.ingredients) -join ", ")

    if ($Entry.use_currency_mode -eq $true) {
        $Rewards = "Currency: $($Entry.currency_type) x $($Entry.currency_reward)"
    }
    else {
        $Rewards = Escape-Markdown (@($Entry.rewards) -join ", ")
    }

    $WikiLines.Add(
        "| [$Title]($($Entry.wiki_path)) | ``$Id`` | $RecipeType | $Ingredients | $Rewards |"
    )
}

$WikiLines.Add("")
$WikiLines.Add("---")
$WikiLines.Add("")
$WikiLines.Add("[Back to Compendium Home](index.md)")

Write-Utf8File `
    -Path $SearchWikiFile `
    -Content ($WikiLines -join "`r`n")

# ------------------------------------------------------------
# Add search link to wiki homepage
# ------------------------------------------------------------

$WikiHome = Join-Path $WikiRoot "index.md"

if (Test-Path -LiteralPath $WikiHome) {
    $HomeText = Get-Content -LiteralPath $WikiHome -Raw

    if ($HomeText -notmatch '(?im)^\s*-\s*\[Search Index\]\(search\.md\)') {
        $RecipeLinkPattern = '(?m)^(\s*-\s*\[Recipes\]\(recipes\.md\).*)$'

        if ($HomeText -match $RecipeLinkPattern) {
            $HomeText = [regex]::Replace(
                $HomeText,
                $RecipeLinkPattern,
                '$1' + "`r`n- [Search Index](search.md) - $($SearchEntries.Count) searchable records",
                1
            )
        }
        else {
            $HomeText += "`r`n`r`n- [Search Index](search.md) - $($SearchEntries.Count) searchable records`r`n"
        }

        Write-Utf8File `
            -Path $WikiHome `
            -Content $HomeText
    }
}

# ------------------------------------------------------------
# Final output
# ------------------------------------------------------------

Write-Host ""
Write-Host ("Item entries indexed   : {0}" -f $ItemEntryCount)
Write-Host ("Recipe entries indexed : {0}" -f $RecipeEntryCount)
Write-Host ("Total search records   : {0}" -f $SearchEntries.Count)

Write-Host ""
Write-Host "Search JSON: $SearchJsonFile" -ForegroundColor Green
Write-Host "Search CSV:  $SearchCsvFile" -ForegroundColor Green
Write-Host "Wiki search: $SearchWikiFile" -ForegroundColor Green
