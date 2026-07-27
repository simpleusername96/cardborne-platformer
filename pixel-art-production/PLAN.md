---
type: plan
status: active
owner: BK
created: 2026-07-27
last_reviewed: 2026-07-27
scope: Produce, review, integrate, and migrate Cardborne's forty pixel-asset families through bounded user-visible gates
related:
  - ../AGENTS.md
  - ../.agents/PLANS.md
  - ../docs/product/vehicle_game_spec.md
  - ../docs/design/UI_VISUAL_SYSTEM.md
  - ./README.md
  - ./assets/asset-inventory.json
  - ./design/visual-research/PART_GUIDELINES.md
  - ./evidence/pipeline-sampler/README.md
---

# Cardborne Pixel-Asset Production — Gated Execution Plan

This plan starts after the approved six-asset sampler. It does not add another
pipeline-only phase. It first produces a bounded set of new candidate assets,
stops for a visible owner review, then proves those assets in the actual Godot
game before expanding one family group at a time. The final result is the
complete forty-family pixel migration with the current gameplay, geometry,
localization, batching, and Web-performance contracts preserved.

## Purpose

- **Objective:** apply the approved sampler's simple, flat, grid-native pixel
  grammar to every asset family in
  [`assets/asset-inventory.json`](./assets/asset-inventory.json).
- **First deliverable:** a post-sampler candidate batch that proves new
  directions, animation, projectiles, enemy silhouettes, and connected tiles.
- **Final artifact:** approved editable masters, semantic layers, manifests,
  atlases, runtime catalog, Godot integration, review evidence, and a validated
  Web build for all forty families.
- **Completion state:** no remaining production family uses the superseded
  procedural artwork, while live geometry, telegraphs, values, localization,
  focus, timers, and accessibility remain procedural or UI-owned.

## Why and Context

The six-category sampler established that one asset can be generated or
authored on a logical grid, palette-normalized, split into semantic parts,
reassembled with zero changed pixels, exported as editable pixel SVG, and
reviewed at native scale. It did not prove:

- repeatable quality on additional assets after the sampler;
- consistent directions and motion frames;
- a complete connected floor/wall family;
- actual retained-atlas rendering in Cardborne;
- gameplay-scale readability under real combat pressure; or
- production of the remaining asset library.

The previous plan spent too much execution space on foundation that is already
complete. This plan makes every remaining phase deliver new art and, from
Phase 2 onward, a user-visible game result.

## Pre-plan Evidence Already Verified

| Source or path | Verified fact | Decision derived |
| --- | --- | --- |
| [`evidence/pipeline-sampler/README.md`](./evidence/pipeline-sampler/README.md) | Six one-direction/state samples pass semantic reassembly and native-scale review but are not production families or Godot assets. | Use their grammar as the starting point, but require a new post-sampler capability gate. |
| [`assets/asset-inventory.json`](./assets/asset-inventory.json) | The inventory contains forty families: thirty raster-atlas, nine procedural-pixel, and one live-UI family; raster ceiling `678`, canonical ImageGen jobs `44`. | Keep one complete coverage ledger and do not invent untracked families. |
| [`README.md`](./README.md) and `tools/` | Brief, manifest, palette, semantic layer, exact reassembly, atlas, catalog, seam, review, frame-budget, and negative validators already pass. | No new pipeline milestone is allowed before asset production. |
| [`docs/design/UI_VISUAL_SYSTEM.md`](../docs/design/UI_VISUAL_SYSTEM.md) | The current game requires flat color, large silhouettes, exact collision/visual agreement, restrained UI, Korean-first localization, and retained rendering. | Pixel art may replace presentation, never gameplay truth or live UI state. |
| [`design/visual-research/PART_GUIDELINES.md`](./design/visual-research/PART_GUIDELINES.md) | The part guide is a `draft` candidate and explicitly does not replace the active visual specification. | Use it as production guidance until the actual-game core slice receives owner approval. |
| `scripts/presentation/vehicle_combat_renderer.gd` | Actors and projectiles use retained `MultiMesh` batches with capacities of 128 enemies, 240 player projectiles, 120 hostile projectiles, 192 XP shards, and 96 effects. | Extend the retained path; add no per-actor or per-projectile nodes. |
| `scripts/vehicle/vehicle_stage_backdrop.gd` | Static floor, void, wall, water, and cover presentation is cached separately from gameplay geometry. | Add a geometry-fed pixel world mesh builder without making art own collision. |
| `scripts/vehicle/vehicle_run.gd` | The run separately constructs backdrop, combat renderer, UI, audio, and presentation snapshots. | Integrate pixel presentation at existing owner boundaries without changing simulation state. |
| `tools/validation/validate_vehicle_combat_renderer.gd` and `scripts/performance/vehicle_performance_recorder.gd` | Current release guards include global batches `<=50`, draw-call p95 `<=200`, native frame p95 `<=18 ms`, Web p95 `<=20 ms`, Web p99 `<=33.3 ms`, and Web median `>=58 FPS`. | Every integrated phase must keep the existing workload and pass these guards. |
| Git commits `672765e`, `186b48e`, and `1b0ddd1` | The sampler, production contracts, and single production workspace are committed; no later production asset batch exists. | Mark only foundation as complete and start at Phase 1. |

## Locked Decisions

| Topic | Final decision |
| --- | --- |
| Visual starting point | The approved six-sample overview defines the initial shape, scale, palette restraint, and pixel density. It is not copied wholesale into runtime. |
| First execution unit | Produce the exact Phase 1 candidate set below. Do not begin all forty families. |
| Approval cadence | Each phase creates named review artifacts and stops at its gate. A rejected phase revises only its current assets. |
| Generation unit | One canonical object or one deliberately related motion frame per ImageGen job. No unrelated sheet or generated full scene. |
| Cleanup | Every draft is snapped, palette-normalized, semantically masked, split, exactly reassembled, and reviewed before approval. |
| Source format | Native indexed-color PNG plus same-origin transparent PNG layers; integer-cell SVG is an editable correction derivative. |
| Runtime format | PNG atlas plus JSON catalog under `pixel-art-production/runtime/`; nearest, lossless, no mipmaps, no repeat, one-pixel extrusion, two-pixel gutter. |
| Rollout flag | Add non-user-facing `cardborne/presentation/pixel_assets`, default `false` until Phase 2 owner approval. |
| Partial family rollout | Atomic families publish as a whole. Aggregate sets (`mobile_enemy_set`, `stationary_enemy_set`, `boss_set`) publish only explicitly listed `published_variants`; a listed variant with a missing frame is a hard error. |
| Renderer path | A visible instance uses exactly one legacy or pixel path. Published pixel actors/projectiles remain retained `MultiMesh` instances. |
| World path | Pixel world surfaces are generated from authoritative geometry into bounded cached textured chunks. They do not own collision or navigation. |
| State ownership | Collision, attack timing, telegraphs, health, timers, minimap position, focus, localized text, cooldowns, and live values remain current-code owned. |
| Design authority | `UI_VISUAL_SYSTEM.md` remains active until Phase 3 actual-game approval. Only that explicit approval may activate the pixel part guide and update the live visual specification. |
| Dependencies | Godot 4.7, GDScript, PowerShell, existing ImageMagick tooling, and built-in ImageGen only; no production dependency or engine change. |
| Runtime budget | Raster frames `<=678`, full pixel combat batches `<=24`, global batches `<=50`, static world chunks `<=60`, repeated-object scene nodes `0`. |

## Rejected Alternatives

| Alternative | Why rejected |
| --- | --- |
| Produce all forty families before another review | It hides whether quality remains repeatable after the sampler and makes art-direction correction too expensive. |
| Add another pipeline/tooling phase | The existing positive and negative pipeline gates already pass; it would repeat the failure that caused this plan rewrite. |
| Integrate the whole world first | It mixes tiles, collision-facing presentation, actor recognition, atlas runtime, and performance into one failure surface. |
| Generate full scenes or unrelated sheets | It breaks grid, semantic ownership, editability, and large-field composition. |
| Add `Sprite2D`/scene nodes per actor, projectile, pickup, or effect | It violates the retained-rendering performance architecture. |
| Let a `TileMapLayer` own collision | It creates a second geometry truth and risks false openings and blockers. |
| Mark the draft pixel guide active before an actual-game gate | The sampler proves production mechanics, not full gameplay readability. |

## Current State

Already landed:

- [x] Forty-family asset inventory and frame ceilings.
- [x] Display and semantic-mask palettes.
- [x] Brief and manifest schema version 2.
- [x] Semantic split, exact reassembly, SVG, atlas, catalog, review, seam,
      import-policy, and frame-budget validation.
- [x] Six-category sampler: player, shooter enemy, hostile thermal shot, repair
      fixture, wall corner, and repair pickup.
- [x] Clean production Web baseline and retained-renderer baseline.
- [x] One canonical `pixel-art-production/` workspace.

Not yet landed:

- [ ] Any approved production family.
- [ ] Any runtime atlas or runtime catalog.
- [ ] A pixel asset catalog owner or atlas shader in Godot.
- [ ] A pixel-rendered player, projectile, enemy, world tile, pickup, or UI
      element in the game.
- [ ] Actual-game owner approval of the pixel direction.

## Scope and Non-scope

In scope:

- production of all assets and variants declared in the forty-family inventory;
- per-asset source, semantic layers, manifest, atlas frame, anchors, and review;
- retained atlas rendering for actors, projectiles, pickups, and effects;
- geometry-derived pixel world chunks;
- restrained raster glyphs and frames around live UI;
- deterministic actual-game captures, focused validation, and Web export;
- removal of superseded procedural visual recipes after their replacement
  passes its family gate.

Out of scope:

- gameplay balance, damage, movement, enemy logic, encounter pacing, stage
  progression, upgrades, input, save data, collision, or navigation changes;
- a new engine, 3D asset workflow, Blender, package, plugin, or external runtime
  dependency;
- a giant field bitmap, full-scene generated background, collision-owning
  tilemap, or per-object scene-node renderer;
- rasterized Korean/English text, values, cooldowns, percentages, focus,
  selection, minimap positions, or attack footprints;
- adding content not already represented by the forty-family inventory.

Destructive actions:

- Legacy visual recipes are deleted only in Phase 8 after their replacements
  pass offline, runtime, performance, localization, and Web gates.
- Rejected drafts remain evidence; they are not published to runtime.

Approval-required actions:

- Gate A: approve the post-sampler candidate batch before runtime work.
- Gate B: approve the first live player/projectile slice before enabling it by
  default.
- Gate C: approve the actual-game core visual direction before activating the
  pixel part guide and expanding broad production.
- Gates D–H: approve each completed family group before the next group starts.

## Proposed Design

Production follows one fixed loop:

1. create or derive one bounded candidate set at native pixel size;
2. validate palette, semantic ownership, reassembly, anchors, seams, and frame
   budget offline;
3. publish only approved frames to the runtime catalog;
4. replace the matching legacy family or explicitly listed aggregate variant
   in the retained renderer;
5. validate the unchanged gameplay workload in native and Web builds;
6. present the named review artifacts and stop at the phase gate; and
7. expand only after approval.

Phase 1 runs only steps 1–2 and demonstrates post-sampler production ability.
Phase 2 proves steps 3–6 with the isolated player/projectile slice. Phase 3
adds actual world and enemy readability. Phases 4–8 repeat the same loop for
the remaining family groups. No phase may substitute tooling work for its
required visible assets.

## Architecture and Ownership

| Concern | Owner | Interface and invariant |
| --- | --- | --- |
| Inventory and production contract | `pixel-art-production/assets/asset-inventory.json`, `pixel-art-production/README.md` | Every production asset maps to one declared family, method, native size, frame ceiling, and runtime group. |
| Editable sources | `pixel-art-production/assets/source/<family>/<asset-id>/` | Native masters and same-origin semantic layers only. |
| Briefs and manifests | `pixel-art-production/assets/briefs/`, `pixel-art-production/assets/manifests/` | Candidate/approved status, frame IDs, checksums, pivots, anchors, and semantic ownership. |
| Offline generated output | `pixel-art-production/assets/generated/` | Reproducible atlases and review metadata; never raw model output. |
| Review evidence | `pixel-art-production/evidence/gates/<gate-id>/` | Native, enlarged, silhouette, grayscale, backdrop, seam, direction, animation, and actual-game evidence. |
| Runtime publication | `pixel-art-production/runtime/` | Approved atlases, catalog, and shader resources visible to Godot. |
| Runtime lookup | new `scripts/presentation/vehicle_pixel_asset_catalog.gd` | Immutable catalog; explicit published families/variants; missing published frame fails loudly. |
| Combat rendering | `scripts/presentation/vehicle_combat_renderer.gd` | Atlas-capable retained `MultiMesh`; no repeated-object nodes; exactly one presentation path per instance. |
| Legacy combat shapes | `scripts/presentation/vehicle_combat_visual_library.gd` | Retained only for unpublished variants, then removed family by family. |
| Static world | `scripts/vehicle/vehicle_stage_backdrop.gd` plus new `scripts/vehicle/vehicle_pixel_world_mesh_builder.gd` | Authoritative geometry produces cached textured chunks; art never changes collision. |
| Run orchestration | `scripts/vehicle/vehicle_run.gd` | Supplies existing presentation snapshots and feature flag; does not derive art-owned gameplay state. |
| UI and localization | existing Godot theme and UI scripts | Text, values, state, focus, layout, and accessibility remain live. |

## As-Is / To-Be Delta Map

| Concern | As-is | To-be | Acceptance | Guard |
| --- | --- | --- | --- | --- |
| Post-sampler capability | Six isolated one-direction/state proofs | New bounded candidates demonstrate additional shapes, cardinal directions, motion, and complete wall topology | Gate A review approved | No runtime work before Gate A |
| Combat art | Procedural meshes in retained batches | Atlas quads in the same retained architecture | Gate B actual-game capture and validators | No actor/projectile nodes or duplicate legacy batch |
| World art | Cached procedural draw geometry | Cached geometry-fed textured chunks | Gate C/D collision-overlay and seam proof | No art-derived collision or fake opening |
| Family rollout | No pixel runtime | Explicit published families/variants with hard missing-frame failure | Catalog validator passes | Unpublished variants remain explicitly legacy |
| UI ornament | Live controls plus current flat theme | Small pixel glyph/corner assets around unchanged live controls | Gate H multilingual viewport review | No raster text/value/state or new bulky panels |
| Legacy removal | All procedural visual recipes active | Only un-migrated families retain legacy recipes | Final catalog and code search | Never delete before family acceptance |

## Milestone Sequence

| Phase | User-visible proof | Gate |
| ---: | --- | --- |
| 1 | New post-sampler direction, motion, projectile, enemy, floor, and wall review boards | Gate A |
| 2 | Pixel player and primary fire running in the current game and Web build | Gate B |
| 3 | Core Stage 1 world/enemy/projectile/pickup visual hierarchy | Gate C |
| 4 | Every functional terrain and facility state in the actual field | Gate D |
| 5 | Complete ordinary/stationary enemy silhouette and startup library | Gate E |
| 6 | Five simultaneous secondary behaviors and persistent player cues | Gate F |
| 7 | Five bosses and contact feedback in Boss Practice and the run | Gate G |
| 8 | Multilingual HUD/guidebook/upgrade ornament and final Web migration | Gate H |

## Tasks

### Phase 1 — Post-sampler production capability

**Goal:** prove that additional assets—not only the original six samples—can be
made coherently before any runtime integration.

**Source owners:** `assets/asset-inventory.json`, `assets/briefs/`,
`assets/manifests/`, `assets/source/`, `assets/generated/`,
`evidence/gates/01-post-sampler-capability/`.

- [x] **1.1 Create candidate contracts for the exact gate set.**
  - `player_chassis`: north, east, south, and west normal frames based on the
    approved interceptor grammar.
  - `player_primary_weapon`: new north/east/south/west idle frames with stable
    muzzle anchors.
  - `player_engine_flame`: one north-facing four-frame thrust cycle authored
    directly.
  - `player_primary_projectiles`: new standard and opening-Breach shapes in
    four cardinal directions with `flight_0` and `flight_1`.
  - `mobile_enemy_set`: new `chaser` and sampler-derived `shooter`, each with
    four cardinal `move` and `attack_startup` frames.
  - `world_floor_void_tiles`: exactly eight frames—one each for `space_void`,
    `floor_light`, `floor_mid`, and `floor_dark`, plus four ordered quadrants
    (`sequence_index` 0–3: north-west, north-east, south-west, south-east) for
    the single `floor_patch_2x2` variant.
  - `wall_cover_tiles`: all sixteen orthogonal signatures.
  - Set every manifest to `approval_status: candidate`; publish none to
    `runtime/`.
  - **Accept:** every item validates against the existing brief/manifest
    schemas and stays within its inventory ceiling.
  - **Guard:** do not add a family, increase a frame ceiling, or substitute a
    sampler-only ID.

- [x] **1.2 Produce one canonical source per new ImageGen job.**
  - Use one logical guide per object and the locked display palette.
  - Use the approved sampler only as grammar evidence, not as a sheet to trace.
  - Generate only primary weapon, standard shot, Breach shot, and chaser; reuse
    the accepted player/shooter silhouette as candidate input and author
    flame/floor/walls directly.
  - **Accept:** one object per draft, flat contiguous cells, no texture,
    gradient, antialiasing, glow, full scene, or unrelated object.
  - **Guard:** one failed cell-following draft gets one targeted retry; after
    that, correct that object directly at native resolution.

- [x] **1.3 Derive and correct the bounded direction and motion set.**
  - Nearest transforms are starting points only; correct each cardinal frame at
    native resolution.
  - Declare chassis center, weapon muzzle, and projectile head/rear anchors.
  - **Accept:** anchor drift is at most one native pixel; front/rear remains
    unambiguous; projectile head equals its declared visible collision extent.
  - **Guard:** do not regenerate each direction independently and do not move
    gameplay anchors to accommodate a bad drawing.

- [x] **1.4 Build semantic layers and exact outputs.**
  - Run palette mapping, mask validation, same-origin layer split, reassembly,
    pixel-SVG export, candidate atlas, and review generation.
  - **Accept:** unknown colors `0`, partial alpha `0`, semantic gaps/overlap
    `0`, and reassembly difference `0` pixels.
  - **Guard:** raw ImageGen output never enters candidate or runtime atlases.

- [x] **1.5 Create Gate A evidence.**
  - `category-review.png`: native `1x`, `8x`, silhouette, grayscale, and every
    permitted backdrop.
  - `direction-motion-review.png`: cardinal direction and animation stability.
  - `wall-signatures.png`: all sixteen signatures and deterministic `3x3`
    assemblies.
  - `candidate-catalog.json`: exact candidates, checksums, review status, and
    rejected-frame list.
  - **Accept:** player, enemy, friendly projectile, hostile role, floor, and
    blocker remain recognizable without labels or color.
  - **Guard:** no staged game integration or production expansion is permitted
    before owner review.

**Gate A — owner review:** stop and present the four artifacts. Approval changes
only this candidate set to `approved`. Rejection revises only named failing
assets and repeats Gate A; Phase 2 remains blocked.

**Current gate state:** Phase 1 production is complete. The owner approved
continuing from the sampler through the full migration on 2026-07-27, so Gate A
is approved and later gates are execution checkpoints rather than chat pauses.

### Phase 2 — First live player and projectile slice

**Goal:** prove that approved pixel art works in the current retained renderer
without changing simulation, collision, controls, or performance.

**Source owners:** Phase 1 approved player assets,
`pixel-art-production/runtime/`, `project.godot`,
`scripts/presentation/vehicle_pixel_asset_catalog.gd`,
`scripts/presentation/vehicle_combat_renderer.gd`,
`scripts/presentation/vehicle_combat_visual_library.gd`,
`tools/validation/validate_vehicle_pixel_asset_catalog.gd`.

- [x] **2.1 Complete the six player-side production families.**
  - Complete `player_chassis`, `player_primary_weapon`,
    `player_engine_modules`, `player_engine_flame`, `player_dash_effect`, and
    `player_primary_projectiles` to the exact inventory directions, states,
    anchors, and frame ceilings.
  - Use live tint/alpha for hit, invulnerability, and upgrade shade; do not
    duplicate full chassis frames for them.
  - **Accept:** every frame passes native, silhouette, direction, motion,
    semantic, anchor, and budget review.
  - **Guard:** count-readable engine modules remain composited modules, not
    unique full-ship sprites.

- [x] **2.2 Publish the first runtime catalog.**
  - Add `cardborne/presentation/pixel_assets=false` to `project.godot`.
  - Publish approved atlases, JSON catalog, and
    `runtime/shaders/pixel_atlas_multimesh.gdshader`.
  - Add `vehicle_pixel_asset_catalog.gd` with immutable frame records,
    explicit `published_families`, pivots, anchors, and direction lookup.
  - Add `validate_vehicle_pixel_asset_catalog.gd`.
  - **Accept:** a valid frame resolves deterministically; a missing frame in a
    published family fails validation and never silently displays another
    frame.
  - **Guard:** offline references, raw drafts, and evidence stay excluded from
    Godot and Web export.

- [x] **2.3 Add the retained atlas presentation path.**
  - Extend `VehicleCombatRenderer` with atlas-backed quad meshes using
    per-instance custom UV data and existing transforms.
  - Select legacy or pixel once per published family; never instantiate both.
  - Preserve procedural target markers, barrier, health, hit tint, telegraphs,
    and all gameplay-owned geometry.
  - **Accept:** player movement, aim, held fire, opening Breach shot, dash, hit,
    and projectile-wall contact remain behaviorally unchanged.
  - **Guard:** actor/projectile scene nodes remain `0`; global batch count stays
    `<=50`.

- [x] **2.4 Create Gate B actual-game evidence.**
  - Capture legacy and pixel views at `1280x720` for idle/facing, held fire,
    opening Breach, dash, accepted hit, ordinary pressure, and hard pressure.
  - Export and run the production Web build.
  - **Accept:** the craft remains the first combat anchor; ordinary and Breach
    fire stay distinct; no visual/collision mismatch; performance passes.
  - **Guard:** do not reduce enemies, projectiles, effects, physics rate, or
    camera scope to pass.

**Gate B — owner review:** stop with the built game and comparison captures.
Approval changes the feature flag default to `true` for published player
families only. Rejection leaves the default `false`, revises only player/runtime
presentation, and repeats Gate B.

### Phase 3 — Core field readability slice

**Goal:** prove the complete visual grammar in a real Stage 1 camera view before
broad production.

**Family coverage:** `world_floor_void_tiles`, `wall_cover_tiles`,
`hostile_projectile_affinities`, `experience_shards`, `repair_pickup`,
`experience_recall_pickup`, `reward_crate`, `telegraph_shape_system`, and
`world_targeting_markers`; publish `scrap_drone`, `chaser`, and `shooter`
variants from `mobile_enemy_set`.

- [ ] **3.1 Finish and approve the core sources.**
  - Complete the three mobile roles, three XP shells, repair/recall pickups,
    reward-crate states, the exact eight floor/void frames defined in Phase 1,
    and all wall signatures.
  - Complete `hostile_projectile_affinities` as exactly eighteen atlas frames:
    for each of `kinetic`, `thermal`, `toxin`, `cryo`, `arc`, and `hybrid`,
    produce `standard_0`, `affinity_motion_0`, and `affinity_motion_1`.
    Normalize the inventory state declaration to those three produced states
    in the same change. Preserve the six-pixel canonical head; gameplay-owned
    light, standard, and heavy collision radii scale the complete head to
    exactly five, six, and seven visible pixels at runtime.
  - Keep exact telegraphs and targeting markers procedural-pixel.
  - **Accept:** roles remain distinct in black silhouette and dense grayscale
    review; projectiles remain visible over every world color.
  - **Guard:** no color-only role, condition promise, fake collision seam, or
    baked warning footprint.

- [ ] **3.2 Add geometry-fed world rendering.**
  - Add `vehicle_pixel_world_mesh_builder.gd`.
  - Feed it the existing immutable floor, void, wall, and cover polygons.
  - Cache bounded textured chunks; rebuild only when the field/layout
    fingerprint changes.
  - Add `validate_vehicle_pixel_world_renderer.gd`.
  - **Accept:** visible openings, blocker edges, projectile clipping, minimap
    geometry, and navigation truth agree; chunks `<=60`.
  - **Guard:** no giant field bitmap, tile-owned collision, or small unusable
    visual gap.

- [ ] **3.3 Publish explicit aggregate variants.**
  - Catalog `scrap_drone`, `chaser`, and `shooter` as published variants.
  - Unlisted mobile variants remain explicitly legacy.
  - **Accept:** each visible enemy instance selects exactly one renderer and a
    missing published variant frame hard-fails validation.
  - **Guard:** no family-wide silent fallback.

- [ ] **3.4 Create Gate C actual-game evidence.**
  - Capture calm center, broad lane, wall opening, ordinary pressure,
    maximum-pressure projectiles/XP, crate/pickups, and grayscale at
    `1280x720`.
  - Show that the field continues beyond all four viewer edges.
  - **Accept:** floor, blockers, player, threats, hostile/friendly shots,
    pickups, and support read in the required hierarchy.
  - **Guard:** no boxed one-screen arena, decorative micro-pattern, or bulky UI
    added to compensate for weak art.

**Gate C — owner art-direction approval:** stop with the built Web slice and
captures. Approval activates the accepted rules in
`PART_GUIDELINES.md`, updates the world/actor clauses in
`UI_VISUAL_SYSTEM.md`, and unlocks broad family production. Rejection changes
only the core assets or grammar named by the owner and repeats Gate C.

### Phase 4 — World functions and facilities

**Goal:** complete every remaining environment, terrain, and facility family.

**Family coverage:** `water_void_edge_tiles`, `arc_surge_strip`,
`breakable_bulkhead`, `transit_gate`, `repair_field`, and `overdrive_field`.

- [ ] Produce all declared states and semantic parts.
- [ ] Reuse the approved repair-fixture grammar for `repair_field`; do not
      publish the sampler proof itself.
- [ ] Pair each visible state with its existing exact footprint, lifetime,
      collision, projectile, and minimap truth.
- [ ] Validate tile seams, bulkhead open/closed clearance, gate traversal,
      support-field timing, non-overlap, and maximum-pressure visibility.
- [ ] Capture every facility inactive/active/expiring and every terrain
      boundary in the actual field.

**Gate D:** stop with the field-function catalog and actual-game captures.
Rejected facilities return only to their canonical base/state frames.

### Phase 5 — Complete enemy library

**Goal:** finish every ordinary, stationary, elite, and condition-facing enemy
visual without turning roles into color swaps.

**Family coverage:** complete `mobile_enemy_set`; complete
`stationary_enemy_set`; produce `elite_trait_overlays` and
`enemy_condition_overlays`.

- [ ] Produce the remaining ten mobile bases and all six stationary bases from
      their inventory names.
- [ ] Expand only approved canonical bases into required directions and visible
      attack states.
- [ ] Keep burn, poison, chill, barrier, health, exact startup, and attack
      geometry composited/live.
- [ ] Review every role as black silhouette, at native scale, in three-to-five
      enemy groups, during startup, and under maximum pressure.
- [ ] Publish variants only after each variant passes; remove its legacy recipe
      in the same accepted family commit.

**Gate E:** stop with mobile/stationary catalogs, startup comparisons, and dense
actual-game captures. Any confusing role is revised before secondary or boss
production begins.

### Phase 6 — Secondary weapons and player upgrade cues

**Goal:** make the five passive secondary behaviors and necessary persistent
ship/projectile cues immediately distinguishable.

**Family coverage:** `secondary_seeker`, `secondary_ion_field`,
`secondary_orbit_blades`, `secondary_wake_mines`,
`secondary_escort_drone`, `player_status_overlays`, and
`player_projectile_modifier_overlays`.

- [ ] Produce the declared secondary frames and anchors.
- [ ] Keep ion radius, blade orbit, mine trigger/explosion radius, seeker
      steering, drone follow path, counts, cooldowns, and timers live.
- [ ] Use module count where count is already readable; use controlled shade or
      one large status cue only where the active visual spec requires it.
- [ ] Capture each secondary alone and all five operating together under
      pressure.
- [ ] Validate friendly/hostile separation in color and grayscale.

**Gate F:** stop with five behavior captures and the upgraded-ship comparison.
No redundant color tier is added where count, radius, or motion already shows
the upgrade.

### Phase 7 — Bosses and combat feedback

**Goal:** complete large threat identity and contact feedback without moving
attack truth into bitmaps.

**Family coverage:** `boss_set` and `impact_effects`.

- [ ] Produce `colossus`, `leviathan`, `titan`, `behemoth`, and `crown` as
      separate canonical silhouettes with readable modules and phase cores.
- [ ] Produce five four-frame impact families at native size.
- [ ] Preserve live boss attack startup, exact paths/areas, autonomous attacks,
      module state, health, status, and off-screen warnings.
- [ ] Review partial-offscreen bosses, each visible startup, phase transition,
      module damage, and impact contact at native scale.
- [ ] Validate all five in Boss Practice and in the connected run.

**Gate G:** stop with Boss Practice captures and attack-alignment overlays. A
boss that reads as an enlarged ordinary enemy or obscures a telegraph is
reworked before UI/final migration.

### Phase 8 — UI glyphs, derived previews, and final migration

**Goal:** finish the remaining visual families, preserve live multilingual UI,
and retire the last superseded procedural recipes.

**Family coverage:** `hud_action_icons`, `minimap_world_markers`,
`guidebook_previews`, `upgrade_card_icons`, `ui_frame_system`, and
`dynamic_combat_ui`.

- [ ] Produce six HUD action glyphs and all current upgrade-card glyphs.
- [ ] Keep minimap positions, exploration, clustering, priority, timers, and
      support lifetime procedural; author its stable marker silhouettes as
      retained procedural-pixel geometry rather than atlas sprites.
- [ ] Derive guidebook previews from approved runtime frames; locked entries
      remain neutral live silhouettes.
- [ ] Add only minimal scalable pixel corners/edges around existing controls.
- [ ] Keep `dynamic_combat_ui` entirely live and verify it rather than
      rasterizing it.
- [ ] Review Korean and English at `960x540`, `1280x720`, and `1920x1080`.
- [ ] Run full native/Web performance and connected-run validation.
- [ ] Remove the presentation flag and remaining superseded procedural visual
      recipes only after all families are approved and the pixel path is the
      sole production path.

**Gate H — final approval:** deliver the complete catalog, asset coverage
ledger, multilingual captures, Boss Practice, connected run, and production Web
build. Mark this plan `done` only after every completion criterion passes.

## Family Coverage Ledger

Every inventory family has exactly one completion phase:

| Phase | Families completed |
| --- | --- |
| 2 | `player_chassis`, `player_primary_weapon`, `player_engine_modules`, `player_engine_flame`, `player_dash_effect`, `player_primary_projectiles` |
| 3 | `world_floor_void_tiles`, `wall_cover_tiles`, `hostile_projectile_affinities`, `experience_shards`, `repair_pickup`, `experience_recall_pickup`, `reward_crate`, `telegraph_shape_system`, `world_targeting_markers` |
| 4 | `water_void_edge_tiles`, `arc_surge_strip`, `breakable_bulkhead`, `transit_gate`, `repair_field`, `overdrive_field` |
| 5 | `mobile_enemy_set`, `stationary_enemy_set`, `elite_trait_overlays`, `enemy_condition_overlays` |
| 6 | `secondary_seeker`, `secondary_ion_field`, `secondary_orbit_blades`, `secondary_wake_mines`, `secondary_escort_drone`, `player_status_overlays`, `player_projectile_modifier_overlays` |
| 7 | `boss_set`, `impact_effects` |
| 8 | `hud_action_icons`, `minimap_world_markers`, `guidebook_previews`, `upgrade_card_icons`, `ui_frame_system`, `dynamic_combat_ui` |

The ledger totals forty families. Phase 1 creates candidates from later
families but declares none complete.

## Test Plan and Validation Cadence

### Per-asset inner loop

```powershell
.\pixel-art-production\tools\design\validate_pixel_asset_brief.ps1 `
  -BriefPath <brief>

.\pixel-art-production\tools\design\validate_pixel_asset_manifest.ps1 `
  -ManifestPath <manifest> `
  -RequireInputFiles

.\pixel-art-production\tools\design\invoke_pixel_asset_build.ps1 `
  -ManifestPath <manifest> `
  -OutputDirectory <build-directory>

.\pixel-art-production\tools\design\build_pixel_asset_review.ps1 `
  -ManifestPath <manifest> `
  -BuildDirectory <build-directory> `
  -OutputPath <review.png>
```

### Offline batch gate

```powershell
.\pixel-art-production\tools\validation\validate_pixel_asset_pipeline.ps1
```

This gate must continue rejecting checksum mismatch, unknown display/semantic
color, partial alpha, semantic gap/overlap, missing layer/frame, duplicate frame
key, incomplete review, frame-budget overflow, atlas bleed, and tile-seam
failure.

### Runtime focused gate

Run after Phase 2 and every later phase:

```powershell
.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_pixel_asset_catalog.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_combat_renderer.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_projectile_store.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_performance_scenarios.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_run.gd
```

Add and run `validate_vehicle_pixel_world_renderer.gd` from Phase 3 onward.
Run the existing terrain, guidebook, stage UI, localization, secondary, boss,
and report validators when their owners are touched.

### Full repository gate

```powershell
Get-ChildItem tools/validation -Filter *.gd | Sort-Object Name | ForEach-Object {
  .\tools\godot.ps1 --headless --script ("res://tools/validation/" + $_.Name)
  if ($LASTEXITCODE -ne 0) { throw "Validation failed: $($_.Name)" }
}

.\tools\export_web.ps1
```

Final rendered evidence uses the production Web build and the deterministic
capture path from the repository `README.md`.

### Runtime thresholds

| Metric | Required result |
| --- | ---: |
| Raster atlas frames | `<=678` |
| Full pixel combat batches | `<=24` |
| Global retained batches | `<=50` |
| Static world chunks | `<=60` |
| Per actor/projectile/pickup/effect nodes | `0` |
| Draw calls p95 | `<=200` |
| Native `1280x720` frame p95 | `<=18 ms` |
| Web `1280x720` median | `>=58 FPS` |
| Web `1280x720` frame p95 | `<=20 ms` |
| Web `1280x720` frame p99 | `<=33.3 ms` |
| Consecutive post-warmup frames over `33.3 ms` | at most `2` |

Rerun a failed narrow check only after a concrete change or new hypothesis.
Rerun full gates only after a complete phase or a fix that could affect them.

## Predetermined Error Handling and Contingencies

| Trigger | Required response | Escalation limit |
| --- | --- | --- |
| ImageGen ignores whole cells | Retry that one object once with the matching cell-fill reference, then correct directly at native size. | Never lower native size or generate a sheet. |
| Candidate silhouette is unclear | Enlarge or simplify its dominant mass inside the same brief. | Do not add labels, glow, texture, or new semantic color. |
| Direction/anchor drift exceeds one pixel | Redraw only that derived frame at native size. | Do not regenerate the base or move gameplay anchors. |
| Semantic split cannot be exact | Simplify contiguous part boundaries in the canonical source. | Do not guess layer ownership. |
| Connected seam fails | Correct native border cells and rerun all signatures/`3x3` proofs. | Do not hide seams with blur, decals, noise, or collision changes. |
| A published frame is missing | Fail catalog validation and disable that candidate build. | Never substitute a neighboring frame silently. |
| Runtime slice exceeds `50` batches | Replace, rather than coexist with, the corresponding legacy batch. | Do not reduce gameplay density. |
| Web fails while native passes | Profile atlas upload, transparent overdraw, shader sampling, and chunk culling in that order. | Do not relax thresholds or call a headless microbenchmark a release pass. |
| Visual and collision truth differ | Fix geometry-to-presentation mapping. | Do not derive collision from art. |
| Owner rejects a gate | Revise only the assets/rules named at that gate and repeat the same evidence. | Do not begin the next phase. |
| Owner changes the accepted art direction | Stop, update the active visual spec and this plan, then repeat Gate C. | Do not continue broad production under mixed rules. |

## Rollback and Safety

- Commit by one candidate batch, one runtime boundary, or one accepted family
  group; never mix gameplay or balance changes into art commits.
- Keep legacy presentation for every unpublished family/variant.
- A rollback disables the pixel flag or removes the rejected family/variant
  from the published catalog; it never rewinds simulation state.
- Generated atlases remain reproducible from committed manifests and native
  masters.
- Raw generation drafts stay evidence and never become build dependencies.
- Do not delete current visual recipes until their accepted replacement and
  fallback both pass the relevant gate.
- Do not stage or modify unrelated user changes.

## Risks

| Risk | Control |
| --- | --- |
| Another long foundation pass produces no new art | Phase 1 permits candidate art only; no tooling milestone exists. |
| Quality collapses after the sampler | Gate A tests new shapes, directions, motion, and topology before runtime investment. |
| Direction/state combinations become uneditable | One approved canonical base, deterministic derivation, semantic layers, stable anchors, and fixed ceilings. |
| Actual game looks worse than review sheets | Gates B–H require built-game captures, not only offline boards. |
| Enemies become color swaps | Unique black silhouettes and startup-state comparisons per role. |
| Pixel world creates false collision | Geometry-fed chunks, seam checks, debug overlays, and no art-owned collision. |
| Atlas integration regresses performance | Retained batches, one path per instance, fixed node/batch/frame/chunk limits, native and Web pressure gates. |
| UI becomes bulky or illegible | Raster only stable glyphs/edges; live multilingual layout and states remain current owners. |
| Plan is called complete after tooling only | Completion requires all forty families, actual-game gates, full validators, and production Web. |

## Assumptions

No material implementation assumptions remain. The user-approved sampler,
forty-family inventory, current Godot owners, generation boundary, file formats,
feature flag, rollout granularity, validation commands, gate evidence, rollback
path, and performance thresholds are fixed. A change to any of these is owner
change control.

## Open Questions

None. Gate approval evaluates the already-defined visible result; it is not an
invitation to choose architecture, scope, tooling, or asset families during
execution.

## Decision Notes

- 2026-07-27: Treat the six sampler assets as an approved visual starting point
  and technical proof, not completed production families.
- 2026-07-27: Remove any further pipeline-only phase; every remaining phase
  produces new art.
- 2026-07-27: Add a post-sampler capability gate before runtime integration.
- 2026-07-27: Prove player/projectile runtime integration before world or enemy
  migration.
- 2026-07-27: Require actual-game core approval before broad production or
  activation of the draft pixel part guide.
- 2026-07-27: Keep all production material and approved runtime publication
  under `pixel-art-production/`.

## Progress

- [x] Foundation: inventory, contracts, tools, six sampler assets, baseline,
      and consolidated workspace.
- [ ] Phase 1: post-sampler production capability and Gate A.
- [ ] Phase 2: first live player/projectile slice and Gate B.
- [ ] Phase 3: core field readability slice and Gate C.
- [ ] Phase 4: world functions/facilities and Gate D.
- [ ] Phase 5: complete enemy library and Gate E.
- [ ] Phase 6: secondaries/player cues and Gate F.
- [ ] Phase 7: bosses/combat feedback and Gate G.
- [ ] Phase 8: UI/final migration and Gate H.
- [ ] Final full validation and production Web handoff.

## Next Steps

1. Execute **Phase 1 only**.
2. Generate the four Gate A review artifacts.
3. Stop and present Gate A to the owner.
4. Begin Phase 2 only after explicit Gate A approval.

## Completion Criteria

- [ ] All forty inventory families are completed exactly once in the coverage
      ledger.
- [ ] Every approved raster frame has a native master, semantic layers,
      manifest, checksum, stable pivot/anchors, atlas entry, and review.
- [ ] Every generated canonical job obeys the one-object grid boundary.
- [ ] Every semantic reassembly changes zero pixels.
- [ ] All connected tiles pass every signature and deterministic `3x3` proof.
- [ ] Player, every enemy role, every projectile owner/weight/affinity, every
      pickup, every secondary, and every boss remain readable at native scale
      and in grayscale.
- [ ] Visible world boundaries and projectile/telegraph extents match
      gameplay-owned truth.
- [ ] No repeated combat object owns a scene node and all frame, batch, chunk,
      draw-call, native, and Web thresholds pass.
- [ ] Korean and English UI pass at all three supported review sizes with no
      clipping, overflow, rasterized text, or hidden state.
- [ ] The connected run and Boss Practice pass in the production Web build.
- [ ] No superseded legacy visual recipe, duplicate production path,
      placeholder, stale path, or unresolved material decision remains.

## Stop Conditions

Complete when every completion criterion and Gate H passes.

Escalate only when the owner changes a locked visual/product decision, a
declared inventory ceiling cannot represent required gameplay, or a current
runtime contract makes the selected retained-atlas path impossible.

Do not stop because asset production is repetitive, a phase is large, or a
single candidate needs correction. Stop only at the named gates, a verified
technical blocker, or completion.

## Handoff

```text
Goal:
Produce all Cardborne pixel assets through small visible approval gates and
integrate them without changing gameplay truth or retained-renderer budgets.

Read first:
pixel-art-production/PLAN.md
pixel-art-production/README.md
pixel-art-production/assets/asset-inventory.json
docs/design/UI_VISUAL_SYSTEM.md

Execute exactly:
Start Phase 1 only. Do not add another pipeline phase and do not start runtime
integration before Gate A approval.

Validate with:
pixel-art-production/tools/validation/validate_pixel_asset_pipeline.ps1
the named Gate A review artifacts

Stop when:
Gate A artifacts are ready for owner review.
```
