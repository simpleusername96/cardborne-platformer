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
- Card reward examples.
- Player controls, stats, skill branches, and level-up choices.
- Equipment examples.
- Enemy, trap, and gimmick catalog.
- Stage layout and visual preview data.

## Requirements

- Treat this data as preimplementation design input, not final runtime schema.
- Prefer stable IDs that can later map to Godot `Resource` paths.
- Keep display names separate from IDs.
- Include purpose and implementation notes for entries that affect gameplay feel.
- Avoid hard-coding final balance assumptions in docs when values are clearly placeholders.
- Validate JSON syntax after changes.
- Regenerate map previews after changing `stage_layouts.json` or the preview generator.

## File Index

| File | Role |
|---|---|
| `economy_tables.json` | XP, coin, material, drop, shop, and clear reward seed values |
| `card_catalog.json` | First-slice card reward pool based on the PRD MVP card list |
| `player_progression.json` | controls, base stats, growth source contract, micro-upgrades, and skill branch examples |
| `equipment_catalog.json` | first-slice equipment slots and sample item data |
| `enemy_trap_gimmick_catalog.json` | enemies, boss, traps, gimmicks, and reward hooks |
| `stage_layouts.json` | script-readable authored map layouts and preview metadata |

## Cross-File Contracts

- Currency IDs used in costs, drops, and rewards must exist in `economy_tables.json`.
- Drop table IDs referenced by enemies, bosses, and reward-bearing gimmicks must exist in `economy_tables.json`.
- Card effects in `card_catalog.json` should use the PRD effect names unless a future implementation intentionally migrates them.
- Starting equipment IDs in `player_progression.json` must exist in `equipment_catalog.json`.
- Stage layout legend values should match documented enemy, trap, or gimmick IDs where applicable.
- Boss stages should use `clear_condition: "defeat_boss"` and should not place an active `E` exit symbol in the authored layout.

## Validation

Run these from the repository root after seed data changes:

```powershell
python -m json.tool data\design\first_slice\economy_tables.json > $null
python -m json.tool data\design\first_slice\card_catalog.json > $null
python -m json.tool data\design\first_slice\player_progression.json > $null
python -m json.tool data\design\first_slice\equipment_catalog.json > $null
python -m json.tool data\design\first_slice\enemy_trap_gimmick_catalog.json > $null
python -m json.tool data\design\first_slice\stage_layouts.json > $null
python -m py_compile tools\generate_map_previews.py
python tools\generate_map_previews.py
git diff --check
```

`tools/generate_map_previews.py` also validates fixed row widths, known symbols, and normal-versus-boss required markers before writing SVGs.

## Acceptance Criteria

- All JSON files parse successfully.
- IDs are lowercase snake_case.
- Cross-file references are readable by humans even before automated validation exists.
- Map data can generate SVG previews using `tools/generate_map_previews.py`.
- The seed data separates XP levels, card choices, coin purchases, material sinks, skill nodes, and equipment modifiers by role.

## Related

- `docs/design/MAP_DATA_AND_VISUALIZATION.md`
- `docs/architecture/FIRST_SLICE_ARCHITECTURE.md`
