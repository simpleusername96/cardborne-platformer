---
type: evidence
status: active
owner: BK
created: 2026-07-27
last_reviewed: 2026-07-27
scope: A bounded six-category proof of the Cardborne pixel-asset production pipeline
related:
  - ../../../execplans/2026-07-27-pixel-asset-production-and-integration.md
  - ../../README.md
  - ../../design/visual-research/PART_GUIDELINES.md
---

# Pixel-Asset Pipeline Sampler

## Purpose

Demonstrate the planned production path without executing the complete
forty-family migration.

The sampler contains one representative asset from each of six different
categories:

| ID | Category | Native size | Method |
| --- | --- | ---: | --- |
| `player-interceptor` | player craft | `64x64` | ImageGen-assisted canonical base |
| `shooter-drone` | mobile enemy | `32x32` | ImageGen-assisted canonical base |
| `thermal-heavy-shot` | hostile projectile | `32x32` | ImageGen-assisted canonical base |
| `repair-fixture` | facility | `64x64` | ImageGen-assisted canonical base |
| `wall-corner-tile` | connected world tile | `24x24` | deterministic direct pixel |
| `repair-pickup` | field pickup | `24x24` | deterministic direct pixel |

## Pipeline

1. Create an integral logical-grid guide.
2. Produce one object on its own guide.
3. Snap to the declared logical grid and approved display palette.
4. Correct the native silhouette and transparent background.
5. Assign every visible pixel to one semantic mask color.
6. Split into same-origin semantic layers.
7. Reassemble with zero changed pixels.
8. Review at native scale, enlarged nearest-neighbor scale, in silhouette,
   grayscale, and over Cardborne world colors.
9. Assemble the six independently produced assets into one comparison sheet.

No generated full scene, unrelated generated sheet, runtime integration, or
gameplay change belongs to this sampler.

## Acceptance

- [x] Each asset reads at native `1x`.
- [x] Player, hostile, support, wall, pickup, and projectile ownership remain
      distinct in grayscale and over permitted world colors.
- [x] Every occupied source pixel belongs to one semantic layer.
- [x] Exact semantic reassembly changes zero pixels.
- [x] The wall tile repeats without a one-pixel break at connected edges.
- [x] The projectile has a visible leading head and non-damaging rear wake.
- [x] The facility does not bake its gameplay radius or timer into the bitmap.
- [x] The pickup cannot be mistaken for a projectile or floor marking.

## Outputs

- [`review/pipeline-sampler-overview.png`](./review/pipeline-sampler-overview.png)
  compares the six independently produced final previews.
- `review/*-pipeline-review.png` shows, in order, the native master, semantic
  mask, exact reassembly, silhouette, and grayscale result.
- `native/` contains the approved logical-size masters.
- `masks/` contains the same-size semantic masks.
- `build/<id>/layers/` contains same-origin PNG and editable pixel-SVG layers.
- Every `build/<id>/semantic-build.json` records
  `reassembly_pixel_difference: 0`.
- `final/` contains the six Creative Production board previews.
- `prompts/` records the exact four ImageGen prompts. The tile and pickup are
  authored directly by `build-sampler.ps1`.

## Result and Boundary

This sampler proves the production mechanics, not the complete art direction
or runtime migration.

- The ImageGen outputs were treated as soft canonical drafts. Their visible
  guide, soft tones, and off-palette values were removed by native grid
  sampling and deterministic palette mapping.
- The disconnected one-cell thermal wake in the generated source was repaired
  at native resolution before semantic masking.
- The wall and pickup demonstrate the direct-pixel route for topology-critical
  or very small assets.
- The semantic masks are deliberately simple and expose how a future direction,
  state, or upgrade can edit one part without regenerating the whole object.
- Only one direction/state exists for each sample. No sample is approved as the
  final production family, and none is connected to Godot.
- `wall_corner_tile` is one connection proof, not the required sixteen-tile
  production wall family.

Rebuild the evidence from the repository root:

```powershell
.\.agents\evidence\pixel-art\pipeline-sampler\build-sampler.ps1
```
