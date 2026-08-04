---
type: evidence
status: archived
owner: BK
created: 2026-08-04
last_reviewed: 2026-08-04
related:
  - docs/design/visual-replacement-workbench/world-map-minimal-v3.html
---

# Archived Gameplay Code-Asset Rasterization Record

> Historical generation evidence only. The current map contract is documented
> in `world-map-minimal-v3.html`; the service rail and support-timer segment
> listed below were subsequently retired and are not production assets.

## Authority input

- Specification: `docs/design/VISUAL_SYSTEM.md`
- Image reference: `docs/design/cardborne-universal-art-style-reference.png`
- Reference SHA-256: `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`
- Reference use: supplied to the generation pass as the actual image input and inspected at original resolution.

## Batch direction

Create one coherent transparent gameplay-asset sheet containing reusable field
surface, wall, rail, health frame, ring, beam strip, diamond marker, timer
segment, disk mask, and crosshair components. Match the canonical general-SF
sheet through broad matte color masses, a dark perimeter, hard planar edges,
and sparse functional accents. Exclude gradients, bevels, glow, texture noise,
dots, particles, nested borders, decorative corners, and micro-detail. Keep
every component readable when reduced to its intended world-space size.

The first draft was rejected because it introduced bevel, gradient, and keyed
edge fringe. The accepted flat-v2 source was normalized to transparent exact
canvases with no more than four opaque RGB planes per exported PNG.

## Accepted source records

| File | SHA-256 |
| --- | --- |
| `world-combat-cue-source-flat-v2.png` | `4bce955fef6d7501bb3c0a8ff9f6032f936c37d77ddb4acaf1c99a040a94cb1d` |
| `world-combat-cue-source-flat-v2-alpha.png` | `7b663a1b69fd56e8278debc79d2bfbae02c21cf1024dd84c250e2b86cb2c4c9b` |
| `world-combat-cue-normalized-preview.png` | `a01d40807ca794891d0b45d76e4a735d6da97f3b41cef09a45ce9d22146910f2` |

## Production mappings at the time of generation

| Semantic ID | Target | Canvas | SHA-256 |
| --- | --- | ---: | --- |
| `world/surface_panel_9` | `art/visuals/production/gameplay/world/presentation/world_surface_panel_9.png` | 288×288 | `02c1c4befd38237889e8bb01cd94ad8ed47ed7287cc004a9215b3024d9eaab62` |
| `world/service_rail_tile` | `art/visuals/production/gameplay/world/presentation/world_service_rail_tile.png` | 288×48 | `06aa310015c9c65cef04653e1997807dae80894b464b3e9f908be7a1e3949d65` |
| `world/wall_segment_9` | `art/visuals/production/gameplay/world/presentation/world_wall_segment_9.png` | 192×96 | `3c7d076ae1b5b5252fbdd57d3b03929ceffb26ef3ceee49084baeeedc03c7aae` |
| `cue/health_bar_frame_9` | `art/visuals/production/gameplay/effects/cues/cue_health_bar_frame_9.png` | 96×16 | `8fbcb50c1ff30b048c724f5b21c8f4eb6a61cc2c8ca91b80adc31192de0322da` |
| `cue/ring` | `art/visuals/production/gameplay/effects/cues/cue_ring.png` | 128×128 | `92bda7c417b667cb9cf9ab0ef12edc08fcfc93836c3e706f137d884a42599b25` |
| `cue/beam_strip_9` | `art/visuals/production/gameplay/effects/cues/cue_beam_strip_9.png` | 128×32 | `f30a3e2027de9e3580973d1e54051617e7b5f87e58571d768f6ad558b2924e48` |
| `cue/diamond_marker` | `art/visuals/production/gameplay/effects/cues/cue_diamond_marker.png` | 64×64 | `650292d8620b237446298a1dcdfde2e85eadfff857c86f393a1a230e9bbbe021` |
| `cue/support_timer_segment` | `art/visuals/production/gameplay/effects/cues/cue_support_timer_segment.png` | 64×64 | `cdaa38973325df6f032c00b358c40bd3e485d8916864f993354560b55f9821ab` |
| `cue/disk_mask` | `art/visuals/production/gameplay/effects/cues/cue_disk_mask.png` | 128×128 | `d3ca68bf46e4902fb1d93594a5af49a53c297968e0d99643ab3d9d641bdfa28e` |
| `cue/crosshair` | `art/visuals/production/gameplay/effects/cues/cue_crosshair.png` | 96×96 | `1d2178754a6fc5b8a88adfd5269103f56d5392c1caebeb358d59dfcfbc6138ee` |

The rejected v1 source files are retained outside the active workbench under
`build/rejected-gameplay-raster-v1/` and do not enter production or the report.
