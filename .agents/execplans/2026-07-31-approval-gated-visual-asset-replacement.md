---
type: plan
status: active
owner: BK
created: 2026-07-31
last_reviewed: 2026-08-01
scope: Targeted Cardborne visual corrections, approved asset replacements, and adjacent gameplay fixes
related:
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../docs/design/component-sheets/semantic-v3-approval/01-world-combat-runtime-gap.md
  - ../../docs/product/vehicle_game_spec.md
  - ../visual-redesign-decision-catalog.md
  - ../semantic-v2-runtime-acceptance-evidence.md
---

# Cardborne 맵·전투 가독성 정상화 및 승인형 에셋 교체 계획

목적은 inventory grid를 관리하거나 새 이미지를 많이 만드는 것이 아니다.
실제 플레이에서 맵·벽·기능 지형·탄환·공격 경로와 UI가 역할과 판정에 맞게
즉시 읽히도록 정상화하는 것이다. inventory grid는 그 과정에서 누락된
에셋과 연결 상태를 하나씩 확인하는 **교체·수정 coverage ledger**로만 쓴다.

모든 디자인을 백지에서 다시 만들지는 않는다. 대신 scoped identity마다
현재 구현과 실제 런타임 결과를 확인해 `REUSE`, `FIX`, `REPLACE`, `ADD` 중
하나를 근거와 함께 결정한다. 미확인 항목을 자동으로 유지하지도, 자동으로
재생성하지도 않는다.

## Purpose

- 목표: 맵과 전투의 시각 표현을 실제 생성·collision·효과 범위·공격 경로와
  일치시키고, 역할과 위험 등급을 첫 시야에서 구분 가능하게 만든다.
- 최종 산출물: 승인된 대상의 새 이미지 또는 수정된 런타임 표현, 관련
  코드 수정, 비교 캡처와 검증 결과.
- 완료 상태: scoped identity 전부의 처리 결과가 기록되고, 승인된 에셋과
  코드 변경이 실제 런타임에서 판정 truth와 일치하며 누락 없이 적용된 상태.
- 현재 상태: `active`, 단 승인 전 권한은 조사·비교·후보 제작까지다. runtime
  manifest/provider, Theme와 gameplay code는 사용자 승인 뒤에 바꾼다.

## Why / Context

현재 semantic-v2에는 이미 기체, 적, 보스, 보조무기, 탄환, 아이템, 효과와
UI 이미지가 있다. 문제는 이 전체가 존재하지 않는 것이 아니라 다음과 같이
일부 표현·연결·레이아웃이 요구와 맞지 않는다는 점이다.

- 바닥·벽 이미지는 파일만 있고 런타임에 연결되지 않았다.
- 지형지물은 이미지와 절차 도형이 섞여 실제 영향 범위와 다르게 느껴진다.
- 공격 방향과 탄환의 위험 등급이 전투 중 충분히 잘 보이지 않는다.
- upgrade card의 이미지·이름·레벨·설명 계층과 font/overflow가 맞지 않는다.
- XP는 필요 이상으로 복잡하고, orbiting secondary의 방향 계산은 어긋난다.
- 적 속도와 pickup contact는 이미지 교체가 아닌 별도 gameplay 수정이다.

따라서 inventory는 수정 작업의 coverage를 보증하는 수단이다. 목표는 각
항목을 실제 게임에서 정상화하는 것이며, 기존 에셋이 목적을 충족하면
재사용하고 그렇지 않으면 수정하거나 교체한다.

## Scope / Non-scope

### In scope

- scoped 에셋을 `REUSE`, `FIX`, `REPLACE`, `ADD`, `OPTIONAL`로 전수 판정.
- 다음 필수 시각 대상의 후보 생성과 사용자 승인.
  - map floor tile과 deterministic placement preview
  - wall straight/corner/end/junction image assets
  - cover, bulkhead, functional terrain/facility image assets
  - ordinary/elite/boss projectile와 attack telegraph readability
  - upgrade card art slot과 image-backed panel composition
  - 단순 XP shard 표현
  - 4–6개 큰 plane으로 단순화한 boss body 5종
  - 모든 boss가 공유하는 방어막 노드 active/damaged/resolved 3상태
- 다음 인접 gameplay 수정.
  - engine이 hull에 rigid하게 붙어 보이도록 attachment transform 확인
  - orbiting secondary가 기체 중심에서 바깥을 향하도록 rotation 수정
  - 적 이동 속도 측정 후 승인된 값만 조정
  - player body와 dash swept path로 pickup 수집
- 승인된 대상만 production asset 또는 runtime code로 반영.
- 모든 승인 대상 구현 후 마지막 성능 검증.

### Out of scope

- 근거 확인 없이 player, ordinary enemy, secondary, effect와 UI 전체를
  일괄 재제작. boss는 2026-08-01 사용자 피드백에 따라 body와 방어막
  objective만 승인 후보로 추가한다.
- 현재 정상이고 사용자가 교체를 요청하지 않은 에셋 변경.
- 적 합동 전략, formation, encounter composition과 spawn capacity 변경.
- 새 보스 패턴·AI·단계·cadence의 콘텐츠 재설계. 기존 pattern kind가 잘못된
  원형 장판으로 축약되는 실행·표시 오류 수정은 in scope다.
- stage topology, collision, navigation, LOS와 save-data 변경.
- 새 engine 또는 production dependency 도입.

## Assumptions

- 현재 asset grid는 교체·수정 작업의 누락 방지 목록이며 그 자체가 목적은
  아니다.
- 기존 에셋 재사용은 실제 런타임 preview에서 요구를 충족했을 때만
  확정한다. 명시적 검토 없이 `REUSE`로 간주하지 않는다.
- 생성된 player foundation 3안은 사용자가 더 낫다고 평가했지만 원래 필수
  요청은 아니므로 `OPTIONAL`로 보관한다.
- UI panel image 위에 localized text, icon, value와 focus state를 올리는
  기존 합성 원칙은 유지한다.
- 성능 검증은 승인된 asset/UI 수정이 모두 적용된 뒤 마지막에 수행한다.

## Pre-plan Evidence Already Verified

| 근거 | 현재 사실 | 계획에 미치는 영향 |
| --- | --- | --- |
| `00-current-asset-inventory-grid.png` | 현재 review sheet 11개를 한 장에 고정 | 교체·수정 누락을 막는 coverage ledger |
| `current-asset-inventory.csv` | 390개 PNG를 runtime/staged/source로 구분 | 파일 존재와 교체 필요를 분리 |
| gameplay manifest/provider | gameplay runtime PNG 239개, floor/wall 8개 미연결 | 파일 존재와 실제 사용을 분리해서 판정 |
| UI manifest/provider | 13 component, 57개 image state | 문제 있는 card/layout만 수정 |
| field surface compiler | 288-unit deterministic vertex-color module | tile 후보 승인 후에만 이미지 연결 |
| world mesh builder | wall/cover는 UV 없는 retained mesh | wall 후보 승인 후 geometry-fed image shell로 변경 |
| terrain runtime | rect/radius/timer/health가 gameplay truth | 이미지를 gameplay 범위에 맞춤 |
| combat renderer | live footprint는 정확하지만 head/tail/tier 판독이 약함 | collision은 유지하고 표시만 개선 |
| upgrade choice card | 작은 header glyph 중심 | top-third art 계층으로 국소 수정 |

## Classification Contract

| 상태 | 의미 | 허용 작업 |
| --- | --- | --- |
| `REUSE` | 실제 runtime preview에서 요구를 충족한 기존 에셋 | 연결 또는 회귀 검증 |
| `FIX` | 에셋은 유지하고 transform/layout/runtime 표현만 수정 | 해당 owner의 최소 코드 변경 |
| `REPLACE` | 현재 이미지가 요구를 충족하지 못함 | 승인된 새 이미지만 교체 |
| `ADD` | 필요한 runtime image가 없거나 미연결 | 승인된 신규 asset과 provider 연결 |
| `OPTIONAL` | 요청 범위 밖이지만 비교 가치가 있는 후보 | 사용자 선택 전 구현·승인 gate에 영향 없음 |

각 scoped asset은 근거가 기록되기 전까지 `UNREVIEWED`다. `OPTIONAL` 항목이
미결정이어도 필수 수정 계획을 진행할 수 있다.

## Locked Target Matrix

| 대상 | 분류 | AS-IS | TO-BE | 승인 필요 |
| --- | --- | --- | --- | --- |
| player hull/engine/aim art | `REUSE` + optional candidate | 현재 runtime image 사용 | 이번 필수 범위에서는 유지; flat 시안은 선호 표현만 기록 | 아니오 |
| engine attachment | `FIX` | 이동 중 부착 인상이 어색할 수 있음 | hull transform만 공유, 별도 꺾임 0 | 시각 캡처 |
| orbit blade orientation | `FIX` | blade index가 rotation에 반영되지 않음 | 각 blade forward가 radial outward와 일치 | 아니오 |
| enemy movement speed | `FIX` | 체감상 느림 | 역할별 time-to-contact 측정 후 승인 수치 적용 | 최종 수치 |
| hostile projectile | `REPLACE/FIX` | 작은 core와 얇은 trail이 잘 안 보임 | core truth 유지, 더 명확한 head/tail silhouette | 이미지 시안 |
| ordinary/elite/boss attack cue | `FIX`, 필요 시 `ADD` | 공용 선 문법 비중이 큼 | 등급별 head, cap, fill/pattern 차이 | integration preview |
| upgrade card | `FIX` + 필요 시 `REPLACE` | 작은 header glyph, 계층/overflow 문제 | 상단 1/3 art → 이름·레벨 → 설명·효과 | panel mock |
| XP pickup | `FIX` | 기계형 3단계 image | 단순 shard geometry, 크기/면 수만 차이 | 간단 시안 |
| floor tile | `FIX/ADD` | deterministic polygon compiler가 있고 PNG는 제외됨 | 기존 seed 배치가 tile ID·회전·UV를 출력 | integration preview + algorithm |
| wall | `FIX/ADD` | 선분 rail renderer이며 PNG는 제외됨 | 선분 topology를 분류해 wall image를 실제 경계에 배치 | integration preview + topology |
| cover/terrain/facility | `FIX`, 필요 시 `REPLACE` | 작은 body image와 실제 rect/radius 도형이 분리됨 | body가 전체 footprint를 차지하고 live truth overlay와 일치 | footprint preview |
| pickup contact | `FIX` | 종류별 contact 경로 확인 필요 | body/dash swept contact로 정확히 1회 수집 | 아니오 |
| boss body | `REPLACE` | 5종 모두 작은 panel·lamp·greeble이 과밀 | 고유 silhouette는 유지하고 4–6개 큰 plane과 한 외곽선으로 단순화 | 이미지 시안 |
| boss 방어막 objective | `REPLACE` | boss마다 10종의 서로 다른 module raster와 이름 사용 | 동일한 보스 방어막 노드 housing의 active/damaged/resolved 3상태만 재사용 | 이미지 시안 + state contract |
| 나머지 actor/secondary/effect/UI | `UNREVIEWED` 또는 `REUSE` | 현재 semantic-v2 | 기존 피드백 범위와 inventory coverage에 따라 판정 | 해당 시각 변경 시 |

## Proposed Design

### Candidate generation

- 먼저 기존 에셋을 실제 크기·경로·배치에 올린 integration preview를 만든다.
- preview에서 요구를 충족하지 못한 `REPLACE/ADD` 대상만 새 후보를 만든다.
- 한 이미지에는 최대 4개 asset identity만 둔다.
- 기존 에셋을 그대로 쓸 수 있다는 판정에는 실제 runtime scale과 배경 위
  비교 근거가 필요하다.
- text, level, value와 gameplay icon을 panel background에 굽지 않는다.
- 후보는 `candidate`일 뿐 runtime manifest에서 참조하지 않는다.
- AS-IS/TO-BE 비교는 모든 report surface에서 왼쪽 AS-IS, 오른쪽 TO-BE의
  가로 한 쌍으로만 표시한다. 좁은 화면에서는 페이지 전체가 아니라 pair
  내부를 가로 scroll한다.

### Map and terrain

- floor art와 placement algorithm을 함께 확인하되 서로 다른 책임으로
  승인한다.
- 현재 288-unit cell, `1×1`, `2×1`, `1×2`, `2×2` module과 deterministic
  hash는 유지하고, 출력에 tile ID·회전·UV/clip을 추가한다.
- tile variation은 field/layout fingerprint와 cell coordinate로 결정한다.
- wall asset은 collision boundary neighbor topology로만 선택한다.
- cover/terrain image는 existing rect/radius를 바꾸지 않고 body를 그 전체에
  맞춘다. 작은 중앙 그림만 교체해 범위 불일치를 숨기지 않는다.
- 무효 문양, rune, 반복 강조 decal은 만들지 않는다.

### Combat readability

- damaging core boundary는 collision truth와 일치한다.
- tail은 방향만 보여주는 non-damaging cue다.
- ordinary/elite/boss는 head silhouette, tail pattern, startup cap 중 2개
  이상이 다르다.
- tier를 projectile state와 telegraph descriptor에서 renderer까지 전달한다.
- thin line은 보조 축으로만 사용하며 filled head/cap 없이 단독으로 쓰지
  않는다.
- beam만 full corridor, projectile은 최대 0.4초 lead, charge는 rounded
  endpoint capsule, area는 실제 outer boundary를 사용한다.

### Upgrade card

- card height의 30–34%를 family art slot으로 사용한다.
- 그 아래 이름+레벨, 설명, 실제 효과, optional behavior 순서다. 중복 level
  pip는 사용하지 않는다.
- 기존 card shell이 맞으면 유지하고 layout만 `FIX`한다.
- shell 자체가 text-safe inset을 침범할 때만 승인된 image state로 교체한다.
- 한국어·영어, 960/1280/1920과 200% text fixture에서 overflow 0.

## Architecture and Ownership

| 관심사 | 기존 owner | 변경 원칙 |
| --- | --- | --- |
| static/effect image | gameplay manifest + semantic provider | 승인된 ID만 추가·교체 |
| actor/projectile/effect batch | combat renderer + component catalog | simulation truth 유지 |
| UI chrome | UI manifest + UI provider + Theme | 기존 shell 우선, 필요한 state만 교체 |
| upgrade layout | upgrade choice card/panel | data/behavior를 UI에서 새로 만들지 않음 |
| floor presentation | field surface compiler | geometry/fingerprint 입력 유지 |
| wall/world presentation | world mesh builder | stage geometry가 collision owner로 유지 |
| terrain state | terrain runtime | rect/radius/timer/health 유지 |
| pickup behavior | pickup/runtime owner | visual과 별도로 swept contact 수정 |

## Milestones

1. 현재 구현을 추적해 image-only/code-only/both를 확정한다.
2. 기존 에셋 integration preview와 필요한 신규 후보만 사용자에게 승인받는다.
3. 승인된 표현 계약대로 map/wall/terrain과 combat code를 수정한다.
4. 나머지 card/XP/behavior 수정과 asset switch를 검증 가능한 batch로 진행한다.
5. 전체 asset/UI 적용과 기능 검증 뒤 마지막으로 성능을 측정한다.

## Tasks

### Phase 0: 구현 감사와 범위 교정

- [x] 현재 390개 PNG의 상태를 CSV로 기록한다.
- [x] 기존 review sheet 11개를 master grid로 합친다.
- [x] grid는 목적이 아니라 교체·수정 coverage 수단으로 계획을 교정한다.
- [x] 맵·벽·지형·탄환·공격 경로의 runtime owner와 실제 draw path를 추적한다.
- [x] 최종 요구를 image-only로 완결할 수 있는 대상이 없음을 확인한다.
- [x] player foundation 3안은 `OPTIONAL`로 보관한다.

Batch acceptance:

- 기존 runtime 파일 변경 0.
- optional player 후보가 필수 승인 gate를 막지 않음.

### Phase 1: 실제 연결 preview와 시각 승인

- [ ] **1.1 Map floor**: 기존 2종을 288-unit algorithm output에 올린 preview.
- [ ] **1.2 Wall**: 기존 6종을 straight/corner/end/junction으로 배치한 preview.
- [ ] **1.3 Terrain**: 기존 cover/repair/overdrive/arc body를 실제 footprint에
  맞춘 preview; 부족한 identity만 최대 4개씩 새로 생성.
- [ ] **1.4 Combat**: 기존 탄환을 정확한 collision core와 tier grammar에 올린
  preview; 부족한 head/tail/cap만 최대 4개씩 새로 생성.
- [ ] **1.5 Upgrade card**: 실제 card 비율의 panel/art/text-safe mock.
- [ ] **1.6 XP**: 단순 3단계 shard 시안.
- [x] **1.7 Boss body**: 현재 5종을 3종/2종 두 sheet로 나누어 단순화한 시안 생성 완료. 사용자 승인 대기.
- [x] **1.8 Boss shield node**: 모든 boss가 공유하는 동일 housing의
  active/damaged/resolved 3상태 시안.
- [ ] 각 필수 후보에 대해 사용자 `approve` 또는 `revise`를 기록한다.

Batch acceptance:

- 각 대상에서 기존 재사용/수정/교체/추가 결정과 이유가 기록됨.
- 새 후보는 실제 연결 preview로 부족함이 확인된 identity만 포함함.

### Phase 2: 승인 대상만 productionize

- [ ] 승인된 후보를 개별 alpha PNG, atlas 또는 9-slice state로 분리한다.
- [ ] canvas, pivot, facing, patch margin과 safe inset을 기록한다.
- [ ] 새 file과 기존 유지 file을 함께 가리키는 최소 manifest diff를 만든다.
- [ ] 미승인·optional 후보는 provider/Theme에서 참조하지 않는다.

Batch acceptance:

- 승인 대상 coverage 100%, 불필요한 새 asset 0.
- `REUSE` path와 hash가 승인 없이 변경되지 않음.

### Phase 3: 비시각 runtime fix

- [ ] engine attachment가 hull transform만 공유하도록 확인·수정한다.
- [ ] orbit blade position angle과 render angle에 같은 blade index를 쓴다.
- [ ] enemy time-to-contact 비교표를 만든 뒤 승인된 speed 값만 적용한다.
- [ ] 모든 pickup 종류의 body/dash swept contact를 검증·수정한다.

Batch acceptance:

- asset replacement 없이 각 behavior fixture가 통과.
- enemy tactics, spawn 수와 attack cadence 변화 0.

### Phase 4: 승인된 combat/UI asset switch

- [ ] projectile tier를 state/descriptor/renderer까지 전달하고 승인된
  head/tail/cap을 전환한다.
- [ ] exact live telegraph geometry를 그대로 사용한다.
- [ ] 3–4 px 단독 선을 footprint fill + boundary + tier grammar로 바꾼다.
- [ ] boss autonomous lane/beam/area가 원형 장판 하나로 축약되는 경로와
  warning readiness를 수정한다.
- [ ] upgrade card art slot과 text hierarchy를 적용한다.
- [ ] card shell 교체는 승인된 경우에만 수행한다.
- [ ] XP를 승인된 단순 표현으로 바꾼다.
- [ ] 승인된 boss body 5종과 공통 방어막 노드 3상태를 production asset으로
  분리하고, 기존 boss-specific module identity를 provider와 renderer에서
  제거한다.

Batch acceptance:

- ordinary/elite/boss와 공격 방향을 압력 캡처에서 구분.
- upgrade card locale/viewport overflow 0.

### Phase 5: 승인된 map/wall/terrain switch

- [ ] floor compiler가 승인 tile ID·회전·clip을 출력하고 renderer가 UV 또는
  instance로 연결한다.
- [ ] boundary neighbor topology로 승인 wall image를 선택·회전한다.
- [ ] terrain body를 전체 live rect/radius에 맞추고 exact boundary/timer만
  dynamic overlay로 유지한다.
- [ ] 무효 decoration을 제거한다.
- [ ] geometry, collision, navigation, LOS와 minimap fingerprint 불변을 확인한다.

Batch acceptance:

- floor/wall/terrain 3계층이 즉시 구분됨.
- visual collider 0, void bleed 0, footprint mismatch 0.

### Phase 6: 최종 회귀와 성능 검증

Phase 1–5가 완료되기 전에는 시작하지 않는다.

- [ ] 관련 focused validator와 full relevant validator를 실행한다.
- [ ] Web export와 built-Web interaction smoke를 수행한다.
- [ ] 한국어·영어 visual matrix를 확인한다.
- [ ] 마지막으로 production, boss, 276-actor peak와 320-capacity performance
  matrix를 실행한다.
- [ ] 실패 시 적 수·탄환 수·해상도·품질을 낮추지 않고 측정된 hot path만
  별도 수정한다.

## Test Plan

승인 전:

- candidate dimensions, alpha, 항목 수와 approved reference fidelity 확인.
- runtime manifest/provider/Theme/code diff 0 확인.

구현 중:

- 대상별 narrow fixture.
- attachment orientation, projectile collision overlay, terrain footprint와 UI
  text bounds 캡처.
- `REUSE` path/hash regression guard.

최종:

- relevant validators.
- Web export와 built runtime smoke.
- 모든 승인된 수정이 적용된 뒤 authoritative performance matrix.

## Rollback / Safety

- 기존 semantic-v2 file을 덮어쓰거나 삭제하지 않는다.
- 승인 replacement는 versioned sibling로 추가한다.
- runtime switch는 대상 가족별 독립 commit으로 만든다.
- map switch 실패 시 기존 vertex-color compiler reference로 되돌릴 수 있게
  한다.
- UI switch 실패 시 Theme reference만 되돌리고 card data/behavior는 유지한다.
- optional player 후보는 별도 승인 없이는 runtime에 연결하지 않는다.

## Risks

- inventory 관리 자체를 목표로 오해하거나, 반대로 미확인 항목을 자동
  유지해 실제 교체 누락을 만드는 위험.
- 기존 이미지가 있다는 이유만으로 런타임 연결·크기·상태 계약을 확인하지
  않고 “에셋 완료”로 처리할 위험.
- tile/wall image 연결 후 batch/VRAM 비용이 증가할 위험.
- 강한 outline이 군집에서 내부 노이즈로 변할 위험.
- terrain body와 실제 rect/radius가 다시 어긋날 위험.
- UI art slot이 text budget을 침범할 위험.

## Open Questions

- 필수 후보의 세부 시각 선택은 승인 카탈로그에서 순차적으로 확정한다.
- optional player 3안은 필수 결정이 아니다. 현재 이미지를 유지해도 계획은
  진행된다.
- enemy speed 최종 값은 before/after 측정표를 본 뒤 사용자 승인을 받는다.

필수 후보가 명시적으로 승인되기 전에는 Phase 2 이후의 production asset
switch로 넘기지 않는다.

## Decision Notes

- 2026-07-31: 현재 에셋 inventory와 master grid를 생성했다.
- 2026-07-31: player foundation 3안을 만들었으나, 사용자는 기체 교체를
  요청하지 않았음을 확인했다. 후보는 `OPTIONAL`로 보관한다.
- 2026-07-31: inventory grid는 목적이 아니라 교체·수정 coverage 수단이며,
  scoped asset에는 implicit `KEEP`가 없다고 교정했다.
- 2026-07-31: 바닥·벽 PNG는 provider에서 제외되고, 기능 장판 이미지는 실제
  범위보다 작으며, projectile/telegraph에는 tier/path code gap이 있음을
  확인했다. 따라서 새 이미지 선생성 대신 integration contract를 먼저
  승인받는다.
- UI panel image + dynamic text/icon 합성 규칙은 유지한다.
- 성능 검증은 승인된 asset/UI 수정이 모두 적용된 마지막에 수행한다.
- 2026-08-01: 모든 report 비교는 AS-IS/TO-BE 가로 쌍만 사용한다.
- 2026-08-01: boss body는 디테일을 줄인 5종 후보로 교체하고, boss마다
  달랐던 방어막 objective는 공통 `보스 방어막 노드` 3상태로 통일한다.
- 2026-08-01: 삭제 목록은 기능 없는 바닥 문양, upgrade level pip, dash
  danger 원, 의미 없는 방사형 flower burst, superseded 후보와 boss-specific
  방어막 module TO-BE다. AS-IS runtime 파일은 승인 비교 근거이므로 최종
  asset switch batch까지 유지하고 provider 전환과 같은 commit에서 제거한다.

## Progress

- [x] current inventory CSV와 master grid.
- [x] 맵·벽·장판·탄환·공격 경로 AS-IS/TO-BE 코드 감사.
- [x] inventory 수단/실제 정상화 목적 교정.
- [x] optional player candidate 3안 보관.
- [x] boss body 단순화 5종과 공통 방어막 노드 3상태 후보 생성.
- [x] 모든 visual unit·effect·UI·staged map을 92개 가로 AS-IS/TO-BE pair로
  재구성.
- [x] upgrade card level pip와 superseded mixed review sheet 삭제.
- [ ] 기존 에셋 integration preview와 필요한 신규 후보 승인.
- [ ] 승인 대상 productionization.
- [ ] targeted runtime fixes/switches.
- [ ] final validation/performance.

## Next Steps

1. player 후보를 필수 gate에서 제외한 상태를 유지한다.
2. 기존 floor/wall 이미지를 현재 algorithm/geometry에 올린 integration
   preview를 먼저 만든다.
3. terrain 실제 footprint와 projectile/telegraph tier 계약 preview를 만든다.
4. preview에서 부족한 identity만 새 에셋으로 생성해 사용자 승인을 받는다.
5. 승인 뒤에만 runtime code와 manifest/provider를 수정한다.

## Completion Criteria

- [ ] 필수 시각 대상이 모두 `REUSE/FIX/REPLACE/ADD`로 근거와 함께 판정됨.
- [ ] 부족한 asset만 재생성되었고 실제 교체·연결 누락이 없음.
- [ ] orbit/engine/pickup/speed 인접 수정이 승인 범위대로 동작함.
- [ ] attack direction/tier가 실제 플레이에서 구분됨.
- [ ] upgrade card overflow 0.
- [ ] floor/wall/terrain visual과 gameplay truth가 일치함.
- [ ] 마지막 performance gate 통과.

## Handoff

```text
Goal:
맵·지형·탄환·공격 표시를 실제 gameplay truth와 일치시키고 읽기 쉽게 만든다.

Read first:
.agents/visual-redesign-decision-catalog.md
docs/design/component-sheets/semantic-v3-approval/README.md
docs/design/UI_VISUAL_SYSTEM.md

Execute exactly:
inventory는 coverage 수단으로 사용한다.
기존 에셋 integration preview를 먼저 만들고 부족한 후보만 생성한다.
승인 전 runtime에는 연결하지 않는다.

Validate with:
tools/design/build_visual_asset_approval_catalog.ps1
candidate alpha/dimension/count 검사
runtime diff guard

Stop when:
현재 필수 승인 단위에 대한 사용자 승인 또는 수정 지시가 필요할 때.
```
