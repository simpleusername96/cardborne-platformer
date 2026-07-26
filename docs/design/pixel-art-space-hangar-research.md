---
type: evidence
status: active
owner: BK
created: 2026-07-26
last_reviewed: 2026-07-26
topic: Pixel-art space-hangar visual direction and production workflow
scope: Research-backed candidate direction for the map, ship, world assets, and Web-safe rendering
related:
  - ./UI_VISUAL_SYSTEM.md
  - ./pixel-art-space-hangar-experiment/README.md
  - ../product/vehicle_game_spec.md
---

# Pixel-Art Space-Hangar Direction Research

## Purpose

Determine a practical way to redesign Cardborne as a readable pixel-art vehicle
shooter set on a space hangar: near-black space outside the playable boundary,
dark steel-gray construction inside it, a new player craft, and modular tiles
for floors, boundaries, walls, and terrain.

This is decision evidence, not the active visual specification. The current
[`UI_VISUAL_SYSTEM.md`](./UI_VISUAL_SYSTEM.md) remains authoritative until BK
accepts a proof package and the approved rules are promoted into that
specification.

## Scope

This research covers:

- how image generation can contribute without becoming the production asset;
- the editable pixel source, raster export, and atlas workflow;
- the appropriate Godot map-tile architecture for the current field;
- the player-craft sprite structure;
- pixel rendering under desktop Web export;
- the minimum proof needed before converting the live game.

It does not implement assets, change collision or encounter behavior, select a
hosting provider, or promise a strict low-resolution viewport.

## Sources

| Source | Relevant evidence |
| --- | --- |
| Current repository: `vehicle_stage_geometry.gd`, `vehicle_stage_backdrop.gd`, `vehicle_stage_visual_profile.gd` | Collision, navigation, and legal placement already use authored polygon geometry; the visible field is currently drawn separately. |
| Current repository: `vehicle_combat_visual_library.gd`, `vehicle_combat_renderer.gd` | High-count actors and shots use retained, fixed-cap `MultiMesh` families to preserve performance. |
| [Godot TileMapLayer](https://docs.godotengine.org/en/stable/classes/class_tilemaplayer.html) and [Using TileMaps](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilemaps.html) | `TileMapLayer` is the current one-layer node; external `TileSet` resources, patterns, terrain connections, and multiple visual layers are supported. Tile changes are batched, so frequently mutating a large field is not free. |
| [Godot TileSetAtlasSource](https://docs.godotengine.org/en/stable/classes/class_tilesetatlassource.html) and [AtlasTexture](https://docs.godotengine.org/en/stable/classes/class_atlastexture.html) | A regular atlas can expose grid cells and alternatives while sharing one texture. |
| [Godot MultiMesh](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html) and [RenderingServer](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html) | Many repeated visuals can be submitted together, and per-instance custom data can select atlas state in a shader. |
| [Godot multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html), [CanvasItem](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html), and [2D introduction](https://docs.godotengine.org/en/stable/tutorials/2d/introduction_to_2d.html) | Nearest filtering, integer scaling, and pixel snapping are available, but transform snapping can conflict with smooth subpixel camera and actor motion. |
| [Godot SVG importer](https://docs.godotengine.org/en/stable/classes/class_resourceimportersvg.html) and [Image](https://docs.godotengine.org/en/stable/classes/class_image.html) | Godot rasterizes SVG into a texture; nearest-neighbor resizing and lossless PNG output are supported. |
| [Tiled tileset editing](https://docs.mapeditor.org/en/stable/manual/editing-tilesets/), [terrain sets](https://docs.mapeditor.org/en/stable/manual/terrain/), and [Automapping](https://docs.mapeditor.org/en/latest/manual/automapping/) | Atlas spacing, edge extrusion, external tileset reuse, connected terrain variants, and rule-based placement are established tile-authoring practices. |
| [Aseprite tilemaps](https://www.aseprite.org/docs/tilemap/), [sprite sheets](https://www.aseprite.org/docs/sprite-sheet/), and [CLI](https://www.aseprite.org/docs/cli/) | A conventional pixel editor can author tilemaps and export deterministic sprite sheets, but it is optional and must not become a required production dependency without approval. |
| [OpenAI image-generation guidance](https://openai.com/academy/image-generation/) and [image editing guidance](https://help.openai.com/en/articles/11084440) | Clear constraints, a small reference set, and incremental edits improve iteration; generated or edited regions still require human inspection and cleanup. |
| [Heat Signature](https://store.steampowered.com/app/268130/Heat_Signature/), [Space Haven](https://store.steampowered.com/app/979110/Space_Haven/), [Star of Providence](https://store.steampowered.com/app/603960/Star_of_Providence/), and [Nova Drift](https://store.steampowered.com/app/858210/Nova_Drift/) | Reference screenshots demonstrate useful, distinct lessons: a lit playable island against space, modular spacecraft interiors, compact pixel-shooter readability, and high-contrast combat against a dark field. These are references to analyze, not styles or assets to copy. |

Sources were reviewed on 2026-07-26.

## Findings

### Current architecture should not be replaced by a painted tilemap

The current field is `7200 x 4320` world units. Its floor, cover, spawn legality,
navigation, line of sight, and projectile blocking are already based on shared
polygon data. Replacing that truth with a hand-painted tilemap would create two
competing definitions of where the player can move.

The safe boundary is:

- polygon geometry remains authoritative for gameplay;
- a tile layer is generated once from the selected geometry snapshot;
- visual cells never add or remove collision;
- an opening is painted only when geometry says it is traversable;
- small geometric gaps that cannot be traversed are painted as closed.

This preserves the project rule that visual geometry is independent from
collision truth while making the field visually modular.

### AI generation cannot be the exact pixel grid

The available image-generation interface does not expose an exact-output-size
contract, and a generated image does not reliably preserve an exact grid,
palette, seamless edge, frame pivot, or transparency. Supplying a `256 x 256` or
`512 x 512` guide improves composition, but it does not turn every generated
sample into valid pixel art.

Image generation is therefore useful for:

- broad ship silhouettes;
- material and palette exploration;
- the relationship between space, hull rim, floor, and wall;
- a family resemblance among terrain props;
- deciding how much detail is acceptable at gameplay scale.

It is not reliable for:

- finished connected-tile variants;
- animation frames with a fixed pivot;
- collision masks;
- exact sprite-sheet spacing;
- a seamless atlas that can be imported unchanged.

### Pixel SVG is useful only as an editable intermediate

Godot imports SVG by rasterizing it. A mechanically traced SVG also tends to
retain anti-aliased noise or generate an excessive number of tiny paths. Using
that file directly does not make the game more pixel-accurate.

For assets that need exact Codex edits, an integer-grid SVG remains useful as an
authoring intermediate when it follows these rules:

- the `viewBox` equals the native pixel grid;
- shapes use integer coordinates and `shape-rendering="crispEdges"`;
- same-color horizontal runs are merged instead of creating one rectangle per
  pixel;
- it contains only the approved palette;
- it is exported at an integer multiple with no smoothing;
- the game imports the resulting lossless PNG atlas, not the SVG.

The PNG atlas is the runtime contract. The editable SVG and palette remain source
art. This makes individual pixel corrections reviewable without asking Godot to
render a verbose vector scene every frame.

### Strict low-resolution rendering is premature

A globally snapped `640 x 360` or similar viewport would produce classic,
uniform pixels, but it would also constrain the current Korean UI, reduce the
room available for dense combat, and risk visible camera or steering jitter.
Cardborne prioritizes responsive aim and smooth movement.

The first conversion should instead use:

- the current `1280 x 720` design viewport;
- native low-resolution sprites scaled by whole numbers;
- nearest texture filtering;
- integer-positioned static tile cells;
- unsnapped simulation and camera motion;
- browser tests at `1280 x 720` and `1920 x 1080`.

Strict integer viewport scaling can be reconsidered only after a playable proof
shows that it improves the image without harming motion or UI legibility.

## Recommended Direction

### Visual language

The proposed field is an orbital drydock, not a black rectangle decorated with
stars.

| Role | Proposed color | Use |
| --- | --- | --- |
| Outer space | `#05070D` | The non-playable exterior only |
| Space lift | `#0A1019` | Sparse, large void variation; no noisy star field |
| Hangar floor | `#202833` | Main traversable surface |
| Floor variation | `#293440` | Large, infrequent service plates |
| Floor seam | `#141B24` | Restrained structural divisions |
| Wall top | `#44515E` | Every solid wall and blocker |
| Wall side | `#222B35` | Height cue shared by all blockers |
| Boundary light | `#65A9B8` | Clear floor-to-space safety rim |
| Player and reward | `#D9A83D` | Player ownership and valuable progression |
| Ordinary danger | `#D84B5F` | Enemies, hostile shots, and damage telegraphs |
| Support | `#75C4B2` | Repair and beneficial terrain |
| Boss danger | `#B73D73` | Boss ownership |
| Bright neutral | `#E8EEF0` | Rare highlight and readable UI contrast |

Environment tiles use flat clusters of color, no gradients, no dithering, and no
speckled texture. Large panels and seams create rhythm. A selective one-pixel
material separation is allowed where two dark surfaces merge, but continuous
black cartoon outlines are not.

The hierarchy remains:

1. playable floor versus space or wall;
2. player versus enemies;
3. hostile shots and telegraphs;
4. pickups and temporary facilities;
5. restrained atmosphere.

### Working grid and scale

Use one `48 x 48` world-unit tile backed by a `24 x 24` native pixel master and
exported at `2x`. This grid fits the current `7200 x 4320` field exactly:
`150 x 90` cells. It also limits each static layer to 13,500 possible cells,
instead of the 30,375 cells required by a `32 x 32` world grid.

Recommended asset masters:

| Asset | Native master | Runtime/world size | Notes |
| --- | ---: | ---: | --- |
| Base tile | `24 x 24` | `48 x 48` | Whole-number `2x` export |
| Large floor patch | `48 x 48` | `96 x 96` | Breaks repetition without micro-noise |
| Player chassis frame | `48 x 48` | `96 x 96` | Close to the current readable player footprint |
| Common enemy frame | `24–32 px` | `48–64 px` | Role-specific silhouette |
| Tower or mine frame | `32 x 32` | `64 x 64` | Usually directionless |
| Boss frame | `72–96 px` | `144–192 px` | Large readable parts, not more tiny detail |
| HUD world icon | `12–16 px` | `24–32 px` | Never contains text |

### Image-generation and pixel cleanup workflow

Use a `512 x 512` guide for all image-generation direction work. A `256 x 256`
guide is too cramped for a ship family or connected-tile grammar and provides no
benefit when the output must be redrawn anyway.

The deterministic workflow is:

1. Prepare a `512 x 512` guide with named cells, safe zones, palette swatches,
   view direction, and explicit forbidden detail.
2. Generate a small number of concept candidates using that guide and the
   approved reference image only.
3. Select by silhouette and material language, not by small generated detail.
4. Redraw the selected concept on the native `24 px` or `48 px` grid.
5. Quantize to the approved palette with dithering disabled.
6. Encode the cleaned source as integer-grid SVG with merged color runs.
7. Inspect and edit individual pixels at the SVG source grid.
8. Export lossless PNG at an exact integer scale with nearest sampling.
9. Add a one-pixel extruded gutter around atlas cells.
10. Run a `3 x 3` seam test, pivot overlay, silhouette test, and gameplay-scale
    composite before importing the atlas.

No generated bitmap is copied directly into the game, and no automatic vector
trace is accepted as finished source.

### Map tile grammar

Use Godot `TileMapLayer` and one external `TileSet` resource for the static
visual field. Do not make a Tiled `.tmx` file canonical; it would add an import
and synchronization owner while the repository already owns geometry.

The initial layer stack is:

1. `SpaceVoid`: near-black exterior, four very sparse large variants;
2. `HangarFloor`: dark steel base and six low-detail floor variants;
3. `FloorDecal`: infrequent service stripe, vent, panel, and light-strip cells;
4. `BoundaryRim`: the continuous readable edge between floor and space;
5. `SolidWall`: every impassable cover object in one material family.

Required tile families:

| Family | Minimum set | Rule |
| --- | ---: | --- |
| Space | 4 large variants | No small stars beneath combat |
| Floor | 6 base variants plus 4 large patterns | Same value range; variation cannot resemble hazards |
| Boundary rim | 16 edge-connected variants | Floor side and void side must never be ambiguous |
| Solid wall | 16 edge-connected variants | One shared top and side material for all blockers |
| Concave wall correction | Up to 4 overlays | Only where the base 16-set cannot preserve the silhouette |
| Floor decals | 8–12 sparse cells | Decorative only; never imply collision or pickups |

The 16 edge-connected variants cover the four orthogonal neighbors. Large floor
patches and controlled variant weights reduce repetition. Functional terrain,
crates, gates, mines, towers, repair fields, and overdrive fields remain
stateful components or retained batches; their art may come from the atlas, but
their state must not be baked into a static tile layer.

### Player-craft construction

Replace the current craft with one compact, forward-readable drydock interceptor.
Do not generate a fully animated human-like sprite sheet. Split the craft into
stable layers:

- `chassis`: 16 aim directions in a `4 x 4` atlas;
- `weapon`: separate hardpoint and two-frame recoil;
- `engines`: module count `0–3`, matching the existing speed-upgrade language;
- `engine_flame`: four-frame loop;
- `dash`: separate directional streak and burst sheet;
- `status anchors`: fixed locations for element, barrier, and temporary-effect
  icons.

Hull and primary-weapon power may use controlled value-depth steps as already
specified; secondary weapons whose count is visible do not also change color.
Hit, invulnerability, barrier, and temporary buffs use shaders or overlays,
rather than duplicating every directional frame.

The player requires 16 directions because aim follows the mouse. Symmetric swarm
enemies may remain directionless, while asymmetric mobile enemies use eight
directions. High-count enemies remain in retained atlas-aware `MultiMesh`
batches; the redesign must not create one `Sprite2D` node per enemy.

### UI boundary

Pixel art applies first to the world, actors, effects, map icons, and restrained
frame ornament. Korean and English text remains live `Noto Sans KR` UI text.
Rasterizing Korean labels or forcing them onto a tiny pixel font would reduce
legibility and localization reliability.

The Web target reinforces this separation: world art may use nearest sampling,
while UI layout and font rendering remain resolution-aware.

## Alternatives Rejected

| Alternative | Reason |
| --- | --- |
| Import generated images directly | No exact grid, palette, seams, pivots, or frame consistency |
| Automatically trace the generated bitmap into SVG | Preserves noise and anti-aliasing while producing difficult source |
| Use pixel SVG as the runtime atlas | Godot rasterizes it anyway; deterministic PNG is simpler to inspect and ship |
| Make Tiled `.tmx` the map authority | Duplicates current collision/navigation geometry and creates drift risk |
| Let visual TileMap layers own collision | Violates the current single gameplay-geometry truth |
| Switch the complete game to a tiny snapped viewport immediately | Risks camera jitter, dense-combat loss, and Korean UI regressions |
| Create one sprite node for every enemy and projectile | Discards the retained batching that was added to stabilize performance |
| Add high-frequency floor noise for variation | Obscures projectiles, pickups, telegraphs, and wall boundaries |

## Required Proof Before Promotion

The direction should replace the active visual specification only after these
four artifacts agree at gameplay scale:

1. a `512 x 512` art-direction board showing palette, space, hangar materials,
   and three player silhouettes;
2. a `512 x 512` tile-grammar board showing all edge cases and sparse floor
   variation;
3. a `512 x 512` layered player-craft sheet showing direction, weapon, engine,
   dash, and upgrade anchors;
4. a `1280 x 720` composite using cleaned pixel assets at representative enemy,
   projectile, pickup, facility, and telegraph density.

The fourth image is essential. A sheet can look coherent while failing inside a
real combat frame.

## Acceptance Criteria

The candidate direction is ready to become the canonical visual specification
only when:

- floor, outer space, boundary rim, and every wall read correctly without labels;
- every impassable shape uses the same blocker material grammar;
- a `3 x 3` tile seam test exposes no gap, smoothing, or atlas bleed;
- the ship's forward direction is immediate in all 16 aim frames;
- player, ordinary enemy, boss, hostile shot, support, and reward remain
  distinguishable in grayscale and under mixed combat effects;
- floor variation cannot be mistaken for an item, hazard, or collision edge;
- the composite remains legible at `1280 x 720` and `1920 x 1080`;
- the Web build preserves nearest-filtered world art without degrading live
  Korean and English UI text;
- the implementation can retain current collision truth and fixed-cap rendering
  budgets.

## Decision

Proceed with a pixel-art orbital-drydock proof using `512 x 512` generation
guides, manually reconstructed integer-grid SVG source, and lossless PNG runtime
atlases. Use a `24 px` native tile master exported to a `48`-world-unit
`TileMapLayer` grid generated from existing gameplay geometry. Keep stateful
terrain separate, rebuild the player as a layered 16-direction craft, and retain
the current batched high-count renderer.

Do not yet replace the current visual specification or live assets. The next
design action is the four-artifact proof package above; approval of that package
is the gate for implementation.
