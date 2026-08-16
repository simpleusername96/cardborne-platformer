---
type: plan
status: active
owner: BK
created: 2026-08-11
last_reviewed: 2026-08-12
topic: Half-scale world presentation, uninterrupted stage continuation, and full-width combat HUD
scope: Cardborne gameplay camera, visible-world consumers, boss-defeat stage flow, combat-state continuity, gameplay HUD, validators, and Web release QA
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../design/DESIGN.md
  - ../cardborne-performance-engineering-policy.md
  - ../research/performance/cardborne-runtime-architecture-audit.md
  - ./2026-08-11-dense-combat-progression-and-run-completion.md
  - ../../docs/product/vehicle_weapon_balance_spec.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/product/vehicle_upgrade_catalog.md
  - ../../docs/design/VISUAL_SYSTEM.md
---

# 월드 1/2 표시, 무중단 스테이지 진행, full-width HUD 실행 계약

기체·적·시설·아이템·지형을 모두 현재 화면 크기의 1/2로 표시하되 충돌과 월드
좌표의 진실은 유지한다. 1~4스테이지 보스 처치 후에는 보스 전용 보상, XP 회수 대기,
전환 모드, 안전 무적 시간을 거치지 않고 체력만 완전 회복한 뒤 같은 전투 화면에서
다음 스테이지를 즉시 시작한다. 이미 태어난 일반 적과 일반 전투 상태는 남기고,
보스에게 종속된 위협만 제거한다. 5스테이지 보스는 빈 화면 없이 즉시 최종 결과를 연다.
동시에 HP/EXP를 화면 최상단에 빈틈 없는 full-width meter로 두고, 그 아래 좌상단에
현재 stage·run 누적 격파와 Dash/Seeker/EMP cooldown을 한 의미당 한 작은 icon만 쓰는
panel-free compact cluster로 묶는다.

## Purpose

- 목표: 월드 오브젝트의 화면상 크기를 일관되게 절반으로 줄이고, 스테이지 사이의
  명시적 휴식·경계·보상 정지를 없앤다.
- 산출물: 카메라/가시 영역 계약, 연속 스테이지 상태 전이, 선택적 보스 정리,
  일반 적 유지, 최종 확정안의 full-width gameplay HUD, 제품·시각 명세, 집중 validator,
  native/Web 검증 결과다.
- 완료 상태: 모든 작업 체크와 최종 게이트가 통과하고, 실제 1→2 및 4→5 전환에서
  일반 적이 계속 움직이고 공격하는 동안 HUD의 스테이지 번호가 즉시 바뀌며, 기체 체력은
  즉시 최대치가 되고, 전환 모달·배너·타이머·보스 카드가 나타나지 않는다. 체력/EXP는
  모든 지원 viewport에서 최상단 전체 폭을 채우고, 누적 격파와 세 cooldown이 겹침 없이 보인다.

## Why and Current Context

### 화면 크기 변경은 단일 상수로 시작하지만 단일 영향이 아니다

`VehicleRun._build_camera()`는 현재 `Camera2D.zoom == Vector2.ONE`을 사용한다. 카메라
zoom을 `Vector2(0.5, 0.5)`로 바꾸면 CanvasLayer HUD를 제외한 기체, 적, 탄환, 시설,
아이템, 지형, 월드 이펙트가 모두 정확히 절반의 화면 크기로 보인다. 이는 수백 개의
시각 반경과 충돌 반경을 따로 줄이는 것보다 일관되고, 시각과 충돌 진실을 분리한다.

그러나 같은 viewport가 가로·세로 두 배, 면적 네 배의 월드를 보게 된다.
`_visible_world_rect()`를 입력으로 쓰는 스폰 배제, 전투 renderer culling, 위협 레이더,
집단 전술, 성능 pressure가 모두 달라진다. 현재 820px 바깥의 적과 탄환은 낮은 motion
cadence를 쓰므로, 그대로 두면 새 화면 안에서 보이는 원거리 적과 탄환이 끊겨 움직일
수 있다. 주무기 사거리는 visible diagonal을 따라 자동으로 늘어나 projectile 수명과
성능에도 영향을 줄 수 있다.

### 현재 스테이지 전환은 일반 적을 보존할 수 없는 일괄 초기화다

`VehicleRun._complete_stage()`는 보스를 포함해 살아 있는 모든 적을 죽이고 적 탄환을
제거한다. 이후 보스 XP를 0.65초 동안 회수하고 보스 보상 카드를 claim해야만
`_finalize_stage_completion()`이 실행된다. `_begin_stage_transition()`은 다음을 한꺼번에
수행한다.

- `RunMode.STAGE_TRANSITION`을 1.6초 유지한다.
- 1.2초 무적을 주고 기체 속도, 대시, EMP startup, 보조 무기와 대시 runtime을 리셋한다.
- 적, 탄환, 효과, XP 조각, 픽업, 장치, 시설 상태를 지우고 다시 만든다.
- 0.35초 뒤 도착 신호, 1.35초 뒤 첫 다음 스테이지 적을 생성한다.

따라서 일반 적 유지와 “체력만 채운 뒤 즉시 계속”은 타이머 삭제만으로 만들 수 없다.
보스 소유 위협과 일반 전투 상태를 구분하고, 다음 encounter 설정과 기존 actor store를
분리해야 한다.

### 이전 활성 계획과의 우선순위

`2026-08-11-dense-combat-progression-and-run-completion.md`의 미해결 성능 게이트는 계속
유효하다. 다만 그 문서의 “스테이지마다 보스 보상 카드를 claim한 뒤 전환한다”는 계약은
이번 후속 사용자 결정으로 대체한다. 이 문서가 카메라 배율과 스테이지 연속성 범위의
현재 실행 소스다. 기존 문서가 보스 보상/전환 동작을 다시 도입하는 근거가 되어서는 안 된다.

`docs/product/vehicle_weapon_balance_spec.md`가 현재 세 action slot을 Dash/내장 보조 무기
Seeker/장착 발동 무기로 해석하고 기본 공격 cooldown은 계속 표시하지 않는다. 이 문서의
카메라, 무중단 스테이지 전환, 일반 적 보존, HUD 배치 계약은 계속 유효하다.

### 현재 HUD는 요청한 정보 구조와 다르다

`VehicleGameplayHud.HealthPips`는 현재 520×44 고정 폭이고 체력과 EXP 사이에 4px 틈이
있다. 좌측 정보는 `stage defeated/quota`라 run 전체 누적 격파가 아니며, cooldown은
화면 하단의 EMP 하나만 크게 보인다. 그러나 `VehicleHudPresenter` snapshot에는 Dash,
Seeker, EMP의 ready/ratio가 이미 있고, `VehicleRun.stats_enemies_defeated`에는 run 누적
격파가 이미 기록된다. 따라서 새 전투 규칙을 만들 필요 없이 기존 진실을 HUD snapshot과
배치에 정확히 연결하면 된다.

현재 HEAD에서 새로 생성한 Cardborne 한국어 1279×720 결정론적 캡처
`build/captures/hud-current-76210948-ko-1279/04-stage-4-xp-hud.png`를 모든 시안의
편집 대상으로 사용했다. canonical sheet는 style grammar, 사용자 캡처는 상단 bar와 그 아래
정보의 layout 관계만 제공했다. A/B/C와 수정 B의 비교 뒤 사용자 피드백으로 텍스트와 정렬을
다시 잠갔다. 최종안은 `HP/EXP/LV/READY`와 숫자만 보이는 두 줄 full-width meter,
stage/누적 격파를 포함한 다섯 개의 독립 icon, 좌상단 cluster 정렬과 각 item 내부 중앙 정렬을
사용한다. 시안 pixel은
production asset이 아니고 layout·정보·semantic 관계만 구현 계약으로 사용한다.

## Scope and Boundaries

### In scope

- gameplay camera zoom을 0.5로 고정해 모든 월드 표시를 절반으로 만든다.
- HUD, 메뉴, 업그레이드 카드, 가이드북, 미니맵 frame, 위협 레이더 frame은 camera zoom에
  따라 1/2로 줄지 않으며 접근성을 유지한다.
- 체력과 EXP meter를 viewport 최상단에서 각각 100% 폭으로 만들고 세로로 맞붙인다.
- 두 meter 아래 좌상단에 현재 stage, run 누적 격파, Dash/Seeker/EMP cooldown을 최종안의
  panel-free compact icon/value cluster로 배치하고 미니맵은 우측에 유지한다.
- zoom에 따라 가시 영역, 스폰 배제, boss arrival, 위협 레이더, renderer culling,
  원거리 simulation cadence, 주무기 visible range가 같은 좌표계를 사용하게 한다.
- Stage 1~4 보스 처치 시 같은 프레임에 full heal과 다음 stage configure를 완료하고
  계속 `RunMode.PLAYING`으로 둔다.
- 이미 생성된 일반 적, 일반 적 탄환, 플레이어 탄환, player-owned zone/effect,
  XP 조각, 빌드, 레벨, 위치, 방향, 속도, cooldown, 대시 상태를 유지한다.
- 보스 본체, 보스 소환물, 보스 reserve 탄환, 보스 공격 telegraph/denied zone만 정리한다.
- 다음 스테이지의 stage-local 픽업과 변칙 장치는 현재 설계처럼 새 배치로
  교체한다. run-fixed 지형, transit gate cooldown, 탐사 상태는 유지한다.
- Stage 5 보스 처치 직후 최종 결과 모달을 연다.
- 현재 동작과 충돌하는 제품·업그레이드·시각 명세, dead transition enum/상수/검증을 갱신한다.
- 새 표시 workload에 대한 native/Web 성능 증거를 별도 라벨로 기록한다.

### Out of scope

- player/enemy/facility/item collision radius, 이동 속도, 공격 사거리 상수, 맵 좌표,
  월드 크기, spawn 수, quota, 체력, 공격력, 공격 cadence를 일괄 1/2로 바꾸는 일.
- 개별 PNG/SVG를 다시 만들거나 새 player-facing asset을 생성하는 일.
- HUD와 메뉴 자체를 1/2로 축소하는 일.
- A/B/C 시안 이미지를 runtime asset 또는 승인된 시각 자산으로 편입하는 일.
- 아직 HUD snapshot에 없는 보조 무기나 네 번째 cooldown을 추측해 표시하는 일.
- Stage 1~4 기존 일반 적을 다음 stage 계수로 소급 강화하거나 체력을 다시 채우는 일.
- 보스 소환물과 보스 공격을 다음 stage까지 남기는 일.
- stage-local 픽업·장치·시설을 누적해 한 맵에 5스테이지 분량을 동시에 두는 일.
- 일반 level-up 카드와 자연 XP 수집을 제거하는 일.
- 기존 고밀도 전투 성능 문제 전체를 이번 변경의 부수 작업으로 해결하는 일.
- GitHub push, itch.io publish, production dependency, 엔진 버전, thread/Web header 변경.

### Constraints and invariants

- `docs/design/cardborne-universal-art-style-reference.png`의 SHA-256
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`와 기존 semantic
  asset identity를 유지한다.
- 월드 시각과 충돌 geometry는 독립이다. 카메라가 절반으로 표시해도 world-unit
  collision/debug truth는 바뀌지 않는다.
- ordinary spawn은 확대된 visible rect 안에 직접 생성되지 않는다.
- 화면 안 actor/projectile은 “far” cadence 때문에 육안으로 점프하지 않는다.
- 다음 stage quota는 0에서 시작한다. 이전 stage에서 살아남은 countable ordinary를
  다음 stage에서 처치하면 새 quota에 1회 계산한다. summoned 적은 기존처럼 계산하지 않는다.
- 다음 stage 신규 적만 새 stage 체력·공격 계수를 사용한다. carry-over 적은 생성 당시
  수치를 유지한다.
- 보스 전용 보상 source는 더 이상 queue/open/claim하지 않는다. 일반 level-up reward만
  `VehicleRewardRuntime`을 계속 사용한다.
- 보스 처치가 XP 조각을 만들면 일반 XP 조각으로 남는다. stage 전환을 위해 recall하거나
  지우지 않는다.
- 파괴·이동·저장처럼 되돌리기 어려운 외부 동작은 없다. 구현은 task-owned git commit으로
  복구 가능해야 한다.
- 외부 배포와 기존 성능 threshold 변경은 별도 사용자 승인 없이는 하지 않는다.
- 체력/EXP track은 top=0에서 시작하고 둘 사이 물리적 gap은 0px다. 경계가 필요하면
  두 track이 공유하는 1px seam만 사용한다.
- meter 높이는 compact 28/18px, standard 32/22px, large 40/26px, 200% text 52/32px로
  고정한다. 순서는 항상 HP 위, EXP 아래다.
- HP 중앙은 모든 언어에서 `HP current / max`, EXP 중앙은 `LV N · EXP current / required`
  또는 `LV N · EXP MAX`를 보인다. label과 값은 meter 전체 기준으로 중앙 정렬한다.
- status icon cluster는 meter 아래 compact/standard/large `4/6/8px` 간격과
  좌측 `16/24/32px` 안전 여백으로 좌상단에 둔다.
  cluster와 각 item은 layout만 소유하며 visible backing, panel, section, surface, border, divider,
  card, frame, rail, line, blur 또는 shadow plate geometry는 정확히 0개다.
- cluster는 `stage_progress`, `total_defeats`, `dash`, `seeker`, `emp` 순서다.
  stage는 offset deck plate stack, 누적 격파는 custom skull silhouette를 새
  `VehicleUiStatusGlyphRenderer` code-native recipe로 추가하고, cooldown은 기존 action glyph를
  사용한다. OS emoji, flag, star, generic diamond,
  lightning, crosshair는 이 두 새 의미에 사용하지 않는다.
- 각 glyph는 게임 전체에서 정확히 한 semantic ID만 소유한다. 같은 image/emoji/icon을 다른
  의미로 재사용하지 않고, 같은 의미에도 다른 glyph를 병행하지 않는다.
- 모든 item은 작은 icon과 필요한 value만 각각 중앙 정렬한다. stage는 `N / 5`, 누적은 숫자만,
  ready action은 `READY`, cooldown 중 action은 0.1초 단위 `N.Ns`를 표시한다. 별도 label과
  cooldown progress geometry는 만들지 않으며 숫자/READY가 color-independent state cue다.
- icon optical size는 compact/standard/large에서 `16/18/20px`, 200% text에서 `20px`다.
  invisible status slot은 `34×36/36×40/40×44px`, action slot은
  `46×36/50×40/54×44px`다. 200% text에서는 status `72×64px`, action `92×64px`이며
  background를 그리지 않는다. item gap은 compact/standard/large/200%에서 `4/6/8/6px`다. 다섯 item은
  지원 viewport에서 약 `222/246/274/444px` 폭의 한 줄 좌측 정렬을 유지하고
  글자나 glyph를 최소치 아래로 줄이거나 slot 밖으로 clip하지 않는다.
- minimap은 meter 아래 우측에 유지한다. status toast는 meter와 icon cluster/minimap의
  가장 낮은 경계 아래에 두어 겹치지 않게 한다. player-anchored threat radar는 영향을 받지 않는다.

## Assumptions and Locked Behavior

사용자의 “체력만 채워지고”는 Stage 1~4 경계에서 기체에 적용하는 유일한 즉시 혜택이
full heal이라는 뜻으로 고정한다. 무적, cooldown 초기화, 무료 EMP/보조 무기 초기화,
보스 카드, 강제 XP 회수는 없다. 이미 pending인 일반 level-up은 다음 stage가 시작된
뒤 기존 reward loop가 정상적으로 열 수 있지만, stage 번호 변경을 지연시키지 않는다.

상태별 유지 계약은 다음과 같다.

| 상태 | Stage 1~4 보스 처치 결과 |
| --- | --- |
| 기체 | 위치·방향·속도·대시·cooldown·barrier 유지, HP만 max로 설정 |
| 빌드/XP | build, level, XP progress, live shard, pending level-up 유지 |
| 일반 적 | alive/active/HP/status/phase/velocity/squad 그대로 유지 |
| 일반 적 탄환 | 위치·수명·소유·진행 그대로 유지 |
| 플레이어 공격 | 탄환, 기뢰, 대시 장판, 보조 무기 pending 상태 유지 |
| 보스 소유 상태 | 보스 add/system, boss-reserve projectile, boss zone/telegraph 제거 |
| encounter | 이전 queue/cue는 폐기, 다음 stage continuation packet을 즉시 cue |
| quota | 다음 stage 0으로 초기화, carry-over countable 처치부터 새 quota에 반영 |
| 정적 필드 | field layout, run-fixed wall/gate, gate cooldown, 탐사 유지 |
| stage-local object | 이전 pickup/device를 retire하고 다음 stage 배치로 교체 |
| HUD | full-width HP/EXP와 좌상단 panel-free compact icon cluster 유지, stage 번호와 run 누적 격파만 즉시 갱신 |

Stage 5는 next-stage full heal을 하지 않고, 보스 소유 상태를 정리하고 stage report history를
완성한 뒤 같은 frame boundary에서 `RunMode.RESULT`와 결과 모달을 연다.

## Alternatives Considered

1. 모든 visual/collision/좌표 상수를 절반으로 바꾼다. 충돌, AI 거리, 공격 footprint,
   spawn, map topology, 수백 개 validator가 함께 달라져 “크기” 요청보다 훨씬 큰 게임
   재설계가 되므로 기각한다.
2. sprite만 절반으로 표시하고 collision은 그대로 둔다. 보이지 않는 충돌과 불공정한
   피격이 생기므로 기각한다.
3. 월드 root를 `scale=0.5`로 바꾼다. 카메라 추적과 좌표 변환, UI anchor, 맵 원점까지
   함께 이동해 Godot의 camera contract보다 위험하므로 기각한다.
4. `Camera2D.zoom=0.5`를 단일 표시 authority로 쓰고 가시 영역 소비자를 함께 교정한다.
   월드/충돌 진실과 HUD를 유지하면서 모든 월드 항목에 동일하게 적용되어 선택한다.
5. 보스 처치 때 모든 hostile을 유지한다. 보스가 사라진 뒤에도 보스 장판과 소환 시스템이
   공격하는 orphan damage가 생겨 기각한다.
6. 일반 적과 일반 전투만 유지하고 boss ownership tag로 선택 정리한다. 사용자 요구와
   전투 공정성을 함께 만족해 선택한다.
7. 현재 Cardborne 캡처 위 A의 36/18px meter와 stacked 52px cooldown row는 읽기 쉽지만
   상단 점유가 과해 기각한다. C의 28/14px meter는 낮지만 stage 한 줄과 filled cooldown
   card 둘째 줄의 대비가 강해 전투보다 먼저 읽히므로 기각한다. 수정 B의 32/16px full-width
   meter와 compact rail을 잠정 선택했지만 visible label과 좌측 정렬이 최신 피드백과 충돌해
   최종안으로 대체한다. 이후 공통 dark panel과 큰 icon을 둔 label-free refinement도
   사용자 피드백으로 기각한다. 최종안은 32/22px meter, centered universal terms,
   standard 18px의 다섯 panel-free semantic icon/value item과 one-icon/one-meaning catalog다.

## Proposed Design

### A. 하나의 world-view scale

`scripts/vehicle/vehicle_stage_rules.gd`에 gameplay 표시 authority
`GAMEPLAY_CAMERA_ZOOM := Vector2(0.5, 0.5)`를 둔다. `VehicleRun._build_camera()`는 이 값을
사용한다. live gameplay를 재현하는 capture reset만 같은 상수를 사용하고, 명시적으로
close-up을 만드는 visual workbench capture의 개별 zoom은 유지한다.

`_visible_world_rect()`는 Godot canvas inverse로 이미 zoom을 반영하므로 별도 배율을 다시
곱하지 않는다. 대신 그 결과를 소비하는 계약을 정리한다.

- spawn allocator와 boss arrival는 enlarged visible rect와 margin 밖을 우선한다.
- combat renderer와 threat discovery는 같은 rect/canvas transform을 사용한다.
- threat radar 최대 world distance는 현재 1200 고정값과 visible half-diagonal + 480 중
  큰 값으로 계산해, 화면 바로 밖 경고 band가 사라지지 않게 한다.
- enemy/projectile near-simulation 반경도 현재 820 고정값과 visible half-diagonal + 최대
  actor margin 중 큰 값을 사용한다. 화면 안 actor를 20Hz/절반 physics bucket으로 보내지 않는다.
- 주무기 range의 기존 “visible diagonal + 80” 계약은 유지한다. 새 화면 끝까지 수동 사격이
  보이도록 하되 projectile capacity와 frame cost를 성능 단계에서 별도 기록한다.

### B. stage flow에서 reward/transition 상태 제거

`scripts/encounters/vehicle_stage_flow.gd`는 `ORDINARY → BOSS_WARNING → BOSS_ACTIVE → COMPLETE`
만 소유한다. `REWARDS`와 `TRANSITION`, `configure_transition()`,
`record_rewards_complete()`, `record_transition_complete()`를 제거한다. 다음 stage는
`configure(next_stage_index, quota)`가 즉시 새 `ORDINARY` 상태를 만든다.

`VehicleRun`에서는 `RunMode.STAGE_TRANSITION`, transition timer/상수,
`pending_stage_completion`, boss reward enqueue/claim gate를 제거한다. 보스 defeat가
확정되면 stage telemetry snapshot을 history에 먼저 넣고 다음 중 하나를 수행한다.

- Stage 1~4: `_begin_next_stage_continuation()`을 같은 call stack에서 실행하고 mode를 계속
  `PLAYING`으로 유지한다.
- Stage 5: run persistence를 저장하고 `_show_final_result()`를 즉시 실행한다.

다음 stage encounter는 deployment 전용 첫 packet을 제외한다. 첫 continuation packet의
arrival cue는 stage advance와 같은 시각 `t=0.0`에 시작하고, birth는 기존 공정한 cue lead
0.9초 뒤에 허용한다. 이미 남아 있는 일반 적이 계속 압박하므로 별도 빈 시간은 없다.

### C. 선택적 combat-state 정리

보스 종속 actor는 기존 `zone in ["boss_wave", "boss_system"]` 또는
`carrier_id == "stage_boss"`를 하나의 helper로 판정한다. 보스 defeat 시 이 actor만
retire하고 `collective_tactics`, `enemy_grid`, `enemy_store`를 정상 갱신한다.

`VehicleProjectileStore`에는 pool/counter를 보존하는 `retire_boss_hostiles()`를 추가해
`uses_boss_reserve` projectile만 swap-remove한다. `denied_zones`에는 문자열 pattern 검사가
아닌 명시적 `owner_kind: &"stage_boss"`를 기록하고 그 값만 제거한다. 일반 hostile과
player projectile/effect는 보존한다. 짧은 presentation-only effect는 damage를 소유하지
않으므로 자연 만료시킨다.

### D. stage-local refresh와 run-state 보존 분리

현재 `_begin_stage_transition()`을 복사하지 않고 다음 책임으로 나눈다.

- telemetry/history 종료
- boss-owned combat retirement
- stage metadata/layout/encounter/stage-flow 설정
- stage-local pickup/device refresh
- run-fixed terrain/gate/exploration과 live ordinary combat 보존
- HUD dirty/reset 최소 갱신

`terrain_runtime.configure()`는 run 시작 때만 호출해 gate cooldown/progress를 stage 사이에
보존한다. 새 tactical layout의 cover/blocker/pursuit field는 같은 shared field 안에서
다음 stage 계약으로 갱신하고, 보존된 enemy store를 clear하지 않은 채 grid와 coordination
index만 rebuild/reconcile한다.

### E. 최종 HUD — full-width dual meter와 panel-free semantic icon cluster

`VehicleGameplayHud`의 top band를 하나의 responsive owner로 만든다. HP와 EXP는 각각
viewport의 x=0부터 width=viewport width까지 채우고 y=0부터 gap 없이 연속 배치한다.
meter fill은 semantic color를 사용하되 값은 항상 텍스트로도 제공한다. bar 장식은 얇은
industrial border 한 겹만 쓰며 double frame, 중첩 원형 gauge, 장식용 badge를 추가하지 않는다.

HP는 `HP current / max`, EXP는 `LV N · EXP current / required` 또는 `LV N · EXP MAX`를
각 track 전체 기준으로 중앙 정렬한다. 두 meter 바로 아래 좌상단에는 다섯 작은 icon/value item을
compact한 한 줄로 둔다. 순서는 offset deck plate stack `stage_progress`, custom skull
`total_defeats`, 기존 double-thrust `dash`, guided-triad `seeker`, radial-pulse
`emp`다. 앞의 두 glyph는 새
`scripts/presentation/components/vehicle_ui_status_glyph_renderer.gd`의 code-native recipe로
소유하고 `VehicleUiGlyphCatalog`가 노출한다. 뒤의 세 glyph는 기존
`VehicleUiActionGlyphRenderer` recipe를 재사용한다. OS emoji나 raster/SVG는 추가하지 않는다.

각 item은 작은 glyph와 값을 광학적으로 중앙 정렬한다. stage는 `N / 5`, 누적 격파는 숫자만,
action은 `READY` 또는 0.1초 단위 `N.Ns`만 보여 준다.
visible `STAGE`, `누적 격파`, `TOTAL DEFEATED`, Dash/Seeker/EMP label은 만들지 않는다.
cluster와 item 뒤에는 contrast 목적까지 포함해 visible geometry를 전혀 만들지 않는다.
panel, section, surface, backing, border, divider, card, frame, line, progress rail, cooldown ring,
blur와 shadow plate는 모두 금지한다. icon/text 자체의 1px dark outline 또는 text shadow만
world contrast를 위해 허용한다. 모든 glyph ID는 catalog에서 하나의 의미만 소유하며
같은 silhouette를 다른 HUD, minimap, 조준, 속성 의미로 재사용하지 않는다.

`VehicleRun`은 기존 `stats_enemies_defeated`를 `cumulative_defeated` snapshot field로
내보낸다. 현재 stage quota 진행값은 encounter 내부 진실로 남지만 이 cluster에는 표시하지
않는다. stage 전환이 일반 적을 보존하므로 carry-over 적을 다음 stage에서 처치해도 누적은
run 전체에서 정확히 한 번 증가한다. 기존 bottom-center EMP slot은 제거해 정보 중복과
시선 이동을 없앤다.

미니맵은 top band 아래 우측에 그대로 남는다. toast와 buff 문구는 icon cluster/minimap과 충돌하지
않는 중앙 상단 안전 영역으로 이동하고, safe-area 및 text-scale 변경 때 clip/overflow를
validator가 검사한다.

### HUD concept visual-authority evidence

- UIUX gate: Level 4 gameplay HUD redesign. Primary task는 전투 중 HP/EXP, stage, 누적 격파,
  세 cooldown을 시야 손실 없이 읽는 것이다.
- Canonical authority: `docs/design/VISUAL_SYSTEM.md` 전체 읽기 완료;
  `docs/design/cardborne-universal-art-style-reference.png` original detail inspection 완료.
- Expected/observed sheet SHA-256:
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- Canonical sheet provenance: original ImageGen artifact
  `C:/Users/BK/.codex/generated_images/019fbfe9-857e-7453-b72d-20908d848577/exec-0b8aa606-cf55-45c1-abb3-fb3df762b080.png`,
  generated 2026-08-02 12:13:44 KST.
- Current edit target: HEAD `76210948`에서 새로 생성한
  `build/captures/hud-current-76210948-ko-1279/04-stage-4-xp-hud.png`; Korean,
  `1279×720`, text scale `1.0`, layout seed `12886704`. Core capture 42개와 manifest가
  `VEHICLE_STAGE_CAPTURE_COMPLETE`로 종료됐고 이 target을 original detail로 검사했다.
- Layout-only reference: 사용자 캡처 `2026-08-11 22 43 42.png`, original detail inspection 완료.
- Reference method: A/B/C는 current Cardborne edit target, canonical sheet, layout-only user
  capture를 모두 실제 `referenced_image_paths`로 전달했다. 수정 B는 최초 B target까지 포함한
  네 reference를 실제 입력으로 받았다. 최종안은 current target, canonical sheet, layout-only
  capture를 실제 입력으로 다시 생성한 뒤 EXP fill truth만 두 번의 targeted edit로 교정했다.
  2026-08-12 좌상단 교정은 직전 panel-free target과 canonical sheet를 실제 입력으로 사용하고,
  compact 폭이 맞지 않은 첫 결과를 한 번 더 targeted edit했다. 프롬프트 텍스트 참조만
  사용하지 않았다.
- Final preview: `C:/Users/BK/.codex/generated_images/019fee3c-67a2-78a0-a7db-bcd99b681d92/exec-f7c396ef-f2d9-44c5-9ba6-b657215cf6c4.png`,
  `1672×941`, SHA-256
  `8d6f402de03c0eaa3c8876b5a1a49f7e9e8277fdcb20b568fac3b33b8d705433`.
- Selected rendered relation: HP와 EXP track이 각각 x=0에서 viewport right까지 이어지고 gap 0,
  두 meter의 visible value는 전체 중앙 정렬이다. 아래 좌상단 compact cluster는 작은 stacked-stage
  `4 / 5`, skull `418`, Dash `2.4s`, Seeker `READY`, EMP `8.1s` 순서이며 icon/value 외
  visible background geometry는 0개다.
- Status: A/B/C, 수정 B와 최종안은 preview-only layout evidence다. 최종안의 정보 구조,
  크기 관계와 semantic mapping만 선택했으며 생성 pixel은 승인·승격·manifest 편입 대상이 아니다.

## Discovery Closure

| 요구/우려 | 확인한 현재 owner와 동작 | 근거 | 잠근 결정 | Task |
| --- | --- | --- | --- | --- |
| 월드 전체 1/2 표시 | `VehicleRun._build_camera()`, zoom 1.0 | `vehicle_run.gd`, `validate_vehicle_run.gd` | camera zoom 0.5, HUD 유지, collision 불변 | 1.1 |
| 확대된 가시 영역 | `_visible_world_rect()`가 spawn/render/radar/pressure에 공유됨 | run call sites와 capture gateway | 수동 배율 중복 없이 소비자 계약 교정 | 1.2~1.4 |
| 화면 안 far LOD | 820px 밖 enemy/projectile cadence 저하 | `vehicle_enemy_update_schedule.gd`, projectile loop | visible half-diagonal 기반 near radius | 1.3 |
| 현재 보스 종료 | 모든 적/적 탄 제거, XP recall, boss card claim 필요 | `_complete_stage()`, `_advance_reward_queue()` | boss card와 pending gate 제거, 즉시 분기 | 2.1~2.2 |
| 일반 적 유지 | `_begin_stage_transition()`이 `_clear_enemies()` 호출 | `vehicle_run.gd` | non-boss, non-boss-owned actor 상태 보존 | 2.3 |
| orphan boss damage | projectile에 boss reserve, zone에는 불안정한 pattern 문자열 | projectile store, denied zone builders | typed retirement API와 owner tag | 2.3 |
| next-stage 시작 시각 | transition packet cue 0.35, birth 1.35 | `_transition_packets()` | cue 0.0, birth 0.9, mode PLAYING | 2.5 |
| stage-local object | transition이 pickup/device를 전량 재구성 | map runtime helpers | 다음 stage 배치로 교체, terrain/gate는 보존 | 2.6 |
| HP/EXP 배치 | `HealthPips`가 520×44 고정, bar 사이 4px | `vehicle_gameplay_hud.gd` | responsive 100% width, top=0, gap=0 dual meter | 3.2 |
| 누적 격파 | `stats_enemies_defeated`는 존재하지만 HUD가 stage defeated/quota만 받음 | `vehicle_run.gd`, presenter fast cluster | `cumulative_defeated` snapshot을 panel-free cluster에 표시 | 3.1~3.3 |
| cooldown | presenter는 Dash/Seeker/EMP를 모두 발행하나 UI는 bottom EMP만 표시 | presenter, HUD, action glyph renderer | 기존 glyph로 세 slot, bottom EMP 제거 | 3.3 |
| icon 의미 | action catalog는 Seeker/Dash/EMP를 소유하지만 stage/누적 격파 glyph가 없고 기존 minimap/target glyph는 별도 의미를 소유함 | `vehicle_ui_glyph_catalog.gd`, action renderer, minimap marker contract | 새 `vehicle_ui_status_glyph_renderer.gd`가 `stage_progress` deck stack과 `total_defeats` skull을 소유하고 catalog가 모든 icon을 one-ID/one-meaning으로 검증 | 3.3 |
| 시안 선택 | current capture 기반 label-free 시안도 icon과 공통 panel이 지나치게 컸음 | current HEAD capture+canonical sheet를 실제 입력한 panel-free refinement | 작은 panel-free semantic icon/value cluster만 구현, 생성 pixel은 미승인 | 3.2~3.3 |
| 제품/시각 문서 | full heal+1.2s protection+boss reward와 이전 HUD footprint 명시 | product/upgrade/visual docs | 연속 계약, screen/world 단위, 최종 HUD로 갱신 | 3.4 |
| 성능 | 기존 320적 capacity가 이미 red, zoom은 visible workload를 바꿈 | active performance plan/policy | 새 결과를 별도 baseline으로 표시, 기존 실패를 해결로 주장하지 않음 | 4.2 |

Readiness statement:

- 제품, 구조, UI, 상태 유지, 성능 라벨, validation cadence의 재결정 사항은 없다.
- Godot 4.7.1은 `./tools/godot.ps1`, Web export는 `./tools/export_web.ps1`로 실행 가능하다.
- 남은 선택은 이 계약 안의 구현 세부이며 visible behavior나 ownership을 바꾸지 않는다.

## Tasks

### Phase 1: 월드 표시 배율과 가시 영역 정합

Goal: 모든 world-space 표시를 1/2로 만들고 확대된 화면에서 spawn, radar, motion,
projectile이 정확히 동작하게 한다.

Preconditions: 현재 clean HEAD의 camera/visible-world 성능과 1280x720 capture를 한 번 기록한다.

Source owners: `scripts/vehicle/vehicle_stage_rules.gd`,
`scripts/vehicle/vehicle_run.gd`, `scripts/enemies/vehicle_enemy_update_schedule.gd`,
`scripts/presentation/vehicle_combat_renderer.gd`,
`scripts/vehicle/vehicle_run_capture_gateway.gd`

- [x] **1.1** gameplay world view를 0.5로 고정한다.
  - Change: Rules constant와 `_build_camera()`를 연결하고 live-gameplay capture reset의
    hardcoded `Vector2.ONE`만 authority 상수로 바꾼다.
  - Accept: 새 focused validator에서 camera zoom이 정확히 `(0.5, 0.5)`, visible rect가
    같은 viewport에서 기존 world width/height의 2배, player/enemy/facility collision
    상수가 변경 전 값과 같음을 확인한다.
  - Guard: close-up/workbench capture의 명시적 composition zoom은 바꾸지 않는다.
- [x] **1.2** spawn/boss arrival/radar가 확대된 visible rect를 따른다.
  - Change: runtime radar distance를 visible half-diagonal 기반으로 계산하고 spawn allocator와
    boss exclusion이 실제 canvas rect를 받는지 고정한다.
  - Accept: 960x540, 1280x720, 1920x1080 fixture에서 ordinary birth와 선택 가능한 boss
    anchor가 visible rect+margin 안에 없고, 화면 바로 밖 480 world-unit band의 위협이 radar에 남는다.
- [x] **1.3** 화면 안 enemy/projectile cadence를 보존한다.
  - Change: schedule/projectile near threshold를 current minimum과 visible half-diagonal+margin의
    max로 만들고 physics tick마다 한 번 계산해 재사용한다.
  - Accept: visible rect 네 모서리의 ordinary actor와 projectile이 near cadence를 사용하고,
    그 바깥 actor만 기존 far bucket을 사용한다.
  - Guard: active count, attack decision interval, collision sweep, projectile speed/life truth는 바꾸지 않는다.
- [x] **1.4** renderer/capture/performance pressure의 좌표 정합을 갱신한다.
  - Change: hardcoded zoom fixture와 visible-count expectation을 gameplay/intentional close-up으로
    분류하고 gameplay path만 새 authority에 맞춘다.
  - Accept: renderer culling count, `ordinary_center_in_viewport`, radar discovery, primary visible
    range가 동일한 visible rect를 사용하며, capture restore 뒤 live zoom이 0.5다.

Phase gate:

- `validate_vehicle_world_view_scale.gd`, `validate_vehicle_spawn_allocation.gd`,
  `validate_vehicle_run.gd`, `validate_vehicle_combat_renderer.gd`,
  `validate_vehicle_performance_scenarios.gd`가 통과한다.
- 1280x720 original-detail capture에서 player, representative ordinary, facility, pickup,
  terrain gate의 screen-space bounding size가 기존 baseline의 50%±2px이다. HUD CanvasLayer는
  camera zoom 영향을 받지 않으며, 최종 top band 높이는 Phase 3의 responsive 계약을 따른다.

### Phase 2: 보스 처치 후 무중단 stage continuation

Goal: 일반 전투가 살아 있는 채 HP만 회복하고 다음 stage를 즉시 시작한다.

Preconditions: Phase 1 gate 통과.

Source owners: `scripts/encounters/vehicle_stage_flow.gd`,
`scripts/vehicle/vehicle_run.gd`, `scripts/combat/vehicle_projectile_store.gd`,
`scripts/encounters/vehicle_encounter_runtime.gd`

- [x] **2.1** reward/transition state를 stage-flow에서 제거한다.
  - Change: `REWARDS`, `TRANSITION`과 관련 API를 제거하고 boss defeat를 `COMPLETE`, next
    configure를 `ORDINARY`로 만든다.
  - Accept: state unit fixture가 ordinary→warning→boss→complete와 next configure→ordinary만
    허용하고 transition/reward state symbol이 reachable code에 0개다.
- [x] **2.2** boss card/recall/timer 없이 stage를 같은 frame에 넘긴다.
  - Change: boss defeat에서 telemetry history를 finalize한 뒤 Stage 1~4는 continuation,
    Stage 5는 result로 직접 분기한다. pending completion과 boss reward claim gate를 제거한다.
  - Accept: Stage 1 boss damage call 반환 직후 mode `PLAYING`, stage ID `stage_2`, HP=max,
    boss reward pending/current/claimed 모두 false, invulnerability 0이며 stage history가 1개다.
  - Guard: 자연 level-up pending/claim과 failure report는 기존대로 동작한다.
- [x] **2.3** 보스 소유 위협만 선택적으로 retire한다.
  - Change: boss-owned actor helper, projectile-store boss retirement, denied-zone owner tag를 추가한다.
  - Accept: mixed fixture에서 ordinary 3, ordinary hostile projectile 2,
    player projectile 2는 동일 object/state로 남고 boss add 2, boss projectile 2, boss zone 2만 사라진다.
  - Guard: projectile pool 합계와 ordinary/boss counter invariant가 통과한다.
- [x] **2.5** next encounter를 cue 즉시, birth 0.9초로 시작한다.
  - Change: `_transition_packets()`을 continuation packet builder로 바꾸고 deployment first
    packet을 제외한 상대 시각을 cue 0에 맞춘다.
  - Accept: stage advance 직후 첫 cue time 0.0, 0.89초까지 birth 0, 0.9초에 authored first
    group이 최대 tick admission cap 안에서 태어난다. carry-over ordinary는 그 동안 계속 공격한다.
- [x] **2.6** run-state와 stage-local refresh를 명시적으로 분리한다.
  - Change: player combat/XP/ordinary store/terrain gate를 보존하고 pickup/device,
    stage metadata/layout/blocker/pursuit/HUD만 다음 stage로 갱신한다.
  - Accept: 전환 전후 player 위치·속도·aim·dash/cooldown·build·XP shard identity·ordinary
    HP/phase가 같고, terrain gate cooldown과 visited cell이 유지된다. next stage pickup 14와
    mystery device 3은 새 stage ID/수치를 가진다.

Phase gate:

- 기존 `validate_vehicle_stage_transition.gd`를
  `validate_vehicle_stage_continuity.gd`로 대체하고 1→2, 2→3, 4→5, 5→RESULT를 검증한다.
- `validate_vehicle_experience.gd`,
  `validate_vehicle_rewards_ui_audio.gd`, `validate_vehicle_enemy_contact.gd`,
  `validate_vehicle_stage_telemetry.gd`가 통과한다.

### Phase 3: 최종 panel-free semantic gameplay HUD와 활성 계약 정리

Goal: full-width meter와 panel-free icon/value cluster를 구현하고 코드, 사용자 문서, 현지화 검증이
새 동작만 설명하게 한다.

Preconditions: Phase 2 gate 통과.

Source owners: `scripts/vehicle/vehicle_run.gd`, `scripts/ui/vehicle_hud_presenter.gd`,
`scripts/ui/vehicle_gameplay_hud.gd`,
`scripts/presentation/components/vehicle_ui_status_glyph_renderer.gd`,
`scripts/presentation/components/vehicle_ui_glyph_catalog.gd`,
`scripts/presentation/components/vehicle_ui_action_glyph_renderer.gd`,
`scripts/vehicle/vehicle_stage_visual_profile.gd`,
`docs/product/vehicle_game_spec.md`, `docs/product/vehicle_upgrade_catalog.md`,
`docs/design/VISUAL_SYSTEM.md`, UI validator, 두 active ExecPlan

- [x] **3.1** 누적 격파와 세 cooldown을 HUD data contract에 연결한다.
  - Change: `VehicleRun.stats_enemies_defeated`를 `cumulative_defeated` snapshot/presenter
    cluster에 추가하고 Dash/Seeker/EMP ready·ratio·remaining을 하나의 HUD view model로 만든다.
  - Accept: stage 1에서 5회, carry-over 포함 stage 2에서 3회 처치한 fixture가 cluster에 8을
    표시하고 stage quota reset과 무관하다. 세 cooldown은 runtime 값과 0.05 이내로 일치한다.
  - Guard: UI가 gameplay timer를 다시 계산하거나 quota를 누적으로 오인하지 않는다.
- [x] **3.2** HP/EXP를 top full-width dual meter로 재구성한다.
  - Change: fixed `HealthPips` 폭과 4px gap을 제거하고 이 문서의 compact/standard/large/200%
    높이, top=0, width=viewport, gap=0 계약과 centered `HP`/`LV · EXP` 값을 적용한다.
  - Accept: KO/EN 960×540, 1280×720, 1920×1080에서 두 track의 x=0, right=viewport width,
    HP top=0, EXP top=HP bottom이며 1px 넘는 gap/overlap이 없다. `HP current / max`와
    `LV N · EXP current / required|MAX`가 track 전체 중앙에 있고 fill ratio와 실제 값 차이는
    1px 이하다.
- [x] **3.3** 최종 좌상단 panel-free compact semantic icon/value cluster를 구현한다.
  - Change: 새 `vehicle_ui_status_glyph_renderer.gd`에 `stage_progress` deck stack과
    `total_defeats` skull code-native recipe를 추가하고 `VehicleUiGlyphCatalog`가 이를 노출한다.
    기존 Dash/Seeker/EMP glyph slot, top-right minimap, non-overlapping toast를 배치한다.
    cluster는 meter 아래 좌측 안전 여백에 붙이고 모든 작은 glyph/value는 각 invisible slot 중앙에 맞추며
    bottom-center EMP 중복 slot을 제거한다.
  - Accept: 모든 viewport에서 한 줄 순서가 stage icon→skull→Dash→Seeker→EMP이며 stage
    `N / 5`, 누적 숫자, action `READY|N.Ns` 외 visible label은 0개다. standard icon optical
    size는 `18px`, standard cluster x는 `24px`, 폭은 `246px`이고 minimap/toast와 겹치거나 viewport 밖으로
    나가는 node가 0개다. cluster/item background draw count와 cooldown progress geometry는
    각각 0이며 catalog ID coverage와 duplicate semantic owner는 각각 complete/0이다.
  - Guard: OS emoji, 새 raster/SVG, panel, section, surface, backing, border, divider, card,
    frame, progress rail, cooldown ring, blur, shadow plate, 네 번째 cooldown 또는 기존
    minimap/target/affinity silhouette 재사용을 추가하지 않는다.
- [x] **3.4** 제품·시각 명세와 obsolete transition surface를 갱신한다.
  - Change: boss reward/1.2s protection/1.6s transition을 immediate continuation으로 바꾸고
    world-unit/0.5 screen presentation, full-width HUD, 누적 격파, 세 cooldown을 명시한다.
    dead RunMode/상수/localization expectation과 이전 active plan의 충돌 문장을 제거한다.
  - Accept: active spec에서 old transition과 fixed-width/EMP-only HUD를 현재 동작으로 주장하는
    문장이 0개다. failure stage-report UI와 world collision 수치는 유지된다.
- [x] **3.5** 한국어/영어 HUD와 result flow를 검증한다.
  - Change: locale-invariant `HP/EXP/LV/READY`, number/seconds, EXP MAX와 text-scale fixture를
    추가하고 stage/누적 격파의 기존 localization key가 live HUD에 다시 나타나지 않게 한다.
  - Accept: KO/EN 960/1280/1920과 200% text scale에서 clip/overflow/overlap이 0이고 stage와
    누적 격파가 같은 frame에 갱신된다. 두 locale의 icon/value 배치가 같고 Stage 5 결과의
    기본 focus와 dim도 정상이다.

Phase gate:

- `validate_vehicle_hud_presenter.gd`, `validate_vehicle_stage_ui_layout.gd`,
  `validate_vehicle_ui_components.gd`, `validate_vehicle_ui_localization.gd`,
  `validate_vehicle_guidebook.gd`, `validate_cardborne_visual_authority.ps1`,
  `validate_document_authority.ps1`가 통과한다.

### Phase 4: 통합·성능·release 검증

Goal: 변경된 workload를 정직하게 측정하고 native/Web 실제 흐름을 확인한다.

Preconditions: Phase 1~3 task와 phase gate 통과, worktree task scope 확인.

- [x] **4.1** import와 focused integration을 완료한다.
  - Change: material implementation 수정이 끝난 뒤 import와 named validator를 한 번 실행한다.
  - Accept: import error 0, 모든 phase validator exit 0, `git diff --check` exit 0다.
- [x] **4.2** zoom product change의 clean native A/B를 기록한다.
  - Change: 같은 seed/count/viewport/duration에서 current 1.0 baseline과 candidate 0.5를
    별도 clean checkpoint로 측정한다. 이 단계 전 목적·예상 시간·중단 조건을 사용자에게 알린다.
  - Accept: 두 sample이 scenario-valid이고 exact actor/projectile/effect count, viewport,
    focus, renderer, duration이 같다. visible count 차이는 의도된 workload로 기록한다.
  - Guard: frame/presentation/render CPU/GPU p95가 baseline보다 10% 이상 나빠지면 release를
    멈추고 카메라 방식 또는 visible-work scheduling 계약을 개정한다. 5% 미만은 noise로
    성능 주장을 하지 않고, 5~10%면 동일 조건 confirmation pair를 한 번만 실행한다.
- [ ] **4.3** Web release build에서 실제 continuity를 확인한다.
  - Change: `./tools/export_web.ps1` 후 `$npjt-port-guard` codex lane에서 built Web을 열고
    Chrome으로 gameplay를 확인한다.
  - Accept: console error 0, world 1/2/HUD 유지, dash/aim/fire 정상, mixed-enemy Stage 1→2
    연속성, full-width dual meter, 누적 격파, 세 cooldown, Stage 5 result가 실제 브라우저에서 재현된다.
- [x] **4.4** task-owned multi-file 품질 감사를 통과한다.
  - Change: `$codebase-quality-auditor`로 transition responsibility, catch-all 확장,
    dead API, save/API break, missing failure path를 감사하고 작은 task-scoped 결함만 수정한다.
  - Accept: competing stage owner, 문자열 기반 boss cleanup, reachable dead transition,
    validator coverage gap이 없다.

Final gate:

- clean committed checkpoint에서 Phase 1~3 validator, import, Web export, built Web QA,
  declared native A/B evidence가 모두 완료된다.
- 새 성능 결과는 `scenario valid`, `native release performance passed/failed/unqualified`,
  `Web smoke passed`를 구분한다. 기존 dense-capacity failure를 해결했다고 주장하지 않는다.

## Test Plan and Validation Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | `./tools/godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_world_view_scale.gd` | camera/visible consumer 변경 | 관련 입력 변경 |
| Inner loop | `./tools/godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_continuity.gd` | stage/boss cleanup 변경 | 관련 입력 변경 |
| Phase 1 | world-view, spawn, run, renderer, performance-scenario validator 묶음 | Phase 1 task 통과 | Phase 1 owner 변경 |
| Phase 2 | continuity, XP/reward, contact, telemetry validator 묶음 | Phase 2 task 통과 | Phase 2 owner 변경 |
| Phase 3 | HUD presenter/layout/component/localization/guidebook/visual/document authority | Phase 3 task 통과 | UI/doc/visual contract 변경 |
| Final | `./tools/godot.ps1 --path . --headless --import`; `./tools/export_web.ps1`; built Web QA; declared native A/B | 모든 phase 통과 | final input 변경 |

Validation rules:

- 각 task는 가장 좁은 acceptance check만 먼저 실행한다.
- passing check는 관련 입력이 바뀌지 않으면 다시 실행하지 않는다.
- failed check는 관련 구현 변경 또는 새 causal hypothesis 뒤에만 다시 실행한다.
- 광범위한 import/export/performance pair는 구현 안정 후 한 번 실행하고, 시작 전 사용자에게
  목적·범위·예상 비용·중단 조건을 알린다.
- camera product change와 simulation optimization을 같은 성능 개선 commit/claim으로 섞지 않는다.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary |
| --- | --- | --- |
| 실제 visual size를 1/2로 만들려면 collision/world constant 변경이 필요함 | 해당 branch 중단, camera/canvas 증거를 재확인하고 계약 개정 | executor가 임의로 gameplay geometry를 축소하지 않음 |
| 확대 visible rect 때문에 offscreen spawn anchor가 없음 | 기존 allocator의 deterministic farthest valid fallback을 사용하고 visible birth는 거부 | map size/anchor count 변경은 재계획 |
| 화면 안 actor가 far cadence로 보임 | near radius/visible classification만 교정 | 적 수·속도·attack cadence 축소 금지 |
| carry-over actor가 새 layout blocker 안에 겹침 | actor를 삭제/teleport하지 않고 exact motion solver가 다음 이동부터 빠져나오게 함; 완전 고착 fixture면 nearest reachable point로 1회 분리하고 기록 | 대규모 actor reset은 재계획 |
| boss-owned damage를 typed ownership으로 구분할 수 없음 | 해당 state에 명시적 owner tag를 추가 | pattern 문자열 추론으로 ship 금지 |
| native A/B가 10% 이상 악화 | release 중단, evidence를 보존하고 이 계획의 visible scheduling을 개정 | threshold 약화나 workload 축소는 사용자 승인 필요 |
| Stage 5 result가 같은 frame에 열리지 않음 | result owner만 수정하고 실제 boss-defeat fixture 재실행 | 보스 보상/대기 gate 재도입 금지 |
| 200% text에서 icon cluster와 minimap clearance가 부족함 | cluster는 status 72×64px/action 92×64px invisible slot, 좌측 안전 여백과 한 줄 좌측 정렬을 유지하고 inter-item gap을 6px로 둔 뒤 minimap을 같은 top band 안에서 아래로 이동 | visible backing 추가, icon 확대, cluster wrap, viewport 밖 clip 금지 |
| cooldown 표시가 runtime과 어긋남 | presenter snapshot의 ready/ratio/remaining만 사용하고 fixture로 비교 | HUD 자체 timer나 추정 cooldown 금지 |
| material fact가 계약과 충돌 | 영향 branch를 중단하고 계약 수정 | executor의 제품/구조 재선택 금지 |

구현 중 발견한 로컬 mechanics는 visible behavior, ownership, architecture, safety, acceptance를
바꾸지 않는 범위에서만 처리한다.

## Rollback and Safety

- camera authority는 단일 상수라 revert가 명확하다. 개별 asset을 변형하거나 삭제하지 않는다.
- collision/world constants와 save schema는 바꾸지 않는다.
- projectile/zone ownership 추가는 append-only runtime state다. pool capacity와 team contract는 유지한다.
- obsolete transition code 삭제는 git에서 복구 가능하고, success transition UI는 이미 runtime에
  존재하지 않는다. failure report/capture workbench는 별도 owner로 유지한다.
- task-owned 파일만 stage/commit하며 unrelated user change를 revert, clean, reset하지 않는다.
- GitHub/itch 배포는 이 계획 완료 조건이 아니며 별도 요청 전에는 실행하지 않는다.

## Risks

| 위험 | 영향 | 완화 |
| --- | --- | --- |
| 4배 visible area로 더 많은 actor가 렌더됨 | 기존 고밀도 버벅임 악화 | clean A/B, visible count 기록, 10% stop gate |
| visible projectile range 증가 | player projectile 수명/cap 압력 증가 | current exact range contract 유지, count/perf validator |
| 멀리 보이는 적이 낮은 cadence로 점프 | 품질과 조준 공정성 저하 | visible half-diagonal near scheduling |
| radar scan이 화면보다 짧아짐 | 화면 바로 밖 적 표시 소실 | runtime radar distance = max(current, visible+band) |
| carry-over 적이 next quota 난이도를 바꿈 | 초반 quota가 기존보다 빨리 진행될 수 있음 | 사용자 요구대로 kill 시 새 quota에 1회 계산, fixture 고정 |
| 이전 시설 child가 새 counter를 건드림 | 생산 cap/소진 상태 오류 | instance carrier provenance |
| 보스 zone 문자열 정리가 누락됨 | 보스 사망 뒤 orphan damage | typed owner tag와 mixed fixture |
| stage-local object 교체가 눈에 보임 | 완전한 세계 지속감 약화 | modal/time stop 없이 같은 frame 교체; 누적 배치는 scope 밖 |
| 기존 active plan이 old reward를 재도입 | 문서 권위 충돌 | 양 문서에 후속 결정 우선순위 기록 |
| full-width meter가 전투 화면을 과도하게 가림 | 상단 시야 감소 | 최종 responsive 높이, 단일 얇은 border, meter별 추가 배경판 금지 |
| 작은 cooldown glyph에서 상태값이 흐려짐 | 전투 중 판독 실패 | standard 18px glyph와 14px value, 50px action slot, 1px contrast outline, 숫자 시간 또는 READY를 유지; backing/progress geometry는 추가하지 않음 |
| 한 glyph가 HUD·미니맵·조준에서 다른 뜻으로 재사용됨 | 학습한 의미가 깨지고 전투 중 오판 | catalog one-ID/one-meaning validator, stage deck stack과 total-defeats skull의 exclusive owner 고정 |

## Open Questions

없음. “1/2”는 world screen-space scale, “체력만”은 full heal 외 즉시 혜택 없음,
“일반 적 유지”는 boss-owned actor를 제외한 이미 태어난 ordinary combat actor 유지로
결정했다. HUD는 최종 좌상단 panel-free compact semantic icon/value cluster, 누적은 run 전체의
`stats_enemies_defeated`, cooldown은 현재 runtime이 제공하는 Dash/Seeker/EMP 세 개로
결정했다. visible HUD 용어는 `HP/EXP/LV/READY`로 고정하며 icon 하나는 게임 전체에서
하나의 의미만 소유한다. 이 해석이 바뀌면 구현 전에 본 계약을 개정한다.

## Decision Notes

- 2026-08-11: 개별 visual/collision 축소 대신 `Camera2D.zoom=0.5`를 선택했다.
- 2026-08-11: HUD는 축소하지 않고 world-space layer만 축소한다.
- 2026-08-11: collision, speed, map coordinate, world size는 유지한다.
- 2026-08-11: Stage 1~4 boss reward card, forced XP recall, transition timer, transition
  invulnerability를 제거한다.
- 2026-08-11: HP 외 player combat state를 유지하고 mode는 계속 `PLAYING`이다.
- 2026-08-11: 일반 적과 일반/projectile state는 유지하며 boss add/projectile/zone만 정리한다.
- 2026-08-11: carry-over countable enemy는 next quota에 계산하고, 기존 수치를 소급 변경하지 않는다.
- 2026-08-11: run-fixed terrain/gate/exploration은 유지하고 stage-local pickup/device는 교체한다.
- 2026-08-11: next cue는 즉시 시작하되 공정한 0.9초 arrival warning은 유지한다.
- 2026-08-11: 기존 dense-combat 계획의 성능 실패는 별도이며 camera 변경으로 해결됐다고
  주장하지 않는다.
- 2026-08-11: 최초 A/B/C가 current Cardborne snapshot을 편집 대상으로 사용하지 않은
  오류를 폐기했다. 현재 HEAD의 Korean 1279×720 capture를 새로 생성해 모든 교정 시안의
  edit target으로 사용했고, canonical sheet와 layout-only 사용자 캡처도 실제 reference로 전달했다.
- 2026-08-11: 교정 A/B/C와 full-width meter 수정 B를 실제 Cardborne 화면에서 비교해
  수정 B를 잠정 선택했으나, 최신 피드백 뒤 visible label과 좌측 rail은 panel-free
  semantic icon/value cluster로 대체했다.
- 2026-08-11: HP/EXP는 standard 32/22px를 포함한 responsive 높이로 top full-width, gap 0이며
  `HP current / max`, `LV N · EXP current / required`를 track 전체 중앙에 둔다.
- 2026-08-11: meter 아래에 stage deck stack, total-defeats skull, Dash, Seeker, EMP
  다섯 작은 icon/value item을 두며 모든 icon과 값은 각 item 안에서 중앙 정렬한다. 공통/개별 panel, section,
  divider와 cooldown progress geometry는 0개다. 각 glyph는 catalog에서 정확히 하나의
  semantic owner만 가진다.
- 2026-08-11: 최종 preview는 현재 Cardborne capture를 edit target으로 사용했고 EXP 73/112
  fill을 약 65.2%로 교정했다. preview pixel은 runtime asset이 아니며 구현은 code-native
  meter/glyph로 재현한다.
- 2026-08-11: panel-bearing preview를 폐기하고, 동일한 edit target에서 dark panel과 모든
  section geometry를 제거한 `exec-885b8afd-362a-4084-915d-4caf874ccee8.png`를 최종 관계로
  선택했다. 아이콘은 이전 시안의 약 1/3 optical size다.
- 2026-08-11: 시안의 생성 actor/background/icon/ring은 preview-only이며 production asset
  approval이나 manifest 편입으로 간주하지 않는다.
- 2026-08-12: 사용자 후속 결정으로 다섯 item cluster를 meter 아래 중앙에서 좌상단으로 옮겼다.
  compact/standard/large는 좌측 `16/24/32px`에 붙고, item 내부 정렬과 panel-free 계약은 유지한다.
- 2026-08-12: 첫 좌상단 편집은 item 간격이 넓어 폐기하고, 같은 target을 재편집한
  `exec-f7c396ef-f2d9-44c5-9ba6-b657215cf6c4.png`를 최종 preview 관계로 선택했다. 다섯 item은
  1280 기준 약 204px 안에 모이며 preview pixel은 여전히 production asset이 아니다.
- 2026-08-12: 첫 runtime 1280×720 캡처에서 36px action slot의 14px `READY` 값이
  서로 붙는 실제 clipping/spacing 결함을 확인했다. icon optical size와 좌상단 관계는 유지하고
  action slot만 50px로 넓혀 standard cluster를 246px로 교정했다. preview의 204px 관계보다
  실제 판독성과 overflow 0 계약을 우선한다.
- 2026-08-12: 200% runtime 캡처에서 accessibility profile이 base 20px에 다시 2배 배율을
  적용해 값을 40px로 만들고 60/72px slot 밖으로 넘기는 결함을 확인했다. 표준 base 14px를
  한 번만 28px로 확대하고 status/action slot을 72/92px로 넓혀 panel 없이 444px 한 줄로 교정했다.

## Execution Evidence

2026-08-12의 task-owned 구현은 commit `405fd3c1156da5bc81dd4b5c5a2cdccf04f356c9`에
고정했다.

- Phase 1: `validate_vehicle_world_view_scale`, spawn allocation, Run, combat renderer,
  performance-scenario validator가 통과했다. 1280×720 current capture와 새 0.5 camera capture를
  original detail로 비교했고 collision/world 상수는 바꾸지 않았다.
- Phase 2: 새 `validate_vehicle_stage_continuity`가 ordinary actor, ordinary/player
  projectile, XP/build/player combat state 유지와 boss actor/projectile/zone 선택 정리,
  Stage 1→2 same-call continuation, Stage 5 same-call result를 통과했다. projectile
  store, XP/reward, contact, telemetry, arrival 검증도 통과했다.
- Phase 3: HUD presenter/layout/component/localization/guidebook 검증과 visual/document authority
  검증이 통과했다. 최종 캡처는
  `build/captures/half-scale-continuity-hud-ko-960`,
  `build/captures/half-scale-continuity-hud-ko-1280-v2`,
  `build/captures/half-scale-continuity-hud-en-1920`,
  `build/captures/half-scale-continuity-hud-ko-1280-text200-v2`다. 200% 첫 캡처의 겹침을
  재현한 뒤 v2에서 다섯 값의 clip/overlap이 없는 것을 original detail로 확인했다.
- Phase 4 import/quality: Godot 4.7.1 import error 0, named validator exit 0,
  `git diff --check` exit 0다. 품질 감사에서 next-layout 실패 전 부분 stage mutation과
  삭제된 원형 EMP debug contract 때문에 validator coroutine이 종료되지 않던 문제를 수정했다.
- Clean native A/B: `peak_horde`는 276 enemies/140 player projectiles/72 hostile
  projectiles/48 effects, `capacity_pressure`는 320/240/120/96으로 exact count가 일치한다.
  두 baseline/candidate 모두 1280×720, focused, native, authoritative, scenario-valid다.
  0.5 camera로 visible instance는 peak `400→539`, capacity `546→698`로 늘었다.
  peak p95는 frame `143.603→137.787 ms`, physics `42.738→21.039 ms`, presentation
  `9.941→5.294 ms`, HUD `17.449→8.891 ms`다. capacity p95는 frame
  `143.263→144.444 ms`(+0.8%), physics `26.503→24.640 ms`, presentation
  `7.052→6.833 ms`, HUD `11.195→10.034 ms`다. 10% regression stop은 발생하지 않았지만
  baseline과 candidate 모두 기존 absolute threshold는 실패했다. 따라서 scenario와 regression
  gate는 valid/pass, native release performance는 failed이며 성능 해결 주장은 하지 않는다.
- Web: `./tools/export_web.ps1`과 `validate_itch_web_release.ps1`가 통과했다. codex lane
  `127.0.0.1:13029`에서 `index.html/js/wasm/pck`가 각각 HTTP 200과 올바른 MIME으로
  응답했고 서버는 종료했다. in-app browser runtime은 초기화 전
  `failed to write kernel assets: 지정된 경로를 찾을 수 없습니다. (os error 3)`로 두 번
  실패했다. 따라서 built Web static smoke는 pass지만 interactive browser smoke와 실제
  Web continuity는 unqualified이며 task 4.3은 열어 둔다.

## Progress and Next Steps

- Canonical progress: 이 문서의 task checkbox다.
- Current phase: Phase 4, interactive Web QA 대기.
- Next task: browser runtime이 정상화되면 4.3 built Web에서 입력, HUD와 1→2/5→RESULT를 확인한다.
- Last completed gate: Phase 1~3, Phase 4.1/4.2/4.4와 Web static release gate.
- Current blocker: 제품 코드가 아니라 in-app browser kernel asset path 초기화 실패다.
- Update rule: acceptance가 통과할 때 증거를 해당 task에 기록하고 checkbox와 current pointer를
  같은 edit에서 갱신한다.
- Resume rule: worktree에서 checkpoint 입력만 확인한 뒤 첫 unchecked task부터 진행한다.

## Completion and Stop Conditions

Complete when:

- 모든 task acceptance, phase gate, final gate가 통과한다.
- 제품/시각 명세가 구현과 일치하고 이전 active plan의 충돌 문장이 정리된다.
- actual native/Web flow에서 world 1/2, HUD 유지, ordinary continuity, HP-only continuation,
  Stage 5 result와 최종 full-width centered meter/좌상단 panel-free compact semantic icon cluster/세 cooldown을 확인한다.
- task-owned code quality audit와 clean scoped commit이 완료된다.
- 그 뒤에만 frontmatter status를 `done`으로 바꾸고 durable spec 반영을 확인한다.

Replan when:

- camera approach가 10% stop gate를 넘거나 collision/world geometry 변경 없이는 요청을
  만족할 수 없다는 material evidence가 나온다.
- boss-owned state를 일반 combat과 안정적으로 구분할 ownership seam이 현재 구조에 없다.
- stage-local object 유지/교체에 관한 사용자의 후속 결정이 이 계약과 다르다.
- 누적 격파 대신 quota 표시를 다시 요구하거나 HUD에 새 cooldown 종류를 추가하는 후속 결정이 나온다.

Do not replan or stop for:

- 이 계약에 이미 포함된 구현 세부.
- 관련 입력이 바뀌지 않은 passing check.
- 기존 dense-capacity 성능 gate가 이미 red라는 사실 자체. 새 regression 여부는 이 계획의
  A/B 규칙으로 판정한다.
