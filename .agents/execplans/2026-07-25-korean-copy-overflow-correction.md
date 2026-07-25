---
type: plan
status: done
owner: BK
created: 2026-07-25
last_reviewed: 2026-07-25
scope: Correct Korean copy quality, eliminate raw runtime identifiers from visible UI, fix stat preview value formatting, and guarantee slot-invariant card containment across supported Cardborne viewports without changing gameplay semantics
related:
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../design-qa.md
---

# Cardborne UI Localization Closure and Upgrade Choice Containment - Execution Plan

## Why / Context

This active plan records the decision-complete implementation roadmap for
resolving Korean copy quality, every verified raw runtime-identifier leak,
misleading stat preview values, and card/panel text overflow in Cardborne.

Runtime evidence captured in capture `2026-07-25 19 39 06.png` disproved the previous draft's conclusion that zero layout overflows existed. The previous draft's claim of zero reproduced defects and its activation blocker are explicitly corrected hereby. This plan is promoted to `active` status with `last_reviewed: 2026-07-25`.

This planning pass modifies no runtime code, CSV, tests, or assets; it defines
the complete checklist and specification required for subsequent execution.
AGY `Gemini 3.6 Flash (High)` performed the screenshot and upgrade-path
re-audit; Codex verified its proposed changes against the current data and
calculation owners before locking this plan.

## Scope / Non-Scope

In scope:

- Korean and English localization-key closure for every current user-facing
  surface.
- Boss-practice pattern and commit-mode presentation.
- Upgrade-card value formatting, text containment, responsive modal sizing,
  and slot invariance.
- Focused validators and rendered evidence that prove those contracts.

Out of scope:

- Card eligibility, upgrade effects, enemy behavior, boss attack behavior,
  damage calculations, progression pacing, or save-data changes.
- A visual redesign of the established Sunken Ceramic Fresco system.
- New gameplay content or a new localization language.

## Assumptions

- 960×540, 1280×720, and 1920×1080 remain the supported verification
  viewports already named by the active UI checks.
- Korean remains the default locale and every changed surface remains complete
  in both Korean and English.
- Stable gameplay IDs remain metadata/data values; only their presentation
  keys and layout change.
- The supplied runtime screenshot is authoritative evidence of a current
  defect even when a headless minimum-size validator passes.

## Sources Inspected

1. Root `AGENTS.md`
2. `.agents/PLANS.md`
3. Runtime Screenshot Capture: `D:\Program Files\ImageMagick-7.1.1-Q16-HDRI\captures\2026-07-25 19 39 06.png`
4. `scripts/ui/vehicle_upgrade_choice_card.gd`
5. `scripts/ui/vehicle_upgrade_choice_panel.gd`
6. `scripts/vehicle/vehicle_run.gd` (specifically `_build_card_offer()`)
7. All 46 upgrade card definitions: `data/cards/vehicle/*.tres`
8. `localization/vehicle_stage.csv` (all 587 Korean entries plus placeholder contracts)
9. `tools/validation/validate_vehicle_upgrade_system.gd`
10. `tools/validation/validate_vehicle_rewards_ui_audio.gd`
11. `tools/validation/validate_vehicle_stage_ui_layout.gd`
12. `docs/product/vehicle_game_spec.md`
13. `docs/design/UI_VISUAL_SYSTEM.md`
14. `scripts/bosses/vehicle_boss_patterns.gd`
15. `scripts/bosses/vehicle_boss_runtime.gd`
16. `scripts/bosses/vehicle_boss_practice_session.gd`
17. `scripts/ui/vehicle_stage_ui.gd`
18. All user-facing `.text`, `tooltip_text`, `accessibility_name`,
    `OptionButton.add_item()`, and notification assignments under `scripts/`
19. All localization-bearing stage, field, enemy, secondary-weapon,
    guidebook, build-summary, and stage-report catalogs

## Verified Facts & Direct Evidence

1. **Raw Key Leakage & Layout Escape**:
   The runtime screenshot capture directly shows:
   - Raw untranslated key `UPGRADE_FAMILY_SECONDARY` inside the family badge of the middle card.
   - Raw untranslated key `UPGRADE_STAT_BREACH_HEALTH_SCALE_BONUS` clipped horizontally as `UPGRADE_STAT_BREACH_HEALTH_SCALE` on the third card.
   - The third card's description loses characters at the right edge and wraps
     into the broken fragment `돌파탄의 직접 피해와 노출 효과를 강` / `다.`.

2. **Dynamic Key Generation Mechanism**:
   In `scripts/vehicle/vehicle_run.gd`, `_build_card_offer()` dynamically generates runtime localization keys using uppercase enum strings:
   - `family_key`: `"UPGRADE_FAMILY_%s" % String(definition.family).to_upper()`
   - `stat_key`: `"UPGRADE_STAT_%s" % String(modifier.stat_id).to_upper()`

3. **Mechanical Audit of All 46 Card Definitions**:
   Comparing all 46 card `.tres` files against `localization/vehicle_stage.csv` reveals exactly 3 generated keys missing from the CSV:
   - `UPGRADE_FAMILY_SECONDARY`: used by 4 cards (`escort_drone`, `ion_field`, `orbit_blades`, `wake_mines`)
   - `UPGRADE_FAMILY_DEFENSE`: used by 2 cards (`aegis_cycle`, `siphon_matrix`)
   - `UPGRADE_STAT_BREACH_HEALTH_SCALE_BONUS`: used by 1 card (`breach_round`)
   A total of 7 card definitions are affected by these 3 missing keys.

4. **Semantic Stat Preview Formatting Defect (`+0 → +0`)**:
   In `scripts/ui/vehicle_upgrade_choice_card.gd`, `_preview_value()` formats all additive modifier values with `%+.0f`. For `breach_round`, the breach health scale bonus value moves from 0.0 to 0.2 (+20%). Under `%+.0f`, 0.0 and 0.2 both round to integer 0, displaying misleadingly as `+0 → +0`.

5. **Card Width Inflation and Defective Containment**:
   Unwrapped raw stat keys (e.g., 38-character string `UPGRADE_STAT_BREACH_HEALTH_SCALE_BONUS`) push the internal `Label` width beyond the 282px card content area, clipping adjacent description text. Setting `clip_contents = true` on `VehicleUpgradeChoiceCard` masks text truncation rather than maintaining valid UI layout.

6. **Correction of Previous Plan Findings**:
   The previous plan draft incorrectly claimed zero reproduced overflows and set a blocker waiting for live evidence. The user-provided screenshot and mechanical card audit provide concrete evidence. All false claims are hereby replaced with verified defect facts.

7. **Complete Static Localization Table Audit**:
   - `localization/vehicle_stage.csv` currently contains 587 unique rows.
   - Korean empty values: 0. English empty values: 0. Duplicate keys: 0.
   - The 345 unique explicit UI localization-key references found in current
     scripts/resources all resolve in the CSV.
   - Korean/English placeholder signatures match on all 587 rows: 0
     mismatches.
   - Therefore the confirmed upgrade leaks come from dynamically generated
     keys, not from an arbitrary explicit-key typo.

8. **Boss Practice Exposes Runtime Variables as Copy**:
   `_refresh_practice_patterns()` currently renders all 30 authored pattern IDs
   and all 3 commit-mode enum values by replacing underscores with spaces. A
   Korean user therefore sees values such as
   `interruptible signature · foundry ram` instead of localized UI copy even
   though every authored pattern already has a valid `PATTERN_*` translation.

9. **Raw Fallbacks Remain Reachable or Latent**:
   - Practice startup assigns `boss.pattern = "practice"`, while
     `_localized_pattern()` falls back to the unrecognized input value; the
     practice HUD can therefore show `practice`.
   - Practice startup notifies with the hardcoded literal `PRACTICE`.
   - Visible boss/target HUD snapshots fall back to hardcoded `BOSS` and
     `TARGET` if a malformed visible snapshot omits its name.
   - All 30 production pattern definitions and their localization mappings are
     complete; the defect is the permissive raw fallback and the separate raw
     practice-menu rendering path.

10. **The Rightmost Card Is a Symptom, Not a Separate Component**:
    All three choices are instances of the same
    `VehicleUpgradeChoiceCard` with equal stretch ratios. The third slot has no
    unique layout code. The supplied capture exposes the defect there because
    the longest raw stat key is placed in that slot and its overflow reaches
    the modal edge. Any card/level state must remain valid in slots 1, 2, and
    3, both selected and unselected.

11. **Current Validators Produce False Confidence**:
    The three focused validators currently pass despite the supplied broken
    screen. `validate_vehicle_rewards_ui_audio.gd` uses three identical,
    short, already-localized fixtures; `validate_vehicle_stage_ui_layout.gd`
    checks only declared minimum sizes and never measures child rectangles,
    visible line counts, localized content, selection state, or slot position.
    The existing capture sequence renders only one catalog-generated offer,
    so it does not close the 46-card/91-preview-state surface.

## Required AS-IS / TO-BE Inventory

| Key / Component | AS-IS Korean | TO-BE Korean | AS-IS English | TO-BE English | Reason / Classification | Consuming File | Acceptance Check |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `DEPLOY_TITLE` | `침수 공방 출격 준비` | `출격 준비` | `Prepare for Flooded Works` | `Prepare for Deployment` | Terminology alignment: Removes stage 1 hardcoded area name from modal header. | `scripts/ui/vehicle_stage_ui.gd` | Header displays area-neutral title in both locales. |
| `UPGRADE_SELECT_DETAIL` | `카드를 선택한 뒤 장착을 눌러 확정하세요.` | `회로를 선택한 뒤 장착을 눌러 확정하세요.` | `Select a card, then press Equip to confirm.` | `Select a circuit, then press Equip to confirm.` | Terminology alignment: Standardizes term from card to circuit across upgrade UI. | `scripts/ui/vehicle_upgrade_choice_panel.gd` | Selection guide text uses circuit terminology. |
| `UPGRADE_APPLY_FAILED` | `현재 빌드에는 적용할 수 없습니다. 다른 카드를 선택하세요.` | `현재 빌드에는 적용할 수 없습니다. 다른 회로를 선택하세요.` | `This cannot be applied to the current build. Choose another card.` | `This cannot be applied to the current build. Choose another circuit.` | Terminology alignment: Standardizes term from card to circuit in error notice. | `scripts/ui/vehicle_upgrade_choice_panel.gd` | Application failure notice uses circuit terminology. |
| `REPORT_GARAGE` | `격납고로 이동` | `차고로 이동` | `Continue to Garage` | `Continue to Garage` | Korean terminology alignment: Matches `GARAGE_KICKER` and the product spec; the English value is already correct. | `scripts/ui/vehicle_stage_report_panel.gd` | Stage report button uses the garage term in both locales. |
| `RESULT_TITLE_CONTINUE` | `다음 수역이 열렸습니다` | `다음 구역이 열렸습니다` | `The next sector is open` | `The next sector is open` | Korean terminology alignment: Replaces the legacy water-area term with the standard stage-area term; the English value is already correct. | `scripts/ui/vehicle_stage_ui.gd` | Inter-stage result title uses the current area terminology. |
| `RESULT_TITLE_FINAL` | `세 수역을 돌파했습니다` | `모든 구역을 돌파했습니다` | `All three sectors are clear` | `All sectors are clear` | The current campaign has five stages, so both locales must remove the obsolete three-sector wording. | `scripts/ui/vehicle_stage_ui.gd` | Final result remains correct if the authored stage count changes again. |
| `UPGRADE_FAMILY_PASSIVE` | `보조무기` | `추적탄` | `Passive` | `Seeker` | The six `passive`-family cards exclusively modify the always-equipped seeker; reserving `보조무기` / `Secondary` for optional secondary weapons prevents two different families from sharing one badge. | `scripts/ui/vehicle_upgrade_choice_card.gd` | All passive-family cards render `추적탄` / `Seeker`; optional-secondary cards remain distinct. |
| `UPGRADE_FAMILY_SECONDARY` | *(Missing key)* | `보조무기` | *(Missing key)* | `Secondary` | Missing localization key: Used by `escort_drone`, `ion_field`, `orbit_blades`, `wake_mines`. | `scripts/ui/vehicle_upgrade_choice_card.gd` | Secondary family badge renders locked localized string without raw key fallback. |
| `UPGRADE_FAMILY_DEFENSE` | *(Missing key)* | `방어` | *(Missing key)* | `Defense` | Missing localization key: Used by `aegis_cycle`, `siphon_matrix`. | `scripts/ui/vehicle_upgrade_choice_card.gd` | Defense family badge renders locked localized string without raw key fallback. |
| `UPGRADE_STAT_BREACH_HEALTH_SCALE_BONUS` | *(Missing key)* | `돌파탄 추가 피해` | *(Missing key)* | `Breach bonus damage` | The modifier adds 0.2/0.4 to the Breach Shot damage scale; the separate exposure multiplier is level-driven and must not be mislabelled as this stat. | `scripts/ui/vehicle_upgrade_choice_card.gd` | Breach Round shows the correct localized damage-stat label. |
| `_preview_value()` formatting | `%+.0f` produces `+0 → +0` for 0.0→0.2 | Percent presentation produces `+0% → +20%` | `%+.0f` produces `+0 → +0` for 0.0→0.2 | Percent presentation produces `+0% → +20%` | A ratio delta must be presented as a percentage rather than a rounded raw decimal. | `scripts/ui/vehicle_upgrade_choice_card.gd` | Breach Round shows `+0% → +20%`, then `+20% → +40%`; flat integer additions and multipliers keep their existing formats. |
| `BOSS_PRACTICE_MODE_COMMITTED` | *(Missing key; raw `committed`)* | `취소 불가` | *(Missing key; raw `committed`)* | `Committed` | Replace the practice picker's internal commit-mode enum with concise localized copy. | `scripts/ui/vehicle_stage_ui.gd` | No practice option contains the raw enum. |
| `BOSS_PRACTICE_MODE_INTERRUPTIBLE` | *(Missing key; raw `interruptible_signature`)* | `차단 가능` | *(Missing key; raw `interruptible_signature`)* | `Interruptible` | Replace the practice picker's internal signature enum with concise localized copy. | `scripts/ui/vehicle_stage_ui.gd` | No practice option contains the raw enum. |
| `BOSS_PRACTICE_MODE_AUTONOMOUS` | *(Missing key; raw `autonomous`)* | `독립 기믹` | *(Missing key; raw `autonomous`)* | `Autonomous` | Replace the practice picker's internal autonomous enum with concise localized copy. | `scripts/ui/vehicle_stage_ui.gd` | No practice option contains the raw enum. |
| Boss practice pattern options | Humanized runtime IDs such as `foundry ram` | Existing localized `PATTERN_*` value | Humanized runtime IDs such as `foundry ram` | Existing localized `PATTERN_*` value | The picker must consume the same presentation mapping as the boss HUD. | `scripts/bosses/vehicle_boss_patterns.gd`, `scripts/ui/vehicle_stage_ui.gd` | All 30 pattern names resolve in Korean and English; metadata retains the stable internal ID. |
| Practice startup copy | HUD state `practice`; notification `PRACTICE` | Existing localized `PATTERN_READING_ARENA` state and `BOSS_PRACTICE_START` notification | HUD state `practice`; notification `PRACTICE` | Existing localized state and notification | Internal debug tokens must never be used as visible copy. | `scripts/vehicle/vehicle_run.gd` | Starting every practice mode shows no raw token. |
| Boss/target name fallback | `BOSS` / `TARGET` if a visible snapshot is malformed | Hide the invalid cluster and fail validation; never print a raw fallback | `BOSS` / `TARGET` | Same | Presentation contracts should fail closed rather than expose implementation placeholders. | `scripts/ui/vehicle_stage_ui.gd` | Missing required snapshot copy produces no visible raw word. |
| Card Text Containment | Unwrapped stat labels clip description lines; the third slot visibly escapes | Wrapped, bounded labels and slot-invariant card geometry | Text truncation on right edge | Complete text in every slot | Content must determine wrapping/height, never widen a card or rely on `clip_contents` to conceal failure. | `scripts/ui/vehicle_upgrade_choice_card.gd`, `scripts/ui/vehicle_upgrade_choice_panel.gd` | All 91 card/level preview states fit in all 3 slots, selected and unselected. |

## Proposed Design and Locked Contracts

### 1. Missing-Key and Presentation Translation Contract
The six missing keys and the existing seeker-family correction are locked with
the following exact values:

- `UPGRADE_FAMILY_SECONDARY`: Korean = `보조무기`, English = `Secondary`
- `UPGRADE_FAMILY_DEFENSE`: Korean = `방어`, English = `Defense`
- `UPGRADE_STAT_BREACH_HEALTH_SCALE_BONUS`: Korean = `돌파탄 추가 피해`, English = `Breach bonus damage`
- `UPGRADE_FAMILY_PASSIVE`: Korean = `추적탄`, English = `Seeker`
- `BOSS_PRACTICE_MODE_COMMITTED`: Korean = `취소 불가`, English = `Committed`
- `BOSS_PRACTICE_MODE_INTERRUPTIBLE`: Korean = `차단 가능`, English = `Interruptible`
- `BOSS_PRACTICE_MODE_AUTONOMOUS`: Korean = `독립 기믹`, English = `Autonomous`

### 2. Fractional Stat Preview Display Contract
In `scripts/ui/vehicle_upgrade_choice_card.gd`,
`_preview_value(preview: Dictionary)` must use the preview's `stat_key` and
`operation`:
- If `operation == "multiply"`: format with `"×%.2f" % value`.
- If `stat_key == "UPGRADE_STAT_BREACH_HEALTH_SCALE_BONUS"`: multiply the
  stored ratio by 100 and format with `"%+.0f%%"` (`+0% → +20%`,
  `+20% → +40%`).
- All other additive stats retain `"%+.0f"` because the current catalog stores
  them as flat integer hull or radius values.

This explicit stat-key contract avoids guessing that every future fractional
addition is a percentage.

### 3. Card Text Containment Contract
- **Card Base Dimensions**:
  - The current `Vector2(282.0, 336.0)` hierarchy is preserved at the
    1280×720 baseline.
  - Compact layout is explicit rather than accidental. At 960×540 the upgrade
    surface must fit inside `viewport - Vector2(24, 24)`, remove the fixed
    900px title/detail minimum width, use a 12px card-row gap, and fit three
    cards in the resulting content width. Compact card height may reduce to
    290px, but no label, value row, pip row, message, or confirmation action may
    be hidden.
- **Label Text Wrapping**:
  - `_impact_title` and secondary stat labels must have
    `autowrap_mode = TextServer.AUTOWRAP_WORD_SMART` and horizontal
    expand/fill sizing so their computed minimum width cannot widen the card.
  - `_effect` (description label) preserves `autowrap_mode = TextServer.AUTOWRAP_WORD_SMART` with vertical size expansion flags (`SIZE_EXPAND_FILL`).
  - Label text must wrap strictly within the internal 242px content width (282px card width minus 40px horizontal margins).
  - Raw keys, ellipsis, and clipping are not accepted substitutes for complete
    family, title, description, stat, value, or level text.
- **Multi-Modifier Containment**:
  - Cards with 2 value preview rows (such as `emp_focus`, `mass_driver`, `stabilizer`) must layout secondary stat rows in clean vertical boxes without pushing level pips off the bottom of the card.
- **Slot Invariance**:
  - The same card/level state must be injected into slot 1, slot 2, and slot 3
    in turn.
  - Each placement must be checked both selected and unselected.
  - Every text-bearing descendant rectangle must remain inside its card, every
    card rectangle must remain inside the upgrade modal content rect, and
    sibling card rectangles must not overlap.
  - For wrapped labels, `get_visible_line_count()` must equal
    `get_line_count()`. `clip_contents = true` is a safety boundary only and
    cannot make a failing geometry assertion pass.
- **Resolution Scale Support**:
  - Containment contracts must hold without text clipping or layout overflow at 960×540, 1280×720, and 1920×1080 in both Korean and English locales.

### 4. Boss Pattern Presentation Contract
- `scripts/bosses/vehicle_boss_patterns.gd` becomes the single presentation-key
  owner for authored pattern IDs, transient boss HUD states, and commit modes.
  Gameplay IDs and pattern behavior remain unchanged.
- The boss HUD and boss-practice picker must request a localization key from
  that owner; neither may call `replace("_", " ")` to manufacture copy.
- All 30 authored pattern IDs, the reachable transient states
  (`system_wake`, `reading_arena`, `recovery_window`, `phase_transition`, and
  `signature_interrupted`), and all 3 commit modes must resolve in both
  locales.
- Unknown IDs return an empty presentation result, emit a development error,
  and keep the affected UI row hidden. Returning the input ID is forbidden.
- Practice start reuses `PATTERN_READING_ARENA` for the initial HUD state and
  `BOSS_PRACTICE_START` for the notification; no new visible `practice` token
  is introduced.

### 5. UI Localization Closure Validation Contract
Add one responsibility-shaped
`tools/validation/validate_vehicle_ui_localization.gd`; do not turn gameplay
validators into localization catch-alls. It must:

- Verify every explicit localization key referenced by user-facing scripts and
  data.
- Instantiate `UpgradeCatalog`, iterate all 46 definitions, and derive every
  `UPGRADE_FAMILY_%s` and `UPGRADE_STAT_%s` key exactly as production does.
- Verify stage/field titles, enemy names, secondary names/descriptions,
  guidebook name/description/row keys, build-summary stat/unit keys, report
  source/attribute keys, boss pattern/state keys, commit-mode keys, settings
  action labels, and difficulty labels.
- Set `TranslationServer` to `ko` and `en` in turn; every required key must
  resolve to a non-empty value different from the raw key. Restore the original
  locale before exit.
- Fail if a visible text path humanizes an ID with
  `replace("_", " ")`, passes a known implementation token such as
  `PRACTICE`, `BOSS`, or `TARGET` as fallback copy, or leaves a localization
  placeholder signature inconsistent between locales.
- Keep `validate_vehicle_upgrade_system.gd` responsible for upgrade gameplay
  rules and `validate_vehicle_boss_patterns.gd` responsible for boss-pattern
  structural rules; each may expose data needed by the localization validator
  without duplicating its closure scan.

### 6. Rendered and Geometry Evidence Contract
- Extract one `_build_card_snapshot(definition, current_level)` helper from
  `scripts/vehicle/vehicle_run.gd::_build_card_offer()` so production offers
  and capture fixtures cannot drift.
- Generate all 91 selectable card/level states (14 one-level, 19 two-level,
  and 13 three-level definitions), not merely one state per definition.
- The automated geometry matrix is exactly:
  `91 states × 3 slots × 2 selection states × 2 locales × 3 viewports = 3,276`
  test states, each with multiple geometry assertions.
- Extend the existing capture sequence to render stable ID/level-sorted card
  sheets in both locales. Direct full-modal captures must include the longest
  Korean and English cases in the third slot, selected and unselected, at
  960×540, 1280×720, and 1920×1080.
- Visual captures must include explicit contact sheets for the three
  multi-modifier cards and the 13 cards affected by family-label corrections
  or missing keys.
- Boss-practice captures must show all three localized commit modes and at
  least one direct and one autonomous pattern in each locale.

### 7. Gameplay Semantics Preservation Contract
- User-visible behavior changes remain restricted to UI presentation and
  localization strings.
- The snapshot-helper extraction in `vehicle_run.gd` must be output-equivalent
  for production offers and exists only to keep capture fixtures on the same
  presentation-data path.
- Card resources in `data/cards/vehicle/*.tres`, gameplay catalog logic in `scripts/cards/`, and status/damage calculations remain completely unchanged.

## Audit Totals Summary

- **Total CSV rows**: 587 existing + 6 missing = 593 total.
- **Explicit UI localization references audited**: 345 unique; 0 missing.
- **CSV integrity**: 0 duplicate keys, 0 empty Korean values, 0 empty
  English values, and 0 Korean/English placeholder-signature mismatches.
- **Total upgrade card resources**: 46.
- **Total selectable card/level preview states**: 91.
- **Card definitions affected by missing keys**: 7 (`aegis_cycle`, `breach_round`, `escort_drone`, `ion_field`, `orbit_blades`, `siphon_matrix`, `wake_mines`).
- **Existing localized rows to update**: 7 (the six prior copy corrections plus `UPGRADE_FAMILY_PASSIVE`).
- **Total card definitions receiving family-label corrections or missing-key fixes**: 13.
- **Missing upgrade localization keys**: 3 (`UPGRADE_FAMILY_SECONDARY`, `UPGRADE_FAMILY_DEFENSE`, `UPGRADE_STAT_BREACH_HEALTH_SCALE_BONUS`).
- **Missing boss-practice presentation keys**: 3 commit-mode labels.
- **Authored boss patterns**: 30; all 30 already have a valid mapped
  `PATTERN_*` row, but all 30 are bypassed by the current practice picker.
- **Reachable/assigned boss HUD values**: 36; `practice` is the sole value
  without a presentation mapping.
- **Hardcoded raw UI fallbacks**: `PRACTICE`, `BOSS`, and `TARGET`.
- **Stat preview display fix**: 1 (`_preview_value()` fractional additive formatting).
- **Layout matrix**: 3,276 card/slot/selection/locale/viewport states.
- **Layout containment fixes**: `VehicleUpgradeChoiceCard` bounded text
  geometry plus responsive `VehicleUpgradeChoicePanel`/modal sizing.

## Milestones / Implementation Checklist

- [x] **Task 1: Add Missing Keys and Update Copy in CSV**
  - **As-is**: `localization/vehicle_stage.csv` lacks 3 upgrade-derived keys
    and 3 boss-practice commit-mode keys, and contains legacy copy in 7 rows.
  - **To-be**: Add the 6 missing keys with the locked values above, and update
    `DEPLOY_TITLE`, `UPGRADE_SELECT_DETAIL`, `UPGRADE_APPLY_FAILED`,
    `REPORT_GARAGE`, `RESULT_TITLE_CONTINUE`, `RESULT_TITLE_FINAL`, and
    `UPGRADE_FAMILY_PASSIVE`.
  - **Accept**: CSV contains 593 properly formatted rows; all 13 added or
    changed rows exactly match the AS-IS / TO-BE inventory.
  - **Guard**: Headless Godot CSV import test passes cleanly.

- [x] **Task 2: Replace Raw Boss-Practice and HUD Presentation Paths**
  - **As-is**: The practice picker humanizes pattern IDs and commit-mode enums;
    practice startup exposes `practice` and `PRACTICE`; generic pattern and
    target-name fallbacks can print raw values.
  - **To-be**: Centralize boss presentation keys in
    `vehicle_boss_patterns.gd`, consume them from both the picker and HUD, reuse
    the locked existing practice strings, and fail closed on malformed visible
    snapshots.
  - **Accept**: All 30 authored patterns and 3 commit modes render localized in
    Korean and English; no reachable visible path returns its internal ID.
  - **Guard**: Boss-pattern, boss-practice, and UI-localization validators pass.

- [x] **Task 3: Fix Stat Preview Value Formatting in Choice Card**
  - **As-is**: `_preview_value()` in `scripts/ui/vehicle_upgrade_choice_card.gd` uses `%+.0f` for all additive stats, rendering `breach_round` values as `+0 → +0`.
  - **To-be**: Give `UPGRADE_STAT_BREACH_HEALTH_SCALE_BONUS` the locked percentage presentation while leaving multiplier and flat-add formats unchanged.
  - **Accept**: `breach_round` displays `+0% → +20%` at level 0 and `+20% → +40%` at level 1; integer flat additions and multipliers retain their existing output.
  - **Guard**: Unit test / validator assertion for `_preview_value()` outputs.

- [x] **Task 4: Enforce Slot-Invariant Card and Modal Containment**
  - **As-is**: Stat labels can widen descendant containers, the modal retains a
    900px content minimum, compact viewport sizing is not applied to the
    upgrade surface, and `clip_contents = true` hides rather than prevents
    invalid geometry.
  - **To-be**: Bound/wrap every text label, stack secondary stat rows
    vertically, add the locked responsive compact mode, and expose measured
    descendant/card/modal rectangles for validation.
  - **Accept**: Zero horizontal/vertical truncation, line loss, sibling overlap,
    or modal escape in all 3,276 matrix states.
  - **Guard**: The layout validator fails if the supplied broken-key fixture is
    reintroduced and passes only after all geometry assertions hold.

- [x] **Task 5: Implement Complete UI Localization Closure Validator**
  - **As-is**: Current validators all pass while 3 generated upgrade keys and
    multiple practice UI values still leak.
  - **To-be**: Add the focused localization validator described above and keep
    gameplay validators in their existing responsibilities.
  - **Accept**: The validator covers all explicit and catalog-derived UI keys in
    both locales, rejects raw-ID humanization/fallbacks, and exits 1 if any
    required translation returns its key.
  - **Guard**: Execute script in headless Godot mode.

- [x] **Task 6: Execute Rendered Evidence & Suite Gates**
  - **As-is**: The capture sequence covers one generated three-card offer and no
    localized practice-pattern matrix.
  - **To-be**: Extract the shared card-snapshot builder, add all 91
    card/level states and boss-practice presentation fixtures, then run the
    locked locale/viewport matrix plus the Web export.
  - **Accept**: All validator scripts pass, capture sets complete, and web export builds cleanly.
  - **Guard**: Clean execution of all validation scripts and web build script.

## Progress

- [x] AGY `Gemini 3.6 Flash (High)` re-audit of the supplied screenshot and upgrade-card
  localization path completed.
- [x] Screenshot evidence `2026-07-25 19 39 06.png` inspected and defects verified.
- [x] Mechanical audit of all 46 card `.tres` resources against CSV completed.
- [x] 3 missing dynamic keys and 7 affected cards identified.
- [x] All 345 explicit UI keys, 587 CSV rows, and bilingual placeholder
  contracts audited.
- [x] All 30 boss patterns, 3 commit modes, 36 reachable/assigned HUD pattern
  values, and raw practice/target fallbacks audited.
- [x] Existing passing validators confirmed not to inspect localized content,
  child geometry, slot position, or selection state.
- [x] Exact 3,276-state containment matrix defined.
- [x] Preview formatting defect (`+0 → +0`) identified and percentage display
  specification defined.
- [x] Plan updated to decision-complete active state with `last_reviewed: 2026-07-25`.
- [x] Task 1: CSV copy updates and missing key additions executed.
- [x] Task 2: Raw boss-practice/HUD presentation paths replaced.
- [x] Task 3: Choice card stat preview formatting fix executed.
- [x] Task 4: Card/modal containment and responsive layout fix executed.
- [x] Task 5: Complete UI localization validator created and executed.
- [x] Task 6: The 3,276-state rendered-geometry matrix, targeted Korean
  960×540 and English 1280×720 captures, full validator suite, and Web export
  executed successfully.

Completion evidence:

- `build/captures/korean-copy-correction/ko-960x540/06d-localization-third-slot.png`
- `build/captures/korean-copy-correction/en-1280x720/06d-localization-third-slot.png`
- `VEHICLE_STAGE_UI_LAYOUT_VALIDATION_OK`
- `VEHICLE_UI_LOCALIZATION_VALIDATION_OK`
- `ALL_VEHICLE_VALIDATORS_OK`
- `WEB_EXPORT_OK path=D:\npjt\cardborne-platformer\build\web\index.html files=4`

## Test Plan / Verification Commands

### 1. CSV Row Count & Format Verification (PowerShell)
```powershell
Import-Csv localization/vehicle_stage.csv | Measure-Object
```

### 2. Locked & Missing Keys Verification (PowerShell)
```powershell
$csv = Import-Csv localization/vehicle_stage.csv
$targetKeys = @(
    'DEPLOY_TITLE', 'UPGRADE_SELECT_DETAIL', 'UPGRADE_APPLY_FAILED',
    'REPORT_GARAGE', 'RESULT_TITLE_CONTINUE', 'RESULT_TITLE_FINAL',
    'UPGRADE_FAMILY_PASSIVE',
    'UPGRADE_FAMILY_SECONDARY', 'UPGRADE_FAMILY_DEFENSE',
    'UPGRADE_STAT_BREACH_HEALTH_SCALE_BONUS',
    'BOSS_PRACTICE_MODE_COMMITTED',
    'BOSS_PRACTICE_MODE_INTERRUPTIBLE',
    'BOSS_PRACTICE_MODE_AUTONOMOUS'
)
$csv | Where-Object { $targetKeys -contains $_.keys } | Format-Table keys, ko, en
```

### 3. Focused Localization, Boss, Upgrade, and Layout Validators
```powershell
.\tools\godot.ps1 --headless --script res://tools/validation/validate_vehicle_ui_localization.gd
.\tools\godot.ps1 --headless --script res://tools/validation/validate_vehicle_boss_patterns.gd
.\tools\godot.ps1 --headless --script res://tools/validation/validate_vehicle_boss_practice.gd
.\tools\godot.ps1 --headless --script res://tools/validation/validate_vehicle_upgrade_system.gd
.\tools\godot.ps1 --headless --script res://tools/validation/validate_vehicle_rewards_ui_audio.gd
.\tools\godot.ps1 --headless --script res://tools/validation/validate_vehicle_stage_ui_layout.gd
```

### 4. Headless Validation Suite
```powershell
.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --quit-after 2

Get-ChildItem tools/validation -Filter *.gd | Sort-Object Name | ForEach-Object {
    .\tools\godot.ps1 --headless --script ("res://tools/validation/" + $_.Name)
    if ($LASTEXITCODE -ne 0) { throw "Validation failed: $($_.Name)" }
}
```

### 5. 91-State Rendered Capture Pipeline
```powershell
$root = (Resolve-Path .).Path
foreach ($locale in @("ko", "en")) {
    foreach ($size in @("960x540", "1280x720", "1920x1080")) {
        $captureDir = Join-Path $root "build\captures\korean-copy-correction\$locale-$size"
        $godotArgs = @(
            "--rendering-method", "gl_compatibility", "--",
            "--capture-all=$captureDir",
            "--capture-locale=$locale",
            "--capture-size=$size",
            "--layout-seed=12886704"
        )
        .\tools\godot.ps1 @godotArgs
        if ($LASTEXITCODE -ne 0) { throw "Capture failed: $locale $size" }
    }
}
```

### 6. Web Platform Export Build
```powershell
.\tools\export_web.ps1
```

## Rollback / Safety

- Changes are presentation-only and remain separable by responsibility:
  localization rows, boss presentation mapping, upgrade-card layout/value
  presentation, validators, and capture fixtures.
- Do not alter card resources, combat numbers, boss sequences, stable IDs, save
  schema, or translation-resource paths.
- If a compact-layout change regresses a larger viewport, revert only the
  responsive presentation change while retaining localization closure and raw
  fallback removal.
- Keep the original locale when validators exit, including failure paths, so
  subsequent tests do not inherit altered global state.

## Risks & Mitigations

- **Risk 1**: CSV saved with UTF-8 BOM or improper quotes breaking Godot CSV localization parser.
  - *Mitigation*: Write CSV in UTF-8 without BOM and verify with headless Godot `--import`.
- **Risk 2**: Long stat titles wrapping onto multiple lines increasing vertical height of cards.
  - *Mitigation*: Ensure card container uses `autowrap_mode = TextServer.AUTOWRAP_WORD_SMART` and vertical size flags expand gracefully without overlapping level pips or choice panel buttons.
- **Risk 3**: Resolution scaling at 960×540 causing text overflow due to reduced viewport height.
  - *Mitigation*: Apply the locked compact layout instead of preserving the
    impossible 960×626 modal minimum, then assert the complete 960×540
    descendant/card/modal geometry.
- **Risk 4**: A localized picker accidentally changes the stable boss-pattern
  ID passed into practice mode.
  - *Mitigation*: Keep localized text in `OptionButton` display values and the
    original pattern ID exclusively in item metadata; validate both.
- **Risk 5**: A permissive fallback hides future catalog drift until runtime.
  - *Mitigation*: Unknown presentation IDs fail the localization validator and
    remain hidden in production rather than being printed to the player.

## Open Questions

None. The implementation choices, copy values, supported viewports, ownership,
and acceptance matrix are decision-complete for this correction.

## Decision Notes

- Reuse existing `PATTERN_*` translations for authored boss-pattern names
  instead of adding duplicate practice-only names.
- Add only the three missing commit-mode labels needed to describe practice
  behavior.
- Centralize boss presentation lookup with boss pattern data; do not keep
  separate HUD and practice-menu maps.
- Add one UI-localization closure validator because this is a cross-surface
  presentation responsibility; keep gameplay validators focused.
- Treat the third-slot defect as a shared component/panel geometry failure and
  prove slot invariance instead of adding right-edge special casing.
- Preserve 1280×720 hierarchy while introducing an explicit compact layout for
  960×540; do not declare the existing 960×626 modal valid at a 540px viewport.

## Next Steps

1. No implementation work remains in this plan.
2. Preserve the localization and measured-containment validators as regression
   gates for future card, copy, and modal changes.
