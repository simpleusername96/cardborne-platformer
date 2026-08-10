---
type: spec
status: active
owner: BK
created: 2026-07-21
last_reviewed: 2026-08-09
canonical_for: Cardborne gameplay and product behavior
scope: Current run-selected-field five-stage vehicle campaign
related:
  - ../design/VISUAL_SYSTEM.md
  - ./vehicle_upgrade_catalog.md
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
stage scatters its own three mystery devices, six
loose pickups, and eight reward crates.

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
- Primary fire, dash, and EMP are rebindable. Conflicting bindings are rejected.
- Korean is the default locale. Korean and English, audio, reduced motion, and
  input settings persist.

### Fixed Hard run difficulty

- Every run uses the existing Hard combat profile. Deployment exposes no
  difficulty selector, description, lock explanation, or saved preference.
- Confirming deployment starts the complete five-stage run with that fixed
  profile. Stage transitions and stage restarts preserve it internally.
- The fixed profile composes with the shallow stage curve. It does not alter
  attack cadence, telegraph duration, hostile projectile speed, threat budgets,
  drops, experience value, or reward quality.

| Mode | Quota | Active cap | Ordinary health | Boss health | Damage | Movement speed | Approximate simultaneous pressure |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Hard | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 |

All non-boss enemy archetypes receive a final `2.60` health multiplier after the
fixed profile and stage curve. The five ordinary health curve values are
`[0.85, 1.00, 1.15, 1.30, 1.45]`. Boss health receives a separate final `2.60`
multiplier on its authored curve.
Ordinary enemy-sourced damage applies the shared `1.755` multiplier, followed
by the stage curve `[1.00, 1.03, 1.06, 1.09, 1.12]`. These compose to
`1.755/1.80765/1.8603/1.91295/1.9656`. Boss `final-effective` attacks and
friendly or environmental damage bypass this ordinary multiplier exactly as
before.
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
  area radius. Projectile and beam corridors stop at the same current wall or
  live crate as collision. From the first visible startup frame, damaging boss
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
  the ship. A live crate also blocks line of sight and both projectile teams;
  hostile fire is absorbed without destroying the reward crate, while player
  fire can break it. `wall_piercing` is an explicit projectile capability whose
  default is false. No current ordinary enemy, boss pattern, primary shot, or
  secondary shot receives that capability implicitly.
- An intact Mystery Device blocks actors and player projectiles. Hostile
  projectiles pass through it and enemy AI never targets it, so a neutral
  interaction cannot become an unintended shield against enemy fire.
- The unmodified Pulse Cannon has an authored 1600-pixel range. At runtime its
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
  rectangles or effect radii as reserved space for stage devices, crates,
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
  stage selects three Mystery Devices, six pickups, and eight crates with
  explicit separation. Crates are never attached to one another or relocated
  into guarded reward enclosures. No stage owns a separate map, boss room,
  closed progression gate, switch maze, or reflector puzzle.
- Pickup contact uses the swept player path with the 24-pixel player radius and
  42-pixel pickup body. Endpoint contact, tangent contact, and a complete dash
  pass collect an active repair or recall exactly once; a path 0.1 pixels
  outside the combined 66-pixel radius misses.
- Capture, validation, and performance paths accept `--layout-seed=<integer>`
  and `--field-id=<id>`; their default layout seed is `0xC4A2B0`, and
  debug/performance snapshots expose the selected field, seed, and fingerprint.
- The explored minimap uses a 20x12 grid. Unvisited geometry remains concealed.
  Dynamic markers expose exactly eight tactical roles: player craft, field
  pickup, reward crate, intact Mystery Device, mobile enemy, priority enemy,
  boss, and reinforcement facility. The pickup marker is `12 x 7.6`, the
  notched crate marker is `9 x 9`, and their perceived polygon areas differ by
  no more than ten percent. The Mystery Device silhouette scales every outer
  point by `1.20`. Elite distinctions, stage-specific boss identity, and the
  Mystery outcome are not separate minimap markers.

### Inner walls, Transit Gates, and Mystery Devices

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
- Every stage places exactly three Mystery Devices. Each is a neutral 192-pixel
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
   pursuit, `6/s` for standoff, and `5/s` for escort/support. Shared route
   guidance is used only for an approach intent whose direct path is blocked;
   it never pulls a holding, strafing, or retreating role back toward the player.
   Attack timing and distance contracts remain unchanged, and
   logical squad anchors and centroid cohesion do not steer ordinary movement.
   Bounded local separation runs only during actual body overlap, checks at
   most eight nearby actors within 120 pixels, blends role/separation velocity
   at 0.55/0.45, and never exceeds the role's original speed. With no overlap,
   separation leaves the smoothed role velocity unchanged. Inner-wall recovery and committed
   attack paths take priority. High density near the player is an allowed
   convergence result. Stationary roles hold authored anchors.
5. Ordinary defeats advance the stage quota. Living enemies never block travel
   or stage completion and summons do not count toward the quota.
   At 35% quota progress, one separate reinforcement facility activates at a
   clear distant anchor. It is not an enemy actor and does not count toward the
   quota. While alive it spawns an existing stage-scaled role every `8/7/6/5/4`
   seconds, respects both the global active cap and a per-facility live-child cap
   of `2/3/4/5/6`, and resets its interval after every accepted spawn. A full
   child or global cap holds a completed interval at zero; freeing either slot
   permits the pending spawn immediately. The facility can repeat this cycle for
   its complete active lifetime and stops permanently when destroyed, retired,
   or the stage completes. Only living summoned actors whose `carrier_id` is
   `reinforcement_facility` count against its child cap.
6. On reaching the quota, ordinary spawning stops and a 1.5-second boss warning
   identifies a reachable arrival anchor at least 1200 pixels from the player
   when the field permits it. Boss creation and boss-defeat completion reject
   calls unless the quota has been reached and the warning has resolved.
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
8. Boss defeat recalls all live experience within 0.65 seconds and resolves the
   mandatory reward choice. Stages 1–4 then full-heal the ship, grant 1.2
   seconds of transition protection, preserve position, facing, aim, build,
   fixed Hard state, exploration, inner walls, and hazard geometry while the next
   encounter begins. No transition banner, success report, or continue input
   interrupts the run. Stage 5 opens the final result;
   failures still open the failure report.

| Stage | Fixed Hard quota | Authored mobile population | Boss |
| ---: | ---: | ---: | --- |
| 1 | 125 | 520 | Foundry Colossus |
| 2 | 166 | 660 | Archive Leviathan |
| 3 | 208 | 816 | Drydock Titan |
| 4 | 250 | 1026 | Switchyard Behemoth |
| 5 | 291 | 1260 | Crown Engine |

The reinforcement facility is the only map-spawned stationary hostile facility;
it is managed outside the enemy actor store and appears as a dedicated minimap
objective. Ordinary hostile projectiles
stop at 96 so 24 of the global 120-shot cap remain reserved for boss attacks. Enemy
health, damage, and movement rise only on a shallow stage curve; boss behavior
changes through authored patterns rather than unchecked stat inflation. Each
boss uses a distinct three-phase direct-pattern sequence plus independently
scheduled autonomous pressure. Every damaging pattern has a visible startup,
active window, and recovery. Routine hits never interrupt or stop the boss, and
every direct pattern remains committed after its warning appears.

Each boss owns one body-attached shield and no external objective actor.
`shield_up` applies `0.15×` damage. Completing a direct boss attack lowers the
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
  recall pulls all live shards toward the player. Breakable crates contain one
  of those two items. Recall retargets the ship's current position every physics
  frame and guarantees all live shards reach it before the 0.65-second recall
  window expires, including while the ship dashes.
- Each stage places six loose field items and eight breakable crates. Four loose
  repairs restore `50 HP`; five crate repairs restore `50 HP` and one restores
  `40 HP`, for an exact `490 HP` field-repair budget. Repair collection still
  clamps at the ship's current maximum hull.
- Level thresholds use
  `min(160, 12 + round(3n + 0.55n²))`, where `n` is the zero-based level
  progression index. This makes early choices frequent while restoring a rising
  late-run requirement. Each level and boss reward opens a guarded selection
  of every legal offer card up to three and requires an explicit choice and
  confirm. When no compatible upgrade remains, one localized completion receipt
  marks XP as `MAX`, clears queued levels and live shards, and suppresses future
  shard spawning and XP awards for that run.
- The live catalog is the 13-card, 36-level-state contract in
  `vehicle_upgrade_catalog.md`. It uses four player-facing categories: Primary
  Weapon Mods, Secondary Weapon Systems, Attack Status Effects, and Chassis &
  Support. Category is separate from change kind and optional weapon-slot
  ownership. Dash and EMP remain base actions but have no upgrade cards.
- A first acquisition is an `unlock` only when it creates a previously absent
  behavior: Split Muzzle, Piercing Rounds, an optional secondary, or an element.
  Homing Missiles is an `enhance` offer from its first card because Seeker starts
  equipped; all later behavior-card levels are enhancements. Change kind remains
  in the frozen offer and localized accessibility name, not visible card chrome.
- Every legal card state publishes one or two gameplay-owned effect rows. The
  six behavior-card sequences are: Split Muzzle `1->2->3` projectiles per volley
  and `100%->140%->165%` total volley damage; Piercing Rounds `0->1->2->3`
  additional penetrations; Homing Missiles `1->2->3` missiles and `25->28->32`
  damage per missile; Electric Field `8->12->16` DPS and `120->140->160` radius;
  Orbiting Blades `2->3->4` blades and `14->18->22` damage per blade; Drop Mines
  `48->60->72` damage and `3.2->2.8->2.4 s` deployment interval. Optional-secondary
  and element unlocks show their acquired values without a false zero comparison.
- `Movement Speed`, `Pickup Radius`, `Hull Integrity`, and `Lifesteal` are the
  complete Chassis & Support category. Pickup Radius preserves the former
  Pickup Magnet card's three-level collection effect. Every run starts with
  `0.5%` Lifesteal. The Lifesteal card raises the total rate to `2%`/`3.5%`.
  Recovery uses actual player-owned enemy damage, has a six-Hull capacity that
  replenishes at six Hull per second, and never exceeds maximum Hull.
- Thermal Burst, Bio Toxin, and Cryo Slow are mutually exclusive complete packages.
  The first selected root locks the other two out of future offers, and only that
  root's later levels remain eligible. Its affinity changes player-primary projectile
  color. The selected condition accumulates bounded stacks and Korean/English
  target text exposes its count. There are no intermediate element branch cards.
  Their card values and runtime payload share one build-owned source: Thermal
  radius is `72/84/96` with burst damage `4/6/8`; Toxin damage per stack is
  `2/3/4` with `5/6/7s` duration; Cryo slow per stack is `6/8/10%` with
  `2/2.5/3s` duration. Boss Chill retains its existing half-effect rule.
- **Secondary Weapons** is the umbrella category for four automatic weapon
  types. **Seeker** is its always-equipped built-in subtype; up to two of the
  other three optional subtypes may be active,
  for three total. Data expresses this with `secondary_slot_kind` values
  `built_in` and `optional`; offer eligibility counts only owned optional
  definitions and never infers slot ownership from a card ID. Seeker remains
  inside this umbrella category and does not consume an optional slot:

| Secondary | Combat role |
| --- | --- |
| Homing Missiles | Periodic targeted projectiles; upgrades increase count and damage |
| Electric Field | Damage over time near the ship |
| Orbiting Blades | Close orbiting contact damage |
| Drop Mines | Timed mines dropped behind movement |

Drop Mine is distinct from Thermal Burst. At levels 1–3 it applies one
`48/60/72` area hit at radius `96/108/120` after proximity or timeout, then
publishes one origin receipt only after damage resolution. Its cosmetic has a
`0.18 s` lifetime and an eight-instance subcap inside the unchanged 96-effect
store. When saturated, it may recycle only another Drop Mine cosmetic; missing
feedback never cancels or duplicates damage.

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
- The fixed-capacity transient effect buffer contains dash afterimage, EMP
  charge/release, the approved Thermal Burst impact receipt, bounded Mystery
  purge pulses, and the separate Drop Mine receipt. It keeps its 96-effect
  ceiling, at most 24 live Thermal impacts, and at most eight live Drop Mine
  receipts; saturated Thermal
  feedback may recycle the oldest Thermal impact or drop the new cosmetic
  receipt but never evicts EMP or changes damage. Toxin and Chill do not create
  effect objects. Existing enemy and boss batches share one status compositor;
  per-instance custom data composes a same-size translucent green or blue layer
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
- The live HUD prioritizes hull, XP, numeric stage progress, EMP,
  minimap, and exceptional timed effects. A panel-free top-left B stack shows only
  localized stage and defeated labels with `current / total` values. At compact,
  standard, and large widths its label/fraction sizes are `15/30`, `16/32`, and
  `18/40 px`; all top zones use an eight-pixel top datum. Top-center uses a long
  panel-free hull strip with an equal-width XP meter below it. Both tracks are
  `400/520/640` wide at compact/standard/large sizes; the amber hull fill is
  13 pixels thick and the blue XP fill is `6/8/8` pixels thick. XP shows `Lv. N`
  and `EXP current / required`, or `EXP MAX` after progression completes. Top-right
  owns only the minimap. Bottom-center owns one enlarged round panel-free EMP indicator. No
  live upgrade icon, edge boss/target health, mission surface, objective text, or
  ornamental full-width dock covers the field.
- The normal top-center toast is `320×36` compact or `360×40` standard/large and
  sits four pixels below the center status stack, independent of the taller B
  stack. Only facility active/destroyed, boss inbound, barrier depleted, Mystery
  Device result, boss shield-down, and progression-complete events may enqueue
  gameplay toasts. Stage
  transitions use no banner.
- Bosses, active reinforcement facilities, and fixed combat installations
  (`turret`, `interceptor_tower`, `beam_sentinel`, and `generator`) own thick,
  backed health bars above their world bodies. Mobile enemies, mines, Mystery
  Devices, and reward crates never receive world health bars. Installation bars
  use a deterministic 12-actor cap. All world health bars share one retained
  batch with a fixed 28-instance ceiling.
- The threat radar samples at five hertz and aggregates contacts into at most 12
  directional sectors around the player. It includes targetable non-boss enemy
  bodies outside the visible world rectangle and within 1,200 world units as dim
  `nearby_enemy` arcs. Scheduler-authored ordinary arrival cues reuse that same
  dim arc during their bounded receipt lifetime; farther cue offsets clamp to the
  1,200-unit boundary. These arcs reveal direction and pressure density, never an
  exact coordinate or triangle. An unseen committed projectile attack has
  priority 3, boss arrival priority 2, and nearby enemy pressure priority 1 when
  contacts share a sector; only the winning role owns that sector's color and
  triangle. A single attack never appears as both a world route and a radar
  contact.
- The minimap publishes exactly eight semantic roles: player, field pickup,
  reward crate, intact Mystery Device, mobile enemy, priority enemy, boss, and
  reinforcement facility. `turret`, `interceptor_tower`, `beam_sentinel`, and
  `generator` are priority enemies; other active non-boss enemies are mobile
  enemies. An intact Mystery Device uses one neutral marker that never leaks its
  hidden result, and resolved or retired devices disappear. Bosses use one
  command-magenta notched marker independent of stage. The reinforcement
  facility keeps its dedicated two-tone diamond. All roles share the existing
  marker capacity, borrowed buffers, explored geometry, fog, and one retained
  minimap mesh. Pickup and crate use the exact size and area relationship
  defined in the field contract above; the Mystery Device uses the `1.20`
  silhouette scale.
- Electric Field displays its complete selected damage radius of 120, 140, or
  160 world units as one ground-attached arc-purple area below actors. The area
  uses a restrained fill, one broken perimeter, and at most four broad internal
  planes; it is not a shield and owns no collision or damage query. Gameplay
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
    `120/140/160` with a full arc-purple disk, internal planes, and one restrained
    perimeter, all clipped inside the live damage radius.
  - EMP charge follows the player and previews a full inner `285` damage/stun disk
    plus a full outer `325` hostile-projectile-clear disk. On release, both
    envelopes resolve immediately at the release position and appear at final
    size for the `0.55 s` fade; the authored octagon is an inner-envelope accent,
    not an outward-moving damage front.
  - Thermal Burst shows a full radius `72/84/96` disk from its direct-hit center;
    the approved impact is a centered accent. Drop Mine shows a full radius
    `96/108/120` disk at the mine origin; its approved detonation is a centered
    accent. Both resolve at final size and only fade during their `0.18 s` life.
  - Mystery Projectile Purge shows its full `420` hostile-projectile-clear disk
    immediately at the device position; its single boundary may remain as an
    accent.
  - Every boss circular damaging startup/window fills the complete committed
    radius with a restrained thermal body plus its single outer boundary. Beam
    startup and active continue to fill their exact clipped damage rectangle.
- Pause and settings expose a `?` entry to the guidebook. The guidebook has ship,
  mobile enemies, bosses, and field objects categories.
- The current ship page shows derived stats and equipped secondaries. Encountered
  entries persist across runs and reuse the same combat meshes for visual
  identification. Unseen entries show only `???` and one neutral silhouette;
  they never leak a name, color, description, or counterplay.
- Settings places read-only Ship Status first. During a paused run it shows
  effective movement, defense, primary, EMP, secondary, level, and
  acquired-upgrade values from one frozen gameplay-owned snapshot. Outside a
  run it shows one localized empty state.
- Stage 1–4 success history is retained for later inspection but does not open a
  modal report. Stage 5 result lists actual defeat counts and effective outgoing
  damage by stable source, plus a second partition by kinetic, thermal, toxin,
  cryo, or arc attribute. Both outgoing totals agree within 0.01. A failed
  attempt opens the report in failure mode with the last hit and the three
  largest incoming sources before Garage.
- Deployment, upgrade, pause/settings, guidebook, result, and garage are modal
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
- The upgrade modal starts directly with its one to three visible cards: it has no separate
  kicker, screen title, or instruction header. Every card shows its real current
  and next level; cards backed by numeric stat modifiers also show the real
  current-to-next stat value. A first element acquisition shows its initial
  values without a false zero-to-value comparison; later levels show the real
  current-to-next values.
- Each card follows one centered vertical information order: category, upgrade
  name, large semantic artwork, `Lv.current → next`, one or two real effect rows,
  then one short localized effect summary. Korean summaries target
  roughly ten characters and English summaries use two to five words. Visible
  change-kind text remains omitted while unlock/enhance meaning stays in its
  accessibility name. The card uses
  one shared artwork identity per mechanic group; UI code does not draw
  mechanic-specific glyph geometry.
- Upgrade cards never scroll independently. At 200% text scale only, the offer
  body may provide one outer vertical scroll while all visible cards remain
  non-scrolling and the Equip action remains fixed.
- Deployment presents loadout and complete control information with one Deploy
  primary action. Deploy, Settings, and the debug-only Boss Practice action share
  one horizontal action row while retaining their primary/secondary roles.
  Every deployment starts the fixed Hard run and exposes no difficulty choice.

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
  vertex-colored mesh surface. At most three Mystery Devices reuse retained
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
  growth, arrival fairness, spawn stop, 1.5-second boss warning, roaming boss,
  preserved build/exploration, automatic stages 1–4 transition, and stage 5
  result pass focused tests.
- Fixed Hard preserves the previous baseline factors, every run uses that same
  profile, and no UI or saved preference can change difficulty.
- The exact 13-card and 36-state catalog loads, Pickup Radius retains the former
  Pickup Magnet card's three values, baseline Lifesteal restores `0.5%`, the
  Lifesteal card raises the total rate to `2%`/`3.5%`, the four secondary weapon
  types load, no more than three are active, and their bounded simulations pass
  tests.
- Accepted-hit, barrier-only, reduced-motion, projectile-size, effective-speed,
  default-inner-wall collision, explicit wall-piercing, separate projectile roles,
  doubled hostile-projectile presentation thickness, structural-only health
  bars, Beam Sentinel startup/active corridors, status-stack, element
  exclusivity, and XP-cadence contracts pass focused tests.
- Held primary fire uses one uniform shot contract, reaches the complete
  unobstructed visible field, hits the enlarged visible enemy target through
  swept collision at full horde capacity, stops at the first target unless
  explicitly pierced, chips structures through repeated hits, and gains no
  alternate first round after release.
- Guide discovery persists, locked entries expose only `???`, settings and pause
  both reach the guide, and Korean/English copy is complete.
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
- Alternative growth systems beyond the current 13-card catalog and four
  secondary weapon types are inactive and require an explicit product-spec revision.
- A selectable, adaptive, or meta-progression difficulty model is inactive and
  requires an explicit product-spec revision.
- Additional map-generation systems, coordinated-enemy tactics, or new boss
  pattern families require both an explicit product-spec revision and a
  separate ExecPlan before implementation.
- A named cultural, marine, ritual, or material motif is not part of the current
  product identity.
