[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$designRoot = Join-Path $repoRoot 'tools\design'
Import-Module (Join-Path $designRoot 'visual_replacement_workbench_model.psm1') -Force
$workbenchRoot = Join-Path $repoRoot 'docs\design\visual-replacement-workbench'
$sourcePath = Join-Path $workbenchRoot 'replacement-workbench.json'
$inventoryPath = Join-Path $workbenchRoot 'inventory.json'
$indexPath = Join-Path $workbenchRoot 'index.html'
$templatePath = Join-Path $workbenchRoot 'index-template.html'
$failures = [Collections.Generic.List[string]]::new()
function Expect([bool]$Condition,[string]$Message){if(-not $Condition){$failures.Add($Message)}}

try { & (Join-Path $designRoot 'build_visual_replacement_workbench.ps1') -Check } catch { $failures.Add($_.Exception.Message) }
foreach($path in @($sourcePath,$inventoryPath,$indexPath,$templatePath)){Expect (Test-Path -LiteralPath $path -PathType Leaf) "missing workbench file: $path"}
if($failures.Count){$failures|ForEach-Object{Write-Error $_};exit 1}

try {
    $source=Get-Content $sourcePath -Raw|ConvertFrom-Json -Depth 100
    $expected=Get-VisualReplacementProjection -RepoRoot $repoRoot -Source $source
    $inventoryText=(Get-Content $inventoryPath -Raw).Replace("`r`n","`n").TrimEnd("`n")
    $actual=$inventoryText|ConvertFrom-Json -Depth 100
    Expect ((Get-VisualCanonicalJson $expected) -ceq (Get-VisualCanonicalJson $actual)) 'inventory.json projection mismatch'
    Expect ($actual.summary.gameplay_png -eq 247) 'Phase 2 gameplay PNG count must be 247'
    Expect ($actual.summary.ui_png -eq 57) 'Phase 2 UI PNG count must be 57'
    Expect ($actual.summary.font -eq 1) 'production font count must be 1'
    Expect ($actual.summary.units -eq 48) 'switch unit count must be 48'
    Expect ($actual.summary.retire_only -eq 3) 'retire-only count must be 3'
    Expect (@($actual.units|Where-Object status -notin @('keep_current','target_required')).Count -eq 0) 'Phase 2 source contains a premature workflow state'
    foreach($unit in $actual.units){
        Expect (-not [string]::IsNullOrWhiteSpace([string]$unit.title_en)) "missing English title: $($unit.id)"
        Expect ([string]$unit.title_ko -match '[가-힣]') "missing Korean title: $($unit.id)"
        foreach($file in $unit.current_files){Expect ([string]$file.path -like 'art/visuals/production/*') "AS-IS is not direct production media: $($unit.id) -> $($file.path)"}
        foreach($deliverable in $unit.deliverables){Expect (([string]$deliverable.workbench_path) -ceq "docs/design/visual-replacement-workbench/to-be/assets/$($deliverable.target_path)") "TO-BE mapping mismatch: $($unit.id) -> $($deliverable.target_path)"}
        foreach($preview in $unit.preview_paths){Expect ([string]$preview -like 'docs/design/visual-replacement-workbench/previews/*') "preview path is not isolated: $($unit.id) -> $preview";Expect ([string]$preview -notlike '*/to-be/assets/*') "preview appears under deliverables: $preview"}
    }
} catch {$failures.Add($_.Exception.Message)}

$index=Get-Content $indexPath -Raw
$match=[regex]::Match($index,'(?s)<script id="inventory-data" type="application/json">(.*?)</script>')
Expect $match.Success 'index lacks embedded inventory data'
if($match.Success){try{$embedded=$match.Groups[1].Value|ConvertFrom-Json -Depth 100;Expect ((Get-VisualCanonicalJson $embedded) -ceq (Get-VisualCanonicalJson $actual)) 'embedded inventory differs'}catch{$failures.Add("invalid embedded inventory: $($_.Exception.Message)")}}
foreach($required in @('id="language-toggle"','id="search"','id="domain-filter"','id="status-filter"','id="kind-filter"','<dialog id="image-dialog"','loading="lazy"','prefers-reduced-motion','data-image','aria-live="polite"','approved_for_switch','target_required','retire_only','promote_visual_replacement_unit.ps1')){Expect ($index.Contains($required)) "index contract missing: $required"}
$prohibitedTokens=@('fetch(','XMLHttpRequest',('9b30'+'9ce'),('semantic-v3-'+'approval'),('current-review-'+'overrides'),('review-'+'images'),('restore_visual_asset_'+'inventory'))
foreach($prohibited in $prohibitedTokens){Expect (-not ($index.Contains($prohibited))) "index contains prohibited token: $prohibited"}

if($failures.Count){$failures|ForEach-Object{Write-Error $_};exit 1}
Write-Host "VISUAL_REPLACEMENT_WORKBENCH_VALIDATION_OK units=$($actual.summary.units) media=$($actual.summary.gameplay_png + $actual.summary.ui_png + $actual.summary.font) statuses=$($actual.summary.statuses.keep_current)/$($actual.summary.statuses.target_required)"
