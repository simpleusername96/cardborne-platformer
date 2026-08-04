---
type: evidence
status: active
owner: Codex
created: 2026-08-04
scope: Repair and overdrive support-pad alpha-edge candidates only
---

# Support Pad Alpha-Edge Repair Evidence

## Authority and scope

- Text authority: `docs/design/VISUAL_SYSTEM.md`, read completely.
- Visual authority: `docs/design/cardborne-universal-art-style-reference.png`, inspected at original detail.
- Expected and observed authority-sheet SHA-256: `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- For each edit, the target PNG and canonical sheet were both supplied to the built-in ImageGen tool through `referenced_image_paths` as actual image references.
- The target image controlled composition, glyph, proportions, and color role. The sheet supplied style grammar only; no depicted object or layout was reused.
- The two final edge-clean rasters were applied to their existing production asset IDs on 2026-08-04. No gameplay radius, effect, timing, or collision behavior changed.

## Preserved design contract

- Exact `192 x 192` RGBA canvas.
- Transparent exterior with four fully transparent corners.
- One complete circular pad and one glyph only.
- Repair: cyan/support fill, dark perimeter, one centered ivory plus.
- Overdrive: amber/player-reward fill, dark perimeter, one centered right-facing ivory chevron with its existing dark separation.
- No rings, dots, seams, lamps, texture, glow, shadows, bevel, or authored gradients.
- The change is limited to removing the contaminated, jagged outer alpha edge. The original glyph geometry and visual weight remain the composition source.

## Processing method

1. Each original production PNG was inspected at original detail.
2. Each target was edited independently with built-in ImageGen, with the target and canonical authority sheet supplied together.
3. ImageGen rendered each edit on a removable green chroma backdrop.
4. The installed `remove_chroma_key.py` helper produced an RGBA source with `--auto-key border --soft-matte --despill --transparent-threshold 12 --opaque-threshold 220 --edge-feather 0.25`.
5. The helper-produced clean circle alpha was normalized to the original `176 x 176` occupied bounds on the exact `192 x 192` canvas.
6. The original plus/chevron geometry was retained. Large color planes were remapped to the original dominant flat role colors; only antialias transition pixels remain between planes.
7. The reconstructed pad was clipped by the helper-produced alpha mask, reviewed at 1x, and then copied over the matching production PNG.

## Files and hashes

| File | Purpose | SHA-256 |
| --- | --- | --- |
| `repair-imagegen-chroma.png` | Repair ImageGen chroma source | `a451e88dfb3e197758feaeb4aea80814b90bcf510ba81375eff1791ec111b3a3` |
| `repair-imagegen-alpha.png` | Repair helper RGBA source | `536edc544fc516d18f5a60f625dd78ef2083e3addfb21afcf87ab1629f427be8` |
| `facility_repair_pad_edge_clean.png` | Final repair-pad candidate | `c6b915a9cee54b1798958daaea2b4636414b87f81ec8bf69a23668303c2bbc5f` |
| `overdrive-imagegen-chroma.png` | Overdrive ImageGen chroma source | `fa4e642f571321f48a3be8a47238d7dc1777c0dfa5db98d310ecf213b2c12f31` |
| `overdrive-imagegen-alpha.png` | Overdrive helper RGBA source | `d15bc8d94c9acd677f7368140b244bd33428b5e06e398687e83b66a10c5e9941` |
| `facility_overdrive_pad_edge_clean.png` | Final overdrive-pad candidate | `330b159fc6ec54167a8a596a223c11812eb5dea85754c1256f10a845cb651a94` |
| `support_pads_as_is_to_be.png` | AS-IS repair, candidate repair, AS-IS overdrive, candidate overdrive at 1x | `b152d157194cb593e574dc63100ad2f3432af635ffebcca62cc770d9c08bac8a` |
| `support_pads_runtime_1x.png` | Both candidates at exact canvas size | `8665e88a1e8175610298d00c02149ff6dfd9d8a8af6e6dc5a5d5195654766079` |

Original source hashes:

- `facility_repair_pad.png`: `5da0a8f5b67469ae8ab51e7fef7d4c711f2ccacb62425adac90348b5a0db0bcc`
- `facility_overdrive_pad.png`: `0fa1f3653af4cd7e87d5b5cdc84132d8b591ec8fd7ca3a7b30d13f7e12163be1`

## Mechanical validation

| Check | Repair | Overdrive |
| --- | ---: | ---: |
| Dimensions | `192 x 192` | `192 x 192` |
| Nonzero-alpha bounds | `(8,8)-(184,184)` | `(8,8)-(184,184)` |
| Corner alpha values | `0,0,0,0` | `0,0,0,0` |
| Fully transparent pixels | `12058` | `12021` |
| Partially transparent pixels | `1444` | `1452` |
| Chroma-fringe pixels | `0` | `0` |
| Exact `#00ff00` pixels with alpha | `0` | `0` |

Both candidates and both 1x previews were visually inspected. The plus and chevron remain centered and readable, the exterior is transparent, and the green fringe present in the AS-IS assets is absent.

## Exact prompts

### Repair pad

```text
Use case: background-extraction
Asset type: edit source for a top-down game repair floor pad
Input images: Image 1 is the exact edit target. Image 2 is Cardborne's canonical style sheet, used only for broad flat-plane grammar and clean hard-edge treatment; do not reproduce any object or layout from it.
Primary request: Preserve Image 1's design exactly: one complete circular cyan/support pad, one dark perimeter, and one large centered ivory plus glyph. Change only the polluted, jagged outer alpha edge by recreating it as a clean antialiased circle.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for later removal.
Composition/framing: exact centered front-facing circle, orthographic top-down, generous equal padding, no crop.
Color palette: preserve Image 1's cyan support fill, dark perimeter, and ivory plus. Do not introduce new colors inside the subject.
Constraints: exactly one circle and one plus glyph; preserve proportions, glyph placement, flat fill, and visual weight; crisp clean antialiasing; background must be one uniform #00ff00 with no variation; do not use #00ff00 in the subject.
Avoid: any redesign, gradients, glow, shadow, rings, dots, seams, texture, bevel, highlight, extra outline, microdetail, text, watermark, cast shadow, contact shadow, reflection.
```

### Overdrive pad

```text
Use case: background-extraction
Asset type: edit source for a top-down game overdrive floor pad
Input images: Image 1 is the exact edit target. Image 2 is Cardborne's canonical style sheet, used only for broad flat-plane grammar and clean hard-edge treatment; do not reproduce any object or layout from it.
Primary request: Preserve Image 1's design exactly: one complete circular amber/player-reward pad, one dark perimeter, and one large centered right-facing ivory chevron with its existing dark separation. Change only the polluted, jagged outer alpha edge by recreating it as a clean antialiased circle.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for later removal.
Composition/framing: exact centered front-facing circle, orthographic top-down, generous equal padding, no crop.
Color palette: preserve Image 1's amber player-reward fill, dark perimeter, ivory chevron, and dark chevron separation. Do not introduce new colors inside the subject.
Constraints: exactly one circle and one right-facing chevron glyph; preserve proportions, glyph placement, flat fill, and visual weight; crisp clean antialiasing; background must be one uniform #00ff00 with no variation; do not use #00ff00 in the subject.
Avoid: any redesign, gradients, glow, shadow, rings, dots, seams, texture, bevel, highlight, extra outline, microdetail, text, watermark, cast shadow, contact shadow, reflection.
```
