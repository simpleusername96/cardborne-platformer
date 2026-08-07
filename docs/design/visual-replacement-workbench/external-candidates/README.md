---
type: evidence
status: active
owner: BK
created: 2026-08-04
last_reviewed: 2026-08-07
topic: Curated external visual sources and review-only EMP candidate
scope: License, provenance, hashes, adaptation intent, rejection decisions, and review artifacts for external visual source intake
source:
  - https://kenney.nl/assets/space-shooter-remastered
  - https://kenney.nl/assets/space-kit
  - https://www.kenney.nl/assets/particle-pack
  - https://kenney.nl/assets/sci-fi-rts
related:
  - ../README.md
  - ../../VISUAL_SYSTEM.md
---

# External Visual Candidate Register

## Purpose

This folder preserves the small, audited subset of external source material that
may accelerate Cardborne's authored PNG replacement work. It also contains one
project-generated EMP proposal. Everything here is review-only: no file in this
folder is an approved TO-BE deliverable or a production runtime asset.

The production rule is unchanged. A selected source must be redrawn or
re-rendered into Cardborne's exact top-down camera, canvas, pivot, palette, dark
perimeter, large-plane count, and semantic role before it can enter
`to-be/assets/` and receive exact-hash approval.

## Sources

### Imported source packs

| Pack | Official page | License | Downloaded archive SHA-256 |
| --- | --- | --- | --- |
| Kenney Space Shooter Remastered | <https://kenney.nl/assets/space-shooter-remastered> | CC0; included copy at [`licenses/kenney-space-shooter-remastered-CC0.txt`](./licenses/kenney-space-shooter-remastered-CC0.txt) | `0edbe0ab5cda6c44901d8c42f150268fdfa0c8d48492098669f37e9c296929b5` |
| Kenney Space Kit | <https://kenney.nl/assets/space-kit> | CC0; included copy at [`licenses/kenney-space-kit-CC0.txt`](./licenses/kenney-space-kit-CC0.txt) | `d5d7cdf2635ed5a43a9187deaf409b6f47484e402321128341d3c3698e9ef4d9` |

The original archives are intentionally not tracked. Only selected PNG sources,
their exact hashes, and the included licenses are retained.

### Inspected and rejected packs

| Pack | Official page | Archive SHA-256 | Decision |
| --- | --- | --- | --- |
| Kenney Particle Pack | <https://www.kenney.nl/assets/particle-pack> | `b631d4b07f7002549fdcf155f01141ad482f79f3440e4e301eed49ce5f1d8958` | Reject the whole pack for production adaptation. Its soft glow, blur, swirl, and generic particle language conflict with the one hard-edged EMP requirement. |
| Kenney Sci-Fi RTS | <https://kenney.nl/assets/sci-fi-rts> | `093cb6adbd5aa3ae49da1c91ca3045251656df254c11903b3bfa8594a7a160ea` | Reject the whole pack. Its isometric/pixel treatment and theme-specific terrain/vegetation do not fit the top-down general-SF contract. |

## Findings

### Curated source PNGs

See the combined visual review at
[`previews/curated-external-source-contact-sheet.png`](./previews/curated-external-source-contact-sheet.png).

| Retained source | Size | SHA-256 | Intended adaptation |
| --- | ---: | --- | --- |
| [`laserBlue07.png`](./sources/kenney-space-shooter-remastered/laserBlue07.png) | 9 x 37 | `17385b78342bcf84320e57aa724f026ee436c40bc355a8d90a2d31bac2d7ad0a` | Seed for a light/standard bolt silhouette. Redraw as one flat collision-aligned core plus a restrained non-damaging tail; role and threat tier may not rely on hue alone. |
| [`bolt_gold.png`](./sources/kenney-space-shooter-remastered/bolt_gold.png) | 19 x 30 | `fe54628a1b6530be345b32331dbdde44bbe0b5156619fd2d4be99c996d6a6dd2` | Seed for the shared XP-master silhouette. Redraw as a distinct bright shard and scale it for gameplay values. |
| [`powerupYellow.png`](./sources/kenney-space-shooter-remastered/powerupYellow.png) | 34 x 33 | `2fd263f36f5b2382d47f41fb268faef7adc78fd56e2a7c02f29b6e3559f69e82` | Seed for the reward-crate main mass. Add the Cardborne amber palette, lock seam, and breakable dark contour. |
| [`structure_closed.png`](./sources/kenney-space-kit/structure_closed.png) | 117 x 91 | `6cff893b9cc46f18e0c3411ec47bbaac8cc72e6d284600c73143f4ce3949cfd3` | Seed for the sealed bulkhead mass. Rebuild one footprint-aligned intact/damaged/open family without gradients or orange trim. |
| [`machine_generator.png`](./sources/kenney-space-kit/machine_generator.png) | 68 x 36 | `7ff088dcb6b2f9348026c0b14824e85e5591af716e9c82489a5d2880ecc54755` | Seed for an Arc Surge end pylon. Redraw the pylon and keep the live full-width curtain as a separately aligned dynamic boundary. |
| [`satelliteDish.png`](./sources/kenney-space-kit/satelliteDish.png) | 59 x 56 | `508da1553e12bf4dff312ecda44a657bba3d32921f0016cd9b4bb7fe245f61b0` | Circular recessed-core reference only. Remove the antenna language and rebuild the transit gate as a complete floor portal or the repair pad as a plus-cut surface. |

No source is suitable for direct runtime use. Space Shooter source files are too
small and arcade-cartoon in finish; Space Kit files use a side/isometric model
language. Their value is limited to dominant silhouette and mass proportion.

### Rejected source families

- Reject all Space Shooter UI, player/enemy, meteor, modular-part, and effect
  families. They are pack-specific, glow-heavy, or animation-oriented.
- Reject Space Kit isometric renders and terrain/corridor/monorail/rocket/
  astronaut/alien families. They introduce a fixed camera, incidental lore, or
  excessive architectural breadth.
- Keep no Particle Pack image, including its 512 x 512 ring/twirl masks.
- Import no complete pack into production and preserve no provider logo.

### Project-generated EMP review candidate

[`emp/cardborne-emp-system-pulse-review-only.png`](./emp/cardborne-emp-system-pulse-review-only.png)
is a new, non-derivative project proposal generated without image references.
It is not derived from Kenney Particle Pack.

| Property | Result |
| --- | --- |
| Generation mode | Built-in image generation; new image |
| Final format | 512 x 512 RGBA PNG |
| SHA-256 | `4980808e5e7119e1c72ad31abde8b7e58653874ef39d443bea8fa1e3b68d4fcd` |
| Alpha validation | All four corner alpha values are 0; visible magenta residue is 0 pixels |
| Visible coverage | 40.2695% |
| Alpha bounding box | `(28, 29, 485, 483)` |
| Dominant opaque colors | `#58BFEA`, `#182431`, `#72D6C4` |

Exact generation prompt:

```text
Use case: stylized-concept
Asset type: review-only top-down gameplay EMP effect sprite candidate for Cardborne
Primary request: create one single, large EMP release ring/pulse that reads instantly at gameplay scale.
Scene/backdrop: perfectly flat solid #ff00ff chroma-key background for local background removal. The entire background must be exactly one uniform color with no shadows, gradients, texture, reflections, floor plane, glow spill, or lighting variation.
Subject: one centered top-down circular electromagnetic pulse, occupying about 76% of the square canvas. Build it as one dominant broad hard-edged ring with four large purposeful angular breaks/notches and a restrained inner teal plane that is part of the same ring, not a second ring. Keep the center open.
Style/medium: original flat-color 2D game-effect sprite; familiar general science fiction; clean antialiased hard-edged geometry; friendly industrial volume; matte filled shapes.
Composition/framing: perfectly centered, orthographic top-down, square canvas, generous even padding on all sides, complete silhouette fully inside the canvas.
Color palette: dominant system cyan #58BFEA and support teal #72D6C4, with a deep navy perimeter/separation plane; no amber unless absolutely necessary, and preferably none. Do not use #ff00ff anywhere in the subject.
Constraints: exactly one EMP pulse; strong readable silhouette; only 2-4 large filled color planes; crisp opaque subject edges suitable for chroma-key removal; no text; no letters; no numbers; no watermark; no logo; no cast shadow; no contact shadow; no reflection.
Avoid: tiny particles, sparks, dots, debris, lightning filaments, unnecessary lines, micro-details, greebles, panel seams, repeated lamps, ornamental markings, multiple concentric rings, nested outlines, decorative pulses, radial rays, starburst, gradient, transparency, soft glow, bloom, blur, painterly texture, photorealism, 3D perspective, scene elements.
```

The generated chroma-key source was converted to alpha, repaired with a one-pixel
edge contraction, remapped to exact Cardborne tokens, and downsampled with a
Mitchell filter. It remains review-only until actual-scale gameplay comparison
and an exact TO-BE hash approval are complete.

## Recommendations

- Begin authored production with projectile, XP, crate, bulkhead, and facility
  families that can use the six retained silhouettes as references.
- Use external files as input references, never as a substitute for the final
  top-down role-readable PNG.
- Review the EMP candidate at its real gameplay radius before deciding whether
  to promote its shape into the exact production target.
- Add no more external source files unless a named final asset lacks a usable
  silhouette after this curated set and project-authored design are exhausted.

## Limitations

- The curated PNGs are not high-resolution production masters.
- No external candidate has passed a runtime comparison or switch approval.
- Quaternius and KayKit 3D packs were researched as optional future silhouette
  sources but were not downloaded or imported into this register.
- This register does not authorize production replacement or file retirement.
