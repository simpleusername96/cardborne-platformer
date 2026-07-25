---
type: plan
status: draft
owner: BK
created: 2026-07-25
scope: Correct Korean copy quality, terminology consistency, and text containment across Cardborne UI without changing gameplay meaning
related:
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../design-qa.md
---

# Cardborne Korean Copy and Text Containment - Execution Plan

## Purpose

This draft records the completed AGY 3.6 Flash audit of all 587 Korean
localization rows and six exact copy replacements for Cardborne at commit
`5c4baf1` on master. The copy batch is decision-complete. The reported live
section-escape defect is not yet decision-complete because none of the current
110 rendered fixtures reproduces it; this document must remain `draft` until
the exact live state is captured or reproduced with a maximal-content fixture.

No layout code may be changed speculatively while that evidence is missing.

## Sources Inspected

1. `localization/vehicle_stage.csv` (all 587 Korean entries, placeholders `%s`, `%d`, `%.1f`, `%level%`, `%count%`, `{token}`, and explicit `\n` sequences).
2. All translation and locale consumer scripts returned by searching
   `tr()`, `TranslationServer`, locale setters, and translation helpers in
   `scripts/`:
   - `scripts/autoload/settings_store.gd`
   - `scripts/input/vehicle_input_profile.gd`
   - `scripts/performance/vehicle_performance_recorder.gd`
   - `scripts/ui/vehicle_build_summary_panel.gd`
   - `scripts/ui/vehicle_guidebook_panel.gd`
   - `scripts/ui/vehicle_settings_panel.gd`
   - `scripts/ui/vehicle_stage_ui.gd`
   - `scripts/ui/vehicle_stage_report_panel.gd`
   - `scripts/ui/vehicle_upgrade_choice_panel.gd`
   - `scripts/ui/vehicle_upgrade_choice_card.gd`
   - `scripts/vehicle/vehicle_field_layout.gd`
   - `scripts/vehicle/vehicle_run.gd`
   - `scripts/vehicle/vehicle_stage_catalog.gd`
   - `scripts/vehicle/vehicle_stage_tactical_layout.gd`
3. Shared UI theme `art/ui/production/vehicle_stage_theme.tres`.
4. Runtime evidence captures across three resolutions:
   - `build/captures/uiux-recovery-final/ko-960x540/` (24 captures)
   - `build/captures/uiux-recovery-final/ko-1280x720/` (60 captures)
   - `build/captures/uiux-recovery-final/ko-1920x1080/` (24 captures)
5. Whole-surface audit contact sheets:
   - `build/audits/korean-copy-overflow/ko-960-all.png`
   - `build/audits/korean-copy-overflow/ko-1280-all.png`
6. `docs/product/vehicle_game_spec.md` and `docs/design/UI_VISUAL_SYSTEM.md`.

## Audit Summary & Totals

- **Total Korean localization entries checked**: 587
- **Hard-coded Hangul found outside localization in runtime scripts, scenes,
  resources, art metadata, or `project.godot`**: 0
- **Directly referenced in GDScript string literals**: 387
- **Reachable via dynamic prefix generation / resource schemas**: 176
- **Not directly referenced in script or UI schemas**: 24
- **Visibly reproduced overflows in static fixture captures**: 0
- **Exact copy replacements**: 6
- **Entries without a proposed copy change**: 581
- **Dynamic-state classes lacking containment evidence**: 4
  (non-fixture cards, maximal summary snapshots, longest live overlays,
  and non-zero scroll states)
- **Locked layout code changes**: 0 (reproduction pending)

## Required AS-IS / TO-BE Inventory

| Key | AS-IS Korean | TO-BE Korean | Reason | Affected Surface | Consuming File / Owner | Classification | Acceptance Check |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `DEPLOY_TITLE` | `침수 공방 출격 준비` | `출격 준비` | `침수 공방`은 1단계 구역 명칭임. 헤더 제목에서 고정 구역명을 제거하여 2단계 이상 출격 모달과의 용어 불일치 해소. | Deployment Modal Header | `scripts/ui/vehicle_stage_ui.gd` | Copy quality & terminology alignment | 모달 제목이 `출격 준비`로 출력되고 상단 `DEPLOY_FIELD_TEMPLATE`("작전 구역 · %s")과 조화를 이룸. |
| `UPGRADE_SELECT_DETAIL` | `카드를 선택한 뒤 장착을 눌러 확정하세요.` | `회로를 선택한 뒤 장착을 눌러 확정하세요.` | 용어 통일. `UPGRADE_TITLE`("회로 하나를 선택하세요") 및 게임 사양서의 회로 용어로 맞춰 `카드`를 `회로`로 수정. | Upgrade Choice Panel | `scripts/ui/vehicle_upgrade_choice_panel.gd` | Copy quality & terminology alignment | 선택 안내문이 `회로를 선택한 뒤 장착을 눌러 확정하세요.`로 표시됨. |
| `UPGRADE_APPLY_FAILED` | `현재 빌드에는 적용할 수 없습니다. 다른 카드를 선택하세요.` | `현재 빌드에는 적용할 수 없습니다. 다른 회로를 선택하세요.` | 용어 통일. 적용 불가 에러 문구 내 `카드`를 `회로`로 수정. | Upgrade Choice Panel | `scripts/ui/vehicle_upgrade_choice_panel.gd` | Copy quality & terminology alignment | 선택 에러문이 `다른 회로를 선택하세요.`로 표시됨. |
| `REPORT_GARAGE` | `격납고로 이동` | `차고로 이동` | 용어 통일. UI 헤더 `GARAGE_KICKER`("간이 차고") 및 사양서 명칭과 일치하도록 `격납고`를 `차고`로 수정. | Stage Report Panel | `scripts/ui/vehicle_stage_report_panel.gd` | Copy quality & terminology alignment | 버튼 문구가 `차고로 이동`으로 표시됨. |
| `RESULT_TITLE_CONTINUE` | `다음 수역이 열렸습니다` | `다음 구역이 열렸습니다` | 용어 통일. 사양서 및 스테이지 라벨(`STAGE_DROWNED_RUINS_1`="침수 유적 · 1구역")과 일치하도록 `수역`을 `구역`으로 수정. | Result Panel | `scripts/ui/vehicle_stage_ui.gd` | Copy quality & terminology alignment | 결과 제목이 `다음 구역이 열렸습니다`로 표시됨. |
| `RESULT_TITLE_FINAL` | `세 수역을 돌파했습니다` | `모든 구역을 돌파했습니다` | 용어 통일. `수역`을 `구역`으로 수정하고 전체 캠페인 완료 전달력 강화. | Result Panel | `scripts/ui/vehicle_stage_ui.gd` | Copy quality & terminology alignment | 최종 결과 제목이 `모든 구역을 돌파했습니다`로 표시됨. |

## Categorization of Findings

### A. Visibly Reproduced Overflows in Static Captures
- **None**: AGY inspected the 108 current Korean captures plus both current
  contact sheets. Deployment, settings, guidebook, the three fixture upgrade
  cards, pause, stage/failure reports, result, and garage keep their fixture
  text inside the intended sections.
- HUD objective, boss, notification, and world-feedback text that appears over
  the playfield is intentional overlay content and is not classified as a
  section escape.

### B. Latent Text Risk & Dynamic Text Containment
- **Longest Upgrade Descriptions in `VehicleUpgradeChoiceCard`**:
  - `UPGRADE_SIPHON_MATRIX_DESC` (53 chars): `실제로 가한 피해의 2%를 회복하며 초당 최대 6까지 회복합니다. 2레벨에는 3.5%가 됩니다.`
  - `UPGRADE_RICOCHET_DESC` (51 chars): `주무기 탄환이 엄폐물에서 한 번 튕깁니다. 통로에 진입하기 전에 포탑을 제거할 수 있습니다.`
  - `UPGRADE_AEGIS_CYCLE_DESC` (50 chars): `14초마다 5초간 방벽을 20 생성합니다. 2레벨에는 방벽 28, 지속시간 6초가 됩니다.`
  - The current fixture renders only `분기 포구`, `빙결 코어`, and `추적탄 탄두`.
    The remaining 43 cards, including three two-modifier cards that add a
    secondary value row, do not yet have rendered containment evidence.
- **Dynamic Result / Garage / Settings Text**:
  - Current fixtures use compact result, garage, and build snapshots. Maximal
    module, reward, secondary, upgrade, objective, notification, boss-name, and
    scrolled states are absent from the capture set.

### C. Terminology Consistency
- `DEPLOY_TITLE`: Removal of hardcoded `침수 공방` from header title.
- `UPGRADE_SELECT_DETAIL`, `UPGRADE_APPLY_FAILED`: Alignment from `카드` to `회로`.
- `REPORT_GARAGE`: Alignment from `격납고` to `차고`.
- `RESULT_TITLE_CONTINUE`, `RESULT_TITLE_FINAL`: Alignment from `수역` to `구역`.

### D. Layout Decision Boundary

- No layout correction is locked from the static evidence because no current
  static fixture reproduces the reported defect.
- Do not shrink the guide preview, report margins, type, or deployment spacing
  as a proxy fix.
- Before this plan becomes active, the escaping live state must be identified
  by an exact screenshot/state or by maximal-content fixtures for the absent
  dynamic states listed above. That evidence must name the owning control and
  permit one exact `AS-IS → TO-BE` containment correction.

## Keys Not Directly Referenced in Scripts (24 Keys)

The following 24 keys in `localization/vehicle_stage.csv` are not directly referenced as literal strings in `.gd` scripts or UI schemas:
`LANGUAGE_LABEL`, `SETTINGS_STATUS_READY`, `UI_HULL_INTEGRITY`, `UI_FLOODED_WORKS`, `UI_LOCKED_TARGET`, `UI_NO_TARGET`, `STATE_LIVE`, `STATE_FIRING`, `STATE_PRIMARY_UNAVAILABLE`, `STATE_PRIMARY_QUICK`, `STATE_PRIMARY_CHARGED`, `STATE_PRIMARY_FULL_POWER`, `STATE_SELECTED`, `DEPLOY_KICKER`, `DEPLOY_CONTROLS_TEMPLATE`, `DEPLOY_FOOTER`, `RESULT_RUN`, `RESULT_WARDEN`, `RESULT_DEFEATED`, `RESULT_BYPASSED`, `RESULT_NEXT_STAGE`, `GARAGE_PASSIVE_SEEKER`, `BUFF_ATTACK`, `SHIP_STATUS_HEADING`.

*(Note: All other 563 CSV entries are either directly referenced by literal key in GDScript or reachable via dynamic prefix generators such as `UPGRADE_%s_TITLE`, `UPGRADE_STAT_%s`, `STAGE_%s`, `NOTIFY_%s`, `OBJECTIVE_%s`, `ENEMY_%s`, `PATTERN_%s` and resource definitions).*

## Tasks

- [ ] **Task 1: Update CSV Localization Copy**
  - **As-is**: `localization/vehicle_stage.csv` contains legacy terms (`침수 공방` in deployment header, `카드` in upgrade choice panel, `격납고` in stage report, `수역` in result titles).
  - **To-be**: Update exact keys `DEPLOY_TITLE` ("출격 준비"), `UPGRADE_SELECT_DETAIL` ("회로를 선택한 뒤 장착을 눌러 확정하세요."), `UPGRADE_APPLY_FAILED` ("현재 빌드에는 적용할 수 없습니다. 다른 회로를 선택하세요."), `REPORT_GARAGE` ("차고로 이동"), `RESULT_TITLE_CONTINUE` ("다음 구역이 열렸습니다"), `RESULT_TITLE_FINAL` ("모든 구역을 돌파했습니다").
  - **Accept**: CSV 6 rows updated while preserving exact format strings and column headers (`keys,ko,en`).
  - **Guard**: Run `Import-Csv` verification and headless Godot import check.

- [ ] **Task 2: Execute Headless Validation & Rendered Evidence Capture Suite**
  - **As-is**: Copy updates pending runtime verification.
  - **To-be**: Run headless import, execute all validator scripts in `tools/validation/`, generate rendered captures across locales and resolutions, and build web export.
  - **Accept**: All validation scripts pass cleanly and web export succeeds.
  - **Guard**: Zero validation failures and clean asset import.

## Progress

- [x] Antigravity full Korean-string audit completed (587 CSV entries verified).
- [x] Codex verified the six proposed replacements against current CSV values,
  product terminology, and source ownership.
- [ ] Plan promoted from `draft` to `active`.
- [ ] Runtime copy implementation completed.
- [ ] Rendered evidence and validation gates passed.

## Verification

### 1. CSV Data Verification (PowerShell)
```powershell
Import-Csv localization/vehicle_stage.csv | ForEach-Object { $_ } | Measure-Object
```

### 2. Exact Key Verification (PowerShell)
```powershell
$csv = Import-Csv localization/vehicle_stage.csv
$targetKeys = @(
    'DEPLOY_TITLE', 'UPGRADE_SELECT_DETAIL', 'UPGRADE_APPLY_FAILED',
    'REPORT_GARAGE', 'RESULT_TITLE_CONTINUE', 'RESULT_TITLE_FINAL'
)
$csv | Where-Object { $targetKeys -contains $_.keys } | Format-Table keys, ko, en
```

### 3. Headless Import & Validator Suite (README.md documented flow)
```powershell
.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --quit-after 2

Get-ChildItem tools/validation -Filter *.gd | Sort-Object Name | ForEach-Object {
  .\tools\godot.ps1 --headless --script ("res://tools/validation/" + $_.Name)
  if ($LASTEXITCODE -ne 0) { throw "Validation failed: $($_.Name)" }
}
```

### 4. Rendered Evidence Generation (README.md documented flow)
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

### 5. Web Platform Build (README.md documented flow)
```powershell
.\tools\export_web.ps1
```

## Risks & Mitigations

- **Risk 1**: CSV saved with UTF-8 BOM or improper line endings breaking Godot localization parser.
  - *Mitigation*: Save `localization/vehicle_stage.csv` with standard UTF-8 without BOM and verify via headless import.
- **Risk 2**: The reported live section escape remains unreproduced.
  - *Mitigation*: Copy verification is complete, but keep the plan in `draft`
    until the user-reported section escape is reproduced and receives one exact
    layout correction.

## Blocker for Plan Activation

- **Concrete Blocker**: The current static evidence does not reproduce the
  user-reported section escape, while 43 non-fixture upgrade cards and maximal
  dynamic snapshot/overlay states remain uncaptured. The exact affected
  control—and therefore the safe layout correction—cannot be named yet.
- **Activation evidence**: either the user's exact screenshot/state or a
  deterministic maximal-content capture that visibly reproduces the escape.
- **Stop rule**: do not apply a blanket font reduction, panel shrink, clipping,
  or ellipsis workaround.

## Next Steps

1. Use the user's exact screenshot/state when available; otherwise render
   maximal-content fixtures for all 46 upgrade cards, full result/garage/build
   snapshots, longest HUD strings, and non-zero scroll states.
2. Add the reproduced defect's exact owner and one locked `AS-IS → TO-BE`
   containment correction to this document.
3. Promote the plan to `active`, apply the six verified copy changes plus that
   exact containment correction, then run the listed localization, capture,
   validator, and Web export gates.
