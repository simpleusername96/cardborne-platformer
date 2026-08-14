[CmdletBinding(PositionalBinding = $false)]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$outputDirectory = Join-Path $repoRoot 'data\generated'
$outputPath = Join-Path $outputDirectory 'vehicle_build_identity.json'

Push-Location -LiteralPath $repoRoot
try {
  $commit = (git rev-parse HEAD).Trim().ToLowerInvariant()
  if ($LASTEXITCODE -ne 0 -or $commit -notmatch '^[0-9a-f]{40}$') { throw 'Could not resolve a full Git commit.' }
  $ref = (git branch --show-current).Trim()
  if ($LASTEXITCODE -ne 0) { throw 'Could not resolve the current branch.' }
  if ([string]::IsNullOrWhiteSpace($ref)) {
    $ref = if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_REF)) { $env:GITHUB_REF } else { (git describe --all --always).Trim() }
  }
  if ([string]::IsNullOrWhiteSpace($ref)) { throw 'Could not resolve a branch or detached ref.' }
  $status = @(git status --porcelain=v1 --untracked-files=all)
  if ($LASTEXITCODE -ne 0) { throw 'Could not inspect source cleanliness.' }
  $sourceChanges = @($status | Where-Object { $_ -notmatch 'data/generated/vehicle_build_identity\.json$' -and $_ -notmatch '^\?\? build/' })
  $sourceFiles = @(git ls-files)
  if ($LASTEXITCODE -ne 0) { throw 'Could not enumerate tracked source files.' }
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    foreach ($relativePath in $sourceFiles | Sort-Object) {
      $absolutePath = Join-Path $repoRoot $relativePath
      if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) { throw "Tracked source file is missing: $relativePath" }
      $line = "$relativePath`t$((Get-FileHash -LiteralPath $absolutePath -Algorithm SHA256).Hash.ToLowerInvariant())`n"
      $bytes = [Text.Encoding]::UTF8.GetBytes($line)
      [void]$sha.TransformBlock($bytes, 0, $bytes.Length, $bytes, 0)
    }
    [void]$sha.TransformFinalBlock([byte[]]::new(0), 0, 0)
    $fingerprint = ([BitConverter]::ToString($sha.Hash) -replace '-', '').ToLowerInvariant()
  } finally { $sha.Dispose() }
  New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
  [ordered]@{
    schema_version = 1
    identity_status = 'resolved'
    commit = $commit
    ref = $ref
    source_cleanliness = if ($sourceChanges.Count -eq 0) { 'clean' } else { 'dirty' }
    source_change_count = $sourceChanges.Count
    content_fingerprint = $fingerprint
    generated_utc = [DateTime]::UtcNow.ToString('o')
    tool_version = 'vehicle-build-identity/1'
  } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $outputPath -Encoding utf8NoBOM
  Write-Output "VEHICLE_BUILD_IDENTITY_WRITTEN $outputPath"
} finally { Pop-Location }
