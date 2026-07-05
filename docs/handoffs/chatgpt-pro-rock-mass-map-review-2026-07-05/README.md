---
type: handoff
status: active
created: 2026-07-05
source: User request to create a ChatGPT Pro handoff folder after rock-mass map refinement
topic: chatgpt-pro-rock-mass-map-review
scope: External review package for current testbed map generation and terrain direction
related:
  - ../../design/testbed-plan/07_rock_mass_generated_routes.md
  - ../../design/TESTBED_REIMPLEMENTATION_CONTRACT.md
  - ../../design/MAP_AUTHORING_PIPELINE_CONTRACT.md
---

# ChatGPT Pro Rock-Mass Map Implementation Handoff

Date: 2026-07-05  
Implementation target: ChatGPT Pro
Workspace: `D:\npjt\cardborne-platformer`  
Branch: `master`  
Implementation baseline before this prompt rewrite: `6433d42 Validate ChatGPT Pro map review`
Remote: `https://github.com/simpleusername96/cardborne-platformer.git`

## Objective

Ask ChatGPT Pro to implement the next rock-mass map hardening pass, run the required validation, push a working branch, and open a pull request against `master`.

This is no longer a review-only handoff. The expected outcome is code, tests or validation evidence, and a PR.

## Reading Order

1. `docs/handoffs/chatgpt-pro-rock-mass-map-review-2026-07-05/current-state.md`
2. `docs/handoffs/chatgpt-pro-rock-mass-map-review-2026-07-05/source-map.md`
3. `docs/handoffs/chatgpt-pro-rock-mass-map-review-2026-07-05/constraints-and-decisions.md`
4. `docs/handoffs/chatgpt-pro-rock-mass-map-review-2026-07-05/external-review-validation.md`
5. `docs/handoffs/chatgpt-pro-rock-mass-map-review-2026-07-05/codex-goal-checklist.md`
6. `docs/design/testbed-plan/07_rock_mass_generated_routes.md`
7. `scripts/stages/MotionTestStage.gd`
8. `data/design/first_slice/stage_layouts.json`

## Requested Output

- Create a branch from latest `origin/master`.
- Implement the route-surface contract and validation hardening described in `codex-goal-checklist.md`.
- Fix the generated-route status overwrite bug.
- Run and report the validation commands.
- Push the implementation branch.
- Open a PR against `master`.
- In the PR body, include changed behavior, validation evidence, known limitations, and any follow-up tasks.

## Do Not Do

- Do not stop at another review-only answer.
- Do not push directly to `master`.
- Do not treat external feedback as source of truth over local code, tests, and repo docs.
- Do not propose deleting the current testbed or replacing the movement/combat foundation.
- Do not recommend raw random tile noise.
- Do not add external art assets or production dependencies.
- Do not broaden the task into a full procedural world generator.
- Do not include private local data, ignored runtime folders, credentials, or unrelated logs.

## Response Storage

After ChatGPT Pro responds or opens a PR, save the outcome in:

`docs/handoffs/chatgpt-pro-rock-mass-map-review-2026-07-05/external-implementation-outcome.md`
