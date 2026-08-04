[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$specPath = 'docs/design/VISUAL_SYSTEM.md'
$sheetPath = 'docs/design/cardborne-universal-art-style-reference.png'
$expectedHash = '96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889'
$expectedWidth = 1448
$expectedHeight = 1086
$failures = [Collections.Generic.List[string]]::new()

function Expect([bool]$Condition, [string]$Message) {
    if (-not $Condition) { $failures.Add($Message) }
}

function Get-RepoFile([string]$RelativePath) {
    return Join-Path $repoRoot $RelativePath.Replace('/', '\')
}

function Get-PngDimensions([string]$LiteralPath) {
    $stream = [IO.File]::OpenRead($LiteralPath)
    try {
        $header = New-Object byte[] 24
        if ($stream.Read($header, 0, 24) -ne 24 -or
            $header[0] -ne 137 -or $header[1] -ne 80 -or
            $header[2] -ne 78 -or $header[3] -ne 71) {
            throw "invalid PNG header: $LiteralPath"
        }
        $width = [int64]$header[16] * 16777216 + [int64]$header[17] * 65536 +
            [int64]$header[18] * 256 + [int64]$header[19]
        $height = [int64]$header[20] * 16777216 + [int64]$header[21] * 65536 +
            [int64]$header[22] * 256 + [int64]$header[23]
        return @([int]$width, [int]$height)
    }
    finally {
        $stream.Dispose()
    }
}

$specAbsolute = Get-RepoFile $specPath
$sheetAbsolute = Get-RepoFile $sheetPath
Expect (Test-Path -LiteralPath $specAbsolute -PathType Leaf) "missing canonical visual specification: $specPath"
Expect (Test-Path -LiteralPath $sheetAbsolute -PathType Leaf) "missing canonical visual reference: $sheetPath"

if (Test-Path -LiteralPath $sheetAbsolute -PathType Leaf) {
    $observedHash = (Get-FileHash -LiteralPath $sheetAbsolute -Algorithm SHA256).Hash.ToLowerInvariant()
    Expect ($observedHash -ceq $expectedHash) "canonical visual reference hash mismatch: expected=$expectedHash observed=$observedHash"
    try {
        $dimensions = Get-PngDimensions $sheetAbsolute
        Expect ($dimensions[0] -eq $expectedWidth -and $dimensions[1] -eq $expectedHeight) "canonical visual reference dimensions must be ${expectedWidth}x${expectedHeight}"
    }
    catch {
        $failures.Add($_.Exception.Message)
    }
}

$requiredText = [ordered]@{
    'AGENTS.md' = @('$cardborne-visual-authority', $specPath, $sheetPath, 'validate_cardborne_visual_authority.ps1')
    $specPath = @('## Mandatory Visual Authority Pair', $sheetPath, $expectedHash, 'actual image reference')
    'docs/README.md' = @('$cardborne-visual-authority', $specPath, $sheetPath)
    'docs/design/visual-replacement-workbench/README.md' = @($specPath, $sheetPath, 'actual image reference', 'visual_authority_evidence')
    'art/visuals/production/README.md' = @($specPath, $sheetPath, 'actual image reference')
    '.agents/skills/cardborne-visual-authority/SKILL.md' = @($specPath, $sheetPath, $expectedHash, 'actual image reference', 'visual_authority_evidence')
}

foreach ($relativePath in $requiredText.Keys) {
    $absolutePath = Get-RepoFile $relativePath
    Expect (Test-Path -LiteralPath $absolutePath -PathType Leaf) "missing visual authority integration file: $relativePath"
    if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) { continue }
    $text = Get-Content -LiteralPath $absolutePath -Raw
    foreach ($token in $requiredText[$relativePath]) {
        Expect ($text.Contains([string]$token)) "visual authority integration missing token: $relativePath -> $token"
    }
    Expect (-not $text.Contains('build/recovered-style-authority')) "active visual authority surface references recovered historical sheets: $relativePath"
}

# This plan is intentionally transient under .agents/PLANS.md. Validate its
# authority preflight while it is active without making future plan deletion fail.
$activeVisualPlan = '.agents/execplans/2026-08-04-complete-remaining-visual-replacements.md'
$activeVisualPlanAbsolute = Get-RepoFile $activeVisualPlan
if (Test-Path -LiteralPath $activeVisualPlanAbsolute -PathType Leaf) {
    $planText = Get-Content -LiteralPath $activeVisualPlanAbsolute -Raw
    foreach ($token in @($specPath, $sheetPath, $expectedHash, 'actual image reference', 'visual_authority_evidence')) {
        Expect ($planText.Contains([string]$token)) "active visual plan missing authority token: $token"
    }
    Expect (-not $planText.Contains('build/recovered-style-authority')) 'active visual plan references recovered historical sheets'
}

$workbenchSourcePath = Get-RepoFile 'docs/design/visual-replacement-workbench/replacement-workbench.json'
if (Test-Path -LiteralPath $workbenchSourcePath -PathType Leaf) {
    try {
        $source = Get-Content -LiteralPath $workbenchSourcePath -Raw | ConvertFrom-Json -Depth 100
        Expect ([string]$source.style_authority -ceq $specPath) 'workbench style_authority is not canonical'
        $record = $source.style_reference_sheet
        Expect ($null -ne $record) 'workbench style_reference_sheet is missing'
        if ($null -ne $record) {
            $fields = @($record.PSObject.Properties.Name | Sort-Object)
            Expect (($fields -join ',') -ceq 'height,path,sha256,width') 'workbench style_reference_sheet fields are not exact'
            Expect ([string]$record.path -ceq $sheetPath) 'workbench style-reference path is not canonical'
            Expect ([string]$record.sha256 -ceq $expectedHash) 'workbench style-reference hash is not canonical'
            Expect ([int]$record.width -eq $expectedWidth -and [int]$record.height -eq $expectedHeight) 'workbench style-reference dimensions are not canonical'
        }
    }
    catch {
        $failures.Add("invalid workbench authority record: $($_.Exception.Message)")
    }
}
else {
    $failures.Add('missing visual replacement workbench source')
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Host "CARDBORNE_VISUAL_AUTHORITY_VALIDATION_OK sheet=$sheetPath sha256=$expectedHash dimensions=${expectedWidth}x${expectedHeight}"
