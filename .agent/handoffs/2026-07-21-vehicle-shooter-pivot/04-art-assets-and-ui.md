---
type: record
status: active
owner: BK
created: 2026-07-21
source: Owner art feedback, UI work, repository asset audit, and commits 740eda5/4884ff4
topic: Retained Cardborne art, asset, and UI decisions
related:
  - ./README.md
  - ../../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../../docs/design/references/README.md
  - ../../../art/ui/production/README.md
---

# Art, Assets, and UI Handoff

## Context

The project accumulated substantial visual exploration before its gameplay
identity stabilized. This record separates retained visual direction from
rejected production approaches and actor-specific assets that may become obsolete.

## Decision

Retain the drowned-ruin/foundry identity and its flat-color, borderless,
low-noise visual language. Re-evaluate humanoid-specific assets if the vehicle
direction is accepted. UI geometry should use scalable primitives where possible;
bespoke atmospheric and representational art should remain raster.

## Rationale

The owner repeatedly rejected noisy pointillist texture, unrelated palette
variation, outlined forms, fake large backgrounds, and UI work that stopped at
mockups instead of reaching the running game.

## Consequences

### Durable art constraints

- Flat color first; no outlines.
- Minimal stains, speckles, micro-patterns, and accidental texture repetition.
- Closely related hues within a terrain family. Optional variation belongs in
  controlled overlay layers.
- Simple, legible silhouettes at gameplay scale.
- Background seams must be intentionally simple and sequentially continued from
  the preceding panel.
- Interactive foregrounds, hazards, installations, and state changes need their
  own readable assets; atmosphere must not hide gameplay truth.
- Ground-plane simulation and isometric presentation remain separate concerns.

### Asset-role boundary

Use SVG or Godot-native scalable UI for:

- buttons, panel shells, slots, separators, banners, and simple icons;
- selection, focus, cooldown, disabled, and hover states where geometry is enough;
- HUD meters and clean symbolic indicators.

Use raster imagery for:

- screen backgrounds and large atmosphere;
- characters or vehicles, bosses, equipment, cards, and pickups;
- terrain/surface art, impact art, special effects, and irregular illustrations;
- component bases and overlays whose state depends on painted material change.

### Canonical retained locations

- Art/UI contract: `docs/design/UI_VISUAL_SYSTEM.md`.
- Owner and generated references: `docs/design/references/`.
- Production UI backgrounds: `art/ui/production/backgrounds/`.
- Production UI shapes/icons/illustrations: `art/ui/production/`.
- Flooded Works world art and Tiled kit: `art/world/flooded_works/`.
- Humanoid isometric actor sheets: `art/world/flooded_works/isometric/actors/`.
- Vehicle concepts: `docs/design/concepts/vehicle-led-isometric/`.
- Vehicle reference analysis:
  `docs/research/vehicle_led_isometric_action_reference_analysis.md`.

### Existing vehicle concepts

- [Exploration / connected field](../../../docs/design/concepts/vehicle-led-isometric/01-exploration.png)
- [Manual-target combat](../../../docs/design/concepts/vehicle-led-isometric/02-combat.png)
- [Boss and build payoff](../../../docs/design/concepts/vehicle-led-isometric/03-boss-build.png)

These are composition references only. They do not establish exact map geometry,
asset scale, camera angle, UI layout, or shippable vehicle design.

### Background and terrain lessons

- A source image's limited dimensions conflict with a world larger than one
  viewport. Do not upscale one generated image into a supposedly huge unique map.
- For continuous atmosphere, create sequential panels with overlap/seam control
  and keep transition regions deliberately low-detail.
- For interactive terrain, use modular chunks, footprints, sockets, and a finite
  role-based component family rather than cutting the whole world from one image.
- The Tiled kit is an authoring and semantic-layout resource; it is not a built-in
  art library and does not solve final surface art automatically.
- Tiled owns walkable ground, room footprint, sockets, and placement anchors.
  Runtime 3D/collision and painted surface/presentation remain separate layers.

### UI lessons

- A screen mockup is evidence, not implementation.
- Every applied screen needs working buttons, navigation, focus, supported
  viewport fit, and production-build verification.
- HUD should show only actionable combat truth: player health/resource, primary
  state, passive secondary state, `Z` cooldown, dash state, pickups/buffs, enemy
  HP, target selection, and boss state.
- Do not draw persistent enemy movement trajectories. Telegraph damaging attacks
  through startup, active area/direction, and recovery cues.
- If a minimap remains in the new product, it should show player position,
  visited/unvisited space, discovered objectives, important pickups, exits, and
  known field/stage bosses without revealing unexplored content.

### Cleanup state

- Duplicate UI background bitmaps formerly under
  `docs/design/references/ui-shell/background-*-v01.png` were removed; canonical
  copies remain under `art/ui/production/backgrounds/`.
- After that consolidation, project files excluding Git/Godot/runtime caches had
  no meaningful exact duplicates beyond intentional empty `.gitkeep` files.
- A prior audit found generated-image archive copies and stale external runtime
  caches. Their deletion was blocked in that turn and must not be assumed done.
- Current modified `.import` files are not part of this handoff and need a later
  owner-aware cleanup or regeneration decision.

## Related

- [Current repository state](./02-current-repository-state.md)
- [Latest product hypothesis](./03-latest-product-hypothesis.md)
