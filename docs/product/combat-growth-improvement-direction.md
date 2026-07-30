---
type: spec
status: draft
owner: BK
created: 2026-07-28
last_reviewed: 2026-07-30
topic: Combat growth, horde, terrain, and boss improvement direction
scope: Proposed evolution of the current five-stage Cardborne vehicle campaign
source: ../../.agents/survivor-shooter-combat-growth-reference-study.md
related:
  - ./vehicle_game_spec.md
  - ../../.agents/survivor-shooter-combat-growth-reference-study.md
  - ../../.agents/vehicle-world-combat-expansion-evidence.md
  - ../design/UI_VISUAL_SYSTEM.md
---

# Combat Growth, Horde, Terrain, and Boss Improvement Direction

## Purpose

이 초안은 Cardborne의 기본 재미를 다음 한 문장으로 강화하는 방향을 정의한다.

> **수동 조준으로 우선 표적을 고르고, 차량 움직임으로 적을 한 덩어리로 유도한 뒤,
> 성장한 무기나 지형을 기폭해 대량 처치하고, 그 성과가 다음 진화와 보스 공략으로 이어진다.**

근거와 레퍼런스별 세부 분석은
[`survivor-shooter-combat-growth-reference-study.md`](../../.agents/survivor-shooter-combat-growth-reference-study.md)에
있다.

## Authority

이 문서는 `draft`이며 현재 구현 계약이 아니다.
[`vehicle_game_spec.md`](./vehicle_game_spec.md)가 계속해서 유일한 active product contract다.

다음 조건을 만족하기 전에는 이 문서의 이름, 수치, 단계 구성을 정본으로 취급하지 않는다.

1. 제품 소유자가 방향을 승인한다.
2. 별도의 ExecPlan이 현재 책임 소유자와 구현 순서를 정한다.
3. vertical slice가 아래 acceptance criteria를 통과한다.
4. 승인된 결정을 `vehicle_game_spec.md`에 통합한다.

## Scope

이 방향은 다음 시스템 사이의 연결을 바꾼다.

- 제한된 카드 제안과 성장 이정표
- authored encounter와 적 formation
- Breach, EMP, mine, bulkhead, Arc Surge를 사용하는 field interaction
- stage boss의 phase, objective, adds, reward
- 대량 처치와 실제 교전 밀도를 검증하는 telemetry

기존 시스템을 전면 교체하거나 콘텐츠 수를 크게 늘리는 제안이 아니다.

## Non-Goals

- 자동 조준 중심 게임으로 전환하지 않는다.
- 주무기·보조 무기를 6개 이상 동시에 쌓는 구조를 만들지 않는다.
- 별도 장착 무기 sprite를 모든 업그레이드마다 제작하지 않는다. 기체에 붙은 무기는 차체 silhouette,
  muzzle, projectile, trail, impact, field effect로 변화를 전달할 수 있다.
- 수백 개 카드, 다수 캐릭터, 별도 shop economy, 새 meta currency를 추가하지 않는다.
- 세 필드를 procedural destruction 또는 mining map으로 바꾸지 않는다.
- 재미 개선의 첫 수단으로 active enemy cap을 올리지 않는다.
- 보스를 HP·속도·탄막 수치만 올려 차별화하지 않는다.
- 현재의 manual aim, held primary fire, one-second Breach, dash, passive seeker, EMP,
  stage boss를 제거하지 않는다.
- repository guidance가 보존하도록 지정한 optional field boss 의도는 유지한다. 다만 현재 live runtime에는
  선택형 field boss encounter가 확인되지 않으므로, 이 초안은 그것을 이미 구현된 기능으로 간주하지 않는다.

## Design Diagnosis

현재 게임에는 카드, 많은 적, 지형 피해, 보스 phase가 이미 있다. 부족한 것은 개별 요소가 아니라
요소 사이의 인과 관계다.

| 현재 사건 | 현재 다음 사건 | 약한 연결 |
| --- | --- | --- |
| 카드 3장 중 하나를 선택 | 다음 카드까지 수치가 누적됨 | 특정 시점의 질적 변신이 보장되지 않음 |
| encounter beat에 따라 최대 1→62→78→88→92명의 일반 적이 활성화 | 8개 squad가 넓은 필드의 여러 anchor에서 접근 | 한 공격으로 지울 수 있는 engaged cluster가 작음 |
| Arc, bulkhead, mine을 발견 | 우연한 피해 또는 이동 편의 | 몰이·기폭·XP 수확의 닫힌 루프가 없음 |
| boss HP가 65%/30%를 통과 | 패턴 순서와 cadence가 강화됨 | 플레이어의 목표와 arena state가 바뀌지 않음 |
| boss 처치 | 일반 풀과 거의 같은 3-card offer | 보스를 이긴 뒤 빌드가 진화했다는 사건이 약함 |

## Target Experience Contract

### 핵심 전투 루프

1. **유도(Gather)**

   적이 넓게 흩어져 따라오는 것이 아니라, authored front와 플레이어의 이동 선택 때문에
   읽을 수 있는 방향에서 한 덩어리로 접근한다.

2. **압축(Compress)**

   dash, 장애물, 좁은 통로, 적 역할, field interaction 중 하나로 적의 경로 또는 밀도가 바뀐다.

3. **기폭(Trigger)**

   1초 Breach, EMP, mine chain, 진화된 주무기 또는 field trigger 중 플레이어가 선택한 능동 행동이
   처치를 시작한다.

4. **대량 처치(Delete)**

   한 번의 준비가 눈에 보이는 적 집단을 짧은 시간 안에 무너뜨린다. 이는 단일 대상 DPS 증가가
   아니라 공격 geometry, chain, propagation, persistent lane 중 하나로 일어난다.

5. **수확(Harvest)**

   환경 처치를 포함한 모든 유효 처치가 XP, kill-chain 피드백, 다음 선택 진행으로 명확히 귀속된다.

6. **진화(Evolve)**

   준비한 계보와 boss milestone이 결합해 기존 행동 규칙을 바꾸는 선택을 연다.

7. **보스 시험(Boss Test)**

   보스는 방금 성장한 빌드가 priority target, crowd clear, movement, Breach 중 무엇을 잘하는지
   고유 objective와 controlled swarm으로 시험한다.

### 성장 감정 곡선

각 스테이지는 같은 감정 순서를 반복하되 요구 조합을 강화한다.

| 구간 | 플레이어가 느껴야 할 변화 |
| --- | --- |
| 방향 설정 | “이번 런에서 무엇을 키울지 알겠다.” |
| 첫 압박 | “아직 이 적 덩어리를 빠르게 처리하지 못한다.” |
| specialization | “내 공격의 방향·대상·공간 역할이 분명해졌다.” |
| power test | “전에는 피하던 덩어리를 이제 쓸어버린다.” |
| boss | “내 빌드의 강점만으로는 부족하고 이 보스의 규칙을 읽어야 한다.” |
| evolution reward | “같은 무기가 아니라 다음 단계의 규칙으로 바뀌었다.” |

## Requirements

## R1. 정체성과 제약을 보존한다

### R1.1 능동 입력

- 수동 조준과 held primary fire가 최우선 표적을 결정해야 한다.
- 1초 Breach는 구조물 파괴, boss interrupt, 군집 기폭 중 적어도 두 역할을 계속 가져야 한다.
- dash와 EMP는 단순 cooldown damage가 아니라 위치·밀도·위험 창을 조작해야 한다.
- Seeker와 선택형 보조 무기는 자동 군집 처리와 combo setup을 담당하되 주무기 조준을 대체하지 않는다.

### R1.2 제한된 런 빌드

- 서로 다른 optional secondary 최대 2개와 기본 Seeker 계약을 유지한다.
- 카드 제안은 run seed, stage, source, serial에 대해 결정적이어야 한다.
- 한 offer에 중복 카드를 내지 않는다.
- 스테이지 1 첫 offer의 primary / element / passive-or-mobility 성립 보장을 유지한다.
- 현재의 early mobility safety guarantee는 제거하지 않는다.

### R1.3 가독성과 성능

- 새로운 damage geometry는 `UI_VISUAL_SYSTEM.md`의 일반 SF 기반 flat-color,
  역할 우선 component 체계를 따른다.
- 플레이어, ordinary enemy, priority enemy, boss telegraph의 시각 우선순위를 뒤집지 않는다.
- reduced motion, flash, camera-shake 설정을 존중한다.
- 같은 global actor budget 안에서 먼저 설계한다.

## R2. 카드를 세 계층으로 재구성한다

현재 46개 카드를 삭제하거나 전부 새로 만들지 않는다. 각 카드를 다음 역할 중 하나로 분류하고,
offer source가 그 역할을 반영하게 한다.

| 계층 | 목적 | 주요 출처 | 허용되는 효과 |
| --- | --- | --- | --- |
| Foundation | 런 성립과 기초 수치 확보 | early level-up | damage, cadence, survivability, 이동, 첫 secondary/element unlock |
| Specialization | 한 계보의 공격 geometry와 상호작용을 선명하게 함 | regular level-up, 향후 optional field boss | pierce, spread, ricochet, mark, mine chain, dash/EMP behavior |
| Evolution | 두 개 이상의 준비 조건을 새 전투 규칙으로 결합 | Stage 1~4 stage boss | target conversion, large propagation, persistent kill lane, subsystem coupling |

### R2.1 Evolution은 별도 보상 계층이다

- Stage 1~4 stage boss의 일반 3-card offer를 **Evolution offer**로 교체한다.
- Evolution 후보는 현재 런에서 준비 조건을 충족한 계보만 사용한다.
- 후보가 세 개 미만이면 빌드를 무시한 임의 카드가 아니라, 모든 빌드에서 쓸 수 있는
  universal transformation 후보로 채운다.
- 후보 eligibility와 아직 부족한 조건은 카드 UI에서 한국어·영어로 설명한다.
- 같은 evolution은 한 런에서 다시 제안하지 않는다.
- Stage 5 처치 뒤에는 사용할 전투 구간이 없으므로 in-run combat evolution을 강제하지 않는다.
  Stage 5 보상은 run completion과 결과 화면의 별도 제품 결정으로 남긴다.

### R2.2 Evolution의 품질 기준

Evolution은 다음 중 최소 하나를 바꾸고, 단순 백분율 증가만으로 구성할 수 없다.

- 한 발이 영향을 주는 대상 수 또는 방향
- priority target 피해가 주변 swarm 처리로 전환되는 방법
- Breach, EMP, dash, mine, secondary 사이의 trigger 관계
- 차량 전면·측면·후방 또는 이동 궤적의 공격 역할
- 처치가 다음 처치를 만드는 propagation 규칙
- 짧은 준비 이후 생성되는 persistent kill corridor

피해량, cadence, radius 수치는 진화의 작동을 지지할 수 있지만 진화의 본체가 될 수 없다.

### R2.3 Vertical-slice evolution archetype

다음은 구현 이름이 아니라 검증할 **역할 원형**이다.

| 원형 | 준비 계보 예 | 규칙 변화 | 시험할 formation |
| --- | --- | --- | --- |
| Line breaker | primary + Breach + pierce/structure | 완전 준비된 Breach가 직선상 군집을 관통하고 첫 구조물·mine·marked target에서 방향성 rupture를 일으킴 | shielded column, 좁은 funnel |
| Priority converter | Seeker/Ion + mark/chain | 수동 주무기로 지정한 priority target에 자동 보조가 집중되고, 처치 또는 stagger가 주변 저체력 군집으로 전파됨 | sustain nest, artillery screen |
| Wake controller | dash/mobility + Mine/Orbit | dash 또는 급회전 궤적이 짧은 kill corridor를 만들고 Breach/EMP로 한 번에 기폭 가능 | pursuing swarm, controller pack |

별도 장착 무기 asset은 필요 조건이 아니다. 차체에 새 총을 덧붙이기보다 projectile silhouette,
trail, impact, field decal, 적의 반응으로 규칙 변화를 전달한다.

### R2.4 성장 배분

- 정규 level-up 총량 21회를 우선 유지한다.
- 첫 검증 목표 배분은 현재의 `7 / 4 / 3 / 3 / 4` 대신 `5 / 4 / 4 / 4 / 4`다.
- 이는 최종 수치가 아니라 simulation target이다. 목적은 Stage 1의 잦은 작은 선택을 줄이고,
  Stage 3~4에도 꾸준한 성장 사건을 보장하는 것이다.
- Stage 1 boss evolution을 포함하면 첫 스테이지 종료 시 최소 한 번의 질적 변화가 반드시 일어난다.
- exact XP curve는 각 stage의 실제 duration과 no-dead-time requirement를 측정한 뒤 결정한다.

## R3. 적 수가 아니라 engaged formation을 authored한다

### R3.1 기존 cap을 유지한다

- 각 stage 안에서 반복되는 Hard beat cap `1 / 62 / 78 / 88 / 92`와 현재 difficulty scaling은
  첫 vertical slice에서 올리지 않는다. 이 값은 Stage 1~5별 cap이 아니라 beat 0~4별 cap이다.
- 전체 population과 quota도 계측 전에는 우선 유지한다.
- 개선 여부는 active count가 아니라 플레이어 주변의 engaged density와 kill burst로 판정한다.

### R3.2 Packet을 2~3개의 pressure front로 묶는다

- 하나의 authored power-test packet이 8개의 독립 방향에서 흩어져 도착하지 않게 한다.
- squad 단위 spawn safety와 offscreen telegraph는 유지하되, 8개 squad를 2~3개의
  shared arrival front로 군집화한다.
- 한 front는 같은 해결법을 공유하는 2~4개 squad로 구성한다.
- 원거리·denial 역할을 모든 방향에 균일하게 뿌리지 않고, front 안의 읽히는 후열로 둔다.
- 플레이어 뒤에서 경고 없이 완성된 formation을 spawn하지 않는다.

### R3.3 Formation 문법

새 적 종류를 먼저 만들지 않고 현재 역할을 다음 formation으로 조합한다.

| Formation | 구성 원리 | 플레이어가 읽을 문제 | 대량 처치 affordance |
| --- | --- | --- | --- |
| Swarm screen | scrap/needle/spark 등 저체력 body 70~80% + priority 1 | 많은 몸체 뒤의 위험 표적 | line, splash, chain이 한 번에 성과를 냄 |
| Shepherd pack | controller/rammer 1~2 + pursuing swarm | 이동 경로가 밀리고 좁아짐 | controller를 역이용해 적을 corridor로 압축 |
| Shielded column | shield escort/bulkhead guard 전열 + support 후열 | 전열을 우회하거나 Breach해야 함 | Breach가 전열과 뒤의 swarm을 함께 여는 구조 |
| Fuse pack | spark/mobile mine/stationary mine + swarm | 언제 어디서 chain을 시작할지 선택 | player shot·Breach로 연쇄 폭발 |
| Sustain nest | repair/carrier/generator 1 + dense fodder | 지원을 먼저 끊지 않으면 전선이 유지됨 | priority 처치가 주변 군집 붕괴 또는 chain의 시작점 |
| Crossfire convoy | shooter/artillery/beam 소수 + chaser screen | 이동과 조준을 동시에 요구 | EMP로 후열 창을 만들고 전면 군집을 삭제 |

각 formation에는 다음이 정확히 보여야 한다.

- 가장 위험한 priority target 1개
- 군집 처치에 사용할 수 있는 geometry 또는 environmental affordance 1개
- 실패했을 때 받는 공정하고 사전에 읽히는 압력 1개

### R3.4 Stage rhythm

각 stage는 최소 다음 네 beat를 가진다.

1. **Teach:** 새 formation 또는 field verb를 낮은 밀도로 보여 준다.
2. **Combine:** 이전 formation에 priority/support 역할 하나를 결합한다.
3. **Power Test:** 직전에 얻은 specialization/evolution으로 짧게 쓸어버릴 수 있는 dense front를 낸다.
4. **Boss Test:** 같은 전투 문법을 boss 고유 rule과 controlled swarm으로 변형한다.

quota는 진행의 backstop으로 남길 수 있지만 설계 목표가 될 수 없다. telemetry에서 후반부가
“남은 소수 적을 찾아다니는 quota tail”로 나타나면 spawn acceleration 또는 encounter-completion
조건을 조정한다. 단순히 quota를 더 크게 만들어 성장감을 증명하지 않는다.

### R3.5 대량 처치 피드백

- 2초 안에 8명 이상 처치하면 별도 currency가 아닌 **Breakthrough chain** 피드백을 시작한다.
- chain은 저비용 hit-stop, audio layer, 적 collapse, XP stream으로 강해졌음을 전달한다.
- 화면 전체 flash나 장시간 camera shake에 의존하지 않는다.
- chain 동안 생성된 XP는 전투 흐름을 끊지 않도록 가까운 pickup을 빠르게 흡수하거나 명확한
  stream으로 보여 준다.
- environment kill과 boss-add kill도 정상적으로 처치 출처와 XP에 귀속한다.
- chain 자체가 추가 damage multiplier를 주어 무한 snowball을 만들지는 않는다.

## R4. Field interaction을 enemy-processing loop로 만든다

### R4.1 공통 계약

각 field는 하나의 강한 signature interaction을 가진다. 그 interaction은 다음 다섯 단계를 모두
지원해야 한다.

1. 작동 범위와 방향을 전투 전에 읽을 수 있다.
2. 플레이어가 적을 그 범위로 유도하거나 장애물을 파괴해 경로를 연다.
3. Breach 또는 EMP로 작동 시점을 의도적으로 선택할 수 있다.
4. ordinary enemy에게 의미 있는 피해·제어를 주고 boss에는 축소된 상태 효과나 vulnerability를 준다.
5. 처치와 XP가 플레이어의 행동으로 귀속된다.

field interaction은 사용하지 않아도 clear 가능한 선택지여야 한다. 올바르게 사용하면 같은 formation을
더 빠르고 화려하게 처리하는 보상 경로가 된다.

### R4.2 세 field의 차별화 방향

아래 명칭은 설명용이며 확정 asset·오브젝트 이름이 아니다.

| Field | 기존 부품 | signature 방향 | 의도한 전투 동사 |
| --- | --- | --- | --- |
| Drowned Ruins | breakable bulkhead, narrow route, Arc | Breach로 bulkhead를 열 때 한 번의 방향성 flood burst가 통로의 ordinary enemy를 밀어 압축하고 피해를 줌 | 유도 → 벽 개방 → 직선 압축 → 관통/연쇄 |
| Tidal Archive | gate pair, open chambers, Arc | EMP로 current vane을 전환해 표시된 lane의 적 이동을 짧게 한 방향으로 편향함. projectile drift는 만들지 않음 | 방향 선택 → 흐름 정렬 → 측면/후방 공격 |
| Storm Drydock | Arc strip 2개, mine chain | Breach 또는 mine chain으로 relay를 overload해 다음 Arc 창을 앞당기거나 한 strip의 전도 범위를 연장함 | 밀집 대기 → 의도적 기폭 → 전기 연쇄 |

### R4.3 기존 상호작용의 강화

- bulkhead 파괴는 길만 여는 것이 아니라 one-time directional combat event가 되어야 한다.
- stationary/mobile mine chain은 chain 경로와 다음 기폭 가능 지점을 미리 읽게 한다.
- repair와 overdrive는 안전 구역으로 끝나지 않고, 그 주변에 formation을 끌어들일 위험과 보상을 둔다.
- gate는 player-only 이동 장치로 유지하되, 사용 후 적 front의 방향을 재배열하는 authored
  opportunity를 만들 수 있다.
- Arc는 우연히 맞는 주기 피해만이 아니라 player-triggerable timing layer를 가진다.
- 모든 visual geometry는 collision truth와 분리하되 정확히 같은 작동 범위를 전달한다.

## R5. 보스는 고유 전투 규칙을 가져야 한다

### R5.1 공통 보스 품질 계약

다섯 stage boss는 공통 telegraph primitive와 damage pipeline을 재사용할 수 있다. 그러나 각 보스는
반드시 다음 다섯 요소를 가진다.

1. 다른 보스와 겹치지 않는 **arena rule**
2. HP threshold에서 실제로 바뀌는 **semantic state**
3. 체력 바 외에 우선순위를 판단하게 하는 **objective target 또는 vulnerability condition**
4. 플레이어의 crowd-clear가 쓸모 있는 **finite controlled swarm**
5. 일반 level-up과 다른 **reward consequence**

phase 전환은 다음 중 최소 두 가지를 바꿔야 한다.

- 공격 가능한 target
- boss의 이동 또는 arena geometry
- ordinary add의 역할과 진입 방향
- Breach/EMP/environment의 반응
- damage window
- 플레이어가 다음 10초 동안 해결해야 할 목표 문장

패턴 순서, read gap, volley count, autonomous interval만 바뀌는 것은 semantic phase로 세지 않는다.

### R5.2 Boss fight와 horde의 결합

- boss 시작 시 모든 ordinary pressure를 영구히 0으로 만들지 않는다.
- phase 2와 3에는 12~18명의 저체력 boss-wave packet을 유한 횟수 투입한다.
- boss-wave ordinary는 동시에 최대 20명, support/priority 역할은 동시에 최대 1명으로 제한한다.
- 기존 global actor cap 안에서 boss module과 ordinary를 함께 예산화한다.
- add는 boss의 고유 objective를 가리거나 projectile flood를 만들지 않는다.
- finite packet이므로 정상 XP를 줄 수 있으며 반복 farming source가 되지 않는다.
- crowd-clear build는 add를 빠르게 지워 boss damage window를 만들고, single-target build는
  Breach·field interaction으로 같은 문제를 해결할 수 있어야 한다.

### R5.3 Stage boss별 고유 규칙 방향

아래는 현재 boss 이름을 유지한 설계 방향이며, 정확한 패턴명과 수치는 후속 ExecPlan에서 정한다.
보스가 어느 field에서 등장해도 작동하도록 필요한 module은 보스가 휴대·배치한다.

| Boss | Phase 1: 규칙 학습 | Phase 2: 상태 전환 | Phase 3: 결합 시험 | 고유 counterplay |
| --- | --- | --- | --- | --- |
| Foundry Colossus | armored press front와 interruptible charge를 읽음 | charge 또는 Breach로 두 forge plate를 깨야 core damage가 열림 | swarm screen을 압축하는 press lane과 exposed core가 교대 | boss charge를 plate/bulkhead에 유도하거나 Breach로 직접 개방 |
| Archive Leviathan | body wake가 지나간 lane을 잠시 위험 구역으로 남김 | 두 segment lock 중 하나를 수동 조준해 끊으면 이동 방향과 취약 측면이 바뀜 | controlled swarm을 wake lane으로 몰아 정리하면서 노출된 측면 공격 | gate/EMP로 lane을 건너고 marked segment에 seeker를 집중 |
| Drydock Titan | 두 portable relay가 shield를 분담 | relay 하나를 overload하면 arena의 Arc polarity와 안전 lane이 바뀜 | boss beam, 한 relay, fuse pack을 같은 chain으로 해결 | Breach·mine chain·EMP 중 하나로 relay window 생성 |
| Switchyard Behemoth | telegraphed track를 따라 돌진하며 switch node를 배치 | switch를 공격해 다음 charge route를 바꾸고 armor car를 분리 | crossfire convoy와 boss route를 동시에 재배치 | 수동 사격으로 switch 선택, dash로 route bait |
| Crown Engine | 이전 네 규칙의 단순 패턴이 아니라 relay lattice와 command core를 소개 | 외곽 core 두 개를 파괴해야 중앙 core가 열리고 horde command가 약해짐 | 이동하는 vulnerability, controlled swarm, field trigger를 하나의 짧은 cycle로 결합 | Breach로 lattice 연결을 끊고 specialization에 맞는 core 순서 선택 |

### R5.4 보스 난이도와 시간

- HP는 고유 cycle을 최소 한 번 보여 줄 만큼 충분해야 하지만, 상태 규칙을 이해한 뒤의 반복 대기 시간을
  만드는 수단이 되어서는 안 된다.
- 각 phase는 baseline eligible build가 고유 규칙을 한 번 성공한 뒤 합리적인 damage window 안에
  넘어갈 수 있어야 한다.
- HP 65%/30% threshold는 유지할 수 있지만, threshold 도달 즉시 phase state와 arena가 실제로
  바뀌어야 한다.
- boss는 읽기 전의 즉사, 경고 없는 offscreen hit, boss body 아래 가려진 objective를 사용하지 않는다.
- difficulty는 고유 rule을 제거하거나 숨기는 대신 timing, formation composition, recovery window로
  조절한다.

## R6. 보상은 성장 곡선을 닫아야 한다

### R6.1 보상 계층

| 사건 | 보상 역할 |
| --- | --- |
| ordinary kill | XP와 현재 build의 steady growth |
| Breakthrough chain | 성장 체감, XP 회수 편의, 시청각 강화 |
| authored elite/priority clear | specialization 후보 또는 현재 계보 진행을 앞당기는 명확한 XP 사건 |
| 향후 optional field boss | 위험을 선택한 대가로 specialization 또는 evolution eligibility 보완. 현재 live encounter에는 없으므로 별도 구현 범위 |
| Stage 1~4 boss | prepared build를 바꾸는 Evolution offer |
| Stage 5 boss | run completion과 결과. 별도 meta reward는 제품 승인 전까지 범위 밖 |

### R6.2 환경 처치 귀속

- Arc, flood, mine chain, boss-routed hazard가 적을 죽여도 플레이어의 유효 trigger가 있었다면
  정상 XP와 kill chain에 포함한다.
- 단순 주기 환경 피해에 우연히 죽은 적을 과도하게 보상하지 않도록 최근 player interaction과
  authored trigger를 구분한다.
- reward attribution 규칙은 UI 코드가 아니라 combat state 소유자가 판정한다.

## R7. 계측으로 재미의 원인을 검증한다

### R7.1 Encounter telemetry

각 deterministic validation seed에서 다음을 기록한다.

- active enemies
- player로부터 600px와 900px 안의 enemy 수
- line-of-sight 또는 navigation 상 실제 접근 가능한 engaged enemy 수
- formation id별 spawned / engaged / defeated / escaped count
- rolling 5-second kills per second
- 1초와 2초 구간의 최대 kill burst
- 8-kill Breakthrough까지 걸린 시간
- primary, secondary, Breach, EMP, mine, environment별 damage와 kill share
- quota 달성 전후의 queue idle time과 stage tail duration

### R7.2 Growth telemetry

- offer source와 세 후보
- 각 후보가 Foundation / Specialization / Evolution 중 어느 계층인지
- eligibility를 만든 prerequisite
- 선택 시점과 stage
- 첫 qualitative behavior와 첫 Evolution 도달 시점
- evolution 전후 같은 formation의 time-to-clear

### R7.3 Boss telemetry

- phase별 duration
- objective가 잠긴 시간과 실제 damage window
- signature startup 횟수, interrupt 성공률
- boss-wave add의 peak engaged count와 clear time
- boss, add, environment에 받은 damage source
- 각 고유 rule을 플레이어가 성공한 횟수
- boss 처치 후 evolution offer eligibility와 선택

telemetry는 debug/validation 경로에 남기며 일반 UI에 raw 수치를 노출하지 않는다.

## Stage Progression Direction

| Stage | 성장 역할 | formation 역할 | boss 역할 |
| --- | --- | --- | --- |
| 1 | foundation을 빠르게 성립하고 첫 evolution 보장 | swarm screen, shielded column으로 line clear 학습 | Breach와 구조물·취약 상태를 가르치는 첫 semantic boss |
| 2 | primary와 한 secondary/element의 결합 | shepherd pack, sustain nest로 priority-to-crowd 시험 | 이동 lane과 측면 노출을 바꾸는 boss |
| 3 | 환경과 build의 상호작용 확립 | fuse pack, crossfire convoy | relay와 Arc state를 직접 조작하는 boss |
| 4 | 두 specialization을 하나의 capstone으로 결합 | 가장 높은 engaged density와 혼합 formation | player-selected route로 arena를 재배치하는 boss |
| 5 | 완성 build가 세 해결법 중 하나를 선택 | 이전 formation의 짧고 읽히는 remix | horde, objective, vulnerability를 결합하는 최종 시험 |

이 표는 각 stage에 새 적과 새 시스템을 하나씩 의무적으로 추가하라는 의미가 아니다. 현재 역할과
부품을 어떤 학습 순서로 재배치할지 정의한다.

## Vertical Slice

첫 구현은 전체 5개 stage를 동시에 바꾸지 않는다. 다음 하나의 end-to-end slice로 루프를 검증한다.

### 포함

- Stage 1 regular level-up 5회 목표와 boss Evolution offer
- 세 evolution 원형의 최소 작동 후보 각 1개
- 현재 적 역할로 만든 Swarm screen과 Shielded column
- 8개 squad를 2~3개 pressure front로 묶은 Stage 1 power-test packet
- 한 field signature interaction의 player-triggered enemy-processing loop
- Foundry Colossus의 세 semantic phase와 finite boss-wave adds
- engaged-density, kill-burst, evolution, boss-phase telemetry
- 한국어·영어 카드 조건과 boss objective 문구

### 제외

- 나머지 네 보스의 완전 구현
- 새 적 archetype
- active cap 상향
- 별도 mounted-weapon art set
- meta progression
- 최종 전체 카드 수치 밸런스

### 구현 전 요구

이 slice는 카드 데이터, offer policy, encounter coordination, world interaction, boss state, UI,
validation을 가로지르므로 승인 뒤 별도 ExecPlan이 필요하다. 각 책임 소유자를 유지하고
카드 behavior를 UI에 넣거나 visual geometry를 collision truth로 사용하지 않는다.

## Acceptance Criteria

### A. 성장

- [ ] 같은 seed와 같은 선택 이력은 같은 regular offer와 Evolution offer를 만든다.
- [ ] Stage 1 첫 offer는 기존 성립 보장을 유지하고, Stage 1 boss 종료 시 질적 Evolution을
  정확히 한 번 선택할 수 있다.
- [ ] Evolution 후보는 실제 prerequisite에서 유도되며 세 후보가 부족할 때만 universal fallback을 쓴다.
- [ ] 각 Evolution은 isolated combat test에서 damage multiplier를 제거해도 규칙 변화가 관찰된다.
- [ ] boss reward에 일반 Foundation 카드가 섞이지 않는다.

### B. 몰이와 대량 처치

- [ ] authored power-test beat에서 최소 24명의 swarm body가 같은 135° arrival sector에 속한다.
- [ ] power-test 구간의 `engaged within 900px / active` P90이 0.55 이상이다.
- [ ] 같은 active cap에서 진화 build는 지정 formation의 ordinary enemy를 2초 안에 최소 12명
  처치하는 순간을 만든다.
- [ ] baseline Foundation-only build는 같은 순간에 8명을 넘기지 않아, 성장 전후 차이가 측정된다.
- [ ] line breaker, priority converter, wake/environment 중 적어도 세 가지 서로 다른 해결 경로가
  동일 formation의 clear에 성공한다.
- [ ] ranged commitment와 denial commitment의 기존 공정성 상한을 위반하지 않는다.

위 수치는 재미의 최종 공식이 아니라 vertical slice의 명확한 성공·실패 경계다. 시각적으로만 많은
적을 보여 주고 실제 처치 가속이 없는 결과를 통과시키지 않기 위해 사용한다.

### C. 환경

- [ ] player가 trigger 시점과 유효 범위를 공격 전에 읽을 수 있다.
- [ ] signature interaction 한 번으로 지정 dense formation에서 최소 8명의 ordinary enemy에게
  피해를 주고, 준비가 잘된 test에서는 최소 6명 처치에 기여한다.
- [ ] environment kill이 XP, kill chain, damage attribution에 정확히 포함된다.
- [ ] interaction을 사용하지 않아도 stage와 boss를 clear할 수 있다.
- [ ] projectile drift나 collision truth와 다른 장식 범위를 만들지 않는다.

### D. 보스

- [ ] 각 phase 시작 후 3초 안에 공격 target, arena state, add role, counterplay 중 최소 두 가지가
  이전 phase와 달라졌음을 읽을 수 있다.
- [ ] Foundry Colossus의 각 phase를 설명하는 목표 문장이 서로 다르다.
- [ ] boss fight에 finite swarm packet이 존재하고 crowd-clear build의 장점이 boss damage window로 이어진다.
- [ ] Breach 또는 field interaction을 성공하면 boss state가 실제로 바뀌며 단순 bonus damage로 끝나지 않는다.
- [ ] boss HP를 2배로 늘리지 않고도 최소 한 번의 고유 cycle을 보여 주며, 해결 이후 무의미한 반복을 만들지 않는다.
- [ ] 처치 후 일반 카드가 아닌 eligible Evolution offer가 열린다.

### E. 품질

- [ ] 현재 focused validators와 Web export가 통과한다.
- [ ] 현재 performance benchmark의 gate를 회귀하지 않고 stale actor·projectile이 남지 않는다.
- [ ] 지원 해상도에서 카드 조건, boss objective, kill-chain UI가 clip 또는 overflow되지 않는다.
- [ ] 한국어와 영어 문자열이 모든 신규 사용자 표면에서 완전하다.
- [ ] reduced motion과 flash 설정에서 동일한 gameplay information을 읽을 수 있다.
- [ ] 기존 주무기, Breach, dash, EMP, seeker 입력 계약을 회귀하지 않는다.

## Decision Log

| 질문 | 선택 | 배제한 대안 |
| --- | --- | --- |
| 성장감을 어떻게 키우는가? | boss milestone의 prepared Evolution | 카드 수와 damage %만 추가 |
| 몰이 장면을 어떻게 만드는가? | 같은 cap에서 squad를 2~3 front로 군집화 | active cap부터 상향 |
| 지형을 어떻게 전투에 연결하는가? | Breach/EMP로 의도적 trigger가 가능한 field signature | 주기적으로 발동하는 무료 피해 장판만 추가 |
| 보스를 어떻게 차별화하는가? | arena rule + semantic phase + objective + finite horde | 더 빠른 generic pattern과 더 높은 HP |
| 차량 무기 외형은 어떻게 다루는가? | 차체 silhouette와 projectile/effect 중심 | 모든 upgrade에 별도 mounted-weapon asset 제작 |
| 콘텐츠 범위는? | 기존 카드·적 역할·필드 부품 재조합 우선 | 수십 무기·캐릭터·meta tree 확장 |

## Open Tuning Decisions

다음 항목은 방향 미정이 아니라 telemetry가 필요한 tuning 변수다.

- `5 / 4 / 4 / 4 / 4` 정규 level-up 배분을 만드는 exact XP curve
- Evolution별 damage, radius, propagation count, cooldown
- pressure front의 정확한 squad 수와 spawn cadence
- field signature의 damage, push, duration, reuse 횟수
- boss-wave packet의 stage별 횟수와 composition
- boss phase별 HP share와 recovery duration
- quota 유지·감소 또는 encounter-completion backstop 전환 여부

이 값은 vertical slice 결과 없이 정본 사양에 넣지 않는다.

## Promotion Gate

이 초안의 방향을 active product contract로 승격하려면 다음 순서를 따른다.

1. 제품 소유자가 Target Experience Contract와 R2~R5를 승인한다.
2. 별도 ExecPlan에서 Stage 1 vertical slice의 코드 소유자와 validation을 정한다.
3. deterministic tests와 production-style Web build로 Acceptance Criteria를 검증한다.
4. 플레이테스트에서 성장 전후 kill burst와 boss phase 이해도를 확인한다.
5. 승인된 요구만 `vehicle_game_spec.md`에 통합하고 이 문서의 lifecycle status를 갱신한다.
