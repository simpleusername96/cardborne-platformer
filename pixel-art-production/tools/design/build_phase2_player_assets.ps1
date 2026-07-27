param(
    [switch]$SkipBuild,
    [switch]$Resume
)

$ErrorActionPreference = "Stop"

$workspaceRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $workspaceRoot ".."))
$magick = (Get-Command magick -ErrorAction Stop).Source
$inventory = Get-Content -LiteralPath (Join-Path $workspaceRoot "assets/asset-inventory.json") -Raw | ConvertFrom-Json
$sourceRoot = Join-Path $workspaceRoot "assets/source/approved/phase-2"
$briefRoot = Join-Path $workspaceRoot "assets/briefs/approved/phase-2"
$manifestRoot = Join-Path $workspaceRoot "assets/manifests/approved/phase-2"
$generatedRoot = Join-Path $workspaceRoot "assets/generated/approved/phase-2"
$evidenceRoot = Join-Path $workspaceRoot "evidence/gates/02-live-player-slice"

function Ensure-Directory {
    param([string]$Path)
    [System.IO.Directory]::CreateDirectory($Path) | Out-Null
}

function Convert-ToRepoPath {
    param([string]$Path)
    return [System.IO.Path]::GetRelativePath($repoRoot, [System.IO.Path]::GetFullPath($Path)).Replace("\", "/")
}

function Write-Json {
    param([object]$Value, [string]$Path)
    Ensure-Directory ([System.IO.Path]::GetDirectoryName($Path))
    $Value | ConvertTo-Json -Depth 32 | Set-Content -LiteralPath $Path -Encoding utf8
}

function Invoke-Magick {
    param([string[]]$Arguments)
    & $magick @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "ImageMagick failed: $($Arguments -join ' ')"
    }
}

function Copy-Rotated {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [int]$Size,
        [double]$Angle
    )
    Ensure-Directory ([System.IO.Path]::GetDirectoryName($OutputPath))
    Invoke-Magick @(
        $InputPath,
        "-background", "none",
        "-filter", "point",
        "-rotate", ([string]$Angle),
        "-gravity", "center",
        "-crop", "${Size}x${Size}+0+0",
        "+repage",
        "-channel", "A",
        "-threshold", "50%",
        "+channel",
        "-dither", "None",
        # Remap against the source asset itself. The global semantic palette
        # contains IDs that are intentionally absent from individual masks;
        # using it here could invent undeclared layer IDs after rotation.
        "-remap", $InputPath,
        "-channel", "A",
        "-threshold", "50%",
        "+channel",
        "-depth", "8",
        "-strip",
        $OutputPath
    )
}

function Copy-Offset {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [int]$Size,
        [int]$OffsetX,
        [int]$OffsetY
    )
    Ensure-Directory ([System.IO.Path]::GetDirectoryName($OutputPath))
    Invoke-Magick @(
        "-size", "${Size}x${Size}", "xc:none",
        "(",
        $InputPath,
        ")",
        "-geometry", ("{0:+#;-#;+0}{1:+#;-#;+0}" -f $OffsetX, $OffsetY),
        "-compose", "over",
        "-composite",
        "-depth", "8",
        "-strip",
        $OutputPath
    )
}

function New-DirectFrame {
    param(
        [int]$Size,
        [string]$OutputPath,
        [string[]]$DrawArguments
    )
    Ensure-Directory ([System.IO.Path]::GetDirectoryName($OutputPath))
    Invoke-Magick (@("-size", "${Size}x${Size}", "xc:none") + $DrawArguments + @(
        "-depth", "8",
        "-strip",
        $OutputPath
    ))
}

function Convert-Point {
    param(
        [int[]]$Point,
        [int]$Size,
        [double]$ClockwiseDegrees
    )
    $center = ($Size - 1.0) * 0.5
    $radians = $ClockwiseDegrees * [Math]::PI / 180.0
    $dx = [double]$Point[0] - $center
    $dy = [double]$Point[1] - $center
    return @(
        [int][Math]::Round($center + $dx * [Math]::Cos($radians) - $dy * [Math]::Sin($radians)),
        [int][Math]::Round($center + $dx * [Math]::Sin($radians) + $dy * [Math]::Cos($radians))
    )
}

function Convert-Anchors {
    param(
        [hashtable]$Anchors,
        [int]$Size,
        [double]$ClockwiseDegrees
    )
    $result = [ordered]@{}
    foreach ($key in $Anchors.Keys | Sort-Object) {
        $result[$key] = Convert-Point -Point @($Anchors[$key]) -Size $Size -ClockwiseDegrees $ClockwiseDegrees
    }
    return $result
}

function New-Asset {
    param(
        [string]$Id,
        [string]$Family,
        [int]$Size,
        [string]$Method,
        [object[]]$Layers,
        [string[]]$States,
        [int]$Directions,
        [string]$RuntimeGroup,
        [hashtable]$Anchors,
        [string]$Identity,
        [string]$Silhouette,
        [string]$Orientation,
        [string[]]$AllowedPaletteRoles,
        [int]$Columns = 8
    )
    $inventoryEntry = $inventory.assets | Where-Object { $_.id -eq $Family } | Select-Object -First 1
    if ($null -eq $inventoryEntry) {
        throw "Missing inventory family: $Family"
    }
    return [ordered]@{
        id = $Id
        family = $Family
        size = $Size
        method = $Method
        layers = $Layers
        states = $States
        directions = $Directions
        runtime_group = $RuntimeGroup
        anchors = $Anchors
        identity = $Identity
        silhouette = $Silhouette
        orientation = $Orientation
        allowed_palette_roles = $AllowedPaletteRoles
        columns = $Columns
        current_owner = @($inventoryEntry.current_owner)
        frames = [System.Collections.Generic.List[object]]::new()
    }
}

function Add-Frame {
    param(
        [hashtable]$Asset,
        [string]$Id,
        [string]$SourcePath,
        [string]$MaskPath,
        [string]$Variant,
        [int]$Direction,
        [string]$State,
        [int]$Sequence,
        [int]$Duration,
        [int[]]$Pivot,
        [object]$Anchors
    )
    $Asset.frames.Add([ordered]@{
        id = $Id
        source_path = Convert-ToRepoPath $SourcePath
        semantic_mask_path = Convert-ToRepoPath $MaskPath
        source_sha256 = (Get-FileHash -LiteralPath $SourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
        atlas_index = $Asset.frames.Count
        variant = $Variant
        direction_index = $Direction
        state = $State
        sequence_index = $Sequence
        duration_ms = $Duration
        pivot = @($Pivot)
        anchors = $Anchors
    })
}

function Complete-Asset {
    param([hashtable]$Asset)
    $briefPath = Join-Path $briefRoot "$($Asset.id).brief.json"
    $manifestPath = Join-Path $manifestRoot "$($Asset.id).manifest.json"
    $buildPath = Join-Path $generatedRoot "build/$($Asset.id)"
    $reviewPath = Join-Path $evidenceRoot "reviews/$($Asset.id).png"
    $brief = [ordered]@{
        schema_version = 1
        id = $Asset.id
        family = $Asset.family
        approval_status = "approved"
        gameplay_identity = $Asset.identity
        current_owner = @($Asset.current_owner)
        native_size = @($Asset.size, $Asset.size)
        rendered_diameter = $Asset.size
        silhouette_requirement = $Asset.silhouette
        orientation_cue = $Asset.orientation
        semantic_parts = @($Asset.layers | ForEach-Object { $_.id })
        pivot = @(($Asset.size / 2), ($Asset.size / 2))
        anchors = $Asset.anchors
        directions = $Asset.directions
        states = @($Asset.states)
        allowed_palette_roles = @($Asset.allowed_palette_roles)
        references = @(
            [ordered]@{id = "game_assault_android_cactus"; study = "Preserve role and orientation at dense top-down combat scale."},
            [ordered]@{id = "cc0_kenney_pixel_shmup"; study = "Preserve economical whole-cell silhouettes and modular construction."}
        )
        avoid_rules = @(
            "No gradients, antialiasing, texture noise, lighting simulation, or baked glow.",
            "Do not derive collision, attack timing, or navigation from pixel alpha."
        )
        production_method = $Asset.method
        collision_reference = "Existing gameplay-owned geometry for $($Asset.family)."
        runtime_group = $Asset.runtime_group
        review_backgrounds = @("space_void", "deck_base", "neutral_highlight")
        density_tier = "all"
    }
    $manifest = [ordered]@{
        schema_version = 2
        id = $Asset.id
        family = $Asset.family
        approval_status = "approved"
        production_method = $Asset.method
        reference_ids = @("game_assault_android_cactus", "cc0_kenney_pixel_shmup")
        avoid_rules = @(
            "No gradients, antialiasing, texture noise, lighting simulation, or baked glow.",
            "Do not derive gameplay geometry from sprite alpha."
        )
        guide_size = 512
        logical_size = @($Asset.size, $Asset.size)
        palette_path = "pixel-art-production/assets/palettes/pixel-hangar-v1.json"
        semantic_palette_path = "pixel-art-production/assets/palettes/semantic-mask-v1.json"
        transparent_color = "#FFFFFF"
        runtime_group = $Asset.runtime_group
        runtime_layers = @($Asset.layers | ForEach-Object { $_.id })
        layers = @($Asset.layers)
        pivot = @(($Asset.size / 2), ($Asset.size / 2))
        anchors = $Asset.anchors
        tile_signature = $null
        collision_reference = "Existing gameplay-owned geometry for $($Asset.family)."
        review_backgrounds = @("space_void", "deck_base", "neutral_highlight")
        silhouette_area_tolerance = 0.12
        anchor_tolerance = 1
        frames = @($Asset.frames)
        atlas = [ordered]@{columns = $Asset.columns; padding = 2; extrude = 1}
    }
    Write-Json $brief $briefPath
    Write-Json $manifest $manifestPath
    $briefRelative = Convert-ToRepoPath $briefPath
    $manifestRelative = Convert-ToRepoPath $manifestPath
    & (Join-Path $PSScriptRoot "validate_pixel_asset_brief.ps1") -BriefPath $briefRelative | Out-Null
    & (Join-Path $PSScriptRoot "validate_pixel_asset_manifest.ps1") -ManifestPath $manifestRelative -RequireInputFiles | Out-Null
    if (-not $SkipBuild) {
        if (-not ($Resume -and (Test-Path -LiteralPath (Join-Path $buildPath "atlas.json")))) {
            & (Join-Path $PSScriptRoot "invoke_pixel_asset_build.ps1") `
                -ManifestPath $manifestRelative `
                -OutputDirectory (Convert-ToRepoPath $buildPath) | Out-Null
        }
        if (-not ($Resume -and (Test-Path -LiteralPath $reviewPath))) {
            & (Join-Path $PSScriptRoot "build_pixel_asset_review.ps1") `
                -ManifestPath $manifestRelative `
                -BuildDirectory (Convert-ToRepoPath $buildPath) `
                -OutputPath (Convert-ToRepoPath $reviewPath) | Out-Null
        }
    }
    return Convert-ToRepoPath (Join-Path $buildPath "atlas.json")
}

foreach ($path in @($sourceRoot, $briefRoot, $manifestRoot, $generatedRoot, $evidenceRoot)) {
    Ensure-Directory $path
}

$semantic5 = @(
    [ordered]@{id = "body"; mask_color = "#FF0000"; z = 0; required = $true},
    [ordered]@{id = "left_wing"; mask_color = "#00FF00"; z = 1; required = $true},
    [ordered]@{id = "right_wing"; mask_color = "#0000FF"; z = 2; required = $true},
    [ordered]@{id = "cockpit"; mask_color = "#FFFF00"; z = 3; required = $true},
    [ordered]@{id = "armor"; mask_color = "#FF00FF"; z = 4; required = $true}
)
$chassis = New-Asset `
    -Id "player_chassis" -Family "player_chassis" -Size 64 -Method "imagegen_assisted" `
    -Layers $semantic5 -States @("normal") -Directions 16 -RuntimeGroup "player" `
    -Anchors @{muzzle = @(32, 8); left_engine = @(25, 56); right_engine = @(39, 56)} `
    -Identity "Player-owned interceptor whose hull facing remains the primary combat anchor." `
    -Silhouette "Pointed nose, paired wings, and a separated rear engine line read before color." `
    -Orientation "The pointed nose and centered forward mount define facing." `
    -AllowedPaletteRoles @("structure_recess", "deck_shadow", "player_reward", "player_energy", "neutral_highlight")
$chassisNorth = Join-Path $workspaceRoot "assets/generated/candidates/phase-1/native/phase1_player_chassis/frames/base_north_normal.png"
$chassisNorthMask = Join-Path $workspaceRoot "assets/generated/candidates/phase-1/native/phase1_player_chassis/frames/base_north_normal-mask.png"
for ($direction = 0; $direction -lt 16; $direction++) {
    $angle = 22.5 * $direction
    $frameRoot = Join-Path $sourceRoot "player_chassis"
    $source = Join-Path $frameRoot ("base_{0:D2}_normal.png" -f $direction)
    $mask = Join-Path $frameRoot ("base_{0:D2}_normal-mask.png" -f $direction)
    Copy-Rotated $chassisNorth $source 64 $angle
    Copy-Rotated $chassisNorthMask $mask 64 $angle
    Add-Frame $chassis ("base_{0:D2}_normal" -f $direction) $source $mask "base" $direction "normal" 0 0 `
        (Convert-Point @(32, 32) 64 $angle) `
        (Convert-Anchors @{muzzle = @(32, 8); left_engine = @(25, 56); right_engine = @(39, 56)} 64 $angle)
}

$weaponLayers = @(
    [ordered]@{id = "mount"; mask_color = "#FF0000"; z = 0; required = $true},
    [ordered]@{id = "barrel"; mask_color = "#00FF00"; z = 1; required = $true},
    [ordered]@{id = "power_core"; mask_color = "#0000FF"; z = 2; required = $true},
    [ordered]@{id = "muzzle_fx"; mask_color = "#FFFF00"; z = 3; required = $true}
)
$weapon = New-Asset `
    -Id "player_primary_weapon" -Family "player_primary_weapon" -Size 64 -Method "imagegen_assisted" `
    -Layers $weaponLayers -States @("idle", "recoil") -Directions 16 -RuntimeGroup "player" `
    -Anchors @{mount = @(32, 44); muzzle = @(32, 9)} `
    -Identity "Independent pulse cannon for manual aim and held primary fire." `
    -Silhouette "A compact rear mount and long centered barrel read separately from the hull." `
    -Orientation "The pale muzzle cap defines the firing edge." `
    -AllowedPaletteRoles @("structure_recess", "deck_shadow", "player_reward", "player_energy", "neutral_highlight")
$weaponNorth = Join-Path $workspaceRoot "assets/generated/candidates/phase-1/native/phase1_player_primary_weapon/frames/pulse_cannon_north_idle.png"
$weaponNorthMask = Join-Path $workspaceRoot "assets/generated/candidates/phase-1/native/phase1_player_primary_weapon/frames/pulse_cannon_north_idle-mask.png"
$weaponRecoil = Join-Path $sourceRoot "player_primary_weapon/pulse_cannon_north_recoil.png"
$weaponRecoilMask = Join-Path $sourceRoot "player_primary_weapon/pulse_cannon_north_recoil-mask.png"
Copy-Offset $weaponNorth $weaponRecoil 64 0 2
Copy-Offset $weaponNorthMask $weaponRecoilMask 64 0 2
foreach ($stateSpec in @(
    @{state = "idle"; source = $weaponNorth; mask = $weaponNorthMask; shift = 0},
    @{state = "recoil"; source = $weaponRecoil; mask = $weaponRecoilMask; shift = 2}
)) {
    for ($direction = 0; $direction -lt 16; $direction++) {
        $angle = 22.5 * $direction
        $frameRoot = Join-Path $sourceRoot "player_primary_weapon"
        $source = Join-Path $frameRoot ("pulse_cannon_{0:D2}_{1}.png" -f $direction, $stateSpec.state)
        $mask = Join-Path $frameRoot ("pulse_cannon_{0:D2}_{1}-mask.png" -f $direction, $stateSpec.state)
        Copy-Rotated $stateSpec.source $source 64 $angle
        Copy-Rotated $stateSpec.mask $mask 64 $angle
        $baseAnchors = @{mount = @(32, (44 + $stateSpec.shift)); muzzle = @(32, (9 + $stateSpec.shift))}
        Add-Frame $weapon ("pulse_cannon_{0:D2}_{1}" -f $direction, $stateSpec.state) $source $mask `
            "pulse_cannon" $direction $stateSpec.state 0 (100) `
            (Convert-Point @(32, (32 + $stateSpec.shift)) 64 $angle) `
            (Convert-Anchors $baseAnchors 64 $angle)
    }
}

$moduleLayers = @(
    [ordered]@{id = "left_mount"; mask_color = "#FF0000"; z = 0; required = $false},
    [ordered]@{id = "center_mount"; mask_color = "#00FF00"; z = 1; required = $false},
    [ordered]@{id = "right_mount"; mask_color = "#0000FF"; z = 2; required = $false}
)
$modules = New-Asset `
    -Id "player_engine_modules" -Family "player_engine_modules" -Size 64 -Method "imagegen_assisted" `
    -Layers $moduleLayers -States @("installed") -Directions 4 -RuntimeGroup "player" `
    -Anchors @{} `
    -Identity "Count-readable installed thruster modules for movement-speed upgrades." `
    -Silhouette "Zero through three large rear pods remain countable without labels." `
    -Orientation "Each pod sits on the rear line opposite the hull nose." `
    -AllowedPaletteRoles @("structure_recess", "deck_shadow", "player_reward", "player_energy") -Columns 4
for ($count = 0; $count -le 3; $count++) {
    $north = Join-Path $sourceRoot "player_engine_modules/module_count_${count}_north.png"
    $northMask = Join-Path $sourceRoot "player_engine_modules/module_count_${count}_north-mask.png"
    $draw = [System.Collections.Generic.List[string]]::new()
    $maskDraw = [System.Collections.Generic.List[string]]::new()
    if ($count -ge 2) {
        $draw.AddRange([string[]]@("-fill", "#D9A83D", "-draw", "rectangle 19,49 26,57", "-fill", "#222B35", "-draw", "rectangle 21,55 24,59"))
        $maskDraw.AddRange([string[]]@("-fill", "#FF0000", "-draw", "rectangle 19,49 26,57 rectangle 21,55 24,59"))
        $draw.AddRange([string[]]@("-fill", "#D9A83D", "-draw", "rectangle 38,49 45,57", "-fill", "#222B35", "-draw", "rectangle 40,55 43,59"))
        $maskDraw.AddRange([string[]]@("-fill", "#0000FF", "-draw", "rectangle 38,49 45,57 rectangle 40,55 43,59"))
    }
    if ($count -in @(1, 3)) {
        $draw.AddRange([string[]]@("-fill", "#D9A83D", "-draw", "rectangle 28,48 35,57", "-fill", "#222B35", "-draw", "rectangle 30,55 33,60"))
        $maskDraw.AddRange([string[]]@("-fill", "#00FF00", "-draw", "rectangle 28,48 35,57 rectangle 30,55 33,60"))
    }
    New-DirectFrame 64 $north @($draw)
    New-DirectFrame 64 $northMask @($maskDraw)
    foreach ($direction in @(0, 4, 8, 12)) {
        $angle = 22.5 * $direction
        $source = Join-Path $sourceRoot ("player_engine_modules/module_count_{0}_{1:D2}.png" -f $count, $direction)
        $mask = Join-Path $sourceRoot ("player_engine_modules/module_count_{0}_{1:D2}-mask.png" -f $count, $direction)
        Copy-Rotated $north $source 64 $angle
        Copy-Rotated $northMask $mask 64 $angle
        Add-Frame $modules ("module_count_{0}_{1:D2}" -f $count, $direction) $source $mask `
            "module_count_$count" $direction "installed" 0 0 @(32, 32) ([ordered]@{})
    }
}

$flameLayers = @(
    [ordered]@{id = "core"; mask_color = "#FF0000"; z = 0; required = $true},
    [ordered]@{id = "outer_flame"; mask_color = "#00FF00"; z = 1; required = $true}
)
$flame = New-Asset `
    -Id "player_engine_flame" -Family "player_engine_flame" -Size 64 -Method "direct_pixel" `
    -Layers $flameLayers -States @("idle", "thrust") -Directions 16 -RuntimeGroup "player" `
    -Anchors @{mount = @(32, 50)} `
    -Identity "A separate engine plume anchored to installed rear thrusters." `
    -Silhouette "One broad outer plume and one narrow bright core read as propulsion." `
    -Orientation "The plume extends away from the mount and opposite movement facing." `
    -AllowedPaletteRoles @("player_energy", "neutral_highlight") -Columns 8
$flameBases = @{}
foreach ($state in @("idle", "thrust")) {
    $length = if ($state -eq "idle") { 7 } else { 13 }
    $source = Join-Path $sourceRoot "player_engine_flame/${state}_north.png"
    $mask = Join-Path $sourceRoot "player_engine_flame/${state}_north-mask.png"
    New-DirectFrame 64 $source @(
        "-fill", "#65A9B8", "-draw", "polygon 27,50 36,50 39,$(50 + $length) 32,$(53 + $length) 24,$(50 + $length)",
        "-fill", "#E8EEF0", "-draw", "rectangle 30,51 33,$(49 + $length)"
    )
    New-DirectFrame 64 $mask @(
        "-fill", "#00FF00", "-draw", "polygon 27,50 36,50 39,$(50 + $length) 32,$(53 + $length) 24,$(50 + $length)",
        "-fill", "#FF0000", "-draw", "rectangle 30,51 33,$(49 + $length)"
    )
    $flameBases[$state] = @{source = $source; mask = $mask}
}
foreach ($state in @("idle", "thrust")) {
    for ($direction = 0; $direction -lt 16; $direction++) {
        $angle = 22.5 * $direction
        $source = Join-Path $sourceRoot ("player_engine_flame/{0}_{1:D2}.png" -f $state, $direction)
        $mask = Join-Path $sourceRoot ("player_engine_flame/{0}_{1:D2}-mask.png" -f $state, $direction)
        Copy-Rotated $flameBases[$state].source $source 64 $angle
        Copy-Rotated $flameBases[$state].mask $mask 64 $angle
        Add-Frame $flame ("{0}_{1:D2}" -f $state, $direction) $source $mask `
            $state $direction $state 0 (90) @(32, 32) `
            (Convert-Anchors @{mount = @(32, 50)} 64 $angle)
    }
}

$dashLayers = @(
    [ordered]@{id = "burst"; mask_color = "#FF0000"; z = 0; required = $true},
    [ordered]@{id = "trail"; mask_color = "#00FF00"; z = 1; required = $true},
    [ordered]@{id = "afterimage"; mask_color = "#0000FF"; z = 2; required = $true}
)
$dash = New-Asset `
    -Id "player_dash_effect" -Family "player_dash_effect" -Size 64 -Method "direct_pixel" `
    -Layers $dashLayers -States @("frame_0") -Directions 16 -RuntimeGroup "player" `
    -Anchors @{origin = @(32, 32)} `
    -Identity "Movement-direction dash feedback split into start, travel, and end phases." `
    -Silhouette "A forward burst, long travel rails, and compact end fragments remain distinct." `
    -Orientation "All streaks align with the actual dash movement vector." `
    -AllowedPaletteRoles @("player_energy", "neutral_highlight", "player_reward") -Columns 8
$dashBases = @{}
foreach ($variant in @("start", "travel", "end")) {
    $source = Join-Path $sourceRoot "player_dash_effect/${variant}_north.png"
    $mask = Join-Path $sourceRoot "player_dash_effect/${variant}_north-mask.png"
    if ($variant -eq "start") {
        New-DirectFrame 64 $source @(
            "-fill", "#65A9B8", "-draw", "polygon 32,5 22,23 27,23 20,37 32,29 44,37 37,23 42,23",
            "-fill", "#E8EEF0", "-draw", "rectangle 30,9 33,26",
            "-fill", "#D9A83D", "-draw", "rectangle 24,34 39,38"
        )
        New-DirectFrame 64 $mask @(
            "-fill", "#FF0000", "-draw", "polygon 32,5 22,23 27,23 20,37 32,29 44,37 37,23 42,23",
            "-fill", "#00FF00", "-draw", "rectangle 30,9 33,26",
            "-fill", "#0000FF", "-draw", "rectangle 24,34 39,38"
        )
    } elseif ($variant -eq "travel") {
        New-DirectFrame 64 $source @(
            "-fill", "#65A9B8", "-draw", "rectangle 18,7 23,53 rectangle 40,7 45,53",
            "-fill", "#E8EEF0", "-draw", "rectangle 20,7 21,45 rectangle 42,7 43,45",
            "-fill", "#D9A83D", "-draw", "rectangle 27,24 36,39"
        )
        New-DirectFrame 64 $mask @(
            "-fill", "#00FF00", "-draw", "rectangle 18,7 23,53 rectangle 40,7 45,53",
            "-fill", "#FF0000", "-draw", "rectangle 20,7 21,45 rectangle 42,7 43,45",
            "-fill", "#0000FF", "-draw", "rectangle 27,24 36,39"
        )
    } else {
        New-DirectFrame 64 $source @(
            "-fill", "#65A9B8", "-draw", "rectangle 13,27 25,31 rectangle 38,27 50,31",
            "-fill", "#E8EEF0", "-draw", "rectangle 20,17 24,25 rectangle 39,17 43,25",
            "-fill", "#D9A83D", "-draw", "rectangle 29,23 34,34"
        )
        New-DirectFrame 64 $mask @(
            "-fill", "#00FF00", "-draw", "rectangle 13,27 25,31 rectangle 38,27 50,31",
            "-fill", "#FF0000", "-draw", "rectangle 20,17 24,25 rectangle 39,17 43,25",
            "-fill", "#0000FF", "-draw", "rectangle 29,23 34,34"
        )
    }
    $dashBases[$variant] = @{source = $source; mask = $mask}
}
foreach ($variant in @("start", "travel", "end")) {
    for ($direction = 0; $direction -lt 16; $direction++) {
        $angle = 22.5 * $direction
        $source = Join-Path $sourceRoot ("player_dash_effect/{0}_{1:D2}.png" -f $variant, $direction)
        $mask = Join-Path $sourceRoot ("player_dash_effect/{0}_{1:D2}-mask.png" -f $variant, $direction)
        Copy-Rotated $dashBases[$variant].source $source 64 $angle
        Copy-Rotated $dashBases[$variant].mask $mask 64 $angle
        Add-Frame $dash ("{0}_{1:D2}_frame_0" -f $variant, $direction) $source $mask `
            $variant $direction "frame_0" 0 80 @(32, 32) `
            (Convert-Anchors @{origin = @(32, 32)} 64 $angle)
    }
}

$projectileLayers = @(
    [ordered]@{id = "body"; mask_color = "#FF0000"; z = 0; required = $true},
    [ordered]@{id = "core"; mask_color = "#00FF00"; z = 1; required = $true},
    [ordered]@{id = "wake"; mask_color = "#0000FF"; z = 2; required = $true},
    [ordered]@{id = "breach_collar"; mask_color = "#FFFF00"; z = 3; required = $false}
)
$projectiles = New-Asset `
    -Id "player_primary_projectiles" -Family "player_primary_projectiles" -Size 32 -Method "imagegen_assisted" `
    -Layers $projectileLayers -States @("flight_0", "flight_1") -Directions 8 -RuntimeGroup "player_projectiles" `
    -Anchors @{head = @(25, 16); rear = @(7, 16)} `
    -Identity "Player standard ammunition and a visibly heavier opening Breach round." `
    -Silhouette "Standard fire is compact; Breach fire has a larger collar and forward mass." `
    -Orientation "A leading head and connected rear wake make travel direction unambiguous." `
    -AllowedPaletteRoles @("structure_recess", "player_reward", "player_energy", "neutral_highlight") -Columns 8
$projectileCanonicals = @(
    @{
        variant = "standard"
        source = (Join-Path $workspaceRoot "assets/generated/candidates/phase-1/native/phase1_player_primary_projectiles/frames/standard_east_flight_0.png")
        mask = (Join-Path $workspaceRoot "assets/generated/candidates/phase-1/native/phase1_player_primary_projectiles/frames/standard_east_flight_0-mask.png")
        head = @(25, 16)
        rear = @(7, 16)
    },
    @{
        variant = "opening_breach"
        source = (Join-Path $workspaceRoot "assets/generated/candidates/phase-1/native/phase1_player_primary_projectiles/frames/opening_breach_east_flight_0.png")
        mask = (Join-Path $workspaceRoot "assets/generated/candidates/phase-1/native/phase1_player_primary_projectiles/frames/opening_breach_east_flight_0-mask.png")
        head = @(26, 16)
        rear = @(5, 16)
    }
)
foreach ($canonical in $projectileCanonicals) {
    foreach ($sequence in 0..1) {
        $sequenceSource = $canonical.source
        if ($sequence -eq 1) {
            $sequenceSource = Join-Path $sourceRoot ("player_primary_projectiles/{0}_east_flight_1-base.png" -f $canonical.variant)
            Invoke-Magick @(
                $canonical.source,
                "-fill", "#E8EEF0",
                "-opaque", "#65A9B8",
                "-depth", "8",
                "-strip",
                $sequenceSource
            )
        }
        for ($directionStep = 0; $directionStep -lt 8; $directionStep++) {
            $direction = $directionStep * 2
            # Projectile direction zero follows the actor contract (north).
            # The canonical source faces east, so rotate it once counter-clockwise
            # before stepping clockwise through the eight authored directions.
            $angle = -90.0 + 45.0 * $directionStep
            $source = Join-Path $sourceRoot ("player_primary_projectiles/{0}_{1:D2}_flight_{2}.png" -f $canonical.variant, $direction, $sequence)
            $mask = Join-Path $sourceRoot ("player_primary_projectiles/{0}_{1:D2}_flight_{2}-mask.png" -f $canonical.variant, $direction, $sequence)
            Copy-Rotated $sequenceSource $source 32 $angle
            Copy-Rotated $canonical.mask $mask 32 $angle
            Add-Frame $projectiles ("{0}_{1:D2}_flight_{2}" -f $canonical.variant, $direction, $sequence) `
                $source $mask $canonical.variant $direction "flight_$sequence" $sequence 70 `
                (Convert-Point @(16, 16) 32 $angle) `
                (Convert-Anchors @{head = $canonical.head; rear = $canonical.rear} 32 $angle)
        }
    }
}

$atlasMetadata = [System.Collections.Generic.List[string]]::new()
foreach ($asset in @($chassis, $weapon, $modules, $flame, $dash, $projectiles)) {
    $atlasMetadata.Add((Complete-Asset $asset))
}

if (-not $SkipBuild) {
    $catalogPath = Join-Path $generatedRoot "catalog.json"
    & (Join-Path $PSScriptRoot "build_pixel_asset_catalog.ps1") `
        -AtlasMetadataPaths @($atlasMetadata) `
        -OutputPath (Convert-ToRepoPath $catalogPath) | Out-Null
    & (Join-Path $workspaceRoot "tools/validation/validate_pixel_asset_catalog.ps1") `
        -CatalogPath (Convert-ToRepoPath $catalogPath) | Out-Null
}

Write-Output "Phase 2 player asset production complete."
Write-Output "Assets=6; frames=$((@($chassis, $weapon, $modules, $flame, $dash, $projectiles) | ForEach-Object { $_.frames.Count } | Measure-Object -Sum).Sum)"
