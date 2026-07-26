param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter(Mandatory = $true)]
    [string]$PalettePath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [ValidateRange(64, 2048)]
    [int]$CanvasSize = 512,

    [ValidateRange(4, 128)]
    [int]$Cells = 32,

    [ValidatePattern("^#[0-9A-Fa-f]{6}$")]
    [string]$TransparentColor = "#FFFFFF",

    [switch]$KeepBackground
)

$ErrorActionPreference = "Stop"

if ($CanvasSize % $Cells -ne 0) {
    throw "CanvasSize must be exactly divisible by Cells."
}

$source = [System.IO.Path]::GetFullPath($InputPath)
$palette = [System.IO.Path]::GetFullPath($PalettePath)
$destination = [System.IO.Path]::GetFullPath($OutputPath)

if (-not [System.IO.File]::Exists($source)) {
    throw "Input image does not exist: $source"
}
if (-not [System.IO.File]::Exists($palette)) {
    throw "Palette image does not exist: $palette"
}

$destinationDirectory = [System.IO.Path]::GetDirectoryName($destination)
if (-not [System.IO.Directory]::Exists($destinationDirectory)) {
    [System.IO.Directory]::CreateDirectory($destinationDirectory) | Out-Null
}

$magick = Get-Command magick -ErrorAction Stop
$magickArguments = @(
    $source,
    "-resize", "${CanvasSize}x${CanvasSize}!",
    "-filter", "point",
    "-resize", "${Cells}x${Cells}!",
    "+dither",
    "-remap", $palette
)
if (-not $KeepBackground) {
    $magickArguments += @("-transparent", $TransparentColor)
}
$magickArguments += @("-depth", "8", $destination)

& $magick.Source @magickArguments

if ($LASTEXITCODE -ne 0) {
    throw "ImageMagick failed to snap the generated image to the logical grid."
}

Write-Output "Snapped image to ${Cells}x${Cells} logical cells from a ${CanvasSize}px template -> $destination"
