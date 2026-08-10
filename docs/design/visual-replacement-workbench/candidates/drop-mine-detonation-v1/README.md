---
type: evidence
status: active
owner: BK
created: 2026-08-10
last_reviewed: 2026-08-10
scope: ImageGen provenance and exact-byte approval gate for the Drop Mine detonation candidate
related:
  - ../../../VISUAL_SYSTEM.md
  - ../../../../../.agents/execplans/2026-08-10-combat-correction-and-boss-pattern-expansion.md
---

# Drop Mine Detonation Candidate v1

## Purpose

This folder records the separately authored Drop Mine detonation candidate. It
is not a Thermal Burst variant and is not production-approved. The exact
switch-ready byte remains under the mirrored `to-be/assets/` path until BK
approves its hash.

## Sources

- Visual specification: `docs/design/VISUAL_SYSTEM.md`, read completely before generation.
- Canonical sheet: `docs/design/cardborne-universal-art-style-reference.png`.
- Canonical sheet SHA-256: `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- Runtime-scale reference: `build/visual-captures/phase9a-status-arrival-ko-1280/09g-electric-field-level-1.png`.
- Both references were supplied to ImageGen through `referenced_image_paths`.

## ImageGen prompt

```text
Use case: stylized-concept
Asset type: one top-down 2D game impact-effect raster candidate for Cardborne Drop Mine detonation
Input images: Image 1 is the mandatory Cardborne style-grammar reference only; do not reproduce any depicted object, silhouette, text, layout, UI, or ornament. Image 2 is a current gameplay capture used only to calibrate actual gameplay contrast, camera, and scale; do not copy the scene or HUD.
Primary request: create one restrained instantaneous kinetic mine detonation identity, not fire and not smoke, centered exactly on the mine origin.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for local background removal; absolutely uniform with no gradient, glow, texture, shadow, reflection, floor, or lighting variation.
Subject: a small flat ivory mechanical impact core made from 2 to 3 broad filled polygons, surrounded by exactly five short amber hard-edged pressure plates. Each pressure plate is one solid broad polygon that starts close to the core and ends well before the canvas edge. No extra fragments, no tiny shards, no dust, no cloud, no sparks. Use a small amount of dark cool-neutral separation only between the core and plates.
Style/medium: flat authored top-down 2D raster VFX, familiar industrial/general science fiction, antialiased hard edges, matte filled planes, no perspective extrusion and no 3D bevel rendering. Follow Image 1's limited-plane grammar only; do not copy its assets.
Composition/framing: square orthographic top-down view, exact center at canvas center, rotationally balanced but slightly asymmetric, entire effect occupies about 58 percent of canvas width and height with generous empty background. Must remain readable at 256x256 for 0.18 seconds.
Color palette: ivory core, restrained muted amber plates, small dark neutral separators. Do not use #00ff00 in the subject.
Constraints: one clean impact sprite; crisp removable outer edge; no cast/contact shadow; no text; no watermark; no logos; no UI; no mine body; no actors; no terrain; no projectiles; no animation frames.
Avoid: cloud-like white center, orange flame, fire, smoke, bloom, glow, gradient halo, ring, concentric geometry, long lightning bolts, thin rays, small debris, shards, dots, particles, nested outlines, photorealism, perspective, chunky 3D object.
```

## Findings

The accepted technical candidate is a transparent, centered five-plate kinetic
impact. It is visually distinct from the orange Thermal Burst, contains no
smoke, flame, ring, debris, or detached particles, and retains readable large
planes at all three intended runtime sizes.

### Exact files

| File | Purpose | SHA-256 |
| --- | --- | --- |
| `source-imagegen.png` | Original ImageGen chroma source | `c028599d871679a9f3028df837c63ed420a065f68b00eae9d5a13168e22b2f4c` |
| `drop-mine-detonation-alpha-source.png` | Non-creative chroma removal and edge cleanup source | `593114a0b3d97bf52c5eb8d949bbd0c4d608182c6b1adc340e5961fd626b3439` |
| `../../to-be/assets/art/visuals/production/gameplay/effects/drop_mine_detonation.png` | Centered transparent 256x256 switch target | `16fc0b4c945ad196d17ac75487465b7e507eb9597dc71e153194a65bc7e6d9eb` |

ImageMagick was used only for non-creative alpha handling, trimming, resizing,
and centering of the already-authored raster. It did not author or repair the
effect geometry.

## Gate

- Technical state: switch-ready candidate.
- User approval: absent for the exact `16fc...9eb` byte.
- Production manifest/provider/renderer registration: prohibited until that
  exact hash is approved.
