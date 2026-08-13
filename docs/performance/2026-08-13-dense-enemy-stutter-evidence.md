---
type: evidence
status: active
owner: BK
created: 2026-08-13
last_reviewed: 2026-08-13
topic: Dense-enemy stutter root-cause analysis
scope: Current Cardborne tracked runtime, retained native and Web evidence, recent performance history, and deployment constraints
source: Repository code and history, retained profiler JSON, GitHub Actions deployment state, prior Codex sessions, and primary technical references
related:
  - ../../.agents/cardborne-performance-engineering-policy.md
  - ../../.agents/2026-08-11-enemy-scale-performance-research.md
  - ../../.agents/cardborne-runtime-architecture-audit.md
  - ./2026-08-13-dense-enemy-architecture-options.md
  - ./2026-08-13-dense-enemy-conclusion-ko.md
---

# Dense-enemy stutter evidence

## Purpose

Determine why Cardborne becomes severely choppy as enemy density rises, distinguish measured
causes from plausible secondary contributors, and establish what is and is not known about the
currently deployed Web build. This document is an evidence report, not a current-HEAD performance
qualification or an implementation contract.

## Executive finding

The established failure is sustained main-thread simulation overload followed by Godot physics
catch-up, not a GPU, texture-size, or draw-call bottleneck. The nonlinear collapse starts near the
point where one 60 Hz physics tick no longer fits within its 16.67 ms wall-clock budget. Godot then
runs multiple physics steps before one rendered frame. In the retained 320-enemy records, the game
completed 3,600 physics ticks but presented only 450 frames over 60 seconds: exactly eight physics
steps per presented frame. The result is a median displayed frame of about 133 ms, or 7.5 FPS.

The most expensive measured owner is ordinary-enemy simulation: scheduling, decision policy,
movement, line-of-sight and local overlap work. Projectile collision and effects are the next
material owner. Presentation and HUD work can amplify a slow frame, but rendering itself remained
green at roughly 0.7-1.0 ms CPU, 1.5-3.1 ms GPU, and about 99-101 draw calls.

The prior two weeks of work were not ineffective. They removed allocations, bounded queries,
introduced cadence lanes, cached immutable values, and improved the stable 320-enemy physics
median by about 8% and p95 by about 11%. Those are real gains, but the remaining gap to the existing
capacity gate is too large for more scalar-expression or small allocation changes to be the main
strategy. A portable data-oriented GDScript migration was therefore implemented and measured. Its
management overhead made the full runtime slower, so the regressive owners were removed rather
than shipped. The remaining performance fix now requires a product or deployment architecture
choice.

## Implementation and final diagnostic outcome

The execution pass started from clean baseline commit `4eb3eef3`. Its eligible 60-second records
measured:

| Scenario | Physics p95 / p99 | Frame p95 / p99 | 1% low | Result |
| --- | ---: | ---: | ---: | ---: | --- |
| `peak_horde`, 276 ordinary | 26.286 / 32.383 ms | 140.505 / 145.688 ms | 6.799 FPS | failed |
| `capacity_pressure`, 320 ordinary | 24.597 / 29.728 ms | 143.240 / 146.266 ms | 6.805 FPS | failed |

The first full GDScript migration combined persistent enemy scheduling, packed enemy state,
incremental overlap rows, packed projectile mirrors and sparse status membership. A valid short
320-enemy sample at `d1982491` measured physics p95 `58.95 ms`; `enemy_scheduled_ordinary` p95 was
`39.44 ms` and overlap p95 was `17.23 ms`. This was a regression, not an acceptable partial result.

Successive same-workload removals established the main costs:

- removing incremental overlap revisions reduced 320-enemy physics p95 to `27.05 ms`;
- removing unused projectile mirrors reduced it to `25.02 ms`;
- a direct same-time baseline recheck at `4eb3eef3` measured `19.37 ms` p95, showing that the
  persistent enemy migration itself still cost about 30% more in the full game.

The regressive enemy, schedule, overlap, projectile and sparse-status migrations were removed.
An experimental immutable presentation frame was also rejected before integration because its
public packed arrays could be mutated by consumers and presentation/rendering was already green.
The retained runtime work is limited to the engagement flow and a bounded runtime-wall broad phase
whose exact collision/LOS narrow phase remains authoritative.

Final clean commit `91ab9968` was checked with a focused validator batch and one valid, focused
5-second warmup + 10-second 320-enemy diagnostic. It measured physics median/p95/p99
`18.218/28.787/34.841 ms`, displayed-frame median/p95/p99
`133.333/143.333/148.510 ms`, and 1% low `6.734 FPS`. Renderer CPU/GPU remained
`0.715/1.562 ms`, draw-call p95 remained `98`, and combat batches remained `38`. The workload was
valid and exact, but the short duration makes it diagnostic rather than authoritative. It failed
the unchanged 6/8 ms capacity physics gate, so the planned authoritative and Web performance runs
were stopped.

## Sources

### Local evidence

- `build/performance/dense-combat/98b39a11-final-count-064.json` through
  `98b39a11-final-count-320.json`
- `build/performance/dense-combat/98b39a11-final-peak_horde-60s.json`
- `build/performance/dense-combat/98b39a11-final-capacity_pressure-60s.json`
- `build/performance/dense-combat/14e8ef29-ablation-decision.json`
- `build/performance/dense-combat/eea6920a-capacity-candidate.json`
- `build/performance/half-scale-continuity/405fd3c1-candidate-peak_horde-60s.json`
- `build/performance/half-scale-continuity/405fd3c1-candidate-capacity_pressure-60s.json`
- `build/performance/half-scale-continuity/b0be0b86-baseline-peak_horde-60s.json`
- `build/performance/half-scale-continuity/b0be0b86-baseline2-capacity_pressure-60s.json`
- `.agents/2026-08-11-enemy-scale-performance-research.md`
- `.agents/cardborne-runtime-architecture-audit.md`
- `docs/reports/2026-08-11-ordinary-enemy-pressure-and-frame-pacing.md`
- `scripts/vehicle/vehicle_run.gd`
- `scripts/enemies/vehicle_enemy_store.gd`
- `scripts/enemies/vehicle_enemy_update_schedule.gd`
- `scripts/combat/vehicle_spatial_grid.gd`
- `scripts/combat/vehicle_projectile_store.gd`
- `scripts/combat/vehicle_status_runtime.gd`
- `scripts/presentation/vehicle_combat_renderer.gd`
- `scripts/performance/vehicle_performance_scenario.gd`
- `scripts/performance/vehicle_performance_recorder.gd`
- `export_presets.cfg`
- `tools/validation/validate_itch_web_release.ps1`
- `.github/workflows/vehicle-run-validation.yml`
- Git history from 2026-07-30 through 2026-08-13
- Bounded Codex session search under `~/.codex/sessions/2026/08/05`, `08/11`, `08/12`
  and `08/13`

### Primary external references

- [Godot 4.7 general optimization](https://docs.godotengine.org/en/4.7/tutorials/performance/general_optimization.html)
- [Godot 4.7 CPU optimization](https://docs.godotengine.org/en/4.7/tutorials/performance/cpu_optimization.html)
- [Godot 4.7 profiler](https://docs.godotengine.org/en/4.7/tutorials/scripting/debug/the_profiler.html)
- [Godot 4.7 Performance API](https://docs.godotengine.org/en/4.7/classes/class_performance.html)
- [Godot Engine physics-step properties](https://docs.godotengine.org/en/4.7/classes/class_engine.html#class-engine-property-max-physics-steps-per-frame)
- [Godot 4.7 physics interpolation](https://docs.godotengine.org/en/4.7/tutorials/physics/interpolation/using_physics_interpolation.html)
- [Godot 4.7 static typing](https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/static_typing.html)
- [Godot 4.7 optimization using Servers](https://docs.godotengine.org/en/4.7/tutorials/performance/using_servers.html)
- [Godot 4.7 MultiMesh](https://docs.godotengine.org/en/4.7/classes/class_multimesh.html)
- [Godot 4.7 thread-safe APIs](https://docs.godotengine.org/en/4.7/tutorials/performance/thread_safe_apis.html)
- [Godot 4.7 using multiple threads](https://docs.godotengine.org/en/4.7/tutorials/performance/using_multiple_threads.html)
- [Godot 4.7 Web export](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html)
- [Godot 4.7 compiling Web templates](https://docs.godotengine.org/en/4.7/engine_details/development/compiling/compiling_for_web.html)
- [Emscripten pthreads](https://emscripten.org/docs/porting/pthreads.html)
- [Emscripten browser runtime model](https://emscripten.org/docs/porting/emscripten-runtime-environment.html)
- [MDN WebGL best practices](https://developer.mozilla.org/en-US/docs/Web/API/WebGL_API/WebGL_best_practices)
- [Chrome DevTools Performance](https://developer.chrome.com/docs/devtools/performance)
- [itch.io HTML5 upload and embedding](https://itch.io/docs/creators/html5)

## Findings

### 1. The failure has a measured density cliff

The short deterministic scaling sweep at `98b39a11` shows a smooth increase in simulation cost,
then an abrupt displayed-frame collapse when the physics p95 crosses the 16.67 ms tick budget.

| Ordinary enemies | Physics median | Physics p95 | Physics p99 | Displayed frame p95 |
| ---: | ---: | ---: | ---: | ---: |
| 64 | 6.14 ms | 8.44 ms | 9.61 ms | 16.67 ms |
| 128 | 10.03 ms | 13.42 ms | 15.67 ms | 22.04 ms |
| 192 | 14.20 ms | 18.85 ms | 21.62 ms | 135.19 ms |
| 256 | 17.07 ms | 25.16 ms | 29.11 ms | 143.17 ms |
| 320 | 17.84 ms | 23.91 ms | 29.09 ms | 144.17 ms |

This matches the reported symptom: the game does not degrade only by a few proportional
milliseconds. Once the simulation falls behind real time, catch-up consumes the render cadence.

Godot exposes a default maximum of eight physics steps per rendered frame. Its documentation warns
that a project appears to slow down when rendering falls below `physics_ticks_per_second /
max_physics_steps_per_frame`. Cardborne's 3,600 physics samples and 450 displayed-frame samples are
the exact signature of that ceiling at 60 Hz.

Changing the ceiling does not remove the work. Raising it can make one displayed frame even longer;
lowering it drops simulation time and changes game behavior. Neither is a root fix.

### 2. Production-density and capacity records both fail

The clean 60-second `98b39a11` records preserve attacks, collision, projectile counts, effects and
fixture counts.

| Scenario | Ordinary enemies | Physics median / p95 / p99 | Displayed frame p95 / p99 | Result |
| --- | ---: | ---: | ---: | --- |
| `peak_horde` | 276 | 15.59 / 22.05 / 27.36 ms | 141.03 / 144.75 ms | Failed |
| `capacity_pressure` | 320 | 18.39 / 26.80 / 32.99 ms | 142.91 / 145.83 ms | Failed |

The 320-enemy case is a capacity stress test, but the authored 276-enemy peak also fails. Reducing
the fixture to an easier count would hide a product problem rather than solve it.

### 3. The latest retained post-camera records do not identify camera scale as the primary cause

Commit `405fd3c1` changed the camera to half scale and expanded the near-simulation range to cover
the visible world. It also changed stage flow, HUD, pressure-fixture behavior and other runtime
paths, so its before/after files are a bundled comparison, not an isolated camera experiment.

| 60-second record | Visible pressure actors | Renderer instances | Physics median / p95 | Frame median / p95 |
| --- | ---: | ---: | ---: | ---: |
| `b0be0b86` peak baseline | 227 | 400 | 18.17 / 42.74 ms | 133.11 / 143.60 ms |
| `405fd3c1` peak candidate | 268 | 539 | 14.84 / 21.04 ms | 69.93 / 137.79 ms |
| `b0be0b86` capacity baseline 2 | 235 | 546 | 19.70 / 26.50 ms | 133.33 / 143.26 ms |
| `405fd3c1` capacity candidate | 273 | 698 | 18.33 / 24.64 ms | 133.33 / 144.44 ms |

The candidate displayed substantially more actors without making the retained physics result
worse. The records therefore do not support camera scale as the main regression. They also do not
prove that the larger near band is free: the commit is confounded, and current code still gives
visible enemies a higher movement cadence. Treat range classification as a secondary measurement
target, not as the current root-cause conclusion.

### 4. Simulation CPU dominates; rendering does not

The authoritative `405fd3c1` capacity record reports:

- physics median/p95: 18.33/24.64 ms;
- enemies and grid p95: 15.30 ms;
- scheduled ordinary enemies p95: 13.15 ms;
- ordinary decision p95: 5.31 ms;
- ordinary motion p95: 4.02 ms;
- local overlap p95: 2.71 ms;
- combat and effects p95: 6.14 ms;
- player projectile path p95: 4.87 ms;
- presentation p95: 6.83 ms;
- HUD p95: 10.03 ms, with a low median of 0.32 ms;
- render CPU/GPU snapshot: 0.73/1.61 ms;
- draw-call p95: 101.

The earlier `98b39a11` capacity record had similarly low render CPU/GPU values and a draw-call p95
near 99. The runtime already uses a retained batched renderer and bounded visual capacities.
Changing art dimensions, adding more MultiMesh use, or moving more nodes directly to
`RenderingServer` is not supported as the first fix.

Presentation and HUD are not free. Their p95 spikes should be addressed after the simulation can
stay within budget, because they reduce headroom and can make a recovered frame less stable. They
do not explain the eight-step catch-up signature on their own.

### 5. Repeated bounded passes are still structurally expensive

The runtime has already replaced naive unbounded scene-node behavior with bounded stores and
packed helper structures. That is useful, but each physics tick still performs several passes over
the same population:

1. encounter aggregates and active counts;
2. a full scheduler rebuild over all enemies;
3. status and activation timers;
4. active-state, boss, generator and critical updates;
5. ordinary due decision and movement work;
6. an overlap snapshot and bounded neighbor search;
7. contact resolution;
8. projectile segment, structure, cover and earliest-hit queries;
9. later radar, minimap and presentation snapshots at lower cadences.

The schedule uses sensible 10 Hz decisions, 30 Hz near motion and 20 Hz far motion, but it rebuilds
its work lists by scanning every enemy at 60 Hz. The overlap cache uses generation stamps and keeps
only eight neighbors, but it snapshots all 320 slots when rebuilt. Exact movement can perform LOS,
safe-path, obstacle and recovery checks for each due actor. Player projectiles can run several
candidate and exact-hit queries for each of up to 240 live shots.

This is why further local expression caching has diminishing returns: the main cost is the number
of hot passes, indirect `EnemyState` object reads, policy calls and repeated query setup.

### 6. The decision path is the strongest measured removable owner

The 320-enemy decision ablation at `14e8ef29` reduced the physics median from about 15.83 ms to
11.42 ms. Historical owner attribution placed ordinary decision near 3.30 ms median and motion near
2.48 ms median before later small optimizations. The current path can perform movement LOS checks,
dynamic structural-wall scans, exact movement attempts and recovery checks for each due actor.

This does not justify deleting AI behavior. It justifies changing how the same decisions are stored,
scheduled and queried.

### 7. Prior marginal work helped but reached diminishing returns

Recent history includes:

- retained batched rendering and bounded minimap/presentation work;
- spatial grid and local steering;
- pooled and capacity-bounded projectile/effect stores;
- decision and motion cadence lanes;
- same-cell and safe-cell motion fast paths;
- scheduled-owner-only overlap work;
- static-cover broadphase and reusable candidate buffers;
- cached immutable movement profiles and precomputed separation;
- more detailed attribution and deterministic pressure fixtures.

From the stable 320-enemy baseline to `eea6920a`, these changes improved physics median by about
8.3% and p95 by about 11.0%. Two smaller scalar/facing experiments were rejected and reverted when
they did not produce a trustworthy improvement. The retained empty-decoy fast path was valid but
too small to change the capacity outcome.

The evidence supports a strategy change, not a conclusion that optimization is impossible.

### 8. Normal manual play and dense load are different regimes

Two retained focused manual traces are useful negative controls:

- `manual-4dec4734-20260805-191909.json`: average 58.31 FPS, physics average 2.78 ms,
  render CPU/GPU average 0.61/1.30 ms, but a 128.94 ms maximum frame and 202 multi-tick
  frames. The first-use spawn allocation hitch was later prewarmed.
- `manual-428a1c40-20260810-232556.json`: average 59.88 FPS, physics average 3.26 ms,
  render CPU/GPU average 0.62/2.50 ms, and only nine multi-tick frames over about 227 seconds.

These traces are diagnostic, not release qualification. They show that the machine and renderer can
run ordinary play near 60 FPS while deterministic dense fixtures remain red. This makes a general
"Godot always stutters on this computer" explanation much weaker and supports density-driven
simulation overload.

### 9. Memory churn, SceneTree scale and physics-node scale are not current primary suspects

The enemy store preallocates 320 `EnemyState` objects and uses indexed membership. Projectile and
effect stores are pooled and capped. One retained capacity record reported about 3.35 MB static
memory growth, 517 nodes and 4,612 objects while passing the lifecycle memory check. This does not
rule out conditional allocations, status dictionaries or later regressions, but it makes
instantiate/free churn and a huge active SceneTree weak first explanations.

The game also implements much collision and movement logic in its own packed spatial grid rather
than as hundreds of independent physics bodies. Direct `PhysicsServer2D` conversion would add
manual RID ownership and query-stall risks without targeting the measured owner.

### 10. The Web result is consistent but not yet release-qualified

The retained `98b39a11` headless Web smoke record was explicitly non-authoritative because the
environment could throttle a headless browser. It nevertheless showed the same shape: about 7.4
median FPS, physics median/p95/p99 near 27/36/42 ms, and frame p95 near 145 ms.

The current tracked runtime contains later gameplay changes through `a1af4287`. No clean native and
published-browser performance pair exists after that commit. Therefore:

- the historical simulation-overload mechanism is established;
- the exact current native and browser cost is not established;
- a real built-Web Chrome trace is still required before claiming the deployed build is fixed.

### 11. Local fixes will transfer to GitHub Pages and itch.io only through the release workflow

The successful GitHub Actions run
[`31661900792`](https://github.com/simpleusername96/cardborne-platformer/actions/runs/31661900792)
built and validated one Web release, published it to itch.io, and deployed the verified Web build to
GitHub Pages. The deployed GitHub Pages URL is
[`simpleusername96.github.io/cardborne-platformer`](https://simpleusername96.github.io/cardborne-platformer/).

A portable GDScript, data-layout, scheduling or query fix made locally will be present in both Web
destinations after it is committed, pushed, and the workflow succeeds. The size of the improvement
can differ because the browser runs WebAssembly/WebGL 2.0 and has a cooperative main-thread event
loop.

The current export contract is deliberately single-threaded and has GDExtension support disabled:

- `export_presets.cfg`: `variant/thread_support=false`;
- `export_presets.cfg`: `variant/extensions_support=false`;
- `validate_itch_web_release.ps1` requires `GODOT_THREADS_ENABLED=false`.

Consequently, a desktop thread or native-library fix does not automatically transfer. Godot's
default Web templates omit GDExtension; Web support requires custom templates built with
`dlink_enabled=yes`. Threaded Web exports require `SharedArrayBuffer` and cross-origin isolation
headers. Those are deployment architecture changes, not local implementation details.

### 12. Session chronology confirms the evidence gap

A bounded search of the prior Codex sessions found the following performance checkpoints:

- 2026-08-05: the manual trace was explicitly treated as diagnostic rather than release
  qualification;
- 2026-08-11: the focused `982fef4c` native pair and an ineligible built-Web payload were reviewed;
  an already active external workload prevented a causal performance claim;
- 2026-08-12: the dense plan metrics and `405fd3c1` half-scale A/B were recorded;
- 2026-08-13: sessions referenced the active plans and prior evidence but did not create a new
  authoritative performance sample.

No session directories were present for 2026-07-30 through 2026-08-01. This is a search gap, not
evidence that no work occurred; Git history covers the implementation chronology for those dates.

### 13. Invalid samples explain why some apparent regressions were not used

The retained evidence set includes explicitly invalid runs with focus loss, concurrent Codex or
external workloads, and headless browser scheduler throttling. One earlier investigation identified
a separate Codex resume process launching Cardborne and unrelated workload children. Those samples
were correctly excluded from causal comparisons.

The latest half-scale A/B records are focused and authority-eligible, but their JSON does not encode
process IDs, system load, VSync state or exact run timestamps. Process isolation comes from the
recorded preflight/report, not from an independently verifiable field in the JSON.

### 14. Current evidence freshness

The code trace began at `a894e0f8`. During this review, the concurrent design session advanced the
branch to `68893e59` with a documentation/artwork probe report. The inspected changes after deployed
commit `b0d4605f` are documentation and artwork-reference assets, so the traced gameplay runtime
still matches the deployed commit. However, the latest clean full dense-combat measurements precede
`a1af4287`; current runtime performance remains unqualified. A later branch head must be checked
again before qualification.

Another active session has untracked visual work under
`docs/design/visual-replacement-workbench/previews/upgrade-artwork-probes-v4/`. This analysis did not
read, edit, stage or include that work. No authoritative performance run was started while that
session and its workload were active.

## Hypothesis ranking

| Rank | Hypothesis | Verdict | Evidence |
| ---: | --- | --- | --- |
| 1 | Enemy decision, movement, LOS and repeated scheduling exceed the physics budget | Established primary cause | Scaling cliff, decision ablation, owner timings, current code trace |
| 2 | Projectile collision and combat effects consume material secondary budget | Established secondary cause | Capacity owner timings and projectile query path |
| 3 | Physics catch-up turns a 20-30 ms tick into 70-145 ms displayed frames | Established amplification mechanism | 3,600 physics vs 450 frame samples and Godot's eight-step ceiling |
| 4 | HUD/presentation spikes reduce remaining headroom | Plausible secondary contributor | Low medians but material p95 spikes; render remains low |
| 5 | Half-scale camera and larger visible-near band increase cost | Plausible, not isolated | More visible actors; bundled comparison did not regress physics |
| 6 | Recent active-recharge/status paths regressed current HEAD | Unmeasured risk | Added after latest clean full baseline; conditional dictionary/string work exists |
| 7 | GPU, draw calls or asset size cause the sustained collapse | Rejected as primary | Render CPU/GPU and draw calls remain low at capacity |
| 8 | Node creation/free churn causes the sustained collapse | Weak current hypothesis | Stores are preallocated/pooled and lifecycle memory gate passes |
| 9 | OS, browser, driver or shader compilation is the root cause | Rejected as sole cause | Deterministic native scaling reproduces by enemy count; these may still add hitches |

## Recommendations

1. Do not repeat the rejected GDScript packed/persistent migration without a new causal hypothesis
   and an isolated kernel benchmark that clears a material trend gate before live integration.
2. Choose one explicit next architecture: exact simulation in a Web-capable GDExtension, exact
   simulation at a lower supported density/cadence, or exact near/engaged simulation plus a virtual
   far reserve.
3. Prefer the virtual far-reserve option for the current itch.io/Web product: keep visible and
   engaged combat exact, then use the new engagement director to materialize distant reserve actors
   into varied front/side approaches. This is a product-truth change and requires user approval.
4. If exact individual truth for all 320 actors is mandatory, prototype the dominant pure-data loop
   behind a GDExtension API and budget the custom Web template and deployment validation together.
5. Preserve the existing exact fixtures as comparison evidence. Do not weaken thresholds or relabel
   a changed workload as a performance pass.
6. Keep renderer/HUD work out of the next performance pass until profiling shows that the already
   green presentation path became dominant.

The compared architectures and a migration sequence are in
`2026-08-13-dense-enemy-architecture-options.md`.

## Limitations

- A new eligible 60-second baseline and a valid final 10-second native diagnostic were executed.
  The final diagnostic is not an authoritative 60-second release qualification.
- No final built-Web trace was run because the native capacity gate failed first. The deployed Web
  build therefore remains unqualified and should be assumed unfixed.
- The half-scale comparison changes several systems at once; it cannot isolate camera/range cost.
- The retained Web smoke run was headless and non-authoritative. It supports a hypothesis but does
  not qualify a published browser build.
- Subsystem timers have instrumentation overhead and are sampled on a stride. They are suitable for
  ranking owners, not for adding all medians into an exact frame total.
- Official documentation establishes engine and platform constraints; expected gains from each
  proposed rewrite remain estimates until measured in Cardborne.
