---
type: spec
status: active
owner: BK
created: 2026-07-17
last_reviewed: 2026-07-17
canonical_for: Cardborne five-to-eight-minute isometric action RPG proof behavior
scope: Direct-start combat proof from movement room through Slime King and result
source: ../../.agent/execplans/2026-07-17-isometric-action-rpg-pivot.md
related:
  - ../../.agent/Prompt.md
  - ../../.agent/execplans/2026-07-17-isometric-action-rpg-pivot.md
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
uses one top-down collision plane, and presents the world with isometric 2D art.

## Requirements

### Player control

- Keyboard/mouse uses `WASD`, mouse aim, LMB melee, RMB ranged, Space dash,
  `E` interact, `Q` potion, and Esc pause.
- Gamepad uses left-stick movement, right-stick aim, RB melee, RT ranged,
  south-face dash, west-face interact, north-face potion, and Menu pause.
- Ground movement has normalized diagonals, `220 px/s` maximum speed,
  `1600 px/s²` acceleration, and `2000 px/s²` braking.
- Dash moves at `520 px/s` for `0.18 s`, is invulnerable for its first `0.10 s`,
  recovers for `0.12 s`, and reuses after `0.55 s` from start.
- Melee is an explicit buffered two-hit sword chain. Ranged is a separate
  straight projectile that stops on world collision and has no ammunition.
- The Traveler has 100 health and three potion charges. A potion heals 35% after
  a committed `0.45 s` use; damage before the heal cancels without consuming it.

### Encounters and route

- Movement Check contains walls, two cover blocks, a resettable dummy, and one
  timed damage pulse. It contains no enemy AI or reward.
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

## Acceptance Criteria

- The direct-start route completes from Movement Check through result, then
  replays immediately without stale card, potion, enemy, objective, or boss state.
- Movement, melee, ranged, dash, potion, damage, cover, and objectives expose
  their exact state and produce the same intent on both supported input families.
- Ordinary projectiles terminate on solid cover; no visual height changes
  collision, navigation, or damage truth.
- Pump Gallery and Pressure Vault can complete with at least one enemy alive.
- All boss damage has a readable startup, active window, and recovery.
- One successful run lasts five to eight minutes at the locked encounter counts.
- The built Web artifact passes the plan's automated, viewport, focus, and
  continuous-play gates before an owner `Go`, `Iterate`, or `No-go` decision.

## Non-Goals

- Restoring platform jumping, ropes, one-way platforms, or old stage geometry.
- True 3D, gameplay elevation, contextual replacement of explicit attacks, or
  animation-owned movement and damage.
- Broad content, randomized rooms, economy, persistent progression, or external
  packages and assets.

## Related

- [Active execution plan](../../.agent/execplans/2026-07-17-isometric-action-rpg-pivot.md)
- [Pivot direction](../../.agent/Prompt.md)
- [UI visual system](../design/UI_VISUAL_SYSTEM.md)
