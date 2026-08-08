---
type: evidence
status: active
created: 2026-08-09
scope: Preview-only straight-beam raster candidate provenance
---

# Borderless Beam Strip Candidate V1

This candidate is not approved for production. It remains isolated in the workbench until BK
approves the exact 128x32 image and rendered Beam Sentinel/boss startup and active states.

## Authority inputs

- `docs/design/VISUAL_SYSTEM.md` was read completely.
- `docs/design/cardborne-universal-art-style-reference.png` was inspected at original detail and
  supplied to the built-in ImageGen tool as an actual image reference.
- Authority sheet SHA-256:
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- The current `cue_beam_strip_9.png` and Crown boss raster were also supplied as footprint and
  runtime-context references. Neither was used as approval.

## Built-in ImageGen prompt

Use case: `stylized-concept`. Create exactly one long, thin, perfectly horizontal, borderless
ivory-white energy strip on a uniform `#00ff00` chroma-key background. Match the authority
sheet's flat matte plane grammar. Keep equal thickness from left to right. Exclude dark perimeter,
outline, embedded core, internal gradient, glow, bloom, endpoint cap, taper, rounded cap,
particles, detached marks, panel seams, repetition, texture, perspective, scene, boss, vehicle,
text, shadow, reflection, and watermark.

## Files and normalization

- `source-imagegen.png`: unmodified built-in ImageGen output.
- `beam-strip-alpha.png`: local chroma-key removal with the installed imagegen skill helper,
  auto-key border sampling, soft matte, thresholds 12/220, and despill.
- `cue_beam_strip_9_candidate.png`: non-creative crop/resize/canvas normalization to exact
  `128x32` RGBA. The visible strip is `128x20` at `(0,6)` so the existing width normalization
  continues to match the live beam corridor.
- Candidate SHA-256:
  `527607b4f68c950a4781b4a6dc521d086d66d752851b34320ca799be0edf23fe`.

## Intended contract

- Semantic ID: `cue/beam_strip_9`.
- Canvas/pivot: `128x32`, `[64,16]`.
- Shared by Beam Sentinel and straight boss beams.
- Candidate bytes may move to production only after exact user approval.

## Rendered evidence

The canonical full-evidence capture path passed with 87 exact outputs at 1280x720 after adding
dedicated Crown-beam startup and active fixtures. The original production raster was restored to
SHA-256 `f30a3e2027de9e3580973d1e54051617e7b5f87e58571d768f6ad558b2924e48`
after candidate capture. Exact AS-IS and TO-BE Beam Sentinel/Crown startup and active images are
stored under `docs/design/visual-replacement-workbench/previews/beam-strip-borderless-v1/`.
