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
$allowedMethods = @("imagegen_assisted", "direct_pixel", "derived_view", "live_ui")
$allowedGroups = @(
    "world",
    "player",
    "mobile_enemies",
    "stationary_enemies",
    "bosses",
    "player_projectiles",
    "hostile_projectiles",
    "secondaries",
    "pickups",
    "impacts",
    "combat_overlays",
    "ui"
)
$guideBySize = @{
    16 = 512
    24 = 768
    32 = 512
    48 = 768
    64 = 512
    96 = 768
}
$ids = @{}
$categoryCounts = @{}
$targetCounts = @{}
$methodCounts = @{}
$frameTotal = 0
$jobTotal = 0

if ([int]$inventory.schema_version -ne 2) {
    $errors.Add("schema_version must be 2")
}
if ($null -eq $inventory.assets -or @($inventory.assets).Count -eq 0) {
    $errors.Add("assets must contain at least one entry")
}
if (@($inventory.assets).Count -ne 40) {
    $errors.Add("inventory must contain exactly 40 asset families")
}
if ([int]$inventory.raster_frame_ceiling -ne 678) {
    $errors.Add("raster_frame_ceiling must be 678")
}
if ([int]$inventory.canonical_job_total -ne 44) {
    $errors.Add("canonical_job_total must be 44")
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

    $method = [string]$asset.production_method
    if ($method -notin $allowedMethods) {
        $errors.Add("$id has unknown production_method: $method")
    }
    $methodCounts[$method] = 1 + [int]$methodCounts[$method]

    $runtimeGroup = [string]$asset.runtime_group
    if ($runtimeGroup -notin $allowedGroups) {
        $errors.Add("$id has unknown runtime_group: $runtimeGroup")
    }

    if ([string]$asset.priority -notin $allowedPriorities) {
        $errors.Add("$id has unknown priority: $($asset.priority)")
    }

    $size = @($asset.master_size)
    if ($size.Count -ne 2 -or [int]$size[0] -le 0 -or [int]$size[1] -le 0) {
        $errors.Add("$id has invalid master_size")
    } elseif ([int]$size[0] -ne [int]$size[1]) {
        $errors.Add("$id master_size must be square")
    } elseif ($id -eq "dynamic_combat_ui") {
        if ([int]$asset.guide_size -ne 0) {
            $errors.Add("$id guide_size must be 0")
        }
    } elseif (-not $guideBySize.ContainsKey([int]$size[0])) {
        $errors.Add("$id has unsupported master_size: $($size[0])")
    } elseif ([int]$asset.guide_size -ne [int]$guideBySize[[int]$size[0]]) {
        $errors.Add("$id guide_size does not match master_size")
    }

    if ([int]$asset.directions -notin @(0, 1, 2, 4, 8, 16)) {
        $errors.Add("$id has invalid directions: $($asset.directions)")
    }

    $variants = @($asset.variants)
    if ($variants.Count -eq 0) {
        $errors.Add("$id has no variants")
    }
    if (@($variants | Sort-Object -Unique).Count -ne $variants.Count) {
        $errors.Add("$id contains duplicate variants")
    }

    $frameCeiling = [int]$asset.frame_ceiling
    $canonicalJobs = [int]$asset.canonical_jobs
    if ($frameCeiling -lt 0) {
        $errors.Add("$id frame_ceiling must not be negative")
    }
    if ($canonicalJobs -lt 0) {
        $errors.Add("$id canonical_jobs must not be negative")
    }
    if ($method -eq "imagegen_assisted" -and $canonicalJobs -le 0) {
        $errors.Add("$id imagegen_assisted work must declare canonical_jobs")
    }
    if ($method -ne "imagegen_assisted" -and $canonicalJobs -ne 0) {
        $errors.Add("$id non-ImageGen work must have canonical_jobs=0")
    }
    if ($target -in @("procedural_pixel", "live_ui") -and $frameCeiling -ne 0) {
        $errors.Add("$id $target work must have frame_ceiling=0")
    }
    if (
        $target -eq "raster_atlas" -and
        $method -ne "derived_view" -and
        $frameCeiling -le 0
    ) {
        $errors.Add("$id raster_atlas work must have a positive frame_ceiling")
    }
    $frameTotal += $frameCeiling
    $jobTotal += $canonicalJobs

    foreach ($owner in @($asset.current_owner)) {
        $ownerPath = [System.IO.Path]::GetFullPath((Join-Path $repoRoot ([string]$owner)))
        if (
            -not [System.IO.File]::Exists($ownerPath) -and
            -not [System.IO.Directory]::Exists($ownerPath)
        ) {
            $errors.Add("$id references missing current_owner: $owner")
        }
    }
}

if ($frameTotal -ne [int]$inventory.raster_frame_ceiling) {
    $errors.Add(
        "frame ceilings sum to $frameTotal; expected $($inventory.raster_frame_ceiling)"
    )
}
if ($jobTotal -ne [int]$inventory.canonical_job_total) {
    $errors.Add(
        "canonical jobs sum to $jobTotal; expected $($inventory.canonical_job_total)"
    )
}

if ($errors.Count -gt 0) {
    $details = ($errors | ForEach-Object { "- $_" }) -join [Environment]::NewLine
    throw "Pixel asset inventory validation failed with $($errors.Count) error(s).$([Environment]::NewLine)$details"
}

Write-Output "Pixel asset inventory valid: $($ids.Count) asset families"
Write-Output "Raster frame ceiling: $frameTotal; ImageGen canonical jobs: $jobTotal"
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
Write-Output "Methods: $(
    ($methodCounts.GetEnumerator() | Sort-Object Name | ForEach-Object {
        "$($_.Name)=$($_.Value)"
    }) -join ", "
)"
