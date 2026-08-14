---
type: evidence
status: archived
owner: BK
created: 2026-08-14
last_reviewed: 2026-08-14
scope: Rejected simplified Gravity, Cryo, and Decoy Mystery Device raster candidates retained only as visual history
source: User rejection of mystery-device-outcomes-v1 for excessive detail on 2026-08-14
related:
  - ../../../VISUAL_SYSTEM.md
  - ../../../cardborne-universal-art-style-reference.png
  - ../../replacement-workbench.json
  - ../mystery-device-outcomes-v1/candidate-evidence.md
---

# Simplified Mystery Device Outcome Candidate Evidence

## Purpose

Retain the historical evidence for a second Mystery Device outcome set. The user
rejected it on 2026-08-14 because the three silhouettes did not communicate
their functions distinctly enough. It is not an approval or production switch.

The replacement review set is
[`../mystery-device-outcomes-v3-semantic/candidate-evidence.md`](../mystery-device-outcomes-v3-semantic/candidate-evidence.md).

## Sources

- `docs/design/VISUAL_SYSTEM.md`, read completely before generation.
- `docs/design/cardborne-universal-art-style-reference.png`, inspected at
  original detail and supplied as an actual ImageGen reference. Its SHA-256 is
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- Current production simplicity references supplied directly to ImageGen:
  `facility_repair_pad.png`, `facility_transit_gate.png`,
  `mystery_device_intact.png`, and `actor_enemy_generator_base.png`.
- OpenAI ImageGen, used through `image_gen.referenced_image_paths` on
  2026-08-14. The tool did not expose a model revision.

## Findings

- The rejected v1 set had too many nested rings, plates, seams, and small
  mechanical parts compared with the actual production world assets.
- The v2 brief limits every outcome to one dominant silhouette, at most two
  functional secondary masses, three or four broad planes, and one restrained
  semantic accent. It prohibits cables, pipes, rivets, repeated lamps, cracks,
  rubble, nested outlines, glow, particles, and decorative micro-detail.
- Gravity is four broad inward-facing masses around one violet void.
- Cryo is two opposing clamp masses around one pale-cyan core.
- Decoy is one triangular beacon mass, three broad fins, and one cyan slit. An
  earlier red-fin output was rejected before retention because red implied a
  danger state instead of misdirection.
- [`reference-scale-comparison.png`](./reference-scale-comparison.png) places
  the candidates beside real 192-pixel production assets. It is the primary
  detail-density check. [`comparison.png`](./comparison.png) shows the current
  generic resolved device beside the three candidates.
- The candidates are review-only. They are absent from the gameplay manifest
  and runtime asset provider.

## Candidate records

| Outcome | Review file | SHA-256 | Proposed semantic ID |
| --- | --- | --- | --- |
| Gravity Pull | `candidates/mystery_device_gravity.png` | `dd2f49743efce2c0b8227e7fc5a8bba23ab14a9b751076872927d4965140c03d` | `world/mystery_device_gravity` |
| Cryo Lock | `candidates/mystery_device_cryo.png` | `df8b8b1943be197e2a4f3032600edb042ca714037459bb67001c8fe2cc54714b` | `world/mystery_device_cryo` |
| Decoy Signal | `candidates/mystery_device_decoy.png` | `c714da509de8f106c24cfd59980afc7268d8fae55ef5e23a13bdf0eda40b2e3e` | `world/mystery_device_decoy` |

The retained source hashes are:

- Gravity chroma source: `19c3344246f97caac88cc652dcac2642d6d2c5ecc31cc986cb7795f2104f0acb`
- Gravity alpha source: `568e62a64e34c9a6447055c9146136fc7758f9f5cc42ccdc2e12df04a6b2a804`
- Cryo chroma source: `639bbb7bce6f73f2da10866cb4283431b796293a1c26b0fa01775996ab1e4325`
- Cryo alpha source: `d99722835aa61f90be09f29cc4efbfa7d9e618939b0726f512719f83d40e4917`
- Decoy chroma source: `e227082bd208889949f547ebd2182e1897bdb1140aee3d405d0708f7f4a258b9`
- Decoy alpha source: `5fbf437e926249aefa1c500d846c32a748fc906508c0a7085313b4beb50767e4`

The project chroma-key helper converted the flat green generation background
to alpha. ImageMagick performed only mechanical resize, alpha-preserving
placement, and plain evidence labeling. It did not author visual geometry.

## Recommendations

- Review the three outcomes as one set at the size shown in
  `reference-scale-comparison.png`.
- Promote no file until the user explicitly approves the full set.
- After approval, route resolved state by outcome and validate the three assets
  together in a live gameplay capture before retiring the generic resolved
  asset.

## Limitations

- This pass verifies silhouette simplicity and relative detail density only.
- It does not prove contrast against every live battlefield background.
- Runtime integration, manifest changes, and production asset replacement are
  intentionally outside this review step.
