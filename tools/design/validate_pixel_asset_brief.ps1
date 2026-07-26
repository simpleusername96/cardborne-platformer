param(
    [Parameter(Mandatory = $true)]
    [string]$BriefPath
)

$ErrorActionPreference = "Stop"

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$briefFile = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $BriefPath))
if (-not [System.IO.File]::Exists($briefFile)) {
    throw "Pixel asset brief does not exist: $briefFile"
}

$brief = Get-Content -LiteralPath $briefFile -Raw | ConvertFrom-Json
$palette = Get-Content -LiteralPath (
    Join-Path $repoRoot "art/pixel/palettes/pixel-hangar-v1.json"
) -Raw | ConvertFrom-Json
$referenceManifest = Get-Content -LiteralPath (
    Join-Path $repoRoot (
        "docs/design/pixel-space-hangar-visual-research/reference-manifest.json"
    )
) -Raw | ConvertFrom-Json

$errors = [System.Collections.Generic.List[string]]::new()
$idPattern = "^[a-z0-9_]+$"
$allowedStatuses = @("proof", "candidate", "approved", "rejected")
$allowedMethods = @("imagegen_assisted", "direct_pixel", "derived_view")
$allowedDensity = @("calm", "ordinary", "hard_peak", "all")
$allowedDirections = @(0, 1, 2, 4, 8, 16)
$paletteRoles = @{}
$referenceIds = @{}

foreach ($property in @($palette.colors.PSObject.Properties)) {
    $paletteRoles[$property.Name] = $true
}
foreach ($reference in @($referenceManifest.game_references)) {
    $referenceIds[[string]$reference.id] = $true
}
foreach ($reference in @($referenceManifest.free_asset_references)) {
    $referenceIds[[string]$reference.id] = $true
}

if ([int]$brief.schema_version -ne 1) {
    $errors.Add("schema_version must be 1")
}
if ([string]$brief.id -notmatch $idPattern) {
    $errors.Add("invalid brief id: $($brief.id)")
}
if ([string]$brief.family -notmatch $idPattern) {
    $errors.Add("invalid family id: $($brief.family)")
}
if ([string]$brief.approval_status -notin $allowedStatuses) {
    $errors.Add("unknown approval_status: $($brief.approval_status)")
}
if ([string]$brief.production_method -notin $allowedMethods) {
    $errors.Add("unknown production_method: $($brief.production_method)")
}
if ([string]$brief.density_tier -notin $allowedDensity) {
    $errors.Add("unknown density_tier: $($brief.density_tier)")
}
if ([int]$brief.directions -notin $allowedDirections) {
    $errors.Add("directions must be one of: $($allowedDirections -join ', ')")
}

$nativeSize = @($brief.native_size)
if (
    $nativeSize.Count -ne 2 -or
    [int]$nativeSize[0] -le 0 -or
    [int]$nativeSize[0] -ne [int]$nativeSize[1]
) {
    $errors.Add("native_size must be a positive square size")
}
$width = if ($nativeSize.Count -eq 2) { [int]$nativeSize[0] } else { 0 }
$pivot = @($brief.pivot)
if (
    $pivot.Count -ne 2 -or
    [int]$pivot[0] -lt 0 -or
    [int]$pivot[0] -ge $width -or
    [int]$pivot[1] -lt 0 -or
    [int]$pivot[1] -ge $width
) {
    $errors.Add("pivot must be inside native_size")
}
foreach ($anchorProperty in @($brief.anchors.PSObject.Properties)) {
    $anchor = @($anchorProperty.Value)
    if (
        $anchor.Count -ne 2 -or
        [int]$anchor[0] -lt 0 -or
        [int]$anchor[0] -ge $width -or
        [int]$anchor[1] -lt 0 -or
        [int]$anchor[1] -ge $width
    ) {
        $errors.Add("anchor $($anchorProperty.Name) must be inside native_size")
    }
}

foreach ($field in @(
    "gameplay_identity",
    "silhouette_requirement",
    "orientation_cue",
    "collision_reference",
    "runtime_group"
)) {
    if ([string]::IsNullOrWhiteSpace([string]$brief.$field)) {
        $errors.Add("$field must not be empty")
    }
}
if ([double]$brief.rendered_diameter -le 0) {
    $errors.Add("rendered_diameter must be positive")
}

foreach ($field in @(
    "current_owner",
    "semantic_parts",
    "states",
    "allowed_palette_roles",
    "references",
    "avoid_rules",
    "review_backgrounds"
)) {
    if (@($brief.$field).Count -eq 0) {
        $errors.Add("$field must contain at least one entry")
    }
}
foreach ($field in @(
    "current_owner",
    "semantic_parts",
    "states",
    "allowed_palette_roles",
    "avoid_rules",
    "review_backgrounds"
)) {
    $values = @($brief.$field | ForEach-Object { [string]$_ })
    if (@($values | Sort-Object -Unique).Count -ne $values.Count) {
        $errors.Add("$field must not contain duplicates")
    }
}
foreach ($field in @("semantic_parts", "states", "allowed_palette_roles", "review_backgrounds")) {
    foreach ($value in @($brief.$field)) {
        if ([string]$value -notmatch $idPattern) {
            $errors.Add("$field contains an invalid id: $value")
        }
    }
}
if (@($brief.references).Count -gt 3) {
    $errors.Add("references may contain at most three entries")
}
$briefReferenceIds = @($brief.references | ForEach-Object { [string]$_.id })
if (@($briefReferenceIds | Sort-Object -Unique).Count -ne $briefReferenceIds.Count) {
    $errors.Add("references must not contain duplicate ids")
}
foreach ($owner in @($brief.current_owner)) {
    $ownerPath = [System.IO.Path]::GetFullPath((Join-Path $repoRoot ([string]$owner)))
    if (
        -not [System.IO.File]::Exists($ownerPath) -and
        -not [System.IO.Directory]::Exists($ownerPath)
    ) {
        $errors.Add("missing current_owner: $owner")
    }
}
foreach ($role in @($brief.allowed_palette_roles) + @($brief.review_backgrounds)) {
    if (-not $paletteRoles.ContainsKey([string]$role)) {
        $errors.Add("unknown palette role: $role")
    }
}
foreach ($reference in @($brief.references)) {
    if ([string]$reference.id -notmatch $idPattern) {
        $errors.Add("invalid reference id: $($reference.id)")
    } elseif (-not $referenceIds.ContainsKey([string]$reference.id)) {
        $errors.Add("unknown reference id: $($reference.id)")
    }
    if ([string]::IsNullOrWhiteSpace([string]$reference.study)) {
        $errors.Add("reference $($reference.id) has no study purpose")
    }
}

if ($errors.Count -gt 0) {
    $details = ($errors | ForEach-Object { "- $_" }) -join [Environment]::NewLine
    throw "Pixel asset brief validation failed with $($errors.Count) error(s).$([Environment]::NewLine)$details"
}

Write-Output "Pixel asset brief valid: $($brief.id)"
Write-Output "Family: $($brief.family); method=$($brief.production_method); status=$($brief.approval_status)"
