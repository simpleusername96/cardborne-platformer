---
type: spec
status: superseded
owner: BK
last_reviewed: 2026-07-14
superseded_by: ./COMBAT_EQUIPMENT_CRAFTING.md
source: Existing character profiles, player controller, player build contracts, and Cardborne Game Blueprint
related:
  - ../product/2d_platform_action_card_game_prd.md
  - ./PROGRESSION_EQUIPMENT_ECONOMY.md
  - ./PROCEDURAL_REGION_GENERATION.md
  - ../architecture/FIRST_SLICE_ARCHITECTURE.md
---

# Player Character Systems

> Superseded on 2026-07-14. This document records the released three-character
> implementation and remains migration evidence. New work follows
> `ARSENAL_EQUIPMENT_PROGRESSION.md`, where these kits become weapon disciplines
> for one hero.

## Purpose

Define the exact first-run player verbs and the three combat kits so implementation
does not invent character identity inside `PlayerController` or during UI work.

## Scope

This specification covers shared traversal, input actions, combat rules, Warrior,
Archer, Assassin, skill cooldowns, mastery nodes, and cross-character acceptance.
Cards and equipment are defined in `PROGRESSION_EQUIPMENT_ECONOMY.md`.

## Shared Traversal Contract

All three characters have these verbs from the first frame of a run:

- accelerated horizontal movement and deceleration;
- variable-height ground jump;
- coyote time and jump buffering;
- one baseline extra jump, producing a double jump;
- at least one ground/air dash charge;
- crouch with a shorter collision body;
- fast fall;
- one-way platform drop;
- rope/ladder entry, climb, and safe dismount;
- damage knockback, invulnerability, death, and checkpoint recovery.

Critical routes may use this shared baseline but never require a combat skill,
mastery, card, equipment item, extra Assassin dash, wall movement, or stat upgrade.

### Baseline movement values

Existing character profiles remain the tuning seed.

| Character | HP | Move | Jump velocity | Extra jumps | Dash charges | Dash cooldown |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Warrior | 6 | 205 | -435 | 1 | 1 | 0.50 s |
| Archer | 5 | 230 | -445 | 1 | 1 | 0.43 s |
| Assassin | 4 | 255 | -455 | 1 | 2 | 0.36 s |

These differences may make optional routes easier for one character, but generation
uses the least-mobile required envelope.

## Controls

Input actions are stable; default keys remain remappable.

| Action | Keyboard default | Gamepad default | Context |
| --- | --- | --- | --- |
| Move | A/D or arrows | Left stick/D-pad | Gameplay and menus where appropriate. |
| Jump | Space | South face button | Also dismounts from a rope. |
| Dash | Shift or K | East face button | Ground or air. |
| Crouch / fast fall | S or Down | D-pad down / stick down | Drop-through uses Down + Jump. |
| Basic attack | F | West face button | Reliable primary attack. |
| Heavy attack | G | North face button | Committed, high-value attack. |
| Skill 1 | Q | Left bumper | Shortest cooldown. |
| Skill 2 | R | Right bumper | Area or positioning skill. |
| Skill 3 | V | Left trigger | Longest cooldown/signature skill. |
| Interact | E or Enter | Right trigger | Chests, gates, exits, rest/forge. |
| Consumable | H | D-pad up | Uses equipped consumable. |
| Pause/settings | Escape | Menu | Pauses safely. |

Gameplay actions do not double as hidden debug commands. Context-sensitive actions
must show the current prompt and cannot trigger a combat action simultaneously.

## Shared Combat Rules

- Basic attacks are available frequently and teach the kit.
- Heavy attacks have at least 0.28 seconds of visible commitment and a larger
  stagger value than basics.
- Skills expose startup, active, recovery, cooldown, hit policy, and interruption
  policy in data.
- A cooldown starts when the skill commits, not when its visual effect ends.
- Damage, knockback, stagger, marks, guard, and invulnerability use shared effect
  contracts rather than direct enemy/player field edits.
- A single attack cannot damage the same target repeatedly unless its data declares
  a tick interval.
- Air use must not silently reset shared jumps or dashes.
- Hit pause and screen shake are feedback, not timing logic.

## Damage And Critical Resolution

Damage is deterministic and integer-valued. The first run does not roll a random
damage range per hit: the same resolved build, target state, and hit context produce
the same result.

```text
base direct damage
 -> additive and multiplicative build effects
 -> one declared critical check
 -> critical multiplier when earned
 -> target mitigation or guard
 -> floor(non-negative value + 0.5), then clamp
```

- A first-run critical hit is earned by a visible positioning, setup, or punish
  condition. Baseline random critical chance is 0%.
- The default critical multiplier is 1.5 and cannot exceed 2.0 from future effects.
- Enemy attacks, hazards, damage-over-time, echoes, aftershocks, and other secondary
  hits cannot critical unless their definition explicitly opts in. None opt in for
  the first run.
- Critical resolution happens once per hit. A critical cannot recursively trigger
  another critical or duplicate on-hit effects.
- Critical feedback uses a distinct hit flash, sound, number treatment, and
  `critical` hit-result tag; color alone is insufficient.
- Enemy and hazard damage is fixed by the threat definition. They have no random
  damage spread and no critical hits in the first run.

First-run earned critical conditions:

| Character | Attack | Condition |
| --- | --- | --- |
| Warrior | `warrior_breaker` | Hit a target during its declared stagger punish state. |
| Archer | `archer_power_shot` | Release at full charge into a target with Hunter's Mark; the mark is consumed. |
| Assassin | `assassin_shadow_lunge` | Hit from the target's authored rear arc. |

## Warrior

### Combat promise

The Warrior controls space and converts enemy recovery into stagger and heavy
damage. He is safest when deliberate, not when trading health indefinitely.

### Base kit

| Verb | ID | Behavior | Startup / active / recovery | Cooldown |
| --- | --- | --- | --- | ---: |
| Passive | `warrior_resolve` | Heavy or skill hits grant `guarded` for 1.5 s. Guarded reduces the next incoming hit by 1, minimum damage 0, then ends. Cannot stack. | Triggered on confirmed hit. | 5 s internal cooldown after guard is consumed. |
| Basic | `warrior_cleave` | Wide forward slash, 2 damage, medium knockback, 20 stagger. Can turn before startup ends. | 0.12 / 0.15 / 0.19 s | 0.46 s total cycle. |
| Heavy | `warrior_breaker` | Overhead strike, 4 damage, 60 stagger, small ground impact radius. Critical against a staggered target. Movement locked after startup midpoint. | 0.42 / 0.16 / 0.48 s | 1.10 s total cycle. |
| Skill 1 | `warrior_shield_rush` | Move 180 px, block frontal projectile/contact damage during travel, deal 2 damage and 35 stagger on first enemy. Stops at solid wall. | 0.16 / 0.32 / 0.26 s | 5 s |
| Skill 2 | `warrior_ground_splitter` | Short ground shockwave, 3 damage, launches light enemies, cannot travel through walls or gaps. | 0.34 / 0.35 / 0.42 s | 8 s |
| Skill 3 | `warrior_rally` | Gain guarded immediately; next Heavy within 5 s starts 30% faster and creates a second shockwave at 50% damage. | 0.25 / instant / 0.25 s | 14 s |

### Intended decisions

- Use Shield Rush to take space, not as unrestricted invulnerability.
- Save Breaker for a tell or recovery window.
- Rally can stabilize a mistake or prepare a burst, but its long cooldown prevents
  permanent defense.

### Mastery nodes

| ID | Prerequisite | Effect |
| --- | --- | --- |
| `warrior_broad_guard` | none | Guard also blocks one projectile without being consumed by 0-damage contact. |
| `warrior_driving_rush` | none | Shield Rush carries light enemies to its endpoint; wall impact adds 20 stagger. |
| `warrior_fracture` | Broad Guard or Driving Rush | Breaker applies `fractured` for 4 s; next skill hit deals +1 damage. |
| `warrior_aftershock` | Driving Rush | Ground Splitter leaves one delayed 1-damage aftershock. |
| `warrior_steady_feet` | Broad Guard | Taking a hit while guarded halves knockback. |
| `warrior_last_bastion` | Fracture + Steady Feet | Once per stage at 1 HP, gain guard and reset Shield Rush; no heal. |

## Archer

### Combat promise

The Archer controls range with marks and repositions without abandoning pressure.
The fun is deciding when to consume a mark for burst and when to preserve it for
area control.

### Base kit

| Verb | ID | Behavior | Startup / active / recovery | Cooldown |
| --- | --- | --- | --- | ---: |
| Passive | `archer_hunters_mark` | Skill hits mark a target for 6 s. A full-charge Heavy consumes the mark, becomes critical, and creates a 90 px, 1-damage radial burst. One mark per target. | Triggered on hit. | None. |
| Basic | `archer_quick_shot` | Fast arrow, 1 damage, 640 px/s, 800 px range. Air use preserves horizontal control. | 0.09 / projectile / 0.21 s | 0.30 s total cycle. |
| Heavy | `archer_power_shot` | Charge up to 0.8 s; piercing arrow deals 2-4 damage and stronger knockback. Minimum charge still fires. | 0.28-0.80 / projectile / 0.32 s | 1.10 s from release. |
| Skill 1 | `archer_vault_shot` | Hop 120 px away from aim direction and fire three low-damage arrows in a narrow fan. Marks first target hit. | 0.12 / 0.30 / 0.20 s | 5 s |
| Skill 2 | `archer_rain_field` | Warn a 220 px-diameter area for 0.45 s, then six arrows strike over 1.2 s. Each target can be hit three times. | 0.30 / 1.20 / 0.30 s | 9 s |
| Skill 3 | `archer_threadline` | Fire a tether arrow. On terrain, pull 160 px toward it without granting route access beyond shared movement; on enemy, pull light target and mark it. | 0.22 / 0.35 / 0.34 s | 12 s |

### Intended decisions

- Quick Shot sustains pressure but should not erase enemy tells from off-screen.
- Power Shot rewards a safe lane and a marked target.
- Threadline is combat repositioning; generated routes cannot require it.

### Mastery nodes

| ID | Prerequisite | Effect |
| --- | --- | --- |
| `archer_quick_nock` | none | Quick Shot after a dash starts 25% faster. |
| `archer_piercing_draw` | none | Full-charge Power Shot pierces one additional target. |
| `archer_shared_mark` | Quick Nock or Piercing Draw | Consuming a mark transfers a 3 s mark to the nearest unmarked enemy within 180 px. |
| `archer_airborne_hunter` | Quick Nock | Vault Shot restores 25% air control immediately after firing. |
| `archer_storm_pattern` | Piercing Draw | Rain Field's final arrow has +1 damage and 30 stagger. |
| `archer_clean_release` | Shared Mark + Storm Pattern | Consuming a mark reduces the longest active skill cooldown by 1 s, once every 4 s. |

## Assassin

### Combat promise

The Assassin crosses through danger, chains distinct verbs, and exits before the
counterattack. Repeating one safe attack should be weaker than alternating tools.

### Base kit

| Verb | ID | Behavior | Startup / active / recovery | Cooldown |
| --- | --- | --- | --- | ---: |
| Passive | `assassin_flow` | Hitting with a different verb category than the previous hit grants one Flow stack for 3 s, max 3. At 3 stacks the next Heavy or skill deals +2 damage and consumes Flow. | Triggered on hit. | None. |
| Basic | `assassin_twin_cut` | Two short slashes; each deals 1 damage. Second hit requires the button to remain held through the first recovery. | 0.07 / 0.07 / 0.08, then 0.08 / 0.07 / 0.12 s | 0.49 s full chain. |
| Heavy | `assassin_shadow_lunge` | Travel 150 px through light enemies, 3 damage; critical from behind. Stops before solid wall and cannot cross closed gates. | 0.24 / 0.20 / 0.34 s | 0.90 s total cycle. |
| Skill 1 | `assassin_smoke_step` | 120 px invulnerable step through an enemy; leaves a decoy that draws aim for 0.8 s. No damage. | 0.08 / 0.18 / 0.18 s | 5 s |
| Skill 2 | `assassin_kunai_fan` | Five short-range projectiles, 1 damage each; one target can take at most three hits. | 0.18 / projectile / 0.25 s | 7 s |
| Skill 3 | `assassin_death_mark` | Mark one enemy for 5 s. The third distinct verb that hits detonates for 4 damage and 40 stagger. | 0.24 / instant / 0.28 s | 13 s |

### Locked execution details

- Flow uses one shared 3 s window. A qualifying hit refreshes it; expiry removes
  all stacks. A verb is the attack or skill definition ID, so one multi-hit action
  remains one verb.
- Rear hits are evaluated at contact from target facing and source position.
- Smoke Step's Lingering Smoke slow is x0.65 for 0.6 s. The decoy attracts aimed
  attacks but does not alter encounter activation.
- Kunai Fan uses five arrows at -24, -12, 0, 12, and 24 degrees, 560 px/s, and
  360 px range. The three-hit cap is shared by the full activation.
- Death Mark targets the nearest valid forward enemy within 320 px.

### Intended decisions

- Flow rewards alternation rather than button repetition.
- Smoke Step is an exit/reposition tool, not a mandatory route ability.
- Death Mark asks the player to plan a three-verb sequence under pressure.

### Mastery nodes

| ID | Prerequisite | Effect |
| --- | --- | --- |
| `assassin_serrated_second` | none | Twin Cut's second hit applies a 2 s, 1-damage bleed; same source does not stack. |
| `assassin_slipstream` | none | Shadow Lunge refunds one dash charge on kill, once every 5 s. |
| `assassin_lingering_smoke` | Serrated Second or Slipstream | Smoke decoy lasts 1.3 s and briefly slows enemies entering it. |
| `assassin_fan_return` | Serrated Second | Two Kunai Fan projectiles return; returning hits cannot hit the same target twice. |
| `assassin_opportunist` | Slipstream | Attacks from behind add one Flow stack, still capped at three. |
| `assassin_perfect_exit` | Lingering Smoke + Opportunist | Death Mark detonation resets Smoke Step if the Assassin took no damage since marking. |

## Requirements

- Character definitions own kit references and tuning data; shared movement does
  not branch on character ID.
- Attack execution owns state, timing, cancellation, cooldown, and hit policy.
- Skills cannot bypass closed gates, camera bounds, or required-route validation.
- Every mastery effect maps to one shared effect or explicit kit extension; no
  mastery writes arbitrary controller fields.
- Base characters remain boss-capable without mastery or equipment unlocks.
- Character selection changes combat decisions, not access to critical routes.

## Acceptance Criteria

- Each character demonstrates basic, heavy, three skills, and passive in a
  production encounter with no debug controls.
- Every attack has visible startup/active/recovery and focused timing tests.
- The same critical seed set is clearable by all three base profiles.
- A 10-minute combat playtest produces distinct dominant decisions for each kit.
- No skill or mastery is required to recover from a generated critical-path fall.
- Cooldown, mark, guard, Flow, damage, and stagger UI agree with runtime state.
- Earned critical conditions produce the same result for the same build and hit
  context; no test depends on lucky rolls.

## Non-Goals

- Character-exclusive map gates in the first run.
- More than three active skills or a separate per-character mana bar.
- Large combo movelists, weapon swapping during combat, or PvP balance.
- Permanent raw-stat growth that makes the base game uncleareable without grind.

## Related

- `docs/product/2d_platform_action_card_game_prd.md`
- `docs/design/PROGRESSION_EQUIPMENT_ECONOMY.md`
- `docs/design/PROCEDURAL_REGION_GENERATION.md`
- `data/characters/*.tres`
