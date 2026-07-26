param(
    [string]$OutputDirectory = "docs/design/pixel-art-asset-pipeline/examples/projectile-system",
    [switch]$RunNegativeValidation
)

$ErrorActionPreference = "Stop"

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$destination = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutputDirectory))
$magick = Get-Command magick -ErrorAction Stop
$spriteSize = 32
$pivot = 16
$columns = 10
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
    "N" = "#081F2B"
}
$directions = @(
    [ordered]@{ id = "e"; angle = 0 },
    [ordered]@{ id = "se"; angle = 45 },
    [ordered]@{ id = "s"; angle = 90 },
    [ordered]@{ id = "sw"; angle = 135 },
    [ordered]@{ id = "w"; angle = 180 },
    [ordered]@{ id = "nw"; angle = 225 },
    [ordered]@{ id = "n"; angle = 270 },
    [ordered]@{ id = "ne"; angle = 315 }
)

function New-PixelBuffer {
    [char[]]$pixels = [char[]]::new($script:spriteSize * $script:spriteSize)
    [Array]::Fill($pixels, [char]".")
    return ,$pixels
}

function Copy-PixelBuffer {
    param([char[]]$Pixels)

    return ,([char[]]$Pixels.Clone())
}

function Set-Pixel {
    param(
        [char[]]$Pixels,
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
        [char[]]$Pixels,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [char]$Color
    )

    for ($py = $Y; $py -lt $Y + $Height; $py++) {
        for ($px = $X; $px -lt $X + $Width; $px++) {
            Set-Pixel $Pixels $px $py $Color
        }
    }
}

function Fill-Diamond {
    param(
        [char[]]$Pixels,
        [int]$CenterX,
        [int]$CenterY,
        [int]$Radius,
        [char]$Color
    )

    for ($dy = -$Radius; $dy -le $Radius; $dy++) {
        $extent = $Radius - [Math]::Abs($dy)
        for ($dx = -$extent; $dx -le $extent; $dx++) {
            Set-Pixel $Pixels ($CenterX + $dx) ($CenterY + $dy) $Color
        }
    }
}

function Fill-Disc {
    param(
        [char[]]$Pixels,
        [int]$CenterX,
        [int]$CenterY,
        [int]$Radius,
        [char]$Color
    )

    $limit = ($Radius + 0.2) * ($Radius + 0.2)
    for ($dy = -$Radius; $dy -le $Radius; $dy++) {
        for ($dx = -$Radius; $dx -le $Radius; $dx++) {
            if ($dx * $dx + $dy * $dy -le $limit) {
                Set-Pixel $Pixels ($CenterX + $dx) ($CenterY + $dy) $Color
            }
        }
    }
}

function Draw-Line {
    param(
        [char[]]$Pixels,
        [int]$X0,
        [int]$Y0,
        [int]$X1,
        [int]$Y1,
        [char]$Color
    )

    $dx = [Math]::Abs($X1 - $X0)
    $sx = if ($X0 -lt $X1) { 1 } else { -1 }
    $dy = -[Math]::Abs($Y1 - $Y0)
    $sy = if ($Y0 -lt $Y1) { 1 } else { -1 }
    $error = $dx + $dy
    while ($true) {
        Set-Pixel $Pixels $X0 $Y0 $Color
        if ($X0 -eq $X1 -and $Y0 -eq $Y1) {
            break
        }
        $doubleError = 2 * $error
        if ($doubleError -ge $dy) {
            $error += $dy
            $X0 += $sx
        }
        if ($doubleError -le $dx) {
            $error += $dx
            $Y0 += $sy
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
    return ,$result
}

function Rotate-Point {
    param(
        [int[]]$Point,
        [int]$Angle
    )

    $radians = $Angle * [Math]::PI / 180.0
    $x = $Point[0] - ($script:pivot - 0.5)
    $y = $Point[1] - ($script:pivot - 0.5)
    $rotatedX = $x * [Math]::Cos($radians) - $y * [Math]::Sin($radians)
    $rotatedY = $x * [Math]::Sin($radians) + $y * [Math]::Cos($radians)
    return @(
        [int][Math]::Round($rotatedX + ($script:pivot - 0.5)),
        [int][Math]::Round($rotatedY + ($script:pivot - 0.5))
    )
}

function Rotate-PixelBuffer {
    param(
        [char[]]$Pixels,
        [int]$Angle
    )

    if ($Angle % 360 -eq 0) {
        return Copy-PixelBuffer $Pixels
    }

    $result = New-PixelBuffer
    $radians = -$Angle * [Math]::PI / 180.0
    $center = $script:pivot - 0.5
    for ($targetY = 0; $targetY -lt $script:spriteSize; $targetY++) {
        for ($targetX = 0; $targetX -lt $script:spriteSize; $targetX++) {
            $x = $targetX - $center
            $y = $targetY - $center
            $sourceX = [int][Math]::Round($x * [Math]::Cos($radians) - $y * [Math]::Sin($radians) + $center)
            $sourceY = [int][Math]::Round($x * [Math]::Sin($radians) + $y * [Math]::Cos($radians) + $center)
            if ($sourceX -lt 0 -or $sourceY -lt 0 -or $sourceX -ge $script:spriteSize -or $sourceY -ge $script:spriteSize) {
                continue
            }
            $symbol = $Pixels[$sourceY * $script:spriteSize + $sourceX]
            if ($symbol -ne ".") {
                $result[$targetY * $script:spriteSize + $targetX] = $symbol
            }
        }
    }
    return ,$result
}

function Pixel-Runs {
    param(
        [char[]]$Pixels,
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
            while ($x -lt $script:spriteSize -and $Pixels[$y * $script:spriteSize + $x] -eq $symbol) {
                $x++
            }
            $color = $script:palette[[string]$symbol]
            $rects.Add(
                "<rect x=`"$($OriginX + $start * $Scale)`" y=`"$($OriginY + $y * $Scale)`" width=`"$(($x - $start) * $Scale)`" height=`"$Scale`" fill=`"$color`"/>"
            )
        }
    }
    return $rects
}

function Opaque-Bounds {
    param([char[]]$Pixels)

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
        return @(0, 0, 0, 0)
    }
    return @($minX, $minY, ($maxX - $minX + 1), ($maxY - $minY + 1))
}

function New-FrameRecord {
    param(
        [string]$Clip,
        [int]$Frame,
        [char[]]$Pixels,
        [int]$Duration,
        [string]$State,
        [AllowNull()][string]$Direction,
        [AllowNull()][int[]]$LeadingAnchor,
        [AllowNull()][int[]]$TrailAnchor
    )

    return [ordered]@{
        clip = $Clip
        frame = $Frame
        pixels = $Pixels
        duration_ms = $Duration
        state = $State
        direction = $Direction
        pivot = @($script:pivot, $script:pivot)
        leading_anchor = $LeadingAnchor
        trail_anchor = $TrailAnchor
    }
}

function Assert-FrameAnchors {
    param([System.Collections.IDictionary]$Frame)

    foreach ($anchorName in @("leading_anchor", "trail_anchor")) {
        $anchor = $Frame[$anchorName]
        if ($null -eq $anchor) {
            continue
        }
        if ($anchor.Count -ne 2 -or $anchor[0] -lt 0 -or $anchor[1] -lt 0 -or $anchor[0] -ge $script:spriteSize -or $anchor[1] -ge $script:spriteSize) {
            throw "Invalid $anchorName in $($Frame.clip) frame $($Frame.frame)."
        }
    }
    if ($null -ne $Frame.leading_anchor -and $null -ne $Frame.trail_anchor) {
        $leadingVector = @(
            ($Frame.leading_anchor[0] - $script:pivot),
            ($Frame.leading_anchor[1] - $script:pivot)
        )
        $trailVector = @(
            ($Frame.trail_anchor[0] - $script:pivot),
            ($Frame.trail_anchor[1] - $script:pivot)
        )
        $dot = $leadingVector[0] * $trailVector[0] + $leadingVector[1] * $trailVector[1]
        if ($dot -ge 0) {
            throw "Leading and trail anchors must be on opposite sides of the pivot in $($Frame.clip)."
        }
    }
}

function Assert-MinimumExtent {
    param(
        [char[]]$Pixels,
        [int]$Minimum,
        [string]$Label
    )

    $bounds = Opaque-Bounds $Pixels
    if ($bounds[2] -lt $Minimum -or $bounds[3] -lt $Minimum) {
        throw "$Label must cover at least ${Minimum}x${Minimum}; got $($bounds[2])x$($bounds[3])."
    }
}

function Add-DirectionalClip {
    param(
        [System.Collections.Generic.List[object]]$Collection,
        [string]$Clip,
        [object[]]$SourceFrames,
        [int]$Duration,
        [string]$State,
        [int[]]$LeadingAnchor,
        [int[]]$TrailAnchor
    )

    foreach ($direction in $script:directions) {
        for ($frameIndex = 0; $frameIndex -lt $SourceFrames.Count; $frameIndex++) {
            $rotatedPixels = Rotate-PixelBuffer $SourceFrames[$frameIndex] $direction.angle
            $rotatedLeading = Rotate-Point $LeadingAnchor $direction.angle
            $rotatedTrail = Rotate-Point $TrailAnchor $direction.angle
            $Collection.Add((New-FrameRecord `
                -Clip $Clip `
                -Frame $frameIndex `
                -Pixels $rotatedPixels `
                -Duration $Duration `
                -State $State `
                -Direction $direction.id `
                -LeadingAnchor $rotatedLeading `
                -TrailAnchor $rotatedTrail))
        }
    }
}

function Add-StaticClip {
    param(
        [System.Collections.Generic.List[object]]$Collection,
        [string]$Clip,
        [object[]]$SourceFrames,
        [int]$Duration,
        [string]$State
    )

    for ($frameIndex = 0; $frameIndex -lt $SourceFrames.Count; $frameIndex++) {
        $Collection.Add((New-FrameRecord `
            -Clip $Clip `
            -Frame $frameIndex `
            -Pixels $SourceFrames[$frameIndex] `
            -Duration $Duration `
            -State $State `
            -Direction $null `
            -LeadingAnchor $null `
            -TrailAnchor $null))
    }
}

function New-PlayerBasicFrame {
    param([int]$Phase)

    $pixels = New-PixelBuffer
    Fill-Rect $pixels (3 + $Phase) 15 (6 - $Phase) 2 "D"
    Fill-Rect $pixels (6 + $Phase) 14 7 4 "Y"
    Fill-Rect $pixels 11 13 11 6 "Y"
    Fill-Rect $pixels 13 14 10 4 "W"
    Fill-Rect $pixels 22 15 4 2 "W"
    Set-Pixel $pixels 26 15 "Y"
    Set-Pixel $pixels 26 16 "Y"
    Set-Pixel $pixels 27 15 "W"
    Set-Pixel $pixels 27 16 "W"
    if ($Phase -eq 0) {
        Set-Pixel $pixels 9 13 "W"
        Set-Pixel $pixels 9 18 "W"
    }
    else {
        Set-Pixel $pixels 7 13 "D"
        Set-Pixel $pixels 7 18 "D"
    }
    return ,$pixels
}

function New-OpeningFrame {
    param([int]$Phase)

    $pixels = New-PixelBuffer
    Fill-Rect $pixels (2 + $Phase) 15 (7 - $Phase) 2 "D"
    Fill-Rect $pixels 7 13 5 6 "Y"
    Fill-Rect $pixels 10 11 3 10 "W"
    Fill-Rect $pixels 12 13 12 6 "Y"
    Fill-Rect $pixels 13 14 12 4 "W"
    Fill-Rect $pixels 24 15 4 2 "W"
    Set-Pixel $pixels 28 15 "Y"
    Set-Pixel $pixels 28 16 "Y"
    Set-Pixel $pixels 29 15 "W"
    Set-Pixel $pixels 29 16 "W"
    if ($Phase -eq 0) {
        Fill-Rect $pixels 8 10 2 2 "Y"
        Fill-Rect $pixels 8 20 2 2 "Y"
    }
    else {
        Fill-Rect $pixels 5 12 3 2 "D"
        Fill-Rect $pixels 5 18 3 2 "D"
    }
    return ,$pixels
}

function New-SeekerFrame {
    param([int]$Phase)

    $pixels = New-PixelBuffer
    $exhaustStart = if ($Phase -eq 0) { 1 } else { 3 }
    Fill-Rect $pixels $exhaustStart 15 (8 - $Phase) 2 "M"
    Fill-Rect $pixels (4 + $Phase) 14 6 4 "Y"
    Fill-Rect $pixels 8 12 14 8 "I"
    Fill-Rect $pixels 10 13 13 6 "M"
    Fill-Rect $pixels 13 14 10 4 "W"
    Set-Pixel $pixels 23 13 "M"
    Set-Pixel $pixels 24 14 "M"
    Set-Pixel $pixels 25 15 "W"
    Set-Pixel $pixels 25 16 "W"
    Set-Pixel $pixels 24 17 "M"
    Set-Pixel $pixels 23 18 "M"
    Fill-Rect $pixels 10 9 4 4 "I"
    Fill-Rect $pixels 10 19 4 4 "I"
    Set-Pixel $pixels 9 10 "M"
    Set-Pixel $pixels 9 21 "M"
    if ($Phase -eq 0) {
        Set-Pixel $pixels 2 13 "B"
        Set-Pixel $pixels 2 18 "B"
    }
    else {
        Set-Pixel $pixels 4 12 "B"
        Set-Pixel $pixels 4 19 "B"
    }
    return ,$pixels
}

function New-HostileFrame {
    param(
        [ValidateSet("light", "standard", "heavy")]
        [string]$Tier,
        [int]$Phase
    )

    $pixels = New-PixelBuffer
    switch ($Tier) {
        "light" {
            Fill-Disc $pixels 15 15 5 "Q"
            Fill-Disc $pixels 15 15 4 "R"
            Fill-Disc $pixels 14 14 1 "W"
            if ($Phase -eq 1) {
                Set-Pixel $pixels 19 14 "W"
                Set-Pixel $pixels 19 15 "W"
            }
        }
        "standard" {
            Fill-Disc $pixels 15 15 6 "Q"
            Fill-Disc $pixels 15 15 5 "R"
            Fill-Diamond $pixels 15 15 2 "W"
            if ($Phase -eq 1) {
                Set-Pixel $pixels 15 9 "R"
                Set-Pixel $pixels 15 21 "R"
                Set-Pixel $pixels 9 15 "R"
                Set-Pixel $pixels 21 15 "R"
            }
        }
        "heavy" {
            Fill-Disc $pixels 15 15 7 "Q"
            Fill-Disc $pixels 15 15 6 "R"
            Fill-Diamond $pixels 15 15 (2 + ($Phase % 2)) "W"
            if ($Phase -eq 1) {
                Fill-Rect $pixels 7 14 3 3 "Q"
                Fill-Rect $pixels 21 14 3 3 "Q"
            }
            if ($Phase -eq 2) {
                Fill-Rect $pixels 14 7 3 3 "O"
                Fill-Rect $pixels 14 21 3 3 "O"
            }
        }
    }
    return ,$pixels
}

function New-AffinityOverlay {
    param(
        [ValidateSet("thermal", "toxin", "cryo", "arc", "hybrid")]
        [string]$Affinity,
        [int]$Phase
    )

    $pixels = New-PixelBuffer
    switch ($Affinity) {
        "thermal" {
            $offset = if ($Phase -eq 0) { 0 } else { 2 }
            Set-Pixel $pixels (7 + $offset) 14 "O"
            Set-Pixel $pixels (5 + $offset) 15 "O"
            Set-Pixel $pixels (7 + $offset) 16 "Y"
            Set-Pixel $pixels 18 10 "O"
            Set-Pixel $pixels 19 11 "O"
            Set-Pixel $pixels 20 12 "Y"
        }
        "toxin" {
            $offset = if ($Phase -eq 0) { 0 } else { 1 }
            Fill-Rect $pixels (8 - $offset) 17 3 2 "G"
            Set-Pixel $pixels (6 - $offset) 19 "G"
            Set-Pixel $pixels 12 21 "M"
            Set-Pixel $pixels 20 18 "G"
            Set-Pixel $pixels 19 20 "G"
        }
        "cryo" {
            $offset = if ($Phase -eq 0) { 0 } else { 1 }
            Draw-Line $pixels (8 + $offset) 9 (11 + $offset) 12 "B"
            Draw-Line $pixels 20 (8 + $offset) 18 (11 + $offset) "M"
            Draw-Line $pixels 21 19 19 21 "B"
            Set-Pixel $pixels 8 20 "W"
        }
        "arc" {
            if ($Phase -eq 0) {
                Draw-Line $pixels 7 13 10 11 "V"
                Draw-Line $pixels 10 11 12 13 "W"
                Draw-Line $pixels 19 18 22 16 "V"
            }
            else {
                Draw-Line $pixels 7 17 10 19 "V"
                Draw-Line $pixels 10 19 12 17 "W"
                Draw-Line $pixels 19 12 22 14 "V"
            }
        }
        "hybrid" {
            if ($Phase -eq 0) {
                Fill-Rect $pixels 10 8 4 2 "O"
                Fill-Rect $pixels 21 13 2 4 "G"
                Fill-Rect $pixels 16 21 4 2 "B"
                Fill-Rect $pixels 8 17 2 4 "V"
            }
            else {
                Fill-Rect $pixels 16 8 4 2 "G"
                Fill-Rect $pixels 21 17 2 4 "B"
                Fill-Rect $pixels 10 21 4 2 "V"
                Fill-Rect $pixels 8 11 2 4 "O"
            }
        }
    }
    return ,$pixels
}

function New-ImpactFrame {
    param(
        [ValidateSet("wall", "enemy", "player_hull", "barrier", "breach_interrupt")]
        [string]$Impact,
        [int]$Phase
    )

    $pixels = New-PixelBuffer
    $primary = switch ($Impact) {
        "wall" { "M" }
        "enemy" { "Y" }
        "player_hull" { "R" }
        "barrier" { "B" }
        "breach_interrupt" { "V" }
    }
    $secondary = switch ($Impact) {
        "wall" { "I" }
        "enemy" { "W" }
        "player_hull" { "O" }
        "barrier" { "W" }
        "breach_interrupt" { "W" }
    }

    switch ($Phase) {
        0 {
            Fill-Diamond $pixels 15 15 2 $primary
            Fill-Diamond $pixels 15 15 1 $secondary
        }
        1 {
            Fill-Disc $pixels 15 15 5 $primary
            Fill-Disc $pixels 15 15 2 $secondary
            Set-Pixel $pixels 15 8 $secondary
            Set-Pixel $pixels 22 15 $secondary
            Set-Pixel $pixels 15 22 $secondary
            Set-Pixel $pixels 8 15 $secondary
        }
        2 {
            Draw-Line $pixels 15 10 15 5 $primary
            Draw-Line $pixels 20 15 25 15 $primary
            Draw-Line $pixels 15 20 15 25 $primary
            Draw-Line $pixels 10 15 5 15 $primary
            Draw-Line $pixels 11 11 7 7 $secondary
            Draw-Line $pixels 19 11 23 7 $secondary
            Draw-Line $pixels 19 19 23 23 $secondary
            Draw-Line $pixels 11 19 7 23 $secondary
        }
        3 {
            Set-Pixel $pixels 15 4 $primary
            Set-Pixel $pixels 26 15 $primary
            Set-Pixel $pixels 15 26 $primary
            Set-Pixel $pixels 4 15 $primary
            Set-Pixel $pixels 7 7 $secondary
            Set-Pixel $pixels 23 7 $secondary
            Set-Pixel $pixels 23 23 $secondary
            Set-Pixel $pixels 7 23 $secondary
        }
    }

    if ($Impact -eq "breach_interrupt" -and $Phase -eq 1) {
        Draw-Line $pixels 9 15 21 15 "W"
        Draw-Line $pixels 15 9 15 21 "W"
    }
    return ,$pixels
}

$frames = [System.Collections.Generic.List[object]]::new()
Add-DirectionalClip `
    -Collection $frames `
    -Clip "player_basic_flight" `
    -SourceFrames @((New-PlayerBasicFrame 0), (New-PlayerBasicFrame 1)) `
    -Duration 80 `
    -State "player_primary" `
    -LeadingAnchor @(28, 16) `
    -TrailAnchor @(3, 16)
Add-DirectionalClip `
    -Collection $frames `
    -Clip "player_opening_breach_flight" `
    -SourceFrames @((New-OpeningFrame 0), (New-OpeningFrame 1)) `
    -Duration 90 `
    -State "player_opening_breach" `
    -LeadingAnchor @(30, 16) `
    -TrailAnchor @(2, 16)
Add-DirectionalClip `
    -Collection $frames `
    -Clip "secondary_seeker_flight" `
    -SourceFrames @((New-SeekerFrame 0), (New-SeekerFrame 1)) `
    -Duration 100 `
    -State "secondary_seeker" `
    -LeadingAnchor @(26, 16) `
    -TrailAnchor @(2, 16)

Add-StaticClip $frames "hostile_light_pulse" @((New-HostileFrame "light" 0), (New-HostileFrame "light" 1)) 100 "hostile_light"
Add-StaticClip $frames "hostile_standard_pulse" @((New-HostileFrame "standard" 0), (New-HostileFrame "standard" 1)) 120 "hostile_standard"
Add-StaticClip $frames "hostile_heavy_pulse" @(
    (New-HostileFrame "heavy" 0),
    (New-HostileFrame "heavy" 1),
    (New-HostileFrame "heavy" 2)
) 150 "hostile_heavy"

foreach ($affinity in @("thermal", "toxin", "cryo", "arc", "hybrid")) {
    Add-StaticClip `
        -Collection $frames `
        -Clip "affinity_${affinity}_motion" `
        -SourceFrames @((New-AffinityOverlay $affinity 0), (New-AffinityOverlay $affinity 1)) `
        -Duration 100 `
        -State "affinity_${affinity}"
}

foreach ($impact in @("wall", "enemy", "player_hull", "barrier", "breach_interrupt")) {
    Add-StaticClip `
        -Collection $frames `
        -Clip "impact_${impact}" `
        -SourceFrames @(
            (New-ImpactFrame $impact 0),
            (New-ImpactFrame $impact 1),
            (New-ImpactFrame $impact 2),
            (New-ImpactFrame $impact 3)
        ) `
        -Duration 60 `
        -State "impact_${impact}"
}

if ($frames.Count -ne 85) {
    throw "Expected 85 projectile animation frames; got $($frames.Count)."
}

$expectedClipCounts = [ordered]@{
    player_basic_flight = 16
    player_opening_breach_flight = 16
    secondary_seeker_flight = 16
    hostile_light_pulse = 2
    hostile_standard_pulse = 2
    hostile_heavy_pulse = 3
    affinity_thermal_motion = 2
    affinity_toxin_motion = 2
    affinity_cryo_motion = 2
    affinity_arc_motion = 2
    affinity_hybrid_motion = 2
    impact_wall = 4
    impact_enemy = 4
    impact_player_hull = 4
    impact_barrier = 4
    impact_breach_interrupt = 4
}
foreach ($entry in $expectedClipCounts.GetEnumerator()) {
    $actual = @($frames | Where-Object { $_.clip -eq $entry.Key }).Count
    if ($actual -ne $entry.Value) {
        throw "Clip $($entry.Key) expected $($entry.Value) frames; got $actual."
    }
}

foreach ($frame in $frames) {
    Assert-FrameAnchors $frame
}

$minimumThreatExtents = [ordered]@{
    hostile_light_pulse = 10
    hostile_standard_pulse = 12
    hostile_heavy_pulse = 14
}
foreach ($entry in $minimumThreatExtents.GetEnumerator()) {
    foreach ($frame in @($frames | Where-Object { $_.clip -eq $entry.Key })) {
        Assert-MinimumExtent $frame.pixels $entry.Value $entry.Key
    }
}

if ($RunNegativeValidation) {
    $invalidAnchor = [ordered]@{
        clip = "negative_anchor"
        frame = 0
        leading_anchor = @(32, 16)
        trail_anchor = @(2, 16)
    }
    $anchorRejected = $false
    try {
        Assert-FrameAnchors $invalidAnchor
    }
    catch {
        $anchorRejected = $true
    }
    if (-not $anchorRejected) {
        throw "Negative validation failed: out-of-bounds anchor was accepted."
    }

    $undersized = New-PixelBuffer
    Set-Pixel $undersized 15 15 "R"
    $extentRejected = $false
    try {
        Assert-MinimumExtent $undersized 14 "negative_heavy"
    }
    catch {
        $extentRejected = $true
    }
    if (-not $extentRejected) {
        throw "Negative validation failed: undersized heavy shot was accepted."
    }
    Write-Output "Negative validation passed: invalid anchor and undersized threat were rejected."
}

if (-not [System.IO.Directory]::Exists($destination)) {
    [System.IO.Directory]::CreateDirectory($destination) | Out-Null
}

$rows = [int][Math]::Ceiling($frames.Count / [double]$columns)
$atlasWidth = $columns * $pitch
$atlasHeight = $rows * $pitch
$atlasSvg = [System.Collections.Generic.List[string]]::new()
$atlasSvg.Add("<svg xmlns=`"http://www.w3.org/2000/svg`" width=`"$atlasWidth`" height=`"$atlasHeight`" viewBox=`"0 0 $atlasWidth $atlasHeight`" shape-rendering=`"crispEdges`">")
$atlasSvg.Add("  <metadata>Cardborne projectile animations; 32x32 cells; one transparent pixel gutter; 85 frames.</metadata>")
$metadataFrames = [System.Collections.Generic.List[object]]::new()
for ($index = 0; $index -lt $frames.Count; $index++) {
    $frame = $frames[$index]
    $column = $index % $columns
    $row = [int][Math]::Floor($index / [double]$columns)
    $originX = $column * $pitch + $padding
    $originY = $row * $pitch + $padding
    foreach ($rect in (Pixel-Runs $frame.pixels $originX $originY 1)) {
        $atlasSvg.Add("  $rect")
    }
    $bounds = Opaque-Bounds $frame.pixels
    $metadataFrames.Add([ordered]@{
        atlas_index = $index
        clip = [string]$frame.clip
        frame = [int]$frame.frame
        region = @($originX, $originY, $spriteSize, $spriteSize)
        duration_ms = [int]$frame.duration_ms
        state = [string]$frame.state
        direction = $frame.direction
        pivot = @($frame.pivot)
        leading_anchor = $frame.leading_anchor
        trail_anchor = $frame.trail_anchor
        opaque_bounds = @($bounds)
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
    throw "Failed to rasterize the projectile animation atlas."
}
$atlasGeometry = (& $magick.Source identify -format "%w %h" $atlasPngPath).Trim()
if ($atlasGeometry -ne "$atlasWidth $atlasHeight") {
    throw "Projectile atlas must be ${atlasWidth}x${atlasHeight}; got $atlasGeometry."
}

$metadata = [ordered]@{
    schema_version = 2
    native_frame_size = @($spriteSize, $spriteSize)
    pivot = @($pivot, $pivot)
    atlas_size = @($atlasWidth, $atlasHeight)
    gutter = $padding
    columns = $columns
    frame_count = $frames.Count
    directions = @($directions | ForEach-Object { $_.id })
    clip_counts = $expectedClipCounts
    frames = @($metadataFrames)
    composition_rule = "physical flight head -> optional affinity motion overlay -> separate impact clip"
}
[System.IO.File]::WriteAllText(
    (Join-Path $destination "projectile-parts-atlas.json"),
    ($metadata | ConvertTo-Json -Depth 8) + [Environment]::NewLine,
    [System.Text.UTF8Encoding]::new($false)
)

function Find-Frame {
    param(
        [string]$Clip,
        [int]$Frame,
        [AllowNull()][string]$Direction
    )

    return $script:frames |
        Where-Object {
            $_.clip -eq $Clip -and
            $_.frame -eq $Frame -and
            (($null -eq $Direction -and $null -eq $_.direction) -or $_.direction -eq $Direction)
        } |
        Select-Object -First 1
}

function Add-PreviewSprite {
    param(
        [System.Collections.Generic.List[string]]$Svg,
        [char[]]$Pixels,
        [int]$X,
        [int]$Y,
        [int]$Scale
    )

    foreach ($rect in (Pixel-Runs $Pixels $X $Y $Scale)) {
        $Svg.Add("  $rect")
    }
}

function Add-SequenceRow {
    param(
        [System.Collections.Generic.List[string]]$Svg,
        [string]$Label,
        [object[]]$SequenceFrames,
        [int]$Y,
        [int]$Scale = 3
    )

    $Svg.Add("  <text x=`"52`" y=`"$($Y + 45)`" fill=`"#FFF6DC`" font-family=`"Arial, sans-serif`" font-size=`"18`" font-weight=`"700`">$Label</text>")
    $x = 300
    foreach ($frame in $SequenceFrames) {
        $Svg.Add("  <rect x=`"$x`" y=`"$Y`" width=`"$(32 * $Scale)`" height=`"$(32 * $Scale)`" fill=`"#0739A6`"/>")
        Add-PreviewSprite $Svg $frame.pixels $x $Y $Scale
        $Svg.Add("  <text x=`"$($x + 48)`" y=`"$($Y + 116)`" text-anchor=`"middle`" fill=`"#75C4B2`" font-family=`"Arial, sans-serif`" font-size=`"12`">$($frame.duration_ms) ms</text>")
        $x += 128
    }
}

$previewWidth = 1280
$previewHeight = 1040
$preview = [System.Collections.Generic.List[string]]::new()
$preview.Add("<svg xmlns=`"http://www.w3.org/2000/svg`" width=`"$previewWidth`" height=`"$previewHeight`" viewBox=`"0 0 $previewWidth $previewHeight`" shape-rendering=`"crispEdges`">")
$preview.Add("  <rect width=`"$previewWidth`" height=`"$previewHeight`" fill=`"#042B7B`"/>")
$preview.Add("  <text x=`"52`" y=`"48`" fill=`"#FFF6DC`" font-family=`"Arial, sans-serif`" font-size=`"28`" font-weight=`"700`">PROJECTILE FLIGHT AND IMPACT SEQUENCES</text>")
$preview.Add("  <text x=`"52`" y=`"78`" fill=`"#A8DACB`" font-family=`"Arial, sans-serif`" font-size=`"15`">32x32 masters · frames shown at 3x · labels are preview-only</text>")

Add-SequenceRow $preview "PLAYER BASIC" @(
    (Find-Frame "player_basic_flight" 0 "e"),
    (Find-Frame "player_basic_flight" 1 "e"),
    (Find-Frame "player_basic_flight" 0 "n"),
    (Find-Frame "player_basic_flight" 1 "n"),
    (Find-Frame "player_basic_flight" 0 "se"),
    (Find-Frame "player_basic_flight" 1 "se")
) 110
Add-SequenceRow $preview "OPENING / BREACH" @(
    (Find-Frame "player_opening_breach_flight" 0 "e"),
    (Find-Frame "player_opening_breach_flight" 1 "e")
) 250
Add-SequenceRow $preview "SEEKER MISSILE" @(
    (Find-Frame "secondary_seeker_flight" 0 "e"),
    (Find-Frame "secondary_seeker_flight" 1 "e"),
    (Find-Frame "secondary_seeker_flight" 0 "ne"),
    (Find-Frame "secondary_seeker_flight" 1 "ne")
) 390
Add-SequenceRow $preview "HOSTILE THREATS" @(
    (Find-Frame "hostile_light_pulse" 0 $null),
    (Find-Frame "hostile_light_pulse" 1 $null),
    (Find-Frame "hostile_standard_pulse" 0 $null),
    (Find-Frame "hostile_standard_pulse" 1 $null),
    (Find-Frame "hostile_heavy_pulse" 0 $null),
    (Find-Frame "hostile_heavy_pulse" 1 $null),
    (Find-Frame "hostile_heavy_pulse" 2 $null)
) 530

$preview.Add("  <text x=`"52`" y=`"715`" fill=`"#FFF6DC`" font-family=`"Arial, sans-serif`" font-size=`"18`" font-weight=`"700`">AFFINITY MOTION</text>")
$preview.Add("  <text x=`"52`" y=`"740`" fill=`"#75C4B2`" font-family=`"Arial, sans-serif`" font-size=`"12`">COMPOSITED ON STANDARD SHOT</text>")
$affinityX = 300
foreach ($affinity in @("thermal", "toxin", "cryo", "arc", "hybrid")) {
    $base = (Find-Frame "hostile_standard_pulse" 0 $null).pixels
    $overlay0 = (Find-Frame "affinity_${affinity}_motion" 0 $null).pixels
    $overlay1 = (Find-Frame "affinity_${affinity}_motion" 1 $null).pixels
    foreach ($composite in @((Merge-PixelBuffers @($base, $overlay0)), (Merge-PixelBuffers @($base, $overlay1)))) {
        $preview.Add("  <rect x=`"$affinityX`" y=`"680`" width=`"64`" height=`"64`" fill=`"#0739A6`"/>")
        Add-PreviewSprite $preview $composite $affinityX 680 2
        $affinityX += 70
    }
    $preview.Add("  <text x=`"$($affinityX - 70)`" y=`"762`" text-anchor=`"middle`" fill=`"#75C4B2`" font-family=`"Arial, sans-serif`" font-size=`"11`">$($affinity.ToUpperInvariant())</text>")
    $affinityX += 22
}

$preview.Add("  <text x=`"52`" y=`"840`" fill=`"#FFF6DC`" font-family=`"Arial, sans-serif`" font-size=`"18`" font-weight=`"700`">IMPACT SEQUENCES</text>")
$preview.Add("  <text x=`"52`" y=`"865`" fill=`"#75C4B2`" font-family=`"Arial, sans-serif`" font-size=`"12`">CONTACT → EXPANSION → FRAGMENTS → FADE</text>")
$impactX = 300
foreach ($impact in @("wall", "enemy", "player_hull", "barrier", "breach_interrupt")) {
    for ($phase = 0; $phase -lt 4; $phase++) {
        $impactFrame = Find-Frame "impact_${impact}" $phase $null
        $preview.Add("  <rect x=`"$impactX`" y=`"805`" width=`"32`" height=`"32`" fill=`"#0739A6`"/>")
        Add-PreviewSprite $preview $impactFrame.pixels $impactX 805 1
        $impactX += 34
    }
    $preview.Add("  <text x=`"$($impactX - 68)`" y=`"858`" text-anchor=`"middle`" fill=`"#75C4B2`" font-family=`"Arial, sans-serif`" font-size=`"10`">$($impact.Replace("_", " ").ToUpperInvariant())</text>")
    $impactX += 16
}
$preview.Add("  <text x=`"52`" y=`"982`" fill=`"#A8DACB`" font-family=`"Arial, sans-serif`" font-size=`"14`">The atlas stores motion and impacts. Upgrade rules remain gameplay state, not centered bullet icons.</text>")
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
    throw "Failed to rasterize the projectile sequence preview."
}

$proofWidth = 1280
$proofHeight = 720
$proof = [System.Collections.Generic.List[string]]::new()
$proof.Add("<svg xmlns=`"http://www.w3.org/2000/svg`" width=`"$proofWidth`" height=`"$proofHeight`" viewBox=`"0 0 $proofWidth $proofHeight`" shape-rendering=`"crispEdges`">")
$proof.Add("  <rect width=`"$proofWidth`" height=`"$proofHeight`" fill=`"#061A25`"/>")
$proof.Add("  <path d=`"M80 78 H1196 V642 H80 Z`" fill=`"#153B3A`"/>")
$proof.Add("  <path d=`"M120 112 H1160 V608 H120 Z`" fill=`"#174E4B`"/>")
$proof.Add("  <path d=`"M120 112 H1160 V608 H120 Z`" fill=`"none`" stroke=`"#75C4B2`" stroke-width=`"4`"/>")
$proof.Add("  <path d=`"M120 252 H360 V294 H120 M920 426 H1160 V468 H920 M510 112 V238 H554 V112 M708 482 V608 H752 V482`" fill=`"#0B2E37`" stroke=`"#75C4B2`" stroke-width=`"3`"/>")
$proof.Add("  <path d=`"M618 319 L650 336 L618 353 L586 336 Z`" fill=`"#D79A17`"/>")
$proof.Add("  <path d=`"M618 324 L641 336 L618 348 L595 336 Z`" fill=`"#FFF6DC`"/>")
$proof.Add("  <rect x=`"606`" y=`"352`" width=`"24`" height=`"8`" fill=`"#3E91B7`"/>")
$proof.Add("  <rect x=`"610`" y=`"360`" width=`"16`" height=`"8`" fill=`"#75C4B2`"/>")

$enemyPositions = @(
    @(198, 168), @(294, 146), @(408, 186), @(842, 150), @(978, 186), @(1080, 254),
    @(1032, 514), @(886, 564), @(752, 548), @(468, 558), @(302, 520), @(186, 438)
)
foreach ($position in $enemyPositions) {
    $x = $position[0]
    $y = $position[1]
    $proof.Add("  <path d=`"M$x $($y - 12) L$($x + 12) $y L$x $($y + 12) L$($x - 12) $y Z`" fill=`"#7B1733`"/>")
    $proof.Add("  <rect x=`"$($x - 5)`" y=`"$($y - 5)`" width=`"10`" height=`"10`" fill=`"#C92F4E`"/>")
}

$playerShots = @(
    @(690, 328, "e", 0), @(746, 320, "e", 1), @(806, 312, "e", 0),
    @(565, 280, "nw", 1), @(534, 247, "nw", 0)
)
foreach ($shot in $playerShots) {
    $pixels = (Find-Frame "player_basic_flight" $shot[3] $shot[2]).pixels
    Add-PreviewSprite $proof $pixels $shot[0] $shot[1] 1
}
Add-PreviewSprite $proof (Find-Frame "player_opening_breach_flight" 0 "se").pixels 662 382 1
Add-PreviewSprite $proof (Find-Frame "secondary_seeker_flight" 1 "ne").pixels 536 364 1

$hostileShots = @(
    @(256, 194, "light", $null), @(302, 216, "light", $null), @(354, 238, "standard", "thermal"),
    @(412, 260, "light", $null), @(452, 280, "standard", "toxin"), @(490, 298, "light", $null),
    @(1000, 210, "light", $null), @(950, 232, "standard", "cryo"), @(906, 250, "light", $null),
    @(862, 272, "heavy", "arc"), @(820, 290, "light", $null), @(780, 306, "standard", "hybrid"),
    @(1000, 500, "light", $null), @(948, 478, "light", $null), @(900, 456, "standard", "toxin"),
    @(852, 434, "light", $null), @(810, 416, "heavy", "thermal"), @(766, 398, "light", $null),
    @(260, 468, "standard", "cryo"), @(314, 442, "light", $null), @(366, 416, "light", $null),
    @(414, 394, "standard", "arc"), @(458, 376, "light", $null), @(502, 360, "light", $null),
    @(596, 166, "light", $null), @(606, 206, "standard", "hybrid"), @(630, 246, "light", $null),
    @(650, 488, "light", $null), @(634, 452, "standard", "thermal"), @(622, 416, "light", $null)
)
foreach ($shot in $hostileShots) {
    $tier = $shot[2]
    $clip = "hostile_${tier}_pulse"
    $phase = if ($tier -eq "heavy") { 2 } else { 0 }
    $basePixels = (Find-Frame $clip $phase $null).pixels
    $composite = $basePixels
    if ($null -ne $shot[3]) {
        $overlay = (Find-Frame "affinity_$($shot[3])_motion" 0 $null).pixels
        $composite = Merge-PixelBuffers @($basePixels, $overlay)
    }
    $scale = if ($tier -eq "light") { 1 } else { 2 }
    Add-PreviewSprite $proof $composite $shot[0] $shot[1] $scale
}

Add-PreviewSprite $proof (Find-Frame "impact_wall" 2 $null).pixels 328 246 2
Add-PreviewSprite $proof (Find-Frame "impact_breach_interrupt" 1 $null).pixels 734 270 2
$proof.Add("</svg>")

$proofSvgPath = Join-Path $destination "projectile-gameplay-proof.svg"
$proofPngPath = Join-Path $destination "projectile-gameplay-proof.png"
[System.IO.File]::WriteAllText(
    $proofSvgPath,
    ($proof -join [Environment]::NewLine) + [Environment]::NewLine,
    [System.Text.UTF8Encoding]::new($false)
)
& $magick.Source -background none $proofSvgPath -depth 8 -strip $proofPngPath
if ($LASTEXITCODE -ne 0) {
    throw "Failed to rasterize the projectile gameplay proof."
}

$previewGeometry = (& $magick.Source identify -format "%w %h" $previewPngPath).Trim()
$proofGeometry = (& $magick.Source identify -format "%w %h" $proofPngPath).Trim()
if ($previewGeometry -ne "$previewWidth $previewHeight") {
    throw "Projectile sequence preview must be ${previewWidth}x${previewHeight}; got $previewGeometry."
}
if ($proofGeometry -ne "$proofWidth $proofHeight") {
    throw "Projectile gameplay proof must be ${proofWidth}x${proofHeight}; got $proofGeometry."
}

Write-Output "Created projectile animation atlas: $atlasPngPath"
Write-Output "Created projectile sequence preview: $previewPngPath"
Write-Output "Created projectile gameplay proof: $proofPngPath"
