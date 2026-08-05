[CmdletBinding(PositionalBinding = $false)]
param(
  [string] $OutputPath = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$hadPerformanceCommit = Test-Path Env:PERFORMANCE_COMMIT
$previousPerformanceCommit = $env:PERFORMANCE_COMMIT
$hadPerformanceDirty = Test-Path Env:PERFORMANCE_DIRTY
$previousPerformanceDirty = $env:PERFORMANCE_DIRTY

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

  $commit = (git rev-parse HEAD).Trim()
  if ($LASTEXITCODE -ne 0 -or -not $commit) {
    throw "Could not resolve the current Git commit."
  }

  if (-not $OutputPath) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $OutputPath = "res://build/performance/manual/manual-$($commit.Substring(0, 8))-$stamp.json"
  }
  if ($OutputPath -notmatch '^res://build/performance/manual/[A-Za-z0-9][A-Za-z0-9._-]*\.json$') {
    throw "OutputPath must be a JSON file directly under res://build/performance/manual/."
  }

  $relativeOutput = $OutputPath.Substring("res://".Length).Replace(
    '/',
    [IO.Path]::DirectorySeparatorChar
  )
  $absoluteOutput = Join-Path $repoRoot $relativeOutput
  if (Test-Path -LiteralPath $absoluteOutput) {
    throw "Refusing to overwrite an existing manual trace: $absoluteOutput"
  }

  $trackedChanges = @(git status --porcelain --untracked-files=no)
  if ($LASTEXITCODE -ne 0) {
    throw "Could not inspect the tracked worktree state."
  }
  $env:PERFORMANCE_COMMIT = $commit
  $env:PERFORMANCE_DIRTY = if ($trackedChanges.Count -eq 0) { '0' } else { '1' }

  Write-Host "수동 성능 기록을 켠 채 게임을 시작합니다. 평소처럼 플레이해 주세요."
  Write-Host "버벅임을 확인한 뒤 게임 창을 정상적으로 닫으면 JSON이 저장됩니다."
  Write-Host "기록 위치: $OutputPath"

  & .\tools\godot.ps1 --path . -- "--manual-performance-output=$OutputPath"
  if ($LASTEXITCODE -ne 0) {
    throw "Godot exited with code $LASTEXITCODE."
  }
  if (-not (Test-Path -LiteralPath $absoluteOutput)) {
    throw "No trace was written. Enter gameplay before closing the game normally."
  }

  Write-Host "MANUAL_PERFORMANCE_TRACE_READY $absoluteOutput"
} finally {
  if ($hadPerformanceCommit) {
    $env:PERFORMANCE_COMMIT = $previousPerformanceCommit
  } else {
    Remove-Item Env:PERFORMANCE_COMMIT -ErrorAction SilentlyContinue
  }
  if ($hadPerformanceDirty) {
    $env:PERFORMANCE_DIRTY = $previousPerformanceDirty
  } else {
    Remove-Item Env:PERFORMANCE_DIRTY -ErrorAction SilentlyContinue
  }
  Pop-Location
}
