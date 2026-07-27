param(
    [Parameter(Mandatory = $true)]
    [string]$CatalogPath,
    [string]$InventoryPath = "pixel-art-production/assets/asset-inventory.json"
)

$ErrorActionPreference = "Stop"
$workspaceRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $workspaceRoot ".."))
$catalogFile = if ([System.IO.Path]::IsPathRooted($CatalogPath)) {
    $CatalogPath
} else {
    Join-Path $repoRoot $CatalogPath
}
$inventoryFile = if ([System.IO.Path]::IsPathRooted($InventoryPath)) {
    $InventoryPath
} else {
    Join-Path $repoRoot $InventoryPath
}
$catalog = Get-Content -LiteralPath $catalogFile -Raw | ConvertFrom-Json
$inventory = Get-Content -LiteralPath $inventoryFile -Raw | ConvertFrom-Json
$ceilings = @{}
foreach ($asset in @($inventory.assets)) {
    $ceilings[[string]$asset.id] = [int]$asset.frame_ceiling
}
$errors = [System.Collections.Generic.List[string]]::new()
$total = 0
$byFamily = @{}
foreach ($asset in @($catalog.assets)) {
    $family = [string]$asset.family
    $count = @($asset.frames).Count
    $total += $count
    $byFamily[$family] = [int]$byFamily[$family] + $count
}
foreach ($entry in $byFamily.GetEnumerator()) {
    if (-not $ceilings.ContainsKey($entry.Name)) {
        $errors.Add("catalog family is absent from inventory: $($entry.Name)")
    } elseif ([int]$entry.Value -gt [int]$ceilings[$entry.Name]) {
        $errors.Add("$($entry.Name) uses $($entry.Value) frames; ceiling=$($ceilings[$entry.Name])")
    }
}
if ($total -gt [int]$inventory.raster_frame_ceiling) {
    $errors.Add("catalog uses $total frames; global ceiling=$($inventory.raster_frame_ceiling)")
}
if ($errors.Count -gt 0) {
    throw "Pixel asset frame budget validation failed:`n$(($errors | ForEach-Object { "- $_" }) -join "`n")"
}
Write-Output "Pixel asset frame budget valid: $total / $($inventory.raster_frame_ceiling)"
