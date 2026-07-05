---
type: spec
status: active
created: 2026-07-05
canonical_for: map authoring pipeline, imported stage marker schema, and resolver boundary for the testbed foundation
source: docs/design/testbed-plan/06_external_foundation_replacement.md
scope: First imported side-view dungeon route and future generated-pocket socket descriptors
related:
  - ./TESTBED_REIMPLEMENTATION_CONTRACT.md
  - ./testbed-plan/06_external_foundation_replacement.md
  - ../research/external_codebase_deep_dive_2026-07-05.md
  - ../research/third_party_adoption_ledger.md
---

# Map Authoring Pipeline Contract

## Purpose

Define the first durable map authoring contract before LDtk files, imported scenes, and marker resolver code multiply. The map source should become authored/imported data, while runtime gameplay continues to use local stage, player, combat, enemy, interactable, checkpoint, and HUD contracts.

## Scope

This contract applies to the first imported side-view dungeon spike and the marker schema that future generated pockets will connect to. The first selected editor is LDtk through Godot LDtk Importer.

Fallback policy: evaluate YATI/Tiled only if the LDtk spike cannot preserve entity fields, import stable scenes, or support the required marker resolver boundary. Do not run LDtk and Tiled pipelines at the same time.

## Non-Goals

- Do not replace player, combat, enemy, checkpoint, HUD, or settings contracts.
- Do not delete the script-built `MotionTestStage` until an imported route proves parity.
- Do not import final art/audio during the pipeline spike.
- Do not let raw LDtk dictionaries or importer node details leak outside resolver files.
- Do not add procedural generated pockets until authored imported rooms work.

## Requirements

### Scale And Bounds

- Tile size: 32 px for the first LDtk spike unless a copied tileset requires a different documented size.
- Map scale: one Godot world unit equals one pixel.
- Default gameplay viewport remains 1280 x 720.
- Room bounds must be authored as room-local rectangles and described by viewport spans or ratios, not one hard-coded global map size.
- The imported proof route must be larger than one viewport and must not show the full playable map during default gameplay.
- Every room must define camera bounds or inherit validated parent bounds.

### Required Layers

| Layer | Required | Purpose |
| --- | --- | --- |
| `Terrain` | yes | Solid floors, walls, ceilings, and dungeon mass. |
| `OneWay` | yes | Drop-through or one-way platforms. |
| `Hazards` | yes | Hazard tiles or hazard placement guides. |
| `Decor` | yes | Non-colliding readability marks and placeholder dressing. |
| `Entities` | yes | Gameplay markers consumed by the resolver. |
| `Debug` | optional | Authoring notes that must not drive gameplay. |

### Collision Expectations

| Runtime concept | Collision expectation |
| --- | --- |
| Terrain | World layer, solid collision. |
| One-way platforms | OneWayPlatform layer, one-way collision, safe landing below if required. |
| Hazards | Hazard layer or hazard scene with visible warning/active/recovery where timed. |
| Interactables | Interactable layer and shared `Interactable` prompt/action path. |
| Enemies | Enemy body plus EnemyHitbox/Projectile paths as appropriate. |
| Player | Existing Player layer and hit/hurt contracts. |
| Player attacks/projectiles | Existing PlayerHitbox/Projectile paths. |

### Room Roles

Supported room roles:

- `start`
- `movement`
- `vertical`
- `combat`
- `hazard`
- `interaction`
- `destructible`
- `generated_socket`
- `exit`

Each room must declare `room_id`, `room_role`, `route_role`, and `bounds_id`. Optional rooms must declare any `required_ability` instead of blocking the critical path silently.

### Required Entity Names And Fields

| Entity | Required fields | Notes |
| --- | --- | --- |
| `PlayerSpawn` | `id`, `room_id`, `facing` | Exactly one critical-path spawn for the first imported route. |
| `Checkpoint` | `id`, `room_id`, `respawn_offset` | Respawn position must be safe and reachable. |
| `CameraBounds` | `id`, `room_id`, `rect` | Can be one per room or one validated route-level bound. |
| `RoomBounds` | `id`, `room_id`, `room_role`, `route_role`, `rect` | Defines authoring and validation bounds. |
| `EnemySpawn` | `id`, `room_id`, `enemy_type`, `spawn_cap`, `route_role` | Resolver instantiates existing enemy scenes. |
| `HazardSpawn` | `id`, `room_id`, `hazard_type`, `warning_seconds`, `route_role` | Immediate hazards use `warning_seconds: 0`. |
| `DestructibleSpawn` | `id`, `room_id`, `destructible_type`, `health`, `route_result` | Destruction must change traversal or validation state. |
| `InteractableSpawn` | `id`, `room_id`, `interactable_type`, `prompt_text`, `single_use` | Uses shared interact action and prompt path. |
| `Climbable` | `id`, `room_id`, `climbable_type`, `height_px`, `exit_side` | Entry and exit must be reachable from stable ground. |
| `OneWayPlatformMarker` | `id`, `room_id`, `width_px`, `drop_safe` | Marks authored one-way behavior when tile metadata is insufficient. |
| `ExitPortal` | `id`, `room_id`, `validation_gate_id`, `route_role` | Exit must report missing validations if locked. |
| `GeneratedSocket` | `id`, `room_id`, `socket_type`, `entry_socket`, `exit_socket`, `required_ability` | Runtime generation remains deferred until imported rooms work. |
| `ValidationGate` | `id`, `room_id`, `validation_id`, `required` | Connects authored route events to clear gating. |

### Field Enums

- `enemy_type`: `walker`, `charger`, `shooter`, `shield_guard`, `leaper`, `sentry_turret`, `summon_node`, `small_summoned_add`
- `hazard_type`: `spike_row`, `timed_poison_vent`, `fall_reset`, `crumbling_platform`
- `interactable_type`: `npc`, `switch`, `chest`, `exit`
- `destructible_type`: `breakable_wall`, `breakable_barrier`, `crate`
- `climbable_type`: `rope`, `ladder`
- `required_ability`: `none`, `dash`, `double_jump`, `extra_dash`, `climb`, `wall_deferred`
- `room_role`: same values as the supported room roles list
- `route_role`: `critical`, `optional`, `debug`, `generated_entry`, `generated_exit`
- `validation_id`: `start`, `timing`, `dash`, `climb`, `combat`, `destructible`, `hazard`, `interaction`, `generated_start`, `generated_exit`

### Socket Vocabulary

- `left`
- `right`
- `up`
- `down`
- `branch`
- `return`
- `generated_entry`
- `generated_exit`

### Passability Rules

- The critical path must be clearable by the least-mobile required profile.
- Optional branches may require advanced ability flags, but must not block clear.
- Every fall in a required route must lead to recovery, a checkpoint route, or a fall reset.
- One-way drops on the critical path must have safe landing or recovery below.
- Every room needs camera bounds.
- No required route should show the entire map at once.
- Enemy, hazard, and spawner budgets must leave safe re-entry space after respawn.
- Destructibles, crumbling platforms, and gates must reset or leave a route around any failed state.

### Resolver Boundary

The public resolver API should use project language, for example:

- `StageMarker`
- `StageImportReport`
- `resolve_stage_markers(imported_root: Node) -> StageImportReport`
- `apply_stage_markers(stage: StageBase, report: StageImportReport) -> void`

The resolver hides:

- raw LDtk dictionaries,
- importer-specific node names/classes,
- external field naming quirks,
- tile editor metadata,
- import-time placeholder entity shapes.

The resolver validates:

- missing required marker,
- unknown entity type,
- missing field,
- invalid enum,
- impossible route,
- duplicate id,
- spawn cap violation.

Critical validation failures block stage start with a readable error. Optional unknown markers produce warnings and must not crash the route.

## Acceptance Criteria

- A future map can be authored from this contract without reading resolver code.
- A future resolver can be written from this contract without opening the LDtk file by hand.
- Player, combat, enemy, and UI scripts do not parse LDtk data directly.
- The first imported proof route includes spawn, checkpoint, camera bounds, room bounds, two enemy types, one hazard, one destructible, one interactable, one climbable, one exit, and one generated socket marker.
- The imported route visually reads as a side-view dungeon with floors, walls, ceilings, lower/bottom space, and room-like pockets.

## Related

- `docs/design/TESTBED_REIMPLEMENTATION_CONTRACT.md`
- `docs/design/testbed-plan/06_external_foundation_replacement.md`
- `docs/research/external_codebase_deep_dive_2026-07-05.md`
- `docs/research/third_party_adoption_ledger.md`
