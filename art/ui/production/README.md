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
