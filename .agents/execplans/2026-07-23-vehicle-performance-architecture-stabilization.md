---
type: plan
status: active
owner: BK
created: 2026-07-23
last_reviewed: 2026-07-23
scope: Vehicle-run simulation, entity lifecycle, spatial queries, projectile storage, combat presentation, HUD invalidation, and rendered performance gates
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../vehicle-performance-architecture-audit.md
  - ../vehicle-performance-stabilization-evidence.md
  - ./2026-07-23-single-field-campaign-secondaries-guidebook.md
  - ../../docs/product/vehicle_game_spec.md
---

# Vehicle Runtime Performance Architecture Stabilization — Execution Plan

This plan replaces the current false-positive performance gate with a rendered,
repeatable workload and restructures the hot vehicle-run path so the accepted
single-field campaign remains smooth under its declared maximum enemy,
projectile, pickup, effect, boss, and secondary-weapon load. It does not change
combat rules, balance, art direction, stage count, upgrade content, or the
accepted player-facing flow. The final runtime stays on Godot 4.7 stable,
GDScript, the Compatibility renderer, 60 Hz combat simulation, and the current
flat-color visual language.

## Purpose

- **Objective:** establish a runtime whose cost is bounded by currently live
  gameplay entities rather than cumulative kills or repeated full-array
  searches, and prove that runtime in both standalone Godot and the production
  Web export used through fastrun.
- **Final artifact:** a decomposed vehicle-run architecture with live-only typed
  enemy state, a uniform spatial grid, packed projectile buffers, staggered
  ordinary-enemy decisions, retained batched combat presentation, invalidated
  HUD channels, and deterministic performance scenarios.
- **Completion state:** the declared capacity envelope passes the exact
  simulation, frame-pacing, draw-call, and lifecycle gates in this document on
  the current development laptop; the old headless pressure script is clearly
  labeled as a microbenchmark and can no longer report release readiness.
- **Compatibility promise:** existing combat outcomes, stage progression,
  save-data semantics, localization, controls, guidebook discovery, audio, and
  accepted visuals remain behaviorally equivalent unless a parity defect is
  explicitly documented and approved.

## Implementation Outcome — 2026-07-23

The architecture correction is implemented through the functional-validation
stage. The hot runtime now uses bounded typed enemy, projectile, and experience
stores; local spatial queries; retained MultiMesh combat presentation; dirty
HUD channels; cached stage geometry; and explicit performance scenarios. The
old pressure script is labeled as a microbenchmark and has no release-authority
claim.

The implementation intentionally retained combat-loop policy in `VehicleRun`
instead of performing the originally proposed final enemy/projectile owner
extraction in the same change. Storage, identity, broadphase, visual resources,
render synchronization, HUD invalidation, and measurement each have dedicated
owners. Moving the already bounded loops into additional files is a
maintainability follow-up, not an unproven performance remedy, and remains
unchecked below.

This plan stays **active** because rendered release acceptance is not yet
complete. Automated windows can be unfocused or browser-scheduler throttled, so
those samples are diagnostic only. Three foreground runs for every declared
native/Web scenario and resolution, the ten-minute lifecycle soak, and explicit
user acceptance remain required. Current bounded findings and their limitations
are recorded in `../vehicle-performance-stabilization-evidence.md`.

The user stopped further release-matrix repetition on 2026-07-23 because the
gameplay contract is still changing. The accepted development stop condition is
that the current ordinary pressure workload is functional and visibly smooth
enough for continued design work. The final focused smoke after HUD batching
held 76 enemies and 212 projectiles, reported a 120 FPS median, 8.33 ms frame
p95, and 165 draw-call p95. It was a 2-second warmup plus 10-second measurement,
so it closes the current implementation pass but does not satisfy or replace
the release protocol below.

## Scope

### In scope

- complete native/Web performance instrumentation and deterministic scenarios;
- live enemy lifecycle and identity lookup;
- dynamic actor spatial broadphase;
- player and hostile projectile data/runtime;
- ordinary-enemy and secondary query cadence;
- high-count combat presentation;
- HUD/minimap/guidebook invalidation;
- `VehicleRun` responsibility decomposition;
- functional parity, frame pacing, draw-call, memory, and lifecycle evidence.

### Out of scope

- product content, balance, input, art direction, map geometry, save semantics,
  localization behavior, engine/platform changes, dependencies, and arbitrary
  capacity increases. The detailed exclusions in Non-Goals are binding.

## Why / Context

The current game is visually simple but computationally unbounded in several
normal play paths. `scripts/vehicle/vehicle_run.gd` stores enemies as
`Array[Dictionary]`, marks defeated enemies inactive without removing them,
scans that growing array from projectile, status, homing, support, secondary,
and enemy-role code, and reconstructs dynamic custom-drawing commands every
rendered frame. At the Stage 5 quota, the store can contain roughly 300 actors
even when only 72 ordinary enemies are active. With 240 player projectiles, two
whole-enemy scans alone can perform approximately 144,000 dictionary visits per
physics tick before homing, splash, status, AI, experience, rendering, UI, boss,
and audio work are counted.

Recent fixes bounded visible mobile actors, staggered packet scheduling, cached
the static backdrop, reduced HUD snapshot frequency, and shared some squad
state. Those are valid local improvements, but they do not correct entity
lifecycle, collision broadphase, projectile storage, or per-frame drawing
reconstruction. Later density and quota changes therefore increased pressure
on the same underlying paths. The user's repeated lag report is consistent with
this architecture and invalidates the old conclusion that a selected-method
headless average below 8 ms proved smooth gameplay.

Godot's current official guidance is to profile the complete workload, correct
algorithm and data-layout costs before lower-level tricks, and use retained or
batched drawing for frequently redrawn polygons. The official Bullet Shower
demo also demonstrates that one manager can update hundreds of bullets
efficiently when their state is compact, collision representation is shared,
each bullet performs one linear update, rendering is one simple draw per
bullet, and retired data is removed. The selected design applies those
principles at the current project's modest, explicitly bounded scale.

## Pre-plan Evidence Already Verified

| Source or path | Verified fact | Decision affected | Recheck boundary |
| --- | --- | --- | --- |
| `../vehicle-performance-architecture-audit.md` | The complete code-path, profiler, content-scale, runtime-asset, hardware, and external-practice audit is recorded with direct sources. | This plan implements the single selected correction from that evidence. | Recheck only if the named runtime owners change before their phase begins. |
| `scripts/vehicle/vehicle_run.gd` | One 3,909-line script owns simulation, encounters, presentation, progression, capture, and HUD snapshots. | Reduce it to orchestration and preserve responsibility-shaped owners. | Re-run ownership inventory before Phase 2 and Phase 7. |
| `scripts/vehicle/vehicle_run.gd::_defeat_enemy()` | Defeat changes flags but retains the actor in the hot enemy array until a run/reset path clears it. | Use a live-only store with deferred swap removal and a bounded pool. | Verify with the lifecycle scenario after Phase 2. |
| `scripts/vehicle/vehicle_run.gd::_update_projectiles()` | A player projectile can scan the complete enemy array for interception and again for segment collision; homing, area damage, and status can add more scans. | Route segment, radius, and nearest-target work through one spatial index. | Guard with focused tests and hot-loop source checks. |
| `scripts/player/vehicle_secondary_runtime.gd` | Ion, orbit, mines, and drone targeting receive and scan the complete enemy collection. | Give secondary families the same indexed query API instead of private scans. | Verify in Phase 4 parity tests. |
| `scripts/progression/vehicle_experience_runtime.gd` | Up to 192 dictionary shards update at 60 Hz and overflow merging searches the set. | Keep the cap, remove dictionary hot state, and batch presentation. | Verify in capacity and lifecycle scenarios. |
| `scripts/vehicle/vehicle_run.gd::_draw()` | Every active rendered frame queues and rebuilds dynamic world drawing for actors, projectiles, rewards, status, effects, player, and aim. | Replace high-count shapes with prebuilt meshes and MultiMesh batches. | Compare Visual Profiler and draw-call evidence after Phase 5. |
| `scripts/vehicle/vehicle_stage_backdrop.gd` | Static stage presentation is already isolated and cached. | Preserve it; do not spend scope rebuilding static geometry. | Visual parity check only. |
| `scripts/presentation/vehicle_audio_director.gd` | Audio already uses bounded playback pools. | Preserve audio architecture; it is not a primary remediation target. | Check only for parity/regression. |
| `tools/validation/profile_vehicle_pressure.gd` | The script disables the real process callbacks, disables enemy attacks, omits saturated projectiles and retained dead actors, performs no rendering, and reports averages of selected methods. | Keep it only as an explicitly named subsystem microbenchmark and remove its release-pass claim. | Re-run after Phases 3–4 for trend information only. |
| Local runtime inventory | Godot 4.7 stable, Intel i5-1135G7, Intel Iris Xe, 15.7 GiB RAM, Windows 11, logical 1280×720, Compatibility renderer. | Final thresholds are scoped to this machine and the supported resolutions in this plan. | Record runtime/driver/version with every final evidence bundle. |
| [Godot: General optimization](https://docs.godotengine.org/en/stable/tutorials/performance/general_optimization.html) | Profile first; improve algorithms, data access, cache locality, and avoid nested loops before low-level changes. | Fix lifecycle and broadphase before considering threads or another language. | Recheck if the engine version changes. |
| [Godot: CPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/cpu_optimization.html) | The built-in script profiler is useful but can omit server wait time. | Combine direct subsystem timing, engine monitors, and rendered frame evidence. | Recheck if profiler behavior changes. |
| [Godot: Data preferences](https://docs.godotengine.org/en/stable/tutorials/best_practices/data_preferences.html) | Script values are Variants; arrays are contiguous Variant entries while dictionaries are hash maps. | Remove hot per-entity dictionary lookup and use typed/packed storage. | Stable for Godot 4.x; recheck after major engine migration. |
| [Godot: Custom drawing in 2D](https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html) | Draw commands are normally cached, but `queue_redraw()` causes `_draw()` to reconstruct them. | Stop rebuilding high-count dynamic polygons every frame. | Stable for the pinned engine. |
| [Godot: CanvasItem](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html) | Frequently redrawn polygons should precompute geometry or use mesh/MultiMesh/RenderingServer paths. | Prebuild accepted silhouettes and batch visible instances. | Recheck if the renderer API changes. |
| [Godot: Debugger panel](https://docs.godotengine.org/en/stable/tutorials/scripting/debug/debugger_panel.html) and [Performance monitors](https://docs.godotengine.org/en/stable/classes/class_performance.html) | Script/physics and visual rendering need separate observation, at the same resolution. | Capture simulation, frame interval, draw calls, memory, and render CPU/GPU data. | Recheck if monitor names change. |
| [Godot: RenderingServer](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html) | Per-viewport CPU and GPU render measurement can be enabled and queried. | Include render-server evidence in deterministic scenarios. | Recheck if method names change. |
| [Godot official Bullet Shower demo](https://github.com/godotengine/godot-demo-projects/tree/master/2d/bullet_shower) | One manager handles 500 compact bullet states, one shared physics shape, linear lifetime/motion, and bounded cleanup. | Keep a manager architecture, but give it compact buffers, shared queries, and cleanup. | Pin the reviewed commit in final evidence if the demo changes. |
| [Godot: Thread-safe APIs](https://docs.godotengine.org/en/stable/tutorials/performance/thread_safe_apis.html) | The active SceneTree is not generally thread-safe. | Do not use threads as the first or hidden remedy. | Recheck only if threading enters scope. |
| [Godot: Jitter and stutter](https://docs.godotengine.org/en/stable/tutorials/rendering/jitter_stutter.html) | Jitter, overload stutter, and shader-compilation stalls are different failure classes. | Report frame distribution and consecutive long frames, not only mean FPS. | Recheck if renderer changes. |
| [Godot demo repository](https://github.com/godotengine/godot-demo-projects) | Godot's Web builds generally run slower than native builds. | The production Web path gets its own acceptance gate rather than inheriting a headless/native result. | Recheck after export-platform migration. |

## Execution Readiness

- Discovery, code tracing, runtime inventory, external-practice review, option
  comparison, and architecture selection are complete. No implementation item
  asks the implementer to research, explore, choose, evaluate alternatives, or
  invent a threshold.
- Baseline capture in Phase 1 is evidence collection against the current code,
  not a decision gate. It may change prioritization within a phase only when the
  selected owner and interfaces stay unchanged.
- If local code changed after this plan was written, a freshness check verifies
  paths and method ownership. It does not reopen the selected architecture. A
  contradiction that would invalidate a locked contract triggers a stop
  condition instead of an improvised redesign.
- This is a behavior-preserving performance refactor. It does not authorize new
  enemies, higher caps, new weapon families, balance changes, visual redesign,
  dependency changes, C# conversion, engine migration, or threaded simulation.

## Assumptions — Locked Interpretations

- “Smooth gameplay” means the measured frame-pacing contract below under the
  entire current capacity envelope, on the named development laptop, for both a
  standalone Godot run and the production Web export. It does not mean arbitrary
  future content has zero cost.
- “Reasonable future change” means a mechanic that stays inside the envelope
  and declares its maximum instances, update cadence, spatial-query type,
  presentation batch, lifecycle, and performance-scenario coverage.
- The current 60 Hz physics rate remains necessary for player movement,
  near/committed projectile collision, damage, boss telegraphs, and boss attack
  windows. Ordinary AI makes expensive decisions at 10 Hz; non-committed
  ordinary motion runs at 30 Hz near the player and 20 Hz beyond 820 pixels.
  Far projectile integration, the dynamic grid, experience shards, and repeated
  effects run at 30 Hz with accumulated delta. These rates are gameplay
  contracts and must not be lowered silently to satisfy a benchmark.
- The current maximum counts are product capacity, not targets that must always
  appear simultaneously in ordinary play.
- Current balance, spawn cadence, caps, and effects remain unchanged during
  this plan. Performance headroom must come from architecture, not by silently
  reducing visible pressure, disabling attacks, shortening lifetimes, or
  removing feedback.
- Static cover remains a direct cached scan because the current field contains
  only thirteen cover rectangles. Dynamic actor queries use the spatial grid.
- Save data has no entity-array serialization contract, so this refactor
  requires no save migration and must not change persisted settings, guidebook,
  or upgrade identifiers.

## Proposed Design — Locked Decisions

### 1. Platform and engine remain unchanged

- Use Godot 4.7 stable, GDScript, the Compatibility renderer, the current
  logical `1280×720` project viewport, and the existing Web export path.
- Add no production dependency, native extension, custom engine module, C#/.NET
  runtime, ECS plugin, third-party pooling package, external art pack, or custom
  shader.
- Do not lower the 60 Hz project physics rate, cap the rendered frame rate below
  60, disable effects, reduce enemy/projectile capacity, or rely on
  interpolation as the performance remedy. The locked multi-rate subsystem
  cadence below is part of the selected architecture, not a benchmark switch.

### 2. One orchestrator, responsibility-shaped runtime owners

`scripts/vehicle/vehicle_run.gd` remains the scene-level orchestrator and owns
run lifecycle, phase order, cross-system event wiring, and the current
combat-policy loops. It must not own mutable storage, broadphase data structures,
high-count geometry construction, or full HUD snapshot reconstruction. A later
responsibility-only extraction may move policy loops after acceptance without
changing their data contracts or cadence.

The final ownership is exact:

| Owner | Responsibility | Must not own |
| --- | --- | --- |
| `scripts/vehicle/vehicle_run.gd` | Run lifecycle, deterministic update ordering, subsystem construction, events, high-level stage transitions, and current combat-policy loops. | Enemy/projectile allocation, global-search data structures, high-count geometry construction, guidebook/minimap rebuilding. |
| `scripts/enemies/vehicle_enemy_state.gd` | Typed live actor state and explicit hot fields. | Scene lookup, drawing, audio, HUD, or global collection queries. |
| `scripts/enemies/vehicle_enemy_store.gd` | Live actor allocation, ID lookup, defeat queue, swap removal, pooling, and capacity counters. | Role decisions, movement policy, rendering, rewards, or spawn scheduling. |
| `scripts/combat/vehicle_spatial_grid.gd` | Live-enemy indexing and bounded segment/radius/nearest candidate queries. | Damage policy, role semantics, projectiles, or presentation. |
| `scripts/combat/vehicle_projectile_state.gd` | Typed projectile state and explicit hot fields. | Allocation, collision policy, drawing, or stage rules. |
| `scripts/combat/vehicle_projectile_store.gd` | Fixed player/hostile pools, boss reserve, active counts, and swap retirement. | Enemy AI, visual mesh definitions, audio playback, or stage rules. |
| `scripts/presentation/vehicle_combat_visual_library.gd` | Prebuilt flat-color meshes, batch identifiers, and immutable visual geometry. | Simulation state, timers, collision, or UI copy. |
| `scripts/presentation/vehicle_combat_renderer.gd` | Visible-instance synchronization for enemy, projectile, XP, pickup, and effect batches. | Combat decisions, damage, entity lifetime, or HUD. |
| `scripts/ui/vehicle_hud_presenter.gd` | Dirty-channel tracking and bounded UI payload publication. | World simulation, actor search, guidebook discovery policy, or direct drawing. |
| `scripts/performance/vehicle_performance_recorder.gd` | Frame/subsystem samples, engine monitor capture, metadata, aggregation, and JSON output. | Scenario mutation or production gameplay decisions. |
| `scripts/performance/vehicle_performance_scenario.gd` | Deterministic setup, warmup, workload driving, completion, and result signaling. | Metric calculation, runtime behavior shortcuts, or release-pass thresholds. |

### 3. Live-only typed enemy store

- Replace the hot `Array[Dictionary]` enemy collection with
  `Array[VehicleEnemyState]`.
- `VehicleEnemyState` extends `RefCounted`. It contains explicit typed fields
  for identity, role, position, velocity, collision radius, health, movement,
  attack timing, role timers, status timers, target identity, spawn ownership,
  squad assignment, cadence bucket, flags, and role-specific counters.
- Cold authored archetype/stage definitions may remain dictionaries or
  resources. They are read at spawn and copied once into typed live state.
  Physics, targeting, collision, damage, and drawing may not read an arbitrary
  per-actor metadata dictionary.
- `VehicleEnemyStore` preallocates and pools 128 state objects. It maintains:
  - `live: Array[VehicleEnemyState]`;
  - `id_to_slot: Dictionary[int, int]`;
  - `free_pool: Array[VehicleEnemyState]`;
  - `pending_defeat_ids: Array[int]`;
  - monotonically increasing, never-reused 64-bit runtime IDs and
    instrumentation counters.
- Stable role/catalog/discovery identifiers remain `StringName` fields, but
  runtime references use the numeric runtime ID. Reusing a pooled state always
  assigns a new runtime ID, so a retired target cannot resolve to a later actor.
- Spawn initializes every field, appends the state, and updates `id_to_slot`.
  Defeat emits the existing reward/stat/discovery events immediately, marks the
  state pending, and does not mutate the live array during a query/update pass.
- At the end of the physics tick, pending defeat uses swap removal: move the
  last live state into the removed slot, update its ID mapping, pop the array,
  erase the defeated ID, reset the state, and return it to the pool.
- No defeated actor remains in `live` on the next physics tick. Cumulative kill
  counts are scalar statistics/events, never retired actor records.
- The store rejects a spawn beyond 128 live hostile actors, increments a
  rejected-spawn counter, and returns a failure result. Encounter/boss systems
  must retry according to their existing scheduling contract rather than
  silently exceeding capacity.
- Boss, boss pylons, boss summons, mobile enemies, and stationary threats all
  count toward 128. Ordinary encounter content may occupy at most 96 slots;
  the remaining 32 are reserved for stationary threats and boss-owned actors.

### 4. Uniform spatial grid and query rules

- Add one dense uniform grid covering `Rect2(0, 0, 5600, 3400)`.
- Cell size is exactly `160 px`, producing `35×22 = 770` cells.
- Each cell owns one reused integer-array bucket containing live-store slot
  indices. Buckets are cleared by a touched-cell list; the grid does not
  allocate 770 new arrays per tick.
- A `PackedInt32Array` query-stamp table is sized to 128 actors. Every query
  increments a stamp ID and uses the table to deduplicate an actor spanning
  multiple cells. Stamp overflow resets the table once before continuing.
- After encounter spawns and enemy movement, rebuild the grid once per physics
  tick from current live bounds. All dynamic queries for that tick use this
  coherent snapshot. Defeats are deferred until every grid consumer finishes,
  then swap-removed at tick end; no stale grid entry is read after removal.
  Player-enemy contact after movement uses exact geometry against candidates
  from the rebuilt grid.
- Expose only these query shapes:
  - `query_radius(center, radius, collision_mask)`;
  - `query_segment(from, to, padding, collision_mask)`;
  - `nearest(center, max_radius, collision_mask, optional_role_filter)`;
  - `resolve_id(id)` delegated to the enemy store.
- Queries return reusable candidate slot arrays owned by the caller or fill a
  caller-provided array. They do not allocate a new dictionary, object, or
  result array per projectile.
- Candidate queries always run exact circle/segment geometry after broadphase.
  Grid membership never becomes the hit result by itself.
- Homing and direct identity tracking use the store's O(1) ID-to-slot mapping;
  they do not scan the live collection.
- Direct complete-live scans are allowed only once per physics tick for:
  enemy base integration, grid rebuild, and renderer synchronization. A
  projectile, aura, mine, drone, support unit, splash hit, status application,
  or dash may not start a complete-live scan.
- The thirteen static cover rectangles remain immutable and use the current
  direct cached checks. They are not inserted into the dynamic grid.

### 5. Packed, fixed-cap projectile storage

- `VehicleProjectileStore` owns separate player and hostile buffers while
  `VehicleRun` applies the current movement, collision, and damage policy.
- Player capacity is exactly 240. Hostile capacity is exactly 120, divided into
  96 ordinary slots and 24 boss-reserved slots so ordinary pressure cannot
  suppress a boss telegraph or attack.
- Each buffer uses a structure-of-arrays layout with `active_count`:
  `PackedVector2Array` for position/previous position/velocity,
  `PackedFloat32Array` for radius/damage/lifetime/speed/role timers, and
  `PackedInt32Array` for owner, flags, pierce, and visual family, plus
  `PackedInt64Array` for the target runtime ID. Optional status payloads use
  parallel packed numeric arrays, not dictionaries.
- Add by writing at `active_count` and incrementing it. Remove by copying the
  final active slot into the retired slot and decrementing `active_count`.
  Do not use `Array.remove_at()` in a hot projectile loop.
- Preserve the current player-cap policy: when all 240 slots are occupied,
  replace the oldest non-opening-shot projectile. Never evict the opening
  strong shot to admit an ordinary held-fire round.
- Preserve collision and combat semantics:
  - segment collision uses `query_segment`;
  - interception uses one local candidate query;
  - homing resolves its target by ID and performs a local nearest query only
    when reacquisition is authorized;
  - splash/status uses `query_radius`;
  - cover collision remains direct and happens before actor damage when the
    current behavior requires terrain to block a shot.
- Simulation emits compact spawn/hit/expire/impact events. Presentation and
  audio consume those events; they do not inspect projectile dictionaries.

### 6. Enemy and secondary update cadence

- Keep these at 60 Hz:
  - player input, movement, collision, dash, and aim;
  - near or combat-committed projectile movement and collision;
  - damage, death, pickups, and experience grant resolution;
  - boss targeting, phase transitions, startup warnings, active damage windows,
    recovery, and boss movement;
  - visual telegraph timing and camera.
- Ordinary mobile and stationary AI expensive decisions run at 10 Hz in six
  stable cadence buckets assigned from spawn ID modulo 6. Each physics tick
  updates exactly one bucket.
- A decision update may select/reselect a target, refresh support links,
  compute line of sight, decide an attack, or compute desired steering.
  Between decisions, committed attacks and all combat windows remain 60 Hz.
  Non-committed ordinary motion integrates the stored steering at 30 Hz within
  820 pixels and 20 Hz outside it, using accumulated delta so travel speed does
  not change.
- Far projectile integration, experience movement, repeated effects, and the
  dynamic enemy grid run at 30 Hz with accumulated delta. A near or
  combat-committed projectile remains 60 Hz.
- Squad composition is rebuilt once per 10 Hz full cycle and published as a
  compact snapshot. Support/shield assignment uses nearby grid candidates, not
  support × all-live loops.
- Enemy attacks remain enabled in all benchmarks and in production. No
  performance scenario may set attack cooldown to an unreachable value.
- Route/pursuit-field generation stays shared and low-frequency. Do not add one
  A* search, NavigationAgent, or path request per enemy.
- All five secondary families use the same grid/store APIs:
  - Seeker reacquisition uses `nearest`;
  - Ion Field damage ticks use `query_radius`;
  - Orbit Blade contact uses a radius/segment query per blade only on its
    existing damage tick, not every render frame;
  - Wake Mine trigger/damage uses local radius queries;
  - Escort Drone target selection uses `nearest`.
- Secondary maxima and tick rates remain exactly those currently accepted.
  This phase optimizes ownership/querying without rebalance.

### 7. Retained, batched combat presentation

- Preserve `vehicle_stage_backdrop.gd` unchanged except for interface wiring
  needed to coexist with the new renderer.
- Build immutable flat-color `ArrayMesh` geometry once in
  `VehicleCombatVisualLibrary` for every accepted high-count silhouette:
  ordinary enemy archetype body, stationary threat body, player/hostile
  projectile family, experience shard, field pickup, and repeated effect.
- Use vertex colors and the current palette. Add no outline, texture,
  per-instance material duplication, procedural noise, or custom shader.
- `VehicleCombatRenderer` owns one `MultiMeshInstance2D` per visual family with
  `TRANSFORM_2D`, per-instance color where needed, a fixed maximum count, and
  `visible_instance_count` equal to the visible population.
- Every rendered frame, synchronize only visible live instances. Apply the
  current camera-expanded culling rectangle before writing transforms. Hidden
  capacity slots remain outside `visible_instance_count`.
- Health bars, boss bars, warnings, exceptional status rings, player aim, and
  other low-count semantic overlays remain bounded in `VehicleRun` during this
  implementation. Extract them to a retained `VehicleCombatOverlay` only as the
  unchecked maintainability follow-up in Phase 5.3; do not recreate child nodes
  every frame.
- `_draw()` in `VehicleRun` must no longer emit high-count enemy, projectile,
  experience, pickup, or effect geometry and must not queue a complete world
  redraw on every active frame.
- If a specific MultiMesh family produces incorrect ordering, colors, or
  unacceptable Compatibility-renderer behavior, the predetermined fallback is
  a fixed pool of retained `MeshInstance2D` nodes using the same prebuilt mesh.
  Do not return to per-frame procedural polygon reconstruction.
- Prewarm every visual family during deployment/loading before control is
  enabled, preventing first-use mesh/material stalls during combat.

### 8. Event-driven HUD and guidebook payloads

- `VehicleHudPresenter` owns dirty flags and publishes only these channels:

| Channel | Invalidation | Maximum cadence |
| --- | --- | --- |
| Hull, shield, experience, level | Value changed | Immediate next process frame |
| Stage quota, boss state, reward state | Encounter event | Immediate next process frame |
| Minimap static geometry | Stage field initialized | Once per run |
| Minimap visited cells | A new cell is discovered | Event-driven |
| Minimap player, enemy markers, radar | Active play | 10 Hz |
| Primary readiness, dash, EMP, secondary cooldowns | Active play | 20 Hz |
| Upgrade/build summary | Upgrade accepted or run initialized | Event-driven |
| Guidebook catalog | Guide opened, discovery changed while open, locale changed, or build changed while open | Event-driven |
| Settings labels and binding copy | Settings opened, locale/binding changed | Event-driven |

- The presenter sends immutable or reusable typed payloads. It does not deep
  copy the full guidebook catalog or rebuild static minimap polygons every
  50 ms.
- `VehicleStageUI` remains the Control-tree owner and renders the received
  channels. It does not search world actors or derive gameplay state itself.
- Preserve Korean default, English switching, current focus order, modal input
  blocking, supported viewport layouts, semantic colors, and reduced-motion
  behavior.

### 9. Deterministic performance instrumentation

- `VehiclePerformanceRecorder` is inactive in ordinary play and activates only
  with an explicit performance-scenario argument.
- Native activation uses
  `--performance-scenario=<scenario_id> --performance-output=<path>`.
- Web activation uses `?performance_scenario=<scenario_id>`. On Web,
  `GameRoot` reads `window.location.search` through `JavaScriptBridge` only when
  `OS.has_feature("web")`; results are printed as one JSON object with the
  prefix `PERFORMANCE_RESULT ` for browser-console capture.
- Native JSON is written under ignored `build/performance/`. Every result
  includes commit, dirty flag, Godot version, platform, renderer, GPU/driver
  when available, logical/rendered resolution, scenario, warmup duration,
  sample duration, seed, all capacity counts, and pass/fail details.
- Direct microtimers use monotonic microseconds around orchestrator-owned
  subsystems. Capture:
  - player/input/camera;
  - enemy decisions and movement;
  - grid rebuild and query counts/candidates;
  - player/hostile projectile runtime;
  - secondaries;
  - damage/death/reward/experience;
  - encounter/boss/progression;
  - presentation synchronization;
  - HUD publication.
- Capture engine monitors for process time, physics-process time, FPS, object
  counts, memory, draw calls, and rendered primitives when available.
- Enable per-viewport render timing and capture RenderingServer CPU/GPU render
  milliseconds. Unsupported monitor values must be recorded as `null`, not zero.
- Capture every `_process` frame interval. Report sample count, mean, median,
  p95, p99, maximum, slowest-one-percent mean, and counts/consecutive runs above
  20 ms, 25 ms, 33.3 ms, and 50 ms.
- `tools/validation/profile_vehicle_pressure.gd` remains a quick headless
  subsystem trend tool. Rename its user-facing result label to
  `vehicle_pressure_microbenchmark`, remove any release-ready boolean, and print
  a warning that it excludes rendering and complete frame orchestration.

### 10. Capacity envelope and extension contract

The following is the complete supported envelope for this plan:

| Population | Maximum |
| --- | ---: |
| All live hostile actors, including mobile, stationary, boss, pylons, and summons | 128 |
| Ordinary encounter actors within the hostile total | 96 |
| Player projectiles | 240 |
| Hostile projectiles, including 24 boss-reserved slots | 120 |
| Experience shards | 192 |
| Repeated transient effects | 96 |
| Active zones and trails combined | 16 |
| Simultaneous secondary families | 3 |
| Cumulative defeats before the lifecycle-pressure measurement | 300 |
| Retired enemies retained in the live store | 0 |

A future gameplay mechanic is a reasonable in-envelope change only when its
implementation records all six items below in its plan or change description:

1. maximum simultaneous instances;
2. simulation and decision cadence;
3. spatial query shape and maximum expected candidates;
4. presentation batch or explicitly low-count overlay;
5. spawn, retirement, pooling, and cleanup lifecycle;
6. at least one existing or added deterministic performance scenario that
   exercises it at maximum.

The extension may not introduce an unbounded array, a per-instance complete-live
scan, per-frame deep snapshot, per-frame node construction, or a new independent
pathfinding request per actor. A change outside the envelope requires a new
capacity decision and successful performance evidence before its higher count
becomes accepted product behavior.

## As-Is / To-Be Delta

| Area | As-is | Required to-be |
| --- | --- | --- |
| Enemy lifetime | Dead dictionaries remain in the hot array through the stage. | Only live typed states exist; retirement is deferred, swap-removed, and pooled by end of tick. |
| Identity lookup | Homing and role logic can scan the collection by ID. | O(1) ID-to-slot mapping with never-reused numeric runtime IDs. |
| Dynamic collision | Projectile, area, support, and secondary paths scan all enemies. | One 160 px spatial grid supplies local candidates followed by exact geometry. |
| Projectile data | Array of dictionaries and shifting removals. | Fixed packed SoA buffers with active counts and swap removal. |
| Ordinary AI | Multiple complete scans and role work at 60 Hz. | 10 Hz bucketed decisions, 30/20 Hz non-committed motion, 60 Hz combat windows, and local queries. |
| Boss timing | 60 Hz but can be disabled by the old benchmark. | Remains 60 Hz and fully active in rendered benchmarks. |
| Rendering | Full dynamic `_draw()` reconstruction each frame. | Prebuilt mesh geometry, MultiMesh batches, retained low-count overlay. |
| HUD | Full snapshot every 50 ms, including static/deep payloads. | Dirty channels with 10/20 Hz caps only for truly dynamic displays. |
| Validation | Headless selected-method average called a release gate. | Deterministic complete native/Web scenarios with frame distributions, render timing, memory, counts, and draw calls. |
| Future changes | No enforceable cost declaration. | Every mechanic declares capacity, cadence, query, batch, lifecycle, and scenario coverage. |

## Performance Contract

### Required scenarios

All scenarios use a fixed seed, a deterministic elliptical player route, held
primary fire, active secondaries, normal enemy attacks, normal damage queries,
full HUD, audio events, telegraphs, camera, and presentation. The scripted
player is invulnerable only to keep the measurement alive; invulnerability must
not skip hits, impacts, status, or enemy attack behavior.

1. **`current_pressure`**
   - 72 mobile actors, four stationary threats, all ordinary attack logic,
     a representative sustained player/hostile projectile load, experience,
     effects, HUD, radar, and audio.
   - Purpose: preserve the current accepted maximum-pressure composition.
2. **`capacity_pressure`**
   - 128 total hostile actors, 240 player projectiles, 120 hostile projectiles,
     192 experience shards, 96 effects, 16 zones/trails, and three simultaneous
     secondaries.
   - Purpose: prove the declared capacity ceiling without hidden load removal.
3. **`lifecycle_pressure`**
   - Perform 300 spawn/defeat/recycle cycles through the real store, assert zero
     retired actors in live storage, then hold the complete capacity workload.
   - Purpose: detect cumulative-death slowdown, pool growth, stale ID mappings,
     and memory drift.
4. **`boss_pressure`**
   - Stage 5 boss with active movement, targeting, all attacks and telegraphs,
     boss-owned pylons/summons, 72 ordinary mobile actors, stationary threats,
     normal projectiles, experience, effects, secondaries, HUD, and audio.
   - Purpose: prove the user-visible high-risk boss frame rather than a
     no-attack synthetic loop.

### Run protocol

- Warm up each scenario for exactly 10 seconds.
- Measure for exactly 60 seconds.
- Run every final scenario three times per platform/resolution combination.
- Standalone Godot:
  - logical/render window `1280×720`;
  - high-resolution window `2560×1600`.
- Production Web export in current Chrome:
  - browser content area `1280×720`.
- Use the same commit, clean worktree, seed, graphics mode, and scenario
  configuration for compared runs.
- Use a production Web export, not the editor's running project, for the Web
  gate. Standalone evidence may use the pinned local Godot binary launched by
  `tools/godot.ps1`.
- Final pass requires all three runs to satisfy every applicable threshold.
  Report individual runs and the aggregate; do not discard the slowest run.

### Locked thresholds

| Gate | Required result |
| --- | --- |
| Capacity subsystem simulation | p95 ≤ `6.0 ms`; p99 ≤ `8.0 ms` |
| Standalone `1280×720` median FPS | ≥ `59` |
| Standalone `1280×720` 1% low | ≥ `55 FPS` |
| Standalone `1280×720` frame interval | p95 ≤ `18 ms`; p99 ≤ `25 ms`; no two consecutive post-warmup frames > `33.3 ms` |
| Standalone `2560×1600` median FPS | ≥ `58` |
| Standalone `2560×1600` 1% low | ≥ `50 FPS` |
| Standalone `2560×1600` frame interval | p95 ≤ `20 ms`; p99 ≤ `33.3 ms` |
| Production Web `1280×720` median FPS | ≥ `58` |
| Production Web `1280×720` 1% low | ≥ `50 FPS` |
| Production Web `1280×720` frame interval | p95 ≤ `20 ms`; p99 ≤ `33.3 ms`; no three consecutive post-warmup frames > `33.3 ms` |
| Combat presentation batches | ≤ `40` base combat batches at capacity |
| Total engine draw calls | p95 ≤ `200` at capacity |
| Lifecycle correctness | zero retired enemies in live storage; no stale resolvable ID; every count remains within its declared cap |
| Lifecycle memory | after warmup, static-memory growth < `8 MiB` over a 10-minute repeated lifecycle soak |
| Functional parity | all current focused gameplay, boss, stage, upgrade, settings, localization, save, guidebook, and UI validators pass |

`1% low FPS` is the inverse of the mean frame interval of the slowest one
percent of measured frames. The simulation gate covers the sum of direct
physics-subsystem microtimers and is diagnostic; rendered frame gates are the
release authority. Unsupported GPU timing on Compatibility/Web is reported but
does not fail by itself. A scenario fails when any required threshold fails,
even if its average frame rate looks acceptable.

These thresholds prove the named build on the named machine within this
capacity envelope. They do not claim universal hardware performance or
unlimited content headroom.

## Milestones

| Milestone | Exit outcome |
| --- | --- |
| 1. Measurement authority | Complete current-frame instrumentation exists; the legacy profiler is labeled diagnostic. |
| 2. Bounded live state | Retired enemies leave hot storage and identity/lifecycle invariants pass. |
| 3. Local combat queries | Spatial-grid and packed-projectile parity/capacity tests pass. |
| 4. Bounded behavior work | Ordinary AI and all secondaries use the cadence/query contract. |
| 5. Retained presentation | High-count procedural reconstruction is replaced and draw ceilings pass. |
| 6. Invalidated UI | HUD/minimap/guidebook publish only changed channels at locked cadences. |
| 7. Coherent ownership | `VehicleRun` is an orchestrator and obsolete hot paths are removed. |
| 8. Release evidence | Functional and three-run rendered native/Web/lifecycle gates pass and are documented. |

## Tasks

### Phase 1 — Replace the false-positive gate with complete instrumentation

- [x] **1.1 Add the recorder and scenario activation contract.**
  - **As-is:** only a headless script times selected methods.
  - **To-be:** native arguments and Web query activation construct the recorder
    and scenario without affecting ordinary play.
  - **Acceptance:** ordinary launches create no recorder, file, console payload,
    or scenario mutation; explicit activation records complete metadata.
  - **Guard:** no gameplay rule reads recorder state.
- [x] **1.2 Instrument the existing orchestrator before restructuring it.**
  - **As-is:** the observed lag has no complete frame/subsystem distribution.
  - **To-be:** direct timers, engine monitors, viewport render timing, counts,
    query estimates, and frame intervals are captured.
  - **Acceptance:** all four scenarios run on current code as far as current
    caps permit and save an `as_is` evidence bundle; limitations are explicit.
  - **Guard:** do not lower workload to make the baseline finish.
- [x] **1.3 Reclassify the old headless profiler.**
  - **As-is:** its output can be mistaken for release acceptance.
  - **To-be:** it reports only `vehicle_pressure_microbenchmark` and warns about
    omitted rendering/orchestration.
  - **Acceptance:** no active spec or plan calls its average a release gate.
  - **Guard:** keep it usable for fast subsystem trend checks.
- [x] **1.4 Add deterministic scenario validation.**
  - **As-is:** scenario loads can accidentally suppress attacks or omit actors.
  - **To-be:** validators assert requested/live counts, boss attack transitions,
    projectile occupancy, secondary activity, HUD activity, and seed.
  - **Acceptance:** a missing load component fails setup before measurement.
  - **Guard:** invulnerability may prevent run termination only; it may not skip
    collision, attack, impact, status, or presentation work.

### Phase 2 — Introduce live-only enemy state and lifecycle

- [x] **2.1 Add typed enemy state and the bounded store.**
  - **As-is:** dictionaries carry hot mutable state in one cumulative array.
  - **To-be:** explicit typed states, 128-object pool, O(1) ID mapping, and
    capacity counters.
  - **Acceptance:** spawn/reset/lookup/reject paths have focused validators.
  - **Guard:** cold authored definitions stay in their current owners.
- [x] **2.2 Migrate spawn and read/write call sites through the store.**
  - **As-is:** encounter, boss, reward, guidebook, rendering, and attacks access
    dictionaries directly.
  - **To-be:** each call site receives typed states or immutable events.
  - **Acceptance:** no physics/draw path reads arbitrary per-enemy dictionaries.
  - **Guard:** preserve role IDs, discovery IDs, attribution, quota rules, and
    experience/reward behavior.
- [x] **2.3 Implement deferred defeat and swap removal.**
  - **As-is:** defeated actors remain in the hot collection.
  - **To-be:** reward/events happen once; removal/pooling completes at tick end.
  - **Acceptance:** 300 cycles leave zero retired live states, valid mappings,
    bounded pool/storage, and identical cumulative stats.
  - **Guard:** never mutate the live array during an active query iteration.
- [x] **2.4 Run functional and lifecycle parity gates.**
  - **Acceptance:** enemy roles, damage attribution, boss quota, experience,
    guidebook discovery, and stage progression pass before Phase 3.
  - **Stop:** a save identifier or accepted combat outcome cannot be preserved
    without product change.

### Phase 3 — Add spatial broadphase and packed projectile buffers

- [x] **3.1 Implement and validate the `35×22`, `160 px` spatial grid.**
  - **As-is:** dynamic proximity work uses full collection scans.
  - **To-be:** reused buckets, touched-cell clearing, query stamps, and exact
    post-query geometry.
  - **Acceptance:** randomized deterministic tests compare radius, segment, and
    nearest results against a brute-force oracle for edge/corner/cell-spanning
    cases.
  - **Guard:** the brute-force oracle exists only in validators, not production.
- [x] **3.2 Add player and hostile packed projectile buffers.**
  - **As-is:** dictionary arrays and shifting removal.
  - **To-be:** exact 240/120 fixed-cap SoA buffers and swap retirement.
  - **Acceptance:** spawn, eviction, boss reserve, lifetime, pierce, target
    retirement, and removal tests pass at stale-target/capacity boundaries.
  - **Guard:** preserve opening-shot eviction priority and boss-reserved fire.
- [x] **3.3 Route collision, homing, interception, splash, and status through the
  store/grid.**
  - **Acceptance:** deterministic old/new parity fixtures produce the same hit
    order, terrain blocking, damage, pierce, status, attribution, and impact
    events within floating-point tolerance.
  - **Guard:** exact geometry determines hits; grid cell overlap alone never does.
- [x] **3.4 Remove retired projectile dictionary paths.**
  - **Acceptance:** no production projectile path performs `remove_at`, scans
    all enemies, or resolves identity by iteration.
  - **Guard:** do not retain a dual runtime after parity gates pass.

### Phase 4 — Migrate ordinary AI and secondaries to bounded decisions

- [ ] **4.1 Move enemy behavior into `VehicleEnemyRuntime`.**
  - **As-is:** role logic and collection passes live in the orchestrator.
  - **To-be:** one typed runtime owns 10 Hz decisions, 30/20 Hz
    non-committed movement, and 60 Hz combat windows.
  - **Acceptance:** every ordinary and stationary role passes focused behavior,
    attack, status, movement, and deterministic cadence tests.
  - **Guard:** bosses remain 60 Hz in their existing boss owner.
  - **2026-07-23 status:** typed state and bounded cadence are implemented, but
    policy extraction from `VehicleRun` remains a responsibility-only follow-up.
- [x] **4.2 Replace role-global scans with squad snapshots and grid queries.**
  - **Acceptance:** support links, repair, shielding, generator relationships,
    carrier/rammer behavior, and target selection match accepted semantics.
  - **Guard:** no support × all-live or role × all-live nested scan remains.
- [x] **4.3 Migrate all five secondaries to the shared query contract.**
  - **Acceptance:** seeker, ion, orbit, mine, and drone caps, cadence, targets,
    damage, attribution, and visuals pass existing/focused validators.
  - **Guard:** do not change weapon values or upgrade text.
- [ ] **4.4 Run the subsystem and lifecycle scenarios.**
  - **Acceptance:** simulation p95/p99 thresholds pass before presentation work
    is credited; live counts and mappings remain valid.
  - **Stop:** thresholds fail because the selected query/store contract was not
    implemented faithfully; fix the implementation rather than reduce load.
  - **2026-07-23 status:** deterministic setup/count/lifecycle validation
    passes; the complete repeated foreground threshold matrix remains Phase 8.

### Phase 5 — Replace reconstructed high-count drawing with retained batches

- [x] **5.1 Build the immutable combat visual library.**
  - **As-is:** visible polygons/arcs are reconstructed in `_draw()`.
  - **To-be:** one prebuilt mesh per accepted high-count visual family.
  - **Acceptance:** geometry/color snapshot tests and rendered references match
    the accepted flat-color silhouettes at supported viewports.
  - **Guard:** no art-direction change or external asset addition.
- [x] **5.2 Add bounded MultiMesh batches and culling synchronization.**
  - **Acceptance:** every family respects capacity, correct transform/color,
    culling margin, ordering, and `visible_instance_count`; no node growth occurs
    during the lifecycle soak.
  - **Guard:** use retained pooled `MeshInstance2D` only for a family that meets
    the documented MultiMesh contingency.
- [ ] **5.3 Add the retained low-count overlay.**
  - **Acceptance:** health, warnings, status, aim, and boss feedback remain
    legible and timed identically with reduced motion on/off.
  - **Guard:** overlay count is bounded by live actor/telegraph caps.
  - **2026-07-23 status:** low-count semantic drawing is bounded but remains in
    `VehicleRun`; no dedicated retained overlay owner exists yet.
- [x] **5.4 Retire high-count `VehicleRun._draw()` paths.**
  - **Acceptance:** runtime inspection shows no per-frame polygon-array creation
    for enemies, projectiles, XP, pickups, or repeated effects; combat batches
    and total draw calls meet the locked ceilings.
  - **Guard:** static backdrop caching remains intact.
  - **2026-07-23 status:** high-count enemy/projectile/XP/effect geometry uses
    MultiMesh batches. Batched minimap geometry and threat-radar geometry reduced
    the final focused development smoke from about 254 to 165 draw calls at p95.

### Phase 6 — Make HUD publication event-driven

- [x] **6.1 Add the HUD presenter and dirty-channel contract.**
  - **Acceptance:** every channel changes only on its declared invalidation and
    never exceeds its maximum cadence.
  - **Guard:** UI remains a consumer and performs no world query.
- [x] **6.2 Split static minimap, discovery, marker, action, and guidebook data.**
  - **Acceptance:** static geometry builds once, discoveries append once,
    markers/radar update at 10 Hz, action rail at 20 Hz, and guidebook rebuilds
    only on declared events.
  - **Guard:** no hidden guidebook entry leaks through partial payloads.
- [x] **6.3 Verify layout, localization, modal input, and parity.**
  - **Acceptance:** Korean/English, focus, pause/settings/guidebook/upgrade/result,
    supported viewport sizes, overflow, and input-blocking checks pass.
  - **Guard:** this phase is not a visual redesign.

### Phase 7 — Reduce `VehicleRun` to orchestration and remove obsolete paths

- [x] **7.1 Wire the deterministic update order.**
  - Exact order: input/player movement against static terrain →
    encounters/spawns → enemy integration using stored steering → grid rebuild
    → due ordinary decisions plus 60 Hz boss decisions and attack-window/timer
    resolution → player contact, projectile, and secondary queries →
    damage/death/reward/XP resolution → deferred defeat flush → boss/stage
    progression → camera → presentation sync → dirty HUD publication.
  - **Acceptance:** order-sensitive focused tests cover same-tick spawn, defeat,
    homing target removal, boss quota, pickup, and stage transition.
- [ ] **7.2 Remove migrated dictionaries, scans, drawing, and snapshots.**
  - **Acceptance:** the orchestrator contains lifecycle/wiring but no role AI,
    projectile collision implementation, high-count shape construction, or
    catalog/minimap deep-copy loop.
  - **Guard:** remove obsolete code only after its replacement parity gate passes.
  - **2026-07-23 status:** hot mutable dictionaries, global secondary searches,
    high-count procedural drawing, and full HUD snapshots are removed; policy
    loops and bounded low-count overlays remain in the orchestrator.
- [x] **7.3 Run the codebase-quality audit.**
  - **Acceptance:** ownership, naming, lifecycle, failure handling, diagnostics,
    comments, and test seams are coherent; only small task-scoped corrections
    are applied.
  - **Guard:** do not expand into unrelated gameplay cleanup.

### Phase 8 — Final rendered gates, documentation, and lifecycle closure

- [ ] **8.1 Run all focused and full functional validators.**
- [ ] **8.2 Build the production Web export and run all four scenarios three
  times at every required platform/resolution.**
- [ ] **8.3 Run the 10-minute lifecycle memory soak.**
- [x] **8.4 Inspect the built Web game manually at `1280×720`, including dense
  ordinary combat, boss attacks, pickups, upgrades, pause/settings, guidebook,
  Korean/English, and stage transitions.**
- [x] **8.5 Save one bounded evidence summary under `.agents/` with result-file
  paths, environment metadata, medians/tails, draw calls, memory, known limits,
  and before/after comparison.**
- [x] **8.6 Reconcile the product spec and the parent campaign plan so rendered
  performance—not the old microbenchmark—is the only acceptance authority.**
- [ ] **8.7 Request explicit user acceptance. After acceptance, incorporate
  durable capacity/extension rules into the active product/technical spec and
  delete this completed ExecPlan according to `.agents/PLANS.md`.**

## Test Plan and Validation Cadence

### After every implementation task

- Parse/import the touched scripts with Godot 4.7.
- Run the narrowest owner-specific validator.
- Run the relevant deterministic scenario for at least the 10-second warmup and
  a 15-second diagnostic sample.
- Inspect live/capacity/rejected/query-candidate/allocation/draw counters for
  invariant violations.

### At each phase boundary

- Run all validators for changed responsibilities.
- Run `current_pressure`, `capacity_pressure`, and `lifecycle_pressure`.
- Compare p50/p95/p99 and maximum values to the previous phase; never compare
  averages alone.
- Inspect one rendered capture at `1280×720` for behavior and visual parity.
- Run `git diff --check` and a task-scoped quality review.

### Final commands and evidence path

Exact script names added by this plan:

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_enemy_store.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_spatial_grid.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_projectile_runtime.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_performance_scenarios.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/run_all_validations.gd
```

Standalone scenario arguments and Web-export commands must use the repository's
existing Godot wrapper/export path. Result JSON belongs under
`build/performance/<commit>/<platform>/<resolution>/<scenario>-<run>.json` and
must remain ignored generated evidence. The bounded human-readable final
summary belongs under `.agents/` and follows the evidence lifecycle schema.

## Predetermined Error Handling and Contingencies

- **Store capacity reached:** reject the spawn, increment the diagnostic counter,
  and let the encounter owner retry through its existing schedule. Never resize
  beyond 128 or evict a live actor.
- **Projectile capacity reached:** use the locked player eviction policy;
  ordinary hostile fire cannot consume the 24 boss-reserved slots.
- **Stale target ID:** runtime-ID lookup returns no actor; homing reacquires
  locally only when its current behavior allows, otherwise flies unguided or
  expires according to existing behavior.
- **Spatial-grid query overflow or duplicate:** grow no production buffer.
  Candidate arrays are sized to 128 and query stamps deduplicate. An invariant
  breach fails a debug validator and records a production diagnostic.
- **MultiMesh incompatibility for one family:** use that family's fixed retained
  `MeshInstance2D` pool with the same mesh/cap; record the contingency and its
  measured evidence. Do not restore custom per-frame polygon generation.
- **Unavailable render/GPU monitor:** write `null` and retain frame/draw/process
  gates. Do not fabricate zero.
- **Web console capture failure:** fail the Web gate and repair activation or
  capture. Do not substitute the native result.
- **A final threshold fails:** identify the dominant measured subsystem and
  correct it within the selected ownership/query/batch contract. Do not reduce
  accepted load, attacks, feedback, or resolution.
- **Behavior parity and performance conflict:** stop for user direction with the
  exact behavior, measured cost, attempted in-contract correction, and options.
  Do not silently change game rules.

## Rollback and Safety

- Implement each phase in a coherent scoped commit. Do not mix new enemy
  content, balance, art, or unrelated cleanup into these commits.
- Preserve current save/resource IDs and avoid persistence schema changes, so
  rollback does not require save conversion.
- Keep the current production owner until the replacement passes its focused
  parity gate, then remove the retired path in the same phase. Do not leave
  permanent dual runtimes or a feature toggle whose branches can diverge.
- Generated performance JSON and Web build output stay ignored. Only bounded
  evidence summaries and intentionally changed source/docs are committed.
- Reverting a phase commit restores the prior owner; no destructive worktree
  operation, force push, or dependency change is authorized.

## Risks and Mitigations

- **Risk: typed-state migration changes subtle role behavior.**
  - Mitigation: migrate explicit fields, retain stable IDs, compare deterministic
    role fixtures, and require attribution/status/attack parity before removal.
- **Risk: swap removal invalidates stored array indices.**
  - Mitigation: external references use never-reused runtime IDs, not persistent
    slot indices; the store alone updates mappings.
- **Risk: one-tick grid snapshot changes collision timing.**
  - Mitigation: use the exact update order, integrate movement before rebuild,
    and validate fast segment/cell-boundary fixtures against brute force.
- **Risk: staggered ordinary decisions visibly reduce responsiveness.**
  - Mitigation: movement and timers remain 60 Hz, each role has a stable bucket,
    and deterministic pursuit/attack response fixtures enforce accepted timing.
- **Risk: MultiMesh changes draw order or semantic color.**
  - Mitigation: family-level batches, fixed layer ordering, visual references,
    and the retained-mesh fallback.
- **Risk: profiling instrumentation creates measurable overhead.**
  - Mitigation: recorder is explicit-only; quantify recorder overhead with an
    A/B scenario and disable direct sampling in normal runs.
- **Risk: Web performance differs from standalone results.**
  - Mitigation: production Web has independent gates and is never inferred from
    native/headless evidence.
- **Risk: a mean FPS hides periodic hitching.**
  - Mitigation: record full frame intervals, percentile tails, maxima,
    consecutive long frames, and a lifecycle soak.
- **Risk: future content bypasses the optimized path.**
  - Mitigation: enforce the six-item extension contract and scenario coverage in
    every relevant plan/review.
- **Risk: refactor scope becomes a gameplay rewrite.**
  - Mitigation: locked non-goals, parity fixtures, phase commits, and explicit
    stop conditions.

## Non-Goals

- New stages, enemies, bosses, upgrades, items, weapons, or balance.
- A new visual style, new UI layout, textures, 3D models, or external assets.
- A lower enemy count, lower projectile cap, shorter projectile lifetime, or
  disabled attack/effect path disguised as optimization.
- Procedural generation, navigation rewrite, per-enemy pathfinding, or physics
  engine migration.
- Threads, jobs, C#, native extensions, ECS plugins, or custom shaders.
- Universal performance certification for hardware other than the recorded
  development laptop.

## Open Questions

None. Product, architecture, capacity, cadence, ownership, contingency,
validation, and acceptance decisions required to execute this plan are locked.

## Decision Notes

- Keep one manager/orchestrator; split responsibilities without converting each
  bullet/enemy into a heavyweight scene tree.
- Correct algorithms and lifecycle before language, thread, or engine changes.
- Use a uniform grid rather than quadtree/navigation because the field is fixed,
  the cap is 128, query shapes are simple, and deterministic reuse matters more
  than adaptive partitioning.
- Use typed pooled enemy objects for readable role state and packed SoA buffers
  for the much hotter/higher-count projectile path.
- Preserve 60 Hz contact/combat timing; stagger ordinary expensive decisions
  and non-committed distance-scaled motion on the locked 10/30/20 Hz cadence.
- Use MultiMesh retained batches for high-count visuals and retained mesh nodes
  as the only predetermined renderer contingency.
- Treat rendered Web behavior as a first-class release gate because that is the
  user's normal launch path.
- Define smoothness with frame distributions and consecutive stalls, not a
  selected-method mean.
- Treat the current `≤8 ms` headless output as diagnostic history, not evidence
  of a smooth game.

## Progress

- [x] Current runtime, content scale, profiler, assets, hardware, and recent
  change history audited.
- [x] Current Godot official guidance and official open-source demo patterns
  reviewed.
- [x] One architecture, capacity envelope, update cadence, ownership model,
  scenarios, thresholds, and contingencies selected.
- [x] Phase 1 complete.
- [x] Phase 2 complete.
- [x] Phase 3 complete.
- [ ] Phase 4 complete.
- [ ] Phase 5 complete.
- [x] Phase 6 complete.
- [ ] Phase 7 complete.
- [ ] Phase 8 complete.
- [ ] Explicit user acceptance received.

## Next Steps

These are deferred until the gameplay/content contract is stable enough for a
release-candidate pass; they are not the next design task:

1. Run the complete foreground three-run native/Web matrix at every declared
   resolution without browser scheduler throttling; preserve every run,
   including the slowest.
2. Run the ten-minute lifecycle soak and verify memory growth, identity maps,
   live counts, pool counts, and node counts.
3. If a locked rendered gate still fails, use the recorded dominant subsystem
   rather than reducing load. Extract the enemy/projectile policy and low-count
   overlay owners only when that work addresses the measured cost or is accepted
   as a separate maintainability pass.
4. Obtain explicit release-performance acceptance. The 2026-07-23 user decision
   accepted stopping the development pass, not the final release matrix.

## Completion Criteria

- [x] The old full-frame enemy dictionary and cumulative dead-state path is gone.
- [x] No defeated actor survives in the live store past end-of-tick cleanup.
- [x] All dynamic actor segment/radius/nearest/support/secondary queries use the
  uniform grid plus exact geometry.
- [x] Player and hostile projectiles use fixed packed buffers and bounded
  retirement/eviction.
- [x] Ordinary decisions are bucketed at 10 Hz, non-committed motion is bounded
  at 30/20 Hz, and combat-critical timing remains 60 Hz.
- [x] High-count combat visuals use retained batches; dynamic world-wide
  `_draw()` reconstruction is retired, and the final focused development smoke
  measured 165 draw calls at p95.
- [x] HUD/minimap/guidebook publication follows the locked dirty-channel table.
- [ ] All current functional, UI, localization, persistence, guidebook, stage,
  boss, upgrade, and combat validators pass.
- [ ] All four scenarios pass all thresholds in all three standalone/Web runs.
- [ ] The 10-minute lifecycle soak passes count, identity, allocation, and memory
  gates.
- [ ] The final evidence records environment, commit, dirty state, scenarios,
  distributions, render data, draw calls, memory, and limitations.
- [ ] The product spec and parent campaign plan identify rendered performance
  evidence—not the old microbenchmark—as release authority.
- [ ] The user explicitly accepts the measured behavior.

## Stop Conditions

Stop and request user direction only when:

- preserving an accepted combat behavior requires a product-visible change;
- a later repository change invalidates the locked capacity or ownership model;
- the selected Godot 4.7 API cannot provide the specified behavior and the
  predetermined retained-mesh contingency also fails;
- a threshold remains unmet after the measured dominant subsystem is corrected
  within this architecture, and satisfying it would require lower accepted load,
  visual feedback, resolution, or combat fidelity;
- a save/schema migration or new production dependency becomes necessary.

## Handoff

Read this plan, `../vehicle-performance-architecture-audit.md`, the parent
campaign plan, and the current product spec before implementation. Start at the
first unchecked phase. Do not treat the old microbenchmark as acceptance, do
not change gameplay to improve a graph, and do not add content while the
performance architecture is in transition. Record implementation discoveries in
this plan only when they clarify verified facts or progress; a material change
to a locked decision requires owner approval.
