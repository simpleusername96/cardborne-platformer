---
type: spec
status: active
owner: BK
last_reviewed: 2026-07-15
canonical_for: First-run stage profiles, terrain vocabulary, room catalog, and constrained generation rules
source: Existing procedural region prototype, movement metrics, rock-mass feedback, and Cardborne Game Blueprint
related:
  - ../product/2d_platform_action_card_game_prd.md
  - ./MAP_AUTHORING_PIPELINE_CONTRACT.md
  - ./ENEMIES_TRAPS_GIMMICKS.md
  - ../architecture/FIRST_SLICE_ARCHITECTURE.md
  - ../../.agent/execplans/2026-07-15-gameplay-validity-repair.md
---

# Procedural Region Generation

## Purpose

Define the constraints a future Lower Ruins random planner must satisfy while
remaining intentionally authored, traversable, readable, and fun. Generation
chooses compatible authored content; it does not draw arbitrary platforms.

Current production does not vary normal-stage topology by run seed. It loads one
versioned approved Stage Plan per region while the complete gameplay loop is tuned.
The planner and its property tests remain dormant implementation evidence; this
specification governs later re-entry rather than the current player-facing path.

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
 -> encounter roles + enemy archetypes + stage variants
 -> hazard/reward allocation
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
| Fall-recovery safety | No enemy, projectile lane, trap, or moving platform can hit spawn during recovery. |

Optional routes may use up to the full shared envelope. They cannot require
equipment, cards, passive Spirit effects, or extra dash charges.

## Stage Profiles

### `ruin_approach`

- 8 required rooms, 1 optional branch.
- Required roles: start, traversal, light combat, route choice, final combat, exit.
- Enemies: Walker, Charger; one Shooter only after its teaching lane.
- Hazards: safe gaps, visible spike rows, one optional rope shaft.
- Encounter budget per combat room: 1-3.
- Hazard budget per room: 0-1.
- Recovery: fall-recovery point after room 3 or before final combat.
- Fun target: confidence and first card anticipation, not attrition.

### `flooded_works`

- 7 required rooms, 1 optional branch, and no in-stage merchant or Forge.
- Required roles in order: start, traversal, timing hazard, combat, route choice,
  final escalation combat, terminal exit.
- Enemies: Walker, Charger, Shooter, Leaper.
- Hazards: poison vent, crumbling platform, moving bridge, drop basin.
- Encounter budget per combat room: 2-5.
- Hazard budget per room: 0-2, but only one new pressure type per teaching room.
- Recovery: fall-recovery point before final escalation. The separate Safe
  Intermission opens after Stage clear and card reward.
- Fun target: decide whether to spend for safety or preserve coins for build power.

### `broken_sanctum`

- 9 required rooms, 2 optional branches.
- Required roles: start, mixed combat, gate loop, hazard combat, optional cache,
  fall recovery, final mixed encounter, exit.
- Enemies: full six-enemy normal roster; Sentry and Shield Guard require compatible
  room geometry.
- Hazards: all core hazards and gimmicks except unapproved crushing blocks.
- Encounter budget per combat room: 4-7.
- Hazard budget per room: 1-2.
- Recovery: no more than three pressure rooms between safe recovery beats.
- Fun target: test the assembled build through combinations, not larger health bars.

## Authored Room Catalog

The production run uses 29 normal-stage templates. Gameplay archetypes such as
choice, choke, timing hazard, and cache are shared design language; a different
socket, geometry, or anchor contract receives a distinct runtime ID.

| Catalog | Count | Runtime members |
| --- | ---: | --- |
| Lower Ruins / Ruin Approach | 10 | `lr_start_shelf`, `lr_rise_steps`, `lr_broken_bridge`, `lr_patrol_gallery`, `lr_charge_lane`, `lr_shooter_overlook`, `lr_lower_upper_choice`, `lr_destructible_cache`, `lr_material_cavern`, `lr_exit_ascent` |
| Flooded Works | 9 | `fw_flooded_entry`, `fw_rope_shaft`, `fw_poison_timing`, `fw_crumble_crossing`, `fw_leaper_basin`, `fw_pump_gallery`, `fw_lower_upper_choice`, `fw_sunken_cache`, `fw_exit_shelter` |
| Broken Sanctum | 11 | `bs_breach_entry`, `bs_shield_choke`, `bs_fractured_gallery`, `bs_sentry_crossfire`, `bs_gate_switch_loop`, `bs_volatile_nave`, `bs_twin_reliquary_choice`, `bs_recovery_cloister`, `bs_material_crypt`, `bs_reliquary_cache`, `bs_exit_ascent` |

Broken Sanctum's choice room owns two independent branch/return socket pairs. Its
shield room owns a flank route, its crossfire room owns two independent cover
zones, and its gate loop owns an optional moving-platform route with safe wait
pads and fall recovery. These are authored geometry contracts, not allocator
exceptions.

The existing `fw_rest_forge` room remains migration material; production uses the
standalone Safe Intermission shell instead. It is not eligible for a normal
combat-stage plan. Normal-stage exit shelters contain no merchant or Forge.

Templates may expose cosmetic or safe authored variants, but a variant cannot
change sockets or movement classification without a new template ID/version.

## Graph Rules

- A Stage Plan has one start and one terminal exit anchor. Safe Intermission is a
  separate scene reached only after Stage clear and card reward.
- Required rooms form a directed clear path; optional branches rejoin before exit.
- Stages 1-2 include exactly one optional branch in the first run; Stage 3 includes
  exactly two. The planner supports bounded profile ranges for future catalogs.
- The same room template cannot appear twice in one Stage Plan unless its contract
  allows repetition and a different authored variant is selected.
- Two combat rooms with the same primary enemy lesson cannot be adjacent.
- A new hazard appears once without simultaneous high encounter pressure before it
  can appear in a mixed room.
- Merchant and Forge anchors are invalid in every normal combat-stage plan.
- Final combat cannot use a pressure combination unseen earlier in the run.

## Encounter, Hazard, And Reward Allocation

Allocation uses authored anchors with compatibility tags.

```text
room budget
 -> reserve teaching/recovery space
 -> select primary pressure role
 -> select compatible support role
 -> select compatible enemy archetype
 -> select exact stage-eligible variant through enemy_variant RNG
 -> select hazard only if response space remains
 -> place reward relative to risk
 -> validate caps and completion state
```

- Optional reward value rises with route and encounter risk.
- Room tags select pressure roles, not concrete enemy scenes. The allocator chooses
  an archetype first, then a stage-eligible variant that satisfies the tuning
  profile and authored anchor geometry.
- A Stage Plan stores both `archetype_id` and `variant_id`, exact budget cost, anchor,
  and resolved content version. Runtime never rolls another combat value.
- Required exits and switches cannot be body-blocked by living enemies after an
  encounter is considered complete.
- Physics pickups are convenience visuals; stage clear never depends on collecting
  every loose pickup.
- Reward RNG uses a stream separate from room selection so retries cannot reroll
  already committed room topology.

## Deferred Generation Determinism And Assembly Retry

- Store `run_seed`, `stage_index`, `content_version`, and named RNG stream seeds,
  including separate `encounter` and `enemy_variant` streams.
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
6. Falls have recovery, reset, or safe fall-recovery behavior.
7. Enemy archetype/variant/tuning references resolve; exact variant stats preserve
   safety bounds; enemy/hazard anchors have support, clearance, response space, and
   active caps.
8. Safe entry, fall-recovery, switch, reward, and exit zones remain unobstructed.
9. Camera bounds frame commitments before the player must make them.
10. Encounter, hazard, reward, and duration budgets remain within profile limits.

## Requirements

- Runtime consumes a validated Stage Plan, not raw design JSON or editor metadata.
- Generation logic is independent from scene instantiation.
- Every content selection is explainable in a Generation Report.
- Generation Reports distinguish pressure role, archetype, and variant; adding a
  variant cannot silently alter room topology.
- Room content is authored to a contract and can be tested independently.
- No accepted stage relies on debug flags or testbed geometry.

## Acceptance Criteria

Current fixed-stage acceptance:

| Stage | Required rooms | Enemies | Vertical range | Meaningful elevation changes | Multi-elevation combat rooms | Max consecutive empty rooms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Ruin Approach | 8 | 8 | 720 px | 9 | 2 | 2 |
| Flooded Works | 7 | 10 | 760 px | 9 | 3 | 1 |
| Broken Sanctum | 9 | 12 | 740 px | 11 | 4 | 2 |

- Every normal-stage card reward routes through Safe Intermission before the next
  stage or boss.
- The baseline Traveler clears each approved fixed route with no movement upgrade.
- No unsupported enemy, floating marker, hidden collision, blocked exit, unsafe
  fall-recovery point, or unrecoverable required fall appears.

Deferred random re-entry gates, not current production acceptance:

- three curated seeds per profile are manually reviewed;
- a 1,000-seed property sweep accepts only valid plans or documented fallbacks;
- same seed/content version reproduces topology and exact content;
- different seeds change room order or an optional branch plus encounter
  allocation without changing the stage's teaching job.

## Non-Goals

- Per-tile noise, arbitrary platform scattering, infinite levels, or random boss
  arenas.
- Metroidvania ability locks or equipment/skill-exclusive critical routes.
- Generating art, collision, enemy AI, or reward rules from prose at runtime.
- Treating mathematical clearability as proof that a room is enjoyable.

## Related

- `docs/product/2d_platform_action_card_game_prd.md`
- `docs/design/MAP_AUTHORING_PIPELINE_CONTRACT.md`
- `docs/design/ENEMIES_TRAPS_GIMMICKS.md`
- `scripts/player/MovementMetrics.gd`
- `docs/data/RUNTIME_CATALOG_INDEX.md`
- `data/generation/`
- `data/rooms/`
