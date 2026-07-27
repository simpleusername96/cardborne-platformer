param(
    [Parameter(Mandatory = $true)]
    [string]$ManifestPath,
    [string]$ProofOutputPath = ""
)

$ErrorActionPreference = "Stop"

function Resolve-RepoPath {
    param([string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $script:RepoRoot $Path))
}

function Get-EdgeSignature {
    param(
        [string]$ImagePath,
        [ValidateSet("north", "east", "south", "west")]
        [string]$Edge,
        [int]$Width,
        [int]$Height
    )

    $crop = switch ($Edge) {
        "north" { "${Width}x1+0+0" }
        "south" { "${Width}x1+0+$($Height - 1)" }
        "west" { "1x${Height}+0+0" }
        "east" { "1x${Height}+$($Width - 1)+0" }
    }
    $pixels = & $script:Magick.Source $ImagePath -crop $crop +repage -depth 8 "txt:-"
    $colors = foreach ($line in $pixels) {
        if ($line -match "#(?<rgba>[0-9A-Fa-f]{6}(?:[0-9A-Fa-f]{2})?)") {
            $Matches.rgba.ToUpperInvariant()
        }
    }
    return $colors -join ":"
}

$script:WorkspaceRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$script:RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $script:WorkspaceRoot ".."))
$designTools = Join-Path $script:WorkspaceRoot "tools/design"
& (Join-Path $designTools "validate_pixel_asset_manifest.ps1") `
    -ManifestPath $ManifestPath `
    -RequireInputFiles
$manifest = Get-Content -LiteralPath (Resolve-RepoPath -Path $ManifestPath) -Raw | ConvertFrom-Json
if ([string]$manifest.tile_signature -ne "orthogonal_16") {
    throw "Seam validation requires tile_signature=orthogonal_16."
}

$script:Magick = Get-Command magick -ErrorAction Stop
$width = [int]$manifest.logical_size[0]
$height = [int]$manifest.logical_size[1]
$canonical = @{}
$errors = [System.Collections.Generic.List[string]]::new()

foreach ($frame in @($manifest.frames)) {
    $source = Resolve-RepoPath -Path ([string]$frame.source_path)
    foreach ($edge in @("north", "east", "south", "west")) {
        $axis = if ($edge -in @("north", "south")) { "horizontal" } else { "vertical" }
        $connected = [bool]$frame.tile_edges.$edge
        $key = "$axis/$connected"
        $signature = Get-EdgeSignature -ImagePath $source -Edge $edge -Width $width -Height $height
        if (-not $canonical.ContainsKey($key)) {
            $canonical[$key] = [ordered]@{
                signature = $signature
                frame = [string]$frame.id
                edge = $edge
            }
        } elseif ([string]$canonical[$key].signature -ne $signature) {
            $errors.Add(
                "$($frame.id) $edge edge disagrees with $($canonical[$key].frame) $($canonical[$key].edge) for $key"
            )
        }
    }
}

if ($errors.Count -gt 0) {
    throw "Connected tile seam validation failed:`n$(($errors | ForEach-Object { "- $_" }) -join "`n")"
}

if (-not [string]::IsNullOrWhiteSpace($ProofOutputPath)) {
    $proofDestination = Resolve-RepoPath -Path $ProofOutputPath
    $proofDirectory = [System.IO.Path]::GetDirectoryName($proofDestination)
    if (-not [System.IO.Directory]::Exists($proofDirectory)) {
        [System.IO.Directory]::CreateDirectory($proofDirectory) | Out-Null
    }
    $allFrame = @($manifest.frames | Where-Object {
        [bool]$_.tile_edges.north -and
        [bool]$_.tile_edges.east -and
        [bool]$_.tile_edges.south -and
        [bool]$_.tile_edges.west
    })[0]
    $allSource = Resolve-RepoPath -Path ([string]$allFrame.source_path)
    $row = Join-Path ([System.IO.Path]::GetTempPath()) "cardborne-seam-row-$PID.png"
    try {
        & $script:Magick.Source $allSource $allSource $allSource +append $row
        & $script:Magick.Source $row $row $row -append -depth 8 -strip $proofDestination
        if ($LASTEXITCODE -ne 0) { throw "Could not create 3x3 seam proof." }
    } finally {
        if ([System.IO.File]::Exists($row)) { Remove-Item -LiteralPath $row }
    }
}

Write-Output "Connected tile seams valid: $($manifest.id); 16 orthogonal signatures"
