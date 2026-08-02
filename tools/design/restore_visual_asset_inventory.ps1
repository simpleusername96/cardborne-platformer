[CmdletBinding()]
param(
    [string]$SnapshotCommit = "9b309ce"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot "visual_asset_inventory_model.psm1") -Force

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$sourceRoot = "docs/design/component-sheets/semantic-v3-approval"
$sourceReport = "$sourceRoot/runtime-visual-inventory-report.html"
$sourceData = "$sourceRoot/runtime-visual-inventory.json"
$targetRelative = "docs/design/visual-asset-inventory"
$targetRoot = Join-Path $repoRoot ($targetRelative.Replace('/', '\'))

function Get-GitText {
    param(
        [Parameter(Mandatory)] [string]$Commit,
        [Parameter(Mandatory)] [string]$Path
    )

    $content = & git -C $repoRoot show "${Commit}:$Path"
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to read $Path from $Commit."
    }
    return ($content -join "`n")
}

function Export-GitBlob {
    param(
        [Parameter(Mandatory)] [string]$Commit,
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Destination
    )

    $destinationDirectory = Split-Path -Parent $Destination
    [System.IO.Directory]::CreateDirectory($destinationDirectory) | Out-Null

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = "git"
    $startInfo.WorkingDirectory = $repoRoot
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.ArgumentList.Add("cat-file")
    $startInfo.ArgumentList.Add("blob")
    $startInfo.ArgumentList.Add("${Commit}:$Path")

    $process = [System.Diagnostics.Process]::Start($startInfo)
    $destinationStream = [System.IO.File]::Open(
        $Destination,
        [System.IO.FileMode]::Create,
        [System.IO.FileAccess]::Write,
        [System.IO.FileShare]::None
    )
    try {
        $process.StandardOutput.BaseStream.CopyTo($destinationStream)
    }
    finally {
        $destinationStream.Dispose()
    }
    $errorText = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) {
        [System.IO.File]::Delete($Destination)
        throw "Unable to restore $Path from $Commit. $errorText"
    }
}

function Convert-ToRepositoryPath {
    param([Parameter(Mandatory)] [string]$Path)

    return Join-Path $repoRoot ($Path.Replace('/', '\'))
}

function Get-CollectedReviewPath {
    param([Parameter(Mandatory)] [string]$HistoricalPath)

    $approvalEvidenceRoot = "$sourceRoot/evidence/"
    $approvalGeneratedRoot = "$sourceRoot/generated/"
    $proposalRoot = "docs/design/component-sheets/semantic-rework-v2-proposal/"
    if ($HistoricalPath.StartsWith($approvalEvidenceRoot)) {
        return "$targetRelative/review-images/evidence/" +
            $HistoricalPath.Substring($approvalEvidenceRoot.Length)
    }
    if ($HistoricalPath.StartsWith($approvalGeneratedRoot)) {
        return "$targetRelative/review-images/candidates/" +
            $HistoricalPath.Substring($approvalGeneratedRoot.Length)
    }
    if ($HistoricalPath.StartsWith($proposalRoot)) {
        return "$targetRelative/review-images/references/" +
            $HistoricalPath.Substring($proposalRoot.Length)
    }
    throw "Unexpected missing rendered image path: $HistoricalPath"
}

function Rewrite-Paths {
    param(
        [AllowNull()] [object]$Node,
        [Parameter(Mandatory)]
        [System.Collections.Generic.Dictionary[string, string]]$PathMap
    )

    if ($null -eq $Node) {
        return
    }
    if ($Node -is [System.Array]) {
        for ($index = 0; $index -lt $Node.Count; $index += 1) {
            $value = $Node[$index]
            if ($value -is [string] -and $PathMap.ContainsKey($value)) {
                $Node[$index] = $PathMap[$value]
            }
            else {
                Rewrite-Paths -Node $value -PathMap $PathMap
            }
        }
        return
    }
    if ($Node -is [pscustomobject]) {
        foreach ($property in $Node.PSObject.Properties) {
            $value = $property.Value
            if ($value -is [string] -and $PathMap.ContainsKey($value)) {
                $property.Value = $PathMap[$value]
            }
            else {
                Rewrite-Paths -Node $value -PathMap $PathMap
            }
        }
    }
}

function Update-CurrentFileEvidence {
    param([Parameter(Mandatory)] [object]$Data)

    foreach ($record in @($Data.file_ledger)) {
        $absolutePath = Convert-ToRepositoryPath -Path $record.path
        $exists = Test-Path -LiteralPath $absolutePath -PathType Leaf
        $record | Add-Member `
            -NotePropertyName "inventory_metadata_matches_disk" `
            -NotePropertyValue $exists `
            -Force
        if (-not $exists) {
            continue
        }
        $item = Get-Item -LiteralPath $absolutePath
        $record | Add-Member `
            -NotePropertyName "bytes" `
            -NotePropertyValue $item.Length `
            -Force
        $record | Add-Member `
            -NotePropertyName "sha256" `
            -NotePropertyValue (
                (Get-FileHash -LiteralPath $absolutePath -Algorithm SHA256).Hash.ToLowerInvariant()
            ) `
            -Force
    }

    foreach ($source in @($Data.evidence_sources)) {
        $path = [string]$source.path
        if ($path -match '^[A-Za-z]:/') {
            continue
        }
        $absolutePath = Convert-ToRepositoryPath -Path $path
        if (Test-Path -LiteralPath $absolutePath -PathType Leaf) {
            $item = Get-Item -LiteralPath $absolutePath
            $source | Add-Member -NotePropertyName "bytes" -NotePropertyValue $item.Length -Force
            $source | Add-Member `
                -NotePropertyName "sha256" `
                -NotePropertyValue (
                    (Get-FileHash -LiteralPath $absolutePath -Algorithm SHA256).Hash.ToLowerInvariant()
                ) `
                -Force
            $source | Add-Member `
                -NotePropertyName "availability" `
                -NotePropertyValue "available_after_restoration" `
                -Force
        }
        else {
            $source | Add-Member `
                -NotePropertyName "availability" `
                -NotePropertyValue "not_restored_or_no_longer_current; historical hash preserved" `
                -Force
        }
    }
}

[System.IO.Directory]::CreateDirectory($targetRoot) | Out-Null
$historicalData = Get-GitText -Commit $SnapshotCommit -Path $sourceData
$data = $historicalData | ConvertFrom-Json -Depth 100
$renderedPaths = Get-VisualAssetInventoryRenderedMediaPaths -Data $data

$pathMap = [System.Collections.Generic.Dictionary[string, string]]::new(
    [System.StringComparer]::Ordinal
)
foreach ($path in $renderedPaths) {
    if ($path -notmatch '^(docs|art)/') {
        continue
    }
    $currentPath = Convert-ToRepositoryPath -Path $path
    if (Test-Path -LiteralPath $currentPath -PathType Leaf) {
        continue
    }
    $collectedPath = Get-CollectedReviewPath -HistoricalPath $path
    $pathMap.Add($path, $collectedPath)
    Export-GitBlob `
        -Commit $SnapshotCommit `
        -Path $path `
        -Destination (Convert-ToRepositoryPath -Path $collectedPath)
}

Rewrite-Paths -Node $data -PathMap $pathMap
Update-CurrentFileEvidence -Data $data
$data.title = "Cardborne 런타임 비주얼 AS-IS / TO-BE 매칭 리포트 · 복원본"
$data | Add-Member -NotePropertyName "restoration" -NotePropertyValue ([pscustomobject]@{
    restored_on = "2026-08-02"
    source_commit = $SnapshotCommit
    authority = "Evidence only. AGENTS.md, vehicle_game_spec.md, and UI_VISUAL_SYSTEM.md remain authoritative."
    review_image_count = $pathMap.Count
    current_gameplay_manifest = "art/gameplay/semantic-v2/asset-manifest.json"
    current_ui_manifest = "art/ui/production/semantic-v2/ui-asset-manifest.json"
}) -Force

$json = $data | ConvertTo-Json -Depth 100
$jsonPath = Join-Path $targetRoot "inventory.json"
[System.IO.File]::WriteAllText(
    $jsonPath,
    $json + "`n",
    [System.Text.UTF8Encoding]::new($false)
)

$report = Get-GitText -Commit $SnapshotCommit -Path $sourceReport
foreach ($entry in $pathMap.GetEnumerator()) {
    $report = $report.Replace($entry.Key, $entry.Value)
}
$report = $report.Replace(
    "var reportPrefix = '../../../../';",
    "var reportPrefix = '../../../';"
)
$report = $report.Replace(
    "<title>Cardborne 런타임 비주얼 인벤토리</title>",
    "<title>Cardborne 런타임 비주얼 인벤토리 · 복원본</title>"
)
$report = $report.Replace(
    "<h1>Cardborne 런타임 비주얼 AS-IS / TO-BE 매칭</h1>",
    "<h1>Cardborne 런타임 비주얼 AS-IS / TO-BE 매칭 · 복원본</h1>"
)
$banner = @'
    <aside class="restoration-banner" role="note">
      <strong>복원된 검토 스냅샷</strong>
      <span>2026-08-01 inventory와 후보를 2026-08-02에 선별 복원했습니다. 후보는 승인안이 아니며 현재 정본은 AGENTS.md, vehicle_game_spec.md, UI_VISUAL_SYSTEM.md입니다.</span>
    </aside>
'@
$report = $report.Replace("<body>", "<body>`n$banner")
$report = $report.Replace(
    "</style>",
    @'
    .restoration-banner {
      margin: 0;
      padding: 12px clamp(18px, 4vw, 52px);
      display: flex;
      gap: 10px;
      align-items: baseline;
      background: #3a2c12;
      border-bottom: 1px solid #9e7728;
      color: #f5e5b6;
      font-size: 14px;
      line-height: 1.5;
    }
    .restoration-banner strong { white-space: nowrap; }
    .table-shell table {
      min-width: 1540px;
      table-layout: fixed;
    }
    .table-shell th:nth-child(1), .table-shell td:nth-child(1) { width: 88px; }
    .table-shell th:nth-child(2), .table-shell td:nth-child(2) { width: 190px; }
    .table-shell th:nth-child(3), .table-shell td:nth-child(3) { width: 140px; }
    .table-shell th:nth-child(4), .table-shell td:nth-child(4) { width: 150px; }
    .table-shell th:nth-child(5), .table-shell td:nth-child(5) { width: 260px; }
    .table-shell th:nth-child(6), .table-shell td:nth-child(6) { width: 270px; }
    .table-shell th:nth-child(7), .table-shell td:nth-child(7) { width: 100px; }
    .table-shell th:nth-child(8), .table-shell td:nth-child(8) { width: 160px; }
    .table-shell th:nth-child(9), .table-shell td:nth-child(9) { width: 180px; }
    .table-shell .path-cell,
    .table-shell .hash {
      max-width: none;
      overflow-wrap: anywhere;
    }
    @media (max-width: 640px) {
      .restoration-banner { align-items: flex-start; flex-direction: column; gap: 2px; }
      .restoration-banner strong { white-space: normal; }
    }
  </style>
'@
)
$embeddedJson = ($data | ConvertTo-Json -Depth 100 -Compress).
    Replace('&', '\u0026').Replace('<', '\u003c').Replace('>', '\u003e')
$inventoryPattern = '(?s)(<script id="inventory-data" type="application/json">).*?(</script>)'
$report = [System.Text.RegularExpressions.Regex]::Replace(
    $report,
    $inventoryPattern,
    { param($match) $match.Groups[1].Value + $embeddedJson + $match.Groups[2].Value },
    1
)
$reportPath = Join-Path $targetRoot "index.html"
[System.IO.File]::WriteAllText(
    $reportPath,
    $report + "`n",
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host (
    "VISUAL_ASSET_INVENTORY_RESTORED report={0} ledger={1} review_images={2}" -f
        $reportPath,
        $data.file_ledger.Count,
        $pathMap.Count
)
