---
type: evidence
status: active
owner: BK
created: 2026-08-09
last_reviewed: 2026-08-12
source: Current Cardborne production capture geometry at 655e0ee2 plus three independent built-in ImageGen edits grounded by the canonical visual authority pair
topic: HUD progression-density alternatives before user selection
related:
  - ../../../VISUAL_SYSTEM.md
  - ../../../../../docs/reports/2026-08-08-combat-pressure-and-surface-depth.md
  - ../progression-feedback-combat-readability-v1/README.md
---

# HUD Progression Density Alternatives

## Purpose

These three independent mockups test ways to remove top-center HUD crowding and stop repeated or
shared upgrade artwork from pretending to identify individual mechanics. They are comparison
evidence only. No direction is selected, approved for runtime, or added to the active execution
contract until the user chooses or requests a revision.

## Sources

- Edit target: the Korean 1280×720 production combat capture referenced by this candidate set.
  Korean `1280x720` production capture.
- Problem reference:
  `../progression-feedback-combat-readability-v1/gameplay-hud-minimap-to-be.png`.
- Text authority: `docs/design/VISUAL_SYSTEM.md`, read completely on 2026-08-09.
- Canonical style reference supplied as an actual reference to every generation:
  `docs/design/cardborne-universal-art-style-reference.png`.
- Expected and observed canonical SHA-256:
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- Reference input method: `image_gen.referenced_image_paths`; each call received the edit target,
  the prior crowded mockup as problem evidence, and the canonical sheet as style grammar only.
- No SVG or ImageMagick geometry was used. ImageMagick was not used to author or repair any image.

## Findings

| Display order | Image | Information model | Main trade-off | SHA-256 |
| ---: | --- | --- | --- | --- |
| 1 | `hud-combat-essential-to-be.png` | Top center keeps hull, XP, selected element, and equipped optional secondary only. Passive upgrades move to acquisition receipts and paused Ship Status. | Lowest combat-time density and clearest mechanic identity, but passive build state is not continuously visible. | `1a0f11936deb24c37f476c4bf171cc6eb062f5f1de30227fa26c4ef60b7b64e3` |
| 2 | `hud-category-summary-to-be.png` | One aggregate group each for primary, secondary, chassis, and element; each shows owned mechanic count and summed level. | Preserves broad build growth in the center, but remains the tallest and busiest top-center direction. | `a416ef1ce7ce7f54a8e7aa84c30b17060bf97b858da9e13d534cbf61bd7138ce` |
| 3 | `hud-side-build-summary-to-be.png` | Top center keeps hull and XP only; one extended minimap Surface owns a four-row category summary. | Gives the cleanest center and most persistent text identity, but consumes more right-side world visibility. | `f759b532e532c914b0e941278451831731a66528aaac7b03214cc2f9f6332582` |

The core issue is informational, not cosmetic. A live receipt cannot show up to 18 separate
upgrades clearly when some mechanics share artwork and the player has no reason to decode every
passive during active combat. The alternatives therefore change what the HUD summarizes instead
of making the existing icon strip smaller.

## Recommendations

- Prefer the combat-essential direction as the default starting point. Selected element and
  equipped optional secondary can change moment-to-moment combat reading; passive numeric upgrades
  can remain in the paused Ship Status and appear briefly when acquired.
- If persistent build growth is a product requirement, prefer category compression over restoring
  individual icons. A single category glyph is honest when it represents an aggregate.
- Treat the side summary as an accessibility or optional expanded-HUD direction only if runtime
  capture proves that the larger minimap Surface does not hide important right-side combat.
- After selection, update the active execution contract and `VISUAL_SYSTEM.md` together before any
  runtime HUD implementation. Do not combine all three directions.

## Limitations

- ImageGen produced `1672x941` review images from the `1280x720` source aspect. Runtime geometry
  still requires `960x540`, `1280x720`, `1920x1080`, Korean/English, and 200% text validation.
- ImageGen reinterpreted some semantic artwork. The two combat-essential images do not approve new
  Thermal, Electric Field, primary, secondary, chassis, or category assets. Runtime must reuse the
  existing semantic artwork and code-native UI owners unless a separate asset workbench unit is
  approved.
- The displayed counts and levels are layout data, not a new gameplay rule. Their exact owner and
  aggregation contract must be locked only after a direction is selected.
- The prior active visual spec still defines an acquired-only icon rail and no XP rail. These
  mockups are explicit alternatives prompted by user feedback; they do not silently supersede the
  spec or active plan.
