---
type: spec
status: active
owner: BK
created: 2026-07-21
last_reviewed: 2026-07-25
canonical_for: Cardborne gameplay and product behavior
scope: Current run-selected-field five-stage vehicle campaign
related:
  - ../design/UI_VISUAL_SYSTEM.md
  - ../../.agents/vehicle-performance-architecture-audit.md
  - ../../.agents/vehicle-performance-stabilization-evidence.md
  - ../../.agents/execplans/2026-07-23-vehicle-performance-architecture-stabilization.md
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

- Primary fire repeats while held. Releasing it for one second primes Breach
  Shot: a larger first-contact projectile with extra structure damage,
  temporary pierce, and explicit interrupt/counterplay rules.
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
  For the first 0.18 seconds the ship uses a coral hit tint and a deterministic
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

### One run-selected field

- A new run deterministically selects `drowned_ruin_field`,
  `tidal_archive_field`, or `storm_drydock_field`. Every stage and retry keeps
  that macro field while each stage resolves one immutable tactical child.
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
  and validation consume the same active stage-tactical layout. Exact retries
  reproduce it; adjacent stages activate a different validated tactical set.
- Thirty-two ordinary arrival candidates, twelve boss arrival anchors, six
  stationary candidate groups, and at least thirty-two item sockets are
  reusable authored positions. Each stage selects four stationary threats, three pickups, and
  five crates from valid sockets. No stage owns a separate map, boss room,
  closed progression gate, switch maze, or reflector puzzle.
- Capture, validation, and performance paths accept `--layout-seed=<integer>`
  and `--field-id=<id>`; their default layout seed is `0xC4A2B0`, and
  debug/performance snapshots expose the selected field, seed, and fingerprint.
- The explored minimap uses a 20x12 grid. Unvisited geometry remains concealed,
  while player facing, moving-enemy clusters, stationary threats, elites, boss
  state, live pickups, unopened crates, and scheduled support fields remain
  visible as tactical markers.

### Functional terrain, facilities, and Breach Shot

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
- A full Breach Shot destroys a full-health Breakable Bulkhead, arms a mine
  with a short fuse, breaks a Bulkhead Guard plate, or cancels an ordinary
  enemy attack only during a metadata-approved startup. Cancellation enters a
  fixed 0.45-second interrupted recovery; Breach never creates idle stun-lock.
- Each boss exposes exactly one nonadjacent signature startup per fight to a
  Breach cancellation. Autonomous systems and already committed attacks remain
  active. Breach otherwise creates a short damage-exposure opportunity during
  a valid natural recovery and never freezes boss locomotion or its pattern
  state.

### Encounter and stage flow

1. Each stage begins at the shared center with no mobile damaging enemy active.
2. The first arrival cue begins at 5.1 seconds and the first scout arrives at
   6.0 seconds.
3. Later arrivals are eight-squad surges. Each squad contains three to five
   enemies, so the first surge schedules at least 24 enemies and later surges
   grow toward 40. Every squad receives its own deterministic valid anchor.
   Arrivals prefer seeded distance lanes at 1200, 1650, or 2100 pixels from the
   player within a valid 900–2400-pixel ring and remain 220 pixels beyond the
   visible world. They avoid the sixteen most recent anchors and use groups
   of at most two squads in beats 0–1 or three squads later. Group gaps are
   0.90 seconds early and 0.65 seconds later. Existing role totals are preserved
   while direct-projectile pressure is distributed between squads.
   Projectile-firing archetypes are capped at 50% of both the authored mobile
   population and the four stationary threats in every stage. A stage already
   below the cap is not inflated to reach it; area, beam, charge, and support
   roles remain separate classifications.
   Hard can sustain 62 active enemies from the first combat beat and reaches 92
   at peak pressure. Normal scales those caps to 58 and 86; Easy scales them to
   55 and 81. The hard peak plus four stationary threats occupies the
   96-ordinary-enemy production budget without spilling into the global
   boss/auxiliary reserve. Excess enemies stay in the deterministic scheduler
   queue. These quotas and caps are approximately 30% above the pre-enlargement
   field values.
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
8. Boss defeat recalls experience, resolves mandatory reward choices, then
   stages 1–4 automatically preserve the build and explored minimap, return the
   ship to the center, and begin the next stage. Stage 5 opens the final result.

| Stage | Hard quota | Normal quota | Easy quota | Authored mobile population | Boss |
| ---: | ---: | ---: | ---: | ---: | --- |
| 1 | 125 | 113 | 101 | 260 | Foundry Colossus |
| 2 | 166 | 149 | 134 | 300 | Archive Leviathan |
| 3 | 208 | 187 | 168 | 340 | Drydock Titan |
| 4 | 250 | 225 | 203 | 380 | Switchyard Behemoth |
| 5 | 291 | 262 | 236 | 420 | Crown Engine |

Four stationary threats are added per stage. Ordinary hostile projectiles stop
at 96 so 24 of the global 120-shot cap remain reserved for boss attacks. Enemy
health, damage, and movement rise only on a shallow stage curve; boss behavior
changes through authored patterns rather than unchecked stat inflation. Each
boss uses a distinct three-phase direct-pattern sequence plus independently
scheduled autonomous pressure. Every damaging pattern has a visible startup,
active window, and recovery. Routine hits never interrupt or stop the boss;
only the one metadata-approved signature startup can be cancelled by a ready
Breach Shot.

### Items, experience, and upgrades

- Enemy defeats leave collectible geometric experience shards. Experience is
  granted only when a shard is collected; summons grant none.
- Exactly two field item behaviors exist: repair restores hull and experience
  recall pulls all live shards toward the player. Breakable crates contain one
  of those two items. Recall retargets the ship's current position every physics
  frame and guarantees all live shards reach it before the 0.65-second recall
  window expires, including while the ship dashes.
- Level thresholds use
  `min(160, 12 + round(3n + 0.55n²))`, where `n` is the zero-based level
  progression index. This makes early choices frequent while restoring a rising
  late-run requirement. Each level and boss reward opens a guarded three-card
  selection that requires an explicit choice and confirm.
- `Tuned Thrusters` is the direct movement upgrade and changes base movement to
  1.08x, 1.16x, then 1.24x. There is no recurring movement-speed cycle.
- Upgrades cover primary cadence, count, damage, opening-shot behavior, status
  payloads, dash, EMP, barrier, sustain, pickup reach, and automatic secondaries.
- Fire, poison, and chill roots are independent and may all coexist. Each uses
  a root → intermediate → capstone chain, and an owned branch guarantees one
  eligible least-progressed child in a normal level-up offer when available.
  Burn, poison, and chill accumulate bounded stacks rather than replacing one
  another. Flashover consumes only burn, Shatter consumes only chill, and
  an eligible opening shot resolves both capstones when both statuses are
  present. Contagion spreads poison to at most eight nearby targets in
  deterministic distance order. World arcs and Korean/English target text
  expose active stack counts.
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

- The live HUD prioritizes hull/experience, stage quota, opening-shot readiness,
  dash, EMP, active secondary families, minimap, boss health, and exceptional
  timed effects. Its 154x34 icon-only action rail sits below hull/experience;
  no bottom-center dock covers the field.
- Pause and settings expose a `?` entry to the guidebook. The guidebook has ship,
  mobile enemies, stationary enemies, bosses, and objects categories.
- The current ship page shows derived stats and equipped secondaries. Encountered
  entries persist across runs and reuse the same combat meshes for visual
  identification. Unseen entries show only `???` and one neutral silhouette;
  they never leak a name, color, description, or counterplay.
- Settings places read-only Ship Status first. During a paused run it shows
  effective movement, defense, primary/Breach, EMP, secondary, level, and
  acquired-upgrade values from one frozen gameplay-owned snapshot. Outside a
  run it shows one localized empty state.
- Confirming a boss reward opens a frozen Stage Report before progression. It
  lists actual defeat counts and effective outgoing damage by stable source,
  plus a second partition by kinetic, thermal, toxin, cryo, or arc attribute.
  Both outgoing totals agree within 0.01 and environmental Arc Surge is
  excluded. A failed attempt opens the same report in failure mode with the
  last hit and the three largest incoming sources before Garage.
- Deployment, upgrade, pause/settings, guidebook, result, and garage are modal
  focus layers. They block carried input and provide deterministic keyboard focus.
- One upgrade offer contains at most one instance of each card ID. Selection
  diversity rules may prefer families or unlocked branches but never duplicate
  a card within the same three-card choice.
  Deployment includes three clearly selected, keyboard-focusable difficulty
  choices with concise Korean and English pressure descriptions.

### Runtime capacity and performance

- Runtime capacity is fixed at 128 live hostile actors, 240 player projectiles,
  120 hostile projectiles with 24 slots reserved for bosses, 192 experience
  shards, and 96 repeated effects. Content may use less but may not silently
  raise a cap.
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
  batches and one shared 24-segment timer batch; neither system creates
  per-actor canvas draws or per-field scene nodes.
- Only the active vehicle-performance stabilization plan's rendered native/Web
  scenarios and lifecycle soak can establish release performance. Headless
  subsystem microbenchmarks are diagnostic only.

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
- Guide discovery persists, locked entries expose only `???`, settings and pause
  both reach the guide, and Korean/English copy is complete.
- Godot import, all focused validators, native boot, Web export, and rendered
  review at supported sizes succeed. Release performance is governed by the
  active vehicle-performance architecture plan's complete native/Web
  frame-pacing, capacity, draw-call, and lifecycle gates; the legacy headless
  pressure microbenchmark is diagnostic only and cannot establish smooth play.

## Non-Goals

- A different physical map for each stage.
- Mandatory extermination of every living enemy.
- Boss rooms, boss gates, ropes, jumping, stacked navigation, or platforming.
- Ammo limits or a charge gate on ordinary held primary fire.
- More than three simultaneous secondary families.
- Unconstrained procedural topology, per-stage layout rerolls, a chore-filled
  base, or exploration puzzles in this run.
