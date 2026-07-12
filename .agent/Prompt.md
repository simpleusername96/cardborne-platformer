# .agent/Prompt.md

## Purpose
- Build Cardborne's first complete run: a compact 2D action-platform roguelite where readable movement and combat earn choices that visibly change the rest of the run.

## Goals
- Responsive shared traversal for Warrior, Archer, and Assassin.
- Distinct basic, heavy, passive, and three-skill kits for each character.
- Three constrained seeded stages assembled from validated authored room templates.
- Readable enemies, hazards, optional risk/reward routes, checkpoints, and no soft locks.
- Run levels, behavior-changing cards, equipment, mastery, shops, and deterministic forging with clear ownership.
- One authored, readable two-phase Giant Slime King fight.
- A 28-38 minute run that is fun to replay before content breadth or presentation polish expands.

## Non-Goals
- Online multiplayer.
- Arbitrary platform scattering or unrestricted procedural geometry.
- Open-world exploration, live service, monetization, localization, or final production-scale content.
- Random upgrade failure, item destruction, downgrade outcomes, or grind required to finish a first run.
- New external dependencies or assets without explicit approval and adoption evidence.

## Hard Constraints
- Use the PRD in `docs/product/2d_platform_action_card_game_prd.md` as active spec.
- Use `docs/README.md` for the complete authority order and the active ExecPlan for implementation order.
- Use GDScript for MVP implementation.
- Keep cards, equipment, mastery, encounters, and room metadata data-driven and separate from UI/player special cases.
- Derive required traversal limits from the least-capable baseline profile and reject invalid stages before play.
- Every damaging boss pattern must telegraph before damage.
- Every gameplay milestone must produce a visible playable path and be checked against the PRD fun contract.

## Common Flows
- Check Godot with `.\tools\godot.ps1 --version`.
- Use `.\tools\godot.ps1 --path . --headless --import` for a fast project sanity check.
- Use the Godot editor for scene-heavy work when possible, then inspect generated diffs.

## Local Guidance Boundaries
- Root `AGENTS.md` carries repo-wide guidance.
- `.agent/*` carries durable working memory and milestone planning.
- No subtree-specific `AGENTS.md` files exist yet.
