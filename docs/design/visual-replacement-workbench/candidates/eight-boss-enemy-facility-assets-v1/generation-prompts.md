---
type: evidence
status: active
owner: BK
created: 2026-08-15
last_reviewed: 2026-08-15
topic: Exact ImageGen prompt construction for the eight-boss visual candidate batch
scope: Nine initial generation prompts and two boss revision prompts
source: Built-in ImageGen calls from the 2026-08-15 candidate session
related:
  - ./README.md
---

# Generation Prompt Record

## Purpose

Record the prompt set used to generate the review candidates. Each initial prompt is the
listed asset-specific prefix followed verbatim by its family common block. Revision
prompts are recorded in full.

## Sources

- Every call received
  `docs/design/cardborne-universal-art-style-reference.png` through
  `image_gen.referenced_image_paths`.
- The canonical style sheet supplied style grammar only. `VISUAL_SYSTEM.md` supplied the
  binding media, plane-count, silhouette, facing, detail, and approval constraints.

## Findings

### Ordinary-enemy common block

```text
Input images: Image 1 supplies Cardborne style grammar only. Do not reproduce any depicted object, silhouette, module, text, or layout. VISUAL_SYSTEM.md is binding.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background, absolutely uniform with no shadow, gradient, texture, floor, reflection, or glow spill.
Style/medium: original flat-color 2D gameplay sprite, orthographic top-down, antialiased hard-edged geometry, matte friendly industrial general-SF.
Composition/framing: one centered actor facing +X/right, square canvas, full silhouette inside generous even padding, no perspective.
Color palette: danger red #F05A5F dominant, cool neutral dark-gray secondary plane, near-black perimeter/separation, at most one restrained warm-off-white live highlight. Never use #00ff00 in the actor.
Constraints: exactly 3-5 broad filled planes inside one dark outer contour; maximum two large functional modules; clear front/rear cut; readable at 48-world-unit radius and in grayscale; crisp opaque edge for chroma-key removal; no text, logo, watermark, cast/contact shadow, reflection.
Avoid: tiny circles, micro-panels, seams, rivets, repeated lamps, concentric rings, nested outlines, random greebles, gradients, glossy 3D, glow, bloom, particles, projectiles, UI, scene elements, copying the reference.
```

The four prefixes were:

```text
Use case: stylized-concept
Asset type: review-only top-down ordinary enemy actor candidate for Cardborne, Beam Ordinary Enemy Lv.1
Primary request: one lean Beam Ordinary Enemy Lv.1 that relocates before firing. Use a long single forward rail spine as the dominant silhouette and one compact rear drive mass. The exact thin-line shot is code-owned and must not appear. The vehicle must look mobile rather than like a fixed turret.

Use case: stylized-concept
Asset type: review-only top-down ordinary enemy actor candidate for Cardborne, Range Ordinary Enemy Lv.1
Primary request: one agile Range Ordinary Enemy Lv.1 that moves tangentially around the player. Use a strongly swept crescent-like side profile with one obvious inward-facing three-shot muzzle cluster represented as one broad module, not three tiny barrels. Preserve a clear +X nose and negative side cut.

Use case: stylized-concept
Asset type: review-only top-down ordinary enemy actor candidate for Cardborne, Sweep Ordinary Enemy Lv.1
Primary request: one fast Sweep Ordinary Enemy Lv.1 that commits to a straight pass and leaves delayed ground blasts. Use a long narrow forward-swept body, one broad ventral bomb-bay cut visible from top-down, and compact rear propulsion. No bombs or explosions outside the body.

Use case: stylized-concept
Asset type: review-only top-down ordinary enemy actor candidate for Cardborne, Melee Ordinary Enemy Lv.2
Primary request: one aggressive Melee Ordinary Enemy Lv.2 that grows stronger when nearby ordinary enemies die. Use a compact predatory collector body with one large open forward intake/jaw-shaped negative space and one heavy rear compression module. It must still read as an attacker at zero stacks. Stack accents are code-owned and must not be baked into the base image.
```

### Stage 7 Boss and Stage 8 Boss common block

```text
Input images: Image 1 supplies Cardborne style grammar only. Do not reproduce any depicted object, silhouette, module, text, or layout. VISUAL_SYSTEM.md is binding.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background, absolutely uniform with no shadow, gradient, texture, floor, reflection, or glow spill.
Style/medium: original flat-color authored 2D gameplay boss sprite, orthographic top-down, antialiased hard-edged geometry, matte friendly industrial general-SF.
Composition/framing: one centered massive vehicle facing +X/right, square canvas, full silhouette inside generous even padding, no perspective.
Color palette: boss-command magenta #D43F8D dominant, cool neutral dark-gray mechanical planes, near-black perimeter/separation, one restrained warm-off-white live highlight. Never use #00ff00 in the boss.
Constraints: exactly 4-6 very broad filled planes inside one dark outer contour; maximum two large functional modules; strong front/rear cut; silhouette readable at 146-world-unit radius and in grayscale; crisp opaque edges for chroma-key removal; no text, logo, watermark, cast/contact shadow, reflection.
Avoid: copying the reference boss, tiny circles, micro-panels, seams, rivets, repeated lamps, concentric rings, nested outlines, random greebles, many small barrels, gradients, glossy 3D, glow, bloom, particles, projectiles, beams, UI, scene elements.
```

The two prefixes were:

```text
Use case: stylized-concept
Asset type: review-only top-down boss actor candidate for Cardborne, Stage 7 Boss
Primary request: one original boss that projects translating parallel and orthogonal laser walls. Express this with exactly two huge perpendicular emitter rails integrated into the body: one long fore-aft mass and one broad crosswise mass, creating a clear offset cross silhouette with large open corner cuts. The moving laser walls are code-owned and must not appear. No shield.

Use case: stylized-concept
Asset type: review-only top-down boss actor candidate for Cardborne, Stage 8 Boss
Primary request: one original final boss that emits expanding and contracting pulse fronts with a missing wedge. Use one heavy faceted central power mass that is NOT a ring, plus one unmistakable open wedge-shaped cut on the forward-right side and two broad opposing stabilizer fins. The pulse rings and spiral projectiles are code-owned and must not appear. No shield.
```

### Facility common block

```text
Input images: Image 1 supplies Cardborne style grammar only. Do not reproduce any depicted object, silhouette, module, symbol, text, or layout. VISUAL_SYSTEM.md is binding.
Scene/backdrop: perfectly flat solid #ff00ff chroma-key background, absolutely uniform with no shadow, gradient, texture, floor, reflection, or glow spill.
Style/medium: original flat-color authored 2D gameplay facility sprite, orthographic top-down, antialiased hard-edged geometry, matte friendly industrial general-SF.
Composition/framing: one centered stationary facility, square canvas, full silhouette inside generous even padding, no perspective.
Color palette: cool neutral-gray main structure, near-black perimeter/separation, support mint #72D6C4 as one large functional plane, restrained warm-off-white highlight. Never use #ff00ff in the facility.
Constraints: exactly 3-5 broad filled planes inside one dark outer contour; one dominant function silhouette and at most one secondary module; readable in grayscale at installation scale; crisp opaque edge for chroma-key removal; no text, logo, watermark, cast/contact shadow, reflection.
Avoid: copying the reference facility, floor tile, enclosing range ring, shield bubble, effect radius, plus-sign UI icon, tiny circles, micro-panels, seams, rivets, repeated lamps, concentric rings, nested outlines, random greebles, gradients, glossy 3D, glow, bloom, particles, UI, scene elements.
```

The two prefixes were:

```text
Use case: stylized-concept
Asset type: review-only top-down neutral facility candidate for Cardborne, Repair Beacon
Primary request: one large neutral repair facility that heals any player or enemy inside its code-owned range. Use a broad four-lobed mechanical body with one open cross-cut negative space through the center and one solid mint service core; make the repair meaning structural, not a plus-sign icon. No cables or beam.

Use case: stylized-concept
Asset type: review-only top-down neutral facility candidate for Cardborne, Barrier Projector
Primary request: one large neutral barrier facility that grants shield to any player or enemy inside its code-owned range. Use a squat diamond-cut projector body with two broad opposing protective vanes and one central mint emitter slab. It must not be circular and must not contain a shield bubble or ring.
```

### Stage 6 Boss v1

The standalone Stage 6 Boss prompt used the same authority, orthographic, chroma,
palette, and prohibition clauses, with this exact subject contract:

```text
Use case: stylized-concept
Asset type: review-only transparent top-down boss actor candidate for Cardborne, Stage 6 Boss
Primary request: create one original massive mobile sustained-fire boss whose identity is alternating left and right sustained projectile banks.
Subject: one centered orthographic top-down industrial general-SF vehicle, facing +X/right. A broad central armored mass with exactly two unmistakable large side firing banks, one on each side, arranged so alternating salvos read immediately. Strong front/rear cut and asymmetric forward weight, but balanced footprint. No shield apparatus.
Constraints: exactly 4-6 broad filled planes plus one dark outer contour; maximum two functional modules; silhouette readable at 146-world-unit presentation radius and in grayscale; crisp opaque edges for chroma-key removal; no text, logo, watermark, cast/contact shadow, reflection.
Avoid: copying the reference boss, tank treads, naval or cultural motifs, turrets made of tiny barrels, micro-panels, seams, rivets, repeated lamps, tiny circles, concentric rings, nested outlines, greebles, gradients, bevel-heavy 3D render, glossy metal, glow, bloom, smoke, projectiles, UI, scene elements.
```

### Boss revision prompts

Stage 6 Boss v2 used Image 1 as the v1 edit target and Image 2 as the canonical style
sheet. It requested one rectangular bank per side and five broad planes. The result lost
the sustained-firing identity and is retained under `revisions/` as rejected evidence.

Stage 7 Boss v2 used Image 1 as the v1 edit target and Image 2 as the canonical style
sheet with this exact change request:

```text
Primary request: keep Image 1's two perpendicular emitter rails but make it clearly face +X/right. Shorten the left arm, extend and taper the right arm into a broad forward head, add one large open notch on the right/front edge, and make the rear/left edge blunt. Remove the central ring-like octagon and replace it with one solid offset rectangular core. Reduce the body to exactly five broad planes.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background, uniform with no shadow, gradient, texture, floor, reflection, or glow spill.
Constraints: orthographic top-down; one boss; 4-6 broad filled planes, one dark outer contour, exactly two integrated perpendicular rail masses; no shield; no beams; no text, logo, watermark. Do not use #00ff00 in the subject.
Avoid: four-way perfect symmetry, central rings, tiny panels, seams, rivets, repeated lamps, nested outlines, greebles, gradients, glossy 3D, glow, projectiles, UI.
```

The final selected Stage 6 Boss v3, Beam Ordinary Enemy Lv.1 v2, Sweep Ordinary Enemy Lv.1 v2, and
Melee Ordinary Enemy Lv.2 v2 used their v1 alpha masters as Image 1 and the canonical style sheet
as Image 2. Each exact primary request below was followed by this shared suffix:

```text
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background, uniform with no shadow, gradient, texture, floor, reflection, or glow spill. Preserve orthographic top-down +X/right facing, Cardborne matte hard-edged style, semantic palette, one dark outer contour, no text/logo/watermark. Image 2 supplies style grammar only; copy none of its objects or layout. Avoid micro-panels, rivets, repeated lamps, tiny circles, concentric rings, nested outlines, greebles, gradients, glossy 3D, glow, projectiles, UI.
```

Their exact primary requests were:

```text
Stage 6 Boss v3: simplify Image 1 but preserve the broad vehicle footprint, pointed right/front nose, blunt rear, and two alternating upper/lower side firing banks. Replace each three-thin-barrel cluster with one broad armored bank containing exactly two large rectangular muzzle channels cut into one mass. Merge the center octagon and small plates into one large central dark armor plane. Use 4-6 broad planes total and exactly two obvious side-bank modules; the sustained-fire identity must remain stronger than an empty armor-panel identity.

Beam Ordinary Enemy Lv.1 v2: preserve Image 1's rail-sniper identity but shorten the forward rail to about 55% of the total length, double the width of the rear drive/body, and widen the rail spine into one broad solid mass. Keep one single rail and one rear drive module, 3-5 broad planes, and at least about 30% opaque canvas coverage. It must remain mobile rather than a fixed turret.

Sweep Ordinary Enemy Lv.1 v2: preserve Image 1's fast long body and right-facing nose. Replace the four repeated dark bomb-bay cells with one single uninterrupted broad dark bomb-bay plane. Slightly broaden the body and simplify the rear into one propulsion mass. Use only 3-5 broad planes and no external bombs or explosions.

Melee Ordinary Enemy Lv.2 v2: preserve Image 1's large open forward collector jaw and aggressive right-facing C silhouette. Merge all rear blocks into one heavy rectangular compression mass and merge the upper/lower jaw tips into two clean broad planes. Use 3-5 broad planes total. Do not bake stack marks, corpses, debris, or pickup objects into the base image.
```

## Limitations

- Prompt compliance is judged from the resulting raster, not from the requested wording.
  The README records visible deviations.
- The prompt record does not grant asset approval or production authority.
