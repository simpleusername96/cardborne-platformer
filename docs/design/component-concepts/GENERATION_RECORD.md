---
type: evidence
status: active
owner: BK
created: 2026-07-29
last_reviewed: 2026-07-29
scope: Reproducibility and visual-QA record for the six Cardborne combat component concept sheets
related:
  - ./README.md
  - ../../../.agents/execplans/2026-07-29-combat-visual-enemy-boss-rework.md
---

# Component Concept Sheet Generation Record

## Purpose

This record preserves the source, exact final prompt set, bounded correction
history, deterministic title treatment, file hashes, and known limitations for
the six pre-implementation concept sheets.

These images are review input. They are not runtime geometry, collision truth,
or the deterministic approval sheets required by Phase 1 of the active
ExecPlan.

## Sources

- User feedback recorded on 2026-07-29.
- `docs/design/UI_VISUAL_SYSTEM.md`
- `docs/product/vehicle_game_spec.md`
- `.agents/execplans/2026-07-29-combat-visual-enemy-boss-rework.md`
- Creative Production board
  `2373df2f-585d-4f82-9d3f-7f3524b3df9d`
- Built-in image generation, followed only by deterministic title-band
  composition with ImageMagick 7.1.1 and the project font
  `NotoSansKR-Variable.ttf` registered as `Noto-Sans-KR`

## Findings

| Output | Final size | SHA-256 | Corrective generations |
| --- | --- | --- | ---: |
| `01-player-components.png` | 1536×1136 | `acf62103d58afad396fb73ed9f95ed571e85e3a49188e0ecfcfcd153976e22e8` | 0 |
| `02-mobile-enemy-roles.png` | 1536×1136 | `55aa6a54f02b26b5f95a90ac316d57a021879e7f5c5d3b6d1bf996a63136ff08` | 0 |
| `03-structures-objectives.png` | 1536×1136 | `660ed6b3188b6fb9fc65594fcda2f9b53917a04e764edbba29cdc1346c796c5d` | 1 |
| `04-rewards-projectiles.png` | 1536×1136 | `dbd2fe29a13d477b63b78c602be84d288e5f1256551ce6e7c5efe37fab62673f` | 1 |
| `05-boss-components.png` | 1536×1136 | `6bfb5fdb328d15b04efb402cb26448e93b8072b6fd4a6da0d0091d29799c1269` | 1 |
| `06-upgrade-glyphs.png` | 1536×1136 | `afd20ae8911179808a8a447d5c7167442b0658d7511818b19e3e8cac53bd3ad7` | 0 |

The visible 112-pixel title band was added after generation. Each band uses
solid cobalt `#042B7B`, ivory `#FFF6DC` at 38 pt, mint `#75C4B2` at
22 pt, centered `Noto-Sans-KR`, and no modification to the generated artwork.
All six board placeholders were completed against the listed repository files;
the final board revision is `8`.

Color and grayscale inspection confirmed the intended high-level silhouette
separation for player states, the 12 mobile roles, repair versus recall,
projectile heads versus direction tails, the five bosses, and the six upgrade
families. This is a qualitative concept check, not the Phase 1 gameplay-scale
or collision-overlay acceptance test.

## Exact Final Prompts

### 01 Player Components

```text
Use case: stylized-concept
Asset type: orthographic top-down vehicle-game component concept sheet, landscape 3:2
Primary request: Create one coherent family of isolated player-craft components and assembled states for Cardborne “Sunken Ceramic Components.”
Scene/backdrop: clean deep-cobalt neutral artboard, arranged as an orderly grid of separate visual cells with generous padding; every component fully inside the canvas.
Subject: a broad mustard wedge hull with a clear front notch and wide rear shoulders; a thin independent aim barrel/turret; rigid rear engine sockets; assembled hull states with zero, one, two, and three installed engine modules; an idle short rear flame; a thrust elongated rear flame; a dash state expressed only through five aligned hull afterimages plus one rear flare; a hit state shown as a coral hull flash; arrival/transit protection shown as four mint corner brackets; a barrier shown as one clean mint ring. Make it unmistakable that every engine remains physically attached behind the hull and rotates with the hull, while the barrel aims independently.
Style/medium: completely non-pixel, antialiased, flat vector-like shapes, matte ceramic inlay feel, large geometric masses, strong negative space, no micro-detail, no gradients, no perspective, no photorealism. Each ordinary component uses at most three large filled masses and two accents.
Color palette: cobalt #0739A6 and #042B7B, ivory #F3E8C9 and #FFF6DC, ceramic green #07564C, mustard player/reward #D79A17, coral hostile #C92F4E, mint support #75C4B2, ink #153B3A.
Composition/framing: orthographic top-down only, crisp isolated components, consistent scale and orientation, balanced landscape 3:2 sheet, generous safe margins.
Text: none.
Constraints: purely visual unlabeled component board; all requested states visible and fully contained; every role/state distinguished by silhouette as well as color.
Avoid: any text, letters, numbers, labels, captions, logos, watermark, UI chrome, readable typography, pixel stair steps, dithering, generic neon sci-fi, cockpit detail, red or coral dash circle, radial dash burst, detached or bent engine, sideways exhaust, shadows, gradients, perspective, tiny ornaments.
```

### 02 Mobile Enemy Roles

```text
Use case: stylized-concept
Asset type: orthographic top-down enemy-role component concept sheet, landscape 3:2
Primary request: Create a coherent family of twelve isolated, equally scaled mobile enemy silhouettes for Cardborne “Sunken Ceramic Components.”
Scene/backdrop: clean ivory neutral artboard, arranged as an orderly grid of twelve separate visual cells with generous padding; every enemy fully inside the canvas.
Subject: exactly twelve distinct roles, one silhouette per cell: a scrap drone as a small chevron-teardrop; a needle drone as a narrow needle; a chaser with a deep forward spear notch; a shooter as a wide bracket with a central muzzle gap; a controller as a split twin-prong with a small magenta command crown; a shield escort as a flat forward slab with a mint plate; an artillery spotter as a long rail body; a rammer as a thick arrowhead with a coral leading edge; a bulkhead guard as a square heavy guard; a splitter barge as a broad body visibly divided into two lobes; a repair tender as a mint crescent cradle with link arms; a drone carrier as a larger rear-bay silhouette.
Style/medium: completely non-pixel, antialiased, flat vector-like shapes, matte ceramic inlay feel, large geometric masses, strong negative space, no micro-detail, no gradients, no perspective, no photorealism. Each ordinary enemy uses at most three large filled masses and two accents.
Color palette: hostile bases in coral #C92F4E, ink #153B3A, and ivory #F3E8C9/#FFF6DC; support accents in mint #75C4B2; command accents in magenta #962754; restrained cobalt #0739A6/#042B7B and ceramic green #07564C where useful.
Composition/framing: orthographic top-down only, consistent scale and forward orientation, balanced four-column by three-row landscape grid, generous safe margins, clear grayscale-distinct negative-space silhouettes.
Text: none.
Constraints: exactly twelve isolated enemy bodies; purely visual unlabeled component board; all requested roles visible and fully contained; every role differs by silhouette as well as color; hostile roles share a coherent family without becoming repeated recolors.
Avoid: any text, letters, numbers, labels, captions, logos, watermark, UI chrome, readable typography, circles or donuts as primary bodies, repeated recolors, humanoids, wings, tiny ornaments, health bars, attack effects, projectiles, shadows, gradients, pixel stair steps, dithering, generic neon sci-fi, perspective, photorealism.
```

### 03 Structures and Objectives

```text
Use case: stylized-concept
Asset type: corrected stationary-threat and objective component concept sheet for Cardborne
Input image: edit target and strict inventory/layout reference. Preserve every component family and every state shown; do not omit, duplicate, merge, reorder, relabel, crop, or replace any design.
Primary request: Restyle the entire reference sheet into an absolutely flat orthographic top-down vector screenprint. Preserve its same clean three-row grid and exact component/state coverage, but remove every trace of faux depth. The result must look as if exported directly from simple SVG paths with all effects disabled.
Exact inventory to preserve: top row—grounded square-base turret with narrow barrel; four-point pressure mine with armed center; split-fork interceptor tower with catch gap; long-slit beam sentinel on heavy base; hexagonal barrier generator with two shield fins; keyed boss pylon. Middle row—destructible plate intact, cracked, broken; relay idle, positive-cut, negative-cut, overloaded/fractured. Bottom row—switch node left-committed and right-committed using directional negative space; outer core locked, open, broken.
Scene/backdrop: one perfectly uniform solid cobalt #0739A6 background covering the entire artboard, with no texture, vignette, border, lighting, shadow, floor, or tonal variation.
Style/medium: pure two-dimensional vector screenprint; solid fills only; hard clean geometric boundaries; completely non-pixel and antialiased; strong negative space; each component uses no more than two or three nested color masses; shapes carry role and state more strongly than decoration.
Composition/framing: landscape 3:2; strict orthographic top-down; orderly isolated cells; generous even padding; nothing cropped; no perspective; no three-dimensional extrusion; no cell borders or UI chrome.
Color palette: cobalt background #0739A6. Components use only flat cream #F3E8C9/#FFF6DC, mustard #D79A17, mint #75C4B2, coral #C92F4E, ceramic green #07564C, and dark ink #153B3A as needed for role coding. Every region is one uniform unchanging solid color.
Lighting: none. This is not an illuminated scene. No highlights, shadows, reflections, ambient occlusion, bevel shading, rim light, volume, or material response.
Text: none—no text, letters, numbers, captions, labels, logos, watermark, readable typography, or UI.
Constraints: preserve all eighteen visible component/state instances from the reference; maintain clear silhouettes and state differences; all designs remain isolated and legible at small game scale; flat cobalt negative space must separate every cell.
Avoid: bevels; chamfers; gradients; highlight strips; color ramps; light-to-dark modeling; cast shadows; contact shadows; drop shadows; inner shadows; glow; faux depth; extrusion; perspective; isometric view; 3D rendering; ceramic shine; thick dimensional outlines; micro-detail; decorative rings; pixel art; dithering; texture; text; labels; missing states; duplicated states. Do not merely reduce the bevel—remove all depth and lighting completely.
```

### 04 Rewards and Projectiles

```text
Use case: stylized-concept
Asset type: top-down reward, pickup, projectile, and telegraph component concept sheet for the Cardborne game
Primary request: Regenerate as a completely non-pixel, antialiased landscape 3:2 component design sheet with absolutely no text. Use exactly three organized horizontal bands and do not duplicate any component.
Top reward band, exactly six cells from left to right: (1) repair pickup as a mint ceramic cross shard; (2) experience-recall pickup as exactly three cobalt-and-mint inward-pointing chevrons, clearly different from repair even in grayscale; (3) small experience as one simple mustard-and-ivory diamond shard; (4) medium experience as a moderately layered mustard-and-ivory diamond shard; (5) large experience as the most complex mustard-and-ivory diamond shard; (6) field crate as a low ceramic-green chest with one mustard seam.
Middle projectile band, exactly seven cells from left to right: (1) PLAYER PROJECTILE, unmistakably mustard-colored ownership shell around a small opaque dark-ink collision core, followed by a short clean pale-mustard tail; (2) hostile kinetic, coral blunt hexagonal head; (3) hostile thermal, orange ember-wedge head; (4) hostile toxin, olive droplet head; (5) hostile cryo, cobalt-blue shard head; (6) hostile arc, violet zig-bolt head; (7) hostile hybrid, bright ivory diamond head. Do not repeat this row. Every projectile must point right. For all six hostile projectiles, the compact opaque damaging head must visibly end at collision size, followed by a longer lighter translucent-looking directional tail that is clearly non-damaging. The player projectile tail is short.
Bottom telegraph band, exactly four small secondary samples from left to right: one straight directional lane; one wedge warning; one narrow beam corridor; one area warning formed as an interrupted outer boundary around a solid center. These four samples must be sparse and visually subordinate to the rewards and projectiles.
Scene/backdrop: clean warm neutral ivory artboard, no floor scenery, no environment, no cast shadows, every component isolated and evenly spaced, nothing cropped
Style/medium: Cardborne “Sunken Ceramic Components”; flat vector-like matte ceramic inlays; simple crisp silhouettes; large geometric masses; strong negative space; max three large masses and two accents for ordinary components; scalable game-asset concept design; no pixel styling
Composition/framing: landscape 3:2, orthographic top-down only, orderly grid-like spacing without borders, labels, or UI frames; generous margins; no overlap; exact inventory of six reward cells, seven unique projectile cells, and four subordinate telegraph cells
Color palette: cobalt #0739A6 and #042B7B, ivory #F3E8C9 and #FFF6DC, ceramic green #07564C, mustard #D79A17, coral #C92F4E, magenta #962754, mint #75C4B2, ink #153B3A, restrained orange for thermal, olive for toxin, cobalt-blue for cryo, violet for arc; shape and color both communicate role
Materials/textures: matte ceramic inlay, extremely restrained shallow seams only, no micro-detail
Text: none—no text, letters, numbers, labels, captions, logos, watermark, UI chrome, or readable typography anywhere
Constraints: include every requested item exactly once; player projectile must be the first cell of the projectile band and visibly mustard, not coral or orange; small/medium/large experience clearly progress in complexity; repair and recall remain distinct in grayscale; antialiased clean edges; flat colors; visual clarity at small gameplay scale
Avoid: duplicated projectile rows or repeated components; omission of the player projectile; round pickup medallions; decorative rings around rewards; particle noise; gradients; glow; perspective; 3D camera; photorealism; generic neon sci-fi; dithering; pixel art; pixel steps; labels; UI frames; cropped assets; touching artboard edges; elaborate background; hostile tails that look as solid or dangerous as the damaging head
```

### 05 Boss Components

```text
Use case: stylized-concept
Asset type: top-down five-boss modular silhouette concept sheet for the Cardborne game
Primary request: Create a much simpler, truly flat concept sheet with exactly five large isolated top-down bosses and exactly one small adjacent broken/open-state sample for each boss. The five large designs, all equal visual scale, are: (1) Foundry Colossus, broad forge body, two huge front plates, small central hot core; (2) Archive Leviathan, long asymmetric body, head notch, two side segment locks, one clearly exposed vulnerable side; (3) Drydock Titan, heavy square body, two separate relay slabs, one with a plus-shaped negative-space cut and one with a minus-shaped negative-space cut; (4) Switchyard Behemoth, long armored body, detachable rear armor car, two large side route-switch nodes; (5) Crown Engine, compact radial crown silhouette, not a ring or donut, with two outer cores, exactly three short lattice arms, and a solid central core.
Scene/backdrop: perfectly clean uniform warm-ivory neutral artboard; no texture, shadows, scenery, frames, dividers, headings, or captions
Style/medium: Cardborne “Sunken Ceramic Components”; non-pixel antialiased flat vector-like matte ceramic inlays. Use only 3–5 large filled geometric pieces for each main boss and 1–3 pieces for each state sample. Strong negative space and instantly readable silhouettes. Absolutely no bevels, highlights, gradients, internal panel seams, surface scratches, outlines made of many nested bands, micro-detail, perspective, or 3D rendering.
Composition/framing: landscape 3:2, tidy two-row sheet, exactly five main bosses, generous padding, nothing cropped; each boss has only one small nearby broken/open state sample; all five main silhouettes unmistakably different in grayscale
Color palette: flat solid fills only: cobalt #0739A6/#042B7B, ivory #F3E8C9/#FFF6DC, ceramic green #07564C, mustard #D79A17, coral #C92F4E, boss magenta #962754, mint #75C4B2, ink #153B3A. Main boss bodies use magenta, ink, and ivory; each has one restrained stage-affinity accent. Targetable modules use a contrasting shape and color.
Text: none
Constraints: exactly five large bosses and exactly five small state samples total; modules visibly detachable or destructible; no text, letters, numbers, labels, logos, watermarks, readable typography, health bars, attack effects, card chrome, or UI mockups
Avoid: recolors of one silhouette, circular blobs, donuts, humanoids, faces, legs, wings, tiny greebles, scenery, neon glow, gradients, shading, cast shadows, textured paper, pixel steps, dithering, photorealism
```

### 06 Upgrade Glyphs

```text
Use case: stylized-concept
Asset type: scalable flat game-UI glyph concept sheet for Cardborne upgrades
Primary request: Create a clean glyph sheet with exactly six coherent isolated upgrade-family glyphs and simple visual state-treatment samples for each family. The six family glyphs are: (1) primary weapon — a forward barrel shape joined to an impact wedge; (2) element — a six-facet solid core with one changing geometric inner cut; (3) passive — an offset diamond seeker plus one short orbit arc; (4) mobility — two rear-facing thruster chevrons; (5) defense — a broad angular shield slab, explicitly not circular; (6) utility — two inward-facing pickup or magnet brackets. Each glyph must remain recognizable at 24, 32, and 42 pixel display sizes and use only one or two large filled shapes with strong negative space.
Scene/backdrop: clean uniform neutral warm-ivory artboard, no texture, scenery, labels, headings, frames, card backgrounds, badges, or dividers
Style/medium: Cardborne “Sunken Ceramic Components”; completely non-pixel, antialiased, perfectly flat vector-like matte ceramic inlay glyphs; bold, minimal, geometric; no micro-detail, no fine lines, no dithering or pixel steps
Composition/framing: landscape 3:2; six orderly isolated family groups with generous padding, nothing cropped. In every group, show the same base glyph in exactly four compact state treatments arranged consistently: default using ivory and ink; focused using the same glyph plus one thin ivory side rail; selected using the same glyph plus one small mustard corner diamond; unavailable as a low-contrast solid silhouette. Keep the glyph, side rail, and corner diamond visually separate. No card mockups.
Color palette: cobalt #0739A6/#042B7B, ivory #F3E8C9/#FFF6DC, ceramic green #07564C, mustard #D79A17, coral #C92F4E, magenta #962754, mint #75C4B2, ink #153B3A. Use mustard for player progression, mint for support, and other affinity colors only as small inner accents.
Materials/textures: flat solid matte ceramic fills only, no gradients or shading
Text: none
Constraints: exactly six family glyph groups; exactly four state-treatment examples per group; every symbol fully visible; one or two filled shapes per base glyph; no text, letters, numbers, labels, logos, watermarks, readable typography, circular badges, pills, card chrome, mockup cards, fine decoration, drop shadows, bevels, perspective, photorealism, or neon glow
Avoid: generic icons, detailed illustrations, circular shield, detailed weapon, repeated family glyphs, UI cards, text-like marks, gradients, texture, tiny ornament
```

## Limitations

- The generated art is intentionally non-authoritative. Small asymmetries,
  spacing drift, and ornamental details must not become runtime requirements.
- `03-structures-objectives.png` retains faint cobalt tonal falloff, and
  `04-rewards-projectiles.png` retains slight shallow dimensional treatment.
  Both are acceptable only as concept-review artifacts. Runtime components
  must use the flat-color contract from the active ExecPlan.
- The sheets have not been tested at actual gameplay scale, with collision
  overlays, at maximum hostile density, or inside the 960×540 upgrade modal.
- The image generator cannot guarantee deterministic redraws. The Phase 1
  runtime descriptor and generated sheet fingerprints remain the reproducible
  source of truth.

## Recommendations

1. Review the Korean mapping and acceptance order in `README.md`.
2. Approve the silhouette/state direction or request one bounded correction
   inside the locked grammar.
3. Translate only approved shapes into runtime descriptors.
4. Run Phase 1 color, grayscale, 1× scale, collision-overlay, and
   maximum-pressure acceptance before runtime publication.
