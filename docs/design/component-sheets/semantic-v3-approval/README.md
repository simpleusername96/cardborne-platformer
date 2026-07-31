---
type: evidence
status: draft
owner: BK
created: 2026-07-31
topic: Cardborne semantic-v3 visual approval
scope: Current asset inventory and review-only replacement candidates
source: ./00-current-asset-inventory-grid.png
related:
  - ../../UI_VISUAL_SYSTEM.md
  - ../../../../.agents/visual-redesign-decision-catalog.md
  - ../../../../.agents/execplans/2026-07-31-approval-gated-visual-asset-replacement.md
---

# Cardborne 비주얼 에셋 승인 보드

## Purpose

현재 사용 중인 이미지와 미연결 이미지, 절차 생성 표현을 구분하고,
새 후보를 작은 가족 단위로 하나씩 확인하기 위한 검토 디렉터리다.
이 디렉터리의 후보는 승인 전까지 runtime asset이 아니다.

## Sources

- `../00-general-sf-component-master-v1.png`: 승인된 일반 SF 형태 기준.
- `art/gameplay/semantic-v2/asset-manifest.json`: gameplay image identity.
- `art/ui/production/semantic-v2/ui-asset-manifest.json`: UI image state.
- 기존 gameplay/UI review sheet 11개: 현재 마스터 그리드 입력.

## Findings

### 현재 에셋 마스터 그리드

![현재 에셋 마스터 그리드](./00-current-asset-inventory-grid.png)

- 원본 11개 review sheet를 그대로 합성했다.
- 생성형 모델로 기존 에셋을 다시 그리지 않았다.
- 파일 단위 전수 목록은
  [`current-asset-inventory.csv`](./current-asset-inventory.csv)에 있다.
- `05 맵 · 벽 · 지형지물`의 floor/wall 8개는 파일만 존재하며 현재
  런타임에는 연결되지 않았다.

### 첫 승인 단위: player foundation

비교 대상은 player hull, rigid rear engine, manual-aim mount 3개다.
모두 +X/right 방향이며 한 이미지에 정확히 3개만 둔다.

#### 시안 1

![평면 실루엣](./generated/01-player-foundation-flat.png)

- 승인 마스터에 가장 가까운 3–4 plane 처리.

#### 시안 2

![절제된 모듈 레이어](./generated/02-player-foundation-layered.png)

- 큰 실루엣을 유지하면서 기능 plane을 한 단계 더 분리.

#### 시안 3

![윤곽 우선](./generated/03-player-foundation-outline.png)

- 군집 속 1× 판독을 위해 바깥 contour와 negative space를 가장 강하게 사용.

## Review rule

- 먼저 1, 2, 3 중 하나를 선택하거나 수정할 부분을 지정한다.
- 선택된 문법으로 secondary 4종을 다음 승인 단위로 생성한다.
- 모든 필수 가족이 승인되기 전에는 manifest/provider/Theme와 runtime
  코드를 바꾸지 않는다.
- UI panel 이미지는 shell만 소유하고, localized text와 dynamic icon은
  Godot Control child로 올린다.

## Generation note

- built-in ImageGen을 사용한다.
- style reference:
  `../00-general-sf-component-master-v1.png`
- flat chroma source를 생성하고 로컬에서 alpha PNG로 변환한다.
- source와 final을 모두 보관해 배경 제거 문제를 재검증할 수 있게 한다.
