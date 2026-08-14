---
type: evidence
status: active
owner: BK
created: 2026-08-14
last_reviewed: 2026-08-14
topic: Transit Gate clean-edge replacement candidate
scope: User-approved 192x192 transparent PNG replacement promoted byte-for-byte
source: User request to preserve the current Transit Gate identity while removing its uneven edge
related:
  - ../../../VISUAL_SYSTEM.md
  - ../../../cardborne-universal-art-style-reference.png
  - ../../replacement-workbench.json
  - ../../../../../.agents/execplans/2026-08-13-evidence-category-slots-and-scalable-swarm.md
---

# Transit Gate Clean-Edge Candidate Evidence

## Purpose

Retain the grounded source, exact hash, and AS-IS/TO-BE evidence for a cleaner
Transit Gate. The candidate preserves the current circular floor-portal identity
and footprint while removing the visibly uneven outer contour.

## Sources

- `docs/design/VISUAL_SYSTEM.md` was read completely before generation.
- `docs/design/cardborne-universal-art-style-reference.png` was inspected at
  original detail and supplied as an actual style-grammar reference.
- `art/visuals/production/gameplay/world/facility_transit_gate.png` was supplied
  as the edit target.
- The required and observed reference SHA-256 is
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- OpenAI built-in ImageGen created the raster on 2026-08-14. The tool did not
  expose a model revision. Reference inputs used
  `image_gen.referenced_image_paths`.
- The installed chroma-key helper removed the flat generation background and
  applied the permitted one-pixel edge contraction after actual-size edge review.
  ImageMagick performed only permitted resize, grayscale conversion,
  AS-IS/TO-BE placement, and plain labels.

## Findings

- The current gate has visibly irregular outer steps and a hard contour.
- The candidate is a radially balanced ring with uniform thickness, one broad
  system-cyan plane, one dark perimeter, and one short warm-off-white highlight.
- [`comparison.png`](./comparison.png) shows the current and candidate assets at
  the same 192x192 scale. [`grayscale-comparison.png`](./grayscale-comparison.png)
  confirms the ring remains legible without color.
- BK explicitly approved the V2 comparison on 2026-08-14. The candidate was
  copied byte-for-byte over the production Transit Gate target; its production
  SHA-256 matches the record below.

## Candidate Record

| Review file | SHA-256 | Canvas |
| --- | --- | --- |
| `candidates/facility_transit_gate.png` | `c97bb65851cfce0f500554fcb41d0ab24c4f836533bdb4de530b1a6695560ff4` | `192x192` transparent PNG |

Retained generation-source hashes:

- Chroma source: `76e495042408dc98843a81b8c41b6fa552ed13739b461db679fba187f3e13af1`
- Alpha source: `9202cd3641d1aaf4f17bee8d28a16bf4604a8b5e56630411fbb2ad531836fde9`

## Prompt

> Redraw only the current Transit Gate as a cleaner complete 192x192 top-down circular floor portal on a perfectly flat `#00ff00` chroma-key background. Preserve its simple circular identity and footprint. Use one thick dark mechanical outer body, one broad cool system-cyan active plane, and one short warm-off-white highlight plane. Make the circle smooth, radially balanced, centered, and uniform in thickness. No notches, modules, lamps, concentric ornament rings, panel seams, greebles, perspective tilt, ellipse, text, glow, or shadow.

## Recommendations

- Preserve the existing 192x192 canvas, pivot, semantic ID, runtime footprint,
  Transit Gate behavior, and guidebook ownership.

## Limitations

- Runtime import, guidebook rendering, live field capture, and Web export are
  not yet tested because the candidate has not been promoted.
