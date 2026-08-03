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
    Expect ($actual.summary.font -eq 1) 'production font count must be 1'
    Expect ($actual.summary.units -eq 36) 'switch unit count must be 36'
    Expect ($actual.summary.retire_only -eq 4) 'retire-only count must be 4'
    Expect ($actual.summary.gameplay_png -eq 215) 'production gameplay PNG count must be 215'
    $historicRetirementIds=@('effect_atlas_retirement','orphan_ui_state_retirement','procedural_floor_and_walls')
    $historicRetirements=@($actual.units|Where-Object id -in $historicRetirementIds)
    Expect ($historicRetirements.Count -eq 3) 'historic retirement unit set is incomplete'
    foreach($historicUnit in $historicRetirements){Expect ([string]$historicUnit.status -ceq 'retired') "historic retirement unit changed state: $($historicUnit.id)"}
    $uiRetirements=@($actual.units|Where-Object id -eq 'ui_chrome_retirement')
    Expect ($uiRetirements.Count -eq 1) 'UI chrome retirement unit must exist exactly once'
    $uiRetirement=if($uiRetirements.Count -eq 1){$uiRetirements[0]}else{$null}
    $uiRetirementState=if($null -ne $uiRetirement){[string]$uiRetirement.status}else{''}
    Expect ($uiRetirementState -in @('switch_ready','approved_for_switch','retired')) 'UI chrome retirement has an invalid state'
    $expectedUiPng=if($uiRetirementState -eq 'retired'){0}else{54}
    Expect ($actual.summary.ui_png -eq $expectedUiPng) 'UI PNG count does not match the UI chrome retirement state'
    $expectedStatuses=[ordered]@{keep_current=2;target_required=30;switch_ready=0;approved_for_switch=0;applied=0;retired=3}
    if($uiRetirementState -in @('switch_ready','approved_for_switch','retired')){$expectedStatuses[$uiRetirementState]++}
    foreach($status in $expectedStatuses.Keys){Expect ([int]$actual.summary.statuses.$status -eq [int]$expectedStatuses[$status]) "status count mismatch: $status"}
    if($null -ne $uiRetirement){
        Expect ([string]$uiRetirement.switch_kind -ceq 'retire') 'UI chrome retirement is not retire-only'
        Expect ([string]$uiRetirement.owner -ceq 'ui_theme') 'UI chrome retirement owner must be ui_theme'
        Expect (@($uiRetirement.current_files).Count -eq $(if($uiRetirementState -eq 'retired'){0}else{54})) 'UI chrome current-file count is invalid'
        Expect (@($uiRetirement.deliverables).Count -eq 0) 'UI chrome retirement has deliverables'
        Expect (@($uiRetirement.consumer_paths).Count -eq 0) 'UI chrome retirement has runtime consumers'
        Expect (@($uiRetirement.consumer_asset_ids).Count -eq 0) 'UI chrome retirement has consumer asset ids'
        Expect (@($uiRetirement.runtime_change_paths).Count -eq 0) 'UI chrome retirement has runtime change paths'
        Expect (@($uiRetirement.retire_paths).Count -eq 113) 'UI chrome retirement path count must be 113'
        Expect ((Get-VisualCanonicalJson @($uiRetirement.retire_paths)) -ceq (Get-VisualCanonicalJson @($uiRetirement.retire_paths|Sort-Object))) 'UI chrome retirement paths must be sorted'
        Expect (@($uiRetirement.retire_paths|Sort-Object -Unique).Count -eq 113) 'UI chrome retirement paths must be unique'
        Expect (@($uiRetirement.retire_paths|Where-Object{[string]$_ -match '[*?\[]'}).Count -eq 0) 'UI chrome retirement paths contain a wildcard'
        foreach($requiredPath in @(
            'art/visuals/production/ui/ui-asset-manifest.json',
            'scripts/ui/vehicle_ui_asset_provider.gd',
            'scripts/ui/vehicle_ui_asset_provider.gd.uid',
            'tools/validation/validate_visual_replacement_ui_surface_targets.gd',
            'tools/validation/validate_visual_replacement_ui_surface_targets.gd.uid'
        )){Expect ([string]$requiredPath -in @($uiRetirement.retire_paths)) "UI chrome retirement omits required path: $requiredPath"}
        foreach($retirePath in @($uiRetirement.retire_paths)){
            $exists=Test-Path -LiteralPath (Join-Path $repoRoot ([string]$retirePath)) -PathType Leaf
            Expect ($exists -eq ($uiRetirementState -ne 'retired')) "UI chrome retirement file presence disagrees with state: $retirePath"
        }
    }
    $retirementIds=@($historicRetirementIds)+@('ui_chrome_retirement')
    $unexpectedRetiredStates=@($actual.units|Where-Object{$_.id -notin $retirementIds -and $_.status -eq 'retired'})
    Expect ($unexpectedRetiredStates.Count -eq 0) 'non-retirement unit uses the retired workflow state'
    foreach($unit in $actual.units){
        Expect (-not [string]::IsNullOrWhiteSpace([string]$unit.title_en)) "missing English title: $($unit.id)"
        Expect ([string]$unit.title_ko -match '[가-힣]') "missing Korean title: $($unit.id)"
        if($unit.id -notin $retirementIds){
            switch([string]$unit.status){
                'keep_current' { Expect ($null -eq $unit.approval -and $null -eq $unit.application) "keep-current unit contains workflow ledger data: $($unit.id)" }
                'target_required' { Expect ($null -eq $unit.approval -and $null -eq $unit.application) "target-required unit contains workflow ledger data: $($unit.id)" }
                'switch_ready' { Expect ($null -eq $unit.approval -and $null -eq $unit.application) "switch-ready unit contains premature workflow ledger data: $($unit.id)" }
                'approved_for_switch' { Expect ($null -ne $unit.approval -and $null -eq $unit.application) "approved unit has an invalid workflow ledger: $($unit.id)" }
                'applied' { Expect ($null -ne $unit.approval -and $null -ne $unit.application) "applied unit has an incomplete workflow ledger: $($unit.id)" }
            }
        }
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
$statusSummary=@($actual.summary.statuses.PSObject.Properties|Where-Object{[int]$_.Value -gt 0}|ForEach-Object{"$($_.Name)=$($_.Value)"}) -join ','
Write-Host "VISUAL_REPLACEMENT_WORKBENCH_VALIDATION_OK units=$($actual.summary.units) media=$($actual.summary.gameplay_png + $actual.summary.ui_png + $actual.summary.font) statuses=$statusSummary"
