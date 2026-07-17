---
type: policy
status: active
owner: BK
last_reviewed: 2026-07-17
topic: Durable product direction during the Cardborne isometric action RPG pivot
source: Owner decision on 2026-07-17 and the active pivot ExecPlan
related:
  - ./execplans/2026-07-17-isometric-action-rpg-pivot.md
  - ../docs/design/UI_VISUAL_SYSTEM.md
---

# Cardborne Pivot Direction

## Purpose

Keep future work aligned while Cardborne is rebuilt as an isometric action RPG.

## Scope

This policy covers the reset baseline and the first playable combat proof. The
active ExecPlan owns implementation order; a later accepted product spec will own
the durable gameplay contract.

## Rules

- Build a two-dimensional top-down simulation presented with isometric art. Do
  not restore platform jumping, ropes, one-way platforms, or vertical stage
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
- Keep world collision, navigation, and combat on one ground plane for the first
  proof. Visual height and Y-sort do not create hidden gameplay elevation.
- Keep cards and equipment data-driven and behavior-changing; numeric-only
  progression cannot carry the first proof.
- Use Godot 4.7 GDScript and existing project assets. Add no production dependency
  or external asset without current owner approval and license evidence.
