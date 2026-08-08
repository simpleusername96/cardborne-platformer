---
type: plan
status: active
created: 2026-08-08
scope: Cardborne combat pressure, elemental hit behavior, surface depth, and qualified frame pacing
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../design/DESIGN.md
  - ../cardborne-performance-engineering-policy.md
  - 2026-08-02-pre-asset-code-stabilization.md
---

# Combat Pressure, Thermal Burst, and Surface Depth - Execution Contract

Deliver a harder-to-cheese but less front-loaded five-stage run by removing the four neutral
map hazard zones, lowering Stage 1 ordinary-enemy health, strengthening stage-to-stage
ordinary health growth, reducing shielded boss damage, replacing Thermal Burn with a bounded
on-hit Thermal Burst, and adding sparse approved surface-detail rasters without compromising
combat readability or the retained-rendering budget. The verified starting point is clean
commit `e6324c96`; current HEAD has no eligible performance sample, so performance qualification
precedes feature edits and is repeated after the final workload is complete.

## Purpose

- Objective: implement the requested pressure, shield, elemental, surface, and frame-pacing
  outcomes as one decision-complete sequence with independent causal commits.
- Deliverable: updated gameplay rules, bilingual product copy, visual authority contract,
  approved production rasters, deterministic retained surface placement, focused validators,
  production Web export, and eligible native/Web performance evidence.
- Completion state: neutral hazards no longer exist; ordinary health uses the locked five-stage
  curve; shielded bosses take 15% incoming damage; Thermal Burst applies bounded enemy-only
  splash; the floor has sparse non-gameplay detail; all correctness, visual, export, and
  performance gates pass from the exact clean final commit.

## Scope and Boundaries

In scope:

- Remove the current four traversable `hazard_zone` footprints, their player/enemy/boss damage,
  lingering exposure, rendering, production assets, guidebook entry, localization, docs, and
  obsolete validator branches.
- Change only ordinary-enemy stage health scaling to `[0.80, 1.00, 1.20, 1.40, 1.60]` while
  retaining authored archetype health, the current ordinary final multiplier `2.60`, and the
  existing 1.12 swarm/standard class factor.
- Change boss `shield_up` incoming damage from `0.25` to `0.15`; preserve the `1.0` exposed
  multiplier, four-second shield-down window, transitions, and `final_effective` bypass.
- Replace the persistent thermal condition and the `thermal_burn` card identity with
  `thermal_burst`: primary-projectile hits create enemy-only splash with radii `72/84/96` and
  flat damage `4/6/8` at levels 1/2/3.
- Introduce the presentation-only `SurfaceDetail` visual category and three small approved
  production rasters: crack, stain/wear, and embedded debris chip.
- Diagnose the reported hitch from eligible evidence and make only an evidence-selected,
  task-scoped performance correction if a release gate remains red.

Out of scope:

- Boss-owned telegraphed `denied_zones`; these are attacks, not the neutral map hazards.
- Boss base-health curve or final boss-health multiplier, ordinary damage/speed curves,
  encounter counts, quotas, spawn cadence, projectile/effect capacities, collision rules, and
  performance thresholds.
- New named material, cultural, marine, ritual, or photoreal environment theme.
- Loose stones that imply collision, navigation, cover, or pickup behavior; the approved
  debris detail is embedded, flat, non-interactive floor wear.
- TileMap adoption, a full-field texture, runtime noise/shader generation, per-detail nodes,
  animated floor detail, gameplay collision, or stage-randomized detail layouts.
- New Thermal Burst world-radius telegraph, persistent ring, particle system, sound asset, or
  standalone explosion raster. Existing thermal projectile color, impact sound, and per-target
  hit feedback carry the response in this scope.
- General optimization, workload reduction, visual-quality reduction, or dependency changes.

Constraints and invariants:

- Preserve the connected five-stage run, manual aim, held primary fire, dash, passive Seekers,
  EMP, authored encounters, map pickups, mutually exclusive elements, card choice flow, quota-
  gated bosses, and complete Korean/English user-facing copy.
- Keep visual geometry independent from collision truth and keep card behavior out of UI code.
- `docs/design/VISUAL_SYSTEM.md` and the exact canonical style-reference sheet remain the visual
  authority pair. The sheet SHA-256 must remain
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- Player-facing raster creation must use ImageGen or another raster authoring path with the
  canonical sheet supplied as an actual image reference. SVG/ImageMagick geometric authoring is
  prohibited; ImageMagick remains limited to non-creative conversion and evidence work.
- The surface remains a low-detail neutral matte plane. Surface detail must be lower contrast
  than every actor, projectile, pickup, telegraph, objective, and world boundary.
- Surface placement is deterministic from the run-fixed field geometry plus a fixed salt. It
  must not depend on current-stage objects or alter topology, collision, reachability, or replay
  behavior.
- The world renderer stays retained. Surface instances use at most three existing-style
  `MultiMeshInstance2D` batches, zero per-instance nodes, zero per-frame transform updates, and
  keep `MAX_VISUAL_BATCHES <= 12`.
- Performance claims require eligible current-commit evidence under
  `.agents/cardborne-performance-engineering-policy.md`. Historical results are diagnostic only.
- Use Godot 4.7.1 through `./tools/godot.ps1`; add no production dependency.

Destructive or irreversible actions:

- Retire the two now-unused tracked hazard production PNGs and their manifest entries only after
  all hazard consumers are removed. Git history makes the deletion recoverable.
- Rename `data/cards/vehicle/thermal_burn.tres` to `thermal_burst.tres` and replace the stable card
  ID because the product spec confirms upgrades are run-only and no persistent build migration is
  required. Preserve the generic `upgrade/element_thermal` artwork asset.
- Retire the unused, contract-incompatible
  `scripts/presentation/vehicle_field_surface_pattern_compiler.gd` when the dedicated surface-
  detail compiler becomes the sole floor-detail owner; do not keep competing dormant owners.

Exact actions requiring owner or user approval:

- This contract authorizes no implementation by itself. Begin execution only after the user
  approves the plan or explicitly asks to implement it.
- Before promoting any generated surface raster, present an exact AS-IS/TO-BE comparison with
  the authority sheet, each candidate at 1x, provenance, intended asset ID, footprint, and in-
  game placement capture. Promote only candidates the user explicitly approves.
- Before the first broad native/Web qualification batch, state its purpose, clean-commit scope,
  expected duration, system impact, and stop condition; run it only after the user aligns with
  that cost. Focused validators and a user-requested manual trace are not this broad batch.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| “Neutral attack zone” identity | No such symbol exists. Four `hazard_zone` footprints are generated by `VehicleFieldLayoutGenerator`; `VehicleTerrainRuntime` applies neutral immediate, 0.75-second tick, and 2.5-second lingering damage. They hurt ordinary enemies more than the player and their kills still advance quota/drop XP. Boss `denied_zones` are separate attack telegraphs. | `scripts/vehicle/vehicle_field_layout_generator.gd`; `scripts/vehicle/vehicle_terrain_runtime.gd`; `scripts/vehicle/vehicle_run.gd`; commit `580cde2c`; product spec | Treat the request as removal of map hazard zones. Remove the mechanic and all unused presentation/product surfaces; preserve boss attack zones. | 2.1-2.3 |
| Early ordinary health and later growth | Ordinary health is authored base x optional 1.12 class factor x `[1.00,1.04,1.08,1.12,1.16]` x `2.60`. Commit `8924a877` doubled the final multiplier from 1.30 on 2026-08-08. Boss health is separate. | `VehicleStageDifficulty`; `VehicleRun._make_enemy`; git history; product spec | Use additive percentage-point growth `[0.80,1.00,1.20,1.40,1.60]`, not 20% compounding. It gives the requested 20% Stage 1 reduction and clear stage separation without compounding Stage 5 to 2.0736x Stage 1. Boss health is excluded. | 3.1-3.2 |
| Combined late-run pressure | Quotas, authored population, active population, role mix, and boss pressure already rise by stage. Removing enemy-damaging hazards also increases effective enemy durability. | Product spec stage tables; encounter owners; hazard damage rules | Keep the requested health direction but do not also raise quotas, counts, damage, speed, or boss HP. Treat `[0.80,1.00,1.20,1.40,1.60]` as the maximum curve for this pass and validate clear-time/TTK before any further increase. | 3.2, 7.2 |
| Shielded boss durability | `VehicleBossShieldRuntime` owns `0.25` shielded, `1.0` exposed, and a four-second down window. | `scripts/bosses/vehicle_boss_shield_runtime.gd`; boss/run validators; commit `b7b9df11` | Set shielded to `0.15`. This is a 40% reduction from current shielded throughput while retaining meaningful chip damage; `0.10` is rejected for this pass because it approaches immunity during downtime. | 3.1-3.2 |
| Thermal meaning and ownership | `thermal_burn` is a persistent three-stack condition held in `VehicleStatusProfile/Runtime`; affinity is inferred from a burn condition bit. All split primary projectiles receive the profile. Seekers do not. | card resource, `VehicleRun._fire_primary`, `VehicleAttackContract`, `VehicleStatusProfile`, `VehicleStatusRuntime` | Canonical term is `Thermal Burst`: an instant elemental payload, not a status. Replace the card ID and profile owner with `VehicleElementProfile`; keep `VehicleStatusRuntime` only for Toxin/Chill. Give attack affinity an explicit element source instead of pretending thermal is a condition. | 4.1-4.4 |
| Thermal Burst hit contract | Existing `_damage_enemies_in_radius` uses the spatial grid but also damages devices/facilities. Seeker burst already excludes its direct target. | `VehicleRun._update_projectile_buffer`; `VehicleRun._damage_enemies_in_radius` | Trigger once for every direct enemy hit by a non-reflected `player_primary` projectile, including split/piercing hits. Use spatial-grid query, radius `72/84/96`, flat damage `4/6/8`, exclude the direct target, damage targetable enemies including a nearby boss through normal shield rules, exclude structures/devices/facility, and never chain or apply Toxin/Chill. | 4.2-4.4 |
| Thermal presentation | Current `upgrade/element_thermal` artwork is a generic orange thermal core, not a burn glyph. Current visual contract permits only a small bounded transient set. | Original-detail asset inspection; visual system; combat renderer | Reuse the artwork, thermal projectile color, impact sound, and normal hit feedback. Add no new effect kind or world visual in this pass. | 4.3-4.4 |
| Surface flatness versus current contract | The visual system mandates a flat `#9EADBC` plane and bans seams, scratches, random noise, and decorative patterning. `VehicleWorldMeshBuilder.DECORATION_BUDGET` is zero. | Full `VISUAL_SYSTEM.md`; original-detail authority sheet; world mesh builder | The flatness feedback is valid, but random uncontrolled PNG scatter is not. Amend the contract first to allow a narrow semantic `SurfaceDetail` category, then add three sparse low-contrast authored rasters under an explicit approval gate. | 5.1-6.4 |
| Surface rendering choice | The world builder already caches asset/z `MultiMeshInstance2D` batches. TileMap would add a new owner; procedural shader/noise violates visual rules; a full 7200x4320 RGBA surface would be roughly 124 MB before mip/import overhead. | Local renderer; Godot 4.7 `MultiMeshInstance2D`, `MultiMesh`, TileMapLayer, GPU optimization, CanvasItem, and RNG docs | Retain the current batch path. Add 72 crack, 72 stain, and 48 embedded-chip instances maximum (192 total), one batch per asset, fixed low z, compact transparent quads, discrete 90-degree rotation and `0.75/1.0/1.25` scale variants, and no runtime updates. | 5.1-6.4 |
| Comparable-game evidence | Official Into the Breach material supports deterministic, immediately readable combat; public primary sources for Into the Breach, Wasteland Kings, and Spelunky do not disclose exact floor-decal batching. | GDC postmortem and official game pages; Godot official docs | Do not claim an unverified clone technique. Use comparable games only for sparse/readable/deterministic principles; choose the renderer from Cardborne architecture and official Godot guidance. | 5.1, 6.4 |
| Reported hitch | Current HEAD has no eligible performance JSON. The last eligible older sample showed frame p95 143 ms with physics catch-up and simulation/HUD cost while render CPU/GPU were low. Later allocator prewarm improved a diagnostic but was never release-qualified. On 2026-08-08, 16 unrelated Godot processes prevented a clean run. | Active performance plan; runtime architecture audit; historical JSON | Make no current root-cause claim. First qualify clean current HEAD, then repeat after all feature work. Optimize only the subsystem selected by a valid trace/sample; never blame new PNGs by intuition. | 1.1-1.4, 7.3-7.4 |
| Performance fixture mismatch | Renderer capacity and visual contract are 28 health overlays, but the performance scenario and its validator still require 50. Release batch threshold remains at most 50. | combat renderer, visual system, renderer validator, performance scenario and validator | Change only the scenario fixture expectation from 50 to 28; retain the release threshold `batches <= 50`. A failing focused validator blocks all expensive samples. | 1.1 |

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership, safety, and validation
  decision is closed.
- Godot 4.7.1 is available through `./tools/godot.ps1`; no bootstrap or dependency change is
  required. Each validator named below already exists. Surface generation uses the installed
  ImageGen workflow and requires the declared user approval gate before promotion.
- Remaining unknowns are implementation-local or measured performance evidence. They cannot
  change this contract without triggering the predetermined change-control rules.

## Tasks

### Phase 1: Qualify the current performance baseline

Goal: remove the static scenario contradiction and finish the existing performance plan's clean
current-HEAD qualification before gameplay or visual workload changes obscure causality.

Preconditions:

- The user has approved implementation of this contract.
- Work from a clean scoped branch/commit and do not disturb unrelated Godot processes.

Source owners: `scripts/performance/vehicle_performance_scenario.gd`,
`tools/validation/validate_vehicle_performance_scenarios.gd`,
`.agents/execplans/2026-08-02-pre-asset-code-stabilization.md`

- [ ] **1.1** Restore a truthful performance fixture contract.
  - Change: replace the stale required health-overlay capacity `50` with renderer capacity `28`
    in the scenario and its focused validator. Do not change the release batch threshold `50`.
  - Accept: `validate_vehicle_combat_renderer.gd`,
    `validate_vehicle_performance_scenarios.gd`, and `validate_vehicle_run.gd` pass.
  - Guard: if any other renderer/scenario capacity disagrees, stop and reconcile it with the
    canonical visual contract; do not lower workload or thresholds.
- [ ] **1.2** Record one user-controlled normal-play hitch trace.
  - Change: from the clean committed fixture state, run
    `./tools/run_manual_performance_trace.ps1`; reproduce normal play until the hitch occurs, exit
    normally, and retain the JSON unchanged.
  - Accept: the trace has matching commit/dirty metadata and identifies whether slow buckets
    correlate with physics catch-up, encounter/pursuit, grid/enemies, projectiles, effects,
    presentation/HUD, render CPU/GPU, pressure, or focus. Record the conclusion as diagnostic,
    never as a release pass.
  - Guard: do not start if the wrapper detects another Godot process or if the user cannot drive
    the trace; record the deferred precondition without substituting a synthetic play claim.
- [ ] **1.3** Complete clean native qualification owned by the active performance plan.
  - Change: after the required user cost alignment, run the exact clean-commit `peak_horde` and
    `capacity_pressure` commands in Phase 8/Test Plan of
    `.agents/execplans/2026-08-02-pre-asset-code-stabilization.md` with GL Compatibility,
    1280x720, quoted position `'40,40'`, VSync disabled, ten-second warmup, and 60-second sample.
  - Accept: both files match commit/workload/window/focus/renderer metadata and pass: frame
    p95/p99 `<=18/25 ms`, median `>=59 FPS`, 1% low `>=55 FPS`, no more than one consecutive
    frame over 33.3 ms, capacity physics p95/p99 `<=6/8 ms`, draw p95 `<=200`, batches `<=50`.
  - Guard: any overlap, focus loss, dirty commit, workload mismatch, or invalid authority field
    rejects the sample without tuning the workload.
- [ ] **1.4** Qualify the built Web target and close the prerequisite plan.
  - Change: only after both native samples pass, export Web from the same clean commit, load
    `$npjt-port-guard`, use the `codex` lane, collect the exact built-Web `peak_horde` result with
    visible Chrome, stop only the task-owned server, and complete/archive the prerequisite plan.
  - Accept: the Web file is commit-proven and threshold-passing; the prerequisite plan is moved
    to its completed location with its evidence links intact.

Batch gate:

- No Phase 2 edit begins until Phase 1 has an eligible clean baseline or the user explicitly
  chooses to defer the baseline after being told that later comparisons will lose causal value.

### Phase 2: Remove neutral map hazards completely

Goal: remove the mechanic that passively kills enemies and grants quota/XP while preserving all
boss-owned attack telegraphs and transit behavior.

Preconditions:

- Phase 1 batch gate passes.

Source owners: `scripts/vehicle/vehicle_field_layout_generator.gd`,
`scripts/vehicle/vehicle_terrain_runtime.gd`, `scripts/vehicle/vehicle_run.gd`,
`scripts/vehicle/vehicle_field_geometry_snapshot.gd`,
`scripts/presentation/vehicle_world_mesh_builder.gd`,
`scripts/presentation/components/vehicle_world_visual_catalog.gd`, guidebook/localization,
production asset manifest, product/visual specs, and focused validators

- [ ] **2.1** Remove hazard generation and combat behavior.
  - Change: remove four hazard footprints, exposure state/timers, player/ordinary/boss hazard
    damage, neutral hazard kill attribution, and hazard geometry snapshots. Keep terrain runtime
    transit-gate ownership and keep `VehicleRun.denied_zones` unchanged.
  - Accept: generated layouts contain zero hazards; no actor can receive hazard damage or retain
    exposure; transit gates and boss attack zones still work.
- [ ] **2.2** Retire every now-unused hazard surface.
  - Change: remove hazard visual descriptors/batches, guidebook entry, Korean/English strings,
    product/visual spec clauses, manifest IDs `world/hazard_toxic_bog` and
    `world/hazard_lava_pool`, and their tracked PNGs. Replace or delete hazard-only validators;
    keep mixed validators and rewrite their exact expectations.
  - Accept: repository search finds no live `hazard_zone`, hazard asset ID, exposure, or guidebook
    contract; no asset is orphaned; visual authority validation passes.
- [ ] **2.3** Commit the hazard removal as one causal change.
  - Change: stage and commit only Phase 2 files.
  - Accept: field-layout, terrain, map-mechanics, stage-layout, world-visual, guidebook,
    localization, asset-manifest, and Run validators pass; `git diff --check` passes.

### Phase 3: Rebalance ordinary health and boss shielding

Goal: make the opening less spongy, make stage growth explicit, and make the boss attack window
matter without changing boss HP or turning shielding into immunity.

Preconditions:

- Phase 2 acceptance passes.

Source owners: `scripts/enemies/vehicle_stage_difficulty.gd`,
`scripts/vehicle/vehicle_run.gd`, `scripts/bosses/vehicle_boss_shield_runtime.gd`, product spec,
and difficulty/boss/Run validators

- [ ] **3.1** Apply the locked numeric contracts at their existing owners.
  - Change: set ordinary health curve to `[0.80,1.00,1.20,1.40,1.60]` and shielded boss damage
    multiplier to `0.15`. Do not change `ORDINARY_HEALTH_MULTIPLIER`, boss HP, exposed multiplier,
    shield-down duration, damage/speed curves, or `final_effective` handling.
  - Accept: Stage 1 ordinary health is exactly 80% of the current formula; successive stages add
    exactly 0.20 of the authored/current-final baseline; 100 ordinary incoming damage applies 15
    while shielded and 100 while exposed.
- [ ] **3.2** Update balance truth and regression examples.
  - Change: update the product spec and exact validator mirrors; add examples for a class-factor
    enemy and a no-class-factor enemy across stages; assert boss health is unchanged.
  - Accept: difficulty, boss-exam, boss-pattern, and Run validators pass and no stale 0.25 or old
    health-curve assertion remains outside retained history/evidence.

### Phase 4: Replace Thermal Burn with Thermal Burst

Goal: make the thermal element an immediate on-hit crowd tool with clear ownership, bounded work,
and no persistent burn semantics.

Preconditions:

- Phase 3 acceptance passes.

Source owners: card resource/catalog/build, `scripts/combat/vehicle_element_profile.gd`,
`scripts/combat/vehicle_status_runtime.gd`, `scripts/combat/vehicle_attack_contract.gd`,
`scripts/combat/vehicle_projectile_state.gd`, `scripts/vehicle/vehicle_run.gd`, damage source,
telemetry/report owners, localization, product/catalog docs, and focused validators

- [ ] **4.1** Align the elemental domain language.
  - Change: replace `thermal_burn` with `thermal_burst` in the run-only card/build/catalog
    contract; replace `VehicleStatusProfile` with immutable `VehicleElementProfile`; make thermal
    affinity explicit while condition masks contain only persistent Toxin and Chill. Keep
    `VehicleStatusRuntime` as the owner of those two statuses.
  - Accept: no live burn DPS, duration, stack, condition bit, report source, localization, or test
    remains; Toxin/Chill behavior and mutual exclusion are unchanged; generic thermal artwork is
    still the card art.
- [ ] **4.2** Apply bounded enemy-only burst damage on primary hits.
  - Change: put level values `radius=[72,84,96]`, `damage=[4,6,8]` in the element profile. On each
    eligible direct hit, use the existing spatial grid to damage targetable nearby enemies once,
    excluding the direct target and all structures/devices/facility. Do not scan the full enemy
    array, recurse, chain, or allocate a per-hit node/list.
  - Accept: normal, split, and piercing primary hits follow the contract; Seekers, EMP, status
    ticks, reflected shots, splash hits, and structure-only hits do not trigger a burst; a nearby
    boss receives its normal shield multiplier.
- [ ] **4.3** Preserve readable thermal feedback without expanding the visual workload.
  - Change: keep thermal projectile affinity/color, reuse current impact audio, and use existing
    per-target hit feedback for every damaged target. Add no effect-store kind or geometry.
  - Accept: combat renderer and attack-contract captures show thermal primary projectiles and
    distinct affected-target feedback without a persistent radius or extra live effects.
- [ ] **4.4** Update product copy, reporting, and focused validation.
  - Change: title the card `열폭발` / `Thermal Burst`; describe primary-hit area damage in both
    languages; attribute splash as `thermal_burst`/thermal player damage; update catalog count and
    state assertions only if the rename actually changes them.
  - Accept: build/card/UI/localization, element/status stacking, attack contract, telemetry,
    report, renderer, capture-driver, and Run validators pass. Direct and splash damage are not
    double-counted and lifesteal sees only actual player-owned damage.

Batch gate:

- Run one deterministic Stage 1 dense-group capture and one shield-up boss-adjacency harness.
  Confirm direct-target exclusion, bounded target count, normal shield application, no structure
  splash, and no status-tick or chain trigger before moving to visual contract work.

### Phase 5: Authorize a narrow SurfaceDetail visual category

Goal: amend the visual contract before generating or integrating any floor-detail raster.

Preconditions:

- Phase 4 batch gate passes.
- Reverify the authority-pair hash and inspect the sheet at original detail.

Source owners: `docs/design/VISUAL_SYSTEM.md`, production asset manifest/workbench inventory,
`.agents/execplans/2026-08-08-combat-pressure-and-surface-depth.md`

- [ ] **5.1** Define the exception without weakening combat readability.
  - Change: keep flat `#9EADBC` as the dominant surface and add `SurfaceDetail` as a semantic,
    presentation-only exception. Permit only crack, stain/wear, and embedded debris-chip rasters;
    ban grids, seams, repeated panels, rivets, nested rings, lamps, random micro-noise, photoreal
    grime, raised-looking loose stones, and topology cues.
  - Accept: the contract states size/density/contrast/z/batch/placement limits, names runtime and
    approval owners, and keeps every gameplay signal above detail priority.
- [ ] **5.2** Replace the dormant competing floor-pattern owner.
  - Change: retire `vehicle_field_surface_pattern_compiler.gd` and register a dedicated
    `vehicle_surface_detail_compiler.gd` responsibility in the active plan/visual contract. The
    new compiler owns placement only; authored PNGs own pixels and tactical layout owns geometry.
  - Accept: only one runtime owner can create ambient floor detail and no prohibited panel-pattern
    path remains reachable or registered.
- [ ] **5.3** Validate the visual authority workflow change.
  - Change: update manifest/workbench expectations for removal of two hazards and later addition
    of three surface assets; record `actual_image_reference_used=false` for this contract-only
    phase because it creates no raster.
  - Accept: `validate_cardborne_visual_authority.ps1` and document-authority validation pass.

### Phase 6: Generate, approve, and integrate sparse surface rasters

Goal: add modest physical depth while keeping the surface quiet, deterministic, and cheap.

Preconditions:

- Phase 5 passes.
- The canonical sheet is supplied to ImageGen as an actual referenced image.

Source owners: three production raster assets, production manifest/workbench evidence,
`scripts/presentation/vehicle_surface_detail_compiler.gd`,
`scripts/presentation/vehicle_world_mesh_builder.gd`, world visual catalog, and visual validators

- [ ] **6.1** Generate grounded candidates to the locked brief.
  - Change: create transparent raster candidates for `world/surface_detail_crack` (96x96),
    `world/surface_detail_stain` (128x96), and `world/surface_detail_embedded_chip` (64x64). Keep
    neutral hangar-floor colors close to `#9EADBC`, irregular authored silhouettes, compact alpha
    bounds, no cast shadow/height cue, and no game-signal colors.
  - Accept: provenance records exact reference path/hash and `actual_image_reference_used=true`;
    each candidate is inspected at original detail and at intended 1x footprint.
- [ ] **6.2** Obtain exact candidate approval before promotion.
  - Change: present AS-IS flat-surface and TO-BE runtime captures plus the three source candidates,
    constraints, provenance, and rejected alternatives.
  - Accept: the user explicitly approves each exact candidate. Rejected candidates remain outside
    production paths and are regenerated from the same locked brief.
- [ ] **6.3** Compile deterministic presentation-only placement.
  - Change: generate at most 72 crack, 72 stain, and 48 chip transforms from run-fixed field
    geometry plus a fixed salt. Use fixed low z, 90-degree rotations, scales
    `0.75/1.0/1.25`, minimum 140-pixel center separation, and rejection against void, walls,
    structural walls, the player-start 220-pixel clearance, and field-edge 96-pixel clearance.
    Placement must be identical across all five stages for the same field.
  - Accept: fingerprints are deterministic across rebuilds/stages; all centers are walkable and
    clear; no detail enters collision/topology data; no per-frame RNG or update occurs.
- [ ] **6.4** Integrate through retained batches and promote only approved rasters.
  - Change: add one compact-quad `MultiMeshInstance2D` batch per approved asset through the
    existing world builder; change `DECORATION_BUDGET` from zero to 192; retire the two hazard
    assets and add the three approved details, for a net manifest count of 70 if the starting
    exact count is still 69.
  - Accept: world batches remain `<=12`; detail instances remain `<=192`; no node-per-detail,
    shader noise, full-field texture, TileMap, collision, or runtime transform update exists.
    Native and Web captures at actual size, grayscale, and combat pressure show no lost actor,
    projectile, pickup, telegraph, boundary, or objective readability.
  - Guard: if the pre-edit manifest count is not 69, calculate and assert `starting - 2 + 3`
    rather than forcing 70. If three batches exceed 12 or eligible rendering evidence regresses,
    stop this branch for contract revision; do not silently add chunking or reduce thresholds.

Batch gate:

- Production manifest, import, world-visual, field-layout, stage-layout, combat-renderer, capture,
  and visual-authority validators pass; the approved runtime capture matches the promoted files.

### Phase 7: Consolidate correctness, feel, export, and performance

Goal: verify the final workload once, preserve causal evidence, and correct only a measured hitch
owner if needed.

Preconditions:

- Phases 2-6 are complete in separate scoped commits.
- Task-local failures are fixed; no unrelated process overlaps broad validation.

Source owners: all task-owned files, focused validators, export tooling, performance recorder and
scenarios, active performance policy/evidence records

- [ ] **7.1** Run the named focused correctness and authority matrix.
  - Change: run the validators named in each phase, then one consolidated union without repeating
    unchanged passing checks; run Godot headless import, `git diff --check`, document authority,
    visual authority, and a production Web export.
  - Accept: all commands exit zero, Web reports `WEB_EXPORT_OK`, and known non-blocking warnings
    are recorded once.
- [ ] **7.2** Perform built-product gameplay QA.
  - Change: use production-style native and built Web paths to check all five ordinary-health
    stages, absence of neutral hazards, one shield-up/down boss cycle, Thermal Burst at all three
    levels in a crowd and near a structure, bilingual card surfaces, and surface readability at
    actual size/grayscale.
  - Accept: the opening is less spongy, later health growth is observable without changing the
    locked curve, boss damage windows are legible, burst never double-hits/direct-chains/damages
    structures, and detail never reads as collision or combat signal.
- [ ] **7.3** Requalify the exact clean final native commit.
  - Change: after user cost alignment, repeat the Phase 1 `peak_horde` and `capacity_pressure`
    protocol from the exact clean final commit. Compare eligible fields with the Phase 1 baseline;
    save raw JSON unchanged.
  - Accept: both final samples pass the unchanged release thresholds and declared workloads.
  - Guard: because removing hazards, adding splash queries, and adding three retained batches all
    change workload, Phase 1 evidence cannot qualify the final commit.
- [ ] **7.4** Diagnose and correct only a valid red owner, then qualify built Web.
  - Change: if a valid final sample or current-commit manual trace is red, use its subsystem/slow-
    frame evidence to select one owner, make the smallest correction that preserves counts,
    cadence, collision, visuals, and thresholds, rerun affected focused validators, and repeat
    only the invalidated sample. Once native passes, collect built-Web peak through
    `$npjt-port-guard` on the `codex` lane and clean up only the task-owned server.
  - Accept: evidence links the correction to the measured owner; native and Web results are
    authority-eligible and passing; no optimization claim exceeds the evidence.
- [ ] **7.5** Close durable records and commits.
  - Change: update product/visual/performance owners with final values and evidence, mark this plan
    `done`, move it to `.agents/execplans/completed/`, and create coherent scoped commits containing
    only task-owned files.
  - Accept: working tree has no task-owned uncommitted changes, no stale active plan remains, and
    final docs do not retain superseded hazard/burn/flat-surface contracts.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | The one or two focused validators named by the active task plus `git diff --check` | After that task compiles and its direct examples are implemented | A relevant source/test/input changes |
| Gameplay phase gate | Field/terrain/map/Run validators for Phase 2; difficulty/boss/Run validators for Phase 3; build/status/attack/telemetry/report/renderer/Run validators for Phase 4 | The phase's tasks pass | A phase-owned input changes |
| Visual phase gate | Production manifest, world visual, field/stage layout, capture, import, and `validate_cardborne_visual_authority.ps1` | Contract changes in Phase 5 and approved asset integration in Phase 6 | Visual contract, raster, manifest, placement, renderer, or capture changes |
| Export gate | `./tools/godot.ps1 --path . --headless --import`; `./tools/export_web.ps1`; require `WEB_EXPORT_OK` | Once after all feature phases and affected focused validators pass | An imported asset, export-affecting source, or project setting changes |
| Native performance gate | Exact clean-commit `peak_horde` and `capacity_pressure` protocol in the prerequisite performance plan | Phase 1 baseline and Phase 7 final state, after user cost alignment | Workload/code/asset/instrumentation changes or a sample is invalid/red for a new evidence-backed hypothesis |
| Web performance gate | Built-Web `peak_horde` on the `codex` lane with exact JSON capture | Native qualification passes and matching Web artifact exists | Native/build/asset/workload changes or the sample is invalid |

Validation rules:

- Run the narrowest check that proves the current task.
- Run each named phase gate once after its owned tasks pass.
- Treat product feel checks as evidence for the locked balance, not permission to tune numbers
  opportunistically. A requested numeric change requires a contract update.
- Do not run expensive release scenarios while another Godot/test/capture process can contaminate
  them. Do not kill unrelated processes; wait for a quiet window.
- Rerun a failed check only after a relevant implementation change or a new hypothesis can produce
  new evidence.
- Record known non-blocking warnings once instead of rediscovering them.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| The user's “neutral attack zone” is proven to mean something other than map `hazard_zone` | Stop Phase 2 and ask the user to identify the exact visible mechanic | Never remove boss `denied_zones` or another attack family by inference |
| The additive health curve makes Stage 4/5 clear time fail the existing run contract | Report measured TTK/clear-time evidence and propose a new curve in this plan | Do not silently reduce quotas, populations, damage, speed, or the locked curve |
| Thermal Burst exceeds projectile/frame budgets in an eligible sample | Attribute spatial-query target count and subsystem time; optimize storage/query reuse within the same visible contract | Do not reduce trigger cadence, radius, damage, projectile count, or enemy count without contract revision |
| An exact surface candidate is rejected | Keep it outside production and regenerate from the same approved semantic/size/contrast brief | Any change to asset count, category, theme, or renderer requires plan and visual-contract revision |
| Surface detail conflicts with gameplay readability or batch cap | Remove the unapproved integration from the candidate branch and stop the visual branch | Do not lower readability/batch thresholds or invent TileMap/shader/chunking ownership |
| A valid current sample is red | Select the largest evidenced owner from slow-frame/subsystem data and make one causal correction | No broad optimization pass and no claim based on historical or invalid samples |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain any required approval before resuming | Do not let the executor choose a new product, architecture, dependency, data, UX, safety, or validation contract |

Implementation-local discoveries may be handled inside the locked contract when they cannot
change scope, visible behavior, ownership, architecture, safety, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 1 - Qualify the current performance baseline.
- Next task: 1.1 - Restore a truthful performance fixture contract.
- Last completed gate: Discovery Closure Gate.
- Update rule: after a checkpoint passes, record concise evidence, check the task, and advance this
  pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check passes.
- Every guard, phase gate, and final gate named by this contract passes.
- No placeholder or unresolved material decision remains.
- Durable product, visual, performance, and lifecycle owners contain the final contracts and
  eligible evidence.
- Frontmatter status is changed to `done` only after implementation is complete, then the plan is
  moved to `.agents/execplans/completed/`.

Replan when:

- A material discovery invalidates the locked product, semantic, visual, architecture,
  performance, safety, or validation contract.

Do not replan or stop for:

- Implementation-local mechanics already contained by this contract.
- A passing check whose relevant inputs have not changed.
