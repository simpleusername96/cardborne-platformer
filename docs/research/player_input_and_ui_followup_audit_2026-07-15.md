---
type: evidence
status: archived
owner: BK
created: 2026-07-15
last_reviewed: 2026-07-15
topic: Web keyboard control conventions, menu navigation, and deferred UI validity findings
scope: Cardborne Traveler vertical slice across keyboard gameplay, mouse/keyboard menus, HUD prompts, and browser input constraints
source: Local implementation reviewed against official web/accessibility guidance, developer control rationale, and comparable action-platformer controls on 2026-07-15
related:
  - ../design/COMBAT_EQUIPMENT_CRAFTING.md
  - ../design/PRODUCTION_UI_CONTRACT.md
  - ../product/2d_platform_action_card_game_prd.md
  - ../../.agent/execplans/2026-07-15-gameplay-validity-repair.md
---

# 플레이어 입력 관습 및 UI 후속 감사 - 2026-07-15

> Historical evidence only. The owner rejected this audit's final `WASD` and
> `J/K/R` recommendation. The active plan records the accepted arrow-key and
> `X/C/E/A` contract plus the separate UI-branch handoff.

## Purpose

Cardborne의 조작을 브라우저에서 쓰는 키보드 중심 2D 액션 플랫폼 게임에 맞게
검토한다. 특정 게임의 키를 그대로 복제하지 않고, 행동 빈도, 동시에 누르는 키,
양손 분담, 브라우저 예약 동작, 재지정 가능성을 함께 판단한다.

UI 가독성·한국어/영어 문구·중앙 팝업 문제는 별도 UI 브랜치의 입력 자료로만
보관한다. 이 문서는 현재 브랜치에서 UI 구현을 시작하지 않는다.

## Owner Decisions

- `Space` 점프와 `Left Shift` 대시는 유지한다.
- 게임플레이는 키보드 입력을 사용하고 메뉴는 키보드와 마우스로 조작한다.
- 기본 공격, 방어, 소비품, 상호작용 외의 전투 입력을 늘리지 않는다.
- 현재 액티브 기술은 0개다. 나중에 필요성이 검증돼도 동시에 하나만 둔다.
- `E` 상호작용은 상자, NPC, 제단, 대장간, 출구에 말을 걸거나 사용하는 행동이다.

## Sources

2026-07-15에 확인했다.

### Primary and official sources

1. [A Look at Bastion's PC Controls](https://www.supergiantgames.com/blog/a-look-at-bastions-pc-controls/), Supergiant Games.
   빠른 액션에서 이동과 전투를 쉽게 병행하도록 기본 배치를 설계하고, 서로 다른
   입력 방식과 전체 재지정을 제공한 개발자 설명이다. 마우스 공격의 장점은 자유
   조준과 결합됐다는 점도 함께 고려했다.
2. [Element: contextmenu event](https://developer.mozilla.org/en-US/docs/Web/API/Element/contextmenu_event), MDN.
   우클릭은 브라우저 컨텍스트 메뉴를 열며, `preventDefault()`로 막더라도 Firefox의
   `Shift + 우클릭`은 예외가 될 수 있다.
3. [Keyboard Ghosting and the SideWinder X4](https://www.microsoft.com/applied-sciences/projects/anti-ghosting), Microsoft Applied Sciences.
   평범한 키보드는 일부 3키 조합도 놓칠 수 있으므로 필수 동시 입력을 한 손의
   가까운 키에 과도하게 몰지 않아야 한다.
4. [Web Content Accessibility Guidelines 2.2](https://www.w3.org/TR/WCAG22/), W3C.
   필수 기능을 키보드 인터페이스로 실행할 수 있어야 한다는 기준을 제공한다.
5. [Dead Cells Update 29](https://dead-cells.com/patchnotes/29), Motion Twin/Evil Empire.
   방패 토글, 느슨한 패리 창, 입력 사용자화처럼 한 행동의 난이도와 유지 입력을
   선택 가능하게 만든 실제 액션 게임 사례다.
6. [Exporting for the Web](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html), Godot Engine.
   최종 입력 검증은 에디터 실행이 아니라 실제 브라우저 export에서 해야 한다.

### Comparable control evidence

1. [Nine Sols controls](https://www.magicgameworld.com/controls-for-nine-sols/):
   `J`/좌클릭 공격, `K`/우클릭 방어, `E` 상호작용, `Space` 점프, `Shift` 회피를
   기록한 비교 자료다.
2. [Nine Sols parry](https://ninesols.wiki.gg/wiki/Parry): 정확한 타이밍과 이른
   입력을 같은 방어 버튼의 서로 다른 결과로 처리하는 사례다.

비교 자료는 관습을 확인하는 보조 근거다. 제품 결정은 Cardborne의 실제 행동과
브라우저 제약을 우선한다.

## Findings

### Why `F/G/H` fails

- `D`와 `F`는 같은 왼손 검지가 담당한다. 오른쪽으로 이동하며 반복 공격할 때
  한 손가락이 두 행동을 번갈아 처리하므로 가장 자주 쓰는 조합이 불편하다.
- `G` 방어도 같은 손을 더 멀리 뻗게 하고, `H` 회복은 이동 자세를 크게 흐트린다.
- `E`도 `D`와 손가락을 공유하지만 상호작용은 보통 전투가 멈춘 저빈도 행동이므로
  같은 문제가 훨씬 작다.

### Why mouse combat is not the default

좌클릭 공격은 익숙하고 양손 분담도 좋다. 하지만 Cardborne은 마우스 조준이 없어서
마우스를 쥐어야 할 기능적 이득이 작다. 우클릭 방어는 브라우저 메뉴와 충돌하고,
특히 유지 중인 `Shift` 대시와 함께 누를 때 Firefox 예외가 있다. 따라서 마우스
전투는 나중에 실제 web export에서 검증할 선택 배치일 수는 있어도 기본값은 아니다.

### Why `J/K` is the default

- 왼손은 `WASD`, `Space`, `Shift`로 이동을 맡고 오른손은 `J/K`로 전투를 맡는다.
- `J`의 돌기와 나란한 키는 보지 않고 찾기 쉽고, 이동과 공격·방어를 동시에 누르기
  쉽다.
- 브라우저의 우클릭 메뉴나 트랙패드 품질에 의존하지 않는다.
- 비슷한 키보드 배치가 실제 액션 게임에도 존재하지만, 채택 이유는 관습 자체보다
  Cardborne의 자동 표적과 양손 분담이다.

## Recommended Control Contract

| Action | Default | Frequency / reason |
| --- | --- | --- |
| Move / climb | `WASD` | 계속 사용; 왼손 전담. |
| Jump | `Space` | 계속 사용; 엄지로 이동과 병행. |
| Drop through | `S + Space` | 기존 플랫폼 문법과 일치. |
| Dash | `Left Shift` | 계속 사용; 새 키를 배우지 않음. |
| Context attack | `J` | 최고 빈도 전투 행동; 오른손 검지. |
| Guard | `K` | 공격 옆의 한 방어 버튼; 오른손 중지. |
| Active skill | 현재 없음; 채택 시 `L` 하나 | 빈 슬롯을 미리 노출하지 않음. |
| Interact | `E` | 상자·NPC·제단·대장간·출구. |
| Consumable | `R` | 저빈도 긴급 회복; 재지정 가능. |
| Pause / back | `Escape` | 게임과 모든 하위 화면에서 같은 의미. |

모든 실제 gameplay key는 재지정 가능해야 하고, 튜토리얼·HUD·상호작용 안내는
현재 바인딩 하나를 즉시 반영해야 한다. 방향키는 메뉴 포커스에 사용하며,
`Enter`/`Space`는 확인, `Escape`는 닫기/뒤로를 뜻한다.

## Minimal Combat Semantics

### Attack

`J` 하나가 현재의 상황 공격을 실행한다. 가까운 유효 표적은 근접 도구, 그 외에는
장착 원거리 도구의 정책을 사용한다. 별도 약공격/강공격 키를 만들지 않는다.

### Guard

`K` 하나로 두 숙련도를 만든다.

- 피격 직전 누르면 정밀 방어;
- 일찍 눌렀거나 계속 누르면 일반 방어;
- 일반 방어도 실제 피해를 안정적으로 줄이되 안정성/상태 비용을 지불;
- 정밀 방어는 더 좋은 보상을 주되 필수 진행 조건이 아님.

패리와 막기를 다른 버튼으로 나누지 않는다. `Hold/Toggle Guard`는 나중에 설정으로
제공할 수 있지만 기본 전투 동사는 하나다.

### Active skill

현재 장비와 패시브 정령석만으로도 공격·방어 선택이 존재하므로 우선 0개가 가장
단순하다. 플레이테스트에서 공격과 방어 사이의 결정이 반복적이라는 증거가 생기면
다음 조건으로 하나만 추가한다.

- 기본 공격이나 방어를 단순히 더 강하게 복제하지 않음;
- 한 번에 하나만 장착;
- 기본키 `L` 하나;
- 별도 스킬 바, 숫자 슬롯, 스킬 휠 없음.

## Current Implementation Validity

| Area | Verdict | Evidence |
| --- | --- | --- |
| `E` interaction meaning | Pass | `InputBindings.gd`와 `Interactable.gd`가 상자·NPC·시설에 공통 `interact` action을 사용한다. `R3`는 불필요한 별도 gamepad mapping이었다. |
| Jump and dash basics | Pass | `Space`, `Shift`, jump buffer, coyote time, jump cut, double jump, `S + Space`가 구현돼 있다. |
| Attack default | Fail | runtime과 remap validator는 아직 `F`를 기본값으로 고정한다. |
| Guard default and feel | Fail / separate gameplay check | runtime은 아직 `G`; 사용자가 실제 차단 효력을 확인하지 못했고 입력 피드백만으로 성공을 증명할 수 없다. |
| Consumable default | Partial | `H`는 동작하지만 이동 자세에서 멀다. |
| Remapping | Partial | 키보드 재지정은 구현됐지만 마우스 메뉴와 실제 browser export 경로의 입력 회귀가 검증되지 않았다. |
| Product input scope | Fail in runtime | `InputBindings.gd`, Settings, prompt switching, and release validators still contain fixed gamepad behavior. Active specs no longer require it; implementation cleanup remains. |
| Browser delivery | Missing | repository has no `export_presets.cfg`; editor/runtime tests do not prove web export behavior. |

현재 검증 통과는 기존 코드가 기존 배치와 일치한다는 뜻일 뿐, 새 제품 입력 계약이
구현됐다는 뜻이 아니다.

## Deferred UI Branch Findings

UI 브랜치에 아래 항목을 보관한다.

1. 모든 핵심 설명을 짧고 자연스러운 한국어와 영어로 제공한다.
2. 핵심 텍스트는 현재보다 대략 2~3배 큰 가독성을 목표로 하되 모든 폰트를
   기계적으로 확대하지 않는다. `960x540`에서 우선순위, 줄바꿈, 스크롤을 다시
   설계한다.
3. NPC, 상인, Forge 상호작용은 중앙 정렬 팝업을 기본으로 검토한다.
4. 팝업과 하위 메뉴는 `Escape`로 닫고, 방향키/`WASD`로 이동하며,
   `Enter`/`Space`로 확인한다. 닫은 뒤 이전 포커스로 돌아간다.
5. 죽음 화면은 체크포인트/스테이지 시작 재시도와 메인 메뉴의 차이, 잃는 것과
   유지하는 것을 짧게 설명한다.
6. 방어 시작, 일반 방어, 정밀 방어, 가드 브레이크를 자세·효과·짧은 HUD 피드백으로
   즉시 구분한다.

UI 구현 전에 게임플레이 소유자가 죽음 복귀 위치, save point 빈도, 방어 효력,
휴식 구역의 상인/Forge 흐름을 먼저 결정해야 한다.

## Validation Required For The Input Implementation Pass

1. `F/G/H` 기본값을 `J/K/R`로 바꾸고 저장·재실행·초기화 round trip을 검증한다.
2. gameplay input과 prompt switching에서 gamepad 전제를 제거한다.
3. 실제 web export에서 `Space`, `Shift`, `Escape`, 포커스 이탈, 브라우저 스크롤,
   우클릭 메뉴를 검증한다.
4. 이동+점프+대시+공격/방어의 핵심 동시 입력 조합을 일반 키보드에서 검사한다.
5. 신규 플레이어가 안내 없이 공격, 방어, 상호작용을 찾는 시간과 오입력을 기록한다.
6. 일반 방어와 정밀 방어가 서로 다른 결과와 명확한 피드백을 내는지 플레이테스트한다.

## Limitations

- 키 배치 자료는 관습을 보여 줄 뿐 편안함을 보장하지 않는다.
- 자동 검증은 손 크기, 피로, 키보드 ghosting 조합, 신규 사용자의 발견성을 측정하지
  못한다.
- 이번 문서 수정은 제품 방향을 고친 것이며 runtime input과 UI를 바꾸지 않았다.
