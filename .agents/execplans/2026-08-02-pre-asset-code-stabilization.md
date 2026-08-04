---
type: plan
status: active
owner: BK
created: 2026-08-02
last_reviewed: 2026-08-05
topic: Enemy motion, frame pacing, and combat-object scale stabilization
scope: Ordinary-enemy motion continuity, measured frame-hitch repair, live XP shard sizing, and player/hostile projectile sizing
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

Finish the remaining runtime-stabilization work without reopening completed UI,
asset-generation, map, or gameplay-content work. The completed upgrade, projectile
asset, attack-route, Wear Collapse, and prior optimization work is the verified
baseline at commit `a6d84b95f5379f57d5069fed5f4630ff35efc3fc`; it is not work to repeat.

The required outcome is:

- ordinary enemies move at the product contract's real 30 Hz near / 20 Hz far
  cadence instead of visibly stepping because scheduled motion work is discarded;
- frame hitches are attributed per contributing physics tick and repaired in the
  measured owner without lowering workload, cadence, or release thresholds;
- live XP shards become materially easier to see while retaining a readable
  small/medium/large order;
- every non-beam player and hostile projectile becomes exactly 30% smaller in
  rendered linear size, with collision and combat behavior unchanged; and
- the broad validation and release-style performance gate runs once, after all
  implementation and measured optimization are complete.

This document is the single active ExecPlan for this outcome. The earlier completed
detail remains available in Git history at `9c66a8bf` and `a6d84b95`; keeping it in
the active checklist would invite already-finished work to be repeated.

## Why / Current State

The user's report contains two distinct motion problems and one scale correction.
They must not be treated as one vague rendering issue.

| Concern | Verified current fact | Consequence |
| --- | --- | --- |
| Ordinary enemy cadence | `VehicleEnemyUpdateSchedule` computes 30/20 Hz `motion_now`, resets `motion_elapsed`, but appends an enemy to `ordinary_due` only when its 10 Hz `decision_now` is true. | Most motion-only ticks are discarded. Ordinary movement is effectively sparse and visibly stepped, and elapsed movement time can be lost. |
| Enemy presentation | `VehicleCombatRenderer._sync_enemies()` writes `enemy.pos` directly to the retained batch. There is no presentation interpolation. | The scheduler defect is visible directly; frame hitches make the discontinuity worse. |
| Steering cache | `refresh_overlap` combines a stable runtime slot with a stable decision bucket parity. | Roughly one deterministic half of ordinary actors can keep reusing an old overlap direction instead of alternating refresh work. |
| Frame pacing | The newest focus-valid 60-second native evidence has 16.009 ms median, 45.833 ms p95, 133.333 ms p99, 7.26 FPS 1% low, and 67 consecutive frames over 33.3 ms. Draw p95 is 86 and combat batches are 33. | Steady render batching passes; tail latency and physics catch-up do not. |
| Attribution quality | Detailed subsystem timing is sampled only every seventh physics tick, while a slow rendered frame may contain several physics ticks. | The artifact proves physics-associated hitching but cannot identify the full p99 owner safely. |
| Current-HEAD diagnostic | A commit-stamped run for `a6d84b95` completed with the valid peak workload, but the game window was unfocused for all 1,348 samples. It produced 27.361 / 134.616 / 142.105 ms median/p95/p99 and is intentionally non-authoritative. | It confirms the symptom under the current commit but cannot be used as a release baseline. |
| XP shards | One 64x64 `pickup/experience_master` image is rendered as value tiers `1`, `2-4`, and `>=5` with radii `12/16/22`. Collection uses the independent fixed radius `34`. | Scaling the renderer-owned radii is mechanically isolated; no new image or pickup rule is needed. |
| Projectiles | All non-beam projectiles share one 64x64 `projectile/energy_teardrop`. Current visual multipliers are hostile `5.50`, primary `6.25`, seeker `5.75`, and opening breach `6.50`. | Four profile constants can implement one consistent 0.70 visual multiplier without changing collision. |

The focused schedule, steering, renderer, projectile, XP, and performance-scenario
validators all pass at plan time. That does not contradict the findings: the current
schedule validator checks that deferred work eventually appears, but does not prove
that motion-only due ticks are dispatched or that one second of accumulated movement
is preserved.

## Scope and Non-Goals

### In scope

- `VehicleEnemyUpdateSchedule` due-list and accumulated-delta correctness.
- The narrow `VehicleRun` dispatch path that consumes scheduled ordinary work.
- Generation-safe steering-cache refresh fairness.
- Presentation-only smoothing only if correct 30/20 Hz truth still fails the locked
  rendered-continuity criterion below.
- Diagnostic-only, full per-physics-tick performance attribution.
- Optimization of the measured dominant runtime owner within its existing module.
- XP shard visual radii and all four non-beam projectile visual multipliers.
- Focused regression checks during implementation and one final broad gate.

### Explicitly out of scope

- Any UI layout, UI chrome, upgrade-card content, menu, HUD layout, or localization
  redesign.
- Any PNG generation, editing, replacement, manifest change, catalog alias, or new
  visual identity. Both requested size changes reuse the current approved masters.
- Floor, wall, map, terrain-art, facility, item, player, enemy, boss, or effect art.
- Enemy count, role mix, spawn rules, attack timing, damage, movement speed, collision,
  target radius, projectile speed/range/lifetime, XP value, pickup radius, or magnet
  behavior changes.
- Capacity, fixture, visual-quality, update-cadence, or acceptance-threshold reductions.
- A new engine, dependency, native extension, renderer, or graphics backend.

## Assumptions and Locked Decisions

- Godot 4.7.1 stable and GL Compatibility remain the implementation baseline.
- The product performance contract remains 60 Hz for player intent, committed states,
  boss behavior, and visible combat windows; 10 Hz for ordinary decisions; 30 Hz for
  near ordinary motion; and 20 Hz beyond 820 pixels.
- A decision-only tick must never consume or reset accumulated motion time. A
  motion-only tick must dispatch even when no decision is due.
- Critical ordinary phases remain on their current 60 Hz lane.
- XP sizing means linear rendered radius. The requested anchors produce small `24`
  (`12 x 2.0`) and large `33` (`22 x 1.5`). Medium becomes `28`, the rounded geometric
  midpoint, rather than staying at `16` and becoming smaller than the small tier.
- “Player projectiles” includes primary, seeker, and opening-breach rounds. All three
  plus hostile rounds use exact 0.70 multipliers:
  - hostile `3.85`;
  - primary `4.375`;
  - seeker `4.025`;
  - opening breach `4.55`.
- Projectile telegraph geometry, beam width, collision radii `5/6/7`, player primary
  base radius `7`, and every gameplay stat remain unchanged.
- The canonical visual authority pair was checked on 2026-08-05:
  `docs/design/VISUAL_SYSTEM.md` plus the inspected original `1448x1086`
  `docs/design/cardborne-universal-art-style-reference.png`, SHA-256
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
  Task constraints are one shared tailless projectile, one XP master, clear actual-size
  readability, and visual geometry independent from collision truth.
- No raster tool or image-reference input is needed during execution because no image
  bytes are created or edited.
- No user approval interlock exists inside this plan. Execution stops only if the
  evidence requires a dependency, engine replacement, gameplay-rule change, workload
  reduction, threshold reduction, or destructive scope outside this contract.

## Discovery Closure and Evidence Map

| Question | Evidence owner | Closed decision |
| --- | --- | --- |
| Why do ordinary enemies visibly step? | `vehicle_enemy_update_schedule.gd:124-154`, `vehicle_run.gd:2084-2142` | Repair the missing motion-only dispatch before considering visual interpolation. |
| Is 30/20 Hz itself the current observed cadence? | The due-list code and incomplete cadence validator | No. The scheduler computes it but does not consistently dispatch it. Add exact 60-tick count and elapsed-time fixtures. |
| Is the frame hitch a draw-call/GPU problem? | Latest focus-valid JSON: draw p95 86, 33 batches, approximately 1 ms terminal CPU/GPU render readings | Not supported. Complete physics attribution before selecting another optimization owner. |
| Why is p99 ownership incomplete? | `PERFORMANCE_DETAIL_SAMPLE_STRIDE = 7` and frame-level accumulation in `VehiclePerformanceRecorder` | Add an explicit diagnostic full-attribution mode; leave ordinary/release instrumentation sampling unchanged. |
| Can XP size change without mechanics? | `VehicleExperienceRuntime.BASE_PICKUP_RADIUS`, `VehicleCombatRenderer._sync_experience()` | Yes. Change only `VehicleStageVisualProfile.EXPERIENCE_RADII`. |
| Can projectile size change without mechanics? | Profile-owned visual multipliers and collision-owned `ProjectileState.radius` | Yes. Change only the four profile constants and their visual assertions. |
| Are new assets required? | Shared manifest/catalog/provider identities | No. No image, manifest, provider, catalog, or guidebook-preview change is authorized. |
| How is the unknown hitch owner handled without guesswork? | Full-attribution output defined below | Select the dominant owner with a fixed quantitative rule, then modify only that owner's existing responsibility boundary. |

## Proposed Design

### 1. Separate ordinary decision and motion truth

Keep one bounded schedule and one deterministic enemy order, but treat the two due
conditions independently:

1. Accumulate `decision_elapsed` and `motion_elapsed` every physics tick.
2. Set `decision_due` only when the stable 10 Hz bucket and interval are due.
3. Set `motion_due` only when the near/far motion bucket and interval are due.
4. Append the actor to the scheduled worklist when either condition is due.
5. Reset `decision_elapsed` only for `decision_due`.
6. Reset and publish `motion_elapsed` only for `motion_due`; publish `0.0` for a
   decision-only tick without consuming accumulated motion.
7. In `VehicleRun._update_scheduled_ordinary_enemy()`, return only when neither
   decision nor motion is due. A decision-only call uses zero time: it may refresh
   desired velocity or commit an eligible attack but cannot advance timers or move.
8. A motion-only call advances timers and collision-resolved movement with the full
   accumulated delta while reusing the last desired velocity.

This restores time-correct 30/20 Hz motion and 10 Hz decisions without raising either
cadence. It also avoids multiplying game speed when decision and motion happen on the
same physics tick.

Replace the fixed-parity overlap refresh with a decision-epoch parity. Each stable
actor refreshes its bounded overlap query on alternating decision epochs; all actors
therefore refresh within 0.20 seconds, while average query volume remains unchanged.
Generation changes invalidate cached values exactly as they do now.

Do not add interpolation in the first pass. Direct truth rendering is preferred because
it cannot diverge from collision. The corrected rendered trace is acceptable when a
continuously moving near actor has at most one unchanged 60 Hz render interval and a far
actor at most two, while critical actors update every interval. Only if that exact trace
fails may the executor add `vehicle_enemy_motion_interpolator.gd`: a fixed 320-slot,
generation-keyed, presentation-only interpolator capped to one observed motion interval,
with immediate snaps on generation, activation, critical phase, teleport, or a truth
offset larger than one actor radius. It must never feed AI, grid, collision, targeting,
telegraphs, or damage.

### 2. Change scale at the existing visual owner

Edit only `scripts/vehicle/vehicle_stage_visual_profile.gd` for runtime values:

```text
EXPERIENCE_RADII = small 24.0, medium 28.0, large 33.0
HOSTILE_PROJECTILE_ENVELOPE_SCALE = 3.85
PLAYER_PRIMARY_PROJECTILE_SCALE = 4.375
PLAYER_SEEKER_PROJECTILE_SCALE = 4.025
PLAYER_OPENING_BREACH_PROJECTILE_SCALE = 4.55
```

`VehicleCombatRenderer` already consumes these values and therefore needs no production
logic change. Update exact validators so they prove the new profile values, shared-image
reuse, and collision separation. The guidebook keeps its independent preview extent.

### 3. Attribute every physics tick only in diagnostic mode

Add `--performance-attribution=full` to the existing performance request. In that mode
only:

- time every top-level physics section on every tick instead of every seventh tick;
- retain a bounded list of the physics ticks contributing to the current rendered frame;
- attach that list only to the existing 64 retained slow-frame samples;
- separate top-level totals from nested `enemy_*` detail so nested timings are never
  double-counted;
- record per-frame top-level coverage, residual physics overhead, dominant owner, VSync
  mode, focus state, commit, and dirty state; and
- mark a full-attribution sample valid only when at least 90% of aggregate physics time
  in the representative p99 frame is assigned to top-level sections or explicit residual
  overhead.

Default performance and ordinary play keep the current stride and allocate no new sample
arrays. The diagnostic flag changes measurement detail, not workload or game behavior.

### 4. Repair only the measured dominant owner

After the cadence and scale corrections, run the same full-attribution peak fixture.
Across the slowest 1% of valid frames, rank non-overlapping top-level owners by aggregate
self-time. An owner qualifies for code work only when it is the largest contributor and
either exceeds 25% of aggregate physics time or 2.0 ms p95.

Use this bounded routing table:

| Dominant result | Allowed owner | Allowed correction |
| --- | --- | --- |
| `enemies_and_grid` / `enemy_scheduled_ordinary` | schedule, `VehicleRun` ordinary update path, local steering, spatial grid | Remove repeated queries or unchanged work, reuse bounded buffers, and distribute existing work; preserve 10/30/20/60 Hz, order, collision, and counts. |
| `enemy_budget_scan` | enemy schedule/store membership | Replace repeat derivation with generation-safe retained state updated on existing spawn/activation/retirement events; preserve deterministic list order and caps. |
| `enemy_wear_terrain` | enemy motion result plus terrain runtime | Visit only actors that moved or remain tracked, using existing state; preserve every entry, occupancy, and damage deadline. |
| `combat_and_effects` | projectile/effect stores and their existing run loops | Remove repeat allocation or duplicate traversal only; preserve all live counts, order, collision, and effect timing. |
| `player_and_rewards` | player/pickup/experience existing owners | Remove repeat allocation or duplicate traversal only; preserve collection and recall behavior. |
| presentation or HUD | renderer or HUD presenter, respectively | Skip unchanged writes or reuse existing buffers; preserve visible state and current refresh latency. |
| engine/scheduler/residual | launch/focus/VSync environment and recorder evidence | Reproduce in a focused foreground run. Do not alter gameplay to hide an external scheduling failure. |

If a top-level owner qualifies but its nested owner is still ambiguous, add one temporary
diagnostic split inside that owner and rerun a short diagnostic before editing behavior.
Do not optimize a runner-up on speculation. Remove temporary splits that are not useful
for the durable recorder output.

## Tasks

### M1 - Make hitch attribution decision-grade

- [ ] Extend `_parse_performance_request()` and recorder configuration with
  `--performance-attribution=full`, including native and Web query parity where relevant.
- [ ] Extend `VehiclePerformanceRecorder` with bounded contributing-physics-tick records,
  non-overlapping top-level aggregation, coverage, focus/VSync, and commit provenance.
- [ ] Extend `validate_vehicle_performance_scenarios.gd` to prove default sampling remains
  unchanged, full mode is bounded, nested timing is not double-counted, and p99 selection
  uses the correct retained frame.
- [ ] Capture one focused, clean, commit-stamped 1280x720 native `peak_horde` diagnostic
  with the exact current workload and full attribution. Reject and rerun any artifact
  with unfocused samples, a mismatched commit, dirty state, invalid fixture, or coverage
  below 90%.

Acceptance: a valid JSON identifies all contributing physics ticks and one dominant
top-level owner for the representative p99 hitch without changing scenario counts.

### M2 - Restore smooth, time-correct enemy motion

- [ ] Change `VehicleEnemyUpdateSchedule.rebuild()` so motion-only and decision-only due
  states are both dispatched and reset only their own accumulators.
- [ ] Change `_update_scheduled_ordinary_enemy()` to process decision-only work with zero
  elapsed motion and motion-only work with the exact accumulated delta.
- [ ] Add a decision epoch and alternate overlap-cache refresh per actor across epochs;
  remove the current stable-parity expression.
- [ ] Extend `validate_vehicle_enemy_update_schedule.gd` with bucket-aligned steady-state
  60-tick near/far fixtures proving 10 decision events, 30/20 motion events, no consumed
  decision-only motion, one second of accumulated motion, and unchanged critical 60 Hz
  behavior.
- [ ] Extend `validate_vehicle_enemy_local_steering.gd` with two-epoch refresh, overlap
  enter/exit, and generation-reuse cases.
- [ ] Extend `validate_vehicle_run.gd` with a collision-free one-second movement fixture
  and a blocker-recovery fixture; assert time-correct distance and unchanged attack timing.
- [ ] Capture one near/far/critical rendered motion trace. Add the bounded presentation
  interpolator only if the locked unchanged-frame criterion fails after the schedule fix.

Acceptance: motion is time-correct, near/far/critical cadence matches 30/20/60 Hz,
decisions remain 10 Hz, no actor has a permanent stale steering cache, and presentation
does not diverge from collision unless the bounded fallback was objectively required.

### M3 - Apply the requested combat-object scale corrections

- [ ] Set XP radii to `24/28/33` and the four projectile multipliers to
  `3.85/4.375/4.025/4.55` in `VehicleStageVisualProfile`, including its self-validation.
- [ ] Update `validate_vehicle_projectile_readability.gd` and
  `validate_vehicle_combat_renderer.gd` for the exact new visual products and unchanged
  shared master/collision ownership.
- [ ] Extend `validate_vehicle_experience.gd` or the renderer validator to prove the
  `1`, `2-4`, `>=5` mapping resolves to `24/28/33` while collection remains radius `34`.
- [ ] Use the existing capture gateway to record small/medium/large XP together and
  friendly/hostile projectile examples at actual gameplay scale; do not create new art.

Acceptance: XP tier order is `24 < 28 < 33`, all non-beam projectile rendered radii are
exactly 70% of the current baseline, and every collision/gameplay value is byte-for-byte
unchanged in its owner.

### M4 - Remove the measured hitch

- [ ] Run a full-attribution diagnostic after M2-M3 and select the owner with the locked
  25% / 2.0 ms rule.
- [ ] Implement one responsibility-local correction from the routing table; add only the
  focused regression needed for the changed owner.
- [ ] Use short peak diagnostics only to compare attribution and reject regressions. They
  are measurements, not completion gates.
- [ ] Repeat owner-local correction only while a valid artifact identifies a qualifying
  dominant owner. Never lower workload, cadence, visual quality, or thresholds.
- [ ] Produce one clean, focused, commit-stamped 60-second native `peak_horde` result
  after the last correction.

Acceptance: native peak workload is valid and passes p95, p99, median FPS, 1% low,
consecutive-hitch, draw-call, and batch thresholds.

### M5 - Run one final gate and retire the plan

- [ ] Run Godot import and the complete `validate_vehicle_*.gd` suite once.
- [ ] Run `validate_cardborne_visual_authority.ps1`, Web export, one foreground native
  smoke, and one visible built-Web smoke once.
- [ ] Run final native `peak_horde` and `capacity_pressure`, then one visible built-Web
  `peak_horde`. Do not run the 600-second lifecycle soak because this plan changes no
  production pool, capacity, lifecycle, or unbounded allocation owner.
- [ ] Review actual-scale XP/projectile captures and the near/far/critical motion trace for
  clipping, deceptive hit boundaries, tier ambiguity, and visible stepping.
- [ ] Update `.agents/semantic-v2-runtime-acceptance-evidence.md` with exact commits,
  artifacts, workload counts, metrics, and any valid environmental limitation.
- [ ] Incorporate any durable contract correction into its canonical spec, mark this plan
  done, and retire it according to `.agents/PLANS.md`.

Acceptance: all mechanical checks pass, native and Web peak gates pass, capacity physics
passes, the worktree contains no out-of-scope visual/UI/map change, and evidence is tied
to the exact clean commit.

## Test Plan

### Focused implementation checks

Run the focused bundle once after M1-M3 code is integrated; during M4 add only the
validator owned by the measured correction:

```powershell
$checks = @(
  'validate_vehicle_enemy_update_schedule.gd',
  'validate_vehicle_enemy_local_steering.gd',
  'validate_vehicle_run.gd',
  'validate_vehicle_combat_renderer.gd',
  'validate_vehicle_projectile_readability.gd',
  'validate_vehicle_experience.gd',
  'validate_vehicle_performance_scenarios.gd'
)
foreach ($name in $checks) {
  .\tools\godot.ps1 --path . --headless --script "res://tools/validation/$name"
  if ($LASTEXITCODE -ne 0) { throw "validator failed: $name" }
}
```

### Full-attribution diagnostic

```powershell
$revision = (git rev-parse HEAD).Trim()
if (git status --porcelain) { throw 'diagnostic commit must be clean' }
$env:PERFORMANCE_COMMIT = $revision
$env:PERFORMANCE_DIRTY = '0'
$output = "build/performance/urgent-stabilization/profiles/$($revision.Substring(0, 8))-peak-horde-full-attribution-native-1280x720.json"
.\tools\godot.ps1 --path . --rendering-method gl_compatibility --resolution 1280x720 --disable-vsync -- `
  --performance-scenario=peak_horde `
  "--performance-output=res://$output" `
  --performance-warmup=10 --performance-duration=60 `
  --performance-attribution=full
if ($LASTEXITCODE -ne 0) { throw 'full-attribution diagnostic failed' }
```

The artifact is invalid if `git.commit` differs from `$revision`, `git.dirty` is true,
the window has any unfocused sample, the scenario workload is invalid, or p99 top-level
coverage is below 90%.

### One final broad gate

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

### Final performance runs

Run the native scenarios from the exact clean implementation commit. A result is invalid
unless it is commit-matched, clean, fully focused, authority-eligible, fixture-valid, and
passing:

```powershell
$revision = (git rev-parse HEAD).Trim()
if (git status --porcelain) { throw 'final performance commit must be clean' }
$env:PERFORMANCE_COMMIT = $revision
$env:PERFORMANCE_DIRTY = '0'

foreach ($scenario in @('peak_horde', 'capacity_pressure')) {
  $output = "build/performance/urgent-stabilization/final/native-$scenario.json"
  .\tools\godot.ps1 --path . --rendering-method gl_compatibility --resolution 1280x720 --disable-vsync -- `
    "--performance-scenario=$scenario" `
    "--performance-output=res://$output" `
    --performance-warmup=10 --performance-duration=60
  if ($LASTEXITCODE -ne 0) { throw "native performance failed: $scenario" }
  $result = Get-Content -LiteralPath $output -Raw | ConvertFrom-Json
  if (
    $result.git.commit -ne $revision -or $result.git.dirty -or
    [int]$result.execution_environment.unfocused_samples -ne 0 -or
    -not $result.authoritative -or
    -not $result.execution_environment.authority_eligible -or
    -not $result.scenario_validation.valid -or
    -not $result.thresholds.passed
  ) { throw "invalid or failing native result: $scenario" }
}
```

For Web, load `$npjt-port-guard`, resolve the fastrun manager's `codex` lane for this
project, and inspect the listener before starting anything. Reuse a listener only when
its PID, command line, project path, and served files prove that it owns this production
export. Otherwise, if the port is free, start one task-owned hidden static server for
`build/web` and retain its PID for cleanup; an unknown conflicting listener is a stop
condition, not permission to kill it or select an ad hoc port.

Use Chrome DevTools MCP to open the exact visible URL below at 1280x720:

```text
http://127.0.0.1:<codexPort>/?performance_scenario=peak_horde&performance_warmup=10&performance_duration=60
```

Before waiting, require `document.hasFocus() == true`,
`document.visibilityState == "visible"`, and a user agent without `HeadlessChrome`.
Save the exact parsed `window.__cardbornePerformanceResultJson` as
`build/performance/urgent-stabilization/final/web-peak_horde.json`; require scenario
`peak_horde`, `authoritative == true`, `execution_environment.authority_eligible == true`,
`scenario_validation.valid == true`, and `thresholds.passed == true`. Stop only the
retained task-owned server PID; leave a proven reused server running.

Final performance acceptance remains unchanged:

- native 1280x720: p95 at most 18 ms, p99 at most 25 ms, median at least 59 FPS,
  1% low at least 55 FPS, and at most one consecutive frame over 33.3 ms;
- visible Web 1280x720: p95 at most 20 ms, p99 at most 33.3 ms, median at least
  58 FPS, 1% low at least 50 FPS, and at most two consecutive frames over 33.3 ms;
- capacity physics: p95 at most 6 ms and p99 at most 8 ms; and
- draw-call p95 at most 200 and combat batches at most 50.

## Rollback / Safety

- Commit M1 instrumentation separately from M2 behavior, M3 scale, and M4 optimization.
- Do not reset, clean, stage, or rewrite unrelated user work.
- If the schedule repair changes attack cadence, collision outcomes, or total one-second
  movement, revert only that milestone and correct the split before continuing.
- If an optimization changes fixture counts, deterministic ordering, gameplay cadence,
  or collision truth, discard that optimization even if frame time improves.
- Revert scale constants and their validator expectations together; no asset rollback is
  necessary because no image bytes change.
- Keep diagnostic arrays behind the explicit performance flag and bounded to current
  frame plus 64 slow samples.

## Risks

- Restoring previously discarded 30/20 Hz motion increases legitimate collision work.
  Mitigation: measure the corrected workload and optimize its actual owner; do not keep
  the bug as a performance shortcut.
- Direct 30/20 Hz rendering may still show mild cadence at high refresh rates.
  Mitigation: use the locked rendered-trace criterion and only then add the bounded,
  presentation-only fallback.
- Larger XP visuals can visually approach the 34-pixel collection radius.
  Mitigation: large remains radius 33 and the validator keeps collection independent.
- Smaller projectile silhouettes can under-communicate collision.
  Mitigation: retain the bright core, actual-scale debug overlay, and exact collision
  assertions; do not shrink the PNG itself.
- Full attribution adds diagnostic overhead.
  Mitigation: compare full mode only to full mode for ownership; use default mode for the
  final release result.
- Window focus or driver scheduling can invalidate native evidence.
  Mitigation: reject unfocused runs explicitly and never compensate by changing gameplay.

## Open Questions

None at plan start. The previously implicit medium XP tier is fixed at radius `28`, all
three player projectile variants are included, the first enemy-motion correction is the
confirmed scheduler defect, and any later performance edit is selected by the quantitative
owner rule rather than another user approval.

## Decision Notes

- 2026-08-05: Reused the sole active runtime-stabilization ExecPlan instead of creating a
  competing plan for the same outcome.
- 2026-08-05: Removed completed UI/art-generation/history detail from the active checklist;
  Git and the active product/visual specifications retain the durable result.
- 2026-08-05: Identified discarded motion-only schedule work as the first enemy-stutter
  defect; direct rendering alone was not treated as the root cause.
- 2026-08-05: Chose `24/28/33` XP radii to honor the requested small/large multipliers
  without reversing the medium tier.
- 2026-08-05: Interpreted 30% smaller projectiles as exact linear scale `0.70` for hostile,
  primary, seeker, and opening-breach visuals.
- 2026-08-05: Kept one final broad validation pass; intermediate performance runs are
  diagnostic measurements required to select and confirm the hot owner.

## Progress

- [x] Read the current product spec, complete visual authority, design-source map, active
  ExecPlan standard, current implementation owners, focused validators, and recent Git
  history.
- [x] Verified the canonical visual reference hash and original dimensions.
- [x] Ran the six focused baseline validators; all passed and their missing cadence
  coverage is documented above.
- [x] Parsed the latest focus-valid performance evidence and captured a commit-stamped but
  correctly rejected unfocused current-HEAD diagnostic.
- [x] Closed the XP-tier, projectile-family, collision-separation, scheduler-cadence,
  performance-attribution, and validation-scope decisions.
- [ ] M1 is the next implementation milestone. No game code or visual asset has been
  changed while writing this plan.

## Next Steps

Start at M1. Implement only diagnostic attribution, commit it independently, and capture
the focused clean baseline before changing schedule behavior. Then execute M2 through M5
without pausing for approval unless a stated stop condition is reached.

## Completion

This plan is complete only when M1-M5 are checked, motion and scale contracts pass,
native/Web peak and native capacity evidence passes on the exact clean commit, the
evidence record is updated, no out-of-scope UI/map/asset work entered the diff, and the
plan is retired under `.agents/PLANS.md`.
