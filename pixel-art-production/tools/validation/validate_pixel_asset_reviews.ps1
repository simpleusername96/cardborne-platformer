param(
    [Parameter(Mandatory = $true)]
    [string[]]$ReviewMetadataPaths
)

$ErrorActionPreference = "Stop"
$workspaceRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $workspaceRoot ".."))
$requiredKinds = @("native_1x", "enlarged_with_pivot", "silhouette", "grayscale")
$errors = [System.Collections.Generic.List[string]]::new()
$reviewCount = 0

foreach ($relativePath in $ReviewMetadataPaths) {
    $metadataFile = if ([System.IO.Path]::IsPathRooted($relativePath)) {
        [System.IO.Path]::GetFullPath($relativePath)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot $relativePath))
    }
    if (-not [System.IO.File]::Exists($metadataFile)) {
        $errors.Add("review metadata does not exist: $relativePath")
        continue
    }
    $review = Get-Content -LiteralPath $metadataFile -Raw | ConvertFrom-Json
    $reviewImage = if ([System.IO.Path]::IsPathRooted([string]$review.review_path)) {
        [System.IO.Path]::GetFullPath([string]$review.review_path)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot ([string]$review.review_path)))
    }
    if (-not [System.IO.File]::Exists($reviewImage)) {
        $errors.Add("review image does not exist: $($review.review_path)")
        continue
    }
    if ([int]$review.schema_version -ne 1) { $errors.Add("$relativePath schema_version must be 1") }
    if ([string]$review.approval_status -eq "approved") {
        $errors.Add("$relativePath is fixture evidence and may not approve production art")
    }
    if (@($review.backgrounds).Count -lt 2) {
        $errors.Add("$relativePath must test at least two world backgrounds")
    }
    foreach ($frame in @($review.frames)) {
        $reviewCount++
        if ([string]$frame.source_sha256 -notmatch "^[0-9a-f]{64}$") {
            $errors.Add("$($frame.id) has invalid source checksum")
        }
        $kinds = @($frame.panels | ForEach-Object { [string]$_.kind })
        foreach ($kind in $requiredKinds) {
            if ($kind -notin $kinds) { $errors.Add("$($frame.id) review is missing $kind") }
        }
        foreach ($background in @($review.backgrounds)) {
            if ("background_$background" -notin $kinds) {
                $errors.Add("$($frame.id) review is missing background_$background")
            }
        }
    }
}
if ($errors.Count -gt 0) {
    throw "Pixel asset review validation failed:`n$(($errors | ForEach-Object { "- $_" }) -join "`n")"
}
Write-Output "Pixel asset reviews valid: files=$($ReviewMetadataPaths.Count); frames=$reviewCount"
