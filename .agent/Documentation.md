# .agent/Documentation.md

## Current Status
- Repository bootstrapped on 2026-06-30 under `D:\npjt\cardborne-platformer`.
- The PRD has been copied into `docs/product/2d_platform_action_card_game_prd.md`.
- Godot 4.7 stable portable runtime is expected at `.codex-runtime/godot-4.7-stable/` when installed. This directory is intentionally ignored by git.
- No gameplay implementation has started yet.

## Durable Decisions
- Use Godot 4.x with GDScript for MVP work.
- Use the standard Godot build, not the .NET/C# build, unless the user changes language direction.
- Build in PRD milestone order and stabilize the player controller before broad content work.
- Use placeholder shapes or simple sprites; avoid external asset dependencies during MVP.
- Treat `docs/product/2d_platform_action_card_game_prd.md` as an active spec.

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
- Git status: `git status --short`
