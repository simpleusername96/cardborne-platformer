# .agent/Documentation.md

## Current Status
- Repository bootstrapped on 2026-06-30 under `D:\npjt\cardborne-platformer`.
- The PRD has been copied into `docs/product/2d_platform_action_card_game_prd.md`.
- Godot 4.7 stable portable runtime is expected at `.codex-runtime/godot-4.7-stable/` when installed. This directory is intentionally ignored by git.
- An integrated movement/combat/map testbed exists and is now diagnostic evidence,
  not the default production direction.
- Remote repository was created at `https://github.com/simpleusername96/cardborne-platformer` and `master` tracks `origin/master`.
- `docs/product/FIRST_COMPLETE_RUN_SCOPE_DELTA.md` defines the active complete-run
  scope over the retained PRD and first-slice RPG-lite detail.
- `.agent/execplans/2026-07-12-actual-game-production-roadmap.md` is the active
  implementation sequence.
- UI/UX screen skeletons are defined as data and generated to SVG previews before any image-model polish or Godot UI scene work.
- A standalone HTML/CSS/JS code mockup under `docs/uiux/code_mockup/` now covers the first-slice screen flow, seeded landscape preview, and forge/enchant equipment roll UI.
- Reference and asset candidates are cataloged, but no third-party assets have been imported yet.
- Production map generation is constrained, seeded assembly of authored room
  templates. Arbitrary platform or tile placement is excluded from critical routes.

## Durable Decisions
- Use Godot 4.x with GDScript for MVP work.
- Use the standard Godot build, not the .NET/C# build, unless the user changes language direction.
- Work in milestone-sized batches from the active production roadmap while
  preserving the proven player movement envelope.
- Do not import an external package or asset family without a version/license
  record, isolated spike, removal boundary, and explicit approval.
- Treat `docs/product/2d_platform_action_card_game_prd.md` as an active spec.
- Treat `docs/product/FIRST_COMPLETE_RUN_SCOPE_DELTA.md` as the canonical current
  scope and clause-level override.
- Treat `docs/product/FIRST_SLICE_EXPANSION.md` as compatible RPG-lite detail, not
  authority for old sequencing limits.
- Treat `data/design/first_slice/` JSON as seed design data, not final runtime schema.
- Treat generated map SVGs under `docs/maps/generated/` as visual planning aids until Godot scenes exist.
- Treat generated UI/UX SVGs under `docs/uiux/generated/` as screen composition targets until Godot UI scenes exist.
- Treat `docs/uiux/code_mockup/` as a reviewable UI prototype, not runtime Godot scene code.
- Treat `docs/references/GENRE_REFERENCES_AND_ASSETS.md` as evidence only; verify licenses again before importing assets.
- Treat `data/design/first_slice/*.json` as migration/design input only; runtime
  catalogs must not silently read it alongside typed Resources.

## Key Discoveries
- The current code proves many component interactions but does not yet provide a
  complete player-facing run.
- Highest production risks are generated-stage validity, state-scope separation,
  effect consistency, progression integrity, character completeness, and boss
  counterplay.

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
