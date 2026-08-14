---
type: evidence
status: active
owner: BK
created: 2026-08-14
last_reviewed: 2026-08-14
topic: Anomaly Device revealed-state symbol candidates
scope: User-approved Gravity Pull, Cryo Lock, and Weakpoint Expose PNG symbols promoted byte-for-byte
source: User-selected replacement of Decoy Signal with Weakpoint Expose on 2026-08-14
related:
  - ../../../VISUAL_SYSTEM.md
  - ../../../cardborne-universal-art-style-reference.png
  - ../mystery-device-outcomes-v3-semantic/candidate-evidence.md
  - ../../../../product/vehicle_game_spec.md
  - ../../../../../.agents/execplans/2026-08-13-evidence-category-slots-and-scalable-swarm.md
---

# Anomaly Device Symbol Candidate Evidence

## Purpose

Retain the grounded PNG sources, exact hashes, runtime-scale comparisons, and
review state for the three Anomaly Device symbols. The neutral device body keeps
the outcome hidden until the first accepted player hit. That hit changes the still-live
device to its separate cracked body; after destruction, one centered symbol is the sole
authored device image while the code-native full-area footprint continues to communicate
exact range and lifetime.

## Sources

- `docs/design/VISUAL_SYSTEM.md` was read completely before generation.
- `docs/design/cardborne-universal-art-style-reference.png` was inspected at
  original detail and supplied as an actual image reference to every generation.
- The required and observed reference SHA-256 is
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- OpenAI built-in ImageGen created each raster on 2026-08-14. The tool did not
  expose a model revision. The canonical reference was supplied with
  `image_gen.referenced_image_paths`.
- The installed chroma-key helper removed the flat generation background and
  applied the permitted one-pixel edge contraction after a thin green fringe
  appeared in the first actual-size review.
  ImageMagick performed only permitted resize, grayscale conversion, comparison
  placement, compositing for the review-only device preview, and plain labels.

## Findings

- Gravity uses four large inward arrows around one dark sink. Its verb is
  **converge**.
- Cryo uses one broad six-arm snowflake and a light hexagonal core. Its verb is
  **freeze**.
- Weakpoint uses two separated armor halves around one exposed red diamond. Its
  verb is **open armor**.
- [`comparison.png`](./comparison.png) verifies the full candidate shapes.
  [`runtime-scale-comparison.png`](./runtime-scale-comparison.png) verifies the
  superseded 72-world-unit review size. [`grayscale-comparison.png`](./grayscale-comparison.png)
  verifies separation without hue. [`device-overlay-preview.png`](./device-overlay-preview.png)
  is superseded review-only placement evidence; it is not the approved runtime composition.
- BK explicitly approved the V4 comparison on 2026-08-14. The candidates were
  promoted byte-for-byte to the matching production world PNG targets; their
  approved production SHA-256 values match the records below.
- BK clarified on 2026-08-14 that the three comparison symbols must appear alone
  after reveal, not over another device image. This clarification supersedes the
  earlier overlay interpretation without changing any approved PNG bytes.

## Locked Product Semantics

- Gravity Pull: radius `480`, duration `5.0 s`, ordinary mobile enemies only.
- Cryo Lock: radius `360`, duration `3.0 s`, ordinary mobile enemies only.
- Weakpoint Expose: radius `420`, duration `5.0 s`; affected ordinary mobile
  enemies take `1.25x` player-owned damage. It changes neither movement nor AI
  targeting and excludes bosses and fixed hostile structures.
- Before reveal, no image, minimap marker, color, or text leaks the assigned
  outcome. The first accepted hit identifies the result in text and switches to the
  neutral cracked body. The symbol appears only after destruction, at `288` world units.

## Candidate Records

| Outcome | Review file | SHA-256 | Shape verb |
| --- | --- | --- | --- |
| Gravity Pull | `candidates/mystery_device_gravity.png` | `171afbb022e322e2c5630394079fb167637b819d3da3e114a38d376f15f40a34` | converge inward |
| Cryo Lock | `candidates/mystery_device_cryo.png` | `7262d3ba378e18c734fbdcb82122595749ab481802fc37fc7e1993cf6bce0dd9` | freeze motion |
| Weakpoint Expose | `candidates/mystery_device_weakpoint.png` | `15e585cd55fdfc423d1addc20c89c69c7e5cc079b1d288c364dafc7b20a153ff` | expose core |

Retained generation-source hashes:

- Gravity base chroma: `0aae10086d8db9b4af006a61593573196a521f2bf5284293454036e08cb12998`
- Gravity selected edit chroma: `cf14264ec8c680f2ab18da03c027fcbe10b1af6a2fb41747de3fffec30902e6d`
- Gravity selected alpha: `01270d06e59d068203e5251d3d0f1ee50ca731349494af522a3c75be726dc2f9`
- Cryo chroma: `86b7094ec2116f7bfc9e6e2e9ee2c34c7c6afd1e94bc1fc4fdba6065051d6abf`
- Cryo alpha: `62e31be60eabccf5e33a5c07f909dcfd021e26d18d4835c55bd99886f72ed828`
- Weakpoint chroma: `315864cbfaac50e9c8a78a6b5167f7c61a598bc6da408bf7eeebe586ae940bd6`
- Weakpoint alpha: `3e55a5ed272b3032230ade2cf09391e3096ab4972e37066036b3f9325aea6350`

## Prompts

All prompts used the canonical reference sheet as style grammar only and
explicitly prohibited copying its objects or layout.

### Gravity Pull

> Create one immediately readable gravity-pull symbol for a top-down science-fiction action game on a perfectly flat `#00ff00` chroma-key background. Use one central near-black compact void with exactly four broad mechanical arrowhead masses pointing inward from north, south, east, and west. Keep one dominant silhouette, at most two secondary functional planes, restrained arc-purple accent, antialiased hard edges, and generous padding. No enclosing circle, badge, text, number, glow, rings, tiny detail, repeated lamps, greebles, or shadow.

The actual-size review found the four small purple shard accents unnecessary, so
one targeted edit used the generated Gravity source and canonical sheet as actual
inputs:

> Remove only the four small purple shard accents. Keep exactly four broad inward arrowheads, the compact near-black central void, overall centered silhouette, scale, padding, top-down orientation, and antialiased hard edges unchanged. Leave clean negative space and add nothing.

### Cryo Lock

> Create one immediately readable freeze symbol for a top-down science-fiction action game on a perfectly flat `#00ff00` chroma-key background. Use one broad six-armed mechanical snowflake built from thick straight cyan bars around one warm-off-white hexagonal core. Keep one dominant silhouette, one secondary core, antialiased hard edges, and generous padding. No enclosing circle, badge, text, number, glow, scattered crystals, tiny detail, repeated lamps, greebles, or shadow.

### Weakpoint Expose

> Create one immediately readable exposed-weakpoint symbol for a top-down science-fiction action game on a perfectly flat `#00ff00` chroma-key background. Use exactly two thick dark mechanical armor halves pulled apart left and right around one large bright danger-red diamond core. Keep wide negative space, one open-armor silhouette, one central core, antialiased hard edges, and generous padding. No shield outline, target ring, crosshair, badge, text, number, glow, tiny cracks, particles, greebles, or shadow.

## Recommendations

- The production owner registers the three world-state semantic PNGs and renders
  exactly one centered `288`-world-unit standalone symbol after destruction. Preserve
  the pristine/cracked neutral body sequence before destruction and preserve the
  code-native effect footprint.

## Limitations

- The original comparison has not been regenerated at the corrected `288`-world-unit
  runtime size; real runtime capture is the current composition evidence.
- Image generation produced limited bevel planes. The user approved the resulting
  symbols and later clarified their standalone runtime composition.
