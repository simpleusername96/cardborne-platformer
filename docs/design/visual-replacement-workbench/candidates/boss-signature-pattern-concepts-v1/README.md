---
type: evidence
status: active
created: 2026-08-10
source: Five built-in ImageGen boss-pattern storyboards grounded by the canonical visual authority pair and the corresponding current Stage 1-5 boss captures
topic: Spatial and temporal review of the proposed five stage-specific boss signature maneuvers
related:
  - ../../../VISUAL_SYSTEM.md
  - ../../../../../.agents/execplans/2026-08-10-combat-correction-and-boss-pattern-expansion.md
---

# Boss Signature Pattern Concepts

## Purpose

These five three-panel storyboards explain the spatial and temporal identity of the
proposed Stage 1-5 boss signature maneuvers. They are review evidence only. They do
not approve replacement actor art, projectile art, VFX, UI, collision geometry, or
production assets.

Read every image from left to right. Empty floor represents a playable escape route;
it is not a proposed route overlay. Panel separators are explanatory framing and are
not runtime UI.

## Visual Authority Evidence

- Text authority: `docs/design/VISUAL_SYSTEM.md`, read completely on 2026-08-10.
- Canonical style reference supplied as an actual image reference to every generation
  and edit: `docs/design/cardborne-universal-art-style-reference.png`.
- Expected and observed canonical SHA-256:
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- Canonical sheet inspected at original `1448 x 1086` detail.
- Reference input method: `image_gen.referenced_image_paths`.
- Every first-pass generation received the canonical sheet and the corresponding
  current Stage 1-5 boss capture. Corrective edits also received the edit target,
  canonical sheet, and corresponding current boss capture.
- The canonical sheet supplied style grammar only. No depicted object, silhouette,
  glyph, UI, or layout is approved or extracted from it.
- No SVG or ImageMagick geometry was used. ImageMagick was not used to author or
  repair these images.

## Concepts

| Stage | Image | Read left to right | Locked runtime meaning | SHA-256 |
| ---: | --- | --- | --- | --- |
| 1 | `stage-1-radial-safe-gap.png` | Eight-direction warning, first outward burst, slightly rotated second burst | Two committed waves with one broad south-facing escape wedge; eight projectiles per wave and no homing | `1183ab22a2d4c29f8890c88e7c452c78aa9075d5965b74f572e253312c97a804` |
| 2 | `stage-2-chained-delayed-zones.png` | Current-position warning, first active plus next warning, old zone removed plus next step | Three frozen current/lead samples; at most one active zone and one next warning visible | `05795a2f4aeeb47b7ed2d3294d22c4582e6bb5073f7751919a10a49191de773f` |
| 3 | `stage-3-rotating-fan-chain.png` | First five-bolt fan, second fan rotated 30 degrees, third fan rotated another 30 degrees | Three committed straight fans, five projectiles each, no post-warning tracking | `0a3a0b943d91ea6124820e9b79c1eee76d32e26a5df659d0166614537afa582a` |
| 4 | `stage-4-stepped-beam-sweep.png` | Static beam below the frozen bearing, centered beam, static beam above it | Three separately warned non-overlapping corridors at `-32/0/+32` degrees; one active beam at a time | `fce2c6d70f20873815b9ab2a4f211553dace5fadc4a89b3de374060c05575815` |
| 5 | `stage-5-crossed-lane-gates.png` | `2-gap-2` warning, matching four-bolt horizontal wavefront, later `1-gap-3` perpendicular wavefront | Two sequential four-projectile gates; the second rotates 90 degrees and shifts the safe lane | `6117d634ae3c6369f17ed8efd828064fb99087033d81dc335f95c686005ccf3e` |

## Review Findings

- Stage 1 teaches the safe-gap rule before rotating it. The escape is visible without
  adding a route line or lowering projectile speed.
- Stage 2 pressures continued movement but does not follow the player after each
  warning is placed. Retiring the oldest zone prevents floor denial from accumulating.
- Stage 3 changes the safe sector over time while keeping every projectile straight and
  countable.
- Stage 4 creates a repositioning sequence rather than a continuously tracking laser.
  Only one exact-width corridor exists at a time.
- Stage 5 asks the player to clear one wall and then change axis for the second. Four
  projectiles per wall keep the maneuver well below the 24-projectile boss reservation.

## Limitations and Approval State

- Status: spatial design candidate only; not approved for runtime or production.
- ImageGen approximates current actor pixels. The existing production actor PNGs remain
  authoritative and are not replaced by these images.
- The diagrams communicate timing and topology, not pixel-exact collision, travel
  distance, speed, alpha, damage, or startup duration. Runtime truth must come from the
  boss pattern data and focused validators.
- Any soft shading introduced by ImageGen is not an approved VFX treatment. Runtime
  warnings, zones, projectiles, and beams must retain the flat hard-edged plane limits in
  `VISUAL_SYSTEM.md` and use existing approved identities where required.
- User acceptance of a maneuver concept updates the execution contract only. It does not
  approve generated pixels as a production asset.
