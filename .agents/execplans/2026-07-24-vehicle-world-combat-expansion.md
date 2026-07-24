---
type: plan
status: active
owner: BK
created: 2026-07-24
last_reviewed: 2026-07-24
scope: Implement three persistent run-level fields, unified wall truth, functional terrain, meaningful Breach Shot interactions, interactive mines, additional enemy roles, distinct bosses, visual guidebook entries, and a damage recap
related:
  - ../PLANS.md
  - ../vehicle-world-combat-expansion-evidence.md
  - ./2026-07-23-vehicle-performance-architecture-stabilization.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
---

# Vehicle World and Combat Expansion ExecPlan

## Purpose

The current build is a playable five-stage vehicle shooter, but its physical
field and boss encounters do not yet communicate enough meaningful decisions.
All functional terrain from the earlier multi-map campaign was deleted during
the shared-field rebuild. The surviving field draws several nonfunctional floor
motifs, while impassable boundaries and internal cover use inconsistent visual
language. The one-second opening shot has numeric bonuses but no exclusive job.
Mines punish only the player, the guidebook is text-only, and the five bosses
mostly reuse the same runtime attack grammar.

This plan expands the game without reversing the persistent-field decision or
raising the active-enemy capacity. After completion, a new run selects one of
three authored field layouts and keeps it for all five stages and retries.
Every solid boundary has one visual and collision truth. Functional terrain
affects both sides. The opening shot becomes a tactical Breach Shot. Mines,
new enemy roles, and five distinct bosses create learnable combat interactions.
The guidebook shows what discovered threats actually look like.

## Scope

### In scope

- Three total, same-theme field layouts selected once per new run.
- A unified static-wall and boundary-rail contract.
- Complete removal of decorative map motifs.
- Flow Channel, Arc Surge Strip, and Breakable Bulkhead terrain.
- Breach Shot behavior, presentation, localization, and counterplay.
- One-shot friendly-fire stationary mines and active mobile minelets.
- Three additional non-projectile enemy roles.
- Three-phase, stage-specific boss behaviors and silhouettes.
- Visual guidebook previews and concise counterplay hints.
- A localized damage-source recap on failure.
- Canonical product/design documentation, Korean/English localization, focused
  validation, production Web export, and rendered evidence.
- Performance evidence inside the current declared capacity envelope.

### Non-goals

- A different physical map per stage.
- A fourth field or runtime procedural topology.
- A new game engine, dependency, renderer, raster asset pack, or shader.
- Raising the `72` ordinary-enemy active cap or projectile capacities.
- New currencies, base stage, exploration puzzles, meta progression, equipment
  repair, or an expanded pickup taxonomy.
- Redesigning current card progression or difficulty selection.
- Adding boss practice, optional challenge rooms, or elite modifiers.
- Rebalancing all existing enemy health and damage.

## Success Criteria

- A seeded new run selects one of three fields, and its field ID, collision,
  terrain, cover selection, and explored minimap remain coherent through all
  five stages.
- No decorative floor motif remains, and a player can identify every
  impassable static boundary solely from the shared wall fill, rail, and shadow.
- Flow Channels and Arc Surge Strips visibly match their exact simulation and
  create intentional interactions with both the player and enemies.
- Breach Shot has four reliable purposes—bulkhead, mine, guard plate, and boss
  recovery—without interrupting held primary fire.
- Mines are readable one-shot state machines, can damage enemies, cannot damage
  through walls, and never lose quota or XP attribution.
- Spark Minelets and the three new roles add stage-by-stage decisions without
  raising the active enemy or projectile envelope.
- Each of the five bosses has a distinguishable silhouette, three behavioral
  phases, one unique spatial mechanic, and one base-speed-avoidable final exam.
- Every discovered enemy, boss, mine, and terrain entry has a matching visual
  preview and concise Korean/English counterplay; locked entries leak nothing.
- Failure recap, focused validators, production Web export, rendered UI/UX
  evidence, and all active performance gates pass.

## Locked Assumptions and Constraints

- Godot `4.7` stable and GDScript remain the implementation platform.
- Korean remains the default language and every new user-facing string has
  complete Korean and English entries.
- Manual aim, held primary fire, one-second idle priming, dash, passive
  secondaries, EMP, five-stage flow, card upgrades, field bosses, and stage
  bosses remain intact.
- One run uses one immutable field topology through all stages and retries.
- `5600x3400`, center `(2800,1700)`, camera zoom `1`, and `480 px` center
  clearance remain common field contracts.
- The Sunken Ceramic Fresco palette and flat-color, large-shape style remain.
- A passable floor overlay may use semantic colors, but every solid static
  obstacle uses the same ceramic-green wall base and common shadow.
- Visual geometry does not become collision authority. One compiled field
  snapshot feeds collision, navigation, projectile clipping, minimap, and
  presentation.
- No attack added by this plan requires dash. From the first damaging warning
  frame, base movement speed has a valid escape route with at least `40 px`
  margin.
- The active performance ExecPlan remains authoritative for frame, draw-call,
  lifecycle, and soak thresholds. This plan may not bypass or relax it.

## Current State and Evidence

The full audit is in
`../vehicle-world-combat-expansion-evidence.md`. Implementation must preserve
these facts:

- Historical current and storm hazards existed in commit `278be30` and were
  removed by `cb40059`; they are not present in the current runtime.
- `drowned_ruin_field.gd` owns four decorative motifs with no gameplay.
- collision is currently composed from the walkable union, water, selected
  covers, and live crates, but those blockers do not share one rendered wall
  language;
- the current opening shot cannot cross the `35` boss stagger threshold;
- the stationary mine is repeatable and damages only the player;
- `spark_minelet` exists in data and visuals but is unused by stage role sets;
- current populations already reach `420` authored enemies and `72` active
  ordinary enemies;
- the guidebook snapshot contains no preview metadata; and
- boss pattern names vary, but several kinds share generic execution.

## Accepted Product Design

### 1. Run-level field selection

Add exactly three registered field definitions:

| Field ID | Spatial identity | Terrain emphasis | Persistent rule |
| --- | --- | --- | --- |
| `drowned_ruin_field` | Open central plaza, four broad outer courts, north/south loops | One Flow Channel, one Arc Surge Strip, two Breakable Bulkheads | Selected once and kept for stages 1–5 and retries |
| `tidal_archive_field` | Two broad lateral halls joined by three crossings and one central court | Two Flow Channels, one Arc Surge Strip, two Breakable Bulkheads | Same |
| `storm_drydock_field` | Large center basin with two wide perimeter loops and four diagonal approaches | One Flow Channel, two Arc Surge Strips, two Breakable Bulkheads | Same |

Each definition must provide:

- at least sixteen broad walkable regions;
- exactly twenty-four ordinary spawn candidates;
- exactly eight boss arrival anchors;
- sixteen cover candidates split into four quadrants, selecting eight per run;
- at least twenty-four item sockets;
- four stationary-enemy candidate groups;
- a `480 px` empty center;
- no corridor narrower than `320 px`;
- no dead-end pocket shorter than `480 px`;
- two vertex-disjoint routes from center to every outer court after selected
  cover and intact bulkheads are applied; and
- terrain zones that do not overlap the center clearance, spawn anchors, boss
  anchors, pickup sockets, or stationary sockets.

`field_id` is derived deterministically from the layout seed with a stable
`field:v1` sub-seed. Add a `--field-id=<id>` debug override. Deployment shows
the selected localized field name as read-only context. The selected ID and
compiled layout remain in `VehicleFieldLayout` through all stage transitions
and stage restarts; only a new run may choose again.

### 2. One wall truth and zero motifs

Delete the motif contract completely:

- remove `motifs` from field definitions and required catalog fields;
- delete `_motifs()` and the four motif draw functions;
- delete motif colors/constants from the visual profile;
- remove motif assertions from validators and canonical specifications; and
- do not leave disabled motif data or presentation branches.

Introduce a compiled `VehicleFieldGeometrySnapshot` owned by the field-layout
pipeline. It exposes immutable:

- walkable polygons;
- selected static-cover rectangles;
- live breakable-bulkhead rectangles;
- wall boundary segments/loops;
- water/background polygons;
- terrain zones;
- navigation occupancy;
- spawn, boss, item, and stationary sockets.

The shared wall presentation contract is:

| Token | Locked value |
| --- | --- |
| `WALL_FILL` | Existing ceramic green |
| `WALL_SHADOW` | Existing deep cobalt shadow |
| `WALL_RAIL_WIDTH` | `48 px` |
| `WALL_SHADOW_OFFSET` | `(0, 12)` |
| static cover/bulkhead base | Same fill, rail, and shadow |
| collision-only color variants | None |

Derive wall boundary loops from the merged walkable union. Draw the `48 px`
rail centered on the physical boundary, so its floor-side edge lies `24 px`
inside the floor and matches the base ship-center clearance. Fill internal
solid islands with `WALL_FILL` and the same shadow. A cobalt outside/water mass
may remain behind the field but may never be the only visual sign of collision.
Any nonwalkable internal hole is either filled as a wall island or enclosed by
the identical rail. No decorative line, motif, floor-tone change, or water
color may imply collision when none exists.

The snapshot is the only source consumed by:

- player and enemy movement;
- pursuit/navigation;
- player and enemy projectile clipping;
- line of sight;
- backdrop drawing;
- minimap static geometry; and
- layout validators.

### 3. Functional terrain contract

Add exactly three initial terrain families. Terrain is authored in field data
and executed by one low-count `VehicleTerrainRuntime`; it does not create one
node per zone or actor.

#### Flow Channel

| Rule | Locked behavior |
| --- | --- |
| footprint | Passable rectangle or polygon at least `320 px` wide |
| player | Adds a `72 px/s` world-space vector after input acceleration and before collision resolution |
| ordinary mobile enemy | Receives the full `72 px/s` vector |
| boss | Receives `36 px/s` |
| stationary enemy | Unaffected |
| projectiles | Unaffected |
| visual | One muted mint/cobalt strip and three large ivory chevrons; no repeating micro-pattern |
| discovery | First camera visibility unlocks the guidebook object entry |

The same vector applies continuously while an actor center is inside the exact
visible footprint. Collision still resolves against the same compiled wall
snapshot, so a current cannot push an actor through a wall.

#### Arc Surge Strip

| Rule | Locked behavior |
| --- | --- |
| cycle | `5.2 s` |
| warning | `1.4 s` |
| active | `0.8 s` |
| player damage | `10` once per active window |
| ordinary-enemy damage | `18` once per active window |
| boss damage | `6` once per active window |
| stationary enemy | Takes the ordinary-enemy value |
| visual | Exact violet boundary, continuous warning fill from `0%` to `100%`, then one active flash |
| discovery | First camera visibility unlocks the guidebook object entry |

One actor cannot be hit twice by the same strip in one active window. Damage is
environmental, participates in the normal accepted-hit feedback, and records
the strip as a damage source. A player-triggered mine explosion may overlap a
surge, but each source resolves independently.

#### Breakable Bulkhead

| Rule | Locked behavior |
| --- | --- |
| count | Exactly `2` per field |
| health | `72` structure |
| blocking | Movement, navigation, line of sight, and both projectile teams |
| visual base | Identical `WALL_FILL`, rail, and shadow |
| state hint | One large mustard fracture glyph; no alternate wall fill |
| normal fire | Deals normal structure damage |
| Breach Shot | Deals exactly `72` structure and breaks an undamaged bulkhead in one hit |
| persistence | Broken through later successful stage transitions in the same run; reset on a stage restart/replay or new run |
| placement | Never required for center-to-court connectivity |

The bulkhead has `intact`, `breaking`, and `broken` states. `breaking` lasts
`0.18 s`, disables collision on the same simulation tick as health reaches
zero, and emits only bounded fragments/effects from the existing effect batch.
It drops no item and grants no experience.

At most three functional-terrain footprints may intersect a normal gameplay
viewer at once. This is a readability constraint, not a simulation shortcut.

### 4. Breach Shot

Rename the user-facing “opening shot” to `Breach Shot` / `돌파탄`. Its baseline
still primes automatically after exactly `1.0 s` without primary fire and
consumes the primed state on the next primary shot. Existing card modifiers may
shorten that baseline only through the established
`opening_seconds_multiplier`; this plan adds no second charge timer.

Use these final modifiers:

| Property | Breach value |
| --- | --- |
| health damage | `1.85x` base primary damage |
| structure damage | `4.0x`, equal to `72` at the current base |
| radius | `1.75x`, equal to `12.25 px` at the current base |
| pierce | `+1` |
| stagger | `40` |

Its exclusive jobs are:

- break a full-health Breakable Bulkhead in one hit;
- force an Arc Mine into its `0.40 s` short fuse;
- remove a full-health Bulkhead Guard front plate in one hit;
- cross the current `35` boss stagger threshold with one hit during recovery.

The center projectile owns the Breach interaction. Its structure damage is
never reduced below `72` by Forked Muzzle's per-projectile falloff, and its
stagger is never reduced below `40`; side projectiles keep their normal scaled
values. This prevents an acquired multishot upgrade from disabling the
bulkhead, guard, mine, or boss-recovery purpose.

A boss accepts at most one Breach stagger per committed attack. Further stagger
is locked until the boss begins another attack, preventing a permanent loop.
Outside boss recovery, stagger accumulates no hidden carry-over.

Presentation uses:

- a collision head exactly matching the `12.25 px` damaging radius;
- a mustard/ivory double-diamond head;
- a `48 px` tapered trail distinct from normal fire;
- a stronger muzzle flash and the existing opening-shot audio channel;
- a complete primed ring near the ship/reticle plus the existing HUD readiness
  channel; and
- a short localized guidebook counterplay line.

Held fire resumes at the existing repeat cadence after the Breach Shot. No new
input, manual charge, or firing lockout is added.

### 5. Mines affect both teams

#### Stationary Arc Mine

Replace the reusable cycle with:

`Dormant -> Armed -> Exploding -> Retired`.

| Transition or effect | Locked behavior |
| --- | --- |
| player enters `190 px` | Arms with a `1.25 s` fuse |
| player damage reduces health to zero | Arms or shortens the fuse to `0.40 s`; never disappears silently |
| enemy proximity alone | Does not arm the mine |
| explosion radius | `205 px`, shown exactly |
| center damage | `26`, linearly tapering to `45%` at the edge |
| targets | Player and every enemy except the source mine |
| boss multiplier | `0.25x` |
| ownership | Player proximity or player damage marks the mine as player-triggered; enemy casualties credit quota/XP while player damage received still names `arc_mine` |
| lifecycle | Retires after one explosion |

An armed ring fills continuously and holds the exact explosion boundary. A mine
hit by another mine does not explode in the same frame. It is armed with at
least `0.35 s` remaining fuse, inherits the originating player trigger, and one
explosion may arm at most six other mines, selected by deterministic distance
order.

#### Mobile Spark Minelet

Activate the existing archetype from stage 2 onward:

- trigger radius `110 px`;
- fuse `0.85 s`;
- explosion radius `120 px`;
- center damage `14`;
- same all-team damage and ownership rules;
- no ranged projectile;
- no more than twelve live minelets; and
- no more than six may be in `Armed` state simultaneously.

Mine explosions stop at neither ordinary enemies nor the player, but they do
not pass through static walls: exposure is checked against the same line-of-
sight/wall snapshot before damage.

### 6. Enemy variety inside the existing capacity

Do not change current authored stage populations, quotas, or the `72` active
ordinary-enemy cap in this plan. Activate the existing Spark Minelet and add
three roles:

| Role | Base contract | Tactical decision | Capacity rule |
| --- | --- | --- | --- |
| Bulkhead Guard | `90` health, `140 px/s`, `24 px` radius, melee; frontal plate has `72` structure and blocks frontal health damage | Reposition around it or use one primed Breach Shot to remove the plate | Maximum `8` live |
| Relay Scavenger | `55` health, `190 px/s`, `18 px` radius; seeks nearby XP instead of firing | Kill it before it escapes with collected XP | Maximum `4` live; target query at `5 Hz` within `360 px` |
| Splitter Barge | `96` health, `120 px/s`, `26 px` radius, melee | Control space before it dies and splits | Maximum `6` live; spawns exactly two summon-only Scrap Drones when capacity permits |

Relay Scavengers never delete player-owned experience. They hold the exact
collected value and drop it plus three experience on death. If retired by a
stage transition, held experience is returned at the transition center.

Splitter children do not add quota or experience and use the existing summon
capacity. No more than twelve splitter children may be live. If capacity is
full, missing children are skipped rather than queued.

Roll out the mechanics as:

| Stage | New lesson | Combination |
| --- | --- | --- |
| 1 | Existing baseline plus one terrain family at a time | Mine friendly fire appears in an authored low-pressure packet |
| 2 | Spark Minelet | Flow Channel changes minelet approach vectors |
| 3 | Bulkhead Guard | Arc Surge and guard positioning |
| 4 | Relay Scavenger | Player chooses between threat removal and XP denial |
| 5 | Splitter Barge and all prior roles | Terrain, support, melee, and ranged roles combine under the existing cap |

Projectile-firing ordinary roles remain no more than `50%` of active ordinary
enemies. The three additions are non-projectile roles.

### 7. Five distinct boss exams

Extract boss state and execution from `VehicleRun` into a dedicated
`VehicleBossRuntime`. Keep data-owned pattern definitions under `scripts/bosses`
and keep presentation dependent only on a boss snapshot.

#### Shared boss rules

- Three phases: phase 1 above `65%` health, phase 2 from `65%` through `30%`,
  phase 3 below `30%`.
- Between committed attacks, the boss pursues or repositions toward its
  stage-specific preferred range. Normal hits never stop movement or attack
  timers.
- Phase sequence gaps are `0.55 s`, `0.42 s`, and `0.32 s`.
- Every direct attack retains its authored startup tell; phase escalation comes
  from combinations and reduced dead time, not removed warning.
- No immediate attack repeat.
- Phase 2 may layer one low-reaction space-control pattern with one direct
  response pattern.
- Phase 3 has one fixed authored combo per boss.
- Light hits remain `20–22`, standard hits `26–30`, and heavy hits `32–36`.
- Every exact damaging footprint is visible from startup through impact.
- Target position/direction locks when the warning first appears and does not
  chase the player afterward.
- Base movement has a valid escape route with at least `40 px` margin.
- Boss projectile reserve remains at most `24`.
- One Breach Shot during recovery can stagger once per committed attack.
- Phase transitions do not erase excess damage.

#### Stage-specific identities

| Boss | Phase-1 vocabulary | Phase-2 layer | Phase-3 exam |
| --- | --- | --- | --- |
| Foundry Colossus | Furnace Gates: two slow projectile walls with one `180 px` gap; Foundry Ram: locked charge | Slag Ring plus two overload pylons | Furnace Gates establish the gap, then Foundry Ram crosses it along a separately warned line |
| Archive Leviathan | Current Fan: slow gapped fan; Archive Lunge: locked pursuit burst | Undertow Lanes add temporary Flow vectors; three staggered Depth Charges lock their circles | Undertow moves the player while three fixed Depth Charges demand route choice |
| Drydock Titan | Titan Pulse: radial ring plus one aimed pair; Grounding Grid: two warned Arc strips with one safe lane | Thunder Chain places three fixed circles in order; at most two Beam Sentinels are called | Grounding Grid activates, then Titan Pulse tests the remaining safe lane |
| Switchyard Behemoth | Breaker Charge; Ricochet Volley with its single-bounce path fully warned | Four one-shot mines establish space; two fixed Switch Sweeps cross afterward | Minefield arms first, then the two sweeps leave one base-speed route through it |
| Crown Engine | Crown Lattice: four ordered lanes; Relay Pulse: timed concentric rings | Carrier Wave calls one carrier and two escorts; Mirror Cross adds direct pressure | Royal Overload combines ordered lattice lanes with concentric timing, never overlapping all exits |

Give every boss a distinct `boss_variant` mesh in
`VehicleCombatVisualLibrary`, using large flat-color masses and no micro-detail:

- Colossus: broad furnace shoulders;
- Leviathan: long split prow;
- Titan: square grounded core;
- Behemoth: forward breaker wedge; and
- Crown Engine: radial crown frame.

The same variants appear in combat, minimap boss markers, guidebook previews,
and boss HUD labels. Pattern affinity still controls effect color; silhouette
does not recolor to communicate collision.

### 8. Visual guidebook and learning aids

Add a reusable `VehicleGuidebookPreview` `Control`. It receives preview metadata
and draws the exact mesh from `VehicleCombatVisualLibrary`; it does not create
or load portrait images.

Unlocked enemy and boss entries contain:

- `preview_archetype` and optional `boss_variant`;
- one `176x176` desktop preview with a `128x128` minimum;
- localized Movement, Attack, and Counter rows;
- no raw health, speed, damage, quota, or hidden spawn data.

Locked entries show:

- the existing `???` name;
- one neutral generic silhouette not derived from the hidden archetype;
- no description, category count leak, color leak, or counterplay text.

Add object entries for:

- Flow Channel;
- Arc Surge Strip;
- Breakable Bulkhead; and
- Arc Mine.

Each object preview is one large semantic diagram: flow chevrons, surge timing
fill, fracture glyph, or armed mine ring. Discovery occurs when the object first
enters the camera-expanded viewer or the player interacts with it. The existing
guidebook persistence store records the ID.

The guidebook remains a modal focus layer. Verify Korean and English text,
keyboard/gamepad focus order, locked/unlocked states, reduced motion, and no
clipping at every supported size.

### 9. Failure damage recap

The failure/result panel adds a compact localized learning block:

- `마지막 피해 / Last hit`: source display name and amount;
- `가장 큰 피해원 / Top damage sources`: at most three source names with
  percentages for the completed attempt.

Sources are stable semantic IDs such as `arc_surge`, `arc_mine`,
`boss_foundry_ram`, `enemy_contact`, and `enemy_projectile`; they do not expose
internal node names. Reset the accumulator at the start of every attempt.
Environmental friendly-fire kills remain attributed correctly for quota and XP,
but the player's recap records only damage received by the player.

This information appears only on failure. It does not add live-HUD text.

## Ownership and File Boundaries

| Responsibility | Existing owner or new owner | Must not absorb |
| --- | --- | --- |
| Immutable field definitions and authored sockets | `scripts/vehicle/stages/*_field.gd` | Runtime timers, actor mutation, UI |
| Field registry and compiled collision snapshot | `vehicle_stage_catalog.gd`, `vehicle_field_layout_generator.gd`, `vehicle_field_layout.gd`, new `vehicle_field_geometry_snapshot.gd` | Boss rules, guidebook copy |
| Terrain definitions and low-count execution | new `scripts/vehicle/vehicle_terrain_catalog.gd`, `vehicle_terrain_runtime.gd` | Backdrop drawing, enemy rendering |
| Static field presentation | `vehicle_stage_backdrop.gd`, `vehicle_stage_visual_profile.gd` | Collision decisions |
| Primary and Breach Shot state | `scripts/player/vehicle_primary_weapon.gd` and run-build modifiers | UI layout, bulkhead lifecycle |
| Enemy definitions and specialist behavior | `vehicle_enemy_archetypes.gd`, `vehicle_enemy_specialist_runtime.gd` | Boss state, stage flow |
| Mine and enemy lifecycle | enemy runtime/store plus bounded query services | Guidebook discovery |
| Boss data and state | `vehicle_boss_patterns.gd`, new `vehicle_boss_runtime.gd` | General enemy store, HUD controls |
| Shared meshes/batched presentation | `vehicle_combat_visual_library.gd`, `vehicle_combat_renderer.gd` | Gameplay damage or collision |
| Guidebook metadata/persistence/UI | `vehicle_guidebook_catalog.gd`, `vehicle_guidebook_store.gd`, `vehicle_guidebook_panel.gd`, new preview control | Enemy behavior |
| Damage receipt and result summary | combat damage source IDs, run-attempt accumulator, result UI | Enemy quota attribution |
| Orchestration only | `vehicle_run.gd` | New catalogs, per-role algorithms, or presentation geometry |

Before implementation, identify each extracted block currently in
`vehicle_run.gd`; move behavior into the owner above instead of adding another
large branch to the orchestrator.

## Tasks

### Milestone 0 — Baseline, authority, and extension budgets

- [ ] Run the current focused vehicle validators and Web export before edits;
      save results under ignored `build/evidence/world-combat-expansion/baseline/`.
- [ ] Capture deterministic standalone and Web `1280x720` performance scenarios
      using the active performance plan's recorder.
- [ ] Record current guidebook, all five bosses, current motifs/walls, and one
      complete Stage 1 run at `1280x720`.
- [ ] Add the accepted contracts in this plan to
      `docs/product/vehicle_game_spec.md` and `docs/design/UI_VISUAL_SYSTEM.md`
      before gameplay code.
- [ ] Add a short implementation progress entry to this plan after every
      milestone without changing locked product decisions.

**Exit condition:** baseline evidence exists, canonical docs agree with this
plan, and no performance threshold was relaxed.

### Milestone 1 — Field registry and unified wall geometry

- [ ] Introduce the three-field registry and deterministic `field:v1`
      selection with `--field-id`.
- [ ] Make `VehicleFieldLayout` retain `field_id`, field definition, compiled
      geometry, terrain blueprint, and persistent bulkhead state.
- [ ] Replace global single-field caches in `VehicleStageCatalog` and layout
      generation with field-keyed immutable caches.
- [ ] Author and validate `tidal_archive_field` and `storm_drydock_field`.
- [ ] Compile merged walkable boundaries and one wall snapshot consumed by
      movement, projectiles, LOS, navigation, minimap, and backdrop.
- [ ] Remove all motif data, rendering, profile constants, localization copy,
      validators, and canonical references.
- [ ] Render every boundary and solid island with the locked shared wall
      material, rail, and shadow.
- [ ] Preserve the chosen field across stages/restarts and preserve broken
      bulkheads across successful stage transitions; a stage restart/replay
      restores its bulkheads.

**Acceptance:**

- every field passes player-radius, ordinary-radius, and boss-radius
  connectivity;
- all required sockets are reachable and clear;
- every blocked pixel boundary has the shared wall rail;
- no visually open slit rejects a `24 px` player;
- no rendered motif remains;
- stage transitions never change `field_id`; and
- field selection is deterministic for a fixed seed.

### Milestone 2 — Functional terrain and Breach Shot

- [ ] Add typed terrain definitions and one centralized runtime.
- [ ] Implement Flow Channel for player, ordinary mobile enemies, and bosses
      with wall-safe movement.
- [ ] Implement Arc Surge warning, one-hit-per-window damage, all-team
      interaction, and source attribution.
- [ ] Implement persistent Breakable Bulkheads using the same wall snapshot.
- [ ] Rename and rebalance the opening shot as Breach Shot.
- [ ] Add exact Breach visuals, readiness feedback, audio use, KR/EN copy, and
      guidebook metadata.
- [ ] Add the bulkhead one-shot and boss-recovery stagger contracts.
- [ ] Preserve the Breach contract under every existing primary-projectile,
      charge-time, pierce, and status upgrade combination.
- [ ] Add terrain discovery events without per-frame deep guidebook snapshots.

**Acceptance:**

- terrain footprints match simulation exactly;
- currents never alter projectiles or push actors through walls;
- each surge hits an actor no more than once per active window;
- surge damage can kill enemies with deterministic ownership;
- one full Breach Shot breaks a full-health bulkhead;
- Forked Muzzle and other existing upgrades cannot remove the center
  projectile's Breach interaction;
- normal primary fire can eventually break a bulkhead;
- one Breach Shot in boss recovery causes one stagger and cannot loop the boss;
- broken bulkheads remain broken through later successful stages and reset on a
  stage restart/replay; and
- no terrain creates a required path narrower than `320 px`.

### Milestone 3 — Mines and additional enemy roles

- [ ] Convert stationary mines to one-shot fuse state machines.
- [ ] Apply mine damage to player and enemies with wall occlusion.
- [ ] Implement player-caused short fuse, deterministic bounded chain arming,
      quota, XP, and damage-source attribution.
- [ ] Activate Spark Minelets from stage 2 within their locked caps.
- [ ] Implement Bulkhead Guard plate ownership and Breach counterplay.
- [ ] Implement Relay Scavenger bounded XP query, storage, return, and drop.
- [ ] Implement Splitter Barge children inside summon capacity.
- [ ] Update authored encounter packets to the locked teach-combine-test rollout
      without changing active/population envelopes.
- [ ] Preserve the `<=50%` ordinary projectile-role share.

**Acceptance:**

- mines retire after one explosion;
- approaching or destroying a mine produces the correct fuse;
- enemy proximity alone does not arm a mine;
- explosions cannot hit through a wall;
- at most six chain mines arm per source explosion;
- quota/XP attribution is correct for approach-triggered and shot-triggered
  explosions;
- no XP is lost when a Relay Scavenger dies or a stage ends;
- splitter children never increase quota/XP and never exceed cap;
- every new role uses local/bounded queries; and
- the active cap remains `72`.

### Milestone 4 — Boss runtime and five distinct exams

- [ ] Extract the boss state machine and attack execution from
      `vehicle_run.gd` into `VehicleBossRuntime`.
- [ ] Replace the two-phase reorder with the locked three-phase sequence model.
- [ ] Implement each named pattern and exact telegraph footprint in the boss
      table above.
- [ ] Ensure pursuit/repositioning continues after normal hits and outside
      committed attacks.
- [ ] Implement one-stagger-per-attack Breach recovery interaction.
- [ ] Add five unique boss meshes/variants and reuse them in combat, minimap,
      HUD, and guidebook.
- [ ] Keep projectile reserve at or below `24` and add bounded summon handling.
- [ ] Add deterministic pattern fixtures for each phase and combo.

**Acceptance:**

- every boss reaches and executes every phase deterministically;
- normal hits never freeze boss movement or attack timers;
- no immediate pattern repeats;
- all warnings stop tracking after lock;
- warning and damage geometry are identical;
- every pattern and phase-three combo is escapable at base speed with `40 px`
  margin;
- damage remains inside the locked light/standard/heavy bands;
- each boss creates a different spatial decision, not only a different color;
- all five variants are visually distinguishable in monochrome silhouette; and
- boss capacity does not exceed the current projectile/summon envelope.

### Milestone 5 — Guidebook previews and damage recap

- [ ] Extend guidebook snapshots with nonleaking preview and counterplay
      metadata.
- [ ] Add `VehicleGuidebookPreview` using shared mesh geometry.
- [ ] Add unique boss, enemy, mine, and terrain object previews.
- [ ] Add Movement, Attack, and Counter rows in Korean and English.
- [ ] Preserve neutral locked silhouettes and `???` without hidden metadata.
- [ ] Add discovery triggers for terrain and new roles.
- [ ] Add attempt-scoped damage-source accumulation and the failure recap.
- [ ] Verify modal pause/input blocking and deterministic focus.

**Acceptance:**

- every discovered enemy/boss entry visually matches its combat silhouette;
- locked entries leak no identity;
- every text key exists and fits in Korean and English;
- preview controls clip neither mesh nor focus indicator;
- reduced motion produces a static but complete preview;
- the failure recap shows the correct last hit and no more than three aggregate
  sources; and
- no new persistent live-HUD text is introduced.

### Milestone 6 — Integration, performance, rendered QA, and cleanup

- [ ] Run every focused validator listed below.
- [ ] Run the complete current vehicle validation suite.
- [ ] Export the production Web build.
- [ ] Run deterministic capacity scenarios for all three fields, all five
      bosses, each terrain family, mine chains, and all three new roles.
- [ ] Complete three foreground standalone/Web repetitions at the required
      resolutions and the active performance plan's ten-minute lifecycle soak.
- [ ] Capture UI/UX evidence at `960x540`, `1280x720`, and `1920x1080` in Korean
      and English.
- [ ] Review field walls, all terrain states, every boss phase, Breach readiness,
      mine fuses, guidebook locked/unlocked entries, focus, and failure recap.
- [ ] Remove superseded branches, dead motif code, unused generic boss
      execution, stale localization, and temporary instrumentation.
- [ ] Run `$codebase-quality-auditor` and apply only safe task-scoped findings.
- [ ] Update evidence, canonical docs, and this plan's progress truthfully.

**Exit condition:** all functional, visual, localization, lifecycle, and
performance gates pass. If any declared gate fails, this plan remains active.

## Validation and Test Plan

### Focused validators

Run with the repository Godot wrapper:

```powershell
./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_stage_layouts.gd
./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_field_layout_generation.gd
./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_navigation_clearance.gd
./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_primary_weapon.gd
./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_attack_contract.gd
./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_boss_patterns.gd
./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_encounter_pacing.gd
./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_spawn_allocation.gd
./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_guidebook.gd
./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_combat_renderer.gd
./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_performance_scenarios.gd
./tools/godot.ps1 --headless --path . --script tools/validation/validate_vehicle_run.gd
```

Add responsibility-shaped validators rather than expanding one catch-all:

- `validate_vehicle_terrain_runtime.gd`
- `validate_vehicle_wall_contract.gd`
- `validate_vehicle_mines.gd`
- `validate_vehicle_enemy_expansion.gd`
- `validate_vehicle_boss_runtime.gd`
- `validate_vehicle_damage_recap.gd`

### Deterministic fixtures

Every test has a fixed seed and no wall-clock dependency:

- each field with fallback and six representative cover masks;
- every terrain state boundary at `warning - epsilon`, `warning`, `active -
  epsilon`, `active`, and cycle reset;
- Flow entry/exit for player, ordinary enemy, boss, stationary enemy, and
  projectile;
- bulkhead normal-fire and Breach destruction;
- mine approach, health-zero, chain, wall occlusion, and attribution;
- each new enemy at capacity and stage transition;
- every boss pattern in every phase and the five phase-three combos;
- guidebook locked/unlocked snapshot equivalence; and
- last-hit/top-three aggregation ties resolved by damage descending, then stable
  source ID.

### Production build

```powershell
./tools/export_web.ps1
```

Use the built Web export for final navigation and rendered QA. A dev/editor run
is iterative evidence only.

### Performance gates

Use the exact active performance-plan thresholds:

| Gate | Required result |
| --- | --- |
| capacity subsystem simulation | `p95 <= 6.0 ms`, `p99 <= 8.0 ms` |
| standalone `1280x720` | median `>=59 FPS`, 1% low `>=55 FPS`, frame `p95 <=18 ms`, `p99 <=25 ms`, no two consecutive frames over `33.3 ms` |
| standalone `2560x1600` | median `>=58 FPS`, 1% low `>=50 FPS`, frame `p95 <=20 ms`, `p99 <=33.3 ms` |
| Web `1280x720` | median `>=58 FPS`, 1% low `>=50 FPS`, frame `p95 <=20 ms`, `p99 <=33.3 ms`, no three consecutive frames over `33.3 ms` |
| total draw calls | `p95 <=200` at capacity |
| lifecycle | no retired live enemies, stale IDs, or cap overflow |
| ten-minute soak | static-memory growth `<8 MiB` after warmup |

Adding content may not lower an accepted simulation cadence, disable visual
feedback, reduce the existing envelope, or reinterpret the threshold.

## UI/UX Gate and Rendered Evidence

This is a Level 4 interface/system revision because wall semantics, terrain,
combat telegraphs, guidebook structure, and result feedback change together.
Final rendered evidence must include:

| Surface | Required states |
| --- | --- |
| deployment | separate seeded captures for each of the three read-only selected field names; KR/EN; keyboard focus |
| gameplay field | all three layouts; shared walls; zero motifs; every terrain warning/active state |
| Breach Shot | unprimed, charging, ready, fired, bulkhead hit, mine hit, boss recovery hit |
| mine | dormant, normal fuse, short fuse, chained fuse, explosion with enemy inside |
| bosses | each silhouette; every phase; phase-three combo; boss HUD/minimap identity |
| guidebook | locked/unlocked enemy, boss, mine, and terrain; KR/EN; focus; reduced motion |
| failure | last hit and one/two/three-source recap in KR/EN |

Capture at `960x540`, `1280x720`, and `1920x1080`. Check alignment,
typography, spacing, focus, overflow, clipping, central combat occlusion,
color-independent shape differentiation, and static reduced-motion states.
No screenshot with debug-only labels may be used as final evidence.

## Predetermined Contingencies

- If a field cannot meet two-route connectivity after thirty-two generated
  cover attempts, use that field's authored fallback cover IDs. If the fallback
  fails, reject the field at load; never silently narrow actor radius.
- If merged boundary loops self-intersect, fail validation and fix the authored
  regions. Do not draw an approximate wall unrelated to collision.
- If a Breakable Bulkhead would disconnect a required route, reject its authored
  socket. Do not auto-open it at runtime.
- If mine-chain demand exceeds six targets, arm the six nearest by distance then
  stable ID; leave the rest dormant.
- If a splitter cannot allocate both children, spawn only the available count;
  do not queue delayed hidden spawns.
- If a boss combo cannot prove base-speed escape, increase warning or gap
  geometry before reducing damage. Dash never becomes mandatory.
- If a guidebook mesh is too large for its preview, scale the shared mesh
  uniformly inside a `16 px` inset; do not crop or author a separate portrait.
- If a new repeated visual cannot use MultiMesh ordering correctly, use a fixed
  retained `MeshInstance2D` pool. Do not return to per-frame procedural
  high-count drawing.
- If any performance gate fails, first profile and reduce query cadence or
  presentation invalidation within the locked behavior. Do not raise caps,
  remove effects, lower physics FPS, or claim success from a headless
  microbenchmark.

## Safety and Rollback

- Work in coherent commits by milestone; do not mix unrelated user changes.
- Field registry changes precede content so every later commit has one field
  selection contract.
- Keep the current field definition usable until all three layouts pass. A
  failed new field can be removed from the registry without reverting wall,
  terrain, or combat fixes.
- Add the new boss runtime behind the same public snapshot contract, then delete
  the old generic branches only after parity validators pass.
- Persisted guidebook IDs are append-only. Never rename an existing discovered
  entry without a migration.
- Layout-seed behavior changes version from existing cover sub-seeds only through
  the new `field:v1` selection. Existing explicit `--layout-seed` remains
  deterministic.

## Risks

| Risk | Control |
| --- | --- |
| Three fields multiply cache and validation bugs | Key every immutable cache by `field_id`; run every fixture across all fields |
| A common wall rail visually shrinks corridors | Lock `320 px` minimum corridor and align the `24 px` floor-side edge with player-center collision |
| Friendly-fire mines solve encounters automatically | Enemy proximity cannot arm them; player approach or damage creates the event |
| Breach Shot becomes mandatory DPS | Its health multiplier stays modest; exclusive strength is structure and recovery stagger |
| Boss layering becomes unreadable | One low-reaction layer plus one direct response; exact warnings and base-speed escape proof |
| New roles reintroduce lag | Bounded live caps, local queries, existing active cap, MultiMesh presentation |
| Guidebook leaks unseen content | Neutral locked preview and snapshots that omit hidden metadata |
| Run-level field variation is mistaken for stage map switching | Field name shown on deployment and field ID immutable through stage flow |

## Progress

- [x] Recovered the previous current and storm terrain behavior from git history.
- [x] Audited the current field, motif, wall, opening-shot, mine, enemy,
      boss-pattern, guidebook, and performance contracts.
- [x] Reviewed current primary external design and engine references.
- [x] Locked one implementation direction with no deferred design choice.
- [ ] Milestone 0 implementation baseline and canonical-spec update.
- [ ] Milestone 1 field registry and wall truth.
- [ ] Milestone 2 terrain and Breach Shot.
- [ ] Milestone 3 mines and enemy expansion.
- [ ] Milestone 4 boss runtime and exams.
- [ ] Milestone 5 guidebook and damage recap.
- [ ] Milestone 6 integration and release evidence.

## Decision Notes

- 2026-07-24: Preserve one field through a run, but select that field from three
  authored layouts at new-run creation.
- 2026-07-24: Delete all motifs rather than recolor or hide them.
- 2026-07-24: Treat every impassable static edge as one wall material and derive
  it from compiled collision geometry.
- 2026-07-24: Rebuild, rather than restore, the old current and storm mechanics
  so terrain affects both sides and never changes projectile flight.
- 2026-07-24: Give the one-second shot structure, mine, protected-enemy, and
  boss-recovery jobs; keep held fire.
- 2026-07-24: Increase enemy and boss decision variety without increasing the
  existing active-cap envelope.
- 2026-07-24: Reuse combat meshes for guidebook visuals instead of creating
  separate image assets.
- 2026-07-24: Include a compact damage recap now; defer practice mode, optional
  danger events, and elite modifiers to later plans.

## Next Steps

Begin Milestone 0 only when implementation is explicitly requested. Do not
alter game code from this planning document alone.
