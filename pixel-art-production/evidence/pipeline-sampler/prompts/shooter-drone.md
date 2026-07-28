---
type: evidence
status: archived
owner: BK
created: 2026-07-27
last_reviewed: 2026-07-28
topic: Historical pipeline-sampler ImageGen prompt for the shooter drone
scope: Reproducibility input for the archived six-category sampler
source: ../README.md
---

# Shooter Drone ImageGen Prompt

```text
Use case: precise-object-edit
Asset type: canonical source draft for a 32×32 logical-cell pixel-art enemy sprite
Input image: Image 1 is the exact 32×32 logical grid and white canvas to draw upon. Preserve the grid and canvas geometry.

Primary request: Draw exactly one centered Cardborne hostile mobile shooter-drone, viewed from a true orthographic 90-degree top-down camera, unmistakably facing east (right). The sprite must be constructed only by completely filling whole grid cells. Every occupied cell is one solid color. No drawing may cross a cell boundary or partially fill a cell.

Required silhouette and semantic parts:
- compact diamond/hexagonal main body
- one conspicuously long forward gun extending toward the east, making facing direction instantly obvious
- exactly two rear mobility pods on the west side
- clean separable regions for body, hostile role accent, weapon/tool, and mobility
- large contiguous filled-cell regions; broad and simple silhouette, not scattered pixels
- generous empty margin of at least four full grid cells on every side

Exact allowed sprite colors only:
- hostile accent: #C92F4E
- darkest structure, replacing any dark-coral shade: #202833
- light structure: #E8EEF0
- mid structure: #44515E
Keep the supplied white background and grid colors unchanged. Do not introduce any other sprite color.

Composition: one object only, centered within the 32×32 grid, east-facing, readable at native 32×32 size. Keep the long gun and two rear pods distinct from the main body without using outlines.

Avoid completely: scene or environment, shadow, contact shadow, universal outline, gradient, glow, lighting, texture, noise, antialiasing, curved vector edges, text, labels, numbers, logo, watermark, projectile, exhaust flame, effect, platform, extra object, extra drone, visible perspective or three-quarter view.

Deliver exactly one square PNG image.
```
