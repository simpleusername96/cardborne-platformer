# Cardborne Platformer

Godot 4.7 GDScript production project for a 2D side-view action platform
roguelite/RPG-lite with constrained generated stages and random build upgrades.

Current product scope is routed through `docs/product/README.md`. The canonical
first-complete-run delta is
`docs/product/FIRST_COMPLETE_RUN_SCOPE_DELTA.md`; the original PRD remains the
baseline where that delta does not override it.

## Requirements

- Godot 4.7 stable or compatible Godot 4.x build.
- GDScript only for the MVP; the .NET/C# Godot build is not required.
- Desktop keyboard controls are the initial target.

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

Follow `.agent/execplans/2026-07-12-actual-game-production-roadmap.md` in
milestone-sized batches. The current sequence is:

1. Reconcile product scope and production foundation decisions.
2. Separate profile, run, character-catalog, and effective-build ownership.
3. Replace the default testbed boot with a player-facing production shell.
4. Build constrained authored-room generation, encounters, progression, character
   kits, and the boss as complete playable workflows.

`MotionTestStage` remains an opt-in diagnostic until focused production tests cover
its useful movement and combat checks.

## Design Data

First-slice seed data lives in `data/design/first_slice/`. Generate map previews with:

```powershell
python tools/generate_map_previews.py
```

Generate UI/UX skeleton wireframes with:

```powershell
python tools/generate_uiux_wireframes.py
```

Generate procedural region graph examples with:

```powershell
python tools/generate_region_graph.py
```
