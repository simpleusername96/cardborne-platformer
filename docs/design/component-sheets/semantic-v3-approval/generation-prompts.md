---
type: evidence
status: draft
created: 2026-07-31
topic: Cardborne semantic-v3 candidate generation prompts
scope: Review-only player foundation candidates
source: ./candidate-manifest.json
related:
  - ./README.md
---

# Player foundation candidate prompts

## Purpose

Preserve the exact generation inputs for the first review-only approval unit.
All three calls used the built-in ImageGen path and
`../00-general-sf-component-master-v1.png` as the sole image reference.

## Sources

- `../00-general-sf-component-master-v1.png`
- `candidate-manifest.json`

## Findings

### 1. Flat silhouette

```text
Use case: stylized-concept
Asset type: review-only modular top-down player vehicle component sheet for a Godot action game
Input images: Image 1 is the sole style and form-language reference. Match its closest approved flat-color general-SF treatment and role-readable silhouette language, but do not reproduce its sheet layout, labels, backdrop, or enemy designs.
Primary request: Create one landscape 1536×1024 image containing exactly three isolated modular player assets, arranged left-to-right in this exact order: (1) player hull, (2) rigid rear twin-nozzle engine module, (3) manual-aim mount. All three assets point toward +X / screen-right.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for local background removal. One uniform color only, with no shadows, gradients, texture, reflections, floor plane, vignette, or lighting variation.
Subject details:
1. Player hull only: a readable non-circular top-down spacecraft/vehicle body, gold main mass, dark navy secondary plane, cyan functional accent, near-black contour, clear pointed front cut on the right and clear rear connection cut on the left; no engine module and no aim mount attached.
2. Rigid rear twin-nozzle engine module only: a compact solid mechanical module viewed from directly above, two clearly separated rear exhaust nozzles at the left and a clean rigid connector/front cut at the right; no flame plume and no hull attached.
3. Manual-aim mount only: a compact directional top-down weapon/aim mount with a short forward barrel or aiming nose pointing right, clear rear/forward cuts, no hull or engine attached.
Style/medium: clean flat vector-like 2D game-sprite concept; familiar general science fiction; antialiased hard edges; crisp readable silhouettes; 3–4 filled planes per asset.
Color palette: gold main mass, dark navy secondary plane, cyan functional accent, near-black contour. No green anywhere in the subjects.
Composition/framing: orthographic top-down view with no perspective; three assets fully visible, isolated, non-overlapping, and separated by generous green gaps; balanced landscape spacing and generous outer padding; no assembly preview or additional objects.
Constraints: exactly three assets and nothing else; all face right; clear front/rear distinction; flat fills only; preserve strong silhouette readability at small game scale.
Avoid: any text, labels, letters, numbers, logos, watermark, border, panel frames, assembly preview, extra parts, photoreal materials, gradients, glow, shadows, reflections, pixel art, tiny greebles, circular hull, named cultural/marine/ritual theme.
```

### 2. Restrained modular layering

```text
Use case: stylized-concept
Asset type: review-only 2D game component sheet for later alpha extraction
Input images: Image 1 is the ONLY style and visual-family reference. Generate a new image; do not reproduce its UI, labels, panels, or full sheet.
Canvas: landscape 1536 × 1024 pixels.
Scene/backdrop: a perfectly flat, solid, uniform #00ff00 chroma-key background filling the entire canvas edge to edge. No floor plane, no shadows, no gradients, no texture, no lighting variation, no reflections.
Primary request: show exactly three isolated, unassembled player-vehicle assets, arranged left-to-right in one horizontal row with generous padding and clearly separate silhouettes: (1) player hull, (2) rigid rear twin-nozzle engine module, (3) manual-aim mount. Every asset points toward +X / screen-right. Use a strict orthographic top-down 2D game-asset view.
Asset 1 — player hull: a strong non-circular right-facing wedge/arrow spacecraft hull silhouette. One large gold primary mass. Dark navy structural spine or inset. One lighter mechanical plane. One small cyan functional slit. Near-black contour. It must read immediately as the player hull, not as a complete assembled ship.
Asset 2 — engine module: separate rigid rear propulsion module with two clearly readable nozzles at its left/rear end and its connection/front facing right. It shares exactly the hull's +X/right orientation and visual language. It must look solid and rigid, never hinged, articulated, wing-like, or curved like a joint.
Asset 3 — manual-aim mount: a separate narrow right-facing rail/barrel or compact aiming mount, long axis horizontal, unmistakably slimmer than the hull and engine. It must not be attached to either other asset.
Style/medium: preserve the approved familiar general-SF family from Image 1: clean flat-color modular geometry, role-readable silhouette, restrained layered construction, antialiased hard edges, no perspective and no 3D rendering. At most five filled color planes per asset: one large gold mass, dark navy structure, one lighter mechanical plane, one cyan functional slit/accent, and near-black contour. Keep cyan sparse and functional.
Composition/framing: exactly three subjects only; left hull, center engine, right aim mount; all fully visible; no overlap; no touching; ample green separation between them and from every canvas edge. No assembly preview and no additional parts, projectiles, exhaust flames, icons, or decorative objects.
Constraints: the subjects contain absolutely no #00ff00 or green hues. Crisp clean silhouettes suitable for chroma removal. Flat solid fills only.
Avoid: text, labels, numbers, logos, watermark, UI frames, diagrams, arrows, assembly preview, photoreal materials, glow, bloom, shadows, highlights that imply 3D lighting, gradients, texture, pixel art, micro-greebles, circular hull, green within any subject, extra objects.
```

### 3. Outline first

```text
Use case: stylized-concept
Asset type: review-only top-down 2D game component sheet candidate
Input image: Image 1 is the sole approved style-family reference. Preserve its familiar general-SF, flat-color, role-readable visual language; do not reproduce its sheet layout, labels, frames, or any other assets.
Canvas: landscape 1536 × 1024 pixels.
Backdrop: one perfectly flat, uniform solid #00ff00 chroma-key field covering the entire canvas, with no gradient, texture, lighting variation, floor, border, shadow, reflection, or vignette.
Primary request: create exactly three and only three isolated opaque player-foundation assets, arranged left-to-right in one centered horizontal row with generous clear separation and padding: (1) player hull, (2) rigid rear twin-nozzle engine module, (3) manual-aim mount. No assembled-vehicle preview and no extra parts.
Orientation: every asset has its front/forward direction unmistakably pointing +X/right. The hull's nose points right. The engine module is a compact rigid unit with its two exhaust nozzles at the trailing left and its attachment/front direction to the right; it must read as one non-articulating, non-hinged block. The manual-aim mount is an unmistakably separate slim rail-and-barrel weapon pointing right.
View and style: orthographic top-down game art, bold flat vector-like raster shapes, antialiased hard edges. Optimize for instant crowded-combat readability using the strongest authored near-black outer contour, bold negative-space cuts, a simple gold main mass, dark navy underside, and sparse cyan functional accents. Use only 3–4 large internal planes per asset. Preserve familiar general-SF forms without introducing a named material, cultural, marine, or ritual theme.
Hull: assertive elongated directional silhouette, clearly non-circular, with a strong right-facing nose and readable cutouts; no mounted weapon and no engine attached.
Engine: compact rigid rear module, visibly twin-nozzle, strong single silhouette, no visual hinge, joint, arm, swivel, or articulation.
Aim mount: distinct detached right-facing manual-aim rail/barrel with a clear base and long directional barrel; no hull or engine attached.
Constraints: exactly three subjects total; each fully isolated from the others and fully inside the canvas; no overlap; no green anywhere in any subject; clean opaque interiors suitable for chroma removal.
Avoid: text, labels, letters, numbers, logos, watermark, UI panels, dividers, assembly diagram, assembly preview, arrows, photoreal materials, glow, bloom, lighting, shading gradients, cast shadow, contact shadow, reflection, pixel art, tiny greebles, excessive internal detail, circular hull, soft painterly edges, additional objects.
```

## Limitations

- These are review sheets, not production canvas/pivot crops.
- The selected candidate still requires deterministic split, scale, alpha-edge,
  pivot, and live-size validation before it can become a runtime asset.
