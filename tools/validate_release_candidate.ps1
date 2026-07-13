param(
  [switch] $Full,
  [switch] $SkipImport,
  [switch] $VerboseOutput,
  [ValidateRange(1, 3600)]
  [int] $ValidatorTimeoutSeconds = 180
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$godot = Join-Path $PSScriptRoot "godot.ps1"
$releaseMatrix = @(
  "validate_design_catalogs.gd",
  "validate_room_templates.gd",
  "validate_flooded_works_rooms.gd",
  "validate_broken_sanctum_rooms.gd",
  "validate_curated_stage_plans.gd",
  "validate_field_pickups.gd",
  "validate_fixed_field_pickup_manifest.gd",
  "validate_fixed_drop_runtime.gd",
  "validate_complete_run_balance.gd",
  "validate_combat_spacing.gd",
  "validate_build_previews.gd",
  "validate_player_stat_presentation.gd",
  "validate_gameplay_hud.gd",
  "validate_shell_ui.gd",
  "validate_equipment_decision_ui.gd",
  "validate_reward_choice_ui.gd",
  "validate_card_reward.gd",
  "validate_reward_receipt.gd",
  "validate_remaining_cards_runtime.gd",
  "validate_roster_stage_matrix.gd",
  "validate_profile_persistence.gd",
  "validate_profile_run_integration.gd",
  "validate_gamepad_input.gd",
  "validate_input_remap.gd",
  "validate_pause_flow.gd",
  "validate_production_boot.gd",
  "validate_production_stage.gd",
  "validate_slime_court_runtime.gd",
  "validate_slime_king_patterns_runtime.gd",
  "validate_boss_roster_matrix.gd",
  "validate_boss_run_flow.gd",
  "validate_run_settlement.gd",
  "validate_run_result_ui.gd"
)

if ($Full) {
  $scripts = @(
    Get-ChildItem -LiteralPath $PSScriptRoot -Filter "validate_*.gd" -File |
      Sort-Object Name |
      ForEach-Object Name |
      Where-Object { $_ -ne "validate_release_candidate.gd" }
  )
} else {
  $scripts = $releaseMatrix
}

$started = Get-Date

function Write-ValidationOutput {
  param(
    [object[]] $Lines,
    [bool] $Failed = $false
  )

  if ($VerboseOutput -or $Failed) {
    $Lines | Write-Output
    return
  }

  $summary = @($Lines | Where-Object { $_ -match "(_OK|WARNING:|ERROR:|SCRIPT ERROR:)" })
  if ($summary.Count -gt 0) {
    $summary | Write-Output
    return
  }

  $lastLine = $Lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Last 1
  if ($null -ne $lastLine) {
    $lastLine | Write-Output
  }
}

function Invoke-GodotCommand {
  param(
    [string[]] $Arguments,
    [string] $Label,
    [hashtable] $Environment = @{}
  )

  $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
  $startInfo.FileName = (Get-Process -Id $PID).Path
  $startInfo.WorkingDirectory = $repoRoot
  $startInfo.UseShellExecute = $false
  $startInfo.RedirectStandardOutput = $true
  $startInfo.RedirectStandardError = $true
  foreach ($key in $Environment.Keys) {
    $startInfo.Environment[[string] $key] = [string] $Environment[$key]
  }
  foreach ($argument in @("-NoLogo", "-NoProfile", "-NonInteractive", "-File", $godot) + $Arguments) {
    $startInfo.ArgumentList.Add([string] $argument)
  }

  $process = [System.Diagnostics.Process]::new()
  $process.StartInfo = $startInfo
  if (-not $process.Start()) {
    throw "Unable to start $Label."
  }
  $standardOutput = $process.StandardOutput.ReadToEndAsync()
  $standardError = $process.StandardError.ReadToEndAsync()
  $timedOut = -not $process.WaitForExit($ValidatorTimeoutSeconds * 1000)
  if ($timedOut) {
    try {
      $process.Kill($true)
    } catch {
      $process.Kill()
    }
  }
  $process.WaitForExit()

  $lines = @()
  foreach ($text in @($standardOutput.GetAwaiter().GetResult(), $standardError.GetAwaiter().GetResult())) {
    if (-not [string]::IsNullOrWhiteSpace($text)) {
      $lines += @($text -split "\r?\n")
    }
  }
  return [PSCustomObject]@{
    Lines = $lines
    ExitCode = if ($timedOut) { -1 } else { $process.ExitCode }
    TimedOut = $timedOut
  }
}

Push-Location -LiteralPath $repoRoot
try {
  if (-not $SkipImport) {
    Write-Output "[release] Godot import"
    $importResult = Invoke-GodotCommand -Arguments @(
      "--path", $repoRoot, "--headless", "--import"
    ) -Label "Godot import"
    $importOutput = @($importResult.Lines)
    $importFailed = $importResult.TimedOut -or $importResult.ExitCode -ne 0 -or ($importOutput -match "(SCRIPT ERROR:|ERROR:)")
    Write-ValidationOutput -Lines $importOutput -Failed $importFailed
    if ($importFailed) {
      if ($importResult.TimedOut) {
        throw "Godot import timed out after $ValidatorTimeoutSeconds seconds."
      }
      throw "Godot import failed."
    }
  }

  $completed = 0
  foreach ($scriptName in $scripts) {
    $scriptPath = Join-Path $PSScriptRoot $scriptName
    if (-not (Test-Path -LiteralPath $scriptPath)) {
      throw "Release validator is missing: $scriptName"
    }
    Write-Output "[release] $scriptName"
    $validatorArguments = @(
      "--path", $repoRoot, "--headless", "--script", "res://tools/$scriptName"
    )
    $validatorEnvironment = @{}
    if ($Full -and $scriptName -eq "validate_broken_sanctum_rooms.gd") {
      $validatorEnvironment["CARDBORNE_INCLUDE_RANDOM_PLANNER"] = "1"
    }
    $result = Invoke-GodotCommand `
      -Arguments $validatorArguments `
      -Label $scriptName `
      -Environment $validatorEnvironment
    $output = @($result.Lines)
    $failed = $result.TimedOut -or $result.ExitCode -ne 0 -or ($output -match "(SCRIPT ERROR:|ERROR:)")
    Write-ValidationOutput -Lines $output -Failed $failed
    if ($failed) {
      if ($result.TimedOut) {
        throw "Release validator timed out after $ValidatorTimeoutSeconds seconds: $scriptName"
      }
      throw "Release validator failed: $scriptName"
    }
    $completed += 1
  }

  $elapsed = [Math]::Round(((Get-Date) - $started).TotalSeconds, 1)
  Write-Output "RELEASE_CANDIDATE_MATRIX_OK checks=$completed full=$($Full.IsPresent) seconds=$elapsed"
} finally {
  Pop-Location
}
