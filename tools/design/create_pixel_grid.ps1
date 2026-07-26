param(
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [ValidateRange(64, 2048)]
    [int]$CanvasSize = 512,

    [ValidateRange(4, 128)]
    [int]$Cells = 32,

    [ValidateRange(1, 32)]
    [int]$MajorEvery = 4
)

$ErrorActionPreference = "Stop"

if ($CanvasSize % $Cells -ne 0) {
    throw "CanvasSize must be exactly divisible by Cells."
}

$magick = Get-Command magick -ErrorAction Stop
$cellSize = [int]($CanvasSize / $Cells)
$lastPixel = $CanvasSize - 1

$minorLines = [System.Collections.Generic.List[string]]::new()
$majorLines = [System.Collections.Generic.List[string]]::new()

for ($index = 0; $index -lt $Cells; $index++) {
    $position = $index * $cellSize
    if ($index % $MajorEvery -eq 0) {
        $majorLines.Add("line $position,0 $position,$lastPixel")
        $majorLines.Add("line 0,$position $lastPixel,$position")
    } else {
        $minorLines.Add("line $position,0 $position,$lastPixel")
        $minorLines.Add("line 0,$position $lastPixel,$position")
    }
}

# Close the right and bottom edges inside the raster bounds.
$majorLines.Add("line $lastPixel,0 $lastPixel,$lastPixel")
$majorLines.Add("line 0,$lastPixel $lastPixel,$lastPixel")

$destination = [System.IO.Path]::GetFullPath($OutputPath)
$destinationDirectory = [System.IO.Path]::GetDirectoryName($destination)
if (-not [System.IO.Directory]::Exists($destinationDirectory)) {
    [System.IO.Directory]::CreateDirectory($destinationDirectory) | Out-Null
}

& $magick.Source `
    -size "${CanvasSize}x${CanvasSize}" `
    "xc:#FFFFFF" `
    -fill none `
    -stroke "#D9DEE5" `
    -strokewidth 1 `
    -draw ($minorLines -join " ") `
    -stroke "#8C9CAD" `
    -strokewidth 2 `
    -draw ($majorLines -join " ") `
    -depth 8 `
    $destination

if ($LASTEXITCODE -ne 0) {
    throw "ImageMagick failed to create the pixel grid."
}

Write-Output "Created ${CanvasSize}x${CanvasSize} grid: ${Cells}x${Cells} cells, ${cellSize}px per cell -> $destination"
