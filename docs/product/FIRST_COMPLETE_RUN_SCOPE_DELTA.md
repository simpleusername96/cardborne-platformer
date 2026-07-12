---
type: spec
status: active
owner: BK
created: 2026-07-12
last_reviewed: 2026-07-12
canonical_for: first complete Cardborne run product scope and clause-level overrides
source: User direction on 2026-07-12 recorded in the actual-game production roadmap
scope: First complete run after the integrated testbed
related:
  - ./2d_platform_action_card_game_prd.md
  - ./FIRST_SLICE_EXPANSION.md
  - ../architecture/FIRST_SLICE_ARCHITECTURE.md
  - ../../.agent/execplans/2026-07-12-actual-game-production-roadmap.md
---

# First Complete Run Scope Delta

## Purpose

Define the first complete production target after the integrated motion/combat
testbed. This specification preserves the original Cardborne product promise while
replacing old MVP restrictions that deferred constrained procedural stages,
multiple playable characters, equipment, materials, and persistent skill trees.

The detailed execution sequence, current-state deltas, validation cadence, and
rollback rules live in
`.agent/execplans/2026-07-12-actual-game-production-roadmap.md`. This document
defines product scope, not implementation order.

## Authority and Override Boundary

Use the product documents in this order when they disagree:

1. This specification defines the first complete production-run scope.
2. `2d_platform_action_card_game_prd.md` remains the baseline for the core promise,
   movement quality, card rewards, readable combat, stage cadence, and boss rules.
3. `FIRST_SLICE_EXPANSION.md` remains active RPG-lite detail for economy,
   equipment, player growth, and encounter vocabulary where compatible with this
   specification.
4. Detailed active design and architecture specifications apply where they do not
   conflict with this document.
5. Testbed plans, handoffs, wireframes, generated previews, and research are
   evidence; they do not define current product scope.

This specification specifically overrides earlier statements that the next
implementation must remain one-character, authored-stage-only, without equipment,
procedural generation, or persistent skill progression.

| Earlier clause | First complete run override |
| --- | --- |
| PRD 2.2 defers local saves, shops, multiple characters, and permanent skill trees. | A versioned local profile, a run-local shop/rest flow, three character archetypes, equipment, and compact character mastery are required. |
| PRD 2.2 and 30.4 defer procedural generation. | Unconstrained tile generation remains excluded; deterministic assembly of authored room templates is required for normal stages. |
| First Slice Expansion requires authored fixed stages and one base character. | Authored room templates form constrained generated stages, and the first complete run supports three playable archetypes. |
| PRD boss defeat restarts the boss stage. | Production death ends the run; retry behavior is developer-only and cannot grant or preserve production rewards. |
| PRD grants a stronger reward after the boss. | Boss victory settles persistent rewards and ends the first complete run; no post-boss card choice is required because there is no following combat stage. |

The roadmap owns execution order and provisional implementation names. It does not
override this product delta, repository policy, or a later explicit user decision.

## Retained PRD Behavior

Unless a clause appears in the table above, retain the PRD's three-stage/card/boss
loop, movement reliability requirements, data-driven card separation, modular
ownership, no-soft-lock stage flow, readable damage rules, and boss
startup/active/recovery telegraphs.

## Scope

The first complete production run is a 2D action-platform roguelite/RPG-lite loop:

1. Start at the main menu.
2. Select one of three characters and a persistent loadout.
3. Generate a reproducible run seed.
4. Clear three constrained, randomly assembled normal stages.
5. Fight enemies, avoid readable traps, explore optional routes, and collect XP,
   coins, materials, equipment, and cards.
6. Choose run-level and stage-clear upgrades.
7. Use a safe rest/shop flow for healing, purchases, and temporary forging.
8. Enter an authored boss arena and defeat a two-phase pattern boss.
9. Settle persistent rewards and show a complete run result.

The target remains compact: one region/biome, three normal stage profiles, one
boss, three characters, and enough content to prove replayable variation and
meaningful build choices.

## Requirements

### Product identity

- The core promise remains: clear short action-platform stages, choose random
  upgrades, and survive readable pattern-heavy boss encounters.
- Movement, combat, map constraints, rewards, and progression must operate as one
  complete run rather than disconnected feature demonstrations.
- The production game boots into a player-facing menu, not `MotionTestStage`.
- `MotionTestStage` may remain as an opt-in diagnostic environment until focused
  production labs replace its useful checks.

### Playable characters

- Use Warrior, Archer, and Assassin as the initial working roster. Their names and
  presentation may change without changing the three-archetype scope or acceptance
  requirements.
- All characters share the critical-path traversal contract:
  - left/right movement;
  - variable jump;
  - baseline double jump;
  - dash;
  - crouch with real body clearance;
  - fast fall;
  - one-way platform drop;
  - damage knockback and recovery.
- Every character has:
  - one passive identity;
  - one basic attack;
  - one heavy attack;
  - three active skills.
- Character identity comes from combat reach, timing, risk, positioning, cooldowns,
  and build compatibility. A character-exclusive skill cannot be required to
  finish a critical route.

### Stage and map generation

- Generate normal stages by assembling authored room templates through typed
  sockets and explicit mission/room graphs.
- Do not generate critical routes through arbitrary per-tile noise or arbitrary
  platform coordinates.
- Deterministic seeds reproduce stage plans, encounters, traps, and rewards for the
  same content/schema version.
- Allowed randomness includes compatible room choice, optional branches, authored
  terrain variants, and budget-safe encounter/reward selection.
- Required routes must be valid for the least-mobile shared character envelope.
- Enemy, trap, reward, checkpoint, and exit placement uses authored, validated
  anchors rather than free coordinates.
- Validation covers graph reachability, required objectives, sockets, collision
  overlap, landing width, headroom, crouch clearance, recovery, checkpoints,
  encounter support, safe response space, and exit access.
- Invalid stages are rejected, retried with deterministic derived seeds, and then
  replaced by a curated known-good fallback if bounded retries fail.
- The first boss arena is authored, not procedurally generated.

### Encounters and traps

- The first normal-enemy set is Walker, Charger, Shooter, Shield Guard, Leaper,
  and Sentry.
- Summon Node is special encounter content; Small Slime is initially a boss add.
- Every burst movement, projectile, repeating trap, and boss attack has readable
  timing appropriate to its threat.
- Encounter generation respects support, patrol/charge room, line of sight,
  approach routes, ceiling clearance, response space, spawn caps, and safe entry.
- Trap generation respects visible approach, stable support, reachable safe zones,
  reversibility, checkpoint safety, and critical-route recovery.
- Most first-run damage removes one health; difficulty rises through combinations,
  timing, and reduced safety rather than one-shot inflation.

### Run-local progression

- XP increases Run Level and offers frequent one-of-three micro-upgrades.
- Stage clears offer one of three build-defining cards.
- Coins fund healing, rerolls, purchases, and temporary forging during the run.
- Cards, XP, Run Level, coins, temporary buffs, and temporary equipment affixes
  reset when the run ends.
- Run-level upgrades and cards have distinct effect pools and cadence.
- The first runtime card catalog contains fifteen tested cards with compatibility,
  stacking, presentation, and effect ownership.

### Persistent progression

- Common materials, Boss Cores, equipment ownership, mastery unlocks, settings,
  and durable content unlocks persist in a versioned local profile.
- Common materials use a shared wallet; mastery purchases remain character-specific.
- Common materials collected during a run are settled on clear or death in the
  first production version. Boss-only rewards require boss defeat.
- Each character has six meaningful mastery nodes across combat, signature skills,
  and survival/mobility.
- At least half of mastery nodes change behavior or available choices rather than
  only increasing a number.
- Development respec is free and non-destructive.

### Equipment and materials

- Persistent loadout slots are Weapon, Armor, Charm, and Relic.
- Consumables use a separate limited-use slot.
- Armor and charms default to shared compatibility; weapons may restrict compatible
  characters or attack styles.
- The initial target is at least twelve persistent equipment items plus a small
  consumable set.
- Persistent crafting uses materials; run-local forging uses coins and applies one
  temporary approved affix.
- The first version has no item destruction, downgrade, durability, or grid inventory.
- Equipment preview and effective-stat output must agree exactly.

### State and reward integrity

- Base character, mastery, equipment, run levels, cards, and temporary effects
  resolve through one deterministic effective-stat path with explicit stacking and
  clamps.
- UI, enemies, stages, cards, and equipment do not mutate unrelated owner state
  directly.
- Reward resolution and collection are idempotent; one source cannot apply twice.
- Stage clear does not depend on collecting every loose physics pickup.
- Persistent saves are versioned and preserve the last valid profile if a write or
  migration fails.
- Reaching zero health ends the production run. Development-only retry modes do not
  define reward settlement or release balance.

### Boss

- The first boss remains the Giant Slime King in an authored arena.
- The fight has two phases and at least four distinct pattern families:
  Jump Slam, Body Bump, Poison Bands, and Small Slime Summon.
- Every damaging pattern exposes startup warning, active damage, recovery, and
  explicit player counterplay.
- Phase 2 may combine patterns only when a valid safe response remains.
- The scheduler limits repeats, cleans up old hazards/adds, and cannot start an
  illegal combination.
- Warrior, Archer, and Assassin must each be able to win with a base loadout.

### User-facing flow and presentation

- Required screens: main menu, character select, loadout, mastery tree, gameplay
  HUD, level-up choice, card reward, rest/shop, pause/settings, boss HUD, death,
  and run clear.
- Production HUD prioritizes health, skills/cooldowns, XP, coins, and immediate
  objectives without hiding traversal or warning zones.
- Debug metrics and route-validation text are opt-in developer overlays.
- Primary flows work with keyboard and one standard gamepad layout.
- Settings shown to the player must affect runtime behavior.
- Use one coherent, license-verified prototype art/audio family before final art.
- Combat and hazards require readable animation, sound, hit feedback, and reduced-
  intensity options where effects could impair readability.

### Quality and validation

- A feature is not complete merely because a resource, script, or JSON entry exists.
- Every visible milestone ends in a user-playable workflow.
- Generation is validated by deterministic fixtures, known valid/invalid geometry,
  seed property sweeps, and curated manual play seeds.
- Combat, rewards, effects, equipment, mastery, saves, and boss scheduling have
  focused automated tests.
- Final validation covers every character, normal-stage profile, representative
  build, death path, boss path, save/reload path, keyboard path, and gamepad path.

## Acceptance Criteria

This production scope is satisfied when:

- a fresh project boot reaches the main menu without entering the testbed;
- the player can choose any of the three characters and start a seeded run;
- each character's passive, basic attack, heavy attack, and three skills work;
- every generated critical route is valid for all three characters;
- three normal stages vary by seed while preserving objectives, budgets, recovery,
  and completion access;
- invalid generation fails closed and uses a known-good fallback;
- normal enemies, traps, rewards, cards, shops, and checkpoints work in generated
  stages without unsupported placements or soft locks;
- run-local and persistent progression have distinct, observable effects;
- equipment, materials, mastery, save, and reload work without duplicate rewards or
  destructive failure;
- the two-phase boss is readable, fair, and defeatable by every character;
- death, clear, settlement, restart, and return-to-menu flows work;
- production UI contains no inert controls or required debug narration;
- automated gates and the final manual run matrix pass.

## Non-Goals

The first complete production run does not include:

- online multiplayer, accounts, cloud saves, trading, or network services;
- multiple biomes, multiple bosses, a narrative campaign, quests, or dialogue trees;
- unlimited procedural tiles, destructible terrain simulation, or random boss arenas;
- more than three initial characters or more than three active skills per character;
- large passive trees, prestige, daily rewards, monetization, or grind-heavy gates;
- grid inventory, durability, item destruction, or downgrade mechanics;
- final commissioned art, final soundtrack, localization, console certification, or
  storefront integration.

## Related

- `docs/product/2d_platform_action_card_game_prd.md`
- `docs/product/FIRST_SLICE_EXPANSION.md`
- `docs/architecture/FIRST_SLICE_ARCHITECTURE.md`
- `docs/design/PLAYER_CHARACTER_SYSTEMS.md`
- `docs/design/ENEMIES_TRAPS_GIMMICKS.md`
- `docs/design/PROCEDURAL_REGION_GENERATION.md`
- `.agent/execplans/2026-07-12-actual-game-production-roadmap.md`
