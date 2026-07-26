param(
    [Parameter(Mandatory = $true)]
    [string]$ManifestPath,

    [Parameter(Mandatory = $true)]
    [string]$FramesDirectory,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
& (Join-Path $PSScriptRoot "validate_pixel_asset_manifest.ps1") -ManifestPath $ManifestPath

$manifestFile = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $ManifestPath))
$framesRoot = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $FramesDirectory))
$destination = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutputPath))
$magick = Get-Command magick -ErrorAction Stop

if (-not [System.IO.File]::Exists($manifestFile)) {
    throw "Pixel asset manifest does not exist: $manifestFile"
}
$manifest = Get-Content -LiteralPath $manifestFile -Raw | ConvertFrom-Json
$schemaVersion = [int]$manifest.schema_version
$logicalSize = @($manifest.logical_size)
$frameWidth = [int]$logicalSize[0]
$frameHeight = [int]$logicalSize[1]
$columns = [int]$manifest.atlas.columns
$padding = [int]$manifest.atlas.padding
$extrude = if ($schemaVersion -eq 2) { [int]$manifest.atlas.extrude } else { 0 }
$cellWidth = $frameWidth + 2 * $extrude
$cellHeight = $frameHeight + 2 * $extrude
$orderedFrames = @($manifest.frames | Sort-Object {[int]$_.atlas_index})
$rows = [int][Math]::Ceiling($orderedFrames.Count / [double]$columns)
$atlasWidth = $columns * $cellWidth + [Math]::Max(0, $columns - 1) * $padding
$atlasHeight = $rows * $cellHeight + [Math]::Max(0, $rows - 1) * $padding

$destinationDirectory = [System.IO.Path]::GetDirectoryName($destination)
if (-not [System.IO.Directory]::Exists($destinationDirectory)) {
    [System.IO.Directory]::CreateDirectory($destinationDirectory) | Out-Null
}

$arguments = @("-size", "${atlasWidth}x${atlasHeight}", "xc:none")
$metadataFrames = [System.Collections.Generic.List[object]]::new()
$temporaryExtruded = [System.Collections.Generic.List[string]]::new()
try {
    foreach ($frame in $orderedFrames) {
    $index = [int]$frame.atlas_index
    $column = $index % $columns
    $row = [int][Math]::Floor($index / [double]$columns)
    $cellX = $column * ($cellWidth + $padding)
    $cellY = $row * ($cellHeight + $padding)
    $x = $cellX + $extrude
    $y = $cellY + $extrude
    $framePath = Join-Path $framesRoot "$($frame.id)/reassembled.png"
    if (-not [System.IO.File]::Exists($framePath)) {
        throw "Approved frame does not exist: $framePath"
    }
    $size = (& $magick.Source identify -format "%w %h" $framePath).Trim()
    if ($size -ne "$frameWidth $frameHeight") {
        throw "Frame $($frame.id) must be ${frameWidth}x${frameHeight}; got $size"
    }
    $packedFramePath = $framePath
    if ($extrude -gt 0) {
        $packedFramePath = Join-Path $destinationDirectory "_atlas-extruded-$PID-$index.png"
        & $magick.Source $framePath `
            -set option:distort:viewport "${cellWidth}x${cellHeight}-$extrude-$extrude" `
            -virtual-pixel edge `
            -filter point `
            -distort SRT 0 `
            -depth 8 `
            -strip `
            $packedFramePath
        if ($LASTEXITCODE -ne 0) {
            throw "ImageMagick failed to extrude frame $($frame.id)."
        }
        $temporaryExtruded.Add($packedFramePath)
    }
    $arguments += @($packedFramePath, "-geometry", "+$cellX+$cellY", "-compose", "over", "-composite")
    $frameMetadata = [ordered]@{
        id = [string]$frame.id
        atlas_index = $index
        region = @($x, $y, $frameWidth, $frameHeight)
        cell_region = @($cellX, $cellY, $cellWidth, $cellHeight)
        pivot = @($manifest.pivot)
        anchors = $manifest.anchors
        direction = if ($schemaVersion -eq 2) { [int]$frame.direction_index } else { $frame.direction }
        state = $frame.state
    }
    if ($schemaVersion -eq 2) {
        $frameMetadata["variant"] = [string]$frame.variant
        $frameMetadata["sequence_index"] = [int]$frame.sequence_index
        $frameMetadata["duration_ms"] = [int]$frame.duration_ms
        $frameMetadata["source_sha256"] = [string]$frame.source_sha256
    }
        $metadataFrames.Add($frameMetadata)
    }
    $arguments += @("-depth", "8", "-strip", $destination)
    & $magick.Source @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "ImageMagick failed to pack the pixel asset atlas."
    }
} finally {
    foreach ($temporaryPath in $temporaryExtruded) {
        if ([System.IO.File]::Exists($temporaryPath)) {
            Remove-Item -LiteralPath $temporaryPath
        }
    }
}

$metadata = [ordered]@{
    schema_version = $schemaVersion
    asset_id = [string]$manifest.id
    family = [string]$manifest.family
    atlas_path = $OutputPath.Replace("\", "/")
    atlas_size = @($atlasWidth, $atlasHeight)
    frame_size = @($frameWidth, $frameHeight)
    cell_size = @($cellWidth, $cellHeight)
    columns = $columns
    rows = $rows
    padding = $padding
    extrude = $extrude
    frames = @($metadataFrames)
}
if ($schemaVersion -eq 2) {
    $metadata["runtime_group"] = [string]$manifest.runtime_group
    $metadata["runtime_layers"] = @($manifest.runtime_layers)
    $metadata["approval_status"] = [string]$manifest.approval_status
}
$metadataPath = [System.IO.Path]::ChangeExtension($destination, ".json")
[System.IO.File]::WriteAllText(
    $metadataPath,
    ($metadata | ConvertTo-Json -Depth 8),
    [System.Text.UTF8Encoding]::new($false)
)

Write-Output "Packed pixel atlas: $destination"
Write-Output "Atlas size: ${atlasWidth}x${atlasHeight}; frames=$($orderedFrames.Count)"
