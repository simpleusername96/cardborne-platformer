param()

$ErrorActionPreference = "Stop"

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../../../.."))
$samplerRoot = [System.IO.Path]::GetFullPath($PSScriptRoot)
$magick = Get-Command magick -ErrorAction Stop
$designTools = Join-Path $repoRoot "tools/design"

function Resolve-SamplerPath {
    param([string]$RelativePath)
    return [System.IO.Path]::GetFullPath((Join-Path $samplerRoot $RelativePath))
}

function Ensure-Directory {
    param([string]$Path)
    if (-not [System.IO.Directory]::Exists($Path)) {
        [System.IO.Directory]::CreateDirectory($Path) | Out-Null
    }
}

function Remove-SamplerDirectory {
    param([string]$RelativePath)

    $path = Resolve-SamplerPath $RelativePath
    $samplerPrefix = $samplerRoot.TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    ) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $path.StartsWith($samplerPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove a directory outside the sampler: $path"
    }
    if ([System.IO.Directory]::Exists($path)) {
        Remove-Item -LiteralPath $path -Recurse -Force
    }
}

function Invoke-Magick {
    param([string[]]$Arguments)
    & $magick.Source @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "ImageMagick failed: $($Arguments -join ' ')"
    }
}

function New-SemanticMask {
    param(
        [string]$SourcePath,
        [string]$OutputPath,
        [int]$Size,
        [array]$Regions
    )

    $arguments = @("-size", "${Size}x${Size}", "xc:#FF0000")
    foreach ($region in $Regions) {
        $arguments += @("-fill", [string]$region.color, "-draw", [string]$region.draw)
    }
    $arguments += @(
        "(",
        $SourcePath,
        "-alpha", "extract",
        ")",
        "-compose", "CopyOpacity",
        "-composite",
        "-depth", "8",
        "-strip",
        $OutputPath
    )
    Invoke-Magick -Arguments $arguments
}

function Build-SemanticLayers {
    param(
        [string]$Id,
        [string]$SourcePath
    )

    $manifestPath = ".agents/evidence/pixel-art/pipeline-sampler/manifests/$Id.manifest.json"
    $maskPath = Resolve-SamplerPath "masks/$Id.png"
    $buildPath = Resolve-SamplerPath "build/$Id"
    & (Join-Path $designTools "split_pixel_asset_layers.ps1") `
        -SourcePath $SourcePath `
        -SemanticMaskPath $maskPath `
        -ManifestPath $manifestPath `
        -OutputDirectory $buildPath

    $manifest = Get-Content -Raw (Join-Path $repoRoot $manifestPath) | ConvertFrom-Json
    foreach ($layer in @($manifest.layers)) {
        & (Join-Path $designTools "raster_to_pixel_svg.ps1") `
            -InputPath (Join-Path $buildPath "layers/$($layer.id).png") `
            -OutputPath (Join-Path $buildPath "layers/$($layer.id).svg")
    }
}

function New-BoardPreview {
    param(
        [string]$SourcePath,
        [string]$OutputPath,
        [int]$Scale
    )

    Invoke-Magick -Arguments @(
        "-size", "512x512", "xc:#44515E",
        "(",
        $SourcePath,
        "-filter", "point",
        "-resize", "$($Scale * 100)%",
        ")",
        "-gravity", "center",
        "-compose", "over",
        "-composite",
        "-depth", "8",
        "-strip",
        $OutputPath
    )
}

function New-ReviewStrip {
    param(
        [string]$Id,
        [string]$SourcePath
    )

    $reviewParts = Resolve-SamplerPath "review/parts"
    Ensure-Directory -Path $reviewParts
    $maskPath = Resolve-SamplerPath "masks/$Id.png"
    $reassembledPath = Resolve-SamplerPath "build/$Id/reassembled.png"
    $nativePreview = Join-Path $reviewParts "$Id-native.png"
    $semanticPreview = Join-Path $reviewParts "$Id-semantic.png"
    $reassembledPreview = Join-Path $reviewParts "$Id-reassembled.png"
    $silhouettePreview = Join-Path $reviewParts "$Id-silhouette.png"
    $grayscalePreview = Join-Path $reviewParts "$Id-grayscale.png"

    Invoke-Magick -Arguments @(
        "-size", "224x224", "xc:#44515E",
        $SourcePath, "-filter", "point", "-resize", "192x192",
        "-gravity", "center", "-compose", "over", "-composite",
        $nativePreview
    )
    Invoke-Magick -Arguments @(
        "-size", "224x224", "xc:#141B24",
        $maskPath, "-filter", "point", "-resize", "192x192",
        "-gravity", "center", "-compose", "over", "-composite",
        $semanticPreview
    )
    Invoke-Magick -Arguments @(
        "-size", "224x224", "xc:#44515E",
        $reassembledPath, "-filter", "point", "-resize", "192x192",
        "-gravity", "center", "-compose", "over", "-composite",
        $reassembledPreview
    )
    Invoke-Magick -Arguments @(
        $SourcePath,
        "-channel", "A", "-threshold", "0",
        "+channel", "-fill", "#E8EEF0", "-colorize", "100",
        "-filter", "point", "-resize", "192x192",
        "-background", "#141B24", "-gravity", "center", "-extent", "224x224",
        $silhouettePreview
    )
    Invoke-Magick -Arguments @(
        "-size", "224x224", "xc:#141B24",
        $SourcePath, "-colorspace", "Gray", "-filter", "point", "-resize", "192x192",
        "-gravity", "center", "-compose", "over", "-composite",
        $grayscalePreview
    )
    Invoke-Magick -Arguments @(
        "montage",
        $nativePreview,
        $semanticPreview,
        $reassembledPreview,
        $silhouettePreview,
        $grayscalePreview,
        "-tile", "5x1",
        "-geometry", "224x224+8+8",
        "-background", "#141B24",
        (Resolve-SamplerPath "review/$Id-pipeline-review.png")
    )
}

$requiredDirectories = @(
    "native",
    "masks",
    "build",
    "final",
    "review",
    "review/parts",
    "palette"
)
foreach ($directory in $requiredDirectories) {
    Ensure-Directory -Path (Resolve-SamplerPath $directory)
}

$displayPaletteSpec = ".agents/evidence/pixel-art/pipeline-sampler/palette/pixel-hangar-v1-sampler.json"
$displayPalette = ".agents/evidence/pixel-art/pipeline-sampler/palette/pixel-hangar-v1-sampler.png"
$semanticPaletteSpec = ".agents/evidence/pixel-art/pipeline-sampler/palette/semantic-mask-v1-sampler.json"
$semanticPalette = ".agents/evidence/pixel-art/pipeline-sampler/palette/semantic-mask-v1-sampler.png"

& (Join-Path $designTools "create_pixel_palette.ps1") `
    -PaletteSpecPath $displayPaletteSpec `
    -ColorGroup colors `
    -OutputPath $displayPalette
& (Join-Path $designTools "create_pixel_palette.ps1") `
    -PaletteSpecPath $semanticPaletteSpec `
    -ColorGroup colors `
    -OutputPath $semanticPalette

$generatedAssets = @(
    @{id = "player-interceptor"; cells = 64; canvas = 512},
    @{id = "shooter-drone"; cells = 32; canvas = 512},
    @{id = "thermal-heavy-shot"; cells = 32; canvas = 512},
    @{id = "repair-fixture"; cells = 64; canvas = 512}
)
foreach ($asset in $generatedAssets) {
    $rawPath = ".agents/evidence/pixel-art/pipeline-sampler/raw/$($asset.id).png"
    $nativePath = ".agents/evidence/pixel-art/pipeline-sampler/native/$($asset.id).png"
    & (Join-Path $designTools "snap_image_to_pixel_grid.ps1") `
        -InputPath $rawPath `
        -PalettePath $displayPalette `
        -OutputPath $nativePath `
        -CanvasSize ([int]$asset.canvas) `
        -Cells ([int]$asset.cells) `
        -TransparentColor "#FFFFFF"
    $resolvedNativePath = Join-Path $repoRoot $nativePath
    Invoke-Magick -Arguments @(
        $resolvedNativePath,
        "-background", "black",
        "-alpha", "background",
        "-depth", "8",
        "-strip",
        $resolvedNativePath
    )
}

# Repair the one-cell gap in the generated thermal wake at native resolution.
Invoke-Magick -Arguments @(
    (Resolve-SamplerPath "native/thermal-heavy-shot.png"),
    "-fill", "#E45F36",
    "-draw", "rectangle 6,15 14,16",
    "-depth", "8",
    "-strip",
    (Resolve-SamplerPath "native/thermal-heavy-shot.png")
)

# Topology-critical world and pickup assets are authored directly on the native
# logical grid rather than generated as soft raster drafts.
Invoke-Magick -Arguments @(
    "-size", "24x24", "xc:none",
    "+antialias",
    "-fill", "#596774", "-draw", "rectangle 0,0 23,7 rectangle 16,0 23,23",
    "-fill", "#222B35", "-draw", "rectangle 0,8 15,11 rectangle 12,8 15,23",
    "-fill", "#E8EEF0", "-draw", "rectangle 0,0 23,0 rectangle 22,1 23,23",
    "-depth", "8", "-strip",
    (Resolve-SamplerPath "native/wall-corner-tile.png")
)
Invoke-Magick -Arguments @(
    "-size", "24x24", "xc:none",
    "+antialias",
    "-fill", "#202833", "-draw",
    "rectangle 7,5 16,18 rectangle 5,7 18,16",
    "-fill", "#596774", "-draw",
    "rectangle 7,6 16,17 rectangle 6,7 17,16",
    "-fill", "#75C4B2", "-draw",
    "rectangle 10,7 13,16 rectangle 7,10 16,13",
    "-fill", "#E8EEF0", "-draw",
    "rectangle 9,6 14,6 rectangle 6,9 6,14",
    "-depth", "8", "-strip",
    (Resolve-SamplerPath "native/repair-pickup.png")
)

New-SemanticMask `
    -SourcePath (Resolve-SamplerPath "native/player-interceptor.png") `
    -OutputPath (Resolve-SamplerPath "masks/player-interceptor.png") `
    -Size 64 `
    -Regions @(
        @{color = "#00FF00"; draw = "rectangle 0,18 25,49"},
        @{color = "#0000FF"; draw = "rectangle 39,18 63,49"},
        @{color = "#FFFF00"; draw = "rectangle 25,22 38,39"},
        @{color = "#FF00FF"; draw = "rectangle 29,7 35,21"},
        @{color = "#00FFFF"; draw = "rectangle 21,49 43,63"}
    )
New-SemanticMask `
    -SourcePath (Resolve-SamplerPath "native/shooter-drone.png") `
    -OutputPath (Resolve-SamplerPath "masks/shooter-drone.png") `
    -Size 32 `
    -Regions @(
        @{color = "#00FFFF"; draw = "rectangle 0,0 10,31"},
        @{color = "#FF00FF"; draw = "rectangle 21,0 31,31"},
        @{color = "#FFFF00"; draw = "rectangle 11,9 20,22"}
    )
New-SemanticMask `
    -SourcePath (Resolve-SamplerPath "native/thermal-heavy-shot.png") `
    -OutputPath (Resolve-SamplerPath "masks/thermal-heavy-shot.png") `
    -Size 32 `
    -Regions @(
        @{color = "#FF8000"; draw = "rectangle 0,0 14,31"},
        @{color = "#FF00FF"; draw = "rectangle 24,0 31,31"},
        @{color = "#FFFF00"; draw = "rectangle 17,12 23,20"}
    )
New-SemanticMask `
    -SourcePath (Resolve-SamplerPath "native/repair-fixture.png") `
    -OutputPath (Resolve-SamplerPath "masks/repair-fixture.png") `
    -Size 64 `
    -Regions @(
        @{color = "#FF8000"; draw = "rectangle 19,17 45,47"},
        @{color = "#FFFF00"; draw = "rectangle 25,23 39,42"}
    )
New-SemanticMask `
    -SourcePath (Resolve-SamplerPath "native/wall-corner-tile.png") `
    -OutputPath (Resolve-SamplerPath "masks/wall-corner-tile.png") `
    -Size 24 `
    -Regions @(
        @{color = "#FF8000"; draw = "rectangle 0,8 15,11 rectangle 12,8 15,23"},
        @{color = "#FFFF00"; draw = "rectangle 0,0 23,0 rectangle 22,1 23,23"}
    )
New-SemanticMask `
    -SourcePath (Resolve-SamplerPath "native/repair-pickup.png") `
    -OutputPath (Resolve-SamplerPath "masks/repair-pickup.png") `
    -Size 24 `
    -Regions @(
        @{color = "#FFFF00"; draw = "rectangle 10,7 13,16 rectangle 7,10 16,13"},
        @{color = "#FF8000"; draw = "rectangle 9,6 14,6 rectangle 6,9 6,14"}
    )

$assetIds = @(
    "player-interceptor",
    "shooter-drone",
    "thermal-heavy-shot",
    "repair-fixture",
    "wall-corner-tile",
    "repair-pickup"
)
foreach ($assetId in $assetIds) {
    $sourcePath = Resolve-SamplerPath "native/$assetId.png"
    Build-SemanticLayers -Id $assetId -SourcePath $sourcePath
    New-ReviewStrip -Id $assetId -SourcePath $sourcePath
}

New-BoardPreview `
    -SourcePath (Resolve-SamplerPath "native/player-interceptor.png") `
    -OutputPath (Resolve-SamplerPath "final/player-interceptor.png") `
    -Scale 7
New-BoardPreview `
    -SourcePath (Resolve-SamplerPath "native/shooter-drone.png") `
    -OutputPath (Resolve-SamplerPath "final/shooter-drone.png") `
    -Scale 14
New-BoardPreview `
    -SourcePath (Resolve-SamplerPath "native/thermal-heavy-shot.png") `
    -OutputPath (Resolve-SamplerPath "final/thermal-heavy-shot.png") `
    -Scale 14
New-BoardPreview `
    -SourcePath (Resolve-SamplerPath "native/repair-fixture.png") `
    -OutputPath (Resolve-SamplerPath "final/repair-fixture.png") `
    -Scale 7
New-BoardPreview `
    -SourcePath (Resolve-SamplerPath "native/repair-pickup.png") `
    -OutputPath (Resolve-SamplerPath "final/repair-pickup.png") `
    -Scale 16

$tilePath = Resolve-SamplerPath "native/wall-corner-tile.png"
$tileSeam = Resolve-SamplerPath "review/wall-corner-tile-3x3.png"
Invoke-Magick -Arguments @(
    "montage",
    $tilePath, $tilePath, $tilePath,
    $tilePath, $tilePath, $tilePath,
    $tilePath, $tilePath, $tilePath,
    "-tile", "3x3",
    "-geometry", "24x24+0+0",
    "-background", "#44515E",
    $tileSeam
)
New-BoardPreview `
    -SourcePath $tileSeam `
    -OutputPath (Resolve-SamplerPath "final/wall-corner-tile.png") `
    -Scale 7

Invoke-Magick -Arguments @(
    "montage",
    (Resolve-SamplerPath "final/player-interceptor.png"),
    (Resolve-SamplerPath "final/shooter-drone.png"),
    (Resolve-SamplerPath "final/thermal-heavy-shot.png"),
    (Resolve-SamplerPath "final/repair-fixture.png"),
    (Resolve-SamplerPath "final/wall-corner-tile.png"),
    (Resolve-SamplerPath "final/repair-pickup.png"),
    "-tile", "3x2",
    "-geometry", "512x512+12+12",
    "-background", "#141B24",
    (Resolve-SamplerPath "review/pipeline-sampler-overview.png")
)

# Review-strip parts are deterministic build intermediates. Keep only the
# composed evidence so the sampler does not become a second asset library.
Remove-SamplerDirectory -RelativePath "review/parts"

Write-Output "Pipeline sampler complete: $samplerRoot"
