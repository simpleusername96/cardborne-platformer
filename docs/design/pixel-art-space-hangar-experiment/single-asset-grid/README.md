---
type: evidence
status: active
owner: BK
created: 2026-07-26
last_reviewed: 2026-07-26
topic: Single-asset grid-guided ImageGen to pixel-SVG workflow
scope: One player-craft experiment; no live game integration
source: ../../pixel-art-space-hangar-research.md
related:
  - ../README.md
  - ../../pixel-art-space-hangar-research.md
---

# Single-Asset Pixel-Grid Experiment

## Purpose

Verify BK's intended workflow with one individual image:

1. script a blank white `512 x 512` canvas with grid lines;
2. include that image as the ImageGen input;
3. generate exactly one asset on the grid;
4. sample the grid into a native logical raster;
5. convert the raster to editable pixel SVG;
6. normalize color and manually reinforce the silhouette.

The experiment uses a player craft because forward direction, symmetry, weapon
separation, and engine anchors make grid failures easy to see.

## Sources

- BK's 2026-07-26 correction and hand-drawn grid reference.
- [`create_pixel_grid.ps1`](../../../../tools/design/create_pixel_grid.ps1).
- Built-in ImageGen with [`01-grid-32x32.png`](./01-grid-32x32.png) as the edit
  target.
- [`raster_to_pixel_svg.ps1`](../../../../tools/design/raster_to_pixel_svg.ps1).
- Rendered and measured artifacts in this directory.

## Artifacts

| File | Role |
| --- | --- |
| [`00-ship-palette.png`](./00-ship-palette.png) | White background plus seven allowed ship colors |
| [`01-grid-32x32.png`](./01-grid-32x32.png) | Scripted white `512 x 512` canvas; `32 x 32` logical cells; 16px per cell |
| [`02-imagegen-ship.png`](./02-imagegen-ship.png) | Unmodified built-in ImageGen output |
| [`02-imagegen-ship-512.png`](./02-imagegen-ship-512.png) | Output normalized to the input-template dimensions |
| [`03-sampled-ship-32.png`](./03-sampled-ship-32.png) | Cell-center sample reduced to native `32 x 32`, transparent background |
| [`03-sampled-ship-32-16x.png`](./03-sampled-ship-32-16x.png) | Nearest-neighbor inspection preview |
| [`04-auto-ship-32.svg`](./04-auto-ship-32.svg) | Automatic pixel-to-SVG conversion with 139 horizontal color runs |
| [`04-auto-ship-32.png`](./04-auto-ship-32.png) | Native raster exported from the automatic SVG |
| [`04-auto-ship-32-16x.png`](./04-auto-ship-32-16x.png) | Automatic SVG inspection preview |
| [`05-cleaned-ship-32.svg`](./05-cleaned-ship-32.svg) | Manually normalized symmetric SVG with functional layers |
| [`05-cleaned-ship-32.png`](./05-cleaned-ship-32.png) | Native cleaned raster |
| [`05-cleaned-ship-32-16x.png`](./05-cleaned-ship-32-16x.png) | Cleaned inspection preview |
| [`06-grid-overlay-proof.png`](./06-grid-overlay-proof.png) | Cleaned SVG placed back on the original coordinate grid |
| [`07-process-comparison.png`](./07-process-comparison.png) | Template, generation, sampled raster, and cleaned result |

## ImageGen Prompt

The built-in tool received `01-grid-32x32.png` as the edit target:

> Draw exactly one compact top-down orbital-drydock interceptor on the white
> `512 x 512`, `32 x 32` coordinate grid. Preserve the complete grid. Center the
> ship with its nose facing upward and keep it within columns 7–24 and rows
> 5–27. Every silhouette corner, wing step, engine block, cockpit block, and
> color boundary follows whole grid-cell boundaries. Use a broad arrowhead nose,
> compact armored chassis, two symmetric short wings, one forward cannon socket,
> and two separate rear engine housings. Use only `#202833`, `#222B35`,
> `#44515E`, `#D9A83D`, `#65A9B8`, and `#E8EEF0`. Add no environment, shadow,
> glow, gradient, texture, dither, text, second ship, or isometric perspective.

## Findings

### The corrected grid changed generation behavior

Unlike the rejected multi-slot template, the single-asset grid gave ImageGen one
coordinate system and one subject. The generated craft:

- remained centered and fully inside the canvas;
- preserved the visible grid;
- used whole-cell stair steps for most of its silhouette;
- made the upward facing direction immediate;
- kept paired wings and engine housings recognizable.

The model still returned `1254 x 1254`, not the input's exact dimensions, and
introduced soft shading inside cells. The template guides composition and cell
alignment; it does not enforce output resolution or palette by itself.

### Center sampling performs the actual pixel conversion

The generated square was normalized to `512 x 512`. Sampling one center point
per 16px grid cell produced a `32 x 32` logical raster. This operation:

- removed the grid lines;
- removed within-cell antialiasing and gradients;
- retained the generated silhouette;
- reduced the craft to six visible colors plus transparency.

This is more deterministic than resizing an ungridded generated image and
calling the result pixel art.

### Automatic SVG conversion remains editable

`raster_to_pixel_svg.ps1` omits transparent pixels and merges adjacent
same-color pixels into horizontal `<rect>` runs. The automatic result contains
139 runs in a `32 x 32` integer view box. Every visual pixel can be changed by
editing an integer coordinate, width, or fill.

### Manual reinforcement is still necessary

The sampled craft inherited asymmetric lighting and inconsistent cyan edging
from ImageGen. `05-cleaned-ship-32.svg` deliberately changes those generated
details:

- the symmetry axis is fixed between columns 15 and 16;
- the forward cannon is isolated as its own integer-aligned block;
- the cockpit and player-ownership color are centralized;
- cyan becomes a sparse material accent instead of a continuous outline;
- paired engine housings expose stable anchors for future `0–3` engine modules;
- the result uses six ship colors plus transparency and no raster effect.

## Limitations

- This validates the workflow, not the final Cardborne craft design.
- `32 x 32` produces a deliberately coarse ship. A `64 x 64` logical grid on
  the same `512 x 512` canvas should be compared before choosing the production
  player resolution.
- One upward-facing frame does not prove 16-direction consistency.
- Weapon recoil, engine animation, dash, damage, and upgrade overlays remain
  separate future tests.
- The live Godot project has not imported or rendered this craft.

## Decision

Use a scripted, blank `512 x 512` coordinate grid for each individual ImageGen
asset. Normalize the result to the template, sample the logical cell centers,
quantize to the semantic palette, convert the native raster to integer-grid SVG,
and then perform direct symmetry and functional-layer edits. Do not use a
multi-slot semantic sheet as the generation template.
