---
type: plan
status: done
owner: BK
created: 2026-07-15
scope: Accepted UI art direction, shell backdrop candidates, and panel reference sheets
related:
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../docs/design/PRODUCTION_UI_CONTRACT.md
  - ../../docs/design/references/README.md
---

# UI Shell Art Direction Batch ExecPlan

## Purpose

Turn the owner's accepted UI-art description into a durable visual specification and a reviewable first image batch without connecting any generated bitmap to a Godot scene.

## Why / Context

The first production UI spike proved that the existing SVG panel and button masks can support live state, focus, and responsive layout. It did not provide screen-specific bitmap backdrops, and earlier generation mixed complete-screen mockups, backgrounds, and component art. This batch separates those responsibilities before any runtime adoption.

## Scope / Non-scope

In scope:

- Activate and tighten the existing `UI_VISUAL_SYSTEM.md` art direction.
- Preserve the owner's selected visual reference inside the repository.
- Generate five 16:9 shell backdrop candidates for Main Menu, Settings, Hero Preparation, Forge, and Run Result.
- Generate two panel-family reference sheets for shell/modals and choice/result surfaces.
- Record role, prompt delta, and non-production status for every retained image.

Out of scope:

- Godot scene, script, Theme, import, or runtime asset changes.
- Gameplay-map panoramas, terrain chunks, hazards, actors, icons, or state overlays.
- Treating generated panel sheets as stretchable runtime panels.
- Selecting a final production backdrop before owner review.

## Assumptions

- The owner reference establishes the ancient industrial ruin theme; the written contract deliberately simplifies its texture density.
- UI screen backdrops are fixed-camera 16:9 compositions, not horizontally sequential gameplay panoramas.
- Settings may reuse a quiet shell backdrop when opened outside gameplay, while pause and in-run settings continue to dim the live scene.
- Generated images are project-bound review references and must be copied out of the generator cache.

## Proposed Design

- Generate Main Menu first from the owner reference.
- Use that first candidate as a style anchor for later backdrops so the batch reads as one location family.
- Keep UI occupancy zones low-contrast and reserve detail for perimeter framing or the opposite side of the screen.
- Generate panels as reference sheets only: flat silhouettes, no text, no icons, no baked state, no border ornament.
- Store all sources and candidates under `docs/design/references/ui-shell/` and index them from the existing visual reference registry.

## Tasks

- [x] Update the active UI visual specification and documentation index.
- [x] Preserve the owner reference and create the UI-shell reference manifest.
- [x] Generate and inspect five backdrop candidates.
- [x] Generate and inspect two panel reference sheets.
- [x] Build a contact sheet, validate file dimensions and documentation links, and commit only task-owned files.

## Milestones

1. Direction lock: the active spec defines theme, construction rules, asset roles, and prohibited generation artifacts.
2. Background family: five screen-specific backdrops share palette and shape language while respecting different UI safe zones.
3. Panel family: two sheets clearly remain implementation references rather than baked UI.
4. Evidence gate: files are present, readable, indexed, and explicitly unconnected to runtime.

## Progress

- Existing UI behavior and screen layouts were inspected at the three supported viewport contracts.
- Existing visual and world-component documents were checked to avoid creating a competing source of truth.
- Preserved the owner-selected reference and generated five `1672x941` shell backdrops with distinct UI-safe compositions.
- Generated two empty panel-family sheets and one labeled contact sheet for owner review.
- Verified that no runtime scene, script, art manifest, or project setting references the new candidate directory.

## Next Steps

No task remains in this plan. Owner selection and any later production adaptation are separate decisions.

## Test Plan / Verification

- Inspect every generated file visually for flat-color construction, coherent palette, clean UI-safe space, and prohibited micro-noise.
- Confirm every retained bitmap is 16:9 for backdrops or a clearly labeled reference sheet.
- Confirm no `.tscn`, `.gd`, `.tres`, project setting, import sidecar, or production asset manifest references the candidates.
- Check every Markdown link and image path, run `git diff --check`, and inspect the scoped commit.

## Rollback / Safety

All image and documentation changes are additive or documentation-only. Rollback removes the new reference directory and reverts the specification/index edits; runtime behavior remains untouched.

## Risks

- Generative outputs may reintroduce speckle, tiny repeated marks, or painterly texture despite the prompt; reject or repair rather than rationalize it.
- Referencing the first candidate too strongly may make every screen composition identical; preserve style while changing camera and functional safe zones.
- Panel sheets may look implementation-ready even though they lack exact stretch margins and state behavior; documentation must keep that boundary explicit.

## Open Questions

None blocking. Owner selection among the candidates remains a later review decision.

## Decision Notes

- Extend the existing active visual system instead of creating a competing `DESIGN.md` or UI guideline.
- Keep protected `AGENTS.md` unchanged; the documentation index already routes visual work to the existing design system.
- Separate shell-screen backdrops from sequential gameplay-map panorama production.
- Keep the generated images as unselected reference candidates and avoid Godot import until the owner chooses a direction.
