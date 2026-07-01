---
type: spec
status: active
canonical_for: first-slice seed design data
source: docs/product/FIRST_SLICE_EXPANSION.md
scope: JSON seed data under data/design/first_slice
---

# First Slice Data README

## Purpose

Explain the seed data files used to design the first playable slice before runtime Godot resources are generated. These files are intentionally plain JSON so they can be inspected, validated, and transformed by small scripts.

## Scope

The seed data lives under `data/design/first_slice/` and covers:

- Economy and drop tables.
- Player controls, stats, skill branches, and level curve.
- Equipment examples.
- Enemy, trap, and gimmick catalog.
- Stage layout and visual preview data.
- UI/UX screen skeletons and generated wireframe targets.
- Reference/source candidates for future code and asset review.
- Procedural region generation rules and generated region graph examples.

## Requirements

- Treat this data as preimplementation design input, not final runtime schema.
- Prefer stable IDs that can later map to Godot `Resource` paths.
- Keep display names separate from IDs.
- Include purpose and implementation notes for entries that affect gameplay feel.
- Avoid hard-coding final balance assumptions in docs when values are clearly placeholders.
- Validate JSON syntax after changes.

## File Index

| File | Role |
|---|---|
| `economy_tables.json` | XP, coin, material, drop, shop, and clear reward seed values |
| `player_progression.json` | controls, base stats, run level curve, skill branches, unlock examples |
| `equipment_catalog.json` | first-slice equipment slots and sample item data |
| `enemy_trap_gimmick_catalog.json` | enemies, boss, traps, gimmicks, and reward hooks |
| `stage_layouts.json` | script-readable authored map layouts and preview metadata |
| `ui_screen_skeletons.json` | screen-level UI/UX composition targets for generated wireframes |
| `reference_asset_candidates.json` | researched source, code, and asset candidates; evidence only |
| `procedural_region_rules.json` | seeded procedural region graph rules, budgets, roles, gates, and validation contracts |
| `generated/*.json` | generated procedural region examples for fixed seeds |

## Acceptance Criteria

- All JSON files parse successfully.
- IDs are lowercase snake_case.
- Cross-file references are readable by humans even before automated validation exists.
- Map data can generate SVG previews using `tools/generate_map_previews.py`.

## Related

- `docs/design/MAP_DATA_AND_VISUALIZATION.md`
- `docs/architecture/FIRST_SLICE_ARCHITECTURE.md`
