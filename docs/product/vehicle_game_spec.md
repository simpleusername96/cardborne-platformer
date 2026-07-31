---
type: spec
status: active
owner: BK
created: 2026-07-21
last_reviewed: 2026-07-31
canonical_for: Cardborne gameplay and product behavior
scope: Current run-selected-field five-stage vehicle campaign
related:
  - ../design/UI_VISUAL_SYSTEM.md
  - ../../.agents/vehicle-performance-architecture-audit.md
  - ../../.agents/vehicle-performance-stabilization-evidence.md
  - ../../.agents/execplans/2026-07-29-horde-foundation-recovery-and-acceptance.md
  - ../../.agents/continuous-horde-readability-evidence.md
  - ../../.agents/continuous-horde-rollout-problem-analysis.md
  - ../../.agents/semantic-v2-runtime-acceptance-evidence.md
---

# Cardborne Vehicle Game Specification

## Purpose

Cardborne is a top-down vehicle action shooter about steering through one large
run-selected field while manually aiming a held primary weapon, dashing through
pressure, and building a compact set of automatic secondary weapons. A new run
selects one of three registered macro fields plus five deterministic
stage-tactical arrangements of large internal cover and content sockets. All
five combat stages reuse that field's floor and boundary while each stage
activates its own validated cover, stationary threats, items, crates, and
support sockets.

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
- Korean is the default locale. Korean and English, audio, reduced motion, input,
  and the preferred next-run difficulty persist.

### Fixed run difficulty

- Deployment exposes exactly three run difficulties: Easy, Normal, and Hard.
  Hard is the default and reproduces the combat balance that existed before this
  selector.
- Confirming deployment snapshots the selected difficulty for the complete
  five-stage run. Stage transitions and stage restarts preserve that snapshot.
  Pause/settings has no difficulty control, and another run always returns to
  deployment before combat begins.
- The saved value is only the preference shown on the next deployment. Changing
  saved settings cannot mutate an active run.
- Run difficulty composes with the shallow stage curve. It does not alter attack
  cadence, telegraph duration, hostile projectile speed, threat budgets, drops,
  experience value, or reward quality.

| Mode | Quota | Active cap | Ordinary health | Boss health | Damage | Movement speed | Approximate simultaneous pressure |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Easy | 0.81 | 0.8836 | 0.9216 | 0.81 | 0.9216 | 0.9604 | 0.72 |
| Normal | 0.90 | 0.94 | 0.96 | 0.90 | 0.96 | 0.98 | 0.85 |
| Hard | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 |

The factors are deliberately distributed. Normal is approximately 15% below
Hard in combined simultaneous pressure, and Easy applies the same reduction a
second time; no individual stat is described as exactly 15% lower.

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
- Every projectile stops at the same static or run-selected cover that blocks
  the ship. A live crate also blocks line of sight and both projectile teams;
  hostile fire is absorbed without destroying the reward crate, while player
  fire can break it. `wall_piercing` is an explicit projectile capability whose
  default is false. No current ordinary enemy, boss pattern, primary shot, or
  secondary shot receives that capability implicitly.
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
- Functional-terrain footprints are mutually disjoint and remain outside the
  player-start clearance. The generator treats their exact rectangles or effect
  radii as reserved space for random cover, stationary threats, crates, field
  items, ordinary spawn anchors, and boss arrival anchors.
- The center has a 560-pixel safe clearance. The camera remains at zoom 1, so the
  field is larger than one screen and exploration state matters.
- At least twenty broad walkable regions define each immutable floor. A run
  selects eight large cover candidates from twenty-four candidates spread
  across six sectors. The selected cover is validated for the ordinary
  36-pixel and boss 76-pixel actor radii before play.
- Rendering, movement, projectile collision, line of sight, pursuit, minimap,
  and validation consume the same active tactical layout. Exact retries
  reproduce it, and the selected cover geometry remains fixed through all five
  stages so a run reads as one continuous field rather than five reset maps.
- Thirty-two ordinary arrival candidates, twelve boss arrival anchors, six
  stationary candidate groups, and at least thirty-two item sockets are
  reusable authored positions. Each stage selects four stationary threats, six pickups, and
  eight crates from valid sockets. No stage owns a separate map, boss room,
  closed progression gate, switch maze, or reflector puzzle.
- Pickup contact uses the swept player path with the 24-pixel player radius and
  42-pixel pickup body. Endpoint contact, tangent contact, and a complete dash
  pass collect an active repair or recall exactly once; a path 0.1 pixels
  outside the combined 66-pixel radius misses.
- Capture, validation, and performance paths accept `--layout-seed=<integer>`
  and `--field-id=<id>`; their default layout seed is `0xC4A2B0`, and
  debug/performance snapshots expose the selected field, seed, and fingerprint.
- The explored minimap uses a 20x12 grid. Unvisited geometry remains concealed,
  while player facing, moving-enemy clusters, stationary threats, elites, boss
  state, live pickups, unopened crates, and scheduled support fields remain
  visible as tactical markers.

### Functional terrain, facilities, and sustained fire

- Every field authors Arc Surge Strips, two paired Transit Gate routes, and
  persistent Breakable Bulkheads. Every stage schedules two repair fields and
  two overdrive fields from validated tactical sockets.
- Arc Surge uses a continuous warning, hits
  each actor at most once per active window, can damage either team, and keeps
  stable damage attribution.
- Transit Gates require a dwell, preserve aim, clear velocity, share a
  ten-second pair cooldown, and move only the player. Both repair fields share
  a 24-hull stage budget and pause after accepted damage. Overdrive applies a
  non-stacking 1.20x player-damage multiplier only while the ship center
  remains inside an active field. The four independent schedules use different
  active/dormant durations and space relocation grants by at least three seconds.
- Primary rounds apply the same per-shot structure damage at every point in the
  firing cadence. At base values, four 18-damage hits destroy a full-health
  Breakable Bulkhead, Bulkhead Guard plate, or armored-elite shell; structure
  upgrades change that repeated-hit result without introducing a special shot.
- Ordinary primary damage never cancels an enemy or boss startup and never
  creates a separate exposure state. EMP stun remains the dedicated crowd
  control behavior. Boss direct attacks are committed once warned, while
  autonomous systems continue independently.

### Encounter and stage flow

1. Stage 1 deployment begins at the shared center. Stages 2–5 begin at the
   player's current position and facing without reopening deployment.
2. Stage 1 keeps its initial arrival cadence. After a successful Stage 1–4 transition,
   the next arrival cue begins after 0.35 seconds and the first hostile arrival
   begins within 1.35 seconds.
3. Main-combat packets use deterministic multi-sector allocation. Every surge
   occupies at least four of eight sectors and all four player-relative
   quadrants before a sector is reused. Local squads still form readable packs,
   but no surge is supplied by one wall, wedge, or two fixed fronts. Due
   enemies enter in bounded bursts of at most four per physics tick so a large
   scheduled packet fills the battlefield instead of remaining mostly queued.
   Recent-sector occupancy prevents repeated replenishment from the same side.
   Projectile-firing mobile roles remain at or below 15% of authored mobile
   population; only three ranged attackers and two denial attackers may commit
   at once. Ordinary hostile fire cannot consume the 24-shot boss reserve.
   Hard active ordinary caps progress through `1/124/172/224/276`; Normal and
   Easy scale those caps through the existing difficulty profile. Excess
   enemies remain in the deterministic scheduler queue and are replenished
   toward the current beat target without increasing individual enemy speed,
   health, damage, telegraph speed, or projectile speed.
4. Every mobile enemy joins a shared low-frequency pursuit field and can route
   around cover toward the player. Stationary roles hold authored anchors.
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
   difficulty, exploration, cover, and persistent terrain state, and show a
   non-modal 1.6-second stage banner while the next encounter begins. No success
   report or continue input interrupts the run. Stage 5 opens the final result;
   failures still open the failure report.

| Stage | Hard quota | Normal quota | Easy quota | Authored mobile population | Boss |
| ---: | ---: | ---: | ---: | ---: | --- |
| 1 | 125 | 113 | 101 | 520 | Foundry Colossus |
| 2 | 166 | 149 | 134 | 660 | Archive Leviathan |
| 3 | 208 | 187 | 168 | 816 | Drydock Titan |
| 4 | 250 | 225 | 203 | 1026 | Switchyard Behemoth |
| 5 | 291 | 262 | 236 | 1260 | Crown Engine |

Four stationary threats are added per stage. Ordinary hostile projectiles stop
at 96 so 24 of the global 120-shot cap remain reserved for boss attacks. Enemy
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
- The ship always has Seeker support. Up to two additional optional secondary
  families may be active, for three total:

| Secondary | Combat role |
| --- | --- |
| Seeker | Periodic targeted projectile |
| Ion Field | Damage over time near the ship |
| Orbit Blades | Close orbiting contact damage |
| Wake Mines | Timed mines dropped behind movement |
| Escort Drone | Following drone with periodic targeted fire |

### UI, guidebook, and persistence

- Every player-facing world, actor, projectile, reward, effect, HUD, modal,
  minimap, and preview uses the shared non-raster general-SF component system
  defined by `UI_VISUAL_SYSTEM.md`. Role color is always paired with a
  silhouette, notch, rail, or glyph cue.
- The ship engine remains a rigid rear child of the continuously rotated hull.
  Dash feedback uses a directional afterimage and engine flare, never a danger
  ring or radial burst.
- The live HUD prioritizes hull/experience, stage quota, dash, EMP, active
  secondary families, minimap, boss health, and exceptional timed effects. Its
  154x34 icon-only action rail sits below hull/experience; no bottom-center dock
  covers the field.
- Pause and settings expose a `?` entry to the guidebook. The guidebook has ship,
  mobile enemies, stationary enemies, bosses, and objects categories.
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
  environmental Arc Surge is excluded. A failed attempt opens the report in
  failure mode with the last hit and the three largest incoming sources before
  Garage.
- Deployment, upgrade, pause/settings, guidebook, result, and garage are modal
  focus layers. They block carried input and provide deterministic keyboard focus.
- One upgrade offer contains at most one instance of each card ID. Selection
  diversity rules may prefer families or unlocked branches but never duplicate
  a card within the same three-card choice. Each newly opened reward
  transaction advances a run-scoped constrained draw, while the cards remain
  frozen for that transaction until the player confirms or declines it; UI
  refreshes never reroll an open offer.
  Deployment includes three clearly selected, keyboard-focusable difficulty
  choices with concise Korean and English pressure descriptions.

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
  vertex-colored mesh surface. Scheduled support fields reuse retained world
  batches and one shared eight-segment timer batch; neither system creates
  per-actor canvas draws or per-field scene nodes.
- Combat presentation coalesces mobile enemies, stationary enemies, bosses,
  hostile affinity trails, and experience into descriptor-backed retained
  batches. The hard ceiling remains 50 combat batches.
- Dynamic enemy broadphase uses stable runtime slots, reuse generations and
  incremental membership updates. Ordered projectile traversal stops a
  non-piercing shot after its first contact; reusable query, support-assignment,
  cover-hit and presentation buffers avoid per-frame full-grid rebuilds and
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
- Hard preserves the previous baseline, Normal and Easy use the specified profile
  factors, the active run keeps its deployment snapshot, and no pause/settings
  control can change difficulty.
- Tuned Thrusters has the exact three values, the five secondary families load,
  no more than three are active, and their bounded simulations pass tests.
- Accepted-hit, barrier-only, reduced-motion, projectile-size, effective-speed,
  default-cover collision, explicit wall-piercing, projectile-role share,
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
