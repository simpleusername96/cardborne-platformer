---
type: evidence
status: active
owner: BK
created: 2026-07-17
last_reviewed: 2026-07-18
source: Built-in image generation and rendered Godot 4.7 validation
topic: Flooded Works raster assets for the native 3D proof
related:
  - ../README.md
  - ../../../../.agent/execplans/2026-07-17-rasterized-3d-presentation.md
  - ../../../../.agent/execplans/2026-07-17-traveler-raster-action-correction.md
  - ../../../../.agent/execplans/2026-07-17-traveler-lateral-dash-presentation.md
  - ../../../../docs/design/UI_VISUAL_SYSTEM.md
---

# Flooded Works Isometric Raster Slice

## Purpose

Record the runtime-approved 2D raster assets used on the native 3D combat proof.
The current slice covers diagonal and lateral Traveler locomotion, dedicated
dash/melee/ranged/guard states, a short dash-afterimage effect, one ranged
projectile, the arena surface, and the distant backdrop. It is not yet a full
terrain, prop, enemy, boss, or effects kit.

## Sources

- `../backgrounds/panel_01.png`: owner-reviewed far-background image reused
  behind the 3D pass.
- `surfaces/foundry-architecture-albedo-v1.png`: 1024x1024 runtime albedo used
  through world-triplanar projection.
- `../../../source/flooded_works/isometric/foundry-architecture-albedo-draft-v1.png`:
  generated 1254x1254 layout input retained for the final same-hue style pass.
- `actors/traveler-locomotion-sheet-v2.png`: corrected 2048x1024 locomotion
  atlas with eight 512x512 cells.
- `actors/traveler-lateral-sheet-v1.png`: dedicated right-profile four-frame
  locomotion row, duplicated vertically for the common 4x2 runtime contract and
  mirrored by the presenter for screen-left movement.
- `actors/traveler-dash-sheet-v1.png`: dedicated two-direction dash atlas with
  compress, launch, glide, and braking phases.
- `actors/traveler-melee-sheet-v1.png`, `traveler-ranged-sheet-v1.png`, and
  `traveler-guard-sheet-v1.png`: matching two-direction action atlases.
- `effects/traveler-ranged-bolt-v1.png`: alpha ranged-projectile art.
- `../../../source/flooded_works/isometric/actors/`: selected generated chroma
  sources retained for reproducibility and excluded from Godot import.
- `../../../ui/production/illustrations/characters/traveler.png`: Traveler
  identity reference; it remains a UI illustration rather than a runtime sprite.

All generated art is original project work produced with the built-in image
generation path. No third-party visual asset was added by this slice.

## Findings

- 3D geometry, collision, targeting, and camera remain authoritative.
- The background is a negative-layer Canvas image and never supplies collision.
- One matte `StandardMaterial3D` applies the surface PNG to room, gate, corridor,
  and cover meshes. The texture uses only close charcoal/blue-green/teal values;
  accent colors and state variation remain separate future layers.
- Traveler renders as one camera-facing `Sprite3D`. Primitive body, head, sword,
  and shield presentation remain in the scene only as hidden rollback geometry;
  the capsule and gameplay queries are unchanged.
- Movement frames advance from actual X/Z distance traveled, not elapsed time.
  A stopped Traveler always returns to column zero, preventing feet from cycling
  while blocked or idle.
- The diagonal/action atlases author away-right and toward-right. Left-facing
  states use horizontal mirroring, so opposite directions cannot drift into
  independently generated proportions. Pure screen-left/right locomotion uses
  the separate right-profile sheet and mirrors it for left.
- A facing enters the lateral locomotion sector only when its absolute
  camera-right component is at least 1.5 times its depth component. This keeps
  arrow-key diagonals on the accepted diagonal atlas without sector flicker.
- Dash uses its own actor atlas. While the authoritative dash is active, the
  presenter emits a non-colliding top-level raster copy every 0.65 m. Each copy
  stays at its world position, fades over 0.16 s, and frees itself.
- Every actor atlas is 2048x1024, four columns by two rows. Each 512x512 cell is
  deterministically repacked at one scale with its foot baseline at y=482.

Runtime direction mapping:

| Row | Camera-relative facing | Columns |
| ---: | --- | --- |
| 0 | away-right; mirrored for away-left | selected by the active atlas |
| 1 | toward-right; mirrored for toward-left | selected by the active atlas |

Runtime column mapping:

| Atlas | 0 | 1 | 2 | 3 |
| --- | --- | --- | --- | --- |
| Locomotion | contact / idle | passing | opposite contact | passing |
| Lateral locomotion | right-foot contact / idle | passing | left-foot contact | passing |
| Dash | compress | launch | low glide | brake / recover |
| Melee | startup | swing | contact | recovery |
| Ranged | ready | draw | release | recovery |
| Guard | raise | settle | hold A | hold B |

## Generation Record

Mode: built-in image generation, followed by deterministic local chroma removal
and atlas normalization. Runtime assets were copied into the repository; the
generated defaults outside the repository are not runtime dependencies.

Final surface prompt:

```text
Use case: style-transfer
Asset type: production world-triplanar albedo texture for the current isometric 3D arena
Input images: Image 1 is the edit target and its broad panel layout must remain; Image 2 is the approved distant Flooded Works palette reference
Primary request: simplify and recolor Image 1 so every surface stays within one close charcoal-to-blue-green material family
Style/medium: flat-color raster game texture; broad geometric planes; outline-free; very clean and matte
Composition/framing: preserve the seamless square coverage and large panel distribution from Image 1; fill the entire image
Color palette: only charcoal #172126, deep blue-green #203238, slate teal #2B464A, and muted verdigris #3E6261; nearby values only
Materials/textures: large quiet stone/metal panels with very sparse broad seams
Constraints: remove every yellow, mustard, brass, lime, moss-green, rust, orange, and bright cyan mark; no accent color; no stains; no vegetation; no cracks; no perspective; no directional lighting; no shadows; no gradients; no text; no logos; no watermark; seamless edges
Avoid: repeated decoration, small details, grain, stippling, speckles, high contrast, photorealism, visible focal elements
```

Shared final Traveler generation contract:

```text
Use case: stylized-concept / targeted edit
Asset type: production 4-column by 2-row isometric Traveler sprite sheet for a Godot Sprite3D billboard
Primary request: preserve one exact Traveler identity and produce a readable four-phase sequence for [locomotion | sword melee | bow ranged | round-shield guard]
Subject: the same hooded Traveler in every cell; off-white hood and angular mask, dark charcoal and muted teal long coat, restrained red scarf, dark trousers and boots; include only the action-appropriate sword, bow, or shield
Style/medium: clean flat-color raster game sprite; broad geometric color planes; simplified hand-painted cutout; no outlines; no texture noise; not pixel art
Composition/framing: exact 4 columns x 2 rows, equal invisible cells, one full-body character centered in every cell, identical scale and foot baseline, generous padding, no figure or equipment crosses a cell boundary
Camera/view: consistent high three-quarter isometric view in every cell, orthographic feel, feet fully visible
Direction rows: top row faces away-right; bottom row faces toward-right; never create left-facing variants because runtime mirrors them
Scene/backdrop: perfectly flat solid #ff00ff chroma-key background for local background removal
Lighting/mood: simple neutral game lighting expressed only with two or three flat value planes on the character
Color palette: off-white hood, charcoal/navy body, muted teal coat, controlled red scarf; do not use #ff00ff in the character
Constraints: uniform chroma background; no cast/contact shadow; crisp edges; exact same proportions in all eight cells; no text, logos, watermark, grid, cell borders, targets, hit markers, projectile, or extra objects
Avoid: outline, grain, stippling, speckles, painterly smears, photorealism, duplicated limbs/equipment, cropped feet, changing costume, changing camera angle, four unrelated character illustrations
```

The final locomotion, melee, and ranged selections each received one targeted
edit that changed only a malformed direction row or missing bow while preserving
the accepted cells. Guard was accepted from its first coherent selection.

Final lateral locomotion prompt:

```text
Use case: stylized-concept with identity references
Asset type: production lateral locomotion sprite source for a Godot Sprite3D billboard
Input images: Image 1 is the accepted Traveler locomotion atlas and is the main costume, proportion, palette, rendering, and camera-height reference. Image 2 is the same Traveler portrait and reinforces the exact hood, angular mask, red scarf, teal coat, and charcoal shoulder armor identity.
Primary request: create exactly four sequential full-body WALKING poses of this same Traveler moving in a strict side-on profile toward screen-right. This must be a genuinely lateral 90-degree profile, not an away-facing or toward-facing three-quarter pose.
Animation order, left to right: right-foot contact, passing pose, left-foot contact, passing pose. Show natural alternating arms, stable torso and head, planted boots, restrained coat-tail motion, and one continuous readable gait.
Style/medium: clean flat-color raster game sprite; broad geometric color planes; simplified hand-painted cutout; no outlines; no texture noise; not pixel art.
Composition/framing: one horizontal row of exactly four equal invisible cells; one complete character centered in each cell; identical scale, camera height, foot baseline, and proportions; generous clear padding around every figure; no overlap and no figure crosses a cell boundary.
Scene/backdrop: perfectly flat solid #ff00ff chroma-key background, uniform edge to edge.
Color palette: off-white hood, angular dark mask with muted teal mark, charcoal/navy body, muted teal long coat, restrained red scarf, dark trousers and boots; never use #ff00ff inside the character.
Constraints: preserve the exact accepted Traveler identity; no weapons, shield, projectile, effect, cast shadow, contact shadow, floor, gradient, lighting variation in the backdrop, grid lines, borders, text, logo, watermark, extra character, duplicated limb, cropped feet, or costume changes.
Avoid: diagonal three-quarter facing, turning between frames, bobbing baseline, changing body width, painterly smears, grain, stippling, speckles, small repeating detail, photorealism.
```

Final dash prompt:

```text
Use case: stylized-concept with identity references
Asset type: production dash-action sprite source for a Godot Sprite3D billboard
Input images: Image 1 is the accepted Traveler locomotion atlas and is the main costume, body proportion, two-row facing, palette, rendering, and camera-height reference. Image 2 is the same Traveler portrait and reinforces the exact hood, angular mask, red scarf, teal coat, and charcoal shoulder armor identity.
Primary request: create exactly eight sequential full-body DASH poses of this same Traveler arranged as an exact 4-column by 2-row sprite sheet. This is one short evasive ground dash, not ordinary walking.
Direction rows: top row consistently faces away-right in a high three-quarter isometric view; bottom row consistently faces toward-right in the same high three-quarter isometric view. Never turn or switch direction within a row. Runtime will mirror each row for left.
Animation order in both rows, left to right: low compressed anticipation with weight forward, explosive launch with a long first stride, low fast glide with coat and scarf trailing behind, controlled braking/recovery while still facing the same direction. The silhouette must read as rapid intentional evasion in every cell.
Style/medium: clean flat-color raster game sprite; broad geometric color planes; simplified hand-painted cutout; no outlines; no texture noise; not pixel art.
Composition/framing: exactly four columns and two rows of equal invisible square cells; one complete character centered in each cell; identical scale, camera height, foot baseline, and proportions; generous padding; no figure crosses a cell boundary.
Scene/backdrop: perfectly flat solid #ff00ff chroma-key background, uniform edge to edge.
Color palette: off-white hood, angular dark mask with muted teal mark, charcoal/navy body, muted teal long coat, restrained red scarf, dark trousers and boots; never use #ff00ff inside the character.
Constraints: preserve the exact accepted Traveler identity; no weapon, shield, projectile, glow, streak, afterimage, particle, dust, cast shadow, contact shadow, floor, gradient, lighting variation in the backdrop, grid lines, borders, text, logo, watermark, extra character, duplicated limb, cropped feet, or costume changes.
Avoid: normal upright walking, jumping, airborne acrobatics, sliding on knees, changing camera angle, changing direction, bobbing baseline, changing body width, painterly smears, grain, stippling, speckles, photorealism.
```

Both new assets were generated once with the built-in image-generation mode and
the two project references above. The generated defaults remain in the local
Codex generation store; selected copies are preserved as
`traveler-lateral-sheet-chroma-v1.png` and
`traveler-dash-sheet-chroma-v1.png` under the ignored source directory.

Final bolt generation contract:

```text
Create one small horizontal flat-color fantasy bolt/arrow projectile for the retained Traveler bow. Use a restrained off-white, muted teal, and tiny amber accent; broad clean shapes; no outline, glow, particles, text, shadow, floor, or extra objects. Center it with generous padding on a perfectly uniform #ff00ff chroma background.
```

Selected generated files were copied to the chroma source paths above. The
installed image-generation chroma helper ran with border auto-keying, soft
matte, despill, thresholds 12/220, then one retry with `--edge-contract 1`.
`tools/art/normalize_sprite_sheet.py` selected the eight figure components,
masked unrelated residue, applied a fixed 0.9 scale, and packed exact 512-square
cells. Runtime atlases have transparent corners, non-empty cells, safe horizontal
margins, and a shared foot baseline.

The lateral and dash sources used the same border auto-key, soft matte, despill,
and thresholds 12/220 without an edge-contraction retry. Lateral normalization
selected four figures at scale 0.78, then duplicated the normalized row; dash
normalization selected eight figures at scale 1.2. Both runtime atlases retain
the shared y=482 baseline and 2048x1024 format.

## Recommendations

- Keep architecture variation close in hue. Add future moss, rust, warning, or
  state marks as separately controlled decals/overlays instead of baking them
  into the base albedo.
- Retain world-space facing and short-lived targeting feedback until equivalent
  raster effects prove the same player-intent information.
- Add hit, defeat, and weapon-specific variants only when those gameplay states
  enter the accepted proof scope; reuse the locked cell and direction contract.

## Limitations

- `no_depth_test` keeps Traveler readable at the fixed foreground cutaway, so
  the sprite intentionally draws above cover/wall pixels in this proof.
- Hit reaction and defeat have no authored raster state yet.
- Two authored depth directions, one authored lateral profile, and mirroring
  assume the current fixed camera and no mechanically significant left/right
  equipment hand.
- One world-triplanar albedo is not a production modular terrain library and
  does not define room scale, collision, or navigation.
