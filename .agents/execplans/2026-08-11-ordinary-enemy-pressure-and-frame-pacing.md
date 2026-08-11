---
type: plan
status: active
owner: BK
created: 2026-08-11
last_reviewed: 2026-08-11
topic: Ordinary-enemy interception, firing-position recovery, forward pressure spawning, and frame-pacing regression removal
scope: Five-stage Cardborne run; ordinary enemy targeting, movement, attack commitment, spawn arrival order, radar and guidebook hot paths, specification updates, validation, Web export, rendered QA, and bounded performance evidence
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../design/DESIGN.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/design/cardborne-universal-art-style-reference.png
  - ./2026-08-11-combat-clarity-smoothness-difficulty.md
  - ./2026-08-11-dash-radar-boss-scaling-guidebook-flow.md
  - ../cardborne-performance-engineering-policy.md
  - ../cardborne-runtime-architecture-audit.md
---

# Ordinary Enemy Pressure and Frame Pacing - Execution Contract

This plan fixes the confirmed frame-pacing regression and makes ordinary enemies create
useful pressure instead of following the player's previous path. It preserves encounter
counts, active caps, decision and movement cadences, attack concurrency caps, telegraphs,
damage, collision accuracy, and visual quality. Difficulty will rise because existing
actors choose better movement and attack targets, not because more work is added to every
frame.

The implementation is complete when deterministic policy tests, encounter and UI
validators, import, Web export, and production-style smoke checks agree. A comparable
performance run is required only when the machine is quiescent; an unrelated runtime is
an explicit evidence blocker, not permission to stop correctness work or to weaken gates.

## Why and Current Context

### Ordinary-enemy behavior

- `VehicleRun._mystery_enemy_target()` currently returns the active decoy position or the
  player's exact current position. The same value is used as movement destination, attack
  eligibility target, and committed attack aim.
- Pursuers therefore follow the player's traveled path. Ranged and support families orbit
  a distance band around the player's current coordinate, but do not deliberately recover
  a clear firing lane when cover blocks line of sight.
- Ordinary projectile and charge attacks commit the player's current coordinate even
  though startup and travel time are substantial. A moving player leaves those attacks
  behind. Bosses already own bounded prediction, but ordinary enemies do not.
- Spawn allocation distributes complete packets over eight sectors and meets separation,
  offscreen, and geometry constraints. Its first sector is hash-selected and ignores the
  player's travel direction. A moving player can therefore receive the earliest births
  behind the ship, where slower ordinary enemies become a permanent tail.
- Active caps `[1, 124, 172, 224, 276]`, packet distribution, and current attack commit
  caps are intentional pressure contracts. Reducing counts would hide tactical defects
  and reverse accepted product behavior.

### Frame-pacing regression

- The previous radar correction added a render-frame call to
  `VehicleThreatRadar.set_live_anchor()`. On every player movement it clears and rebuilds
  twelve Dictionary records, reclassifies the twelve sampled contacts, and queues a draw.
- In comparable committed evidence, HUD CPU median rose from `0.229 ms` to `2.386 ms` and
  draw-call p95 rose from `82` to `99`. Overall physics timing is also worse, but the
  machine was not isolated, so only the new per-frame Dictionary rebuild has direct code
  and measurement agreement.
- The movement hot path creates one intent Dictionary per scheduled enemy and samples the
  shared pursuit field before it knows whether route guidance is needed. Most enemies with
  a clear direct path pay for a result they discard.
- Guidebook discovery also formats enemy IDs repeatedly and rebuilds the full valid-ID
  table when an empty or unknown ID reaches the store. This is a smaller `5 Hz` cost but
  has a safe constant-time correction.

## Scope and Non-scope

In scope:

- Separate ordinary-enemy pressure focus, movement focus, and committed attack target.
- Add deterministic, bounded, role-aware prediction without per-enemy navigation or
  tactical candidate searches.
- Make ranged, escort, and support enemies recover a firing lane when their direct attack
  path is blocked, using the existing shared pursuit field.
- Bias the first spawn arrival sector toward player travel while retaining complete
  eight-sector distribution, deterministic replay, and all spatial constraints.
- Remove radar render-frame Dictionary churn while preserving its exact live-anchor and
  retained-mesh visual contract.
- Remove ordinary movement intent allocation, defer pursuit-field sampling until needed,
  and make guidebook discovery lookup constant-time.
- Update the active product specification, focused validators, capture fixture, Web build,
  and evidence.

Out of scope:

- Changing ordinary enemy counts, active caps, spawn packet sizes, cadence, health,
  damage, attack commit caps, projectile caps, or stage pressure curves.
- Increasing ordinary continuous movement above the player base speed.
- Shortening startup, recovery, or other reaction windows.
- Per-enemy A*, navigation meshes, ray fans, cover sampling, group centroids, or new squad
  anchors.
- Boss behavior, player control, upgrades, save schema, new content, or production
  dependencies.
- New raster/SVG art, generated images, mesh replacement, colors, radar topology, sector
  count, or visual effects.
- Weakening performance thresholds, collision accuracy, renderer quality, or validation
  workloads.

## Domain Alignment and Invariants

| Term | Meaning | Owner | Invariant |
| --- | --- | --- | --- |
| Pressure focus | Current player or active decoy position | run target selection | Decoy focus is exact and is never velocity-predicted |
| Movement focus | Bounded forward point used to choose ordinary movement direction | enemy targeting policy | Pure vector/scalar policy; no world query or persistent actor ownership |
| Attack target | One bounded predicted aim point frozen for attack startup/active | attack commitment path | Falls back to pressure focus if the predicted line is blocked |
| Line-of-fire recovery | Lateral/route-assisted movement that seeks a viable attack lane | movement policy plus existing shared pursuit field | Does not cause a per-enemy path search |
| Forward arrival | First due birth sector nearest the current travel heading | spawn allocator | Changes arrival order only; packet membership and all-sector balance remain unchanged |
| Live radar anchor | Current player world and projected screen position | HUD presentation | Rebased each render frame over at most 12 retained records, with no hostile rescan or mesh recreation |

Target prediction is clamped by both time and distance. Movement uses family bounds:
`pursuit <= 1.20 s / 280 px`, `standoff <= 0.85 s / 200 px`,
`escort/support <= 0.60 s / 140 px`, and stationary actors use no movement lead. Prediction
is disabled below `80 px/s`. Attack commitment includes remaining startup plus analytic
projectile/charge travel when a positive attack speed exists, then clamps ordinary direct
attacks to `260 px`, artillery to `320 px`, and beam-style commitments to `220 px`.
These are decision aids, not homing: the target remains frozen after commitment.

## Alternatives Considered

1. Increase speed, counts, damage, or attack cadence. Rejected because it makes rear
   followers and frame pressure worse, while accepted caps and stage scaling already
   provide substantial numerical pressure.
2. Give every enemy navigation and multi-ray tactical candidate selection. Rejected
   because up to 276 live ordinary enemies make that cost inappropriate, and Cardborne's
   runtime contract prefers shared bounded fields and fixed-rate decisions.
3. Use bounded role-aware prediction, forward-first arrival ordering, and the existing
   shared pursuit field only when a blocked lane needs it. Selected because it fixes the
   observed semantics at existing cadence and capacity while also removing hot-path work.

## Proposed Design

### Targeting policy

- Add `VehicleEnemyTargetingPolicy` as a pure ordinary-enemy policy. It receives family,
  role, actor position/speed, pressure focus, player velocity, startup, and attack speed.
- Calculate movement focus at the existing `10 Hz` decision boundary. Pursuit gets the
  longest bounded lead; standoff and support get shorter lead so their authored bands
  remain meaningful.
- Calculate attack target only when an attack starts. Use a stable analytic intercept when
  possible, add remaining startup, and clamp the final displacement. If predicted LOS is
  blocked, commit the current pressure focus instead.
- Preserve decoy meaning: an active decoy is an exact pressure, movement, and attack focus;
  player velocity must not drag aim away from it.

### Movement and firing positions

- Add an allocation-free direction API to `VehicleEnemyMovementPolicy`. Retain the
  Dictionary `intent()` adapter only for compatibility validators and non-hot callers.
- Pursuit approaches movement focus. Ranged/support families keep their authored distance
  bands, but a blocked line of fire turns tangential movement into an explicit reposition
  request.
- In `VehicleRun._desired_enemy_velocity()`, evaluate direct obstruction first and query
  the shared pursuit field only when approach or line-of-fire recovery needs it. Blend
  route guidance strongly for blocked approach and moderately for lateral repositioning.

### Spawn arrival pressure

- Thread `player_velocity` through `VehicleEncounterRuntime.tick()` to
  `VehicleSpawnAllocator` with a default of `Vector2.ZERO` for compatibility.
- Above `80 px/s`, choose the available sector whose direction is closest to player travel
  as the first member of the existing maximally-spaced order. Below the threshold, preserve
  the existing hash-selected start. Continue the same maximally-spaced algorithm after the
  first sector.
- Do not alter candidate scoring, offscreen bounds, geometry truth, separation relaxation,
  packet count, arrival windows, or capacity admission.

### Frame-pacing corrections

- Replace the radar's internal sample/display Dictionaries with fixed-size packed arrays
  for active flags, counts, positions, angles, distances, kinds, and readiness. The feed's
  public snapshot remains unchanged. Meshes remain retained; each live-anchor update only
  resets and rebases fixed storage.
- Route the runtime through allocation-free movement direction and avoid pursuit-field
  sampling for unblocked direct movement.
- Replace formatted guidebook enemy IDs with a constant lookup. Cache valid IDs in the
  store and reject empty IDs before any lookup or save.

### Specification

- Update `docs/product/vehicle_game_spec.md` to define the three target concepts, bounded
  prediction, line-of-fire recovery, and forward-first moving arrivals.
- Replace wording that categorically forbids route guidance during holding/strafing with
  the narrower rule: the shared route field may assist blocked approach or line-of-fire
  recovery, but never becomes a permanent player-seeking squad anchor.

## Milestones and Progress

- [x] `M0` Reproduce and trace the current semantics and compare committed performance evidence.
- [x] `M0` Read root/project instructions, ExecPlan policy, performance guard, domain guidance, UI/visual authority, design authority, and the full visual system; inspect the canonical sheet at original detail.
- [x] `M0` Lock invariants, alternatives, target bounds, validation workloads, and performance evidence rules in this plan.
- [ ] `M1` Add the pure targeting policy and its deterministic validator.
- [ ] `M2` Integrate bounded movement focus, line-of-fire recovery, deferred route sampling, and predicted attack commitment.
- [ ] `M3` Add forward-first moving arrival order while preserving complete packet distribution and replay compatibility at zero velocity.
- [ ] `M4` Replace radar per-frame Dictionary churn and guidebook discovery allocation with fixed/constant storage.
- [ ] `M5` Update the product specification and capture metrics for intercept and firing-lane behavior.
- [ ] `M6` Run focused gameplay, spawn, scheduler, UI, radar, guidebook, and visual-authority validators; correct task-owned failures.
- [ ] `M7` Run import, Web export, built production smoke, rendered movement/radar QA, and bounded performance evidence when quiescence permits.
- [ ] `M8` Run the codebase quality audit, close evidence, mark this plan `done`, and commit only task-owned changes.

Current pointer: `M1` is next. Discovery is closed; no material product or architecture
choice remains open.

## Test Plan

### Deterministic policy and integration checks

- New targeting-policy validator: zero velocity produces no lead; moving focus produces an
  ahead point; each family/time/distance clamp holds; impossible intercepts remain bounded;
  decoy focus remains exact; repeated inputs are deterministic.
- Movement-policy validator: existing unblocked directions and bands remain valid;
  blocked standoff/support actors request lateral recovery; stationary actors hold;
  smoothing and speed caps remain unchanged.
- Run integration validator: ordinary attack commitment uses prediction once, freezes the
  result, and falls back to current focus when predicted LOS is blocked.
- Spawn validators: zero-velocity replay remains stable; moving-right first arrival is in
  the forward sector; all eight sectors and packet balance, offscreen, geometry, distance,
  separation, and capacity constraints still pass.
- Scheduler/contact/pacing validators: `10 Hz` decision, `30/20 Hz` movement, damage truth,
  ranged/denial commit caps, and encounter quota contracts stay intact.

### UI and runtime checks

- Radar validator: maximum 12 sectors, packed internal rebase, same-frame live screen
  anchor, dash center error `<= 1 px`, no per-anchor mesh creation, and unchanged cue
  priorities/geometry.
- Guidebook validator: all enemy IDs resolve through the constant table; boss/empty IDs do
  not rebuild catalog state or save discovery.
- Run import and focused scripts through `./tools/godot.ps1`; run the Web export after
  task-owned validators pass.
- Start the built Web output only through the `npjt-port-guard` codex lane. Check the five-
  stage run, moving spawns, pursuer interception, ranged repositioning, dash radar, pause,
  guidebook, and boss transition. Stop task-owned helpers after evidence capture.

### Performance evidence

- Do not profile an uncommitted or dirty checkpoint. After implementation is committed,
  verify process quiescence and scenario validity first.
- If quiescent, run one exact `60 s` peak workload and one exact `60 s` capacity workload,
  with required warmup and the prior committed checkpoint as baseline. Stop after that pair
  unless a validator proves the scenario invalid.
- Compare frame, physics, scheduled ordinary-enemy update, overlap cache, ordinary-due,
  HUD, presentation, draw-call, occupancy, and due-work distributions. Preserve raw JSON.
- If an unrelated Godot/browser workload remains, record process identity and skip the
  authoritative comparison. Report only deterministic hot-path changes and existing
  evidence; make no global FPS or regression-pass claim.

## Rollback and Safety

- All behavior changes are pure policy or optional-argument additions with existing
  defaults. Reverting the targeting/spawn integration restores old behavior without save
  migration.
- Radar public snapshots and HUD call sites remain compatible; only private storage changes.
- Do not delete user data, modify guidebook IDs, alter saves, install dependencies, change
  engine versions, kill unrelated processes, or weaken supply-chain/performance safeguards.
- Commit the plan, implementation, and closeout as coherent task-owned checkpoints. Do not
  stage or rewrite unrelated user changes.

## Risks and Mitigations

- Prediction could feel unfair. Keep current startup/recovery, cap time and distance, and
  freeze aim after commitment so normal dodging remains effective.
- Forward-first births could become repetitive. Apply it only while the player is moving;
  retain maximally-spaced follow-up sectors and deterministic hash order while slow.
- Line-of-fire recovery could overuse the field. Query it only after a direct obstruction
  is confirmed and only for scheduled enemies at existing cadence.
- Packed radar arrays are index-sensitive. Centralize resize/reset helpers and assert exact
  `SECTOR_COUNT` storage in the validator/debug contract.
- Existing stress baselines are red and current machine load is contaminated. Separate
  functional acceptance from authoritative performance evidence and state the limitation.

## Open Questions

None. The user requested a complete implementation, and the code/spec evidence resolves
the remaining choices without a risky product assumption.

## Decision Notes

- 2026-08-11: Preserve counts, caps, cadence, telegraphs, damage, and continuous speed;
  improve how existing enemies spend those budgets.
- 2026-08-11: Select bounded predictive targeting plus existing shared route guidance;
  reject per-enemy navigation and numerical escalation.
- 2026-08-11: Treat the radar Dictionary rebase as a confirmed local regression, while
  treating broader physics timing as inconclusive until the machine is isolated.
- 2026-08-11: No raster output is created. The canonical visual sheet was inspected only
  as style authority; expected and observed SHA-256 are
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
