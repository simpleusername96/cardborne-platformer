---
type: handoff
status: active
created: 2026-07-05
source: User request to create a ChatGPT Pro handoff folder after rock-mass map refinement
topic: chatgpt-pro-rock-mass-map-review
scope: Copyable prompt for ChatGPT Pro
related:
  - ./README.md
  - ./current-state.md
  - ./source-map.md
  - ./constraints-and-decisions.md
---

# External Model Prompt

I am asking you to review a local Godot project. Your role is to give design and implementation feedback, not to be the source of truth.

Project/repo:

- Remote: `https://github.com/simpleusername96/cardborne-platformer.git`
- Branch: `master`
- Code baseline commit to review: `67e4b9145070e110317b2ee2b8a2cd684e6a5626`
- Handoff docs: `docs/handoffs/chatgpt-pro-rock-mass-map-review-2026-07-05/`

Goal:

Review the current testbed map after the first rock-mass terrain refinement pass. The user wants filled rock-like terrain masses at varied heights, guaranteed player movement space between terrain shapes, and deterministic constrained random generation. The map should not read as thin floating platforms.

Please review these files in order:

1. `docs/handoffs/chatgpt-pro-rock-mass-map-review-2026-07-05/current-state.md`
2. `docs/handoffs/chatgpt-pro-rock-mass-map-review-2026-07-05/source-map.md`
3. `docs/handoffs/chatgpt-pro-rock-mass-map-review-2026-07-05/constraints-and-decisions.md`
4. `docs/design/testbed-plan/07_rock_mass_generated_routes.md`
5. `scripts/stages/MotionTestStage.gd`
6. `data/design/first_slice/stage_layouts.json`

Current diagnosis:

- The first pass converted many runtime surfaces to filled rock-mass visuals.
- The generated start duplicate collision was removed and replaced with a visual socket.
- `critical_path` room metadata now matches declared rooms.
- Design map markers that were floating over gaps were moved onto supported terrain.
- Generated-route validation now checks route distance plus surface count, landing width, link gaps, step-ups, and duplicate generated surfaces.
- Remaining gaps: no full pathfinding/simulated traversal validation, generated route is not yet template/resource based, and narrow HUD view obscures the map.

Please answer with these sections:

1. Your understanding of the current problem.
2. Whether the first pass matches the user's feature intent.
3. Must-fix defects or contradictions you see.
4. The smallest next useful change, with concrete file/module recommendations.
5. Which improvements should remain deterministic local code rather than model judgment.
6. Validation or test suggestions, ranked by value.
7. Assumptions, uncertainty, and what must be verified locally before implementation.

Constraints:

- Do not propose destructive actions.
- Do not assume access to private local files or ignored runtime folders.
- Do not recommend raw random tile noise.
- Do not recommend replacing the player controller or combat system just to compensate for map geometry.
- Do not bypass repo-local guardrails.
- Prefer source-backed, implementation-ready feedback over generic best-practices advice.

