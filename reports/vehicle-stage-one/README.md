---
type: evidence
status: active
owner: BK
created: 2026-07-20
topic: Vehicle Stage 1 validation, rendered evidence, and play observations
related:
  - ../../docs/product/vehicle_stage_one_experimental_spec.md
  - ../../.agent/execplans/2026-07-20-vehicle-stage-one.md
---

# Vehicle Stage One Evidence

## Build under review

- Branch: `agent/vehicle-stage-one`
- Base: `302ca2a6815735bf2d9fc7e154577a6aed4d3f89`
- Engine target: Godot 4.7.x GL Compatibility
- Perspective: flat top-down 2D on one authored ground plane
- External assets: none

## Play instructions

1. Choose Rapid Repeater or Scatter Array from deployment.
2. Move with arrows or WASD and aim with the mouse. Hold left mouse or Left Shift to fire.
3. Use Space to dash and `Z` for the EMP burst.
4. The Auto Seeker fires on its own when an eligible target is in range and visible.
5. Destroy both shield/repair generators in the installation district. The upper route contains the optional Dredge Warden; the lower route bypasses it.
6. Open the relay cache and select one of three cards with the mouse or keys 1–3.
7. Enter the eastern basin and defeat the Foundry Colossus. Ordinary enemies outside the basin do not have to be killed.
8. Review the result and modules in the garage, change primary if desired, and replay.

## Automated and build evidence

The CI workflow records headless import, focused vehicle contracts, viewport layout checks, rendered native captures, Web export, and a built-browser boot screenshot. Exact run URLs, artifact names, and pass/fail output are added here after the remote workflow completes.

Expected capture set:

- `01-deployment.png`
- `02-open-combat.png`
- `03-installations-route.png`
- `04-upgrade-choice.png`
- `05-optional-field-boss.png`
- `06-stage-boss.png`
- `07-result.png`
- `08-garage.png`
- `09-web-build-boot.png`

## Concrete play observations

These observations are completed from the rendered build and direct scripted/manual review before the PR is marked ready:

- Movement and shooting without rewards: pending remote built-artifact review.
- Manual target priority: pending review of generator/turret and boss-pylon encounters.
- Dash purpose: pending review of lane crossing, invulnerability, Ion Wake, and Ram Pulse.
- Upgrade visibility: pending review of the post-cache installation/boss approach.
- Damage attribution: pending projectile/telegraph and browser-render review.
- Immediate replay pull: pending result/garage/replay review.

## Known limitations before owner review

- Runtime art is deliberately project-owned vector/geometry-style proof art, not final bespoke raster production art.
- Generated waveform SFX prove timing and feedback channels but are not a final sound library.
- The bounded proof keeps one chassis, two primaries, one passive, and one active skill.
- Minimal persistence stores modules and loadout only; there is no economy or cross-stage progression.
- The main stage runtime is intentionally consolidated for fast experimental iteration and should be decomposed if the direction is accepted.
