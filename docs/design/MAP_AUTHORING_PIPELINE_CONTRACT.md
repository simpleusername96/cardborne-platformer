---
type: spec
status: active
owner: BK
last_reviewed: 2026-07-15
canonical_for: Production room-template scene, socket, anchor, and validation schema
source: Existing StageBase/component contracts, map pipeline research, and active procedural generation spec
related:
  - ./PROCEDURAL_REGION_GENERATION.md
  - ./ENEMIES_TRAPS_GIMMICKS.md
  - ../architecture/FIRST_SLICE_ARCHITECTURE.md
  - ../research/third_party_adoption_ledger.md
  - ../../.agent/execplans/2026-07-15-gameplay-validity-repair.md
---

# Map Authoring Pipeline Contract

## Purpose

Define the source format that lets rooms be authored, inspected, assembled, and
validated without returning to a monolithic script-built stage.

## Scope

The first production pipeline uses native Godot room scenes plus typed Resource
metadata. This reuses current Godot components and requires no new package.

LDtk or another editor may later become an authoring front end only after an
approval-gated spike. Any importer must produce the same local room contract; raw
external dictionaries never enter generation or gameplay code.

## Source Of Truth

Each room owns:

```text
scenes/rooms/lower_ruins/<room_id>.tscn
data/rooms/lower_ruins/<room_id>.tres
```

- The scene is source of truth for geometry, collision, visuals, and authored
  anchor nodes.
- The Resource is source of truth for IDs, roles, eligibility, sockets, budgets,
  tags, and validation expectations.
- Importers may generate either file but cannot become a runtime dependency.
- Generated Stage Plans reference room IDs and content versions, never scene paths
  copied into arbitrary gameplay data.

## Required Room Scene Shape

```text
RoomTemplate (Node2D, RoomTemplateHost.gd)
├── Terrain (Node2D)
├── OneWay (Node2D)
├── Hazards (Node2D)
├── DecorBack (Node2D)
├── DecorFront (Node2D)
├── Anchors (Node2D)
│   ├── Sockets (Node2D)
│   ├── Enemy (Node2D)
│   ├── Hazard (Node2D)
│   ├── Reward (Node2D)
│   ├── Objective (Node2D)
│   └── Recovery (Node2D)
├── CameraBounds (Area2D or authored Rect2 owner)
└── Validation (Node2D)
```

Empty anchor groups may remain empty, but required roots and metadata must exist.
Decor nodes have no gameplay collision.

## Room Template Resource

Target `RoomTemplateData` fields:

| Field | Type | Rule |
| --- | --- | --- |
| `id` | StringName | Unique lowercase snake_case ID. |
| `content_version` | int | Increment when sockets or gameplay contract changes. |
| `scene` | PackedScene | Matching authored room scene. |
| `role` | enum | One primary room role. |
| `stage_tags` | Array[StringName] | Eligible stage profiles. |
| `required_route` | bool | Whether template may carry critical path. |
| `bounds` | Rect2 | Room-local playable/camera bounds. |
| `entry_sockets` | Array[RoomSocketData] | At least one for non-start rooms. |
| `exit_sockets` | Array[RoomSocketData] | At least one for non-exit rooms. |
| `encounter_budget_min/max` | int | Allocator range. |
| `hazard_budget_min/max` | int | Allocator range. |
| `reward_budget_min/max` | int | Allocator range. |
| `allowed_enemy_tags` | Array[StringName] | Compatibility allowlist. |
| `forbidden_pairs` | Array[StringName] | Room-local pressure exclusions. |
| `estimated_seconds` | Vector2i | Expected first-clear duration range. |
| `variant_group` | StringName | Optional safe-variant family. |

Room roles:

`start`, `traversal`, `combat`, `hazard`, `choice`, `objective`, `optional`,
`safe`, `exit`.

## Socket Contract

Target `RoomSocketData` fields:

| Field | Type | Rule |
| --- | --- | --- |
| `id` | StringName | Unique within room. |
| `direction` | enum | `left`, `right`, `up`, `down`, `branch`, `rejoin`. |
| `route_role` | enum | `critical`, `optional`, `return`. |
| `local_position` | Vector2 | Stable authored position. |
| `opening_size` | Vector2 | Free collision opening. |
| `support_top` | float | Walkable surface at transition. |
| `transition_type` | enum | `seam`, `safe_gap`, `dash_gap`, `drop`, `rope`, `one_way`. |
| `required_ability` | enum | `baseline`, `double_jump`, `dash`, `crouch`, `climb`. |
| `approach_width` | float | Stable pre-transition surface. |
| `landing_width` | float | Stable post-transition surface. |
| `headroom` | float | Minimum free vertical space. |
| `recovery_id` | StringName | Recovery/reset owner if transition can fail. |

Socket compatibility requires opposite or declared branch/rejoin directions,
matching route role, compatible opening size, valid support delta, and a transition
inside shared movement limits.

## Anchor Contract

All content is placed through `StageAnchor` nodes or equivalent typed data.

| Anchor type | Required fields | Validation |
| --- | --- | --- |
| `player_spawn` | facing, safe_radius | Exactly one in start room; no active threat inside radius. |
| `enemy` | allowed_tags, support_width, patrol_width, ceiling, line_of_sight | Selected enemy must satisfy every field. |
| `hazard` | allowed_ids, warning_space, safe_zone_id, reset_id | Trap must leave documented response. |
| `reward` | reward_role, risk_tier, interaction_space | Reachable and not overlapped by collision/threat spawn. |
| `checkpoint` | facing, safe_radius, camera_id | Internal anchor ID for a stable fall-recovery point; never death retry or saved run state. |
| `switch` | objective_id, target_gate_id | Reachable before target gate; idempotent. |
| `gate` | objective_id, open_clearance | Cannot permanently block required route after completion. |
| `destructible` | allowed_ids, result_role | Optional unless reset/alternate route exists. |
| `climbable` | width, height, entry_support, exit_support | Both ends overlap stable terrain. |
| `moving_platform` | path_id, wait_pad_ids, fall_recovery | Predictable cycle and safe boarding. |
| `exit` | objective_requirements, interaction_space | Exactly one final required exit. |

Anchors are candidates, not instructions to spawn everything. The allocator may
leave optional anchors empty.

## Geometry Rules

- Critical collision uses solid support-capable terrain; visual rock body extends
  below each support top to room/world lower bound.
- Visual-only polygons have collision disabled and explicit naming.
- Hidden collision outside visible terrain is forbidden.
- One-way collision is used only for authored one-way ledges.
- A committed `drop` return uses a visible pass-through hatch on collision layer 2;
  solid terrain at the source socket is a validation failure.
- A drop return owns a supported target landing and a recovery anchor on that landing.
- A cross-room return rope reaches its lower mount and extends at least 24 px above
  the upper landing collision surface so jump-dismount can settle on the platform.
- Every approved committed return has an all-character runtime input fixture in
  addition to static socket/support validation.
- Required landings expose continuous support for their declared width.
- A crouch tunnel must prove standing collision cannot enter and crouch collision
  can enter/exit without trapping the player.
- All walls, ceilings, columns, and gates preserve the declared socket opening.
- Terrain seams between assembled rooms cannot overlap or leave accidental cracks.

## Camera And Presentation Rules

- The player sees the next required commitment before crossing the final safe
  approach point.
- Camera bounds do not reveal the entire stage or hide a required landing.
- Foreground decor cannot obscure the player, enemy tells, hazard warnings, rewards,
  or exits.
- Background and rock mass silhouette communicate traversable versus blocked space
  without debug labels.

## Runtime Boundary

Target public responsibilities:

- `RoomCatalog`: resolves and validates room IDs and versions.
- `StagePlanner`: chooses room IDs, connections, budgets, and RNG streams.
- `StagePlanValidator`: validates the full plan without instantiating presentation.
- `StageAssembler`: instantiates accepted rooms and connects sockets.
- `EncounterAllocator`: fills compatible enemy/hazard/reward anchors.
- `GenerationReport`: records all decisions and failures.

`StageAssembler` may know scene node contracts. `StagePlanner` and allocators do
not traverse arbitrary scene trees or parse external editor data.

## Authoring Workflow

1. Choose one catalog ID and its gameplay promise.
2. Block solid filled terrain and camera bounds.
3. Add sockets and verify transition surfaces.
4. Add recovery and fall-recovery (`checkpoint`) anchors before pressure anchors.
5. Add enemy/hazard/reward candidates with compatibility fields.
6. Run isolated room validation.
7. Play the room with the baseline Traveler movement/combat profile.
8. Add visuals without changing collision communication.
9. Register the Resource and reviewed timing range.
10. Add the room to the approved fixed Stage Plan before considering future random
    eligibility.

## Requirements

- Every production room can be opened and understood without generator code.
- Every generator-facing property is typed and validated.
- Shared player, enemy, hazard, reward, and fall-recovery components are
  instantiated through local project contracts.
- External editors remain replaceable behind an import adapter.
- A room with a critical validation failure cannot enter the runtime catalog.

## Acceptance Criteria

- The 29-room normal-stage catalog has matching scene/Resource pairs and unique
  IDs; Safe Intermission uses a separate scene/Resource contract.
- Each room passes isolated schema, geometry, camera, and anchor validation.
- Every required-route room is manually cleared by the baseline Traveler.
- Assembling two compatible rooms produces no collision crack, overlap, camera
  jump, unsafe spawn, or mismatched visual seam.
- Changing a socket contract increments content version and invalidates stale Stage
  Plan fixtures.
- No production script references LDtk/Tiled/importer-specific structures unless a
  later approved adapter owns that boundary.

## Non-Goals

- Mandating a third-party editor before a successful spike.
- Runtime parsing of design preview JSON.
- Procedurally generating raw collision polygons or art.
- Encoding rewards, enemy AI, or economy values directly in room scenes.

## Related

- `docs/design/PROCEDURAL_REGION_GENERATION.md`
- `docs/design/ENEMIES_TRAPS_GIMMICKS.md`
- `docs/architecture/FIRST_SLICE_ARCHITECTURE.md`
- `docs/research/foundation_resource_survey_2026-07-05.md`
- `docs/research/third_party_adoption_ledger.md`
