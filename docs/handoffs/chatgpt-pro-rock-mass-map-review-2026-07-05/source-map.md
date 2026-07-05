---
type: handoff
status: active
created: 2026-07-05
source: User request to create a ChatGPT Pro handoff folder after rock-mass map refinement
topic: chatgpt-pro-rock-mass-map-review
scope: Source map for external implementation
related:
  - ../../design/testbed-plan/07_rock_mass_generated_routes.md
  - ../../design/TESTBED_REIMPLEMENTATION_CONTRACT.md
  - ../../design/MAP_AUTHORING_PIPELINE_CONTRACT.md
---

# Source Map

## Source Of Truth

1. `AGENTS.md`: repo-wide implementation rules and Godot workflow.
2. `README.md`: project summary and runtime commands.
3. `docs/product/2d_platform_action_card_game_prd.md`: active product specification.
4. `docs/design/TESTBED_REIMPLEMENTATION_CONTRACT.md`: current testbed behavior contract.
5. `docs/design/MAP_AUTHORING_PIPELINE_CONTRACT.md`: map authoring and marker expectations.
6. `docs/design/testbed-plan/07_rock_mass_generated_routes.md`: current plan for rock-mass terrain and constrained random generation.
7. `docs/handoffs/chatgpt-pro-rock-mass-map-review-2026-07-05/external-review-validation.md`: locally validated external findings.
8. `docs/handoffs/chatgpt-pro-rock-mass-map-review-2026-07-05/codex-goal-checklist.md`: implementation checklist for the next pass.
9. `scripts/stages/MotionTestStage.gd`: current runtime map and generated route owner.
10. `data/design/first_slice/stage_layouts.json`: previewable first-slice map data.
11. `docs/maps/generated/*.svg` and `*.png`: regenerated design previews.

## Runtime Files To Inspect First

- `scripts/stages/MotionTestStage.gd`: terrain creation, generated route assembly, validation, and clear gating.
- `scripts/stages/StageBase.gd`: shared stage lifecycle, checkpoint, respawn, and clear behavior.
- `scripts/player/Player.gd`: movement/collision behavior that map passability depends on.
- `scripts/autoload/RunState.gd`: active profile and movement metric snapshots.
- `scripts/ui/HUD.gd`: HUD layout and validation/route summary display.

## Relevant Data And Preview Files

- `data/design/first_slice/stage_layouts.json`
- `tools/generate_map_previews.py`
- `docs/maps/generated/stage_01.svg`
- `docs/maps/generated/stage_02.svg`
- `docs/maps/generated/stage_03.svg`
- `docs/maps/generated/boss_stage_01.svg`

## Recent Commits

- `6433d42 Validate ChatGPT Pro map review`
- `8803796 Add ChatGPT Pro map review handoff`
- `67e4b91 Refine testbed map rock-mass terrain`
- `21c4291 Add rock-mass route generation plan`
- `c97f866 Tighten input remap quality checks`

## Local Validation Commands

```powershell
git diff --check
python tools/generate_map_previews.py
.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --quit-after 2
.\tools\godot.ps1 --path . --script res://tools/capture_ui_screenshots.gd
```

If the environment cannot run Windows PowerShell, use the repo's configured Godot runtime equivalent and report the exact substituted command.

## Excluded From External Review

- `.codex-runtime/`: local runtime/cache and screenshots, not source of truth.
- `.godot/`: Godot import/cache output.
- credentials, `.env` files, local account data, raw logs, and unrelated generated exports.
- full chat history; this package summarizes the relevant intent and state.
