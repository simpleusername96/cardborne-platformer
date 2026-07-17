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
  - ../../../../docs/design/UI_VISUAL_SYSTEM.md
---

# Flooded Works Isometric Raster Slice

## Purpose

Record the first runtime-approved 2D raster assets used on the native 3D combat
proof. These files prove the hybrid presentation path; they are not yet a full
terrain, prop, enemy, or action-animation kit.

## Sources

- `../backgrounds/panel_01.png`: owner-reviewed far-background image reused
  behind the 3D pass.
- `surfaces/foundry-architecture-albedo-v1.png`: 1024x1024 runtime albedo used
  through world-triplanar projection.
- `../../../source/flooded_works/isometric/foundry-architecture-albedo-draft-v1.png`:
  generated 1254x1254 layout input retained for the final same-hue style pass.
- `actors/traveler-walk-sheet-v1.png`: 1024x1024 alpha walk sheet with sixteen
  256x256 cells.
- `../../../source/flooded_works/isometric/traveler-walk-sheet-chroma-v1.png`:
  1254x1254 generated chroma-key source retained for reproducibility.
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
- Traveler renders as a camera-facing `Sprite3D`. The primitive body and head are
  retained but hidden; the capsule collision remains unchanged.
- Runtime sprite rows are mapped explicitly rather than inferred from filenames:

| Row | Camera-relative facing | Columns |
| ---: | --- | --- |
| 0 | away-right | contact, passing, opposite contact, settle |
| 1 | away-left | contact, passing, opposite contact, settle |
| 2 | toward-right | contact, passing, opposite contact, settle |
| 3 | toward-left | contact, passing, opposite contact, settle |

## Generation Record

Mode: built-in image generation. Runtime assets were copied into the repository;
the generated defaults outside the repository are not runtime dependencies.

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

Final Traveler prompt:

```text
Use case: stylized-concept
Asset type: production 4-by-4 isometric game character walk-cycle sprite sheet for a Godot Sprite3D billboard
Input images: Image 1 is the exact Traveler identity reference for hood, angular mask, teal/navy coat, and red scarf; Image 2 is the accepted full-body isometric scale and silhouette reference
Primary request: create one consistent full-body Traveler walk-cycle sheet with exactly 16 equal cells arranged in four columns and four rows
Subject: the same single hooded Traveler in every cell; off-white hood and angular mask, dark charcoal and muted teal long coat, restrained bright red scarf/sash, dark trousers and boots; hands empty; practical compact silhouette
Style/medium: clean flat-color raster game sprite; broad geometric color planes; simplified hand-painted cutout; no outlines; no texture noise; not pixel art
Composition/framing: exact 4 columns x 4 rows, equal invisible cells, one full-body character centered in every cell, identical scale and foot baseline within each row, generous padding, no character crosses a cell boundary
Camera/view: consistent high three-quarter isometric view in every cell, orthographic feel, feet fully visible
Scene/backdrop: perfectly flat solid #ff00ff chroma-key background for local background removal
Lighting/mood: simple neutral game lighting expressed only with two or three flat value planes on the character
Color palette: off-white hood, charcoal/navy body, muted teal coat, controlled red scarf; do not use #ff00ff in the character
Constraints: background must be one uniform #ff00ff color with no shadows, gradients, texture, reflections, floor plane, or lighting variation; no cast shadow; no contact shadow; crisp edges; exact same character identity and proportions in all 16 cells; no text; no logos; no watermark; no grid lines; no cell borders; no weapons; no extra objects
Avoid: outline, grain, stippling, speckles, painterly smears, photorealism, animation notes, labels, duplicated limbs, cropped feet, changing costume, changing camera angle
```

The generated Traveler source used the installed chroma-removal helper with
border auto-keying, soft matte, despill, thresholds 12/220, then ImageMagick
Lanczos normalization to 1024x1024. The runtime sheet has transparent corner
pixels and non-empty alpha content in every cell.

## Recommendations

- Keep architecture variation close in hue. Add future moss, rust, warning, or
  state marks as separately controlled decals/overlays instead of baking them
  into the base albedo.
- Create attack, ranged, guard, hit, and defeat sprite sheets only after the
  four-direction locomotion scale and silhouette are owner-approved.
- Retain world-space gameplay feedback until a replacement sprite/effect proves
  the same startup, active, recovery, and targeting information.

## Limitations

- The sheet has locomotion poses only; sword and shield feedback remain 3D proof
  geometry during their relevant actions.
- `no_depth_test` keeps Traveler readable at the fixed foreground cutaway, so
  the sprite intentionally draws above cover/wall pixels in this proof.
- One world-triplanar albedo is not a production modular terrain library and
  does not define room scale, collision, or navigation.
