---
name: cardborne-performance-guard
description: Use before Cardborne profiling, performance claims, runtime hot-path changes, capacity work, frame-pacing fixes, or visual and asset integration suspected of causing stutter. Enforces controlled baselines, render-versus-simulation attribution, workload and threshold integrity, narrow ownership, and precise pass labels.
---

# Cardborne Performance Guard

Read `.agents/cardborne-performance-engineering-policy.md` completely before acting.
Consult `.agents/research/performance/cardborne-runtime-architecture-audit.md` for the current evidence
boundary; do not treat its historical numbers as current-HEAD qualification.

If the task creates, edits, reviews, approves, promotes, or switches a player-facing
visual, also load `$cardborne-visual-authority` and complete its preflight first.

## Workflow

1. **Name the symptom and claim.** Distinguish continuous low FPS, intermittent hitch,
   cold load/import delay, physics backlog, presentation staging, render CPU, GPU/fill,
   memory growth, and external process contention.
2. **Find the latest eligible evidence.** Resolve the relevant active plan from lifecycle
   metadata under `.agents/execplans/`, then follow its named durable evidence record under
   `.agents/`. Treat ignored `build/performance/` JSON as supporting local evidence unless
   the active plan explicitly pins it. Require the exact commit, dirty state, workload,
   viewport, renderer, warmup, duration, focus, and process-isolation metadata before
   comparing results.
3. **Establish the before state.** A red or missing baseline cannot prove that the next
   asset or code change caused the failure. Record it as pre-existing or unqualified.
4. **Attribute before editing.** Use physics and named subsystem timings for simulation;
   presentation/HUD timings for staging; render CPU/GPU, draw calls, batches, resolution
   sensitivity, and texture memory for the visual path. Use a bounded ablation only when
   passive profiling cannot distinguish owners.
5. **Constrain the owner.** Keep an asset-only replacement in raster, manifest, provider,
   and presentation owners. Keep AI, collision, cadence, capacity, and encounter changes
   out unless the user separately authorizes a gameplay change. Optimize one measured
   owner at a time and preserve exact behavior with a focused oracle or validator.
6. **Validate proportionately.** Run cheap owner-focused checks while implementing. Run
   the authoritative native/Web scenarios only at the active plan's declared checkpoint,
   from a clean commit and a quiescent machine. Do not repeat a valid expensive run merely
   for confidence.
7. **Report the narrow verdict.** Say `asset import passed`, `visual budget passed`,
   `scenario valid`, `native release performance passed`, or `Web release performance
   passed`. Never shorten a partial result to `performance passed`.

## Asset-Swap Boundary

For a drop-in raster replacement, preserve the semantic ID, canvas, pivot, intended world
footprint, and import contract. Confirm that the asset diff does not change enemy logic,
collision, update cadence, actor counts, projectile counts, or performance thresholds.

Disk PNG bytes and unequal source dimensions are not causal evidence. Investigate assets
only when measurements show a cold-load, texture-memory, draw/state-change, overdraw,
render-CPU, or GPU owner. Do not reduce resolution, enable lossy/VRAM compression, build an
atlas, or rewrite batches without that evidence.

## Stop Conditions

Stop the affected branch and report the exact blocker when:

- no comparable before baseline exists;
- another Godot, capture, test, or heavy process overlaps the sample;
- a proposed fix changes workload, cadence, collision, visual quality, or thresholds;
- the only remaining proposal requires threads, GDExtension/native code, an engine change,
  or a dependency;
- the measured owner contradicts the proposed change surface;
- a performance optimization changes player-visible or deterministic gameplay behavior.

Do not kill unrelated processes, weaken a gate, or make a product tradeoff to manufacture
a passing result.
