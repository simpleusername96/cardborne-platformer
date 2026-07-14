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
  - ../../.agent/execplans/2026-07-14-minimum-equipment-progression-vertical-slice.md
  - ../../.agent/execplans/2026-07-12-actual-game-production-roadmap.md
---

# Runtime Catalog Index

## Purpose

Map each gameplay domain to its typed Godot Resource owner. Runtime code, tests,
and future content changes must use these resources rather than parallel JSON.

## Scope

This index covers production content roots, their runtime resolvers, focused
validation entry points, and the retained v1 compatibility boundary. It does not
define balance values or player-facing behavior.

## Catalog Owners

These are the typed owners used by the active Traveler production flow.

| Domain | Runtime owner | Focused validation |
| --- | --- | --- |
| Hero and movement | `data/hero/traveler.tres` | `validate_hero_definition.gd`, `validate_player_movement_runtime.gd` |
| Combat actions | `data/attacks/traveler_sword.tres`, `hunting_spear.tres`, `hunting_bow.tres`, `matchlock.tres`; model policy in `data/equipment/models/` | `validate_hero_attack_definitions.gd`, `validate_context_combat_contract.gd`, shared combat validators |
| Equipment progression | `data/equipment/equipment_progression_catalog.tres`, `data/equipment/models/`, `data/equipment/blueprints/`, `data/materials/`, `data/spirit_stones/` | equipment catalog, resolver, command, profile v2, and Forge validators |
| Cards and run levels | `data/cards/card_catalog.tres`, `data/progression/run_progression_catalog.tres` | `validate_remaining_cards_catalog.gd`, card runtime, and reward progression validators |
| Rewards and economy | `data/rewards/reward_catalog.tres` | `validate_stage1_progression_rewards.gd`, `validate_reward_progression.gd`, `validate_reward_source_runtime.gd` |
| Field supplies | `data/items/field_pickup_catalog.tres` | `validate_field_pickups.gd`, fixed manifest/drop validators |
| Enemies | `data/enemies/enemy_catalog.tres`, `data/enemies/enemy_scene_catalog.tres` | enemy catalog and runtime validators |
| Hazards | `data/hazards/hazard_catalog.tres` | `validate_hazard_catalog.gd`, stage hazard validators |
| Fixed stages and rooms | `data/generation/*.tres`, `data/rooms/`, native room scenes | curated plan, room, geometry, recovery, and production-stage validators |
| Boss | `scenes/stages/boss/SlimeCourt.tscn`, `scripts/bosses/` | boss pattern, arena, scheduler, flow, and settlement validators |

## Active Equipment Ownership

| Domain | Typed owner | Owns | Must not own |
| --- | --- | --- | --- |
| Tool models | `EquipmentProgressionCatalog`, `EquipmentModelDefinition` | Six combat-tool and two armor definitions, action/guard references, weaknesses, grade values | Profile mutation, UI state |
| Blueprints and materials | `EquipmentBlueprintDefinition`, `MaterialDefinition` | Model recipes, material family and grade | Combat targeting, random affixes |
| Runtime values | `EquipmentRuntimeResolver`, `HeroCombatLoadoutResolver` | Exact effective stats for the equipped crafted state | Crafting costs, persistence |
| Craft/recraft/repair | `EquipmentProgressionService`, `ProfileCommandService`, `ProfileState` | Deterministic previews, atomic commands, persistence | Combat target selection |
| Context attack and guard | `AttackIntentResolver`, `PlayerCombatController`, `ShieldCombatRuntime` | Melee/ranged legality, committed intent, shield state | Blueprint ownership, UI formatting |
| Passive Spirit | `SpiritStoneCombatRuntime`, `SpiritStoneDefinition` | One declared passive trigger per equipped Stone | Inputs, cooldowns, resonance, active Arts |

## Compatibility Catalogs

`data/characters/`, `data/skills/`, `data/mastery/`, and the old
`data/equipment/items/` catalog remain only for v1 save migration and focused
historical fixtures. `ProfileData` keeps compatibility fields for those fixtures,
but the production Traveler flow does not read them. Legacy equipment-discovery
fields in reward Resources must remain empty in every active reward table.

## Requirements

- Stable content IDs and accepted values live in typed Resources and active specs.
- Runtime systems resolve IDs through catalogs; they do not parse design JSON.
- Catalog validators check local definitions and cross-catalog references.
- Balance changes update the typed resource, focused validator, and active spec in
  the same batch.
- Production must not resolve a class kit, mastery node, active skill, temporary
  affix, or random equipment discovery from compatibility catalogs.
- External assets and references remain governed by
  `docs/research/third_party_adoption_ledger.md`.

## Acceptance Criteria

- Every active hero, equipment, card, reward, enemy, hazard, room, and boss ID
  resolves through exactly one typed catalog owner.
- Active catalogs contain no class skill, temporary affix, or random equipment
  discovery reference.
- Local and cross-catalog validators report exact invalid IDs before gameplay.
- `validate_design_catalogs.gd`, equipment/profile validators, and the active Full
  release matrix pass.

## Migration Record

The provisional files formerly under `data/design/first_slice/` were retired after
all gameplay catalogs moved to typed Resources. The class-select, RestForge,
temporary-affix, and generated equipment-discovery production owners were retired
after the Traveler path passed migration and release gates. Git history preserves
them; active runtime catalogs do not reference them.

## Validation

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validate_design_catalogs.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_equipment_progression_catalog.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validate_profile_v2.gd
.\tools\validate_release_candidate.ps1 -Full
```
