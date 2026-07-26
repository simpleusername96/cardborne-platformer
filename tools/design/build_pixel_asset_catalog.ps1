param(
    [Parameter(Mandatory = $true)]
    [string[]]$AtlasMetadataPaths,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

function Resolve-RepoPath {
    param([string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $script:RepoRoot $Path))
}

$script:RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$destination = Resolve-RepoPath -Path $OutputPath
$assetIds = @{}
$frameKeys = @{}
$assets = [System.Collections.Generic.List[object]]::new()
$runtimeGroups = @{}
$frameCount = 0

foreach ($metadataPath in $AtlasMetadataPaths) {
    $resolvedMetadata = Resolve-RepoPath -Path $metadataPath
    if (-not [System.IO.File]::Exists($resolvedMetadata)) {
        throw "Atlas metadata does not exist: $metadataPath"
    }
    $metadata = Get-Content -LiteralPath $resolvedMetadata -Raw | ConvertFrom-Json
    if ([int]$metadata.schema_version -ne 2) {
        throw "Production catalog accepts schema-version-2 atlas metadata only: $metadataPath"
    }
    $assetId = [string]$metadata.asset_id
    if ($assetIds.ContainsKey($assetId)) {
        throw "Duplicate asset_id in catalog input: $assetId"
    }
    $assetIds[$assetId] = $true

    $atlasPath = Resolve-RepoPath -Path ([string]$metadata.atlas_path)
    if (-not [System.IO.File]::Exists($atlasPath)) {
        throw "Atlas image does not exist: $($metadata.atlas_path)"
    }
    $atlasHash = (Get-FileHash -LiteralPath $atlasPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $frames = [System.Collections.Generic.List[object]]::new()
    foreach ($frame in @($metadata.frames | Sort-Object {[int]$_.atlas_index})) {
        $key = "$assetId/$($frame.variant)/$([int]$frame.direction)/$($frame.state)/$([int]$frame.sequence_index)"
        if ($frameKeys.ContainsKey($key)) {
            throw "Duplicate stable frame key: $key"
        }
        $frameKeys[$key] = $true
        $frames.Add([ordered]@{
            key = $key
            id = [string]$frame.id
            atlas_index = [int]$frame.atlas_index
            region = @($frame.region)
            cell_region = @($frame.cell_region)
            pivot = @($frame.pivot)
            anchors = $frame.anchors
            variant = [string]$frame.variant
            direction_index = [int]$frame.direction
            state = [string]$frame.state
            sequence_index = [int]$frame.sequence_index
            duration_ms = [int]$frame.duration_ms
            source_sha256 = [string]$frame.source_sha256
        })
        $frameCount++
    }
    $runtimeGroup = [string]$metadata.runtime_group
    $runtimeGroups[$runtimeGroup] = 1 + [int]$runtimeGroups[$runtimeGroup]
    $assets.Add([ordered]@{
        id = $assetId
        family = [string]$metadata.family
        runtime_group = $runtimeGroup
        runtime_layers = @($metadata.runtime_layers)
        approval_status = [string]$metadata.approval_status
        atlas_path = [string]$metadata.atlas_path
        atlas_sha256 = $atlasHash
        atlas_size = @($metadata.atlas_size)
        frame_size = @($metadata.frame_size)
        cell_size = @($metadata.cell_size)
        padding = [int]$metadata.padding
        extrude = [int]$metadata.extrude
        frames = @($frames)
    })
}

$catalog = [ordered]@{
    schema_version = 1
    generated_from = @($AtlasMetadataPaths | ForEach-Object { $_.Replace("\", "/") })
    asset_count = $assets.Count
    frame_count = $frameCount
    runtime_groups = [ordered]@{}
    assets = @($assets | Sort-Object {[string]$_.id})
}
foreach ($entry in $runtimeGroups.GetEnumerator() | Sort-Object Name) {
    $catalog.runtime_groups[$entry.Name] = [int]$entry.Value
}

$destinationDirectory = [System.IO.Path]::GetDirectoryName($destination)
if (-not [System.IO.Directory]::Exists($destinationDirectory)) {
    [System.IO.Directory]::CreateDirectory($destinationDirectory) | Out-Null
}
[System.IO.File]::WriteAllText(
    $destination,
    ($catalog | ConvertTo-Json -Depth 12),
    [System.Text.UTF8Encoding]::new($false)
)

Write-Output "Pixel asset catalog built: $destination"
Write-Output "Assets=$($assets.Count); frames=$frameCount; runtime_groups=$($runtimeGroups.Count)"
