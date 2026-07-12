---
type: spec
status: draft
source: docs/product/FIRST_SLICE_EXPANSION.md
scope: First playable character and progression model
---

# Player Character Systems

## Purpose

Define what is available to the user character in the first slice: controls, movement verbs, combat verbs, skill branches, equipment slots, and growth sources.

## Scope

The first implementation should ship one playable base character. Additional characters can be designed later, but the first slice should already have data shapes that make future character variants possible.

## Requirements

### Base Character

Working label: **Base Adventurer**.

The first playable character should support:

- Left/right movement.
- Acceleration and deceleration.
- Ground jump.
- Variable jump height.
- Coyote time.
- Jump buffer.
- Dash.
- Crouch.
- Fast fall.
- Drop-through one-way platform.
- Basic melee attack.
- Damage knockback.
- Temporary post-hit invulnerability.
- Health and death flow.
- XP collection.
- Coin collection.
- Material collection.
- Card effect application.
- Equipment stat modifiers.

### Controls

| Action | Keyboard Input |
|---|---|
| Move left | A / Left Arrow |
| Move right | D / Right Arrow |
| Jump | Space |
| Attack | F |
| Dash | K / Shift |
| Crouch | S / Down Arrow |
| Fast fall | Hold Down in air |
| Drop through one-way platform | Down + Jump |
| Interact / confirm | E / Enter |
| Open skill/equipment debug panel | Tab |
| Pause | Esc |

Gamepad is optional for the first slice, but actions should be named so bindings can be added later.

Current motion-testbed profiles may tune basic attack damage, cooldown, active time, range, hitbox height, offset, knockback, motion style, and projectile values before separate character controllers exist.

### Growth Sources

| Source | Timing | Reset Behavior | Purpose |
|---|---|---|---|
| XP level | During run | Resets each run | Frequent progress feedback and micro-upgrades |
| Card | Stage clear or special reward | Resets each run | Build-defining upgrade choice |
| Coin purchase | In-run shop/rest point | Resets each run | Tactical spending and recovery choices |
| Material upgrade | Between runs or debug profile | May persist once local profile exists | Longer-term upgrade or crafting hook |
| Equipment | Found, bought, or crafted | Depends on implementation | Build identity and stat shaping |

### Skill Branches

First-slice data should define these branches even if the first implementation only activates a small subset:

**Combat**

- Basic attack damage.
- Attack cooldown.
- Boss damage.
- Critical chance as a future hook.
- Heavy attack unlock as a future hook.

**Mobility**

- Dash cooldown.
- Extra dash charge.
- Air control.
- Fast-fall control.
- Wall jump as a future hook.

**Survival**

- Max health.
- Damage reduction as a future hook.
- Healing bonus.
- Invulnerability duration.

**Card**

- Extra card choice as a future hook.
- One reroll per reward as a future hook.
- Rare-card weight bonus as a future hook.

**Economy**

- Coin gain.
- Material gain.
- Shop discount.
- Chest bonus chance as a future hook.

### Equipment Slots

First-slice equipment should use a small slot model:

- **Weapon**: changes attack damage, attack timing, or range.
- **Armor**: changes health, defense hooks, or knockback resistance.
- **Charm 1**: small special modifier.
- **Charm 2**: small special modifier, unlocked later.
- **Relic**: run-defining or rare modifier.
- **Consumable**: limited-use healing or utility item.

Do not build a complex grid inventory for the first slice. Equipment can be represented as a list of owned item IDs plus equipped slot IDs.

## Acceptance Criteria

- Player movement and combat code can read effective stats without knowing whether the stat came from skill, card, equipment, or level.
- The first UI can show health, XP, level, coins, materials, and equipped weapon without requiring full inventory management.
- Skill and equipment data can be expanded without rewriting player movement.
- The first playable character is feature-complete enough to clear the planned stages and boss.

## Related

- `data/design/first_slice/player_progression.json`
- `data/design/first_slice/equipment_catalog.json`
- `docs/architecture/FIRST_SLICE_ARCHITECTURE.md`
