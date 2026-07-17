---
type: evidence
status: active
created: 2026-07-16
last_reviewed: 2026-07-17
owner: BK
source: Owner-reviewed Flooded Works art proof
topic: Retained world-art direction after the isometric action RPG reset
related:
  - ../../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../../.agent/execplans/2026-07-17-isometric-action-rpg-pivot.md
  - ../../../.agent/execplans/2026-07-17-rasterized-3d-presentation.md
---

# Flooded Works World-Art Evidence

## Purpose

Preserve the accepted visual language and source images without carrying the
former side-view room, collision, hazard-state, or parallax contracts into the
new isometric runtime.

## Sources

- `backgrounds/`: owner-reviewed sequential environment panels.
- `terrain/` and `components/`: flat-color foreground studies from the retired
  platformer implementation.
- `art/source/flooded_works/`: image-generation direction boards; they are not
  runtime atlases.

## Findings

- Theme: ancient flooded foundry inside a fortress ruin.
- Medium: flat raster art built from broad geometric planes with no outlines.
- Palette: charcoal, deep blue-green, muted verdigris, desaturated rust, and
  restrained mustard light.
- Detail budget: large silhouettes first; no stippling, speckles, grain, stains,
  dense hatching, tiny repeated bolts, or AI microtexture.
- Backgrounds contain no baked characters, enemies, hazards, UI, or text.
- Gameplay-significant terrain and props must remain separable from decorative
  background art.
- `isometric/` now contains the first runtime vertical slice: one restrained
  same-hue surface albedo, a corrected two-direction Traveler locomotion atlas,
  melee/ranged/guard atlases, and a raster ranged bolt. It proves the hybrid
  renderer but does not establish a complete production asset kit.

## Recommendations

- Reuse palette, value grouping, shape simplification, and material language.
- Recompose future world art for the new camera and navigation plane; do not
  interpret these side-view images as collision, room geometry, or scale truth.
- Build a small isometric terrain/prop proof only after the graybox combat camera
  and readable engagement distances are accepted.
- Keep runtime base surfaces within one close hue family. Add rust, moss,
  warnings, and other variation through separate controlled layers or decals.

## Limitations

- The retained panels are not an isometric map kit.
- Terrain and state-overlay images are visual studies only until a new asset
  contract is approved.
- Exact source dimensions and seams describe these files, not future runtime
  streaming or camera behavior.
