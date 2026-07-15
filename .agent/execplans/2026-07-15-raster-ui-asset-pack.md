---
type: plan
status: done
owner: BK
created: 2026-07-15
scope: Production-ready raster UI illustrations that are not practical as SVG masks
related:
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../art/ui/production/asset-manifest.json
---

# Raster UI Asset Pack

## Purpose / Why

Create the first coherent set of independent bitmap illustrations for current
vertical-slice content while keeping panels, buttons, state overlays, labels,
and simple semantic glyphs in the existing SVG/Theme system.

## Context

The shell already has five approved bitmap backdrops, but Hero Preparation,
Forge, rewards, and boss/result surfaces still lack expressive content art.
The active source of truth is the single Traveler, eight equipment models, two
Spirit Stones, one potion, five cards in `data/cards/card_catalog.tres`, and the
Slime King reward loop.

## Scope / Non-scope

In scope:

- one Traveler portrait;
- eight equipment-model illustrations;
- two Spirit Stone illustrations and one potion illustration;
- five active card illustrations;
- one Slime King portrait and one boss-core reward illustration;
- production manifest, provenance list, and a deterministic review contact sheet.

Out of scope:

- wiring the new art into runtime screens;
- panels, buttons, bindings, meters, selection, rarity, lock, damage, or cooldown states;
- gameplay sprites, animation sheets, terrain chunks, hazards, and interactable props;
- retired class-specific cards and legacy equipment.

## Assumptions

- Generated source images are large enough for UI display after reviewed downscaling.
- Flat-color subjects with crisp edges are suitable for chroma-key alpha removal.
- Card art remains a transparent borderless vignette; all assets use transparent PNG.
- Runtime state stays live and is never baked into the art.

## Proposed Design

| Concern | As-is | To-be | Accept | Guard |
| --- | --- | --- | --- | --- |
| Content identity | Text and procedural glyphs | Independent raster illustrations keyed to active content IDs | Every active item resolves in the manifest | No legacy/class assets |
| Art style | Approved flat shell palette | Outline-free, low-noise, 4-6 large color masses | Contact sheet reads as one family | No pointillism, stains, tiny repeated detail, text, or watermark |
| State | Mostly code-rendered | Still code-rendered over neutral art | One neutral image per content ID | No selected/disabled/rarity variants |
| Delivery | Background-only raster manifest | Categorized illustration folders plus source/provenance record | PNG dimensions, alpha, padding, and IDs validate | No generated sprite-sheet crops used at runtime |

## Milestones / Tasks

- [x] Freeze the active content inventory and generation prompts.
- [x] Generate and inspect each independent source image.
- [x] Remove chroma key for transparent assets and normalize production dimensions.
- [x] Build a deterministic contact sheet from the individual files.
- [x] Register assets and document SVG/raster boundaries and provenance.
- [x] Import with Godot and validate format, dimensions, alpha, and visual coherence.
- [x] Run a task-scoped quality review and commit only task-owned files.

## Progress

- Existing shell references, current production screens, active catalogs, and UI
  visual-system rules were inspected.
- Nineteen independent sources were generated, visually inspected, chroma-keyed,
  normalized to transparent `512x512` PNGs, registered, and cataloged.
- Automated validation passed for all 19 manifest identities, dimensions, RGBA
  modes, transparent corners, alpha coverage, and chroma residue.
- The contact sheet was inspected at full size and at its embedded 64 px samples;
  no crop, halo, or identity collision remained.
- Godot 4.7 imported all 19 textures with lossless mode, mipmaps disabled, and
  no size limit; headless project boot succeeded.
- The final quality pass found no material task-scoped issue. Runtime adoption
  remains outside this pack rather than an incomplete task.

## Next Steps

No next step remains inside this plan. Runtime screen adoption, gameplay sprites,
terrain art, and animation pipelines require separately scoped implementation.

## Test Plan

- PNG dimensions and color mode match the documented contract.
- Every asset has alpha, fully transparent corners, no key-color fringe, and
  useful subject coverage; cards are transparent borderless vignettes.
- 64 px thumbnails retain distinct silhouettes.
- Godot headless import and boot succeed without missing-resource warnings.
- Review contact sheet contains only independent source assets and no stretched crops.
- `git diff --check` and manifest JSON parsing pass.

## Rollback / Safety

All additions are new files or append-only manifest/document updates. Runtime scenes
are not changed, so rollback is removal of this pack and its registrations.

## Risks

- Separate generations can drift in scale, perspective, or palette.
- Chroma removal can leave halos on antialiased edges.
- Small source output can look soft at unusually large display sizes.
- Generative models are not appropriate for frame-consistent animation sheets.

## Open Questions

- Runtime adoption order remains a later owner decision after review of this pack.
- Gameplay sprite, terrain, and interactable pipelines remain separate milestones.

## Decision Notes

- Simple semantic icons remain SVG masks.
- This pack uses one file per content identity; contact sheets are review evidence only.
- Active `card_catalog.tres`, not dormant class-card files, defines the five card assets.
