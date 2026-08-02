Set-StrictMode -Version Latest

function Get-InventoryPropertyValue {
    param(
        [AllowNull()] [object]$Object,
        [Parameter(Mandatory)] [string]$Name
    )

    if ($null -eq $Object) {
        return $null
    }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }
    return $property.Value
}

function Add-InventoryMediaPath {
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$Paths,
        [AllowNull()] [object]$Value
    )

    if ($null -ne $Value -and -not [string]::IsNullOrWhiteSpace([string]$Value)) {
        $Paths.Add([string]$Value)
    }
}

function Add-InventoryEvidenceBlockPaths {
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$Paths,
        [AllowNull()] [object]$Block
    )

    if ($null -eq $Block) {
        return
    }
    foreach ($key in @("image", "sheet")) {
        $media = Get-InventoryPropertyValue -Object $Block -Name $key
        Add-InventoryMediaPath -Paths $Paths -Value (
            Get-InventoryPropertyValue -Object $media -Name "path"
        )
    }
}

function Get-VisualAssetInventoryRenderedMediaPaths {
    param([Parameter(Mandatory)] [object]$Data)

    $paths = [System.Collections.Generic.List[string]]::new()
    foreach ($unit in @($Data.visual_system_units)) {
        foreach ($path in @(
            Get-InventoryPropertyValue -Object $unit -Name "asis_images"
        )) {
            Add-InventoryMediaPath -Paths $paths -Value $path
        }
        Add-InventoryMediaPath -Paths $paths -Value (
            Get-InventoryPropertyValue -Object $unit -Name "representative_image"
        )
        $toBe = Get-InventoryPropertyValue -Object $unit -Name "tobe"
        foreach ($path in @(
            Get-InventoryPropertyValue -Object $toBe -Name "images"
        )) {
            Add-InventoryMediaPath -Paths $paths -Value $path
        }
    }
    foreach ($decision in @($Data.approval_decisions)) {
        Add-InventoryEvidenceBlockPaths -Paths $paths -Block $decision.current_truth
        Add-InventoryEvidenceBlockPaths -Paths $paths -Block $decision.candidate_evidence
    }
    foreach ($record in @($Data.staged_not_runtime)) {
        Add-InventoryMediaPath -Paths $paths -Value $record.path
    }
    foreach ($override in $Data.tobe_overrides.PSObject.Properties.Value) {
        foreach ($path in @($override.images)) {
            Add-InventoryMediaPath -Paths $paths -Value $path
        }
    }
    return @($paths | Sort-Object -Unique)
}

Export-ModuleMember -Function Get-VisualAssetInventoryRenderedMediaPaths
