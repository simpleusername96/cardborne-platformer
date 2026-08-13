---
type: plan
status: active
owner: BK
created: 2026-08-13
last_reviewed: 2026-08-13
topic: Run pacing, cumulative time, final-result integrity, ordinary-enemy readability, and image-filled upgrade slots
scope: Cardborne five-stage boss pacing, XP cadence, active-run clock, ordinary enemy scale and durability, upgrade build summary, final Result, captures, and native/Web qualification
related:
  - ../../AGENTS.md
  - ../PLANS.md
  - ../design/DESIGN.md
  - ../cardborne-performance-engineering-policy.md
  - ../cardborne-runtime-architecture-audit.md
  - ./2026-08-13-dense-combat-and-engagement-flow.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/product/vehicle_upgrade_catalog.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/performance/2026-08-13-dense-enemy-stutter-evidence.md
---

# Run Pacing, Result, and Upgrade Slots - Execution Contract

> Current follow-up authority: use
> `2026-08-13-evidence-category-slots-and-scalable-swarm.md` for performance provenance,
> the category-owned build-slot correction, the current cap-48 p99 work, and capacity exploration.
> This plan remains active as the implementation record and contract for its other completed or
> unresolved run-pacing and Result scope.

Correct the five-stage run after the exact ordinary-enemy population was reduced. Bosses must arrive
after a deliberately smaller defeat path, the existing upgrade cadence must survive the shorter run,
the run clock must include mandatory upgrade decisions, and the final Result must show the complete
run record and build. Enlarge ordinary enemies slightly and increase their durability without
restoring dense-actor load. Replace the text-only current-build rail with the user-directed
four-column empty-slot grid that fills with existing semantic upgrade artwork.

This document is the implementation-ready contract. No gameplay, balance, UI, asset, or runtime code
is changed by creating it.

## Outcome

- Boss-trigger quotas become `48/64/80/96/112` instead of `125/166/208/250/291`.
- Exact materialized ordinary-enemy caps remain `1/40/48/48/48`; the global 320-hostile store and
  virtual authored reserve remain intact.
- New ordinary admissions stop when the quota is reached. A window whose cue is already visible
  completes; uncued reserve is canceled explicitly and never materializes during the boss fight.
- Swarm, standard, and priority XP values become `3/5/10`; boss XP remains `24`. The minimum quota
  path keeps the current stage level-up cadence `9/5/4/5/6` and ends at run level 30.
- Active run time accumulates in `PLAYING` and mandatory `UPGRADE`, across all five stages. It excludes
  Deployment, explicit Pause/Settings/Guidebook time, Failure Report, and final Result.
- Moving ordinary enemy presentation radius becomes `48` instead of `44`; fixed installations and
  bosses keep `62/146`. Ordinary health receives one explicit final `1.20` multiplier. Movement,
  body-contact radius, speed, damage, attacks, and materialized population do not change.
- The upgrade build rail starts with four outlined empty cells. First acquisition fills the next cell
  with its existing `upgrade/<id>` image; a level-up updates that cell instead of consuming another.
- Stage 5 Result aggregates all retained stage records and displays actual defeats, outgoing damage,
  damage attributes, cumulative active run time, final Hull, and the frozen image-based build. Its
  Deployment action remains fixed and unique.
- Korean and English remain complete at `960x540`, `1280x720`, `1920x1080`, and 200% text scale. The
  same final commit passes native and Web qualification before release.

## Current Findings and Root Causes

| Symptom | Confirmed cause | Evidence owner | Required correction |
| --- | --- | --- | --- |
| Run became much longer after reducing enemies | Boss quota is still `125/166/208/250/291`, while exact active pressure is now only `40/48` after the opening beat. Virtual reserve does not update `VehicleStageFlow`. | `vehicle_combat_stages.gd`, `vehicle_encounter_director.gd`, `vehicle_stage_flow.gd` | Re-author explicit boss quotas and preserve them with integration tests; do not derive them implicitly from a live cap. |
| Ordinary enemies continue to arrive after quota | The scheduler is stopped only after boss defeat. | `vehicle_run.gd::_complete_stage`, `vehicle_encounter_runtime.gd::stop_spawning` | Seal new admissions at quota while honoring an already-cued atomic window. |
| A shorter quota would reduce upgrades | Current XP cadence is validated against the old quota path and ends at level 30. | `validate_vehicle_experience.gd` | Rebalance enemy XP to `3/5/10`, preserving `9/5/4/5/6` level-ups. |
| Play time does not feel continuous | `run_time` advances only when `mode == PLAYING`; mandatory card selection uses `UPGRADE`, so the clock pauses. It does already survive stage changes. | `vehicle_run.gd::_physics_process`, `_simulation_active` | Separate clock activity from simulation activity; count `PLAYING + UPGRADE`, but not explicit Pause or terminal screens. |
| Final Result looks incomplete | Run passes `stage_history`, but `VehicleResultPanel` ignores it and renders only three counters, the last upgrade title, and static reward text. | `vehicle_run.gd::_show_final_result`, `vehicle_result_panel.gd` | Add a gameplay-owned run-result aggregator and a report/build Result body. |
| Existing final capture is misleading | The `result` fixture uses Stage 1 and `has_next_stage: true`, although live Stage 5 uses final state. | `vehicle_run_capture_gateway.gd`, `93-final-result.png` | Use a dense, final-stage fixture and validate final semantics. |
| Upgrade summary is text instead of images | `VehicleBuildSnapshotBuilder` emits a flat list and `VehicleUpgradeBuildRail` creates `text_row` nodes. It never resolves artwork or creates slots. | `vehicle_build_snapshot_builder.gd`, `vehicle_upgrade_build_rail.gd` | Publish frozen display records and render a progressive four-column image grid. |
| Enemy size cannot be changed safely as a purely visual number | Runtime currently sets projectile hit radius equal to visual radius, and the spatial grid uses the larger hit radius. | `vehicle_run.gd::_make_enemy`, `vehicle_spatial_grid.gd` | Give visual radius and projectile target radius explicit names and tests; keep movement/contact radius separate. |

The existing failure report body is populated and the Stage 1-4 no-modal continuation is intentional.
Do not restore success reports between stages. The defect is the Stage 5 final Result and its stale
capture fixture, not the continuous stage transition.

## Scope and Boundaries

In scope:

- The five stage quotas, quota-to-boss transition, reserve cancellation accounting, and boss-entry
  integration validation.
- XP values and the existing level-30 quota-path oracle.
- Run-clock semantics and all report/result consumers.
- Moving ordinary enemy visual/target size and one global ordinary-health multiplier.
- Frozen build presentation records, image slots, slot detail popover, and Result reuse.
- Result aggregation and responsive Result/report presentation.
- Product, upgrade, visual, capture, localization, accessibility, native, and Web validation.

Out of scope:

- Raising or restoring the 320 shipping enemy workload.
- Changing authored role order, engagement sectors, gate movement, attack commitment, enemy damage,
  enemy speed, boss patterns, boss HP, projectile speed, or stage geometry.
- Adding new upgrade artwork. All 28 live upgrade PNGs already exist and are registered.
- Reintroducing Stage 1-4 success modals, boss reward cards, transition timers, or forced XP recall.
- Treating the presentation grid as a gameplay equipment limit.
- Changing GitHub Pages, itch.io deployment, save progression, or permanent rewards in this task.

## Domain and Ownership Contract

| Term | Exact meaning | Canonical owner |
| --- | --- | --- |
| Authored reserve | Deterministic packet identities that have no position, health, collision, reward, or render state yet. | `VehicleEncounterRuntime` |
| Materialized ordinary | A live exact ordinary actor admitted under the `1/40/48/48/48` pressure cap. | Encounter runtime plus `VehicleEnemyStore` |
| Boss-trigger quota | Countable ordinary defeats required before the boss warning. It is stage balance, not storage capacity. | `VehicleCombatStages` and `VehicleStageFlow` |
| Quota seal | The one-way transition that blocks new ordinary windows, fulfills any already-visible atomic cue, and cancels uncued reserve. | `VehicleEncounterRuntime` |
| Active run elapsed time | Time after deployment while gameplay is active or a mandatory upgrade decision blocks continuation; explicit user pause and terminal screens do not count. | `VehicleRun` lifecycle |
| Frozen build snapshot | Read-only gameplay-authored values and artwork IDs for presentation. UI never recalculates card effects. | `VehicleBuildSnapshotBuilder` |
| Build grid cell | One presentation-only position for one unique acquired upgrade. It is not an equipment slot. | `VehicleUpgradeBuildRail` |
| Final run result | One immutable aggregate of all completed stage reports plus final build and run metrics. | New `VehicleRunResultBuilder` |

Use these terms in code, tests, telemetry, and documents. Do not call authored reserve “active
enemies,” do not call build grid cells gameplay slots, and do not reuse simulation activity as the
run-clock predicate.

## Locked Design

### 1. Boss pacing and XP

The explicit Stage 1-5 boss-trigger quotas are:

| Stage | Old quota | New quota | Peak exact materialized cap | Maximum cap turnovers before quota |
| ---: | ---: | ---: | ---: | ---: |
| 1 | 125 | 48 | 48 | 1.00 |
| 2 | 166 | 64 | 48 | 1.33 |
| 3 | 208 | 80 | 48 | 1.67 |
| 4 | 250 | 96 | 48 | 2.00 |
| 5 | 291 | 112 | 48 | 2.33 |

The quotas are content data. A validator relates them to the exact active cap, but runtime does not
recompute them when a cap changes.

On the defeat that reaches quota:

1. `VehicleStageFlow` enters the existing 1.5-second boss warning.
2. `VehicleEncounterRuntime` seals future ordinary admission.
3. An already admitted/cued atomic arrival window remains reserved and emits all promised rounds.
4. Uncued windows, queued packets, and virtual reserve are canceled with explicit
   `quota_canceled_reserve` accounting. No materialized enemy is despawned.
5. The boss may enter on the existing warning/store-reserve rule. Surviving ordinary enemies remain
   valid combatants and preserve the continuous-stage contract.

XP changes only at the existing drop-value owner:

| Health class | Old XP | New XP |
| --- | ---: | ---: |
| Swarm | 1 | 3 |
| Standard | 2 | 5 |
| Priority | 4 | 10 |
| Stage boss | 24 | 24 |

Elite scaling retains the existing rule on top of these values. With the authored minimum role
sequence and new quotas, the five stages still award `9/5/4/5/6` level-ups and finish at level 30.
Do not lower the XP curve or add stage-clear XP as a second compensation system.

### 2. Active run clock

Rename the ambiguous runtime value to `active_run_elapsed_seconds` and use a dedicated
`_run_clock_active()` predicate.

- Count: `PLAYING`, `UPGRADE`.
- Do not count: `DEPLOYMENT`, `PAUSED`, `FAILURE_REPORT`, `RESULT`.
- `STAGE_REPORT` remains non-counting; Stage 1-4 do not enter it and failure is terminal.
- Preserve the value across Stage 1-5 continuation and reset it only for a fresh deployment.
- Report snapshots receive the value; UI only formats it as minutes and seconds.

This defines “gameplay time from run start” as player-controlled play plus unavoidable card decisions,
not wall-clock application time and not time intentionally spent in Pause/Settings/Guidebook.

### 3. Slightly larger, tougher ordinary enemies

- Moving non-boss ordinary visual radius: `44 -> 48` (`+9.1%`).
- Moving non-boss projectile target radius: explicit `48`, no longer assigned by copying the visual
  field. It changes with the visual in this release but remains a separate gameplay constant.
- Movement/contact/crowd/wall radius: unchanged per archetype.
- Installations: visual radius remains `62`; bosses remain `146`.
- Ordinary health: apply one final `1.20` multiplier to every non-boss hostile, including summoned
  ordinary actors and stationary installations, before elite modifiers. Boss health is unchanged.
- Speed, damage, recovery, attack cadence, projectile count, and threat budgets remain unchanged.

Size and health land in separate commits and are measured separately. If the size-only after-sample
regresses the valid production replay beyond its gate, retain the 20% health change but revert the
radius change to 44; do not compensate by reducing update truth or collision accuracy.

### 4. Progressive four-column upgrade grid

The newest user direction replaces the unresolved grouped 12/13-cell draft in the visual document.
The rail is a compact installed-upgrade inventory, not an equipment diagram.

- Four columns at every supported width.
- Cell/art sizes remain `44/36`, `52/44`, and `56/48` for compact/standard/large.
- At zero upgrades, show exactly four empty outline cells and no `SHIP_STATUS_NONE` replacement text.
- A first acquisition appends its ID to run-owned acquisition order and fills the next cell with the
  existing `upgrade/<id>` semantic PNG.
- A later level of the same ID updates the existing cell and popover; it never adds another cell.
- Visible capacity is `min(24, max(4, ceil((filled_count + 1) / 4) * 4))`: reveal one spare row as
  needed, up to six rows. The legal catalog path has at most 21 unique acquired IDs.
- Only filled cells are focusable. Hover/focus opens one transient detail popover; click/accept pins
  it; Escape, outside click, or another cell closes/replaces it.
- The popover uses frozen title, level, one or two current effect rows, and one short description.
- The rail owns its vertical scroll. At 200% text, the existing outer modal scroll rule remains.
- The same component may render the final Result build. It never mutates `VehicleRunBuild`.

Update the visual acceptance text from stale `12 registered upgrade identities` to all 28 registered
upgrade images and from stale manifest total 64 to the current validated total 80.

### 5. Complete final Result

Add `VehicleRunResultBuilder` beside the stage report builder. It consumes the five frozen stage
records and final build snapshot, merges rows by stable ID, recomputes aggregate percentages, and
publishes no localized strings or mutable gameplay state.

The final snapshot includes:

- cumulative active run time, final Hull/max Hull, total defeats, primary hits, Dash uses, and
  installations;
- aggregated defeat rows with elite counts;
- aggregated outgoing damage rows and exact total;
- aggregated kinetic/thermal/toxin/cryo/arc rows, status applications, and exact total;
- the complete frozen build snapshot and equipped secondary/active loadout;
- the existing restrained permanent reward summary.

The Result content region scrolls while the single Deployment action remains fixed. At wide sizes,
reuse one shared three-column combat-report component. At compact sizes, use keyboard/controller tabs
for Defeats, Damage, and Attributes, followed by the four-column build grid. Extract the shared report
body instead of copying `VehicleStageReportPanel` logic into Result.

The capture fixture must use Stage 5, `has_next_stage: false`, five dense stage records, a partial
image-filled build, and final action semantics. Capture-only stage/failure fixtures must either set a
real report mode and pending snapshot or be explicitly non-interactive; they may not pretend their
fixed action works.

## Discovery Closure

| Decision area | Evidence checked | Closed decision | Implemented in |
| --- | --- | --- | --- |
| Boss delay | stage quotas, materialized/authored caps, stage flow, reserve runtime, git history | Explicit `48/64/80/96/112` quota curve and quota seal | Phase 1 |
| Growth economy | XP drop rules, geometric level curve, authored role sequences, level-30 validator | `3/5/10/24` XP preserves `9/5/4/5/6` | Phase 1 |
| Time semantics | every `RunMode`, reset/continuation paths, report consumers | Count PLAYING+UPGRADE; exclude explicit pause/terminal | Phase 2 |
| Enemy scale | archetypes, visual profile, renderer, contact, projectile hit, grid | Moving ordinary 48 visual/target, unchanged body radius | Phase 3 |
| Enemy durability | current multipliers and elite order | One final non-boss `1.20` multiplier before elite | Phase 3 |
| Upgrade artwork | catalog, manifest, provider, offer rows, build rail, visual contract, user sketch | Four-column progressive image grid, max 24 cells | Phase 4 |
| Final report | stage telemetry/builder/panel, result panel, live/capture state paths, product spec | Aggregate all five records and reuse report body/build grid | Phase 5 |
| Release safety | performance policy, current native replay, Web export and itch validators | causal native samples, then one final native/Web gate | Phase 6 |

No material product question remains. The user's four-cell sketch means four columns and an initial
four-cell empty state, not a four-upgrade gameplay limit.

## Tasks

### Phase 0: Contract and baseline freeze

Goal: make the new user decision authoritative and capture a comparable before state before runtime
changes.

Source owners: this plan, `docs/product/vehicle_game_spec.md`,
`docs/product/vehicle_upgrade_catalog.md`, `docs/design/VISUAL_SYSTEM.md`, the active dense-combat
plan, capture tooling, and performance evidence.

- [x] **0.1** Update product/visual terminology and acceptance numbers.
  - Change: record new quotas, quota seal, XP values, clock states, 48 radius, 1.20 health, 4-column
    progressive grid, 28 upgrade images/80 manifest entries, and complete Result fields.
  - Accept: document-authority and visual-authority validators pass; no active document still claims
    old quotas, text-only build rail, 12 upgrade identities, or 64 total assets as shipping truth.
  - Guard: do not rewrite completed dense-runtime evidence; add a supersession note only for the old
    quota/reward-preservation decision.
- [ ] **0.2** Record one eligible short native `production_replay` before gameplay changes.
  - Change: none; use the clean current commit, 1280x720 GL Compatibility, declared scenario, quiet
    machine, and existing recorder schema.
  - Accept: retain valid JSON with commit, counts, focus, duration, physics/frame percentiles, draw
    calls, batches, and memory.
  - Stop: one valid sample. Invalid focus/external-load samples may be retried once after cleanup.

### Phase 1: Short boss path with preserved upgrades

Goal: make the reduced exact population produce a shorter run without starving the build.

Source owners: `scripts/vehicle/stages/vehicle_combat_stages.gd`,
`scripts/encounters/vehicle_stage_flow.gd`, `scripts/encounters/vehicle_encounter_runtime.gd`,
`scripts/vehicle/vehicle_run.gd`, `scripts/rewards/vehicle_field_drop_rules.gd`, reserve telemetry,
and encounter/experience validators.

- [x] **1.1** Replace stage quotas with `48/64/80/96/112` and update every exact oracle.
  - Accept: a real packet-materialization/defeat integration fixture reaches warning on the exact
    final required kill and never one kill early.
  - Guard: summoned enemies remain non-counting; carry-over countable actors keep the current
    continuous-stage rule.
- [x] **1.2** Add the one-way quota seal.
  - Accept: no new window is admitted after quota; an already-cued window fulfills every promised
    round; uncued reserve becomes `quota_canceled_reserve`; materialized enemies are not despawned.
  - Guard: reservation totals, generations, boss slot reserve, and cue truth remain exact.
- [x] **1.3** Change XP to `3/5/10/24` and update the quota-path fixture.
  - Accept: stage level-ups are exactly `9/5/4/5/6`, final run level is 30, elite XP remains bounded,
    and shard/pool capacity invariants pass.
  - Guard: do not add stage-clear XP or change the level requirement curve.

### Phase 2: Continuous active-run time

Goal: make every mandatory part of a live run count once and only once.

Source owners: `scripts/vehicle/vehicle_run.gd`, stage report/result builders, capture gateway, and
run/stage-continuity/report validators.

- [x] **2.1** Separate run-clock activity from simulation activity and rename the value.
  - Accept: a deterministic lifecycle fixture proves PLAYING counts, UPGRADE counts, PAUSED does not,
    continuation preserves, and FAILURE_REPORT/RESULT freeze the same final value.
  - Guard: gameplay simulation, cooldowns, attacks, effects, and physics remain stopped in UPGRADE.
- [x] **2.2** Route the canonical value to retained stage reports, failure report, Result, capture,
  debug context, and persistence-facing snapshots that display time.
  - Accept: every surface shows the same rounded cumulative time and no stage-local label remains.
  - Guard: do not persist elapsed time across separate runs.

### Phase 3: Enemy readability and durability

Goal: make the smaller population visually stronger without reintroducing density or hidden collision
changes.

Source owners: enemy combat tuning policy/archetypes, `vehicle_stage_visual_profile.gd`, enemy
construction, renderer target samples, spatial-grid target radius, and focused actor/contact tests.

- [x] **3.1** Add the final ordinary-health `1.20` multiplier as one named gameplay policy.
  - Accept: all non-boss fixtures receive exactly +20% after existing stage/difficulty factors and
    before elite modifiers; boss fixtures are byte-for-byte numerically unchanged.
  - Guard: no role base table is hand-edited to duplicate the multiplier.
- [x] **3.2** Set moving ordinary visual and projectile target radii to separate explicit 48 values.
  - Accept: rendered size and swept projectile target truth are 48; movement/contact/wall radii remain
    each archetype's old value; installations/boss remain 62/146.
  - Guard: the dead archetype `visual_radius` field is removed or made authoritative; do not retain
    two competing scale owners.
- [ ] **3.3** Run one comparable short native after-sample.
  - Accept: valid scenario/count/focus evidence and the existing 6 ms p95 / 8 ms p99 capacity gate.
  - Contingency: if size is the causal regression, revert only 48 back to 44 and retain health/quota;
    remeasure once. Do not weaken collision, scheduling, or thresholds.

### Phase 4: Four-column image build grid

Goal: replace the text list with the user's empty-outline-to-image-fill behavior.

Source owners: `VehicleRunBuild`, `VehicleBuildSnapshotBuilder`, a new responsibility-shaped
`VehicleUpgradeBuildCell`, `VehicleUpgradeBuildRail`, semantic asset provider, shared UI components,
and upgrade/UI/localization validators.

- [x] **4.1** Record stable first-acquisition order and publish frozen cell data.
  - Accept: first acquisition appends once; level-ups preserve position; reset clears order; save-free
    run ownership remains unchanged; snapshot includes artwork and current effect text.
  - Guard: UI never reads or mutates `VehicleRunBuild` directly.
- [x] **4.2** Implement empty, filled, focused, pinned, and popover cell states.
  - Accept: empty/partial/21-unique fixtures produce the locked progressive capacities, exactly one
    image per filled cell, zero focusable empty cells, stable focus order, and one open popover.
  - Guard: no new raster/SVG asset, text substitute, mechanic-specific drawn glyph, or gameplay slot
    limit is introduced.
- [x] **4.3** Integrate the rail without changing the three offer rows.
  - Accept: rail widths `216/248/264`, four columns, slot/art sizes, scroll behavior, fixed Equip,
    three offer images, and Korean/English text fit all supported matrices.

### Phase 5: Complete Stage 5 Result

Goal: turn the incomplete terminal summary into the product-specified run report.

Source owners: new `scripts/combat/vehicle_run_result_builder.gd`, shared report body component,
`vehicle_stage_report_panel.gd`, `vehicle_result_panel.gd`, `vehicle_stage_ui.gd`, Run, capture
gateway/driver, localization, and report/result validators.

- [x] **5.1** Aggregate five frozen stage records in gameplay space.
  - Accept: stable defeat/elite counts sum exactly; outgoing-source and attribute totals agree within
    `0.01`; row ordering and percentage rounding are deterministic; input records are not mutated.
  - Guard: UI does not calculate damage, attributes, or totals.
- [x] **5.2** Extract and reuse the responsive report body, then add the build grid to Result.
  - Accept: wide three columns, compact tabs, scrollable content, fixed Deployment, one primary action,
    final build/loadout, and no clipped/blank required section.
  - Guard: failure last-hit/top-three incoming remains failure-only; Stage 1-4 stay modal-free.
- [x] **5.3** Correct live/capture final-state semantics and locale refresh.
  - Accept: final fixture is Stage 5 with `has_next_stage: false`; report/result refresh in Korean and
    English; deterministic initial focus; capture primary actions match reachable modes.
  - Guard: visual-only fixtures are never used as evidence that an interaction works.

### Phase 6: Integration, quality, and release qualification

Goal: prove the complete change in source, rendered UI, native runtime, and the exported Web game.

Source owners: all task-owned files, focused validators, capture output, export tooling, itch release
validator, performance evidence, and this plan.

- [x] **6.1** Run the changed-owner focused batch and headless import once after integration.
  - Required: encounter pacing, arrival scheduler, stage flow/continuity, experience, Run, stage report,
    stage UI layout, upgrade system/UI, semantic asset provider, actor visuals, enemy expansion,
    contact, spatial grid, renderer, localization, capture driver, document authority, visual authority,
    and `git diff --check`.
  - Accept: all commands exit successfully with no parser/runtime/assertion error.
- [x] **6.2** Run the diff-scoped codebase-quality audit and repair only task-owned findings.
  - Accept: no competing quota, clock, health, scale, build-slot, or result owner; no reachable stale
    text rail or simplified final Result path; no public schema lacks a consumer/test.
- [x] **6.3** Produce rendered evidence.
  - Accept: Korean and English at `960x540`, `1280x720`, `1920x1080`, plus 200% text, covering empty
    rail, partial rail/popover, dense final Result, and failure report. Overlap, overflow, and clipping
    are zero; only filled slots focus.
- [ ] **6.4** Run one authoritative native `production_replay` on the clean candidate commit.
  - Accept: valid 60-second sample, exact shipping counts/caps, physics p95 <= 6 ms and p99 <= 8 ms,
    no fixed-step frame backlog, and retained JSON/evidence.
  - Stop: preserve a valid red result and replan its measured owner; do not lower thresholds or raise
    actor caps.
- [ ] **6.5** Export Web and test the same commit.
  - Required: `./tools/export_web.ps1`, `validate_itch_web_release.ps1`, static export validation, and
    one visible built-Web smoke for deploy -> upgrade -> quota -> boss -> Stage 5 Result.
  - Accept: native and Web show the same quotas, time, scale, build images, report data, and actions;
    no console error or missing imported upgrade texture.
- [ ] **6.6** Update durable evidence, mark this plan done only after every gate, and create coherent
  scoped commits. Push/deployment require a separate user instruction.

## Validation and Rework Controls

| Layer | Command or evidence | Run when | Rerun when |
| --- | --- | --- | --- |
| Inner balance | focused stage-flow, encounter, XP validators | Phase 1 edits settle | quota/reserve/XP input changes |
| Inner clock | focused Run, continuity, report validators | Phase 2 edits settle | lifecycle/time consumer changes |
| Inner enemy | actor visual, expansion, contact, grid, renderer | each health/size commit | health/scale/collision input changes |
| Inner UI | upgrade UI/system, stage report/layout, localization | each UI milestone | snapshot/component/layout changes |
| Causal performance | one short before and one short after `production_replay` | before Phase 1 and after Phase 3 | invalid sample or radius contingency only |
| Broad source | complete focused batch plus import | after Phase 5 integration | a relevant owner changes |
| Rendered UI | KO/EN viewport/text-scale matrix | after broad source is green | UI/copy/theme/capture changes |
| Final native | one clean 60-second production replay | clean candidate commit | invalid environment or material runtime change |
| Final Web | export, static/itch validation, visible built-Web smoke | native gate passes on same commit | export/runtime/UI input changes |

Broad and expensive checks run once at their named gate. Preserve large raw evidence under the
existing ignored build/evidence paths and summarize only decisions and measured values in durable
documents.

## Risks and Predetermined Contingencies

| Risk | Impact | Predetermined response |
| --- | --- | --- |
| Quota seal breaks an already-visible cue | Player sees a false promise | Finish the admitted window; cancel only uncued reserve. Never silently drop a cued round. |
| New quotas skip too much authored role variety | Later roles appear too rarely | Keep role order and time triggers; ensure the minimum quota fixture contains pursuit, ranged, denial, and support where the stage catalog provides them. Do not raise live cap. |
| XP compensation over-levels players who farm during boss | More than the quota-path level cadence | Keep ordinary enemies finite after seal and preserve XP for living extras; the level-30 contract is a minimum path, while legal catalog exhaustion already terminates rewards safely. |
| 48 target radius raises broadphase cost | Frame-time regression | Use explicit target radius, measure size separately, and revert only size if the valid gate fails. |
| +20% health cancels too much of the shorter quota | Run still feels long | Do not change the locked value without a measured manual run; first verify quota seal and actual boss timing. |
| Four-column grid grows vertically | Upgrade modal clips | Progressive rows plus rail scroll; fixed offer/action region and 200% outer-scroll contract remain. |
| Acquisition order adds competing build state | Save/reset or offers diverge | Store IDs only on first successful `VehicleRunBuild.apply`; it has no effect on eligibility/stats and is tested on reset/rejection. |
| Result aggregation duplicates report rules | Totals disagree | Extract shared pure row aggregation/percentage helpers and keep UI formatting-only. |
| Other UI session overlaps files | User work is overwritten | Before each phase, inspect status/diff; do not stage, revert, or edit overlapping unowned changes. Stop that phase if ownership cannot be separated. |

## Rollback and Safety

- Each milestone is a separate scoped commit: contract, quota/XP, clock, health, size, build grid,
  Result, and qualification evidence.
- The new quota seal is additive until old completion-only cancellation is proven unreachable; then
  remove obsolete paths in the same phase.
- No existing user-authored dirty file is staged, reverted, or cleaned.
- No new production dependency, engine version, asset, save schema, destructive filesystem action,
  or deployment is required.
- If final native qualification is red, keep the valid record and stop before Web/release rather than
  hiding the result or changing the gate.

## Decision Notes

- 2026-08-13: BK observed that reducing simultaneous enemies improved playability but made the old
  boss path drag. This plan intentionally supersedes only the old “preserve exact quotas/rewards”
  decision in the active dense-combat plan; its virtual reserve, exact caps, engagement flow, and
  performance gates remain authoritative.
- 2026-08-13: `48/64/80/96/112` keeps Stage 1 at one peak population and grows to 2.33 peak-population
  turnovers by Stage 5. This is explicit stage balance, not a formula hidden in the runtime.
- 2026-08-13: `3/5/10/24` preserves the validated `9/5/4/5/6` level cadence and final level 30 on the
  new authored minimum quota path without another reward system.
- 2026-08-13: mandatory upgrade decision time counts; user-controlled Pause/Settings/Guidebook time
  does not.
- 2026-08-13: the user's four-box sketch is implemented as a four-column progressive presentation
  grid. It replaces the inconsistent 12/13-cell draft and never becomes a gameplay limit.
- 2026-08-13: no new upgrade artwork is needed. The defect is a text-only consumer that predates the
  already-applied 28-image artwork system.
- 2026-08-13: clean commit `b0285329` produced an authority-eligible native result, but the replay
  workload decayed from its primed 48 actors to a 39-actor median because this one fixed-pressure
  scenario left production enemies at shipping health. Scenario counts therefore failed before the
  result could qualify the release. Physics p95/p99 were `5.178/11.737 ms`; the p99 is consistent
  with the pre-size-change `72883f0d` diagnostic (`5.375/11.871 ms`), so there is no evidence for the
  predetermined 48-to-44 radius rollback. Preserve
  `build/performance/run-pacing-result-slots-production-replay-rerun.json`, keep radius 48, and make
  the replay stabilize its timed population exactly as the other fixed-pressure fixtures do while
  retaining real attacks and collisions.
- 2026-08-13: clean commit `4f7f7acd` produced the final valid native stop. The replay held the exact
  discrete 90-percent pressure floor at 43 actors for all ten retained peak samples, scenario counts
  passed, focus remained valid, and frame p95/p99 were `2.381/4.718 ms` at 660 median FPS. Draw p95
  was 95 and combat batches were 38. Physics p95 passed at `5.211 ms`, but p99 remained red at
  `11.593 ms` against the unchanged 8 ms gate. The largest detailed tails remain ordinary simulation
  and scheduling (`enemies_and_grid` p99 `3.430 ms`, `encounter_and_pursuit` p99 `2.870 ms`) rather
  than rendering. Preserve
  `build/performance/run-pacing-result-slots-production-replay-final.json`; Phase 6.4 remains red and
  Phase 6.5 Web qualification must not start until the pre-existing ordinary-simulation tail owner is
  replanned and passes.

## Open Questions

None. The values, state semantics, presentation behavior, ownership boundaries, acceptance gates,
and measured rollback for the only performance-sensitive visual change are fixed above. New user
direction or valid contradictory runtime evidence must update this plan before implementation
continues.

## Progress and Next Steps

- [x] Current source, product/design contracts, relevant captures, git history, and focused validator
  gaps were inspected.
- [x] Boss/quota, clock, final Result, enemy scale/health, and upgrade-grid causes were independently
  audited read-only and synthesized here.
- [x] Product decisions, ownership, values, acceptance checks, stop conditions, and contingencies are
  closed.
- [x] Phase 0.1 updated the product, upgrade, and visual contracts plus the older dense-plan
  supersession note. `validate_document_authority.ps1`,
  `validate_cardborne_visual_authority.ps1`, and `git diff --check` passed.
- [x] Phases 1-5 are implemented and their focused source, localization, and rendered KO/EN matrix
  checks pass. The final Result uses five frozen stage records, and the build rail shows progressive
  four-column semantic artwork with a working detail popover.
- [ ] Phase 6.4 is the active stop. The stabilized replay is valid and every release check except
  capacity physics p99 passed. The measured remaining owner is the pre-existing combined ordinary
  simulation/scheduling tail; Web export and qualification were intentionally not run. The next task
  is a separate measured replan of that owner, not a threshold, cap, cadence, or radius change.

## Completion and Stop Conditions

Complete only when:

- Every task and acceptance check in Phases 0-6 is complete.
- Bosses warn at exactly `48/64/80/96/112`, no uncued reserve appears afterward, and XP cadence stays
  `9/5/4/5/6` through level 30.
- Active run time counts mandatory upgrades, survives all stage transitions, and freezes on terminal
  state.
- Ordinary health is +20%; accepted moving ordinary size is 48 or the predetermined measured rollback
  is documented at 44; other combat truth is unchanged.
- The build rail starts with four empty outlined cells, fills with the correct registered images, and
  exposes only filled cells to focus/popovers.
- Final Result displays complete five-stage combat and build data with one fixed Deployment action.
- Focused, rendered, native, and same-commit Web gates pass, or a valid red final gate is preserved and
  the plan remains active with its measured owner named.
- Durable specs/evidence reflect the shipping behavior and this frontmatter changes to `status: done`.

Stop and replan only if a valid measurement disproves a locked performance assumption, the current
catalog cannot represent the progressive grid without a gameplay schema change beyond acquisition
order, or concurrent user-owned edits make a phase's file ownership inseparable.
