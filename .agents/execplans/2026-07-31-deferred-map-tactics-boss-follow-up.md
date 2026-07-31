---
type: plan
status: draft
owner: BK
created: 2026-07-31
last_reviewed: 2026-07-31
scope: Deferred algorithmic map generation, coordinated enemy tactics, and boss-pattern candidates that require separate validation and explicit activation
related:
  - ../../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../docs/design/component-sheets/semantic-rework-v2-proposal/README.md
  - ../vehicle-world-combat-expansion-evidence.md
  - ../vehicle-performance-architecture-audit.md
  - ./2026-07-30-semantic-visual-world-boss-performance-rework.md
---

# 맵 생성·적 합동 전략·보스 패턴 후속 검토 초안

> 이 문서는 `draft`이며 구현 권한이 없다. 현재 active plan, product spec
> 또는 이미 구현된 enemy/boss behavior를 수정하지 않는다. 재개하려면
> 사용자의 명시적 지시, 현재 코드 재감사, 제한된 prototype 비교와 승인된
> 새 active ExecPlan이 필요하다.

## Purpose

2026-07-31 범위 축소로 active plan에서 제외한 세 영역을 잃지 않고
보존한다.

1. 알고리즘 floor/wall surface와 기능 지형을 포함한 map generation
2. ordinary enemy의 역할별 거리대, squad slot과 density steering
3. 다섯 boss의 새 ranged, movement, nuisance와 counter pattern

이 문서의 목적은 이전 제안과 그 근거를 보존하고, 나중에 다시 다룰 때
검증되지 않은 아이디어를 곧바로 전체 구현하지 않도록 activation gate를
고정하는 것이다.

## Why / Context

- 사용자는 map generation을 후순위로 미뤘다.
- 사용자는 enemy coordinated tactic과 boss pattern을 현재 active
  수정 범위에서 제외했다.
- 기존 제안은 외부 사례와 현재 code audit에 근거했지만, 실제 gameplay
  prototype이나 AS-IS/TO-BE 플레이 비교를 통과하지 않았다.
- 특히 cell occupancy `12`, steering `35%`, boss별 timing과 safe-space
  수치는 검증된 결론이 아니라 이전 설계 후보였다.
- 현재 shipped tactic과 boss pattern은 관련된 이전 plan에서 이미 구현된
  상태이므로, 이 draft가 그 동작을 자동으로 재개방하지 않는다.

## Scope / Non-scope

### Candidate scope

- current authored geometry를 바탕으로 한 structural floor/wall compiler
- map topology 자체를 절차 생성할지에 대한 별도 owner decision
- ordinary enemy의 role band, deterministic squad slot과 density response
- 다섯 boss의 distinct dodge verb, movement consequence, nuisance,
  recovery와 objective interaction
- 각 후보의 작은 prototype, 비교 기준과 승인 gate

### Explicitly not active

- active plan이 수행하는 raster asset integration, UI, shared attack
  telegraph, boss damage/objective state와 non-behavioral performance
- 현재 map, enemy tactic 또는 boss pattern code 수정
- 이 draft의 숫자와 표를 product spec이나 test contract로 승격
- 사용자 승인 없는 status 변경

## Assumptions

- 이 문서를 재개하는 시점에는 active plan 구현이 끝났거나 사용자가
  우선순위 변경을 명시한다.
- 재개 시점의 code, product spec과 performance payload를 다시 확인한다.
- current behavior를 기준선으로 보존한 별도 prototype 또는 practice
  route를 사용한다.
- prototype 결과가 좋지 않으면 후보를 폐기하거나 다시 설계하며, 기존
  runtime을 그대로 유지한다.

## Sources

### Map

- Godot 4.7
  [TileMap](https://docs.godotengine.org/en/4.7/tutorials/2d/using_tilemaps.html)
  과
  [TileSet terrain](https://docs.godotengine.org/en/4.7/tutorials/2d/using_tilesets.html)
- David Pittman,
  [Procedural Level Design in Eldritch](https://media.gdcvault.com/gdc2015/presentations/Pittman_David_Procedural%20Level%20Design.pdf)
- `15-world-layering-asis-tobe.png`

### Boss

- Itay Keren,
  [Boss Up: Boss Battle Design](https://gdcvault.com/play/1024921/Boss-Up-Boss-Battle-Design)
- Double Fine,
  [Crafting Epic Boss Battles in Psychonauts 2](https://www.gdcvault.com/play/1028746/AI-Summit-Crafting-Epic-Boss)
- Bad Robot Games,
  [4:Loop Scanner design](https://blog.playstation.com/2026/04/28/4loop-designing-the-ominous-cube-shaped-scanner-boss/)
- Game Bakers,
  [Furi and creating memorable moments](https://www.thegamebakers.com/furi-and-creating-memorable-moments/)

### Enemy coordination

- current `VehicleEnemyStore`, `VehicleEnemyUpdateSchedule`,
  `VehiclePursuitField`, encounter director와 spatial grid
- `.agents/vehicle-performance-architecture-audit.md`
- `.agents/vehicle-world-combat-expansion-evidence.md`

이 source는 후보 방향을 설명하지만 재미, 난이도와 movement feel을
증명하지 않는다.

## Current State

### Map

- current map은 authored layout과 geometry snapshot을 사용한다.
- floor surface compiler의 `variant`, `has_inset`과 hash-ranked
  `service_rail`은 결정적이지만 gameplay function은 아니다.
- floor, wall, collision, cover와 navigation이 같은 의미 계층으로
  명확하게 표현되지 않는 문제가 관찰됐다.
- active plan은 floor/wall compiler와 world-layering asset을 수정하지
  않는다.

### Coordinated enemy tactics

- pool, critical/near/far update cadence, shared pursuit field와 formation
  offset이 이미 있다.
- squad cohesion과 player pursuit가 고밀도에서 같은 지역으로 수렴하는
  현상이 관찰됐다.
- 새 role band, angular slot과 density steering은 아직 구현·검증되지
  않았다.
- incremental grid, query cache와 allocation 교정은 tactic 변경 없이
  active plan에서 별도로 처리한다.

### Boss patterns

- 다섯 boss와 stage별 pattern sequence가 이미 있다.
- pattern 선택은 deterministic sequence이며 즉시 반복을 피한다.
- 실행은 `lanes`, `fan`, `cross`, `charge`, `beam`, `area`, `summon`
  같은 공용 kind에 크게 의존한다.
- boss damage/objective와 attack telegraph는 active plan에서 교정하지만
  pattern table, movement와 timing은 유지한다.
- 아래 새 boss table은 gameplay prototype을 거치지 않은 후보다.

## Candidate Design — Not Approved

### A. Algorithmic map

#### 먼저 결정해야 하는 범위

“맵 생성”은 서로 다른 두 작업을 뜻할 수 있다.

1. 현재 authored geometry는 유지하고 floor/wall surface만 neighbor-aware
   compiler로 생성
2. walkable topology, room, corridor와 encounter route 자체를 절차 생성

이 둘은 save/replay, collision, navigation, encounter와 QA 비용이 크게
다르므로 재개 시 사용자가 먼저 범위를 선택해야 한다. 이전 제안은 1번만
구체화했으며 2번은 분석하지 않았다.

#### 보존된 structural-surface 후보

- tile cell `192×192`
- joint width `8`
- geometry fingerprint가 같은 cell은 같은 mesh hash 생성
- floor tile 형태는 8-neighbor mask 또는 실제 function footprint만 결정
- wall은 exact blocker geometry에서 shadow, side mass, top cap과 perimeter
  생성
- functional layer는 repair, overdrive, arc surge, transit와 destructible
  bulkhead만 허용
- hash-only inset, crack, service rail, glyph와 route arrow 제거
- 실제 `TileMapLayer` migration 대신 current static mesh owner에서
  terrain neighbor-mask 원리만 적용

#### 후보 검증

- current geometry/collision/navigation/cover fingerprint가 동일
- visible wall과 blocker가 1:1
- invisible blocker와 false wall이 0
- 기능 없는 mark가 0
- 1× capture에서 tile seam이 actor보다 먼저 읽히지 않음

이 값과 방식은 재승인 전까지 구현하지 않는다.

### B. Coordinated enemy tactics

#### 보존할 current structure

- `VehicleEnemyStore`와 projectile store pool
- critical/near/far update cadence
- shared pursuit field
- swept collision
- authored encounter count와 existing capacity

#### 보존된 후보

1. ordinary enemy가 role별 annular band를 가진다.
2. squad member가 deterministic angular slot을 가진다.
3. 모두 player의 같은 지점으로 수렴하지 않는다.
4. candidate cell occupancy가 `12`를 넘으면 committed attacker를 제외한
   movement actor가 가장 덜 찬 인접 cell 방향으로 최대 `35%`
   density-gradient steering을 혼합한다.
5. pairwise separation은 사용하지 않고 cell aggregate를 사용한다.
6. committed startup/active actor는 tactic correction에서 제외해 attack
   endpoint가 흔들리지 않게 한다.

`12`, `35%`, band radius와 slot spacing은 provisional 값이다.

#### 필요한 판단 prototype

동일한 seed, encounter, player route와 적 수로 AS-IS/TO-BE를 비교한다.

- cell occupancy p50/p95/max
- player 주변 동일 반경의 enemy angular coverage
- 겹친 body 수와 target-selection stability
- melee 접근 시간과 ranged firing opportunity
- movement oscillation, slot swapping과 wall trapping
- frame/physics cost
- 사람이 본 pressure, 자연스러움과 공격 원인 가독성

성능이 좋아도 전투가 산만하거나 역할 압력이 약해지면 채택하지 않는다.

### C. Five boss pattern candidates

공통 random bag을 추가하지 않는다. 후보마다 한 개의 주 회피 동사,
movement consequence, 낮은 자극 nuisance와 objective interaction을
결합한다.

| Boss | 주 판단 | 원거리 후보 | 이동 이후 후보 | 낮은 자극 방해 후보 | 반격/목표 후보 |
| --- | --- | --- | --- | --- | --- |
| Colossus | 옆으로 피하고 돌진 유도 | 두 shoulder의 3회 staggered Forge Volley | `0.80 s` tell, `0.65 s` ram, 충돌 뒤 `1.10 s` rear counter | 외곽 slag vent 최대 2 | ram을 active Forge Plate에 유도 |
| Leviathan | 연속 탄환 사이를 weave | 좌우 반 박자 차이의 5발 Wake Fan | `0.70 s` lunge 뒤 경로 양옆 cross-wake, 중심은 안전 | depth charge 최대 2 | active Segment Lock 방향 emitter 제거 |
| Titan | polarity에 맞는 lane 선택 | solid positive rail과 split negative rail 교대 | `0.75 s` magnetic pull 뒤 side shift, `0.90 s` counter | arc strip 최대 1 | relay 파괴로 해당 pattern safe lane 확장 |
| Behemoth | charge route를 고정하고 후방 공격 | armor rail shot 또는 full-path beam | `0.90 s` locked charge, 1회 aim correction, 충돌 뒤 `1.25 s` rear open | 이전 route mine 최대 4, `4 s` 만료 | Route Switch 뒤 Armor Car 충돌 유도 |
| Crown | lattice gap을 따라 회전 | 세 pylon radial burst와 한 sector gap | `0.70 s` marked reposition 뒤 lattice 회전 | sentinel 최대 2와 `1.0 s` assembly tell | outer core 파괴로 pylon attack과 summon slot 제거 |

#### 보존된 fairness 후보

- 동시에 direct high-salience attack은 최대 1개
- autonomous persistent zone은 최대 2개, arena 합계 `≤30%`
- player diameter `48` 기준 최소 `144` continuous safe corridor와 서로
  다른 safe sector 2개
- autonomous attack이 유일한 safe corridor를 덮으면 recovery까지 연기
- nuisance는 player 바로 아래가 아니라 최소 `144` 떨어진 예측 위치에
  생성
- phase progression은 damage만 높이지 않고 timing, 조합과 counter
  window를 변경

모든 수치와 pattern은 provisional이다.

#### 필요한 판단 prototype

전체 다섯 boss를 동시에 바꾸지 않는다.

1. 기존 boss 중 한 종류를 isolated Boss Practice vertical slice로 선택
2. 현재 pattern과 candidate를 같은 build와 difficulty에서 비교
3. 첫 시도에서 위험 원인과 대응법을 이해할 수 있는지 확인
4. 공격 회피 뒤 명확한 counter window가 생기는지 확인
5. nuisance가 판단을 보조하는지 단순 방해인지 확인
6. 반복 플레이에서 순서 암기만 남지 않는지 확인
7. 사용자 승인 뒤에만 다른 boss로 확대

## Tasks

### Activation Gate 0 — 명시적 재개

- [ ] 사용자가 map, enemy tactic 또는 boss pattern 중 재개할 범위를
  명시한다.
- [ ] 재개하지 않은 나머지 영역은 이 draft에 그대로 남긴다.
- [ ] 재개 시점의 product spec, runtime owner, tests와 recent history를
  다시 감사한다.

### Activation Gate 1 — 범위별 판단

- [ ] map은 structural surface compiler와 procedural topology 중 목표를
  먼저 확정한다.
- [ ] enemy tactic은 동일 seed A/B sandbox와 측정 항목을 확정한다.
- [ ] boss pattern은 prototype할 한 boss와 비교 기준을 확정한다.

### Activation Gate 2 — 제한된 prototype

- [ ] selected scope만 production behavior와 분리된 practice/capture
  surface에서 구현한다.
- [ ] current baseline과 candidate evidence를 같은 조건으로 보존한다.
- [ ] 기능, 체감, readability와 performance를 함께 검토한다.

### Activation Gate 3 — 사용자 승인과 새 active plan

- [ ] 후보별 채택·수정·폐기 결정을 사용자에게 설명한다.
- [ ] 승인된 내용만 product contract와 source owner에 맞춰 새 active
  ExecPlan으로 작성한다.
- [ ] 새 plan이 활성화되기 전에는 production code를 수정하지 않는다.

## Test Plan

현재는 실행하지 않는다. 재개 후에는 선택 영역에 따라 다음 focused
surface를 사용한다.

- map: field layout/world visual validator와 geometry fingerprint capture
- enemy tactic: collective tactic, pursuit, grid와 same-seed pressure
  scenario
- boss: boss practice, boss runtime/pattern validator와 per-boss replay

active plan의 asset/UI performance matrix를 이 draft의 prototype 결과로
대체하지 않는다.

## Rollback / Safety

- prototype은 current production behavior와 분리한다.
- baseline code와 authored data를 덮어쓰지 않는다.
- full five-boss, all-stage map 또는 276-enemy rollout 전에 one-slice
  approval을 요구한다.
- draft 숫자를 test expectation이나 product spec으로 복사하지 않는다.
- user-authored unrelated change를 stage, revert 또는 cleanup하지 않는다.

## Risks

| 위험 | 대응 |
| --- | --- |
| draft가 active instruction처럼 사용됨 | frontmatter `status: draft`와 activation banner 유지 |
| map surface와 topology가 다시 혼동됨 | 재개 첫 gate에서 둘 중 하나를 명시적으로 선택 |
| boss 후보가 재미 검증 없이 전체 구현됨 | one-boss practice prototype과 사용자 승인 선행 |
| tactic 성능 개선이 곧 재미 개선으로 오인됨 | same-seed 수치와 human gameplay review를 함께 요구 |
| active plan과 source owner가 그동안 바뀜 | 재개 시 current truth를 다시 감사하고 새 plan 작성 |

## Progress

- [x] 이전 active plan에서 map, enemy coordinated tactic과 boss-pattern
  후보를 분리했다.
- [x] research source, candidate contracts, provisional 수치와 acceptance
  의도를 보존했다.
- [x] 이 문서를 non-authoritative `draft`로 분류했다.
- [ ] activation 요청 없음
- [ ] prototype 없음
- [ ] 사용자 승인 없음

## Next Steps

현재 active work에서는 아무것도 실행하지 않는다. 사용자가 특정 영역을
다시 요청하면 Activation Gate 0부터 시작하고, 나머지 영역은 계속
deferred 상태로 둔다.

## Open Questions

- 향후 “맵 생성”이 current topology의 surface generation을 뜻하는지,
  topology와 encounter route 자체의 procedural generation을 뜻하는지
  사용자가 재개 시 결정해야 한다.
- enemy tactic과 boss pattern의 후보 수치·내용은 prototype 이전에
  승인된 결정으로 취급하지 않는다.

## Decision Notes

- 2026-07-31: 사용자가 map generation을 후순위로 미뤘다.
- 2026-07-31: 사용자가 active plan에는 asset/UI, attack communication,
  boss damage/objective, non-behavioral performance와 validation만 남기도록
  지시했다.
- 2026-07-31: enemy coordinated tactic과 boss-pattern 제안은 연구 근거는
  있으나 playable validation이 없으므로 draft에만 보존했다.
- 2026-07-31: current shipped tactic과 boss pattern은 이 draft 때문에
  자동으로 변경되지 않는다.
