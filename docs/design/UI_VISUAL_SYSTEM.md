---
type: spec
status: active
owner: BK
last_reviewed: 2026-07-24
canonical_for: Cardborne vehicle-game art direction and UI presentation
related:
  - ../product/vehicle_game_spec.md
  - ./sunken-ceramic-fresco.png
---

# Cardborne UI and Visual System

## Purpose

Define one readable flat-color visual language for the current shared-field
vehicle game. `sunken-ceramic-fresco.png` supplies palette, large-shape rhythm,
and restrained detail; gameplay meaning comes from this specification.

## Scope

This contract applies to the shared field, actors, combat feedback, HUD,
deployment, upgrades, pause/settings, guidebook, result, and garage. Gameplay
rules remain owned by the product specification.

## Requirements

### Art language and semantic palette

- Use flat color, large geometric masses, clean silhouettes, and sparse
  monumental motifs. Avoid outlines, fine texture, speckling, micro-patterns,
  surface stains, and decorative detail that competes with combat.
- A frame must read in this order: walkable floor, solid cover/void, player,
  threats and telegraphs, pickups/rewards, then atmosphere.
- Ivory means walkable ground, ceramic green means solid cover/installations,
  cobalt means water or void, mustard means player/reward/progress, coral means
  ordinary danger, magenta means boss danger, and mint means recovery/support.
- All solid static cover uses the same blocker fill. State is communicated by a
  large shape, animation, or icon—not by inventing a new wall color.

### Shared-field readability

- Rendering and collision use the exact same floor and cover polygons. A visible
  opening must be traversable and a visible barrier must block movement,
  projectiles, line of sight, pursuit, and minimap space.
- Main lanes remain broad enough for the player and pursuing groups to pass one
  another. Small unusable gaps are visually sealed.
- The map is larger than the viewer. The camera shows only a local combat area;
  the explored 16x10 minimap communicates the persistent whole.
- Stage identity comes from population, pacing, boss, and UI state on the same
  drowned-ruin field. A new run may select eight large modules from the authored
  cover candidates, but that result must not recolor or rearrange between stages
  or retries.
- Motifs are large and sparse. Do not add tiny debris or repeated decoration to
  fake variation.

### Actor and combat readability

- The player, swarm units, mobile specialists, stationary threats, bosses,
  experience shards, repair, recall, and crates have distinct silhouettes and
  scale classes.
- All dangerous attacks show startup, damage area or projectile, and recovery.
  Enemy intent is communicated through authored motion and telegraphs, not
  permanent trajectory overlays.
- Accepted hull damage must be legible at the ship without reading the HUD:
  coral hit tint, small presentation-only recoil, bounded camera response,
  pale-coral invulnerability state, and a dedicated impact sound. Fully
  absorbed barrier damage remains visually distinct.
- Ordinary hostile projectiles retain a visible coral head and 36-pixel trail
  around their five-pixel collision radius. Boss projectiles remain slightly
  larger and magenta. Rendered danger may exceed collision size but may never be
  smaller than it.
- Burn, poison, and chill use three retained, shape-distinct status arcs around
  an affected enemy. Stack counts belong in localized target/boss text rather
  than tiny floating labels.
- Boss warning and boss health replace competing top-level information while
  active. Off-screen threat arcs supplement the field and never duplicate
  visible enemies.
- Automatic secondaries use bounded, recognizable shapes: seeker projectile,
  mint ion ring, mustard orbit blades, coral wake mines, and a following drone.

### HUD and modal hierarchy

- Korean is the default. Korean and English use the same layout and a real
  medium-or-heavier Noto Sans KR font weight.
- Keep live HUD clusters compact and outside the central combat rectangle.
  Prefer icons, strong numerals, radial cooldowns, and short labels over wide
  explanatory panels.
- Timed effects use shape-distinct radial badges around the ship. Cooldown and
  active duration are distinguishable without color alone.
- Hull loss updates the main fill immediately and uses one restrained trailing
  segment. Reduced motion replaces recoil, shake, and flicker with steady tint,
  ring, and outline-pulse feedback; gameplay invulnerability duration is
  unchanged.
- Deployment, upgrade, pause/settings, guidebook, result, and garage hide
  conflicting live HUD, block gameplay input, have one clear primary action,
  and never clip at the supported minimum viewport.
- Upgrade selection uses a two-step choose-and-confirm flow. No timeout, hover,
  or accidental carried click applies a card.
- The guidebook is reachable through `?`, uses five stable categories, clearly
  separates discovered content from `???`, and shows current ship statistics
  without exposing future entries.

### Implementation boundaries

- Typography and reusable control states belong in the production Godot theme.
- Values, labels, cooldowns, focus, selection, localization, and guide discovery
  remain live UI state; do not bake them into raster assets.
- Static world presentation belongs to `vehicle_stage_backdrop.gd`; immutable
  floor/candidate data belongs to `drowned_ruin_field.gd`; the run-scoped
  `VehicleFieldLayout` owns selected cover and sockets; dynamic combat belongs
  to the run.
- Raster assets are justified only when procedural flat shapes cannot communicate
  the required silhouette at gameplay size.

## Acceptance Criteria

- At 960x540, 1280x720, and 1920x1080, HUD clusters do not overlap, modal content
  is not clipped, and command targets remain at least 44 pixels high.
- Korean and English expose identical reachable controls and complete copy.
- Walkable, blocker, void, player/reward, danger, support, and boss semantics are
  distinguishable without relying on fine detail.
- The player, current objective, opening-shot state, active secondaries, and boss
  warning remain locatable at maximum supported enemy pressure.
- Accepted damage is readable at the ship and hull bar in both motion modes;
  status arcs and stack text remain legible without adding per-enemy nodes.
- Rendered review shows one persistent field across all stage states, no fake
  passable gaps, no retired boss gate, and no hidden guidebook controls.

## Non-Goals

- Realistic materials, ornamental borders, dense texture, or micro-decoration.
- Per-stage field recolors or geometry variants.
- Text baked into screenshots or image assets.
- Black-floor/white-wall conversion without a separately accepted actor and
  telegraph contrast system.
