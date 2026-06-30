---
type: spec
status: active
canonical_for: first-slice RPG-lite scope expansion
source: User request on 2026-06-30; docs/product/2d_platform_action_card_game_prd.md
scope: First playable version before gameplay code generation
---

# First Slice Expansion

## Purpose

Define the expanded first playable slice before gameplay code is generated. This document is a product delta on top of `docs/product/2d_platform_action_card_game_prd.md`; it does not discard the original PRD. It adds first-version expectations for XP, coin, materials, map design data, player build systems, equipment, enemies, traps, and map gimmicks.

## Scope

The first slice should still be a compact Godot 4.x GDScript vertical slice, but it is no longer only a card-reward platformer. It should feel like a 2D action-platform RPG-lite loop:

1. Enter an authored stage.
2. Traverse platforming sections and map gimmicks.
3. Fight enemies and avoid traps.
4. Collect XP, coins, and materials from drops, chests, and clear rewards.
5. Gain temporary run power through level-up rewards and stage-clear card choices.
6. Spend coins on run-local utility or upgrades when a shop/rest point is available.
7. Use materials for lightweight persistent or between-run progression once local profile persistence exists.
8. Defeat a telegraphed two-phase boss.

The active PRD remains the baseline for movement, combat, card rewards, stage count, boss requirements, and Godot structure. This document expands the first-version content model and authoring guidance.

## Requirements

- Include XP drops from enemy defeats and selected breakable or reward objects.
- Include coin drops from enemies, chests, destructibles, and stage clear rewards.
- Include materials as named resources with clear sources and intended sinks.
- Keep card rewards after normal stage clears; cards remain one of the primary run-build systems.
- Add an in-run level curve so XP has immediate player-facing value.
- Add a simple economy distinction:
  - **XP** is run-local growth.
  - **Coins** are run-local spending money.
  - **Materials** are crafting/upgrade resources that may later persist through a lightweight local profile.
- Define data before code in JSON seed files under `data/design/first_slice/`.
- Define map layout data in a script-readable format and generate visual previews from it.
- Define what the initial playable character can do: controls, movement verbs, combat verbs, stats, level-up hooks, skill tree branches, and equipment slots.
- Define first-slice equipment examples before implementing inventory UI.
- Define first-slice enemies, traps, and map gimmicks with teaching purpose, damage rules, and reward/drop hooks.
- Preserve authored stages for the MVP. Do not replace them with procedural generation in the first slice.

## Acceptance Criteria

- Future implementation can create the first playable build without inventing core currencies, reward sources, equipment slots, or map notation.
- A designer or agent can inspect `data/design/first_slice/stage_layouts.json` and understand each stage's high-level shape.
- Running the map preview generator produces readable SVG map previews from the stage layout data.
- Player growth systems are separated by purpose: XP for run level, coins for in-run purchases, materials for upgrade/crafting sinks.
- Enemy, trap, and gimmick entries each state their gameplay purpose and reward interaction.
- Equipment examples are data-shaped and do not require a full inventory system to understand their role.

## Non-Goals

- No online economy.
- No player trading.
- No complex inventory grid.
- No procedural map generation for the first slice.
- No large crafting tree before the player controller, combat, and boss loop are playable.
- No multiple playable characters in the first implementation. The first slice defines one base character plus future archetype hooks.
- No cloud save. If material persistence is implemented, start with a small local profile only.

## Canonical First-Slice Terms

- **Run**: One attempt from Stage 1 through the boss or death.
- **XP**: Run-local experience dropped mostly by enemies. XP advances run level.
- **Run Level**: Temporary level inside the current run. Resets unless a later meta system explicitly preserves something.
- **Coin**: Run-local money used for shops, healing, card rerolls, or temporary purchases.
- **Material**: Named resource collected from stronger enemies, hidden objects, stage clears, or bosses. Intended for crafting or persistent upgrades.
- **Card**: Stage-clear or reward-screen upgrade choice that immediately changes the current run build.
- **Equipment**: Item occupying a defined slot and modifying stats or verbs while equipped.
- **Skill Node**: Upgrade in a branch. Nodes may be temporary run unlocks or persistent meta unlocks, but the data must state which.
- **Trap**: Harmful map object with predictable damage or control pressure.
- **Gimmick**: Interactive or moving map object that changes traversal, pacing, routing, or reward access.

## Related

- `docs/product/2d_platform_action_card_game_prd.md`
- `docs/architecture/FIRST_SLICE_ARCHITECTURE.md`
- `docs/design/PLAYER_CHARACTER_SYSTEMS.md`
- `docs/design/MAP_DATA_AND_VISUALIZATION.md`
- `docs/design/ENEMIES_TRAPS_GIMMICKS.md`
- `docs/data/FIRST_SLICE_DATA_README.md`
