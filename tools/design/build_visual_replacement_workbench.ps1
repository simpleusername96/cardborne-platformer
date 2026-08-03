[CmdletBinding()]
param([switch]$Check)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot 'visual_replacement_workbench_model.psm1') -Force

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$workbenchRoot = Join-Path $repoRoot 'docs\design\visual-replacement-workbench'
$sourcePath = Join-Path $workbenchRoot 'replacement-workbench.json'
$templatePath = Join-Path $workbenchRoot 'index-template.html'
$inventoryPath = Join-Path $workbenchRoot 'inventory.json'
$indexPath = Join-Path $workbenchRoot 'index.html'

foreach ($required in @(
    $sourcePath,
    $templatePath,
    (Join-Path $repoRoot 'art\visuals\production\gameplay\asset-manifest.json'),
    (Join-Path $repoRoot 'art\visuals\production\ui\vehicle_stage_theme.tres')
)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "missing builder input: $required" }
}

$sourceText = Get-Content -LiteralPath $sourcePath -Raw
$prohibited = @(
    ('9b30' + '9ce'),
    ('semantic-v3-' + 'approval'),
    ('current-review-' + 'overrides'),
    ('review-' + 'images'),
    ('restore_visual_asset_' + 'inventory')
)
foreach ($needle in $prohibited) {
    if ($sourceText.Contains($needle)) { throw "active workbench source contains prohibited historical token: $needle" }
}
$source = $sourceText | ConvertFrom-Json -Depth 100
$uiRetirement = @($source.units | Where-Object { [string]$_.id -ceq 'ui_chrome_retirement' })
$uiManifestRequired = $uiRetirement.Count -eq 0 -or [string]$uiRetirement[0].status -eq 'switch_ready'
$uiManifestPath = Join-Path $repoRoot 'art\visuals\production\ui\ui-asset-manifest.json'
if ($uiManifestRequired -and -not (Test-Path -LiteralPath $uiManifestPath -PathType Leaf)) {
    throw "missing builder input: $uiManifestPath"
}
$projection = Get-VisualReplacementProjection -RepoRoot $repoRoot -Source $source
$inventoryText = Get-VisualCanonicalJson $projection
$templateText = (Get-Content -LiteralPath $templatePath -Raw).Replace("`r`n","`n").Replace("`r","`n")
if (($templateText.Split('__INVENTORY_JSON__').Count - 1) -ne 1) { throw 'index-template.html must contain exactly one __INVENTORY_JSON__ placeholder' }
foreach ($needle in $prohibited) {
    if ($templateText.Contains($needle)) { throw "active workbench template contains prohibited historical token: $needle" }
}
$embedded = $inventoryText.Replace('&','\u0026').Replace('<','\u003c').Replace('>','\u003e')
$indexText = $templateText.Replace('__INVENTORY_JSON__', $embedded)

if ($Check) {
    $failures = @()
    if (-not (Test-Path $inventoryPath -PathType Leaf) -or (Get-Content $inventoryPath -Raw).Replace("`r`n","`n").TrimEnd("`n") -cne $inventoryText) { $failures += 'inventory.json differs from deterministic output' }
    if (-not (Test-Path $indexPath -PathType Leaf) -or (Get-Content $indexPath -Raw).Replace("`r`n","`n").TrimEnd("`n") -cne $indexText.TrimEnd("`n")) { $failures += 'index.html differs from deterministic output' }
    if ($failures.Count) { throw ($failures -join "`n") }
    Write-Host "VISUAL_REPLACEMENT_WORKBENCH_CHECK_OK units=$($projection.summary.units) media=$($projection.summary.gameplay_png + $projection.summary.ui_png + $projection.summary.font)"
    exit 0
}

Write-VisualUtf8Lf -LiteralPath $inventoryPath -Text $inventoryText
Write-VisualUtf8Lf -LiteralPath $indexPath -Text $indexText
Write-Host "VISUAL_REPLACEMENT_WORKBENCH_BUILD_OK units=$($projection.summary.units) gameplay=$($projection.summary.gameplay_png) ui=$($projection.summary.ui_png) font=$($projection.summary.font)"
