---
type: evidence
status: active
owner: BK
created: 2026-07-26
last_reviewed: 2026-07-26
topic: Image-generation-to-pixel-atlas workflow experiment
scope: One modular space-hangar tile-sheet experiment; no live game integration
source: ../space-hangar-research.md
related:
  - ../../../docs/design/UI_VISUAL_SYSTEM.md
  - ../space-hangar-research.md
  - ./single-asset-grid/README.md
---

# Space-Hangar Pixel-Atlas Experiment

## Corrected Interpretation

This `4 x 4` semantic tile-sheet experiment is retained as evidence of an
incorrect interpretation. BK requested a `512 x 512` coordinate grid applied to
one individual generated image, not sixteen named asset slots inside one image.

Do not use `01-grid-template.*` as the asset-generation grid. The corrected
single-asset workflow and current evidence are in
[`single-asset-grid/README.md`](./single-asset-grid/README.md).

## Purpose

Test the rejected multi-slot interpretation with real artifacts:

1. make a constrained `512 x 512` grid template;
2. use it as an ImageGen layout and palette reference;
3. normalize the generated concept to the approved palette;
4. reconstruct it as an editable integer-grid SVG;
5. export deterministic PNGs and test repeated seams.

This historical experiment does not replace live Cardborne assets or the active
visual specification.

## Artifacts

| File | Role |
| --- | --- |
| [`00-palette.png`](./00-palette.png) | Exact nine-color remap palette |
| [`01-grid-template.svg`](./01-grid-template.svg) | Editable `512 x 512` layout, roles, palette, and constraints |
| [`01-grid-template.png`](./01-grid-template.png) | Raster reference supplied to ImageGen |
| [`02-imagegen-concept.png`](./02-imagegen-concept.png) | Unmodified built-in ImageGen result |
| [`02-imagegen-concept-quantized.png`](./02-imagegen-concept-quantized.png) | Generated result remapped to nine colors, with dithering disabled |
| [`03-cleaned-pixel-atlas.svg`](./03-cleaned-pixel-atlas.svg) | Manually reconstructed, editable `4 x 4` atlas with named tile groups |
| [`03-cleaned-pixel-atlas-native.png`](./03-cleaned-pixel-atlas-native.png) | Native `96 x 96` atlas: sixteen `24 x 24` cells |
| [`03-cleaned-pixel-atlas.png`](./03-cleaned-pixel-atlas.png) | Proposed runtime-scale `192 x 192` atlas: sixteen `48 x 48` cells |
| [`03-cleaned-pixel-atlas-4x.png`](./03-cleaned-pixel-atlas-4x.png) | Inspection-scale nearest-neighbor preview |
| [`04-seam-proof.png`](./04-seam-proof.png) | Repeated boundary and closed-wall-ring test |
| [`05-pipeline-comparison.png`](./05-pipeline-comparison.png) | Template, quantized generation, and cleaned atlas comparison |

## ImageGen Input

The built-in ImageGen tool was used. The `512 x 512` PNG template was supplied
as a layout reference with this prompt:

> Create a coherent `4 x 4` top-down orbital-drydock pixel-art tile family.
> Preserve the template's cell order and palette, but omit its labels, header,
> guides, and typography. Row 1 is space, floor base, floor panel, and floor
> grate. Row 2 is the floor-to-space rim facing north, east, south, and west.
> Row 3 is a solid steel wall facing north, east, south, and west. Row 4 is the
> four matching outer wall corners. Use strict top-down orthographic tiles,
> large flat pixel clusters, crisp stair-step edges, and only `#05070D`,
> `#0A1019`, `#202833`, `#293440`, `#141B24`, `#44515E`, `#222B35`, `#65A9B8`,
> and `#E8EEF0`. No text, UI, characters, gradients, bloom, dithering, speckle,
> tiny bolts, continuous outlines, or watermark.

## Findings

### Generation respected the composition, not the production contract

The generated result understood the broad material family and most cell roles.
It did not satisfy an exact tile contract:

- the tool returned `1254 x 1254`, despite the `512 x 512` reference;
- the result contained `36,617` colors;
- gradients and soft material shading appeared;
- stars and high-frequency surface noise appeared despite the avoid list;
- cyan frames became part of the image;
- opposite edge and wall thicknesses were not identical;
- the corner family was suggestive rather than mechanically connected.

This is still useful concept evidence. It is not a shippable atlas.

### Palette remapping fixes color count, not structure

ImageMagick remapping with dithering disabled reduced the concept to the exact
nine-color palette. The output retained scattered dark clusters because
quantization maps gradient pixels to discrete steps; it does not understand that
those clusters are unwanted texture. It also cannot correct tile topology,
pivots, edge thickness, or role mistakes.

Automatic quantization is therefore an inspection step, not the cleanup step.

### Integer-grid reconstruction produces editable pixel art

The cleaned SVG uses:

- a `96 x 96` integer view box;
- sixteen named `24 x 24` groups;
- integer-coordinate rectangles and paths;
- `shape-rendering="crispEdges"`;
- only the nine approved colors;
- no filters, gradients, opacity, masks, or automatic tracing.

The SVG is compact enough to edit a single pixel or color run directly. Runtime
PNGs are exported with nearest-neighbor scaling. The native and runtime atlases
both contain exactly nine colors.

### Seam proof passed, variety proof did not

The boundary strip joins without gaps and the four wall directions assemble into
a closed ring. The proof deliberately repeats one floor cell, which makes the
panel rhythm visibly repetitive. Production work therefore needs weighted floor
alternatives and larger `2 x 2` patterns, even though the underlying seam is
valid.

## What This Experiment Proves

- A generated concept can successfully set material language and broad
  silhouette.
- A `512 x 512` template is useful as a semantic guide, not a pixel-coordinate
  guarantee.
- Color remapping can enforce the palette but cannot replace pixel cleanup.
- An integer-grid SVG is a practical, patchable source for exact Codex edits.
- A lossless PNG atlas should remain the Godot runtime asset.
- Connected layouts must be rendered and inspected; an atlas sheet alone is not
  sufficient evidence.

## Limits Before Production

This is a pipeline proof, not a complete TileSet:

- it contains only a pilot cardinal-edge and outer-corner family;
- it does not yet contain all terrain-bitmask combinations, inner corners, or
  weighted alternatives;
- atlas extrusion/gutters and Godot import settings are not yet implemented;
- it has no collision or navigation data by design;
- the player craft, enemies, props, and combat effects have not gone through the
  same workflow;
- the live game has not been changed or rendered with these assets.

The next useful experiment is the layered player craft. It should reuse this
palette and test a `48 x 48` native frame, 16 aim directions, a separate weapon,
engine modules `0–3`, engine flame, dash, and hit-overlay anchors.
