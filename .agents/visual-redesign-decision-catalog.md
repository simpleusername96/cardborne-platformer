---
type: evidence
status: draft
owner: BK
created: 2026-07-31
last_reviewed: 2026-07-31
topic: Cardborne targeted visual asset decisions
scope: Current asset triage and pre-implementation approval decisions
source: ../docs/design/component-sheets/semantic-v3-approval/
related:
  - ./execplans/2026-07-31-approval-gated-visual-asset-replacement.md
  - ../docs/design/UI_VISUAL_SYSTEM.md
---

# Cardborne 선택적 비주얼 수정 승인 카탈로그

## Purpose

현재 에셋 전체를 교체 목록으로 취급하지 않고, 각 항목을 `KEEP`, `FIX`,
`REPLACE`, `ADD`, `OPTIONAL`로 구분한다. 사용자가 명시한 문제만 후보를
만들고 승인하며, 나머지는 현재 runtime asset을 유지한다.

이 문서는 구현 권한이 아니다. 필수 시각 대상이 승인될 때까지 runtime
manifest/provider, Theme와 gameplay code를 바꾸지 않는다.

## Sources

- `docs/design/component-sheets/semantic-v3-approval/00-current-asset-inventory-grid.png`
- `docs/design/component-sheets/semantic-v3-approval/current-asset-inventory.csv`
- `art/gameplay/semantic-v2/asset-manifest.json`
- `art/ui/production/semantic-v2/ui-asset-manifest.json`
- `docs/design/component-sheets/00-general-sf-component-master-v1.png`
- `docs/design/UI_VISUAL_SYSTEM.md`
- 현재 semantic provider, world compiler, terrain runtime와 UI Theme

## Findings

### 현재 이미지 수

| 구분 | 수 | 상태 |
| --- | ---: | --- |
| runtime gameplay PNG | 239 | 기본 `KEEP` |
| runtime UI PNG | 57 | 기본 `KEEP` |
| floor/wall PNG | 8 | 파일은 있으나 runtime 미연결 |
| gameplay review/source PNG | 79 | runtime 미사용 |
| UI review/source PNG | 7 | runtime 미사용 |

### 핵심 해석

- inventory에 있다는 사실은 교체 대상이라는 뜻이 아니다.
- player, ordinary enemy, boss, secondaries와 기존 UI panel은 별도 지시가
  없으면 유지한다.
- 필요한 수정은 map/wall/terrain 연결, attack readability, upgrade card,
  XP 단순화와 runtime behavior 일부다.
- 새 player 3안은 원 요청 밖에서 만들어졌지만 사용자가 더 낫다고
  평가했으므로 optional comparison으로 보관한다.

### 현재 기준 그리드

![현재 에셋 마스터 그리드](../docs/design/component-sheets/semantic-v3-approval/00-current-asset-inventory-grid.png)

원본 11개 review sheet를 재해석 없이 합성했다. `05 맵 · 벽 · 지형지물`의
floor/wall 이미지는 현재 runtime에서 사용하지 않는다.

## Decision Matrix

| 대상 | 분류 | 후보/수정 | 필수 승인 | 현재 결정 |
| --- | --- | --- | --- | --- |
| player hull/engine/aim art | `KEEP` | 기존 runtime 유지 | 아니오 | 유지 |
| 새 player foundation 3안 | `OPTIONAL` | `generated/01–03-player-foundation-*.png` | 아니오 | flat 시안 선호 표현; runtime 교체 미승인 |
| engine attachment transform | `FIX` | 새 art 없이 rigid transform 확인 | 구현 전 캡처 | 예정 |
| orbit blade direction | `FIX` | 새 art 없이 radial outward rotation | 아니오 | 예정 |
| enemy speed | `FIX` | 측정표 후 승인 수치만 적용 | 수치 승인 | 예정 |
| hostile projectile | `REPLACE/FIX` | head/tail 가독성 후보 | 예 | 미생성 |
| ordinary/elite/boss cue | `REPLACE/ADD` | 등급별 head/cap/pattern | 예 | 미생성 |
| upgrade card | `FIX`, 필요 시 `REPLACE` | top-third art와 layout mock | 예 | 미생성 |
| XP pickup | `FIX` | 단순 3단계 shard | 예 | 미생성 |
| floor tile/algorithm | `ADD` | tile art + deterministic preview | 예 | 미생성 |
| wall topology | `ADD` | straight/corner/end/junction | 예 | 미생성 |
| cover/terrain/facility | `REPLACE/FIX` | body image + truth overlay | 예 | 미생성 |
| pickup contact | `FIX` | body/dash swept collection | 아니오 | 예정 |
| 그 외 current asset | `KEEP` | 생성·교체 없음 | 아니오 | 유지 |

## Required Approval Queue

player 후보는 아래 순서에 포함되지 않는다.

| 순서 | 필수 승인 단위 | 한 이미지 최대 항목 | 확인 대상 |
| ---: | --- | ---: | --- |
| 1 | floor tile + algorithm preview | 4 | 실제적·단순, deterministic, 무효 문양 없음 |
| 2 | wall topology | 4 | floor보다 높고 blocker가 즉시 보임 |
| 3 | cover/terrain/facility | 4 | image와 rect/radius truth 일치 |
| 4 | projectile + attack tier cue | 4 | 방향, ordinary/elite/boss, affinity 판독 |
| 5 | upgrade card | 1 card mock | top 1/3 art, 이름·레벨·설명, overflow 0 |
| 6 | XP shard | 3 | 가장 단순한 값 단계 구분 |

## Decision Rules

- 명시적 `REPLACE` 결정이 없는 current asset은 `KEEP`이다.
- `OPTIONAL` 후보의 미결정은 필수 계획을 막지 않는다.
- 후보 한 장에는 최대 4개 identity만 둔다.
- 승인되지 않은 후보는 runtime에서 참조하지 않는다.
- UI background image에는 localized text, icon, level과 value를 굽지 않는다.
- map/terrain 후보는 visual body와 실제 footprint overlay를 함께 비교한다.
- 사용자 선택 또는 수정 지시는 이 문서의 결정표에 기록한다.

## Recommendations

- 다음 생성 대상은 player가 아니라 floor tile + algorithm preview다.
- wall과 terrain은 floor 승인 뒤 같은 world contrast 기준으로 만든다.
- projectile/attack cue는 actor art를 다시 만들지 않고 기존 actor 위에서
  읽히는 방향으로 설계한다.
- player 후보는 이후 사용자가 명시적으로 채택할 때만 productionize한다.

## Limitations

- optional player 이미지는 review sheet이며 개별 canvas/pivot asset이 아니다.
- 필수 후보는 아직 생성되지 않았으므로 이 문서는 `draft`다.
- 적 전략과 보스 패턴 재설계는 이 카탈로그의 결정 대상이 아니다.
