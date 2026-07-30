---
type: evidence
status: active
created: 2026-07-29
topic: Hidden techniques, collective enemy behavior, and mastery-linked unlocks
scope: Advisory gameplay research for the current five-stage Cardborne vehicle campaign
source: User idea seeds from the 2026-07-29 design discussion, current repository state, and linked external references
related:
  - ../product/vehicle_game_spec.md
  - ../product/combat-growth-improvement-direction.md
  - ../../.agents/survivor-shooter-combat-growth-reference-study.md
  - ../../.agents/execplans/2026-07-29-horde-foundation-recovery-and-acceptance.md
  - ../../.agents/execplans/2026-07-30-full-visual-system-redesign.md
---

# 숨은 조작·적 집단행동·행동 기반 해금 설계 분석

## Purpose

이 문서는 다음 세 가지 아이디어를 Cardborne에 무조건 적용하기 위한 사양이나 실행 계획이 아니다.

1. 기존 버튼의 누르기·떼기·순서 조합으로 발동하는 숨은 조작
2. 적의 종류·수·위치에 따라 발생하는 집단행동
3. 특정 처치·수집·행동을 반복했을 때 열리는 능력

목적은 이 아이디어들에서 드러나는 플레이 취향을 분석하고, 서로 연결했을 때 어떤 게임 구조가
될 수 있는지 설명하며, 검증할 가치가 있는 후보와 피해야 할 구현을 분리하는 것이다.

이 문서는 `evidence`다. 현재 제품 계약은
[`vehicle_game_spec.md`](../product/vehicle_game_spec.md)이며, 승인되지 않은 아래 명칭·수치·기능은
구현 요구사항이 아니다.

## Scope

포함:

- 적은 버튼으로 높은 숙련도와 표현력을 만드는 방법
- 현재 적 역할과 편대 데이터를 활용한 집단 전술
- 행동을 학습시키는 조건부 능력 해금
- 집단 전술, 지형, 속성, 대시, Breach, EMP, 보스를 연결하는 전투 순환
- 작은 vertical slice에서 먼저 검증할 범위

제외:

- 현재 진행 중인 적 밀도·가독성·연속 스테이지 작업의 대체
- UI 개편 또는 신규 UI 시안
- 확정 밸런스 수치
- 격투게임 수준의 커맨드 입력
- 새 메타 재화, 대규모 스킬 트리 또는 영구 수치 강화
- 이 문서만을 근거로 한 구현 착수

## Executive Summary

세 아이디어에서 공통으로 드러나는 취향은 다음과 같다.

> **조작은 단순하지만, 기존 행동과 적의 상태가 특정 관계를 만들면 질적으로 다른 사건이 발생하고,
> 플레이어가 그 규칙을 발견·숙련하면서 이전에는 처리하지 못하던 대규모 위협을 해체하는 게임.**

따라서 이 방향을 단순히 `커맨드 입력`, `합체 적`, `업적 해금`이라는 독립 기능 세 개로 구현하면
의도가 약해진다. 가장 강한 결합은 다음과 같다.

1. 적들이 읽을 수 있는 집단 전술을 준비한다.
2. 초보자는 기존 대시·사격·EMP만으로도 피하거나 버틸 수 있다.
3. 숙련자는 기존 버튼의 간단한 변형과 빌드 상태를 이용해 집단 전술을 붕괴시킨다.
4. 붕괴가 연쇄 피해, 지형 기폭, 대량 처치로 이어진다.
5. 그 대응 행동 자체가 새 기술이나 진화 카드의 발견 조건이 된다.
6. 후반 보스는 앞에서 배운 집단 규칙을 더 큰 규모로 지휘한다.

이 구조를 임시로 **숨은 전술 문법**이라고 부를 수 있다. 이는 설명을 위한 작업 명칭이며 제품
용어나 코드 명칭으로 확정하지 않는다.

## Sources

### 현재 프로젝트

- [`vehicle_game_spec.md`](../product/vehicle_game_spec.md)
  - 수동 조준, held primary fire, 1초 opening Breach, dash, EMP, 자동 보조 무기
  - authored encounter, 적 역할, 카드 제안, 속성 상태, 보스 규칙
- [`combat-growth-improvement-direction.md`](../product/combat-growth-improvement-direction.md)
  - `Gather → Compress → Trigger → Delete → Harvest → Evolve → Boss Test` 성장 방향 초안
- [`survivor-shooter-combat-growth-reference-study.md`](../../.agents/survivor-shooter-combat-growth-reference-study.md)
  - survivor-shooter 레퍼런스와 현재 성장·몰이·보스 진단
- [`vehicle_encounter_director.gd`](../../scripts/encounters/vehicle_encounter_director.gd)
  - squad 중심점, cohesion, 공격 commit budget
- [`vehicle_enemy_state.gd`](../../scripts/enemies/vehicle_enemy_state.gd)
  - `group_id`, `squad_id`, formation slot/size/offset, attack phase
- [`vehicle_enemy_specialist_runtime.gd`](../../scripts/enemies/vehicle_enemy_specialist_runtime.gd)
  - rammer, repair tender, carrier, beam sentinel의 현재 역할별 협조 규칙

### 외부 레퍼런스와 query expansion

사용자의 세 아이디어를 문자 그대로만 검색하지 않고 다음 인접 개념으로 확장했다.

| 아이디어 seed | 확장한 조사 개념 |
| --- | --- |
| 숨은 커맨드 | low-input/high-expression controls, tap-hold variants, stateful verbs, discoverable hidden mechanics |
| N마리 집단행동 | squad coordination, collective attacks, formation recipes, interruptible merge, large-force tactics |
| 조건부 능력 해금 | mastery challenges, behavior-linked unlocks, horizontal meta progression, achievements that teach mechanics |
| 적을 맵에 이용 | telegraphed threat redirection, arena control, enemy attacks as environmental tools |

주요 출처:

- [Apple Game Controls](https://developer.apple.com/design/human-interface-guidelines/game-controls)
  - 같은 조작의 탭·홀드 변형과 과도한 동시·연속 입력 축소 원칙
- [F.I.S.T. 전투 설계](https://blog.playstation.com/2021/08/10/the-arcade-style-combat-in-f-i-s-t-forged-in-shadow-torch/)
  - 한 버튼의 차지·연속 공격·처형과, 장기 플레이에서 드러난 단조로움 및 차지의 실전 문제
- [TUNIC의 미스터리 설계](https://www.gamedeveloper.com/design/designing-content-for-no-one-an-interview-with-the-team-behind-tunic)
  - 이미 존재하던 세계와 조작을 재해석하게 만드는 발견 구조
- [Days Gone의 동적 분대 조정](https://www.gdcvault.com/play/1027066/AI-Summit-Squad-Coordination-in)
  - 동적 squad 생성, 공간 분석, 집단 상태에 따른 행동 선택
- [Believable Tactics for Squad AI](https://www.gdcvault.com/play/1015665/Believable-Tactics-for-Squad)
  - 중앙형·분산형 squad 동기화와 scripted/procedural 방식의 trade-off
- [Dynasty Warriors: Origins의 Large Force](https://www.koeitecmoamerica.com/dw_origins/us/system/?ac=tgt-features02)
  - 다수의 적이 집단 전력과 대규모 전술을 형성하고, 이를 붕괴시키는 구조
- [Cronos의 적 합체와 차단](https://blog.playstation.com/?p=407108)
  - 적 합체가 위치·처치 순서·중단 행동을 바꾸는 arena-control 규칙
- [Into the Breach](https://www.subsetgames.com/itb.html)
  - 강한 적 공격을 사전에 보여주고 플레이어가 공격 자체를 전환·방해하게 하는 원칙
- [적 공격 예고와 전투 공정성](https://www.gamedeveloper.com/design/enemy-design-and-enemy-ai-for-melee-combat-systems)
  - 강한 공격일수록 명확한 tell과 대응 기회가 필요하다는 전투 설계 분석
- [Risk of Rain 2 Challenges](https://riskofrain2.wiki.gg/wiki/Challenges)
  - 특정 전투 행동으로 alternate skill, item, equipment를 해금하는 사례
- [Cogmind achievement-system analysis](https://www.gamedeveloper.com/design/designing-and-building-a-robust-comprehensive-achievement-system)
  - 업적을 새로운 플레이 방식과 시스템 학습으로 유도하는 방법

Risk of Rain 2의 세부 challenge 목록은 커뮤니티 위키이므로 개별 수치의 정본 근거가 아니라
`행동 조건 → 관련 능력 해금`이라는 구조를 분석하는 보조 자료로만 사용한다.

## Findings

### F1. 원하는 것은 어려운 커맨드가 아니라 낮은 입력 복잡도와 높은 시스템 깊이다

사용자의 첫 번째 아이디어에서 중요한 것은 `대시를 2초 누른다` 또는 `5배 이동한다`는 수치가 아니다.
같은 버튼도 플레이어의 의도, 타이밍, 빌드 상태에 따라 다른 의미가 생긴다는 점이다.

이 취향은 다음과 구분해야 한다.

| 원하는 방향 | 피해야 할 방향 |
| --- | --- |
| 같은 버튼의 탭·짧은 홀드·릴리스 | 긴 방향 커맨드와 프레임 단위 입력 |
| 기본 동작은 언제나 즉시 사용 가능 | 고급 조작 때문에 기본 동작이 늦게 발동 |
| 상황을 읽는 숙련 | 키 입력 암기를 요구하는 숙련 |
| 속성이 행동의 성질을 변경 | 속성별로 색만 다른 피해 장판 |
| 발견 후 이해하고 재현 가능 | 공략을 보지 않으면 존재조차 알 수 없음 |

Cardborne에는 이미 이 방향의 기반이 있다.

- 주무기는 누르고 있으면 연사한다.
- 사격 중단 시간이 opening Breach 준비 상태를 만든다.
- dash와 EMP는 별도 버튼이지만 현재는 동작 변형이 적다.
- 속성, 상태 이상, 자동 보조 무기가 이미 플레이어 상태를 제공한다.

따라서 새 버튼을 추가하기보다 다음 문법을 제한적으로 쓰는 편이 맞다.

> `기존 행동 + 입력 변형 하나 + 현재 전투 상태`

예:

- `dash + 짧은 홀드 후 릴리스 + 운동 속성`
- `dash 직후 EMP + 이미 생성된 속성 흔적`
- `준비된 Breach + 적 편대의 연결점`

한 기술이 두 개를 넘는 연속 행동이나 매우 짧은 타이밍을 요구하면 단순 조작이라는 제품 정체성을
훼손한다.

### F2. 세 아이디어 중 적 집단행동이 가장 강한 중심축이다

적 수를 늘리는 작업은 몰이사냥의 물량 기반을 만든다. 그러나 적이 모두 독립적으로 플레이어만
추적하면 100마리도 동일한 체력 덩어리의 반복이 될 수 있다.

적 집단행동은 같은 적 roster로도 다음 변화를 만든다.

- 한눈에 읽을 수 있는 전장의 큰 사건
- 지금 우선 처치해야 할 대상
- 이동 방향을 결정하는 공간 문제
- 발동 전 방해할지, 피한 뒤 반격할지에 대한 선택
- 적 공격을 다른 적이나 지형에 되돌리는 기회
- 일반전에서 배운 규칙을 보스가 확대하는 학습 구조

현재 코드에는 squad 식별자, formation offset, squad 중심점과 cohesion, 역할별 공격 commit 제한이
이미 있다. 따라서 모든 적에게 복잡한 개별 AI를 추가하기보다 **편대 단위 조정자**가 일정 조건을
평가하고 기존 적에게 일시적인 역할과 위치를 배정하는 방식이 자연스럽다.

### F3. 집단행동의 조건은 단순한 N이 아니라 ‘recipe’여야 한다

단순히 같은 적이 N마리 근처에 있으면 특수 공격을 발동할 경우 다음 문제가 생긴다.

- 화면 밖에서 우연히 조건이 완성될 수 있다.
- 플레이어가 원인을 이해하기 어렵다.
- 적이 많아질수록 특수 공격이 과도하게 중첩된다.
- 편대가 아니라 숫자 확인 로직처럼 보인다.
- 특정 스폰 seed가 지나치게 어려워질 수 있다.

권장 recipe는 다음 네 조건을 모두 사용한다.

1. **구성**: 필요한 역할과 최소 인원
2. **공간**: 직선, 삼각형, 원, 연결 가능한 고정 노드 등
3. **준비 시간**: 조건을 유지하며 집결하는 시간
4. **공격 권한**: 전역 집단공격 cap과 개별 recipe cooldown

집단행동은 공통적으로 다음 네 phase를 가져야 한다.

1. **Gather**: 구성원이 슬롯으로 이동한다.
2. **Lock**: 대형과 공격 방향이 고정되고 강한 tell이 나타난다.
3. **Execute**: 공격이 실행된다.
4. **Break/Recover**: 중단되거나 실행 후 취약해진다.

강한 공격은 `Lock` 단계에서 구성원 하나, 핵심 연결점 또는 선두를 제거하면 붕괴시킬 수 있어야 한다.

### F4. 숨은 기술은 ‘비밀’이 아니라 ‘발견 가능한 지식’이어야 한다

생존에 필요한 핵심 행동을 완전히 숨기면 플레이어는 자신이 못한 이유를 알 수 없다. 반대로 모든
고급 조작을 처음부터 튜토리얼 표로 보여주면 발견의 재미가 사라진다.

권장 공개 단계:

1. 기술을 전혀 시도하지 않았을 때는 가이드북에 실루엣이나 짧은 암시만 표시한다.
2. 유사 입력 또는 관련 편대 대응에 처음 성공하면 조건의 방향을 보여준다.
3. 처음 완전히 성공하면 기술 이름, 입력, 효과를 공개한다.
4. 이후에는 가이드북과 설정에서 언제든 다시 확인할 수 있다.

기본 생존 동작은 처음부터 공개하고, 없어도 게임을 진행할 수 있는 효율·표현·대량처치 기술만
발견 대상으로 둔다.

### F5. 행동 기반 해금은 반복량이 아니라 학습을 검증해야 한다

좋은 해금 조건은 보상받을 능력의 사용법을 먼저 연습시킨다.

나쁜 예:

- 적 1,000마리 처치
- 대시 500회 사용
- 경험치 아이템 2,000개 수집
- 운이 좋은 특정 카드 조합을 여러 번 요구

좋은 예:

- 한 번의 준비된 Breach로 큰 직선 군집을 제거
- 집단 돌격이 실행되기 전에 편대를 여러 번 붕괴
- 적 레이저 연결점을 끊어 다른 적에게 역류 피해 발생
- 서로 다른 두 상황에서 짧은 시간 안에 대량 처치
- 상태 이상을 의도적으로 조합한 뒤 관련 trigger로 마무리

권장 영구 보상은 `+10% damage` 같은 누적 수치가 아니라 다음 런부터 선택 가능한 새 카드,
진화, 조작 변형이다. 이는 오래 플레이한 계정을 단순히 강하게 만들기보다 표현 가능한 빌드를
늘린다.

### F6. 적 집단행동은 현재 부족한 지형 활용과 직접 연결할 수 있다

집단공격을 단순히 피하는 위험으로만 만들지 않고, 플레이어가 유도할 수 있는 전장 도구로 설계한다.

예:

- 돌격 대열이 breakable bulkhead에 충돌하면 대열이 붕괴하고 파편 피해가 발생한다.
- 도탄 방진의 예고 경로를 지뢰 쪽으로 유도해 연쇄 기폭한다.
- 연결 레이저가 특정 시설이나 적 편대를 가로지르게 위치를 조정한다.
- 수리망을 Breach로 끊으면 shield collapse가 주변 졸개에게 전달된다.

이렇게 하면 지형은 별도 퍼즐이 아니라 대규모 적 처리를 돕는 전투 증폭기가 된다.

### F7. 보스는 집단 규칙의 지휘관이 될 때 더 보스답다

일반 적의 집단행동이 생기면 보스는 단순히 더 큰 공격을 가진 개체일 필요가 없다.

- 스테이지 전반에서 한두 개의 집단 recipe를 먼저 보여준다.
- 보스는 그 recipe를 더 빠르게 만들거나 다른 조합으로 지휘한다.
- 플레이어가 집단 전술을 붕괴시키면 보스의 방어 또는 signature attack이 노출된다.
- 보스 phase는 HP 비율만이 아니라 지휘하는 집단 규칙의 변화로 구분된다.
- 보스 자체의 고유 공격도 유지해 단순한 support enemy가 되지 않게 한다.

이 구조는 일반전의 학습, 몰이사냥, 보스 목표를 하나의 전투 언어로 연결한다.

## Recommendations

### R1. 플레이어 측에는 ‘고급 조작’ 하나만 먼저 시험한다

#### 후보: 짧은 차지 대시

아래 수치는 확정값이 아니라 조작성 검증 범위다.

- 탭하면 현재 일반 대시가 즉시 발동한다.
- 약 `0.45~0.70초` 홀드하면 장거리 대시가 준비된다.
- 준비 중에도 기체의 일반 이동 속도를 강제로 낮추거나 정지시키지 않는다.
- 진행 방향과 예상 경로를 차체·바닥 cue로 표시한다.
- 버튼을 떼면 일반 대시의 약 `2.5~3배` 거리를 이동한다.
- 이동·사격·EMP 중 적절한 하나로 준비를 취소할 수 있다.
- 이동 거리가 늘어도 무적 시간은 동일 비율로 늘리지 않는다.
- 오입력으로 일반 대시가 지연되지 않아야 한다.

`2초 정지 후 5배 대시`는 seed로서는 유효하지만 첫 시험값으로는 부적절하다.

- 대규모 적 압박 속에서 2초 정지는 사용 기회를 지나치게 제한한다.
- 정지 강제는 빠른 이동감을 보존하려는 현재 방향과 충돌한다.
- 5배 이동은 화면과 encounter geometry를 건너뛰거나 카메라 가독성을 해칠 수 있다.

#### 속성 변형 후보

각 속성은 같은 피해 장판의 색상 교체가 아니라 편대에 서로 다른 영향을 준다.

| 상태 계열 | 차지 대시 변형 후보 | 편대에 주는 의미 |
| --- | --- | --- |
| Thermal | 지나간 경로가 짧은 지연 후 순차 폭발 | 추격 대열을 시간차로 절단 |
| Toxin | 경로가 약화·전염 영역이 됨 | 후속 공격과 Contagion 준비 |
| Cryo | 경로상의 적을 감속하고 brittle 상태로 만듦 | 대형 고정 또는 붕괴 준비 |
| Arc | 출발점과 도착점 사이에 순간 연결 방전 | 연결된 다수와 고정 노드 공격 |
| Kinetic | 경로상의 적을 좌우로 밀어냄 | 직선·보호막 편대를 물리적으로 절단 |

첫 vertical slice에서는 한 속성만 구현해 입력 자체가 재미있는지 먼저 확인한다. 다섯 속성을 동시에
만들면 조작 문제와 속성 설계 문제를 분리해 판단하기 어렵다.

### R2. 적 측에는 두 개의 집단 recipe를 먼저 시험한다

#### Recipe A — 창끝 대열

작업명이며 제품 명칭이 아니다.

- 구성: chaser, rammer 또는 경량 추격 계열 `6명 이상`
- 공간: 좁고 긴 복도 형태의 슬롯
- Gather: 구성원이 선두와 측면 슬롯으로 정렬
- Lock: 약 `1.0~1.3초`, 큰 화살 silhouette와 진행 lane 표시
- Execute: 한 방향 동시 고속 돌격
- 중단:
  - 선두 제거
  - 대열 중간을 Kinetic, Breach, EMP 중 하나로 절단
  - 핵심 인원이 최소치 아래로 감소
- 실행 후:
  - 벽이나 bulkhead 충돌 시 구성원 stagger
  - 제한된 회복 시간 동안 큰 취약 창
- 지형 활용:
  - 지뢰, breakable bulkhead 또는 다른 적 편대로 유도 가능

초보자는 일반 대시로 lane을 피할 수 있어야 한다. 집단 전술을 직접 붕괴시키는 것은 더 빠르고
화려한 숙련 해법이지 필수 정답이 아니다.

#### Recipe B — 수리망 방벽

- 구성: repair tender `3명`, 또는 repair tender `2명 + generator 1기`
- 공간: 서로 링크 가능한 거리와 시야
- Gather: 각 support가 삼각형 또는 연결망 슬롯으로 이동
- Lock: 링크선이 순차적으로 밝아지고 중심 방벽 범위 표시
- Execute: 주변 일반 적에게 공유 보호막 또는 강한 회복 제공
- 중단:
  - 링크 노드 하나 제거
  - Breach로 링크 관통
  - EMP로 연결을 일시 차단
- 붕괴 보상:
  - 구성원 전체 stagger
  - 보호받던 적에게 짧은 취약 또는 shield-collapse 피해

이 recipe는 단순히 적 생존 시간을 늘리면 전투를 지루하게 만든다. 플레이어가 연결점을 찾아
한 번에 많은 적을 무너뜨리는 보상까지 포함해야 한다.

### R3. 두 번째 묶음 후보는 검증 후에만 확장한다

#### 도탄 방진

- shield escort 또는 bulkhead guard `4명`
- 공 또는 쐐기 형태로 압축
- 실행 전에 `2~3회` 반사 경로를 표시
- 반사 횟수를 제한하고 실행 후 긴 취약 상태 제공
- 지뢰·구조물·다른 적과 충돌 가능

맵 전체를 무제한으로 튕기면 예측 불가능한 화면 밖 피해가 되므로 피한다.

#### 레이저 결속

- beam sentinel `3기`
- 새 거대 actor로 합체하지 않고 기존 노드를 시각적으로 연결
- 약 `1.3~1.6초`의 강한 link telegraph
- 중앙 또는 임의 핵심 노드를 제거하면 전체 공격 실패
- EMP나 Breach로 중단하면 역류가 주변 적에게 피해

#### 지뢰 도화선

- spark minelet 또는 설치 지뢰가 일정한 짧은 선을 형성
- 점화 cue가 한쪽 끝에서 다른 쪽으로 이동
- 플레이어가 먼저 끝점을 공격하면 폭발 방향 또는 시점을 바꿀 수 있음
- 적 대열을 지뢰 쪽으로 유도했을 때 큰 연쇄 처치 발생

### R4. 모든 집단공격에 공통 안전 규칙을 둔다

- 첫 vertical slice에서는 전역으로 집단공격 하나만 `Lock/Execute` 상태가 될 수 있다.
- 화면 밖에서는 `Lock`을 완료하지 않는다.
- 색만으로 상태를 전달하지 않는다.
- 구성원 연결선, 대형 silhouette, 공격 방향, 고유 음향을 함께 사용한다.
- Lock 전에 적이 위치를 바꾸는 이유가 보여야 한다.
- 중단 조건은 매번 동일하고 가이드북에서 확인 가능해야 한다.
- 실행 성공 여부와 관계없이 recipe별 cooldown을 둔다.
- 보스 공격, 원거리 commit, denial commit과 같은 전역 pressure budget에 포함한다.
- 구성원이 pathfinding에 실패하거나 최소 인원 아래가 되면 안전하게 취소한다.
- rigid-body처럼 모든 적을 강제로 결합하지 않고 semantic slot과 한 명의 coordinator를 사용한다.

### R5. 행동 기반 해금은 두 단계로 구성한다

권장 구조:

1. **발견**
   - 의미 있는 행동을 처음 성공한다.
   - 비모달 알림과 함께 기술 설명이 공개된다.
   - 현재 런의 다음 호환 카드 제안에서 해당 기술을 보장한다.
2. **숙련**
   - 같은 원리를 서로 다른 상황에서 `3~5회` 정도 재현한다.
   - 이후 런의 정상 카드·진화 풀에 영구적으로 편입된다.

이 방식은 조건 달성 직후 아무 변화가 없는 문제와, 카드 비용 없이 강한 능력을 즉시 영구 지급하는
문제 사이의 절충이다.

#### 해금 후보

| 학습 행동 | 발견/숙련 조건 후보 | 열리는 선택지의 역할 |
| --- | --- | --- |
| 직선 군집 처리 | 준비된 Breach 한 발로 12명 이상 처치, 서로 다른 교전에서 3회 | Line-breaker 진화 |
| 집단 돌격 대응 | 창끝 대열을 Lock 중 3회 붕괴 | 편대 횡단 대시 변형 |
| support 우선순위 | 수리망 핵심 노드를 3회 제거해 전체 방벽 붕괴 | support collapse 전파 |
| 전장 역이용 | 레이저 역류 또는 지뢰 연쇄로 적 10명 이상 처치 | 환경 trigger 강화 |
| 짧은 대량 처치 | 2초 이내 20명 처치를 서로 다른 두 런에서 달성 | crowd-clear 카드군 |
| 상태 조합 | 서로 다른 상태를 의도적으로 쌓고 관련 trigger로 마무리 | 복합 속성 진화 |

숫자는 실제 적 밀도와 처치 로그를 본 뒤 조정한다. 조건이 특정 운 좋은 build 또는 특정 stage
seed에서만 가능하면 안 된다.

### R6. 보스는 스테이지의 집단 언어를 재조합한다

후속 후보:

- Stage 1~2에서 창끝 대열을 일반전에서 충분히 보여준다.
- 해당 보스는 한 방향의 대열을 직접 지휘하되 준비 시간을 길게 둔다.
- 후속 phase에서는 두 개의 후보 대열을 만들지만 실제 실행 권한은 하나만 가진다.
- 플레이어가 올바른 대열을 붕괴시키면 보스의 signature startup을 Breach로 끊을 수 있는 창이 열린다.
- 수리망 보스는 방벽 노드를 직접 소환하는 대신 기존 support 적에게 지휘 권한을 부여한다.
- 마지막 보스는 이미 배운 두 recipe를 순차적으로 결합하되 새로운 해법을 갑자기 요구하지 않는다.

보스를 집단 전술만 사용하는 지휘관으로 만들지는 않는다. 각 보스의 직접 pattern과 고유 silhouette는
유지하고, 집단 전술은 phase 목표와 취약 창을 만드는 계층으로 사용한다.

## Unified Combat Example

다음은 세 아이디어가 한 교전에서 어떻게 연결되는지 보여주는 예시다.

1. 추격형 적 7명이 창끝 대열을 만들기 시작한다.
2. 바닥에 큰 화살 형태와 돌격 방향이 나타난다.
3. 처음 보는 플레이어는 일반 대시로 옆으로 빠진다.
4. 이후 Kinetic 계열 대시 변형을 얻은 플레이어는 대시 버튼을 짧게 홀드한다.
5. 돌격 직전에 대열을 가로질러 이동하며 적을 좌우로 밀어낸다.
6. 편대가 붕괴하고 일부 적이 지뢰와 bulkhead에 충돌한다.
7. 연쇄 폭발로 주변 적까지 제거되며 큰 XP 덩어리가 생긴다.
8. 첫 성공이라면 관련 기술과 가이드북 단서가 공개된다.
9. 같은 원리를 몇 차례 재현하면 이후 런의 대시 진화 풀에 영구 편입된다.
10. 후반 보스는 두 대열을 만들지만 플레이어는 앞에서 학습한 원리로 핵심 대열을 골라 붕괴시킨다.

이 예시는 다음 문제를 동시에 다룬다.

- 대규모 적이 단순한 체력 덩어리로 보이는 문제
- 맵을 이용해 적을 쓸어버리는 사건이 부족한 문제
- 성장해도 행동 자체가 달라지지 않는 문제
- 일반전과 보스전의 학습이 단절된 문제
- 메타 진행이 단순 수치 누적으로 흐르는 문제

## Recommended Validation Slice

전체 시스템을 한 번에 만들지 않는다. 첫 검증 범위는 다음으로 제한한다.

### 포함

- 플레이어 고급 조작 1개
  - Kinetic 짧은 차지 대시
- 적 집단 recipe 2개
  - 창끝 대열
  - 수리망 방벽
- 행동 기반 발견 3개
  - 편대 붕괴
  - support 망 붕괴
  - 대량 처치
- 기존 한 개 stage 또는 전용 검증 scenario
- 편대 인식, 중단, 오입력, 성능 telemetry

### 성공 판정 후보

- 일반 탭 대시는 기존과 같은 반응성을 유지한다.
- 한 번의 contextual hint 뒤 고급 대시 입력 성공률이 충분히 높다.
- 의도하지 않은 차지 대시 발동이 드물다.
- 플레이어가 집단공격 실행 전에 대형과 방향을 인지한다.
- 두 번째 노출부터 회피 또는 중단 비율이 뚜렷하게 상승한다.
- 집단공격을 붕괴시켰을 때 일반 처치보다 큰 전장 변화가 보인다.
- 집단행동 때문에 hostile projectile·denial pressure cap이 우회되지 않는다.
- 현재 목표 enemy density에서 Web 성능 예산을 유지한다.
- 해금 조건은 정상 플레이 중 의도적으로 달성할 수 있고 반복 노동을 요구하지 않는다.

### 관찰할 지표

- 일반 대시 입력부터 발동까지의 지연
- 차지 시작, 취소, 성공, 오발 횟수
- recipe별 Gather/Lock/Execute/Break 횟수
- 플레이어가 Lock 이후 피격, 회피, 중단한 비율
- 편대 붕괴 뒤 2초 내 처치 수
- 환경 피해가 만든 처치 수
- recipe가 화면 밖에서 취소된 횟수
- 동시에 활성화된 적·투사체·effect 수와 frame budget
- 해금 첫 진척까지 걸린 교전 수

## Rejected or Deferred Directions

### 첫 검증에서 거부

- 2초 동안 기체를 정지시키는 기본 차지
- 일반 대시보다 5배 이상 긴 초기 이동
- 기본 생존에 필요한 조작의 완전 은폐
- 세 동작 이상을 연속으로 입력하는 커맨드
- frame-perfect 또는 빠른 double-tap 요구
- 모든 속성을 동일한 피해 장판으로 처리
- 같은 종류의 적이 N마리라는 이유만으로 즉시 발동
- 화면 밖에서 완성되는 대형 공격
- 무제한 전맵 도탄
- 복수의 맵 횡단 레이저 동시 실행
- 적 집단행동으로 현재 enemy pressure cap을 우회
- 수백·수천 회 반복을 요구하는 해금
- 영구적인 공격력·체력 수치만 주는 메타 보상

### 후속 검증으로 보류

- 모든 속성의 차지 대시 변형
- 두 종류 이상의 집단공격 동시 실행
- 집단행동끼리 결합하는 복합 recipe
- 보스별 고유 집단 recipe
- 즉시 능력 지급과 카드 풀 편입을 결합한 상세 보상 방식
- 해금 progress를 표현하는 별도 UI

## Relationship to Current Work

현재 활성 ExecPlan인
[`2026-07-29-horde-foundation-recovery-and-acceptance.md`](../../.agents/execplans/2026-07-29-horde-foundation-recovery-and-acceptance.md)는
다음 구현 상태의 기술적 안정화를 담당한다.

- 적 수 2~3배 증가
- 사방에 고르게 분포된 spawn
- 원거리 적 비례 증가 제한
- 기체·적·투사체·아이템 가독성
- 아이템의 필드 존재감
- 스테이지 간 비모달 연속 진행

집단행동 rollout은 별도의 활성
[`2026-07-30-full-visual-system-redesign.md`](../../.agents/execplans/2026-07-30-full-visual-system-redesign.md)가
소유한다. 숨은 조작과 행동 기반 해금은 어느 활성 계획에도 포함되지 않는다.
충분한 적 밀도와 가독성은 이 제안의 선행조건이며, 복잡한 집단 AI가 현재
요청한 물량 개선을 미루는 이유가 되어서는 안 된다.

## Limitations

- 실제 플레이 로그 없이 제안한 인원, 시간, 거리, 반복 횟수는 확정할 수 없다.
- 현재 formation 데이터는 spawn cohesion을 지원하지만 집단 recipe 전체를 이미 지원하는 것은 아니다.
- 집단공격이 적을 더 흥미롭게 만들 수는 있어도, 기본 총기 타격감과 대량 처치 VFX가 약하면
  몰이사냥의 쾌감 자체를 대신할 수 없다.
- 숨은 기술의 발견 감각은 튜토리얼 노출량에 매우 민감하므로 텍스트만으로 품질을 판정할 수 없다.
- 이 연구는 입력 접근성, 키보드 ghosting, 게임패드 배치의 상세 검증을 수행하지 않았다.
- 외부 사례는 설계 원리를 비교하기 위한 것이며 Cardborne에 그대로 복제할 콘텐츠 목록이 아니다.

## Decision Needed Before Implementation

구현 계획으로 승격하기 전에 제품 소유자가 다음만 결정하면 된다.

1. 집단행동을 Cardborne의 핵심 전투 축 후보로 시험할 것인가?
2. 행동 기반 해금은 영구 수치가 아니라 카드·진화 선택지 확장으로 제한할 것인가?
3. 숨은 조작은 기본 기능이 아니라 선택형 업그레이드 또는 발견 기술로 시작할 것인가?
4. 첫 vertical slice를 `차지 대시 + 창끝 대열 + 수리망 방벽`으로 제한할 것인가?

승인된 항목만 별도 ExecPlan과 acceptance criteria로 옮기며, 거부되거나 보류된 항목은 현재 제품
사양에 반영하지 않는다.
