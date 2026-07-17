---
type: evidence
status: active
owner: BK
created: 2026-07-15
last_reviewed: 2026-07-17
topic: Selected UI shell backdrops and panel image-generation references
scope: Main Menu, Settings, Hero Preparation, Forge, Run Result, and reusable panel references
source: Owner-approved art direction, retired production UI layouts, and built-in image generation
related:
  - ../../UI_VISUAL_SYSTEM.md
  - ../README.md
---

# UI Shell Image References

## Purpose

Keep the accepted visual anchor, selected shell-backdrop sources, and generated
panel-family references together. Reference files remain outside Godot import;
selected backgrounds have retained copies in the production asset tree.

## Sources

- `owner-reference-lower-ruins.png`: primary owner-selected theme and structural mood reference.
- `../visual-style-slate-cutout.png`: supporting simplification reference for broad flat masses and restrained detail.
- The retired shell layouts remain evidence for each candidate's quiet UI
  occupancy zone; they do not define the new screen flow.

## Candidate Set

| File | Role | Composition contract |
| --- | --- | --- |
| `background-main-menu-v01.png` | Main Menu backdrop | Dark quiet left field; architectural opening and depth concentrated on the right. |
| `background-settings-v01.png` | Settings shell backdrop | Perimeter-weighted archive/control chamber; calm center for the large settings panel. |
| `background-preparation-v01.png` | Hero Preparation backdrop | Subdued armory hall with detail confined to extreme edges and upper band. |
| `background-forge-v01.png` | Forge backdrop | Ancient workshop with restrained amber heat at the perimeter and a quiet work surface. |
| `background-run-result-v01.png` | Run Result backdrop | Monumental crown gate with a low-contrast central result zone and edge framing. |
| `panel-shell-reference-v01.png` | Panel direction sheet | Large settings slab, pause slab, compact confirmation, and header/banner silhouettes. |
| `panel-choice-reference-v01.png` | Panel direction sheet | Choice card, detail surface, result summary, receipt band, and action-band silhouettes. |
| `ui-shell-candidates-contact-sheet.png` | Review board | One-page comparison of the seven generated candidates. |

## Retained Production Copies

The owner selected all five screen backgrounds for production consideration on
2026-07-15. Their copies remain available below; no current runtime scene consumes
them after the isometric pivot reset. Source files remain provenance and
comparison evidence.

| Selected source | Production copy |
| --- | --- |
| `background-main-menu-v01.png` | `art/ui/production/backgrounds/main_menu.png` |
| `background-settings-v01.png` | `art/ui/production/backgrounds/settings.png` |
| `background-preparation-v01.png` | `art/ui/production/backgrounds/hero_preparation.png` |
| `background-forge-v01.png` | `art/ui/production/backgrounds/forge.png` |
| `background-run-result-v01.png` | `art/ui/production/backgrounds/run_result.png` |

The prior runtime used four copies as full-screen shell imagery and retained Forge
for a contextual slot. That adoption was deleted with the platformer runtime. The
panel sheets were never promoted. Future screens must keep panels, labels, focus,
interaction, and state live in Godot controls.

## Shared Generation Contract

- Use case: `stylized-concept`.
- Style: outline-free flat-color digital illustration, large clean polygonal masses, three to five depth planes, sparse broad lighting.
- Theme: drowned ancient industrial ruins, monolithic stone, restrained oxidized metal, monumental shafts and arches, sparse moss, pale cyan distance light.
- Palette: charcoal and deep navy base; verdigris teal secondary; moss, mustard amber, warm off-white, and controlled coral/violet only as small semantic accents.
- Avoid: pointillism, speckle, hatching, repeated micro-patterns, dense cracks, stains, brush noise, photorealism, painterly daubs, text, logos, HUD, buttons, characters, enemies, gameplay hazards, and watermarks.
- Backdrops reserve a low-contrast occupancy zone for live UI and contain no baked UI element.
- Panel sheets contain no labels, icons, data, focus state, shadow stack, or decorative border. They are shape references for later SVG/NinePatch/Theme work.

## Generation Record

- Generator path: built-in image generation, one call per distinct asset.
- Sequence: Main Menu was generated from the owner reference; the remaining backgrounds used Main Menu as the style-family anchor; the second panel sheet used the first panel sheet as its shape-family anchor.
- Prompt set: the shared contract above plus each asset's composition contract in the candidate table. No runtime-output or transparency mode was requested.
- Retained generator sources:
  - Main Menu: `exec-9c3a2525-3920-4350-8666-f6aa7763ca09.png`;
  - Settings: `exec-70d43f5f-7255-44c7-bae9-6cdb0376383f.png`;
  - Hero Preparation: `exec-f43e5905-59c4-4b2d-baad-d7b69c9d03fe.png`;
  - Forge: `exec-b2d03524-6291-402f-922c-f92409aceae8.png`;
  - Run Result: `exec-e6ea9170-5198-4843-aedf-5e1b84928eb1.png`;
  - shell panels: `exec-84fd357e-649c-41cc-878d-590e87ff8ded.png`;
  - choice panels: `exec-56eecc24-7c0e-4ddf-bbde-422a4fcb9a62.png`.

## Findings

- All five backdrop candidates are `1672x941` 16:9 images, contain no baked text or UI, and preserve the required screen-specific quiet zones.
- The two panel sheets contain only related dark-navy silhouettes on a neutral review canvas. Their slight generated tonal variation is reference material, not a production texture treatment.
- The retained files test whether one simplified art family can cover multiple shell screens while preserving the separation between bitmap backdrops and live UI panels.
- All five background sources remain separate production copies; none is currently connected, and the two panel sheets remain non-runtime references.

## Limitations

- Image-generation output is not evidence of exact crop safety, stretch margins, alpha, or production filtering.
- Panel candidates require deterministic reconstruction before implementation.
- Production background replacement should preserve the existing screen-safe compositions or repeat the three-viewport visual QA pass.
- These shell references do not define isometric room, actor, occluder, or combat-telegraph production.
