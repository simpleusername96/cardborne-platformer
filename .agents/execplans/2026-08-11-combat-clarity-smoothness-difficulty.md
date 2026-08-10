---
type: plan
status: active
owner: BK
created: 2026-08-11
last_reviewed: 2026-08-11
topic: Unified combat-effect grammar, smooth enemy presentation, health-bar correctness, boss entry reliability, and difficulty escalation
scope: Five-stage Cardborne run; combat presentation, bounded runtime fixes, ordinary-enemy and boss tuning, focused validation, Web export, and runtime QA
supersedes: ./2026-08-10-non-boss-combat-and-upgrade-integrity.md
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../combat-clarity-runtime-difficulty-analysis.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../design/DESIGN.md
  - ../cardborne-performance-engineering-policy.md
  - ../cardborne-runtime-architecture-audit.md
---

# Combat Clarity, Smoothness, and Difficulty - Execution Contract

This contract turns the accepted analysis into production behavior. It establishes one
geometry-based combat language, fixes the confirmed presentation and progression defects,
raises ordinary and boss pressure without breaking reaction windows, and qualifies the
result with deterministic validators, a production Web build, and rendered runtime checks.
The work continues through every automated gate without an approval pause. Any subjective
play-feel observations that cannot be automated are handed to the user as a short QA list
after the automated contract is complete.

## Purpose

- Make effect shape, footprint, and lifecycle communicate gameplay meaning before color.
- Keep simple runtime geometry as final production presentation; do not create replacement
  images for disks, rings, corridors, bars, or links.
- Remove visible movement stair-stepping without increasing simulation cadence or changing
  collision truth.
- Make every approved world health bar geometrically correct and safe at viewport edges.
- Guarantee quota-ready bosses eventually enter when reserved capacity becomes available.
- Make the run materially harder through role-bounded speed, staged health/damage pressure,
  and explicit boss durability/damage/shield tuning.

## Why and Current Context

- Electric Field fills its radius but gives a stronger broken perimeter to an effect that
  damages the entire disk.
- EMP resolves damage/stun instantly in `285 px` and projectile clearing instantly in
  `325 px`, yet both regions are rendered as unexplained solid disks. Live-charge culling
  also uses a stale stored center while drawing at the moving player center.
- Thermal Burst and Drop Mine already publish exact-radius impulses, while Explosive
  Seeker applies a `95 px` burst without publishing any effect receipt.
- Repair Tender draws one thick undirected line from `VehicleRun`, splitting presentation
  ownership and reading too much like a damaging beam.
- Scheduled enemy movement runs at `30 Hz` near and `20 Hz` far, but MultiMesh positions
  copy simulation samples directly. The observed manual trace held about `59.88 FPS`; the
  visible stepping is therefore a presentation-cadence problem before it is evidence of a
  sustained frame-rate collapse.
- Health-bar fill anchoring assumes the wrong mesh extent, nominal `16/18` height is
  divided by the mesh aspect, large bars are unbounded, and bars are not placed safely at
  viewport edges.
- Boss entry changes to `BOSS_ACTIVE` once. If the reserved-capacity check fails on that
  tick, no later path retries the spawn.
- Two common pursuers already exceed the player's `280 px/s` base speed under the global
  `1.40` multiplier. Difficulty must therefore retune archetype bases, not add another
  global speed multiplier.

## Scope and Boundaries

In scope:

- Electric Field, EMP charge/release, Thermal Burst, Drop Mine, Explosive Seeker,
  Mystery purge, shields, beam corridors, and Repair Tender link presentation.
- Exact area footprints and unified short impulse envelopes.
- Renderer-owned, fixed-capacity enemy transform interpolation keyed by pool slot and
  generation, including spawn/reuse/discontinuity resets.
- Boss/facility/installation health-bar geometry, placement, selection, and capacity.
- Retryable boss entry under the existing reserved-capacity guard.
- Role-specific ordinary movement bases, staged ordinary health/damage pressure, boss
  health/damage, and shield-up mitigation.
- Removal of stale Mystery Device health-bar timer data.
- Focused validators, visual capture, import, Web export, production-style smoke QA, and
  honest performance comparison against the current known-red stress baseline.

Out of scope:

- New raster or SVG assets for shape-and-color-only effects.
- New enemy roles, attacks, stages, cards, boss patterns, or shortened telegraphs.
- Projectile-speed escalation, player-speed changes, or an all-enemy `60 Hz` simulation
  rewrite.
- Steering/separation retuning unless interpolation evidence still proves a separate
  simulation oscillation.
- Save-data or public resource-schema changes.

## Facts, Constraints, and Assumptions

- Gameplay geometry remains authoritative. Presentation consumes positions, radii, and
  state but never infers damage or collision truth.
- A filled footprint means the complete affected region; a body-attached closed boundary
  means protection; a filled corridor means directional damage; a segmented link means
  support; a brief full-footprint impulse means instant area resolution.
- Color remains an affinity layer, not the only gameplay signifier.
- EMP release is immediate, not an outward damage wave. Its inner disk is damage/stun;
  only the outer `40 px` fringe represents projectile-clear utility.
- Player base movement stays `280 px/s`. Normal continuous Stage 5 movement stays below
  that value; committed charges and bosses may remain explicit exceptions.
- The synthetic performance gate is already red at the current checkpoint. This plan may
  claim no performance regression or causal improvement only from comparable evidence;
  it must not relabel the existing red baseline as passed.

## Proposed Design

### Effect grammar

- Build Electric Field as one full low-alpha arc disk plus no dominant perimeter. At most
  two broad, low-contrast interior planes may add energy direction without looking like a
  separate hit region.
- Render EMP damage/stun as one full `285 px` disk. Render only the `285-325 px` utility
  band with sparse system-blue segmented marks. Charge and release use the same exact
  radii; release changes opacity, not radius.
- Resolve live EMP draw position before culling so culling and rendering share the current
  player center.
- Use one `0.18 s` full-footprint envelope for Thermal Burst, Drop Mine, and Explosive
  Seeker: whole footprint attacks, briefly holds, and fades together. Do not shrink an
  inner disk independently.
- Keep shield protection as one body-attached closed line. Keep existing beam startup and
  active states as exact filled corridors.
- Move Repair Tender feedback into `VehicleCombatRenderer`. Draw repeated source-to-target
  packets and an open recipient chevron; reduced motion keeps the same segmented link but
  removes packet travel.

### Presentation interpolation

- Preallocate arrays for all `320` enemy pool slots: generation, last seen serial,
  previous/current display position, target position, elapsed time, and segment duration.
- Key identity by `spatial_slot + runtime_generation`; reset on first sight, pool reuse,
  reactivation, or large discontinuity.
- When simulation position changes, start from the current presented position and advance
  toward the new sample over a bounded duration derived from displacement and speed,
  clamped to scheduled near/far intervals. Critical high-cadence movement finishes within
  one frame.
- Use the presented position for body, shield, semantic overlays, health bar, repair link,
  and culling. Simulation, collision, targeting, and telegraph truth remain unchanged.
- Add an optional frame-delta argument to renderer sync and pass `_process(delta)`.

### Health bars

- Use a health quad with normalized bounds `x=-1..1`, `y=-0.5..0.5`.
- Keep the fill's left edge invariant at ratios `0`, `0.25`, `0.5`, `0.75`, and `1` by
  offsetting it `-half_width * (1-ratio)`.
- Clamp installation half-width to `42..72`, boss to `96..120`, and facility to `88..112`
  world units. Preserve nominal fill heights `16` and `18`.
- Prefer the bar above its owner. If the backing would cross the visible top edge, place it
  below; then clamp the complete backing rectangle inside the visible world rect.
- Preserve the approved capacity: boss `1`, facility `1`, installations `12`, total
  instances `28`. Ordinary enemies, crates, and Mystery Devices receive no bar.

### Runtime reliability and difficulty

- Retry `_start_stage_boss()` every progression tick while boss entry is ready and the
  boss has not started. Preserve the reserve guard and never exceed `320` enemies.
- Retune ordinary archetype base speeds so the global `1.40` and stage `1.00..1.04` curves
  yield bounded role targets. Stage 1/5 target pairs are: Scrap/Chaser/Rammer `266/277`,
  Needle `246/258`, Shield `238/250`, Shooter `232/244`, Repair `222/234`, Bulkhead
  `230/244`, Controller `210/224`, Splitter `220/234`, Artillery `196/210`, Carrier
  `190/204`, Spark `140/150`; stationary roles stay zero.
- Multiply ordinary health by staged pressure `[1.35, 1.40, 1.45, 1.50, 1.50]` after the
  existing class/global/stage factors.
- Multiply ordinary incoming damage by staged pressure
  `[1.15, 1.20, 1.25, 1.30, 1.30]` after the existing ordinary/stage factors.
- Raise the boss health multiplier from `2.60` to `3.90`, expose boss pattern base damage
  through one explicit `1.30` multiplier, and change shield-up received damage from
  `0.15` to `0.12`. Keep the `4.0 s` exposed window and all telegraph timing unchanged.
- Remove Mystery Device `health_visible_timer` state because the presentation contract
  explicitly forbids its health bar.

## Discovery Closure Map

| Question | Evidence/decision | Owning change | Proof |
|---|---|---|---|
| Does every damage area show its full hit region? | Full footprint is mandatory | renderer/effect store/spec | exact-radius buffer tests and captures |
| Does EMP propagate outward? | No; both gameplay actions resolve at release | renderer/spec | fixed-radius charge/release tests |
| What distinguishes shield, beam, and heal? | boundary, corridor, segmented link | renderer/visual spec | semantic batch tests and capture |
| Is enemy stepping a frame collapse? | trace says no sustained collapse; renderer lacks interpolation | renderer only | low-cadence interpolation test and trace |
| Why can the boss fail to appear? | one-shot state transition plus reserve refusal | progression owner | capacity refusal/recovery validator |
| Which bars are allowed? | boss, facility, and fixed installations only | renderer/spec | class/capacity/edge tests |
| How is difficulty raised safely? | role bases plus staged pressure, unchanged reaction windows | archetypes/difficulty/boss owners | numeric contract tests |

## Milestones and Tasks

### 0. Contract and specification

- [x] 0.1 Supersede the previous active plan and record this execution contract.
- [x] 0.2 Reconcile product and visual specifications with the final primitive grammar,
  EMP semantics, health-bar policy, interpolation ownership, and difficulty values.
- [x] 0.3 Record that no new image asset is required or approved for these primitives.

### 1. Effect grammar

- [x] 1.1 Remove Electric Field's dominant perimeter and simplify its interior planes.
- [x] 1.2 Correct live EMP culling and render the inner damage disk plus differentiated
  outer utility fringe for charge and release.
- [x] 1.3 Add a bounded Explosive Seeker impact receipt at the exact `95 px` gameplay
  radius and share the unified short impulse lifecycle with Thermal Burst and Drop Mine.
- [x] 1.4 Move Repair Tender feedback into the retained renderer as a segmented,
  directional support link and remove the direct `VehicleRun` line.
- [x] 1.5 Remove stale authored-EMP wording and stale Mystery Device health-bar state.

### 2. Smoothness, health bars, and progression

- [x] 2.1 Add fixed-capacity, generation-safe enemy presentation interpolation without
  changing simulation positions or decision cadence.
- [x] 2.2 Apply presented positions consistently to attached visual consumers.
- [x] 2.3 Fix health-bar mesh bounds, left anchoring, class width clamps, safe placement,
  approved-class filtering, and capacity accounting.
- [x] 2.4 Make boss entry retry until capacity permits, while preserving reserve limits.

### 3. Difficulty

- [x] 3.1 Retune ordinary role base speeds and prove normal Stage 5 continuous speed stays
  below the player's base movement.
- [x] 3.2 Add staged ordinary health and damage pressure arrays at their domain owners.
- [x] 3.3 Raise boss health, boss pattern damage, and shield-up mitigation without changing
  telegraph, active-window, projectile-speed, or exposed-window timing.

### 4. Focused verification and rework

- [x] 4.1 Extend effect-store, visual-event, renderer, run, mystery-device, difficulty,
  boss-pattern, and boss-runtime validators before relying on rendered evidence.
- [x] 4.2 Run each affected focused validator and fix all task-caused failures.
- [x] 4.3 Run the visual-authority validator and the relevant capture driver; inspect the
  rendered result for grammar, overlap, edge placement, and opacity hierarchy.
- [x] 4.4 Run Godot import and Web export. Start the built product through the project
  fastrun `codex` lane and smoke the relevant flows.
- [ ] 4.5 Run comparable native/runtime performance evidence after code stops changing.
  Report the pre-existing red stress baseline honestly and reject any new allocation or
  frame-pacing regression.

### 5. Closeout

- [x] 5.1 Run the codebase quality audit over all task-owned multi-file changes and make
  only small safe task-scoped corrections.
- [ ] 5.2 Record commands, results, captures, residual risks, and any user-only play-feel
  QA in this plan.
- [ ] 5.3 Commit only task-owned files in coherent scoped commits.
- [ ] 5.4 Mark this plan `done` only after every automated gate is complete and no required
  implementation work remains.

## Test Plan

Focused deterministic gates:

- Effect store: fixed total capacity, bounded explosive-impact recycling, exact radii,
  EMP primary/secondary radius ownership.
- Renderer: Electric Field has a full disk and no perimeter family; EMP culls/draws from
  one resolved center; instant impacts retain full radius across their envelope; Repair
  packets are directional and disappear with an invalid target.
- Interpolation: first sight snaps, 20/30 Hz samples advance monotonically, reuse and large
  discontinuities reset, and simulation `enemy.pos` is unchanged.
- Health bars: mesh bounds, exact heights, left-edge invariance at five ratios, class width
  clamps, above/below placement, viewport clamping, approved classes, and `28` instances.
- Run progression: boss refusal above reserve threshold, later success at or below it,
  one boss only, and no capacity overflow.
- Difficulty: exact role speeds across Stage 1/5, staged ordinary health/damage factors,
  boss health totals, `1.30` boss damage, `0.12` shield mitigation, and unchanged timing.
- Mystery Device: no health-bar timer field in runtime or snapshots.

Final gates:

- `./tools/godot.ps1 --editor --headless --quit-after 1` or the repository's equivalent
  import command.
- Relevant `tools/validation/validate_*.gd` scripts through `./tools/godot.ps1`.
- `./tools/validation/validate_cardborne_visual_authority.ps1`.
- Project capture driver for combat effects/health/interpolation evidence, with direct
  visual inspection of generated PNGs.
- Web export and production-style built start through fastrun's `codex` lane.
- Comparable performance scenario/manual trace where safely automatable.

User QA may remain only for subjective feel: whether the new pressure curve is enjoyable
through a real multi-stage run, whether heal packets remain legible in a dense fight, and
whether health bars feel proportionate at the user's normal viewport. These are not a
substitute for automated correctness gates.

## Anti-Rework Rules

- Do not add a second visual radius unless gameplay owns a second radius with a different
  function.
- Do not use a dominant perimeter for a full-area damaging effect.
- Do not create an image for a plain runtime shape or color treatment.
- Do not raise the global ordinary speed multiplier above `1.40`.
- Do not hide scheduler cadence by moving collision or AI truth into presentation.
- Do not shorten telegraphs or increase projectile speeds in this difficulty pass.
- Do not tune separation/recovery unless post-interpolation evidence isolates it.
- Do not add Mystery Device, crate, or ordinary-enemy health bars.
- Do not expand `VehicleRun` when the effect store, renderer, archetype catalog, stage
  difficulty, boss pattern, or boss shield owner already owns the change.

## Rollback and Safety

- Every change is code/data/docs only and remains reversible through scoped commits.
- Renderer interpolation can be removed without changing simulation state or save data.
- Difficulty arrays and constants are isolated from encounter definitions and can be
  reverted independently if playtest pressure is excessive.
- Effect-store additions must reuse the existing `96` states and reject/recycle only their
  own cosmetic family; they must never evict EMP or higher-priority receipts.
- Do not delete user files, unrelated assets, or historical evidence.

## Risks and Mitigations

- Interpolation lag may make collision appear offset. Keep duration bounded, snap large
  discontinuities, and test contact-adjacent motion.
- Heal segments may consume too many overlay instances. Use a fixed small segment count
  per active Repair Tender and retain the existing batch capacity guard.
- Health bars may overlap large bodies near corners. Prefer above/below placement and then
  clamp the complete backing, verified at all four edges.
- Combined health and damage increases may overshoot. Preserve telegraphs and role speed
  ceilings, then leave only whole-run enjoyment as user QA.
- Existing performance stress is red. Compare like-for-like and report deltas; do not claim
  release performance success from a non-comparable or staged capture.

## Open Questions

No material implementation question remains. Subjective play-feel acceptance is explicitly
deferred to the user after all deterministic and production-build gates pass.

## Decision Notes

- 2026-08-11: Accepted code-native geometry as final production language for exact runtime
  shapes; no image generation is needed for this contract.
- 2026-08-11: Accepted semantic grammar: fill=affected area, attached line=shield,
  corridor=beam damage, segmented directed link=heal, brief full fill=instant impact.
- 2026-08-11: Accepted EMP as simultaneous inner damage/stun and outer projectile-clear
  utility, not an outward damage wave.
- 2026-08-11: Accepted role-specific speed retuning, staged `+35..50%` ordinary health,
  staged `+15..30%` ordinary damage, `+50%` boss health, `+30%` boss damage, and stronger
  shield-up mitigation.

## Progress and Evidence

- Current step: Task 4.5.
- Evidence baseline: `.agents/combat-clarity-runtime-difficulty-analysis.md`.
- Commands/results: all affected focused Godot validators passed; the visual-authority
  PowerShell validator passed with the canonical style-sheet hash intact. Godot import
  and release Web export passed. The built four-file Web artifact loaded through fastrun's
  `codex` lane at `127.0.0.1:13029`; Deployment, combat entry, and live EMP activation
  rendered without browser warnings or errors. The task-owned server was stopped and the
  port was confirmed released.
- Captures: `build/captures/execplan-2026-08-11-combat-clarity/` contains the complete
  `116`-file capture set and manifest. Direct original-detail review covered Electric
  Field levels, standard/reduced-motion EMP charge and release, Explosive Seeker impact,
  semantic health bars and Repair Tender link, beam corridor, essential transients, and
  Stage 5 boss active state. The images preserve the approved shape grammar, exact-area
  hierarchy, safe bar placement, and readable overlap.
- Quality audit: responsibilities remain with the effect store, renderer, archetype,
  difficulty, boss, and progression owners; the renderer API addition is optional and
  synchronized across callers; bounded capacities and rejection paths are covered; no
  competing runtime owner, catch-all fallback, or untested reachable failure path remains.
- Residual risks: pending final validation.

## Completion Conditions

This plan is complete only when Tasks `0.1` through `5.4` are checked, task-owned focused
validators pass, the visual-authority gate passes, Web export succeeds, the built product
has been smoke-tested, performance evidence is reported without overstating the known-red
baseline, and any remaining user work is limited to the subjective QA list defined above.
