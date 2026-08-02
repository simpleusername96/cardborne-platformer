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
Expect ($reportText.Contains("min-width: 1540px;")) "ledger column-width contract is missing"
Expect ($data.restoration.source_commit -eq "9b309ce") "unexpected restoration source commit"
Expect ($data.file_ledger.Count -eq 305) "file ledger must contain 305 current/staged records"
Expect ($data.summary.runtime_visual_files_including_font -eq 297) "runtime visual total must remain 297"

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
    "VISUAL_ASSET_INVENTORY_VALIDATION_OK ledger={0} rendered_media={1} review_images={2}" -f
        $data.file_ledger.Count,
        $renderedPaths.Count,
        $reviewImages.Count
)
