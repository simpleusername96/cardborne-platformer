---
type: evidence
status: active
owner: BK
created: 2026-07-15
last_reviewed: 2026-07-15
topic: Player input conventions, menu navigation, and deferred UI validity findings
scope: Cardborne Traveler vertical slice across keyboard, mouse, standard gamepad, HUD prompts, and production menus
source: Local implementation and current-run captures reviewed against official accessibility guidance and comparable action-platformer control references on 2026-07-15
related:
  - ../design/COMBAT_EQUIPMENT_CRAFTING.md
  - ../design/PRODUCTION_UI_CONTRACT.md
  - ../product/2d_platform_action_card_game_prd.md
  - ../../.agent/execplans/2026-07-14-minimum-equipment-progression-vertical-slice.md
---

# 플레이어 입력 관습 및 UI 후속 감사 - 2026-07-15

## Purpose

완료된 최소 장비 성장 버티컬 슬라이스가 2D 액션 플랫폼·로그라이트에서 널리
쓰이는 조작 문법과 메뉴 조작 기대를 충족하는지 확인한다. 사용자가 지적한 UI
가독성·팝업·언어 문제는 **별도 UI 브랜치의 입력 자료로만 보관**하며, 이 문서는
현재 브랜치에서 UI 구현을 시작하거나 정식 제품 규칙을 바꾸는 권한을 주지 않는다.

판정 기준은 특정 게임의 버튼 배치를 그대로 복제하는 것이 아니다. 유사 게임에서
반복되는 기본값, 공식 접근성 지침, Cardborne의 실제 행동 빈도와 동시에 눌러야
하는 입력을 함께 본다.

## Sources

### External standards and official product evidence

1. [Xbox Accessibility Guideline 107: Input](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/107), Microsoft.
   모든 지원 입력의 게임 내 재지정, 재지정된 안내 갱신, 아날로그 입력의 디지털
   대체, 스틱 클릭의 대체 가능성, 장시간 누르기·동시 입력의 대안을 권고한다.
2. [Xbox Accessibility Guideline 112: UI navigation](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/112), Microsoft.
   논리적인 포커스 순서, 디지털 방향 입력, 일관된 `A/Select`와 `B/Back`, 모든
   하위 화면의 예측 가능한 복귀 경로를 요구한다.
3. [UI navigation controller](https://learn.microsoft.com/en-us/windows/uwp/gaming/ui-navigation-controller), Microsoft.
   방향, Menu, Accept, Cancel을 공통 UI 명령 집합으로 정의한다.
4. [Prince of Persia: The Lost Crown - Accessibility Spotlight](https://www.ubisoft.com/en-gb/game/prince-of-persia/the-lost-crown/news-updates/5nGZiBSFtcEzFd93QlTotS/prince-of-persia-the-lost-crown-accessibility-spotlight), Ubisoft.
   키보드·마우스와 게임패드 지원, 양쪽 입력 재지정, 스틱 교환·축 반전, 진동
   조정, 버튼 연타 자동 완료를 실제 동종 장르 사례로 제시한다.
5. [Dead Cells current patch notes](https://dead-cells.com/patchnotes/), Motion Twin/Evil Empire.
   큰 조작 아이콘, 컨트롤러 아이콘 선택, 플랫폼 통과 입력 옵션, 트리거·스틱
   데드존, 텍스트 배경 같은 후속 접근성 개선이 현재까지 유지된다.

### Comparable control references

아래 자료는 기본 배치 비교용 커뮤니티 문서다. 공식 지침과 동일한 권위를 갖지
않으며, 한 게임의 배치를 보편 법칙으로 승격하지 않는다.

1. [Dead Cells controls](https://deadcells.fandom.com/wiki/Controls): `X` 주 무기,
   `Y` 보조 무기, `LB` 회복, `RB` 일반 상호작용, `R3` 특수 신체 행동,
   `Down + Jump` 플랫폼 통과, 키보드 `Space/Shift/LMB/RMB` 배치를 기록한다.
2. [Hollow Knight controls](https://hollowknight.wiki/w/Controls_%28Hollow_Knight%29):
   `A` 점프, `X` 공격, `Start` 일시정지, 게임패드 포함 재지정을 기록한다. 대시는
   `RT`이므로 대시 버튼에는 장르 전체의 단일 정답이 없다는 비교 근거이기도 하다.
3. [Rogue Legacy game controls](https://roguelegacy.wiki.gg/wiki/Game_controls):
   제목·일시정지 화면에서의 조작 변경, 위 방향 상호작용, 누르는 길이에 따른 점프
   높이, `Down + Jump` 플랫폼 통과를 기록한다.

### Local evidence

- 완료 계획: `.agent/execplans/2026-07-14-minimum-equipment-progression-vertical-slice.md`
- 제품 규칙: `docs/design/COMBAT_EQUIPMENT_CRAFTING.md`,
  `docs/design/PRODUCTION_UI_CONTRACT.md`
- 입력 정의: `scripts/autoload/InputBindings.gd`
- 이동 처리: `scripts/player/CharacterProfile.gd`,
  `scripts/player/PlayerController.gd`
- 전투·방어 입력: `scripts/player/PlayerCombatController.gd`
- 메뉴: `scripts/ui/PauseMenu.gd`, `scripts/ui/SettingsPopup.gd`,
  `scripts/ui/production/ForgeScreen.gd`,
  `scripts/ui/production/HeroPreparation.gd`, 보상·결과 화면
- 검증기: `tools/validate_gamepad_input.gd`,
  `tools/validate_input_remap.gd`, `tools/validate_player_movement_runtime.gd`,
  `tools/validate_pause_flow.gd`, `tools/validate_hero_preparation_ui.gd`,
  `tools/validate_forge_screen.gd`

## Common Control Model

외부 자료에서 Cardborne에 적용할 수 있는 공통분모는 다음과 같다.

1. 이동은 왼쪽 스틱과 D-pad를 모두 지원하고, 키보드는 WASD 또는 방향키를
   지원한다.
2. Xbox 계열 기준 `A` 점프, `X` 주 공격, `Menu/Start` 일시정지는 매우 익숙한
   기본값이다. 대시·방어·소비품·상호작용은 게임마다 다르므로 특정 버튼보다
   **완전한 재지정과 동시 조작 가능성**이 더 중요하다.
3. `Down + Jump` 플랫폼 통과, 짧게/길게 누르는 점프 높이, 점프 버퍼와 코요테
   타임은 2D 플랫폼 이동의 학습 비용을 낮춘다.
4. 메뉴는 방향키/D-pad, `A/Enter` 확인, `B/Escape` 취소·뒤로, `Menu/Start`
   일시정지를 화면마다 같은 의미로 사용해야 한다.
5. 자주 쓰는 상호작용을 스틱 클릭에만 고정하거나, 아날로그 트리거 행동을 디지털
   버튼으로 옮길 수 없게 하는 것은 피한다.
6. 재지정 후 HUD, 튜토리얼, 상호작용 프롬프트가 실제 새 입력을 즉시 보여야 한다.
7. 누르고 유지하는 방어처럼 다른 행동과 동시에 써야 하는 입력은 어깨 버튼이
   유리할 수 있다. 이는 외부 자료의 보편 규칙이 아니라 Cardborne의 행동 조합에
   대한 인체공학적 추론이므로 실제 플레이테스트와 재지정 지원으로 검증해야 한다.

## Findings

### Verdict matrix

| Area | Verdict | Evidence and interpretation |
| --- | --- | --- |
| 이동 기본값 | Pass | 키보드 A/D·방향키, 게임패드 LS·D-pad, `Space/A` 점프, `Shift/B` 대시가 제공된다. |
| 플랫폼 이동 감각 | Pass | 0.10초 코요테 타임, 0.12초 점프 버퍼, 점프 컷, 2단 점프, `Down + Jump` 통과, 점프·대시로 등반 해제가 구현되어 있다. |
| 주 공격 기본값 | Pass | `F/X` 한 개의 상황 공격은 `X` 주 공격 관습과 맞고, 현재 단일 영웅 설계에도 일관된다. |
| 게임패드 대시 | Pass with caveat | `B` 대시는 충분히 익숙한 배치다. 유사 게임도 트리거를 쓰는 등 차이가 있으므로 고정값보다 재지정이 중요하다. |
| 방어 기본값 | Partial | `G/Y`는 보조 무기 슬롯에 방패를 두는 해석으로는 성립한다. 하지만 누르고 유지하는 `Y`와 점프·대시·공격의 동시 사용이 불편할 수 있고 재지정·토글 대안이 없다. 별도 기능 감사에서 방어 피드백과 실제 효력이 불명확했던 문제도 남아 있다. |
| 상호작용 기본값 | Fail | `E`는 익숙하지만 게임패드의 고빈도 상호작용이 `R3`에 고정돼 있다. 비교 대상의 일반 상호작용은 `RB` 또는 위 방향이고, Microsoft 지침은 스틱 클릭 행동의 재지정 가능성을 명시한다. |
| 소비품 기본값 | Partial | `H/RT` 자체가 절대적으로 잘못된 배치는 아니다. 다만 H는 WASD 이동 중 손이 멀고, RT 아날로그 입력을 디지털 버튼으로 옮길 수 없다. |
| 키보드 재지정 | Pass | 키 캡처, 충돌 거부, 저장·복원, 개별/전체 초기화가 동작한다. |
| 게임패드·마우스 재지정 | Fail | 설정이 `InputEventKey`만 받으며 화면에도 “Gamepad layout is fixed”라고 표시한다. 마우스 버튼은 표시 코드만 있고 기본 전투 배치나 캡처 경로가 없다. |
| 프롬프트 전환 | Pass | 키보드·마우스/게임패드 전환을 감지하고 HUD 상호작용 프롬프트가 현재 바인딩 문자열을 읽는다. |
| Pause/Settings 취소 | Pass | `Escape`/`ui_cancel`로 닫히고, 확인창의 안전 행동과 복귀 포커스가 검증됐다. |
| 전체 메뉴 Back 계약 | Fail | Forge는 `LEAVE` 버튼만 있고 `ui_cancel` 처리와 Back 프롬프트가 없다. 준비 화면도 Back 버튼은 있지만 전역 `Escape/B` 처리가 없다. |
| 공간 포커스 이동 | Partial | 카드·레벨 보상은 좌우 이웃이 명시돼 있고 여러 화면이 초기 포커스를 잡는다. Forge는 명시적 이웃이 없고, 준비 화면 검증은 실제 방향 입력이 아니라 `find_next_valid_focus()`로 일부 컨트롤만 순회한다. |
| 자동 검증의 의미 | Partial | 현재 검증기는 구현 일관성과 회귀에는 유효하지만, 고정 `R3`, 고정 게임패드라는 설계 자체를 성공 조건으로 삼아 장르 관습·접근성을 검증하지 않는다. |

### 1. 잘 적용된 부분

- `A/Space` 점프와 `X/F` 공격은 비교 대상과 곧바로 통한다.
- `B/Shift` 대시는 단순하고 접근하기 쉽다. 대시와 등반 취소가 문맥적으로 같은
  버튼을 쓰는 것도 예측 가능하다.
- `Down + Jump`로 일방통행 플랫폼을 통과하며, 점프를 일찍 놓으면 상승이 짧아진다.
- 코요테 타임과 점프 버퍼가 존재해 입력 허용 범위가 지나치게 엄격하지 않다.
- 상호작용 프롬프트는 하드코딩된 `E`만 그리지 않고 현재 바인딩을 읽는다.
- Pause와 Settings는 `Escape/B` 복귀, 안전 행동 초기 포커스, 설정 종료 후 포커스
  복원이 구현되어 있다.

### 2. 가장 큰 조작 문제: `R3` 고정 상호작용

Cardborne의 상호작용은 상자, NPC, 제단, Forge, 출구처럼 런 중 반복해서 쓰는
핵심 행동이다. 이를 오른쪽 스틱 클릭에 고정하면 다음 문제가 생긴다.

- 표준 패드 그림을 보지 않은 신규 플레이어가 추측하기 어렵다.
- 이동 중 스틱을 눌러야 하거나, 손가락 힘이 약한 플레이어에게 불필요한 부담이다.
- Dead Cells의 비교 배치에서는 일반 상호작용이 `RB`이고 `R3`는 드문 특수 행동이다.
- 더 나은 버튼으로 옮길 수 없으므로 잘못된 기본값을 사용자가 복구할 수 없다.

따라서 `R3` 자체보다 **고빈도 행동 + 스틱 클릭 + 고정 배치**의 조합이 실패다.

### 3. 게임패드 고정 배치는 제품 문서와도 충돌한다

`docs/design/COMBAT_EQUIPMENT_CRAFTING.md`는 “모든 입력은 재지정 가능”이라고
정의하지만 실제 설정은 키보드 키만 바꿀 수 있다. `validate_gamepad_input.gd`와
`validate_input_remap.gd`도 이 제한을 오류로 잡지 않고 오히려 게임패드 이벤트가
고정돼 있는지 확인한다.

즉 현재 검증 통과의 정확한 의미는 다음과 같다.

> 구현은 현재의 고정 배치 계약과 일치하지만, 활성 제품 문서 및 외부 접근성
> 기준과는 일치하지 않는다.

### 4. 방어 버튼은 단독으로 틀렸다고 할 수 없지만 대안이 필요하다

`Y`는 Dead Cells의 보조 무기 위치이므로 방패가 그 슬롯을 차지한다는 설명은
가능하다. 반면 Cardborne 방어는 누르고 유지하는 동안 활성화되고, 같은 오른손
엄지로 `A/B/X`를 자주 사용한다. 실제 방어가 이동·점프·대시와 동시에 필요하다면
`LT`가 더 편할 가능성이 있다.

따라서 권장 정책은 다음 순서다.

1. 우선 게임패드 재지정을 제공한다.
2. 기본값은 `LT` 방어를 플레이테스트하되, `Y` 유지안도 비교한다.
3. `Hold/Toggle Guard` 옵션을 제공하거나 최소한 토글 방식의 접근성 대안을 검토한다.
4. 버튼을 눌렀을 때 자세, 방패 상태, 막은 피해, 가드 브레이크를 즉시 구분해
   보여준다. 기능 효력 문제는 UI가 아닌 전투 구현 소유다.

### 5. 키보드는 기본 골격이 좋지만 입력 밀도가 고르지 않다

- `WASD/방향키`, `Space`, `Shift`, `E`, `Escape`는 익숙하다.
- `F/G`는 이동 손 주변에 있어 공격·방어로 사용할 수 있다.
- `H` 소비품은 이동 중 누르기 멀고, 급한 회복 행동의 기본값으로는 약하다.
- `K/Shift` 두 개를 대시 안내에 함께 노출하면 학습에는 도움보다 잡음이 될 수
  있다. 보조 바인딩은 유지하더라도 간결한 HUD에는 주 바인딩 하나만 보여도 된다.
- Hollow Knight처럼 키보드 전용 전투도 장르 안에 존재하므로 마우스 공격은
  절대 요구사항이 아니다. 다만 Cardborne이 입력 장치를 `keyboard_mouse`로 묶고
  마우스 전환을 감지하므로, 마우스를 지원 범위로 볼지 UI 전용으로 볼지 문서와
  설정에서 명확히 해야 한다.

### 6. 메뉴는 일부 화면만 보편적인 Back 계약을 지킨다

Pause와 Settings는 기준에 부합한다. 반면 Forge와 Hero Preparation은 화면 안의
버튼을 직접 찾아야 하며 `Escape/B`로 같은 의미의 복귀를 보장하지 않는다. 특히
Forge는 탭, 모델 목록, 세부 패널, 명령 버튼이 함께 있어 D-pad가 시각적 방향대로
움직이는지 검증해야 하지만 현재 검증은 명령 실행과 첫 포커스만 확인한다.

모든 하위 화면에 다음 계약을 공통 적용해야 한다.

- `A/Enter`: 확인 또는 현재 버튼 실행
- `B/Escape`: 현재 팝업 닫기 또는 이전 화면 복귀
- D-pad/방향키: 화면 배치와 일치하는 포커스 이동
- 선형 목록: 처음/끝 순환 여부를 일관되게 적용
- 파괴적 복귀: 확인창과 안전한 기본 포커스
- 현재 입력 장치에 맞는 Select/Back 프롬프트 표시

## Recommended Default Candidate

아래는 구현 명세가 아니라 다음 입력 브랜치에서 비교할 시작안이다.

| Action | Keyboard / mouse candidate | Xbox candidate | Judgment |
| --- | --- | --- | --- |
| Move | A/D + arrows | LS + D-pad | Keep current. |
| Jump | Space | A | Keep current. |
| Dash | Shift; K as optional secondary | B | Keep current, allow remap. |
| Context attack | F; optional LMB | X | Keep current. |
| Guard | G; optional RMB | LT | Test against current Y; add remap and Hold/Toggle option. |
| Interact | E/Enter | RB | Replace high-frequency R3 default. |
| Consumable | Q or user choice; H as secondary | LB or D-pad Up | Test with guard/interact simultaneously; never require analog-only input. |
| Pause | Escape | Menu/Start | Keep current; label it “Pause/Menu,” not “Settings.” |
| UI accept/back | Enter/A; Escape/B | A/B | Apply consistently to every submenu and popup. |

`LT/LB/RB` 선택은 보편 법칙이 아니다. 현재 행동 수에서 오른손 엄지를 점프·대시·
공격에 남겨 두고, 누르는 방어와 반복 상호작용을 분리하기 위한 Cardborne 전용
후보다. 최종값은 30분 패드 플레이테스트와 재지정 사용률로 결정한다.

## Deferred UI Branch Findings

UI 브랜치에서는 아래 항목을 한 묶음으로 읽되, 게임플레이 정책과 구현 소유권을
분리한다.

### UI branch scope

1. 한국어와 영어 설명을 모두 제공하고, 문장은 짧고 직접적으로 다시 쓴다.
2. 현재보다 2~3배 큰 가독성을 목표로 하되 모든 폰트를 기계적으로 배수 확대하지
   않는다. `960x540`에서 중앙 팝업, 정보 우선순위, 줄바꿈·스크롤을 다시 설계해
   핵심 행동과 상태가 실제로 그 크기를 확보하게 한다.
3. NPC, 상인, Forge 상호작용은 전체 화면 전환 대신 중앙 정렬 팝업을 기본으로
   검토한다. `Escape/B` 닫기, 방향키/D-pad 이동, `Enter/A` 확인, 복귀 포커스를
   공통 컴포넌트 계약으로 만든다.
4. 설정 화면에 게임패드·마우스 재지정, 충돌 안내, 기본값 복원, 현재 입력 프롬프트
   갱신을 추가한다.
5. 죽음 화면은 실제 게임플레이 정책이 정해진 뒤 `체크포인트 재시작`, `스테이지
   처음부터`, `메인 메뉴`의 의미와 잃는/유지하는 상태를 짧게 설명한다.
6. 방어 입력, 방어 성공, 정밀 방어, 가드 브레이크가 HUD와 캐릭터 상태에서 즉시
   구분되도록 한다.

### Separate gameplay/state scope

- 죽음 후 체크포인트 또는 스테이지 시작으로 복귀하는 실제 상태 전이
- Save point의 위치·빈도와 저장 범위
- 방어 판정과 피해 차단의 실제 효력
- 몬스터 스테이지 밖 휴식 허브, 상인·Forge NPC, 구매·판매·회복 루프
- 맵 수직성, 적 수와 조합, 전투 밀도

이 항목들은 UI 브랜치가 화면만 만들어 해결할 수 없으므로 별도 게임플레이·스테이지
작업이 먼저 정책을 소유해야 한다.

## Validation Gaps To Add Later

1. 게임패드 행동을 다른 버튼과 디지털 입력으로 바꾼 뒤 저장·재실행·복원되는지
   확인한다.
2. 재지정 직후 HUD, 튜토리얼, 상호작용, 설정 목록의 프롬프트가 모두 갱신되는지
   확인한다.
3. Forge, 준비, 보상, 결과, 설정의 모든 하위 화면에서 `Escape/B`가 동일한 Back
   계약을 지키는지 확인한다.
4. `find_next_valid_focus()` 호출 대신 실제 방향키와 D-pad 이벤트를 보내 시각적
   방향, 선형 목록 순환, 탭 전환, 스크롤 진입·탈출을 검증한다.
5. 키보드 전용, 마우스 포함, 게임패드 전용으로 시작·설정·플레이·종료의 필수 경로를
   각각 완주한다.
6. 방어 Hold/Toggle, 트리거의 디지털 대체, 스틱 클릭 대체를 검증한다.
7. 신규 사용자 패드 플레이테스트에서 R3 발견 시간, 잘못 누른 버튼, 회복 지연,
   방어 중 점프·대시 실패를 기록한다.

## Current Verification Evidence

2026-07-15 현재 빌드에서 다음 캡처를 새로 생성했다.

```text
.codex-runtime/uiux/gameplay_hud/desktop_interaction.png
.codex-runtime/uiux/shell/compact_settings.png
.codex-runtime/uiux/progression/desktop_forge.png
```

이 파일은 생성형 런타임 증거라 Git에 보관하지 않는다. 아래 스크립트로 재생성할 수
있다.

```powershell
.\tools\godot.ps1 --path . --script res://scripts/ui/validation/CaptureShellUI.gd
.\tools\godot.ps1 --path . --script res://scripts/ui/validation/CaptureGameplayHUD.gd
.\tools\godot.ps1 --path . --script res://tools/capture_ui_screenshots.gd
```

집중 검증 결과:

- `GAMEPAD_INPUT_VALIDATION_OK actions=14 device_switches=4`
- `validate_input_remap.gd`: exit code 0
- `PLAYER_MOVEMENT_RUNTIME_VALIDATION_OK`
- `PAUSE_FLOW_VALIDATION_OK viewport=960x540 confirmation=1 settings_return=1`
- `HERO_PREPARATION_UI_VALIDATION_OK`
- `FORGE_SCREEN_VALIDATION_OK viewports=3 tabs=5 command=craft`

이 통과 결과는 구현 회귀가 없다는 증거다. 위 Verdict matrix의 Fail 항목은 검증기가
현재 고정 배치와 제한된 포커스 계약을 성공 조건으로 삼는 데서 생긴 **제품 타당성
차이**다.

## Priority

1. **P0:** 게임패드 재지정 또는 최소한 `R3` 상호작용 대체, 아날로그 행동의 디지털
   대체, 활성 설계 문서와 실제 설정의 모순 해소.
2. **P0:** Forge·준비 화면을 포함한 `Escape/B` Back 계약과 실제 D-pad 포커스 경로.
3. **P0, gameplay:** 방어가 실제로 작동하고 명확히 피드백되는지 수정·검증.
4. **P1:** 방어 `Y` 대 `LT`, 소비품 `RT` 대 `LB/D-pad`, Hold/Toggle을 패드
   플레이테스트로 결정.
5. **P1:** 키보드/마우스 지원 범위를 명시하고 마우스를 지원한다면 버튼 재지정 제공.
6. **P1:** 현재 정확한 배치를 확인하는 테스트를 사용자 경로·재지정·Back 계약
   테스트로 확장.

## Limitations

- 유사 게임의 기본 배치는 장르 관습을 보여 주는 비교 자료이지 Cardborne의 정답이
  아니다. 특히 대시·방어·회복 버튼은 게임마다 다르다.
- 커뮤니티 위키의 배치는 공식 지침보다 낮은 증거 등급으로 사용했다.
- 자동 검증과 정적 코드 검사는 손 크기, 피로, 동시 입력, 신규 플레이어의 발견성을
  측정하지 못한다.
- 이번 작업은 감사와 기록만 수행했다. 입력·UI·게임플레이 코드는 변경하지 않았다.
