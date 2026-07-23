---
type: plan
status: active
owner: BK
created: 2026-07-23
scope: Enlarged single-field five-stage combat loop, roaming bosses, secondary weapons, simple movement upgrade, and encounter-driven guidebook
related:
  - ../PLANS.md
  - ../vehicle-performance-architecture-audit.md
  - ./2026-07-23-vehicle-performance-architecture-stabilization.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
---

# Single-Field Campaign, Secondary Arsenal, and Guidebook — Execution Plan

This plan replaces the current five-map progression with one persistent,
`5600×3400` Drowned Ruins field, five escalating combat stages, quota-triggered
roaming bosses, five bounded passive secondary weapon families, one simple
base-speed upgrade, and a persistent encounter-driven guidebook. The work is
divided into six executable phases and is complete only when all five stages run
consecutively on the same enlarged field and the native, Web, performance,
localization, save, and rendered UI gates pass.

## Purpose

- **Objective:** make the current vehicle shooter a legible, repeatable combat
  run in which enemies come to the player, each stage culminates in a roaming
  boss, build choices materially change passive offense, and discovered game
  knowledge is available from the pause/settings flow.
- **Final artifact:** one five-stage Godot campaign using one shared `5600×3400`
  field, five secondary weapon families, a simplified movement card, and a
  localized guidebook with persistent discovery.
- **Completion state:** stages 1–4 advance automatically after their boss reward;
  stage 5 opens the final result; all obsolete map-gate, arena-lock, temporary
  movement-cycle, and inter-stage result code is retired.

## Why / Context

The current runtime has five different geometry definitions and binds stage
progress to installations, relay caches, fixed boss gates, fixed boss arenas, and
map-specific mechanics. `VehicleRun._advance_stage()` reloads the next geometry,
while `_start_stage_boss()` and the boss update path assume an authored arena.
This conflicts with the accepted direction: the field must remain constant,
ordinary enemies must arrive over time and pursue the player, and the boss must
enter the same open field after enough non-boss enemies have been defeated.

The current passive secondary is one Seeker Launcher with several seeker-only
modifiers. It has upgrade depth but not weapon-type breadth. The current movement
catalog also includes a permanent speed card and a periodic Thruster Cycle, while
the requested movement upgrade is only a direct increase to base movement speed.

The pause/settings UI has no in-game reference surface. Enemy definitions,
stationary threats, bosses, pickups, and derived player stats already have clear
runtime owners, but no player-facing catalog combines them and no persistent
discovery state records what the player has actually encountered.

## Pre-plan Evidence Already Verified

| Source or path | Verified fact | Decision affected | Freshness / recheck boundary |
| --- | --- | --- | --- |
| `AGENTS.md`, `.agents/AGENTS.md`, `.agents/PLANS.md` | Cross-system gameplay, persistence, UI, and schema work requires an active ExecPlan; completed plans are deleted after accepted behavior is incorporated into the active specs. | Plan placement, lifecycle, ownership, and final cleanup. | Re-read if repository instructions change. |
| `docs/product/vehicle_game_spec.md` | At plan creation, the shipped contract defined five authored maps, installation-owned gates, passive seekers, 43 cards, two field pickup types, five bosses, and an 8 ms fixed-step performance gate. The document now reflects the implemented campaign and reopens release performance under the active stabilization plan. | Historical behaviors to preserve, replace, or retire explicitly; current performance authority. | Re-read before Phase 6 spec reconciliation. |
| `docs/design/UI_VISUAL_SYSTEM.md` | The accepted visual language is flat-color Sunken Ceramic Fresco with large shapes, Noto Sans KR, Korean default, 44 px commands, and modal/focus requirements at 960×540, 1280×720, and 1920×1080. | Guidebook layout and secondary-weapon feedback must reuse the current system. | Recheck after any shared theme change. |
| `scripts/vehicle/vehicle_stage_catalog.gd`, `scripts/vehicle/stages/*.gd` | Five stage IDs currently select five separate geometry, hazard, landmark, packet, pickup, and boss-arena definitions. | Split one field definition from five combat-stage profiles and retire duplicate geometry owners. | Recheck immediately before deleting migrated stage files. |
| `scripts/vehicle/vehicle_run.gd` | `_advance_stage()` reloads a map and opens gameplay manually from a result; `_update_stage_progression()` uses generators/cache/zone gates; bosses are arena-locked; `_update_passive_secondary()` only creates seeker shots; `_player_move_speed()` reads permanent and periodic movement modifiers. | Stage-flow, boss, passive-runtime, and movement changes. | Recheck after each phase that touches the orchestrator. |
| `scripts/vehicle/stages/flooded_works.gd`, `scripts/vehicle/vehicle_run.gd`, `project.godot`, `tools/validation/validate_vehicle_stage_layouts.gd` | The reusable source field is `4400×2800`, centered at `(2200,1400)`, with nine cover rectangles; gameplay uses a `1280×720` viewport, camera zoom `1.0`, and a `13×6` minimap grid. The layout validator hard-codes the old dimensions and center. | Enlarge the field without scaling combat, update camera/minimap bounds, and replace stale layout assertions. | Verify the exact replacement geometry and metrics in Phase 1. |
| `scripts/encounters/vehicle_encounter_runtime.gd` | Packets already spawn units sequentially from authored anchors, but event-only activation and per-packet leash rectangles prevent a global timed pursuit loop. | Keep deterministic packets and caps; replace activation/leash semantics. | Recheck after Phase 2. |
| `scripts/enemies/vehicle_enemy_archetypes.gd`, `scripts/bosses/vehicle_boss_patterns.gd` | Nineteen roles and five stage-boss pattern sets exist; stationary roles are already distinguishable from mobile roles, but some boss patterns assume map-specific lanes, gates, or reflectors. | Reuse enemy identities and five bosses while making boss patterns field-portable. | Recheck before Phase 3 boss migration. |
| `scripts/cards/vehicle_upgrade_catalog.gd`, `data/cards/vehicle/*.tres` | The runtime expects 43 card resources. `tuned_thrusters` and `thruster_cycle` both affect movement; seeker modifiers do not create other secondary weapon families. | Retire the movement cycle, add four secondary unlock/level cards, and update validation counts. | Recheck after card additions/removals. |
| `scripts/ui/vehicle_stage_ui.gd`, `scripts/ui/vehicle_settings_panel.gd` | Pause, settings, upgrade, result, and garage are runtime-built modal layers. Settings has four tabs and no help/guide entry. | Add one reusable `?` entry and a separate guidebook modal without duplicating settings. | Recheck after Phase 5 responsive changes. |
| `scripts/autoload/settings_store.gd` | Settings persistence owns audio, locale, bindings, combat preset, and reduced motion only. | Guide discovery must not be added to the settings store. | Stable unless persistence ownership changes. |
| [Nova Drift official site](https://www.novadrift.io/) (accessed 2026-07-23) | A vehicle action RPG supports seeking payloads, drone armies, nearby damage, shield discharge, and modular interaction rather than only projectile-count upgrades. | Keep manual primary aim while giving passive weapons distinct spatial jobs. | Revisit only if the product direction changes. |
| [Nova Drift official patch notes](https://blog.novadrift.io/patch-notes/) (accessed 2026-07-23) | Drones, mines, turrets, and seeking attacks are established build families; construct/projectile counts require explicit caps and performance care. | Select drones and mines, and bound every passive entity count. | Revisit only if performance architecture changes. |
| [SPACEFIGHTER developer Steam page](https://store.steampowered.com/app/4451950/) (accessed 2026-07-23) | A current top-down vehicle survivor uses homing rockets, Tesla/kill auras, floating mines, minions, orbital drones, manual targeting, bosses, and a discovery bestiary. | Confirms the five selected secondary archetypes and encounter-driven guidebook are familiar for the subgenre. No names, assets, or exact balance values are copied. | Revisit only if secondary scope changes. |

## Execution Readiness

- Discovery, current-state inspection, option comparison, and product decisions
  are complete before Phase 1. Phases 1–6 contain implementation and post-change
  verification only; none contains a search, research, comparison, selection, or
  deferred design task.
- This plan authorizes exactly one implementation solution: the locked contracts
  in this document. Rejected Alternatives records why prior options are closed;
  it is not a menu for the implementer.
- A freshness check means verifying that a named current owner has not changed
  before editing or deleting it. It does not reopen product discovery. If the
  checked source contradicts a locked contract materially, stop under change
  control instead of adding an exploratory task to this plan.

## Assumptions — Locked Interpretations

- “Five secondary weapon types” means **five total families including the
  existing Seeker Launcher**, not five additions on top of it.
- “The same map” means the current Flooded Works geometry and accepted visual
  theme become one persistent `drowned_ruin_field`; stage identity comes from
  enemies and bosses, not geometry or recoloring. The field is enlarged to the
  exact dimensions and geometry contract in Locked Decision 1.
- The campaign remains five stages because five boss identities and reward steps
  already exist. A change to campaign length is owner-level scope change.
- “Non-boss enemies” means non-summoned mobile enemies and stationary threats.
  Carrier children, boss pylons, and any other summoned actor grant neither boss
  quota progress nor experience.
- No material product or technical decisions remain open. Changes to the five
  weapon families, simultaneous passive limit, kill quotas, persistence rules,
  or inter-stage flow require explicit owner approval.

## Locked Decisions

### 1. One enlarged persistent field and five combat stages

- The shared field is named `drowned_ruin_field`. Its exact world rectangle is
  `Rect2(0, 0, 5600, 3400)`, its exact center respawn is
  `Vector2(2800, 1700)`, and the center has a `480 px` clear radius with no
  cover, stationary threat, item, crate, ordinary spawn, or boss arrival anchor.
- Do not uniformly scale the current map, actor sprites, movement, weapon range,
  camera, cover, or combat spacing. Translate the ten accepted Flooded Works
  walkable regions and its nine cover rectangles by exactly
  `Vector2(600, 300)`, then union the translated floor with these six new broad
  walkable rectangles:

  | Region ID | Exact rectangle | Function |
  | --- | --- | --- |
  | `northwest_court` | `Rect2(240, 300, 1400, 900)` | broad northwest combat court |
  | `southwest_court` | `Rect2(240, 2200, 1400, 900)` | broad southwest combat court |
  | `northeast_court` | `Rect2(3960, 300, 1400, 900)` | broad northeast combat court |
  | `southeast_court` | `Rect2(3960, 2200, 1400, 900)` | broad southeast combat court |
  | `north_outer_lane` | `Rect2(1380, 500, 2840, 520)` | upper cross-field route joining both north courts |
  | `south_outer_lane` | `Rect2(1380, 2380, 2840, 520)` | lower cross-field route joining both south courts |

- Translate all nine cover rectangles, then widen the translated lower-west
  rectangle from `Rect2(1250,2180,300,170)` to exactly
  `Rect2(1190,2180,360,170)` so the `122 px` stage-boss radius cannot enter a
  one-cell pocket that it cannot leave. Add exactly four sparse outer-court
  cover rectangles: `Rect2(640,690,280,180)`,
  `Rect2(640,2530,280,180)`, `Rect2(4680,690,280,180)`, and
  `Rect2(4680,2530,280,180)`. The final field therefore has exactly thirteen
  cover rectangles.
- Do not translate the five old water rectangles because they would overlap the
  new courts and falsely present walkable floor as water. Replace them with four
  non-walkable border-water rectangles: `Rect2(80,60,2400,180)`,
  `Rect2(3120,60,2400,180)`, `Rect2(80,3160,2400,180)`, and
  `Rect2(3120,3160,2400,180)`. All other space outside the walkable union remains
  cobalt void.
- Reuse the four accepted large motif kinds, radii, rotations, and semantic
  colors, but place them at exact valid centers rather than translating centers
  that would collide with cover or land in void: Tide Curl `(1120,560)`, radius
  `210`, rotation `-0.28`; Split Current `(1250,2850)`, radius `245`, rotation
  `0`; Relay Flower `(4440,900)`, radius `135`, rotation `PI/4`; Sun Gate
  `(4360,2520)`, radius `235`, rotation `0`. Add no smaller repeated floor motif.
- The enlarged field is `54.5%` larger by area than Flooded Works. At the
  unchanged `1280×720` gameplay viewport and camera zoom `1.0`, it spans exactly
  `4.375` view widths by `4.722` view heights (`20.66` viewport areas), so the
  whole field cannot appear on one gameplay screen. At base speed `280`, the
  straight center-to-edge times are `10.00 s` horizontally and `6.07 s`
  vertically; center-to-corner is `11.70 s`. No validated center-to-arrival-anchor
  navigation route may exceed `3640 px` (`13.0 s` at base speed).
- Preserve the current movement-readability geometry contracts: passable
  openings are at least `168 px`, primary travel/combat lanes are at least
  `320 px`, and turning pockets are at least `240×240 px`. Every outer court has
  two walkable routes back to the central network; no new dead-end combat pocket
  or visually open but colliding slit is allowed.
- Replace the `13×6` minimap with an exact `16×10` grid. Each cell represents
  `350×340` world pixels; entering a cell keeps the current one-cell-neighbor
  reveal (`3×3`, clipped at edges). Explored cells still persist across stages.
- Use exactly sixteen ordinary-enemy spawn anchors and eight boss arrival
  anchors. They are immutable field data and use these exact positions:

  ```text
  ordinary: (480,520), (880,480), (1280,560), (4320,520),
            (4800,480), (5200,640), (480,2860), (880,2920),
            (1280,2820), (4320,2860), (4800,2920), (5200,2760),
            (1900,700), (3600,700), (1900,2700), (3600,2700)
  boss:     (520,960), (1280,440), (4320,440), (5080,960),
            (520,2440), (1280,2960), (4320,2960), (5080,2440)
  ```

- Reuse the four non-progression stationary-threat positions and all current
  field pickup/crate positions after the same `(600,300)` translation. Their
  exact field anchors are:

  ```text
  stationary: (3650,1250), (3650,2110), (3320,890), (3320,2510)
  pickups:    repair (2300,1700), recall (3640,870), repair (4280,2350)
  crates:     (1330,2000), (2210,1810), (3860,1710), (2020,1460),
              (4300,990)
  ```

- A pre-implementation `96 px` sampled-grid sanity check of these exact
  rectangles reaches all `999/999` ordinary-radius (`36 px`) cells and all
  `651/651` stage-boss-radius (`122 px`) cells. Every listed anchor is valid;
  the longest sampled center-to-anchor paths are `3174.2 px` for ordinary
  enemies and `3475.9 px` for bosses. Phase 1 must reproduce this with the
  engine geometry validator; this arithmetic check is evidence, not a substitute
  for acceptance.

- Fixed boss gates, boss chambers, generator progression gates, relay-cache
  progression, optional field-boss branches, electrical-current lane hazards,
  sweep islands, switch gates, and reflectors do not survive as stage-flow
  contracts.
- The field exposes:
  - the exact center, sixteen ordinary spawn anchors, and eight boss anchors
    listed above;
  - the exact four stationary-threat, three pickup, and five crate anchors listed
    above, with pickups and crates restocked at each stage reset.
- Walkable space, solid cover, line of sight, minimap blockers, backdrop drawing,
  spawn validation, and pursuit navigation continue to consume one geometry
  source.
- Explored minimap cells persist across the five stages of a run because the
  physical field does not change. Dynamic enemy, boss, item, and objective
  markers reset per stage. A new run resets exploration.

### 2. Stage pressure, quota, and boss identity

| Stage | Non-boss defeat quota | Mobile roles introduced or emphasized | Stationary threats | Roaming boss |
| ---: | ---: | --- | --- | --- |
| 1 | 96 | Scrap Drone, Needle Drone, Rivet Chaser, Lane Skirmisher | Foundry Turret, Arc Mine | Foundry Colossus |
| 2 | 128 | Flood Controller, Shield Escort | Interceptor Tower, Barrier Generator | Archive Leviathan |
| 3 | 160 | Artillery Spotter, Rammer | Beam Sentinel plus earlier threats | Drydock Titan |
| 4 | 192 | Repair Tender, Drone Carrier | Mixed support and denial anchors | Switchyard Behemoth |
| 5 | 224 | All discovered mobile roles in mixed squads | Mixed stationary threats | Crown Engine |

- Every stage starts at the field center with the current six-second safe arrival.
- Time-authored packets spawn from distributed anchors. After the opening scout,
  each cue schedules eight squads of three to five units. The first surge
  schedules at least 24 enemies, later surges grow toward 40, and surge cues are
  spaced 2.4 seconds apart. All packets use time triggers; route-entry events no
  longer gate the availability of combat.
- Each stage profile authors at least `quota + active_cap` countable enemies so a
  boss cannot become impossible because the finite schedule ran dry.
- Standard reaches 48 active enemies on the first combat beat. Both Standard and
  Onslaught hard-cap active simulation at 72 enemies while retaining the existing
  attack-family budgets. Excess authored population stays queued, so stage
  profiles change density without breaking the frame budget.
- Once the quota is reached, the scheduler stops issuing new ordinary enemies.
  Already living non-boss enemies remain active during the boss warning and boss
  fight, but no reinforcements are added.
- Boss creation and boss-defeat completion both require `BOSS_ACTIVE` with the
  full quota recorded. Elapsed time, debug calls, and a stray boss actor cannot
  bypass the ordinary-combat phase.
- The objective chip displays `Threats defeated: current / quota` until the
  quota is met, then switches to the boss arrival warning and boss state.

### 3. Global pursuit and stationary-role boundary

- Spawn anchors determine where an enemy enters, not where it is allowed to
  remain.
- Mobile ordinary roles and stage bosses use a shared player-centered pursuit
  field. A 96 px navigation grid is rebuilt at most 5 Hz when the player changes
  cell or dynamic walkability changes. Actors sample the shared field and retain
  their role-specific attack distance and recovery behavior near the player.
- Per-enemy full path searches are forbidden. If a grid route is temporarily
  unavailable, the actor uses local slide recovery and requests a field rebuild;
  it never returns to its spawn anchor or becomes dormant solely because the
  player is distant.
- Turrets, stationary mines, interceptor towers, beam sentinels, barrier
  generators, and boss pylons never pursue. Their combat logic stays anchored.
- A mobile actor that makes no route progress for two seconds chooses the next
  lower-cost neighboring pursuit cell. After another two seconds it is moved to
  the nearest validated walkable cell on that route; it is never teleported near
  the player.

### 4. Roaming boss arrival

- Reaching the stage quota starts a 1.5-second boss arrival warning without a
  zone-entry, chest, generator, or ordinary-enemy-clear requirement.
- The boss anchor is chosen from the eight validated anchors by maximum path
  distance from the player, with the stage/run seed breaking ties. The chosen
  point must be walkable, reachable, and at least 1200 px from the player. If no
  point satisfies 1200 px, the farthest valid point is used.
- The warning appears in the world, on the minimap, and in the off-screen threat
  arc. The boss is registered in the guidebook when this named arrival starts.
- The boss globally pursues the player and is never clamped to a boss arena.
- Boss startup aim tracks the moving player while the boss approaches, retreats,
  or strafes. Projectile patterns lock one predictively aimed lane and repeat
  volleys along it; charge, area, pylon, and summon patterns add one aimed
  three-shot pressure burst. Startup remains the visible warning and active
  attacks retain bounded recovery.
- Every attack still has startup, active, and recovery windows. Map-specific
  names may remain, but their effects become local to the boss/player and solid
  cover:
  - lane attacks are projected relative to the boss and current target;
  - charge attacks collide with any shared-field solid cover;
  - pylon and summon positions are projected to validated walkable cells near
    the boss;
  - reflector-, switch-, and fixed-gate dependencies are removed;
  - all hostile projectiles and beams obey shared solid-cover rules unless a
    named, visibly telegraphed boss pattern explicitly says otherwise.

### 5. Boss reward and automatic next-stage transition

1. Boss defeat stops new damage and ordinary spawning, cancels hostile startup
   and active attacks, clears hostile projectiles, and removes surviving enemies
   without defeat rewards.
2. All uncollected experience shards enter the existing 0.65-second recall flow.
3. Pending level-up choices resolve in order, followed by the mandatory stage
   boss card choice. Every choice retains the current select-then-confirm guard.
4. After the last mandatory reward is confirmed, stages 1–4 enter a 0.35-second
   fade, clear transient combat actors/effects, restore hull to the current
   maximum, preserve run level, experience remainder, acquired upgrades, guide
   discovery, and explored minimap cells, then place the ship at the exact field
   center.
5. The next stage banner appears while the next six-second safe arrival begins.
   There is no intermediate result screen and no “Next Stage” button.
6. Stage 5 opens the final result/garage flow after its rewards. Replay starts a
   fresh run and resets the run build and map exploration without resetting
   settings or guide discovery.

### 6. Simple movement upgrade

- `Tuned Thrusters` is the only card whose purpose is ordinary movement speed.
- Its three levels set the base movement multiplier to exactly `1.08`, `1.16`,
  and `1.24`. With the current 280 base speed, the displayed effective values are
  302.4, 324.8, and 347.2 px/s.
- `Thruster Cycle` and stale temporary movement-speed pickup/card copy are removed
  from data, runtime cycle state, localization, status-orbit presentation, and
  validators. Dash upgrades remain because they change the explicit dash action,
  not ordinary movement speed.
- If the player does not own `Tuned Thrusters`, the second level-up offer of a
  run contains it as one of the three choices. It is offered, not auto-applied.
- The card and guidebook state page show `Base movement speed` and `Current
  movement speed`; no periodic movement timer or conditional speed prose remains.

### 7. Five passive secondary weapon families

The Seeker Launcher remains equipped at run start. A run can operate at most
three secondary families simultaneously: the Seeker plus any two of the other
four. The first level of a new family consumes a slot; once both additional slots
are occupied, unowned family cards are excluded while owned family upgrades
remain eligible. All five are automatic and require no new input binding.

| Family | Tactical job | Level contract | Hard runtime bound |
| --- | --- | --- | --- |
| **Seeker Launcher** | Long-range priority-target pressure using the current homing shot. | Base 25 damage, 1.35 s interval, 560 range; existing count, cadence, pierce, priority, mark, and warhead cards continue to modify it. | Existing player-projectile cap; no separate construct. |
| **Ion Field** | Continuous close-range swarm attrition around the ship. | Radius 120/140/160; 8/12/16 DPS; fixed 0.25 s damage tick. | One procedural field; no projectile or particle entities. |
| **Orbit Blades** | Burst contact damage that rewards close weaving without duplicating the field’s continuous damage. | 2/3/4 blades at 78 radius; 14/18/22 damage; 0.55 s per-target hit cooldown. | Four procedural blade positions and one target cooldown map. |
| **Wake Mine Layer** | Kiting and route denial by dropping explosives behind movement. | Interval 3.2/2.8/2.4 s; cap 3/4/5; damage 48/60/72; blast radius 96/108/120; eight-second lifetime. | Five mines; spawning at cap retires the oldest mine. |
| **Escort Drone** | Sustained mid-range fire from a displaced origin while the player manually aims elsewhere. | One drone; 480 range; 12/16/20 hitscan damage at 0.85/0.72/0.60 s intervals. | One drone and one short-lived beam effect; no drone projectile entities. |

- Solid cover blocks Seeker and Escort targeting and blocks Ion Field, Orbit
  Blade, and Wake Mine damage to a target when the relevant damage origin has no
  line of sight. Passive weapons never damage crates or progression objects.
- Player-owned secondary damage uses the normal damage attribution path, so
  status, mark, and Siphon Matrix rules are deterministic and overkill is not
  counted twice.
- Each new family uses one max-level-3 card resource. The card catalog therefore
  moves from 43 to exactly 46 definitions after `thruster_cycle` is removed and
  four new family cards are added. Seeker-family metadata lives in the secondary
  definition rather than adding another card. The validator and README both
  assert the same count of 46.
- Secondary weapon definitions own localized name/description keys, level values,
  slot cost, behavior kind, and visual role. The UI receives snapshots and does
  not hard-code weapon behavior.
- The action dock retains one passive readiness slot for the Seeker because it has
  a discrete cooldown. Ion Field, Orbit Blades, mines, and the drone communicate
  state in the world. The garage and guidebook list every equipped family and
  level; no additional opaque combat panel is added.

### 8. Encounter-driven guidebook

The guidebook is a persistent reference, not a second settings page and not a
source of gameplay authority. It has five categories:

| Category | Visible information | Locked behavior |
| --- | --- | --- |
| **Current Ship** | Hull, run level/XP, base/current movement speed, primary damage/cadence/count/speed/range/opening values, dash cooldown, EMP cooldown/radius, equipped secondaries and levels, and acquired card levels. | Never locked; values come from the live runtime snapshot. |
| **Mobile Enemies** | Name, silhouette, movement/attack behavior, target-priority reason, and counterplay. No raw stats. | One stable slot per known catalog role; title is `???`, neutral silhouette only, and no hidden description leaks. |
| **Stationary Threats** | Turret, Arc Mine, Interceptor Tower, Beam Sentinel, Barrier Generator, and Boss Pylon roles and attacks. No raw stats. | Same `???` contract. |
| **Bosses** | Five stage-boss names, silhouette, major attacks, and expected response. No raw stats or undiscovered phase names. | Same `???` contract. |
| **Field Objects** | Experience Shard, Repair pickup, Experience Recall pickup, and breakable Supply Crate purpose. | Unlock on first collection or first crate break; otherwise `???`. |

Discovery rules are exact:

- a mobile or stationary enemy unlocks when it first enters the current camera
  world rectangle or first attacks/takes player damage, whichever happens first;
- a stage boss unlocks when its named arrival warning begins;
- an item unlocks when collected, and a crate unlocks when first broken;
- an offered but unselected upgrade is not considered acquired and appears only
  in the temporary upgrade modal, not the Current Ship page;
- discoveries persist across runs in a dedicated versioned guidebook save owned
  outside `SettingsStore`;
- existing saves start with no inferred historical discoveries because the old
  save contains no reliable per-entry encounter evidence. Current ship equipment
  remains visible immediately.

### 9. Guidebook UI and navigation

- Add a 44×44 `?` button with localized accessible label and tooltip
  `Guidebook` to the pause header and the shared settings header. Both open the
  same guidebook modal and remember the return surface.
- `Escape` closes the guidebook back to pause or settings; it never resumes
  gameplay directly. The first unlocked category control receives deterministic
  focus on open.
- The guidebook uses one `ModalSurface` and separators rather than nested card
  panels: a 160 px category rail, a 230 px entry list, and a flexible detail
  region. At 960×540 it compacts to a 136 px rail and 200 px list without hiding
  controls or creating horizontal scrolling.
- Body text is at least 16 px, list text 17 px, category controls at least 44 px
  high, and headings use the existing Noto Sans KR strong weight. Korean and
  English expose identical entries and navigation.
- Flat procedural silhouettes reuse the same large-shape actor language. No new
  raster assets or external packages are added.
- Locked entries do not reveal enemy count, name length, attack type, stage, or
  description. The only visible content is the slot silhouette and `???`.

## Rejected Alternatives

| Alternative | Why it was viable | Why it was rejected |
| --- | --- | --- |
| Load Flooded Works for all five existing stage IDs without changing the catalog. | Smallest apparent patch. | Leaves map-specific gates, hazards, landmarks, validation, and boss assumptions attached to misleading stage IDs. |
| Preserve all five maps and only teleport the player to each map center. | Reuses shipped content. | Directly conflicts with the single-map requirement and keeps the current navigation/readability cost. |
| Uniformly scale Flooded Works from `4400×2800` to `5600×3400`. | Keeps the same topology with little authoring. | Scales lane widths, cover, travel gaps, and motif proportions while leaving combat ranges and actor size unchanged; the result is emptier and less legible rather than meaningfully larger. |
| Zoom the camera out to show the enlarged field. | Exposes more geography at once. | Defeats the requirement that the field extend beyond one screen and makes small enemies, pickups, and telegraphs harder to read. Gameplay zoom remains `1.0`. |
| Require all ordinary enemies to die before the boss. | Simple counter. | Recreates the prior hidden/stuck-enemy failure; a finite quota gives a clear, recoverable objective. |
| Keep the boss in a fixed arena. | Existing patterns and gates already support it. | Directly conflicts with roaming boss arrival and global pursuit. |
| Add five new secondaries in addition to the Seeker. | Maximizes content breadth. | The request is satisfied by five total families; six families would expand balance, UI, card-pool, and performance cost without a distinct missing tactical role. |
| Activate all five passive families in every run. | Makes every behavior immediately visible. | Removes build identity, adds visual noise, and increases passive simulation cost. Three active families preserve choice and readability. |
| Use chain lightning as the fifth family instead of an Escort Drone. | Familiar multi-target passive. | It overlaps Seeker auto-targeting and Ion Field crowd clearing; the drone adds displaced-origin positioning and better fits the vehicle identity. |
| Store guide discovery in `SettingsStore`. | Existing autoload already writes a config file. | Discovery is game progression, not a user preference; mixing them would broaden the settings owner and make resets unsafe. |
| Put the full guidebook in a fifth Settings tab. | Fewer modal types. | The content density and current-build state exceed the compact settings surface and would bury both settings and reference tasks. |
| Run one A* search per pursuing enemy. | Straightforward routes. | Current actor counts and the active rendered-performance contract require one shared low-frequency field instead. |

## Current State

Already true or reusable:

- [x] Godot 4.7 project, shared geometry helpers, deterministic packet scheduler,
  enemy roles, five boss identities, card resources, XP shards, two field pickup
  behaviors, Korean/English localization, current modal system, minimap, threat
  radar, fixed-step profiler, native boot, and Web export exist.
- [x] Flooded Works has a centered start and accepted Sunken Ceramic Fresco field
  art suitable for the shared map.
- [x] The current field is `4400×2800`; the gameplay camera is `1280×720` at
  zoom `1.0`; the minimap is `13×6`; and the current validator owns hard-coded
  old dimensions that Phase 1 must replace.
- [x] Primary fire, opening attack, dash, EMP, Seeker Launcher, card confirmation,
  and run-build persistence already provide the core combat loop.

Remaining implementation:

- [x] Separate shared field geometry from combat-stage profiles.
- [x] Replace route/installation progression with countable-defeat quotas.
- [x] Add shared pursuit and roaming boss arrival.
- [x] Replace manual intermediate result transitions with the automatic reward
  and center-reset flow.
- [x] Simplify movement upgrades and add four secondary families.
- [x] Add guidebook catalog, persistence, discovery hooks, UI, and localization.
- [x] Remove obsolete stage/map mechanics and reconcile specs, README, tests, and
  generated evidence.

## Scope

In scope:

- one shared `5600×3400` map for all five stages, with the exact expansion,
  camera, minimap, route, cover, and anchor contract in Locked Decision 1;
- stage-specific enemy composition, quota, stationary threats, boss, and rewards;
- ordinary mobile and boss global pursuit;
- automatic stages 1–4 transition and final stage result;
- direct base movement-speed upgrade only;
- five total secondary weapon families with at most three active;
- guidebook current stats and encounter-gated entries;
- Korean/English UI, keyboard/focus behavior, save migration, performance,
  rendered evidence, native boot, Web export, and canonical documentation.

Out of scope:

- any second map, procedural map generation, per-stage geometry, or map
  recoloring;
- new manual attack buttons, ammunition, defense action, or primary-weapon input
  changes;
- new enemy art assets, external asset packs, external packages, or realistic
  rendering;
- enemy raw stats in the guidebook;
- optional field bosses, exploration puzzles, a walkable base, meta-economy, or
  additional campaign stages;
- controller-specific redesign beyond preserving existing focus navigation.

Destructive or irreversible actions:

- None to user data. Legacy source files are deleted only after their behavior is
  migrated and the replacement validators pass in the same branch.

Exact actions requiring owner/user approval:

- None for this implementation. Dependency additions, campaign-length changes,
  save deletion, or changes to the locked weapon/slot/quota contracts require a
  new explicit approval.

## Architecture and Ownership

| Concern | Final owner | Interface / invariant | Existing owner to reuse or retire |
| --- | --- | --- | --- |
| Shared field geometry and anchors | `scripts/vehicle/stages/drowned_ruin_field.gd` | Immutable `5600×3400` field with center `(2800,1700)`, translated core, six exact extensions, thirteen covers, four waters, four motif placements, sixteen ordinary anchors, and eight boss anchors; consumed by drawing, collision, minimap, spawning, camera, and validation. | Migrate and enlarge Flooded Works geometry; reuse motif drawing from `vehicle_stage_visual_profile.gd`, retire stage-specific backdrop transforms, and retire all five map-definition files after migration. |
| Five combat-stage profiles | `scripts/vehicle/stages/vehicle_combat_stages.gd` behind `vehicle_stage_catalog.gd` | Stage ID maps to quota, packets, static threats, boss profile, rewards; every profile references the same field ID. | Replace geometry-bearing stage definitions. |
| Quota/boss/reward/transition state | `scripts/encounters/vehicle_stage_flow.gd` | Records only countable defeats, emits boss warning/start/reward/advance events, and exposes a read-only snapshot. | Extract progression flags from `vehicle_run.gd`; retire generator/cache/boss-gate state. |
| Timed packet scheduling | `scripts/encounters/vehicle_encounter_runtime.gd` | Deterministic time packets, active caps, stop-spawning contract, and metrics. | Reuse scheduler; retire route-event-only activation and home leashes for mobile actors. |
| Shared pursuit | `scripts/enemies/vehicle_pursuit_field.gd` | One 96 px reverse-cost field, max 5 Hz rebuild, shared by mobile enemies and boss. | Reuse `vehicle_stage_rules.gd` walkability and slide recovery. |
| Boss attack data | `scripts/bosses/vehicle_boss_patterns.gd` | Five portable local pattern sets with startup/active/recovery and cover behavior. | Reuse five identities; retire fixed arena/gate/reflector dependencies. |
| Secondary definitions | `scripts/player/vehicle_secondary_definition.gd`, `data/weapons/vehicle/secondary/*.tres` | Five typed definitions with behavior, level values, caps, and localization keys. | Migrate Seeker constants from `vehicle_run.gd`. |
| Secondary simulation | `scripts/player/vehicle_secondary_runtime.gd` | Receives player/enemy/cover snapshots, emits bounded damage/effect intents, owns passive timers/entities only. | Replace `_update_passive_secondary()` as a seeker-only owner. |
| Card compatibility/build state | `scripts/cards/vehicle_upgrade_definition.gd`, `vehicle_upgrade_catalog.gd`, `vehicle_run_build.gd`, `data/cards/vehicle/*.tres` | New-family first level consumes one of two optional passive slots; owned families can level; movement uses only Tuned Thrusters. | Reuse typed card system; retire Thruster Cycle. |
| Guide entry metadata | `scripts/progression/vehicle_guidebook_catalog.gd` | Stable IDs, categories, localized keys, silhouettes, ordering; no runtime state. | Reads enemy, boss, item, and secondary IDs without hard-coding entries in UI. |
| Guide discovery persistence | `scripts/autoload/vehicle_guidebook_store.gd` | Versioned known-ID sets in `user://vehicle-guidebook.cfg`; invalid IDs are discarded; settings file is untouched. | New autoload; do not expand `SettingsStore`. |
| Guidebook presentation | `scripts/ui/vehicle_guidebook_panel.gd`, `vehicle_settings_panel.gd`, `vehicle_stage_ui.gd` | Snapshot-only localized modal, `?` entry, return-surface and focus contract. | Reuse current theme and modal root; remove intermediate result advance control. |
| Runtime orchestration | `scripts/vehicle/vehicle_run.gd` | Connects owners, forwards intents/snapshots, draws live actors; does not become a second catalog/store. | Shrink stage progression, passive, and persistence responsibilities. |

## As-Is / To-Be Delta Map

| Concern | As-is | To-be | Acceptance check | Guard / leftover check |
| --- | --- | --- | --- | --- |
| Map | Five geometry definitions reload in order; Flooded Works is `4400×2800`. | One exact `5600×3400` `drowned_ruin_field` persists for all five stages. | World/center equal `Rect2(0,0,5600,3400)` / `(2800,1700)`; geometry fingerprint and field ID are identical across transitions. | No stage-specific walkable/cover/water owner or old `4400×2800` layout assertion remains. |
| Camera/minimap | Gameplay zoom is `1.0`; exploration uses a coarse `13×6` grid. | Keep zoom `1.0` and use a `16×10` grid with `350×340` world-pixel cells. | At `1280×720`, the field spans `4.375×4.722` screens; cell mapping and `3×3` reveal pass at all edges. | No gameplay fit-to-world zoom or stale 13/6 constant remains. |
| Progress | Generators, cache, zone, boss arena, and result button. | Countable defeat quota, roaming boss, reward queue, automatic center reset. | Boss starts at quota without any location interaction; stage increments after reward confirmation. | No `boss_gate`, `boss_arena`, `chest_claimed`, or `advance_requested` progression dependency remains. |
| Pursuit | Packet leashes return mobile enemies home and can deactivate them. | Mobile actors and bosses globally path toward the player. | Simulated mobile and boss path distances decrease around cover; stationary roles do not move. | No mobile role uses spawn-home deactivation. |
| Movement | Permanent and periodic movement upgrades. | One permanent three-level Tuned Thrusters card. | Runtime speeds equal 280/302.4/324.8/347.2. | No Thruster Cycle resource, timer, badge, copy, or validator expectation remains. |
| Secondary | One seeker behavior with several modifiers. | Five families, max three active, bounded runtime. | Each family passes damage, cover, cap, level, attribution, and offer tests. | No passive loop remains hard-coded only to seeker shots. |
| Reference UI | No guidebook or discovery state. | `?` opens current ship, enemies, towers, bosses, and items with persistent discovery. | Locked/unlocked/current-build states pass focus, locale, save, and rendered checks. | Unknown entries reveal no hidden localized name/description. |
| Inter-stage UI | Result modal and manual Next Stage after every boss. | No result modal during stages 1–4; final result only after stage 5. | Stage 1 reward returns to stage 2 center within one second of final confirmation. | No intermediate result path can receive focus. |

## Tasks

### Phase 1: Shared-field and stage-flow contracts

**Goal:** establish validated data and state owners before changing live combat.

**Source owners touched:** `scripts/vehicle/stages/`,
`scripts/vehicle/vehicle_stage_catalog.gd`,
`scripts/vehicle/vehicle_stage_rules.gd`,
`scripts/vehicle/vehicle_stage_backdrop.gd`,
`scripts/vehicle/vehicle_stage_visual_profile.gd`,
`scripts/vehicle/vehicle_run.gd`,
`scripts/encounters/vehicle_stage_flow.gd`, validation scripts.

- [x] **1.1 Create the immutable shared field.**
  - **As-is:** Flooded Works mixes reusable geometry with stage gates, field boss,
    installations, pickups, packets, and boss chamber data in a `4400×2800`
    world; the minimap and layout validator encode that old size.
  - **To-be:** create the exact `5600×3400` field in Locked Decision 1: translate
    the accepted core by `(600,300)`, apply the exact lower-west cover correction,
    add the six listed walkable rectangles and four listed outer covers, replace
    water with the four listed border rectangles, place the four listed large
    motifs, set center `(2800,1700)` and clearance `480`, install the sixteen
    ordinary/eight boss anchors, remove the fixed boss gate, retain camera zoom
    `1.0`, and change minimap resolution to `16×10`.
  - **Accept:** one field schema validates exact bounds/center/counts/coordinates,
    all anchors as walkable and reachable at their `36 px` ordinary or `122 px`
    stage-boss radius, every center-to-anchor route at
    `≤3640 px`, minimum `168/320/240×240` clearances, two routes per outer court,
    thirteen cover rectangles, four water rectangles disjoint from walkable
    floor, four valid large motif bounds, `350×340` minimap cells, and no
    one-screen fit at all three supported viewports.
  - **Guard:** world drawing, collision, projectiles, LOS, minimap, pursuit, and
    validators consume the same polygons; actor scale, weapon range, movement
    values, and gameplay camera zoom do not change.
- [x] **1.2 Create five combat-stage profiles.**
  - **As-is:** each stage owns a complete map.
  - **To-be:** `vehicle_combat_stages.gd` owns the exact quota table, timed
    packets, static threats, boss identity/pattern profile, pickups, crates, and
    reward configuration while referencing one field ID.
  - **Accept:** five profiles validate and each contains at least
    `quota + active_cap` countable enemies.
  - **Guard:** no profile contains walkable, cover, water, boss gate, boss arena,
    or stage-environment geometry.
- [x] **1.3 Add a stage-flow state machine.**
  - **As-is:** progression booleans and reward flags are spread through
    `vehicle_run.gd`.
  - **To-be:** `vehicle_stage_flow.gd` owns stage index, quota progress,
    spawn/boss/reward/transition states, and deterministic events.
  - **Accept:** a headless state test walks all five profiles from zero kills to
    final result without a map or zone input.
  - **Guard:** summons and boss pylons never increment the quota.

**Batch acceptance:** the catalog can return five distinct combat profiles and
one identical field definition; the current live runtime still boots while the
new path is not yet connected.

**Batch guard:** do not delete legacy stage files in this phase.

### Phase 2: Stage 1 vertical slice — timed pursuit, roaming boss, automatic reset

**Goal:** make one complete, user-testable stage use the final loop before
expanding it to all five stages.

**Source owners touched:** `scripts/encounters/vehicle_encounter_runtime.gd`,
`scripts/enemies/vehicle_pursuit_field.gd`, `scripts/vehicle/vehicle_run.gd`,
`scripts/ui/vehicle_stage_ui.gd`.

- [x] **2.1 Convert Stage 1 packets to timed distributed arrivals.**
  - **As-is:** later packets depend on route events and mobile actors retain a
    home leash.
  - **To-be:** keep the six-second opening, schedule all Stage 1 groups by time
    from distributed anchors, and stop the scheduler at 96 countable defeats.
  - **Accept:** an idle-player simulation observes the first scout at 6.0 seconds
    and arrivals from at least three distinct anchors before the quota.
  - **Guard:** active caps, bounded unit spacing, and eight-squad surge cohesion
    remain deterministic in both presets.
- [x] **2.2 Add shared global pursuit.**
  - **As-is:** mobile enemies return home or become dormant outside a leash.
  - **To-be:** mobile Stage 1 roles sample the shared 96 px pursuit field and use
    local role movement when close enough to attack.
  - **Accept:** representative chaser and shooter routes reach attack distance
    from every enemy anchor without crossing solid cover.
  - **Guard:** turret and Arc Mine positions remain unchanged for 30 simulated
    seconds.
- [x] **2.3 Spawn and run the Foundry Colossus in the open field.**
  - **As-is:** boss start requires authored progression and an arena trigger.
  - **To-be:** exactly the 20th countable defeat starts the 1.5-second warning,
    chooses a valid distant anchor, and starts a globally pursuing boss.
  - **Accept:** the boss spawns at least 1200 px away when possible, appears on
    minimap/threat radar, reaches the player around cover, and executes only
    startup/active/recovery attacks.
  - **Guard:** no boss gate, boss chamber, cache contact, or location trigger is
    read.
- [x] **2.4 Complete the Stage 1 → Stage 2 automatic transition.**
  - **As-is:** a result modal requires a Next Stage command.
  - **To-be:** boss death runs cleanup, XP recall, pending level-up choices,
    mandatory boss choice, fade, full repair, center reset, and Stage 2 safe
    arrival automatically.
  - **Accept:** build levels and XP remainder are unchanged across transition,
    hull is full, position equals field center, and stage index increments once.
  - **Guard:** carried attack/confirm input cannot fire or select during the
    transition.

**Batch acceptance:** a human can boot, kill 20 countable enemies anywhere on the
field, fight the roaming boss, confirm rewards, and begin Stage 2 at center with
no manual result action.

**Batch guard:** do not migrate stages 2–5 until this complete slice passes its
focused validators and rendered evidence.

### Phase 3: Five-stage single-field campaign and portable bosses

**Goal:** migrate the remaining stage compositions and bosses without restoring
map-specific progression.

**Source owners touched:** `scripts/vehicle/stages/vehicle_combat_stages.gd`,
`scripts/bosses/vehicle_boss_patterns.gd`,
`scripts/enemies/vehicle_enemy_specialist_runtime.gd`,
`scripts/vehicle/vehicle_run.gd`.

- [x] **3.1 Connect the Stage 2–5 quota profiles.**
  - **As-is:** each later stage changes field geometry and adds map mechanics.
  - **To-be:** use the exact 128/160/192/224 quotas and role table on the same field;
    reset static threats, items, crates, packets, and dynamic markers only.
  - **Accept:** every stage reaches its quota with ordinary enemies available and
    begins its boss without player location input.
  - **Guard:** field geometry fingerprint, camera bounds, backdrop resource, and
    explored minimap cells remain constant across all transitions.
- [x] **3.2 Make all five boss profiles field-portable.**
  - **As-is:** some patterns assume currents, grounded lanes, switches, reflectors,
    or a fixed arena.
  - **To-be:** preserve each boss’s four-pattern identity while expressing every
    attack relative to boss/player, shared cover, and validated local summons.
  - **Accept:** each boss completes phase one and phase two pattern cycles from
    all eight boss anchors without leaving walkable space or losing pursuit.
  - **Guard:** every damaging pattern retains visible startup, active, recovery,
    damage, and cover behavior.
- [x] **3.3 Finalize run completion.**
  - **As-is:** every stage enters result mode.
  - **To-be:** only Stage 5 enters final result/garage; stages 1–4 use automatic
    transitions.
  - **Accept:** one debug run completes five rewards and one final result, with
    exactly four automatic transitions and no duplicate clear increment.
  - **Guard:** replay resets run build/map exploration but preserves settings and
    later guide discovery.

**Batch acceptance:** a deterministic full-run validator completes all five
stages on one field and records the exact quotas, bosses, four transitions, and
one final result.

**Batch guard:** field bosses and old map interactions cannot appear through a
stale packet, marker, objective, save, or debug path.

### Phase 4: Simple movement and five bounded secondary families

**Goal:** create visible build variety without new controls or unbounded
simulation.

**Source owners touched:** `scripts/player/`, `data/weapons/vehicle/secondary/`,
`scripts/cards/`, `data/cards/vehicle/`, `scripts/vehicle/vehicle_run.gd`,
`scripts/ui/vehicle_stage_ui.gd`, `scripts/ui/vehicle_status_orbit.gd`.

- [x] **4.1 Reduce movement progression to Tuned Thrusters.**
  - **As-is:** permanent and periodic movement upgrades coexist.
  - **To-be:** apply exact 1.08/1.16/1.24 permanent multipliers, guarantee the
    second-level-up offer when unowned, and remove Thruster Cycle behavior/data/UI.
  - **Accept:** direct stat tests return 280/302.4/324.8/347.2 and no other
    ordinary-movement card exists.
  - **Guard:** dash speed, dash cooldown, dash behavior cards, and current input
    stay unchanged.
- [x] **4.2 Add typed secondary definitions and runtime.**
  - **As-is:** `vehicle_run.gd` directly schedules Seeker projectiles.
  - **To-be:** define Seeker, Ion Field, Orbit Blades, Wake Mine Layer, and Escort
    Drone resources and run them through one bounded secondary runtime.
  - **Accept:** each family matches its exact level table, cover rule, damage
    attribution, target rules, and hard entity cap.
  - **Guard:** no family allocates unbounded projectiles, particles, target maps,
    mines, blades, or drones.
- [x] **4.3 Add four family cards and the three-family slot contract.**
  - **As-is:** Seeker modifiers are always compatible and no passive slot count
    exists.
  - **To-be:** the four new max-level-3 family cards consume one optional passive
    slot on first acquisition; offers exclude unowned families at the three-family
    total while continuing owned levels/modifiers.
  - **Accept:** offer tests cover zero, one, and two optional slots; card selection
    never silently replaces an equipped family.
  - **Guard:** first level-up still contains primary and element choices; the
    second level-up Tuned Thrusters guarantee remains intact.
- [x] **4.4 Expose passive state without enlarging combat HUD.**
  - **As-is:** HUD and garage label the passive as Seeker only.
  - **To-be:** keep Seeker cooldown in the dock, draw other families in-world,
    and list equipped family names/levels in garage and guide snapshots.
  - **Accept:** all three active families remain understandable at gameplay zoom
    and do not obscure player, hostile telegraphs, threat arcs, or status badges.
  - **Guard:** opaque HUD area stays within the existing 12% limit at 960×540.

**Batch acceptance:** a debug build can equip Seeker plus any two new families,
exercise all level-3 behaviors under cover, and remain within fixed entity and
frame budgets.

**Batch guard:** selecting a fourth family is impossible through UI, debug calls,
save restoration, or malformed data.

### Phase 5: Persistent encounter guidebook and current-build UI

**Goal:** make known mechanics and the live build understandable without exposing
unencountered content.

**Source owners touched:** `scripts/progression/vehicle_guidebook_catalog.gd`,
`scripts/autoload/vehicle_guidebook_store.gd`, `project.godot`,
`scripts/ui/vehicle_guidebook_panel.gd`, `vehicle_stage_ui.gd`,
`vehicle_settings_panel.gd`, enemy/boss/item catalogs, localization.

- [x] **5.1 Define stable guide entries and versioned discovery persistence.**
  - **As-is:** names exist in separate catalogs and no discovery state exists.
  - **To-be:** register current ship sections, mobile roles, stationary roles,
    five bosses, and four field objects under stable IDs; store sanitized known
    IDs in `user://vehicle-guidebook.cfg` schema version 1.
  - **Accept:** save/load round trips known IDs, discards unknown IDs, survives a
    malformed guide file by resetting only guide discovery, and never modifies
    settings or run progress.
  - **Guard:** UI receives entry snapshots and never becomes the metadata or save
    owner.
- [x] **5.2 Wire exact encounter discovery events.**
  - **As-is:** visibility, attacks, damage, boss arrival, pickups, and crate breaks
    do not record discovery.
  - **To-be:** emit the locked discovery event for each source and update the
    guide store idempotently.
  - **Accept:** each event unlocks only its own entry once; previewing an upgrade
    and minimap-only ordinary markers do not unlock hidden entries.
  - **Guard:** hidden names/descriptions are absent from locked UI snapshots, not
    merely visually obscured.
- [x] **5.3 Build the localized guidebook flow.**
  - **As-is:** pause and shared settings have no guide entry.
  - **To-be:** add the two `?` controls, one responsive guide modal, category/list/
    detail navigation, `???` locked state, return-surface tracking, and Escape/
    focus behavior.
  - **Accept:** Korean and English locked, partially discovered, and fully
    discovered captures fit at all supported viewports and all commands are at
    least 44 px.
  - **Guard:** settings remains four focused configuration tabs; guide content is
    not duplicated inside them.
- [x] **5.4 Feed truthful current-ship stats.**
  - **As-is:** garage shows a summary string and fixed Seeker/EMP labels.
  - **To-be:** build one semantic runtime snapshot containing the exact derived
    stats and acquired/equipped levels listed in the guide contract.
  - **Accept:** guide values match direct runtime calculations before/after
    Tuned Thrusters, primary modifiers, EMP modifiers, and three secondaries.
  - **Guard:** enemy raw stats and hidden future upgrade data never enter the
    snapshot.

**Batch acceptance:** from paused gameplay, `?` opens the guide, shows current
build truth, hides future enemies as `???`, persists a newly encountered enemy,
and returns to pause without resuming play.

**Batch guard:** deployment/settings/garage entry paths return to their exact
origin and cannot leave two modal layers visible.

### Phase 6: Legacy retirement, specification reconciliation, and release gates

**Goal:** leave one canonical implementation and one truthful documentation set.

**Source owners touched:** obsolete stage files and runtime branches,
`docs/product/vehicle_game_spec.md`, `docs/design/UI_VISUAL_SYSTEM.md`, `README.md`,
all relevant validators and capture helpers.

- [x] **6.1 Delete migrated five-map and fixed-gate owners.**
  - **As-is:** five stage files, environment branches, boss arena/gate helpers,
    field-boss progression, relay/generator gates, and intermediate result advance
    paths remain.
  - **To-be:** remove these files, fields, functions, localization keys, markers,
    capture paths, and tests after replacements pass:
    `flooded_works.gd`, `tidal_archive.gd`, `storm_drydock.gd`,
    `coral_switchyard.gd`, `abyssal_observatory.gd`, their stage-environment
    branches, and obsolete Thruster Cycle assets/copy.
  - **Accept:** `rg` finds no live references to retired map classes,
    `boss_gate`, `boss_arena`, `chest_claimed`, map-specific environment IDs,
    `thruster_cycle`, or intermediate `advance_requested` behavior.
  - **Guard:** five boss identities, shared-field art, current settings, final
    result, garage, and persistent clear count remain.
- [x] **6.2 Reconcile canonical product and visual contracts.**
  - **As-is:** specs describe five maps, installation gates, field bosses,
    periodic movement speed, Seeker-only passive support, and result after every
    stage.
  - **To-be:** update the active product spec, visual system, docs indexes where
    needed, and README to describe the implemented single-field quotas, roaming
    bosses, automatic transitions, five secondaries, simple speed card, and
    guidebook.
  - **Accept:** no active document claims a replaced map, gate, movement cycle,
    secondary count, card count, or result flow.
  - **Guard:** accepted flat-color art direction, primary controls, Korean default,
    and performance/accessibility contracts stay intact.
- [ ] **6.3 Run focused, full, performance, build, and rendered gates.**
  - **As-is:** validators assume five layouts and current progression.
  - **To-be:** add focused single-field, secondary, and guidebook validators;
    update existing run, upgrade, settings, reward, boss, navigation, pressure,
    and capture contracts.
  - **Accept:** every command in Test Plan passes from a clean process and all
    required captures receive a human visual review. The functional, build, and
    rendered-content checks have passed, but the performance subgate is reopened:
    `2026-07-23-vehicle-performance-architecture-stabilization.md` must pass its
    rendered native/Web frame-pacing and lifecycle contract.
  - **Guard:** no ignored validation error, malformed save warning, orphaned
    runtime helper, generated capture, or build artifact enters the commit.
- [ ] **6.4 Retire this ExecPlan after implementation acceptance.**
  - **As-is:** this document is the active work owner.
  - **To-be:** after all durable behavior is recorded in the active specs and all
    checks pass, delete this plan in the final implementation commit as required
    by `.agents/PLANS.md`.
  - **Accept:** `.agents/execplans/` contains no completed copy of this plan.
  - **Guard:** do not delete the plan before its completion criteria pass.

**Batch acceptance:** current code, active specs, README, localization, tests, and
rendered evidence describe and demonstrate the same game.

**Batch guard:** no legacy direction remains executable or agent-authoritative.

## Test Plan

### Focused inner-loop commands

```powershell
.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_single_field_campaign.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_secondary_weapons.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_guidebook.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_upgrade_system.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_settings_store.gd
```

### Batch gates

- Phase 1: exact `5600×3400` field/schema/state-flow, route-clearance,
  anchor-coordinate, camera-bound, and `16×10` minimap validators.
- Phase 2: Stage 1 quota, pursuit, boss anchor/path, reward, and automatic
  transition validator plus one 1280×720 rendered slice.
- Phase 3: full five-stage debug run, five boss pattern cycles, shared geometry
  fingerprint, and navigation clearance.
- Phase 4: all five passive families at levels 1–3, slot compatibility, damage
  attribution, cover behavior, entity bounds, and performance scenario.
- Phase 5: locked/partial/full guide persistence, truthful stat snapshot, modal
  focus/return, locale parity, and three viewport captures.
- Phase 6: complete suite, native boot, Web export, performance, rendered review,
  document and leftover checks.

### Final gates

Full validator suite:

```powershell
Get-ChildItem tools/validation -Filter *.gd | Sort-Object Name | ForEach-Object {
  .\tools\godot.ps1 --headless --script ("res://tools/validation/" + $_.Name)
  if ($LASTEXITCODE -ne 0) { throw "Validation failed: $($_.Name)" }
}
```

Legacy subsystem microbenchmark and boot:

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/profile_vehicle_pressure.gd
.\tools\godot.ps1 --path . --headless --quit-after 2
.\tools\export_web.ps1
```

The headless pressure command is diagnostic only. Release performance requires
the complete rendered native/Web scenarios, thresholds, lifecycle soak, and
evidence defined by
`2026-07-23-vehicle-performance-architecture-stabilization.md`.

Rendered evidence:

- Capture 960×540, 1280×720, and 1920×1080 in Korean and English.
- Required states: a debug full-field capture proving the six extensions and
  connected routes, gameplay at center and all four outer courts, Stage 1
  ordinary pressure, boss arrival from an off-screen anchor, roaming boss near
  shared cover, three active secondary families, pause with `?`, guide locked
  state, guide partial state, guide current ship state, upgrade selection,
  Stage 1 → 2 center reset, and final result.
- Verify no clipping, overlap, hidden command, opaque central obstruction, tiny
  Korean copy, unreadable `???`, passive/hostile effect confusion, or focus loss.
- At gameplay zoom `1.0`, verify the whole `5600×3400` field cannot fit inside
  any supported viewport, floor/void boundaries remain legible, and no new lane
  looks passable while rejecting a player-radius traversal.
- Before any browser server is started under `D:\npjt`, load `npjt-port-guard`
  and use the fastrun manager Codex lane. Native built-app review is still
  required even when Web review passes.

Persistence and cleanup:

```powershell
rg -n "boss_gate|boss_arena|chest_claimed|thruster_cycle|advance_requested|tidal_archive|storm_drydock|coral_switchyard|abyssal_observatory" scripts data localization docs README.md
git diff --check
git status --short
```

Expected remaining textual references after cleanup are limited to deliberate
historical migration notes in the active implementation commit, if any; active
runtime, localization, specs, and README must contain none of the retired
contracts.

### Rerun policy

- Rerun a failed focused validator only after a concrete code/data change or a
  new hypothesis.
- Rerun full gates only after the suspected cause changed.
- Treat native/Web boot failures, save corruption, stage-transition deadlock,
  guidebook hidden-data leaks, invalid boss spawn, and any failed rendered
  performance threshold in the active stabilization plan as blockers, not
  warnings.

## Rollback / Safety

- Add no external package, asset dependency, or install step.
- Keep legacy stage files until the shared field and full-run validators pass;
  delete them only in Phase 6 in the same coherent branch that removes all
  references.
- Keep `cardborne-settings.cfg` untouched by guide discovery. A malformed
  `vehicle-guidebook.cfg` resets only guide discovery and logs one warning.
- Never delete or reset an existing user save during migration. Missing guidebook
  data means an empty discovery set, not a failed load.
- Stage transition advances only after every queued mandatory reward resolves.
  If applying a reward fails, keep the modal open, report the existing localized
  error, and do not increment the stage.
- Boss arrival never chooses an invalid/unreachable point. If the 1200 px filter
  removes every anchor, use the farthest validated anchor and retain the full
  warning.
- Passive entity caps are hard invariants. At cap, Wake Mine Layer retires the
  oldest mine; other families reuse their fixed instances rather than allocating
  more.
- If pursuit has no valid neighbor, request a rebuild and use bounded local slide
  recovery. Do not teleport an actor toward the player or allow it through cover.

## Risks

- **Runtime concentration:** `vehicle_run.gd` is already large. Mitigation is to
  extract stage flow, pursuit, secondary simulation, and guide persistence into
  the named owners rather than adding new dictionaries and branches in place.
- **Boss portability:** later boss names imply retired map mechanics. Mitigation
  is to preserve recognizable attack rhythm while making effects local and
  validating all patterns at every boss anchor.
- **Passive visual noise:** three simultaneous families can compete with hostile
  telegraphs. Mitigation is large flat silhouettes, hard entity caps, short
  effects, existing semantic colors, and rendered maximum-pressure review.
- **Card-pool dilution:** four new family cards can hide basic upgrades.
  Mitigation is the locked second-level Tuned Thrusters guarantee and slot-aware
  compatibility that removes impossible family cards.
- **Guidebook save drift:** catalog IDs can change during cleanup. Mitigation is a
  versioned store that sanitizes against the current catalog and never stores
  localized strings.
- **Same-field repetition:** map identity no longer changes. Mitigation is staged
  enemy-role introduction, different stationary threat sets, five portable boss
  exams, evolving passive builds, and persistent minimap knowledge—not cosmetic
  recolors or added texture noise.
- **Larger-field downtime and navigation cost:** more area can separate the
  player from pressure and increases pursuit-grid cells. Mitigation is the exact
  six-region extension instead of uniform scaling, sixteen distributed spawn
  anchors, a `3640 px` maximum center-to-anchor route, unchanged combat scale,
  cached `96 px` pursuit cells rebuilt only on the existing triggers, and the
  rendered native/Web capacity contract in the active performance-stabilization
  plan.

## Open Questions

None. The implementation contract is decision-complete. Any request to change
the five total secondary families, three-family active limit, 96/128/160/192/224
quotas, five-stage length, `5600×3400` field geometry, `16×10` minimap, shared
field identity, or guide discovery semantics is change control and must update
this plan before implementation continues.

## Decision Notes

- **2026-07-23:** accepted one persistent field instead of five changing maps.
- **2026-07-23:** accepted quota-triggered roaming bosses that pursue the player
  and require no arena, gate, cache, generator, or location interaction.
- **2026-07-23:** accepted automatic post-reward center reset for stages 1–4 and a
  final result only after stage 5.
- **2026-07-23:** interpreted secondary breadth as five total families including
  the existing Seeker and capped simultaneous families at three for build choice,
  readability, and performance.
- **2026-07-23:** reduced ordinary movement progression to one direct permanent
  Tuned Thrusters card.
- **2026-07-23:** selected a separate persistent guidebook modal entered by `?`,
  with live ship stats and encounter-gated enemies, towers, bosses, and items.
- **2026-07-23:** enlarged the persistent field from `4400×2800` to exactly
  `5600×3400` by translating the accepted core and adding four outer courts plus
  two broad connector lanes; combat scale and camera zoom remain unchanged.

## Progress

- [x] Pre-plan discovery completed against current code, active specs, current
  documentation policy, tests, and bounded external genre references.
- [x] Product, architecture, data, UI, persistence, balance, retirement, and
  validation decisions locked.
- [x] Phase 1 complete.
- [x] Phase 2 complete.
- [x] Phase 3 complete.
- [x] Phase 4 complete.
- [x] Phase 5 complete.
- [ ] Phase 6 complete.
- [ ] Final gates complete.

## Next Steps

1. Complete
   `2026-07-23-vehicle-performance-architecture-stabilization.md`; its rendered
   native/Web and lifecycle gates are a prerequisite for this plan's Phase 6.3.
2. Rerun this plan's complete functional, build, rendered-content, and new
   performance gates from one clean commit.
3. Obtain user acceptance of the implemented behavior and rendered result.
4. After that explicit acceptance, delete this ExecPlan as required by the
   repository documentation lifecycle.

## Implementation Outcome — 2026-07-23

- One immutable `5600×3400` Drowned Ruins field now backs all five combat stages.
- Quota-driven encounters, global pursuit, roaming bosses, automatic reward
  transitions, five passive secondary families, Tuned Thrusters, and the
  persistent localized guidebook are implemented.
- Legacy five-map, fixed-gate, arena-lock, field-boss, intermediate-result, and
  periodic movement-cycle owners are removed.
- All 13 vehicle validators and the settings validator passed at implementation
  time; native boot and Web export succeeded, and the three required viewport
  captures were reviewed without clipping or modal overlap. Repeated Standard
  and Onslaught headless microbenchmark samples reported `4.507 ms` and
  `6.602 ms`, but subsequent user-observed lag proved that this selected-method,
  non-rendered average was not valid release-performance evidence.
- **2026-07-23 density amendments:** post-implementation play feedback replaced
  single-squad arrivals with eight-squad surges, increased finite mobile reserves
  to 260/300/340/380/420, expanded quotas to 96/128/160/192/224, and bounded both
  presets at a repeatedly measured 72 active enemies. Bosses reserve 24 hostile
  projectile slots, track and move during startup, fire predictively aimed
  repeated volleys, and limit stagger to a 0.75-second recovery-window interrupt.
- Phase 6.4 remains intentionally open because plan deletion requires explicit
  user acceptance under the documentation lifecycle policy.

## Completion Criteria

- [x] All five stages use the exact `5600×3400` field geometry and persistent
  `16×10` explored minimap state.
- [x] The translated core, six exact extension rectangles, thirteen covers,
  center `(2800,1700)`, sixteen ordinary anchors, eight boss anchors, route
  limits, and camera visibility metrics pass automated and rendered checks.
- [x] Mobile enemies and every stage boss pursue globally; stationary threats do
  not move.
- [x] Bosses appear at the exact quotas from valid distant anchors without a
  location or full-clear requirement.
- [x] Stages 1–4 advance automatically after all rewards and restart at center;
  Stage 5 alone opens final result.
- [x] Tuned Thrusters is the only ordinary movement-speed card and returns the
  exact four speed values.
- [x] Five secondary families exist, at most three can operate, and every family
  passes behavior, cap, cover, offer, attribution, performance, and visual checks.
- [x] The guidebook shows truthful current build data, persists discoveries, and
  hides unencountered entries as `???` without hidden-data leakage.
- [x] Korean and English modal/focus/copy parity and all three viewports pass.
- [ ] Full validators, native boot, Web export, built-app review, save checks,
  `git diff --check`, leftover search, and every rendered native/Web/lifecycle
  threshold in the active performance-stabilization plan pass from one clean
  commit.
- [x] Canonical product/visual specs and README describe the implemented game.
- [x] Legacy five-map, gate/arena, field-boss, periodic movement, Seeker-only,
  and intermediate result owners are gone.
- [ ] This completed ExecPlan is deleted after durable decisions land in the
  canonical specs.

## Stop Conditions

**Complete when:** every completion criterion and final gate passes, active specs
match runtime truth, and this plan has been retired according to repository
policy.

**Escalate only when:** an implementation result would require changing a locked
quota, weapon family, active slot count, five-stage length, field identity,
`5600×3400` geometry/minimap contract, persistence ownership, user data,
dependency set, or visible discovery rule.

**Do not stop when:** a stage-specific legacy helper is difficult to remove, a
boss pattern needs local reprojection, a focused validator exposes a defect, or
performance needs task-scoped optimization within the locked behavior.

## Handoff

```text
Goal:
Implement the enlarged `5600×3400` single-field five-stage vehicle campaign,
five bounded secondary families, simple Tuned Thrusters progression, and
persistent encounter guidebook.

Read first:
AGENTS.md
.agents/AGENTS.md
.agents/PLANS.md
.agents/execplans/2026-07-23-single-field-campaign-secondaries-guidebook.md
docs/product/vehicle_game_spec.md
docs/design/UI_VISUAL_SYSTEM.md

Execute exactly:
Complete Phases 1–6 in order. Do not migrate stages 2–5 before the complete
Stage 1 vertical slice passes. Do not add dependencies or alter locked product
contracts.

Validate with:
Run the focused checks beside each task, then every command and rendered review
in Test Plan.

Stop when:
All completion criteria pass, canonical specs match the implementation, legacy
owners are removed, and this completed plan is deleted per repository policy.
```
