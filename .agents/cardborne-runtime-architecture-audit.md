---
type: evidence
status: active
owner: BK
created: 2026-08-05
last_reviewed: 2026-08-12
topic: Cardborne runtime architecture and stutter attribution
scope: Repository history through the 2026-08-08 combat-readability implementation, retained local performance evidence, gameplay raster pack, and current Godot 4.7 guidance
source: Official Godot 4.7 documentation and Cardborne repository evidence through the 2026-08-08 combat-readability implementation based on 6339795d
related:
  - ./cardborne-performance-engineering-policy.md
  - ../docs/reports/2026-08-02-pre-asset-code-stabilization.md
  - ./semantic-v2-runtime-acceptance-evidence.md
  - ../docs/design/VISUAL_SYSTEM.md
---

# Cardborne Runtime Architecture Audit

## Purpose

Determine whether Cardborne's stutter is plausibly caused by differently sized 2D assets,
whether the runtime design has structural performance problems, and which improvements are
supported by current evidence. This is an audit, not a current-HEAD release qualification
or an implementation plan.

## Sources

### Primary external sources

- [Godot 4.7: General optimization tips](https://docs.godotengine.org/en/4.7/tutorials/performance/general_optimization.html)
  — profile first, distinguish CPU/GPU owners, prefer performant algorithms and compact,
  local data, and retest each change.
- [Godot 4.7: Debugger panel](https://docs.godotengine.org/en/4.7/tutorials/scripting/debug/debugger_panel.html)
  — the Visual Profiler measures rendering CPU/GPU and excludes scripting and physics.
- [Godot 4.7: CPU optimization](https://docs.godotengine.org/en/4.7/tutorials/performance/cpu_optimization.html)
  — profile bottlenecks, account for Node/physics cost, reuse bounded state, and avoid
  optimizing unmeasured paths.
- [Godot 4.7: Engine](https://docs.godotengine.org/en/4.7/classes/class_engine.html)
  — physics defaults to 60 ticks/s and at most eight physics steps per rendered frame;
  falling behind can make the game appear to slow down.
- [Godot 4.7: Performance monitors](https://docs.godotengine.org/en/4.7/classes/class_performance.html)
  — process/physics time, object/node count, collision pairs, draw calls, and texture/video
  memory are distinct monitors with sampling limitations.
- [Godot 4.7: GPU optimization](https://docs.godotengine.org/en/4.7/tutorials/performance/gpu_optimization.html)
  — 2D batching reduces draw/state changes; resolution sensitivity helps identify fill
  rate; transparent overlap and texture reads can be expensive when GPU-bound.
- [Godot 4.7: Importing images](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_images.html)
  — source-file bytes, decoded texture memory, compression, mipmaps, and load behavior are
  different concerns; 2D compression/mipmap choices carry quality and memory tradeoffs.
- [Godot 4.7: MultiMesh](https://docs.godotengine.org/en/4.7/classes/class_multimesh.html)
  — instancing reduces submission overhead but treats instances as one spatial object for
  visibility purposes.
- [Godot 4.7: GDScript static typing](https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/static_typing.html)
  and [GDScript basics](https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/gdscript_basics.html)
  — typed operations can use optimized opcodes; packed arrays are compact and can improve
  measured numeric hot paths.
- [Godot: Using multiple threads](https://docs.godotengine.org/en/stable/tutorials/performance/using_multiple_threads.html),
  [Thread-safe APIs](https://docs.godotengine.org/en/stable/tutorials/performance/thread_safe_apis.html),
  and [Optimization using Servers](https://docs.godotengine.org/en/stable/tutorials/performance/using_servers.html)
  — threads and direct servers are escalation paths with synchronization, SceneTree,
  rendering-resource, and readback hazards.
- [Godot 4.7: Background loading](https://docs.godotengine.org/en/4.7/tutorials/io/background_loading.html)
  — blocking resource loads can cause visible pauses; threaded loading is appropriate
  only for a demonstrated load transition with a managed request and retrieval lifecycle.

The stable MultiMesh tutorial currently warns that it was not updated for Godot 4.7. This
audit therefore relies on the current stable `MultiMesh` class reference for binding API
claims and treats tutorial-only advice as non-binding context.

### Cross-engine corroboration

These sources support general performance-engineering principles only. They are not API
authority for this Godot project.

- [Unity: Collect performance data on a target platform](https://docs.unity3d.com/6000.0/Documentation/Manual/profiling-target-device.html)
  — distinguish quick editor iteration from final measurements on the intended release
  target, because editor and profiler activity can skew results.
- [Unity: Pooling and reusing objects](https://docs.unity3d.com/6000.0/Documentation/Manual/performance-reusable-code.html)
  — reuse frequently created objects and collections when their lifecycle and capacity
  are known; pooling is a specific allocation strategy, not a universal speed switch.
- [Unreal Engine: Introduction to performance profiling and configuration](https://dev.epicgames.com/documentation/en-us/unreal-engine/introduction-to-performance-profiling-and-configuration-in-unreal-engine)
  — reason in frame time, separate CPU, GPU, memory, storage, and other bottleneck classes,
  and profile on target hardware.

Godot, Unity, and Unreal use different runtimes, yet their official guidance agrees on the
core method used here: reproduce the workload, measure the actual owner, change one causal
boundary, and validate the same case. Unity's managed-memory details do not prove a Godot
garbage-collector issue; only the narrower reuse principle is carried into this audit.

### Local sources

- `art/visuals/production/gameplay/asset-manifest.json`
- `scripts/presentation/components/vehicle_semantic_asset_provider.gd`
- `scripts/presentation/vehicle_combat_renderer.gd`
- `scripts/vehicle/vehicle_run.gd`
- `scripts/enemies/vehicle_enemy_store.gd`
- `scripts/enemies/vehicle_enemy_update_schedule.gd`
- `scripts/enemies/vehicle_enemy_local_steering.gd`
- `scripts/combat/vehicle_spatial_grid.gd`
- `scripts/performance/vehicle_performance_scenario.gd`
- `scripts/performance/vehicle_performance_recorder.gd`
- `docs/reports/2026-08-02-pre-asset-code-stabilization.md`
- `.agents/semantic-v2-runtime-acceptance-evidence.md`
- retained ignored JSON under `build/performance/`
- relevant git history through `ba8846ed`

## Findings

### 1. Unequal asset dimensions are not the demonstrated sustained-stutter cause

The current gameplay pack is small:

- 67 production PNGs total about 1.25 MB as source files.
- The theoretical decoded RGBA8 footprint is about 9.04 MB without mipmaps.
- The largest image is one 512×512 EMP texture. Bosses are 352×352. Ordinary enemies are
  primarily 112×112 or 160×160.
- Imports use lossless mode, no mipmaps, and no size limit. These are plausible 2D choices;
  changing them is a quality/memory decision, not a generic speed fix.

Source PNG bytes mainly affect storage and decompression. Pixel dimensions affect decoded
memory and can affect bandwidth/fill. The number of texture/material changes affects
batching. These are different mechanisms and must not be collapsed into “large asset.”

Cardborne's retained renderer creates a bounded MultiMesh batch per actor/projectile role
and reuses preallocated buffers (`vehicle_combat_renderer.gd:101-140, 189-233, 342-473`).
Historical visual runs recorded 33–34 combat batches against a limit of 50 and draw-call
p95 values of 85–122 against a limit of 200. Valid pre-fix root-cause evidence recorded
render CPU/GPU near 1–2 ms while total frame p95 was about 140 ms.

This strongly rejects raster size or GPU drawing as the primary cause of the observed
continuous slowdown. It does not rule out a separate first-use load hitch: the semantic
provider loads a texture on first request (`vehicle_semantic_asset_provider.gd:43-53`),
and no cold-load/texture-residency trace currently closes that question.

### 2. The game computes much more than the screen suggests

The renderer is visually simple, but the performance contract is not a small workload:

- Historical production replay evidence contained 249–276 active ordinary enemies.
- Peak pressure uses 276 enemies, 140 player projectiles, and 72 hostile projectiles in
  the current active plan.
- Capacity pressure locks 320 enemies, 240 player projectiles, 120 hostile projectiles,
  192 XP shards, and 96 effects (`pre-asset-code-stabilization.md:80-87`).
- At 60 physics ticks/s, 276 live enemies alone create up to 16,560 actor/tick dispatch
  opportunities per second before neighbor, collision, projectile, HUD, and rendering
  work are counted. Scheduling lowers non-critical work, but the full set is still scanned
  and fairness-critical phases remain full-rate.

Therefore “simple 2D game” does not imply “small CPU simulation.” The player may see a
readable scene while hundreds of offscreen or low-detail actors, projectiles, collision
candidates, encounter state, and UI summaries are still updated.

The 320/360 capacity case is a stress ceiling. The production replay's 249–276 active
ordinary enemies is more important: if that internal density is not intended product
behavior, it should be reviewed as an encounter/capacity decision. It must not be silently
lowered and called an optimization.

### 3. Valid evidence identified a physics backlog, not a rendering backlog

The last authoritative pre-fix root-cause run in the active plan reported:

| Metric | p95 or relevant value |
| --- | ---: |
| Total frame | 143.044 ms |
| Physics | 30.584 ms |
| Scheduled ordinary enemies | 20.150 ms |
| Enemies and grid | 23.521 ms |
| HUD | 15.507 ms |
| Presentation staging | 8.200 ms |
| Render CPU / GPU | 0.711 / 1.770 ms |

The run completed 3,600 physics ticks but rendered only 450 frames. A 133.333 ms median
frame corresponds to eight 60 Hz physics ticks, matching Godot's default maximum catch-up
steps. The visible “lag” was the engine repeatedly catching up expensive simulation work.

Controlled ablations made the ownership more specific: disabling local steering reduced
scheduled-ordinary p95 from 18.214 to 10.045 ms; disabling static motion checks alone
saved only about 1 ms. The primary historical problem was repeated per-owner neighbor
discovery and object-backed steering work, followed by allocation-heavy HUD/presentation
snapshots and bounded secondary simulation paths.

### 4. The original simulation data flow had design-level problems

The observed defects were not caused by Godot being unable to draw ordinary 2D sprites.
They were algorithm and ownership problems:

- Each due enemy rediscovered nearby overlap candidates, repeated symmetric pair tests,
  materialized object references, and then iterated them again for steering.
- Several physics/HUD/presentation paths built or deep-copied arrays and dictionaries at
  recurring cadence.
- The hot frame owner mixed orchestration, combat, collision, terrain, progression,
  snapshots, capture fixtures, rendering fallback, and instrumentation in one script.

Those are design problems because cost scales with actor count and because unrelated
responsibilities make measurement and safe correction harder. They are not evidence that
the product needs a different engine.

### 5. The current runtime checkpoint contains meaningful structural improvements

Runtime checkpoint `76989997` is materially better shaped than the diagnosed baseline.
Repository HEAD `ba8846ed` only records why qualification was blocked; it does not change
that runtime implementation.

- `VehicleEnemyStore` preallocates 320 states, uses stable generations, swap retirement,
  and indexed lookup (`vehicle_enemy_store.gd:4-26, 98-126`).
- `VehicleEnemyUpdateSchedule` keeps reusable worklists and separates 10 Hz decisions,
  30 Hz near motion, 20 Hz far motion, and full-rate critical phases
  (`vehicle_enemy_update_schedule.gd:13-18, 62-155`).
- `VehicleSpatialGrid` owns packed overlap rows and only scans marked owners' nearby 3×3
  buckets (`vehicle_spatial_grid.gd:335-374`).
- Projectiles and effects use bounded stores; effects use a fixed 96-state pool.
- HUD and presentation use staged/reused frames, with alternating buffers where consumers
  retain state (`vehicle_run.gd:237-248, 5700-5844`).
- Performance fixtures validate counts, focus, commit metadata, frame tails, physics,
  draw calls, and batch ceilings (`vehicle_performance_recorder.gd:245-335`).

These are appropriate data-oriented, behavior-preserving responses to the measured owners.

### 6. The current runtime checkpoint is not yet performance-qualified

The active execution contract leaves native Phase 8.2 and built-Web Phase 8.3 unchecked.
Four 60-second runs after the latest implementation were rejected because unrelated Godot
work overlapped the samples. There is no clean, authoritative native pair for runtime
checkpoint `76989997` proving either pass or failure; `ba8846ed` is the later documentation
commit that records this blocker.

Consequently:

- it is incorrect to claim that the current fixes have passed release performance;
- it is also incorrect to claim from the old numbers that current HEAD still costs 143 ms;
- the next performance action is measurement in a quiescent environment, not another
  speculative code change.

### 7. Remaining architecture risks

#### P1: `VehicleRun` is an oversized hot orchestrator

`vehicle_run.gd` is 6,503 lines with 251 functions. It owns the physics loop, player,
encounter dispatch, enemies, projectiles, collision, terrain, damage, stage/boss flow,
snapshots, drawing fallback, persistence, capture parsing, and performance lifecycle.

Existing runtime owners reduce some internal work, but `VehicleRun` remains a high-risk
coordination and regression surface. A big-bang rewrite would be worse. Extract only one
measured section at a time behind the current call boundary and lock behavior with the
existing focused validators.

#### P1: overlap-cache rebuild still performs bounded global work

`VehicleSpatialGrid.rebuild_local_overlap_cache()` clears validity/count arrays and
snapshots up to 320 actor slots before scanning only marked owners
(`vehicle_spatial_grid.gd:335-374`). This is bounded and much better than repeated
per-owner discovery, but still O(capacity) per rebuild. It is a candidate only if the
clean current-HEAD profile keeps this owner material.

#### P1: projectile collision remains a large exact path at capacity

The runtime loops up to 360 live projectiles, performs grid segment queries for player
shots, and resolves exact first contact (`vehicle_run.gd:3385-3570`). Historical capacity
attribution placed combat/effects below enemy steering but still material. Preserve exact
collision and optimize query receipts or data layout only after current attribution.

#### P2: retained renderer uploads every active batch per presented physics state

`VehicleCombatRenderer.sync()` rescans inputs, resets all batch counts, and uploads every
batch when a new physics state is presented (`vehicle_combat_renderer.gd:204-233,
1678-1688`). The render path is currently below its limits, so dirty uploads or spatial
batch splitting are not justified yet. Keep this as a measured contingency, not the next
default task.

#### P2: two visual/gameplay coupling leaks remain

- Enemy `projectile_hit_radius` is initialized from `visual_radius`
  (`vehicle_run.gd:901-903`), and the spatial grid uses the maximum of body and projectile
  hit radius (`vehicle_spatial_grid.gd:193-203`). A change to intended visual footprint can
  therefore alter collision candidates and cost. Make the hit radius an explicit gameplay
  contract even when it intentionally equals the visual value.
- Ordinary renderer batches synthesize `actor/<archetype>` instead of consuming the actor
  catalog's `asset` field (`vehicle_combat_renderer.gd:342-354`). This does not cause the
  current stutter, but it makes semantic-ID changes require renderer edits. Let the catalog
  remain the single visual identity owner.

#### P2: cold-load hitch ownership is unmeasured

The current evidence explains sustained frame collapse, not the first frame on which a
texture is requested. Add a one-time load/residency measurement only if users report a
repeatable first-use hitch after frame/physics performance is green.

### 8. 2026-08-08 follow-up: current symptom paths and safe responses

The user still reports stutter, but this task did not produce a valid new timing sample.
The required quiescence preflight found 16 pre-existing Godot processes before the
planned native diagnostic. Starting another recorder would have mixed Cardborne cost with
unrelated editor, test, or capture work, so no performance scenario was started and no
pass/fail claim was made.

One narrow hot-path cleanup was safe without attribution: crates no longer have health
bars, so `VehicleRun` no longer builds or retains `crate_health_overlays` on every combat
presentation snapshot. This removes obsolete recurring dictionary writes. It is a code-
contract cleanup, not evidence that the visible stutter is fixed. The visual workload also
changed: the world-health batch ceiling fell from 50 to 26 instances, hostile projectile
thickness changed only through the existing transform, and a visible Beam Sentinel now
uses two startup planes and three active planes. These bounded changes require the same
clean requalification as any other current workload; historical timing cannot qualify them.

Use the symptom shape to choose the next measurement and response:

| Symptom | Current evidence | Next clean measurement | Safe response if confirmed | Do not do by default |
| --- | --- | --- | --- | --- |
| Sustained slow motion or repeated long frames under dense combat | Historical evidence selected a physics catch-up backlog, led by enemy/grid work; current HEAD is unqualified | Run the active plan's clean native `peak_horde` and `capacity_pressure` pair; compare frame, physics, scheduled-enemy, grid, combat/effects, render CPU, and GPU fields | If grid/scheduling is still material, narrow packed overlap-cache work. If combat/effects is material, reuse projectile query receipts while preserving exact earliest-hit collision | Do not reduce counts, cadence, collision checks, or thresholds |
| One hitch when the first enemies arrive | A manual trace selected synchronous spawn allocation; commit `483cab1f` prewarmed immutable geometry | Record the debug-only manual trace from launch through the first arrival and compare the spawn-allocation owner before and after prewarm | Correct only the named spawn path if it remains material | Do not infer a texture or GPU problem from one visual coincidence |
| One hitch the first time a specific asset or stage appears | Cold load/residency remains unmeasured | Add a one-time resource-load and texture-memory trace around the exact transition | Preload only the demonstrated set during an authored transition, or use `ResourceLoader` threaded loading with an explicit request/poll/retrieval lifecycle | Do not bulk-preload the whole project or move SceneTree work to background threads |
| Isolated spike during projectile or effect bursts | Two historical `combat_and_effects` spikes were retained, but their post-fix recurrence is unknown | Capture a manual trace covering the exact burst and inspect projectile/effect count plus subsystem p95/tail | Reuse bounded receipts or pooled state in the selected owner without changing damage, collision, or visual timing | Do not rewrite the renderer or lower effect/projectile capacity without evidence |
| Cost rises sharply with resolution or beam-heavy scenes while physics stays green | Historical render CPU/GPU was green; the new beam adds bounded transparent overlap | Compare two resolutions and use the Visual Profiler for rendering CPU/GPU only | Reduce proven overdraw or dirty uploads while preserving the exact gameplay corridor and readability contract | Do not treat the Visual Profiler as scripting or physics evidence |
| Native is smooth but built Web stutters | No current built-Web qualification exists | Run the active plan's built-Web peak after native evidence is clean | Isolate Web-specific main-thread, browser, or upload cost while preserving the workload | Do not use native-only success as Web qualification |
| Results vary while other Godot/editor jobs run | This follow-up found 16 pre-existing Godot processes | Repeat only after the environment is quiet and record process isolation with the evidence | Reuse a known project-owned process or wait for quiescence | Do not publish contaminated samples |

Official Godot guidance supports this order: classify and profile the actual bottleneck,
use the Debugger monitors to separate process/physics/render ownership, treat the Visual
Profiler as rendering-only evidence, and use background loading only for demonstrated
blocking loads. Threads and direct servers remain later escalation paths because their
synchronization and SceneTree constraints add correctness risk; they require a separately
approved contract after the existing owners are exhausted.

### 9. Design verdict

The project does have design debt, but not in the form “the assets are different sizes” or
“Godot cannot handle this 2D game.”

- **Visual/media architecture:** broadly appropriate for the current scale. Assets are
  small, semantic ownership is explicit, retained MultiMesh batching is in place, and
  measured render budgets were green.
- **Original simulation architecture:** structurally inefficient at dense counts. Repeated
  neighbor discovery, object-heavy data flow, and recurring snapshot allocation caused a
  physics backlog. This was a real design problem.
- **Current simulation architecture:** directionally sound improvements are present, but
  release performance is unqualified until clean native/Web evidence exists.
- **Responsibility architecture:** still too concentrated in `VehicleRun`; improve it
  incrementally at measured boundaries rather than through a general rewrite.
- **Performance process:** previously allowed task-scoped visual passes and scenario passes
  to sound like a global performance pass. Baselines, claim labels, and environment
  isolation need a durable guard.

No current evidence supports switching engines. The next decision should be based on the
clean current-HEAD result: continue GDScript/data-layout work only if a named owner still
fails; consider native/threaded work only after the existing boundary is exhausted and the
user approves its cost and risk.

## Recommendations

1. **P0 — qualify current HEAD before further optimization.** Run the already specified
   clean native peak/capacity pair only after the external workload is quiet. Do not change
   code first.
2. **P0 — use the new performance policy and guard.** Every future asset or runtime task
   must record its pre-change state and use exact partial-pass labels.
3. **P1 — decide whether production-scale density is intentional.** Stress capacity can
   remain 320/360, but the prior production replay's 249–276 active ordinary enemies should
   be confirmed as desired product behavior. Any reduction is a product change, not a
   hidden optimization.
4. **P1 — if current profiling still points to the grid, narrow snapshot work.** Preserve
   immutable boundary semantics and deterministic nearest-eight ordering; optimize only
   `rebuild_local_overlap_cache()` and its refresh-mask lifecycle.
5. **P1 — if combat/effects remains material, improve projectile query data flow.** Reuse
   query receipts and keep exact first-hit/collision behavior. Do not reduce projectile
   activity.
6. **P1 — reduce `VehicleRun` responsibility one measured section at a time.** Start with
   the highest remaining named subsystem, retain its API and oracle, and avoid a mega
   refactor.
7. **P2 — remove coupling leaks.** Give projectile hit radius an explicit gameplay owner
   and make the renderer consume actor catalog asset IDs. These improve asset-swap safety;
   they are not urgent frame-time fixes.
8. **P2 — measure cold-load hitches separately if they remain.** Record first-use resource
   loads and texture memory at an authored transition; preload only the demonstrated set.
9. **P2 — touch renderer uploads only with render evidence.** Current draw, batch, and
   render CPU/GPU metrics do not justify a renderer rewrite.
10. **P3 — escalate deliberately.** Threads, direct servers, GDExtension, engine changes,
    workload changes, and threshold changes require a new user-approved contract.

## Limitations

- No clean authoritative performance pair exists for current HEAD after the latest packed
  overlap-cache changes.
- Retained JSON under `build/performance/` is ignored local evidence and is not portable
  repository state; durable figures above are corroborated by the active plan/evidence.
- No GPU frame capture, texture-residency trace, or cold-load timing was available.
- The 2026-08-08 follow-up ran focused functional validators and made the narrow combat-
  presentation cleanup described above. It did not start a performance scenario because
  the quiescence preflight failed, and it made no asset changes.
- Hardware-specific conclusions require the same controlled measurements on the intended
  release hardware and Web target.
