---
type: plan
status: done
owner: BK
created: 2026-07-21
topic: Korean-first bilingual UI and complete Vehicle Stage 1 layout refinement
scope: Replace the audited Vehicle Stage 1 HUD and modal layouts, add persistent Korean/English switching with Korean as the default, and preserve gameplay and art-direction contracts
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../../docs/product/vehicle_stage_one_experimental_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ./2026-07-21-ceramic-fresco-uiux-refinement.md
---

# Korean-first Vehicle Stage 1 UI Layout Refinement Plan

The finished runtime keeps the accepted Sunken Ceramic Fresco art, combat, route, rewards, input, and persistence behavior while replacing the audited fixed-position UI composition. Five phases add a native Godot translation catalog with Korean as the first-run default, persist live Korean/English switching, establish one responsive HUD safe frame, and rebuild every reachable modal with a consistent hierarchy at 960x540, 1280x720, and 1920x1080.

## Purpose

- Objective: make every current screen readable and task-focused in Korean and English without obscuring combat or duplicating state.
- Final artifact: a bilingual Stage 1 whose initial deployment, gameplay HUD, upgrade, pause/settings, boss HUD, result, and garage all use the same responsive layout contract.
- Completion state: both locales pass deterministic localization/layout checks, native capture inspection at 960x540 and 1280x720, gameplay regression validation, Web export, built boot, and task-scoped quality review.

## Pre-plan Evidence Already Verified

| Source or path | Verified fact | Decision affected | Recheck boundary |
| --- | --- | --- | --- |
| `.godot/ui-layout-audit-2026-07-21/` | Fresh captures show duplicated objective/notification text, HUD visible behind upgrade and pause, oversized empty choice panels, cramped 960 layouts, and mixed garage/settings ownership. | Locks the complete screen list and remediation order. | Recheck after each rendered batch. |
| `scripts/ui/vehicle_stage_ui.gd` | All current screens are runtime-built; `show_upgrade()` and `show_pause()` deliberately leave HUD visible; fixed sizes own layout. | Rebuild composition in the same owner while preserving signals. | Recheck signals, focus, and layout after replacement. |
| `scripts/vehicle/vehicle_stage_one.gd` | Objectives, enemy names/states, notifications, buffs, boss labels, and result values contain user-facing English. | Localize stage-produced snapshots and messages, not only modal copy. | Recheck every user-facing string after integration. |
| `scripts/vehicle/vehicle_stage_rules.gd` | Upgrade data stores rendered English title, family, and description strings. | Replace display strings with translation keys while retaining upgrade IDs and behavior. | Recheck upgrade validator and capture choices. |
| `scripts/autoload/pivot_settings_store.gd` | Only Master and SFX values persist. | Add a validated `ui.locale` value and `locale_changed` signal to the same small settings owner. | Recheck malformed and missing settings behavior. |
| `art/ui/production/fonts/NotoSansKR-Variable.ttf` | The active vehicle Theme already loads Korean and Latin glyphs under OFL. | Reuse the current font; add no asset or dependency. | Recheck only if the Theme font changes. |
| `tools/validation/validate_vehicle_stage_one.gd` | 87 gameplay, focus, visual, and nominal layout checks already pass. | Extend the same validator with locale, modal visibility, Korean text, and revised layout contracts. | Run after every phase. |
| [Godot stable localization spreadsheet guide](https://docs.godotengine.org/en/stable/tutorials/i18n/localization_using_spreadsheets.html) | UTF-8 CSV catalogs use a `keys,<locale...>` header and imported catalogs are registered for runtime loading. | Use a repository CSV catalog with `ko` and `en`. | Recheck only after a Godot major-version change. |
| [Godot TranslationServer reference](https://docs.godotengine.org/en/stable/classes/class_translationserver.html) | Loaded translations can be switched at runtime with `TranslationServer.set_locale()`. | Language changes apply immediately without restarting. | Recheck only after a Godot major-version change. |

## Locked Decisions

| Topic | Final decision | Rationale |
| --- | --- | --- |
| Supported locales | `ko` and `en`; missing or invalid preference resolves to `ko`. | Explicit owner request for Korean default and EN switching. |
| Translation format | `localization/vehicle_stage.csv`, UTF-8 without BOM, with stable semantic keys. | Native Godot import, reviewable copy, no custom localization framework. |
| Runtime locale owner | `PivotSettingsStore` persists `ui.locale`, calls `TranslationServer.set_locale()`, and emits `locale_changed`. | Existing global settings owner already handles persistent user preferences. |
| Live refresh | Static Control text uses translation keys; runtime-composed text translates keys at snapshot/update time. Locale changes trigger UI redraw and the next stage snapshot refresh. | Avoids rebuilding the scene or duplicating translated rendered strings in state. |
| Initial language access | A visible two-option `한국어 / EN` selector appears in deployment; the same control appears in pause/settings and garage settings. | An English user must be able to switch before deploying. |
| HUD hierarchy | Health top-left, one-line objective top-center, compact minimap top-right, unified action rail bottom-center, compact target strip bottom-right. | Maximizes the playable center and removes floating clusters. |
| Boss hierarchy | Boss HUD replaces the ordinary objective and minimap while the boss is alive; objective notifications do not repeat it. | Removes the audited triple-message collision. |
| Modal rule | Deployment, upgrade, pause, result, and garage hide the gameplay HUD. Only the dimmed live world remains behind modal surfaces. | Prevents clipped target panels and false actionable HUD. |
| Deployment interaction | Weapon cards select; a separate primary command deploys. Selection has shape/text/focus treatment, not color alone. | Separates comparison from commitment and preserves keyboard clarity. |
| Upgrade layout | Three compact equal-width cards show family, title, one effect paragraph, and number key. | Keeps the real decision visible at 960x540. |
| Pause layout | Resume and restart lead; audio and language form a distinct settings group; abort uses danger styling. | Separates routine, settings, and destructive intents. |
| Result layout | Outcome, permanent reward, concise run facts, and action row form distinct groups. | Promotes the reward and removes the prose pile. |
| Garage layout | Loadout and module status form the main column; settings form a separate compact group; swap and launch share one footer action row. | Removes empty space and mixed hierarchy without inventing inventory. |
| Responsive target | 960x540 is the compact minimum, 1280x720 the reference, 1920x1080 the expanded view. Type does not scale below 13 px and routine controls remain at least 44 px. | Existing product acceptance plus Korean text-fit requirement. |
| Non-scope | No gameplay tuning, map geometry, new inventory, new settings screen, save migration, touch UI, or external dependency. | Keeps the change coherent and reversible. |

## Rejected Alternatives

| Alternative | Why viable | Why rejected |
| --- | --- | --- |
| Custom dictionaries in GDScript | Easy to prototype. | Competes with Godot localization, scatters copy, and weakens import/export tooling. |
| Use OS locale on first run | Familiar consumer default. | Conflicts with the explicit Korean-default requirement. |
| Keep HUD behind translucent modals | Preserves context. | Current captures prove it produces duplicate and clipped state; the world itself provides sufficient context. |
| Add a new main/settings screen | Could centralize locale and audio. | Adds a new flow outside the current short proof and is unnecessary for the requested correction. |
| Scale the complete 1280 UI uniformly at 960 | Minimal code. | Current 960 captures show unreadably small text and unchanged information density. |

## Architecture and Ownership

| Concern | Final owner | Contract |
| --- | --- | --- |
| Translation catalog | `localization/vehicle_stage.csv` | Contains every current user-facing Stage 1 key in Korean and English. |
| Locale persistence | `scripts/autoload/pivot_settings_store.gd` | `ui_locale`, supported-locale validation, immediate apply, saved preference, change signal. |
| Upgrade copy | `scripts/vehicle/vehicle_stage_rules.gd` | IDs and effects remain stable; display fields become translation keys. |
| Stage runtime copy | `scripts/vehicle/vehicle_stage_one.gd` | Produces translated objectives, notifications, names, state labels, buffs, and result values without changing gameplay. |
| Screen composition | `scripts/ui/vehicle_stage_ui.gd` | Preserves existing outward signals, owns selectors, focus, visibility, and responsive layout. |
| Component styling | `art/ui/production/vehicle_stage_theme.tres` | Adds selected and danger states while retaining the ceramic palette and font. |
| Durable product/UI contract | `docs/product/vehicle_stage_one_experimental_spec.md`, `docs/design/UI_VISUAL_SYSTEM.md` | Records Korean-first locale and revised HUD/modal rules. |
| Validation | `tools/validation/validate_vehicle_stage_one.gd` | Verifies locales, translation coverage, modal HUD visibility, focus, target size, and supported viewport layout. |

## Tasks

### Phase 1: Localization foundation

Goal: make Korean the deterministic first-run language and enable persistent live switching.

- [x] **1.1** Add the complete CSV catalog and project registration.
  - As-is: no translation resource exists.
  - To-be: all current user-facing UI, stage, card, enemy, pickup, boss, result, and garage copy has `ko` and `en` entries.
  - Accept: both catalogs load headlessly and representative keys translate in both locales.
  - Guard: IDs, input names, and gameplay source strings remain stable.
- [x] **1.2** Extend `PivotSettingsStore` with locale persistence.
  - As-is: audio-only settings with no signal.
  - To-be: missing/invalid values use `ko`; `set_ui_locale()` immediately applies, persists, and emits once on change.
  - Accept: validator proves `ko` default, `en` switch, and invalid fallback.
  - Guard: Master/SFX loading and persistence remain unchanged.
- [x] **1.3** Convert rules and stage display data to translation keys.
  - As-is: English rendered copy is embedded in gameplay and upgrade definitions.
  - To-be: translation occurs only at presentation boundaries while stable IDs own behavior.
  - Accept: grep and validator find no known English display literal outside the catalog/capture expectations.
  - Guard: all upgrade and encounter behavior tests pass unchanged.

Batch acceptance: Korean renders as the initial locale and EN can be applied without restarting.

Batch guard: no new runtime dependency or translated gameplay identifier is introduced.

### Phase 2: Combat HUD safe frame

Goal: recover the central play space and expose one copy of each actionable fact.

- [x] **2.1** Recompose health, objective, minimap, target, buffs, and action rail.
  - As-is: large floating clusters compete with world geometry and shrink poorly.
  - To-be: compact anchored clusters and a single bottom rail retain health, map, action state, target, and buffs.
  - Accept: no HUD cluster overlaps another or the supported viewport boundary in either locale.
  - Guard: every existing snapshot fact remains represented or is intentionally redundant and removed.
- [x] **2.2** Make boss HUD replace ordinary top-center information.
  - As-is: objective, boss bar, minimap, and notification compete.
  - To-be: one boss strip replaces objective and minimap; zone notifications do not repeat it.
  - Accept: boss capture contains one name, one health bar, and one pattern/state line.
  - Guard: damage warnings and world-space telegraphs remain unchanged.
- [x] **2.3** Enforce modal visibility rules.
  - As-is: upgrade and pause retain actionable-looking gameplay HUD.
  - To-be: every modal hides HUD and restores it only on gameplay resume.
  - Accept: debug visibility contract and captures show no clipped target/action/goal clusters behind modals.
  - Guard: modal focus and current game mode remain unchanged.

Batch acceptance: Korean and English gameplay/boss captures pass at 960 and 1280.

Batch guard: playable center remains unobstructed and no status relies on color alone.

### Phase 3: Modal and settings layouts

Goal: give every non-combat screen one clear task and common composition.

- [x] **3.1** Rebuild deployment with selection then commitment.
  - Accept: two compact choices, visible selection text/shape, initial locale selector, and one deploy command fit at 960.
  - Guard: exactly one deployment signal emits per deploy action.
- [x] **3.2** Rebuild upgrade and pause/settings.
  - Accept: upgrade cards fit without underlying HUD; pause separates resume/restart, audio/language, and danger action with stable focus order.
  - Guard: sliders and settings persistence remain functional.
- [x] **3.3** Rebuild result and garage.
  - Accept: permanent reward is prominent, run facts scan as groups, loadout/settings are distinct, and action rows do not become stacked full-width piles.
  - Guard: replay, garage, primary swap, and module display preserve existing behavior.

Batch acceptance: all five modal surfaces fit both locales at 960, 1280, and 1920 with 44 px controls.

Batch guard: no new unsupported screen, inventory, or setting appears.

### Phase 4: Durable contracts and deterministic validation

Goal: make localization and layout requirements enforceable.

- [x] **4.1** Update product and visual-system documents.
  - Accept: Korean-first locale, language entry points, HUD replacement behavior, and modal visibility are explicit.
  - Guard: selected art direction and combat contracts remain unchanged.
- [x] **4.2** Extend vehicle validation.
  - Accept: the validator checks catalog registration, both locales, fallback, selectors, modal HUD state, responsive safe frame, focusables, and prior 87 contracts.
  - Guard: tests do not depend on translated rendered sentences when stable keys/IDs are available.

Batch acceptance: deterministic validation names any missing key, layout collision, or visibility regression.

### Phase 5: Render, build, quality, and completion

Goal: prove the implementation in both languages and leave a coherent commit.

- [x] **5.1** Capture every screen in Korean and English at 1280x720 plus compact Korean at 960x540.
- [x] **5.2** Inspect text fit, hierarchy, focus, clipping, modal layers, and boss replacement; correct only observed blockers.
- [x] **5.3** Run Web release export and built HTTP boot on the fastrun `codex` lane.
- [x] **5.4** Run task-scoped code quality review, complete this plan, and commit only task-owned files.

Batch acceptance: UIUX gate passes with rendered evidence, Web export/boot succeeds, and only scoped files are committed.

Batch guard: pre-existing `.import` churn remains unstaged and no remote push occurs.

## Validation Cadence

Inner loop:

- `.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_one.gd`
- `.\tools\godot.ps1 --path . --headless --quit-after 2`
- `git diff --check`

Final gates:

- Native captures: deployment, gameplay, installations, upgrade, pause/settings, field boss, stage boss, result, and garage in `ko` and `en` at 1280x720; `ko` at 960x540.
- Gameplay tests: `VEHICLE_STAGE_VALIDATION_OK` with every prior contract retained.
- Production build: `.\tools\godot.ps1 --path . --headless --export-release Web build/web/index.html`.
- Built boot: HTTP 200 from the registered fastrun-manager `codex` lane and exact task-owned process cleanup.
- Lifecycle/Git: plan status and evidence truthful, `git diff --cached --check`, explicit staged-file audit, scoped commit.

## Predetermined Error Handling and Contingencies

| Trigger | Required response | Limit |
| --- | --- | --- |
| CSV import does not register generated translations | Inspect the generated `.import` destination paths and add those exact `.translation` resources to `project.godot`; do not add a custom localization framework. | Escalate only if Godot cannot load either generated locale after a clean import. |
| Korean text clips at 960 | Shorten secondary copy, enable word-smart wrapping, or use compact modal spacing; never reduce routine text below 13 px or controls below 44 px. | Escalate only if required actions still cannot fit. |
| Locale changes but dynamic HUD copy remains stale | Rebuild the current snapshot immediately on `locale_changed` and redraw custom Controls. | Do not reload the scene or reset gameplay. |
| Modal HUD remains visible | Centralize surface visibility in `hide_all_modals()` plus each `show_*()` owner and add a debug contract. | Do not patch individual child visibility ad hoc. |
| Existing gameplay validator fails | Correct only the localization/layout regression and keep the previous assertion. | Escalate if evidence proves the failure predates this task. |
| Godot regenerates unrelated imports | Leave all pre-existing `.import` changes unstaged. | Never clean or revert user-owned churn. |

## Progress

- [x] Phase 1: localization foundation.
- [x] Phase 2: combat HUD safe frame.
- [x] Phase 3: modal and settings layouts.
- [x] Phase 4: durable contracts and validation.
- [x] Phase 5: rendered evidence, build, quality, and commit.
- [x] Final gates.

## Completion Criteria

- [x] Korean is the first-run default and EN switching persists and applies immediately.
- [x] Every current user-facing string has a Korean and English catalog entry.
- [x] Every audited screen has one clear task, no duplicate HUD state, and no clipped or hidden required content.
- [x] Both locales fit 960x540, 1280x720, and 1920x1080 with visible focus and 44 px controls.
- [x] Existing combat, route, input, rewards, and persistence behavior remains valid.
- [x] Native captures, validator, Web export, built boot, documentation, and staged-file audit pass.

## Decision Notes

- The final catalog contains 163 complete unique keys with no duplicate, blank, or missing referenced UI entry.
- The vehicle validator now passes 99 contracts, including all prior gameplay checks plus modal visibility, locale entry points, boss replacement, and responsive safe-frame checks.
- Native review evidence contains 27 captures: all nine screens in Korean and English at 1280x720, plus all nine in Korean at 960x540.
- The release Web export and HTTP boot on registered `codex` port `13029` passed. The in-app browser automation runtime could not attach because its local kernel-assets path was unavailable; native captures and the built HTTP response were used as the strongest safe substitutes, and no test server was left running.
- The task-scoped quality pass removed side effects from locale-only upgrade refresh, strengthened compact minimap assertions, and kept locale persistence inside the existing settings owner.

## Residual Risks

- Browser-specific WebGL rendering was not interactively inspected in this run because the browser-control runtime failed before page attachment. Native Godot rendering, headless boot, Web release export, and built HTTP response all passed.
- Korean and English are complete for the current Vehicle Stage 1. New user-facing gameplay copy still requires a catalog key and both translations.

## Open Questions

No material implementation questions remain. Adding another locale, a new main/settings screen, translated voice, touch layout, or new gameplay content requires a new owner decision.

## Stop Conditions

Complete when all five phases, completion criteria, and final gates pass and the scoped commit exists.

Escalate only if a required result demands gameplay, new-screen, dependency, destructive Git, or remote-push authority outside this plan.

Do not stop while a Korean/English clipping issue, modal-layer regression, capture correction, or scoped validator fix remains within this contract.

## Handoff

```text
Goal: Deliver the complete current Vehicle Stage 1 UI in Korean by default with live persistent English switching and a corrected responsive layout.

Read first: this plan, docs/product/vehicle_stage_one_experimental_spec.md, docs/design/UI_VISUAL_SYSTEM.md.

Execute exactly: phases 1-5 without changing combat, map, reward, input, or persistence identities.

Validate with: both-locale translation checks, the extended vehicle validator, native screen captures at 960/1280, Web release export, and built HTTP boot.

Stop when: every completion criterion passes, the plan is done, and only task-owned files are committed.
```
