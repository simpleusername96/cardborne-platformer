---
type: plan
status: active
created: 2026-07-02
source: Split from docs/design/MOTION_TEST_BED_MVP_PLAN.md
scope: Seeded generated landscape and miniature game loop
related:
  - ../MOTION_TEST_BED_MVP_PLAN.md
  - ../MOTION_TEST_BED_SPEC.md
  - ./00_foundation_contracts.md
  - ./01_authored_lanes.md
  - ./02_combat_damage.md
  - ./03_interaction_input_ui.md
  - ../PROCEDURAL_REGION_GENERATION.md
---

# 04 - Generated Landscape

## Purpose

Add the testbed's miniature game mode: deterministic segment-template terrain generation, camera-followed multi-screen route validation, runtime assembly, seed replay, regeneration, and clear/fail summary.

This is not the full procedural region graph runtime. It is a small playable landscape generator inside the testbed.

## Progress

Already true:

- [x] High-level procedural region design exists in `PROCEDURAL_REGION_GENERATION.md`.
- [x] Python/data prototypes exist for region graph planning.
- [x] Runtime combat, interaction, and movement contracts are planned or built by earlier phase docs.

Still open:

- [ ] No runtime segment template contract exists.
- [ ] No generated route plan or validation status exists.
- [ ] No deterministic runtime RNG path exists for testbed terrain.
- [ ] No generated lane root or terrain builder exists.
- [ ] No generated segment contract exists for camera span, climbables, or destructible obstacles.
- [ ] No UI exists for seed, mode, regenerate, or replay.
- [ ] No clear/fail summary exists for the miniature run.

## Tasks

### Phase 8 - Segment Template Data Contract

Source owners touched: new scripts/resources under `scripts/stages/testbed/` or `scripts/stages/`, optional data under `data/testbed/`.

- [ ] **8.1** Create a `SegmentTemplate` contract with ID, width, height delta, required ability, gap range, ledge range, safe landing width, camera span, enemy budget, hazard budget, interactable budget, destructible budget, and critical/optional eligibility.
- [ ] **8.2** Create a generated route plan shape with seed, profile ID, ability flags, generator mode, segment IDs, placements, validation status, and failure reason.
- [ ] **8.3** Add generator profiles: `movement_only`, `combat_route`, `hazard_route`, and `mixed_mini_run`.
- [ ] **8.4** Encode initial templates: flat safe, low step, standard jump, near-limit jump, jump+dash, one-way vertical, rope/ladder climb, wall climb/wall-jump, optional advanced branch, destructible barrier, combat pocket, hazard pocket, interaction pocket, exit.
- [ ] **8.5** Add validation rules that compare segment requirements against movement metrics and enabled abilities.
- [ ] **8.6** Add deterministic RNG from seed and generator mode.
- [ ] **8.7** Add a minimum route span rule so valid generated routes cannot fit entirely in one default viewport.

Accept:

- [ ] Same seed/profile/ability/mode produces the same route plan.
- [ ] Invalid segment combinations report a reason before instantiation.
- [ ] Critical path templates never require disabled optional abilities.
- [ ] Valid generated routes exceed the minimum viewport-traversal requirement.

Guard:

- [ ] Do not use arbitrary tile noise for this testbed generator.
- [ ] Do not depend on `tools/generate_region_graph.py` at runtime.

### Phase 9 - Runtime Generated Landscape Assembly

Source owners touched: terrain builder under `scripts/stages/testbed/`, `MotionTestStage.gd`, generated lane container in `MotionTestStage.tscn`.

- [ ] **9.1** Add a generated-lane root node that can be cleared and rebuilt safely.
- [ ] **9.2** Add a terrain builder that creates placeholder collision and visual nodes for each segment.
- [ ] **9.3** Add spawn position and exit position from the route plan.
- [ ] **9.4** Instantiate enemy placements through enemy scenes.
- [ ] **9.5** Instantiate hazard placements through shared hazard scripts.
- [ ] **9.6** Instantiate interactable placements through shared interactable scenes.
- [ ] **9.7** Instantiate destructible placements through shared destructible obstacle scenes.
- [ ] **9.8** Instantiate climbable placements through shared climbable or traversal scenes.
- [ ] **9.9** Add camera bounds for the generated route.
- [ ] **9.10** Add safe recovery areas and fall catch/reset behavior.
- [ ] **9.11** Add generated route labels or compact debug overlay for segment IDs and validation status.

Accept:

- [ ] Generated lane is playable from spawn to exit for valid route plans.
- [ ] Enemies, hazards, interactables, and exit all use shared runtime contracts.
- [ ] Climbables and destructibles use shared runtime contracts when generated.
- [ ] Regenerating does not leave duplicate old nodes or stale signals.

Guard:

- [ ] Generated node cleanup must be scoped to the generated-lane root only.

### Phase 10 - Miniature Game Loop

Source owners touched: `MotionTestStage.gd`, `RunState.gd`, `SignalBus.gd`, `HUD.gd`, `SettingsPopup.gd` or new testbed panel.

- [ ] **10.1** Add UI controls for generator mode, seed entry, random seed, regenerate, and replay same seed.
- [ ] **10.2** Track active seed, selected profile, ability flags, route length, viewport spans, segment list, enemy count, hazard count, interactable count, destructible count, validation status, clear/fail status, and clear time.
- [ ] **10.3** Add route start/reset behavior that respawns the player at generated spawn.
- [ ] **10.4** Add clear condition through generated exit.
- [ ] **10.5** Add fail/death summary and replay/regenerate choices.
- [ ] **10.6** Reject invalid generation with visible reason or retry within a bounded retry count.
- [ ] **10.7** Add manual test seed list: one movement-only seed, one combat seed, one hazard seed, one mixed seed, and one invalid or edge-case seed.

Accept:

- [ ] A tester can enter a seed, generate a landscape, play it, clear or fail, replay same seed, and generate a new seed.
- [ ] Same seed reproduces the same route under the same profile/ability/mode.
- [ ] Invalid route reasons are visible and not silently spawned.
- [ ] Generated route is played through a following camera, not a full-map overview.

Guard:

- [ ] The miniature loop must not hide failures by auto-skipping required content.

## Verification

- [ ] Unit-like script check or manual route summary check proves deterministic route plans.
- [ ] Manual generation for `movement_only`, `combat_route`, `hazard_route`, and `mixed_mini_run`.
- [ ] Replay same seed twice and compare route summary.
- [ ] Regenerate three times and confirm old generated nodes/signals do not remain.
- [ ] Manual generated route clear with the least-mobile required profile.
- [ ] Manual generated route camera test confirms the full route is not visible at once.
- [ ] Manual generated climb/destructible tests when those segment types are enabled.
- [ ] `git diff --check` before commit.

## Risks

- This can sprawl into full procedural world generation. Keep it segment-template based.
- Invalid generated layouts can waste tester time if they spawn silently.
- Generated enemies/hazards can bypass shared contracts if created as generator-only actors.
- Generated routes can look valid in an overview while failing in the actual camera-followed view.

## Next Steps

- [ ] Commit after seeded miniature generated routes are playable and replayable.
- [ ] Move to `05_qa_and_handoff.md`.
