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

# ChatGPT Pro Rock-Mass Map Review Handoff

Date: 2026-07-05  
Reviewer target: ChatGPT Pro  
Workspace: `D:\npjt\cardborne-platformer`  
Branch: `master`  
Code baseline commit: `67e4b9145070e110317b2ee2b8a2cd684e6a5626`  
Dirty state at package start: clean  
Remote: `https://github.com/simpleusername96/cardborne-platformer.git`

## Objective

Ask ChatGPT Pro to review the current testbed map direction after the first rock-mass terrain refinement pass. The useful answer should focus on whether the map now matches the intended feature direction, what the next smallest improvement should be, and which validation gaps matter most before expanding random generation.

## Reading Order

1. `docs/handoffs/chatgpt-pro-rock-mass-map-review-2026-07-05/current-state.md`
2. `docs/handoffs/chatgpt-pro-rock-mass-map-review-2026-07-05/source-map.md`
3. `docs/handoffs/chatgpt-pro-rock-mass-map-review-2026-07-05/constraints-and-decisions.md`
4. `docs/design/testbed-plan/07_rock_mass_generated_routes.md`
5. `scripts/stages/MotionTestStage.gd`
6. `data/design/first_slice/stage_layouts.json`

## Requested Output

- Review whether the first pass satisfies the intended feature direction.
- Identify the smallest next change that most improves map quality.
- Separate must-fix defects from optional design improvements.
- Label assumptions, uncertainty, and items that require local verification.
- Avoid generic best-practices advice; tie recommendations to files and current behavior.

## Do Not Do

- Do not treat external feedback as source of truth over local code, tests, and repo docs.
- Do not propose deleting the current testbed or replacing the movement/combat foundation.
- Do not recommend raw random tile noise.
- Do not include private local data, ignored runtime folders, credentials, or unrelated logs.

## Response Storage

After ChatGPT Pro responds, save the raw answer in:

`docs/handoffs/chatgpt-pro-rock-mass-map-review-2026-07-05/external-review-raw.md`

