---
type: plan
status: active
owner: BK
created: 2026-07-25
last_reviewed: 2026-07-25
scope: Stage-local tactical layouts, independently relocating support fields, combat HUD and minimap, vehicle upgrade readability, player-projectile presentation, and stage damage telemetry
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ./2026-07-23-vehicle-performance-architecture-stabilization.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../docs/design/vehicle-hud-upgrade-direction/03-runtime-vehicle-upgrade-sheet.png
---

# Stage Tactical Variation and UI Readability — Execution Plan

## Purpose

Implement one deterministic, performance-bounded design in which the selected
field keeps its macro identity for the whole run, but cover, stationary threats,
items, crates, and support-field positions change between stages. Make those
changes readable through a compact top-left action rail, a tactical minimap,
independent world-space support-field timers, restrained persistent vehicle
upgrade changes, fixed-ownership player projectiles, and a three-part stage
report.

The plan is grounded in the current Godot 4.7 implementation. It does not ask a
future implementer to research alternatives or invent tuning values. It is
separate from the active performance-architecture plan: this work must stay
inside that plan's current entity, projectile, HUD-update, and rendered
presentation budgets.

## Progress

- [x] Read the active product and visual specifications.
- [x] Trace the current layout generator, layout data owner, terrain runtime,
  run orchestration, backdrop, pursuit field, combat renderer, HUD presenter,
  minimap, upgrade resources, telemetry, report builder, report panel,
  guidebook, localization, and focused validators.
- [x] Confirm the current mismatch: cover and functional terrain are fixed for
  the run; only stationary enemies, pickups, and crates vary by stage.
- [x] Confirm the current repair basin and overdrive field have no independent
  lifetime or relocation state.
- [x] Confirm the minimap updates through the existing 10 Hz HUD channel but
  omits ordinary enemy movement, support-field lifetime, and most tactical
  objects.
- [x] Confirm the current player is one combined mesh, so hull, primary weapon,
  and engine changes cannot be tinted or counted independently without
  separating presentation parts.
- [x] Confirm player projectile presentation currently derives color and trail
  shape from condition affinity, including the unwanted bright hybrid result.
- [x] Confirm stage telemetry groups outgoing damage only by source and cannot
  produce a non-overlapping attribute breakdown.
- [x] Re-audit the locked design against the current five-stage catalog,
  layout/backdrop/runtime ownership, capture CLI, and active performance
  contract; close the stage-layout, support-lifecycle, and damage-ownership
  contradictions found by that audit.
- [x] Lock the implementation decisions and acceptance thresholds below.
- [ ] Execute Milestones 1–6 in order.
- [ ] Incorporate accepted behavior into both active specifications, mark this
  plan done, then delete it after its durable decisions have been absorbed.

## Why / Context

The current run selects one field and one set of eight cover rectangles in
`VehicleFieldLayout`. `VehicleRun` configures that geometry once and reuses it
for every stage. The generator already creates deterministic stage-specific
stationary threats, pickups, crates, and encounter seeds, so stage-local
tactical layouts can extend an existing boundary instead of introducing a
second procedural-map system.

`VehicleTerrainRuntime` currently receives the field's authored features
directly. Every field contains one repair basin, one overdrive field, one flow
channel, arc terrain, transit gates, and bulkheads. Repair and overdrive are
fixed and therefore encourage camping. Flow is the least legible and least
useful field feature and was explicitly rejected. The selected design removes
flow, keeps arc/gate/bulkhead features authored and fixed, and makes only the
helpful repair and overdrive fields independently relocate.

The current HUD reserves a wide bottom-center dock for four actions even though
combat depends on seeing the lower field. The minimap is already a retained
custom control and its dynamic channel already runs at 10 Hz. Moving the action
rail below hull/experience and extending the existing minimap snapshot is safer
than introducing world-space labels or a second radar.

The current player mesh combines hull, cockpit, and shadow. Persistent visual
tiers therefore need responsibility-shaped player mesh parts. Count- or
radius-readable secondary upgrades must not also become darker: redundant
signals would imply an extra stat. Only a stat that cannot already be read from
the live weapon family receives a restrained shade tier.

## Current Evidence and Consequences

| Current source | Verified fact | Consequence locked by this plan |
| --- | --- | --- |
| Root `AGENTS.md` versus its referenced active product spec | The root sentence still says “three-stage,” while `vehicle_game_spec.md` and `vehicle_combat_stages.gd` both define the current five-stage run. | Treat the root phrase as stale factual guidance and correct only `three-stage` to `five-stage` in Milestone 1 before code changes. |
| `scripts/vehicle/stages/vehicle_combat_stages.gd` | `StageCatalog.STAGE_IDS` currently contains five stages. | Compile one tactical layout for every existing catalog entry; do not add, remove, or reorder stages. |
| `scripts/vehicle/vehicle_field_layout.gd` | One layout currently owns one cover set, one geometry snapshot, one pair of spawn-anchor arrays, all stage objects, encounter seeds, and persistent bulkhead health. | Introduce an immutable stage-tactical child object instead of adding parallel stage dictionaries and an “active” mode to the aggregate. |
| `scripts/vehicle/vehicle_stage_backdrop.gd` and `scripts/vehicle/vehicle_run.gd` | Backdrop, collision, pursuit, spawning, minimap, and encounter setup currently read run-global cover or anchor data. | Stage activation must publish one child layout atomically and every geometry consumer must read it. |
| `scripts/vehicle/vehicle_terrain_runtime.gd` | Repair and overdrive are fixed features; terrain time advances only when `VehicleRun` calls it during play. | Four scheduled slots belong to terrain runtime, and their pause/reset semantics are explicit below. |
| `scripts/vehicle/vehicle_run.gd::_damage_enemy()` | Every enemy hit is recorded as outgoing, including terrain-owned `Arc Surge`, even though `_is_player_owned_damage_source()` excludes it from player bonuses. | Add explicit ownership plus attribute to applied damage; Arc Surge remains environmental and is excluded from both outgoing report partitions. |
| `scripts/vehicle/vehicle_run.gd::_capture_stage_sequence()` | The deterministic capture fixture currently seeds only source totals and includes Arc Surge as outgoing. | Update the fixture with player-owned source/attribute pairs, four support phases, and the responsive report state. |
| `.agents/execplans/2026-07-23-vehicle-performance-architecture-stabilization.md` | The accepted capacity contract already fixes entity/projectile caps, scenarios, and rendered thresholds. | This plan adds no new high-count nodes and reuses `current_pressure`; it does not redefine or claim completion of the performance plan. |

## Scope

### In scope

- One selected macro field for the complete run.
- Deterministic stage-local cover and tactical object layouts.
- Exact-retry stability and next-stage variation.
- Removal of Flow Channel from current fields, runtime, drawing, discovery,
  guidebook, localization, and validation.
- Two independently relocating repair fields and two independently relocating
  overdrive fields.
- Compact top-left icon-only action rail.
- Tactical minimap markers for enemy groups, priority enemies, items, and
  support fields.
- World and minimap support-field lifetime arcs.
- Hull shade, engine count, primary weapon shade, and bounded secondary visual
  rules based on actual upgrade ownership.
- Fixed friendly projectile ownership color while preserving hostile attack
  affinity cues.
- Stage report breakdown by defeats, damage source, and non-overlapping damage
  attribute.
- Korean/English parity, focused validators, Web export, and rendered captures.

### Non-goals

- New stages, enemies, bosses, weapons, cards, audio, dependencies, shaders, or
  engine changes.
- A new world topology, separate boss room, puzzle system, base stage, or
  unconstrained procedural generation.
- Rebalancing quotas, enemy stats, boss stats, projectile caps, card strength,
  or difficulty multipliers. Support fields retain a bounded shared repair
  budget so this change does not silently lower difficulty.
- Replacing the existing threat radar, boss warning, hit feedback, settings,
  guidebook navigation, or upgrade confirmation flow.
- Recoloring hostile attacks by ownership. Hostile affinity remains important
  because it distinguishes attack behavior and telegraph semantics.
- Adding persistent body decoration for cadence, pierce, status stacking,
  projectile count, or other behavior already visible during play.
- Completing the independent active performance-architecture release matrix.

## Assumptions — Locked Interpretations

- “The map stays the same” means one field keeps its world rectangle, floor,
  water, outer boundary, transit gates, arc strips, and bulkhead identities for
  the complete run.
- “Terrain and item placement changes each stage” means stage-local cover,
  stationary threats, pickups, crates, and support-field socket sequences
  change. A retry of the same stage reproduces the same layout; advancing to a
  new stage produces a different layout.
- The current `StageCatalog.STAGE_IDS` sequence is content truth. This plan
  compiles every existing stage and changes neither stage count nor order.
- A same-stage restart restores bulkheads, stage objects, and support schedules
  to their deterministic stage-start state. Advancing to the next stage keeps
  the current persistent bulkhead-health contract but starts the new stage's
  objects and support schedules from their own deterministic initial state.
- “More fields” means four low-count support-field instances: two repair and two
  overdrive. It does not mean four of every functional terrain type.
- “Fields must not all move together” means one central relocation arbiter
  permits at most one old-site departure and new-site warning during any rolling
  three-second window. A ready field remains as a dormant marker at its old
  socket until granted; fields never disappear or relocate in one synchronized
  batch.
- “Each field has a different duration” means every one of the four instances
  has its own fixed active and dormant duration, not only a different duration
  per category.
- Support schedules advance only in `RunMode.PLAYING`. Pause, settings,
  guidebook, upgrade choice, deployment, report, failure, and result modes
  freeze them exactly; neither wall-clock time nor modal animation time is
  charged to a field.
- Secondary levels already communicated by a visible count or radius receive no
  shade tier. A separate passive-damage stat may use one small shared secondary
  power core because its value is not the count of any family.
- The user's projectile color feedback applies to player projectiles. Hostile
  projectiles and telegraphs keep affinity colors and shapes.
- Stage damage source and attribute reports include only player-owned applied
  damage. Terrain-owned Arc Surge can damage enemies but is excluded from both
  outgoing partitions and from lifesteal/overdrive ownership checks.
- The existing 10 Hz tactical HUD channel is sufficient for minimap movement.
  Combat simulation and collision stay at their current cadence.

## Proposed Design — Locked Decisions

### 1. Stage-local tactical layout

Add `scripts/vehicle/vehicle_stage_tactical_layout.gd` as an immutable
`RefCounted` child owned by the run-scoped `VehicleFieldLayout`. Each child owns
exactly one stage's:

- `stage_id`, `cover_ids`, and `cover_rects`;
- `geometry_snapshot` and its cover broadphase;
- `ordinary_spawn_anchors` and `boss_arrival_anchors`;
- stationary, pickup, and crate blueprints;
- `support_sockets`;
- `encounter_seed`, `fingerprint`, and `used_fallback`.

`VehicleFieldLayout` keeps the selected field definition, layout seed, a
`Dictionary[StringName, VehicleStageTacticalLayout]`, the aggregate fingerprint,
and the existing persistent bulkhead-health dictionary. It exposes
`tactical_layout(stage_id)` and delegates the existing blueprint/seed accessors
during migration. It does not copy a child's arrays into mutable “active”
fields. `VehicleRun` alone owns `_active_tactical_layout` and passes that exact
object to consumers.

| Owner | Owns | Must not own |
| --- | --- | --- |
| `VehicleFieldLayoutGenerator` | Deterministic compilation and validation of every stage child. | Runtime relocation, combat state, or UI snapshots. |
| `VehicleFieldLayout` | Selected field, child lookup, aggregate fingerprint, and persistent bulkhead-health channel. | Active-stage mirrors or support timers. |
| `VehicleStageTacticalLayout` | Immutable stage geometry, anchors, objects, sockets, broadphase, and encounter seed. | Mutable actors, support lifecycle, or HUD state. |
| `VehicleTerrainRuntime` | Fixed functional-terrain state plus four support-slot schedules/effects. | Choosing cover, drawing UI, or changing encounter quotas. |
| `VehicleHudPresenter` / `VehicleStageUI` | Dirty-channel publication and retained HUD/minimap/report presentation. | Card behavior, geometry truth, or damage attribution. |
| `VehicleCombatRenderer` | Retained vehicle/projectile visual instances and feedback composition. | Collision radius, upgrade rules, or damage math. |
| `VehicleStageTelemetry` / report builder | Bounded numeric partitions and presentation-ready report rows. | Damage application, ownership inference, or gameplay effects. |

The generator uses stable channel strings of the form
`"%d:%s:%s:v2" % [layout_seed, stage_id, channel]`. A retry uses the same seed,
canonical blueprint, and fingerprint. Each channel has its own RNG so adding a
new pickup decision cannot perturb cover, anchors, or support sockets.
Stage-local random cover selection keeps the current `32` attempts. If those
attempts fail, the generator enumerates the finite Cartesian product of sector
candidate indexes in stable lexicographic order, rotated by the stage cover
sub-seed, and accepts the first fully valid mask whose canonical cover set
differs from the previous stage. If no such mask exists, generation fails with
one bounded diagnostic; it never reuses invalid or identical fallback geometry.

Each stage selects eight cover rectangles using the current sector model.
Existing radius, floor, water, start-clearance, feature-clearance,
cover-clearance, reachability, ordinary-anchor, and boss-anchor checks remain
mandatory. Reachability is validated with all authored breakable bulkheads
intact, so breaking a bulkhead can open a shortcut but can never be required to
reach ordinary or boss anchors, stage objects, or support sockets. Static
arc/gate/bulkhead footprints stay reserved. Repair, overdrive, stationary,
pickup, crate, and support sockets are selected after cover so they cannot
overlap it. The generator filters the field's existing authored
`item_socket_candidates`, excludes the eight sockets assigned to stage pickups
and crates, and stores at least twelve remaining points whose complete
180-pixel support footprint passes floor, water, cover, intact-bulkhead,
feature, start, player-radius reachability, and boss-radius reachability checks.
These become `support_sockets`; no second random point generator is introduced.

Stage activation is one ordered transaction:

1. resolve and assign `_active_tactical_layout`;
2. configure `VehicleStageBackdrop` with
   `configure(stage_id, _active_tactical_layout)`;
3. rebuild runtime blockers from active cover plus live bulkheads, then
   configure pursuit/navigation;
4. configure terrain with fixed field features, active support sockets, and
   the correct restart/advance bulkhead-preservation flag;
5. configure encounter allocation with the active ordinary anchors and
   encounter seed, and boss arrival with the active boss anchors;
6. publish static minimap geometry and only then reset player, actors, and
   dynamic HUD state.

No geometry consumer may read the previous global `cover_rects`,
`ordinary_spawn_anchors`, `boss_arrival_anchors`, or `geometry_snapshot` after
migration. The compatibility accessors are removed in the same milestone once
all consumers and validators compile against the stage child.

### 2. Independently relocating support fields

Flow Channel is removed. Arc Surge, Transit Gate, and Breakable Bulkhead remain
authored field features. Repair and overdrive become stage-owned scheduled
features with these exact slots:

| Slot | Kind | Radius | Warning | Active | Dormant | Initial offset |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| `repair_a` | repair | 150 | 1.5 s | 18 s | 10 s | 0 s |
| `repair_b` | repair | 150 | 1.5 s | 23 s | 11 s | 12 s |
| `overdrive_a` | overdrive | 180 | 1.5 s | 12 s | 14 s | 5 s |
| `overdrive_b` | overdrive | 180 | 1.5 s | 15 s | 16 s | 19 s |

Initial offset is a stage-start dormant delay before the slot's first warning.
After that, every slot runs
`warning → active → dormant_marker → relocation_pending → warning`. The world
circle appears during warning, becomes effective only while active, and drains
one clockwise boundary arc from 100% to 0%. The final 20% uses a thicker inner
notch as a shape cue; it does not flash or add text. At active expiry, the
effect stops but a muted zero-arc marker remains at the old socket for the
slot's dormant duration and while it waits for relocation permission. This is
the visual guarantee that fields do not all vanish together.

The relocation arbiter:

- grants at most one old-site departure/new-site warning every 3.0 seconds;
- seeds each choice with the stable string
  `"%d:%s:%s:%d:support-v2" % [layout_seed, stage_id, slot_id, relocation_index]`;
- rejects the current socket and the previous two sockets of that slot;
- rejects overlap with the player at 420 pixels, cover at effect radius plus
  64 pixels, static functional terrain, spawn/boss anchors, stationary threats,
  pickups, crates, and another support field at combined radii plus 96 pixels;
- requires the player-radius reachability grid to contain the socket;
- uses the stage's prevalidated fallback socket order if no shuffled socket is
  valid;
- defers the slot rather than placing an invalid field if every socket is
  temporarily occupied.

Both repair slots consume the existing single stage-wide 24-hull repair budget.
Relocation never replenishes it. Existing dwell and post-hit pause remain.
When the shared budget reaches zero, both repair slots enter `depleted`, stop
requesting relocation, drain their boundary to empty, and fade out over
1.0 second; their minimap markers are then removed. A depleted field never
advertises healing it cannot provide.

Overdrive remains 1.20x only while inside an active field, does not stack when
two fields are nearby, and is removed immediately when a slot leaves active
state. This preserves current difficulty while preventing one-position
camping.

`VehicleTerrainRuntime.snapshot()` exposes one bounded dictionary per slot with
`slot_id`, `kind`, `state`, `position`, `radius`, `phase_progress`,
`remaining_seconds`, `effect_active`, and `relocation_index`. These four
snapshots are the single source for world drawing, minimap markers, and
validators. Slot timers advance only through the existing gameplay `delta`;
same-stage restart resets the four states and socket histories exactly, next
stage uses that stage child's schedules/sockets, and pause or any modal leaves
all values bit-stable.

### 3. HUD, minimap, and field readability

At `1280×720`:

- Hull/experience remains at `(18, 16)`, `184×54`.
- The bottom action dock is removed.
- A `154×34` action rail sits at `(18, 76)` with four `34×34` icon slots and
  three 6-pixel gaps: primary, passive, dash, EMP.
- The rail has no key names, action text, or opaque outer panel. Cooldown,
  ready, and disabled states use the existing icon silhouette plus a maximum
  3-pixel radial sweep.
- Rail slots are non-interactive status indicators with `mouse_filter` ignored
  and no focus entry; actual rebinding controls keep visible localized labels
  and the existing 44-pixel command-target contract in settings.
- Bindings and text remain available in settings and the guidebook.
- The objective stays top-center as one restrained line.
- The minimap stays top-right but loses its title row; a `176×108` tactical map
  uses the full cluster with one thin border and dim background.

The same anchors scale down at `960×540` without overlap and scale by viewport
anchors at `1920×1080`. No new HUD content is placed at bottom center. The
stage-report modal uses
`Vector2(min(1120, viewport_width - 48), min(560, viewport_height - 40))`; it
shows three columns at viewport widths `>= 1180` and the same three datasets as
keyboard-accessible tabs below that threshold.

The minimap keeps the existing 20×12 exploration mask and receives:

- player triangle plus facing line from explicit `player_facing`;
- ordinary mobile enemies clustered by minimap cell, using one coral dot whose
  radius is `2.5`, `4.0`, or `5.5` logical pixels for bounded `1`, `2–4`, or
  `5+` counts and whose clamped `4–7` pixel tick shows average velocity;
- stationary threats as `5×5` squares;
- elites as solid `7×7` coral diamonds with one `2×2` ivory center notch,
  avoiding a decorative outline;
- the boss and boss warning as their existing unique marker;
- every live repair/recall pickup as a 5-pixel circle and every unopened crate
  as a `6×6` neutral cache square regardless of fog; crates never reveal their
  future drop;
- every warning, active, or dormant-marker support field regardless of fog,
  because these are time-limited strategic destinations;
- a support-field ring whose remaining arc matches the world-space lifetime.

Enemy and tactical markers draw above unexplored fog while concealed floor and
wall geometry remains dark; this exposes current threats/destinations without
pretending the route has been explored. Repair uses a mint plus, overdrive a
mustard chevron ring, pickups circles, crates squares, elites outlined diamonds,
and hostile groups coral dots. Shape remains authoritative in grayscale.

The ordinary cluster channel is bounded by the 240 minimap cells rather than
the enemy cap. Priority actors remain individual. The dynamic snapshot contains
only `player_position`, `player_facing`, ordinary cluster
`cell/count/average_velocity`, priority actor `kind/position`, live item
`kind/position`, and the four support snapshots. Static geometry is resent only
on stage-layout change; dynamic markers and field timers stay on the existing
10 Hz channel.

### 4. Vehicle upgrade and projectile presentation

Split the production player presentation into retained mesh parts:

- `player_hull_mesh()` — body, cockpit, and shadow;
- `player_primary_mesh()` — the forward cannon;
- `player_engine_mesh()` — one rear engine module;
- `player_secondary_core_mesh()` — one small shared passive-power core.

`VehicleCombatRenderer` keeps one hull and one primary instance, up to three
engine instances, and one secondary-core instance. Hit tint and invulnerability
feedback modulate the composed player consistently and override persistent
shade only for their current feedback window.

Shade tiers use one fixed mix table, `[0.00, 0.28, 0.52, 0.72]`. Hull and
primary mix `Art.MUSTARD` toward `Art.MUSTARD_DARK`; the secondary core and
escort-drone weapon core mix `Art.MINT` toward `Art.CERAMIC_GREEN`. Cockpit,
outline-free silhouette breaks, hit flash, and invulnerability flicker are not
darkened by this persistent mix. These changes are supplemental glance cues:
the existing pause Ship Status/upgrade list remains the text-and-value source of
truth, so no stat depends on color or shade alone.

Persistent upgrade mapping is exact:

| Upgrade/stat | Persistent visual | Tier rule |
| --- | --- | --- |
| `reinforced_hull` | Hull mustard shade becomes progressively darker while preserving cockpit contrast | 0–3 |
| `tuned_thrusters` | Rear engine module count | 0–3 |
| `kinetic_rounds` | Primary cannon mustard shade becomes progressively darker | 0–3 |
| `seeker_warhead` / passive damage multiplier | Small shared secondary core becomes progressively darker | 0–3 |
| `twin_seekers` | Launcher/projectile count only | No shade tier |
| `orbit_blades` | Blade count only | No shade tier |
| `wake_mines` | Live mine/cap count only | No shade tier |
| `ion_field` | Field radius only | No shade tier |
| `escort_drone` | Drone weapon-core shade because level is not a count | 1–3 |

Fire, poison, and chill remain shape-distinct icons adjacent to the ship.
Cadence, pierce, projectile count, opening-shot readiness, and status behavior
do not add permanent chassis marks because their live behavior already reveals
them.

Every player projectile head uses the same mustard ownership color and dark
cobalt core; its trail uses the same ownership palette. Condition stacking does
not recolor it and multi-condition projectiles never become ivory. Projectile
radius, Breach size, count, trajectory, and wall-piercing geometry still show
their actual behavior. Enemy projectile heads, trails, and telegraphs preserve
their authored affinity colors and shape rhythms.

The deterministic design sheet at
`docs/design/vehicle-hud-upgrade-direction/03-runtime-vehicle-upgrade-sheet.png`
is regenerated immediately after the production mesh split and must match these
rules before the retained renderer hookup is accepted.

### 5. Stage telemetry and report

Every player-owned applied-damage event records two independent dimensions:

1. its existing source (`primary`, seeker, ion field, orbit blade, wake mine,
   drone, EMP, dash, status, and so on);
2. exactly one damage attribute: `kinetic`, `thermal`, `toxin`, `cryo`, or
   `arc`.

The two views are alternative partitions of the same outgoing total, not values
to add together. Both totals must match within `0.01`.

| Applied player-owned damage | Attribute |
| --- | --- |
| Primary direct hit, passive seeker, orbit blades, wake mine, escort drone, dash impact, ram pulse | `kinetic` |
| Burn tick and Flashover bonus | `thermal` |
| Poison tick | `toxin` |
| Shatter bonus | `cryo` |
| Ion field, EMP/aftershock, player arc mine, Ion Wake, Shock Breach | `arc` |
| Reflected projectile | Preserve the reflected attack's original normalized attribute. |

Condition application never changes the direct hit's kinetic row; its later
burn/poison/Shatter damage enters the corresponding row. Terrain-owned Arc
Surge is not player damage and appears in neither outgoing partition.

Replace source-string ownership inference at the application boundary with
explicit arguments:

```gdscript
_damage_enemy(
    enemy: VehicleEnemyState,
    amount: float,
    source: String,
    stagger: float,
    attribute: StringName,
    player_owned: bool
) -> float
```

Every production call site supplies the last two values. Defaults are not
allowed because they would silently classify new attacks as player kinetic
damage. Only `player_owned` events call
`stage_telemetry.record_outgoing(source_id, attribute, applied_damage)`, receive
overdrive/lifesteal ownership benefits, or contribute to report totals.
`DamageSourceCatalog` remains the stable source-ID mapper; attribute is an
independent five-value enum validated by telemetry. The existing `arc_surge`
source label may remain as harmless compatibility data, but no current
player-owned call produces it.

`VehicleStatusRuntime.tick()` returns separate burn and poison amounts instead
of one combined float. Opening resolution returns separate thermal Flashover
and cryo Shatter bonuses. Application counts for burn, poison, and chill are
stored as bounded integers so chill can remain visible in the report even when
it contributes control but no direct damage.

At viewport width `>= 1180`, the stage report uses three columns: enemy defeats,
damage by source, and damage by attribute. Below that threshold it uses three
keyboard-accessible tabs. Every attribute row has a large shape icon, localized
name, amount, and percentage. Chill application count appears in the cryo row;
it is never converted into invented damage. Each dataset keeps a localized
`기록 없음` / `No data` empty row instead of collapsing its section, and zero
totals produce `0%`, never `NaN` or an empty percentage.

The report modal grabs initial focus, orders focus as
defeats → sources → attributes → continue/retry, uses visible focus, and keeps
compact tab targets at least 44 pixels high. Wide columns use spacing and
dividers inside the one modal surface rather than nested bordered cards.

## Milestone Outcomes

| Milestone | Exit outcome |
| --- | --- |
| 1. Layout ownership | Every catalog stage has one immutable, validated tactical child and every geometry consumer reads the active child. |
| 2. Support runtime | Four independently phased fields relocate through one staggered arbiter, freeze in modals, and preserve repair/overdrive limits. |
| 3. Tactical HUD | The bottom dock is gone; the compact action rail and fog-aware tactical minimap meet the bounded payload contract. |
| 4. Vehicle presentation | Production meshes show only the approved upgrade tiers, and player projectiles keep one readable ownership palette. |
| 5. Combat report | Every player-owned applied hit belongs to one source and one attribute partition with equal totals. |
| 6. Release evidence | Focused/full validators, deterministic captures, one native pressure gate, and production Web export all pass. |

## Tasks

### Milestone 1 — Canonical contracts and stage layout ownership

- [ ] Correct the one stale root `AGENTS.md` phrase from “connected three-stage
  run” to “connected five-stage run”; make no other protected-instruction
  changes.
  - **Protected-file approval gate:** execute this exact one-phrase correction
    only after the user explicitly authorizes executing all tasks in this plan
    or separately approves the quoted diff. Otherwise leave `AGENTS.md`
    untouched and report the stale phrase.
- [ ] Update `docs/product/vehicle_game_spec.md` and
  `docs/design/UI_VISUAL_SYSTEM.md` to replace run-fixed tactical placement,
  fixed support facilities, Flow Channel, hybrid player projectile color,
  bottom action dock, two-column report, and limited minimap markers with this
  plan's locked contracts.
- [ ] Add `scripts/vehicle/vehicle_stage_tactical_layout.gd` with immutable
  stage-local cover, geometry snapshot/broadphase, ordinary/boss anchors,
  objects, support sockets, encounter seed, canonical blueprint, and
  fingerprint; reduce `VehicleFieldLayout` to the run aggregate and accessor
  described above.
- [ ] Extend `scripts/vehicle/vehicle_field_layout_generator.gd` to compile and
  validate one tactical layout per stage, including distinct-adjacent-stage and
  exact-retry invariants and complete deterministic fallback enumeration.
- [ ] Remove authored Flow Channel and fixed repair/overdrive entries from
  `scripts/vehicle/stages/drowned_ruin_field.gd`,
  `scripts/vehicle/stages/tidal_archive_field.gd`, and
  `scripts/vehicle/stages/storm_drydock_field.gd`; derive support sockets from
  each field's existing authored `item_socket_candidates`.
- [ ] Update `scripts/vehicle/vehicle_field_geometry_snapshot.gd`,
  `scripts/vehicle/vehicle_stage_backdrop.gd`, and
  `scripts/enemies/vehicle_pursuit_field.gd` only as required to consume the
  active stage geometry.
- [ ] Update `scripts/vehicle/vehicle_run.gd` so stage activation switches all
  geometry consumers atomically before encounter state begins, same-stage
  restart restores bulkheads/objects, and next-stage activation preserves only
  the current persistent bulkhead-health contract.

**Accept:** every current field/stage pair compiles one child, exact retries
match, adjacent stage fingerprints differ, and every geometry consumer reports
the active child fingerprint.

**Guard:** stage count/order, macro field topology, actor radii, bulkhead
persistence between stages, and all encounter/balance values remain unchanged.

### Milestone 2 — Dynamic support-field runtime

- [ ] Extend `scripts/vehicle/vehicle_terrain_definition.gd` with scheduled
  support-slot identity and lifecycle snapshot fields.
- [ ] Refactor `scripts/vehicle/vehicle_terrain_runtime.gd` to own the four
  fixed slots, independent state machines, dormant old-site markers, shared
  relocation arbiter, repair depletion, non-stacking overdrive, deterministic
  socket history, and modal freeze/reset behavior.
- [ ] Remove `flow_vector_at()` callers and Flow Channel rendering/discovery
  paths from `scripts/vehicle/vehicle_run.gd`.
- [ ] Render warning, active fill, exact boundary, and remaining-time arc in
  `scripts/vehicle/vehicle_run.gd` without text or per-field scene nodes.
- [ ] Remove the Flow Channel guide entry from
  `scripts/progression/vehicle_guidebook_catalog.gd`,
  `scripts/ui/vehicle_guidebook_preview.gd`, and
  `localization/vehicle_stage.csv`; update repair and overdrive copy for
  relocation and independent lifetime.

**Accept:** the four exact schedules, old-site staggering, modal freeze,
depletion, 24-hull repair cap, and 1.20x non-stacking overdrive pass the focused
runtime validator and rendered state fixture.

**Guard:** Arc Surge, Transit Gate, and Breakable Bulkhead behavior stays
unchanged; no support-field scene node, per-frame search over map candidates, or
new gameplay clock is introduced.

### Milestone 3 — Compact HUD and tactical minimap

- [ ] Update `scripts/ui/vehicle_stage_ui.gd` to remove the bottom dock, create
  the icon-only top-left rail, remove the minimap title row, draw clustered
  mobile velocity markers, priority actors, items, support fields, and lifetime
  arcs.
- [ ] Extend `scripts/ui/vehicle_hud_presenter.gd` only with dirty channels
  needed for stage-layout invalidation and 10 Hz tactical data.
- [ ] Extend `scripts/vehicle/vehicle_run.gd::_minimap_snapshot()` to emit
  bounded cell clusters, `player_facing`, tactical items/crates, and the four
  support snapshots; do not send one ordinary marker per enemy.
- [ ] Preserve the current world threat radar and status-orbit ownership; do
  not duplicate visible enemies in both threat radar and off-screen arcs.
- [ ] Update Korean and English HUD/guide copy in
  `localization/vehicle_stage.csv`.

**Accept:** `960×540`, `1280×720`, and `1920×1080` layouts contain the compact
rail and complete tactical markers with no clipping/overlap; report controls,
settings, and guidebook remain keyboard reachable in both locales.

**Guard:** static minimap geometry stays event-driven, dynamic publication stays
at 10 Hz, ordinary enemies remain cell-clustered, and the action rail remains
non-interactive presentation rather than a second input surface.

### Milestone 4 — Vehicle and projectile visual contract

- [ ] Split player geometry in
  `scripts/presentation/vehicle_combat_visual_library.gd` into the four retained
  mesh parts without changing collision truth.
- [ ] Extend `scripts/vehicle/vehicle_run.gd::_combat_presentation_snapshot()`
  with only the bounded visual levels needed by the renderer.
- [ ] Extend `scripts/presentation/vehicle_combat_renderer.gd` with one-instance
  hull/primary/core batches, a three-instance engine batch, tier shades, and
  hit-feedback composition.
- [ ] Keep count/radius-readable secondaries free of shade tiers; apply only the
  exact table above.
- [ ] Force player projectile head/trail ownership colors in
  `scripts/presentation/vehicle_combat_renderer.gd` while preserving hostile
  affinity presentation and all collision/size contracts.
- [ ] Regenerate
  `docs/design/vehicle-hud-upgrade-direction/03-runtime-vehicle-upgrade-sheet.png`
  with `tools/design/vehicle_upgrade_sheet_capture.gd`.

**Accept:** the generated production-mesh sheet and gameplay capture agree on
all fixed shade/count tiers, condition icons, feedback priority, and the
mustard/cobalt player-projectile contract.

**Guard:** collision geometry, damage/status math, hostile affinity rendering,
and count/radius-readable secondary behavior do not change.

### Milestone 5 — Attribute telemetry and report UI

- [ ] Extend `scripts/combat/vehicle_stage_telemetry.gd` with bounded stage/run
  attribute totals and condition-application counters.
- [ ] Split status results in
  `scripts/combat/vehicle_status_runtime.gd`; pass explicit ownership and
  attribute from every `_damage_enemy()` call site, and exclude terrain-owned
  Arc Surge from outgoing telemetry.
- [ ] Extend `scripts/combat/vehicle_stage_report_builder.gd` with sorted,
  percentage-assigned attribute rows and the source-total equality invariant.
- [ ] Extend `scripts/ui/vehicle_stage_report_panel.gd` to three columns at wide
  width and three tabs at compact width.
- [ ] Add complete Korean/English attribute labels and accessibility text to
  `localization/vehicle_stage.csv`.

**Accept:** success, failure, and zero-data fixtures produce equal source and
attribute totals, correct condition counts, stable percentages, and the
wide/compact report layouts with the declared focus order.

**Guard:** applied damage, status stack/tick timing, lifesteal value, source IDs,
and terrain-owned Arc Surge behavior remain unchanged.

### Milestone 6 — Validation, rendered QA, and lifecycle close

- [ ] Add or extend focused validators listed in Test Plan.
- [ ] Update the deterministic capture fixture in
  `scripts/vehicle/vehicle_run.gd` to stage all four support phases, tactical
  minimap markers, vehicle visual tiers, and source/attribute report rows
  without treating Arc Surge as player-owned.
- [ ] Run every focused validator with zero errors and zero orphan-node or
  leaked-resource warnings.
- [ ] Export the production Web build with `tools/export_web.ps1`.
- [ ] Capture deterministic native Korean and English gameplay, minimap, pause,
  and report states at `960×540`, `1280×720`, and `1920×1080`; then inspect the
  production Web export at `1280×720` through the registered fastrun-manager
  Codex lane.
- [ ] Verify a fixed seed through two exact retries and two adjacent stages.
- [ ] Run one standalone `current_pressure` sample at `1280×720`, using the
  active performance plan's 10-second warmup, 60-second sample, caps, and
  standalone frame thresholds. This is a task-scoped regression gate, not the
  unfinished three-run native/Web release matrix.
- [ ] Record material behavior in the active specs, set this plan to `done`,
  and remove it once no unchecked implementation work remains.

**Accept:** every command and rendered check in Test Plan passes, the
authoritative task-scoped pressure result passes, the Web export opens through
the registered path, and the Level 4 UIUX evidence fields are recorded.

**Guard:** do not reinterpret this task-scoped performance pass as completion
of the separate active performance plan or mix unrelated balance/content work
into the closeout.

## Test Plan

Run focused validators from the repository root after their owning milestone:

```powershell
$focusedValidators = @(
  "validate_vehicle_field_layout_generation.gd",
  "validate_vehicle_navigation_clearance.gd",
  "validate_vehicle_single_field_campaign.gd",
  "validate_vehicle_spawn_allocation.gd",
  "validate_vehicle_stage_layouts.gd",
  "validate_vehicle_terrain_runtime.gd",
  "validate_vehicle_support_field_schedule.gd",
  "validate_vehicle_hud_presenter.gd",
  "validate_vehicle_stage_ui_layout.gd",
  "validate_vehicle_combat_renderer.gd",
  "validate_vehicle_upgrade_system.gd",
  "validate_vehicle_status_stacking.gd",
  "validate_vehicle_secondary_weapons.gd",
  "validate_vehicle_stage_telemetry.gd",
  "validate_vehicle_stage_report.gd",
  "validate_vehicle_pause.gd",
  "validate_vehicle_guidebook.gd",
  "validate_vehicle_rewards_ui_audio.gd",
  "validate_vehicle_run.gd",
  "validate_vehicle_performance_scenarios.gd"
)
foreach ($validator in $focusedValidators) {
  .\tools\godot.ps1 --path . --headless --script ("res://tools/validation/" + $validator)
  if ($LASTEXITCODE -ne 0) { throw "Validation failed: $validator" }
}
```

Milestone 6 then runs the complete repository validator set:

```powershell
Get-ChildItem tools/validation -Filter *.gd | Sort-Object Name | ForEach-Object {
  .\tools\godot.ps1 --path . --headless --script ("res://tools/validation/" + $_.Name)
  if ($LASTEXITCODE -ne 0) { throw "Validation failed: $($_.Name)" }
}
```

Regenerate the production-mesh reference sheet with a rendered, non-headless
scene; this capture scene must not be substituted with an SVG mock:

```powershell
.\tools\godot.ps1 --path . --rendering-method gl_compatibility res://tools/design/VehicleUpgradeSheetCapture.tscn
if (-not (Test-Path "docs/design/vehicle-hud-upgrade-direction/03-runtime-vehicle-upgrade-sheet.png")) {
  throw "Vehicle upgrade sheet was not generated."
}
```

Capture the deterministic locale/size matrix for the canonical field and one
Korean `1280×720` set for each other selectable field:

```powershell
$captureRoot = Join-Path (Resolve-Path .).Path "build\captures\tactical-ui"
$seed = 12886704
foreach ($locale in @("ko", "en")) {
  foreach ($size in @("960x540", "1280x720", "1920x1080")) {
    $dir = Join-Path $captureRoot "drowned_ruin_field-$locale-$size"
    $args = @(
      "--path", ".", "--rendering-method", "gl_compatibility", "--",
      "--capture-all=$dir", "--capture-locale=$locale",
      "--capture-size=$size", "--layout-seed=$seed",
      "--field-id=drowned_ruin_field"
    )
    .\tools\godot.ps1 @args
    if ($LASTEXITCODE -ne 0) { throw "Capture failed: $locale $size" }
  }
}
foreach ($field in @("tidal_archive_field", "storm_drydock_field")) {
  $dir = Join-Path $captureRoot "$field-ko-1280x720"
  $args = @(
    "--path", ".", "--rendering-method", "gl_compatibility", "--",
    "--capture-all=$dir", "--capture-locale=ko",
    "--capture-size=1280x720", "--layout-seed=$seed",
    "--field-id=$field"
  )
  .\tools\godot.ps1 @args
  if ($LASTEXITCODE -ne 0) { throw "Capture failed: $field" }
}
```

Run the one task-scoped rendered performance regression with the native window
focused for the complete 70 seconds, then produce the Web export:

```powershell
$performanceArgs = @(
  "--path", ".", "--resolution", "1280x720",
  "--rendering-method", "gl_compatibility", "--",
  "--performance-scenario=current_pressure",
  "--performance-output=res://build/performance/tactical-ui-current-pressure.json",
  "--performance-warmup=10", "--performance-duration=60"
)
.\tools\godot.ps1 @performanceArgs
if ($LASTEXITCODE -ne 0) { throw "current_pressure failed." }
$performanceResult = Get-Content "build/performance/tactical-ui-current-pressure.json" -Raw | ConvertFrom-Json
if (
  -not $performanceResult.authoritative
  -or -not $performanceResult.scenario_validation.valid
  -or -not $performanceResult.thresholds.passed
) {
  throw "current_pressure did not pass its authoritative rendered thresholds."
}
.\tools\export_web.ps1
```

For the built-Web visual pass, load `$npjt-port-guard`, use the registered
fastrun-manager `codex` lane, and inspect `build/web` at `1280×720`; do not
launch an ad hoc server or use the editor run as the production substitute.

Required automated assertions:

- Every current `StageCatalog.STAGE_IDS` entry compiles exactly one tactical
  child with a geometry snapshot, ordinary/boss anchors, objects, at least
  twelve support sockets, an encounter seed, and a nonzero fingerprint.
- The same field/seed/stage produces byte-equivalent canonical blueprints and
  fingerprints through generation, same-stage restart, and a second process.
- Adjacent stages produce different cover sets and different complete tactical
  fingerprints; forced fallback follows the same rule.
- All cover, objects, spawn/boss anchors, support sockets, and current support
  circles are reachable with intact bulkheads, mutually non-overlapping,
  outside start clearance, and clear of water/static functional terrain.
- Backdrop, collision, projectile walls, pursuit, encounter allocation, boss
  arrival, and static minimap all consume the same active child fingerprint.
- No old-site departure or new-site warning begins within three seconds of
  another slot's relocation grant.
- All four slots preserve their declared initial offsets and independent
  `warning/active/dormant_marker/relocation_pending` sequence; pausing or
  opening any modal leaves snapshots unchanged.
- Repair never exceeds 24 hull per stage across both slots.
- Repair depletion removes both false affordances and further relocation.
- Overdrive never stacks above 1.20x.
- Minimap ordinary markers are bounded by 240 cell clusters.
- Minimap payload contains player facing, average cluster velocity, live
  repair/recall items, unopened crates, priority actors, and exactly four
  support entries before repair depletion.
- Static minimap geometry changes once per stage activation, not at 10 Hz.
- Wide and compact HUD contracts contain a `154×34` icon-only action rail, no
  bottom-center panel, no live action text, no clipping, and no overlap.
- Count/radius-readable secondaries do not receive a tier-shade input.
- Hull/primary/core shade levels use the fixed mix table; renderer feedback can
  override but cannot permanently mutate those levels.
- Player projectile rendering ignores player affinity color but hostile
  rendering still consumes it.
- Every `_damage_enemy()` production call supplies explicit ownership and
  attribute; Arc Surge contributes to neither player outgoing partition.
- Source and attribute outgoing totals match within `0.01`.
- Zero-data report sections remain present with `0%`; compact tabs have visible
  focus, 44-pixel minimum height, and the declared focus order.
- Korean and English expose identical controls, tabs, report rows, and guide
  entries.

Required rendered checks:

- At least two support fields are visible in one representative capture and
  their different remaining arcs are immediately distinguishable.
- An expired field remains as a muted dormant marker, then only that field
  leaves when its new valid-socket warning appears; no capture transition shows
  all fields disappearing together.
- Repair and overdrive are distinguishable by shape without reading color, and
  a depleted repair field does not retain an active-looking world or minimap
  affordance.
- The minimap shows moving enemy clusters, stationary threats, an elite, a
  pickup, an unopened crate, and timed support fields above fog without
  concealing the player or its facing line.
- Hull shade levels, zero-to-three engines, primary shade levels, secondary
  core levels, count/radius secondaries, and fixed player projectiles match the
  reference sheet at gameplay scale.
- Player projectiles remain mustard/cobalt with simultaneous fire, toxin, and
  chill icons and never wash out to ivory.
- The three-column report is readable at `1280×720`; all three compact tabs are
  keyboard reachable at `960×540`; neither locale clips at `1920×1080`.
- Native pause freezes field arcs and the built Web game preserves pause input,
  cursor visibility, Korean default copy, English switching, and report
  navigation.

The Milestone 6 handoff records the UIUX-gate evidence fields explicitly:
surface and primary task, Level 4 invocation depth, files/screens touched,
`960×540`/`1280×720`/`1920×1080` viewports, warning/active/dormant/depleted/
empty/selected/focus/paused/report states, keyboard and non-color checks,
capture paths, accepted exceptions, remaining warnings, and pass/blocked
result. Rendered captures, not node-tree inspection alone, are the visual
authority.

## Completion Criteria

- [ ] All six milestone outcomes are complete in coherent scoped commits.
- [ ] The current stage count/order, field IDs, combat caps, balance values, and
  collision truth remain unchanged except for the explicitly retired Flow
  Channel and moving support-field placement.
- [ ] Every catalog stage and selectable field passes deterministic layout,
  intact-bulkhead clearance, restart, and adjacent-stage variation assertions.
- [ ] Four support slots pass schedule, staggering, pause, depletion, and effect
  limits with no per-field scene nodes or unbounded dynamic arrays.
- [ ] HUD/minimap/report behavior passes at all three supported capture sizes in
  Korean and English, and every referenced image is inspected at actual
  gameplay scale.
- [ ] Source and attribute totals agree within `0.01` for stage completion and
  failure reports; environment damage cannot enter either player partition.
- [ ] The authoritative `current_pressure` JSON reports
  `scenario_validation.valid == true` and `thresholds.passed == true`.
- [ ] The production Web export succeeds and the registered built-app flow is
  manually checked at `1280×720`.
- [ ] Accepted durable behavior is incorporated into
  `docs/product/vehicle_game_spec.md` and
  `docs/design/UI_VISUAL_SYSTEM.md`; this plan is marked `done` and then deleted
  after no unchecked work remains.

## Stop Conditions

Stop implementation and request direction only if:

- exhaustive deterministic cover-mask search cannot produce a distinct valid
  child for an existing stage without changing the authored macro topology;
- a field cannot provide twelve valid support sockets without changing its
  walkable/water boundary or reducing the locked four-field design;
- preserving explicit damage ownership requires changing accepted damage,
  lifesteal, status, or difficulty behavior rather than attribution alone;
- the authoritative rendered gate still fails after task-owned regressions are
  isolated, and the remaining correction belongs to the separate active
  performance-architecture plan or requires balance/cap changes;
- the production Web failure is caused by unavailable external runtime state
  rather than repository code.

Ordinary compile errors, validator failures, temporary support-socket
occupancy, layout fallback, capture fixture drift, and localization omissions
are implementation work, not reasons to reopen the design.

## Rollback / Safety

- Commit each milestone separately. Do not mix balance or content changes into
  these commits.
- Preserve stable field, stage, upgrade, card, guidebook, setting, and damage
  source IDs. Flow Channel is the only intentionally retired ID.
- Keep a compatibility accessor for the active stage cover during the layout
  migration; delete the old run-global cover fields only after all consumers
  and validators use the stage accessor.
- Keep geometry and collision sourced from the same active layout. Never fix a
  visual mismatch by adding presentation-only blockers.
- Do not mutate the active performance plan or claim its final release matrix
  is complete.
- If no prevalidated support socket is temporarily available at runtime, defer
  relocation and log one bounded warning in debug builds; never place through a
  wall, on an actor, or inside another field.
- If the new report's source and attribute totals diverge, block report
  completion and fix attribution rather than normalizing percentages to hide
  the mismatch.

## Risks

- Switching stage cover touches collision, line of sight, pursuit, backdrop,
  minimap, spawn validation, and projectiles. Atomic stage activation and the
  shared geometry snapshot are required to prevent one-frame disagreement.
- Four moving support fields could reduce difficulty. The shared 24-hull budget,
  non-stacking overdrive, overlap rejection, and unchanged enemy tuning bound
  that risk.
- Individual enemy minimap nodes would reintroduce HUD cost. Cell clustering
  and the existing 10 Hz channel are mandatory.
- Whole-mesh tint would also darken cockpit and hit feedback. Separate retained
  player parts and explicit feedback priority are mandatory.
- Attribute telemetry can double-count status and direct damage. Each applied
  damage event must choose exactly one attribute, while source and attribute
  totals remain parallel partitions.
- Removing Flow Channel affects guidebook discovery persistence. Unknown saved
  discovery IDs must remain harmless and ignored; no save reset is authorized.

## Open Questions

None. Product behavior, tuning constants, ownership, file scope, validation, and
stop conditions are decision-complete for implementation.

## Next Steps

1. Execute Milestone 1 and commit the stage-layout/spec contract.
2. Execute Milestone 2 and validate all four independent field schedules.
3. Continue through HUD, vehicle presentation, telemetry, and final QA without
   reopening the locked decisions unless current code contradicts a named
   invariant.

## Decision Notes

- The macro field stays fixed; tactical cover and content vary by stage. This
  reconciles run identity with the requested stage-to-stage variation.
- Only repair and overdrive relocate. Arc, gate, and bulkhead behavior remains
  authored so the field retains stable landmarks and collision truth.
- Four support slots are enough to create movement choices while staying
  low-count and performance-bounded.
- Support lifetimes are intentionally different per instance, and a central
  arbiter guarantees staggered relocation rather than relying on phase offsets
  that could eventually align.
- Count and radius are complete visual signals. Shade is reserved for
  otherwise-invisible permanent power changes.
- Friendly projectiles use ownership color; hostile attacks retain affinity
  semantics. This removes accidental white player rounds without erasing
  hostile attack readability.
- Stage reports use source and attribute as separate 100% views of the same
  outgoing damage total.
