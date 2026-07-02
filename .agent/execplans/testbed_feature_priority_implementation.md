---
type: plan
status: done
created: 2026-07-02
source: User request to use FEATURE_PRIORITY.md to craft the test bed
scope: Immediate feature-priority implementation for Motion Test Bed
related:
  - ../../AGENTS.md
  - ../PLANS.md
  - ../../docs/design/testbed-plan/FEATURE_PRIORITY.md
  - ../../docs/design/testbed-plan/00_foundation_contracts.md
  - ../../docs/design/testbed-plan/01_authored_lanes.md
  - ../../docs/design/testbed-plan/02_combat_damage.md
  - ../../docs/design/testbed-plan/03_interaction_input_ui.md
  - ../../docs/design/testbed-plan/04_generated_landscape.md
---

# Testbed Feature Priority Implementation

## Why / Context

The active feature priority matrix says the next testbed pass must prove shared contracts through a playable miniature test stage, not merely document them. This implementation should close the immediate `Now` and `Now, simplified` items without pulling in full production stages, card rewards, shop/rest rooms, or boss content.

## Scope / Non-scope

In scope:

- Movement metrics and debug ability flags visible to the player.
- Camera-followed route larger than one viewport.
- Authored movement lanes with jump, dash, one-way, climb, optional double-jump, combat, hazard, destructible, NPC/object interaction, and exit path.
- One reusable enemy baseline, one hazard contract, one destructible obstacle contract, and one climbable contract.
- Input binding guide driven by the actual `InputMap`.
- Minimal deterministic generated route with random/replay commands and clear/fail status.

Out of scope:

- Full wall traversal polish.
- Persistent key remapping.
- Production procedural region graph.
- Production Stage01/Stage02/Stage03, cards, shop/rest, boss, final art/audio/localization.

## Assumptions

- The testbed is a separate validation context, not production stage content.
- Three playable characters remain profile resources on the shared controller for this pass.
- Double jump and rope climb are debug testbed abilities; wall traversal is visibly deferred.
- Placeholder shapes are preferred until the movement contracts are trusted.

## Proposed Design

- Add a single movement metric helper under `scripts/player/` so UI, authored lanes, and generation share the same calculations.
- Keep ability flags in `RunState`; the player consumes them, while UI observes them.
- Convert `MotionTestStage` into a runtime stage controller that builds authored and generated lanes from reusable stage/enemy contracts.
- Keep generated landscape segment-template based and deterministic from seed, profile, and ability state.
- Keep HUD/settings compact: visible controls and metrics, no fake full remap UI.

## Milestones

1. [x] Add movement metric, ability flag, input summary, and testbed signals.
2. [x] Add reusable climbable, hazard, destructible, interactable, enemy contracts.
3. [x] Rebuild `MotionTestStage` as camera-followed authored lanes plus generated route.
4. [x] Update HUD/settings to expose controls, metrics, flags, seed/replay status, and deferred features.
5. [x] Validate with Godot smoke checks, UI screenshots, quality pass, and a scoped commit.

## Progress

- Implemented the immediate feature-priority pass.
- Kept wall traversal and persistent remapping visibly deferred.
- Confirmed fastrun already stores the Godot launch command for `D:\npjt\cardborne-platformer`.

## Test Plan

- [x] `.\tools\godot.ps1 --path . --headless --import`
- [x] `.\tools\godot.ps1 --path . --headless --quit-after 3`
- [x] Render/check HUD and settings at desktop and narrow viewport with `res://tools/capture_ui_screenshots.gd`.
- [ ] Manual route checks: movement, jump, dash, climb, double jump, enemy, hazard, destructible, NPC interact, generated seed replay.
- [x] `git diff --check`

## Rollback / Safety

- New contracts are additive and responsibility-shaped.
- Existing `StageBase`, `Interactable`, and damage contracts remain the shared base.
- If generated route assembly breaks, it can be disabled from `MotionTestStage.gd` without changing player/combat contracts.

## Risks

- Generated route work can sprawl into full procedural generation; keep it a small segment-template loop.
- HUD can become cluttered; keep text compact and verify narrow layout.
- Climb traversal can destabilize the controller; keep it isolated to climbable overlap and debug flags.

## Open Questions

- Persistent remapping and full wall traversal remain deferred unless the user promotes them into immediate scope.

## Decision Notes

- Use the feature-priority document as the immediate implementation boundary and leave Later items visibly deferred in-game.
