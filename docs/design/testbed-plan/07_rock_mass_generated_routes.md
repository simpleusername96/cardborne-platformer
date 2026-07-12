---
type: plan
status: superseded
superseded_by: ../../../.agent/execplans/2026-07-12-actual-game-production-roadmap.md
created: 2026-07-05
source: User map feedback and inspection findings from 2026-07-05
scope: Rock-mass terrain, movement-space guarantees, and constrained random route generation for the testbed map
related:
  - ../TESTBED_REIMPLEMENTATION_CONTRACT.md
  - ../MAP_AUTHORING_PIPELINE_CONTRACT.md
  - ./04_generated_landscape.md
  - ./06_external_foundation_replacement.md
  - ../../maps/README.md
---

# 07 - Rock-Mass Generated Routes

## Purpose

Turn the map feedback into an executable feature plan.

The desired map should read as a side-view dungeon made from filled rock masses at varied heights, not as a collection of thin floating platforms. Random generation is still required, but it must be constrained random generation: the route changes by seed while always preserving player movement space, safe traversal, object placement rules, and clear validation.

## Scope

In scope:

- replace thin-platform-heavy route language with filled rock/terrain masses where appropriate,
- keep one-way platforms, crumbling platforms, moving platforms, and debug traversal pieces as special-case features,
- ensure terrain gaps, tunnels, ceilings, and landings leave enough space for the active player profile,
- keep generated maps deterministic by seed,
- reject or retry generated maps that fail passability or placement validation,
- repair the map errors found during inspection,
- keep the current Godot testbed runnable while the terrain model is improved.

Out of scope:

- final production art,
- arbitrary tile-noise world generation,
- replacing player movement/combat contracts,
- building the full final roguelite world map,
- adding new external map-editor dependencies in this plan unless another active plan phase explicitly does that work.

## Progress

Already known:

- [x] Current map JSON previews are rectangular and use known symbols.
- [x] Current Godot project boots headless without scene-load errors.
- [x] User clarified that desired terrain is filled rock-like ground with varied heights.
- [x] User clarified that generated terrain must preserve character movement space.
- [x] User clarified that maps should still be generated randomly.

Inspection issues to include:

- [x] Runtime route metadata is inconsistent: `critical_path` names `lower_corridor` and `exit`, but the room list does not define those IDs.
- [x] Runtime generated-start terrain duplicates authored mid-connector geometry.
- [x] Generated-route validation only checks route distance, not real passability.
- [x] Design map actor/reward markers can float over gaps without declaring whether that is intentional.
- [x] Current visual language still leans too much on thin platforms instead of filled dungeon/rock mass.

Resolved in the first implementation pass:

- [x] Added filled rock-mass visual treatment to the current runtime route while preserving traversal surfaces.
- [x] Replaced duplicate generated-start collision with a visual generated socket.
- [x] Added route metadata room IDs for every `critical_path` entry.
- [x] Added generated-route validation for surface count, landing width, link gaps, step-ups, and duplicate generated surfaces.
- [x] Moved unsupported design map markers onto supporting terrain and regenerated map previews.

Still open after the first implementation pass:

- [ ] Full template-based generated route assembly.
- [ ] Full spawn-to-exit pathfinding or simulated traversal validation.
- [ ] Manual full-clear QA with the least-mobile profile.
- [ ] UI/HUD layout refinement for narrow viewport map readability.

## Feature Principles

- [ ] Filled terrain is the default for primary route surfaces.
- [ ] Thin platforms are reserved for readable mechanics: one-way drops, timed platforms, lifts, crumbling steps, or explicit optional traversal.
- [ ] Randomness changes terrain width, height, gap size, room order, optional branches, and feature placement within validated bounds.
- [ ] Randomness must not create impossible jumps, cramped corridors, unreachable exits, unavoidable hazards, or unsupported enemies.
- [ ] Every required route is validated against the least-mobile required profile before it becomes active.
- [ ] Every optional route declares its extra ability or risk, instead of silently blocking clear.
- [ ] Airborne pickups are allowed only when intentionally marked as airborne; enemies, chests, gates, and ground interactions need stable support.

## Tasks

### Phase 0 - Baseline And Intent Lock

Goal: preserve the current runnable testbed while making the new terrain target explicit.

- [ ] **0.1** Record the current playable map state with screenshots or generated previews before terrain changes.
- [ ] **0.2** Save the inspection findings as task inputs: route metadata mismatch, duplicate generated-start geometry, weak validation, unsupported markers, and thin-platform-heavy map language.
- [ ] **0.3** Confirm the runtime source for the current playable route: script-built `MotionTestStage` versus design preview JSON.
- [ ] **0.4** Confirm which design previews remain planning aids and which route must match the runtime.
- [ ] **0.5** Define the feature target in map terms: filled terrain masses, varied elevations, guaranteed movement space, deterministic random variation.
- [ ] **0.6** Keep the existing seed replay and regenerate controls working during the replacement.

Accept:

- [ ] A future implementer can tell what is being changed and what must remain stable.
- [ ] The current stage can still be launched before any terrain replacement work begins.

### Phase 1 - Terrain Shape Contract

Goal: define the shapes that replace thin generic platforms.

- [ ] **1.1** Define primary terrain as filled rock masses with a top surface, side wall, lower fill, collision, and matching visual shell.
- [ ] **1.2** Define allowed terrain mass types:
  - [ ] flat ledge mass,
  - [ ] tall rock column,
  - [ ] stepped block,
  - [ ] cliff wall,
  - [ ] low ceiling/overhang mass,
  - [ ] pit-side mass,
  - [ ] chamber floor mass,
  - [ ] optional branch mass.
- [ ] **1.3** Define special thin features separately:
  - [ ] one-way platform,
  - [ ] moving platform/lift,
  - [ ] crumbling platform,
  - [ ] temporary bridge,
  - [ ] debug measurement ledge.
- [ ] **1.4** Define minimum readable visual depth for a terrain mass so it does not look like a floating plank.
- [ ] **1.5** Define how adjacent masses can touch, overlap, or stitch without creating duplicate collision.
- [ ] **1.6** Define when a visible gap is a playable jump, a pit, a shaft, a vista, or a blocked/future branch.

Accept:

- [ ] Main route surfaces visually read as ground, walls, or rock blocks.
- [ ] Thin platforms are visually and mechanically exceptional.
- [ ] Terrain shape rules can be applied to authored and generated routes.

### Phase 2 - Movement-Space Guarantees

Goal: make player clearance a generation constraint, not a manual afterthought.

- [ ] **2.1** Pick the required profile used for critical-path validation, normally the least-mobile required profile.
- [ ] **2.2** Define minimum horizontal corridor width.
- [ ] **2.3** Define minimum headroom above walkable surfaces.
- [ ] **2.4** Define minimum landing width before and after required jumps.
- [ ] **2.5** Define maximum required horizontal gap.
- [ ] **2.6** Define maximum required vertical ledge height.
- [ ] **2.7** Define safe recovery space after drops, one-way platform descents, and hazard exits.
- [ ] **2.8** Define enemy re-entry space so respawn or knockback does not trap the player immediately.
- [ ] **2.9** Define camera-safe space so the route is readable without showing outside-map void.
- [ ] **2.10** Treat crouch-height passages as optional until crouch traversal is intentionally designed as a required mechanic.

Accept:

- [ ] Critical path movement constraints are explicit and measurable.
- [ ] Generated gaps and ledges cannot exceed the required profile's route limits.
- [ ] Every required landing has enough width and headroom for stable control.

### Phase 3 - Current Map Error Repair

Goal: fix known map correctness issues before broad random generation work.

- [x] **3.1** Add or rename route rooms so runtime `critical_path` and room IDs match.
- [x] **3.2** Remove, move, or merge the generated-start platform that currently duplicates the authored middle connector floor.
- [x] **3.3** Make generated-start terrain read as a proper filled mass or socket, not a second flat body inside existing geometry.
- [x] **3.4** Fix unsupported design markers:
  - [x] Stage 02 `W` walker over a gap,
  - [x] Stage 02 `T` chest over a gap,
  - [x] Stage 03 `C` charger over a gap,
  - [x] Boss Stage 01 `m` small slimes over gaps.
- [x] **3.5** Decide whether Stage 01 `$` coin cluster is intentionally airborne.
- [x] **3.6** If airborne pickups are intentional, mark them with an explicit airborne/reward placement rule; first pass avoided this by moving the Stage 01 coin cluster onto supporting terrain.
- [x] **3.7** Rebuild or refresh map previews after design data changes.

Accept:

- [ ] Route metadata has no missing room IDs.
- [ ] No required runtime terrain is duplicated at the same position.
- [ ] Ground actors and chests are supported by terrain.
- [ ] Airborne rewards are distinguishable from placement bugs.

### Phase 4 - Rock-Mass Route Replacement

Goal: replace the main route's thin-platform look with filled dungeon terrain.

- [ ] **4.1** Convert entrance and lower corridor surfaces into filled floor masses with side and lower fill.
- [ ] **4.2** Convert timing chamber ledges into rock ledges while keeping one-way behavior only where it teaches drop-through movement.
- [ ] **4.3** Convert broken bridge into two readable cliff/rock masses with a deliberate jump or dash gap between them.
- [ ] **4.4** Convert vertical shaft sides and floors into room-like rock masses with recovery shelves.
- [ ] **4.5** Convert combat hall and connector spaces into larger chambers instead of isolated slabs.
- [ ] **4.6** Keep destructible, crumbling, and switch/gate elements visually distinct from permanent rock.
- [ ] **4.7** Ensure ceiling and side masses frame the camera view without blocking critical path movement.
- [ ] **4.8** Preserve checkpoints, enemies, hazards, interactables, generated socket, and exit flow while changing terrain shape.

Accept:

- [ ] The map reads as connected side-view dungeon space.
- [ ] Varied height masses create clear jumps, drops, ledges, and rooms.
- [ ] Placeholder visuals remain simple but no longer look like debug-only floating rectangles.

### Phase 5 - Constrained Random Generation

Goal: keep randomness, but generate only valid terrain arrangements.

- [ ] **5.1** Define generator profiles that choose route roles, difficulty budget, verticality budget, and terrain mass palette.
- [ ] **5.2** Define terrain templates with entry sockets, exit sockets, top-surface bounds, filled-body bounds, and camera hints.
- [ ] **5.3** Generate a route plan before instantiating visible terrain.
- [ ] **5.4** Vary rock mass width, height, elevation, gap size, optional branch placement, and room order within safe ranges.
- [ ] **5.5** Keep seed determinism: same seed, profile, and ability flags produce the same route plan.
- [ ] **5.6** Avoid raw random tiles; random choices must select and parameterize known templates.
- [ ] **5.7** Prevent generated terrain masses from overlapping unless the overlap is an intentional stitch.
- [ ] **5.8** Preserve enough open space between masses for walking, jumping, falling, and combat.
- [ ] **5.9** Include a safe fallback route if all generation retries fail.
- [ ] **5.10** Publish a compact route summary with seed, profile, template IDs, validation result, and failure reason.

Accept:

- [ ] Randomly generated maps differ by seed.
- [ ] Generated maps still look like filled rock/dungeon terrain.
- [ ] Invalid generated routes are rejected before they become required for clear.

### Phase 6 - Passability And Placement Validation

Goal: replace distance-only validation with player-space and route validation.

- [ ] **6.1** Validate that the critical path is connected from spawn to exit.
- [x] **6.2** Validate required gaps and ledges against the selected profile's movement metrics.
- [ ] **6.3** Validate minimum corridor width and headroom along the route.
- [x] **6.4** Validate every required landing zone.
- [ ] **6.5** Validate every fall has recovery, checkpoint route, or fall reset.
- [ ] **6.6** Validate hazards do not create unavoidable damage on the required route.
- [ ] **6.7** Validate enemies and spawners leave safe re-entry space.
- [ ] **6.8** Validate interactables, chests, gates, and ground enemies are supported by terrain.
- [ ] **6.9** Validate airborne rewards only when marked intentional.
- [x] **6.10** Validate no generated terrain duplicates existing collision at the same place.
- [ ] **6.11** Validate exit accessibility after required interactions, destructibles, gates, and generated route completion.
- [ ] **6.12** On validation failure, retry up to a bounded limit, then keep the previous valid route or load a safe fallback.

Accept:

- [ ] `route_distance` alone is no longer enough to call a route valid.
- [ ] Validation catches impossible routes, cramped routes, unsupported objects, duplicate terrain, and unreachable exits.
- [ ] Failure reasons are visible enough for debugging and QA.

### Phase 7 - Map Preview And Runtime Readability

Goal: make the map reviewable both as generated data and as a played camera-followed route.

- [ ] **7.1** Update previews so filled terrain masses are visible, not just top-edge lines.
- [ ] **7.2** Show intended airborne rewards differently from unsupported actors.
- [ ] **7.3** Verify the default camera never shows the whole route at once.
- [ ] **7.4** Verify camera bounds do not reveal large outside-map voids.
- [ ] **7.5** Verify HUD and world labels do not hide critical traversal cues.
- [ ] **7.6** Capture at least one desktop screenshot of the generated rock-mass route.
- [ ] **7.7** Capture at least one narrow viewport screenshot if UI or camera framing is affected.
- [ ] **7.8** Keep debug overview or full preview available only for review, not as the default gameplay presentation.

Accept:

- [ ] Preview images and live gameplay both communicate filled terrain and varied elevations.
- [ ] Floating actor mistakes are visible during review.
- [ ] Gameplay framing remains readable.

### Phase 8 - Seed Matrix And QA Handoff

Goal: prove the feature with repeatable seeds and a short tester path.

- [ ] **8.1** Define fixed QA seeds:
  - [ ] safe movement seed,
  - [ ] vertical terrain seed,
  - [ ] combat terrain seed,
  - [ ] hazard terrain seed,
  - [ ] optional branch seed,
  - [ ] forced invalid or edge-case seed if supported.
- [ ] **8.2** For each seed, record expected route roles and validation result.
- [ ] **8.3** Replay each fixed seed twice and compare route summaries.
- [ ] **8.4** Regenerate random seeds several times and verify old generated nodes, signals, and validations do not remain.
- [ ] **8.5** Manually clear at least one generated route with the least-mobile required profile.
- [ ] **8.6** Manually test fall recovery, hazard recovery, object support, and exit validation.
- [ ] **8.7** Update the handoff notes or QA plan with remaining bad seeds and known limitations.

Accept:

- [ ] Seed replay is deterministic.
- [ ] Random generation produces varied but valid terrain.
- [ ] QA has concrete seeds and expected outcomes.

## Verification

- [ ] `git diff --check`.
- [ ] Godot headless import or boot check through `.\tools\godot.ps1`.
- [ ] Map data validation confirms rectangular rows, known symbols, expected spawn/exit counts, and support rules.
- [ ] Runtime map validation confirms no missing critical room IDs.
- [ ] Runtime terrain validation confirms no duplicate same-place generated/authored terrain.
- [ ] Generated route validation confirms connected spawn-to-exit path and profile-clearable movement.
- [ ] Manual camera-followed playthrough confirms the route is playable without full-map overview.
- [ ] Screenshot review confirms filled rock masses and varied heights are visible.

## Risks

- This can expand into a full procedural world generator. Keep it as template-based seeded route generation.
- Filled terrain can accidentally create cramped spaces if headroom and corridor width are not validated.
- Better visual mass can hide collision mistakes unless collision and visual bounds are checked together.
- Random generation can look valid in overview while failing in the camera-followed playthrough.
- Fixing previews without fixing runtime, or fixing runtime without updating preview expectations, can create two conflicting map truths.

## Next Steps

- [ ] Start with Phase 0 and Phase 1 before touching runtime generation.
- [ ] Repair the confirmed current map errors in Phase 3 before adding more random variation.
- [ ] Implement passability validation before allowing generated routes to block clear.
- [ ] Only after validation exists, increase visual/random terrain variety.
