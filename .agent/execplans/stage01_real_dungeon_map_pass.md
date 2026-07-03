---
type: plan
status: done
created: 2026-07-03
source: User request to move from the motion testbed toward a real map
scope: First Stage01-style real dungeon route inside the current playable Godot entrypoint
related:
  - ../../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/2d_platform_action_card_game_prd.md
  - ../../docs/product/FIRST_SLICE_EXPANSION.md
  - ../../docs/design/MOTION_TEST_BED_SPEC.md
  - ../../docs/design/MAP_DATA_AND_VISUALIZATION.md
  - ../../docs/design/PROCEDURAL_REGION_GENERATION.md
  - ../../data/design/first_slice/stage_layouts.json
---

# Stage01 Real Dungeon Map Pass

## Why / Context

The motion testbed now proves movement, attack visibility, enemy contracts, interaction, destructibles, checkpoints, and seeded generated terrain, but the authored route still reads like a validation lane. The next step is to make the default playable route feel like an actual side-view dungeon map: camera-followed, enclosed, multi-screen, movement-aware, and built from rooms, shafts, branches, combat pockets, and gates.

This pass uses Stage 01 "Lower Ruins Ascent" from the first-slice map data as the design seed, while preserving the existing motion testbed contracts so no foundation work is lost.

## Scope / Non-scope

In scope:

- Rebuild the current authored route as a Stage01-style lower-ruins dungeon route.
- Keep the current Godot entrypoint playable without adding a new menu or stage selector.
- Preserve required contracts: camera follow, checkpoints, movement metrics, rope climb, visible wall-traversal deferral, combat, destructible gate, hazard, non-exit interaction, generated seed route, and exit gate.
- Add stronger dungeon enclosure: rear wall, ceiling mass, side mass, lower masonry, local room frames, pillars, alcoves, and recovery floors.
- Shape the route around the least-mobile required profile.

Out of scope:

- Full production Stage01/Stage02/Stage03 scenes and stage manager flow.
- Final tile art, sprites, animation sets, audio, or external assets.
- Full procedural region runtime with key/gate/shortcut mission graph.
- Shop/rest, card rewards, boss map, or persistent materials.
- Full wall climb/slide/jump mechanics.

## Assumptions

- The first implementation can live inside `MotionTestStage` because that is the current boot path and already owns the shared testbed contracts.
- "Real map" means a playable stage-like route, not final art polish.
- The critical route should remain clearable by Warrior; optional branches may hint at stronger movement.
- Text labels can remain while this is still a testbed, but the spatial layout should carry more of the route readability.

## Proposed Design

- Replace the straight authored lane with a lower-ruins route:
  - entrance corridor,
  - timing ledges,
  - dash gap,
  - central rope shaft,
  - optional high branch,
  - combat hall,
  - breakable gate,
  - hazard trench,
  - NPC/cache interaction,
  - bridge into the generated seed route.
- Add visual room shells and masonry props around the authored route so bottom and side space no longer reads as empty void.
- Keep generated landscape after the authored dungeon route for miniature-game seed proof.
- Keep `MotionTestStage` as the owner of this testbed-specific orchestration; do not move stage-flow behavior into `StageBase`.

## Milestones

1. [x] Create this ExecPlan.
2. [x] Rebuild the authored route into a Stage01-style dungeon path.
3. [x] Add local dungeon framing helpers and route dressing.
4. [x] Preserve generated route integration and final clear gate.
5. [x] Run Godot import/runtime validation and static checks.
6. [x] Run code quality audit and make small safe fixes.
7. [x] Mark this plan done and commit.

## Test Plan

- `.\tools\godot.ps1 --path . --headless --import`
- `.\tools\godot.ps1 --path . --headless --quit-after 3`
- `.\tools\godot.ps1 --path . --script res://tools/capture_ui_screenshots.gd` if screenshot capture remains compatible.
- Static checks for stale one-screen/lane-only assumptions.
- `git diff --check`

## Validation Results

- Godot import completed without reported script errors.
- Short headless runtime completed without reported script errors.
- UI screenshot capture completed and produced desktop/narrow HUD captures under `.codex-runtime/uiux/`.
- Desktop screenshot confirmed the route now opens as a lower-ruins dungeon space with enclosed walls, ceiling mass, lower masonry, local room framing, and the new Stage01-style route label.
- Static search found no stale old authored platform names from the prior straight-lane route.
- `git diff --check` passed with only the existing Windows line-ending notice for `scripts/stages/MotionTestStage.gd`.
- Code quality audit found no further small safe fixes after the label wording was changed from a feature explanation to a route objective.

## Rollback / Safety

- The pass is mostly contained in `scripts/stages/MotionTestStage.gd`.
- Existing shared contracts and scene boot path remain in place.
- If the route breaks, rollback can restore the previous authored-route body without touching player, combat, enemy, UI, or autoload systems.

## Risks

- A more organic route can hide the original validation purpose if required checks are not still reachable.
- Larger decorative framing can occlude labels, enemies, or platforms.
- Vertical camera bounds can expose top or bottom void if route bounds are too shallow.
- The current generated route remains simplified and should not be mistaken for the final procedural region runtime.

## Open Questions

- Whether the next pass should split this into a production `Stage01.tscn` instead of continuing to evolve `MotionTestStage`.
- Whether wall traversal should be promoted from visible deferral to implemented movement before Stage01 production content.
- Whether shop/rest should become the next room type after this map pass.

## Decision Notes

- Use current docs as source of truth; do not create a parallel large checklist.
- Treat this as the first real-map implementation pass, not final Stage01 production completion.
