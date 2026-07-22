---
type: spec
status: active
owner: BK
last_reviewed: 2026-07-22
canonical_for: Cardborne vehicle-game art direction and UI presentation
related:
  - ../product/vehicle_game_spec.md
  - ./sunken-ceramic-fresco.png
---

# Cardborne UI and Visual System

## Purpose

Define one readable visual language for the current vehicle game across the map,
actors, combat feedback, HUD, deployment, upgrades, pause/settings, results, and
garage.

`sunken-ceramic-fresco.png` is the visual reference for palette, large-shape
rhythm, and restrained detail. Runtime layout and gameplay semantics come from
this specification rather than from the reference image's depicted objects.

## Scope

This contract applies to every reachable screen and every gameplay object in the
current five-stage campaign. Gameplay rules remain owned by the product specification
and runtime systems.

## Requirements

### Art language

- Use flat color, large geometric masses, sparse monumental motifs, and clean
  silhouettes.
- Avoid outlines, fine texture, speckling, repeated micro-patterns, and decorative
  detail that competes with combat information.
- A screen should read first as walkable space, blockers, player, threats,
  rewards, and objectives; atmosphere comes after those roles.
- Reuse a small set of strong shapes. Variation comes from composition, scale,
  rotation, and state—not unrelated colors or surface noise.

### Semantic palette

| Role | Color family | Use |
| --- | --- | --- |
| Walkable ground | Ivory | Traversable floor and modal surfaces |
| Blocking geometry | Ceramic green | Cover, walls, installations |
| Water and void | Cobalt | Non-walkable field and depth |
| Player, reward, progress | Mustard | Vehicle focus, pickups, active progress |
| Ordinary danger | Coral | Enemies, hostile attacks, damage |
| Boss danger | Magenta | Boss-only hierarchy |
| Recovery and support | Mint | Healing, safe state, assistance |
| Text | Deep green/ivory | High-contrast copy only |

Do not assign a new color when an existing semantic role already communicates the
state.

### Map and actor readability

- Traversable floor and collision-blocking geometry must be distinguishable
  before the player touches them.
- Cover geometry must use the same shape for movement, projectile collision, line
  of sight, minimap blocking, and rendered presentation.
- Keep major floor motifs between 120 and 250 pixels in radius and use them
  sparingly.
- The player, ordinary enemies, installations, field bosses, stage bosses,
  pickups, and caches need visibly different scale and silhouette classes.
- Startup, active, recovery, disabled, shielded, targeted, and destroyed states
  must remain readable at gameplay zoom.
- Off-screen threat arcs supplement the field; they must not duplicate enemies
  already visible on screen.

### Stage identity

All stages use the same semantic palette. Identity comes from macro composition
and one large mechanic, not recoloring or added surface noise:

| Stage | Large-shape identity |
| --- | --- |
| Flooded Works | Centered ivory plaza, split generator routes, green foundry cover, and broad cobalt voids. |
| Tidal Archive | Long current channels with large directional water marks and counter-current branch. |
| Storm Drydock | Grounded islands, broad electrical sweep lanes, and a restrained safe spine. |
| Coral Switchyard | Three mustard switch circles and one paired green gate that visibly changes flank ownership. |
| Abyssal Observatory | Two large mint reflector diamonds, readable orientation bars, consoles, and a symmetrical crown chamber. |

Mechanics that change collision must update world drawing and minimap in the
same frame. Switch gates and reflector orientations are large navigational
signals, not decorative icons.

### UI hierarchy

- Korean is the default language. Korean and English use the same layout and a
  real medium-or-heavier Noto Sans KR weight.
- Live combat prioritizes hull, current objective, primary-fire state, dash, EMP,
  passive support, minimap, and exceptional buffs.
- Primary fire owns the strongest bottom-rail hierarchy. Utility actions remain
  secondary.
- Boss state replaces competing objective/minimap clusters while the boss is
  active.
- Deployment, upgrade, pause, result, and garage are modal focus layers. They hide
  gameplay HUD content, block carried input, expose one clear primary action, and
  never apply a selection before explicit confirmation.
- Use short labels and strong numerals. Do not solve hierarchy with small gray
  explanatory text.

### Implementation boundaries

- Recurring typography and control states belong in
  `art/ui/production/vehicle_stage_theme.tres`.
- Live values, labels, cooldowns, health, selection, focus, and localization stay
  in Godot UI; do not bake them into images.
- `vehicle_stage_visual_profile.gd` owns semantic colors and presentation scale.
- `vehicle_stage_backdrop.gd` owns cached static world drawing. Dynamic combat
  state remains in the vehicle run.
- New raster assets are justified only when procedural shapes cannot communicate
  the required silhouette or landmark at gameplay size.
- Generated capture and build folders contain `.gdignore` boundaries so QA
  evidence never enters the shipped resource graph.

## Acceptance Criteria

- At 960x540, 1280x720, and 1920x1080, HUD clusters do not overlap, modal content
  is not clipped, and every command target remains at least 44 pixels high.
- Korean and English expose the same reachable controls and complete copy.
- Walkable, blocked, threat, player/reward, recovery, and boss roles pass the
  visual-profile contract validator.
- The player and objective remain locatable during maximum supported enemy
  pressure.
- Every modal has deterministic initial focus, disabled state, confirmation, and
  dismissal behavior.
- Visual changes pass `tools/validation/validate_vehicle_run.gd` and a rendered
  review at the supported viewport sizes.

## Non-Goals

- Realistic materials, dense texture detail, or ornamental borders.
- Per-screen component forks that duplicate an existing visual role.
- UI-baked screenshots used as runtime screens.
- Visual effects that obscure hostile telegraphs, collision boundaries, or the
  player's silhouette.
