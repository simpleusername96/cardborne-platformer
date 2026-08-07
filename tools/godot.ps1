[CmdletBinding(PositionalBinding = $false)]
param(
  [string] $RuntimeRelease = "4.7.1-stable",
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]] $GodotArgs
)

$ErrorActionPreference = "Stop"

$candidatePaths = New-Object System.Collections.Generic.List[string]
$sharedRuntimeRoot = "D:\tools\Godot"

if ($env:GODOT_BIN) {
  $candidatePaths.Add($env:GODOT_BIN)
}

$candidatePaths.Add((Join-Path $sharedRuntimeRoot "$RuntimeRelease\Godot_v$RuntimeRelease`_win64_console.exe"))
$candidatePaths.Add((Join-Path $sharedRuntimeRoot "$RuntimeRelease\Godot_v$RuntimeRelease`_win64.exe"))

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

Write-Error "Godot executable not found. Run .\tools\setup-godot.ps1 to provision D:\tools\Godot or set GODOT_BIN to a Godot 4.x executable."
exit 1
