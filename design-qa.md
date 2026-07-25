---
type: evidence
status: active
owner: BK
created: 2026-07-25
scope: Rendered comparison of the recovered Cardborne UI against the selected six-screen visual direction
related:
  - docs/design/UI_VISUAL_SYSTEM.md
  - docs/design/uiux-refinement-direction/README.md
---

# Cardborne UIUX Recovery — Design QA

## Comparison contract

- Source visual truth:
  `docs/design/uiux-refinement-direction/01-combat-hud.png` through
  `06-stage-report.png`.
- Implementation truth:
  `build/captures/uiux-recovery-final/ko-1280x720/`.
- Responsive and localization evidence:
  `build/captures/uiux-recovery-final/{ko,en}-{960x540,1280x720,1920x1080}/`.
- Comparison viewport and CSS-equivalent logical size: `1280x720`.
- Source pixels: `1280x720`; implementation pixels: `1280x720`.
- Device density: `1`; no density normalization or viewport scaling was needed.
- Compared states: maximum-pressure combat, selected level-up card, deployment,
  active-run ship status, discovered boss guide entry, and successful stage
  report.

## Evidence

### Full-view comparison

`build/audits/uiux-recovery/final/contact-sheet.png` places each selected source
screen directly beside its implementation capture. The order is combat,
upgrade, deployment, ship settings, guidebook, and stage report.

### Focused-region comparison

`build/audits/uiux-recovery/final/focused-contact-sheet.png` compares the
regions where full-screen reduction makes text and control treatment difficult
to judge:

- upgrade family badges, title/effect hierarchy, impact value, level pips, and
  selected state;
- ship-stat grouping, value alignment, separators, and scroll treatment;
- guide preview, description, counterplay icons, labels, and row surfaces.

Focused crops preserve each source's pixels. Their differing crop bounds isolate
the same semantic region without stretching the source or implementation.

## Findings

No actionable P0, P1, or P2 mismatch remains.

- Typography: Noto Sans KR remains the shared Korean/English face. Display
  headings, section labels, metrics, body copy, and supporting copy now have
  distinct weights and readable sizes. Korean and longer English strings remain
  legible without clipping at `960x540`.
- Spacing and layout: the six selected screens now preserve the intended broad
  surfaces, balanced columns, explicit separators, large upgrade cards, and one
  dominant primary action. Pause, result, and garage reuse the same hierarchy
  without the previous empty panels or full-width action stacks.
- Colors and tokens: ivory, ceramic green, mustard, mint, coral, magenta, and
  cobalt-derived modal contrast retain their semantic roles. Selected and
  keyboard-focus states remain independently visible.
- Image quality and assets: the guidebook uses the real retained combat preview
  mesh rather than a placeholder. Existing procedural flat icons remain sharp
  at all captured resolutions and match the project's current large-shape art
  contract.
- Copy and content: Korean is the default; English parity is present. Labels
  describe actual bindings, build values, upgrade deltas, guide entries, and
  report data rather than decorative mock content.
- States and accessibility: deployment difficulty, upgrade selection and
  confirmation guard, keyboard focus, settings tabs, guide discovery, compact
  report tabs, pause, result, and garage states are covered by deterministic
  captures and focused validators.
- Responsiveness: the complete screen set rendered at `960x540`, `1280x720`,
  and `1920x1080` in Korean and English. Persistent controls do not overlap,
  clip, or escape their modal surface.

Accepted P3 deviations:

- The source concepts contain subtle gradients and paper texture. Production
  keeps flat fills because `docs/design/UI_VISUAL_SYSTEM.md` explicitly forbids
  texture and decorative detail that competes with play.
- Runtime guide previews use the actual combat silhouette and therefore differ
  slightly from the concept illustration's proportions.
- The combat comparison uses deterministic live fixture content, so enemy and
  pickup positions do not duplicate the concept composition.

## Comparison history

### Baseline

Earlier implementation evidence under
`build/captures/uiux-refinement/drowned_ruin_field-ko-1280x720/` had three
blocking visual findings:

- **P1 — hierarchy and scale:** deployment, settings, guidebook, and reports
  were materially undersized, used small type, and left large unowned regions.
- **P1 — upgrade decision clarity:** cards compressed family, effect, value,
  and level into one weak text block.
- **P2 — modal action hierarchy:** pause, result, and garage used stacked
  full-width controls or empty containers that obscured the primary action.

### Fixes

- Added shared display, title, section, metric, summary-band, selection, and
  separator theme contracts.
- Rebuilt deployment, upgrade, ship status, guidebook, report, pause, result,
  and garage composition around the selected screen hierarchy.
- Added explicit 1280 logical modal targets with safe minimum-viewport
  adaptation.
- Added localization for the new control and upgrade hierarchy without moving
  gameplay rules into UI code.
- Added validator assertions for modal scale, display typography, and upgrade
  card dimensions.

### Post-fix evidence

- Equal-size source/implementation comparison:
  `build/audits/uiux-recovery/final/contact-sheet.png`.
- Focused typography/component comparison:
  `build/audits/uiux-recovery/final/focused-contact-sheet.png`.
- Small-screen Korean and English evidence:
  `build/audits/uiux-recovery/final/{ko,en}-960-key-screens.png`.
- All 37 repository validators pass.
- Production Web export succeeds at `build/web/index.html`.

## Implementation checklist

- [x] Match the selected six-screen hierarchy and modal scale.
- [x] Preserve Korean default and complete English rendering.
- [x] Preserve focus, confirmation, snapshot, and gameplay ownership contracts.
- [x] Verify all required modal and HUD states at three supported resolutions.
- [x] Compare source and implementation in combined full-view and focused
  evidence.
- [x] Run the complete validator suite and production Web export.

final result: passed
