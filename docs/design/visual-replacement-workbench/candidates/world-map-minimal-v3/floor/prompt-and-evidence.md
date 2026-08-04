---
type: evidence
status: active
owner: BK
created: 2026-08-04
last_reviewed: 2026-08-04
canonical_for: Candidate-only correction provenance for world_surface_panel_9
---

# Minimal Floor Perimeter Repair

Status: applied to `world/surface_panel_9` on 2026-08-04. The approved AS-IS composition is unchanged; only the contaminated transparent perimeter was normalized.

## Authority and source inputs

- Read `.agents/skills/cardborne-visual-authority/SKILL.md` and `docs/design/VISUAL_SYSTEM.md` before generation.
- Inspected the production target at original detail: `art/visuals/production/gameplay/world/presentation/world_surface_panel_9.png`.
- Inspected the canonical style sheet at original detail: `docs/design/cardborne-universal-art-style-reference.png`.
- Canonical style sheet SHA-256: `96CCF5D053E66DD3A102CCDF39DAEFD0B0C54B0E88D20428B7BA1C894F002889`.
- ImageGen received both source images as actual referenced inputs. The style sheet supplied style grammar only, never asset approval or a layout/object source.

## ImageGen prompt

> Use case: stylized-concept. Flat-color raster repair of the FIRST input only. Preserve its exact existing composition: broad dark slate-blue center, one thin restrained cyan octagonal inset, and the same chamfered proportions. The SECOND input is only Cardborne style grammar; do not reproduce it. Fix only the jagged/contaminated transparent outer perimeter: use a fully opaque flat #101923 canvas all the way to every edge. Critical hard constraint: every color region must be perfectly flat solid color—NO gradient, shading, blur, soft light, vignette, texture, noise, anti-aliased outer silhouette, or banding. No transparency. No additional outlines, seams, panels, ornaments, lights, text, objects, rivets or dots. Keep the composition sparse and visually identical to the input apart from a clean opaque perimeter. Square floor texture intended for downscaling exactly to 288x288.

The generated edit remained smoothly shaded despite the flat-color constraint and was rejected. The retained v2 raster preserves the target's measured flat palette and broad/inset/chamfer composition, while normalizing only the outer perimeter to hard opaque color regions.

## Files and hashes

| File | Purpose | SHA-256 |
| --- | --- | --- |
| `source/world_surface_panel_9-asis.png` | Exact production target copy (288 x 288) | `02C1C4BEFD38237889E8BB01CD94AD8ED47ED7287CC004A9215B3024D9EAAB62` |
| `source/imagegen-edit-gradient-rejected.png` | Retained provenance source; rejected for smooth gradient | `371195EA0B4BB6B8D15711C16A5E2281FF8CADDA41729B5BA7ED373CA3593EAA` |
| `world_surface_panel_9-edge-corrected-v2.png` | Selected 288 x 288 opaque candidate | `B76DFEB2AF4D5D3ACEEEAAF542E276BBBF29D53F54236D5B5F052FC746B11B4B` |
| `world_surface_panel_9-edge-corrected-v2-repeat-3x3.png` | Non-runtime 3 x 3 repeat inspection | `131B012C55B3965C500A0FEB1BFE85228281AAD174BB02B0532AED83FF7BC142` |

## Candidate v2 validation

- Exact canvas and mode: 288 x 288 RGBA.
- Alpha range: `255..255`; all corners are opaque `#101923` (`16,25,35,255`). No chroma background was used or retained, so chroma-key removal was not applicable.
- Palette: four solid opaque colors only: outer canvas `#101923`, AS-IS perimeter `(36,49,70)`, AS-IS broad center `(37,50,71)`, and AS-IS cyan inset `(42,81,101)`.
- Chroma-fringe scan: zero green- or magenta-key-like pixels.
- Edge pairs: top-to-bottom maximum per-channel delta `0`; left-to-right maximum per-channel delta `0`.
- Original-size and 3 x 3 inspections: clean opaque outer canvas, a single restrained cyan inset, no random perimeter specks, no transparency, no new seam/detail, and no edge mismatch. Repetition retains the current panel rhythm; it does not attempt to alter runtime compiler gutters.

## Rejected outputs

- `world_surface_panel_9-edge-corrected-v1.png` and its preview retain the source's dark jagged perimeter after alpha compositing; do not promote.
- `source/imagegen-edit-gradient-rejected.png` is provenance only; do not promote.
