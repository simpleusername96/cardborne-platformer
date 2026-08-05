---
type: policy
status: active
owner: BK
created: 2026-08-05
last_reviewed: 2026-08-05
canonical_for: Cardborne runtime performance diagnosis, optimization, and performance claims
scope: Runtime hot paths, visual and asset integration, performance fixtures, profiling, and release qualification
related:
  - ./cardborne-runtime-architecture-audit.md
  - ./execplans/2026-08-02-pre-asset-code-stabilization.md
  - ./semantic-v2-runtime-acceptance-evidence.md
  - ../docs/design/VISUAL_SYSTEM.md
---

# Cardborne Performance Engineering Policy

## Purpose

Prevent performance work from confusing asset size, rendering, presentation staging,
simulation, loading, and test-environment contention. Future changes must preserve
Cardborne's gameplay and visual contracts while optimizing only a measured owner.

The diagnostic principles are engine-agnostic: measure frame time rather than guessing
from visible complexity, isolate CPU/GPU/loading/memory owners, reuse bounded hot data,
and validate on the actual target. Godot documentation remains authoritative for this
project's APIs, execution model, import behavior, and runtime limits.

## Scope

This policy applies when work can affect frame pacing, physics cost, render cost, memory,
loading, actor or projectile scale, visual assets, batching, performance fixtures, or a
claim that a build has passed a performance gate.

It governs diagnosis and engineering process. Product changes to encounter density,
capacity, cadence, collision, difficulty, visual quality, or supported hardware remain
user decisions.

## Rules

### 1. Classify the symptom before changing code

- Separate continuous low frame rate, intermittent hitch, cold load/import delay,
  physics catch-up, script cost, presentation/HUD staging, render CPU, GPU/fill rate,
  memory growth, and external process contention.
- Use the standard Godot profiler or named subsystem timers for script and physics cost.
  Use the Visual Profiler and render monitors for render CPU/GPU cost. The Visual
  Profiler does not include scripting or physics.
- Treat total frame time as the result of the slowest relevant owner. A low GPU time does
  not excuse a slow physics path, and a low script time does not rule out GPU fill cost.
- Do not optimize from visual complexity, file size, intuition, or a single FPS counter.

### 2. Establish a comparable baseline

- Compare the same workload, viewport, renderer, VSync setting, warmup, sample duration,
  focus state, commit cleanliness, instrumentation mode, and machine state.
- Record the pre-change result before attributing a regression. If the baseline is red or
  missing, describe the result as pre-existing or unqualified; do not blame the next asset
  or code change.
- Keep the causal diff narrow. Asset integration and simulation optimization belong in
  separate commits and separate claims.
- Reject samples that overlap unrelated Godot, test, capture, build, browser, or other
  heavy processes. Do not stop processes whose ownership is not positively known.

### 3. Use precise pass labels

- Report `import passed`, `focused validator passed`, `visual budget passed`, `scenario
  valid`, `native release performance passed`, and `Web release performance passed` as
  distinct outcomes.
- Never shorten a partial gate to `performance passed`.
- A successful Web export is not an interactive smoke result. A visual draw/batch pass is
  not a frame/physics pass. A short diagnostic is not authoritative release evidence.
- Preserve failed and invalid evidence with its exact eligibility reason; never select a
  shorter or luckier sample as the final result.

### 4. Keep asset changes presentation-only

- A drop-in raster replacement preserves semantic ID, canvas, pivot, intended world
  footprint, import contract, and runtime ownership. It must not change AI, attack rules,
  collision, cadence, encounter density, actor capacity, or projectile capacity.
- Disk PNG size affects package size and can affect load/decompression. Pixel dimensions
  affect decoded texture memory and can affect bandwidth or fill. Unique textures and
  materials can affect batching. None of these facts alone proves a sustained frame-time
  regression.
- Investigate the asset path only when evidence shows cold-load time, texture memory,
  render CPU/GPU, draw calls, state changes, overdraw, or resolution sensitivity as an
  owner.
- Do not blanket-reduce texture resolution, enable lossy or VRAM compression, generate
  mipmaps, build an atlas, or change filtering to solve a script or physics bottleneck.
  In 2D, compression and mipmap choices also have visible-quality and memory tradeoffs.
- Do not load or decode resources inside a recurring gameplay hot path. If a first-use
  hitch is measured, preload or warm the exact resource set at an existing transition
  boundary and validate memory as well as latency.

### 5. Design hot paths around bounded, reusable data

- Prefer bounded pools, typed arrays, packed arrays for compatible measured hot data,
  stable IDs, linear iteration, incremental indexes, and reusable caller-owned output
  buffers.
- Avoid per-tick node creation/destruction, deep `Dictionary`/`Array` snapshots,
  `duplicate(true)`, repeated full-set discovery, symmetric pair work performed twice,
  and queries that allocate their result in a high-frequency loop.
- Move invariant computation out of loops or precompute it at load/layout time when its
  inputs are stable.
- Use spatial partitioning to reduce candidates, then measure the cost of maintaining and
  snapshotting the partition itself. A grid is not automatically fast if every query still
  rebuilds global state.
- Pool only bounded, frequently recycled state whose lifecycle is clear. Do not introduce
  a generic pool or cache without an invalidation, ownership, and capacity contract.

### 6. Preserve gameplay while scheduling work

- Keep player input, committed attacks, collision, damage, boss windows, and other
  fairness-critical state on their authored physics boundary.
- Non-critical decisions or distant presentation may use fixed accumulated cadence only
  when the product contract and validators preserve observable behavior.
- Do not lower physics tick rate, `max_physics_steps_per_frame`, update cadence, workload,
  or capacity as a hidden optimization. Changing those values changes responsiveness,
  catch-up behavior, or product pressure rather than repairing the measured algorithm.
- Treat multiple physics ticks per rendered frame as backlog evidence. Optimize the
  physics work; do not raise the catch-up ceiling to hide it.

### 7. Keep rendering retained and measurable

- Reuse semantic textures/materials and retained batches. Keep the existing combat batch,
  world batch, and draw-call ceilings unless the user approves a new release contract.
- MultiMesh reduces submission overhead but is one spatial object; do not merge unrelated
  world regions into a batch that defeats useful culling. Split only when profiling shows
  the tradeoff matters.
- Do not rewrite retained buffers, add atlases, or introduce dirty-upload machinery while
  render CPU/GPU and draw/batch metrics are already green. Profile after a material render
  change before selecting the next owner.
- Bound transparent overlays and overlapping full-screen effects because screen-space
  coverage can create fill-rate cost even when source textures are small.

### 8. Keep orchestration separate from measured owners

- `VehicleRun` coordinates the frame but should not absorb new subsystem rules, storage,
  rendering, formatting, or performance-fixture behavior for convenience.
- Put state and algorithms in the existing responsibility owner. Expose a narrow fill-into,
  advance, or query contract to the orchestrator.
- Extract existing `VehicleRun` responsibilities only one measured section at a time with
  behavior-equivalence tests. Do not perform a speculative big-bang rewrite of the run.
- Instrument named subsystem boundaries. Remove or disable high-detail instrumentation
  outside performance runs when its own overhead is material.

### 9. Treat threads, servers, and native code as escalation paths

- Exhaust measured algorithm, data-layout, allocation, and ownership fixes before adding
  threads, direct server control, GDExtension, or engine changes.
- Do not touch the active SceneTree or rendering resources from worker threads. Use only
  documented thread-safe APIs and explicit synchronization for shared data.
- Avoid frequent mutex contention, just-in-time thread creation, and per-frame server
  readbacks that force synchronization.
- Native code, engine changes, threading model changes, and new dependencies require
  explicit user approval and a separate risk/validation contract.

### 10. Validate at the right cadence

- Run focused owner validators while implementing. Run import/export only after a relevant
  source or asset change. Run authoritative performance scenarios only from the exact
  clean checkpoint declared by the active plan.
- Do not repeat an expensive passing gate without a relevant input change. Rerun a failed
  gate only after a code change or a new causal hypothesis can produce new evidence.
- Preserve exact actor/projectile/effect counts and attack activity in performance
  fixtures. A scenario that silently loses work is invalid even when its FPS improves.
- Stop and request a user decision when the remaining path requires a product tradeoff,
  weaker threshold, native/dependency work, or materially broader architecture.

### 11. Correlate perceived stutter with normal play

- When a synthetic fixture does not match the user's reported on-screen workload, run
  `tools/run_manual_performance_trace.ps1` and reproduce the symptom through the normal
  deployment flow. Close the game normally after the slow period so the trace is flushed.
- The manual trace is debug-only, bounded, and diagnostic-only. It preserves persistence,
  layout randomness, gameplay rules, counts, collision, cadence, and UI; it never produces
  a release pass or fail result.
- Read `ordinary_active` as map-wide simulated cap-counting ordinary enemies,
  `ordinary_center_in_viewport` as the subset whose body center is inside the visible
  world rectangle, and `ordinary_offscreen_active` as their difference. Do not equate any
  of these with total live actors.
- Use `physics_ticks` greater than one on a rendered frame as physics catch-up evidence.
  Correlate slow frames and approximately one-second buckets with subsystem,
  presentation, HUD, render, focus, projectile, effect, and pressure fields before
  selecting a code or product owner.
- Treat the trace as instrumented evidence: named timers, pressure copying, and viewport
  render measurement add bounded diagnostic overhead. Confirm a selected owner with the
  focused profiler or release fixture before making a final performance claim.
- Keep the generated JSON under `build/performance/manual/`. It is local evidence ignored
  by Git; summarize a durable finding in the active plan only after reviewing the trace.

## Prohibited Directions

- Do not infer that differently sized PNG files require enemy AI changes.
- Do not edit enemy behavior merely because an asset switch and a performance test happened
  in the same phase.
- Do not mix visual replacement, gameplay correction, profiler changes, and optimization in
  one causal diff.
- Do not call a visual-budget pass a release-performance pass.
- Do not reduce workload, collision accuracy, attack activity, cadence, resolution, visual
  quality, or thresholds to manufacture a green result.
- Do not add caches, pools, threads, atlases, MultiMeshes, or native code as generic
  best-practice cargo cults; each requires a measured owner and a narrow contract.
- Do not optimize an invalid or externally contaminated benchmark.
- Do not leave a temporary performance workaround as an undocumented permanent owner.

## Exceptions

The user may approve a product, quality, workload, threshold, engine, native-code,
threading, or dependency change. Record that decision separately from a behavior-preserving
optimization and re-baseline every affected scenario.

Debug-only experiments may temporarily violate a production boundary when they are
strictly bounded, cannot ship, preserve the control run, and are removed after they answer
one named hypothesis.

## Related

- Current audit and source map: `./cardborne-runtime-architecture-audit.md`
- Active stabilization contract: `./execplans/2026-08-02-pre-asset-code-stabilization.md`
- Historical performance evidence: `./semantic-v2-runtime-acceptance-evidence.md`
- Visual/collision ownership contract: `../docs/design/VISUAL_SYSTEM.md`
- Reusable workflow trigger: `./skills/cardborne-performance-guard/SKILL.md`
