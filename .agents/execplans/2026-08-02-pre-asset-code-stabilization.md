---
type: plan
status: active
owner: BK
created: 2026-08-02
last_reviewed: 2026-08-05
topic: Enemy motion, frame pacing, and combat-object scale stabilization
scope: Ordinary-enemy motion correctness, physics catch-up removal, live XP sizing, and non-beam projectile sizing
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/design/cardborne-universal-art-style-reference.png
  - ../semantic-v2-runtime-acceptance-evidence.md
---

# Enemy Motion, Frame Pacing, and Combat Scale Stabilization

## Purpose

Correct the two verified sources of visible stutter, then apply the requested XP and
projectile display-size changes. This plan starts from commit `c3d56614`; completed UI,
map, asset-generation, attack-route, Wear Collapse, and upgrade work must not be reopened.

The finished result must:

- preserve 10 Hz ordinary decisions, restore real 30 Hz near / 20 Hz far ordinary
  movement, and keep critical combat phases at 60 Hz;
- prevent peak-load physics work from entering the fixed-step catch-up spiral;
- render XP tiers at radii `24/28/33` without changing collection behavior;
- render every non-beam player and hostile projectile at exactly 70% of its current
  linear size without changing collision; and
- pass one consolidated validation and release-performance gate after implementation.

## Why / Verified Root Cause

Discovery is complete. There is no remaining “profile first and choose an owner later”
step.

### Enemy movement discontinuity

`VehicleEnemyUpdateSchedule.rebuild()` calculates both `decision_now` and `motion_now`,
but appends an ordinary actor only when `decision_now` is true. A motion-only tick still
resets `motion_elapsed`, so its elapsed movement is discarded. A 60-tick trace proved
that ordinary actors move only 9–10 times per second and receive between 0.15 and 0.50
seconds of movement time depending on bucket alignment, instead of the intended one
second. `VehicleCombatRenderer` presents `enemy.pos` directly, so the defect is visible.

The same path has a second correctness bug: steering overlap refresh uses the parity of
a stable runtime slot plus that actor's stable decision bucket. Roughly half the actors
therefore never refresh their overlap cache.

### Frame and physics discontinuity

The focused normal-instrumentation 60-second `peak_horde` run is CPU/physics-bound:

| Measurement | Observed result |
| --- | ---: |
| Rendered frame median / p95 / p99 | `16.009 / 45.833 / 133.333 ms` |
| 1% low | `7.26 FPS` |
| Longest run above 33.3 ms | `67 frames` |
| Physics tick median / p95 / p99 | `11.631 / 18.827 / 24.068 ms` |
| Draw-call p95 / combat batches | `86 / 33` |

The 18.827 ms physics p95 exceeds the 16.67 ms budget. Once a tick falls behind, Godot
runs multiple fixed ticks before rendering, producing the long visible stalls.

A separate focused 60-second diagnostic sampled every physics tick. It recorded 3,600
physics ticks but only 797 rendered frames (`4.52` ticks per rendered frame). Its p99
rendered frame accumulated `160.01 ms` of physics while the largest individual physics
tick was only `49.06 ms`. This proves repeated overdue physics ticks and catch-up, not a
single renderer stall.

Across the diagnostic's 64 slowest frames, non-overlapping physics ownership was:

| Owner | Mean slow-frame time | Share |
| --- | ---: | ---: |
| `enemies_and_grid` | `99.55 ms` | `58.6%` |
| `combat_and_effects` | `45.01 ms` | `26.5%` |
| `player_and_rewards` | `14.16 ms` | `8.3%` |
| `encounter_and_pursuit` | `10.96 ms` | `6.5%` |

`enemy_scheduled_ordinary` accounts for `67.79 ms`, or `68.1%`, of enemy time. Its
current work combines ordinary movement/collision with decision work. The second owner
is the per-tick traversal and collision testing of the peak projectile population.
HUD and presentation average only `5.38 ms` and `6.54 ms` on those slow frames; draw and
terminal CPU/GPU render readings are also within budget. They are contributors, not the
root cause.

The full-detail diagnostic intentionally added overhead—physics p95 rose from `18.827`
to `33.166 ms`—so its absolute frame result is not a release gate. Its complete
top-level coverage is sufficient to establish ownership. The temporary stride and
foreground instrumentation used for this diagnosis has already been removed.

## Scope and Non-Goals

### In scope

- Independent ordinary decision and motion scheduling.
- Decision-only, motion-only, and coincident ordinary update behavior.
- Steering-cache refresh fairness.
- Removal of verified redundant enemy-list, carrier-count, wear, open-space collision,
  and no-live-crate work.
- Empty-topology fast paths in the existing projectile collision owner.
- XP visual radii and the four existing non-beam projectile visual multipliers.
- Focused regression coverage and one final broad validation/performance pass.

### Out of scope

- UI, HUD layout, menus, upgrade-card layout/content, or localization redesign.
- PNG generation, editing, replacement, manifest/catalog/provider changes, or new art.
- Map, floor, wall, terrain, facility, actor, boss, item, or effect art.
- Enemy/projectile counts, spawn rules, role mix, attack timing, damage, speed, range,
  lifetime, collision radii, XP values, collection radius, or pickup behavior.
- Lower cadence, workload, quality, capacity, or acceptance thresholds.
- New dependencies, engine changes, native extensions, or renderer changes.

## Assumptions and Locked Decisions

- Godot 4.7.1 stable and GL Compatibility remain the runtime baseline.
- Decision and motion elapsed time have separate owners. A decision-only event cannot
  consume motion time, and a motion-only event cannot run decision work.
- A coincident event dispatches once, moves using the previously committed velocity,
  then evaluates the new decision. This preserves the current move-before-attack order.
- Motion keeps exact collision and spatial-grid truth. Renderer interpolation must not
  be used to conceal a lower simulation cadence.
- The active store remains the owner of live enemy membership. Cached derived counts
  must be invalidated by a generation/revision, never by object identity alone.
- The XP tier radii are `24`, `28`, and `33`. Medium is the rounded geometric bridge so
  the tier order remains readable after small doubles and large grows by 1.5x.
- Projectile visual multipliers become hostile `3.85`, primary `4.375`, seeker `4.025`,
  and opening breach `4.55`. Gameplay and collision radii remain unchanged.
- The visual authority remains `docs/design/VISUAL_SYSTEM.md` plus the inspected
  `1448x1086` canonical reference, SHA-256
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- No approval pause exists inside this plan. Stop only for a dependency, engine change,
  gameplay-rule change, workload/threshold reduction, destructive action, or scope
  expansion not authorized above.

## Proposed Design

### 1. Separate decision and motion lanes

`VehicleEnemyUpdateSchedule` keeps one union `ordinary_due` list so an actor is visited
at most once per physics tick, but records independent per-slot state:

- `decision_due` and accumulated `decision_delta`;
- `motion_due` and accumulated `motion_delta`; and
- generation-safe due stamps.

`rebuild()` appends an actor when either lane is due. It resets only the accumulator for
the lane it publishes. Over a warmed steady-state second, each ordinary actor therefore
receives 10 decisions totaling one second, while near/far actors receive 30/20 motion
applications totaling one second.

Split the current conflated ordinary update in `VehicleRun` into responsibility-shaped
paths:

- decision: cooldowns, phase transitions outside the critical lane, target/commit
  eligibility, LOS, role intent, and cached desired velocity;
- motion: cached-velocity integration, collision recovery, position change, and exact
  spatial-grid update; and
- critical: the existing 60 Hz startup/active/interrupted-recovery behavior.

Motion-only work never recomputes LOS, pursuit, attack eligibility, support targets, or
local steering. Decision-only work never moves or advances motion time.

Increment a decision-cycle epoch after each six-bucket cycle. Refresh local overlap on
alternating `(spatial_slot + epoch)` parity, with immediate refresh for an empty or
generation-invalid cache. Every actor then refreshes within 0.20 seconds without
increasing average steering-query volume.

### 2. Remove the confirmed enemy hot-path waste

Keep these changes inside the current store, scheduler, terrain, grid, and run-loop
owners:

1. Remove the scheduler's copied `alive` list. Iterate `VehicleEnemyStore.live` for the
   status/activation pass and retain only lists that materially group later work.
2. Add a live-membership revision to `VehicleEnemyStore`, incremented on add, clear, and
   successful defeat flush. Rebuild carrier-child counts only when that revision changes;
   same-tick child creation still updates the cached count immediately.
3. Record actors whose position actually changed. Evaluate Wear Collapse for that set
   plus the terrain runtime's already-tracked occupants, deduplicated by stable slot and
   generation, instead of scanning every active actor again. Stationary tracked actors
   continue receiving the exact 60 Hz damage deadline.
4. Track the live-crate count from stage population through crate destruction. When it is
   zero, bypass crate-clearance, projectile/crate, and LOS/crate cell queries with their
   exact no-hit result.
5. In open-space movement, use the existing safe-motion cell and tactical-cover
   broadphase result before invoking exact rectangle collision. Direct integration is
   allowed only when the safe cell is valid, the swept runtime-cover candidate list is
   empty, and the live-crate guard is clear. All other paths retain the current exact
   solver and retry behavior.

These changes offset the legitimate increase from restoring 30/20 Hz movement. They do
not defer grid position truth or reduce any simulation population.

### 3. Remove the confirmed projectile hot-path waste

Keep projectile pools, capacities, integration cadence, ordered enemy-grid traversal,
and first-hit semantics unchanged.

For each non-wall-piercing projectile, obtain the swept tactical/runtime cover candidate
list once. If that list and static stage cover are both empty, return the reusable
no-cover receipt without invoking the segment/rectangle solver. Otherwise execute the
existing exact solver in the same cover-before-crate-before-actor order. Use the shared
live-crate guard from Design 2 to skip crate queries only when no crate can exist.

No effect, trail, zone, fire-rate, projectile-count, or collision reduction is authorized;
their current loops are bounded and were not established as removable root work.

### 4. Change only renderer-owned scale values

Set the following constants in `vehicle_stage_visual_profile.gd`:

```text
EXPERIENCE_RADII = 24.0 / 28.0 / 33.0
HOSTILE_PROJECTILE_ENVELOPE_SCALE = 3.85
PLAYER_PRIMARY_PROJECTILE_SCALE = 4.375
PLAYER_SEEKER_PROJECTILE_SCALE = 4.025
PLAYER_OPENING_BREACH_PROJECTILE_SCALE = 4.55
```

The existing shared XP and energy-teardrop PNGs remain unchanged. Collection and
projectile collision continue to use their current independent gameplay values.

## Tasks

### M1 - Correct ordinary scheduling and motion

- [x] Add independent decision/motion due flags and accumulated deltas to
  `VehicleEnemyUpdateSchedule`; keep a single union dispatch list.
- [x] Split ordinary decision/state work from cached-velocity locomotion in `VehicleRun`.
- [x] Preserve one move on coincident ticks and the existing 60 Hz critical lane.
- [x] Replace fixed steering parity with the generation-safe decision-cycle epoch.
- [x] Add exact cadence, elapsed-time, ordering, collision-distance, attack-timing, and
  two-epoch steering regression cases.

Acceptance: steady-state counts are decision `10`, near motion `30`, far motion `20`,
critical `60`; each elapsed lane totals one second; motion distance, collision, and attack
timing remain correct; no actor keeps a permanently stale steering cache.

### M2 - Remove the verified physics hot-path waste

- [x] Remove the copied scheduler `alive` list and cache carrier-child counts behind the
  store membership revision.
- [x] Replace the all-active wear pass with moved-plus-tracked, stable-slot-deduplicated
  work while retaining 60 Hz stationary occupancy damage.
- [x] Add the live-crate count and apply its exact no-hit guard to movement, LOS, and
  projectile queries.
- [x] Add the safe open-space motion fast path without bypassing any candidate cover.
- [x] Add the empty-cover projectile fast path without changing ordered collision.
- [x] Add regression cases for membership invalidation, final-crate transition,
  stationary wear damage, open/candidate cover, wall piercing, and first actor hit.

Acceptance: no gameplay population or cadence is reduced; every candidate-bearing path
uses the existing exact collision result; empty topology avoids the proven redundant
queries; grid, wear, carrier, and crate state remain generation-safe.

### M3 - Apply the requested display-size corrections

- [x] Set XP radii to `24/28/33` and the four projectile multipliers to
  `3.85/4.375/4.025/4.55` in `VehicleStageVisualProfile`.
- [x] Update existing renderer/readability validators for the exact display values and
  unchanged shared-image/collision ownership.
- [x] Capture all three XP tiers and friendly/hostile projectiles together at gameplay
  scale through the existing capture gateway; do not create or edit production images.

Acceptance: XP tier order is `24 < 28 < 33`; all non-beam projectiles are exactly 70% of
the current rendered size; collision, collection, speed, damage, and image bytes are
unchanged.

### M4 - Run one final gate and retire the plan

- [x] After M1-M3 were integrated, run the complete `validate_vehicle_*.gd` suite once,
  visual-authority validation once, and Web export once.
- [x] Run one focused, clean, commit-stamped native 1280x720 `peak_horde` and one
  `capacity_pressure` result with normal stride-7 instrumentation. Both authoritative
  runs completed, but the release thresholds remain unmet; the exact results are
  recorded below.
- [x] Run one visible built-Web gameplay smoke/performance trace using the repository's
  guarded Codex port lane. The built Web canvas entered gameplay at 1280x720 with no
  console errors; the raw browser trace was tool-local because its file path was outside
  the browser tool's configured workspace roots.
- [x] Review the final actual-scale capture for XP order, projectile readability,
  clipping, and collision-boundary deception.
- [x] Record exact commit, artifact, and metric evidence. Plan retirement remains
  intentionally blocked by the failed native release gate; do not mark this plan done
  or delete it until a later task-owned optimization pass satisfies the locked limits.

Acceptance: all validators and exports pass; native/Web scenario validation is valid and
fully focused; no UI/map/PNG change is present; native peak meets p95 `<=18 ms`, p99
`<=25 ms`, median `>=59 FPS`, 1% low `>=55 FPS`, and at most one consecutive frame over
33.3 ms; capacity physics meets p95 `<=6 ms` and p99 `<=8 ms`; draw-call p95 remains
`<=200` and combat batches `<=50`.

## Test Plan

Do not run broad checkpoints between milestones. Write the focused cases alongside the
implementation, then execute one consolidated final batch after M1-M3:

```powershell
.\tools\godot.ps1 --path . --headless --import

$validators = Get-ChildItem -LiteralPath 'tools/validation' -Filter 'validate_vehicle_*.gd' |
  Sort-Object Name
foreach ($validator in $validators) {
  .\tools\godot.ps1 --path . --headless --script "res://tools/validation/$($validator.Name)"
  if ($LASTEXITCODE -ne 0) { throw "validator failed: $($validator.Name)" }
}

.\tools\validation\validate_cardborne_visual_authority.ps1
if ($LASTEXITCODE -ne 0) { throw 'visual authority validation failed' }
.\tools\export_web.ps1
if ($LASTEXITCODE -ne 0) { throw 'Web export failed' }
git diff --check
```

Run native performance from the exact clean implementation commit with the current
`peak_horde` and `capacity_pressure` fixtures, 10-second warmup, 60-second sample,
1280x720, GL Compatibility, VSync disabled, commit/dirty environment fields set, and
normal recorder stride. Reject a result with unfocused samples, dirty/mismatched commit,
invalid scenario counts, or a failed threshold. Use `$npjt-port-guard` and the built Web
export for the one visible Web run; stop only a positively task-owned server.

A failed check is not a pause for user approval. Correct the task-owned defect, rerun the
failed focused check, then rerun the final gate needed to establish a clean result.

## Rollback / Safety

- Commit scheduling, hot-path, scale, and final evidence as coherent task-owned commits.
- Never reset, clean, stage, or rewrite unrelated user work.
- If decision/motion separation changes attack timing, distance, collision, or critical
  cadence, correct that milestone before continuing; do not retain the old discard bug.
- If a fast path disagrees with the exact solver for any candidate-bearing case, remove
  the fast path rather than weaken collision truth.
- Revert scale constants and their validator expectations together. No asset rollback is
  necessary because image bytes do not change.

## Risks

- Restored 30/20 Hz movement increases legitimate collision applications. The plan pairs
  the repair with decision/motion separation and verified empty-topology shortcuts; it
  must not preserve dropped motion as an optimization.
- Cached membership or topology can become stale after pool-slot reuse. Every cache is
  revision/generation guarded and has reuse regression coverage.
- Larger XP and smaller projectile visuals can obscure collision expectations. The final
  actual-scale capture and independent collision assertions guard this without changing
  mechanics.
- OS focus can invalidate performance evidence. Any unfocused sample invalidates the
  artifact; gameplay must not be changed to compensate for external scheduling.

## Open Questions

None. Motion and frame causes, implementation owners, scale interpretation, collision
separation, validation scope, and no-approval execution behavior are closed.

## Decision Notes

- 2026-08-05: Rejected the earlier conditional profiling milestone because it left the
  hitch owner unresolved inside an executable plan.
- 2026-08-05: A temporary every-tick focused diagnostic established fixed-step catch-up,
  `enemies_and_grid` as the primary owner, `enemy_scheduled_ordinary` as its dominant
  child, and `combat_and_effects` as the secondary owner. Temporary source edits were
  restored immediately after capture.
- 2026-08-05: Chose independent decision/motion lanes and cached locomotion rather than
  renderer interpolation or lower cadence.
- 2026-08-05: Kept only one final broad gate; no milestone-by-milestone full validation
  remains.
- 2026-08-05: Follow-up hot-path review confirmed the runtime schedule is rebuilt every
  physics tick so due lanes are never replayed between buckets. Same-cell enemy motion
  now updates cached grid coordinates without rebuilding membership, and the exact
  movement solver reuses the safe-cell result already computed by the runtime cover
  owner.
- 2026-08-05: Final code review found that the implementation had accidentally wrapped
  the scheduler rebuild in `decision_bucket == 0`, which discarded five of six decision
  buckets and most 30/20 Hz motion opportunities. Commit `df2d1744f1f1be422fd582cd030c671bbbb7d194`
  restores a rebuild on every physics tick. The same commit adds a generation-safe
  static-cover broadphase result so motion can skip only the redundant full cover scan;
  floor/void and dynamic-cover checks remain exact.
- 2026-08-05: Final authoritative native evidence at commit `df2d1744f1f1be422fd582cd030c671bbbb7d194`
  is valid and clean but fails the locked performance gate. `peak_horde` recorded frame
  p95/p99 `144.444/147.790 ms`, physics p95/p99 `38.860/49.752 ms`, 1% low `6.741 FPS`,
  and `450` consecutive frames over 33.3 ms; draw p95 `84`, combat batches `33`, and
  scenario counts passed. `capacity_pressure` recorded frame p95/p99 `133.333/143.301 ms`,
  physics p95/p99 `44.172/54.431 ms`, 1% low `6.842 FPS`, and `397` consecutive frames
  over 33.3 ms; draw p95 `93`, combat batches `33`, and scenario counts passed. Both
  runs had zero unfocused samples, `authoritative=true`, and `dirty=false`.
- 2026-08-05: The complete current validator set is green: 58 vehicle validators
  (including the 161-second multi-sector case), visual authority, Web export, and
  `git diff --check`. The final capture is
  `build/captures/stabilization-df2d1744/capture-manifest.json`; the Web smoke used
  Codex port `13029` and entered the built gameplay canvas without console errors.

## Progress

- [x] Read the active product, visual, execution-plan, and repository guidance.
- [x] Reproduced and quantified the normal focused release failure.
- [x] Traced the scheduler for representative near/far buckets over 60 physics ticks.
- [x] Captured full per-tick ownership, proved catch-up, and restored diagnostic edits.
- [x] Audited enemy, grid, terrain, projectile, crate, renderer, and recorder ownership.
- [x] Closed the implementation design and final acceptance thresholds.
- [x] M1 ordinary scheduling and motion separation is implemented with focused cadence
  and steering coverage.
- [x] M2 verified hot-path guards are implemented with membership, wear, crate, cover,
  and collision regression coverage.
- [x] M3 renderer-owned XP and non-beam projectile scale constants are implemented;
  the final actual-scale capture is complete.
- [x] M4 validation, performance evidence, Web smoke, and final actual-scale review are
  executed. The plan remains active because the locked native release gate is failed.

## Next Steps

Keep this plan active for the next task-owned performance pass. Start from the exact
profiling evidence above, target `enemy_scheduled_ordinary` and the fixed-step catch-up
chain, and preserve the locked 10/30/20/60 Hz cadence, workload, collision truth, and
acceptance thresholds. Do not touch UI, maps, PNGs, gameplay populations, or lower the
release limits to make the failed gate appear green.
