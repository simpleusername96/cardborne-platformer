[CmdletBinding(PositionalBinding = $false)]
param(
  [string] $OutputPath = "",
  [string] $EvidenceId = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path

Push-Location -LiteralPath $repoRoot
try {
  $competingGodot = @(
    Get-CimInstance Win32_Process |
      Where-Object { $_.Name -like 'Godot*' }
  )
  if ($competingGodot.Count -ne 0) {
    $competingGodot |
      Select-Object ProcessId, Name, CommandLine |
      Format-Table -Wrap -AutoSize |
      Out-Host
    throw "Another Godot process is running. Wait for it or close it yourself before recording."
  }

  $commit = (git rev-parse HEAD).Trim().ToLowerInvariant()
  if ($LASTEXITCODE -ne 0 -or $commit -notmatch '^[0-9a-f]{40}$') {
    throw "Could not resolve the current Git commit."
  }
  $sourceChanges = @(git status --porcelain=v1 --untracked-files=all)
  if ($LASTEXITCODE -ne 0) { throw "Could not inspect source cleanliness." }
  if ($sourceChanges.Count -ne 0) {
    throw "Encounter pacing evidence requires a clean source tree. Commit task changes first."
  }

  $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
  if (-not $OutputPath) {
    $OutputPath = "res://build/performance/encounter-pacing-$($commit.Substring(0, 8))-$stamp.json"
  }
  if (-not $EvidenceId) {
    $EvidenceId = "$($commit.Substring(0, 8))-opening-boss-overlap-$stamp"
  }
  if ($OutputPath -notmatch '^res://build/performance/[A-Za-z0-9][A-Za-z0-9._-]*\.json$') {
    throw "OutputPath must be a JSON file directly under res://build/performance/."
  }
  if ($EvidenceId -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
    throw "EvidenceId may contain only letters, numbers, dots, underscores, and hyphens."
  }

  $relativeOutput = $OutputPath.Substring("res://".Length).Replace(
    '/',
    [IO.Path]::DirectorySeparatorChar
  )
  $absoluteOutput = Join-Path $repoRoot $relativeOutput
  if (Test-Path -LiteralPath $absoluteOutput) {
    throw "Refusing to overwrite an existing pacing capture: $absoluteOutput"
  }

  & .\tools\diagnostics\write_vehicle_build_identity.ps1 | Out-Host
  if ($LASTEXITCODE -ne 0) { throw "Could not generate the build identity." }
  $identityPath = Join-Path $repoRoot 'data\generated\vehicle_build_identity.json'
  $identity = Get-Content -Raw -LiteralPath $identityPath | ConvertFrom-Json
  if (
    [string]$identity.commit -ne $commit -or
    [string]$identity.source_cleanliness -ne 'clean' -or
    [string]$identity.content_fingerprint -notmatch '^[0-9a-f]{64}$'
  ) {
    throw "Generated build identity does not match the clean current commit."
  }

  & .\tools\godot.ps1 --headless --path . -- `
    "--encounter-pacing-output=$OutputPath" `
    "--encounter-pacing-evidence-id=$EvidenceId" `
    "--encounter-pacing-expected-commit=$commit" `
    "--encounter-pacing-expected-fingerprint=$($identity.content_fingerprint)"
  if ($LASTEXITCODE -ne 0) { throw "Godot exited with code $LASTEXITCODE." }
  if (-not (Test-Path -LiteralPath $absoluteOutput)) {
    throw "No encounter pacing capture was written."
  }

  $result = Get-Content -Raw -LiteralPath $absoluteOutput | ConvertFrom-Json
  if (
    [string]$result.build_identity.commit -ne $commit -or
    [string]$result.build_identity.content_fingerprint -ne [string]$identity.content_fingerprint
  ) {
    throw "Capture identity does not match the generated build identity."
  }
  Write-Output "ENCOUNTER_PACING_CAPTURE_READY $absoluteOutput"
} finally {
  Pop-Location
}
