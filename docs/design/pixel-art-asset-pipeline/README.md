---
type: spec
status: active
created: 2026-07-26
last_reviewed: 2026-07-26
canonical_for: Pixel-art asset inventory, authoring manifests, semantic layer separation, deterministic cleanup, and atlas production
scope: Offline visual-asset production; it does not replace the current live visual system or gameplay geometry
related:
  - ../UI_VISUAL_SYSTEM.md
  - ../pixel-art-space-hangar-research.md
  - ../pixel-art-space-hangar-experiment/single-asset-grid/README.md
  - ../../product/vehicle_game_spec.md
---

# Pixel-Art Asset Production Pipeline

## Purpose

Define one production path for replacing Cardborne's procedural visual assets
with editable pixel art. The path applies to map tiles, terrain, the player
craft, enemies, bosses, projectiles, secondary weapons, effects, pickups, and
icon artwork without turning collision, telegraphs, localization, or changing
runtime values into bitmaps.

The complete machine-readable inventory is
[`asset-inventory.json`](./asset-inventory.json). It currently contains 40 asset
families: 30 raster-atlas families, nine procedurally positioned pixel
families, and one live-UI family.

## Scope

This specification owns:

- the current visual-asset inventory and migration priority;
- native logical sizes, variants, directions, states, and semantic parts;
- the manifest contract for one producible asset family;
- generation input, palette cleanup, semantic masking, layer extraction,
  exact reassembly, pixel-SVG export, and atlas packing;
- acceptance checks before an atlas may be considered runtime-ready.

It does not:

- change the live Godot renderer in this revision;
- replace authored collision, navigation, line of sight, or spawn legality;
- bake exact telegraph areas, minimap positions, cooldowns, numbers, focus
  states, or Korean/English strings into images;
- add an image API client, API key, package, or external production dependency;
- accept an ImageGen output as finished art without deterministic cleanup.

## Current State

The current game has no runtime PNG, SVG, `Sprite2D`, or `TileMapLayer` art.
World surfaces are owned by `vehicle_stage_backdrop.gd`; actors and projectiles
are mesh families in `vehicle_combat_visual_library.gd`; batching and state
overlays are owned by `vehicle_combat_renderer.gd`. Existing PNG files are
design references and captures, not runtime assets.

The pipeline therefore treats current scripts as the inventory source and future
atlases as a presentation replacement. Gameplay geometry remains the sole truth.

### Inventory coverage

| Group | Asset families |
| --- | --- |
| Environment, terrain, facilities, props (9) | `world_floor_void_tiles`, `wall_cover_tiles`, `water_void_edge_tiles`, `arc_surge_strip`, `breakable_bulkhead`, `transit_gate`, `repair_field`, `overdrive_field`, `reward_crate` |
| Player and effects (8) | `player_chassis`, `player_primary_weapon`, `player_engine_modules`, `player_engine_flame`, `player_dash_effect`, `player_status_overlays`, `enemy_condition_overlays`, `impact_effects` |
| Enemies and bosses (4) | `mobile_enemy_set`, `stationary_enemy_set`, `elite_trait_overlays`, `boss_set` |
| Projectiles (3) | `player_primary_projectiles`, `player_projectile_modifier_overlays`, `hostile_projectile_affinities` |
| Secondary weapons (5) | `secondary_seeker`, `secondary_ion_field`, `secondary_orbit_blades`, `secondary_wake_mines`, `secondary_escort_drone` |
| Pickups (3) | `experience_shards`, `repair_pickup`, `experience_recall_pickup` |
| Combat feedback and UI (8) | `telegraph_shape_system`, `world_targeting_markers`, `hud_action_icons`, `minimap_world_markers`, `guidebook_previews`, `upgrade_card_icons`, `ui_frame_system`, `dynamic_combat_ui` |

Each set entry expands into the variants named in the JSON inventory. For
example, the mobile-enemy set contains all 13 current archetypes, the stationary
set contains six roles, the boss set contains five stage variants, and the card
icon set contains all 46 current upgrade IDs.

## Requirements

### Three output modes

| Mode | Use | Examples |
| --- | --- | --- |
| `raster_atlas` | Approved fixed silhouettes, frames, or connected tiles | craft, enemies, bosses, projectiles, pickups, walls |
| `procedural_pixel` | Pixel glyphs or small tiles positioned by exact runtime state | telegraph fill/border, status rings, minimap markers |
| `live_ui` | Values and interactions that must remain dynamic and localized | health, cooldown fill, report values, Korean/English text |

An asset family may use a raster base plus procedural overlays. Do not generate
every modifier combination as a separate bitmap.

### Native grids

| Family | Native master |
| --- | ---: |
| Floor, void, wall, and edge tile | `24 x 24` |
| Small projectile or shard | `16 x 16` |
| Pickup, status, or HUD glyph | `24 x 24` |
| Common mobile enemy | `32 x 32` |
| Tower, mine, terrain component | `32–64 px` |
| Player craft frame | `64 x 64` |
| Boss frame | `96 x 96` |

One ImageGen job contains one asset or one deliberately related frame—not a
sheet of unrelated objects. A `512 x 512` guide canvas maps exactly onto the
declared logical grid. The finished native frame is the logical size, not
`512 x 512`.

### Semantic part contract

Every visible source pixel must belong to exactly one semantic layer. Each layer:

- uses one unique ID color in a same-size semantic mask;
- occupies the full frame canvas and preserves the shared origin;
- declares a stable z-order;
- keeps anchors and pivots in logical-pixel coordinates;
- can be edited independently and reassembled at `(0, 0)`;
- must reassemble to the approved source with an absolute pixel difference of
  zero.

The image model may propose a part layout, but the semantic mask is corrected
deterministically. A prompt instruction such as “leave a visible seam between
the wing and body” improves separability; it does not prove pixel-perfect
ownership. The mask and validator do.

### Stable gameplay anchors

Actor manifests declare one pivot and named anchors such as muzzle, engine
nozzle, orbit center, status position, and impact origin. All direction and
animation frames keep those anchors stable unless the animation explicitly
moves that part. Collision is never derived from alpha.

## Production Workflow

### 1. Register the family

Add or update one entry in `asset-inventory.json`. Record the current code owner,
target mode, master size, variants, directions, states, semantic layers, and
priority. This prevents forgotten runtime visuals and duplicate ownership.

### 2. Create the job manifest

Copy the shape in
[`examples/player-craft.manifest.json`](./examples/player-craft.manifest.json)
and validate it against
[`pixel-asset-manifest.schema.json`](./pixel-asset-manifest.schema.json).
The manifest is the durable contract; filenames inferred from a prompt are not.

### 3. Build the generation input

Create a white `512 x 512` guide with one exact logical grid. Supply that guide,
the approved display palette, a small style reference, and a structured prompt.
The prompt must state:

1. asset identity and camera direction;
2. exact silhouette and functional anchors;
3. permitted flat colors and no dithering/gradients;
4. transparent or white removable background;
5. one object only, centered with margin;
6. large, clean semantic parts separated by simple one-cell boundaries;
7. invariants that an edit must not change.

Example actor prompt:

> Create one north-facing drydock interceptor inside the supplied 64-by-64
> logical-cell guide. Fill every occupied cell edge-to-edge with one flat
> palette color. Keep body, left wing, right wing, cockpit, weapon mount, and
> two engines as large contiguous regions with clean boundaries. Keep the
> muzzle on the vertical centerline and both engine nozzles symmetric. No
> outlines, gradients, dithering, texture speckles, labels, shadows, or extra
> objects. Preserve transparent background outside the silhouette.

For later variations, edit the approved frame instead of regenerating from
scratch. State the invariants first, then request one small change.

### 4. Snap to the logical grid and palette

`snap_image_to_pixel_grid.ps1` normalizes the image to the guide size, samples
one logical cell, disables dithering, remaps to the approved palette, and removes
the declared key background. Hidden RGB in transparent input is normalized
before remapping so it cannot become visible pixels.

### 5. Create the semantic mask

Create a same-canvas mask using the manifest's ID colors. The mask may be drafted
by image editing or by broad deterministic regions, then corrected at native
resolution. It is not presentation art and its colors do not affect the game.

The mask must assign every visible pixel once, assign no transparent pixel, use
only declared colors, and populate every required layer.

### 6. Split, verify, and reassemble

`split_pixel_asset_layers.ps1` checks source/mask coverage, writes one
full-canvas transparent PNG per semantic layer, composites them in z-order, and
rejects the build unless the reassembled image has pixel difference `0`.

`raster_to_pixel_svg.ps1` then creates an optional integer-grid SVG for direct
pixel correction. Same-color horizontal runs are merged. PNG remains the atlas
and runtime contract; SVG is only an editable intermediate.

### 7. Produce directions and animation

- Player aim: 16 directions.
- Asymmetric mobile enemies: eight directions.
- Symmetric swarm units, mines, and fixed bases: directionless when readable.
- Projectiles: use fewer directional frames only when rotation preserves their
  silhouette exactly.
- Effects: short state-specific loops; do not add idle micro-animation.

Generate or edit one frame at a time. Validate silhouette area, pivot, and anchor
drift before packing. Recoil, flame, dash, and status effects remain separate
layers or sheets so chassis combinations do not multiply.

### 8. Pack the atlas

`pack_pixel_asset_atlas.ps1` follows explicit `atlas_index` values and writes a
PNG plus JSON metadata containing every frame region, pivot, and anchor.
Connected tiles must additionally pass a repeated `3 x 3` seam test. Atlas
padding and edge extrusion can be introduced in the manifest when the Godot
import proof establishes the required Web-safe gutter.

### 9. Integrate later

Godot integration is a separate, reviewable phase:

- retain current gameplay geometry and retained high-count batching;
- select atlas regions in existing renderer-owned batches;
- use nearest texture filtering and whole-number sprite scale;
- derive visual tiles from geometry, never the reverse;
- test the Web export at `1280 x 720` and `1920 x 1080`;
- compare combat readability and frame pacing before broad conversion.

## Family-Specific Rules

### Map tiles

Floor variation is large and sparse; it may never resemble collision, hazards,
pickups, or telegraphs. Walls and every impassable blocker use one material
grammar. Orthogonal wall/edge sets use all 16 neighbor combinations. Static art
does not own collision. Each tile family needs a `3 x 3` repeat and connection
proof.

### Player, enemies, and bosses

Silhouette communicates ownership and role before interior detail. Attack
startup, active state, recovery, damage, and destruction use separate states
only when visible during play. Boss sprite phases support boss logic but never
replace exact procedural attack geometry.

### Projectiles and effects

The rendered projectile head must not imply a smaller safe area than the actual
collision radius. Ownership, affinity, and threat weight use shape plus value;
modifier overlays are composable. Wall clipping and hit truth stay in combat
code.

### Items and facilities

Repair and experience recall remain the only field-item behaviors. XP value
classes share one family. Repair/overdrive fields use a pixel fixture, while
radius, lifetime, and fill animation remain exact live geometry.

### UI

Raster art is limited to glyphs, markers, and restrained ornament. Text,
bindings, focus, selection, changing numbers, progress arcs, and accessibility
states remain live controls. Korean and English never become atlas text.

## Commands

From the repository root:

```powershell
./tools/design/create_pixel_palette.ps1 `
  -PaletteSpecPath docs/design/pixel-art-asset-pipeline/example-drydock-palette.json `
  -ColorGroup colors `
  -OutputPath docs/design/pixel-art-asset-pipeline/examples/player-craft-display-palette.png

./tools/design/create_projectile_pixel_sheet.ps1

./tools/design/validate_pixel_asset_inventory.ps1

./tools/design/validate_pixel_asset_manifest.ps1 `
  -ManifestPath docs/design/pixel-art-asset-pipeline/examples/player-craft.manifest.json `
  -RequireInputFiles

./tools/design/invoke_pixel_asset_build.ps1 `
  -ManifestPath docs/design/pixel-art-asset-pipeline/examples/player-craft.manifest.json `
  -OutputDirectory docs/design/pixel-art-asset-pipeline/examples/player-craft-build

./tools/validation/validate_pixel_asset_pipeline.ps1
```

The checked-in proof splits the 64-cell craft into body, two wings, cockpit,
primary mount, and two engines, then reassembles it with zero changed pixels:

![Semantic split proof](./examples/player-craft-semantic-proof.png)

The projectile proof is authored directly on the logical pixel grid rather than
generated as combination-specific images. Its 24 atlas slots contain complete
heads, affinity overlays, modifier overlays, trails, and impacts; the final row
of the preview shows runtime compositions:

![Projectile pixel system](./examples/projectile-system/projectile-system-preview.png)

## Acceptance Criteria

- [ ] Every current visual family is present in the inventory exactly once.
- [ ] Each manifest passes structural and input-file validation.
- [ ] The generated frame is snapped to its declared logical size and approved
      palette with no dithering or partial cells.
- [ ] Every visible pixel has exactly one known semantic owner.
- [ ] Every required semantic layer contains pixels.
- [ ] Layer reassembly has absolute pixel difference `0`.
- [ ] Pivots and anchors stay stable across directions and frames.
- [ ] Connected tiles pass the repeated seam and adjacency tests.
- [ ] Actor, enemy, projectile, pickup, and telegraph roles remain distinguishable
      at gameplay scale and in grayscale.
- [ ] Collision, navigation, telegraph truth, live state, localization, and
      accessibility remain outside raster art.
- [ ] Godot integration retains batching and passes the Web export before any
      family is declared migrated.

## Sources

Sources reviewed on 2026-07-26:

- [OpenAI Image generation guide](https://developers.openai.com/api/docs/guides/image-generation):
  the Image API supports single generation/edit jobs, while the Responses API
  supports multi-turn image editing. Masks require matching image dimensions
  and alpha. The current documented image model is `gpt-image-2`.
- [OpenAI GPT Image prompting guide](https://developers.openai.com/cookbook/examples/multimodal/image-gen-models-prompting-guide):
  use structured prompts, explicit constraints and invariants, references, and
  small iterative edits. Exact consistency and composition still require
  downstream validation.
- [Godot TileMapLayer](https://docs.godotengine.org/en/stable/classes/class_tilemaplayer.html),
  [TileSetAtlasSource](https://docs.godotengine.org/en/stable/classes/class_tilesetatlassource.html),
  and [MultiMesh](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html):
  atlas art can replace presentation while the current geometry and retained
  batching remain authoritative.

The local Codex ImageGen capability is used for visual drafts. This repository
does not call an image API directly, so the pipeline does not assume an exposed
model selector, API key, or transparent-output option. Transparency is
normalized during deterministic cleanup.
