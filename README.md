# Cardborne

Cardborne is a Godot 4.7 top-down vehicle action shooter built around manual
targeting, held primary fire, a one-second opening shot, dash movement, passive
seekers, EMP, map pickups, and card upgrades.

## Current Game

- `project.godot` boots `scenes/main/GameRoot.tscn` and the connected
  `scenes/run/VehicleRun.tscn` campaign.
- The run covers Flooded Works, Tidal Archive, and Storm Drydock.
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
```
