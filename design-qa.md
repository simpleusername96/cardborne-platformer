---
type: evidence
status: active
owner: Codex
created: 2026-08-03
last_reviewed: 2026-08-03
topic: Selected upgrade-card dossier implementation QA
scope: Upgrade choice modal, responsive states, and Secondary Weapons terminology
related:
  - docs/design/VISUAL_SYSTEM.md
  - docs/product/vehicle_game_spec.md
  - docs/design/visual-replacement-workbench/previews/ui-screen-direction/03b-upgrade-card-selected.png
  - docs/design/visual-replacement-workbench/previews/ui-screen-direction/03c-upgrade-card-runtime.png
---

# Upgrade Card Design QA

## Comparison target

- Source visual truth: `docs/design/visual-replacement-workbench/previews/ui-screen-direction/03b-upgrade-card-selected.png`.
- Rendered implementation: `build/upgrade-dossier-final/ko-1280x720/06b-level-up-selected.png`.
- Additional long-copy and Seeker-category evidence: `docs/design/visual-replacement-workbench/previews/ui-screen-direction/03c-upgrade-card-runtime.png`.
- Viewport/state: Korean, dark theme, `1280×720`, upgrade modal open, first visible card selected, Equip available.
- Source pixels: `1672×941`, normalized to `1280×720` for comparison.
- Implementation pixels and logical viewport: `1280×720`; density scale `1`.
- The mock uses illustrative offer content while the runtime capture uses the deterministic live first-offer fixture. The comparison therefore judges the locked structure, hierarchy, scale, states, and information treatment rather than literal card titles.

## Evidence

- Full-view normalized comparison: `build/upgrade-dossier-final/reference-vs-runtime-final.png` (source left, runtime right).
- Responsive selected-state matrix: `build/upgrade-dossier-final/responsive-selected-matrix.png`.
- Complete capture sets: `build/upgrade-dossier-final/{ko,en}-{960x540,1280x720,1920x1080}` and `build/upgrade-dossier-final/{ko,en}-1280x720-text2`.
- A separate crop was not needed: the original-resolution full comparison keeps category, title, level, stat rows, descriptions, glyph edges, selection rail, and Equip state legible. The tracked `03c` runtime capture provides an additional original-resolution long-copy check.

## Findings

No actionable P0, P1, or P2 differences remain.

- [P3] Primary-action surface differs intentionally.
  - Location: Equip action.
  - Evidence: the mock uses an amber outline; runtime uses the project's filled mustard primary Command state.
  - Impact: none on hierarchy or use. Runtime preserves the active visual-system rule that one primary action is filled and visually dominant.
  - Resolution: accepted as a shared-system constraint; no screen-local style was added.
- [P3] Selected surface fill is stronger in runtime.
  - Location: selected upgrade card.
  - Evidence: both use the amber 3 px left rail/border, while runtime also uses the existing raised selected fill.
  - Impact: improves selected/focus distinction without adding ornament or relying on color alone.
  - Resolution: accepted as the public shared Selectable state.

## Required fidelity surfaces

- Fonts and typography: the runtime uses the project Noto Sans KR variable family with 800-weight category/title and 650-weight body copy. Category, title, `Lv.<current> → <next>`, stat labels/values, and descriptions retain the mock hierarchy. Korean and English wrapping is complete with no truncation.
- Spacing and layout rhythm: three `352×432` cards and 20 px gaps fit the wide modal; `280×378` compact cards fit `960×540`. One divider separates image and comparison lanes, and one footer rule appears only when a footer exists. No nested decorative panels were introduced.
- Colors and visual tokens: dark navy surfaces, cyan system text, white primary copy, and amber selection/primary action reuse existing project tokens. Contrast and state distinctions remain validator-backed.
- Image quality and asset fidelity: all cards use one resolved semantic gameplay PNG through the shared semantic asset provider; no placeholder, generated runtime image, SVG substitute, code drawing, sprite-sheet crop, or stretched screenshot is used. The card TextureRect fills the assigned artwork slot while preserving aspect ratio and sharpness.
- Copy and content: every card retains category, subtype-specific name, image, real level transition, zero-to-two numeric changes, and description. Behavior-only cards place their change description in the comparison lane instead of leaving it blank. Seeker cards display the shared `보조 무기 / Secondary Weapons` category.
- States and accessibility: normal, keyboard focus, selected, pending/disabled, failed confirm, Korean/English, compact/wide, and 200% text scale are covered. At 200%, only the outer offer body scrolls and Equip remains fixed; cards never scroll internally.

## Comparison history

1. Initial compact validation found P2 clipping in the longest English behavior description and the `Structure damage` stat label. The compact card changed from `272×356` to `280×378`, its comparison lane widened from 112 to 140 px, its dossier height increased from 144 to 182 px, and compact stat labels gained a two-line budget. Post-fix `validate_vehicle_upgrade_ui.gd` and `validate_vehicle_stage_ui_layout.gd` passed, and the final responsive matrix shows all three complete cards.
2. The first rendered comparison exposed a stale imported Korean level template (`레벨 0 → 1`) rather than the locked compact form. Godot reimported `vehicle_stage.csv`; the final evidence now shows `Lv.0 → 1` in Korean and English.
3. The first full-view comparison found P2 under-scaling of semantic artwork inside the correct control slot. The shared card TextureRect now fills the authored artwork slot without enlarging the control or narrowing the comparison lane. The final comparison shows larger, sharp artwork and both layout validators still pass.

## Interaction and responsive evidence

- The upgrade component validator covers the 0.35-second input guard, keyboard focus, card selection, explicit Equip confirmation, pending/disabled state, failure recovery, exactly three offers, and zero exit actions.
- The final deterministic matrix contains Korean and English at `960×540`, `1280×720`, and `1920×1080`, plus both locales at 200% text scale. Manifest/file correspondence and PNG dimensions were verified for every capture.

## Implementation checklist

- [x] Match the selected split-dossier hierarchy.
- [x] Preserve every card value and description.
- [x] Keep one shared Selectable state and one shared primary Command.
- [x] Verify Korean, English, compact, wide, selected, and 200% states.
- [x] Verify no clipping, overlap, per-card scroll, placeholder imagery, or extra exit action.

## Final integration evidence

- All 58 Godot validators passed in one integrated run; the log is saved at `build/upgrade-dossier-final/all-godot-validators-final.log`.
- Godot import, the visual-replacement workbench check and validation, and the release Web export passed. The export produced the complete four-file artifact at `build/web/index.html`.
- The exported build was served on the fastrun-manager Codex lane at port `13029` and inspected in Chrome. The `Cardborne` canvas loaded at `1920×911`, the deployment action entered live gameplay, and the browser reported zero warning or error logs. The task-owned server was then stopped and the port was verified clean.

final result: passed
