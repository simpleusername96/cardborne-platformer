# Cardborne

Cardborne is a Godot 4.7 top-down vehicle action shooter built around manual
targeting, held primary fire, a one-second opening shot, dash movement, automatic
secondary weapons, EMP, collectible experience, and card upgrades.

## Current Game

- `project.godot` boots `scenes/main/GameRoot.tscn` and the connected
  `scenes/run/VehicleRun.tscn` campaign.
- Each new run selects one of three validated macro fields. Its five
  deterministic tactical layouts each activate eight large cover modules,
  four stationary threats, six loose pickups, and eight crates. All five stages
  and exact retries reuse the selected field while builds and explored minimap
  cells persist.
- Encounter packets begin with a six-second safe arrival, then grow from one
  scout into local packs distributed across all four quadrants and at least
  four of eight telegraphed field sectors. Hard's post-scout active-cap curve is
  124/172/224/276; Normal and Easy reduce combined count and combat-stat
  pressure.
- Easy, Normal, or Hard is selected before deployment and remains locked for the
  complete run.
- Substantial ordinary-defeat quotas summon a roaming boss into the same field;
  neither elapsed time nor a direct boss call can bypass that gate. Surviving
  enemies never lock travel or force a full clear.
- Bosses pursue and strafe during read and recovery, then commit one predicted
  target when a startup warning appears. Its position and damage footprint stay
  fixed through impact before a bounded recovery window.
- The current build includes 46 card upgrades and five automatic secondary
  families, with at most three active at once. Fire, poison, and chill upgrade
  branches can coexist and apply independent bounded stacks.
- The persistent `?` guidebook reveals only enemies, bosses, objects, and ship
  details the player has encountered.
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
  "--capture-all=$captureDir", "--capture-locale=ko", "--capture-size=1280x720",
  "--layout-seed=12886704"
)
.\tools\godot.ps1 @godotArgs
```
