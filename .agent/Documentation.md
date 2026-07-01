# .agent/Documentation.md

## Current Status
- Repository bootstrapped on 2026-06-30 under `D:\npjt\cardborne-platformer`.
- The PRD has been copied into `docs/product/2d_platform_action_card_game_prd.md`.
- Godot 4.7 stable portable runtime is expected at `.codex-runtime/godot-4.7-stable/` when installed. This directory is intentionally ignored by git.
- No gameplay implementation has started yet.
- Remote repository was created at `https://github.com/simpleusername96/cardborne-platformer` and `master` tracks `origin/master`.
- First-slice expansion docs and seed data now define XP, coins, materials, map previews, player skill/equipment guidance, and enemies/traps/gimmicks before gameplay code generation.
- UI/UX screen skeletons are defined as data and generated to SVG previews before any image-model polish or Godot UI scene work.
- A standalone HTML/CSS/JS code mockup under `docs/uiux/code_mockup/` now covers the first-slice screen flow, seeded landscape preview, and forge/enchant equipment roll UI.
- Reference and asset candidates are cataloged, but no third-party assets have been imported yet.
- Procedural region generation is now modeled as seeded mission/region graph generation before any random tile placement.

## Durable Decisions
- Use Godot 4.x with GDScript for MVP work.
- Use the standard Godot build, not the .NET/C# build, unless the user changes language direction.
- Build in PRD milestone order and stabilize the player controller before broad content work.
- Use placeholder shapes or simple sprites; avoid external asset dependencies during MVP.
- Treat `docs/product/2d_platform_action_card_game_prd.md` as an active spec.
- Treat `docs/product/FIRST_SLICE_EXPANSION.md` as the active first-slice product delta on top of the PRD.
- Treat `data/design/first_slice/` JSON as seed design data, not final runtime schema.
- Treat generated map SVGs under `docs/maps/generated/` as visual planning aids until Godot scenes exist.
- Treat generated UI/UX SVGs under `docs/uiux/generated/` as screen composition targets until Godot UI scenes exist.
- Treat `docs/uiux/code_mockup/` as a reviewable UI prototype, not runtime Godot scene code.
- Treat `docs/references/GENRE_REFERENCES_AND_ASSETS.md` as evidence only; verify licenses again before importing assets.
- Treat `data/design/first_slice/procedural_region_rules.json` as the first procedural map-generation contract.

## Key Discoveries
- The PRD is detailed enough for Codex to start implementation without inventing core requirements.
- Highest implementation risks from the PRD: player movement reliability, card-system data separation, boss telegraph readability, and scope control.

## Known Risks
- Godot scene files can be fragile when hand-edited. Prefer editor-generated scenes when practical, then review diffs.
- A one-shot full-game implementation would likely hide movement and boss-readability problems. Keep work milestone-sized.
- The local Godot binary is ignored and should not be committed.

## Run / Verify
- Check Godot: `.\tools\godot.ps1 --version`
- Open editor: `.\tools\godot.ps1 --path . --editor`
- Headless project check: `.\tools\godot.ps1 --path . --headless --import`
- Generate map previews: `python tools/generate_map_previews.py`
- Generate UI/UX wireframes: `python tools/generate_uiux_wireframes.py`
- Generate procedural region examples: `python tools/generate_region_graph.py`
- Git status: `git status --short`
