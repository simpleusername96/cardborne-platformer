Set-StrictMode -Version Latest

$script:ProductionRoot = 'art/visuals/production'
$script:WorkbenchRoot = 'docs/design/visual-replacement-workbench'
$script:StyleAuthorityPath = 'docs/design/VISUAL_SYSTEM.md'
$script:StyleReferenceSheetPath = 'docs/design/cardborne-universal-art-style-reference.png'
$script:StyleReferenceSheetSha256 = '96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889'
$script:StyleReferenceSheetWidth = 1448
$script:StyleReferenceSheetHeight = 1086
$script:Statuses = @(
    'keep_current', 'target_required', 'switch_ready',
    'approved_for_switch', 'applied', 'retired'
)
$script:Owners = @(
    'gameplay_manifest', 'ui_manifest', 'ui_theme',
    'procedural_presentation', 'composite'
)
$script:SwitchKinds = @('replace', 'add', 'consolidate', 'retire')
$script:TechnicalRecordOwners = @('BK', 'autonomous-executor')

function ConvertTo-NormalizedVisualPath {
    param([Parameter(Mandatory)][string]$Path)
    $normalized = $Path.Replace('\', '/')
    while ($normalized.StartsWith('./', [StringComparison]::Ordinal)) {
        $normalized = $normalized.Substring(2)
    }
    return $normalized
}

function Resolve-VisualRepositoryPath {
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$Path
    )
    $normalized = ConvertTo-NormalizedVisualPath $Path
    if ([string]::IsNullOrWhiteSpace($normalized) -or
        $normalized -match '(^|/)\.\.(/|$)' -or
        [IO.Path]::IsPathRooted($normalized)) {
        throw "unsafe repository-relative path: $Path"
    }
    $root = [IO.Path]::GetFullPath($RepoRoot).TrimEnd('\', '/')
    $resolved = [IO.Path]::GetFullPath((Join-Path $root $normalized.Replace('/', '\')))
    if (-not $resolved.StartsWith($root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw "path escapes repository: $Path"
    }
    return $resolved
}

function Get-VisualPngDimensions {
    param([Parameter(Mandatory)][string]$LiteralPath)
    $stream = [IO.File]::OpenRead($LiteralPath)
    try {
        $header = New-Object byte[] 24
        if ($stream.Read($header, 0, 24) -ne 24 -or
            $header[0] -ne 137 -or $header[1] -ne 80 -or
            $header[2] -ne 78 -or $header[3] -ne 71) {
            throw "invalid PNG header: $LiteralPath"
        }
        $width = (
            ([int64]$header[16] * 16777216) +
            ([int64]$header[17] * 65536) +
            ([int64]$header[18] * 256) +
            [int64]$header[19]
        )
        $height = (
            ([int64]$header[20] * 16777216) +
            ([int64]$header[21] * 65536) +
            ([int64]$header[22] * 256) +
            [int64]$header[23]
        )
        return @([int]$width, [int]$height)
    }
    finally {
        $stream.Dispose()
    }
}

function Get-VisualSha256 {
    param([Parameter(Mandatory)][string]$LiteralPath)
    return (Get-FileHash -LiteralPath $LiteralPath -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-VisualProductionMediaPaths {
    param([Parameter(Mandatory)][string]$RepoRoot)
    $root = Resolve-VisualRepositoryPath -RepoRoot $RepoRoot -Path $script:ProductionRoot
    return @(
        Get-ChildItem -LiteralPath $root -Recurse -File |
            Where-Object { $_.Extension -in @('.png', '.ttf') } |
            ForEach-Object {
                ConvertTo-NormalizedVisualPath $_.FullName.Substring($RepoRoot.Length + 1)
            } |
            Sort-Object
    )
}

function Get-VisualCanonicalJson {
    param([Parameter(Mandatory)]$Value)
    return ($Value | ConvertTo-Json -Depth 100 -Compress)
}

function Write-VisualUtf8Lf {
    param(
        [Parameter(Mandatory)][string]$LiteralPath,
        [Parameter(Mandatory)][string]$Text
    )
    $normalized = $Text.Replace("`r`n", "`n").Replace("`r", "`n").TrimEnd("`n") + "`n"
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($LiteralPath)) | Out-Null
    [IO.File]::WriteAllText($LiteralPath, $normalized, [Text.UTF8Encoding]::new($false))
}

function Test-VisualObjectFields {
    param($Object, [string[]]$Allowed, [string]$Context, [Collections.Generic.List[string]]$Failures)
    foreach ($field in $Object.PSObject.Properties.Name) {
        if ($field -notin $Allowed) { $Failures.Add("unknown field in ${Context}: $field") }
    }
}

function Get-VisualReplacementProjection {
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)]$Source
    )
    $failures = [Collections.Generic.List[string]]::new()
    Test-VisualObjectFields $Source @('schema_version','production_root','style_authority','style_reference_sheet','external_sources','categories','units') 'source' $failures
    if ($Source.schema_version -ne 2) { $failures.Add('schema_version must be 2') }
    if ($Source.production_root -cne $script:ProductionRoot) { $failures.Add('production_root is not canonical') }
    $styleAuthorityProperty = $Source.PSObject.Properties['style_authority']
    $styleAuthorityPath = if ($null -ne $styleAuthorityProperty) { [string]$styleAuthorityProperty.Value } else { '' }
    if ([string]::IsNullOrWhiteSpace($styleAuthorityPath)) {
        $failures.Add('missing style_authority')
    } elseif ($styleAuthorityPath -cne $script:StyleAuthorityPath) {
        $failures.Add('style_authority is not canonical')
    }
    if (-not [string]::IsNullOrWhiteSpace($styleAuthorityPath)) {
        $absoluteStyleAuthority = $null
        try { $absoluteStyleAuthority = Resolve-VisualRepositoryPath $RepoRoot $styleAuthorityPath } catch { $failures.Add($_.Exception.Message) }
        if ($null -ne $absoluteStyleAuthority -and -not (Test-Path -LiteralPath $absoluteStyleAuthority -PathType Leaf)) {
            $failures.Add("missing style authority document: $styleAuthorityPath")
        }
    }

    $styleReferenceSheetProperty = $Source.PSObject.Properties['style_reference_sheet']
    $styleReferenceSheet = if ($null -ne $styleReferenceSheetProperty) { $styleReferenceSheetProperty.Value } else { $null }
    $styleReferencePath = ''
    if ($null -eq $styleReferenceSheet) {
        $failures.Add('missing style_reference_sheet object')
    } elseif ($styleReferenceSheet -isnot [pscustomobject]) {
        $failures.Add('style_reference_sheet must be an object')
    } else {
        $requiredStyleReferenceFields = @('path','sha256','width','height')
        Test-VisualObjectFields $styleReferenceSheet $requiredStyleReferenceFields 'style_reference_sheet' $failures
        foreach ($field in $requiredStyleReferenceFields) {
            if ($null -eq $styleReferenceSheet.PSObject.Properties[$field]) {
                $failures.Add("missing field in style_reference_sheet: $field")
            }
        }

        $pathProperty = $styleReferenceSheet.PSObject.Properties['path']
        if ($null -ne $pathProperty) {
            $styleReferencePath = [string]$pathProperty.Value
            if ($styleReferencePath -cne $script:StyleReferenceSheetPath) {
                $failures.Add('style_reference_sheet.path is not canonical')
            }
        }
        $hashProperty = $styleReferenceSheet.PSObject.Properties['sha256']
        if ($null -ne $hashProperty -and [string]$hashProperty.Value -cne $script:StyleReferenceSheetSha256) {
            $failures.Add('style_reference_sheet.sha256 is not canonical')
        }
        foreach ($dimension in @(
            @('width', $script:StyleReferenceSheetWidth),
            @('height', $script:StyleReferenceSheetHeight)
        )) {
            $dimensionProperty = $styleReferenceSheet.PSObject.Properties[[string]$dimension[0]]
            if ($null -ne $dimensionProperty) {
                if ($dimensionProperty.Value -isnot [int] -and $dimensionProperty.Value -isnot [long]) {
                    $failures.Add("style_reference_sheet.$($dimension[0]) must be an integer")
                } elseif ([int64]$dimensionProperty.Value -ne [int64]$dimension[1]) {
                    $failures.Add("style_reference_sheet.$($dimension[0]) is not canonical")
                }
            }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($styleReferencePath)) {
        $absoluteStyleReference = $null
        try { $absoluteStyleReference = Resolve-VisualRepositoryPath $RepoRoot $styleReferencePath } catch { $failures.Add($_.Exception.Message) }
        if ($null -ne $absoluteStyleReference) {
            if (-not (Test-Path -LiteralPath $absoluteStyleReference -PathType Leaf)) {
                $failures.Add("missing style reference sheet: $styleReferencePath")
            } else {
                if ((Get-VisualSha256 $absoluteStyleReference) -cne $script:StyleReferenceSheetSha256) {
                    $failures.Add("style reference sheet hash mismatch: $styleReferencePath")
                }
                try {
                    $observedStyleReferenceDimensions = Get-VisualPngDimensions $absoluteStyleReference
                    if ($observedStyleReferenceDimensions[0] -ne $script:StyleReferenceSheetWidth -or
                        $observedStyleReferenceDimensions[1] -ne $script:StyleReferenceSheetHeight) {
                        $failures.Add("style reference sheet dimension mismatch: $styleReferencePath")
                    }
                } catch {
                    $failures.Add($_.Exception.Message)
                }
            }
        }
    }

    $externalSourceIds = @{}
    $referencedExternalSourceIds = @{}
    $projectedExternalSources = [Collections.Generic.List[object]]::new()
    foreach ($externalSource in @($Source.external_sources)) {
        $sourceId = [string]$externalSource.id
        Test-VisualObjectFields $externalSource @(
            'id','source_path','official_url','license_name','license_path',
            'archive_sha256','source_sha256','adaptation_scope_en'
        ) "external source $sourceId" $failures
        if ($sourceId -notmatch '^[a-z][a-z0-9_]*$') { $failures.Add("invalid external source id: $sourceId") }
        if ($externalSourceIds.ContainsKey($sourceId)) { $failures.Add("duplicate external source id: $sourceId") }
        $externalSourceIds[$sourceId] = $true
        $sourcePath = ConvertTo-NormalizedVisualPath ([string]$externalSource.source_path)
        $licensePath = ConvertTo-NormalizedVisualPath ([string]$externalSource.license_path)
        if (-not $sourcePath.StartsWith("$script:WorkbenchRoot/external-candidates/sources/")) {
            $failures.Add("external source path escapes curated source root: $sourceId -> $sourcePath")
        }
        if (-not $licensePath.StartsWith("$script:WorkbenchRoot/external-candidates/licenses/")) {
            $failures.Add("external license path escapes curated license root: $sourceId -> $licensePath")
        }
        $absoluteSource = $null
        $absoluteLicense = $null
        try { $absoluteSource = Resolve-VisualRepositoryPath $RepoRoot $sourcePath } catch { $failures.Add($_.Exception.Message) }
        try { $absoluteLicense = Resolve-VisualRepositoryPath $RepoRoot $licensePath } catch { $failures.Add($_.Exception.Message) }
        if ($null -ne $absoluteSource -and -not (Test-Path -LiteralPath $absoluteSource -PathType Leaf)) {
            $failures.Add("missing external source file: $sourceId -> $sourcePath")
        }
        if ($null -ne $absoluteLicense -and -not (Test-Path -LiteralPath $absoluteLicense -PathType Leaf)) {
            $failures.Add("missing external license file: $sourceId -> $licensePath")
        }
        if ([string]$externalSource.official_url -notmatch '^https://[^\s]+$') { $failures.Add("invalid external source URL: $sourceId") }
        if ([string]::IsNullOrWhiteSpace([string]$externalSource.license_name)) { $failures.Add("missing external source license: $sourceId") }
        if ([string]$externalSource.archive_sha256 -notmatch '^[0-9a-f]{64}$') { $failures.Add("invalid external archive hash: $sourceId") }
        if ([string]$externalSource.source_sha256 -notmatch '^[0-9a-f]{64}$') { $failures.Add("invalid selected-source hash: $sourceId") }
        if ([string]::IsNullOrWhiteSpace([string]$externalSource.adaptation_scope_en)) { $failures.Add("missing external adaptation scope: $sourceId") }
        if ($null -ne $absoluteSource -and (Test-Path -LiteralPath $absoluteSource -PathType Leaf)) {
            $observedSourceHash = Get-VisualSha256 $absoluteSource
            if ($observedSourceHash -cne [string]$externalSource.source_sha256) {
                $failures.Add("selected-source hash mismatch: $sourceId -> $sourcePath")
            }
        }
        $projectedExternalSources.Add([ordered]@{
            id=$sourceId;source_path=$sourcePath;official_url=[string]$externalSource.official_url;
            license_name=[string]$externalSource.license_name;license_path=$licensePath;
            archive_sha256=[string]$externalSource.archive_sha256;source_sha256=[string]$externalSource.source_sha256;
            adaptation_scope_en=[string]$externalSource.adaptation_scope_en
        })
    }

    $categoryIds = @{}
    $categoryOrders = @{}
    foreach ($category in @($Source.categories)) {
        Test-VisualObjectFields $category @('id','order','title_en','title_ko') "category $($category.id)" $failures
        if ([string]$category.id -notmatch '^[a-z][a-z0-9_]*$') { $failures.Add("invalid category id: $($category.id)") }
        if ($categoryIds.ContainsKey([string]$category.id)) { $failures.Add("duplicate category id: $($category.id)") }
        if ($categoryOrders.ContainsKey([string]$category.order)) { $failures.Add("duplicate category order: $($category.order)") }
        $categoryIds[[string]$category.id] = $true
        $categoryOrders[[string]$category.order] = $true
    }

    $unitIds = @{}
    $unitOrders = @{}
    $targetPaths = @{}
    $finalPaths = @{}
    $reusePaths = @{}
    $retirePathOwners = @{}
    $coveredMedia = @{}
    $projectedUnits = [Collections.Generic.List[object]]::new()
    foreach ($unit in @($Source.units)) {
        $id = [string]$unit.id
        Test-VisualObjectFields $unit @(
            'id','category_id','order','title_en','title_ko','owner','switch_kind','status',
            'current_paths','consumer_paths','consumer_asset_ids','direction_en','deliverables',
            'final_paths','reuse_paths','preview_paths','rendered_as_is_paths','retire_paths','runtime_change_paths',
            'acceptance_commands','visual_authority_evidence','approval','application'
        ) "unit $id" $failures
        if ($id -notmatch '^[a-z][a-z0-9_]*$') { $failures.Add("invalid unit id: $id") }
        if ($unitIds.ContainsKey($id)) { $failures.Add("duplicate unit id: $id") }
        $unitIds[$id] = $true
        if (-not $categoryIds.ContainsKey([string]$unit.category_id)) { $failures.Add("unknown category for ${id}: $($unit.category_id)") }
        $orderKey = "$($unit.category_id):$($unit.order)"
        if ($unitOrders.ContainsKey($orderKey)) { $failures.Add("duplicate unit order: $orderKey") }
        $unitOrders[$orderKey] = $true
        if ([string]$unit.owner -notin $script:Owners) { $failures.Add("invalid owner for ${id}: $($unit.owner)") }
        if ([string]$unit.switch_kind -notin $script:SwitchKinds) { $failures.Add("invalid switch_kind for ${id}: $($unit.switch_kind)") }
        if ([string]$unit.status -notin $script:Statuses) { $failures.Add("invalid status for ${id}: $($unit.status)") }
        $renderedAsIsProperty = $unit.PSObject.Properties['rendered_as_is_paths']
        $renderedAsIsPathsRaw = if ($null -ne $renderedAsIsProperty) { @($renderedAsIsProperty.Value) } else { @() }
        $allowsRetiredPathsMissing = (
            [string]$unit.status -in @('approved_for_switch','applied','retired') -and
            $null -ne $unit.approval
        )
        $allowsAppliedRuntimePathMissing = (
            [string]$unit.status -in @('applied','retired') -and
            $null -ne $unit.application
        )

        $currentRecords = [Collections.Generic.List[object]]::new()
        $unitCurrentPaths = @{}
        foreach ($pathValue in @($unit.current_paths)) {
            if ($null -eq $pathValue -or [string]::IsNullOrWhiteSpace([string]$pathValue)) { continue }
            $path = ConvertTo-NormalizedVisualPath ([string]$pathValue)
            if ($unitCurrentPaths.ContainsKey($path)) { $failures.Add("duplicate current path in unit: $id -> $path") }
            $unitCurrentPaths[$path] = $true
            try { $absolute = Resolve-VisualRepositoryPath $RepoRoot $path } catch { $failures.Add($_.Exception.Message); continue }
            if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) {
                if (-not $allowsRetiredPathsMissing) { $failures.Add("missing current path: $id -> $path") }
                continue
            }
            if ([IO.Path]::GetExtension($path).ToLowerInvariant() -in @('.png','.ttf')) {
                if ($coveredMedia.ContainsKey($path)) { $failures.Add("production media assigned twice: $path") }
                $coveredMedia[$path] = $id
            }
            $dimensions = if ($path.EndsWith('.png')) { Get-VisualPngDimensions $absolute } else { @($null,$null) }
            $currentRecords.Add([ordered]@{path=$path;bytes=(Get-Item -LiteralPath $absolute).Length;width=$dimensions[0];height=$dimensions[1];sha256=(Get-VisualSha256 $absolute)})
        }
        foreach ($pathValue in @($unit.consumer_paths) + @($unit.runtime_change_paths) + @($unit.preview_paths) + $renderedAsIsPathsRaw + @($unit.retire_paths)) {
            if ($null -eq $pathValue -or [string]::IsNullOrWhiteSpace([string]$pathValue)) { continue }
            $path = ConvertTo-NormalizedVisualPath ([string]$pathValue)
            try { $absolute = Resolve-VisualRepositoryPath $RepoRoot $path } catch { $failures.Add($_.Exception.Message); continue }
            if (-not (Test-Path -LiteralPath $absolute)) {
                $isRetirePath = $path -in @($unit.retire_paths)
                $isAppliedRuntimePath = $path -in @($unit.runtime_change_paths)
                if (-not (
                    ($allowsRetiredPathsMissing -and $isRetirePath) -or
                    ($allowsAppliedRuntimePathMissing -and $isAppliedRuntimePath)
                )) { $failures.Add("missing declared path: $id -> $path") }
            }
            if ($path -in @($unit.preview_paths) -and -not $path.StartsWith("$script:WorkbenchRoot/previews/")) { $failures.Add("preview escapes preview root: $id -> $path") }
            if ($path -in $renderedAsIsPathsRaw -and -not $path.StartsWith("$script:WorkbenchRoot/previews/")) { $failures.Add("rendered AS-IS evidence escapes preview root: $id -> $path") }
        }

        $unitFinalPaths = [Collections.Generic.List[string]]::new()
        foreach ($pathValue in @($unit.final_paths)) {
            if ($null -eq $pathValue -or [string]::IsNullOrWhiteSpace([string]$pathValue)) { continue }
            $path = ConvertTo-NormalizedVisualPath ([string]$pathValue)
            try { Resolve-VisualRepositoryPath $RepoRoot $path | Out-Null } catch { $failures.Add($_.Exception.Message); continue }
            if (-not $path.StartsWith("$script:ProductionRoot/")) { $failures.Add("final path escapes production root: $id -> $path") }
            if ([IO.Path]::GetExtension($path).ToLowerInvariant() -notin @('.png','.ttf')) { $failures.Add("final path is not PNG or font: $id -> $path") }
            if ($finalPaths.ContainsKey($path)) { $failures.Add("final path assigned twice: $path") }
            $finalPaths[$path] = $id
            $unitFinalPaths.Add($path)
        }
        if (@($unitFinalPaths | Sort-Object -Unique).Count -ne $unitFinalPaths.Count) { $failures.Add("duplicate final path in unit: $id") }

        # Once a replacement unit is applied, its final production files become
        # the current files shown by the report. Historical current_paths remain
        # as the AS-IS record but may have been retired from disk.
        if ([string]$unit.status -ceq 'applied') {
            foreach ($path in $unitFinalPaths) {
                if ($unitCurrentPaths.ContainsKey($path)) { continue }
                $absolute = Resolve-VisualRepositoryPath $RepoRoot $path
                if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) {
                    $failures.Add("missing applied final path: $id -> $path")
                    continue
                }
                $unitCurrentPaths[$path] = $true
                if ([IO.Path]::GetExtension($path).ToLowerInvariant() -in @('.png','.ttf')) {
                    if ($coveredMedia.ContainsKey($path)) { $failures.Add("production media assigned twice: $path") }
                    $coveredMedia[$path] = $id
                }
                $dimensions = if ($path.EndsWith('.png')) { Get-VisualPngDimensions $absolute } else { @($null,$null) }
                $currentRecords.Add([ordered]@{
                    path=$path;bytes=(Get-Item -LiteralPath $absolute).Length;
                    width=$dimensions[0];height=$dimensions[1];sha256=(Get-VisualSha256 $absolute)
                })
            }
        }

        $unitReusePaths = [Collections.Generic.List[string]]::new()
        foreach ($pathValue in @($unit.reuse_paths)) {
            if ($null -eq $pathValue -or [string]::IsNullOrWhiteSpace([string]$pathValue)) { continue }
            $path = ConvertTo-NormalizedVisualPath ([string]$pathValue)
            if ($path -notin $unitFinalPaths) { $failures.Add("reuse path is not a final path: $id -> $path") }
            if (-not $unitCurrentPaths.ContainsKey($path)) { $failures.Add("reuse path is not a current path: $id -> $path") }
            try { $absoluteReuse = Resolve-VisualRepositoryPath $RepoRoot $path } catch { $failures.Add($_.Exception.Message); continue }
            if (-not (Test-Path -LiteralPath $absoluteReuse -PathType Leaf)) { $failures.Add("missing reuse path: $id -> $path") }
            if ($reusePaths.ContainsKey($path)) { $failures.Add("reuse path assigned twice: $path") }
            $reusePaths[$path] = $id
            $unitReusePaths.Add($path)
        }
        if (@($unitReusePaths | Sort-Object -Unique).Count -ne $unitReusePaths.Count) { $failures.Add("duplicate reuse path in unit: $id") }

        $deliverableRecords = [Collections.Generic.List[object]]::new()
        foreach ($deliverable in @($unit.deliverables)) {
            Test-VisualObjectFields $deliverable @(
                'target_path','width','height','pivot','patch_margin','safe_inset','frame_count',
                'fps','loop','blend','brief_en','external_source_ids'
            ) "deliverable $id" $failures
            $target = ConvertTo-NormalizedVisualPath ([string]$deliverable.target_path)
            if (-not $target.StartsWith("$script:ProductionRoot/")) { $failures.Add("target escapes production root: $id -> $target") }
            if ($targetPaths.ContainsKey($target)) { $failures.Add("duplicate target path: $target") }
            $targetPaths[$target] = $id
            if ($target -notin $unitFinalPaths) { $failures.Add("deliverable is not a final path: $id -> $target") }
            if ($target -in $unitReusePaths) { $failures.Add("deliverable is also marked for reuse: $id -> $target") }
            if ([int]$deliverable.width -le 0 -or [int]$deliverable.height -le 0) { $failures.Add("invalid dimensions: $id -> $target") }
            $brief = [string]$deliverable.brief_en
            if ([string]::IsNullOrWhiteSpace($brief)) { $failures.Add("missing final brief: $id -> $target") }
            $deliverableSourceIds = @($deliverable.external_source_ids | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_) })
            if (@($deliverableSourceIds | Sort-Object -Unique).Count -ne $deliverableSourceIds.Count) { $failures.Add("duplicate external source reference: $id -> $target") }
            foreach ($sourceIdValue in $deliverableSourceIds) {
                $sourceId = [string]$sourceIdValue
                if (-not $externalSourceIds.ContainsKey($sourceId)) { $failures.Add("unknown external source reference: $id -> $target -> $sourceId") }
                $referencedExternalSourceIds[$sourceId] = $true
            }
            $toBePath = "$script:WorkbenchRoot/to-be/assets/$target"
            $absoluteToBe = Resolve-VisualRepositoryPath $RepoRoot $toBePath
            $exists = Test-Path -LiteralPath $absoluteToBe -PathType Leaf
            if ($exists -and ([IO.Path]::GetFileNameWithoutExtension($target) -match '(sheet|montage|candidates)')) { $failures.Add("deliverable looks like review media: $target") }
            if ($exists) {
                $actualSize = Get-VisualPngDimensions $absoluteToBe
                if ($actualSize[0] -ne [int]$deliverable.width -or $actualSize[1] -ne [int]$deliverable.height) { $failures.Add("deliverable dimension mismatch: $target") }
            }
            $hash = if ($exists) { Get-VisualSha256 $absoluteToBe } else { $null }
            $optional = @{}
            foreach ($field in @('pivot','patch_margin','safe_inset','frame_count','fps','loop','blend')) {
                $property = $deliverable.PSObject.Properties[$field]
                $optional[$field] = if ($null -ne $property) { $property.Value } else { $null }
            }
            $observedBytes = if ($exists) { (Get-Item -LiteralPath $absoluteToBe).Length } else { $null }
            $deliverableRecords.Add([ordered]@{target_path=$target;workbench_path=$toBePath;width=[int]$deliverable.width;height=[int]$deliverable.height;pivot=$optional.pivot;patch_margin=$optional.patch_margin;safe_inset=$optional.safe_inset;frame_count=$optional.frame_count;fps=$optional.fps;loop=$optional.loop;blend=$optional.blend;brief_en=$brief;external_source_ids=$deliverableSourceIds;observed_sha256=$hash;bytes=$observedBytes})
        }
        $expectedDeliverableTargets = @($unitFinalPaths | Where-Object { $_ -notin $unitReusePaths } | Sort-Object)
        $actualDeliverableTargets = @($deliverableRecords | ForEach-Object { $_.target_path } | Sort-Object)
        if ((Get-VisualCanonicalJson $expectedDeliverableTargets) -cne (Get-VisualCanonicalJson $actualDeliverableTargets)) {
            $failures.Add("final paths do not equal deliverables plus reuse paths: $id")
        }

        $visualAuthorityEvidenceProperty = $unit.PSObject.Properties['visual_authority_evidence']
        $visualAuthorityEvidence = if ($null -ne $visualAuthorityEvidenceProperty) { $visualAuthorityEvidenceProperty.Value } else { $null }
        $projectedVisualAuthorityEvidence = $null
        if ($null -ne $visualAuthorityEvidence) {
            if ($visualAuthorityEvidence -isnot [pscustomobject]) {
                $failures.Add("visual_authority_evidence must be an object: $id")
            } else {
                $authorityEvidenceFields = @(
                    'spec_path','sheet_path','sheet_sha256','document_read_complete',
                    'sheet_inspected_original','actual_image_reference_used','reference_input_method'
                )
                Test-VisualObjectFields $visualAuthorityEvidence $authorityEvidenceFields "visual authority evidence $id" $failures
                foreach ($field in $authorityEvidenceFields) {
                    if ($null -eq $visualAuthorityEvidence.PSObject.Properties[$field]) {
                        $failures.Add("missing visual authority evidence field: $id -> $field")
                    }
                }

                $specPath = if ($null -ne $visualAuthorityEvidence.PSObject.Properties['spec_path']) { [string]$visualAuthorityEvidence.spec_path } else { '' }
                $sheetPath = if ($null -ne $visualAuthorityEvidence.PSObject.Properties['sheet_path']) { [string]$visualAuthorityEvidence.sheet_path } else { '' }
                $sheetSha256 = if ($null -ne $visualAuthorityEvidence.PSObject.Properties['sheet_sha256']) { [string]$visualAuthorityEvidence.sheet_sha256 } else { '' }
                if ($specPath -cne $script:StyleAuthorityPath) { $failures.Add("visual authority evidence has wrong spec path: $id") }
                if ($sheetPath -cne $script:StyleReferenceSheetPath) { $failures.Add("visual authority evidence has wrong sheet path: $id") }
                if ($sheetSha256 -cne $script:StyleReferenceSheetSha256) { $failures.Add("visual authority evidence has wrong sheet hash: $id") }

                foreach ($field in @('document_read_complete','sheet_inspected_original','actual_image_reference_used')) {
                    $property = $visualAuthorityEvidence.PSObject.Properties[$field]
                    if ($null -ne $property -and $property.Value -isnot [bool]) {
                        $failures.Add("visual authority evidence field must be boolean: $id -> $field")
                    }
                }
                $documentReadComplete = if ($null -ne $visualAuthorityEvidence.PSObject.Properties['document_read_complete']) { $visualAuthorityEvidence.document_read_complete } else { $null }
                $sheetInspectedOriginal = if ($null -ne $visualAuthorityEvidence.PSObject.Properties['sheet_inspected_original']) { $visualAuthorityEvidence.sheet_inspected_original } else { $null }
                $actualImageReferenceUsed = if ($null -ne $visualAuthorityEvidence.PSObject.Properties['actual_image_reference_used']) { $visualAuthorityEvidence.actual_image_reference_used } else { $null }
                if ($documentReadComplete -isnot [bool] -or -not [bool]$documentReadComplete) {
                    $failures.Add("visual authority document was not read completely: $id")
                }
                if ($sheetInspectedOriginal -isnot [bool] -or -not [bool]$sheetInspectedOriginal) {
                    $failures.Add("visual authority sheet was not inspected at original detail: $id")
                }

                $hasRasterDeliverable = @($deliverableRecords | Where-Object { [string]$_.target_path -like '*.png' }).Count -gt 0
                $referenceInputMethod = if ($null -ne $visualAuthorityEvidence.PSObject.Properties['reference_input_method']) { [string]$visualAuthorityEvidence.reference_input_method } else { '' }
                if ($hasRasterDeliverable) {
                    if ($actualImageReferenceUsed -isnot [bool] -or -not [bool]$actualImageReferenceUsed) {
                        $failures.Add("raster unit lacks actual sheet-reference evidence: $id")
                    }
                    if ([string]::IsNullOrWhiteSpace($referenceInputMethod) -or $referenceInputMethod -ceq 'not_applicable') {
                        $failures.Add("raster unit lacks reference input method: $id")
                    }
                } else {
                    if ($actualImageReferenceUsed -isnot [bool] -or [bool]$actualImageReferenceUsed) {
                        $failures.Add("non-raster unit must mark actual image reference as not used: $id")
                    }
                    if ($referenceInputMethod -cne 'not_applicable') {
                        $failures.Add("non-raster unit must use not_applicable reference input method: $id")
                    }
                }

                $projectedVisualAuthorityEvidence = [ordered]@{
                    spec_path=$script:StyleAuthorityPath;sheet_path=$script:StyleReferenceSheetPath;
                    sheet_sha256=$script:StyleReferenceSheetSha256;
                    document_read_complete=[bool]$documentReadComplete;
                    sheet_inspected_original=[bool]$sheetInspectedOriginal;
                    actual_image_reference_used=[bool]$actualImageReferenceUsed;
                    reference_input_method=$referenceInputMethod
                }
            }
        }
        if ([string]$unit.status -in @('switch_ready','approved_for_switch','applied') -and $null -eq $projectedVisualAuthorityEvidence) {
            $failures.Add("ready unit lacks visual authority evidence: $id")
        }
        if ([string]$unit.status -in @('switch_ready','approved_for_switch','applied') -and @($deliverableRecords | Where-Object { $null -eq $_.observed_sha256 }).Count -gt 0) { $failures.Add("ready unit has missing deliverable: $id") }
        if ($null -ne $unit.approval) {
            Test-VisualObjectFields $unit.approval @('approved_by','approved_at','baseline_commit','deliverable_sha256','retire_paths') "approval $id" $failures
            if ([string]$unit.approval.approved_by -notin $script:TechnicalRecordOwners) { $failures.Add("invalid technical record owner: $id") }
            $approvalTime = if ($unit.approval.approved_at -is [datetime]) { $unit.approval.approved_at.ToString('yyyy-MM-ddTHH:mm:sszzz') } else { [string]$unit.approval.approved_at }
            if ($approvalTime -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?\+09:00$') { $failures.Add("invalid approval time: $id") }
            if ([string]$unit.approval.baseline_commit -notmatch '^[0-9a-f]{40}$') { $failures.Add("invalid approval baseline commit: $id") }
            $recordedTargets = @($unit.approval.deliverable_sha256.PSObject.Properties | ForEach-Object { [string]$_.Name } | Sort-Object)
            $observedTargets = @($deliverableRecords | ForEach-Object { [string]$_.target_path } | Sort-Object)
            if ((Get-VisualCanonicalJson $recordedTargets) -cne (Get-VisualCanonicalJson $observedTargets)) {
                $failures.Add("technical record target paths mismatch: $id")
            }
            foreach ($record in $deliverableRecords) {
                $approved = $unit.approval.deliverable_sha256.PSObject.Properties[$record.target_path]
                if ($null -eq $approved -or [string]$approved.Value -cne [string]$record.observed_sha256) { $failures.Add("technical record hash mismatch: $id -> $($record.target_path)") }
            }
            if ((Get-VisualCanonicalJson @($unit.approval.retire_paths)) -cne (Get-VisualCanonicalJson @($unit.retire_paths))) { $failures.Add("technical record retire_paths mismatch: $id") }
        }
        if ($null -ne $unit.application) {
            Test-VisualObjectFields $unit.application @('commit','applied_at','validation_evidence') "application $id" $failures
            if ([string]$unit.application.commit -notmatch '^[0-9a-f]{40}$') { $failures.Add("invalid application commit: $id") }
            $applicationTime = if ($unit.application.applied_at -is [datetime]) { $unit.application.applied_at.ToString('yyyy-MM-ddTHH:mm:sszzz') } else { [string]$unit.application.applied_at }
            if ($applicationTime -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?\+09:00$') { $failures.Add("invalid application time: $id") }
        }
        $consumerPaths = @($unit.consumer_paths | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_) })
        $consumerIds = @($unit.consumer_asset_ids | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_) })
        $previewPaths = @($unit.preview_paths | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_) })
        $renderedAsIsPaths = @($renderedAsIsPathsRaw | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_) })
        $renderedAsIsRecords = @($renderedAsIsPaths | ForEach-Object {
            $path = ConvertTo-NormalizedVisualPath ([string]$_)
            $absolute = Resolve-VisualRepositoryPath $RepoRoot $path
            $dimensions = Get-VisualPngDimensions $absolute
            [ordered]@{path=$path;bytes=(Get-Item -LiteralPath $absolute).Length;width=$dimensions[0];height=$dimensions[1];sha256=(Get-VisualSha256 $absolute)}
        })
        $retirePaths = @($unit.retire_paths | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_) })
        $runtimePaths = @($unit.runtime_change_paths | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_) })
        $commands = @($unit.acceptance_commands | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_) })
        foreach ($retirePathValue in $retirePaths) {
            $retirePath = ConvertTo-NormalizedVisualPath ([string]$retirePathValue)
            if ($retirePathOwners.ContainsKey($retirePath)) { $failures.Add("retire path assigned twice: $retirePath") }
            $retirePathOwners[$retirePath] = $id
            if ($retirePath -in $unitFinalPaths) { $failures.Add("path is both final and retired: $id -> $retirePath") }
        }
        if ([string]$unit.switch_kind -ceq 'retire') {
            $status = [string]$unit.status
            if ($status -notin @('target_required','switch_ready','approved_for_switch','retired')) {
                $failures.Add("retire-only unit has invalid status: $id -> $status")
            }
            if ($deliverableRecords.Count -ne 0) { $failures.Add("retire-only unit has deliverables: $id") }
            if ($retirePaths.Count -eq 0) { $failures.Add("retire-only unit has no retire paths: $id") }
            if ($null -ne $unit.approval -and @($unit.approval.deliverable_sha256.PSObject.Properties).Count -ne 0) {
                $failures.Add("retire-only approval hash map is not empty: $id")
            }
            if (@($retirePaths | Sort-Object -Unique).Count -ne $retirePaths.Count) { $failures.Add("retire-only paths are not unique: $id") }
            if ((Get-VisualCanonicalJson @($retirePaths)) -cne (Get-VisualCanonicalJson @($retirePaths | Sort-Object))) {
                $failures.Add("retire-only paths are not sorted: $id")
            }
            foreach ($retirePath in $retirePaths) {
                if ([string]$retirePath -match '[*?\[]') { $failures.Add("retire-only path contains a wildcard: $id -> $retirePath") }
            }
            foreach ($currentPath in @($unit.current_paths)) {
                $normalizedCurrent = ConvertTo-NormalizedVisualPath ([string]$currentPath)
                if ($normalizedCurrent -notin $retirePaths) { $failures.Add("retire-only current path is not retired: $id -> $normalizedCurrent") }
            }
            if ($status -in @('target_required','switch_ready')) {
                if ($null -ne $unit.approval -or $null -ne $unit.application) { $failures.Add("switch-ready retirement contains workflow ledger data: $id") }
                foreach ($retirePath in $retirePaths) {
                    $absoluteRetirePath = Resolve-VisualRepositoryPath $RepoRoot ([string]$retirePath)
                    if (-not (Test-Path -LiteralPath $absoluteRetirePath -PathType Leaf)) { $failures.Add("switch-ready retirement path is missing: $id -> $retirePath") }
                }
            } elseif ($status -eq 'approved_for_switch') {
                if ($null -eq $unit.approval -or $null -ne $unit.application) { $failures.Add("approved retirement has an invalid workflow ledger: $id") }
            } elseif ($status -eq 'retired') {
                if ($null -eq $unit.approval -or $null -eq $unit.application) { $failures.Add("retired unit has an incomplete workflow ledger: $id") }
                foreach ($retirePath in $retirePaths) {
                    $absoluteRetirePath = Resolve-VisualRepositoryPath $RepoRoot ([string]$retirePath)
                    if (Test-Path -LiteralPath $absoluteRetirePath) { $failures.Add("retired path still exists: $id -> $retirePath") }
                }
            }
        }
        $projectedUnits.Add([ordered]@{
            id=$id;category_id=[string]$unit.category_id;order=[int]$unit.order;title_en=[string]$unit.title_en;title_ko=[string]$unit.title_ko;
            owner=[string]$unit.owner;switch_kind=[string]$unit.switch_kind;status=[string]$unit.status;direction_en=[string]$unit.direction_en;
            current_files=@($currentRecords);rendered_as_is_files=$renderedAsIsRecords;consumer_paths=$consumerPaths;consumer_asset_ids=$consumerIds;
            deliverables=@($deliverableRecords);final_paths=@($unitFinalPaths);reuse_paths=@($unitReusePaths);
            preview_paths=$previewPaths;retire_paths=$retirePaths;runtime_change_paths=$runtimePaths;
            acceptance_commands=$commands;visual_authority_evidence=$projectedVisualAuthorityEvidence;
            approval=$unit.approval;application=$unit.application
        })
    }
    foreach ($sourceId in $externalSourceIds.Keys) {
        if (-not $referencedExternalSourceIds.ContainsKey($sourceId)) { $failures.Add("unreferenced external source record: $sourceId") }
    }
    $productionMedia = Get-VisualProductionMediaPaths $RepoRoot
    foreach ($path in $productionMedia) { if (-not $coveredMedia.ContainsKey($path)) { $failures.Add("unassigned production media: $path") } }
    foreach ($path in $coveredMedia.Keys) { if ($path -notin $productionMedia) { $failures.Add("assigned non-production media: $path") } }
    $currentGameplayPng = @($productionMedia | Where-Object { $_.StartsWith("$script:ProductionRoot/gameplay/") -and $_.EndsWith('.png') })
    foreach ($path in $currentGameplayPng) {
        $isFinal = $finalPaths.ContainsKey($path)
        $isRetired = $retirePathOwners.ContainsKey($path)
        if ($isFinal -eq $isRetired) { $failures.Add("current gameplay PNG needs exactly one final disposition: $path") }
        if ($isFinal -and [string]$finalPaths[$path] -cne [string]$coveredMedia[$path]) { $failures.Add("current/final unit mismatch: $path") }
        if ($isRetired -and [string]$retirePathOwners[$path] -cne [string]$coveredMedia[$path]) { $failures.Add("current/retirement unit mismatch: $path") }
    }
    if ($failures.Count -gt 0) { throw ($failures -join "`n") }

    $orderedCategories = @($Source.categories | Sort-Object order)
    $orderedUnits = @($projectedUnits | Sort-Object @{Expression={($orderedCategories | Where-Object id -eq $_.category_id).order}}, order, id)
    $statusCounts = [ordered]@{}
    foreach ($status in $script:Statuses) { $statusCounts[$status] = @($orderedUnits | Where-Object status -eq $status).Count }
    return [ordered]@{
        schema_version=2;production_root=$script:ProductionRoot;style_authority=$script:StyleAuthorityPath;
        style_reference_sheet=[ordered]@{
            path=$script:StyleReferenceSheetPath;sha256=$script:StyleReferenceSheetSha256;
            width=$script:StyleReferenceSheetWidth;height=$script:StyleReferenceSheetHeight
        };
        summary=[ordered]@{
            gameplay_png=$currentGameplayPng.Count;
            final_gameplay_png=@($finalPaths.Keys | Where-Object { $_.StartsWith("$script:ProductionRoot/gameplay/") -and $_.EndsWith('.png') }).Count;
            authored_gameplay_png=@($targetPaths.Keys | Where-Object { $_.StartsWith("$script:ProductionRoot/gameplay/") -and $_.EndsWith('.png') }).Count;
            reused_gameplay_png=@($reusePaths.Keys | Where-Object { $_.StartsWith("$script:ProductionRoot/gameplay/") -and $_.EndsWith('.png') }).Count;
            retired_gameplay_png=@($currentGameplayPng | Where-Object { $retirePathOwners.ContainsKey($_) }).Count;
            ui_png=@($productionMedia | Where-Object {$_.StartsWith("$script:ProductionRoot/ui/") -and $_.EndsWith('.png')}).Count;
            font=@($productionMedia | Where-Object {$_.EndsWith('.ttf')}).Count;
            units=$orderedUnits.Count;retire_only=@($orderedUnits | Where-Object switch_kind -eq 'retire').Count;
            external_sources=$projectedExternalSources.Count;statuses=$statusCounts
        };
        external_sources=@($projectedExternalSources | Sort-Object id);categories=$orderedCategories;units=$orderedUnits
    }
}

Export-ModuleMember -Function @(
    'ConvertTo-NormalizedVisualPath','Resolve-VisualRepositoryPath','Get-VisualPngDimensions',
    'Get-VisualSha256','Get-VisualProductionMediaPaths','Get-VisualCanonicalJson',
    'Write-VisualUtf8Lf','Get-VisualReplacementProjection'
)
