[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Import-Module (
    Join-Path $PSScriptRoot "..\design\visual_asset_inventory_model.psm1"
) -Force

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$inventoryRoot = Join-Path $repoRoot "docs\design\visual-asset-inventory"
$reportPath = Join-Path $inventoryRoot "index.html"
$dataPath = Join-Path $inventoryRoot "inventory.json"
$readmePath = Join-Path $inventoryRoot "README.md"
$templatePath = Join-Path $inventoryRoot "report-template.html"
$currentReviewOverlayPath = Join-Path $inventoryRoot "current-review-overrides.json"
$failures = [System.Collections.Generic.List[string]]::new()

function Expect {
    param(
        [Parameter(Mandatory)] [bool]$Condition,
        [Parameter(Mandatory)] [string]$Message
    )

    if (-not $Condition) {
        $failures.Add($Message)
    }
}

function Resolve-RepositoryPath {
    param([Parameter(Mandatory)] [string]$Path)

    return Join-Path $repoRoot ($Path.Replace('/', '\'))
}

Expect (Test-Path -LiteralPath $reportPath -PathType Leaf) "missing report: $reportPath"
Expect (Test-Path -LiteralPath $dataPath -PathType Leaf) "missing inventory data: $dataPath"
Expect (Test-Path -LiteralPath $readmePath -PathType Leaf) "missing evidence README: $readmePath"
Expect (Test-Path -LiteralPath $templatePath -PathType Leaf) "missing report template: $templatePath"
Expect (Test-Path -LiteralPath $currentReviewOverlayPath -PathType Leaf) (
    "missing current review overlay: $currentReviewOverlayPath"
)
if ($failures.Count -gt 0) {
    foreach ($failure in $failures) { Write-Error $failure }
    exit 1
}

$jsonText = Get-Content -Raw -LiteralPath $dataPath
$data = $jsonText | ConvertFrom-Json -Depth 100
$reportText = Get-Content -Raw -LiteralPath $reportPath
$match = [System.Text.RegularExpressions.Regex]::Match(
    $reportText,
    '(?s)<script id="inventory-data" type="application/json">(.*?)</script>'
)
Expect $match.Success "report does not contain embedded inventory data"
if ($match.Success) {
    $embedded = $match.Groups[1].Value | ConvertFrom-Json -Depth 100
    $canonicalJson = $data | ConvertTo-Json -Depth 100 -Compress
    $embeddedJson = $embedded | ConvertTo-Json -Depth 100 -Compress
    Expect ($canonicalJson -ceq $embeddedJson) "report embedded data differs from inventory.json"
}

Expect ($reportText.Contains("var reportPrefix = '../../../';")) "report root prefix is incorrect"
Expect ($reportText.Contains("복원된 검토 스냅샷")) "report lacks restored-evidence warning"
Expect ($reportText.Contains("min-width: 1280px;")) "ledger column-width contract is missing"
Expect ($reportText.Contains("Cardborne 비주얼 자산 검토표")) "report title is not simplified"
Expect (-not $reportText.Contains('id="decision-selector"')) "standalone decision selector must not return"
Expect (-not $reportText.Contains('id="animation-grid"')) "duplicate animation catalog must not return"
Expect (-not $reportText.Contains('id="ui-component-grid"')) "duplicate UI catalog must not return"
Expect (-not $reportText.Contains('id="staged-grid"')) "duplicate staged catalog must not return"
Expect ($data.restoration.source_commit -eq "9b309ce") "unexpected restoration source commit"
Expect (
    $data.restoration.current_review_overlay -eq
        "docs/design/visual-asset-inventory/current-review-overrides.json"
) "current review overlay provenance is missing"
Expect ($data.file_ledger.Count -eq 305) "file ledger must contain 305 current/staged records"
Expect ($data.summary.runtime_visual_files_including_font -eq 297) "runtime visual total must remain 297"

$currentCandidateIds = @("player_hull_aim", "player_engine", "player_minimap_marker")
foreach ($candidateId in $currentCandidateIds) {
    $matches = @($data.visual_system_units | Where-Object { $_.id -ceq $candidateId })
    Expect ($matches.Count -eq 1) "current candidate unit must exist exactly once: $candidateId"
    if ($matches.Count -ne 1) {
        continue
    }
    $candidate = $matches[0]
    Expect ($candidate.tobe.action -ceq "CANDIDATE_AVAILABLE") (
        "current candidate must be guide-only: $candidateId"
    )
    Expect ([string]$candidate.decision_label -like "*승인 전*") (
        "current candidate must remain explicitly unapproved: $candidateId"
    )
    Expect ([string]$candidate.target_direction -like "AS-IS runtime*") (
        "current candidate must explicitly retain AS-IS runtime: $candidateId"
    )
}
$playerMarkerRecords = @($data.file_ledger | Where-Object { $_.id -ceq "raster-203" })
Expect (
    $playerMarkerRecords.Count -eq 1 -and
        $playerMarkerRecords[0].system_unit_id -ceq "player_minimap_marker"
) "player minimap marker must belong only to player_minimap_marker"
$nonPlayerMarkerUnit = @(
    $data.visual_system_units | Where-Object { $_.id -ceq "hud_and_minimap_dynamic" }
)
Expect (
    $nonPlayerMarkerUnit.Count -eq 1 -and
        "raster-203" -notin @($nonPlayerMarkerUnit[0].ledger_ids)
) "player marker must not remain duplicated in the non-player minimap group"

$taxonomy = $null
$taxonomyMatch = [System.Text.RegularExpressions.Regex]::Match(
    $reportText,
    '(?s)<script id="report-taxonomy" type="application/json">(.*?)</script>'
)
Expect $taxonomyMatch.Success "report does not contain the hierarchical taxonomy"
if ($taxonomyMatch.Success) {
    $taxonomy = $taxonomyMatch.Groups[1].Value | ConvertFrom-Json -Depth 20
    $classifiedIds = @(
        $taxonomy.categories | ForEach-Object {
            $_.groups | ForEach-Object { @($_.unit_ids) }
        }
    )
    $uniqueClassifiedIds = @($classifiedIds | Sort-Object -Unique)
    $sourceUnitIds = @($data.visual_system_units.id | Sort-Object -Unique)
    $taxonomyDifference = @(Compare-Object $sourceUnitIds $uniqueClassifiedIds)
    Expect ($taxonomy.categories.Count -eq 5) "report taxonomy must contain five clear top-level categories"
    Expect ($classifiedIds.Count -eq $data.visual_system_units.Count) (
        "taxonomy item count differs: taxonomy=$($classifiedIds.Count) data=$($data.visual_system_units.Count)"
    )
    Expect ($uniqueClassifiedIds.Count -eq $classifiedIds.Count) "a visual unit appears more than once in taxonomy"
    Expect ($taxonomyDifference.Count -eq 0) "taxonomy and visual system unit IDs differ"
}

$actionCounts = @{ keep = 0; guide = 0; missing = 0 }
$actionBySource = @{}
if ($null -ne $taxonomy) {
    $actionIds = @($taxonomy.actions.id | Sort-Object)
    Expect (($actionIds -join ',') -ceq 'guide,keep,missing') "report must define exactly three action states"
    foreach ($definition in @($taxonomy.actions)) {
        foreach ($sourceAction in @($definition.source_actions)) {
            Expect (-not $actionBySource.ContainsKey([string]$sourceAction)) (
                "source action appears in more than one report state: $sourceAction"
            )
            $actionBySource[[string]$sourceAction] = [string]$definition.id
        }
    }
}
$assetUnits = @($data.visual_system_units | Where-Object { @($_.ledger_ids).Count -gt 0 })
foreach ($unit in $assetUnits) {
    $action = [string]$unit.tobe.action
    if (-not $actionBySource.ContainsKey($action)) {
        $failures.Add("visual unit has an unclassified source action: $($unit.id) -> $action")
        continue
    }
    $reportAction = [string]$actionBySource[$action]
    $actionCounts[$reportAction] += 1
    if ($reportAction -eq 'guide') {
        Expect (@($unit.tobe.images).Count -gt 0) "guide-ready unit lacks a TO-BE image: $($unit.id)"
    }
    elseif ($reportAction -eq 'missing') {
        Expect (@($unit.tobe.images).Count -eq 0) "guide-missing unit unexpectedly exposes a TO-BE image: $($unit.id)"
    }
}
Expect ($assetUnits.Count -eq 26) "report must contain exactly 26 file-backed asset groups"
Expect ($actionCounts.keep -eq 7) "keep count must remain 7"
Expect ($actionCounts.guide -eq 11) "guide-ready count must remain 11"
Expect ($actionCounts.missing -eq 8) "guide-missing count must remain 8"

$templateText = Get-Content -Raw -LiteralPath $templatePath
Expect (($templateText.Split("__INVENTORY_JSON__").Count - 1) -eq 1) (
    "report template must contain exactly one inventory placeholder"
)
$expectedEmbeddedJson = ($data | ConvertTo-Json -Depth 100 -Compress).
    Replace('&', '\u0026').Replace('<', '\u003c').Replace('>', '\u003e')
$expectedReportText = $templateText.Replace("__INVENTORY_JSON__", $expectedEmbeddedJson).
    TrimEnd([char[]]"`r`n") + "`n"
Expect ($reportText -ceq $expectedReportText) (
    "generated report differs from report-template.html plus inventory.json"
)

$renderedPaths = Get-VisualAssetInventoryRenderedMediaPaths -Data $data
foreach ($path in $renderedPaths) {
    if ($path -notmatch '^(docs|art)/') {
        continue
    }
    Expect (Test-Path -LiteralPath (Resolve-RepositoryPath -Path $path) -PathType Leaf) (
        "missing rendered media: $path"
    )
}

$reviewImages = @(Get-ChildItem -LiteralPath (Join-Path $inventoryRoot "review-images") -File -Recurse)
Expect ($reviewImages.Count -eq [int]$data.restoration.review_image_count) (
    "review image count differs: files=$($reviewImages.Count) data=$($data.restoration.review_image_count)"
)

foreach ($record in @($data.file_ledger)) {
    $absolutePath = Resolve-RepositoryPath -Path $record.path
    if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
        $failures.Add("missing ledger file: $($record.path)")
        continue
    }
    $actualHash = (Get-FileHash -LiteralPath $absolutePath -Algorithm SHA256).Hash.ToLowerInvariant()
    Expect ($actualHash -ceq [string]$record.sha256) "ledger hash mismatch: $($record.path)"
}

$readmeText = Get-Content -Raw -LiteralPath $readmePath
Expect ($readmeText.StartsWith("---`ntype: evidence`nstatus: active")) "README lifecycle frontmatter is invalid"
Expect ($readmeText.Contains("승인안이 아닙니다")) "README must distinguish evidence from approval"

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Error $failure
    }
    exit 1
}

Write-Host (
    "VISUAL_ASSET_INVENTORY_VALIDATION_OK ledger={0} review_items={1} actions={2}/{3}/{4} evidence_media={5} review_images={6}" -f
        $data.file_ledger.Count,
        $assetUnits.Count,
        $actionCounts.keep,
        $actionCounts.guide,
        $actionCounts.missing,
        $renderedPaths.Count,
        $reviewImages.Count
)
