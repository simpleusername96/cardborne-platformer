---
type: spec
status: active
owner: BK
created: 2026-06-30
last_reviewed: 2026-07-12
canonical_for: Cardborne product identity and first complete run scope
source: Existing PRD, first-run scope delta, first-slice expansion, and owner feedback through 2026-07-12
related:
  - ../design/PLAYER_CHARACTER_SYSTEMS.md
  - ../design/PROCEDURAL_REGION_GENERATION.md
  - ../design/MAP_AUTHORING_PIPELINE_CONTRACT.md
  - ../design/ENEMIES_TRAPS_GIMMICKS.md
  - ../design/PROGRESSION_EQUIPMENT_ECONOMY.md
  - ../design/PLAYER_FACING_FLOW.md
  - ../architecture/FIRST_SLICE_ARCHITECTURE.md
  - ../../.agent/execplans/2026-07-12-actual-game-production-roadmap.md
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

The first complete run contains:

- three playable characters;
- three seeded normal stages assembled from authored room templates;
- one authored two-phase boss fight;
- character-specific basic attacks, heavy attacks, three skills, and one passive;
- run levels, stage-clear cards, coins, temporary forging, and consumables;
- persistent equipment ownership, materials, and six mastery nodes per character;
- enemies, traps, optional routes, checkpoints, shops, rewards, death, settlement,
  and clear flows;
- one coherent Lower Ruins region with production-readable placeholder art and
  audio.

## Product Promise

> Move through dangerous ruins with a responsive character, read threats, turn
> openings into aggressive attacks, and assemble a build that changes how the
> next room is played.

The player should be able to explain a satisfying run in terms of decisions:

- which route they risked;
- which enemy opening they exploited;
- which card changed their attack pattern;
- what they bought or forged instead of healing;
- how their character kit solved the boss.

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
- Reward screens never offer effects that the selected character cannot use.

### 4. Fair variety

- Seeds vary room order, optional branches, encounters, hazards, and rewards.
- Authored templates define valid possibilities; generation never invents
  arbitrary critical geometry.
- The least-mobile base character can clear every required route.
- Optional routes may be harder, but reward risk rather than gate completion.
- Invalid generation fails closed and loads a curated fallback.

### 5. Short-run tension without grind

- A target run lasts 28-38 minutes: Stage 1 6-8, Stage 2 7-9, Stage 3 8-10,
  boss 4-6, and choices/rest 3-5 minutes.
- Common materials survive death so failed runs still teach and progress.
- Base loadouts can clear the game. Persistent progression adds options and
  bounded advantages, not a mandatory grind wall.

## Core Run Loop

```text
main menu
 -> character and persistent loadout
 -> seeded Stage 1: teach and establish build
 -> stage-clear card
 -> seeded Stage 2: hazards and route risk
 -> stage-clear card + rest/forge
 -> seeded Stage 3: mixed mastery check
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
| Ruin Approach | Learn the seed and establish confidence. | 6 required + 1 optional | Basic traversal, Walker, Charger, simple gaps, visible rewards. |
| Flooded Works | Force timing and spending decisions. | 7 required + 1-2 optional | Poison vents, crumbling paths, Shooter, Leaper, rest/forge. |
| Broken Sanctum | Test the completed run build. | 8 required + 2 optional | Shield Guard, Sentry, gates, mixed encounters, reduced recovery. |
| Slime Court | Read patterns and cash in the build. | Authored arena | Four boss patterns, two phases, bounded adds, clear punish windows. |

Normal stages belong to one Lower Ruins region, so templates can share a visual
language while stage profiles change pacing, danger budgets, and room eligibility.

## Playable Roster

All characters share the same required traversal envelope: variable jump,
baseline double jump, dash, crouch clearance, fast fall, one-way drop, rope use,
damage recovery, and checkpoint respawn.

| Character | Combat promise | Primary decision |
| --- | --- | --- |
| Warrior | Hold space, stagger threats, and convert defense into heavy punishment. | Commit now for control or wait for a safer counter. |
| Archer | Control range, apply marks, and reposition while maintaining pressure. | Spend a mark for burst or preserve it for area control. |
| Assassin | Cross through danger, chain distinct attacks, and exit before retaliation. | Continue a risky chain or disengage with cooldowns intact. |

Exact attacks, skills, passives, timings, and mastery nodes are defined in
`docs/design/PLAYER_CHARACTER_SYSTEMS.md`.

## Progression Layers

Each growth layer has one purpose.

| Layer | Scope | Cadence | Purpose |
| --- | --- | --- | --- |
| Run Level | Run | Frequent XP thresholds | Small stabilizing choice that keeps momentum. |
| Card | Run | After each normal stage | Build-defining behavior change. |
| Coin | Run | Shops, rerolls, healing, temporary forge | Tactical opportunity cost. |
| Temporary Forge | Run | One planned rest/forge beat plus rare reward | Tailor current equipment to the current build. |
| Equipment | Persistent ownership | Loadout and rare discoveries | Starting identity and tradeoffs. |
| Mastery | Persistent per character | Between runs | Unlock options and bounded kit variants. |
| Material | Persistent shared wallet | Enemies, challenges, settlement | Fund equipment and mastery without affecting route access. |

The stat pipeline resolves sources in this order:

```text
character base
 -> persistent mastery
 -> equipped items
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
- 12 persistent equipment items;
- 18 mastery nodes, six per character;
- 4 Giant Slime King pattern families.

Content IDs, roles, constraints, and values live in the linked design specs and
typed runtime catalogs indexed by `docs/data/RUNTIME_CATALOG_INDEX.md`. A catalog
entry is not complete until it is reachable in the player-facing loop and has
focused validation.

## Random Generation Contract

- The generator creates a Stage Plan, not raw terrain.
- A Stage Plan selects room templates, socket connections, encounter anchors,
  hazard anchors, optional branches, checkpoints, and rewards.
- Every accepted plan records seed, data version, retries, selected templates,
  budget use, validation results, and fallback status.
- Required geometry uses filled rock masses with visibly supported undersides,
  varied top heights, stable landing surfaces, and navigable space between masses.
- Critical route transitions are derived from `MovementMetrics` for the complete
  base roster; no character-exclusive combat skill is a route requirement.
- Enemy, trap, reward, and exit placement uses authored anchors only.
- Encounter generation selects a pressure role, then an enemy archetype, then an
  exact stage-eligible variant. It never rolls hidden per-instance combat stats.

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
- Every character can win with a base loadout.
- Boss victory settles persistent rewards and ends the run; there is no unused
  post-boss card reward.

## Player-Facing Surfaces

Required surfaces are main menu, character/loadout selection, mastery, gameplay
HUD, level-up choice, stage card reward, rest/forge, pause/settings, boss HUD,
death summary, and clear summary.

- HUD shows health, skills/cooldowns, XP, coins, and immediate objective.
- Debug route metrics and explanatory test labels do not exist in production UI.
- Every visible setting changes runtime behavior.
- Primary flows support keyboard and one standard gamepad layout.
- Danger telegraphs remain legible without relying on color alone.

## Playtest And Balance Gates

Automated validation protects correctness; playtests protect fun.

Record per run:

- seed, character, loadout, duration, room order, and fallback use;
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
- Three base characters clear every required route and the boss.
- All 13 first-run enemy variants preserve their archetype response contract and
  are reproducible from the accepted stage seed/content version.
- Same seed and content version reproduce the same accepted Stage Plan.
- Invalid stages never reach gameplay silently.
- Rewards apply once and state scopes do not leak across run/profile boundaries.
- Persistent writes are versioned and preserve the last valid profile.
- Every major milestone ends in a playable workflow with rendered inspection.

## Acceptance Criteria

The first complete run is done when a fresh player can:

1. Select any character and persistent loadout.
2. Complete three varied, valid seeded stages.
3. Use every attack and skill with readable feedback.
4. Gain levels, choose three stage cards, spend coins, forge, and use equipment.
5. Collect and settle persistent materials without duplicate rewards.
6. Defeat the two-phase boss or lose the run fairly.
7. Return to menu, reload the profile, and start another reproducible run.

The release candidate additionally passes the all-character seed matrix, economy
bounds, save round trip, boss scheduler simulation, keyboard/gamepad path, and
960x540/1280x720/1920x1080 rendered review.

## Non-Goals

- Online accounts, cloud saves, multiplayer, trading, or monetization.
- Multiple biomes, multiple bosses, quests, dialogue trees, or campaign story.
- Arbitrary per-tile procedural terrain or random boss arenas.
- More than three characters or more than three active skills per character.
- Grid inventory, durability, item destruction, downgrade, or mandatory grind.
- Final commissioned art, final soundtrack, localization, console certification,
  or storefront work.

## Related

- `docs/product/README.md`
- `docs/design/PLAYER_CHARACTER_SYSTEMS.md`
- `docs/design/PROCEDURAL_REGION_GENERATION.md`
- `docs/design/MAP_AUTHORING_PIPELINE_CONTRACT.md`
- `docs/design/ENEMIES_TRAPS_GIMMICKS.md`
- `docs/design/PROGRESSION_EQUIPMENT_ECONOMY.md`
- `docs/design/PLAYER_FACING_FLOW.md`
- `docs/architecture/FIRST_SLICE_ARCHITECTURE.md`
- `.agent/execplans/2026-07-12-actual-game-production-roadmap.md`
