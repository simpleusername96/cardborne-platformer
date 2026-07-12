---
type: plan
status: active
owner: BK
created: 2026-07-12
last_reviewed: 2026-07-12
topic: Actual game production after the integrated testbed
scope: Godot 4.7 production roadmap for the first complete Cardborne run
source: User direction on 2026-07-12
related:
  - ../../docs/product/2d_platform_action_card_game_prd.md
  - ../../docs/product/FIRST_SLICE_EXPANSION.md
  - ../../docs/architecture/FIRST_SLICE_ARCHITECTURE.md
  - ../../docs/design/PLAYER_CHARACTER_SYSTEMS.md
  - ../../docs/design/ENEMIES_TRAPS_GIMMICKS.md
  - ../../docs/design/PROCEDURAL_REGION_GENERATION.md
  - ../../docs/design/MAP_AUTHORING_PIPELINE_CONTRACT.md
  - ../../docs/research/foundation_resource_survey_2026-07-05.md
  - ../../docs/research/third_party_adoption_ledger.md
---

# Cardborne Actual Game Production Roadmap - 2026-07-12

This plan moves Cardborne from an integrated mechanics testbed to a complete,
player-facing game loop. It preserves useful movement, combat, damage, enemy,
checkpoint, input, and stage contracts, but stops treating the motion testbed as
the game. Every major phase must end in a user-playable workflow, not only new
infrastructure.

## Purpose

Produce the first complete Cardborne run with:

- three selectable characters;
- shared reliable platforming and character-specific combat kits;
- three constrained, seeded, randomly assembled normal stages;
- authored room templates with generated terrain, encounters, traps, and rewards;
- run-local levels, cards, coins, equipment upgrades, and temporary effects;
- persistent materials, equipment ownership, and compact character skill trees;
- one readable, two-phase boss fight;
- menus, HUD, rewards, loadout, skill tree, death, and clear flows;
- coherent prototype art, animation, sound, and game-feel feedback;
- automated and manual evidence that generated routes are playable.

## Why / Context

The current app intentionally placed many unfinished systems together to learn
how movement, combat, enemies, hazards, checkpoints, UI, and map geometry interact.
That experiment has served its purpose. It exposed the most important production
requirements:

- map generation must be constrained by real character movement;
- visual terrain and collision terrain must communicate the same shape;
- critical routes must work for every selectable character;
- progression systems need distinct time scopes and one stat-resolution path;
- combat content needs complete attacks, feedback, rewards, and encounter context;
- a full playable run must become the unit of progress.

The active PRD remains the broad product baseline, but this plan intentionally
overrides its old sequencing rules that deferred multiple characters, persistent
skill trees, equipment, and procedural generation. Existing specs must be
reconciled before implementation so future work does not follow conflicting scope.

## Decisions Locked With The Owner - 2026-07-12

| Topic | Decision | Source / note |
| --- | --- | --- |
| Product phase | Stop expanding the testbed as the primary product and build the actual game. | User request, 2026-07-12. |
| Map model | Use constrained random generation for terrain, traps, enemies, and rewards. | User request, 2026-07-12. |
| Character depth | Multiple characters need basic attacks, heavy attacks, and multiple skills. | User request, 2026-07-12. |
| Growth | Implement run levels, skill trees, equipment, currencies, materials, and upgrade sinks. | User request, 2026-07-12. |
| Bosses | Define and implement readable boss patterns, not only a large enemy health bar. | User request, 2026-07-12 and active PRD. |
| Shared traversal | Every playable character has a baseline double jump; required routes cannot depend on character-exclusive skills. | Prior owner feedback and current character profiles. |
| Plan first | Create and review a detailed execution plan before broad implementation. | User request, 2026-07-12. |

## Assumptions And Open Decisions

These are planning defaults, not owner-locked product decisions. Change them
before the affected milestone without invalidating earlier completed work.

| Topic | Current planning default | Why it matters | Confirmation point |
| --- | --- | --- | --- |
| Engine | Keep Godot 4.7 and GDScript. | Preserves current work and follows repository policy. | Revisit only with explicit engine-migration approval. |
| Initial roster | Warrior, Archer, and Assassin, using the existing profiles as seeds. | Avoids inventing a fourth character and converts existing test data into real content. | Before Milestone 2 content lock. |
| Run shape | Three generated normal stages followed by one authored boss arena. | Preserves the PRD reward cadence while adding controlled variation. | Before Milestone 3. |
| Map technology | Author rooms in LDtk or Godot scenes, then assemble them by typed sockets. | Random tile noise cannot guarantee intentional platforming. | Select after the Milestone 0 editor spike. |
| Cards | Keep the 1-of-3 stage-clear card system as a run-defining layer. | It remains the original product identity. | Before Milestone 4. |
| Material persistence | Materials, equipment ownership, and skill-tree unlocks persist locally; XP, coins, cards, and temporary affixes reset each run. | Separates long-term growth from run balance. | Before save schema is committed. |
| Equipment scope | Weapon, armor, charm, and relic are equipped; consumables are carried separately. | Keeps loadouts meaningful without a grid inventory. | Before Milestone 4 UI. |
| Character skill scope | Each character ships with one passive, one basic attack, one heavy attack, and three active skills. | Gives real identity without building a large action bar. | Before Milestone 5. |
| Skill trees | Six meaningful persistent nodes per character in the first complete run. | Eighteen nodes are enough to prove branching without content explosion. | Before Milestone 4 data lock. |
| Art direction | Use one coherent, license-verified prototype asset family before commissioning or generating final art. | Readability and animation cannot be judged with unrelated rectangles. | Asset approval gate in Milestone 0. |

## Progress

### Started 2026-07-12

- Product authority now routes through
  `docs/product/FIRST_COMPLETE_RUN_SCOPE_DELTA.md`; compatible PRD and first-slice
  behavior remains active.
- Obsolete testbed execution plans are superseded or archived while
  `MotionTestStage` remains an opt-in diagnostic.
- Current official-source package review recommends an approval-gated LDtk/importer
  and Kenney spike, references State Charts and Maaack components, and defers
  GdUnit4 and Phantom Camera.
- The first package-independent Milestone 1 batch covers character catalog,
  deterministic build resolution, and profile/run state separation.

### Landed / already true

- Godot 4.7 project imports and boots headlessly.
- Three character profiles provide movement and basic-attack tuning seeds.
- Shared player movement includes jump, double jump, dash, crouch input, damage,
  knockback, checkpoints, and respawn foundations.
- Damage payload, hitbox, hurtbox, projectile, hazard, and enemy foundations exist.
- Walker, Charger, Shooter, Shield Guard, Leaper, Sentry, Summon Node, and Small
  Slime test actors exist.
- Input remapping and focused validation scripts exist.
- Seed design data exists for XP, coins, materials, equipment, enemies, traps,
  gimmicks, stage layouts, and procedural region graphs.
- The testbed has produced useful movement metrics and route-surface concepts.

### Still open

- Production main menu, character selection, run director, and complete stage flow.
- Real character combat kits, attack states, cooldown presentation, and animation.
- Runtime cards, level-up choices, rewards, equipment, skill trees, and persistence.
- Room authoring/import pipeline and reusable room template catalog.
- Movement-aware stage and encounter generators with bounded retry and fallback.
- Production Stage 1-3 scenes and a complete boss implementation.
- Cohesive visual/audio assets and production UI.
- Automated route traversal, generation property, economy, save, and boss tests.

### Work intentionally not credited as finished game content

- `MotionTestStage` geometry, labels, and generated rock route.
- Wireframes and generated map previews.
- JSON seed values that have no runtime owner.
- Enemies that work only as isolated colored test actors.
- Settings displayed in UI but not consumed by runtime systems.

## Guiding Implementation Principle

Build one complete, visible loop first, then widen content.

The implementation invariant is:

> Authored intent defines valid room and encounter possibilities; seeded generation
> chooses among those possibilities; runtime validation rejects anything that the
> selected character cannot safely complete.

Additional rules:

1. Do not generate arbitrary tile noise and hope it is traversable.
2. Do not place enemies, traps, or rewards at arbitrary coordinates.
3. Do not let UI, cards, equipment, or skill trees mutate player fields directly.
4. Do not import a large third-party framework without an isolated spike,
   license check, wrapper boundary, and explicit approval.
5. Do not add a second unfinished foundation phase when the current phase can end
   with a user-playable path.
6. Keep `MotionTestStage` as a diagnostic reference until production flows replace
   its useful checks; retire it only in a separate, reviewable change.

## Canonical Terms

| Term | Meaning in this plan |
| --- | --- |
| Run | One attempt from character selection through three stages and the boss. |
| Stage | One generated normal level or one authored boss arena. |
| Room Template | Authored gameplay chunk with terrain, sockets, anchors, tags, and validation metadata. |
| Stage Plan | Seeded graph of selected room templates, connections, budgets, and objectives. |
| Critical Path | Required route from stage entrance to exit. It must work for all characters. |
| Optional Route | Reward or challenge route that may use stricter movement, but cannot block completion. |
| Run Level | Temporary XP level that resets at run end. |
| Mastery | Persistent per-character skill-tree progression. |
| Card | Run-local build modifier selected from a reward choice. |
| Equipment | Persistent owned item selected in the loadout; it may receive run-local upgrades. |
| Material | Persistent crafting or mastery resource. |
| Coin | Run-local purchasing and temporary forging currency. |
| Encounter Budget | Allowed enemy pressure for a room or stage. |
| Hazard Budget | Allowed trap pressure for a room or stage. |
| Generation Report | Seed, selected templates, retries, validations, warnings, and fallback result. |

## Source Map And Evidence Rules

### Source priority

1. Current explicit user decisions.
2. Root and nearest `AGENTS.md` files.
3. `docs/product/README.md` and the active product specifications it routes.
4. This active plan for execution order and planning defaults.
5. Current runtime code and tests as implementation evidence.
6. Active evidence documents and external references.
7. Superseded testbed plans and consumed handoffs only as historical evidence.

### Evidence requirements

- A feature is not complete because a class or JSON entry exists.
- Small implementation slices need a scoped commit and targeted test evidence.
- New durable ownership boundaries need an updated spec or concise decision note.
- Generated content needs reproducible seed evidence and a validation report.
- User-facing flows need rendered inspection and a manual play path.
- Imported packages and assets must update
  `docs/research/third_party_adoption_ledger.md` in the same commit.
- Balance values remain provisional until tested in the complete run.

## Current-State Map - Evidence

| Concern | Owner today | Observed state | Plan handling |
| --- | --- | --- | --- |
| High-level flow | `scripts/autoload/Game.gd`, `scripts/main/Main.gd` | Loads only the motion test and has no production run state machine. | Replace test-only entry with explicit run phases while retaining stage-loading helpers where useful. |
| Run facts | `scripts/autoload/RunState.gd` | Mixes profiles, health, settings, currencies, test flags, and test metrics; most progression values are inert. | Split temporary run facts, persistent profile facts, and build calculation behind narrow commands. |
| Character definition | `scripts/player/CharacterProfile.gd`, `data/characters/*.tres` | Defines base stats and one attack style per profile. | Extend profile data with attack, skill, passive, equipment, and traversal references instead of adding character-specific conditionals to the controller. |
| Player movement/combat | `scripts/player/PlayerController.gd` | One large controller owns movement, damage response, and three basic attack presentations. | Preserve proven motion, then extract combat and skill execution into focused owners. |
| Damage | `scripts/combat/*` | Useful common payload and hit/hurt contracts exist. | Reuse and extend tags, hit policy, source attribution, and status hooks. |
| Enemies | `scripts/enemies/*` | Several isolated test actors exist with local state strings and placeholder visuals. | Promote selected actors into data-backed production scenes; retire duplicate ad hoc state logic when a shared state owner is proven. |
| Stages | `scripts/stages/StageBase.gd`, `MotionTestStage.gd` | Respawn and clear contracts exist, but one 1,100-line testbed owns map authoring, generation, factories, and validation. | Keep `StageBase`; split template loading, generation, encounter allocation, validation, and instantiation into separate owners. |
| Map data | `data/design/first_slice/*.json`, preview tools | Design seed and graph prototypes exist; runtime does not consume a validated production schema. | Promote accepted data into versioned Godot resources or validated runtime JSON. |
| Cards | PRD and design data only | No runtime card directory or reward flow on current master. | Implement data, selection, application, stacking, and UI as a complete slice. |
| Economy | JSON seeds plus counters in `RunState` | No pickups, reward service, drop resolution, shop transaction, or persistence. | Create one reward/economy owner and observable pickup/transaction flows. |
| Equipment and mastery | JSON seed only | No inventory, effective-stat aggregation, unlock rules, loadout, save, or UI. | Implement compact persistent profile and one deterministic stat pipeline. |
| Boss | Design catalog only | No `scripts/bosses/` or boss scene. | Build one pattern scheduler and Slime King content after production combat and stage contracts stabilize. |
| UI | HUD and settings test surfaces | Debug information dominates; production screens and state handling are absent. | Replace with task-specific game screens and explicit focus/pause/input ownership. |
| Tests | Two focused validation scripts | No route clearability, generation, progression, save, encounter, or boss tests. | Add unit, scene, seed-matrix, and full-run gates. |

## As-Is / To-Be Delta Map

| Concern | As-is | To-be | Acceptance check | Guard / leftover check |
| --- | --- | --- | --- | --- |
| Product entry | Immediate motion-test launch. | Main menu -> character select -> new run -> Stage 1. | Fresh boot reaches Stage 1 without debug keys. | Motion-test path is not the production default. |
| Character identity | Stat/color variants with one attack. | Three complete kits with shared traversal and distinct combat decisions. | Each character clears the same production stage and demonstrates every attack/skill. | No profile-ID branches in shared movement. |
| Stage creation | Script-built rectangles plus tiny jitter. | Authored room templates assembled by deterministic graph and typed sockets. | Same seed reproduces the same stage; different seeds vary valid room order and encounters. | No arbitrary unsupported geometry placement. |
| Passability | Independent gap/step checks. | Graph validation plus collision-aware movement-envelope checks and bounded fallback. | Seed suite produces no invalid accepted critical path. | Invalid stage never starts silently. |
| Encounters | Hard-coded enemy factory calls. | Anchored, tagged spawn candidates selected under budgets and compatibility rules. | Spawn report explains every selected enemy, trap, and reward. | No unsupported or floating marker. |
| Growth | Counters and JSON only. | Run XP choices, cards, coins, materials, equipment, mastery, and save all affect play. | A reward can be acquired, displayed, applied once, saved when persistent, and observed in combat. | UI cannot write stats or balances directly. |
| Boss | Catalog entry. | Authored arena, scheduler, telegraphs, four patterns, phase variants, death and reward. | Both player and boss can win; every damaging action exposes startup, active, and recovery. | No pattern bypasses telegraph contract. |
| Presentation | Colored geometry and debug labels. | Coherent prototype asset family, animations, SFX, hit feedback, readable production HUD. | Full run is legible without debug text. | Debug overlays are opt-in only. |

## Scope / Non-Scope

### In scope for the first complete run

- Three playable characters: Warrior, Archer, Assassin.
- Shared baseline movement: run, variable jump, double jump, dash, crouch with
  real collision change, fast fall, one-way drop, damage response, and recovery.
- One basic attack, one heavy attack, three active skills, and one passive per
  character.
- Three generated normal stages, one authored boss arena, and one complete run.
- At least eighteen room templates across entrance, traversal, combat, hazard,
  reward, safe/shop, and exit roles by the final content milestone.
- Six normal enemy archetypes plus the Small Slime boss add.
- Four trap/gimmick families used under placement constraints.
- Fifteen run cards, a six-level run curve, and one-of-three level-up rewards.
- Six mastery nodes per character.
- At least twelve equipment items across weapon, armor, charm, and relic slots.
- Persistent local profile for materials, owned equipment, mastery, settings,
  and durable unlocks.
- Run-local XP, coins, cards, temporary forge rolls, health, stage state, and seed.
- Main menu, character select, HUD, reward, level-up, shop/rest, loadout, mastery,
  pause/settings, death, boss, and clear surfaces.
- Keyboard and gamepad action support before release candidate.
- Coherent prototype art/audio with verified licenses and attribution.

### Non-scope until the first complete run passes

- Online multiplayer or network services.
- Multiple biomes, multiple bosses, narrative campaign, dialogue trees, quests,
  achievements, or localization.
- Unlimited procedural tiles, destructible terrain simulation, or physics-driven
  terrain generation.
- Randomly generated boss arenas.
- Grid inventory, item durability, item destruction, trading, or auction systems.
- More than three active skills per character or per-character resource meters.
- Large passive trees, prestige systems, daily rewards, or monetization.
- Final commissioned art, final music, console certification, or storefront work.

## Proposed Design

### 1. Complete run flow

```text
boot
 -> main menu
 -> character select and persistent loadout
 -> run seed creation
 -> generated Stage 1
 -> stage reward card
 -> generated Stage 2
 -> stage reward card + rest/shop opportunity
 -> generated Stage 3
 -> stage reward card
 -> authored boss arena
 -> boss rewards and persistent material settlement
 -> run clear summary
```

Production default: reaching zero health ends the run and opens the run-result
screen. A nonlethal fall or reset hazard may deal its declared damage and return
the player to the latest safe checkpoint. Development mode may allow unlimited
checkpoint or boss retries, but that mode cannot define release balance or reward
settlement.

### 2. Character and combat contract

All characters share the critical-path movement envelope. Combat identity comes
from reach, timing, positioning, cooldowns, and risk, not from making one
character unable to cross the map.

| Character | Basic attack | Heavy attack | Active skills | Passive | Intended role |
| --- | --- | --- | --- | --- | --- |
| Warrior | Wide two-step sword chain. | Charged Cleave: slow, high stagger, armor during late startup. | Shield Rush, Ground Breaker, Iron Guard. | Grit: reduced knockback and a small low-health defense benefit. | Forgiving close-range control. |
| Archer | Fast horizontal arrow with range falloff rules. | Piercing Shot: charged projectile that passes through enemies. | Backstep Volley, Arrow Rain, Snare Trap. | Patient Aim: bonus after briefly holding position or maintaining distance. | Ranged positioning and route control. |
| Assassin | Rapid short-range dual cut chain. | Execution Lunge: committed forward strike with high punish damage. | Dash Slash, Fan of Knives, Smoke Veil. | Momentum: first attack after a dash gains a bounded bonus. | High mobility and timing risk. |

Each attack or skill definition must declare:

- identifier, owner character, input action, and display data;
- startup, active, recovery, cooldown, and cancel policy;
- damage, stagger, knockback, hit count, and tags;
- movement impulse or movement lock;
- ground/air availability;
- hitbox or projectile definition;
- animation and feedback events;
- stat coefficients and allowed modifiers;
- test scenario and balance notes.

No attack is complete until miss, hit, interruption, cooldown, death, pause, and
stage-transition behavior are defined.

### 3. Stage and room generation contract

Generation order:

```text
run seed
 -> stage profile and difficulty band
 -> mission/room graph
 -> room-template selection
 -> socket and coordinate assembly
 -> traversal validation
 -> encounter/hazard/reward allocation
 -> full validation
 -> scene instantiation
 -> generation report
```

Allowed randomness:

- room-template choice among compatible candidates;
- optional branch count within profile limits;
- room order where mission anchors permit it;
- authored terrain variants inside declared bounds;
- enemy, trap, reward, and prop selection at compatible anchors;
- budget-safe quantity and timing variants;
- cosmetic dressing that has no collision impact.

Required invariants:

- entrance, critical path, exit, safe recovery, and stage objective exist;
- all critical transitions fit the least-mobile shared character envelope;
- collision and visible terrain use the same authored mass or documented one-way
  exception;
- room sockets align without collision overlap or unsupported gaps;
- every landing has minimum width and required headroom;
- required drops cannot strand the player;
- every fall leads to recovery, checkpoint reset, or deliberate damage reset;
- checkpoints, exits, and doors have safe standing and camera space;
- no enemy, trap, chest, or material node floats without an explicit airborne tag;
- boss access cannot be skipped by generated connections;
- stage start is blocked when critical validation fails.

Failure policy:

1. Reject invalid candidate and retain the failure reason.
2. Retry with a deterministic derived seed, up to a bounded attempt count.
3. If retries fail, load a curated fallback Stage Plan for the difficulty band.
4. Show a development warning and preserve the Generation Report.
5. Never replace failure with empty terrain or an unvalidated route.

### 4. Room-template contract

Every production room template declares:

- room ID, role, difficulty band, bounds, camera bounds, and tile scale;
- entry/exit sockets with direction, width, floor height, and approach clearance;
- terrain collision source and one-way surfaces;
- critical route surface sequence and recovery surfaces;
- enemy anchors with platform width, patrol bounds, and compatibility tags;
- trap anchors with warning space, safe response area, and support requirements;
- reward anchors and optional-route tags;
- checkpoint, gate, interactable, destructible, and exit anchors as applicable;
- allowed mirror/variant transformations;
- required and forbidden neighboring room tags;
- validation fixtures for every selectable character.

The first catalog target is eighteen templates:

- 2 entrance templates;
- 4 traversal templates;
- 4 combat templates;
- 3 hazard templates;
- 2 optional reward templates;
- 1 safe/shop template;
- 2 exit/transition templates.

### 5. Encounter, trap, and reward allocation

Placement happens only at authored anchors. Each stage profile supplies encounter,
hazard, reward, and recovery budgets that rise across Stage 1-3.

Core constraints include:

- no spawn inside the entrance safety radius, checkpoint safety radius, exit
  interaction zone, or another collision body;
- every ground enemy requires verified support and patrol room;
- Charger requires a clear charge lane and cannot spawn on a short ledge;
- Shooter and Sentry require a valid line of sight plus a reachable approach or
  safe dodge route;
- Shield Guard requires flanking or spacing room;
- Leaper requires ceiling clearance and a safe landing envelope;
- Summon Node requires an active-child cap and valid child spawn surfaces;
- spike rows require solid support and visible approach distance;
- timed poison requires a reachable safe floor segment during every active window;
- crumbling platforms cannot be the only irreversible critical-path support;
- rewards cannot spawn in damage volumes or behind unavailable character skills;
- combined enemy and trap pressure cannot exceed the room's response-space budget.

The first production enemy set is Walker, Charger, Shooter, Shield Guard, Leaper,
and Sentry. Summon Node is reserved for controlled special encounters; Small
Slime is primarily a boss add until normal-stage swarm balance is proven.

### 6. Progression and economy scopes

| System | Scope | Primary sources | Primary sinks | Reset rule |
| --- | --- | --- | --- | --- |
| XP / Run Level | Run | Enemy defeats, encounters, stage clear. | One-of-three micro-upgrades. | Reset at run end. |
| Cards | Run | Normal-stage reward, rare room, boss reward. | Build choices; reroll costs coins. | Reset at run end. |
| Coins | Run | Enemies, chests, rooms, stage clear. | Healing, rerolls, shop equipment offers, temporary forging. | Reset at run end. |
| Common materials | Persistent | Enemy families, nodes, elite rooms. | Mastery nodes, equipment crafting, permanent upgrades. | Save locally. |
| Boss Core | Persistent | Boss clear. | High-tier mastery and relic blueprints. | Save locally. |
| Equipment ownership | Persistent | Crafting, boss/elite blueprint, clear unlock. | Loadout and upgrade recipes. | Save locally. |
| Temporary affix | Run | Forge/shop/event. | Modifies equipped item for current run. | Reset at run end. |

Reward invariants:

- a reward source resolves at most once;
- deterministic rolls use the run RNG stream, not global random state;
- pickup collection is idempotent;
- stage clear cannot depend on collecting every loose physics pickup;
- persistent settlement occurs through an explicit run-result transaction;
- the first default banks all collected common materials on clear or death, while
  boss-only materials still require the boss reward to have resolved;
- save failure never silently deletes the previous valid profile.

### 7. Effective-stat resolution

One owner calculates final character capabilities in this order:

```text
base character
 -> persistent mastery unlocks
 -> persistent equipment base effects
 -> run-level micro-upgrades
 -> cards
 -> temporary equipment affixes and buffs
 -> final clamps and derived values
```

Movement, attacks, skills, UI, and map validation read snapshots from this owner.
They do not inspect card IDs, equipment IDs, or mastery nodes directly.

Every effect declares stacking behavior:

- additive flat;
- additive percent;
- multiplicative;
- unique/non-stacking;
- highest-only;
- unlock;
- replacement.

Final clamps protect minimum damage, cooldown, movement speed, invulnerability,
projectile count, and other values that could break animation or encounters.

### 8. Persistent mastery trees

Each character starts with six nodes across three branches:

- **Core Combat**: improves basic/heavy identity without eliminating recovery.
- **Signature Skills**: unlocks or changes one skill behavior.
- **Survival/Mobility**: improves forgiveness or positioning without changing the
  critical-path traversal contract.

Tree rules:

- two nodes per branch for the first complete run;
- prerequisites form a small visible graph, not a linear stat list;
- at least half of nodes alter behavior or choice rather than only adding damage;
- materials are character-agnostic unless a later design justifies class tokens;
- unlocks are permanent and versioned in the profile save;
- respec is free in development and has no destructive cost in the first release;
- locked nodes show cost, prerequisite, and resulting behavior before purchase.

### 9. Equipment and upgrades

First release slots:

- Weapon: character-compatible attack modifier or alternate weapon profile.
- Armor: health, recovery, knockback, or movement tradeoff.
- Charm: one bounded utility or build modifier.
- Relic: rare run-shaping modifier, unlocked from bosses or milestones.
- Consumable: separate one-use slot, not part of persistent stat aggregation.

Initial catalog target:

- 4 weapons, including one baseline and one alternative for each combat style;
- 3 armor pieces;
- 3 charms;
- 2 relics;
- 3 consumables.

Upgrade rules:

- no item destruction or stat downgrade in the first release;
- persistent crafting upgrades base item level with materials;
- run forging uses coins and applies one temporary approved affix;
- every item lists compatible characters, slots, source, effects, rarity, and
  upgrade profile;
- equipping an item previews the exact stat and verb changes;
- invalid or missing item IDs fall back safely and produce a data error.

### 10. Card and run-level relationship

Run levels provide frequent, small, broadly useful choices. Stage-clear cards
provide rarer, build-defining changes. They must not duplicate each other.

- Run-level choice examples: health, minor damage, dash cooldown, move speed,
  pickup radius, or modest skill cooldown.
- Card examples: attack replacement, projectile split, conditional damage,
  skill mutation, heavy-attack behavior, or risk/reward economy modifier.
- Equipment establishes the starting loadout and tradeoffs.
- Mastery unlocks durable options and modest baseline growth.

The first card catalog remains fifteen cards, but every card must state compatible
characters, effect owner, stacking rule, presentation text, and automated test.

### 11. Boss pattern contract

The first boss remains the Giant Slime King in an authored arena. Every pattern is
a data-backed state with:

- eligibility and phase;
- target selection or fixed arena zones;
- startup tell and minimum reaction time;
- active hitboxes and hazard lifetime;
- recovery and punish window;
- cooldown, weight, and anti-repeat rule;
- arena-space requirements;
- cleanup on interruption, death, restart, and phase change;
- explicit player counterplay.

Pattern target:

1. Jump Slam with landing shadow and jumpable shockwave.
2. Body Bump with directional tell and wall-safe recovery.
3. Poison Bands with at least one guaranteed reachable safe floor segment.
4. Small Slime Summon with spawn warnings and active-add cap.

Phase 2 adds faster but still bounded timings, wider shockwaves, and two reviewed
combination sequences. The scheduler cannot repeat one pattern more than twice,
cannot begin a pattern while required cleanup is pending, and cannot select a
combination that removes every valid safe response.

### 12. User-facing screens and feedback

Required production surfaces:

- Main Menu: start, continue profile, settings, quit.
- Character Select: role, attacks, skills, passive, loadout summary.
- Loadout: equipment slots, compatible inventory, before/after stats.
- Mastery Tree: branches, prerequisites, costs, preview, purchase result.
- In-Game HUD: health, skills/cooldowns, run level/XP, coins, concise objective.
- Level-Up Choice: three micro-upgrades with controller/keyboard focus.
- Card Reward: three choices, compatibility, current-stack context, reroll.
- Rest/Shop: heal, buy, forge, compare, leave.
- Boss HUD: boss health, phase transition, readable warnings in world space.
- Pause/Settings: input, audio, video, accessibility, return/quit flow.
- Run Result: cause, seed, rewards earned, persistent settlement, restart/menu.

UI must show state and choices without obscuring traversal. Debug metrics and route
validation text move behind an opt-in developer overlay. Keyboard and gamepad focus
order, pause ownership, disabled states, long labels, and 1280x720 scaling are
acceptance requirements, not polish-only work.

### 13. External foundation and asset policy

Milestone 0 evaluates, but does not automatically adopt:

- LDtk plus Godot LDtk Importer for room authoring and typed markers;
- Phantom Camera for production camera behavior;
- GdUnit4 for unit, scene, and seed-matrix testing;
- Godot State Charts or a local state pattern for character/boss state ownership;
- Maaack Game Template components for menu/settings/save comparison;
- one Kenney or similarly coherent, license-verified prototype asset family.

Adoption requires:

- exact release or commit pin;
- local license and attribution record;
- isolated import/boot test;
- one representative integration scenario;
- clear wrapper or removal boundary;
- explicit approval before adding a production dependency.

## Shared Owners To Create, Reuse, Or Retire

Names below are responsibility targets. Exact class names may change after the
Milestone 0 spikes, but ownership must remain narrow.

| Concern | Desired owner | Existing owner to reuse or retire |
| --- | --- | --- |
| Run orchestration | `Game.gd` plus a production run-phase owner. | Reuse loading helpers; retire motion-test-only default flow. |
| Persistent profile | New versioned profile/save owner under `scripts/autoload/`. | Remove persistent concerns from `RunState.gd`. |
| Temporary run facts | Focused `RunState.gd`. | Retire test flags and test metrics from production state. |
| Effective stats/build | Focused player-build/stat resolver under `scripts/player/`. | Retire direct dictionary mutation from unrelated systems. |
| Character kit data | Expanded `CharacterProfile` plus attack/skill resources. | Replace string attack-style switch as the only character distinction. |
| Movement | Focused `PlayerController.gd`. | Preserve proven movement; extract combat and skill execution. |
| Rewards/economy | Reward/drop/transaction owner in a responsibility-shaped module. | Retire hard-coded counter changes and future enemy-embedded rewards. |
| Stage generation | `StageGenerator`, template catalog, and `GenerationReport` owners. | Retire generation from `MotionTestStage.gd`. |
| Stage validation | Separate graph, geometry, encounter, and full-stage validation owner. | Retire distance-only acceptance logic. |
| Stage instantiation | Stage assembler/resolver behind local project vocabulary. | Hide LDtk/importer-specific data from gameplay code. |
| Enemy state | Shared production state contract where it reduces duplication. | Retire duplicated ad hoc state strings only after parity tests. |
| Boss state | Boss scheduler plus isolated pattern owners under `scripts/bosses/`. | No current runtime owner. |
| Cards | Card data, selection, and effect application under `scripts/cards/`. | No current runtime owner. |
| UI | Separate screen scenes/controllers under `scripts/ui/` and `scenes/ui/`. | Retire all-in-one debug HUD as production HUD. |

## Planned Production File Map

This map names likely files so implementation batches have concrete destinations.
Exact filenames may change during Milestone 0, but a change must preserve the
responsibility boundary and update this plan or the accepted architecture spec.

### Existing owners expected to change

- `scripts/main/Main.gd`: production boot and root registration only.
- `scripts/autoload/Game.gd`: run orchestration and scene transitions.
- `scripts/autoload/RunState.gd`: temporary run facts only.
- `scripts/autoload/SignalBus.gd`: cross-owner notifications with typed payloads.
- `scripts/player/CharacterProfile.gd`: base identity, stats, and kit references.
- `scripts/player/PlayerController.gd`: movement and body state after combat extraction.
- `scripts/stages/StageBase.gd`: production stage lifecycle, spawn, checkpoint, and clear.
- `scripts/enemies/EnemyBase.gd`: shared enemy health, damage, defeat, reset, and drop ID.

### New owner candidates

- `scripts/autoload/ProfileState.gd`: versioned persistent profile and save boundary.
- `scripts/player/PlayerBuild.gd`: effective-stat and capability snapshot.
- `scripts/player/PlayerCombatController.gd`: basic/heavy attack execution.
- `scripts/player/PlayerSkillController.gd`: active skill execution and cooldowns.
- `scripts/player/AttackDefinition.gd`: typed attack resource.
- `scripts/player/SkillDefinition.gd`: typed skill resource.
- `scripts/player/EffectDefinition.gd`: typed modifier and stacking contract.
- `scripts/cards/`: card data, reward selection, compatibility, and application.
- `scripts/progression/`: mastery, equipment ownership, crafting, and transactions.
- `scripts/rewards/`: drop tables, deterministic rolls, pickups, and settlement.
- `scripts/stages/generation/`: stage profiles, room templates, graph generation,
  encounter allocation, validation, assembly, and Generation Report.
- `scripts/stages/import/`: LDtk or chosen-editor resolver boundary, if adopted.
- `scripts/bosses/`: boss base, scheduler, Slime King, and isolated pattern owners.
- `scenes/stages/production/`: stage host, room instances, and authored boss arena.
- `scenes/ui/production/`: menu, character, loadout, mastery, reward, shop, HUD,
  pause, death, and clear scenes.
- `data/characters/`, `data/cards/`, `data/equipment/`, `data/skills/`, and
  `data/stages/`: accepted runtime resources.
- `tests/unit/`, `tests/scenes/`, and `tests/generation/`: production test suites if
  GdUnit4 is adopted; otherwise equivalent focused scripts under `tools/`.

### Data-source rule

- Typed Godot resources are the default runtime source for characters, attacks,
  skills, effects, cards, equipment, stage profiles, and encounter definitions.
- LDtk or authored scene files own room geometry and editor markers if that spike wins.
- Versioned profile files own player persistence.
- `data/design/first_slice/*.json` remains design/migration input until each catalog
  is promoted; no gameplay system may silently read both old JSON and new resources
  as competing sources of truth.

## Tasks / Milestones

### Milestone 0 - Reconcile scope and choose production foundations

**Goal:** Remove contradictory guidance and make high-cost dependency decisions
before production code depends on them.

- [x] **0.1 Reconcile active specs and indexes.**
  - As-is: PRD and first-slice docs still defer multiple characters, procedural
    stages, permanent trees, and complex equipment.
  - To-be: write an accepted product delta for the scope in this plan; update
    product indexes and mark conflicting claims explicitly superseded or deferred.
  - Accept: a future session can determine scope without reading chat history.
  - Guard: do not rewrite protected `AGENTS.md` without separate approval.
- [ ] **0.2 Lock canonical vocabulary and progression scopes.**
  - As-is: level, skill, material persistence, equipment, and cards overlap.
  - To-be: define Run Level, Mastery, Card, Equipment, Material, Coin, Stage,
    Room Template, and Stage Plan consistently in specs and data.
  - Accept: every runtime field has one scope and one owner.
  - Guard: no second currency with an indistinguishable purpose.
- [ ] **0.3 Run the room-authoring spike.**
  - Compare LDtk/importer against Godot-native scenes using one room with terrain,
    one-way platform, two sockets, enemy/trap/reward anchors, and camera bounds.
  - Accept: chosen path preserves typed metadata, stable collisions, import
    repeatability, and local resolver isolation.
  - Guard: no simultaneous LDtk and Tiled production pipelines.
- [ ] **0.4 Run focused package spikes.**
  - Evaluate GdUnit4, Phantom Camera, State Charts, and Maaack components only on
    representative scenarios.
  - Accept: record adopt/reference/defer/reject with release, license, integration
    cost, and removal boundary.
  - Guard: do not commit a large package merely to inspect it.
- [ ] **0.5 Select the coherent prototype asset family.**
  - Accept: one room displays player, terrain, enemies, hazards, pickups, prompts,
    and HUD icons with documented licensing.
  - Guard: no mixed asset collage and no unverified commercial redistribution.

*Milestone accept:* scope is coherent, foundation decisions are recorded, and one
production room can be authored, loaded, and inspected without `MotionTestStage`.

### Milestone 1 - Production shell, state scopes, and test harness

**Goal:** Make a clean game boot and durable state model before adding content.

- [ ] **1.1 Implement production boot flow.**
  - As-is: boot immediately starts the testbed.
  - To-be: Main Menu -> Character Select -> Run Start -> production stage host.
  - Accept: keyboard and gamepad can traverse the flow and return safely.
  - Guard: no debug key is required for the primary path.
- [ ] **1.2 Split run and persistent profile state.**
  - To-be: versioned profile owns materials, equipment, mastery, settings, and
    durable unlocks; RunState owns health, XP, coins, cards, temporary effects,
    stage index, and seed.
  - Accept: starting a new run resets only temporary data.
  - Guard: profile save remains unchanged when a run is abandoned before settlement.
- [ ] **1.3 Implement save safety.**
  - Include schema version, validation, temporary write, atomic replacement where
    practical, backup/fallback, and readable error reporting.
  - Accept: corrupted current save can fall back without erasing the last valid save.
- [ ] **1.4 Establish effective-stat resolution and effect registry.**
  - Accept: base, mastery, equipment, level, card, and temporary sources produce a
    deterministic snapshot with clamps and source breakdown.
  - Guard: unsupported effect type fails data validation before gameplay.
- [ ] **1.5 Establish automated test harness and CI command.**
  - Cover state reset, save round trip, stat ordering, effect stacking, input,
    stage loading, and one scene-runner interaction.
  - Accept: one documented command runs the focused production suite headlessly.

*Milestone accept:* a user can start a new production run shell, and state survives
or resets according to its declared scope.

### Milestone 2 - First playable production slice with Warrior

**Goal:** Deliver the first non-testbed gameplay path before broad generation work.

- [ ] **2.1 Refocus the player controller.**
  - Preserve movement and damage behavior; implement real crouch collision and
    extract attack/skill execution from movement ownership.
  - Accept: movement regression room passes standing, crouching, jumping, double
    jumping, dashing, one-way drops, damage, checkpoint, and respawn checks.
- [ ] **2.2 Implement the attack/skill definition contract.**
  - Accept: startup, active, recovery, cooldown, cancel, movement, hitbox,
    animation, and feedback fields drive execution without profile-ID branches.
- [ ] **2.3 Complete Warrior core kit.**
  - Implement basic chain, Charged Cleave, Shield Rush, and one initial skill from
    Ground Breaker or Iron Guard.
  - Accept: hit, miss, interruption, cooldown, air restriction, and death cleanup
    all work in a production encounter room.
- [ ] **2.4 Promote Walker and Charger to production scenes.**
  - Add animation/state feedback, death events, drop IDs, reset, terrain-safe
    movement, and encounter metadata.
  - Accept: both enemies can be fought, defeated, reset, and cannot leave their
    valid navigation surface.
- [ ] **2.5 Build one authored golden-path stage.**
  - Six production rooms or room sections, one checkpoint, one optional reward,
    two enemy types, one trap, one chest/material reward, and one exit.
  - Accept: Warrior clears from production menu to stage result with no debug text.
- [ ] **2.6 Add minimum production HUD and result flow.**
  - Health, skill cooldown, XP, coins, interaction prompt, pause, stage result.
  - Accept: HUD does not cover required play space at 1280x720.

*Milestone accept:* the user can play a short, coherent action-platform stage from
menu to result. This is the first visible product checkpoint.

### Milestone 3 - Constrained stage generation

**Goal:** Replace the fixed golden path with safe seeded stage assembly.

- [ ] **3.1 Implement versioned room-template data and catalog validation.**
  - Accept: unknown tags, duplicate IDs, missing sockets, invalid anchors, or
    missing camera bounds fail before generation.
- [ ] **3.2 Implement deterministic graph and template selection.**
  - Accept: same seed reproduces room order, variants, and objective structure.
  - Guard: generation uses a dedicated RNG stream.
- [ ] **3.3 Implement socket assembly and terrain ownership.**
  - Accept: visible terrain and collision align; no duplicate support surfaces,
    seams, embedded masses, or unsupported critical gaps.
- [ ] **3.4 Implement traversal validation.**
  - Validate graph reachability, required objectives, all critical transitions,
    landing width, headroom, crouch clearance, collision sweeps, recovery routes,
    checkpoint safety, and exit access.
  - Accept: accepted routes pass all three character movement envelopes.
- [ ] **3.5 Implement bounded retry, curated fallback, and Generation Report.**
  - Accept: deliberately impossible template data never loads as a playable stage.
- [ ] **3.6 Convert Stage 1 to generated production content.**
  - Use at least six compatible room templates and three reviewed seeds.
  - Accept: Stage 1 teaches movement and basic combat without relying on a fixed
    room order.

*Milestone accept:* production Stage 1 is deterministic, varied, validated, and
always falls back to a known-good layout when generation cannot satisfy rules.

### Milestone 4 - Rewards, cards, equipment, mastery, and shop loop

**Goal:** Make every combat and exploration reward feed an understandable build.

- [ ] **4.1 Implement reward/drop resolution and pickups.**
  - XP, coins, materials, equipment/blueprint rewards, chest rewards, and stage
    settlement use one deterministic transaction path.
  - Accept: rewards apply once and expose source/result events to UI.
- [ ] **4.2 Implement run levels and micro-upgrade choices.**
  - Accept: XP thresholds pause safely, show three valid choices, apply one effect,
    and resume without duplicate rewards.
- [ ] **4.3 Implement fifteen cards and stage-clear reward flow.**
  - Accept: every card has compatibility, stacking, source breakdown, and a
    focused behavioral test; selection affects the following stage.
- [ ] **4.4 Implement persistent equipment ownership and loadout.**
  - Deliver initial weapon, armor, charm, relic, and consumable subset.
  - Accept: equip comparison and effective stats agree exactly.
- [ ] **4.5 Implement run forging and persistent crafting.**
  - Accept: coins buy temporary affixes; materials unlock or upgrade persistent
    items; no operation destroys an item or decreases a stat.
- [ ] **4.6 Implement six Warrior mastery nodes.**
  - Accept: purchase validates prerequisite/cost, persists, supports free respec in
    development, and changes the previewed behavior or stat.
- [ ] **4.7 Implement rest/shop room flow.**
  - Accept: heal, buy, compare, forge, and leave actions are keyboard/gamepad safe
    and cannot double-charge currency.

*Milestone accept:* one Warrior run supports drops, levels, cards, shopping,
equipment, materials, and persistent mastery from acquisition through save/load.

### Milestone 5 - Complete three-character roster

**Goal:** Finish combat breadth only after shared combat and build contracts work.

- [ ] **5.1 Complete Warrior's remaining skills and passive.**
- [ ] **5.2 Implement Archer basic, heavy, three skills, and passive.**
- [ ] **5.3 Implement Assassin basic, heavy, three skills, and passive.**
- [ ] **5.4 Implement six mastery nodes for Archer and six for Assassin.**
- [ ] **5.5 Complete character-compatible equipment and cards.**
- [ ] **5.6 Run cross-character stage and build matrix.**
  - Accept: each character clears reviewed Stage 1 seeds using base loadout and can
    demonstrate every attack, skill, passive, mastery branch, and compatible item.
  - Guard: no critical route or required reward needs a character-exclusive skill.

*Milestone accept:* character selection changes combat style and build choices,
not basic access to the game.

### Milestone 6 - Full normal-stage content and encounter generation

**Goal:** Build Stage 2 and Stage 3 variation using complete room and enemy vocabularies.

- [ ] **6.1 Finish the eighteen-template room catalog.**
- [ ] **6.2 Promote Shooter, Shield Guard, Leaper, and Sentry to production.**
- [ ] **6.3 Implement encounter allocator and compatibility constraints.**
- [ ] **6.4 Implement spike, poison, pit/reset, crumbling, moving-platform, gate,
  destructible, chest, and material-node production content.**
- [ ] **6.5 Generate Stage 2 with hazard/timing emphasis.**
- [ ] **6.6 Generate Stage 3 with mixed encounters and tighter recovery budget.**
- [ ] **6.7 Balance stage profiles and reward budgets.**
  - Accept: difficulty rises through combinations and reduced safety, not inflated
    one-shot damage.
- [ ] **6.8 Run multi-seed encounter and route matrix.**
  - Accept: no unsupported spawn, unreachable reward, impossible trap timing,
    checkpoint ambush, or exit obstruction across the release seed set.

*Milestone accept:* all three normal stages are varied, character-safe, reward the
player correctly, and lead through the complete card/rest cadence.

### Milestone 7 - Giant Slime King boss and run completion

**Goal:** Complete the first run with a production boss and settlement flow.

- [ ] **7.1 Build authored boss arena and camera contract.**
  - Accept: all characters have approach, attack, dodge, and recovery space.
- [ ] **7.2 Implement boss base, scheduler, phase transition, and cleanup.**
- [ ] **7.3 Implement Jump Slam and Body Bump.**
- [ ] **7.4 Implement Poison Bands with safe-zone validation.**
- [ ] **7.5 Implement warned Small Slime Summon and active-add cap.**
- [ ] **7.6 Implement Phase 2 timing and two reviewed combinations.**
- [ ] **7.7 Implement boss HUD, death/restart, rewards, settlement, and clear screen.**
- [ ] **7.8 Run boss matrix for all characters and representative builds.**
  - Accept: every damaging action has visible startup, active, and recovery;
    repeated scheduler simulation never produces an illegal sequence.

*Milestone accept:* all three characters can complete the full run and the boss can
also defeat the player fairly.

### Milestone 8 - Production presentation, accessibility, and game feel

**Goal:** Replace testbed readability with a coherent playable presentation.

- [ ] **8.1 Apply the approved terrain, character, enemy, pickup, and UI asset family.**
- [ ] **8.2 Implement animation states and event-driven attack/skill timing.**
- [ ] **8.3 Implement hit pause, bounded screen shake, flashes, particles, and
  distinct audio cues with settings and reduced-intensity options.**
- [ ] **8.4 Complete all production UI states.**
  - Loading, empty, unavailable, selected, disabled, purchase failure, save error,
    pause, death, and clear states are explicit.
- [ ] **8.5 Complete keyboard/gamepad remapping and input prompt switching.**
- [ ] **8.6 Render-inspect production screens and gameplay.**
  - Required desktop checks: 1280x720 and 1920x1080.
  - Robustness check: 960x540 for menus/HUD where practical.
  - Accept: no clipping, overlap, hidden fixed content, unreadable warning, or HUD
    obstruction; focus order matches the task flow.
- [ ] **8.7 Remove or gate testbed-only labels and controls.**
  - Guard: diagnostic overlays remain available only through a developer flag.

*Milestone accept:* the complete run communicates controls, danger, rewards, and
state without relying on explanatory debug text.

### Milestone 9 - Release-candidate validation and testbed retirement

**Goal:** Prove the first complete run is stable and remove superseded production paths.

- [ ] **9.1 Run clean-clone import, boot, save, and full-run checks.**
- [ ] **9.2 Run generator property tests and curated manual seed matrix.**
- [ ] **9.3 Run all-character, all-stage, representative-build matrix.**
- [ ] **9.4 Verify economy bounds and no duplicate reward settlement.**
- [ ] **9.5 Verify boss legality, restart, and cleanup under repeated runs.**
- [ ] **9.6 Audit dependencies, assets, attribution, settings, and export configuration.**
- [ ] **9.7 Reconcile docs with runtime and mark completed plans/handoffs appropriately.**
- [ ] **9.8 Retire obsolete testbed production ownership.**
  - Remove dead scene content and factories only after equivalent production tests
    pass; retain a small focused movement/encounter lab if it remains useful.
- [ ] **9.9 Produce release notes and a concise operator/player test path.**

*Milestone accept:* a fresh user can launch, choose any character, complete three
generated stages, make build decisions, defeat the boss, receive persistent
rewards, restart, and reproduce any failure from its run seed.

## Test Plan

### Inner-loop checks

- `git diff --check` for every small batch.
- `./tools/godot.ps1 --path . --headless --import` after script/resource changes.
- Narrow unit or scene test for the changed owner.
- One focused manual room or UI flow, not the whole run.
- Data-schema and ID validation for edited catalogs.

### Milestone gates

- Headless import and short boot.
- All tests owned by the milestone.
- One clean start-to-finish manual path for the milestone's visible workflow.
- Screenshot or short capture for changed user-facing screens and combat feedback.
- No new engine error, orphaned node, invalid resource, or unhandled warning.

### Generator gates

- Determinism: same seed and data version produce the same Stage Plan.
- Diversity: reviewed seeds differ in room order, optional routes, and encounter
  allocation without violating invariants.
- Property sweep: at least 1,000 seeds per stage profile at batch/final gates.
- Geometry fixtures: known valid and invalid transitions for all profiles.
- Full-stage validation: critical path, recovery, objectives, checkpoints, exits,
  anchors, budgets, and collision overlaps.
- Failure fixtures: impossible data reaches bounded fallback, never gameplay.

### Combat and progression gates

- Attack/skill timing and interruption tests.
- Damage attribution, invulnerability, death, and cleanup tests.
- Effect stacking, clamps, compatibility, and source breakdown tests.
- Reward idempotency and deterministic drop tests.
- Save round-trip, migration, corrupt-save fallback, and settlement tests.
- Equipment/mastery transaction and free-development-respec tests.

### Final full-run matrix

- Three characters.
- Three normal stage profiles.
- At least ten curated run seeds plus automated property sweeps.
- Base loadout, one damage build, one mobility build, and one survival build.
- Death at normal stage, death at boss, quit/reload, pause/settings, and clear.
- Keyboard and one standard gamepad layout.
- 1280x720 and 1920x1080 rendered gameplay/UI inspection.

### Validation cadence and rerun policy

- Use narrow tests during implementation.
- Run stage-level suites after a room/generator/encounter batch.
- Run the full seed sweep only at generator milestone gates and final handoff.
- Rerun a failed slow check only after a concrete code/data change or new hypothesis.
- If a GUI automation tool fails twice for tool reasons, use scene tests, captures,
  targeted input simulation, or documented manual verification.

## Guard Checks

- [ ] No profile-ID or card-ID branching in shared movement code.
- [ ] No UI script directly edits effective stats, currencies, or save dictionaries.
- [ ] No enemy script embeds drop quantities that belong to reward data.
- [ ] No stage script parses raw LDtk/importer structures outside the resolver boundary.
- [ ] No generated critical route uses an unvalidated surface transition.
- [ ] No accepted room lacks camera bounds, recovery, or safe entry space.
- [ ] No character-exclusive skill is required on the critical path.
- [ ] No persistent operation overwrites the only valid save directly.
- [ ] No package or asset is copied without ledger, pin, license, and attribution review.
- [ ] No production screen exposes inert settings or fake actions.
- [ ] No testbed debug label is visible in the default production flow.
- [ ] No unrelated user-authored changes are staged or committed.

## Rollback / Safety

- Build production scenes and systems beside the testbed until replacement parity is
  demonstrated. Do not delete `MotionTestStage` early.
- Keep each milestone in scoped commits so a failed subsystem can be reverted
  without discarding unrelated content.
- Pin external packages and isolate them under `addons/` with local wrappers.
- Keep imported source data separate from generated Godot output.
- Version stage, character, card, equipment, and save schemas.
- Preserve a curated known-good Stage Plan for each normal stage profile.
- Preserve the last valid profile save before migrations or settlement.
- Ask before package adoption, destructive cleanup, large asset imports, or any
  engine migration.

## Error Handling

- Missing or conflicting product decision: stop the affected milestone, present
  the exact alternatives and impact, and continue only on unaffected work.
- Package import failure: try one documented compatibility fix; after two tool-level
  failures, reject/defer and use the local fallback instead of debugging the package
  indefinitely.
- Invalid generated stage: reject, retry deterministically, then curated fallback.
- Invalid data ID or effect: fail validation before entering gameplay.
- Save failure: retain previous save, notify the player, and keep unsaved session
  state available for retry where practical.
- Test failure: rerun the narrowest failing fixture after a concrete change; do not
  repeat full suites as a substitute for diagnosis.
- Performance regression: capture the seed, stage plan, node count, and profiler
  evidence before reducing content blindly.

## Risks

| Risk | Consequence | Mitigation |
| --- | --- | --- |
| Scope expansion across every system | Many new unfinished components recreate the testbed problem. | One complete visible workflow per milestone; no parallel content explosion. |
| Procedural geometry remains mathematically valid but unpleasant | Technically clearable maps still feel arbitrary. | Authored templates, reviewed seeds, optional branches, pacing tags, and manual play. |
| Three characters multiply every content/test cost | Balance and bug matrix grows quickly. | Shared movement and effect contracts; complete Warrior first, then breadth pass. |
| Progression layers become redundant | Choices feel like repeated stat bonuses. | Give XP, cards, equipment, and mastery distinct cadence and effect classes. |
| External framework controls architecture | Updates or removal become expensive. | Spike, pin, wrap, ledger, and explicit approval. |
| Persistent upgrades trivialize early stages | Difficulty becomes grind-dependent. | Favor option unlocks and bounded modifiers; validate base-loadout completion. |
| Room catalog is too small | Runs repeat visibly. | Final target of eighteen templates, safe transforms, encounter variants, and seed review. |
| Art integration delays gameplay | Asset fitting becomes another foundation project. | One coherent prototype family, minimal animation set, gameplay timing remains data-driven. |
| Boss combinations remove counterplay | Fight appears unfair despite individual tells. | Pattern legality rules, scheduler simulation, arena validation, all-character manual matrix. |
| Stale documents redirect future work | Agents resume old testbed priorities. | Milestone 0 scope reconciliation and final lifecycle audit. |

## Open Questions

These questions do not block writing this plan. They become blocking only before
the named implementation commitment.

1. Should the production death rule remain immediate run failure at zero health,
   or later gain a limited revive resource? Default: immediate run failure; the
   unlimited retry path remains development-only.
2. Should all common materials collected before death be banked? Default: yes for
   the first complete run; boss-only rewards still require boss defeat.
3. Are persistent materials shared by all characters or stored per character?
   Default: shared wallet, character-specific mastery purchases.
4. Should equipment be universally wearable with compatibility tags, or mostly
   character-specific? Default: armor/charms shared, weapons character-compatible.
5. Should active skills all be available at once or should the player equip two of
   three? Default for the first complete run: all three available through named
   actions, subject to control-layout testing.
6. Should cards be universally offered or filtered by selected character?
   Default: shared core pool plus character-compatible cards; never offer dead choices.
7. Should the first boss reward end the run or open a post-boss upgrade hub?
   Default: settlement and clear summary, no hub exploration yet.
8. What final visual direction should replace the coherent prototype asset family?
   This does not block production systems but must be answered before final art.

## Decision Notes

- 2026-07-12: The testbed is treated as completed discovery work, not the main game.
- 2026-07-12: Room/chunk assembly is the default procedural model; random tile noise
  is rejected for required routes.
- 2026-07-12: The initial roster defaults to the existing Warrior, Archer, and
  Assassin profiles.
- 2026-07-12: The critical path is shared by all characters; combat kits create
  identity without changing required traversal access.
- 2026-07-12: The boss arena remains authored for the first complete run.
- 2026-07-12: External projects are reference or spike candidates until explicitly
  adopted through the dependency and license gate.

## Success Criteria

The plan's implementation is complete only when:

- a fresh boot enters a production menu rather than the motion test;
- the player can select Warrior, Archer, or Assassin;
- every character has one passive, basic attack, heavy attack, and three skills;
- each character can clear every critical route with a base loadout;
- three normal stages are generated reproducibly under room, terrain, encounter,
  hazard, reward, and recovery constraints;
- invalid stages are rejected and fall back safely;
- enemies and traps are supported, readable, and compatible with their rooms;
- XP, cards, coins, materials, equipment, mastery, crafting, and forging have
  distinct scopes and observable gameplay effects;
- the Slime King provides a fair two-phase pattern fight;
- run death, restart, boss clear, settlement, save, and reload all work;
- production UI and feedback are readable without debug narration;
- automated suites and the final manual matrix pass;
- documentation and runtime behavior agree.

## Stop Conditions

- Mark this plan `done` only after all required milestones and final gates pass.
- Ask the owner when an open decision would change save schema, engine choice,
  dependency adoption, persistent economy, destructive cleanup, or final content scope.
- Stop a generated stage from loading on any critical validation failure.
- Do not stop the overall plan merely because a milestone is large; split the
  milestone into a smaller playable batch while preserving its acceptance gate.
- Mark work blocked only after the same external condition prevents progress for
  three consecutive goal turns and no unaffected task remains.

## Next Steps

1. Review the planning defaults and answer only the Open Questions that should
   change Milestone 0 or the first playable production slice.
2. Create the accepted product-scope delta and reconcile conflicting active docs.
3. Run the isolated room-authoring, test-framework, camera, state, shell, and asset
   spikes without importing a production dependency yet.
4. Record decisions in the third-party adoption ledger.
5. Begin Milestone 1 with production boot flow, state scopes, save safety, stat
   resolution, and the focused test harness.

## Handoff Summary

Read first:

- this plan;
- root `AGENTS.md` and `.agent/PLANS.md`;
- the active PRD and first-slice product delta;
- `docs/architecture/FIRST_SLICE_ARCHITECTURE.md`;
- the external foundation survey and adoption ledger.

Produce last:

- a playable release-candidate run;
- passing automated and manual evidence;
- reconciled current specs and lifecycle statuses;
- dependency and asset attribution records;
- concise release notes and reproduction instructions using the run seed.

Stop when:

- all Success Criteria are observable from a clean project checkout and no required
  milestone work remains.
