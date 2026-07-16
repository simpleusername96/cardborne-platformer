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

$godotRunner = Join-Path $repositoryRoot "tools\godot.ps1"
& $godotRunner --path $repositoryRoot --headless --script res://tools/report_stage_visual_coverage.gd
if ($LASTEXITCODE -ne 0) {
    throw "Stage visual coverage report failed."
}

New-Item -ItemType Directory -Force -Path $assetOutputDirectory | Out-Null
foreach ($fileName in @("index.html", "styles.css", "gallery.js")) {
    Copy-Item -LiteralPath (Join-Path $sourceDirectory $fileName) -Destination (Join-Path $outputDirectory $fileName) -Force
}

$assetMap = [ordered]@{
    "panel-01.png" = "art\world\flooded_works\backgrounds\panel_01.png"
    "panel-02.png" = "art\world\flooded_works\backgrounds\panel_02.png"
    "terrain-solid-320x100.png" = "art\world\flooded_works\terrain\solid_320x100.png"
    "terrain-solid-240x100.png" = "art\world\flooded_works\terrain\solid_240x100.png"
    "terrain-solid-240x140.png" = "art\world\flooded_works\terrain\solid_240x140.png"
    "terrain-solid-240x180.png" = "art\world\flooded_works\terrain\solid_240x180.png"
    "terrain-oneway-720x12.png" = "art\world\flooded_works\terrain\oneway_720x12.png"
    "vent-base.png" = "art\world\flooded_works\components\poison_vent\base.png"
    "vent-warning.png" = "art\world\flooded_works\components\poison_vent\warning_overlay.png"
    "vent-active.png" = "art\world\flooded_works\components\poison_vent\active_overlay.png"
    "vent-cooldown.png" = "art\world\flooded_works\components\poison_vent\cooldown_overlay.png"
    "crumble-base.png" = "art\world\flooded_works\components\crumbling_platform\base.png"
    "crumble-warning.png" = "art\world\flooded_works\components\crumbling_platform\warning_overlay.png"
    "crumble-disabled.png" = "art\world\flooded_works\components\crumbling_platform\disabled_overlay.png"
    "crumble-respawning.png" = "art\world\flooded_works\components\crumbling_platform\respawning_overlay.png"
    "flooded-poison-baseline.png" = "tools\component_gallery\assets\flooded-poison-baseline.png"
    "flooded-poison-proof.png" = "tools\component_gallery\assets\flooded-poison-proof.png"
    "flooded-poison-debug.png" = "tools\component_gallery\assets\flooded-poison-debug.png"
}

foreach ($entry in $assetMap.GetEnumerator()) {
    $sourcePath = Join-Path $repositoryRoot $entry.Value
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Gallery asset is missing: $sourcePath"
    }
    Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $assetOutputDirectory $entry.Key) -Force
}

$reportPath = Join-Path $runtimeRoot "reports\stage_visual_coverage.json"
$report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
$flooded = $report.stages | Where-Object { $_.id -eq "flooded_works" } | Select-Object -First 1
if ($null -eq $flooded) {
    throw "Flooded Works coverage is absent from the generated report."
}
$galleryData = [ordered]@{
    viewportEnvelope = $report.viewport_envelope
    totalInitialPanelCount = $report.total_initial_panel_count
    flooded = $flooded
}
$coverageScript = "window.CARDBORNE_VISUAL_COVERAGE = " + ($galleryData | ConvertTo-Json -Depth 12 -Compress) + ";`n"
[System.IO.File]::WriteAllText(
    (Join-Path $outputDirectory "coverage-data.js"),
    $coverageScript,
    [System.Text.UTF8Encoding]::new($false)
)

$entryPath = Join-Path $outputDirectory "index.html"
Write-Host "Component gallery built: $entryPath"
