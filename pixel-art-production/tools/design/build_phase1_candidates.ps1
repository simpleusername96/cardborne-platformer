param()

$ErrorActionPreference = "Stop"

$workspaceRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $workspaceRoot ".."))
$sourceRoot = Join-Path $workspaceRoot "assets/source/candidates/phase-1"
$generatedRoot = Join-Path $workspaceRoot "assets/generated/candidates/phase-1"
$briefRoot = Join-Path $workspaceRoot "assets/briefs/candidates/phase-1"
$manifestRoot = Join-Path $workspaceRoot "assets/manifests/candidates/phase-1"
$evidenceRoot = Join-Path $workspaceRoot "evidence/gates/01-post-sampler-capability"
$nativeRoot = Join-Path $generatedRoot "native"
$buildRoot = Join-Path $generatedRoot "build"
$canonicalRoot = Join-Path $generatedRoot "canonical"
$reviewRoot = Join-Path $evidenceRoot "reviews"
$magick = Get-Command magick -ErrorAction Stop
$inventoryPath = Join-Path $workspaceRoot "assets/asset-inventory.json"
$inventory = Get-Content -LiteralPath $inventoryPath -Raw | ConvertFrom-Json
$frameSources = @{}
$frameMasks = @{}
$assetConfigs = [System.Collections.Generic.List[object]]::new()

function Ensure-Directory {
    param([string]$Path)

    if (-not [System.IO.Directory]::Exists($Path)) {
        [System.IO.Directory]::CreateDirectory($Path) | Out-Null
    }
}

function Remove-GeneratedDirectory {
    param([string]$Path)

    $resolved = [System.IO.Path]::GetFullPath($Path)
    $workspacePrefix = $workspaceRoot.TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    ) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($workspacePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove a directory outside pixel-art-production: $resolved"
    }
    if ([System.IO.Directory]::Exists($resolved)) {
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}

function Invoke-Magick {
    param([string[]]$Arguments)

    & $magick.Source @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "ImageMagick failed: $($Arguments -join ' ')"
    }
}

function Write-Json {
    param(
        [object]$Value,
        [string]$Path,
        [int]$Depth = 16
    )

    Ensure-Directory -Path ([System.IO.Path]::GetDirectoryName($Path))
    [System.IO.File]::WriteAllText(
        $Path,
        ($Value | ConvertTo-Json -Depth $Depth),
        [System.Text.UTF8Encoding]::new($false)
    )
}

function Get-RepoRelativePath {
    param([string]$Path)

    return [System.IO.Path]::GetRelativePath(
        $repoRoot,
        [System.IO.Path]::GetFullPath($Path)
    ).Replace("\", "/")
}

function Get-InventoryAsset {
    param([string]$Family)

    $asset = @($inventory.assets | Where-Object { [string]$_.id -eq $Family })
    if ($asset.Count -ne 1) {
        throw "Inventory family must exist exactly once: $Family"
    }
    return $asset[0]
}

function Convert-Point {
    param(
        [object[]]$Point,
        [int]$Size,
        [ValidateSet(0, 90, 180, 270)]
        [int]$ClockwiseDegrees
    )

    $x = [int]$Point[0]
    $y = [int]$Point[1]
    switch ($ClockwiseDegrees) {
        0 { return @($x, $y) }
        90 { return @(($Size - 1 - $y), $x) }
        180 { return @(($Size - 1 - $x), ($Size - 1 - $y)) }
        270 { return @($y, ($Size - 1 - $x)) }
    }
}

function Convert-Anchors {
    param(
        [hashtable]$Anchors,
        [int]$Size,
        [int]$ClockwiseDegrees
    )

    $result = [ordered]@{}
    foreach ($entry in $Anchors.GetEnumerator() | Sort-Object Name) {
        $result[$entry.Name] = Convert-Point `
            -Point @($entry.Value) `
            -Size $Size `
            -ClockwiseDegrees $ClockwiseDegrees
    }
    return $result
}

function Copy-RotatedImage {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [int]$ClockwiseDegrees
    )

    Ensure-Directory -Path ([System.IO.Path]::GetDirectoryName($OutputPath))
    Invoke-Magick -Arguments @(
        $InputPath,
        "-background", "none",
        "-filter", "point",
        "-rotate", [string]$ClockwiseDegrees,
        "-background", "black",
        "-alpha", "background",
        "-depth", "8",
        "-strip",
        $OutputPath
    )
}

function Normalize-ImageGenSource {
    param(
        [string]$RawName,
        [string]$OutputName,
        [int]$Cells,
        [hashtable]$Replacements
    )

    $rawPath = Join-Path $sourceRoot $RawName
    $outputPath = Join-Path $canonicalRoot $OutputName
    $temporary = "$outputPath.tmp.png"
    if (-not [System.IO.File]::Exists($rawPath)) {
        throw "Missing ImageGen source: $rawPath"
    }
    Ensure-Directory -Path $canonicalRoot
    & (Join-Path $PSScriptRoot "snap_image_to_pixel_grid.ps1") `
        -InputPath (Get-RepoRelativePath -Path $rawPath) `
        -PalettePath "pixel-art-production/assets/palettes/pixel-hangar-v1.png" `
        -OutputPath (Get-RepoRelativePath -Path $outputPath) `
        -CanvasSize 512 `
        -Cells $Cells `
        -TransparentColor "#FFFFFF" | Out-Null
    $arguments = @($outputPath)
    foreach ($entry in $Replacements.GetEnumerator() | Sort-Object Name) {
        $arguments += @("-fill", [string]$entry.Value, "-opaque", [string]$entry.Name)
    }
    $arguments += @("-depth", "8", "-strip", $temporary)
    Invoke-Magick -Arguments $arguments
    Move-Item -LiteralPath $temporary -Destination $outputPath -Force
    return $outputPath
}

function New-SemanticMask {
    param(
        [string]$SourcePath,
        [string]$OutputPath,
        [int]$Size,
        [scriptblock]$ResolveSemanticColor
    )

    $groups = @{}
    foreach ($line in & $magick.Source $SourcePath -depth 8 "txt:-") {
        if ($line -notmatch "^(?<x>\d+),(?<y>\d+):.*#(?<rgba>[0-9A-Fa-f]{6}(?:[0-9A-Fa-f]{2})?)") {
            continue
        }
        $rgba = $Matches.rgba.ToUpperInvariant()
        $alpha = if ($rgba.Length -eq 8) { $rgba.Substring(6, 2) } else { "FF" }
        if ($alpha -eq "00") {
            continue
        }
        $x = [int]$Matches.x
        $y = [int]$Matches.y
        $displayColor = "#$($rgba.Substring(0, 6))"
        $semanticColor = [string](& $ResolveSemanticColor $x $y $displayColor)
        if ($semanticColor -notmatch "^#[0-9A-Fa-f]{6}$") {
            throw "No semantic color for $SourcePath at $x,$y ($displayColor)"
        }
        $semanticColor = $semanticColor.ToUpperInvariant()
        if (-not $groups.ContainsKey($semanticColor)) {
            $groups[$semanticColor] = [System.Collections.Generic.List[string]]::new()
        }
        $groups[$semanticColor].Add("point $x,$y")
    }
    if ($groups.Count -eq 0) {
        throw "Semantic mask source has no visible pixels: $SourcePath"
    }

    $arguments = @("-size", "${Size}x${Size}", "xc:none")
    foreach ($entry in $groups.GetEnumerator() | Sort-Object Name) {
        $arguments += @(
            "-fill", [string]$entry.Name,
            "-draw", ($entry.Value -join " ")
        )
    }
    $arguments += @("-depth", "8", "-strip", $OutputPath)
    Ensure-Directory -Path ([System.IO.Path]::GetDirectoryName($OutputPath))
    Invoke-Magick -Arguments $arguments
}

function New-AssetConfig {
    param(
        [string]$Id,
        [string]$Family,
        [int]$Size,
        [string]$Method,
        [string]$RuntimeGroup,
        [object[]]$Layers,
        [hashtable]$DefaultAnchors,
        [int]$Columns,
        [string[]]$AllowedPaletteRoles,
        [string]$GameplayIdentity,
        [string]$SilhouetteRequirement,
        [string]$OrientationCue,
        [string]$TileSignature = ""
    )

    $config = [ordered]@{
        id = $Id
        family = $Family
        size = $Size
        method = $Method
        runtime_group = $RuntimeGroup
        layers = @($Layers)
        default_pivot = @([int]($Size / 2), [int]($Size / 2))
        default_anchors = $DefaultAnchors
        columns = $Columns
        allowed_palette_roles = @($AllowedPaletteRoles)
        gameplay_identity = $GameplayIdentity
        silhouette_requirement = $SilhouetteRequirement
        orientation_cue = $OrientationCue
        tile_signature = $TileSignature
        frames = [System.Collections.Generic.List[object]]::new()
    }
    $assetConfigs.Add($config)
    return $config
}

function Add-CandidateFrame {
    param(
        [object]$Config,
        [string]$FrameId,
        [string]$SourcePath,
        [string]$MaskPath,
        [string]$Variant,
        [int]$DirectionIndex,
        [string]$State,
        [int]$SequenceIndex,
        [int]$DurationMs,
        [object[]]$Pivot,
        [object]$Anchors,
        [object]$TileEdges = $null
    )

    $frame = [ordered]@{
        id = $FrameId
        source_path = Get-RepoRelativePath -Path $SourcePath
        semantic_mask_path = Get-RepoRelativePath -Path $MaskPath
        source_sha256 = (Get-FileHash -LiteralPath $SourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
        atlas_index = $Config.frames.Count
        variant = $Variant
        direction_index = $DirectionIndex
        state = $State
        sequence_index = $SequenceIndex
        duration_ms = $DurationMs
        pivot = @($Pivot)
        anchors = $Anchors
    }
    if ($null -ne $TileEdges) {
        $frame["tile_edges"] = $TileEdges
    }
    $Config.frames.Add($frame)
    $frameSources["$($Config.id)/$FrameId"] = $SourcePath
    $frameMasks["$($Config.id)/$FrameId"] = $MaskPath
}

function Write-And-BuildAsset {
    param([object]$Config)

    $inventoryAsset = Get-InventoryAsset -Family ([string]$Config.family)
    $briefPath = Join-Path $briefRoot "$($Config.id).brief.json"
    $manifestPath = Join-Path $manifestRoot "$($Config.id).manifest.json"
    $states = @($Config.frames | ForEach-Object { [string]$_.state } | Sort-Object -Unique)
    $directions = @($Config.frames | ForEach-Object { [int]$_.direction_index } | Sort-Object -Unique)
    $directionCount = if ([int]$inventoryAsset.directions -eq 0) {
        0
    } else {
        [Math]::Max(1, $directions.Count)
    }
    $references = @(
        [ordered]@{
            id = "game_assault_android_cactus"
            study = "Read owner, role, and orientation at dense top-down combat scale."
        },
        [ordered]@{
            id = if ([string]$Config.family -in @("world_floor_void_tiles", "wall_cover_tiles")) {
                "cc0_eris_scifi_platform_tiles"
            } else {
                "cc0_kenney_pixel_shmup"
            }
            study = "Study economical whole-cell silhouettes and modular construction."
        }
    )
    $brief = [ordered]@{
        schema_version = 1
        id = [string]$Config.id
        family = [string]$Config.family
        approval_status = "candidate"
        gameplay_identity = [string]$Config.gameplay_identity
        current_owner = @($inventoryAsset.current_owner)
        native_size = @([int]$Config.size, [int]$Config.size)
        rendered_diameter = [int]$Config.size
        silhouette_requirement = [string]$Config.silhouette_requirement
        orientation_cue = [string]$Config.orientation_cue
        semantic_parts = @($Config.layers | ForEach-Object { [string]$_.id })
        pivot = @($Config.default_pivot)
        anchors = $Config.default_anchors
        directions = $directionCount
        states = $states
        allowed_palette_roles = @($Config.allowed_palette_roles)
        references = $references
        avoid_rules = @(
            "No gradient, antialiasing, texture noise, lighting simulation, or baked glow.",
            "Do not derive gameplay collision, timing, or range from candidate pixels."
        )
        production_method = [string]$Config.method
        collision_reference = "Candidate presentation follows existing gameplay-owned geometry for $($Config.family)."
        runtime_group = [string]$Config.runtime_group
        review_backgrounds = @("space_void", "deck_base", "neutral_highlight")
        density_tier = "all"
    }
    Write-Json -Value $brief -Path $briefPath

    $manifest = [ordered]@{
        schema_version = 2
        id = [string]$Config.id
        family = [string]$Config.family
        approval_status = "candidate"
        production_method = [string]$Config.method
        reference_ids = @($references | ForEach-Object { [string]$_.id })
        avoid_rules = @(
            "No microtexture, gradients, dithering, lighting simulation, or full-scene generation.",
            "Do not derive collision, attack timing, or navigation from sprite alpha."
        )
        guide_size = if ([int]$Config.size -eq 24) { 768 } else { 512 }
        logical_size = @([int]$Config.size, [int]$Config.size)
        palette_path = "pixel-art-production/assets/palettes/pixel-hangar-v1.json"
        semantic_palette_path = "pixel-art-production/assets/palettes/semantic-mask-v1.json"
        transparent_color = "#FFFFFF"
        runtime_group = [string]$Config.runtime_group
        runtime_layers = @($Config.layers | ForEach-Object { [string]$_.id })
        layers = @($Config.layers)
        pivot = @($Config.default_pivot)
        anchors = $Config.default_anchors
        tile_signature = if ([string]::IsNullOrWhiteSpace([string]$Config.tile_signature)) {
            $null
        } else {
            [string]$Config.tile_signature
        }
        collision_reference = "Existing gameplay-owned geometry for $($Config.family)"
        review_backgrounds = @("space_void", "deck_base", "neutral_highlight")
        silhouette_area_tolerance = 0.08
        anchor_tolerance = 1
        frames = @($Config.frames)
        atlas = [ordered]@{
            columns = [int]$Config.columns
            padding = 2
            extrude = 1
        }
    }
    Write-Json -Value $manifest -Path $manifestPath

    $briefRelative = Get-RepoRelativePath -Path $briefPath
    $manifestRelative = Get-RepoRelativePath -Path $manifestPath
    $buildDirectory = Join-Path $buildRoot ([string]$Config.id)
    $reviewPath = Join-Path $reviewRoot "$($Config.id).png"
    & (Join-Path $PSScriptRoot "validate_pixel_asset_brief.ps1") -BriefPath $briefRelative
    & (Join-Path $PSScriptRoot "invoke_pixel_asset_build.ps1") `
        -ManifestPath $manifestRelative `
        -OutputDirectory (Get-RepoRelativePath -Path $buildDirectory)
    & (Join-Path $PSScriptRoot "build_pixel_asset_review.ps1") `
        -ManifestPath $manifestRelative `
        -BuildDirectory (Get-RepoRelativePath -Path $buildDirectory) `
        -OutputPath (Get-RepoRelativePath -Path $reviewPath)
}

function New-DirectImage {
    param(
        [int]$Size,
        [string]$OutputPath,
        [string[]]$DrawArguments
    )

    Ensure-Directory -Path ([System.IO.Path]::GetDirectoryName($OutputPath))
    $arguments = @("-size", "${Size}x${Size}", "xc:none") + $DrawArguments +
        @("-depth", "8", "-strip", $OutputPath)
    Invoke-Magick -Arguments $arguments
}

function New-LabeledRow {
    param(
        [string]$Label,
        [string[]]$Images,
        [int]$PanelSize,
        [string]$OutputPath
    )

    $temporaryRoot = Join-Path $evidenceRoot "_review-parts"
    Ensure-Directory -Path $temporaryRoot
    $labelPath = Join-Path $temporaryRoot "$([guid]::NewGuid().ToString('N'))-label.png"
    Invoke-Magick -Arguments @(
        "-size", "220x${PanelSize}",
        "xc:#141B24",
        "-fill", "#E8EEF0",
        "-font", "Arial",
        "-pointsize", "18",
        "-gravity", "center",
        "-annotate", "0", $Label,
        $labelPath
    )
    Invoke-Magick -Arguments (@($labelPath) + $Images + @(
        "+append",
        "-depth", "8",
        "-strip",
        $OutputPath
    ))
}

function New-SourcePanel {
    param(
        [string]$SourcePath,
        [string]$OutputPath,
        [int]$PanelSize,
        [string]$Background = "#44515E"
    )

    $size = (& $magick.Source identify -format "%w" $SourcePath).Trim()
    $scale = [Math]::Max(1, [int][Math]::Floor(($PanelSize - 16) / [double][int]$size))
    Invoke-Magick -Arguments @(
        "-size", "${PanelSize}x${PanelSize}", "xc:$Background",
        "(",
        $SourcePath,
        "-filter", "point",
        "-resize", "$($scale * 100)%",
        ")",
        "-gravity", "center",
        "-compose", "over",
        "-composite",
        "-depth", "8",
        "-strip",
        $OutputPath
    )
}

foreach ($directory in @($generatedRoot, $briefRoot, $manifestRoot, $evidenceRoot)) {
    Remove-GeneratedDirectory -Path $directory
    Ensure-Directory -Path $directory
}
foreach ($directory in @($nativeRoot, $buildRoot, $canonicalRoot, $reviewRoot)) {
    Ensure-Directory -Path $directory
}

$weaponCanonical = Normalize-ImageGenSource `
    -RawName "player-primary-weapon-raw.png" `
    -OutputName "player-primary-weapon-north.png" `
    -Cells 64 `
    -Replacements @{
        "#222B35" = "#202833"
        "#596774" = "#44515E"
        "#769A32" = "#D9A83D"
    }
$standardCanonical = Normalize-ImageGenSource `
    -RawName "player-standard-shot-raw.png" `
    -OutputName "player-standard-shot-east.png" `
    -Cells 32 `
    -Replacements @{}
$breachCanonical = Normalize-ImageGenSource `
    -RawName "player-breach-shot-raw.png" `
    -OutputName "player-breach-shot-east.png" `
    -Cells 32 `
    -Replacements @{
        "#222B35" = "#202833"
        "#596774" = "#44515E"
    }
$chaserCanonical = Normalize-ImageGenSource `
    -RawName "chaser-raw.png" `
    -OutputName "chaser-east.png" `
    -Cells 32 `
    -Replacements @{
        "#222B35" = "#202833"
        "#596774" = "#44515E"
    }

$chassis = New-AssetConfig `
    -Id "phase1_player_chassis" `
    -Family "player_chassis" `
    -Size 64 `
    -Method "imagegen_assisted" `
    -RuntimeGroup "player" `
    -Layers @(
        [ordered]@{id = "body"; mask_color = "#FF0000"; z = 0; required = $true},
        [ordered]@{id = "left_wing"; mask_color = "#00FF00"; z = 1; required = $true},
        [ordered]@{id = "right_wing"; mask_color = "#0000FF"; z = 2; required = $true},
        [ordered]@{id = "cockpit"; mask_color = "#FFFF00"; z = 3; required = $true},
        [ordered]@{id = "armor"; mask_color = "#FF00FF"; z = 4; required = $true}
    ) `
    -DefaultAnchors @{muzzle = @(32, 8); left_engine = @(25, 56); right_engine = @(39, 56)} `
    -Columns 4 `
    -AllowedPaletteRoles @("structure_recess", "deck_shadow", "player_reward", "player_energy", "neutral_highlight") `
    -GameplayIdentity "Player-owned interceptor candidate whose facing remains the primary combat anchor." `
    -SilhouetteRequirement "Pointed nose, paired wings, and separated rear engine line read before color." `
    -OrientationCue "The pointed nose and centered muzzle define the forward direction."

$chassisNorthSource = Join-Path $workspaceRoot "evidence/pipeline-sampler/native/player-interceptor.png"
$chassisNorthMaskSource = Join-Path $workspaceRoot "evidence/pipeline-sampler/masks/player-interceptor.png"
$chassisBaseMask = Join-Path $canonicalRoot "player-chassis-north-mask.png"
Invoke-Magick -Arguments @(
    $chassisNorthMaskSource,
    "-fill", "#FF0000", "-opaque", "#FF00FF",
    "-fill", "#FF00FF", "-opaque", "#00FFFF",
    "-depth", "8", "-strip",
    $chassisBaseMask
)
$northChassisAnchors = @{muzzle = @(32, 8); left_engine = @(25, 56); right_engine = @(39, 56)}
foreach ($direction in @(
    @{name = "north"; index = 0; angle = 0},
    @{name = "east"; index = 4; angle = 90},
    @{name = "south"; index = 8; angle = 180},
    @{name = "west"; index = 12; angle = 270}
)) {
    $frameId = "base_$($direction.name)_normal"
    $frameDirectory = Join-Path $nativeRoot "$($chassis.id)/frames"
    $sourcePath = Join-Path $frameDirectory "$frameId.png"
    $maskPath = Join-Path $frameDirectory "$frameId-mask.png"
    Copy-RotatedImage -InputPath $chassisNorthSource -OutputPath $sourcePath -ClockwiseDegrees $direction.angle
    Copy-RotatedImage -InputPath $chassisBaseMask -OutputPath $maskPath -ClockwiseDegrees $direction.angle
    Add-CandidateFrame `
        -Config $chassis `
        -FrameId $frameId `
        -SourcePath $sourcePath `
        -MaskPath $maskPath `
        -Variant "base" `
        -DirectionIndex $direction.index `
        -State "normal" `
        -SequenceIndex 0 `
        -DurationMs 0 `
        -Pivot (Convert-Point -Point @(32, 32) -Size 64 -ClockwiseDegrees $direction.angle) `
        -Anchors (Convert-Anchors -Anchors $northChassisAnchors -Size 64 -ClockwiseDegrees $direction.angle)
}

$weapon = New-AssetConfig `
    -Id "phase1_player_primary_weapon" `
    -Family "player_primary_weapon" `
    -Size 64 `
    -Method "imagegen_assisted" `
    -RuntimeGroup "player" `
    -Layers @(
        [ordered]@{id = "mount"; mask_color = "#FF0000"; z = 0; required = $true},
        [ordered]@{id = "barrel"; mask_color = "#00FF00"; z = 1; required = $true},
        [ordered]@{id = "power_core"; mask_color = "#0000FF"; z = 2; required = $true},
        [ordered]@{id = "muzzle_fx"; mask_color = "#FFFF00"; z = 3; required = $true}
    ) `
    -DefaultAnchors @{mount = @(32, 44); muzzle = @(32, 9)} `
    -Columns 4 `
    -AllowedPaletteRoles @("structure_recess", "deck_shadow", "deck_base", "player_reward", "player_energy", "neutral_highlight") `
    -GameplayIdentity "Centered pulse-cannon module candidate for player manual aim and held fire." `
    -SilhouetteRequirement "One compact rear mount and one long forward barrel read as a weapon, not a vehicle." `
    -OrientationCue "The barrel and pale muzzle cap define the forward direction."
$weaponBaseMask = Join-Path $canonicalRoot "player-primary-weapon-north-mask.png"
New-SemanticMask `
    -SourcePath $weaponCanonical `
    -OutputPath $weaponBaseMask `
    -Size 64 `
    -ResolveSemanticColor {
        param($x, $y, $color)
        if ($color -eq "#65A9B8") { return "#0000FF" }
        if ($color -eq "#E8EEF0") { return "#FFFF00" }
        if ($y -le 32) { return "#00FF00" }
        return "#FF0000"
    }
$northWeaponAnchors = @{mount = @(32, 44); muzzle = @(32, 9)}
foreach ($direction in @(
    @{name = "north"; index = 0; angle = 0},
    @{name = "east"; index = 4; angle = 90},
    @{name = "south"; index = 8; angle = 180},
    @{name = "west"; index = 12; angle = 270}
)) {
    $frameId = "pulse_cannon_$($direction.name)_idle"
    $frameDirectory = Join-Path $nativeRoot "$($weapon.id)/frames"
    $sourcePath = Join-Path $frameDirectory "$frameId.png"
    $maskPath = Join-Path $frameDirectory "$frameId-mask.png"
    Copy-RotatedImage -InputPath $weaponCanonical -OutputPath $sourcePath -ClockwiseDegrees $direction.angle
    Copy-RotatedImage -InputPath $weaponBaseMask -OutputPath $maskPath -ClockwiseDegrees $direction.angle
    Add-CandidateFrame `
        -Config $weapon `
        -FrameId $frameId `
        -SourcePath $sourcePath `
        -MaskPath $maskPath `
        -Variant "pulse_cannon" `
        -DirectionIndex $direction.index `
        -State "idle" `
        -SequenceIndex 0 `
        -DurationMs 0 `
        -Pivot (Convert-Point -Point @(32, 32) -Size 64 -ClockwiseDegrees $direction.angle) `
        -Anchors (Convert-Anchors -Anchors $northWeaponAnchors -Size 64 -ClockwiseDegrees $direction.angle)
}

$engine = New-AssetConfig `
    -Id "phase1_player_engine_flame" `
    -Family "player_engine_flame" `
    -Size 64 `
    -Method "direct_pixel" `
    -RuntimeGroup "player" `
    -Layers @(
        [ordered]@{id = "core"; mask_color = "#FF0000"; z = 0; required = $true},
        [ordered]@{id = "outer_flame"; mask_color = "#00FF00"; z = 1; required = $true}
    ) `
    -DefaultAnchors @{left_nozzle = @(25, 55); right_nozzle = @(38, 55)} `
    -Columns 4 `
    -AllowedPaletteRoles @("player_energy", "neutral_highlight") `
    -GameplayIdentity "Two restrained rear thrust plumes whose four-frame rhythm communicates movement." `
    -SilhouetteRequirement "Two paired plumes stay separate from the chassis and from each other." `
    -OrientationCue "The plumes extend south from two fixed north-facing engine nozzles."
$engineLengths = @(5, 8, 6, 9)
for ($frameIndex = 0; $frameIndex -lt 4; $frameIndex++) {
    $frameId = "thrust_north_frame_$frameIndex"
    $frameDirectory = Join-Path $nativeRoot "$($engine.id)/frames"
    $sourcePath = Join-Path $frameDirectory "$frameId.png"
    $maskPath = Join-Path $frameDirectory "$frameId-mask.png"
    $length = $engineLengths[$frameIndex]
    $endY = [Math]::Min(63, 55 + $length)
    New-DirectImage -Size 64 -OutputPath $sourcePath -DrawArguments @(
        "-fill", "#65A9B8",
        "-draw", "rectangle 23,55 27,$endY rectangle 36,55 40,$endY",
        "-fill", "#E8EEF0",
        "-draw", "rectangle 25,55 25,$([Math]::Max(55, $endY - 2)) rectangle 38,55 38,$([Math]::Max(55, $endY - 2))"
    )
    New-SemanticMask -SourcePath $sourcePath -OutputPath $maskPath -Size 64 -ResolveSemanticColor {
        param($x, $y, $color)
        if ($color -eq "#E8EEF0") { return "#FF0000" }
        return "#00FF00"
    }
    Add-CandidateFrame `
        -Config $engine `
        -FrameId $frameId `
        -SourcePath $sourcePath `
        -MaskPath $maskPath `
        -Variant "thrust" `
        -DirectionIndex 0 `
        -State "frame_$frameIndex" `
        -SequenceIndex $frameIndex `
        -DurationMs 80 `
        -Pivot @(32, 32) `
        -Anchors ([ordered]@{left_nozzle = @(25, 55); right_nozzle = @(38, 55)})
}

$projectiles = New-AssetConfig `
    -Id "phase1_player_primary_projectiles" `
    -Family "player_primary_projectiles" `
    -Size 32 `
    -Method "imagegen_assisted" `
    -RuntimeGroup "player_projectiles" `
    -Layers @(
        [ordered]@{id = "body"; mask_color = "#FF0000"; z = 0; required = $true},
        [ordered]@{id = "core"; mask_color = "#00FF00"; z = 1; required = $true},
        [ordered]@{id = "wake"; mask_color = "#0000FF"; z = 2; required = $true},
        [ordered]@{id = "breach_collar"; mask_color = "#FFFF00"; z = 3; required = $false}
    ) `
    -DefaultAnchors @{head = @(23, 16); rear = @(7, 16)} `
    -Columns 8 `
    -AllowedPaletteRoles @("structure_recess", "deck_base", "player_reward", "player_energy", "neutral_highlight") `
    -GameplayIdentity "Friendly standard and opening Breach projectiles with immediate owner and weight recognition." `
    -SilhouetteRequirement "A decisive front head stays larger than its connected rear wake; Breach adds a broad collar." `
    -OrientationCue "The damaging head and tapering rear wake define travel direction."
$eastProjectileAnchors = @{head = @(23, 16); rear = @(7, 16)}
foreach ($variantSpec in @(
    @{variant = "standard"; canonical = $standardCanonical},
    @{variant = "opening_breach"; canonical = $breachCanonical}
)) {
    foreach ($flightIndex in 0..1) {
        $eastSource = Join-Path $canonicalRoot "$($variantSpec.variant)-east-flight-$flightIndex.png"
        if ($flightIndex -eq 0) {
            Invoke-Magick -Arguments @($variantSpec.canonical, "-depth", "8", "-strip", $eastSource)
        } else {
            Invoke-Magick -Arguments @(
                $variantSpec.canonical,
                "-fill", "#E8EEF0",
                "-opaque", "#65A9B8",
                "-depth", "8",
                "-strip",
                $eastSource
            )
        }
        $eastMask = Join-Path $canonicalRoot "$($variantSpec.variant)-east-flight-$flightIndex-mask.png"
        $isBreach = [string]$variantSpec.variant -eq "opening_breach"
        New-SemanticMask -SourcePath $eastSource -OutputPath $eastMask -Size 32 -ResolveSemanticColor {
            param($x, $y, $color)
            if ($x -le 13) { return "#0000FF" }
            if ($color -in @("#202833", "#222B35")) { return "#00FF00" }
            if ($isBreach -and $color -eq "#E8EEF0") { return "#FFFF00" }
            return "#FF0000"
        }
        foreach ($direction in @(
            @{name = "north"; index = 0; angle = 270},
            @{name = "east"; index = 4; angle = 0},
            @{name = "south"; index = 8; angle = 90},
            @{name = "west"; index = 12; angle = 180}
        )) {
            $frameId = "$($variantSpec.variant)_$($direction.name)_flight_$flightIndex"
            $frameDirectory = Join-Path $nativeRoot "$($projectiles.id)/frames"
            $sourcePath = Join-Path $frameDirectory "$frameId.png"
            $maskPath = Join-Path $frameDirectory "$frameId-mask.png"
            Copy-RotatedImage -InputPath $eastSource -OutputPath $sourcePath -ClockwiseDegrees $direction.angle
            Copy-RotatedImage -InputPath $eastMask -OutputPath $maskPath -ClockwiseDegrees $direction.angle
            Add-CandidateFrame `
                -Config $projectiles `
                -FrameId $frameId `
                -SourcePath $sourcePath `
                -MaskPath $maskPath `
                -Variant $variantSpec.variant `
                -DirectionIndex $direction.index `
                -State "flight_$flightIndex" `
                -SequenceIndex $flightIndex `
                -DurationMs 70 `
                -Pivot (Convert-Point -Point @(16, 16) -Size 32 -ClockwiseDegrees $direction.angle) `
                -Anchors (Convert-Anchors -Anchors $eastProjectileAnchors -Size 32 -ClockwiseDegrees $direction.angle)
        }
    }
}

function Add-MobileEnemyCandidate {
    param(
        [string]$Id,
        [string]$Variant,
        [string]$MoveEastSource,
        [string]$MoveEastMask,
        [string]$StartupEastSource,
        [string]$StartupEastMask,
        [hashtable]$EastAnchors
    )

    $config = New-AssetConfig `
        -Id $Id `
        -Family "mobile_enemy_set" `
        -Size 32 `
        -Method "imagegen_assisted" `
        -RuntimeGroup "mobile_enemies" `
        -Layers @(
            [ordered]@{id = "body"; mask_color = "#FF0000"; z = 0; required = $true},
            [ordered]@{id = "role_accent"; mask_color = "#00FF00"; z = 1; required = $true},
            [ordered]@{id = "weapon_or_tool"; mask_color = "#0000FF"; z = 2; required = $true},
            [ordered]@{id = "mobility"; mask_color = "#FFFF00"; z = 3; required = $true}
        ) `
        -DefaultAnchors $EastAnchors `
        -Columns 4 `
        -AllowedPaletteRoles @("structure_recess", "deck_base", "blocker_top", "neutral_highlight", "ordinary_threat") `
        -GameplayIdentity "$Variant mobile-enemy candidate with a role-specific attack startup." `
        -SilhouetteRequirement "The role remains distinct in black silhouette and does not depend on color." `
        -OrientationCue "Forward contact tool or weapon and rear mobility blocks define travel direction."
    foreach ($stateSpec in @(
        @{state = "move"; source = $MoveEastSource; mask = $MoveEastMask},
        @{state = "attack_startup"; source = $StartupEastSource; mask = $StartupEastMask}
    )) {
        foreach ($direction in @(
            @{name = "north"; index = 0; angle = 270},
            @{name = "east"; index = 4; angle = 0},
            @{name = "south"; index = 8; angle = 90},
            @{name = "west"; index = 12; angle = 180}
        )) {
            $frameId = "$($Variant)_$($direction.name)_$($stateSpec.state)"
            $frameDirectory = Join-Path $nativeRoot "$Id/frames"
            $sourcePath = Join-Path $frameDirectory "$frameId.png"
            $maskPath = Join-Path $frameDirectory "$frameId-mask.png"
            Copy-RotatedImage -InputPath $stateSpec.source -OutputPath $sourcePath -ClockwiseDegrees $direction.angle
            Copy-RotatedImage -InputPath $stateSpec.mask -OutputPath $maskPath -ClockwiseDegrees $direction.angle
            Add-CandidateFrame `
                -Config $config `
                -FrameId $frameId `
                -SourcePath $sourcePath `
                -MaskPath $maskPath `
                -Variant $Variant `
                -DirectionIndex $direction.index `
                -State $stateSpec.state `
                -SequenceIndex 0 `
                -DurationMs 0 `
                -Pivot (Convert-Point -Point @(16, 16) -Size 32 -ClockwiseDegrees $direction.angle) `
                -Anchors (Convert-Anchors -Anchors $EastAnchors -Size 32 -ClockwiseDegrees $direction.angle)
        }
    }
}

$chaserMoveMask = Join-Path $canonicalRoot "chaser-east-move-mask.png"
New-SemanticMask -SourcePath $chaserCanonical -OutputPath $chaserMoveMask -Size 32 -ResolveSemanticColor {
    param($x, $y, $color)
    if ($color -eq "#C92F4E") { return "#0000FF" }
    if ($color -eq "#E8EEF0") { return "#00FF00" }
    if ($x -le 10 -and $color -eq "#44515E") { return "#FFFF00" }
    return "#FF0000"
}
$chaserStartupSource = Join-Path $canonicalRoot "chaser-east-attack-startup.png"
Invoke-Magick -Arguments @(
    $chaserCanonical,
    "-fill", "#E8EEF0",
    "-draw", "rectangle 23,11 24,12 rectangle 23,19 24,20",
    "-depth", "8", "-strip",
    $chaserStartupSource
)
$chaserStartupMask = Join-Path $canonicalRoot "chaser-east-attack-startup-mask.png"
New-SemanticMask -SourcePath $chaserStartupSource -OutputPath $chaserStartupMask -Size 32 -ResolveSemanticColor {
    param($x, $y, $color)
    if ($x -ge 23) { return "#0000FF" }
    if ($color -eq "#C92F4E") { return "#0000FF" }
    if ($color -eq "#E8EEF0") { return "#00FF00" }
    if ($x -le 10 -and $color -eq "#44515E") { return "#FFFF00" }
    return "#FF0000"
}
Add-MobileEnemyCandidate `
    -Id "phase1_mobile_enemy_chaser" `
    -Variant "chaser" `
    -MoveEastSource $chaserCanonical `
    -MoveEastMask $chaserMoveMask `
    -StartupEastSource $chaserStartupSource `
    -StartupEastMask $chaserStartupMask `
    -EastAnchors @{contact = @(24, 16); rear = @(9, 16)}

$shooterMoveSource = Join-Path $workspaceRoot "evidence/pipeline-sampler/native/shooter-drone.png"
$shooterSamplerMask = Join-Path $workspaceRoot "evidence/pipeline-sampler/masks/shooter-drone.png"
$shooterMoveMask = Join-Path $canonicalRoot "shooter-east-move-mask.png"
$shooterStartupSource = Join-Path $canonicalRoot "shooter-east-attack-startup.png"
$shooterStartupMask = Join-Path $canonicalRoot "shooter-east-attack-startup-mask.png"
New-SemanticMask -SourcePath $shooterSamplerMask -OutputPath $shooterMoveMask -Size 32 -ResolveSemanticColor {
    param($x, $y, $color)
    switch ($color) {
        "#FF0000" { "#FF0000" } # body
        "#FFFF00" { "#00FF00" } # role core
        "#FF00FF" { "#0000FF" } # weapon
        "#00FFFF" { "#FFFF00" } # mobility
        default { throw "Unexpected shooter sampler semantic color $color" }
    }
}
Invoke-Magick -Arguments @(
    $shooterMoveSource,
    "-fill", "#E8EEF0",
    "-draw", "rectangle 29,15 30,16",
    "-depth", "8", "-strip",
    $shooterStartupSource
)
Invoke-Magick -Arguments @(
    $shooterMoveMask,
    "-fill", "#0000FF",
    "-draw", "rectangle 29,15 30,16",
    "-depth", "8", "-strip",
    $shooterStartupMask
)
Add-MobileEnemyCandidate `
    -Id "phase1_mobile_enemy_shooter" `
    -Variant "shooter" `
    -MoveEastSource $shooterMoveSource `
    -MoveEastMask $shooterMoveMask `
    -StartupEastSource $shooterStartupSource `
    -StartupEastMask $shooterStartupMask `
    -EastAnchors @{muzzle = @(30, 16); rear = @(7, 16)}

$floor = New-AssetConfig `
    -Id "phase1_world_floor_void_tiles" `
    -Family "world_floor_void_tiles" `
    -Size 24 `
    -Method "direct_pixel" `
    -RuntimeGroup "world" `
    -Layers @(
        [ordered]@{id = "base"; mask_color = "#FF0000"; z = 0; required = $true},
        [ordered]@{id = "large_material_break"; mask_color = "#00FF00"; z = 1; required = $true}
    ) `
    -DefaultAnchors @{center = @(12, 12)} `
    -Columns 4 `
    -AllowedPaletteRoles @("space_void", "structure_recess", "deck_shadow", "deck_base", "blocker_top") `
    -GameplayIdentity "Large quiet floor and void cells that establish walkable versus outside space." `
    -SilhouetteRequirement "Large material regions read without speckle or tiny panel repetition." `
    -OrientationCue "No facing direction; the four patch quadrants assemble in fixed north-west order."
$floorSpecs = @(
    @{id = "space_void"; variant = "space_void"; sequence = 0; base = "#141B24"; break = "#202833"; rect = "rectangle 4,4 11,11"},
    @{id = "floor_light"; variant = "floor_light"; sequence = 0; base = "#596774"; break = "#44515E"; rect = "rectangle 4,4 13,13"},
    @{id = "floor_mid"; variant = "floor_mid"; sequence = 0; base = "#44515E"; break = "#596774"; rect = "rectangle 10,5 19,14"},
    @{id = "floor_dark"; variant = "floor_dark"; sequence = 0; base = "#2E3945"; break = "#44515E"; rect = "rectangle 5,10 14,19"},
    @{id = "floor_patch_2x2_nw"; variant = "floor_patch_2x2"; sequence = 0; base = "#44515E"; break = "#596774"; rect = "rectangle 14,14 23,23"},
    @{id = "floor_patch_2x2_ne"; variant = "floor_patch_2x2"; sequence = 1; base = "#44515E"; break = "#596774"; rect = "rectangle 0,14 9,23"},
    @{id = "floor_patch_2x2_sw"; variant = "floor_patch_2x2"; sequence = 2; base = "#44515E"; break = "#596774"; rect = "rectangle 14,0 23,9"},
    @{id = "floor_patch_2x2_se"; variant = "floor_patch_2x2"; sequence = 3; base = "#44515E"; break = "#596774"; rect = "rectangle 0,0 9,9"}
)
foreach ($spec in $floorSpecs) {
    $frameDirectory = Join-Path $nativeRoot "$($floor.id)/frames"
    $sourcePath = Join-Path $frameDirectory "$($spec.id).png"
    $maskPath = Join-Path $frameDirectory "$($spec.id)-mask.png"
    New-DirectImage -Size 24 -OutputPath $sourcePath -DrawArguments @(
        "-fill", $spec.base, "-draw", "rectangle 0,0 23,23",
        "-fill", $spec.break, "-draw", $spec.rect
    )
    $breakColor = [string]$spec.break
    New-SemanticMask -SourcePath $sourcePath -OutputPath $maskPath -Size 24 -ResolveSemanticColor {
        param($x, $y, $color)
        if ($color -eq $breakColor) { return "#00FF00" }
        return "#FF0000"
    }
    Add-CandidateFrame `
        -Config $floor `
        -FrameId $spec.id `
        -SourcePath $sourcePath `
        -MaskPath $maskPath `
        -Variant $spec.variant `
        -DirectionIndex 0 `
        -State "static" `
        -SequenceIndex $spec.sequence `
        -DurationMs 0 `
        -Pivot @(12, 12) `
        -Anchors ([ordered]@{center = @(12, 12)})
}

$wall = New-AssetConfig `
    -Id "phase1_wall_cover_tiles" `
    -Family "wall_cover_tiles" `
    -Size 24 `
    -Method "direct_pixel" `
    -RuntimeGroup "world" `
    -Layers @(
        [ordered]@{id = "top"; mask_color = "#FF0000"; z = 0; required = $true},
        [ordered]@{id = "side"; mask_color = "#00FF00"; z = 1; required = $true},
        [ordered]@{id = "shadow"; mask_color = "#0000FF"; z = 2; required = $true},
        [ordered]@{id = "boundary_light"; mask_color = "#FFFF00"; z = 3; required = $true}
    ) `
    -DefaultAnchors @{center = @(12, 12)} `
    -Columns 4 `
    -AllowedPaletteRoles @("deck_shadow", "blocker_top", "blocker_edge", "player_energy") `
    -GameplayIdentity "One blocker material with complete orthogonal connectivity and exact transparent openings." `
    -SilhouetteRequirement "Every connected arm reaches its tile edge at a consistent eight-pixel width." `
    -OrientationCue "Neighbor signatures, not decorative perspective, determine orientation." `
    -TileSignature "orthogonal_16"
$wallVariants = @(
    @{name = "isolated"; n = $false; e = $false; s = $false; w = $false},
    @{name = "north"; n = $true; e = $false; s = $false; w = $false},
    @{name = "east"; n = $false; e = $true; s = $false; w = $false},
    @{name = "south"; n = $false; e = $false; s = $true; w = $false},
    @{name = "west"; n = $false; e = $false; s = $false; w = $true},
    @{name = "north_east"; n = $true; e = $true; s = $false; w = $false},
    @{name = "east_south"; n = $false; e = $true; s = $true; w = $false},
    @{name = "south_west"; n = $false; e = $false; s = $true; w = $true},
    @{name = "west_north"; n = $true; e = $false; s = $false; w = $true},
    @{name = "north_south"; n = $true; e = $false; s = $true; w = $false},
    @{name = "east_west"; n = $false; e = $true; s = $false; w = $true},
    @{name = "north_east_south"; n = $true; e = $true; s = $true; w = $false},
    @{name = "east_south_west"; n = $false; e = $true; s = $true; w = $true},
    @{name = "south_west_north"; n = $true; e = $false; s = $true; w = $true},
    @{name = "west_north_east"; n = $true; e = $true; s = $false; w = $true},
    @{name = "all"; n = $true; e = $true; s = $true; w = $true}
)
foreach ($variant in $wallVariants) {
    $rectangles = [System.Collections.Generic.List[string]]::new()
    $rectangles.Add("rectangle 8,8 15,15")
    if ($variant.n) { $rectangles.Add("rectangle 8,0 15,8") }
    if ($variant.e) { $rectangles.Add("rectangle 15,8 23,15") }
    if ($variant.s) { $rectangles.Add("rectangle 8,15 15,23") }
    if ($variant.w) { $rectangles.Add("rectangle 0,8 8,15") }
    $frameDirectory = Join-Path $nativeRoot "$($wall.id)/frames"
    $sourcePath = Join-Path $frameDirectory "$($variant.name).png"
    $maskPath = Join-Path $frameDirectory "$($variant.name)-mask.png"
    New-DirectImage -Size 24 -OutputPath $sourcePath -DrawArguments @(
        "-fill", "#596774", "-draw", ($rectangles -join " "),
        "-fill", "#222B35", "-draw", "rectangle 8,14 15,15",
        "-fill", "#2E3945", "-draw", "rectangle 14,9 15,13",
        "-fill", "#65A9B8", "-draw", "rectangle 8,8 13,8"
    )
    New-SemanticMask -SourcePath $sourcePath -OutputPath $maskPath -Size 24 -ResolveSemanticColor {
        param($x, $y, $color)
        switch ($color) {
            "#596774" { "#FF0000" }
            "#222B35" { "#00FF00" }
            "#2E3945" { "#0000FF" }
            "#65A9B8" { "#FFFF00" }
            default { throw "Unexpected wall color $color" }
        }
    }
    $tileEdges = [ordered]@{
        north = [bool]$variant.n
        east = [bool]$variant.e
        south = [bool]$variant.s
        west = [bool]$variant.w
    }
    Add-CandidateFrame `
        -Config $wall `
        -FrameId $variant.name `
        -SourcePath $sourcePath `
        -MaskPath $maskPath `
        -Variant $variant.name `
        -DirectionIndex 0 `
        -State "static" `
        -SequenceIndex 0 `
        -DurationMs 0 `
        -Pivot @(12, 12) `
        -Anchors ([ordered]@{center = @(12, 12)}) `
        -TileEdges $tileEdges
}

foreach ($config in $assetConfigs) {
    Write-And-BuildAsset -Config $config
}

$wallManifestRelative = Get-RepoRelativePath -Path (Join-Path $manifestRoot "$($wall.id).manifest.json")
$wallSeamProof = Join-Path $evidenceRoot "wall-all-3x3-native.png"
& (Join-Path $workspaceRoot "tools/validation/validate_pixel_asset_seams.ps1") `
    -ManifestPath $wallManifestRelative `
    -ProofOutputPath (Get-RepoRelativePath -Path $wallSeamProof)

$atlasMetadata = @(
    $assetConfigs | ForEach-Object {
        Get-RepoRelativePath -Path (Join-Path $buildRoot "$($_.id)/atlas.json")
    }
)
$catalogPath = Join-Path $evidenceRoot "candidate-catalog.json"
& (Join-Path $PSScriptRoot "build_pixel_asset_catalog.ps1") `
    -AtlasMetadataPaths $atlasMetadata `
    -OutputPath (Get-RepoRelativePath -Path $catalogPath)
$catalog = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
$catalog | Add-Member -NotePropertyName gate -NotePropertyValue "A"
$catalog | Add-Member -NotePropertyName review_status -NotePropertyValue "awaiting_owner"
$catalog | Add-Member -NotePropertyName rejected_frames -NotePropertyValue @()
$catalog | Add-Member -NotePropertyName prompt_sources -NotePropertyValue @(
    "pixel-art-production/assets/source/candidates/phase-1/prompts/player-primary-weapon.md",
    "pixel-art-production/assets/source/candidates/phase-1/prompts/player-standard-shot.md",
    "pixel-art-production/assets/source/candidates/phase-1/prompts/player-breach-shot.md",
    "pixel-art-production/assets/source/candidates/phase-1/prompts/chaser.md"
)
Write-Json -Value $catalog -Path $catalogPath -Depth 20

$reviewMetadata = @(
    $assetConfigs | ForEach-Object {
        Get-RepoRelativePath -Path (Join-Path $reviewRoot "$($_.id).json")
    }
)
& (Join-Path $workspaceRoot "tools/validation/validate_pixel_asset_catalog.ps1") `
    -CatalogPath (Get-RepoRelativePath -Path $catalogPath)
& (Join-Path $workspaceRoot "tools/validation/validate_pixel_asset_frame_budget.ps1") `
    -CatalogPath (Get-RepoRelativePath -Path $catalogPath)
& (Join-Path $workspaceRoot "tools/validation/validate_pixel_asset_reviews.ps1") `
    -ReviewMetadataPaths $reviewMetadata

$temporaryReviewRoot = Join-Path $evidenceRoot "_review-parts"
Ensure-Directory -Path $temporaryReviewRoot

$categoryRows = @(
    @{label = "PLAYER CHASSIS"; asset = $chassis.id; frame = "base_north_normal"},
    @{label = "PRIMARY WEAPON"; asset = $weapon.id; frame = "pulse_cannon_north_idle"},
    @{label = "ENGINE FLAME"; asset = $engine.id; frame = "thrust_north_frame_1"},
    @{label = "STANDARD SHOT"; asset = $projectiles.id; frame = "standard_east_flight_0"},
    @{label = "BREACH SHOT"; asset = $projectiles.id; frame = "opening_breach_east_flight_0"},
    @{label = "CHASER"; asset = "phase1_mobile_enemy_chaser"; frame = "chaser_east_move"},
    @{label = "SHOOTER"; asset = "phase1_mobile_enemy_shooter"; frame = "shooter_east_move"},
    @{label = "FLOOR"; asset = $floor.id; frame = "floor_mid"},
    @{label = "WALL"; asset = $wall.id; frame = "all"}
)
$categoryRowPaths = [System.Collections.Generic.List[string]]::new()
$categoryIndex = 0
foreach ($row in $categoryRows) {
    $source = [string]$frameSources["$($row.asset)/$($row.frame)"]
    $mask = [string]$frameMasks["$($row.asset)/$($row.frame)"]
    $rowDirectory = Join-Path $temporaryReviewRoot "category-$categoryIndex"
    Ensure-Directory -Path $rowDirectory
    $panelSize = 168
    $nativePanel = Join-Path $rowDirectory "01-native.png"
    $enlargedPanel = Join-Path $rowDirectory "02-enlarged.png"
    $semanticPanel = Join-Path $rowDirectory "03-semantic.png"
    $silhouettePanel = Join-Path $rowDirectory "04-silhouette.png"
    $grayscalePanel = Join-Path $rowDirectory "05-grayscale.png"
    $spacePanel = Join-Path $rowDirectory "06-space.png"
    $deckPanel = Join-Path $rowDirectory "07-deck.png"
    $lightPanel = Join-Path $rowDirectory "08-light.png"
    Invoke-Magick -Arguments @(
        "-size", "${panelSize}x${panelSize}", "xc:#44515E",
        $source, "-gravity", "center", "-compose", "over", "-composite",
        $nativePanel
    )
    New-SourcePanel -SourcePath $source -OutputPath $enlargedPanel -PanelSize $panelSize
    New-SourcePanel -SourcePath $mask -OutputPath $semanticPanel -PanelSize $panelSize -Background "#141B24"
    $silhouette = Join-Path $rowDirectory "_silhouette.png"
    Invoke-Magick -Arguments @(
        $source,
        "-channel", "A", "-threshold", "0",
        "+channel", "-fill", "#E8EEF0", "-colorize", "100",
        $silhouette
    )
    New-SourcePanel -SourcePath $silhouette -OutputPath $silhouettePanel -PanelSize $panelSize -Background "#141B24"
    $grayscale = Join-Path $rowDirectory "_grayscale.png"
    Invoke-Magick -Arguments @($source, "-colorspace", "Gray", $grayscale)
    New-SourcePanel -SourcePath $grayscale -OutputPath $grayscalePanel -PanelSize $panelSize -Background "#2E3945"
    New-SourcePanel -SourcePath $source -OutputPath $spacePanel -PanelSize $panelSize -Background "#141B24"
    New-SourcePanel -SourcePath $source -OutputPath $deckPanel -PanelSize $panelSize -Background "#44515E"
    New-SourcePanel -SourcePath $source -OutputPath $lightPanel -PanelSize $panelSize -Background "#E8EEF0"
    $rowPath = Join-Path $temporaryReviewRoot "category-row-$categoryIndex.png"
    New-LabeledRow `
        -Label $row.label `
        -Images @(
            $nativePanel,
            $enlargedPanel,
            $semanticPanel,
            $silhouettePanel,
            $grayscalePanel,
            $spacePanel,
            $deckPanel,
            $lightPanel
        ) `
        -PanelSize $panelSize `
        -OutputPath $rowPath
    $categoryRowPaths.Add($rowPath)
    $categoryIndex++
}
Invoke-Magick -Arguments (@($categoryRowPaths) + @(
    "-append",
    "-depth", "8",
    "-strip",
    (Join-Path $evidenceRoot "category-review.png")
))

$directionRows = @(
    @{label = "CHASSIS N E S W"; keys = @("base_north_normal", "base_east_normal", "base_south_normal", "base_west_normal"); asset = $chassis.id},
    @{label = "WEAPON N E S W"; keys = @("pulse_cannon_north_idle", "pulse_cannon_east_idle", "pulse_cannon_south_idle", "pulse_cannon_west_idle"); asset = $weapon.id},
    @{label = "ENGINE CYCLE 0-3"; keys = @("thrust_north_frame_0", "thrust_north_frame_1", "thrust_north_frame_2", "thrust_north_frame_3"); asset = $engine.id},
    @{label = "STANDARD FLIGHT 0"; keys = @("standard_north_flight_0", "standard_east_flight_0", "standard_south_flight_0", "standard_west_flight_0"); asset = $projectiles.id},
    @{label = "STANDARD FLIGHT 1"; keys = @("standard_north_flight_1", "standard_east_flight_1", "standard_south_flight_1", "standard_west_flight_1"); asset = $projectiles.id},
    @{label = "BREACH FLIGHT 0"; keys = @("opening_breach_north_flight_0", "opening_breach_east_flight_0", "opening_breach_south_flight_0", "opening_breach_west_flight_0"); asset = $projectiles.id},
    @{label = "BREACH FLIGHT 1"; keys = @("opening_breach_north_flight_1", "opening_breach_east_flight_1", "opening_breach_south_flight_1", "opening_breach_west_flight_1"); asset = $projectiles.id},
    @{label = "CHASER MOVE"; keys = @("chaser_north_move", "chaser_east_move", "chaser_south_move", "chaser_west_move"); asset = "phase1_mobile_enemy_chaser"},
    @{label = "CHASER STARTUP"; keys = @("chaser_north_attack_startup", "chaser_east_attack_startup", "chaser_south_attack_startup", "chaser_west_attack_startup"); asset = "phase1_mobile_enemy_chaser"},
    @{label = "SHOOTER MOVE"; keys = @("shooter_north_move", "shooter_east_move", "shooter_south_move", "shooter_west_move"); asset = "phase1_mobile_enemy_shooter"},
    @{label = "SHOOTER STARTUP"; keys = @("shooter_north_attack_startup", "shooter_east_attack_startup", "shooter_south_attack_startup", "shooter_west_attack_startup"); asset = "phase1_mobile_enemy_shooter"}
)
$directionRowPaths = [System.Collections.Generic.List[string]]::new()
$directionIndex = 0
foreach ($row in $directionRows) {
    $panels = [System.Collections.Generic.List[string]]::new()
    foreach ($key in $row.keys) {
        $panel = Join-Path $temporaryReviewRoot "direction-$directionIndex-$key.png"
        New-SourcePanel `
            -SourcePath ([string]$frameSources["$($row.asset)/$key"]) `
            -OutputPath $panel `
            -PanelSize 160
        $panels.Add($panel)
    }
    $rowPath = Join-Path $temporaryReviewRoot "direction-row-$directionIndex.png"
    New-LabeledRow `
        -Label $row.label `
        -Images @($panels) `
        -PanelSize 160 `
        -OutputPath $rowPath
    $directionRowPaths.Add($rowPath)
    $directionIndex++
}
Invoke-Magick -Arguments (@($directionRowPaths) + @(
    "-append",
    "-depth", "8",
    "-strip",
    (Join-Path $evidenceRoot "direction-motion-review.png")
))

$wallPanels = [System.Collections.Generic.List[string]]::new()
$wallIndex = 0
foreach ($variant in $wallVariants) {
    $panel = Join-Path $temporaryReviewRoot "wall-$wallIndex.png"
    $tilePanel = Join-Path $temporaryReviewRoot "wall-$wallIndex-tile.png"
    New-SourcePanel `
        -SourcePath ([string]$frameSources["$($wall.id)/$($variant.name)"]) `
        -OutputPath $tilePanel `
        -PanelSize 192 `
        -Background "#44515E"
    $signature = "{0}{1}{2}{3}" -f @(
        [int][bool]$variant.n,
        [int][bool]$variant.e,
        [int][bool]$variant.s,
        [int][bool]$variant.w
    )
    Invoke-Magick -Arguments @(
        "-size", "192x220", "xc:#141B24",
        $tilePanel, "-geometry", "+0+0", "-compose", "over", "-composite",
        "-fill", "#E8EEF0", "-font", "Arial", "-pointsize", "18",
        "-gravity", "south", "-annotate", "+0+5", "$signature  $($variant.name)",
        $panel
    )
    $wallPanels.Add($panel)
    $wallIndex++
}
$wallGrid = Join-Path $temporaryReviewRoot "wall-grid.png"
Invoke-Magick -Arguments (@("montage") + @($wallPanels) + @(
    "-tile", "4x4",
    "-geometry", "192x220+4+4",
    "-background", "#141B24",
    $wallGrid
))
$wallProofPanel = Join-Path $temporaryReviewRoot "wall-proof-panel.png"
Invoke-Magick -Arguments @(
    "-size", "800x320", "xc:#141B24",
    "(",
    $wallSeamProof,
    "-filter", "point",
    "-resize", "288x288",
    ")",
    "-gravity", "center",
    "-compose", "over",
    "-composite",
    $wallProofPanel
)
Invoke-Magick -Arguments @(
    $wallGrid,
    $wallProofPanel,
    "-append",
    "-depth", "8",
    "-strip",
    (Join-Path $evidenceRoot "wall-signatures.png")
)

if ([System.IO.Directory]::Exists($temporaryReviewRoot)) {
    Remove-Item -LiteralPath $temporaryReviewRoot -Recurse -Force
}

Write-Output "Phase 1 candidate production complete."
Write-Output "Gate A evidence: $evidenceRoot"
$totalFrameCount = ($assetConfigs | ForEach-Object { $_.frames.Count } | Measure-Object -Sum).Sum
Write-Output "Candidate assets: $($assetConfigs.Count); frames: $totalFrameCount"
