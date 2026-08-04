# Structural Wall Candidate Evidence

Status: candidate only; not approved or connected to runtime.

## Authority preflight

- Read `docs/design/VISUAL_SYSTEM.md` completely before generation.
- Inspected `docs/design/cardborne-universal-art-style-reference.png` at original detail.
- Required and observed sheet SHA-256: `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- The canonical sheet was supplied to built-in ImageGen as an actual referenced image at `referenced_image_paths`; it supplied style grammar only and was not copied.

## Deliverables

| File | Role | SHA-256 |
| --- | --- | --- |
| `wall_segment_source.png` | Original built-in ImageGen output | `38543e4fe74eeacec37ea2c70fc62a7bbd0b779f6ab1611bb03e763d2418b554` |
| `build/rejected-world-rework-v2/wall/wall_segment_192x96_candidate.png` | Rejected first normalization, retained outside the active review set | `6619bcd1b5e3592e065d2a095c93c7994bc146c75104825d5d3f474e774658b8` |

The normalized candidate is 192x96 RGBA. It is intentionally fully opaque:
the structural wall is a continuous world mass, not a cutout sprite. Its alpha
range is `255..255`, so the four corners and both horizontal repeat edges carry
solid pixels rather than chroma-key remnants.

The exact candidate check reported `18432/18432` opaque pixels. The maximum
per-channel left-edge/right-edge difference is `3` on the normalized image;
there is no transparent cap gap, but the slight generated color difference is
another reason this remains a review candidate rather than a promotion.

## Generation prompt

```text
Use case: stylized-concept
Asset type: a single repeatable top-down structural wall texture candidate for a 2D game.
Input image: Image 1 is style grammar only. Do not copy any depicted object, wall, facility, layout, or silhouette.
Primary request: Create one horizontal pale-metal structural wall segment, exact 2:1 aspect ratio, intended to be normalized to 192 by 96 pixels. It must occupy the entire canvas from left edge to right edge and touch both edges with no end caps or empty gaps, so it can repeat or stretch horizontally without seams. Continuous long structural mass, clearly brighter than the dark floor. Use only 3 or 4 large matte planes: broad pale gray-blue central structural mass, one darker lower hard shadow plane, one restrained lighter upper hard plane, one near-black outer contour. Keep the horizontal continuation visually identical at the left and right edges.
Style/medium: clean top-down flat-color industrial general SF. Anti-aliased hard edges, sparse, readable at small size.
Composition/framing: full-bleed wall strip filling the entire horizontal canvas. No background visible; no text, no labels.
Color palette: pale cool metal using #7A8795 and #AAB6C2, dark structural plane #354454, near-black outline #070B11. No semantic accent color.
Constraints: no white UI-button appearance, no nested border, bevel, glow, gradient, texture noise, dots, lamps, rivets, seams, panels, greeble, scratches, decorative corners, end caps, holes, or repeated modules. The reference is style grammar only, never an asset to reproduce.
```

## Inspection notes

- At intended 192x96 size, the candidate reads as a continuous pale-metal wall
  and is materially brighter than the normal dark floor.
- The left and right edges are full-bleed, with no transparent gap or end-cap.
- It uses a near-dark outer contour and three broad planes only.
- The generated source still has mild tonal falloff across its broad planes.
  This is less flat than the strictest matte interpretation; retain this as an
  unapproved comparison candidate until the final wall family review.

## V2 flat-color revision

`wall_segment_192x96_candidate_v2.png` is a targeted post-process of the
candidate silhouette, not a new production asset. It maps every pixel to exactly
four opaque colors and then makes the right edge identical to the left edge:

| Plane | RGB |
| --- | --- |
| dark perimeter / separation | `7, 11, 17` |
| dark lower plane | `79, 91, 106` |
| pale main mass | `145, 155, 167` |
| restrained hard light plane | `190, 196, 204` |

| File | Role | SHA-256 |
| --- | --- | --- |
| `wall_segment_192x96_candidate_v2.png` | Four-color exact 192x96 revision | `3e14f4d5505ac5bf22927c92eb1823baa637198a4c978a5b496356d4f6c98f38` |
| `wall_segment_repeat_x5_v2.png` | Five-segment horizontal repeat preview | `ee2886a594bf5398b512d823e5e49d6010650b03f748df8f976c067fd6c5beb1` |

V2 is `192x96` RGBA with `18432/18432` opaque pixels and exactly four unique
RGBA values. Its left/right repeat-edge maximum per-channel difference is `0`
(within the required `<=1`). The five-segment preview was visually inspected:
the wall remains a continuous pale-metal mass with no cap gap, white button-like
interior, smooth falloff, banding, texture, noise, nested border, or microdetail.
