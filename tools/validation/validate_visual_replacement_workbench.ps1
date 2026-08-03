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
    Expect ($actual.summary.units -eq 48) 'switch unit count must be 48'
    Expect ($actual.summary.retire_only -eq 3) 'retire-only count must be 3'
    $phase3ReadyIds=@('effect_atlas_retirement','orphan_ui_state_retirement','procedural_floor_and_walls')
    $phase3Units=@($actual.units|Where-Object id -in $phase3ReadyIds)
    Expect ($phase3Units.Count -eq 3) 'Phase 3 retirement unit set is incomplete'
    $phase3States=@($phase3Units.status|Sort-Object -Unique)
    Expect ($phase3States.Count -eq 1) 'Phase 3 retirement units must advance atomically'
    $phase3State=if($phase3States.Count -eq 1){[string]$phase3States[0]}else{''}
    Expect ($phase3State -in @('switch_ready','approved_for_switch','retired')) 'Phase 3 retirement units have an invalid transition state'
    $unexpectedRetiredStates=@($actual.units|Where-Object { $_.id -notin $phase3ReadyIds -and $_.status -eq 'retired' })
    Expect ($unexpectedRetiredStates.Count -eq 0) 'non-retirement unit uses the retired workflow state'
    $retirementApplied=$phase3State -in @('approved_for_switch','retired')
    Expect ($actual.summary.gameplay_png -eq $(if($retirementApplied){217}else{247})) 'gameplay PNG count does not match the Phase 3 state'
    Expect ($actual.summary.ui_png -eq $(if($retirementApplied){54}else{57})) 'UI PNG count does not match the Phase 3 state'
    foreach($phase3Unit in $phase3Units){
        Expect ([string]$phase3Unit.switch_kind -ceq 'retire') "Phase 3 unit is not retire-only: $($phase3Unit.id)"
        Expect (@($phase3Unit.deliverables).Count -eq 0) "retire-only unit has deliverables: $($phase3Unit.id)"
        foreach($retirePath in @($phase3Unit.retire_paths)){
            $exists=Test-Path -LiteralPath (Join-Path $repoRoot ([string]$retirePath)) -PathType Leaf
            Expect ($exists -eq (-not $retirementApplied)) "retirement file presence disagrees with state: $($phase3Unit.id) -> $retirePath"
        }
        if($phase3State -eq 'switch_ready'){
            Expect ($null -eq $phase3Unit.approval) "switch-ready unit has approval data: $($phase3Unit.id)"
            Expect ($null -eq $phase3Unit.application) "switch-ready unit has application data: $($phase3Unit.id)"
        }else{
            Expect ($null -ne $phase3Unit.approval) "approved retirement unit lacks approval data: $($phase3Unit.id)"
            Expect (@($phase3Unit.approval.deliverable_sha256.PSObject.Properties).Count -eq 0) "retire-only approval hash map is not empty: $($phase3Unit.id)"
            if($phase3State -eq 'approved_for_switch'){Expect ($null -eq $phase3Unit.application) "production-switch unit has premature application data: $($phase3Unit.id)"}
            if($phase3State -eq 'retired'){Expect ($null -ne $phase3Unit.application) "retired unit lacks application data: $($phase3Unit.id)"}
        }
    }
    foreach($unit in $actual.units){
        Expect (-not [string]::IsNullOrWhiteSpace([string]$unit.title_en)) "missing English title: $($unit.id)"
        Expect ([string]$unit.title_ko -match '[가-힣]') "missing Korean title: $($unit.id)"
        if($unit.id -notin $phase3ReadyIds){
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
