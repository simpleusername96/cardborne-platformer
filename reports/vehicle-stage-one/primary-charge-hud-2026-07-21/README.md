---
type: evidence
status: active
owner: BK
created: 2026-07-21
scope: Rendered verification for the primary charge cycle, bottom action rail, and stronger bilingual typography
related:
  - ../../../.agent/execplans/2026-07-21-primary-charge-hud-content-expansion.md
  - ../../../docs/product/vehicle_stage_one_experimental_spec.md
---

# Primary charge HUD evidence

This folder contains deterministic native Godot captures after the primary-charge and bottom-rail pass. `.gdignore` keeps the evidence images out of the Godot resource import and export pipeline.

## Capture sets

| Folder | Locale | Viewport | Screens |
| --- | --- | --- | --- |
| `ko-1280x720/` | Korean | 1280x720 | 9 |
| `en-1280x720/` | English | 1280x720 | 9 |
| `ko-960x540/` | Korean | 960x540 | 9 |

Each set contains deployment, open combat with a partially charged primary, installation route, upgrade choice, optional field boss, stage boss, pause/settings, result, and garage.

## Review result

- The former four-medallion dock is replaced by one low, flat action rail.
- The primary cell is wider than the passive, dash, and EMP cells and exposes both discrete rounds and recharge progress.
- Korean and English text use the scoped medium/bold font variations and no new translation key is rendered raw.
- `2 / 6발 · 충전 1.7초` and `2 / 6 rounds · Charge 1.6s` fit without clipping in the rendered gameplay surface.
- The rail remains separate from the lower-right target panel and does not cover threats at either captured width.
- All modal surfaces inherit the stronger type while preserving their prior focus and visibility rules.

## Validation result

- Vehicle Stage 1 validator: 113 checks, 0 failures.
- Settings/localization validator: pass.
- Web release export: pass.
- Built Web files were served on the registered Codex port and returned HTTP 200 for HTML, JavaScript, PCK, and WASM artifacts. The in-app browser runtime could not initialize because its local kernel-asset path was unavailable, so interactive browser boot was not claimed; native runtime captures provide the rendered visual evidence.
