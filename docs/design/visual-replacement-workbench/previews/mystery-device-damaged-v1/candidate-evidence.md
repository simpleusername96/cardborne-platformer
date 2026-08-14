---
type: evidence
status: active
owner: BK
created: 2026-08-14
last_reviewed: 2026-08-14
topic: Anomaly Device attacked-but-unbroken raster state
scope: ImageGen source, alpha conversion, exact production candidate, and runtime-state contract
source: BK request on 2026-08-14 for a visibly cracked destructible intermediate state
related:
  - ../../../VISUAL_SYSTEM.md
  - ../../../cardborne-universal-art-style-reference.png
  - ../mystery-device-outcomes-v4-symbols/candidate-evidence.md
  - ../../../../../.agents/execplans/2026-08-13-evidence-category-slots-and-scalable-swarm.md
---

# Anomaly Device Damaged-State Evidence

## Decision

Use one same-footprint neutral damaged body after the first accepted hit while device
health remains above zero. The large central fractures communicate that the facility is
destructible without leaking Gravity, Cryo, or Weakpoint imagery. On destruction, remove
the body and display only the selected `288`-world-unit outcome symbol.

## Visual-authority evidence

- `docs/design/VISUAL_SYSTEM.md` was read completely before generation.
- `docs/design/cardborne-universal-art-style-reference.png` was inspected at original
  detail. Required and observed SHA-256:
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- The intact production device was the edit target. The canonical sheet was supplied in
  the same `image_gen.referenced_image_paths` call as style grammar only; its objects and
  layout were explicitly excluded from reproduction.
- Original reference provenance:
  `C:/Users/BK/.codex/generated_images/019fbfe9-857e-7453-b72d-20908d848577/exec-0b8aa606-cf55-45c1-abb3-fb3df762b080.png`,
  timestamp `2026-08-02 12:13:44 KST`.

## Files and hashes

| File | Purpose | SHA-256 |
| --- | --- | --- |
| `mystery-device-damaged-chroma-source.png` | retained built-in ImageGen source | `ce8b6ad3d0b7af7e855898bbc81e0cd1525dc7617700df48f9048fd91f112d49` |
| `mystery-device-damaged-alpha-contract-1024.png` | chroma-removed source with one-pixel edge contraction | `8b2687fa7b7fb9290cee9185afc06fc3d0fa898082911e9c114c240f98f03513` |
| `mystery-device-damaged.png` | exact 384×384 candidate and production byte | `57dd2919f4dea40864a51fcfee01caacfdcf46eec47045300f052285b022fb9f` |
| `comparison.png` | mechanically composed pristine/damaged review | `6b9d1f00170a44d6bf0bdbbb0e883ee52d9253f1181bfecca554384ae06e8cf4` |

The installed ImageGen chroma-key helper performed background removal and one-pixel edge
contraction. ImageMagick performed only permitted mechanical trim, resize, centered canvas
placement, dimension checks, hash checks, and review composition. The final alpha content
rectangle is `[8, 5, 368, 374]` on a `384×384` canvas.

## Generation prompt summary

The edit preserved the intact device's camera, footprint, neutral dark-gray palette,
cyan accents, and broad mechanical masses. It requested two or three large high-contrast
fractures across the central plate, one displaced or chipped plate edge, and restrained
impact scuffing. It prohibited outcome symbols/colors, tiny random scratches, extra
objects, glow, rings, text, and decorative greebles.

## Approval and limits

BK directly requested implementation of a clearly cracked attacked state on 2026-08-14.
The generated result is integrated as that requested intermediate state. Runtime capture,
focused import, and asset/renderer validation remain required before this evidence is
closed.
