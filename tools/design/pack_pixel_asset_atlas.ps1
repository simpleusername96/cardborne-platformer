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
$logicalSize = @($manifest.logical_size)
$frameWidth = [int]$logicalSize[0]
$frameHeight = [int]$logicalSize[1]
$columns = [int]$manifest.atlas.columns
$padding = [int]$manifest.atlas.padding
$orderedFrames = @($manifest.frames | Sort-Object {[int]$_.atlas_index})
$rows = [int][Math]::Ceiling($orderedFrames.Count / [double]$columns)
$atlasWidth = $columns * $frameWidth + [Math]::Max(0, $columns - 1) * $padding
$atlasHeight = $rows * $frameHeight + [Math]::Max(0, $rows - 1) * $padding

$destinationDirectory = [System.IO.Path]::GetDirectoryName($destination)
if (-not [System.IO.Directory]::Exists($destinationDirectory)) {
    [System.IO.Directory]::CreateDirectory($destinationDirectory) | Out-Null
}

$arguments = @("-size", "${atlasWidth}x${atlasHeight}", "xc:none")
$metadataFrames = [System.Collections.Generic.List[object]]::new()
foreach ($frame in $orderedFrames) {
    $index = [int]$frame.atlas_index
    $column = $index % $columns
    $row = [int][Math]::Floor($index / [double]$columns)
    $x = $column * ($frameWidth + $padding)
    $y = $row * ($frameHeight + $padding)
    $framePath = Join-Path $framesRoot "$($frame.id)/reassembled.png"
    if (-not [System.IO.File]::Exists($framePath)) {
        throw "Approved frame does not exist: $framePath"
    }
    $size = (& $magick.Source identify -format "%w %h" $framePath).Trim()
    if ($size -ne "$frameWidth $frameHeight") {
        throw "Frame $($frame.id) must be ${frameWidth}x${frameHeight}; got $size"
    }
    $arguments += @($framePath, "-geometry", "+$x+$y", "-compose", "over", "-composite")
    $metadataFrames.Add([ordered]@{
        id = [string]$frame.id
        atlas_index = $index
        region = @($x, $y, $frameWidth, $frameHeight)
        pivot = @($manifest.pivot)
        anchors = $manifest.anchors
        direction = $frame.direction
        state = $frame.state
    })
}
$arguments += @("-depth", "8", "-strip", $destination)
& $magick.Source @arguments
if ($LASTEXITCODE -ne 0) {
    throw "ImageMagick failed to pack the pixel asset atlas."
}

$metadata = [ordered]@{
    schema_version = 1
    asset_id = [string]$manifest.id
    atlas_path = $OutputPath.Replace("\", "/")
    atlas_size = @($atlasWidth, $atlasHeight)
    frame_size = @($frameWidth, $frameHeight)
    columns = $columns
    rows = $rows
    padding = $padding
    frames = @($metadataFrames)
}
$metadataPath = [System.IO.Path]::ChangeExtension($destination, ".json")
[System.IO.File]::WriteAllText(
    $metadataPath,
    ($metadata | ConvertTo-Json -Depth 8),
    [System.Text.UTF8Encoding]::new($false)
)

Write-Output "Packed pixel atlas: $destination"
Write-Output "Atlas size: ${atlasWidth}x${atlasHeight}; frames=$($orderedFrames.Count)"
