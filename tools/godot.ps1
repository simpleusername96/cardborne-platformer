param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]] $GodotArgs
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$candidatePaths = New-Object System.Collections.Generic.List[string]

if ($env:GODOT_BIN) {
  $candidatePaths.Add($env:GODOT_BIN)
}

$candidatePaths.Add((Join-Path $repoRoot ".codex-runtime\godot-4.7-stable\Godot_v4.7-stable_win64_console.exe"))
$candidatePaths.Add((Join-Path $repoRoot ".codex-runtime\godot-4.7-stable\Godot_v4.7-stable_win64.exe"))

foreach ($path in $candidatePaths) {
  if ($path -and (Test-Path -LiteralPath $path)) {
    & $path @GodotArgs
    exit $LASTEXITCODE
  }
}

foreach ($commandName in @("godot.exe", "godot4.exe")) {
  $command = Get-Command $commandName -ErrorAction SilentlyContinue
  if ($command) {
    & $command.Source @GodotArgs
    exit $LASTEXITCODE
  }
}

Write-Error "Godot executable not found. Run .\tools\setup-godot.ps1 or set GODOT_BIN to a Godot 4.x executable."
exit 1
