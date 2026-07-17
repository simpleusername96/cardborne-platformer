---
type: evidence
status: active
owner: BK
created: 2026-07-17
last_reviewed: 2026-07-17
source: Built-in image generation and rendered Godot 4.7 validation
topic: Flooded Works raster assets for the native 3D proof
related:
  - ../README.md
  - ../../../../.agent/execplans/2026-07-17-rasterized-3d-presentation.md
  - ../../../../.agent/execplans/2026-07-17-traveler-raster-action-correction.md
  - ../../../../docs/design/UI_VISUAL_SYSTEM.md
---

# Flooded Works Isometric Raster Slice

## Purpose

Record the runtime-approved 2D raster assets used on the native 3D combat proof.
The current slice covers stable Traveler locomotion, the three explicit combat
actions, one ranged projectile, the arena surface, and the distant backdrop. It
is not yet a full terrain, prop, enemy, boss, or effects kit.

## Sources

- `../backgrounds/panel_01.png`: owner-reviewed far-background image reused
  behind the 3D pass.
- `surfaces/foundry-architecture-albedo-v1.png`: 1024x1024 runtime albedo used
  through world-triplanar projection.
- `../../../source/flooded_works/isometric/foundry-architecture-albedo-draft-v1.png`:
  generated 1254x1254 layout input retained for the final same-hue style pass.
- `actors/traveler-locomotion-sheet-v2.png`: corrected 2048x1024 locomotion
  atlas with eight 512x512 cells.
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
- Only two facings are authored. Left-facing states use horizontal mirroring, so
  opposite directions cannot drift into independently generated proportions.
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
- Dash currently uses distance-driven locomotion frames rather than a dedicated
  dash atlas. Hit reaction and defeat also have no authored raster state yet.
- Two authored directions and mirroring assume the current fixed camera and no
  mechanically significant left/right equipment hand.
- One world-triplanar albedo is not a production modular terrain library and
  does not define room scale, collision, or navigation.
