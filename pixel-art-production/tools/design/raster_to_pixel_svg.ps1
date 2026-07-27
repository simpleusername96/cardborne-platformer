param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

$magick = Get-Command magick -ErrorAction Stop
$source = [System.IO.Path]::GetFullPath($InputPath)
$destination = [System.IO.Path]::GetFullPath($OutputPath)

if (-not [System.IO.File]::Exists($source)) {
    throw "Input image does not exist: $source"
}

$size = (& $magick.Source identify -format "%w %h" $source).Trim().Split(" ")
$width = [int]$size[0]
$height = [int]$size[1]

$pixels = @{}
$pixelText = & $magick.Source $source -depth 8 "txt:-"
foreach ($line in $pixelText) {
    if ($line -notmatch "^(?<x>\d+),(?<y>\d+):.*#(?<rgba>[0-9A-Fa-f]{8})") {
        continue
    }

    $rgba = $Matches.rgba.ToUpperInvariant()
    if ($rgba.Substring(6, 2) -eq "00") {
        continue
    }

    $key = "$($Matches.x),$($Matches.y)"
    $pixels[$key] = "#$($rgba.Substring(0, 6))"
}

$rects = [System.Collections.Generic.List[string]]::new()
for ($y = 0; $y -lt $height; $y++) {
    $x = 0
    while ($x -lt $width) {
        $key = "$x,$y"
        if (-not $pixels.ContainsKey($key)) {
            $x++
            continue
        }

        $color = $pixels[$key]
        $start = $x
        $x++
        while ($x -lt $width -and $pixels["$x,$y"] -eq $color) {
            $x++
        }

        $runWidth = $x - $start
        $rects.Add("  <rect x=`"$start`" y=`"$y`" width=`"$runWidth`" height=`"1`" fill=`"$color`"/>")
    }
}

$svg = @(
    "<svg xmlns=`"http://www.w3.org/2000/svg`" width=`"$width`" height=`"$height`" viewBox=`"0 0 $width $height`" shape-rendering=`"crispEdges`">"
    "  <metadata>Generated from $([System.IO.Path]::GetFileName($source)); transparent pixels omitted; same-color horizontal pixels merged.</metadata>"
    $rects
    "</svg>"
) -join [Environment]::NewLine

$destinationDirectory = [System.IO.Path]::GetDirectoryName($destination)
if (-not [System.IO.Directory]::Exists($destinationDirectory)) {
    [System.IO.Directory]::CreateDirectory($destinationDirectory) | Out-Null
}

[System.IO.File]::WriteAllText(
    $destination,
    $svg + [Environment]::NewLine,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Output "Created ${width}x${height} pixel SVG with $($rects.Count) color runs -> $destination"
