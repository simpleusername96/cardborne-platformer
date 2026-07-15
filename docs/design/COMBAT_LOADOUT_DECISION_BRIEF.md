---
type: record
status: active
owner: BK
created: 2026-07-14
last_reviewed: 2026-07-15
source: Owner feedback and scope correction through 2026-07-15
topic: Concise decision summary for the minimum single-hero combat and equipment loop
related:
  - ./COMBAT_EQUIPMENT_CRAFTING.md
  - ../../.agent/execplans/2026-07-14-minimum-equipment-progression-vertical-slice.md
  - ./PRODUCTION_UI_CONTRACT.md
  - ../research/player_input_and_ui_followup_audit_2026-07-15.md
---

# 최소 전투·장비 결정 요약

## Context

이전 제안은 12개 전투 도구, 제압/전술 기술, 액티브 정령술, 공명 게이지까지
한 번에 설계해 첫 구현의 목적을 흐렸다. 반대로 제작·설계도·재료 성장을 나중으로
미루면 사용자가 원하는 핵심 게임 순환 자체가 사라진다.

따라서 **핵심 시스템은 모두 구현하되 콘텐츠 수만 제한한다.** 상세 규칙은
`COMBAT_EQUIPMENT_CRAFTING.md`, 실행 순서는 새 작업이 시작될 때 작성하는
활성 ExecPlan이 소유한다.

## Decision

- 플레이 캐릭터는 한 명이다. 클래스 선택은 없다.
- 근접 도구, 원거리 도구, 방패를 하나씩 동시에 장착한다.
- 공격은 가까운 유효 적에 근접, 그렇지 않은 유효 먼 적에 원거리를 사용한다.
- 방어 입력은 항상 장착 방패를 사용한다.
- 첫 콘텐츠는 검/창, 활/화승총, 원형/대형 방패, 여행자/보강 방어구만 둔다.
- 새 설계도는 행동과 약점을 바꾸고, 상위 재료 재제작은 같은 행동의 직접 수치만 올린다.
- 재료는 금속·목재·섬유 세 계열, 일반·정제 두 등급만 사용한다.
- 근접 도구와 방패는 수리 가능한 상태를 가지지만 0에서도 파괴되거나 사용 불가가 되지 않는다.
- 불씨/서리 정령석 두 개는 패시브 효과 하나씩만 제공한다.
- 별도 액티브 기술, 기술 슬롯, 스킬 트리, 정령 액티브, 공명 게이지는 이번 구현에 없다.
  이후 실험도 동시에 하나를 초과하지 않는다.
- 고정 연습장과 고정 Stage 1에서 획득, 제작, 재제작, 장착, 저장을 한 번 완주한다.

## Rationale

- 시스템을 줄이지 않으므로 핵심 재미인 전투-획득-제작-다음 전투 순환을 실제로 검증한다.
- 모델을 역할별 두 개로 제한해 행동 차이를 비교할 수 있으면서 구현 범위를 통제한다.
- 설계도와 재료 등급의 책임을 나누면 새 장비와 수치 성장의 의미가 겹치지 않는다.
- 정령석을 패시브로 제한하면 장비 성장과 액티브 기술 체계가 서로 침범하지 않는다.
- 합의되지 않은 기술 체계를 미리 코드와 UI에 고정하지 않아 이후 설계를 자유롭게 유지한다.

## Consequences

- 이전의 12개 도구, 제압/전술/정령술, 장신구 목표는 현재 구현 목표가 아니다.
- 생산 HUD에는 공격, 방어, 소비 아이템과 필요한 장비 자원만 표시한다.
- 현재 액티브 기술 키는 없다. `R`은 소비 아이템에 사용하며 다중 기술 키를 만들지 않는다.
- 첫 완료 보상은 대안 장비 하나 제작과 장비 하나 Grade 2 재제작을 보장한다.
- Stage 2, 추가 장비, 스킬 트리, 랜덤 맵은 첫 순환이 플레이테스트를 통과한 뒤 별도 계획으로 확장한다.

## Related

- 상세 사양: `docs/design/COMBAT_EQUIPMENT_CRAFTING.md`
- 완료된 구현 기록: `.agent/execplans/2026-07-14-minimum-equipment-progression-vertical-slice.md`
- UI contract: `docs/design/PRODUCTION_UI_CONTRACT.md`
- 입력 및 별도 UI 브랜치 기록: `docs/research/player_input_and_ui_followup_audit_2026-07-15.md`
