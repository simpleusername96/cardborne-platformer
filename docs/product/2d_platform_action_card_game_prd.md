---
type: spec
status: active
owner: BK
created: 2026-06-30
last_reviewed: 2026-07-14
canonical_for: Cardborne product identity and first complete run scope
source: Existing PRD, first-run scope delta, first-slice expansion, and owner feedback through 2026-07-14
related:
  - ../design/ARSENAL_EQUIPMENT_PROGRESSION.md
  - ../design/PROCEDURAL_REGION_GENERATION.md
  - ../design/MAP_AUTHORING_PIPELINE_CONTRACT.md
  - ../design/ENEMIES_TRAPS_GIMMICKS.md
  - ../design/PLAYER_FACING_FLOW.md
  - ../architecture/FIRST_SLICE_ARCHITECTURE.md
  - ../../.agent/execplans/2026-07-14-single-hero-arsenal-migration.md
---

# Cardborne Game Blueprint

## Purpose

Define the game that current code and future implementation must build. This is
the product source of truth. Linked design specifications own detailed content and
a new active plan, when one exists, owns implementation order.

Cardborne is not a mechanics testbed and not a collection of independent RPG
systems. It is a compact 2D action-platform roguelite where readable movement and
combat produce rewards that visibly transform the rest of the run.

## Scope

The target first complete run contains:

- one persistent hero with a fixed reliable movement envelope;
- three approved fixed normal stages assembled from authored room templates;
- one authored two-phase boss fight;
- two equipped weapon disciplines, each with Basic, Heavy, three skills, passive,
  mastery, weapon form, and enchantment;
- run levels, stage-clear cards, coins, temporary forging, and consumables;
- armor, charm, relic, consumable, deterministic enhancement, four materials, and
  six mastery nodes per weapon discipline;
- a skippable and replayable Arsenal Trial, three local profile slots, automatic
  profile persistence, and checkpoint-level Continue;
- enemies, traps, optional routes, checkpoints, shops, rewards, death, settlement,
  and clear flows;
- one coherent Lower Ruins region with production-readable placeholder art and
  audio.

## Product Promise

> Move one persistent hero through dangerous ruins, read threats, switch between
> two prepared weapon disciplines, and turn discoveries into a build that changes
> how the next room is played.

The player should be able to explain a satisfying run in terms of decisions:

- which route they risked;
- which enemy opening they exploited;
- which card changed their attack pattern;
- what they enhanced, equipped, or forged instead of healing;
- when switching weapons or using support gear solved the boss.

## Fun Contract

Fun cannot be proven by code coverage. It can be designed as testable hypotheses.
Every milestone must protect these five pillars.

### 1. Responsive momentum

- Ground control, jump buffering, coyote time, double jump, dash, crouch, fast
  fall, one-way drop, and rope use must feel immediate and predictable.
- Required traversal alternates action and recovery instead of long empty walks.
- Normal rooms target 20-60 seconds. A player should rarely spend more than eight
  seconds without a movement, combat, route, or reward decision.

### 2. Read, commit, punish

- Dangerous movement and attacks expose a readable tell before damage.
- Committing to an attack creates risk; enemy recovery creates a real punish
  window.
- Difficulty comes from compatible combinations and timing, not hidden rules or
  inflated one-hit damage.
- After a death, the player should be able to name the missed tell or bad choice.

### 3. Builds change verbs

- Level-up choices may provide clear numeric support, but cards, mastery, and
  equipment must mostly alter triggers, follow-ups, positioning, area coverage,
  defense timing, or resource cadence.
- By the middle of Stage 2, two runs with different card choices should play
  differently without comparing stat screens.
- Reward screens never offer effects that neither equipped discipline can use.

### 4. Fair authored variety

- The current vertical slice uses one reviewed Stage Plan per normal stage while
  combat, progression, rewards, and presentation are finalized.
- Authored rooms still provide route, encounter, hazard, and reward variety within
  each fixed plan; no runtime system invents arbitrary critical geometry.
- The shared hero baseline can clear every required route with any legal loadout.
- Optional routes may be harder, but reward risk rather than gate completion.
- The dormant random planner may return only after fixed-stage gameplay is
  accepted and it can prove the same traversal and content contracts.

### 5. Short-run tension without grind

- A target run lasts 28-38 minutes: Stage 1 6-8, Stage 2 7-9, Stage 3 8-10,
  boss 4-6, and choices/rest 3-5 minutes.
- Common materials survive death so failed runs still teach and progress.
- Base loadouts can clear the game. Persistent progression adds options and
  bounded advantages, not a mandatory grind wall.

## Core Run Loop

```text
main menu
 -> profile / Continue / New Run / Training
 -> optional Arsenal Trial or mechanically equal skip
 -> Armory: two weapons and complete equipment loadout
 -> fixed Stage 1: establish and test the build
 -> stage-clear card
 -> inter-stage Armory
 -> fixed Stage 2: hazards and route risk
 -> stage-clear card + Armory/rest/forge
 -> fixed Stage 3: mixed mastery check
 -> stage-clear card
 -> authored Giant Slime King arena
 -> persistent settlement and run summary
```

Inside a normal stage:

```text
safe entry
 -> traversal or light encounter
 -> route choice
 -> combat/hazard escalation
 -> optional reward risk
 -> checkpoint or recovery beat
 -> final encounter/objective
 -> exit
```

## Stage Cadence

| Stage | Player-facing job | Room target | Content emphasis |
| --- | --- | ---: | --- |
| Ruin Approach | Learn the route language and establish confidence. | 6 required + 1 optional | Basic traversal, Walker, Charger, simple gaps, visible rewards. |
| Flooded Works | Force timing and spending decisions. | 7 required + 1-2 optional | Poison vents, crumbling paths, Shooter, Leaper, rest/forge. |
| Broken Sanctum | Test the completed run build. | 8 required + 2 optional | Shield Guard, Sentry, gates, mixed encounters, reduced recovery. |
| Slime Court | Read patterns and cash in the build. | Authored arena | Four boss patterns, two phases, bounded adds, clear punish windows. |

Normal stages belong to one Lower Ruins region, so templates can share a visual
language while stage profiles change pacing, danger budgets, and room eligibility.

## Hero And Arsenal

The game has one persistent hero. Variable jump, double jump, dash, crouch
clearance, fast fall, one-way drop, rope use, damage recovery, and checkpoint
respawn never depend on equipment or unlocks.

| Weapon discipline | Combat promise | Primary decision |
| --- | --- | --- |
| Sword & Shield | Hold space, stagger threats, and convert defense into heavy punishment. | Commit now for control or wait for a safer counter. |
| Bow | Control range, apply marks, and reposition while maintaining pressure. | Spend a mark for burst or preserve it for area control. |
| Twin Blades | Cross through danger, chain distinct attacks, and exit before retaliation. | Continue a risky chain or disengage with cooldowns intact. |
| Spear | Hold ideal spacing and pin movement. | Keep measured reach or trade it for crowd control. |
| Great Axe | Make slow commitments that break armor and posture. | Spend safety for the strongest stagger payoff. |
| Matchlock | Plan powerful shots around an explicit reload cadence. | Fire now or preserve the prepared shot for a priority target. |

The first migration reuses the three released character kits as the first three
disciplines. Spear, Great Axe, and Matchlock are authored only after that slice
passes combat-fun and balance gates. Exact content is owned by
`docs/design/ARSENAL_EQUIPMENT_PROGRESSION.md`.

## Progression Layers

Each growth layer has one purpose.

| Layer | Scope | Cadence | Purpose |
| --- | --- | --- | --- |
| Run Level | Run | Frequent XP thresholds | Small stabilizing choice that keeps momentum. |
| Card | Run | After each normal stage | Build-defining behavior change. |
| Coin | Run | Shops, rerolls, healing, temporary forge | Tactical opportunity cost. |
| Temporary Forge | Run | One planned rest/forge beat plus rare reward | Tailor current equipment to the current build. |
| Equipment | Persistent ownership | Armory and rare discoveries | Two weapons plus armor, charm, relic, consumable, and enchantments define preparation. |
| Enhancement | Persistent per item | Armory | Deterministic authored weapon/armor growth without failure or random rolls. |
| Mastery | Persistent per discipline | Armory | Unlock behavior options and equip a bounded preset. |
| Material | Persistent shared wallet | Enemies, challenges, settlement | Fund equipment, enhancement, and mastery without affecting route access. |

The stat pipeline resolves sources in this order:

```text
hero base
 -> equipped weapon disciplines and mastery presets
 -> armor, charm, relic, consumable, and enchantments
 -> run-level upgrades
 -> cards
 -> temporary forge/effects
 -> clamps and derived values
```

UI, enemies, cards, rooms, and equipment never edit final player fields directly.

## Content Scope

The first complete run ships with:

- 30 authored stage-specific room templates: 10 Ruin, 9 Flooded, 11 Sanctum;
- 6 normal enemy archetypes and 13 stage-eligible first-run variants;
- 2 special enemy actors: Summon Node and Small Slime;
- 4 core hazard families plus moving platform, switch gate, destructible cache,
  chest, material node, checkpoint, and exit;
- 15 stage-clear cards;
- 5 repeatable run-level micro upgrades;
- a first migration set of 6 weapon forms, existing support equipment, 4
  enchantments, and 18 mastery nodes;
- a bounded complete target of 18 weapon forms, 5 armor, 6 charms, 4 relics, 4
  consumables, and 36 mastery nodes;
- 4 Giant Slime King pattern families.

Content IDs, roles, constraints, and values live in the linked design specs and
typed runtime catalogs indexed by `docs/data/RUNTIME_CATALOG_INDEX.md`. A catalog
entry is not complete until it is reachable in the player-facing loop and has
focused validation.

## Stage Plan And Deferred Generation Contract

- Production currently loads one versioned approved Stage Plan for each normal
  stage through the explicit curated path. Different run seeds must not change its
  rooms, connections, encounters, hazards, rewards, or field pickups.
- A Stage Plan selects authored room templates, socket connections, encounter
  anchors, hazard anchors, optional branches, checkpoints, and rewards; it never
  describes raw arbitrary terrain coordinates.
- Every approved plan records mode, layout version, fixed layout seed, selected
  templates, complete content signature, and validation results.
- Required geometry uses filled rock masses with visibly supported undersides,
  varied top heights, stable landing surfaces, and navigable space between masses.
- Critical route transitions are derived from `MovementMetrics` for the shared
  hero baseline; no weapon discipline, equipment effect, or mastery unlock is a
  route requirement.
- Enemy, trap, reward, and exit placement uses authored anchors only.
- Encounter generation selects a pressure role, then an enemy archetype, then an
  exact stage-eligible variant. It never rolls hidden per-instance combat stats.
- The random planner remains testable but dormant. A later re-entry plan must add
  player-accepted fixed-stage baselines, broad seed validation, guaranteed return
  from committed drops, and rendered review before production can call it again.

## Combat And Encounter Contract

- Basic attacks are reliable; heavy attacks create commitment and stagger;
  skills create identity and room-scale decisions.
- Every hit records source, amount, knockback, tags, and target policy.
- Direct damage is deterministic. There is no per-hit random damage spread and
  enemies/hazards cannot critical in the first run.
- Player critical hits use declared skill conditions with a 1.5 default multiplier,
  not baseline luck; the same build and hit context produce the same outcome.
- Enemies expose one primary lesson and one punish window.
- An encounter has safe entry, support under every mobile enemy, enough response
  space for its pressure roles, and a deterministic completion condition.
- Most normal damage removes one health. Boss or elite exceptions require a
  stronger tell and explicit approval in the content spec.
- Defeat rewards resolve once through a reward owner; enemy AI never grants
  currency directly.

## Boss Contract

The Giant Slime King is an authored two-phase fight with Jump Slam, Body Bump,
Poison Bands, and Small Slime Summon.

- Every pattern has startup, active, recovery, and documented counterplay.
- Phase 2 increases tempo and allows only reviewed legal combinations.
- Poison never removes every safe floor segment.
- Active adds are capped and cleaned between attempts.
- The shared hero can win with every legal base weapon pair and no mastery unlocks.
- Boss victory settles persistent rewards and ends the run; there is no unused
  post-boss card reward.

## Player-Facing Surfaces

Required surfaces are profile-aware main menu, optional Arsenal Trial, Armory,
mastery, gameplay HUD, level-up choice, stage card reward, inter-stage preparation,
pause/settings, boss HUD, death summary, and clear summary.

- Main Menu exposes Continue only for a valid checkpoint suspend; New Run resolves
  any existing suspend explicitly.
- HUD shows health, active and reserve weapons, swap state, enchantment, skills,
  consumable, XP, coins, and immediate objective.
- Debug route metrics and explanatory test labels do not exist in production UI.
- Every visible setting changes runtime behavior.
- Primary flows support keyboard and one standard gamepad layout.
- Danger telegraphs remain legible without relying on color alone.

## Playtest And Balance Gates

Automated validation protects correctness; playtests protect fun.

Record per run:

- run ID, approved-plan version, profile, weapon pair, full loadout, duration, and
  room order;
- damage taken by source and whether the source was visible;
- encounter and room duration;
- offered and selected cards;
- unused skills and equipment;
- coins earned/spent and materials settled;
- death room/pattern and player explanation.

Milestone playtest questions:

1. Was movement enjoyable without enemies?
2. Did each enemy create a different response?
3. Did the selected card change the next stage in a noticeable way?
4. Was an optional route tempting for a clear reason?
5. Did the boss expose understandable punish windows?
6. Did any wait, walk, reward screen, or encounter overstay its purpose?

A milestone does not pass merely because players can finish it. Rework it when
repeated testers describe combat as trading damage, maps as random blocks, rewards
as invisible numbers, or deaths as unclear.

## Requirements

- Fresh boot enters production menu and never loads the retired integrated
  testbed.
- A complete run can be played without debug input or explanatory labels.
- The shared hero and every legal base weapon pair clear every required route and
  the boss.
- All 13 first-run enemy variants preserve their archetype response contract and
  are reproducible from the approved plan/content version.
- Different run seeds reproduce the same approved Stage Plan and map-content
  signature for each normal stage.
- Invalid stages never reach gameplay silently.
- Rewards apply once and state scopes do not leak across run/profile boundaries.
- Persistent writes are versioned and preserve the last valid profile.
- Tutorial completion and skip grant identical mechanical unlocks exactly once.
- Continue restores only validated safe-boundary state and never duplicates a
  reward transaction.
- Every major milestone ends in a playable workflow with rendered inspection.

## Acceptance Criteria

The first complete run is done when a fresh player can:

1. Select a profile, complete or skip the Arsenal Trial, and prepare a legal full
   equipment loadout in the Armory.
2. Complete three varied, valid approved fixed stages with one hero and two
   swappable weapon disciplines.
3. Use both complete weapon kits, support equipment, consumable, and enchantments
   with readable feedback.
4. Gain levels, choose three stage cards, spend coins, forge, enhance, and use
   persistent materials.
5. Save and return at a legal boundary, then Continue without duplicate rewards.
6. Defeat the two-phase boss or lose the run fairly.
7. Reload any of three isolated profiles and start another reproducible run.

The release candidate additionally passes the weapon-pair approved-plan matrix,
economy bounds, profile and suspend round trips, boss scheduler simulation,
keyboard/gamepad path, and 960x540/1280x720/1920x1080 rendered review.

## Non-Goals

- Online accounts, cloud saves, multiplayer, trading, or monetization.
- Multiple biomes, multiple bosses, quests, dialogue trees, or campaign story.
- Arbitrary per-tile procedural terrain or random boss arenas.
- Runtime-random normal-stage topology during the fixed-stage gameplay refinement.
- Multiple playable heroes, unrestricted weapon proliferation, or more than three
  active skills per weapon discipline.
- Grid inventory, durability, item destruction, downgrade, or mandatory grind.
- Final commissioned art, final soundtrack, localization, console certification,
  or storefront work.

## Related

- `docs/product/README.md`
- `docs/design/ARSENAL_EQUIPMENT_PROGRESSION.md`
- `docs/design/PROCEDURAL_REGION_GENERATION.md`
- `docs/design/MAP_AUTHORING_PIPELINE_CONTRACT.md`
- `docs/design/ENEMIES_TRAPS_GIMMICKS.md`
- `docs/design/PLAYER_FACING_FLOW.md`
- `docs/architecture/FIRST_SLICE_ARCHITECTURE.md`
- `.agent/execplans/2026-07-14-single-hero-arsenal-migration.md`
