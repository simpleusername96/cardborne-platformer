[CmdletBinding(PositionalBinding = $false)]
param(
  [Parameter(Mandatory = $true)] [string] $EvidenceId,
  [Parameter(Mandatory = $true)] [string] $RawPath,
  [Parameter(Mandatory = $true)] [string] $PlanCheckpoint
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
if ($EvidenceId -notmatch '^[a-z0-9][a-z0-9._-]+$') { throw 'EvidenceId must be a stable lowercase identifier.' }
$raw = (Resolve-Path -LiteralPath $RawPath).Path
if (-not (Test-Path -LiteralPath $raw -PathType Leaf)) { throw "Raw evidence is missing: $RawPath" }
try { $record = Get-Content -Raw -LiteralPath $raw | ConvertFrom-Json -AsHashtable } catch { throw 'Raw evidence is not JSON.' }
$identity = $record.build_identity
$provenance = $record.provenance
if ($null -eq $identity -or $null -eq $provenance -or [string]$identity.commit -notmatch '^[0-9a-f]{40}$' -or [string]$identity.content_fingerprint -notmatch '^[0-9a-f]{64}$') { throw 'Raw evidence lacks a complete provenance envelope.' }
$destinationDirectory = Join-Path $repoRoot 'docs\performance\evidence'
$destination = Join-Path $destinationDirectory "$EvidenceId.json"
$ledger = Join-Path $repoRoot 'docs\performance\vehicle-performance-evidence.jsonl'
if ((Test-Path -LiteralPath $destination) -or (Select-String -LiteralPath $ledger -SimpleMatch "`"evidence_id`":`"$EvidenceId`"" -Quiet -ErrorAction SilentlyContinue)) { throw "Evidence ID already exists: $EvidenceId" }
New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
Copy-Item -LiteralPath $raw -Destination $destination
$artifact = Get-Item -LiteralPath $destination
$entry = [ordered]@{
  evidence_id = $EvidenceId
  artifact_kind = [string]$provenance.artifact_kind
  status = [string]$provenance.status
  commit = [string]$identity.commit
  content_fingerprint = [string]$identity.content_fingerprint
  scenario = [string]$provenance.scenario
  authority_eligible = [bool]$provenance.authority_eligible
  thresholds_passed = [bool]$provenance.thresholds_passed
  plan_checkpoint = $PlanCheckpoint
  artifacts = @([ordered]@{ path = "docs/performance/evidence/$EvidenceId.json"; sha256 = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant(); bytes = [int64]$artifact.Length })
}
Add-Content -LiteralPath $ledger -Value ($entry | ConvertTo-Json -Compress)
Write-Output "VEHICLE_EVIDENCE_PROMOTED $EvidenceId"
