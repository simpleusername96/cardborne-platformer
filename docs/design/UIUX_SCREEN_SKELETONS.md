---
type: spec
status: active
canonical_for: first-slice UI/UX skeleton screens
source: User request on 2026-07-01
scope: Preimplementation screen composition and image-generation constraints
---

# UI/UX Screen Skeletons

## Purpose

Lock the first-slice screen composition before asking image models or artists to polish the visuals. The skeleton data is the target; generated art should follow it instead of inventing new UI structures.

## Scope

This spec covers the first UI/UX skeleton set:

- Start page.
- Settings popup.
- Character select.
- Normal stage HUD.
- Card reward screen.
- Rest and shop map.
- Shop and equipment popup.
- Boss stage HUD.

## Requirements

- Store screen composition in `data/design/first_slice/ui_screen_skeletons.json`.
- Generate wireframe SVGs with `tools/generate_uiux_wireframes.py`.
- Treat generated SVGs under `docs/uiux/generated/` as the authoritative visual skeleton until Godot UI scenes exist.
- Use the wireframes as composition references for AI-generated images, hand-drawn concept art, or later Godot `Control` scene work.
- Do not add UI panels, currencies, classes, buttons, or progression systems in generated images unless they already exist in the skeleton data or active first-slice specs.
- Keep gameplay HUD compact enough that enemy, hazard, and boss telegraph readability remains the priority.
- Keep shop and equipment interactions in a safe rest/shop state for the first implementation.

## Image Generation Contract

When generating polished images from these skeletons:

1. Start from the matching SVG skeleton.
2. Preserve screen identity, panel count, and UI hierarchy.
3. Preserve required gameplay readability:
   - player health,
   - XP/level,
   - coins/materials,
   - card choices,
   - shop/equipment cost preview,
   - boss HP and warning zones.
4. Reject images that move critical HUD into gameplay space or add unsupported systems.
5. Save accepted bitmap concepts into a project-local asset folder instead of referencing only a tool temp path.

## Acceptance Criteria

- `python tools/generate_uiux_wireframes.py` produces one SVG per screen plus an overview SVG.
- Each generated screen fits a 1280x720 canvas.
- Each screen has a clear flow state and purpose.
- Later Godot UI implementation can map each skeleton to a scene or modal.

## Related

- `data/design/first_slice/ui_screen_skeletons.json`
- `docs/uiux/generated/uiux_index.md`
- `docs/design/MAP_DATA_AND_VISUALIZATION.md`
- `docs/product/FIRST_SLICE_EXPANSION.md`
