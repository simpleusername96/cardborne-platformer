---
type: plan
status: active
created: 2026-07-05
source: ./external-review-validation.md
topic: rock-mass-generated-route-hardening
related:
  - ./external-review-validation.md
  - ../../design/testbed-plan/07_rock_mass_generated_routes.md
  - ../../../scripts/stages/MotionTestStage.gd
---

# Codex Goal Checklist

Objective: harden the generated rock-mass map so visible terrain, collision support, passability validation, and route status agree before extracting a broader terrain template generator.

## Scope

- Keep work focused on the testbed map and generated route contract.
- Preserve the current rock-mass visual direction: filled bodies with varied heights and player-space gaps.
- Keep deterministic seed behavior.
- Do not add external assets or a broad generator architecture in this pass.

## Source Map

- `scripts/stages/MotionTestStage.gd`: route generation, terrain construction, generated-route validation, and route status signals.
- `docs/design/testbed-plan/07_rock_mass_generated_routes.md`: accepted feature plan and open validation phases.
- `docs/handoffs/chatgpt-pro-rock-mass-map-review-2026-07-05/external-review-validation.md`: validated external review findings.

## Phase 1 - Route Surface Registry

- [ ] Add a compact surface record for terrain that can affect route validation.
- [ ] Track at least: id, source, role, visual bounds, collision bounds, top surface, support capability, one-way state, and solid-fill state.
- [ ] Register authored support surfaces that can overlap or connect to generated route surfaces.
- [ ] Register generated support surfaces separately from visual-only masses.
- [ ] Keep comments short and limited to invariants that are not obvious from field names.

## Phase 2 - Honest Route Validation

- [ ] Validate links using support-capable collision surfaces, not visual-only records.
- [ ] Exclude visual-only records from landing and route-link checks unless explicitly bridged to a real support surface.
- [ ] Detect generated/generated duplicate support surfaces.
- [ ] Detect generated/authored duplicate support surfaces at the same level.
- [ ] Keep intentional stitches allowed through an explicit role or flag.
- [ ] Preserve existing distance, surface count, landing width, and gap checks unless replaced by stronger checks.

## Phase 3 - Route Status And Failure Flow

- [ ] Prevent `_publish_testbed_context()` from overwriting an invalid generated-route status with ready.
- [ ] Show the generated route as invalid when route validation fails.
- [ ] Keep `complete_stage()` locked while generated route validation is invalid.
- [ ] Keep failure reason available in route summary for debugging and handoff.

## Phase 4 - Movement-Space Checks

- [ ] Add minimum headroom checks above required landing and corridor regions.
- [ ] Add minimum horizontal corridor width checks between filled masses.
- [ ] Validate fall recovery or reset coverage on required drops.
- [ ] Validate object and enemy placement against real support surfaces.
- [ ] Treat intentional airborne pickups as explicit data, not accidental placement.

## Phase 5 - Seed And QA Matrix

- [ ] Define fixed QA seeds for safe movement, vertical terrain, combat terrain, hazard terrain, optional branch terrain, and at least one invalid edge case if supported.
- [ ] Replay each fixed seed twice and compare route summaries.
- [ ] Regenerate random seeds repeatedly and confirm stale generated nodes, statuses, and validation state do not persist.
- [ ] Manually clear at least one generated route with the least-mobile required movement profile.

## Validation Cadence

- [ ] Run `git diff --check`.
- [ ] Run the Godot headless smoke command through `.\tools\godot.ps1`.
- [ ] Regenerate map previews if geometry changes.
- [ ] Review generated map previews only after mechanical checks pass.

## Stop Conditions

- Stop and ask before broad generator extraction, production dependency changes, or forceful git operations.
- Stop if movement metrics cannot be verified from local player/controller state.
- Stop if collision changes make the player controller feel regressions likely without manual playtest evidence.

## Success Criteria

- The generated route cannot be marked ready when route validation fails.
- Visual-only terrain is not treated as a walkable support surface by validation.
- Generated surfaces are checked against authored collision for duplicate same-level support.
- Random seeds still vary map arrangement while preserving guaranteed traversal space.
- The map retains filled, varied-height rock masses rather than reverting to thin floating platforms.
