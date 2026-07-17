---
type: policy
status: active
owner: BK
last_reviewed: 2026-07-17
topic: Durable product direction during the Cardborne isometric action RPG pivot
source: Owner decision on 2026-07-17 and the active pivot ExecPlan
related:
  - ./execplans/2026-07-17-native-3d-isometric-foundation.md
  - ../docs/design/UI_VISUAL_SYSTEM.md
---

# Cardborne Pivot Direction

## Purpose

Keep future work aligned while Cardborne is rebuilt as an isometric action RPG.

## Scope

This policy covers the native 3D foundation and the first playable combat proof. The
active ExecPlan owns implementation order; a later accepted product spec will own
the durable gameplay contract.

## Rules

- Build the proof in Godot native 3D with a fixed orthographic isometric camera.
  Do not restore platform jumping, ropes, one-way platforms, or vertical stage
  assembly from Git history.
- Preserve the accepted flat-color, borderless, low-noise drowned-ruin art
  direction and the existing project-owned production art as reference material.
- Preserve these product identities, but redesign their runtime contracts:
  Traveler, explicit melee and ranged tools, defense, cards, equipment, forging,
  merchants, run rewards, persistent progression, and Slime King.
- Prove responsive movement and combat in a short authored slice before rebuilding
  the full economy, procedural generation, multiple regions, or broad content.
- Use explicit player intent. No contextual system may silently replace a
  requested melee, ranged, defensive, or movement action with another action.
- Do not make exterminating every enemy the universal room-completion rule.
  Encounters may use priority-target, survival, activation, escort, escape, or
  optional-combat objectives when they are clearly communicated.
- Keep traversable collision, navigation, and combat on one ground elevation for
  the first proof. 3D visual height must not create hidden gameplay elevation.
- Keep cards and equipment data-driven and behavior-changing; numeric-only
  progression cannot carry the first proof.
- Use Godot 4.7 GDScript. External assets require current owner approval, an
  adoption-ledger entry, a copied license, and a source that permits commercial
  modification and redistribution; prefer small selected imports over packages.
- Primary keyboard actions are arrows for movement, Space dash, Shift guard,
  Z melee, X ranged, C potion, and Esc pause. Gamepad remains secondary.
