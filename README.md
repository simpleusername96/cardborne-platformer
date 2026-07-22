# Cardborne

Godot 4.7 GDScript action project. The current executable is a flat top-down
vehicle run that preserves the project's flat-color drowned-ruin art direction.

## Current Runtime

- `project.godot` boots `scenes/main/PivotRoot.tscn`, which instantiates
  `scenes/run/VehicleStageOne.tscn`.
- The playable run contains Flooded Works, Tidal Archive, and Storm Drydock,
  manual aim and held primary fire, dash, passive seekers, EMP, field pickups,
  card upgrades, fixed installations, ordinary enemies, field bosses, and stage
  bosses.
- Korean is the default UI language and can be switched to English in runtime
  settings.
- The earlier humanoid native-3D proof remains in the repository as retained
  implementation evidence, but it is not the main boot path.

The implemented vehicle behavior is documented in
`docs/product/vehicle_content_expansion_spec.md`. Repository policy still
contains older humanoid-proof language that requires an explicit owner decision
before it can be rewritten; `docs/README.md` records that authority boundary.

## Local Godot

```powershell
.\tools\godot.ps1 --version
.\tools\godot.ps1 --path . --editor
.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --quit-after 2
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_one.gd
```

Use `docs/README.md` for current document authority, known conflicts, and retained
references.
