---
type: evidence
status: archived
owner: BK
created: 2026-07-27
last_reviewed: 2026-07-28
topic: Cardborne Phase 1 post-sampler pixel-asset capability gate
scope: Offline candidate review only; no runtime publication
source: ../../../README.md
related:
  - ../../../assets/asset-inventory.json
  - ../../pipeline-sampler/README.md
  - ./category-review.png
  - ./direction-motion-review.png
  - ./wall-signatures.png
  - ./candidate-catalog.json
---

# Gate A — Post-sampler capability evidence

## Purpose

This gate proves that the approved sampler grammar can produce a bounded new
asset set with directions, motion states, semantic layers, exact reassembly,
projectile variants, floor variants, and complete orthogonal wall topology.
It intentionally stops before Godot or Web runtime integration.

## Sources

- `pixel-art-production/README.md`, production requirements and workflow
- `pixel-art-production/assets/asset-inventory.json`
- `pixel-art-production/evidence/pipeline-sampler/`
- Four saved ImageGen prompts and raw candidates under
  `pixel-art-production/assets/source/candidates/phase-1/`
- Candidate briefs, manifests, native sources, semantic masks, split layers,
  pixel SVG derivatives, atlases, and review metadata under
  `pixel-art-production/assets/{briefs,manifests,generated}/candidates/phase-1/`

## Findings

- Eight candidate assets were built with sixty-eight frames:
  player chassis, primary weapon, engine flame, primary projectiles, chaser,
  shooter, floor/void tiles, and wall/cover tiles.
- Player chassis and weapon have four cardinal directions. Standard and opening
  Breach shots each have four directions and two flight frames.
- Chaser and shooter each have four move frames and four attack-startup frames.
- The floor set contains exactly eight planned variants. The wall set contains
  all sixteen orthogonal connection signatures plus a deterministic 3-by-3
  seam proof.
- Every manifest remains `approval_status: candidate`. The catalog is
  `review_status: awaiting_owner`, with no rejected frame recorded.
- Palette, alpha, semantic coverage, semantic overlap, exact reassembly,
  manifest, frame-budget, review, catalog, and connected-seam validators pass.
  Exact semantic reassembly differs from the native source by zero pixels.
- No output was copied into `pixel-art-production/runtime/`, and no game script,
  scene, resource, or import setting was changed.

## Review artifacts

- `category-review.png` compares each category at native and enlarged scale,
  then shows its semantic mask, silhouette, grayscale rendering, and permitted
  game backdrops.
- `direction-motion-review.png` shows the fixed column order north, east, south,
  west for cardinal rows; engine columns are animation frames zero through
  three.
- `wall-signatures.png` shows the complete sixteen-signature wall set followed
  by the deterministic 3-by-3 assembly.
- `candidate-catalog.json` is the machine-readable inventory of the eight
  candidates, sixty-eight frames, checksums, pivots, anchors, and Gate A review
  state.

## Limitations

- This gate establishes offline production capability and visual coherence,
  not in-game scale, combat readability, animation timing, retained-renderer
  performance, or Web behavior.
- The engine-flame loop is a minimal four-frame capability proof. Runtime
  timing and any additional native-pixel cleanup belong to the live slice only
  after Gate A approval.
- Candidate assets are not production-approved and must not be referenced by
  runtime code yet.

## Recommendations

- Review the three PNG boards and name any failing asset or frame.
- If accepted, change only this candidate set to approved and begin the
  isolated Phase 2 player/projectile runtime slice.
- If rejected, revise only the named assets and repeat Gate A. Keep Phase 2
  blocked until owner approval.
