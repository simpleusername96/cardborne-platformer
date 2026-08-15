---
type: evidence
status: active
created: 2026-08-16
topic: Evidence synthesis for Cardborne boss identity, combat readability, encounter cadence, and dense-enemy performance
scope: Repository evidence at b1d0f605, retained native evidence at 65afb5ea, primary external references, and pending Claude Code review
related:
  - ./2026-08-16-boss-pattern-density-problem-brief.md
  - ../../.agents/execplans/2026-08-15-combat-readability-and-pressure-decisions.md
  - ../product/vehicle_game_spec.md
  - ../design/VISUAL_SYSTEM.md
---

# Boss Identity and Dense-Cadence Research

## Decision question

How should Cardborne make each of its eight bosses teach a distinct response, make every
dangerous space readable without restoring projectile trajectory lines, lengthen the combat
between bosses, and raise visible ordinary-enemy density without hiding the current physics
failure?

This document is evidence and analysis. Exact implementation values become authoritative
only after they are copied into the active execution contract.

## Evidence boundary

### Local evidence

- `VehicleBossPatterns.STAGE_SEQUENCES` gives every boss five direct slots, two of which are
  the same `common_charge` and `common_broad_barrage`. Common behavior therefore consumes
  40% of each direct sequence before autonomous systems are counted.
- `VehicleBossRuntime.update_active()` implements direct `lanes`, `fan`, `cross`,
  `broad_barrage`, `cross_corridors`, `charge`, `beam`, `area`, `pylons`, and `summon` kinds.
  It does not execute direct `long_banks`, `moving_walls`, `wedge_rings`, or `spiral` kinds.
  Stages 6, 7, and 8 place those kinds in their direct sequences, so those direct slots
  currently spend their active time without producing their named attack.
- `VehicleBossRuntime.advance_autonomous()` emits an event immediately when its cadence
  timer expires. `VehicleRun._execute_boss_autonomous()` immediately creates zones or
  projectiles. Zone kinds carry their own warning time, but `long_banks` and `spiral`
  projectiles spawn immediately; their authored startup values do not delay release.
- Autonomous cadence does not inspect the direct attack state. A boss can therefore layer
  an autonomous system over a direct startup/active window, ordinary enemies, and phase
  adds without a shared attention budget.
- Direct moving-wall and wedge attacks cannot simply be inserted into the current active
  dispatcher. Their collision-true warning geometry must exist during direct startup, and
  projectile-system attacks must release only when direct active begins.
- Boss maintenance is separate from the stage materialized cap. After quota seal it admits
  reserve-backed ordinary identities only below an 8-enemy low watermark, up to a
  12-enemy high watermark, in groups of at most four. Raising the stage cap does not by
  itself make boss-time maintenance reach that cap.
- The latest eligible native evidence used a cap of 72 but ended with 68 live ordinary
  enemies. It qualifies the recorded cap-72 production-replay workload, not a claim that
  every sampled frame contained exactly 72 enemies.

### External primary sources

- Riot's [League VFX Style Guide](https://nexus.leagueoflegends.com/en-us/2017/10/dev-leagues-vfx-style-guide/)
  says VFX should communicate gameplay space, power, and function, match visual impact to
  gameplay impact, and minimize clutter. Cardborne should spend its strongest footprint
  treatment on committed beams, delayed areas, moving walls, and ring/wedge denial rather
  than on every ordinary projectile.
- Riot's [Clarity in League](https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/)
  defines clarity as identifying and responding, requires an importance hierarchy, and
  says projectile direction should be readable from the projectile itself. This supports
  Cardborne's current no-predicted-path rule for non-beam projectiles.
- Housemarque's [Hyperion fight analysis](https://blog.playstation.com/2021/05/28/returnal-the-making-of-that-unforgettable-hyperion-fight/)
  describes phase escalation, pattern contrast, repeated testing, and deliberate gaps that
  remain learnable under overlap. The useful transfer is response-language contrast and
  safe-gap testing, not Returnal's theme or projectile volume.
- Santa Monica Studio's [first-boss retrospective](https://blog.playstation.com/2018/08/16/fighting-a-god-behind-the-scenes-of-god-of-wars-first-boss-battle/)
  shows that arena size, attack feel, and interference density were prototype questions,
  not late decoration. Cardborne should validate each signature mechanic with its intended
  arena response and ordinary-enemy interference present.
- Valve's [Left 4 Dead AI systems](https://steamcdn-a.akamaihd.net/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf)
  presents build-up, sustain, and relaxation as a dramatic-intensity structure. Cardborne
  should keep many enemy bodies while changing which layer owns the current peak instead
  of allowing every layer to peak continuously.
- Godot 4.7's [general optimization guidance](https://docs.godotengine.org/en/4.7/tutorials/performance/general_optimization.html)
  requires measuring the largest bottleneck, changing it, and profiling again; it also
  favors compact, local, linear data and moving invariant work out of loops.
- Godot 4.7's [CPU optimization guidance](https://docs.godotengine.org/en/4.7/tutorials/performance/cpu_optimization.html)
  recommends profiler-led work and repeated timing. Its language, thread, and tick-rate
  suggestions are not adopted here because Cardborne's approved boundary keeps GDScript,
  60 Hz physics, exact collision, and single-threaded runtime ownership.
- Microsoft's [Xbox Accessibility Guideline 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103)
  supports redundant critical cues. Danger red is an ownership color, not the only signal;
  exact shape, near-black perimeter, inward notches, timing, and audio carry the same truth.

## Cross-boss diagnosis

### Identity is diluted by shared sequence slots

The common charge and broad barrage teach reusable literacy, but putting both in every
five-slot sequence makes all eight bosses spend nearly half of their direct cadence on the
same verbs. The later bosses also repeat broad barrage before or after a signature system,
so their silhouettes differ more strongly than their decision demands.

The correction is not to add more attacks. Each direct sequence should contain three
boss-owned exams. Phase escalation should reorder or combine those exams, while autonomous
systems should support the same response verb and yield during the signature peak.

### Some named signature attacks are currently direct no-ops

`battery_long_banks`, both Loom moving-wall attacks, and both Pulse system attacks have
definitions and autonomous implementations, but the direct state machine has no matching
branches. This creates a material gap between design data and runtime behavior. It also
explains why adding more VFX alone would not repair the later bosses.

### Visual evidence does not cover signature states

The current eight-boss startup/active contact sheet selects the first direct pattern after
phase reset. That pattern is the shared charge, whose trajectory is intentionally hidden.
The resulting startup/active pairs are nearly identical and prove body silhouettes, not the
readability of all eight signature mechanics. Final evidence needs one collision-true
startup/active pair for each boss's primary exam, captured in one background batch after
implementation.

## Per-boss response contract

| Boss | Primary response verb | Direct exam set | Autonomous support | Required correction |
| --- | --- | --- | --- | --- |
| Foundry | Read lane compression, then punish the opening | Furnace Gates, Foundry Burst, Furnace Ring | Slag Ring, Forge Vent | Remove common slots; keep a clear lane-to-area escalation and ensure recovery is the damage opportunity. |
| Archive | Reposition through orthogonal/X geometry | Archive Cross, Archive Depth, Current Fan | Undertow Lanes, Depth Charges | Make the X two exact committed corridors; do not let an autonomous area erase the readable crossing gap. |
| Drydock | Flank a directional defense, then respect stored counterpressure | Grounding Grid, Drydock Counterburst, Titan Pulse | Thunder Chain, Beam Sentinel | Align the rendered frontal arc with the interception angle; communicate counterburst charge on the body/HUD, not with a ground route. |
| Switchyard | Orbit around a sweeping axis and switch sides | Switch Sweep, Gate Shockwave, Ricochet Volley | Switchyard Mines, Switch Sweeps | Keep exact beam corridors; hold extra mine/sweep commits while the signature sweep owns the attention peak. |
| Crown | Choose and break a shield sector while lanes close | Crown Beam, Mirror Cross, Carrier Wave | Crown Lattice, Relay Pulse Rings | Align each body sector with collision truth and keep broken sectors visibly absent; phase adds should reinforce, not hide, sector choice. |
| Siege | Engage before bank projectiles mature with distance | Battery Long Banks, Ricochet Volley, Gate Shockwave | Long Banks | Implement long banks in the direct dispatcher and preserve body-only projectile direction. The distance-growth mechanic is the boss's range rule, not a global projectile rule. |
| Loom | Find and follow translating gaps | Translating Walls, Archive Cross, Orthogonal Pass | Moving walls | Create collision-true wall segments during direct startup, retain the 180-unit gap, and prevent a second wall system from closing the authored escape at the same time. |
| Pulse | Align with the missing wedge, then change rhythm for the spiral | Missing Wedge, Mirror Cross, Sparse Spiral | Wedge/spiral | Implement direct wedge and spiral delivery; show the exact dangerous ring and negative safe wedge, then rely on projectile bodies for the spiral. |

## Visualization rules

1. Non-beam projectiles and charge movement keep no projected world trajectory.
2. Beam startup and active states use the same exact corridor. Startup is lower-opacity
   danger red; active is stronger danger red; both retain one thin near-black perimeter.
3. Delayed area, corridor, moving-wall, and wedge/ring damage shows the exact committed
   footprint. The negative safe space must remain visually empty enough to read at 1x.
4. Danger ownership uses red, but shape and perimeter provide redundant meaning. Circular
   footprints keep inward notches; corridors use their long axis and black edge; the Pulse
   ring communicates safety by a missing wedge.
5. Projectile threat is communicated by source posture, projectile silhouette/tail, speed,
   and off-screen radar. It is not communicated by a line from source to target.
6. Recovery is a gameplay state and needs restrained body/HUD feedback. It must not reuse
   danger-red ground geometry because recovery is an opportunity, not damage space.

## Cadence and density model

### Separate three numbers

- **Defeat quota** controls time and build development between bosses.
- **Materialized cap/refill floor** controls ordinary body density before quota seal.
- **Boss-maintenance low/high watermarks** control ordinary interference during the boss.

Changing one of these does not solve the other two. The next execution contract must name
all three explicitly.

### Provisional target for the execution contract

- Defeat quotas: `60/66/72/78/84/90/96/102` (exact 1.5x current values). This changes the
  minimum ordinary path from 432 to 648 defeats and makes the cadence increase predictable
  rather than stage-specific guesswork.
- Materialized caps: `40/52/64/72/84/84/84/84`. The late-run target is 84, a 16.7% increase
  over the current cap, not an unsupported jump to 96.
- Refill floors: `16/22/28/34/40/46/52/58`. These increase the visible-pressure target while
  remaining below each stage cap.
- Boss maintenance: keep the 8/12 low/high body watermark initially, but introduce an
  attention state: ordinary attack commits hold during the brief startup/active peak of a
  signature footprint and resume during boss read/recovery. Existing bodies remain active,
  collidable, targetable, and mobile; the system changes commit ownership, not population.

The 1.5x quota path produces `3445 XP` and reaches run level 45, or 44 level-up rewards,
when evaluated with the current authored blueprint order and XP rules. Stage XP is
`264/290/342/348/461/470/610/660`; cumulative end levels are
`11/15/18/22/27/32/38/45`. The upgrade catalog declares 91 total level states, although
run-specific compatibility still decides the actual available set. The implementation must
replace the old `2296 XP / 32 upgrades` assertion with this explicit route result and retain
truthful catalog-exhaustion handling rather than discarding enemy rewards.

## Performance diagnosis and safe work order

The current failure is CPU/physics-owned, not GPU-owned. The late-run target cannot be
qualified until the 72-cap physics tail is repaired.

1. Preserve the current eligible 72-cap JSON as the before-state.
2. Optimize only `enemies_and_grid` / `enemy_scheduled_ordinary` first.
3. Candidate A: remove per-decision `Dictionary` allocation from
   `VehicleEngagementRelevancePolicy.sample()` through one typed, reusable result owned by
   the policy/caller boundary. Preserve every scalar and release reason.
4. Candidate B: cache tick-invariant viewport rectangles and other invariant query inputs
   outside due-enemy loops. This is relevant only when the corresponding path is active.
5. Candidate C: inspect repeated line-of-sight queries and movement-profile lookups inside
   `_desired_enemy_velocity()`. Reuse a result only when input equality proves behavior
   equivalence; do not merge different collision paddings by approximation.
6. Re-run a short focused owner profiler after one causal change. Do not run the 60-second
   release scenario during iteration.
7. After all gameplay and visual work is complete, run the clean native 84 workload. Run
   built Web only if native is scenario-valid and passes. Preserve a failed result and stop
   before any threshold, collision, activity, resolution, or physics-rate reduction.

## Acceptance evidence required

- Pattern validator: no common attack in production boss sequences; every direct kind has
  an execution branch; no immediate repeat; phase order is deterministic.
- Runtime validator: each boss produces its three named exams, every delayed footprint has
  matching warning/damage geometry, and later-boss direct system attacks are not no-ops.
- Attention validator: autonomous systems do not commit during a signature peak; ordinary
  bodies remain present and exact; ordinary attack budgets resume in recovery.
- Encounter validator: all eight quotas, caps, floors, authored reserve, boss seal, and
  maintenance watermarks are exact and never exceed fixed stores.
- Progression validator: new minimum-path XP and level cadence are explicit and catalog
  exhaustion behavior remains truthful.
- Visual evidence: one final background capture batch containing one signature startup and
  active state per boss at supported scale; no repeated interactive game launches.
- Performance evidence: exact clean native and built-Web results at the final 84-cap
  workload with precise pass labels.

## Claude Code review status

- Opus job `20260815T162800522Z-7610f5b7-13f3-4e60-9cd3-427fe9cca78f` ran read-only for
  467.716 seconds and then failed at the provider session limit. Its immutable answer is
  stored at `C:\Users\BK\.codex\tools\model-cli-mcp\logs\jobs\20260815T162800522Z-7610f5b7-13f3-4e60-9cd3-427fe9cca78f\answer.md`.
- Sonnet retry `20260815T163715774Z-cfb12fa5-667e-4a57-b86c-438d843dc3c9` confirmed the
  same provider-wide limit. No model timeout was set on either job.
- The provider reports a reset at 06:20 Asia/Seoul. The successful read-only report will be
  added here and checked against source before this evidence is promoted into the execution
  contract.

## Limitations

- No new runtime capture or performance scenario was run during research.
- The proposed 84 cap is a product target, not a performance claim.
- Still images cannot validate temporal safe gaps or mixed-layer reaction time.
- External sources provide design principles, not Cardborne-specific balance numbers.
