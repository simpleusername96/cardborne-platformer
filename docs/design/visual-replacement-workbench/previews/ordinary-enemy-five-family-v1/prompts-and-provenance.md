---
type: evidence
status: active
owner: BK
created: 2026-08-20
last_reviewed: 2026-08-20
topic: Ordinary-enemy five-family visual candidates
scope: Generated master sheets, normalized actor crops, trait-state comparisons, and provenance before runtime integration
source: ../../../../../.agents/execplans/2026-08-20-ordinary-enemy-family-and-pack-restructure.md
related:
  - ../../../VISUAL_SYSTEM.md
  - ../../../cardborne-universal-art-style-reference.png
  - ../../README.md
---

# Ordinary Enemy Five-Family Visual Candidate Evidence

## Purpose

Record how the pre-integration ordinary-enemy visual candidates were generated and derived.
This evidence is consult-only. It does not approve the candidates or change production,
runtime, collision, gameplay, or workbench switch state.

## Sources

- Plan gate: commit `43fb8c55`,
  `.agents/execplans/2026-08-20-ordinary-enemy-family-and-pack-restructure.md`.
- Visual specification: `docs/design/VISUAL_SYSTEM.md`, SHA-256
  `2e5cf7e3f156629bcbe956da0e6cb30f6d3b608d9c20122ec5285fa1562aa006`.
- Canonical style sheet:
  `docs/design/cardborne-universal-art-style-reference.png`, SHA-256
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- Generation method: built-in `image_gen` with the canonical sheet supplied through
  `referenced_image_paths` on every generation call.
- The report-only family lineup was not supplied to ImageGen. It did not act as a style or
  edit target.

## Findings

- Five 3×3 masters were generated: columns T1/T2/T3; rows base/trait A/trait B.
- ImageGen returned baked white or checkerboard RGB backgrounds. The raw outputs are kept
  in `source/`. A non-creative ImageMagick flood-fill converted only the connected light
  background to alpha; no vehicle body was repainted.
- Each 418×418 grid cell was cropped, reduced to its largest connected actor body,
  normalized to a centered 256×256 transparent canvas, and stored under `assets/`.
- The final staged set contains exactly 45 PNGs. Each file is 256×256, has a transparent
  corner, contains one connected visible body, and has a non-empty alpha footprint.
- The normalized PNGs do not encode tier size. The comparison sheets render the three
  columns at exact 100%, 125%, and 150% scale.
- Trait hints are body-owned: Splitter cleft, Frenzy blades, Double prongs,
  Self-Destruct core, Artillery breech, Slow fork/chamber, Bulwark shoulders, Reflector
  plate, Blink slit, and Pack-Feed branching plate.
- No production visual, semantic manifest, runtime provider, collision value, enemy code,
  or current `ordinary_enemy_family` workbench unit changed.

## Generation Prompts

### Pursuer generation

```text
Use case: stylized-concept
Asset type: Cardborne production-candidate top-down enemy sprite board
Primary request: create one strict 3 by 3 sprite board for the PURSUER ordinary-enemy family. Exactly nine isolated vehicle bodies, centered in nine equal invisible cells. Columns are T1, T2, T3. Rows are Base, Splitter trait, Frenzy trait. Do not render any text, numbers, labels, grid lines, borders, or cell backgrounds.

Input images:
Image 1 is Cardborne's mandatory style-grammar reference only. Follow its shape grammar, surface treatment, palette roles, top-down camera, and readability rules. Do not reproduce any object, example enemy, sheet layout, text, or decorative composition from Image 1.

Family identity:
All nine are compact aggressive pursuit drones, exact top-down orthographic view, facing right. The shared family silhouette is a low wedge with a broad rear drive mass and a sharply readable forward nose. They must look like one family, not nine unrelated vehicles.
T1/T2/T3 are three authored body designs with progressively heavier mass and at most one larger functional module. Keep every source sprite in the same normalized bounding-box size and pivot; do not make later tiers physically larger on this board because runtime will apply 100%, 125%, and 150% scale later.

Trait rows:
Base row: no trait cue.
Splitter row: preserve each tier body but add one deep, broad forward cleft that visibly divides the nose into two large lobes. No duplicate vehicle, offspring, icon, or floating effect.
Frenzy row: preserve each tier body but add exactly two long swept side blades as a permanent silhouette cue. No aura, speed lines, glow, or floating effect.

Style and materials:
Familiar industrial science-fiction vehicle language. One dominant silhouette, three to five large filled planes, dark perimeter, matte charcoal main mass, one light plane, one shadow plane, and danger-coral hostile armor in one coherent region. At most two large functional modules. Restrained highlights only. Strong silhouette and negative space must remain readable in grayscale and at small combat scale.

Composition:
Genuinely transparent background with preserved alpha. Equal generous transparent padding in every cell. All complete bodies visible; identical right-facing direction; consistent top-down lighting. No cast shadow outside the body footprint.

Avoid:
No perspective or three-quarter view. No white or colored backdrop. No decorative rivets, tiny circles, repeated lamps, random seams, concentric rings, nested frames, badges, symbols, UI, projectiles, trails, explosions, shield rings, bloom, text, watermark, or logos.
```

### Pursuer transparency edit

```text
Use case: precise-object-edit
Asset type: Cardborne transparent enemy sprite board
Input images:
Image 1 is the edit target: the generated PURSUER 3 by 3 sprite board.
Image 2 is the mandatory Cardborne style-grammar reference only; it is not an edit target and must not be reproduced.

Primary request:
Remove the entire gray-and-white checkerboard from Image 1 and replace every background pixel outside the nine vehicle bodies with genuine alpha transparency. Preserve all nine vehicle bodies exactly: same geometry, colors, surfaces, cell positions, scale, top-down camera, right-facing direction, padding, and 3 by 3 layout.

Hard constraints:
The delivered PNG must contain a real alpha channel. Fully transparent background means alpha 0, not a simulated checkerboard and not white, gray, or colored pixels. Keep opaque body interiors opaque and keep clean anti-aliased alpha only on body edges. Do not redraw, add, remove, move, crop, recolor, relight, or restyle any body. No grid lines, shadows, labels, text, effects, watermark, or new objects.
```

### Charger generation

```text
Use case: stylized-concept
Asset type: Cardborne production-candidate top-down enemy sprite board
Primary request: create one strict 3 by 3 sprite board for the CHARGER ordinary-enemy family. Exactly nine isolated vehicle bodies in nine equal invisible cells. Columns are T1, T2, T3. Rows are Base, Double trait, Self-Destruct trait. No text, numbers, labels, dividers, borders, or cell backgrounds.

Input images:
Image 1 is Cardborne's mandatory style-grammar reference only. Follow its shape grammar, surface treatment, palette roles, top-down camera, and small-scale readability. Do not reproduce any example object, object layout, text, or decorative composition from Image 1.

Family identity:
All nine are compact ramming vehicles in exact top-down orthographic view, facing right. The family silhouette is a dense rear drive mass leading into one broad armored wedge nose. It must read as a direct lane attack, not as a gunner or defender.
T1/T2/T3 are three authored bodies with progressively heavier mass and at most one larger functional plate. Keep all source sprites in the same normalized bounding-box size and centered pivot; runtime applies 100%, 125%, and 150% size later.

Trait rows:
Base: one solid wedge nose, no trait cue.
Double: preserve each tier but add exactly two parallel forward charge prongs with one large clean gap. No second vehicle or motion effect.
Self-Destruct: preserve each tier but expose one large central danger-coral core held by exactly two broad dark shutters. The core is a flat body plane, not a glowing orb, badge, countdown, or blast effect.

Style:
Familiar industrial science-fiction. One dominant silhouette, three to five large filled planes, dark perimeter, matte charcoal main mass, one light plane, one shadow plane, and one coherent danger-coral hostile armor region. At most two large functional modules. Strong grayscale-readable shape and negative space.

Composition:
Genuinely transparent PNG background with alpha 0 outside bodies; do not simulate transparency with a checkerboard. Equal transparent padding; complete bodies; consistent lighting; no cast shadow outside body footprint.

Avoid:
No perspective, white backdrop, checkerboard, decorative rivets, tiny circles, repeated lamps, random seams, concentric rings, nested frames, badges, symbols, UI, projectiles, charge lane, explosion, halo, bloom, text, logo, or watermark.
```

### Gunner generation

```text
Use case: stylized-concept
Asset type: Cardborne production-candidate top-down enemy sprite board
Primary request: create one strict 3 by 3 sprite board for the GUNNER ordinary-enemy family. Exactly nine isolated vehicle bodies in nine equal invisible cells. Columns are T1, T2, T3. Rows are Base, Artillery trait, Slow trait. No text, numbers, labels, dividers, borders, or cell backgrounds.

Input images:
Image 1 is Cardborne's mandatory style-grammar reference only. Follow its shape grammar, surface treatment, palette roles, top-down camera, and small-scale readability. Do not reproduce any example object, object layout, text, or decorative composition from Image 1.

Family identity:
All nine are top-down right-facing mobile ranged vehicles. The shared silhouette has one compact rear body and one clearly readable forward weapon axis. It must read as ranged fire, not a charging wedge. T1/T2/T3 are three authored bodies with progressively heavier breech mass and at most one larger functional plate. Keep all source sprites in the same normalized bounding-box size and centered pivot; runtime applies 100%, 125%, and 150% size later.

Trait rows:
Base: one medium direct-fire barrel with a simple rectangular muzzle, no trait cue.
Artillery: replace that barrel with one short wide mortar-like barrel and one enlarged breech. No shell, trajectory, impact marker, or area effect.
Slow: preserve the ranged body but use one broad forked muzzle and exactly one cyan chamber plane within the body. Shape, not cyan alone, must identify the trait. No projectile or trail.

Style:
Familiar industrial science-fiction. One dominant silhouette, three to five large filled planes, dark perimeter, matte charcoal main mass, one light plane, one shadow plane, and one coherent danger-coral hostile armor region. Cyan is allowed only on the Slow chamber. At most two large functional modules. Strong grayscale-readable silhouette and negative space.

Composition:
Genuinely transparent PNG background with alpha 0 outside bodies; do not simulate transparency with a checkerboard. Equal transparent padding; complete bodies; exact top-down orthographic view; all face right; consistent lighting; no cast shadow outside the body.

Avoid:
No perspective, white backdrop, checkerboard, decorative rivets, tiny circles, repeated lamps, random seams, concentric rings, nested frames, badges, symbols, UI, bullets, trails, impact zones, glow, text, logo, or watermark.
```

### Defender generation

```text
Use case: stylized-concept
Asset type: Cardborne production-candidate top-down enemy sprite board
Primary request: create one strict 3 by 3 sprite board for the DEFENDER ordinary-enemy family. Exactly nine isolated vehicle bodies in nine equal invisible cells. Columns are T1, T2, T3. Rows are Base, Bulwark trait, Reflector trait. No text, numbers, labels, dividers, borders, or cell backgrounds.

Input images:
Image 1 is Cardborne's mandatory style-grammar reference only. Follow its shape grammar, surface treatment, palette roles, exact top-down camera, and small-scale readability. Do not reproduce any example object, object layout, text, or decorative composition from Image 1.

Family identity:
All nine are slow right-facing defensive vehicles. The shared silhouette is a compact rear body joined to one broad, solid frontal shield slab on the right. The shield mass must dominate and must not look like a gun barrel or charging prongs. T1/T2/T3 are three authored bodies with progressively heavier shield mass and at most one larger functional plate. Keep all source sprites in the same normalized bounding-box size and centered pivot; runtime applies 100%, 125%, and 150% size later.

Trait rows:
Base: one broad normal front shield slab, no trait cue.
Bulwark: preserve each tier and add exactly two large folded outer shield shoulders around the broad front plate. They are closed body modules, not an active shield ring or aura.
Reflector: preserve the normal shield but add one large angular mirror-like inset across its front face. Use one restrained pale-cyan or live-highlight plane plus a strongly cut angular shape, so color is not the only cue. No reflected projectile or beam.

Style:
Familiar industrial science-fiction. One dominant silhouette, three to five large filled planes, dark perimeter, matte charcoal main mass, one light plane, one shadow plane, one coherent danger-coral hostile armor region. At most two large functional modules. Strong grayscale-readable silhouette and negative space.

Composition:
Genuinely transparent PNG background with alpha 0 outside bodies; do not simulate transparency with a checkerboard. Equal transparent padding; complete bodies; exact top-down orthographic view; all face right; consistent lighting; no cast shadow beyond the body.

Avoid:
No perspective, white backdrop, checkerboard, decorative rivets, tiny circles, repeated lamps, random seams, concentric rings, nested frames, badges, UI, shield halo, radius circle, beam, projectile, glow, text, logo, or watermark.
```

### Coordinator generation

```text
Use case: stylized-concept
Asset type: Cardborne production-candidate top-down enemy sprite board
Primary request: create one strict 3 by 3 sprite board for the COORDINATOR ordinary-enemy family. Exactly nine isolated vehicle bodies in nine equal invisible cells. Columns are T1, T2, T3. Rows are Base, Blink trait, Pack-Feed trait. No text, numbers, labels, dividers, borders, or cell backgrounds.

Input images:
Image 1 is Cardborne's mandatory style-grammar reference only. Follow its shape grammar, surface treatment, palette roles, exact top-down camera, and small-scale readability. Do not reproduce any example object, object layout, text, or decorative composition from Image 1.

Family identity:
Make this the simplest family. Each body is one compact round or softly octagonal command puck with one broad right-facing nose cut and no arms, legs, antennae, turret, barrel, radial pods, or repeated lamps. It should be visibly simpler than Pursuer, Charger, Gunner, and Defender. T1/T2/T3 are three authored pucks with progressively heavier central mass and at most one larger functional plate. Never use concentric rings. Keep all source sprites in the same normalized bounding-box size and centered pivot; runtime applies 100%, 125%, and 150% size later.

Trait rows:
Base: plain command puck with one large danger-coral plate and one broad right-facing nose cut. No trait cue.
Blink: preserve each tier but add one large offset cut through one side of the round body and exactly one transverse cyan slit inside the body. No afterimage, duplicate body, teleport ring, spark, or trail.
Pack-Feed: preserve each tier but add one thick Y-shaped receiver plate as a single large inset inside the body. It must have broad arms and no small endpoint nodes, orbs, lamps, arrows, icons, or surrounding units. Use shape, not color alone.

Style:
Familiar industrial science-fiction. One dominant compact silhouette, three to five large filled planes, dark perimeter, matte charcoal main mass, one light plane, one shadow plane, one coherent danger-coral hostile armor region. Cyan is allowed only as the restrained Blink slit. Strong grayscale readability.

Composition:
Genuinely transparent PNG background with alpha 0 outside bodies; do not simulate transparency with a checkerboard. Equal transparent padding; complete bodies; exact top-down orthographic view; all face right; consistent lighting; no cast shadow beyond the body.

Avoid:
No perspective, white backdrop, checkerboard, decorative rivets, tiny circles, repeated lights, radial modules, concentric rings, random seams, nested frames, badges, symbols, UI, pack members, healing particles, halo, glow, text, logo, or watermark.
```

## Output Hashes

### Raw generated sources

| File | SHA-256 |
| --- | --- |
| `source/charger-master-rgb.png` | `ec59b26897ede61f29957c8974d4391834b01fd8c849bcb58f377ac4b299399c` |
| `source/coordinator-master-rgb.png` | `82e86840ed51afff9e9076a1143bc8b5ff9ee5eb913e3392a83455108dc698fd` |
| `source/defender-master-rgb.png` | `cf646ea87f13745bed49cc408e550204bc5fda417a68f4112507a2692023270a` |
| `source/gunner-master-rgb.png` | `9ed134ed130f91c4e5c2df5022131f6959954c27bb26bb2a9b582513d754c349` |
| `source/pursuer-master-rgb.png` | `65d4fbda888d77341ebd346e99332ac155756eac614e745a74e52cc90a836b45` |

### Alpha master sheets

| File | SHA-256 |
| --- | --- |
| `master-sheets/charger-master.png` | `d85001323b4eb851f1da39a900efb901784b15b08d7cd11a1db03d2e84188c67` |
| `master-sheets/coordinator-master.png` | `0e44e195c34fcf7e002c334b6f47206be512ad5d7c5c5df105e861545b782193` |
| `master-sheets/defender-master.png` | `e787343ce29ec2e8eaf447f3d9f1dc812f2bd111380f6cba78d402e556f5a444` |
| `master-sheets/gunner-master.png` | `e41e53cfcaa252f7dc0e592338b4aca91f96778971a85a1605b96959674cdb4d` |
| `master-sheets/pursuer-master.png` | `7e50e7f34e16140bd2eb3f8a9c92f49ac76a5ec1ecc7136999147addc9a67df4` |

### Review comparisons

| File | SHA-256 |
| --- | --- |
| `comparisons/all-families-color.png` | `94409a1605562c2cea582a90b04f4386d5460de58e7cb5d1efb286d6f9e03014` |
| `comparisons/all-families-grayscale.png` | `504d958bc5b69a34cfbea94d24202c8a0267f8e303765c4587841be212161a0e` |
| `comparisons/charger-comparison.png` | `2aac92cda0c4d2b2f088a9e00dbfeb372faf5e2038139b9befc3633df068248e` |
| `comparisons/coordinator-comparison.png` | `46531f8d8dd965d40d5effdd66722474f73160b418cd10356c2cc79509e65b0e` |
| `comparisons/defender-comparison.png` | `bfcc4af9052b9b446c92ae0fc46ef14c617dddcb828661840802c692a50a8b73` |
| `comparisons/gunner-comparison.png` | `78a327b3d2e81b292617ddbfca142d4d8bb588982e26c39b2bf5528e0c5a90bd` |
| `comparisons/pursuer-comparison.png` | `ab30d2c0c92e74cdd9efa6d09ceac017402e196a9167653a24c5fef0b858c78b` |

All 45 normalized actor hashes are recorded in `asset-hashes.sha256`.

## Verification

- Staged counts: 5 raw sources, 5 alpha masters, 45 normalized actors, 5 family
  comparisons, and 2 overview comparisons.
- Every normalized actor is 256×256, has a transparent corner, has a non-empty alpha
  footprint, and resolves to one connected visible body after thresholding.
- Every entry in `asset-hashes.sha256` matches its current file.
- `.\tools\validation\validate_cardborne_visual_authority.ps1` passed.
- `.\tools\validation\validate_visual_replacement_workbench.ps1` passed.
- No report test, Godot import, gameplay test, Web export, or runtime smoke was run.

## Recommendations

- Review the five family comparison sheets and approve or reject each family explicitly.
- If a family is rejected, regenerate only that family sheet and preserve the accepted
  family hashes.
- After all five families are approved and stable semantic IDs exist, create a new exact
  workbench switch unit. Do not overwrite the already-applied 19-ID unit.
- Implement timed shield, blast, impact, blink, and projectile geometry as retained
  code-native presentation tied to gameplay truth, not as additional actor rasters.

## Limitations

- These files have not been imported into Godot or viewed in live combat because the user
  required visual creation before project changes.
- The 100/125/150 comparisons are non-creative review composites. Runtime scale, collision,
  projectile hit radius, and health-bar placement remain unimplemented.
- The candidates remain review-only until the user approves them and a later workbench
  unit records exact production paths and technical acceptance.
