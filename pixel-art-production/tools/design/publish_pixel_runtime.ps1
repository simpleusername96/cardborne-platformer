param(
    [Parameter(Mandatory = $true)]
    [string]$CatalogPath
)

$ErrorActionPreference = "Stop"

$workspaceRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $workspaceRoot ".."))
$sourceCatalog = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $CatalogPath))
$runtimeRoot = Join-Path $workspaceRoot "runtime"
$atlasRoot = Join-Path $runtimeRoot "atlases"
$runtimeCatalogPath = Join-Path $runtimeRoot "catalog.json"
$runtimeAtlasPath = Join-Path $atlasRoot "cardborne-pixel-atlas.png"
$magick = (Get-Command magick -ErrorAction Stop).Source

if (-not [System.IO.File]::Exists($sourceCatalog)) {
    throw "Pixel source catalog does not exist: $CatalogPath"
}

[System.IO.Directory]::CreateDirectory($atlasRoot) | Out-Null
$catalog = Get-Content -LiteralPath $sourceCatalog -Raw | ConvertFrom-Json
$sourceAtlases = [System.Collections.Generic.List[object]]::new()
$atlasWidth = 0
$atlasHeight = 0
foreach ($asset in @($catalog.assets)) {
    $sourceAtlas = [System.IO.Path]::GetFullPath((Join-Path $repoRoot ([string]$asset.atlas_path)))
    if (-not [System.IO.File]::Exists($sourceAtlas)) {
        throw "Pixel atlas does not exist: $($asset.atlas_path)"
    }
    $dimensions = (& $magick identify -format "%w %h" $sourceAtlas).Split(" ")
    if ($LASTEXITCODE -ne 0 -or $dimensions.Count -ne 2) {
        throw "Could not inspect source atlas: $sourceAtlas"
    }
    $width = [int]$dimensions[0]
    $height = [int]$dimensions[1]
    $sourceAtlases.Add([ordered]@{
        asset = $asset
        source = $sourceAtlas
        width = $width
        height = $height
        offset_y = $atlasHeight
    })
    $atlasWidth = [Math]::Max($atlasWidth, $width)
    $atlasHeight += $height
}

$arguments = @("-size", "${atlasWidth}x${atlasHeight}", "xc:none")
foreach ($entry in $sourceAtlases) {
    $arguments += @(
        "(",
        [string]$entry.source,
        ")",
        "-geometry",
        "+0+$([int]$entry.offset_y)",
        "-compose",
        "over",
        "-composite"
    )
}
$arguments += @("-depth", "8", "-strip", $runtimeAtlasPath)
& $magick @arguments
if ($LASTEXITCODE -ne 0) {
    throw "Could not compose the shared runtime pixel atlas."
}

$runtimeAtlasHash = (Get-FileHash -LiteralPath $runtimeAtlasPath -Algorithm SHA256).Hash.ToLowerInvariant()
foreach ($entry in $sourceAtlases) {
    $asset = $entry.asset
    $offsetY = [int]$entry.offset_y
    foreach ($frame in @($asset.frames)) {
        $frame.region[1] = [int]$frame.region[1] + $offsetY
        $frame.cell_region[1] = [int]$frame.cell_region[1] + $offsetY
    }
    $asset.atlas_path = "pixel-art-production/runtime/atlases/cardborne-pixel-atlas.png"
    $asset.atlas_sha256 = $runtimeAtlasHash
    $asset.atlas_size = @($atlasWidth, $atlasHeight)
}

$catalog | ConvertTo-Json -Depth 32 | Set-Content -LiteralPath $runtimeCatalogPath -Encoding utf8
& (Join-Path $workspaceRoot "tools/validation/validate_pixel_asset_catalog.ps1") `
    -CatalogPath "pixel-art-production/runtime/catalog.json"

Write-Output "Published pixel runtime catalog: $runtimeCatalogPath"
Write-Output "Assets=$($catalog.asset_count); frames=$($catalog.frame_count)"
