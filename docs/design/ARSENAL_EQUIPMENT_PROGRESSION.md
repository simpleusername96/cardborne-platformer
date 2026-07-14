---
type: spec
status: active
owner: BK
created: 2026-07-14
last_reviewed: 2026-07-14
canonical_for: Single-hero combat disciplines, equipment loadouts, skills, enchantments, upgrades, materials, tutorial unlocks, and save continuity
supersedes:
  - ./PLAYER_CHARACTER_SYSTEMS.md
  - ./PROGRESSION_EQUIPMENT_ECONOMY.md
source: Owner direction through 2026-07-14, current typed combat/progression catalogs, and comparative game-system research
related:
  - ../product/2d_platform_action_card_game_prd.md
  - ./PLAYER_FACING_FLOW.md
  - ../architecture/FIRST_SLICE_ARCHITECTURE.md
  - ../../.agent/execplans/2026-07-14-single-hero-arsenal-migration.md
  - ./reports/arsenal-equipment-system.html
---

# Arsenal, Equipment, And Progression

## Purpose

Define the target Cardborne build system after replacing character classes with one
persistent hero. The player's identity remains constant while combat style changes
through two equipped weapon disciplines, complete equipment, elemental enchantments,
weapon mastery, deterministic upgrades, run cards, and preparation between stages.

This specification replaces class ownership with arsenal ownership without throwing
away the working Warrior, Archer, and Assassin kits. Those kits become the first
three weapon disciplines.

As of 2026-07-14 this is the required target, not a claim that migration has
landed. The released code still uses the three-profile v1 model; implementation
status and deletion gates live in the linked active ExecPlan.

## Scope

This specification owns:

- the single playable hero and shared movement contract;
- weapon disciplines, concrete weapon forms, attacks, skills, and mastery;
- armor, charm, relic, consumable, and enchantment slots;
- persistent unlocks, deterministic equipment upgrades, materials, and blueprints;
- run-local levels, technique cards, coins, and temporary forging;
- the skippable Arsenal Trial and its permanent unlock behavior;
- profile persistence and resumable-run expectations.

Stage geometry, enemies, hazards, boss patterns, and room assembly stay in their
existing specifications. Their content may reward or test different loadouts, but
required traversal never depends on an equipped weapon or progression unlock.

## Product Contract

> One persistent hero enters each stage with two prepared weapon disciplines and a
> compact equipment loadout, then turns enemy materials, discoveries, and stage
> rewards into new combat verbs rather than larger piles of interchangeable stats.

The player should make three readable decisions:

1. **Preparation:** Which two weapons and support equipment answer the next stage?
2. **Expression:** Which weapon, skill, and enchantment solves the current threat?
3. **Growth:** Which permanent option is worth materials, and which temporary card
   changes this run?

## Canonical Terms

| Term | Meaning | Persistent? |
| --- | --- | --- |
| **Hero** | The one player avatar used for every run. Appearance and equipment presentation may change; identity and baseline traversal do not. | Yes |
| **Weapon discipline** | A complete combat grammar: passive, Basic, Heavy, Skill 1, Skill 2, Skill 3, and six mastery nodes. | Unlock |
| **Weapon form** | A concrete equippable item inside one discipline, with a fixed tradeoff and upgrade track. | Yes |
| **Mastery node** | A permanent discipline-specific behavior option. It changes a verb or interaction, not required traversal. | Yes |
| **Equipment loadout** | Two weapon forms, one armor, one charm, one relic, one consumable, and one enchantment per weapon. | Saved preset |
| **Enchantment** | One elemental rules module socketed into a weapon at an armory. | Recipe unlock; assignment saved |
| **Enhancement** | A deterministic forge rank on a weapon form or armor. | Yes |
| **Technique card** | A run-local behavior modifier offered during a run and filtered by the equipped disciplines. | No |
| **Blueprint** | A unique content unlock for a discipline, weapon form, enchantment, armor, charm, relic, or consumable recipe. It is not stackable currency. | Yes |
| **Material** | Stackable persistent crafting value with one primary economic job. | Yes |
| **Run suspend** | One resumable snapshot written only at a safe boundary. It is not a free manual save state. | Until replaced/abandoned/death/clear |

Do not use `class`, `character mastery`, or `character-compatible weapon` for the
target system. Historical IDs may remain during migration but cannot leak into new
player-facing copy.

## Target Content Envelope

The target is deliberately bounded. New content must replace or extend a listed
slot instead of inventing a parallel progression layer.

| Content | First migration slice | Complete target |
| --- | ---: | ---: |
| Playable heroes | 1 | 1 |
| Weapon disciplines | 3 | 6 |
| Weapon forms | 6 | 18, three per discipline |
| Mastery nodes | 18 | 36, six per discipline |
| Elemental enchantments | 4 | 4 |
| Armor | 3 | 5 |
| Charms | 2 | 6 |
| Relics | 1 | 4 |
| Consumables | 3 | 4 |
| Persistent material currencies | 4 | 4 |

The first migration slice reclassifies existing content. The complete target adds
Spear, Great Axe, and Matchlock after the first three disciplines are fun and
balanced. Dual Axes remain a Twin Blades or Great Axe weapon form until playtests
prove that a separate discipline creates a genuinely different decision pattern.

## Shared Hero Contract

The hero always has accelerated movement, variable jump, coyote time, jump buffer,
double jump, one dash, crouch, fast fall, one-way drop, rope climb, damage recovery,
and checkpoint return. Base health and mobility no longer vary by selected class.

Initial tuning seed:

| Stat | Target |
| --- | ---: |
| Max health | 5 |
| Move speed | 230 px/s |
| Jump velocity | -445 px/s |
| Extra jumps | 1 |
| Dash charges | 1 |
| Dash cooldown | 0.43 s |

Equipment may create bounded tradeoffs, but no legal loadout can fall below the
validated critical-route movement envelope. An item cannot remove double jump,
required crouch clearance, rope use, or checkpoint recovery.

## Weapon Loadout And Controls

The hero equips two weapon forms. Either slot may use the same discipline, but the
exact same form cannot occupy both slots. Switching has a short readable transition
and cannot cancel received hitstun or committed Heavy recovery.

Every discipline preserves the same input grammar:

| Input role | Contract |
| --- | --- |
| Basic | Frequent identity-teaching attack. |
| Heavy | Committed punish, stagger, or setup conversion. |
| Skill 1 | Defense, escape, or short reposition. |
| Skill 2 | Area control or multi-target pressure. |
| Skill 3 | Signature setup, payoff, or long-cooldown rule change. |
| Weapon Swap | Change the complete active kit and HUD set. |
| Consumable | Use the one equipped consumable charge. |

Swapping weapons changes Basic, Heavy, Skill 1-3, passive state display, and active
enchantment feedback. Movement, health, armor, charm, relic, cards, and consumable
remain shared.

## Weapon Disciplines

### First migration disciplines

| Discipline | Combat promise | Existing kit reused | Mastery question |
| --- | --- | --- | --- |
| **Sword & Shield** | Hold space, guard a readable threat, then convert recovery into stagger and punishment. | Warrior: Resolve, Cleave, Breaker, Shield Rush, Ground Splitter, Rally. | Safer counterplay or stronger committed control? |
| **Bow** | Control range, mark targets, and choose when to spend a prepared shot. | Archer: Hunter's Mark, Quick Shot, Power Shot, Vault Shot, Rain Field, Threadline. | Mobile pressure or prepared piercing/area payoff? |
| **Twin Blades** | Alternate fast verbs, cross danger, build status, and leave before retaliation. | Assassin: Flow, Twin Cut, Shadow Lunge, Smoke Step, Kunai Fan, Death Mark. | Sustained sequence or precise burst-and-exit? |

### Complete-target disciplines

| Discipline | Basic / Heavy identity | Skill pattern | Distinct constraint |
| --- | --- | --- | --- |
| **Spear** | Measured thrust chain / planted impale. | Backstep guard, sweep control, pinning signature. | Strong at ideal spacing; weak when crowded. |
| **Great Axe** | Slow arc / armor-breaking overhead. | Shoulder brace, quake, execution window. | Highest stagger and commitment; no safe attack spam. |
| **Matchlock** | Deliberate shot / aimed armor-piercing shot. | Roll reload, powder mine, overcharged volley. | Explicit reload cadence and limited close-range safety. |

Every discipline must pass a representative ground enemy, mobile enemy, ranged
enemy, mixed encounter, and boss-punish fixture with its base form and zero mastery.

## Weapon Forms

Each discipline has exactly three target forms:

1. **Baseline form:** readable default with no hidden penalty.
2. **Specialist form A:** changes one timing, area, defense, or resource interaction
   and states its tradeoff.
3. **Specialist form B:** changes a different decision axis and states its tradeoff.

Forms do not replace the discipline's skill tree. A form may alter at most two
declared behaviors and one bounded stat family. There are no random rarity rolls,
procedural names, hidden affixes, durability, item destruction, or duplicate item
levels. A duplicate discovery converts to the form's declared salvage materials.

Existing migration examples:

| Discipline | Baseline form | Specialist form |
| --- | --- | --- |
| Sword & Shield | Iron Cleaver | Bell Hammer: stronger Breaker/stagger, longer Heavy recovery. |
| Bow | Field Bow | Twinstring Bow: follow-up Quick Shot, lower Power Shot ceiling. |
| Twin Blades | Rust Knives | Hooked Blades: bleed payoff, shorter Shadow Lunge. |

## Full Equipment Loadout

| Slot | Count | Job | Must not become |
| --- | ---: | --- | --- |
| Weapon A | 1 | First complete combat kit and enchantment. | A raw attack-stat stick. |
| Weapon B | 1 | Alternate response and enchantment. | A mandatory traversal key. |
| Armor | 1 | Health, knockback, poise, or mobility tradeoff. | Five-piece inventory bookkeeping. |
| Charm | 1 | Conditional cadence, economy, aerial, or interaction modifier. | A second mastery tree. |
| Relic | 1 | Rare once-per-encounter/stage rule changer. | A universal best-in-slot damage multiplier. |
| Consumable | 1 | Explicit charged recovery or tactical utility. | A general grid inventory. |

Armor has at most two enhancement ranks. Charms and relics have fixed authored
effects and do not level. This keeps comparison readable and prevents every slot
from duplicating weapon progression.

Initial and target support gear:

| Category | Existing forms retained | Complete-target additions |
| --- | --- | --- |
| Armor | Traveler Jacket, Patched Mail, Runner Cloak | Guard Mantle, Alchemist Weave |
| Charm | Copper Charm, Spring Charm | Counter Seal, Scavenger Knot, Element Loop, Swap Pin |
| Relic | Slime Relic | Forge Heart, Storm Lens, Pilgrim Bell |
| Consumable | Small Potion, Dash Tonic, Salvage Kit | Purging Flask |

## Mastery And Skill Trees

Each discipline owns six permanent nodes in a shallow `2 root -> 3 middle -> 1
capstone` graph. Nodes unlock or reshape attacks and skills. They do not grant
required traversal or generic percentage ladders.

- Root nodes present two playstyle directions.
- Middle nodes deepen a direction or create a cross-branch interaction.
- The capstone requires two prerequisites and one Boss Core.
- Purchased nodes remain unlocked; an armory preset equips at most three non-root
  mastery modifiers plus the capstone.
- Respec changes equipped mastery modifiers for free at an armory. It does not
  refund or destroy permanent unlocks.

The existing six nodes per class map directly to the first three disciplines.
Compatibility filters change from `profile_id` to `discipline_id`.

## Enchantments

One unlocked enchantment may be socketed into each equipped weapon at an armory.
The recipe is persistent; the socket assignment is part of the loadout. Reassigning
an owned enchantment is free only between stages or before a run.

| Enchantment | Shared rule | Best natural users | Guardrail |
| --- | --- | --- | --- |
| **Fire** | Apply Scorch. At three stacks, a Heavy or signature skill consumes them for a small burst and +2 direct damage. | Great Axe, Sword & Shield, Matchlock | Burst cannot recursively trigger on-hit effects. |
| **Frost** | Apply Chill. Three stacks slow by 25% for 2 s; Heavy consumes Chill for +35 stagger. | Spear, Bow, Sword & Shield | Bosses receive stagger, never a full freeze. |
| **Poison** | Eligible finishers apply Venom. Three stacks consume after 2 s for 1 damage; reapplication refreshes but does not multiply ticks. | Twin Blades, Bow, Spear | Secondary damage cannot critical or spread itself. |
| **Shock** | A Heavy or skill charges a target for 3 s. The next distinct Heavy/skill consumes it and arcs 1 damage to one nearby target. | Matchlock, Bow, Twin Blades | One arc per consumption; no infinite chains. |

Fast multi-hit attacks do not apply one full stack per hit. Each attack definition
declares `none`, `once`, or `finisher` application. Elements use the shared status
rules above; weapon-specific code may change delivery, not redefine the status.

Enemy resistance is a soft adjustment to buildup or duration. Required encounters
and bosses have no total element immunity, and UI never presents an element as a
required key.

## Deterministic Enhancement

Weapons have three permanent forge ranks; armor has two.

| Rank | Weapon result | Cost role |
| --- | --- | --- |
| 0 | Authored base form. | None |
| 1 | One fixed reliability improvement appropriate to the form. | Common materials |
| 2 | Unlock both authored behavior branches; choose one at an armory. | Common materials + blueprint milestone |
| 3 | Signature capstone with a strict trigger or limit. | Common materials + 1 Boss Core |

Rank 2 branch switching is free after both branches are unlocked. An enhancement
cannot fail, downgrade, destroy, roll a random value, or silently replace an
enchantment. Maximum persistent direct-power contribution is bounded to roughly
15% effective output; most value must come from timing, coverage, defense, status,
or resource cadence.

Armor Rank 1 improves its declared strength; Rank 2 softens its declared drawback
or adds one conditional behavior. Charms and relics remain fixed so the player can
read them without another rank matrix.

## Progression Responsibilities

| System | Player question | Scope |
| --- | --- | --- |
| Weapon discipline | Which combat grammar do I know? | Persistent unlock |
| Weapon form | Which tradeoff version do I own and equip? | Persistent ownership |
| Mastery | Which verbs have I learned within that discipline? | Persistent unlock + preset |
| Enhancement | Which owned form deserves scarce forge investment? | Persistent rank |
| Enchantment | Which status interaction complements this stage and weapon pair? | Persistent recipe + loadout assignment |
| Armor/charm/relic | Which shared strengths and limits support both weapons? | Persistent equipment |
| Run level | Which small weakness should I stabilize now? | Run-local |
| Technique card | Which trigger/follow-up should define this run? | Run-local |
| Temporary forge | How do I adapt the current loadout for the remaining run? | Run-local |

No reward may update final player fields directly. The build resolver applies:

```text
hero base
 -> equipped weapon forms and armor
 -> selected mastery modifiers
 -> charm and relic
 -> run-level upgrades
 -> compatible technique cards
 -> enchantment/status rules
 -> temporary forge effects
 -> clamps and derived values
```

## Materials And Blueprints

Keep four persistent currencies. Element identity belongs to blueprints, not four
additional wallets.

| Material | Primary sources | Primary sinks | Current ID retained |
| --- | --- | --- | --- |
| **Rusted Scrap** | Melee/armored enemies, destructibles, caches | Weapon forms, weapon/armor enhancement | `rusted_scrap` |
| **Sky Thread** | Ranged/mobile enemies, high routes, movement challenges | Precision disciplines, charms, mastery | `sky_thread` |
| **Slime Residue** | Slimes, poison rooms, alchemy caches | Enchantment recipes, consumables, status gear | `slime_residue` |
| **Boss Core** | Major boss victory only | Rank 3, mastery capstone, relics | `boss_core` |

Blueprints are unique unlock records and never appear as a numeric currency. A
blueprint source is authored and previewable: tutorial milestone, optional chest,
stage clear, boss reward, or material purchase. Unlocking a blueprint does not also
pay its material crafting cost unless the reward explicitly says so.

## Reward Sources

| Source | Normal reward job | First-clear job |
| --- | --- | --- |
| Enemy defeat | XP, coins, bounded common material chance/table | No exclusive weapon unlock from an ordinary random enemy. |
| Field pickup | Immediate health, charge, cooldown, coin, or material beat | Never stores equipment in a hidden inventory. |
| Optional chest | Curated gear/blueprint choice or a large material bundle | May guarantee one unseen category item. |
| Stage clear | Technique-card choice and safe armory access | May grant one authored discipline/enchantment blueprint. |
| Boss clear | Settlement, Boss Core, summary | Discipline, Rank 3, or relic milestone. |

Rewards remain transaction-safe and idempotent. A source cannot grant both a
normal reward and its replacement, and suspended runs persist consumed transaction
IDs to prevent resume duplication.

## Arsenal Trial

The onboarding stage is a separate **Arsenal Trial** prologue, not numbered Stage 1.
It is deterministic, short, replayable from Training, and permanently skippable.

First-profile flow:

```text
New Journey
 -> Play Arsenal Trial
    -> Blade room: move, Basic, Heavy
    -> Guard room: block/counter and Shield Rush
    -> Bow room: aim, charge, ranged spacing
    -> Swap trial: use both disciplines against mixed threats
    -> grant Sword & Shield + Bow baseline forms and tutorial completion
 -> or Skip Trial
    -> show concise confirmation
    -> grant the same baseline forms, tutorial completion, and default preset
 -> Armory
 -> Ruin Approach (Stage 1)
```

Skipping never forfeits stats, equipment, blueprints, currency, story-critical
facts, or achievements unrelated to completing the trial itself. The confirmation
states that mechanics can be replayed under Training. The trial is not repeated on
new runs after completion or skip.

Twin Blades become the first normal-run discipline unlock so the player experiences
the reward loop after learning the two baseline responses. Later target disciplines
arrive one at a time through authored milestones.

## Armory And Stage Preparation

Character selection is replaced by one Armory screen. It shows the persistent hero,
next-stage pressure preview, two weapon slots, both enchantments, armor, charm,
relic, consumable, mastery presets, and resulting stats/behavior in one workflow.

- Before a run: all owned equipment and presets may change.
- Between stages: all owned equipment, enchantments, and mastery presets may change.
- At a checkpoint during a stage: inventory may be inspected, but equipment cannot
  change unless the checkpoint is explicitly an armory safe room.
- During combat: only weapon swap and consumable use are available.
- Every comparison shows base effect, enhancement rank, selected branch,
  enchantment, resulting deltas, and tradeoff before confirmation.
- The next-stage preview communicates enemy pressure roles and hazards, not exact
  hidden spawn data or a prescribed best loadout.

## Save And Continue Contract

The current profile autosave is retained and expanded. Player-facing continuity is
split into a durable profile and one optional run suspend per profile.

### Profile save

Three local profile slots are the complete target. Each slot stores:

- schema and content version;
- tutorial completed/skipped state;
- discipline, blueprint, equipment, enchantment, and recipe unlocks;
- weapon/armor enhancement ranks and selected branches;
- mastery purchases and saved mastery presets;
- materials, owned equipment, armory presets, settings, and playtime;
- applied persistent transaction IDs.

Profile writes remain automatic after each accepted persistent command, use a
verified temporary file, and rotate the previous valid file to backup.

### Run suspend

One run may be suspended only at an authored checkpoint, between stages, or through
`Save & Quit` from a safe pause state. It stores:

- profile ID, run schema/content version, run seed, phase, stage/plan version, and
  checkpoint ID;
- health, XP, run level, coins, unsettled materials, consumable state, elapsed time;
- equipped loadout snapshot, cards, micro-upgrades, enchantments, temporary forge;
- completed objectives, consumed reward IDs, and pending mandatory choice state.

It does not serialize arbitrary node trees, exact mid-air position, projectiles,
enemy transforms, animation frames, or partial attack windows. Resume reconstructs
the approved stage and places the hero at the saved checkpoint with deterministic
objective/reward state.

Resuming does not delete the suspend. It remains crash-recoverable until the next
safe boundary atomically replaces it. The suspend is deleted only after explicit
abandon, terminal death settlement, or victory settlement. A corrupt primary
suspend falls back to backup; incompatible content offers a clear `Restart current
stage` or `Abandon run` choice without duplicating rewards.

### Player-facing save flow

- Main Menu: `Continue`, `New Run`, `Profiles`, `Training`, `Settings`, `Quit`.
- `Continue` appears only when the selected profile has a valid suspend.
- `New Run` with an existing suspend asks whether to continue or abandon it.
- Pause: `Resume`, `Loadout Overview`, `Settings`, `Save & Return to Menu`,
  `Abandon Run`.
- Save status uses concise `Saving`, `Saved`, or actionable failure feedback.
- There is no unrestricted manual save/load list and no mid-combat save scumming.

### Migration from profile v1

- Warrior loadout/mastery -> Sword & Shield discipline.
- Archer loadout/mastery -> Bow discipline.
- Assassin loadout/mastery -> Twin Blades discipline.
- Existing weapon ownership, armor, charms, relic, materials, settings, and
  transaction IDs remain.
- The historical v1 selected-character ID maps to the initial active discipline;
  a missing second slot receives a different compatible baseline form.
- Migration writes v2 only after round-trip validation and preserves the v1 backup.

## Requirements

- One hero is the only player identity in production flow.
- Two equipped weapon forms define the active combat choices; support equipment
  modifies both without creating another class.
- The six target disciplines remain behaviorally distinct and base-clear capable.
- Required traversal and stage completion never depend on weapon, enchantment,
  mastery, equipment, or persistent grind.
- Every permanent reward has a visible source, owner, cost, and deterministic result.
- Elements share four global status contracts and cannot create per-weapon copies
  of the same rule.
- Equipment comparisons expose current/result values and behavioral tradeoffs.
- Profile writes and run suspend writes are atomic, versioned, recoverable, and
  duplicate-safe.
- Tutorial skip grants all mechanical tutorial rewards and remains replayable.
- Existing class content is migrated before new disciplines are authored.

## Acceptance Criteria

- A fresh profile can complete or skip the Arsenal Trial and reach the same valid
  Sword & Shield + Bow starting state.
- The hero can equip two weapon forms, switch full kits, and see truthful HUD state.
- Existing Warrior, Archer, and Assassin combat behavior passes after reclassification
  as Sword & Shield, Bow, and Twin Blades.
- Each support-equipment slot changes a distinct, previewed decision axis.
- Every enchantment applies and consumes its shared status deterministically with
  no recursive or critical secondary damage.
- Weapon/armor enhancement round-trips through save v2 and cannot fail/downgrade.
- A profile v1 fixture migrates without losing materials, ownership, mastery intent,
  settings, or transaction history.
- Save & Quit from every legal boundary returns to the main menu; Continue restores
  the same run facts at the authored checkpoint and cannot replay consumed rewards.
- Corrupt primary profile and suspend fixtures recover from valid backups.
- Keyboard/gamepad users can complete profile -> tutorial/skip -> armory -> run ->
  inter-stage preparation -> save/continue -> settlement without debug input.

## Non-Goals

- Multiple playable heroes or cosmetic characters with different gameplay stats.
- More than two active weapon kits, an unrestricted weapon wheel, or combat-time
  equipment swapping.
- Separate helmet/gloves/boots slots, a grid inventory, item weight, durability,
  random rarity rolls, procedural affixes, trading, or online economy.
- Hard elemental immunities, elemental traversal locks, or a required best loadout.
- Exact mid-frame save states, multiple manual run saves, cloud conflict resolution,
  cross-device sync, or save editing tools.

## Related

- `docs/product/2d_platform_action_card_game_prd.md`
- `docs/design/PLAYER_FACING_FLOW.md`
- `docs/architecture/FIRST_SLICE_ARCHITECTURE.md`
- `.agent/execplans/2026-07-14-single-hero-arsenal-migration.md`
- `docs/design/reports/arsenal-equipment-system.html`
