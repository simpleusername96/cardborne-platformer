---
type: evidence
status: active
owner: BK
created: 2026-07-29
last_reviewed: 2026-07-29
topic: Continuous-horde rollout problem analysis and recovery-solution selection
scope: Problems introduced or left unresolved by the 2026-07-29 density, readability, item-frequency, and continuous-stage implementation
source: ./execplans/2026-07-29-continuous-multidirectional-horde-readability.md
related:
  - ./continuous-horde-readability-evidence.md
  - ./vehicle-performance-stabilization-evidence.md
  - ./execplans/2026-07-29-horde-foundation-recovery-and-acceptance.md
  - ../docs/product/vehicle_game_spec.md
  - ../docs/product/combat-growth-improvement-direction.md
  - ../docs/design/UI_VISUAL_SYSTEM.md
---

# 직전 대규모 적군 구현 단계 문제 분석과 해결안 선정 근거

## Purpose

직전 rollout에서 구현된 사실, 아직 수용되지 않은 결과, 잘못된 검증 surface와 실제
runtime 병목을 분리하고, 가능한 해결안을 같은 기준으로 비교해 하나의 recovery
solution을 확정한다.

## Sources

- `8a0b003..b87a84b`의 task-owned git history와 diff;
- 현재 gameplay, performance, capture, renderer와 validator source;
- ignored `build/performance/2026-07-29-horde/*.json` payload;
- ignored `build/evidence/2026-07-29-problem-audit/` rendered capture;
- current product, visual, performance와 rollout plan/evidence 문서;
- 사용자 피드백이 남아 있는 현재 conversation history.

## Findings

핵심 finding은 구현된 density contract와 그것을 증명하는 acceptance contract가
분리됐다는 것이다. 아래 결론, 문제 목록, core-reason mapping과 solution comparison은
이 finding을 source별로 구체화한다.

## 결론

직전 단계는 사용자가 명시한 다음 계약을 실제 코드에 반영했다.

- Hard active cap `1/124/172/224/276`;
- stage authored reserve `520/660/816/1026/1260`;
- 네 사분면·다중 sector spawn;
- ranged/denial commit 상한 `3/2`;
- 플레이어 속도 `280 px/s`와 camera zoom `1` 유지;
- actor, projectile, pickup, XP의 presentation footprint 확대;
- stage당 loose pickup 6개와 crate 8개;
- Stage 1–4의 비모달 연속 전환.

따라서 “아무것도 구현되지 않았다”가 문제의 정확한 진술은 아니다. 문제는 이 구현이
실제 플레이에서 충분히 보이고, 읽히고, 매끄럽고, 재미있는지 증명하지 못한 채
완료에 가까운 상태로 서술되었다는 것이다.

가장 큰 원인은 세 종류의 부하를 `current_pressure` 하나로 섞은 것이다.

1. 실제 encounter scheduler와 플레이어 입력이 만드는 **대표 플레이 부하**;
2. 276기 동시 활성이라는 목표를 재현하는 **최대 몰이 부하**;
3. 320-slot pool의 안전성을 확인하는 **용량·lifecycle 부하**.

현재 `current_pressure`는 280기 중 240기를 화면에 넣고 267기를 플레이어 600px
안에 둔다. 이는 실제 four-quadrant scheduler를 재현하지 않는 near-field saturation
fixture다. 이 결과는 “현재 실제 게임이 항상 42 FPS다”라는 근거가 될 수 없지만,
동시에 현재 runtime이 목표 최대 부하를 안전하게 처리하지 못한다는 경고로는
충분하다.

최종 해결안은 다음 네 조각을 하나의 순서로 적용하는 것이다.

1. 대표 플레이·최대 몰이·용량 부하를 분리하고 capture와 performance가 같은 fixture
   owner를 사용하게 한다.
2. 적 수와 무관하게 60 Hz가 필요한 상태만 60 Hz에 남기고, ordinary decision은
   10 Hz, near/far locomotion은 30/20 Hz에 실제로 분리한다.
3. actor 크기는 유지하되 health bar와 priority marker에 명시적인 화면 정보량
   예산을 두고, combat renderer를 critical 60 Hz와 crowd 30 Hz channel로 나눈다.
4. 실제 Stage 1/3/5 telemetry, rendered transition/item evidence, clean native/Web
   성능 matrix와 사용자 플레이 승인 전에는 “완료”로 간주하지 않는다.

보스, 카드, 집단 적 행동, 숨겨진 조작, 지형 연쇄 처치는 중요한 후속 재미 설계지만
이번 recovery에 섞지 않는다. 먼저 대규모 적군이라는 기반이 실제로 작동하고
측정되는 상태를 만든 뒤 별도 vertical slice로 진행해야 한다.

## 분석 범위와 확인한 근거

### 기준 시점

- 시작 기준: `8a0b003` (`Refine combat HUD action states`)
- 직전 구현 범위:
  - `a9ae769` capacity와 pressure 관측값
  - `2263014` multi-sector 적군 밀도
  - `50bd8c2` combat readability와 item presence
  - `9485560` continuous stage transition
  - `d87520b` 최대 부하 최적화
  - `b87a84b` rollout 문서화
- 총 변경: 38 files, 2,349 insertions, 1,055 deletions

### 직접 확인한 소스

| 경로 | 확인한 사실 |
| --- | --- |
| `scripts/performance/vehicle_performance_scenario.gd` | `current_pressure`가 production scheduler 대신 수동 280기 fixture를 만들며, `_walkable_ring_points()`가 340px부터 48개 단위의 동심원으로 적을 채운다. |
| `build/performance/2026-07-29-horde/smoke-current-cached.json` | 280 active, 240 visible, near-600 267, median 42.28 FPS, frame p95 64.84ms, physics p95 15.13ms, presentation p95 8.91ms다. |
| `scripts/vehicle/vehicle_run.gd::_update_enemies()` | budget, status/activation, coordination, behavior/motion이 별도 full scan이고, non-committed ordinary도 매 physics tick `_update_ordinary_enemy()`에 들어간다. |
| `scripts/enemies/vehicle_enemy_specialist_runtime.gd` | rammer commit과 carrier child count가 hot-path에서 다시 전체 enemy array를 순회할 수 있다. |
| `scripts/presentation/vehicle_combat_renderer.gd` | 매 sync마다 모든 batch count를 reset하고 모든 presentation channel을 다시 작성·upload한다. |
| 같은 renderer의 `debug_snapshot()` payload | 280기 fixture가 1,184 visible instances를 만들며 health back/fill이 각각 109, beam 148, shield 40, ring 40, diamond 43개다. |
| `scripts/vehicle/vehicle_run.gd::_capture_pressure_evidence()` | production allocator가 아니라 한쪽으로 길게 늘어선 수동 grid에 276기를 배치한다. |
| `scripts/vehicle/vehicle_run.gd::_capture_field_item_evidence()` | production의 6 pickup + 8 crate가 아니라 pickup 두 개만 만든 뒤 `05-two-field-items.png`를 저장한다. |
| capture sequence | Stage 1–4 success modal을 제거했지만 `91-stage-report.png`에서 Stage 1 success report를 계속 생성하며, 실제 transition banner capture는 없다. |
| `tools/validation/validate_vehicle_run.gd` | legacy `_reset_run()` fixture를 “stage transition respawns at center”라고 부른다. 실제 no-teleport 전환은 별도 `validate_vehicle_stage_transition.gd`가 검사한다. |
| `README.md` | 현재 6 pickup + 8 crate, 124–276 active-cap 계약과 달리 3 pickup + 5 crate, 48–72 active baseline을 여전히 안내한다. |
| lifecycle frontmatter | 두 performance 관련 ExecPlan이 동시에 `active`이고, evidence 문서가 허용되지 않는 `status: superseded`를 사용한다. |

### Rendered evidence

현재 ignored evidence의 `03-maximum-pressure-xp.png`는 화면 왼쪽 경계에 적과 warning
geometry가 겹친 수동 fixture를 보여 준다. 실제 다방향 접근을 입증하지 않는다.
`05-two-field-items.png`는 개별 아이템의 식별성은 보여 주지만, “아이템이 더 자주
보인다”는 production 배치 계약은 보여 주지 않는다.

### 현재 수치의 해석 한계

8개의 5초 안팎 smoke는 같은 280기 label 아래에서도 median FPS가 약 7.14에서
47.14까지 변한다. fixture 구성, visible count, instrumentation 상태와 구현이 함께
바뀌었기 때문에 이 표본들만으로 개별 micro-optimization의 효과를 확정할 수 없다.
마지막 payload도 `authoritative: false`, sample 5초이며 git commit 필드가 비어 있다.
따라서 release evidence가 아니다.

반면 마지막 payload 안에서 다음 방향성은 일관되게 중요하다.

- `enemy_behavior_and_motion` p95: 7.39ms
- 전체 `enemies_and_grid` p95: 8.93ms
- `presentation` p95: 8.91ms
- `combat_and_effects` p95: 3.10ms
- `player_and_rewards` p95: 2.44ms
- draw-call p95: 117, retained batch: 23

즉 draw-call 수 자체보다 ordinary behavior/motion과 CPU-side presentation 작성·upload가
현재 우선 병목이다.

## 공통 용어

앞으로 적 수를 다음처럼 구분한다.

| 용어 | 정확한 의미 | 현재 예 |
| --- | --- | --- |
| authored reserve | 한 stage encounter schedule이 필요에 따라 꺼낼 수 있는 총 적 수. 동시에 존재한다는 뜻이 아니다. | Stage 5 `1260` |
| live | `VehicleEnemyStore`에서 점유 중인 모든 actor. inactive와 auxiliary를 포함한다. | 최대 `320` |
| active ordinary | 행동하고 active cap을 점유하는 일반 이동 적. | Hard peak `276` |
| visible ordinary | 현재 combat renderer의 visible world 안에 있는 active ordinary. | 잘못된 fixture에서 `240` |
| near-900 | 플레이어 중심 900px 안의 active ordinary. | 잘못된 fixture에서 `270` |
| committed | startup/active 공격 권한을 받은 적. body count와 별도다. | ranged `3`, denial `2` |
| authoritative sample | clean commit, 지정된 foreground/scheduler 조건, 10초 warmup + 60초 측정을 모두 만족한 표본. | 현재 없음 |

문서와 UI 설명에서 authored reserve `1260`을 “화면에 1,260기가 나온다”는 식으로
표현하지 않는다. 사용자가 체감하는 수치는 active, visible, near-900, spawn rate다.

## 문제 목록

### P0 — 수용 여부를 막는 문제

| ID | 문제 | 직접 결과 | 상태 |
| --- | --- | --- | --- |
| P0-1 | `current_pressure`가 대표 플레이와 maximum/capacity stress를 혼합한다. | 실제 게임 체감과 성능 수치의 관계를 설명할 수 없다. | 미해결 |
| P0-2 | 현재 maximum fixture에서 frame gate가 크게 실패한다. | 280기 목표를 유지한 채 runtime 개선이 더 필요하다. | 미해결 |
| P0-3 | clean 60초 native/Web 3회, 10분 lifecycle evidence가 없다. | release-performance claim을 할 수 없다. | 미해결 |
| P0-4 | 최대 압력, item frequency, Stage 1→2 전환 capture가 production behavior를 보여 주지 않는다. | 사용자가 요청한 변화가 눈에 보이는지 검증할 수 없다. | 미해결 |
| P0-5 | Stage 1/3/5 × difficulty의 실제 active/visible/spawn/damage telemetry와 사용자 플레이 승인이 없다. | “적이 실제로 많아졌는가”, “난이도가 어떻게 달라졌는가”에 수치와 체감으로 답할 수 없다. | 미해결 |

### P1 — 구현 구조가 대규모 부하에 맞지 않는 문제

| ID | 문제 | 직접 결과 | 상태 |
| --- | --- | --- | --- |
| P1-1 | ordinary decision이 10 Hz로 bucketed되어도 모든 active ordinary가 매 physics tick 전체 update 함수에 들어간다. | 280기로 늘어난 actor 수가 behavior/motion CPU 비용에 거의 선형으로 반영된다. | 미해결 |
| P1-2 | budget/status/coordination/behavior가 별도 scan이고 rammer/carrier helper가 추가 full scan을 만들 수 있다. | hot-path가 같은 사실을 반복 계산한다. | 미해결 |
| P1-3 | renderer가 critical projectile/telegraph와 ordinary crowd를 같은 60 Hz full refresh에 묶는다. | 움직이지 않는 crowd frame에도 전체 batch buffer 작성·upload 비용이 든다. | 미해결 |
| P1-4 | health bar와 priority overlay가 actor 수에 비례해 증가한다. | 큰 sprite가 곧 높은 가독성이 되지 않고 화면 clutter와 presentation 비용이 함께 증가한다. | 미해결 |
| P1-5 | `vehicle_run.gd`가 5,826 lines, 242 functions이며 직전 범위에서 394 lines가 늘었다. | orchestration 파일이 fixture, capture, cadence, behavior 정책을 계속 흡수할 위험이 크다. | 구조 경계 필요 |

### P1 — 검증과 현재 행동이 어긋난 문제

| ID | 문제 | 직접 결과 | 상태 |
| --- | --- | --- | --- |
| P1-6 | capture fixture가 production allocator/layout/stage flow를 재사용하지 않는다. | production이 바뀌어도 capture는 과거 행동을 계속 그린다. | 미해결 |
| P1-7 | 구조 validator 40개 통과가 rendered/feel/performance 수용으로 서술됐다. | “테스트 통과”가 사용자가 볼 수 있는 결과를 대신했다. | 미해결 |
| P1-8 | legacy reset test 이름이 no-teleport stage transition과 충돌한다. | 다음 구현자가 중앙 respawn을 현행 계약으로 오해할 수 있다. | 미해결 |
| P1-9 | Web export 성공만 있고 built Web runtime frame evidence가 없다. | 실제 배포 경로의 성능을 알 수 없다. | 미해결 |

### P2 — 문서·범위·소통 문제

| ID | 문제 | 직접 결과 | 상태 |
| --- | --- | --- | --- |
| P2-1 | product spec을 acceptance evidence보다 먼저 canonicalize했다. | 구현된 목표와 승인된 품질이 같은 것으로 읽힌다. | 상태 표기 보정 필요 |
| P2-2 | 두 performance ExecPlan이 동시에 active다. | 어떤 plan의 scenario와 gate가 현재 authority인지 불명확하다. | lifecycle 보정 필요 |
| P2-3 | historical evidence가 허용되지 않는 `status: superseded`를 쓴다. | doc lifecycle validator와 충돌한다. | lifecycle 보정 필요 |
| P2-4 | root README가 이전 48–72/3+5 계약을 안내한다. | 새 사용자와 다음 agent가 현재 게임 규모를 잘못 이해한다. | 현재 문서 보정 필요 |
| P2-5 | authored reserve, active, visible을 구분하지 않은 숫자 전달 가능성이 있다. | `1260`이라는 큰 숫자와 실제 화면 체감 사이에 신뢰 문제가 생긴다. | 용어 계약 필요 |
| P2-6 | 이번 rollout은 density/readability/flow 기반만 다뤘지만 “게임 개선” 전체로 받아들여질 수 있었다. | 보스·성장·집단 행동·지형 연쇄의 재미 부족은 그대로다. | 후속 범위 분리 필요 |

## Core reasons

### R1. 부하 모델과 수용 모델이 하나로 압축됐다

`current`, `maximum`, `capacity`라는 서로 다른 질문을 하나의 280기 fixture에 맡겼다.
그 결과 fixture가 너무 밀집해도 “production이 느리다”고 읽히고, fixture가 구조상
valid하면 “실제 난이도가 좋아졌다”고 읽히는 양방향 오류가 생겼다.

연결 문제: P0-1, P0-2, P0-3, P0-5, P1-7, P1-9.

### R2. 검증 fixture가 production owner와 별도의 세계를 만들었다

performance와 capture가 spawn allocator, item layout, stage flow를 호출하지 않고
각자 위치와 상태를 수동 생성한다. 따라서 production behavior가 바뀌어도 evidence가
함께 바뀐다는 보장이 없다.

연결 문제: P0-4, P1-6, P1-8.

### R3. 기존 76기 전후 cadence를 276기에 그대로 확대했다

decision bucket은 존재하지만 함수 진입, timer, role branch, collision 준비와
presentation rebuild는 여전히 actor 수에 비례한다. 기존 구조는 76기 clean sample에
맞춰 안정화됐고, 3배 이상의 active actor와 overlay를 같은 비용 구조로 받게 됐다.

연결 문제: P1-1, P1-2, P1-3, P1-4, P1-5.

### R4. 구현 milestone과 사용자 수용 milestone을 같은 것으로 취급했다

capacity, spawn, transition 코드와 deterministic validator가 먼저 끝났고,
rendered evidence, real-play telemetry, Web runtime, explicit user acceptance는
“남은 일”이 됐다. 그런데 문서와 handoff는 이미 rollout 결과를 중심으로 서술했다.

연결 문제: P0-3, P0-4, P0-5, P1-7, P1-9, P2-1, P2-6.

### R5. 용어와 문서 authority가 함께 갱신되지 않았다

active cap과 authored reserve가 바뀌었지만 README, historical evidence status,
두 active plan과 scenario naming이 동시에 정리되지 않았다.

연결 문제: P2-2, P2-3, P2-4, P2-5.

## Core reason별 solution list

### R1 — 부하·수용 모델 분리

1. `production_replay`: 실제 Stage 5 Hard scheduler, production allocator,
   projectile/collision/attack 경로와 고정된 player input route를 사용한다.
2. `peak_horde`: 276 active ordinary와 production role/sector contract를 재현하되
   visible/near-field를 의도적인 범위로 고정한다.
3. `capacity_pressure`: 320 live pool의 simulation capacity를 검증하며,
   user-facing frame gate와 혼동하지 않는다.
4. `lifecycle_pressure`: 10분 retire/reuse/memory integrity를 검증한다.
5. `boss_pressure`: 실제 boss attack과 production reinforcement 규모를 검증한다.
6. `current_pressure` 이름은 폐기한다. “current”가 무엇인지 다시 모호해지기 때문이다.

### R2 — fixture의 parallel truth 제거

1. test-only `VehiclePressureFixture`를 한 곳에 두고 performance와 capture가 같이
   사용한다.
2. fixture는 role/position을 독자 발명하지 않고 `VehicleSpawnAllocator`,
   `VehicleCombatStages`, field-layout result를 입력으로 받는다.
3. item capture는 production layout의 6 loose pickup + 8 crate를 그대로 보여 준다.
4. transition capture는 실제 Stage 1 boss-clear state machine을 통해 Stage 2 spawn까지
   진행한다.
5. Stage 1 success report capture와 잘못 이름 붙은 center-respawn assertion을
   제거한다.

### R3 — simulation과 presentation의 비용을 중요도·주기로 분리

1. 한 tick에 active/critical/decision/motion/support/counter workset을 한 번 만든다.
2. startup, active attack, boss, stun/status damage처럼 hit timing에 관여하는 경로만
   60 Hz를 유지한다.
3. ordinary commit/target/role decision과 cooldown/support는 누적 delta를 사용해
   10 Hz에서 실행한다.
4. non-committed locomotion은 현재 계약대로 near 30 Hz, far 20 Hz에서만 실제
   collision movement를 수행한다.
5. rammer commit 수와 carrier child count를 workset에서 미리 계산해 per-enemy
   full scan을 없앤다.
6. renderer는 projectile/telegraph/boss/committed actor의 critical channel은
   60 Hz, crowd body/XP/ordinary semantic channel은 30 Hz로 나눈다.
7. ordinary health bar는 aim target을 포함해 최대 12개, 추가 priority marker는
   최대 8개로 제한한다. 공격 telegraph, mine danger area, boss cue는 이 예산으로
   숨기지 않는다.
8. actor visual radius, collision radius, player speed, camera zoom은 유지한다.

### R4 — 수용 milestone을 구현보다 앞에 둔다

1. 첫 phase의 결과물을 “고친 capture와 대표 workload”로 만든다.
2. 매 최적화 batch는 동일 fixture 3회 측정에서 target subsystem p95를 최소 10%
   낮추고 frame p95를 5% 넘게 악화시키지 않을 때만 유지한다.
3. 최종 acceptance는 structural validator가 아니라 real-stage telemetry,
   rendered matrix, native/Web frame matrix, 사용자 플레이 승인으로 구성한다.
4. authoritative gate가 끝나기 전 evidence에는 `provisional` 한계를 명시한다.

### R5 — 용어·authority 정리

1. 이 문서의 authored/live/active/visible/committed 용어를 performance payload,
   evidence와 README에 사용한다.
2. 새 recovery ExecPlan 하나만 active로 두고 기존 두 plan은 superseded로 보존한다.
3. historical evidence는 `archived`, 현재 rollout evidence는 acceptance가 끝날 때까지
   `active`로 둔다.
4. root README의 48–72/3+5 설명을 현재 계약으로 바로잡는다.

## 가능한 전체 해결안 비교

### 필수 통과 조건

아래 네 조건 중 하나라도 실패하면 최종안이 될 수 없다.

1. 276 Hard peak, 320 capacity, player speed 280, camera zoom 1을 보존한다.
2. 실제 runtime failure와 evidence failure를 둘 다 해결한다.
3. Godot 4.7 GDScript, Compatibility renderer와 기존 dependency set을 유지한다.
4. 진행 중인 일반 UI/asset 작업을 건드리지 않고 combat renderer와 test harness
   경계 안에서 끝낸다.

### 대안

| 대안 | 장점 | 결정적 한계 | 필수 조건 |
| --- | --- | --- | --- |
| A. 적 수·actor 크기·해상도를 다시 낮춘다 | 가장 빠르게 FPS와 clutter를 낮춘다. | 사용자가 확정한 핵심 방향을 되돌리고 몰이 성장의 기반을 약화한다. | 실패 |
| B. benchmark/capture만 고친다 | 실제 플레이와 evidence의 관계를 복구한다. | 현재 maximum fixture에서 드러난 physics/presentation 병목은 그대로다. | 실패 |
| C. 현재 함수에 micro-cache를 더한다 | 변경 범위가 작고 일부 개선 가능성이 있다. | 이미 batch 51→23 이후 cache의 추가 효과가 작았고, cadence와 overlay scaling 원인을 해결하지 못한다. | 통과하지만 불충분 |
| D. ECS/C#/thread/GDExtension 수준으로 전면 재작성한다 | 장기 headroom은 가장 클 수 있다. | 현재 병목에 비해 비용·parity 위험이 과도하고 dependency/engine 경계를 넓힌다. | 실패 |
| E. fixture authority 복구 + cadence workset + salience-budget renderer | 사용자 계약을 보존하면서 측정과 두 실제 병목을 함께 해결한다. | 두 개의 집중 runtime batch와 full acceptance가 필요하다. | 통과 |

### 가중 평가

점수는 1–5이며, 필수 조건을 실패한 안은 점수가 높아도 탈락한다.

| 기준 | 가중치 | A | B | C | D | E |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 사용자 계약 보존 | 30% | 1 | 5 | 5 | 5 | 5 |
| core reason 해결 범위 | 25% | 2 | 2 | 2 | 5 | 5 |
| 현재 구조에서의 실현 가능성 | 15% | 5 | 5 | 4 | 1 | 4 |
| 측정·회귀·rollback 가능성 | 15% | 4 | 5 | 3 | 3 | 5 |
| concurrent UI isolation | 10% | 5 | 5 | 5 | 2 | 4 |
| 시간 대비 결과 | 5% | 5 | 5 | 4 | 1 | 3 |
| 가중 점수 / 5 | 100% | 2.90 | 4.25 | 3.75 | 3.60 | **4.65** |

B는 점수만 보면 높지만 runtime outcome 조건을 실패한다. E만 모든 필수 조건을
통과하면서 root cause coverage도 가장 높다.

## 확정 solution

### S1. Truth-aligned workload와 evidence

- `production_replay`, `peak_horde`, `capacity_pressure`,
  `lifecycle_pressure`, `boss_pressure`의 다섯 scenario를 사용한다.
- `peak_horde`의 target은 active 276, visible 120–160, near-900 200–240,
  네 사분면과 8 sector 모두 점유, sector당 24–45기다.
- performance와 capture는 한 fixture owner를 재사용한다.
- `production_replay`만 실제 difficulty/flow의 대표성 authority이고,
  `peak_horde`는 maximum readability/performance authority,
  `capacity/lifecycle`은 integrity authority다.

### S2. Frequency-shaped enemy simulation

- `VehicleEnemyUpdateSchedule`은 workset, 누적 cadence delta와 반복 counter만
  소유한다.
- `VehicleRun`은 attack, collision, damage와 role policy를 계속 소유한다.
- `VehicleEnemyStore`는 storage/pool/identity만 소유하며 scheduling policy를
  흡수하지 않는다.
- ordinary critical lane 60 Hz, decision lane 10 Hz, near/far movement
  30/20 Hz를 분리한다.
- 새로운 per-enemy Node, pathfinding, thread, dependency를 만들지 않는다.

### S3. Salience-budgeted retained presentation

- player, hostile/player projectiles, attack telegraphs, boss와 committed body는
  60 Hz다.
- non-committed crowd body, XP와 ordinary semantic overlay는 30 Hz다.
- ordinary health bar는 총 12개, extra priority marker는 총 8개다.
- aim target, committed attacker, recently damaged 가까운 적 순으로 deterministic
  selection한다.
- boss cue, committed attack cue, mine danger area, projectile collision core는
  절대 이 예산으로 생략하지 않는다.
- 확대된 actor/item/projectile footprint와 실제 collision truth는 유지한다.

### S4. Acceptance-first rollout

- 첫 번째 user-testable 결과는 production-aligned maximum/item/transition capture와
  새 scenario payload다.
- 두 runtime batch는 동일 fixture 3회 비교에서 target subsystem p95 10% 이상
  개선이 없으면 보존하지 않는다.
- 최종 gate는 기존 native/Web/frame/capacity/lifecycle threshold를 완화하지 않는다.
- 두 bounded runtime batch 뒤에도 gate가 실패하면 적 수·속도·해상도를 낮추지 않고
  정확한 dominant subsystem과 수치를 보고하고 별도 architecture 승인을 요청한다.

### S5. Broader fun work와의 경계

이번 solution은 “몰이사냥과 성장 재미”의 기반을 안정화한다. 다음 항목은 삭제하거나
거부하는 것이 아니라, performance/readability acceptance 뒤의 별도 gameplay
vertical slice로 남긴다.

- 집단 조건에 따라 합체·돌격·보호막·대형 레이저를 만드는 collective enemy behavior;
- 단순 입력 안의 hold/double-tap 같은 hidden mastery;
- 누적 처치·수집·행동 기반 unlock;
- 지형 연쇄 처치;
- 보스의 고유 objective와 build test;
- 카드 제약 random과 evolution.

이 경계를 지키는 이유는 재미 아이디어가 중요하지 않아서가 아니다. 현재 density
foundation이 실제로 몇 기를 보여 주고 어떤 frame budget을 쓰는지 확정하지 않은 채
새 적 행동과 boss effect를 더하면 같은 실패를 더 큰 범위로 반복하기 때문이다.

## 남은 불확실성과 변경 통제

최종 solution을 실행하는 데 필요한 product/architecture 결정은 닫혔다. 남은 것은
구현 결과가 고정 threshold를 통과하는지 여부다.

- actor 수, 속도, camera, resolution, collision truth 변경은 contingency가 아니다.
- 성능 gate 실패 시 자동으로 새 ECS, C#, thread 또는 native extension으로 넘어가지
  않는다.
- 일반 HUD/menu/hangar/garage asset 또는 layout 변경이 필요해지면 현재 plan을 멈추고
  UI 작업 owner와 범위를 조정한다.
- 보스·카드·지형·hidden mastery를 이번 recovery에 추가하지 않는다.
