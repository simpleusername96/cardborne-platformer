[CmdletBinding(PositionalBinding = $false)]
param(
  [string] $LedgerPath = 'docs/performance/vehicle-performance-evidence.jsonl'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$ledger = Join-Path $repoRoot $LedgerPath
if (-not (Test-Path -LiteralPath $ledger -PathType Leaf)) { throw "Missing evidence ledger: $LedgerPath" }
$seen = [Collections.Generic.HashSet[string]]::new()
$lineNumber = 0
foreach ($line in Get-Content -LiteralPath $ledger) {
  $lineNumber++
  if ([string]::IsNullOrWhiteSpace($line)) { continue }
  try { $entry = $line | ConvertFrom-Json -AsHashtable } catch { throw "Invalid JSONL at line $lineNumber" }
  foreach ($field in @('evidence_id','artifact_kind','status','commit','content_fingerprint','scenario','authority_eligible','thresholds_passed')) {
    if (-not $entry.ContainsKey($field)) { throw "Ledger line $lineNumber is missing $field" }
  }
  if ([string]$entry.evidence_id -notmatch '^[a-z0-9][a-z0-9._-]+$' -or -not $seen.Add([string]$entry.evidence_id)) { throw "Ledger line $lineNumber has a duplicate or invalid evidence_id" }
  if ([string]$entry.commit -notmatch '^[0-9a-f]{40}$') { throw "Ledger line $lineNumber has no full commit" }
  if ([string]$entry.content_fingerprint -notmatch '^[0-9a-f]{64}$') { throw "Ledger line $lineNumber has no content fingerprint" }
  if ([string]$entry.status -notin @('authoritative_pass','authoritative_fail','diagnostic','invalid')) { throw "Ledger line $lineNumber has an invalid status" }
  if ([bool]$entry.authority_eligible -and ([string]$entry.status -notmatch '^authoritative_')) { throw "Ledger line $lineNumber conflates authority with status" }
  foreach ($artifact in @($entry.artifacts)) {
    foreach ($field in @('path','sha256','bytes')) { if (-not $artifact.ContainsKey($field)) { throw "Ledger line $lineNumber artifact is missing $field" } }
    if ([string]$artifact.sha256 -notmatch '^[0-9a-f]{64}$' -or [int64]$artifact.bytes -lt 1) { throw "Ledger line $lineNumber has invalid artifact integrity" }
  }
}
Write-Output "VEHICLE_EVIDENCE_LEDGER_VALIDATION_OK"
