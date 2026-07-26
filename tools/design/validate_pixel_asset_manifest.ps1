param(
    [Parameter(Mandatory = $true)]
    [string]$ManifestPath,

    [switch]$RequireInputFiles
)

$ErrorActionPreference = "Stop"

function Resolve-RepoPath {
    param([string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $script:RepoRoot $Path))
}

function Test-PointInside {
    param(
        [object[]]$Point,
        [int]$Width,
        [int]$Height
    )

    return (
        $Point.Count -eq 2 -and
        [int]$Point[0] -ge 0 -and
        [int]$Point[0] -lt $Width -and
        [int]$Point[1] -ge 0 -and
        [int]$Point[1] -lt $Height
    )
}

function Add-MissingPathError {
    param(
        [string]$RelativePath,
        [string]$Label
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        $script:Errors.Add("$Label path must not be empty")
        return
    }
    if (-not [System.IO.File]::Exists((Resolve-RepoPath -Path $RelativePath))) {
        $script:Errors.Add("missing $Label input: $RelativePath")
    }
}

$script:RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$manifestFile = Resolve-RepoPath -Path $ManifestPath
if (-not [System.IO.File]::Exists($manifestFile)) {
    throw "Pixel asset manifest does not exist: $manifestFile"
}

$manifest = Get-Content -LiteralPath $manifestFile -Raw | ConvertFrom-Json
$script:Errors = [System.Collections.Generic.List[string]]::new()
$idPattern = "^[a-z0-9_]+$"
$colorPattern = "^#[0-9A-Fa-f]{6}$"
$hashPattern = "^[0-9a-f]{64}$"
$schemaVersion = [int]$manifest.schema_version

if ($schemaVersion -notin @(1, 2)) {
    $script:Errors.Add("schema_version must be 1 or 2")
}
if ([string]$manifest.id -notmatch $idPattern) {
    $script:Errors.Add("invalid manifest id: $($manifest.id)")
}
if ([string]$manifest.family -notmatch $idPattern) {
    $script:Errors.Add("invalid manifest family: $($manifest.family)")
}
if ([string]$manifest.transparent_color -notmatch $colorPattern) {
    $script:Errors.Add("transparent_color must be a six-digit hex color")
}

$logicalSize = @($manifest.logical_size)
$logicalWidth = 0
$logicalHeight = 0
if ($logicalSize.Count -ne 2) {
    $script:Errors.Add("logical_size must contain width and height")
} else {
    $logicalWidth = [int]$logicalSize[0]
    $logicalHeight = [int]$logicalSize[1]
    if ($logicalWidth -le 0 -or $logicalHeight -le 0) {
        $script:Errors.Add("logical_size values must be positive")
    }
    if ($logicalWidth -ne $logicalHeight) {
        $script:Errors.Add("per-frame logical_size must be square; pack rectangular atlases after frame approval")
    }
}

if ($schemaVersion -eq 1) {
    if ([int]$manifest.canvas_size -lt 64 -or [int]$manifest.canvas_size -gt 2048) {
        $script:Errors.Add("canvas_size must be between 64 and 2048")
    }
    if ($logicalWidth -gt 0 -and [int]$manifest.canvas_size % $logicalWidth -ne 0) {
        $script:Errors.Add("canvas_size must divide evenly by logical_size")
    }
} elseif ($schemaVersion -eq 2) {
    if ([int]$manifest.guide_size -notin @(512, 768)) {
        $script:Errors.Add("guide_size must be 512 or 768")
    }
    if ([string]$manifest.approval_status -notin @("proof", "candidate", "approved")) {
        $script:Errors.Add("unknown approval_status: $($manifest.approval_status)")
    }
    if ([string]$manifest.production_method -notin @("imagegen_assisted", "direct_pixel", "derived_view")) {
        $script:Errors.Add("unknown production_method: $($manifest.production_method)")
    }
    if ([string]$manifest.runtime_group -notmatch $idPattern) {
        $script:Errors.Add("invalid runtime_group: $($manifest.runtime_group)")
    }
    if (@($manifest.reference_ids).Count -lt 1 -or @($manifest.reference_ids).Count -gt 3) {
        $script:Errors.Add("reference_ids must contain one to three entries")
    }
    if (@($manifest.reference_ids | Sort-Object -Unique).Count -ne @($manifest.reference_ids).Count) {
        $script:Errors.Add("reference_ids must be unique")
    }
    if (@($manifest.avoid_rules).Count -lt 1) {
        $script:Errors.Add("avoid_rules must contain at least one entry")
    } elseif (@($manifest.avoid_rules | Sort-Object -Unique).Count -ne @($manifest.avoid_rules).Count) {
        $script:Errors.Add("avoid_rules must be unique")
    }
    if (@($manifest.review_backgrounds).Count -lt 2) {
        $script:Errors.Add("review_backgrounds must contain at least two palette roles")
    } elseif (@($manifest.review_backgrounds | Sort-Object -Unique).Count -ne @($manifest.review_backgrounds).Count) {
        $script:Errors.Add("review_backgrounds must be unique")
    }
    if ([double]$manifest.silhouette_area_tolerance -lt 0 -or [double]$manifest.silhouette_area_tolerance -gt 0.25) {
        $script:Errors.Add("silhouette_area_tolerance must be between 0 and 0.25")
    }
    if ([int]$manifest.anchor_tolerance -ne 1) {
        $script:Errors.Add("anchor_tolerance must be exactly 1 logical pixel")
    }
    if ([string]::IsNullOrWhiteSpace([string]$manifest.collision_reference)) {
        $script:Errors.Add("collision_reference must not be empty")
    }
    if ($null -ne $manifest.tile_signature -and [string]$manifest.tile_signature -ne "orthogonal_16") {
        $script:Errors.Add("tile_signature must be null or orthogonal_16")
    }
}

$layerIds = @{}
$layerColors = @{}
$layerZ = @{}
foreach ($layer in @($manifest.layers)) {
    $layerId = [string]$layer.id
    $maskColor = ([string]$layer.mask_color).ToUpperInvariant()
    if ($layerId -notmatch $idPattern) {
        $script:Errors.Add("invalid layer id: $layerId")
    }
    if ($layerIds.ContainsKey($layerId)) {
        $script:Errors.Add("duplicate layer id: $layerId")
    }
    if ($maskColor -notmatch $colorPattern) {
        $script:Errors.Add("$layerId has invalid mask_color: $maskColor")
    }
    if ($layerColors.ContainsKey($maskColor)) {
        $script:Errors.Add("duplicate layer mask_color: $maskColor")
    }
    if ($layerZ.ContainsKey([int]$layer.z)) {
        $script:Errors.Add("duplicate layer z: $($layer.z)")
    }
    $layerIds[$layerId] = $true
    $layerColors[$maskColor] = $true
    $layerZ[[int]$layer.z] = $true
}
if ($layerIds.Count -eq 0) {
    $script:Errors.Add("manifest must contain at least one semantic layer")
}

if ($schemaVersion -eq 2) {
    if (@($manifest.runtime_layers).Count -eq 0) {
        $script:Errors.Add("runtime_layers must contain at least one layer")
    } elseif (@($manifest.runtime_layers | Sort-Object -Unique).Count -ne @($manifest.runtime_layers).Count) {
        $script:Errors.Add("runtime_layers must be unique")
    }
    foreach ($runtimeLayer in @($manifest.runtime_layers)) {
        if (-not $layerIds.ContainsKey([string]$runtimeLayer)) {
            $script:Errors.Add("runtime layer is not declared in layers: $runtimeLayer")
        }
    }
}

if ($logicalWidth -gt 0 -and $logicalHeight -gt 0) {
    if (-not (Test-PointInside -Point @($manifest.pivot) -Width $logicalWidth -Height $logicalHeight)) {
        $script:Errors.Add("pivot must be inside logical_size")
    }
    foreach ($anchorProperty in @($manifest.anchors.PSObject.Properties)) {
        if (-not (Test-PointInside -Point @($anchorProperty.Value) -Width $logicalWidth -Height $logicalHeight)) {
            $script:Errors.Add("anchor $($anchorProperty.Name) must be inside logical_size")
        }
    }
}

$frameIds = @{}
$atlasIndices = @{}
$frameTuples = @{}
$tileEdgeSignatures = @{}
foreach ($frame in @($manifest.frames)) {
    $frameId = [string]$frame.id
    $atlasIndex = [int]$frame.atlas_index
    if ($frameId -notmatch $idPattern) {
        $script:Errors.Add("invalid frame id: $frameId")
    }
    if ($frameIds.ContainsKey($frameId)) {
        $script:Errors.Add("duplicate frame id: $frameId")
    }
    if ($atlasIndices.ContainsKey($atlasIndex)) {
        $script:Errors.Add("duplicate atlas_index: $atlasIndex")
    }
    if ($atlasIndex -lt 0) {
        $script:Errors.Add("atlas_index must not be negative: $atlasIndex")
    }
    $frameIds[$frameId] = $true
    $atlasIndices[$atlasIndex] = $true

    if ($schemaVersion -eq 2) {
        if ([string]$frame.variant -notmatch $idPattern) {
            $script:Errors.Add("$frameId has invalid variant: $($frame.variant)")
        }
        if ([string]$frame.state -notmatch $idPattern) {
            $script:Errors.Add("$frameId has invalid state: $($frame.state)")
        }
        if ([int]$frame.direction_index -lt 0 -or [int]$frame.direction_index -gt 15) {
            $script:Errors.Add("$frameId direction_index must be between 0 and 15")
        }
        if ([int]$frame.duration_ms -lt 0 -or [int]$frame.duration_ms -gt 10000) {
            $script:Errors.Add("$frameId duration_ms must be between 0 and 10000")
        }
        if ([int]$frame.sequence_index -lt 0 -or [int]$frame.sequence_index -gt 31) {
            $script:Errors.Add("$frameId sequence_index must be between 0 and 31")
        }
        $tuple = "$($frame.variant)|$([int]$frame.direction_index)|$($frame.state)|$([int]$frame.sequence_index)"
        if ($frameTuples.ContainsKey($tuple)) {
            $script:Errors.Add("duplicate variant/direction/state/sequence tuple: $tuple")
        }
        $frameTuples[$tuple] = $true
        if ([string]$frame.source_sha256 -notmatch $hashPattern) {
            $script:Errors.Add("$frameId source_sha256 must be lowercase SHA-256")
        }
        if ([string]$manifest.tile_signature -eq "orthogonal_16") {
            $edgeNames = @("north", "east", "south", "west")
            $tileEdgesProperty = $frame.PSObject.Properties["tile_edges"]
            if ($null -eq $tileEdgesProperty) {
                $script:Errors.Add("$frameId must declare tile_edges for orthogonal_16")
            } else {
                $tileEdges = $tileEdgesProperty.Value
                $edgeBits = foreach ($edgeName in $edgeNames) {
                    $edgeProperty = $tileEdges.PSObject.Properties[$edgeName]
                    if ($null -eq $edgeProperty) {
                        $script:Errors.Add("$frameId tile_edges is missing $edgeName")
                    }
                    if ($null -ne $edgeProperty -and [bool]$edgeProperty.Value) { "1" } else { "0" }
                }
                $edgeSignature = $edgeBits -join ""
                if ($tileEdgeSignatures.ContainsKey($edgeSignature)) {
                    $script:Errors.Add("duplicate orthogonal tile edge signature: $edgeSignature")
                }
                $tileEdgeSignatures[$edgeSignature] = $true
            }
        } elseif ($null -ne $frame.PSObject.Properties["tile_edges"]) {
            $script:Errors.Add("$frameId declares tile_edges but tile_signature is not orthogonal_16")
        }
    }
}
if ([string]$manifest.tile_signature -eq "orthogonal_16" -and $tileEdgeSignatures.Count -ne 16) {
    $script:Errors.Add("orthogonal_16 manifests must contain all 16 unique tile edge signatures")
}
if ($frameIds.Count -eq 0) {
    $script:Errors.Add("manifest must contain at least one frame")
}
for ($index = 0; $index -lt $frameIds.Count; $index++) {
    if (-not $atlasIndices.ContainsKey($index)) {
        $script:Errors.Add("atlas_index values must be contiguous from zero; missing $index")
    }
}

if ([int]$manifest.atlas.columns -le 0) {
    $script:Errors.Add("atlas.columns must be positive")
}
if ($schemaVersion -eq 1) {
    if ([int]$manifest.atlas.padding -lt 0) {
        $script:Errors.Add("atlas.padding must not be negative")
    }
} elseif ([int]$manifest.atlas.padding -ne 2 -or [int]$manifest.atlas.extrude -ne 1) {
    $script:Errors.Add("v2 atlases require padding=2 and extrude=1")
}

Add-MissingPathError -RelativePath ([string]$manifest.palette_path) -Label "palette"
Add-MissingPathError -RelativePath ([string]$manifest.semantic_palette_path) -Label "semantic palette"

if ($schemaVersion -eq 2) {
    $palettePath = Resolve-RepoPath -Path ([string]$manifest.palette_path)
    $semanticPalettePath = Resolve-RepoPath -Path ([string]$manifest.semantic_palette_path)
    $palette = if ([System.IO.File]::Exists($palettePath)) {
        Get-Content -LiteralPath $palettePath -Raw | ConvertFrom-Json
    } else {
        $null
    }
    $semanticPalette = if ([System.IO.File]::Exists($semanticPalettePath)) {
        Get-Content -LiteralPath $semanticPalettePath -Raw | ConvertFrom-Json
    } else {
        $null
    }
    if ($null -ne $palette -and [string]$palette.transparent_color -ne [string]$manifest.transparent_color) {
        $script:Errors.Add("display palette transparent_color does not match manifest")
    }
    if ($null -ne $semanticPalette) {
        $semanticColors = @($semanticPalette.colors.PSObject.Properties.Value | ForEach-Object { ([string]$_).ToUpperInvariant() })
        foreach ($maskColor in $layerColors.Keys) {
            if ($maskColor -notin $semanticColors) {
                $script:Errors.Add("layer mask color is not in semantic palette: $maskColor")
            }
        }
    }
    if ($null -ne $palette) {
        $paletteRoles = @($palette.colors.PSObject.Properties.Name)
        foreach ($background in @($manifest.review_backgrounds)) {
            if ([string]$background -notin $paletteRoles) {
                $script:Errors.Add("unknown review background palette role: $background")
            }
        }
    }

    $referenceManifestPath = Join-Path $script:RepoRoot "docs/design/pixel-space-hangar-visual-research/reference-manifest.json"
    if ([System.IO.File]::Exists($referenceManifestPath)) {
        $referenceManifest = Get-Content -LiteralPath $referenceManifestPath -Raw | ConvertFrom-Json
        $referenceIds = @(
            @($referenceManifest.game_references) +
            @($referenceManifest.free_asset_references)
        ) | ForEach-Object { [string]$_.id }
        foreach ($referenceId in @($manifest.reference_ids)) {
            if ([string]$referenceId -notin $referenceIds) {
                $script:Errors.Add("unknown reference id: $referenceId")
            }
        }
    }
}

if ($RequireInputFiles) {
    $magick = Get-Command magick -ErrorAction Stop
    foreach ($frame in @($manifest.frames)) {
        $sourcePath = Resolve-RepoPath -Path ([string]$frame.source_path)
        $maskPath = Resolve-RepoPath -Path ([string]$frame.semantic_mask_path)
        Add-MissingPathError -RelativePath ([string]$frame.source_path) -Label "$($frame.id) source"
        Add-MissingPathError -RelativePath ([string]$frame.semantic_mask_path) -Label "$($frame.id) semantic mask"
        if (
            $schemaVersion -eq 2 -and
            [System.IO.File]::Exists($sourcePath) -and
            [System.IO.File]::Exists($maskPath)
        ) {
            $sourceSize = (& $magick.Source identify -format "%w %h" $sourcePath).Trim()
            $maskSize = (& $magick.Source identify -format "%w %h" $maskPath).Trim()
            if ($sourceSize -ne "$logicalWidth $logicalHeight") {
                $script:Errors.Add("$($frame.id) source must be ${logicalWidth}x${logicalHeight}; got $sourceSize")
            }
            if ($maskSize -ne "$logicalWidth $logicalHeight") {
                $script:Errors.Add("$($frame.id) semantic mask must be ${logicalWidth}x${logicalHeight}; got $maskSize")
            }
            $actualHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
            if ($actualHash -ne [string]$frame.source_sha256) {
                $script:Errors.Add("$($frame.id) source_sha256 does not match source_path")
            }
        }
    }
}

if ($script:Errors.Count -gt 0) {
    $details = ($script:Errors | ForEach-Object { "- $_" }) -join [Environment]::NewLine
    throw "Pixel asset manifest validation failed with $($script:Errors.Count) error(s).$([Environment]::NewLine)$details"
}

Write-Output "Pixel asset manifest valid: $($manifest.id) (schema v$schemaVersion)"
Write-Output "Logical size: ${logicalWidth}x${logicalHeight}; layers=$($layerIds.Count); frames=$($frameIds.Count)"
