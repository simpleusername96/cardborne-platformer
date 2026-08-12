---
type: spec
status: active
owner: BK
created: 2026-08-04
last_reviewed: 2026-08-12
canonical_for: Agent-facing map of Cardborne product and surface intent, authority order, preserved experience contracts, and production design owners
scope: Substantial user-facing UI and visual work across gameplay, HUD, modals, menus, guidebook, reports, and visual replacement
related:
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/design/cardborne-universal-art-style-reference.png
  - ../skills/cardborne-visual-authority/SKILL.md
  - ../../art/visuals/production/README.md
  - ../../docs/design/visual-replacement-workbench/README.md
---

# Cardborne Project Design Context

## Purpose

This is the concise agent-facing entry point for Cardborne design work. It maps
approved product intent and visual authority to their production owners so that
agents do not substitute historical sheets, task previews, or local UI inventions.
It does not replace or restate the production design system.

## Scope

Read this file after `$uiux-gate` for substantial user-facing interface work and
for changes spanning multiple surfaces or shared design owners. For every visual
creation, edit, review, approval, or switch, also follow
[`$cardborne-visual-authority`](../skills/cardborne-visual-authority/SKILL.md).

## Authority Order

1. [`vehicle_game_spec.md`](../../docs/product/vehicle_game_spec.md) owns product
   behavior, reachable flows, controls, combat truth, and campaign structure.
2. [`VISUAL_SYSTEM.md`](../../docs/design/VISUAL_SYSTEM.md) and the exact
   [`cardborne-universal-art-style-reference.png`](../../docs/design/cardborne-universal-art-style-reference.png)
   form the mandatory visual authority pair. The document owns binding rules; the
   sheet is style reference only, never asset approval.
3. Runtime sources listed below own the currently implemented Theme, components,
   semantic roles, fonts, imagery, and surface behavior.
4. The visual-replacement workbench and active ExecPlan own candidate, evidence,
   approval, and switching state only. They do not own art direction.

When these sources disagree materially, surface the conflict and correct the
responsible owner. Do not blend them or resolve the disagreement in this map.

## Product and Surface Intent

- Preserve the connected five-stage run, manual aim, held primary fire, dash,
  passive secondary weapons, the default EMP or its run-scoped active-weapon
  replacement, authored encounters, map pickups, card upgrades, and quota-gated bosses.
- Keep Korean as the default language and keep Korean and English complete on every
  user-facing surface.
- Optimize first-clear readability, fair pressure, target priority, responsive
  control, and reliable performance before adding content or ornament.
- Keep the world sparse, the HUD cockpit-compact, and modals information-first.
  Use shared primitives, large readable masses, restrained semantic accents, and
  only detail that communicates role, state, direction, or action.
- The shipped run has one fixed Hard difficulty. Do not add a difficulty selector
  or imply unsupported modes in UI copy.
- Keep the threat radar on the live projected player anchor while its bounded
  hostile sector feed remains sampled at five hertz.
- Keep the Guidebook stat-first: combat owners provide effective values, Enemies
  contains all hostiles and elite modifiers, Field Objects contains no enemies,
  and undiscovered content is one count rather than fake `???` entries.
- Garage is not a reachable product surface. Pause abort, failure, and final result
  return directly to Deployment. Deployment and Pause keep Settings in the top-right
  header; Pause exposes no stage restart action.

## Runtime Source Map

| Concern | Canonical production owner | Agent use |
| --- | --- | --- |
| Product flow and surface orchestration | [`vehicle_game_spec.md`](../../docs/product/vehicle_game_spec.md), `scripts/ui/vehicle_stage_ui.gd`, and focused `scripts/ui/vehicle_*_panel.gd` owners | Preserve reachable flow; keep gameplay and card behavior out of UI code. |
| Theme and shared UI primitives | `art/visuals/production/ui/vehicle_stage_theme.tres` and `scripts/ui/vehicle_ui_component_factory.gd` | Reuse shared Surface, TextRow, Command, Selectable, Meter, and PreviewWell roles; do not create screen-specific chrome. |
| Semantic colors, type scale, spacing, and breakpoints | `scripts/vehicle/vehicle_stage_visual_profile.gd` | Consume semantic roles; do not redeclare literal design tokens in local screens. |
| Font | `art/visuals/production/ui/fonts/NotoSansKR-Variable.ttf`, loaded by `vehicle_stage_theme.tres` | Use the one production family and preserve Korean/English glyph coverage. |
| Persistent gameplay imagery | `art/visuals/production/gameplay/asset-manifest.json`, `scripts/presentation/components/vehicle_semantic_asset_provider.gd`, and responsibility-specific catalogs | Use only approved manifest assets; keep presentation geometry independent from collision and behavior truth. |
| UI glyphs and live geometry | `scripts/presentation/components/vehicle_ui_glyph_catalog.gd` and responsibility-specific renderers | Keep only resolution-independent dynamic truth code-native; do not replace authored world objects with procedural stand-ins. |
| Candidate and switch workflow | [`visual-replacement-workbench/README.md`](../../docs/design/visual-replacement-workbench/README.md) and `replacement-workbench.json` | Preserve per-unit AS-IS/TO-BE evidence and exact approval; never promote a preview by style similarity alone. |
| Validation | `tools/validation/validate_vehicle_ui_components.gd`, focused surface validators, and `validate_cardborne_visual_authority.ps1` | Run checks proportional to changed owners; broad runtime work still requires the production Web path. |

## Experience Contracts

- Preserve the product spec's connected run and reachable surface flow. UI must
  not add unsupported choices or actions, reinterpret gameplay state, or hide a
  required action.
- Read the current `VISUAL_SYSTEM.md` for the binding shared-component, HUD, modal,
  focus/state, responsive, localization, and reduced-motion contracts. Do not rely
  on a copied measurement or page-layout summary in this agent map.
- Keep presentation separate from controls, collision, attack geometry, encounter
  truth, upgrade behavior, and other product state owned outside the surface.

## Requirements

- Start substantial UI work with `$uiux-gate`, then use this map to open the actual
  product, visual, and runtime owners needed for the task.
- Complete the full `$cardborne-visual-authority` preflight before any visual
  action. The exact sheet hash and inspection contract remain owned by that skill
  and the authority validator.
- Reuse the production Theme, component factory, visual profile, manifests, and
  focused surface owners instead of copying them into `.agents/design/`.
- Keep task alternatives, screenshots, approval hashes, QA logs, and progress in
  the active workbench, ExecPlan, or evidence owner.
- Update this context only after an approved durable change to product direction,
  authority order, system ownership, preserved experience, reachable states, or
  responsive behavior.

## Repeated Failures to Prevent

- Do not use recovered or historical sheets, generated previews, workbench images,
  or runtime captures as the canonical style reference.
- Do not bypass the shared Theme and component factory with local StyleBoxes,
  literal token copies, screen-specific chrome, or fragmented decorative assets.
- Do not add nested frames, repeated lines, dots, lamps, seams, rings, or other
  detail that does not communicate gameplay role, state, direction, or action.
- Do not let UI invent product behavior, unsupported actions, difficulty choices,
  placeholder values, or visual geometry that appears to change gameplay truth.
- Do not treat dated evidence or a style-aligned candidate as current production
  authority or individual asset approval.

## Non-Goals

- This folder is not a runtime resource location, asset library, screenshot archive,
  page-by-page specification, token/component export, or second visual contract.
- Do not add `visual-guide.md`, copied reference images, `system-sheet.png`,
  `tokens.json`, or `components.json` while links to current production owners are
  sufficient.

## Acceptance Criteria

- Every linked authority and runtime owner resolves from the repository.
- Root `AGENTS.md` directs substantial interface work through `$uiux-gate` and this
  document, while visual actions still route through `$cardborne-visual-authority`.
- `tools/validation/validate_cardborne_visual_authority.ps1` verifies the entry
  point, canonical pair, required owner paths, design-folder boundary, and absence
  of recovered authorities.
- `.agents/design/` contains no copied production component, token, font, icon,
  image, or task evidence.

## Maintenance

Keep this map concise. When a durable owner or contract changes, update the
canonical production source first and revise only the affected link or preserved
contract here in the same governance change.
