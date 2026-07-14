---
type: spec
status: active
owner: BK
created: 2026-07-14
last_reviewed: 2026-07-14
canonical_for: Minimum single-hero contextual combat, equipment, blueprint, material-grade, crafting, repair, passive Spirit Stone, and Stage 1 progression rules
supersedes:
  - ./ARSENAL_EQUIPMENT_PROGRESSION.md
  - ./PLAYER_CHARACTER_SYSTEMS.md
  - ./PROGRESSION_EQUIPMENT_ECONOMY.md
source: Owner decisions through 2026-07-14 and current runtime inspection
related:
  - ../../.agent/execplans/2026-07-14-minimum-equipment-progression-vertical-slice.md
  - ./COMBAT_LOADOUT_DECISION_BRIEF.md
  - ../product/2d_platform_action_card_game_prd.md
  - ./PRODUCTION_UI_CONTRACT.md
  - ../architecture/FIRST_SLICE_ARCHITECTURE.md
---

# 최소 전투·장비·제작 시스템

## Purpose

한 명의 영웅이 근접 도구, 원거리 도구, 방패를 동시에 장착하고, 전투와 탐색에서
얻은 재료·설계도·정령석으로 다음 전투 방식을 바꾸는 Cardborne의 첫 완결
시스템을 정의한다.

첫 목표는 시스템을 생략한 전투 데모가 아니다. 아래 핵심 순환 전체를 구현하되
장비와 재료의 개수만 제한한다.

```text
전투/탐색 -> 재료·설계도·정령석 획득 -> 제작/재제작/수리
 -> 장비 비교와 장착 -> 다음 전투에서 변화 확인 -> 자동 저장
```

현재 생산 경로는 이 사양의 한 Traveler, 상황 공격, 방패 방어, 장비 성장 순환을
사용한다. 이전 세 클래스 데이터는 v1 저장 마이그레이션과 역사 fixture에만 남는다.

## Scope

이 사양이 소유하는 범위:

- 한 영웅의 상황 공격과 방패 방어;
- 근접·원거리·방패·방어구·정령석·소비 아이템 loadout;
- 모델별 행동 차이와 명시적 약점;
- 설계도, 일반/정제 재료, 확정 제작과 재제작;
- 근접/방패 상태와 수리, 활/총 보급과 재장전;
- 패시브 정령석 효과;
- 고정 연습장과 고정 Stage 1의 획득·제작 순환;
- 획득 거래, 프로필 저장과 재실행 복구.

별도 액티브 기술, 스킬 트리, 정령 액티브, 공명 게이지, 장신구, 세 번째 이후
장비 모델, Stage 2 이후 성장, 런타임 랜덤 맵은 이 사양의 첫 목표가 아니다.

## Domain Brief

- **전투 경계:** 공격 의도와 표적 스냅샷을 받아 근접 또는 원거리 행동 하나를
  결정한다. UI와 저장 파일을 알지 못한다.
- **방어 경계:** 장착 방패의 시작, 활성, 정밀 방어, 안정성, 실패를 해결한다.
- **장비 경계:** 장비 모델은 행동과 장단점을 소유한다. 재료 등급이나 정령석
  효과를 직접 계산하지 않는다.
- **제작 경계:** 설계도, 제작식, 재료 등급, 보유 모델, 상태를 검증하고 확정
  결과를 만든다. 무작위 옵션이나 실패 확률을 만들지 않는다.
- **정령석 경계:** 입력 없이 선언된 공격/방어 이벤트에 패시브 결과 하나를
  적용한다. 별도 버튼이나 게이지를 소유하지 않는다.
- **보상 경계:** 적·상자·NPC·정예·제단·Stage 완료 원천을 거래 ID로 정확히
  한 번 정산한다.
- **불변 규칙:** 상태 0, 화살/탄약 0, 미장착 정령석만으로 진행이 막히지 않는다.
- **단순 CRUD 여부:** 아니다. 입력 선택, 전투 상태, 제작 거래, 보상 중복 방지,
  저장 복구가 서로 영향을 준다.

## Product Contract

> 플레이어는 전투 중 무기를 교체하지 않는다. 가까운 유효 위협은 장착 근접
> 도구, 먼 유효 위협은 장착 원거리 도구로 공격하며, 방어 입력은 항상 장착
> 방패를 사용한다. 전리품은 새 행동을 여는 설계도와 익숙한 장비를 강하게 만드는
> 상위 재료로 나뉜다. 정령석은 버튼이 아니라 조건부 원소 패시브다.

성장은 세 질문으로 읽혀야 한다.

1. **행동:** 어떤 근접·원거리·방패 모델을 가져갈까?
2. **투자:** 새 설계도를 제작할까, 익숙한 모델을 상위 재료로 재제작할까?
3. **원소:** 어떤 패시브 정령석 조건을 장착할까?

## Canonical Terms

| 표준 용어 | 의미 | 사용하지 않을 표현 |
| --- | --- | --- |
| 전투 도구 | 근접 도구, 원거리 도구, 방패 세 슬롯. | 클래스 장비, 무기 A/B |
| 장비 모델 | 사용 방식과 약점이 고정된 하나의 장비 종류. | 스킨, 재료 등급 |
| 설계도 | 특정 장비 모델 제작을 영구 해금하는 지식. | 완성 장비, 랜덤 희귀도 |
| 제작 | 해금된 설계도와 일반 재료로 미보유 모델을 만드는 확정 작업. | 장비 드롭, 확률 강화 |
| 재료 등급 | 같은 모델을 다시 만들 때 사용하는 일반/정제 품질 단계. | +1/+2 숫자 이름, 희귀도 |
| 재제작 | 같은 모델을 상위 재료로 확정 성장시키는 작업. | 새 행동, 인챈트 |
| 상태 | 근접 도구와 방패의 현재 마모도. | 파괴 확률, 방어구 내구도 |
| 정령석 | 입력 없이 원소 조건 하나를 제공하는 패시브 장비. | 액티브 기술, 궁극기 |
| 획득 거래 | 보상 원천 하나를 정확히 한 번 적용하는 정산. | 획득 애니메이션 자체 |
| 준비 구역 | 제작, 재제작, 수리, 장착이 가능한 안전 구역. | 전투 중 인벤토리 |

장비의 기본 공격과 방어를 `스킬`이라고 부르지 않는다. 이번 목표에는 `charm`,
`참`, `제압 기술`, `전술 기술`, `Spirit Art`, `공명`이 없다.

## Functional Ownership

| Function | Single owner | Must not duplicate it |
| --- | --- | --- |
| 반복 근거리 피해 | 근접 도구 공격 | 정령석, 방어구 |
| 반복 원거리 해결 | 원거리 도구 공격 | 정령석, 소비 아이템 |
| 피해 방어와 정밀 방어 | 방패 | 방어구, 정령석 |
| 모델 행동 차이 | 장비 모델 | 재료 등급 |
| 영구 직접 수치 성장 | 재료 등급 | 설계도, 정령석 |
| 패시브 원소 조건 | 정령석 | 각 장비 모델의 별도 원소 복사본 |
| 긴급 회복 | 소비 아이템 | 방어구, 정령석 |
| 정확히 한 번 보상 | 보상/프로필 거래 | 적 AI, UI |

모든 대안 장비는 활성 방식, 표적, 전달, 자원, 주 결과, 명시적 약점을 기록한다.
같은 역할의 기존 모델과 적어도 두 축이 달라야 하며 `피해 +10%` 또는 다른 색만으로
새 모델이 될 수 없다.

## Minimum Content Envelope

| Content | First target | Equipped at once |
| --- | ---: | ---: |
| Combat roles | 3 | melee 1 + ranged 1 + shield 1 |
| Combat models | 6 | role별 1 |
| Armor | 2 | 1 |
| Spirit Stones | 2 | 1 |
| Consumables | 1 | 1 |
| Material families | 3 | wallet |
| Material grades | 2 | crafted model별 1 |
| Active skills | 0 | 0 |

## Loadout And Controls

### Preparation loadout

| Slot | Count | Responsibility |
| --- | ---: | --- |
| Melee | 1 | 가까운 위협의 반복 피해. |
| Ranged | 1 | 먼 위협을 화살 또는 발사/재장전으로 해결. |
| Shield | 1 | 전면 방어와 정밀 방어. |
| Armor | 1 | 생존과 이동 부담의 교환. |
| Spirit Stone | 1 | 패시브 원소 조건 하나. |
| Consumable | 1 | 긴급 체력 회복. |

전투 중에는 장비를 변경하지 않는다. 변경, 제작, 재제작, 수리는 준비 구역이나
대장간에서만 가능하다.

### Controls

| Role | Keyboard | Gamepad | Action |
| --- | --- | --- | --- |
| Move | `A/D` | Left stick | 이동. |
| Jump | `Space` | `A` | 공통 점프/2단 점프. |
| Dash | `Shift` or `K` | `B` | 공통 대시. |
| Context attack | `F` | `X` | 근접 또는 원거리 공격 하나. |
| Guard | `G` | `Y` | 장착 방패를 들고/내림. |
| Consumable | `H` | `RT` | 회복 물약 사용. |
| Interact | `E` | `R3` | 상자, NPC, 제단, 대장간, 출구. |
| Pause | `Escape` | `Menu` | 일시정지와 설정. |

Q/R/V 또는 LT에 숨은 액티브 전투 행동을 두지 않는다. 모든 입력은 재지정 가능하고
게임패드에서 한 버튼에 두 전투 행동을 겹치지 않는다.

## Context Attack Resolution

공격 입력은 정확히 하나의 불변 `AttackIntent`를 만든다.

1. 영웅이 바라보는 쪽의 살아 있고 발견된 적을 후보로 만든다.
2. 근접 모델의 실제 판정과 16px 완충 영역에 적 hurtbox가 닿으면 가장 가까운
   적에 근접 공격을 선택한다.
3. 근접 후보가 없으면 원거리 모델이 시야, 사거리, 화살/탄약, 장전 상태를 검증한다.
4. 유효한 원거리 후보가 있으면 원거리 공격을 선택한다.
5. 원거리 후보가 없거나 자원이 없으면 바라보는 방향으로 근접 공격을 실행한다.
6. 선택은 startup에서 고정되고 recovery가 끝날 때까지 바뀌지 않는다.

마지막 선택은 경계에서 0.15초 유지한다. 벽 뒤, 화면 밖, 뒤쪽, 상호작용 물체,
발견하지 않은 적은 자동 표적이 아니다. 조준/범위 표시와 실제 실행은 같은
intent를 사용한다.

## Combat Models

### Melee

| Model | Action | Strength | Explicit weakness |
| --- | --- | --- | --- |
| Traveler Sword | 76px 균형형 연속 베기, damage 2. | 빠른 시작과 안정적 이동 전투. | 긴 리치와 높은 자세 피해가 없다. |
| Hunting Spear | 118px 좁은 찌르기, damage 3, 끝거리 완전 적중. | 안전한 끝거리와 일렬 적. | 36px 이내와 위아래 적에 약하고 recovery가 길다. |

### Ranged

| Model | Action/resource | Strength | Explicit weakness |
| --- | --- | --- | --- |
| Hunting Bow | 520px 직선 화살, damage 2, 12/20 arrows. | 빠른 반복 사격과 이동 대응. | 화살 소비와 낮은 단발 피해. |
| Matchlock | 680px 한 발, damage 5, 5/8 cartridges, 1.35s reload. | 높은 단발 피해와 자세 피해. | 발사 후 긴 공백, 대시가 장전을 취소. |

### Shields

| Model | Action | Strength | Explicit weakness |
| --- | --- | --- | --- |
| Round Shield | 0.08s startup, 120-degree guard, 100 stability. | 빠른 전환과 0.14s 정밀 방어. | 강한 연속 공격에 안정성이 낮다. |
| Tower Shield | 0.30s startup, 160-degree guard, 150 stability. | 넓고 안정적인 전면 방어. | 방어 중 이동 35%, 점프 불가, 측후면 취약. |

모든 방패는 방어 불가 공격과 측후면 공격을 막지 못한다. startup, active,
precise window, guard break, recovery를 시각/소리로 구분한다.

## Armor And Consumable

| Model | Effect | Tradeoff |
| --- | --- | --- |
| Traveler Coat | 기준 방어구, 이동 변화 없음. | 추가 생존 보너스 없음. |
| Reinforced Coat | max HP +2, knockback -15%. | dash cooldown +0.06s. |
| Small Potion | HP 2 회복, 1회. | 최대 체력에서는 소비하지 않음. |

방어구는 상태와 액티브가 없다. 어떤 방어구도 점프, 2단 점프, 대시, 줄 오르기,
숙이기, 낙하 복귀를 제거하지 않는다.

## Passive Spirit Stones

한 번에 정령석 하나만 장착한다. 정령석은 등급, 내구도, 액티브 입력, 재사용
대기시간, 공명 자원, 랜덤 옵션을 가지지 않는다.

| Stone | Passive effect | Weakness |
| --- | --- | --- |
| Ember Spirit Stone | 3초 안의 네 번째 직접 공격이 1 피해 화상을 2회 적용. | 직접 공격 간격이 끊기면 횟수 초기화. |
| Frost Spirit Stone | 정밀 방어 성공 시 공격자를 1.5초 동안 25% 둔화. | 방어 불가 공격과 일반 방어에는 발동하지 않음. |

정령석은 이벤트 ID로 한 공격/방어를 한 번만 처리한다. 도구별 원소 구현을
복제하지 않고 하나의 패시브 해석기가 장착 Stone만 평가한다.

## Blueprints, Materials, And Recipes

### Two growth directions

1. **새 모델 제작:** 다른 행동과 약점을 연다.
2. **같은 모델 재제작:** 상위 재료로 직접 성능만 올린다.

새 모델은 상위 호환이 아니다. 최고 재료 Traveler Sword와 Hunting Bow도 이후
스테이지에서 유효해야 한다.

### Materials

| Family | Grade 1 | Grade 2 |
| --- | --- | --- |
| Metal | Iron Scrap (`rusted_scrap`) | Steel Fragment (`steel_fragment`) |
| Timber | Common Timber (`common_timber`) | Hardwood (`hardwood`) |
| Textile | Rough Fiber (`sky_thread`) | Reinforced Fabric (`reinforced_fabric`) |

기존 `slime_residue`와 `boss_core`는 저장에서 보존하지만 첫 제작식에는 사용하지 않는다.

### Recipes

| Model | Same-grade cost |
| --- | --- |
| Traveler Sword | Metal 5 + Timber 2 |
| Hunting Spear | Metal 3 + Timber 4 |
| Hunting Bow | Metal 1 + Timber 5 + Textile 3 |
| Matchlock | Metal 6 + Timber 3 + Textile 1 |
| Round Shield | Metal 3 + Timber 4 |
| Tower Shield | Metal 6 + Timber 4 |
| Traveler Coat | Metal 1 + Textile 5 |
| Reinforced Coat | Metal 4 + Textile 5 |

기본 모델은 Grade 1 완성품과 설계도로 지급된다. 대안 설계도는 완성 장비를
지급하지 않는다. Grade 2는 해당 모델의 damage +1, stagger/stability +15%,
근접/방패 max condition +20%, 방어구 max HP +1만 적용한다. 행동, 사거리, 폭,
표적 정책, 탄약 최대치, 정령 조건은 변하지 않는다.

모든 제작/재제작은 확정 성공한다. 실패, 파괴, 하락, 무작위 옵션, 동일 모델
복제품이 없다.

## Condition, Repair, And Supply

- 근접 도구와 방패만 상태를 가진다. Grade 1 max 100, Grade 2 max 120.
- 근접은 적어도 한 대상을 맞힌 공격 거래마다 1 감소한다.
- Round Shield는 일반/강/정밀 방어에서 1/3/0 감소한다.
- Tower Shield는 일반/강/정밀 방어에서 1/2/0 감소한다.
- 25% 이하에서 아이콘과 짧은 소리로 경고한다.
- 상태 0은 마모됨이다. damage/stability -15%, recovery +10%만 적용하고 계속 사용한다.
- 같은 등급 주 재료 1개로 max condition의 35%를 수리한다.
- Stage 진입 전 장착 근접/방패가 25% 미만이면 25%까지 무료 정비한다.

| Ranged model | Start/max | Stage minimum | Supply |
| --- | ---: | ---: | --- |
| Hunting Bow | 12/20 arrows | 8 | Arrow bundle +4 |
| Matchlock | 5/8 cartridges | 4 | Cartridge pouch +2, safe reload |

자원 0이면 상황 공격은 근접 fallback을 사용한다. 원거리 도구로만 해결할 수 있는
필수 적, 스위치, 진행문을 만들지 않는다.

## Acquisition And Fixed First Slice

### Arsenal Trial

- 이동, 근접, 원거리, 방어, 준비를 각각 한 짧은 고정 방에서 가르친다.
- 완료와 건너뛰기는 같은 거래로 Traveler Sword, Hunting Bow, Round Shield,
  Traveler Coat, Ember Spirit Stone, Small Potion과 tutorial resolved를 지급한다.
- 재연습은 보상을 다시 지급하지 않는다.
- 완료 4-6분, 건너뛰기 10초 이내를 목표로 한다.

### Ruin Approach Stage 1

| Source | Fixed reward |
| --- | --- |
| NPC task | Hunting Spear blueprint |
| Optional chest | Matchlock blueprint |
| Elite Shield Guard | Tower Shield blueprint + refined materials |
| Spirit shrine | Frost Spirit Stone |
| Stage clear | Reinforced Coat blueprint + refined materials |

필수 경로 총합은 대안 모델 하나와 Grade 2 재제작 하나를 보장한다. 중간 대장간에서
Grade 1 대안을 제작하고, 최종 대장간에서 수리 또는 Grade 2 재제작한 뒤 마지막
전투에서 차이를 확인한다.

모든 하단 구역에는 직접 복귀 경로 또는 즉시 체크포인트 복귀가 있다. 필수/선택
왕복은 공통 이동 지표로 검증하며 장비, 탄약, 상태, 정령석을 경로 조건으로 쓰지 않는다.

## Loot And Feedback

- 재료와 보급은 안전한 바닥에 실제 픽업으로 생성된다.
- 금속은 파편, 목재는 묶음, 섬유는 감긴 천, 화살은 화살통, 탄약은 주머니로
  형태를 구분하고 Grade 2는 테두리/표식을 추가한다.
- 일반 픽업은 접촉 획득하고 낭떠러지/전투 종료 시 안전 회수한다.
- 설계도와 정령석은 `E` 상호작용 후 이름, 슬롯, 행동/효과, 제작 필요 여부를 표시한다.
- 화면 애니메이션은 보상 owner가 성공을 확정한 뒤에만 나타난다.
- 보상과 보이는 아이템은 같은 거래 ID를 사용해 재실행 후 중복되지 않는다.

## Persistence Contract

프로필 v2는 아래 사실을 저장한다.

- 한 hero ID와 한 loadout;
- 재료 wallet;
- 해금 설계도;
- 모델별 제작 등급과 근접/방패 상태;
- 해금/장착 정령석;
- tutorial 완료/건너뛰기;
- 설정, durable unlocks, 적용된 profile transaction IDs.

모든 영구 명령은 복제 데이터에서 검증한 뒤 비용과 결과를 원자적으로 적용하고
staging/backup 저장을 거친다. 앱 재실행 후 설계도, 재료, 등급, 상태, 정령석,
loadout이 복원되어야 한다.

첫 목표에는 다중 프로필과 중간 런 Continue가 없다. v1 재료, 설정, 거래 장부는
마이그레이션에서 보존하고 이전 추가 장비는 고정 salvage와 migration 기록으로 남긴다.

## Requirements

- [ ] 생산 화면에 클래스 선택, 무기 전환, Q/R/V 기술 슬롯이 없다.
- [ ] 한 영웅이 근접, 원거리, 방패를 동시에 장착한다.
- [ ] 상황 공격과 실제 미리보기가 같은 intent를 사용한다.
- [ ] 방어 입력은 항상 장착 방패를 사용한다.
- [ ] 6개 전투 모델은 같은 역할의 다른 모델과 두 기능 축 이상 다르고 약점이 있다.
- [ ] 정령석은 패시브 효과 하나만 제공하고 입력/공명/액티브가 없다.
- [ ] 설계도 획득과 장비 제작은 별도 상태다.
- [ ] 재료 등급은 직접 수치만 바꾸고 행동을 바꾸지 않는다.
- [ ] 제작, 재제작, 수리는 실패·파괴·하락·랜덤이 없다.
- [ ] 상태 0과 원거리 자원 0으로도 Stage 1을 시작하고 완료할 수 있다.
- [ ] 모든 설계도/정령석은 고정 획득처와 정확히 한 번 거래를 가진다.
- [ ] Trial 완료와 건너뛰기는 같은 기계적 프로필 상태를 만든다.
- [ ] 모든 필수 이동 경로는 loadout과 무관하게 통과 가능하다.
- [ ] 모든 영구 획득과 장비 상태는 앱 재실행 후 복원된다.

## Acceptance Criteria

1. 새 프로필이 Trial 또는 Skip 뒤 동일한 기본 loadout으로 Stage 1에 진입한다.
2. 가까운/먼/벽 뒤/뒤쪽/자원 0/경계 거리 시나리오에서 상황 공격 결과가 재현된다.
3. Traveler Sword/Hunting Spear, Hunting Bow/Matchlock,
   Round Shield/Tower Shield의 행동과 약점 차이를 전투에서 확인한다.
4. NPC, 상자, 정예, 제단, Stage clear 보상이 정확히 한 번 적용된다.
5. 첫 완료 필수 보상으로 대안 모델 하나와 Grade 2 하나를 만든다.
6. 대장간 비교값, 명령 결과, 실제 전투값이 일치한다.
7. 상태 0과 화살/탄약 0 fixture에서 진행 불능이 없다.
8. 저장 실패 rollback, backup 복구, v1 -> v2, 앱 재실행 round trip이 통과한다.
9. UI는 `PLAYER_UIUX_REFINEMENT_PLAN.md`의 세 해상도, 포커스, 피드백 검증을 통과한다.

## Non-Goals

- 별도 액티브 기술, 스킬 트리, 정령 액티브, 공명 게이지;
- 세 번째 이후 도구/방어구/정령석, 장신구, 다중 방어구 슬롯;
- 무기별 원소 소켓, 원소 탄약, 랜덤 희귀도/옵션/강화;
- 장비 파괴, 상태 0 사용 금지, 기본 보급을 위한 의무 반복;
- 다중 프로필, 체크포인트 런 중단, 클라우드 저장;
- 장비로만 통과하는 필수 이동 경로;
- 고정 Stage 1 검증 전 런타임 랜덤 지형 생성.

## Related

- `.agent/execplans/2026-07-14-minimum-equipment-progression-vertical-slice.md`
- `docs/product/2d_platform_action_card_game_prd.md`
- `docs/design/PLAYER_UIUX_REFINEMENT_PLAN.md`
- `docs/design/ENEMIES_TRAPS_GIMMICKS.md`
- `docs/architecture/FIRST_SLICE_ARCHITECTURE.md`
