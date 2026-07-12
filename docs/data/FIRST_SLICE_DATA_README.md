---
type: spec
status: active
owner: BK
last_reviewed: 2026-07-12
canonical_for: Preimplementation first-run JSON catalog role and migration boundary
source: Cardborne active design specifications
related:
  - ../product/2d_platform_action_card_game_prd.md
  - ../architecture/FIRST_SLICE_ARCHITECTURE.md
---

# First-Run Design Data

## Purpose

Index the JSON catalogs that make current design IDs and provisional tuning
machine-checkable before matching typed Godot Resources are implemented.

## Scope

Files under `data/design/first_slice/` are migration input, not a runtime API.
Each implementation milestone should convert the relevant entries to validated
Godot Resources, update cross-reference tests, then retire that JSON ownership.

## Catalogs

| File | Canonical detail source | Migration target |
| --- | --- | --- |
| `player_progression.json` | `PLAYER_CHARACTER_SYSTEMS.md` | CharacterKit, AttackDefinition, SkillDefinition, MasteryDefinition Resources. |
| `card_catalog.json` | `PROGRESSION_EQUIPMENT_ECONOMY.md` | CardDefinition Resources and CardCatalog. |
| `equipment_catalog.json` | `PROGRESSION_EQUIPMENT_ECONOMY.md` | EquipmentDefinition and ForgeAffix Resources. |
| `economy_tables.json` | `PROGRESSION_EQUIPMENT_ECONOMY.md` | RewardTable, ShopOffer, RunLevelCurve Resources. |
| `enemy_trap_gimmick_catalog.json` | `ENEMIES_TRAPS_GIMMICKS.md` | EnemyArchetypeDefinition, EnemyVariantDefinition, EnemyTuningProfile, HazardDefinition, BossPatternDefinition Resources. |
| `procedural_region_rules.json` | `PROCEDURAL_REGION_GENERATION.md` | StageProfile, RoomTemplateData, generation fixtures. |
| `reference_asset_candidates.json` | Research evidence only | No runtime migration without approval/license ledger. |

## Requirements

- JSON syntax is valid and each catalog matches its explicitly accepted schema;
  encounter catalog v2 owns the archetype/variant split while other catalogs remain
  v1 until their own contract changes.
- IDs are lowercase snake_case and match active specs.
- Cross-file references resolve or are explicitly marked as planned runtime owners.
- Runtime does not silently read JSON and typed Resources for the same catalog.
- Design docs own meaning; JSON owns exact migration IDs and provisional values.
- A later balance change updates the typed runtime owner first after migration, not
  this retired input.

## Acceptance Criteria

- Every catalog parses and contains no duplicate ID within its namespace.
- Character kit, critical rule, card, equipment, enemy archetype/variant/tuning,
  drop, stage profile, room, and boss IDs cross-reference successfully.
- The next implementation batch can enumerate exact Resources to create without
  inventing content names or effects.
- Deleted fixed-grid map and wireframe data is not referenced by active docs/tools.

## Non-Goals

- Treating JSON as final save, network, or runtime schema.
- Generating production scenes directly from prose.
- Preserving obsolete testbed markers or preview formats.

## Related

- `docs/product/2d_platform_action_card_game_prd.md`
- `docs/architecture/FIRST_SLICE_ARCHITECTURE.md`
- `data/design/first_slice/`
