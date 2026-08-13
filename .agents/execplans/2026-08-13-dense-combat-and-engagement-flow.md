---
type: plan
status: active
owner: BK
created: 2026-08-13
last_reviewed: 2026-08-13
topic: Dense-combat runtime recovery and varied enemy engagement flow
scope: Cardborne ordinary-enemy birth, approach, simulation, spatial queries, combat receipts, presentation snapshots, native/Web qualification, and durable product contracts
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../cardborne-performance-engineering-policy.md
  - ../cardborne-runtime-architecture-audit.md
  - ./2026-08-11-dense-combat-progression-and-run-completion.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/performance/2026-08-13-dense-enemy-stutter-evidence.md
  - ../../docs/performance/2026-08-13-dense-enemy-architecture-options.md
  - ../../docs/performance/2026-08-13-enemy-arrival-and-engagement-research.md
  - ../../docs/performance/2026-08-13-enemy-arrival-conclusion-ko.md
---

# Dense Combat and Engagement Flow - Execution Contract

Replace Cardborne's repeated dense-enemy scans with bounded, incremental typed-GDScript owners and
add a deterministic engagement director that spreads actual combat arrivals across direction and
time. The implementation keeps the current eight-sector off-screen birth contract, authored enemy
counts, combat truth, and single-threaded native/Web release shape. Work proceeds in independently
validated checkpoints and ends only after gameplay, deterministic, native, and built-Web gates pass.

## Purpose

- Objective: remove the high-count physics backlog and the common rear-tail enemy mass while
  preserving Cardborne's authored five-stage pressure and fair, readable combat.
- Deliverable: a low-frequency engagement reservation owner; incremental enemy storage, scheduling,
  spatial, status, projectile, and snapshot paths; updated product/validator contracts; retained
  native/Web evidence; and removal of replaced hot-path owners.
- Completion state: the engagement replay meets its distribution and fairness checks; every focused
  behavior validator passes; the exact 276-enemy peak and 320-enemy capacity workloads remain valid;
  clean native thresholds pass; the same-commit Web export, static release contract, and focused
  built-Web run pass; and no old/new competing runtime authority remains.

## Scope and Boundaries

In scope:

- Distinguish object birth, arrival scheduling, approach, engagement entry, and attack commitment.
- Preserve all-eight-sector births but reserve a separate target-relative engagement sector and ETA.
- Add role-aware ETA selection, exactly two deterministic candidate choices, one-shot approach
  gates, one ordinary-play escape corridor, and two authored patterns.
- Keep one bounded incremental reservation table; no full-enemy scan decides a reservation.
- Move ordinary hot fields to fixed 320-slot packed columns with stable slot/generation handles.
- Replace per-physics schedule rebuilding with persistent 60/30/20/10-Hz due lanes.
- Replace capacity-wide overlap snapshots with incrementally invalidated active rows.
- Keep exact LOS/collision narrow phases while reducing candidate preparation and duplicate reads.
- Process statuses through sparse active-slot membership.
- Move projectile hot state and query receipts into bounded reusable storage after enemy work.
- Publish immutable current/previous presentation frames to renderer, HUD, radar, and minimap.
- Update observation telemetry, deterministic validators, the product specification, performance
  fixtures, Web export/static validation, and durable evidence.

Out of scope:

- New player-facing art, UI layout, copy, audio, localization, or changes to the concurrent upgrade
  artwork workbench.
- A general-purpose ECS, a catch-all `DenseCombatWorld`, or a wholesale `VehicleRun` rewrite.
- New production dependencies, engine changes, GDExtension, custom Web templates, worker threads,
  direct Server ownership, or GPU compute.
- Lower physics tick rate, changed catch-up ceiling, reduced actor/projectile/effect counts, reduced
  collision accuracy, reduced attack activity, reduced visual quality, or weaker thresholds.
- Far-enemy aggregate/impostor simulation, silent teleportation, or despawn/respawn used to repair
  engagement balance.
- Re-authoring stage quotas, enemy stats, upgrade behavior, boss behavior, or global difficulty.
- GitHub push, itch.io publication, or changes to the deployment repositories. A later publish will
  inherit local fixes only after the normal export/commit/deployment workflow is run.

Constraints and invariants:

- Godot `4.7.1.stable.official.a13da4feb`, GDScript, GL Compatibility, and repository-owned
  `./tools/godot.ps1` remain the implementation/runtime contract.
- The current no-thread/no-extension Web preset remains unchanged.
- Preserve ordinary active caps `1/124/172/224/276`, enemy store capacity 320, player projectile
  capacity 240, hostile projectile capacity 120 with its 24-shot boss reserve, and effect capacity 96.
- Preserve manual aim, held primary fire, dash, seekers, EMP, pickups, cards, authored encounter
  packets, quota-gated bosses, continuous stages, and Korean/English completeness.
- Preserve 0.90-second cue lead, at least 1.20 seconds between windows, 0.16-second unit rounds,
  maximum four births per tick, deterministic packet fencing, cap reservation, and retry behavior.
- Preserve off-screen birth distance 900-2400 pixels, deterministic 2800-pixel relaxation,
  220-pixel visible margin, 320-pixel hard separation, and balanced use of all eight birth sectors.
- Preserve 60-Hz critical phases, 30-Hz near motion, 20-Hz far motion, and 10-Hz ordinary decisions.
- Preserve exact attack startup/active/recovery timing, threat budgets, ranged/denial/rammer limits,
  earliest swept-hit ordering, contact truth, damage/shield/status order, XP, kill credit, and boss
  reserve behavior.
- Ordinary engagement distribution must never seek a perfect surround. A pattern reserves at least
  a three-sector rear-side escape arc and may not grant attack permission.
- Existing active actors are never teleported or silently reassigned. A one-shot gate is fixed at
  birth; sharp player reversal causes expiry to normal role movement, not retargeting.
- `VehicleRun` remains orchestration. It may call new owners and apply receipts but does not own
  packed storage, reservation policy, queue membership, spatial indexes, or presentation buffering.
- Concurrent untracked design/UI files are user-owned. Do not stage, edit, move, or delete them.

Destructive or irreversible actions:

- None. Each checkpoint is a scoped Git commit and can be reverted without touching user-owned work.

Exact actions requiring owner or user approval:

- Any fallback to GDExtension, threads, custom Web templates/headers, a dependency, global physics
  cadence, approximate off-screen truth, reduced workload, reduced collision, or changed thresholds.
- GitHub push or itch.io publication.

## Domain and Ownership Contract

| Term | Meaning | Canonical runtime owner |
| --- | --- | --- |
| Birth | Materializing one exact enemy at a safe off-screen world position. | `VehicleSpawnAllocator` and `VehicleEncounterRuntime` |
| Arrival window | Cue, admission, capacity reservation, and due birth rounds. | `VehicleEncounterRuntime` |
| Engagement reservation | Target-relative sector, ETA bucket, fixed approach gate, lifecycle, and load counters. | new `VehicleEngagementDirector` |
| Approach | Movement toward a fixed reservation gate before ordinary role movement takes over. | ordinary enemy simulation using existing movement/route policies |
| Engagement entry | Gate completion or deterministic expiry that releases the actor to normal role behavior. | `VehicleEngagementDirector` lifecycle plus enemy state |
| Attack commitment | Permission to start an authored harmful action. | existing encounter and role attack contracts; unchanged by a reservation |
| Dense enemy state | Bounded hot numeric state, stable handles, transitions, counters, and sparse membership. | `VehicleEnemyStore` |
| Due work | Persistent cadence membership and due-slot consumption. | `VehicleEnemyUpdateSchedule` |
| Spatial truth | Incremental occupancy and candidate preparation; exact checks remain final truth. | `VehicleSpatialGrid` and existing geometry/rule owners |
| Side effects | Damage, progression, spawning, audio, and effect application from bounded receipts. | existing owners coordinated by `VehicleRun` |

Callers see compact commands, handles, due slots, receipts, and snapshots. Packed layout, queue
indices, relaxation scoring, generation checks, and buffer reuse remain hidden inside their owners.

## Locked Engagement Design

### Birth and engagement stay separate

Canonical birth windows continue to use all eight sectors. `birth_sector` remains a world-position
fact. The new `engagement_sector` is relative to the player's travel heading sampled when the
arrival window is admitted. At player speed below 80 pixels/second, a seeded window heading is used.

The allocator keeps its geometry tiers T0-T3. Role-aware target-distance preference replaces the
identity-only distance hash:

- pursuit: prefer 1650 or 2100 pixels;
- standoff: prefer 1200 or 1650 pixels;
- escort/support: prefer 1200 pixels;
- stationary/special roles: retain their existing authored path and receive no ordinary gate.

The selected position must still pass all existing off-screen, floor, clearance, and deterministic
fingerprint checks. Distance preference never weakens geometry truth.

### Reservation data and lifecycle

`VehicleEngagementDirector` owns at most 320 fixed slots and packed numeric arrays. A reservation
handle is `{slot, generation}`. Hot fields are numeric; packet/cue/pattern identifiers remain cold
debug metadata outside per-tick loops.

Each live reservation contains:

- engagement sector `0..7`;
- ETA bucket `0..31`, each bucket 0.5 seconds wide;
- absolute expected engagement time;
- fixed predicted-player anchor;
- fixed approach gate;
- absolute expiry time;
- state `reserved`, `materialized`, or `released`; and
- exactly one counter contribution while reserved/materialized.

Transitions are:

```text
free -> reserved -> materialized -> released -> free(next generation)
                  \-> cancelled -> free(next generation)
reserved ----------> cancelled -> free(next generation)
```

Only reservation, accepted birth, gate completion, expiry, spawn failure, defeat, retirement, and
stage reset mutate counters. Debug reconciliation may scan in validators but never in shipping
physics work.

### ETA and gate constants

- Candidate transit time is `birth_to_gate_distance / effective ordinary speed`.
- Effective speed is supplied from the same stage/difficulty/enemy profile used by `_make_enemy`;
  no duplicate base-speed table is permitted.
- Target prediction reuses `VehicleEnemyTargetingPolicy.movement_focus()` and its existing family
  clamps. The predicted anchor is sampled once and never follows later player movement.
- Gate radius from the predicted anchor is 520 pixels for pursuit, the existing distance-band
  midpoint for standoff/escort/support, and clamped to 430-600 pixels.
- A gate completes within 96 pixels.
- Expiry is `birth time + clamp(transit ETA + 2.0 seconds, 4.0, 18.0)`.
- ETA buckets are selected from absolute expected engagement time modulo the fixed 32-bucket ring;
  generation/epoch disambiguates reused buckets.
- Each unit samples exactly two eligible deterministic candidate sectors. Candidate score is
  `reserved sector/ETA load * 16 + sector debt + angular travel penalty + seeded tie fraction`.
  Lower score wins. Debt is bounded `0..8`, increments for eligible unserved sectors once per
  admitted window, and resets to zero when selected.

### Patterns and escape contract

Two patterns are the complete first production vocabulary:

- `broad_crescent`: relative sectors `-2,-1,0,+1,+2`; the rear three-sector arc remains open.
- `two_offset_streams`: relative sectors `-2,-1,+1,+2`; unit rounds alternate left and right and
  keep the forward center plus rear three-sector arc unreserved.

Window pattern sequence is deterministic:

- windows 0 and 2 use `broad_crescent`;
- window 1 uses `two_offset_streams`;
- single-unit opening packets use the current birth behavior and no approach gate.

Rear sectors are not ordinary engagement candidates in this first release. Existing enemies may
naturally move behind the player, and an authored future beat may add telegraphed rear pressure only
through a separate product decision.

If both sampled engagement candidates are invalid because their gates fall outside walkable field
geometry, sample the next two eligible sectors in deterministic score order. If no gate is valid,
birth proceeds with no gate and the actor immediately uses existing role movement. This fallback
does not retry, teleport, or block a valid birth window.

### Movement handoff

Reservation scalars are copied into `VehicleEnemyState` at materialization and cleared on pooled
reuse. While a gate is active, `_desired_enemy_velocity()` uses the fixed gate as movement focus.
Existing LOS/route recovery, turn response, speed multipliers, collision, separation, decoy, and
committed attack paths retain priority. Gate state changes only on an existing 10-Hz decision or a
critical transition; it does not introduce a new per-frame decision pass.

Crossing the 96-pixel radius or expiry releases the reservation and immediately resumes existing
pursuit/standoff/escort/support targeting. Attack permissions and committed targets are never
rewritten by the engagement director.

## Locked Dense-Simulation Design

### Storage

Evolve `VehicleEnemyStore`; do not add a general ECS. Stable `spatial_slot` plus
`runtime_generation` becomes the public handle. Add fixed 320-element packed columns only for hot
ordinary state used by scheduling, motion, spatial, contact, status, and presentation. Keep boss,
specialist, localized, authored, and debug-only state cold until a measured phase requires it.

The store owns accepted spawn, activation/deactivation, phase/cadence membership changes, commit
changes, defeat/retirement, ID lookup, and incremental counters. Existing `EnemyState` remains a
cold compatibility facade during migration and is removed from each migrated hot loop when the
corresponding packed column becomes canonical. Shipping code must not simulate both copies.

### Scheduling

Evolve `VehicleEnemyUpdateSchedule` from `rebuild()` to persistent bounded lanes:

- critical lane: every physics tick while an actor is in startup/active/interrupted recovery;
- near-motion ring: 30 Hz;
- far-motion ring: 20 Hz;
- decision ring: 10 Hz;
- sparse timer/status lanes for actors that actually own those states.

Spawn, activation, phase change, near/far band change, death, and retirement update membership once.
Due consumption uses stable slot order and accumulated delta. The old full rebuild is retained only
as a validator oracle until the persistent path passes, then deleted.

### Spatial and movement

Evolve `VehicleSpatialGrid` as the only dynamic actor-occupancy owner. Update membership only when
a body changes cells, activation, generation, radius, or life state. Local-overlap rows are built
only for due owners and invalidated by owner generation plus position revision. Preserve the eight
nearest-neighbor cap, distance ordering, actor-ID tie break, deterministic zero-distance direction,
and exact overlap test.

Static tactical layout stays in `VehicleStageTacticalLayout`. Runtime structural walls gain a
bounded cell broad phase only if reached by the migrated movement path. `_runtime_has_line_of_sight`,
`_runtime_first_cover_hit`, and the stage-rule geometry remain exact narrow-phase truth. Attack
commit LOS is never served from a stale movement cache.

Ordinary movement execution moves into `scripts/enemies/vehicle_enemy_simulation.gd`. It owns the
ordinary phase order and numeric hot-loop execution, invokes existing pure targeting/movement/local
steering/pursuit policies, and fills caller-owned movement, attack-intent, contact, spawn, and state
receipts. `VehicleRun` applies side effects through existing owners.

### Projectiles and statuses

After enemy scheduling/movement passes its phase gate, evolve `VehicleProjectileStore` to packed
player/hostile columns with caller-owned candidate and hit receipts. Preserve exact first-contact
`t`, wall/structure/actor precedence, group exit, pierce, bounce, interception, boss reserve, damage,
and status application.

The enemy store maintains a sparse list of status-bearing slots. `VehicleStatusRuntime` retains
stacking, timing, speed, damage, and renderer receipt semantics; only membership and hot storage
change. Empty-status actors receive no status tick call.

### Presentation

Add one bounded current/previous simulation-frame owner after correctness and physics gates identify
presentation publication as remaining material work. It publishes enemy/projectile/effect transforms,
facing, phase, health, radar/minimap markers, and cues. Renderer/HUD/radar/minimap receive immutable
frames and cannot read or mutate live hot storage. Interpolation affects pixels only, never physics,
AI, attacks, collision, cooldowns, or progression.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Rear-tail cause | allocator balances all eight births; movement later converges on a faster moving player | spawn allocator, targeting/movement policies, engagement research | keep birth truth; add separate ETA/sector/gate owner | 1.1-2.4 |
| Fairness | current cues and attack caps are separate from movement | encounter runtime/spec and attack validators | unchanged cues/caps; open rear arc; no attack authority in director | 2.1-2.5 |
| Performance owner | enemy scheduling/decision/motion/LOS/overlap and projectile work dominate; render is green | retained scenario/ablation evidence | typed GDScript incremental owners first | 3.1-6.3 |
| Scheduling cadence | full schedule rebuild currently preserves 60/30/20/10-Hz opportunities | enemy update schedule and validator | persistent lanes with identical cadence/order/deltas | 3.1-3.3 |
| Spatial truth | grid already has stable pooled slots and exact candidate oracles but rebuilds overlap snapshot | spatial grid and steering validators | incremental rows with same narrow truth | 4.1-4.3 |
| Combat truth | Run owns exact side effects; projectile store pools objects | projectile/contact/status/run validators | bounded receipts; Run remains side-effect coordinator | 5.1-6.3 |
| Release targets | capacity and frame thresholds live in recorder; Web is single-threaded | performance recorder, export preset, itch validator | thresholds and preset unchanged | 7.1-8.4 |
| Concurrent design work | untracked upgrade plan/report exists and other task processes are active | current `git status` and process inspection | exclude files; defer authoritative timing until quiescent | all, especially 0.2/8.2 |
| Deployment inheritance | GitHub/itch use exported committed code | export workflow and evidence research | validate local native/Web; do not publish | 8.3-8.4 |

Readiness statement:

- Every material product, architecture, dependency, data, gameplay, ownership, safety, and
  validation decision is closed.
- Required Godot 4.7.1 runtime and repository wrappers are available. `--path`, `--headless`,
  `--script`, `--import`, `--rendering-method`, `--resolution`, `--disable-vsync`, and
  `--export-release` were verified against the installed binary.
- The current all-eight birth rule is retained; only engagement sectors are pattern-controlled.
- Calibration constants are fixed above. Changing them outside acceptance repair requires a plan
  decision note, not executor preference.
- Remaining unknowns are implementation-local. Failure to meet a locked acceptance threshold uses
  the predetermined contingency and does not authorize a new architecture or product tradeoff.

## Tasks

### Phase 0: Baseline contract and observation owners

Goal: preserve a comparable before state and add observation that can prove the engagement problem
without changing gameplay.

Preconditions:

- Read this contract, root instructions, performance policy, current product spec, and the four
  linked 2026-08-13 evidence documents.
- Do not run authoritative timing while any unrelated Godot, capture, export, browser automation,
  or other heavy process is active. Do not terminate it.

Source owners: `scripts/performance/vehicle_performance_recorder.gd`,
`scripts/performance/vehicle_manual_performance_trace.gd`,
`scripts/performance/vehicle_performance_scenario.gd`, `scripts/encounters/vehicle_encounter_runtime.gd`,
`tools/validation/validate_vehicle_performance_scenarios.gd`,
`tools/validation/validate_vehicle_manual_play_trace.gd`

- [x] **0.1** Add bounded engagement-distribution telemetry.
  - Change: record at 4 Hz the rear-hemisphere engaged share relative to player velocity, eight
    engagement-sector counts, largest empty gap, births and gate completions per 0.5-second bucket,
    longest rear-tail interval, active reservations, expiry/cancel counts, and director CPU. Use
    fixed packed counters and aggregates; do not retain per-enemy time-series state.
  - Accept: telemetry validators prove empty, stationary, moving, reset, and capacity-bound cases;
    ordinary play without a recorder performs no debug JSON duplication.
  - Guard: existing performance scenario counts, thresholds, and output schema remain backward
    readable; new fields are additive.
- [ ] **0.2** Capture the current clean native baseline when the machine is quiescent.
  - Change: commit 0.1, set exact commit/dirty metadata, and run one 10-second warmup + 60-second
    `peak_horde` and `capacity_pressure` pair at 1280x720 GL Compatibility with VSync disabled.
    Also run one 5-second warmup + 10-second 64/128/192/256/320 scaling sweep. Store ignored JSON
    under `build/performance/dense-engagement/` and summarize it in this plan.
  - Accept: every JSON is scenario-valid, focused, exact-count, exact viewport/renderer, and names
    its clean commit. A red result is a valid baseline, not a task failure.
  - Guard: if competing processes or focus contamination appear, preserve the invalid sample label,
    wait for quiescence, and rerun only the invalid scenario.

Batch gate:

- Engagement telemetry has focused validation, and one eligible current-runtime native baseline is
  recorded before behavior or hot-path implementation begins.

### Phase 1: Product contract and deterministic engagement director

Goal: implement reservation logic as a pure bounded owner without changing live movement.

Preconditions:

- Phase 0 batch gate passes.

Source owners: `docs/product/vehicle_game_spec.md`,
`scripts/encounters/vehicle_engagement_director.gd`,
`scripts/encounters/vehicle_spawn_allocator.gd`,
`scripts/vehicle/stages/vehicle_combat_stages.gd`,
`tools/validation/validate_vehicle_engagement_director.gd`,
`tools/validation/validate_vehicle_spawn_allocation.gd`,
`tools/validation/validate_vehicle_multi_sector_spawns.gd`

- [ ] **1.1** Promote the accepted birth/engagement distinction into the product spec.
  - Change: preserve all-eight birth clauses and define reservation lifecycle, two patterns, escape
    arc, role-aware distance preference, one-shot gate, fallback, unchanged attack permission, and
    acceptance metrics.
  - Accept: document authority validation passes for task-owned docs and existing spawn-contract
    validator constants have an exact corresponding spec clause.
- [ ] **1.2** Add the fixed-capacity engagement director.
  - Change: implement configure/reset/reserve/confirm/complete/expire/cancel/release and fill-into
    debug/telemetry APIs with 320 stable generation slots and packed sector/ETA counters.
  - Accept: new focused validator proves deterministic fingerprints, two-choice selection, bounded
    debt, 32-bucket epoch safety, every lifecycle transition, stale-handle rejection, reset, capacity
    rejection, and counter reconciliation.
  - Guard: validator source scan confirms the production reserve path accepts no `enemies` array
    and performs no full-population reconciliation.
- [ ] **1.3** Make allocation role-aware without weakening birth geometry.
  - Change: select target distance by movement family and effective speed input; attach reservation
    request data while preserving existing allocation order and geometry tiers.
  - Accept: direct and prewarmed allocation fingerprints match; every role multiset, distance,
    off-screen margin, clearance, deterministic seed, all-eight birth-sector balance, and edge-field
    fallback remains valid.
- [ ] **1.4** Add only the two locked authored pattern identifiers to stage packet data.
  - Change: assign broad-crescent/two-stream sequence to multi-window surge packets; opening
    singletons have no gate.
  - Accept: encounter pacing validator proves counts, roles, windows, cues, caps, and packet timing
    unchanged except the additive pattern identifier.

Batch gate:

- `validate_vehicle_engagement_director`, spawn allocation, multi-sector spawn, encounter pacing,
  and `git diff --check` pass; no runtime movement behavior has changed yet.

### Phase 2: Live reservation lifecycle and one-shot approach

Goal: make actual combat arrivals varied while preserving birth safety, movement speed, collision,
and attack contracts.

Preconditions:

- Phase 1 batch gate passes.

Source owners: `scripts/encounters/vehicle_encounter_runtime.gd`,
`scripts/enemies/vehicle_enemy_state.gd`, `scripts/vehicle/vehicle_run.gd`,
`scripts/enemies/vehicle_enemy_targeting_policy.gd`,
`scripts/enemies/vehicle_enemy_movement_policy.gd`,
`tools/validation/validate_vehicle_arrival_scheduler.gd`,
`tools/validation/validate_vehicle_enemy_targeting_policy.gd`,
`tools/validation/validate_vehicle_enemy_movement_policy.gd`,
`tools/validation/validate_vehicle_enemy_contact.gd`

- [ ] **2.1** Reserve engagement gates when a window is admitted.
  - Change: `_admit_due_window` requests reservations after birth allocation; spawn specs carry a
    handle and immutable gate scalars; spawn failure cancels; accepted append confirms; stop/reset
    cancels queues. `_process_due_round` remains the only birth emitter.
  - Accept: arrival scheduler proves 12 cues, first-birth cue identity, 0.90/1.20/0.16 timing,
    maximum four births/tick, cap reservation, packet fence, starvation, cancellation, and reset.
- [ ] **2.2** Persist and safely reset approach state.
  - Change: add typed reservation/gate scalars to pooled enemy state and clear every field on reuse.
    All defeat, retirement, stage reset, carrier/splitter spawn, and rejected-add paths release or
    omit reservations exactly once.
  - Accept: enemy store and new director tests pass repeated pool reuse, stale generations, swap
    retirement, boss-only retirement, and full clear with zero reservation debt.
- [ ] **2.3** Apply gate-first movement at the existing decision cadence.
  - Change: use the fixed gate as movement focus until the 96-pixel completion or locked expiry;
    existing committed/decoy/recovery priorities and exact collision paths stay intact.
  - Accept: targeting/movement/update-schedule validators prove stable gate, no per-frame retarget,
    10/30/20/60-Hz cadence, unchanged speed/turn/band behavior after release, and deterministic
    expiry on reversal or unreachable geometry.
- [ ] **2.4** Prove fairness and distribution in a deterministic moving-player replay.
  - Change: add a replay fixture that runs births, approach, gate lifecycle, collision, and attack
    admission for both patterns across representative fields and seeds.
  - Accept: within each 12-second steady-travel sample, at least three engagement sectors complete;
    no rear engagement reservation is created; the largest reserved burst is at most four per
    0.5 seconds; an open three-sector rear arc remains; exact birth/cue/role/count fingerprints and
    attack commit caps pass; no teleport occurs.
  - Guard: contact validator preserves swept hull contact, earliest contact, cooldown, and persistent
    overlap truth.
- [ ] **2.5** Record a bounded normal-play engagement trace.
  - Change: after other Godot work is quiet, use the manual trace once through a representative
    moving combat segment and close normally.
  - Accept: JSON is valid and contains engagement metrics; evidence shows at least three completed
    directions and no director-created rear reservation. This is gameplay evidence, not a release
    performance pass.

Batch gate:

- All Phase 2 focused checks pass and the user-visible tail mechanism is corrected without changing
  counts, cadence, collision, or attack limits.

### Phase 3: Event-owned enemy state and persistent due lanes

Goal: eliminate schedule/aggregate full scans and establish the packed compatibility boundary.

Preconditions:

- Phase 2 batch gate passes.

Source owners: `scripts/enemies/vehicle_enemy_store.gd`,
`scripts/enemies/vehicle_enemy_update_schedule.gd`,
`scripts/enemies/vehicle_enemy_simulation.gd`, `scripts/vehicle/vehicle_run.gd`,
`tools/validation/validate_vehicle_enemy_store.gd`,
`tools/validation/validate_vehicle_enemy_update_schedule.gd`,
`tools/validation/validate_vehicle_dense_simulation.gd`

- [ ] **3.1** Add stable packed hot columns and event-owned counters.
  - Change: store position/previous position/velocity/desired velocity; health/radius/speed/timers;
    role/family/phase/lane/cell/flags/generation; active/elite/boss-add/armed-minelet/family/commit/
    carrier-child counts. Transition APIs are the only shipping mutation path.
  - Accept: store validator proves 320 capacity, handle generation/wrap, ID lookup, pool reuse,
    every counter transition, and debug full reconciliation. Existing state/store consumers pass.
  - Guard: no localized text, debug dictionaries, or authored packet data enters packed hot columns.
- [ ] **3.2** Replace `rebuild()` with persistent due lanes.
  - Change: register/unregister/reclassify slots on store transitions; consume bounded due slots in
    stable order with accumulated deltas and exact commit accounting.
  - Accept: old rebuild oracle and persistent scheduler produce identical due/critical/decision/
    motion order and deltas for 64/128/192/276/320 actors across spawn, deactivate, near/far change,
    phase change, death, and reuse traces.
  - Guard: shipping `_update_enemies` contains no scheduler full-array rebuild.
- [ ] **3.3** Replace recurring aggregate and sparse-state scans.
  - Change: remove `_refresh_enemy_frame_aggregate`, `_active_mobile_count`, `_live_elite_count`,
    `_live_boss_add_count`, `_armed_minelet_count`, and carrier/status membership scans as shipping
    authorities; use store counters and sparse lists.
  - Accept: Run, encounter, store, status, facility/carrier, performance-scenario, and dense-simulation
    validators match old oracle outputs for all transitions.

Batch gate:

- `profile_vehicle_pressure.gd` shows the migrated schedule/aggregate owner at least 2x faster than
  the retained Phase 0 baseline with identical diagnostic fingerprints. This is a trend gate, not a
  release pass. If the gain is smaller, keep correct code only when the full capacity diagnostic is
  materially lower; otherwise revert the phase commit and revise this contract before proceeding.

### Phase 4: Incremental spatial rows and ordinary simulation

Goal: eliminate capacity-wide overlap preparation and move ordinary numeric execution out of the
orchestrator without changing exact geometry or behavior.

Preconditions:

- Phase 3 batch gate passes.

Source owners: `scripts/combat/vehicle_spatial_grid.gd`,
`scripts/enemies/vehicle_enemy_local_steering.gd`,
`scripts/enemies/vehicle_enemy_simulation.gd`, `scripts/vehicle/vehicle_run.gd`,
`scripts/vehicle/vehicle_stage_tactical_layout.gd`,
`tools/validation/validate_vehicle_spatial_grid.gd`,
`tools/validation/validate_vehicle_enemy_local_steering.gd`,
`tools/validation/validate_vehicle_dense_simulation.gd`

- [ ] **4.1** Make overlap rows incremental and due-owner only.
  - Change: remove global snapshot clear/copy; build or reuse a row only for a due owner; invalidate
    by generation, position revision, active state, radius, or nearby cell revision.
  - Accept: randomized brute-force oracle passes radius/segment/boundary/zero-distance/reuse cases;
    eight-neighbor ordering and deterministic separation are byte-for-byte stable.
- [ ] **4.2** Add bounded runtime-wall candidate preparation.
  - Change: index dynamic structural walls by existing field cells and fill caller-owned candidates;
    retain exact segment/circle checks as final truth.
  - Accept: navigation, attack-route readability, destructible terrain, spatial grid, movement, and
    projectile cover oracles prove no missed blocker or changed earliest hit.
- [ ] **4.3** Move ordinary decision/motion phase order into `VehicleEnemySimulation`.
  - Change: consume due slots and packed columns, call the existing pure policies, and fill bounded
    receipts. `VehicleRun` invokes the owner and applies side effects; old migrated functions are
    deleted once oracle parity passes.
  - Accept: dense simulation compares per-tick position, velocity, phase, timer, attack-intent,
    contact, spawn, and state receipts at 64/128/192/276/320 actors for repeated seeds.
  - Guard: critical attacks, contact, damage, boss windows, and projectile collision remain on their
    authored physics boundary; no hot loop creates arrays, dictionaries, strings, or callables.

Batch gate:

- Focused spatial/movement/contact/Run validators pass, and the capacity diagnostic shows lower
  `enemies_and_grid` p95 than Phase 3 with exact counts.

### Phase 5: Packed projectile and sparse combat receipts

Goal: reduce the established secondary combat cost after enemy work is stable.

Preconditions:

- Phase 4 batch gate passes.

Source owners: `scripts/combat/vehicle_projectile_store.gd`,
`scripts/combat/vehicle_status_runtime.gd`, `scripts/vehicle/vehicle_run.gd`,
`tools/validation/validate_vehicle_projectile_store.gd`,
`tools/validation/validate_vehicle_status_stacking.gd`,
`tools/validation/validate_vehicle_attack_contract.gd`,
`tools/validation/validate_vehicle_dense_simulation.gd`

- [ ] **5.1** Move player and hostile projectile hot fields into bounded packed columns.
  - Change: keep separate 240/120 stores and boss reserve counters; publish stable handles and
    compatibility snapshots only at non-hot boundaries.
  - Accept: store validator proves add/remove/reuse/reserve/capacity, and Run/dense oracle matches
    every projectile state transition.
- [ ] **5.2** Reuse candidate and hit receipts without weakening exact contact.
  - Change: fill caller-owned segment candidates, group-exit records, and earliest-hit receipts;
    eliminate per-projectile temporary arrays/dictionaries from the hot path.
  - Accept: exact first-contact `t`, wall/structure/actor precedence, pierce, bounce, interceptor,
    hit-once, boss reserve, damage, kill, XP, and effect assertions pass.
- [ ] **5.3** Process only status-bearing actor slots.
  - Change: add/remove sparse membership on first application/final expiry/death; retain current
    stacking and renderer ratios.
  - Accept: status stacking, conditional damage, enemy store, dense simulation, and presentation
    receipts match existing behavior; empty-status actors are not visited by status tick.

Batch gate:

- Combat/status/projectile validators pass and the capacity diagnostic shows lower
  `combat_and_effects` p95 than Phase 4 with unchanged projectile/effect counts.

### Phase 6: Immutable presentation publication

Goal: prevent mutable simulation scans and publication spikes from consuming recovered headroom.

Preconditions:

- Phase 5 batch gate passes.

Source owners: new `scripts/presentation/vehicle_simulation_frame.gd`,
`scripts/presentation/vehicle_combat_renderer.gd`,
`scripts/presentation/vehicle_threat_radar_feed.gd`,
`scripts/vehicle/vehicle_run.gd`, HUD/minimap adapters and their focused validators

- [ ] **6.1** Publish fixed current/previous frames after each simulation step.
  - Change: fill bounded enemy/projectile/effect/cue transforms and scalar presentation state;
    swap once; never expose mutable hot storage.
  - Accept: snapshot validator proves capacity, immutability after swap, generation reuse, current/
    previous alignment, and no retained `EnemyState`/`ProjectileState` references.
- [ ] **6.2** Consume snapshots in renderer, HUD, radar, and minimap.
  - Change: replace their live-state scans with immutable frame reads; interpolate only transforms
    that already run below 60 Hz.
  - Accept: renderer, Run, HUD presenter, stage UI layout, threat radar, minimap/capture, actor visual,
    and projectile readability validators pass. Existing draw/batch limits remain unchanged.
  - Guard: no visual asset, layout, collision, AI, or cadence change is introduced.

Batch gate:

- Presentation/HUD diagnostic p95 does not regress from Phase 5, and exact render-instance,
  draw-call, combat-batch, and snapshot counts pass.

### Phase 7: Integration, quality, and durable cleanup

Goal: prove the complete runtime at source/headless level and remove transitional authority.

Preconditions:

- Phases 0-6 pass.

Source owners: all task-owned runtime/spec/validator files and this plan

- [ ] **7.1** Remove every replaced compatibility hot path.
  - Change: delete old scheduler rebuild authority, duplicate aggregate scans, capacity-wide overlap
    snapshot authority, migrated object projectile loop, and presentation live-state scans. Retain
    debug reconciliation only behind explicit validator/performance activation.
  - Accept: `rg` assertions in the dense-simulation validator find one shipping owner for each
    storage/schedule/spatial/projectile/snapshot responsibility.
- [ ] **7.2** Run the diff-scoped codebase quality audit and apply only small task-owned corrections.
  - Change: check responsibility creep, public contracts, stale comments, reachable invalid/reset/
    capacity/reuse paths, and missing focused validation.
  - Accept: no high-impact finding remains; broad pre-existing debt is reported, not absorbed.
- [ ] **7.3** Run the focused integration batch and import once.
  - Change: run all changed-owner validators, `validate_vehicle_run.gd`, performance scenario/manual
    trace structure, stage continuity, encounter pacing, document authority, `git diff --check`, and
    `./tools/godot.ps1 --path . --headless --import`.
  - Accept: all exit successfully with no new parser/runtime error. A document-authority failure
    caused only by concurrent untracked design files is recorded and replaced by a task-owned path/
    frontmatter/link check until those files are committed by their owner.

Batch gate:

- One clean scoped implementation commit exists and the tracked worktree is clean. Concurrent
  untracked design/UI paths may remain but are excluded from commit and performance dirty metadata.

### Phase 8: Native and Web release qualification

Goal: prove the final same-commit behavior and performance on the supported native and Web paths.

Preconditions:

- Phase 7 batch gate passes.
- User has been told the purpose, expected cost, scenario count, and stop condition.
- No unrelated Godot, browser automation, capture, export, or heavy process is active. Do not kill an
  unrelated process; wait and retry the preflight.

Source owners: `scripts/performance/vehicle_performance_scenario.gd`,
`scripts/performance/vehicle_performance_recorder.gd`, `tools/export_web.ps1`,
`tools/validation/validate_itch_web_release.ps1`, ignored evidence under
`build/performance/dense-engagement/`, and this plan

- [ ] **8.1** Run one final diagnostic scaling sweep.
  - Change: from the final clean commit run 64/128/192/256/320 with 5-second warmup and 10-second
    sample, identical viewport/renderer/focus; record phase visited/due/candidate/receipt counts.
  - Accept: every scenario is valid and shows no lost workload; the density curve does not show a
    new nonlinear failure before 320.
- [ ] **8.2** Run the authoritative clean native pair.
  - Change: run `peak_horde` and `capacity_pressure`, each 10-second warmup + 60-second sample, at
    1280x720 GL Compatibility with VSync disabled and exact commit metadata.
  - Accept: both JSON records report valid scenario/count/viewport/focus/memory/batch state and
    `thresholds.passed=true`. Capacity requires physics p95 <=6 ms and p99 <=8 ms. Both require frame
    p95 <=18 ms, p99 <=25 ms, median >=59 FPS, 1% low >=55 FPS, at most one consecutive frame above
    33.3 ms, draw calls p95 <=200, and combat batches <=50.
  - Guard: a red but valid result is preserved. Reprofile the named final owner and revise this
    contract; do not weaken the gate or workload.
- [ ] **8.3** Export and statically validate the same commit for Web.
  - Change: run `./tools/export_web.ps1`, then
    `./tools/validation/validate_itch_web_release.ps1 -ReleaseDirectory build/web`.
  - Accept: `WEB_EXPORT_OK`; required HTML/JS/PCK/WASM exist; exact-case references, no-thread/
    no-extension contract, file/path/size limits, and gzip allowance pass.
- [ ] **8.4** Run focused built-Web performance and interaction QA.
  - Change: load `npjt-port-guard`, use only its `codex` lane and a hidden task-owned server for
    `build/web`; run focused visible Chrome `peak_horde` for 10+60 seconds, poll
    `window.__cardbornePerformanceResultJson`, inspect console, and exercise normal movement, fire,
    dash, seekers, EMP, stage continuation, result, cues, and varied arrival directions. Stop only
    the positively identified task-owned server/browser helpers.
  - Accept: Web scenario and workload are valid, no focus/throttling/console/input/catch-up failure
    occurs, engagement metrics meet Phase 2 rules, and saved JSON is tied to the same commit. Report
    exact Web numbers separately; native pass is not relabeled as Web performance pass.

Batch gate:

- Native release performance passed, Web release performance passed for the focused supported
  workload, and normal-play interaction passed on the same clean commit.

### Phase 9: Close the contract

Goal: leave durable truth without a stale active plan.

Preconditions:

- Phase 8 passes.

Source owners: `docs/product/vehicle_game_spec.md`, performance evidence/record docs, prior active
dense-combat plan, this plan

- [ ] **9.1** Record final evidence and retire superseded performance state.
  - Change: update the durable performance evidence with exact commit/native/Web labels, engagement
    metrics, architecture outcome, limitations, and evidence paths. Mark the older dense-combat plan's
    unresolved M8/M9 performance condition as superseded by the passing record without rewriting its
    completed product history.
  - Accept: future agents can identify one current product spec, performance policy, architecture
    evidence, and final qualification record without consulting chat history.
- [ ] **9.2** Mark all tasks complete and retire this plan per `.agents/PLANS.md`.
  - Change: record final checkpoint evidence, set `status: done`, commit the closeout, then remove the
    completed plan only after durable decisions/evidence are present in their canonical homes.
  - Accept: no relevant active execution plan points to completed dense-runtime work; document
    authority and `git diff --check` pass.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | the focused validator named by the current task, invoked through `./tools/godot.ps1 --path . --headless --script`, plus `git diff --check` | direct behavior exists | relevant implementation input changes |
| Engagement phase gate | director, allocation, multi-sector, arrival, pacing, targeting, movement, schedule, contact | Phase 1/2 tasks pass | reservation/pattern/gate/cadence input changes |
| Storage/schedule gate | store, schedule, dense simulation, Run, status/carrier owners, `profile_vehicle_pressure.gd` | Phase 3 tasks pass | packed transition or queue input changes |
| Spatial/simulation gate | spatial grid, steering, movement, navigation, attack route, contact, dense simulation | Phase 4 tasks pass | cell/overlap/LOS/movement input changes |
| Combat gate | projectile store, attack contract, status, damage, Run, dense simulation | Phase 5 tasks pass | projectile/status/receipt input changes |
| Presentation gate | simulation frame, renderer, HUD, radar, minimap, capture, readability | Phase 6 tasks pass | snapshot/presentation input changes |
| Integration gate | all changed-owner validators, Run, performance structures, continuity, import, docs, diff | Phase 7 implementation is complete | final source/spec input changes |
| Final diagnostic | one 64/128/192/256/320 sweep | clean final commit and quiescent machine | material simulation/instrumentation input changes |
| Final native | one clean 60-second peak/capacity pair | diagnostic valid and quiescent machine | invalid environment or material runtime change |
| Final Web | export/static check and one focused visible built-Web run | native gate passes on same commit | export/runtime/hosting input changes |

Validation rules:

- Run the narrowest check that proves the current task.
- Run each named phase gate once after its tasks pass.
- Do not repeat passing expensive evidence without a relevant input change.
- Rerun a failed check only after a relevant implementation change or a new causal hypothesis.
- Record known non-blocking warnings once. Never label a diagnostic, export, static check, or smoke
  as a release-performance pass.
- Before any broad or expensive run, tell the user its purpose, number/duration of runs, expected
  machine impact, and stopping condition.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain any required approval before resuming | executor cannot select a new product, architecture, dependency, UX, safety, or validation contract |
| Concurrent design/UI file overlaps a task-owned path | Stop that file's edit, preserve both sides, and coordinate through a non-overlapping owner or wait for the other commit | never stage/revert/clean another session's work |
| Competing Godot/browser/heavy process exists | Continue source/focused headless work only when safe; defer authoritative timing | never kill by name or claim contaminated evidence |
| Engagement gate is invalid in field geometry | Try remaining eligible deterministic candidates, then birth with no gate and normal role movement | never move birth on-screen, teleport, or block a valid window |
| Player sharply reverses after reservation | Keep the fixed gate until completion/expiry, then resume normal focus | never continuously retarget the gate |
| Reservation generation/counter reconciliation fails | stop integration, repair lifecycle owner, rerun only director/store/schedule checks | no compensating full-enemy shipping scan |
| Persistent lanes miss or duplicate due work | compare with retained validator oracle and repair transition membership | do not lower cadence or skip critical work |
| Spatial broad phase misses an exact hit | restore exact candidate completeness and repair index invalidation | broad phase may reduce candidates, never become approximate truth |
| Phase diagnostic fails to improve its named owner | revert only the ineffective phase if behavior-neutral, preserve evidence, and revise the contract | no speculative cache pile-up |
| Final native threshold remains red | preserve JSON, profile the named final owner, revise the plan | GDExtension/threads/workload/threshold change requires explicit approval |
| Native passes but Web remains materially red | preserve separate labels and profile built Web | custom templates, threads, extensions, or hosting headers require explicit approval |

Implementation-local discoveries may be handled inside the locked contract when they cannot change
scope, visible behavior, ownership, architecture, safety, or acceptance.

## Rollback and Safety

- Each phase receives a coherent scoped commit after its gate passes. Do not combine concurrent
  design/UI files or generated build evidence with runtime commits.
- Keep old/new parity only in validators or explicitly activated diagnostics. Delete the replaced
  shipping authority within the same phase that makes the new one canonical.
- Revert an ineffective isolated phase by its scoped commit; never use hard reset or clean.
- Generated performance JSON and Web output remain under ignored `build/` paths. Do not overwrite
  named evidence; include commit and timestamp in filenames.
- Stop only task-owned processes identified by PID and command line.

## Risks

- Packed-slot reuse can corrupt unrelated actors; generation validation and transition reconciliation
  are mandatory before integration.
- A gate can create a new intercept clump; ETA buckets, two-choice load, open sectors, and burst
  assertions guard against moving rather than solving the pile.
- More nearby visible enemies can increase LOS/projectile/presentation work; native/Web gates measure
  this rather than assuming dispersion is faster.
- Persistent queues can silently drop fairness-critical ticks; old-path oracle parity covers every
  membership transition before deletion.
- A broad phase can omit exact collision candidates; brute-force randomized oracles remain final.
- Presentation snapshots can alias mutable arrays; swap/immutability tests reject retained hot-state
  references.
- This is a large cross-module migration; responsibility-shaped files and phase commits prevent
  `VehicleRun` or a new world object from becoming a catch-all.

## Open Questions

None. Product behavior, first calibration, architecture, dependencies, ownership, validation,
fallbacks, and approval boundaries are locked. Measured failure uses the contingency table; it does
not grant the executor discretion to change workload, thresholds, or release architecture.

## Decision Notes

- 2026-08-13: retain all-eight birth sectors and place pattern control in a distinct engagement
  sector. This avoids conflating safe object creation with later combat pressure.
- 2026-08-13: ordinary patterns leave the rear arc open. This first release directly removes the
  repeated tail mechanism; future authored rear pressure requires a separate product decision.
- 2026-08-13: choose role-aware ETA + one-shot gate + deterministic two-choice load as the first
  production mechanism. Perfect rings, pairwise flocking, teleportation, and global optimizers are
  rejected.
- 2026-08-13: use typed GDScript incremental owners first. Native code and threads remain explicit
  escalation paths because the current Web preset excludes both.
- 2026-08-13: preserve existing exact density and combat gates. Better arrival distribution is not
  accepted as a substitute for the dense-simulation performance fix.
- 2026-08-13: this contract supersedes only the unresolved dense-performance M8/M9 portion of
  `2026-08-11-dense-combat-progression-and-run-completion.md`; it does not rewrite that plan's
  completed progression, upgrade, pickup, facility, device, or product history.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 0.
- Next task: 0.2, clean native baseline and scaling sweep.
- Last completed gate: Discovery Closure Gate.
- Update rule: after a checkpoint passes, record concise evidence, check the task, and advance this
  pointer in the same edit. Do not mirror progress into a second plan.
- Anti-rework: on start or resume, read this contract and inspect the worktree only enough to confirm
  the next checkpoint inputs. Treat checked tasks and passing evidence as complete unless their
  relevant input changed. Run each check only at its declared cadence.

Checkpoint evidence:

- 2026-08-13, task 0.1: added recorder-only 4 Hz engagement telemetry with a stable 900-pixel
  observation shell, eight-sector aggregates, meaningful rear-tail detection, bounded event buckets,
  and forward lifecycle/director hooks. `validate_vehicle_engagement_telemetry.gd`,
  `validate_vehicle_arrival_scheduler.gd`, `validate_vehicle_manual_play_trace.gd`, headless import,
  and `git diff --check` passed. Ordinary play keeps the collector absent. Two pre-import validator
  attempts exceeded their wrappers and left exact task-owned Godot children; those children were
  identified by full command line and stopped, and the same manual-trace validator passed after the
  import completed.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check passes.
- Every guard, phase gate, and final gate named here passes.
- No placeholder or unresolved material decision remains.
- Durable behavior is in `docs/product/vehicle_game_spec.md`; final measured results and limitations
  are in a durable evidence/record document; reusable performance procedure stays in the policy.
- Frontmatter status becomes `done` only after implementation and release qualification complete;
  the plan is then retired according to `.agents/PLANS.md`.

Replan when:

- A material discovery invalidates a locked decision or a final valid red result requires an
  unapproved native/thread/dependency/workload/threshold path.

Do not replan or stop for:

- Implementation-local mechanics already contained by this contract.
- A passing check whose relevant inputs have not changed.
- Red baseline evidence that is valid and only establishes the known before state.
