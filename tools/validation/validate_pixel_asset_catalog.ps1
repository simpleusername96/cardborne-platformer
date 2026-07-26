param(
    [Parameter(Mandatory = $true)]
    [string]$CatalogPath
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

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
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

if ([int]$catalog.schema_version -ne 1) { $errors.Add("schema_version must be 1") }
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
    $actualHash = (Get-FileHash -LiteralPath $atlasPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -ne [string]$asset.atlas_sha256) {
        $errors.Add("$assetId atlas checksum mismatch")
    }
    $actualSize = (& $magick.Source identify -format "%w %h" $atlasPath).Trim()
    if ($actualSize -ne "$($asset.atlas_size[0]) $($asset.atlas_size[1])") {
        $errors.Add("$assetId atlas size mismatch: $actualSize")
    }
    if ([int]$asset.padding -ne 2 -or [int]$asset.extrude -ne 1) {
        $errors.Add("$assetId does not use the production gutter contract")
    }
    $pixels = Read-PixelMap -Path $atlasPath
    $occupiedCells = @{}
    foreach ($frame in @($asset.frames)) {
        $countedFrames++
        $key = [string]$frame.key
        if ($frameKeys.ContainsKey($key)) { $errors.Add("duplicate frame key: $key") }
        $frameKeys[$key] = $true
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
        for ($cellY = [int]$cell[1]; $cellY -lt [int]$cell[1] + [int]$cell[3]; $cellY++) {
            for ($cellX = [int]$cell[0]; $cellX -lt [int]$cell[0] + [int]$cell[2]; $cellX++) {
                $occupiedCells["$cellX,$cellY"] = $true
            }
        }
        $x = [int]$region[0]
        $y = [int]$region[1]
        $width = [int]$region[2]
        $height = [int]$region[3]
        for ($offset = 0; $offset -lt $width; $offset++) {
            if ($pixels["$($x+$offset),$($y-1)"] -ne $pixels["$($x+$offset),$y"]) {
                $errors.Add("$key top extrusion does not match its source edge")
                break
            }
            if ($pixels["$($x+$offset),$($y+$height)"] -ne $pixels["$($x+$offset),$($y+$height-1)"]) {
                $errors.Add("$key bottom extrusion does not match its source edge")
                break
            }
        }
        for ($offset = 0; $offset -lt $height; $offset++) {
            if ($pixels["$($x-1),$($y+$offset)"] -ne $pixels["$x,$($y+$offset)"]) {
                $errors.Add("$key left extrusion does not match its source edge")
                break
            }
            if ($pixels["$($x+$width),$($y+$offset)"] -ne $pixels["$($x+$width-1),$($y+$offset)"]) {
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
            if ($pixels["$($corner[0]),$($corner[1])"] -ne $pixels["$($corner[2]),$($corner[3])"]) {
                $errors.Add("$key corner extrusion does not match its source corner")
                break
            }
        }
    }
    foreach ($pixel in $pixels.GetEnumerator()) {
        $alpha = ([string]$pixel.Value).Substring(6, 2)
        if ($alpha -ne "00" -and -not $occupiedCells.ContainsKey([string]$pixel.Key)) {
            $errors.Add("$assetId has atlas bleed outside a frame cell at $($pixel.Key)")
            break
        }
    }
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
Write-Output "Pixel asset catalog valid: assets=$($assetIds.Count); frames=$countedFrames"
