---
type: plan
status: active
owner: BK
created: 2026-07-17
last_reviewed: 2026-07-17
topic: Cardborne native 3D isometric action RPG foundation
scope: Playable 3D combat room through the first authored combat exchange
source: Owner correction after reviewing the prior 2D graybox
related:
  - ../Prompt.md
  - ../../docs/product/isometric_action_rpg_product_brief.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../docs/research/third_party_adoption_ledger.md
---

# Cardborne Native 3D Isometric Foundation

## Purpose

Replace the visually flat 2D proof with a real Godot 4.7 3D foundation whose
camera, collision, controls, and combat can grow into the intended isometric
action RPG without adding a second Web runtime.

## Why / Context

The first graybox proved inputs but did not resemble the accepted screen
direction. The owner explicitly allowed Three.js, Godot 3D, or safe external
sources and asked the implementation to choose. Godot native 3D keeps gameplay,
input, physics, export, and debugging in one runtime. Kenney Modular Dungeon Kit
2.1 supplies a small CC0 GLB vocabulary while Cardborne-owned materials keep the
dark drowned-foundry palette.

## Scope / Non-scope

In scope:

- one authored orthographic 3D room with a fixed isometric camera;
- real `CharacterBody3D`, `StaticBody3D`, and `Area3D` collision;
- arrow-key movement, Shift dash, Space melee, Z ranged, X interact, C potion;
- solid cover that terminates ordinary projectiles;
- one resettable target and one startup/active/recovery hazard;
- responsive viewport captures and automated behavior validation.

Not yet in scope:

- enemies, boss, cards, room transitions, procedural generation, save data;
- vertical traversal, jumping, or free camera rotation;
- final character animation, VFX, audio, or production cover models;
- a second Three.js/WebGL gameplay implementation.

## Assumptions

- Fixed orthographic presentation remains the desired readable camera model.
- Gamepad stays supported as a secondary input family; the requested keyboard
  layout is the primary visible contract.
- Imported GLB geometry owns presentation while explicit simple Godot shapes own
  collision, keeping navigation and projectile truth inspectable.

## Proposed Design

- `PivotRoot` registers semantic actions and loads one `CombatSandbox3D`.
- `Traveler3D` owns movement, facing, dash, health, potion, and action requests.
- Combat primitives own projectile, dummy, and hazard behavior separately.
- A fixed `Camera3D` looks at the room through orthographic projection.
- Kenney meshes receive one project material override; their source texture is
  retained only to keep imported GLBs valid and is not the active palette.
- The HUD communicates only current health, potion charges, action feedback, and
  the keyboard contract.

## Milestones / Tasks

- [x] Choose Godot native 3D over a separate Three.js runtime.
- [x] Verify and adopt the CC0 Kenney Modular Dungeon Kit source.
- [x] Build the authored 3D room, camera, collision, cover, and lighting.
- [x] Implement requested keyboard controls and secondary gamepad bindings.
- [x] Implement melee, ranged, dash, damage, potion, and pulse fixtures.
- [x] Remove the superseded 2D-only sandbox implementation.
- [x] Pass automated behavior and three-viewport rendered checks.
- [ ] Tune two minutes of keyboard feel with the owner.
- [ ] Replace training fixtures with the first real enemy combat exchange.

## Progress

The native 3D foundation is implemented. Automated checks cover the scene,
bindings, movement, dash invulnerability, melee, ranged impact, projectile cover,
potion charges, and hazard damage. Rendered evidence exists at 960x540, 1280x720,
and 1920x1080. The next product decision is combat feel, not engine choice.

## Next Steps

1. Run the room and record only movement, camera, dash, and attack-feel defects.
2. Make one bounded tuning pass without adding content systems.
3. Add one melee and one ranged enemy with readable attacks, then validate a
   60–90 second combat exchange before restoring cards or route flow.

## Test Plan / Verification

- `./tools/godot.ps1 --headless --path . --editor --quit`
- `./tools/godot.ps1 --headless --path . --script res://tools/validation/inspect_kenney_3d_assets.gd`
- `./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_movement_and_actions.gd`
- `./tools/godot.ps1 --path . --script res://tools/validation/capture_movement_check.gd`
- inspect 960x540, 1280x720, and 1920x1080 captures for framing, clipping, and
  threat readability.

## Rollback / Safety

- The prior 2D proof remains recoverable from commit `4f2aca7` but is not an
  alternate active runtime.
- Do not stage unrelated pre-existing `.import` modifications.
- Keep third-party files limited to the ledgered selected GLBs, shared texture,
  and license; do not import the full package by default.

## Risks

- Primitive character and cover visuals may be mistaken for final art.
- Imported visual geometry and authored collision can drift; validators should
  continue asserting collision-owned gameplay behavior.
- Orthographic depth can hide the player; future tall occluders need a fade or
  authored cutaway before larger rooms are accepted.

## Open Questions

- Does movement feel fast and direct enough at the current camera scale?
- Should ranged facing follow last movement, a keyboard aim cluster, or assisted
  target selection after the first enemy fixture exists?
- Is the first production encounter one mixed room or two shorter rooms?

## Decision Notes

- Accepted: Godot 4.7 native 3D, fixed orthographic camera, GLB assets, explicit
  collision, and requested lower-left keyboard action cluster.
- Rejected: embedding Three.js beside Godot, because it duplicates gameplay,
  input, build, and asset-loading ownership without improving this proof.

## Stop Conditions

Pause expansion if the two-minute feel review rejects the fixed isometric camera
or the keyboard action ownership. Otherwise continue only to the first real
combat exchange; do not infer approval for cards, route, boss, or persistence.
