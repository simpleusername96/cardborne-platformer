param(
    [string]$ManifestPath = "pixel-art-production/assets/manifests/approved/visual-recovery/core-slice.json",
    [string]$CatalogPath = ""
)

$ErrorActionPreference = "Stop"

function Add-ValidationError {
    param([string]$Message)

    $script:Errors.Add($Message)
}

function Test-HasProperty {
    param(
        [object]$Value,
        [string]$Name
    )

    return $null -ne $Value -and $null -ne $Value.PSObject.Properties[$Name]
}

function Get-PropertyValue {
    param(
        [object]$Value,
        [string]$Name
    )

    if (-not (Test-HasProperty -Value $Value -Name $Name)) {
        return $null
    }
    # Preserve JSON arrays as arrays even when they contain a single value.
    return ,$Value.PSObject.Properties[$Name].Value
}

function Test-JsonInteger {
    param([object]$Value)

    return (
        $Value -is [sbyte] -or
        $Value -is [byte] -or
        $Value -is [int16] -or
        $Value -is [uint16] -or
        $Value -is [int32] -or
        $Value -is [uint32] -or
        $Value -is [int64] -or
        $Value -is [uint64]
    )
}

function Test-ContainsOrdinal {
    param(
        [string[]]$Values,
        [string]$Expected
    )

    foreach ($value in $Values) {
        if ([string]::Equals($value, $Expected, [System.StringComparison]::Ordinal)) {
            return $true
        }
    }
    return $false
}

function Resolve-RepoPath {
    param(
        [string]$Path,
        [switch]$RequireRepoRelative
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "Path cannot be empty."
    }
    $candidate = $Path.Trim()
    if ($candidate.StartsWith("res://", [System.StringComparison]::OrdinalIgnoreCase)) {
        $candidate = $candidate.Substring(6)
    }
    if ([System.IO.Path]::IsPathRooted($candidate)) {
        if ($RequireRepoRelative) {
            throw "Path must be repository-relative: $Path"
        }
        return [System.IO.Path]::GetFullPath($candidate)
    }
    $resolved = [System.IO.Path]::GetFullPath((Join-Path $script:RepoRoot $candidate))
    if ($RequireRepoRelative) {
        $repoPrefix = $script:RepoRoot.TrimEnd(
            [System.IO.Path]::DirectorySeparatorChar,
            [System.IO.Path]::AltDirectorySeparatorChar
        ) + [System.IO.Path]::DirectorySeparatorChar
        if (-not $resolved.StartsWith(
            $repoPrefix,
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
            throw "Path escapes the repository root: $Path"
        }
    }
    return $resolved
}

function Read-JsonDocument {
    param(
        [string]$Path,
        [string]$Label
    )

    if (-not [System.IO.File]::Exists($Path)) {
        throw "$Label does not exist: $Path"
    }
    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    } catch {
        throw "$Label is not valid JSON: $Path ($($_.Exception.Message))"
    }
}

function Test-Sha256 {
    param([string]$Value)

    return $Value -match "^[0-9A-Fa-f]{64}$"
}

function Confirm-FileHash {
    param(
        [string]$DeclaredPath,
        [string]$ExpectedHash,
        [string]$Label
    )

    $resolvedPath = $null
    try {
        $resolvedPath = Resolve-RepoPath -Path $DeclaredPath -RequireRepoRelative
    } catch {
        Add-ValidationError "$Label path is invalid: $DeclaredPath"
        return $null
    }
    if (-not [System.IO.File]::Exists($resolvedPath)) {
        Add-ValidationError "$Label does not exist: $DeclaredPath"
        return $null
    }
    if (-not (Test-Sha256 -Value $ExpectedHash)) {
        Add-ValidationError "$Label SHA-256 must contain exactly 64 hexadecimal characters."
        return $resolvedPath
    }
    $actualHash = (Get-FileHash -LiteralPath $resolvedPath -Algorithm SHA256).Hash
    if (-not [string]::Equals(
        $actualHash,
        $ExpectedHash,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        Add-ValidationError "$Label SHA-256 mismatch: $DeclaredPath"
    }
    return $resolvedPath
}

function Get-ImagePixels {
    param(
        [string]$ImagePath,
        [string]$Label
    )

    $identifyOutput = @(
        & $script:Magick.Source identify -quiet -format "%w %h" $ImagePath 2>&1
    )
    if ($LASTEXITCODE -ne 0) {
        Add-ValidationError "$Label could not be read by ImageMagick: $ImagePath"
        return $null
    }
    $dimensions = (($identifyOutput | ForEach-Object { [string]$_ }) -join "").Trim()
    if ($dimensions -notmatch "^(?<width>\d+) (?<height>\d+)$") {
        Add-ValidationError "$Label returned invalid ImageMagick dimensions: $dimensions"
        return $null
    }
    $width = [int]$Matches.width
    $height = [int]$Matches.height
    if ($width -le 0 -or $height -le 0) {
        Add-ValidationError "$Label must have positive dimensions."
        return $null
    }

    $pixelOutput = @(
        & $script:Magick.Source $ImagePath -alpha on -depth 8 "txt:-" 2>&1
    )
    if ($LASTEXITCODE -ne 0) {
        Add-ValidationError "$Label pixels could not be read by ImageMagick: $ImagePath"
        return $null
    }
    $pixels = [string[]]::new($width * $height)
    $seen = 0
    foreach ($lineValue in $pixelOutput) {
        $line = [string]$lineValue
        if (
            $line -match (
                "^(?<x>\d+),(?<y>\d+):.*#" +
                "(?<rgba>[0-9A-Fa-f]{6}(?:[0-9A-Fa-f]{2})?)(?:\s|$)"
            )
        ) {
            $x = [int]$Matches.x
            $y = [int]$Matches.y
            if ($x -ge $width -or $y -ge $height) {
                continue
            }
            $rgba = $Matches.rgba.ToUpperInvariant()
            if ($rgba.Length -eq 6) {
                $rgba = "${rgba}FF"
            }
            $index = $y * $width + $x
            if ($null -eq $pixels[$index]) {
                $seen++
            }
            $pixels[$index] = $rgba
        }
    }
    if ($seen -ne $width * $height) {
        Add-ValidationError (
            "$Label did not yield exactly $($width * $height) pixels through ImageMagick."
        )
        return $null
    }
    return [pscustomobject]@{
        Width = $width
        Height = $height
        Pixels = $pixels
    }
}

function Confirm-ImagePolicy {
    param(
        [object]$Image,
        [string]$Label,
        [int[]]$ExpectedSize,
        [bool]$RequireOpaque,
        [bool]$RequireRepeatSafe
    )

    if ($null -eq $Image) {
        return
    }
    if (
        $ExpectedSize.Count -eq 2 -and
        (
            [int]$Image.Width -ne $ExpectedSize[0] -or
            [int]$Image.Height -ne $ExpectedSize[1]
        )
    ) {
        Add-ValidationError (
            "$Label dimensions are $($Image.Width)x$($Image.Height); " +
            "expected $($ExpectedSize[0])x$($ExpectedSize[1])."
        )
    }

    $partialAlphaReported = $false
    $transparencyReported = $false
    $transparentColorReported = $false
    $paletteReported = $false
    for ($index = 0; $index -lt $Image.Pixels.Count; $index++) {
        $rgba = [string]$Image.Pixels[$index]
        $alpha = $rgba.Substring(6, 2)
        $x = $index % [int]$Image.Width
        $y = [int][Math]::Floor($index / [double]$Image.Width)
        if ($alpha -ne "00" -and $alpha -ne "FF" -and -not $partialAlphaReported) {
            Add-ValidationError "$Label contains partial alpha at $x,$y."
            $partialAlphaReported = $true
        }
        if ($RequireOpaque -and $alpha -ne "FF" -and -not $transparencyReported) {
            Add-ValidationError "$Label must be fully opaque; alpha differs at $x,$y."
            $transparencyReported = $true
        }
        if (
            $alpha -eq "00" -and
            $rgba.Substring(0, 6) -ne $script:TransparentColor -and
            -not $transparentColorReported
        ) {
            Add-ValidationError (
                "$Label uses transparent RGB #$($rgba.Substring(0, 6)) at $x,$y; " +
                "expected #$($script:TransparentColor)."
            )
            $transparentColorReported = $true
        }
        if (
            $alpha -eq "FF" -and
            -not $script:AllowedPalette.Contains($rgba.Substring(0, 6)) -and
            -not $paletteReported
        ) {
            Add-ValidationError "$Label uses off-palette color #$($rgba.Substring(0, 6)) at $x,$y."
            $paletteReported = $true
        }
    }

    if ($RequireRepeatSafe) {
        $horizontalMismatch = $false
        for ($x = 0; $x -lt [int]$Image.Width; $x++) {
            $north = [string]$Image.Pixels[$x]
            $south = [string]$Image.Pixels[
                ([int]$Image.Height - 1) * [int]$Image.Width + $x
            ]
            if ($north -ne $south) {
                Add-ValidationError "$Label north and south edges are not mechanically equal."
                $horizontalMismatch = $true
                break
            }
        }
        for ($y = 0; $y -lt [int]$Image.Height; $y++) {
            $west = [string]$Image.Pixels[$y * [int]$Image.Width]
            $east = [string]$Image.Pixels[
                $y * [int]$Image.Width + [int]$Image.Width - 1
            ]
            if ($west -ne $east) {
                Add-ValidationError "$Label west and east edges are not mechanically equal."
                break
            }
        }
    }
}

function Confirm-ImagesEqual {
    param(
        [object]$Expected,
        [object]$Actual,
        [string]$Label
    )

    if ($null -eq $Expected -or $null -eq $Actual) {
        return
    }
    if (
        [int]$Expected.Width -ne [int]$Actual.Width -or
        [int]$Expected.Height -ne [int]$Actual.Height
    ) {
        Add-ValidationError "$Label does not have the approved source dimensions."
        return
    }
    for ($index = 0; $index -lt $Expected.Pixels.Count; $index++) {
        if ([string]$Expected.Pixels[$index] -ne [string]$Actual.Pixels[$index]) {
            Add-ValidationError "$Label pixels do not match the approved repeat source."
            return
        }
    }
}

function ConvertTo-GodotRoundedInteger {
    param([double]$Value)

    # Equivalent 45-degree coordinates can land one ULP to either side of a
    # half pixel across math runtimes. Restore the exact grid-symmetry point
    # before applying Godot's documented halfway rule.
    $nearestHalf = [Math]::Round($Value * 2.0) / 2.0
    if ([Math]::Abs($Value - $nearestHalf) -le 1.0e-12) {
        $Value = $nearestHalf
    }
    # Godot roundi() rounds halfway cases away from zero.
    if ($Value -ge 0.0) {
        return [int][Math]::Floor($Value + 0.5)
    }
    return [int][Math]::Ceiling($Value - 0.5)
}

function New-ExpectedRuntimeFrame {
    param(
        [object]$SourceImage,
        [int]$PixelScale,
        [int]$SourceDirection,
        [int]$TargetDirection,
        [string]$Label
    )

    if ($null -eq $SourceImage) {
        return $null
    }
    $scaledWidth = [int]$SourceImage.Width * $PixelScale
    $scaledHeight = [int]$SourceImage.Height * $PixelScale
    if (
        $PixelScale -le 0 -or
        $scaledWidth -gt $script:RuntimeFrameSize -or
        $scaledHeight -gt $script:RuntimeFrameSize
    ) {
        Add-ValidationError "$Label cannot be transformed into a 64x64 runtime frame."
        return $null
    }

    $transparentPixel = "$($script:TransparentColor)00"
    $embeddedPixels = [string[]]::new(
        $script:RuntimeFrameSize * $script:RuntimeFrameSize
    )
    [Array]::Fill($embeddedPixels, $transparentPixel)
    $offsetX = [int][Math]::Floor(
        ($script:RuntimeFrameSize - $scaledWidth) / 2.0
    )
    $offsetY = [int][Math]::Floor(
        ($script:RuntimeFrameSize - $scaledHeight) / 2.0
    )
    for ($scaledY = 0; $scaledY -lt $scaledHeight; $scaledY++) {
        $sourceY = [int][Math]::Floor($scaledY / [double]$PixelScale)
        for ($scaledX = 0; $scaledX -lt $scaledWidth; $scaledX++) {
            $sourceX = [int][Math]::Floor($scaledX / [double]$PixelScale)
            $sourceIndex = $sourceY * [int]$SourceImage.Width + $sourceX
            $targetIndex = (
                ($offsetY + $scaledY) * $script:RuntimeFrameSize +
                $offsetX +
                $scaledX
            )
            $embeddedPixels[$targetIndex] = [string]$SourceImage.Pixels[$sourceIndex]
        }
    }

    $rotationSteps = (
        ($TargetDirection - $SourceDirection) % 16 + 16
    ) % 16
    if ($rotationSteps -eq 0) {
        return [pscustomobject]@{
            Width = $script:RuntimeFrameSize
            Height = $script:RuntimeFrameSize
            Pixels = $embeddedPixels
        }
    }

    $rotatedPixels = [string[]]::new(
        $script:RuntimeFrameSize * $script:RuntimeFrameSize
    )
    [Array]::Fill($rotatedPixels, $transparentPixel)
    $angle = [double]$rotationSteps * 2.0 * [Math]::PI / 16.0
    $sine = [Math]::Sin(-$angle)
    $cosine = [Math]::Cos(-$angle)
    $center = ($script:RuntimeFrameSize - 1) / 2.0
    for ($y = 0; $y -lt $script:RuntimeFrameSize; $y++) {
        for ($x = 0; $x -lt $script:RuntimeFrameSize; $x++) {
            $deltaX = [double]$x - $center
            $deltaY = [double]$y - $center
            $sourceX = ConvertTo-GodotRoundedInteger (
                $deltaX * $cosine - $deltaY * $sine + $center
            )
            $sourceY = ConvertTo-GodotRoundedInteger (
                $deltaX * $sine + $deltaY * $cosine + $center
            )
            if (
                $sourceX -ge 0 -and
                $sourceX -lt $script:RuntimeFrameSize -and
                $sourceY -ge 0 -and
                $sourceY -lt $script:RuntimeFrameSize
            ) {
                $rotatedPixels[$y * $script:RuntimeFrameSize + $x] = (
                    $embeddedPixels[$sourceY * $script:RuntimeFrameSize + $sourceX]
                )
            }
        }
    }
    return [pscustomobject]@{
        Width = $script:RuntimeFrameSize
        Height = $script:RuntimeFrameSize
        Pixels = $rotatedPixels
    }
}

function Confirm-RuntimeFramePixelsEqual {
    param(
        [object]$Expected,
        [object]$Actual,
        [string]$Label
    )

    if ($null -eq $Expected -or $null -eq $Actual) {
        return
    }
    if (
        [int]$Expected.Width -ne [int]$Actual.Width -or
        [int]$Expected.Height -ne [int]$Actual.Height
    ) {
        Add-ValidationError "$Label must be a 64x64 transformed runtime frame."
        return
    }
    for ($index = 0; $index -lt $Expected.Pixels.Count; $index++) {
        $expectedPixel = [string]$Expected.Pixels[$index]
        $actualPixel = [string]$Actual.Pixels[$index]
        if ($expectedPixel -cne $actualPixel) {
            $x = $index % [int]$Expected.Width
            $y = [int][Math]::Floor($index / [double]$Expected.Width)
            Add-ValidationError (
                "$Label pixels differ from the approved source transform at " +
                "$x,$y (expected #$expectedPixel; actual #$actualPixel)."
            )
            return
        }
    }
}

function Confirm-FrameTransformMetadata {
    param(
        [object]$Record,
        [object]$Rule,
        [object]$SourceImage,
        [int]$TargetDirection,
        [string]$Label
    )

    if (
        -not (Test-HasProperty -Value $Record -Name "source_transform") -or
        $null -eq (Get-PropertyValue -Value $Record -Name "source_transform")
    ) {
        Add-ValidationError "$Label is missing source_transform."
        return
    }
    $transform = Get-PropertyValue -Value $Record -Name "source_transform"
    $pixelScale = [int](Get-PropertyValue -Value $Rule -Name "pixel_scale")
    $sourceDirection = [int](
        Get-PropertyValue -Value $Rule -Name "source_direction_index"
    )
    $rotationSteps = (
        ($TargetDirection - $sourceDirection) % 16 + 16
    ) % 16
    $expectedOffset = @(
        [int][Math]::Floor(
            ($script:RuntimeFrameSize - [int]$SourceImage.Width * $pixelScale) / 2.0
        ),
        [int][Math]::Floor(
            ($script:RuntimeFrameSize - [int]$SourceImage.Height * $pixelScale) / 2.0
        )
    )

    foreach ($arrayCheck in @(
        @("atlas_frame_size", @($script:RuntimeFrameSize, $script:RuntimeFrameSize)),
        @("center_offset", $expectedOffset)
    )) {
        $field = [string]$arrayCheck[0]
        $expected = @($arrayCheck[1])
        $actualValue = Get-PropertyValue -Value $transform -Name $field
        $actual = @($actualValue)
        if (
            -not (Test-HasProperty -Value $transform -Name $field) -or
            -not ($actualValue -is [System.Array]) -or
            $actual.Count -ne 2 -or
            -not (Test-JsonInteger -Value $actual[0]) -or
            -not (Test-JsonInteger -Value $actual[1]) -or
            [int64]$actual[0] -ne [int64]$expected[0] -or
            [int64]$actual[1] -ne [int64]$expected[1]
        ) {
            Add-ValidationError "$Label $field does not match the approved source transform."
        }
    }
    foreach ($scalarCheck in @(
        @("native_pixel_scale", $pixelScale),
        @("source_direction_index", $sourceDirection),
        @("target_direction_index", $TargetDirection),
        @("rotation_steps_16", $rotationSteps)
    )) {
        $field = [string]$scalarCheck[0]
        $expected = [int]$scalarCheck[1]
        $actual = Get-PropertyValue -Value $transform -Name $field
        if (
            -not (Test-HasProperty -Value $transform -Name $field) -or
            -not (Test-JsonInteger -Value $actual) -or
            [int64]$actual -ne $expected
        ) {
            Add-ValidationError "$Label $field does not match the approved source transform."
        }
    }
}

function Confirm-GeneratedFrameMaster {
    param(
        [string]$Family,
        [object]$CatalogFrame,
        [object]$Rule,
        [object]$SourceImage,
        [int]$TargetDirection,
        [string]$Key
    )

    $label = "Generated frame $Key"
    $frameId = [string](Get-PropertyValue -Value $CatalogFrame -Name "id")
    if ([string]::IsNullOrWhiteSpace($frameId)) {
        Add-ValidationError "$label catalog record is missing id."
        return
    }
    $directoryRelative = (
        "$($script:GeneratedFrameRoot)/$Family/$frameId"
    )
    try {
        $directoryPath = Resolve-RepoPath -Path $directoryRelative -RequireRepoRelative
        $frameRootPath = Resolve-RepoPath `
            -Path $script:GeneratedFrameRoot `
            -RequireRepoRelative
    } catch {
        Add-ValidationError "$label output path is invalid."
        return
    }
    $frameRootPrefix = $frameRootPath.TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    ) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $directoryPath.StartsWith(
        $frameRootPrefix,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        Add-ValidationError "$label output path escapes the generated frame root."
        return
    }

    $manifestRelative = "$directoryRelative/manifest.json"
    $manifestPath = Resolve-RepoPath -Path $manifestRelative -RequireRepoRelative
    if (-not [System.IO.File]::Exists($manifestPath)) {
        Add-ValidationError "$label manifest does not exist: $manifestRelative"
        return
    }
    try {
        $frameManifest = Read-JsonDocument `
            -Path $manifestPath `
            -Label "$label manifest"
    } catch {
        Add-ValidationError $_.Exception.Message
        return
    }
    if (
        -not (Test-HasProperty -Value $frameManifest -Name "frame_key") -or
        [string](Get-PropertyValue -Value $frameManifest -Name "frame_key") -cne $Key
    ) {
        Add-ValidationError "$label manifest frame_key does not match the catalog."
    }
    Confirm-Provenance `
        -Actual $frameManifest `
        -Expected $Rule `
        -Label "$label manifest"
    Confirm-FrameTransformMetadata `
        -Record $CatalogFrame `
        -Rule $Rule `
        -SourceImage $SourceImage `
        -TargetDirection $TargetDirection `
        -Label "$label catalog"
    Confirm-FrameTransformMetadata `
        -Record $frameManifest `
        -Rule $Rule `
        -SourceImage $SourceImage `
        -TargetDirection $TargetDirection `
        -Label "$label manifest"

    $masterRelative = "$directoryRelative/master.png"
    if (
        -not (Test-HasProperty -Value $frameManifest -Name "master_path") -or
        -not (Test-ResolvedPathMatch `
            -Actual ([string](
                Get-PropertyValue -Value $frameManifest -Name "master_path"
            )) `
            -Expected $masterRelative
        )
    ) {
        Add-ValidationError "$label manifest master_path does not match $masterRelative."
    }
    $manifestHash = [string](
        Get-PropertyValue -Value $frameManifest -Name "source_sha256"
    )
    $catalogHash = [string](
        Get-PropertyValue -Value $CatalogFrame -Name "source_sha256"
    )
    if (
        -not (Test-Sha256 -Value $manifestHash) -or
        -not (Test-Sha256 -Value $catalogHash) -or
        -not [string]::Equals(
            $manifestHash,
            $catalogHash,
            [System.StringComparison]::OrdinalIgnoreCase
        )
    ) {
        Add-ValidationError "$label source_sha256 differs between its manifest and catalog."
    }
    $masterPath = Confirm-FileHash `
        -DeclaredPath $masterRelative `
        -ExpectedHash $manifestHash `
        -Label "$label master"
    if ($null -eq $masterPath) {
        return
    }
    $masterImage = Get-ImagePixels -ImagePath $masterPath -Label "$label master"
    Confirm-ImagePolicy `
        -Image $masterImage `
        -Label "$label master" `
        -ExpectedSize @($script:RuntimeFrameSize, $script:RuntimeFrameSize) `
        -RequireOpaque $false `
        -RequireRepeatSafe $false
    $expectedFrame = New-ExpectedRuntimeFrame `
        -SourceImage $SourceImage `
        -PixelScale ([int](Get-PropertyValue -Value $Rule -Name "pixel_scale")) `
        -SourceDirection ([int](
            Get-PropertyValue -Value $Rule -Name "source_direction_index"
        )) `
        -TargetDirection $TargetDirection `
        -Label $label
    Confirm-RuntimeFramePixelsEqual `
        -Expected $expectedFrame `
        -Actual $masterImage `
        -Label "$label master"
}

function Get-LogicalSize {
    param(
        [object]$Record,
        [string]$Label
    )

    if (
        -not (Test-HasProperty -Value $Record -Name "logical_size") -or
        -not ($Record.logical_size -is [System.Array])
    ) {
        Add-ValidationError "$Label logical_size must be an array."
        return @()
    }
    $size = @($Record.logical_size)
    if (
        $size.Count -ne 2 -or
        -not (Test-JsonInteger -Value $size[0]) -or
        -not (Test-JsonInteger -Value $size[1]) -or
        [int64]$size[0] -le 0 -or
        [int64]$size[1] -le 0 -or
        [int64]$size[0] -gt [int]::MaxValue -or
        [int64]$size[1] -gt [int]::MaxValue
    ) {
        Add-ValidationError "$Label logical_size must contain two positive integers."
        return @()
    }
    return @([int]$size[0], [int]$size[1])
}

function Confirm-RawImageReadable {
    param(
        [string]$ImagePath,
        [string]$Label
    )

    if ($null -eq $ImagePath) {
        return
    }
    $identifyOutput = @(
        & $script:Magick.Source identify -quiet -format "%w %h" $ImagePath 2>&1
    )
    $dimensions = (($identifyOutput | ForEach-Object { [string]$_ }) -join "").Trim()
    if (
        $LASTEXITCODE -ne 0 -or
        $dimensions -notmatch "^\d+ \d+$"
    ) {
        Add-ValidationError "$Label is not a readable image according to ImageMagick."
    }
}

function Confirm-SourceRecord {
    param(
        [object]$Record,
        [string]$Label,
        [bool]$RequireOpaque,
        [bool]$RequireRepeatSafe
    )

    foreach ($field in @(
        "source_path",
        "source_sha256",
        "raw_source_path",
        "raw_source_sha256",
        "prompt_path",
        "prompt_sha256",
        "logical_size",
        "production_method"
    )) {
        if (-not (Test-HasProperty -Value $Record -Name $field)) {
            Add-ValidationError "$Label is missing '$field'."
        }
    }
    if ([string](Get-PropertyValue -Value $Record -Name "production_method") -ne "imagegen_assisted") {
        Add-ValidationError "$Label must use production_method=imagegen_assisted."
    }
    if ($RequireRepeatSafe) {
        if (
            -not (Test-HasProperty -Value $Record -Name "repeat_safe") -or
            -not ((Get-PropertyValue -Value $Record -Name "repeat_safe") -is [bool]) -or
            -not [bool](Get-PropertyValue -Value $Record -Name "repeat_safe")
        ) {
            Add-ValidationError "$Label must declare repeat_safe=true."
        }
    }

    $logicalSize = @(Get-LogicalSize -Record $Record -Label $Label)
    $approvedPath = Confirm-FileHash `
        -DeclaredPath ([string](Get-PropertyValue -Value $Record -Name "source_path")) `
        -ExpectedHash ([string](Get-PropertyValue -Value $Record -Name "source_sha256")) `
        -Label "$Label approved source"
    $rawPath = Confirm-FileHash `
        -DeclaredPath ([string](Get-PropertyValue -Value $Record -Name "raw_source_path")) `
        -ExpectedHash ([string](Get-PropertyValue -Value $Record -Name "raw_source_sha256")) `
        -Label "$Label raw ImageGen source"
    Confirm-FileHash `
        -DeclaredPath ([string](Get-PropertyValue -Value $Record -Name "prompt_path")) `
        -ExpectedHash ([string](Get-PropertyValue -Value $Record -Name "prompt_sha256")) `
        -Label "$Label prompt" | Out-Null
    Confirm-RawImageReadable -ImagePath $rawPath -Label "$Label raw ImageGen source"

    $approvedImage = $null
    if ($null -ne $approvedPath) {
        $approvedImage = Get-ImagePixels -ImagePath $approvedPath -Label "$Label approved source"
        Confirm-ImagePolicy `
            -Image $approvedImage `
            -Label "$Label approved source" `
            -ExpectedSize $logicalSize `
            -RequireOpaque $RequireOpaque `
            -RequireRepeatSafe $RequireRepeatSafe
    }
    return [pscustomobject]@{
        LogicalSize = $logicalSize
        ApprovedPath = $approvedPath
        ApprovedImage = $approvedImage
    }
}

function Test-ResolvedPathMatch {
    param(
        [string]$Actual,
        [string]$Expected
    )

    try {
        $actualPath = Resolve-RepoPath -Path $Actual -RequireRepoRelative
        $expectedPath = Resolve-RepoPath -Path $Expected
        return [string]::Equals(
            $actualPath,
            $expectedPath,
            [System.StringComparison]::OrdinalIgnoreCase
        )
    } catch {
        return $false
    }
}

function Confirm-Provenance {
    param(
        [object]$Actual,
        [object]$Expected,
        [string]$Label
    )

    if ([string](Get-PropertyValue -Value $Actual -Name "production_method") -ne "imagegen_assisted") {
        Add-ValidationError "$Label production_method does not match imagegen_assisted."
    }
    foreach ($mapping in @(
        @("approved_source_path", "source_path"),
        @("raw_source_path", "raw_source_path"),
        @("prompt_path", "prompt_path")
    )) {
        $actualField = [string]$mapping[0]
        $expectedField = [string]$mapping[1]
        if (
            -not (Test-HasProperty -Value $Actual -Name $actualField) -or
            -not (Test-ResolvedPathMatch `
                -Actual ([string](Get-PropertyValue -Value $Actual -Name $actualField)) `
                -Expected ([string](Get-PropertyValue -Value $Expected -Name $expectedField))
            )
        ) {
            Add-ValidationError "$Label $actualField does not match the override manifest."
        }
    }
    foreach ($mapping in @(
        @("approved_source_sha256", "source_sha256"),
        @("raw_source_sha256", "raw_source_sha256"),
        @("prompt_sha256", "prompt_sha256")
    )) {
        $actualField = [string]$mapping[0]
        $expectedField = [string]$mapping[1]
        if (
            -not (Test-HasProperty -Value $Actual -Name $actualField) -or
            -not [string]::Equals(
                [string](Get-PropertyValue -Value $Actual -Name $actualField),
                [string](Get-PropertyValue -Value $Expected -Name $expectedField),
                [System.StringComparison]::OrdinalIgnoreCase
            )
        ) {
            Add-ValidationError "$Label $actualField does not match the override manifest."
        }
    }
}

function Confirm-Catalog {
    param(
        [object]$Catalog,
        [string]$CatalogFile,
        [object]$Manifest,
        [string]$ManifestFile,
        [System.Collections.Generic.Dictionary[string, object]]$ExpandedFrames,
        [System.Collections.Generic.Dictionary[string, object]]$FrameTransforms,
        [System.Collections.Generic.Dictionary[string, object]]$RepeatSources
    )

    if (-not (Test-HasProperty -Value $Catalog -Name "source_overrides")) {
        Add-ValidationError "Catalog does not declare source_overrides: $CatalogFile"
        return
    }
    $summary = $Catalog.source_overrides
    if (
        -not (Test-HasProperty -Value $summary -Name "manifest_path") -or
        -not (Test-ResolvedPathMatch `
            -Actual ([string]$summary.manifest_path) `
            -Expected $ManifestFile
        )
    ) {
        Add-ValidationError "Catalog source_overrides.manifest_path does not match the validated manifest."
    }
    $manifestHash = (Get-FileHash -LiteralPath $ManifestFile -Algorithm SHA256).Hash
    if (
        -not (Test-HasProperty -Value $summary -Name "manifest_sha256") -or
        -not [string]::Equals(
            [string]$summary.manifest_sha256,
            $manifestHash,
            [System.StringComparison]::OrdinalIgnoreCase
        )
    ) {
        Add-ValidationError "Catalog source_overrides.manifest_sha256 does not match the manifest file."
    }
    if (
        -not (Test-HasProperty -Value $summary -Name "generation_board_id") -or
        [string](Get-PropertyValue -Value $summary -Name "generation_board_id") -ne
        [string](Get-PropertyValue -Value $Manifest -Name "generation_board_id")
    ) {
        Add-ValidationError "Catalog source_overrides.generation_board_id does not match the manifest."
    }
    if (
        -not (Test-HasProperty -Value $summary -Name "frame_override_count") -or
        -not (Test-JsonInteger -Value $summary.frame_override_count) -or
        [int64]$summary.frame_override_count -ne $ExpandedFrames.Count
    ) {
        Add-ValidationError (
            "Catalog source_overrides.frame_override_count does not match the expanded frame rules."
        )
    }
    if (
        -not (Test-HasProperty -Value $summary -Name "repeat_tile_override_count") -or
        -not (Test-JsonInteger -Value $summary.repeat_tile_override_count) -or
        [int64]$summary.repeat_tile_override_count -ne $script:ExpectedRepeatKeys.Count
    ) {
        Add-ValidationError (
            "Catalog source_overrides.repeat_tile_override_count must be " +
            "$($script:ExpectedRepeatKeys.Count)."
        )
    }

    $runtimeFrames = [System.Collections.Generic.Dictionary[string, object]]::new(
        [System.StringComparer]::Ordinal
    )
    $runtimeFrameFamilies = [System.Collections.Generic.Dictionary[string, string]]::new(
        [System.StringComparer]::Ordinal
    )
    if (
        -not (Test-HasProperty -Value $Catalog -Name "assets") -or
        -not ($Catalog.assets -is [System.Array])
    ) {
        Add-ValidationError "Catalog assets must be an array."
    } else {
        foreach ($asset in @($Catalog.assets)) {
            $family = [string](Get-PropertyValue -Value $asset -Name "id")
            foreach ($frame in @((Get-PropertyValue -Value $asset -Name "frames"))) {
                $key = [string](Get-PropertyValue -Value $frame -Name "key")
                $productionMethod = [string](
                    Get-PropertyValue -Value $frame -Name "production_method"
                )
                $generatorPath = [string](
                    Get-PropertyValue -Value $frame -Name "generator_path"
                )
                $approvedSourcePath = [string](
                    Get-PropertyValue -Value $frame -Name "approved_source_path"
                )
                if (
                    $productionMethod -eq "imagegen_assisted" -and
                    -not [string]::IsNullOrWhiteSpace($generatorPath) -and
                    [string]::IsNullOrWhiteSpace($approvedSourcePath)
                ) {
                    $frameLabel = if ([string]::IsNullOrWhiteSpace($key)) {
                        "<missing frame key>"
                    } else {
                        $key
                    }
                    Add-ValidationError (
                        "$frameLabel is procedurally generated but labeled " +
                        "imagegen_assisted without approved_source_path."
                    )
                }
                if ([string]::IsNullOrWhiteSpace($key)) {
                    continue
                }
                if ($runtimeFrames.ContainsKey($key)) {
                    Add-ValidationError "Catalog contains duplicate frame key while checking overrides: $key"
                } else {
                    $runtimeFrames[$key] = $frame
                    $runtimeFrameFamilies[$key] = $family
                }
                $directionIndex = Get-PropertyValue -Value $frame -Name "direction_index"
                $sequenceIndex = Get-PropertyValue -Value $frame -Name "sequence_index"
                if (
                    -not [string]::IsNullOrWhiteSpace($family) -and
                    (Test-JsonInteger -Value $directionIndex) -and
                    (Test-JsonInteger -Value $sequenceIndex)
                ) {
                    $computedKey = "{0}/{1}/{2}/{3}/{4}" -f @(
                        $family,
                        [string](Get-PropertyValue -Value $frame -Name "variant"),
                        [int64]$directionIndex,
                        [string](Get-PropertyValue -Value $frame -Name "state"),
                        [int64]$sequenceIndex
                    )
                    if ($computedKey -cne $key) {
                        Add-ValidationError "Catalog frame key does not match its exact frame fields: $key"
                    }
                }
            }
        }
    }
    foreach ($entry in $ExpandedFrames.GetEnumerator()) {
        $key = [string]$entry.Key
        if (-not $runtimeFrames.ContainsKey($key)) {
            Add-ValidationError "Catalog is missing expanded frame override: $key"
            continue
        }
        Confirm-Provenance `
            -Actual $runtimeFrames[$key] `
            -Expected $entry.Value `
            -Label "Catalog frame $key"
        if (-not $FrameTransforms.ContainsKey($key)) {
            Add-ValidationError "Validated transform inputs are missing for frame override: $key"
            continue
        }
        $transform = $FrameTransforms[$key]
        Confirm-GeneratedFrameMaster `
            -Family $runtimeFrameFamilies[$key] `
            -CatalogFrame $runtimeFrames[$key] `
            -Rule $entry.Value `
            -SourceImage $transform.SourceImage `
            -TargetDirection ([int]$transform.TargetDirection) `
            -Key $key
    }

    $runtimeRepeats = [System.Collections.Generic.Dictionary[string, object]]::new(
        [System.StringComparer]::Ordinal
    )
    if (
        -not (Test-HasProperty -Value $Catalog -Name "runtime_repeat_tiles") -or
        -not ($Catalog.runtime_repeat_tiles -is [System.Array])
    ) {
        Add-ValidationError "Catalog runtime_repeat_tiles must be an array."
    } else {
        foreach ($record in @($Catalog.runtime_repeat_tiles)) {
            $runtimeKey = [string](Get-PropertyValue -Value $record -Name "runtime_key")
            if (-not (Test-ContainsOrdinal -Values $script:ExpectedRepeatKeys -Expected $runtimeKey)) {
                Add-ValidationError "Catalog contains unknown runtime repeat tile: $runtimeKey"
                continue
            }
            if ($runtimeRepeats.ContainsKey($runtimeKey)) {
                Add-ValidationError "Catalog contains duplicate runtime repeat tile: $runtimeKey"
            } else {
                $runtimeRepeats[$runtimeKey] = $record
            }
        }
    }
    if ($runtimeRepeats.Count -ne $script:ExpectedRepeatKeys.Count) {
        Add-ValidationError (
            "Catalog must publish exactly $($script:ExpectedRepeatKeys.Count) runtime repeat tiles."
        )
    }

    foreach ($runtimeKey in $script:ExpectedRepeatKeys) {
        if (-not $runtimeRepeats.ContainsKey($runtimeKey)) {
            Add-ValidationError "Catalog is missing runtime repeat tile: $runtimeKey"
            continue
        }
        $record = $runtimeRepeats[$runtimeKey]
        $repeatTileObject = Get-PropertyValue -Value $Manifest -Name "repeat_tiles"
        $expectedRule = Get-PropertyValue -Value $repeatTileObject -Name $runtimeKey
        if ($null -eq $expectedRule) {
            continue
        }
        Confirm-Provenance `
            -Actual $record `
            -Expected $expectedRule `
            -Label "Runtime repeat tile $runtimeKey"
        if (
            -not (Test-HasProperty -Value $record -Name "repeat_safe") -or
            -not ((Get-PropertyValue -Value $record -Name "repeat_safe") -is [bool]) -or
            -not [bool](Get-PropertyValue -Value $record -Name "repeat_safe")
        ) {
            Add-ValidationError "Runtime repeat tile $runtimeKey must declare repeat_safe=true."
        }
        $logicalSize = @(Get-LogicalSize -Record $expectedRule -Label "repeat tile $runtimeKey")
        $recordSize = @((Get-PropertyValue -Value $record -Name "size"))
        if (
            -not (Test-HasProperty -Value $record -Name "size") -or
            -not ((Get-PropertyValue -Value $record -Name "size") -is [System.Array]) -or
            $recordSize.Count -ne 2 -or
            -not (Test-JsonInteger -Value $recordSize[0]) -or
            -not (Test-JsonInteger -Value $recordSize[1]) -or
            $logicalSize.Count -ne 2 -or
            [int64]$recordSize[0] -ne $logicalSize[0] -or
            [int64]$recordSize[1] -ne $logicalSize[1]
        ) {
            Add-ValidationError "Runtime repeat tile $runtimeKey size does not match logical_size."
        }

        $expectedOutput = $script:ExpectedRepeatOutputs[$runtimeKey]
        if (
            -not (Test-HasProperty -Value $record -Name "output_path") -or
            -not (Test-ResolvedPathMatch `
                -Actual ([string](Get-PropertyValue -Value $record -Name "output_path")) `
                -Expected $expectedOutput
            )
        ) {
            Add-ValidationError (
                "Runtime repeat tile $runtimeKey output_path must resolve to $expectedOutput."
            )
        }
        $outputPath = Confirm-FileHash `
            -DeclaredPath ([string](Get-PropertyValue -Value $record -Name "output_path")) `
            -ExpectedHash ([string](Get-PropertyValue -Value $record -Name "output_sha256")) `
            -Label "Runtime repeat tile $runtimeKey output"
        if ($null -eq $outputPath) {
            continue
        }
        $outputImage = Get-ImagePixels `
            -ImagePath $outputPath `
            -Label "Runtime repeat tile $runtimeKey output"
        Confirm-ImagePolicy `
            -Image $outputImage `
            -Label "Runtime repeat tile $runtimeKey output" `
            -ExpectedSize $logicalSize `
            -RequireOpaque $true `
            -RequireRepeatSafe $true
        Confirm-ImagesEqual `
            -Expected $RepeatSources[$runtimeKey].ApprovedImage `
            -Actual $outputImage `
            -Label "Runtime repeat tile $runtimeKey output"
    }
}

$script:WorkspaceRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$script:RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $script:WorkspaceRoot ".."))
$script:Errors = [System.Collections.Generic.List[string]]::new()
$script:ExpectedRepeatKeys = [string[]]@(
    "hangar_floor",
    "hangar_wall",
    "hangar_water"
)
$script:ExpectedRepeatOutputs = @{
    hangar_floor = "pixel-art-production/runtime/tiles/hangar-floor.png"
    hangar_wall = "pixel-art-production/runtime/tiles/hangar-wall.png"
    hangar_water = "pixel-art-production/runtime/tiles/hangar-water.png"
}
$script:GeneratedFrameRoot = (
    "pixel-art-production/assets/generated/approved/complete/frames"
)
$script:RuntimeFrameSize = 64
$script:Magick = Get-Command magick -ErrorAction Stop
$script:AllowedPalette = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase
)

$paletteFile = Resolve-RepoPath `
    -Path "pixel-art-production/assets/palettes/pixel-hangar-v1.json"
$palette = Read-JsonDocument -Path $paletteFile -Label "Pixel palette"
$transparentColor = [string](
    Get-PropertyValue -Value $palette -Name "transparent_color"
)
if ($transparentColor -notmatch "^#[0-9A-Fa-f]{6}$") {
    throw "Pixel palette transparent_color is invalid: $paletteFile"
}
$script:TransparentColor = $transparentColor.Substring(1).ToUpperInvariant()
foreach ($color in @($palette.colors.PSObject.Properties | ForEach-Object { [string]$_.Value })) {
    if ($color -match "^#[0-9A-Fa-f]{6}$") {
        $script:AllowedPalette.Add($color.Substring(1)) | Out-Null
    }
}
if ($script:AllowedPalette.Count -eq 0) {
    throw "Pixel palette contains no valid visible colors: $paletteFile"
}

$manifestFile = Resolve-RepoPath -Path $ManifestPath
$manifest = Read-JsonDocument `
    -Path $manifestFile `
    -Label "Pixel source override manifest"
if (
    -not (Test-HasProperty -Value $manifest -Name "schema_version") -or
    -not (Test-JsonInteger -Value $manifest.schema_version) -or
    [int64]$manifest.schema_version -ne 1
) {
    Add-ValidationError "Pixel source override schema_version must be 1."
}
if (
    -not (Test-HasProperty -Value $manifest -Name "generation_board_id") -or
    [string]::IsNullOrWhiteSpace([string]$manifest.generation_board_id)
) {
    Add-ValidationError "Pixel source override generation_board_id must be non-empty."
}

$expandedFrames = [System.Collections.Generic.Dictionary[string, object]]::new(
    [System.StringComparer]::Ordinal
)
$frameTransforms = [System.Collections.Generic.Dictionary[string, object]]::new(
    [System.StringComparer]::Ordinal
)
if (
    -not (Test-HasProperty -Value $manifest -Name "frame_rules") -or
    -not ($manifest.frame_rules -is [System.Array])
) {
    Add-ValidationError "Pixel source override frame_rules must be an array."
} else {
    $ruleIndex = 0
    foreach ($rule in @($manifest.frame_rules)) {
        $label = "frame rule[$ruleIndex]"
        foreach ($field in @(
            "family",
            "variant",
            "states",
            "directions",
            "sequence_indices",
            "pixel_scale",
            "source_direction_index"
        )) {
            if (-not (Test-HasProperty -Value $rule -Name $field)) {
                Add-ValidationError "$label is missing '$field'."
            }
        }
        $family = [string](Get-PropertyValue -Value $rule -Name "family")
        $variant = [string](Get-PropertyValue -Value $rule -Name "variant")
        $statesValue = Get-PropertyValue -Value $rule -Name "states"
        $directionsValue = Get-PropertyValue -Value $rule -Name "directions"
        $sequencesValue = Get-PropertyValue -Value $rule -Name "sequence_indices"
        $pixelScale = Get-PropertyValue -Value $rule -Name "pixel_scale"
        $sourceDirection = Get-PropertyValue -Value $rule -Name "source_direction_index"
        if ([string]::IsNullOrWhiteSpace($family)) {
            Add-ValidationError "$label family must be non-empty."
        }
        if ([string]::IsNullOrWhiteSpace($variant)) {
            Add-ValidationError "$label variant must be non-empty."
        }
        foreach ($arrayField in @("states", "directions", "sequence_indices")) {
            $arrayValue = Get-PropertyValue -Value $rule -Name $arrayField
            if (
                $null -eq $arrayValue -or
                -not ($arrayValue -is [System.Array]) -or
                @($arrayValue).Count -eq 0
            ) {
                Add-ValidationError "$label $arrayField must be a non-empty array."
            }
        }
        if (
            -not (Test-JsonInteger -Value $pixelScale) -or
            [int64]$pixelScale -le 0
        ) {
            Add-ValidationError "$label pixel_scale must be a positive integer."
        }
        if (
            -not (Test-JsonInteger -Value $sourceDirection) -or
            [int64]$sourceDirection -lt 0 -or
            [int64]$sourceDirection -gt 15
        ) {
            Add-ValidationError "$label source_direction_index must be an integer from 0 through 15."
        }

        $source = Confirm-SourceRecord `
            -Record $rule `
            -Label $label `
            -RequireOpaque $false `
            -RequireRepeatSafe $false
        if (
            $source.LogicalSize.Count -eq 2 -and
            (Test-JsonInteger -Value $pixelScale) -and
            [int64]$pixelScale -gt 0 -and
            (
                $source.LogicalSize[0] * [int64]$pixelScale -gt 64 -or
                $source.LogicalSize[1] * [int64]$pixelScale -gt 64
            )
        ) {
            Add-ValidationError "$label exceeds the 64x64 runtime frame after pixel_scale."
        }

        $states = @($statesValue)
        $directions = @($directionsValue)
        $sequences = @($sequencesValue)
        foreach ($state in $states) {
            if ([string]::IsNullOrWhiteSpace([string]$state)) {
                Add-ValidationError "$label states must contain non-empty strings."
                continue
            }
            foreach ($direction in $directions) {
                if (
                    -not (Test-JsonInteger -Value $direction) -or
                    [int64]$direction -lt 0 -or
                    [int64]$direction -gt 15
                ) {
                    Add-ValidationError "$label directions must contain integers from 0 through 15."
                    continue
                }
                foreach ($sequence in $sequences) {
                    if (
                        -not (Test-JsonInteger -Value $sequence) -or
                        [int64]$sequence -lt 0
                    ) {
                        Add-ValidationError "$label sequence_indices must contain non-negative integers."
                        continue
                    }
                    $key = "{0}/{1}/{2}/{3}/{4}" -f @(
                        $family,
                        $variant,
                        [int64]$direction,
                        [string]$state,
                        [int64]$sequence
                    )
                    if ($expandedFrames.ContainsKey($key)) {
                        Add-ValidationError "Duplicate expanded frame override key: $key"
                    } else {
                        $expandedFrames[$key] = $rule
                        $frameTransforms[$key] = [pscustomobject]@{
                            SourceImage = $source.ApprovedImage
                            TargetDirection = [int]$direction
                        }
                    }
                }
            }
        }
        $ruleIndex++
    }
}

$repeatSources = [System.Collections.Generic.Dictionary[string, object]]::new(
    [System.StringComparer]::Ordinal
)
if (
    -not (Test-HasProperty -Value $manifest -Name "repeat_tiles") -or
    $null -eq $manifest.repeat_tiles -or
    $manifest.repeat_tiles -is [System.Array]
) {
    Add-ValidationError "Pixel source override repeat_tiles must be an object."
} else {
    $actualRepeatKeys = [string[]]@(
        $manifest.repeat_tiles.PSObject.Properties | ForEach-Object { [string]$_.Name }
    )
    foreach ($expectedKey in $script:ExpectedRepeatKeys) {
        if (-not (Test-ContainsOrdinal -Values $actualRepeatKeys -Expected $expectedKey)) {
            Add-ValidationError "Pixel source override is missing repeat tile: $expectedKey"
        }
    }
    foreach ($actualKey in $actualRepeatKeys) {
        if (-not (Test-ContainsOrdinal -Values $script:ExpectedRepeatKeys -Expected $actualKey)) {
            Add-ValidationError "Pixel source override contains unexpected repeat tile: $actualKey"
        }
    }
    foreach ($runtimeKey in $script:ExpectedRepeatKeys) {
        if (-not (Test-ContainsOrdinal -Values $actualRepeatKeys -Expected $runtimeKey)) {
            continue
        }
        $repeatSources[$runtimeKey] = Confirm-SourceRecord `
            -Record (Get-PropertyValue -Value $manifest.repeat_tiles -Name $runtimeKey) `
            -Label "repeat tile $runtimeKey" `
            -RequireOpaque $true `
            -RequireRepeatSafe $true
    }
}

if (-not [string]::IsNullOrWhiteSpace($CatalogPath)) {
    $catalogFile = Resolve-RepoPath -Path $CatalogPath
    $catalog = Read-JsonDocument -Path $catalogFile -Label "Pixel asset catalog"
    Confirm-Catalog `
        -Catalog $catalog `
        -CatalogFile $catalogFile `
        -Manifest $manifest `
        -ManifestFile $manifestFile `
        -ExpandedFrames $expandedFrames `
        -FrameTransforms $frameTransforms `
        -RepeatSources $repeatSources
}

if ($script:Errors.Count -gt 0) {
    throw (
        "Pixel source override validation failed:`n" +
        (($script:Errors | ForEach-Object { "- $_" }) -join "`n")
    )
}
$catalogSummary = if ([string]::IsNullOrWhiteSpace($CatalogPath)) {
    "manifest only"
} else {
    "catalog verified"
}
Write-Output (
    "Pixel source overrides valid: frames=$($expandedFrames.Count); " +
    "repeat_tiles=$($repeatSources.Count); $catalogSummary"
)
