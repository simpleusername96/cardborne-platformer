---
type: evidence
status: active
created: 2026-08-09
source: Current Cardborne production capture geometry at 655e0ee2 plus built-in ImageGen edits grounded by the canonical visual authority pair
topic: Progression feedback, combat readability, and HUD TO-BE direction
related:
  - ../../../VISUAL_SYSTEM.md
  - ../../../../../docs/reports/2026-08-08-combat-pressure-and-surface-depth.md
---

# Progression Feedback and Combat Readability TO-BE Evidence

## Purpose

These images make the planned HUD, upgrade, Electric Field, elemental-feedback, minimap, and boss-shield
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
- Revision input: direct user corrections on 2026-08-09 require a literal visible XP label, an
  Electric Field that fills its complete damage area and does not resemble a shield, zero internal
  horizontal lines in upgrade cards, and same-size actor-clipped Toxin/Cryo overlays. Phase 8.1 of
  the related execution plan must amend the older no-XP/text-only-status visual clauses before
  runtime implementation; these evidence images do not silently override the active spec.

## Findings

| TO-BE image | AS-IS edit target | Prompt set and intended decision | SHA-256 |
| --- | --- | --- | --- |
| `gameplay-hud-minimap-to-be.png` | `05b-reinforcement-facility.png` | Preserve the gameplay scene; add an unmistakable panel-free rail with `Lv. 7` and literal `EXP 84 / 160`, low-priority nearby-enemy direction arcs, one higher-priority incoming-attack triangle, and shape-distinct minimap roles. Electric Field is intentionally absent because its scale question is isolated below. | `1b580319c552eb2e0868a841b7e7b368e2ce3d0de9a4d293c46d1c86a7c13665` |
| `electric-field-to-be.png` | `30-boss-04-stage-4-active.png` | Remove the current Mint hollow donut while preserving its outer gameplay radius; show one ground-attached low-alpha Arc-purple disk whose complete interior is visible, distinct beside the unchanged magenta boss shield. | `fbdaa7425e2fb7a3d7eec38f532d058daf29549eacbae088b8cc3e98a3990ff5` |
| `element-upgrade-enhance-to-be.png` | `06b-level-up-selected.png` | Preserve the three-card modal; show Thermal Burst `Lv.1 -> 2` with exact current-to-next radius and damage rows. The card uses vertical spacing only and contains no horizontal separator, divider, underline, rule, or row bar. | `ed69ca1c5be25700208322b722c772ac1a95c1c112b01b95342fb75745c7108a` |
| `elemental-hit-feedback-to-be.png` | `03-peak-horde.png` | Three-state visual QA board: one bounded Thermal impact and same-size Toxin/Cryo translucent layers clipped to the enemy body silhouette, with affinity-colored primary projectiles. | `2204d77a9eeff115b4d595b77c72dd8ce0774f7f96e21b3b51cef795aee3c85f` |
| `boss-shield-readability-to-be.png` | `30-boss-04-stage-4-active.png` | Remove the opaque shield disc; retain one restrained body-attached command boundary and a notched boss minimap marker so the authored boss body owns identity. | `16bd966c87b937ae369bae6cdd575640d52af43e3abb81997f785a238ddde2f6` |

The images are intentionally separate because each answers a different approval question:
HUD density, Electric Field range language, upgrade information hierarchy, elemental state
readability, and boss-body readability. The execution plan owns exact behavior, copy, sizes,
capacities, and validation. An earlier combined HUD/field generation exaggerated the field across
most of the viewport; it was rejected during review and was not copied into this folder.

## Limitations

- ImageGen produced `1672x941` review images. Runtime implementation must be validated at the
  supported `960x540`, `1280x720`, and `1920x1080` viewports instead of copying these pixels.
- ImageGen slightly reinterpreted some unchanged art. In particular, the boss mockup is evidence
  for shield dominance and marker shape only. Production must preserve the existing five boss
  PNGs and change only their shared shield presentation unless a later exact per-boss workbench
  unit receives approval.
- The Electric Field image preserves the current screenshot ring's apparent outer footprint for
  comparison; it is not a measurement oracle. Runtime captures and the collision debug overlay
  must prove exact `120/140/160` world-unit radii from the secondary definition. Enemy damage still
  begins when the enemy body overlaps that disk, so the enemy radius remains part of hit testing.
- The elemental triptych is a comparison board, not a reachable simultaneous runtime state.
  Cardborne still permits only one selected primary element at a time.
- The Toxin and Cryo examples authorize only an overlay with the same transform, scale, and alpha
  silhouette as the unchanged actor. They do not authorize an outline, enlargement, halo,
  surrounding ring, separate status raster, orbit icon, particle system, or repeated strobe.
- The vertical rules in the elemental QA comparison board separate examples and are not runtime UI.
  Upgrade cards must contain no horizontal separator in unlock, enhancement, selected, hover,
  focus, or disabled states.
- Mockup typography is not a localization asset. Runtime Korean and English strings remain
  Control-owned and must pass glyph, overflow, and 200% text checks.
- No image in this folder is approved for the production manifest. Thermal impact art, if used,
  requires its own transparent PNG candidate, AS-IS/TO-BE evidence, exact hash, and explicit
  approval under the visual-replacement workflow.
