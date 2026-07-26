param(
    [Parameter(Mandatory = $true)]
    [string]$ManifestPath,

    [switch]$RequireInputFiles
)

$ErrorActionPreference = "Stop"

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$manifestFile = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $ManifestPath))
if (-not [System.IO.File]::Exists($manifestFile)) {
    throw "Pixel asset manifest does not exist: $manifestFile"
}

$manifest = Get-Content -LiteralPath $manifestFile -Raw | ConvertFrom-Json
$errors = [System.Collections.Generic.List[string]]::new()
$idPattern = "^[a-z0-9_]+$"
$colorPattern = "^#[0-9A-Fa-f]{6}$"

if ([int]$manifest.schema_version -ne 1) {
    $errors.Add("schema_version must be 1")
}
if ([string]$manifest.id -notmatch $idPattern) {
    $errors.Add("invalid manifest id: $($manifest.id)")
}
if ([string]$manifest.family -notmatch $idPattern) {
    $errors.Add("invalid manifest family: $($manifest.family)")
}
if ([int]$manifest.canvas_size -lt 64 -or [int]$manifest.canvas_size -gt 2048) {
    $errors.Add("canvas_size must be between 64 and 2048")
}
if ([string]$manifest.transparent_color -notmatch $colorPattern) {
    $errors.Add("transparent_color must be a six-digit hex color")
}

$logicalSize = @($manifest.logical_size)
if ($logicalSize.Count -ne 2) {
    $errors.Add("logical_size must contain width and height")
} else {
    $logicalWidth = [int]$logicalSize[0]
    $logicalHeight = [int]$logicalSize[1]
    if ($logicalWidth -le 0 -or $logicalHeight -le 0) {
        $errors.Add("logical_size values must be positive")
    }
    if ($logicalWidth -ne $logicalHeight) {
        $errors.Add("per-frame logical_size must be square; pack rectangular atlases after frame approval")
    }
    if ($logicalWidth -gt 0 -and [int]$manifest.canvas_size % $logicalWidth -ne 0) {
        $errors.Add("canvas_size must divide evenly by logical_size")
    }
}

$layerIds = @{}
$layerColors = @{}
$layerZ = @{}
foreach ($layer in @($manifest.layers)) {
    $layerId = [string]$layer.id
    $maskColor = ([string]$layer.mask_color).ToUpperInvariant()
    if ($layerId -notmatch $idPattern) {
        $errors.Add("invalid layer id: $layerId")
    }
    if ($layerIds.ContainsKey($layerId)) {
        $errors.Add("duplicate layer id: $layerId")
    }
    if ($maskColor -notmatch $colorPattern) {
        $errors.Add("$layerId has invalid mask_color: $maskColor")
    }
    if ($layerColors.ContainsKey($maskColor)) {
        $errors.Add("duplicate layer mask_color: $maskColor")
    }
    if ($layerZ.ContainsKey([int]$layer.z)) {
        $errors.Add("duplicate layer z: $($layer.z)")
    }
    $layerIds[$layerId] = $true
    $layerColors[$maskColor] = $true
    $layerZ[[int]$layer.z] = $true
}
if ($layerIds.Count -eq 0) {
    $errors.Add("manifest must contain at least one semantic layer")
}

if ($logicalSize.Count -eq 2) {
    $logicalWidth = [int]$logicalSize[0]
    $logicalHeight = [int]$logicalSize[1]
    $pivot = @($manifest.pivot)
    if ($pivot.Count -ne 2 -or [int]$pivot[0] -lt 0 -or [int]$pivot[0] -ge $logicalWidth -or [int]$pivot[1] -lt 0 -or [int]$pivot[1] -ge $logicalHeight) {
        $errors.Add("pivot must be inside logical_size")
    }
    foreach ($anchorProperty in @($manifest.anchors.PSObject.Properties)) {
        $anchor = @($anchorProperty.Value)
        if ($anchor.Count -ne 2 -or [int]$anchor[0] -lt 0 -or [int]$anchor[0] -ge $logicalWidth -or [int]$anchor[1] -lt 0 -or [int]$anchor[1] -ge $logicalHeight) {
            $errors.Add("anchor $($anchorProperty.Name) must be inside logical_size")
        }
    }
}

$frameIds = @{}
$atlasIndices = @{}
foreach ($frame in @($manifest.frames)) {
    $frameId = [string]$frame.id
    $atlasIndex = [int]$frame.atlas_index
    if ($frameId -notmatch $idPattern) {
        $errors.Add("invalid frame id: $frameId")
    }
    if ($frameIds.ContainsKey($frameId)) {
        $errors.Add("duplicate frame id: $frameId")
    }
    if ($atlasIndices.ContainsKey($atlasIndex)) {
        $errors.Add("duplicate atlas_index: $atlasIndex")
    }
    $frameIds[$frameId] = $true
    $atlasIndices[$atlasIndex] = $true
}
if ($frameIds.Count -eq 0) {
    $errors.Add("manifest must contain at least one frame")
}
for ($index = 0; $index -lt $frameIds.Count; $index++) {
    if (-not $atlasIndices.ContainsKey($index)) {
        $errors.Add("atlas_index values must be contiguous from zero; missing $index")
    }
}

if ([int]$manifest.atlas.columns -le 0) {
    $errors.Add("atlas.columns must be positive")
}
if ([int]$manifest.atlas.padding -lt 0) {
    $errors.Add("atlas.padding must not be negative")
}

$pathsToCheck = @(
    [string]$manifest.palette_path,
    [string]$manifest.semantic_palette_path
)
if ($RequireInputFiles) {
    foreach ($frame in @($manifest.frames)) {
        $pathsToCheck += [string]$frame.source_path
        $pathsToCheck += [string]$frame.semantic_mask_path
    }
}
foreach ($relativePath in $pathsToCheck) {
    if ([string]::IsNullOrWhiteSpace($relativePath)) {
        $errors.Add("manifest input path must not be empty")
        continue
    }
    $resolved = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $relativePath))
    if (-not [System.IO.File]::Exists($resolved)) {
        $errors.Add("missing manifest input: $relativePath")
    }
}

if ($errors.Count -gt 0) {
    $details = ($errors | ForEach-Object { "- $_" }) -join [Environment]::NewLine
    throw "Pixel asset manifest validation failed with $($errors.Count) error(s).$([Environment]::NewLine)$details"
}

Write-Output "Pixel asset manifest valid: $($manifest.id)"
Write-Output "Logical size: $($logicalSize[0])x$($logicalSize[1]); layers=$($layerIds.Count); frames=$($frameIds.Count)"
