param(
  [string] $Version = "4.7.1-stable"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$runtimeRoot = Join-Path $repoRoot ".codex-runtime"
$installDir = Join-Path $runtimeRoot "godot-$Version"
$downloadDir = Join-Path $runtimeRoot "downloads"
$zipPath = Join-Path $downloadDir "Godot_v$Version`_win64.exe.zip"
$templateZipPath = Join-Path $downloadDir "Godot_v$Version`_export_templates.zip"
$releaseRoot = "https://github.com/godotengine/godot-builds/releases/download/$Version"
$editorUrl = "$releaseRoot/Godot_v$Version`_win64.exe.zip"
$templateUrl = "$releaseRoot/Godot_v$Version`_export_templates.tpz"
$templateVersion = $Version -replace "-", "."
$templateInstallDir = Join-Path $env:APPDATA "Godot\export_templates\$templateVersion"
$templateExtractDir = Join-Path $runtimeRoot "godot-$Version-export-templates"

New-Item -ItemType Directory -Force -Path $installDir, $downloadDir, $templateExtractDir, $templateInstallDir | Out-Null

if (-not (Test-Path -LiteralPath $zipPath)) {
  Invoke-WebRequest -Uri $editorUrl -OutFile $zipPath
}

if (-not (Test-Path -LiteralPath $templateZipPath)) {
  Invoke-WebRequest -Uri $templateUrl -OutFile $templateZipPath
}

Expand-Archive -LiteralPath $zipPath -DestinationPath $installDir -Force
Expand-Archive -LiteralPath $templateZipPath -DestinationPath $templateExtractDir -Force

$templateSourceDir = Join-Path $templateExtractDir "templates"
if (-not (Test-Path -LiteralPath $templateSourceDir -PathType Container)) {
  throw "Godot export template archive did not contain the expected templates directory."
}
Copy-Item -Path (Join-Path $templateSourceDir "*") -Destination $templateInstallDir -Recurse -Force

$webTemplatePath = Join-Path $templateInstallDir "web_release.zip"
if (-not (Test-Path -LiteralPath $webTemplatePath -PathType Leaf)) {
  throw "Godot Web release template was not installed."
}

$installedEditor = Join-Path $installDir "Godot_v$Version`_win64_console.exe"
if (-not (Test-Path -LiteralPath $installedEditor -PathType Leaf)) {
  throw "Godot console editor was not installed."
}

& (Join-Path $PSScriptRoot "godot.ps1") -RuntimeRelease $Version --version
