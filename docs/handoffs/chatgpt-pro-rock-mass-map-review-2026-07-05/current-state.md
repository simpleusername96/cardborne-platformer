---
type: handoff
status: active
created: 2026-07-05
source: User request to create a ChatGPT Pro handoff folder after rock-mass map refinement
topic: chatgpt-pro-rock-mass-map-review
scope: Current project state for external map review
related:
  - ../../design/testbed-plan/07_rock_mass_generated_routes.md
  - ../../../scripts/stages/MotionTestStage.gd
---

# Current State

## User Intent

The user wants the map to use filled rock-like terrain masses at varied heights, with guaranteed player movement space between terrain shapes, while still preserving deterministic random generation. The map should not read as thin floating platforms.

## Current Behavior

The playable boot path is still `MotionTestStage`. The first refinement pass changed the current testbed route so the main surfaces render as filled rock masses with rough top lips and strata lines. Thin platforms remain only for special traversal pieces such as one-way platforms and crumbling platforms.

The generated route still uses a hard-coded list of segment anchors with seeded jitter. It now validates more than distance: surface count, minimum landing width, link gaps, step-ups, and duplicate generated surfaces. This is still not full pathfinding or simulated traversal validation.

## Mismatch Still To Resolve

- Generated route assembly is not yet template/resource based.
- Validation does not yet prove full spawn-to-exit traversal through actual collision and player movement.
- The default narrow viewport HUD covers much of the map; this was observed but not fixed in the map pass.
- The current route still lives in `MotionTestStage.gd`; production `Stage01` split remains future work.

## Relevant Flow

```text
seed / replay / random input
  -> MotionTestStage._build_generated_route()
  -> route surfaces and actors instantiated under GeneratedRoot
  -> _validate_generated_route()
  -> route_summary and HUD status
  -> generated exit clear gate
```

## Completed Work

- `21c4291 Add rock-mass route generation plan`
- `67e4b91 Refine testbed map rock-mass terrain`

The first pass:

- added rock-mass helpers to `MotionTestStage.gd`;
- converted many runtime surfaces to filled rock-mass visuals;
- removed duplicate generated-start collision and replaced it with a visual socket;
- added missing `lower_corridor` and `exit` room metadata;
- moved unsupported map-data markers onto supporting terrain;
- regenerated map preview SVG/PNG files;
- updated `07_rock_mass_generated_routes.md` progress.

## Validation Baseline

Commands run successfully before this handoff:

- `git diff --check`
- map JSON validation for rectangular rows, known symbols, spawn/exit counts, and support rules
- runtime critical-path room ID check
- `.\tools\godot.ps1 --path . --headless --import`
- `.\tools\godot.ps1 --path . --headless --quit-after 2`
- `.\tools\godot.ps1 --path . --script res://tools/capture_ui_screenshots.gd`

Visual observation:

- desktop screenshot shows filled rock-mass terrain in the starting route;
- narrow screenshot shows the existing HUD obscures much of the world.

## Open Questions

- Should the next change focus on generated route templates, full traversal validation, or splitting `Stage01` out of `MotionTestStage`?
- How much of the rock-mass shape should become reusable builder code now versus waiting for the map pipeline/importer work?
- What is the smallest validation improvement that catches real impossible generated maps without overbuilding a full simulation?

