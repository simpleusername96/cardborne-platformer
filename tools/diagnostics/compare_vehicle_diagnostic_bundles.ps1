[CmdletBinding(PositionalBinding = $false)]
param(
  [Parameter(Mandatory = $true)] [string] $LeftPath,
  [Parameter(Mandatory = $true)] [string] $RightPath
)

$ErrorActionPreference = 'Stop'
function Read-Bundle([string] $path) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing bundle: $path" }
  try { return (Get-Content -Raw -LiteralPath $path | ConvertFrom-Json -AsHashtable) } catch { throw "Invalid diagnostic JSON: $path" }
}
$left = Read-Bundle $LeftPath
$right = Read-Bundle $RightPath
foreach ($bundle in @($left, $right)) {
  if (
    [int]$bundle.schema_version -ne 1 -or
    [string]$bundle.kind -notin @('session_diagnostic','cardborne_diagnostics_export')
  ) { throw 'Only schema-1 session diagnostics or redacted exports are comparable.' }
  foreach ($key in @('locale','viewport_class','reduced_motion','renderer')) {
    if (-not $bundle.session_context.ContainsKey($key)) {
      throw "Diagnostic comparison requires session_context.$key."
    }
  }
}
$incompatible = @()
foreach ($key in @('content_fingerprint','commit')) {
  if ([string]$left.build_identity[$key] -ne [string]$right.build_identity[$key]) { $incompatible += "build_identity.$key" }
}
foreach ($key in @('registry_version')) {
  if ([string]$left[$key] -ne [string]$right[$key]) { $incompatible += $key }
}
foreach ($key in @('locale','viewport_class','reduced_motion','renderer')) {
  if ([string]$left.session_context[$key] -ne [string]$right.session_context[$key]) { $incompatible += "session_context.$key" }
}
if ($incompatible.Count -gt 0) { throw "Incompatible diagnostic comparison: $($incompatible -join ', ')" }

function Measure-Session([hashtable] $bundle) {
  $events = @($bundle.events | Sort-Object { [int]$_.sequence })
  $eventCounts = [ordered]@{}
  foreach ($event in $events) {
    $kind = [string]$event.kind
    if (-not $eventCounts.Contains($kind)) { $eventCounts[$kind] = 0 }
    $eventCounts[$kind]++
  }

  $openingGap = $null
  $stageStart = $events | Where-Object { [string]$_.kind -eq 'stage_started' } | Select-Object -First 1
  if ($null -ne $stageStart) {
    $stageIndex = [int]$stageStart.fields.stage_index
    $firstVisible = $events | Where-Object {
      [string]$_.kind -eq 'first_visible' -and
      [int]$_.fields.stage_index -eq $stageIndex -and
      [double]$_.monotonic_seconds -ge [double]$stageStart.monotonic_seconds
    } | Select-Object -First 1
    if ($null -ne $firstVisible) {
      $openingGap = [Math]::Round(
        [double]$firstVisible.monotonic_seconds - [double]$stageStart.monotonic_seconds,
        4
      )
    }
  }

  $bossWindows = @()
  $bossStart = $null
  foreach ($event in $events) {
    if ([string]$event.kind -eq 'boss_warning') { $bossStart = [double]$event.monotonic_seconds }
    if ([string]$event.kind -eq 'boss_ended' -and $null -ne $bossStart) {
      $bossWindows += ,@($bossStart, [double]$event.monotonic_seconds)
      $bossStart = $null
    }
  }
  if ($null -ne $bossStart) { $bossWindows += ,@($bossStart, [double]::PositiveInfinity) }
  $bossGapMax = 0.0
  foreach ($gap in @($events | Where-Object { [string]$_.kind -eq 'visible_gap_closed' })) {
    $gapSeconds = [double]$gap.fields.gap_seconds
    $gapEnd = [double]$gap.monotonic_seconds
    $gapStart = $gapEnd - $gapSeconds
    foreach ($window in $bossWindows) {
      if ($gapStart -le [double]$window[1] -and $gapEnd -ge [double]$window[0]) {
        $bossGapMax = [Math]::Max($bossGapMax, $gapSeconds)
      }
    }
  }

  $announcement = [ordered]@{}
  foreach ($kind in @('queued','shown','interrupted','dropped')) {
    $announcement[$kind] = [int]($eventCounts["announcement_$kind"] ?? 0)
  }
  $anomalies = [ordered]@{}
  foreach ($event in @($events | Where-Object { [string]$_.kind -eq 'anomaly_activated' })) {
    $effect = [string]$event.fields.effect_id
    if (-not $anomalies.Contains($effect)) { $anomalies[$effect] = [ordered]@{ activations = 0; affected = 0 } }
    $anomalies[$effect].activations++
    $anomalies[$effect].affected += [int]$event.fields.affected_count
  }
  $seconds = @($bundle.one_hz)
  $slowTicks = @($bundle.slow_tick_receipts)
  $oneHzMax = 0.0
  $oneHzOver33 = 0
  foreach ($second in $seconds) {
    $maximum = [double]$second.max_frame_ms
    $oneHzMax = [Math]::Max($oneHzMax, $maximum)
    if ($maximum -gt 33.3) { $oneHzOver33++ }
  }
  $slowTickMax = 0.0
  foreach ($receipt in $slowTicks) { $slowTickMax = [Math]::Max($slowTickMax, [double]$receipt.total_ms) }
  return [ordered]@{
    events = $eventCounts
    opening_gap_seconds = $openingGap
    boss_visible_gap_max_seconds = [Math]::Round($bossGapMax, 4)
    category_decision = [ordered]@{
      focused = [int]($eventCounts.upgrade_focused ?? 0)
      confirmed = [int]($eventCounts.upgrade_confirmed ?? 0)
    }
    announcements = $announcement
    anomalies = $anomalies
    slow_tail = [ordered]@{
      one_hz_max_frame_ms = [Math]::Round($oneHzMax, 4)
      one_hz_seconds_over_33_3_ms = $oneHzOver33
      receipts_retained = $slowTicks.Count
      receipt_max_total_ms = [Math]::Round($slowTickMax, 4)
    }
  }
}

$summary = [ordered]@{
  comparable = $true
  compatibility = [ordered]@{
    commit = [string]$left.build_identity.commit
    content_fingerprint = [string]$left.build_identity.content_fingerprint
    registry_version = [int]$left.registry_version
    session_context = $left.session_context
  }
  left = Measure-Session $left
  right = Measure-Session $right
}
$summary | ConvertTo-Json -Compress -Depth 10
