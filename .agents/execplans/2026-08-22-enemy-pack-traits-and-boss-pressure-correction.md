---
type: plan
status: done
created: 2026-08-22
scope: Ordinary enemy pack ownership and trait reachability, Coordinator leadership, Stage 6 projectile topology, Stage 11 pressure, and early-boss cadence
related:
  - docs/reports/2026-08-22-enemy-pack-trait-and-boss-gap-audit-ko.html
  - docs/product/vehicle_game_spec.md
  - docs/design/VISUAL_SYSTEM.md
  - .agents/execplans/2026-08-21-onboarding-progression-and-combat-pressure.md
  - .agents/execplans/2026-08-22-boss-device-contact-integration.md
---

# Enemy Pack Traits and Boss Pressure Correction - Execution Contract

The current HEAD already contains the separately completed continuous singleton Enemy Upgrade Device lifecycle. This contract corrects the remaining report-confirmed gaps: ordinary squads become persistent semantic packs with explicit family, trait, and leader ownership; Defender and Coordinator traits become reachable and executable; Stage 6 growth projectiles become a bounded time-staggered volley; Stage 11 uses a single close-range damage threshold with lower overlapping pressure; and bosses 1-3 receive a small read-gap cadence increase without shorter warnings or more simultaneous attacks.

## Purpose

- Objective: make the five ordinary families and ten traits truthful in live pack combat, and align the named boss mechanics with the user's observed combat failures.
- Deliverable: current runtime, canonical product/design specs, focused validators, rendered evidence, Web export, and one scoped commit that agree on the corrected behavior.
- Completion state: every task and gate below passes, the task-scoped quality audit finds no unresolved reachable defect or competing owner, and this plan is marked `done`.

## Scope and Boundaries

In scope:

- Ordinary normal-pack composition metadata, pack leader identity, pack-level trait rollout, per-actor family/trait visuals, collective trait timers, Blink dispatch, Pack Feed leadership, and Bulwark protection.
- Existing ten-pack physical composition: four Pursuer rosters, three Charger rosters, and three equal Emitter-Defender paired rosters.
- Stage 6 distance-growth emission timing and its fixed-cap pending scheduler.
- Stage 11 movement, common damage scale, autonomous delay/intervals, received-damage threshold, and collision-owned range presentation.
- Bosses 1-3 direct read gaps only.
- Canonical product/design text and validators that own these contracts.

Out of scope:

- The already-completed continuous Enemy Upgrade Device lifecycle, health, routing, upgrade effects, or presentation, except correcting one stale visual-spec sentence that still says four devices per next cycle.
- New enemy families, traits, bodies, raster/SVG assets, UI panels, labels, badges, nodes, per-enemy materials, projectile trails, adaptive difficulty, or production dependencies.
- Ordinary population, active cap, quota, arrival cadence, Emitter-Defender actor ratio, projectile collision radii, warning duration, boss health, Stage 12 tuning, or subjective final difficulty certification.
- Rewriting the dated Korean audit report; it remains evidence for repository state `e2993775`.

Constraints and invariants:

- Cycle 1 onboarding remains base-only and kill-gated at `0/15/30/45/60`; every normal admission remains one atomic four-to-eight-member squad.
- Each normal pack owns exactly one primary family, one tier, at most one family trait, one tactic, and one explicit leader. Only actors in the owning family select the matching trait body and direct family behavior; every member consumes the shared pack trait state.
- The ten-roster bag remains physically `4 Pursuer / 3 Charger / 3 Emitter-Defender`. The three paired rosters expose two Emitter-primary packs and one Defender-primary pack. Exactly one eligible Pursuer/Charger roster per bag is promoted to a Coordinator-primary pack by replacing its first member with the Coordinator leader.
- Cycle 1 has no normal-pack traits. From cycle 2 onward, one of each three consecutive normal packs owns one family trait; trait A/B selection is deterministic and both traits for every family must be reachable across the authored twelve-cycle run.
- Bulwark uses the existing spatial grid and reusable query buffer to protect only living same-pack members within `250` units. No all-enemy nested scan or new hot-path allocation is allowed.
- Stage 6 schedules exactly five paired shots at `0.00/0.22/0.44/0.66/0.88 s`. Each pair starts at lateral offsets `-180/+180`, has no longitudinal pre-laid chain, and remains ten independent projectiles under a fixed five-receipt queue.
- Stage 11 health remains `122300`. Move speed becomes `540`, attack-move speed `432`, initial autonomous delay `2.00 s`, autonomous intervals `2.75/2.30/1.95 s`, and common damage scale `1.66`. Player-owned damage is full at distance `<= 760` and `0.20x` beyond; no inner boundary, shifted band, interval, or cue remains.
- Bosses 1-3 retain all startup, active, recovery, damage, projectile, and overlap rules. Only their absolute phase read gaps become `0.2412/0.1809/0.14472`, `0.234/0.1755/0.1404`, and `0.2268/0.1701/0.13608` seconds.
- Existing actor/projectile batches, capacities, collision truth, warning timing, and the combat renderer's 80-batch ceiling remain unchanged.

Destructive or irreversible actions:

- None.

Exact actions requiring owner or user approval:

- None. Publishing, deployment, dependency changes, destructive cleanup, and subjective tuning beyond the locked values remain unauthorized.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Upgrade Device absence | Commit `f20d6fff` replaced cycle publication with one immediate recurring run-level device, constant health, and a `9 s` enabled-time respawn | `vehicle_enemy_upgrade_device_runtime.gd`; focused device validator; current product spec | Treat the report's device section as resolved and do not reopen its runtime | 3.1 |
| Pack semantics | Composition admits squads atomically, but rolls traits per family member; the collective runtime copies family and trait from whichever member registers first | `vehicle_enemy_spawn_composition.gd`; `vehicle_encounter_runtime.gd`; `vehicle_collective_tactic_runtime.gd`; Korean audit | Put family, trait, tactic, and leader in pack metadata and propagate them explicitly to every actor | 1.1, 1.2 |
| Spawnable roster list | Current bag has four Pursuer, three Charger, three 1:1 Emitter-Defender rosters, plus one last-member Coordinator overlay | composition source and validator | Preserve physical roster counts; make paired primary ownership `2 Emitter / 1 Defender`; promote one eligible roster to a first-member Coordinator leader | 1.1 |
| Trait rollout | Canonical spec says cycle 1 base-only and later traits on one third of packs; current implementation uses member-level `4:3:3` bags and allows stage-1 normal traits | product spec lines 303-308; family catalog; validators | Replace member bags with deterministic pack-level one-in-three rollout and validate all ten traits across authored stages | 1.1, 1.4 |
| Defender behavior | Bulwark and Reflector timers depend on the copied first-member trait. Bulwark renders `250` range but shields only its owning Defender | collective runtime; `_apply_enemy_shield`; renderer; product/design specs | Make Defender-primary packs reachable and add spatial-grid same-pack Bulwark assignment; keep Reflector body-only reflection during the shared window | 1.2, 1.3 |
| Coordinator behavior | Coordinator is rare, last, not leader, and not tactic owner. The `pack_trait` event handler is incorrectly nested under the phase branch, so Blink requests are not dispatched | composition source; event handler; Korean audit | Coordinator becomes the first member, leader, `shepherd_pack` owner, and trait owner; repair top-level event dispatch | 1.1, 1.3 |
| Stage 6 connected projectiles | The explicit renderer trail is gone, but ten projectiles are created in one frame along two axes at `48`-unit longitudinal spacing; their `4.20x` envelopes overlap | `_spawn_boss_long_banks`; projectile renderer; audit | Use five time-staggered lateral pairs with no pre-laid longitudinal spacing and a bounded queue | 2.1 |
| Stage 11 pressure | Current profile uses `545/441.45`, `1.60 s` initial autonomous delay, `2.40/1.95/1.55 s` intervals, and `1.70` common damage. Damage requires tracking two moving boundaries | boss profile, pattern scale, late mechanic, renderer, audit | Apply the exact calmer profile and one fixed `760` maximum-distance rule above; keep health unchanged | 2.2 |
| Early boss cadence | Bosses 1-3 have no autonomous sequence and use direct recovery plus a phase read gap | boss patterns/runtime/profile; audit | Reduce only the three read-gap arrays by exactly 10%; preserve warnings, recovery, damage, and overlap | 2.3 |
| Presentation authority | Existing retained trait cues and projectile bodies are approved; Stage 11 currently renders an annulus with two boundaries | complete read of `VISUAL_SYSTEM.md`; original-detail canonical sheet inspection | Reuse existing cues; render Stage 11 as one restrained filled disk plus one outer boundary; create no image asset | 2.2, 3.1 |
| Performance ownership | Collective state is bounded to 32 packs; actor cap is 72; retained batches and spatial grid already own high-count work | performance policy and runtime architecture audit | Keep fixed arrays/queues and shared buffers; report focused scenario only if run, never release performance | 1.3, 2.1, 3.2 |

Rejected alternatives:

- Do not add pure Defender-only or Coordinator-only actor swarms. Explicit primary ownership inside the current bounded bag fixes reachability without broad population or combat-composition changes.
- Do not copy one literal trait ID onto actors from other families. The pack owns the shared trait state; only the owning family selects the family-exclusive body and direct behavior.
- Do not keep the Stage 11 inner boundary or alternate only the outer value. Any two-boundary band retains the unrealistic distance-maintenance tax identified by the user.
- Do not solve Stage 6 overlap by shrinking projectile art or collision. Time topology is the defect; collision and the approved `4.20x` presentation envelope remain authoritative.
- External research is not required: current canonical product/design specs, current code, validators, the dated audit, and recent commit history close the decisions without an external API or genre comparison.

Visual-authority receipt:

- Canonical spec: `docs/design/VISUAL_SYSTEM.md`; pre-edit SHA-256 `cd44b5f672043d68af4ee5c7bdc140ff81cadcd4a05cf3a9ed4850bad458e798`; post-alignment SHA-256 `c8dde49b2506d01b4ff298622b0bf31a233f141c4ea609d8a42a7a17a01fb560`; read completely.
- Canonical sheet: `docs/design/cardborne-universal-art-style-reference.png`; expected and observed SHA-256 `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`; inspected at original `1448 x 1086` detail.
- `actual_image_reference_used=false`; `reference_input_method=not_applicable`. No raster, SVG, mockup, or generated image is created or promoted.
- Task constraints: retain the 45 family-tier-trait PNGs; use current code-native trait cues; keep Stage 6 bodies independent with no trail/beam; show one collision-owned Stage 11 distance region; preserve actor/projectile batches and the 80-batch ceiling.

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership, safety, and validation decision is closed.
- Godot `4.7.1.stable` is available through `./tools/godot.ps1`; the repository owns the focused validators, visual checks, capture path, and Web export path named below.
- Remaining unknowns are implementation-local and cannot change this contract.

## Tasks

### Phase 1: Semantic Packs and Reachable Family Traits

Goal: every normal squad has one durable meaning, and all five family owners can execute their two traits in live combat.

Preconditions:

- Preserve all unrelated tracked/untracked workspace state and the completed device commit.
- Keep normal actor counts, pack sizes, capacity, and admission timing unchanged.

Source owners: `scripts/encounters/vehicle_enemy_spawn_composition.gd`, `scripts/enemies/vehicle_enemy_family_trait_catalog.gd`, `scripts/encounters/vehicle_encounter_runtime.gd`, `scripts/enemies/vehicle_enemy_state.gd`, `scripts/encounters/vehicle_collective_tactic_runtime.gd`, `scripts/vehicle/vehicle_run.gd`

- [x] **1.1** Publish explicit primary family, leader, tactic, and one-in-three trait metadata.
  - Change: replace member-level trait bags with the locked pack rollout; expose two Emitter-primary and one Defender-primary paired rosters; promote exactly one eligible roster to a first-member Coordinator leader; copy the pack trait only to owning-family actors.
  - Accept: deterministic seeds show the unchanged physical `4/3/3` bag, all five primary families, one Coordinator-led pack, one Defender-primary pack, valid leader indices, base-only cycle 1, exact one-in-three later traits, and all ten traits across the authored run.
  - Guard: no normal pack loses atomic four-to-eight-member admission or valid Emitter-Defender pairing.
- [x] **1.2** Register collective state from explicit pack truth.
  - Change: propagate `pack_family` and `pack_trait` through spawn specs into pooled actor state; initialize the bounded collective record from those fields; wait for the explicit leader instead of silently choosing the first arrival.
  - Accept: registration order cannot change pack family, trait, tactic, or leader; a Defender-primary paired pack works even though its Defender leader is not the first roster member.
- [x] **1.3** Complete Defender and Coordinator trait execution.
  - Change: repair top-level phase/break/pack-trait event dispatch; route Blink requests; apply Bulwark to living same-pack actors within `250` through the spatial grid and reusable buffer; preserve Reflector and Pack Feed rules.
  - Accept: focused fixtures observe Bulwark activation and nearby same-pack shielding, Reflector's active reflection window, Blink warning/request dispatch, Pack Feed stacking and Coordinator-leader shutdown, with no cross-pack protection.
- [x] **1.4** Replace catalog-only validation with authored reachability checks.
  - Change: extend focused composition, trait, collective, and integrated specialist validators to prove emitted pack metadata and actual shared trait state.
  - Accept: each validator fails against the pre-change defect and passes only when the production owners satisfy the locked pack contract.

Phase 1 gate:

```powershell
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_enemy_spawn_composition.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_enemy_family_traits.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_collective_tactics.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_specialist_enemy_integration.gd
git diff --check
```

### Phase 2: Boss Topology and Pressure Corrections

Goal: Stage 6 fires readable independent growth shots, Stage 11 asks for one practical distance decision under lower overlap, and bosses 1-3 attack slightly more often without less warning.

Preconditions:

- Phase 1 acceptance checks and gate pass.

Source owners: `scripts/bosses/vehicle_boss_runtime.gd`, `scripts/vehicle/vehicle_run.gd`, `scripts/bosses/vehicle_boss_profile_catalog.gd`, `scripts/bosses/vehicle_boss_patterns.gd`, `scripts/bosses/vehicle_late_boss_mechanics.gd`, `scripts/presentation/vehicle_combat_renderer.gd`

- [x] **2.1** Emit Stage 6 growth ammunition as five delayed lateral pairs.
  - Change: add one fixed five-receipt scheduler, advance it once per progression tick, clear it on every existing boss/reset cleanup path, and emit each pair at the locked offsets/times.
  - Accept: integrated validation observes counts `2/4/6/8/10` at the five release points, no early shot, no second execution, independent projectile bodies, and no renderer trail or beam.
  - Guard: do not reduce projectile size, collision, speed, growth, damage, proximity, detonation, store reserve, or lifetime.
- [x] **2.2** Replace Stage 11's shifting annulus with one close-range threshold and lower overlapping pressure.
  - Change: apply the locked profile and common damage scale; replace band/shift/cue APIs with a fixed maximum-distance multiplier; publish one radius to the renderer and draw one restrained disk plus its outer boundary.
  - Accept: `<=760` applies full player-owned damage, `>760` applies `0.20x`, elapsed time cannot change the threshold, the exact profile values are queryable, and no inner or shifted boundary remains in runtime, renderer, active specs, or validators.
- [x] **2.3** Increase only bosses 1-3 direct selection cadence.
  - Change: replace their read-gap arrays with the locked 10% reductions.
  - Accept: exact profile queries pass while all boss startup caps, active duration, recovery, damage, projectile count, autonomous ownership, and squad cadence remain unchanged.

Phase 2 gate:

```powershell
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_distance_growth_projectile.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_late_boss_mechanics_correction.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_boss_difficulty_correction.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_boss_patterns.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_boss_runtime.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_run_difficulty.gd
git diff --check
```

### Phase 3: Canonical Truth, Rendered Evidence, and Handoff

Goal: specifications, rendered presentation, build output, and durable plan state agree with the corrected runtime.

Preconditions:

- Phases 1-2 and their gates pass.

Source owners: `docs/product/vehicle_game_spec.md`, `docs/design/VISUAL_SYSTEM.md`, this plan, focused renderer/run validators, repository export tooling

- [x] **3.1** Update active product and visual authority.
  - Change: record the exact pack ownership/trait policy, Stage 6 volley timing, Stage 11 threshold/profile, early read gaps, and continuous singleton device sentence; preserve the Korean report as dated evidence.
  - Accept: active specs contain no member-level `4:3:3` trait rollout, Stage 11 two-boundary band, simultaneous Stage 6 longitudinal bank, or next-cycle four-device claim.
- [x] **3.2** Validate the changed runtime and presentation at proportionate cost.
  - Change: run focused integration, visual authority, one native `1280x720` capture, one Web export/static verification, and inspect only captures that prove family-trait cues, Stage 6 projectiles, and Stage 11 range presentation.
  - Accept: checks pass at unchanged workload/capacity; screenshots show no connected Stage 6 line, Defender/Coordinator trait cues remain readable, and Stage 11 has one outer threshold without clipping or duplicate rings.
  - Guard: label headless checks, rendered capture, Web export, and static verification separately; make no release-performance or subjective difficulty claim.
- [x] **3.3** Audit ownership and commit the completed contract.
  - Change: run `$codebase-quality-auditor`, apply only small safe task-scoped corrections, mark this plan `done`, and commit only task-owned files with a short explanatory body.
  - Accept: no responsibility creep, competing owner, broken public contract, reachable failure path, stale task-owned spec, or uncommitted task file remains.

Final local gate:

```powershell
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_run.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_combat_renderer.gd
./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_twelve_boss_campaign.gd
./tools/validation/validate_cardborne_visual_authority.ps1
./tools/godot.ps1 --headless --path . --import
./tools/export_web.ps1 -SkipImport
./tools/validation/validate_itch_web_release.ps1 -ReleaseDirectory build/web
git diff --check
```

The one native capture command is:

```powershell
./tools/godot.ps1 --path . --rendering-method gl_compatibility -- --capture-all=build/enemy-pack-trait-boss-correction/captures-native --capture-locale=ko --capture-size=1280x720
```

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | Current task's narrow Godot validator plus `git diff --check` | After one coherent owner edit | A relevant implementation input changes |
| Phase 1 gate | Four pack/trait commands under Phase 1 | Tasks 1.1-1.4 pass | A pack, trait, actor-state, collective, or shield input changes |
| Phase 2 gate | Six boss/projectile commands under Phase 2 | Tasks 2.1-2.3 pass | A boss profile, mechanic, scheduler, renderer, or validator input changes |
| Render gate | One native capture and original-detail inspection of relevant files | Functional phases and renderer validator pass | A relevant presentation input changes |
| Final gate | Final local command block | All tasks and quality audit pass | A final-gate input changes |

Validation rules:

- Run the narrowest check that proves the current task.
- Run each phase gate once after its owned tasks pass.
- Treat a passing check as current until one of its relevant inputs changes.
- Rerun a failed check only after a relevant implementation change or a new hypothesis can produce different evidence.
- Preserve exact actor, projectile, pack, collision, and renderer capacities. Reduced workload cannot manufacture a pass.
- Static/headless evidence cannot prove subjective difficulty or pixel readability. Rendered evidence proves only the named visible contracts.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain required approval before resuming | Do not choose a new product, architecture, dependency, UX, safety, or validation contract during implementation |
| Exact one-in-three rollout fails to expose both traits for one family across authored stages | Adjust only the deterministic trait-A/B selector while preserving stage-1 base and one-in-three pack frequency | Do not change roster counts, stage counts, or trait frequency |
| Fixed five-shot Stage 6 queue conflicts with an existing delayed-shot owner | Move the same five receipts into the nearest existing bounded boss scheduler | Do not use unbounded timers, nodes, per-shot objects outside the projectile store, or simultaneous longitudinal placement |
| A capture fixture does not expose a named corrected state | Add or repair one evidence-only deterministic fixture using production owners | Do not alter production timing or visuals merely to satisfy a screenshot |
| An unrelated worktree change overlaps a task file | Preserve it, isolate the task hunk, and stop only if ownership cannot be separated safely | Never reset, clean, revert, or stage unrelated user work |

Implementation-local discoveries may be handled inside the locked contract when they cannot change scope, visible behavior, ownership, architecture, safety, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Complete.
- Next task: None.
- Last completed gate: scoped task commit after the final local gate, native `1280x720` capture, Web export, itch.io static verification, and ownership audit.
- Implementation note: the quality pass found that `VehicleBossRuntime` already owns delayed boss-projectile receipts for Stage 8. The fixed five-receipt Stage 6 queue was therefore placed beside that existing owner; `VehicleRun` retains only projectile emission side effects, as required by the predetermined contingency.
- Rendered evidence: `03g-family-traits-active.png` shows the Bulwark, Reflector, and Blink Coordinator bodies and cues; `30-boss-06-distance-growth-pairs.png` shows independent unconnected shots; `30-boss-11-resonance-range.png` shows one filled damage region with one outer boundary.
- Validation note: every Phase 1, Phase 2, renderer/run/campaign, visual-authority, capture-driver, import, Web export, and itch.io static check passed. The capture-driver audit corrected its manifest contract from `160` to `163` after the three task-specific evidence files were added.
- Update rule: after a checkpoint passes, record concise evidence, check the task, and advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check passes.
- Every guard, phase gate, render gate, and final gate named by this contract passes.
- No placeholder or unresolved material decision remains.
- Product and visual specs record the durable accepted behavior, while the dated audit remains advisory evidence.
- Frontmatter status is changed to `done` only after implementation, validation, audit, and the scoped commit are complete.

Replan when:

- A material discovery invalidates the locked contract.

Do not replan or stop for:

- Implementation-local mechanics already contained by this contract.
- A passing check whose relevant inputs have not changed.
