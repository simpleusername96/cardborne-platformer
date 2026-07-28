---
type: evidence
status: archived
owner: BK
created: 2026-07-27
last_reviewed: 2026-07-28
topic: Historical pipeline-sampler ImageGen prompt for the thermal heavy shot
scope: Reproducibility input for the archived six-category sampler
source: ../README.md
---

# Thermal Heavy Shot ImageGen Prompt

```text
Use case: stylized-concept
Asset type: canonical hostile heavy thermal projectile draft for a top-down pixel-art game
Input image: Image 1 is a strict 32×32 logical-cell construction grid on a white canvas. Preserve the white background and visible grid exactly as the construction reference. Draw by filling complete logical cells only; every colored boundary must align to the supplied grid.

Primary request: Create exactly one projectile and nothing else. It is a true 90-degree top-down game sprite, centered on the horizontal middle axis, traveling east (right). The east-facing leading head must be unmistakable at first glance.

Semantic construction:
- Head: one large, compact ember-like damaging mass at the right/front, reading as roughly a 7-cell-radius form. Use a decisive rounded or faceted cell silhouette, not a literal flame icon.
- Dark inner core: a compact internal mass clearly contained inside the head.
- Affinity edge: a restrained hot-magenta region attached to the head's outer/front-facing area; it is a semantic material band, not an outline around the whole projectile.
- Wake: one narrow, connected rear wake extending west (left), visibly much thinner than the head and tapering in a few large cell steps. It must remain physically connected to the head.

Exact asset colors only:
- thermal orange #E45F36
- hot magenta #C92F4E
- dark core #202833
- pale highlight #E8EEF0
- existing white background and grid colors from the reference
Do not introduce any other asset colors.

Composition and constraints:
- generous empty grid margin on every side
- exactly one projectile; no duplicates, particles, sparks, debris, scene, environment, target, weapon, ship, UI, or extra object
- strictly flat whole-cell color regions
- no literal flame pictogram
- no cast shadow or contact shadow
- no enclosing outline around the whole asset
- no gradient, glow, bloom, transparency, antialiasing, texture, lighting, depth rendering, text, logo, or watermark
- retain the visible construction grid; do not redraw, distort, rotate, crop, or obscure it outside the filled projectile cells
- the silhouette must remain immediately readable after exact reduction to the 32×32 logical grid
```
