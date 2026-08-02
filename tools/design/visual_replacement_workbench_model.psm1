Set-StrictMode -Version Latest

$script:ProductionRoot = 'art/visuals/production'
$script:WorkbenchRoot = 'docs/design/visual-replacement-workbench'
$script:Statuses = @(
    'keep_current', 'target_required', 'switch_ready',
    'approved_for_switch', 'applied', 'retired'
)
$script:Owners = @(
    'gameplay_manifest', 'ui_manifest', 'ui_theme',
    'procedural_presentation', 'composite'
)
$script:SwitchKinds = @('replace', 'add', 'consolidate', 'retire')

function ConvertTo-NormalizedVisualPath {
    param([Parameter(Mandatory)][string]$Path)
    return $Path.Replace('\', '/').TrimStart('./')
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
        $width = [uint32]($header[16] -shl 24) -bor [uint32]($header[17] -shl 16) -bor
            [uint32]($header[18] -shl 8) -bor [uint32]$header[19]
        $height = [uint32]($header[20] -shl 24) -bor [uint32]($header[21] -shl 16) -bor
            [uint32]($header[22] -shl 8) -bor [uint32]$header[23]
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
    Test-VisualObjectFields $Source @('schema_version','production_root','style_authority','categories','units') 'source' $failures
    if ($Source.schema_version -ne 1) { $failures.Add('schema_version must be 1') }
    if ($Source.production_root -cne $script:ProductionRoot) { $failures.Add('production_root is not canonical') }
    if ($Source.style_authority -cne 'docs/design/VISUAL_SYSTEM.md') { $failures.Add('style_authority is not canonical') }

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
    $coveredMedia = @{}
    $projectedUnits = [Collections.Generic.List[object]]::new()
    foreach ($unit in @($Source.units)) {
        $id = [string]$unit.id
        Test-VisualObjectFields $unit @(
            'id','category_id','order','title_en','title_ko','owner','switch_kind','status',
            'current_paths','consumer_paths','consumer_asset_ids','direction_en','deliverables',
            'preview_paths','retire_paths','runtime_change_paths','acceptance_commands','approval','application'
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

        $currentRecords = [Collections.Generic.List[object]]::new()
        foreach ($pathValue in @($unit.current_paths)) {
            if ($null -eq $pathValue -or [string]::IsNullOrWhiteSpace([string]$pathValue)) { continue }
            $path = ConvertTo-NormalizedVisualPath ([string]$pathValue)
            try { $absolute = Resolve-VisualRepositoryPath $RepoRoot $path } catch { $failures.Add($_.Exception.Message); continue }
            if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) { $failures.Add("missing current path: $id -> $path"); continue }
            if ([IO.Path]::GetExtension($path).ToLowerInvariant() -in @('.png','.ttf')) {
                if ($coveredMedia.ContainsKey($path)) { $failures.Add("production media assigned twice: $path") }
                $coveredMedia[$path] = $id
            }
            $dimensions = if ($path.EndsWith('.png')) { Get-VisualPngDimensions $absolute } else { @($null,$null) }
            $currentRecords.Add([ordered]@{path=$path;bytes=(Get-Item -LiteralPath $absolute).Length;width=$dimensions[0];height=$dimensions[1];sha256=(Get-VisualSha256 $absolute)})
        }
        foreach ($pathValue in @($unit.consumer_paths) + @($unit.runtime_change_paths) + @($unit.preview_paths) + @($unit.retire_paths)) {
            if ($null -eq $pathValue -or [string]::IsNullOrWhiteSpace([string]$pathValue)) { continue }
            $path = ConvertTo-NormalizedVisualPath ([string]$pathValue)
            try { $absolute = Resolve-VisualRepositoryPath $RepoRoot $path } catch { $failures.Add($_.Exception.Message); continue }
            if (-not (Test-Path -LiteralPath $absolute)) { $failures.Add("missing declared path: $id -> $path") }
            if ($path -in @($unit.preview_paths) -and -not $path.StartsWith("$script:WorkbenchRoot/previews/")) { $failures.Add("preview escapes preview root: $id -> $path") }
        }

        $deliverableRecords = [Collections.Generic.List[object]]::new()
        foreach ($deliverable in @($unit.deliverables)) {
            Test-VisualObjectFields $deliverable @('target_path','width','height','pivot','patch_margin','safe_inset','frame_count','fps','loop','blend') "deliverable $id" $failures
            $target = ConvertTo-NormalizedVisualPath ([string]$deliverable.target_path)
            if (-not $target.StartsWith("$script:ProductionRoot/")) { $failures.Add("target escapes production root: $id -> $target") }
            if ($targetPaths.ContainsKey($target)) { $failures.Add("duplicate target path: $target") }
            $targetPaths[$target] = $id
            if ([int]$deliverable.width -le 0 -or [int]$deliverable.height -le 0) { $failures.Add("invalid dimensions: $id -> $target") }
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
            $deliverableRecords.Add([ordered]@{target_path=$target;workbench_path=$toBePath;width=[int]$deliverable.width;height=[int]$deliverable.height;pivot=$optional.pivot;patch_margin=$optional.patch_margin;safe_inset=$optional.safe_inset;frame_count=$optional.frame_count;fps=$optional.fps;loop=$optional.loop;blend=$optional.blend;observed_sha256=$hash;bytes=$observedBytes})
        }
        if ([string]$unit.status -in @('switch_ready','approved_for_switch','applied') -and @($deliverableRecords | Where-Object { $null -eq $_.observed_sha256 }).Count -gt 0) { $failures.Add("ready unit has missing deliverable: $id") }
        if ($null -ne $unit.approval) {
            foreach ($record in $deliverableRecords) {
                $approved = $unit.approval.deliverable_sha256.PSObject.Properties[$record.target_path]
                if ($null -eq $approved -or [string]$approved.Value -cne [string]$record.observed_sha256) { $failures.Add("approval hash mismatch: $id -> $($record.target_path)") }
            }
            if ((Get-VisualCanonicalJson @($unit.approval.retire_paths)) -cne (Get-VisualCanonicalJson @($unit.retire_paths))) { $failures.Add("approval retire_paths mismatch: $id") }
        }
        $consumerPaths = @($unit.consumer_paths | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_) })
        $consumerIds = @($unit.consumer_asset_ids | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_) })
        $previewPaths = @($unit.preview_paths | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_) })
        $retirePaths = @($unit.retire_paths | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_) })
        $runtimePaths = @($unit.runtime_change_paths | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_) })
        $commands = @($unit.acceptance_commands | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_) })
        $projectedUnits.Add([ordered]@{
            id=$id;category_id=[string]$unit.category_id;order=[int]$unit.order;title_en=[string]$unit.title_en;title_ko=[string]$unit.title_ko;
            owner=[string]$unit.owner;switch_kind=[string]$unit.switch_kind;status=[string]$unit.status;direction_en=[string]$unit.direction_en;
            current_files=@($currentRecords);consumer_paths=$consumerPaths;consumer_asset_ids=$consumerIds;
            deliverables=@($deliverableRecords);preview_paths=$previewPaths;retire_paths=$retirePaths;runtime_change_paths=$runtimePaths;
            acceptance_commands=$commands;approval=$unit.approval;application=$unit.application
        })
    }
    $productionMedia = Get-VisualProductionMediaPaths $RepoRoot
    foreach ($path in $productionMedia) { if (-not $coveredMedia.ContainsKey($path)) { $failures.Add("unassigned production media: $path") } }
    foreach ($path in $coveredMedia.Keys) { if ($path -notin $productionMedia) { $failures.Add("assigned non-production media: $path") } }
    if ($failures.Count -gt 0) { throw ($failures -join "`n") }

    $orderedCategories = @($Source.categories | Sort-Object order)
    $orderedUnits = @($projectedUnits | Sort-Object @{Expression={($orderedCategories | Where-Object id -eq $_.category_id).order}}, order, id)
    $statusCounts = [ordered]@{}
    foreach ($status in $script:Statuses) { $statusCounts[$status] = @($orderedUnits | Where-Object status -eq $status).Count }
    return [ordered]@{
        schema_version=1;production_root=$script:ProductionRoot;style_authority='docs/design/VISUAL_SYSTEM.md';
        summary=[ordered]@{gameplay_png=@($productionMedia | Where-Object {$_ -like 'art/visuals/production/gameplay/*.png' -or $_ -like 'art/visuals/production/gameplay/**/*.png'}).Count;ui_png=@($productionMedia | Where-Object {$_ -like 'art/visuals/production/ui/*.png' -or $_ -like 'art/visuals/production/ui/**/*.png'}).Count;font=@($productionMedia | Where-Object {$_.EndsWith('.ttf')}).Count;units=$orderedUnits.Count;retire_only=@($orderedUnits | Where-Object switch_kind -eq 'retire').Count;statuses=$statusCounts};
        categories=$orderedCategories;units=$orderedUnits
    }
}

Export-ModuleMember -Function @(
    'ConvertTo-NormalizedVisualPath','Resolve-VisualRepositoryPath','Get-VisualPngDimensions',
    'Get-VisualSha256','Get-VisualProductionMediaPaths','Get-VisualCanonicalJson',
    'Write-VisualUtf8Lf','Get-VisualReplacementProjection'
)
