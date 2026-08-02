---
type: plan
status: active
owner: BK
created: 2026-08-02
last_reviewed: 2026-08-02
topic: Asset/UI 교체 전 코드·게임플레이 안정화
scope: 2026-07-31~2026-08-02 세션에서 확정된 비디자인 미해결 이슈, 일반 적 이동·spawn 분산과 release gate
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../semantic-v2-runtime-acceptance-evidence.md
  - ../2026-08-02-enemy-movement-spawn-research.md
---

# Asset/UI 교체 전 코드·게임플레이 안정화 계획

최근 3일 세션, 현재 코드와 적 이동·spawn 외부 사례를 대조한 결과,
asset/UI 교체 전에 끝낼 작업은 다섯 묶음이다: 기체·보조무기 상태/방향,
일반 적의 이동·도착·국소 밀도, 파괴 지형, 공격 위협 등급 데이터, 고밀도
성능. 이미 해결된 항목은 회귀 검사만 하고, 새 이미지·UI 외관·enemy roster와
role 비율·boss pattern·맵 생성은 이 계획에서 다루지 않는다.

## Purpose

- 목표: 최근 세션에서 확인된 비디자인 결함과 미완성 gameplay 계약을 모두
  고친 뒤에만 asset/UI 교체를 시작한다.
- 최종 산출물: gameplay 코드, focused/integration validator, 갱신된 제품 명세,
  native/Web/lifecycle 성능 증거.
- 완료 상태: 아래 다섯 작업과 최종 gate가 모두 통과한
  `code_ready_for_asset_ui_switch`.

## Why / Context

이전 버전은 최근 세션을 제대로 전수 대조하지 않고 “성능만 미해결”이라고
잘못 결론냈다. 특히 7월 31일에 이미 기록된 방사 방향, 느린 적, 파괴 타일과
공격 가독성의 코드 전제조건을 누락했다. 이 계획은 그 결론을 폐기하고 현재
코드에서 실제로 남은 선행 작업만 다시 고정한다.

## Pre-plan Evidence Already Verified

| Source | 확인한 사실 | 계획 결정 |
| --- | --- | --- |
| `C:/Users/BK/.codex/sessions/2026/07/31/rollout-2026-07-31T13-22-07-019fb668-756a-75f1-8038-6a28323e6b42.jsonl` lines 10, 10876, 1223, 12287 | pickup·UI overflow·boss 무피해·군집 렉 보고, 오래된 자료 제거 요청, 맵 생성 보류 | 해결 항목과 성능 defect를 분리하고 맵 생성 제외 |
| `C:/Users/BK/.codex/sessions/2026/07/31/rollout-2026-07-31T23-29-48-019fb894-d02b-7600-aba9-b5207b150fe1.jsonl` lines 6048, 6279, 6628 | 궤도 물체는 바깥 방향, 적이 느림, 공격 방향 구분, 파괴 벽과 마모·붕괴 타일 요구 | 방향·속도·지형·위협 등급을 선행 코드 작업으로 확정 |
| `C:/Users/BK/.codex/sessions/2026/08/01/rollout-2026-08-01T23-32-12-019fbdbd-60ce-71b3-ad72-a10941855269.jsonl` lines 9, 543, 975 | 문서 권위와 capture 책임 정리 승인 | commits `e9efe70`, `4eac45a`, `7f9c554`로 해결; 재구현 금지 |
| `C:/Users/BK/.codex/sessions/2026/08/02/rollout-2026-08-02T09-39-40-019fbfe9-857e-7453-b72d-20908d848577.jsonl` lines 2126, 2648, 3008, 3114 | 디자인/적·boss 전략 외 모든 미해결 코드를 asset보다 먼저 고치라는 최종 범위 | 이 계획의 권위와 asset gate 순서 확정 |
| current `vehicle_secondary_runtime.gd`, `vehicle_combat_renderer.gd`, `vehicle_run.gd` | blade 위치는 개별 각도지만 회전은 공통 각도, orbiting drone body는 안쪽을 향하고, mine은 실제 변위가 아닌 hull 방향 사용하며, engine thrust는 dash 외에도 항상 표시됨 | Phase 1 |
| current `vehicle_enemy_archetypes.gd`, `vehicle_run.gd`, `vehicle_encounter_director.gd` | 일반 적 속도는 role base × 1.20 × difficulty × stage이며 체감 pace validator 없음 | Phase 2 |
| current `vehicle_combat_stages.gd`, `vehicle_spawn_allocator.gd`, `vehicle_encounter_runtime.gd` | main surge 약 90기를 12 squads로 나눈 뒤 3 squads가 하나의 anchor를 공유하고, 네 quadrant도 pack 순서로 도착 | Phase 2의 distinct-anchor/arrival-wave 계약 |
| current `vehicle_encounter_director.gd`, `vehicle_run.gd`, `vehicle_spatial_grid.gd` | ordinary move에도 30% cohesion이 상시 적용되지만 local separation은 없고, late active cap 276은 약 세 surge를 동시에 허용 | Phase 2의 separation/local-pressure 계약 |
| `.agents/2026-08-02-enemy-movement-spawn-research.md` | combat budget, distinct spawn directions, separation/cohesion 분리, minimum-distance sampling, bounded-neighbor avoidance를 현재 코드와 대조 | Phase 2 수치와 rejected alternatives |
| current `vehicle_terrain_runtime.gd`, three field definitions, `vehicle_game_spec.md` | Breakable Bulkhead 체력·파괴 core만 있고 현재 두 bulkhead는 enclosure 없는 독립 rect이며, wear/collapse tile은 명세가 금지하고 구현도 없음 | Phase 3에서 명세와 구현을 함께 교정 |
| current `docs/design/UI_VISUAL_SYSTEM.md` lines 216-220, `vehicle_attack_telegraph_builder.gd`, `vehicle_projectile_state.gd` | 정본은 delivery·ordinary/elite/boss·power 구분을 요구하지만 현재는 방향·affinity·피해량만 전달되고 위협 등급은 투사체 수명 전체에 보존되지 않음 | Phase 4 |
| `.agents/semantic-v2-runtime-acceptance-evidence.md` lines 141-180 | peak/capacity frame·physics gate 실패, 600초 lifecycle 미실행 | Phase 5 |

2026-08-02에 pickup, stage UI layout, boss exam, terrain runtime, secondary,
attack contract, combat renderer, performance scenario, document-authority
validator를 현재 HEAD에서 다시 실행했고 모두 exit code 0이었다. 이 통과는
기존 validator가 새 결함을 검사하지 않는다는 사실도 함께 확인한다.

## Complete Issue Ledger

### Asset/UI 전 수정

| 이슈 | 현재 상태 | 이 계획의 처리 |
| --- | --- | --- |
| 이동 중 engine cue | 부분 해결 | engine module은 hull에 고정하되 thrust/flame은 dash 중에만 표시 |
| Orbit Blade·Escort Drone 방향 | 미해결 구현 결함 | orbiting body별 바깥 방향으로 교정하고 8방향 renderer test 추가 |
| Wake Mine 배치 방향 | 계약·검증 미완성 | 현재 frame의 실제 이동 변위를 우선하고 정지 시 hull 방향을 fallback으로 사용 |
| 일반 적이 느림 | 미해결 tuning | ordinary 전용 multiplier `1.40`과 closing-time 계약을 적용 |
| 한 spawn 지점에 많은 적이 겹침 | 현 validator가 의도적으로 허용 | shared pack anchor를 12 distinct squad anchors와 3×4 arrival waves로 교체 |
| spawn 후 다시 한 덩어리가 됨 | permanent cohesion, separation 없음 | ordinary cohesion 제거, bounded local separation 적용 |
| player 주변 동시 압력이 지나침 | late active cap 276, local cap 없음 | authored 총량은 유지하고 active/600px/900px cap을 분리 |
| Breakable Bulkhead 보상 구역 | 체력·파괴 core만 구현, 막힌 구역은 없음 | 각 field에 두 개의 작은 authored reward enclosure를 만들고 기존 crate 8개 중 2개를 그 안으로 옮겨 파괴→접근 경로 검증 |
| 마모·붕괴 타일 | 미구현, 현 명세와 충돌 | 이 계획에 고정된 수치·지속성으로 명세와 runtime 구현 |
| 일반/엘리트/boss 공격 구분의 코드 데이터 | 부분 구현 | telegraph와 실제 hostile projectile에 `threat_tier` 보존 |
| 적 군집 시 렉 | 미해결 | 기능 수정 뒤 native/Web/lifecycle release gate까지 개선 |

### 해결되어 회귀 검사만 유지

| 이슈 | 현재 증거 |
| --- | --- |
| 기체 접촉 pickup | `VEHICLE_PICKUP_CONTACT_VALIDATION_OK` |
| upgrade vertical overflow | `VEHICLE_STAGE_UI_LAYOUT_VALIDATION_OK` |
| boss가 특정 상태에서 무피해 | sealed core도 `0.20×` 피해, `VEHICLE_BOSS_EXAMS_VALIDATION_OK` |
| boss 약화 목표 안내 | HUD/minimap/radar가 같은 objective snapshot 소비 |
| 기체 engine이 이동 중 꺾임 | hull rear socket에 고정되고 aim mount만 별도 회전 |
| dash의 붉은 radial | directional start/afterimage로 교체됨 |
| 지형 효과의 수치상 범위 불일치 | damage와 snapshot/render가 같은 `Rect2`/radius 사용 |
| 정본 문서와 capture 책임 혼재 | `e9efe70`, `4eac45a`, `7f9c554`; authority/capture validator 통과 |

### 이 계획에서 제외하지만 폐기하지 않음

- 기체 단일 asset화, engine/weapon attachment 제거, UI panel/card, XP 모양,
  projectile texture/glow, map wall·tile 이미지와 art style은 후속 asset/UI
  switch가 처리한다.
- 공격 가독성 중 코드가 맡는 것은 Phase 4의 방향·affinity·threat tier까지다.
  실제 색·모양·animation 차등은 해당 데이터를 소비하는 후속 asset 작업이다.
- 알고리즘 map 생성은 7월 31일 사용자 지시에 따라 보류한다.
- enemy roster, stage별 role 비율과 boss pattern 재설계는 별도 범위다. 다만
  ordinary 이동, spawn 공간/시간 분산, active/local-pressure cap과 collective
  cohesion 경계는 이번 지시로 이 계획에 포함한다.

## Locked Decisions

1. 새 asset이나 UI 외관 변경은 만들지 않는다.
2. player engine module은 후속 단일 craft asset switch 전까지 hull rear socket에
   고정한다. thrust beam/flame은 `dash_active=true`일 때만 보이고 일반 이동과
   정지 상태에서는 보이지 않는다.
3. 방향 기준은 다음처럼 고정한다.
   - Orbit Blade와 Escort Drone body: `body_position - player_position`의 각도.
   - Seeker와 Drone 공격 event: 실제 target 방향.
   - Wake Mine: 현재 frame 실제 변위의 반대편; 변위가 0이면 마지막 hull
     방향의 반대편.
4. ordinary movement multiplier는 `1.40`으로 고정한다. boss 이동과 committed
   charge의 `ENEMY_SPEED_MULTIPLIER=1.20`, projectile 속도는 그대로 둔다. role
   base 상대값, difficulty/stage curve와 elite `overclocked 1.15`/`heavy 0.90`은
   ordinary multiplier 뒤에 정확히 한 번 합성한다.
5. spawn 용어와 분산 계약은 다음처럼 고정한다.
   - authored population과 role multiset, main surge의 12 squads와 squad당
     4~8기는 유지한다.
   - 한 main surge는 `3 arrival waves × 4 quadrant-owned squads`로 예약한다.
     같은 wave에는 각 quadrant에서 한 squad씩 오고 wave gap은 `0.62초`, unit
     spacing은 `0.16초`, cue lead는 `0.90초`다.
   - 12 squads는 서로 다른 candidate anchor를 사용한다. anchor 목표 최소 거리는
     `480px`, 허용 하한은 `320px`이다. 한 squad 안 unit은 anchor 주위 최대
     `160px` fan에서 center-to-center `84px` 이상 떨어진다.
   - canonical field/seed fixture는 네 quadrant와 최소 6/8 sectors를 사용하고,
     한 sector population share `<=20%`, 인접 두 sector `<=35%`를 지킨다.
   - runtime field edge에서 후보가 부족하면 `480 → 400 → 320px` 순으로만
     완화하고, 그보다 낮은 fallback은 발생 횟수와 이유를 telemetry에 남긴다.
6. ordinary 이동과 collective tactic의 의미를 분리한다.
   - 일반 `move/recovery`에서는 squad centroid cohesion을 적용하지 않는다.
   - 명시적 `gather/lock/execute`만 formation target을 소유한다.
   - ordinary decision cadence `0.10초`에 기존 spatial grid로 가장 가까운
     8개 이웃만 조회한다. neighbor search는 `120px`, desired clearance는
     `self.radius + other.radius + 20px`이다.
   - 겹치지 않은 근접 상태는 role steering/separation을 `0.80/0.20`, 실제
     clearance 침범은 `0.55/0.45`로 blend한다. obstacle/cover recovery와
     committed attack path가 항상 우선한다.
7. 총량과 국소 압력을 분리한다.
   - Hard ordinary active caps는 `1/72/104/136/168`로 고정하고 Normal/Easy는
     기존 `active_cap` factor를 그대로 적용한다. 한 late active cap은 약
     1.9 surge까지만 동시에 활성화한다.
   - Hard 600px local caps는 `1/16/28/38/48`, 900px local caps는
     `1/32/56/76/96`이다. difficulty scaling은 active cap과 같은 factor다.
   - cap 밖의 적은 despawn하거나 순간 이동하지 않는다. 자신의 deterministic
     `target_sector`를 따라 900~1200px approach band에서 lateral steering을
     하고 slot이 생기면 진입한다.
   - authored population, stage quota와 performance stress fixture의
     276/320 actor workload는 유지한다. gameplay cap 감소로 성능 gate를
     낮추거나 통과한 것으로 간주하지 않는다.
8. `Wear Collapse Tile`은 다음 제품 결과와 수치로 고정한다.
   - 기존 wall·cover·Breakable Bulkhead와 다른 traversable terrain이다.
   - player 또는 enemy의 반복 통과로 `intact → cracked → collapsed`가 된다.
   - collapsed footprint 안에서는 player와 enemy 모두 피해를 받는다.
   - projectile은 wear를 만들지 않는다.
   field당 authored tile `4개`, distinct crossing `3회`에서 붕괴
   (`1회 cracked`), collapsed damage는 player/enemy/boss 모두 `8 damage /
   0.75초`, 상태는 같은 run 동안 stage 전환 뒤에도 유지한다. 예시로 언급된
   poison/lava 표현은 후속 asset 결정이지 code affinity로 자동 승격하지 않는다.
9. 각 field의 두 authored Breakable Bulkhead는 각각 작은 reward enclosure의
   유일한 입구다. enclosure의 나머지 면은 파괴되지 않는 structural wall이며
   ordinary cover와 별도 분류한다. 해당 stage의 기존 crate 8개 중 두 개를
   하나씩 안으로 relocate하고 새 crate는 추가하지 않는다. 이는 요청된 보상
   구역만 author하는 예외이며 알고리즘 map 생성이나 progression gate가 아니다.
   기존 bulkhead health persistence를 유지하므로 한 번 연 enclosure는 같은
   run의 후속 stage에서도 열린 상태다.
10. attack `threat_tier`는 `ordinary`, `elite`, `boss` 세 값만 사용한다.
   source가 `stage_boss`이면 `boss`, source enemy의 `elite_trait`가 비어 있지
   않으면 `elite`, 나머지는 `ordinary`다. affinity와 persistent condition은
   현재 계약을 그대로 유지한다.
11. production gameplay cap은 사용자 요구에 따라 낮추지만 performance
   qualification의 actor/projectile 수, 해상도, 품질과 release threshold는
   낮추지 않는다.
12. Phase 1~6과 최종 회귀 검사가 모두 끝나기 전에는 asset/UI switch를
   시작하지 않는다.

## Assumptions

- user가 말한 “뭉쳐다니는 수”는 authored stage 총량 자체보다 같은 spawn
  origin과 player 근처의 동시 밀도를 뜻한다. 따라서 authored population과
  quota는 유지하고 active/local pressure를 낮춘다.
- 현재 32개 field spawn candidates와 7200×4320 수준의 field는 canonical
  fixture에서 12 distinct anchors, 6 sectors, 320px 하한을 만족할 수 있다.
- 기존 threat budget과 collective tactic recipe는 공격 동시성의 별도 owner로
  유효하며 spawn/steering 변경 때문에 함께 재설계하지 않는다.

## Proposed Design

```text
authored 12 squads
  -> allocator: 3 waves × 4 quadrant-owned distinct anchors
  -> scheduler: max 4/tick, one lane per quadrant, 0.90s cue
  -> director: active cap + 600/900px local-pressure slots
  -> ordinary steering: role movement + bounded local separation
  -> explicit tactic only: gather/lock/execute formation override
```

이 흐름에서 stage data는 무엇이 얼마나 나오는지만, allocator/runtime은 어디서
언제 나오는지만, director는 동시에 얼마가 압력을 주는지만, local steering은
개체 사이 간격만 소유한다.

## Rejected Alternatives

| 대안 | 채택하지 않는 이유 |
| --- | --- |
| multiplier만 1.40으로 상향 | 현재 shared anchor와 cohesion이 유지되어 더 빨리 큰 덩어리가 됨 |
| spawn fan radius만 확대 | 3 squads가 한 anchor를 공유하고 네 quadrant가 순차 도착하는 구조를 해결하지 못함 |
| 모든 적에 Godot NavigationAgent/RVO 적용 | 새 node/solver 비용과 감속 tuning이 생기며 기존 grid·custom cover recovery와 책임이 중복됨 |
| active cap만 낮춤 | spawn origin 겹침과 permanent cohesion이 남아 작은 덩어리가 계속 만들어짐 |
| authored population/quota 삭제 | stage progression과 XP cadence를 불필요하게 바꾸고 performance workload도 약화함 |
| 매 frame 전체 enemy pair 검사 | 최대 actor workload에서 O(N²)이고 existing spatial grid를 무시함 |

## Architecture and Ownership

| Concern | Owner | 불변조건 |
| --- | --- | --- |
| secondary simulation | `scripts/player/vehicle_secondary_runtime.gd` | damage·cap·cooldown 유지 |
| player motion handoff | `scripts/vehicle/vehicle_run.gd` | manual aim, dash, collision truth 유지 |
| secondary presentation | `scripts/presentation/vehicle_combat_renderer.gd` | simulation 위치와 renderer 위치 일치 |
| ordinary pace/pressure caps | `scripts/encounters/vehicle_encounter_director.gd`, `vehicle_run_difficulty.gd` | ordinary만 변경; boss/attack/projectile 불변 |
| arrival packet shape | `scripts/vehicle/stages/vehicle_combat_stages.gd` | authored count, 12 squads, role multiset 유지 |
| arrival allocation/timing | `scripts/encounters/vehicle_spawn_allocator.gd`, `vehicle_encounter_runtime.gd` | distinct anchors, 3×4 wave, cue fairness, deterministic replay |
| ordinary local steering | 새 책임 파일 `scripts/enemies/vehicle_enemy_local_steering.gd`; `vehicle_run.gd`는 호출·적용만 수행 | grid query는 재사용, collective tactic과 committed path 침범 금지 |
| collective formations | `scripts/encounters/vehicle_collective_tactic_runtime.gd` | formation은 explicit gather/lock/execute에서만 활성 |
| functional terrain | `scripts/vehicle/vehicle_terrain_runtime.gd`, `scripts/vehicle/vehicle_terrain_definition.gd`, three field files | structural wall/cover 분리, exact footprint, bulkhead와 wear state의 run persistence |
| reward placement | `scripts/vehicle/vehicle_field_layout_generator.gd` | stage당 6 loose/8 crate와 drop 총량 유지 |
| attack semantics | `scripts/combat/vehicle_attack_contract.gd`, `vehicle_attack_telegraph_builder.gd`, `vehicle_projectile_state.gd` | collision·affinity·condition truth 유지 |
| performance | existing scenario/recorder, schedule/grid/projectile/renderer owners | `VehicleRun`에 새 catch-all 최적화 owner를 만들지 않음 |

## Tasks

### Phase 1 — engine cue와 보조무기 방향을 simulation truth와 일치

- [x] 일반 이동·정지 중 항상 그려지는 engine thrust beam을 제거하고,
  `dash_active` 중에만 rear 방향 cue를 그린다. engine module 위치와 aim mount
  회전은 현재 계약을 유지한다.
- [x] player 이동·dash·collision 적용 직후 실제 frame 변위를 계산해 secondary
  runtime에 `movement_direction`과 `hull_direction`을 분리 전달한다.
- [x] Wake Mine은 실제 movement direction을 우선하고 정지 fallback만 hull을
  사용한다.
- [x] Orbit Blade rotation에 blade index offset을 포함하고 Escort Drone body도
  player를 향하는 현재 inward vector를 반대로 바꿔 radial outward로 둔다.
- [x] Seeker/Drone 공격 event가 실제 target vector를 유지하는지 고정한다.
- [x] `validate_vehicle_secondary_weapons.gd`와
  `validate_vehicle_combat_renderer.gd`에 정지, 이동 반전, collision 정지,
  dash와 8방향 fixture를 추가한다.

Accept: non-dash frame의 thrust cue instance가 `0`, dash frame은 rear 방향 cue가
`1` 이상이다. nonzero Orbit Blade/Drone radial vector와 각 texture forward의
dot이 `>= 0.999`이고, mine 위치가 기대 rear point와 1px 이내다.

Guard: engine module socket, secondary damage, count, cooldown, target selection과
player aim은 변하지 않는다.

### Phase 2 — 일반 적 이동·spawn 분산·국소 압력 교정

Goal: 적은 더 빨리 유효 사거리로 들어오되, 한 지점에서 쏟아지거나 player
주변에서 다시 한 덩어리가 되지 않는다. 총 authored population과 enemy role
구성은 유지하고 active/local pressure만 별도로 제어한다.

#### 2A. 이동 속도

표의 각 셀은 `Stage 1 / Stage 5 px/s`이며 player base는 `280 px/s`다.
AS-IS는 현재 `1.20`, TO-BE는 ordinary 전용 `1.40`이다. stationary role은 두
경우 모두 `0`이고 boss/committed attack은 기존 `1.20`을 유지한다.

| Role | Base | AS-IS Easy | AS-IS Normal | AS-IS Hard | TO-BE Easy | TO-BE Normal | TO-BE Hard |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| scrap_drone | 225 | 259.3/269.7 | 264.6/275.2 | 270.0/280.8 | 302.5/314.6 | 308.7/321.0 | 315.0/327.6 |
| needle_drone | 170 | 195.9/203.8 | 199.9/207.9 | 204.0/212.2 | 228.6/237.7 | 233.2/242.6 | 238.0/247.5 |
| spark_minelet | 90 | 103.7/107.9 | 105.8/110.1 | 108.0/112.3 | 121.0/125.9 | 123.5/128.4 | 126.0/131.0 |
| chaser | 205 | 236.3/245.7 | 241.1/250.7 | 246.0/255.8 | 275.6/286.7 | 281.3/292.5 | 287.0/298.5 |
| shooter | 155 | 178.6/185.8 | 182.3/189.6 | 186.0/193.4 | 208.4/216.7 | 212.7/221.2 | 217.0/225.7 |
| controller | 135 | 155.6/161.8 | 158.8/165.1 | 162.0/168.5 | 181.5/188.8 | 185.2/192.6 | 189.0/196.6 |
| shield_escort | 165 | 190.2/197.8 | 194.0/201.8 | 198.0/205.9 | 221.9/230.7 | 226.4/235.4 | 231.0/240.2 |
| artillery_spotter | 115 | 132.5/137.8 | 135.2/140.6 | 138.0/143.5 | 154.6/160.8 | 157.8/164.1 | 161.0/167.4 |
| rammer | 185 | 213.2/221.7 | 217.6/226.3 | 222.0/230.9 | 248.7/258.7 | 253.8/264.0 | 259.0/269.4 |
| bulkhead_guard | 140 | 161.3/167.8 | 164.6/171.2 | 168.0/174.7 | 188.2/195.8 | 192.1/199.8 | 196.0/203.8 |
| splitter_barge | 120 | 138.3/143.8 | 141.1/146.8 | 144.0/149.8 | 161.3/167.8 | 164.6/171.2 | 168.0/174.7 |
| repair_tender | 145 | 167.1/173.8 | 170.5/177.3 | 174.0/181.0 | 195.0/202.8 | 198.9/206.9 | 203.0/211.1 |
| drone_carrier | 105 | 121.0/125.9 | 123.5/128.4 | 126.0/131.0 | 141.2/146.8 | 144.1/149.8 | 147.0/152.9 |

- [x] 모든 mobile ordinary archetype의 현재/목표 최종 속도를 difficulty와
  Stage 1/5 기준으로 산출했다.
- [ ] `ORDINARY_MOVEMENT_SPEED_MULTIPLIER=1.40`을 적용하고 tuning snapshot,
  제품 명세와 exact-value validator를 갱신한다.
- [ ] open-field fixture에서 Easy/Normal/Hard Stage 1의 `scrap_drone`과 `chaser`가
  1200px에서 출발해 stationary base player의 250px band 안으로 `<=4.2초`에
  들어오는지 검증한다. ranged/support role은 현재 distance band를 유지한다.

#### 2B. 12 distinct anchors와 3×4 arrival waves

| 항목 | AS-IS | TO-BE |
| --- | --- | --- |
| surge 구조 | 4 packs × pack당 3 squads | 3 waves × wave당 4 quadrant squads |
| squad anchor | pack의 3 squads가 한 점 공유 | 12 squads가 distinct anchor 사용 |
| quadrant timing | pack index에 따라 순차 도착 | 매 wave에 네 quadrant 동시 도착 |
| main unit spacing | 0.10초 | 0.16초 |
| wave gap | pack gap 0.65초 | 0.62초 |
| intra-squad spread | 38px fan | 160px fan, unit 간 84px 이상 |
| anchor spread | distinct 하한 없음 | 목표 480px, canonical 하한 320px |
| sector acceptance | 4/8 이상, one sector 35% | 6/8 이상, one 20%, adjacent 35% |

- [ ] `VehicleSpawnAllocator`가 먼저 네 quadrant별 candidate pool을 만들고,
  wave 0~2마다 각 pool에서 하나씩 선택하도록 바꾼다. 점수는 offscreen/fair
  ring, recent sector, 480px minimum distance, target distance, seeded tie-break
  순으로 결정한다.
- [ ] allocation descriptor에 `arrival_wave`, `arrival_lane`, `relaxation_tier`,
  `anchor_clearance`를 추가한다. `pack_index` 기반 production 경로와
  `SQUADS_PER_PACK` 의미는 제거하되 과거 save migration은 만들지 않는다.
- [ ] `VehicleEncounterRuntime`은 `(effective_time, arrival_wave,
  arrival_lane, unit_index, id)`의 안정된 key로 queue를 정렬해 같은 tick의
  최대 4기가 서로 다른 quadrant에서 하나씩 나오게 한다.
- [ ] 한 squad unit 위치는 seeded candidate sequence에서 84px minimum distance를
  만족하는 첫 점으로 고른다. 최대 16회 실패하면 fan radius 안의 가장 멀리
  떨어진 후보를 사용하고 fallback counter를 남긴다.
- [ ] cue는 squad anchor당 하나를 사용하되 wave가 분리되므로 동시에 보이는
  새 cue는 최대 4개다. 기존 0.90초 warning과 offscreen margin을 유지한다.
- [ ] stage transition의 첫 arrival `1.35초 이내` 계약을 보존하되 네 quadrant
  중 하나만 먼저 쏟아지는 `pack_gap=0` 예외는 제거한다.

#### 2C. ordinary local separation과 collective 경계

- [ ] 새 `VehicleEnemyLocalSteering`이 existing spatial grid로 120px 안의
  가장 가까운 active ordinary 8기를 `(distance_squared, id)` 순으로 고른다.
- [ ] 각 neighbor의 `self.radius + neighbor.radius + 20px` clearance 침범량과
  inverse-distance 방향을 합산하고 normalize한다. zero-distance tie는 두 actor
  ID hash로 정한 반대 방향을 사용해 replay를 결정적으로 유지한다.
- [ ] normal proximity는 `role 0.80 + separation 0.20`, clearance overlap은
  `role 0.55 + separation 0.45`로 합성하고 원래 role speed로 limit한다.
- [ ] obstacle/cover recovery, active charge, startup/lock, explicit collective
  gather/execute에는 ordinary separation을 섞지 않는다. collective break 뒤
  다음 ordinary decision부터 separation을 다시 사용한다.
- [ ] `EncounterDirector.cohesion_velocity()`의 ordinary 호출 경로와
  `formation_offset` 의존을 제거한다. formation geometry는
  `VehicleCollectiveTacticRuntime`만 소유한다.

#### 2D. active population과 local pressure

- [ ] Hard active cap을 `1/72/104/136/168`로 교체하고 difficulty scaling과
  deterministic queue replenishment를 유지한다.
- [ ] encounter pressure snapshot에 difficulty-scaled `near_600_cap`,
  `near_900_cap`, `near_600_overflow`, `near_900_overflow`와 sector별 inner/near
  histogram을 추가한다.
- [ ] local slot 판정은 enemy의 `target_sector`와 stable runtime ID 순으로 한다.
  900px cap 밖의 ordinary는 900~1200px band에서 자신의 sector를 향해 lateral
  movement하고, slot이 생기면 원래 role steering으로 복귀한다.
- [ ] startup/active, stationary, boss, boss add는 이 hold behavior로 갑자기
  취소하거나 이동시키지 않는다. 이미 900px 안에 있는 적을 cap 초과라는
  이유로 밀어내거나 despawn하지도 않는다.
- [ ] stress fixture의 peak 276, capacity/lifecycle 320 actor는 유지한다.
  production qualification만 새 active/local cap과 분리 계약을 검사한다.

#### 2E. focused·integration acceptance

- [ ] `validate_vehicle_spawn_allocation.gd`와
  `validate_vehicle_multi_sector_spawns.gd`의 shared-anchor 기대를 제거하고,
  all fields × all stages × 16 seeds에서 distinct distance, 3×4 timing, role
  multiset, cue limit, deterministic replay를 검증한다.
- [ ] 새 `validate_vehicle_enemy_local_steering.gd`로 zero-distance, 8-neighbor
  bound, role blend, overlap resolution, collective exclusion, cover priority를
  검증한다.
- [ ] `validate_vehicle_collective_tactics.gd`는 gather/lock/execute formation과
  break/cooldown만 검사하고 ordinary dormant cohesion이 없음을 추가한다.
- [ ] production replay 60초 sample에서 beat 4 median active가 cap의 90~100%,
  `near_600<=48`, `near_900<=96`, 한 900px sector share `<=25%`, scheduler
  starvation 0, ranged/denial commit cap 유지인지 검증한다.
- [ ] fixed path capture를 before/after로 겹쳐 첫 spawn warning, 첫 도착,
  10/30/60초의 위치·sector histogram과 평균 nearest-neighbor distance를
  evidence에 기록한다.

Batch acceptance: target speed table과 runtime 값이 일치하고, canonical
allocation은 12 distinct anchors/3×4 waves/6 sectors를 만족한다. 60초 production
replay에서 active cap은 채워지지만 player 900px 안에는 최대 한 surge 수준만
들어오며, overlap fixture는 두 actor가 두 decision 이내에 clearance를 회복한다.

Batch guard: authored count, quota, 12 squads, role multiset, enemy health/damage,
boss movement, committed charge, hostile projectile speed, attack budget과
collective tactic recipe는 변하지 않는다.

### Phase 3 — 파괴 지형 완성

Wear Collapse Tile은 아직 코드와 명세에 없으므로 AS-IS는 모두 `없음`이다.
구현 TO-BE는 아래 한 묶음으로 고정한다.

| 결정 | 고정 TO-BE | 이유 |
| --- | --- | --- |
| 배치 | field당 authored tile 4개 | 적은 수로도 반복 통과 경로를 만들고 topology를 과밀하게 하지 않음 |
| wear threshold | distinct crossing 3회 (`1회 cracked`, `3회 collapsed`) | 상태 전이가 눈에 띄면서 우발적 1회 통과로 즉시 위험해지지 않음 |
| collapsed damage | 8 damage / 0.75초 | 양 팀에 의미가 있지만 boss·player를 순간 삭제하지 않는 고정 cadence |
| boss 포함 | 포함 | “player와 enemy 모두” 계약에서 예외를 만들지 않음 |
| stage persistence | 같은 run 동안 유지 | 단일 연속 field와 bulkhead persistence 계약에 맞춤 |

- [x] `vehicle_game_spec.md`에 Breakable Bulkhead를 ordinary cover가 아닌 작은
  optional reward enclosure의 파괴 가능한 입구로 정의하고, 나머지 면의
  structural wall과 stage progression gate를 명확히 구분한다.
- [ ] `vehicle_game_spec.md`의 현 제외 문구를 위의 고정 계약으로 교체한다.
- [ ] TerrainRuntime이 `intact → cracked → collapsed` 상태와 wear/damage
  판정을 소유하고, VehicleRun은 player와 enemy의 post-collision swept path를
  전달하고 실제 damage만 적용한다.
- [ ] 정지 중에는 wear가 반복 증가하지 않고, 완전 이탈 뒤 재진입은 한 번
  증가하며, 빠른 dash와 한 frame 고속 enemy 통과도 빠뜨리지 않도록 focused
  validator를 추가한다.
- [ ] field당 4개의 authored `wear_collapse_tile` rect를 field definition에
  추가하고 wall, cover, spawn, pickup, gate와 겹치지 않게 검증한다.
- [ ] snapshot에 wear tile의 최소 `rect`, `state`, `wear`, `threshold`와
  enclosure structural wall의 exact rect를 내보내 후속 asset renderer가 같은
  gameplay truth를 소비하게 한다. 이 단계에서는 기존 wall fallback 기반의
  임시 geometry만 사용한다.
- [x] 각 field의 두 Breakable Bulkhead를 입구로 삼는 작은 reward enclosure를
  author한다. 나머지 면은 별도 `structural_wall` rect로 두고 movement,
  projectile, LOS와 pursuit가 같은 blocker를 소비하게 한다. selected ordinary
  cover 8개를 이어 붙여 벽처럼 사용하지 않는다.
- [x] 각 enclosure에 guarded `reward_pos`를 두고 stage마다 생성되는 기존 crate
  8개 중 두 개를 그 위치로 relocate한다. closed bulkhead 기준으로 일반 item
  socket과 달리 의도적으로 unreachable이어야 하고, open 기준으로 reachable
  이어야 한다.
- [x] 새 `tools/validation/validate_vehicle_destructible_terrain_flow.gd`로
  sealed 상태에서는 다른 경로·LOS·projectile로
  reward crate에 접근할 수 없고, `primary 4발 → bulkhead open → player/enemy/
  projectile/LOS/pursuit blocker 갱신 → crate 접근·player shot 파괴`가 가능하며
  hostile fire는 기존대로 crate에 막히는 전체 경로를 검증한다. stage 전환 뒤
  open 상태와 새 stage의 총 crate 8개도 함께 검증한다.

Accept: 고정된 tile 계약에서 양 팀의 swept crossing과 damage가 결정적이다.
각 enclosure의 reward point는 closed 상태 movement graph에서 player start와
분리되고 open 상태에서는 연결되며, LOS/projectile도 같은 경계를 따른다.
crate/drop 총량은 기존과 같다.

Guard: 두 authored reward enclosure 밖의 map topology, 알고리즘 map 생성,
ordinary cover 8개, spawn anchors, support field와 reward 총량은 변하지 않는다.

### Phase 4 — 공격 방향·위협 등급 데이터 완성

- [x] `VehicleAttackContract`에 세 `threat_tier`, normalize helper와
  `stage_boss → boss`, nonempty `elite_trait → elite`, 그 외 `ordinary`
  source mapping을 둔다.
- [x] ordinary/elite/boss telegraph descriptor가 tier, affinity, delivery,
  direction/footprint와 readiness를 함께 보존한다.
- [x] `VehicleProjectileState` pool configure/reset과 모든 hostile spawn call이
  source에서 계산한 tier를 수명 끝까지 보존한다. boss runtime call은 `boss`,
  ordinary/elite enemy call은 해당 enemy state를 명시적으로 전달한다.
- [x] ordinary, elite, boss projectile과 telegraph fixture를 추가해 tier가 서로
  섞이지 않고 reflection/retire/reuse 뒤 stale 값이 남지 않음을 검증한다.
- [x] renderer는 현재 fallback에서도 tier를 읽을 수 있게 하되 새 texture,
  palette나 UI를 만들지 않는다.

Accept: 세 공격 등급을 runtime snapshot에서 확정적으로 구별할 수 있고,
방향·affinity·danger footprint는 현재 collision truth와 동일하다.

Guard: damage, condition, startup, boss pattern과 elite gameplay modifier는
변하지 않는다.

### Phase 5 — 고밀도 성능과 release qualification

- [ ] Phase 1~4 완료 HEAD에서 `capacity_pressure` 3회 기준선을 다시 만든다.
- [ ] performance-active일 때만 grid write, enemy schedule, projectile/effect,
  presentation 비용을 분리 계측한다.
- [ ] 가장 큰 measured owner에 아래의 정해진 경계만 적용한다.

| Measured owner | 허용 변경 |
| --- | --- |
| enemy schedule | 동일 tick semantics를 유지하며 중복 traversal/clear 제거 |
| spatial grid | cell `Array.erase`를 reverse-index swap-remove로 교체하고 generation 검증 |
| projectile/effects | 기존 reusable buffer와 earliest-hit를 유지하며 중복 query/temporary allocation 제거 |
| presentation | actor body culling과 view-intersecting telegraph 검사를 분리 |

- [ ] 변경마다 owner validator와 capacity 3회 before/after를 비교하고 개선이
  run variance 안이면 task-owned 실험을 보존하지 않는다.
- [ ] native `production_replay`, `peak_horde`, `capacity_pressure`,
  `boss_pressure`, Web 같은 matrix, native 600초 `lifecycle_pressure`를 순서대로
  통과한다.

Native baseline과 최종 matrix는 1280×720 창을 계속 foreground/focused 상태로
두고 다음 명령을 사용한다. 각 결과의 `authoritative`, commit, dirty state와
scenario qualification을 함께 검사한다.

```powershell
$performanceCommit = (git rev-parse HEAD).Trim()
$performanceDirty = if (git status --porcelain) { "1" } else { "0" }
$env:PERFORMANCE_COMMIT = $performanceCommit
$env:PERFORMANCE_DIRTY = $performanceDirty

for ($attempt = 1; $attempt -le 3; $attempt++) {
  ./tools/godot.ps1 --path . --rendering-method gl_compatibility --resolution 1280x720 -- `
    --performance-scenario=capacity_pressure `
    --performance-output="res://build/performance/pre-asset/native/capacity-baseline-$attempt.json" `
    --performance-warmup=10 --performance-duration=60
  if ($LASTEXITCODE -ne 0) { throw "capacity baseline $attempt failed" }
}

foreach ($scenario in @("production_replay", "peak_horde", "capacity_pressure", "boss_pressure")) {
  ./tools/godot.ps1 --path . --rendering-method gl_compatibility --resolution 1280x720 -- `
    "--performance-scenario=$scenario" `
    "--performance-output=res://build/performance/pre-asset/native/$scenario-final.json" `
    --performance-warmup=10 --performance-duration=60
  if ($LASTEXITCODE -ne 0) { throw "performance matrix failed: $scenario" }
}

./tools/godot.ps1 --path . --rendering-method gl_compatibility --resolution 1280x720 -- `
  --performance-scenario=lifecycle_pressure `
  --performance-output=res://build/performance/pre-asset/native/lifecycle-pressure-600s.json `
  --performance-warmup=10 --performance-duration=600
if ($LASTEXITCODE -ne 0) { throw "lifecycle soak failed" }
Remove-Item Env:PERFORMANCE_COMMIT, Env:PERFORMANCE_DIRTY -ErrorAction SilentlyContinue
```

Web는 production export를 `$npjt-port-guard`의 fastrun `codex` lane으로 연 뒤
각 scenario에
`?performance_scenario=<id>&performance_warmup=10&performance_duration=60`을
붙인다. 보이는 foreground Chrome에서 실행하고
`window.__cardbornePerformanceResultJson`을 읽어
`build/performance/pre-asset/web/<id>-final.json`으로 보존한다. headless 또는
한 번이라도 hidden 상태였던 결과는 authoritative evidence로 사용하지 않는다.

Accept: frame median `>=59 FPS`, p95 `<=18 ms`, p99 `<=25 ms`, 1% low
`>=55 FPS`, consecutive `>33.3 ms` frame `<=1`, capacity/lifecycle physics
p95/p99 `<=6/8 ms`, lifecycle memory growth `<8 MiB`, draw-call p95 `<=200`,
combat batch `<=50`.

Guard: workload, 품질, actor/projectile/effect 수와 threshold를 낮추지 않는다.

### Phase 6 — Asset/UI switch gate 해제

- [ ] 전체 `tools/validation/validate_vehicle_*.gd`를 통과한다.
- [ ] document authority, Godot import, production Web export를 통과한다.
- [ ] `$npjt-port-guard`의 fastrun `codex` lane에서 built-Web 이동, primary,
  dash, EMP, terrain, secondary와 report 복귀 smoke를 수행한다.
- [ ] `.agents/semantic-v2-runtime-acceptance-evidence.md`에 commit, dirty state,
  환경, raw result와 최종 판정을 append한다.
- [ ] 완료된 gameplay 계약을 `vehicle_game_spec.md`에 남기고 이 ExecPlan은
  완료 후 active tree에서 삭제한다.

## Validation Cadence

Focused inner loop:

```powershell
$checks = @(
  "validate_vehicle_secondary_weapons.gd",
  "validate_vehicle_combat_renderer.gd",
  "validate_vehicle_run_difficulty.gd",
  "validate_vehicle_spawn_allocation.gd",
  "validate_vehicle_multi_sector_spawns.gd",
  "validate_vehicle_enemy_local_steering.gd",
  "validate_vehicle_collective_tactics.gd",
  "validate_vehicle_terrain_runtime.gd",
  "validate_vehicle_destructible_terrain_flow.gd",
  "validate_vehicle_field_layout_generation.gd",
  "validate_vehicle_attack_contract.gd",
  "validate_vehicle_projectile_store.gd",
  "validate_vehicle_stage_transition.gd",
  "validate_vehicle_run.gd",
  "validate_vehicle_performance_scenarios.gd"
)
foreach ($check in $checks) {
  ./tools/godot.ps1 --path . --headless --script "res://tools/validation/$check"
  if ($LASTEXITCODE -ne 0) { throw "Validation failed: $check" }
}
```

Final gates:

- 모든 `validate_vehicle_*.gd`.
- `./tools/validation/validate_document_authority.ps1`.
- `./tools/godot.ps1 --path . --headless --import`.
- `./tools/export_web.ps1`.
- built-Web smoke와 native/Web performance matrix.
- native 600초 lifecycle soak.

## Predetermined Error Handling

| Trigger | Required response |
| --- | --- |
| 기능 validator 실패 | 해당 batch를 완료 처리하지 않고 task-owned 변경만 수정 |
| wear tile이 authored feature와 겹침 | feature rect만 같은 field의 validated open floor로 이동; 개수·threshold는 변경 금지 |
| speed 변경이 boss/pattern 값에 전파됨 | ordinary 전용 multiplier 경계로 되돌리고 회귀 test 추가 |
| canonical allocation이 320px/6 sectors를 만족하지 못함 | stage 수치나 field geometry를 바꾸지 않고 allocator의 candidate ordering과 wave-to-quadrant assignment만 수정 |
| runtime edge에서 anchor relaxation이 320px 아래로 내려감 | spawn은 진행하되 fallback reason을 기록하고 같은 player-position fixture를 regression에 추가 |
| local separation이 cover route를 막거나 속도를 낮춤 | cover recovery 우선순위를 복구하고 neighbor weight만 정해진 0.20/0.45 범위 안에서 적용 |
| local pressure cap이 scheduler starvation을 만듦 | despawn/teleport 없이 approach-band slot arbitration과 replenishment ordering만 수정 |
| performance run이 focus/validation 때문에 invalid | 같은 build를 환경 교정 후 최대 3회 재실행 |
| performance 개선이 run variance 안 | 실험 diff를 보존하지 않고 다음 predetermined owner로 이동 |
| 관련 사용자 변경과 diff가 겹침 | 자동 revert하지 않고 중단해 정확한 overlap 보고 |
| dependency/native code, workload/threshold 변경이 필요 | 범위 밖이므로 사용자 승인 전 중단 |

## Rollback / Safety

- batch별 task-owned commit을 만든다.
- unrelated user change를 stage, revert 또는 정리하지 않는다.
- save schema가 아니라 run-local field state만 확장한다.
- hard reset, dependency 변경, threshold 완화와 history rewrite를 하지 않는다.
- gameplay behavior가 acceptance와 다르면 성능 개선이어도 폐기한다.

## Risks

| Risk | Control |
| --- | --- |
| mine 방향이 aim과 movement를 다시 혼동 | motion/hull/aim을 별도 인자로 고정하고 8방향 test |
| dash 전용 thrust가 engine module까지 숨김 | module instance와 transient cue count를 별도로 검증 |
| 속도 상향이 boss pattern까지 변경 | ordinary 전용 multiplier와 exact value validator |
| distinct anchor가 warning marker를 과밀하게 만듦 | 3 waves로 나눠 동시에 보이는 cue를 4개로 제한 |
| separation이 swarm을 흩어 role 정체성을 없앰 | clearance 근처에서만 20%, overlap에서만 45%로 제한하고 explicit tactic formation 보존 |
| approach band가 완전한 원형 벽을 만듦 | stable target sector와 lateral steering, sector별 slot cap으로 한 방향 정체 방지 |
| gameplay cap 감소가 성능 해결로 오인됨 | 276/320 stress fixtures와 release thresholds를 그대로 유지 |
| wear occupancy가 actor retire 뒤 남음 | tile 밖/retire cleanup과 lifecycle bounded-state 검사 |
| enclosure가 bulkhead를 우회할 수 있음 | closed/open movement graph와 LOS/projectile blocker를 같은 rect set으로 검증 |
| bulkhead reward가 reward 총량을 늘림 | stage마다 기존 8개 crate 중 두 개를 relocate하고 총량 validator 유지 |
| threat tier가 pooled projectile에 잔류 | configure/reset/reuse generation fixture |
| 기능 추가가 capacity를 악화 | Phase 1~4 완료 뒤 fresh 성능 baseline과 release gate |

## Progress

- [x] 최근 3일 root/continuation 세션에서 비디자인 issue 전수 추출.
- [x] current code, product spec, Git history와 focused validator로 상태 재판정.
- [x] 해결·asset/UI·deferred·미해결 범위 분리.
- [x] Phase 1: engine cue와 secondary 방향.
- [ ] Phase 2: ordinary enemy pace, distinct arrival, local separation/pressure.
- [ ] Phase 3: destructible terrain.
- [x] Phase 4: threat tier data.
- [ ] Phase 5: performance/release.
- [ ] Phase 6: asset/UI switch gate.

## Next Steps

1. Phase 2A 속도와 2B distinct arrival를 한 batch로 구현·검증한다.
2. Phase 2C local steering과 2D pressure cap을 두 번째 batch로 구현하고 60초
   production replay evidence를 남긴다.
3. Phase 3 wear 계약을 코드·제품 명세·validator에 반영한다.
4. 기능이 고정된 HEAD에서 Phase 5 성능을 측정·개선한다.
5. Phase 6가 통과하면 그때 asset/UI switch를 시작한다.

## Completion Criteria

- [x] dash 전용 thrust, secondary 방향·mine rear placement가 모든 fixture에서 정확하다.
- [ ] ordinary `1.40`, 12 distinct anchors, 3×4 waves, bounded separation과
  active/local pressure cap이 focused/production fixture에서 검증된다.
- [ ] boss/pattern/projectile 속도, authored count/quota/role multiset이 변하지 않는다.
- [ ] bulkhead reward flow와 고정된 wear/collapse tile 양 팀 damage 계약이 통과한다.
- [ ] ordinary/elite/boss threat tier가 telegraph와 projectile에 보존된다.
- [ ] native/Web/capacity/lifecycle 성능 gate가 모두 통과한다.
- [ ] resolved issue regression, import, Web export와 built-Web smoke가 통과한다.
- [ ] 새 asset/UI 외관 작업이 이 plan diff에 섞이지 않는다.

## Open Questions

없음. 이 계획의 구현에 필요한 speed, spawn distance/timing, active/local caps,
separation과 wear 수치는 모두 고정했다. 새 visual, map 생성, enemy roster/role
비율, boss pattern, dependency/native code 또는 performance workload/threshold
변경이 실제로 필요해질 때만 별도 승인을 요청한다.

## Decision Notes

- 2026-08-02: “성능만 미해결” 결론을 폐기했다.
- 2026-08-02: 7월 31일 방향·속도·파괴 지형·공격 구분 피드백을 선행 코드
  범위로 복구했다.
- 2026-08-02: wear/collapse tile의 배치·threshold·damage·persistence를
  decision-complete 값으로 고정했다.
- 2026-08-02: 공격 가독성은 code semantic과 후속 visual 소비로 분리했다.
- 2026-08-02: 성능은 모든 gameplay 수정 뒤 최종 release gate로 유지했다.
- 2026-08-02: Phase 1 engine/secondary 방향 구현과 focused/run/performance
  scenario 회귀 검증을 완료했다.
- 2026-08-02: ordinary movement를 boss/committed attack과 분리하고 전 role
  AS-IS/TO-BE와 `1.40`을 고정했다.
- 2026-08-02: 세 field의 두 bulkhead를 structural-wall reward enclosure의
  유일한 입구로 바꾸고 기존 crate 두 개 relocation과 closed/open flow를
  검증했다.
- 2026-08-02: ordinary/elite/boss `threat_tier`를 telegraph와 pooled hostile
  projectile 수명 전체에 보존하고 renderer fallback이 해당 값을 읽게 했다.
- 2026-08-02: 외부 game-developer 사례, steering/sampling/crowd 연구와 현재
  packet/runtime을 대조해 Phase 2를 speed-only에서 distinct arrival,
  separation, active/local pressure까지 확장했다.

## Stop Conditions

Complete when: Phase 1~6의 acceptance가 모두 통과하고 evidence가 기록됐을 때.

Escalate only when: 명시된 경계로 해결할 수 없어 새 dependency/native code,
map/strategy 변경, workload 또는 threshold 변경이 필요할 때.

Do not stop when: 한 validator 또는 한 performance run만 실패했을 때. 원인을
수정한 뒤 해당 narrow gate부터 재실행한다.

## Handoff

```text
Goal:
  최근 3일의 미해결 비디자인 이슈를 모두 고친 뒤 asset/UI switch gate를 연다.

Read first:
  이 계획, docs/product/vehicle_game_spec.md,
  .agents/2026-08-02-enemy-movement-spawn-research.md,
  .agents/semantic-v2-runtime-acceptance-evidence.md

Execute exactly:
  Phase 1 → 2 → 3 → 4 → 5 → 6

Stop when:
  기능·회귀·native/Web/lifecycle gate가 모두 통과했을 때
```
