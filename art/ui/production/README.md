# Cardborne Production UI SVGs

These SVGs were drawn specifically for this repository. No third-party icon,
font, raster image, traced shape, or external URL is embedded or required.
They may be used, modified, recolored, and shipped with Cardborne without an
attribution requirement from this asset set.

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

The icon set covers the current production contract: navigation, the six Traveler
loadout roles, forge materials and supplies, run rewards, and interaction. Every
icon uses a `64 x 64` view box and fill-only geometry so it remains readable from
approximately `24 px` through `64 px`.

See `docs/design/reports/ui-svg-asset-catalog.html` for the rendered catalog.

## Raster shell backgrounds

The five files under `backgrounds/` are production copies of the owner-selected
UI-shell candidates. They contain world atmosphere only; all panels, labels,
icons, focus, and interaction state remain live Godot controls.

| Asset | Runtime role |
| --- | --- |
| `backgrounds/main_menu.png` | Main Menu establishing view |
| `backgrounds/settings.png` | Shell-only Settings view; in-run Settings keeps the live stage |
| `backgrounds/hero_preparation.png` | Hero Preparation armory view |
| `backgrounds/forge.png` | Contextual Forge artwork retained for a later measured slot; not a full-screen in-run backdrop |
| `backgrounds/run_result.png` | Run Result gate view |

`ProductionBackdrop` displays the four connected shell images with
aspect-preserving cover behavior. Forge keeps the live stage behind its centered
modal, so its raster remains an available asset rather than a forced backdrop.
Do not stretch these files, tile them, or bake screen controls into replacements.
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

## Runtime ownership and current adoption

`scripts/ui/production/ProductionUIAssets.gd` is the only runtime path and
fallback resolver. Screens request semantic IDs or content-owner IDs; they do not
repeat raster paths. `tools/validate_production_ui_assets.gd` cross-checks all 52
registry entries against this manifest, imported dimensions, fallbacks, owners,
and disposition.

The first adoption batch uses:

- four shell background contexts: Main Menu, shell Settings, Hero Preparation,
  and Run Result;
- Traveler, equipment, Spirit Stone, and potion art in Hero Preparation;
- all five active card vignettes in Card Reward;
- Traveler, Slime King, and Boss Core art in the result summary.

Structural SVGs and the remaining small semantic icons retain explicit deferred
or fallback disposition in the manifest until the shared Theme, merchant, and HUD
milestones measure their actual slots.
