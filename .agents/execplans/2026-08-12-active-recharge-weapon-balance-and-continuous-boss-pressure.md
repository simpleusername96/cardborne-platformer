---
type: plan
status: active
owner: BK
created: 2026-08-12
last_reviewed: 2026-08-12
topic: Active-weapon combat recharge, weapon balance, continuous ordinary boss pressure, facility removal, and boss offense
scope: Player weapons, damage receipts, boss-gated encounter flow, boss offense, reinforcement-facility removal, compact combat HUD contracts, product specifications, and focused validators
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../design/DESIGN.md
  - ../cardborne-performance-engineering-policy.md
  - ../cardborne-runtime-architecture-audit.md
  - ./2026-08-11-half-scale-continuous-stage-flow.md
  - ./2026-08-11-dense-combat-progression-and-run-completion.md
  - ./2026-08-12-player-facing-language-simplification.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/product/vehicle_upgrade_catalog.md
  - ../../docs/reports/2026-08-12-cardborne-upgrade-feedback.json
  - ../../docs/design/VISUAL_SYSTEM.md
---

# Active Recharge, Weapon Balance, and Continuous Boss Pressure

Combat must recharge the equipped active weapon often enough that it becomes a
regular part of the player's rotation. Recharge must not scale without bound with
primary-fire rate, piercing, damage-over-time ticks, or enemy density. Every
weapon family must be compared by intended role, reliability, coverage, damage,
control, and cadence at every level. Reaching the stage defeat quota only unlocks
the boss; it does not stop ordinary arrivals. The reinforcement facility is
removed. Boss health and shield durability stay unchanged while boss damage and
attack frequency increase. The top HUD continues to show Dash, the built-in
secondary weapon, and the equipped active weapon, with no primary cooldown slot.

## Purpose

- Add bounded combat recharge that makes active weapons available roughly 29% sooner under
  sustained successful offense and at most about 36% faster when the incoming-hit
  bonus is also continuously available.
- Establish one durable role-based balance contract for primary upgrades, damage
  and utility attributes, built-in and optional secondaries, and active weapons.
- Correct Cross Beam's low practical reliability with moderate width, damage,
  startup, and cooldown changes instead of one extreme compensation.
- Make defeat quota a boss-arrival threshold only. Ordinary authored arrivals
  continue during warning and the boss fight.
- Delete reinforcement-facility gameplay, presentation, assets, guidebook,
  minimap, localization, validation, and active-document surfaces.
- Increase boss offense without increasing health, shield durability, adds,
  coverage, projectile speed, or reducing telegraphs.
- Preserve the compact top HUD. It already has no primary cooldown; the apparent
  primary slot is Seeker, Cardborne's built-in secondary.

Completion means implementation, product specifications, focused validators, and
player-facing surfaces express the same contracts. This planning pass does not
launch the game or collect runtime performance or play telemetry. First-pass
values come from current data and deterministic combat fixtures.

## Why and Current Context

### There is currently no combat recharge

`VehicleActiveWeaponRuntime` starts a cooldown and subtracts elapsed time only.
`VehicleRun._damage_enemy()` knows when positive player damage was applied, and
`_damage_player()` knows when barrier or hull damage was accepted, but neither
sends recharge. `VehicleSecondaryRuntime.record_primary_success()` is a
shot-fired signal used by Auto Laser; it is not proof that the shot hit.

Current active cooldowns are EMP 13 seconds, Black Hole 12, Shockwave 9, and Cross
Beam 12. The shared coolant multiplies them by `0.90/0.82/0.75`, so a new reduction
needs a hard event and time budget.

### Raw per-hit reduction would favor the wrong builds

The primary fires every 0.12 seconds. A literal 0.1-second reduction for every hit
can remove 0.83 cooldown seconds per real second before split shots, piercing,
secondaries, thermal bursts, poison, electric-field ticks, or dense groups. It
would reward hit-event production more than aim or weapon choice.

Official examples support the mechanic but also support limits. Diablo IV has
used per-target reduction with per-cast caps and per-cast proc limits. Destiny 2
has used both dealt and received damage as ability-energy sources and normalized
refunds by cooldown tier. Risk of Rain 2 has used conditional reduction as a
risk/reward mastery rule:

- [Diablo IV patch notes 1.3-1.5](https://news.blizzard.com/en-gb/article/24140806/diablo-iv-patch-notes-1-3-1-5)
- [Diablo IV 1.5.0 patch notes](https://news.blizzard.com/en-us/article/24123440/diablo-iv-1-5-0-patch-notes)
- [Destiny 2 Update 3.4.0](https://www.bungie.net/7/en/News/Article/50880)
- [Destiny 2 Update 7.3.0](https://www.bungie.net/7/en/News/Article/update-7-3-0-patch-notes)
- [Risk of Rain 2 official development notes](https://store.steampowered.com/news/posts/?appids=632360&enddate=1608046072&feed=steam_community_announcements)

### Cross Beam pays more reliability cost than its budget recognizes

Cross Beam crosses the full map on two axes, ignores cover, and hits each target
once. Its half-width is only `14/18/22/26`, while damage is `70/95/125/160` and
cooldown is 12 seconds. Black Hole has the same cooldown, `60/85/115/150` damage,
a `150/175/200/225` radius, and grouping control. Cross Beam's global reach matters,
but its narrow low-level corridor requires precise alignment against moving
ordinary enemies for only a small damage advantage.

The balance problem is broader than DPS. Dead Cells' official balance discussion
describes weapons becoming dominant when range, area, damage, short cooldown,
control, and safety accumulate. Riot's clarity guidance requires high-impact
evadable hitboxes and visual cues to agree:

- [Dead Cells official balance discussion](https://store.steampowered.com/news/posts/?appids=588650&enddate=1565706851&feed=steam_community_announcements)
- [Riot Games, Clarity in League](https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/)

### Quota currently stops ordinary spawning

Stage quotas are `125/166/208/250/291`, while authored ordinary counts are
`520/660/816/1026/1260`. On the countable defeat that fills quota,
`VehicleRun._defeat_enemy()` immediately calls
`encounter_runtime.stop_spawning()`. Stage flow waits 1.5 seconds and starts the
boss. No boss-start path bulk-deletes ordinary enemies, but no new enemies arrive,
so the remaining population naturally disappears during the fight.

Current data already contains far more authored enemies than quota requires.
Removing the quota-time stop keeps the existing scheduler active. An infinite
maintenance generator would add XP farming and a second scheduling mode without
evidence that either is needed.

### The reinforcement facility is a competing spawn owner

The facility activates at 35% progress and produces a finite set of non-quota
enemies. It has a dedicated runtime plus collision, damage, renderer, minimap,
guidebook, localization, capture, catalog, asset, document, and validator
surfaces. Once the ordinary scheduler continues through the boss, this owner is no
longer needed and makes spawn responsibility harder to understand.

### Boss offense and HUD

Boss damage multipliers currently rise from 1.35 to 1.70, cadence scales fall from
0.95 to 0.75, and health rises from 5250 to 7590. The requested change is a
deliberate increase over this baseline. Because ordinary enemies will continue,
startup warnings, active windows, coverage, projectile speed, health, shields,
and add limits remain fixed.

The compact HUD is Stage, total defeats, Dash, Seeker, and equipped active weapon.
Its contract already says `shows_primary_slot=false`. Optional secondaries are
automatic or continuous and do not share one truthful cooldown.

## Scope and Boundaries

### In scope

- Add active cooldown reduction from bounded accepted outgoing and incoming events.
- Give a primary volley, Seeker volley, piercing attack, area attack, or other
  multi-target action one stable identity so targets do not multiply recharge.
- Add a deterministic balance fixture and durable specification covering every
  approved weapon and level.
- Apply the locked Cross Beam first-pass values below.
- Adjust other approved weapons only when the role contract finds a dead level,
  same-role outlier, or strict multi-axis dominance.
- Continue ordinary authored arrivals during boss warning and active states.
- Preserve global capacity and the existing 13-slot boss/add reserve without
  deleting ordinary enemies to make room.
- Delete every reachable reinforcement-facility surface and its dedicated files.
- Increase boss damage and frequency with the locked offense profile below.
- Preserve the three action HUD slots and call Seeker the built-in secondary in
  product/UI contracts.
- Use simple player-facing terms: `기본 공격 / Primary`, `보조 무기 / Secondary`,
  `발동 무기 / Active Weapon`, and `전투 충전 / Combat Recharge` only where an
  explanation is necessary.

### Out of scope

- New weapons, cards, elements, slots, or rejected upgrades from the feedback.
- Replacing the approved damage-attribute plus utility-attribute slot model.
- A new cooldown meter, tutorial banner, meta explanation, or primary cooldown.
- Showing every automatic optional secondary as a top-HUD timer.
- An infinite post-authored spawn generator or infinite XP source.
- Boss health, shield, add-count, range, projectile-speed, or telegraph changes.
- Changes to quotas, authored counts, active caps, global capacity, or map geometry.
- Runtime performance claims or performance profiling.
- New or replacement player-facing raster assets.

## Assumptions and Invariants

- The active runtime owns remaining cooldown. A recharge policy requests a
  reduction; only the active runtime clamps and applies it.
- Recharge is discarded while ready and never banked.
- Active damage cannot recharge the same active weapon.
- Credit is sent after positive damage, not on fire or overlap.
- One action earns at most one credit in its class regardless of split, pierce,
  explosion, beam, or area target count.
- Thermal Burst and poison ticks do not add another credit to the primary action.
- Periodic actions use the smaller credit and share the outgoing maximum.
- Incoming credit requires positive barrier or hull loss. Invulnerable, ignored,
  zero-damage, or locked-out contacts give none.
- Quota owns boss eligibility only; encounter runtime owns ordinary arrivals.
- Capacity can defer a birth or boss entry but cannot retire an ordinary actor.
- Boss health, shields, phase floors, add limits, coverage, projectile speed,
  startup, and active duration stay unchanged.
- Feedback JSON approvals constrain identity and behavior. This pass changes
  values and reliability, not the approved list or slots.
- Balance is role parity, not identical DPS. Control and skillshot weapons differ.
- No new media is produced. Cross cues expand to collision truth exactly.

## User-Visible Behavior

### Combat recharge

| Event | Reduction | Duplicate rule | Limit |
| --- | ---: | --- | --- |
| Direct primary, secondary, or dash action applies positive enemy damage | 0.10 s | Once per stable action identity | Shared outgoing limit |
| Periodic field or dash action applies positive enemy damage | 0.025 s | Once per periodic action identity | At most 0.10 s of outgoing limit per second |
| One hostile hit removes barrier or hull | 0.20 s | Once for the received attack | 1.25 s lockout |
| Active weapon, poison, derived Thermal Burst, reflection, structure/device, or zero damage | 0.00 s | Excluded | Excluded |

Outgoing credits share a replenishing limit of 0.40 cooldown seconds per real
second. Maximum incoming contribution is 0.16 per real second. Natural time plus
both contributions advances cooldown at most `1.56` seconds per real second. This
is a mathematical cap, not a runtime measurement.

| Active | Locked base cooldown | Maximum-combat time | With max coolant |
| --- | ---: | ---: | ---: |
| EMP | 13.0 s | 8.33 s | 6.25 s |
| Black Hole | 12.0 s | 7.69 s | 5.77 s |
| Shockwave | 9.0 s | 5.77 s | 4.33 s |
| Cross Beam | 10.5 s | 6.73 s | 5.05 s |

The table assumes both budgets remain saturated. Typical play is slower. Existing
EMP relay behavior remains separate and covered by validation. No new HUD text or
meter appears; the active cooldown number simply reaches ready sooner. Guidebook
and upgrade detail explain the rule in Korean and English.

### Cross Beam first-pass balance

| Level | Current damage | New damage | Current half-width | New half-width |
| ---: | ---: | ---: | ---: | ---: |
| 1 | 70 | 80 | 14 | 24 |
| 2 | 95 | 110 | 18 | 32 |
| 3 | 125 | 145 | 22 | 40 |
| 4 | 160 | 185 | 26 | 48 |

- Startup changes from 0.35 to 0.30 seconds.
- Base cooldown changes from 12.0 to 10.5 seconds.
- Full cue and collision widths become `48/64/80/96` world units.
- It remains player-centered, map-spanning, cover-piercing, and one-hit per target.
- It gains no boss-only multiplier. Moderate changes across four real costs replace
  one extreme compensation.
- EMP, Black Hole, and Shockwave keep current first-pass values unless the complete
  role fixture proves a mandatory failure.

### Continuous boss pressure and facility removal

- Filling quota starts the existing warning but does not call `stop_spawning()`.
- Due and queued authored packets continue through warning and boss active,
  subject to the same caps and boss reserve.
- `stop_spawning()` remains valid only for completion, reset, and teardown.
- No facility appears in world, minimap, guidebook, HUD, localization, captures,
  asset manifest, or current product documentation.
- Facility children disappear as a concept. Scheduler enemies keep normal quota,
  XP, role, and transition rules.

### Boss offense

| Stage | Current damage multiplier | New damage multiplier |
| ---: | ---: | ---: |
| 1 | 1.35 | 1.50 |
| 2 | 1.42 | 1.60 |
| 3 | 1.50 | 1.70 |
| 4 | 1.58 | 1.80 |
| 5 | 1.70 | 1.90 |

- Direct-pattern recovery is multiplied by `0.80`.
- Read gaps change from `0.55/0.42/0.32` to `0.45/0.34/0.26` before the existing
  stage cadence scale.
- Autonomous base intervals change from `6.0/4.9/3.9` to `5.4/4.4/3.5` before the
  existing stage scale.
- Startup, active windows, speed, coverage, health, shields, phase floors, and add
  limits do not change.
- The largest current direct base hit is 36. With Stage 5's new multiplier its
  single-hit value is 68.4, below the base 120 hull.

### Combat HUD

```text
Stage | Total defeats | Dash | Secondary (Seeker) | Equipped Active Weapon
```

There is no primary cooldown today and none is added. Action order remains
`dash`, `seeker`, `active`. Automatic optional secondaries stay in the build
summary and guidebook instead of a misleading aggregate timer.

## Weapon Balance Contract

### Canonical roles

| Family | Weapon or upgrade | Intended job |
| --- | --- | --- |
| Primary | Base primary | Manual reliable sustained single-target damage |
| Primary | Split Muzzle | Multi-lane coverage with less reliable side shots |
| Primary | Piercing Rounds | Aligned multi-target damage requiring positioning |
| Damage attribute | Thermal Burst | Immediate clustered area damage |
| Damage attribute | Bio Toxin | Sustained damage after repeated application |
| Utility attribute | Cryo Slow | Movement control without raw damage |
| Utility attribute | Shock Disruption | Attack-start control without raw damage |
| Built-in secondary | Seeker | Reliable automatic ranged damage |
| Optional secondary | Electric Field | Continuous close area pressure |
| Optional secondary | Orbiting Blades | High-risk contact damage and interception |
| Optional secondary | Drop Mines | Route and pursuit punishment |
| Optional secondary | Auto Laser | Automatic line selection toward dense enemies |
| Optional secondary | Storm Barrage | Distant clustered ordinary-enemy damage |
| Active | EMP | Reliable emergency control and projectile clear |
| Active | Black Hole | Remote grouping and delayed area damage |
| Active | Shockwave | Frequent close defense and knockback |
| Active | Cross Beam | Map-spanning cover-piercing aimed damage |

### Fixed deterministic fixtures

The validator uses pure data and geometry, not a gameplay scene:

1. One large target at 480 units for boss damage, startup, cooldown, and restrictions.
2. Eight ordinary targets on the aim axis for piercing and line weapons.
3. Twelve ordinary targets within 285 units for EMP, fields, mines, and thermal.
4. Thirty-two dispersed targets in a fixed visible rectangle for global coverage
   and automatic selection.
5. Eight targets around the hull for orbiting, close defense, and movement control.

For each level it reports separate columns for damage per use and over 10 seconds,
distinct contacts, startup, cooldown, range/area/width/cap/cover behavior, control,
targeting burden, exposure, and level gain. It does not hide them in one score. The
unupgraded primary's 150 raw DPS (`18 / 0.12`) is a normalization point only.

### Pass and adjustment rules

- Every level improves its intended job. A numeric level needs at least 15%
  intended-fixture gain or a discrete breakpoint such as a projectile, blade,
  mine, penetration, or target.
- A non-discrete level cannot exceed 45% intended-fixture gain. A discrete count
  breakpoint may reach 65% but cannot also receive a large separate cadence and
  damage spike.
- Same-role peers at equal investment remain within 20% on intended damage.
  Separate control, reliability, restriction, and safety columns can justify less.
- No same-slot weapon may equal or beat a peer on damage, coverage, reliability,
  control, safety, and cadence with at least one strict advantage.
- Shared damage and cooldown enhancements apply after base rows and exactly once.
- Correct reliability in this order: cue/collision agreement, width or radius,
  targeting, cooldown, then damage.
- Correct damage or control with the smallest 5% data step that enters the band.
  Change one axis per failed iteration except for the locked Cross correction.
- Cue width and collision truth change together in one commit.
- Rejected upgrades are never used as balance solutions.

The milestone cannot close with an unresolved outlier. Final fixture values belong
in a durable weapon balance specification, not only validator constants or this
plan.

## Interface and Data Contracts

### Active recharge ownership

Add `scripts/player/vehicle_active_recharge_runtime.gd` to own outgoing action
deduplication, 0.40-second outgoing budget, 0.10-second periodic sub-budget,
1.25-second incoming lockout, and accepted reduction amounts:

```gdscript
func reset() -> void
func advance(delta: float) -> void
func credit_outgoing(
    action_family: StringName,
    action_serial: int,
    periodic: bool
) -> float
func credit_incoming(barrier_loss: float, hull_loss: float) -> float
func debug_snapshot() -> Dictionary
```

`VehicleActiveWeaponRuntime` adds:

```gdscript
func reduce_cooldown(seconds: float) -> float
```

It clamps at zero, returns consumed reduction, and returns zero while ready.
`VehicleRun` wires positive damage receipts only. UI never decides eligibility.

Player projectiles and secondary intents carry a combat action serial separate
from projectile spawn serial. One primary or Seeker volley shares one serial; all
targets in one mine, beam, storm, field tick, or area share one serial. Pool reset
clears it. Deduplication uses `(action_family, action_serial)`.

### Stage and spawn ownership

`VehicleStageFlow` retains quota, warning, boss active, and completion but removes
APIs implying it owns ordinary spawning. `VehicleEncounterRuntime` remains the
only ordinary scheduler. At quota, `VehicleRun` records the boss warning and
anchor without stopping encounter runtime. Completion, reset, and teardown can
still stop it. Capacity checks continue to defer admissions, and reserve tests
prove boss plus bounded adds enter without forced ordinary cleanup.

### Facility deletion boundary

Delete the facility runtime and UID, focused validator and UID, production raster
and import sidecar, workbench duplicate, and facility-only capture fixtures.
Remove facility branches and keys from run, renderer, world/UI catalogs, minimap,
guidebook, semantic manifest, localization, product specs, `VISUAL_SYSTEM.md`,
workbench inventories, active plans, and current reports.

Reduce and rename the mixed facility/anomaly report to anomaly-only if it contains
unique anomaly evidence. Historical evidence retained for provenance must be
explicitly retired and cannot be linked as current authority. Live snapshots have
no `reinforcement_facility` key and enemy states use no facility carrier
provenance. Unrelated transit, repair, overdrive, and anomaly objects remain.

### Balance truth

Create `docs/product/vehicle_weapon_balance_spec.md` as the durable role, fixture,
and final-value source. Runtime values remain with existing owners: primary rules,
approved card and payload data, secondary data/runtime, active data/runtime, and
boss pattern/runtime/stage difficulty. The validator imports those owners and
does not duplicate weapon truth.

## Chosen Approach and Rejected Alternatives

### Active cooldown

| Option | Benefit | Failure | Decision |
| --- | --- | --- | --- |
| Reduce all base cooldowns | Simple | Rewards downtime and compounds with coolant | Reject globally |
| Subtract 0.1 for every hit target | Immediate | Scales with fire rate, pierce, DOT, and density | Reject |
| Convert damage into charge | Helps low-hit attacks | Snowballs with damage and needs health normalization | Reject first pass |
| Deduplicated action credits with outgoing/incoming limits | Responsive and bounded | Needs stable action identity | **Choose** |

### Weapon balance and Cross Beam

| Option | Benefit | Failure | Decision |
| --- | --- | --- | --- |
| Equalize DPS | Easy | Erases coverage, control, reliability, and safety | Reject |
| One weighted score | Produces a rank | Hides arbitrary control/aim weights | Reject |
| Role fixtures plus dominance test | Preserves identity and exposes dead levels | More explicit columns | **Choose** |
| Cross damage only | Strong hits | Misses still feel bad | Reject |
| Cross width only | More contacts | Boss value and cadence stay weak | Reject |
| Cross cooldown only | More attempts | Repeats unsatisfying misses | Reject |
| Moderate changes on four axes | Pays real costs without one extreme stat | Cue/collision update required | **Choose** |

### Ordinary spawn and facility

| Option | Benefit | Failure | Decision |
| --- | --- | --- | --- |
| Keep quota stop and facility | Minimal change | Preserves boss-only phase | Reject |
| Remove stop and keep facility | More pressure | Two competing spawn owners | Reject |
| Remove stop, delete facility, continue authored packets | Uses 520-1260 existing schedules and one owner | Broad cleanup | **Choose** |
| Infinite maintenance generator | Endless bodies | Infinite XP policy and second scheduling mode | Reject |

### Boss offense and HUD

| Option | Benefit | Failure | Decision |
| --- | --- | --- | --- |
| Damage only | Simple | Boss waits too much | Reject |
| Cadence only | More attacks | Hits remain soft | Reject |
| More health/shield | Longer fight | Adds sponge behavior against user direction | Reject |
| Damage plus shorter recovery/read/autonomous gaps | More threat without hidden reaction loss | Needs combined-pressure checks | **Choose** |
| Preserve Dash / Seeker / Active HUD | Three truthful cooldowns; no primary already | Passives stay elsewhere | **Choose** |
| Show every optional secondary | Complete detail | Clutter and continuous weapons lack timers | Reject |
| Aggregate secondary timer | Compact | Cannot truthfully combine six behaviors | Reject |

## Implementation Map

| Responsibility | Primary owner | Adjacent contract |
| --- | --- | --- |
| Recharge policy | New active-recharge runtime | Focused validator and reset |
| Cooldown mutation | Active weapon runtime | Clamp, coolant, relay |
| Damage wiring | `vehicle_run.gd` | Enemy/player accepted receipts |
| Action identity | Projectile state/store, primary, secondaries | Volley/area dedup and pool reset |
| Weapon values | Existing weapon and card owners | Durable balance spec and fixture |
| Cross cues | Active presentation owners | Exact collision parity; no new asset |
| Quota/boss | Stage flow and run | Remove quota-time stop |
| Ordinary arrivals | Encounter runtime | Caps and boss reserve |
| Facility removal | Facility runtime and all consumers | Assets, map, guide, docs, validators |
| Boss offense | Stage difficulty, boss runtime/patterns | Cycle and damage validators |
| HUD | Gameplay HUD, presenter, product and tests | Exactly three action slots |

`vehicle_run.gd` remains orchestration. It does not own recharge budgets, balance
tables, facility visuals, or boss pattern data.

## Milestones and Progress

- [x] `M0` Inspect weapon values/owners, cooldown flow, damage receipts, quota/boss
  transition, authored counts, facility surfaces, boss scaling, HUD contract,
  active plans, feedback JSON, and primary references without launching the game.
- [x] `M0` Compare at least three viable approaches for each material decision and
  lock the selected rules and first-pass values.
- [ ] `M1` Add stable combat action identity and bounded recharge; wire positive
  outgoing/incoming receipts and reset/dedup/budget validators.
- [ ] `M2` Create the durable balance spec and deterministic role fixture; apply
  Cross values and resolve every approved weapon's mandatory failures.
- [ ] `M3` Decouple quota from ordinary spawning, preserve boss reserve, and prove
  arrivals continue during warning and boss active.
- [ ] `M4` Remove the facility from runtime, presentation, assets, guide, minimap,
  localization, captures, current docs/reports, and validators.
- [ ] `M5` Apply boss damage, recovery, read-gap, and autonomous-interval values
  while freezing health, shields, coverage, speed, adds, startup, and active time.
- [ ] `M6` Preserve/clarify the three-slot HUD, update Korean/English copy, and
  produce required Cross-width and facility-absence visual evidence without UI text.
- [ ] `M7` Run focused validators, absence checks, visual authority validation, Web
  export, and production-style release path. Performance profiling is excluded.
- [ ] `M8` Record final fixture values/outcomes in durable specs, delete this
  completed ExecPlan, and commit coherent task-owned changes.

## Acceptance Criteria

### Recharge and weapons

- Primary fire cannot reduce active cooldown by more than 0.40 seconds per real
  second through outgoing events.
- Split, four penetrations, multi-target Seeker, mine, beam, storm, and area actions
  each demonstrate one direct credit per action, not target.
- Periodic sources use at most 0.10 seconds of outgoing budget per second. Poison,
  derived Thermal Burst, and active self-damage give none.
- One received attack removing barrier and hull gives one 0.20 credit; further
  accepted hits inside 1.25 seconds give none.
- Invulnerability, zero damage, structures/devices, and ready-state events give no
  credit or banking. Cooldown never becomes negative; coolant/relay apply once.
- Every approved weapon and level appears in the role matrix and fixture output.
- No dead level, excessive spike, unjustified same-role outlier, or strict
  dominance remains under the locked rules.
- Cross uses damage `80/110/145/185`, half-width `24/32/40/48`, startup 0.30, and
  cooldown 10.5; cue and collision match.
- Approved list, two attribute slots, maximum two optional secondaries, and notes
  remain intact. Rejected upgrades do not return.

### Encounter, facility, and boss

- The defeat reaching quota changes boss eligibility while
  `encounter_runtime.spawning_enabled()` stays true.
- A deterministic fixture observes an ordinary cue and accepted spawn after
  `BOSS_ACTIVE` begins when capacity is available.
- Boss warning/entry does not retire ordinary enemies. Boss/add reserve respects
  the 320-hostile pool without forced cleanup.
- Completion remains the point that stops the old encounter before next-stage setup.
- No reachable snapshot, renderer, minimap, guide, localization row, asset manifest,
  current spec, or focused validator contains facility identity.
- Dedicated facility runtime, validator, raster, import, and workbench duplicate
  are deleted; unrelated facilities and anomaly devices remain.
- Boss damage multipliers are `1.50/1.60/1.70/1.80/1.90`, recovery uses 0.80, read
  gaps are `0.45/0.34/0.26`, and autonomous intervals are `5.4/4.4/3.5`.
- Boss health, shields, floors, add caps, coverage, speeds, startup, and active
  durations are unchanged. Largest Stage 5 single direct hit is at most 68.4.

### HUD, copy, and visual authority

- HUD remains `action_slot_count == 3`, `shows_primary_slot == false`, and order
  `dash`, `seeker`, `active`.
- No new HUD meter, label, explanatory sentence, or secondary aggregate appears.
- Product/guide copy identifies Seeker as secondary with complete Korean/English.
- Cross visual width matches collision at cue and release.
- Facility absence and Cross evidence are inspected under the canonical visual
  authority pair. No new raster or SVG is created.

## Test Plan

- Add `validate_vehicle_active_recharge.gd` for deduplication, direct/periodic
  budgets, incoming lockout, ready discard, self-exclusion, coolant, relay, reset.
- Extend primary, secondary, projectile-store, and active validators for combat
  serial propagation, pool reset, and Cross cue/collision parity.
- Add `validate_vehicle_weapon_balance_contract.gd` for five pure fixtures, level
  gains, peer bands, dominance, shared multipliers, and exact Cross values.
- Extend arrival, run, and continuity validators for post-quota and boss-active
  arrivals, reserve, capacity deferral, and no ordinary cleanup.
- Delete the facility validator and remove facility branches from run, renderer,
  guide, map, localization, semantic, visual replacement, and capture validators.
- Extend boss validators for exact offense values while freezing durability,
  telegraphs, coverage, speed, adds, and escape margins.
- Preserve HUD assertions for three action slots and no primary slot.
- Run `rg --hidden` for facility IDs/names. Remaining matches must be unrelated
  generic facilities or explicitly retired history; no live authority/code match.
- Check Korean/English parity and product/guide values against runtime owners.
- Run `git diff --check` after milestones and before commit.
- Use focused headless validators during implementation and the relevant
  consolidated entry point once after the feature set is complete.
- Run `validate_cardborne_visual_authority.ps1`, Web export, and the required
  production-style path. Inspect supported-width Korean/English captures for the
  unchanged HUD, Cross parity, and facility absence.
- Do not run a performance scenario or make a frame-time claim. Continuous pressure
  is a product workload decision subject to the separate performance gate.

## Rollout and Recovery

- Ship recharge, values, spawn decoupling, facility deletion, boss offense, copy,
  and validators as one coherent product change. Partial rollout leaves competing
  spawn owners or false guide data.
- No save migration is needed because facility state is not player progression.
  Old guide IDs load permissively and remain absent from current entries.
- If defective, revert the coherent implementation commit. Do not restore only the
  facility visual or only the quota-time stop.
- If recharge later proves too fast, tune the two budgets and lockout in the policy
  owner, not scattered per-weapon exceptions.
- If a weapon fails its role band, change the smallest allowed axis and update the
  durable matrix and validator together.

## Risks

- Continuing arrivals plus stronger boss offense raises combined pressure.
  Preserve caps, reserve, telegraphs, coverage, speed, health, and adds; do not
  silently reduce workload.
- Action serials can collide across families. Deduplicate by family and serial and
  clear pooled state.
- Incoming recharge can reward intentional damage. Keep it fixed at 0.20, locked
  for 1.25 seconds, independent of damage size, and require real barrier/hull loss.
- Coolant can amplify recharge. Validate base and max-coolant envelopes and keep
  one outgoing cap independent of weapon and target count.
- Broad facility removal can leave stale asset, map, guide, or capture references.
  Use explicit inventory, hidden-file absence search, and semantic validators.
- Cross width plus damage can overgrow group output. Use locked moderate values,
  fixture contact counts, and no boss-only multiplier.

## Decision Notes

- 2026-08-12: Chose deduplicated action credits with outgoing/incoming caps over
  literal per-target 0.1-second reduction.
- 2026-08-12: Chose no global base-cooldown cut. Cross alone gets a lower base
  cooldown as part of its reliability correction.
- 2026-08-12: Chose role fixtures and dominance testing over equal DPS or one score.
- 2026-08-12: Locked moderate Cross changes on four axes.
- 2026-08-12: Confirmed boss start does not bulk-delete ordinary enemies; the
  quota-time `stop_spawning()` creates the boss-only phase.
- 2026-08-12: Chose existing authored schedules over an infinite generator because
  counts already exceed quota widely and infinity adds XP farming.
- 2026-08-12: Chose complete facility removal so arrivals have one owner.
- 2026-08-12: Chose boss damage plus cadence while freezing durability, telegraphs,
  coverage, speed, and adds.
- 2026-08-12: Confirmed current HUD has no primary cooldown; preserve Dash, Seeker,
  and active only.
- 2026-08-12: No game, browser, server, or performance scenario was launched.

## Open Questions

None. Recharge budgets, Cross values, spawn ownership, facility removal, boss
offense, HUD policy, adjustment rules, validation, and rollout are decision-complete.
New runtime evidence can trigger a later revision but is not required to implement.

## Outcomes and Retrospective

The plan is active and claims no implementation outcome. On completion, record the
final matrix, rule-driven changes beyond Cross, validation results, and whether the
combined pressure matched the product contract. Then update durable specs and
delete this ExecPlan according to `.agents/PLANS.md`.
