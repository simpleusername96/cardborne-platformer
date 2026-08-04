[CmdletBinding()]
param([switch]$Apply)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$sourcePath = Join-Path $repoRoot 'docs/design/visual-replacement-workbench/replacement-workbench.json'
$productionRoot = (Resolve-Path (Join-Path $repoRoot 'art/visuals/production/gameplay')).Path
$workbench = Get-Content -Raw -LiteralPath $sourcePath | ConvertFrom-Json -Depth 100
$units = @($workbench.units | Where-Object { [string]$_.status -ceq 'approved_for_switch' })
$retirePaths = @($units | ForEach-Object { @($_.retire_paths) } | Sort-Object -Unique)
$pngPaths = @($retirePaths | Where-Object { $_ -like '*.png' })
$sidecarPaths = @($retirePaths | Where-Object { $_ -like '*.png.import' })

if ($retirePaths.Count -ne 354 -or $pngPaths.Count -ne 177 -or $sidecarPaths.Count -ne 177) {
    throw "Expected exact 177 PNG + 177 sidecar retirement set; observed total=$($retirePaths.Count) png=$($pngPaths.Count) sidecar=$($sidecarPaths.Count)."
}

foreach ($pngPath in $pngPaths) {
    if ($sidecarPaths -cnotcontains "$pngPath.import") {
        throw "Missing exact sidecar pair for retirement path: $pngPath"
    }
}

$absolutePaths = @()
foreach ($relativePath in $retirePaths) {
    if ([IO.Path]::IsPathRooted([string]$relativePath)) {
        throw "Retirement path must stay repository-relative: $relativePath"
    }
    $absolutePath = [IO.Path]::GetFullPath((Join-Path $repoRoot ([string]$relativePath)))
    if (-not $absolutePath.StartsWith("$productionRoot$([IO.Path]::DirectorySeparatorChar)", [StringComparison]::OrdinalIgnoreCase)) {
        throw "Retirement path escapes the production gameplay root: $relativePath"
    }
    if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
        throw "Approved retirement file is missing before apply: $relativePath"
    }
    $absolutePaths += $absolutePath
}

# Evidence and planning files intentionally describe retired paths. Consumer
# proof is limited to runtime, resources, manifests, guidebook code, and gates.
$consumerRoots = @('scripts', 'scenes', 'data', 'localization', 'shaders', 'tools/validation')
$consumerFiles = @()
foreach ($relativeRoot in $consumerRoots) {
    $absoluteRoot = Join-Path $repoRoot $relativeRoot
    if (Test-Path -LiteralPath $absoluteRoot -PathType Container) {
        $consumerFiles += Get-ChildItem -LiteralPath $absoluteRoot -Recurse -File | Where-Object {
            $_.Extension -in @('.gd', '.tscn', '.tres', '.json', '.cfg', '.godot', '.ps1', '.py', '.md')
        }
    }
}
$consumerFiles += Get-Item -LiteralPath (Join-Path $repoRoot 'project.godot')
$consumerFiles += Get-ChildItem -LiteralPath (Join-Path $repoRoot 'art/visuals/production') -Recurse -File | Where-Object {
    $_.Extension -in @('.json', '.tres', '.tscn', '.gd')
}
$consumerTexts = @{}
foreach ($file in $consumerFiles | Sort-Object FullName -Unique) {
    $consumerTexts[$file.FullName] = Get-Content -Raw -LiteralPath $file.FullName
}

$references = [Collections.Generic.List[string]]::new()
$gameplayPrefix = 'art/visuals/production/gameplay/'
foreach ($pngPath in $pngPaths) {
    $normalized = ([string]$pngPath).Replace('\', '/')
    $suffix = $normalized.Substring($gameplayPrefix.Length)
    foreach ($entry in $consumerTexts.GetEnumerator()) {
        $text = ([string]$entry.Value).Replace('\', '/')
        if ($text.Contains($normalized) -or $text.Contains($suffix)) {
            $relativeConsumer = [IO.Path]::GetRelativePath($repoRoot, [string]$entry.Key).Replace('\', '/')
            $references.Add("$normalized <- $relativeConsumer")
        }
    }
}
if ($references.Count -gt 0) {
    throw "Legacy visual consumers remain:`n$($references -join "`n")"
}

if (-not $Apply) {
    Write-Output "VISUAL_RETIREMENT_DRY_RUN_OK files=354 png=177 sidecars=177 consumers=0"
    exit 0
}

$dirty = @(git -C $repoRoot status --porcelain)
if ($dirty.Count -gt 0) {
    throw 'Exact visual retirement requires a clean committed worktree.'
}
foreach ($absolutePath in $absolutePaths) {
    Remove-Item -LiteralPath $absolutePath
}
$remainingPng = @(Get-ChildItem -LiteralPath $productionRoot -Recurse -File -Filter '*.png').Count
if ($remainingPng -ne 49) {
    throw "Retirement completed but production gameplay PNG count is $remainingPng instead of 49."
}
Write-Output "VISUAL_RETIREMENT_APPLY_OK files=354 png=177 sidecars=177 remaining_png=49"
