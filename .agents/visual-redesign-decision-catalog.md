---
type: evidence
status: draft
owner: BK
created: 2026-07-31
topic: Cardborne visual asset approval catalog
scope: Pre-implementation visual decisions and current-state inventory
source: ../docs/design/component-sheets/semantic-v3-approval/
related:
  - ./execplans/2026-07-31-approval-gated-visual-asset-replacement.md
  - ../docs/design/UI_VISUAL_SYSTEM.md
---

# Cardborne 비주얼 에셋 승인 카탈로그

## Purpose

현재 런타임과 파일 저장소의 시각 truth를 구분하고, 새 후보를 가족별로
하나씩 승인하기 위한 결정 기록이다. 이 문서는 구현 권한이 아니며,
필수 행이 모두 승인될 때까지 runtime asset이나 코드를 바꾸지 않는다.

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
| gameplay static manifest PNG | 124 | 이 중 8개 바닥·벽은 런타임 미연결 |
| runtime gameplay static PNG | 116 | 실제 provider 대상 |
| runtime effect atlas/frame PNG | 123 | 22개 animation identity |
| runtime gameplay 합계 | 239 | static + effect |
| runtime UI PNG | 57 | 13 component의 state 이미지 |
| gameplay review/source PNG | 79 | runtime 미사용 |
| UI review/source PNG | 7 | runtime 미사용 |

### 이미지가 아닌 현재 표현

| 표현 | 현재 방식 | 승인 뒤 목표 |
| --- | --- | --- |
| floor tile | 288-unit vertex-color retained mesh | 승인 tile image를 쓰는 deterministic compiler |
| wall shell | geometry-derived, UV 없는 retained mesh | topology-selected wall image shell |
| 공격 피해 범위 | exact live procedural geometry + 작은 cue image | truth 유지 + 명확한 head/tail/tier image |
| terrain footprint | image body와 procedural rect/ring 혼합 | 고유 image body + 실제 rect/radius overlay |
| upgrade 일부 fallback | 작은 glyph/절차 보조 표현 | top-third family art + image-backed state |

### 현재 기준 그리드

![현재 에셋 마스터 그리드](../docs/design/component-sheets/semantic-v3-approval/00-current-asset-inventory-grid.png)

원본 11개 review sheet를 그대로 합성했으며 생성형 모델로 다시 그리지
않았다. `05 맵 · 벽 · 지형지물`의 floor/wall 8개는 파일은 있지만
현재 런타임에서 사용하지 않는다.

## Approval Queue

상태 값은 `current`, `candidate`, `revise`, `approved`만 사용한다.

| 순서 | 승인 단위 | 현재 기준 | 후보 | 상태 | 결정 |
| ---: | --- | --- | --- | --- | --- |
| 1 | player hull · engine · aim mount | `01-player-weapons.png` | `01–03-player-foundation-*.png` | candidate | 사용자 선택 대기 |
| 2 | secondary 4종 | `01-player-weapons.png` | 미생성 | current | 1번 승인 후 생성 |
| 3 | ordinary enemy 19종 | `02-enemies.png` | 미생성 | current | 2번 승인 후 생성 |
| 4 | boss 5종 · module 10종 | `03-bosses-modules.png` | 미생성 | current | 3번 승인 후 생성 |
| 5 | projectile · attack tier cue | `04`, `07–09` sheet | 미생성 | current | actor grammar 승인 후 생성 |
| 6 | barrier · field · shield · status | `04`, `06` sheet | 미생성 | current | topology 분리 시안 생성 |
| 7 | XP · repair · recall · crate | `04` sheet | 미생성 | current | XP 단순 도형 우선 |
| 8 | effect 22 identity | `07–08` sheet | 미생성 | current | key pose 최대 3종씩 |
| 9 | floor tile · algorithm | `05-world.png`, 현재 compiler | 미생성 | current | tile art와 output 별도 승인 |
| 10 | wall topology 6종 | `05-world.png`, 현재 mesh | 미생성 | current | straight/corner/end/junction |
| 11 | cover · terrain · facility | `05-world.png`, terrain runtime | 미생성 | current | footprint overlay 포함 |
| 12 | HUD · UI panel · upgrade card | `06`, UI sheet 2개 | 미생성 | current | shell/dynamic content 분리 |

## Decision Rules

- 승인되지 않은 후보는 runtime manifest, provider, Theme에서 참조하지 않는다.
- 한 후보 이미지에는 최대 4개 identity만 둔다.
- 승인 마스터의 큰 실루엣, 평면 색, 역할별 negative space를 유지한다.
- 현재의 과도한 기계 디테일, pixel 제약과 의미 없는 장식 문양은
  다음 후보에 계승하지 않는다.
- UI 배경 이미지에는 텍스트, 아이콘, 레벨과 수치를 굽지 않는다.
- map/terrain 후보는 visual과 실제 범위를 같은 이미지에서 비교한다.
- 선택 또는 수정 지시는 이 표의 `결정` 열에 기록한다.

## Recommendations

- 첫 선택에서는 player 3안의 내부 디테일보다는 1× 크기에서의 전후 방향,
  engine 부착 인상과 바깥 contour를 우선 비교한다.
- 한 안을 선택한 뒤 그 문법을 secondary 4종에 그대로 적용해 가족
  일관성을 먼저 확인한다.
- floor/wall은 actor 후보와 별도로 승인해 전투 개체와 배경의 대비를
  독립적으로 조절한다.

## Limitations

- 현재 후보는 review-only다. 선택된 안도 개별 canvas/pivot/alpha와
  runtime scale을 고정하기 전에는 production asset이 아니다.
- master grid는 overview다. 작은 label과 frame detail은 원본 11개 sheet와
  CSV에서 확인한다.
- 이 문서는 적 전략, 보스 패턴과 성능 최적화 결정을 포함하지 않는다.
