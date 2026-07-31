---
type: plan
status: draft
owner: BK
created: 2026-07-31
scope: Cardborne visual assets, image-backed UI, attack readability, and world presentation
related:
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../docs/product/vehicle_game_spec.md
  - ../visual-redesign-decision-catalog.md
  - ../semantic-v2-runtime-acceptance-evidence.md
---

# Cardborne 승인 기반 비주얼 에셋 교체 계획

현재 semantic-v2의 실제 사용 에셋과 절차 생성 표현을 한 기준으로 고정한
뒤, 작은 가족 단위로 새 이미지를 생성·승인하고, 모든 필수 승인이 끝난
후에만 런타임 교체와 추가 수정에 들어가는 8단계 계획이다.

## Purpose

- 목표: 기체, 보조무기, 적, 보스, 탄환, 아이템, 효과, 맵, 벽,
  지형지물, HUD와 UI 패널을 승인된 일반 SF 문법으로 일관되게 교체한다.
- 최종 산출물: 승인된 개별 PNG/atlas/9-slice 묶음, 갱신된 manifest와
  provider, 실제 런타임 비교 캡처, 마지막 성능 검증 결과.
- 완료 상태: 모든 승인 행이 `approved`이고, 교체 후 한국어·영어 및
  지원 해상도 검증과 최종 성능 검증이 통과한 상태.
- 현재 상태: `draft`. 사용자 승인 전에는 런타임 코드, manifest,
  밸런스, 맵 생성기를 수정하지 않는다.

## Why / Context

현재 비주얼 교체는 파일 수와 런타임 연결 수는 많지만, 승인 마스터보다
과도하게 세밀하고 가족 간 형태 문법이 흔들린다. 맵 바닥과 벽 PNG는
존재하지만 런타임에서 사용되지 않고, 지형지물은 이미지와 절차 도형이
혼합되어 실제 영향 범위와 시각적 덩어리가 다르게 느껴진다. 공격 표시도
정확한 충돌 형상을 사용하지만, 작은 탄두와 얇은 선 위주라 전투 압력
속에서 방향과 위험 등급이 충분히 읽히지 않는다.

이번 계획은 에셋을 먼저 대량 적용하는 방식이 아니라 다음 순서를
강제한다.

1. 현재 상태를 정확히 한 장과 파일 목록으로 고정한다.
2. 한 이미지에 최대 4개의 관련 항목만 넣어 후보를 만든다.
3. 사용자가 각 가족을 승인하거나 수정 지시한다.
4. 모든 필수 가족이 승인된 뒤에만 production cutout과 런타임 교체를
   시작한다.
5. 성능 검증은 모든 에셋과 UI 교체가 끝난 마지막 단계에만 수행한다.

## Pre-plan Evidence Already Verified

| 근거 | 확인된 사실 | 계획에 미치는 영향 |
| --- | --- | --- |
| `art/gameplay/semantic-v2/asset-manifest.json` | 게임플레이 런타임 PNG 239개, 바닥·벽 미연결 PNG 8개 | 파일 존재와 런타임 사용을 분리해서 승인한다. |
| `art/ui/production/semantic-v2/ui-asset-manifest.json` | UI는 13개 component, 57개 image state를 사용한다. | 패널 이미지는 유지하되 텍스트·아이콘은 동적 child로 둔다. |
| `scripts/presentation/components/vehicle_semantic_asset_provider.gd` | `world_shared_floor_*`, `world_wall_*`를 명시적으로 제외한다. | 승인 전에는 이 제외 규칙을 바꾸지 않는다. |
| `scripts/presentation/vehicle_field_surface_pattern_compiler.gd` | 바닥은 288-unit 결정론적 vertex-color module이다. | 이미지 타일과 알고리즘을 따로 승인한 뒤 compiler를 교체한다. |
| `scripts/presentation/vehicle_world_mesh_builder.gd` | 벽·cover는 UV 없는 retained mesh이며 collision을 소유하지 않는다. | 새 벽 이미지는 기존 geometry/collision truth를 소비해야 한다. |
| `scripts/vehicle/vehicle_terrain_runtime.gd` | Arc rect, gate 96, repair 150, overdrive 180 등 실제 범위를 소유한다. | 지형지물 이미지는 이 rect/radius에 맞춰야 하며 새 collider를 만들지 않는다. |
| `scripts/presentation/vehicle_combat_renderer.gd` | 공격 범위는 live geometry지만 작은 탄두·trail과 공용 cue가 주 표현이다. | 피해 범위는 유지하고 탄두, 방향, 등급 문법을 강화한다. |
| `scripts/ui/vehicle_upgrade_choice_card.gd` | 현재 카드는 작은 header glyph 중심이며 상단 1/3 이미지 구성이 아니다. | 카드 구조를 상단 art, 이름·레벨, 설명 순으로 바꾼다. |
| `docs/design/component-sheets/00-general-sf-component-master-v1.png` | 단순한 큰 실루엣, 평면 색, 역할별 negative space가 승인 기준이다. | 신규 후보의 binding style reference다. |
| `.agents/semantic-v2-runtime-acceptance-evidence.md` | 이전 비주얼 검증은 통과했지만 peak/capacity 성능은 미완료다. | 과거 통과를 새 디자인 승인으로 간주하지 않고, 성능은 마지막에 재검증한다. |

## Locked Decisions

| 주제 | 고정 결정 |
| --- | --- |
| 장르 | 익숙한 industrial/general SF. 특정 문화·재질·해양·의례 테마를 도입하지 않는다. |
| 형태 | 큰 실루엣과 negative space를 우선하고, 색은 역할 구분의 보조 수단으로 쓴다. |
| 화풍 | pixel 제약을 두지 않는다. antialiased hard edge와 3–5개 filled plane을 사용한다. |
| 외곽선 | 이동 개체와 전투 핵심에는 authored near-black contour를 사용한다. 군집에서는 내부선보다 바깥 실루엣을 우선한다. |
| 이미지 밀도 | 후보 한 장에 최대 4개 asset identity만 배치한다. 애니메이션 한 종류의 keyframe은 한 identity로 센다. |
| UI 합성 | 패널/frame/background는 이미지, 텍스트·아이콘·수치·focus는 그 위의 Godot Control이 소유한다. |
| 업그레이드 카드 | 상단 약 1/3은 family art, 그 아래 이름+레벨, 그 아래 설명/효과다. scroll이나 잘림으로 overflow를 숨기지 않는다. |
| XP | 값은 크기와 단순 면 수로 구분하는 기본 도형형 shard로 단순화한다. 복잡한 기계 부품 이미지는 사용하지 않는다. |
| 공격 표시 | 실제 피해 geometry는 유지한다. ordinary/elite/boss는 탄두 실루엣, tail pattern, startup cap 중 2개 이상이 다르다. 얇은 선 하나만으로 위험을 표시하지 않는다. |
| 기체 부착물 | engine은 hull의 rigid child다. orbiting secondary는 기체 중심에서 바깥으로 향한다. |
| 맵 | 현실적으로 납득 가능한 단순 panel tile, 명확히 솟은 벽, 기능성 지형지물의 3계층으로 구성한다. 무효 장식 문양은 넣지 않는다. |
| 충돌 소유권 | visual geometry는 기존 stage/terrain/combat collision truth를 소비하며 새 collision owner가 되지 않는다. |
| 적용 게이트 | 모든 필수 승인 후 사용자의 명시적 실행 지시가 있어야 런타임 교체를 시작한다. |
| 성능 순서 | 모든 asset과 UI 교체 및 기능 검증이 끝난 뒤 마지막에만 성능 검증을 한다. |

## Rejected Alternatives

| 대안 | 제외 이유 |
| --- | --- |
| 현재 semantic-v2 이미지를 그대로 미세 수정 | 승인 마스터와의 전체 형태 언어 차이를 해소하지 못한다. |
| 모든 에셋을 한 거대한 생성 이미지에서 제작 | 개별 품질, 방향, pivot, alpha edge와 형태 일관성을 검수하기 어렵다. |
| UI 텍스트와 아이콘을 패널 이미지에 굽기 | 한국어·영어, 레벨, 수치, focus와 접근성 상태를 유지할 수 없다. |
| 맵 이미지를 바로 provider에 연결 | 타일 알고리즘, 벽 topology, collision parity가 승인되지 않은 상태에서 구조 변경이 일어난다. |
| 공격 표시를 더 굵은 선만으로 해결 | 탄환·빔·돌진·범위 공격과 적 등급을 동시에 구분할 수 없다. |
| 성능을 위해 적 수·탄환 수·해상도·품질을 낮추기 | 제품 구성 자체를 바꾸며, 사용자가 요구한 근본 원인 검증을 회피한다. |

## Current State

이미 완료:

- 현재 에셋 11개 review sheet를 재해석 없이 한 장으로 합친
  `00-current-asset-inventory-grid.png`.
- 게임플레이, 효과 frame, UI, source/review와 미연결 맵 파일을 구분한
  `current-asset-inventory.csv`.
- 첫 승인 단위인 player hull/engine/aim mount 3안 생성과 alpha 검증 완료.

남은 일:

- player 기반 3안 중 하나 승인.
- 나머지 11개 가족의 후보 생성과 가족별 승인.
- 승인 뒤 production 파일 분리·정규화·manifest 고정.
- 런타임 교체, 추가 수정, 회귀 검증, 마지막 성능 검증.

## Scope

포함:

- player, secondaries, ordinary/elite/boss actor와 boss module 이미지.
- player/hostile projectile, defense/state, pickup, effect atlas와 combat cue.
- floor tile, wall topology, cover, bulkhead, facility와 functional terrain 이미지.
- HUD glyph, minimap marker, UI panel/control state와 upgrade card composition.
- orbit 방향, engine rigid attachment 표현, 공격 가독성, XP 단순화,
  지형지물 시각/영향 범위 일치.
- 비주얼 교체 뒤 적 이동 속도 체감 재측정과 승인된 값의 소규모 조정.

제외:

- 적 합동 전략, formation, encounter composition과 spawn capacity 변경.
- 보스 패턴·AI·단계·공격 cadence의 재설계.
- stage topology, walkable geometry, collision, navigation, LOS 규칙 변경.
- 새 engine, production dependency, 렌더러 전면 재작성.
- 승인 전 runtime asset overwrite, manifest/provider 변경.

파괴적 또는 되돌리기 어려운 작업:

- 기존 에셋을 덮어쓰지 않는다. 새 versioned pack을 만들고 switch commit을
  별도로 유지한다.
- 기존 semantic-v2는 새 pack의 runtime 검증이 끝날 때까지 rollback
  source로 보존한다.

사용자 승인이 필요한 정확한 작업:

- 각 가족 후보의 `approved` 전환.
- tile algorithm output과 wall topology asset set 승인.
- 모든 필수 행 승인 뒤 이 문서의 `active` 전환과 런타임 적용 시작.
- 적 속도의 최종 수치.

## Proposed Design

### 승인 단위와 상태

각 행은 다음 상태만 가진다.

`current` → `candidate` → `approved` → `productionized` → `switched` → `verified`

- `candidate`: 보드와 repo에 검토 이미지가 존재하지만 런타임 미사용.
- `approved`: 사용자가 시각 방향과 항목 구성을 승인.
- `productionized`: 개별 alpha PNG, pivot, canvas, 9-slice 또는 frame
  metadata가 확정.
- `switched`: provider/Theme/runtime이 새 pack을 참조.
- `verified`: 실제 플레이 캡처와 validator가 통과.

### 가족별 생성 순서

| 순서 | 가족 | 한 시트 최대 항목 | 승인 핵심 |
| ---: | --- | ---: | --- |
| 1 | player hull · rigid engine · aim mount | 3 | +X 방향, rear socket, 큰 실루엣 |
| 2 | seeker · escort · orbit blade · wake mine | 4 | 모두 다른 silhouette, orbit outward facing |
| 3 | ordinary enemy 역할 19종 | 4 | grayscale에서도 역할 구분 |
| 4 | boss 5종 · objective module 10종 | 3 | 본체 비대칭, 파괴 목표 분리 |
| 5 | player/hostile projectile · ordinary/elite/boss attack cue | 4 | 탄두, 방향, 등급, affinity 동시 판독 |
| 6 | barrier · ion field · shield source · status | 4 | 보호막/역장 topology 중복 제거 |
| 7 | XP 3단계 · repair · recall · crate | 4 | XP는 가장 단순, reward는 충돌 시 판독 |
| 8 | effect identity 22종 | 3 | key pose, 잔상/충돌/폭발 의미 분리 |
| 9 | floor tile primitives · algorithm preview | 4 | 실제적·단순, deterministic, 무효 문양 없음 |
| 10 | wall straight/corner/end/junction | 4 | floor보다 높고 blocker 경계가 즉시 보임 |
| 11 | cover · bulkhead · repair/overdrive/arc/gate | 4 | 이미지 footprint와 effect/collision overlay 일치 |
| 12 | HUD/UI glyph · panel/control · upgrade card | 4 | image shell + dynamic content, overflow 0 |

### 맵 타일 알고리즘 승인 계약

승인용 preview는 구현 코드가 아니라 다음 고정 입력을 보여주는 설계
산출물이다.

- 동일한 walkable mask에 대해 같은 `field_id`, layout fingerprint와
  cell coordinate는 항상 같은 결과를 낸다.
- 기본 cell 크기는 현재 288 world unit을 유지한 안을 먼저 제시한다.
- `1×1`, `2×1`, `1×2`, `2×2` module은 바닥 panel seam만 만든다.
- wall asset 선택은 collision boundary의 neighbor topology로만 정한다.
- floor variation은 낮은 대비 panel plane과 드문 service joint만 허용한다.
- gameplay 의미가 없는 문양, rune, 큰 decal과 반복 강조선은 금지한다.

사용자가 288-unit 안을 거절할 경우에만 cell 크기를 별도 결정 항목으로
올린다. 승인 전에는 compiler 상수를 바꾸지 않는다.

### 공격 표시 계약

- damaging core 외곽은 collision boundary와 동일하다.
- non-damaging tail은 진행 방향을 보여주며 core보다 낮은 명도다.
- ordinary는 단일 solid head와 한 줄 tail pattern.
- elite는 split/notched head와 이중 tail 또는 별도 startup cap.
- boss는 boss-command silhouette와 pattern-specific locked endpoint를
  사용한다.
- beam만 full corridor를 사용한다. projectile은 최대 0.4초 lead,
  charge는 rounded endpoint capsule, area는 실제 outer boundary를 쓴다.
- thin line은 보조 축으로만 사용하고, head/cap/filled footprint 없이
  단독 위험 표시는 하지 않는다.

### UI 카드 계약

- 카드 height의 30–34%를 `TextureRect` family art slot으로 사용한다.
- art는 카드 background에 굽지 않고 upgrade family image로 공급한다.
- 이름과 레벨은 같은 행 또는 인접한 한 덩어리로 표시한다.
- 설명은 3줄, 실제 효과는 최대 2행, behavior는 필요할 때 1행,
  level pip은 마지막 고정 행이다.
- `960×540`, `1280×720`, `1920×1080`, 한국어·영어, 200% text
  fixture에서 잘림·겹침·container 이탈이 0이어야 한다.

## Architecture and Ownership

| 관심사 | 기존 소유자 | 교체 시 지켜야 할 경계 |
| --- | --- | --- |
| gameplay image ID/pivot/frame | `art/gameplay/semantic-v2/asset-manifest.json`, semantic provider | 새 versioned manifest를 만들고 collision/behavior를 넣지 않는다. |
| actor/projectile/effect batch | `vehicle_combat_renderer.gd`와 component catalog | texture와 presentation scale만 바꾸고 simulation 값을 재정의하지 않는다. |
| UI chrome | UI manifest, `vehicle_ui_asset_provider.gd`, Godot Theme | `StyleBoxTexture`와 dynamic Control 합성을 유지한다. |
| upgrade card layout | `vehicle_upgrade_choice_card.gd`, panel owner | card behavior/data는 UI에서 만들지 않는다. |
| floor presentation | `vehicle_field_surface_pattern_compiler.gd` | active geometry/fingerprint를 입력으로 사용하고 topology를 바꾸지 않는다. |
| wall/world presentation | `vehicle_world_mesh_builder.gd` | stage geometry가 collision owner로 남고 visual collider는 0개다. |
| terrain state/range | `vehicle_terrain_runtime.gd` | 실제 rect/radius/timer/health가 이미지와 overlay를 구동한다. |
| direct terrain draw | `vehicle_run.gd::_draw_terrain` | procedural shell을 승인 이미지로 교체하되 live state overlay만 남긴다. |

## As-Is / To-Be Delta Map

| 항목 | AS-IS | TO-BE | 수용 기준 |
| --- | --- | --- | --- |
| player engine | rigid 계약은 있으나 현재 이미지와 이동 중 부착 인상이 어색함 | 단순 rear module, hull transform만 공유, flame 길이만 변화 | 회전·dash·감속 캡처에서 engine angle drift 0 |
| orbit blade | 위치 각도와 render rotation의 index offset 불일치 | 각 blade의 radial vector가 바깥 방향과 일치 | 모든 blade dot(radial, forward) > 0 |
| enemy speed | 최근 비주얼 작업에서 미조정 | 시각 교체 후 체감과 time-to-contact 측정, 승인 수치만 적용 | 역할별 속도표와 before/after fixture 승인 |
| projectile/readability | 작은 5/6/7px core와 36px trail, 등급 문법 약함 | collision core 유지, 등급별 head/tail/cap 분리 | 압력 캡처에서 ordinary/elite/boss와 방향 오인 0 |
| upgrade card | 작은 header glyph, top-third art 없음 | top-third art → 이름·레벨 → 설명·효과 | 모든 locale/viewport overflow 0 |
| XP | 3개 기계형 이미지 | 단순 shard geometry, 크기/면 수로 값 구분 | 1× scale에서 세 단계 즉시 구분 |
| floor | 288-unit vertex-color module | 승인 image tile + deterministic compiler | 동일 seed/hash 동일, void bleed 0 |
| wall | retained mesh, PNG 6개 미연결 | topology-selected wall image shell | 모든 blocker boundary 표시, visual collider 0 |
| terrain | image와 procedural shape 혼합 | 고유 image body + 실제 rect/radius overlay | debug footprint와 visual boundary 정합 |
| UI panel | image-backed이나 card hierarchy와 font fit 불량 지점 존재 | 승인 shell + Noto Sans KR dynamic content | text bounds, focus, overflow validator 통과 |

## Tasks

### Phase 0: 승인 카탈로그 고정

목표: 런타임을 바꾸지 않고 현재 truth와 첫 후보를 검토 가능하게 만든다.

- [x] **0.1** 현재 PNG 파일 전수 목록과 상태 분류를 생성한다.
- [x] **0.2** 기존 11개 review sheet를 한 장의 master grid로 합친다.
- [x] **0.3** player foundation 3안을 repo와 같은 Creative Production
  board에 올린다.
- [ ] **0.4** 사용자가 player foundation 한 안을 승인하거나 수정 지시한다.

단계 수용: inventory와 master grid가 재생성 가능하고 후보가 runtime에서
참조되지 않는다.

단계 방어: `git diff`에 provider, Theme, gameplay/UI manifest와 runtime
script 변경이 없어야 한다.

### Phase 1: 모든 시각 가족 승인

목표: 12개 가족을 작은 시트로 생성하고 하나씩 승인한다.

- [ ] **1.1** 승인된 이전 가족의 문법을 다음 가족 prompt와 manifest에
  고정한다.
- [ ] **1.2** 후보 한 장당 최대 4개 identity만 생성한다.
- [ ] **1.3** 각 후보를 실제 플레이 크기의 조밀한 배경 mock에서
  outline/색/negative space로 검수한다.
- [ ] **1.4** tile algorithm, wall topology와 terrain footprint는 일반
  actor asset과 별도 승인한다.
- [ ] **1.5** 모든 필수 행이 승인되면 선택된 파일 hash, canvas, pivot,
  state/frame 요구를 이 문서에 기록하고 `active` 승인을 요청한다.

단계 수용: 승인 카탈로그의 필수 행이 모두 `approved`.

단계 방어: 하나라도 `candidate` 또는 `revise`이면 Phase 2로 넘어가지 않는다.

### Phase 2: 승인 이미지를 production pack으로 정규화

목표: 시안을 개별 alpha PNG, atlas와 9-slice로 변환하되 런타임은 아직
바꾸지 않는다.

- [ ] **2.1** 각 asset을 canvas/pivot/facing 계약에 맞춰 분리한다.
- [ ] **2.2** alpha fringe, 투명 모서리, subject coverage와 trim 정책을
  검증한다.
- [ ] **2.3** animation은 승인 key pose에서 필요한 최소 frame만 만들고
  atlas/frame metadata를 고정한다.
- [ ] **2.4** UI shell은 state별 독립 PNG와 patch margin/safe inset을
  만든다.
- [ ] **2.5** 새 versioned manifest와 review sheet를 생성한다.

단계 수용: 모든 승인 identity가 정확히 한 production file/record owner를
갖고 누락·중복 0.

### Phase 3: player, secondary, pickup과 combat image switch

- [ ] **3.1** player hull/engine/aim attachment를 새 pack으로 전환한다.
- [ ] **3.2** orbit blade의 position angle과 render rotation angle을 같은
  blade index로 계산한다.
- [ ] **3.3** secondaries와 XP/reward pickup을 전환한다.
- [ ] **3.4** projectile head/tail, attack tier cue와 effect atlas를 전환한다.
- [ ] **3.5** defense/field/shield source의 topology 중복이 없는지
  grayscale과 pressure fixture로 확인한다.

단계 수용: 기체 부착 방향, 보조무기, pickup, projectile와 attack tier가
실제 플레이에서 승인 시안과 일치한다.

### Phase 4: enemy, boss와 target guidance image switch

- [ ] **4.1** ordinary enemy 19종과 elite trait overlay를 전환한다.
- [ ] **4.2** boss 5종과 objective module 10종을 전환한다.
- [ ] **4.3** ordinary/elite/boss attack cue가 head/tail/cap 문법으로
  구분되는지 fixture를 추가한다.
- [ ] **4.4** boss reduced-damage 상태와 파괴 목표 안내가 body/module/UI에서
  같은 target을 가리키는지 확인한다.

단계 수용: 군집, elite, boss startup/active/recovery 캡처에서 역할과
공격 방향이 가려지지 않는다.

### Phase 5: UI panel과 upgrade card switch

- [ ] **5.1** 승인된 panel/control state를 Theme의 image-backed
  `StyleBoxTexture`로 전환한다.
- [ ] **5.2** upgrade card를 top-third art, 이름+레벨, 설명/효과/pip
  구조로 재배치한다.
- [ ] **5.3** Noto Sans KR provider와 font size/weight를 확인한다.
- [ ] **5.4** 한국어·영어, 960/1280/1920과 200% text fixture의
  overflow/focus를 검증한다.

단계 수용: UI chrome은 이미지가 소유하고 dynamic content는 Control이
소유하며 overflow 0.

### Phase 6: floor, wall과 terrain image switch

- [ ] **6.1** 승인 tile primitives를 deterministic compiler output으로
  배치한다.
- [ ] **6.2** wall neighbor topology로 straight/corner/end/junction image를
  선택한다.
- [ ] **6.3** cover와 terrain body를 승인 이미지로 교체하고 live
  radius/rect/progress overlay만 절차적으로 유지한다.
- [ ] **6.4** decorative no-op descriptor와 무효 문양을 제거한다.
- [ ] **6.5** geometry, collision, navigation, LOS, minimap fingerprint가
  바뀌지 않았는지 검증한다.

단계 수용: floor/wall/terrain 3계층이 즉시 구분되고 모든 visual footprint가
debug truth와 일치한다.

### Phase 7: 비시각 인접 수정

- [ ] **7.1** current enemy speed와 실제 time-to-contact를 역할별로
  측정하고 승인용 수치표를 제시한다.
- [ ] **7.2** 승인된 속도만 archetype owner에 적용하고 attack cadence,
  spawn 수, formation은 바꾸지 않는다.
- [ ] **7.3** 모든 pickup 종류가 player body와 dash swept contact로
  정확히 한 번 수집되는지 확인한다.
- [ ] **7.4** 공격 표시가 collision truth를 바꾸지 않았는지 회귀 검증한다.

단계 수용: 사용자가 승인한 속도 체감과 pickup contact가 재현된다.

### Phase 8: 최종 회귀와 성능 검증

이 단계는 Phase 2–7이 모두 완료되기 전에는 시작하지 않는다.

- [ ] **8.1** 관련 focused validator와 full validator를 실행한다.
- [ ] **8.2** Web export, production-style start와 실제 플레이 smoke를
  수행한다.
- [ ] **8.3** 한국어·영어 전체 visual matrix와 승인 시안 비교를 완료한다.
- [ ] **8.4** 마지막으로 production, boss, 276-actor peak와 320-capacity
  성능 matrix를 실행한다.
- [ ] **8.5** 성능 실패 시 actor/projectile 수, 해상도, 품질을 낮추지 않고
  측정된 hot path만 별도 수정한다.
- [ ] **8.6** native/Web/lifecycle evidence가 모두 끝난 뒤 문서와 plan
  lifecycle을 정리한다.

단계 수용: 기능·시각 검증이 먼저 통과하고, 그 뒤 기존 성능 threshold가
통과한다.

## Test Plan

승인 전:

- catalog generator를 다시 실행해 master grid와 CSV가 같은 입력에서
  재현되는지 확인.
- 후보 PNG의 alpha, dimensions, 투명 모서리, 항목 수와 reference
  fidelity를 시각 검수.
- `git diff`로 runtime 변경 0 확인.

교체 중:

- 가족별 asset/provider/UI/world focused validator.
- attachment rotation, collision overlay, texture pivot와 frame event fixture.
- 지원 해상도와 한국어·영어 캡처.
- 각 switch commit은 해당 가족만 포함하고 이전 pack으로 rollback 가능.

최종:

- `tools/validation/` 전체 relevant validators.
- `./tools/godot.ps1 --headless --path . --export-release Web ...`에 해당하는
  기존 Web export 경로.
- built Web의 입력, pause, pointer와 주요 modal smoke.
- 모든 asset/UI가 전환된 뒤에만 authoritative performance matrix.

## Validation Cadence

- 후보 생성 단계에서는 asset 파일 자체만 검사하고 게임 성능을 측정하지
  않는다.
- productionization 단계에서는 파일 계약과 catalog coverage만 검사한다.
- switch 단계에서는 해당 가족의 narrow fixture만 실행한다.
- 전체 Web/export/performance gate는 마지막 Phase 8에서 한 번 실행하고,
  실패 원인이 바뀐 경우에만 반복한다.

## Rollback / Safety

- 기존 semantic-v2 파일은 승인된 새 pack이 `verified`될 때까지 삭제하거나
  덮어쓰지 않는다.
- 새 pack은 별도 versioned root에 생성한다.
- manifest/provider/Theme switch는 가족별 독립 commit으로 만든다.
- floor/wall switch가 실패하면 기존 vertex-color presentation compiler로
  되돌릴 수 있어야 하며 stage geometry와 save data는 영향을 받지 않는다.
- UI switch가 실패하면 기존 Theme reference만 되돌리고 card data/behavior는
  유지한다.

## Predetermined Error Handling and Contingencies

| 조건 | 대응 | 한계 |
| --- | --- | --- |
| 후보가 승인 마스터보다 과도하게 세밀함 | 같은 identity로 한 번만 단순화 재생성 | 두 번 실패하면 해당 가족을 새 prompt로 분리 |
| 한 이미지에 항목 누락·융합 | 항목 수를 더 줄여 재생성 | 최대 4개 규칙은 완화하지 않음 |
| alpha fringe 또는 배경 잔존 | chroma removal을 한 번 재실행 | 계속 실패하면 후보만 보존하고 productionized로 올리지 않음 |
| runtime에서 pivot/scale 불일치 | manifest canvas/pivot만 수정하고 gameplay geometry는 유지 | collision 변경 금지 |
| tile가 반복적으로 보임 | coordinate hash variant와 rotation만 조정 | 무효 장식 추가 금지 |
| wall/terrain visual이 truth보다 큼/작음 | image fit과 overlay를 truth에 맞춤 | collision을 이미지에 맞춰 변경 금지 |
| UI overflow | art slot/text budget/spacing을 재배치 | font 14 미만 축소나 clip으로 은폐 금지 |
| 마지막 성능 gate 실패 | profiler 근거가 있는 allocation/traversal/batch 수정 | 적 수·탄환 수·해상도·품질 하향은 별도 승인 |

## Risks

- 생성 시트에서 좋아 보이는 작은 디테일이 실제 플레이 크기에서 뭉칠 수
  있다. 각 가족은 압력 배경 1× mock 검수가 필요하다.
- 모든 actor에 강한 내부선까지 넣으면 군집이 시끄러워진다. 바깥 contour는
  유지하되 내부선은 역할 판독에 필요한 것만 남긴다.
- 바닥·벽 이미지를 연결하면 batch와 VRAM cost가 바뀐다. 다만 사용자의
  지시에 따라 성능 판단은 모든 교체 뒤 마지막에 수행한다.
- UI 이미지가 text-safe inset을 잘못 가지면 다시 overflow가 생긴다.
- 이전 `done`/`superseded` 계획의 수치와 임시 테마를 새 승인으로 오인할
  위험이 있다.

## Open Questions

이 문서가 `draft`인 동안 남아 있는 사용자 결정이다.

- player foundation 3안 중 채택 또는 수정 방향.
- 이후 각 가족 후보의 채택 여부.
- 288-unit tile 후보가 승인되지 않을 경우 대체 cell 크기.
- 모든 시각 승인 후 적 이동 속도의 최종 수치.

이 질문은 구현 단계의 선택 과제가 아니다. 모두 승인 카탈로그에서
결정되고 문서에 기록된 뒤에만 이 계획을 `active`로 전환한다.

## Decision Notes

- 2026-07-31: 사용자는 현재 에셋을 하나의 그리드로 고정하고, 에셋·타일
  알고리즘·벽·지형지물을 모두 확인한 뒤에만 추가 수정과 교체를
  시작하도록 지시했다.
- 2026-07-31: 이전 `done` 계획은 재활성화하지 않는다. 현재 문서는 새
  승인 게이트와 최신 피드백만 소유한다.
- 2026-07-31: UI panel image 위에 localized text와 dynamic icon을
  배치하는 합성 규칙을 유지한다.
- 2026-07-31: 성능 검증은 모든 asset/UI 교체 후 마지막으로 고정한다.

## Progress

- [x] 현재 에셋 inventory 생성.
- [x] 단일 master grid 생성.
- [x] 첫 player foundation 후보 3안 생성 및 등록.
- [ ] 필수 가족 승인.
- [ ] plan 활성화 승인.
- [ ] productionization과 runtime switch.
- [ ] 최종 validation/performance.

## Next Steps

1. player foundation 3안을 검토한다.
2. 선택된 안으로 secondary 4종 후보를 생성한다.
3. 승인 카탈로그의 순서대로 모든 필수 가족을 하나씩 확정한다.
4. 전부 승인된 뒤 이 문서를 decision-complete 상태로 갱신하고 사용자에게
   런타임 적용 시작 권한을 확인한다.

## Completion Criteria

- [ ] 모든 필수 승인 행이 `approved`다.
- [ ] 승인된 identity가 모두 productionized/switched/verified 상태다.
- [ ] 기존 runtime pack의 미승인 잔존 참조가 0이다.
- [ ] UI panel은 image-backed이고 dynamic text/icon ownership을 지킨다.
- [ ] upgrade card overflow가 모든 locale/viewport에서 0이다.
- [ ] floor/wall/terrain visual과 collision/effect truth가 일치한다.
- [ ] orbit 방향, engine attachment, attack readability, XP 단순화와
  pickup contact가 검증된다.
- [ ] 모든 asset/UI 교체 후 마지막 성능 gate가 통과한다.

## Stop Conditions

완료:

- 최종 completion criteria와 lifecycle 정리가 모두 끝났을 때.

중단 및 사용자 결정 요청:

- 필수 후보가 `revise` 또는 미승인 상태일 때.
- tile cell 크기, 적 속도 수치처럼 사용자 선택이 필요한 항목이 남았을 때.
- collision/topology/게임 구성 변경 없이는 승인 시안을 구현할 수 없다는
  근거가 생겼을 때.

중단하지 않음:

- 후보 생성이나 production 분리가 번거롭다는 이유.
- 마지막 성능 gate가 처음 실패했지만 측정 가능한 hot path가 남아 있을 때.

## Handoff

```text
Goal:
모든 Cardborne 시각 가족을 먼저 승인하고, 승인 후에만 runtime을 교체한다.

Read first:
.agents/visual-redesign-decision-catalog.md
docs/design/component-sheets/semantic-v3-approval/README.md
docs/design/UI_VISUAL_SYSTEM.md

Execute exactly:
현재는 Phase 0–1의 후보 생성과 승인만 수행한다.
필수 승인 완료 전 runtime/manifest/provider/Theme를 바꾸지 않는다.

Validate with:
tools/design/build_visual_asset_approval_catalog.ps1
후보 PNG alpha/dimension/항목 수 검사
git diff runtime 변경 0 확인

Stop when:
다음 가족을 만들기 전에 현재 가족에 대한 사용자 승인 또는 수정 지시를 받는다.
```
