param(
    [string]$OutputRoot = "docs/design/component-sheets/semantic-v3-approval/generated/semantic-v5/previews"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$approvalRoot = Join-Path $repoRoot "docs\design\component-sheets\semantic-v3-approval"
$outputDir = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutputRoot))
$approvalPrefix = $approvalRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
if (-not $outputDir.StartsWith($approvalPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "OutputRoot must stay inside $approvalRoot"
}

$semanticV5 = Split-Path $outputDir -Parent
$requiredInputs = @(
    (Join-Path $repoRoot "art/gameplay/semantic-v2/actors/player/actor_player_hull_base.png"),
    (Join-Path $repoRoot "art/gameplay/semantic-v2/actors/player/actor_player_engine.png"),
    (Join-Path $repoRoot "art/gameplay/semantic-v2/weapons/secondaries/secondary_orbit_blade.png"),
    (Join-Path $repoRoot "art/gameplay/semantic-v2/weapons/secondaries/secondary_escort_drone.png"),
    (Join-Path $repoRoot "art/gameplay/semantic-v2/weapons/secondaries/secondary_seeker.png"),
    (Join-Path $repoRoot "art/gameplay/semantic-v2/weapons/secondaries/secondary_wake_mine.png"),
    (Join-Path $repoRoot "art/gameplay/semantic-v2/weapons/projectiles/projectile_hostile_kinetic.png"),
    (Join-Path $semanticV5 "floor-base-candidates.png"),
    (Join-Path $semanticV5 "upgrade-offense-candidates.png"),
    (Join-Path $semanticV5 "upgrade-chassis-candidates.png")
)
$missingInputs = @($requiredInputs | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
if ($missingInputs.Count -gt 0) {
    throw "Missing required preview inputs:`n$($missingInputs -join "`n")"
}

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$palette = @{
    Back = [System.Drawing.Color]::FromArgb(255, 10, 17, 25)
    Panel = [System.Drawing.Color]::FromArgb(255, 22, 34, 46)
    Line = [System.Drawing.Color]::FromArgb(255, 68, 91, 111)
    Text = [System.Drawing.Color]::FromArgb(255, 238, 244, 248)
    Muted = [System.Drawing.Color]::FromArgb(255, 166, 183, 197)
    Cyan = [System.Drawing.Color]::FromArgb(255, 86, 215, 238)
    Amber = [System.Drawing.Color]::FromArgb(255, 245, 184, 52)
    Coral = [System.Drawing.Color]::FromArgb(255, 240, 90, 95)
}

function New-Canvas {
    param([int]$Width, [int]$Height)

    $bitmap = New-Object System.Drawing.Bitmap($Width, $Height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.Clear($palette.Back)
    return @{ Bitmap = $bitmap; Graphics = $graphics }
}

function Save-Canvas {
    param($Canvas, [string]$Path)

    $Canvas.Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $Canvas.Graphics.Dispose()
    $Canvas.Bitmap.Dispose()
}

function Draw-Label {
    param(
        [System.Drawing.Graphics]$Graphics,
        [string]$Text,
        [float]$X,
        [float]$Y,
        [float]$Size = 21,
        [System.Drawing.Color]$Color = $palette.Text,
        [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Bold
    )

    $font = New-Object System.Drawing.Font("Malgun Gothic", $Size, $Style)
    $brush = New-Object System.Drawing.SolidBrush($Color)
    try { $Graphics.DrawString($Text, $font, $brush, $X, $Y) }
    finally { $font.Dispose(); $brush.Dispose() }
}

function Draw-Panel {
    param([System.Drawing.Graphics]$Graphics, [System.Drawing.RectangleF]$Rect)

    $fill = New-Object System.Drawing.SolidBrush($palette.Panel)
    $line = New-Object System.Drawing.Pen($palette.Line, 2)
    try {
        $Graphics.FillRectangle($fill, $Rect)
        $Graphics.DrawRectangle($line, $Rect.X, $Rect.Y, $Rect.Width, $Rect.Height)
    }
    finally { $fill.Dispose(); $line.Dispose() }
}

function Draw-ImageFit {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Image]$Image,
        [System.Drawing.RectangleF]$Rect,
        [float]$Alpha = 1.0
    )

    $scale = [Math]::Min($Rect.Width / $Image.Width, $Rect.Height / $Image.Height)
    $width = [float]($Image.Width * $scale)
    $height = [float]($Image.Height * $scale)
    $x = $Rect.X + (($Rect.Width - $width) / 2)
    $y = $Rect.Y + (($Rect.Height - $height) / 2)
    $attributes = New-Object System.Drawing.Imaging.ImageAttributes
    $matrix = New-Object System.Drawing.Imaging.ColorMatrix
    $matrix.Matrix33 = $Alpha
    $attributes.SetColorMatrix($matrix)
    try {
        $Graphics.DrawImage(
            $Image,
            [System.Drawing.Rectangle]::Round([System.Drawing.RectangleF]::new($x, $y, $width, $height)),
            0,
            0,
            $Image.Width,
            $Image.Height,
            [System.Drawing.GraphicsUnit]::Pixel,
            $attributes
        )
    }
    finally { $attributes.Dispose() }
}

function Draw-RotatedImage {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Image]$Image,
        [float]$CenterX,
        [float]$CenterY,
        [float]$Width,
        [float]$Height,
        [float]$Degrees,
        [float]$Alpha = 1.0
    )

    $state = $Graphics.Save()
    try {
        $Graphics.TranslateTransform($CenterX, $CenterY)
        $Graphics.RotateTransform($Degrees)
        Draw-ImageFit -Graphics $Graphics -Image $Image -Rect ([System.Drawing.RectangleF]::new(-$Width / 2, -$Height / 2, $Width, $Height)) -Alpha $Alpha
    }
    finally { $Graphics.Restore($state) }
}

function Draw-Arrow {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X1,
        [float]$Y1,
        [float]$X2,
        [float]$Y2,
        [System.Drawing.Color]$Color = $palette.Cyan
    )

    $pen = New-Object System.Drawing.Pen($Color, 4)
    $pen.CustomEndCap = New-Object System.Drawing.Drawing2D.AdjustableArrowCap(5, 7, $true)
    try { $Graphics.DrawLine($pen, $X1, $Y1, $X2, $Y2) }
    finally { $pen.Dispose() }
}

function Draw-Exhaust {
    param([System.Drawing.Graphics]$Graphics, [float]$SocketX, [float]$CenterY, [float]$Length)

    if ($Length -le 0) { return }
    $outer = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 49, 210, 238))
    $core = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(235, 226, 252, 255))
    try {
        $outerPoints = @(
            [System.Drawing.PointF]::new($SocketX, $CenterY - 20),
            [System.Drawing.PointF]::new($SocketX - $Length, $CenterY),
            [System.Drawing.PointF]::new($SocketX, $CenterY + 20)
        )
        $corePoints = @(
            [System.Drawing.PointF]::new($SocketX, $CenterY - 7),
            [System.Drawing.PointF]::new($SocketX - ($Length * .72), $CenterY),
            [System.Drawing.PointF]::new($SocketX, $CenterY + 7)
        )
        $Graphics.FillPolygon($outer, $outerPoints)
        $Graphics.FillPolygon($core, $corePoints)
    }
    finally { $outer.Dispose(); $core.Dispose() }
}

function Draw-PlayerAssembly {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Image]$Hull,
        [System.Drawing.Image]$Engine,
        [float]$CenterX,
        [float]$CenterY,
        [float]$ExhaustLength,
        [bool]$Afterimage
    )

    if ($Afterimage) {
        Draw-ImageFit -Graphics $Graphics -Image $Hull -Rect ([System.Drawing.RectangleF]::new($CenterX - 208, $CenterY - 66, 210, 132)) -Alpha .14
        Draw-ImageFit -Graphics $Graphics -Image $Hull -Rect ([System.Drawing.RectangleF]::new($CenterX - 166, $CenterY - 66, 210, 132)) -Alpha .25
    }
    Draw-Exhaust -Graphics $Graphics -SocketX ($CenterX - 113) -CenterY $CenterY -Length $ExhaustLength
    Draw-ImageFit -Graphics $Graphics -Image $Engine -Rect ([System.Drawing.RectangleF]::new($CenterX - 125, $CenterY - 45, 90, 90))
    Draw-ImageFit -Graphics $Graphics -Image $Hull -Rect ([System.Drawing.RectangleF]::new($CenterX - 92, $CenterY - 66, 210, 132))
}

function Build-EnginePreview {
    param([bool]$Target, [string]$OutputPath)

    $hull = [System.Drawing.Image]::FromFile((Join-Path $repoRoot "art/gameplay/semantic-v2/actors/player/actor_player_hull_base.png"))
    $engine = [System.Drawing.Image]::FromFile((Join-Path $repoRoot "art/gameplay/semantic-v2/actors/player/actor_player_engine.png"))
    $canvas = New-Canvas -Width 1200 -Height 520
    $g = $canvas.Graphics
    try {
        Draw-Label -Graphics $g -Text $(if ($Target) { "목표: 대시에만 불꽃과 잔상" } else { "현재: 일반 이동에도 exhaust가 계속 보임" }) -X 36 -Y 25 -Size 28
        $states = @(
            @{ Label = "대기"; X = 205; Exhaust = $(if ($Target) { 0 } else { 38 }); Dash = $false },
            @{ Label = "일반 이동"; X = 600; Exhaust = $(if ($Target) { 0 } else { 92 }); Dash = $false },
            @{ Label = "대시 0.20초"; X = 995; Exhaust = 170; Dash = $Target }
        )
        foreach ($state in $states) {
            $rect = [System.Drawing.RectangleF]::new([float]($state.X - 175), 96, 350, 350)
            Draw-Panel -Graphics $g -Rect $rect
            Draw-Label -Graphics $g -Text $state.Label -X ($state.X - 70) -Y 116 -Size 20 -Color $palette.Muted
            Draw-PlayerAssembly -Graphics $g -Hull $hull -Engine $engine -CenterX ($state.X + 10) -CenterY 305 -ExhaustLength $state.Exhaust -Afterimage $state.Dash
        }
    }
    finally {
        $hull.Dispose()
        $engine.Dispose()
        Save-Canvas -Canvas $canvas -Path $OutputPath
    }
}

function Build-SecondaryPreview {
    param([bool]$Target, [string]$OutputPath)

    $hull = [System.Drawing.Image]::FromFile((Join-Path $repoRoot "art/gameplay/semantic-v2/actors/player/actor_player_hull_base.png"))
    $blade = [System.Drawing.Image]::FromFile((Join-Path $repoRoot "art/gameplay/semantic-v2/weapons/secondaries/secondary_orbit_blade.png"))
    $escort = [System.Drawing.Image]::FromFile((Join-Path $repoRoot "art/gameplay/semantic-v2/weapons/secondaries/secondary_escort_drone.png"))
    $seeker = [System.Drawing.Image]::FromFile((Join-Path $repoRoot "art/gameplay/semantic-v2/weapons/secondaries/secondary_seeker.png"))
    $mine = [System.Drawing.Image]::FromFile((Join-Path $repoRoot "art/gameplay/semantic-v2/weapons/secondaries/secondary_wake_mine.png"))
    $canvas = New-Canvas -Width 1200 -Height 760
    $g = $canvas.Graphics
    try {
        Draw-Label -Graphics $g -Text $(if ($Target) { "목표: 배치 방식별 방향 규칙" } else { "현재: 궤도 위치와 sprite 방향이 어긋남" }) -X 36 -Y 24 -Size 28
        $centerX = 600
        $centerY = 330
        $orbitPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 68, 91, 111), 3)
        try { $g.DrawEllipse($orbitPen, $centerX - 235, $centerY - 235, 470, 470) }
        finally { $orbitPen.Dispose() }
        Draw-ImageFit -Graphics $g -Image $hull -Rect ([System.Drawing.RectangleF]::new($centerX - 110, $centerY - 72, 220, 144))
        foreach ($angle in @(0, 90, 180, 270)) {
            $radians = $angle * [Math]::PI / 180
            $x = $centerX + ([Math]::Cos($radians) * 220)
            $y = $centerY + ([Math]::Sin($radians) * 220)
            $rotation = if ($Target) { $angle } else { 28 }
            Draw-Arrow -Graphics $g -X1 ($centerX + [Math]::Cos($radians) * 135) -Y1 ($centerY + [Math]::Sin($radians) * 135) -X2 ($centerX + [Math]::Cos($radians) * 185) -Y2 ($centerY + [Math]::Sin($radians) * 185) -Color $(if ($Target) { $palette.Cyan } else { $palette.Coral })
            Draw-RotatedImage -Graphics $g -Image $blade -CenterX $x -CenterY $y -Width 88 -Height 88 -Degrees $rotation
        }
        foreach ($angle in @(45, 225)) {
            $radians = $angle * [Math]::PI / 180
            $x = $centerX + ([Math]::Cos($radians) * 150)
            $y = $centerY + ([Math]::Sin($radians) * 150)
            $rotation = if ($Target) { $angle } else { $angle + 180 }
            Draw-RotatedImage -Graphics $g -Image $escort -CenterX $x -CenterY $y -Width 90 -Height 64 -Degrees $rotation
        }

        $legendY = 625
        Draw-Panel -Graphics $g -Rect ([System.Drawing.RectangleF]::new(36, 600, 1128, 120))
        Draw-ImageFit -Graphics $g -Image $seeker -Rect ([System.Drawing.RectangleF]::new(70, $legendY, 125, 55))
        Draw-Arrow -Graphics $g -X1 195 -Y1 ($legendY + 28) -X2 260 -Y2 ($legendY + 28)
        Draw-Label -Graphics $g -Text "시커: 속도 방향" -X 275 -Y ($legendY + 4) -Size 18
        Draw-ImageFit -Graphics $g -Image $mine -Rect ([System.Drawing.RectangleF]::new(565, $legendY, 60, 60))
        Draw-Label -Graphics $g -Text "지뢰·이온장: 방향 없음" -X 650 -Y ($legendY + 4) -Size 18
    }
    finally {
        $hull.Dispose(); $blade.Dispose(); $escort.Dispose(); $seeker.Dispose(); $mine.Dispose()
        Save-Canvas -Canvas $canvas -Path $OutputPath
    }
}

function Build-BossStreamPreview {
    param([bool]$Target, [string]$OutputPath)

    $projectileSource = [System.Drawing.Image]::FromFile((Join-Path $repoRoot "art/gameplay/semantic-v2/weapons/projectiles/projectile_hostile_kinetic.png"))
    $projectile = Get-AlphaTrimmedBitmap -Image $projectileSource
    $projectileSource.Dispose()
    $canvas = New-Canvas -Width 1200 -Height 460
    $g = $canvas.Graphics
    try {
        Draw-Label -Graphics $g -Text $(if ($Target) { "목표: 일반 적 탄환 family를 그대로 재사용" } else { "현재: 등간격 탄환 chain이 하나의 긴 줄처럼 보임" }) -X 36 -Y 28 -Size 27
        Draw-Panel -Graphics $g -Rect ([System.Drawing.RectangleF]::new(36, 100, 1128, 280))
        $originBrush = New-Object System.Drawing.SolidBrush($palette.Coral)
        try { $g.FillEllipse($originBrush, 92, 218, 48, 48) }
        finally { $originBrush.Dispose() }
        $positions = if ($Target) { @(190, 340, 490, 735, 885, 1035) } else { @(150, 250, 350, 450, 550, 650, 750, 850, 950, 1050) }
        foreach ($x in $positions) {
            $g.DrawImage($projectile, [System.Drawing.Rectangle]::new($x, 225, 94, 34))
        }
        if ($Target) {
            Draw-Label -Graphics $g -Text "같은 일반 탄환 · 짧은 묶음 사이 pause" -X 330 -Y 318 -Size 18 -Color $palette.Muted -Style ([System.Drawing.FontStyle]::Regular)
        }
    }
    finally {
        $projectile.Dispose()
        Save-Canvas -Canvas $canvas -Path $OutputPath
    }
}

function Export-Cell {
    param([string]$SourcePath, [int]$Columns, [int]$Rows, [int]$Column, [int]$Row, [string]$OutputPath)

    $source = [System.Drawing.Image]::FromFile($SourcePath)
    try {
        $cellWidth = [int]($source.Width / $Columns)
        $cellHeight = [int]($source.Height / $Rows)
        $bitmap = New-Object System.Drawing.Bitmap($cellWidth, $cellHeight)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.Clear([System.Drawing.Color]::Transparent)
            $graphics.DrawImage(
                $source,
                [System.Drawing.Rectangle]::new(0, 0, $cellWidth, $cellHeight),
                [System.Drawing.Rectangle]::new($Column * $cellWidth, $Row * $cellHeight, $cellWidth, $cellHeight),
                [System.Drawing.GraphicsUnit]::Pixel
            )
            $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally { $graphics.Dispose(); $bitmap.Dispose() }
    }
    finally { $source.Dispose() }
}

function Get-AlphaTrimmedBitmap {
    param([System.Drawing.Image]$Image)

    $source = New-Object System.Drawing.Bitmap($Image)
    $left = $source.Width
    $top = $source.Height
    $right = -1
    $bottom = -1
    for ($y = 0; $y -lt $source.Height; $y++) {
        for ($x = 0; $x -lt $source.Width; $x++) {
            if ($source.GetPixel($x, $y).A -le 8) { continue }
            $left = [Math]::Min($left, $x)
            $top = [Math]::Min($top, $y)
            $right = [Math]::Max($right, $x)
            $bottom = [Math]::Max($bottom, $y)
        }
    }
    if ($right -lt $left -or $bottom -lt $top) { return $source }
    $bounds = [System.Drawing.Rectangle]::new($left, $top, $right - $left + 1, $bottom - $top + 1)
    $trimmed = $source.Clone($bounds, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $source.Dispose()
    return $trimmed
}

function Build-UpgradeContactSheet {
    param([string]$OutputPath)

    $entries = @(
        @{ Id = "primary"; Label = "주무기" },
        @{ Id = "secondary"; Label = "보조무기" },
        @{ Id = "skill"; Label = "스킬" },
        @{ Id = "element"; Label = "속성" },
        @{ Id = "passive"; Label = "지속 효과" },
        @{ Id = "defense"; Label = "방어" },
        @{ Id = "dash"; Label = "대시" },
        @{ Id = "mobility"; Label = "기동" }
    )
    $canvas = New-Canvas -Width 1600 -Height 900
    $g = $canvas.Graphics
    try {
        Draw-Label -Graphics $g -Text "업그레이드 카드용 8개 family 이미지" -X 42 -Y 28 -Size 30
        for ($index = 0; $index -lt $entries.Count; $index++) {
            $column = $index % 4
            $row = [Math]::Floor($index / 4)
            $rect = [System.Drawing.RectangleF]::new(42 + ($column * 388), 100 + ($row * 380), 350, 342)
            Draw-Panel -Graphics $g -Rect $rect
            $imagePath = Join-Path $outputDir ("upgrade-{0}.png" -f $entries[$index].Id)
            $image = [System.Drawing.Image]::FromFile($imagePath)
            try { Draw-ImageFit -Graphics $g -Image $image -Rect ([System.Drawing.RectangleF]::new($rect.X + 55, $rect.Y + 35, 240, 240)) }
            finally { $image.Dispose() }
            Draw-Label -Graphics $g -Text $entries[$index].Label -X ($rect.X + 24) -Y ($rect.Y + 286) -Size 20
            Draw-Label -Graphics $g -Text ("upgrade_{0}" -f $entries[$index].Id) -X ($rect.X + 24) -Y ($rect.Y + 316) -Size 13 -Color $palette.Muted -Style ([System.Drawing.FontStyle]::Regular)
        }
    }
    finally { Save-Canvas -Canvas $canvas -Path $OutputPath }
}

$engineCurrent = Join-Path $outputDir "engine-motion-asis.png"
$engineTarget = Join-Path $outputDir "engine-motion-tobe.png"
$secondaryCurrent = Join-Path $outputDir "secondary-facing-asis.png"
$secondaryTarget = Join-Path $outputDir "secondary-facing-tobe.png"
$bossCurrent = Join-Path $outputDir "boss-stream-asis.png"
$bossTarget = Join-Path $outputDir "boss-stream-tobe.png"

Build-EnginePreview -Target $false -OutputPath $engineCurrent
Build-EnginePreview -Target $true -OutputPath $engineTarget
Build-SecondaryPreview -Target $false -OutputPath $secondaryCurrent
Build-SecondaryPreview -Target $true -OutputPath $secondaryTarget
Build-BossStreamPreview -Target $false -OutputPath $bossCurrent
Build-BossStreamPreview -Target $true -OutputPath $bossTarget

$floorSheet = Join-Path $semanticV5 "floor-base-candidates.png"
$offenseSheet = Join-Path $semanticV5 "upgrade-offense-candidates.png"
$chassisSheet = Join-Path $semanticV5 "upgrade-chassis-candidates.png"

Export-Cell -SourcePath $floorSheet -Columns 2 -Rows 1 -Column 0 -Row 0 -OutputPath (Join-Path $outputDir "floor-base-plain.png")
Export-Cell -SourcePath $floorSheet -Columns 2 -Rows 1 -Column 1 -Row 0 -OutputPath (Join-Path $outputDir "floor-base-alternate.png")

$offenseIds = @("primary", "secondary", "skill", "element")
$chassisIds = @("passive", "defense", "dash", "mobility")
for ($index = 0; $index -lt 4; $index++) {
    Export-Cell -SourcePath $offenseSheet -Columns 2 -Rows 2 -Column ($index % 2) -Row ([Math]::Floor($index / 2)) -OutputPath (Join-Path $outputDir ("upgrade-{0}.png" -f $offenseIds[$index]))
    Export-Cell -SourcePath $chassisSheet -Columns 2 -Rows 2 -Column ($index % 2) -Row ([Math]::Floor($index / 2)) -OutputPath (Join-Path $outputDir ("upgrade-{0}.png" -f $chassisIds[$index]))
}
Build-UpgradeContactSheet -OutputPath (Join-Path $outputDir "upgrade-family-contact-sheet.png")

$expectedOutputs = @(
    "engine-motion-asis.png", "engine-motion-tobe.png",
    "secondary-facing-asis.png", "secondary-facing-tobe.png",
    "boss-stream-asis.png", "boss-stream-tobe.png",
    "floor-base-plain.png", "floor-base-alternate.png",
    "upgrade-primary.png", "upgrade-secondary.png", "upgrade-skill.png", "upgrade-element.png",
    "upgrade-passive.png", "upgrade-defense.png", "upgrade-dash.png", "upgrade-mobility.png",
    "upgrade-family-contact-sheet.png"
)
$missingOutputs = @($expectedOutputs | Where-Object { -not (Test-Path -LiteralPath (Join-Path $outputDir $_) -PathType Leaf) })
if ($missingOutputs.Count -gt 0) {
    throw "Preview generation did not produce:`n$($missingOutputs -join "`n")"
}

Write-Output "Wrote feedback revision previews to $outputDir"
