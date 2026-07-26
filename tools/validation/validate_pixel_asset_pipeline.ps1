param(
    [string]$ManifestPath = "docs/design/pixel-art-asset-pipeline/examples/player-craft.manifest.json",
    [string]$BuildDirectory = "docs/design/pixel-art-asset-pipeline/examples/player-craft-build"
)

$ErrorActionPreference = "Stop"

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$designTools = Join-Path $repoRoot "tools/design"
$manifestFile = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $ManifestPath))
$buildRoot = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $BuildDirectory))
$manifest = Get-Content -LiteralPath $manifestFile -Raw | ConvertFrom-Json
$frame = @($manifest.frames | Sort-Object {[int]$_.atlas_index})[0]
$frameRoot = Join-Path $buildRoot ([string]$frame.id)
$source = Join-Path $frameRoot "source.png"
$semanticMask = Join-Path $frameRoot "semantic-mask.png"
$atlas = Join-Path $buildRoot "atlas.png"
$magick = Get-Command magick -ErrorAction Stop
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) "cardborne-pixel-pipeline-$PID"

try {
    & (Join-Path $designTools "validate_pixel_asset_inventory.ps1")
    & (Join-Path $designTools "validate_pixel_asset_manifest.ps1") `
        -ManifestPath $ManifestPath `
        -RequireInputFiles
    & (Join-Path $designTools "invoke_pixel_asset_build.ps1") `
        -ManifestPath $ManifestPath `
        -OutputDirectory $BuildDirectory

    $difference = (& $magick.Source compare -metric AE $source $atlas "null:" 2>&1).ToString().Trim()
    if ($LASTEXITCODE -ne 0 -or $difference -ne "0") {
        throw "Packed atlas differs from the approved one-frame source by $difference pixel(s)."
    }

    foreach ($layer in @($manifest.layers)) {
        $layerPath = Join-Path $frameRoot "layers/$($layer.id).png"
        $size = (& $magick.Source identify -format "%w %h" $layerPath).Trim()
        $expected = "$($manifest.logical_size[0]) $($manifest.logical_size[1])"
        if ($size -ne $expected) {
            throw "Layer $($layer.id) must be $expected; got $size."
        }
    }

    [System.IO.Directory]::CreateDirectory($temporaryRoot) | Out-Null
    $invalidMask = Join-Path $temporaryRoot "invalid-semantic-mask.png"
    & $magick.Source $semanticMask -fill "#123456" -draw "point 32,5" $invalidMask
    if ($LASTEXITCODE -ne 0) {
        throw "Could not create the negative-test semantic mask."
    }

    $rejected = $false
    try {
        & (Join-Path $designTools "split_pixel_asset_layers.ps1") `
            -SourcePath $source `
            -SemanticMaskPath $invalidMask `
            -ManifestPath $ManifestPath `
            -OutputDirectory (Join-Path $temporaryRoot "invalid-build")
    } catch {
        if ($_.Exception.Message -match "Semantic coverage validation failed") {
            $rejected = $true
        } else {
            throw
        }
    }
    if (-not $rejected) {
        throw "An unknown semantic mask color was not rejected."
    }

    Write-Output "Pixel asset pipeline valid: inventory, manifest, semantic coverage, exact reassembly, SVG layers, and atlas."
    Write-Output "Negative semantic-color test: rejected as expected."
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
