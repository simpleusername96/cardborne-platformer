---
type: evidence
status: active
owner: BK
created: 2026-08-13
last_reviewed: 2026-08-14
topic: Architecture options for eliminating dense-enemy stutter
scope: Behavior-preserving and product-changing options for native and Web Cardborne runtimes
source: Dense-enemy evidence, current code ownership, and official Godot, Emscripten, browser, and itch.io documentation
related:
  - ./2026-08-13-dense-enemy-stutter-evidence.md
  - ./2026-08-13-dense-enemy-conclusion-ko.md
  - ../../.agents/cardborne-performance-engineering-policy.md
  - ../../.agents/execplans/2026-08-11-dense-combat-progression-and-run-completion.md
---

# Dense-enemy architecture options

## Purpose

Compare small, structural and radical ways to remove Cardborne's dense-enemy stutter while keeping
native and Web deployment honest. This is an option study. It does not authorize a dependency,
threading, custom engine-template, fixed-timestep or gameplay-density change.

## Sources

- `2026-08-13-dense-enemy-stutter-evidence.md` and its retained profiler JSON sources
- Current dense runtime owners under `scripts/vehicle`, `scripts/enemies`, `scripts/combat`,
  `scripts/presentation` and `scripts/performance`
- `.agents/cardborne-performance-engineering-policy.md`
- Official Godot 4.7 optimization, profiling, packed-data, Server, MultiMesh, thread and Web export
  documentation linked from the evidence report
- Official Emscripten pthread/runtime, MDN WebGL and Chrome Performance documentation linked from
  the evidence report

## Findings

The measured gap justified a new dense-simulation boundary, but the first portable typed-GDScript
migration failed its live trend gate. Persistent queue maintenance, compatibility synchronization
and revision-driven overlap caching cost more than the object scans they replaced in Cardborne's
current full runtime. The regressive owners were removed. Native code or a product-level reduction
in exact far-offscreen work is now the next decision, not a later theoretical fallback.

### Measured implementation outcome

The migration was not stopped at design. Packed enemy columns, event-owned counters, persistent due
lanes, incremental overlap rows, packed projectile mirrors, sparse status membership and an
immutable-frame prototype were built and validated in focused isolation.

Full-game profiling rejected them:

- combined migration, 320 enemies: physics p95 `58.95 ms`;
- after removing incremental overlap revisions: `27.05 ms`;
- after removing unused projectile mirrors: `25.02 ms`;
- same-time original baseline: `19.37 ms`.

The immutable-frame prototype was not integrated because a consumer could mutate its exposed
packed arrays. Renderer CPU/GPU and batches were already within limits, so completing that migration
would not address the established primary owner.

## Decision constraints

The default solution must preserve:

- manual aim, held primary fire, dash, seekers and EMP;
- authored encounters, map pickups, cards and quota-gated bosses;
- the authored peak of 276 ordinary enemies and the exact 320-enemy capacity fixture;
- attack cadence, earliest-hit projectile truth, contact fairness and deterministic fixture counts;
- Korean and English user-facing completeness;
- the current single-threaded Godot 4.7 Web release unless a separate deployment change is approved.

The existing acceptance gate for the exact capacity scenario is physics p95 at or below 6 ms and
p99 at or below 8 ms, with frame and count checks also passing. Current retained records are roughly
three to four times over that simulation target at p95. The chosen strategy must therefore remove
whole passes and indirect work, not only shave fractions of a millisecond.

## Recommended direction

For the current itch.io/Web product, use an **exact-near plus virtual-far reserve**. Actors that are
visible, engaged, attacking, damaged, status-bearing, required, boss-related or close enough to
affect combat keep exact current simulation. Distant ordinary reserves keep only authored identity,
role, health and scheduled engagement information. The engagement director materializes them into
safe front/side approaches before they can affect the player.

This option best connects the gameplay improvement with the performance constraint: the game does
not spend full AI, movement, overlap and collision work on actors that cannot yet affect the current
fight. It changes far-offscreen individual simulation truth and therefore requires explicit product
approval plus transition, damage, quota and replay validators.

If exact individual simulation for all 320 actors is non-negotiable, the next candidate is a small
C++ GDExtension kernel behind a narrow command/receipt API. Web support, custom export templates and
CI/deployment checks are part of that option, not follow-up polish. Do not combine it with threads
in the first experiment.

## Target runtime shape

```text
Encounter / Cards / Player input
              |
        simulation commands
              v
+-----------------------------------------------+
| DenseCombatWorld                              |
|                                               |
| handles + packed state + sparse components    |
| lane queues + incremental spatial index       |
| decision -> motion -> collision -> combat     |
| event receipts + current/previous snapshots   |
+-----------------------------------------------+
       | events                    | snapshots
       v                           v
Progression / audio          Renderer / HUD / radar
```

### State layout

Use a dense live-slot set plus stable `{slot, generation}` handles. Store hot columns separately:

- `PackedVector2Array`: position, previous position, velocity, facing, desired velocity;
- `PackedFloat32Array`: health, radius, timers, cooldowns, speed and range scalars;
- `PackedInt32Array`: generation, role, movement family, phase, lane, cell and flags;
- bit flags or small packed integer fields for common booleans;
- sparse slot lists for status effects, shields, carriers, telegraphs and other optional state;
- immutable tables for role and movement profiles.

Cold strings, localized labels, card text and debug metadata must stay outside the hot arrays.

### Scheduling

Replace the 60 Hz full schedule rebuild with persistent queues or a timing wheel:

- critical queue: player-danger and exact-commit work at 60 Hz;
- visible-motion queues: 30 Hz motion publication with current/previous state interpolation;
- far-motion queues: 20 Hz;
- decision queues: 10 Hz, partitioned by stable slot or deterministic phase;
- sparse timer queues: status expiry, activation, shield and telegraph deadlines;
- distance-band reassignment: lower cadence or cell-boundary driven, not a full 60 Hz scan.

Each tick consumes due slots. Spawn, death, activation and band-change events update membership once.
Debug validators can reconcile queues against the full store outside the shipping hot path.

### Spatial queries

Use one dynamic cell owner for enemy occupancy and dynamic blockers:

- update membership only when a slot crosses a cell boundary;
- retain fixed-capacity occupant arrays or linked slot lists per cell;
- query neighboring cell ranges directly into reusable packed buffers;
- keep static cover in an immutable precomputed index;
- keep exact narrow-phase checks and deterministic tie-breaking;
- store local-neighbor results only for due motion owners;
- invalidate results by slot position generation, not by capacity-wide snapshot rebuild.

### Combat and projectiles

Keep 60 Hz swept projectile truth, but make the path flat and receipt-based:

- group projectile state in packed arrays;
- traverse the relevant cells once per segment;
- resolve static cover, structures and enemy candidates through reusable result buffers;
- retain exact earliest-contact ordering and stable tie-breaks;
- publish damage, kill, status and effect receipts to later phases;
- update sparse statuses only for slots that have statuses;
- use event-owned active counts instead of global recounts.

### Presentation

The renderer and HUD should never inspect mutable simulation objects while a simulation phase is
running. Publish bounded current/previous snapshots after each physics tick. Render once per
presented frame, interpolate transforms, and update only dirty batch ranges where measurement
justifies it.

Godot's `MultiMesh.set_buffer_interpolated()` can accept current and previous buffers. Cardborne
already batches rendering, so interpolation and dirty publication are the opportunities; replacing
the renderer wholesale is not.

## Option matrix

Scores are relative to Cardborne's measured bottleneck. `Web: full` means compatible with the
current single-thread export. It does not mean native and browser speedups will be identical.

| Option | Expected impact | Web | Behavior risk | Engineering risk | Decision |
| --- | --- | --- | --- | --- | --- |
| Current-head native + built-Web trace gate | Diagnostic, not a speedup | Full | None | Low | Required first |
| More isolated scalar caching in current functions | Low | Full | Low | Low | Use only for a newly measured owner |
| Remove 60 Hz schedule rebuild with persistent lane queues | High | Full | Low/medium | Medium | Recommended early slice |
| Event-owned counts and sparse status/activation lists | Medium/high | Full | Low | Medium | Recommended early slice |
| Packed structure-of-arrays enemy state | High | Full | Medium | High | Recommended foundation |
| Incremental cell membership and generation-invalidated neighbor rows | Medium/high | Full | Medium | High | Recommended foundation |
| Packed projectile state and unified query receipts | Medium | Full | Medium | High | Recommended after enemy core |
| Current/previous presentation snapshots with interpolation | Medium frame-pacing benefit | Full | Low | Medium | Recommended after simulation core |
| Dirty renderer batch uploads and repair-link lookup | Low/medium | Full | Low | Medium | Measure after simulation recovery |
| Cache movement LOS for one decision interval | Medium | Full | Medium fairness risk | Medium | Candidate with exact attack LOS retained |
| Spatially index dynamic structural blockers | Medium in affected stages | Full | Low | Medium | Candidate with targeted profile |
| Lower enemy motion cadence but interpolate visuals | Medium/high | Full | Medium | Medium | Candidate only with behavior replay checks |
| 30/40 Hz whole-game physics plus interpolation | High CPU reduction | Full | High | Medium/high | Product/physics decision, not default |
| Far-enemy cohort or impostor simulation | Very high | Full | Very high | High | Radical fallback requiring product approval |
| C++ GDExtension for the packed hot core | Very high | Conditional | Low behavior risk, high platform risk | Very high | Fallback if portable core misses gate |
| Pure-data worker threads with double buffering | Medium/high native | Conditional | Medium ordering risk | Very high | Later experiment, not first |
| Direct `PhysicsServer2D`/`RenderingServer` ownership | Low for measured owner | Likely | Medium | High | Not supported as first fix |
| More MultiMesh conversion | Low for measured owner | Full | Low | Medium | Renderer already green and batched |
| Third-party ECS/plugin | Unknown | Dependency-specific | Medium | High | Avoid; bespoke bounded core is smaller |
| Reduce enemy/projectile/effect counts | Artificially high | Full | Violates product load | Low | Rejected as a hidden fix |
| Raise/lower catch-up step ceiling | Does not remove work | Full | High time/fairness risk | Low | Rejected as root fix |
| GPU compute simulation | Not available on current Web renderer | No | High | Very high | Rejected |

## Detailed alternatives

### A. Continue incremental optimization in `VehicleRun`

This keeps the smallest diff and lowest migration risk. Plausible remaining slices include a
dynamic-blocker spatial index, a repair-link lookup, event-owned counters, sparse status updates and
decision-interval LOS caching.

The problem is responsibility and magnitude. `vehicle_run.gd` is 6,597 lines with 263 functions and
already owns orchestration, policies, collision, LOS, projectile paths and presentation assembly.
The retained marginal sequence improved p95 by about 11%, while the capacity target requires a much
larger change. Adding more caches inside the same integration owner raises invalidation risk and
makes later migration harder.

Decision: allow measured tactical fixes, but do not make this the main program.

### B. Data-oriented typed GDScript core

This removes repeated object traversal and establishes explicit hot/cold data boundaries without
changing the engine or release pipeline. It is the best first structural option because it targets
the measured owner and transfers to native and current Web builds.

Main risks:

- slot reuse and generation bugs;
- behavior drift from reordered phases;
- duplicated old/new authority during migration;
- overly broad `DenseCombatWorld` ownership;
- packed-array copy mistakes and accidental per-tick conversions.

Controls:

- one canonical slot allocator and handle validator;
- golden deterministic replays at 64, 128, 192, 276 and 320 enemies;
- per-phase receipts and stable sorting only where gameplay requires ordering;
- parallel shadow comparison against the old path in test builds, not shipping dual simulation;
- remove each old owner when its replacement becomes canonical.

Decision: recommended.

### C. Lower-rate or multirate simulation

Cardborne already uses 10 Hz decisions and 20/30 Hz motion lanes while keeping critical work and
projectiles at 60 Hz. A better queue implementation can preserve those rates without full scans.
Further cadence reduction can be safe for far, non-attacking motion if presentation interpolates
between simulation states.

Changing the whole physics rate to 30 or 40 Hz would nearly halve some work, but it changes dash
feel, input response, cooldown boundaries and tunneling behavior. Physics interpolation only smooths
transforms; it does not restore missed decisions or collision samples. Swept collision can mitigate
tunneling but cannot make the change behavior-neutral.

Decision: improve current multirate ownership first. Treat a global tick-rate change as a separate
product experiment.

### D. Far-enemy cohort simulation

Group far enemies by cell, role and objective. Simulate aggregate progress and materialize exact
individuals before they can attack or enter the visible safety band. This can make cost scale with
active local cohorts rather than total individual count.

This is the largest portable algorithmic reduction, but it changes the meaning of individual
positions, collisions, damage, status, kill credit and pickups. It also needs deterministic
materialization rules so enemies cannot pop, overlap or become unfair at the boundary.

Decision: valid radical redesign only if exact-individual simulation remains too expensive and the
product owner approves changed offscreen truth.

### E. GDExtension hot core

C++ can execute compact loops much faster than GDScript while preserving the same algorithms and
public API. A good extension boundary accepts packed commands/state and returns packed snapshots or
receipts; it must not call back into the SceneTree per enemy.

Desktop export is straightforward relative to Web. Current Godot Web templates omit GDExtension
support. Supporting it requires custom Godot export templates built with `dlink_enabled=yes`, Web
extension binaries, CI artifact ownership, version pinning and release validation. The existing
export preset and itch validator explicitly disable extension support, so adopting this option is a
release-architecture change.

Decision: predesign the API, but implement only after a GDScript packed-core benchmark shows that
algorithm and layout alone cannot pass.

### F. Worker threads

Only pure data can safely run in a worker. The active SceneTree is not thread-safe, and frequent
server value queries can stall asynchronous servers. A viable design would double-buffer immutable
input, compute decisions or grid work off-thread, and publish results at a later tick with explicit
latency and ordering contracts.

The current Web build is single-threaded. Emscripten pthreads require `SharedArrayBuffer`, COOP/COEP
cross-origin isolation and a distinct threaded binary. Thread creation, locks and main-thread
proxying can also erase gains for small jobs.

Decision: not the first cross-platform fix. Reconsider only when one pure-data phase remains large
after the structural rewrite and both hosting targets can be proven compatible.

### G. Direct Servers and more MultiMesh

Godot's low-level Servers reduce high-level node overhead, but Cardborne already has a modest node
count and a retained batched renderer. Render CPU/GPU and draw calls are green. Server APIs also
require manual RID lifetime and can stall when values are read back.

MultiMesh is valuable for drawing many copies, but it does not execute enemy AI, movement policy,
contact resolution or projectile collision. The current renderer already uses batched instances.

Decision: use only for a newly measured presentation or node-owner bottleneck.

## Recommendations

Use the following migration sequence. Create a decision-complete ExecPlan only after Gate 0
establishes a current baseline and the user approves implementation scope.

### Recommended migration sequence

### Gate 0: qualify the current tracked runtime

Wait until the concurrent UI/design workload is quiet. On one commit and a clean tree:

1. run native 60-second `peak_horde` and `capacity_pressure` records;
2. run the 64/128/192/256/320 scaling sweep;
3. export the production Web build;
4. capture Chrome Performance traces for the same peak and capacity fixtures;
5. record browser, device, focus state, viewport, renderer, thread mode and exact commit;
6. stop if fixture counts or authority checks fail.

This resolves the post-`a1af4287` gap and measures whether the published browser has an additional
owner beyond the native simulation overload.

### Slice 1: establish a benchmarkable packed kernel

Build a test-only kernel for 320 entities containing handles, position/velocity, lane deadlines and
incremental cell membership. It should execute the existing motion/neighbor inputs without UI,
audio or rendering.

Continue only if it demonstrates a material reduction, preferably at least 2x for the migrated
enemy scheduling/motion/overlap owner. A smaller result is unlikely to close the full-game gate.

### Slice 2: replace scheduling and aggregate scans

Move spawn/death/activation/band changes behind commands. Make counts event-owned. Consume due
slots from queues. Preserve current 10/20/30/60 Hz behavior and compare deterministic receipts to
the old path.

### Slice 3: replace spatial and movement queries

Move dynamic occupancy, local separation, dynamic blockers and movement collision behind the
packed index. Retain exact narrow-phase checks, stable tie-breaking and safe-path behavior.

### Slice 4: move projectiles and sparse combat state

Move projectile state and receipts, then statuses and optional components. Keep exact earliest hit,
damage, kills, boss interactions, XP and effect caps.

### Slice 5: publish immutable presentation frames

Give renderer, HUD, radar and minimap bounded snapshots. Add current/previous interpolation and
measure dirty uploads. Remove the replaced mutable-object presentation reads.

### Gate 1: full qualification

Run targeted validators during each slice, then one broad native and production-Web qualification
after the architecture is substantially complete. The stopping condition is the existing exact
count and frame/simulation thresholds, not subjective smoothness.

### Gate 2: native escalation decision

If the portable core preserves behavior but still fails capacity physics p95/p99, profile the new
phases. Move only the dominant pure-data kernel behind the stable API to a Web-capable GDExtension.
Do not add threads at the same time; that would prevent attribution.

## Validation contract

The implementation contract should require:

- exact fixture counts: 276 peak ordinary, 320 capacity ordinary, 240 player projectiles, 120
  hostile projectiles, 96 effects and the existing XP target;
- 1280x720 supported viewport and half-scale gameplay camera;
- attacks, collision, LOS, status, damage, kills, pickups and boss pressure enabled;
- deterministic count and receipt comparison across repeated seeds;
- native and built-Web evidence from the same commit;
- frame, physics, engine process, render CPU/GPU, draw calls, node/object count and memory;
- per-phase visited-slot, due-slot, query-candidate and receipt counters;
- explicit authority eligibility and focus/throttling metadata;
- no background Codex, browser, export or design workload during authoritative runs.

## Final 2026-08-14 gate update

The final portable-GDScript source commit is `e0962d7e`. It passes the isolated native cap-48
authority gate at physics p95/p99 `3.344/4.127 ms`, but the exact-cap staircase fails at 64 with
`9.623/12.062 ms`. The same exported build then fails a valid visible Chrome Web run at cap 48:
physics p95/p99 `11.0/13.6 ms`, frame p95/p99 `47.8/63.89 ms`, and 1% low `14.27 FPS`.

This closes Gate 0 and changes the decision. More local GDScript tuning is not a credible release
path for the current Web workload, and higher exact-cap experiments are not justified. The narrow
next experiment is one single-truth packed kernel for the measured ordinary-enemy decision,
movement, and neighbor-query loop. It must replace, not mirror, the current authoritative state;
preserve deterministic handles, exact collision/narrow-phase rules, cadence, and receipts; remain
single-threaded for attribution; and ship through a Web-capable custom template from the same
commit. This is a production toolchain and deployment-shape change, so it requires explicit user
approval before implementation.

The first spike boundary is limited to the ordinary-enemy schedule/decision/movement path currently
coordinated by `vehicle_run.gd`, `vehicle_enemy_update_schedule.gd`, and
`vehicle_spatial_grid.gd`. Bosses, generators, encounter admission and quota, projectiles, effects,
damage truth, progression, renderer, HUD, and presentation remain outside it. The packed kernel
accepts pure data and returns next state plus semantic receipts; it does not call the SceneTree or
keep a second live `EnemyState` copy.

Acceptance for that spike is deliberately small: a deterministic kernel oracle plus one isolated
native/Web benchmark must demonstrate at least a material 2x reduction in the migrated owner before
VehicleRun integration. If the isolated spike misses that trend gate, reject it without changing
the product runtime or export workflow.

## Immediate decision

The typed-GDScript live migration has been measured and rejected. Choose one next contract before
more runtime implementation:

1. approve exact-near plus virtual-far reserve for the Web-first product (recommended);
2. require exact 320-actor truth and approve a Web-capable GDExtension/custom-template spike; or
3. approve a lower supported exact density or cadence.

Threads, global physics-rate changes, weaker thresholds and hidden count reductions remain
unapproved.

## Limitations

- Effort and gains are relative estimates, not schedules or promises.
- The prototype and live migration were built; their negative full-game result is retained above.
- Web browser behavior can vary by browser, device, iframe embedding and focus state even when the
  same GDScript is deployed.
- A data-oriented layout improves locality and pass ownership but does not automatically make a
  poor algorithm fast. Query and cadence design remain essential.
- The active dense-combat ExecPlan predates later facility and active-combat changes. A new
  implementation contract must reconcile current code rather than copy stale plan text.
