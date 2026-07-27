param(
    [string]$PolicyPath = "pixel-art-production/assets/pixel-import-policy.json",
    [string[]]$RuntimeTexturePaths = @()
)

$ErrorActionPreference = "Stop"
$workspaceRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $workspaceRoot ".."))
$policyFile = if ([System.IO.Path]::IsPathRooted($PolicyPath)) {
    [System.IO.Path]::GetFullPath($PolicyPath)
} else {
    [System.IO.Path]::GetFullPath((Join-Path $repoRoot $PolicyPath))
}
if (-not [System.IO.File]::Exists($policyFile)) {
    throw "Pixel import policy does not exist: $PolicyPath"
}
$policy = Get-Content -LiteralPath $policyFile -Raw | ConvertFrom-Json
$errors = [System.Collections.Generic.List[string]]::new()

if ([int]$policy.schema_version -ne 1) { $errors.Add("schema_version must be 1") }
if ([string]$policy.texture_filter -ne "nearest") { $errors.Add("texture_filter must be nearest") }
if ([bool]$policy.mipmaps) { $errors.Add("mipmaps must be false") }
if ([bool]$policy.repeat) { $errors.Add("repeat must be false") }
if (-not [bool]$policy.lossless) { $errors.Add("lossless must be true") }
if (-not [bool]$policy.integer_scale) { $errors.Add("integer_scale must be true") }
if ([int]$policy.atlas_padding -ne 2) { $errors.Add("atlas_padding must be 2") }
if ([int]$policy.atlas_extrude -ne 1) { $errors.Add("atlas_extrude must be 1") }
$owner = [System.IO.Path]::GetFullPath((Join-Path $repoRoot ([string]$policy.runtime_owner)))
if (-not [System.IO.File]::Exists($owner)) { $errors.Add("runtime_owner does not exist") }

foreach ($texturePath in $RuntimeTexturePaths) {
    $texture = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $texturePath))
    $importFile = "$texture.import"
    if (-not [System.IO.File]::Exists($texture)) {
        $errors.Add("runtime texture does not exist: $texturePath")
        continue
    }
    if (-not [System.IO.File]::Exists($importFile)) {
        $errors.Add("runtime texture has no Godot import metadata: $texturePath")
        continue
    }
    $importText = Get-Content -LiteralPath $importFile -Raw
    foreach ($required in @(
        'importer="texture"',
        "compress/mode=0",
        "mipmaps/generate=false",
        "process/size_limit=0"
    )) {
        if ($importText -notmatch [regex]::Escape($required)) {
            $errors.Add("$texturePath import metadata is missing: $required")
        }
    }
}

if ($errors.Count -gt 0) {
    throw "Pixel import settings validation failed:`n$(($errors | ForEach-Object { "- $_" }) -join "`n")"
}
Write-Output "Pixel import policy valid: nearest, lossless, no mipmaps, no repeat, integer scale."
Write-Output "Imported runtime textures checked: $($RuntimeTexturePaths.Count)"
