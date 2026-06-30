# .agent/Prompt.md

## Purpose
- Build a compact Godot 4.x GDScript MVP for `Cardborne Platformer`, a 2D side-view action platformer with random upgrade cards.

## Goals
- Stable platformer movement and damage response.
- Simple, reliable melee combat.
- Three short authored stages.
- Three-card reward choice after normal stages.
- Data-driven cards and modular card effect application.
- One readable two-phase boss with telegraphed attacks.

## Non-Goals
- Online multiplayer.
- Full procedural generation.
- Complex inventory.
- Dialogue, shop, multiple playable characters, permanent skill tree, monetization, localization, or final production art/audio.

## Hard Constraints
- Use the PRD in `docs/product/2d_platform_action_card_game_prd.md` as active spec.
- Use GDScript for MVP implementation.
- Keep cards data-driven and separate from UI/player special cases.
- Every damaging boss pattern must telegraph before damage.

## Common Flows
- Check Godot with `.\tools\godot.ps1 --version`.
- Use `.\tools\godot.ps1 --path . --headless --import` for a fast project sanity check.
- Use the Godot editor for scene-heavy work when possible, then inspect generated diffs.

## Local Guidance Boundaries
- Root `AGENTS.md` carries repo-wide guidance.
- `.agent/*` carries durable working memory and milestone planning.
- No subtree-specific `AGENTS.md` files exist yet.
