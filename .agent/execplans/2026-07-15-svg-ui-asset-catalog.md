---
type: plan
status: done
owner: BK
created: 2026-07-15
scope: Original production UI SVG primitives and rendered asset catalog
related:
  - ../../docs/design/PRODUCTION_UI_CONTRACT.md
  - ../../scripts/ui/production/ProductionUIStyles.gd
---

# SVG UI Asset Catalog ExecPlan

## Purpose

Create an original, project-owned SVG starter set for Cardborne panels, buttons,
and semantic icons, then prove the assets in a rendered catalog. The catalog is a
visual adoption aid; it does not replace the current Godot screen structure.

## Why / Context

The approved screen direction uses broad flat-color shapes, clipped stone planes,
and restrained semantic accents. Baking every panel and state into raster images
would make resizing and state changes brittle, while external icon packs would add
license and stylistic reconciliation work. Small original SVG masks are appropriate
for structural silhouettes and simple glyphs; world art remains raster work.

## Scope / Non-scope

In scope:

- Reusable SVG masks for panel, banner, card, button, and icon-button silhouettes.
- Original monochrome SVG glyphs for the current Traveler UI domains.
- A responsive HTML catalog showing scale, palette, button states, and one HUD
  composition assembled from the same source assets.
- Static validation, browser rendering, and desktop/compact screenshots.

Out of scope:

- Replacing current Godot scenes or `ProductionUIStyles.gd` in this pass.
- Raster backgrounds, terrain chunks, characters, props, or animation.
- External packages, fonts, icon libraries, or third-party licensed assets.

## Assumptions

- White SVG fills act as tintable masks; Godot can apply semantic color through
  `modulate` or a themed wrapper.
- Text, focus behavior, dimensions, and state logic remain live UI concerns rather
  than baked SVG content.
- The current production palette and the `960x540` minimum remain authoritative.

## Proposed Design

- Store importable originals under `art/ui/production/` by responsibility.
- Keep every glyph fill-only, outline-free, visually legible at 24-64 px, and free
  of embedded text, filters, gradients, patterns, scripts, or external references.
- Use one neutral button silhouette for normal, hover/focus, pressed, and disabled
  states; the catalog demonstrates those states through color, offset, and labels.
- Record origin and intended use next to the assets without claiming third-party
  provenance.

## Tasks

- [x] Add structural SVG masks and original semantic glyphs.
- [x] Add source/usage notes and an asset manifest.
- [x] Build the HTML catalog from the real SVG files.
- [x] Validate SVG structure, references, overflow, focus, and responsive rendering.
- [x] Capture desktop and compact evidence in Godot.
- [x] Commit only task-owned files and retire this plan to `done`.

## Milestones

1. Asset foundation: shapes, glyphs, manifest, and origin note exist.
2. Visible slice: the catalog renders the actual files and interactive button states.
3. Evidence gate: markup/static checks and two viewport captures pass.

## Progress

- Added 6 structural masks and 22 semantic glyphs under
  `art/ui/production/`, with one manifest and a provenance/usage note.
- Added `docs/design/reports/ui-svg-asset-catalog.html` as a responsive adoption
  catalog assembled from the real source files.
- Added `tools/capture_svg_asset_catalog.gd` and captured the same imports at
  `1536x1120` and `960x1480` under ignored runtime evidence.
- Reworked Timber, Steel, and Cartridges after the first rendered pass so their
  silhouettes remain distinct at HUD size.

## Next Steps

No task remains in this plan. Screen-specific adoption into Godot production
controls is a separate implementation decision.

## Test Plan / Verification

- Parse every SVG as XML and reject embedded raster images, scripts, filters,
  gradients, patterns, external URLs, text, and non-white visual fills.
- Confirm the manifest enumerates every source asset exactly once.
- Import all SVGs with Godot 4.7 and render the catalog through `TextureRect` at
  desktop and compact widths; inspect clipping, spacing, state distinction, and
  legibility. The in-app browser disallows local file URLs, so the HTML catalog
  received static reference checks while target-engine captures own visual proof.
- Run `git diff --check` and inspect the scoped diff before commit.

## Rollback / Safety

All new art and report files are additive. Rollback is removal of the task-owned
directories and plan changes; existing Godot scenes and user-authored untracked
reference files remain untouched.

## Risks

- SVG import is rasterized by Godot at configured scale, so large world art must
  not migrate into this asset category.
- Color-only state changes would violate the production contract; the catalog must
  pair color with labels, geometry, or focus treatment.
- Excessive geometric detail would collapse at HUD icon sizes.

## Open Questions

None blocking. Actual Godot adoption and any final icon additions remain a later,
screen-specific implementation decision.

## Decision Notes

- Use original assets instead of an external pack so the first set has no
  third-party attribution or style-mixing burden.
- Treat generated full-screen mockups as composition references, not texture
  atlases or implementation layers.
- Use the Godot render as final visual evidence because it exercises the actual
  SVG importer and tint path used by the game.
