---
type: evidence
status: active
owner: BK
created: 2026-07-13
last_reviewed: 2026-07-17
topic: Retained Cardborne visual references
scope: Mood, palette, shell composition, and production UI asset evidence for the isometric action RPG pivot
source: Owner-selected images and project-generated references through 2026-07-17
related:
  - ../UI_VISUAL_SYSTEM.md
  - ../../../art/ui/production/README.md
  - ../../../.agent/execplans/2026-07-17-isometric-action-rpg-pivot.md
---

# Visual Reference Index

## Purpose

Preserve the accepted Cardborne art language while preventing old side-view
layouts from becoming isometric gameplay geometry by accident.

## Sources

### Primary direction

- `ui-shell/owner-reference-lower-ruins.png` is the owner-selected structural and
  palette anchor.
- `visual-style-slate-cutout.png` is the simplification reference: broad shapes,
  clean surfaces, no outlines, and restrained detail.
- `visual-style-relic-print.png` and
  `visual-style-forge-relic-hybrid.png` support the teal, rust, charcoal, gold,
  and controlled-violet hierarchy.

### Shell and UI assets

- `ui-shell/background-*.png` are source references for retained production
  copies under `art/ui/production/backgrounds/`.
- `ui-shell/panel-*.png` are shape-language evidence only; never crop them into
  production controls.
- `ui-assets/README.md` records the generated illustration family and asset IDs.
- `../reports/ui-raster-asset-catalog.png` and
  `../reports/ui-svg-asset-catalog.html` are inspection artifacts, not atlases.

## Findings

- The retained direction is a drowned ancient-industrial ruin built from large,
  flat color masses and three to five readable depth planes.
- Surfaces stay clean: no pointillism, dense cracks, hatching, speckle, repeated
  micro-patterns, or visible outlines.
- UI uses borderless flat planes, live typography, and semantic glyphs.
- Detailed portraits, equipment, cards, backgrounds, and world objects remain
  raster art; simple structural controls and glyph masks may remain SVG.
- Side-view terrain sheets, platform silhouettes, and former map compositions are
  not layout references for the new isometric ground plane.

## Recommendations

- Use these images to judge palette, silhouette, density, lighting, and material
  language only.
- Produce new isometric room chunks, actor direction sets, floor/wall occluders,
  and cover props against a graybox gameplay contract.
- Keep collision, navigation, interaction bounds, telegraphs, and state overlays
  outside generated background images.
- Review new world assets at gameplay scale and against Y-sorted actors before
  accepting detail or lighting.

## Limitations

- None of these images proves isometric collision, navigation, occlusion, or
  combat readability.
- Retained platform-era subjects may be reused as identity or palette references,
  but their camera angle and proportions are obsolete.
