---
type: handoff
status: active
created: 2026-07-05
source: User request to rewrite ChatGPT Pro handoff for implementation, tests, and PR creation
topic: chatgpt-pro-rock-mass-map-review
scope: Copyable implementation prompt for ChatGPT Pro
related:
  - ./README.md
  - ./current-state.md
  - ./source-map.md
  - ./constraints-and-decisions.md
  - ./external-review-validation.md
  - ./codex-goal-checklist.md
---

# External Model Prompt

You are working on a Godot 4.x GDScript project. This is an implementation task, not a review-only task.

Repository:

- Remote: `https://github.com/simpleusername96/cardborne-platformer.git`
- Target base branch: `master`
- Create implementation branch: `chatgpt-pro/rock-mass-route-contract`
- Open a pull request against `master` when done.

Product goal:

The testbed map should use filled rock-like terrain masses at varied heights, while still guaranteeing player movement space between terrain shapes and deterministic constrained random generation. The map must not read as a set of thin floating platforms.

Current validated problem:

- The first pass improved the visual direction, but the generated route is still a hard-coded segment list with seeded jitter.
- Some filled rock masses are visual-depth only while their actual collision remains a thin surface.
- The generated start socket is visual-only but can still participate in route validation checks.
- Duplicate validation compares generated surfaces only with other generated surfaces, not authored terrain.
- Startup can publish a ready route status after generated route validation has emitted invalid.
- Retry/fallback and full traversal validation are still later work.

Read these files before coding:

1. `AGENTS.md`
2. `docs/handoffs/chatgpt-pro-rock-mass-map-review-2026-07-05/README.md`
3. `docs/handoffs/chatgpt-pro-rock-mass-map-review-2026-07-05/current-state.md`
4. `docs/handoffs/chatgpt-pro-rock-mass-map-review-2026-07-05/source-map.md`
5. `docs/handoffs/chatgpt-pro-rock-mass-map-review-2026-07-05/constraints-and-decisions.md`
6. `docs/handoffs/chatgpt-pro-rock-mass-map-review-2026-07-05/external-review-validation.md`
7. `docs/handoffs/chatgpt-pro-rock-mass-map-review-2026-07-05/codex-goal-checklist.md`
8. `docs/design/testbed-plan/07_rock_mass_generated_routes.md`
9. `scripts/stages/MotionTestStage.gd`
10. `scripts/autoload/RunState.gd`
11. `scripts/player/Player.gd`
12. `data/design/first_slice/stage_layouts.json`

Required implementation scope:

1. Add a compact route-surface registry or equivalent surface contract in `scripts/stages/MotionTestStage.gd`.
2. Track authored and generated terrain separately enough to validate overlap and route links.
3. Track at least: id, source, role, visual bounds, collision bounds, top surface, support capability, one-way/solid state, and whether the filled body is visual-only or solid.
4. Update generated-route validation so landing, gap, and step checks use support-capable collision surfaces, not decorative visual-only masses.
5. Detect same-level duplicate support between generated terrain and authored terrain unless it is explicitly intentional.
6. Fix the route status bug so invalid generated routes are not overwritten as ready by `_publish_testbed_context()`.
7. Preserve deterministic seed replay and the current filled rock-mass visual direction.
8. Keep the change scoped. Do not extract a broad procedural generator or replace the player controller.

Preferred stretch scope only if low-risk:

- Add minimum headroom or corridor-width checks using existing player movement metrics.
- Add or update a small deterministic seed validation helper if the repo already has a suitable pattern.
- Update `docs/design/testbed-plan/07_rock_mass_generated_routes.md` checkboxes only for work actually completed.

Validation required:

Run and report the results of:

```powershell
git diff --check
python tools/generate_map_previews.py
.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --quit-after 2
```

If geometry previews change, commit the regenerated preview files. If the environment cannot run the Windows PowerShell Godot wrapper, run the closest repo-valid Godot equivalent and state the exact substituted command.

Pull request requirements:

- Push branch `chatgpt-pro/rock-mass-route-contract`.
- Open a PR to `master`.
- PR title: `Harden rock-mass generated route validation`
- PR body must include:
  - summary of behavior changes;
  - files changed;
  - validation commands and results;
  - screenshots or preview notes if map visuals changed;
  - known limitations and follow-up work;
  - confirmation that the PR does not merge itself.

Do not:

- Stop at advice or another review-only response.
- Push directly to `master`.
- Add external art assets or production dependencies.
- Use raw random tile noise.
- Replace player movement or combat systems to hide map geometry problems.
- Bypass repo-local guardrails, tests, lockfiles, or instructions.
- Include credentials, ignored runtime folders, private local files, or unrelated logs.

If you cannot open a PR:

1. Still create the implementation branch and commit the changes.
2. Push the branch if credentials allow.
3. Provide the branch name, commit hash, diff summary, validation results, and the exact blocker preventing PR creation.
