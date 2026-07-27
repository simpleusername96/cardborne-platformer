param(
    [Parameter(Mandatory = $true)]
    [string]$ManifestPath,

    [Parameter(Mandatory = $true)]
    [string]$BuildDirectory,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

function Resolve-RepoPath {
    param([string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $script:RepoRoot $Path))
}

$script:WorkspaceRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$script:RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $script:WorkspaceRoot ".."))
& (Join-Path $PSScriptRoot "validate_pixel_asset_manifest.ps1") `
    -ManifestPath $ManifestPath `
    -RequireInputFiles

$manifest = Get-Content -LiteralPath (Resolve-RepoPath -Path $ManifestPath) -Raw | ConvertFrom-Json
if ([int]$manifest.schema_version -ne 2) {
    throw "Review boards require a schema-version-2 manifest."
}
$palette = Get-Content -LiteralPath (Resolve-RepoPath -Path ([string]$manifest.palette_path)) -Raw | ConvertFrom-Json
$buildRoot = Resolve-RepoPath -Path $BuildDirectory
$destination = Resolve-RepoPath -Path $OutputPath
$destinationDirectory = [System.IO.Path]::GetDirectoryName($destination)
if (-not [System.IO.Directory]::Exists($destinationDirectory)) {
    [System.IO.Directory]::CreateDirectory($destinationDirectory) | Out-Null
}

$magick = Get-Command magick -ErrorAction Stop
$panelSize = 256
$panelGap = 8
$backgroundRoles = @($manifest.review_backgrounds | Select-Object -First 3)
$panelCount = 4 + $backgroundRoles.Count
$boardWidth = $panelCount * $panelSize + [Math]::Max(0, $panelCount - 1) * $panelGap
$orderedFrames = @($manifest.frames | Sort-Object {[int]$_.atlas_index})
$boardHeight = $orderedFrames.Count * $panelSize + [Math]::Max(0, $orderedFrames.Count - 1) * $panelGap
$temporaryRoot = Join-Path $destinationDirectory "_review-$PID"
[System.IO.Directory]::CreateDirectory($temporaryRoot) | Out-Null
$boardArguments = @("-size", "${boardWidth}x${boardHeight}", "xc:#141B24")
$reviewFrames = [System.Collections.Generic.List[object]]::new()

try {
    for ($frameIndex = 0; $frameIndex -lt $orderedFrames.Count; $frameIndex++) {
        $frame = $orderedFrames[$frameIndex]
        $frameRoot = Join-Path $buildRoot ([string]$frame.id)
        $source = Join-Path $frameRoot "source.png"
        $mask = Join-Path $frameRoot "semantic-mask.png"
        foreach ($required in @($source, $mask, (Join-Path $frameRoot "reassembled.png"))) {
            if (-not [System.IO.File]::Exists($required)) {
                throw "Review input does not exist: $required"
            }
        }

        $logicalWidth = [int]$manifest.logical_size[0]
        $logicalHeight = [int]$manifest.logical_size[1]
        $reviewScale = [Math]::Max(1, [int][Math]::Floor($panelSize / [double][Math]::Max($logicalWidth, $logicalHeight)))
        $scaledWidth = $logicalWidth * $reviewScale
        $scaledHeight = $logicalHeight * $reviewScale
        $offsetX = [int][Math]::Floor(($panelSize - $scaledWidth) / 2.0)
        $offsetY = [int][Math]::Floor(($panelSize - $scaledHeight) / 2.0)
        $rowY = $frameIndex * ($panelSize + $panelGap)
        $panels = [System.Collections.Generic.List[object]]::new()

        $nativePanel = Join-Path $temporaryRoot "$($frame.id)-native.png"
        & $magick.Source -size "${panelSize}x${panelSize}" xc:"#2E3945" `
            $source -geometry "+$([int](($panelSize-$logicalWidth)/2))+$([int](($panelSize-$logicalHeight)/2))" `
            -compose over -composite -depth 8 -strip $nativePanel
        if ($LASTEXITCODE -ne 0) { throw "Could not build native review panel." }

        $scaled = Join-Path $temporaryRoot "$($frame.id)-scaled.png"
        & $magick.Source $source -filter point -resize "$($reviewScale * 100)%" $scaled
        if ($LASTEXITCODE -ne 0) { throw "Could not enlarge review source." }
        $pivotX = $offsetX + [int]$manifest.pivot[0] * $reviewScale
        $pivotY = $offsetY + [int]$manifest.pivot[1] * $reviewScale
        $anchorDraw = [System.Collections.Generic.List[string]]::new()
        foreach ($anchorProperty in @($manifest.anchors.PSObject.Properties)) {
            $anchor = @($anchorProperty.Value)
            $anchorX = $offsetX + [int]$anchor[0] * $reviewScale
            $anchorY = $offsetY + [int]$anchor[1] * $reviewScale
            $anchorDraw.Add("circle $anchorX,$anchorY $($anchorX+4),$anchorY")
        }
        $scaledPanel = Join-Path $temporaryRoot "$($frame.id)-anchors.png"
        $anchorPanelArguments = @(
            "-size", "${panelSize}x${panelSize}", "xc:#2E3945",
            $scaled, "-geometry", "+$offsetX+$offsetY", "-compose", "over", "-composite",
            "-stroke", "#D9A83D", "-strokewidth", "2", "-fill", "none",
            "-draw", "line $($pivotX-6),$pivotY $($pivotX+6),$pivotY line $pivotX,$($pivotY-6) $pivotX,$($pivotY+6)"
        )
        if ($anchorDraw.Count -gt 0) {
            $anchorPanelArguments += @("-stroke", "#65A9B8", "-draw", ($anchorDraw -join " "))
        }
        $anchorPanelArguments += @("-depth", "8", "-strip", $scaledPanel)
        & $magick.Source @anchorPanelArguments
        if ($LASTEXITCODE -ne 0) { throw "Could not build anchor review panel." }

        $silhouette = Join-Path $temporaryRoot "$($frame.id)-silhouette.png"
        & $magick.Source $source -channel A -separate +channel -threshold 0 -transparent black -fill white -colorize 100 $silhouette
        $silhouetteScaled = Join-Path $temporaryRoot "$($frame.id)-silhouette-scaled.png"
        & $magick.Source $silhouette -filter point -resize "$($reviewScale * 100)%" $silhouetteScaled
        $silhouettePanel = Join-Path $temporaryRoot "$($frame.id)-silhouette-panel.png"
        & $magick.Source -size "${panelSize}x${panelSize}" xc:"#141B24" `
            $silhouetteScaled -geometry "+$offsetX+$offsetY" -compose over -composite `
            -depth 8 -strip $silhouettePanel

        $grayscale = Join-Path $temporaryRoot "$($frame.id)-grayscale.png"
        & $magick.Source $source -colorspace gray -filter point -resize "$($reviewScale * 100)%" $grayscale
        $grayscalePanel = Join-Path $temporaryRoot "$($frame.id)-grayscale-panel.png"
        & $magick.Source -size "${panelSize}x${panelSize}" xc:"#2E3945" `
            $grayscale -geometry "+$offsetX+$offsetY" -compose over -composite `
            -depth 8 -strip $grayscalePanel

        $panelPaths = @($nativePanel, $scaledPanel, $silhouettePanel, $grayscalePanel)
        $panelKinds = @("native_1x", "enlarged_with_pivot", "silhouette", "grayscale")
        for ($backgroundIndex = 0; $backgroundIndex -lt $backgroundRoles.Count; $backgroundIndex++) {
            $role = [string]$backgroundRoles[$backgroundIndex]
            $color = [string]$palette.colors.$role
            $backgroundPanel = Join-Path $temporaryRoot "$($frame.id)-background-$role.png"
            & $magick.Source -size "${panelSize}x${panelSize}" "xc:$color" `
                $scaled -geometry "+$offsetX+$offsetY" -compose over -composite `
                -depth 8 -strip $backgroundPanel
            $panelPaths += $backgroundPanel
            $panelKinds += "background_$role"
        }

        for ($panelIndex = 0; $panelIndex -lt $panelPaths.Count; $panelIndex++) {
            $panelX = $panelIndex * ($panelSize + $panelGap)
            $boardArguments += @(
                $panelPaths[$panelIndex],
                "-geometry",
                "+$panelX+$rowY",
                "-compose",
                "over",
                "-composite"
            )
            $panels.Add([ordered]@{
                kind = $panelKinds[$panelIndex]
                region = @($panelX, $rowY, $panelSize, $panelSize)
            })
        }
        $reviewFrames.Add([ordered]@{
            id = [string]$frame.id
            source_sha256 = [string]$frame.source_sha256
            scale = $reviewScale
            pivot = @($manifest.pivot)
            anchors = $manifest.anchors
            panels = @($panels)
        })
    }

    $boardArguments += @("-depth", "8", "-strip", $destination)
    & $magick.Source @boardArguments
    if ($LASTEXITCODE -ne 0) {
        throw "ImageMagick failed to build the pixel asset review board."
    }
} finally {
    if ([System.IO.Directory]::Exists($temporaryRoot)) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}

$reviewMetadata = [ordered]@{
    schema_version = 1
    asset_id = [string]$manifest.id
    approval_status = [string]$manifest.approval_status
    review_path = $OutputPath.Replace("\", "/")
    board_size = @($boardWidth, $boardHeight)
    panel_size = $panelSize
    backgrounds = $backgroundRoles
    frames = @($reviewFrames)
}
$metadataPath = [System.IO.Path]::ChangeExtension($destination, ".json")
[System.IO.File]::WriteAllText(
    $metadataPath,
    ($reviewMetadata | ConvertTo-Json -Depth 10),
    [System.Text.UTF8Encoding]::new($false)
)

Write-Output "Pixel asset review built: $destination"
Write-Output "Frames=$($orderedFrames.Count); panels_per_frame=$panelCount"
