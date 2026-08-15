---
type: plan
status: active
owner: BK
created: 2026-08-15
last_reviewed: 2026-08-16
scope: Implement the approved report-truth, combat-readability, neutral-facility, conditional-status, enemy-engagement, boss-identity, boss-pressure, and 72-ordinary encounter revision and qualify the production Web build
related:
  - ../../docs/reports/2026-08-15-combat-readability-pressure-review.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../design/DESIGN.md
  - ../cardborne-performance-engineering-policy.md
  - ../cardborne-runtime-architecture-audit.md
  - ./2026-08-15-eight-boss-combat-depth-and-run-report.md
---

# Combat Readability and Pressure Revision - Execution Contract

Cardborne will preserve its connected eight-boss run while making terminal reports
truthful, hostile attacks immediately recognizable, conditional upgrades visible in one
compact HUD row, neutral facilities strategically large and time-readable, engagement
movement relevant, boss identities mechanically faithful, and ordinary pressure
continuously replenished up to an exact live cap of 72. Implementation remains bounded,
gameplay-owned, bilingual, retained, and qualified in the production Web build.

## Purpose

- Objective: implement the user-approved combat readability and pressure revision without
  moving gameplay rules into UI, presentation, fixtures, or orchestration.
- Deliverable: updated product and visual contracts; report, facility, HUD, movement,
  encounter, boss, projectile, renderer, localization, diagnostics, validators, captures,
  Web export, and native/Web same-workload evidence.
- Completion state: every task acceptance check and final gate passes at the exact 72-live-
  ordinary workload; this plan is then marked `done`.

## Scope and Boundaries

In scope:

- Failure-report build parity, completed-cleanup boss status, and no boss-owned cleanup
  rewards.
- Exact hostile-area grammar: danger-red full footprint, one thin near-black perimeter,
  and four inward boundary notches; affinity never recolors hostile danger footprints.
- One panel-free top-left HUD row containing the current four items followed by at most five
  meaningful conditional statuses.
- Facility radii `1260/1260/1440/1080/1260` for Repair/Barrier/Gravity/Cryo/Weakpoint,
  reduced symmetric magnitudes, bounded overlap, distinct role colors, pass-through hits,
  localized hit receipt, and duration shown by the large effect-footprint perimeter.
- Stale engagement-gate release without teleport or retarget.
- Exact ordinary materialized caps `32/44/56/64/72/72/72/72`, continuous engaged-visible
  refill floors `12/16/20/24/28/32/36/40`, unchanged bounded attack-commit/denial budgets,
  and an explicit first-attack-preparation metric.
- Drydock frontal interception, Crown three body-attached defensive sectors, Archive Cross
  X corridors, broad-barrage and wedge-ring telegraphs, Siege Battery distance-accelerating
  ammunition, axis-specific boss pressure tuning, and body-only boss death cleanup.
- Current native and built-Web functional, visual, and performance qualification.

Out of scope:

- New production raster assets, external boss objectives, a global projectile-distance
  rule, ordinary-enemy distance-growth ammunition, capacities above 72 ordinary enemies,
  higher attack-commit budgets, a new engine/dependency/thread/native path, physics-rate or
  threshold reductions, new maps, difficulty selection, or a campaign-structure change.

Constraints and invariants:

- Use Godot 4.7.1 through `./tools/godot.ps1`; do not add dependencies.
- Preserve manual aim, held primary fire, dash, card-acquired weapons, exact collision
  footprints, one-hit semantics, deterministic encounter replay, Korean default, and
  complete Korean/English surfaces.
- `owner` means player, hostile, or neutral; `affinity` means thermal, toxin, cryo, arc, or
  kinetic; `footprint` means the exact gameplay area. Presentation never substitutes one
  concept for another.
- Gameplay owners publish immutable presentation snapshots. HUD and renderers do not infer
  card rules, collision, shield direction, spawn eligibility, or timer truth.
- Hostile circles, wedges, shockwaves, and damaging corridors use danger red regardless of
  affinity. Projectile bodies retain their authored player-primary, seeker, and hostile-
  bolt identities.
- The single top-left row must fit at 960x540, 1280x720, 1920x1080, and 200% text without
  clipping or entering the minimap. Values stay compact; full upgrade names remain in Ship
  Status.
- Facility duration uses the actual large effect-radius perimeter. The colored arc begins
  at 12 o'clock and drains clockwise; the spent perimeter remains a thin muted line. No
  facility-body countdown ring exists.
- High-threat attacks keep startup at least 1.30 seconds, exact committed geometry, one
  player-diameter-plus-80 escape corridor, and no final-commit retarget.
- Exact 72-live-ordinary pressure is a user-approved product workload. Performance work
  must repair measured owners; it may not reduce the cap, attack activity, collision
  accuracy, visual quality, resolution, physics rate, or release thresholds.
- Fixed runtime capacities remain 320 hostile actors, 240 player projectiles, 120 hostile
  projectiles with 24 boss-reserved slots, 192 XP shards, and 96 repeated effects unless a
  measured bounded owner proves an existing pool insufficient. Any capacity change beyond
  the approved ordinary cap requires a contract revision.

Destructive or irreversible actions:

- Remove the boss-death explosion PNG only after all runtime, manifest, workbench, capture,
  spec, and validator references are removed in the same scoped commit. Git history is the
  recovery path.

Exact actions requiring owner or user approval:

- None remain for this contract. The user delegated remaining decisions, approved a
  one-line HUD, approved the effect-radius countdown perimeter, and set the ordinary cap
  near 72; this contract fixes it at exactly 72.
- Stop for approval only if completion would require a new dependency, threads,
  GDExtension/native code, weaker performance thresholds, a cap below 72, or a materially
  different player-facing behavior.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Failure build/report truth | `VehicleRun._stage_report_context()` omits build; stage builder defaults empty; boss rows infer clear from ID | `vehicle_run.gd`, `vehicle_stage_report_builder.gd`, existing failure capture | One frozen gameplay-owned terminal snapshot; cleanup-complete boss status | 1.1 |
| Boss cleanup rewards | Death receipt forbids rewards but finalizer grants XP/group reward | `vehicle_boss_death_runtime.gd`, `vehicle_run.gd` | Cleanup grants no boss-owned XP, group reward, or quota | 1.2 |
| Hostile area ownership | Renderer drops owner/affinity and uses thermal orange | `vehicle_combat_renderer.gd` | All hostile damage footprints use danger-red fill, thin near-black boundary, four inward notches | 2.1 |
| Facility strategy and timer | Runtime publishes radius and `active_ratio`; current renderer uses small cyan symbol contour and separate faint field ring | `vehicle_mystery_device_runtime.gd`, interaction-edge shader, renderer | Approximate 3x radii; timer clips the large footprint perimeter; no body timer | 2.2 |
| Facility hit receipt | Both factions damage once then pass through; hit metadata is discarded | `vehicle_run.gd`, `vehicle_mystery_device_runtime.gd` | Preserve pass-through and add bounded localized impact receipt | 2.3 |
| Conditional UI | Runtime owns timers/stacks; HUD exposes only progress, defeats, dash, active | combo, dash, recovery runtimes and HUD presenter | Append at most five meaningful status slots to the same top-left row | 2.4 |
| Engagement relevance | Role standoff/recovery is intentional; immutable birth gate can remain stale for 18 seconds | movement policy, engagement director, run orchestration | Preserve role behavior; release irrelevant gates without retarget/teleport | 3.1 |
| Encounter density | Current caps are `18/32/40/40/48/48/48/48`; reserve is virtual | encounter director/runtime/stage data | Caps `32/44/56/64/72/72/72/72`; visible refill floors `12/16/20/24/28/32/36/40` | 3.2 |
| Pacing evidence | First cue/spawn/damage exist; first attack preparation is not explicit | encounter runtime diagnostics | Record and validate first preparation within 8 seconds | 3.3 |
| Directional shields | Catalog says frontal/sector; runtime uses one global multiplier/full ring | phase catalog, shield runtime, damage path, renderer | Drydock frontal arc and Crown three body-attached sectors with directional collision truth | 4.1 |
| Boss identity cues | Broad barrage lacks descriptor; wedge ring is not rendered; Archive Cross fires four shots | telegraph builder, boss patterns/runtime, renderer | Exact descriptors, wedge rendering, and X-shaped committed corridors | 4.2 |
| Boss pressure | Current movement, speed, reach, charge, and AOE values are independently owned | difficulty and pattern owners | Locomotion 1.25x, projectile speed 1.40x, reach 1.45x, charge 1.30x, area radius 1.25x; warning never reduced | 4.3 |
| Distance-growth idea | No current global or boss mechanic | projectile state and boss pattern owners | Siege Battery only; arm at 360, cap at 880, speed `0.75x->1.35x`, radius `1.0x->1.5x`, damage `1.0x->1.6x` | 4.4 |
| Boss death presentation | Exactly one explosion overlay grows/fades for two seconds | death runtime, renderer, manifest/workbench/spec | Remove explosion; keep body tint/dim/fade and exact safe cleanup | 4.5 |
| Authority drift | Specs/tests disagree on eight-cycle HUD, quota, facility blocking, shield form, explosion, and difficulty curve | product/visual specs and validators | Eight-cycle `Boss N/8` plus quota; pass-through facilities; directional boss defense; no explosion; eight-value runtime curve | 0.1 |
| Performance | Earlier native evidence is not current 72-count Web qualification | active performance policy/audit and prior plan | Capture controlled before state, then qualify exact clean 72-count native and Web workloads | 5.1-5.3 |

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership, safety, and
  validation decision is closed.
- Godot 4.7.1, repository wrappers, validators, capture drivers, Web export, and performance
  scenarios are available. Server/browser work will use the `npjt-port-guard` codex lane.
- Remaining unknowns are implementation-local and cannot change this contract.

## Tasks

### Phase 0: Canonical contracts and stale gates

Goal: make every later implementation target one coherent eight-cycle, 72-cap contract.

Preconditions:

- Clean commit `58a6e093` is the documentation baseline.
- The mandatory visual authority pair has been read/inspected and its sheet hash is
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.

Source owners: `docs/product/vehicle_game_spec.md`, `docs/design/VISUAL_SYSTEM.md`,
`.agents/design/DESIGN.md`, focused authority and replay validators

- [x] **0.1** Align canonical product and visual contracts with the locked decisions.
  - Change: remove ten-stage/no-quota drift, contradictory facility blocking, binary-only
    boss shield and explosion requirements; specify the one-line conditional HUD, hostile
    red footprints, facility-radius timer, exact 72 caps/floors, eight-value curve, and
    body-attached directional defenses.
  - Accept: `validate_document_authority.ps1` and
    `validate_cardborne_visual_authority.ps1` pass.
- [x] **0.2** Repair stale deterministic fixtures before feature edits.
  - Change: make engagement replay assert cap-aware deterministic reserve preservation
    rather than full packet materialization in one sample; retain birth/gate fingerprint,
    no-rear, burst, and no-teleport checks.
  - Accept: `validate_vehicle_engagement_replay.gd` passes both fixed seeds.

Batch gate:

- `git diff --check`; commit contract and stale-gate alignment separately from runtime
  behavior.

### Phase 1: Terminal and reward truth

Goal: defeat, victory, Settings, XP, and boss status agree with gameplay truth.

Preconditions:

- Phase 0 passes.

Source owners: `scripts/vehicle/vehicle_run.gd`, report/result builders, boss death runtime,
report panels, focused report/campaign validators

- [x] **1.1** Publish one frozen build/report snapshot to every terminal surface.
  - Change: pass current build rows through failure/stage/final contexts without UI
    calculation; derive boss clear state from completed cleanup.
  - Accept: a focused validator asserts partial and dense builds on defeat in Korean and
    English and rejects premature `CLEARED`.
- [x] **1.2** Remove competing boss reward ownership.
  - Change: make the cleanup/flow receipt authoritative and prevent boss retirement from
    adding XP, group rewards, or ordinary quota.
  - Accept: campaign and report validators assert zero boss-owned reward and correct totals.

Batch gate:

- `validate_vehicle_stage_report.gd`, `validate_vehicle_run_result_builder.gd`, and
  `validate_vehicle_eight_boss_campaign.gd` pass.

### Phase 2: Combat cues, facilities, and one-line conditional HUD

Goal: ownership, active conditions, facility role, radius, time, and hits are readable at a
glance without new raster assets or parallel gameplay truth.

Preconditions:

- Phase 1 passes; product/visual contracts own the revised semantics.

Source owners: visual profile, mystery-device runtime, gameplay presentation snapshot,
combat renderer and shaders, HUD presenter/component, localization, focused renderer/HUD/
facility validators

- [x] **2.1** Apply the hostile-area grammar to every damaging area shape.
  - Change: carry owner through descriptors; render circles, wedges, shockwaves, and
    corridors with danger-red full footprint, one thin near-black boundary, and four inward
    notches where the shape permits. Startup remains lighter than active.
  - Accept: renderer fixtures distinguish hostile footprints from player and neutral areas
    in color and grayscale and preserve exact dimensions.
- [x] **2.2** Expand and recolor facilities with effect-radius countdowns.
  - Change: radii become `1260/1260/1440/1080/1260`; Repair/Barrier restore `1/6` maximum
    hull per second, Gravity multiplier becomes `0.70`, Cryo `0.82`, Weakpoint `1.15`;
    same-kind effects choose the strongest and at most two distinct facility modifiers
    affect one actor. Repair is green, Barrier light blue, Gravity near-black fill with a
    pale boundary, Cryo ice blue, Weakpoint danger red. The large footprint perimeter clips
    clockwise to `active_ratio`; no symbol countdown remains.
  - Accept: facility/runtime/renderer validators assert exact values, overlap selection,
    role colors, full-area fill, and large-radius countdown geometry.
- [x] **2.3** Make pass-through facility hits visible.
  - Change: publish accepted hit position/direction/role and use the fixed effect store for
    one short local core flash/contour compression; the projectile continues and cannot hit
    the same facility twice.
  - Accept: both player and hostile projectiles produce one bounded receipt, preserve
    pass-through, and allocate no unbounded node/effect state.
- [x] **2.4** Extend the existing top-left cluster into one conditional-status row.
  - Change: gameplay publishes ordered meaningful statuses for Overflow Barrier, Dash
    Overdrive, Braced Fire, Hit Chain or Miss Compensation, and Last Stand. The HUD appends
    icon plus compact value to the existing progress/defeats/dash/active row. Full names and
    card rules remain outside HUD.
  - Accept: standard and 200% Korean/English fixtures show one line, at most five condition
    slots, stable priority, activation/charge/consume/reset/expiry, and no minimap overlap or
    clipping at 960/1280/1920 widths.

Batch gate:

- Focused facility, combat-renderer, HUD-presenter, stage-layout, localization, and visual-
  authority validators pass; background rendered capture covers one-line HUD, two active
  facility timers, overlapping footprints, hostile area, and reduced motion.

### Phase 3: Relevant movement and continuous 72-count pressure

Goal: enemies maintain authored roles while continuously presenting relevant, bounded
pressure up to the approved cap.

Preconditions:

- Phase 2 passes and current before-state performance evidence is recorded without a pass
  claim if the baseline is red or ineligible.

Source owners: engagement relevance policy/director, enemy movement orchestration,
encounter director/runtime, stage data, pacing diagnostics and validators

- [x] **3.1** Release stale engagement gates without erasing role movement.
  - Change: after at least `0.80s`, release a gate when player distance has increased for
    `0.80s` and gate/current-player directions have dot `< -0.20`, or the gate path adds
    more than `300` units versus immediate role policy. Never retarget or teleport.
  - Accept: deterministic fixtures cover relevant completion, both release conditions,
    pursuit, standoff, recovery, wall reposition, and no speed/teleport violation.
- [x] **3.2** Admit and replenish exact 72-count ordinary pressure.
  - Change: set caps `32/44/56/64/72/72/72/72`; continuously expedite eligible reserve
    packets when engaged-visible count is below `12/16/20/24/28/32/36/40`; seal admissions
    at boss warning; keep current attack-commit and denial budgets.
  - Accept: deterministic pacing/replay fixtures reach each cap/floor when authored reserve
    exists, never exceed 72, preserve reserve work, and keep first-visible/no-gap contracts.
- [x] **3.3** Record first meaningful attack preparation.
  - Change: publish the first committed startup/cue time through pacing snapshots and
    reports without scanning enemies from UI.
  - Accept: all eight stages prepare a meaningful attack within 8.0 seconds in the locked
    fixture and expose the measured value in diagnostics.

Batch gate:

- Movement, engagement replay, encounter pacing, run, spatial-grid, and exact-cap scenario
  validators pass with authored count/activity assertions intact.

### Phase 4: Boss identity, pressure, distance growth, and cleanup

Goal: every boss communicates and executes its authored mechanic under the revised pressure
without global defense shortcuts or an explosion overlay.

Preconditions:

- Phase 3 passes at exact 72 ordinary capacity.

Source owners: boss phase catalog/runtime/shield/death/pattern owners, attack telegraph
builder, projectile state/runtime, combat renderer, stage difficulty, focused boss validators

- [x] **4.1** Implement directional Drydock and Crown defenses.
  - Change: Drydock blocks 90% damage inside a body-facing frontal 110-degree arc and feeds
    blocked damage into its counterburst charge. Crown owns three 120-degree body-attached
    sector integrity values; only the hit sector intercepts damage and depleted sectors
    stay open. Publish exact arc/sector state for one retained segmented boundary.
  - Accept: front/rear/edge hits, facing lock, sector depletion, bypass, and defense-to-
    offense coupling pass deterministic tests and match rendered boundaries.
- [x] **4.2** Restore missing boss attack cues and Archive Cross geometry.
  - Change: broad barrage publishes startup/offscreen descriptors without a visible
    projectile route; projectile startup and live shots rely on muzzle anticipation,
    authored projectile bodies, and off-screen threat-radar direction. `wedge_ring`
    renders its exact damage footprint; Archive Cross uses two committed X corridors
    rather than four generic projectiles. Only beam attacks expose an exact corridor.
  - Accept: every boss attack kind has a startup descriptor and radar policy; projectile
    descriptors never render predicted paths even if stale input contains `show_path`;
    beams and delayed areas render only exact committed damage geometry; one-hit semantics
    and no final-commit retarget remain intact.
- [x] **4.3** Apply axis-specific boss pressure values.
  - Change: multiply locomotion by `1.25`, projectile speed by `1.40`, beam/projectile reach
    by `1.45`, charge speed by `1.30`, and circular/wedge radius by `1.25`; keep existing
    stage coverage scaling and add `0.15s` startup when a high-threat footprint exceeds the
    old maximum.
  - Accept: boss balance fixtures assert exact transformed values, monotonic progression,
    minimum warning, and escape corridor.
- [x] **4.4** Add Siege Battery distance-accelerating ammunition.
  - Change: one authored boss projectile kind arms at 360 traveled units and interpolates
    monotonically to its hard cap at 880: speed `0.75x->1.35x`, radius `1.0x->1.5x`, damage
    `1.0x->1.6x`. Size/trail state changes before damage; walls terminate it; threat radar
    covers dangerous offscreen approach.
  - Accept: distance samples, hard caps, collision, warning, pooling/reuse reset, and no
    application to ordinary/global projectiles pass.
- [x] **4.5** Remove the boss explosion and retain safe body-only cleanup.
  - Change: delete the shared explosion runtime/asset references and use attack disable,
    restrained hit tint, dim/desaturation, and body fade over exactly 2.00 seconds; reduced
    motion removes growth/impulse/hit-stop.
  - Accept: exactly one body remains during cleanup, zero explosion/effect raster instances
    exist, danger/reward is disabled, transition timing is exact, and manifest/workbench
    counts reconcile.

Batch gate:

- Boss patterns, exams, shields, campaign, renderer, semantic provider, asset coverage,
  workbench, visual authority, import, and focused run validators pass; rendered captures
  cover Drydock front/back, Crown sectors, broad barrage, wedge ring, Archive Cross, Siege
  acceleration stages, and body-only death.

### Phase 5: Production integration and 72-count qualification

Goal: prove the combined result in the actual native and Web products without weakening the
approved workload or thresholds.

Preconditions:

- Phases 0-4 pass and the worktree is clean at the candidate commit.

Source owners: project wrappers, capture/export/performance harnesses, active performance
policy and durable acceptance evidence

- [x] **5.1** Complete functional and rendered integration gates.
  - Change: run the relevant full validator set once, import, targeted captures for the
    affected UI/world states, and production Web export after feature completion. Do not
    reopen unrelated gameplay screens or repeat a broad capture matrix.
  - Accept: all named checks pass; affected rendered states cover the one-line HUD at its
    dense 960x540/200% boundary, facility footprints/timers, hostile areas, directional
    shields, boss cues, and terminal build rows in the languages and motion modes they
    change.
- [ ] **5.2** Qualify exact native 72-count workload.
  - Change: run the release performance scenario on a clean, isolated checkpoint with exact
    actor/projectile/effect/attack activity and eligible metadata.
  - Accept: scenario validity passes and native release thresholds pass; report the precise
    label `native release performance passed` only then.
  - Current evidence: clean commit `65afb5ea`, Godot 4.7.1, focused 1280x720, 10-second
    warmup and 60-second sample produced a valid exact-72 workload with ten pressure
    samples, but release physics failed at p95 `7.159 ms` versus `6.0 ms` and p99
    `9.078 ms` versus `8.0 ms`. All other threshold checks passed. Evidence is retained at
    `build/performance/combat-readability/65afb5ea-production-replay-native-60s.json`.
- [ ] **5.3** Qualify the production built-Web 72-count workload.
  - Change: use `npjt-port-guard`, the fastrun manager codex lane, the built export, and the
    same workload/viewport/warmup/duration/focus contract; inspect interaction and pixels.
  - Accept: scenario validity, interaction smoke, and Web release thresholds pass; report
    `Web release performance passed` only then.
  - Guard: if 72 fails, preserve the failed evidence and profile the named simulation,
    presentation, render, or browser owner. Do not lower count, activity, resolution,
    quality, physics rate, or threshold.

Batch gate:

- Update the existing durable performance/acceptance evidence with commit, clean state,
  engine, platform, viewport, workload, warmup, duration, isolation, validity, and precise
  native/Web labels.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | Owning focused `./tools/godot.ps1 --headless --path . --script res://tools/validation/<validator>.gd` | A task changes its owner | Relevant implementation input changes |
| Phase 0 | document authority, visual authority, engagement replay, `git diff --check` | Contract/fixture edits complete | A Phase-0 input changes |
| Phase 1 | stage report, result builder, eight-boss campaign | Terminal/reward tasks pass | Report/reward input changes |
| Phase 2 | facility, renderer, HUD presenter/layout/localization, background capture | Cue/HUD/facility tasks pass | Phase-2 input changes |
| Phase 3 | movement, replay, pacing, run, grid, exact-cap scenario | Movement/density tasks pass | Phase-3 input changes |
| Phase 4 | boss patterns/exams/shields/campaign, renderer/assets/workbench, import, capture | Boss tasks pass | Phase-4 input changes |
| Final functional | relevant full validators, import, production Web export, built-product smoke | All phases pass | A final functional input changes |
| Final performance | clean exact-72 native release, then same built-Web release workload | Functional final gate passes | Performance-affecting input changes |

Validation rules:

- Run the narrowest check that proves the current task.
- Run each named phase gate once after its owned tasks pass.
- Rerun a failed check only after a relevant implementation change or a new hypothesis can
  produce new evidence.
- Record known non-blocking warnings once instead of rediscovering them.
- Never treat headless success as rendered proof, export success as Web interaction proof,
  or visual-budget success as release-performance success.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A material fact contradicts this contract | Stop the affected branch and revise the contract | Do not let implementation choose a new product/UX/architecture contract |
| One-line HUD approaches minimap at 960x540/200% | Shorten values and gaps within existing minimums; preserve all meaningful states and one line | Escalate only if fitting requires hidden state or unreadable text |
| Facility 3x overlap exceeds two effects | Select same-kind strongest, then two distinct effects by stable facility ID priority | Never multiply unbounded effects |
| 72-count pool admission is full | Preserve reserve and retry under existing bounded scheduler policy | Never grow beyond declared pools during combat |
| Native/Web 72-count performance fails | Preserve evidence, attribute the measured owner, optimize bounded algorithms/data/presentation, and rerun only after a causal change | Approval required for cap/threshold/quality/physics reduction or native/thread/dependency escalation |
| Boss pressure violates warning/corridor | Increase warning or reduce only the offending per-pattern pressure within the locked axis ceiling | Do not globally undo the approved pressure revision |
| Explosion deletion leaves manifest/workbench drift | Stop promotion and reconcile every reference/count in the same commit | Do not leave a missing production reference |

Implementation-local discoveries may be handled inside the locked contract when they
cannot change scope, visible behavior, ownership, architecture, safety, or acceptance.

## Anti-Rework Execution Rules

- On start or resume, read this contract and inspect the worktree only enough to confirm
  checkpoint inputs, then continue from the first unchecked task whose prerequisites pass.
- Treat checked tasks and recorded passing evidence as complete unless a relevant input
  changed or evidence is missing.
- Run each check at its declared cadence; do not repeat a passing check for confidence.
- Rerun a failed check only after a relevant code change or a new causal hypothesis.
- Mark a task complete only after its acceptance check passes; update its checkbox and the
  progress pointer in the same edit.
- If reality contradicts a material decision, stop that branch and revise this contract.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 5.
- Next task: optimize the measured `enemies_and_grid` owner without reducing the exact-72
  workload, decision/motion cadence, collision truth, attack activity, or thresholds; rerun
  native only after a causal change, then run the same built-Web workload only after native
  passes.
- Last completed gate: 5.1; focused validators and affected-state captures pass, and the
  production Web export succeeds at implementation commit `65afb5ea`. The native scenario
  is now valid after `c8b8364d` preserved barrier-bypassing denial pressure, and
  `65afb5ea` balanced 10 Hz decision lanes, but the retained authoritative result remains
  red in the `enemies_and_grid` physics owner (p95 `5.49 ms`, p99 `6.98 ms`). The reopened
  4.2 visual regression gate passes: broad-barrage projectile descriptors remain available
  to threat radar while the cue policy and renderer expose no predicted projectile-path
  mode, including stale `show_path` input.
- Update rule: after a checkpoint passes, record concise evidence, check the task, and
  advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check, guard, phase gate, and final gate passes.
- The production built-Web product is visually inspected and interactively exercised.
- Exact clean 72-count native and Web same-workload evidence receives precise pass labels.
- Durable product, visual, performance, and validation knowledge is updated in its existing
  owner; no active evidence-only recommendation competes with the accepted contracts.
- Frontmatter status is changed to `done` only after implementation is complete.

Replan when:

- A material discovery invalidates a locked product, UX, architecture, safety, dependency,
  or validation decision.

Do not replan or stop for:

- Implementation-local mechanics contained by this contract.
- A passing check whose relevant inputs have not changed.
- A 72-count performance failure that can be addressed inside existing bounded owners
  without weakening workload or thresholds.
