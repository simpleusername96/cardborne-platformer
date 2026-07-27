param(
    [Parameter(Mandatory = $true)]
    [string]$CatalogPath,
    [switch]$SkipNativeSourceValidation
)

$ErrorActionPreference = "Stop"

function Read-PixelMap {
    param([string]$Path)

    $result = @{}
    foreach ($line in & $script:Magick.Source $Path -depth 8 "txt:-") {
        if ($line -match "^(?<x>\d+),(?<y>\d+):.*#(?<rgba>[0-9A-Fa-f]{6}(?:[0-9A-Fa-f]{2})?)") {
            $rgba = $Matches.rgba.ToUpperInvariant()
            if ($rgba.Length -eq 6) { $rgba = "${rgba}FF" }
            $result["$($Matches.x),$($Matches.y)"] = $rgba
        }
    }
    return $result
}

$workspaceRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $workspaceRoot ".."))
$catalogFile = if ([System.IO.Path]::IsPathRooted($CatalogPath)) {
    [System.IO.Path]::GetFullPath($CatalogPath)
} else {
    [System.IO.Path]::GetFullPath((Join-Path $repoRoot $CatalogPath))
}
if (-not [System.IO.File]::Exists($catalogFile)) {
    throw "Pixel asset catalog does not exist: $CatalogPath"
}
$catalog = Get-Content -LiteralPath $catalogFile -Raw | ConvertFrom-Json
$errors = [System.Collections.Generic.List[string]]::new()
$assetIds = @{}
$frameKeys = @{}
$countedFrames = 0
$magick = Get-Command magick -ErrorAction Stop
$script:Magick = $magick
$atlasCache = @{}
$occupiedCellsByAtlas = @{}
$atlasWidths = @{}
$validatedBleedAtlases = @{}
Add-Type -AssemblyName System.Drawing

if ([int]$catalog.schema_version -ne 1) { $errors.Add("schema_version must be 1") }
foreach ($asset in @($catalog.assets)) {
    $atlasKey = [string]$asset.atlas_path
    if (-not $occupiedCellsByAtlas.ContainsKey($atlasKey)) {
        $atlasWidth = [int]$asset.atlas_size[0]
        $atlasHeight = [int]$asset.atlas_size[1]
        $occupiedCellsByAtlas[$atlasKey] = [bool[]]::new($atlasWidth * $atlasHeight)
        $atlasWidths[$atlasKey] = $atlasWidth
    }
    $atlasCells = $occupiedCellsByAtlas[$atlasKey]
    $atlasWidth = [int]$atlasWidths[$atlasKey]
    foreach ($frame in @($asset.frames)) {
        $cell = @($frame.cell_region)
        if ($cell.Count -ne 4) { continue }
        for ($cellY = [int]$cell[1]; $cellY -lt [int]$cell[1] + [int]$cell[3]; $cellY++) {
            for ($cellX = [int]$cell[0]; $cellX -lt [int]$cell[0] + [int]$cell[2]; $cellX++) {
                $atlasCells[$cellY * $atlasWidth + $cellX] = $true
            }
        }
    }
}
foreach ($asset in @($catalog.assets)) {
    $assetId = [string]$asset.id
    if ($assetIds.ContainsKey($assetId)) { $errors.Add("duplicate asset id: $assetId") }
    $assetIds[$assetId] = $true
    $atlasPath = if ([System.IO.Path]::IsPathRooted([string]$asset.atlas_path)) {
        [System.IO.Path]::GetFullPath([string]$asset.atlas_path)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot ([string]$asset.atlas_path)))
    }
    if (-not [System.IO.File]::Exists($atlasPath)) {
        $errors.Add("missing atlas: $($asset.atlas_path)")
        continue
    }
    if (-not $atlasCache.ContainsKey($atlasPath)) {
        $atlasCache[$atlasPath] = @{
            hash = (Get-FileHash -LiteralPath $atlasPath -Algorithm SHA256).Hash.ToLowerInvariant()
            size = (& $magick.Source identify -format "%w %h" $atlasPath).Trim()
            bitmap = [System.Drawing.Bitmap]::new($atlasPath)
        }
    }
    $atlasInfo = $atlasCache[$atlasPath]
    $actualHash = [string]$atlasInfo.hash
    if ($actualHash -ne [string]$asset.atlas_sha256) {
        $errors.Add("$assetId atlas checksum mismatch")
    }
    $actualSize = [string]$atlasInfo.size
    if ($actualSize -ne "$($asset.atlas_size[0]) $($asset.atlas_size[1])") {
        $errors.Add("$assetId atlas size mismatch: $actualSize")
    }
    if ([int]$asset.padding -ne 2 -or [int]$asset.extrude -ne 1) {
        $errors.Add("$assetId does not use the production gutter contract")
    }
    $bitmap = $atlasInfo.bitmap
    $occupiedCells = $occupiedCellsByAtlas[[string]$asset.atlas_path]
    $atlasWidth = [int]$atlasWidths[[string]$asset.atlas_path]
    foreach ($frame in @($asset.frames)) {
        $countedFrames++
        $key = [string]$frame.key
        if ($frameKeys.ContainsKey($key)) { $errors.Add("duplicate frame key: $key") }
        $frameKeys[$key] = $true
        if (-not $SkipNativeSourceValidation) {
            $frameDirectory = Join-Path $repoRoot (
                "pixel-art-production/assets/generated/approved/complete/frames/{0}/{1}" -f
                $assetId, [string]$frame.id
            )
            $masterPath = Join-Path $frameDirectory "master.png"
            $manifestPath = Join-Path $frameDirectory "manifest.json"
            if (-not [System.IO.File]::Exists($masterPath)) {
                $errors.Add("$key has no native master")
            } elseif (
                [string]$frame.source_sha256 -ne
                (Get-FileHash -LiteralPath $masterPath -Algorithm SHA256).Hash.ToLowerInvariant()
            ) {
                $errors.Add("$key native master checksum does not match")
            }
            if (-not [System.IO.File]::Exists($manifestPath)) {
                $errors.Add("$key has no semantic manifest")
            } else {
                $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
                if (
                    [string]$manifest.frame_key -ne $key -or
                    [int]$manifest.reassembly_difference_pixels -ne 0 -or
                    (
                        [int]$manifest.visible_pixel_count -gt 0 -and
                        @($manifest.semantic_layers).Count -eq 0
                    )
                ) {
                    $errors.Add("$key semantic manifest is incomplete")
                }
            }
        }
        $region = @($frame.region)
        $cell = @($frame.cell_region)
        if ($region.Count -ne 4 -or $cell.Count -ne 4) {
            $errors.Add("$key has invalid region metadata")
            continue
        }
        if (
            [int]$region[0] -ne [int]$cell[0] + 1 -or
            [int]$region[1] -ne [int]$cell[1] + 1 -or
            [int]$cell[2] -ne [int]$region[2] + 2 -or
            [int]$cell[3] -ne [int]$region[3] + 2
        ) {
            $errors.Add("$key has incorrect extrusion geometry")
        }
        if (
            [int]$cell[0] -lt 0 -or
            [int]$cell[1] -lt 0 -or
            [int]$cell[0] + [int]$cell[2] -gt [int]$asset.atlas_size[0] -or
            [int]$cell[1] + [int]$cell[3] -gt [int]$asset.atlas_size[1]
        ) {
            $errors.Add("$key cell is outside the atlas")
        }
        $x = [int]$region[0]
        $y = [int]$region[1]
        $width = [int]$region[2]
        $height = [int]$region[3]
        for ($offset = 0; $offset -lt $width; $offset++) {
            if (
                $bitmap.GetPixel($x + $offset, $y - 1).ToArgb() -ne
                $bitmap.GetPixel($x + $offset, $y).ToArgb()
            ) {
                $errors.Add("$key top extrusion does not match its source edge")
                break
            }
            if (
                $bitmap.GetPixel($x + $offset, $y + $height).ToArgb() -ne
                $bitmap.GetPixel($x + $offset, $y + $height - 1).ToArgb()
            ) {
                $errors.Add("$key bottom extrusion does not match its source edge")
                break
            }
        }
        for ($offset = 0; $offset -lt $height; $offset++) {
            if (
                $bitmap.GetPixel($x - 1, $y + $offset).ToArgb() -ne
                $bitmap.GetPixel($x, $y + $offset).ToArgb()
            ) {
                $errors.Add("$key left extrusion does not match its source edge")
                break
            }
            if (
                $bitmap.GetPixel($x + $width, $y + $offset).ToArgb() -ne
                $bitmap.GetPixel($x + $width - 1, $y + $offset).ToArgb()
            ) {
                $errors.Add("$key right extrusion does not match its source edge")
                break
            }
        }
        foreach ($corner in @(
            @(($x - 1), ($y - 1), $x, $y),
            @(($x + $width), ($y - 1), ($x + $width - 1), $y),
            @(($x - 1), ($y + $height), $x, ($y + $height - 1)),
            @(($x + $width), ($y + $height), ($x + $width - 1), ($y + $height - 1))
        )) {
            if (
                $bitmap.GetPixel([int]$corner[0], [int]$corner[1]).ToArgb() -ne
                $bitmap.GetPixel([int]$corner[2], [int]$corner[3]).ToArgb()
            ) {
                $errors.Add("$key corner extrusion does not match its source corner")
                break
            }
        }
    }
    $atlasKey = [string]$asset.atlas_path
    if (-not $validatedBleedAtlases.ContainsKey($atlasKey)) {
        $validatedBleedAtlases[$atlasKey] = $true
        $bleedFound = $false
        for ($pixelY = 0; $pixelY -lt $bitmap.Height -and -not $bleedFound; $pixelY++) {
            for ($pixelX = 0; $pixelX -lt $bitmap.Width; $pixelX++) {
                if (
                    $bitmap.GetPixel($pixelX, $pixelY).A -ne 0 -and
                    -not $occupiedCells[$pixelY * $atlasWidth + $pixelX]
                ) {
                    $errors.Add("$assetId has atlas bleed outside a frame cell at $pixelX,$pixelY")
                    $bleedFound = $true
                    break
                }
            }
        }
    }
}
foreach ($atlasInfo in $atlasCache.Values) {
    $atlasInfo.bitmap.Dispose()
}
if ($assetIds.Count -ne [int]$catalog.asset_count) {
    $errors.Add("asset_count does not match catalog contents")
}
if ($countedFrames -ne [int]$catalog.frame_count) {
    $errors.Add("frame_count does not match catalog contents")
}
if ($errors.Count -gt 0) {
    throw "Pixel asset catalog validation failed:`n$(($errors | ForEach-Object { "- $_" }) -join "`n")"
}
if ($null -ne $catalog.PSObject.Properties["source_overrides"]) {
    & (Join-Path $PSScriptRoot "validate_pixel_source_overrides.ps1") `
        -ManifestPath ([string]$catalog.source_overrides.manifest_path) `
        -CatalogPath $catalogFile
}
Write-Output "Pixel asset catalog valid: assets=$($assetIds.Count); frames=$countedFrames"
