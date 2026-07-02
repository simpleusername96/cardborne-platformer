---
type: plan
status: active
created: 2026-07-02
source: Split from docs/design/MOTION_TEST_BED_MVP_PLAN.md
scope: Character-aware authored validation lanes for the motion test bed
related:
  - ../MOTION_TEST_BED_MVP_PLAN.md
  - ../MOTION_TEST_BED_SPEC.md
  - ./00_foundation_contracts.md
---

# 01 - Authored Lanes

## Purpose

Replace the freeform placeholder map with labeled, character-aware lanes that prove movement behavior before generated routes or production stages are built. The default gameplay camera must follow the player through a route larger than one viewport; the whole playable map should not be visible at once.

## Progress

Already true:

- [x] `scenes/stages/MotionTestStage.tscn` exists.
- [x] `StageBase` can spawn the player.
- [x] The current scene has basic platforms, a hazard, a dummy, and an exit.

Still open:

- [ ] The map is not divided into validation lanes.
- [ ] Platform heights and gaps are not derived from movement metrics.
- [ ] Jump buffer, coyote time, one-way drop, dash reach, and advanced movement are not explicitly tested.
- [ ] Rope climb, wall climb, wall slide, and wall jump are not explicitly tested or visibly deferred.
- [ ] The current map does not prove camera-followed traversal through an area larger than the viewport.
- [ ] Required route gating does not prove that lanes were exercised.
- [ ] Recovery paths under required failures are incomplete.

## Tasks

### Phase 2 - Authored Lane Rebuild

Source owners touched: `scenes/stages/MotionTestStage.tscn`, new `scripts/stages/MotionTestStage.gd`, optional lane label helper scene/script.

- [ ] **2.1** Add a testbed-specific stage controller if lane state, labels, gates, or generated lane orchestration do not belong in `StageBase`.
- [ ] **2.2** Split the scene into lane containers:
  - spawn and controls,
  - movement metrics,
  - jump behavior,
  - advanced movement,
  - combat,
  - enemy behavior,
  - hazard/damage,
  - NPC/object interaction,
  - input/settings,
  - exit,
  - generated landscape placeholder.
- [ ] **2.3** Add visible lane labels and compact objective text that do not cover the player.
- [ ] **2.4** Build a safe flat start area for acceleration, deceleration, crouch, facing, and debug profile switching.
- [ ] **2.5** Make the route larger than the default 1280x720 viewport and add camera follow plus camera bounds.
- [ ] **2.6** Add jump height markers and horizontal reach markers using the metric helper.
- [ ] **2.7** Add forgiving and threshold gaps for ground jump.
- [ ] **2.8** Add jump+dash gap using conservative required-route limits.
- [ ] **2.9** Add a coyote-time ledge and a jump-buffer landing test.
- [ ] **2.10** Add one-way platform drop-through with safe recovery below.
- [ ] **2.11** Add rope or ladder-like climb route when enabled, with clear mount, climb, dismount, drop/cancel, and recovery behavior.
- [ ] **2.12** Add wall climb, wall slide, or wall-jump route when enabled, with clear entry, exit, and failure recovery.
- [ ] **2.13** Add an advanced movement route that is passable only when the relevant ability flag is enabled.
- [ ] **2.14** Mark unavailable advanced movement visibly when the ability flag is off.
- [ ] **2.15** Add recovery paths under every required fall.
- [ ] **2.16** Gate exit progression so the player cannot walk directly to the portal without exercising the required route.

Accept:

- [ ] Warrior or the current least-mobile required profile can clear the required authored route.
- [ ] Archer and Assassin can clear without route dimensions hiding control problems.
- [ ] Optional advanced route is clearly optional and does not block clear.
- [ ] Default camera follows the player, and the full playable route is not visible at once.
- [ ] Rope/climb and wall traversal are either testable or explicitly blocked/labeled as deferred.
- [ ] No required route creates a soft lock after falling.
- [ ] Lane labels and objectives remain readable at 1280x720.

Guard:

- [ ] No required gap exceeds the generated metric limit unless a documented manual test proves it.
- [ ] Route design must not be tuned only for the fastest profile.
- [ ] Do not use an always-zoomed-out overview camera as the default gameplay view.
- [ ] This phase should not add production Stage01/Stage02/Stage03.

## Verification

- [ ] Manual clear with the least-mobile profile.
- [ ] Manual clear with the other two profiles.
- [ ] Manual test of coyote time, jump buffer, dash gap, one-way drop, crouch, and advanced route ability-off/on states.
- [ ] Manual camera test confirms the route scrolls and camera bounds do not show void.
- [ ] Manual climb test confirms rope/ladder-like climb and wall traversal if enabled.
- [ ] UI overlap check at 1280x720.
- [ ] `git diff --check` before commit.

## Risks

- Overbuilding the lane scene can delay the first playable proof.
- Too much text in the scene can cover movement/combat.
- Lanes built by eye will not protect future generated landscape work.
- An overview camera can hide route readability and traversal problems.

## Next Steps

- [ ] Commit after authored movement lanes are passable and labeled.
- [ ] Move to `02_combat_damage.md`.
