---
type: plan
status: active
owner: BK
created: 2026-07-27
last_reviewed: 2026-07-27
scope: Recover Cardborne's pixel-art presentation from procedural placeholder publication to reviewed grid-native ImageGen-assisted assets
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../pixel-art-production/README.md
  - ../../pixel-art-production/PLAN.md
  - ../../pixel-art-production/design/experiment/single-asset-grid/README.md
---

# Pixel-Art Visual Recovery — Execution Plan

Recover the live game from the completed-but-rejected procedural pixel
migration. The work keeps the existing Godot geometry, retained batching,
gameplay, localization, and accessibility owners, but replaces synthetic shape
publication with reviewed grid-native assets whose actual production origin is
recorded truthfully.

## Purpose

- **Objective:** make the live map, player, enemies, projectiles, pickups,
  facilities, bosses, and restrained raster UI ornament visibly match the
  Sunken Ceramic Fresco direction at gameplay scale.
- **First user-visible artifact:** one complete live core slice containing
  generated floor/wall/water materials, the 64×64 player chassis, one common
  enemy, and one pickup.
- **Completion state:** no catalog family marked `imagegen_assisted` is supplied
  by a procedural rectangle/circle/polygon fallback, and every raster family
  passes native, gameplay, Korean/English, native-build, Web-build, and
  performance gates.

## Pre-plan Evidence Already Verified

| Source or path | Verified fact | Decision affected | Recheck boundary |
| --- | --- | --- | --- |
| `pixel-art-production/evidence/gates/08-final-migration/03-core-field.png` | The published core set is dominated by generic geometric silhouettes and flat stripe tiles. | Treat the completed migration as visually rejected; do not expand its grammar. | Recheck after each recovery batch. |
| `pixel-art-production/evidence/gates/08-final-migration/gameplay-pass-2/03-maximum-pressure-xp.png` | The repeated floor lines dominate the field while actors and pickups collapse to tiny symbols. | The first batch must include map materials and gameplay-scale actor/pickup evidence. | Same deterministic capture after integration. |
| `tools/design/generate_complete_pixel_library.gd` | `_produce_inventory_asset()` calls `_make_sprite()` for non-imported families, and `_make_sprite()` builds rectangles, circles, polygons, and lines. | Procedural fallback may never satisfy an `imagegen_assisted` family. | Validator and code-search gate. |
| `pixel-art-production/runtime/catalog.json` | The catalog publishes 40 families and 644 frames, while provenance labels are inherited from inventory rather than verified per source frame. | Production origin must be frame-backed and validator-enforced. | Every runtime catalog build. |
| `pixel-art-production/design/experiment/single-asset-grid/README.md` | The accepted method is a supplied logical-cell guide, one generated asset, deterministic snapping, palette cleanup, semantic ownership, and direct pixel correction. | Use that method for every recovered raster master. | Per generated master. |
| `docs/design/UI_VISUAL_SYSTEM.md` | Sunken Ceramic Fresco, Korean-first parity, first-clear readability, flat colors, and gameplay-owned geometry remain active. | Preserve the design system and all live state owners. | Final Level 4 UIUX gate. |
| `pixel-art-production/README.md` | Native masters are 24×24 world tiles, 64×64 player, 32×32 common enemy/projectile, 24×24 pickup, and 96×96 boss. | A 64×64 grid is used for the player; each other family uses its declared native grid rather than shrinking a full map to 64×64. | Inventory/manifest validator. |
| `scripts/presentation/vehicle_combat_renderer.gd` | High-count combat art already uses retained atlas `MultiMesh` batches. | Replace atlas sources/catalog entries, not the renderer ownership model. | Renderer and performance validators. |
| `scripts/presentation/vehicle_pixel_world_mesh_builder.gd` | Three repeat textures are fed by authoritative floor, water, and cover geometry. | Replace material images without deriving collision from pixels. | Geometry fingerprint and collision-overlay capture. |
| Git `c494751` and `147f916` | The rejected look arrived in the final migration and player-slice commits; the worktree was clean at recovery start. | Preserve history and correct forward in scoped commits. | Before every commit. |

## Locked Decisions

| Topic | Final decision | Rationale |
| --- | --- | --- |
| Visual direction | Sunken Ceramic Fresco translated into restrained, grid-native top-down pixel art with large ceramic inlays and clear silhouettes. | Active design specification and user correction. |
| Generation route | Built-in Image Gen only, one asset or related frame per call, using the exact logical-grid guide plus whole-cell behavior and style references. | Existing accepted experiment; no API key or dependency. |
| Native sizes | Floor/wall/water `24×24`; player `64×64`; common enemy `32×32`; pickup `24×24`; later families follow `asset-inventory.json`. | Existing pipeline contract. |
| Raw output | Raw model output is evidence, never runtime art. | Image Gen does not enforce whole cells or the palette exactly. |
| Cleanup | Normalize, snap to the declared grid, remove white, remap to `pixel-hangar-v1`, correct symmetry/seams/anchors, then build semantic layers and exact reassembly. | Existing deterministic production contract. |
| Runtime publication | Import approved recovery frames ahead of procedural fallback into the existing shared atlas and catalog. | Preserves retained batching and avoids a second renderer. |
| Missing approved art | An `imagegen_assisted` family with no reviewed source fails publication; it is never silently fabricated by `_make_sprite()`. | Fixes the provenance defect. |
| Direct-pixel allowance | `procedural_pixel` and explicitly `direct_pixel` families may remain code-authored only when the inventory and runtime catalog both say so. | Live telegraphs, timers, positions, and localized UI remain dynamic. |
| Mounted primary | The fixed mount stays in `player_chassis`; the independently aimed barrel, recoil offset, and muzzle flash are retained live direct-pixel presentation, not a separate raster family. | Manual aim remains responsive without multiplying or regenerating 64×64 weapon frames. |
| Map ownership | Art is repeated/positioned from stage geometry; collision, navigation, line of sight, projectile walls, and minimap geometry remain unchanged. | Product and design invariants. |
| Rollout unit | Six visible masters per batch, followed by native and gameplay review before the next batch. | Keeps rejection/revision bounded. |
| Dependencies | Godot 4.7, GDScript, existing PowerShell/ImageMagick tools, and built-in Image Gen only. | No dependency change is needed. |

## Rejected Alternatives

| Alternative | Why it was viable | Why it was rejected |
| --- | --- | --- |
| Keep the generated atlas and only adjust colors/import settings | Fast and low-risk. | The defect is silhouette/source quality, not filtering. |
| Generate one complete map screenshot and use it as the field | It could look richer quickly. | It would disagree with deterministic stage geometry and collision. |
| Use one 64×64 grid for the whole game scene | It follows a literal but over-broad reading of the grid request. | It collapses tiles, enemies, projectiles, and pickups below their declared native contracts. |
| Hand-code more elaborate procedural shapes | It preserves deterministic output. | It repeats the rejected production path and still does not use the requested Image Gen workflow. |
| Add `Sprite2D` nodes per object | Simple asset wiring. | It breaks the retained high-count performance architecture. |
| Replace the complete 644-frame atlas before a live slice | Produces one large migration. | It makes another art-direction failure expensive and hard to isolate. |

## Current State

Already true:

- The runtime atlas, catalog, nearest filtering, extrusion, gutters, retained
  renderer, geometry-fed world builder, deterministic captures, localization
  matrix, and validators exist.
- The worktree was clean at recovery start.
- The 64×64 player guide, 32×32/24×24 guides, palette, style reference, and
  snapping tools exist.

Remaining implementation:

- Produce and review real recovery masters.
- Make runtime publication provenance-aware.
- Replace the rejected families in bounded batches.
- Re-run the full native/Web/readability/performance release gates.

## Scope

In scope:

- truthful frame-level production provenance;
- recovery of all raster families in `asset-inventory.json`;
- the six-master core slice;
- the existing atlas/catalog publication path;
- map material, player, actor, projectile, pickup, facility, boss, and
  restrained UI-glyph presentation;
- Korean/English and three-viewport evidence;
- focused validators, native build, production Web export, and production-style
  manual QA.

Out of scope:

- gameplay balance, collision, navigation, encounter, card, save, input, audio,
  or localization-copy changes;
- rasterized text, bindings, cooldowns, progress, focus, selection, minimap
  position, telegraph geometry, or exact attack footprints;
- new dependencies, engine changes, content families, or a new renderer;
- deleting prior evidence or history.

Destructive or irreversible actions:

- None. Rejected assets remain recoverable in git history and evidence.

Exact actions requiring owner/user approval:

- None for the selected recovery direction and in-repository forward fixes.
- Any future dependency, engine, gameplay, or collision change remains outside
  this plan and requires separate approval.

## Architecture and Ownership

| Concern | Final owner | Interface or invariant | Reuse or retire |
| --- | --- | --- | --- |
| Art direction and semantic hierarchy | `docs/design/UI_VISUAL_SYSTEM.md` | Sunken Ceramic Fresco, flat color, role-first read order | Reuse |
| Native production contract | `pixel-art-production/README.md` and manifests | Exact grid, palette, layers, anchors, approval state | Reuse |
| Raw/generated evidence | `pixel-art-production/assets/source/candidates/visual-recovery/` | One generated source and prompt per master | Add within existing source taxonomy |
| Approved sources/builds | `pixel-art-production/assets/source/approved/visual-recovery/`, manifests, generated catalog | Exact reviewed files and checksums | Add |
| Runtime atlas/catalog | `pixel-art-production/runtime/` | One shared atlas; truthful method; bounded frames | Reuse |
| Publisher | `tools/design/generate_complete_pixel_library.gd` | Import approved catalogs; fail missing ImageGen sources | Retire synthetic ImageGen fallback |
| Static world | `vehicle_pixel_world_mesh_builder.gd` | Geometry-fed repeat materials only | Reuse |
| Combat sprites | `vehicle_combat_renderer.gd` | Retained atlas batches and exact gameplay transforms | Reuse |
| Live overlays/UI | existing run/UI scripts | Dynamic values, state, focus, localization, telegraphs | Reuse |

## As-Is / To-Be Delta Map

| Concern | As-is | To-be | Acceptance check | Guard |
| --- | --- | --- | --- | --- |
| Provenance | Inventory label survives even when a frame is procedurally fabricated. | Every ImageGen label resolves to reviewed source files and checksums. | Provenance validator passes. | No `_make_sprite()` fallback for ImageGen families. |
| Map | Three stripe textures repeat over the whole field. | Quiet ceramic floor, solid blocker grammar, and cobalt water/void retain stage clarity. | Seam proof plus collision capture. | No false blocker, opening, hazard, or pickup motif. |
| Player | Thin generic arrow shape. | Broad 64×64 interceptor with nose, paired wings, cockpit, mount, and rear engines. | Native silhouette and maximum-pressure capture. | Stable pivot/muzzle/nozzles across directions. |
| Common enemy | One of seven generic procedural contours. | Chaser has a unique hostile ceramic ram silhouette. | Native silhouette group and startup capture. | Distinct from player/pickup/turret in grayscale. |
| Pickup | Small generic diamond/plus. | Repair pickup has a large container and plus cue. | Native/background review and live field capture. | Distinct from XP/projectiles/support field. |

## Tasks

### Phase 1 — Truthful six-master live core slice

Goal: replace the most visible rejected sources and prove the complete corrected
workflow in the actual game.

Source owners touched: grid/style references, recovery source/manifests,
runtime tiles/atlas/catalog, publisher/provenance validator, world builder,
capture evidence.

- [x] **1.1 Generate six independent masters**
  - As-is: runtime art is direct-pixel stripes or procedural geometry.
  - To-be: floor, wall, water, player chassis, chaser, and repair pickup each
    have a raw built-in Image Gen output made against the correct logical grid.
  - Accept: six non-empty source files, six prompt records, and six board
    completion receipts.
  - Guard: no contact sheet, unrelated sprite sheet, full-scene downsample, or
    generated text.
- [x] **1.2 Snap and correct native assets**
  - As-is: raw generations may cross cells or contain off-palette values.
  - To-be: declared-size native PNGs use whole cells, approved colors,
    transparency, stable anchors, and corrected symmetry/seams.
  - Accept: palette, alpha, size, silhouette, seam, and review checks pass.
  - Guard: no antialiasing, dithering, gradients, partial alpha, baked glow, or
    false geometry.
- [x] **1.3 Publish with truthful provenance**
  - As-is: the publisher synthesizes absent families while keeping
    `imagegen_assisted`.
  - To-be: approved recovery frames import before fallback; ImageGen families
    without sources fail publication.
  - Accept: catalog provenance validator and runtime catalog validator pass.
  - Guard: explicitly direct/procedural families remain available only under
    their truthful method.
- [x] **1.4 Integrate and capture**
  - As-is: repeated stripes and generic symbols dominate live combat.
  - To-be: the six recovered masters render through the existing retained and
    geometry-fed owners.
  - Accept: safe-arrival, maximum-pressure, field, and collision captures at
    `1280×720` show the corrected hierarchy with unchanged gameplay geometry.
  - Guard: batches `<=50`, world chunks `<=60`, no repeated-object nodes.

Batch acceptance:

- The generated sources, snapped masters, runtime assets, and gameplay captures
  visibly share one Sunken Ceramic Fresco pixel grammar.
- The player, chaser, repair pickup, wall, walkable floor, and water/void remain
  separable in grayscale and without labels.

Batch guard:

- Do not begin broad frame replacement until the actual-game core slice passes.

### Phase 2 — Player, projectile, and pickup families

Goal: recover the complete friendly-ownership and collection layer.

- [ ] Replace every frame in `player_chassis`, `player_engine_modules`,
  `player_engine_flame`, `player_dash_effect`,
  `player_primary_projectiles`, `player_projectile_modifier_overlays`,
  `experience_shards`, `repair_pickup`, and `experience_recall_pickup`.
- [ ] Preserve the one-second opening shot, held primary fire, dash, upgrade
  modules, friendly ownership, collision extents, and retained capacities.
- [ ] Pass native direction/animation boards and dense live gameplay captures.

### Phase 3 — Ordinary enemies, stationary enemies, and hostile projectiles

Goal: give every ordinary combat role a unique readable silhouette and startup.

- [ ] Replace every published variant in `mobile_enemy_set`,
  `stationary_enemy_set`, `elite_trait_overlays`,
  `enemy_condition_overlays`, and `hostile_projectile_affinities`.
- [ ] Preserve role, facing, startup, active/recovery state, affinity shape,
  projectile head extent, and current batching.
- [ ] Pass black-silhouette groups, grayscale groups, startup captures, and
  maximum-pressure captures.

### Phase 4 — World functions, facilities, secondaries, and effects

Goal: recover all world interaction and automatic-weapon silhouettes.

- [ ] Replace every raster family for connected walls, water/void edges,
  Arc Surge, bulkheads, gates, repair/overdrive fixtures, crates, seekers, ion,
  orbit blades, mines, escort drones, impacts, and status effects.
- [ ] Preserve exact collision, open gaps, timers, radii, movement paths,
  support budgets, and telegraph geometry as live state.
- [ ] Pass 16-signature wall seams, `3×3` repeats, facility-state captures, and
  simultaneous-secondary captures.

### Phase 5 — Bosses, guide previews, and restrained UI glyphs

Goal: finish the exceptional-threat and non-text ornament layer.

- [ ] Replace all five boss variants and their readable phase/module frames.
- [ ] Derive guidebook previews from approved runtime frames.
- [ ] Replace only declared HUD, minimap, card, and frame glyph assets while
  keeping text, focus, values, selection, and state live.
- [ ] Pass Boss Practice, partial-offscreen, Korean/English, keyboard, and
  three-viewport evidence.

### Phase 6 — Final migration gate and retirement

Goal: prove the recovered presentation as the only production raster path.

- [ ] Run every pixel-production and repository validator.
- [ ] Run the native capture matrix and authoritative performance scenarios.
- [ ] Export and production-start the Web build through the registered
  `fastrun` codex lane, then verify Korean default, English switch, gameplay,
  pause, guidebook, upgrade, report, and result flows.
- [ ] Remove only the synthetic fallback branches whose families are fully
  source-backed; keep live procedural overlays and gameplay geometry.
- [ ] Incorporate accepted durable rules into the active specs, mark this plan
  done, and delete it only after all required gates pass.

## Validation Cadence

Inner-loop commands:

- `./pixel-art-production/tools/design/validate_pixel_asset_manifest.ps1`
- `./pixel-art-production/tools/design/invoke_pixel_asset_build.ps1`
- `./pixel-art-production/tools/validation/validate_pixel_asset_palettes.ps1`
- `./pixel-art-production/tools/validation/validate_pixel_asset_seams.ps1`
- `./pixel-art-production/tools/validation/validate_pixel_asset_catalog.ps1`
- `./tools/godot.ps1 --headless --path . --script <focused validator>`

Batch gates:

- `./pixel-art-production/tools/validation/validate_pixel_asset_pipeline.ps1`
- focused renderer, world, catalog, import, localization, and capture validators
- native deterministic capture at `1280×720`

Final gates:

- Full validators: every script under `tools/validation/`
- Production build: `./tools/export_web.ps1`
- Production start: registered `fastrun-manager` `codex` lane only
- Viewports: `960×540`, `1280×720`, `1920×1080`
- Locales: Korean default and complete English parity
- States: safe arrival, maximum pressure, support fields, upgrades, boss
  startup/active/recovery, pause, guidebook, reports, result, garage
- Performance: existing native/Web thresholds; no threshold changes
- Documentation: `git diff --check` and lifecycle/frontmatter review

Rerun policy:

- Rerun a failed narrow check only after a concrete source, cleanup, manifest,
  catalog, renderer, or test change.
- Rerun full gates only after the suspected cause changes.
- Record unrelated pre-existing warnings without weakening a gate.

## Predetermined Error Handling and Contingencies

| Trigger | Required response | Limit / escalation point |
| --- | --- | --- |
| Raw generation ignores cell fills | Retry once with the whole-cell behavior reference and a single stricter cell-fill instruction. | After two attempts, keep the best concept and correct native cells manually; do not publish raw output. |
| Chroma/white removal leaves halos | Re-snap with white as the declared transparent color and inspect alpha at native/enlarged scale. | If partial alpha remains, reject the asset. |
| Seam proof fails | Correct only opposite edge cells and rebuild the `3×3` proof. | Do not change geometry or hide seams with filtering. |
| Direction rotation damages silhouette | Author the failing cardinal/intercardinal master separately and derive only the bounded in-between frames. | Never accept unreadable automatic rotations. |
| Approved frame is missing | Fail publication with family/frame ID. | No procedural substitution for ImageGen-assisted art. |
| Live sprite implies false collision | Correct art to the existing gameplay footprint. | Do not change collision in this plan. |
| Performance threshold fails | Isolate task-owned texture, chunk, batch, or upload cost and correct it. | Do not weaken thresholds or reduce gameplay workload. |

## Progress

- [x] Root and `.agents` instructions, active specs, pixel pipeline, grid
  experiment, current scripts, captures, current history, and worktree inspected.
- [x] Procedural publication/provenance defect confirmed.
- [x] Phase 1 complete: six raw generations and prompt records, nine approved
  native/runtime sources, 28 frame overrides, three repeat tiles, runtime
  catalog/renderer checks, deterministic Korean captures, and Web export
  verified on 2026-07-27.
- [ ] Phases 2–5 complete.
- [ ] Phase 6 final gates complete.

## Next Steps

1. Begin Phase 2 with the remaining player, projectile, and pickup families.
2. Review each six-master batch at native scale and in maximum-pressure
   gameplay before publishing it.
3. Continue through the locked family order without relabelling procedural
   fallback as ImageGen-assisted work.

## Completion Criteria

- [ ] Every user-visible raster family is backed by reviewed declared-size
  source art and truthful production metadata.
- [ ] No `imagegen_assisted` family reaches runtime through procedural
  rectangle/circle/polygon fallback.
- [ ] The live map and combat hierarchy visibly match Sunken Ceramic Fresco at
  all supported viewports and in grayscale.
- [ ] Collision, navigation, attacks, cards, localization, input, save data,
  and accessibility remain current-owner truth.
- [ ] Every focused, repository, native, Web, localization, and performance
  gate passes without weakened thresholds.
- [ ] Superseded synthetic branches are removed only after their full family
  replacements pass.

## Stop Conditions

Complete when:

- All completion criteria pass and the active specifications contain the
  accepted durable production contract.

Escalate only when:

- A required visible correction would change gameplay-owned geometry,
  dependencies, engine version, content scope, balance, or localization
  behavior; or an external tool is unavailable after its bounded retry.

Do not stop when:

- A raw generation needs grid snapping, palette correction, seam correction,
  semantic masking, direction cleanup, or a focused retry.

## Handoff

```text
Goal:
Replace the rejected procedurally fabricated pixel migration with truthful,
reviewed grid-native ImageGen-assisted assets.

Read first:
AGENTS.md
.agents/PLANS.md
.agents/execplans/2026-07-27-pixel-art-visual-recovery.md
docs/design/UI_VISUAL_SYSTEM.md
pixel-art-production/README.md
pixel-art-production/design/experiment/single-asset-grid/README.md

Execute exactly:
Continue the first unchecked phase and its named six-asset batches. Never
publish an ImageGen-assisted family through procedural fallback.

Validate with:
The inner-loop, batch, and final gates in this plan.

Stop when:
The completion criteria pass, or a named escalation boundary requires new
authority.
```
