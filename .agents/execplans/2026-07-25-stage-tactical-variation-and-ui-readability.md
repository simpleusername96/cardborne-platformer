---
type: plan
status: active
owner: BK
created: 2026-07-25
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
- “More fields” means four low-count support-field instances: two repair and two
  overdrive. It does not mean four of every functional terrain type.
- “Fields must not all move together” means one central relocation arbiter
  permits at most one support field to enter relocation during any rolling
  three-second window. A ready field waits; it never skips validation.
- “Each field has a different duration” means every one of the four instances
  has its own fixed active and dormant duration, not only a different duration
  per category.
- Secondary levels already communicated by a visible count or radius receive no
  shade tier. A separate passive-damage stat may use one small shared secondary
  power core because its value is not the count of any family.
- The user's projectile color feedback applies to player projectiles. Hostile
  projectiles and telegraphs keep affinity colors and shapes.
- The existing 10 Hz tactical HUD channel is sufficient for minimap movement.
  Combat simulation and collision stay at their current cadence.

## Proposed Design — Locked Decisions

### 1. Stage-local tactical layout

`VehicleFieldLayout` remains the immutable run-scoped owner, but stores one
compiled tactical layout per stage:

- `stage_cover_ids[stage_id]`
- `stage_cover_rects[stage_id]`
- `stage_geometry_snapshots[stage_id]`
- `stage_objects[stage_id]`
- `stage_support_sockets[stage_id]`
- `encounter_seeds[stage_id]`

The generator uses `hash(layout_seed, stage_id, channel_version)` for every
stage-local channel. A retry uses the same seed and fingerprint. Adjacent stages
must not have an identical canonical cover-ID set or identical object/socket
blueprint. If a random candidate fails, the existing deterministic mask
fallback is applied per stage; it never falls back to unvalidated geometry.

Each stage selects eight cover rectangles using the current sector model.
Existing radius, floor, water, start-clearance, feature-clearance,
cover-clearance, reachability, ordinary-anchor, and boss-anchor checks remain
mandatory. Static arc/gate/bulkhead footprints stay reserved. Repair,
overdrive, stationary, pickup, crate, and support sockets are selected after
cover so they cannot overlap it. The generator filters the field's existing
authored `item_socket_candidates`, excludes the eight sockets assigned to stage
pickups and crates, and stores at least twelve remaining points whose complete
180-pixel support footprint passes floor, water, cover, feature, start, and
reachability checks. These become `stage_support_sockets`; no second random
point generator is introduced.

At stage activation, `VehicleRun` switches the current stage layout before
resetting the player, enemies, terrain runtime, backdrop, blockers, pursuit
field, minimap static geometry, and encounter coordinator. Nothing may retain a
previous stage's cover array or geometry snapshot.

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

Every slot runs `warning → active → dormant → relocation request`. The world
circle appears during warning, becomes effective only while active, and drains
one clockwise boundary arc from 100% to 0%. The final 20% uses a thicker inner
notch as a shape cue; it does not flash or add text.

The relocation arbiter:

- grants at most one relocation every 3.0 seconds;
- seeds each choice with
  `layout_seed + stage_id + slot_id + relocation_index`;
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
Overdrive remains 1.20x only while inside an active field, does not stack when
two fields are nearby, and is removed immediately when a slot leaves active
state. This preserves current difficulty while preventing one-position
camping.

### 3. HUD, minimap, and field readability

At `1280×720`:

- Hull/experience remains at `(18, 16)`, `184×54`.
- The bottom action dock is removed.
- A `158×34` action rail sits at `(18, 76)` with four `34×34` icon slots and
  6-pixel gaps: primary, passive, dash, EMP.
- The rail has no key names, action text, or opaque outer panel. Cooldown,
  ready, and disabled states use the existing icon silhouette plus a maximum
  3-pixel radial sweep.
- Bindings and text remain available in settings and the guidebook.
- The objective stays top-center as one restrained line.
- The minimap stays top-right but loses its title row; a `176×108` tactical map
  uses the full cluster with one thin border and dim background.

The same anchors scale down at `960×540` without overlap and scale by viewport
anchors at `1920×1080`. No new HUD content is placed at bottom center.

The minimap keeps the existing 20×12 exploration mask and receives:

- player triangle plus facing line;
- ordinary mobile enemies clustered by minimap cell, using one coral dot whose
  radius encodes a bounded `1`, `2–4`, or `5+` count and whose short tick shows
  average velocity;
- stationary threats as squares;
- elites as outlined diamonds;
- the boss and boss warning as their existing unique marker;
- repair and recall items after their cell is explored;
- every currently warning or active support field regardless of fog, because
  these are time-limited strategic destinations;
- a support-field ring whose remaining arc matches the world-space lifetime.

The ordinary cluster channel is bounded by the 240 minimap cells rather than
the enemy cap. Priority actors remain individual. Static geometry is resent
only on stage-layout change; positions, clusters, items, and field timers stay
on the existing 10 Hz dynamic channel.

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
is regenerated from production mesh code and must match these rules before the
runtime implementation begins.

### 5. Stage telemetry and report

Every player-owned applied-damage event records two independent dimensions:

1. its existing source (`primary`, seeker, ion field, orbit blade, wake mine,
   drone, EMP, dash, status, and so on);
2. exactly one damage attribute: `kinetic`, `thermal`, `toxin`, `cryo`, or
   `arc`.

The two views are alternative partitions of the same outgoing total, not values
to add together. Both totals must match within `0.01`.

- Direct primary and physical secondary damage is kinetic.
- Burn ticks and Flashover damage are thermal.
- Poison ticks are toxin.
- Shatter bonus damage is cryo.
- EMP, arc surge, and player arc-mine damage are arc.
- Reflected damage preserves the original applied attack attribute.

`VehicleStatusRuntime.tick()` returns separate burn and poison amounts instead
of one combined float. Opening resolution returns separate thermal Flashover
and cryo Shatter bonuses. Application counts for burn, poison, and chill are
stored as bounded integers so chill can remain visible in the report even when
it contributes control but no direct damage.

At `1280` and wider, the stage report uses three columns: enemy defeats, damage
by source, and damage by attribute. At compact width it uses three
keyboard-accessible tabs. Every attribute row has a large shape icon, localized
name, amount, and percentage. Chill application count appears in the cryo row;
it is never converted into invented damage.

## Tasks

### Milestone 1 — Canonical contracts and stage layout ownership

- [ ] Update `docs/product/vehicle_game_spec.md` and
  `docs/design/UI_VISUAL_SYSTEM.md` to replace run-fixed tactical placement,
  fixed support facilities, Flow Channel, hybrid player projectile color,
  bottom action dock, two-column report, and limited minimap markers with this
  plan's locked contracts.
- [ ] Extend `scripts/vehicle/vehicle_field_layout.gd` with stage-local cover,
  geometry, objects, support sockets, accessors, canonical blueprint,
  fingerprints, and per-stage broadphase activation.
- [ ] Extend `scripts/vehicle/vehicle_field_layout_generator.gd` to compile and
  validate one tactical layout per stage, including distinct-adjacent-stage and
  exact-retry invariants.
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
  geometry consumers atomically before encounter state begins.

### Milestone 2 — Dynamic support-field runtime

- [ ] Extend `scripts/vehicle/vehicle_terrain_definition.gd` with scheduled
  support-slot identity and lifecycle snapshot fields.
- [ ] Refactor `scripts/vehicle/vehicle_terrain_runtime.gd` to own the four
  fixed slots, independent state machines, shared relocation arbiter, repair
  budget, non-stacking overdrive, and deterministic socket history.
- [ ] Remove `flow_vector_at()` callers and Flow Channel rendering/discovery
  paths from `scripts/vehicle/vehicle_run.gd`.
- [ ] Render warning, active fill, exact boundary, and remaining-time arc in
  `scripts/vehicle/vehicle_run.gd` without text or per-field scene nodes.
- [ ] Remove the Flow Channel guide entry from
  `scripts/progression/vehicle_guidebook_catalog.gd`,
  `scripts/ui/vehicle_guidebook_preview.gd`, and
  `localization/vehicle_stage.csv`; update repair and overdrive copy for
  relocation and independent lifetime.

### Milestone 3 — Compact HUD and tactical minimap

- [ ] Update `scripts/ui/vehicle_stage_ui.gd` to remove the bottom dock, create
  the icon-only top-left rail, remove the minimap title row, draw clustered
  mobile velocity markers, priority actors, items, support fields, and lifetime
  arcs.
- [ ] Extend `scripts/ui/vehicle_hud_presenter.gd` only with dirty channels
  needed for stage-layout invalidation and 10 Hz tactical data.
- [ ] Extend `scripts/vehicle/vehicle_run.gd::_minimap_snapshot()` to emit
  bounded cell clusters and support-field state; do not send one ordinary
  marker per enemy.
- [ ] Preserve the current world threat radar and status-orbit ownership; do
  not duplicate visible enemies in both threat radar and off-screen arcs.
- [ ] Update Korean and English HUD/guide copy in
  `localization/vehicle_stage.csv`.

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

### Milestone 5 — Attribute telemetry and report UI

- [ ] Extend `scripts/combat/vehicle_stage_telemetry.gd` with bounded stage/run
  attribute totals and condition-application counters.
- [ ] Split status results in
  `scripts/combat/vehicle_status_runtime.gd` and pass explicit attributes from
  every outgoing damage call site in `scripts/vehicle/vehicle_run.gd`.
- [ ] Extend `scripts/combat/vehicle_stage_report_builder.gd` with sorted,
  percentage-assigned attribute rows and the source-total equality invariant.
- [ ] Extend `scripts/ui/vehicle_stage_report_panel.gd` to three columns at wide
  width and three tabs at compact width.
- [ ] Add complete Korean/English attribute labels and accessibility text to
  `localization/vehicle_stage.csv`.

### Milestone 6 — Validation, rendered QA, and lifecycle close

- [ ] Add or extend focused validators listed in Test Plan.
- [ ] Run every focused validator with zero errors and zero orphan-node or
  leaked-resource warnings.
- [ ] Export the production Web build with `tools/export_web.ps1`.
- [ ] Capture Korean and English gameplay, minimap, pause, and report states at
  `960×540`, `1280×720`, and `1920×1080` from the built path.
- [ ] Verify a fixed seed through two exact retries and two adjacent stages.
- [ ] Run the current rendered pressure scenario and confirm this work does not
  exceed the accepted entity/projectile caps or regress the current development
  smoothness stop condition.
- [ ] Record material behavior in the active specs, set this plan to `done`,
  and remove it once no unchecked implementation work remains.

## Test Plan

Run from the repository root:

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_field_layout_generation.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_navigation_clearance.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_terrain_runtime.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_hud_presenter.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_combat_renderer.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_status_stacking.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_secondary_weapons.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_telemetry.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_report.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_guidebook.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_rewards_ui_audio.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_run.gd
.\tools\export_web.ps1
```

Required automated assertions:

- The same field/seed/stage produces byte-equivalent canonical blueprints.
- Adjacent stages produce different cover and tactical object blueprints.
- All cover, objects, support sockets, and current support circles are
  reachable, non-overlapping, outside start clearance, and clear of static
  functional terrain.
- No support field enters relocation within three seconds of another.
- All four slots preserve their declared independent lifetime sequence.
- Repair never exceeds 24 hull per stage across both slots.
- Overdrive never stacks above 1.20x.
- Minimap ordinary markers are bounded by 240 cell clusters.
- Static minimap geometry changes once per stage activation, not at 10 Hz.
- Wide and compact HUD contracts contain no bottom-center action panel, no text
  in the live action rail, and no overlap.
- Count/radius-readable secondaries do not receive a tier-shade input.
- Player projectile rendering ignores player affinity color but hostile
  rendering still consumes it.
- Source and attribute outgoing totals match within `0.01`.
- Korean and English expose identical controls, tabs, report rows, and guide
  entries.

Required rendered checks:

- At least two support fields are visible in one representative capture and
  their different remaining arcs are immediately distinguishable.
- A relocation warning appears at a new valid socket before the field becomes
  effective.
- The minimap shows moving enemy clusters, stationary threats, an item, and
  timed support fields without concealing the player marker.
- Hull shade levels, zero-to-three engines, primary shade levels, secondary
  core levels, count/radius secondaries, and fixed player projectiles match the
  reference sheet at gameplay scale.
- The three-column report is readable at `1280×720`; all three compact tabs are
  keyboard reachable at `960×540`.

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
- If a stage has no valid support socket, defer relocation and log one bounded
  warning in debug builds; never place through a wall, on an actor, or inside
  another field.
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
