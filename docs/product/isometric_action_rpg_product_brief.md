---
type: spec
status: active
owner: BK
created: 2026-07-17
last_reviewed: 2026-07-18
canonical_for: Cardborne five-to-eight-minute isometric action RPG proof behavior
scope: Direct-start combat proof from movement room through Slime King and result
source: ../../.agent/execplans/2026-07-17-rasterized-3d-presentation.md
related:
  - ../../.agent/Prompt.md
  - ../../.agent/execplans/2026-07-17-native-3d-isometric-foundation.md
  - ../../.agent/execplans/2026-07-17-rasterized-3d-presentation.md
  - ../../.agent/execplans/2026-07-17-traveler-lateral-dash-presentation.md
  - ../design/UI_VISUAL_SYSTEM.md
---

# Cardborne Isometric Action RPG Proof

## Purpose

Define the smallest playable build that can show whether responsive isometric
combat is a better foundation for Cardborne than the retired platformer.

## Scope

The proof starts directly in play and follows one deterministic route:
Movement Check → Foundry Approach → one three-card reward → Pump Gallery →
Pressure Vault → Slime King → Run Result. It supports keyboard/mouse and gamepad,
uses one traversable ground elevation, and presents a native 3D world through a
fixed-angle, bounded-follow orthographic isometric camera. Gameplay remains 3D,
while the accepted presentation is a hybrid of 2D raster background/surface art
and camera-facing actor sprites.

## Requirements

### Player control

- Keyboard uses arrow-key movement, Space dash, Left Shift melee, `Z` ranged,
  held `X` guard, `C` potion, `V` interact, and Esc pause. Non-zero movement sets
  persistent combat facing; idle preserves it.
- Gamepad uses left-stick movement, south-face dash, LB guard, RB melee, RT
  ranged, north-face potion, west-face interact, and Menu pause. Right-stick aim
  remains deferred.
- Melee and ranged resolve bounded soft assistance only when the attack starts.
  Candidates must be targetable, inside that attack's range and cone, and have
  unobstructed line of sight. With no candidate, the attack follows exact combat
  facing; later movement cannot bend a committed hit or projectile.
- Ground movement has normalized diagonals, `6 m/s` maximum speed,
  `28 m/s²` acceleration, and `34 m/s²` braking.
- Dash moves at `14 m/s` for `0.18 s`, is invulnerable for its first `0.10 s`,
  recovers for `0.12 s`, and reuses after `0.55 s` from start.
- Guard reduces incoming damage by 65% while held, slows movement to 45%, and
  prevents attacks and dash until released.
- Melee is an explicit buffered two-hit sword chain. Ranged is a separate
  straight projectile that stops on world collision and has no ammunition.
- The Traveler has 100 health and three potion charges. A potion heals 35% after
  a committed `0.45 s` use; damage before the heal cancels without consuming it.

### Encounters and route

- Movement Check contains cutaway walls, two projectile-blocking cover blocks,
  three resettable target fixtures, and one timed damage pulse. It contains no
  enemy AI or reward.
- The proof room has a 19.8×19.8 m walkable footprint and never fits completely
  in one frame. Its fixed-angle camera follows the Traveler on X/Z, clamps its
  center to ±3.5 m, and keeps camera-facing walls below the Traveler silhouette.
- Foundry Approach is the only deliberate arena clear and contains five enemies
  across two fixed waves using Pursuer, Shooter, and Controller roles.
- Pump Gallery completes after two one-second activations even if enemies live.
- Pressure Vault completes after 45 seconds even if enemies live.
- One reward appears after Foundry Approach: Dash Wake, Perfect Punish, or Split
  Focus. Each effect changes a visible behavior and cannot trigger itself.
- Slime King has lane charge, landing slam, poison safe bands, and pressure-node
  patterns. Every damaging pattern has startup, active, recovery, and safe ground.

### Run and UI

- Run, card, health, and potion state are memory-only. Retry restores the current
  room snapshot; Replay creates a clean session.
- Only master and SFX volume persist in
  `user://cardborne_pivot_settings.cfg`.
- Required surfaces are gameplay HUD, objective/boss band, card choice,
  pause/audio settings, and result replay/exit.
- The proof has no main menu, minimap, Forge, merchant, loadout, economy,
  equipment inventory, profile, procedural room graph, or permanent progression.
- Art and UI follow the flat-color, borderless, low-noise drowned-foundry contract
  in `docs/design/UI_VISUAL_SYSTEM.md`.
- The current arena keeps 3D geometry and collision, uses a project-authored
  same-hue raster albedo through world-triplanar projection, and displays the
  approved Flooded Works panel only as a non-interactive far background.
- Traveler depth/diagonal locomotion uses two authored camera-relative
  directions plus horizontal mirroring. Pure screen-left/right movement uses a
  dedicated side-profile atlas, mirrored for left. All four-frame walk cycles
  advance from actual ground distance, not a free-running animation clock.
- Dash selects a dedicated compress/launch/glide/recovery atlas. Presentation
  emits non-colliding world-stationary raster afterimages every 0.65 m that fade
  over 0.16 s; those images never affect movement, invulnerability, or collision.
- Melee, ranged, and guard each select a dedicated full-body `Sprite3D` atlas;
  the sword, bow, and shield are painted into those poses, and the ranged bolt
  is also raster art. Hidden primitive equipment is never gameplay feedback.
- Animation remains presentation only. Movement, hit/release timing, targeting,
  cover, damage, and collision stay authoritative in gameplay code.

## Acceptance Criteria

- The direct-start route completes from Movement Check through result, then
  replays immediately without stale card, potion, enemy, objective, or boss state.
- Movement, melee, ranged, dash, guard, potion, damage, cover, and objectives
  expose their exact state and produce the same intent on both supported input
  families.
- Pure screen-left/right movement visibly selects the profile gait, and an
  accepted Space dash visibly selects the dash atlas and leaves a short raster
  trail without changing its authoritative displacement or invulnerability.
- Ordinary projectiles terminate on solid cover; no visual height changes
  collision, navigation, or damage truth.
- The Traveler's world-space front notch, short-lived assisted-target marker,
  and attack direction agree without a persistent lock-on or trajectory line.
- Pump Gallery and Pressure Vault can complete with at least one enemy alive.
- All boss damage has a readable startup, active window, and recovery.
- One successful run lasts five to eight minutes at the locked encounter counts.
- The built Web artifact passes the plan's automated, viewport, focus, and
  continuous-play gates before an owner `Go`, `Iterate`, or `No-go` decision.

## Non-Goals

- Restoring platform jumping, ropes, one-way platforms, or old stage geometry.
- Free camera rotation, gameplay elevation, contextual replacement of explicit
  attacks, or animation-owned movement and damage.
- Broad content, randomized rooms, economy, persistent progression, or unverified
  external packages and assets.

## Related

- [Active raster presentation plan](../../.agent/execplans/2026-07-17-rasterized-3d-presentation.md)
- [Completed native 3D foundation](../../.agent/execplans/2026-07-17-native-3d-isometric-foundation.md)
- [Traveler lateral walk and dash plan](../../.agent/execplans/2026-07-17-traveler-lateral-dash-presentation.md)
- [Pivot direction](../../.agent/Prompt.md)
- [UI visual system](../design/UI_VISUAL_SYSTEM.md)
