# 시맨틱 비주얼 재작업 v2 비교 시안

이 디렉터리는 현재 runtime과 production component sheet에서 확인된
중복·가독성 문제를 구현 전에 고정하기 위한 비교 시안이다. 시안 자체는
runtime asset이 아니며, 구현 완료 뒤에는 같은 catalog와 renderer에서
재생성한 production sheet로 교체한다.

- `13-visual-taxonomy-asis-tobe.png`: 방어 상태, 보조 무기, 상태 이상,
  속성 탄환과 군집 윤곽선
- `14-attack-telegraph-asis-tobe.png`: 탄환·빔·돌진·범위·지속 장판·소환의
  공격 예고 문법과 보스 목표 안내
- `15-world-layering-asis-tobe.png`: 알고리즘 바닥 타일, 명확한 벽,
  기능성 지형의 3계층 맵

구현 순서와 수용 기준은
`.agents/execplans/2026-07-30-semantic-visual-world-boss-performance-rework.md`를
따른다.

## 생성 근거

세 이미지는 현재 runtime capture와 `system-v1` production sheet를
reference image로 사용해 생성했다.

- 시각 분류: 현재 ring 중복, generic secondary/status/affinity를 왼쪽에
  두고, 독립적인 barrier/field/shield/facility와 무기·상태·속성 문법을
  오른쪽에 배치
- 공격 표시: full-lifetime projectile corridor와 generic circle을 왼쪽에
  두고, projectile/beam/charge/area/persistent/summon lifecycle과 boss
  objective guidance를 오른쪽에 배치
- 맵: 현재 장식 panel/rail과 약한 wall hierarchy를 왼쪽에 두고,
  192-unit floor, raised wall shell, functional terrain을 오른쪽에 배치

생성 이미지는 concept evidence이며 글자나 세부 형상을 그대로 runtime
texture로 복사하지 않는다. runtime catalog와 renderer가 이 관계를 실제
component로 다시 만들어야 한다.

## SHA-256

```text
13-visual-taxonomy-asis-tobe.png
a9442385b03d30c9f2bec3430defb5bd82ff39407f0f1d5db02da9dde8d0e0a5

14-attack-telegraph-asis-tobe.png
cdd2e51b0de7e196e68c451d9a5475059e236988e18d5cd44a9421f2bc13f545

15-world-layering-asis-tobe.png
9ad48e86fc93aa9ba3b5d52d914187e6df9f25a1bf1217432e9382f09b3649d4
```
