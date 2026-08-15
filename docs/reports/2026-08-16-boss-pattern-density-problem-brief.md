---
type: evidence
status: active
created: 2026-08-16
topic: Boss pattern identity, combat visualization, boss cadence, and dense-enemy performance
scope: Current Cardborne eight-boss production implementation at commit b1d0f605
related:
  - ../../.agents/execplans/2026-08-15-eight-boss-combat-depth-and-run-report.md
  - ../../.agents/execplans/2026-08-15-combat-readability-and-pressure-decisions.md
  - ../product/vehicle_game_spec.md
  - ../design/VISUAL_SYSTEM.md
---

# Boss Pattern, Visualization, and Density Problem Brief

## Purpose

This brief fixes the current evidence boundary before an external Claude Code review and
before Cardborne's next boss/density execution contract. It is evidence, not an accepted
design or implementation plan.

## Sources

- User report on 2026-08-16: boss attacks and their visualization need a comprehensive
  evaluation; boss arrivals feel too close together; each boss should require more ordinary
  defeats; more enemies should be visible at once; current stutter is the limiting factor.
- `scripts/bosses/vehicle_boss_patterns.gd`
- `scripts/bosses/vehicle_boss_runtime.gd`
- `scripts/bosses/vehicle_boss_phase_catalog.gd`
- `scripts/combat/vehicle_attack_telegraph_builder.gd`
- `scripts/presentation/vehicle_combat_renderer.gd`
- `scripts/presentation/components/vehicle_combat_cue_policy.gd`
- `scripts/vehicle/stages/vehicle_combat_stages.gd`
- `scripts/encounters/vehicle_encounter_director.gd`
- `scripts/encounters/vehicle_encounter_runtime.gd`
- `scripts/enemies/vehicle_enemy_update_schedule.gd`
- `scripts/vehicle/vehicle_run.gd`
- `build/performance/combat-readability/65afb5ea-production-replay-native-60s.json`
- `docs/design/VISUAL_SYSTEM.md` and its canonical style-reference sheet

## Findings

### Boss cadence and encounter density

- The eight ordinary-defeat quotas are currently `40/44/48/52/56/60/64/68`.
  `VehicleStageFlow` begins the boss warning on the exact final countable defeat.
- The eight stage materialized-active caps are `32/44/56/64/72/72/72/72`; the corresponding
  engaged-visible refill floors are `12/16/20/24/28/32/36/40`.
- Ordinary maintenance spawning remains available during boss combat, while only the boss
  and its bounded phase adds are exempt from ordinary quota progression. This can preserve
  pressure but can also compete with the boss for attention and visual space.
- The authored ordinary populations are much larger than the boss quotas
  (`260/300/340/390/440/500/560/630`), so increasing defeat requirements does not require
  inventing a new population source.

### Current performance constraint

- The latest retained eligible native run used Godot 4.7.1, OpenGL compatibility rendering,
  1280x720, a 10-second warmup, and a 60-second production-replay sample at clean commit
  `65afb5ea`.
- The scenario had an active/materialized cap of 72 and sampled 68 live ordinary enemies at
  the final snapshot; slow receipts recorded 63-64 enemy centers inside the visible world.
- Release physics failed: p95 `7.159 ms` against `6.0 ms` and p99 `9.078 ms` against
  `8.0 ms`. Frame, presentation, draw-call, memory, and other recorded thresholds passed.
- The named hot owner was `enemies_and_grid` (p95 `5.49 ms`, p99 `6.98 ms`). Its dominant
  child was `enemy_scheduled_ordinary` (p95 `4.14 ms`, p99 `5.59 ms`). Within that work,
  ordinary decision policy measured p95 `2.04 ms` and ordinary motion policy p95 `1.61 ms`;
  movement collision, overlap cache/query, and pursuit sampling were individually smaller.
- This evidence does not qualify a count above 72 and does not support raising capacity
  before a causal optimization. It also does not prove that reducing visible enemies is an
  acceptable product solution.

### Boss pattern structure

- Every boss uses one shared committed charge and one shared three-row broad barrage in a
  five-pattern direct sequence. This guarantees baseline literacy but spends 40% of each
  direct sequence on common behavior.
- Boss-specific direct patterns are composed from a small shared vocabulary: lanes, fan,
  area, beam, cross/cross-corridor, summon, long banks, moving walls, wedge rings, and spiral.
- Autonomous sequences add two repeating background mechanics per boss. They can create
  identity and layered pressure, but their simultaneous use with direct attacks, ordinary
  enemies, and phase adds has not been qualified here for attention load or safe-gap clarity.
- Only Drydock Titan and Crown Engine own defensive systems. Phase changes at 65% and 30%
  health also add bounded ordinary-role packets, with a maximum of 12 live adds.
- The previous projectile-route regression is fixed at commit `b1d0f605`: non-beam
  projectiles expose no predicted world path. Exact beam corridors and exact delayed damage
  footprints remain visible; off-screen projectile descriptors drive threat-radar direction.

### Visual contract

- Boss bodies use one authored body with 4-6 large filled planes and one outer perimeter;
  boss rank must not be communicated through small panels, nested outlines, repeated lamps,
  or decorative particles.
- Hostile circles, wedges, shockwaves, and damaging corridors use the exact committed
  danger-red footprint, one thin near-black perimeter, and four inward notches where the
  geometry permits. Color cannot be the only cue.
- Projectile startup and live non-beam projectiles show no predicted route. Beam startup and
  active states share the exact gameplay corridor. Charge startup shows no travel corridor.
- Visual geometry cannot become a second collision or timing owner, and new player-facing
  cue raster/SVG geometry is prohibited.

## Questions for Claude Code

1. For each of the eight bosses, which direct and autonomous patterns are mechanically
   distinct, redundant, unreadable under overlap, or inconsistent with the boss's stated
   identity? Cite exact files and symbols.
2. Which attacks have warning geometry or timing that does not match runtime damage,
   targeting, movement, or phase behavior? Separate verified defects from design opinions.
3. How should each boss's direct sequence, autonomous layer, phase transition, adds, and
   visual language change so that the player can identify the boss and the required response
   within one encounter?
4. How should exact beams, areas, moving walls, rings, projectile bodies, source anticipation,
   off-screen warnings, recovery, and safe gaps be prioritized without restoring predicted
   projectile paths or adding visual noise?
5. Why does `enemy_scheduled_ordinary` dominate the current 72-cap physics workload? Identify
   concrete algorithmic/data-flow candidates that preserve collision truth, movement quality,
   attack activity, determinism, and the 60 Hz physics contract.
6. What staged capacity qualification would safely support higher visible density after the
   72-cap failure is repaired? Do not recommend lowering quality, thresholds, resolution,
   cadence, or enemy activity to manufacture a pass.
7. Propose evidence-backed defeat quotas and visible/materialized density targets that make
   boss arrivals feel earned without turning each pre-boss segment into repetitive cleanup.
   State assumptions and identify which values require gameplay measurement.
8. Return a detailed English report with an executive summary, per-boss table, visualization
   critique, cadence/density analysis, performance diagnosis, prioritized recommendations,
   validation plan, risks, and explicit uncertainties.

## Limitations

- No new gameplay capture or long performance run was performed for this brief.
- The retained native run is authoritative for its recorded commit and workload only; current
  HEAD includes later non-performance and visual changes.
- Still images cannot prove temporal readability, safe-gap duration, or player response time.
- External references and Claude Code recommendations remain advisory until verified against
  current source and promoted into the product specification and an active execution contract.
