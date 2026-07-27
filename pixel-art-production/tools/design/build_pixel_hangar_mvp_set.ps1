param(
    [Parameter(Mandatory = $true)]
    [string]$ManifestPath
)

$ErrorActionPreference = "Stop"

$workspaceRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $workspaceRoot ".."))
$manifestFile = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $ManifestPath))
$snapScript = Join-Path $PSScriptRoot "snap_image_to_pixel_grid.ps1"
$magick = Get-Command magick -ErrorAction Stop

if (-not [System.IO.File]::Exists($manifestFile)) {
    throw "MVP build manifest does not exist: $manifestFile"
}

$manifest = Get-Content -LiteralPath $manifestFile -Raw | ConvertFrom-Json
$canvasSize = [int]$manifest.canvas_size
$cells = [int]$manifest.cells
$reviewSize = [int]$manifest.review_size
$candidates = @($manifest.candidates)

if ($candidates.Count -lt 1) {
    throw "MVP build manifest must contain at least one candidate."
}
if ($canvasSize % $cells -ne 0) {
    throw "canvas_size must be exactly divisible by cells."
}
if ($reviewSize % $cells -ne 0) {
    throw "review_size must be an integer multiple of cells."
}

function Resolve-RepoPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return [System.IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
}

$reviewFiles = [System.Collections.Generic.List[string]]::new()

foreach ($candidate in $candidates) {
    $source = Resolve-RepoPath ([string]$candidate.source)
    $palette = Resolve-RepoPath ([string]$candidate.palette)
    $native = Resolve-RepoPath ([string]$candidate.native)
    $review = Resolve-RepoPath ([string]$candidate.review)

    foreach ($required in @($source, $palette)) {
        if (-not [System.IO.File]::Exists($required)) {
            throw "Required MVP input does not exist: $required"
        }
    }

    & $snapScript `
        -InputPath $source `
        -PalettePath $palette `
        -OutputPath $native `
        -CanvasSize $canvasSize `
        -Cells $cells `
        -KeepBackground

    $reviewDirectory = [System.IO.Path]::GetDirectoryName($review)
    if (-not [System.IO.Directory]::Exists($reviewDirectory)) {
        [System.IO.Directory]::CreateDirectory($reviewDirectory) | Out-Null
    }

    & $magick.Source `
        $native `
        -filter point `
        -resize "${reviewSize}x${reviewSize}!" `
        -depth 8 `
        -strip `
        $review
    if ($LASTEXITCODE -ne 0) {
        throw "ImageMagick failed to create review image for '$($candidate.id)'."
    }

    $nativeGeometry = (& $magick.Source identify -format "%wx%h" $native).Trim()
    $reviewGeometry = (& $magick.Source identify -format "%wx%h" $review).Trim()
    $nativeColors = [int]((& $magick.Source identify -format "%k" $native).Trim())
    if ($nativeGeometry -ne "${cells}x${cells}") {
        throw "Native MVP '$($candidate.id)' must be ${cells}x${cells}; got $nativeGeometry."
    }
    if ($reviewGeometry -ne "${reviewSize}x${reviewSize}") {
        throw "Review MVP '$($candidate.id)' must be ${reviewSize}x${reviewSize}; got $reviewGeometry."
    }
    if ($nativeColors -gt 16) {
        throw "Native MVP '$($candidate.id)' exceeds the 16-color research limit: $nativeColors."
    }

    $reviewFiles.Add($review)
}

if ($null -ne $manifest.comparison -and [string]$manifest.comparison -ne "") {
    $comparison = Resolve-RepoPath ([string]$manifest.comparison)
    $comparisonDirectory = [System.IO.Path]::GetDirectoryName($comparison)
    if (-not [System.IO.Directory]::Exists($comparisonDirectory)) {
        [System.IO.Directory]::CreateDirectory($comparisonDirectory) | Out-Null
    }

    $montageArguments = @(
        "montage"
    )
    $montageArguments += @($reviewFiles)
    $montageArguments += @(
        "-tile", "2x",
        "-geometry", "${reviewSize}x${reviewSize}+16+16",
        "-background", "#0B1118",
        "-depth", "8",
        "-strip",
        $comparison
    )

    & $magick.Source @montageArguments
    if ($LASTEXITCODE -ne 0) {
        throw "ImageMagick failed to create the MVP comparison image."
    }
}

Write-Output "Built $($candidates.Count) logical-cell MVP candidates from $manifestFile"
