param(
    [Parameter(Mandatory = $true)]
    [string]$ManifestPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory
)

$ErrorActionPreference = "Stop"

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$manifestFile = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $ManifestPath))
$destination = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutputDirectory))

& (Join-Path $PSScriptRoot "validate_pixel_asset_manifest.ps1") -ManifestPath $ManifestPath -RequireInputFiles

$manifest = Get-Content -LiteralPath $manifestFile -Raw | ConvertFrom-Json
$canvasSize = [int]$manifest.canvas_size
$logicalSize = @($manifest.logical_size)
$cells = [int]$logicalSize[0]
if ($cells -ne [int]$logicalSize[1]) {
    throw "invoke_pixel_asset_build.ps1 currently accepts square per-frame logical grids only."
}
if (-not [System.IO.Directory]::Exists($destination)) {
    [System.IO.Directory]::CreateDirectory($destination) | Out-Null
}

foreach ($frame in @($manifest.frames | Sort-Object {[int]$_.atlas_index})) {
    $frameDirectory = Join-Path $destination ([string]$frame.id)
    if (-not [System.IO.Directory]::Exists($frameDirectory)) {
        [System.IO.Directory]::CreateDirectory($frameDirectory) | Out-Null
    }
    $snappedSource = Join-Path $frameDirectory "source.png"
    $snappedSemanticMask = Join-Path $frameDirectory "semantic-mask.png"

    & (Join-Path $PSScriptRoot "snap_image_to_pixel_grid.ps1") `
        -InputPath ([string]$frame.source_path) `
        -PalettePath ([string]$manifest.palette_path) `
        -OutputPath $snappedSource `
        -CanvasSize $canvasSize `
        -Cells $cells `
        -TransparentColor ([string]$manifest.transparent_color)

    & (Join-Path $PSScriptRoot "snap_image_to_pixel_grid.ps1") `
        -InputPath ([string]$frame.semantic_mask_path) `
        -PalettePath ([string]$manifest.semantic_palette_path) `
        -OutputPath $snappedSemanticMask `
        -CanvasSize $canvasSize `
        -Cells $cells `
        -TransparentColor ([string]$manifest.transparent_color)

    $sourceRelative = [System.IO.Path]::GetRelativePath($repoRoot, $snappedSource).Replace("\", "/")
    $maskRelative = [System.IO.Path]::GetRelativePath($repoRoot, $snappedSemanticMask).Replace("\", "/")
    $frameRelative = [System.IO.Path]::GetRelativePath($repoRoot, $frameDirectory).Replace("\", "/")
    & (Join-Path $PSScriptRoot "split_pixel_asset_layers.ps1") `
        -SourcePath $sourceRelative `
        -SemanticMaskPath $maskRelative `
        -ManifestPath $ManifestPath `
        -OutputDirectory $frameRelative

    foreach ($layer in @($manifest.layers)) {
        $layerPath = Join-Path $frameDirectory "layers/$($layer.id).png"
        $svgPath = Join-Path $frameDirectory "layers/$($layer.id).svg"
        & (Join-Path $PSScriptRoot "raster_to_pixel_svg.ps1") `
            -InputPath $layerPath `
            -OutputPath $svgPath
    }
}

$framesRelative = [System.IO.Path]::GetRelativePath($repoRoot, $destination).Replace("\", "/")
$atlasRelative = [System.IO.Path]::GetRelativePath($repoRoot, (Join-Path $destination "atlas.png")).Replace("\", "/")
& (Join-Path $PSScriptRoot "pack_pixel_asset_atlas.ps1") `
    -ManifestPath $ManifestPath `
    -FramesDirectory $framesRelative `
    -OutputPath $atlasRelative

Write-Output "Pixel asset build complete: $destination"
