# Cardborne

Cardborne is a Godot 4.7 top-down vehicle action shooter built around manual
targeting, uniform held primary fire, dash movement, automatic secondary
weapons, EMP, collectible experience, and card upgrades.

## Current Game

`project.godot` boots the connected five-stage vehicle run. The current product
and visual contracts, including exact controls, stage flow, content counts,
localization and acceptance criteria, are indexed in `docs/README.md`; this
README intentionally does not duplicate them.

## Local Godot

```powershell
.\tools\setup-godot.ps1
.\tools\godot.ps1 --path . --editor
.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --quit-after 2
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_run.gd
.\tools\export_web.ps1
```

Run every focused validator:

```powershell
Get-ChildItem tools/validation -Filter *.gd | Sort-Object Name | ForEach-Object {
  .\tools\godot.ps1 --headless --script ("res://tools/validation/" + $_.Name)
  if ($LASTEXITCODE -ne 0) { throw "Validation failed: $($_.Name)" }
}
```

Generate deterministic rendered evidence. Passing the Godot `--` separator via
an argument array keeps PowerShell from consuming it:

```powershell
$captureDir = Join-Path (Resolve-Path .).Path "build\captures"
$godotArgs = @(
  "--rendering-method", "gl_compatibility", "--",
  "--capture-all=$captureDir", "--capture-locale=ko", "--capture-size=1280x720",
  "--layout-seed=12886704"
)
.\tools\godot.ps1 @godotArgs
```
