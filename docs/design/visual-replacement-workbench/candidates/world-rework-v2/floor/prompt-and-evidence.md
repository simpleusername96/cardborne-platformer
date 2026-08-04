---
type: evidence
status: active
owner: BK
created: 2026-08-04
last_reviewed: 2026-08-04
canonical_for: Floor tile candidate v2 generation provenance
---

# Floor Tile Candidate v2

Status: review candidate only. It is not approved, integrated, or mapped to a runtime asset.

## Authority preflight

- Read: `.agents/skills/cardborne-visual-authority/SKILL.md`
- Read: `docs/design/VISUAL_SYSTEM.md`
- Inspected at original detail: `docs/design/cardborne-universal-art-style-reference.png`
- Canonical sheet SHA-256 (expected and observed): `96CCF5D053E66DD3A102CCDF39DAEFD0B0C54B0E88D20428B7BA1C894F002889`
- The sheet was supplied to ImageGen as the sole reference input. It informed style grammar only, not asset approval or object/layout reproduction.

## Generation prompt

> Use case: stylized-concept. Generate exactly one seamless full-bleed square top-down gameplay floor tile, style grammar only from the supplied Cardborne sheet; do not recreate its sample map tile. The canvas should look almost like a quiet matte deep-slate-blue (`#182431`) painted industrial floor. Strictly no border or perimeter design: all four edges must be the same uninterrupted base surface so copied tiles meet invisibly. Permit ONE single subtle thin straight vertical functional service seam through the exact center, from top edge to bottom edge, with no corner turn, no branches, no panels; it must continue cleanly into repeated copies. No other seam, no frame, no bevel, no shadow, no glow, no gradient, no texture/noise/grain, no rivets/dots/greebles/lights, no text, no objects, no transparent pixels. Maintain a simple hard-edge general-SF matte plane suitable behind actors.

The first generated source was rejected because it had four perimeter-like corner seams. The retained source is the second generation, which has only the central vertical seam.

## Files and hashes

| File | Purpose | SHA-256 |
| --- | --- | --- |
| `source/floor-tile-imagegen-source.png` | Retained ImageGen source (1254 x 1254) | `629AEF5D6048327F0FC95128EF504685BE0A5DBBF5AA4BD4FC806683763DC62A` |
| `build/rejected-world-rework-v2/floor/floor-tile-candidate-v1.png` | Rejected first normalization, retained outside the active review set | `A3B844CA89FCC7894D929FDE1AE09F4564BA2DAAA5EB272DA95EBF44040B2E6E` |
| `build/rejected-world-rework-v2/floor/floor-tile-repeat-preview-v1.png` | Rejected repeat preview, retained outside the active review set | `FBB1924B7B21BDE9873F31EA9FAB9BDD216DD32DD50D5C73EDC38FA98E53E560` |

## Raster and visual evidence

- Candidate mode: RGBA; exact dimensions: 288 x 288.
- Alpha range: 255 to 255; all four corner alpha values: 255. The candidate is fully opaque and full-bleed, with no chroma key or transparent fringe.
- Original-size inspection: one low-contrast straight central service seam only; no border, bevel, ornament, object, text, or incidental detail found.
- 3 x 3 repeat inspection: adjacent copies meet as an uninterrupted matte surface. The central seam repeats at the deliberate 288 px interval; no empty edge or frame gap is present.

## Review limitation

This proves candidate geometry and visual intent only. Runtime stretching and gameplay contrast have not been tested, and promotion requires the separate visual-switch workflow.

## Active review candidate

Status: review candidate only. It is not approved, integrated, or mapped to a runtime asset. It supersedes v1 for review because it removes the generated tonal gradient.

### Flattening contract

- Canvas: exact 288 x 288 RGBA.
- Palette: two opaque RGB colors total: matte base `(24, 36, 49)` and the central functional seam `(45, 59, 70)`.
- Geometry: the seam occupies columns 143 and 144 from top to bottom. There is no light plane, shadow plane, gradient, banding, border, or perimeter treatment.
- Edge verification: top-to-bottom max per-channel delta `0`; left-to-right max per-channel delta `0`.
- Alpha verification: range `255` to `255`; all four corners are `(24, 36, 49, 255)`.

### v2 files and hashes

| File | Purpose | SHA-256 |
| --- | --- | --- |
| `floor-tile-candidate-v2.png` | Flattened exact review candidate (288 x 288) | `26B560239AA5FB0210A27FAE70C45E9B8157BA10D3CE404FA58FC020F4DF3030` |
| `floor-tile-repeat-preview-v2.png` | 3 x 3 non-runtime repeat inspection | `9BF29C58A66B690D54550926991D51B7AFFBB349330620647BB2BEAAE22A8E4D` |

### v2 inspection

- Original-size inspection confirms a flat, two-color surface and a single deliberate vertical seam.
- The 3 x 3 preview has no border, alpha gap, horizontal edge mismatch, or vertical edge mismatch. Repeated seams remain the intentional 288 px functional rhythm.
