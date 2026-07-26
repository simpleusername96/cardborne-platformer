param(
    [Parameter(Mandatory = $true)]
    [string]$PaletteSpecPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [ValidateSet("colors", "semantic_colors")]
    [string]$ColorGroup = "colors"
)

$ErrorActionPreference = "Stop"

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$specFile = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $PaletteSpecPath))
$destination = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutputPath))
$colorPattern = "^#[0-9A-Fa-f]{6}$"
$magick = Get-Command magick -ErrorAction Stop

if (-not [System.IO.File]::Exists($specFile)) {
    throw "Pixel palette specification does not exist: $specFile"
}

$spec = Get-Content -LiteralPath $specFile -Raw | ConvertFrom-Json
$transparentColor = ([string]$spec.transparent_color).ToUpperInvariant()
if ($transparentColor -notmatch $colorPattern) {
    throw "transparent_color must be a six-digit hex color."
}

$group = $spec.$ColorGroup
if ($null -eq $group -or @($group.PSObject.Properties).Count -eq 0) {
    throw "Palette group '$ColorGroup' is empty."
}

$colors = [System.Collections.Generic.List[string]]::new()
$colors.Add($transparentColor)
foreach ($property in @($group.PSObject.Properties)) {
    $color = ([string]$property.Value).ToUpperInvariant()
    if ($color -notmatch $colorPattern) {
        throw "Palette color '$($property.Name)' is invalid: $color"
    }
    if (-not $colors.Contains($color)) {
        $colors.Add($color)
    }
}

$destinationDirectory = [System.IO.Path]::GetDirectoryName($destination)
if (-not [System.IO.Directory]::Exists($destinationDirectory)) {
    [System.IO.Directory]::CreateDirectory($destinationDirectory) | Out-Null
}

$arguments = @()
foreach ($color in $colors) {
    $arguments += "xc:$color"
}
$arguments += @("+append", "-depth", "8", "-strip", $destination)
& $magick.Source @arguments
if ($LASTEXITCODE -ne 0) {
    throw "ImageMagick failed to create the palette image."
}

Write-Output "Created $($colors.Count)-color '$ColorGroup' palette -> $destination"
