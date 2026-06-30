# Cardborne Platformer

Godot 4.x GDScript prototype for a 2D side-view action platformer with random upgrade cards.

The product source of truth is `docs/product/2d_platform_action_card_game_prd.md`.

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

## Implementation Order

Start with Milestone 1 and Milestone 2 from the PRD:

1. Project skeleton: main menu, Stage01, HUD, Player scene.
2. Player controller: movement, jump features, dash, crouch, fast fall, health, damage, death.

Do not build permanent progression, procedural generation, multiple characters, or extra content before the MVP vertical slice works.
