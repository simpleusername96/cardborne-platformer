---
type: spec
status: active
canonical_for: first-slice map data and visual preview guidance
source: docs/product/FIRST_SLICE_EXPANSION.md
scope: Authored stage planning before Godot scene implementation
---

# Map Data And Visualization

## Purpose

Provide a lightweight, script-readable way to describe map intent before building full Godot scenes. The map data is design seed material, not yet a runtime scene format.

## Scope

This guide applies to first-slice authored stage planning:

- Stage 01.
- Stage 02.
- Stage 03.
- Boss Stage 01.

Each stage should have a readable grid layout, legend, objective, teaching goals, encounter placements, reward placements, and navigation notes.

## Requirements

- Store first-slice stage layout data in `data/design/first_slice/stage_layouts.json`.
- Keep the layout as rows of fixed-width text so it can be reviewed in git and converted to simple previews.
- Prefer `.` as visible empty-space filler inside large maps so horizontal and vertical structure remains readable in source control.
- Use a shared legend for common stage symbols.
- Include per-stage notes for:
  - purpose,
  - teaching goals,
  - expected critical path,
  - optional rewards,
  - enemy pressure,
  - trap pressure,
  - soft-lock risks.
- Generate SVG previews into `docs/maps/generated/` using `tools/generate_map_previews.py`.
- Treat generated SVGs as visual aids only; Godot scenes remain the implementation source once built.

## Map Legend

| Symbol | Meaning |
|---|---|
| `S` | Player spawn |
| `E` | Exit portal |
| `B` | Boss spawn |
| `#` | Solid ground or wall |
| `=` | One-way platform |
| `P` | Moving platform route or platform anchor |
| `^` | Spike or immediate-contact trap |
| `~` | Poison or damage floor |
| `!` | Telegraph/warning zone |
| `W` | Walker enemy |
| `C` | Charger enemy |
| `R` | Shooter enemy |
| `m` | Small summoned enemy |
| `$` | Coin cluster |
| `M` | Material node |
| `T` | Chest or reward container |
| `K` | Key or unlock pickup |
| `G` | Gate or locked blocker |
| `.` | Empty layout filler rendered as open space |
| space | Empty space |

## Visual Preview Contract

The preview generator should:

- Read `stage_layouts.json`.
- Validate that each row in a stage has the same width.
- Render each symbol as a tile-colored SVG rectangle.
- Add labels for major objects.
- Write one SVG per stage plus an index file.
- Fail clearly when JSON is malformed or row widths are inconsistent.

## Acceptance Criteria

- `python tools/generate_map_previews.py` produces SVG files for all stages in the seed data.
- A future agent can compare stage intent and generated SVG before creating or changing `.tscn` files.
- Map data includes reward and encounter intent, not just collision tiles.
- Layouts include meaningful horizontal and vertical volume, not only a single flat route.
- Layouts avoid unreachable exits, hidden required collectibles, and route blockers that can soft-lock the first slice.

## Related

- `data/design/first_slice/stage_layouts.json`
- `docs/maps/README.md`
- `tools/generate_map_previews.py`
