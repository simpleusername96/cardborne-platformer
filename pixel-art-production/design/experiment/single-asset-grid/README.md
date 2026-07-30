---
type: evidence
status: archived
owner: BK
created: 2026-07-26
last_reviewed: 2026-07-30
topic: Single-asset grid-guided ImageGen to pixel-SVG workflow
scope: Historical player-craft pixel-workflow experiment; not input for new combat-component design
source: ../../space-hangar-research.md
related:
  - ../../../README.md
  - ../../space-hangar-research.md
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
- [`create_pixel_grid.ps1`](../../../tools/design/create_pixel_grid.ps1).
- Built-in ImageGen with [`01-grid-32x32.png`](./01-grid-32x32.png) as the edit
  target.
- [`snap_image_to_pixel_grid.ps1`](../../../tools/design/snap_image_to_pixel_grid.ps1).
- [`raster_to_pixel_svg.ps1`](../../../tools/design/raster_to_pixel_svg.ps1).
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
| [`08-imagegen-cell-fill-retry.png`](./08-imagegen-cell-fill-retry.png) | Second ImageGen result using a separate complete-cell-fill behavior reference |
| [`08-imagegen-cell-fill-retry-512.png`](./08-imagegen-cell-fill-retry-512.png) | Second result normalized to the template dimensions |
| [`09-cell-fill-retry-32.png`](./09-cell-fill-retry-32.png) | Second result snapped to exactly one palette color per logical cell |
| [`09-cell-fill-retry-32-16x.png`](./09-cell-fill-retry-32-16x.png) | Snapped second result at inspection scale |
| [`10-cell-fill-retry-32.svg`](./10-cell-fill-retry-32.svg) | Automatic editable SVG from the snapped second result |
| [`10-cell-fill-retry-32.png`](./10-cell-fill-retry-32.png) | Native raster round-tripped from the automatic SVG |
| [`11-cell-fill-retry-grid-proof.png`](./11-cell-fill-retry-grid-proof.png) | Snapped second result placed back on the input grid |
| [`11a-old-sampled-grid-proof.png`](./11a-old-sampled-grid-proof.png) | First result's snapped reconstruction for comparison |
| [`12-cell-fill-comparison.png`](./12-cell-fill-comparison.png) | First generation, cell-aware retry, and deterministic snapped output |
| [`13-grid-64x64.png`](./13-grid-64x64.png) | Scripted white `512 x 512` canvas; `64 x 64` logical cells; 8px per cell |
| [`13-cell-fill-method-64-sprite.png`](./13-cell-fill-method-64-sprite.png) | Native helper raster used to build the density-matched behavior reference |
| [`13-cell-fill-method-64.png`](./13-cell-fill-method-64.png) | Separate whole-cell behavior reference at the `64 x 64` density |
| [`14-imagegen-ship-64.png`](./14-imagegen-ship-64.png) | Unmodified built-in ImageGen output from the `64 x 64` test |
| [`14-imagegen-ship-64-512.png`](./14-imagegen-ship-64-512.png) | `64 x 64` test normalized to the template dimensions |
| [`15-snapped-ship-64.png`](./15-snapped-ship-64.png) | Palette-snapped native `64 x 64` raster |
| [`15-snapped-ship-64-8x.png`](./15-snapped-ship-64-8x.png) | Nearest-neighbor inspection preview |
| [`16-snapped-ship-64.svg`](./16-snapped-ship-64.svg) | Editable integer-coordinate SVG with 604 horizontal color runs |
| [`16-snapped-ship-64.png`](./16-snapped-ship-64.png) | Nearest-neighbor SVG render used for visual inspection |
| [`17-grid-overlay-proof-64.png`](./17-grid-overlay-proof-64.png) | Snapped `64 x 64` result placed back on its input grid |
| [`18-32-vs-64-comparison.png`](./18-32-vs-64-comparison.png) | Strict `32 x 32`, raw `64 x 64`, and strict `64 x 64` results at equal display size |

## First ImageGen Prompt

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

This prompt failed the strict cell-fill requirement. It preserved the grid and
roughly followed it, but it drew a shaded illustration over the graph rather
than assigning one flat color to every occupied cell.

## Cell-Fill Retry Prompt

The second built-in call received two inputs:

- `01-grid-32x32.png` as the blank edit target;
- `06-grid-overlay-proof.png` only as a complete-cell-fill behavior example.

The critical instruction was:

> Treat this like coloring spreadsheet cells, not drawing over graph paper.
> Every occupied logical cell is filled completely from grid line to grid line
> with exactly one solid palette color. Every empty cell stays white. Never
> place an edge, line, highlight, shadow, or color boundary inside a cell.

## 64-Cell Density Test

The third built-in call used:

- `13-grid-64x64.png` as the blank edit target;
- `13-cell-fill-method-64.png` only as a whole-cell behavior reference.

It requested one centered top-down drydock interceptor within columns 12–51
and rows 6–57. Details had to occupy at least `2 x 2` logical cells, and the
same restrained ship palette was used. The prompt explicitly prohibited
within-cell shading, antialiasing, continuous outlines, texture, and glow.

The raw generation is visibly closer to a usable craft concept than the
`32 x 32` attempt. The higher density preserves a stepped silhouette while
making the cockpit, cannon socket, swept wings, and twin engine housings
separately legible. It still introduces subtle value changes inside some cells,
so it remains concept input rather than a runtime asset.

## Findings

### The first generation was not pixel art

The first generated craft was centered and faced upward, but those qualities do
not satisfy the pixel-art contract. It:

- crossed logical cell boundaries with contours and highlights;
- contained gradients and different values inside the same cell;
- used the grid as graph paper behind an illustration;
- therefore required reconstruction before any pixel claim was valid.

The model still returned `1254 x 1254`, not the input's exact dimensions, and
introduced soft shading inside cells. My earlier statement that the generation
had already used whole-cell fills was incorrect.

### A complete-cell behavior reference materially improved the retry

The retry visibly assigns its silhouette and major color regions by whole cells.
It is much closer to a grid-native source, but it still contains subtle
within-cell value changes.

Distance from each normalized generation to its own strict cell-snapped
reconstruction was measured as mean grayscale difference:

| Generation | Difference |
| --- | ---: |
| First grid-only prompt | `0.0428108` |
| Retry with cell-fill behavior reference | `0.0146254` |
| `64 x 64` test with density-matched behavior reference | `0.0228101` |

The retry reduced the difference by about 66%, but did not reach zero. ImageGen
can be guided toward filled cells; it cannot be trusted to enforce them.
The `64 x 64` score is not directly a quality ranking against `32 x 32`: its
smaller cells expose more generated sub-cell shading. Its strict reconstruction
is nevertheless much more descriptive at the same display size.

### Grid snapping performs the actual pixel conversion

`snap_image_to_pixel_grid.ps1` normalizes the generated square to `512 x 512`
and samples one center point per 16px cell. It then maps that sample to the
approved palette and produces a `32 x 32` logical raster. This operation:

- removed the grid lines;
- removed within-cell antialiasing and gradients;
- retained the generated silhouette;
- made every logical cell exactly one palette color or transparency.

This is more deterministic than resizing an ungridded generated image and
calling the result pixel art.

### Automatic SVG conversion remains editable

`raster_to_pixel_svg.ps1` omits transparent pixels and merges adjacent
same-color pixels into horizontal `<rect>` runs. The first automatic result
contains 139 runs and the retry contains 137 runs in a `32 x 32` integer view
box. Every visual pixel can be changed by editing an integer coordinate, width,
or fill.

The `64 x 64` conversion contains 604 horizontal color runs and round-trips to
the snapped raster with a maximum pixel difference of zero. Its automatic
reconstruction uses six palette colors plus transparency. A symmetry audit
found only two mismatched center-axis pixels, both in one cockpit row; that is
small, explicit cleanup rather than a silhouette rebuild.

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
- No raw ImageGen result qualifies as a runtime pixel asset.
- `32 x 32` is too coarse for the intended player craft. `64 x 64` is the
  preferred authoring density for the next player-craft proof, subject to a
  gameplay-scale composite and animation test.
- One upward-facing frame does not prove 16-direction consistency.
- Weapon recoil, engine animation, dash, damage, and upgrade overlays remain
  separate future tests.
- The live Godot project has not imported or rendered this craft.

## Decision

Use a scripted, blank `512 x 512` coordinate grid for each individual ImageGen
asset and provide a separate complete-cell-fill behavior reference. Treat the
generated bitmap as a concept only. Normalize it to the template, force every
logical cell to one palette color with `snap_image_to_pixel_grid.ps1`, convert
the native raster to integer-grid SVG, and then perform direct symmetry and
functional-layer edits. Do not call the raw generated bitmap pixel art, and do
not use a multi-slot semantic sheet as the generation template.

Use `64 x 64` logical cells for the next player-craft concept. Keep `32 x 32`
available for simpler enemies, towers, mines, pickups, and props whose roles do
not need the player's cockpit, weapon, and engine separation.
