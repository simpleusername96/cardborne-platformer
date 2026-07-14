---
type: plan
status: done
owner: BK
created: 2026-07-14
last_reviewed: 2026-07-14
topic: Minimum complete equipment-progression vertical slice
scope: One hero, contextual combat, fixed tutorial and Stage 1, blueprints, two material grades, crafting, recrafting, repair, passive Spirit Stones, rewards, UI, and persistence
supersedes: 2026-07-14-single-hero-arsenal-migration.md
source: Owner decisions through 2026-07-14 and inspected production code, data, scenes, validators, and active design documents
related:
  - ../../docs/product/2d_platform_action_card_game_prd.md
  - ../../docs/design/COMBAT_EQUIPMENT_CRAFTING.md
  - ../../docs/design/PRODUCTION_UI_CONTRACT.md
  - ../../docs/architecture/FIRST_SLICE_ARCHITECTURE.md
  - ../../docs/data/RUNTIME_CATALOG_INDEX.md
---

# 최소 완결 장비 성장 버티컬 슬라이스 구현 계획

## Goal Definition

### Objective

현재의 Warrior, Archer, Assassin 선택형 런타임을 한 명의 영웅으로 통합하고,
짧은 고정 연습장과 고정 Stage 1 안에서 아래 순환을 실제로 한 번 완주할 수 있게
한다.

```text
전투와 탐색
 -> 보이는 회복/탄약/재료 획득
 -> 상자·NPC·정예·완료 보상으로 설계도 또는 정령석 해금
 -> 대장간에서 제작·재제작·수리
 -> 장비 비교 후 장착
 -> 새 선택을 다음 전투에서 사용
 -> 영구 상태 자동 저장과 재실행 복구
```

이 계획은 시스템을 생략해서 작게 만들지 않는다. **핵심 순환에 필요한 시스템은
모두 구현하고, 각 시스템의 콘텐츠 수만 최소화한다.** 구현은 8개 배치로 진행하며,
각 배치는 현재 소유자, 목표 소유자, 관찰 가능한 완료 조건, 이전 경로 제거 조건을
함께 가진다.

## Why / Context

현재 코드는 세 캐릭터, 다섯 전투 입력, 캐릭터별 장비·숙련, 임시 강화, 카드,
세 개 고정 스테이지와 보스를 실행할 수 있지만, 사용자가 원하는 핵심 판타지인
`한 영웅이 전리품과 설계도로 장비를 만들고 다음 전투 방식을 바꾸는 경험`은 없다.
먼저 이 작은 완결 순환을 검증해야 이후 스테이지, 장비, 기술, 정령, 보스를 늘릴
때 무엇이 재미있는지 근거를 갖고 확장할 수 있다.

### Expected Artifact

- 한 명의 영웅으로 시작하는 생산 실행 경로;
- 건너뛰기 가능한 고정 무기 연습장;
- 한 번의 첫 완료로 핵심 순환을 검증하는 고정 `Ruin Approach` Stage 1;
- 근접·원거리·방패 각 2개, 방어구 2개, 정령석 2개의 실제 데이터와 동작;
- 설계도, 2개 재료 등급, 제작, 재제작, 수리, 탄약, 필드 보상;
- 현재 장비와 결과를 비교할 수 있는 준비/대장간 UI와 전투 HUD;
- 프로필 v2 마이그레이션, 자동 저장, 재실행 복구;
- 집중 검증 스크립트, 전체 회귀 결과, 렌더링된 UI 증거;
- 완료 시 `status: done`으로 전환된 이 계획과 최신화된 정식 문서.

## Scope / Non-Scope

### In Scope

- 한 명의 영웅과 근접·원거리·방패의 상황 기반 전투;
- 방어구와 패시브 정령석을 포함하는 최소 장비 세팅;
- 설계도, 재료 등급, 제작, 재제작, 수리, 상태, 화살·탄약 보급;
- 건너뛰기 가능한 고정 연습장과 고정 Stage 1의 완결 성장 순환;
- 필드 픽업, 상자, NPC, 정예, 제단, 스테이지 완료 보상;
- 준비/대장간 화면, 전투 HUD, 획득·제작 결과 피드백;
- 기존 프로필의 v2 마이그레이션, 원자적 자동 저장, 재실행 복구;
- 이전 클래스 중심 생산 경로 제거와 관련 회귀 검증.

### Non-Scope

- 액티브 기술, 기술 슬롯, 스킬 트리, 액티브 정령술;
- 런타임 랜덤 지형 생성과 Stage 2 이후 콘텐츠 확장;
- 세 번째 이상의 장비 모델, 재료 계열·등급, 정령석 원소;
- 확률 강화, 랜덤 옵션, 장비 파괴, 필수 반복 파밍;
- 다중 저장 슬롯, 중간 런 저장, 클라우드 저장;
- 카드 시스템의 장비 중심 재설계.

## Decisions Locked With The Owner (2026-07-14)

| Topic | Locked decision | Source / note |
| --- | --- | --- |
| Scope strategy | 시스템 수를 줄이지 않고 콘텐츠 수를 줄인다. | 사용자가 제작·설계도·성장을 핵심으로 명시했다. |
| Player identity | 생산 게임에는 한 명의 동일한 영웅만 존재한다. 클래스 선택과 클래스별 프로필은 제거한다. | 단일 캐릭터 장비 성장 방향. |
| Combat tools | 근접 도구 1개, 원거리 도구 1개, 방패 1개를 동시에 장착한다. | 무기 전환 메뉴 없이 거리와 상황이 사용 도구를 정한다. |
| Input | `공격`은 근접/원거리를 상황에 따라 선택하고 `방어`는 항상 방패를 사용한다. | 공격과 방어 판단을 분리한다. |
| Skills | 별도 액티브 기술, 기술 슬롯, 스킬 트리는 이번 계획에서 만들지 않는다. | 기술 내용과 역할이 합의되지 않았으므로 임의 설계를 금지한다. |
| Spirit Stone | 정령석은 장착형 패시브 장비다. 액티브 정령술, 공명 게이지, 전용 입력이 없다. | 사용자의 명시적 교정. |
| Growth axes | 새 설계도는 행동을 바꾸고, 상위 재료 재제작은 같은 행동의 직접 성능을 높인다. | 행동 선택과 수치 성장을 분리한다. |
| Equipment breadth | 근접 2, 원거리 2, 방패 2, 방어구 2, 정령석 2만 구현한다. | 선택 가능성을 증명하는 최소 데이터 수. |
| Materials | 금속·목재·섬유 3개 계열과 일반·정제 2개 등급만 사용한다. | 제작식을 읽기 쉽게 유지한다. |
| Condition | 근접 도구와 방패만 상태를 가진다. 0에서도 파괴되거나 사용 불가가 되지 않는다. | 수리 의미는 유지하고 진행 불능은 금지한다. |
| Ranged supply | 활은 화살, 화승총은 탄약과 재장전을 사용한다. 스테이지 시작과 고정 보급으로 최소량을 보장한다. | 이전 스테이지 반복을 강제하지 않는다. |
| Stage generation | 연습장과 Stage 1은 승인된 고정 배치다. 런타임 랜덤 지형 생성은 비활성 상태를 유지한다. | 전체 게임플레이를 먼저 확정한다. |
| Tutorial | 연습장은 건너뛸 수 있고 완료와 건너뛰기는 같은 기본 장비·정령석·저장 상태를 정확히 한 번 지급한다. | 스킵으로 약한 프로필을 만들지 않는다. |
| Persistence | 우선 한 개 로컬 프로필을 자동 저장하고 재실행 시 불러온다. 다중 슬롯과 중간 런 저장은 확장 범위다. | 핵심 영구 성장만 먼저 검증한다. |
| Existing work | 이동, 피해, 공격 표현, 적, 보상 거래, 필드 픽업, 고정 방, 체크포인트, 프로필 백업을 재사용한다. | 처음부터 다시 만들지 않는다. |

## Assumptions And Open Questions

현재 구현을 시작하는 데 사용자 답변이 필요한 항목은 없다. 아래 항목은 첫
플레이테스트에서 조정할 수 있는 수치이며 시스템 구조를 바꾸지 않는다.

| Topic | Working default | Why it can wait | Adjustment rule |
| --- | --- | --- | --- |
| Exact damage and enemy health | 기존 `Ruin Approach` 전투 시간을 기준으로 아래 상대 수치를 적용한다. | 체감 튜닝은 실제 조작 후에만 정확하다. | 모델 정체성, 도달 거리, 입력 리듬은 유지하고 수치만 조정한다. |
| Material totals | 첫 완료에서 대안 장비 1개 제작과 장비 1개 정제 재제작이 각각 보장된다. | 비용의 정확한 양은 플레이 시간에 따라 바뀔 수 있다. | 최소 보장보다 낮추지 않고 과잉만 줄인다. |
| Condition drain | 한 Stage 1 완료에서 주력 근접/방패 상태가 약 20-35% 감소하도록 시작한다. | 적중 횟수와 방어 빈도에 따라 달라진다. | 한 번의 첫 완료에서 0이 되지 않게 한다. |
| Tutorial duration | 완료 4-6분, 스킵 10초 이내를 목표로 한다. | 실제 읽기·조작 속도가 필요하다. | 설명문을 늘리지 않고 공간과 적 행동으로 조정한다. |

다음 항목은 의도적으로 미해결 상태로 유지하며 구현하지 않는다.

- 액티브 기술의 개수, 입력, 획득 방식, 스킬 트리;
- 정령석의 세 번째 이후 원소와 장기 성장 방식;
- 다중 저장 슬롯, 체크포인트 런 중단, 클라우드 저장;
- Stage 2 이후 재료 등급과 장비 모델 수;
- 카드 시스템을 장비 중심으로 재설계할지 여부.

## Canonical Domain Language

| Term | Meaning in this plan | Not this |
| --- | --- | --- |
| 전투 도구 | 근접 도구, 원거리 도구, 방패 세 슬롯의 총칭. | 클래스, 무기 A/B |
| 장비 모델 | 사용 방식과 장단점이 고정된 하나의 장비 종류. | 등급, 스킨 |
| 설계도 | 특정 장비 모델 제작을 영구 해금하는 지식. | 완성 장비, 소비 재료 |
| 제작 | 해금된 설계도와 재료로 아직 만들지 않은 모델을 소유 상태로 만드는 확정 작업. | 무작위 드롭, 확률 강화 |
| 재료 등급 | 같은 모델을 다시 만들 때 사용하는 일반/정제 품질 단계. | 희귀도 색상, 랜덤 옵션 |
| 재제작 | 같은 모델을 상위 재료로 확정 갱신하는 작업. 행동은 그대로이고 직접 성능만 오른다. | 새 설계 제작, 인챈트 |
| 상태 | 근접 도구와 방패의 현재 마모도. 0이어도 사용할 수 있다. | 파괴 확률, 방어구 내구도 |
| 정령석 | 공격 또는 방어의 선언된 조건에 패시브 원소 결과 하나를 더하는 장비. | 액티브 기술, 궁극기 |
| 획득 거래 | 보상 원천 하나를 정확히 한 번 적용하는 식별 가능한 정산. | 화면 애니메이션 자체 |
| 준비 구역 | 제작, 재제작, 수리, 장착을 허용하는 안전한 화면 또는 대장간. | 전투 중 인벤토리 |

사용자 화면에서 `charm`이나 `참`을 사용하지 않는다. 이번 계획에는 장신구 슬롯
자체가 없다. 장비의 기본 동작을 `스킬` 또는 `패시브 스킬`이라고 부르지 않고
`공격`, `방어`, `장비 특성`, `정령석 효과`로 구분한다.

## Progress State

### Completed

- [x] 공통 이동은 달리기, 점프 버퍼, 코요테 타임, 2단 점프, 대시, 숙이기,
  일방 통행 낙하, 줄 오르기를 지원한다.
- [x] `StageBase`와 `FallResetZone`은 낙하 시 최근 체크포인트로 복귀시킨다.
- [x] `AttackDefinition`, `PlayerCombatController`, 공격 프레젠터, 투사체,
  피해 해석과 피격 피드백이 존재한다.
- [x] Walker, Shooter, Charger, Shield Guard를 포함한 적과 보상 원천이 존재한다.
- [x] `RewardTransaction`과 프로필 거래 장부가 중복 보상 방지 기반을 제공한다.
- [x] `FieldPickup`과 `RewardReceiptPresenter`가 필드 획득과 짧은 수령 표시를 제공한다.
- [x] `EquipmentDefinition`, `EquipmentCatalog`, `ProfileData`,
  `ProfileCommandService`, `ProfileSaveService`가 영구 장비·재료·백업 저장 기반을 제공한다.
- [x] 한 Traveler가 상황 공격, 방패 방어, 장비·설계도·재료·정령석을 소유한다.
- [x] 8개 장비 모델, 2개 정령석, 6개 재료, 2개 등급, 제작·재제작·수리,
  상태, 화살·탄약이 typed Resource와 원자적 명령으로 동작한다.
- [x] 프로필 v2 마이그레이션, 자동 저장, backup 복구, 재실행 round trip이 통과한다.
- [x] 고정 Arsenal Trial의 완료/스킵 동등성과 고정 Stage 1 획득·제작 순환이 동작한다.
- [x] Hero Preparation, Forge, 장비 중심 HUD, 상호작용/획득 receipt가 생산 UI다.
- [x] 클래스 선택, class HUD, active skill 입력, RestForge, 임시 affix, 구 장비 드롭이
  생산 실행에서 제거되었다.
- [x] 고정 레이아웃 V5의 세 normal stage, 복귀 경로, boss, settlement가 통과한다.
- [x] 활성 Full release matrix 68개와 세 해상도 렌더링 QA가 통과했다.

## Guiding Implementation Principle

> **시스템 완결성은 유지하고 콘텐츠 수만 제한한다.** 각 기반 작업은 다음
> 배치에서 플레이어가 직접 사용할 수 있는 경로를 열어야 하며, 두 배치 이상
> 연속으로 데이터 구조만 만들지 않는다.

추가 불변식:

- UI는 프로필, 제작, 전투 소유자의 스냅샷만 표시하고 상태를 직접 수정하지 않는다.
- 한 보상 원천은 하나의 거래 ID를 사용하고 저장 복구 후에도 한 번만 적용된다.
- 장비 모델, 재료 등급, 정령석은 서로의 책임을 대신하지 않는다.
- 필수 이동과 스테이지 완료는 장착 모델, 탄약, 상태, 정령석과 무관하게 가능하다.
- 상태 0이나 탄약 0은 불리한 상태일 수 있으나 플레이 불가능 상태가 될 수 없다.
- 상황 공격 미리보기와 실제 공격은 동일한 `AttackIntent` 결과를 사용한다.
- 사용자가 거부한 액티브 정령술, 공명, 제압/전술 슬롯을 호환 명목으로 남기지 않는다.

## Source Map

### Instruction And Product Sources

- `AGENTS.md`
- `.agent/AGENTS.md`
- `.agent/PLANS.md`
- `.agent/Documentation.md`
- `docs/product/2d_platform_action_card_game_prd.md`
- `docs/design/COMBAT_EQUIPMENT_CRAFTING.md`
- `docs/design/PLAYER_UIUX_REFINEMENT_PLAN.md`
- `docs/architecture/FIRST_SLICE_ARCHITECTURE.md`
- `docs/data/RUNTIME_CATALOG_INDEX.md`

### Runtime Owners Inspected

- Player and combat: `scripts/player/PlayerController.gd`,
  `PlayerCombatController.gd`, `CharacterKit.gd`, `AttackDefinition.gd`,
  `scripts/player/combat/*CombatRuntime.gd`, `scenes/player/Player.tscn`.
- Profile and equipment: `scripts/progression/EquipmentDefinition.gd`,
  `EquipmentCatalog.gd`, `scripts/profile/ProfileData.gd`,
  `ProfileCommandService.gd`, `ProfileSaveService.gd`,
  `scripts/autoload/ProfileState.gd`.
- Run and rewards: `scripts/autoload/RunState.gd`, `RunDirector.gd`,
  `scripts/progression/Reward*.gd`, `scripts/items/FieldPickup*.gd`.
- Stage: `scripts/stages/StageBase.gd`, `StageCheckpoint.gd`, `FallResetZone.gd`,
  `ChestInteractable.gd`, `StageRewardInteractable.gd`,
  `scripts/stages/production/ProductionStageHost.gd`,
  `scripts/generation/CuratedStagePlanBuilder.gd`.
- UI: `scripts/ui/production/CharacterSelect.gd`, `RestForge.gd`,
  `ProductionHUD.gd`, `RewardReceiptPresenter.gd`, shared production components.
- Data: `data/characters/`, `data/skills/`, `data/equipment/`, `data/rewards/`,
  `data/items/`, `data/rooms/lower_ruins/`, `data/generation/`.
- Validation: `tools/validate_character_*`, `validate_*combat*`,
  `validate_equipment_*`, `validate_profile_*`, `validate_reward_*`,
  `validate_curated_stage_plans.gd`, `validate_fixed_*`,
  `validate_gameplay_hud.gd`, `validate_shell_ui.gd`, release candidate scripts.

## Evidence Rules

- 사용자의 2026-07-14 교정과 이 계획의 `Decisions Locked`가 목표 기능의 최우선
  근거다.
- 현재 코드와 집중 검증은 배포된 동작의 근거이며, 목표 설계의 근거가 아니다.
- 정식 사양은 이 계획과 같은 결정으로 먼저 정렬한 뒤 구현한다. `정령술`,
  `공명`, `제압/전술 슬롯`, `12개 도구`가 남은 문구는 이전 제안의 잔재다.
- 기존 클래스 런타임은 재사용 후보이지 유지해야 할 제품 계약이 아니다.
- 수치 튜닝은 `working default`, 사용자 결정은 `locked`, 미합의 기능은
  `unresolved/out of scope`로 표시한다.
- 작은 코드 배치는 별도 증거 문서를 만들지 않는다. 변경 파일, 집중 테스트,
  커밋과 이 계획의 체크 상태를 증거로 사용한다.
- UI 완료 주장은 실제 960x540, 1280x720, 1920x1080 캡처와 포커스 검증이
  있어야 한다.

## Current-State Evidence Map

| Concern | Current owner(s) | Observed behavior / problem | Plan handling |
| --- | --- | --- | --- |
| Player identity | `CharacterCatalog`, `RunState.selected_profile`, `CharacterSelect` | 세 프로필이 이동, 전투, 장비, 숙련, 카드 호환성을 소유한다. | 공통 영웅 스냅샷으로 교체하고 이전 ID는 마이그레이션 경계에만 둔다. |
| Combat inputs | `CharacterKit`, `PlayerCombatController.try_start_input()` | `attack`, `heavy_attack`, `skill_1..3` 다섯 정의를 캐릭터 키트에서 찾는다. | `attack`은 상황 공격, `guard`는 방패로 분리하고 기술 입력은 생산 전투에서 제거한다. |
| Attack geometry | `AttackDefinition`, `PlayerAttackPresenter`, hitbox/projectile code | 실제 판정 기반은 있으나 근접/원거리 선택과 공통 의도 스냅샷이 없다. | `AttackIntentResolver`가 하나의 결과를 만들고 프레젠터와 실행기가 같이 사용한다. |
| Equipment data | `EquipmentDefinition`, `EquipmentCatalog` | `weapon/armor/charm/relic`과 클래스 호환성, 12개 고정 ID를 강제한다. | `melee/ranged/shield/armor/spirit_stone` 모델과 제작 정의로 교체한다. |
| Persistent state | `ProfileData` schema v1 | 클래스별 loadout, 장비 ID 집합, 네 기존 재료, 숙련을 저장한다. | 한 영웅 loadout, 설계도, 제작 장비 상태, 정령석, 재료, 거래 장부를 가진 v2로 마이그레이션한다. |
| Profile commands | `ProfileCommandService`, `ProfileState` | 발견·구매·장착·숙련만 지원하며 제작 등급·상태를 모른다. | `unlock_blueprint`, `craft`, `recraft`, `repair`, `equip`, `unlock_spirit_stone` 명령을 단일 소유자로 둔다. |
| Temporary forge | `RunState.begin_forge_offer/commit_forge_affix`, `RestForge` | 코인으로 한 런 임시 무작위 후보 3개 중 하나를 고른다. | 생산 UI와 순환에서 제거하고 확정 제작·재제작·수리로 대체한다. |
| Rewards | `RewardEntry`, `RewardService`, reward tables | 화폐와 완성 장비 발견을 거래로 정산한다. 설계도/정령석 타입은 없다. | 보상 타입을 확장하고 필드 표현과 영구 거래를 같은 ID로 연결한다. |
| Field pickup | `FieldPickup`, `FieldPickupDefinition`, receipt presenter | 체력, 코인, 기존 재료, 보조 효과를 접촉 획득한다. | 금속·목재·섬유, 화살·탄약을 모양과 이름이 다른 실제 픽업으로 확장한다. |
| Stage topology | `CuratedStagePlanBuilder`, lower-ruins rooms, fixed layout V3 | Stage 1은 고정이지만 새 획득·중간 대장간 순환을 가르치지 않는다. | 고정 방/앵커를 재구성해 획득-제작-시험 순서를 보장한다. |
| Fall recovery | `StageBase`, `FallResetZone`, `ProductionStageHost` | 체크포인트 복귀와 월드 하한 안전망이 이미 있다. | 유지하고 연습장/개정 Stage 1 전체 낙하 경로를 다시 검증한다. |
| Preparation UI | `CharacterSelect`, `EquipmentDecisionPanel` | 클래스 선택, 클래스별 장비·숙련을 한 화면에 구성한다. | 한 영웅의 장비 5칸과 제작 결과 비교 화면으로 교체한다. |
| Forge UI | `RestForge` | 회복·소비재·임시 affix를 코인으로 구매한다. | 제작/재제작/수리 세 명령과 재료 비교만 표시한다. |
| HUD | `ProductionHUD` | 클래스 이름, 6개 액션 슬롯, 클래스 자원을 표시한다. | HP, 공격 의도, 탄약, 방패/근접 상태, 정령석 효과, 소비 아이템만 표시한다. |
| Persistence UX | `ProfileSaveService`, `ProfileState` | 자동 저장과 백업은 있으나 장비 성장 v2를 모른다. | 같은 단일 프로필 경로를 유지하고 모든 영구 명령 후 원자적 자동 저장 및 복구를 검증한다. |

## As-Is / To-Be Delta Map

| Concern | As-is | To-be | Acceptance check | Guard / leftover check |
| --- | --- | --- | --- | --- |
| Entry | Main Menu -> Character Select -> 세 프로필 중 하나. | Main Menu -> 첫 실행 Trial/Skip -> 한 영웅 준비 화면 -> Stage 1. | 키보드/게임패드로 완료·스킵 양쪽이 Stage 1에 진입한다. | 생산 화면에 Warrior/Archer/Assassin 선택 카드가 없다. |
| Loadout | 클래스별 weapon/armor/charm/relic/consumable. | melee/ranged/shield/armor/spirit_stone/consumable 한 벌. | 저장-재실행 후 장착과 실제 전투 동작이 동일하다. | `loadouts[character_id]` 생산 쓰기가 없다. |
| Attack | 캐릭터 기본/강공격/기술을 입력별 직접 조회. | 한 공격 입력이 근접 우선, 유효 원거리 차선, 근접 fallback 중 하나를 결정한다. | 경계 거리·벽·뒤쪽·탄약 0 시나리오가 반복 가능하다. | UI와 실행기가 별도 표적 계산을 하지 않는다. |
| Defense | G가 캐릭터 Heavy이고 일부 효과만 방어한다. | G/게임패드 Y는 항상 장착 방패의 방어 상태를 실행한다. | 일반/정밀/강공격/측후면/방어 불가 공격이 규칙대로 처리된다. | `heavy_attack`이 생산 방어 입력으로 남지 않는다. |
| Skills | 세 클래스가 각 3개 기술과 HUD 슬롯을 가진다. | 이번 슬라이스에는 별도 액티브 기술이 없다. | Q/R/V를 눌러 숨은 전투 행동이 발생하지 않는다. | 기술 슬롯, 공명, Spirit Art가 HUD/준비 화면에 없다. |
| Tool choice | 클래스 또는 무기 장비가 전체 키트를 바꾼다. | 각 슬롯의 모델만 해당 공격/방어 동작과 수치를 제공한다. | 검/창, 활/총, 원형/대형이 각각 다른 행동과 약점을 보인다. | 캐릭터 ID가 도구 동작을 선택하지 않는다. |
| Blueprint | 완성 장비 발견 또는 재료 구매. | 고정 보상으로 설계도를 영구 해금한 뒤 대장간에서 확정 제작. | 미해금/재료 부족/이미 제작/성공 상태가 모두 테스트된다. | 무작위 설계도 드롭과 중복 완성 장비가 없다. |
| Recraft | 영구 재료 등급 없음; 임시 forge affix만 존재. | 같은 모델을 정제 재료로 Grade 2 재제작해 직접 수치만 올린다. | 비교값과 런타임값이 같고 행동 ID·사거리 정책은 유지된다. | 임시 affix가 영구 성장 UI에 남지 않는다. |
| Condition | 장비 상태와 수리가 없다. | 근접/방패 상태, 마모 불이익, 안전 최소치, 확정 수리가 있다. | 상태 0에서도 Stage 1을 시작·완료하고 수리할 수 있다. | 파괴·장착 금지·확률 수리가 없다. |
| Ranged supply | Archer 투사체는 영구 탄약 경제가 아니다. | 활 화살과 총 탄약/재장전, 고정 보급, 최소 보장이 있다. | 0, 보급, 재시작, 장비 변경 시 값이 유효 범위다. | 탄약 부족이 Stage 진입을 막지 않는다. |
| Spirit | 현재 없음; 잘못된 문서는 동조+정령술+공명을 제안한다. | 장착 정령석 하나가 패시브 효과 하나만 제공한다. | 입력 없이 정확한 조건에 한 번 발동하고 거래/공격 이벤트를 중복 처리하지 않는다. | V/LT, 공명 게이지, 액티브 정령술이 없다. |
| Drops | 기존 재료/코인/완성 장비 중심. | 적·상자·NPC·정예·완료 보상이 서로 다른 고정 책임을 가진다. | 각 출처가 화면 표시와 저장에 정확히 한 번 반영된다. | 낭떠러지 보상 유실과 재실행 중복이 없다. |
| UI | 클래스/기술/디버그 정보와 현재 결과가 여러 화면에 흩어진다. | 전투 HUD와 대장간이 현재 상태, 비용, 결과, 부족 이유, 획득 내용을 짧게 표시한다. | 세 해상도, 키보드/게임패드, 비활성/성공/실패 상태가 통과한다. | 원시 ID, 설명문 벽, 겹침, 잘린 텍스트가 없다. |

## Proposed Design

### 1. Minimum Content Catalog

#### Starting equipment

| Slot | ID / display name | Core behavior | Starting weakness |
| --- | --- | --- | --- |
| Melee | `traveler_sword` / 여행자의 검 | 짧은 전진이 있는 균형형 연속 베기. | 긴 리치와 높은 자세 피해가 없다. |
| Ranged | `hunting_bow` / 사냥 활 | 보이는 전방 적에게 빠른 직선 화살을 발사한다. | 화살을 소비하고 단발 피해가 낮다. |
| Shield | `round_shield` / 원형 방패 | 빠르게 들고 전면을 지속 방어하며 짧은 정밀 방어 구간을 가진다. | 강한 연속 공격에 자세가 빨리 소진된다. |
| Armor | `traveler_coat` / 여행자 외투 | 이동 성능 변화가 없는 기준 방어구. | 추가 생존 보너스가 없다. |
| Spirit Stone | `ember_spirit_stone` / 불씨 정령석 | 3초 안의 네 번째 직접 공격이 1 피해 화상을 2회 적용한다. | 연속 적중이 끊기면 횟수가 초기화된다. |
| Consumable | `small_potion` / 회복 물약 | 체력 2 회복, 1회 사용. | 최대 체력에서는 소비하지 않는다. |

#### Stage 1 alternatives

| Slot | ID / display name | Behavior difference | Acquisition |
| --- | --- | --- | --- |
| Melee | `hunting_spear` / 사냥 창 | 검보다 길고 좁은 찌르기, 끝거리 보상, 느린 회복. | 짧은 NPC 의뢰 완료. |
| Ranged | `matchlock` / 화승총 | 높은 단발 피해, 긴 사거리, 발사 후 자동 재장전. | 선택 경로의 고정 보물상자. |
| Shield | `tower_shield` / 대형 방패 | 느리게 들지만 넓고 안정적인 전면 방어, 방어 중 이동 저하. | 정예 Shield Guard 최초 처치. |
| Armor | `reinforced_coat` / 보강 갑옷 | 최대 체력과 밀려남 저항, 대시 회복 지연. | Stage 1 최초 완료. |
| Spirit Stone | `frost_spirit_stone` / 서리 정령석 | 정밀 방어 성공 시 공격자를 1.5초 동안 25% 둔화한다. | 선택 경로의 고정 정령 제단. |

두 모델의 차이는 단순 피해량 차이가 아니다. 각 대안은 입력/도달/속도/자원/
위험 중 적어도 두 축이 다르고 한 가지 명시적 약점을 가진다.

### 2. Initial Combat Tuning Contract

아래 값은 첫 구현 기준이며 플레이테스트에서 같은 모델 정체성을 유지한 채 조정할
수 있다. 단위는 Godot 픽셀과 초다.

| Model | Damage / guard | Reach / range | Startup | Recovery / reload | Other |
| --- | ---: | ---: | ---: | ---: | --- |
| Traveler Sword | 2 damage, 18 stagger | 76 | 0.10 | 0.22 | 3번째 연속 입력은 폭 20% 증가 |
| Hunting Spear | 3 damage, 24 stagger | 118 | 0.16 | 0.30 | 영웅 36px 이내는 약한 적중, 끝 32px은 완전 적중 |
| Hunting Bow | 2 damage, 10 stagger | 520 | 0.12 | 0.44 | 화살 12 시작 / 20 최대 |
| Matchlock | 5 damage, 42 stagger | 680 | 0.08 | 1.35 reload | 탄약 5 시작 / 8 최대, 대시는 장전 취소 |
| Round Shield | 100 stability | 120-degree front | 0.08 | 0.14 lower | 정밀 방어 0.14초, 방어 이동 70% |
| Tower Shield | 150 stability | 160-degree front | 0.30 | 0.28 lower | 방어 이동 35%, 방어 중 점프 불가 |
| Traveler Coat | baseline | n/a | n/a | n/a | 이동/대시 변화 없음 |
| Reinforced Coat | +2 max HP | n/a | n/a | n/a | 밀려남 15% 감소, 대시 재사용 +0.06초 |

공격 판정과 미리보기는 같은 수치를 사용한다. UI는 소수점 내부값 대신 이해할 수
있는 `피해`, `도달 거리`, `공격 속도`, `자세 피해`, `방어 안정성`, `이동 부담`,
`탄약`으로 변환해 표시한다.

### 3. Context Attack Contract

공격 입력 한 번은 정확히 하나의 불변 `AttackIntent`를 만든다.

1. 영웅의 바라보는 반평면 안에서 살아 있고 발견된 적만 후보로 만든다.
2. 장착 근접 도구의 실제 hit region과 16px 완충 영역에 적 hurtbox가 닿으면
   가장 가까운 후보에 근접 행동을 선택한다.
3. 근접 후보가 없으면 원거리 모델 정책이 시야, 사거리, 자원, 장전 상태를 검증한다.
4. 유효한 원거리 후보가 있으면 해당 원거리 행동을 선택한다.
5. 원거리 후보가 없거나 자원이 없으면 바라보는 방향으로 근접 행동을 실행한다.
6. 선택은 startup 시작 시 고정하고 recovery가 끝날 때까지 바꾸지 않는다.

동일 적이 근접/원거리 경계에서 흔들리지 않도록 마지막 선택을 0.15초 유지한다.
벽 뒤, 화면 밖, 영웅 뒤, 상호작용 물체, 아직 발견하지 않은 적은 자동 표적이
아니다. 조준 표식, 공격 궤적, 실제 hitbox/projectile은 같은 intent를 받는다.

### 4. Defense Contract

- `G` / gamepad `Y`를 누르면 장착 방패를 들고 놓으면 내린다.
- 방패가 활성화되기 전 startup, 막는 active, 내리는 recovery를 구분한다.
- 정면 각도 안의 일반 근접·투사체만 막는다.
- 붉은 방어 불가 태그와 측후면 공격은 막지 못한다.
- 정밀 방어는 방패별 시작 구간 안에서만 성립하며 별도 랜덤 판정이 없다.
- 방어 안정성이 0이면 방어가 깨지고 짧은 recovery가 발생하지만 체력 피해를
  임의로 0으로 만들지 않는다.

### 5. Materials, Recipes, And Recrafting

#### Material families

| Family | Grade 1 / display name | Grade 2 / display name | Existing-data handling |
| --- | --- | --- | --- |
| Metal | `rusted_scrap` / 철 조각 | `steel_fragment` / 강철 조각 | 기존 `rusted_scrap` 수량을 1:1 유지한다. |
| Timber | `common_timber` / 일반 목재 | `hardwood` / 단단한 나무 | 신규. 파괴물·상자·Walker 계열에서 얻는다. |
| Textile | `sky_thread` / 거친 섬유 | `reinforced_fabric` / 질긴 직물 | 기존 `sky_thread` 수량을 1:1 유지한다. |

기존 `slime_residue`와 `boss_core`는 프로필에서 보존하지만 이 슬라이스의 제작식에
사용하지 않는다. 삭제하거나 다른 재료로 자동 변환하지 않는다.

#### Recipes

| Model | Same-grade recipe |
| --- | --- |
| Traveler Sword | Metal 5 + Timber 2 |
| Hunting Spear | Metal 3 + Timber 4 |
| Hunting Bow | Metal 1 + Timber 5 + Textile 3 |
| Matchlock | Metal 6 + Timber 3 + Textile 1 |
| Round Shield | Metal 3 + Timber 4 |
| Tower Shield | Metal 6 + Timber 4 |
| Traveler Coat | Metal 1 + Textile 5 |
| Reinforced Coat | Metal 4 + Textile 5 |

- 기본 장비는 Grade 1 완성품으로 지급되고 해당 설계도도 함께 해금된다.
- 대안 설계도는 획득만으로 완성 장비를 지급하지 않는다.
- 제작은 Grade 1 재료를 소비해 미보유 모델을 만든다.
- 재제작은 같은 수량의 Grade 2 재료를 소비해 보유 모델을 Grade 2로 갱신한다.
- Grade 2는 직접 공격 피해 `+1`, 자세 피해 `+15%`, 방패 안정성 `+15%`,
  근접/방패 최대 상태 `+20%`, 방어구 최대 체력 `+1` 중 해당 항목만 적용한다.
- Grade 2는 공격 거리, 폭, 입력, 표적 정책, 탄약 최대치, 정령석 조건을 바꾸지 않는다.
- 성공 확률, 실패, 파괴, 등급 하락, 재료 환급 랜덤, 품질 편차가 없다.
- 동일 모델 복제품을 여러 개 만들지 않는다. 프로필은 모델별 최고 제작 등급과
  현재 상태 하나만 저장한다.

#### Stage 1 guaranteed economy

첫 완료의 필수/고정 보상 총합은 최소 아래 수량을 보장한다.

| Material | Guaranteed total | Purpose |
| --- | ---: | --- |
| Iron Scrap | 12 | 대안 모델 하나의 주요 제작비. |
| Common Timber | 10 | 창·총·방패 중 하나의 제작비. |
| Rough Fiber | 6 | 총 또는 방어구 제작 선택 지원. |
| Steel Fragment | 6 | 보유 장비 하나의 Grade 2 재제작. |
| Hardwood | 5 | 무기/방패 Grade 2 재제작. |
| Reinforced Fabric | 5 | 활/방어구 Grade 2 재제작. |

선택 경로를 무시해도 대안 모델 하나와 Grade 2 하나를 만들 수 있어야 한다.
선택 경로는 더 빠른 두 번째 제작 또는 다른 정령석을 제공한다. 반복 입장 전에는
획득 가능한 재료 계열과 고정 미회수 보상을 표시한다.

### 6. Condition, Repair, And Ranged Supply

#### Condition

- Traveler Sword, Hunting Spear, Round Shield, Tower Shield만 상태를 가진다.
- Grade 1 최대 상태는 100, Grade 2는 120이다.
- 근접 도구는 적어도 한 대상을 맞힌 공격 거래마다 상태 1을 잃는다. 다수 적중도
  같은 공격 거래에서는 한 번만 감소한다.
- 원형 방패는 일반 방어 1, 강한 공격 방어 3, 정밀 방어 0을 잃는다.
- 대형 방패는 일반 방어 1, 강한 공격 방어 2, 정밀 방어 0을 잃는다.
- 상태 25% 이하에서 아이콘과 짧은 소리로 경고한다.
- 상태 0은 `마모됨`이다. 근접 피해/방패 안정성 `-15%`, recovery `+10%`만
  적용하며 장비는 사라지거나 비활성화되지 않는다.
- 대장간에서 같은 등급 주 재료 1개로 현재 최대 상태의 35%를 수리한다.
- Stage 진입 전 장착 근접/방패가 25% 미만이면 25%까지 무료 기본 정비한다.

#### Ranged supply

| Model | Resource | Start / max | Stage minimum | Fixed supply pickup |
| --- | --- | ---: | ---: | --- |
| Hunting Bow | Arrow | 12 / 20 | 8 | 화살 묶음 +4 |
| Matchlock | Cartridge + reload | 5 / 8 | 4 | 탄약 주머니 +2, 비전투 시 장전 완료 |

화살/탄약 0이면 공격 intent가 근접 fallback을 선택한다. 원거리로만 처치 가능한
필수 적, 스위치, 진행문은 만들지 않는다. 보급품은 장착 도구에 맞는 외형과 이름을
사용하며 추상 `ammo` 보석 하나로 통일하지 않는다.

### 7. Fixed Tutorial And Stage 1 Flow

#### Arsenal Trial

| Room | Teaches | Completion rule | Failure protection |
| --- | --- | --- | --- |
| 1. Movement | 이동, 점프, 2단 점프, 대시 | 짧은 안전 경로 통과 | 모든 낙하는 입구 복귀, 피해 없음 |
| 2. Melee | 근접 범위와 검 공격 | 정지 Walker 1 + 느린 Walker 1 처치 | 체력 1 이하에서 적 공격 중단 및 회복 제공 |
| 3. Ranged | 먼 적에서 활 자동 선택, 화살 | 고정 Shooter 표적 2개 처리 | 화살 무한 연습 보급, 완료 시 정상 수량으로 정산 |
| 4. Defense | 방패 지속/정밀 방어 | 예고 투사체 3개 중 2개 방어 | 실패해도 즉시 재시도, 낙하 없음 |
| 5. Preparation | 장비 슬롯, 정령석 패시브, 대장간 | 기본 loadout 확인 후 출구 사용 | 제작을 요구하지 않음 |

첫 프로필은 `연습 시작`과 `연습 건너뛰기`를 명확히 선택한다. 두 경로는 같은
idempotent 거래로 기본 6개 항목과 tutorial resolved 상태를 지급한다. 연습 완료만
통계 플래그가 다르고 장비·재료·전투 성능은 같다. 재연습은 보상을 다시 지급하지 않는다.

#### Ruin Approach Stage 1

| Beat | Fixed content | Reward / purpose |
| --- | --- | --- |
| 1. Entry patrol | Walker 2, 안전한 낮은 단차 | 일반 재료와 회복 픽업을 읽는다. |
| 2. Shooter overlook | Shooter 1 + Walker 1, 엄폐와 하단 복귀로 모두 통과 가능 | 화살/탄약 보급과 원거리/방패 선택을 시험한다. |
| 3. NPC side task | 막힌 작업대 주변 Walker 2 처치 후 NPC와 재상호작용 | Hunting Spear blueprint. |
| 4. Optional cache | 시야 안 선택 경로, 필수 이동 능력만 사용 | Matchlock blueprint와 추가 일반 재료. |
| 5. Mid-stage forge | 체크포인트, 대장간, 회복 | 최소 한 대안 장비를 제작·장착하고 비교할 수 있다. |
| 6. Choice test | 긴 접근 적 + 먼 Shooter 조합 | 새 장비가 없어도 통과, 선택에 따라 접근법이 달라진다. |
| 7. Spirit shrine | 짧은 선택 경로와 고정 제단 | Frost Spirit Stone, 중복 획득 없음. |
| 8. Elite guard | Shield Guard 1, 측면 이동 공간과 후퇴 공간 보장 | Tower Shield blueprint와 정제 재료. |
| 9. Final forge | 체크포인트, 수리, Grade 2 재제작 | 장비 하나를 상위 재료로 확정 성장시킨다. |
| 10. Exit encounter | Walker 2 + Shooter 1 | 제작/재제작 결과를 실제 전투에서 확인한다. |
| 11. Stage clear | 출구 상호작용 | Reinforced Coat blueprint, 남은 정제 재료, 영구 저장. |

모든 하단 구역에는 올라오는 경로 또는 즉시 체크포인트 복귀가 있다. 고정 계획은
공통 이동 지표로 전체 경로, 선택 경로, NPC 왕복, 상자 왕복, 대장간 왕복을
검증한다. 장비 모델, 상태, 탄약, 정령석은 이동 검증 입력에 포함하지 않는다.

### 8. Reward Delivery

- 일반 재료와 보급은 적 사망 또는 고정 앵커의 가장 가까운 안전 바닥에 실제
  픽업으로 생성된다.
- 철은 파편, 목재는 묶음, 섬유는 감긴 천, 화살은 화살통, 탄약은 봉한 주머니로
  실루엣을 구분한다. Grade 2는 동일 계열 형태에 테두리와 표식을 더한다.
- 재료는 0.35초 뒤 짧게 끌려오며 접촉 시 획득한다. 낭떠러지로 떨어지거나
  전투가 끝나면 안전 회수한다.
- 설계도와 정령석은 자동 흡수하지 않는다. 상자/NPC/정예 완료/제단/Stage clear
  화면에서 이름, 장비 슬롯, 동작 차이, 제작 필요 여부를 확인한다.
- 설계도 해금, 제작, 재제작, 수리, 정령석 해금은 각각 고유 거래/명령 ID를
  사용하고 결과가 확정된 뒤에만 수령 UI를 표시한다.
- 중복 설계도는 재료로 자동 변환하지 않는다. 이미 해금됨을 표시하고 동일
  거래를 소비한 상태로 끝낸다.

### 9. Preparation, Forge, HUD, And Receipts

#### Preparation / Forge

- 상단: 현재 영웅, Stage 1, 저장 상태.
- 왼쪽: `근접`, `원거리`, `방패`, `방어구`, `정령석`, `소비 아이템` 슬롯.
- 가운데: 해당 슬롯의 보유 모델과 미제작 설계도 목록.
- 오른쪽: 현재 장비와 선택 결과 비교. 행동 설명, 강점, 약점, 핵심 수치, 등급,
  상태/탄약, 재료 비용, 보유량을 표시한다.
- 하단 명령: 상태에 따라 정확히 하나의 `제작`, `재제작`, `수리`, `장착` 주 행동과
  `뒤로`만 강조한다.
- 재료 부족, 미해금, 이미 최고 등급, 상태 가득 참, 전투 중 변경 불가 이유를
  버튼 비활성 상태 옆에 짧게 표시한다.
- 성공 후 목록 전체를 닫지 않고 동일 모델 상세를 갱신해 결과를 즉시 비교한다.

#### Combat HUD

- 왼쪽 상단: HP와 현재 방어구의 간단한 상태.
- 하단 중앙: 공격 입력에 근접/원거리 아이콘 한 쌍을 보여주고 현재 intent만
  강조한다. 별도 무기 전환 버튼처럼 보이면 안 된다.
- 공격 옆: 원거리 자원, 근접 상태. 방어 옆: 방패 상태와 안정성.
- 정령석은 작은 아이콘과 발동 준비/진행만 표시한다. 액티브 버튼이나 게이지처럼
  보이면 안 된다.
- 회복 물약은 남은 횟수와 입력을 표시한다.
- Q/R/V 기술 슬롯, 클래스 이름, 디버그 계약 문구, 지속적인 전체 재료 목록은 없다.
- 상자/NPC/대장간/출구는 가까울 때만 `E` 상호작용 문구를 표시한다.

#### Receipt

- 일반 픽업: 아이콘 + 이름 + 수량, 최대 2.0초.
- 설계도/정령석: 이름 + 슬롯/효과 + `대장간에서 제작 가능` 또는 `장착 가능`,
  최대 4.0초 또는 확인 입력.
- 제작/재제작/수리: 이전 -> 결과의 핵심 변화 한 줄.
- 큐는 최대 4개이며 같은 재료의 연속 획득은 수량을 합친다.

### 10. Profile V2 And Persistence

프로필 v2는 한 모델당 하나의 상태만 저장한다.

```text
schema_version
hero_id
materials
unlocked_blueprints
crafted_equipment[model_id] = {grade_id, condition}
unlocked_spirit_stones
loadout = {melee, ranged, shield, armor, spirit_stone, consumable}
tutorial_state
durable_unlocks
applied_profile_transactions
settings
```

- 기본 모델 설계도와 완성 Grade 1 장비는 새 프로필에 함께 지급한다.
- `condition`은 근접/방패에만 존재하며 다른 슬롯은 필드를 저장하지 않는다.
- 모든 영구 명령은 복제 데이터에서 검증하고 비용 차감과 결과 적용을 한 번에
  성공시킨 뒤 `ProfileSaveService`의 staging/backup 경로로 저장한다.
- 저장 실패 시 메모리의 확정 전 데이터로 돌아가고 Retry를 제공한다.
- v1 마이그레이션은 기존 `rusted_scrap`, `sky_thread`, `slime_residue`,
  `boss_core`, 설정, 거래 장부를 보존한다.
- v1 시작 장비는 새 기본 장비로 대체한다. 추가 소유 장비는 항목별 고정 salvage
  재료를 지급하고 원래 ID를 `durable_unlocks`에 migration 기록으로 남긴다.
- 실제 사용자 경로는 테스트에서 사용하지 않는다. 모든 저장 테스트는 고유한
  `user://test_*` 경로를 만들고 자기 파일만 정리한다.

다중 프로필, 수동 저장 슬롯, Stage 도중 Continue는 이 계획에 포함하지 않는다.
단, 앱을 종료하고 다시 실행했을 때 설계도, 재료, 제작 등급, 상태, 정령석,
장착 상태가 정확히 복원되는 것은 출시 차단 조건이다.

## Shared Owners To Create, Reuse, Or Retire

| Concern | Desired owner | Existing owner(s) to reuse or retire |
| --- | --- | --- |
| Hero baseline | one `HeroDefinition` or equivalent immutable snapshot | Normalize and retire production use of three `CharacterProfile` resources. |
| Tool model | typed `CombatToolDefinition` with role, attack/guard, target/resource policy references | Reuse `AttackDefinition`; remove `CharacterKit` as production tool selector. |
| Context attack | one `AttackIntentResolver` returning immutable intent | Reuse target queries, hitbox/projectile execution; do not duplicate in UI. |
| Shield defense | one guard runtime configured by shield definition | Extract reusable guard behavior from current Warrior/progression hooks. |
| Crafting definitions | typed blueprint, recipe, material-grade catalogs | Generalize `EquipmentDefinition/Catalog`; retire fixed 12-ID class catalog. |
| Persistent commands | `ProfileCommandService` | Extend existing atomic command boundary; UI never mutates profile dictionaries. |
| Persistent save | `ProfileSaveService` + v1 -> v2 migration | Reuse staged write, backup rotation, corruption recovery. |
| Rewards | `RewardService` and transaction types | Extend current currency/equipment discovery contract for blueprint/Spirit unlocks. |
| Stage presentation | curated plan and authored room anchors | Reuse room assembly, content spawning, checkpoint/fall recovery. |
| Preparation/forge UI | one reusable equipment decision view fed by snapshots | Reuse decision panel/styles; retire class strip, mastery view, affix chooser. |
| HUD | `ProductionHUD` fed by run/combat/equipment snapshots | Reuse responsive shell, action slot, receipt; retire class state and skill slots. |

## Milestones / Execution Phases

### Phase A - Freeze Baseline And Align Contracts

**Goal:** 보존할 현재 동작을 고정하고 잘못된 문서/용어를 제거한 뒤 코드 변경을 시작한다.

**Source owners:** active docs, current combat/profile/reward/UI validators.

- [x] **A1 Align authoritative documents.**
  - As-is: 정식 문서가 12개 도구, 제압/전술/정령술, 공명, 장신구를 목표로 한다.
  - To-be: 이 계획의 최소 콘텐츠와 패시브 정령석만 정식 계약으로 남긴다.
  - Accept: 활성 문서와 `.agent/Documentation.md`에 `Spirit Art`, `resonance`,
    생산 `control/tactical skill`이 긍정 요구사항으로 남지 않는다. 과거 결정을
    폐기하는 문장과 non-goal/guard 문장은 허용한다.
  - Guard: superseded 연구/기록 문서는 역사 근거로 유지하고 실행 권한을 주지 않는다.
- [x] **A2 Capture representative v1 fixtures.**
  - `PlayerCombatController`, Warrior melee/guard, Archer projectile, profile save,
    reward settlement, field pickup, fixed Stage 1, HUD/forge 스냅샷을 집중 fixture로 고정한다.
  - Accept: 새 fixture가 현재 `master`에서 통과하고 실패 시 어떤 보존 동작이 깨졌는지 말한다.
- [x] **A3 Define target Resource and snapshot contracts without production activation.**
  - `CombatToolDefinition`, material/blueprint/Spirit definitions, `AttackIntent`,
    hero loadout, crafted equipment snapshot의 필드와 검증 규칙을 만든다.
  - Accept: 최소 8 장비 모델, 2 정령석, 2등급 재료 fixture가 정적 검증을 통과한다.
  - Guard: 아직 `RunDirector`와 실제 프로필 쓰기를 바꾸지 않는다.

*Visible result:* 개발 검증 화면 또는 테스트가 목표 8개 장비와 실제 비교 수치를
읽을 수 있지만 기존 생산 실행은 그대로 유지된다.

### Phase B - One Hero, Context Attack, And Shield Defense

**Goal:** 기존 Stage 1에서 기본 검·활·원형 방패를 쓰는 한 영웅 플레이를 만든다.

**Source owners:** `PlayerController`, `PlayerCombatController`, current combat
runtimes, input bindings, Player scene, RunState development activation path.

- [x] **B1 Add one shared hero baseline.**
  - As-is: `RunState` selects one of three profiles and applies character movement/build.
  - To-be: 하나의 영웅 HP·이동 지표와 loadout snapshot을 플레이어에 적용한다.
  - Accept: 모든 기존 필수 경로가 동일한 영웅 fixture로 통과한다.
  - Guard: 이동에 장비 ID나 정령석 ID 조건문을 넣지 않는다.
- [x] **B2 Implement `AttackIntentResolver`.**
  - 근접 후보, 원거리 후보, 시야, 자원, fallback, 16px 완충, 0.15초 유지,
    action lock 규칙을 순수 입력/결과 계약으로 구현한다.
  - Accept: 가까운/먼/뒤/벽 뒤/탄약 0/경계/다수 적 fixture가 정확한 모델 ID를 반환한다.
- [x] **B3 Route preview and execution through the same intent.**
  - `PlayerAttackPresenter`와 `PlayerCombatController`가 같은 intent geometry를 사용한다.
  - Accept: 표시 범위와 실제 hurtbox/projectile 판정 오차가 허용치 4px 이하다.
- [x] **B4 Implement shield runtime and `guard` input.**
  - 원형 방패 startup/active/recovery, 정면 각도, stability, 정밀 방어를 구현한다.
  - `heavy_attack`은 마이그레이션 입력 alias로 한 배치만 유지한 뒤 생산 표시에서 제거한다.
  - Accept: 일반/강/측후면/방어 불가/정밀 방어 fixture가 통과한다.
- [x] **B5 Remove production skill input execution.**
  - Q/R/V 입력이 생산 플레이어에서 어떤 공격도 시작하지 않게 한다.
  - Accept: 입력 검증과 HUD snapshot에 기술 슬롯이 없다.
  - Guard: 기존 기술 데이터는 A fixture와 마이그레이션이 필요할 때까지 삭제하지 않는다.

*Visible result:* 기존 고정 Stage 1을 한 영웅이 F 공격과 G 방어만으로 플레이하며,
가까운 적은 검, 먼 적은 활이 자동 선택되고 표시와 판정이 일치한다.

### Phase C - Profile V2, Equipment Catalog, And Atomic Commands

**Goal:** 최소 장비와 영구 성장 상태를 안전하게 저장하는 소유 경계를 만든다.

**Source owners:** `EquipmentDefinition/Catalog`, `ProfileData`,
`ProfileCommandService`, `ProfileState`, `ProfileSaveService`, data Resources.

- [x] **C1 Replace class equipment catalog with the minimum catalog.**
  - 8 equipment models, 2 Spirit Stones, 6 material IDs와 recipes를 typed Resource로 만든다.
  - Accept: exact ID/count, recipe, role, grade, weakness, unsupported field 검증이 통과한다.
  - Guard: 새 카탈로그가 랜덤 옵션, 희귀도, 액티브 기술 참조를 허용하지 않는다.
- [x] **C2 Add profile schema v2.**
  - 한 hero loadout, blueprint set, crafted model state, Spirit unlock, materials,
    tutorial state, settings, transaction ledger를 직렬화한다.
  - Accept: defaults, round trip, invalid slot/grade/condition/material fixtures가 통과한다.
- [x] **C3 Implement v1 -> v2 migration.**
  - 기존 재료/설정/거래를 보존하고 장비는 명시적 salvage 표로 전환한다.
  - Accept: Warrior/Archer/Assassin 대표 v1 저장과 손상 primary/정상 backup이 기대 v2로 복구된다.
  - Guard: 검증된 v2 staging이 성공하기 전 v1 primary를 덮어쓰지 않는다.
- [x] **C4 Add atomic profile commands.**
  - blueprint/Spirit unlock, craft, recraft, repair, equip을 복제-검증-비용 차감-저장
    순서로 구현한다.
  - Accept: 성공, 미해금, 재료 부족, 중복, 잘못된 slot/grade, save failure rollback이 통과한다.
- [x] **C5 Activate the one-hero loadout behind a temporary migration flag.**
  - B의 전투가 프로필 v2 snapshot을 사용하도록 연결하되 이전 save fixture는 유지한다.
  - Accept: 앱 재실행 후 장착 모델과 상태가 동일하다.

*Visible result:* 개발 준비 화면에서 기본 6개 항목과 재료를 보고 장착을 바꾸고,
앱을 재시작해도 그대로 복원된다.

### Phase D - Crafting, Recrafting, Repair, Condition, And Supply

**Goal:** 전투와 영구 성장 사이의 실제 대장간 순환을 완성한다.

**Source owners:** profile commands, new crafting service/catalog, combat equipment
runtime state, RunState stage preparation, RestForge replacement.

- [x] **D1 Implement deterministic crafting previews.**
  - 현재 모델, 결과 모델, recipe, 보유량, 부족량, 행동 차이, 수치 차이를 한 snapshot으로 만든다.
  - Accept: UI preview, command result, runtime build가 동일한 resolver 값을 사용한다.
- [x] **D2 Implement craft and recraft.**
  - Grade 1 대안 제작과 Grade 2 같은 모델 재제작을 구현한다.
  - Accept: 재료가 정확히 한 번 차감되고 모델 복제품이 생기지 않는다.
- [x] **D3 Implement condition and repair.**
  - 공격/방어 거래당 감소, 마모 불이익, 무료 25% 정비, 35% 수리를 연결한다.
  - Accept: 다중 적중 중복 감소 없음, 상태 clamp, 상태 0 전투 가능, save round trip이 통과한다.
- [x] **D4 Implement arrows, cartridges, and reload.**
  - 활/총 자원 adapter, stage minimum, 보급 결과, 총 자동 장전을 구현한다.
  - Accept: 자원 0 fallback, 보급 상한, 대시 장전 취소, 장비 변경, respawn fixture가 통과한다.
- [x] **D5 Replace temporary forge production actions.**
  - `RunState` 임시 affix와 `RestForge` affix 선택을 생산 경로에서 제거하고
    제작/재제작/수리/장착 명령으로 교체한다.
  - Guard: 기존 affix fixture는 기록용으로만 남기거나 대체 검증 후 삭제한다.

*Visible result:* 고정 안전 구역에서 창/총/대형 방패/보강 갑옷 중 하나를 제작하거나
기본 장비를 Grade 2로 재제작하고, 수리·탄약 보급 결과를 다음 전투에서 확인한다.

### Phase E - Passive Spirit Stones And Reward Types

**Goal:** 패시브 원소 선택과 고정 설계도 획득을 거래 안전하게 연결한다.

**Source owners:** damage/status resolution, Spirit definitions/runtime, reward
entry/service/result, chest/NPC/elite/stage reward integration, receipt presenter.

- [x] **E1 Implement one passive Spirit owner.**
  - 장착 Stone 하나의 조건과 결과만 구독하고 공격/방어 이벤트 ID로 중복을 막는다.
  - Accept: 불씨 4번째 직접 공격과 서리 정밀 방어가 정확한 조건에서만 발동한다.
  - Guard: 입력 action, cooldown, resonance, active damage API가 없다.
- [x] **E2 Add blueprint and Spirit reward entry types.**
  - `RewardEntry`, `RewardTransaction`, `RewardResult`, `RewardService`에 영구 해금 타입을 추가한다.
  - Accept: 미보유/기보유/재실행/저장 실패 경로가 정확히 한 번 정산된다.
- [x] **E3 Extend field pickup families.**
  - 일반/정제 금속·목재·섬유와 활/총 보급을 모양, 색, 이름, 실제 변화량으로 연결한다.
  - Accept: 접촉, 낭떠러지 안전 회수, 최대치, 장착 불일치, receipt 병합이 통과한다.
- [x] **E4 Implement exact acquisition sources.**
  - NPC 의뢰=창, 상자=화승총, 정예=대형 방패, Stage clear=보강 갑옷,
    제단=서리 정령석을 고정 ID로 연결한다.
  - Accept: 각 출처를 두 번 실행하거나 앱을 재시작해도 중복 지급되지 않는다.

*Visible result:* 플레이어가 설계도와 정령석을 실제 상호작용으로 얻고, 무엇을
얻었으며 어디에서 사용할지 게임 화면에서 즉시 이해한다.

### Phase F - Arsenal Trial And Fixed Stage 1 Vertical Slice

**Goal:** 새 시스템을 설명문이 아닌 플레이 순서로 가르치고 한 번의 Stage 1에서
획득-제작-재제작-전투를 완주한다.

**Source owners:** new fixed Trial scene/plan, curated Stage 1 builder/rooms,
content anchors/spawner, RunDirector phases, checkpoints/fall recovery.

- [x] **F1 Author five fixed Trial rooms.**
  - 기존 방/적/체크포인트/픽업을 재사용하고 4-6분 길이로 만든다.
  - Accept: 새 프로필 완료 경로에서 각 동작을 실제로 한 번 수행한다.
- [x] **F2 Implement complete/skip parity.**
  - 같은 idempotent baseline transaction으로 기본 loadout과 tutorial resolved를 지급한다.
  - Accept: 완료/스킵 profile snapshot이 telemetry flag를 제외하고 동일하다.
- [x] **F3 Recompose fixed Ruin Approach beats.**
  - 위 11개 beat와 고정 획득 앵커, 중간/최종 forge, 체크포인트를 배치한다.
  - Accept: 승인된 room/anchor IDs와 전체 Stage Plan 검증이 통과한다.
- [x] **F4 Validate all committed returns and fall recovery.**
  - NPC, cache, shrine, forge, elite 선택 경로의 진입-복귀를 검증한다.
  - Accept: 하단에 머무는 상태가 없고 fall zone/월드 하한이 최근 체크포인트로 복귀시킨다.
- [x] **F5 Validate guaranteed economy.**
  - 필수 경로에서 대안 1개와 Grade 2 1개가 가능하며 선택 경로 보상은 추가 선택만 만든다.
  - Accept: 고정 보상 합계, 중복 방지, 사망/재진입 시나리오가 통과한다.

*Visible result:* 새 프로필이 Trial 또는 Skip 뒤 Stage 1에 들어가 설계도를 얻고,
장비를 만들고, 재제작하고, 그 차이를 마지막 전투에서 사용한 뒤 저장한다.

### Phase G - Production UI And Player Feedback

**Goal:** 클래스/테스트베드 느낌을 제거하고 전투, 획득, 제작 판단을 자연스러운
게임 UI로 표현한다.

**Source owners:** MainMenu, CharacterSelect replacement, RestForge replacement,
ProductionHUD, equipment decision component, receipt presenter, styles, input glyphs.

- [x] **G1 Replace character selection with one-hero preparation.**
  - As-is: 캐릭터 strip, class loadout, mastery mode.
  - To-be: 6개 loadout slot, 모델 목록, 제작 상태, 비교, 저장 상태, Start.
  - Accept: 마우스/키보드/게임패드로 모든 모델을 검사하고 가능한 주 행동을 실행한다.
  - Guard: 클래스 이름, mastery tab, 원시 ID가 없다.
- [x] **G2 Replace RestForge with deterministic forge.**
  - craft/recraft/repair/equip 상태와 실패 이유를 동일 비교 component로 표시한다.
  - Accept: 성공 후 포커스와 선택 모델이 유지되고 결과값이 즉시 갱신된다.
- [x] **G3 Simplify Production HUD.**
  - HP, contextual attack pair, ammo, melee/shield condition, shield stability,
    Spirit passive, potion, objective/prompt/receipt만 남긴다.
  - Accept: 960x540에서 전투 시야를 가리지 않고 1920x1080에서 과도하게 퍼지지 않는다.
- [x] **G4 Complete reward and interaction feedback.**
  - E prompt, chest/NPC/shrine result, material merge receipt, craft/recraft/repair result를 구현한다.
  - Accept: 각 획득/명령의 성공·실패·중복 상태가 플레이어에게 보인다.
- [x] **G5 Verify accessibility and responsive behavior.**
  - 명확한 포커스, 40px 이상 주요 타깃, 색 외 상태 표시, 텍스트 wrap/overflow,
    motion-sensitive feedback controls, 입력 glyph 변경을 검증한다.

*Visible result:* 새 시스템을 설명하는 디버그 문단 없이도 플레이어가 현재 장비,
다음 행동, 획득 내용, 제작 가능 여부를 화면에서 이해한다.

### Phase H - Production Activation, Cleanup, And Release Gates

**Goal:** 새 경로를 기본 생산 실행으로 전환하고 이전 클래스/기술/임시 forge
소유자를 안전하게 제거한다.

**Source owners:** RunDirector/RunPhase/RunState, catalogs, old character/skill data,
old UI, cards/micro-upgrades compatibility, release scripts, docs.

- [x] **H1 Activate the one-hero flow by default.**
  - Main Menu의 New Game이 Trial/Skip 또는 준비 화면으로 진입한다.
  - Accept: 개발 flag 없이 production boot와 Stage 1 complete가 통과한다.
- [x] **H2 Preserve only compatible existing run systems.**
  - 공유 카드와 장비에 무관한 micro-upgrade만 유지한다.
  - 스킬 cooldown, character-specific, heavy-specific 선택은 offer에서 제외한다.
  - Accept: 보상 화면에 죽은 선택이나 존재하지 않는 입력 설명이 없다.
- [x] **H3 Retire old production owners.**
  - class selection, character loadouts, class HUD state, skill action slots,
    temporary affix production UI/data consumers를 제거한다.
  - Guard: historical migration fixture와 superseded docs 외에 class ID 분기가 없다.
- [x] **H4 Run focused and full validation.**
  - 아래 Validation Cadence의 batch/final gates와 실제 렌더링을 완료한다.
- [x] **H5 Update durable docs and close the plan.**
  - architecture/data index/PRD/UI spec/release record/`.agent/Documentation.md`를
    실제 구현으로 갱신하고 이 계획을 `done`으로 바꾼다.

*Visible result:* 앱을 새로 실행해 한 영웅으로 Trial/Skip, Stage 1, 획득, 제작,
재제작, 저장-재실행을 완주하며 이전 클래스/기술 UI가 나타나지 않는다.

## Test Plan / Validation Cadence

### Inner-Loop Checks

- 변경한 Resource/서비스의 단일 `validate_*.gd` 스크립트.
- `git diff --check`와 대상 용어/ID `rg` guard.
- 전투 변경 시 가까운/먼/방어 한 fixture만 실행.
- 프로필 변경 시 임시 경로의 단일 round-trip fixture만 실행.
- UI 변경 시 960x540 한 상태 캡처와 포커스 snapshot.

### Batch Gates

- **After B:** one-hero movement, context attack matrix, guard matrix, attack presentation.
- **After C:** catalog, profile defaults/v1 migration/v2 round trip, command rollback.
- **After D/E:** crafting preview/runtime parity, condition, ammo, Spirit, reward idempotence.
- **After F:** curated plan, room anchors, committed returns, fall recovery, economy totals.
- **After G:** shell/HUD/receipt at 960x540, 1280x720, 1920x1080 and keyboard/gamepad.

### Final Gates

- `./tools/godot.ps1 --version`
- `./tools/godot.ps1 --path . --headless --import`
- `./tools/godot.ps1 --path . --headless --quit-after 2`
- `./tools/godot.ps1 --path . --headless --script res://tools/validate_production_boot.gd`
- new minimum catalog/profile/crafting/context/Spirit/Trial/Stage 1 validators;
- updated `validate_production_stage.gd`, `validate_curated_stage_plans.gd`,
  `validate_fixed_drop_runtime.gd`, `validate_fixed_field_pickup_manifest.gd`;
- updated `validate_gameplay_hud.gd`, `validate_shell_ui.gd`, input remap/gamepad validators;
- `./tools/validate_release_candidate.ps1` followed by `-Full` once before handoff;
- one fresh-profile Trial run, one Skip run, one Stage 1 full clear, one fall recovery,
  one state-0 fixture, one ammo-0 fixture, one save-restart recovery;
- production-like rendered review at 960x540, 1280x720, 1920x1080.

### Rerun Policy

- 실패 원인이나 코드가 바뀌기 전에는 같은 느린 검증을 반복하지 않는다.
- 먼저 가장 좁은 실패 fixture를 재실행하고 통과한 뒤 해당 batch gate를 한 번 실행한다.
- 전체 release matrix는 H와 최종 handoff에서만 실행한다.
- 알려진 비차단 경고는 기록하고 통과한 전체 검증을 진척처럼 반복하지 않는다.

### UI Tool Fallback

- Godot 캡처/GUI 자동화가 도구 문제로 두 번 실패하면 capture script,
  scene-tree/Control rect snapshot, 수동 실행 체크로 전환한다.
- 렌더링을 하지 못했으면 렌더링 완료라고 보고하지 않고 제한을 명시한다.

## Guard Checks

- [x] 생산 실행에 클래스 선택과 Warrior/Archer/Assassin 표시가 없다.
- [x] 생산 combat path에 `skill_1`, `skill_2`, `skill_3`, Spirit Art, resonance가 없다.
- [x] 정령석은 입력, cooldown, resource gauge를 소유하지 않는다.
- [x] 상황 공격 미리보기와 실행이 하나의 intent를 사용한다.
- [x] UI는 profile/run/crafting/reward dictionary를 직접 수정하지 않는다.
- [x] 설계도 획득과 완성 장비 제작은 서로 다른 상태다.
- [x] 재료 등급은 행동·사거리·표적 정책을 바꾸지 않는다.
- [x] 제작·재제작·수리에 실패 확률, 파괴, 하락, 랜덤 옵션이 없다.
- [x] 상태 0과 탄약 0에서도 Stage 1을 시작하고 완료할 수 있다.
- [x] 필수 경로는 특정 장비, 정령석, 탄약, 상태를 요구하지 않는다.
- [x] 모든 낙하는 안전 복귀 또는 최근 체크포인트 respawn으로 끝난다.
- [x] Trial 완료와 Skip의 기계적 profile snapshot이 동일하다.
- [x] 모든 reward/profile transaction은 재실행 후에도 한 번만 적용된다.
- [x] 저장 테스트가 실제 `user://profile.json`을 읽거나 쓰지 않는다.
- [x] 임시 forge affix가 영구 제작 UI나 build에 남지 않는다.
- [x] 원시 ID, 디버그 계약 문구, 기술 슬롯, 공명 게이지가 생산 UI에 없다.
- [x] 세 지원 해상도에서 clipping, overlap, accidental horizontal overflow가 없다.
- [x] 관련 없는 사용자 변경과 `docs/design/references/`를 stage/revert/정리하지 않는다.

## Rollback / Safety

- 새 hero/combat/profile 경로는 각 batch gate가 통과할 때까지 개발 activation flag
  뒤에 둔다. H에서 한 번만 기본 경로로 전환한다.
- v1 fixture와 migration reader는 v2 저장, 복구, production boot가 통과할 때까지
  삭제하지 않는다.
- 프로필 저장은 기존 staging -> validation -> backup rotation -> activation 순서를
  유지한다. 실패 시 마지막 유효 primary/backup을 보존한다.
- reward/crafting 명령은 복제 데이터에서 먼저 검증한다. 비용 차감 후 실패하는
  부분 상태를 허용하지 않는다.
- 고정 Stage 1 V3를 직접 덮어쓰기 전에 현재 curated plan fixture를 보존한다.
  개정된 layout version을 올리고 이전 버전은 회귀 fixture로만 유지한다.
- 이전 코드 삭제는 새 생산 경로, 마이그레이션, grep guard가 모두 통과한 H3에서만 한다.
- 의존성이나 외부 에셋을 추가하지 않는다. 필요해지면 별도 승인과 도입 검증이 필요하다.

## Error Handling

- 목표 파일이 없으면 유사 이름 파일을 만들기 전에 `rg`로 현재 소유자를 다시 찾는다.
- v1 -> v2 변환이 실패하면 v1 primary/backup을 보존하고 새 프로필로 조용히 덮지 않는다.
- 제작 저장이 실패하면 재료와 결과 장비 모두 이전 상태로 되돌리고 Retry를 제공한다.
- reward source와 거래 ID가 없으면 해당 보상을 적용하지 않고 개발 빌드에서 오류를 표시한다.
- Stage Plan 또는 route validation이 실패하면 잘못된 Stage를 로드하지 않고 안정된 메뉴로 돌아간다.
- 필드 픽업 안전 바닥을 찾지 못하면 즉시 프로필/run owner에 정산하고 receipt에 안전 회수를 표시한다.
- UI snapshot 필드가 없으면 가짜 기본값으로 성공처럼 보이지 않고 해당 명령을 비활성화한다.
- 기존 관련 없는 변경을 발견하면 되돌리거나 포함하지 않고, 목표 파일과 충돌할 때만 사용자에게 묻는다.

## Risks And Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| 한 공격 버튼 자동 선택이 플레이어 의도와 다름 | 전투가 통제 불가능하게 느껴짐 | 근접 우선, 명확한 시야/거리, 16px buffer, 0.15초 hysteresis, 공통 intent preview. |
| 제작 시스템이 단순 수치 메뉴가 됨 | 핵심 순환이 재미없음 | 새 설계도는 행동 차이, 재료 등급만 직접 수치 성장으로 분리한다. |
| 재료가 너무 많아 첫 Stage가 장부처럼 느껴짐 | 획득 가독성 저하 | 3계열 x 2등급만 표시하고 한 번에 한 대안+한 재제작을 보장한다. |
| 상태/탄약이 실험을 벌함 | 반복 강제와 소프트락 | 무료 25% 정비, stage minimum supply, 상태 0 사용 가능, 필수 원거리 적 금지. |
| 기존 클래스 결합이 넓음 | 장기간 호환 어댑터와 중복 소유자 | fixture -> target contract -> visible slice -> activation -> cleanup 순서를 지킨다. |
| 프로필 마이그레이션이 보상을 중복/유실 | 영구 진행 손상 | idempotent migration transaction, staged validation, backup, exact fixtures. |
| UI가 다시 디버그 대시보드가 됨 | 게임 몰입과 조작 이해 저하 | 전투 중 필요한 상태만 HUD, 상세 비교는 준비 구역, 실제 렌더링 gate. |
| Stage 1에 너무 많은 설명이 들어감 | 흐름이 느리고 테스트베드처럼 보임 | 공간/적/보상 순서로 가르치고 텍스트는 상호작용과 결과에만 사용한다. |

## Suggested Execution Order

1. A: 문서 정렬, v1 fixture, 목표 계약.
2. B: 한 영웅의 기본 검·활·원형 방패 플레이.
3. C: 프로필 v2와 최소 장비/재료 카탈로그.
4. D: 제작·재제작·수리·상태·탄약.
5. E: 패시브 정령석과 고정 획득 거래.
6. F: Trial 완료/스킵과 고정 Stage 1 순환.
7. G: 실제 게임 UI/UX와 피드백.
8. H: 기본 생산 경로 전환, 이전 소유자 제거, 최종 검증.

## Success Criteria

계획 전체는 아래 항목을 모두 관찰할 수 있을 때만 완료한다.

1. 새 프로필에서 Trial 완료와 Skip이 같은 기본 장비·정령석 상태를 만든다.
2. 한 영웅이 Stage 1의 모든 필수/선택 왕복 경로를 기본 이동만으로 통과한다.
3. 가까운 적은 근접, 유효한 먼 적은 원거리, 자원 0/표적 없음은 근접 fallback을
   선택하고 표시와 판정이 일치한다.
4. 방어 입력은 장착 방패만 사용하며 원형/대형 방패의 차이와 실패 조건이 실제로 보인다.
5. NPC, 상자, 정예, 제단, Stage clear가 각자 지정 설계도/정령석을 정확히 한 번 지급한다.
6. 첫 완료의 필수 보상만으로 대안 모델 하나와 Grade 2 장비 하나를 만들 수 있다.
7. 제작은 새 행동을 열고 재제작은 같은 행동의 직접 성능만 올린다.
8. 상태 0, 화살 0, 탄약 0에서도 Stage 시작과 완료가 가능하다.
9. 대장간 비교값, 명령 결과, 실제 전투값이 동일한 resolver에서 나온다.
10. 획득, 제작, 재제작, 수리, 장착 후 앱을 재실행해도 상태가 정확히 복원된다.
11. HUD와 준비/대장간 화면에 클래스, 기술 3칸, 공명, 액티브 정령술, 디버그 문단이 없다.
12. 집중 검증, release candidate core/full, 세 해상도 UI 검증이 통과한다.

## Stop Conditions

- **Complete:** 모든 Success Criteria와 final gates가 통과하고 필수 체크가 남지 않았을 때
  `status: done`으로 바꾼다.
- **Ask the owner:** 액티브 기술/스킬 트리, 세 번째 장비 모델, 새로운 재료 계열,
  정령석 액티브, 랜덤 맵, 다중 저장 슬롯처럼 이 계획의 명시적 비범위를 구현해야만
  진행할 수 있게 되었을 때 멈추고 묻는다.
- **Do not stop:** 작업이 크거나 튜닝이 필요하거나 전체 검증이 느리다는 이유만으로
  중단하지 않는다. 가장 좁은 미완료 배치로 계속 진행한다.
- **Blocked:** 같은 외부 차단 조건이 세 번 연속 반복되고 사용자 입력 또는 환경 변화
  없이는 의미 있는 진전이 불가능할 때만 차단으로 처리한다.

## Decision Notes

- **2026-07-14:** `최소 구현`을 시스템 생략이 아니라 콘텐츠 수 제한으로 정의했다.
  따라서 제작·설계도·재료·재제작·수리·영구 저장은 후속 단계가 아니라 이 계획의
  완료 조건이다.
- **2026-07-14:** 클래스 선택을 제거하고 한 영웅의 장비 선택으로 전투 변화를 만든다.
- **2026-07-14:** 별도 액티브 기술은 합의 전까지 만들지 않는다. 정령석도 전용 입력이나
  게이지 없이 장착형 패시브로만 동작한다.
- **2026-07-14:** 랜덤 맵보다 전체 성장 순환 검증을 우선하므로 연습장과 Stage 1은
  승인된 고정 배치를 사용한다.
- **2026-07-14:** 기존 이동·피해·공격 표현·적·보상·저장 기반은 재사용하되, 클래스
  중심 생산 경로와 중복 소유자는 교체 완료 후 제거한다.

## Completion Record

- 한 Traveler 생산 경로, 상황 공격, 방패 방어, 장비 성장, 고정 Trial/Stage 1,
  profile v2, Forge, HUD, 보상, 세 고정 stage, boss flow가 구현되었다.
- `validate_release_candidate.ps1 -Full -SkipImport`는 2026-07-14에 활성 검사
  `68/68`을 통과했다.
- progression UI, gameplay HUD, shell UI, fixed-stage evidence를 Godot 4.7로
  렌더링하고 `960x540`, `1280x720`, `1920x1080` 적용 화면을 검사했다.
- 활성 제품/전투/UI/architecture/catalog 문서와 현재 release record를 구현에
  맞췄다.
- `docs/design/references/`의 관련 없는 사용자 파일은 변경하거나 stage하지 않았다.

이 계획은 완료 기록이며 더 이상 실행 지시가 아니다. 액티브 기술, 추가 장비,
랜덤 맵, 다중 저장 슬롯, 최종 아트는 owner playtest 근거와 새 ExecPlan 없이
연속 구현하지 않는다.
