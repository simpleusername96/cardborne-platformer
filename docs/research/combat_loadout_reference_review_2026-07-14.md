---
type: evidence
status: archived
owner: BK
created: 2026-07-14
last_reviewed: 2026-07-15
topic: Action-platformer combat loadouts, active/passive separation, and distinct weapon verbs
scope: Advisory evidence for Cardborne's single-hero combat equipment and skill-slot redesign
source: Official developer, publisher, and game-site material reviewed on 2026-07-14
related:
  - ../design/COMBAT_LOADOUT_DECISION_BRIEF.md
  - ../design/COMBAT_EQUIPMENT_CRAFTING.md
  - ../design/PLAYER_UIUX_REFINEMENT_PLAN.md
---

# 전투 구성 비교 조사 - 2026-07-14

> Historical evidence only. The three-active-skill recommendation below was
> rejected. Current combat direction is owned by
> `COMBAT_EQUIPMENT_CRAFTING.md` and caps any later active-skill experiment at one.

## Purpose

Cardborne의 근접·원거리·방패, 액티브 기술, 패시브 효과가 같은 기능을 이름과
수치만 바꿔 반복하지 않도록 유사 액션 게임의 구성 원리를 확인한다. 이 문서는
판단 근거이며 제품 규칙은 `docs/design/COMBAT_EQUIPMENT_CRAFTING.md`가 소유한다.

## Sources

1. [Prince of Persia: The Lost Crown combat overview](https://www.ubisoft.com/en-us/studio/montpellier/news/NvEbHCYiO8TjMNmfchQ6X/prince-of-persia-the-lost-crown-will-put-your-combat-platforming-and-puzzlesolving-skills-to-the-test), Ubisoft Montpellier.
2. [Dead Cells Update 5 patch notes](https://deadcells.com/patchnotes/5), Motion Twin.
3. [Dead Cells Update 21 patch notes](https://deadcells.com/patchnotes/21), Motion Twin/Evil Empire.
4. [Dead Cells current patch notes](https://deadcells.com/patchnotes/), Motion Twin/Evil Empire.
5. [Risk of Rain 2 Skills 2.0 developer announcement](https://store.steampowered.com/news/posts/?appids=632360&enddate=1585925796&feed=steam_community_announcements), Hopoo Games.
6. [Hades High Speed Update patch notes](https://www.supergiantgames.com/blog/hades-the-high-speed-update-patch-notes/), Supergiant Games.
7. [Nine Sols official press kit](https://redcandlegames.com/presskit/sheet.php?l=ch&p=nine+sols), Red Candle Games.
8. [Wizard of Legend official changelog](https://wizardoflegend.com/changelog.html), Contingent99.

## Findings

### 1. 적은 기본 행동 수와 많은 변형을 분리한다

- `Prince of Persia: The Lost Crown`은 쌍검, 활, 되돌아오는 Chakram, 패리라는
  읽기 쉬운 기본 행동을 유지한다. 별도 Athra 능력은 공격으로 게이지를 채워
  쓰며, 패시브 성격의 Amulet은 제한된 비용 안에서 장착한다.
- `Hades`는 Attack, Special, Cast처럼 적은 기본 동사를 유지하고 Boon이 그
  동사의 조건과 결과를 바꾼다. 패치 노트도 무기별 Attack/Special과 Cast를
  별도 조정 대상으로 다룬다.
- `Risk of Rain 2`의 Skills 2.0은 런 전에 같은 역할 슬롯의 능력을 교체한다.
  개발사는 캐릭터 정체성은 유지하면서 일부 변형은 기존 기술과 완전히 다른
  행동이 되도록 했다고 설명한다.

**관찰:** 콘텐츠 수를 늘리는 방식은 새 버튼을 계속 추가하는 것이 아니라,
고정된 역할 슬롯 안에서 실행 방식과 위험을 바꾸는 쪽에 가깝다.

### 2. 액티브와 패시브는 입력과 책임으로 구분한다

- Lost Crown의 Athra 능력은 게이지를 소비하는 명시적 액티브다. Amulet은 독
  저항, 패리 성공 시 회복처럼 조건부 패시브이며 장착 제한이 있다.
- `Dead Cells`는 Mutation을 최대 3개까지 쌓는 패시브 전문화 층으로 설명하며,
  근접·원거리/기술·방패/회복의 경향을 나눈다. 무기와 액티브 기술은 별도
  슬롯과 재사용 대기시간을 가진다.
- Wizard of Legend의 공식 변경 기록도 Arcana와 Relic을 별도 분류하고 장착
  화면에 분류 표식을 추가했다. Arcana는 실행 행동, Relic은 지속 효과라는
  구분이 UI에서도 드러난다.

**관찰:** 패시브를 액티브 목록에 섞거나, 장비의 기본 행동을 다시 기술로
복제하면 선택의 의미가 흐려진다. 분류는 데이터와 화면 양쪽에서 보여야 한다.

### 3. 무기 차이는 사거리와 공격력보다 전달 방식에서 생긴다

- Lost Crown의 활과 Chakram은 모두 먼 적을 상대하지만 하나는 화살이고 다른
  하나는 충전 후 벽에 튕겨 돌아오는 투사체다.
- Dead Cells의 공식 패치 노트에는 무거운 곡사 폭발체인 Anathema, 긴 시전 뒤
  가까운 적 위에 광선을 소환하는 Indulgence, 적에게 순간 이동하는 Snake
  Fangs처럼 표적과 전달 방식이 전혀 다른 사례가 있다.
- Nine Sols는 베기, 튕겨내기, 부적 부착·폭발, 활을 한 전투 문법에 결합한다.
- Wizard of Legend의 공식 변경 기록에는 균열, 꽃잎, 유성, 선형 충격 등
  투사체 발사 이외의 공간 전달 방식이 반복해서 등장한다.

**관찰:** `빠른 활/느린 활/기동 활`은 충분한 콘텐츠 차이가 아니다. 조준,
발사, 회수, 재장전, 지면 지정, 시전 지연처럼 플레이어가 실제로 수행하는
과정이 달라야 한다.

### 4. 강한 능력은 별도 자원이나 명확한 공백을 가진다

- Lost Crown의 Athra는 공격 성공으로 채우고 피격으로 잃는 게이지를 쓴다.
- Hades의 Cast는 탄약 회수 규칙을 가지며, Call은 게이지에 묶인다.
- Wizard of Legend의 Signature는 공격으로 충전해 더 큰 결과를 만든다.
- Dead Cells의 강한 기술은 재사용 대기시간, 긴 시전, 저주 같은 명시적 비용을
  가진다.

**관찰:** 강한 액티브를 단순히 또 하나의 공격 버튼으로 만들면 기본 공격을
대체한다. 자원, 시전 공백, 실패 위험 중 하나는 보여야 한다.

### 5. 제한된 슬롯이 선택을 만든다

- Dead Cells는 Mutation을 최대 3개로 제한한다.
- Lost Crown은 Amulet 비용 한도와 두 단계 Athra 게이지를 사용한다.
- Risk of Rain 2는 역할이 고정된 스킬 슬롯에 변형을 넣는다.
- Wizard of Legend는 Arcana 분류를 유지하고 런 전 구성과 런 중 확장을
  구분한다.

**관찰:** 모든 해금 기술을 동시에 쓰는 구조보다 역할별 제한 슬롯이 읽기,
조작, 밸런스에 유리하다.

## Recommendations

### Cardborne에 채택할 원칙

1. 근접·원거리·방패 세 전투 도구는 유지하되, 각 모델은 `입력 리듬`, `표적`,
   `전달`, `자원`, `주 결과`, `명시적 약점`으로 구분한다.
2. 기본 전투 동사는 공격과 방어로 유지하고, 추가 액티브는 **제압**, **전술**,
   **정령술** 세 슬롯까지만 둔다.
3. 제압과 전술은 준비 화면에서 하나씩 고른다. 정령술은 장착한 정령석이
   결정하므로 자유 선택 버튼은 실질적으로 두 개다.
4. 장비 고유 특성, 장신구, 정령 동조, 런 카드는 패시브로 선언한다. 재료
   등급은 수치 성장이지 패시브 기술이 아니다.
5. 원거리 도구는 활, 화승총, 회수형 투척날, 지면 각인 마법처럼 서로 다른
   표적·자원 정책을 갖는다. 같은 투사체의 속도와 색만 바꾼 모델은 금지한다.
6. 새 콘텐츠는 기존 요소와 `활성 조건 + 주 표적 + 주 결과`가 같으면 추가하지
   않는다. 적어도 두 개의 핵심 축과 하나의 약점이 달라야 한다.

### 슬롯 수에 대한 프로젝트 판단

Cardborne의 권장 전투 액티브는 총 다섯 동사다.

| 동사 | 입력 | 책임 |
| --- | --- | --- |
| 상황 공격 | `F` / `X` | 가까운 적은 근접, 먼 적은 장착 원거리 도구로 반복 피해. |
| 방어 | `G` / `Y` | 방패의 방어·패리·반사 규칙 실행. |
| 제압 기술 | `Q` / `LB` | 적의 위치와 행동 시간을 바꿈. |
| 전술 기술 | `R` / `RB` | 영웅의 준비 상태, 적의 주목, 정보 우위를 바꿈. |
| 정령술 | `V` / `LT` | 축적한 공명으로 큰 원소 결과를 냄. |

점프, 대시, 상호작용, 소비 아이템은 전투 기술 슬롯에 포함하지 않는다. 추가
액티브를 네 개 이상 두면 게임패드에서 이동·상호작용과 경쟁하고 HUD가 다시
현재의 테스트베드식 버튼 목록으로 돌아갈 가능성이 높다. 이 수치는 외부
게임의 보편 법칙이 아니라 Cardborne의 현재 카메라, 조작, 콘텐츠 규모에 대한
설계 추론이다.

## Limitations

- 공식 자료는 시스템의 존재와 방향을 확인하는 데 충분하지만 전체 프레임
  데이터나 모든 입력 조합을 공개하지 않는다.
- 서로 다른 장르와 카메라를 가진 게임을 그대로 복제하지 않았다. Cardborne의
  자동 근접/원거리 선택과 2D 횡스크롤 가독성에 맞춰 원칙만 적용했다.
- 세 추가 액티브가 실제로 편한지는 키보드와 게임패드 30분 플레이테스트,
  버튼 오입력률, 미사용 슬롯 비율로 검증해야 한다.
- 제안한 도구 수와 수치는 구현 전 기준값이다. 기능 책임은 고정하되 세부
  타이밍과 피해는 플레이테스트로 조정한다.
