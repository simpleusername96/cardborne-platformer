---
type: spec
status: active
owner: BK
last_reviewed: 2026-07-12
canonical_for: First-run stage profiles, terrain vocabulary, room catalog, and constrained generation rules
source: Existing procedural region prototype, movement metrics, rock-mass feedback, and Cardborne Game Blueprint
related:
  - ../product/2d_platform_action_card_game_prd.md
  - ./MAP_AUTHORING_PIPELINE_CONTRACT.md
  - ./ENEMIES_TRAPS_GIMMICKS.md
  - ../architecture/FIRST_SLICE_ARCHITECTURE.md
---

# Procedural Region Generation

## Purpose

Define how the Lower Ruins varies by seed while remaining intentionally authored,
traversable, readable, and fun. Generation chooses compatible authored content; it
does not draw arbitrary platforms.

## Scope

This specification covers the three normal stages. The Giant Slime King arena is
authored and excluded from procedural generation.

## Design Principle

```text
seed + content version
 -> stage profile
 -> mission/room graph
 -> room-template selection
 -> socket resolution
 -> encounter/hazard/reward allocation
 -> full-stage validation
 -> bounded retry or curated fallback
 -> Stage Plan and Generation Report
```

The output is a plan that runtime instantiates. It is never a bag of random world
coordinates.

## Terrain Vocabulary

The visual and collision language follows the owner's rock-mass direction:

- Primary terrain is a solid rock mass whose visible body continues below its
  walkable top to the lower world bound.
- Adjacent masses may have different top heights and widths.
- A separated mass must expose a real traversable gap, recovery floor, or fall
  reset; it cannot be a visual-only separation over hidden collision.
- Required corridors preserve enough body space for standing, jumping, dashing,
  and the declared crouch segment.
- One-way ledges are secondary traversal, not substitutes for an unsupported
  critical floor.
- Ceilings, columns, arches, and foreground decoration never contradict collision.

Supported terrain patterns:

| Pattern | Purpose | Critical-path rule |
| --- | --- | --- |
| `mass_seam` | Continuous walking across different rock heights. | Horizontal gap 0; vertical step within shared ledge limit. |
| `safe_gap` | Basic jump commitment. | Gap <= conservative single-jump limit; landing >= 220 px. |
| `dash_gap` | Late-stage shared dash check. | Explicitly tagged; stable 260 px approach and landing; no hazard on landing. |
| `rise_steps` | Ascending mass sequence. | Each rise independently valid; no camera-hidden landing. |
| `drop_basin` | Downward route with recovery. | Landing visible before commitment; return or forward route guaranteed. |
| `split_level` | Upper risk route over lower safe route. | Lower route always completes the room. |
| `rope_shaft` | Vertical climb with side ledges. | Rope entry and exit touch stable support; fall recovery below. |
| `crouch_tunnel` | Short clearance change. | Crouch collider validated; no enemy body-block inside. |
| `one_way_stack` | Controlled vertical repositioning. | Drop destination safe; never traps player below the exit. |
| `moving_bridge` | Timing challenge. | Safe waiting pads, deterministic cycle, fall recovery. |

## Movement-Derived Constraints

At generation time, calculate route limits from every base profile with
`MovementMetrics.route_limits_for_profiles`. Use the minimum accepted values.

| Constraint | Rule |
| --- | --- |
| Required gap | <= `max_required_gap`; ordinary rooms target <= 65% of that limit. |
| Required rise | <= `max_required_ledge`; ordinary rooms target <= 72% of that limit. |
| Landing width | >= 220 px after a required jump; >= 180 px for low-pressure optional landings. |
| Approach width | >= 180 px before a required jump; >= 260 px before a required dash gap. |
| Standing headroom | Player standing height + 20 px across required movement lanes. |
| Crouch headroom | Crouched height + 12 px and explicit `crouch_required` tag. |
| Rope entry/exit | Stable support overlaps climb volume by >= 24 px. |
| Enemy support | Full enemy footprint plus 24 px margin on each side. |
| Safe entry | First 240 px of a room cannot contain active damage or immediate aggro. |
| Checkpoint safety | No enemy, projectile lane, trap, or moving platform can hit spawn during recovery. |

Optional routes may use up to the full shared envelope. They cannot require
equipment, cards, mastery, Archer Threadline, Assassin Smoke Step, or extra dash
charges.

## Stage Profiles

### `ruin_approach`

- 6 required rooms, 1 optional branch.
- Required roles: start, traversal, light combat, route choice, final combat, exit.
- Enemies: Walker, Charger; one Shooter only after its teaching lane.
- Hazards: safe gaps, visible spike rows, one optional rope shaft.
- Encounter budget per combat room: 1-3.
- Hazard budget per room: 0-1.
- Recovery: checkpoint after room 3 or before final combat.
- Fun target: confidence and first card anticipation, not attrition.

### `flooded_works`

- 7 required rooms, 1-2 optional branches, one rest/forge room.
- Required roles in order: start, traversal, timing hazard, combat, route choice,
  final escalation combat, terminal rest/forge exit.
- Enemies: Walker, Charger, Shooter, Leaper.
- Hazards: poison vent, crumbling platform, moving bridge, drop basin.
- Encounter budget per combat room: 2-5.
- Hazard budget per room: 0-2, but only one new pressure type per teaching room.
- Recovery: checkpoint before final escalation; rest/forge opens only after all
  Stage 2 objectives are clear.
- Fun target: decide whether to spend for safety or preserve coins for build power.

### `broken_sanctum`

- 8 required rooms, 2 optional branches.
- Required roles: start, mixed combat, gate loop, hazard combat, optional cache,
  checkpoint, final mixed encounter, exit.
- Enemies: full six-enemy normal roster; Sentry and Shield Guard require compatible
  room geometry.
- Hazards: all core hazards and gimmicks except unapproved crushing blocks.
- Encounter budget per combat room: 4-7.
- Hazard budget per room: 1-2.
- Recovery: no more than three pressure rooms between safe recovery beats.
- Fun target: test the assembled build through combinations, not larger health bars.

## Authored Room Catalog

The first run uses these 18 templates. Exact geometry lives in scenes; this table
locks purpose, stage eligibility, and required anchors.

| ID | Role | Stages | Terrain/gameplay promise | Required anchors |
| --- | --- | --- | --- | --- |
| `lr_start_shelf` | start | 1-3 | Wide continuous mass, no pressure, one visible next goal. | player spawn, camera, right exit, recovery. |
| `lr_rise_steps` | traversal | 1-3 | Three filled masses rise within ordinary ledge limits. | entry/exit sockets, three landings. |
| `lr_lower_upper_choice` | choice | 1-3 | Lower safe path and upper optional reward route rejoin. | branch/rejoin, reward, lower recovery. |
| `lr_rope_shaft` | traversal | 1-2 | Rope connects lower mass to two stable side ledges. | rope, lower recovery, top exit. |
| `lr_broken_bridge` | traversal | 1-3 | One reviewed safe gap; lower basin prevents void confusion. | jump approach/landing, fall reset or recovery. |
| `lr_patrol_gallery` | combat | 1-3 | Long mass with small elevation change for basic melee. | 3 ground enemy anchors, safe entry, clear gate. |
| `lr_charge_lane` | combat | 1-3 | Wide telegraphed lane with two escape ledges. | charger anchor, turn bounds, escape pads. |
| `lr_shooter_overlook` | combat | 1-3 | Lower approach and upper ranged perch with cover column. | shooter anchor, ground anchors, cover, line-of-sight tags. |
| `lr_shield_choke` | combat | 3 | Two-level arena lets player cross behind Shield Guard. | shield anchor, flank route, no narrow body block. |
| `lr_leaper_basin` | combat | 2-3 | Basin and side ledges expose leap arc and landing punish. | leaper anchor, arc clearance, side recovery. |
| `lr_poison_timing` | hazard | 2-3 | Alternating warned floor bands with permanent safe pad. | vent groups, safe zone, cycle phase. |
| `lr_crumble_crossing` | hazard | 2-3 | Crumbling ledges over recoverable lower mass. | platform anchors, lower route, respawn-safe exit. |
| `lr_gate_switch_loop` | objective | 2-3 | Switch opens a visible gate after a short loop; no key search. | switch, gate, return path, objective state. |
| `lr_destructible_cache` | optional | 1-3 | Readable breakable wall protects material/equipment chance. | destructible, cache reward, optional branch. |
| `lr_material_cavern` | optional | 1-3 | Low-pressure rope/drop branch with material node. | material node, branch/rejoin, recovery. |
| `lr_rest_forge` | safe | 2 | Terminal safe room hosts the stage card, heal, forge, and exit to Stage 3. | rest spawn, forge, shop, stage exit, no hazard. |
| `lr_sentry_crossfire` | combat | 3 | Cover and two elevations prevent unavoidable projectile overlap. | sentry anchors, cover, safe entry, projectile limits. |
| `lr_exit_ascent` | exit | 1, 3 | Final ascent to a clearly framed gate on a broad mass. | checkpoint, final encounter anchors, exit portal. |

Templates may expose cosmetic or safe authored variants, but a variant cannot
change sockets or movement classification without a new template ID/version.

## Graph Rules

- A Stage Plan has one start and one terminal exit anchor. Stage 2's anchor lives
  in its terminal rest/forge room.
- Required rooms form a directed clear path; optional branches rejoin before exit.
- Stage 1 includes exactly one optional branch; Stages 2-3 include at least one.
- The same room template cannot appear twice in one Stage Plan unless its contract
  allows repetition and a different authored variant is selected.
- Two combat rooms with the same primary enemy lesson cannot be adjacent.
- A new hazard appears once without simultaneous high encounter pressure before it
  can appear in a mixed room.
- Rest/forge cannot be first, last, or adjacent to another safe room.
- Final combat cannot use a pressure combination unseen earlier in the run.

## Encounter, Hazard, And Reward Allocation

Allocation uses authored anchors with compatibility tags.

```text
room budget
 -> reserve teaching/recovery space
 -> select primary pressure role
 -> select compatible support role
 -> select hazard only if response space remains
 -> place reward relative to risk
 -> validate caps and completion state
```

- Optional reward value rises with route and encounter risk.
- Required exits and switches cannot be body-blocked by living enemies after an
  encounter is considered complete.
- Physics pickups are convenience visuals; stage clear never depends on collecting
  every loose pickup.
- Reward RNG uses a stream separate from room selection so retries cannot reroll
  already committed room topology.

## Determinism And Retry

- Store `run_seed`, `stage_index`, `content_version`, and named RNG stream seeds.
- Same inputs produce byte-equivalent Stage Plan data.
- Validation failure derives a deterministic retry seed and records the reason.
- Maximum three assembly retries, then load a curated known-good Stage Plan for
  that profile.
- Fallback use is visible in the Generation Report and telemetry, never to the
  player as a debug overlay.

## Validation Pipeline

Reject a Stage Plan when any required check fails:

1. IDs, schema versions, and references resolve.
2. Room graph reaches every required objective and exit in order.
3. Socket directions, elevations, and bounds match.
4. Critical surfaces form a traversable collision path.
5. Required jumps, rises, landings, headroom, crouch, ropes, and one-way drops fit
   the least-mobile shared envelope.
6. Falls have recovery, reset, or safe checkpoint behavior.
7. Enemy/hazard anchors have support, clearance, response space, and active caps.
8. Safe entry, checkpoint, switch, reward, and exit zones remain unobstructed.
9. Camera bounds frame commitments before the player must make them.
10. Encounter, hazard, reward, and duration budgets remain within profile limits.

## Requirements

- Runtime consumes a validated Stage Plan, not raw design JSON or editor metadata.
- Generation logic is independent from scene instantiation.
- Every content selection is explainable in a Generation Report.
- Room content is authored to a contract and can be tested independently.
- No accepted stage relies on debug flags or testbed geometry.

## Acceptance Criteria

- Three curated seeds per profile are manually reviewed and fun to replay.
- A 1,000-seed property sweep per profile accepts only valid plans or documented
  fallbacks.
- Same seed/content version reproduces room order, encounters, hazards, and rewards.
- Every base character clears the curated seed set with no movement upgrade.
- No unsupported enemy, floating marker, hidden collision, blocked exit, unsafe
  checkpoint, or unrecoverable required fall appears.
- Different seeds change at least room order or optional branch plus encounter
  allocation without changing the stage's teaching job.

## Non-Goals

- Per-tile noise, arbitrary platform scattering, infinite levels, or random boss
  arenas.
- Metroidvania ability locks or character-exclusive critical routes.
- Generating art, collision, enemy AI, or reward rules from prose at runtime.
- Treating mathematical clearability as proof that a room is enjoyable.

## Related

- `docs/product/2d_platform_action_card_game_prd.md`
- `docs/design/MAP_AUTHORING_PIPELINE_CONTRACT.md`
- `docs/design/ENEMIES_TRAPS_GIMMICKS.md`
- `scripts/player/MovementMetrics.gd`
- `data/design/first_slice/procedural_region_rules.json`
