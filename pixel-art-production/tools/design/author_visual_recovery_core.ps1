param(
    [string]$SourceDirectory = "pixel-art-production/assets/source/candidates/visual-recovery/native",
    [string]$OutputDirectory = "pixel-art-production/assets/source/approved/visual-recovery/core",
    [string]$EvidenceDirectory = "pixel-art-production/assets/source/candidates/visual-recovery/evidence"
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../../.."))
$sourceRoot = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $SourceDirectory))
$outputRoot = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutputDirectory))
$evidenceRoot = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $EvidenceDirectory))
$magick = (Get-Command magick -ErrorAction Stop).Source

$palette = [ordered]@{
    space = "#141B24"
    recess = "#202833"
    shadow = "#2E3945"
    deck = "#44515E"
    blocker = "#596774"
    edge = "#222B35"
    ivory = "#E8EEF0"
    mustard = "#D9A83D"
    cyan = "#65A9B8"
    coral = "#C92F4E"
    boss = "#962754"
    mint = "#75C4B2"
    thermal = "#E45F36"
    toxin = "#769A32"
    cryo = "#3E91B7"
    arc = "#9B59B6"
}
$allowedColors = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]$palette.Values,
    [System.StringComparer]::OrdinalIgnoreCase
)

function ConvertTo-Color {
    param([Parameter(Mandatory = $true)][string]$Hex)

    return [System.Drawing.ColorTranslator]::FromHtml($Hex)
}

function Get-Hex {
    param([Parameter(Mandatory = $true)][System.Drawing.Color]$Color)

    return "#{0:X2}{1:X2}{2:X2}" -f $Color.R, $Color.G, $Color.B
}

function Open-NormalizedBitmap {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not [System.IO.File]::Exists($Path)) {
        throw "Native recovery candidate does not exist: $Path"
    }
    $source = [System.Drawing.Bitmap]::new($Path)
    $result = [System.Drawing.Bitmap]::new(
        $source.Width,
        $source.Height,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    for ($y = 0; $y -lt $source.Height; $y++) {
        for ($x = 0; $x -lt $source.Width; $x++) {
            $result.SetPixel($x, $y, $source.GetPixel($x, $y))
        }
    }
    $source.Dispose()
    return $result
}

function Save-Bitmap {
    param(
        [Parameter(Mandatory = $true)][System.Drawing.Bitmap]$Bitmap,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Set-OppositeEdgesEqual {
    param([Parameter(Mandatory = $true)][System.Drawing.Bitmap]$Bitmap)

    $lastX = $Bitmap.Width - 1
    $lastY = $Bitmap.Height - 1
    for ($x = 0; $x -lt $Bitmap.Width; $x++) {
        $Bitmap.SetPixel($x, $lastY, $Bitmap.GetPixel($x, 0))
    }
    for ($y = 0; $y -lt $Bitmap.Height; $y++) {
        $Bitmap.SetPixel($lastX, $y, $Bitmap.GetPixel(0, $y))
    }
}

function Replace-Colors {
    param(
        [Parameter(Mandatory = $true)][System.Drawing.Bitmap]$Bitmap,
        [Parameter(Mandatory = $true)][hashtable]$Map
    )

    for ($y = 0; $y -lt $Bitmap.Height; $y++) {
        for ($x = 0; $x -lt $Bitmap.Width; $x++) {
            $pixel = $Bitmap.GetPixel($x, $y)
            if ($pixel.A -eq 0) {
                continue
            }
            $hex = Get-Hex -Color $pixel
            if ($Map.ContainsKey($hex)) {
                $Bitmap.SetPixel($x, $y, (ConvertTo-Color -Hex ([string]$Map[$hex])))
            }
        }
    }
}

function New-FilledBitmap {
    param(
        [Parameter(Mandatory = $true)][int]$Size,
        [Parameter(Mandatory = $true)][string]$Hex
    )

    $bitmap = [System.Drawing.Bitmap]::new(
        $Size,
        $Size,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    $color = ConvertTo-Color -Hex $Hex
    for ($y = 0; $y -lt $Size; $y++) {
        for ($x = 0; $x -lt $Size; $x++) {
            $bitmap.SetPixel($x, $y, $color)
        }
    }
    return $bitmap
}

function Copy-MaskCrop {
    param(
        [Parameter(Mandatory = $true)][System.Drawing.Bitmap]$Source,
        [Parameter(Mandatory = $true)][System.Drawing.Bitmap]$Target,
        [Parameter(Mandatory = $true)][System.Drawing.Rectangle]$SourceRect,
        [Parameter(Mandatory = $true)][int]$TargetX,
        [Parameter(Mandatory = $true)][int]$TargetY,
        [Parameter(Mandatory = $true)][hashtable]$ColorMap,
        [switch]$FlipX,
        [switch]$FlipY
    )

    for ($localY = 0; $localY -lt $SourceRect.Height; $localY++) {
        for ($localX = 0; $localX -lt $SourceRect.Width; $localX++) {
            $sourceX = if ($FlipX) {
                $SourceRect.Right - 1 - $localX
            } else {
                $SourceRect.Left + $localX
            }
            $sourceY = if ($FlipY) {
                $SourceRect.Bottom - 1 - $localY
            } else {
                $SourceRect.Top + $localY
            }
            $sourceHex = Get-Hex -Color ($Source.GetPixel($sourceX, $sourceY))
            if ($ColorMap.ContainsKey($sourceHex)) {
                $Target.SetPixel(
                    $TargetX + $localX,
                    $TargetY + $localY,
                    (ConvertTo-Color -Hex ([string]$ColorMap[$sourceHex]))
                )
            }
        }
    }
}

function Assert-NativeContract {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][int]$Size,
        [switch]$RepeatSafe,
        [switch]$RequireTransparency
    )

    $bitmap = [System.Drawing.Bitmap]::new($Path)
    try {
        if ($bitmap.Width -ne $Size -or $bitmap.Height -ne $Size) {
            throw "Unexpected dimensions for $Path"
        }
        $visible = 0
        $transparent = 0
        for ($y = 0; $y -lt $bitmap.Height; $y++) {
            for ($x = 0; $x -lt $bitmap.Width; $x++) {
                $pixel = $bitmap.GetPixel($x, $y)
                if ($pixel.A -notin @(0, 255)) {
                    throw "Partial alpha in $Path at $x,$y"
                }
                if ($pixel.A -eq 0) {
                    $transparent++
                    if ($RepeatSafe) {
                        throw "Repeat tile contains transparency: $Path"
                    }
                    continue
                }
                $visible++
                $hex = Get-Hex -Color $pixel
                if (-not $allowedColors.Contains($hex)) {
                    throw "Off-palette color $hex in $Path at $x,$y"
                }
            }
        }
        if ($visible -eq 0) {
            throw "Approved master is empty: $Path"
        }
        if ($RequireTransparency -and $transparent -eq 0) {
            throw "Approved actor/pickup has no transparent exterior: $Path"
        }
        if ($RepeatSafe) {
            $lastX = $bitmap.Width - 1
            $lastY = $bitmap.Height - 1
            for ($x = 0; $x -lt $bitmap.Width; $x++) {
                if ($bitmap.GetPixel($x, 0).ToArgb() -ne $bitmap.GetPixel($x, $lastY).ToArgb()) {
                    throw "Top/bottom seam mismatch in $Path at column $x"
                }
            }
            for ($y = 0; $y -lt $bitmap.Height; $y++) {
                if ($bitmap.GetPixel(0, $y).ToArgb() -ne $bitmap.GetPixel($lastX, $y).ToArgb()) {
                    throw "Left/right seam mismatch in $Path at row $y"
                }
            }
        }
    } finally {
        $bitmap.Dispose()
    }
}

[System.IO.Directory]::CreateDirectory($outputRoot) | Out-Null
[System.IO.Directory]::CreateDirectory($evidenceRoot) | Out-Null

# Actor silhouettes already passed the logical-cell snap. Re-encoding removes
# source metadata while preserving every approved opaque/transparent cell.
foreach ($actor in @(
    [ordered]@{name = "player-interceptor-64.png"; size = 64},
    [ordered]@{name = "chaser-32.png"; size = 32}
)) {
    $bitmap = Open-NormalizedBitmap -Path (Join-Path $sourceRoot $actor.name)
    try {
        Save-Bitmap -Bitmap $bitmap -Path (Join-Path $outputRoot $actor.name)
    } finally {
        $bitmap.Dispose()
    }
}

# Keep four quiet crops of the generated ceramic masses and flatten the rest.
# This retains ImageGen's irregular contours without turning one large diagonal
# gesture into a screen-filling repeated symbol.
$floorSource = Open-NormalizedBitmap -Path (Join-Path $sourceRoot "ceramic-deck-24.png")
$floor = [System.Drawing.Bitmap]::new(
    24,
    24,
    [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
)
try {
    $deckColor = ConvertTo-Color -Hex $palette.deck
    $shadowColor = ConvertTo-Color -Hex $palette.shadow
    $floorRegions = @(
        [System.Drawing.Rectangle]::new(2, 2, 6, 6),
        [System.Drawing.Rectangle]::new(14, 3, 7, 7),
        [System.Drawing.Rectangle]::new(5, 14, 8, 7),
        [System.Drawing.Rectangle]::new(17, 15, 5, 6)
    )
    for ($y = 0; $y -lt $floor.Height; $y++) {
        for ($x = 0; $x -lt $floor.Width; $x++) {
            $floor.SetPixel($x, $y, $deckColor)
            $insideCrop = $false
            foreach ($region in $floorRegions) {
                if ($region.Contains($x, $y)) {
                    $insideCrop = $true
                    break
                }
            }
            if (
                $insideCrop -and
                (Get-Hex -Color ($floorSource.GetPixel($x, $y))) -eq $palette.shadow
            ) {
                $floor.SetPixel($x, $y, $shadowColor)
            }
        }
    }
    Set-OppositeEdgesEqual -Bitmap $floor
    Save-Bitmap -Bitmap $floor -Path (Join-Path $outputRoot "ceramic-deck-24.png")
} finally {
    $floor.Dispose()
    $floorSource.Dispose()
}

# Replace the generated full-width contact band with two large recessed panels.
# The blocker remains quiet and unmistakably solid when repeated in two axes.
$wall = Open-NormalizedBitmap -Path (Join-Path $sourceRoot "ceramic-wall-24.png")
try {
    $deckColor = ConvertTo-Color -Hex $palette.deck
    $shadowColor = ConvertTo-Color -Hex $palette.shadow
    $blockerColor = ConvertTo-Color -Hex $palette.blocker
    for ($y = 0; $y -lt $wall.Height; $y++) {
        for ($x = 0; $x -lt $wall.Width; $x++) {
            $wall.SetPixel($x, $y, $blockerColor)
        }
    }
    foreach ($panel in @(
        [System.Drawing.Rectangle]::new(3, 5, 6, 4),
        [System.Drawing.Rectangle]::new(15, 15, 6, 4)
    )) {
        for ($y = $panel.Top; $y -lt $panel.Bottom; $y++) {
            for ($x = $panel.Left; $x -lt $panel.Right; $x++) {
                $isInner = (
                    $x -gt $panel.Left -and
                    $x -lt ($panel.Right - 1) -and
                    $y -gt $panel.Top -and
                    $y -lt ($panel.Bottom - 1)
                )
                $wall.SetPixel($x, $y, $(if ($isInner) { $shadowColor } else { $deckColor }))
            }
        }
    }
    Set-OppositeEdgesEqual -Bitmap $wall
    Save-Bitmap -Bitmap $wall -Path (Join-Path $outputRoot "ceramic-wall-24.png")
} finally {
    $wall.Dispose()
}

# Preserve only two short crops of the generated wave mass. The full generated
# loop read as a repeated glyph; these separated fragments read as sparse water.
$waterSource = Open-NormalizedBitmap -Path (Join-Path $sourceRoot "cobalt-water-24.png")
$water = [System.Drawing.Bitmap]::new(
    24,
    24,
    [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
)
try {
    $spaceColor = ConvertTo-Color -Hex $palette.space
    $cryoColor = ConvertTo-Color -Hex $palette.cryo
    $cyanColor = ConvertTo-Color -Hex $palette.cyan
    $waveRegions = @(
        [System.Drawing.Rectangle]::new(2, 3, 10, 6),
        [System.Drawing.Rectangle]::new(12, 16, 10, 6)
    )
    for ($y = 0; $y -lt $water.Height; $y++) {
        for ($x = 0; $x -lt $water.Width; $x++) {
            $water.SetPixel($x, $y, $spaceColor)
            $insideCrop = $false
            foreach ($region in $waveRegions) {
                if ($region.Contains($x, $y)) {
                    $insideCrop = $true
                    break
                }
            }
            if (-not $insideCrop) {
                continue
            }
            $sourceHex = Get-Hex -Color ($waterSource.GetPixel($x, $y))
            if ($sourceHex -eq $palette.cryo) {
                $water.SetPixel($x, $y, $cryoColor)
            } elseif ($sourceHex -eq $palette.cyan) {
                $water.SetPixel($x, $y, $cyanColor)
            }
        }
    }
    Set-OppositeEdgesEqual -Bitmap $water
    Save-Bitmap -Bitmap $water -Path (Join-Path $outputRoot "cobalt-water-24.png")
} finally {
    $water.Dispose()
    $waterSource.Dispose()
}

# The snap preserved two grid-border artifacts outside the capsule. Remove only
# those exterior rows; the generated mint body and large ivory plus stay intact.
$repair = Open-NormalizedBitmap -Path (Join-Path $sourceRoot "repair-pickup-24.png")
try {
    $transparent = [System.Drawing.Color]::FromArgb(0, 255, 255, 255)
    foreach ($row in @(4, 21)) {
        for ($x = 0; $x -lt $repair.Width; $x++) {
            $repair.SetPixel($x, $row, $transparent)
        }
    }
    Save-Bitmap -Bitmap $repair -Path (Join-Path $outputRoot "repair-pickup-24.png")
} finally {
    $repair.Dispose()
}

# Runtime repeat surfaces use a larger source period than the native 24-cell
# masters. Each material remains built from the generated cell masks, but its
# fragments are distributed irregularly so gameplay does not read one glyph
# stamped across the entire map.
$floorSeed = Open-NormalizedBitmap -Path (Join-Path $sourceRoot "ceramic-deck-24.png")
$floorRepeat = New-FilledBitmap -Size 192 -Hex $palette.deck
try {
    $floorCrops = @(
        [ordered]@{rect = [System.Drawing.Rectangle]::new(2, 2, 6, 6); x = 14; y = 16; fx = $false; fy = $false},
        [ordered]@{rect = [System.Drawing.Rectangle]::new(14, 3, 7, 7); x = 68; y = 10; fx = $true; fy = $false},
        [ordered]@{rect = [System.Drawing.Rectangle]::new(5, 14, 8, 7); x = 134; y = 24; fx = $false; fy = $true},
        [ordered]@{rect = [System.Drawing.Rectangle]::new(17, 15, 5, 6); x = 168; y = 62; fx = $true; fy = $true},
        [ordered]@{rect = [System.Drawing.Rectangle]::new(5, 14, 8, 7); x = 30; y = 74; fx = $true; fy = $false},
        [ordered]@{rect = [System.Drawing.Rectangle]::new(2, 2, 6, 6); x = 96; y = 64; fx = $false; fy = $true},
        [ordered]@{rect = [System.Drawing.Rectangle]::new(14, 3, 7, 7); x = 140; y = 102; fx = $false; fy = $false},
        [ordered]@{rect = [System.Drawing.Rectangle]::new(17, 15, 5, 6); x = 12; y = 132; fx = $false; fy = $true},
        [ordered]@{rect = [System.Drawing.Rectangle]::new(14, 3, 7, 7); x = 68; y = 150; fx = $true; fy = $true},
        [ordered]@{rect = [System.Drawing.Rectangle]::new(5, 14, 8, 7); x = 118; y = 138; fx = $false; fy = $false},
        [ordered]@{rect = [System.Drawing.Rectangle]::new(2, 2, 6, 6); x = 164; y = 164; fx = $true; fy = $false}
    )
    foreach ($crop in $floorCrops) {
        Copy-MaskCrop -Source $floorSeed -Target $floorRepeat -SourceRect $crop.rect `
            -TargetX $crop.x -TargetY $crop.y -FlipX:$crop.fx -FlipY:$crop.fy `
            -ColorMap @{
                "#2E3945" = $palette.shadow
                "#596774" = $palette.shadow
            }
    }
    Set-OppositeEdgesEqual -Bitmap $floorRepeat
    Save-Bitmap -Bitmap $floorRepeat -Path (Join-Path $outputRoot "ceramic-deck-repeat-192.png")
} finally {
    $floorRepeat.Dispose()
    $floorSeed.Dispose()
}

$wallRepeat = New-FilledBitmap -Size 192 -Hex $palette.blocker
try {
    $deckColor = ConvertTo-Color -Hex $palette.deck
    $shadowColor = ConvertTo-Color -Hex $palette.shadow
    foreach ($panel in @(
        [System.Drawing.Rectangle]::new(16, 14, 14, 8),
        [System.Drawing.Rectangle]::new(110, 20, 10, 6),
        [System.Drawing.Rectangle]::new(62, 76, 16, 9),
        [System.Drawing.Rectangle]::new(150, 104, 12, 7),
        [System.Drawing.Rectangle]::new(22, 146, 18, 8),
        [System.Drawing.Rectangle]::new(104, 164, 12, 6)
    )) {
        for ($y = $panel.Top; $y -lt $panel.Bottom; $y++) {
            for ($x = $panel.Left; $x -lt $panel.Right; $x++) {
                $isInner = (
                    $x -gt $panel.Left -and
                    $x -lt ($panel.Right - 1) -and
                    $y -gt $panel.Top -and
                    $y -lt ($panel.Bottom - 1)
                )
                $wallRepeat.SetPixel($x, $y, $(if ($isInner) { $shadowColor } else { $deckColor }))
            }
        }
    }
    Set-OppositeEdgesEqual -Bitmap $wallRepeat
    Save-Bitmap -Bitmap $wallRepeat -Path (Join-Path $outputRoot "ceramic-wall-repeat-192.png")
} finally {
    $wallRepeat.Dispose()
}

$waterSeed = Open-NormalizedBitmap -Path (Join-Path $sourceRoot "cobalt-water-24.png")
$waterRepeat = New-FilledBitmap -Size 192 -Hex $palette.space
try {
    $waterCrops = @(
        [ordered]@{rect = [System.Drawing.Rectangle]::new(2, 3, 10, 6); x = 12; y = 16; fx = $false; fy = $false},
        [ordered]@{rect = [System.Drawing.Rectangle]::new(12, 16, 10, 6); x = 74; y = 24; fx = $true; fy = $false},
        [ordered]@{rect = [System.Drawing.Rectangle]::new(2, 3, 10, 6); x = 144; y = 44; fx = $true; fy = $true},
        [ordered]@{rect = [System.Drawing.Rectangle]::new(12, 16, 10, 6); x = 34; y = 86; fx = $false; fy = $true},
        [ordered]@{rect = [System.Drawing.Rectangle]::new(2, 3, 10, 6); x = 106; y = 98; fx = $false; fy = $true},
        [ordered]@{rect = [System.Drawing.Rectangle]::new(12, 16, 10, 6); x = 156; y = 126; fx = $true; fy = $false},
        [ordered]@{rect = [System.Drawing.Rectangle]::new(2, 3, 10, 6); x = 16; y = 150; fx = $true; fy = $false},
        [ordered]@{rect = [System.Drawing.Rectangle]::new(12, 16, 10, 6); x = 88; y = 164; fx = $false; fy = $false}
    )
    foreach ($crop in $waterCrops) {
        Copy-MaskCrop -Source $waterSeed -Target $waterRepeat -SourceRect $crop.rect `
            -TargetX $crop.x -TargetY $crop.y -FlipX:$crop.fx -FlipY:$crop.fy `
            -ColorMap @{
                "#3E91B7" = $palette.cryo
                "#65A9B8" = $palette.cyan
            }
    }
    Set-OppositeEdgesEqual -Bitmap $waterRepeat
    Save-Bitmap -Bitmap $waterRepeat -Path (Join-Path $outputRoot "cobalt-water-repeat-192.png")
} finally {
    $waterRepeat.Dispose()
    $waterSeed.Dispose()
}

Assert-NativeContract -Path (Join-Path $outputRoot "player-interceptor-64.png") -Size 64 -RequireTransparency
Assert-NativeContract -Path (Join-Path $outputRoot "chaser-32.png") -Size 32 -RequireTransparency
Assert-NativeContract -Path (Join-Path $outputRoot "repair-pickup-24.png") -Size 24 -RequireTransparency
foreach ($tileName in @("ceramic-deck-24.png", "ceramic-wall-24.png", "cobalt-water-24.png")) {
    Assert-NativeContract -Path (Join-Path $outputRoot $tileName) -Size 24 -RepeatSafe
}
foreach ($tileName in @("ceramic-deck-repeat-192.png", "ceramic-wall-repeat-192.png", "cobalt-water-repeat-192.png")) {
    Assert-NativeContract -Path (Join-Path $outputRoot $tileName) -Size 192 -RepeatSafe
}

$contactSheet = Join-Path $evidenceRoot "approved-core-contact-sheet.png"
& $magick montage `
    (Join-Path $outputRoot "player-interceptor-64.png") `
    (Join-Path $outputRoot "chaser-32.png") `
    (Join-Path $outputRoot "ceramic-deck-24.png") `
    (Join-Path $outputRoot "ceramic-wall-24.png") `
    (Join-Path $outputRoot "cobalt-water-24.png") `
    (Join-Path $outputRoot "repair-pickup-24.png") `
    -filter point -geometry "384x384+24+24" -tile 3x2 -background $palette.space `
    $contactSheet
if ($LASTEXITCODE -ne 0) {
    throw "Could not build the approved core contact sheet."
}

$tileProofs = [System.Collections.Generic.List[string]]::new()
foreach ($tileName in @(
    "ceramic-deck-repeat-192.png",
    "ceramic-wall-repeat-192.png",
    "cobalt-water-repeat-192.png"
)) {
    $sourcePath = Join-Path $outputRoot $tileName
    $proofPath = Join-Path $evidenceRoot ($tileName -replace "\.png$", "-3x3.png")
    $tileInputs = @($sourcePath) * 9
    & $magick montage @tileInputs -filter point -geometry "192x192+0+0" `
        -tile 3x3 -background $palette.space $proofPath
    if ($LASTEXITCODE -ne 0) {
        throw "Could not build repeat proof for $tileName"
    }
    $tileProofs.Add($proofPath)
}

$repeatSheet = Join-Path $evidenceRoot "approved-repeat-proof.png"
& $magick montage @($tileProofs) -geometry "+16+16" -tile 3x1 `
    -background $palette.space $repeatSheet
if ($LASTEXITCODE -ne 0) {
    throw "Could not build the combined repeat proof."
}

Write-Output "Approved visual recovery core authored and validated: $outputRoot"
Write-Output "Evidence: $contactSheet"
Write-Output "Evidence: $repeatSheet"
