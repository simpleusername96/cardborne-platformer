---
type: plan
status: active
owner: BK
created: 2026-08-02
last_reviewed: 2026-08-02
topic: Asset/UI 교체 전 코드·게임플레이 안정화
scope: 2026-07-31~2026-08-02 세션에서 확정된 비디자인 미해결 이슈, 일반 적 이동·unit birth 분산·player 수렴과 release gate
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
일반 적의 이동·개별 출생 분산·player 수렴, 파괴 지형, 공격 위협 등급 데이터,
고밀도 성능. 이미 해결된 항목은 회귀 검사만 하고, 새 이미지·UI 외관·enemy
roster와 role 비율·boss pattern·맵 생성은 이 계획에서 다루지 않는다.

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
| current `vehicle_combat_stages.gd`, `vehicle_spawn_allocator.gd`, `vehicle_encounter_runtime.gd` | main surge 약 90기를 12 squads로 나눈 뒤 3 squads가 하나의 anchor를 공유하고, 네 quadrant도 pack 순서로 도착 | squad는 authored metadata로만 유지하고 모든 ordinary birth position을 unit별로 분리 |
| current `vehicle_encounter_director.gd`, `vehicle_run.gd`, `vehicle_spatial_grid.gd` | ordinary move에도 30% cohesion이 상시 적용되고 실제 body overlap을 푸는 steering은 없다 | ordinary cohesion을 제거하고 physical overlap만 해소 |
| current `vehicle_encounter_runtime.gd`, `vehicle_run.gd` | 기존 cue는 active-cap 예약보다 먼저 방출되고 0.90초 유지되므로 cue-to-first-arrival이 capacity에 따라 어긋날 수 있다 | 세 arrival window와 최대 네 cue는 timing으로만 유지하고 first-unit reservation을 추가 |
| current field candidates, `vehicle_field_layout_generator.gd`, `vehicle_spawn_allocator.gd`, `vehicle_field_geometry_snapshot.gd` | field당 32 authored candidate는 runtime에서 valid subset으로 필터링되고 현재 최소 20점만 보장되어, window당 최대 32기의 독립 birth position과 320px hard floor를 항상 만들 수 없다 | immutable geometry에서 unit-level candidate pool을 만들고 cue admission 시 minimum-distance sampling |
| current pressure snapshot, `vehicle_enemy_state.gd` | `near_600/900`은 현재 관측값일 뿐이고 `target_sector` hash-vector는 소비되지 않는다 | 관측 telemetry만 유지하고 local admission과 unused `target_sector`는 만들거나 유지하지 않음 |
| `.agents/2026-08-02-enemy-movement-spawn-research.md` | minimum-distance sampling, separation/cohesion 분리와 combat budget을 현재 코드와 대조 | sampling은 birth에만, separation은 overlap에만, budget은 global active admission에만 적용 |
| 2026-08-02 user clarification | 외곽에서는 개별 적이 넓게 태어나고 이후 기체로 수렴해야 하며, 기체 근처의 고밀도 전투는 허용 | 600/900px local cap과 lateral hold를 폐기하고 role convergence를 acceptance로 고정 |
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
| 한 spawn 지점에 많은 적이 겹침 | 현 validator가 의도적으로 허용 | 모든 ordinary에 독립된 offscreen birth position과 320px hard floor 적용 |
| spawn 후 squad가 다시 합쳐짐 | permanent cohesion, overlap resolution 없음 | ordinary cohesion 제거, 실제 body overlap만 bounded steering으로 해소 |
| player 주변 고밀도 전투 | 허용해야 할 장르 결과 | 별도 진입 cap 없이 role steering으로 기체에 수렴; 수치는 관측만 함 |
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
  ordinary 이동, unit-level birth 분산, global active admission과 collective
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
   - 한 main surge의 12 squads는 `3 arrival windows × 4 logical squads`로
     예약한다. 이는 도착 시간을 나누는 scheduler 단위일 뿐, 이동 lane·formation·
     동일 출생 지점을 뜻하지 않는다. window request gap은 `1.20초`, unit
     spacing은 최소 `0.16초`다.
     여기서 `개별 출생`은 각 unit이 독립 좌표를 가진다는 뜻이며, 같은 atomic
     round의 1~4기가 서로 다른 좌표에 동시에 출현하는 것은 허용한다.
     일반 main packet의 cue lead와 visual duration은 `0.90초`다. stage transition의
     opening main packet만 기존 `0.35초 cue → 1.35초 first arrival` 계약을 보존해
     둘 다 `1.00초`를 사용한다.
   - authored beat-0 scout는 `scrap_drone` 한 기, cue/active-cap reservation 한 slot,
     `0.90초` cue lead와 visual duration을 유지하며 main arrival window로 합치지
     않는다.
   - 전역 cue budget은 window 하나의 첫 unit cue, 즉 marker 최대 `4개`다. cue를
     방출하기 전에 네 logical squad의 첫 unit, 총 `4 slot`을 current global active
     cap에 예약하고 각 cue가 가리킨 exact birth position에 cue lead 뒤 한 atomic
     round로 출현시킨다. 뒤 unit index도 살아 있는 squad를 한 atomic round로 묶어
     충분한 global slot이 생긴 첫 tick에 함께 내보낸다.
     capacity 때문에 뒤 round가 늦어져도 이미 보인 cue와 첫 arrival은 이동하지
     않는다.
   - squad는 role 조합과 collective tactic authoring을 위한 logical metadata로만
     남긴다. 모든 ordinary unit은 anchor/fan 없이 독립된 `birth_position`을 받고,
     같은 packet의 확정·pending position 및 최근 `2.0초` 실제 birth position과
     center-to-center 거리를 잰다.
   - unit-level allocation tier는 `T0: 900~2400px/목표 480px`,
     `T1: 900~2400px/목표 400px`, `T2: 900~2400px/하한 320px`,
     `T3: 900~2800px/하한 320px` 순서다. 모든 unit은 cue 시점 player 기준
     offscreen margin `220px`와 walkable-disc 검사를 지킨다. `T3` 다음 unsafe,
     on-screen 또는 320px 미만 fallback은 없다.
   - canonical player-start fixture에서는 window의 unit birth가 8개 sector를 모두
     사용하고 sector별 unit 수의 `max-min <= 1`을 지킨다. 첫 네 cue position은
     가능한 서로 가장 먼 sector에 하나씩 둔다. runtime field edge에서는 안전한
     sector를 round-robin으로 모두 사용하되 최소 2 sectors를 요구한다. 안전한
     unit position 전체를 만들 수 없으면 cue를 내지 않고 해당 window를 `0.25초`
     뒤 다시 allocation한다.
6. ordinary 이동과 collective tactic의 의미를 분리한다.
   - 일반 `move/recovery`에서는 squad centroid cohesion을 적용하지 않는다.
   - 명시적 `gather/lock/execute`만 formation target을 소유한다.
   - ordinary decision cadence `0.10초`에 기존 spatial grid로 가장 가까운
     8개 이웃만 조회한다. neighbor search는 `120px`지만 separation 대상은
     `distance < self.radius + other.radius`인 실제 body overlap뿐이다.
   - overlap이 없으면 기존 role velocity를 정확히 그대로 사용한다. overlap이
     있으면 role steering/separation을 `0.55/0.45`로 blend하고 원래 role speed로
     제한한다. obstacle/cover recovery와 committed attack path가 항상 우선한다.
   - 침범 neighbor가 있는데 separation 합이 상쇄되어 zero에 가까우면 가장 큰
     침범량의 neighbor 한 기에서 멀어지는 방향을 사용한다. tie는
     `(distance_squared, stable runtime ID)`이고 exact overlap만 두 ID hash의
     반대 방향을 사용한다.
7. 총량 제어와 관측 밀도를 분리한다.
   - `global active admission`만 field 전체의 alive/active/counts-active-cap ordinary
     수와 예약 slot을 제어한다. player 중심 `600/900px observed occupancy`는
     결과를 보는 telemetry일 뿐 진입 허가, 상한 또는 steering 명령이 아니다.
   - 현재 Hard/base ordinary active caps `1/124/172/224/276`을 그대로 유지한다.
     기존 `active_cap` factor를 한 번 적용한 derived caps는 Easy
     `1/110/152/198/244`, Normal `1/117/162/211/259`, Hard
     `1/124/172/224/276`이다. scheduler reservation도 이 전역 cap에 포함한다.
   - ordinary는 birth 뒤 `target_sector`, spawn anchor, squad centroid의 영향을
     받지 않고 각 role의 기존 pursuit/range/support behavior로 player에게
     수렴한다. player 근처에서 높은 밀도를 이루는 것은 허용된 전투 결과다.
   - 현재 소비되지 않는 `VehicleEnemyState.target_sector`와 관련 descriptor/
     configure 값을 제거한다. 새 `local_pressure_exempt`, local cap, crossing queue,
     hold band와 lateral steering은 만들지 않는다.
   - authored population, stage quota와 performance stress fixture의
     276/320 actor workload는 유지한다. 관측 밀도 증가를 performance gate 완화나
     gameplay cap 감소의 근거로 쓰지 않는다.
8. `Wear Collapse Tile`은 다음 제품 결과와 수치로 고정한다.
   - 기존 wall·cover·Breakable Bulkhead와 다른 traversable terrain이다.
   - player 또는 enemy의 반복 통과로 `intact → cracked → collapsed`가 된다.
   - collapsed footprint 안에서는 player와 enemy 모두 피해를 받는다.
   - projectile은 wear를 만들지 않는다.
   field당 authored tile `4개`, distinct crossing `3회`에서 붕괴
   (`1회 cracked`), collapsed damage는 player/enemy/boss 모두 entry 즉시
   `8 damage`와 연속 overlap 중 `0.75초마다 8 damage`, 상태는 같은 run 동안
   stage 전환 뒤에도 유지한다. 예시로 언급된
   poison/lava 표현은 후속 asset 결정이지 code affinity로 자동 승격하지 않는다.
   `VehicleFieldLayout.persistent_wear_tile_state`에는 feature ID별 `state`와
   `wear`만 저장한다. actor occupancy와 0.75초 damage cooldown은 stage-local이며
   transition configure에서 reset한다.
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
11. production global active cap과 performance qualification의 actor/projectile
   수, 해상도, 품질과 release threshold는 모두 현재 값에서 낮추지 않는다.
12. Phase 1~6과 최종 회귀 검사가 모두 끝나기 전에는 asset/UI switch를
   시작하지 않는다.

## Assumptions

없음. “뭉쳐다니는 수”는 같은 origin에서 겹쳐 태어나는 현상과 ordinary의
상시 squad cohesion을 뜻한다. 외곽 birth는 넓게 분산하고, birth 뒤에는 role
steering으로 player에게 수렴하며, player 근처 동시 밀도는 제한하지 않는다.
authored population/quota, threat budget과 collective tactic recipe를 바꾸려면
이 계획 밖의 별도 승인이 필요하다.

## Proposed Design

```text
authored roles + 12 logical squads
  -> scheduler: 3 timing windows × 4 logical squads
  -> allocator at cue admission: independent sparse offscreen birth per unit
  -> scheduler: four first-unit cues/reservations + atomic tail rounds
  -> director: unchanged global active cap only
  -> ordinary steering: unrestricted role movement toward/around player
  -> local steering: physical-overlap resolution only
  -> telemetry: observed 600/900px density, with no pass/fail ceiling
  -> explicit tactic only: gather/lock/execute formation override
```

이 흐름에서 stage data는 무엇이 얼마나 나오는지만, allocator/runtime은 어디서
언제 태어나는지만, director는 전역 활성 총량만, role steering은 birth 뒤
player 수렴을, local steering은 실제 body penetration 해소만 소유한다.

## Rejected Alternatives

| 대안 | 채택하지 않는 이유 |
| --- | --- |
| multiplier만 1.40으로 상향 | 현재 shared anchor와 cohesion이 유지되어 더 빨리 큰 덩어리가 됨 |
| spawn fan radius만 확대 | 공유 anchor라는 원인을 남기며 unit별 sparse birth를 보장하지 못함 |
| 모든 적에 Godot NavigationAgent/RVO 적용 | 새 node/solver 비용과 감속 tuning이 생기며 기존 grid·custom cover recovery와 책임이 중복됨 |
| global active cap 축소 | spawn origin 겹침과 permanent cohesion을 고치지 못하고 전투 총량만 약화함 |
| 600/900px local cap과 lateral hold | player 수렴을 막아 외곽 ring wall을 만들고 근접 고밀도를 허용한다는 제품 결정과 충돌함 |
| authored population/quota 삭제 | stage progression과 XP cadence를 불필요하게 바꾸고 performance workload도 약화함 |
| 매 frame 전체 enemy pair 검사 | 최대 actor workload에서 O(N²)이고 existing spatial grid를 무시함 |

## Architecture and Ownership

| Concern | Owner | 불변조건 |
| --- | --- | --- |
| secondary simulation | `scripts/player/vehicle_secondary_runtime.gd` | damage·cap·cooldown 유지 |
| player motion handoff | `scripts/vehicle/vehicle_run.gd` | manual aim, dash, collision truth 유지 |
| secondary presentation | `scripts/presentation/vehicle_combat_renderer.gd` | simulation 위치와 renderer 위치 일치 |
| ordinary pace/global active admission | `scripts/encounters/vehicle_encounter_director.gd`, `scripts/vehicle/vehicle_run_difficulty.gd` | speed multiplier만 변경; current global caps와 boss/attack/projectile 불변 |
| arrival packet shape | `scripts/vehicle/stages/vehicle_combat_stages.gd` | authored count, 12 squads, role multiset 유지 |
| birth candidate geometry | `scripts/vehicle/vehicle_field_geometry_snapshot.gd`, existing tactical-layout owner | immutable geometry의 pure walkable-disc/candidate query; map topology 불변 |
| arrival allocation/timing | `scripts/encounters/vehicle_spawn_allocator.gd`, `scripts/encounters/vehicle_encounter_runtime.gd`, `scripts/vehicle/vehicle_run.gd` | cue 시점 unit-level allocation, max 4 first-unit cues, global reservation, deterministic replay |
| ordinary local steering | 새 책임 파일 `scripts/enemies/vehicle_enemy_local_steering.gd`; `vehicle_run.gd`는 호출·적용만 수행 | actual overlap만 해소; non-overlap role velocity와 collective/committed path 불변 |
| collective formations | `scripts/encounters/vehicle_collective_tactic_runtime.gd` | formation은 explicit gather/lock/execute에서만 활성 |
| functional terrain | `scripts/vehicle/vehicle_terrain_runtime.gd`, `scripts/vehicle/vehicle_terrain_definition.gd`, `scripts/vehicle/vehicle_field_layout.gd`, three field files | structural wall/cover 분리, exact footprint, bulkhead와 wear state의 run persistence |
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

### Phase 2 — 일반 적 이동·unit-level spawn 분산·player 수렴

Goal: 일반 적은 넓은 화면 외곽의 서로 떨어진 위치에서 개별 출생하고, 출생
직후부터 각 role steering으로 player에게 수렴한다. player 근처의 고밀도 전투는
허용하며, authored population·role 구성과 current global active cap은 유지한다.

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
- [x] `ORDINARY_MOVEMENT_SPEED_MULTIPLIER=1.40`을 적용하고 tuning snapshot,
  제품 명세와 exact-value validator를 갱신한다.
- [x] open-field fixture에서 Easy/Normal/Hard Stage 1의 `scrap_drone`과 `chaser`가
  1200px에서 출발해 stationary base player의 250px band 안으로 `<=4.2초`에
  들어오는지 검증한다. ranged/support role은 현재 distance band를 유지한다.
- [x] 같은 open-field에서 player가 initial pursuit line에 수직으로 base
  `280px/s`로 4.2초 이동할 때 `chaser`의 시작 대비 closing distance가 Easy
  `>=500px`, Normal `>=520px`, Hard `>=540px`인지 검증한다. directly retreating
  player를 항상 따라잡게 만들지는 않는다.

#### 2B. main surge의 unit-level sparse birth와 truthful cue

| 항목 | AS-IS | TO-BE |
| --- | --- | --- |
| authored grouping | 4 packs × pack당 3 squads | 12 logical squads와 role multiset 유지 |
| scheduler grouping | pack 순서 | 3 timing windows × window당 4 logical squads |
| birth position | 3 squads가 pack anchor를 공유하고 38px fan | 모든 unit이 독립된 final position 보유 |
| birth clearance | unit-level 하한 없음 | 목표 480px, hard floor 320px |
| birth direction | 네 pack quadrant가 순차 도착 | canonical 8 sectors 균등 사용; field edge 최소 2 safe sectors |
| visible cue | pack cue coalescing | window의 squad별 첫 unit만 exact-position cue, 최대 4개 |
| main unit spacing | 0.10초 | 0.16초 |
| window gap | 기본 beat≤1 0.90초 / beat≥2 0.65초; transition opening first packet 0초 | request와 실제 `cue_at` 모두 최소 1.20초 |

- [x] stage data는 12 logical squad의 role slots와 requested timing만 소유한다.
  squad에는 spatial anchor, lane 또는 post-spawn movement 의미를 두지 않는다.
- [x] `VehicleFieldGeometrySnapshot`/tactical-layout owner가 immutable field geometry로
  deterministic candidate pool과 pure `is_spawnable_disc(position, radius)` query를
  제공한다. field당 32 authored candidate와 generated tactical-layout의 current
  valid-subset minimum 20을 억지로 늘리거나 map topology를 바꾸지 않는다.
- [x] 각 arrival window가 cue admission을 받을 때 `VehicleSpawnAllocator`가 그
  frame의 player position·visible rect·geometry snapshot으로 window의 모든 unit
  `birth_position`을 먼저 확정한다. 같은 packet의 확정·pending positions와 최근
  `2.0초` 실제 birth positions를 상대로 `T0→T3` minimum-distance tier를 적용하고,
  cue 뒤에는 위치를 바꾸지 않는다. window 단위 admission은 cue/timing의 원자성을
  위한 것이며 unit별 좌표의 독립성을 합치지 않는다.
- [x] canonical start는 8 sectors를 모두 사용하고 sector별 count의
  `max-min <= 1`을 지킨다. 첫 네 position은 가능한 서로 가장 먼 sector에서
  고른다. field edge는 안전한 sector를 round-robin으로 모두 사용하되 최소 2개를
  요구한다. 전체 unit position이 offscreen `220px`, player 거리 `>=900px`,
  pairwise hard floor `>=320px`, walkable-disc를 만족하지 못하면 cue 없이
  `birth_capacity_blocked`를 기록하고 `0.25초` 뒤 window 전체를 재시도한다.
- [x] descriptor는 `arrival_window`, `window_slot`, `unit_index`, `birth_position`,
  `birth_clearance`, `birth_sector`, `relaxation_tier`만 전달한다. `arrival_lane`,
  shared anchor/fan, `pack_index`, `group_index`, `pack_count`, `squads_per_pack`,
  `pack_gap`, `SQUADS_PER_PACK`, cue coalescing과 unused `target_sector` production
  경로를 제거한다. run-local 변경이므로 save migration은 만들지 않는다.
- [x] `VehicleEncounterRuntime`은 window request를
  `(requested_cue_time, authored_packet_index, arrival_window, packet_id)` FIFO로
  관리한다. global cue budget이 비고 current active cap에 4 slot이 있으면 각
  logical squad의 unit index 0을 예약한 뒤 exact birth position의 cue 네 개를 함께
  방출한다. 예약은 summon 포함 global cap 계산에 들어가고 first round 출현 또는
  `stop_spawning()` 때 해제한다.
- [x] first round는 `cue_at + cue_lead`에 정확히 출현한다. tail round `j>0`은
  각 logical squad의 unit index `j` 중 존재하는 1~4기를 묶어 nominal
  `cue_at + cue_lead + j×0.16` 이후 global slot이 생긴 첫 tick에 부분 분할 없이
  출현시킨다. tail도 이미 확정한 독립 birth position을 사용하며 squad cue
  position이나 fan에서 나오지 않는다.
- [x] cue reservation과 tail round는 nominal time FIFO 하나를 사용하고 다음
  packet은 이전 packet의 final tail 뒤에만 시작한다. `capacity_blocked`와
  spacing/fence 대기를 구분하며 eligible item을 첫 tick에 처리하지 못한 경우만
  `scheduler_starvation`으로 기록한다.
- [x] beat-0 scout는 별도 one-unit request로 active slot 하나를 예약하고 0.90초
  cue 뒤 exact spawn한다. stage transition은 scout를 생략하고 opening main의
  cue lead/visual duration만 1.00초로 유지한다. standard main과 scout는 0.90초다.
  `VehicleRun`이 cue descriptor의 `visual_duration`을 effect lifetime으로 전달하고
  renderer는 그 effect를 그린다.
- [x] runtime snapshot은 `reserved_arrival_slots`, `capacity_blocked_seconds`,
  `packet_fence_blocked_seconds`, `birth_capacity_blocked`,
  `scheduler_starvation`과 window별 `requested_cue_at`, `cue_at`, `nominal_due`,
  `emitted_at`을 내보낸다. 이미 보인 cue를 global delay로 미는 기존 경로는 제거한다.

#### 2C. role convergence, physical-overlap resolution과 collective 경계

- [x] `EncounterDirector.cohesion_velocity()`의 ordinary 호출과 ordinary
  `formation_offset` 의존을 제거한다. spawn descriptor는 birth 뒤 steering에
  관여하지 않고 기존 pursuit/range/support role velocity가 player에게 수렴한다.
- [x] 새 `VehicleEnemyLocalSteering`은 existing spatial grid로 120px 안의 가장
  가까운 active ordinary 8기를 `(distance_squared, id)` 순으로 조회하되,
  `distance < self.radius + neighbor.radius`인 실제 overlap만 계산한다.
- [x] overlap vector는 penetration depth를 가중해 합산한다. 합이 zero에 가까우면
  가장 큰 침범량, `(distance_squared, id)` 순의 neighbor에서 멀어지고, exact
  zero-distance 방향만 두 actor ID hash로 결정해 replay를 안정화한다.
- [x] 한 cadence에는 가장 가까운 actual-overlap neighbor 최대 8기만 해소하고
  나머지는 다음 cadence에서 다시 평가한다. 8기 상한을 채우기 위해 non-overlap
  neighbor를 separation 대상으로 승격하지 않는다.
- [x] overlap이 없으면 role velocity를 bit-for-bit 그대로 반환한다. overlap이
  있을 때만 `role 0.55 + separation 0.45`로 합성해 원래 role speed로 제한한다.
  desired clearance, proximity spacing, squad cohesion과 player 주변 밀도 완화는
  추가하지 않는다.
- [x] obstacle/cover recovery, active charge, startup/lock과 explicit collective
  `gather/lock/execute`가 항상 우선한다. collective formation geometry는
  `VehicleCollectiveTacticRuntime`만 소유하며 phase 종료 뒤 ordinary role
  steering으로 복귀한다.

#### 2D. current global active admission과 관측 밀도

- [x] current Hard/base active caps `1/124/172/224/276`과 difficulty scaling을
  유지한다. derived Easy `1/110/152/198/244`, Normal
  `1/117/162/211/259`, Hard `1/124/172/224/276`을 exact-value validator로 잠그고
  arrival reservation도 같은 cap에서 센다.
- [x] 600/900px local cap, boundary crossing admission, per-sector queue,
  `local_pressure_exempt`, hold band, inward-component 제거와 lateral steering은
  구현하지 않는다. 이미 계획만 존재하는 `VehicleLocalPressureAdmission` 파일과
  validator도 만들지 않는다.
- [x] current `near_600/900`과 sector histogram은 actual-position 기반 관측
  telemetry로 유지한다. 값에 gameplay ceiling이나 pass/fail upper bound를 두지
  않고 actor를 deactivate, despawn, teleport 또는 밀어내는 데 사용하지 않는다.
- [x] fixed-player와 moving-player fixture에서 birth 시점과 `+2/+4초`의
  player-distance 및 role target-band error를 기록한다. non-committed mobile
  ordinary는 role별 target band를 향해 진행해야 하며, 근접한 결과나 높은
  `near_600/900`은 실패로 판정하지 않는다.
- [x] authored population, quota와 peak 276/capacity·lifecycle 320 actor workload를
  그대로 두고 성능은 Phase 5의 별도 gate로 판정한다.

#### 2E. focused·integration acceptance

- [x] `validate_vehicle_spawn_allocation.gd`와
  `validate_vehicle_multi_sector_spawns.gd`에서 pack/shared-anchor 기대를 제거한다.
  `FIXED_SEED + 0..15`, all fields × all stages × every main packet에서 unit별
  final position, deterministic replay, role multiset, offscreen/player distance,
  320px hard floor와 canonical 8-sector balance를 검사한다. field-edge fixture는
  최소 2 safe sectors를 사용하거나 window 전체가 지연되며 unsafe fallback은 없다.
- [x] 새 `validate_vehicle_arrival_scheduler.gd`는 cue marker `<=4`, exact-position
  first arrival, standard/scout `0.90초`, transition exception `1.00초`, actual window
  gap `>=1.20초`, packet completion fence, atomic tail round, active+reserved cap,
  equal-time FIFO, capacity recovery, `scheduler_starvation=0`과 stop cleanup을 검사한다.
- [x] 새 `validate_vehicle_enemy_local_steering.gd`는 zero-distance, 8-neighbor bound,
  symmetric fallback, overlap 해소와 collective/cover priority를 검사한다.
  non-overlap fixture에서는 출력 velocity가 입력 role velocity와 정확히 같아야 한다.
- [x] `validate_vehicle_collective_tactics.gd`는 explicit gather/lock/execute
  formation과 break/cooldown만 검사하고 ordinary dormant cohesion이 없음을 추가한다.
- [x] Hard production replay의 pass/fail에는 birth clearance violation `0`,
  `+2/+4초` role target-band progress와 `scheduler_starvation=0`만 사용한다.
- [x] 같은 replay의 10/30/60초 actual-position sector histogram,
  `near_600/900`과 nearest-neighbor distance는 diagnostic evidence로만 기록한다.
  spawn 뒤 nearest-neighbor 감소와 근접 밀도 증가에는 상한을 두지 않는다.
- [x] scripted five-stage run은 각 difficulty에서 scaled quota만큼 ordinary를
  공급해 boss warning/spawn까지 도달하고, `stop_spawning()` 뒤 cue, reservation과
  pending round가 모두 0이며 defeat/XP counting 계약이 같은지 검사한다.

Batch acceptance: speed table과 runtime 값이 일치하고, 모든 main ordinary는
unit-level sparse offscreen birth를 가진다. cue는 정확한 first birth를 예고하며
동시에 네 개를 넘지 않는다. birth 뒤에는 spawn metadata의 제약 없이 role별로
player에게 수렴하고 실제 body overlap만 해소한다. 기존 committed attack과 explicit
collective tactic만 role convergence의 의도된 예외이며, player 근처 고밀도는
허용된다.

Batch guard: authored count, quota, 12 logical squads, role multiset, current global
active caps, enemy health/damage, boss movement, committed charge, hostile projectile
speed, attack budget과 collective tactic recipe는 변하지 않는다.

### Phase 3 — 파괴 지형 완성

Wear Collapse Tile은 아직 코드와 명세에 없으므로 AS-IS는 모두 `없음`이다.
구현 TO-BE는 아래 한 묶음으로 고정한다.

| 결정 | 고정 TO-BE | 이유 |
| --- | --- | --- |
| 배치 | field당 authored tile 4개 | 적은 수로도 반복 통과 경로를 만들고 topology를 과밀하게 하지 않음 |
| wear threshold | distinct crossing 3회 (`1회 cracked`, `3회 collapsed`) | 상태 전이가 눈에 띄면서 우발적 1회 통과로 즉시 위험해지지 않음 |
| collapsed damage | entry 즉시 8 damage, 연속 overlap 중 0.75초마다 8 | 모든 actor 범주에 의미가 있지만 boss·player를 순간 삭제하지 않는 고정 cadence |
| boss 포함 | 포함 | “player와 enemy 모두” 계약에서 예외를 만들지 않음 |
| stage persistence | 같은 run 동안 유지 | 단일 연속 field와 bulkhead persistence 계약에 맞춤 |

- [x] `vehicle_game_spec.md`에 Breakable Bulkhead를 ordinary cover가 아닌 작은
  optional reward enclosure의 파괴 가능한 입구로 정의하고, 나머지 면의
  structural wall과 stage progression gate를 명확히 구분한다.
- [x] `vehicle_game_spec.md`의 현 제외 문구를 위의 고정 계약으로 교체한다.
- [x] TerrainRuntime이 `intact → cracked → collapsed` 상태와 wear/damage
  판정을 소유하고, VehicleRun은 player와 enemy의 post-collision swept path를
  전달하고 실제 damage만 적용한다.
- [x] 이미 collapsed인 tile에 swept path가 처음 진입하거나 해당 crossing이 wear
  3을 만들어 tile을 collapsed로 바꾸는 순간 8 damage를 즉시 한 번 적용한다.
  overlap이 이어지면 actor×tile별 다음 deadline부터 0.75초마다 8 damage를 주고,
  한 physics tick에는 한 번만 적용한 뒤 그 적용 시점에서 다음 0.75초를 센다.
  완전 이탈하면 occupancy와 deadline을 제거하므로 재진입은 다시 즉시 피해다.
- [x] `VehicleFieldLayout.persistent_wear_tile_state`를 run-scoped owner로 추가하고
  TerrainRuntime configure가 feature ID별 `state/wear`를 읽고 즉시 write-through
  한다. 기존 `persistent_bulkhead_health`는 이름과 계약을 유지하며 두 dictionary를
  합치거나 save schema를 만들지 않는다.
- [x] 정지 중에는 wear가 반복 증가하지 않고, 완전 이탈 뒤 재진입은 한 번
  증가하며, 빠른 dash와 한 frame 고속 enemy 통과도 빠뜨리지 않도록 focused
  validator를 추가한다.
- [x] 새 `validate_vehicle_wear_collapse_tiles.gd`는 player, ordinary와 stage boss의
  swept crossing, collapse-triggering crossing의 immediate hit, continuous
  `8 damage / 0.75초`, exit/re-entry immediate hit, stationary wear non-repeat와
  actor retire cleanup을 검사한다. stage 1에서 `cracked`/`collapsed`를 만든 뒤
  stage 2와 3의 새 TerrainRuntime에서도 `state/wear`가 같고 occupancy/cooldown만
  비어야 한다. configure 뒤 still-collapsed tile에 처음 감지된 overlap도 새 entry로
  보고 즉시 한 번 피해를 준다.
- [x] field당 4개의 authored `wear_collapse_tile` rect를 field definition에
  추가하고 wall, cover, spawn, pickup, gate와 겹치지 않게 검증한다.
- [x] snapshot에 wear tile의 최소 `rect`, `state`, `wear`, `threshold`와
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

Accept: 고정된 tile 계약에서 player/ordinary/boss의 swept crossing과 damage가
결정적이고 `state/wear`만 stage를 넘어 지속된다.
각 enclosure의 reward point는 closed 상태 movement graph에서 player start와
분리되고 open 상태에서는 연결되며, LOS/projectile도 같은 경계를 따른다.
crate/drop 총량은 기존과 같다.

Guard: 두 authored reward enclosure 밖의 map topology, 알고리즘 map 생성,
ordinary cover 8개, ordinary birth-candidate geometry의 walkability, support field와
reward 총량은 변하지 않는다.

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

- [x] Phase 1~4 완료 HEAD에서 `capacity_pressure` 3회 기준선을 다시 만든다.
- [x] performance-active일 때만 grid write, enemy schedule, projectile/effect,
  presentation 비용을 분리 계측한다.
- [x] 가장 큰 measured owner에 아래의 정해진 경계만 적용한다.

| Measured owner | 허용 변경 |
| --- | --- |
| enemy schedule | 동일 tick semantics를 유지하며 중복 traversal/clear 제거 |
| spatial grid | cell `Array.erase`를 reverse-index swap-remove로 교체하고 generation 검증 |
| projectile/effects | 기존 reusable buffer와 earliest-hit를 유지하며 중복 query/temporary allocation 제거 |
| presentation | actor body culling과 view-intersecting telegraph 검사를 분리 |

- [x] 변경마다 owner validator와 capacity 3회 before/after를 비교하고 개선이
  run variance 안이면 task-owned 실험을 보존하지 않는다.
- [ ] native와 Web의 `production_replay`, `peak_horde`, `capacity_pressure`,
  `boss_pressure`를 각각 authoritative 3회 통과한 뒤 native 600초
  `lifecycle_pressure`를 통과한다. 각 3회는 모두 개별 threshold를 만족해야 하고
  worst-of-three를 최종 evidence에 기록한다.

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
  for ($attempt = 1; $attempt -le 3; $attempt++) {
    ./tools/godot.ps1 --path . --rendering-method gl_compatibility --resolution 1280x720 -- `
      "--performance-scenario=$scenario" `
      "--performance-output=res://build/performance/pre-asset/native/$scenario-final-$attempt.json" `
      --performance-warmup=10 --performance-duration=60
    if ($LASTEXITCODE -ne 0) { throw "performance matrix failed: $scenario/$attempt" }
  }
}

./tools/godot.ps1 --path . --rendering-method gl_compatibility --resolution 1280x720 -- `
  --performance-scenario=lifecycle_pressure `
  --performance-output=res://build/performance/pre-asset/native/lifecycle-pressure-600s.json `
  --performance-warmup=10 --performance-duration=600
if ($LASTEXITCODE -ne 0) { throw "lifecycle soak failed" }
Remove-Item Env:PERFORMANCE_COMMIT, Env:PERFORMANCE_DIRTY -ErrorAction SilentlyContinue
```

Web는 production export를 `$npjt-port-guard`의 fastrun `codex` lane으로 연 뒤
각 scenario를 attempt `1..3`으로 반복하고
`?performance_scenario=<id>&performance_warmup=10&performance_duration=60`을
붙인다. 보이는 foreground Chrome에서 실행하고
`window.__cardbornePerformanceResultJson`을 읽어
`build/performance/pre-asset/web/<id>-final-<attempt>.json`으로 보존한다. 세 valid
payload가 모두 threshold를 통과해야 한다. headless 또는 한 번이라도 hidden
상태였던 결과는 count하지 않고 같은 scenario에서 최대 3번까지만 replacement
run을 허용하며, 그 안에 valid 3회를 만들지 못하면 Phase 5를 중단한다.

Accept: 각 native/Web attempt의 frame median `>=59 FPS`, p95 `<=18 ms`, p99
`<=25 ms`, 1% low
`>=55 FPS`, consecutive `>33.3 ms` frame `<=1`, capacity/lifecycle physics
p95/p99 `<=6/8 ms`, lifecycle memory growth `<8 MiB`, draw-call p95 `<=200`,
combat batch `<=50`이다. report summary는 metric별 worst-of-three와 raw payload
세 경로를 함께 가진다.

Guard: workload, 품질, actor/projectile/effect 수와 threshold를 낮추지 않는다.

### Phase 6 — Asset/UI switch gate 해제

- [x] 전체 `tools/validation/validate_vehicle_*.gd`를 통과한다.
- [x] document authority, Godot import, production Web export를 통과한다.
- [ ] `$npjt-port-guard`의 fastrun `codex` lane에서 built-Web 이동, primary,
  dash, EMP, terrain, secondary와 report 복귀 smoke를 수행한다.
- [x] `.agents/semantic-v2-runtime-acceptance-evidence.md`에 commit, dirty state,
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
  "validate_vehicle_encounter_pacing.gd",
  "validate_vehicle_spawn_allocation.gd",
  "validate_vehicle_multi_sector_spawns.gd",
  "validate_vehicle_arrival_scheduler.gd",
  "validate_vehicle_enemy_local_steering.gd",
  "validate_vehicle_collective_tactics.gd",
  "validate_vehicle_terrain_runtime.gd",
  "validate_vehicle_destructible_terrain_flow.gd",
  "validate_vehicle_wear_collapse_tiles.gd",
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
| canonical allocation이 T3까지 320px/8-sector balance를 만족하지 못함 | field geometry·hard floor·sector 계약을 낮추지 않고 geometry-derived candidate ordering과 unit assignment를 수정; 그래도 실패하면 Phase 2B를 중단하고 사용자 승인 요청 |
| runtime edge에서 전체 unit을 2개 이상 safe sectors에 배치할 수 없음 | cue/spawn하지 않고 해당 window 전체를 0.25초 뒤 재평가하며 `birth_capacity_blocked` 기록; 320px 아래/on-screen fallback 금지 |
| cue 뒤 first round가 descriptor의 cue lead(일반 0.90초, transition opening main 1.00초)보다 늦어짐 | 예약 산술과 ordinary summon admission을 수정하고 emitted cue/birth position을 이동시키지 않음 |
| 실제 window cue gap이 1.20초 미만이거나 다음 packet이 이전 final tail 전에 시작됨 | spacing/completion fence를 복구하고 authored count·cue duration·global active cap은 바꾸지 않음 |
| scheduler starvation이 1 이상 | nominal-order atomic queue를 수정; 실제 active-cap 부족인 `capacity_blocked`를 starvation으로 오분류하지 않음 |
| overlap steering이 non-overlap role velocity 또는 cover route를 바꿈 | non-overlap early return과 cover/committed priority를 복구하고 0.45 overlap weight 밖의 spacing logic을 제거 |
| observed `near_600/900`이 높음 | 허용된 수렴 결과로 기록하고 local cap·hold·despawn을 추가하지 않음; frame/physics 문제만 Phase 5에서 처리 |
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
| unit별 birth를 모두 cue해 marker가 과밀해짐 | logical squad별 first-unit cue만 표시해 visible cue를 4개로 제한 |
| active cap 때문에 cue와 spawn이 어긋남 | cue 전 first round 4 slot을 예약하고 뒤 round만 capacity-blocked로 지연 |
| separation이 swarm을 인위적으로 흩음 | body overlap일 때만 45%를 적용하고 non-overlap velocity identical test로 고정 |
| unit-level candidate가 authored anchor 수에 묶임 | immutable geometry-derived candidate pool을 사용하고 320px 아래 fallback 없이 window를 지연 |
| 구현 중 gameplay cap을 성능 해결 수단으로 낮춤 | current 1/124/172/224/276과 276/320 stress fixtures를 exact-value gate로 유지 |
| wear occupancy가 actor retire 뒤 남음 | occupancy/cooldown은 stage-local로 reset하고 `state/wear`만 persistent dictionary에 유지 |
| enclosure가 bulkhead를 우회할 수 있음 | closed/open movement graph와 LOS/projectile blocker를 같은 rect set으로 검증 |
| bulkhead reward가 reward 총량을 늘림 | stage마다 기존 8개 crate 중 두 개를 relocate하고 총량 validator 유지 |
| threat tier가 pooled projectile에 잔류 | configure/reset/reuse generation fixture |
| 기능 추가가 capacity를 악화 | Phase 1~4 완료 뒤 fresh 성능 baseline과 release gate |

## Progress

- [x] 최근 3일 root/continuation 세션에서 비디자인 issue 전수 추출.
- [x] current code, product spec, Git history와 focused validator로 상태 재판정.
- [x] 해결·asset/UI·deferred·미해결 범위 분리.
- [x] Phase 2 final consistency audit: unit-level birth, cue reservation, 320px hard
  floor, unrestricted role convergence와 observational density 계약 보정.
- [x] Phase 1: engine cue와 secondary 방향.
- [x] Phase 2: ordinary enemy pace, sparse unit birth, role convergence, overlap-only steering.
- [x] Phase 3: destructible terrain.
- [x] Phase 4: threat tier data.
- [ ] Phase 5: performance/release.
- [ ] Phase 6: asset/UI switch gate.

## Next Steps

1. native code/dependency, workload 또는 threshold 변경 중 어떤 범위를 허용할지
   사용자 결정을 받는다. 현재 GDScript owner 경계만으로는 capacity 6/8ms를
   충족하지 못했다.
2. 승인된 범위에서 native `capacity_pressure`부터 다시 통과시킨다.
3. 그 뒤에만 나머지 native/Web matrix, 600초 lifecycle과 built-Web smoke를
   실행하고 asset/UI switch gate를 연다.

## Completion Criteria

- [x] dash 전용 thrust, secondary 방향·mine rear placement가 모든 fixture에서 정확하다.
- [x] ordinary `1.40`, 12 logical squads의 unit-level sparse birth, 3 timing
  windows의 max-four first-unit cue/atomic tail, role convergence와 overlap-only
  separation이 focused/production fixture에서 검증된다.
- [x] current global active caps는 유지되고 `near_600/900`은 상한 없는 관측값으로만
  남으며 local admission/hold/lateral steering 경로가 없다.
- [x] boss/pattern/projectile 속도, authored count/quota/role multiset이 변하지 않는다.
- [x] bulkhead reward flow와 wear/collapse tile의 player/ordinary/boss damage 및
  state/wear stage persistence 계약이 통과한다.
- [x] ordinary/elite/boss threat tier가 telegraph와 projectile에 보존된다.
- [ ] native/Web/capacity/lifecycle 성능 gate가 모두 통과한다.
- [ ] resolved issue regression, import, Web export와 built-Web smoke가 통과한다.
- [x] 새 asset/UI 외관 작업이 이 plan diff에 섞이지 않는다.

## Open Questions

없음. 이 계획의 구현에 필요한 speed, birth distance/timing, global active cap,
overlap resolution과 wear 수치는 모두 고정했다. 새 visual, map 생성, enemy roster/role
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
- 2026-08-02: 외부 game-developer 사례, minimum-distance sampling과 steering/crowd
  연구를 현재 runtime에 좁게 적용했다. sampling은 birth에만, separation은 실제
  overlap에만, combat budget은 current global active admission에만 사용한다.
- 2026-08-02: cue 충돌과 32-anchor 한계를 확인해 1.20초 max-four cue reservation,
  geometry-derived unit candidate pool, hard 320px tier와 packet fence로 교정했다.
- 2026-08-02: 사용자 최종 확인에 따라 600/900px local admission과 lateral hold,
  active-cap 축소안을 폐기했다. 외곽 unit-level sparse birth 뒤 role steering으로
  player에게 수렴하고 근접 고밀도를 허용하는 것을 Phase 2 acceptance로 고정했다.
- 2026-08-02: commits `6d9d6c2`, `5aceddf`, `0f5eb6e`로 Phase 2~3과 정해진
  GDScript 성능 owner 개선을 구현했다. 전체 56개 vehicle validator, document
  authority, Godot import와 production Web export는 통과했다.
- 2026-08-02: clean `0f5eb6e` capacity 3회는 모두 focused/valid였으나 physics
  p95/p99 `19.22~20.77/23.86~26.40 ms`로 `6/8 ms` gate를 통과하지 못했다.
  actor/projectile 수, 해상도와 threshold를 유지한 채 남은 격차를 닫으려면
  이 계획 밖의 native/dependency work 또는 명시적 workload/threshold 결정이
  필요하므로 Phase 5~6을 완료 처리하지 않는다.

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
