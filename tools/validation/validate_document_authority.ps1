[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure([string] $Message) {
  $failures.Add($Message)
}

function Relative-RepoPath([string] $Path) {
  [IO.Path]::GetRelativePath($repoRoot, $Path).Replace('\', '/')
}

function Read-Frontmatter([string] $Path) {
  $lines = Get-Content -LiteralPath $Path
  $fields = @{}
  if ($lines.Count -eq 0 -or $lines[0] -ne '---') {
    return $fields
  }
  for ($index = 1; $index -lt $lines.Count; $index++) {
    if ($lines[$index] -eq '---') { break }
    if ($lines[$index] -match '^([A-Za-z_]+):\s*(.*)$') {
      $fields[$Matches[1]] = $Matches[2].Trim()
    }
  }
  return $fields
}

function Expect-Contract(
  [string] $RelativePath,
  [string] $CanonicalPattern
) {
  $absolute = Join-Path $repoRoot $RelativePath
  if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) {
    Add-Failure "Missing canonical document: $RelativePath"
    return
  }
  $fields = Read-Frontmatter $absolute
  if ($fields['type'] -ne 'spec') {
    Add-Failure "$RelativePath must declare type: spec"
  }
  if ($fields['status'] -ne 'active') {
    Add-Failure "$RelativePath must declare status: active"
  }
  if ($fields['canonical_for'] -notmatch $CanonicalPattern) {
    Add-Failure "$RelativePath has the wrong canonical_for scope"
  }
}

Push-Location -LiteralPath $repoRoot
try {
  Expect-Contract 'docs/product/vehicle_game_spec.md' 'gameplay|product'
  Expect-Contract 'docs/product/vehicle_upgrade_catalog.md' 'upgrade|card'
  Expect-Contract 'docs/design/VISUAL_SYSTEM.md' 'visual|UI|art'

  $rootInstructions = Get-Content -Raw -LiteralPath 'AGENTS.md'
  foreach ($required in @(
      'docs/product/vehicle_game_spec.md',
      'docs/design/VISUAL_SYSTEM.md',
      '.agents/PLANS.md'
    )) {
    if (-not $rootInstructions.Contains($required)) {
      Add-Failure "AGENTS.md does not point to $required"
    }
  }

  $docsIndex = Get-Content -Raw -LiteralPath 'docs/README.md'
  foreach ($required in @(
      'product/vehicle_game_spec.md',
      'product/vehicle_upgrade_catalog.md',
      'design/VISUAL_SYSTEM.md'
    )) {
    if (-not $docsIndex.Contains($required)) {
      Add-Failure "docs/README.md does not point to $required"
    }
  }

  $productSpec = Get-Content -Raw -LiteralPath 'docs/product/vehicle_game_spec.md'
  $visualSpec = Get-Content -Raw -LiteralPath 'docs/design/VISUAL_SYSTEM.md'
  if (-not $productSpec.Contains('### Inner walls, Transit Gates, and Anomaly Devices')) {
    Add-Failure 'Product spec is missing the gameplay/collision terrain owner section'
  }
  if (-not $visualSpec.Contains('### Semantic categories')) {
    Add-Failure 'Visual spec is missing the delegated semantic category section'
  }

  $trackedMarkdown = @(
    git ls-files --cached --others --exclude-standard -- '*.md' '*.mdx'
  ) | Where-Object {
    $_ -and (Test-Path -LiteralPath (Join-Path $repoRoot $_) -PathType Leaf)
  }
  $allowedCanonical = @(
    '.agents/PLANS.md',
    '.agents/cardborne-performance-engineering-policy.md',
    '.agents/design/DESIGN.md',
    'docs/product/vehicle_game_spec.md',
    'docs/product/vehicle_upgrade_catalog.md',
    'docs/design/VISUAL_SYSTEM.md'
  )
  $allowedTypes = @('policy', 'spec', 'plan', 'handoff', 'evidence', 'record')
  $allowedStatuses = @('draft', 'active', 'done', 'superseded', 'archived')

  foreach ($relative in $trackedMarkdown) {
    $normalized = $relative.Replace('\', '/')
    $absolute = Join-Path $repoRoot $relative
    $fields = Read-Frontmatter $absolute
    if ($fields.ContainsKey('canonical_for') -and $normalized -notin $allowedCanonical) {
      Add-Failure "$normalized makes an unauthorized canonical_for claim"
    }
    if ($fields.Count -gt 0 -and $normalized -ne 'AGENTS.md' -and
        $normalized -ne '.agents/AGENTS.md') {
      if ($fields.ContainsKey('type') -and $fields['type'] -notin $allowedTypes) {
        Add-Failure "$normalized has invalid lifecycle type '$($fields['type'])'"
      }
      if ($fields.ContainsKey('status') -and $fields['status'] -notin $allowedStatuses) {
        Add-Failure "$normalized has invalid lifecycle status '$($fields['status'])'"
      }
      if ($fields['type'] -in @('evidence', 'record') -and
          $fields.ContainsKey('canonical_for')) {
        Add-Failure "$normalized evidence/record cannot claim canonical authority"
      }
      if ($fields['status'] -eq 'draft' -and $fields.ContainsKey('canonical_for')) {
        Add-Failure "$normalized draft cannot claim canonical authority"
      }
    }

    if ($normalized.StartsWith('.agents/execplans/')) {
      if ($fields['type'] -ne 'plan') {
        Add-Failure "$normalized must declare type: plan"
      }
      if ($fields['status'] -in @('done', 'superseded', 'archived')) {
        Add-Failure "$normalized is retired and must not remain in the active tree"
      }
      if ($fields['status'] -eq 'active') {
        $content = Get-Content -Raw -LiteralPath $absolute
        if (-not $content.Contains('../../docs/product/vehicle_game_spec.md')) {
          Add-Failure "$normalized active plan does not relate to the product spec"
        }
      }
    }

    $content = Get-Content -Raw -LiteralPath $absolute
    $matches = [regex]::Matches($content, '!?' + '\[[^\]]*\]\(([^)]+)\)')
    foreach ($match in $matches) {
      $target = $match.Groups[1].Value.Trim().Trim('<', '>')
      if ($target -match '^(https?://|mailto:|#)' -or $target -eq '') { continue }
      $target = ($target -split '\s+"', 2)[0]
      $target = ($target -split '#', 2)[0]
      if ($target -eq '') { continue }
      $decoded = [Uri]::UnescapeDataString($target).Replace('/', [IO.Path]::DirectorySeparatorChar)
      $resolved = [IO.Path]::GetFullPath((Join-Path (Split-Path $absolute) $decoded))
      if (-not (Test-Path -LiteralPath $resolved)) {
        Add-Failure "$normalized has a broken relative link: $target"
      }
    }
  }

  if ($failures.Count -gt 0) {
    foreach ($failure in $failures) { Write-Error $failure }
    exit 1
  }
  Write-Output "DOCUMENT_AUTHORITY_VALIDATION_OK markdown=$($trackedMarkdown.Count)"
} finally {
  Pop-Location
}
