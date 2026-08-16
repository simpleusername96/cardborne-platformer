---
type: evidence
status: active
owner: BK
created: 2026-08-11
last_reviewed: 2026-08-14
topic: Anomaly Device runtime behavior
scope: Current five-stage Cardborne runtime behavior
source: Current code inspection and focused validation on 2026-08-11
related:
  - ../../../docs/product/vehicle_game_spec.md
---

# 변칙 장치의 현재 동작

## Purpose

현재 실행 코드에서 변칙 장치가 어떻게 배치되고, 피해를 받고, 전투에 영향을
주며, 언제 사라지는지 설명한다. `mystery_device`는 내부 호환 ID이고 화면과
가이드북에는 `변칙 장치 / Anomaly Device`로 표시한다.

## Findings

관측된 배치, 결과, 피해, 생명주기, 공개 정보와 직접 픽업 경계를 아래에 기록한다.

## 배치와 결과

각 스테이지에 정확히 3개를 놓는다. 장치는 시작점에서 도달할 수 있는 96픽셀
그리드 위치를 사용하며 벽·게이트·다른 장치·직접 픽업과 필요한 간격을 둔다.
Gravity/Cryo/Weakpoint 세 결과를 중복 없이 하나씩 배정한다. 할당된 결과
문양은 배치 순간부터 보인다.

| 결과 | 범위 | 시간 | 실제 동작 |
| --- | ---: | ---: | --- |
| 중력 견인 | 480 | 5초 | 범위 안 일반 적을 장치 중심으로 끌어당김 |
| 급속 냉각 | 360 | 3초 | 일반 적 이동과 새 공격 시작을 정지 |
| 약점 노출 | 420 | 5초 | 범위 안 일반 적이 받는 플레이어 피해를 1.25배로 높임 |

결과 순서는 `레이아웃 시드 + 스테이지 ID`로 정해진다. 같은 시드와 스테이지는
같은 결과를 재현하며, 전투 중 결과를 다시 뽑지 않는다. 세 효과는 모두
플레이어에게 유리하고 보스·고정 구조물에는 적용되지 않는다.

## 피해와 생명주기

장치 체력은 90, 충돌·직격 반경은 84다. 플레이어의 `direct` 또는 `area`
피해만 받고 적·접촉·환경 피해는 무시한다.

```text
intact(결과 표시) → 파괴 → resolved(효과 활성) → 효과 종료 → retired
```

- 온전한 장치는 플레이어 이동과 기본탄을 막는다.
- 유효 타격은 체력만 깎으며 표시 문양을 바꾸지 않는다.
- 파괴 순간 결과를 한 번 발동하고 충돌을 제거한다.
- 지속 효과가 있으면 잔해를 기준점으로 유지하고, 효과 종료 뒤 퇴장한다.
- 처치 할당량, XP, 아이템 드롭에는 영향을 주지 않는다.

## 공개 정보와 타이밍 판단

런타임 스냅샷은 배치 순간부터 `outcome`을 공개한다. 첫 타격 공개 알림은 없다.
파괴 순간에는 결과 이름과 실제 영향 대상 수를 한 번 알린다. 이 숫자는 정보만
제공하며 결과, 범위, 지속 시간이나 발동 조건을 바꾸지 않는다. 상황에 따라 대상
수가 0일 수 있으며 자동 대기나 재추첨은 하지 않는다.

## 직접 픽업과 분류 경계

각 스테이지에는 경험치 회수 신호기 4개와 수리 캡슐 10개가 직접 배치된다.
적 목록에는 일반 적, 고정 전투 설치물, 엘리트 변형이 들어가고 필드 오브젝트에는
경험치 조각, 수리, 회수 신호기, 변칙 장치, Transit Gate가 들어간다. 변칙
장치는 중립이고 모든 효과가 플레이어에게 유리하다.

## Sources

- 장치 상태: `scripts/vehicle/vehicle_mystery_device_runtime.gd`
- 런 통합: `scripts/vehicle/vehicle_run.gd`
- 배치·직접 픽업: `scripts/vehicle/vehicle_field_layout_generator.gd`
- 가이드북 수치: `scripts/progression/vehicle_guidebook_stat_adapter.gd`
- 검증: `validate_vehicle_mystery_device_runtime.gd`,
  `validate_vehicle_map_mechanics_integration.gd`,
  `validate_vehicle_field_layout_generation.gd`
