---
type: plan
status: active
owner: BK
created: 2026-08-02
last_reviewed: 2026-08-05
topic: Behavior-preserving combat performance stabilization
scope: Dense-enemy steering, conservative motion clearance, bounded simulation receipts, HUD staging, and combat presentation staging
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../semantic-v2-runtime-acceptance-evidence.md
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

### A. Grid-owned batched directed-overlap cache

`VehicleSpatialGrid` owns a fixed-capacity cache. Add `LOCAL_OVERLAP_LIMIT := 8` and
pre-size generation, validity, count, neighbor-slot, distance, actor-ID, body-radius,
refresh-mask, and occupied-local-cell buffers for `MAX_TRACKED_ACTORS` and
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

The rebuild runs once immediately before ordinary dispatch. It walks each occupied local
cell's internal pairs and forward neighbor offsets `(1,-1)`, `(1,0)`, `(1,1)`, `(0,1)`;
therefore every unordered nearby pair is examined once. It validates active/alive state
and generation once, applies the exact current predicates
`distance_squared <= 120^2` and
`distance_squared < (radius_a + radius_b)^2`, then offers the pair to each direction
whose owner mask requests refresh. Each fixed row retains the best eight ordered by
`(distance_squared, actor_id)`.

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
- Add a responsibility-shaped `VehicleEffectStore` with 96 preallocated effect states,
  swap retirement, and the current eviction order. `VehicleRun` keeps the scheduled-
  aftershock side effect; the store owns only bounded state and reuse. The renderer and
  capture/performance fixtures consume the typed live list. Do not merge projectile or
  denied-zone behavior into this store.

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

- [ ] **5.1 Implement the packed batched local-overlap cache**
  - Owners: `scripts/combat/vehicle_spatial_grid.gd`,
    `scripts/enemies/vehicle_enemy_local_steering.gd`,
    `scripts/vehicle/vehicle_run.gd`, capture gateway only if its direct path requires
    cache preparation, and their focused validators.
  - Accept: randomized 320-slot fixtures match a brute-force oracle in count, ordered
    IDs, distances, and adjusted velocity; cover same/cross cell, zero distance, exact
    tangent, inactive/dead, boss/pylon exclusion, generation reuse, and more than eight
    equal-distance candidates. Refresh-mask membership matches the prior twelve-bucket,
    critical, and parity behavior. Saturated play performs no production per-owner
    nearest query and no cache growth.
- [ ] **5.2 Add the existing-certificate early return**
  - Owners: `scripts/vehicle/vehicle_run.gd` and navigation-clearance validators.
  - Accept: certified same-cell motion is identical; every uncertified/static edge,
    selected cover, structural wall, live/opened bulkhead, radius-over-36, cross-cell,
    out-of-bounds, and crate fixture remains exact. Do not extend which cells qualify.

### Phase 6 - Remove recurring secondary-physics allocations

- [ ] **6.1 Reuse XP and terrain receipts and remove duplicate pickup contact**
  - Owners: `scripts/progression/vehicle_experience_runtime.gd`,
    `scripts/vehicle/vehicle_terrain_runtime.gd`, `scripts/vehicle/vehicle_run.gd`, and
    focused XP/terrain/pickup validators.
  - Accept: repeated empty and non-empty calls return the same borrowed receipt identity;
    XP totals/sources/levels, heal/transit event order, pickup collection order, dash
    crossing, endpoint contact, and pool capacities match the old oracle.
- [ ] **6.2 Pool transient effect state behind one store**
  - Owners: new responsibility-shaped files under `scripts/combat/`, the narrow effect
    boundary in `vehicle_run.gd`, `vehicle_combat_renderer.gd`, performance/capture
    fixtures, and focused validators.
  - Accept: cap 96, non-aftershock eviction preference, swap order, time/duration,
    target/direction/value/multiplier fields, aftershock release timing, rendered effect
    count, reset, and pool accounting are exact. No effect dictionary is allocated after
    store initialization during a saturated effect soak.

### Phase 7 - Remove HUD and presentation allocation tails

- [ ] **7.1 Publish atomic HUD clusters and reuse world-channel frames**
  - Owners: `scripts/ui/vehicle_hud_presenter.gd`, `scripts/vehicle/vehicle_run.gd`, and
    HUD/minimap validators. `VehicleGameplayHud` may change only if required to consume
    the same snapshot schema without visual/layout changes.
  - Accept: initial publication is complete; unchanged clusters are absent; damage,
    heal, max-hull, XP, and level changes always include the entire hull/progression
    cluster and never render `1/1` unless simulation is `1/1`; all action siblings stay
    atomic; world cadence is 5 Hz; two marker buffers alternate and neither mutates while
    retained; marker roles/order/count match the current oracle at 320 enemies.
- [ ] **7.2 Reuse the synchronous combat-presentation frame**
  - Owners: `scripts/vehicle/vehicle_run.gd`,
    `scripts/player/vehicle_secondary_runtime.gd`,
    `scripts/vehicle/vehicle_terrain_runtime.gd`,
    `scripts/presentation/vehicle_combat_renderer.gd`, and renderer/run validators.
  - Accept: repeated syncs reuse the top-level frame and nested bounded buffers;
    renderer-visible fields equal the old snapshot oracle; all actor/projectile/shard/
    effect counts, support fields, mines, orbit blades, drone, protection, cursor, and
    damage overlays remain identical; render batches stay at or below 50.

### Phase 8 - Consolidated qualification

- [ ] **8.1 Run focused correctness checks and one production Web export**
  - Run the Test Plan only after Phases 5-7 are implemented. Fix task-owned failures and
    rerun only affected checks. Then run the complete named batch once.
- [ ] **8.2 Commit the implementation and run native release scenarios**
  - Measure from the exact clean implementation commit with normal stride-7
    instrumentation. Quote the window position as `'40,40'`; unquoted PowerShell input
    becomes invalid `40 40`.
  - Accept both `peak_horde` and `capacity_pressure`: exact workload/count/cadence,
    focused window, supported viewport, matching clean commit metadata,
    `thresholds.passed=true`; frame p95/p99 at most `18/25 ms`, median at least `59 FPS`,
    1% low at least `55 FPS`, at most one consecutive frame over `33.3 ms`; capacity
    physics p95/p99 at most `6/8 ms`; draw p95 at most 200 and batches at most 50.
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
  'validate_vehicle_hud_presenter.gd',
  'validate_vehicle_combat_renderer.gd',
  'validate_vehicle_stage_ui_layout.gd',
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
| Batched cache differs from brute-force semantics | Reject the cache result; fix pair enumeration, generation stamping, or top-eight ordering. Never relax the oracle. |
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
- Effect pooling crosses simulation and renderer ownership. A dedicated store prevents
  `VehicleRun` or the renderer from becoming a catch-all, while `VehicleRun` retains the
  gameplay side effect for scheduled aftershock.
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

## Progress

- [x] Reproduce the corrected workload and preserve an authoritative failure.
- [x] Run current-source causal ablations for steering and static motion.
- [x] Trace secondary physics, HUD, and presentation owners.
- [x] Compare alternatives and lock the selected architecture.
- [ ] Complete Phase 5.
- [ ] Complete Phase 6.
- [ ] Complete Phase 7.
- [ ] Complete Phase 8 and retire this plan.

Current task: **5.1 Implement the packed batched local-overlap cache.**

## Open Questions

None inside the authorized scope. Implementation-local mechanics may be resolved without
user interruption when they preserve the locked responsibilities, behavior, capacities,
cadences, dependencies, and acceptance criteria above.
