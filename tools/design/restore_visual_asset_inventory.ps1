[CmdletBinding()]
param(
    [string]$SnapshotCommit = "9b309ce"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot "visual_asset_inventory_model.psm1") -Force

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$sourceRoot = "docs/design/component-sheets/semantic-v3-approval"
$sourceData = "$sourceRoot/runtime-visual-inventory.json"
$targetRelative = "docs/design/visual-asset-inventory"
$targetRoot = Join-Path $repoRoot ($targetRelative.Replace('/', '\'))
$templatePath = Join-Path $targetRoot "report-template.html"
$currentReviewOverlayPath = Join-Path $targetRoot "current-review-overrides.json"

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

function Apply-CurrentReviewOverlay {
    param(
        [Parameter(Mandatory)] [object]$Data,
        [Parameter(Mandatory)] [object]$Overlay
    )

    if ([int]$Overlay.schema_version -ne 1) {
        throw "Unsupported current review overlay schema: $($Overlay.schema_version)"
    }

    foreach ($patch in @($Overlay.collection_patches)) {
        $collectionName = [string]$patch.collection
        $collectionProperty = $Data.PSObject.Properties[$collectionName]
        if ($null -eq $collectionProperty) {
            throw "Overlay patch references missing collection: $collectionName"
        }
        $matches = @(
            @($collectionProperty.Value) |
                Where-Object { [string]$_.id -ceq [string]$patch.id }
        )
        if ($matches.Count -ne 1) {
            throw "Overlay patch requires exactly one $collectionName id=$($patch.id); found $($matches.Count)."
        }
        foreach ($property in $patch.set.PSObject.Properties) {
            $matches[0] | Add-Member `
                -NotePropertyName $property.Name `
                -NotePropertyValue $property.Value `
                -Force
        }
    }

    foreach ($addition in @($Overlay.collection_additions)) {
        $collectionName = [string]$addition.collection
        $collectionProperty = $Data.PSObject.Properties[$collectionName]
        if ($null -eq $collectionProperty) {
            throw "Overlay addition references missing collection: $collectionName"
        }
        $itemId = [string]$addition.item.id
        $matches = @(
            @($collectionProperty.Value) |
                Where-Object { [string]$_.id -ceq $itemId }
        )
        if ($matches.Count -ne 0) {
            throw "Overlay addition duplicates $collectionName id=$itemId."
        }
        $collectionProperty.Value = @($collectionProperty.Value) + @($addition.item)
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
if (-not (Test-Path -LiteralPath $currentReviewOverlayPath -PathType Leaf)) {
    throw "Missing current review overlay: $currentReviewOverlayPath"
}
$currentReviewOverlay = Get-Content -Raw -LiteralPath $currentReviewOverlayPath |
    ConvertFrom-Json -Depth 100
Apply-CurrentReviewOverlay -Data $data -Overlay $currentReviewOverlay
Update-CurrentFileEvidence -Data $data
$currentRenderedPaths = Get-VisualAssetInventoryRenderedMediaPaths -Data $data
$reviewImageCount = @(
    $currentRenderedPaths |
        Where-Object { $_.StartsWith("$targetRelative/review-images/") }
).Count
$data.title = "Cardborne 런타임 비주얼 AS-IS / TO-BE 매칭 리포트 · 복원본 + 현재 후보"
$data | Add-Member -NotePropertyName "restoration" -NotePropertyValue ([pscustomobject]@{
    restored_on = "2026-08-02"
    source_commit = $SnapshotCommit
    authority = "Evidence only. AGENTS.md, vehicle_game_spec.md, and VISUAL_SYSTEM.md remain authoritative."
    review_image_count = $reviewImageCount
    current_review_overlay = "$targetRelative/current-review-overrides.json"
    current_review_authority = "Art-style approval only. Every candidate asset remains unapproved and is not connected to runtime."
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

$report = [System.IO.File]::ReadAllText($templatePath)
$placeholder = "__INVENTORY_JSON__"
if (($report.Split($placeholder).Count - 1) -ne 1) {
    throw "Report template must contain exactly one $placeholder placeholder."
}
$embeddedJson = ($data | ConvertTo-Json -Depth 100 -Compress).
    Replace('&', '\u0026').Replace('<', '\u003c').Replace('>', '\u003e')
$report = $report.Replace($placeholder, $embeddedJson)
$reportPath = Join-Path $targetRoot "index.html"
[System.IO.File]::WriteAllText(
    $reportPath,
    $report.TrimEnd([char[]]"`r`n") + "`n",
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host (
    "VISUAL_ASSET_INVENTORY_RESTORED report={0} ledger={1} review_images={2}" -f
        $reportPath,
        $data.file_ledger.Count,
        $reviewImageCount
)
