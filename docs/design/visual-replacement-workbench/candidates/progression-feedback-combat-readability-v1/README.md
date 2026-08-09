---
type: evidence
status: active
created: 2026-08-09
source: Current Cardborne production capture geometry at 655e0ee2 plus built-in ImageGen edits grounded by the canonical visual authority pair
topic: Progression feedback, combat readability, and HUD TO-BE direction
related:
  - ../../../VISUAL_SYSTEM.md
  - ../../../../../.agents/execplans/2026-08-08-combat-pressure-and-surface-depth.md
---

# Progression Feedback and Combat Readability TO-BE Evidence

## Purpose

These images make the planned HUD, upgrade, elemental-feedback, minimap, and boss-shield
changes concrete before implementation. They are composition and hierarchy references only.
They are not production assets, runtime acceptance captures, per-asset approvals, or permission
to replace existing authored actor art.

## Sources

- Visual text authority: `docs/design/VISUAL_SYSTEM.md`, read completely on 2026-08-09.
- Canonical sheet supplied as an actual image reference to every ImageGen edit:
  `docs/design/cardborne-universal-art-style-reference.png`.
- Observed canonical-sheet SHA-256:
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- AS-IS capture set: `build/visual-captures/beam-production-655e0ee2`, Korean,
  `1280x720`, 87-image production capture completed on 2026-08-09.
- Capture revision: `655e0ee2cee81a8e4e300782dc0285295da5f952`.
- Verified implementation baseline at planning time:
  `b9a41aee47eb18bb07edbe63a7bf840b47d6ef1c`. The intervening changes affect
  documentation, workbench state, and Thermal Burst localization, not gameplay HUD or world
  geometry.
- Generation mode: built-in ImageGen with the AS-IS capture as edit target and the canonical
  sheet as style-grammar reference. No SVG or ImageMagick geometry was used.

## Findings

| TO-BE image | AS-IS edit target | Prompt set and intended decision | SHA-256 |
| --- | --- | --- | --- |
| `gameplay-hud-minimap-to-be.png` | `05b-reinforcement-facility.png` | Preserve the gameplay scene; add a panel-free slim XP rail, low-priority nearby-enemy direction arcs, one higher-priority incoming-attack triangle, and shape-distinct minimap roles. | `7b34c3d2658d11647ce732e55d604c56972c622854e326f30dfcc0b16f225676` |
| `element-upgrade-enhance-to-be.png` | `06b-level-up-selected.png` | Preserve the three-card modal; show Thermal Burst `Lv.1 -> 2` with exact current-to-next radius and damage rows and select that card. | `d875fe9a34b34d33744c32d7c84390767a6af71858b5e6eaa690e0580d86ba8a` |
| `elemental-hit-feedback-to-be.png` | `03-peak-horde.png` | Three-state visual QA board: one bounded Thermal impact, Toxin body tint/application pulse, and Cryo body tint/application pulse, with affinity-colored primary projectiles. | `8ecb8f3567d6796027d2da7060cae4e2dcd2e4de9515ddac11ffca81313bee0b` |
| `boss-shield-readability-to-be.png` | `30-boss-04-stage-4-active.png` | Remove the opaque shield disc; retain one restrained body-attached command boundary and a notched boss minimap marker so the authored boss body owns identity. | `16bd966c87b937ae369bae6cdd575640d52af43e3abb81997f785a238ddde2f6` |

The images are intentionally separate because each answers a different approval question:
HUD density, upgrade information hierarchy, elemental state readability, and boss-body
readability. The execution plan owns exact behavior, copy, sizes, capacities, and validation.

## Limitations

- ImageGen produced `1672x941` review images. Runtime implementation must be validated at the
  supported `960x540`, `1280x720`, and `1920x1080` viewports instead of copying these pixels.
- ImageGen slightly reinterpreted some unchanged art. In particular, the boss mockup is evidence
  for shield dominance and marker shape only. Production must preserve the existing five boss
  PNGs and change only their shared shield presentation unless a later exact per-boss workbench
  unit receives approval.
- The elemental triptych is a comparison board, not a reachable simultaneous runtime state.
  Cardborne still permits only one selected primary element at a time.
- The visible Toxin and Cryo outlines illustrate a short application pulse. They do not authorize
  a persistent ring, separate status raster, orbit icon, particle system, or repeated strobe.
- Mockup typography is not a localization asset. Runtime Korean and English strings remain
  Control-owned and must pass glyph, overflow, and 200% text checks.
- No image in this folder is approved for the production manifest. Thermal impact art, if used,
  requires its own transparent PNG candidate, AS-IS/TO-BE evidence, exact hash, and explicit
  approval under the visual-replacement workflow.
