param(
    [string]$OutputPath = "docs/design/pixel-space-hangar-visual-research/references/cc0/cc0-reference-contact-sheet.png"
)

$ErrorActionPreference = "Stop"

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$destination = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutputPath))
$magick = Get-Command magick -ErrorAction Stop
$inputs = @(
    "docs/design/pixel-space-hangar-visual-research/references/cc0/samples/kenney-pixel-shmup/Tilemap/ships.png",
    "docs/design/pixel-space-hangar-visual-research/references/cc0/samples/kenney-pixel-shmup/Tilemap/tiles.png",
    "docs/design/pixel-space-hangar-visual-research/references/cc0/original/oga-top-down-space-fighter.png",
    "docs/design/pixel-space-hangar-visual-research/references/cc0/original/oga-spaceships-with-engines.png",
    "docs/design/pixel-space-hangar-visual-research/references/cc0/original/oga-scifi-platform-tiles-16x16.png",
    "docs/design/pixel-space-hangar-visual-research/references/cc0/original/oga-scifi-bg-chip.png",
    "docs/design/pixel-space-hangar-visual-research/references/cc0/samples/oga-ui-minimal-scifi/MainPanel01.png",
    "docs/design/pixel-space-hangar-visual-research/references/cc0/samples/oga-ui-minimal-scifi/Button01.png"
)

$resolvedInputs = [System.Collections.Generic.List[string]]::new()
foreach ($inputPath in $inputs) {
    $resolved = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $inputPath))
    if (-not [System.IO.File]::Exists($resolved)) {
        throw "Reference input does not exist: $resolved"
    }
    $resolvedInputs.Add($resolved)
}

$destinationDirectory = [System.IO.Path]::GetDirectoryName($destination)
if (-not [System.IO.Directory]::Exists($destinationDirectory)) {
    [System.IO.Directory]::CreateDirectory($destinationDirectory) | Out-Null
}

$arguments = @("montage")
$arguments += @($resolvedInputs)
$arguments += @(
    "-thumbnail", "360x220",
    "-background", "#081F2B",
    "-fill", "#FFF6DC",
    "-stroke", "none",
    "-font", "Arial",
    "-pointsize", "14",
    "-set", "label", "%t",
    "-tile", "4x2",
    "-geometry", "388x276+12+12",
    "-depth", "8",
    "-strip",
    $destination
)
& $magick.Source @arguments
if ($LASTEXITCODE -ne 0) {
    throw "ImageMagick failed to create the CC0 reference contact sheet."
}

$geometry = (& $magick.Source identify -format "%wx%h" $destination).Trim()
if ($geometry -ne "1648x640") {
    throw "Reference contact sheet must be 1648x640; got $geometry."
}

Write-Output "Created CC0 reference contact sheet -> $destination"
