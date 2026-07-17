---
type: evidence
status: active
owner: BK
created: 2026-07-18
last_reviewed: 2026-07-18
topic: Flooded Works Floor 1 map, encounter, enemy, and prop visual direction
scope: Composition evidence for the connected Floor 1 execution plan; not runtime assets or exact geometry
source: Built-in image generation using current runtime, approved Flooded Works art, Traveler atlas, Slime King art, and prior proof mockups as references
related:
  - ../../../../.agent/execplans/2026-07-18-flooded-works-floor1-map-enemies.md
  - ../../UI_VISUAL_SYSTEM.md
  - ../../../../art/world/flooded_works/README.md
---

# Flooded Works Floor 1 Visual Direction

## Purpose

Explain how the current Movement Check can expand into connected rooms, how one
representative encounter composes enemies/cover/objectives/props, and how the
first enemy/prop family should read. These are design targets for implementation
and later asset production, not images to apply directly to runtime.

## Sources

- `build/validation/movement-check-1280x720.png`: current playable camera,
  Traveler scale, wall cutaway, surface, and hybrid 3D/raster state.
- `art/world/flooded_works/backgrounds/panel_01.png`: approved distant palette,
  monumental drowned-foundry scale, cyan depth, and restrained amber light.
- `art/world/flooded_works/isometric/actors/traveler-locomotion-sheet-v2.png`:
  actor camera, proportion, palette, and rendering.
- `art/ui/production/illustrations/bosses/slime_king.png`: boss identity.
- `art/source/flooded_works/terrain-component-source-sheet.png`: close-hue stone,
  metal, waterline, and rust-accent language; not a runtime atlas.
- `docs/design/mockups/isometric-proof-v01/02-foundry-approach.png` and
  `04-pump-gallery.png`: earlier encounter/room ideas only. Their old controls,
  high detail, and exact composition are not retained.

## Findings

### 1. Connected floor route

![Connected Flooded Works Floor 1](./01-connected-floor-route.png)

- Large terrain silhouettes create variation: dry intake, press/rail foundry,
  water-channel pump room, circular pressure/reservoir threshold.
- Matching gates, materials, fog, and light make separate room scenes read as one
  facility.
- The image depicts simultaneous spatial continuity for explanation. Runtime
  loads only the active room and uses short gate transitions.
- Small accidental figure-like marks in the first room are generation artifacts;
  backgrounds and runtime room surfaces must not contain baked actors.

### 2. Pump Gallery combat composition

![Pump Gallery combat](./02-pump-gallery-combat.png)

- The room exceeds one camera frame and keeps the foreground open.
- Pursuer, Shooter, and Controller occupy different distance bands.
- Permanent cover interrupts the Shooter lane; the Controller owns only one
  active warning disk.
- Pumps, intact/broken crates, potion, water, and exit read as separate components.
- Exact positions and counts come from the execution plan, not image pixels.

### 3. Enemy and prop family

![Enemy and prop roster](./03-enemy-prop-roster.png)

- Ordinary roles share one charcoal/teal material family and differ through
  silhouette, stance, and tool.
- Slime King is deliberately larger and keeps the retained crown identity.
- Crate, potion, pump, and vent establish prop shapes; each state still needs an
  individual normalized runtime asset.
- The fourth lower-row object is only a salvage-shape study. The active map/enemy
  plan does not implement material pickups.

## Recommendations

- Graybox and validate navigation/combat before producing the raster enemy pack.
- Generate one production asset/atlas per runtime owner and state family. Never
  crop a multi-object concept sheet into game assets.
- Preserve same-hue foregrounds, broad value groups, no outlines, and minimal
  surface noise at gameplay scale.
- Let telegraphs, hit flashes, and live UI supply state; do not paint state into
  room backgrounds.

## Limitations

- Image generation cannot establish collision, navigation, timing, hitbox,
  camera bounds, exact dimensions, or animation consistency.
- The route image is more distant than the actual gameplay camera.
- Figures and props are illustrative silhouettes, not sprite sheets.
- All final gameplay decisions live in the linked active execution plan and
  current product specifications.

## Generation Record

Mode: OpenAI built-in image generation tool. Originals remain under the local
Codex generated-image store; selected copies are saved here.

### `01-connected-floor-route.png`

```text
Use case: stylized-concept
Asset type: wide connected-floor environment concept for a Godot isometric action RPG
Input images: Image 1 is the current playable runtime screenshot and fixes the orthographic high three-quarter camera, character scale, broad floor treatment, cutaway foreground walls, and current hybrid 3D/raster presentation. Image 2 is the approved Flooded Works distant-background reference and fixes the drowned ancient-foundry palette, monumental arches, cyan depth light, and very restrained amber guidance light. Image 3 is an earlier Foundry Approach mockup used only for readable combat-space proportions and gate language, not for its UI, controls, texture density, or exact composition.
Primary request: show one coherent Floor 1 as four distinct but connected authored rooms in a single wide sequential cutaway panorama: a dry intake movement court, a broken foundry approach with broad press bases and rails, a pump gallery crossed by simple dark-teal water channels with two pump stations, and a circular pressure vault ending at a monumental reservoir gate. Connect every room through clearly matching stone-and-metal gates and short corridors so the route feels physically continuous. Each room must have a different large terrain silhouette while remaining unmistakably the same Flooded Works complex.
Style/medium: clean flat-color raster game environment over simple isometric 3D forms; large geometric color masses; outline-free; matte; production concept board, not painterly concept art.
Composition/framing: 16:9 wide establishing view, high three-quarter orthographic isometric perspective, four readable room masses left-to-right, consistent scale, one traversable ground elevation, low or absent camera-facing walls, broad open combat lanes, clear door-to-door flow.
Color palette: dominant charcoal #172126, deep blue-green #203238, slate teal #2B464A, muted verdigris #3E6261, tiny restrained rust and mustard accents, pale cyan only for distant depth.
Materials/textures: broad clean stone and oxidized metal planes; water as simple flat shapes; no surface dirt texture.
Constraints: no characters, enemies, hazards, pickups, UI, labels, text, logos, watermark, room borders, grid, arrows, or diagram symbols. Gameplay-significant props must remain visually separable from the background. Keep every room readable at game camera distance.
Avoid: outlines, pointillism, stippling, grain, speckles, stains, hatching, dense cracks, tiny repeated bolts, tile-like repetition, noisy moss, high walls hiding the play area, stacked floors, stairs as gameplay elevation, side-view platform geometry, photorealism, glow-heavy sci-fi lighting.
```

### `02-pump-gallery-combat.png`

```text
Use case: stylized-concept
Asset type: final gameplay-screen composition target for the Pump Gallery room of a Godot isometric action RPG
Input images: Image 1 is the current playable runtime screenshot and fixes the exact orthographic high three-quarter camera, current Traveler scale, cutaway-wall strategy, and hybrid 3D/raster rendering. Image 2 is the approved Traveler locomotion atlas and fixes the Traveler's hood, angular mask, teal coat, red scarf, proportions, and flat raster rendering. Image 3 is an earlier Pump Gallery mockup used only for the two-pump objective and readable combat-space idea; replace its dense texture, old enemies, old controls, and UI with the cleaner current direction.
Primary request: create one believable in-game Pump Gallery combat view. The Traveler stands in the lower-left third and faces into the room. A compact melee Pursuer actively curves around low cover toward the Traveler. A tall ranged Shooter laterally repositions behind a permanent cover block with a single ordinary projectile visible; the projectile lane must visibly terminate at cover. A mid-range Controller stands near the second pump and creates one simple amber warning disk on the ground. Place two large pump stations on opposite sides, one broad dark-teal water channel crossed by two dry walkable lanes, one matching north exit gate, two waterlogged wooden supply crates at safe side margins, one broken crate with a small potion vial and a few scrap pieces beside it, and no other loose clutter.
Style/medium: clean flat-color raster game art over simple isometric 3D forms; broad geometric planes; outline-free; matte; practical gameplay mockup rather than painterly concept art.
Composition/framing: 16:9 gameplay framing, same camera height and actor scale as Image 1, room larger than the visible frame, camera-facing walls absent or very low, foreground remains unobstructed, distinct open lanes around permanent cover, every actor and pickup fully readable.
Color palette: charcoal, deep blue-green, slate teal, muted verdigris; enemies stay in close same-hue material families with small role accents only; controlled coral for hostile warning and tiny mustard for pumps/pickup.
Materials/textures: large clean stone and oxidized metal planes; flat water; very restrained wear.
Constraints: no HUD, labels, text, logo, watermark, minimap, attack trajectory line, enemy movement path, persistent target line, glowing outlines, floating panels, health bars, extra characters, or baked interface. Only the active Controller warning disk is shown as a gameplay telegraph. One traversable ground elevation; visual water/architecture must not imply platform jumping.
Avoid: outlines, speckles, grain, stains, pointillism, dense cracks, tiny repeated details, unrelated enemy colors, visual clutter, tall foreground walls, stacked floors, stairs as gameplay elevation, side-view platform geometry, photorealism, excessive bloom.
```

### `03-enemy-prop-roster.png`

```text
Use case: stylized-concept
Asset type: enemy-and-gameplay-prop concept sheet for a Godot isometric action RPG
Input images: Image 1 is the approved Traveler atlas and fixes the high three-quarter isometric actor camera, clean flat raster geometry, human scale, teal/charcoal/off-white material language, and outline-free rendering. Image 2 is the approved Slime King illustration and fixes the boss's simple broad faceted shape language and mustard crown accent. Image 3 is the Flooded Works terrain source board and fixes the same-hue stone, oxidized metal, waterline, and extremely restrained rust accent.
Primary request: create one clean concept sheet with exactly two loose rows and no visible grid or labels. Top row: four complete isometric figures at consistent ground baseline and readable relative scale — (1) a compact fast Pursuer made from low drowned-foundry armor with a short cleaver and forward-leaning silhouette, (2) a taller ranged Shooter with a compact rivet-crossbow and sideways repositioning pose, (3) a mid-range Controller with a pressure staff and wide grounded robe/armor silhouette, and (4) the same crowned Slime King identity from Image 2 at visibly larger boss scale. Each ordinary enemy must be visually related through the same stone/metal family but immediately distinguishable by silhouette, weapon, and stance rather than unrelated colors.
Bottom row: exactly six separate gameplay props with generous spacing — one intact waterlogged wooden supply crate, the same crate broken open, one small amber potion vial, one compact rusted-scrap bundle, one waist-high pump activation console, and one low circular pressure vent base in inactive state.
Style/medium: clean flat-color raster game concept art; broad geometric color planes; simplified hand-painted cutout; no outlines; no texture noise; not pixel art; not a production sprite atlas.
Composition/framing: 16:9 landscape sheet, neutral dark blue-green background, top figures fully visible from head to feet, bottom props fully visible, generous empty space, consistent high three-quarter isometric view and light direction.
Color palette: charcoal, deep blue-green, slate teal, muted verdigris, off-white masks, tiny controlled coral role marks, restrained mustard only for potion/crown/machine guidance; wooden crate stays desaturated brown within the same dark value family.
Constraints: no Traveler in the output, no text, labels, numbers, arrows, borders, grid, UI, health bars, telegraph circles, floor scene, cast shadows, logos, or watermark. Every item is one distinct readable silhouette and nothing overlaps.
Avoid: outlines, bright unrelated enemy palettes, speckles, grain, stains, hatching, dense cracks, tiny repeated bolts, painterly smears, photorealism, excessive glow, duplicate props, extra weapons, cropped feet, changing camera angle, visual clutter.
```
