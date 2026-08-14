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
  if ([int]$bundle.schema_version -ne 1 -or [string]$bundle.kind -ne 'session_diagnostic') { throw 'Only schema-1 completed session diagnostics are comparable.' }
}
$incompatible = @()
foreach ($key in @('content_fingerprint','commit')) {
  if ([string]$left.build_identity[$key] -ne [string]$right.build_identity[$key]) { $incompatible += "build_identity.$key" }
}
foreach ($key in @('registry_version')) {
  if ([string]$left[$key] -ne [string]$right[$key]) { $incompatible += $key }
}
if ($incompatible.Count -gt 0) { throw "Incompatible diagnostic comparison: $($incompatible -join ', ')" }
$summary = [ordered]@{
  comparable = $true
  left_events = @($left.events).Count
  right_events = @($right.events).Count
  left_one_hz = @($left.one_hz).Count
  right_one_hz = @($right.one_hz).Count
}
$summary | ConvertTo-Json -Compress
