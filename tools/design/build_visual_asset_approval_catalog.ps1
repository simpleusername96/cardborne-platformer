param(
    [string]$OutputRoot = "docs/design/component-sheets/semantic-v3-approval"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$outputDir = Join-Path $repoRoot $OutputRoot
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$gameplayRoot = Join-Path $repoRoot "art/gameplay/semantic-v2"
$uiRoot = Join-Path $repoRoot "art/ui/production/semantic-v2"
$inventoryPath = Join-Path $outputDir "current-asset-inventory.csv"
$gridPath = Join-Path $outputDir "00-current-asset-inventory-grid.png"

function Get-RelativeRepoPath {
    param([string]$Path)
    return $Path.Substring($repoRoot.Length + 1).Replace("\", "/")
}

function Get-ImageMetadata {
    param([System.IO.FileInfo]$File)

    $image = [System.Drawing.Image]::FromFile($File.FullName)
    try {
        return @{
            width = $image.Width
            height = $image.Height
        }
    }
    finally {
        $image.Dispose()
    }
}

$inventory = @()
foreach ($file in Get-ChildItem -Recurse -File -Path $gameplayRoot -Filter "*.png") {
    $relativeToPack = $file.FullName.Substring($gameplayRoot.Length + 1).Replace("\", "/")
    $category = $relativeToPack.Split("/")[0]
    $status = "runtime_gameplay_static"

    if ($relativeToPack.StartsWith("effects/atlases/")) {
        $status = "runtime_effect_atlas"
    }
    elseif ($relativeToPack.StartsWith("effects/frames/")) {
        $status = "runtime_effect_frame"
    }
    elseif ($relativeToPack.StartsWith("sheets/")) {
        $status = "review_sheet_only"
    }
    elseif ($relativeToPack.StartsWith("sources/")) {
        $status = "source_only"
    }
    elseif (
        $relativeToPack -match "^world/world_shared_floor_\d+\.png$" -or
        $relativeToPack -match "^world/world_wall_.*\.png$"
    ) {
        $status = "staged_not_runtime"
    }

    $metadata = Get-ImageMetadata -File $file
    $inventory += [pscustomobject]@{
        domain = "gameplay"
        category = $category
        status = $status
        asset_name = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        path = Get-RelativeRepoPath -Path $file.FullName
        width = $metadata.width
        height = $metadata.height
        bytes = $file.Length
    }
}

foreach ($file in Get-ChildItem -Recurse -File -Path $uiRoot -Filter "*.png") {
    $relativeToPack = $file.FullName.Substring($uiRoot.Length + 1).Replace("\", "/")
    $category = $relativeToPack.Split("/")[0]
    $status = "runtime_ui"

    if ($relativeToPack.StartsWith("sheets/")) {
        $status = "review_sheet_only"
    }
    elseif ($relativeToPack.StartsWith("sources/")) {
        $status = "source_only"
    }

    $metadata = Get-ImageMetadata -File $file
    $inventory += [pscustomobject]@{
        domain = "ui"
        category = $category
        status = $status
        asset_name = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        path = Get-RelativeRepoPath -Path $file.FullName
        width = $metadata.width
        height = $metadata.height
        bytes = $file.Length
    }
}

$sortedInventory = @($inventory | Sort-Object domain, status, category, path)
$inventoryIndex = 0
$sortedInventory |
    ForEach-Object {
        $inventoryIndex += 1
        [pscustomobject]@{
            index = $inventoryIndex
            domain = $_.domain
            category = $_.category
            status = $_.status
            asset_name = $_.asset_name
            path = $_.path
            width = $_.width
            height = $_.height
            bytes = $_.bytes
        }
    } |
    Export-Csv -NoTypeInformation -Encoding UTF8 -Path $inventoryPath

$sheets = @(
    @{
        title = "01 플레이어 · 보조무기"
        status = "실사용 에셋"
        path = Join-Path $gameplayRoot "sheets/01-player-weapons.png"
    },
    @{
        title = "02 일반 적"
        status = "실사용 에셋"
        path = Join-Path $gameplayRoot "sheets/02-enemies.png"
    },
    @{
        title = "03 보스 · 모듈"
        status = "실사용 에셋"
        path = Join-Path $gameplayRoot "sheets/03-bosses-modules.png"
    },
    @{
        title = "04 탄환 · 상태 · 아이템"
        status = "실사용 에셋"
        path = Join-Path $gameplayRoot "sheets/04-projectiles-status-pickups.png"
    },
    @{
        title = "05 맵 · 벽 · 지형지물"
        status = "혼합: 시설 실사용 / 바닥·벽 미연결"
        path = Join-Path $gameplayRoot "sheets/05-world.png"
    },
    @{
        title = "06 HUD 글리프"
        status = "실사용 에셋"
        path = Join-Path $gameplayRoot "sheets/06-hud-glyphs.png"
    },
    @{
        title = "07 효과 아틀라스"
        status = "실사용 에셋"
        path = Join-Path $gameplayRoot "sheets/07-effect-atlases.png"
    },
    @{
        title = "08 효과 의미 확장"
        status = "실사용 에셋"
        path = Join-Path $gameplayRoot "sheets/08-effect-semantic-expansion.png"
    },
    @{
        title = "09 전투 신호 글리프"
        status = "실사용 에셋"
        path = Join-Path $gameplayRoot "sheets/09-combat-cue-glyphs.png"
    },
    @{
        title = "10 UI 패널"
        status = "실사용 에셋"
        path = Join-Path $uiRoot "sheets/01-ui-surface-components.png"
    },
    @{
        title = "11 UI 컨트롤 상태"
        status = "실사용 에셋"
        path = Join-Path $uiRoot "sheets/02-ui-control-states.png"
    }
)

$canvasWidth = 4200
$canvasHeight = 6400
$margin = 72
$headerHeight = 190
$footerHeight = 90
$columnCount = 3
$rowCount = 4
$gap = 30
$cellWidth = [int](($canvasWidth - ($margin * 2) - ($gap * ($columnCount - 1))) / $columnCount)
$cellHeight = [int](($canvasHeight - $headerHeight - $footerHeight - ($margin * 2) - ($gap * ($rowCount - 1))) / $rowCount)
$cellHeaderHeight = 104

$bitmap = New-Object System.Drawing.Bitmap($canvasWidth, $canvasHeight)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$graphics.Clear([System.Drawing.Color]::FromArgb(255, 13, 21, 30))

$titleFont = New-Object System.Drawing.Font("Malgun Gothic", 46, [System.Drawing.FontStyle]::Bold)
$subtitleFont = New-Object System.Drawing.Font("Malgun Gothic", 22, [System.Drawing.FontStyle]::Regular)
$cellTitleFont = New-Object System.Drawing.Font("Malgun Gothic", 25, [System.Drawing.FontStyle]::Bold)
$statusFont = New-Object System.Drawing.Font("Malgun Gothic", 17, [System.Drawing.FontStyle]::Regular)
$footerFont = New-Object System.Drawing.Font("Malgun Gothic", 18, [System.Drawing.FontStyle]::Regular)
$whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 237, 243, 248))
$mutedBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 164, 181, 195))
$runtimeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 112, 219, 188))
$mixedBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 246, 184, 74))
$panelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 20, 34, 47))
$borderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 59, 79, 98), 3)

$graphics.DrawString("Cardborne 현재 에셋 마스터 그리드", $titleFont, $whiteBrush, $margin, 40)
$graphics.DrawString(
    "기존 11개 검토 시트를 원본 그대로 합성 · 생성형 재해석 없음 · 2026-07-31",
    $subtitleFont,
    $mutedBrush,
    $margin,
    112
)

for ($index = 0; $index -lt $sheets.Count; $index++) {
    $column = $index % $columnCount
    $row = [int][Math]::Floor($index / $columnCount)
    $x = $margin + ($column * ($cellWidth + $gap))
    $y = $margin + $headerHeight + ($row * ($cellHeight + $gap))
    $cellRect = New-Object System.Drawing.Rectangle($x, $y, $cellWidth, $cellHeight)

    $graphics.FillRectangle($panelBrush, $cellRect)
    $graphics.DrawRectangle($borderPen, $cellRect)
    $graphics.DrawString($sheets[$index].title, $cellTitleFont, $whiteBrush, $x + 22, $y + 16)

    $statusBrush = if ($sheets[$index].status.StartsWith("혼합")) { $mixedBrush } else { $runtimeBrush }
    $graphics.DrawString($sheets[$index].status, $statusFont, $statusBrush, $x + 22, $y + 60)

    $sourceImage = [System.Drawing.Image]::FromFile($sheets[$index].path)
    try {
        $imageAreaX = $x + 16
        $imageAreaY = $y + $cellHeaderHeight
        $imageAreaWidth = $cellWidth - 32
        $imageAreaHeight = $cellHeight - $cellHeaderHeight - 18
        $scale = [Math]::Min($imageAreaWidth / $sourceImage.Width, $imageAreaHeight / $sourceImage.Height)
        $drawWidth = [int]($sourceImage.Width * $scale)
        $drawHeight = [int]($sourceImage.Height * $scale)
        $drawX = $imageAreaX + [int](($imageAreaWidth - $drawWidth) / 2)
        $drawY = $imageAreaY + [int](($imageAreaHeight - $drawHeight) / 2)
        $graphics.DrawImage($sourceImage, $drawX, $drawY, $drawWidth, $drawHeight)
    }
    finally {
        $sourceImage.Dispose()
    }
}

$footerY = $canvasHeight - $footerHeight + 12
$graphics.DrawString(
    "파일 단위 전체 목록: current-asset-inventory.csv  |  바닥·벽 8개는 파일만 존재하며 현재 런타임 미연결",
    $footerFont,
    $mutedBrush,
    $margin,
    $footerY
)

$bitmap.Save($gridPath, [System.Drawing.Imaging.ImageFormat]::Png)

$graphics.Dispose()
$bitmap.Dispose()
$titleFont.Dispose()
$subtitleFont.Dispose()
$cellTitleFont.Dispose()
$statusFont.Dispose()
$footerFont.Dispose()
$whiteBrush.Dispose()
$mutedBrush.Dispose()
$runtimeBrush.Dispose()
$mixedBrush.Dispose()
$panelBrush.Dispose()
$borderPen.Dispose()

Write-Output "Wrote $inventoryPath"
Write-Output "Wrote $gridPath"
