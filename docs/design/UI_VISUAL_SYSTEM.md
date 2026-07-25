---
type: spec
status: active
owner: BK
last_reviewed: 2026-07-25
canonical_for: Cardborne vehicle-game art direction and UI presentation
related:
  - ../product/vehicle_game_spec.md
  - ./sunken-ceramic-fresco.png
---

# Cardborne UI and Visual System

## Purpose

Define one readable flat-color visual language for the current run-selected-field
vehicle game. `sunken-ceramic-fresco.png` supplies palette, large-shape rhythm,
and restrained detail; gameplay meaning comes from this specification.

## Scope

This contract applies to the run-selected field, actors, combat feedback, HUD,
deployment, upgrades, pause/settings, guidebook, result, and garage. Gameplay
rules remain owned by the product specification.

## Requirements

### Art language and semantic palette

- Use flat color, large geometric masses, and clean silhouettes. Avoid
  decorative floor motifs, outlines, fine texture, speckling, micro-patterns,
  surface stains, and decorative detail that competes with combat.
- A frame must read in this order: walkable floor, solid cover/void, player,
  threats and telegraphs, pickups/rewards, then atmosphere.
- Ivory means walkable ground, ceramic green means solid cover/installations,
  cobalt means water or void, mustard means player/reward/progress, coral means
  ordinary danger, magenta means boss danger, and mint means recovery/support.
- Attack affinity may override the general danger fill: kinetic is coral
  (mustard for friendly fire), thermal is orange, toxin is olive, cryo is blue,
  arc is violet, and a multi-condition hybrid is bright ivory. Affinity is also
  encoded by a large trail or interior shape, never by color alone. Boss body,
  warning ownership, and health remain magenta even when a specific boss attack
  uses another affinity.
- All solid static cover uses the same blocker fill. State is communicated by a
  large shape, animation, or icon—not by inventing a new wall color.

### Shared-field readability

- Rendering and collision use the exact same floor and cover polygons. A visible
  opening must be traversable and a visible barrier must block movement,
  projectiles, line of sight, pursuit, and minimap space.
- Functional-terrain shapes never overlap one another or generated cover,
  actors, rewards, or spawn markers. Their visible footprint matches the
  reserved gameplay rectangle or radius used by layout validation.
- Main lanes remain broad enough for the player and pursuing groups to pass one
  another. Small unusable gaps are visually sealed.
- The map is larger than the viewer. The camera shows only a local combat area;
  the explored 20x12 minimap communicates the persistent whole.
- A new run selects one of three registered macro fields. Each stage activates
  eight deterministic large modules and tactical sockets from that field;
  exact retries reproduce them and adjacent stages use a different valid set.
- Functional terrain uses one large readable shape and a shape-coded purpose:
  mint plus for repair, mustard outward arrows for transit, mustard stacked
  chevrons for overdrive, violet lightning for an arc hazard, and blocker-fill
  walls with one large fracture for a
  breakable bulkhead. Helpful, hazardous, traversable-utility, directional, and
  blocking roles must remain distinguishable without reading color. Do not add
  decorative motifs, tiny debris, or repeated decoration to fake variation.

### Actor and combat readability

- The player, swarm units, mobile specialists, stationary threats, bosses,
  experience shards, repair, recall, and crates have distinct silhouettes and
  scale classes.
- Tactically different enemy roles do not share one outer contour. A role uses
  one large directional mass, cut, or center accent that remains recognizable
  in grayscale at gameplay scale; role color and simulation radius remain
  independent from that silhouette.
- All dangerous attacks show startup, damage area or projectile, and recovery.
  Startup fill and its outer boundary show the exact player-center danger
  footprint, not a decorative approximation. Any on-screen portion remains
  visible when the attacker is off-screen. Enemy intent is communicated through
  authored motion and bounded telegraphs, not permanent trajectory overlays.
- A warning's position and geometry are fixed from its first visible frame.
  Readiness changes continuously and monotonically from a pale, low-opacity
  affinity tint to a darker, higher-contrast tint at impact; it never flashes,
  pulses, or chases the ship.
- Accepted hull damage must be legible at the ship without reading the HUD:
  coral hit tint, small presentation-only recoil, bounded camera response,
  pale-coral invulnerability state, and a dedicated impact sound. Fully
  absorbed barrier damage remains visually distinct.
- A projectile head ends exactly at its circular collision radius. Light,
  standard, and heavy hostile damage use five-, six-, and seven-pixel heads;
  power therefore changes visible and physical size together. A short
  non-damaging hostile trail communicates direction and uses a shape-distinct
  kinetic, thermal, toxin, cryo, arc, or hybrid silhouette. Player projectiles
  always use a mustard ownership shell with a dark cobalt core; hostile
  projectiles keep affinity color and shape.
- Hostile affinity heads use large, distinct silhouettes: kinetic disk, thermal
  ember, toxin drop, cryo shard, arc bolt, and split hybrid diamond. Head and
  trail may share one static vertex-colored mesh and retained batch, but the
  head's farthest vertex must still equal the projectile collision radius.
- The unmodified Pulse Cannon starts from a seven-pixel collision radius and a
  rendered head exactly that large. Solid-cover impacts must terminate the
  visible trail at the same blocker used by collision; a projectile may appear
  beyond cover only when its state explicitly carries the exceptional
  `wall_piercing` capability.
- Corridor fill reaches the exact expanded collision boundary, including the
  swept circle's rounded start and end caps. Boundary rails sit inside that
  edge, and projectile or beam warnings end at the same live wall or crate
  contact as simulation. Area warnings, active persistent zones, and boss area
  attacks keep their exact outer radius visible for the complete damaging
  window. Ordinary rails are 3 pixels and heavy rails are 4 pixels; center
  accents remain 2–3 pixels so paths do not dominate the field. Area fill is
  strongest inside the central 55% to communicate center-weighted damage while
  the thin outer ring remains the exact cutoff. Thermal, toxin, cryo, and arc
  variations add restrained, large interior rhythms without changing the
  damage footprint.
- `Affinity` describes immediate impact presentation. Burn, poison, and chill
  are separate real `condition` payloads; no color promises a damage-over-time
  effect that gameplay does not apply. Multi-condition player rounds use the
  hybrid family.
- Burn, poison, and chill use three retained, shape-distinct status arcs around
  an affected enemy. Stack counts belong in localized target/boss text rather
  than tiny floating labels.
- Boss warning and boss health replace competing top-level information while
  active. Off-screen threat arcs supplement the field and never duplicate
  visible enemies.
- Automatic secondaries use bounded, recognizable shapes: seeker projectile,
  mint ion ring, mustard orbit blades, coral wake mines, and a following drone.
- Persistent glance cues use four fixed tiers. Reinforced Hull darkens the
  mustard hull, Tuned Thrusters shows zero to three rear engine modules,
  Kinetic Rounds darkens the primary cannon, and passive-damage upgrades darken
  one mint secondary core. Count- or radius-readable secondary upgrades do not
  receive a redundant shade tier.

### HUD and modal hierarchy

- Korean is the default. Korean and English use the same layout and a real
  medium-or-heavier Noto Sans KR font weight.
- Keep live HUD clusters compact and outside the central combat rectangle.
  Prefer icons, strong numerals, radial cooldowns, and short labels over wide
  explanatory panels.
- Hull/experience remains at the top left with a 154x34 icon-only action rail
  directly below it. The bottom center remains free. The title-free 176x108
  minimap uses player facing, clustered moving enemies, shape-coded priority
  actors/items/crates, and support-field lifetime arcs.
- Timed effects use shape-distinct radial badges around the ship. Cooldown and
  active duration are distinguishable without color alone.
- Hull loss updates the main fill immediately and uses one restrained trailing
  segment. Reduced motion replaces recoil, shake, and flicker with steady tint,
  ring, and outline-pulse feedback; gameplay invulnerability duration is
  unchanged.
- Deployment, upgrade, pause/settings, guidebook, result, and garage hide
  conflicting live HUD, block gameplay input, have one clear primary action,
  and never clip at the supported minimum viewport.
- Deployment uses a centered header above a two-column body: controls and
  primary-weapon truth on the left, run difficulty and its lock explanation on
  the right. Deploy is the single centered `300x48` primary action; settings is
  secondary and Boss Practice remains debug-only.
- Upgrade selection uses three equal structured cards with family, title,
  effect, existing numeric deltas, and three level pips. Selection uses a
  four-pixel mustard frame plus a diamond marker, keyboard focus uses a separate
  rail, and a centered `300x48` Equip action confirms the choice. No timeout,
  hover, or accidental carried click applies a card.
- Pause keeps Resume as the only filled primary action. Restart and Settings
  remain secondary; aborting to the garage is a restrained tertiary danger
  action. Garage uses the same primary/secondary hierarchy and explicitly shows
  `없음` / `None` when no passive weapon is installed.
- The guidebook is reachable through `?`, uses five stable categories, clearly
  separates discovered content from `???`, and shows current ship statistics
  without exposing future entries. Discovered actors reuse the combat mesh;
  locked entries use one neutral muted silhouette.
- The Guidebook hides its redundant entry column only for Current Ship. Other
  categories retain category, entry, and detail columns with explicit selected
  states; discovered details render separate Movement, Attack, and Counter
  rows.
- Settings places Ship Status first and renders dense read-only values inside a
  vertical scroll region. An active run shows one level/hull/experience summary,
  then Hull/Mobility, Primary/Breach, and EMP stat groups before secondary
  weapons and upgrades. Its no-run state contains only the localized empty
  state—no empty group headings or stale values.
- Stage and failure reports are full modal focus layers with one bottom primary
  action. At 1180 pixels and wider, defeats, damage source, and damage attribute
  use three columns; below that, keyboard-accessible tabs expose one list at a
  time. Light dividers separate the wide columns; names, amounts, percentages,
  and counts align independently, and the bottom primary action is `300x48`.
  Percentage, amount, and count columns remain readable in both Korean and
  English.

### Implementation boundaries

- Typography and reusable control states belong in the production Godot theme.
- `VehicleUpgradeChoiceCard` owns presentation of one frozen offer only.
  `VehicleUpgradeChoicePanel` owns selection, guard, decline, and confirmation;
  card compatibility and application stay outside UI code.
- `VehicleBuildSummaryPanel` renders only a frozen build snapshot shared by
  Settings and Guidebook. It never queries or mutates gameplay state.
- Values, labels, cooldowns, focus, selection, localization, and guide discovery
  remain live UI state; do not bake them into raster assets.
- Static world presentation belongs to `vehicle_stage_backdrop.gd`; immutable
  floor/candidate data belongs to the three registered field definitions; the
  run-scoped `VehicleFieldLayout` owns the selected field and immutable
  stage-tactical children; `VehicleTerrainRuntime` owns scheduled support
  fields; dynamic combat belongs to the run.
- Static minimap geometry and each bounded dynamic tactical snapshot render as
  one vertex-colored mesh surface. Do not reintroduce per-actor or per-marker
  canvas draw commands.
- World support fields use retained disk, ring, and beam batches plus one shared
  24-segment timer batch. They do not use per-field immediate canvas drawing or
  per-field scene nodes.
- Raster assets are justified only when procedural flat shapes cannot communicate
  the required silhouette at gameplay size.

## Verification

Run the focused UI and presentation validators after relevant changes:

```powershell
.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_ui_layout.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_rewards_ui_audio.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_build_snapshot.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_guidebook.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_report.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_combat_renderer.gd
.\tools\export_web.ps1
```

Rendered review covers Korean and English at `960x540`, `1280x720`, and
`1920x1080`, including Deployment, upgrade default/selected, Pause, active and
empty Ship Status, discovered and locked Guidebook entries, wide and compact
reports, Garage, maximum combat pressure, and actor/projectile catalogs.

## Acceptance Criteria

- At 960x540, 1280x720, and 1920x1080, HUD clusters do not overlap, modal content
  is not clipped, and command targets remain at least 44 pixels high.
- Korean and English expose identical reachable controls and complete copy.
- Walkable, blocker, void, player/reward, danger, support, and boss semantics are
  distinguishable without relying on fine detail.
- The player, current objective, Breach Shot state, active secondaries, and boss
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
