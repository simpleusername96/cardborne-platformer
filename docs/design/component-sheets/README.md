---
type: evidence
status: active
owner: BK
created: 2026-07-30
last_reviewed: 2026-07-30
topic: Selected general-SF visual-system direction seed
scope: Direction evidence for the replacement component grammar
source: ../../../pixel-art-production/evidence/space-hangar-v2/runtime/ko-1280-maximum-pressure.png
related:
  - ../UI_VISUAL_SYSTEM.md
  - ../../../.agents/execplans/2026-07-30-full-visual-system-redesign.md
---

# 일반 SF 전투 컴포넌트 디자인 시안

## Purpose

현재 맵에서 사용하는 역할별 의미를 유지하면서 기존 픽셀 형태를 재사용하지
않는 전체 비주얼 시스템의 선택된 방향 seed다. 이 방향은 전투 컴포넌트에서
시작해 world, effect, HUD와 UI로 확장한다.

이 문서는 `active evidence`이며 정본 spec이나 runtime asset은 아니다. 실제
게임의 visual truth는 runtime descriptor, Godot Theme와 그것으로 생성한
[`system-v1/manifest.json`](./system-v1/manifest.json)이 소유한다.

## Sources

- 현재 최대 압력 gameplay capture: 맵 밝기, 배경 대비, 실제 플레이 크기 확인
- 현재 runtime atlas: 필요한 역할 목록과 semantic color 확인
- `UI_VISUAL_SYSTEM.md`: 일반적인 top-down space-hangar SF, 역할별 색·형태,
  non-pixel combat component 계약

기존 atlas의 실루엣, pixel grid, 장식, 방향별 frame은 디자인 입력으로
사용하지 않았다.

## Findings

![일반 SF 컴포넌트 마스터 시안](./00-general-sf-component-master-v1.png)

| 위치 | 역할 | 형태 기준 |
| --- | --- | --- |
| 1행 | 플레이어, 군집, 근접, 원거리 | wedge, solid chevron, split spear, muzzle bracket |
| 2행 | 지휘, 방벽, 포격, 지원 | twin prong, forward slab, long rail, open cradle |
| 3행 | 수리, 회수, 탄환, 보스 | plus cut, inward chevrons, core/tail, detachable modules |

- 엔진 socket은 플레이어 hull 뒤에 고정되어 있고 thrust 때 flame 길이만
  바뀐다.
- dash는 붉은 원 대신 기체 방향을 유지하는 짧은 afterimage로 표현한다.
- ordinary enemy는 색이 없어도 외곽선과 negative space로 역할을 구분한다.
- repair와 recall은 각각 plus cut과 inward chevron이라 충돌 순간에도
  오인하기 어렵다.
- boss는 원형 blob 대신 비대칭 본체와 외곽 objective module로 구성한다.

## Production handoff

- `01-foundation-tokens.png`와 `10-ui-controls-states.png`는 실제
  `VehicleStageVisualProfile`, catalog registry와 Noto Sans KR provider에서
  생성한다.
- 이후 sheet도 descriptor와 동일한 polygon으로 normalized view,
  gameplay 1×, grayscale, state, anchor, collision overlay를 생성한다.

## Limitations

- 이 이미지는 ImageGen 기반 방향 시안이며 runtime geometry의 정본이 아니다.
- 하단 gameplay-scale strip은 상대 판독성 비교용으로, 실제 collision radius와
  정확한 화면 배율 검증을 대신하지 않는다.
- upgrade glyph, stationary enemy, 다섯 boss 전체와 pressure composite는 아직
  포함하지 않았다.
