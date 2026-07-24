---
type: spec
status: active
owner: BK
created: 2026-07-21
last_reviewed: 2026-07-24
canonical_for: Cardborne gameplay and product behavior
scope: Current shared-field five-stage vehicle campaign
related:
  - ../design/UI_VISUAL_SYSTEM.md
  - ../../.agents/vehicle-performance-architecture-audit.md
  - ../../.agents/vehicle-performance-stabilization-evidence.md
  - ../../.agents/execplans/2026-07-23-vehicle-performance-architecture-stabilization.md
---

# Cardborne Vehicle Game Specification

## Purpose

Cardborne is a top-down vehicle action shooter about steering through one large
drowned-ruin field while manually aiming a held primary weapon, dashing through
pressure, and building a compact set of automatic secondary weapons. A new run
selects one validated arrangement of large internal cover and content sockets.
All five combat stages and retries reuse that arrangement while pressure, enemy
composition, boss patterns, and rewards change.

This is the canonical product contract for the current executable.

## Scope

This specification covers controls, the shared field, stage flow, enemies,
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

- Primary fire repeats while held. Releasing it for one second primes a stronger
  opening shot with extra structure damage and temporary pierce.
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
  calculation with a multiplier of `0.82`. Ordinary hostile shots use a
  five-pixel collision radius and a minimum six-pixel head; boss-reserved shots
  use a six-pixel collision radius and a minimum seven-pixel head. Both retain a
  36-pixel readable trail. The Pulse Cannon's unmodified projectile uses a
  seven-pixel collision radius, and upgrades scale from that base.
- Every projectile stops at the same static or run-selected cover that blocks
  the ship. A live crate also blocks line of sight and both projectile teams;
  hostile fire is absorbed without destroying the reward crate, while player
  fire can break it. `wall_piercing` is an explicit projectile capability whose
  default is false. No current ordinary enemy, boss pattern, primary shot, or
  secondary shot receives that capability implicitly.

### One shared field

- Every stage uses `drowned_ruin_field` with a `5600x3400` world rectangle and
  respawns the player at `(2800, 1700)`.
- The center has a 480-pixel safe clearance. The camera remains at zoom 1, so the
  field is larger than one screen and exploration state matters.
- Sixteen walkable regions, four water/void regions, and sparse large motifs
  define the immutable floor. A run selects exactly two large cover candidates
  in each quadrant from sixteen authored candidates, for eight internal cover
  shapes. The selected cover is validated for the ordinary 36-pixel and boss
  76-pixel actor radii before play.
- Rendering, movement, projectile collision, line of sight, pursuit, minimap,
  and validation consume the same run layout. The layout remains unchanged
  across stages and exact retries; only a new run selects another arrangement.
- Twenty-four ordinary arrival candidates, eight boss arrival anchors, twelve
  stationary candidates, and twenty-four item sockets are reusable authored
  positions. Each stage selects four stationary threats, three pickups, and
  five crates from valid sockets. No stage owns a separate map, boss room,
  closed progression gate, switch maze, or reflector puzzle.
- Capture, validation, and performance paths accept `--layout-seed=<integer>`;
  their default is `0xC4A2B0`, and debug/performance snapshots expose the
  selected seed and layout fingerprint.
- The explored minimap uses a 16x10 grid. Unvisited cells remain concealed; the
  player, discovered pickups, boss warning, and active boss are marked.

### Encounter and stage flow

1. Each stage begins at the shared center with no mobile damaging enemy active.
2. The first arrival cue begins at 5.1 seconds and the first scout arrives at
   6.0 seconds.
3. Later arrivals are eight-squad surges. Each squad contains three to five
   enemies, so the first surge schedules at least 24 enemies and later surges
   grow toward 40. Every squad receives its own deterministic valid anchor.
   Arrivals prefer positions at least 960 pixels from the player and 160 pixels
   beyond the visible world, avoid the four most recent anchors, and use groups
   of at most two squads in beats 0–1 or three squads later. Group gaps are
   0.90 seconds early and 0.65 seconds later. Existing role totals are preserved
   while direct-projectile pressure is distributed between squads.
   Projectile-firing archetypes are capped at 50% of both the authored mobile
   population and the four stationary threats in every stage. A stage already
   below the cap is not inflated to reach it; area, beam, charge, and support
   roles remain separate classifications.
   Hard can sustain 48 active enemies from the first combat beat and remains
   capped at the measured 72-enemy ceiling. Normal scales those caps to 45 and
   68; Easy scales them to 42 and 64. Excess enemies stay in the deterministic
   scheduler queue.
4. Every mobile enemy joins a shared low-frequency pursuit field and can route
   around cover toward the player. Stationary roles hold authored anchors.
5. Ordinary defeats advance the stage quota. Living enemies never block travel
   or stage completion and summons do not count toward the quota.
6. On reaching the quota, ordinary spawning stops and a 1.5-second boss warning
   identifies a reachable arrival anchor at least 1200 pixels from the player
   when the field permits it. Boss creation and boss-defeat completion reject
   calls unless the quota has been reached and the warning has resolved.
7. The boss enters the same field and pursues the player. It does not wait in a
   sealed arena. During visible startup it tracks the moving player while
   approaching, retreating, or strafing at a readable speed. Projectile attacks
   lock a predictively aimed lane and repeat volleys along it; charge, area,
   pylon, and summon patterns add one aimed three-shot pressure burst. The
   active attack preserves the telegraphed direction before its bounded recovery.
8. Boss defeat recalls experience, resolves mandatory reward choices, then
   stages 1–4 automatically preserve the build and explored minimap, return the
   ship to the center, and begin the next stage. Stage 5 opens the final result.

| Stage | Hard quota | Normal quota | Easy quota | Authored mobile population | Boss |
| ---: | ---: | ---: | ---: | ---: | --- |
| 1 | 96 | 86 | 78 | 260 | Foundry Colossus |
| 2 | 128 | 115 | 104 | 300 | Archive Leviathan |
| 3 | 160 | 144 | 130 | 340 | Drydock Titan |
| 4 | 192 | 173 | 156 | 380 | Switchyard Behemoth |
| 5 | 224 | 202 | 181 | 420 | Crown Engine |

Four stationary threats are added per stage. Ordinary hostile projectiles stop
at 96 so 24 of the global 120-shot cap remain reserved for boss attacks. Enemy
health, damage, and movement rise only on a shallow stage curve; boss behavior
changes through authored patterns rather than unchecked stat inflation. Every
damaging boss pattern has a visible startup, active window, and recovery. Routine
hits cannot interrupt an attack; stagger can build only during recovery and lasts
exactly 0.75 seconds before the boss resumes its pattern loop.

### Items, experience, and upgrades

- Enemy defeats leave collectible geometric experience shards. Experience is
  granted only when a shard is collected; summons grant none.
- Exactly two field item behaviors exist: repair restores hull and experience
  recall pulls all live shards toward the player. Breakable crates contain one
  of those two items.
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
  timed effects. It must not cover the central combat area.
- Pause and settings expose a `?` entry to the guidebook. The guidebook has ship,
  mobile enemies, stationary enemies, bosses, and objects categories.
- The current ship page shows derived stats and equipped secondaries. Encountered
  entries persist across runs; unseen entries show only `???` and never leak
  their name or description.
- Deployment, upgrade, pause/settings, guidebook, result, and garage are modal
  focus layers. They block carried input and provide deterministic keyboard focus.
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
- Only the active vehicle-performance stabilization plan's rendered native/Web
  scenarios and lifecycle soak can establish release performance. Headless
  subsystem microbenchmarks are diagnostic only.

## Acceptance Criteria

- The immutable field, 480-pixel start clearance, all 1,296 cover masks, both
  actor radii, 256 seeded complete layouts, and one-layout identity across all
  five stages and retries pass validation.
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
