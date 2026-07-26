param(
    [string]$InventoryPath = "docs/design/pixel-art-asset-pipeline/asset-inventory.json"
)

$ErrorActionPreference = "Stop"

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$inventoryFile = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $InventoryPath))
if (-not [System.IO.File]::Exists($inventoryFile)) {
    throw "Pixel asset inventory does not exist: $inventoryFile"
}

$inventory = Get-Content -LiteralPath $inventoryFile -Raw | ConvertFrom-Json
$errors = [System.Collections.Generic.List[string]]::new()
$allowedTargets = @("raster_atlas", "procedural_pixel", "live_ui")
$allowedPriorities = @("P0", "P1", "P2")
$ids = @{}
$categoryCounts = @{}
$targetCounts = @{}

if ([int]$inventory.schema_version -ne 1) {
    $errors.Add("schema_version must be 1")
}
if ($null -eq $inventory.assets -or @($inventory.assets).Count -eq 0) {
    $errors.Add("assets must contain at least one entry")
}

foreach ($asset in @($inventory.assets)) {
    $id = [string]$asset.id
    if ($id -notmatch "^[a-z0-9_]+$") {
        $errors.Add("invalid asset id: $id")
        continue
    }
    if ($ids.ContainsKey($id)) {
        $errors.Add("duplicate asset id: $id")
    }
    $ids[$id] = $true

    $category = [string]$asset.category
    if ([string]::IsNullOrWhiteSpace($category)) {
        $errors.Add("$id has no category")
    }
    $categoryCounts[$category] = 1 + [int]$categoryCounts[$category]

    $target = [string]$asset.target_representation
    if ($target -notin $allowedTargets) {
        $errors.Add("$id has unknown target_representation: $target")
    }
    $targetCounts[$target] = 1 + [int]$targetCounts[$target]

    if ([string]$asset.priority -notin $allowedPriorities) {
        $errors.Add("$id has unknown priority: $($asset.priority)")
    }

    $size = @($asset.master_size)
    if ($size.Count -ne 2 -or [int]$size[0] -le 0 -or [int]$size[1] -le 0) {
        $errors.Add("$id has invalid master_size")
    }
    if ([int]$asset.directions -lt 0 -or [int]$asset.directions -gt 16) {
        $errors.Add("$id has invalid directions: $($asset.directions)")
    }

    $variants = @($asset.variants)
    if ($variants.Count -eq 0) {
        $errors.Add("$id has no variants")
    }
    if (@($variants | Sort-Object -Unique).Count -ne $variants.Count) {
        $errors.Add("$id contains duplicate variants")
    }

    foreach ($owner in @($asset.current_owner)) {
        $ownerPath = [System.IO.Path]::GetFullPath((Join-Path $repoRoot ([string]$owner)))
        if (-not [System.IO.File]::Exists($ownerPath) -and -not [System.IO.Directory]::Exists($ownerPath)) {
            $errors.Add("$id references missing current_owner: $owner")
        }
    }
}

if ($errors.Count -gt 0) {
    $details = ($errors | ForEach-Object { "- $_" }) -join [Environment]::NewLine
    throw "Pixel asset inventory validation failed with $($errors.Count) error(s).$([Environment]::NewLine)$details"
}

Write-Output "Pixel asset inventory valid: $($ids.Count) asset families"
Write-Output "Categories: $(
    ($categoryCounts.GetEnumerator() | Sort-Object Name | ForEach-Object {
        "$($_.Name)=$($_.Value)"
    }) -join ", "
)"
Write-Output "Targets: $(
    ($targetCounts.GetEnumerator() | Sort-Object Name | ForEach-Object {
        "$($_.Name)=$($_.Value)"
    }) -join ", "
)"
