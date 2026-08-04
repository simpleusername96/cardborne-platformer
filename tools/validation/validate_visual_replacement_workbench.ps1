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
$canonicalStyleAuthorityPath = 'docs/design/VISUAL_SYSTEM.md'
$canonicalStyleReferenceSheet = [ordered]@{
    path = 'docs/design/cardborne-universal-art-style-reference.png'
    sha256 = '96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889'
    width = 1448
    height = 1086
}
$failures = [Collections.Generic.List[string]]::new()
function Expect([bool]$Condition,[string]$Message){if(-not $Condition){$failures.Add($Message)}}
function New-AuthorityEvidence([bool]$Raster,[string]$Method){
    return [pscustomobject]@{
        spec_path=$canonicalStyleAuthorityPath;sheet_path=$canonicalStyleReferenceSheet.path;
        sheet_sha256=$canonicalStyleReferenceSheet.sha256;document_read_complete=$true;
        sheet_inspected_original=$true;actual_image_reference_used=$Raster;
        reference_input_method=$Method
    }
}
function Expect-ProjectionRejected($Candidate,[string]$Expected,[string]$Context){
    $message=$null
    try { Get-VisualReplacementProjection -RepoRoot $repoRoot -Source $Candidate | Out-Null } catch { $message=$_.Exception.Message }
    Expect ($null -ne $message) "workbench model accepted invalid authority evidence: $Context"
    if($null -ne $message){Expect ($message.Contains($Expected)) "workbench model rejected $Context for the wrong reason"}
}

try { & (Join-Path $designRoot 'build_visual_replacement_workbench.ps1') -Check } catch { $failures.Add($_.Exception.Message) }
foreach($path in @($sourcePath,$inventoryPath,$indexPath,$templatePath)){Expect (Test-Path -LiteralPath $path -PathType Leaf) "missing workbench file: $path"}
if($failures.Count){$failures|ForEach-Object{Write-Error $_};exit 1}

try {
    $source=Get-Content $sourcePath -Raw|ConvertFrom-Json -Depth 100
    $expected=Get-VisualReplacementProjection -RepoRoot $repoRoot -Source $source
    $inventoryText=(Get-Content $inventoryPath -Raw).Replace("`r`n","`n").TrimEnd("`n")
    $actual=$inventoryText|ConvertFrom-Json -Depth 100
    Expect ((Get-VisualCanonicalJson $expected) -ceq (Get-VisualCanonicalJson $actual)) 'inventory.json projection mismatch'
    Expect ([string]$actual.style_authority -ceq $canonicalStyleAuthorityPath) 'projected style authority path is not canonical'
    $expectedStyleReference=$expected.style_reference_sheet
    $actualStyleReference=$actual.style_reference_sheet
    Expect ($null -ne $expectedStyleReference) 'projection omits style_reference_sheet'
    Expect ($null -ne $actualStyleReference) 'inventory omits style_reference_sheet'
    if($null -ne $expectedStyleReference){Expect ((Get-VisualCanonicalJson $expectedStyleReference) -ceq (Get-VisualCanonicalJson $canonicalStyleReferenceSheet)) 'projected style reference sheet contract is not canonical'}
    if($null -ne $actualStyleReference){Expect ((Get-VisualCanonicalJson $actualStyleReference) -ceq (Get-VisualCanonicalJson $canonicalStyleReferenceSheet)) 'inventory style reference sheet contract is not canonical'}
    $styleAuthorityFile=Resolve-VisualRepositoryPath -RepoRoot $repoRoot -Path $canonicalStyleAuthorityPath
    $styleReferenceFile=Resolve-VisualRepositoryPath -RepoRoot $repoRoot -Path $canonicalStyleReferenceSheet.path
    Expect (Test-Path -LiteralPath $styleAuthorityFile -PathType Leaf) 'canonical style authority document is missing'
    Expect (Test-Path -LiteralPath $styleReferenceFile -PathType Leaf) 'canonical style reference sheet is missing'
    if(Test-Path -LiteralPath $styleReferenceFile -PathType Leaf){
        Expect ((Get-VisualSha256 $styleReferenceFile) -ceq $canonicalStyleReferenceSheet.sha256) 'canonical style reference sheet hash mismatch'
        $styleReferenceDimensions=Get-VisualPngDimensions $styleReferenceFile
        Expect ($styleReferenceDimensions[0] -eq $canonicalStyleReferenceSheet.width -and $styleReferenceDimensions[1] -eq $canonicalStyleReferenceSheet.height) 'canonical style reference sheet dimension mismatch'
    }
    Expect ($actual.summary.font -eq 1) 'production font count must be 1'
    Expect ($actual.summary.units -eq 17) 'switch unit count must be 17'
    Expect ($actual.summary.retire_only -eq 6) 'retire-only count must be 6'
    Expect ($actual.summary.gameplay_png -eq 57) 'production gameplay PNG count must be 57'
    Expect ($actual.summary.final_gameplay_png -eq 57) 'final gameplay PNG forecast must be 57'
    Expect ($actual.summary.authored_gameplay_png -eq 55) 'authored gameplay PNG output count must be 55'
    Expect ($actual.summary.reused_gameplay_png -eq 2) 'reused gameplay PNG count must be 2'
    Expect ($actual.summary.retired_gameplay_png -eq 0) 'no retired gameplay PNG may remain in production'
    Expect ($actual.summary.external_sources -eq 5) 'curated external source count must be 5'
    Expect (@($actual.external_sources).Count -eq 5) 'external source registry must contain five records'

    $missingEvidenceSource=Get-Content $sourcePath -Raw|ConvertFrom-Json -Depth 100
    $missingEvidenceUnit=$missingEvidenceSource.units|Where-Object id -ceq 'hud_minimap_combat_cues_code_native'
    $missingEvidenceUnit.PSObject.Properties.Remove('visual_authority_evidence')
    Expect-ProjectionRejected $missingEvidenceSource 'ready unit lacks visual authority evidence' 'applied unit without evidence'

    $validNonRasterSource=Get-Content $sourcePath -Raw|ConvertFrom-Json -Depth 100
    $validNonRasterUnit=$validNonRasterSource.units|Where-Object id -ceq 'hud_minimap_combat_cues_code_native'
    $validNonRasterUnit|Add-Member -NotePropertyName visual_authority_evidence -NotePropertyValue (New-AuthorityEvidence $false 'not_applicable') -Force
    try {
        $validNonRasterProjection=Get-VisualReplacementProjection -RepoRoot $repoRoot -Source $validNonRasterSource
        Expect (($validNonRasterProjection.units|Where-Object id -ceq 'hud_minimap_combat_cues_code_native').status -ceq 'applied') 'valid non-raster authority evidence was not projected'
    } catch {$failures.Add("valid non-raster authority evidence was rejected: $($_.Exception.Message)")}

    $invalidRasterSource=Get-Content $sourcePath -Raw|ConvertFrom-Json -Depth 100
    $invalidRasterUnit=$invalidRasterSource.units|Where-Object id -ceq 'projectile_family'
    $invalidRasterUnit|Add-Member -NotePropertyName visual_authority_evidence -NotePropertyValue (New-AuthorityEvidence $false 'not_applicable') -Force
    Expect-ProjectionRejected $invalidRasterSource 'raster unit lacks actual sheet-reference evidence' 'raster unit without actual reference input'

    $autonomousRecordSource=Get-Content $sourcePath -Raw|ConvertFrom-Json -Depth 100
    ($autonomousRecordSource.units|Where-Object id -ceq 'effect_atlas_retirement').approval.approved_by='autonomous-executor'
    try {
        $autonomousProjection=Get-VisualReplacementProjection -RepoRoot $repoRoot -Source $autonomousRecordSource
        Expect (($autonomousProjection.units|Where-Object id -ceq 'effect_atlas_retirement').approval.approved_by -ceq 'autonomous-executor') 'autonomous technical record owner was not projected'
    } catch {$failures.Add("valid autonomous technical record was rejected: $($_.Exception.Message)")}

    $invalidRecordOwnerSource=Get-Content $sourcePath -Raw|ConvertFrom-Json -Depth 100
    ($invalidRecordOwnerSource.units|Where-Object id -ceq 'effect_atlas_retirement').approval.approved_by='untrusted-executor'
    Expect-ProjectionRejected $invalidRecordOwnerSource 'invalid technical record owner' 'untrusted technical record owner'

    $extraRecordTargetSource=Get-Content $sourcePath -Raw|ConvertFrom-Json -Depth 100
    $extraRecordHashMap=($extraRecordTargetSource.units|Where-Object id -ceq 'effect_atlas_retirement').approval.deliverable_sha256
    $extraRecordHashMap|Add-Member -NotePropertyName 'art/visuals/production/gameplay/unlisted.png' -NotePropertyValue ('0'*64)
    Expect-ProjectionRejected $extraRecordTargetSource 'technical record target paths mismatch' 'technical record with an extra target path'

    $expectedGameplayUnits=[ordered]@{
        player_craft=@(1,1)
        hud_minimap_combat_cues_code_native=@(0,0)
        small_effect_suppression=@(0,0)
        emp_authored_replacement=@(1,1)
        projectile_family=@(1,1)
        defense_status_family=@(0,0)
        pickup_reward_family=@(4,4)
        world_facility_family=@(8,8)
        secondary_and_wear_family=@(7,7)
        ordinary_enemy_family=@(19,19)
        boss_and_shared_node_family=@(8,8)
        gameplay_code_asset_rasterization=@(8,8)
    }
    foreach($unitId in $expectedGameplayUnits.Keys){
        $matches=@($actual.units|Where-Object id -ceq $unitId)
        Expect ($matches.Count -eq 1) "gameplay unit must exist exactly once: $unitId"
        if($matches.Count -eq 1){
            Expect (@($matches[0].current_files).Count -eq [int]$expectedGameplayUnits[$unitId][0]) "current PNG count mismatch: $unitId"
            Expect (@($matches[0].final_paths).Count -eq [int]$expectedGameplayUnits[$unitId][1]) "final PNG count mismatch: $unitId"
        }
    }
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
    $statusTotal=0
    foreach($status in @('keep_current','target_required','switch_ready','approved_for_switch','applied','retired')){$statusTotal += [int]$actual.summary.statuses.$status}
    Expect ($statusTotal -eq [int]$actual.summary.units) 'status counts do not cover every unit'
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
    $unexpectedRetiredStates=@($actual.units|Where-Object{$_.switch_kind -ne 'retire' -and $_.status -eq 'retired'})
    Expect ($unexpectedRetiredStates.Count -eq 0) 'non-retirement unit uses the retired workflow state'
    foreach($unit in $actual.units){
        Expect (-not [string]::IsNullOrWhiteSpace([string]$unit.title_en)) "missing English title: $($unit.id)"
        Expect ([string]$unit.title_ko -match '[가-힣]') "missing Korean title: $($unit.id)"
        $authorityEvidence=$unit.visual_authority_evidence
        if([string]$unit.status -in @('switch_ready','approved_for_switch','applied')){Expect ($null -ne $authorityEvidence) "ready unit lacks visual authority evidence: $($unit.id)"}
        if($null -ne $authorityEvidence){
            Expect ([string]$authorityEvidence.spec_path -ceq $canonicalStyleAuthorityPath) "unit authority evidence has wrong spec path: $($unit.id)"
            Expect ([string]$authorityEvidence.sheet_path -ceq $canonicalStyleReferenceSheet.path) "unit authority evidence has wrong sheet path: $($unit.id)"
            Expect ([string]$authorityEvidence.sheet_sha256 -ceq $canonicalStyleReferenceSheet.sha256) "unit authority evidence has wrong sheet hash: $($unit.id)"
            Expect ([bool]$authorityEvidence.document_read_complete) "unit authority document was not read completely: $($unit.id)"
            Expect ([bool]$authorityEvidence.sheet_inspected_original) "unit authority sheet was not inspected at original detail: $($unit.id)"
            $hasRasterDeliverable=@($unit.deliverables|Where-Object{[string]$_.target_path -like '*.png'}).Count -gt 0
            Expect ([bool]$authorityEvidence.actual_image_reference_used -eq $hasRasterDeliverable) "unit actual-reference evidence disagrees with media type: $($unit.id)"
            Expect (([string]$authorityEvidence.reference_input_method -cne 'not_applicable') -eq $hasRasterDeliverable) "unit reference input method disagrees with media type: $($unit.id)"
        }
        switch([string]$unit.status){
            'keep_current' { Expect ($null -eq $unit.approval -and $null -eq $unit.application) "keep-current unit contains workflow ledger data: $($unit.id)" }
            'target_required' { Expect ($null -eq $unit.approval -and $null -eq $unit.application) "target-required unit contains workflow ledger data: $($unit.id)" }
            'switch_ready' { Expect ($null -eq $unit.approval -and $null -eq $unit.application) "switch-ready unit contains premature workflow ledger data: $($unit.id)" }
            'approved_for_switch' { Expect ($null -ne $unit.approval -and $null -eq $unit.application) "approved unit has an invalid workflow ledger: $($unit.id)" }
            'applied' { Expect ($null -ne $unit.approval -and $null -ne $unit.application) "applied unit has an incomplete workflow ledger: $($unit.id)" }
            'retired' { Expect ($null -ne $unit.approval -and $null -ne $unit.application) "retired unit has an incomplete workflow ledger: $($unit.id)" }
        }
        foreach($file in $unit.current_files){Expect ([string]$file.path -like 'art/visuals/production/*') "AS-IS is not direct production media: $($unit.id) -> $($file.path)"}
        foreach($deliverable in $unit.deliverables){Expect (([string]$deliverable.workbench_path) -ceq "docs/design/visual-replacement-workbench/to-be/assets/$($deliverable.target_path)") "TO-BE mapping mismatch: $($unit.id) -> $($deliverable.target_path)"}
        foreach($deliverable in $unit.deliverables){
            Expect (-not [string]::IsNullOrWhiteSpace([string]$deliverable.brief_en)) "TO-BE deliverable lacks a final brief: $($unit.id) -> $($deliverable.target_path)"
            foreach($sourceId in @($deliverable.external_source_ids)){Expect ($sourceId -in @($actual.external_sources.id)) "TO-BE brief references missing provenance: $($unit.id) -> $($deliverable.target_path) -> $sourceId"}
        }
        foreach($preview in $unit.preview_paths){Expect ([string]$preview -like 'docs/design/visual-replacement-workbench/previews/*') "preview path is not isolated: $($unit.id) -> $preview";Expect ([string]$preview -notlike '*/to-be/assets/*') "preview appears under deliverables: $preview"}
    }
} catch {$failures.Add($_.Exception.Message)}

$template=Get-Content $templatePath -Raw
$index=Get-Content $indexPath -Raw
$match=[regex]::Match($index,'(?s)<script id="inventory-data" type="application/json">(.*?)</script>')
Expect $match.Success 'index lacks embedded inventory data'
if($match.Success){try{$embedded=$match.Groups[1].Value|ConvertFrom-Json -Depth 100;Expect ((Get-VisualCanonicalJson $embedded) -ceq (Get-VisualCanonicalJson $actual)) 'embedded inventory differs'}catch{$failures.Add("invalid embedded inventory: $($_.Exception.Message)")}}
foreach($required in @('id="language-toggle"','id="search"','id="domain-filter"','id="status-filter"','id="kind-filter"','id="issue-only"','id="copy-issues"','id="download-issues"','data-issue-check','data-issue-note','localStorage','cardborne.visualReplacementIssues.v1','Technical status','기술 상태','<dialog id="image-dialog"','loading="lazy"','prefers-reduced-motion','data-image','aria-live="polite"','approved_for_switch','target_required','retire_only','"final_gameplay_png":57','"external_sources"','"style_reference_sheet"','"visual_authority_evidence"')){Expect ($index.Contains($required)) "index contract missing: $required"}
$authorityUiMarkers=@(
    'id="visual-authority-pair"',
    'id="style-authority-link"',
    'href="../VISUAL_SYSTEM.md"',
    'id="style-reference-trigger"',
    'docs/design/VISUAL_SYSTEM.md',
    'docs/design/cardborne-universal-art-style-reference.png',
    'Mandatory visual authority pair',
    '필수 비주얼 정본 쌍',
    'The sheet is a style reference only; it is not approval of any depicted asset.',
    '이 시트는 스타일 참조일 뿐이며, 개별 에셋 승인이 아닙니다.',
    'data.style_reference_sheet'
)
foreach($marker in $authorityUiMarkers){Expect ($template.Contains($marker)) "template authority UI missing: $marker";Expect ($index.Contains($marker)) "index authority UI missing: $marker"}
$prohibitedTokens=@('fetch(','XMLHttpRequest','Validate and preview promotion','검증 및 전환 미리보기',('9b30'+'9ce'),('semantic-v3-'+'approval'),('current-review-'+'overrides'),('review-'+'images'),('restore_visual_asset_'+'inventory'))
foreach($prohibited in $prohibitedTokens){Expect (-not ($index.Contains($prohibited))) "index contains prohibited token: $prohibited"}

if($failures.Count){$failures|ForEach-Object{Write-Error $_};exit 1}
$statusSummary=@($actual.summary.statuses.PSObject.Properties|Where-Object{[int]$_.Value -gt 0}|ForEach-Object{"$($_.Name)=$($_.Value)"}) -join ','
Write-Host "VISUAL_REPLACEMENT_WORKBENCH_VALIDATION_OK units=$($actual.summary.units) current=$($actual.summary.gameplay_png) final=$($actual.summary.final_gameplay_png) authored=$($actual.summary.authored_gameplay_png) retired=$($actual.summary.retired_gameplay_png) statuses=$statusSummary"
