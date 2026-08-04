[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9a-f]{40}$')]
    [string]$AppliedCommit,
    [string]$WorkbenchPath = 'docs/design/visual-replacement-workbench/replacement-workbench.json'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$absoluteWorkbench = Join-Path $repoRoot $WorkbenchPath
& git -C $repoRoot cat-file -e "$AppliedCommit^{commit}" 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "Applied commit is not available locally: $AppliedCommit"
}

$workbench = Get-Content -Raw -LiteralPath $absoluteWorkbench | ConvertFrom-Json -Depth 100
$units = @($workbench.units | Where-Object { [string]$_.status -ceq 'approved_for_switch' })
if ($units.Count -ne 10) {
    throw "Expected exactly 10 approved units, observed $($units.Count)."
}
$appliedAt = [DateTimeOffset]::Now.ToOffset([TimeSpan]::FromHours(9)).ToString('yyyy-MM-ddTHH:mm:sszzz')
$evidence = @(
    '.\tools\design\promote_visual_replacement_unit.ps1 -AllApproved -Apply',
    '.\tools\design\retire_visual_replacement_batch.ps1 -Apply',
    'production gameplay PNG reconciliation: exactly 49',
    '.\tools\design\build_visual_replacement_workbench.ps1 -Check'
)
foreach ($unit in $units) {
    $unit.status = if ([string]$unit.switch_kind -ceq 'retire') { 'retired' } else { 'applied' }
    $unit.application = [pscustomobject][ordered]@{
        commit = $AppliedCommit
        applied_at = $appliedAt
        validation_evidence = $evidence
    }
}

$json = $workbench | ConvertTo-Json -Depth 100
$utf8NoBom = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText($absoluteWorkbench, "$json`n", $utf8NoBom)
Write-Output "VISUAL_BATCH_APPLICATION_RECORDED units=10 commit=$AppliedCommit applied_at=$appliedAt"
