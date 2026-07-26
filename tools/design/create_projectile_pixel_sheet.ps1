param(
    [string]$OutputDirectory = "docs/design/pixel-art-asset-pipeline/examples/projectile-system"
)

$ErrorActionPreference = "Stop"

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$destination = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutputDirectory))
$magick = Get-Command magick -ErrorAction Stop
$spriteSize = 16
$columns = 6
$padding = 1
$pitch = $spriteSize + $padding * 2
$palette = [ordered]@{
    "." = $null
    "W" = "#FFF6DC"
    "Y" = "#D79A17"
    "D" = "#8A5B10"
    "R" = "#C92F4E"
    "Q" = "#7B1733"
    "O" = "#E45F36"
    "G" = "#769A32"
    "B" = "#3E91B7"
    "V" = "#9B59B6"
    "M" = "#75C4B2"
    "I" = "#153B3A"
}

function New-PixelBuffer {
    $pixels = [System.Collections.Generic.List[char]]::new(
        $script:spriteSize * $script:spriteSize
    )
    for ($index = 0; $index -lt $script:spriteSize * $script:spriteSize; $index++) {
        $pixels.Add(".")
    }
    return ,$pixels
}

function Copy-PixelBuffer {
    param([System.Collections.Generic.List[char]]$Pixels)

    return ,[System.Collections.Generic.List[char]]::new($Pixels)
}

function Set-Pixel {
    param(
        [System.Collections.Generic.List[char]]$Pixels,
        [int]$X,
        [int]$Y,
        [char]$Color
    )

    if ($X -lt 0 -or $Y -lt 0 -or $X -ge $script:spriteSize -or $Y -ge $script:spriteSize) {
        return
    }
    $Pixels[$Y * $script:spriteSize + $X] = $Color
}

function Fill-Rect {
    param(
        [System.Collections.Generic.List[char]]$Pixels,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [char]$Color
    )

    for ($py = $Y; $py -lt $Y + $Height; $py++) {
        for ($px = $X; $px -lt $X + $Width; $px++) {
            Set-Pixel -Pixels $Pixels -X $px -Y $py -Color $Color
        }
    }
}

function Fill-Diamond {
    param(
        [System.Collections.Generic.List[char]]$Pixels,
        [int]$CenterX,
        [int]$CenterY,
        [int]$Radius,
        [char]$Color
    )

    for ($dy = -$Radius; $dy -le $Radius; $dy++) {
        $extent = $Radius - [Math]::Abs($dy)
        for ($dx = -$extent; $dx -le $extent; $dx++) {
            Set-Pixel -Pixels $Pixels -X ($CenterX + $dx) -Y ($CenterY + $dy) -Color $Color
        }
    }
}

function Merge-PixelBuffers {
    param([object[]]$Layers)

    $result = New-PixelBuffer
    foreach ($layer in $Layers) {
        for ($index = 0; $index -lt $layer.Count; $index++) {
            if ($layer[$index] -ne ".") {
                $result[$index] = $layer[$index]
            }
        }
    }
    return $result
}

function Add-Sprite {
    param(
        [System.Collections.Generic.List[object]]$Collection,
        [string]$Id,
        [string]$Label,
        [string]$Category,
        [System.Collections.Generic.List[char]]$Pixels
    )

    $Collection.Add([ordered]@{
        id = $Id
        label = $Label
        category = $Category
        pixels = $Pixels
    })
}

function Pixel-Runs {
    param(
        [System.Collections.Generic.List[char]]$Pixels,
        [int]$OriginX,
        [int]$OriginY,
        [int]$Scale = 1
    )

    $rects = [System.Collections.Generic.List[string]]::new()
    for ($y = 0; $y -lt $script:spriteSize; $y++) {
        $x = 0
        while ($x -lt $script:spriteSize) {
            $symbol = $Pixels[$y * $script:spriteSize + $x]
            if ($symbol -eq ".") {
                $x++
                continue
            }
            $start = $x
            $x++
            while (
                $x -lt $script:spriteSize -and
                $Pixels[$y * $script:spriteSize + $x] -eq $symbol
            ) {
                $x++
            }
            $color = $script:palette[[string]$symbol]
            $runWidth = $x - $start
            $rects.Add(
                "<rect x=`"$($OriginX + $start * $Scale)`" y=`"$($OriginY + $y * $Scale)`" width=`"$($runWidth * $Scale)`" height=`"$Scale`" fill=`"$color`"/>"
            )
        }
    }
    return $rects
}

function Opaque-Bounds {
    param([System.Collections.Generic.List[char]]$Pixels)

    $minX = $script:spriteSize
    $minY = $script:spriteSize
    $maxX = -1
    $maxY = -1
    for ($y = 0; $y -lt $script:spriteSize; $y++) {
        for ($x = 0; $x -lt $script:spriteSize; $x++) {
            if ($Pixels[$y * $script:spriteSize + $x] -eq ".") {
                continue
            }
            $minX = [Math]::Min($minX, $x)
            $minY = [Math]::Min($minY, $y)
            $maxX = [Math]::Max($maxX, $x)
            $maxY = [Math]::Max($maxY, $y)
        }
    }
    if ($maxX -lt 0) {
        return @(0, 0)
    }
    $width = $maxX - $minX + 1
    $height = $maxY - $minY + 1
    return @($width, $height)
}

$sprites = [System.Collections.Generic.List[object]]::new()

# Complete projectile heads. Direction points to the right.
$playerStandard = New-PixelBuffer
Fill-Rect $playerStandard 3 6 8 4 "Y"
Fill-Rect $playerStandard 1 7 4 2 "D"
Fill-Diamond $playerStandard 11 7 3 "W"
Fill-Rect $playerStandard 8 7 5 2 "Y"
Set-Pixel $playerStandard 14 7 "W"
Set-Pixel $playerStandard 14 8 "W"
Add-Sprite $sprites "player_standard" "STANDARD" "PROJECTILE HEADS" $playerStandard

$playerOpening = New-PixelBuffer
Fill-Diamond $playerOpening 9 7 5 "Y"
Fill-Diamond $playerOpening 10 7 3 "W"
Fill-Rect $playerOpening 1 6 8 4 "D"
Fill-Rect $playerOpening 4 7 10 2 "W"
Set-Pixel $playerOpening 15 7 "Y"
Set-Pixel $playerOpening 15 8 "Y"
Set-Pixel $playerOpening 8 2 "W"
Set-Pixel $playerOpening 8 12 "W"
Add-Sprite $sprites "player_opening_breach" "OPENING" "PROJECTILE HEADS" $playerOpening

$enemyLight = New-PixelBuffer
Fill-Diamond $enemyLight 8 7 5 "Q"
Fill-Diamond $enemyLight 8 7 3 "R"
Fill-Rect $enemyLight 7 7 3 2 "W"
Add-Sprite $sprites "enemy_light" "ENEMY LIGHT" "PROJECTILE HEADS" $enemyLight

$enemyStandard = New-PixelBuffer
Fill-Diamond $enemyStandard 8 7 6 "Q"
Fill-Diamond $enemyStandard 8 7 5 "R"
Fill-Diamond $enemyStandard 8 7 1 "W"
Add-Sprite $sprites "enemy_standard" "ENEMY STD" "PROJECTILE HEADS" $enemyStandard

$enemyHeavy = New-PixelBuffer
Fill-Rect $enemyHeavy 4 1 9 14 "Q"
Fill-Rect $enemyHeavy 1 4 15 8 "Q"
Fill-Rect $enemyHeavy 5 2 7 12 "R"
Fill-Rect $enemyHeavy 2 5 13 6 "R"
Fill-Diamond $enemyHeavy 8 7 2 "W"
Set-Pixel $enemyHeavy 1 7 "R"
Set-Pixel $enemyHeavy 15 7 "R"
Add-Sprite $sprites "enemy_heavy" "ENEMY HEAVY" "PROJECTILE HEADS" $enemyHeavy

$seeker = New-PixelBuffer
Fill-Rect $seeker 3 6 8 4 "D"
Fill-Rect $seeker 6 5 6 6 "Y"
Fill-Diamond $seeker 12 7 2 "W"
Set-Pixel $seeker 5 4 "M"
Set-Pixel $seeker 6 4 "M"
Set-Pixel $seeker 5 11 "M"
Set-Pixel $seeker 6 11 "M"
Fill-Rect $seeker 1 7 3 2 "M"
Add-Sprite $sprites "seeker_missile" "SEEKER" "PROJECTILE HEADS" $seeker

# Hostile affinity overlays. These are combined with light/standard/heavy heads.
$kinetic = New-PixelBuffer
Fill-Rect $kinetic 3 7 10 2 "W"
Set-Pixel $kinetic 11 5 "W"
Set-Pixel $kinetic 12 6 "W"
Set-Pixel $kinetic 11 10 "W"
Set-Pixel $kinetic 12 9 "W"
Add-Sprite $sprites "affinity_kinetic" "KINETIC" "ENEMY AFFINITIES" $kinetic

$thermal = New-PixelBuffer
Fill-Diamond $thermal 8 8 3 "O"
Set-Pixel $thermal 7 3 "O"
Set-Pixel $thermal 8 4 "O"
Set-Pixel $thermal 10 4 "O"
Set-Pixel $thermal 9 5 "W"
Set-Pixel $thermal 7 9 "W"
Add-Sprite $sprites "affinity_thermal" "THERMAL" "ENEMY AFFINITIES" $thermal

$toxin = New-PixelBuffer
Fill-Diamond $toxin 8 9 3 "G"
Fill-Rect $toxin 7 4 3 4 "G"
Set-Pixel $toxin 8 3 "M"
Set-Pixel $toxin 7 9 "M"
Set-Pixel $toxin 8 8 "W"
Add-Sprite $sprites "affinity_toxin" "TOXIN" "ENEMY AFFINITIES" $toxin

$cryo = New-PixelBuffer
Fill-Rect $cryo 7 3 2 10 "B"
Fill-Rect $cryo 3 7 10 2 "B"
Set-Pixel $cryo 4 4 "B"
Set-Pixel $cryo 11 4 "B"
Set-Pixel $cryo 4 11 "B"
Set-Pixel $cryo 11 11 "B"
Fill-Diamond $cryo 8 8 1 "W"
Add-Sprite $sprites "affinity_cryo" "CRYO" "ENEMY AFFINITIES" $cryo

$arc = New-PixelBuffer
Fill-Rect $arc 8 2 3 4 "V"
Fill-Rect $arc 6 5 4 3 "V"
Fill-Rect $arc 5 7 4 3 "W"
Fill-Rect $arc 3 9 4 4 "V"
Set-Pixel $arc 11 3 "W"
Set-Pixel $arc 3 13 "W"
Add-Sprite $sprites "affinity_arc" "ARC" "ENEMY AFFINITIES" $arc

$hybrid = New-PixelBuffer
Fill-Diamond $hybrid 8 7 4 "R"
Fill-Rect $hybrid 7 2 2 4 "O"
Fill-Rect $hybrid 10 6 4 2 "G"
Fill-Rect $hybrid 7 9 2 4 "B"
Fill-Rect $hybrid 2 6 4 2 "V"
Fill-Diamond $hybrid 8 7 1 "W"
Add-Sprite $sprites "affinity_hybrid" "HYBRID" "ENEMY AFFINITIES" $hybrid

# Player modifier overlays. They keep the player projectile's ownership color.
$pierce = New-PixelBuffer
Fill-Rect $pierce 2 7 12 2 "W"
Set-Pixel $pierce 12 5 "Y"
Set-Pixel $pierce 13 6 "Y"
Set-Pixel $pierce 12 10 "Y"
Set-Pixel $pierce 13 9 "Y"
Add-Sprite $sprites "modifier_pierce" "PIERCE" "PLAYER MODIFIERS" $pierce

$ricochet = New-PixelBuffer
Set-Pixel $ricochet 3 5 "M"
Set-Pixel $ricochet 4 6 "M"
Set-Pixel $ricochet 5 7 "M"
Set-Pixel $ricochet 4 8 "M"
Set-Pixel $ricochet 3 9 "M"
Set-Pixel $ricochet 10 4 "W"
Set-Pixel $ricochet 11 5 "W"
Set-Pixel $ricochet 12 6 "W"
Set-Pixel $ricochet 11 7 "W"
Set-Pixel $ricochet 10 8 "W"
Add-Sprite $sprites "modifier_ricochet" "RICOCHET" "PLAYER MODIFIERS" $ricochet

$explosive = New-PixelBuffer
Set-Pixel $explosive 6 2 "O"
Set-Pixel $explosive 9 2 "O"
Set-Pixel $explosive 3 5 "O"
Set-Pixel $explosive 12 5 "O"
Set-Pixel $explosive 2 8 "O"
Set-Pixel $explosive 13 8 "O"
Set-Pixel $explosive 4 11 "O"
Set-Pixel $explosive 11 11 "O"
Fill-Diamond $explosive 8 7 1 "W"
Add-Sprite $sprites "modifier_explosive" "EXPLOSIVE" "PLAYER MODIFIERS" $explosive

$homing = New-PixelBuffer
Fill-Rect $homing 2 4 2 8 "M"
Fill-Rect $homing 3 3 4 2 "M"
Fill-Rect $homing 3 11 4 2 "M"
Set-Pixel $homing 11 5 "W"
Set-Pixel $homing 12 6 "W"
Set-Pixel $homing 13 7 "W"
Set-Pixel $homing 12 8 "W"
Set-Pixel $homing 11 9 "W"
Add-Sprite $sprites "modifier_homing" "HOMING" "PLAYER MODIFIERS" $homing

$wallPiercing = New-PixelBuffer
Fill-Rect $wallPiercing 4 5 8 6 "V"
Fill-Rect $wallPiercing 5 6 8 4 "W"
Set-Pixel $wallPiercing 13 6 "V"
Set-Pixel $wallPiercing 14 7 "V"
Set-Pixel $wallPiercing 13 9 "V"
Set-Pixel $wallPiercing 2 5 "V"
Set-Pixel $wallPiercing 2 10 "V"
Add-Sprite $sprites "modifier_wall_piercing" "WALL PIERCE" "PLAYER MODIFIERS" $wallPiercing

$reflected = New-PixelBuffer
Fill-Rect $reflected 4 7 9 2 "Y"
Set-Pixel $reflected 3 6 "Y"
Set-Pixel $reflected 2 5 "W"
Set-Pixel $reflected 3 9 "Y"
Set-Pixel $reflected 2 10 "W"
Set-Pixel $reflected 11 5 "M"
Set-Pixel $reflected 12 6 "M"
Set-Pixel $reflected 11 10 "M"
Set-Pixel $reflected 12 9 "M"
Add-Sprite $sprites "modifier_reflected" "REFLECTED" "PLAYER MODIFIERS" $reflected

# Flight and impact parts.
$playerTrail = New-PixelBuffer
Fill-Rect $playerTrail 1 7 8 2 "D"
Fill-Rect $playerTrail 4 6 7 4 "Y"
Fill-Rect $playerTrail 8 7 4 2 "W"
Set-Pixel $playerTrail 2 6 "Y"
Set-Pixel $playerTrail 2 9 "Y"
Add-Sprite $sprites "trail_player" "PLAYER TRAIL" "FLIGHT / IMPACT" $playerTrail

$hostileTrail = New-PixelBuffer
Fill-Rect $hostileTrail 1 7 8 2 "Q"
Fill-Rect $hostileTrail 4 6 7 4 "R"
Fill-Rect $hostileTrail 8 7 4 2 "W"
Set-Pixel $hostileTrail 2 6 "R"
Set-Pixel $hostileTrail 2 9 "R"
Add-Sprite $sprites "trail_hostile" "HOSTILE TRAIL" "FLIGHT / IMPACT" $hostileTrail

$seekerExhaust = New-PixelBuffer
Fill-Rect $seekerExhaust 2 7 9 2 "M"
Fill-Rect $seekerExhaust 5 6 6 4 "Y"
Fill-Rect $seekerExhaust 9 7 4 2 "W"
Set-Pixel $seekerExhaust 1 6 "B"
Set-Pixel $seekerExhaust 1 9 "B"
Add-Sprite $sprites "trail_seeker_exhaust" "SEEKER EXHAUST" "FLIGHT / IMPACT" $seekerExhaust

$wallImpact = New-PixelBuffer
Fill-Diamond $wallImpact 8 7 2 "W"
Set-Pixel $wallImpact 8 1 "M"
Set-Pixel $wallImpact 8 13 "M"
Set-Pixel $wallImpact 2 7 "M"
Set-Pixel $wallImpact 14 7 "M"
Set-Pixel $wallImpact 4 3 "I"
Set-Pixel $wallImpact 12 3 "I"
Set-Pixel $wallImpact 4 11 "I"
Set-Pixel $wallImpact 12 11 "I"
Add-Sprite $sprites "impact_wall" "WALL IMPACT" "FLIGHT / IMPACT" $wallImpact

$hullImpact = New-PixelBuffer
Fill-Diamond $hullImpact 8 7 3 "R"
Fill-Diamond $hullImpact 8 7 1 "W"
Set-Pixel $hullImpact 8 1 "Y"
Set-Pixel $hullImpact 8 13 "Y"
Set-Pixel $hullImpact 2 7 "Y"
Set-Pixel $hullImpact 14 7 "Y"
Set-Pixel $hullImpact 3 3 "R"
Set-Pixel $hullImpact 13 11 "R"
Add-Sprite $sprites "impact_hull" "HULL IMPACT" "FLIGHT / IMPACT" $hullImpact

$breachInterrupt = New-PixelBuffer
Fill-Diamond $breachInterrupt 8 7 4 "Y"
Fill-Diamond $breachInterrupt 8 7 2 "I"
Fill-Diamond $breachInterrupt 8 7 1 "W"
Set-Pixel $breachInterrupt 2 2 "M"
Set-Pixel $breachInterrupt 13 2 "M"
Set-Pixel $breachInterrupt 2 12 "M"
Set-Pixel $breachInterrupt 13 12 "M"
Fill-Rect $breachInterrupt 7 0 2 3 "W"
Add-Sprite $sprites "impact_breach_interrupt" "INTERRUPT" "FLIGHT / IMPACT" $breachInterrupt

if ($sprites.Count -ne 24) {
    throw "Expected 24 projectile parts; got $($sprites.Count)."
}

$minimumThreatExtents = [ordered]@{
    enemy_light = 10
    enemy_standard = 12
    enemy_heavy = 14
}
foreach ($entry in $minimumThreatExtents.GetEnumerator()) {
    $sprite = $sprites | Where-Object {$_.id -eq $entry.Key} | Select-Object -First 1
    $bounds = Opaque-Bounds $sprite.pixels
    if ($bounds[0] -lt $entry.Value -or $bounds[1] -lt $entry.Value) {
        throw "$($entry.Key) visual extent must cover at least $($entry.Value)x$($entry.Value) logical pixels; got $($bounds[0])x$($bounds[1])."
    }
}

if (-not [System.IO.Directory]::Exists($destination)) {
    [System.IO.Directory]::CreateDirectory($destination) | Out-Null
}

$rows = [int][Math]::Ceiling($sprites.Count / [double]$columns)
$atlasWidth = $columns * $pitch
$atlasHeight = $rows * $pitch
$atlasSvg = [System.Collections.Generic.List[string]]::new()
$atlasSvg.Add("<svg xmlns=`"http://www.w3.org/2000/svg`" width=`"$atlasWidth`" height=`"$atlasHeight`" viewBox=`"0 0 $atlasWidth $atlasHeight`" shape-rendering=`"crispEdges`">")
$atlasSvg.Add("  <metadata>Cardborne projectile parts; 16x16 regions; one transparent pixel gutter.</metadata>")
$metadataSprites = [System.Collections.Generic.List[object]]::new()
for ($index = 0; $index -lt $sprites.Count; $index++) {
    $sprite = $sprites[$index]
    $column = $index % $columns
    $row = [int][Math]::Floor($index / [double]$columns)
    $originX = $column * $pitch + $padding
    $originY = $row * $pitch + $padding
    foreach ($rect in (Pixel-Runs $sprite.pixels $originX $originY 1)) {
        $atlasSvg.Add("  $rect")
    }
    $metadataSprites.Add([ordered]@{
        id = [string]$sprite.id
        category = [string]$sprite.category
        region = @($originX, $originY, $spriteSize, $spriteSize)
    })
}
$atlasSvg.Add("</svg>")

$atlasSvgPath = Join-Path $destination "projectile-parts-atlas.svg"
$atlasPngPath = Join-Path $destination "projectile-parts-atlas.png"
[System.IO.File]::WriteAllText(
    $atlasSvgPath,
    ($atlasSvg -join [Environment]::NewLine) + [Environment]::NewLine,
    [System.Text.UTF8Encoding]::new($false)
)
& $magick.Source -background none $atlasSvgPath -depth 8 -strip $atlasPngPath
if ($LASTEXITCODE -ne 0) {
    throw "Failed to rasterize the projectile parts atlas."
}
$atlasGeometry = (& $magick.Source identify -format "%w %h" $atlasPngPath).Trim()
if ($atlasGeometry -ne "$atlasWidth $atlasHeight") {
    throw "Projectile atlas must be ${atlasWidth}x${atlasHeight}; got $atlasGeometry."
}

$metadata = [ordered]@{
    schema_version = 1
    native_sprite_size = @($spriteSize, $spriteSize)
    atlas_size = @($atlasWidth, $atlasHeight)
    gutter = $padding
    columns = $columns
    sprites = @($metadataSprites)
    composition_rule = "trail -> complete head -> affinity or modifier overlay"
}
[System.IO.File]::WriteAllText(
    (Join-Path $destination "projectile-parts-atlas.json"),
    ($metadata | ConvertTo-Json -Depth 6),
    [System.Text.UTF8Encoding]::new($false)
)

# Human-scale preview. The fifth row contains compositions, not extra atlas slots.
$compositions = [System.Collections.Generic.List[object]]::new()
Add-Sprite $compositions "example_player" "PLAYER BASIC" "ASSEMBLED EXAMPLES" (
    Merge-PixelBuffers @($playerTrail, $playerStandard)
)
Add-Sprite $compositions "example_opening" "OPENING + PIERCE" "ASSEMBLED EXAMPLES" (
    Merge-PixelBuffers @($playerTrail, $playerOpening, $pierce)
)
Add-Sprite $compositions "example_kinetic" "LIGHT KINETIC" "ASSEMBLED EXAMPLES" (
    Merge-PixelBuffers @($hostileTrail, $enemyLight, $kinetic)
)
Add-Sprite $compositions "example_toxin" "STANDARD TOXIN" "ASSEMBLED EXAMPLES" (
    Merge-PixelBuffers @($hostileTrail, $enemyStandard, $toxin)
)
Add-Sprite $compositions "example_thermal" "HEAVY THERMAL" "ASSEMBLED EXAMPLES" (
    Merge-PixelBuffers @($hostileTrail, $enemyHeavy, $thermal)
)
Add-Sprite $compositions "example_hybrid" "HEAVY HYBRID" "ASSEMBLED EXAMPLES" (
    Merge-PixelBuffers @($hostileTrail, $enemyHeavy, $hybrid)
)

$previewWidth = 1200
$previewHeight = 960
$cardWidth = 174
$cardHeight = 128
$cardGap = 12
$left = 48
$top = 116
$rowPitch = 164
$previewScale = 5
$preview = [System.Collections.Generic.List[string]]::new()
$preview.Add("<svg xmlns=`"http://www.w3.org/2000/svg`" width=`"$previewWidth`" height=`"$previewHeight`" viewBox=`"0 0 $previewWidth $previewHeight`" shape-rendering=`"crispEdges`">")
$preview.Add("  <rect width=`"$previewWidth`" height=`"$previewHeight`" fill=`"#042B7B`"/>")
$preview.Add("  <text x=`"48`" y=`"48`" fill=`"#FFF6DC`" font-family=`"Arial, sans-serif`" font-size=`"26`" font-weight=`"700`">CARDBORNE PROJECTILE PIXEL SYSTEM</text>")
$preview.Add("  <text x=`"48`" y=`"76`" fill=`"#A8DACB`" font-family=`"Arial, sans-serif`" font-size=`"15`">16x16 masters · flat palette · parts atlas + runtime composition · preview at 5x</text>")

$previewRows = @(
    @($sprites | Where-Object {$_.category -eq "PROJECTILE HEADS"}),
    @($sprites | Where-Object {$_.category -eq "ENEMY AFFINITIES"}),
    @($sprites | Where-Object {$_.category -eq "PLAYER MODIFIERS"}),
    @($sprites | Where-Object {$_.category -eq "FLIGHT / IMPACT"}),
    @($compositions)
)
for ($rowIndex = 0; $rowIndex -lt $previewRows.Count; $rowIndex++) {
    $rowSprites = $previewRows[$rowIndex]
    $rowY = $top + $rowIndex * $rowPitch
    $category = [string]$rowSprites[0].category
    $preview.Add("  <text x=`"$left`" y=`"$($rowY - 12)`" fill=`"#75C4B2`" font-family=`"Arial, sans-serif`" font-size=`"14`" font-weight=`"700`">$category</text>")
    for ($column = 0; $column -lt $rowSprites.Count; $column++) {
        $sprite = $rowSprites[$column]
        $cardX = $left + $column * ($cardWidth + $cardGap)
        $preview.Add("  <rect x=`"$cardX`" y=`"$rowY`" width=`"$cardWidth`" height=`"$cardHeight`" fill=`"#0739A6`"/>")
        $preview.Add("  <rect x=`"$($cardX + 1)`" y=`"$($rowY + 1)`" width=`"$($cardWidth - 2)`" height=`"$($cardHeight - 2)`" fill=`"none`" stroke=`"#0755C7`" stroke-width=`"2`"/>")
        $spriteX = $cardX + [int](($cardWidth - $spriteSize * $previewScale) / 2)
        $spriteY = $rowY + 13
        foreach ($rect in (Pixel-Runs $sprite.pixels $spriteX $spriteY $previewScale)) {
            $preview.Add("  $rect")
        }
        $preview.Add("  <text x=`"$($cardX + $cardWidth / 2)`" y=`"$($rowY + 114)`" text-anchor=`"middle`" fill=`"#FFF6DC`" font-family=`"Arial, sans-serif`" font-size=`"12`" font-weight=`"700`">$($sprite.label)</text>")
    }
}
$preview.Add("</svg>")

$previewSvgPath = Join-Path $destination "projectile-system-preview.svg"
$previewPngPath = Join-Path $destination "projectile-system-preview.png"
[System.IO.File]::WriteAllText(
    $previewSvgPath,
    ($preview -join [Environment]::NewLine) + [Environment]::NewLine,
    [System.Text.UTF8Encoding]::new($false)
)
& $magick.Source -background none $previewSvgPath -depth 8 -strip $previewPngPath
if ($LASTEXITCODE -ne 0) {
    throw "Failed to rasterize the projectile system preview."
}
$previewGeometry = (& $magick.Source identify -format "%w %h" $previewPngPath).Trim()
if ($previewGeometry -ne "$previewWidth $previewHeight") {
    throw "Projectile preview must be ${previewWidth}x${previewHeight}; got $previewGeometry."
}

Write-Output "Created projectile parts atlas: $atlasPngPath"
Write-Output "Created projectile system preview: $previewPngPath"
