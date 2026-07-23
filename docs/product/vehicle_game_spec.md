---
type: spec
status: active
owner: BK
created: 2026-07-21
last_reviewed: 2026-07-23
canonical_for: Cardborne gameplay and product behavior
scope: Current shared-field five-stage vehicle campaign
related:
  - ../design/UI_VISUAL_SYSTEM.md
---

# Cardborne Vehicle Game Specification

## Purpose

Cardborne is a top-down vehicle action shooter about steering through one large
drowned-ruin field while manually aiming a held primary weapon, dashing through
pressure, and building a compact set of automatic secondary weapons. Five combat
stages reuse the same physical field. Pressure, enemy composition, boss patterns,
and rewards change; the map does not reload into a different layout.

This is the canonical product contract for the current executable.

## Scope

This specification covers controls, the shared field, stage flow, enemies,
bosses, items, upgrades, HUD and modal flows, the guidebook, localization,
settings, persistence, and release validation. It does not promise procedural
maps, a base stage, exploration puzzles, or content beyond the five-stage run.

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
- Korean is the default locale; Korean and English, audio, difficulty, and input
  settings persist.

### One shared field

- Every stage uses `drowned_ruin_field` with a `5600x3400` world rectangle and
  respawns the player at `(2800, 1700)`.
- The center has a 480-pixel safe clearance. The camera remains at zoom 1, so the
  field is larger than one screen and exploration state matters.
- Sixteen walkable regions, thirteen solid cover shapes, four water/void regions,
  and sparse large motifs define the field. The same geometry drives rendering,
  movement, projectile collision, line of sight, pursuit, minimap, and validation.
- Sixteen ordinary spawn anchors, eight boss arrival anchors, and four stationary
  anchors are reusable content sockets. No stage owns a separate map, boss room,
  closed progression gate, switch maze, or reflector puzzle.
- The explored minimap uses a 16x10 grid. Unvisited cells remain concealed; the
  player, discovered pickups, boss warning, and active boss are marked.

### Encounter and stage flow

1. Each stage begins at the shared center with no mobile damaging enemy active.
2. The first arrival cue begins at 5.1 seconds and the first scout arrives at
   6.0 seconds.
3. Later arrivals are eight-squad surges. Each squad contains three to five
   enemies, so the first surge schedules at least 24 enemies and later surges
   grow toward 40. Standard can sustain 48 active enemies from the first combat
   beat; both presets remain hard-capped at the measured 72-enemy ceiling. The
   excess stays in the deterministic scheduler queue.
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

| Stage | Ordinary quota | Authored mobile population | Boss |
| ---: | ---: | ---: | --- |
| 1 | 96 | 260 | Foundry Colossus |
| 2 | 128 | 300 | Archive Leviathan |
| 3 | 160 | 340 | Drydock Titan |
| 4 | 192 | 380 | Switchyard Behemoth |
| 5 | 224 | 420 | Crown Engine |

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
- Level thresholds are intentionally frequent. Each level and boss reward opens
  a guarded three-card selection that requires an explicit choice and confirm.
- `Tuned Thrusters` is the direct movement upgrade and changes base movement to
  1.08x, 1.16x, then 1.24x. There is no recurring movement-speed cycle.
- Upgrades cover primary cadence, count, damage, opening-shot behavior, status
  payloads, dash, EMP, barrier, sustain, pickup reach, and automatic secondaries.
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

## Acceptance Criteria

- The shared field, all anchors, 480-pixel start clearance, player and boss
  reachability, and geometry identity across all five stages pass validation.
- The first cue/scout timing, stage quotas, eight-squad surge growth, spawn stop,
  1.5-second boss warning, roaming boss, preserved build/exploration, automatic
  stages 1–4 transition, and stage 5 result pass focused tests.
- Tuned Thrusters has the exact three values, the five secondary families load,
  no more than three are active, and their bounded simulations pass tests.
- Guide discovery persists, locked entries expose only `???`, settings and pause
  both reach the guide, and Korean/English copy is complete.
- Godot import, all focused validators, the pressure profile at no more than 8ms,
  native boot, Web export, and rendered review at supported sizes succeed.

## Non-Goals

- A different physical map for each stage.
- Mandatory extermination of every living enemy.
- Boss rooms, boss gates, ropes, jumping, stacked navigation, or platforming.
- Ammo limits or a charge gate on ordinary held primary fire.
- More than three simultaneous secondary families.
- Procedural generation, a chore-filled base, or exploration puzzles in this run.
