[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$compare = Join-Path $PSScriptRoot 'compare_vehicle_diagnostic_bundles.ps1'
$testDirectory = Join-Path ([IO.Path]::GetTempPath()) (
  'cardborne-diagnostic-comparison-' + [Guid]::NewGuid().ToString('N')
)
New-Item -ItemType Directory -Path $testDirectory | Out-Null

try {
  $identity = [ordered]@{
    commit = 'a' * 40
    content_fingerprint = 'b' * 64
  }
  $context = [ordered]@{
    locale = 'ko'
    viewport_class = 'standard'
    reduced_motion = $false
    renderer = 'gl_compatibility'
  }
  $events = @(
    @{ sequence = 1; monotonic_seconds = 0.0; kind = 'stage_started'; fields = @{ stage_index = 0 } },
    @{ sequence = 2; monotonic_seconds = 1.2; kind = 'first_visible'; fields = @{ stage_index = 0 } },
    @{ sequence = 3; monotonic_seconds = 8.0; kind = 'boss_warning'; fields = @{ stage_index = 0 } },
    @{ sequence = 4; monotonic_seconds = 9.0; kind = 'visible_gap_closed'; fields = @{ stage_index = 0; gap_seconds = 0.8 } },
    @{ sequence = 5; monotonic_seconds = 10.0; kind = 'announcement_shown'; fields = @{ semantic_id = 'boss_inbound' } },
    @{ sequence = 6; monotonic_seconds = 10.5; kind = 'anomaly_activated'; fields = @{ effect_id = 'gravity_pull'; affected_count = 4 } },
    @{ sequence = 7; monotonic_seconds = 12.0; kind = 'boss_ended'; fields = @{ stage_index = 0 } },
    @{ sequence = 8; monotonic_seconds = 13.0; kind = 'upgrade_focused'; fields = @{ upgrade_id = 'thermal_burst' } },
    @{ sequence = 9; monotonic_seconds = 13.2; kind = 'upgrade_confirmed'; fields = @{ upgrade_id = 'thermal_burst' } }
  )
  $bundle = [ordered]@{
    schema_version = 1
    kind = 'session_diagnostic'
    registry_version = 1
    build_identity = $identity
    session_context = $context
    events = $events
    one_hz = @(@{ max_frame_ms = 35.0 })
    slow_tick_receipts = @(@{ total_ms = 12.5 })
  }
  $leftPath = Join-Path $testDirectory 'left.json'
  $rightPath = Join-Path $testDirectory 'right.json'
  $bundle | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $leftPath
  $bundle | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $rightPath
  $summary = (& $compare -LeftPath $leftPath -RightPath $rightPath) |
    ConvertFrom-Json -AsHashtable
  if (-not $summary.comparable -or [double]$summary.left.opening_gap_seconds -ne 1.2) {
    throw 'Compatible diagnostic summary did not retain the opening gap.'
  }
  if (
    [double]$summary.left.boss_visible_gap_max_seconds -ne 0.8 -or
    [int]$summary.left.category_decision.confirmed -ne 1 -or
    [int]$summary.left.announcements.shown -ne 1 -or
    [int]$summary.left.anomalies.gravity_pull.affected -ne 4 -or
    [double]$summary.left.slow_tail.receipt_max_total_ms -ne 12.5
  ) {
    throw 'Compatible diagnostic summary lost a required hypothesis signal.'
  }
  $incompatible = $bundle | ConvertTo-Json -Depth 10 |
    ConvertFrom-Json -AsHashtable
  $incompatible.session_context.locale = 'en'
  $incompatible | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $rightPath
  $rejected = $false
  try {
    & $compare -LeftPath $leftPath -RightPath $rightPath | Out-Null
  } catch {
    $rejected = $_.Exception.Message -like '*session_context.locale*'
  }
  if (-not $rejected) { throw 'Incompatible locale comparison was not rejected.' }
  Write-Output 'VEHICLE_DIAGNOSTIC_COMPARISON_VALIDATION_OK'
} finally {
  if (Test-Path -LiteralPath $testDirectory) {
    Remove-Item -LiteralPath $testDirectory -Recurse -Force
  }
}
