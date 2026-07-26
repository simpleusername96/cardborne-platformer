param(
    [string[]]$PaletteSpecs = @(
        "art/pixel/palettes/pixel-hangar-v1.json",
        "art/pixel/palettes/semantic-mask-v1.json"
    )
)

$ErrorActionPreference = "Stop"
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$designTools = Join-Path $repoRoot "tools/design"
$magick = Get-Command magick -ErrorAction Stop
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) "cardborne-palette-validation-$PID"
[System.IO.Directory]::CreateDirectory($temporaryRoot) | Out-Null

try {
    foreach ($relativeSpec in $PaletteSpecs) {
        $specPath = if ([System.IO.Path]::IsPathRooted($relativeSpec)) {
            [System.IO.Path]::GetFullPath($relativeSpec)
        } else {
            [System.IO.Path]::GetFullPath((Join-Path $repoRoot $relativeSpec))
        }
        if (-not [System.IO.File]::Exists($specPath)) {
            throw "Palette specification does not exist: $relativeSpec"
        }
        $spec = Get-Content -LiteralPath $specPath -Raw | ConvertFrom-Json
        $properties = @($spec.colors.PSObject.Properties)
        if ($properties.Count -eq 0) {
            throw "Palette contains no colors: $relativeSpec"
        }
        $hexes = @($properties | ForEach-Object { ([string]$_.Value).ToUpperInvariant() })
        if (@($hexes | Sort-Object -Unique).Count -ne $hexes.Count) {
            throw "Palette contains duplicate visible colors: $relativeSpec"
        }
        foreach ($property in $properties) {
            if ([string]$property.Name -notmatch "^[a-z0-9_]+$") {
                throw "Palette role is invalid: $($property.Name)"
            }
            if ([string]$property.Value -notmatch "^#[0-9A-Fa-f]{6}$") {
                throw "Palette color is invalid: $($property.Name)=$($property.Value)"
            }
        }

        $committedPng = [System.IO.Path]::ChangeExtension($specPath, ".png")
        if (-not [System.IO.File]::Exists($committedPng)) {
            throw "Generated palette strip is missing: $committedPng"
        }
        $temporaryPng = Join-Path $temporaryRoot ([System.IO.Path]::GetFileName($committedPng))
        & (Join-Path $designTools "create_pixel_palette.ps1") `
            -PaletteSpecPath $relativeSpec `
            -OutputPath $temporaryPng
        $difference = (& $magick.Source compare -metric AE $committedPng $temporaryPng "null:" 2>&1).ToString().Trim()
        if ($LASTEXITCODE -ne 0 -or $difference -ne "0") {
            throw "Palette strip does not match JSON: $relativeSpec ($difference changed pixels)"
        }
        Write-Output "Pixel palette valid: $($spec.id); roles=$($properties.Count)"
    }
} finally {
    if ([System.IO.Directory]::Exists($temporaryRoot)) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}
