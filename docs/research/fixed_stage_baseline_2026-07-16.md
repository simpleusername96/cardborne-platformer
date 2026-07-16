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

### Structural red evidence

The new directionality and branch diagnostics intentionally fail the target
contract on the unchanged V6 layouts:

| Stage | Meaningful ascent | Meaningful descent | Direction reversals | Same-hub returns | Forward rejoins |
| --- | ---: | ---: | ---: | ---: | ---: |
| Ruin Approach | 9 | 0 | 0 | 1 | 0 |
| Flooded Works | 9 | 0 | 0 | 1 | 0 |
| Broken Sanctum | 10 | 1 | 2 | 2 | 0 |

This preserves the exact reasons the geometry milestones exist: Ruin is
monotonic, Flooded has only a non-meaningful 40 px aggregate descent, and all
four optional rooms return to their origin hub.

### Empirical movement comfort bands

`validate_player_movement_runtime.gd` now drives the production player from rest
and with a short run-up, rather than relying only on ballistic constants:

```text
PLAYER_JUMP_COMFORT short=86.0x39.0 full=148.3x82.6 late=165.0x82.6 margin=62.3
```

The first value is horizontal reach and the second is rise. For this fixed-stage
pass:

- routine required transitions should survive the short-release envelope where
  practical;
- intentional challenge transitions may use the full-from-rest envelope, but
  cannot repeat without a recovery landing;
- the run-up result is optional-mastery headroom, not the default required-route
  target.

The new composition report also identifies repeated 80 px rises as roughly 61.5%
of the Traveler's theoretical route ledge height. That aligns with the owner-play
complaint: an 80 px rise is nearly the measured full single-jump height and
should not be repeated as ordinary staircase texture.

### Fixed-stage capture manifest

Regeneration command:

```powershell
.\tools\godot.ps1 --path . --script res://tools/capture_fixed_stage_screenshots.gd
```

The pre-change captures are stored under
`.codex-runtime/uiux/fixed_stage/` and intentionally remain outside source
control. SHA-256:

```text
575dd2ef25b76f30dc27b6b1c6c9e97ab036fd11f11534c5c865e6eefda8403e  flooded_optional_cache.png
277929999c3b2bdf473d12ca021b73ed66e15614e091758ca4991d14a39f4078  flooded_poison_visual_baseline.png
f37be3103ccaa62ef61b8a0abc8b2d724699ebcd974dab2f3d0577b878710c9e  flooded_poison_visual_debug.png
2d28dfe7efd2477ef78dd832fdb40eac7a7c01cb593291159ef51fc9ce0178d0  flooded_poison_visual_proof.png
e5acd915ab8333b4d1b863d321fa41ed1c8dd79b0abaca6b61439fd90c4d31af  flooded_route_choice.png
25e3fd08ec2fff1d390a53700da48fd2a0edb48ba345374f0ada24ed7265f4e9  ruin_route_choice.png
42e3546e3eaf482574f99effb467a3937936a7dfa6746765b2ae0e6d466b098f  ruin_start.png
f9f201c37d2b2b9dee0eb3d12d9b088177fbfe2b3b5c613cfeea369dfc181b0c  sanctum_crypt_recovery_compact.png
4397508856db9585cc9baf35406b77e4f45e581ed4ffdedccea2e69c61e5197f  sanctum_crypt_recovery.png
447fd5988aed48e305c0607ac6bae6c8faec0764e46fa68cf6aa88c404455ba6  sanctum_reliquary_return.png
7f4a14e5f56b920c0915a60951c6290f8c4821d413d6608651515c24f6daee89  sanctum_route_choice.png
```

## Limitations

- This is automated baseline evidence, not a manual fun verdict.
- Current fixed screenshots are isolated teleports and do not prove continuous
  start-to-exit traversal.
- No minimap exists at this baseline.
- Existing user-owned `.import` changes were present and are not part of this
  evidence or any task-owned commit.
