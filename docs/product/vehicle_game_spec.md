---
type: spec
status: active
owner: BK
created: 2026-07-21
last_reviewed: 2026-08-06
canonical_for: Cardborne gameplay and product behavior
scope: Current run-selected-field five-stage vehicle campaign
related:
  - ../design/VISUAL_SYSTEM.md
  - ../../.agents/semantic-v2-runtime-acceptance-evidence.md
---

# Cardborne Vehicle Game Specification

## Purpose

Cardborne is a top-down vehicle action shooter about steering through one large
run-selected field while manually aiming a held primary weapon, dashing through
pressure, and building a compact set of automatic secondary weapons. A new run
selects one of three registered macro fields plus five deterministic
stage-tactical content arrangements. All five combat stages reuse that field's
floor, boundary, five inner-wall groups, four broad hazard zones, and two
Transit Gate routes. Each stage scatters its own three mystery devices, six
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
- Every hostile attack has a startup descriptor produced from simulation
  values. Its `danger footprint` is the exact set of player-center positions
  that can receive damage: projectile radius plus player radius, contact
  colliders plus padding, beam half-width plus player radius, or the authored
  area radius. Swept projectile and charge corridors include their rounded
  endpoint caps. A footprint is rendered whenever it intersects the viewer even
  if its owner is off-screen. Projectile and beam corridors stop at the same
  current wall or live crate as collision. From the first visible startup frame,
  damaging boss attacks hold their warned origin, direction, and target through
  impact; only warning readiness changes.
- Projectile startup shows its muzzle/cadence cue and no more than `0.4`
  seconds of predicted travel; the current contract uses `0.36 s`. Beam is the
  only delivery that warns its full committed corridor. Charge uses its locked
  endpoint capsule, and area/support warnings retain their own exact footprint
  rather than inheriting projectile or beam geometry.
- Boss charge, area, pylon, and damaging summon warnings include their aimed
  three-shot burst as separate corridors. Active beams retain both their
  physical beam body and the expanded player-center danger boundary. Persistent
  damage zones and boss area attacks keep their exact outer boundary visible
  for the complete damaging window. Hostile circular damage falls linearly from
  100% at the center to 45% at that boundary and stops outside it.
- Warning readiness progresses monotonically from a pale, restrained footprint
  to a darker and stronger affinity cue at impact. It never pulses, follows the
  player, or changes the committed damage geometry after appearing.
- `Affinity` is an attack's impact family and controls large color and trail
  shape cues: kinetic, thermal, toxin, cryo, arc, hybrid, or support.
  `Condition` means a real persistent burn, poison, or chill payload. Thermal,
  toxin, or cryo presentation alone never invents a condition. Current hostile
  attacks apply direct damage only; player primary rounds derive affinity from
  their actual stackable condition payload, with multi-condition rounds shown
  as hybrid.
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
- Run-fixed wall, hazard, and gate footprints have no forbidden overlap and
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
- The generator also places exactly four traversable hazard footprints:
  `768x576`, `960x576`, `1152x480`, and `864x672`. A run selects one shared
  hazard presentation, toxic bog or lava pool, while both use the same neutral
  damage rule. The combined footprint is broad ground pressure, not a narrow
  pass-through wall.
- Rendering, movement, projectile collision, line of sight, pursuit, minimap,
  and validation consume the same active tactical layout. Exact retries
  reproduce it, and the inner-wall and hazard geometry remains fixed through all five
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
  Dynamic markers expose only four tactical roles: player craft, item, enemy,
  and boss. All live pickups, unopened crates, and intact Mystery Devices share
  the item marker; all non-boss hostiles share the enemy marker; every boss uses
  the same boss marker. Subtypes, elite distinctions, objective state, hazard
  affinity, and mystery outcome are not separate minimap markers.

### Inner walls, hazard zones, Transit Gates, and Mystery Devices

- An inner wall is run-fixed, impassable structure. It blocks movement,
  projectiles, line of sight, and pursuit through the same tactical geometry.
  It also provides the short attack break previously supplied by independent
  cover, so there is no separate cover category. A wall group may compile to
  two rectangles, but U, C, O, closed-room, and reward-pocket shapes are not
  generated.
- Exactly four hazard zones remain active for the entire run. They have no solid
  collision and enemy AI does not globally avoid or intentionally attack them.
  Entering or remaining inside a zone refreshes one non-stacking environmental
  `field_exposure` to 2.5 seconds. Contact deals an immediate tick; further
  ticks occur every 0.75 seconds, including after exit until exposure expires.
  Tick damage is 5 to the player, 8 to ordinary/elite enemies, and 3 to the
  stage boss.
- Hazard damage is neutral. A hazard kill advances the ordinary quota and drops
  the normal XP shard, but it never invokes player-owned kill effects. The
  toxic-bog or lava-pool label changes affinity and ground presentation only;
  both use the same neutral environment damage source and do not use or stack the player's burn/poison/chill
  payload rules.
- Two paired Transit Gate routes remain fixed through the run. Gates require a
  dwell, preserve aim, clear velocity, share a ten-second pair cooldown, grant
  the existing short transfer protection, and move only the player. They never
  damage actors.
- Every stage places exactly three Mystery Devices. Each is a neutral 192-pixel
  body with an 84-pixel collision/target radius and 90 structure health, equal
  to five unmodified 18-damage primary hits. Player direct and area damage may
  break it; enemy AI and hostile attacks ignore it. It is not an enemy, never
  counts toward quota, and drops no XP or item.
- A stage assigns three different hidden outcomes from `gravity_pull`,
  `cryo_lock`, `projectile_purge`, and `decoy_signal`. Breaking a device reveals
  and applies one outcome. Pull affects non-boss enemies within 480 pixels for
  1.2 seconds. Cryo lock stops non-boss movement and new attack starts within
  360 pixels for 0.8 seconds but does not cancel a committed warned attack.
  Projectile purge retires hostile projectiles within 420 pixels immediately.
  Decoy signal redirects nearby enemy movement/aim toward the wreck within 900
  pixels for 6 seconds without making the wreck an attack target.
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
   final round.
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
   mobile follows its role pursuit/range/support behavior toward the player;
   logical squad anchors and centroid cohesion do not steer ordinary movement.
   Bounded local separation runs only during actual body overlap, checks at
   most eight nearby actors within 120 pixels, blends role/separation velocity
   at 0.55/0.45, and never exceeds the role's original speed. With no overlap,
   role velocity remains bit-for-bit unchanged. Inner-wall recovery and committed
   attack paths take priority. High density near the player is an allowed
   convergence result. Stationary roles hold authored anchors.
5. Ordinary defeats advance the stage quota. Living enemies never block travel
   or stage completion and summons do not count toward the quota.
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
   aimed lane and repeat volleys along it; charge, area, pylon, and damaging
   summon patterns add one aimed three-shot pressure burst. Recovery resumes
   repositioning only after the committed attack ends.
8. Boss defeat recalls all live experience within 0.65 seconds and resolves the
   mandatory reward choice. Stages 1–4 then full-heal the ship, grant 1.2
   seconds of transition protection, preserve position, facing, aim, build,
   fixed Hard state, exploration, inner walls, and hazard geometry, and show a
   non-modal 1.6-second stage banner while the next encounter begins. No success
   report or continue input interrupts the run. Stage 5 opens the final result;
   failures still open the failure report.

| Stage | Fixed Hard quota | Authored mobile population | Boss |
| ---: | ---: | ---: | --- |
| 1 | 125 | 520 | Foundry Colossus |
| 2 | 166 | 660 | Archive Leviathan |
| 3 | 208 | 816 | Drydock Titan |
| 4 | 250 | 1026 | Switchyard Behemoth |
| 5 | 291 | 1260 | Crown Engine |

No map-spawned stationary enemies are added per stage. Ordinary hostile projectiles
stop at 96 so 24 of the global 120-shot cap remain reserved for boss attacks. Enemy
health, damage, and movement rise only on a shallow stage curve; boss behavior
changes through authored patterns rather than unchecked stat inflation. Each
boss uses a distinct three-phase direct-pattern sequence plus independently
scheduled autonomous pressure. Every damaging pattern has a visible startup,
active window, and recovery. Routine hits never interrupt or stop the boss, and
every direct pattern remains committed after its warning appears.

Boss objective state changes damage efficiency rather than creating immunity:
`SEALED` applies `0.20×`, `OPEN` applies `1.55×` for five seconds, and
`STABLE` applies `1.00×`. Objective lock and phase thresholds never clamp
accepted damage to zero. A phase threshold starts the next sequential objective
but is not an HP floor. Inactive sequential modules are neither targetable nor
projectile blockers. The boss strip, objective tracker, world cue, threat radar,
and minimap consume the same active module ID, state, and health. A state-entry
hint appears once and the same hint cannot repeat within two seconds.

### Items, experience, and upgrades

- Enemy defeats leave collectible geometric experience shards. Experience is
  granted only when a shard is collected; summons grant none.
- Exactly two field item behaviors exist: repair restores hull and experience
  recall pulls all live shards toward the player. Breakable crates contain one
  of those two items. Recall retargets the ship's current position every physics
  frame and guarantees all live shards reach it before the 0.65-second recall
  window expires, including while the ship dashes.
- Each stage places six loose field items and eight breakable crates. The larger
  number of item sightings redistributes the existing 245-point field-repair
  budget rather than increasing total recovery without limit.
- Level thresholds use
  `min(160, 12 + round(3n + 0.55n²))`, where `n` is the zero-based level
  progression index. This makes early choices frequent while restoring a rising
  late-run requirement. Each level and boss reward opens a guarded three-card
  selection that requires an explicit choice and confirm.
- `Tuned Thrusters` is the direct movement upgrade and changes base movement to
  1.08x, 1.16x, then 1.24x. There is no recurring movement-speed cycle.
- The live catalog contains 41 upgrades covering primary cadence, count,
  damage, status payloads, dash, EMP, barrier, sustain, pickup reach, and
  automatic secondaries. No upgrade changes the first round after a firing
  pause.
- Fire, poison, and chill roots are independent and may all coexist. Fire and
  chill each use a root → intermediate chain; poison uses a root →
  intermediate → Contagion chain. An owned branch guarantees one eligible
  least-progressed child in a normal level-up offer when available. Burn,
  poison, and chill accumulate bounded stacks rather than replacing or
  consuming one another. Contagion spreads poison to at most eight nearby
  targets in deterministic distance order. World arcs and Korean/English
  target text expose active stack counts.
- **Secondary Weapons** is the sole user-facing upgrade family and the umbrella
  system for five automatic weapon families. **Seeker** is its always-equipped
  built-in subtype; up to two of the other four optional subtypes may be active,
  for three total. Data expresses this with `secondary_slot_kind` values
  `built_in` and `optional`; offer eligibility counts only owned optional
  definitions and never infers slot ownership from a card ID. Seeker remains
  inside this umbrella category and does not consume an optional slot:

| Secondary | Combat role |
| --- | --- |
| Seeker | Periodic targeted projectile |
| Ion Field | Damage over time near the ship |
| Orbit Blades | Close orbiting contact damage |
| Wake Mines | Timed mines dropped behind movement |
| Escort Drone | Following drone with periodic targeted fire |

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
- The live HUD prioritizes hull/experience, stage quota, dash, EMP, active
  secondary families, minimap, boss health, target state, and exceptional timed
  effects. It uses four restrained zones: top-left hull/experience, top-center
  objective and conditional boss state, top-right minimap and conditional
  target, and one compact bottom-center action strip. No ornamental full-width
  dock covers the field.
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
  cryo, or arc attribute. Both outgoing totals agree within 0.01 and
  neutral hazard-zone damage is excluded. A failed attempt opens the report in
  failure mode with the last hit and the three largest incoming sources before
  Garage.
- Deployment, upgrade, pause/settings, guidebook, result, and garage are modal
  focus layers. They block carried input and provide deterministic keyboard focus.
- One upgrade offer contains at most one instance of each card ID. Selection
  diversity rules may prefer families or unlocked branches but never duplicate
  a card within the same three-card choice. Each newly opened reward
  transaction advances a run-scoped constrained draw, while the cards remain
  frozen for that transaction until the player selects one and confirms Equip;
  UI refreshes never reroll an open offer. An opened reward transaction has no
  Leave, Exit, Skip, or decline action.
- The upgrade modal starts directly with the three cards: it has no separate
  kicker, screen title, or instruction header. Every card shows its real current
  and next level; cards backed by numeric stat modifiers also show the real
  current-to-next stat value.
- Each card follows one fixed information order: family, upgrade name, large
  semantic artwork, `Lv.current → next`, up to two real current-to-next values,
  then a concise description. Behavior-only cards use a localized “New behavior”
  row rather than fabricated numbers. The card uses one shared artwork identity
  per mechanic group; UI code does not draw upgrade-specific glyph geometry.
- Upgrade cards never scroll independently. At 200% text scale only, the offer
  body may provide one outer vertical scroll while all three cards remain
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
  vertex-colored mesh surface. Four hazard footprints and at most three Mystery
  Devices reuse retained world batches; neither system creates per-actor canvas
  draws or per-field scene nodes.
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
- Tuned Thrusters has the exact three values, the five secondary families load,
  no more than three are active, and their bounded simulations pass tests.
- Accepted-hit, barrier-only, reduced-motion, projectile-size, effective-speed,
  default-inner-wall collision, explicit wall-piercing, projectile-role share,
  status-stack, elemental-prerequisite, and XP-cadence contracts pass focused
  tests.
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
- Alternative growth systems beyond the current 41-card and five-secondary
  contract are inactive and require an explicit product-spec revision.
- A selectable, adaptive, or meta-progression difficulty model is inactive and
  requires an explicit product-spec revision.
- Additional map-generation systems, coordinated-enemy tactics, or new boss
  pattern families require both an explicit product-spec revision and a
  separate ExecPlan before implementation.
- A named cultural, marine, ritual, or material motif is not part of the current
  product identity.
