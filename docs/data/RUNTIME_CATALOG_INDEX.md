---
type: spec
status: active
owner: BK
last_reviewed: 2026-07-14
canonical_for: Cardborne typed runtime catalog ownership and validation entry points
source: Implemented Godot Resources and active design specifications
related:
  - ../product/2d_platform_action_card_game_prd.md
  - ../design/COMBAT_EQUIPMENT_CRAFTING.md
  - ../architecture/FIRST_SLICE_ARCHITECTURE.md
  - ../../.agent/execplans/2026-07-12-actual-game-production-roadmap.md
---

# Runtime Catalog Index

## Purpose

Map each gameplay domain to its typed Godot Resource owner. Runtime code, tests,
and future content changes must use these resources rather than parallel JSON.

## Catalog Owners

This table describes the released v1 runtime and remains implementation evidence,
not the unimplemented single-hero target.

| Domain | Runtime owner | Focused validation |
| --- | --- | --- |
| Characters and kits | `data/characters/character_catalog.tres`, `data/combat/kits/` | `validate_character_catalog.gd`, character combat validators |
| Cards | `data/cards/card_catalog.tres` | `validate_remaining_cards_catalog.gd`, card runtime validators |
| Equipment and forge | `data/equipment/equipment_catalog.tres`, `data/forge/forge_catalog.tres` | `validate_equipment_mastery_catalogs.gd`, `validate_rest_forge.gd` |
| Mastery and run levels | `data/mastery/mastery_catalog.tres`, `data/progression/run_progression_catalog.tres` | `validate_equipment_mastery_catalogs.gd`, `validate_complete_run_balance.gd` |
| Rewards and economy | `data/rewards/reward_catalog.tres` | `validate_reward_progression.gd`, `validate_reward_source_runtime.gd` |
| Enemies | `data/enemies/enemy_catalog.tres`, `data/enemies/enemy_scene_catalog.tres` | enemy catalog and runtime validators |
| Hazards | `data/hazards/hazard_catalog.tres` | `validate_hazard_catalog.gd`, stage hazard validators |
| Regions and rooms | `data/generation/*.tres`, `data/rooms/` | region generation, room, and geometry validators |
| Boss | `scenes/stages/boss/SlimeCourt.tscn`, `scripts/bosses/` | boss pattern, arena, roster, and settlement validators |

## Target Combat Catalog Migration

The next migration replaces character-owned combat content through these
non-overlapping owners. Paths are target locations until the replacement
ExecPlan implements and validates them.

| Domain | Target typed owner | Owns | Must not own |
| --- | --- | --- | --- |
| Combat tools | `data/equipment/combat/`, `EquipmentCatalog` | 12 model definitions, action/trait references, recipes | Active skill effects, passive trigger dispatch |
| Ranged policies | `data/equipment/combat/`, `RangedTargetingPolicy` implementations | Bow line, matchlock reload, blade recall, Root Sigil ground legality | Damage resolution, HUD drawing |
| Active skills | `data/skills/control/`, `data/skills/tactical/`, `ActiveSkillCatalog` | Control/tactical role definitions and validation | Tool basic attacks, passive effects |
| Passive traits | `data/passives/`, `PassiveTriggerResolver` | Intrinsic, accessory, Attunement, and run-card trigger dispatch | Input bindings, material-grade values |
| Spirit bindings | `data/spirit_stones/`, `SpiritStoneCatalog` | One Attunement, one Spirit Art, resonance policy per Stone | Per-weapon enchantment copies |
| Crafting and supply | `data/crafting/`, `CraftingService`, ranged-resource owners | Recipes, grades, condition, tool-specific resource floors | Combat target selection |

The v1 character, skill, mastery, equipment, and forge catalogs remain migration
fixtures until parity is accepted. They do not become a second target authority.

## Ownership Rules

- Stable content IDs and accepted values live in typed Resources and active specs.
- Runtime systems resolve IDs through catalogs; they do not parse design JSON.
- Catalog validators check local definitions and cross-catalog references.
- Balance changes update the typed resource, focused validator, and active spec in
  the same batch.
- External assets and references remain governed by
  `docs/research/third_party_adoption_ledger.md`.

## Migration Record

The provisional files formerly under `data/design/first_slice/` were retired after
all six gameplay catalogs moved to typed Resources. The JSON had already diverged
from runtime room counts, reward values, and the accepted run-level curve, so it is
available only through Git history. `validate_design_catalogs.gd` now validates the
typed catalogs directly and rejects restoration of the retired directory.

## Validation

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validate_design_catalogs.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_complete_run_balance.gd
```
