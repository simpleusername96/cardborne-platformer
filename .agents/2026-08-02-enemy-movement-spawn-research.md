---
type: evidence
status: active
owner: BK
created: 2026-08-02
last_reviewed: 2026-08-02
topic: 일반 적 이동·군집·spawn 분산 설계 근거
scope: Asset/UI 교체 전에 적용할 ordinary-enemy movement와 encounter arrival
related:
  - ../docs/reports/2026-08-02-pre-asset-code-stabilization.md
  - ../docs/product/vehicle_game_spec.md
---

# 일반 적 이동·군집·spawn 분산 조사

## Purpose

현재 게임에서 함께 나타나는 세 문제, 즉 일반 적의 느린 접근, 같은 지점에서의
대량 출현, player 주변 재군집을 서로 다른 제어 문제로 분리하고 구현 계획의
근거를 남긴다. 이 문서는 조사 증거이며 제품 명세나 실행 계획을 대신하지
않는다.

## Sources

### 현재 프로젝트

- `scripts/vehicle/stages/vehicle_combat_stages.gd`
  - main surge 하나는 12 squads, squad당 4~8기, 총 약 86~96기다.
  - surge trigger는 2.4초 간격이고 main arrival은 `multi_sector`다.
- `scripts/encounters/vehicle_spawn_allocator.gd`
  - 12 squads를 4 packs로 묶고 pack당 3 squads가 정확히 한 anchor를 공유한다.
  - 네 quadrant는 사용하지만 한 pack 안의 실제 출현 원점은 하나다.
- `scripts/encounters/vehicle_encounter_runtime.gd`
  - 같은 squad의 unit은 반경 38px 안에서 출현하고 0.10초 간격으로 예약된다.
  - `group_index=pack_index`라 네 quadrant가 동시에 퍼지는 것이 아니라 pack
    순서로 도착한다.
- `scripts/encounters/vehicle_encounter_director.gd`
  - ordinary 이동 multiplier는 1.20이고 Hard active cap은
    `1/124/172/224/276`이다.
  - 명시적 collective tactic 상태가 아닌 일반 이동에도 30% squad cohesion이
    계속 적용된다.
- `scripts/vehicle/vehicle_run.gd`
  - 모든 이동 role은 player 또는 role별 거리 band를 향하고, 일반 steering에
    local separation이 없다.
- `scripts/combat/vehicle_spatial_grid.gd`
  - 이미 반경 query와 stable actor slot을 제공하므로 별도 navigation
    dependency 없이 bounded neighbor query를 구현할 수 있다.
- 2026-08-02 baseline validators:
  - `VEHICLE_SPAWN_ALLOCATION_VALIDATION_OK`
  - `VEHICLE_MULTI_SECTOR_SPAWNS_VALIDATION_OK`
  - `VEHICLE_COLLECTIVE_TACTICS_VALIDATION_OK`
  - 이 통과는 현재의 4 shared anchors와 permanent cohesion을 올바른 것으로
    검사한다는 뜻이지, 사용자에게 적절한 분산을 보장한다는 뜻은 아니다.

### 게임 제작 사례와 개발자 기록

- Marie Mejerwall, GDC 2025,
  [Growing an AI Director into a Full Adventure Director](https://media.gdcvault.com/gdc2025/Slides/Mejerwall_Marie_Growing_an_AI.pdf)
  - NPC의 총 전투 가치를 `Combat Budget`으로 제한하고 pack을 여러 방향에서
    보내되, 한 pack이 남은 budget의 절반 이상을 독점하지 않게 했다.
  - spawn quantity, 종류, 빈도와 실제 체감 intensity를 분리했다.
  - 서로 다른 방향의 pack은 공간 인지를 만들지만, 사방 ambush만 반복하면
    플레이가 정체된다는 playtest 결과도 기록했다.
- Craig Reynolds, GDC 1999,
  [Steering Behaviors for Autonomous Characters](https://www.red3d.com/cwr/steer/gdc99/)
  - separation, cohesion, alignment는 각각 다른 local-neighborhood behavior다.
  - crowding 방지는 separation이 담당하며 cohesion과 같은 값으로 취급하면
    안 된다.
  - obstacle avoidance 같은 상위 행동을 우선하고 나머지를 제한적으로 blend할
    수 있다.
- Insomniac Games, GDC 2015,
  [AI in the Awesomepocalypse](https://gdcvault.com/play/1021780/AI-in-the-Awesomepocalypse-Creating)
  - 빠르고 이동성이 큰 player에게 기존의 단순 cover/flank/melee-swarm
    관습이 충분하지 않았다는 postmortem이다. 적 수만 늘리기보다 player 이동
    능력에 맞는 접근 행동을 별도로 검증해야 한다.
- Sony Bend Studio, GDC 2021,
  [Squad Coordination in Days Gone](https://gdcvault.com/play/1027237/AI-Summit-Squad-Coordination-in)
  - squad coordination은 friendly/enemy space 분석과 동적 위치 선정의
    상위 계층으로 다뤄졌다. 모든 개체를 항상 centroid로 끌어당기는 것과는
    다르다.
- Flanne, 20 Minutes Till Dawn developer update,
  [Enemy overhaul](https://steamcommunity.com/app/1966900/allnews/)
  - boss전에는 unique minion만 남기고 ordinary spawn을 멈춰 clutter를
    줄였다. 이는 총 enemy count와 현재 encounter의 읽을 수 있는 압력을
    별도 예산으로 취급한 동종 장르 사례다.

### 비게임 알고리즘과 공개 코드

- Robert Bridson,
  [Fast Poisson Disk Sampling in Arbitrary Dimensions](https://www.cs.ubc.ca/~rbridson/docs/bridson-siggraph07-poissondisk.pdf)
  - uniform random은 cluster를 만들 수 있지만 minimum-distance sampling은
    모든 sample 사이에 하한을 둔다. Cardborne에는 전체 알고리즘을 도입하지
    않고 deterministic candidate rejection 규칙만 적용할 수 있다.
- Godot stable documentation,
  [Using NavigationAgents](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html)
  - RVO avoidance는 pathfinding과 별도이며 neighbor distance, max neighbors,
    time horizon이 비용과 감속을 좌우한다. time horizon이 크면 agent가 과도하게
    느려질 수 있다.
- UNC GAMMA,
  [RVO2 source and algorithm](https://github.com/snape/RVO2)
  - reciprocal collision avoidance는 각 agent가 충돌 회피 책임을 나누는
    정식 해법이고 공개 구현도 있다. 다만 이 프로젝트는 이미 custom movement,
    cover recovery, fixed decision cadence와 spatial grid를 가지므로 이 단계에서
    외부 solver를 추가할 이유는 부족하다.

## Findings

### 1. 현재 `multi_sector`라는 이름과 실제 출현 분산은 다르다

현재 검사는 네 quadrant를 사용하면 분산된 것으로 판정하지만, 각 quadrant에서
3 squads, 최대 24기가 한 anchor와 38px fan을 공유한다. 따라서 sector 통계는
넓어도 실제 local density는 높다. 또한 pack별 시간차 때문에 한 순간의 도착은
사방 분산이 아니라 한 방향의 큰 덩어리에 가깝다.

### 2. 느린 체감은 base speed와 도착 거리의 합성 결과다

Hard Stage 1에서 현재 ordinary multiplier 1.20을 적용하면 `scrap_drone`은
270px/s, `chaser`는 246px/s로 base player 280px/s보다 느리다. spawn ring은
900~2400px라 cover routing까지 겹치면 첫 유효 압력까지 오래 걸린다. 단순히
trigger 빈도를 올리면 접근 지연 동안 reserve만 쌓였다가 뒤늦게 한꺼번에
도착한다.

### 3. spawn을 넓혀도 permanent cohesion이 다시 합친다

ordinary move 상태의 모든 squad는 role velocity 70%와 centroid/slot velocity
30%를 계속 섞는다. local separation이 없으므로 서로 겹치지 않게 밀어내는 힘은
없고, spawn 이후에도 동일 squad가 하나의 군집으로 복구된다. 명시적
collective tactic이 별도로 존재하므로 일반 cohesion은 책임이 중복된다.

### 4. 총 개체 수와 전투 압력은 같은 숫자가 아니다

현재 active cap 276은 성능 workload이자 gameplay pressure로 동시에 쓰인다.
한 surge가 약 90기이므로 late beat는 세 surge 이상을 동시에 활성화할 수 있다.
필요한 것은 authored population과 quota를 삭제하는 것이 아니라 다음 값을
분리하는 것이다.

| 용어 | 이 계획에서의 의미 | 소유자가 제어할 값 |
| --- | --- | --- |
| authored population | stage 전체에서 예약된 ordinary 수 | stage data |
| active population | 동시에 simulation에 들어온 ordinary 수 | encounter director |
| arrival squad | 하나의 cue/anchor를 공유하는 4~8기 | stage data/runtime |
| arrival wave | 같은 시간 창에 각 quadrant에서 하나씩 오는 네 squads | scheduler |
| local pressure | player 600/900px 안의 active ordinary 수 | director/movement |
| collective tactic | 짧은 gather/lock/execute를 가진 의도된 편대 행동 | tactic runtime |
| local separation | 겹침과 과밀만 푸는 근거리 steering | movement owner |

### 5. Cardborne에는 full RVO보다 bounded separation이 맞다

RVO/ORCA는 유효하지만 현재 목표는 물리적으로 완전한 무충돌 crowd가 아니라
읽을 수 있는 간격이다. 기존 spatial grid에서 최대 8개 이웃만 0.10초 decision
cadence로 조회하면 새 dependency, NavigationAgent node, 매-frame 전 agent
solver 없이 필요한 현상을 직접 고칠 수 있다. cover collision recovery와
committed attack path는 기존 우선순위를 유지할 수 있다.

## Recommendations

1. ordinary movement multiplier를 1.20에서 1.40으로 올리고 boss, committed
   charge, projectile 속도와 분리한다.
2. 12 squads/role multiset은 유지하되 `4 packs × shared anchor`를
   `3 arrival waves × 4 quadrant-owned distinct anchors`로 바꾼다.
3. candidate anchor와 squad unit 위치에 deterministic minimum distance를 두고
   fallback relaxation을 telemetry로 노출한다.
4. ordinary move의 permanent squad cohesion을 제거하고, 명시적 collective
   tactic에서만 formation을 사용한다.
5. 기존 spatial grid로 최대 8-neighbor separation을 계산한다. overlap 회피가
   role steering보다 강하고, 평상시 separation은 약하게 blend한다.
6. authored population과 stress fixture는 유지하되 gameplay active cap과
   600/900px local pressure cap을 별도 값으로 낮춘다.
7. validator가 quadrant/sector 개수뿐 아니라 minimum spawn distance, 시간대별
   quadrant 균형, local neighbor count, closing time을 검사하게 바꾼다.

## Limitations

- 외부 게임의 내부 수치나 proprietary spawn 코드는 공개되지 않았으므로
  Cardborne의 정확한 cap과 거리 값은 현재 packet 크기, field 크기, player
  280px/s, 기존 stress fixture를 기준으로 정했다.
- 연구 자료는 설계 원리를 뒷받침하지만 재미를 자동 보장하지 않는다. 계획의
  수치는 deterministic fixture와 production replay를 통과한 뒤 native/Web
  실플레이에서 최종 확인해야 한다.
- 이 문서는 enemy roster, role 비율, boss pattern, map generation, visual
  asset 변경을 권고하지 않는다.
