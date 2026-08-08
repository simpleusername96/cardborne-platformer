param(
    [string]$OutputRoot = '',
    [switch]$RenderPngPreviews
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $repoRoot 'docs\design\visual-replacement-workbench\candidates\surface-detail-svg-experiment'
}
$OutputRoot = [IO.Path]::GetFullPath($OutputRoot)
$assetsRoot = Join-Path $OutputRoot 'assets'
$previewsRoot = Join-Path $OutputRoot 'previews'
[void](New-Item -ItemType Directory -Force -Path $assetsRoot, $previewsRoot)

$invariant = [Globalization.CultureInfo]::InvariantCulture
$utf8NoBom = [Text.UTF8Encoding]::new($false)

function Format-Number([double]$Value) {
    return $Value.ToString('0.###', $invariant)
}

function Next-Range([Random]$Rng, [double]$Minimum, [double]$Maximum) {
    return $Minimum + (($Maximum - $Minimum) * $Rng.NextDouble())
}

function Write-Utf8Svg([string]$LiteralPath, [string]$Content) {
    $normalized = $Content.Replace("`r`n", "`n").Trim() + "`n"
    [IO.File]::WriteAllText($LiteralPath, $normalized, $utf8NoBom)
}

function Get-SvgVisualFragment([string]$Content) {
    $fragment = [regex]::Replace($Content, '(?s)^.*?</desc>\s*', '')
    return [regex]::Replace($fragment, '(?s)\s*</svg>\s*$', '').Trim()
}

function New-SvgHeader([int]$Width, [int]$Height, [string]$Title) {
    return @"
<svg xmlns="http://www.w3.org/2000/svg" width="$Width" height="$Height" viewBox="0 0 $Width $Height" shape-rendering="geometricPrecision">
  <title>$Title</title>
  <desc>Review-only deterministic SVG experiment authorized by the user on 2026-08-09. Not approved or connected to runtime.</desc>
"@
}

function New-PolylinePath([object[]]$Points) {
    $commands = [Collections.Generic.List[string]]::new()
    for ($index = 0; $index -lt $Points.Count; $index += 1) {
        $prefix = if ($index -eq 0) { 'M' } else { 'L' }
        $commands.Add("$prefix $(Format-Number $Points[$index].X) $(Format-Number $Points[$index].Y)")
    }
    return $commands -join ' '
}

function New-CrackSvg([int]$Seed, [int]$Variant) {
    $rng = [Random]::new($Seed)
    $points = [Collections.Generic.List[object]]::new()
    $x = Next-Range $rng 39 57
    $y = Next-Range $rng 10 15
    $points.Add([pscustomobject]@{ X = $x; Y = $y })
    for ($index = 0; $index -lt 6; $index += 1) {
        $x = [Math]::Max(15, [Math]::Min(81, $x + (Next-Range $rng -8.5 8.5)))
        $y += Next-Range $rng 9.5 13
        $points.Add([pscustomobject]@{ X = $x; Y = $y })
    }

    $branches = [Collections.Generic.List[string]]::new()
    foreach ($anchorIndex in @(2, 4)) {
        $anchor = $points[$anchorIndex]
        $side = if ($rng.NextDouble() -lt 0.5) { -1.0 } else { 1.0 }
        $branchPoints = @(
            [pscustomobject]@{ X = $anchor.X; Y = $anchor.Y },
            [pscustomobject]@{ X = $anchor.X + ($side * (Next-Range $rng 8 14)); Y = $anchor.Y + (Next-Range $rng 3 7) },
            [pscustomobject]@{ X = $anchor.X + ($side * (Next-Range $rng 15 23)); Y = $anchor.Y + (Next-Range $rng 9 15) }
        )
        $branches.Add((New-PolylinePath $branchPoints))
    }

    $header = New-SvgHeader 96 96 "Compact surface crack $Variant"
    return @"
$header
  <g fill="none" stroke="#536979" stroke-linecap="round" stroke-linejoin="round">
    <path d="$(New-PolylinePath $points.ToArray())" stroke-opacity="0.46" stroke-width="2.1"/>
    <path d="$($branches[0])" stroke-opacity="0.34" stroke-width="1.45"/>
    <path d="$($branches[1])" stroke-opacity="0.3" stroke-width="1.25"/>
  </g>
</svg>
"@
}

function New-BlobPath([Random]$Rng, [double]$CenterX, [double]$CenterY, [double]$RadiusX, [double]$RadiusY, [int]$PointCount) {
    $points = [Collections.Generic.List[object]]::new()
    for ($index = 0; $index -lt $PointCount; $index += 1) {
        $angle = (2.0 * [Math]::PI * $index) / $PointCount
        $radiusFactor = Next-Range $Rng 0.78 1.12
        $points.Add([pscustomobject]@{
            X = $CenterX + ([Math]::Cos($angle) * $RadiusX * $radiusFactor)
            Y = $CenterY + ([Math]::Sin($angle) * $RadiusY * $radiusFactor)
        })
    }
    return (New-PolylinePath $points.ToArray()) + ' Z'
}

function New-StainSvg([int]$Seed, [int]$Variant) {
    $rng = [Random]::new($Seed)
    $outer = New-BlobPath $rng 64 48 50 28 15
    $middle = New-BlobPath $rng (Next-Range $rng 57 63) (Next-Range $rng 45 50) 34 20 13
    $island = New-BlobPath $rng (Next-Range $rng 78 90) (Next-Range $rng 34 43) 13 8 9
    $header = New-SvgHeader 128 96 "Broad low-contrast wear stain $Variant"
    return @"
$header
  <path d="$outer" fill="#627887" fill-opacity="0.1"/>
  <path d="$middle" fill="#536B7B" fill-opacity="0.08"/>
  <path d="$island" fill="#718594" fill-opacity="0.07"/>
</svg>
"@
}

function New-PolygonPoints([Random]$Rng, [double]$CenterX, [double]$CenterY, [double]$RadiusX, [double]$RadiusY, [int]$PointCount) {
    $points = [Collections.Generic.List[string]]::new()
    for ($index = 0; $index -lt $PointCount; $index += 1) {
        $angle = (2.0 * [Math]::PI * $index) / $PointCount
        $radiusFactor = Next-Range $Rng 0.78 1.1
        $x = $CenterX + ([Math]::Cos($angle) * $RadiusX * $radiusFactor)
        $y = $CenterY + ([Math]::Sin($angle) * $RadiusY * $radiusFactor)
        $points.Add("$(Format-Number $x),$(Format-Number $y)")
    }
    return $points -join ' '
}

function New-ChipSvg([int]$Seed, [int]$Variant) {
    $rng = [Random]::new($Seed)
    $outer = New-PolygonPoints $rng 32 32 25 10.5 10
    $exposedLayer = New-PolygonPoints $rng (Next-Range $rng 29 33) (Next-Range $rng 31 34) 17 6.5 8
    $edgeLeftX = Next-Range $rng 11 17
    $edgeLeftY = Next-Range $rng 28 33
    $edgeCenterX = Next-Range $rng 20 27
    $edgeCenterY = Next-Range $rng 25 29
    $edgeRightX = Next-Range $rng 43 51
    $edgeRightY = Next-Range $rng 31 35
    $header = New-SvgHeader 64 64 "Shallow embedded surface chip $Variant"
    return @"
$header
  <polygon points="$outer" fill="#5D7282" fill-opacity="0.19"/>
  <polygon points="$exposedLayer" fill="#718493" fill-opacity="0.12"/>
  <path d="M $(Format-Number $edgeLeftX) $(Format-Number $edgeLeftY) L $(Format-Number $edgeCenterX) $(Format-Number $edgeCenterY) M $(Format-Number ($edgeRightX - 8)) $(Format-Number ($edgeRightY - 3)) L $(Format-Number $edgeRightX) $(Format-Number $edgeRightY)" fill="none" stroke="#4F6575" stroke-opacity="0.17" stroke-width="1.15" stroke-linecap="round"/>
</svg>
"@
}

$assetDefinitions = @(
    @{ Name = 'surface_crack_01.svg'; Symbol = 'surface-crack-01'; Width = 96; Height = 96; Content = New-CrackSvg 41011 1 },
    @{ Name = 'surface_crack_02.svg'; Symbol = 'surface-crack-02'; Width = 96; Height = 96; Content = New-CrackSvg 41029 2 },
    @{ Name = 'surface_stain_01.svg'; Symbol = 'surface-stain-01'; Width = 128; Height = 96; Content = New-StainSvg 52021 1 },
    @{ Name = 'surface_stain_02.svg'; Symbol = 'surface-stain-02'; Width = 128; Height = 96; Content = New-StainSvg 52057 2 },
    @{ Name = 'surface_chip_01.svg'; Symbol = 'surface-chip-01'; Width = 64; Height = 64; Content = New-ChipSvg 63029 1 },
    @{ Name = 'surface_chip_02.svg'; Symbol = 'surface-chip-02'; Width = 64; Height = 64; Content = New-ChipSvg 63043 2 }
)

foreach ($asset in $assetDefinitions) {
    Write-Utf8Svg (Join-Path $assetsRoot $asset.Name) $asset.Content
}

$assetBySymbol = @{}
foreach ($asset in $assetDefinitions) {
    $assetBySymbol[$asset.Symbol] = $asset
}

function New-EmbeddedInstance([hashtable]$Asset, [double]$X, [double]$Y, [double]$Width, [double]$Height, [double]$Rotation, [double]$Opacity) {
    $scaleX = $Width / $Asset.Width
    $scaleY = $Height / $Asset.Height
    $centerX = $X + ($Width / 2.0)
    $centerY = $Y + ($Height / 2.0)
    $fragment = Get-SvgVisualFragment $Asset.Content
    return @"
    <g transform="rotate($(Format-Number $Rotation) $(Format-Number $centerX) $(Format-Number $centerY))" opacity="$(Format-Number $Opacity)">
      <g transform="translate($(Format-Number $X) $(Format-Number $Y))">
        <g transform="scale($(Format-Number $scaleX) $(Format-Number $scaleY))">
$fragment
        </g>
      </g>
    </g>
"@
}

$sheetCrack1 = New-EmbeddedInstance $assetBySymbol['surface-crack-01'] 70 125 96 96 0 1
$sheetCrack2 = New-EmbeddedInstance $assetBySymbol['surface-crack-02'] 178 206 96 96 0 1
$sheetStain1 = New-EmbeddedInstance $assetBySymbol['surface-stain-01'] 375 130 128 96 0 1
$sheetStain2 = New-EmbeddedInstance $assetBySymbol['surface-stain-02'] 456 220 128 96 180 1
$sheetChip1 = New-EmbeddedInstance $assetBySymbol['surface-chip-01'] 700 145 64 64 0 1
$sheetChip2 = New-EmbeddedInstance $assetBySymbol['surface-chip-02'] 790 235 64 64 90 1

$sheetHeader = New-SvgHeader 960 420 'Surface detail SVG candidate sheet'
$assetSheet = @"
$sheetHeader
  <rect width="960" height="420" fill="#EEF3F7"/>
  <text x="40" y="48" fill="#243445" font-family="Arial, sans-serif" font-size="22" font-weight="700">SURFACE DETAIL — SVG EXPERIMENT</text>
  <text x="40" y="73" fill="#465A6E" font-family="Arial, sans-serif" font-size="14">REVIEW ONLY · NOT CONNECTED TO RUNTIME</text>
  <g>
    <rect x="40" y="105" width="270" height="270" rx="8" fill="#9EADBC"/>
$sheetCrack1
$sheetCrack2
    <text x="58" y="352" fill="#243445" font-family="Arial, sans-serif" font-size="14" font-weight="700">CRACK · 96×96</text>
  </g>
  <g>
    <rect x="345" y="105" width="270" height="270" rx="8" fill="#9EADBC"/>
$sheetStain1
$sheetStain2
    <text x="363" y="352" fill="#243445" font-family="Arial, sans-serif" font-size="14" font-weight="700">WEAR STAIN · 128×96</text>
  </g>
  <g>
    <rect x="650" y="105" width="270" height="270" rx="8" fill="#9EADBC"/>
$sheetChip1
$sheetChip2
    <text x="668" y="352" fill="#243445" font-family="Arial, sans-serif" font-size="14" font-weight="700">EMBEDDED CHIP · 64×64</text>
  </g>
</svg>
"@
Write-Utf8Svg (Join-Path $previewsRoot 'surface_detail_asset_sheet.svg') $assetSheet

$previewRng = [Random]::new(74017)
$placements = [Collections.Generic.List[object]]::new()
$families = @(
    @{ Symbols = @('surface-crack-01', 'surface-crack-02'); Width = 96; Height = 96; Count = 7; Scales = @(0.55, 0.7, 0.85) },
    @{ Symbols = @('surface-stain-01', 'surface-stain-02'); Width = 128; Height = 96; Count = 6; Scales = @(0.65, 0.8, 1.0) },
    @{ Symbols = @('surface-chip-01', 'surface-chip-02'); Width = 64; Height = 64; Count = 7; Scales = @(0.5, 0.65, 0.8) }
)

foreach ($family in $families) {
    for ($index = 0; $index -lt $family.Count; $index += 1) {
        $accepted = $false
        for ($attempt = 0; $attempt -lt 80 -and -not $accepted; $attempt += 1) {
            $x = Next-Range $previewRng 55 1160
            $y = Next-Range $previewRng 45 630
            $accepted = $true
            foreach ($existing in $placements) {
                $dx = $x - $existing.X
                $dy = $y - $existing.Y
                if ((($dx * $dx) + ($dy * $dy)) -lt (105 * 105)) {
                    $accepted = $false
                    break
                }
            }
        }
        if (-not $accepted) { continue }
        $scale = $family.Scales[$previewRng.Next(0, $family.Scales.Count)]
        $placements.Add([pscustomobject]@{
            Symbol = $family.Symbols[$previewRng.Next(0, $family.Symbols.Count)]
            X = $x
            Y = $y
            Width = $family.Width * $scale
            Height = $family.Height * $scale
            Rotation = @(0, 90, 180, 270)[$previewRng.Next(0, 4)]
            Opacity = Next-Range $previewRng 0.78 1.0
        })
    }
}

$placementMarkup = [Collections.Generic.List[string]]::new()
foreach ($placement in $placements) {
    $placementMarkup.Add((New-EmbeddedInstance $assetBySymbol[$placement.Symbol] $placement.X $placement.Y $placement.Width $placement.Height $placement.Rotation $placement.Opacity))
}

$previewHeader = New-SvgHeader 1280 720 'Sparse deterministic surface detail distribution preview'
$distributionPreview = @"
$previewHeader
  <rect width="1280" height="720" fill="#9EADBC"/>
$($placementMarkup -join "`n")
</svg>
"@
Write-Utf8Svg (Join-Path $previewsRoot 'surface_detail_distribution_preview.svg') $distributionPreview

if ($RenderPngPreviews) {
    $magick = Get-Command magick -ErrorAction Stop
    foreach ($previewName in @('surface_detail_asset_sheet', 'surface_detail_distribution_preview')) {
        $svgPath = Join-Path $previewsRoot "$previewName.svg"
        $pngPath = Join-Path $previewsRoot "$previewName.png"
        & $magick.Source -background none $svgPath -strip $pngPath
        if ($LASTEXITCODE -ne 0) {
            throw "ImageMagick preview conversion failed for $svgPath"
        }
    }
}

Write-Output "SURFACE_DETAIL_SVG_EXPERIMENT_OK assets=$($assetDefinitions.Count) placements=$($placements.Count) png_previews=$([bool]$RenderPngPreviews) root=$OutputRoot"
