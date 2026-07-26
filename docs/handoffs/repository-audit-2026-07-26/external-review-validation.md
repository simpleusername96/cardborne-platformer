---
type: evidence
status: active
created: 2026-07-26
source: Codex reconciliation against the local repository
topic: Validation of Claude's Cardborne repository audit
baseline: faf8dfc4e85f129913ea38423a143d681a795f7c
related:
  - external-review-raw.md
  - external-model-prompt.md
---

# Claude Audit Validation

## Verdict

Claude found several real release-confidence gaps and four plausible
spec/runtime inconsistencies. Its performance conclusion is directionally
useful, but its validator inventory and several coverage claims are unreliable.
The raw report must not be used as an execution plan without the corrections
below.

## Accepted

| Claim | Verdict | Local evidence |
| --- | --- | --- |
| No current release-qualified rendered performance result exists | Accept | `scripts/performance/vehicle_performance_recorder.gd` requires a focused, non-headless sample of at least 60 seconds. `.agents/vehicle-performance-stabilization-evidence.md:99-113` records a qualifying-length run that was disqualified by focus and clean 30-second regression samples that are intentionally non-authoritative. |
| Hit-flash duration differs from the product spec | Accept | `docs/product/vehicle_game_spec.md:89` says 0.18 seconds; `scripts/vehicle/vehicle_run.gd:96` sets `PLAYER_HIT_FLASH_DURATION := 0.20`. |
| Boss arrival can violate the documented 1200-pixel minimum | Accept | `docs/product/vehicle_game_spec.md:228` requires at least 1200 pixels when the field permits it; `scripts/vehicle/vehicle_run.gd:3673-3674` accepts 900–1500 pixels before fallback. |
| The interruptible boss signature can recur during one fight | Accept | The spec says exactly one nonadjacent signature startup per fight at `docs/product/vehicle_game_spec.md:192`. `VehicleBossRuntime.select_direct()` cycles phase sequences and has no fight-level consumed-signature flag. |
| Stage title keys are field-agnostic | Accept with product clarification | `scripts/vehicle/stages/vehicle_combat_stages.gd:12-15` always uses `STAGE_DROWNED_RUINS_*`, while a run can select any of three fields. The selected field name is shown elsewhere, so the defect is incorrect stage naming rather than missing field identity everywhere. |
| `vehicle_run.gd` concentrates substantial orchestration responsibility | Accept | The file is 5,394 lines and directly coordinates player, combat, boss, progression, UI, rendering snapshots, debug fixtures, and transitions. Decomposition should follow change pressure and ownership, not line count alone. |
| Korean and English localization cells are complete | Accept | `localization/vehicle_stage.csv` has 594 lines including the header, and the existing localization validator covers both locales. |

## Modified

| Claude claim | Corrected conclusion |
| --- | --- |
| `vehicle_run.gd` has 158 methods and 53 preloaded dependencies | The current file has 234 top-level `func` declarations and 48 `preload(` calls. The maintainability concern remains, but Claude's counts are wrong. |
| The headless pressure profiler is the only existing performance measurement | False as written. `vehicle_performance_recorder.gd` records complete rendered-frame distributions, render CPU/GPU timing, focus/headless qualification, and 60-second authority. Several rendered samples are documented. The real gap is that no current clean sample satisfies every authority condition. |
| Four validators merely restate constants | Overstated. `validate_vehicle_run_difficulty.gd` verifies difficulty propagation, active-run locking, quotas, restart behavior, and settings isolation. `validate_vehicle_single_field_campaign.gd` exercises stage-flow completion and field continuity. `validate_vehicle_attack_contract.gd` checks computed radial damage, affinity, wall blocking, and status behavior in addition to constants. Some tests remain contract-focused, but the named examples are not trivial constant assertions. |
| No integration test exercises stage behavior | Too broad. `validate_vehicle_run.gd` loads the main scene and exercises stage transition, build/exploration preservation, player respawn, projectile and boss-interrupt behavior. There is still no single validator that plays the entire five-stage run under real input and rendering. |
| Persistence lacks a round-trip validator | Settings persistence is explicitly round-trip tested by `validate_settings_store.gd:22-62`, including malformed-value repair. The product spec does not promise persistence of an in-progress run, so a run-progression save test is not a missing contract unless that feature is added. |

## Rejected

| Claude claim | Why rejected |
| --- | --- |
| Strong validators include `validate_vehicle_stage_catalog.gd`, `validate_vehicle_upgrade_catalog.gd`, `validate_vehicle_combat_stages.gd`, and `validate_vehicle_experience_runtime.gd` | These files do not exist. The actual validators are named `validate_vehicle_stage_layouts.gd`, `validate_vehicle_upgrade_system.gd`, `validate_vehicle_single_field_campaign.gd`, and `validate_vehicle_experience.gd`. Findings tied to the invented names are not trustworthy. |
| No audio validation exists | `tools/validation/validate_vehicle_rewards_ui_audio.gd:92-97` constructs the audio director, requires all fourteen stored WAV streams to load, and checks the fourteen-sound contract. Runtime timing and mix quality still require listening, but asset/contract validation exists. |
| Card interaction needs drag, tap, hold, and cancel simulation | The current upgrade choice is a button/keyboard selection flow, not a drag-placement system. These interaction modes were invented and are not product requirements. |
| “At least twenty” walkable regions versus 21 is a spec drift | “At least twenty” includes 21. This is not a contradiction and does not require an exact-number documentation edit. |
| Supported upgrade-card layouts remain unverified at runtime | The repository already validates 3,276 states across Korean/English, selected/unselected cards, three slots, and the three supported viewports. Extreme aspect ratios are optional breadth, not evidence that supported layouts are unverified. |

## Needs Local Runtime Verification

- Run a focused, visible, non-headless 60-second current-pressure and
  boss-pressure capture on the target laptop using the existing recorder.
- Compare 0.18- and 0.20-second hit feedback only if the spec is not simply
  corrected to match the chosen feel.
- Play-test the 900-pixel boss arrival case before deciding whether code or spec
  should change.
- Verify actual combat audio timing and mix; the validator proves that assets
  load, not that they sound correct together.
- Inspect minimap legibility, font rendering, boss telegraph feel, and complete
  stage-transition pacing in the built game.

## Recommended Priority

1. Obtain a release-qualified rendered performance sample using the recorder
   already in the repository.
2. Decide and reconcile the three real behavioral contracts: hit-flash
   duration, boss arrival minimum, and one-signature-per-fight semantics.
3. Replace field-agnostic `DROWNED_RUINS` stage labels with naming derived from
   the selected field.
4. Treat `vehicle_run.gd` decomposition as incremental architecture work only
   when a concrete subsystem is being changed; do not begin a broad rewrite
   from Claude's line-count argument.

No implementation was authorized or performed as part of this validation.
