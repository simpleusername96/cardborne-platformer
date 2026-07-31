---
type: evidence
status: active
owner: BK
created: 2026-07-31
last_reviewed: 2026-07-31
topic: Cardborne targeted visual asset decisions
scope: Current asset triage and pre-implementation approval decisions
source: ../docs/design/component-sheets/semantic-v3-approval/
related:
  - ./execplans/2026-07-31-approval-gated-visual-asset-replacement.md
  - ../docs/design/UI_VISUAL_SYSTEM.md
  - ../docs/design/component-sheets/semantic-v3-approval/01-world-combat-runtime-gap.md
---

# Cardborne 비주얼 정상화 승인 카탈로그

## Purpose

실제 맵·전투·UI 문제를 고치기 위해 scoped asset을 `REUSE`, `FIX`,
`REPLACE`, `ADD`, `OPTIONAL`로 구분한다. inventory grid는 교체·수정 누락을
막는 coverage ledger이며 이 문서의 목적은 grid 관리가 아니라, 각 표현이
실제 게임에서 요구를 충족하는지 승인하는 것이다.

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
| runtime gameplay PNG | 239 | 실제 사용·표현 확인 필요 |
| runtime UI PNG | 57 | 기존 피드백 범위별 확인 필요 |
| floor/wall PNG | 8 | 파일은 있으나 runtime 미연결 |
| gameplay review/source PNG | 79 | runtime 미사용 |
| UI review/source PNG | 7 | runtime 미사용 |

### 핵심 해석

- inventory는 교체·수정 작업의 기준 목록이지만, 목록 작성 자체가 목적은
  아니다.
- 목록의 각 scoped identity는 실제 runtime 결과를 근거로 재사용·수정·교체·
  추가 중 하나를 결정한다. 기존이라고 자동 유지하지 않고, 목록에 있다고
  자동 재생성하지도 않는다.
- 현재 우선 수정은 map/wall/terrain 연결, projectile/attack readability다.
  upgrade card, XP 단순화와 runtime behavior는 그 승인 뒤 이어진다.
- 새 player 3안은 원 요청 밖에서 만들어졌지만 사용자가 더 낫다고
  평가했으므로 optional comparison으로 보관한다.

### 현재 기준 그리드

![현재 에셋 마스터 그리드](../docs/design/component-sheets/semantic-v3-approval/00-current-asset-inventory-grid.png)

원본 11개 review sheet를 재해석 없이 합성했다. `05 맵 · 벽 · 지형지물`의
floor/wall 이미지는 현재 runtime에서 사용하지 않는다.

## Decision Matrix

| 대상 | 분류 | 후보/수정 | 필수 승인 | 현재 결정 |
| --- | --- | --- | --- | --- |
| player hull/engine/aim art | `REUSE` | 이번 필수 범위에서는 기존 runtime 유지 | 아니오 | 유지 |
| 새 player foundation 3안 | `OPTIONAL` | `generated/01–03-player-foundation-*.png` | 아니오 | flat 시안 선호 표현; runtime 교체 미승인 |
| engine attachment transform | `FIX` | 새 art 없이 rigid transform 확인 | 구현 전 캡처 | 예정 |
| orbit blade direction | `FIX` | 새 art 없이 radial outward rotation | 아니오 | 예정 |
| enemy speed | `FIX` | 측정표 후 승인 수치만 적용 | 수치 승인 | 예정 |
| hostile projectile | `FIX`, 필요 시 `REPLACE` | 기존 80×80 계약 integration preview 후 head/tail 후보 | 예 | 코드·이미지 모두 필요 |
| ordinary/elite/boss cue | `FIX`, 필요 시 `ADD` | tier 전달 + footprint fill + 등급별 cap/pattern | 예 | 코드 중심 |
| upgrade card | `FIX`, 필요 시 `REPLACE` | top-third art와 layout mock | 예 | 미생성 |
| XP pickup | `FIX` | 단순 3단계 shard | 예 | 미생성 |
| floor tile/algorithm | `FIX/ADD` | 기존 2종을 deterministic output에 연결한 preview | 예 | PNG가 provider에서 제외됨 |
| wall topology | `FIX/ADD` | 기존 6종을 boundary topology에 연결한 preview | 예 | topology 코드 없음 |
| cover/terrain/facility | `FIX`, 필요 시 `REPLACE` | 기존 body를 전체 rect/radius에 맞춘 preview | 예 | 작은 body와 truth overlay가 분리됨 |
| pickup contact | `FIX` | body/dash swept collection | 아니오 | 예정 |
| 그 외 scoped current asset | `UNREVIEWED` | 실제 runtime 결과로 판정 | 해당 시각 변경 시 | 자동 유지/교체하지 않음 |

## Required Approval Queue

player 후보는 아래 순서에 포함되지 않는다.

| 순서 | 필수 승인 단위 | 한 이미지 최대 항목 | 확인 대상 |
| ---: | --- | ---: | --- |
| 1 | floor 기존 에셋 integration + algorithm | 4 | 실제적·단순, deterministic, 무효 문양 없음 |
| 2 | wall 기존 에셋 integration + topology | 4 | floor보다 높고 blocker가 즉시 보임 |
| 3 | cover/terrain/facility footprint | 4 | image body와 rect/radius truth 일치 |
| 4 | projectile + attack tier contract | 4 | 방향, ordinary/elite/boss, affinity 판독 |
| 5 | upgrade card | 1 card mock | top 1/3 art, 이름·레벨·설명, overflow 0 |
| 6 | XP shard | 3 | 가장 단순한 값 단계 구분 |

## Decision Rules

- scoped asset은 비교 근거가 없으면 `UNREVIEWED`다.
- 기존 에셋은 실제 크기·배경·경로의 integration preview를 통과해야
  `REUSE`로 확정한다.
- `OPTIONAL` 후보의 미결정은 필수 계획을 막지 않는다.
- 후보 한 장에는 최대 4개 identity만 둔다.
- 승인되지 않은 후보는 runtime에서 참조하지 않는다.
- UI background image에는 localized text, icon, level과 value를 굽지 않는다.
- map/terrain 후보는 visual body와 실제 footprint overlay를 함께 비교한다.
- 사용자 선택 또는 수정 지시는 이 문서의 결정표에 기록한다.

## Recommendations

- 다음 산출물은 새 floor 그림이 아니라, 기존 floor/wall 이미지를 실제
  algorithm/geometry에 연결한 preview다.
- wall과 terrain은 floor 승인 뒤 같은 world contrast 기준으로 검증한다.
- projectile/attack cue는 tier/path 코드 계약을 먼저 고정하고, 기존 이미지가
  부족한 head/tail/cap만 새로 만든다.
- player 후보는 이후 사용자가 명시적으로 채택할 때만 productionize한다.

## Limitations

- optional player 이미지는 review sheet이며 개별 canvas/pivot asset이 아니다.
- integration preview와 최종 시각 결정은 아직 승인되지 않았다.
- 적 전략과 보스 패턴 재설계는 이 카탈로그의 결정 대상이 아니다.
