---
type: plan
status: active
created: 2026-07-02
source: Split from docs/design/MOTION_TEST_BED_MVP_PLAN.md
scope: Final testbed clear gate, QA matrix, stop conditions, and handoff
related:
  - ../MOTION_TEST_BED_MVP_PLAN.md
  - ../MOTION_TEST_BED_SPEC.md
  - ./00_foundation_contracts.md
  - ./01_authored_lanes.md
  - ./02_combat_damage.md
  - ./03_interaction_input_ui.md
  - ./04_generated_landscape.md
---

# 05 - QA And Handoff

## Purpose

Make the testbed clear path meaningful and verify that future Stage01/Stage02/Stage03 work can safely build on it.

## Progress

Already true:

- [x] Earlier phase docs define focused acceptance checks.
- [x] `StageBase.complete_stage` and `ExitPortal` already support basic stage clear.

Still open:

- [ ] Final testbed exit does not prove that required validations were exercised.
- [ ] Final QA does not yet include camera-followed map traversal, climb traversal, or destructible obstacle coverage.
- [ ] No generated run clear/fail summary exists.
- [ ] No manual QA matrix exists for profile, ability, combat, interaction, input, and seed replay coverage.
- [ ] No final handoff format is defined for implementation completion.

## Tasks

### Phase 11 - Exit, Clear, And No-Soft-Lock Gate

Source owners touched: `StageBase.gd`, `ExitPortal.gd`, `MotionTestStage.gd`, `HUD.gd`, `SignalBus.gd`.

- [ ] **11.1** Decide whether authored lane completion is tracked by checkpoints, area triggers, interaction results, or generated summary.
- [ ] **11.2** Prevent final exit clear until required authored validations and generated mini-run are completed or explicitly skipped in debug mode.
- [ ] **11.3** Label debug skip actions in HUD/settings if any exist.
- [ ] **11.4** Show final clear summary with profile, ability flags, camera route status, seed, route mode, and required validations passed.
- [ ] **11.5** Add reset/restart route for failed validation.

Accept:

- [ ] Testbed clear implies movement, camera-followed traversal, climb traversal when enabled, destructibles, combat, interaction, input visibility, and generated route were exercised.
- [ ] Debug skip cannot be mistaken for normal clear.

Guard:

- [ ] Do not block the user behind a bug without a reset/reload path.

### Phase 12 - Verification, Tuning, And Handoff

Source owners touched: docs, optional test scripts, final scene/source changes.

- [ ] **12.1** Run Godot smoke command through `.\tools\godot.ps1`.
- [ ] **12.2** Manually test authored route with Warrior, Archer, and Assassin.
- [ ] **12.3** Manually test advanced route with ability off and on.
- [ ] **12.4** Manually test camera follow and camera bounds; confirm the whole map is not visible at once in default gameplay.
- [ ] **12.5** Manually test rope/ladder-like climb and wall traversal when enabled.
- [ ] **12.6** Manually test enemy contact damage, player attack, enemy defeat/reset, destructible obstacle break/reset, hazard damage, and player death/reload.
- [ ] **12.7** Manually test NPC/object prompt, interaction result, and prompt hiding.
- [ ] **12.8** Manually test binding guide/settings and confirm guide matches actual input map, including climb actions when enabled.
- [ ] **12.9** Manually test generated seeds for all generator profiles.
- [ ] **12.10** Replay one seed twice and compare route summary.
- [ ] **12.11** Run static guards: `rg` for duplicated input action strings, old dummy-only assumptions, generator-only damage paths, and destructible one-off paths.
- [ ] **12.12** Update `MOTION_TEST_BED_SPEC.md` only if implementation reveals a better durable rule.
- [ ] **12.13** Commit scoped batches; do not mix unrelated work.

Accept:

- [ ] Testbed can be launched and cleared by following in-game guidance.
- [ ] No required route soft locks are found in the manual profile pass.
- [ ] Camera-followed traversal, climb traversal, and destructible obstacle behavior are covered in manual QA.
- [ ] Generated route validation catches invalid layouts before play.
- [ ] Worktree is clean after final commit.

Guard:

- [ ] Do not treat a single happy-path generated seed as enough validation.

## Verification

Inner-loop checks:

- [ ] Use `.\tools\godot.ps1 --path . --headless --quit` after script or scene ownership changes when practical.
- [ ] Use Godot editor/manual launch for movement feel, route dimensions, and UI visibility.
- [ ] Use targeted `rg` checks after input, generator, or damage ownership changes.
- [ ] Use one or two known seeds for fast generator iteration.

Batch gates:

- [ ] After authored lanes: manually clear authored movement route with all three profiles.
- [ ] After combat/damage: manually damage and kill/reset real enemy.
- [ ] After interaction/input: confirm binding guide displays actual input map.
- [ ] After generated assembly: regenerate the lane three times and confirm old nodes/signals do not remain.
- [ ] After miniature loop: replay the same seed twice and compare route summary.

Final gates:

- [ ] Godot smoke command through `.\tools\godot.ps1`.
- [ ] Full manual testbed clear with least-mobile required profile.
- [ ] Manual camera-follow check: full map is not visible at once in default gameplay.
- [ ] Manual climb/destructible check.
- [ ] Manual generated seed matrix: movement-only, combat, hazard, mixed, edge/invalid.
- [ ] UI check at 1280x720 and one narrower viewport if supported.
- [ ] `git diff --check`.
- [ ] Final commit with scoped changed files.

## Error Handling

- Missing Godot runtime: use `.\tools\godot.ps1` resolution first; report the missing runtime and do not edit around it.
- Conflicting docs: prefer current user corrections, then `MOTION_TEST_BED_SPEC.md`, then PRD.
- Failed generated route validation: show the failure reason and keep the previous valid route or empty generated lane.
- Generation retry exhaustion: stop after a bounded retry count and show invalid status.
- Failed manual movement route: adjust metric limits or platform dimensions, then retest with the least-mobile profile.
- Binding conflict: reject duplicate remap or label remap as deferred.
- Scene corruption risk: make small scene edits or script-generated layout helpers, then smoke test.
- Ambiguous ability scope: implement as debug-only testbed ability and label it clearly until card/skill systems own it.

## Risks

- A clear portal can hide incomplete validation if route gates are too weak.
- QA can become too slow if full checks are rerun after every small edit.
- Final docs can drift if implementation discovers new rules but the spec is not updated.

## Goal Completion Criteria

- [ ] Required artifacts exist: authored validation lanes plus generated miniature game lane.
- [ ] HUD or settings UI explains all required controls in-game.
- [ ] Movement obstacles are tied to profile metrics.
- [ ] Default gameplay camera follows the player through a route larger than one viewport.
- [ ] Rope/ladder-like climb and wall traversal are testable or explicitly deferred.
- [ ] Real enemy combat, hazard damage, and non-exit interaction are all testable.
- [ ] Attack-destructible obstacles are testable and route-changing.
- [ ] Generated landscape can be created from a seed, validated, played, replayed, and regenerated.
- [ ] Same seed/profile/ability/mode produces the same route summary.
- [ ] Invalid generated routes are rejected or visibly reported.
- [ ] Exit/clear flow proves the required path was exercised.
- [ ] Required checks and manual test matrix are recorded in the final handoff.

## Goal Stop Conditions

Complete the goal when:

- [ ] The miniature testbed is playable end to end.
- [ ] All final gates pass or any skipped gate has a concrete reason.
- [ ] No required implementation work remains for this plan.

Ask the user when:

- [ ] A choice would change product direction, such as making double jump default, changing canonical controls, adding external assets, or promoting full procedural region generation into this phase.
- [ ] A destructive cleanup would remove existing user-authored work.

Mark blocked when:

- [ ] The same runtime/tool blocker prevents meaningful progress for three consecutive goal turns and no local fallback exists.

Do not stop when:

- [ ] The work is large but still progressing.
- [ ] A validation failure points to a concrete fix.
- [ ] A later phase would benefit from polish but the current phase has a clear next task.

## Next Steps

- [ ] Use this doc only after `04_generated_landscape.md` has produced a playable generated route.
- [ ] Run the final QA matrix.
- [ ] Update `MOTION_TEST_BED_SPEC.md` only for durable rule changes discovered during implementation.
- [ ] Final response should summarize changed files, checks run, skipped checks, and remaining risk.

## Handoff Prompt

```text
Goal: Finish QA and handoff for the Cardborne Platformer motion testbed miniature game.

Read first:
- AGENTS.md
- docs/design/MOTION_TEST_BED_MVP_PLAN.md
- docs/design/testbed-plan/05_qa_and_handoff.md
- docs/design/MOTION_TEST_BED_SPEC.md

Produce:
- Final QA result for authored lanes and generated landscape mode.
- Clear list of checks run and any skipped checks.
- Scoped commits only.

Stop when:
- The testbed can be launched, understood from in-game UI, cleared through required authored and generated routes, and replayed by seed.
```
