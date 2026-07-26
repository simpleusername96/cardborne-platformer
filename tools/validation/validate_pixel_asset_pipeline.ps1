param(
    [string]$PlayerManifestPath = "docs/design/pixel-art-asset-pipeline/examples/player-craft.manifest.json",
    [string]$PlayerBriefPath = "docs/design/pixel-art-asset-pipeline/examples/player-craft.brief.json",
    [string]$PlayerBuildDirectory = "docs/design/pixel-art-asset-pipeline/examples/player-craft-build-v2",
    [string]$ProjectileManifestPath = "docs/design/pixel-art-asset-pipeline/examples/projectile-proof/projectile.manifest.json",
    [string]$ProjectileBriefPath = "docs/design/pixel-art-asset-pipeline/examples/projectile-proof/projectile.brief.json",
    [string]$ProjectileBuildDirectory = "docs/design/pixel-art-asset-pipeline/examples/projectile-proof/build",
    [string]$CatalogPath = "docs/design/pixel-art-asset-pipeline/examples/proof-catalog.json"
)

$ErrorActionPreference = "Stop"

function Resolve-RepoPath {
    param([string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $script:RepoRoot $Path))
}

function Write-Json {
    param(
        [object]$Value,
        [string]$Path
    )

    [System.IO.File]::WriteAllText(
        $Path,
        ($Value | ConvertTo-Json -Depth 20),
        [System.Text.UTF8Encoding]::new($false)
    )
}

function Assert-Rejected {
    param(
        [string]$Name,
        [scriptblock]$Action,
        [string]$MessagePattern
    )

    $rejected = $false
    try {
        & $Action
    } catch {
        if ($_.Exception.Message -match $MessagePattern) {
            $rejected = $true
        } else {
            throw "Negative test '$Name' failed for an unexpected reason: $($_.Exception.Message)"
        }
    }
    if (-not $rejected) {
        throw "Negative test '$Name' was not rejected."
    }
    Write-Output "Negative test rejected as expected: $Name"
}

function Assert-Reassembly {
    param(
        [object]$Manifest,
        [string]$BuildDirectory
    )

    foreach ($frame in @($Manifest.frames)) {
        $source = Resolve-RepoPath -Path ([string]$frame.source_path)
        $reassembled = Join-Path (Resolve-RepoPath -Path $BuildDirectory) "$($frame.id)/reassembled.png"
        $difference = (& $script:Magick.Source compare -metric AE $source $reassembled "null:" 2>&1).ToString().Trim()
        if ($LASTEXITCODE -ne 0 -or $difference -ne "0") {
            throw "$($frame.id) reassembly differs from approved source by $difference pixel(s)."
        }
    }
}

function New-OrthogonalTileFixture {
    param([string]$Directory)

    [System.IO.Directory]::CreateDirectory($Directory) | Out-Null
    $source = Join-Path $Directory "source.png"
    $mask = Join-Path $Directory "mask.png"
    & $script:Magick.Source -size 24x24 "xc:#44515E" -depth 8 -strip $source
    & $script:Magick.Source -size 24x24 "xc:#FF0000" -depth 8 -strip $mask
    if ($LASTEXITCODE -ne 0) { throw "Could not generate seam-test fixture." }
    $hash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant()
    $frames = [System.Collections.Generic.List[object]]::new()
    for ($bits = 0; $bits -lt 16; $bits++) {
        $variant = "edges_$($bits.ToString('x1'))"
        $frames.Add([ordered]@{
            id = $variant
            source_path = $source
            semantic_mask_path = $mask
            source_sha256 = $hash
            atlas_index = $bits
            variant = $variant
            direction_index = 0
            state = "static"
            sequence_index = 0
            duration_ms = 0
            tile_edges = [ordered]@{
                north = [bool]($bits -band 1)
                east = [bool]($bits -band 2)
                south = [bool]($bits -band 4)
                west = [bool]($bits -band 8)
            }
        })
    }
    $manifest = [ordered]@{
        schema_version = 2
        id = "orthogonal_tile_fixture"
        family = "wall_cover_tiles"
        approval_status = "proof"
        production_method = "direct_pixel"
        reference_ids = @("cc0_kenney_roguelike_modern_city")
        avoid_rules = @("No texture noise.")
        guide_size = 768
        logical_size = @(24, 24)
        palette_path = "art/pixel/palettes/pixel-hangar-v1.json"
        semantic_palette_path = "art/pixel/palettes/semantic-mask-v1.json"
        transparent_color = "#FFFFFF"
        runtime_group = "world"
        runtime_layers = @("base")
        layers = @(
            [ordered]@{id = "base"; mask_color = "#FF0000"; z = 0; required = $true}
        )
        pivot = @(12, 12)
        anchors = [ordered]@{}
        tile_signature = "orthogonal_16"
        collision_reference = "scripts/vehicle/vehicle_stage_geometry.gd"
        review_backgrounds = @("space_void", "deck_base")
        silhouette_area_tolerance = 0.0
        anchor_tolerance = 1
        frames = @($frames)
        atlas = [ordered]@{columns = 4; padding = 2; extrude = 1}
    }
    $manifestPath = Join-Path $Directory "orthogonal.manifest.json"
    Write-Json -Value $manifest -Path $manifestPath
    return [ordered]@{
        manifest = $manifest
        path = $manifestPath
        source = $source
        mask = $mask
    }
}

$script:RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$designTools = Join-Path $script:RepoRoot "tools/design"
$script:Magick = Get-Command magick -ErrorAction Stop
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) "cardborne-pixel-pipeline-$PID"
[System.IO.Directory]::CreateDirectory($temporaryRoot) | Out-Null

$fixturePairs = @(
    [ordered]@{
        manifest = $PlayerManifestPath
        brief = $PlayerBriefPath
        build = $PlayerBuildDirectory
        review = "$PlayerBuildDirectory/review.png"
    },
    [ordered]@{
        manifest = $ProjectileManifestPath
        brief = $ProjectileBriefPath
        build = $ProjectileBuildDirectory
        review = "$ProjectileBuildDirectory/review.png"
    }
)

try {
    & (Join-Path $designTools "validate_pixel_asset_inventory.ps1")
    & (Join-Path $PSScriptRoot "validate_pixel_asset_palettes.ps1")
    & (Join-Path $PSScriptRoot "validate_pixel_asset_import_settings.ps1") -RuntimeTexturePaths @(
        "art/pixel/palettes/pixel-hangar-v1.png",
        "art/pixel/palettes/semantic-mask-v1.png"
    )

    foreach ($fixture in $fixturePairs) {
        & (Join-Path $designTools "validate_pixel_asset_brief.ps1") -BriefPath $fixture.brief
        & (Join-Path $designTools "validate_pixel_asset_manifest.ps1") `
            -ManifestPath $fixture.manifest `
            -RequireInputFiles
        & (Join-Path $designTools "invoke_pixel_asset_build.ps1") `
            -ManifestPath $fixture.manifest `
            -OutputDirectory $fixture.build
        & (Join-Path $designTools "build_pixel_asset_review.ps1") `
            -ManifestPath $fixture.manifest `
            -BuildDirectory $fixture.build `
            -OutputPath $fixture.review
        $manifest = Get-Content -LiteralPath (Resolve-RepoPath -Path $fixture.manifest) -Raw | ConvertFrom-Json
        Assert-Reassembly -Manifest $manifest -BuildDirectory $fixture.build
    }

    $atlasMetadata = @(
        "$PlayerBuildDirectory/atlas.json",
        "$ProjectileBuildDirectory/atlas.json"
    )
    & (Join-Path $designTools "build_pixel_asset_catalog.ps1") `
        -AtlasMetadataPaths $atlasMetadata `
        -OutputPath $CatalogPath
    & (Join-Path $PSScriptRoot "validate_pixel_asset_catalog.ps1") -CatalogPath $CatalogPath
    & (Join-Path $PSScriptRoot "validate_pixel_asset_frame_budget.ps1") -CatalogPath $CatalogPath
    & (Join-Path $PSScriptRoot "validate_pixel_asset_reviews.ps1") -ReviewMetadataPaths @(
        "$PlayerBuildDirectory/review.json",
        "$ProjectileBuildDirectory/review.json"
    )

    $playerManifest = Get-Content -LiteralPath (Resolve-RepoPath -Path $PlayerManifestPath) -Raw | ConvertFrom-Json
    $playerSource = Resolve-RepoPath -Path ([string]$playerManifest.frames[0].source_path)
    $playerMask = Resolve-RepoPath -Path ([string]$playerManifest.frames[0].semantic_mask_path)

    $badChecksum = Get-Content -LiteralPath (Resolve-RepoPath -Path $PlayerManifestPath) -Raw | ConvertFrom-Json
    $badChecksum.frames[0].source_sha256 = "0" * 64
    $badChecksumPath = Join-Path $temporaryRoot "bad-checksum.manifest.json"
    Write-Json -Value $badChecksum -Path $badChecksumPath
    Assert-Rejected -Name "checksum mismatch" -MessagePattern "source_sha256 does not match" -Action {
        & (Join-Path $designTools "validate_pixel_asset_manifest.ps1") `
            -ManifestPath $badChecksumPath `
            -RequireInputFiles
    }

    $unknownMask = Join-Path $temporaryRoot "unknown-mask.png"
    & $script:Magick.Source $playerMask -fill "#123456" -draw "point 32,5" $unknownMask
    Assert-Rejected -Name "unknown semantic color" -MessagePattern "unknown semantic color" -Action {
        & (Join-Path $designTools "split_pixel_asset_layers.ps1") `
            -SourcePath $playerSource `
            -SemanticMaskPath $unknownMask `
            -ManifestPath $PlayerManifestPath `
            -OutputDirectory (Join-Path $temporaryRoot "unknown-mask-build")
    }

    $partialAlpha = Join-Path $temporaryRoot "partial-alpha.png"
    & $script:Magick.Source $playerSource -alpha on -channel A -evaluate set 50% +channel $partialAlpha
    Assert-Rejected -Name "partial alpha" -MessagePattern "partial source alpha" -Action {
        & (Join-Path $designTools "split_pixel_asset_layers.ps1") `
            -SourcePath $partialAlpha `
            -SemanticMaskPath $playerMask `
            -ManifestPath $PlayerManifestPath `
            -OutputDirectory (Join-Path $temporaryRoot "partial-alpha-build")
    }

    $unknownDisplay = Join-Path $temporaryRoot "unknown-display.png"
    & $script:Magick.Source $playerSource -fill "#123456" -draw "point 32,5" $unknownDisplay
    Assert-Rejected -Name "unknown display color" -MessagePattern "unknown display color" -Action {
        & (Join-Path $designTools "split_pixel_asset_layers.ps1") `
            -SourcePath $unknownDisplay `
            -SemanticMaskPath $playerMask `
            -ManifestPath $PlayerManifestPath `
            -OutputDirectory (Join-Path $temporaryRoot "unknown-display-build")
    }

    $semanticGap = Join-Path $temporaryRoot "semantic-gap.png"
    & $script:Magick.Source $playerMask -alpha on -channel A -evaluate set 0 +channel $semanticGap
    Assert-Rejected -Name "semantic gap" -MessagePattern "unassigned source pixel" -Action {
        & (Join-Path $designTools "split_pixel_asset_layers.ps1") `
            -SourcePath $playerSource `
            -SemanticMaskPath $semanticGap `
            -ManifestPath $PlayerManifestPath `
            -OutputDirectory (Join-Path $temporaryRoot "semantic-gap-build")
    }

    $duplicatePalette = Get-Content -LiteralPath (Resolve-RepoPath -Path "art/pixel/palettes/pixel-hangar-v1.json") -Raw | ConvertFrom-Json
    $duplicatePalette.colors.arc = [string]$duplicatePalette.colors.thermal
    $duplicatePalettePath = Join-Path $temporaryRoot "duplicate-palette.json"
    Write-Json -Value $duplicatePalette -Path $duplicatePalettePath
    Assert-Rejected -Name "duplicate palette color" -MessagePattern "duplicate visible colors" -Action {
        & (Join-Path $PSScriptRoot "validate_pixel_asset_palettes.ps1") -PaletteSpecs @($duplicatePalettePath)
    }

    $badPolicy = Get-Content -LiteralPath (Resolve-RepoPath -Path "art/pixel/pixel-import-policy.json") -Raw | ConvertFrom-Json
    $badPolicy.mipmaps = $true
    $badPolicyPath = Join-Path $temporaryRoot "bad-import-policy.json"
    Write-Json -Value $badPolicy -Path $badPolicyPath
    Assert-Rejected -Name "unsafe import policy" -MessagePattern "mipmaps must be false" -Action {
        & (Join-Path $PSScriptRoot "validate_pixel_asset_import_settings.ps1") -PolicyPath $badPolicyPath
    }

    $catalog = Get-Content -LiteralPath (Resolve-RepoPath -Path $CatalogPath) -Raw | ConvertFrom-Json
    $duplicateCatalog = Get-Content -LiteralPath (Resolve-RepoPath -Path $CatalogPath) -Raw | ConvertFrom-Json
    $duplicateFrames = @($duplicateCatalog.assets[0].frames) + @($duplicateCatalog.assets[0].frames[0])
    $duplicateCatalog.assets[0].frames = $duplicateFrames
    $duplicateCatalog.frame_count = [int]$duplicateCatalog.frame_count + 1
    $duplicateCatalogPath = Join-Path $temporaryRoot "duplicate-catalog.json"
    Write-Json -Value $duplicateCatalog -Path $duplicateCatalogPath
    Assert-Rejected -Name "duplicate catalog frame key" -MessagePattern "duplicate frame key" -Action {
        & (Join-Path $PSScriptRoot "validate_pixel_asset_catalog.ps1") -CatalogPath $duplicateCatalogPath
    }

    $overflowCatalog = Get-Content -LiteralPath (Resolve-RepoPath -Path $CatalogPath) -Raw | ConvertFrom-Json
    $overflowFrames = [System.Collections.Generic.List[object]]::new()
    for ($index = 0; $index -lt 1000; $index++) {
        $overflowFrames.Add($overflowCatalog.assets[0].frames[0])
    }
    $overflowCatalog.assets[0].frames = @($overflowFrames)
    $overflowCatalog.frame_count = 1000 + @($overflowCatalog.assets[1].frames).Count
    $overflowCatalogPath = Join-Path $temporaryRoot "overflow-catalog.json"
    Write-Json -Value $overflowCatalog -Path $overflowCatalogPath
    Assert-Rejected -Name "frame budget overflow" -MessagePattern "frame budget validation failed" -Action {
        & (Join-Path $PSScriptRoot "validate_pixel_asset_frame_budget.ps1") -CatalogPath $overflowCatalogPath
    }

    $badReview = Get-Content -LiteralPath (
        Resolve-RepoPath -Path "$PlayerBuildDirectory/review.json"
    ) -Raw | ConvertFrom-Json
    $badReview.frames[0].panels = @($badReview.frames[0].panels | Where-Object {
        [string]$_.kind -ne "silhouette"
    })
    $badReview.review_path = Resolve-RepoPath -Path "$PlayerBuildDirectory/review.png"
    $badReviewPath = Join-Path $temporaryRoot "bad-review.json"
    Write-Json -Value $badReview -Path $badReviewPath
    Assert-Rejected -Name "incomplete review board" -MessagePattern "missing silhouette" -Action {
        & (Join-Path $PSScriptRoot "validate_pixel_asset_reviews.ps1") -ReviewMetadataPaths @($badReviewPath)
    }

    $bleedAtlas = Join-Path $temporaryRoot "bleed-atlas.png"
    $sourceAtlas = Resolve-RepoPath -Path ([string]$catalog.assets[0].atlas_path)
    $sourceAtlasWidth = [int]$catalog.assets[0].atlas_size[0]
    $sourceAtlasHeight = [int]$catalog.assets[0].atlas_size[1]
    & $script:Magick.Source $sourceAtlas -background none -gravity northwest `
        -extent "$($sourceAtlasWidth + 3)x$sourceAtlasHeight" `
        -fill "#E45F36" -draw "point $($sourceAtlasWidth + 2),1" `
        -depth 8 -strip $bleedAtlas
    $bleedCatalog = Get-Content -LiteralPath (Resolve-RepoPath -Path $CatalogPath) -Raw | ConvertFrom-Json
    $bleedCatalog.assets[0].atlas_path = $bleedAtlas
    $bleedCatalog.assets[0].atlas_size[0] = $sourceAtlasWidth + 3
    $bleedCatalog.assets[0].atlas_sha256 = (
        Get-FileHash -LiteralPath $bleedAtlas -Algorithm SHA256
    ).Hash.ToLowerInvariant()
    $bleedCatalogPath = Join-Path $temporaryRoot "bleed-catalog.json"
    Write-Json -Value $bleedCatalog -Path $bleedCatalogPath
    Assert-Rejected -Name "atlas bleed" -MessagePattern "atlas bleed" -Action {
        & (Join-Path $PSScriptRoot "validate_pixel_asset_catalog.ps1") -CatalogPath $bleedCatalogPath
    }

    $tileFixture = New-OrthogonalTileFixture -Directory (Join-Path $temporaryRoot "tiles")
    & (Join-Path $PSScriptRoot "validate_pixel_asset_seams.ps1") `
        -ManifestPath $tileFixture.path `
        -ProofOutputPath (Join-Path $temporaryRoot "tile-proof.png")
    $brokenTile = Join-Path $temporaryRoot "tiles/broken-source.png"
    & $script:Magick.Source $tileFixture.source -fill "#596774" -draw "point 23,12" $brokenTile
    $brokenTileHash = (Get-FileHash -LiteralPath $brokenTile -Algorithm SHA256).Hash.ToLowerInvariant()
    $brokenManifest = $tileFixture.manifest
    $brokenManifest.frames[0].source_path = $brokenTile
    $brokenManifest.frames[0].source_sha256 = $brokenTileHash
    $brokenManifestPath = Join-Path $temporaryRoot "tiles/broken.manifest.json"
    Write-Json -Value $brokenManifest -Path $brokenManifestPath
    Assert-Rejected -Name "connected tile seam" -MessagePattern "seam validation failed" -Action {
        & (Join-Path $PSScriptRoot "validate_pixel_asset_seams.ps1") -ManifestPath $brokenManifestPath
    }

    Write-Output "Pixel asset pipeline valid: v2 contracts, exact semantic rebuilds, extrusion, catalog, reviews, budgets, seams, and negative gates."
} finally {
    $resolvedTemporaryRoot = [System.IO.Path]::GetFullPath($temporaryRoot)
    $resolvedSystemTemp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    if (
        [System.IO.Directory]::Exists($resolvedTemporaryRoot) -and
        $resolvedTemporaryRoot.StartsWith($resolvedSystemTemp, [System.StringComparison]::OrdinalIgnoreCase) -and
        [System.IO.Path]::GetFileName($resolvedTemporaryRoot).StartsWith("cardborne-pixel-pipeline-")
    ) {
        Remove-Item -LiteralPath $resolvedTemporaryRoot -Recurse -Force
    }
}
