---
type: spec
status: active
owner: BK
created: 2026-07-21
last_reviewed: 2026-08-12
canonical_for: Cardborne gameplay and product behavior
scope: Current run-selected-field five-stage vehicle campaign
related:
  - ../design/VISUAL_SYSTEM.md
  - ./vehicle_upgrade_catalog.md
  - ./vehicle_weapon_balance_spec.md
  - ../../.agents/semantic-v2-runtime-acceptance-evidence.md
---

# Cardborne Vehicle Game Specification

## Purpose

Cardborne is a top-down vehicle action shooter about steering through one large
run-selected field while manually aiming a held primary weapon, dashing through
pressure, and building a compact set of automatic secondary weapons. A new run
selects one of three registered macro fields plus five deterministic
stage-tactical content arrangements. All five combat stages reuse that field's
floor, boundary, five inner-wall groups, and two Transit Gate routes. Each
stage scatters its own three Anomaly Devices and fourteen direct pickups.

This is the canonical product contract for the current executable.

## Scope

This specification covers controls, the run-selected field, stage flow, enemies,
bosses, items, upgrades, HUD and modal flows, the guidebook, localization,
settings, persistence, and release validation. It does not promise unconstrained
procedural topology, a base stage, exploration puzzles, or content beyond the
five-stage run.

### Delivery target

- Cardborne's intended public distribution target is a desktop-browser game
  exported through Godot Web. Native builds remain development and QA paths.
- The repository is the source of truth. A generated Web export is a release
  artifact and must not become a separately hand-maintained version of the game.
- A browser release is not qualified by a successful boot alone. The complete
  five-stage loop, keyboard and mouse input, pause and pointer behavior, audio
  startup, persistence, Korean and English surfaces, and browser runtime
  performance must pass release validation.
- Mobile-browser controls, responsive touch play, hosting provider selection,
  and a public URL are not implied by this target and require separate decisions.

## Requirements

### Controls and player intent

| Intent | Default |
| --- | --- |
| Move | Arrow keys or WASD |
| Aim | Mouse position, independent of movement |
| Primary fire | Hold Mouse 1 |
| Dash | Space |
| EMP | Left Shift |
| Pause and settings | Escape |

- Primary fire repeats uniform rounds while held. Releasing fire only stops the
  cadence; waiting before the next press never changes that next round's
  damage, size, pierce, structure damage, status payload, or counter behavior.
- Dash is a fast defensive repositioning action. EMP is the sole explicit skill
  button. Secondary weapons operate automatically.
- Primary fire, dash, and the active weapon are rebindable. Conflicting bindings are rejected.
- Korean is the default locale. Korean and English, audio, reduced motion, and
  input settings persist.

### Fixed Hard run difficulty

- Every run uses the existing Hard combat profile. Deployment exposes no
  difficulty selector, description, lock explanation, or saved preference.
- Confirming deployment starts the complete five-stage run with that fixed
  profile. Stage transitions preserve it internally.
- The fixed profile composes with the shallow stage curve. It does not alter
  attack cadence, telegraph duration, hostile projectile speed, threat budgets,
  drops, experience value, or reward quality.

| Mode | Quota | Active cap | Ordinary health | Boss health | Damage | Movement speed | Approximate simultaneous pressure |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Hard | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 |

All non-boss enemy archetypes receive the existing final `2.60` health
multiplier after the fixed profile and shallow stage curve, then the stage
pressure `[1.15, 1.55, 1.70, 1.85, 2.00]`. The five ordinary health curve values
remain `[0.85, 1.00, 1.15, 1.30, 1.45]`. Stage 1 pressure is approximately 15%
lower than its previous value; Stage 2–5 pressure is higher. Boss health uses
the separate stage profile defined below.
Ordinary enemy-sourced damage applies the shared `1.755` multiplier, the stage
curve `[1.00, 1.03, 1.06, 1.09, 1.12]`, and the additional stage pressure
`[0.98, 1.30, 1.42, 1.54, 1.66]`. For one authored damage point these compose
to `1.7199/2.349945/2.641626/2.945943/3.262896`. Boss `final-effective` attacks
use their separate stage profile and bypass the ordinary multiplier and ordinary
stage pressure. Friendly or environmental damage bypasses both.
Repair Tenders restore `8 HP/s`, and Generator support ticks restore `8 HP` every
`0.75 s`; both healing outputs are twice their previous values.

### Damage readability and hostile projectiles

- Accepted hull damage starts exactly one second of post-hit invulnerability.
  For the first 0.20 seconds the ship uses a coral hit tint and a deterministic
  presentation-only recoil of at most five pixels. The camera response is
  bounded to three pixels. A fully absorbed barrier hit remains a distinct
  event and starts neither hull feedback nor hull invulnerability.
- During the remainder of invulnerability the ship alternates between its
  normal and pale-coral state without becoming transparent. Reduced motion
  replaces recoil, camera shake, and flicker with a steady pale-coral state and
  a thin ring.
- During the complete `0.20 s` dash, the craft and all hull-attached
  directional cues use the frozen dash direction. Craft-only positional hit
  recoil is suppressed during the dash. Orbiting secondaries remain centered
  on the true player position, and deployed mines remain world-positioned.
- Hull UI applies current damage immediately, holds the lost segment for 0.18
  seconds, then closes it over 0.45 seconds. This animation processes only while
  active.
- Hostile projectile motion and predictive aim share one effective-speed
  calculation with a multiplier of `0.82`. Authored damage determines both
  collision and rendered head size: light damage at or below `10` uses a
  five-pixel radius, standard damage below `20` uses six pixels, and heavy
  damage uses seven pixels. The head boundary is the collision boundary; the
  36-pixel trail is a non-damaging direction and affinity cue. The Pulse
  Cannon's unmodified projectile uses a seven-pixel collision radius, and
  upgrades scale from that base.
- An enemy's compact movement/contact radius remains independent from its
  player-projectile hit radius. The latter matches the enlarged visible target,
  and swept collision chooses the earliest intersected enemy. A round without
  explicit pierce is retired at that first enemy instead of crossing the
  visible body.
- Ordinary hull contact uses the relative swept path between the player's and
  enemy's physics-start and physics-end positions, so two moving bodies cannot
  cross between endpoint checks. Chaser, Scrap Drone, Rammer, and committed
  collective execution contact can damage at most once per warned active
  attack. Bulkhead Guard and Splitter Barge use persistent hull contact with a
  `0.8 s` per-enemy retry cooldown that starts only when barrier or hull accepts
  damage; an invulnerability rejection leaves the contact armed. Ranged,
  support, fixed-structure, and ordinary-mine hull overlap never deals contact
  damage. Boss contact remains independently authored.
- Every hostile attack has a startup descriptor produced from simulation
  values. Its `danger footprint` is the exact set of player-center positions
  that can receive damage: projectile radius plus player radius, contact
  colliders plus padding, beam half-width plus player radius, or the authored
  area radius. Projectile and beam corridors stop at the same current tactical
  wall as collision. From the first visible startup frame, damaging boss
  attacks hold their warned origin, direction, and target through impact; only
  warning readiness changes. These descriptors remain simulation truth and do
  not require a visible world route.
- Projectile attacks use muzzle/cadence and the actual projectile without a
  predicted route, including off-screen sources and live shots approaching the
  viewport. The threat radar owns the directional warning for an off-screen
  source. Charge startup routes remain hidden. Beam startup shows the exact
  committed damage corridor at low intensity; the active beam fills that same
  rectangle with a body, inner energy plane, and hot core. Neither state adds
  endpoint caps or a larger predicted route. Non-damaging support descriptors
  create no warning.
- Only boss attacks may create ranged circular bombardment. Every boss area uses
  one orange outer boundary for startup and its damaging window, independent of
  affinity. Controller and Artillery Spotter attacks are projectiles; ordinary
  mine proximity damage draws no world range ring. Affinity-specific inner rings,
  diamonds, center lines, tick bars, endpoint caps, and commit markers are absent.
  Circular damage falls linearly from 100% at the center to 45% at the boundary
  and stops outside it.
- `Affinity` is an attack's impact family and controls large color and trail
  shape cues: kinetic, thermal, toxin, cryo, arc, hybrid, or support.
  `Condition` means a real persistent poison or chill payload. Thermal Burst is
  immediate thermal area damage and never creates a persistent condition.
  Thermal, toxin, or cryo presentation alone never invents a condition. Current
  hostile attacks apply direct damage only; player primary rounds derive affinity
  from the one selected element. Multi-element player rounds are not legal.
- Every projectile stops at the same static or run-selected inner wall that blocks
  the ship. Attackable field structures resolve through the player structure-hit
  route and are never treated as reward cover. `wall_piercing` is an explicit projectile capability whose
  default is false. No current ordinary enemy, boss pattern, primary shot, or
  secondary shot receives that capability implicitly.
- An intact Anomaly Device blocks actors and player projectiles. Hostile
  projectiles pass through it and enemy AI never targets it, so a neutral
  interaction cannot become an unintended shield against enemy fire.
- The built-in primary weapon has an authored 1600-pixel range. At runtime its
  effective range is never shorter than the current visible world rectangle's
  diagonal plus 80 pixels, so an unobstructed target visible from any
  camera-clamped player position remains reachable.

### One run-selected field

- A new run deterministically selects `drowned_ruin_field`,
  `tidal_archive_field`, or `storm_drydock_field`. Every stage and retry keeps
  that macro field while each stage resolves one immutable tactical child.
  Every stage-facing title derives from the selected field in both Korean and
  English rather than reusing another field's label.
- Every registered field uses a `7200x4320` world rectangle and respawns the
  player at `(3600, 2160)`.
- Run-fixed wall and gate footprints have no forbidden overlap and
  remain outside the player-start clearance. The generator treats their exact
  rectangles or effect radii as reserved space for stage devices, direct
  pickups, ordinary spawn anchors, and boss arrival anchors.
- The center has a 560-pixel safe clearance. The camera remains at zoom 1, so the
  field is larger than one screen and exploration state matters.
- At least twenty broad walkable regions define each immutable floor. A run
  selects exactly five inner-wall templates without replacement from
  `i_short`, `i_long`, `l_small`, `l_large`, `t_small`, and `step`. Each group
  uses 192-pixel wall thickness, 96-pixel grid alignment, and 90-degree
  rotation. The selected walls are validated for the ordinary 36-pixel and
  boss 76-pixel actor radii before play.
- The generator places no neutral or traversable damage zone. Only authored
  enemy and boss attacks can create hostile damage areas on the field.
- Rendering, movement, projectile collision, line of sight, pursuit, minimap,
  and validation consume the same active tactical layout. Exact retries
  reproduce it, and the inner-wall geometry remains fixed through all five
  stages so a run reads as one continuous field rather than five reset maps.
- Thirty-two ordinary arrival candidates, twelve boss arrival anchors, and at
  least thirty-two content candidates are reusable authored sources. Each
  stage selects three Anomaly Devices and fourteen direct pickups with explicit
  separation. No stage owns a separate map, boss room,
  closed progression gate, switch maze, or reflector puzzle.
- Pickup contact uses the swept player path with the 24-pixel player radius and
  42-pixel pickup body. Endpoint contact, tangent contact, and a complete dash
  pass collect an active repair or recall exactly once; a path 0.1 pixels
  outside the combined 66-pixel radius misses.
- Capture, validation, and performance paths accept `--layout-seed=<integer>`
  and `--field-id=<id>`; their default layout seed is `0xC4A2B0`, and
  debug/performance snapshots expose the selected field, seed, and fingerprint.
- The explored minimap uses a 20x12 grid. Unvisited geometry remains concealed.
  Dynamic markers expose exactly six tactical roles: player craft, field
  pickup, intact Anomaly Device, mobile enemy, priority enemy, boss, and
  no separate objective marker. The pickup marker is `12 x 7.6`. The Anomaly Device silhouette scales every outer
  point by `1.20`. Elite distinctions, stage-specific boss identity, and the
  Mystery outcome are not separate minimap markers.

### Inner walls, Transit Gates, and Anomaly Devices

- An inner wall is run-fixed, impassable structure. It blocks movement,
  projectiles, line of sight, and pursuit through the same tactical geometry.
  It also provides the short attack break previously supplied by independent
  cover, so there is no separate cover category. A wall group may compile to
  two rectangles, but U, C, O, closed-room, and reward-pocket shapes are not
  generated.
- Two paired Transit Gate routes remain fixed through the run. Gates require a
  dwell, preserve aim, clear velocity, share a ten-second pair cooldown, grant
  the existing short transfer protection, and move only the player. They never
  damage actors.
- Every stage places exactly three Anomaly Devices. Each is a neutral 192-pixel
  body with an 84-pixel collision/target radius and 90 structure health, equal
  to five unmodified 18-damage primary hits. Player direct and area damage may
  break it; enemy AI and hostile attacks ignore it. It is not an enemy, never
  counts toward quota, and drops no XP or item.
- A stage assigns three different outcomes from `gravity_pull`, `cryo_lock`,
  `projectile_purge`, and `decoy_signal`. The first accepted player hit reveals
  the assigned outcome without triggering it; breaking the device applies it
  and reports the number of affected enemies or cleared hostile projectiles.
  Pull affects non-boss enemies within 480 pixels for
  1.2 seconds. Cryo lock stops non-boss movement and new attack starts within
  360 pixels for 0.8 seconds but does not cancel a committed warned attack.
  Projectile purge retires hostile projectiles within 420 pixels immediately.
  Decoy signal redirects nearby enemy movement/aim toward the wreck within 900
  pixels for 6 seconds without making the wreck an attack target.
- Cryo lock feeds the same exact-size translucent blue enemy-body compositor as
  Chill without creating a Chill stack. Projectile purge emits one short System
  pulse after the clear. Decoy redirection is visible because affected enemies
  face its target outside already committed attacks. The minimap never reveals
  the outcome.
- Every revealed Mystery effect shows its complete gameplay footprint from the
  device position: Gravity Pull radius `480` for `1.2 s`, Cryo Lock radius `360`
  for `0.8 s`, Projectile Purge radius `420` for its short pulse, and Decoy Signal
  radius `900` for `6 s`. A boundary accent never substitutes for the filled area.
- Primary rounds apply the same per-shot structure damage at every point in the
  firing cadence. Structure upgrades change the repeated-hit result for Mystery
  Devices, Bulkhead Guard plates, and armored-elite shells without introducing
  a special first or charged shot.
- Ordinary primary damage never cancels an enemy or boss startup. EMP remains
  the dedicated player-controlled crowd-control skill; the mystery cryo outcome
  is local, one-use, non-boss, and shorter than EMP. Boss direct attacks remain
  committed once warned while autonomous systems continue independently.

### Encounter and stage flow

1. Stage 1 deployment begins at the shared center. Stages 2–5 begin at the
   player's current position and facing without reopening deployment.
2. Stage 1 keeps its initial arrival cadence. After a successful Stage 1–4 transition,
   the next arrival cue begins after 0.35 seconds and the first hostile arrival
   begins within 1.35 seconds.
3. Main-combat packets retain twelve logical role squads but schedule them as
   three arrival windows of four squads. Every ordinary unit receives an
   independent birth position: 900–2400 pixels from the cue-time player
   position, at least 220 pixels outside the visible view, and at least 320
   pixels from other positions in its window and births from the previous two
   seconds. Allocation may extend to 2800 pixels but never falls back on-screen
   or below the hard separation floor. Canonical windows use all eight sectors
   with sector counts differing by at most one; runtime edge cases require at
   least two safe sectors or retry the whole window after 0.25 seconds.
   Each window exposes at most four exact-position cues and reserves those four
   first arrivals against the global cap before showing them. Ordinary cues
   lead the first atomic round by 0.90 seconds; windows begin at least 1.20
   seconds apart and tail rounds preserve 0.16-second unit spacing. Due rounds
   contain at most four enemies and later packets wait for the current packet's
   final round. Presentation copies at most eight active cue positions into a
   fixed receipt store and reuses the dim, no-triangle `nearby_enemy` radar arc
   for `cue visual duration + 1.10s`. Positions beyond 1,200 units are clamped
   to the radar boundary, so the cue exposes direction only and never changes
   trigger time, admission, birth position, count, capacity, or actor state.
   While the player travels at least 80 pixels per second, each due window starts
   its existing maximally-spaced sector order at the available sector nearest the
   travel heading. The remaining births still complete the same all-sector,
   deterministic distribution. At lower speed the seeded start sector is
   unchanged. This rule changes arrival order only; it never changes packet
   membership, count, cue timing, geometry, distance, or separation truth.
   Projectile-firing mobile roles remain at or below 15% of authored mobile
   population; only three ranged attackers and two denial attackers may commit
   at once. Ordinary hostile fire cannot consume the 24-shot boss reserve.
   Fixed-Hard active ordinary caps progress through `1/124/172/224/276`.
   Excess enemies remain in the deterministic scheduler queue. Player-centered 600
   and 900 pixel occupancy are observation telemetry only and never impose a
   local admission cap, hold band, lateral detour, or despawn rule.
4. Ordinary mobile movement applies one 1.40 multiplier after role base speed
   and before the fixed Hard profile, stage, and elite factors. Boss,
   committed charge, and projectile speeds are unchanged. After birth, each
   mobile follows its role pursuit/standoff/escort/support behavior. Pursuit
   roles keep closing until their attack contract. Ranged and support roles use
   continuous radial correction around their existing distance band while
   tangential movement peaks at the midpoint. Turn response is `9/s` for
   pursuit, `6/s` for standoff, and `5/s` for escort/support. Ordinary targeting
   separates pressure focus, movement focus, and committed attack target. The
   pressure focus is the current player or exact active Decoy position. At the
   existing decision cadence, a moving-player movement focus may lead pursuit by
   at most `1.20 s / 280 px`, standoff by `0.85 s / 200 px`, and escort/support by
   `0.60 s / 140 px`; movement below 80 pixels per second and Decoy focus receive
   no prediction. Shared route guidance is sampled only when a direct approach is
   blocked or a ranged actor in or beyond its safe band must recover a
   blocked firing lane. It never becomes a squad anchor or overrides a necessary
   close-range retreat. Ordinary attacks predict once when startup begins, include
   startup and projectile/charge travel, clamp direct lead to 260 pixels,
   artillery to 320 pixels, and beam lead to 220 pixels, then keep that warned
   target frozen through resolution. A blocked predicted line falls back to the
   current pressure focus. Attack timing remains unchanged. Artillery alone corrects
   its old unreachable `520–760` hold band to `440–600` and its direct-fire admission
   maximum from 880 to 650, within the unchanged shell speed and 2.2-second lifetime;
   other attack distance contracts remain unchanged. In all cases,
   logical squad anchors and centroid cohesion do not steer ordinary movement.
   Bounded local separation runs only during actual body overlap, checks at
   most eight nearby actors within 120 pixels, blends role/separation velocity
   at 0.55/0.45, and never exceeds the role's original speed. With no overlap,
   separation leaves the smoothed role velocity unchanged. Inner-wall recovery and committed
   attack paths take priority. High density near the player is an allowed
   convergence result. Stationary roles hold authored anchors. The tuned mobile
   base speeds are Scrap Drone/Chaser/Rammer `190`, Needle Drone `176`, Shield
   Escort `170`, Shooter `166`, Bulkhead Guard `164`, Repair Tender `159`,
   Splitter Barge `157`, Controller `150`, Artillery Spotter `140`, Drone Carrier
   `136`, and Spark Minelet `100` pixels per second. With the Stage 5 `1.04`
   curve, every ordinary continuous movement speed remains below the player's
   `280 px/s`; explicitly committed charges remain exceptions.
5. Ordinary defeats advance the stage quota. Living enemies never block travel
   or stage completion and summons do not count toward the quota.
   Reaching quota starts boss eligibility only; it does not stop the authored
   encounter scheduler or remove living ordinary enemies.
6. On reaching the quota, a 1.5-second boss warning
   identifies a reachable arrival anchor at least 1200 pixels from the player
   when the field permits it. Boss creation and boss-defeat completion reject
   calls unless the quota has been reached and the warning has resolved. If the
   enemy store cannot preserve the boss-entry reserve when the warning ends,
   boss entry stays pending and retries every progression tick. It begins once
   live enemies fall to the safe threshold and never exceeds the 320-enemy cap.
7. The boss enters the same field and pursues the player. It does not wait in a
   sealed arena. It repositions during its read state, predicts the player once
   when selecting an attack, then freezes its position and committed geometry
   while startup is visible. Circular target prediction is capped to 96 pixels
   from the player's commitment-time position. Every damaging circular pattern
   allows the base 280-pixel-per-second ship to clear the radius with at least
   40 pixels of margin during startup. Projectile attacks lock a predictively
   aimed lane and repeat volleys along it; charge, area, autonomous bombardment, and damaging
   summon patterns add one aimed three-shot pressure burst. Recovery resumes
   repositioning only after the committed attack ends.
8. Boss defeat records the completed-stage telemetry and removes only boss-owned
   adds, hostile projectiles, and damage zones. Stages 1–4 full-heal the ship and
   begin the next encounter in the same gameplay frame. Existing ordinary enemies,
   ordinary and player projectiles, XP shards, position, velocity, facing, aim,
   cooldowns, build, fixed Hard state, exploration, and run-fixed terrain remain.
   There is no boss reward card, forced XP recall, transition protection, banner,
   success report, timer, or continue input. Stage-local pickups and Anomaly Devices
   refresh for the new stage. Stage 5 opens the final result;
   failures still open the failure report.

| Stage | Fixed Hard quota | Authored mobile population | Boss |
| ---: | ---: | ---: | --- |
| 1 | 125 | 520 | Foundry Colossus |
| 2 | 166 | 660 | Archive Leviathan |
| 3 | 208 | 816 | Drydock Titan |
| 4 | 250 | 1026 | Switchyard Behemoth |
| 5 | 291 | 1260 | Crown Engine |

Ordinary hostile projectiles
stop at 96 so 24 of the global 120-shot cap remain reserved for boss attacks.
Stage 1 ordinary health and damage pressure is `1.15/0.98`, approximately 15%
below the previous `1.35/1.15`. Stage 2–5 ordinary health pressure is
`1.55/1.70/1.85/2.00` and damage pressure is `1.30/1.42/1.54/1.66`; each is
higher than its previous value. These multiply the existing stage, class,
fixed-Hard, and global factors without changing speed, cadence, projectile speed,
count, quota, or cap. Each
boss uses a distinct three-phase direct-pattern sequence plus independently
scheduled autonomous pressure. Every damaging pattern has a visible startup,
active window, and recovery. Routine hits never interrupt or stop the boss, and
every direct pattern remains committed after its warning appears.

Each boss owns one body-attached shield and no external objective actor.
Stage 1–5 boss profiles use target HP `5250/5805/6380/6975/7590`, damage
multipliers `1.50/1.60/1.70/1.80/1.90`, shield-up received-damage multipliers
`0.110/0.105/0.100/0.095/0.090`, cadence scales
`0.95/0.90/0.85/0.80/0.75`, and coverage scales
`1.05/1.10/1.15/1.20/1.25`. Phase 1–3 direct read gaps are
`0.45/0.34/0.26s`; autonomous base intervals are `5.4/4.4/3.5s`; authored direct
recovery is multiplied by `0.80`. Cadence scales only the read gap, initial
autonomous delay, and autonomous interval. Coverage scales each pattern's applicable radius,
beam width, lane spacing, and fan spread. Projectile count and speed, startup,
active duration, recovery, and caps remain pattern-owned. Autonomous `area`,
`lanes`, `beam`, and `summon` attacks execute their authored shape rather than a
generic circular substitute. Completing a direct boss attack lowers the
shield for four seconds, during which damage is `1.00×`, then the shield returns.
Phase thresholds start the next phase and raise the shield but are not HP floors.
The boss body owns the shield state and one always-visible world-attached health
bar. The four-second shield-down window produces one top-center hint; shield-up
does not produce a transient message.

### Items, experience, and upgrades

- Enemy defeats leave collectible geometric experience shards. Experience is
  granted only when a shard is collected; summoned enemies grant the normal XP
  for their health class.
- Exactly two field item behaviors exist: repair restores hull and experience
  recall pulls all live shards toward the player. Both spawn directly on the
  field. Recall retargets the ship's current position every physics
  frame and guarantees all live shards reach it before the 0.65-second recall
  window expires, including while the ship dashes.
- Each stage places fourteen direct pickups: four experience recalls and ten
  repairs. Nine repairs restore `50 HP` and one restores `40 HP`, for an exact
  `490 HP` field-repair budget. Repair collection clamps at the ship's current
  maximum Hull unless Overflow Barrier converts eligible excess recovery.
- Level thresholds use
  `min(96, 6 + round(1.5n + 0.32n²))`, where `n` is the zero-based level
  progression index. The first requirement is 6 XP, the first five requirements
  total 54 XP, and the late-run requirement is capped at 96 XP. The authored
  minimum-quota path ends at level 30. Each level opens a guarded selection
  of every legal offer card up to three and requires an explicit choice and
  confirm. When no compatible upgrade remains, one localized completion receipt
  marks XP as `MAX`, clears queued levels and live shards, and suppresses future
  shard spawning and XP awards for that run.
- The live catalog is the 28-card, 92-level-state contract in
  `vehicle_upgrade_catalog.md`. It uses six player-facing categories: Primary
  Weapon Mods, Secondary Weapon Systems, Attack Attributes, Active Weapons,
  Chassis & Support, and Combat Conditions. Category is separate from change
  kind and slot ownership. Dash, Seeker, and EMP remain base actions; one active
  weapon kind may replace EMP, and shared cards can modify all active weapons.
- A first acquisition is an `unlock` only when it creates a previously absent
  behavior: Split Muzzle, Piercing Rounds, an optional secondary, or an element.
  Homing Missiles is an `enhance` offer from its first card because Seeker starts
  equipped; all later behavior-card levels are enhancements. Change kind remains
  in the frozen offer and localized accessibility name, not visible card chrome.
- Every legal card state publishes one or two gameplay-owned effect rows. The
  extended attack sequences preserve existing object counts: Split Muzzle ends
  at three projectiles and `180%` volley damage; Piercing Rounds ends at four
  additional penetrations; Homing Missiles starts at two missiles and ends at four missiles and `38`
  damage; Electric Field ends at `22 DPS` and radius `160`; Orbiting Blades ends
  at four blades and `28` damage; Drop Mines ends at `88` damage, `2.4 s`
  interval, and five live mines; Auto Laser ends at `86` damage; Thermal Burst
  ends at `11` damage and radius `96`; Bio Toxin ends at `5.5 DPS` per stack for
  seven seconds. Optional-secondary, attribute, and active-weapon unlocks show
  acquired values without a false zero comparison.
- `Movement Speed`, `Pickup Radius`, `Hull Integrity`, `Lifesteal`, and
  `Overflow Barrier` form Chassis & Support. Pickup Radius preserves the former
  Pickup Magnet card's three-level collection effect. Every run starts with
  `0.5%` Lifesteal; its card raises the total rate to `2%`/`3.5%`. Recovery uses
  actual player-owned enemy damage and a six-Hull budget replenished at six Hull
  per second. Overflow Barrier applies Hull recovery first, then converts
  eligible excess at `50/75/100%` into an eight-second barrier capped at
  `15/25/35%` of maximum Hull.
- Primary payloads have one damage-attribute slot and one utility-attribute slot.
  Thermal Burst and Bio Toxin compete for the damage slot; Cryo Slow and Shock
  compete for the utility slot. One choice from each slot can coexist on the same
  primary projectile. Thermal radius is `72/84/96/96` with burst damage
  `4/5.75/8/11`; Toxin damage per stack is `2/2.85/4/5.5` with `5/6/7/7s` duration;
  Cryo slow per stack is `6/8/10%` with `2/2.5/3s` duration. Shock blocks only
  new enemy attack commitments for `0.6/0.8/1.0s`, has a three-second reapply
  lockout, does not alter movement, and never cancels an already warned or active
  attack. Boss Chill and Shock duration are halved.
- Combat Conditions contains Critical Hit, Dash Boost, Dash Afterburn Field, and
  Low-Hull Damage. Direct attacks have a
  deterministic `8/12/16%` critical chance for `2x` damage. Dash Boost grants
  `15/25/35%` for two seconds after Dash. Low-Hull Damage scales from zero below
  60% Hull to `5/10/20%` at 25% Hull. These non-critical bonuses add and cap at
  `+100%`; critical multiplication happens afterward.
- Dash Afterburn Field creates one exact capsule from the Dash start to the
  actual Dash end, including an end shortened by cover. Its half-width is 72,
  lifetime is three seconds, tick interval is 0.5 seconds, tick damage is
  `10/15/20`, and at most two paths remain active.
- **Secondary Weapons** is the umbrella category for six automatic weapon
  types. **Seeker** is its always-equipped built-in subtype; up to two of the
  other five optional subtypes may be active,
  for three total. Data expresses this with `secondary_slot_kind` values
  `built_in` and `optional`; offer eligibility counts only owned optional
  definitions and never infers slot ownership from a card ID. Seeker remains
  inside this umbrella category and does not consume an optional slot:

| Secondary | Combat role |
| --- | --- |
| Homing Missiles | Periodic targeted projectiles; upgrades increase count and damage |
| Electric Field | Damage over time near the ship |
| Orbiting Blades | Close orbiting contact damage at radius 88 |
| Drop Mines | One immediate mine, then timed mines behind movement or the stopped hull |
| Auto Laser | A cover-clipped beam toward the direction that intersects the most enemies |
| Storm Barrage | A warned area strike on a distant threat cluster |

Drop Mine is distinct from Thermal Burst. At levels 1–4 it applies one
`48/60/72/88` area hit at radius `96/108/120/120` after proximity or timeout, then
publishes one origin receipt only after damage resolution. Its cosmetic has a
`0.18 s` lifetime and an eight-instance subcap inside the unchanged 96-effect
store. When saturated, it may recycle only another Drop Mine cosmetic; missing
feedback never cancels or duplicates damage.

Auto Laser fires at most every `0.9 s` on a successful primary shot. It scores
up to 24 nearby candidates against that same bounded set and picks the direction
that intersects the most targets. It deals `48/66/86`, uses a 760-long corridor
with half-width 18, and stops at the first tactical wall. Storm Barrage checks
threats from 480 to 960 pixels every `4.5 s`, warns for `0.55 s`, then deals
`70/95/125` inside radius 140 to at most twelve eligible targets. It can damage
ordinary enemies and an Anomaly Device.

Secondary Cooldown applies one shared `0.90/0.82/0.75` cooldown multiplier to
Seeker, Electric Field, Orbiting Blades, Drop Mines, Auto Laser, and Storm
Barrage. Secondary Damage applies one shared `1.12/1.25/1.40` damage multiplier
to those same six families, including Seeker structure damage. These cards do
not consume an optional-secondary slot or raise an object or target cap.

Each Seeker missile applies its level-owned direct damage, then one `12` damage
kinetic burst to other enemies inside `95` world units. The direct target is not
damaged twice. Damage resolves before the bounded Explosive Seeker impact receipt;
missing or recycled feedback never cancels or repeats gameplay damage.

The third action slot always represents the equipped active weapon. EMP is the
default. One Black Hole, Shockwave, or Cross Beam card may replace it for the
run; shared active cooldown and damage cards apply to whichever weapon is
equipped. Active weapon state belongs to `VehicleActiveWeaponRuntime`, while
enemy, structure, and projectile mutation stays with the existing run owners.
EMP starts in `0.42s`, deals `62` in radius `285`, clears hostile projectiles in
radius `325`, stuns for `2.1s`, and has a `13s` cooldown. Black Hole starts in
`0.35s`, pulls non-boss mobile enemies at `360 px/s` for `1.2s` with a 10 Hz
bounded cadence, then deals `60/85/115/150` in radius `150/175/200/225`; it has a
`12s` cooldown and never displaces bosses or structures. Shockwave starts in
`0.20s`, deals `45/65/90/120` in radius `180/210/240/270`, and pushes non-boss
mobile enemies up to 180 without stun or projectile clearing; it has a `9s`
cooldown. Cross Beam starts in `0.30s` and deals `80/110/145/185` once per target
through the union of two map-spanning, cover-ignoring corridors with half-width
`24/32/40/48`; it has a `10.5s` cooldown. Startup presentation and collision use
the same exact half-width.

Accepted combat actions reduce the equipped active weapon's remaining cooldown.
One direct primary, secondary, or dash action removes `0.10s` once for its stable
action identity; periodic field or dash damage removes `0.025s` once per tick
identity. Outgoing recharge is limited to `0.40s` per real second with a `0.10s`
periodic sub-limit. One hostile hit that removes barrier or Hull removes `0.20s`
and starts a `1.25s` lockout. Active self-damage, status ticks, derived Thermal
Burst, reflection, structures, devices, zero damage, and ready-state events give
no credit or stored charge.

### UI, guidebook, and persistence

- Every player-facing world, actor, projectile, reward, effect, HUD, modal,
  minimap, and preview uses the shared general-SF visual system defined by
  `VISUAL_SYSTEM.md`. UI chrome comes from one code-native Theme and shared
  component factory; meaningful craft, upgrade, enemy, boss, object, minimap,
  and action imagery remains semantic gameplay content. Role color is always
  paired with a silhouette, notch, rail, or glyph cue.
- The ship uses one authored craft body containing its fixed hull, engine
  housing, and weapon housing. The body follows movement/hull rotation only;
  manual aim remains independent through cursor, muzzle, projectile, and hit
  cues. Dash feedback uses a directional afterimage and rear-anchor flare,
  never a danger ring or radial burst.
- The gameplay camera uses `0.5×` zoom, so the ship, enemies, facilities,
  pickups, terrain, projectiles, and world effects appear at half their previous
  screen size while world coordinates, collision radii, speeds, attack ranges,
  spawn counts, and map dimensions remain unchanged. HUD and modal CanvasLayers
  do not inherit this world scale.
- The fixed-capacity transient effect buffer contains dash afterimage, EMP
  charge/release, Thermal Burst, bounded Mystery purge pulses, Drop Mine, and
  Explosive Seeker impact receipts. It keeps its 96-effect
  ceiling, at most 24 live Thermal impacts, and at most eight live Drop Mine
  receipts; saturated Thermal
  feedback may recycle the oldest Thermal impact or drop the new cosmetic
  receipt but never evicts EMP or changes damage. Toxin, Chill, and Shock do not
  create effect objects. Existing enemy and boss batches share one status compositor;
  per-instance custom data composes a same-size translucent green, blue, or violet layer
  inside the authored body alpha without another draw, batch, actor, texture, or
  per-enemy material. Stack levels use ordered `0.66/0.76/0.84` colorization
  weights. The bounded 0.16-second application pulse reaches at most `0.94` only
  after the direct-hit flash ends, and Toxin DOT does not restart that generic
  flash. Reduced motion removes the pulse and keeps the static condition layer.
  Floating damage numbers remain absent.
- Every directional enemy publishes one simulation-owned effective facing.
  During startup and active attack phases this is the committed direction;
  otherwise it points to the player or an active Decoy target. Controller spin
  and nondirectional mine/generator bodies are the only exceptions. The renderer
  consumes this field and does not infer AI targets.
- The renderer keeps one fixed-capacity presentation sample for each enemy pool
  slot and generation. It interpolates scheduled `20/30 Hz` movement samples
  without changing simulation position, collision, targeting, or decision
  cadence, and resets on first appearance, pool reuse, reactivation, or a large
  discontinuity. Bodies and all attached shield, support, semantic, and health
  cues consume the same presented position.
- The live HUD starts at viewport `y=0` with full-width HP and EXP meters and no
  gap between them. HP shows centered `HP current / max`; EXP shows centered
  `LV N · EXP current / required` or `LV N · EXP MAX`. HP/EXP heights are
  `28/18`, `32/22`, `40/26`, and `52/32 px` for compact, standard, large, and
  200% text respectively. Immediately below, a panel-free one-line cluster at
  left margin `16/24/32 px` shows exactly five icon/value items in this order:
  stage deck stack `N / 5`, total-defeats skull with the run-cumulative count,
  Dash, Seeker, and the equipped active weapon. Action values are `READY` or
  remaining time to 0.1 s.
  Every icon owns one meaning; the cluster has no labels, panels, sections,
  borders, dividers, cooldown rings, or progress rails. Top-right owns only the
  minimap. No bottom-center action, live upgrade icon, edge boss/target health,
  mission surface, objective text, or ornamental dock is present.
- The normal top-center toast is `320×36` compact or `360×40` standard/large and
  sits four pixels below the lower edge of the status-cluster/minimap band. Only boss inbound, barrier depleted, Mystery
  Device result, boss shield-down, and progression-complete events may enqueue
  gameplay toasts. Stage
  transitions use no banner.
- Bosses and fixed combat installations
  (`turret`, `interceptor_tower`, `beam_sentinel`, and `generator`) own thick,
  backed health bars above their world bodies. Mobile enemies, mines, and
  Anomaly Devices never receive world health bars. Installation bars
  use a deterministic 12-actor cap. Fill left edges remain fixed at every health
  ratio. Installation and boss half-widths clamp to `42–72` and
  `96–120` world units; complete bars prefer the body top, move
  below when the top edge would clip, and clamp inside the visible world. All
  world health bars share one retained batch with a fixed 26-instance ceiling.
- The threat radar samples at five hertz and atomically publishes its sampled
  player origin, generation, and at most 12 directional sector records. The HUD
  rebases those bounded records against the live player world position and draws
  the retained radar at the matching projected player position every frame, so a
  complete dash cannot separate or squeeze the radar origin. This live-anchor path
  rebases fixed packed storage for exactly 12 sample/display slots; it does not
  allocate sector dictionaries, rescan enemies, or rebuild meshes. It includes targetable non-boss enemy
  bodies outside the visible world rectangle and within the greater of 1,200
  world units or the farthest visible corner plus a 480-world-unit band as dim
  `nearby_enemy` arcs. Scheduler-authored ordinary arrival cues reuse that same
  dim arc during their bounded receipt lifetime; farther cue offsets clamp to that
  runtime boundary. These arcs reveal direction and pressure density, never an
  exact coordinate or triangle. An unseen committed projectile attack has
  priority 3, boss arrival priority 2, and nearby enemy pressure priority 1 when
  contacts share a sector; only the winning role owns that sector's color and
  triangle. A single attack never appears as both a world route and a radar
  contact.
- The minimap publishes exactly six semantic roles: player, field pickup,
  intact Anomaly Device, mobile enemy, priority enemy, and boss. `turret`, `interceptor_tower`, `beam_sentinel`, and
  `generator` are priority enemies; other active non-boss enemies are mobile
  enemies. An intact Anomaly Device uses one neutral marker that never leaks its
  hidden result, and resolved or retired devices disappear. Bosses use one
  command-magenta notched marker independent of stage. All roles share the existing
  marker capacity, borrowed buffers, explored geometry, fog, and one retained
  minimap mesh. The Anomaly Device uses the `1.20` silhouette scale.
- Electric Field displays its complete selected damage radius of 120, 140, or
  160 world units as one ground-attached arc-purple area below actors. The area
  uses a restrained fill and at most two broad low-contrast internal planes. It
  has no perimeter, is not a shield, and owns no collision or damage query. Gameplay
  retains the 0.25-second tick, line-of-sight rule, and enemy-body overlap test.
- Every displayed area effect contains a continuous low-alpha body from its
  center through its exact gameplay boundary. A perimeter or authored impact
  may reinforce identity but is never the only range representation. An area
  that resolves in one simulation step appears at full extent on that frame and
  only fades; it does not grow outward after recipients were already resolved.
  Presentation consumes gameplay-owned centers, shapes, radii, phases, and
  timing and never performs collision or damage queries.
- The exact area presentation contract is:
  - Electric Field follows the player for its complete active interval at radius
    `120/140/160` with a full arc-purple disk and at most two low-contrast internal
    planes, all clipped inside the live damage radius and with no perimeter.
  - EMP charge follows the player and previews a full inner `285` damage/stun disk
    plus a sparse segmented `285–325` hostile-projectile-clear utility fringe. On
    release, both resolve immediately at the release position and appear at final
    size for the `0.55 s` fade. Neither standard nor reduced motion uses an
    outward-moving damage front or shape-only image accent.
  - Thermal Burst shows a full radius `72/84/96` disk from its direct-hit center.
    Drop Mine shows a full radius `96/108/120` disk at the mine origin. Explosive
    Seeker shows its full `95` radius at the impact point. Each complete footprint
    uses one synchronized `0.18 s` attack/hold/fade envelope with no independently
    shrinking or disappearing middle shape.
  - Mystery Projectile Purge shows its full `420` hostile-projectile-clear disk
    immediately at the device position; its single boundary may remain as an
    accent.
  - Mystery Gravity Pull, Cryo Lock, and Decoy Signal keep full disks at their
    exact respective radii `480`, `360`, and `900` for their complete active
    durations; their single boundaries remain accents.
  - Black Hole, Shockwave, and Cross Beam use retained code-native disks, rings,
    and beam corridors from gameplay-owned active-weapon snapshots. They add no
    raster asset, per-target node, or collision query to presentation.
  - Every boss circular damaging startup/window fills the complete committed
    radius with a restrained thermal body plus its single outer boundary. Beam
    startup and active continue to fill their exact clipped damage rectangle.
- Protection, damage, and support keep distinct geometry. A shield is one closed
  boundary attached to the protected body. A laser or beam is a filled damage
  corridor. Repair Tender healing is a segmented source-to-recipient mint link
  with an open recipient chevron; it is neither a solid damage beam nor a closed
  shield ring.
- Pause and settings expose a `?` entry to the guidebook. The guidebook has ship,
  enemies, bosses, and field objects categories. Enemies contains every non-boss
  hostile actor, including stationary installations and elite modifiers. Field
  Objects contains interaction, traversal, direct reward objects, and the Anomaly
  Device.
- The current ship page shows derived stats and equipped secondaries. Encountered
  enemy and boss entries show ordered combat statistics derived from gameplay
  owners, not duplicated movement/attack/counter prose. An active run shows exact
  effective values for its current stage; outside a run ordinary enemies show an
  explicit Stage 1–5 range. Encountered entries persist across runs and reuse the
  same combat previews for identification. Each category summarizes undiscovered
  content with one non-selectable count; it never creates selectable `???` entries
  or leaks a name, preview, or statistic. The existing `mystery_device` mechanic is
  displayed as Anomaly Device / 변칙 장치. Guidebook navigation uses one 48-pixel
  left-arrow command with a localized accessible name, tooltip, and input hint.
- Settings places read-only Ship Status first. During a paused run it shows
  effective movement, defense, primary, equipped active weapon, secondary, level, and
  acquired-upgrade values from one frozen gameplay-owned snapshot. Outside a
  run it shows one localized empty state.
- Stage 1–4 success history is retained for later inspection but does not open a
  modal report. Stage 5 result lists actual defeat counts and effective outgoing
  damage by stable source, plus a second partition by kinetic, thermal, toxin,
  cryo, or arc attribute. Both outgoing totals agree within 0.01. A failed
  attempt opens the report in failure mode with the last hit and the three
  largest incoming sources, then returns directly to Deployment. The final result
  and Pause abort action also return directly to Deployment.
- Deployment, upgrade, pause/settings, guidebook, result, and report are modal
  focus layers. They block carried input and provide deterministic keyboard focus.
- One upgrade offer contains one to three unique compatible card IDs. The
  deterministic first pass prefers distinct categories, then fills from the
  same legal pool; it never duplicates or fabricates a fallback. Each newly opened reward
  transaction advances a run-scoped constrained draw, while the cards remain
  frozen for that transaction until the player selects one and confirms Equip;
  UI refreshes never reroll an open offer. The runtime rejects an unoffered,
  stale, or double-submitted ID without mutating the build. An opened reward
  transaction has no Leave, Exit, Skip, or decline action. If no legal ID remains,
  the explicit `MAX` progression-complete receipt resolves the transaction and
  cannot block Stage 5 completion. A zero-card offer while a compatible definition
  remains is an invariant failure and never resolves silently.
- From Stage 3 onward, every offer includes at least one compatible unfinished
  attack card when one exists. This guarantee preserves all optional-secondary,
  element, unique-ID, and frozen-transaction rules.
- The upgrade modal starts directly with a frozen current-build rail on the left
  and one to three visible offer rows on the right. It has no separate kicker,
  screen title, or instruction header. Every offer shows its real current
  and next level; cards backed by numeric stat modifiers also show the real
  current-to-next stat value. A first element acquisition shows its initial
  values without a false zero-to-value comparison; later levels show the real
  current-to-next values.
- Each offer row follows one horizontal information order: semantic artwork;
  category, upgrade name, one short summary, and one or two real effect rows;
  then `Lv.current → next`. Korean summaries target
  roughly ten characters and English summaries use two to five words. Visible
  change-kind text remains omitted while unlock/enhance meaning stays in its
  accessibility name. The row uses
  one shared artwork identity per mechanic group; UI code does not draw
  mechanic-specific glyph geometry.
- Upgrade offers never scroll independently. At 200% text scale only, the offer
  body may provide one outer vertical scroll while all visible rows remain
  non-scrolling and the Equip action remains fixed.
- Deployment presents the craft, one short primary-weapon explanation, complete
  control information, and one Deploy primary action. Settings is a localized,
  accessible icon in the top-right header. Field flavor, build philosophy, and
  other meta commentary are not shown. Every deployment starts the fixed Hard
  run and exposes no difficulty choice.
- Player-facing stage titles use only Stage 1 through Stage 5. Field and encounter
  identifiers remain internal until a later naming decision changes that contract.
- Pause provides Resume and Abort Run only. Guidebook and Settings are localized,
  accessible header icons.

### Runtime capacity and performance

- Runtime capacity is fixed at 320 live hostile actors, 240 player projectiles,
  120 hostile projectiles with 24 slots reserved for bosses, 192 experience
  shards, and 96 repeated effects. Content may use less but may not silently
  raise a cap. Dynamic enemy spatial queries cover every live slot through 320;
  no subsystem may impose a smaller hidden tracking ceiling.
- Allocation is bounded and observable. A full pool rejects or applies its
  documented eviction policy; it never grows during combat. Ordinary hostile
  fire cannot consume the boss reserve.
- Player intent, damage, committed attacks, boss behavior, and their visible
  combat windows remain 60 Hz. Ordinary decisions run at 10 Hz;
  non-committed ordinary motion runs at 30 Hz near the player and 20 Hz beyond
  820 pixels; far projectile integration, dynamic-grid refresh, experience
  movement, and repeated effects run at 30 Hz with accumulated delta.
- Every future mechanic declares its maximum live instances, update cadence,
  spatial-query path, presentation batch, retirement rule, and deterministic
  performance-scenario coverage before increasing runtime load.
- Static minimap geometry and each bounded dynamic tactical snapshot use one
  vertex-colored mesh surface. At most three Anomaly Devices reuse retained
  world batches and create no per-actor canvas draws or per-field scene nodes.
- Combat presentation coalesces mobile enemies, bosses,
  hostile affinity trails, and experience into descriptor-backed retained
  batches. The hard ceiling remains 50 combat batches.
- Dynamic enemy broadphase uses stable runtime slots, reuse generations and
  incremental membership updates. Ordered projectile traversal stops a
  non-piercing shot after its first contact; reusable query, support-assignment,
  inner-wall-hit and presentation buffers avoid per-frame full-grid rebuilds and
  high-count temporary allocations.
- Only rendered native/Web scenarios and the complete lifecycle soak can
  establish release performance. Headless subsystem microbenchmarks and short
  focused samples are diagnostic only. Current acceptance and known failures
  are recorded in `.agents/semantic-v2-runtime-acceptance-evidence.md`.

## Acceptance Criteria

- All three immutable macro fields, the 560-pixel start clearance, both actor
  radii, five deterministic tactical children, exact-retry identity, and
  adjacent-stage variation pass validation.
- The first cue/scout timing, stage quotas, distributed eight-squad surge
  growth, arrival fairness, continued ordinary spawning, 1.5-second boss warning, roaming boss,
  preserved build/exploration, automatic stages 1–4 transition, and stage 5
  result pass focused tests.
- Fixed Hard preserves the previous baseline factors, every run uses that same
  profile, and no UI or saved preference can change difficulty.
- The exact 28-card and 92-state catalog loads, Pickup Radius retains the former
  Pickup Magnet card's three values, baseline Lifesteal restores `0.5%`, the
  Lifesteal card raises the total rate to `2%`/`3.5%`, six secondary weapon
  types and four active weapon types load, no more than three secondary families
  are active, and their bounded simulations pass tests.
- Accepted-hit, barrier-only, reduced-motion, projectile-size, effective-speed,
  default-inner-wall collision, explicit wall-piercing, separate projectile roles,
  doubled hostile-projectile presentation thickness, structural-only health
  bars, Beam Sentinel startup/active corridors, status-stack, two-slot attribute
  exclusivity, and XP-cadence contracts pass focused tests.
- Held primary fire uses one uniform shot contract, reaches the complete
  unobstructed visible field, hits the enlarged visible enemy target through
  swept collision at full horde capacity, stops at the first target unless
  explicitly pierced, chips structures through repeated hits, and gains no
  alternate first round after release.
- Guide discovery persists, locked content appears only as a non-selectable count,
  settings and pause both reach the guide, and Korean/English copy is complete.
- Godot import, all focused validators, native boot, Web export, and rendered
  review at supported sizes succeed. Release performance is governed by the
  complete native/Web frame-pacing, capacity, draw-call, and lifecycle gates;
  the legacy headless pressure microbenchmark and a successful export alone are
  diagnostic only and cannot establish smooth play.

## Non-Goals

- A different physical map for each stage.
- Mandatory extermination of every living enemy.
- Boss rooms, boss gates, ropes, jumping, stacked navigation, or platforming.
- Ammo limits or a charge gate on ordinary held primary fire.
- More than three simultaneous secondary families.
- Unconstrained procedural topology, per-stage layout rerolls, a chore-filled
  base, or exploration puzzles in this run.
- Growth systems beyond the current 28-card catalog, six secondary weapon types,
  and four active weapon types require an explicit product-spec revision.
- A selectable, adaptive, or meta-progression difficulty model is inactive and
  requires an explicit product-spec revision.
- Additional map-generation systems, coordinated-enemy tactics, or new boss
  pattern families require both an explicit product-spec revision and a
  separate ExecPlan before implementation.
- A named cultural, marine, ritual, or material motif is not part of the current
  product identity.
