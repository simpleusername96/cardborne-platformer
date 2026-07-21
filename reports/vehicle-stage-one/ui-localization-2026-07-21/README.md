---
type: evidence
status: active
owner: BK
created: 2026-07-21
scope: Rendered verification for the Korean-first bilingual Vehicle Stage 1 UI layout
related:
  - ../../../.agent/execplans/2026-07-21-localized-ui-layout-refinement.md
  - ../../../docs/product/vehicle_stage_one_experimental_spec.md
---

# Vehicle Stage 1 bilingual UI evidence

This folder contains deterministic native Godot captures of every reachable
Vehicle Stage 1 surface after the 2026-07-21 localization and layout pass.
`.gdignore` keeps review evidence out of the Godot resource import and export
pipeline.

## Capture sets

| Folder | Locale | Viewport | Screens |
| --- | --- | --- | --- |
| `ko-1280/` | Korean | 1280x720 | 9 |
| `en-1280/` | English | 1280x720 | 9 |
| `ko-960/` | Korean | 960x540 | 9 |

Each set contains deployment, open combat, installation route, upgrade choice,
optional field boss, stage boss, pause/settings, result, and garage.

## Review result

- Required Korean and English text remains inside its surface at both tested widths.
- Deployment separates selection from commitment and marks selection with a side bar plus check.
- Upgrade and pause hide the gameplay HUD under the modal layer.
- The boss strip replaces the objective and minimap instead of stacking with them.
- The bottom action rail and lower-right target panel do not overlap at 960x540.
- Result promotes the permanent reward; garage separates loadout and settings.

The translation catalog contained 163 unique complete rows at capture time, with
no blank cells, duplicate keys, or missing referenced UI keys.
