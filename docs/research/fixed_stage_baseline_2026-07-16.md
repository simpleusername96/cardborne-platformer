---
type: evidence
status: active
owner: BK
created: 2026-07-16
source: master commit fbaecc0 and Godot 4.7 headless validators
topic: Fixed-stage map, traversal, combat, retry, and HUD baseline before ExecPlan implementation
related:
  - ../../.agent/execplans/2026-07-15-fixed-stage-map-enhancement.md
  - ../design/STAGE_MAP_BLUEPRINTS.md
---

# Fixed Stage Baseline — 2026-07-16

## Purpose

Preserve the exact pre-implementation baseline for the active fixed-stage map
ExecPlan so later metric, behavior, and rendered comparisons do not rely on
memory or a moving branch.

## Sources

- Git baseline: `fbaecc0 docs: add stage progression and minimap plan`
- Runtime: Godot `4.7.stable.official.5b4e0cb0f`
- Commands:
  - `.\tools\godot.ps1 --path . --headless --import`
  - `validate_stage_composition.gd`
  - `validate_production_stage.gd`
  - `validate_player_movement_runtime.gd`
  - `validate_shooter_runtime.gd`
  - `validate_flooded_enemy_runtime.gd`
  - `validate_gameplay_hud.gd`
  - `validate_stage_attempt_retry.gd`
  - `validate_curated_stage_plans.gd`

## Findings

### Composition baseline

| Stage | Required rooms | Enemies | Vertical range | Ascent | Descent | Elevation changes | Multi-elevation combat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Ruin Approach | 8 | 8 | 720 px | 720 px | 0 px | 9 | 2 |
| Flooded Works | 7 | 10 | 760 px | 800 px | 40 px | 9 | 3 |
| Broken Sanctum | 9 | 12 | 740 px | 980 px | 240 px | 11 | 4 |

The numbers reproduce the active ExecPlan. They do not prove traversal comfort,
forward rejoin, camera timing, projectile cover, or terrain-aware enemy behavior.

### Passing baseline commands

- stage composition
- player movement runtime
- shooter runtime
- Flooded enemy runtime
- gameplay HUD in two locales and three viewports
- stage-attempt retry
- curated stage plans for two run seeds

### Known pre-existing failure

`validate_production_stage.gd` exits non-zero at the HUD assertion requiring the
localized melee/ranged names to contain literal English `Sword` and `Bow`.
`validate_gameplay_hud.gd` passes its localized semantic contract, so the
production-stage assertion is a stale English-copy assumption rather than a
runtime load or map failure. The Milestone A HUD update must replace it with a
locale-safe role/asset assertion before the final gate.

## Limitations

- This is automated baseline evidence, not a manual fun verdict.
- Current fixed screenshots are isolated teleports and do not prove continuous
  start-to-exit traversal.
- No minimap exists at this baseline.
- Existing user-owned `.import` changes were present and are not part of this
  evidence or any task-owned commit.
