---
type: plan
status: draft
owner: BK
created: 2026-07-31
last_reviewed: 2026-07-31
scope: Targeted Cardborne visual corrections, approved asset replacements, and adjacent gameplay fixes
related:
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../docs/product/vehicle_game_spec.md
  - ../visual-redesign-decision-catalog.md
  - ../semantic-v2-runtime-acceptance-evidence.md
---

# Cardborne 선택적 비주얼 수정 및 에셋 교체 계획

현재 에셋은 **유지가 기본값**이다. 전체를 처음부터 다시 만드는 계획이
아니며, 현재 grid에서 사용자가 문제를 명시한 항목만 `FIX`, `REPLACE` 또는
`ADD`로 분류한다. 맵 타일·벽·지형지물·공격 표시·업그레이드 카드 등 필수
대상의 시안을 먼저 승인받고, 승인된 항목만 런타임에 반영한다.

## Purpose

- 목표: 현재 에셋을 보존하면서 명시된 가독성·구성·정합성 문제만 고친다.
- 최종 산출물: 승인된 대상의 새 이미지 또는 수정된 런타임 표현, 관련
  코드 수정, 비교 캡처와 검증 결과.
- 완료 상태: 필수 대상만 승인·구현·검증되고, `KEEP` 대상은 불필요하게
  재생성되거나 교체되지 않은 상태.
- 현재 상태: `draft`. 시각 후보 승인 전에는 runtime manifest/provider,
  Theme와 gameplay code를 바꾸지 않는다.

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

따라서 inventory 전체는 검토 기준일 뿐 전체 재제작 목록이 아니다.

## Scope / Non-scope

### In scope

- 현재 에셋을 `KEEP`, `FIX`, `REPLACE`, `ADD`, `OPTIONAL`로 분류.
- 다음 필수 시각 대상의 후보 생성과 사용자 승인.
  - map floor tile과 deterministic placement preview
  - wall straight/corner/end/junction image assets
  - cover, bulkhead, functional terrain/facility image assets
  - ordinary/elite/boss projectile와 attack telegraph readability
  - upgrade card art slot과 image-backed panel composition
  - 단순 XP shard 표현
- 다음 인접 gameplay 수정.
  - engine이 hull에 rigid하게 붙어 보이도록 attachment transform 확인
  - orbiting secondary가 기체 중심에서 바깥을 향하도록 rotation 수정
  - 적 이동 속도 측정 후 승인된 값만 조정
  - player body와 dash swept path로 pickup 수집
- 승인된 대상만 production asset 또는 runtime code로 반영.
- 모든 승인 대상 구현 후 마지막 성능 검증.

### Out of scope

- player, ordinary enemy, boss, secondary, effect와 UI 전체를 일괄 재제작.
- 현재 정상이고 사용자가 교체를 요청하지 않은 에셋 변경.
- 적 합동 전략, formation, encounter composition과 spawn capacity 변경.
- 보스 패턴·AI·단계·cadence 재설계.
- stage topology, collision, navigation, LOS와 save-data 변경.
- 새 engine 또는 production dependency 도입.

## Assumptions

- 현재 asset grid는 교체 목록이 아니라 현황 확인용 목록이다.
- 사용자가 특정 항목을 `REPLACE`로 지정하지 않으면 `KEEP`이다.
- 생성된 player foundation 3안은 사용자가 더 낫다고 평가했지만 원래 필수
  요청은 아니므로 `OPTIONAL`로 보관한다.
- UI panel image 위에 localized text, icon, value와 focus state를 올리는
  기존 합성 원칙은 유지한다.
- 성능 검증은 승인된 asset/UI 수정이 모두 적용된 뒤 마지막에 수행한다.

## Pre-plan Evidence Already Verified

| 근거 | 현재 사실 | 계획에 미치는 영향 |
| --- | --- | --- |
| `00-current-asset-inventory-grid.png` | 현재 review sheet 11개를 한 장에 고정 | 모든 항목을 새로 만든다는 뜻이 아님 |
| `current-asset-inventory.csv` | 390개 PNG를 runtime/staged/source로 구분 | 파일 존재와 교체 필요를 분리 |
| gameplay manifest/provider | gameplay runtime PNG 239개, floor/wall 8개 미연결 | 기존 runtime asset은 기본 유지 |
| UI manifest/provider | 13 component, 57개 image state | 문제 있는 card/layout만 수정 |
| field surface compiler | 288-unit deterministic vertex-color module | tile 후보 승인 후에만 이미지 연결 |
| world mesh builder | wall/cover는 UV 없는 retained mesh | wall 후보 승인 후 geometry-fed image shell로 변경 |
| terrain runtime | rect/radius/timer/health가 gameplay truth | 이미지를 gameplay 범위에 맞춤 |
| combat renderer | live footprint는 정확하지만 head/tail/tier 판독이 약함 | collision은 유지하고 표시만 개선 |
| upgrade choice card | 작은 header glyph 중심 | top-third art 계층으로 국소 수정 |

## Classification Contract

| 상태 | 의미 | 허용 작업 |
| --- | --- | --- |
| `KEEP` | 현재 에셋을 그대로 유지 | 회귀 검증만 수행 |
| `FIX` | 에셋은 유지하고 transform/layout/runtime 표현만 수정 | 해당 owner의 최소 코드 변경 |
| `REPLACE` | 현재 이미지가 요구를 충족하지 못함 | 승인된 새 이미지만 교체 |
| `ADD` | 필요한 runtime image가 없거나 미연결 | 승인된 신규 asset과 provider 연결 |
| `OPTIONAL` | 요청 범위 밖이지만 비교 가치가 있는 후보 | 사용자 선택 전 구현·승인 gate에 영향 없음 |

각 asset은 명시적 결정이 없으면 `KEEP`이다. `OPTIONAL` 항목이 미결정이어도
필수 수정 계획을 진행할 수 있다.

## Locked Target Matrix

| 대상 | 분류 | AS-IS | TO-BE | 승인 필요 |
| --- | --- | --- | --- | --- |
| player hull/engine/aim art | `KEEP` + optional candidate | 현재 runtime image 사용 | 현재 유지; flat 시안은 선호 표현만 기록 | 아니오 |
| engine attachment | `FIX` | 이동 중 부착 인상이 어색할 수 있음 | hull transform만 공유, 별도 꺾임 0 | 시각 캡처 |
| orbit blade orientation | `FIX` | blade index가 rotation에 반영되지 않음 | 각 blade forward가 radial outward와 일치 | 아니오 |
| enemy movement speed | `FIX` | 체감상 느림 | 역할별 time-to-contact 측정 후 승인 수치 적용 | 최종 수치 |
| hostile projectile | `REPLACE/FIX` | 작은 core와 얇은 trail이 잘 안 보임 | core truth 유지, 더 명확한 head/tail silhouette | 이미지 시안 |
| ordinary/elite/boss attack cue | `REPLACE/ADD` | 공용 선 문법 비중이 큼 | 등급별 head, cap, fill/pattern 차이 | 이미지 시안 |
| upgrade card | `FIX` + 필요 시 `REPLACE` | 작은 header glyph, 계층/overflow 문제 | 상단 1/3 art → 이름·레벨 → 설명·효과 | panel mock |
| XP pickup | `FIX` | 기계형 3단계 image | 단순 shard geometry, 크기/면 수만 차이 | 간단 시안 |
| floor tile | `ADD` | 절차 mesh, image 미연결 | 현실적이고 단순한 tile + deterministic placement | art+algorithm |
| wall | `ADD` | retained mesh, PNG 미연결 | floor와 명확히 구분되는 topology image | asset set |
| cover/terrain/facility | `REPLACE/FIX` | image와 실제 rect/radius가 다르게 느낌 | 고유 body image + live truth overlay | asset set |
| pickup contact | `FIX` | 종류별 contact 경로 확인 필요 | body/dash swept contact로 정확히 1회 수집 | 아니오 |
| 나머지 actor/secondary/effect/UI | `KEEP` | 현재 semantic-v2 | 사용자가 별도 지정할 때만 재분류 | 아니오 |

## Proposed Design

### Candidate generation

- 필수 `REPLACE/ADD` 대상만 후보를 만든다.
- 한 이미지에는 최대 4개 asset identity만 둔다.
- 현재 에셋을 그대로 쓸 수 있으면 새 이미지를 만들지 않는다.
- text, level, value와 gameplay icon을 panel background에 굽지 않는다.
- 후보는 `candidate`일 뿐 runtime manifest에서 참조하지 않는다.

### Map and terrain

- floor art와 placement algorithm을 별도로 승인한다.
- 첫 algorithm candidate는 현재 288-unit cell, `1×1`, `2×1`, `1×2`,
  `2×2` module을 유지한다.
- tile variation은 field/layout fingerprint와 cell coordinate로 결정한다.
- wall asset은 collision boundary neighbor topology로만 선택한다.
- cover/terrain image는 existing rect/radius를 바꾸지 않는다.
- 무효 문양, rune, 반복 강조 decal은 만들지 않는다.

### Combat readability

- damaging core boundary는 collision truth와 일치한다.
- tail은 방향만 보여주는 non-damaging cue다.
- ordinary/elite/boss는 head silhouette, tail pattern, startup cap 중 2개
  이상이 다르다.
- thin line은 보조 축으로만 사용하며 filled head/cap 없이 단독으로 쓰지
  않는다.
- beam만 full corridor, projectile은 최대 0.4초 lead, charge는 rounded
  endpoint capsule, area는 실제 outer boundary를 사용한다.

### Upgrade card

- card height의 30–34%를 family art slot으로 사용한다.
- 그 아래 이름+레벨, 설명, 실제 효과, optional behavior와 level pip 순서다.
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

1. 현재 inventory와 선택적 수정 범위를 고정한다.
2. 필수 6개 시각 대상만 생성·승인한다.
3. 승인 대상만 productionize하고 인접 runtime 문제를 수정한다.
4. combat/UI와 map/wall/terrain을 각각 검증 가능한 batch로 전환한다.
5. 전체 기능 검증 뒤 마지막으로 성능을 측정한다.

## Tasks

### Phase 0: inventory와 범위 교정

- [x] 현재 390개 PNG의 상태를 CSV로 기록한다.
- [x] 기존 review sheet 11개를 master grid로 합친다.
- [x] 전체 재제작이 아니라 `KEEP` 기본의 선택적 수정으로 계획을 교정한다.
- [x] player foundation 3안은 `OPTIONAL`로 보관한다.

Batch acceptance:

- 기존 runtime 파일 변경 0.
- optional player 후보가 필수 승인 gate를 막지 않음.

### Phase 1: 필수 시각 후보 생성과 승인

- [ ] **1.1 Map floor**: tile primitives와 3개 deterministic output sample.
- [ ] **1.2 Wall**: straight, corner, end, junction topology asset set.
- [ ] **1.3 Terrain**: cover, bulkhead, repair/overdrive/arc/gate를 최대 4개씩.
- [ ] **1.4 Combat**: projectile와 ordinary/elite/boss cue를 최대 4개씩.
- [ ] **1.5 Upgrade card**: 실제 card 비율의 panel/art/text-safe mock.
- [ ] **1.6 XP**: 단순 3단계 shard 시안.
- [ ] 각 필수 후보에 대해 사용자 `approve` 또는 `revise`를 기록한다.

Batch acceptance:

- 필수 6개 대상만 승인됨.
- 나머지 current asset은 자동으로 `REPLACE`되지 않음.

### Phase 2: 승인 대상만 productionize

- [ ] 승인된 후보를 개별 alpha PNG, atlas 또는 9-slice state로 분리한다.
- [ ] canvas, pivot, facing, patch margin과 safe inset을 기록한다.
- [ ] 새 file과 기존 유지 file을 함께 가리키는 최소 manifest diff를 만든다.
- [ ] 미승인·optional 후보는 provider/Theme에서 참조하지 않는다.

Batch acceptance:

- 승인 대상 coverage 100%, 불필요한 새 asset 0.
- `KEEP` path와 hash가 변경되지 않음.

### Phase 3: 비시각 runtime fix

- [ ] engine attachment가 hull transform만 공유하도록 확인·수정한다.
- [ ] orbit blade position angle과 render angle에 같은 blade index를 쓴다.
- [ ] enemy time-to-contact 비교표를 만든 뒤 승인된 speed 값만 적용한다.
- [ ] 모든 pickup 종류의 body/dash swept contact를 검증·수정한다.

Batch acceptance:

- asset replacement 없이 각 behavior fixture가 통과.
- enemy tactics, spawn 수와 attack cadence 변화 0.

### Phase 4: 승인된 combat/UI asset switch

- [ ] projectile head/tail과 attack tier cue를 전환한다.
- [ ] exact live telegraph geometry를 그대로 사용한다.
- [ ] upgrade card art slot과 text hierarchy를 적용한다.
- [ ] card shell 교체는 승인된 경우에만 수행한다.
- [ ] XP를 승인된 단순 표현으로 바꾼다.

Batch acceptance:

- ordinary/elite/boss와 공격 방향을 압력 캡처에서 구분.
- upgrade card locale/viewport overflow 0.

### Phase 5: 승인된 map/wall/terrain switch

- [ ] floor compiler에 승인 tile 이미지를 연결한다.
- [ ] wall topology로 승인 wall image를 선택한다.
- [ ] terrain body 이미지를 바꾸고 live rect/radius overlay만 유지한다.
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
- `KEEP` path/hash leftover guard.

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

- inventory를 replacement backlog로 오해해 다시 전체 재제작할 위험.
- tile/wall image 연결 후 batch/VRAM 비용이 증가할 위험.
- 강한 outline이 군집에서 내부 노이즈로 변할 위험.
- terrain body와 실제 rect/radius가 다시 어긋날 위험.
- UI art slot이 text budget을 침범할 위험.

## Open Questions

- 필수 후보의 세부 시각 선택은 승인 카탈로그에서 순차적으로 확정한다.
- optional player 3안은 필수 결정이 아니다. 현재 이미지를 유지해도 계획은
  진행된다.
- enemy speed 최종 값은 before/after 측정표를 본 뒤 사용자 승인을 받는다.

이 문서가 `active`로 전환되기 전에는 위 선택을 구현 과제로 넘기지 않는다.

## Decision Notes

- 2026-07-31: 현재 에셋 inventory와 master grid를 생성했다.
- 2026-07-31: player foundation 3안을 만들었으나, 사용자는 기체 교체를
  요청하지 않았음을 확인했다. 후보는 `OPTIONAL`로 보관한다.
- 2026-07-31: 전체 재제작 해석을 폐기하고 `KEEP` 기본의 선택적 수정으로
  범위를 교정했다.
- UI panel image + dynamic text/icon 합성 규칙은 유지한다.
- 성능 검증은 승인된 asset/UI 수정이 모두 적용된 마지막에 수행한다.

## Progress

- [x] current inventory CSV와 master grid.
- [x] over-scoped plan correction.
- [x] optional player candidate 3안 보관.
- [ ] 필수 6개 시각 대상 후보 생성·승인.
- [ ] 승인 대상 productionization.
- [ ] targeted runtime fixes/switches.
- [ ] final validation/performance.

## Next Steps

1. player 후보를 필수 gate에서 제외한 상태를 유지한다.
2. 다음 필수 승인 단위로 map floor tile + algorithm preview를 만든다.
3. wall, terrain, combat, upgrade card, XP 순서로 필요한 후보만 만든다.
4. 필수 시안이 확정되면 이 문서를 decision-complete 상태로 갱신하고
   runtime 적용 권한을 확인한다.

## Completion Criteria

- [ ] 필수 6개 시각 대상만 승인·구현·검증됨.
- [ ] `KEEP` asset이 불필요하게 재생성·교체되지 않음.
- [ ] orbit/engine/pickup/speed 인접 수정이 승인 범위대로 동작함.
- [ ] attack direction/tier가 실제 플레이에서 구분됨.
- [ ] upgrade card overflow 0.
- [ ] floor/wall/terrain visual과 gameplay truth가 일치함.
- [ ] 마지막 performance gate 통과.

## Handoff

```text
Goal:
기존 에셋은 유지하고, 명시된 문제 대상만 승인 후 수정·교체한다.

Read first:
.agents/visual-redesign-decision-catalog.md
docs/design/component-sheets/semantic-v3-approval/README.md
docs/design/UI_VISUAL_SYSTEM.md

Execute exactly:
KEEP는 건드리지 않는다.
필수 REPLACE/ADD 후보만 생성하고 승인 전 runtime에 연결하지 않는다.

Validate with:
tools/design/build_visual_asset_approval_catalog.ps1
candidate alpha/dimension/count 검사
runtime diff guard

Stop when:
현재 필수 승인 단위에 대한 사용자 승인 또는 수정 지시가 필요할 때.
```
