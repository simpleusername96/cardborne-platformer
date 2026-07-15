# Cardborne Platformer

Godot 4.7 GDScript project for a 2D action-platform roguelite. Authored room
templates are assembled into constrained seeded stages; responsive traversal and
readable combat feed a run-changing card, equipment, and mastery build.

Start with `docs/README.md`. The canonical product scope is
`docs/product/2d_platform_action_card_game_prd.md`. Completed ExecPlans under
`.agent/execplans/` are implementation records, not an active backlog.

## Requirements

- Godot 4.7 stable or compatible Godot 4.x build.
- GDScript only for the MVP; the .NET/C# Godot build is not required.
- Gameplay uses remappable keyboard input; menus also accept the mouse.

## Local Godot

This repository is set up to use an ignored portable Godot runtime under `.codex-runtime/` when present. You can also set `GODOT_BIN` to any Godot executable.

Check the runtime:

```powershell
.\tools\godot.ps1 --version
```

Open the project editor:

```powershell
.\tools\godot.ps1 --path . --editor
```

Run a headless import/project sanity check:

```powershell
.\tools\godot.ps1 --path . --headless --import
```

If the local runtime is missing, install it with:

```powershell
.\tools\setup-godot.ps1
```

## Current Playable Baseline

One persistent Traveler can clear three approved fixed stages, make card and
equipment decisions, use deterministic Forge services, and fight the two-phase
Slime King. Blueprints, materials, crafted grades, equipment condition, and the
equipped loadout persist between app starts.

See `docs/release/TRAVELER_EQUIPMENT_VERTICAL_SLICE.md` for the implemented path
and validation evidence. Completed roadmaps remain implementation records rather
than active checklists.

## Runtime Catalogs

Typed Godot Resources under `data/` own gameplay IDs and accepted values. See
`docs/data/RUNTIME_CATALOG_INDEX.md` and validate their definitions and
cross-references with:

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validate_design_catalogs.gd
```

Validate production boot and the current playable stage with:

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validate_production_boot.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_production_stage.gd
```

Run the release gate with:

```powershell
.\tools\validate_release_candidate.ps1
.\tools\validate_release_candidate.ps1 -Full
```
