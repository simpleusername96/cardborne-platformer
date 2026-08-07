---
type: spec
status: active
owner: BK
created: 2026-08-07
last_reviewed: 2026-08-07
canonical_for: Cardborne live vehicle upgrade categories, cards, levels, effects, and offer rules
scope: Run-scoped vehicle upgrade catalog and secondary-slot ownership
related:
  - ./vehicle_game_spec.md
  - ../design/VISUAL_SYSTEM.md
  - ../reports/game-system-review/effects-upgrades-as-is.md
---

# Vehicle Upgrade Catalog

## Purpose

Define the complete live Cardborne upgrade catalog in one place. This document
owns card IDs, player-facing categories, level effects, secondary-slot rules,
and reward-offer invariants. `vehicle_game_spec.md` continues to own the larger
five-stage run.

## Scope

This specification covers the 19 run-scoped upgrade cards and 39 selectable
level states loaded from `data/cards/vehicle/`. It does not define permanent
progression, enemy balance, stage rewards, or visual art direction.

## Requirements

- A run uses six player-facing upgrade categories.
- Every card has one explicit semantic artwork ID and complete Korean/English
  title and description text.
- Numeric cards show the real current-to-next value.
- A behavior card shows `New behavior` / `새 행동` at level 1 and
  `Behavior upgrade` / `행동 강화` at later levels.
- Built-in Seeker cards consume no optional weapon slot.
- Ion Field, Orbit Blades, and Wake Mines each consume one optional slot on first
  acquisition. A run may own at most two of those three weapons.
- Every level-up and boss reward freezes exactly three unique legal cards. The
  player must select one; there is no reroll, skip, decline, or fabricated card.
- The runtime accepts only an ID from the exact frozen offer and rejects stale,
  unoffered, or double-submitted IDs without changing the build.

## Upgrade Classification

`category` answers one question: which build lane does the player understand
this card to belong to? It does not encode trigger ownership, weapon slots, or
whether the next level unlocks a behavior.

| Category ID | Korean / English label | Meaning | Cards |
| --- | --- | --- | ---: |
| `primary` | 주무기 / Primary | Held-fire damage, cadence, or projectile form | 4 |
| `secondary` | 보조 무기 / Secondary Weapons | Built-in Seeker behavior or an optional autonomous weapon | 5 |
| `element` | 원소 / Element | One elemental status package applied by player attacks | 3 |
| `dash` | 대시 / Dash | A new result caused by Dash | 2 |
| `emp` | EMP / EMP | A new result caused by EMP | 2 |
| `chassis` | 차체 / Chassis | Persistent movement, collection, or survivability stats | 3 |

Two separate axes complete the classification:

- `change_kind`: `stats`, `unlock`, or `enhance` for the next level;
- `secondary_slot_kind`: empty, `built_in`, or `optional`.

This replaces the old `family` field, which mixed trigger, result, weapon type,
and reward grouping in one label.

## Shared Baselines

These base values make multiplier and behavior cards unambiguous.

| System | Live baseline |
| --- | --- |
| Pulse Cannon | 18 damage, 0.12-second interval, 1,120 px/s, radius 7; minimum interval 0.085 seconds |
| Seeker Launcher | 25 damage, 1.35-second interval, 560 range; one built-in Seeker |
| Dash | 0.20-second duration, 1,220 px/s, 1.25-second cooldown |
| EMP | 62 damage, radius 285, 2.1-second stun, 0.42-second startup, 13-second cooldown |
| Chassis | 120 maximum hull, 280 px/s movement |
| Experience shard | 92 attraction radius and 34 collection radius |

## Complete Catalog

### Primary

| ID | Korean / English | Levels | Exact level effect |
| --- | --- | ---: | --- |
| `kinetic_rounds` | 운동탄 / Kinetic Rounds | 3 | L1: damage ×1.15 = 20.70. L2: ×1.3225 = 23.805. L3: ×1.520875 = 27.37575. |
| `rapid_cycle` | 고속 순환 / Rapid Cycle | 3 | L1: interval ×0.90 = 0.108 s. L2: ×0.81 = 0.0972 s. L3: ×0.729 = 0.08748 s. The global 0.085-second minimum still applies. |
| `forked_muzzle` | 분기 포구 / Forked Muzzle | 2 | L1 unlock: every shot adds one alternating side round at ±7°, dealing 40% primary damage. L2 enhance: two side rounds at −7° and +7°, each dealing 32.5%. The main round is unchanged. |
| `phase_lance` | 위상 창 / Phase Lance | 2 | L1 unlock: each primary round can pass through one enemy. L2 enhance: each round can pass through two enemies. Solid cover still stops the shot. |

### Secondary Weapons

| ID | Korean / English | Slot | Levels | Exact level effect |
| --- | --- | --- | ---: | --- |
| `twin_seekers` | 쌍둥이 추적탄 / Twin Seekers | Built-in | 2 | L1 unlock: fire two Seekers at distinct eligible targets; each deals 85% of base Seeker damage (21.25). L2 enhance: fire three; each deals 70% (17.5). |
| `marked_salvo` | 표식 일제사 / Marked Salvo | Built-in | 1 | Primary hits mark one target for 2.5 seconds. Seekers prioritize it and deal 25% more damage. A new mark replaces the prior mark. |
| `ion_field` | 이온 역장 / Ion Field | Optional | 3 | L1 unlock: 8 DPS in radius 120. L2 enhance: 12 DPS in radius 140. L3: 16 DPS in radius 160. Damage ticks every 0.25 seconds. |
| `orbit_blades` | 궤도 칼날 / Orbit Blades | Optional | 3 | L1 unlock: 2 blades, 14 damage each. L2: 3 blades, 18 damage. L3: 4 blades, 22 damage. Orbit radius is 78; one blade has a 0.55-second per-target hit cooldown. |
| `wake_mines` | 항적 기뢰 / Wake Mine Layer | Optional | 3 | L1 unlock: 48 damage, 3.2-second placement, cap 3, radius 96. L2: 60 damage, 2.8 seconds, cap 4, radius 108. L3: 72 damage, 2.4 seconds, cap 5, radius 120. Mines last 8 seconds and detect targets within 54. |

The Seeker is always equipped. The optional slot cap creates a choose-two
decision among Ion Field, Orbit Blades, and Wake Mines.

### Element

| ID | Korean / English | Levels | Exact level effect |
| --- | --- | ---: | --- |
| `incendiary_core` | 소이 코어 / Incendiary Core | 1 | Primary hits apply Burn: 2 DPS per stack, 3-second duration, maximum 3 stacks. |
| `toxin_core` | 독성 코어 / Toxin Core | 1 | Primary hits apply Poison: 2 DPS per stack, 5-second duration, maximum 3 stacks. |
| `cryo_core` | 빙결 코어 / Cryo Core | 1 | Primary hits apply Chill: 6% movement/attack slow per stack, 2-second duration, maximum 3 stacks. Boss magnitude and duration are halved. |

The three elemental roots can coexist and stack independently. There are no
intermediate or capstone branch cards.

### Dash

| ID | Korean / English | Levels | Exact level effect |
| --- | --- | ---: | --- |
| `coolant_wake` | 냉각 점화 / Coolant Surge | 1 | Completing Dash reduces the primary interval by 15% for 2 seconds. The 0.085-second global minimum still applies. |
| `phase_shear` | 위상 절단 / Phase Shear | 1 | The first enemy crossed by Dash is marked for 3 seconds and takes 20% more damage. Crossing a new target transfers the mark. |

### EMP

| ID | Korean / English | Levels | Exact level effect |
| --- | --- | ---: | --- |
| `emp_aftershock` | EMP 여진 / EMP Aftershock | 1 | 0.72 seconds after the main EMP, emit one pulse with 34 damage, 193.8 radius (68% of base), 1.25-second stun, and projectile clearing to radius +40. |
| `static_aegis` | 정전기 방벽 / Static Aegis | 2 | L1 unlock: the main EMP grants 18 barrier for 10 seconds. L2 enhance: grant 24 barrier for 10 seconds. The aftershock does not grant barrier. |

### Chassis

| ID | Korean / English | Levels | Exact level effect |
| --- | --- | ---: | --- |
| `tuned_thrusters` | 조율 추진기 / Tuned Thrusters | 3 | L1: movement ×1.08 = 302.4 px/s. L2: ×1.16 = 324.8 px/s. L3: ×1.24 = 347.2 px/s. |
| `pickup_magnet` | 수집 자석 / Pickup Magnet | 3 | L1: +70 attraction radius = 162. L2: +140 = 232. L3: +210 = 302. The final collection radius remains 34. |
| `reinforced_hull` | 강화 선체 / Reinforced Hull | 3 | L1: +15 maximum hull = 135. L2: +30 = 150. L3: +45 = 165. Every acquisition also restores 15 hull, capped by the new maximum. |

## Offer and Application Rules

The live pool has 30 non-optional level states. A run can access six additional
states from any two optional secondary weapons, so every build has at least 36
reachable states. The current quota path produces 20 level-up choices and five
boss rewards, for 25 mandatory selections.

For each reward transaction:

1. collect every compatible non-maxed definition;
2. block only the first acquisition of a third optional secondary;
3. deterministically shuffle with run seed, stage, reward source, and serial;
4. take at most one card from each category in the first pass;
5. fill remaining positions from the same shuffled legal pool;
6. require exactly three unique cards before the modal opens;
7. freeze those cards until one exact offered ID is applied and claimed.

There is no forced first category, forced Tuned Thrusters offer, elemental
branch priority, behavior priority, source-specific card pool, duplicate, or
fallback card.

## Retired Cards

The following 22 cards are not part of the live catalog.

| Removed group | IDs | Reason |
| --- | --- | --- |
| Hidden or narrow primary stats | `accelerator_coil`, `mass_driver`, `stabilizer` | Projectile handling and structure-only values were weaker decisions than damage, cadence, and projectile form. |
| Duplicate primary systems | `overclock_cycle`, `ricochet_matrix` | Removed the separate periodic cycle runtime and a third projectile-form branch. |
| Redundant Seeker tuning | `hunter_firmware`, `phase_seeker`, `seeker_cycle`, `seeker_warhead` | Removed target-specific exceptions and pure Seeker stat layers; kept count and manual-mark synergy. |
| Redundant optional weapon | `escort_drone` | Built-in Seeker already owns autonomous ranged fire; three optional choices are enough for the two-slot decision. |
| Incremental element branches | `thermal_compound`, `concentrated_toxin`, `contagion`, `deep_freeze` | Each element is now one complete, independent status package. |
| Redundant Dash layers | `dash_capacitor`, `ion_wake`, `ram_pulse` | Kept two clear Dash results and removed cooldown, trail, and arrival-pulse branches. |
| EMP and defense duplication | `aegis_cycle`, `emp_capacitor`, `emp_focus`, `relay_overload`, `siphon_matrix` | Kept base EMP plus two readable skill results; removed cycles, narrow installation rules, pure EMP stats, and lifesteal. |

## Acceptance Criteria

- Exactly 19 card resources and 39 level states load.
- Category counts are Primary 4, Secondary 5, Element 3, Dash 2, EMP 2, and
  Chassis 3.
- `Pickup Magnet` has three levels and reaches +210 attraction radius.
- Optional IDs are exactly `ion_field`, `orbit_blades`, and `wake_mines`; no
  more than two can be acquired.
- Every shipped 25-choice route fixture returns three unique compatible cards.
- Korean and English category, title, description, stat, unlock, and enhancement
  strings resolve for every level.
- All 39 card states fit the 960×540, 1280×720, and 1920×1080 layout matrices
  without clipped shaped text or overflow.
- Valid, unoffered, double, and stale application cases pass focused runtime
  validation.

## Non-Goals

- New cards, card art, rerolls, skips, shops, reward sources, or permanent
  progression.
- Balance changes to enemies, bosses, stages, base Dash, base EMP, or rewards.
- Deleting existing shared semantic artwork that no live card currently uses.
- Changing performance thresholds or claiming performance qualification.

## Sources

- Card data: `data/cards/vehicle/`
- Optional weapon data: `data/weapons/vehicle/secondary/`
- Catalog and build rules: `scripts/cards/vehicle_upgrade_catalog.gd` and
  `scripts/cards/vehicle_run_build.gd`
- Live behavior: `scripts/vehicle/vehicle_run.gd`,
  `scripts/player/vehicle_secondary_runtime.gd`, and
  `scripts/combat/vehicle_status_profile.gd`
- Card presentation: `scripts/cards/vehicle_upgrade_offer_presenter.gd` and
  `scripts/ui/vehicle_upgrade_choice_card.gd`
- Bilingual copy: `localization/vehicle_stage.csv`
