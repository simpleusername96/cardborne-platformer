---
type: evidence
status: archived
owner: BK
created: 2026-08-08
last_reviewed: 2026-08-09
topic: selected combat HUD implementation QA
source: C:/Users/BK/.codex/generated_images/019fdc36-5189-72f2-9e47-9834db637d7e/exec-6eed99e2-bcba-43f5-aaa3-8c01f8c09b1f.png
related:
  - docs/reports/2026-08-08-combat-pressure-and-surface-depth.md
  - docs/design/VISUAL_SYSTEM.md
---

# Selected Combat HUD Design QA

## Purpose

Record the source-to-runtime comparison, responsive checks, and built-Web smoke
for the user-selected linear combat HUD. This is evidence, not product policy.

## Sources

- Source visual truth: `C:/Users/BK/.codex/generated_images/019fdc36-5189-72f2-9e47-9834db637d7e/exec-6eed99e2-bcba-43f5-aaa3-8c01f8c09b1f.png`
- Final native implementation: `D:/npjt/cardborne-platformer/build/captures/combat-feedback-final/ko-1680x941-designqa-after/04-build-state-12-upgrades.png`
- Final full-view comparison: `D:/npjt/cardborne-platformer/build/captures/combat-feedback-final/designqa-comparison-after.png`
- Final focused top-HUD comparison: `D:/npjt/cardborne-platformer/build/captures/combat-feedback-final/designqa-top-hud-after.png`
- Built-Web deployment capture: `D:/npjt/cardborne-platformer/build/captures/combat-feedback-final/web-built-1280x720.png`
- Responsive/localized capture root: `D:/npjt/cardborne-platformer/build/captures/combat-feedback-final/`

## Comparison Setup

- Source pixels: `1680 x 941`.
- Implementation pixels and logical viewport: `1680 x 941`.
- Density normalization: none; both comparison images are equal-pixel, 1:1
  captures with no resize.
- State: the source is a dense combat mock with eleven visible upgrade receipts;
  the deterministic implementation fixture is Stage 1 with twelve receipts.
  World actors therefore are not compared. The comparable regions are the
  top-left mission surface, centered hull/upgrade rail, top-right minimap, and
  bottom EMP placement.
- Full-view evidence stacks source above implementation at the same viewport.
- Focused evidence crops the same top `140 px` from both equal-size images and
  stacks them without scaling.

## Findings

- No actionable P0, P1, or P2 finding remains.
- Fonts and typography: Korean hierarchy, centered hull value, level numerals,
  and compact mission copy remain readable. The runtime uses the project font
  and approved optical weights rather than copying generated mock lettering.
- Spacing and layout rhythm: the final large hull strip is `640 px` against the
  mock's approximately `665 px`; this preserves the selected long, thin ratio.
  The upgrade rail is centered, panel-free, and bounded to two rows through
  eighteen receipts.
- Colors and tokens: amber hull, dark track, cyan map marks, magenta EMP/boss
  roles, and restrained dark surfaces use the existing visual tokens. No new
  palette was inferred from the mock.
- Image quality and asset fidelity: runtime upgrade icons use the approved
  semantic raster assets. Their internal transparent margins make the visible
  silhouettes smaller than the generated mock, but replacing or stretching
  those assets would reduce production fidelity. No placeholder, custom SVG, or
  CSS-style substitute is present.
- Copy and content: Korean and English remain complete. Mission, boss-shield,
  upgrade-card, and result text use the current localization catalog.
- Responsive behavior: `960 x 540`, `1280 x 720`, and `1920 x 1080` were captured
  in Korean and English. Korean and English `960 x 540` were also captured at
  200% text. The rail covers `0/6/12/18` receipts in each set. At 200%, it wraps
  after ten icons and stays within the `404 px` center zone.
- Minimap hierarchy: ordinary enemies use `4.0/2.6` radii and bosses use
  `10.0/7.6`; the boss is materially larger without changing the map frame.

## Comparison History

### Iteration 1 — blocked

- P2: at `1680 x 941`, the implementation used the `520 px` standard hull width
  and `30 px` icons, while the selected mock used a materially wider top-center
  region.
- P2: at `960 x 540` with 200% text, twelve `34 px` icons exceeded the declared
  center zone instead of wrapping.
- Evidence: `D:/npjt/cardborne-platformer/build/captures/combat-feedback-final/designqa-comparison-before.png` and
  `D:/npjt/cardborne-platformer/build/captures/combat-feedback-final/ko-960x540-text200/04-build-state-12-upgrades.png`

### Fixes

- Added the locked `640 px` large hull profile and `40 px` large icon profile.
- Restored the compact hull width to `400 px`.
- Added a ten-icon accessibility wrap and computed rail height from real row
  geometry instead of a fixed estimate.
- Added deterministic `0/6/12/18` receipt captures to core and full manifests.

### Iteration 2 — passed

- The equal-viewport full and focused comparisons show the selected hierarchy,
  proportions, and panel-free center rail without actionable P0/P1/P2 drift.
- The refreshed 200% captures show no rail overflow or clipped level numeral.

## Built-Web Verification

- Export: `tools/export_web.ps1` passed and produced four Web build files.
- Browser viewport: `1280 x 720`; Godot canvas: `1280 x 720`; no browser density
  emulation was applied.
- Primary interaction: Chrome loaded the deployment screen, the `출격` action
  was activated, and live gameplay with the selected HUD rendered.
- Network: document, PNG, JavaScript, WASM, PCK, icon, and two blob requests all
  returned HTTP 200.
- Console: zero warnings, errors, or issues after deployment and gameplay entry.
- The registered Codex Web lane `13029` was used. The task-owned server and page
  were closed, and the port was verified free.

## Limitations

- This QA proves visual and functional contracts, not combat balance or frame
  performance.
- The mock and deterministic gameplay fixture intentionally use different world
  populations; world-actor placement was excluded from fidelity judgment.

## Final Result

final result: passed
