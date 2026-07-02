---
type: plan
status: active
created: 2026-07-02
source: Split from docs/design/MOTION_TEST_BED_MVP_PLAN.md
scope: Motion test bed foundation contracts, baseline launch, movement metrics, and ability flags
related:
  - ../MOTION_TEST_BED_MVP_PLAN.md
  - ../MOTION_TEST_BED_SPEC.md
  - ../../product/2d_platform_action_card_game_prd.md
  - ../../architecture/FIRST_SLICE_ARCHITECTURE.md
---

# 00 - Foundation Contracts

## Purpose

Build the shared foundation that every later testbed slice consumes: launch path, profile stats, movement metrics, ability flags, input actions, signals, and HUD debug visibility.

This phase should not build broad stage content. It should make the rules measurable and visible.

## Progress

Already true:

- [x] `project.godot` defines `SignalBus`, `RunState`, and `Game` autoloads.
- [x] `Game.ensure_input_map` creates the current input actions.
- [x] `RunState` loads three profiles and publishes effective stats.
- [x] `PlayerController` consumes `RunState.get_effective_stats()`.
- [x] `HUD` shows health, profile, stage, prompt, status, and a basic control guide.
- [x] `StageBase` spawns a player and emits stage clear signals.

Still open:

- [ ] Godot launch baseline and known warnings are not recorded for this implementation pass.
- [ ] Movement metrics are not computed by a reusable helper.
- [ ] Required route limits are not derived from the least-mobile profile.
- [ ] Testbed ability flags such as double jump, extra dash, rope climb, wall climb, wall slide, or wall jump are not represented.
- [ ] HUD does not show metrics or ability flags.
- [ ] Debug shortcuts are not clearly labeled as debug-only.

## Tasks

### Phase 0 - Baseline Guard And Run Path

- [ ] **0.1** Run `.\tools\godot.ps1 --path . --headless --quit` or the nearest available Godot smoke command.
- [ ] **0.2** Confirm the fastrun manager command launches `D:\npjt\cardborne-platformer` through `.\tools\godot.ps1 --path .`.
- [ ] **0.3** Record known baseline Godot warnings if any appear.
- [ ] **0.4** Confirm `project.godot` still lists `SignalBus`, `RunState`, and `Game` autoloads.
- [ ] **0.5** Confirm the worktree has no unrelated changes before implementation starts.

Accept:

- [ ] Project opens or headless smoke exits without missing script errors.
- [ ] Manual launch path is known before scene edits begin.

Guard:

- [ ] Do not start large scene edits if the baseline cannot boot.

### Phase 1 - Movement Metrics And Ability Flags

Source owners touched: `scripts/player/CharacterProfile.gd`, a new metric helper under `scripts/player/` or `scripts/stages/`, `scripts/autoload/RunState.gd`, `scripts/autoload/SignalBus.gd`, `scripts/ui/HUD.gd`.

- [ ] **1.1** Add one movement metric helper that computes apex height, airtime, single-jump reach, dash reach, and jump+dash reach from an effective stat dictionary.
- [ ] **1.2** Add conservative required-route limits for gap width and ledge height derived from the least-mobile required profile.
- [ ] **1.3** Add testbed ability flags such as `double_jump_enabled`, `extra_dash_enabled`, `air_dash_enabled`, `rope_climb_enabled`, `wall_climb_enabled`, `wall_slide_enabled`, and `wall_jump_enabled`.
- [ ] **1.4** Keep ability flag ownership narrow: prefer `RunState` or a small player-build adapter, not duplicated fields across stage/UI/player scripts.
- [ ] **1.5** Emit a signal when metrics or ability flags change.
- [ ] **1.6** Add HUD/debug display for active profile, ability flags, jump height, jump reach, dash reach, and jump+dash reach.
- [ ] **1.7** Label profile cycle and ability toggles as debug-only until real character select or card/skill systems own them.
- [ ] **1.8** Add a short note in code or debug UI identifying the current least-mobile required profile.
- [ ] **1.9** Define whether climb traversal uses existing movement actions or new canonical input actions before UI work starts.

Accept:

- [ ] Changing the active profile updates displayed movement metrics.
- [ ] Authored lane code and generator code can read the same metric output.
- [ ] Debug ability flags are visible and cannot be confused with final progression.

Guard:

- [ ] Movement formulas exist in one helper, not repeated in stage and generator code.
- [ ] UI observes state; it does not own movement rules.

## Verification

- [ ] Godot smoke command succeeds after script changes.
- [ ] Manual launch shows profile, metrics, and ability flags in the HUD/debug UI.
- [ ] Manual launch shows climb-related ability flags when they are enabled or explicitly deferred.
- [ ] `rg` confirms movement formulas are not duplicated in multiple owners.
- [ ] `git diff --check` passes before committing.

## Risks

- Metrics can drift from actual controller behavior because acceleration, jump cut, coyote time, and dash timing affect real reach.
- Ability flags can become fake progression if they are not clearly labeled debug-only.
- Putting metrics in UI or stage code would create duplication before generation work starts.

## Next Steps

- [ ] Commit this phase once metrics and ability flags are visible.
- [ ] Move to `01_authored_lanes.md`.
