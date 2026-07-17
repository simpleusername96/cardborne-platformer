---
type: evidence
status: active
owner: BK
created: 2026-07-15
last_reviewed: 2026-07-17
topic: Production raster UI illustration pack and generation provenance
scope: Traveler, active equipment, Spirit Stones, consumable, active cards, Slime King, and large Boss Core reward art
source: Retired content catalogs at Git commit 7cc069c, the active UI visual-system contract, owner-selected lower-ruins references, and built-in image generation
related:
  - ../../UI_VISUAL_SYSTEM.md
  - ../README.md
  - ../../../../art/ui/production/asset-manifest.json
---

# Raster UI Asset Pack V01

## Purpose

Record the first production raster illustrations that carry more internal color,
material, pose, or expressive identity than a monochrome SVG mask should own.
Every file remains an independent neutral-state PNG; selection, rarity, damage,
quantity, cooldown, lock, and disabled states stay in live Godot UI.

## Sources

- `../ui-shell/owner-reference-lower-ruins.png`: world palette and material family.
- `../visual-style-slate-cutout.png`: broad flat-shape and low-noise reference.
- Git commit `7cc069c`: retired catalogs and scenes used to establish the original
  eight equipment, five card, Traveler, and Slime King identities.

## Findings

- The useful immediate raster boundary is 19 assets: one Traveler portrait,
  eight equipment models, two Spirit Stones, one potion, five card vignettes,
  one Slime King portrait, and one large Boss Core reward illustration.
- Panels, buttons, slots, meters, navigation, material/supply counters, role
  glyphs, and the small Boss Core counter stay in the project SVG/Theme system.
- Card art is a transparent borderless vignette, not a baked complete card.
- Gameplay sprites, animation sheets, terrain chunks, hazards, and interactable
  props need a separate raster pipeline with frame, pivot, socket, and collision
  constraints; they are not part of this UI pack.

## Asset Inventory

### Traveler

| Asset ID | Production file | Intended display |
| --- | --- | --- |
| `portrait_traveler` | `illustrations/characters/traveler.png` | 64, 160, or 256 px portrait |

### Equipment

| Asset ID | Production file | Fallback SVG role |
| --- | --- | --- |
| `equipment_traveler_sword` | `illustrations/equipment/traveler_sword.png` | `melee` |
| `equipment_hunting_spear` | `illustrations/equipment/hunting_spear.png` | `melee` |
| `equipment_hunting_bow` | `illustrations/equipment/hunting_bow.png` | `ranged` |
| `equipment_matchlock` | `illustrations/equipment/matchlock.png` | `ranged` |
| `equipment_round_shield` | `illustrations/equipment/round_shield.png` | `shield` |
| `equipment_tower_shield` | `illustrations/equipment/tower_shield.png` | `shield` |
| `equipment_traveler_coat` | `illustrations/equipment/traveler_coat.png` | `armor` |
| `equipment_reinforced_coat` | `illustrations/equipment/reinforced_coat.png` | `armor` |

Equipment sources target 48 px list thumbnails, 128 px preparation previews,
and 192-256 px Forge/detail views from the same file.

### Spirit Stones And Consumable

| Asset ID | Production file | Fallback SVG role |
| --- | --- | --- |
| `spirit_ember` | `illustrations/spirit_stones/ember_spirit_stone.png` | `spirit` |
| `spirit_frost` | `illustrations/spirit_stones/frost_spirit_stone.png` | `spirit` |
| `consumable_small_potion` | `illustrations/consumables/small_potion.png` | `potion` |

### Active Card Vignettes

| Asset ID | Production file | Mechanical identity |
| --- | --- | --- |
| `card_dash_wake` | `illustrations/cards/dash_wake.png` | Forward dash and damaging wake |
| `card_aerial_opener` | `illustrations/cards/aerial_opener.png` | Extra-jump opening strike |
| `card_perfect_punish` | `illustrations/cards/perfect_punish.png` | Strike during enemy recovery |
| `card_second_wind` | `illustrations/cards/second_wind.png` | Clean-room recovery |
| `card_last_stand` | `illustrations/cards/last_stand.png` | One-health survival guard |

These files contain no frame, rarity, title, description, stack count, or state.
They are intended for a live card illustration slot around 96-224 px.

### Boss And Reward

| Asset ID | Production file | Intended display |
| --- | --- | --- |
| `boss_slime_king` | `illustrations/bosses/slime_king.png` | Boss HUD, encounter, or result portrait at 64-256 px |
| `reward_boss_core` | `illustrations/rewards/boss_core.png` | Large reward/result art at 128-256 px |

`icons/icon_boss_core.svg` remains the small 24-64 px semantic counter. The PNG
is a separate detailed reward role, not a replacement for that glyph.

## Shared Prompt Contract

- Use case: `stylized-concept`; one independent game UI illustration per call.
- Style references: owner-selected lower-ruins image, simplified slate-cutout
  image, then the accepted Traveler/equipment output as family anchors.
- Style: outline-free flat/faceted 2D illustration, crisp hard edges, four to six
  major color masses, simple upper-left light plane, minimal internal texture.
- Palette: charcoal and deep navy, restrained verdigris/cyan, warm off-white,
  with one small semantic coral or mustard-amber accent.
- Composition: square, one cohesive subject, central 74-78%, at least 10% clear
  source padding, readable when reduced to 64-96 px.
- Transparent-source backdrop: uniform `#00ff00`; Slime King and Boss Core use
  `#ff00ff` to avoid removing their green hues.
- Avoid: outlines, pointillism, speckles, hatching, stains, cracks, brush noise,
  tiny repeated motifs, photorealism, text, logos, watermarks, frames, scenery,
  cast shadows, and baked UI state.

Subject prompts were the exact active content names plus their source-backed
silhouette: straight sword, leaf-head spear, compact recurve bow, matchlock,
round shield, tower shield, light coat, reinforced coat, ember/frost relic,
small potion, five mechanics-specific action vignettes, crown-wearing green
Slime King, and a broken-ring Boss Core relic.

## Generation Record

- Generator: built-in image generation; one call per distinct asset.
- Traveler source: `exec-272031b5-b9cf-4592-b9ec-48eb0a583e19.png`.
- Equipment sources: `exec-e98027b4-47bc-409e-810c-28db72e00f29.png`,
  `exec-b94f5a7b-a011-4bf8-9926-501080655fb3.png`,
  `exec-3615f7e0-5a51-474d-b5b3-4e693c66952b.png`,
  `exec-d7ab94f9-03dc-4922-88df-3f265c59bdd8.png`,
  `exec-70bc9595-5599-4518-8ce7-a8a104465190.png`,
  `exec-a46cc492-68ea-4ad7-b25b-106059cb46c7.png`,
  `exec-2a8384a5-955b-4102-bfb3-07b9a530d76e.png`, and
  `exec-2cc298b6-2a9e-4cec-ac09-4e859c46c6c9.png`.
- Stone/potion sources: `exec-423443c2-15d3-4543-b440-b40de7dde11b.png`,
  `exec-b69e0989-64c4-40f6-905e-885a8f03236e.png`, and
  `exec-4be61467-64cd-4826-b138-8407170d1a69.png`.
- Card sources: `exec-fee3f7b5-06d8-435a-a2f3-0bdfe2cb53d5.png`,
  `exec-2abe0fcc-019f-434e-bf25-b1c91dd848b4.png`,
  `exec-01ed1edd-5129-44a6-b31f-3288c7917844.png`,
  `exec-a17fae55-e12b-4f75-926c-1e1e202dfe60.png`, and
  `exec-437cc662-0e06-41c2-93cd-413457050c2b.png`.
- Boss/reward sources: `exec-e2e12331-2d39-4834-9a71-0a9cede18a0b.png`
  and `exec-8130430b-fd6b-4452-b484-a7215e3af008.png`.

## Post-processing And Validation

- Chroma removal used the installed imagegen helper with border auto-sampling,
  soft matte, despill, transparent threshold `32`, and opaque threshold `160`.
- Production files were resized to `512x512` RGBA PNG and fully transparent
  pixels were normalized to black RGB to prevent filtered color bleed.
- Automated alpha validation checked dimensions, RGBA mode, transparent
  corners, subject bounds, coverage, and saturated key-color residue: `19/19`.
- `docs/design/reports/ui-raster-asset-catalog.png` shows every asset on a
  checkerboard plus a 64 px sample; no visible crop or chroma halo remains.

## Limitations

- These assets are retained production candidates with no current runtime screen;
  adoption belongs to the isometric pivot rather than the retired layouts.
- A later native-art pass may simplify individual facets further without
  changing IDs, display contracts, or fallbacks.
- Frame-consistent actor animation and seamless world art require dedicated
  pipelines rather than independent UI-illustration generation.
