---
type: evidence
status: active
owner: BK
created: 2026-08-11
last_reviewed: 2026-08-11
topic: Dense-enemy performance research and Cardborne bottleneck selection
scope: Native and Web five-stage runtime at high ordinary-enemy occupancy
source: Current code inspection, committed profiler evidence, and primary technical references
related:
  - ./cardborne-performance-engineering-policy.md
  - ./cardborne-runtime-architecture-audit.md
  - ./execplans/2026-08-11-dense-combat-progression-and-run-completion.md
  - ../docs/reports/2026-08-11-ordinary-enemy-pressure-and-frame-pacing.md
---

# Dense-enemy performance research

## Purpose

This is agent-only working evidence. It separates measured Cardborne facts from broad
computer-science options, then selects the smallest sequence that can improve dense combat
without hiding the problem by reducing authored enemies, attacks, collision truth, or visual
quality.

## Sources

### Local sources

- `build/performance/ordinary-enemy-pressure/66f78582-capacity_pressure-60s.json`
- `.agents/cardborne-performance-engineering-policy.md`
- `.agents/cardborne-runtime-architecture-audit.md`
- `docs/reports/2026-08-11-ordinary-enemy-pressure-and-frame-pacing.md`
- `scripts/vehicle/vehicle_run.gd`
- `scripts/enemies/vehicle_enemy_update_schedule.gd`
- `scripts/vehicle/vehicle_spatial_grid.gd`
- `scripts/vehicle/vehicle_reinforcement_facility_runtime.gd`
- `scripts/encounters/vehicle_encounter_runtime.gd`
- `scripts/presentation/vehicle_combat_renderer.gd`
- `scripts/ui/vehicle_hud_presenter.gd`

The only current clean, authoritative capacity record is commit `66f78582`. It is valid
evidence about the remaining bottleneck shape, but it is not release qualification for the
current HEAD. A new clean baseline is required before making a current performance claim.

### External primary or original references

- [Godot 4.7: General optimization tips](https://docs.godotengine.org/en/4.7/tutorials/performance/general_optimization.html)
- [Godot 4.7: Debugging and profilers](https://docs.godotengine.org/en/4.7/tutorials/scripting/debug/index.html)
- [Godot 4.7: ObjectDB profiler](https://docs.godotengine.org/en/4.7/tutorials/scripting/debug/objectdb_profiler.html)
- [Godot 4.7: Optimization using MultiMeshes](https://docs.godotengine.org/en/4.7/tutorials/performance/using_multimesh.html)
- [Godot: Optimization using Servers](https://docs.godotengine.org/en/latest/tutorials/performance/using_servers.html)
- [Godot: Using multiple threads](https://docs.godotengine.org/en/stable/tutorials/performance/using_multiple_threads.html)
- [Godot: Exporting for the Web](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)
- [Box2D: Dynamic tree](https://box2d.org/documentation/group__tree.html)
- [Gaffer on Games: Fix Your Timestep](https://gafferongames.com/post/fix_your_timestep/)
- [Azure Architecture Center: Queue-Based Load Leveling](https://learn.microsoft.com/en-us/azure/architecture/patterns/queue-based-load-leveling)

Godot's central advice is to identify the largest measured bottleneck, optimize it, and
measure again. It also calls out data locality, compact storage, precomputation, and moving
work out of inner loops. Box2D documents broad-phase spatial indexing as a way to reduce the
set examined by geometric queries. The fixed-timestep reference explains why simulation
work that takes longer than simulated time creates a catch-up spiral. Queue load-leveling is
not a game-specific technique, but its producer/consumer rule transfers directly: a burst
can be buffered only when average production does not exceed bounded consumption.

## Findings

### 1. What the committed measurement proves

The exact capacity workload contains 320 enemies, 240 player projectiles, 120 hostile
projectiles, 96 effects, and 191 XP shards at `1280x720`.

| Metric | Median | p95 | Gate |
| --- | ---: | ---: | ---: |
| Display frame | 133.333 ms | 142.633 ms | p95 <= 18 ms |
| Recorded physics | 19.077 ms | 24.768 ms | capacity p95 <= 6 ms |
| Engine physics | 24.832 ms | 32.658 ms | diagnostic |
| Engine process | 15.371 ms | 21.246 ms | diagnostic |
| Render CPU | 0.971 ms observed | - | diagnostic |
| Render GPU | 3.143 ms observed | - | diagnostic |
| Draw calls | - | p95 99 | p95 <= 200 |

The sample advances 3,600 physics ticks during only 450 displayed frames. That is exactly
eight fixed physics steps per displayed frame, the configured catch-up ceiling. The game is
not merely drawing slowly: simulation is behind, repeated catch-up increases CPU demand,
and the renderer receives a new state only after that work. This matches the general
fixed-timestep “spiral of death” failure mode.

The recorded subsystem distribution is:

| Subsystem | Median | p95 | Interpretation |
| --- | ---: | ---: | --- |
| Enemies and grid | 11.750 ms | 15.307 ms | dominant physics owner |
| Scheduled ordinary enemies | 9.428 ms | 12.443 ms | dominant named child |
| Ordinary due work | 7.258 ms | 9.497 ms | decision/movement/attack work, not scheduler scanning |
| Overlap cache | 1.852 ms | 2.661 ms | material bounded full-capacity work |
| Combat and effects | 4.391 ms | 5.566 ms | second simulation owner |
| Player and rewards | 1.844 ms | 4.393 ms | material tail cost |
| Presentation | 4.624 ms | 6.010 ms | secondary CPU owner |
| HUD | 0.171 ms | 9.542 ms | low median, intermittent tail |

The already optimized renderer uses retained batches and MultiMesh-style bounded storage.
The draw-call and render timings are green. Replacing art, reducing resolution, removing
effects, or adding another renderer is therefore unsupported as the first fix.

### 2. How cost grows with enemy count

The runtime stores enemies in fixed-capacity arrays, but “bounded” is not the same as
“cheap.” Several owners independently repeat O(N) work during the same physics tick:

1. encounter admission scans active mobile enemies and active attack families;
2. pressure snapshots scan active enemies;
3. the enemy scheduler rebuild scans the entire store;
4. alive/status processing scans again;
5. overlap-cache rebuild snapshots and clears capacity-sized storage;
6. contact resolution scans active enemies;
7. the reinforcement facility scans all enemies to count its own children and asks for
   another full active count;
8. presentation sync scans the enemy store after the physics serial changes;
9. radar/minimap scan at 5 Hz, although their visible output is bounded.

Each individual scan is linear. Their sum is still O(N), but the constant is the number of
passes and the work performed inside each pass. In addition, each due ordinary enemy can
perform movement policy, route sampling, and line-of-sight checks. The static line-of-sight
helper loops every runtime blocker; standoff movement can request it more than once. This
is O(A * B) for A due actors and B blockers, even though neither loop looks like an obvious
all-pairs enemy algorithm.

Attacks create a second scaling path. More attackers produce more projectile integration,
segment queries, hit candidates, effects, audio/feedback, and damage receipts. Projectile
stores have caps, so memory is bounded, but a full store still consumes its bounded maximum
each tick. Dense scenes also make spatial queries return more candidates.

### 3. Broad solution catalogue

| Technique | General CS idea | Cardborne fit | Main risk | Rank now |
| --- | --- | --- | --- | --- |
| Reuse one frame snapshot | compute once, share immutable result | active counts, families, carrier counts | stale data if ownership is vague | high |
| Incremental counters | maintain aggregates on state transition | active cap and facility children | missed transition corrupts count | high, with assertions |
| Spatial broad phase | query a small candidate region before exact checks | static blocker LOS, nearby actors | maintenance overhead; bad cells can regress | high for measured LOS |
| Time slicing | spread non-urgent work across fixed ticks | ordinary decisions already do this | stale decisions or unfair attacks | refine only |
| Priority scheduling | preserve critical work, defer cosmetic work | effects/audio/HUD, never damage truth | visible inconsistency | medium |
| Load leveling | queue bursts and consume at a fixed rate | spawn construction/prewarm and nonessential feedback | backlog grows if average demand is too high | diagnostic/secondary |
| Object/scratch pooling | reuse memory, avoid allocation/GC | receipts, query buffers, effects | pools add complexity; many already exist | medium |
| Structure of Arrays / packed data | contiguous data and linear access | hot actor fields or query snapshots | invasive GDScript rewrite | later |
| Dirty/generation stamps | avoid clearing whole buffers | overlap cache rows and marks | wrap/reset correctness | high if cache stays material |
| Memoization | cache repeated pure results | static LOS cells/cover candidates | invalidation with destructibles | high after crate removal |
| Admission control | cap production to sustainable service rate | nonessential VFX/audio events | cannot discard authored enemies/attacks | narrow only |
| Level of detail | lower update rate with distance/importance | offscreen presentation, distant movement | gameplay changes and dash surprises | only after proof |
| SIMD/native extension | lower per-element CPU cost | huge packed simulations | new dependency/build/Web complexity | last resort |
| Worker threads | parallel independent data work | pure snapshots only | Godot API thread safety, sync cost, Web headers | last resort |
| RenderingServer/PhysicsServer | lower-level engine API | very large Node populations | current actors are already data-oriented; renderer is green | reject now |

### 4. Beginner checks that are easy to miss

These checks are intentionally simple. They prevent a large rewrite when one repeated call
or test condition is the real problem.

- Reproduce with the same seed, stage, window size, build, and actor counts. “It feels
  slower” across different encounters is not comparable evidence.
- Record process, physics, object/node count, draw calls, collision pairs, render CPU, and
  render GPU together. FPS alone cannot identify the owner.
- Double actors from N to 2N. About 2x CPU suggests linear work; near 4x suggests a hidden
  pairwise or nested query; a sudden cliff suggests a cap, cache, allocator, or catch-up
  threshold.
- Run diagnostic ablations separately: AI decisions off, attacks/projectiles off,
  presentation off, and effects/audio off. Do not ship these toggles as fixes.
- Profile a production-style build. Editor, debug checks, browser developer tools, and
  unrelated Godot/browser processes can contaminate timing.
- Look inside the hottest named section. A low-cost scheduler scan does not mean scheduled
  work is cheap; Cardborne's `ordinary_due` result demonstrates this.
- Search for allocation inside loops: new Dictionaries/Arrays, string formatting, repeated
  snapshots, sort/filter/map, and signal/callable construction.
- Search for repeated global scans and queries whose result could be owned once.
- Avoid increasing physics tick rate to make the game “smoother.” When simulation already
  misses budget, that increases demanded work and can worsen catch-up.
- Do not add threads before proving a parallel region is large enough to exceed dispatch,
  copying, locking, and synchronization cost.

### 5. Candidate ablation and scaling matrix

The next clean profiling checkpoint should run one deterministic native scaling sweep at
64, 128, 192, 256, and 320 live enemies, then stop. Each point needs a short warmup and a
fixed sample duration. The sweep records the existing named sections and these new debug-
only sub-timers:

- ordinary movement focus and policy;
- static blocker line-of-sight;
- dynamic cover line-of-sight;
- pursuit-field sampling;
- attack admission/commit;
- repeated active/family/facility count scans;
- overlap snapshot, row clear/mark, and candidate collection;
- projectile integration, spatial query, hit resolution, and effect feedback.

Then run at most four same-count diagnostic ablations: ordinary decision disabled,
hostile/player attacks disabled, presentation disabled, and overlap avoidance disabled.
The stopping condition is a named owner that is material and scales with N, or evidence
that current instrumentation cannot distinguish the owner. “Material” means median at
least 1 ms or p95 at least 2 ms at capacity and at least 10% of recorded physics time.

### 6. Executed scaling, ablation, and attribution evidence

The diagnostic matrix was executed on the exact same fixed workload, seed, viewport, and
enemy-count override. The override is capacity-only and does not change release gameplay.
Samples use a five-second warmup and ten-second recording window. Raw JSON and logs are
under `build/performance/dense-combat/`; they are local generated evidence and are not
committed.

The first count sweep at instrumentation commit `14e8ef29` was:

| Enemies | Physics median | p95 | p99 | Enemies/grid median | Decision median | Combat median | Presentation median |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 64 | 6.047 ms | 8.043 ms | 10.094 ms | 2.006 ms | 0.468 ms | 3.249 ms | 2.089 ms |
| 128 | 9.125 ms | 14.457 ms | 16.180 ms | 4.210 ms | 1.176 ms | 3.612 ms | 2.822 ms |
| 192 | 13.599 ms | 22.418 ms | 26.716 ms | 7.459 ms | 2.071 ms | 4.069 ms | 3.512 ms |
| 256 | 18.590 ms | 25.711 ms | 30.005 ms | 11.384 ms | 3.033 ms | 4.488 ms | 4.859 ms |
| 320 | 20.927 ms | 28.565 ms | 33.587 ms | 13.364 ms | 4.278 ms | 4.535 ms | 5.093 ms |

The 320 point was contaminated by transient system load, so it is not the optimization
baseline. Three repeated 320-enemy runs after movement attribution at `c94c6509` were stable:

| Repeat | Physics median | p95 | p99 |
| ---: | ---: | ---: | ---: |
| 1 | 15.555 ms | 20.061 ms | 23.487 ms |
| 2 | 15.837 ms | 20.472 ms | 24.154 ms |
| 3 | 15.828 ms | 20.592 ms | 24.193 ms |

Repeat 3 is the comparison baseline. Its named medians were enemies/grid `10.629 ms`,
decision `3.304 ms`, motion `2.480 ms`, and overlap `1.610 ms`. Movement intent,
smoothing, and collision were `0.595/0.719/0.279 ms`.

The four 320-enemy diagnostic ablations selected the work owners:

| Ablation | Physics median | p95 | p99 | Interpretation |
| --- | ---: | ---: | ---: | --- |
| ordinary decision off | 11.419 ms | 15.069 ms | 18.032 ms | largest removable branch |
| attacks off | 16.023 ms | 24.010 ms | 29.316 ms | combat is material but secondary |
| overlap off | 20.483 ms | 28.319 ms | 33.414 ms | smaller than decision branch |
| presentation off | 20.934 ms | 28.085 ms | 32.697 ms | does not explain physics scaling |

Presentation was therefore rejected as the first fix. Ordinary decision/movement was the
primary owner, with projectile combat selected after movement improvements.

### 7. Implemented optimization sequence and measured effect

Each step preserved all 320 enemies, projectile/effect capacities, exact hit tests, attack
truth, visual assets, and draw topology.

| Commit | Change | Physics median | p95 | Selected child result |
| --- | --- | ---: | ---: | --- |
| `ad64cfdd` | reuse frame active/family aggregates, event-owned facility child count, static-cover broad phase, generation-stamped overlap rows | 15.511 ms | 20.435 ms | facility rescan removed; overlap 1.423 ms |
| `ca80425a` | cache immutable enemy movement profiles | 14.971 ms | 19.219 ms | grid 9.775; decision 3.140; motion 2.274 ms |
| `92b449a0` | align ordinary facing refresh with scheduled motion | 14.935 ms | 19.154 ms | active-state loop 0.443 -> 0.072 ms |
| `17069ceb` | precompute bounded exact separation in the spatial grid | 14.570 ms | 18.962 ms | smoothing 0.664 -> 0.267 ms |
| `1db38892` | repair projectile timer attribution and split zones/effects | 14.591 ms | 18.501 ms | player projectile 2.719; hostile 0.591 ms |
| `793e3bf9` | split projectile cover and structure query timers | 14.700 ms | 18.619 ms | cover 1.103; structure 0.487; candidates 1.019 ms |
| `eea6920a` | reuse exact-order projectile cover candidates and remove per-shot empty receipt allocation | 14.517 ms | 18.323 ms | cover 1.066 ms |

Against stable baseline repeat 3, current candidate `eea6920a` reduces recorded physics
median from `15.828` to `14.517 ms` (**8.3%**) and p95 from `20.592` to `18.323 ms`
(**11.0%**). This is a real same-workload improvement, but it is not release qualification.
The existing capacity gate is p95 `<=6 ms` and p99 `<=8 ms`; the candidate remains far above
it. The next largest measured combat owner is the player-projectile route, particularly
cover and spatial-candidate queries. Further changes require another bounded evidence step,
not count reduction or gameplay degradation.

## Recommendations

### Selected resolution sequence

1. **Refresh evidence first.** Commit the functional bug fixes separately, reach a clean
   checkpoint, confirm process quiescence, then capture the native scaling/ablation matrix.
   Do not claim the historical `66f78582` run as current qualification.
2. **Remove redundant ownership scans.** Reuse scheduler/frame aggregates for active count
   and attack families. Give the reinforcement runtime an incremental live-child count,
   updated only on accepted spawn and child defeat/retirement, with a debug reconciliation
   assertion. This removes obvious repeated O(N) work without changing enemy behavior.
3. **Fix the selected ordinary hot path.** If LOS/movement is material by the rule above,
   build a reusable static-blocker broad phase and query only candidate cells before exact
   segment tests. Crate removal makes this easier because moving/destructible cover no longer
   shares the path. Cache the result only for the existing decision interval; attacks still
   perform their required exact commitment check.
4. **Remove full-capacity overlap clearing.** If overlap remains material, replace full row
   clear/snapshot work with generation stamps and active-row reuse. Preserve the exact
   candidate cap and separation behavior.
5. **Optimize combat/effects next only if selected.** Reuse projectile hit receipts and
   effect feedback records, then remeasure. Do not lower projectile collision accuracy or
   silently drop player damage.
6. **Treat presentation as a separate branch.** Only change HUD/presentation when current
   render/process evidence selects it. Keep the retained renderer, assets, effect topology,
   and draw-call gate.
7. **Keep threads, Servers, GDExtension, ECS rewrites, and new dependencies out of this
   contract.** They require a new evidence-backed design and explicit authority, especially
   because the default Web export is single-threaded and threaded Web exports require
   cross-origin isolation.

### Non-negotiable performance invariants

- Do not reduce stage quotas, active caps, enemy roles, attack concurrency, collision
  accuracy, telegraph duration, or authored visual quality to make the profiler green.
- Do not let a queue grow without a bound. Spawn leveling may spread object initialization,
  but required actors must still arrive within the authored arrival window.
- Never defer contact, damage, projectile collision, or committed attack truth.
- Compare identical scenario counts and seeds. A faster run with fewer actors is invalid.
- The capacity release gates remain the existing recorder limits: scenario-valid exact
  counts, p95 simulation <= 6 ms, p99 <= 8 ms, frame p95 <= 18 ms, frame p99 <= 25 ms,
  median >= 59 FPS, 1% low >= 55 FPS, p95 draw calls <= 200, and no more than one
  consecutive frame over 33.3 ms.

## Limitations

- The short 5/10-second diagnostic samples select owners and compare candidates; they do
  not replace the authoritative 60-second peak/capacity native and Web release scenarios.
- The historical `66f78582` record and current short samples have different code and sample
  windows, so only same-series count/ablation/candidate comparisons are valid.
- Static inspection cannot quantify cache locality, allocator stalls, browser JavaScript/
  WebAssembly overhead, driver behavior, or operating-system scheduling.
- Native gates and Web playability are separate. The browser build needs its own smoke and
  frame-pacing evidence, but its single-thread constraints must not be used to weaken the
  native deterministic workload.
- The selected sequence is deliberately conditional on named evidence. If the refreshed
  profile selects a different owner, stop and revise the execution contract before making
  an unrelated rewrite.
