---
type: evidence
status: archived
owner: BK
created: 2026-08-14
topic: EMP upgrade-card artwork approval candidate
source: .agents/completed-plans/2026-08-14-weapon-unlocks-and-early-level-pacing.md
related:
  - ../../../VISUAL_SYSTEM.md
  - ../../../cardborne-universal-art-style-reference.png
---

# EMP Upgrade Card Candidate V2

## Purpose

This evidence package records the exact EMP upgrade-card artwork that BK approved
and that was subsequently promoted into the production gameplay asset set.

## Sources

- Binding visual specification: `docs/design/VISUAL_SYSTEM.md`, read completely.
- Canonical style sheet: `docs/design/cardborne-universal-art-style-reference.png`.
- Canonical sheet SHA-256:
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- The canonical sheet was inspected at original detail and supplied through
  `image_gen.referenced_image_paths` for both generation passes.
- Built-in ImageGen was used. The second pass simplified the first result to the
  required flat-stencil plane count and removed decorative discharge bursts.
- A flat green chroma background was removed with the installed ImageGen helper,
  then the result was mechanically resized to the required 192×192 canvas.

Final generation prompt:

> Redraw the EMP device as a simpler flat-stencil symbol beside the canonical
> Cardborne assets. Preserve a recognizable central capacitor and two outward
> prongs. Use 4–6 large flat planes, warm off-white, near-black, and one
> system-cyan capacitor plane. Remove bevels, highlights, gradients, surface
> facets, internal segment lines, lightning bursts, text, frames, rings, glow,
> particles, shadows, texture, and tiny details.

## Findings

- Approval target: `emp-upgrade-card-candidate-v2-192.png`.
- Candidate SHA-256:
  `328e8eba58246c0000e9d6454730531a063db09ba46e1300d7ad31aa744213b6`.
- Comparison sheet: `active-family-comparison.png`.
- Comparison SHA-256:
  `dc6e03cab3f2a3e1e31ae4bcc8dd55bf5566b3998447fd1d79231c8f04ce3ef6`.
- The candidate is centered, transparent, 192×192, and remains readable at the
  intended card-art size.
- It uses one familiar capacitor-device silhouette and does not copy a specific
  object from the canonical sheet.
- BK approved this exact candidate in the active implementation session on
  2026-08-14.
- The approved bytes were promoted to
  `art/visuals/production/gameplay/upgrades/emp.png` with the same SHA-256. The
  workbench records the unit as `applied`, and the production manifest resolves
  the identity as `upgrade/emp`.

## Limitations

- The files in this directory remain historical approval evidence. Runtime code
  must resolve the promoted production asset rather than load this preview path.
