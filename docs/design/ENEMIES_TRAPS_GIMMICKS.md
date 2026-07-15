---
type: spec
status: active
owner: BK
last_reviewed: 2026-07-15
canonical_for: First-run enemy archetypes, variants, encounter composition, hazards, gimmicks, and Giant Slime King patterns
source: Existing enemy and stage component scripts, prior content catalog, and Cardborne Game Blueprint
related:
  - ../product/2d_platform_action_card_game_prd.md
  - ./PROCEDURAL_REGION_GENERATION.md
  - ./MAP_AUTHORING_PIPELINE_CONTRACT.md
  - ./PROGRESSION_EQUIPMENT_ECONOMY.md
  - ../../.agent/execplans/2026-07-15-gameplay-validity-repair.md
---

# Enemies, Traps, Gimmicks, And Boss

## Purpose

Define the pressure vocabulary of the first complete run. Every actor must create a
specific player response and fit declared room geometry; variety comes from
compatible combinations, not arbitrary spawning.

## Scope

This specification covers six normal enemy archetypes, 13 first-run variants, two
special actors, four core hazards, reusable stage gimmicks, encounter budgets, and
the Giant Slime King.

## Enemy Domain Terms

| Term | Owned meaning |
| --- | --- |
| `EnemyArchetype` | Stable behavior lesson, tell, response, punish window, pressure roles, geometry contract, and safety bounds. Walker and Shooter are archetypes, not individual enemies. |
| `EnemyVariant` | Concrete stage-eligible presentation and exact combat values for one archetype. It cannot replace the archetype's response contract. |
| `EnemyTuningProfile` | Authoring bounds for a stage. It validates variants; it is not a blanket runtime multiplier. |
| `ResolvedEnemySpec` | Immutable archetype + variant result consumed by a production enemy scene. |
| `EnemyInstance` | One spawned runtime actor with current health, state, statuses, and position. It does not invent permanent stats. |
| `PressureRole` | Encounter-composition job such as occupier, burst, ranged, or guard. It is not an enemy identity. |

`template` remains reserved for authored room templates. Enemy code and data use
the terms above so room generation, combat behavior, and runtime instances do not
share an overloaded name.

## Threat Design Rules

- Each enemy has one primary lesson, one readable tell, and one punish window.
- Normal contact/projectile/trap damage is 1 unless explicitly approved below.
- A tell begins before the damaging movement or hitbox becomes active.
- Variants may adjust health, movement, warning, active duration, recovery, attack
  cadence, range, projectile speed, stagger capacity, budget, drops, and
  presentation only within their stage profile.
- Later stages primarily increase pressure through composition and space. Variant
  health rises only enough to expose behavior, never to create damage sponges.
- Exact combat values come from the selected variant. Runtime instances have no
  hidden random stat rolls or universal stage multiplier.
- A variant must reveal meaningful timing, reach, armor, or weapon differences
  through silhouette, equipment, animation, and telegraph; color alone is not enough.
- Spawns use compatible authored anchors with stable support and response room.
- Enemies stop applying damage immediately on defeat and resolve rewards once.
- Off-screen enemies do not begin burst attacks toward an unseen player.
- Repeated traps use deterministic phases and preserve a visible safe response.

## Pressure Roles

| Role | Job | Combination limit |
| --- | --- | --- |
| `occupier` | Takes ordinary ground and asks for basic spacing. | Up to 3 light occupiers. |
| `burst` | Temporarily claims a lane after a tell. | One primary burst actor per narrow lane. |
| `ranged` | Makes stationary play unsafe. | One early; max two only with cover and no active turret overlap. |
| `guard` | Blocks frontal repetition and asks for flank/stagger. | One per choke; never blocks the only exit. |
| `vertical` | Claims jump arcs or platforms. | Requires ceiling/landing clearance. |
| `zone` | Controls persistent space. | Must leave a stable safe route. |
| `summoner` | Creates escalating target priority. | One; children count against active cap. |

## Enemy Archetype Catalog

The values below are archetype reference values and behavior invariants. Stage
generation never spawns an archetype directly; it selects one of the exact variants
listed later.

### Walker (`walker`)

- Role/cost: occupier, 1 point.
- Existing owner: `WalkerEnemy.gd` + `EnemyBase.gd`.
- Health: 3; contact damage: 1; speed: 70.
- Tell: visible patrol and facing are sufficient; no hidden acceleration.
- Response: approach, jump over, knock back, or basic attack.
- Punish: hit stun or direction change at patrol edge.
- Anchor: >= 180 px support, patrol turn points, no immediate ledge fall.
- Drop: 6 XP guaranteed; common coin chance.
- Stage use: all stages; first hostile lesson in Stage 1.

### Charger (`charger`)

- Role/cost: burst, 2 points.
- Existing owner: `ChargerEnemy.gd`.
- Health: 5; contact damage: 1.
- Timing seed: warning 0.48 s, charge 0.52 s at 360 px/s, recovery 0.42 s.
- Safety floor: warning >= 0.40 s and recovery >= 0.36 s for every variant.
- Tell: body compresses, facing locks, lane warning flashes.
- Response: jump, dash away, change elevation, or use cover.
- Punish: recovery after wall/charge endpoint; receives +20 stagger during recovery.
- Anchor: >= 520 px charge lane or declared wall-stop lane; escape ledge/pad.
- Exclusion: no poison band active across its only dodge lane.
- Drop: 12 XP, 3 coins, Rusted Scrap chance.

### Shooter (`shooter`)

- Role/cost: ranged, 2 points.
- Existing owner: `ShooterEnemy.gd` + `EnemyProjectile.gd`.
- Health: 4; contact/projectile damage: 1.
- Timing seed: aim 0.38 s, projectile 280 px/s, 1.8 s interval.
- Reference range: 760 px; post-shot recovery: 0.45 s.
- Safety floor: aim >= 0.32 s, interval >= 1.50 s, post-shot recovery >= 0.40 s.
- Tell: aim line or body pose shows direction; projectile contrasts background.
- Response: move, use cover, change level, or interrupt.
- Punish: aim and post-shot pause; melee approach remains possible.
- Anchor: line-of-sight lane, cover or elevation change, no spawn behind opaque decor.
- Exclusion: Stage 1 does not pair it with Sentry or poison timing.
- Drop: 10 XP, 2 coins, Sky Thread chance.

### Shield Guard (`shield_guard`)

- Role/cost: guard, 3 points.
- Existing owner: `ShieldGuardEnemy.gd`.
- Health: 7; contact/attack damage: 1.
- Timing seed: guard 1.2 s, attack tell 0.35 s, recovery 0.55 s.
- Safety floor: attack tell >= 0.35 s and recovery >= 0.55 s.
- Tell: shield direction and attack windup remain visually distinct.
- Response: cross behind, bait and guard the attack, or use the ranged tool from a
  legal flank line.
- Punish: back and attack recovery; frontal blocked hits do not damage but still
  provide clear feedback.
- Anchor: >= 420 px room, flank route or second elevation, exit cannot sit behind
  an unflankable guard.
- Exclusion: one per encounter; no narrow crouch tunnel placement.
- Drop: 18 XP, 4 coins, high Rusted Scrap chance.

### Leaper (`leaper`)

- Role/cost: vertical/burst, 2 points.
- Existing owner: `LeaperEnemy.gd`.
- Health: 4; contact damage: 1.
- Timing seed: windup 0.35 s, leap 0.52 s, recovery 0.50 s.
- Safety floor: windup >= 0.32 s and landing recovery >= 0.45 s.
- Tell: crouch and projected landing marker.
- Response: move through the arc, change elevation, or attack the landing.
- Punish: fixed landing recovery; landing location cannot retarget after launch.
- Anchor: >= 420 px horizontal lane, 180 px vertical clearance above arc, stable
  landing support.
- Exclusion: no low ceiling or moving-platform-only floor.
- Drop: 12 XP, 2 coins, Slime Residue or Sky Thread chance.

### Sentry (`sentry`)

- Role/cost: ranged/zone, 3 points.
- Existing owner: `SentryTurretEnemy.gd`.
- Health: 6; projectile damage: 1; stationary.
- Timing seed: warning 0.45 s, projectile 300 px/s, 1.4 s interval, max 2 active.
- Reference range: 900 px; post-shot recovery: 0.45 s.
- Safety floor: warning >= 0.42 s, interval >= 1.40 s, post-shot recovery >= 0.45 s.
- Tell: rotating aim line locks before firing.
- Response: use cover, change level, close distance, or destroy from range.
- Punish: cannot turn during the final warning; 0.45 s post-shot pause.
- Anchor: fixed support, authored cover, no unavoidable crossfire at room entry.
- Exclusion: two Sentries require at least two independent safe cover zones and a
  validated no-overlap firing phase.
- Drop: 20 XP, 5 coins, Rusted Scrap and equipment-blueprint chance.

## Enemy Tuning Profiles

Ratios compare a concrete variant with its archetype reference values. Duration
ratios below 1.0 are faster. These profiles validate authored variants and are not
applied again when an instance spawns.

| Stage profile | Health | Warning | Active | Recovery | Cadence | Speed/range | Max stagger capacity | Damage |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `ruin_approach` | 0.90-1.10 | 1.00-1.25 | 1.00-1.10 | 1.00-1.25 | 1.00-1.15 | 0.85-1.05 | 1.00 | 1 |
| `flooded_works` | 1.00-1.35 | 0.95-1.10 | 1.00-1.10 | 0.95-1.10 | 0.95-1.05 | 1.00-1.10 | 1.10 | 1 |
| `broken_sanctum` | 1.00-1.70 | 0.85-1.05 | 1.00-1.15 | 0.85-1.05 | 0.85-1.05 | 1.00-1.25 | 1.20 | 1 |

`Cadence` is the ratio for repeated attack intervals such as Shooter and Sentry
fire intervals. Values below 1.0 attack more frequently; archetype safety floors
still take precedence.

- A health ratio above 1.35 in Stage 3 is reserved for the low-cost Walker or an
  archetype whose behavior still resolves within the room-duration budget.
- Attack damage remains 1. An approved 2-damage elite action would require a new
  visible action, distinct telegraph, explicit spec entry, and separate budget.
- Faster warnings or recovery cannot cross the archetype safety floor even when a
  tuning profile ratio would otherwise allow it.

## First-Run Enemy Variants

All values are resolved values, not multipliers applied at spawn. Every variant
inherits its archetype's roles, geometry contract, and behavior owner.

| Variant | Stage | Exact tuning focus | Presentation requirement |
| --- | --- | --- | --- |
| `walker_ruin` | Ruin Approach | HP 3, move 70, stagger 40, cost 1. | Plain occupier silhouette and clear facing. |
| `charger_ruin` | Ruin Approach | HP 5, warn 0.48 s, active 0.52 s, recovery 0.42 s, speed 360, stagger 60, cost 2. | Long teaching windup and lane flash. |
| `shooter_ruin` | Ruin Approach | HP 4, aim 0.42 s, interval 2.00 s, projectile 260, range 700, stagger 40, cost 2. | Short weapon and broad aim line. |
| `walker_flooded` | Flooded Works | HP 4, move 76, stagger 42, cost 1. | Faster gait and stage-readable wet gear. |
| `charger_flooded` | Flooded Works | HP 6, warn 0.46 s, active 0.55 s, recovery 0.42 s, speed 375, stagger 66, cost 2. | Longer charge trail without hiding windup. |
| `shooter_flooded` | Flooded Works | HP 5, aim 0.38 s, interval 1.75 s, projectile 290, range 820, stagger 44, cost 2. | Longer weapon plus matching range telegraph. |
| `leaper_flooded` | Flooded Works | HP 4, windup 0.38 s, leap 0.52 s, recovery 0.52 s, stagger 55, cost 2. | Large landing marker and slow teaching crouch. |
| `walker_sanctum` | Broken Sanctum | HP 5, move 82, stagger 46, cost 2. | Reinforced silhouette communicates resistance. |
| `charger_sanctum` | Broken Sanctum | HP 6, warn 0.42 s, active 0.58 s, recovery 0.38 s, speed 395, stagger 72, cost 3. | Heavier lane trail and sharper recovery pose. |
| `shooter_sanctum` | Broken Sanctum | HP 6, aim 0.34 s, interval 1.55 s, projectile 315, range 920, stagger 48, cost 3. | Long weapon and narrow locked aim line. |
| `shield_guard_sanctum` | Broken Sanctum | HP 7, guard 1.20 s, tell 0.35 s, recovery 0.55 s, stagger 100, cost 3. | Shield direction and exposed rear arc remain obvious. |
| `leaper_sanctum` | Broken Sanctum | HP 5, windup 0.33 s, leap 0.55 s, recovery 0.46 s, stagger 60, cost 3. | Faster crouch but unchanged landing marker lead. |
| `sentry_sanctum` | Broken Sanctum | HP 6, warn 0.45 s, interval 1.40 s, projectile 300, range 900, stagger 80, cost 3. | Fixed barrel and cover-readable aim line. |

## Enemy Selection Pipeline

```text
room pressure role and budget
 -> compatible EnemyArchetype
 -> variants eligible for stage and tuning profile
 -> deterministic enemy_variant RNG selection
 -> anchor/geometry validation
 -> Stage Plan stores archetype_id + variant_id
 -> scene receives one immutable ResolvedEnemySpec
 -> EnemyInstance starts with exact resolved values
```

- Encounter budget uses the selected variant's cost.
- Same seed, content version, room, and encounter context select the same variant.
- Archetype selection and variant selection use separate named RNG streams so a
  presentation/tuning addition does not silently rewrite room topology.
- Per-instance random health, attack, defense, range, warning, recovery, or reload
  rolls are forbidden. Cosmetic-only variation may use a separate stream when it
  does not alter collision, silhouette class, or telegraph readability.
- Special actors remain concrete definitions because their summon/cleanup contract
  is encounter-specific. Promote them to archetype/variant only when reused as a
  normal generated family.

## Special Actors

### Summon Node (`summon_node`)

- Role/cost: summoner, 4 points; Stage 3 optional/final encounter only.
- Existing owner: `SummonNodeEnemy.gd`.
- Health: 8; no contact chase.
- Warn 0.45 s before spawning; interval 2.6 s.
- Max 2 active children, 6 total per encounter.
- Spawn markers stay >= 150 px from player and on stable support.
- Defeating the node removes or disables remaining children according to encounter
  completion policy.

### Small Slime (`small_slime`)

- Role/cost: light occupier/add, 1 point.
- Existing owner: `SmallSlimeEnemy.gd`.
- Health: 2; contact damage: 1; limited lifetime outside boss.
- Spawn warning appears before collision/damage activates.
- Initially used by Summon Node and boss; not random free-roaming filler.

## Encounter Composition

| Budget | Typical legal examples | Forbidden examples |
| ---: | --- | --- |
| 1-2 | 2 Walkers; 1 Charger; 1 Shooter. | Burst plus hazard before either is taught. |
| 3-4 | Charger + Walker; Shooter + 2 Walkers; Leaper + Walker. | Shield Guard blocking a single narrow exit. |
| 5-6 | Shield Guard + Shooter with flank/cover; Charger + Leaper with two escape levels. | Shooter + Sentry without cover; Charger across full poison floor. |
| 7 | Sentry + Shield + Walker in reviewed Stage 3 arena; Summon Node + light support. | Two burst actors sharing one unavoidable lane; summoner plus active-cap overflow. |

Composition rules:

- At most one new enemy lesson per teaching encounter.
- At most two simultaneous high-attention roles: burst, ranged, guard, vertical,
  zone, or summoner.
- Light occupiers may fill downtime but cannot obscure tells.
- The encounter completes deterministically when its declared required enemies or
  objective are resolved; wandering physics pickups are irrelevant.
- Reinforcements need authored warning anchors and count toward the same budget.

## Hazard Catalog

### Spike Row (`spike_row`)

- Cost: 1; damage: 1.
- Static visible geometry; no delayed tell required.
- Critical placement leaves >= 220 px takeoff/landing or a safe walking bypass.
- Does not begin inside a camera-hidden landing.

### Timed Poison Vent (`timed_poison_vent`)

- Cost: 2; damage: 1 per tick.
- Existing owner: `TimedPoisonVent.gd`.
- Timing seed: warning 0.70 s, active 1.20 s, cooldown 1.50 s, tick 0.65 s.
- Warning and active states differ by shape/motion and color.
- Permanent safe support remains available; encounter combinations preserve an
  escape route during warning.

### Fall Reset (`fall_reset`)

- Cost: 1; damage: 1 then safe fall-recovery/anchor reset.
- Existing owner: `FallResetZone.gd`.
- Gap and lower void are visually obvious before commitment.
- Reset cannot emit a second damage/death before invulnerability begins.

### Crumbling Platform (`crumbling_platform`)

- Cost: 2.
- Existing owner: `CrumblingPlatform.gd`.
- Timing seed: shake 0.45 s, disabled 1.8 s, reappear 0.25 s.
- Stable waiting/landing pads exist at both ends; required route has lower recovery
  or fall-recovery reset.
- It resets on stage/room retry.

`crushing_block` remains excluded until a production component and reviewed safe
timing room exist.

## Gimmick Catalog

| ID | Existing foundation | Gameplay job | Required safety |
| --- | --- | --- | --- |
| `one_way_platform` | Player drop-through + collision | Vertical choice and recovery. | Safe destination and return/forward path. |
| `rope` | `Climbable.gd` | Shared vertical traversal. | Stable entry/exit and lower recovery. |
| `moving_platform` | not implemented | Predictable timing bridge. | Safe wait pads, visible path, reset state. |
| `switch_gate` | `SwitchGate.gd`, `SwitchInteractable.gd` | Short visible objective loop. | Switch precedes gate and action is idempotent. |
| `destructible_cache` | `DestructibleObstacle.gd` | Optional reward access and attack feedback. | Never sole required route unless it resets. |
| `chest` | planned Interactable subtype | Deliberate reward claim. | Stable interaction space; applies once. |
| `material_node` | planned damage/interact subtype | Optional persistent resource risk. | Reachable optional route and deterministic drop source. |
| `checkpoint` | `StageCheckpoint.gd` | Internal ID/component for fall recovery and pacing, never death retry. | No active pressure in safe radius. |
| `exit_portal` | `ExitPortal.gd` | Stage completion. | Objective-valid, unobstructed interaction space. |

## Giant Slime King

### Arena

- Authored 1280x720 combat frame with 1,080 px usable ground lane.
- Two one-way side platforms at different heights; neither is mandatory safety.
- Camera remains stable; entrance locks only after player control and boss intro.
- Arena supports melee approach, ranged line of sight, dash/jump evasion, and add
  cleanup for every character.
- No pattern damages the player during intro, phase transition, or death cleanup.

### Base properties

- ID: `slime_king`.
- Health seed: 80; phase 2 begins at 50%.
- Contact damage: 1 only during declared active movement.
- Stagger: normal hits build a bounded stagger meter; stagger grants a 1.4 s punish
  window and resets queued combo.
- Pattern scheduler avoids immediate repeats and records chosen patterns.

### Pattern timing

| Pattern | Startup | Active | Recovery | Counterplay |
| --- | ---: | ---: | ---: | --- |
| `jump_slam` | 0.80 s shadow and ascent | 0.18 s landing + two ground shockwaves | 1.00 s | Leave shadow, then jump/dash shockwave; punish landing. |
| `body_bump` | 0.55 s lean/flash, direction locks | 0.45 s horizontal body hitbox | 0.80 s | Change elevation or cross behind; punish wall/endpoint. |
| `poison_bands` | 0.90 s floor warnings | 2.20 s alternating active bands | 0.80 s cleanup | Move to guaranteed safe 35% floor/platform area. |
| `small_slime_summon` | 0.70 s two spawn markers | Adds activate; max 2 | 1.00 s | Clear adds or use boss recovery; markers never appear on player. |

### Phase 2 legality

- Base timing may accelerate by at most 15%; warning floors remain unchanged.
- Legal reviewed chains: Body Bump -> 0.50 s neutral -> Jump Slam; Poison Bands ->
  Summon only when safe floor and add spawn zones do not overlap.
- Jump Slam cannot land while Poison Bands remove its shockwave jump landing area.
- Body Bump cannot start while two active adds body-block both side responses.
- Summon is skipped at active-add cap.
- After any legal chain, boss takes at least 0.75 s neutral recovery.

### Boss rewards and cleanup

- Boss defeat disables all damage immediately, clears projectiles/hazards/adds,
  then settles Boss Core and run result exactly once.
- Player death cancels the scheduler and clears transient arena state before the
  Retry Decision. `Retry Stage` rebuilds from the boss-entry snapshot; `End
  Expedition` settles death exactly once.
- No post-boss card is offered because no following combat remains.

## Requirements

- Enemy AI declares a drop source ID but does not grant rewards directly.
- Enemy behavior consumes a `ResolvedEnemySpec`; it does not switch on stage or
  variant IDs to calculate stats.
- Encounter allocator owns composition and anchor selection.
- Encounter allocator selects archetype before variant and records both IDs.
- Every threat has a visual/audio tell suitable for its response time.
- Every repeated or spawned actor has an active cap and cleanup owner.
- Placeholder geometry remains readable without debug labels.

## Acceptance Criteria

- Every normal enemy can kill and be killed in an isolated production encounter.
- All 13 variants validate against their archetype safety bounds and stage tuning
  profile, and each appears in a focused fixture before random allocation.
- Each enemy's intended response and punish window are observable in play.
- Curated encounter fixtures cover every legal pair and every forbidden high-risk
  combination.
- No enemy floats, patrols off support, fires through required opaque cover, or
  blocks an exit/fall-recovery point permanently.
- Every hazard teaches alone before appearing with high encounter pressure.
- Boss scheduler simulation never produces an illegal overlap or repeat sequence.
- The Traveler defeats the boss with the baseline loadout, and the boss can defeat
  the Traveler through readable mistakes.

## Non-Goals

- Generic behavior-tree framework before current state scripts prove insufficient.
- Random per-instance stats, generic stage multipliers, random enemy critical hits,
  undeclared elite affixes, one-shot attacks, or invisible traps.
- More normal enemy types before the six roles produce distinct encounters.
- Procedurally generated boss arena or unrestricted pattern overlap.

## Related

- `docs/product/2d_platform_action_card_game_prd.md`
- `docs/design/PROCEDURAL_REGION_GENERATION.md`
- `docs/design/MAP_AUTHORING_PIPELINE_CONTRACT.md`
- `docs/data/RUNTIME_CATALOG_INDEX.md`
- `data/enemies/enemy_catalog.tres`
- `data/hazards/hazard_catalog.tres`
