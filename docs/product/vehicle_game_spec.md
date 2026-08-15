---
type: spec
status: active
owner: BK
created: 2026-07-21
last_reviewed: 2026-08-15
canonical_for: Cardborne gameplay and product behavior
scope: Current run-selected-field eight-boss-cycle vehicle campaign
related:
  - ../design/VISUAL_SYSTEM.md
  - ./vehicle_upgrade_catalog.md
  - ./vehicle_weapon_balance_spec.md
  - ../../.agents/semantic-v2-runtime-acceptance-evidence.md
---

# Cardborne Vehicle Game Specification

## Purpose

Cardborne is a top-down vehicle action shooter about steering through one large
run-selected field while manually aiming a held primary weapon, dashing through pressure,
and building a compact set of automatic and active weapons. A new run selects one of
three registered macro fields and keeps it through eight deterministic boss cycles. Each
cycle refreshes an authored tactical arrangement, three neutral facilities, and direct
experience placements without resetting the player's combat state.

This is the canonical product contract for the current executable eight-boss-cycle run.

## Scope

This specification covers controls, the run-selected field, boss-cycle flow, enemies,
bosses, facilities, items, upgrades, HUD and modal flows, the guidebook, localization,
settings, persistence, and release validation. It does not promise unconstrained
procedural topology, a base stage, exploration puzzles, separate bossless stages, a boss
room, or an absolute completion-time target.

### Delivery target

- Cardborne's intended public distribution target is a desktop-browser game
  exported through Godot Web. Native builds remain development and QA paths.
- The repository is the source of truth. A generated Web export is a release
  artifact and must not become a separately hand-maintained version of the game.
- A browser release is not qualified by a successful boot alone. The complete
  eight-boss-cycle loop, keyboard and mouse input, pause and pointer behavior, audio
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
| Active weapon | Left Shift |
| Pause and settings | Escape |

- Primary fire repeats uniform rounds while held. Releasing fire only stops the
  cadence; waiting before the next press never changes that next round's
  damage, size, pierce, structure damage, status payload, or counter behavior.
- Dash is a fast defensive repositioning action. The acquired active weapon uses
  the sole explicit skill button. Automatic weapons operate without input.
- Primary fire, dash, and the active weapon are rebindable. Conflicting bindings are rejected.
- Korean is the default locale. Korean and English, audio, reduced motion, and
  input settings persist.

### Fixed Hard run difficulty

- Every run uses the existing Hard combat profile. Deployment exposes no
  difficulty selector, description, lock explanation, or saved preference.
- Confirming deployment starts the complete eight-boss-cycle run with that fixed
  profile. Cycle transitions preserve it internally.
- The fixed profile composes with the shallow stage curve. It does not alter
  attack cadence, telegraph duration, hostile projectile speed, threat budgets,
  drops, experience value, or reward quality.

| Mode | Quota | Active cap | Ordinary health | Boss health | Damage | Movement speed | Approximate simultaneous pressure |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Hard | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 |

All non-boss enemy archetypes receive the existing `2.60` health multiplier
after the fixed profile and eight-cycle ordinary-health curve, then the eight-cycle pressure
curves defined in the campaign section, followed by one final ordinary-durability
multiplier of `1.20` before elite modifiers. The ordinary health curve is
`[0.85, 0.936, 1.021, 1.107, 1.193, 1.279, 1.364, 1.45]`.
Boss health uses
the separate stage profile defined below and never receives the `1.20`
ordinary-durability multiplier.
Ordinary enemy-sourced damage applies the shared `1.755` multiplier, the stage
curve `[1.00, 1.017, 1.034, 1.051, 1.069, 1.086, 1.103, 1.12]`, and the additional stage pressure defined below. Boss `final-effective` attacks
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
  player-projectile hit radius. Moving non-boss ordinary enemies use an explicit
  `48`-pixel visible radius and a separately owned `48`-pixel projectile target
  radius. Fixed installations remain `62` and bosses remain `146`; movement,
  contact, crowd, and wall radii do not change. Swept collision chooses the earliest intersected enemy. A round without
  explicit pierce is retired at that first enemy instead of crossing the
  visible body.
- Ordinary hull contact uses the relative swept path between the player's and
  enemy's physics-start and physics-end positions, so two moving bodies cannot
  cross between endpoint checks. Chaser, Scrap Drone, Rammer, and committed
  collective execution contact can damage at most once per warned active
  attack. Bulkhead Guard and Splitter Barge use persistent hull contact with a
  `0.8 s` per-enemy retry cooldown that starts only when barrier or hull accepts
  damage; an invulnerability rejection leaves the contact armed. Mobile Shooter,
  Controller, and Artillery Spotter behavior roles, including their swarm
  archetype variants, use low hull-scrape contact for `6` damage with a `1.0 s`
  per-enemy accepted-hit cooldown. A rejected scrape remains armed. Support,
  fixed-structure, ordinary-mine, and ordinary Chaser/Rammer hull overlap outside
  their warned contact attacks remains damage-inert. Boss contact remains
  independently authored.
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
- All hostile circles, wedges, shockwaves, and damaging corridors use a danger-red full
  footprint, one thin near-black perimeter, and four inward boundary notches, regardless
  of affinity. Controller and Artillery Spotter attacks are projectiles; ordinary
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
  reproduce it, and the inner-wall geometry remains fixed through all eight
  cycles so a run reads as one continuous field rather than eight reset maps.
- Thirty-two ordinary arrival candidates, twelve boss arrival anchors, and at
  least thirty-two content candidates are reusable authored sources. Each
  cycle selects three dormant neutral facilities, two experience-recall pickups, and ten XP shards with explicit
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

### Inner walls, Transit Gates, and neutral facilities

- Run-selected inner walls and paired Transit Gates preserve their geometry, collision,
  line-of-sight, dwell, cooldown, and deterministic layout owners.
- Every cycle places three distinct neutral facilities from a run-seeded rotation. Across
  eight cycles Repair, Barrier, Gravity, Cryo, and Weakpoint each appear at least once.
- Facilities have 360 health, begin dormant, accept player and hostile damage, and all
  projectiles pass through them. Destruction activates the assigned effect for exactly 12 seconds;
  the facility then expires at the end of that timer or at cycle cleanup.
- Dormant facilities apply no modifier. While active, every facility applies one symmetric
  center-in-radius rule to the player and eligible enemies. Leaving the radius or expiry
  ends its effect immediately.
- Repair and Barrier use radius 1260; Repair restores one sixth of maximum hull per
  second and Barrier caps shield at maximum hull. Gravity uses radius 1440 and multiplies
  acceleration and maximum speed by 0.70 without positional pull. Cryo uses radius 1080
  and multiplies movement and attack cadence by 0.82. Weakpoint uses radius 1260 and
  multiplies received damage by 1.15. The actual effect-radius perimeter carries the
  12-second countdown: its colored arc starts at 12 o'clock and drains clockwise over a
  thin muted spent perimeter; the facility body has no countdown ring.
- Facilities are neutral tactical priorities, not allies, enemies, pickups, cover, or
  boss shield objectives.

### Encounter and boss-cycle flow

1. Each cycle executes `ORDINARY_COMBAT -> BOSS_WARNING -> BOSS_COMBAT ->
   BOSS_DEATH_CLEANUP -> CYCLE_TRANSITION`.
2. Ordinary quotas are `40/44/48/52/56/60/64/68`; authored mobile populations are
   `260/300/340/390/440/500/560/630`. Exact materialized ordinary caps are
   `32/44/56/64/72/72/72/72`, and engaged-visible refill floors are
   `12/16/20/24/28/32/36/40`. Reserve scheduling preserves authored populations instead
   of deleting excess work.
3. First visible hostile is due within 4.0 seconds, first meaningful attack preparation
   within 8.0 seconds, and no empty or off-screen-only combat gap may exceed 3.0 seconds.
   The scheduler may expedite eligible reserves and redirect nearby mobile hostiles along
   existing paths. It may not teleport them or lower counts, cadence, or collision work.
4. Every ordinary role attacks the player. Ordinary defeats advance quota; summons,
   facilities, and boss-cleanup retirement do not. Living ordinary enemies never block
   the quota-triggered boss.
5. Quota completion starts a 1.5-second boss warning. The eight bosses appear in order:
   Foundry Colossus, Archive Leviathan, Drydock Titan, Switchyard Behemoth, Crown Engine,
   Siege Battery, Vector Loom, and Pulse Core.
6. All bosses share a committed charge and a broad three-row projectile barrage. Common
   patterns occupy at most two of any five direct selections. Every barrage emits three
   rows at 0.38-second intervals, with 4/5/6 simultaneous projectiles per row in cycles
   1-3/4-6/7-8 and either a 42-degree spread or 22.5-degree row-axis rotation.
7. Only Drydock and Crown use directional defense, and each defense directly charges or
   owns an attack. Drydock intercepts from a body-attached frontal arc; Crown has three
   body-attached defensive sectors. Their collision truth follows those directions. No
   boss is defense-only and no global shield-down rule exists.
   Drydock blocks 90% inside its body-facing frontal 110-degree arc and converts blocked
   damage into its counterburst. Crown owns three independent 120-degree sectors; a
   depleted sector remains open until the next authored phase.
8. High-threat attacks deal 60-85 damage once per execution, warn for at least 1.30
   seconds, use collision-matching committed geometry, and leave an escape corridor at
   least player diameter + 80 units. Pressure damage is 10-18 and normal damage is 22-38.
   No true instant-kill attack exists.
9. Boss base health is 5200. Health scales are
   `1.00/1.12/1.25/1.39/1.54/1.70/1.87/2.05`; damage scales
   `1.00/1.06/1.12/1.18/1.24/1.31/1.38/1.46`; move speeds
   `181.25/187.5/193.75/200/207.5/215/222.5/230`; cadence scales
   `1.00/.97/.94/.91/.88/.85/.82/.79`; coverage scales
   `1.00/1.04/1.08/1.12/1.16/1.20/1.24/1.28`.
   Boss projectile speed uses `1.40x`, beam reach `1.45x`, committed charge speed
   `1.30x`, and circular or wedge radius `1.25x`; warning time is never reduced.
   Archive Cross commits two clipped perpendicular X corridors. Siege Battery alone
   uses ammunition that arms at 360 traveled units and caps at 880, interpolating speed
   `0.75x->1.35x`, radius `1.0x->1.5x`, and damage `1.0x->1.6x`.
10. Lethal boss damage starts 2.00 seconds of safe cleanup. Boss-owned danger stops
    immediately. The boss body receives a restrained hit tint, dim/desaturation, and
    fade only; no explosion, effect raster, growth, impulse, or hit-stop occurs. Owned
    summons/facilities stagger-shrink/fade without reward or quota. Transition waits for
    cleanup completion.
11. Cycle completion refreshes cycle-local facilities and XP placements while preserving
    player position, velocity, aim, projectiles, XP, build, cooldowns, fixed Hard state,
    exploration, and terrain. Cycle 8 opens Result; failure opens Failure Report.

| Boss cycle | Quota | Authored mobile population | Boss |
| ---: | ---: | ---: | --- |
| 1 | 40 | 260 | Foundry Colossus |
| 2 | 44 | 300 | Archive Leviathan |
| 3 | 48 | 340 | Drydock Titan |
| 4 | 52 | 390 | Switchyard Behemoth |
| 5 | 56 | 440 | Crown Engine |
| 6 | 60 | 500 | Siege Battery |
| 7 | 64 | 560 | Vector Loom |
| 8 | 68 | 630 | Pulse Core |

### Items, experience, and upgrades

- Enemy defeats leave collectible XP shards; boss-cleanup retirement never grants XP.
  Each cycle adds exactly ten visible XP shards to authored placements.
- Repair pickups are removed. Their former sockets produce XP shards and Repair facilities
  own high-rate recovery.
- `vehicle_upgrade_catalog.md` is canonical for 27 cards and 91 nominal level states.
  Thermal Burst or Bio Toxin occupies the damage slot; Cryo is the sole utility attribute.
  Shock and any replacement utility attribute do not exist.
- Miss Compensation stores up to five missed shot groups and consumes them on the next
  hostile hit for +8/11/14% damage per stack. Hit Chain stores up to eight consecutive
  hit groups for +3/4/5% primary damage per stack and clears on a miss. Braced Fire charges
  one segment per 220 movement units up to five; after 0.60 seconds below speed 20 it
  grants +6/8/10% primary damage per segment for 4.0 seconds and ends above speed 60.
  Split children share one shot-group outcome.
- If active and secondary weapons are both absent, one offer slot is reserved for each.
  If one is absent, one slot is reserved for it. Each reservation ends immediately after
  that category's first acquisition.
- Dash remains the only innate action. Automatic and active weapons require card
  acquisition and preserve their balance/resource owners.

### UI, guidebook, report, and persistence

- Korean is default and Korean/English coverage is complete on every reachable surface.
  Deployment, Pause, Upgrade, Guidebook, Settings, Result, and Failure Report preserve
  their existing flow. Pause abort and terminal primary actions return to Deployment.
- HUD progression reads `보스 N/8` / `Boss N/8` with remaining ordinary quota. The
  panel-free top-left row contains progression, total defeats, Dash, and Active, followed
  by at most five meaningful conditional status icon/value slots; full upgrade names stay
  in Ship Status. No
  player-facing `Stage N/10`, odd/even pairing, transition banner, boss room, or
  difficulty selector remains.
- Guidebook categories remain Ship, Enemies, Bosses, and Field Objects. It lists all eight
  bosses and active ordinary roles from gameplay data; facilities are Field Objects.
- Victory, defeat, and Settings Ship Status reuse one report view model and report body:
  one left-aligned vertical stack, exactly one outer scroll, no report tabs, metric
  sub-scroll, narrow build rail, or multi-column metric body.
- Section order is outcome, cycle progress, build, damage, defense, enemies, bosses,
  pacing, diagnostic limitations. Terminal screens keep one fixed Deployment action.
  Korean/English at 960x540, 1280x720, 1920x1080 and 100%/200% text must not clip,
  overlap, overflow, or create horizontal scrolling.
- Active run time includes PLAYING and mandatory UPGRADE, excludes explicit Pause and
  terminal screens, and is observational telemetry rather than an acceptance target.
- Diagnostics retain at most the newest ten valid completed bundles by
  `(saved_unix, session_id)` descending on load and persistence. Modification time is
  not authoritative. Invalid bundles quarantine first; 25 MiB and 14-day caps remain.
  Protected summaries preserve cycle time, gap data, boss identity, cleanup duration,
  and report outcome.

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

- Exactly eight boss cycles complete in order; every boss follows its quota and safe
  cleanup, and no player-facing ten-stage/paired language remains.
- Every boss charges, fires simultaneous multi-projectile rows, and emphasizes its
  identity patterns. Base stats strengthen monotonically.
- Drydock and Crown alone use defense and link it to offense. No global shield rule,
  defense-only boss, true instant kill, or mismatched high-threat warning remains.
- Boss death lasts exactly 2.00 seconds and permits no boss-owned damage, reward, quota,
  or early transition. Reduced motion preserves state/timing while removing growth,
  impulse, and hit-stop.
- The four new ordinary roles attack. Wreck Scavenger uses eligible radius-360 death
  events, caps at five stacks, and creates no corpse.
- Shock has no reachable data, runtime, status, offer, copy, telemetry, or image. Thermal
  and Toxin remain damage alternatives and Cryo is the sole utility attribute.
- New primary-fire upgrades, missing-category offer reservations, five symmetric
  facilities, repair-pickup removal, and ten added visible XP shards per cycle pass
  deterministic fixtures.
- Diagnostics keep the newest ten valid bundles under age/byte/quarantine rules.
- Report surfaces share one left-aligned stack, one scroll, exact section order, complete
  focus path, and zero clipping/overflow in the locked matrix.
- The approved production manifest contains no boss-death explosion or effect raster.
- Focused validators, Godot import/parse, production Web export, built-Web interaction,
  and separately labeled native/Web same-workload evidence complete truthfully.

## Non-Goals

- A different physical map for each stage.
- Mandatory extermination of every living enemy.
- Boss rooms, boss gates, ropes, jumping, stacked navigation, or platforming.
- Ammo limits or a charge gate on ordinary held primary fire.
- More than three simultaneous secondary families.
- Unconstrained procedural topology, per-cycle layout rerolls, a chore-filled
  base, or exploration puzzles in this run.
- Growth systems beyond the current 27-card catalog, six automatic weapon types,
  and four active weapon types require an explicit product-spec revision.
- A selectable, adaptive, or meta-progression difficulty model is inactive and
  requires an explicit product-spec revision.
- Additional map-generation systems or coordinated-enemy tactic families require an
  explicit product-spec revision and a separate ExecPlan before implementation.
- A named cultural, marine, ritual, or material motif is not part of the current
  product identity.
