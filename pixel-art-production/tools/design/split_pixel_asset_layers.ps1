param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,

    [Parameter(Mandatory = $true)]
    [string]$SemanticMaskPath,

    [Parameter(Mandatory = $true)]
    [string]$ManifestPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory
)

$ErrorActionPreference = "Stop"

function Read-PixelMap {
    param([string]$Path)

    $result = @{}
    $lines = & $script:Magick.Source $Path -depth 8 "txt:-"
    foreach ($line in $lines) {
        if ($line -notmatch "^(?<x>\d+),(?<y>\d+):.*#(?<rgba>[0-9A-Fa-f]{6}(?:[0-9A-Fa-f]{2})?)") {
            continue
        }
        $rgba = $Matches.rgba.ToUpperInvariant()
        $alpha = if ($rgba.Length -eq 8) { $rgba.Substring(6, 2) } else { "FF" }
        $result["$($Matches.x),$($Matches.y)"] = @{
            color = "#$($rgba.Substring(0, 6))"
            alpha = $alpha
        }
    }
    return $result
}

$workspaceRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $workspaceRoot ".."))
& (Join-Path $PSScriptRoot "validate_pixel_asset_manifest.ps1") -ManifestPath $ManifestPath

function Resolve-InputPath {
    param([string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
}

$source = Resolve-InputPath -Path $SourcePath
$semanticMask = Resolve-InputPath -Path $SemanticMaskPath
$manifestFile = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $ManifestPath))
$destination = Resolve-InputPath -Path $OutputDirectory
$script:Magick = Get-Command magick -ErrorAction Stop

foreach ($path in @($source, $semanticMask, $manifestFile)) {
    if (-not [System.IO.File]::Exists($path)) {
        throw "Required pixel asset input does not exist: $path"
    }
}
if (-not [System.IO.Directory]::Exists($destination)) {
    [System.IO.Directory]::CreateDirectory($destination) | Out-Null
}

$manifest = Get-Content -LiteralPath $manifestFile -Raw | ConvertFrom-Json
$logicalSize = @($manifest.logical_size)
$width = [int]$logicalSize[0]
$height = [int]$logicalSize[1]
$sourceSize = (& $script:Magick.Source identify -format "%w %h" $source).Trim()
$maskSize = (& $script:Magick.Source identify -format "%w %h" $semanticMask).Trim()
if ($sourceSize -ne "$width $height") {
    throw "Source must be ${width}x${height}; got $sourceSize"
}
if ($maskSize -ne "$width $height") {
    throw "Semantic mask must be ${width}x${height}; got $maskSize"
}

$layersByColor = @{}
$layerCounts = @{}
foreach ($layer in @($manifest.layers)) {
    $color = ([string]$layer.mask_color).ToUpperInvariant()
    $layersByColor[$color] = $layer
    $layerCounts[[string]$layer.id] = 0
}

$sourcePixels = Read-PixelMap -Path $source
$maskPixels = Read-PixelMap -Path $semanticMask
$coverageErrors = [System.Collections.Generic.List[string]]::new()
$allowedDisplayColors = @{}
if ([int]$manifest.schema_version -eq 2) {
    $palettePath = Resolve-InputPath -Path ([string]$manifest.palette_path)
    $displayPalette = Get-Content -LiteralPath $palettePath -Raw | ConvertFrom-Json
    foreach ($property in @($displayPalette.colors.PSObject.Properties)) {
        $allowedDisplayColors[([string]$property.Value).ToUpperInvariant()] = $true
    }
}
for ($y = 0; $y -lt $height; $y++) {
    for ($x = 0; $x -lt $width; $x++) {
        $key = "$x,$y"
        if ($sourcePixels[$key].alpha -notin @("00", "FF")) {
            $coverageErrors.Add("partial source alpha at $key")
            continue
        }
        if ($maskPixels[$key].alpha -notin @("00", "FF")) {
            $coverageErrors.Add("partial semantic-mask alpha at $key")
            continue
        }
        $sourceVisible = $sourcePixels[$key].alpha -ne "00"
        $maskVisible = $maskPixels[$key].alpha -ne "00"
        if ($sourceVisible -and -not $maskVisible) {
            $coverageErrors.Add("unassigned source pixel at $key")
            continue
        }
        if (-not $sourceVisible -and $maskVisible) {
            $coverageErrors.Add("semantic pixel outside source at $key")
            continue
        }
        if (-not $sourceVisible) {
            continue
        }
        if (
            [int]$manifest.schema_version -eq 2 -and
            -not $allowedDisplayColors.ContainsKey([string]$sourcePixels[$key].color)
        ) {
            $coverageErrors.Add("unknown display color $($sourcePixels[$key].color) at $key")
            continue
        }
        $maskColor = [string]$maskPixels[$key].color
        if (-not $layersByColor.ContainsKey($maskColor)) {
            $coverageErrors.Add("unknown semantic color $maskColor at $key")
            continue
        }
        $layerId = [string]$layersByColor[$maskColor].id
        $layerCounts[$layerId] = 1 + [int]$layerCounts[$layerId]
    }
}
foreach ($layer in @($manifest.layers)) {
    if ([bool]$layer.required -and [int]$layerCounts[[string]$layer.id] -eq 0) {
        $coverageErrors.Add("required layer has no pixels: $($layer.id)")
    }
}
if ($coverageErrors.Count -gt 0) {
    $details = (
        $coverageErrors |
            Select-Object -First 20 |
            ForEach-Object { "- $_" }
    ) -join [Environment]::NewLine
    throw "Semantic coverage validation failed with $($coverageErrors.Count) error(s).$([Environment]::NewLine)$details"
}

$layersDirectory = Join-Path $destination "layers"
if (-not [System.IO.Directory]::Exists($layersDirectory)) {
    [System.IO.Directory]::CreateDirectory($layersDirectory) | Out-Null
}
$temporaryMask = Join-Path $destination "_layer-mask.png"
$orderedLayers = @($manifest.layers | Sort-Object {[int]$_.z})
$layerPaths = [System.Collections.Generic.List[string]]::new()
foreach ($layer in $orderedLayers) {
    $maskColor = ([string]$layer.mask_color).ToUpperInvariant()
    $outputPath = Join-Path $layersDirectory "$($layer.id).png"
    & $script:Magick.Source $semanticMask -alpha off -fill black "+opaque" $maskColor -fill white -opaque $maskColor $temporaryMask
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create extraction mask for $($layer.id)"
    }
    & $script:Magick.Source $source $temporaryMask -alpha off -compose CopyOpacity -composite -depth 8 -strip $outputPath
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to extract semantic layer $($layer.id)"
    }
    $layerPaths.Add($outputPath)
}

$reassembled = Join-Path $destination "reassembled.png"
$composeArguments = @("-size", "${width}x${height}", "xc:none")
foreach ($layerPath in $layerPaths) {
    $composeArguments += @($layerPath, "-compose", "over", "-composite")
}
$composeArguments += @("-depth", "8", "-strip", $reassembled)
& $script:Magick.Source @composeArguments
if ($LASTEXITCODE -ne 0) {
    throw "Failed to reassemble semantic layers."
}

$difference = & $script:Magick.Source compare -metric AE $source $reassembled "null:" 2>&1
$differenceText = ([string]$difference).Trim()
if ($LASTEXITCODE -ne 0 -or $differenceText -ne "0") {
    throw "Semantic reassembly differs from source by $differenceText pixel(s)."
}

if ([System.IO.File]::Exists($temporaryMask)) {
    Remove-Item -LiteralPath $temporaryMask
}

$summary = [ordered]@{
    asset_id = [string]$manifest.id
    size = @($width, $height)
    source = if ([System.IO.Path]::IsPathRooted($SourcePath)) {
        [System.IO.Path]::GetFileName($SourcePath)
    } else {
        $SourcePath.Replace("\", "/")
    }
    semantic_mask = if ([System.IO.Path]::IsPathRooted($SemanticMaskPath)) {
        [System.IO.Path]::GetFileName($SemanticMaskPath)
    } else {
        $SemanticMaskPath.Replace("\", "/")
    }
    reassembly_pixel_difference = 0
    layers = @(
        $orderedLayers | ForEach-Object {
            [ordered]@{
                id = [string]$_.id
                mask_color = ([string]$_.mask_color).ToUpperInvariant()
                z = [int]$_.z
                pixel_count = [int]$layerCounts[[string]$_.id]
                output = "layers/$($_.id).png"
            }
        }
    )
}
$summaryPath = Join-Path $destination "semantic-build.json"
[System.IO.File]::WriteAllText(
    $summaryPath,
    ($summary | ConvertTo-Json -Depth 6),
    [System.Text.UTF8Encoding]::new($false)
)

Write-Output "Semantic layers valid: $($manifest.id)"
Write-Output "Layers: $($layerPaths.Count); reassembly_pixel_difference=0"
Write-Output "Output: $destination"
