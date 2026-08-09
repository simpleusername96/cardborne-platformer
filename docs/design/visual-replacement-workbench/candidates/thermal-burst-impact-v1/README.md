---
type: evidence
status: draft
created: 2026-08-09
scope: Approval-gated Thermal Burst direct-impact raster candidate
---

# Thermal Burst Impact Candidate V1

This workbench unit is isolated from production. The exact candidate, hash, alpha bounds, import
contract, and runtime-scale evidence must receive explicit user approval before any manifest,
provider, catalog, renderer, or effect-store integration.

## Locked target

- Semantic ID: `effect/thermal_burst_impact`
- Canvas/pivot: `192x192`, `[96,96]`
- Runtime scale by gameplay radius: `0.75/0.875/1.0` for `72/84/96`
- Direct player-primary enemy hit only; no splash-recipient, DOT, Seeker, reflected,
  structure-only, or EMP receipt
- One hard-edged orange burst with a compact hot center and two or three large planes
- No text, ring, particle field, smoke, gradient, soft glow, endpoint mark, frame sequence,
  detached debris, or background

## Approval state

The candidate is technically normalized and registered as `switch_ready`, but it has not received
user approval. `switch_ready` is not approval and does not authorize production promotion.

## Exact candidate

- Approval target:
  `docs/design/visual-replacement-workbench/to-be/assets/art/visuals/production/gameplay/effects/thermal_burst_impact.png`
- Candidate SHA-256: `4cb1b15b1118a093c52ad0f5f750e38af2af0640536659ffc4dc1e19c0474904`
- Canvas/pivot: `192x192`, `[96,96]`
- RGBA alpha bounds: `173x176+9+8`; all four corner pixels are fully transparent
- Planned production semantic ID: `effect/thermal_burst_impact`
- Planned production path:
  `art/visuals/production/gameplay/effects/thermal_burst_impact.png`
- Planned import: lossless PNG, alpha enabled, filter enabled, mipmaps disabled, no repeat
- Runtime footprint: the full `192`-pixel canvas is scaled to `144/168/192` world units, which
  represents gameplay radii `72/84/96` without changing collision or damage

The source ImageGen output is `source-imagegen.png` with SHA-256
`228c254f8638ede15abd2995fd479731c2e839ed3d48ef7c2c00fbb373dd5425`.
Chroma removal produced `thermal-burst-impact-alpha-source.png`; the only subsequent operations
were alpha handling, trim, proportional resize, and transparent centering.

## Actual reference input

ImageGen received both required images as actual image references:

1. `docs/design/cardborne-universal-art-style-reference.png`, canonical sheet SHA-256
   `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`
2. `build/visual-captures/phase8-radar-minimap-ko/03-peak-horde.png`, current gameplay pressure
   capture

The generation prompt requested one centered, transparent-ready, top-down Thermal Burst impact on
flat `#00ff00`: two or three hard-edged orange color planes, a compact pale hot center, Cardborne's
flat matte familiar-science-fiction language, and no ring, particles, sparks, debris, smoke, flame
plume, text, frame sequence, bloom, glow, blur, or background scene.

## Runtime-scale evidence

All previews use the current `1280x720` Korean gameplay capture. They place the exact candidate at
the same direct-hit point; no gameplay file, manifest, provider, effect store, or renderer consumes
the candidate yet.

| Evidence | Meaning | SHA-256 |
| --- | --- | --- |
| `docs/design/visual-replacement-workbench/previews/thermal-burst-impact-v1/as-is-generic-direct-hit.png` | Current generic direct-hit flash without Thermal receipt | `5f945c6228c5c151d627994b29d9353808bd127d9c7741ce929d27f2a78ccb5f` |
| `docs/design/visual-replacement-workbench/previews/thermal-burst-impact-v1/to-be-thermal-level-1-radius-72.png` | Candidate at `0.75x`, radius `72` | `87b49ca5aef324505eedf4e5a514202e432bdfb018e795431816dcbba9dc02b7` |
| `docs/design/visual-replacement-workbench/previews/thermal-burst-impact-v1/to-be-thermal-level-2-radius-84.png` | Candidate at `0.875x`, radius `84` | `4bc9fd1d66cc246533ea855e7802a5d18b82b8b7725f3888d5a7b06761a4f66c` |
| `docs/design/visual-replacement-workbench/previews/thermal-burst-impact-v1/to-be-thermal-level-3-radius-96.png` | Candidate at `1.0x`, radius `96` | `32abe80d35c926424d9ddd9605d7d7a2acc88cc3f6f71842ed21fc5cbb2c700d` |

## Exact approval gate

Approval must identify the SHA-256 above and accept the asset **as-is** for
`effect/thermal_burst_impact`. Until then, Phase 9.2 remains blocked: do not copy it into
production, add it to the manifest/provider, or emit a live Thermal effect.
