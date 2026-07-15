param(
  [switch] $SkipImport
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$godot = Join-Path $PSScriptRoot "godot.ps1"
$buildParent = [System.IO.Path]::GetFullPath((Join-Path $repoRoot "build"))
$outputRoot = [System.IO.Path]::GetFullPath((Join-Path $buildParent "web"))
$outputPath = Join-Path $outputRoot "index.html"
$expectedOutputRoot = [System.IO.Path]::GetFullPath((Join-Path $repoRoot "build\web"))

if ($outputRoot -ne $expectedOutputRoot) {
  throw "Refusing to clean an unexpected web export path: $outputRoot"
}

function Invoke-Godot {
  param(
    [Parameter(Mandatory = $true)]
    [string[]] $Arguments,
    [Parameter(Mandatory = $true)]
    [string] $Label
  )

  $shell = (Get-Process -Id $PID).Path
  & $shell -NoLogo -NoProfile -NonInteractive -File $godot @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "$Label failed with exit code $LASTEXITCODE."
  }
}

Push-Location -LiteralPath $repoRoot
try {
  if (Test-Path -LiteralPath $outputRoot) {
    Remove-Item -LiteralPath $outputRoot -Recurse -Force
  }
  New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null

  if (-not $SkipImport) {
    Invoke-Godot -Arguments @("--path", $repoRoot, "--headless", "--import") -Label "Godot import"
  }

  Invoke-Godot -Arguments @(
    "--path", $repoRoot, "--headless", "--export-release", "Web", $outputPath
  ) -Label "Web release export"

  $requiredFiles = @("index.html", "index.js", "index.pck", "index.wasm")
  foreach ($fileName in $requiredFiles) {
    $requiredPath = Join-Path $outputRoot $fileName
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
      throw "Web export did not produce $fileName."
    }
  }

  Write-Output "WEB_EXPORT_OK path=$outputPath files=$($requiredFiles.Count)"
} finally {
  Pop-Location
}
