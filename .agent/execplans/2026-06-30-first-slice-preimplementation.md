---
type: plan
status: superseded
superseded_by: ./2026-07-12-actual-game-production-roadmap.md
created: 2026-06-30
related:
  - docs/product/FIRST_SLICE_EXPANSION.md
  - docs/architecture/FIRST_SLICE_ARCHITECTURE.md
---

# First Slice Preimplementation Plan

## Why / Context

The repository started with a card-reward platformer PRD. The user expanded the first-version intent to include XP drops, coin/money, materials, map visual data, player controls, skill trees, equipment, enemies, traps, and map gimmick guidance before code generation.

## Scope / Non-scope

Scope:

- Document the expanded first-slice product expectations.
- Define architecture boundaries before implementation.
- Add seed JSON data for economy, player progression, equipment, encounters, and maps.
- Generate simple visual map previews from script-readable data.

Non-scope:

- No gameplay `.gd` or `.tscn` implementation in this plan.
- No final balance pass.
- No complex inventory, procedural generation, or online systems.

## Assumptions

- Godot 4.x GDScript remains the target.
- The PRD remains active baseline scope unless explicitly superseded by first-slice expansion docs.
- The first implementation should still prioritize movement reliability and no-soft-lock stage flow.
- Materials may become persistent through a lightweight local profile later, but seed data can define them now.

## Proposed Design

- Keep product scope in `docs/product/`.
- Keep architecture and system boundaries in `docs/architecture/`.
- Keep player, map, enemy, trap, and gimmick guidance in `docs/design/`.
- Keep seed JSON in `data/design/first_slice/`.
- Keep generated map previews in `docs/maps/generated/`.
- Keep external model attempts as evidence under `docs/research/`.

## Milestones

1. Baseline repository pushed to remote.
2. First-slice expansion docs and seed data committed.
3. Future implementation milestone: Godot project skeleton.
4. Future implementation milestone: player controller and HUD.
5. Future implementation milestone: reward economy and drops.
6. Future implementation milestone: card, level-up, equipment, and skill UI.
7. Future implementation milestone: Stage01-03 and boss loop.

## Test Plan

- Validate JSON syntax.
- Run map preview generation.
- Check git status before commit.
- Confirm remote push.
- During future implementation, use `.\tools\godot.ps1 --path . --headless --import` after Godot files exist.

## Rollback / Safety

- The documentation/data expansion is additive.
- No existing PRD content is deleted.
- If the expanded scope proves too large, implementation can stage the systems in order: player controller, combat, drops, cards, level-up, equipment, materials.

## Risks

- Scope can grow faster than movement/combat quality.
- Materials and equipment can imply a full inventory/crafting system if not kept narrow.
- XP level-up and card rewards can overlap unless their roles remain distinct.
- Map JSON can drift from Godot scenes unless previews are treated as design aids, not runtime truth.

## Open Questions

- Should materials persist in the first playable build or only after a local profile save exists?
- Should XP level-ups offer a separate micro-upgrade pool or reuse card-like choices?
- Should the first shop appear after every stage or only before the boss?

## Decision Notes

- Use private GitHub remote by default because the user did not request a public repository.
- Use plain JSON for first-slice data because it is easy to parse without extra Godot or Python dependencies.
- Generate SVG previews from stage layout data so map intent is visible in the repository before scene implementation.
