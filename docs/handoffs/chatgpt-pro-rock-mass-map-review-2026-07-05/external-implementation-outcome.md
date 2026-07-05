---
type: evidence
status: active
created: 2026-07-05
source: User-provided ChatGPT Pro implementation outcome and downloaded replacement file
topic: chatgpt-pro-rock-mass-map-review
related:
  - ./README.md
  - ./external-model-prompt.md
  - ./codex-goal-checklist.md
  - ./raw/MotionTestStage.chatgpt-pro.gd.txt
---

# External Implementation Outcome

ChatGPT Pro reported that GitHub write and PR mutation calls were blocked by its connector, so it could not push the implementation branch or open a PR.

It provided a full local replacement for:

- `scripts/stages/MotionTestStage.gd`

Durable raw copy:

- `raw/MotionTestStage.chatgpt-pro.gd.txt`

Reported implementation summary:

- added `_route_surfaces: Array[Dictionary]` as a compact surface registry;
- registered terrain/platform surfaces with id, source, role, visual bounds, collision bounds, top, support capability, one-way state, solid-fill state, visual-only state, and stitch allowance;
- separated authored and generated surfaces;
- cleared generated surface records on seed rebuild while preserving authored support records;
- treated `GeneratedStartSocket` as visual-only and removed it from route-link validation;
- started generated route validation from real authored support: `MiddleConnectorFloor`;
- validated landing width, gaps, and step-ups using support-capable collision bounds;
- detected same-level generated/generated and generated/authored duplicate support terrain;
- preserved deterministic seed use and filled rock-mass visuals;
- routed `_publish_testbed_context()` and `_mark_validation()` through route status state so invalid generated routes stay invalid.

Reported external static validation:

- downloaded file bytes: `46578`
- reported line count: `1076`
- downloaded file SHA-256: `07e89b1766dbc388a8cf41ff2a1233de57e040484c4da19ba8238519959b1903`
- trailing whitespace: none
- basic quote/bracket balance: passed

Local ingestion note:

- Codex copied the replacement into `scripts/stages/MotionTestStage.gd` on branch `codex/rock-mass-route-contract` for local validation and follow-up fixes.
- Codex renamed the durable raw copy to `.gd.txt` so Godot does not import the evidence file as a script.

Local validation completed by Codex:

- `git diff --check`: passed.
- `python tools/generate_map_previews.py`: passed; regenerated 4 map previews with no tracked preview diff.
- `.\tools\godot.ps1 --path . --headless --import`: passed.
- `.\tools\godot.ps1 --path . --headless --quit-after 2`: passed.
- `.\tools\godot.ps1 --path . --script res://tools/capture_ui_screenshots.gd`: passed.

Local adjustments after ingest:

- added a compact registry invariant comment near `_route_surfaces`;
- marked the completed route-validation checklist items in the implementation checklist and design plan;
- kept headroom, corridor-width, fall recovery, seed matrix, and retry/fallback work open.
