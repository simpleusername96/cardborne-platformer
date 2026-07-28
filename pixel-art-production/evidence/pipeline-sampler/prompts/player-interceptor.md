---
type: evidence
status: archived
owner: BK
created: 2026-07-27
last_reviewed: 2026-07-28
topic: Historical pipeline-sampler ImageGen prompt for the player interceptor
scope: Reproducibility input for the archived six-category sampler
source: ../README.md
---

# Player Interceptor ImageGen Prompt

```text
Use case: stylized-concept
Asset type: Cardborne player-craft pixel-art sprite draft
Input images: Image 1 is a strict 64 x 64 logical-cell reference grid on a 512 x 512 white canvas; preserve the white background and visible grid and align the craft to its cells.
Primary request: Create exactly one canonical north-facing Cardborne interceptor, centered on the supplied grid.
Subject: One mustard-yellow interceptor only. True 90-degree top-down view. Give it an unmistakable pointed nose facing straight north, broad paired left and right wings, a compact cyan cockpit, one centered primary weapon mount, and a clear straight rear engine line. Keep body, left wing, right wing, cockpit, weapon mount, and engines as six visually separable semantic parts with simple cell-aligned boundaries.
Style/medium: Simple flat-color pixel art. Treat each logical cell as an indivisible 8 x 8 physical-pixel block. Fill every occupied cell edge-to-edge; use large contiguous regions and hard stair-stepped edges with no partial cells or antialiasing.
Composition/framing: Center the single craft with a generous minimum six-logical-cell margin on every side. Symmetric left/right silhouette except for no decorative asymmetry.
Color palette: Use only #D9A83D, #65A9B8, #2E3945, #202833, #E8EEF0 for the craft, plus the existing white background and reference-grid lines. Do not introduce any other craft colors.
Constraints: Preserve the grid as a visible construction guide. One craft only; clear north-facing orientation; centered weapon mount and rear engine line; simple semantic boundaries; no text; no watermark.
Avoid: any scene or environment, shadow or contact shadow, outline around the whole craft, gradients, glow, transparency effects, texture, speckles, scratches, panel noise, lighting variation, perspective, three-quarter view, side view, extra objects, labels, logos, or decorative micro-detail.
```
