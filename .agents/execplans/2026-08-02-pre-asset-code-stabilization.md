---
type: plan
status: active
owner: BK
created: 2026-08-02
last_reviewed: 2026-08-05
topic: Combat correctness, telegraph cleanup, and frame-pacing stabilization
scope: Ordinary attack delivery, player damage protection, hostile projectile readability, circular attack telegraphs, and remaining combat hot paths
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/design/cardborne-universal-art-style-reference.png
  - ../../docs/design/visual-replacement-workbench/README.md
  - ../semantic-v2-runtime-acceptance-evidence.md
---

# Combat Correctness and Frame Pacing - Execution Contract

Verified baseline commit `448470dc` contains a confirmed ordinary-attack state regression: normal
attackers enter `startup` but never advance to `active`, so they create no projectiles
and deliver no ordinary damage. This contract restores that combat path first, removes
the malformed black treatment from circular warnings, repairs an unsafe motion fast
path, and then requalifies the corrected workload with one consolidated correctness,
visual, export, and performance gate. It does not claim an unproven performance fix.

## Purpose

- Objective: restore normal enemy attacks and player damage while preserving fixed-Hard
  behavior, make hostile shots and circular danger boundaries readable, correct the
  unsafe collision shortcut, and measure frame pacing under the restored workload.
- Deliverable: corrected scheduling/damage code, one normalized shared ring cue, focused
  regression coverage, actual-scale combat captures, and commit-stamped performance
  evidence.
- Completion state for Phases 1-3: ordinary attacks progress and hit, circular warnings
  contain no malformed black line, and collision remains exact. Full plan completion
  additionally requires the existing release thresholds to pass under the restored
  workload; a valid failure is recorded evidence, not permission to weaken the gate.

## Scope and Boundaries

In scope:

- Ordinary `startup`, `active`, and `interrupted_recovery` execution at 60 Hz.
- Normal hostile projectile creation, collision delivery, and player hull damage.
- The existing barrier `blockable` contract.
- The shared `cue/ring` alpha/color mask and ARC circular-warning decoration.
- The selected tactical-layout safe-motion proof and its exact fallback.
- Focused validators, actual-scale captures, Web export/smoke, and native performance.

Out of scope:

- UI, HUD layout, upgrade cards, menus, localization, maps, floor/wall art, or items.
- Enemy counts, attack rules, threat budgets, damage, speed, range, lifetime, projectile
  collision radii, or fixed-Hard difficulty.
- Player projectile scale or the previously requested XP sizes.
- New dependencies, engine changes, native extensions, or reduced release thresholds.

Constraints and invariants:

- Player intent, damage, committed attacks, and visible attack windows remain 60 Hz.
- Ordinary decisions remain 10 Hz; non-committed motion remains 30 Hz near and 20 Hz
  far. A motion-only event never runs decision work.
- Hostile collision, cover, crate, spatial-grid, and first-hit truth stay exact.
- The hostile projectile presentation multiplier remains `3.85`; the confirmed reason
  shots disappear is failed creation, not renderer clipping. Reconsidering that earlier
  user-requested 30% reduction is a separate visual decision after live shots exist.
- `cue/ring` keeps its current ID, path, `128x128` canvas, and `64,64` pivot. This plan
  normalizes a defective approved mask; it does not add, retire, or rename an asset.
- The mandatory visual authority is `docs/design/VISUAL_SYSTEM.md` plus the inspected
  `1448x1086` reference PNG at
  `docs/design/cardborne-universal-art-style-reference.png`, with SHA-256
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.

Destructive or irreversible actions:

- None. Every change is version-controlled and scoped to existing owners.

Exact actions requiring owner or user approval:

- None inside this contract. A production dependency/native rewrite, gameplay workload
  reduction, cadence change, or threshold change remains outside scope and requires a
  separate explicit authorization.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Player appears invulnerable | Normal deployment clears protection and `_damage_player` reduces hull; three focused validators pass | `vehicle_run.gd::_reset_run_state`, `_damage_player`; `validate_vehicle_damage_feedback.gd` | Fix attack delivery, not base hull arithmetic | 1.1, 1.2 |
| Ordinary projectiles are absent | Live probe: shooter/turret/interceptor enter startup at ticks `11/11/8`, remain there for 180 ticks, and create `0` shots | `_update_scheduled_ordinary_enemy`; temporary probe removed with clean worktree | Route critical entries through full critical-state work; reserve motion-only helper for noncritical motion-only entries | 1.1 |
| Environmental damage can be wrongly absorbed | `_damage_player` accepts `blockable` but its barrier branch ignores it | `vehicle_run.gd:4223-4242` | Gate barrier absorption with `blockable` | 1.2 |
| Hostile shots were intentionally reduced | `9a59d2d0` changed hostile scale `5.50 -> 3.85`; renderer layer and clipping are correct | `vehicle_stage_visual_profile.gd`, `_sync_projectiles` | Keep `3.85` while restoring actual live shots; capture it at gameplay scale | 1.3 |
| Circular warnings show black lines | `cue_ring.png` contains 204 fully opaque black pixels; ARC areas also add two black-edged beam strips | `_sync_area_telegraph`, `_write_danger_ring`, manifest `cue/ring` | Normalize the ring into a tintable white-alpha mask and remove ARC cross-bars | 2.1, 2.2 |
| Enemy movement can cross selected cover | Current fast path proves only static catalog clearance, then skips tactical-layout cover lookup | `_runtime_motion_cover_rects`, `StageCatalog.is_fast_motion_clear` | Replace it with one combined layout-owned safe-cell proof | 3.1 |
| Stutter is physics catch-up | Diagnostic recorded 3,600 physics ticks but only 797 rendered frames; physics accumulated to `160.01 ms` at frame p99 and enemy/grid owned 58.6% of the 64 worst frames | `build/performance/root-cause/full-detail-current-60s.json` | Preserve workload, correct the unsafe shortcut, and remeasure only after attacks work | 3.1, 4.2 |
| Primary remaining hot owners | Peak p95: scheduled ordinary `26.55 ms`; combat/effects `4.89 ms`; renderer is not the root | `build/performance/urgent-stabilization/final-df2d1744-focused-peak-horde-60s.json` | Do not add an unmeasured pooling rewrite or disguise the result with lower load; any further optimization needs new evidence | 4.2 |

Readiness statement:

- Product behavior, ownership, visual authority, safety boundaries, implementation
  order, and validation commands are closed.
- No correctness or visual implementation task is an investigation placeholder.
- Remaining uncertainty is only whether the authorized GDScript-safe changes meet the
  existing performance gate; failure has the predetermined stop response below and
  cannot authorize a native dependency or workload reduction by implication.

## Assumptions and Locked Decisions

- The attack-freeze regression introduced by `31f8cd55` is the common cause of ordinary
  projectile absence and the apparent normal-enemy invulnerability.
- Boss and environmental delivery remain separate; they are not rewritten to solve an
  ordinary scheduling defect.
- Critical actors are already committed. Their 60 Hz state advancement must not consume
  another threat-budget slot or begin a second attack.
- The ring remains one authored texture whose RGB is neutral and whose alpha supplies
  the single boundary. Runtime continues to own center, radius, readiness, tint, and
  alpha.
- ARC affinity remains readable through tint and a restrained center marker; two full
  diameter cross-bars are decorative duplication and are removed.
- Performance is measured only after attack delivery is restored so the result includes
  real hostile projectile and impact work.

## Proposed Design

### 1. Separate critical combat from motion-only dispatch

Handle `critical_delta >= 0` before evaluating scheduled due flags. Advance a critical
ordinary actor through `_update_ordinary_enemy` with the physics delta for state and
motion, `decision_due=true` for phase logic, and `can_commit=false` because commitment
already occurred. Keep position/grid/wear reconciliation identical to the existing full
path. Only a noncritical scheduled entry with `motion_due=true` and
`decision_due=false` may call `_update_motion_only_ordinary_enemy`.

Barrier absorption becomes conditional on `blockable`. A barrier still absorbs normal
hostile projectiles, contact, and mines; Arc Surge and Wear Collapse calls that already
pass `false` reach hull and leave barrier strength unchanged.

### 2. Normalize circular attack presentation

Normalize `cue_ring.png` as a neutral white RGB alpha mask: one connected antialiased
annulus, transparent interior/exterior, no opaque black pixel or black RGB fringe. Keep
the existing manifest identity and batch.

In `_sync_area_telegraph`, preserve the exact outer ring and readiness tint but remove
the horizontal/vertical beam-strip pair for ARC. Use at most one small center marker;
do not add another ring, bar, or decorative part. Corridor and active-beam rendering are
unchanged.

### 3. Make the motion shortcut provably safe

`VehicleStageTacticalLayout.configure()` builds `_safe_motion_cells_36` plus
`_fast_motion_min_cell`, `_fast_motion_width`, and `_fast_motion_height` once from
`geometry_snapshot.world_rect`, and keeps them immutable for that layout fingerprint.
The mask uses `80.0` world-unit cells to
match `StageCatalog.COLLISION_CELL_SIZE`. A cell is marked safe only when its complete
cell rectangle grown by `36.0` is enclosed by one walkable rectangle and is disjoint
from every void, selected tactical cover, structural-wall footprint, and initial
breakable-bulkhead footprint in `geometry_snapshot`. This conservative rule may reject
open cells spanning two walkable rectangles; those cells use the exact solver.

The exact public query is
`is_fast_motion_clear(from: Vector2, to: Vector2, radius: float) -> bool`. It returns
false when `geometry_snapshot` is absent, `radius > 36.0`, either point is outside the
compiled bounds, the points are in different `80.0` cells, or that cell is not
certified. `vehicle_run.gd` may bypass
the exact stage solver only when both this query and
`StageCatalog.is_fast_motion_clear()` return true and no current runtime structural wall
or live bulkhead intersects the sweep. The radius-76 stage boss therefore always uses
the exact path. Crate collision remains in the existing post-move exact check. The mask
is rebuilt only by `configure()` when a new immutable layout/fingerprint is selected;
opening a bulkhead can leave a cell conservatively unsafe but can never make it falsely
safe.

## Tasks

### Phase 1 - Restore ordinary attacks and hull damage

Goal: ordinary attackers complete their committed phases, create their attacks, and can
damage the player under normal protection rules.

Source owners: `scripts/vehicle/vehicle_run.gd`,
`scripts/vehicle/vehicle_run_capture_gateway.gd`,
`scripts/vehicle/vehicle_run_capture_driver.gd`,
`tools/validation/validate_vehicle_run.gd`,
`tools/validation/validate_vehicle_damage_feedback.gd`, and
`tools/validation/validate_vehicle_run_capture_driver.gd`

- [ ] **1.1 Restore 60 Hz critical phase advancement**
  - Change: add the explicit critical branch and keep motion-only dispatch exclusive to
    noncritical motion-only schedule entries.
  - Accept: shooter, turret, and interceptor fixtures each progress
    `move -> startup -> active/recovery` and add a hostile projectile; a chaser/contact
    fixture completes its damaging window; no second commitment is counted.
- [ ] **1.2 Honor unblockable damage**
  - Change: require `blockable` before barrier absorption.
  - Accept: blockable hostile damage consumes barrier, unblockable terrain damage
    reduces hull without consuming barrier, and accepted hull damage grants exactly one
    second of post-hit protection.
- [ ] **1.3 Lock live hostile-shot evidence**
  - Change: add `ordinary_projectile` to the driver's full-evidence fixture sequence,
    implement that fixture in `vehicle_run_capture_gateway.gd`, and extend the exact
    file list. Create the shooter with `_make_enemy`/`_append_enemy`, advance its real
    committed path with `_update_scheduled_ordinary_enemy`, and advance flight/hit with
    `_update_projectiles`; never call `_spawn_hostile_projectile` directly. Save
    `09-effects-projectile-hostile-startup.png`,
    `09-effects-projectile-hostile-flight.png`, and
    `09-effects-projectile-hostile-hit.png` under the requested capture directory.
  - Accept: the current shared teardrop is visible at `3.85`, renders above actors, and
    the accepted hit retires the projectile and changes hull immediately; the gateway
    asserts startup/active transition, projectile count, and before/after hull instead
    of manufacturing a projectile directly. The capture validator asserts the fixture
    token and all three filenames.

### Phase 2 - Remove malformed circular-warning lines

Goal: circular attack boundaries remain exact and readable without black artifacts or
full-diameter decorative bars.

Source owners: `docs/design/visual-replacement-workbench/replacement-workbench.json`,
`docs/design/visual-replacement-workbench/to-be/assets/art/visuals/production/gameplay/effects/cues/cue_ring.png`,
`art/visuals/production/gameplay/effects/cues/cue_ring.png`,
`scripts/presentation/vehicle_combat_renderer.gd`,
`scripts/vehicle/vehicle_run_capture_gateway.gd`, and
`tools/validation/validate_vehicle_attack_route_readability.gd`

- [ ] **2.1 Normalize the shared ring mask**
  - Change: reopen the existing `gameplay_code_asset_rasterization` workbench unit and
    replace only its mirrored `cue_ring.png` TO-BE bytes. Call ImageGen with
    `referenced_image_paths` containing both exact paths
    `docs/design/cardborne-universal-art-style-reference.png` and
    `art/visuals/production/gameplay/effects/cues/cue_ring.png`; record
    `image_gen.referenced_image_paths` and the canonical hash in
    `visual_authority_evidence`. Rebuild
    `docs/design/visual-replacement-workbench/index.html`; it must show the production
    AS-IS and exact switch-ready TO-BE at native and mine/boss gameplay scales before
    promotion, with no user response gate.
  - Apply: set the unit to `approved_for_switch` against a clean candidate commit and
    refresh its exact eight-file ledger. Require the other seven TO-BE hashes to equal
    their current production hashes, run
    `promote_visual_replacement_unit.ps1 -UnitId gameplay_code_asset_rasterization -Apply`,
    then commit the changed production ring and return the unit to `applied` with that
    exact applied commit. The tool copies all eight unit deliverables; the hash equality
    check guarantees that only `cue_ring.png` changes bytes.
  - Accept: canvas/pivot/manifest ID are unchanged; every nontransparent pixel has
    neutral RGB, the alpha annulus is one connected boundary, and opaque black pixel
    count is zero. The rebuilt workbench and visual-authority validators pass and the
    unit's exact SHA-256 ledger matches promoted production bytes.
- [ ] **2.2 Simplify ARC area decoration**
  - Change: remove the two beam strips from ARC circular areas and retain at most one
    restrained center marker. Add `arc_area_telegraphs` to the driver's full-evidence
    fixture sequence, implement it in the gateway, and save
    `09-effects-arc-mine-startup.png` and
    `30-boss-01-stage-1-arc-area-startup.png` at real runtime scale.
  - Accept: mine and boss ARC captures show the exact outer radius with no black line;
    corridor/beam geometry and all attack timing/damage are byte-for-byte unaffected.
    `FULL_CAPTURE_FILES` and its validator increase from `77` to exactly `82`, contain
    all five new unique filenames, and assert both new fixture tokens.

### Phase 3 - Correct the motion-collision fast path

Goal: stop the shortcut from allowing actors through selected layout cover without
lowering combat load or changing exact fallback behavior.

Source owners: `scripts/vehicle/vehicle_stage_tactical_layout.gd`,
`scripts/vehicle/vehicle_run.gd`, relevant navigation/performance validators

- [ ] **3.1 Replace static-only motion clearance with combined clearance**
  - Change: add `FAST_MOTION_CELL_SIZE := 80.0`,
    `FAST_MOTION_RADIUS := 36.0`, `_safe_motion_cells_36`,
    `_fast_motion_min_cell`, `_fast_motion_width`, `_fast_motion_height`, the
    configure-time builder, and the exact `is_fast_motion_clear(...)` query described
    above. Consume the logical AND of the layout and `StageCatalog` proofs from
    `_runtime_motion_cover_rects`/`_move_actor`; otherwise collect selected covers and
    current runtime blockers and call the existing exact solver.
  - Accept: open same-cell motion reaches the identical destination; static edge,
    selected tactical cover, structural wall, live bulkhead, and crate cases all retain
    exact blocking; an opened bulkhead may remain on the exact fallback but never becomes
    passable by a false positive; radius `> 36.0`, different-cell, and out-of-bounds
    queries return false; 10/30/20/60 Hz counts and per-move grid truth are unchanged.

### Phase 4 - Run one consolidated final gate

Goal: prove the corrected workload is functional, visually clean, exportable, and
measure whether it meets the unchanged frame-pacing gate.

- [ ] **4.1 Run the focused correctness and visual batch once**
  - Run the exact commands in the Test Plan after Phases 1-3 are complete.
  - Accept: every named validator, authority check, import, Web export, and
    `git diff --check` passes; actual-scale captures show attack progression, hull loss,
    projectile continuity, and clean mine/boss ARC circles.
- [ ] **4.2 Run authoritative performance once per scenario**
  - Harness: at the start of `_start_performance_scenario()`, before warmup or recorder
    sampling, call `DisplayServer.window_move_to_foreground()` only when not Web and
    only when `DisplayServer.has_method("window_move_to_foreground")`. This path is
    reachable only for an explicit performance request; normal gameplay never changes
    window focus. Lock that guard in `validate_vehicle_performance_scenarios.gd`.
  - Run clean commit-stamped `peak_horde` and `capacity_pressure` native scenarios with
    normal stride-7 instrumentation, then the built-Web smoke/performance path only
    after both native runs pass their validity and threshold checks.
  - Pass: scenario counts/cadence are unchanged; peak frame p95/p99 are at most
    `18/25 ms`, median at least `59 FPS`, 1% low at least `55 FPS`, and no more than one
    consecutive frame exceeds `33.3 ms`; capacity physics p95/p99 are at most `6/8 ms`;
    draw p95 remains at most `200` and combat batches at most `50`.
  - Valid failure: save the unchanged-workload result, leave this plan active at 4.2,
    and report that no further safe optimization has been proven. Do not mark the plan
    done or infer authority for workload, cadence, threshold, engine, or dependency
    changes.

## Test Plan

Do not run the broad suite between phases. Add focused assertions with their owning
changes, then run this consolidated batch once after Phase 3:

```powershell
.\tools\godot.ps1 --path . --headless --import
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed' }

$validators = @(
  'validate_vehicle_enemy_update_schedule.gd',
  'validate_vehicle_run.gd',
  'validate_vehicle_damage_feedback.gd',
  'validate_vehicle_projectile_readability.gd',
  'validate_vehicle_attack_route_readability.gd',
  'validate_vehicle_field_layout_generation.gd',
  'validate_vehicle_navigation_clearance.gd',
  'validate_vehicle_performance_scenarios.gd',
  'validate_vehicle_run_capture_driver.gd',
  'validate_vehicle_visual_replacement_coverage.gd'
)
foreach ($validator in $validators) {
  .\tools\godot.ps1 --path . --headless --script "res://tools/validation/$validator"
  if ($LASTEXITCODE -ne 0) { throw "validator failed: $validator" }
}

.\tools\validation\validate_cardborne_visual_authority.ps1
if ($LASTEXITCODE -ne 0) { throw 'visual authority validation failed' }
.\tools\design\build_visual_replacement_workbench.ps1 -Check
if ($LASTEXITCODE -ne 0) { throw 'workbench generated outputs are stale' }
.\tools\validation\validate_visual_replacement_workbench.ps1
if ($LASTEXITCODE -ne 0) { throw 'workbench validation failed' }
.\tools\export_web.ps1
if ($LASTEXITCODE -ne 0) { throw 'Web export failed' }
git diff --check
if ($LASTEXITCODE -ne 0) { throw 'git diff check failed' }
```

After that batch, generate the exact capture evidence through the existing capture
owner. The five new files named in Tasks 1.3 and 2.2 must exist and the capture manifest
must record the requested `1280x720` viewport:

```powershell
$short = (git rev-parse --short=8 HEAD).Trim()
$captureDir = Join-Path (Resolve-Path .).Path "build\captures\combat-correctness-$short"
$captureArgs = @(
  '--path', (Resolve-Path .).Path,
  '--rendering-method', 'gl_compatibility', '--',
  "--capture-all=$captureDir", '--capture-locale=ko', '--capture-size=1280x720',
  '--layout-seed=12886704'
)
.\tools\godot.ps1 @captureArgs
if ($LASTEXITCODE -ne 0) { throw 'combat evidence capture failed' }
```

Review those five PNGs at original detail. Reject clipping, opaque black pixels/fringes,
ARC cross-bars, a projectile hidden behind an actor, a manufactured projectile fixture,
or a hit capture whose recorded hull did not decrease. The workbench report owns the
ring AS-IS/TO-BE comparison; the capture directory owns post-switch runtime evidence.

Commit the Phase 1-3 implementation and evidence-owned source changes before measuring.
Run native performance from that exact clean tracked commit at `1280x720`, GL
Compatibility, VSync disabled, 10-second warmup, 60-second sample, zero unfocused
samples, matching commit metadata, and the normal stride-7 recorder:

```powershell
$trackedDirty = @(git status --porcelain --untracked-files=no)
if ($trackedDirty.Count -ne 0) { throw 'performance requires a clean tracked commit' }
$perfCommit = (git rev-parse HEAD).Trim()
$short = $perfCommit.Substring(0, 8)
New-Item -ItemType Directory -Force -Path 'build\performance\combat-correctness' | Out-Null
$env:PERFORMANCE_COMMIT = $perfCommit
$env:PERFORMANCE_DIRTY = '0'
try {
  foreach ($scenario in @('peak_horde', 'capacity_pressure')) {
    $output = "res://build/performance/combat-correctness/final-$short-$scenario-60s.json"
    .\tools\godot.ps1 --path . --rendering-method gl_compatibility `
      --resolution 1280x720 --position 40,40 --disable-vsync -- `
      "--performance-scenario=$scenario" "--performance-output=$output" `
      '--performance-warmup=10' '--performance-duration=60'
    if ($LASTEXITCODE -ne 0) { throw "performance scenario invalid: $scenario" }
  }
} finally {
  Remove-Item Env:PERFORMANCE_COMMIT -ErrorAction SilentlyContinue
  Remove-Item Env:PERFORMANCE_DIRTY -ErrorAction SilentlyContinue
}
```

Both native JSON files must report the exact commit, `dirty=false`, supported viewport,
zero unfocused samples, authoritative scenario counts, and `thresholds.passed=true`.
If either file is invalid, correct only the environment and rerun that scenario. If it
is valid but fails thresholds, record the failure and stop at Task 4.2 without running
Web performance.

Only after both native files pass, query the fastrun manager's `codex` lane, serve the
already-built export, and use the Chrome DevTools browser in a visible foreground tab:

```powershell
$repo = (Resolve-Path .).Path
$guard = 'C:\Users\BK\.codex\skills\npjt-port-guard\scripts\npjt_port_guard.py'
$codexPort = py -3.11 $guard --project $repo --service web --print-port
if ($LASTEXITCODE -ne 0 -or -not $codexPort) { throw 'codex port resolution failed' }
$server = Start-Process -FilePath 'py' -ArgumentList @(
  '-3.11', '-m', 'http.server', "$codexPort", '--bind', '127.0.0.1',
  '--directory', (Join-Path $repo 'build\web')
) -WindowStyle Hidden -PassThru
```

Open
`http://127.0.0.1:<codexPort>/?performance_scenario=peak_horde&performance_warmup=10&performance_duration=60`,
keep the tab visible, poll `window.__cardbornePerformanceResultJson`, parse the returned
JSON string, and save it unchanged with `apply_patch` as
`build/performance/combat-correctness/final-<shortcommit>-web-peak-horde-60s.json`.
Require `execution_environment.authority_eligible=true`, visible/non-headless state,
valid counts, and `thresholds.passed=true`. Before cleanup, read the server PID's command
line and require it to contain the resolved port, `http.server`, and this repository's
`build\web`; then stop only `$server.Id`. Never stop a server discovered only by port or
process name.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Task review | Static code/asset contract and newly added assertion review | Each task is implemented | Its owned input changes |
| Final focused gate | The command batch above plus capture review | All Phase 1-3 tasks pass review | A covered source/asset changes |
| Final performance gate | One valid peak and capacity run, then built Web | Focused gate passes on a clean commit | Runtime/performance input changes |

Validation rules:

- A failed check is rerun only after a relevant task-owned change.
- Do not run the full 58-validator historical matrix again; the named focused set covers
  the changed owners and Web export supplies the production build gate.
- Diagnostic stride-1 profiling may explain ownership but cannot qualify release.
- Do not accept a performance improvement produced by frozen attacks, missing
  projectiles, reduced populations, lower cadence, or invalid focus/commit metadata.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A critical fixture progresses but creates no shot | Trace only the existing role eligibility, pool return, and spawn path; fix the task-owned defect without changing attack rules | Replan only if a product rule is contradictory |
| Ring normalization changes canvas, pivot, ID, or radius | Reject the output and retain the existing production bytes | No new visual ID or manifest switch is authorized |
| Combined safe cache disagrees with exact collision | Mark that cell unsafe and use the exact fallback | Never loosen collision to retain a fast path |
| Native result is invalid or unfocused | Discard it and rerun once after correcting the environment | Do not tune gameplay against invalid evidence |
| Valid final performance still misses the locked gate | Save the evidence and leave this plan active at 4.2; report the quantified gap | A native/dependency rewrite or workload/cadence change requires new explicit authority; do not choose one implicitly |
| A material fact contradicts this contract | Stop only the affected branch and update this contract | Do not silently choose new product, architecture, visual, or safety behavior |

Implementation-local discoveries may be handled without a user pause when they do not
change visible behavior, ownership, architecture, dependencies, safety, or acceptance.

## Rollback / Safety

- Commit combat correctness, telegraph cleanup, collision-proof changes, and final evidence
  as separate coherent task-owned commits.
- Never reset, clean, stage, or rewrite unrelated user work.
- Revert the critical dispatch and its assertions together if it changes attack timing;
  do not restore the frozen path as an optimization.
- Revert `cue_ring.png` and its renderer change together if its geometry no longer
  matches the gameplay radius.
- Remove a fast path that disagrees with the exact solver; preserve the solver.

## Risks

- Restoring ordinary attacks adds the projectile and impact work that the failed path
  omitted. Performance must be judged only under that corrected load.
- The current motion shortcut is faster partly because it can ignore selected cover.
  Correcting it may expose more exact-solver work; performance cannot take precedence
  over collision truth.
- No allocation/GC rewrite is included because current evidence does not identify it as
  a material hitch owner. The authorized correctness changes may still miss the release
  gate, and this contract deliberately does not invent an optimization to promise a pass.
- A clean ring alpha mask must not become a second radius owner; runtime scale remains
  authoritative.

## Open Questions

None inside the authorized scope. A native acceleration path or gameplay workload
change is intentionally not selected without explicit user authority.

## Decision Notes

- 2026-08-05: Replaced the earlier mostly completed plan body with this compact remaining
  execution contract rather than creating a competing active plan.
- 2026-08-05: A live temporary probe proved the apparent player invulnerability and
  absent ordinary shots share one critical-dispatch regression. The probe was removed;
  the worktree returned clean.
- 2026-08-05: Kept the user-requested hostile projectile scale reduction because shots
  currently disappear before rendering. Scale is not used to conceal the spawn defect.
- 2026-08-05: Visual-authority inspection locked one clean tintable ring and removal of
  the ARC cross-bars; no UI or map visual is included.
- 2026-08-05: Performance work remains behavior-preserving. No cadence, population,
  collision, workload, or threshold reduction is authorized.
- 2026-08-05: Removed the proposed effect-dictionary pool because no measurement tied it
  to the observed hitch tail. Performance is now a truthful requalification boundary,
  not an unproven implementation promise.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Completed baseline: prior scheduling/cadence separation, XP/projectile scale work,
  diagnostic ownership capture, Web export/smoke, and failed release evidence through
  commit `448470dc`.
- Current phase: Phase 1.
- Next task: 1.1 restore 60 Hz critical phase advancement.
- Last completed gate: Discovery Closure Gate on 2026-08-05.
- Update rule: check a task only with its concise evidence and advance this pointer in
  the same plan edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check passes.
- The final focused, visual, export, native, and built-Web gates pass.
- No attack is frozen, no ordinary delivery path is absent, and no performance result
  relies on reduced workload or invalid evidence.
- Any durable behavior change is incorporated into its owning product/design spec before
  this plan is marked `done` and retired under `.agents/PLANS.md`.

Replan when:

- A verified material fact invalidates the locked design or an out-of-scope architecture
  change becomes explicitly authorized.

Remain active at Task 4.2 when:

- Correctness, visuals, collision, export, and evidence pass but a valid unchanged-load
  performance result misses the release thresholds. That state is a measured boundary,
  not a completed plan and not an implicit request for a broader rewrite.

Do not replan or stop for:

- Implementation-local mechanics already contained by this contract.
- A passing check whose relevant inputs have not changed.
