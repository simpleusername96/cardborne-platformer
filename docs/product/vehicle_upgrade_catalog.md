---
type: spec
status: active
owner: BK
created: 2026-08-07
last_reviewed: 2026-08-08
canonical_for: Cardborne live vehicle upgrade categories, cards, levels, effects, and offer rules
scope: Run-scoped vehicle upgrade catalog and secondary-slot ownership
related:
  - ./vehicle_game_spec.md
  - ../design/VISUAL_SYSTEM.md
  - ../reports/game-system-review/effects-upgrades-as-is.md
---

# 차량 업그레이드 카탈로그

## 목적과 범위

이 문서는 현재 런에서 등장하는 모든 업그레이드 카드의 분류, 이름,
레벨별 효과, 보조 무기 슬롯 규칙과 보상 제약을 정의한다. 전체 런 구조는
`vehicle_game_spec.md`가 소유한다.

현재 카탈로그는 카드 12장, 선택 가능한 레벨 상태 34개로 구성된다.
Dash와 EMP는 기본 액션으로 유지하지만 관련 업그레이드 카드는 없다.
영구 성장, 적·보스 밸런스, 스테이지 보상량과 미술 방향은 이 문서의 범위가
아니다.

## 구성 원칙

- 플레이어가 효과를 바로 예측할 수 있는 네 분류만 사용한다.
- 비슷한 수치 조정, 간접 표식, 짧은 조건부 강화는 제거한다.
- 한 카드는 하나의 전투 역할만 설명한다.
- `코어`처럼 실제 효과를 설명하지 않는 이름은 사용하지 않는다.
- 모든 카드에는 한국어·영어 이름과 설명, 하나의 의미 기반 이미지 ID가 있다.
- 기존 `Pickup Magnet`의 수집 기능과 3레벨 수치는 유지하되, 카드 이름은
  `수거 범위 / Pickup Radius`로 명확하게 바꾼다.

## 분류

| 분류 ID | 한국어 / English | 판단 기준 | 카드 수 |
| --- | --- | --- | ---: |
| `primary` | 주무기 개조 / Primary Weapon Mods | 기본 탄환의 형태와 충돌 규칙을 바꾼다 | 2 |
| `secondary` | 보조 무기 체계 / Secondary Weapon Systems | 추적 미사일 또는 자율 보조 무기를 바꾼다 | 4 |
| `element` | 공격 속성 부여 / Attack Status Effects | 적격 공격에 화염·독·냉기 상태를 부여한다 | 3 |
| `chassis` | 차체 및 지원 / Chassis & Support | 이동·수거·내구 수치를 영구 변경한다 | 3 |

`category`는 카드가 어느 성장 축에 속하는지만 나타낸다. 보조 무기 슬롯은
`secondary_slot_kind`로 별도 관리한다. 추적 미사일은 `built_in`, 전기장·회전
날개·후방 기뢰는 `optional`이다.

## 공통 기준값

| 체계 | 기본값 |
| --- | --- |
| 펄스 캐논 | 피해 18, 발사 간격 0.12초, 속도 1,120 px/s, 충돌 반지름 7 |
| 추적 미사일 | 1발, 피해 25, 발사 간격 1.35초, 탐색 거리 560, 충돌 반지름 8 |
| Dash | 지속 0.20초, 속도 1,220 px/s, 재사용 대기시간 1.25초 |
| EMP | 피해 62, 반지름 285, 기절 2.1초, 준비 0.42초, 재사용 대기시간 13초 |
| 차체 | 최대 내구도 120, 이동 속도 280 px/s |
| 경험치 조각 | 끌어당김 반지름 92, 최종 수거 반지름 34 |

## 전체 카드

### 주무기 개조 / Primary Weapon Mods

| ID | 한국어 / English | 레벨 | 정확한 효과 |
| --- | --- | ---: | --- |
| `split_muzzle` | 확산 총구 / Split Muzzle | 2 | L1: 매 발사마다 좌우를 번갈아 ±7° 측면탄 1발을 추가한다. 측면탄 피해는 주 탄환의 40%다. L2: −7°와 +7°에 측면탄 2발을 동시에 추가하며, 각각 32.5% 피해를 준다. 주 탄환은 변하지 않는다. |
| `piercing_rounds` | 관통 탄환 / Piercing Rounds | 3 | L1/L2/L3: 주무기 탄환이 각각 적 1명/2명/3명을 관통한다. 단단한 엄폐물은 계속 탄환을 막는다. |

`운동탄 / Kinetic Rounds`은 벽에서 한 번 튕기는 카드가 아니라 단순 피해
배율 카드였으므로 삭제했다. 현재 카탈로그에는 도탄 업그레이드가 없다.

### 보조 무기 체계 / Secondary Weapon Systems

| ID | 한국어 / English | 슬롯 | 레벨 | 정확한 효과 |
| --- | --- | --- | ---: | --- |
| `homing_missiles` | 추적 미사일 / Homing Missiles | 기본 장착 | 2 | 기본은 1발·피해 25다. L1: 서로 다른 표적에 2발, 각 28 피해. L2: 서로 다른 표적에 3발, 각 32 피해. 가능한 표적이 부족하면 기존 표적을 다시 사용할 수 있다. |
| `electric_field` | 전기장 / Electric Field | 선택 슬롯 | 3 | L1: 반지름 120, 8 DPS. L2: 반지름 140, 12 DPS. L3: 반지름 160, 16 DPS. 피해 판정 간격은 0.25초다. |
| `orbiting_blades` | 회전 날개 / Orbiting Blades | 선택 슬롯 | 3 | L1: 날개 2개, 접촉 피해 14. L2: 3개, 피해 18. L3: 4개, 피해 22. 회전 반지름은 78이며, 날개 하나의 대상별 재타격 대기시간은 0.55초다. |
| `drop_mines` | 후방 기뢰 / Drop Mines | 선택 슬롯 | 3 | L1: 피해 48, 3.2초마다 투하, 최대 3개, 폭발 반지름 96. L2: 피해 60, 2.8초, 최대 4개, 반지름 108. L3: 피해 72, 2.4초, 최대 5개, 반지름 120. 수명은 8초, 감지 반지름은 54다. |

추적 미사일은 항상 장착되어 선택 슬롯을 쓰지 않는다. 나머지 보조 무기
세 개 중 최대 두 개만 한 런에서 처음 획득할 수 있다. 이미 획득한 보조
무기는 슬롯이 찬 뒤에도 다음 레벨을 선택할 수 있다.

시각 크기는 판정과 분리한다. 추적 미사일은 충돌 반지름 8을 유지하면서
전용 Seeker image로 표시한다. 후방 기뢰는 감지 반지름 54와 폭발 반지름을
유지하면서 표시 반지름을 44로 키웠다. 회전 칼날도 판정은 유지하고 표시
반지름을 이전의 두 배인 38로 키웠다.

### 공격 속성 부여 / Attack Status Effects

| ID | 한국어 / English | 레벨 | 정확한 효과 |
| --- | --- | ---: | --- |
| `thermal_burn` | 화염 부여 / Thermal Burn | 3 | 적격 공격이 최대 3중첩의 화염을 부여한다. L1/L2/L3: 중첩당 2/3/4 DPS, 지속 3/4/5초. |
| `bio_toxin` | 독 부여 / Bio Toxin | 3 | 적격 공격이 최대 3중첩의 독을 부여한다. L1/L2/L3: 중첩당 2/3/4 DPS, 지속 5/6/7초. |
| `cryo_slow` | 냉기 부여 / Cryo Slow | 3 | 적격 공격이 최대 3중첩의 냉기를 부여한다. L1/L2/L3: 중첩당 이동·공격 속도 6%/8%/10% 감소, 지속 2/2.5/3초. 보스는 감속량과 지속 시간이 절반이다. |

세 속성은 상호 배타적이다. 첫 속성을 획득하면 다른 두 속성은 이후 제안에서
제외되고, 선택한 속성의 다음 레벨만 등장한다. 해당 속성은 주무기 탄환 색에도
반영된다. `소이 코어`, `독성 코어`, `빙결 코어`처럼 불명확한 `코어` 명칭은
사용하지 않는다.

### 차체 및 지원 / Chassis & Support

| ID | 한국어 / English | 레벨 | 정확한 효과 |
| --- | --- | ---: | --- |
| `chassis_speed` | 주행 속도 / Movement Speed | 3 | L1: ×1.08 = 302.4 px/s. L2: ×1.16 = 324.8 px/s. L3: ×1.24 = 347.2 px/s. |
| `pickup_radius` | 수거 범위 / Pickup Radius | 3 | 기존 `Pickup Magnet` 효과를 유지한다. L1: +70 = 162. L2: +140 = 232. L3: +210 = 302. 최종 수거 반지름은 34로 유지한다. |
| `hull_integrity` | 장갑 내구도 / Hull Integrity | 3 | L1: +15 = 최대 135. L2: +30 = 최대 150. L3: +45 = 최대 165. 획득할 때마다 새 최대치 안에서 내구도 15를 즉시 회복한다. |

## 보상과 적용 규칙

전체 카드에는 34개 레벨 상태가 있다. 선택 보조 무기 세 개 중 두 개만 획득하고
속성 뿌리도 하나만 획득하므로 한 런의 합법 풀은 선택에 따라 줄어든다. 합법 ID가
3개 이상이면 정확히 세 장을 제안한다. 진행 끝에서 합법 ID가 3개 미만이면 보상
거래를 자동 종결하며, 스테이지 완료를 막지 않는다.

각 보상은 다음 순서로 처리한다.

1. 호환되며 최대 레벨이 아닌 카드를 모은다.
2. 선택 보조 무기 두 개를 이미 획득했다면 세 번째 무기의 첫 획득만 막는다.
3. 한 속성을 획득했다면 다른 두 속성 뿌리를 막는다.
4. 런 시드, 스테이지, 보상 출처와 일련번호로 결정론적으로 섞는다.
5. 첫 패스에서 가능한 한 서로 다른 분류를 뽑는다.
6. 같은 합법 카드 풀에서 남은 자리를 채워 정확히 세 장을 만든다.
7. 플레이어가 제안된 ID 하나를 선택하고 장착할 때까지 제안을 고정한다.
8. 제안되지 않았거나 오래됐거나 중복 제출된 ID는 빌드를 바꾸지 않고 거부한다.

재추첨, 건너뛰기, 거절, 가짜 대체 카드는 없다.

## 이번 정리에서 삭제한 카드

| 삭제 카드 | 삭제 이유 |
| --- | --- |
| `kinetic_rounds` | 실제 효과가 벽 1회 도탄이 아니라 단순 주무기 피해 배율이었다. |
| `rapid_cycle` | 발사 간격만 줄이는 범용 수치 카드로, 무기 형태를 만드는 선택보다 구분력이 낮았다. |
| `marked_salvo` | 표식 유지, 추적 우선순위, 추가 피해라는 간접 예외를 만들었다. 추적 미사일 자체의 발수와 피해 증가로 통합했다. |
| `coolant_wake`, `phase_shear` | Dash 기본 액션은 유지하되 Dash 업그레이드 계층 전체를 삭제했다. |
| `emp_aftershock`, `static_aegis` | EMP 기본 액션은 유지하되 EMP 업그레이드 계층 전체를 삭제했다. |

이전 19장 카탈로그의 나머지 카드는 삭제하지 않고 의미를 명확히 한 새 ID로
교체했다.

| 이전 ID | 현재 ID |
| --- | --- |
| `forked_muzzle` | `split_muzzle` |
| `phase_lance` | `piercing_rounds` |
| `twin_seekers` | `homing_missiles` |
| `ion_field` | `electric_field` |
| `orbit_blades` | `orbiting_blades` |
| `wake_mines` | `drop_mines` |
| `incendiary_core` | `thermal_burn` |
| `toxin_core` | `bio_toxin` |
| `cryo_core` | `cryo_slow` |
| `tuned_thrusters` | `chassis_speed` |
| `pickup_magnet` | `pickup_radius` |
| `reinforced_hull` | `hull_integrity` |

업그레이드는 런 한정 상태이며 영구 저장 ID 마이그레이션은 필요하지 않다.

## 완료 조건

- 카드 리소스가 정확히 12장, 레벨 상태가 정확히 34개다.
- 분류별 카드 수는 주무기 2, 보조 무기 4, 공격 속성 3, 차체 및 지원 3이다.
- `수거 범위 / Pickup Radius`가 기존 3레벨 수집 효과와 +210 최종 보너스를 유지한다.
- 선택 보조 무기 ID는 `electric_field`, `orbiting_blades`, `drop_mines`이며 최대 두 개만 획득한다.
- 합법 ID가 세 개 이상인 모든 선택 경로에서 서로 다른 합법 카드 세 장을 제안한다.
- 모든 레벨의 한국어·영어 분류, 제목과 실제 수치 변화가 해석된다.
- 각 카드는 실제 효과를 한국어 약 10자·영어 2–5단어로 요약한다. 설명은
  primary text 색상과 compact/standard/large `32/34/36 px` 글꼴을 사용하며
  최대 두 줄로 표시한다. 변화 종류 문장은 화면에서 숨기되 접근성 이름에는
  유지하고, 첫 획득을 포함해 별도 unlock `+` 아이콘은 표시하지 않는다.
- 가장 긴 카드 조합이 960×540, 1280×720, 1920×1080에서 잘리거나 넘치지 않는다.
- 유효·미제안·중복·오래된 카드 적용 사례가 집중 검증을 통과한다.

## 제외 범위

- 새 카드, 카드 이미지, 재추첨, 건너뛰기, 상점, 영구 성장 추가
- 적, 보스, 스테이지, 기본 Dash, 기본 EMP, 보상량 밸런스 변경
- 더 이상 카드가 사용하지 않는 공유 의미 이미지 삭제
- 성능 기준 변경 또는 성능 인증 주장

## 구현 근거

- 카드 데이터: `data/cards/vehicle/`
- 보조 무기 데이터: `data/weapons/vehicle/secondary/`
- 카탈로그와 빌드 규칙: `scripts/cards/vehicle_upgrade_catalog.gd`,
  `scripts/cards/vehicle_run_build.gd`
- 실제 동작: `scripts/vehicle/vehicle_run.gd`,
  `scripts/player/vehicle_secondary_runtime.gd`,
  `scripts/combat/vehicle_status_profile.gd`
- 카드 표시: `scripts/cards/vehicle_upgrade_offer_presenter.gd`,
  `scripts/ui/vehicle_upgrade_choice_card.gd`
- 한국어·영어 문구: `localization/vehicle_stage.csv`
