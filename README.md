# Cardborne Platformer

Godot 4.7 GDScript project for a 2D action-platform roguelite. Authored room
templates are assembled into constrained seeded stages; responsive traversal and
readable combat feed a run-changing card, equipment, and mastery build.

Start with `docs/README.md`. The canonical product scope is
`docs/product/2d_platform_action_card_game_prd.md`, and the active implementation
checklist is `.agent/execplans/2026-07-12-actual-game-production-roadmap.md`.

## Requirements

- Godot 4.7 stable or compatible Godot 4.x build.
- GDScript only for the MVP; the .NET/C# Godot build is not required.
- Desktop keyboard and fixed-layout gamepad controls are supported.

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

## Active Implementation

Follow the active roadmap in milestone-sized batches. The production sequence is:

1. Finish a typed Warrior combat room and reward/build loop.
2. Assemble the first generated stage from validated authored rooms.
3. Add persistence, equipment, mastery, Stage 2, and the complete Warrior kit.
4. Complete Archer and Assassin, Stage 3, the boss, and full-run polish.

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
