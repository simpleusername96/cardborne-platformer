---
type: evidence
status: archived
owner: BK
created: 2026-07-23
last_reviewed: 2026-07-29
topic: Vehicle runtime performance stabilization
scope: Implemented runtime boundaries, deterministic workload evidence, validation, and remaining release limits
source: Git commit 1c7a2b0 and the repository validators named below
related:
  - ./vehicle-performance-architecture-audit.md
  - ./execplans/2026-07-29-horde-foundation-recovery-and-acceptance.md
  - ../docs/product/vehicle_game_spec.md
---

# Vehicle Runtime Performance Stabilization Evidence

## Purpose

Record what the 2026-07-23 stabilization actually changed, what was verified,
what the measurements showed, and which release claims remained unproven. This
document is retained as the 76-enemy performance baseline; the 2026-07-29
continuous-horde evidence is the current implementation companion.

## Sources

- Current repository implementation and focused validators.
- Local result payloads under ignored `build/performance/`, especially
  `final2-current.log`, `final4-current.log`, `final4-throughput.json`, and
  `post-ui-current.json`.
- Built Web export and rendered `1280x720` inspection performed during this
  implementation pass.
- [Godot general optimization](https://docs.godotengine.org/en/stable/tutorials/performance/general_optimization.html),
  [CPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/cpu_optimization.html),
  [data preferences](https://docs.godotengine.org/en/stable/tutorials/best_practices/data_preferences.html),
  [custom drawing](https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html),
  [CanvasItem](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html),
  [performance monitors](https://docs.godotengine.org/en/stable/classes/class_performance.html),
  [RenderingServer](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html),
  [jitter and stutter](https://docs.godotengine.org/en/stable/tutorials/rendering/jitter_stutter.html),
  and the official
  [Bullet Shower demo](https://github.com/godotengine/godot-demo-projects/tree/master/2d/bullet_shower).

## Findings

### Root cause

The lag was credible despite flat graphics. The pre-change runtime retained dead
enemy dictionaries, repeated projectile-by-enemy and secondary-by-enemy scans,
rebuilt high-count procedural drawing, and reconstructed broad HUD payloads.
The old headless script excluded complete rendered orchestration and therefore
could not establish smooth play.

### Implemented runtime

| Concern | Current implementation |
| --- | --- |
| Enemies | 128 preallocated typed states, live-only store, O(1) ID map, deferred swap retirement |
| Projectiles | Separate fixed pools of 240 player and 120 hostile shots; 24 hostile slots reserved for bosses |
| Experience | 192 preallocated typed shards with bounded reuse |
| Dynamic queries | Reused `35x22` uniform grid at 160 world pixels; exact geometry after broadphase |
| Static queries | Cached immutable floor geometry, one run-scoped eight-cover broadphase, and a 320-pixel crate grid |
| Presentation | 49 retained MultiMesh families with prebuilt flat-color meshes, six shape-distinct projectile-affinity trails per team, one exact thin danger-ring family, fixed visible counts, and one three-family elemental-status batch |
| HUD | Dirty channels; static minimap once, radar at 10 Hz, action state at 20 Hz, guidebook on invalidation |
| Cadence | Critical combat at 60 Hz; ordinary decisions 10 Hz; non-committed motion 30/20 Hz; far projectiles, grid, ordinary XP attraction, and repeated effects 30 Hz; the bounded 0.65-second global XP recall runs at 60 Hz |
| Measurement | Four deterministic scenarios, focus/visibility/scheduler qualification, complete frame distributions, subsystem samples, counts, draw calls, render timing, and memory |

Pool exhaustion is explicit and counted. Ordinary hostile shots cannot consume
the boss reserve. Performance instrumentation is inactive in ordinary play,
and detailed subsystem timing is sampled every seventh physics tick to avoid
aliasing with the six ordinary-decision buckets.

### Validation

- Typed-store, spatial-grid, projectile-pool, retained-renderer, HUD presenter,
  experience, five-secondary, stage, boss, upgrade, settings, localization,
  guidebook, campaign, and integrated run validators pass.
- The exhaustive layout gate passes all 1,296 cover masks and 256 complete
  seeded layouts; distributed-spawn, hull-feedback, and independent elemental
  stack validators also pass.
- Deterministic setup reaches the requested counts for `current_pressure`,
  `capacity_pressure`, `lifecycle_pressure`, and `boss_pressure`.
- Lifecycle validation performs 300 retire/reuse cycles before saturation and
  continues churn without stale live IDs or cap growth.
- Production Web export and a built `1280x720` pressure scene rendered without a
  console error during this pass.

### Bounded measurements

These are diagnostic implementation snapshots, not a completed release matrix.
Early results came from dirty implementation worktrees. The final two seeded
field regressions came from clean commit `1c7a2b0`. Embedded threshold objects
produced before the final gate correction used a looser draw-call limit; the
values below are judged against the active plan instead.

| Result | Qualification | Key observations |
| --- | --- | --- |
| `final2-current.log`, native current pressure, 10 s warmup + 60 s sample | Foreground and duration-qualified; earlier in the implementation lineage | 76 enemies, 140/72 player/hostile shots; frame median 16.67 ms, p95 16.67 ms, p99 27.91 ms, 1% low 32.67 FPS, three consecutive frames over 33.3 ms; physics p95 7.26 ms; presentation p95 3.48 ms; draw-call p95 254 |
| `final4-current.log`, latest full current-pressure sample | Disqualified because 3,362 of 3,388 sampled frames were unfocused | Scenario counts valid; frame median 16.67 ms, p95 23.63 ms, p99 32.21 ms; physics p95 9.27 ms; presentation p95 4.48 ms; draw-call p95 254 |
| `final4-throughput.json`, latest current-pressure 120 FPS probe, 2 s + 10 s | Short and partly unfocused; CPU-throughput diagnostic only | Frame median 8.33 ms, p95 17.26 ms; physics p95 9.24 ms; presentation p95 4.46 ms; zero consecutive frames over 33.3 ms |
| Built Web current-pressure probe | Disqualified by automated browser scheduling | Counts valid at 76 enemies and 140/72 shots; the rendered scene, HUD, projectiles, and effects were visually present |
| `post-ui-current.json`, final focused current-pressure 120 FPS smoke, 2 s + 10 s | Foreground and scheduler-qualified, but intentionally too short for release authority | 76 enemies and 212 total projectiles; frame median/p95/p99 8.33/8.33/9.09 ms; physics p95 6.23 ms; presentation p95 2.97 ms; draw-call p95 165; every applicable threshold check passed |
| `2026-07-24-clean/current-pressure-30s.json`, seeded-layout current pressure, 10 s + 30 s | Clean commit `1c7a2b0`; focused and scheduler-qualified implementation regression; non-authoritative only because it is shorter than 60 s | 76 enemies, 140/72 player/hostile shots, eight runtime covers; frame median/p95/p99 16.67/16.67/16.67 ms; physics p95/p99 4.98/6.06 ms; presentation p95/p99 1.76/2.33 ms; draw-call p95 161; no frame over 20 ms |
| `2026-07-24-clean/boss-pressure-30s.json`, seeded-layout boss pressure, 10 s + 30 s | Clean commit `1c7a2b0`; focused and scheduler-qualified implementation regression; non-authoritative only because it is shorter than 60 s | 77 enemies including one boss, 140/100 player/hostile shots, eight runtime covers; frame median/p95/p99 16.67/16.67/16.67 ms; physics p95/p99 5.90/7.36 ms; presentation p95/p99 2.33/3.04 ms; draw-call p95 164; one 22.04 ms frame and no frame over 25 ms |
| `2026-07-24-attack-telegraph-current.json`, affinity-telegraph current pressure, 2 s + 10 s | Dirty implementation smoke; continuously unfocused and intentionally too short for authority | Counts valid at 76 enemies and 140/72 shots; 49 retained batches; frame median/p95/p99 16.67/16.67/18.06 ms; physics p95 7.11 ms; presentation p95 2.99 ms; draw-call p95 162; no frame over 33.3 ms |
| `2026-07-24-attack-telegraph-boss.json`, affinity-telegraph boss pressure, 2 s + 10 s | Dirty implementation smoke; continuously unfocused and intentionally too short for authority | Counts valid at 77 enemies including one boss and 140/100 shots; 49 retained batches; frame median/p95/p99 16.67/16.67/18.06 ms; physics p95 7.31 ms; presentation p95 3.17 ms; draw-call p95 165; no frame over 33.3 ms |

The final short smoke meets the user's current development stop condition:
ordinary maximum pressure remains functional and has enough measured headroom
to continue game-design work. Minimap static polygons and threat-radar arcs now
use one retained mesh each, reducing draw calls from roughly 254 to 165 at p95.
The latest full-duration sample is still non-authoritative because focus was
lost, so no release guarantee is claimed.

The 2026-07-24 seeded-field regression keeps that development condition under
both current and boss pressure. Both clean foreground samples held a 16.67 ms
frame p99. Current pressure had no post-warmup frame above 20 ms; boss pressure
had one 22.04 ms frame and none above 25 ms. Neither sample rejected an actor
or projectile, and draw-call p95 stayed below 165. These results cover the new
runtime cover broadphase and retained status batches, but their 30-second
duration remains development evidence rather than release certification.

The later attack-telegraph smoke confirms that six affinity trail families per
team plus one exact danger-ring family raise the retained family count from 38
to 49 without exceeding the revised ceiling of 50 or the 200 draw-call limit.
Both short samples kept a 16.67 ms frame p95 with no frame above 33.3 ms. They
were continuously unfocused and are recorded only as workload and regression
diagnostics, not as evidence that replaces either clean 30-second sample.

## Recommendations

Do not repeat the release matrix while the game design is still changing. Once
the gameplay/content contract reaches a release-candidate state:

1. Run all four scenarios three times in a continuously foreground native
   `1280x720` window, then repeat the required native `2560x1600` and production
   Web `1280x720` combinations from one clean commit.
2. Run `lifecycle_pressure` for a full ten-minute measured interval and retain
   memory, identity, pool, node, and live-count evidence.
3. Use the then-current dominant subsystem if a gate fails; do not reduce
   accepted load to pass.
4. Extract enemy/projectile policy and the bounded low-count overlay from
   `VehicleRun` only as a measured optimization or a separately accepted
   maintainability pass.

## Limitations

- Automated focus and Web scheduler behavior make several local samples
  non-authoritative; the recorder now labels those conditions explicitly.
- The latest code has not completed the three-run platform/resolution matrix or
  the ten-minute soak.
- The 2026-07-24 current/boss regressions are focused 30-second samples from
  clean commit `1c7a2b0`, but are deliberately non-authoritative because the
  release gate requires at least 60 seconds.
- The draw-call ceiling passes the final focused short smoke, but strict
  full-duration frame-tail gates are not release-qualified.
- This evidence proves bounded ownership and functional behavior, not unlimited
  headroom for future content.
