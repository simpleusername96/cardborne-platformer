---
type: evidence
status: archived
owner: BK
created: 2026-08-07
last_reviewed: 2026-08-07
topic: effects and upgrades AS-IS taxonomy
scope: Pre-reduction 41-card baseline after the minimal-effect pass
source: Current repository implementation and canonical visual specification
related:
  - ../../design/VISUAL_SYSTEM.md
  - ../../product/vehicle_upgrade_catalog.md
---

# Cardborne 이펙트와 업그레이드 AS-IS 구분

## Purpose

2026-08-07의 41장 축소 전 구현을 기준으로 **이펙트**와 **업그레이드**가
각각 무엇을 소유했는지 구분한다. 이 문서는 과거 기준선 근거이며 현재
카탈로그 정본은 `docs/product/vehicle_upgrade_catalog.md`이다.

## Findings

### 핵심 경계

| 구분 | 이펙트 | 업그레이드 |
| --- | --- | --- |
| 핵심 질문 | 지금 무엇이 일어났고, 어디에 영향을 주는가? | 이번 런에서 무엇을 할 수 있고, 얼마나 강한가? |
| 책임 | 전투 사건·상태·범위·소유자를 화면에 전달 | 능력치·행동·무기 구성을 변경 |
| 수명 | 순간 또는 해당 상태가 유지되는 동안 | 획득 후 현재 런이 끝날 때까지 |
| 게임 규칙 변경 | 하지 않음 | 함 |
| 대표 예 | 피격, 폭발, EMP 범위, 조준 경고, 상태 표시 | 피해량 증가, 쿨다운 감소, 새 행동 해금, 보조 무기 강화 |

한 문장으로 줄이면 다음과 같다.

> 업그레이드는 “무엇이 가능하고 얼마나 강한가”를 소유하고, 이펙트는
> “지금 무엇이 일어나며 어디에 영향을 주는가”를 전달한다.

### 1. 이펙트 범주

현재 이펙트는 **버퍼에 저장하는 순간 표현**과 **게임 상태에서 직접 그리는
필수 전달**로 나뉜다. 둘을 모두 별도 이벤트로 만들지 않는다.

#### 1.1 순간 전투 이벤트

`VehicleVisualEventCatalog`에는 실제로 버퍼에 넣어 그리는 이벤트 네 개만
등록되어 있다.

| 이벤트 | 표현 | 남긴 이유 |
| --- | --- | --- |
| `player_dash_afterimage` | 기체 잔상 한 개 | 대시 이동 방향과 순간 변위를 읽게 함 |
| `player_emp_charge` | 실제 EMP 반경 링 | 발동 전에 영향 범위를 정확히 전달 |
| `player_emp_release` | 승인된 EMP 이미지 | 유일한 대형 순간 효과이며 Aftershock도 재사용 |
| `boss_core_reduced_hit` | 실제 피해량·배율 숫자 | 보스 코어 피해 감소라는 예외 규칙을 설명 |
| **합계** | **4개** | |

#### 1.2 이벤트 표현 방식

네 이벤트는 각각 실제 렌더 경로를 하나씩 가진다.

| 현재 표현 모드 | 수 | 의미 |
| --- | ---: | --- |
| `hull_afterimage` | 1 | 대시 잔상 |
| `live_emp_radius` | 1 | 실제 EMP 반경과 일치하는 실시간 범위 |
| `authored_emp` | 1 | 승인된 대형 EMP 래스터 이미지 |
| `floating_damage` | 1 | 보스의 실제 적용 피해와 감소율 |
| **합계** | **4** | |

기존 `direct_feedback`, `suppressed`, `directed_transfer`, `hud_only` 이벤트는
카탈로그와 생성 경로에서 삭제했다. 필요한 정보는 원래 책임자가 직접 그린다.

#### 1.3 지속 상태와 실시간 전투 기하

다음 항목은 플레이어에게 필요한 시각 피드백이지만 순간 이벤트 버퍼에 넣지
않는다.

- 공격 예고선과 목표 지점
- 빔·충전 공격의 실제 통로
- 지뢰 경계
- 방어막과 Ion Field의 실제 반경 및 방어막 피격 점멸
- 화상·중독·빙결 같은 액터 색 변화와 현지화 상태 문구
- Marked, Sheared 같은 전투 상태 표시
- 보스 방어막 노드의 `active → damaged → resolved` 상태
- 대시 엔진 플레어

이 항목은 대체로 **실시간 게임 기하** 또는 **액터 상태 피드백**이 소유한다.
따라서 독립 애니메이션 파일 수만 세면 현재 이펙트 범위를 과소평가하게 된다.

#### 1.4 현재 미디어 경계

- 대형 독립 이펙트 래스터는 EMP 한 종류만 유지한다.
- 작은 필수 피드백은 액터 상태, 공유 큐, 코드 기반 동적 표현으로 직접 처리한다.
- 보이지 않거나 장식뿐인 사건은 빈 이벤트 ID로 남기지 않고 생성 자체를 하지 않는다.
- 보호막·Ion Field는 별도 장식 이미지가 아니라 공유 링과 실제 반경으로 표시한다.
- 투사체, 충전 통로, 빔, 텔레그래프의 위치·길이·폭·반경은 게임플레이가 소유한다.
- 카드 그림은 월드 이펙트를 대신하지 않는다.

### 2. 업그레이드 범주

현재 업그레이드는 41개 카드와 총 83개 레벨 상태로 구성된다.

| 데이터 패밀리 | 카드 수 | 레벨 상태 수 | 현재 성격 |
| --- | ---: | ---: | --- |
| Dash | 4 | 4 | 행동형 4 |
| Defense | 2 | 4 | 행동형 2 |
| Element | 7 | 10 | 행동형 7 |
| Mobility | 4 | 11 | 수치형 4 |
| Primary | 9 | 21 | 행동형 4, 수치형 5 |
| Secondary | 10 | 24 | 행동형 8, 수치형 2 |
| Skill | 5 | 9 | 행동형 3, 수치형 2 |
| **합계** | **41** | **83** | **행동형 28, 수치형 13** |

현재 `hybrid`로 분류된 카드는 없다. 즉, 한 카드가 수치 비교와 새 행동 해금을
동시에 표현하도록 분류된 사례는 현재 0개다.

#### 2.1 수치형 업그레이드

수치형은 기존 규칙을 유지하면서 값을 바꾼다.

- 피해량, 쿨다운, 이동 속도, 체력, 획득 반경 등의 가감
- `add` 또는 `multiply` 방식의 modifier 적용
- 카드 UI에서 현재 값과 다음 값을 `현재 → 다음`으로 비교

#### 2.2 행동형 업그레이드

행동형은 `behavior_id`를 통해 새로운 규칙이나 기존 규칙의 변형을 해금한다.

- EMP 후속 폭발
- 표식 연계
- 관통 또는 위상 효과
- 보호막 순환
- 보조 무기 해금·변형

행동형은 비교할 단일 숫자가 없을 수 있으므로, 설명 문장이 핵심 정보가 된다.

#### 2.3 현재 데이터 패밀리 이름의 주의점

`Mobility`에는 실제 이동 강화만 있는 것이 아니다.

- `tuned_thrusters`
- `dash_capacitor`
- `pickup_magnet`
- `reinforced_hull`

즉, AS-IS의 `Mobility`는 순수 이동 범주라기보다 기체 기반 수치 강화 묶음에
가깝다. 현재 구현을 읽을 때 데이터 패밀리 이름과 실제 플레이 의미를 동일시하면
안 된다.

#### 2.4 보조 무기 구조

보조 무기는 다음과 같이 나뉜다.

- 기본 장착 Seeker: 선택형 슬롯을 소비하지 않는다.
- Seeker 강화 6종: `hunter_firmware`, `marked_salvo`, `phase_seeker`,
  `seeker_cycle`, `seeker_warhead`, `twin_seekers`
- 선택형 보조 무기 4종: Ion Field, Orbit Blades, Wake Mines, Escort Drone
- 선택형 슬롯: 2개
- 따라서 한 런에서 Seeker를 포함해 최대 3개 보조 무기 패밀리를 운용할 수 있다.

#### 2.5 업그레이드 카드 아트의 역할

현재 업그레이드 UI는 41개 카드마다 별도 그림을 두지 않는다. 카드 데이터가
참조하는 의미 아트 ID는 총 16개이며, 그중 10개는 `upgrade/*` 전용 공유
아이덴티티다. 나머지 6개는 EMP, 공통 투사체, Seeker·Drone·Blade·Mine 같은
기존 전투 아이덴티티를 재사용한다. 이 그림의 책임은 카드 내용을 빠르게
식별하게 하는 것이다. 실제 전투 범위, 타격, 상태 지속을 표현하는 이펙트의
책임을 대신하지 않는다.

### 3. 같은 기능에서 두 범주가 만나는 방식

| 업그레이드가 소유하는 것 | 이펙트가 소유하는 것 |
| --- | --- |
| EMP Focus, EMP Capacitor, Aftershock의 성능·행동 변화 | EMP 충전·방출 범위; Aftershock은 같은 방출 표현 재사용 |
| Marked Salvo의 표식 연계 규칙 | 현재 표식 대상과 표식 상태 표시 |
| Phase Shear, Ram Pulse의 행동 해금 | 투사체·충돌·대상 상태가 직접 제공하는 판독 정보 |
| Static Aegis, Aegis Cycle의 보호 규칙 | 보호막 링, 피격 반응, 활성 상태 표시 |
| Ion Field 해금과 레벨별 성능 | 현재 활성화된 실제 피해 반경 |

경계는 다음 두 규칙으로 확인할 수 있다.

1. 카드가 없어도 필요한 기본 전투 전달이라면 이펙트 책임이다.
2. 카드 획득 때문에 판정·수치·행동이 바뀐다면 업그레이드 책임이다.

### 4. 혼동하면 안 되는 항목

- 이펙트는 피해량, 쿨다운, 보호 시간 같은 게임 규칙을 결정하지 않는다.
- 업그레이드 UI는 전투 효과를 직접 실행하거나 해석하지 않는다.
- 카드 아트는 전장 이펙트가 아니며, 전장 이펙트는 카드의 레벨이나 빌드를
  소유하지 않는다.
- 충돌과 실제 범위는 시각 이미지가 아니라 게임플레이 기하가 소유한다.
- 별도 이벤트가 없다는 사실을 전투 기능이 없다는 뜻으로 보면 안 된다.

## Sources

- `scripts/presentation/components/vehicle_visual_event_catalog.gd`
- `scripts/presentation/components/vehicle_visual_event_capture_fixture.gd`
- `scripts/presentation/vehicle_combat_renderer.gd`
- `data/cards/vehicle/*.tres`
- `scripts/cards/vehicle_upgrade_catalog.gd`
- `scripts/cards/vehicle_run_build.gd`
- `scripts/cards/vehicle_upgrade_offer_presenter.gd`
- `docs/design/VISUAL_SYSTEM.md`
- `docs/design/cardborne-universal-art-style-reference.png`

## Limitations

- 이 문서는 2026-08-07 최소 이펙트 정리 후 현재 구현을 설명한다. 이후 이벤트
  카탈로그나 카드 데이터가 바뀌면 수량과 분류를 다시 확인해야 한다.
- 정본 제품 요구사항과 시각 규칙은 각각 `docs/product/vehicle_game_spec.md`와
  `docs/design/VISUAL_SYSTEM.md`가 소유한다. 이 문서는 두 정본을 대체하지 않는다.
- 참조 시트는 스타일 기준일 뿐, 시트 안의 개별 오브젝트나 레이아웃을 승인하지 않는다.
