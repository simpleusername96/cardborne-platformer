---
type: handoff
status: active
created: 2026-07-05
source: User request to create a ChatGPT Pro handoff folder after rock-mass map refinement
topic: chatgpt-pro-rock-mass-map-review
scope: Constraints and decisions for external map review
related:
  - ../../design/TESTBED_REIMPLEMENTATION_CONTRACT.md
  - ../../design/testbed-plan/07_rock_mass_generated_routes.md
---

# Constraints And Decisions

## Must Preserve

- Godot 4.x GDScript MVP direction.
- Existing player movement/combat contracts unless a map issue proves they block playability.
- `MotionTestStage` as the current boot path until a deliberate `Stage01` split happens.
- Deterministic seed replay: same seed/profile/ability flags should reproduce the same generated route.
- Critical route must remain clearable by the least-mobile required profile.
- Random generation must be constrained/template-like, not arbitrary tile noise.
- Placeholder visuals are acceptable, but terrain should read as filled rock/dungeon mass.

## Must Avoid

- Do not propose final art asset dependencies.
- Do not replace the player controller just to make bad map geometry passable.
- Do not move stage-only behavior into `StageBase`.
- Do not suggest a full procedural world generator as the next step.
- Do not bypass repo safeguards, lockfiles, or local instructions.
- Do not treat ChatGPT Pro's answer as source of truth; Codex must verify it locally.

## Source Of Truth Hierarchy

1. Current local code, tests, and validation commands.
2. Root `AGENTS.md`, `.agent/*` guidance, and canonical project docs.
3. Active specs and plans under `docs/design/`.
4. This handoff package.
5. External model feedback, after local verification.

## Decisions Already Made

- Use filled rock-mass visual language for primary route surfaces.
- Keep one-way, crumbling, moving, and debug ledges as special thin features.
- Fix current marker support problems before expanding random generation.
- Keep the first pass inside `MotionTestStage.gd` for speed and safety.
- Track next steps in `docs/design/testbed-plan/07_rock_mass_generated_routes.md`.

## Known Tradeoffs

- The rock-mass helper grew inside `MotionTestStage.gd`; this is acceptable for the first pass but should be extracted if it keeps growing.
- Current generated validation is better than distance-only but still not a full traversal proof.
- Narrow HUD readability is a real issue, but it is a UI refinement rather than core terrain generation.

