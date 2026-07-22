---
type: plan
status: active
owner: BK
created: 2026-07-22
last_reviewed: 2026-07-22
scope: Five-stage vehicle map clarity, collectible experience progression, boss threat, combat HUD, and bounded difficulty refinement
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
---

# Vehicle Map, Progression, Boss, and HUD Refinement ExecPlan

## Purpose

Refine the current five-stage vehicle game without replacing its accepted flat-color
Sunken Ceramic Fresco direction. The result must make collision boundaries obvious,
make every intended passage comfortable, turn enemy defeats into collectible experience,
offer upgrades more frequently, make each boss actively threatening, and reduce HUD
occlusion while preserving the current controls, stage identities, and deliberate
three-choice upgrade flow.

This is an execution plan, not permission to adopt the deferred black-floor/white-wall
direction. The first playable checkpoint is a complete Flooded Works vertical slice;
the remaining stages follow only after that slice is visually and mechanically valid.

## Why / Current Context

The current build is internally consistent with its old contracts, but those contracts
do not cover the reported failures:

- `vehicle_stage_backdrop.gd` renders walkable and blocking rectangles as chamfered
  polygons, while `vehicle_stage_catalog.gd` and `vehicle_stage_rules.gd` collide
  against the original full rectangles. The invisible rectangular corners can block a
  vehicle where the drawing appears open.
- The route validator proves that selected landmarks are reachable on a 56-70 px grid.
  It does not enumerate every visible opening, enforce a comfortable minimum corridor
  width, include route obstruction from live crates, or compare the rendered mask with
  the collision mask.
- Static cover uses a deep-blue shadow, ceramic-green body, and lighter green cap.
  Dynamic gates add more state colors. These layers weaken the requested single wall
  color and make some blockers look like decoration or floor variation.
- The runtime has no experience or run-level model. Enemy death increments statistics
  directly, while each stage separately authors eight field pickups, five crates, and
  three mandatory upgrade transactions.
- The field catalog currently exposes nine pickup families: repair, major repair,
  attack, cadence, movement, barrier, seeker, opening-shot reserve, and magnet effects.
  This duplicates behavior that belongs in the card build and makes floor objects hard
  to identify at combat speed.
- Enemy health, speed, projectile speed, damage, and recovery use one global multiplier
  for the whole run. Later stages increase authored population and role complexity but
  do not have a small explicit stage-stat curve.
- Stages 1-3 share one generic boss sequence. Stage 4 repeats only `switch_charge` and
  stage 5 alternates only beam and carrier behaviors. Their long read/startup/recovery
  chain and sparse pattern sets explain why bosses can appear inactive.
- At 1280x720 the live HUD reserves 282x84 for hull, 500x72 for the objective,
  218x144 for the minimap, up to 240x124 for the target, and 724x82 for the bottom
  action rail. At 960x540 the compact layout still substantially covers combat space;
  notifications and boss state can overlap attack telegraphs.

### Baseline evidence

- Branch and revision at plan creation: `master` at `c5b0880`.
- Rendered evidence inspected:
  `build/captures/2026-07-22-pressure/{960x540,1280x720}/`, especially open combat,
  installations, upgrade selection, all later-stage views, and the stage boss.
- Existing validators pass because they assert the previous contract:
  `validate_vehicle_stage_layouts.gd`, `validate_vehicle_rewards_ui_audio.gd`,
  `validate_vehicle_upgrade_system.gd`, and `validate_vehicle_run.gd`.
- Existing CPU pressure baseline:
  - Standard: 30 active, 2.600 ms combined measured step.
  - Onslaught: 48 active, 5.295 ms combined measured step.
  - Both are under the existing 8 ms headless evidence threshold.

## Scope

### In scope

- One shared visual/collision/minimap representation for floor, cover, gates, and
  reflector blockers.
- One wall/blocker fill color across all five stages.
- Reauthoring interior cover and pickup/crate placement to remove false openings and
  narrow passages.
- Collectible experience shards, run levels, queued level-up choices, and a compact XP
  display.
- Exactly two field pickup behaviors: repair and collect-all-experience.
- Migration of temporary field buffs into understandable card upgrades.
- Periodic shield, attack, and movement upgrades with player-adjacent radial timing.
- Damage lifesteal that applies to all player-owned combat damage through one damage
  result path.
- Small stage-by-stage enemy stat growth plus a modest simultaneous-pressure increase.
- Distinct field-boss accents and four distinct attacks for every stage boss.
- A smaller combat HUD, icon/radial cooldown presentation, Korean/English fit, and
  rendered QA at supported viewports.
- Product/design specification updates and replacement of validators that encode the
  retired reward and layout contracts.

### Non-scope

- Black walkable floor, white blockers, or a monochrome player/enemy redesign. These
  require a separate actor/readability decision after this plan is playable.
- New vehicle or enemy silhouettes, raster asset generation, or external asset packs.
- New stages, new enemy archetypes, exploration puzzles, procedural generation, or
  persistent metagame currency.
- A separate ore currency. This plan uses one run-only experience resource so deaths
  do not create multiple ambiguous floor drops.
- Control changes, audio replacement, equipment repair, base-stage systems, or save-file
  expansion beyond the current persistent settings/modules.

## Assumptions

- Godot 4.7 stable and GDScript remain the runtime.
- Korean remains the default locale and English remains fully supported.
- Player collision radius remains 24 px and the current 120 base hull remains the
  balance reference.
- The current mustard player, coral ordinary enemies, magenta bosses, ivory floor,
  cobalt void, and flat large-shape art language remain active.
- The active run build and experience reset on replay. Settings and earned persistent
  modules retain their current persistence behavior.
- Standard is the primary balance target. Onslaught remains an explicitly denser
  preset, not the source of Standard tuning.

## Locked Decisions

### 1. Map geometry and blocker presentation

- Add `scripts/vehicle/vehicle_stage_geometry.gd` as the single geometry owner.
  Stage-authored floor and cover entries expose one polygon plus cached bounds; world
  drawing, player/projectile collision, line of sight, minimap rasterization, and
  validation consume that same polygon.
- Preserve chamfered large shapes only when the chamfer is part of the shared polygon.
  Never draw a chamfered polygon and collide against its uncut rectangle.
- Define `BLOCKER_FILL = Color("#07564C")` in
  `vehicle_stage_visual_profile.gd`. Every static wall, cover body, closed boss gate,
  active switch gate, and closed vault gate uses this exact fill.
- Remove alternate green caps and blocker shadows from collision-bearing geometry.
  Dynamic state is shown with a large mustard/mint sigil or motion cue, not by changing
  the blocker fill.
- Floor and void keep their current semantic colors. The proposed black/white palette
  is recorded as deferred and must not leak into this implementation.
- Any opening presented as passable must provide at least 168 px of edge-to-edge clear
  width. Main travel/combat lanes must provide at least 320 px. Turning pockets at a
  bend or branch must provide at least 240x240 px.
- Any visual gap below 168 px is either widened or sealed as one continuous blocker;
  it may not remain as a misleading slit.
- Static interior-cover budgets are:

  | Stage | Maximum static cover shapes | Additional stateful blockers |
  | --- | ---: | --- |
  | Flooded Works | 9 | boss gate |
  | Tidal Archive | 10 | boss gate |
  | Storm Drydock | 9 | boss gate |
  | Coral Switchyard | 9 | two active switch gates and boss gate |
  | Abyssal Observatory | 8 | reflectors, vault gate, and boss gate |

- Outer silhouettes, water/void boundaries, boss gates, and one or two intentional
  combat-cover islands carry the map structure. Long paired interior walls that form
  narrow channels are removed or replaced by isolated cover islands.
- Alive crates and static installations are included in clearance validation. They may
  not reduce a required route below 168 px or occupy the only turning pocket.
- The player start and every stage transition retain a 360 px obstacle-free radius.

### 2. Experience, levels, and field rewards

- Enemy defeats award no experience directly. An XP-awarding enemy creates exactly one
  `experience_shard` at its defeat position; experience is added only when the shard is
  collected by proximity or by `experience_recall`.
- Shards are simple mustard geometric forms with no text or physics bounce:
  diamond for value 1, hexagon for value 2-4, and a larger sun/core shape for boss
  value. Size communicates value in addition to color.
- XP values are:

  | Source | XP |
  | --- | ---: |
  | Authored swarm enemy | 1 |
  | Authored standard enemy | 2 |
  | Authored priority enemy or installation | 4 |
  | Field boss | 18 |
  | Stage boss | 24 |
  | Carrier child, boss summon, or respawned pylon | 0 |

- Summoned enemies grant zero XP to prevent farming. Their parent already grants the
  authored reward.
- Keep at most 192 live shard entries. At the cap, merge the new value into the nearest
  shard within 160 px, otherwise into the oldest shard; total uncollected XP must be
  preserved exactly.
- Run level starts at 1. Required XP for the next level is
  `min(72, 26 + 3 * (run_level - 1))`. Excess XP carries into the next level.
- A reached level queues one mandatory three-card offer, pauses simulation, preserves
  the existing 0.35-second input guard, and requires select then confirm. Multiple
  earned levels resolve sequentially without losing XP or applying a card twice.
- A full-clear route should produce 4-6 XP level-ups per stage. A player who takes the
  ordinary exit without clearing all optional enemies simply earns fewer upgrades.
- Calibration and relay caches stop opening fixed card modals. They release collectible
  XP clusters worth 18 and 30 XP respectively. Stage-boss defeat still yields one
  mandatory boss card; an optional field boss still yields one optional card.
- A stage boss drops its large XP shard and enters a pending-reward state. Collecting
  that shard opens the mandatory boss offer; confirming the offer completes the stage.
  This preserves the rule that awarded XP must be collected.
- If a field-boss or stage-boss shard crosses one or more level thresholds, resolve the
  queued mandatory level-up offers first, then the field-boss or stage-boss offer. Only
  one modal transaction may exist at a time, and stage completion waits for the entire
  queue.
- Exactly two field pickup kinds remain:
  - `repair`: one behavior with an authored `heal_amount` (35 normally, 70 for a
    field-boss reward) and the existing mint recovery role.
  - `experience_recall`: collects every active experience shard on the current map over
    a short 0.65-second inward sweep. It does not collect repair pickups, unopened
    crates, caches, or objectives.
- Each stage authors two repair pickups and one experience-recall pickup. Its five
  crates contain four repairs and one experience recall. Random group-completion field
  items are removed; individual shards are the consistent combat reward.
- Individual XP shards do not appear on the minimap. The two field pickup kinds retain
  discovered minimap markers so the map does not become a cloud of tiny reward dots.

### 3. Upgrade catalog and timed effects

- Add `level_up` as the primary source tag. The first level-up offer keeps the current
  guarantee of one primary, one element, and one passive/mobility direction. Later
  offers retain compatible, non-duplicate, behavior-first three-card selection.
- Retire `field_converter` because temporary field durations and barrier field items no
  longer exist.
- Retire the pickup-triggered `salvage_booster`. Replace the two retired definitions
  with four explicit cards, for a catalog total of 43:

  | Card | Levels | Exact behavior |
  | --- | ---: | --- |
  | Aegis Cycle | 2 | Every 14 s, create 20/28 barrier for 5/6 s. |
  | Overclock Cycle | 2 | Every 12 s, grant +25%/+35% player-owned damage for 4 s. |
  | Thruster Cycle | 2 | Every 10 s, grant +20%/+28% move speed for 3.5 s. |
  | Siphon Matrix | 2 | Heal 2%/3.5% of actual post-mitigation health damage, capped at 6 hull/s. |

- Selecting a cycle card demonstrates it immediately, then begins its normal recharge.
  Re-selecting upgrades the same timer and does not create a duplicate status entry.
- Siphon Matrix applies to primary shots, opening shots, seekers, EMP, dash/ram damage,
  trails, and player-owned burn/poison ticks. It excludes overkill, crates, invulnerable
  targets, reflected self-damage, and non-health structure damage. All qualifying
  routes report actual damage through one damage-result path so healing cannot trigger
  twice.
- `pickup_magnet` applies to experience-shard proximity only. Existing seeker, opening,
  damage, cadence, movement, EMP, and barrier cards remain normal upgrades rather than
  floor-item effects.
- The three cycle effects are the only recurring timed upgrades in this pass. This
  bounds the amount of player-adjacent status UI and avoids hidden overlapping timers.

### 4. Player-adjacent status UI

- Add `scripts/ui/vehicle_status_orbit.gd`. It renders at fixed screen-pixel scale
  around the projected vehicle, not in world scale.
- Show at most three 24 px badges on a 62 px orbit. Aegis uses a hexagon, Overclock a
  triangle/star, and Thruster a double-chevron. The existing off-screen threat radar
  remains outside them at its 96 px arc radius.
- During recharge, a 3 px radial arc fills clockwise. During the active window, the
  full arc changes to the effect accent and drains clockwise. Shape and fill direction
  communicate state without relying on color alone.
- No timer text appears around the vehicle. Pause/settings exposes localized names and
  exact values. Reduced-motion mode disables pulse/rotation while preserving arc state.
- Lifesteal uses a short mint hull pulse on successful healing, not a persistent fourth
  ring and not repeated notification text.

### 5. Enemy pressure and modest stage scaling

- Add `scripts/enemies/vehicle_stage_difficulty.gd`; do not scatter stage checks through
  enemy behavior code.
- Apply this curve to authored swarm, standard, priority, installation, and carrier-child
  health/damage/speed. Field bosses and stage bosses use their explicit profiles below.

  | Stage | Health | Damage | Move speed |
  | --- | ---: | ---: | ---: |
  | 1 | 1.00 | 1.00 | 1.00 |
  | 2 | 1.04 | 1.03 | 1.01 |
  | 3 | 1.08 | 1.06 | 1.02 |
  | 4 | 1.12 | 1.09 | 1.03 |
  | 5 | 1.16 | 1.12 | 1.04 |

- The curve applies after archetype values and before the current global difficulty
  multiplier. Do not add stage scaling to projectile speed, attack startup, recovery,
  denial duration, or ranged/denial concurrency; readability may not degrade with stage.
- Change Standard active caps from `1/14/20/26/30` to `1/15/22/28/32` and Standard
  threat budgets from `1.0/3.0/4.25/5.0/6.0` to `1.0/3.0/4.5/5.25/6.25`.
- Change Onslaught active caps from `1/20/30/40/48` to `1/22/33/44/52`; keep its 7.5
  threat budget. Keep at most three ranged and two denial commits in both presets.
- Do not increase authored population bands in this pass. The small cap/stat changes
  provide the requested difficulty increase without reintroducing the recent frame-time
  and stage-1 pressure problems.

### 6. Boss threat and stage identity

- Store pattern data in `scripts/bosses/vehicle_boss_patterns.gd`; keep execution in
  responsibility-shaped boss helpers rather than adding another large match block to
  `vehicle_run.gd`.
- Stage-boss health is authored as 1250/1350/1450/1550/1650 across stages 1-5.
  Field-boss health is 560/590/620/650/680. Bosses do not receive the ordinary stage
  health curve on top of these values.
- Each stage boss owns four attacks and a distinct phase-two sequence:

  | Stage | Four attacks | Intended effective hit damage on Standard |
  | --- | --- | --- |
  | Flooded Works | Twin Foundry Lanes, Foundry Ram, Furnace Ring, Pylon Overload | 20 / 34 / 26 / 24 |
  | Tidal Archive | Current Fan, Undertow Sweep, Depth Charge, Archive Ram | 20 / 28 / 32 / 34 |
  | Storm Drydock | Arc Lanes, Grounded Ring, Thunder Drop, Escort Surge | 22 / 28 / 34 / 24 |
  | Coral Switchyard | Open-Lane Charge, Gate Shockwave, Ricochet Volley, Switch Sweep | 36 / 28 / 22 / 30 |
  | Abyssal Observatory | Crown Beam, Mirror Cross, Carrier Wave, Relay Pulse | 34 / 28 / summon / 30 |

- Damage values in the table are final effective hull damage after the Standard global
  damage multiplier. Store raw values through the central damage scaler and validate
  the final result to prevent accidental double scaling.
- Ordinary boss hits stay in the 20-30 hull band; committed signature attacks stay in
  the 32-36 band. No single clean hit exceeds 30% of the base 120 hull.
- Every damaging pattern has at least 0.8 s startup; signature attacks have at least
  1.1 s. Active windows are 0.4-1.1 s and recovery is 0.9-1.6 s. While the player is in
  the arena, the next startup begins no later than 2.4 s after the prior damage window.
- Only one major damage window may be active at once. Summon patterns release at most
  three children and cannot overlap a beam, ram, or large denial window.
- Phase two changes attack topology or ordering; it does not merely shorten every timer.
  Every attack still exposes startup, active, and recovery.
- Each field boss receives three patterns: one readable ram, one area attack, and one
  stage-specific verb (foundry ring, current fan, lightning line, open-lane rush, or
  reflected beam). Field-boss signatures target 26-32 effective damage and obey the
  same no-overlap rule.

### 7. Compact combat HUD

- Replace the five large hull pips with one 184x54 hull/XP cluster (168x50 at 960 px):
  hull icon, continuous hull bar and number, run level, and a 6 px XP bar.
- Replace the 500x72 objective panel with a maximum 360x44 chip (300x40 at 960 px).
  Show localized detail for three seconds when the objective changes, then collapse to
  the one-line objective title.
- Reduce the minimap to 168x112 at 1280+ and 144x96 at 960. Preserve player, blockers,
  objectives, rewards, boss, discovered cells, and fog; do not add XP-shard dots.
- Replace the 724x82 text rail with a maximum 276x60 icon cluster. Primary fire gets a
  64 px icon; passive, dash, and EMP get 52 px icons. Each uses radial readiness/cooldown
  fill plus a short binding label. Exact names remain available in settings/help.
- Reduce the target panel to 184x64 and show it only for the current aimed priority
  target or boss sub-objective. Remove verbose enemy-state prose from ordinary combat.
- Use a 520x40 maximum boss strip at top center. World telegraphs communicate the active
  pattern; the strip shows only localized boss name, phase, and hull.
- Replace the wide buff text row with the status orbit plus a maximum three-icon compact
  exceptional-status tray. Use a maximum 360x36 toast and queue messages so they do not
  overlap the boss strip or attack warnings.
- At 960x540, opaque combat HUD panels must cover at most 12% of viewport area. No opaque
  panel may enter the central 60% by 60% combat rectangle. Modal layers are exempt.
- Preserve at least 44 px targets in settings and modals, deterministic keyboard focus,
  the select-then-confirm upgrade transaction, and text fit in Korean and English.

## Proposed Ownership and File Delta

| Responsibility | Owner / change |
| --- | --- |
| Shared polygon geometry and clearance helpers | New `scripts/vehicle/vehicle_stage_geometry.gd`; update catalog/rules/backdrop/minimap consumers |
| Five authored layouts | Update `scripts/vehicle/stages/*.gd` |
| Blocker color/scale contract | Update `scripts/vehicle/vehicle_stage_visual_profile.gd` |
| XP thresholds, carry, queues, shard merge | New `scripts/progression/vehicle_experience_runtime.gd` |
| Allowed field drops and values | New `scripts/rewards/vehicle_field_drop_rules.gd` |
| Stage stat curves | New `scripts/enemies/vehicle_stage_difficulty.gd` |
| Timed card effects | New `scripts/cards/vehicle_cycle_runtime.gd`; update card resources/catalog/build |
| Actual damage/lifesteal hook | Return an actual-damage result from the shared enemy-damage path; keep one hook under `scripts/combat/` |
| Boss pattern data | Expand `scripts/bosses/vehicle_boss_patterns.gd`; extract execution helpers if needed |
| Compact HUD and XP snapshot | Update `scripts/ui/vehicle_stage_ui.gd`; add `vehicle_status_orbit.gd` and reusable radial indicator |
| Runtime orchestration | Update `scripts/vehicle/vehicle_run.gd` only to connect the owners above |
| Localization | Update Korean/English CSV keys for XP, cards, status, bosses, and compact labels |
| Contracts | Update product/design specs and focused validators listed below |

`vehicle_run.gd` must not absorb XP curves, drop tables, stage scaling tables, radial
drawing code, or boss content tables. It may coordinate their results and publish the
HUD snapshot.

## Tasks

### Milestone 0 - Lock replacement contracts before runtime edits

- [ ] Update `docs/product/vehicle_game_spec.md` with the locked XP values/curve, two
  field pickups, 43-card catalog, reward cadence, stage scaling, caps/budgets, and boss
  damage/timing bands.
- [ ] Update `docs/design/UI_VISUAL_SYSTEM.md` with one blocker fill, exact shared-shape
  requirement, corridor rules, compact HUD bounds, and status-orbit semantics.
- [ ] Add failing focused assertions for the new contracts before deleting old
  assertions such as nine pickup families, eight pickups per stage, 41 cards, and 15
  mandatory fixed rewards.
- [ ] Record the black/white direction as deferred in the spec decision notes, without
  adding dormant palette constants or feature flags.

Acceptance: another implementer can derive every value and behavior in this plan from
the active specs without making a product decision.

### Milestone 1 - Build the Flooded Works vertical slice

- [ ] Add shared polygon geometry and migrate Flooded Works floor, cover, boss gate,
  collision, line of sight, projectile blocking, and minimap rendering to it.
- [ ] Reauthor Flooded Works to at most nine static cover shapes, 168 px minimum visible
  openings, 320 px main lanes, and 240x240 turning pockets.
- [ ] Apply the single blocker fill and remove alternate wall caps/shadows.
- [ ] Add experience shards, XP carry/level queue, the level-up source, two field pickup
  behaviors, and stage-1 authored placements/crate drops.
- [ ] Convert Flooded Works calibration/relay caches to 18/30 XP clusters and route the
  boss core through pending reward -> collection -> mandatory card -> stage result.
- [ ] Add the four Flooded Works boss attacks and its three-pattern field boss.
- [ ] Implement compact hull/XP, objective, minimap, action cluster, status orbit, target,
  boss strip, and queued toast for this slice.
- [ ] Render and manually play the complete stage in Korean at 960x540 and 1280x720.

Acceptance: a fresh player can identify every wall before contact, traverse every visible
opening without scraping, collect kill XP, receive at least one early level-up, identify
the only two field items, read all four boss attacks, and finish the stage without HUD
covering a telegraph.

### Milestone 2 - Apply geometry and reward clarity to stages 2-5

- [ ] Migrate every floor/cover/dynamic blocker to shared polygons.
- [ ] Meet each stage's static-cover budget and all clearance/turning-pocket rules.
- [ ] Reposition crates, installations, reward anchors, and pickups so no required route
  loses clearance in any legal dynamic-gate/reflector state.
- [ ] Ensure switch gates, vault gates, reflectors, world drawing, collision, and minimap
  change from the same state and geometry in the same frame.
- [ ] Replace all stage pickup/crate tables with two repairs, one experience recall, four
  repair crates, and one recall crate.
- [ ] Capture a collision-overlay evidence image for every stage and every stateful
  blocker configuration.

Acceptance: exact mask comparison reports no visual/collision mismatch, every required
and optional route passes, and no visible sub-168 px slit remains.

### Milestone 3 - Complete run progression and card migration

- [ ] Apply XP values to all 19 archetypes with zero-reward flags for summons.
- [ ] Enforce 192-shard merging without loss of total XP and without per-shard Nodes.
- [ ] Queue and resolve multiple level-ups safely across combat, field-boss, boss, pause,
  death, replay, and stage transitions.
- [ ] Remove all seven retired temporary item behaviors and random group item drops.
- [ ] Retire `field_converter` and `salvage_booster`; add Aegis, Overclock, Thruster, and
  Siphon resources, localization, previews, source tags, and exact value tests.
- [ ] Route every player-owned damage family through one actual-damage/lifesteal result.
- [ ] Confirm a full-clear deterministic run yields 4-6 XP levels per stage plus one
  mandatory boss choice, while skipping optional combat produces fewer choices.

Acceptance: no experience is granted before collection, no field pickup grants a hidden
temporary combat stat, every card description states exact values, and replay resets XP,
level, pending choices, cycles, and lifesteal state.

### Milestone 4 - Apply bounded enemy scaling and pressure

- [ ] Add the stage curve owner and apply it exactly once to the allowed archetype
  classes.
- [ ] Update Standard and Onslaught caps/budgets while preserving 3 ranged / 2 denial
  commits and current spawn-introduction pacing.
- [ ] Validate effective stage-1 and stage-5 health/damage/speed ratios, including
  projectiles, DOT ownership, contact attacks, and carrier children.
- [ ] Verify priority enemies remain readable and later enemies do not become sponges.
- [ ] Run the pressure profiler with 32/52 active units and 192 pending XP shards.

Acceptance: Standard combined measured step remains below 8 ms, active caps never exceed
32/52, and stage scaling does not modify startup, recovery, projectile speed, or denial
duration.

### Milestone 5 - Complete stage-specific bosses

- [ ] Implement the four locked attacks and distinct phase-two order for stages 2-5.
- [ ] Implement the stage-specific field-boss verb in every stage.
- [ ] Centralize raw-to-effective boss damage and validate every listed Standard value.
- [ ] Validate startup, active, recovery, maximum idle gap, summon cap, and no-overlap
  constraints through deterministic boss simulations.
- [ ] Render one startup, one active window, one recovery, and one phase-two composite
  for every stage boss at 1280x720.
- [ ] Manually play every boss without upgrades and with a representative full-clear
  build to check threat and survivability at both ends.

Acceptance: every stage boss uses all four attacks in a bounded simulation, no stage
shares an identical sequence, each signature hit matters, and no unavoidable same-frame
major damage stack occurs.

### Milestone 6 - Finish HUD, localization, accessibility, and modal states

- [ ] Apply the compact HUD dimensions and 12% occlusion budget at 960x540, 1280x720,
  and 1920x1080.
- [ ] Verify the status orbit against the threat radar under three simultaneous cycles,
  a targeted priority enemy, projectiles, and a boss telegraph.
- [ ] Add full Korean/English copy and text-fit tests for XP, level-up, two pickups, four
  new cards, all boss attacks/states, and compact action labels.
- [ ] Verify keyboard focus, explicit confirmation, input guard, pause/resume, locale
  switching, and reduced-motion state.
- [ ] Review color-plus-shape semantics, contrast, clipping, overflow, and central combat
  visibility at all supported viewports.

Acceptance: no required label clips in Korean or English, no combat panel enters the
central safe rectangle, and timers remain understandable without color or animation.

### Milestone 7 - Final validation, build, and durable handoff

- [ ] Run every focused validator and the full vehicle validator.
- [ ] Run `profile_vehicle_pressure.gd` for Standard and Onslaught.
- [ ] Produce the normal web build with `tools/export_web.ps1` and launch the built app
  through the project's production-style path.
- [ ] Capture ordinary combat with maximum supported pressure and uncollected XP, every
  map, a level-up modal, all timed effects, both field pickups, and every boss in Korean;
  repeat layout-critical screens in English.
- [ ] Perform a complete five-stage Standard run and targeted Onslaught pressure run.
- [ ] Use the codebase quality audit on the multi-file implementation and make only safe,
  task-scoped corrections.
- [ ] Incorporate accepted behavior into the product/design specs, remove obsolete
  comments/localization/tests, and delete this completed ExecPlan per `.agents/PLANS.md`.

Acceptance: the built app, not only the editor/headless runtime, passes the relevant
manual flows and the active specs fully describe the shipped behavior.

## Test Plan

### Automated commands

Run with Godot 4.7 through the repository wrapper:

```powershell
.\tools\godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_navigation_clearance.gd
.\tools\godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_experience.gd
.\tools\godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_boss_patterns.gd
.\tools\godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_upgrade_system.gd
.\tools\godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_encounter_pacing.gd
.\tools\godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_rewards_ui_audio.gd
.\tools\godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_stage_layouts.gd
.\tools\godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_run.gd
.\tools\godot.ps1 --headless --path . --script res://tools/validation/profile_vehicle_pressure.gd
```

### New focused validator contracts

- `validate_vehicle_navigation_clearance.gd`
  - uses exact shared polygons, not a coarse approximation;
  - compares visual, movement, projectile, line-of-sight, and minimap masks;
  - checks 168/320 px widths, 240 px turns, 360 px starts, cover budgets, crates,
    installations, boss gates, all switch states, and both reflector/vault states.
- `validate_vehicle_experience.gd`
  - proves no direct kill XP, single collection, recall behavior, XP carry, threshold
    formula, multiple queued levels, zero-XP summons, 192-entry merging, boss pending
    reward, two pickup families, and replay reset.
- `validate_vehicle_boss_patterns.gd`
  - proves four unique stage-boss patterns per stage, three field-boss patterns, phase
    changes, timings, effective damage bands, maximum idle gap, summon caps, and no
    overlapping major windows.

### Rendered evidence matrix

| Surface/state | 960x540 | 1280x720 | 1920x1080 | KO | EN |
| --- | ---: | ---: | ---: | ---: | ---: |
| Arrival and first objective | yes | yes | yes | yes | yes |
| Maximum Standard pressure + XP field | yes | yes | yes | yes | layout check |
| Three cycle timers + threat radar | yes | yes | yes | yes | layout check |
| Level-up select and confirm | yes | yes | yes | yes | yes |
| Repair and experience recall | yes | yes | yes | yes | layout check |
| Each stage map + collision overlay | layout | yes | layout | yes | n/a |
| Each stage boss startup/active/recovery | layout | yes | layout | yes | layout check |
| Pause/settings/reduced motion | yes | yes | yes | yes | yes |

Rendered review must explicitly check alignment, typography, spacing, overflow, clipping,
central-map occlusion, blocker recognition, player visibility, telegraph visibility,
icon/shape distinction, and motion-independent timer comprehension.

## Validation Cadence

- After geometry ownership: navigation-clearance and stage-layout validators.
- After XP/drop ownership: experience, reward, and upgrade validators.
- After each boss stage: boss-pattern validator plus one rendered capture.
- After HUD changes: full UI contract at all three viewports and both locales.
- After cap/scaling changes: encounter pacing, full run, and pressure profile.
- Before every milestone commit: relevant focused validators plus `git diff --check`.
- Before handoff: all commands and the production-style built-app review.

## Rollback and Safety

- Implement each milestone as a coherent scoped commit; do not mix unrelated repository
  changes into these commits.
- There is no external dependency or asset-pack change in this plan.
- Experience and cycle state are run-local, so no persistent save migration is required.
- Preserve a playable Flooded Works checkpoint before applying the geometry schema to
  the remaining four stages.
- If a later-stage migration fails, revert only that stage's authored data and keep the
  shared geometry owner; do not restore the known visual/collision mismatch.
- Never solve a performance regression by silently deleting XP value, committed enemies,
  or telegraphs. Merge shard entries, reduce redraw work, or profile the responsible
  owner first.

## Risks and Mitigations

- **Frequent modal interruption:** Target 4-6 level-ups per full-clear stage, queue
  simultaneous levels, and retain boss-only mandatory authored rewards instead of the
  old three fixed rewards per stage.
- **Uncollected shard accumulation:** Use array-backed drawing, 192-entry value-preserving
  merge, zero-XP summons, and the experience-recall field item.
- **Lifesteal double triggers:** Base healing only on one returned actual-damage result;
  test every damage family, DOT, overkill, shields, and invulnerability.
- **Reduced walls flatten tactics:** Preserve outer silhouette, one or two intentional
  cover islands, stage mechanics, and wide flanking lanes; remove only clutter and false
  corridors.
- **Status orbit conflicts with threat radar:** Keep 24 px badges at radius 62 and threat
  arcs at radius 96; validate maximum simultaneous state at gameplay zoom.
- **Difficulty stacking:** Keep the stage curve small, exclude boss/projectile/recovery
  double scaling, retain commit ceilings, and validate final effective damage.
- **Boss spectacle obscures danger:** One major damage window at a time, flat large
  telegraphs, no micro-particles, and HUD occlusion checks during every boss capture.

## Open Questions

None for this execution pass. The black-floor/white-blocker direction and a matching
player/enemy redesign are explicitly deferred change-control decisions, not unresolved
implementation details.

## Decision Notes

- 2026-07-22: Preserve the accepted semantic palette for now; unify blockers to one
  ceramic-green fill and defer full black/white art direction.
- 2026-07-22: Use one collectible XP resource rather than separate ore and XP, because a
  second currency is not yet connected to a persistent economy and would add floor noise.
- 2026-07-22: Replace calibration/relay card interruptions with collectible XP clusters;
  keep boss and optional field-boss card rewards for authored milestones.
- 2026-07-22: Set 168 px as the minimum presented passage because the collision diameter
  is 48 px and the visual vehicle diameter is approximately 84 px; this leaves useful
  steering margin rather than merely proving mathematical reachability.
- 2026-07-22: Increase simultaneous pressure modestly and leave authored population
  unchanged, because recent play feedback already identified both high difficulty and
  frame-time sensitivity.
- 2026-07-22: Treat boss damage values as final effective Standard damage and validate
  after global scaling to prevent accidental double multiplication.

## Next Steps

1. Complete Milestone 0 so the product, visual, and failing validator contracts reflect
   this plan before runtime behavior changes.
2. Build and validate only the Flooded Works vertical slice from Milestone 1.
3. Review that playable slice against its acceptance statement before migrating stages
   2-5 or applying the later-run balance curve.

## Progress

- [x] Read repository operating instructions, active product/design specs, current code,
  validators, recent revision, and rendered captures.
- [x] Record baseline validation and CPU pressure evidence.
- [x] Lock product decisions and implementation boundaries in this plan.
- [ ] Milestone 0 - replacement contracts.
- [ ] Milestone 1 - Flooded Works vertical slice.
- [ ] Milestone 2 - remaining map geometry and reward clarity.
- [ ] Milestone 3 - full-run progression and cards.
- [ ] Milestone 4 - enemy scaling and pressure.
- [ ] Milestone 5 - stage-specific bosses.
- [ ] Milestone 6 - HUD/localization/accessibility.
- [ ] Milestone 7 - build, final QA, specs, and plan retirement.

## Completion and Handoff

Completion requires every milestone acceptance statement, all automated commands, the
rendered evidence matrix, a production-style built-app check, and current product/design
specifications that contain the accepted behavior. When those conditions are satisfied,
marking this plan complete is not sufficient: incorporate any final decisions into the
active specs and delete this file as required by `.agents/PLANS.md`.

If work stops mid-plan, the handoff must name the last completed milestone, current
commit, failing command or visual state, remaining unchecked item, and the exact capture
or log path that demonstrates the blocker.
