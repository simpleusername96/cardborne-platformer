# Cardborne Production UI Assets

The SVGs and raster images in this directory were created specifically for this
repository. They may be used, modified, recolored, and shipped with Cardborne
without an attribution requirement from that project-original asset set. The
separately identified Noto Sans KR font is the only third-party production UI
asset and ships under its included SIL Open Font License 1.1.

The files are deliberately monochrome white masks:

- tint icons and silhouettes with Godot `modulate` or a themed wrapper;
- keep labels, numbers, focus, hover, disabled state, and semantic feedback live;
- import at the largest expected display scale because Godot rasterizes SVGs at
  import time;
- keep backgrounds, terrain, characters, enemies, props, and detailed item art
  in the raster asset pipeline instead.

## Structural shapes

| Asset | Intended use |
| --- | --- |
| `shapes/panel_slab.svg` | Large preparation, forge, or result section |
| `shapes/panel_compact.svg` | HUD/status or compact detail section |
| `shapes/panel_card.svg` | Reward and selectable model card |
| `shapes/banner_objective.svg` | Stage title and objective strip |
| `shapes/button_plate.svg` | Primary, quiet, focused, and disabled buttons |
| `shapes/slot_plate.svg` | HUD action and equipment slots |

`button_plate.svg` is intentionally one asset. Interaction states should not be
separate textures; state is expressed by tint, an accent wedge, label, and focus
treatment.

## Icons

The icon set covers the retained product vocabulary: navigation, the six Traveler
loadout roles, forge materials and supplies, run rewards, and interaction. Every
icon uses a `64 x 64` view box and fill-only geometry so it remains readable from
approximately `24 px` through `64 px`.

See `docs/design/reports/ui-svg-asset-catalog.html` for the rendered catalog.

## Raster shell backgrounds

The five files under `backgrounds/` are production copies of the owner-selected
UI-shell candidates. They contain world atmosphere only; all panels, labels,
icons, focus, and interaction state remain live Godot controls.

| Asset | Intended role |
| --- | --- |
| `backgrounds/main_menu.png` | Main Menu establishing view |
| `backgrounds/settings.png` | Shell-only Settings view; in-run Settings keeps the live stage |
| `backgrounds/hero_preparation.png` | Hero Preparation armory view |
| `backgrounds/forge.png` | Contextual Forge artwork retained for a later measured slot; not a full-screen in-run backdrop |
| `backgrounds/run_result.png` | Run Result gate view |

No current runtime scene consumes these images after the isometric pivot reset.
Future shell screens may reuse them with aspect-preserving cover behavior. Do not
stretch these files, tile them, or bake screen controls into replacements.
Source references and generation provenance remain under
`docs/design/references/ui-shell/`.

## Raster UI illustrations

The first non-background raster pack lives under `illustrations/` and contains
19 independent `512 x 512` RGBA PNGs:

- one Traveler portrait;
- eight active equipment-model illustrations;
- two Spirit Stones and one small potion;
- five active-card vignettes;
- one Slime King portrait and one large Boss Core reward illustration.

These images carry internal color, material, pose, and expressive identity that
would become brittle or noisy as monochrome SVG. They are neutral-state art:
selection, rarity, quantity, condition, cooldown, lock, disabled, and focus stay
live in Godot. Card files contain no card frame or text.

Use the SVG role icons as stable fallbacks and for small semantic counters. In
particular, `icon_boss_core.svg` remains the small counter while
`illustrations/rewards/boss_core.png` is reserved for a large reward view.

The complete ID, display-size, safe-padding, fallback, ownership, and source
mapping is in `asset-manifest.json`. Generation prompts and alpha-validation
evidence are recorded in `docs/design/references/ui-assets/README.md`; the visual
catalog is `docs/design/reports/ui-raster-asset-catalog.png`.

## Production Theme

`production_ui_theme.tres` is the project-level owner for recurring production UI
styles. Its fifteen semantic variations cover primary, secondary, danger, icon,
choice, action-slot, and prompt controls; flat/modal surfaces; health, resource,
and boss meters; and recurring title, secondary, and numeric text roles.

The Theme follows `docs/design/UI_VISUAL_SYSTEM.md`: square corners, flat planes,
no decorative perimeter outlines, and at least 48 px primary targets. Focus and
selection reserve a stable four-pixel inside-left marker lane and combine that
marker with fill or live text, so state is not color-only and does not move the
layout. The future UI foundation must recreate one narrow semantic-token owner;
screens must not rebuild shared variations locally.

The Theme embeds `fonts/NotoSansKR-Variable.ttf` as its default font so Korean
and English remain identical across desktop and Web exports instead of relying
on host fonts. The file is an unmodified Noto Sans KR variable TTF from Google
Fonts commit `26c5c976d82d50c24a8f0a7ac455e0a7c639c226`; only its local filename was
normalized. Its copyright notice and OFL-1.1 terms are preserved in
`fonts/NotoSansKR-OFL.txt`, and adoption evidence is recorded in
`docs/research/third_party_adoption_ledger.md`.

The retired theme validator is available at Git commit `7cc069c`. The new UI pass
must add a smaller replacement covering variation/base-type ownership,
zero-radius/no-perimeter rules, button target height, bundled font ownership, and
representative Korean/English glyph coverage.

## Pivot Status

`asset-manifest.json` remains the retained source inventory, but there is no
current runtime resolver. Recreate one shared resolver before multiple screens
consume the same family; screens must not repeat raster paths.

The retired adoption batch used:

- four shell background contexts: Main Menu, shell Settings, Hero Preparation,
  and Run Result;
- Traveler, equipment, Spirit Stone, and potion art in Hero Preparation;
- all five active card vignettes in Card Reward;
- Traveler, Slime King, and Boss Core art in the result summary.

Those placements are historical evidence, not accepted isometric layouts.
Structural SVGs and small semantic icons retain explicit candidate or fallback
roles in the manifest until new screens measure their actual slots.
