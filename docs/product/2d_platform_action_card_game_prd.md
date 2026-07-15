---
type: spec
status: active
owner: BK
created: 2026-06-30
last_reviewed: 2026-07-15
canonical_for: Cardborne product identity and first complete run scope
source: Existing PRD, first-run scope delta, first-slice expansion, and owner feedback through 2026-07-15
related:
  - ../design/COMBAT_EQUIPMENT_CRAFTING.md
  - ../design/PROCEDURAL_REGION_GENERATION.md
  - ../design/MAP_AUTHORING_PIPELINE_CONTRACT.md
  - ../design/ENEMIES_TRAPS_GIMMICKS.md
  - ../design/PRODUCTION_UI_CONTRACT.md
  - ../architecture/FIRST_SLICE_ARCHITECTURE.md
  - ../../.agent/execplans/2026-07-15-gameplay-validity-repair.md
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
- three simultaneously equipped combat tools: one melee tool, one ranged tool,
  and one shield, selected by attack/defense context rather than manual swapping;
- run levels, stage-clear cards, coins, blacksmith services, and consumables;
- armor, one passive Spirit Stone, one consumable, deterministic blueprint crafting,
  and two material grades across metal, timber, and textile;
- a skippable and replayable weapon training prologue and automatic single-profile
  persistence for the first vertical slice;
- enemies, traps, optional routes, fall-recovery points, shops, rewards, death,
  settlement, and clear flows;
- one coherent Lower Ruins region with production-readable placeholder art and
  audio.

## Product Promise

> Move one persistent hero through dangerous ruins, read distance and attack
> intent, let melee, a mechanically distinct ranged tool, and a shield answer the
> situation without a weapon menu,
> and turn discovered blueprints, better materials, and Spirit Stones into a build
> that changes how the next room is played.

The player should be able to explain a satisfying run in terms of decisions:

- which route they risked;
- which enemy opening they exploited;
- which card changed their attack pattern;
- what they recrafted, equipped, repaired, or resupplied instead of healing;
- when attacking, defending, changing equipment, or using a passive Spirit effect
  solved an encounter.

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

- Level-up choices may provide clear numeric support, but cards, tool models and
  Spirit Stones must mostly alter triggers, follow-ups, positioning, area coverage,
  defense timing, or resource cadence.
- By the middle of Stage 2, two runs with different card choices should play
  differently without comparing stat screens.
- Reward screens never offer effects that the equipped tools or Spirit Stone cannot use.

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
 -> New Game / Training / Settings
 -> optional weapon training prologue or mechanically equal skip
 -> preparation: melee tool, ranged tool, shield, armor, Spirit Stone, consumable
 -> stage map: first-clear/replay rewards and next destination
 -> fixed Stage 1: establish and test the build
 -> stage-clear card
 -> safe intermission: merchant / Forge / preparation
 -> fixed Stage 2: hazards and route risk
 -> stage-clear card
 -> safe intermission: merchant / Forge / preparation
 -> fixed Stage 3: mixed build check
 -> stage-clear card
 -> safe intermission: merchant / Forge / preparation
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
 -> fall-recovery point or recovery beat
 -> final encounter/objective
 -> exit
```

## Stage Cadence

| Stage | Player-facing job | Room target | Content emphasis |
| --- | --- | ---: | --- |
| Ruin Approach | Learn the route language and establish confidence. | 6 required + 1 optional | Basic traversal, Walker, Charger, simple gaps, visible rewards. |
| Flooded Works | Force timing and spending decisions. | 7 required + 1-2 optional | Poison vents, crumbling paths, Shooter, Leaper, and timed recovery. |
| Broken Sanctum | Test the completed run build. | 8 required + 2 optional | Shield Guard, Sentry, gates, mixed encounters, reduced recovery. |
| Slime Court | Read patterns and cash in the build. | Authored arena | Four boss patterns, two phases, bounded adds, clear punish windows. |

Normal stages belong to one Lower Ruins region, so templates can share a visual
language while stage profiles change pacing, danger budgets, and room eligibility.

## Hero And Combat Equipment

The game has one persistent hero. Variable jump, double jump, dash, crouch
clearance, fast fall, one-way drop, rope use, damage recovery, and fall-recovery
respawn never depend on equipment or unlocks.

The hero always carries one melee tool, one ranged tool, and one shield. Attack
chooses melee for a valid close target; otherwise the equipped ranged tool resolves
its own target and resource policy. Defense always uses the shield. There is no
combat-time weapon swap and no selectable combat class.

| Combat role | First vertical-slice models | Primary decision |
| --- | --- | --- |
| Melee tool | Traveler Sword, Hunting Spear | Balanced close pressure or slower sweet-spot reach. |
| Ranged tool | Hunting Bow, Matchlock | Fast arrow pressure or a high-impact shot followed by reload. |
| Shield | Round Shield, Tower Shield | Fast balanced guard or slow stable brace. |

Every model declares a distinct action, one resource/recovery policy, and one hard
weakness. A new model must differ on at
least two functional axes; damage, speed, color, or element alone do not qualify.
Raw growth comes from rebuilding the same model with better material grades.

The first vertical slice adds no active skill. One equipped Spirit Stone provides
one passive elemental rule and never adds an input, active Art, or resonance gauge.
If a later combat playtest proves that one more decision is necessary, the design
may add at most one active skill; it may not grow into multiple skill slots or a
skill bar. Exact content and selection rules are owned by
`docs/design/COMBAT_EQUIPMENT_CRAFTING.md`.

## Progression Layers

Each growth layer has one purpose.

| Layer | Scope | Cadence | Purpose |
| --- | --- | --- | --- |
| Run Level | Run | Frequent XP thresholds | Small stabilizing choice that keeps momentum. |
| Card | Run | After each normal stage | Build-defining behavior change. |
| Coin | Run | Shops, rerolls, healing, repair, and resupply | Tactical opportunity cost. |
| Equipment | Persistent ownership | Preparation and fixed discoveries | Melee, ranged, shield, armor, Spirit Stone, and consumable define preparation. |
| Blueprint | Persistent unlock | Fixed chests, NPC quests, milestones | Add a new readable tool tradeoff without random rarity. |
| Material Grade | Persistent per crafted item | Blacksmith | Rebuild a known form with better materials, no failure or random rolls. |
| Spirit Stone | Persistent unlock | Fixed shrine or milestone | Add one passive elemental condition without adding a button. |
| Passive Source | Mixed | Spirit Stone and run card | Modify one declared trigger without duplicating the equipment action. |
| Material | Persistent shared wallet | Visible drops, challenges, settlement | Fund crafting and repair without affecting route access. |

The stat pipeline resolves sources in this order:

```text
hero base
 -> equipped melee, ranged, shield, and their material grades
 -> armor, passive Spirit Stone, and consumable
 -> run-level upgrades
 -> cards
 -> consumable and other declared temporary effects
 -> clamps and derived values
```

UI, enemies, cards, rooms, and equipment never edit final player fields directly.

## Content Scope

The first complete run ships with:

- 29 authored normal-stage room templates: 10 Ruin, 8 Flooded, 11 Sanctum;
- 1 authored Safe Intermission shell reused between every combat map;
- 6 normal enemy archetypes and 13 stage-eligible first-run variants;
- 2 special enemy actors: Summon Node and Small Slime;
- 4 core hazard families plus moving platform, switch gate, destructible cache,
  chest, material node, fall-recovery point, and exit;
- 15 stage-clear cards;
- 5 repeatable run-level micro upgrades;
- 6 combat-tool models and blueprints across melee, ranged, and shield roles;
- 2 material grades across metal, timber, and textile, plus 2 passive Spirit Stones;
- 2 armor and 1 consumable in the first vertical slice;
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
  anchors, hazard anchors, optional branches, fall-recovery points, and rewards;
  it never describes raw arbitrary terrain coordinates.
- Every approved plan records mode, layout version, fixed layout seed, selected
  templates, complete content signature, and validation results.
- Required geometry uses filled rock masses with visibly supported undersides,
  varied top heights, stable landing surfaces, and navigable space between masses.
- Critical route transitions are derived from `MovementMetrics` for the shared
  hero baseline; no combat equipment or Spirit Stone is a route requirement.
- Enemy, trap, reward, and exit placement uses authored anchors only.
- Encounter generation selects a pressure role, then an enemy archetype, then an
  exact stage-eligible variant. It never rolls hidden per-instance combat stats.
- The random planner remains testable but dormant. A later re-entry plan must add
  player-accepted fixed-stage baselines, broad seed validation, guaranteed return
  from committed drops, and rendered review before production can call it again.

## Combat And Encounter Contract

- Context attacks are reliable: close qualified threats use melee; otherwise the
  equipped ranged tool resolves its declared line, recall, reload, or ground-target
  policy. No valid ranged intent falls back to melee without consuming a resource.
- The first vertical slice has no active skill. Equipment actions and passive
  Spirit effects must not create hidden extra inputs. A later experiment is capped
  at one explicit active skill and requires a playtest-backed owner decision.
- Defense always uses the shield and distinguishes normal, precise, heavy, and
  unblockable responses with visible tells.
- Every hit records source, amount, knockback, tags, and target policy.
- Direct damage is deterministic. There is no per-hit random damage spread and
  enemies/hazards cannot critical in the first run.
- Player critical hits use declared earned conditions with a 1.5 default multiplier,
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
- The shared hero can win with the three basic combat tools and the starting
  passive Spirit Stone.
- Boss victory settles persistent rewards and ends the run; there is no unused
  post-boss card reward.

## Player-Facing Surfaces

Required surfaces are profile-aware main menu, optional weapon training prologue,
equipment preparation, the safe intermission map, centered merchant and Forge
popups, stage map/replay, gameplay HUD, level-up choice, stage card reward,
pause/settings, boss HUD, death retry choice, and clear summary.

- HUD shows health, the predicted melee/ranged action, shield state, the equipped
  ranged tool's one relevant resource, condition warnings, the equipped passive
  Spirit Stone, consumable, coins, and the immediate objective. Passive effects appear
  only when charged or triggered; persistent materials stay in preparation screens.
- Debug route metrics and explanatory test labels do not exist in production UI.
- Every visible setting changes runtime behavior.
- Gameplay uses remappable keyboard actions. Menus and decision screens are fully
  operable by keyboard and mouse.
- Player-facing explanations are available as concise Korean and English locale
  paths. The selected language uses short, direct copy at a readable size.
- Defeat offers a same-run current-stage retry from the stage-entry snapshot or a
  return to the main menu; fall-recovery points do not imply death-save behavior.
- Danger telegraphs remain legible without relying on color alone.

## Playtest And Balance Gates

Automated validation protects correctness; playtests protect fun.

Record per run:

- run ID, approved-plan version, hero, full equipment loadout, duration, and
  room order;
- damage taken by source and whether the source was visible;
- encounter and room duration;
- offered and selected cards;
- unused equipment and ranged resources;
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
- The shared hero with the three basic combat tools clears every required route and boss.
- All 13 first-run enemy variants preserve their archetype response contract and
  are reproducible from the approved plan/content version.
- Different run seeds reproduce the same approved Stage Plan and map-content
  signature for each normal stage.
- Invalid stages never reach gameplay silently.
- Rewards apply once and state scopes do not leak across run/profile boundaries.
- Persistent writes are versioned and preserve the last valid profile.
- Weapon training completion and skip grant identical mechanical unlocks exactly once.
- Condition and ranged resources can create preparation pressure but can never
  block stage entry: equipped tools receive minimum maintenance or readiness.
- Blueprint and Spirit Stone rewards have fixed recoverable sources; random drops
  cannot permanently deny them.
- Restarting the app restores the last valid persistent profile without duplicating
  a reward or crafting transaction.
- Every major milestone ends in a playable workflow with rendered inspection.

## Acceptance Criteria

The first complete run is done when a fresh player can:

1. Select a profile, complete or skip weapon training, and prepare a legal full
   equipment loadout.
2. Complete three varied, valid approved fixed stages with one hero carrying
   melee, ranged, and shield equipment without manual weapon swapping.
3. Predict and use contextual attacks, shield defense, equipment tradeoffs,
   consumables, and passive Spirit effects with readable feedback.
4. Gain levels, choose three stage cards, spend coins, craft, rebuild, repair,
   resupply ranged resources, and use persistent materials.
5. Restart the app and recover blueprints, materials, crafted grades, condition,
   Spirit Stones, and the equipped loadout without duplicate rewards.
6. Defeat the two-phase boss or lose the run fairly.
7. Reload the local profile and preserve blueprints, materials, crafted grades,
   condition, Spirit Stones, and the equipped loadout.

The release candidate additionally passes the context-attack scenario matrix,
equipment/passive approved-plan matrix, economy bounds, condition/resource
soft-lock fixtures, profile round trips, boss scheduler simulation,
keyboard/mouse path, and 960x540/1280x720/1920x1080 browser-viewport review.

## Non-Goals

- Online accounts, cloud saves, multiplayer, trading, or monetization.
- Multiple biomes, multiple bosses, long quest chains, dialogue trees, or campaign
  story. Short fixed NPC requests for blueprints and Spirit trials are in scope.
- Arbitrary per-tile procedural terrain or random boss arenas.
- Runtime-random normal-stage topology during the fixed-stage gameplay refinement.
- Multiple playable heroes, combat-time weapon swapping, unrestricted weapon
  proliferation, or multiple active-skill slots.
- Grid inventory, ranged-weapon durability on top of ammunition, item destruction,
  downgrade, random affixes, or mandatory grind.
- Final commissioned art or final soundtrack.

## Related

- `docs/product/README.md`
- `docs/design/COMBAT_EQUIPMENT_CRAFTING.md`
- `docs/design/PROCEDURAL_REGION_GENERATION.md`
- `docs/design/MAP_AUTHORING_PIPELINE_CONTRACT.md`
- `docs/design/ENEMIES_TRAPS_GIMMICKS.md`
- `docs/design/PRODUCTION_UI_CONTRACT.md`
- `docs/architecture/FIRST_SLICE_ARCHITECTURE.md`
