---
type: spec
status: active
owner: BK
created: 2026-07-12
last_reviewed: 2026-07-12
canonical_for: First-run levels, cards, equipment, materials, shops, forging, rewards, and settlement
source: Existing economy/equipment seed catalogs, original card PRD, first-run scope decisions, and fun contract
related:
  - ../product/2d_platform_action_card_game_prd.md
  - ./PLAYER_CHARACTER_SYSTEMS.md
  - ./ENEMIES_TRAPS_GIMMICKS.md
  - ../architecture/FIRST_SLICE_ARCHITECTURE.md
---

# Progression, Equipment, And Economy

## Purpose

Make every reward answer a different player question. This spec prevents four
parallel systems from becoming repeated damage bonuses and gives implementation
stable IDs, effects, scopes, costs, and settlement behavior.

## Scope

This document covers run levels, 15 cards, coins, materials, equipment ownership,
loadouts, consumables, mastery costs, temporary forging, shops, drops, reward
transactions, death, and clear settlement.

## Progression Responsibilities

| System | Question it asks | Reset |
| --- | --- | --- |
| Run Level | What small weakness should I stabilize now? | End of run. |
| Card | What new interaction should define this build? | End of run. |
| Coin | Do I buy safety, flexibility, or temporary power? | End of run. |
| Temporary Forge | How should current gear support current cards? | End of run. |
| Equipment | What tradeoff and starting pattern do I bring? | Persistent ownership. |
| Mastery | Which kit variant do I unlock for future runs? | Persistent per character. |
| Material | Which persistent option do I unlock next? | Persistent shared wallet. |

No layer may quietly duplicate another layer's cadence and effect pool.

## State Scopes

### Run-local

- run seed and current stage;
- health, XP, run level, coins;
- selected micro upgrades and cards;
- temporary forge affixes and temporary buffs;
- consumable charges for this run;
- pending room/stage reward transaction IDs.

### Persistent profile

- material wallet;
- owned equipment and equipped loadouts;
- mastery purchases by character;
- durable content unlocks and settings;
- schema/save version and last valid backup.

UI only observes snapshots and sends commands. It does not write either scope.

## Run Level Curve

| Level | Total XP | Reward |
| ---: | ---: | --- |
| 1 | 0 | Starting state. |
| 2 | 20 | Choose one of three micro upgrades. |
| 3 | 55 | Choose one of three micro upgrades. |
| 4 | 105 | Choose one of three micro upgrades. |
| 5 | 170 | Choose one of three micro upgrades. |
| 6 | 250 | Choose one of three micro upgrades. |

Level-up pauses gameplay only after the current hit/defeat transaction finishes.
Queued XP can trigger multiple choices sequentially without losing overflow.

### Micro-upgrade pool

| ID | Effect | Max stacks |
| --- | --- | ---: |
| `micro_power` | All direct damage x1.08. | 3 |
| `micro_vitality` | +1 max health and heal 1. | 3 |
| `micro_quick_step` | Dash cooldown -0.04 s, minimum 0.24 s. | 4 |
| `micro_skill_tempo` | Skill cooldowns x0.94, minimum per-skill clamp applies. | 4 |
| `micro_light_foot` | +8 move speed and +4% air acceleration. | 4 |

Offers exclude capped choices. If fewer than three remain, fill from a bounded
`heal_now 2` recovery choice rather than display a dead option.

## Stage Card Rules

- Exactly one card is chosen after each normal stage.
- Default offer is three compatible cards: at least one shared card, at least one
  selected-character card when available, and no duplicate maxed card.
- One reroll costs 12 coins and replaces all unchosen cards without repeating the
  same set.
- Cards apply once through an effect owner and persist through the run.
- Card descriptions state trigger, effect, limit, and character compatibility.
- A repeated card is offered only when its `max_stacks` is greater than one and
  the next stack changes a visible value.

## Card Catalog

### Shared cards

| ID / rarity | Trigger | Effect | Stacks |
| --- | --- | --- | ---: |
| `echo_heavy` / rare | Heavy attack confirms a hit. | After 0.22 s, repeat its hit shape at 40% damage and 40% stagger. Echo cannot trigger on-hit card effects. | 1 |
| `dash_wake` / common | Complete a dash. | Leave a 0.35 s trail; each target takes 1 damage once per dash. Second stack adds +1 trail damage. | 2 |
| `aerial_opener` / common | First attack after spending the extra jump. | +1 damage and +20 stagger; resets on landing. | 1 |
| `perfect_punish` / rare | Hit an enemy during its declared recovery. | +1 damage and reduce the longest active skill cooldown by 0.75 s; 2 s internal cooldown. | 1 |
| `chain_burst` / rare | Kill an enemy with a skill. | 90 px burst deals 2 damage to other enemies. Second stack raises radius to 125 px, not damage. | 2 |
| `kinetic_refund` / common | One Heavy/skill hits at least two targets. | Reduce all active skill cooldowns by 1 s; 3 s internal cooldown. | 1 |
| `second_wind` / common | Clear a required encounter without taking damage in that encounter. | Heal 1, up to once per room. | 1 |
| `last_stand` / legendary | Take damage that leaves exactly 1 HP. | Gain 1.2 s invulnerability and reset Skill 1; once per stage. | 1 |
| `treasure_instinct` / common | Open an optional-route chest. | Add one compatible equipment/forge preview choice; taking it replaces, not duplicates, the normal reward. | 1 |

### Warrior cards

| ID / rarity | Trigger | Effect | Stacks |
| --- | --- | --- | ---: |
| `warrior_seismic_edge` / rare | Breaker hits supported ground. | Create a forward shockwave for 2 damage and 25 stagger. | 1 |
| `warrior_counterweight` / legendary | Guard is consumed by an incoming hit. | Next Heavy within 4 s starts 35% faster and cannot be interrupted during startup. | 1 |

### Archer cards

| ID / rarity | Trigger | Effect | Stacks |
| --- | --- | --- | ---: |
| `archer_split_shaft` / rare | Power Shot hits or reaches max range. | Split into two 1-damage arrows at +/-18 degrees; split arrows cannot split. | 1 |
| `archer_storm_mark` / legendary | Consume Hunter's Mark. | One delayed Rain Field arrow strikes that target for 2 damage after 0.35 s. | 1 |

### Assassin cards

| ID / rarity | Trigger | Effect | Stacks |
| --- | --- | --- | ---: |
| `assassin_afterimage` / rare | Shadow Lunge completes without hitting a wall. | Afterimage repeats the lunge hit at 50% damage without moving the player. | 1 |
| `assassin_red_sequence` / legendary | Consume three Flow stacks. | Apply a 4 s mark; the next distinct verb detonates it for 3 area damage. | 1 |

## Currency And Material Catalog

| ID | Scope | Primary sources | Primary sinks |
| --- | --- | --- | --- |
| `xp` | run | Enemy defeat, encounter clear, stage clear. | Run levels. |
| `coin` | run | Enemy defeat, chest, encounter/stage clear. | Heal, reroll, consumable, temporary forge. |
| `rusted_scrap` | persistent | Walker/Charger/Shield/Sentry, destructibles, caches. | Warrior/shared equipment and mastery. |
| `sky_thread` | persistent | Shooter/Leaper, high optional routes, moving challenges. | Archer/mobility equipment and mastery. |
| `slime_residue` | persistent | Slimes, poison rooms, boss content. | Assassin/survival equipment and mastery. |
| `boss_core` | persistent | Giant Slime King victory only. | Capstone mastery and Slime Relic. |

Common materials are added to the persistent wallet through idempotent pickup
transactions and remain after death. Boss Core is created only by boss victory.

## Equipment Rules

- Persistent slots: Weapon, Armor, Charm, Relic.
- One separate consumable slot has run-local charges.
- Starting weapons are character-compatible; armor/charms are shared by default.
- Alternate items offer a behavior/tradeoff, not a strict linear tier.
- Base loadouts can clear every stage and boss.
- Duplicate owned item discoveries convert to their declared salvage materials.
- Equipment discovery settles immediately so a rare optional-route reward is not
  erased by a later death. Boss-only equipment still requires victory.

## Equipment Catalog

### Weapons

| ID | Compatibility/source | Effect/tradeoff |
| --- | --- | --- |
| `iron_cleaver` | Warrior starting | Baseline Warrior timing; no modifier. |
| `bell_hammer` | Warrior optional cache | Breaker +1 damage and +20 stagger; Heavy recovery +0.12 s. |
| `field_bow` | Archer starting | Baseline Archer projectile timing; no modifier. |
| `twinstring_bow` | Archer high-route cache | Quick Shot repeats at 50% damage after 0.16 s; Power Shot max damage -1. |
| `rust_knives` | Assassin starting | Baseline Assassin timing; no modifier. |
| `hooked_blades` | Assassin Stage 3 cache | Twin Cut second hit applies 1 bleed; Shadow Lunge distance -20 px. |

### Armor

| ID | Source | Effect/tradeoff |
| --- | --- | --- |
| `traveler_jacket` | Shared starting | Baseline armor; no modifier. |
| `patched_mail` | Chest/shop unlock | +1 max health, knockback x0.85, move speed -8. |
| `runner_cloak` | High-route reward | Move speed +16, dash cooldown -0.03 s, max health -1 with minimum 3. |

### Charms and relic

| ID | Source | Effect/tradeoff |
| --- | --- | --- |
| `copper_charm` | Shop/material unlock | First card reroll each run costs 6 fewer coins; no coin-gain multiplier. |
| `spring_charm` | Stage 2 optional reward | First aerial attack after double jump gains +15 stagger; no jump-height change. |
| `slime_relic` | Boss Core unlock | Once per stage, clearing an encounter at full health grants a 1-hit guard for 20 s; guard expires on room exit. |

### Consumables

| ID | Cost/source | Effect |
| --- | --- | --- |
| `small_potion` | Starting or 8 coins | Heal 2; one charge. |
| `dash_tonic` | 10 coins | Dash cooldown -0.12 s until stage exit; one charge. |
| `salvage_kit` | 10 coins | Next material node gives +1 matching common material; one charge. |

## Mastery Economy

The 18 node effects and prerequisites live in `PLAYER_CHARACTER_SYSTEMS.md`.

| Node depth | Cost rule | Design rule |
| --- | --- | --- |
| Root | 4 matching common material | Introduces one kit variant. |
| Middle | 8 matching material + one prerequisite | Extends a chosen branch. |
| Capstone | 10 matching material + 1 Boss Core + two prerequisites | Enables a conditional reset/sequence, not a raw damage multiplier. |

Development builds allow free non-destructive respec. Release balance must remain
clearable with zero mastery nodes.

## Shop And Rest/Forge

After the final Stage 2 encounter, the terminal safe room opens the stage card and
rest/forge flow before Stage 3. It presents one unambiguous action surface:

- heal 2 for 8 coins;
- buy one available consumable for its listed cost;
- reroll the current card offer for 12 coins when a card offer is active;
- forge one equipped item for 15 coins;
- leave.

### Temporary forging

Forging is not a hidden random success roll. The system deterministically offers
three eligible affixes from the run seed and item tags; the player chooses one.

Initial affixes:

| ID | Eligibility | Effect |
| --- | --- | --- |
| `forge_force` | weapon | Direct damage x1.10. |
| `forge_tempo` | weapon/charm | Relevant attack or skill cooldown x0.92. |
| `forge_guard` | armor/relic | First damage in next required encounter is reduced by 1. |
| `forge_stride` | armor/charm | Move speed +10 and air acceleration +5%. |
| `forge_salvage` | charm/relic | Next two material drops gain +1 common material. |

One item may hold one temporary affix. Reforging replaces it only after explicit
confirmation. There is no downgrade, destruction, or no-change result.

## Reward Transactions

Every reward source creates a unique transaction ID based on run seed, stage,
room, source anchor, and reward sequence.

```text
create transaction
 -> resolve deterministic reward
 -> present or spawn claim
 -> apply through owning state service
 -> record transaction consumed
 -> emit result snapshot
```

- Replaying a consumed transaction returns its recorded result and applies nothing.
- Enemy AI references a drop table ID only.
- Stage clear settles objective rewards even if loose pickup visuals remain.
- Reward UI cannot close as success until one valid choice is accepted or an
  explicit skip rule exists; normal stage cards cannot be skipped.

## Economy Targets

| Checkpoint | Expected coin earned | Expected mandatory spend | Intended decision |
| --- | ---: | ---: | --- |
| End Stage 1 | 18-28 | 0 | Save or spend a reroll. |
| Stage 2 rest | 38-58 cumulative | 8-25 | Heal versus forge versus flexibility. |
| End Stage 3 | 65-95 cumulative | 16-45 typical | Build should have made at least one meaningful spend. |

Balance fails when the player can always buy every useful option or can rarely
afford one choice despite normal combat participation.

## Death And Clear Settlement

### On death

- Run-local XP, levels, coins, cards, affixes, buffs, and consumable state reset.
- Common materials and immediately unlocked equipment remain persisted.
- No Boss Core or boss relic can be granted.
- Summary shows stage, seed, build, damage source, materials kept, and unlocks.

### On boss clear

- Same common-material settlement plus one Boss Core and eligible boss unlock.
- Clear summary shows final build and run duration.
- No post-boss card choice is generated.

## Requirements

- All stat/effect sources resolve through one deterministic build pipeline.
- Cards and equipment use stable IDs and compatibility tags.
- Offers contain no capped, incompatible, or functionally dead choice.
- Every transaction is idempotent and attributable to one source.
- Save writes preserve the previous valid profile until replacement succeeds.
- Persistent unlocks add options; they do not gate shared movement or base clear.

## Acceptance Criteria

- A run can gain all six levels without losing overflow or duplicating choices.
- Every one of the 15 cards is offered, applied, stacked/limited, displayed, and
  behavior-tested according to its contract.
- Each equipment item changes the effective-build preview and actual behavior
  identically.
- Shop purchases and forging cannot double-charge or apply after insufficient funds.
- Death and clear settlement pass save round-trip and duplicate-event tests.
- At least three distinct viable builds are observable by Stage 3 for each
  character across curated card seeds.
- Playtests report card/equipment effects as noticeable actions, not invisible
  percentage noise.

## Non-Goals

- Random failure forging, item destruction, downgrade, durability, or grid inventory.
- Persistent character levels, mandatory stat grind, trading, or online economy.
- Unlimited affixes, procedural item names, or rare-tier inflation.
- Offering a reward that cannot affect the selected character.

## Related

- `docs/product/2d_platform_action_card_game_prd.md`
- `docs/design/PLAYER_CHARACTER_SYSTEMS.md`
- `docs/design/ENEMIES_TRAPS_GIMMICKS.md`
- `data/design/first_slice/card_catalog.json`
- `data/design/first_slice/equipment_catalog.json`
- `data/design/first_slice/economy_tables.json`
