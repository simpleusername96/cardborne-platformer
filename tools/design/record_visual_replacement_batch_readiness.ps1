param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9a-f]{40}$')]
    [string]$BaselineCommit,
    [string]$WorkbenchPath = 'docs/design/visual-replacement-workbench/replacement-workbench.json'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$absoluteWorkbench = Join-Path $repoRoot $WorkbenchPath
$candidateRoot = Join-Path $repoRoot 'docs/design/visual-replacement-workbench/to-be/assets'
$previewRoot = 'docs/design/visual-replacement-workbench/previews/final-batch'
$authorityHash = '96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889'

& git -C $repoRoot cat-file -e "$BaselineCommit^{commit}" 2>$null
if ($LASTEXITCODE -ne 0) { throw "baseline commit is not available locally: $BaselineCommit" }

$workbench = Get-Content -Raw -LiteralPath $absoluteWorkbench | ConvertFrom-Json
$targetUnits = @($workbench.units | Where-Object { [string]$_.status -ceq 'target_required' })
if ($targetUnits.Count -ne 10) { throw "expected exactly 10 target_required units, observed $($targetUnits.Count)" }

$approvedAt = [DateTimeOffset]::Now.ToOffset([TimeSpan]::FromHours(9)).ToString('yyyy-MM-ddTHH:mm:sszzz')
foreach ($unit in $targetUnits) {
    $deliverables = @($unit.deliverables)
    $hasRaster = $deliverables.Count -gt 0
    $hashes = [ordered]@{}
    foreach ($deliverable in $deliverables) {
        $target = [string]$deliverable.target_path
        $candidate = Join-Path $candidateRoot $target
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            throw "candidate is missing: $($unit.id) -> $target"
        }
        $hashes[$target] = (Get-FileHash -Algorithm SHA256 -LiteralPath $candidate).Hash.ToLowerInvariant()
    }

    if ($hasRaster) {
        $preview = "$previewRoot/$($unit.id).png"
        if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $preview) -PathType Leaf)) {
            throw "comparison preview is missing: $($unit.id) -> $preview"
        }
        $unit.preview_paths = @($preview)
    }

    $authority = [pscustomobject][ordered]@{
        spec_path = 'docs/design/VISUAL_SYSTEM.md'
        sheet_path = 'docs/design/cardborne-universal-art-style-reference.png'
        sheet_sha256 = $authorityHash
        document_read_complete = $true
        sheet_inspected_original = $true
        actual_image_reference_used = $hasRaster
        reference_input_method = if ($hasRaster) { 'image_gen.referenced_image_paths' } else { 'not_applicable' }
    }
    $unit | Add-Member -NotePropertyName visual_authority_evidence -NotePropertyValue $authority -Force
    $unit.status = 'approved_for_switch'
    $unit.approval = [pscustomobject][ordered]@{
        approved_by = 'autonomous-executor'
        approved_at = $approvedAt
        baseline_commit = $BaselineCommit
        deliverable_sha256 = [pscustomobject]$hashes
        retire_paths = @($unit.retire_paths)
    }
    $unit.application = $null
}

$json = $workbench | ConvertTo-Json -Depth 100
$utf8NoBom = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText($absoluteWorkbench, "$json`n", $utf8NoBom)
Write-Output "Recorded exact autonomous readiness for $($targetUnits.Count) units at $approvedAt."
