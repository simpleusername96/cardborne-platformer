---
type: record
status: active
owner: BK
last_reviewed: 2026-07-22
topic: Cardborne humanoid isometric action RPG pivot state recorded on 2026-07-18
source: Owner pivot decision, repository reset, and active ExecPlan
related:
  - ./execplans/2026-07-18-flooded-works-floor1-map-enemies.md
  - ../docs/README.md
  - ../docs/product/vehicle_content_expansion_spec.md
  - ../docs/design/UI_VISUAL_SYSTEM.md
---

# Project Documentation Memory

> Historical boundary: this record describes the humanoid proof state captured
> on 2026-07-18. It does not describe the current vehicle main scene. Use
> `../docs/README.md` for current document authority and known conflicts.

## Context

The former side-view action-platform implementation was structurally complete but
did not meet the owner's fun target. After comparing its play with Bastion and
Hades, the owner chose to reset the runtime and explore an isometric action RPG.

## Decision

- The retired platformer runtime, typed content, scenes, stage data, validators,
  release records, and obsolete plans were removed on the pivot branch.
- Cardborne now targets a Godot-native 3D world with fixed orthographic
  isometric presentation and one traversable ground elevation for the proof.
- The accepted art style and all project-owned art remain available.
- Traveler, weapons, defense, cards, equipment, forging, merchant, run/reward,
  persistence, and Slime King survive as product identities only; none of their
  deleted runtime behavior is implicitly accepted.
- `docs/product/isometric_action_rpg_product_brief.md` is the active proof
  behavior source. `.agent/execplans/2026-07-18-flooded-works-floor1-map-enemies.md`
  is the active implementation plan for the connected Floor 1 map/enemy slice.

## Rationale

A clean runtime prevents platform movement, room geometry, contextual attacks,
and legacy validation assumptions from shaping the new combat by accident. Git
history retains the prior implementation if a specific algorithm or asset mapping
later proves worth recovering.

## Consequences

- The project boots directly into a playable native 3D combat foundation.
- The first implementation milestone remains a focused combat sandbox rather
  than restoration of menus, persistence, or the former complete run.
- Old screenshots and world assets are references, not geometry or collision
  sources for the new game.
- The pre-pivot runtime can be inspected at commit `7cc069c` without reintroducing
  it into the active tree.

## State Recorded on 2026-07-18

- Active branch: `master`.
- Runtime reset and research-backed plan: completed on 2026-07-17.
- The native 3D Movement Check is playable: `CombatSandbox3D` contains an
  imported CC0 dungeon room, explicit boundary collision, two cover blocks, a
  damageable dummy, a telegraphed pulse, and the Traveler.
- Traveler arrow-key input, movement, facing, dash, damage-reducing guard, melee,
  solid-blocked ranged shot, three-charge potion, damage, pause, reset, action
  trace, and bounded camera are live.
- The automated native 3D gate and 960x540, 1280x720, and 1920x1080 rendered
  captures pass, with additional 1280x720 guard and pause-state evidence. The
  Web release exports and boots from the manager-provided `codex` lane with
  focused action input and no browser console warning or error.
  Dedicated lateral locomotion, dash presentation/afterimages, raster melee,
  ranged, guard, and projectile presentation are also integrated.
- The 2026-07-18 map/enemy pre-plan audit confirmed that no enemy AI, navigation,
  room flow, boss runtime, drop runtime, audio stream, audio bus layout, or
  settings store exists yet. The new active plan adds those in bounded phases.
- Three Floor 1 visual direction images and a separate future progression/upgrade
  specification now document the intended connected rooms, enemy/prop family,
  and post-proof reward ownership.
- Retained authority: root `AGENTS.md`, `.agent/Prompt.md`, the active ExecPlan,
  `docs/product/isometric_action_rpg_product_brief.md`, and
  `docs/design/UI_VISUAL_SYSTEM.md` for art direction.

## Verification

Use these focused Phase 1 checks:

- `./tools/godot.ps1 --path . --headless --import`
- `./tools/godot.ps1 --path . --headless --script res://tools/validation/validate_movement_and_actions.gd`
- `./tools/godot.ps1 --path . --script res://tools/validation/capture_movement_check.gd`
- `./tools/export_web.ps1`

The capture command intentionally uses the real display driver. It writes ignored
review evidence under `build/validation/` at the three supported viewports.
