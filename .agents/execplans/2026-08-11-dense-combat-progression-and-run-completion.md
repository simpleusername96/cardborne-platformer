---
type: plan
status: active
owner: BK
created: 2026-08-11
last_reviewed: 2026-08-11
topic: Dense-combat performance, final-run completion, upgrade depth, direct pickups, and field-object correction
scope: Five-stage Cardborne run, native and Web runtime, product/UI contracts, validators, and performance evidence
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../design/DESIGN.md
  - ../cardborne-performance-engineering-policy.md
  - ../cardborne-runtime-architecture-audit.md
  - ../2026-08-11-enemy-scale-performance-research.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/product/vehicle_upgrade_catalog.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/reports/2026-08-11-vehicle-upgrade-idea-catalog.md
  - ../../docs/reports/2026-08-11-reinforcement-facility-and-anomaly-device-runtime.md
---

# 고밀도 전투·성장·런 종료 정상화 실행 계획

이 계획은 적이 많을 때 발생하는 극심한 물리 프레임 지연을 실제 비용 소유자부터
줄이고, 5스테이지 보스 처치 후 빈 화면에 머무는 종료 결함을 고친다. 동시에 후반
화력 성장, 직접 아이템 배치, 증원 조립소와 변칙 장치의 역할·정보 전달을 하나의
검증 가능한 제품 계약으로 정리한다.

완료 조건은 “코드가 바뀜”이 아니다. 실제 보스 처치 경로가 결과 모달까지 도달하고,
4~5스테이지 공격 빌드가 새 레벨을 정상 제안·적용하며, 상자 런타임이 완전히 사라지고,
필드 오브젝트의 유한 상태가 결정적으로 재현되며, 깨끗한 성능 시나리오가 동일 적 수로
기존 게이트를 통과해야 한다. 성능 게이트를 통과하지 못하면 완료로 표시하지 않는다.

## Why and Current Context

### 1. 적이 많을 때 느려지는 핵심은 렌더보다 물리 처리다

현재 사용할 수 있는 마지막 깨끗한 capacity 기록 `66f78582`는 적 320, 플레이어 탄
240, 적 탄 120, 효과 96, XP 조각 191 조건에서 프레임 중앙값 133.333ms, p95
142.633ms다. 렌더 CPU 0.971ms, GPU 3.143ms, 드로우콜 p95 99는 기준 안이지만
물리 처리 중앙값 19.077ms, p95 24.768ms는 capacity 기준 p95 6ms를 크게 넘는다.
한 표시 프레임마다 물리를 최대 8회 따라잡는 상태라 고정 물리 프레임의 backlog가
버벅임을 더 키운다.

가장 큰 기록 구간은 `enemies_and_grid`와 `scheduled_ordinary`다. 스케줄러 자체보다
일반 적의 실제 판단·이동·공격(`ordinary_due`)이 크다. 같은 물리 틱 안에서 active
count, attack family, scheduler rebuild, status, overlap, contact, 시설 자식 수를 각각
전체 적 배열에서 다시 계산하는 구조도 있다. 정적 장애물 시야 검사는 일반 적마다
모든 runtime blocker를 훑을 수 있다.

### 2. 5스테이지 빈 화면은 보스 보상 전달 경로가 끊겨 생긴다

`VehicleExperienceRuntime.complete_progression()` 이후에는 XP 조각 생성을 거부한다.
보스 보상 source는 현재 보스 XP 조각 안에서만 `reward_runtime`으로 전달된다. 모든
합법 업그레이드를 먼저 소진한 상태에서 5스테이지 보스를 처치하면 보스 조각이 생성되지
않고 `boss` 보상도 queue에 들어가지 않는다.

`_complete_stage()`는 이미 적·적 탄·위험 영역을 지우고
`pending_stage_completion=true`로 만든다. 하지만 `_advance_reward_queue()`는 현재
스테이지의 `boss` 보상이 claim되어야 `_finalize_stage_completion()`을 호출한다.
결과는 전투가 없는 빈 화면에서 영구 대기하는 상태다.

현재 stage-transition validator는 실제 보스 처치 대신
`_open_upgrade_reward("boss")`를 직접 호출해 이 결함을 우회한다. 기존 두 관련
validator가 통과한 것은 현재 테스트의 coverage gap을 확인할 뿐, 결함이 없다는
근거가 아니다.

### 3. 후반 적 체력 곡선보다 공격 성장 선택지가 짧다

4스테이지 표준/군집 일반 적의 실효 체력 배율은 기본 역할 체력의 약 7.00배이고,
우선/고정 적은 약 6.25배다. 방어막은 주무기 피해를 추가로 55% 줄인다. 현재 카드는
13종, 명목 레벨 36개지만 원소 1개와 선택 보조 2개 제한 때문에 한 런의 합법 선택
상한은 27이다. 공격 카드를 충분히 받지 못하거나 일찍 최대가 되면 4스테이지 후반부터
처치보다 도주가 우세해지고 전투가 늘어진다.

### 4. 아이템 상자는 보상뿐 아니라 엄폐물이라 제거 표면이 넓다

스테이지마다 직접 픽업 6개와 파괴 상자 8개가 있다. 합계 보상은 recall 4개,
repair 10개, repair 총량 490이다. 상자는 체력 24, 이동 충돌, 양 팀 탄환/시야 엄폐,
플레이어 피해, 파괴 효과, 미니맵, 가이드북, 시각 asset 역할을 가진다. 직접 아이템
전환은 보상 blueprint만 바꾸는 작업이 아니라 이 런타임과 계약을 모두 제거하는 작업이다.

### 5. 두 필드 오브젝트는 전투 목적과 상태가 잘 전달되지 않는다

- 증원 조립소는 35% 진행 시 갑자기 나타나며 총 생산량 상한 없이 비할당량 적과 XP를
  반복 생산한다. 시설 한 개를 위해 매 물리 틱 전체 적을 다시 세고, 다음 생산·자식 수를
  화면에서 알 수 없고, 가이드북 전용 항목도 없다.
- 변칙 장치는 첫 타격으로 결과를 공개하지만 외형과 미니맵 상태가 그대로라 잠깐의
  알림을 놓치면 다시 확인하기 어렵다. 네 결과는 모두 유리하지만 타이밍이 나쁘면 영향
  대상이 0일 수 있다.

## Scope and Non-scope

### In scope

- 실제 보스 처치에서 보스 보상을 XP 조각과 독립적으로 queue하고 5스테이지 결과
  모달까지 검증한다.
- 기존 직접 피해 카드 8종에 성능 친화적인 최종 레벨을 하나씩 추가한다.
- 3~5스테이지 보상에 호환 가능한 공격 카드 최소 1장을 결정적으로 보장한다.
- 상자 8개를 같은 보상·결정적 위치의 직접 픽업으로 바꾸고 상자 런타임, 엄폐,
  렌더, 미니맵, 가이드북, 활성 시각 역할을 제거한다.
- 증원 조립소를 시작부터 식별 가능하고 총 생산량이 유한한 시설로 바꾸며 자식 수를
  이벤트로 소유한다.
- 변칙 장치의 첫 타격 공개 결과와 현재 유효 대상 수를 월드·미니맵에서 계속 확인하게
  한다. 기존 결과와 발동 규칙은 유지한다.
- 현재 HEAD에서 동일 수·동일 시드 성능 기준을 만들고, 정해진 분기 기준에 따라 중복
  스캔, 일반 적 시야/이동, overlap cache, combat/effect 비용을 순서대로 줄인다.
- 제품 명세, 업그레이드 카탈로그, 활성 시각 시스템, 가이드북, 한국어/영어 localization,
  validator, Web export를 갱신한다.

### Out of scope

- 적 처치 할당량, active cap, 역할 구성, 공격 동시성, 공격 startup/recovery, 충돌
  정확도, 시각 품질을 낮춰 성능 수치를 맞추는 일.
- 일반 적이나 보스의 체력·공격력·스테이지 곡선을 이번 작업에서 추가로 변경하는 일.
- 새 카드 종류, 진화 시스템, 재추첨 화폐, 영구 메타 성장, 새 슬롯 UI.
- 변칙 장치 결과의 재추첨, 새로운 다섯 번째 효과, 자동 발동 대기.
- 새 raster/SVG 자산, 기존 actor/effect 교체, 새 procedural player-facing visual.
- 엔진 버전 변경, GDExtension, C++/Rust, ECS 전환, 새 production dependency,
  RenderingServer/PhysicsServer 전면 재작성, 멀티스레드 Web 전환.
- 과거 완료 보고서와 visual workbench의 역사적 crate 기록을 현재 동작처럼 재작성하는 일.
- 이 계획 작성 단계에서 GitHub 또는 itch.io 외부 배포를 변경하는 일. 구현 완료 후 기존
  배포 workflow를 실행하는 것은 별도 release 승인 범위다.

## Assumptions and Invariants

| 계약 | 소유자 | 불변 조건 |
| --- | --- | --- |
| 보스 보상 | `VehicleRewardRuntime` | 보스 처치마다 최대 1회 queue/claim; XP 진행 완료와 무관 |
| 결과 전환 | `VehicleStageFlow` + `VehicleRun` | Stage 5 boss claim 뒤 `RunMode.RESULT`와 실제 모달이 같은 프레임 경계에서 열림 |
| 업그레이드 효과 | primary/secondary/element runtime | 표시 수치가 실제 damage source와 같고 새 레벨에서 개체 수·틱·범위 상한을 늘리지 않음 |
| 후반 제안 | `VehicleUpgradeCatalog` | 3~5스테이지에 합법 공격 카드가 있으면 3장 중 최소 1장; ID 중복과 슬롯/원소 규칙 없음 |
| 필드 보상 | field layout + pickup runtime | 스테이지마다 직접 픽업 14개, recall 4, repair 10, 총 repair 490, 같은 시드 재현 |
| 상자 제거 | run/layout/presentation | live crate, crate cover, crate marker, crate guide entry가 reachable runtime에 0개 |
| 시설 생산 | facility runtime | 총 충전 `[2,3,4,5,6]`, 동시 생존 상한도 `[2,3,4,5,6]`, 비할당량, XP는 유한 |
| 장치 결과 | mystery runtime | 스테이지당 3개, 4개 중 3개 중복 없음, 시드 결정, 첫 유효 타격 공개, 파괴 발동 유지 |
| 성능 | performance recorder | 동일 시드·count·viewport, 깨끗한 commit, authoritative scenario만 비교 |
| 시각 | active visual system | 기존 시설·장치·픽업 asset과 theme만 사용; 새 player-facing asset 없음 |

`object_crate`가 과거 guidebook save에 들어 있어도 로드는 실패하지 않아야 한다. 이 ID는
숨겨진 retired alias로만 허용하고 현재 catalog, discovery, preview에는 노출하지 않는다.
나머지 upgrade ID와 save 의미는 바꾸지 않는다.

## Alternatives Considered

### 성능

1. 적 수·공격·효과를 줄인다. 관측 조건과 게임 난이도를 함께 바꿔 원인을 숨기므로
   기각한다.
2. 해상도·asset·renderer를 먼저 줄인다. 현재 render CPU/GPU/draw-call 증거와 맞지
   않아 기각한다.
3. 모든 적을 Node/ECS/Server/스레드로 다시 쓴다. 현재 data-oriented store와 retained
   renderer의 이득을 버리고 Web 배포 위험이 크므로 기각한다.
4. 동일 tick 중복 소유를 제거하고, 세부 계측으로 선택된 일반 적 query와 bounded
   cache를 개선한다. 현재 측정과 가장 직접적으로 연결되어 선택한다.

### 5스테이지 종료

1. 진행 완료 상태에서도 보스 XP 조각만 강제로 만든다. 보상과 XP 운반 결합을 유지해
   같은 종류의 결함이 남으므로 기각한다.
2. `_finalize_stage_completion()`의 boss claim 조건을 제거한다. 보상 UI를 건너뛸 수
   있어 기각한다.
3. 보스 처치가 reward source를 직접 queue하고 XP 조각은 XP만 운반한다. 책임이
   분리되고 queue가 중복을 거부하므로 선택한다.

### 아이템 상자

1. 상자 외형만 없애고 투명 엄폐로 유지한다. 플레이어가 볼 수 없는 충돌이 생겨 기각한다.
2. 보상 상자 대신 무보상 엄폐물을 같은 위치에 만든다. 사용자가 요청하지 않은 전투
   구조를 추가하므로 기각한다.
3. 보상과 엄폐를 함께 제거하고 같은 위치에 직접 픽업을 둔다. 가장 직관적이고 선택한
   결과다.

### 시설과 장치

1. 두 오브젝트를 모두 삭제한다. 복잡성은 줄지만 우선 목표와 전술 환경을 함께 잃는다.
2. 표시만 고친다. 장치에는 적합하지만 시설의 무한 생산·XP·전체 스캔은 남는다.
3. 시설은 유한 충전+명시적 상태, 장치는 기존 규칙+지속 정보로 분리한다. 각 문제의
   크기에 맞아 선택한다.

## Proposed Design

### A. 보스 보상과 최종 결과 전환

`VehicleRun._defeat_enemy()`에서 `stage_boss` 처치를 확정한 순간
`reward_runtime.enqueue(&"boss")`를 호출한다. 보스 XP 조각은 다른 적과 같은 XP만
담고 `reward_source`는 비운다. queue는 같은 source의 current/pending 중복을 이미
거부하므로 중복 보상은 생기지 않는다.

현재 `_advance_reward_queue()`의 순서는 유지한다.

```text
boss defeat
  → boss reward enqueue
  → stage completion pending, combat clear
  → 남은 XP recall/shard 처리
  → pending level-up 처리
  → boss reward open/claim
  → stage 1~4는 다음 stage, stage 5는 RESULT modal
```

`progression_complete=true`이면 boss XP 조각은 생성되지 않지만 boss reward는 이미
pending이므로 즉시 정상 흐름으로 이어진다. 실제 통합 validator는 MAX 빌드에서 보스
`EnemyState`를 처치하고 `_physics_process` 경계를 진행해야 한다. 내부 함수를 직접 열지
않는다. 모드 값뿐 아니라 모달 visible, 한국어/영어 title/body, 기본 버튼 focus,
background dim, 빈 전투 상태를 확인한다.

### B. 공격 업그레이드 최종 레벨과 후반 제안

새 최종 값은 다음으로 고정한다.

| ID | 새 max | 새 최종 값 |
| --- | ---: | --- |
| `split_muzzle` | 3 | 3발 유지, 측면탄 40%+40%, 총 180% |
| `piercing_rounds` | 4 | 추가 관통 4 |
| `homing_missiles` | 3 | 3발 유지, 발당 38, interval 1.35초 |
| `electric_field` | 4 | 22 DPS, 반지름 160, tick 0.25초 |
| `orbiting_blades` | 4 | 4개 유지, 접촉 피해 28, 재타격 0.55초 |
| `drop_mines` | 4 | 피해 88, 2.4초, 최대 5개, 반지름 120, 수명 8초 |
| `thermal_burst` | 4 | 추가 피해 11, 반지름 96 |
| `bio_toxin` | 4 | 중첩당 5.5 DPS, 지속 7초, 최대 중첩 유지 |

`VehiclePrimaryUpgradeRules`는 split L3에서 네 번째 탄을 만들지 않고 L2와 같은 3발을
반환한다. Mine radius도 level 공식으로 132가 되지 않게 L3의 120에 고정한다.
secondary definition은 built-in base 상태를 포함하므로 seeker는 4개 상태, optional은
각 4개 상태를 허용한다. catalog 명목 상태 계약은 44다.

`VehicleUpgradeCatalog`에 공격 ID 집합을 한 번만 정의한다. `stage_index >= 2`이고
합법 공격 후보가 있으면 결정적 shuffle 결과의 첫 공격 후보를 offer에 먼저 넣고,
나머지는 기존 카테고리 다양성 순서로 채운다. 카드 3장, ID 중복 금지, optional 2개,
원소 1개, max 제외 규칙은 그대로다. 합법 공격 후보가 없을 때는 기존 offer와 동일하다.

### C. 상자 없는 직접 아이템 필드

`VehicleFieldLayoutGenerator`는 장치 3개와 픽업 위치 14개를 같은 결정적 후보 순회에서
고른다. 기존 crate 위치 8개를 버리지 않고 direct pickup 위치로 변환해 보상 분포와
공간 분산을 유지한다.

- recall: 기존 loose 2 + crate 2 = 4
- repair 50: 기존 loose 4 + crate 5 = 9
- repair 40: 기존 crate 1 = 1
- repair 총량: `9 × 50 + 40 = 490`

layout 결과에서 `crates` schema를 제거하고 `pickups`만 반환한다. `VehicleRun`의 crate
배열, 생성, 이동 충돌, LOS, 양 팀 탄환 흡수, 피해, 파괴, drop, health, draw/snapshot,
minimap/radar marker를 삭제한다. renderer의 crate batch/health-bar 통계와 reward visual
catalog/glyph/minimap polygon/guide preview/guide entry도 active contract에서 제거한다.

`VISUAL_SYSTEM.md`의 현재 canonical 역할은 여덟 역할에서 crate를 뺀 일곱 역할로
갱신한다. production manifest/provider에서 crate를 unreferenced/retired로 처리하되,
과거 workbench JSON과 완료 보고서는 역사 증거로 유지한다. 실제 PNG 삭제는 active
validator와 workbench 역사 계약을 함께 만족하는지 확인한 뒤 별도 recoverable commit에서만
한다. 기능 완료에는 PNG 물리 삭제가 필요하지 않다.

### D. 증원 조립소와 변칙 장치

#### 증원 조립소

시설 runtime state는 `offline → active → spent/retired` 또는
`offline/active → destroyed`로 명시한다.

- stage 시작부터 기존 시설 asset을 낮은 강조의 offline 상태로 표시한다.
- offline은 충돌·피해·생산이 없고, 35% 진행 시 active가 된다.
- stage별 HP, interval, role은 유지한다.
- 총 생산 충전과 동시 생존 상한은 각각 `[2,3,4,5,6]`이다.
- accepted spawn 때 remaining charge를 1 줄이고 live child를 1 늘린다.
- 자식 defeat/retire 때 facility callback으로 live child를 1 줄인다.
- 마지막 충전 후 live child가 0이면 spent가 되고 0.8초 종료 표현 뒤 retired된다.
- 시설이 먼저 파괴되면 추가 생산만 중단하고 이미 나온 자식은 남는다.
- 자식은 quota 제외, 정상 XP 유지, 시설 직접 보상 없음이다.
- 정상 update는 전체 적을 세지 않는다. debug validator가 주기적으로 실제 배열과
  incremental count를 대조한다.

renderer/HUD는 기존 facility asset, health treatment, theme meter를 사용해 offline,
spawn progress, remaining charge, live child를 표시한다. 새 raster나 procedural glyph를
만들지 않는다. 미니맵은 offline부터 기존 facility silhouette을 낮은 강조로 보여 준다.

#### 변칙 장치

배치, HP 90, 결과 4종 중 3종, 시드 순서, 첫 유효 타격 공개, 파괴 발동, 효과 범위·시간,
보스/고정 구조물 제외 규칙은 바꾸지 않는다.

첫 공개 후 장치 위에 theme 기반 짧은 localized chip(`중력/냉각/소거/유인`,
`Gravity/Cryo/Purge/Decoy`)을 유지한다. 미니맵은 기존 장치 실루엣을 유지하고 공개된
결과의 기존 semantic tint만 반영한다. 5Hz snapshot에서 현재 유효 대상 수를 계산해
작은 count badge로 보여 준다. purge는 범위 안 hostile projectile, 나머지는 실제 효과
대상 ordinary enemy를 센다. 결과를 다시 뽑거나 효과를 자동 발동하지 않는다.

가이드북은 둘을 `필드 오브젝트`로만 분류한다. 시설은 HP, interval, live cap, total
charge를, 장치는 HP와 결과별 radius/duration을 runtime adapter에서 읽는다. 적 목록에는
시설과 장치가 들어가지 않는다.

### E. 성능 계측과 최적화 분기

기능 변경이 끝난 깨끗한 commit을 성능 baseline으로 만든다. 먼저 현재 recorder에
debug-only sub-timer를 추가하고 native에서 64/128/192/256/320 적 scaling sweep을
한 번 실행한다. 각 점은 같은 seed/build/viewport와 고정 warmup/sample을 사용한다.
capacity에서는 decision off, attack/projectile off, presentation off, overlap off 네
ablation을 각 한 번만 실행한다.

측정 구간은 ordinary movement policy, static LOS, dynamic cover LOS, pursuit sampling,
attack commit, active/family/facility scans, overlap snapshot/clear/query, projectile
integration/query/hit/effect다. `median >= 1ms` 또는 `p95 >= 2ms`이면서 recorded physics의
10% 이상인 구간을 material owner로 정의한다.

분기는 미리 고정한다.

1. **항상 적용:** scheduler/frame aggregate를 encounter의 active count와 attack family에
   재사용하고, facility child를 이벤트 카운터로 바꾼다. debug reconciliation으로 누락을
   잡는다.
2. **ordinary LOS/movement가 material:** 정적 blocker를 cell broad phase에 한 번 넣고
   segment가 통과하는 cell 후보만 exact 검사한다. crate 제거 후 dynamic cover path는
   bulkhead 등 실제 변동 owner만 유지한다. 결과 cache는 기존 decision interval까지만
   유효하며 attack commitment exact check는 생략하지 않는다.
3. **overlap이 material:** capacity-sized clear 대신 generation stamp와 active row reuse를
   적용한다. 후보 상한 8과 현재 separation 결과는 그대로다.
4. **combat/effects가 material:** projectile hit receipt와 effect feedback record를 재사용한다.
   projectile cap, sweep, earliest hit, damage, effect 시각은 바꾸지 않는다.
5. **presentation/render가 새 material owner:** 이 계획의 simulation 변경을 멈추고 측정
   자료로 계획을 개정한다. renderer asset/quality를 임의로 낮추지 않는다.
6. 어느 named owner도 기준을 만족하지 못하면 instrumentation이 부족한 것이다. 추측성
   구조 변경을 하지 않고 계획을 개정한다.

각 변경 뒤 동일 capacity 한 번으로 owner 감소를 확인한다. 전체 scaling sweep은 마지막
후보가 고정된 뒤 한 번만 다시 실행한다. 최종 clean commit에서 peak와 capacity 60초
authoritative pair를 실행하고 기존 release gate를 그대로 사용한다.

## Responsibility and File Map

| 책임 | 주 소유 파일 | 함께 갱신할 계약 |
| --- | --- | --- |
| final reward | `scripts/vehicle/vehicle_run.gd`, `scripts/rewards/vehicle_reward_runtime.gd` | stage transition validator |
| upgrade data | `data/cards/vehicle/*.tres`, `data/weapons/vehicle/secondary/*.tres` | primary rules, secondary runtime/catalog, previews, product catalog |
| offer policy | `scripts/cards/vehicle_upgrade_catalog.gd` | upgrade-system validator |
| direct field items | `scripts/vehicle/vehicle_field_layout_generator.gd`, `scripts/vehicle/vehicle_run.gd` | field layout, pickup contact, map/destructible validators |
| facility | `scripts/vehicle/vehicle_reinforcement_facility_runtime.gd` | run integration, renderer snapshot, guide stats |
| anomaly device | `scripts/vehicle/vehicle_mystery_device_runtime.gd` | renderer/UI snapshot, map mechanics, guide stats |
| active presentation | renderer, minimap builder, world/reward/glyph catalogs, guide preview | visual system, localization, layout/UI validators |
| performance | `vehicle_run`, enemy schedule, spatial grid, performance recorder/scenarios | raw clean JSON and performance report |
| product truth | game spec, upgrade catalog, visual system | Korean/English complete runtime surfaces |

`vehicle_run.gd`는 orchestration과 runtime integration만 소유한다. 새 upgrade 계산은 각
weapon owner에, 시설 lifecycle은 facility runtime에, 시각 조합은 renderer/UI owner에
둔다. performance helper가 필요하면 query/schedule responsibility에 맞는 별도 파일을
사용하고 `vehicle_run.gd`에 범용 cache를 쌓지 않는다.

## Milestones and Progress

- [x] `M0` 현재 HEAD 코드, 활성 spec, design/visual authority, performance policy, 마지막
  authoritative record, 시설/장치/업그레이드 동작을 추적한다.
- [x] `M0` 성능 연구와 업그레이드 아이디어를 별도 문서화하고 선택지·근거·한계를 남긴다.
- [x] `M0` 5스테이지 빈 화면의 실제 reward transport 결함과 validator coverage gap을
  정적으로 확인하고 결정 완료 계획을 작성한다.
- [ ] `M1` 보스 보상 source를 XP 조각과 분리하고 실제 MAX progression boss-defeat 결과
  통합 validator를 추가한다.
- [ ] `M2` crate blueprint를 14개 direct pickup으로 통합하고 crate runtime/cover/UI/guide
  active surface를 제거한다.
- [ ] `M3` 공격 카드 8종의 새 최종 레벨, 후반 공격 offer 보장, preview/localization/spec,
  계산 validator를 구현한다.
- [ ] `M4` facility 유한 충전·offline/spent lifecycle·incremental child count와 mystery
  revealed-state/count presentation, guidebook stat을 구현한다.
- [ ] `M5` 기능 변경 후 clean baseline과 scaling/ablation evidence를 한 번 수집하고 material
  owner를 고정된 기준으로 선택한다.
- [ ] `M6` 중복 aggregate scan 제거와 선택된 LOS/overlap/combat branch를 순서대로 구현하고
  각 owner를 동일 capacity에서 재측정한다.
- [ ] `M7` 제품 명세, upgrade catalog, active visual system, localization, save-compatible
  retired crate alias를 현재 동작과 일치시킨다.
- [ ] `M8` focused validator, import, Web export, built native/Web 수동·렌더 QA, 최종 clean
  peak/capacity pair를 실행한다.
- [ ] `M9` task-owned code quality audit를 통과하고, durable spec에 결정을 옮긴 뒤 이 계획을
  `done`으로 표시하고 coherent scoped commit을 만든다.

Current pointer: `M1`. 조사와 결정은 끝났고 구현은 시작하지 않았다. 열린 제품 선택은 없다.

## Acceptance Criteria

### 기능

- 진행을 모두 완료한 Stage 5에서 실제 보스 처치 후 빈 전투 상태를 거쳐 boss reward가
  한 번 열리고, claim 뒤 클리어 결과 모달이 보이며 focus가 기본 버튼에 있다.
- Stage 1~4도 보스 XP와 boss reward 순서를 유지하고 다음 스테이지로 한 번만 전환한다.
- 8개 공격 카드는 표의 새 max와 실제 최종 값을 표시·적용한다. 새 레벨에서 player
  projectile, seeker, blade, mine, query radius, tick 수가 표의 상한을 넘지 않는다.
- 3~5스테이지에 합법 미완성 공격 카드가 있으면 offer 3장 중 최소 1장이고 같은 seed는
  같은 offer를 만든다.
- 모든 합법 업그레이드 소진은 실제 선택 상한 33에서 종료되고 가짜 카드가 나오지 않는다.
- 각 스테이지 direct pickup은 정확히 14개이며 recall 4, repair 10, 총 repair 490이다.
  `crates` runtime/schema/live collision/cover/damage/drop/marker/guide entry는 0개다.
- 시설은 시작부터 offline 위치가 보이고 35%에서 활성화되며 총 `[2,3,4,5,6]`회만
  생산한다. 파괴·소진·stage retire 뒤 추가 생산이 없고 event child count가 실제 수와 같다.
- 장치 3개의 공개 결과가 파괴 전까지 월드와 미니맵에서 다시 식별되고 5Hz 유효 대상
  count가 실제 effect eligibility와 일치한다.
- 가이드북의 적에는 적만, 필드 오브젝트에는 시설·장치·직접 아이템만 들어가며 실제
  runtime stat을 한국어/영어로 표시한다.

### UI/시각

- 새 raster/SVG/player-facing procedural asset이 없다. 기존 canonical sheet SHA-256
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`가 유지된다.
- 결과 모달, upgrade offer, facility/device 상태, guidebook이 960/1280/1920 너비와
  한국어/영어, 200% text scale에서 잘리거나 겹치지 않는다.
- keyboard/controller focus가 결과 모달, upgrade card, guidebook back icon에서 보인다.
- 장치 short chip과 count는 player, boss telegraph, damage warning, minimap priority를
  가리지 않는다.

### 성능

- 최종 비교는 clean committed, scenario-valid, exact-count native run이다.
- 기능 전 baseline과 최종 run의 seed/build/viewport/count/load class가 같다.
- capacity gate: simulation p95 <= 6ms, p99 <= 8ms, frame p95 <= 18ms,
  p99 <= 25ms, median >= 59 FPS, 1% low >= 55 FPS, draw calls p95 <= 200,
  33.3ms 초과 연속 frame <= 1이다.
- peak와 capacity 모두 threshold `passed=true`이고 scenario counts, supported viewport,
  memory/lifecycle, combat batches가 모두 true다.
- Web release build는 동일 기능을 실행하고 브라우저 console error가 없으며 dense fixture에서
  catch-up 고착이나 입력 정지가 없다. Web 측정은 native gate를 대체하지 않는다.

## Test Plan

### 구현 중 저비용 검사

- Reward: `validate_vehicle_stage_transition.gd`, 새 progression-complete boss-defeat fixture.
- Upgrade: `validate_vehicle_upgrade_system.gd`, `validate_vehicle_upgrade_ui.gd`, primary/
  secondary focused contract.
- Pickup/crate removal: `validate_vehicle_field_layout_generation.gd`,
  `validate_vehicle_destructible_terrain_flow.gd`, `validate_vehicle_damage_feedback.gd`,
  `validate_vehicle_run.gd`.
- Facility/device: `validate_vehicle_reinforcement_facility.gd`,
  `validate_vehicle_mystery_device_runtime.gd`, `validate_vehicle_map_mechanics_integration.gd`.
- Guide/UI: `validate_vehicle_guidebook.gd`, `validate_vehicle_stage_ui_layout.gd`, localization
  and semantic asset coverage validators.
- Visual authority: `tools/validation/validate_cardborne_visual_authority.ps1`.
- 각 milestone 뒤 관련 validator만 실행하고 `git diff --check`를 실행한다.

### 통합 검사

- 같은 seed에서 5스테이지를 진행하는 deterministic fixture로 direct pickup 총량,
  facility charge, mystery outcomes, upgrade exhaustion, boss reward, result modal을 연결한다.
- Stage 4 late build에서 모든 새 공격 source가 실제 damage receipt에 나타나는지, 방어막
  multiplier 적용/우회가 기존 계약과 같은지 확인한다.
- 상자 제거 후 player/ordinary/boss projectile의 earliest swept hit가 wall, bulkhead,
  actor에 대해 그대로이고 보이지 않는 crate collision이 없는지 확인한다.
- Korean/English 960/1280/1920과 200% text scale capture를 생성해 original detail로
  inspect한다. 결과 모달은 실제 reachable state에서 캡처한다.

### 넓은 검증과 비용 통제

성능 scaling sweep, 최종 60초 pair, 전체 import/Web export는 기능 구현이 안정된 뒤 한 번씩
실행한다. 시작 전 사용자에게 목적, 예상 시간, 실행 수, 중단 조건을 알린다. unrelated
Godot/browser process가 있으면 죽이지 않고 owner를 확인하며 authoritative 실행을 미룬다.

최종 단계에서:

1. `./tools/godot.ps1 --path . --headless --import`
2. 관련 focused validator 전체
3. visual authority와 asset/localization coverage
4. Web release export
5. `npjt-port-guard` codex lane의 built Web smoke와 Chrome QA
6. clean commit의 native peak/capacity authoritative pair
7. codebase quality audit

중 하나가 실패하면 해당 owner만 수정하고 관련 focused test를 다시 실행한다. material
performance 변경이 있었을 때만 최종 pair를 한 번 다시 실행한다.

## Rollback and Safety

- 보스 보상 enqueue는 기존 source ID와 idempotent queue를 사용해 save migration이 없다.
- upgrade ID는 유지하고 max/value array만 append한다. 기존 build level은 그대로 해석된다.
- crate save discovery ID는 retired alias로 받아 load 오류를 막는다. 현재 런에는 crate를
  복원하지 않는다.
- facility/device는 run-scoped state라 영구 save migration이 없다.
- 성능 변경은 actor 수, 공격 truth, collision truth, 시각 품질을 바꾸지 않는다.
- production dependency, engine setting, thread support, Web header를 변경하지 않는다.
- 기존 crate PNG 삭제가 필요하면 active reference 0개와 historical validator 영향을 먼저
  확인하고 별도 commit으로 처리한다. 삭제는 git에서 복구 가능해야 한다.
- 각 milestone은 task-owned 파일만 포함한 coherent commit으로 만든다. unrelated user
  change를 stage, revert, clean, reset하지 않는다.

## Risks and Mitigations

| 위험 | 영향 | 완화 |
| --- | --- | --- |
| 상자 엄폐 제거가 난이도를 올림 | 사격선과 이동 경로가 더 열림 | 보상 총량·위치는 유지하고 새 공격 레벨과 함께 Stage 4/5 수동 QA |
| 공격 offer 보장이 무작위성을 줄임 | 빌드 편차 감소 | 공격 ID를 고정하지 않고 compatible shuffled 후보 한 장만 보장 |
| 새 공격 레벨이 성능을 악화 | 탄/효과 수 증가 | 모든 최종 레벨에서 count/tick/radius/lifetime 상한 고정 validator |
| facility 유한화가 존재감을 약화 | 우선 목표 가치 감소 | 기존 HP/간격/역할 유지, offline/charge 정보로 계획성 강화 |
| incremental count가 누락됨 | 생산 정지 또는 상한 초과 | accepted spawn/defeat/retire 단일 transition API와 debug reconciliation |
| mystery chip이 화면을 가림 | 전투 가독성 저하 | 짧은 localized chip, 5Hz, distance/viewport culling, 기존 UI priority 유지 |
| static LOS grid가 잘못된 후보를 누락 | 벽을 통과한 공격/이동 | broad phase는 후보만 줄이고 exact segment truth 유지, brute-force oracle validator |
| overlap generation stamp 오류 | 적 겹침 또는 stale 후보 | wrap/reset test, 기존 cap/fixture 비교, debug full-clear oracle |
| clean 성능 gate가 계속 실패 | 계획 미완료 | top material owner를 다시 계측하고 계획 개정; 적 수/품질로 우회하지 않음 |
| Web에서 native 개선이 작음 | itch 플레이 버벅임 지속 | single-thread Web built smoke 별도 기록; threads 전환은 새 승인 계획으로 분리 |

## Open Questions

없음. 기능·수치·표시·성능 분기와 중단 조건을 현재 코드와 사용자 요구로 결정했다.
계측이 현재 가설과 충돌하면 구현자가 임의로 다른 구조를 고르지 않고 이 계획을 개정한다.

## Decision Notes

- 2026-08-11: 성능 해결은 동일 적 수와 품질을 보존한다. historical capacity record는
  병목 방향 증거로만 사용하고 current release pass로 주장하지 않는다.
- 2026-08-11: 보스 reward transaction을 XP shard transport에서 분리한다. stage finalization의
  boss claim 조건은 유지한다.
- 2026-08-11: 직접 피해 카드 8종에 +1레벨을 추가하되 새 최종 레벨의 actor/query count를
  늘리지 않는다. 명목 상태 44, 실제 합법 선택 상한 33으로 정한다.
- 2026-08-11: 3~5스테이지는 합법 공격 후보가 있으면 최소 1장을 보장한다.
- 2026-08-11: 상자 보상은 14개 direct pickup으로 변환하고 상자의 엄폐까지 제거한다.
  총 recall 4, repair 10, repair 490을 유지한다.
- 2026-08-11: 시설은 유한 충전과 event-owned child count를 사용한다. 장치는 효과를
  바꾸지 않고 공개 정보와 유효 대상 수를 지속 표시한다.
- 2026-08-11: 새 시각 자산은 만들지 않는다. 활성 visual role/spec는 바꾸되 역사적
  workbench와 완료 보고서는 증거로 보존한다.
- 2026-08-11: threads, Servers, GDExtension, ECS는 현재 증거가 요구하지 않으며 Web 배포
  위험이 커서 이 계약에서 제외한다.
