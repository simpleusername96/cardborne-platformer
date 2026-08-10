---
type: plan
status: superseded
owner: BK
created: 2026-08-02
last_reviewed: 2026-08-10
topic: Behavior-preserving combat performance stabilization
scope: Dense-enemy steering, conservative motion clearance, bounded simulation receipts, HUD staging, combat presentation staging, and real-play workload correlation
superseded_by: ../../.agents/execplans/2026-08-10-combat-correction-and-boss-pattern-expansion.md
related:
  - ../../AGENTS.md
  - ../../.agents/AGENTS.md
  - ../../.agents/PLANS.md
  - ../product/vehicle_game_spec.md
  - ../../.agents/semantic-v2-runtime-acceptance-evidence.md
---

# Combat Frame-Pacing Stabilization - Execution Contract

Cardborne's combat-correctness regressions are fixed, but the corrected workload still
misses the unchanged release gate. This is not primarily a rendering-hardware problem.
At dense enemy counts, the runtime repeats the same local-overlap discovery for each
steering owner; the resulting physics backlog forces about eight physics ticks into
each rendered frame. HUD and combat-presentation paths then add allocation-heavy tail
work by rebuilding nested snapshots and hundreds of minimap marker dictionaries.

This plan replaces those repeated object-backed paths with bounded, reusable GDScript
data paths while preserving the connected five-stage run, fixed-Hard behavior, enemy
and projectile capacities, update cadences, collision truth, local-separation rules,
minimap semantics, and all visible UI/art. It is the only active execution plan for
this outcome and requires no user approval between tasks.

## Purpose and Completion State

- Objective: make dense combat responsive without reducing workload or changing player-
  visible behavior.
- Deliverable: one grid-owned packed local-overlap cache, a proven motion-clear early
  return, reusable bounded receipts for recurring simulation state, reusable HUD and
  presentation staging, focused regression coverage, and clean commit-stamped native
  and built-Web performance evidence.
- Completion: every checkbox is complete; focused validators and Web export pass; both
  authoritative native scenarios pass their existing thresholds; built-Web peak-horde
  is valid and passes; the plan is marked `done` under `.agents/PLANS.md`.

## Completed Baseline

Phases 1-4 of the earlier version of this contract are complete. The retained baseline
is:

- `e5c7c59f`: ordinary committed attacks advance at 60 Hz, hostile shots exist, the
  player takes damage, hull HUD state is coherent, ARC warning cross-bars are removed,
  and the same-cell motion certificate is collision-safe.
- `88267378`: lethal denied-zone transitions cannot index a cleared reverse-pass array.
- `b494d84f`: the performance soak keeps real damage and attack work active.
- `0f864804`: the valid unchanged-load native failure is recorded without weakening the
  gate.

No task below reopens those behavior or visual decisions.

## Scope, Non-Scope, and Invariants

In scope:

- `VehicleSpatialGrid` and `VehicleEnemyLocalSteering` local-overlap data flow.
- The already-certified motion fast path and its runtime blocker scan.
- XP, terrain-event, pickup-contact, and transient combat-effect allocation paths.
- Fast-HUD invalidation, minimap marker staging, and synchronous combat-presentation
  snapshot construction.
- Exact focused validators, Web export, native release scenarios, and built-Web peak.

Out of scope:

- UI/HUD layout, typography, art, assets, map visuals, upgrade cards, localization, or
  input behavior.
- Enemy/projectile/item/effect capacities, encounter density, threat budgets, attack
  rules, damage, speed, range, collision radii, or fixed-Hard difficulty.
- Any lower simulation/presentation cadence or weaker release threshold.
- Projectile first-hit traversal or cover collision redesign in this pass.
- Threads, `WorkerThreadPool`, GDExtension, engine changes, or new dependencies.

Locked invariants:

- Player intent, player damage, committed attacks, boss visible windows, and combat
  presentation remain physics-synchronized at 60 Hz.
- Ordinary decisions remain 10 Hz; non-committed motion remains 30 Hz near and 20 Hz
  far; far projectiles, XP, and effects retain their current accumulated 30 Hz update.
- Live caps remain 320 enemies, 240 player projectiles, 120 hostile projectiles, 192 XP
  shards, and 96 effects. No hidden lower cap is permitted.
- Local separation applies only to actual body overlap, considers at most the nearest
  eight bodies within 120 units ordered by `(distance_squared, stable_enemy_id)`, blends
  `0.55` role velocity with `0.45` separation velocity, never exceeds role speed, and
  returns bit-for-bit role velocity when there is no overlap.
- Projectile collision remains earliest swept hit with exact cover, bulkhead, crate,
  and generation truth.
- Fast HUD remains 10 Hz and world markers remain 5 Hz. Hull/progression and action
  sibling fields are always delivered as atomic clusters.
- The minimap continues to expose only the existing player, item, enemy, and boss roles;
  marker order and visible meaning do not change.
- Reusable containers are borrowed only for synchronous consumption. Anything retained
  by a UI consumer uses two alternating buffers so the previously published frame is
  never mutated in place.

Destructive actions: none. All changes are version-controlled. No dependency, native
rewrite, workload reduction, cadence change, or threshold change is authorized.

## Current Evidence and Root Cause

The authoritative 60-second native result is
`build/performance/combat-correctness/final-b494d84f-peak_horde-60s.json`. It is a clean,
focused `1280x720` GL Compatibility run with 276 enemies, 140 player projectiles, and 72
hostile projectiles. It reports:

| Metric | Result |
| --- | ---: |
| frame p95 / p99 | `143.044 / 146.570 ms` |
| median / 1% low | `7.500 / 6.747 FPS` |
| physics p95 / p99 | `30.584 / 38.557 ms` |
| scheduled ordinary p95 / p99 | `20.150 / 25.022 ms` |
| enemies-and-grid p95 | `23.521 ms` |
| HUD p95 | `15.507 ms` |
| presentation p95 | `8.200 ms` |
| render CPU / GPU p95 | `0.711 / 1.770 ms` |

The run completed 3,600 physics ticks but only 450 rendered frames. The exact
`133.333 ms` median frame is eight 60 Hz ticks, so most apparent unattributed frame time
is backlog/catch-up caused by simulation and staging work, not GPU rendering.

Fresh current-HEAD diagnostics use the same peak workload, `1280x720`, 10-second warmup,
and 15-second sample. They are diagnostic only, but every run passed scenario-count and
focus validation:

| Diagnostic | frame median / p95 | physics median / p95 | scheduled ordinary mean / p95 |
| --- | ---: | ---: | ---: |
| unchanged current source | `133.333 / 145.049 ms` | `20.539 / 28.821 ms` | `13.244 / 18.214 ms` |
| steering disabled only | `104.289 / 134.078 ms` | `13.949 / 20.244 ms` | `6.741 / 10.045 ms` |
| static motion checks disabled only | `133.333 / 145.049 ms` | `19.803 / 27.587 ms` | `12.319 / 17.184 ms` |
| both disabled | `19.713 / 45.833 ms` | `11.390 / 17.407 ms` | `4.998 / 7.466 ms` |

The steering ablation removes about `6.50 ms` ordinary mean and `8.17 ms` ordinary p95,
directly proving the primary owner. The static-motion ablation saves only about `1 ms`,
so it is useful but cannot be the main fix. The combined result also proves these two
changes alone are insufficient: HUD/presentation and the bounded secondary simulation
paths must be removed from the tail as well.

The current 15-second capacity result contains 320 enemies, 240 player projectiles, 120
hostile projectiles, and 275 enemies within 600 units. Physics p95 is `22.891 ms`:
scheduled ordinary is `13.551 ms`, combat/effects is `3.892 ms`, player/rewards is
`3.634 ms`, and encounter/pursuit is `1.020 ms`. These subsystem timings close ownership
without changing the workload.

Source tracing closes the mechanism:

1. `_update_enemies()` dispatches each due actor through `_desired_enemy_velocity()`.
   Each refreshing owner calls `query_nearest_overlaps_into()`, walks object-backed local
   cell buckets, repeats distance/radius tests for the opposite direction of the same
   pair, materializes `EnemyState` candidates, and loops those objects again in local
   steering. At 271-275 nearby enemies this repeated pair discovery dominates.
2. `_runtime_motion_cover_rects()` already has a combined catalog/layout safe proof but
   still builds a swept rectangle and scans immutable walls and initially known
   bulkheads. This is a measured secondary cost.
3. `VehicleExperienceRuntime.advance()` allocates a result dictionary and source array
   at 30 Hz; terrain creates an event array at 60 Hz; pickups perform the same swept
   contact twice; effects allocate ten-field dictionaries and iterate them at a cap of
   96. These are the bounded owners inside the measured secondary physics groups.
4. `_combat_presentation_snapshot()` creates a nested dictionary every physics frame,
   duplicates protection/mines, and rebuilds support/secondary snapshots. The minimap
   creates as many as 320 marker dictionaries every 5 Hz. These allocations occur on
   the measured `6-15 ms` HUD/presentation tail despite render CPU/GPU being small.

## Alternatives Considered

| Alternative | Benefit | Why it is not selected |
| --- | --- | --- |
| Reduce counts, density, cadence, collision checks, or thresholds | Fastest apparent pass | Violates product and user requirements and hides rather than fixes the workload |
| Extend only the static motion certificate | Low-risk, small patch | Measured at only about `1 ms`; insufficient by itself |
| Micro-optimize the existing per-owner nearest query | Smaller code change | Still walks the same buckets and evaluates the same pair twice for many owners |
| Threaded GDScript or native/GDExtension solver | Potential large speedup | Requires copied state/synchronization or a new native dependency and threatens deterministic Web behavior |
| Data-oriented GDScript hot paths | Removes repeated work and allocation while retaining semantics | **Selected**; bounded capacities make fixed packed buffers practical and verifiable |

## Selected Design

### A. Grid-owned marked-owner directed-overlap cache

`VehicleSpatialGrid` owns a fixed-capacity cache. Add `LOCAL_OVERLAP_LIMIT := 8` and
pre-size generation, validity, count, neighbor-slot, distance, actor-ID, body-radius,
and immutable snapshot buffers for `MAX_TRACKED_ACTORS` and
`MAX_TRACKED_ACTORS * LOCAL_OVERLAP_LIMIT`. Do not allocate or grow them during play.

Add:

```gdscript
func rebuild_local_overlap_cache(refresh_slots: PackedByteArray) -> void
func cached_local_overlap_count(owner: EnemyState) -> int
func cached_local_overlap_slot(owner: EnemyState, index: int) -> int
func cached_local_position(slot: int) -> Vector2
func cached_local_body_radius(slot: int) -> float
func cached_local_actor_id(slot: int) -> String
```

The rebuild runs once immediately before ordinary dispatch. It first captures one
immutable 320-slot position/radius/ID/generation snapshot. It then iterates only marked,
valid owner slots; each owner scans its own and adjacent 3x3 local-cell buckets and
offers directed candidates to that owner row. Candidate validation applies the exact
current predicates `distance_squared <= 120^2` and
`distance_squared < (radius_a + radius_b)^2`. Each fixed row retains the best eight
ordered by `(distance_squared, actor_id)`. No occupied-cell list, forward-pair walk,
bidirectional pair helper, or per-candidate production instrumentation is retained.

`VehicleRun` owns one pre-sized refresh mask. It marks exactly the critical or ordinary-
due actors for which the existing decision/parity predicate would pass. Normal play
performs one cache build per enemy-update pass. A controlled direct validator/capture
entry may build a one-owner mask; the normal performance scenario must record zero
legacy per-owner nearest-query calls.

`VehicleEnemyLocalSteering` retains its current adjusted-velocity cache. A refresh reads
the grid row and performs the existing penetration, deterministic zero-distance
direction, strongest-neighbor fallback, blend, and speed cap. A non-refresh continues
to reuse the prior adjusted direction at the current role speed. The old object query
remains only as a temporary brute-force test oracle and is removed from production once
equivalence tests pass.

### B. Proven motion early return

Do not broaden collision clearance. In `_runtime_motion_cover_rects()`, when both the
existing catalog and tactical-layout certificates are true, return the cleared shared
buffer before constructing a swept rectangle or scanning structural walls/bulkheads.
The certificates already exclude every initial structural wall and bulkhead footprint;
runtime can remove a bulkhead but cannot add an unrepresented blocker. All uncertified,
cross-cell, large-radius, selected-cover, and crate cases keep the exact existing path.

### C. Reusable bounded simulation receipts

- `VehicleExperienceRuntime` owns one result dictionary and one typed collected-source
  array, clears/resets them at the start of `advance()`, and returns borrowed scratch.
  Callers consume it immediately. Shard order, attraction, recall, collection, XP award,
  and swap-removal remain unchanged.
- `VehicleTerrainRuntime` owns and clears its small event buffer rather than allocating
  an empty array every tick. Event order remains heal before transit.
- `_update_pickups()` performs one swept-contact call. Add endpoint/dash equivalence
  coverage before deleting the redundant zero-length call.
- Add a responsibility-shaped `VehicleEffectStore` with 96 preallocated presentation
  states, swap retirement, and deterministic first-entry swap eviction when saturated.
  The store owns only bounded visual state and reuse. `VehicleRun` owns the EMP
  aftershock's scalar 0.72-second schedule, advances it on the accumulated 30 Hz effect
  boundary, and cancels it through the same reset helper that clears presentation state.
  The renderer and capture/performance fixtures consume the typed live list. Do not
  merge gameplay scheduling, projectile, or denied-zone behavior into this store.

### D. Reusable HUD and presentation staging

- Preserve the public snapshot helpers for validators/capture, but add fill-into or
  borrowed-buffer runtime paths.
- Replace whole-fast-snapshot publication with explicit atomic clusters only when that
  cluster changes: hull/progression (`health`, `max_health`, `level`, `experience`,
  `experience_required`, `reduced_motion`), objective, action slots, target, and boss.
  The hull/progression and all action siblings can never be split.
- Use two alternating preallocated minimap snapshots. Each owns reused visited storage
  and a pool of marker dictionaries sized for the locked live caps. Preserve insertion
  order and the existing marker schema. Alternation prevents the retained minimap from
  observing mutation of the currently displayed buffer.
- Reuse the small threat-radar wrapper while preserving its retained contact cache.
- `VehicleRun` owns one synchronous combat-presentation dictionary. Pass protection
  sources and mine state by borrowed reference, and add fill-into support-field state;
  expose only `orbit_angle`, `mines`, and `drone_position` from secondary presentation
  state because those are the renderer's actual consumers. Do not deep-duplicate them.
- `VehicleCombatRenderer.sync()` remains 60 Hz and consumes the borrowed frame
  synchronously. Do not change layout, assets, draw geometry, batch identities, or
  animation semantics. Dirty-upload work is not authorized unless the reusable-frame
  implementation still identifies buffer upload as a measured owner.

## Tasks

### Phase 5 - Remove repeated dense-enemy work

- [x] **5.1 Implement the packed marked-owner local-overlap cache**
  - Owners: `scripts/combat/vehicle_spatial_grid.gd`,
    `scripts/enemies/vehicle_enemy_local_steering.gd`,
    `scripts/vehicle/vehicle_run.gd`, capture gateway only if its direct path requires
    cache preparation, and their focused validators.
  - Accept: randomized 320-slot fixtures match a brute-force oracle in count, ordered
    IDs, distances, and adjusted velocity; a dense 24-actor partial mask publishes exact
    rows for only two selected owners; cover same/cross cell, zero distance, exact
    tangent, inactive/dead, boss/pylon exclusion, generation reuse, and more than eight
    equal-distance candidates. Refresh-mask membership matches the prior twelve-bucket,
    critical, and parity behavior. Saturated play performs no production per-owner
    nearest query and no cache growth.
  - Evidence: `validate_vehicle_spatial_grid.gd`,
    `validate_vehicle_enemy_local_steering.gd`, and
    `validate_vehicle_enemy_update_schedule.gd` pass with randomized 320-slot and dense
    two-owner partial-mask oracles, fixed-capacity, generation, edge, refresh-mask, and
    zero-legacy-query assertions.
- [x] **5.2 Add the existing-certificate early return**
  - Owners: `scripts/vehicle/vehicle_run.gd` and navigation-clearance validators.
  - Accept: certified same-cell motion is identical; every uncertified/static edge,
    selected cover, structural wall, live/opened bulkhead, radius-over-36, cross-cell,
    out-of-bounds, and crate fixture remains exact. Do not extend which cells qualify.
  - Evidence: `validate_vehicle_navigation_clearance.gd` and
    `validate_vehicle_run.gd` pass with combined-certificate, exact fallback, selected
    cover, wall, live/opened bulkhead, radius, cross-cell, bounds, and crate fixtures.

### Phase 6 - Remove recurring secondary-physics allocations

- [x] **6.1 Reuse XP and terrain receipts and remove duplicate pickup contact**
  - Owners: `scripts/progression/vehicle_experience_runtime.gd`,
    `scripts/vehicle/vehicle_terrain_runtime.gd`, `scripts/vehicle/vehicle_run.gd`, and
    focused XP/terrain/pickup validators.
  - Accept: repeated empty and non-empty calls return the same borrowed receipt identity;
    XP totals/sources/levels, heal/transit event order, pickup collection order, dash
    crossing, endpoint contact, and pool capacities match the old oracle.
  - Evidence: `validate_vehicle_experience.gd`,
    `validate_vehicle_terrain_runtime.gd`, `validate_vehicle_pickup_contact.gd`, and
    `validate_vehicle_run.gd` pass with borrowed-identity, XP, ordered-event,
    randomized endpoint-equivalence, dash, and capacity assertions.
- [x] **6.2 Pool transient effect state behind one store**
  - Owners: new responsibility-shaped files under `scripts/combat/`, the narrow effect
    boundary in `vehicle_run.gd`, `vehicle_combat_renderer.gd`, performance/capture
    fixtures, and focused validators.
  - Accept: cap 96, ordinary first-entry swap eviction, time/duration,
    target/direction/value/multiplier fields, rendered effect count, reset, and pool
    accounting are exact, and the store contains presentation state only. `VehicleRun`
    owns exact 0.72-second EMP aftershock timing, boundary release, and reset
    cancellation. No effect-state instance is allocated after store initialization
    during a saturated effect soak.
  - Evidence: `validate_vehicle_effect_store.gd`,
    `validate_vehicle_combat_renderer.gd`, `validate_vehicle_run.gd`, and
    `validate_vehicle_performance_scenarios.gd` pass with ordinary first-entry swap
    eviction, typed rendering, Run-owned aftershock timing/reset, exact 96-state
    creation, `validate_capacity()`, saturated live count, and sane live/pool accounting
    assertions.

### Phase 7 - Remove HUD and presentation allocation tails

- [x] **7.1 Publish atomic HUD clusters and reuse world-channel frames**
  - Owners: `scripts/ui/vehicle_hud_presenter.gd`, `scripts/vehicle/vehicle_run.gd`, and
    HUD/minimap validators. `VehicleGameplayHud` may change only if required to consume
    the same snapshot schema without visual/layout changes.
  - Accept: initial publication is complete; unchanged clusters are absent; damage,
    heal, max-hull, XP, and level changes always include the entire hull/progression
    cluster and never render `1/1` unless simulation is `1/1`; all action siblings stay
    atomic; world cadence is 5 Hz; two marker buffers alternate and neither mutates while
    retained; marker roles/order/count match the current oracle at 320 enemies.
  - Evidence: `validate_vehicle_hud_presenter.gd` and `validate_vehicle_run.gd` pass
    with every field asserted in all five initial clusters (hull/progression, objective,
    action slots, target, and boss), atomic cluster omission/change coverage, no fallback
    `1/1`, five-hertz world cadence, exact 320-hostile minimap oracle order, fixed
    capacity, alternating identity, retained-frame immutability, and threat-wrapper
    borrowing assertions.
- [x] **7.2 Reuse the synchronous combat-presentation frame**
  - Owners: `scripts/vehicle/vehicle_run.gd`,
    `scripts/player/vehicle_secondary_runtime.gd`,
    `scripts/vehicle/vehicle_terrain_runtime.gd`,
    `scripts/presentation/vehicle_combat_renderer.gd`, and renderer/run validators.
  - Accept: repeated syncs reuse the top-level frame and nested bounded buffers;
    renderer-visible fields equal the old snapshot oracle; all actor/projectile/shard/
    effect counts, support fields, mines, orbit blades, drone, protection, cursor, and
    damage overlays remain identical; render batches stay at or below 50.
  - Evidence: `validate_vehicle_secondary_weapons.gd`,
    `validate_vehicle_terrain_runtime.gd`, `validate_vehicle_combat_renderer.gd`,
    `validate_vehicle_run.gd`, and `validate_vehicle_damage_feedback.gd` pass with
    cold-oracle equality, borrowed protection/mine/live-list identity, 128-call
    top-level/nested-buffer identity, 128-sync actor/projectile/shard/effect/support/
    overlay count stability, current-value refresh, and the retained batch ceiling.

### Phase 8 - Consolidated qualification

- [x] **8.1 Run focused correctness checks and one production Web export**
  - Run the Test Plan only after Phases 5-7 are implemented. Fix task-owned failures and
    rerun only affected checks. Then run the complete named batch once.
  - Evidence: before the ownership post-pass, the complete 14-validator named batch,
    Godot headless import, `tools/export_web.ps1` (`WEB_EXPORT_OK`, four files), and
    `git diff --check` passed. After moving EMP scheduling out of presentation state,
    the four affected focused validators passed. After the marked-owner cache correction,
    spatial-grid, local-steering, enemy-update-schedule, Run, and performance-scenario
    validators plus `git diff --check` pass. Import and Web export were intentionally not
    repeated under the two post-passes' focused-check scope.
- [ ] **8.2 Commit the implementation and run native release scenarios**
  - Before another release scenario, collect one user-controlled native play trace through
    `tools/run_manual_performance_trace.ps1`. The debug-only trace must preserve normal
    persistence, layout randomness, gameplay counts, AI, collision, cadence, and UI. It
    records only active-simulation frames, retains bounded approximately one-second
    buckets and the 64 slowest frames, and correlates those frames with the already-
    computed encounter pressure snapshot. `ordinary_active` means map-wide simulated cap-counting enemies;
    `ordinary_center_in_viewport` means those whose body center is inside the visible
    world rectangle; `ordinary_offscreen_active` is their difference.
  - The manual trace is diagnostic-only and can neither pass nor fail the release gate.
    Analyze whether the reported hitch is continuous or intermittent and whether it
    correlates with physics catch-up, presentation/HUD time, render time, active/visible/
    offscreen enemies, projectiles, effects, or focus loss. Do not change encounter caps,
    workload, cadence, visuals, or thresholds until that real-play evidence selects an
    owner or exposes a product decision.
  - Measure from the exact clean implementation commit with normal stride-7
    instrumentation. Quote the window position as `'40,40'`; unquoted PowerShell input
    becomes invalid `40 40`.
  - Accept both `peak_horde` and `capacity_pressure`: exact workload/count/cadence,
    focused window, supported viewport, matching clean commit metadata,
    `thresholds.passed=true`; frame p95/p99 at most `18/25 ms`, median at least `59 FPS`,
    1% low at least `55 FPS`, at most one consecutive frame over `33.3 ms`; capacity
    physics p95/p99 at most `6/8 ms`; draw p95 at most 200 and batches at most 50.
  - Current evidence: implementation commit `315f275a` and the marked-owner correction
    commit `76989997` are clean and all focused checks pass. Four 60-second peak attempts
    were rejected before qualification because unrelated Godot tests/captures overlapped
    the sample. Their unchanged JSON files are retained under
    `build/performance/frame-pacing/invalid-315f275a-*.json`; none is release evidence.
    The recurring owner is a separate long-running `codex.exe resume` process (observed
    PID 6124) launching Cardborne and paint-mountain children. Do not stop or suspend it
    from this plan; resume only after a continuous quiet window.
  - Manual-trace implementation evidence: the bounded recorder, normal-path integration,
    scan-free pressure fill, unique-output wrapper, focused manual/Run/encounter/synthetic
    validators, headless import, and production Web export pass. The wrapper refuses to
    start while another Godot process could contaminate the trace.
  - BK's normal-exit 144.223-second trace at
    `build/performance/manual/manual-4dec4734-20260805-191909.json` selected synchronous
    spawn allocation as the first-use hitch owner. Render CPU, GPU, presentation, and HUD
    stayed low while the 8-second Stage 1 surge produced an approximately 75 ms
    `encounter_and_pursuit` spike with only one ordinary enemy active. A focused allocator
    diagnostic then reproduced 52-74 ms arrival-window work without rendering.
  - Commit `483cab1f` compiles immutable exact-radius candidate geometry during stage
    setup and removes request-invariant scoring and admission checks from inner candidate
    loops. The same Stage 1 fingerprints remain exact while the latest diagnostic reports
    window median/p95 values of `9.616/10.590`, `4.279/5.062`, and `4.354/6.074` ms.
    Prewarm cost was 41.474 ms outside active play. Spawn-allocation, multi-sector,
    arrival-scheduler, encounter-pacing, and Run validators plus import and Web export
    pass. These diagnostic timings are owner evidence, not release qualification.
- [ ] **8.3 Run built-Web peak and close the plan**
  - Only after both native results pass, load `$npjt-port-guard`, serve the already-built
    export on the `codex` lane, use the visible Chrome DevTools path, save the returned
    JSON unchanged, and require a valid focused authority-eligible result with passing
    thresholds. Stop only the positively identified task-owned server.
  - Mark this plan `done`, move it to `.agents/execplans/completed/`, and update durable
    owning documentation only if an actual public contract changed.

## Test Plan

Task-local checks may run while implementing. Do not run the broad historical matrix or
performance scenarios until all implementation tasks are complete.

```powershell
$validators = @(
  'validate_vehicle_spatial_grid.gd',
  'validate_vehicle_enemy_local_steering.gd',
  'validate_vehicle_enemy_update_schedule.gd',
  'validate_vehicle_navigation_clearance.gd',
  'validate_vehicle_experience.gd',
  'validate_vehicle_terrain_runtime.gd',
  'validate_vehicle_pickup_contact.gd',
  'validate_vehicle_projectile_store.gd',
  'validate_vehicle_effect_store.gd',
  'validate_vehicle_hud_presenter.gd',
  'validate_vehicle_combat_renderer.gd',
  'validate_vehicle_stage_ui_layout.gd',
  'validate_vehicle_manual_play_trace.gd',
  'validate_vehicle_run.gd',
  'validate_vehicle_performance_scenarios.gd'
)
foreach ($validator in $validators) {
  .\tools\godot.ps1 --path . --headless --script "res://tools/validation/$validator"
  if ($LASTEXITCODE -ne 0) { throw "validator failed: $validator" }
}
.\tools\godot.ps1 --path . --headless --import
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed' }
.\tools\export_web.ps1
if ($LASTEXITCODE -ne 0) { throw 'Web export failed' }
git diff --check
if ($LASTEXITCODE -ne 0) { throw 'git diff check failed' }
```

Commit only task-owned implementation before measuring. Run each native scenario once;
rerun only an invalid environment result or after a relevant source fix:

```powershell
$trackedDirty = @(git status --porcelain --untracked-files=no)
if ($trackedDirty.Count -ne 0) { throw 'performance requires a clean tracked commit' }
$perfCommit = (git rev-parse HEAD).Trim()
$short = $perfCommit.Substring(0, 8)
New-Item -ItemType Directory -Force -Path 'build\performance\frame-pacing' | Out-Null
$env:PERFORMANCE_COMMIT = $perfCommit
$env:PERFORMANCE_DIRTY = '0'
try {
  foreach ($scenario in @('peak_horde', 'capacity_pressure')) {
    $output = "res://build/performance/frame-pacing/final-$short-$scenario-60s.json"
    .\tools\godot.ps1 --path . --rendering-method gl_compatibility `
      --resolution 1280x720 --position '40,40' --disable-vsync -- `
      "--performance-scenario=$scenario" "--performance-output=$output" `
      '--performance-warmup=10' '--performance-duration=60'
    if ($LASTEXITCODE -ne 0) { throw "performance scenario invalid: $scenario" }
  }
} finally {
  Remove-Item Env:PERFORMANCE_COMMIT -ErrorAction SilentlyContinue
  Remove-Item Env:PERFORMANCE_DIRTY -ErrorAction SilentlyContinue
}
```

For Web, resolve the port with
`C:\Users\BK\.codex\skills\npjt-port-guard\scripts\npjt_port_guard.py`, use the `codex`
lane, serve `build/web` with a hidden task-owned process, and open:

```text
http://127.0.0.1:<codexPort>/?performance_scenario=peak_horde&performance_warmup=10&performance_duration=60
```

Poll `window.__cardbornePerformanceResultJson`; save the exact JSON to
`build/performance/frame-pacing/final-<short>-web-peak-horde-60s.json`. Before cleanup,
verify the process command line contains the resolved port, `http.server`, and this
repository's `build/web`, then stop only that PID.

## Validation and Rework Controls

| Cadence | Check | Run when | Rerun condition |
| --- | --- | --- | --- |
| Task-local | Changed owner's focused validator | A task compiles | Only after that owner changes |
| Consolidated | Named validator batch, import, Web export, diff check | Phases 5-7 complete | Covered source changes |
| Native release | Peak then capacity, 60 seconds each | Clean implementation commit | Invalid environment or runtime source change |
| Built Web | Peak, 60 seconds | Both native scenarios pass | Web/runtime source changes |

No result is acceptable if attacks freeze, projectiles disappear, damage stops, counts
or cadences fall, focus/commit metadata is invalid, or the profiler itself uses a
nonstandard detail stride.

## Predetermined Contingencies

| Trigger | Required response |
| --- | --- |
| Directed cache differs from brute-force semantics | Reject the cache result; fix owner/candidate enumeration, generation stamping, or top-eight ordering. Never relax the oracle. |
| Safe-motion early return disagrees with exact collision | Remove that early return and retain the exact solver. Do not broaden certification. |
| Reused receipt is retained by a consumer | Convert that boundary to two alternating owned buffers; do not allocate per tick or mutate a published live frame. |
| Pooled state changes order/timing/cap | Revert the store task and fix against the old-path oracle before continuing. |
| A native run is invalid or unfocused | Discard it, correct only the environment, and rerun that scenario. |
| A valid final result still fails | Keep this plan active and save the exact evidence. Do not lower workload or thresholds. Use the existing subsystem fields to identify which selected owner missed its acceptance; make only a semantics-preserving correction inside Phases 5-7, rerun its focused checks, recommit, and requalify. A dependency/native/workload change requires a new explicit user decision. |
| A material fact contradicts this contract | Stop only the affected branch and update this same plan; do not create a competing active plan. |

## Rollback and Safety

- Commit the plan separately, then use coherent implementation commits by responsibility.
- Never reset, clean, stage, or rewrite unrelated user work.
- Keep the old brute-force overlap logic only as a test oracle until the packed cache
  passes; then remove it from production dispatch.
- Revert an optimization with its assertions if it changes simulation or visible state.
- Performance evidence under `build/` is derived output; source and validators remain the
  durable truth.

## Risks

- A batch snapshot removes update-order-dependent neighbor observation within one physics
  pass. The authoritative behavior is the documented boundary snapshot and deterministic
  nearest-eight contract; randomized oracle tests lock that contract explicitly.
- Reusing dictionaries is unsafe across retained UI frames. The plan therefore requires
  alternating minimap buffers and synchronous-only borrowing elsewhere.
- Effect pooling crosses simulation and renderer ownership. The dedicated store owns
  presentation records only; `VehicleRun` owns the scalar aftershock schedule and its
  gameplay release, so neither the store nor renderer becomes a catch-all.
- The current gate is demanding for GDScript. This plan does not promise a pass by hiding
  load; it exhausts the proven behavior-preserving owners before any broader architecture
  can be considered.

## Decision Notes

- 2026-08-05: Preserved this single active plan instead of creating a second performance
  plan. Completed correctness/visual history was compacted into the baseline above.
- 2026-08-05: Fresh same-workload ablations proved local steering is the primary physics
  owner and static motion scanning is only secondary.
- 2026-08-05: Selected a grid-owned batched directed cache over per-owner tuning,
  threading, native code, workload reduction, or threshold changes.
- 2026-08-05: Added bounded simulation and presentation staging because the combined
  steering/motion ablation still misses frame and physics gates.
- 2026-08-05: Kept projectile first-hit traversal and renderer batch geometry unchanged;
  neither has evidence sufficient to justify a higher-risk rewrite in this pass.
- 2026-08-05: Moved EMP aftershock scheduling from the pooled presentation store to a
  Run-owned scalar timer. Focused validation now locks the strict presentation boundary,
  all five initial HUD clusters, and exact 96-state saturated performance accounting.
- 2026-08-05: Source tracing showed the refresh schedule selects roughly `N/12` owner
  rows, while the first packed builder enumerated all nearby pairs before mask rejection.
  Corrected the builder to scan 3x3 buckets only for marked owners, preserving the same
  immutable snapshot, directed rows, exact predicates, and deterministic top-eight order.
- 2026-08-05: Committed the marked-owner correction as `76989997`. Phase 8.2 remains
  unchecked because four native peak attempts overlapped Godot work owned by another
  Codex session. Internally plausible JSON is still invalid when external process
  monitoring proves contention; capacity and Web qualification were not started.
- 2026-08-05: A source audit established that `249-276` came from the synthetic
  `production_replay` route rather than a recorded manual session. Added a bounded,
  debug-only manual-play correlation checkpoint before any encounter-density or further
  release-qualification decision; it is evidence for diagnosis, never a release pass.
- 2026-08-05: BK's manual trace disproved asset rendering and current on-screen enemy
  density as the main early-run hitch. The trace and a focused headless diagnostic both
  selected synchronous spawn allocation, where immutable geometry was recomputed inside
  an arrival frame.
- 2026-08-05: Committed the exact-output spawn-geometry prewarm and inner-loop cleanup as
  `483cab1f`. No enemy count, packet cadence, position, collision radius, asset, visual,
  or release threshold changed.
- 2026-08-07: The separately authorized upgrade reduction removed Ion Wake and its
  damaging-trail runtime. The synthetic performance fixture now measures 8/16 authored
  damage zones instead of combined zones and trails. This changes workload composition,
  so earlier performance JSON is historical evidence only and cannot qualify the new
  catalog. Keep every threshold unchanged, but record a new clean native baseline before
  resuming release qualification.
- 2026-08-08: The separately authorized combat-readability pass removed obsolete crate
  health-overlay staging, reduced the shared world-health batch ceiling from 50 to 28,
  doubled hostile projectile presentation thickness through its existing transform, and
  changed Beam Sentinel presentation to two startup planes and three active planes. The
  quiescence preflight found 16 pre-existing Godot processes, so no contaminated native
  performance run was started. These changes do not alter scenario counts or thresholds,
  but the clean baseline must use the resulting committed workload.

## Progress

- [x] Reproduce the corrected workload and preserve an authoritative failure.
- [x] Run current-source causal ablations for steering and static motion.
- [x] Trace secondary physics, HUD, and presentation owners.
- [x] Compare alternatives and lock the selected architecture.
- [x] Complete Phase 5.
- [x] Complete Phase 6.
- [x] Complete Phase 7.
- [ ] Complete Phase 8 and retire this plan.

Current task: **After the combat-readability work is committed and the environment is
quiet, record a new clean native baseline for the current damage-zone-only workload. Then
use that exact committed workload for the two native release scenarios; do not compare it
directly with the retired zones-and-trails evidence and do not change the existing
thresholds.**

## Open Questions

- The main early-run first-use hitch was synchronous spawn allocation. The pre-fix trace
  also retained two isolated `combat_and_effects` spikes near 72 and 104 seconds; do not
  change that owner unless later post-fix real-play evidence shows those spikes remain
  perceptible and reproducible.
