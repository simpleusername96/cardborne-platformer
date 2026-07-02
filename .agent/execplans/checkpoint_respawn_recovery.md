---
type: plan
status: done
created: 2026-07-03
source: User request to implement save-point respawn after falling or dying
scope: Runtime checkpoint and fall recovery for the motion test bed
related:
  - ../../AGENTS.md
  - ../PLANS.md
  - ../../docs/design/testbed-plan/01_authored_lanes.md
  - ../../docs/design/testbed-plan/02_combat_damage.md
  - ../../docs/design/testbed-plan/04_generated_landscape.md
---

# Checkpoint Respawn Recovery

## Why / Context

The current motion test bed reloads the whole stage after player death and has no automatic recovery when the player falls below the route. That is not enough for a playable platformer testbed because it hides soft-locks, resets generated content unnecessarily, and makes traversal iteration slow.

## Scope / Non-scope

In scope:

- Stage-local checkpoint state.
- Checkpoint trigger objects for authored and generated route sections.
- Fall reset zone below the playable route.
- Death recovery through the same checkpoint path.
- Player state reset for velocity, dash/climb/attack timers, one-way drop, camera, and temporary invulnerability.

Out of scope:

- Persistent save files.
- Bonfire/rest UI.
- Full enemy/destructible lane reset.
- Economy, rewards, or checkpoint upgrades.

## Assumptions

- "Save point" means stage-local respawn checkpoint for this pass.
- Respawn restores health to full in the testbed so testers can keep validating movement/combat.
- Generated route seed/content should survive death or fall unless the tester presses regenerate.

## Proposed Design

- `StageBase` owns the current checkpoint ID/position and the public `set_checkpoint` / `respawn_player` contract.
- `Game` asks the active stage to respawn after death and only reloads as a fallback.
- `PlayerController` exposes `respawn_at` so stage flow can reset controller state without duplicating player internals.
- `StageCheckpoint` and `FallResetZone` are reusable stage contracts under `scripts/stages/`.
- `MotionTestStage` places checkpoints before major lanes and a wide fall reset zone below the full camera-bounded route.

## Milestones

1. [x] Add stage respawn contract and player reset API.
2. [x] Add checkpoint and fall reset stage objects.
3. [x] Place recovery objects in authored and generated routes.
4. [x] Validate Godot import/runtime smoke and diff hygiene.

## Progress

- Death now respawns through the active stage checkpoint contract when available.
- Falling below the motion test route triggers a stage-local fall reset zone.
- Authored lanes and generated seed route now place checkpoint triggers.
- Regenerate/replay moves the checkpoint to the generated start without rebuilding the full app state.

## Test Plan

- [x] `.\tools\godot.ps1 --path . --headless --import`
- [x] `.\tools\godot.ps1 --path . --headless --quit-after 3`
- [ ] Manual: touch checkpoints, fall below route, die from enemy/hazard, confirm respawn at latest checkpoint.
- [ ] Manual: regenerate/replay seed, confirm generated start checkpoint and same seed content survive fall/death.
- [x] `git diff --check`

## Rollback / Safety

- If checkpoint recovery breaks a stage, `Game` still has a reload fallback when the active stage lacks `respawn_player_after_defeat`.
- New checkpoint/fall objects are additive stage contracts.

## Risks

- Enemy/destructible partial reset remains out of scope, so repeated combat tests may still need manual stage reload.
- Fall reset zones must be wide enough for generated route bounds.

## Open Questions

- Whether falling should cost health in production stages remains undecided.

## Decision Notes

- For this testbed pass, falling does not cost health; both fall and death restore full health at the latest checkpoint.
