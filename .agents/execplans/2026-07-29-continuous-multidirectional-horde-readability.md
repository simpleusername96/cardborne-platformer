---
type: plan
status: superseded
owner: BK
created: 2026-07-29
last_reviewed: 2026-07-29
scope: Multiply ordinary enemy presence by two to three, distribute arrivals across the field, bound ranged pressure, improve combat-object readability and item presence, and remove the Stage 1-4 report interruption without slowing the ship
superseded_by: ./2026-07-29-horde-foundation-recovery-and-acceptance.md
supersedes:
  - ./2026-07-28-stage-1-horde-front-gameplay-density.md
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/product/combat-growth-improvement-direction.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../vehicle-performance-stabilization-evidence.md
  - ../continuous-horde-readability-evidence.md
---

# 다방향 대규모 적군·가독성·연속 스테이지 실행 계획

## Why / Context

현재 구현은 Hard 후반 beat에서 일반 이동 적을 최대 92대만 활성화한다. Stage 1의
첫 surge는 그중 27대를 두 개의 `horde_front`에 집중시키지만, 이는 사용자가 요구한
“적 자체를 2~3배 늘리고 맵 전반에서 골고루 접근하게 한다”는 방향과 반대다. 또한
한 physics tick에 due spawn을 한 대만 꺼내므로 큰 packet을 예약해도 전장을 빠르게
채우지 못한다.

스테이지 전환도 연속된 런처럼 보이지 않는다. 보스 처치 뒤 XP recall과 보상 처리가
끝나면 `Stage Report` 모달이 HUD를 숨기고 입력을 끊는다. 계속을 누른 뒤에는
`_reset_run()`이 플레이어를 중앙으로 옮기고, 체력·쿨다운·적·투사체·아이템·상자와
stage tactical layout을 다시 초기화한다.

현재 시각 기준은 플레이어 반경 42, ordinary enemy 반경 36, pickup plinth 반경 34이며
XP shard는 반경 9/12/17이다. 적대 투사체 충돌 반경은 5/6/7이고, 현행 시각 계약은
투사체의 밝은 head가 그 충돌 반경에서 끝나도록 고정한다. 1280×720에서 많은 작은
요소가 같은 화면에 겹치면 플레이어·적·아이템·적탄의 우선순위가 약해진다.

이 계획은 위 문제를 수치 조정 몇 개로 가장하지 않는다. 동시 활성 수, 전장 점유,
원거리 공격 권한, actor/render capacity, 시각 footprint, field item 수, 성공한
스테이지의 전환 상태를 하나의 검증 가능한 계약으로 바꾼다.

`combat-growth-improvement-direction.md`의 “cap을 먼저 올리지 않는다”와 “2~3개
front로 집중한다”는 초안 제안은 이 범위에서 최신 사용자 결정에 의해 대체된다.
카드·지형 기폭·보스 고유화 등 그 문서의 다른 제안은 이 계획이 승인하거나
구현하지 않는다.

## Purpose

사용자가 확정한 피드백을 해석 여지가 없는 구현 단위로 고정하고, 여러 subsystem을
건드리는 작업이 적 수·기체 속도·가시성·스테이지 흐름 중 하나를 조용히 희생하지
못하게 한다. 구현자는 이 문서만으로 순서, 소유 경계, 목표 수치, 검증 방법과 실패
처리를 알 수 있어야 한다.

## Outcome

Hard 기준 첫 본 전투부터 현재의 두 배, 후반에는 세 배에 가까운 일반 적이 실제로
활성화된다. 적은 한쪽 벽이나 두 전선에 몰려 생성되지 않고 플레이어를 기준으로
네 사분면의 유효한 맵 anchor에서 local pack을 이루어 접근한다. 많은 적이 존재해도
실제 적탄 발사자와 denial commit 수는 현행 상한을 유지한다.

플레이어 기체의 기본 속도 `280 px/s`, 카메라 zoom `1`, 적 이동 속도, 적 체력,
개별 공격 피해는 이 작업에서 바꾸지 않는다. 난이도의 주된 변화는 “더 많은 몸체를
더 넓은 방향에서 처리해야 한다”는 데서 온다.

보스 처치 뒤에는 XP가 전부 회수되고 필수 보상 선택을 마친 즉시 비모달 stage
transition이 시작된다. 체력은 완전히 회복되지만 플레이어의 위치·방향·빌드·탐색
상태는 유지된다. Stage 1~4에는 성공 report 모달이 끼어들지 않고, 다음 stage의
arrival cue와 적군이 transition banner가 보이는 동안 이미 시작된다.

## Scope

### In scope

- authored mobile population과 beat별 active cap의 2~3배 확대;
- enemy store와 retained renderer의 live-hostile capacity 확대;
- 모든 본 전투 packet의 four-quadrant, multi-sector pack allocation;
- 같은 방향에서 연속 보충되는 것을 막는 sector occupancy 규칙;
- ranged/denial 적 비중과 실제 attack commitment의 비례 증가 방지;
- due spawn을 bounded burst로 처리하고 target occupancy를 유지하는 scheduler;
- 플레이어·적·보스·아이템·XP·투사체의 visual footprint와 salience 조정;
- 충돌 크기를 바꾸지 않는 적탄 core + non-damaging halo/trail 계약;
- stage당 field item 수 확대와 회복 총량 보존;
- Stage 1~4 성공 report 제거, XP recall·full heal·비모달 transition·즉시 다음
  encounter 시작;
- 한 run에서 cover geometry와 탐색 상태를 유지하는 field-layout 계약;
- 구조·통합·rendered·performance 검증과 canonical spec 갱신.

### Out of scope

- 플레이어 기체 감속, 카메라 zoom 변경, viewport 축소;
- 적 이동 속도, 적 체력, 개별 피해, telegraph 시간, projectile 속도 상향;
- stage quota 증가와 그로 인한 의도적인 플레이 시간 연장;
- 카드 카탈로그·제약 랜덤·XP curve·무기·스킬·보스 패턴·boss reward 재설계;
- 새 적 archetype, 새 pickup 종류, 새 화폐, meta progression;
- terrain 파괴·환경 연쇄 처치·optional field boss 구현;
- 맵 또는 전체 UI의 미술 방향 재설계;
- 진행 중인 Space Hangar UI asset/evidence/recipe 파일 수정;
- 엔진·언어·production dependency·save schema 변경.

## User Feedback → Locked Contract

| 사용자 피드백 | 구현 계약 | 금지되는 오해 |
| --- | --- | --- |
| 적 수를 2~3배 늘린다 | Hard active cap을 `1/124/172/224/276`, authored population을 stage별 `520/660/816/1026/1260`으로 바꾼다. | 기존 27대를 재배치한 뒤 “더 많아졌다”고 표현하지 않는다. |
| 맵 전반에 골고루 spawn한다 | 본 전투 surge마다 8 sector 중 최소 4개, 네 사분면을 모두 점유한다. | 화면 밖 임의 위치에 균일 난수를 뿌리거나 한쪽 wedge에 집중하지 않는다. |
| 원거리 적은 덜 늘린다 | projectile-firing mobile share를 최대 15%로 제한하고 ranged/denial commit 상한은 현행을 유지한다. | 전체 적 수와 적탄 수를 같은 배율로 키우지 않는다. |
| 탄환과 적 가시성을 높인다 | 적탄 visual envelope를 1.5배, 주요 actor/item footprint를 약 20~30% 키우고 outline·shape·audio를 함께 사용한다. | collision hitbox를 몰래 키우거나 채도만 일괄 상승시키지 않는다. |
| 기체·적·아이템 등 전반적인 크기를 검토한다 | 아래의 고정 visual scale 표를 적용하고 physics radius는 보존한다. | gameplay collision과 art scale을 한 상수로 묶지 않는다. |
| stage가 끊기지 않게 한다 | Stage 1~4 성공 report를 제거하고 같은 위치에서 transition과 다음 encounter를 시작한다. | 중앙 teleport, deployment 재진입, 별도 continue 입력을 남기지 않는다. |
| XP 흡수와 체력 회복은 유지한다 | 모든 live XP shard를 0.65초 안에 recall하고 reward 종료 시 hull을 full heal한다. | XP를 삭제하거나 회복을 다음 stage pickup으로 대체하지 않는다. |
| 다음 stage UI를 보여 준다 | HUD 위 비모달 1.6초 banner를 한국어·영어로 표시한다. | 화면 전체 모달, 카메라 zoom, 입력 차단으로 stage를 다시 끊지 않는다. |
| 아이템을 더 자주 보이게 한다 | stage당 6 loose pickups + 8 crates를 배치하되 총 회복량은 현행과 같게 나눈다. | 회복 총량까지 무제한으로 늘려 밀도 난이도를 상쇄하지 않는다. |
| 기체는 느리게 하지 않는다 | `PLAYER_BASE_SPEED = 280.0`, speed upgrade, dash와 카메라 계약을 그대로 둔다. | 성능·멀미·난이도를 이유로 감속하지 않는다. |

## Assumptions and Existing Truth

- Godot 4.7 stable, GDScript, Compatibility renderer, logical 1280×720과 Web
  export가 유지된다.
- 세 등록 field는 7200×4320이며 카메라 zoom은 1이다.
- 현재 Hard active-cap curve는 beat 기준 `1/62/78/88/92`이고 stage별 값이
  아니다.
- 현재 authored mobile population은 stage별 `260/300/340/380/420`이며
  quota는 `125/166/208/250/291`이다.
- actor store와 renderer는 128 live enemies, player projectile 240,
  hostile projectile 120, XP shard 192를 preallocate한다.
- hostile projectile 120 중 24는 boss용 reserve다.
- 현행 ranged commit은 early 2/late 3, denial commit은 early 1/late 2다.
- 각 stage는 3 loose pickups와 5 crates를 배치한다. pickup 종류는
  `repair`와 `experience_recall`만 허용한다.
- current UI session의 변경은 별도 소유다. 구현 시작 시 그 세션의 commit을
  기준으로 re-inspect하되 이 계획을 이유로 해당 asset/evidence를 되돌리거나
  재생성하지 않는다.

## Proposed Design

### D1. Enemy quantity means live pressure, not only a larger queue

Hard beat별 target은 다음과 같다.

| Beat | Current Hard active cap | Target Hard active cap | Ratio |
| ---: | ---: | ---: | ---: |
| 0 | 1 | 1 | tutorial scout 보존 |
| 1 | 62 | 124 | 2.00× |
| 2 | 78 | 172 | 2.21× |
| 3 | 88 | 224 | 2.55× |
| 4 | 92 | 276 | 3.00× |

기존 difficulty factor를 같은 방식으로 적용한 curve는 다음과 같다.

| Difficulty | Beat 1 | Beat 2 | Beat 3 | Beat 4 |
| --- | ---: | ---: | ---: | ---: |
| Easy | 110 | 152 | 198 | 244 |
| Normal | 117 | 162 | 211 | 259 |
| Hard | 124 | 172 | 224 | 276 |

Stage authored mobile population은 `520/660/816/1026/1260`으로 바꾼다. 이는
stage 1에서 2.0×로 시작해 stage 5에서 3.0×가 되는 scheduler headroom이다.
quota와 difficulty quota scaling은 이번 작업에서 유지한다. 더 많은 적을
보여 주는 목표를 더 긴 grind로 바꾸지 않기 위해서다.

`VehicleEnemyStore.MAX_LIVE_HOSTILES`와
`VehicleCombatRenderer.ENEMY_CAPACITY`는 320으로 올린다. peak ordinary 276,
stationary 4 이후에도 boss·pylon·summon·replacement용 40 slot을 남긴다.
모든 pool은 계속 fixed-capacity이며 combat 중 grow하지 않는다.

`VehicleEncounterRuntime`은 physics tick마다 due request 한 대만 꺼내는 대신
최대 네 대를 꺼낸다. 단, active cap, store capacity와 deterministic queue
order를 넘지 않는다. queue가 있고 boss/reward/transition 상태가 아닐 때
rolling active count가 cap의 90% 아래로 오래 머물지 않게 한다.

### D2. Four-quadrant multi-sector arrivals replace horde fronts

Stage 1의 `horde_front` production exception과 전용 allocation/cue path를
제거한다. 모든 post-scout ordinary packet은 `multi_sector` arrival policy를
사용한다.

한 surge는 다음 구조를 가진다.

- four quadrant packs;
- pack당 2~3 authored squads;
- squad당 4~8 units;
- pack 내부 squad는 같은 semantic arrival area를 공유하되 충돌 반경 기반의
  fan offset으로 겹치지 않는다;
- pack당 arrival cue 한 번, surge당 총 네 cue;
- cue는 해당 pack 첫 unit보다 최소 0.9초 먼저 보인다.

Allocator는 플레이어 기준 8개 45도 sector를 사용하고 다음을 모두 만족한다.

1. 한 surge는 최소 네 sector를 사용한다.
2. top-left, top-right, bottom-left, bottom-right 각 사분면에 한 pack이 있다.
3. 한 sector가 surge population의 35%를 넘지 않는다.
4. 인접 두 sector 합이 surge population의 55%를 넘지 않는다.
5. 같은 sector가 두 번 연속 largest pack이 되지 않는다.
6. anchor는 가능하면 플레이어로부터 900~2400px이고 visible rect + 220px
   밖에 있어야 한다.
7. valid anchor 부족 시 ring보다 offscreen safety를 먼저 보존하고, 마지막
   fallback도 네 사분면 중 아직 비어 있는 쪽을 우선한다.

“맵 전반”은 플레이어와 무관한 먼 지점에 적을 낭비한다는 뜻이 아니다. 전장 전체의
유효 anchor를 사용하되, 현재 교전으로 실제 합류할 수 있는 ring 안에서 네 방향을
점유한다. 이로써 화면에는 적이 적은데 맵 반대편 queue만 큰 상태를 피한다.

### D3. Body count grows; ranged lethality does not grow proportionally

Mobile packet composition은 다음 budget을 지킨다.

| Role family | Maximum / minimum share |
| --- | ---: |
| pursuit/fodder/contact | 최소 65% |
| direct projectile-firing | 최대 15% |
| denial/area control | 최대 8% |
| support/priority | 최대 12% |

Stationary threat는 stage당 네 개를 유지하고 적 수와 함께 늘리지 않는다. 실제 공격
권한은 현행 absolute cap을 유지한다.

- ranged commit: beat 1~3에서 2, beat 4에서 3;
- denial commit: beat 1~3에서 1, beat 4에서 2;
- hostile projectile pool: 120, boss reserve: 24;
- attack cadence, projectile speed, telegraph duration: 변경 없음.

화면에 보이는 몸체는 크게 늘지만 동시에 실제 피해를 확정하는 적은 제한된다.
commit을 얻은 원거리 적은 밝은 readiness marker와 고유 silhouette/audio cue를
사용하고, 대기 중인 원거리 적과 색만으로 구분하지 않는다.

### D4. Player and enemy movement are invariant

다음 값과 동작은 이 작업의 performance 또는 balance fallback으로 사용할 수 없다.

- `PLAYER_BASE_SPEED = 280.0`;
- dash 거리·시간·cooldown;
- speed card의 기존 적용 방식;
- camera zoom 1과 logical viewport;
- 모든 existing enemy archetype speed와 stage/difficulty speed multiplier.

대규모 적 때문에 performance gate가 실패하면 hot-path, batching, LOD cadence,
query reuse를 고친다. 적 수·기체 속도·렌더 해상도를 낮춰 통과 처리하지 않는다.

### D5. Increase visual footprint without changing collision truth

고정 visual target은 다음과 같다.

| Element | Current | Target | Collision |
| --- | ---: | ---: | --- |
| player visual radius | 42 | 50 | player radius 24 유지 |
| ordinary enemy presentation radius | 36 | 44 | archetype collision 유지 |
| installation presentation radius | 54 | 62 | archetype collision 유지 |
| stage boss presentation radius | 122 | 146 | boss collision 76 유지 |
| pickup plinth radius | 34 | 42 | pickup collection radius만 48→60 |
| XP small/medium/large radius | 9/12/17 | 12/16/22 | collection logic 유지 |
| hostile projectile visible envelope | collision radius ×3 asset footprint | collision radius ×4.5 | 5/6/7 유지 |
| player primary projectile asset footprint | current | 1.25× | projectile collision 유지 |

적탄은 중앙의 solid damage core가 정확한 5/6/7px collision 경계를 계속 보여 준다.
그 밖의 1.5배 확대분은 얇은 outline, direction tail 또는 halo이며 피해 판정이 없다.
`UI_VISUAL_SYSTEM.md`의 “head 끝 = collision 끝” 계약을 “solid core 끝 =
collision 끝”으로 명시적으로 바꾼다. 화면에 크게 보인다는 이유로 맞지 않은 탄에
피격됐다고 느끼지 않게 해야 한다.

색은 전역 saturation slider처럼 바꾸지 않는다.

- player/projectile, hostile projectile, ordinary body, priority body, pickup,
  background 순으로 salience tier를 둔다;
- hostile projectile는 affinity color 외에 공통 밝은 core와 어두운 keyline을
  가진다;
- priority enemy는 크기·outline·shape marker를 함께 사용한다;
- pickup은 plinth, 고유 icon, pulse, minimap marker와 짧은 spatial audio를
  함께 사용한다;
- color-only 구분을 금지하고 grayscale 및 deuteranopia/protanopia/tritanopia
  simulation capture로 확인한다;
- reduced motion에서는 pulse amplitude, flash와 shake를 줄이되 outline과
  static marker는 남긴다.

### D6. More field items, same total recovery budget

각 stage tactical content는 최소 14개의 유효 item socket을 선택한다.

- loose pickups 6개: recall 2, repair 4;
- crates 8개: recall 2, repair 6;
- 총 repair pickup 10개의 합산 회복량은 현행과 같은 stage당 245 hull이다;
- repair 9개는 25 hull, 나머지 1개는 20 hull로 나누어 “더 자주 보이지만
  한 번에 과회복하지 않는” 구조로 만든다;
- pickup 종류는 현행 두 종류만 사용한다;
- 네 개 이상의 field sector에 items를 분산하고, 한 sector에 전체의 30%를
  넘게 놓지 않는다;
- loose pickup과 unopened crate는 minimap에 shape-distinct marker로 보인다.

Stage transition에서 이전 stage의 XP shard만 자동 수확한다. 사용하지 않은 repair/
recall pickup은 transition 시작 시 정리하고 다음 stage tactical item set을 banner
동안 활성화한다. 보이지 않는 기존 pickup을 자동으로 소비하거나 회복으로 바꾸지
않는다.

### D7. One persistent combat field across five stages

Run layout은 macro field뿐 아니라 cover IDs도 한 번만 선택한다. 다섯 stage tactical
children은 같은 cover geometry를 공유하고 다음 content만 stage별로 바꾼다.

- stationary threat blueprint;
- item/crate sockets;
- support-field sockets와 schedule;
- ordinary/boss arrival choice와 encounter seed.

따라서 stage 전환 때 player를 중앙으로 teleport할 필요가 없고, 현재 위치 아래에
새 cover가 생기지 않는다. `visited_cells`, explored minimap과 persistent bulkhead
health는 계속 유지된다. stage-specific dynamic markers만 교체한다.

### D8. Successful stage flow becomes non-modal

Stage 1~4 성공 흐름은 다음 순서를 고정한다.

1. boss defeat를 기록하고 ordinary spawn을 정지한다.
2. live ordinary enemy와 hostile projectile/zone을 안전하게 정리한다.
3. 모든 live XP shard를 기존 0.65초 recall로 실제 획득 처리한다.
4. pending level-up과 필수 boss reward를 현행 규칙대로 끝낸다.
5. stage telemetry snapshot은 run history에 저장하되 Stage Report를 열지 않는다.
6. hull을 max로 회복하고 1.2초 transition invulnerability를 부여한다.
7. player position, aim/hull direction, build, run time, difficulty, explored map,
   persistent terrain state를 유지한다. carried movement velocity만 0으로 정리한다.
8. `RunMode.STAGE_TRANSITION`과 `VehicleStageFlow.State.TRANSITION`에 진입한다.
9. 1.6초 비모달 banner를 HUD 위에 띄운다. 입력과 HUD는 계속 살아 있다.
10. 0.35초에 네 방향 arrival cue를 시작하고 1.35초부터 다음 stage 적을 spawn한다.
11. 1.6초에 mode를 `PLAYING`으로 확정하되 이미 예약된 encounter는 끊지 않는다.

Stage 1의 최초 deployment와 tutorial scout cue 5.1초/spawn 6.0초는 유지한다.
Stage 2~5에서는 lone tutorial scout를 반복하지 않고 transition 중 첫 multi-sector
surge를 시작한다.

Stage 5 성공은 현행 final result로 간다. 실패 report와 Garage 흐름도 유지한다.
Stage 1~4에서 제거한 성공 report 데이터는 final result의 stage history 또는 debug
telemetry에서 확인할 수 있지만, 새 modal을 만들지 않는다.

### D9. Transition banner is a narrow UI integration

대형 `vehicle_stage_ui.gd`가 transition animation과 layout 책임까지 흡수하지 않도록
전용 `VehicleStageTransitionBanner` component가 text, timing, reduced-motion
presentation을 소유한다. `VehicleStageUI`는 show/update/hide 호출만 전달한다.

표시는 다음 두 줄만 사용한다.

- title: `스테이지 %d · %s` / `STAGE %d · %s`;
- status: `선체 회복 · 적 증원 접근` / `HULL RESTORED · HOSTILES INBOUND`.

960×540, 1280×720, 1920×1080에서 HUD objective, boss bar, minimap과 겹치지
않아야 한다. 한국어·영어 문자열은 같은 commit에서 추가한다. reduced motion에서는
slide/scale을 사용하지 않고 opacity 전환 또는 즉시 표시만 사용한다.

현재 진행 중인 Space Hangar UI 세션이 끝난 뒤 settled UI hierarchy를 다시 읽고
integration point만 맞춘다. 그 세션의 asset, candidate-validation, layout-proof
파일은 이 계획의 소유가 아니다.

## Ownership and File Boundaries

| Responsibility | Existing owner / planned boundary | Planned change |
| --- | --- | --- |
| quantities, packet roles, schedule | `scripts/vehicle/stages/vehicle_combat_stages.gd` | population, 12-squad multi-sector packets, Stage 2~5 transition timing |
| cap and attack authority | `scripts/encounters/vehicle_encounter_director.gd` | active curve; commit/projectile caps unchanged |
| due queue and occupancy metrics | `scripts/encounters/vehicle_encounter_runtime.gd` | four-per-tick bounded dequeue, occupancy snapshot |
| spatial allocation | `scripts/encounters/vehicle_spawn_allocator.gd` | replace horde front with four-quadrant allocator |
| actor capacity/lifecycle | `scripts/enemies/vehicle_enemy_store.gd` | fixed capacity 320 |
| rendered capacity and scale | `scripts/presentation/vehicle_combat_renderer.gd` | fixed capacity 320, visual footprint/halo |
| shared visual constants | `scripts/vehicle/vehicle_stage_visual_profile.gd` | target radii and validation |
| collision/danger truth | `scripts/combat/vehicle_attack_contract.gd` | collision unchanged; expose visual-core contract only if needed |
| field geometry and item sockets | `scripts/vehicle/vehicle_field_layout_generator.gd`, `vehicle_field_layout.gd`, `vehicle_stage_tactical_layout.gd` | shared cover set, 14 item sockets |
| stage state | `scripts/encounters/vehicle_stage_flow.gd` | explicit transition state |
| orchestration | `scripts/vehicle/vehicle_run.gd` | non-resetting stage handoff, heal, recall, content swap |
| transition presentation | new focused UI component + `scripts/ui/vehicle_stage_ui.gd` integration | non-modal banner only |
| localization | `localization/vehicle_stage.csv` | complete Korean/English keys |
| performance fixtures | `scripts/performance/vehicle_performance_scenario.gd`, recorder/validators | 280/320 actor loads and sector metrics |
| durable contract | `docs/product/vehicle_game_spec.md`, `docs/design/UI_VISUAL_SYSTEM.md` | accepted behavior and visual truth |

Card eligibility/application remains in progression owners. UI code must not select, reroll or
apply cards. Collision radii remain in gameplay owners; renderer scale must not become collision
truth.

## Progress

- 계획·현행 코드·기존 성능 근거·상충 문서 확인: 완료
- 사용자 피드백의 수치·흐름 계약화: 완료
- 기존 single-front 계획 lifecycle 정리: 완료
- concurrent UI 기준 commit: `8a0b003`
- concurrent UI 비소유 경로: `pixel-art-production/`, `docs/design/vehicle-hud-upgrade-direction/`,
  기존 Space Hangar asset/evidence/recipe
- production implementation: M1~M4 완료 (`a9ae769`~`9485560`)
- bounded performance optimization: `d87520b`; 280기 workload와 23 retained
  batch는 유효하지만 Intel Iris Xe 1280×720 short diagnostic은 약 42.28 FPS로
  locked frame gate 미달
- structural validation: `validate_vehicle_*.gd` 40개 통과
- production Web export: 성공
- canonical product/visual spec과 active evidence: 구현값으로 갱신
- 남은 acceptance: 실플레이 telemetry, 전체 rendered/accessibility matrix,
  clean native/Web performance matrix와 10분 lifecycle soak

## Tasks

### M0 — Authority and conflict cleanup

- [x] Read root and `.agents` guidance, ExecPlan standard, current product/visual specs,
  current runtime owners and performance evidence.
- [x] Translate the latest feedback into fixed numeric and flow contracts.
- [x] Mark the single-front Stage 1 plan as superseded without deleting history.
- [x] At implementation start, record the settled concurrent UI commit and exact non-owned
  paths.

### M1 — Capacity and observability first

- [x] Raise enemy store and retained renderer capacity to 320.
- [x] Update status/health-overlay retained capacities from the shared enemy capacity.
- [x] Add explicit pool rejection counters; any rejection before declared cap fails validation.
- [x] Extend encounter/performance snapshots with active, visible, near-600, near-900,
  eight-sector histogram, ranged/denial commits and hostile projectile count.
- [x] Change `current_pressure` to 280 actors and `capacity_pressure`/
  `lifecycle_pressure` to 320 actors.
- [x] Pass store, renderer, lifecycle and performance-scenario structural validators before
  increasing production data.

### M2 — Quantity, composition and multi-sector spawning

- [x] Replace active caps with `1/124/172/224/276`.
- [x] Replace authored populations with `520/660/816/1026/1260`; preserve quotas.
- [x] Rebuild post-scout packets as four packs, 2~3 squads per pack, 4~8 units per squad.
- [x] Enforce the 65/15/8/12 composition budget deterministically per stage.
- [x] Remove Stage 1 production `horde_front` metadata and dedicated allocator/runtime path.
- [x] Add deterministic four-quadrant allocation, recent-sector memory and fairness fallback.
- [x] Coalesce cues to one per pack and preserve at least 0.9-second cue lead.
- [x] Dequeue at most four due spawns per physics tick until active occupancy reaches target.
- [x] Verify Stage 2~5 first surge can begin during transition without repeating the tutorial
  scout.

### M3 — Readability and item presence

- [x] Apply the locked actor, pickup, XP and projectile visual targets without collision drift.
- [x] Render hostile projectile solid collision core plus non-damaging halo/tail.
- [x] Add shape/outline/readiness treatment for committed ranged and priority enemies.
- [x] Increase pickup collection radius to 60 and keep it independent from plinth art.
- [x] Generate six loose pickups and eight crates across at least four field sectors.
- [x] Split repair value into nine 25-hull events and one 20-hull event; keep two loose and
  two crate recalls.
- [x] Update minimap marker shapes/sizes without increasing radar update rate.
- [x] Update visual-system source-of-truth and renderer validators.

### M4 — Persistent field and seamless transition

- [x] Make one cover selection shared by all five tactical children.
- [x] Preserve player position, facing, build, difficulty, map exploration and terrain state.
- [x] Add `TRANSITION` to stage-flow and run-mode state machines.
- [x] Keep XP recall, mandatory reward resolution and full heal in that order.
- [x] Stop opening Stage 1~4 success reports; retain telemetry, Stage 5 result and failure report.
- [x] Refresh only dynamic stage content and item sets.
- [x] Add the focused transition banner component and complete Korean/English copy.
- [x] Start next-stage cues at 0.35 seconds and spawn at 1.35 seconds without continue input.

### M5 — Integrated evidence and canonicalization

- [x] Update focused validators and retire horde-front-only assertions.
- [x] Add a complete Stage 1→2→3 transition validator covering position, heal, XP, build,
  difficulty, exploration, item refresh and no success modal.
- [ ] Run fixed-seed gameplay telemetry for Stage 1, Stage 3 and Stage 5 on all difficulties.
- [ ] Capture maximum-pressure gameplay and transition states at all supported viewports,
  languages and motion modes.
- [ ] Run grayscale and three color-vision simulations; verify critical elements remain
  distinguishable by shape/outline.
- [ ] Build production Web export and run the full native/Web performance gate.
- [x] Update `vehicle_game_spec.md` and `UI_VISUAL_SYSTEM.md` only after implementation and
  evidence agree.
- [x] Run task-scoped quality audit, diff check and commit only owned files.

## Test Plan

### Structural and deterministic validation

Add or update focused Godot validators to prove:

- Hard/Normal/Easy cap curves equal the table above;
- authored population and quota arrays equal their locked values;
- every post-scout production packet uses `multi_sector`;
- every surge occupies four quadrants and at least four of eight sectors;
- sector population limits, offscreen preference, cue lead and deterministic fallback hold
  across all fields and a bounded seed matrix;
- projectile-firing share never exceeds 15%, denial 8%, support/priority 12%;
- ranged/denial commit and projectile caps remain unchanged;
- the store accepts exactly 320 live actors and rejects actor 321 observably;
- renderer retained capacities match the store and hide unused instances;
- visual radii change while collision radii remain unchanged;
- every stage layout has 6 pickups, 8 crates, 4+ occupied item sectors and 245 total repair;
- all five tactical children share cover IDs while stage content stays deterministic;
- Stage 1~4 success never opens report, never teleports the player and starts the next encounter
  automatically;
- Stage 5 result and failure report still open;
- Korean and English contain identical transition keys.

Run at minimum:

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_enemy_store.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_encounter_pacing.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_spawn_allocation.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_field_layout_generation.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_combat_renderer.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_experience.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_rewards_ui_audio.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_report.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_ui_layout.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_performance_scenarios.gd
```

Replace `validate_vehicle_horde_fronts.gd` with a purpose-named multi-sector validator after
all production consumers of `horde_front` are removed.

### Gameplay acceptance

Fixed-seed Stage 1/3/5 Hard captures must show:

- active ordinary count reaches at least 90% of the current beat cap within five seconds while
  the queue has due enemies;
- after the initial fill, rolling five-second occupancy does not fall below 75% of cap for more
  than two consecutive windows unless boss/reward/transition is active;
- visible and near-900 enemy median is at least 2.0× the pre-change baseline in Stage 1,
  2.4× in Stage 3 and 2.8× in Stage 5;
- no five-second spawn window is supplied from fewer than four sectors;
- ranged commits never exceed 3, denial commits never exceed 2 and ordinary hostile shots
  never consume the 24-slot boss reserve;
- player base movement remains 280px/s and camera zoom remains 1;
- no collision hit occurs outside the displayed projectile solid core;
- player, committed hostile projectile, priority enemy and pickup are locatable at maximum
  pressure without relying on color alone;
- Stage 1→2 transition requires no button, keeps position/build/map state, heals to full, recalls
  all XP and starts the next hostile arrival within 1.35 seconds.

Normal and Easy must preserve the same logic with their scaled caps. They are not allowed to
change reward quality, projectile speed or transition behavior.

### Rendered UI and accessibility evidence

Capture Korean and English at 960×540, 1280×720 and 1920×1080:

- maximum ordinary pressure;
- active hostile projectiles over a busy background;
- pickup/crate field and minimap markers;
- Stage 1→2 transition with HUD visible;
- reduced-motion transition;
- Stage 5 result and failure report.

Reject if the banner clips, blocks the crosshair/objective, hides HUD controls, or persists into
boss/upgrade modals. Reject if grayscale or color-vision simulation removes the distinction
between player fire, hostile fire, pickups and background.

### Performance gate

Use the existing authoritative thresholds without relaxing them:

- native 1280×720: median ≥59 FPS, 1% low ≥55 FPS, frame p95 ≤18ms, p99 ≤25ms;
- native 2560×1600: median ≥58 FPS, 1% low ≥50 FPS, p95 ≤20ms, p99 ≤33.3ms;
- production Web 1280×720: median ≥58 FPS, 1% low ≥50 FPS, p95 ≤20ms,
  p99 ≤33.3ms;
- capacity simulation p95 ≤6ms and p99 ≤8ms;
- draw calls p95 ≤200, retained combat batches ≤50;
- lifecycle soak: 10 minutes, static-memory growth <8MiB, no stale ID or cap growth.

Warm up 10 seconds, measure 60 seconds and run three authoritative samples per
platform/resolution from the same clean commit. The 10-minute lifecycle sample remains separate.
All three runs must pass; do not discard the slowest result.

If a gate fails, inspect the measured dominant subsystem and optimize within the existing
data-oriented owners. Do not lower the 320 capacity, 276 peak cap, actor visual target, physics
rate, player speed or rendering resolution to manufacture a pass.

## Rollback and Safety

- Implement capacity/metrics before production population so pool exhaustion is explicit rather
  than silent.
- Keep quantity/allocation, readability/items and transition as coherent commits so a regression
  can be bisected without reverting unrelated UI work.
- Do not stage or amend concurrent Space Hangar UI asset/evidence changes.
- No save migration or dependency installation is required.
- If a stage transition state corrupts progression, revert only M4 and temporarily retain the
  old report flow; do not revert M1~M3 or unrelated UI commits.
- If performance remains below the locked gate after bounded task-scoped optimization, stop and
  report the failing metrics. Do not ship a hidden lower-density fallback.

## Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| 276 bodies physically trap the player | keep actor collision truth unchanged, validate pursuit spacing and four-direction approach, preserve dash and 280px/s movement |
| four directions feel like unfair surround | offscreen cue ≥0.9s, absolute attack-token caps, readiness markers and spawn safety ring |
| larger sprites imply larger hitboxes | retain exact collision core/outline contract and automated geometry assertions |
| extra pickups erase difficulty | split the existing recovery envelope into more, smaller items rather than increasing total repair |
| stage content pops under the player | share cover geometry for the run; swap only dynamic content during invulnerable banner |
| actor-cap increase breaks Web performance | expand fixed buffers, measure 280/320 scenarios, optimize measured hot owners; no density downgrade |
| transition UI conflicts with concurrent redesign | wait for the settled UI commit, use a focused component, touch no asset/evidence recipes |
| old documents send agents back to horde fronts | this active plan supersedes the old active plan and explicitly overrides the conflicting draft sections |

## Open Questions

There are no blocking product or technology decisions in this plan. Damage, HP, quota,
projectile speed, card logic, boss design and terrain-processing ideas remain intentionally
outside this implementation. Any later change to those requires separate evidence and authority.

Fine tuning may move pack-internal spacing or visual halo opacity only within the locked
contracts. It may not change the 2~3× cap curve, four-quadrant rule, absolute ranged/denial
commit caps, player speed, no-report transition, item count or recovery envelope without a new
user decision.

## Next Steps

1. 사용자가 이 계획의 확정 피드백 범위를 승인하면 M1부터 순서대로 구현한다.
2. 구현 시작 직전에 concurrent UI session의 settled commit과 task-owned path를
   기록한다.
3. M1~M5의 검증을 통과한 뒤에만 active product/visual spec을 갱신하고 사용자
   플레이 확인을 요청한다.

## Decision Notes

- 2026-07-29: User rejected slowing the ship and clarified that speed is a positive unless it
  causes actual discomfort. Player speed and camera are now explicit invariants.
- 2026-07-29: User selected an actual 2~3× enemy increase rather than another same-count
  concentration experiment.
- 2026-07-29: User rejected one-sided arrivals and requested broad, multi-direction field
  coverage. The Stage 1 horde-front exception is therefore retired.
- 2026-07-29: Ranged enemies must scale much less than body count. Absolute attack commitment
  and projectile capacity remain bounded.
- 2026-07-29: XP recall and full heal are accepted transition benefits; the Stage 1~4 report
  interruption and center reset are not.
- 2026-07-29: The plan documents only the accepted feedback. Boss, terrain, growth and other
  researched improvements are advisory until separately approved.
