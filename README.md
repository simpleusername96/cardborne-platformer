# Cardborne

Cardborne is a Godot 4.7 top-down vehicle action shooter built around manual
targeting, held primary fire, a one-second opening shot, dash movement, passive
seekers, EMP, map pickups, and card upgrades.

## Current Game

- `project.godot` boots `scenes/main/GameRoot.tscn` and the connected
  `scenes/run/VehicleRun.tscn` campaign.
- The run covers Flooded Works, Tidal Archive, Storm Drydock, Coral Switchyard,
  and Abyssal Observatory in order.
- Encounter packets begin with a six-second safe arrival, then grow from one
  scout into sequential 3/4/5-unit squads under Standard or Onslaught caps.
- The current data set contains 19 enemy archetypes and 46 card upgrades; a full
  run grants 15 mandatory and up to five optional choices.
- Ordinary enemies may be bypassed; installations and bosses own progression
  gates.
- Korean is the default UI language and English can be selected in settings.
- The active product and visual contracts are indexed in `docs/README.md`.

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
  "--capture-all=$captureDir", "--capture-locale=ko", "--capture-size=1280x720"
)
.\tools\godot.ps1 @godotArgs
```
