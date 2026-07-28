---
type: evidence
status: active
created: 2026-07-29
topic: space-hangar-v2 runtime acceptance
scope: Gate D world slice and Gate E UI rollout
related:
  - ../../../runtime/atlases/space-hangar-v2/world-recipe.json
  - ../../../runtime/ui/space-hangar-v2/chrome-recipe.json
  - ../../../../docs/design/UI_VISUAL_SYSTEM.md
---

# Space Hangar v2 Runtime Evidence

## Purpose

Preserve the rendered evidence used to accept the image-backed world and UI
runtime rollout. These images support the active visual specification; they do
not define gameplay or UI behavior.

## Sources

- Korean and English native Godot captures at 960x540, 1280x720, and
  1920x1080.
- Safe-arrival and maximum-pressure captures at 1280x720.
- Published world and UI recipes linked in the frontmatter.

## Findings

- Gate D passed: the three registered fields retain their authored geometry
  while repeat masters and 42 atlas stamps render as presentation-only detail.
- Gate E passed: panel, button, card, tab, and HUD-frame states are
  image-backed while Korean/English text, focus, selection, values, and
  accessibility state remain live controls.
- Layout, localization, field, terrain, pause, guidebook, report, reward,
  runtime, and Web-export validation passed on 2026-07-29.
- The exported Web build loaded at 960x540 with all seven initial network
  requests returning 200 and no browser console warnings or errors.
- The VSync-independent 60-second `current_pressure` sample kept 131/200 draw
  calls, 50/50 combat batches, 17.37/18 ms frame p95, 25/25 ms frame p99,
  1.28 ms CPU render, and 1.16 ms GPU render.

## Limitations

- Contact sheets are review summaries. Native captures under `build/captures/`
  remain the detailed transient evidence.
- The release performance result remains false only for the 1% low gate:
  35.90 FPS against 55 FPS. Stored pre-rollout 96-enemy/212-projectile
  baselines also failed that gate at about 39 FPS, so this is not accepted as a
  new image-chrome regression and remains performance-work scope.
