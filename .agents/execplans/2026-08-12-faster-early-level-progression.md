---
type: plan
status: active
owner: BK
created: 2026-08-12
last_reviewed: 2026-08-12
topic: Faster early run leveling through a lower experience requirement curve
scope: Run-scoped XP thresholds, level-up cadence, dependent HUD defaults, fixtures, validation, and product specification
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/product/vehicle_upgrade_catalog.md
  - ./2026-08-11-dense-combat-progression-and-run-completion.md
---

# 초반 레벨업 가속 실행 계획

## Purpose

5스테이지 런의 적 경험치 값과 수거 방식은 유지하면서, 레벨마다 필요한 경험치를
크게 줄인다. 첫 업그레이드는 현재보다 약 두 배 빨리 나오고, 최소 할당량 경로의
전체 업그레이드 선택 횟수는 20회에서 29회로 늘어나야 한다.

이 문서는 조사 대안 목록이 아니라 구현 수치가 고정된 실행 계획이다. 구현이 완료되면
새 공식과 검증된 수치를 `docs/product/vehicle_game_spec.md`에 반영하고 이 계획은 삭제한다.

## Why and Current Context

### 현재 구현

- `VehicleExperienceRuntime.required_experience()`가
  `min(160, 12 + round(3n + 0.55n²))`를 직접 소유한다. `n`은 현재 런 레벨에서
  1을 뺀 값이다.
- 적 한 명의 경험치는 군집 1, 일반 2, 우선 4, 엘리트는 해당 값의 1.5배 올림,
  스테이지 보스는 24다.
- 경험치는 적 처치 즉시가 아니라 경험치 조각을 수거했을 때만 들어온다. 경험치 회수
  아이템은 조각을 끌어올 뿐 경험치를 새로 만들지 않는다.
- 한 번에 여러 레벨 분량을 수거하면 레벨업을 모두 대기열에 넣고, 카드 선택 한 번마다
  하나씩 소비한다. 이 동작은 이미 검증되어 있다.
- 현재 카드 카탈로그는 경로에 따라 48~51회의 합법 선택을 지원한다. 아래 새 곡선의
  최소 할당량 경로 29회는 카탈로그를 소진하지 않는다.

### 로컬 수치 모델

`validate_vehicle_experience.gd`와 같은 방식으로 각 스테이지의 할당량만큼 작성된 적을
세고 보스 경험치 24를 더했다. 이 결정론적 최소 할당량 경로는 스테이지별
`212 / 301 / 374 / 519 / 586 XP`, 총 `1,992 XP`다.

| 기준 | 현재 | 결정된 새 곡선 | 변화 |
| --- | ---: | ---: | ---: |
| 첫 레벨업 요구량 | 12 | 6 | -50.0% |
| 첫 5회 레벨업 누적 | 107 | 54 | -49.5% |
| 첫 10회 레벨업 누적 | 413 | 218 | -47.2% |
| 첫 20회 레벨업 누적 | 1,853 | 1,052 | -43.2% |
| 후기 1레벨 상한 | 160 | 96 | -40.0% |
| 스테이지별 레벨업 수 | 7 / 4 / 2 / 4 / 3 | 9 / 5 / 4 / 5 / 6 | 총 +9회 |
| 최소 할당량 경로 종료 레벨 | 21 | 30 | +9레벨 |

외부 설계 사례는 정확한 계수를 제공하지 않으므로 방향 검증에만 사용한다. 초반 보상을
자주 주고 이후 간격을 늘리라는 진행 곡선 모델은 이번 목적과 맞는다. 반대로 전투 중
선택 화면이 너무 잦으면 흐름을 끊을 수 있다는 슈팅 게임 사후 분석이 있으므로,
수치 검증과 실제 런 확인을 함께 한다. 경험치 곡선 변경 뒤 전체 빌드를 다시
플레이테스트해야 한다는 Diablo II 사후 분석도 최종 검증 범위를 뒷받침한다.

## Scope and Non-scope

### Scope

- 레벨별 경험치 요구량 공식과 명명된 상수
- 새 공식의 정확한 임계값, 초과 경험치 이월, 다중 레벨 대기열 검증
- 스테이지별 최소 할당량 경로 레벨업 수 검증
- 레벨 1 경험치 요구량을 가정하는 HUD 기본값과 테스트 fixture
- 경험치 표시용 캡처 fixture의 유효한 현재값
- 활성 제품 명세의 공식과 검증된 진행 수치
- Web export를 포함한 관련 회귀 검증

### Non-scope

- 적 종류별 경험치 드롭값 변경
- 경험치 조각 생성, 합치기, 끌어당김, 수거 반지름 또는 회수 아이템 변경
- 스테이지 할당량, 적 배치, 보스 보상 또는 카드 제안 규칙 변경
- 레벨업 선택 화면의 일괄 처리, 건너뛰기, 재추첨 또는 자동 선택 추가
- 카드 효과 수치나 적 체력 조정
- 저장 데이터 또는 리소스 스키마 변경

## Assumptions

- 사용자의 “대폭 감소”는 첫 요구량 약 50%, 후기 상한 40% 감소를 의미한다.
- 초반의 기준은 첫 5회 선택 누적 경험치와 Stage 1 레벨업 수다.
- 실제 플레이에서는 조각을 놓칠 수 있으므로 최소 할당량 경로는 획득 가능한 경험치
  예산의 기준이지 실제 시간 보장은 아니다.
- 더 빨라진 성장으로 난이도가 내려가는 것은 이번 변경의 의도된 결과다. 적 체력이나
  공격력을 같은 변경에서 보상 상향하지 않는다.

## Proposed Design

### 결정된 공식

`VehicleExperienceRuntime`에 다음 네 상수를 두고 한 함수에서만 사용한다.

```gdscript
const BASE_LEVEL_REQUIREMENT := 6
const LINEAR_LEVEL_GROWTH := 1.5
const QUADRATIC_LEVEL_GROWTH := 0.32
const MAX_LEVEL_REQUIREMENT := 96
```

```gdscript
min(96, 6 + round(1.5n + 0.32n²))
```

레벨 1부터 20까지 다음 레벨에 필요한 정확한 값은
`6, 8, 10, 13, 17, 22, 27, 32, 38, 45, 53, 61, 70, 80, 90, 96, 96, 96, 96, 96`이다.

선택 이유:

- 첫 요구량 6은 Stage 1 최소 경로의 평균 경험치로 약 4마리이며, 현재 약 8마리에서
  절반으로 줄어든다.
- 첫 5회 선택까지 필요한 경험치도 거의 정확히 절반이다.
- 후기 요구량도 40% 낮아져 “초반만 보정”이 아니라 전 레벨 감소가 된다.
- 총 1,992 XP 경로에서 29회 선택이 발생해 48~51회인 합법 카드 한도와 충분히
  떨어져 있다.
- 경험치 드롭값을 건드리지 않아 적 역할별 보상 비율, 보스 경험치의 의미, 조각 수와
  수거 성능 계약을 보존한다.

### 대안 처리

- 상한만 낮추는 방식은 초반 속도를 바꾸지 않으므로 제외한다.
- 적 경험치를 일괄 배수로 늘리는 방식은 드롭 가치, 보스 비중, 엘리트 반올림과 조각
  합치기까지 같이 바꾸므로 제외한다.
- `7 / 1.75 / 0.38 / 112`와 `8 / 2.0 / 0.4 / 120` 후보는 최소 경로 종료가 각각
  레벨 27과 26이고 첫 요구량도 7과 8이라, 요청한 “대폭” 감소보다 보수적이어서
  제외한다.
- 임계값 배열을 직접 저장하는 방식은 같은 결과를 더 많은 데이터와 경계 처리로
  표현하므로 제외한다.

## Milestones and Tasks

### M1. 런타임 곡선 교체

- [ ] `scripts/progression/vehicle_experience_runtime.gd`에 네 개의 곡선 상수를 추가한다.
- [ ] `required_experience()`를 결정된 공식으로 교체한다.
- [ ] 초과 경험치 이월, 다중 레벨 대기열, 진행 완료 동작은 수정하지 않는다.

Gate: 런타임이 레벨 1~20의 고정 임계값과 일치하고 기존 XP 생명주기 계약이 유지된다.

### M2. 표시 기본값과 fixture 정합성

- [ ] `scripts/ui/vehicle_gameplay_hud.gd`의 레벨 1 fallback/default 요구량을 12에서 6으로 맞춘다.
- [ ] `scripts/vehicle/vehicle_run_capture_gateway.gd`의 레벨 12 경험치를 `37 / 61`로 바꾸고,
  뒤의 `+7` 갱신도 임계값을 넘지 않는 `44 / 61` 상태로 유지한다.
- [ ] `tools/validation/validate_vehicle_build_snapshot.gd`의 레벨 2 fixture를 요구량 8로 맞춘다.
- [ ] `tools/validation/validate_vehicle_guidebook.gd`의 레벨 1 fixture를 요구량 6으로 맞춘다.

Gate: 모든 표시 fixture에서 `0 <= current < required`가 성립하고 HUD fallback이 런타임 시작값과 같다.

### M3. 결정론적 진행 검증 갱신

- [ ] `tools/validation/validate_vehicle_experience.gd`에 레벨 1~20 정확한 임계값 검증을 추가한다.
- [ ] 7 XP 수거가 레벨 2와 이월 1 XP를 만들고, 다음 요구량이 8인지 검증한다.
- [ ] 100 XP 단일 수거가 6레벨을 대기시키고 24 XP를 이월하는지 검증한다.
- [ ] 스테이지별 최소 할당량 경로가 `9 / 5 / 4 / 5 / 6`회, 종료 레벨 30인지 고정한다.
- [ ] `tools/validation/validate_vehicle_rewards_ui_audio.gd`의 새 런 시작 요구량을 6으로 갱신한다.

Gate: 임계값, 이월, 대기열, 스테이지 진행 수치가 모두 하나의 공식과 일치한다.

### M4. 제품 계약과 최종 검증

- [ ] `docs/product/vehicle_game_spec.md`의 이전 공식을 새 공식으로 교체한다.
- [ ] 명세에 첫 요구량 6, 첫 5회 누적 54, 후기 상한 96, 최소 할당량 경로 종료
  레벨 30을 기록한다.
- [ ] 아래 집중 validator와 Web export를 실행한다.
- [ ] 실제 Stage 1 런에서 첫 업그레이드가 초반에 나오고 9회의 업그레이드 흐름이
  정상적으로 이어지는지 확인한다.
- [ ] 구현과 검증이 끝나면 이 계획을 삭제한다.

Gate: 활성 명세, 런타임, HUD, fixture, 자동 검증과 실제 Stage 1 확인이 같은 곡선을 가리킨다.

## Progress

- [x] 현재 공식과 경험치 소유자를 확인했다.
- [x] 적 역할별 드롭값과 경험치 수거 동작을 확인했다.
- [x] 스테이지별 최소 할당량 XP를 `212 / 301 / 374 / 519 / 586`으로 계산했다.
- [x] 세 후보 곡선을 현재 곡선과 같은 경로로 비교했다.
- [x] 카드 카탈로그가 48~51회의 합법 선택을 지원함을 확인했다.
- [x] 구현 공식과 기대 진행 수치를 결정했다.
- [ ] M1~M4 구현과 검증은 아직 시작하지 않았다.

## Next Steps

1. M1에서 `VehicleExperienceRuntime`의 공식만 먼저 교체한다.
2. `validate_vehicle_experience.gd`로 정확한 임계값과 경로 수치를 고정한다.
3. HUD와 fixture의 시작값을 맞춘다.
4. 제품 명세를 갱신한 뒤 집중 검증, Web export, Stage 1 실제 런 확인을 수행한다.

## Test Plan

집중 자동 검증:

```powershell
.\tools\godot.ps1 --headless --script res://tools/validation/validate_vehicle_experience.gd
.\tools\godot.ps1 --headless --script res://tools/validation/validate_vehicle_rewards_ui_audio.gd
.\tools\godot.ps1 --headless --script res://tools/validation/validate_vehicle_build_snapshot.gd
.\tools\godot.ps1 --headless --script res://tools/validation/validate_vehicle_guidebook.gd
.\tools\godot.ps1 --headless --script res://tools/validation/validate_vehicle_run.gd
.\tools\godot.ps1 --headless --script res://tools/validation/validate_vehicle_upgrade_system.gd
.\tools\godot.ps1 --headless --script res://tools/validation/validate_vehicle_stage_ui_layout.gd
```

최종 빌드 검증:

```powershell
.\tools\export_web.ps1
```

수동 확인:

- 새 런의 HUD가 `LV 1 · EXP 0 / 6`으로 시작한다.
- Stage 1 평균 역할 구성에서 첫 선택이 약 4마리 분량의 수거 경험치 안에 열린다.
- Stage 1 최소 할당량과 보스 XP를 모두 수거하면 레벨업이 정확히 9회 발생한다.
- 한 수거에서 여러 레벨이 쌓여도 선택 화면이 하나씩 안전하게 처리되고 전투로 복귀한다.
- 경험치 회수 아이템, 조각 수거, 보스 보상, `EXP MAX`가 이전과 동일하게 동작한다.

## Acceptance Criteria

- 레벨 1~20 요구량이 고정 배열과 정확히 일치한다.
- 첫 레벨 요구량은 6이고 첫 5회 누적 요구량은 54다.
- 후기 요구량은 96을 넘지 않는다.
- 최소 할당량 경로의 스테이지별 레벨업은 `9 / 5 / 4 / 5 / 6`, 종료 레벨은 30이다.
- 적 역할별 경험치 값, 조각 수거, 회수 아이템, 카드 제안 규칙은 바뀌지 않는다.
- 100 XP 단일 수거가 6레벨과 이월 24 XP를 잃지 않고 처리한다.
- 모든 집중 validator와 Web export가 통과한다.
- Stage 1 실제 런에서 첫 업그레이드가 확실히 빨라지고, 연속 선택 또는 보상 대기열
  막힘이 없다.

## Rollback and Safety

- 변경은 런 단위 공식과 그 표시·검증 값에 한정되며 영구 저장 데이터가 없다.
- 문제가 생기면 네 상수와 관련 fixture를 이전 공식으로 되돌릴 수 있다.
- 실제 런 확인이 실패하면 임의로 계수를 미세 조정하지 않는다. 실패한 수거 시점,
  레벨, 보유 카드와 대기열을 기록하고 별도 균형 결정을 연다.
- 기존 경험치 드롭이나 카드 효과를 같은 롤백에 섞지 않는다.

## Risks

- Stage 1의 선택 화면이 7회에서 9회로 늘어 전투 흐름을 더 자주 멈춘다. 실제 런에서
  대기열과 복귀 흐름을 확인하되, 이번 범위에 선택 화면 일괄 처리는 추가하지 않는다.
- 5스테이지 종료 레벨이 21에서 30으로 올라 플레이어 화력이 더 빨리 커진다. 이는
  의도된 결과지만 추후 적 체력 조정 판단은 별도 플레이테스트 근거로 한다.
- 최소 할당량 모델은 모든 조각을 수거한다고 가정한다. 조각을 놓치는 플레이어의 실제
  시간은 더 느릴 수 있으나 회수 아이템과 수거 반지름 계약은 이번에 바꾸지 않는다.
- 경험치 곡선은 많은 빌드 경로에 영향을 준다. 단일 정상 빌드만 보고 완료하지 않고
  전체 런과 서로 다른 카드 선택 경로를 확인해야 한다.

## Open Questions

구현을 막는 미결정 사항은 없다. 체감 난이도와 모달 빈도에 대한 추가 조정은 이 공식의
검증 결과를 근거로 별도 요청에서 다룬다.

## Decision Notes

- 2026-08-12: 드롭값 대신 요구량 공식을 낮추기로 결정했다.
- 2026-08-12: 후보 중 `6 / 1.5 / 0.32 / 96` 곡선을 선택했다.
- 2026-08-12: 자동 수치 모델과 실제 Stage 1 런을 모두 완료 조건으로 두었다.
- 2026-08-12: 현재 입력된 업그레이드 HTML 피드백의 저장·백업 작업은 이 XP 구현과
  독립된 현재 작업으로 유지한다.

## Sources

- Local runtime: `scripts/progression/vehicle_experience_runtime.gd`
- Local drop rules: `scripts/rewards/vehicle_field_drop_rules.gd`
- Local stage cadence model: `tools/validation/validate_vehicle_experience.gd`
- Local upgrade capacity: `docs/product/vehicle_upgrade_catalog.md` and
  `tools/validation/validate_vehicle_upgrade_system.gd`
- [Creating a Casual Game Progression Curve](https://www.gamedeveloper.com/design/creating-a-casual-game-progression-curve)
  — 초반 보상 빈도와 시뮬레이션 기반 곡선 비교의 참고 자료.
- [The game is the boss: A Resogun postmortem](https://www.gamedeveloper.com/business/the-game-is-the-boss-a-i-resogun-i-postmortem)
  — 전투 중 선택 UI가 흐름을 끊을 수 있다는 실제 개발 사례.
- [Postmortem: Blizzard's Diablo II](https://www.gamedeveloper.com/design/postmortem-blizzard-s-i-diablo-ii-i-)
  — 경험치 곡선 변경 뒤 다양한 빌드의 전체 플레이 검증이 필요하다는 사례.
