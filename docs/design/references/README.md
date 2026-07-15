---
type: evidence
status: active
owner: BK
created: 2026-07-13
last_reviewed: 2026-07-15
topic: Generated visual exploration and component decomposition references
scope: Mood boards and production-guide images for Cardborne world components and UI
source: Owner feedback and generated reference images through 2026-07-13
related:
  - ../GAME_COMPONENT_ART_SYSTEM.md
  - ../UI_VISUAL_SYSTEM.md
  - ../../research/component_ui_foundation_research_2026-07-13.md
---

# Visual Reference Index

## Status

Most images in this folder are retained exploratory references, not production-ready runtime assets. They communicate candidate palette, silhouette, density, and modular decomposition. The owner-selected anchor and five selected shell backgrounds under `ui-shell/` are exceptions: they ground the active UI art direction, while their separately imported production copies live under `art/ui/production/backgrounds/`.

## UI Shell Art Direction

| Path | Use | Runtime status |
| --- | --- | --- |
| `ui-shell/owner-reference-lower-ruins.png` | Primary owner-selected theme and structural mood anchor for shell UI imagery. | Reference only. |
| `ui-shell/background-*.png` | Selected screen-specific source references generated from the active visual contract. | Production copies exist under `art/ui/production/backgrounds/`; four shell contexts are connected and Forge is deferred. |
| `ui-shell/panel-*.png` | Shape-language reference sheets for deterministic SVG/NinePatch/Theme reconstruction. | Never crop or stretch directly into production. |
| `ui-shell/README.md` | Batch roles, generation constraints, findings, and limitations. | Advisory evidence. |

## Working Direction

The working synthesis captured by these boards is:

- steampunk plus post-apocalyptic flooded-foundry structure and mechanisms;
- the stronger teal, rust, gold, charcoal, and controlled violet color language from the relic-print direction;
- a saturated result, not pale or washed out;
- simpler shapes and less micro-detail than the mood boards;
- stage-specific skin kits over shared gameplay contracts;
- borderless, flat-color UI.

## Mood And Style Boards

| File | Use | Do not use for |
| --- | --- | --- |
| `visual-style-slate-cutout.png` | Broad flat-shape direction and restrained detail. | Final palette or direct game assets. |
| `visual-style-luminous-gouache.png` | Lighting and luminous pickup contrast. | Painterly runtime texture density. |
| `visual-style-relic-print.png` | Teal/rust/gold/violet palette and graphic hierarchy. | Directly sliced sprites. |
| `visual-style-forge-relic-hybrid.png` | Selected structural mood: flooded foundry, ruins, machinery, readable gameplay elements. | Exact tile dimensions; it is too detailed for production scale. |
| `visual-style-modular-foundry.png` | Clearest high-level example of repeated blocks, modular traps, traversal space, and flat HUD. | Final TileSet; seams and dimensions are illustrative. |

## Component Guides

| File | Production question it answers | Required redraw work |
| --- | --- | --- |
| `component-guides/terrain-tile-kit.png` | Which semantic tile families are needed: fill, cap, side, corner, one-way, water edge, and assembled example. | Choose exact cell size; rebuild every tile on one grid; remove baked lighting/noise; verify all terrain peering combinations and collision. |
| `component-guides/mechanical-trap-kit.png` | How a trap separates mount, pivot, connector, payload, telegraph, and motion envelope. | Lock chassis/payload dimensions and pivots; create stage skins; define collision/telegraph outside the art. |
| `component-guides/traversal-interactable-kit.png` | State families for rope, moving/crumbling/destructible platform, spikes, vent, and chest. | Normalize dimensions and state frame counts; separate each component into its own transparent sprite/animation source. |
| `component-guides/pickup-hud-kit.png` | Shared pickup silhouettes, icon scale variants, meters, action slots, cooldown, and disabled-state examples. | Rebuild icons with consistent optical boxes; remove any border-like framing; produce Theme-driven states rather than baking them into images. |

## Mandatory Interpretation Rules

- A reference object is not automatically one production asset. Decompose it by semantic role.
- Tile images define appearance only; collision and gameplay tags are authored and validated separately.
- Stateful traps and interactables remain reusable scenes even when their art fits a tile grid.
- Chassis, connector, and payload art may vary by stage skin, but behavior dimensions do not change unless a typed gameplay variant declares them.
- Do not introduce random cross-stage material mixing.
- Do not reproduce the reference images' pointillism, speckle, dense hatching, or tiny surface marks.
- Do not bake labels, key bindings, values, selection, cooldown, lock, or disabled states into UI images.
- No generated `.png.import` sidecar under `docs/` is committed; documentation images are source references only.

## Production Handoff Checklist

- [ ] Exact logical cell size selected through the terrain spike.
- [ ] Tile atlas grid, padding, naming, source IDs, and filtering documented.
- [ ] Required terrain peering matrix has no missing edge/corner case.
- [ ] Component pivots, sockets, motion envelope, collision bounds, and state frames documented.
- [ ] One stage-skin kit completed without cross-region assets.
- [ ] UI icon box, safe padding, display sizes, tint permission, and fallback IDs documented.
- [ ] Generated micro-detail removed at gameplay scale.
- [ ] Human review confirms silhouette readability at 960x540 gameplay capture.
