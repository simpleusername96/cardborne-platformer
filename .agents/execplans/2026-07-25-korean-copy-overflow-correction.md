---
type: plan
status: active
owner: BK
created: 2026-07-25
last_reviewed: 2026-07-25
scope: Correct Korean copy quality, add missing localization keys, fix stat preview value formatting, and guarantee card text containment across Cardborne UI without changing gameplay semantics
related:
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../design-qa.md
---

# Cardborne Korean Copy, Localization Key Alignment, and Card Text Containment - Execution Plan

## Purpose

This active plan records the decision-complete implementation roadmap for resolving Korean copy quality, missing dynamic localization keys, misleading stat preview values, and card container text overflow in Cardborne.

Runtime evidence captured in capture `2026-07-25 19 39 06.png` disproved the previous draft's conclusion that zero layout overflows existed. The previous draft's claim of zero reproduced defects and its activation blocker are explicitly corrected hereby. This plan is promoted to `active` status with `last_reviewed: 2026-07-25`.

This planning pass modifies no runtime code, CSV, tests, or assets; it defines
the complete checklist and specification required for subsequent execution.
AGY `Gemini 3.6 Flash (High)` performed the screenshot and upgrade-path
re-audit; Codex verified its proposed changes against the current data and
calculation owners before locking this plan.

## Sources Inspected

1. Runtime Screenshot Capture: `D:\Program Files\ImageMagick-7.1.1-Q16-HDRI\captures\2026-07-25 19 39 06.png`
2. `scripts/ui/vehicle_upgrade_choice_card.gd`
3. `scripts/ui/vehicle_upgrade_choice_panel.gd`
4. `scripts/vehicle/vehicle_run.gd` (specifically `_build_card_offer()`)
5. All 46 upgrade card definitions: `data/cards/vehicle/*.tres`
6. `localization/vehicle_stage.csv` (all 587 Korean entries plus placeholder contracts)
7. `tools/validation/validate_vehicle_upgrade_system.gd`
8. `tools/validation/validate_vehicle_rewards_ui_audio.gd`
9. `tools/validation/validate_vehicle_stage_ui_layout.gd`
10. `docs/product/vehicle_game_spec.md`
11. `docs/design/UI_VISUAL_SYSTEM.md`

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
| Card Text Containment | Unwrapped stat labels clip description lines | Word-wrapped stat & description labels fitting within card width | Text truncation on right edge | Clean multi-line wrapping within 282px | UI layout defect: Stat labels enable word wrapping; card layout adapts across resolutions. | `scripts/ui/vehicle_upgrade_choice_card.gd` | All 46 cards display full text without horizontal or vertical clipping. |

## Locked Contracts & Specifications

### 1. Upgrade Family and Missing-Key Translation Contract
The three missing keys and the existing seeker-family correction are locked
with the following exact values:
- `UPGRADE_FAMILY_SECONDARY`: Korean = `보조무기`, English = `Secondary`
- `UPGRADE_FAMILY_DEFENSE`: Korean = `방어`, English = `Defense`
- `UPGRADE_STAT_BREACH_HEALTH_SCALE_BONUS`: Korean = `돌파탄 추가 피해`, English = `Breach bonus damage`
- `UPGRADE_FAMILY_PASSIVE`: Korean = `추적탄`, English = `Seeker`

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
- **Card Base Dimensions**: Minimum size of `Vector2(282.0, 336.0)` is preserved at 1280×720 baseline.
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
- **Resolution Scale Support**:
  - Containment contracts must hold without text clipping or layout overflow at 960×540, 1280×720, and 1920×1080 in both Korean and English locales.

### 4. Dynamic Catalog Validation Contract
Extend `tools/validation/validate_vehicle_upgrade_system.gd` rather than
creating a competing validator owner. It must:
- Instantiate `UpgradeCatalog` and iterate through all 46 upgrade definitions.
- Check every explicit `title_key` and `description_key`.
- Derive each family key with `UPGRADE_FAMILY_%s` and each modifier key with
  `UPGRADE_STAT_%s`, matching `_build_card_offer()` exactly.
- Set `TranslationServer` to Korean and English in turn, assert that every
  derived key translates to a non-empty value different from the raw key, and
  restore the original locale before exit.

### 5. Rendered Evidence Contract
- Extract one `_build_card_snapshot(definition, current_level)` helper from
  `scripts/vehicle/vehicle_run.gd::_build_card_offer()` so production offers
  and capture fixtures cannot drift.
- Extend the existing capture sequence to show the 46 definitions in stable
  ID-sorted groups of three, including the highest preview level for
  multi-level cards.
- Automated capture tools must render visual evidence for all 46 upgrade cards across 3 resolutions (960×540, 1280×720, 1920×1080) and 2 locales (`ko`, `en`).
- Visual captures must include explicit contact sheets for the three
  multi-modifier cards and the 13 cards affected by family-label corrections
  or missing keys.

### 6. Gameplay Semantics Preservation Contract
- User-visible behavior changes remain restricted to UI presentation and
  localization strings.
- The snapshot-helper extraction in `vehicle_run.gd` must be output-equivalent
  for production offers and exists only to keep capture fixtures on the same
  presentation-data path.
- Card resources in `data/cards/vehicle/*.tres`, gameplay catalog logic in `scripts/cards/`, and status/damage calculations remain completely unchanged.

## Audit Totals Summary

- **Total CSV rows**: 587 existing + 3 missing = 590 total.
- **Total upgrade card resources**: 46.
- **Card definitions affected by missing keys**: 7 (`aegis_cycle`, `breach_round`, `escort_drone`, `ion_field`, `orbit_blades`, `siphon_matrix`, `wake_mines`).
- **Existing localized rows to update**: 7 (the six prior copy corrections plus `UPGRADE_FAMILY_PASSIVE`).
- **Total card definitions receiving family-label corrections or missing-key fixes**: 13.
- **Missing dynamic localization keys**: 3 (`UPGRADE_FAMILY_SECONDARY`, `UPGRADE_FAMILY_DEFENSE`, `UPGRADE_STAT_BREACH_HEALTH_SCALE_BONUS`).
- **Stat preview display fix**: 1 (`_preview_value()` fractional additive formatting).
- **Layout containment fixes**: `VehicleUpgradeChoiceCard` text label wrapping and container constraints.

## Implementation Tasks

- [ ] **Task 1: Add Missing Keys and Update Copy in CSV**
  - **As-is**: `localization/vehicle_stage.csv` lacks `UPGRADE_FAMILY_SECONDARY`, `UPGRADE_FAMILY_DEFENSE`, and `UPGRADE_STAT_BREACH_HEALTH_SCALE_BONUS`, and contains legacy copy in 7 rows.
  - **To-be**: Add the 3 missing keys with the locked values above, and update `DEPLOY_TITLE`, `UPGRADE_SELECT_DETAIL`, `UPGRADE_APPLY_FAILED`, `REPORT_GARAGE`, `RESULT_TITLE_CONTINUE`, `RESULT_TITLE_FINAL`, and `UPGRADE_FAMILY_PASSIVE`.
  - **Accept**: CSV contains 590 properly formatted rows; all ten added or changed rows exactly match the AS-IS / TO-BE inventory.
  - **Guard**: Headless Godot CSV import test passes cleanly.

- [ ] **Task 2: Fix Stat Preview Value Formatting in Choice Card**
  - **As-is**: `_preview_value()` in `scripts/ui/vehicle_upgrade_choice_card.gd` uses `%+.0f` for all additive stats, rendering `breach_round` values as `+0 → +0`.
  - **To-be**: Give `UPGRADE_STAT_BREACH_HEALTH_SCALE_BONUS` the locked percentage presentation while leaving multiplier and flat-add formats unchanged.
  - **Accept**: `breach_round` displays `+0% → +20%` at level 0 and `+20% → +40%` at level 1; integer flat additions and multipliers retain their existing output.
  - **Guard**: Unit test / validator assertion for `_preview_value()` outputs.

- [ ] **Task 3: Enforce UI Containment in Upgrade Choice Card & Panel**
  - **As-is**: Stat labels lack word wrapping, causing unwrapped keys to expand card minimum width and clip sibling description text under `clip_contents = true`.
  - **To-be**: Configure `autowrap_mode = TextServer.AUTOWRAP_WORD_SMART` on stat title labels, adjust separation and padding, and ensure all 46 card layouts fit cleanly.
  - **Accept**: Zero horizontal or vertical text truncation across all 46 cards at 960×540, 1280×720, and 1920×1080 in Korean and English.
  - **Guard**: Layout validator passes with zero overflow warnings.

- [ ] **Task 4: Implement Dynamic Catalog Localization Validator**
  - **As-is**: No automated validator checks if dynamic keys generated by `_build_card_offer()` exist in CSV.
  - **To-be**: Extend `tools/validation/validate_vehicle_upgrade_system.gd` to test explicit and dynamically derived keys across all 46 cards in `ko` and `en`.
  - **Accept**: Validator exits code 0 when all dynamic keys translate successfully, and fails with exit code 1 if any key returns raw string.
  - **Guard**: Execute script in headless Godot mode.

- [ ] **Task 5: Execute Rendered Evidence & Suite Gates**
  - **As-is**: Rendered captures cover only 3 fixture cards.
  - **To-be**: Extract the shared card-snapshot builder, extend the existing capture sequence with deterministic all-card fixtures, then run it across 3 resolutions and 2 locales plus the Web export.
  - **Accept**: All validator scripts pass, capture sets complete, and web export builds cleanly.
  - **Guard**: Clean execution of all validation scripts and web build script.

## Progress

- [x] AGY `Gemini 3.6 Flash (High)` re-audit of the supplied screenshot and upgrade-card
  localization path completed.
- [x] Screenshot evidence `2026-07-25 19 39 06.png` inspected and defects verified.
- [x] Mechanical audit of all 46 card `.tres` resources against CSV completed.
- [x] 3 missing dynamic keys and 7 affected cards identified.
- [x] Preview formatting defect (`+0 → +0`) identified and percentage display
  specification defined.
- [x] Plan updated to decision-complete active state with `last_reviewed: 2026-07-25`.
- [ ] Task 1: CSV copy updates and missing key additions executed.
- [ ] Task 2: Choice card stat preview formatting fix executed.
- [ ] Task 3: Choice card UI text containment fix executed.
- [ ] Task 4: Dynamic catalog localization validator created and executed.
- [ ] Task 5: 46-card rendered captures and Web export build executed.

## Verification Commands

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
    'UPGRADE_FAMILY_SECONDARY', 'UPGRADE_FAMILY_DEFENSE', 'UPGRADE_STAT_BREACH_HEALTH_SCALE_BONUS'
)
$csv | Where-Object { $targetKeys -contains $_.keys } | Format-Table keys, ko, en
```

### 3. Focused Upgrade and Layout Validators
```powershell
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

### 5. 46-Card Rendered Capture Pipeline
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

## Risks & Mitigations

- **Risk 1**: CSV saved with UTF-8 BOM or improper quotes breaking Godot CSV localization parser.
  - *Mitigation*: Write CSV in UTF-8 without BOM and verify with headless Godot `--import`.
- **Risk 2**: Long stat titles wrapping onto multiple lines increasing vertical height of cards.
  - *Mitigation*: Ensure card container uses `autowrap_mode = TextServer.AUTOWRAP_WORD_SMART` and vertical size flags expand gracefully without overlapping level pips or choice panel buttons.
- **Risk 3**: Resolution scaling at 960×540 causing text overflow due to reduced viewport height.
  - *Mitigation*: Test card layouts explicitly under 960×540 viewport settings in both locales.

## Next Steps

1. Apply Task 1's ten exact CSV additions or replacements.
2. Implement Tasks 2–4 in their existing UI and validation owners without
   changing card data or combat calculations.
3. Add the deterministic all-card fixture to the existing capture sequence,
   run the focused checks, inspect every Korean and English contact sheet, then
   run the full validator suite and Web export.
