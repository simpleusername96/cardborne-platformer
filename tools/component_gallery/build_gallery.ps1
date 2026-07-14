[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$sourceDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $sourceDirectory "..\.."))
$runtimeRoot = [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot ".codex-runtime"))
$outputDirectory = [System.IO.Path]::GetFullPath((Join-Path $runtimeRoot "component-gallery"))
$assetOutputDirectory = Join-Path $outputDirectory "assets"

if (-not $outputDirectory.StartsWith($runtimeRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to write the gallery outside the repository runtime directory."
}

New-Item -ItemType Directory -Force -Path $assetOutputDirectory | Out-Null

foreach ($fileName in @("index.html", "styles.css", "gallery.js")) {
    Copy-Item -LiteralPath (Join-Path $sourceDirectory $fileName) -Destination (Join-Path $outputDirectory $fileName) -Force
}

Copy-Item `
    -LiteralPath (Join-Path $sourceDirectory "assets\flooded-works-panorama-preview.png") `
    -Destination (Join-Path $assetOutputDirectory "flooded-works-panorama-preview.png") `
    -Force

$entryPath = Join-Path $outputDirectory "index.html"
Write-Host "Component gallery built: $entryPath"
