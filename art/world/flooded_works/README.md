# Flooded Works World Art Proof

This directory contains the accepted first-room proof for the production world-art
pipeline. It is intentionally smaller than a full stage kit.

## Visual direction

- Theme: an ancient flooded foundry built into a fortress ruin.
- Medium: flat raster art with broad geometric planes and no outlines.
- Palette: charcoal, deep blue-green, muted verdigris, desaturated rust, and
  restrained mustard light. Interactive terrain stays within the same family.
- Detail budget: large silhouettes first; sparse structural seams only. Do not add
  stippling, pointillism, speckles, grain, stains, dense hatching, tiny repeated
  bolts, or AI microtexture.
- Separation: distant images contain no playable platforms, hazards, characters,
  UI, or text. Terrain and hazards are independent foreground components.

## Background contract

- Each source panel is `2048x1536` (`4:3`).
- Adjacent panels overlap by `192 px` and form a `3904x1536` composite.
- The second panel was generated from the first panel's right-edge reference, then
  center-cropped, Lanczos-resized, and blended through the accepted overlap.
- `Parallax2D.scroll_scale` is `0.18`; horizontal/vertical overscan is `192/128`.
- Only the current location's string-addressed panels are loaded. Other stage
  definitions retain the procedural fallback.

## Representative terrain contract

`fw_poison_timing` contains six surface instances but five unique collision
signatures. The duplicate `240x100` masses reuse one raster type. The five runtime
assets are not a tile grid and do not alter collision shapes, support metadata, or
room placement.

## Stateful component contract

The poison vent and crumbling platform each own one canonical `base.png`. Runtime
state changes only overlay visibility (and collision behavior already owned by the
component). The base texture, base node, local position, and root pivot stay fixed.

The two files under `art/source/flooded_works/` are image-generation direction
boards. They are not atlases and are never sliced at runtime. Production PNGs in
this directory are normalized, exact-size assets derived from the measured room
contract.
