[CmdletBinding()]
param([Parameter(Mandatory)][ValidatePattern('^[a-z][a-z0-9_]*$')][string]$UnitId,[switch]$Apply)

$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$repoRoot=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Import-Module (Join-Path $PSScriptRoot 'visual_replacement_workbench_model.psm1') -Force
& (Join-Path $repoRoot 'tools\validation\validate_visual_replacement_workbench.ps1')
if($LASTEXITCODE -ne 0){throw 'workbench validation failed'}
$source=Get-Content (Join-Path $repoRoot 'docs\design\visual-replacement-workbench\replacement-workbench.json') -Raw|ConvertFrom-Json -Depth 100
$projection=Get-VisualReplacementProjection -RepoRoot $repoRoot -Source $source
$unit=@($projection.units|Where-Object id -ceq $UnitId)
if($unit.Count -ne 1){throw "unit must exist exactly once: $UnitId"};$unit=$unit[0]
if($unit.status -cne 'approved_for_switch'){throw "unit is not technically ready: $UnitId -> $($unit.status)"}
$baseline=[string]$unit.approval.baseline_commit
git -C $repoRoot cat-file -e "$baseline^{commit}" 2>$null
if($LASTEXITCODE -ne 0){throw "technical record baseline is not a local commit: $baseline"}
$dirty=@(git -C $repoRoot status --porcelain=v1)
if($dirty.Count){throw 'technical application requires a clean committed worktree'}
foreach($deliverable in $unit.deliverables){
    if($null -eq $deliverable.observed_sha256){throw "missing deliverable: $($deliverable.workbench_path)"}
    $approved=$unit.approval.deliverable_sha256.PSObject.Properties[$deliverable.target_path]
    if($null -eq $approved -or [string]$approved.Value -cne [string]$deliverable.observed_sha256){throw "technical record hash mismatch: $($deliverable.target_path)"}
    $sourcePath=Resolve-VisualRepositoryPath $repoRoot $deliverable.workbench_path;$targetPath=Resolve-VisualRepositoryPath $repoRoot $deliverable.target_path
    if(-not $deliverable.workbench_path.StartsWith('docs/design/visual-replacement-workbench/to-be/assets/')){throw "promotion source escapes TO-BE root: $($deliverable.workbench_path)"}
    if(-not $deliverable.target_path.StartsWith('art/visuals/production/')){throw "promotion target escapes production root: $($deliverable.target_path)"}
    Write-Host "COPY $($deliverable.workbench_path) -> $($deliverable.target_path) sha256=$($deliverable.observed_sha256)"
    if($Apply){[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($targetPath))|Out-Null;Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Force}
}
foreach($path in $unit.retire_paths){Write-Host "RETIRE_REVIEW_ONLY $path"}
if($Apply){Write-Host "VISUAL_REPLACEMENT_TECHNICAL_APPLICATION_COPIED unit=$UnitId files=$(@($unit.deliverables).Count)"}else{Write-Host "VISUAL_REPLACEMENT_TECHNICAL_PREVIEW_OK unit=$UnitId files=$(@($unit.deliverables).Count)"}
