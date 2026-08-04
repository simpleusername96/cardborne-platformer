---
type: evidence
status: draft
owner: Codex
created: 2026-08-04
scope: World service rail replacement candidate only
---

# World Service Rail Candidate Evidence

## Authority preflight

- Text authority: `docs/design/VISUAL_SYSTEM.md`, read completely on 2026-08-04.
- Visual authority: `docs/design/cardborne-universal-art-style-reference.png`, inspected at original detail.
- Expected and observed visual-reference SHA-256: `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- The canonical sheet was supplied to the built-in ImageGen tool through `referenced_image_paths` as an actual image reference.
- The sheet supplied style grammar only. No depicted object, silhouette, glyph, tile, facility, UI shell, text, or layout was reused.
- Candidate status: review candidate only; not approved and not promoted to production.

## Task contract

The rail is a continuous structural guide embedded in the field floor. It must remain readable when horizontally stretched or rotated without becoming a wall, facility, pipe, or gameplay cue.

- Canvas: exact `288 x 48` pixels.
- Alpha: none; fully opaque.
- Palette: exactly three opaque RGB colors: `#070B11`, `#243445`, and `#58BFEA`.
- Construction: one dark structural strip and one restrained cyan functional lane.
- Tiling: full bleed at both horizontal edges; the first and last pixel columns must match exactly.
- Exclusions: gradients, chromatic fringe, glow, shadow, bevel, end caps, dots, lamps, seams, rivets, arrows, symbols, and microdetail.

## Generation and normalization

Built-in ImageGen generated `imagegen-source.png` with the canonical sheet supplied as the actual referenced image. The prompt requested one top-down, edge-to-edge service rail with exactly three flat colors and the exclusions above. The generated source was then deterministically normalized into `service_rail_288x48.png` by sampling one uninterrupted vertical cross-section, scaling it across the exact canvas, and remapping it without dithering to the three semantic colors. This removes model-added gradients and guarantees a repeatable horizontal cross-section while retaining the generated rail's broad-mass construction.

## Validation evidence

| File | Purpose | SHA-256 |
| --- | --- | --- |
| `imagegen-source.png` | Referenced ImageGen source | `055f6201f2534cf4d02ceb8cb0bcd7f49b2d5f1394f6b2287ee77fb3168c32f5` |
| `service_rail_288x48.png` | Exact candidate | `eb92f42c8b1e03fbaa99ad213a73a0d4a8b21e459f8971cbbb4ccbc049cb736e` |
| `preview-repeated-horizontal.png` | Four-copy horizontal seam check | `27545c2a1ea0f40fc6d0da916c8d5305ffe29b3d0fa408310c91b12d6f2deae4` |
| `preview-rotated-elongated.png` | Rotation and non-uniform stretch check | `d72bddc3075ee6cf0e059dc0089c7fd2f9cce7ac53ddc29e19c5cc649ba9fb0e` |

- Candidate geometry: `288 x 48`.
- Candidate channel declaration: `sRGB`, three channels, no alpha.
- Unique opaque RGB colors: `3`.
- First/last column maximum normalized per-channel delta: `0`.
- Visual inspection: the repeated preview has no seam; the elongated rotated preview preserves a single uninterrupted cyan lane and broad dark structure.

## Exact ImageGen prompt

```text
Use case: stylized-concept
Asset type: source artwork for one top-down sci-fi game world service rail texture
Input images: Image 1 is Cardborne's canonical style-reference sheet. Use it only for broad flat plane grammar, restrained contrast, sparse functional detail, and hard-edge treatment. Do not reproduce, crop, trace, or copy any object, silhouette, glyph, tile, facility, UI shell, text, or layout from the sheet.
Primary request: Create one perfectly straight, very wide horizontal service rail strip viewed exactly top-down. It must read as a continuous structural guide embedded in a floor, not as a wall, pipe, platform, road, or UI element.
Composition/framing: one long strip spanning completely from the left image edge to the right image edge, centered vertically, orthographic, no perspective. The strip should be easy to crop to an extreme 6:1 texture.
Style/medium: clean authored raster game asset with broad matte flat shapes and antialiased hard edges.
Color palette: exactly three flat colors only: near-black outer structural strip, dark blue-gray main strip, one restrained cyan functional lane. No additional shades.
Constraints: fully opaque; full bleed to both left and right edges; left and right cross-sections identical; one cyan lane only; no end caps; no isolated objects; no background transparency; no text; no watermark.
Avoid: gradients, lighting falloff, shadow, glow, bloom, texture, noise, dither, bevel, highlights, dots, lamps, seams, rivets, panel lines, arrows, chevrons, symbols, borders within borders, microdetail, chromatic fringe, perspective, diagonal orientation.
```
