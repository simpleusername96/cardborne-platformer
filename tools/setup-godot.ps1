param(
  [string] $Version = "4.7-stable"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$runtimeRoot = Join-Path $repoRoot ".codex-runtime"
$installDir = Join-Path $runtimeRoot "godot-$Version"
$downloadDir = Join-Path $runtimeRoot "downloads"
$zipPath = Join-Path $downloadDir "Godot_v$Version`_win64.exe.zip"
$url = "https://github.com/godotengine/godot/releases/download/$Version/Godot_v$Version`_win64.exe.zip"

New-Item -ItemType Directory -Force -Path $installDir, $downloadDir | Out-Null

if (-not (Test-Path -LiteralPath $zipPath)) {
  Invoke-WebRequest -Uri $url -OutFile $zipPath
}

Expand-Archive -LiteralPath $zipPath -DestinationPath $installDir -Force

& (Join-Path $PSScriptRoot "godot.ps1") --version
