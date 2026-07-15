---
type: spec
status: active
owner: BK
created: 2026-07-15
last_reviewed: 2026-07-15
source: 2D platformer map-design research, current Cardborne PRD, authored-room contract, movement metrics, and fixed-stage validation evidence
topic: Canonical Cardborne map-design and gameplay-verticality guideline
scope: Future normal-stage, optional-room, combat-room, and traversal-room authoring for the Web vertical slice
related:
  - ../product/2d_platform_action_card_game_prd.md
  - ./MAP_AUTHORING_PIPELINE_CONTRACT.md
  - ./PROCEDURAL_REGION_GENERATION.md
  - ./ENEMIES_TRAPS_GIMMICKS.md
  - ../research/2d_platformer_map_design_research_2026-07-15.md
  - ../../.agent/execplans/2026-07-15-fixed-stage-map-enhancement.md
---

# 2D Platformer Map Design Guideline

## Purpose

Cardborne의 모든 future map이 단순히 높고 복잡해 보이는 데서 끝나지 않고,
이동·전투·경로 선택·시선·리듬을 실제로 바꾸는 공간이 되게 한다.

이 문서는 platformer map composition의 canonical design rule이다.
[Map Authoring Pipeline Contract](./MAP_AUTHORING_PIPELINE_CONTRACT.md)가
scene/resource/socket/anchor의 기술 계약을 소유하고, 이 문서는 그 room과
stage가 제공해야 하는 플레이 경험을 소유한다.

## Scope

적용 대상:

- 세 normal stage와 이후 추가되는 authored stage
- required route, optional branch, forward rejoin, shortcut
- traversal, combat, hazard, choice, objective, safe, exit room
- terrain, enemy, hazard, reward, recovery anchor, camera framing의 조합
- blockout, validator, rendered capture, continuous playtest

## Non-Goals

- UI typography, HUD, modal, localization의 시각 overhaul
- gamepad 또는 다른 입력 장치 지원
- 새로운 movement skill, enemy archetype, card system의 추가
- world art asset 수량이나 최종 illustration style 결정
- dormant random planner의 production 재활성화
- death/save-point policy 변경

UI 작업과 분리하더라도 landing, pit, collision, enemy tell, reward,
route silhouette가 world 안에서 읽혀야 하는 책임은 map authoring에 남는다.

## Design Thesis

높이 차이는 다음 다섯 질문 중 하나 이상의 답을 바꿔야 한다.

1. 어디로 갈 것인가?
2. 누구를 먼저 상대할 것인가?
3. 어디서 안전하게 관찰하거나 회복할 것인가?
4. 어떤 이동 동사와 타이밍을 사용할 것인가?
5. 무엇을 보고 다음 행동을 결정할 것인가?

어느 답도 바뀌지 않으면 그 높이 차이는 gameplay verticality로 세지 않는다.

## Vocabulary

| Term | Project meaning |
| --- | --- |
| Movement envelope | 현재 player가 baseline 상태에서 가능한 jump, double jump, dash, fall recovery의 검증된 범위 |
| Commitment | 되돌리기 어렵거나 위험을 감수해야 하는 jump, drop, dash, gate 진입 |
| Safe zone | 현재 enemy/hazard reach 밖에서 다음 행동을 관찰하고 계획할 수 있는 공간 |
| Rhythm group | preview/teach에서 시작해 commit과 consequence를 거쳐 recovery에서 끝나는 짧은 challenge phrase |
| Route line | player가 한 방 또는 연속 방을 통과하는 구별 가능한 이동선 |
| Portal | route line이 갈라지거나 재합류하는 지점 |
| Forward rejoin | optional line이 출발점으로 완전히 되돌아가지 않고 진행 방향 앞쪽에서 main line과 합쳐지는 구조 |
| Spatial verb | climb, controlled drop, crossfire flank, hazard timing, loop return처럼 공간이 요구하는 주된 행동 |
| Structural verticality | 총 높이 범위와 상승·하강 구조 |
| Navigational verticality | 높이에 따른 분기, loop, shortcut, rejoin |
| Tactical verticality | 높이에 따른 threat, cover, attack, escape 변화 |
| Perceptual verticality | 높이 사이의 목표, 착지, 위험, 보상 가독성 |
| Rhythmic verticality | ascent, descent, pause, commit, recovery가 만드는 행동 리듬 |
| Thematic verticality | stage의 장소와 사건을 표현하는 height profile |

## Requirements

### R1. Freeze the playable envelope first

- 모든 critical transition은 현재 `MovementMetrics.gd` 기준으로 Traveler
  baseline에서 가능해야 한다.
- card, equipment, damage boost, enemy bounce, speedrun trick은 required
  route의 전제가 될 수 없다.
- optional expert line은 baseline으로도 가능해야 하며, 숙련으로 더 빠르게
  통과할 수는 있다.
- intended jump와 impossible gap 사이에 애매한 범위를 두지 않는다.
- landing과 recovery space는 성공 arc뿐 아니라 약간 짧거나 긴 입력도
  고려한다.

### R2. Give each stage one spatial thesis

stage blockout 전에 다음을 한 문장으로 작성한다.

> 이 stage는 [장소/상황]에서 [signature spatial verb]를 배우고 변형해,
> 마지막에 [known elements]를 결합해서 통과하는 경험이다.

stage에는 다음이 있어야 한다.

- 하나의 signature spatial verb
- 그 verb의 teach, transform, test 위치
- macro height profile과 방향 전환 이유
- peak와 recovery 위치
- required line과 optional line의 역할 차이
- stage-specific geometry vocabulary

색상과 enemy variant만 바뀌고 topology가 같다면 stage identity로
인정하지 않는다.

### R3. Give each room one sentence of intent

모든 authored room은 implementation 전에 다음 worksheet를 채운다.

| Field | Required answer |
| --- | --- |
| Room ID and role | stable ID와 start/traversal/combat/hazard/choice/optional/safe/exit |
| One-sentence intention | player가 여기서 무엇을 보고 어떤 결정을 해야 하는가 |
| Rhythm role | preview/teach, transform, combine/test, release 중 하나 |
| Safe entry | 첫 control frame에서 관찰 가능한 위치 |
| Primary line | baseline route와 필요한 movement |
| Alternate line | 없으면 none; 있으면 다른 verb/risk/reward |
| Commitment | player가 결정을 확정하는 지점 |
| Consequence | 성공, 실패, 낙하, 우회가 어디로 이어지는가 |
| Enemy-terrain relation | enemy A가 terrain B 때문에 response C를 요구한다 |
| Reward/recovery | challenge의 끝과 다음 rhythm 경계 |
| Camera proof | commitment 전에 보이는 landing, threat, goal |

“적을 잡고 오른쪽으로 간다”처럼 어느 평지에도 적용되는 문장은
room intention으로 충분하지 않다.

### R4. Compose rhythm groups, not uniform density

기본 sequence는 다음과 같다.

1. Preview/Teach: 안전한 조건에서 한 요소와 response를 보여준다.
2. Transform: 같은 요소를 다른 높이, 방향, 간격, timing으로 바꾼다.
3. Combine/Test: 이미 배운 요소만 결합해 집중 challenge를 만든다.
4. Release: safe zone, reward, 전망, 쉬운 mastery beat로 긴장을 푼다.

모든 room이 더 어려워질 필요는 없다. 그러나 같은 setup을 의미 변화 없이
반복해서는 안 된다. stage의 어려움은 직선 상승이 아니라 peak와 release의
파형으로 조절한다.

### R5. Make vertical routes disagree

upper/lower 또는 left/right split은 다음 항목 중 최소 둘이 달라야 한다.

- movement verb 또는 timing
- enemy/hazard exposure
- traversal time
- reward 또는 positional advantage
- recovery cost
- information gained

추가 규칙:

- main line은 첫 진입에서 이해 가능해야 한다.
- optional line은 다른 방향, 더 높은 마찰, reward clue 중 하나로
  optional임을 알려야 한다.
- 가능하면 forward rejoin 또는 짧은 loop를 사용한다.
- 같은 hub로의 완전 왕복은 reward가 그 비용을 정당화할 때만 사용한다.
- 두 route가 같은 발판 순서와 같은 threat를 공유하면 한 route로 간주한다.
- route choice를 stage 한 방에 몰아넣지 않는다.

### R6. Author combat and terrain together

enemy count와 y-span은 하한선이다. combat room은 아래 질문을 통과해야 한다.

- 각 enemy의 threat lane은 무엇인가?
- player가 관찰할 safe zone은 어디인가?
- primary response는 guard, jump, dash, elevation change, flank 중 무엇인가?
- 다른 높이의 enemy를 어느 순서로 처리할 이유가 있는가?
- 아래로 떨어졌을 때 failure, recovery, alternate line 중 무엇이 되는가?
- exit가 combat 정보를 가리거나 unavoidable damage를 만들지 않는가?

권장 조합 예:

| Pattern | Terrain question | Enemy use |
| --- | --- | --- |
| Exposed upper / sheltered lower | 빠른 위 line을 택할지 cover가 있는 아래 line을 택할지 | shooter가 upper exposure, walker/charger가 lower occupancy를 만든다. |
| Perch and flank | 정면 lane을 넘을지 side ledge로 올라갈지 | shield guard 또는 sentry를 다른 각도에서 처리한다. |
| Drop basin escape | 떨어져 reward를 얻고 어느 side를 통해 복귀할지 | leaper가 basin center를 압박하고 shooter가 한 exit를 통제한다. |
| Cross-lane transfer | 두 높이 사이를 언제 바꿀지 | charger의 horizontal lane과 shooter/sentry line이 교차한다. |
| Recovery ledge | peak 뒤 짧게 재정비할지 바로 shortcut을 탈지 | 약한 enemy 하나가 mastery를 확인하되 safe zone을 침범하지 않는다. |

enemy를 빈 공간 채우기 위해 배치하지 않는다. intention 문장에 역할이 없는
enemy는 제거하거나 다른 room으로 옮긴다.

### R7. Show critical information before commitment

- irreversible jump/drop 전에 landing, safe-drop cue, 또는 recovery outcome이
  보여야 한다.
- enemy startup warning과 intended response space를 같은 camera frame에서
  확인할 수 있어야 한다.
- room entry와 exit에 짧은 buffer를 둔다.
- thin collision은 의도적으로 불안감을 만들 때만 사용하고, 일반 safe
  surface는 시각적으로 충분한 두께를 갖는다.
- foreground와 decor는 collision edge, pit, reward, enemy silhouette를
  가리지 않는다.
- camera 밖으로 나가야 성공하는 critical action을 만들지 않는다.

### R8. Use rewards as route language

- reward는 optional line의 방향, risk, completion을 설명한다.
- high-value reward는 challenge 중간보다 challenge 끝 또는 안전한 banking
  지점에 둔다.
- breadcrumb는 초반과 새로운 verb 소개에서 더 명확하게 사용하고,
  이미 학습한 구간에서는 줄인다.
- collectible을 모든 jump arc에 뿌려 시각 소음으로 만들지 않는다.
- reward가 가리키는 곳이 실제 secret, route, safe drop이 아니면 안 된다.

### R9. Make recovery part of the room

- required room 진입점은 hazard와 enemy line of fire 밖이어야 한다.
- fall recovery anchor는 death retry가 아니라 local traversal recovery라는
  현재 의미를 유지한다.
- recovery가 challenge를 무효화하거나 reward duplication을 만들지 않는다.
- peak 뒤의 release 위치는 다음 commitment를 관찰할 수 있어야 한다.
- challenge 길이와 stage retry 비용을 함께 playtest한다.

### R10. Keep stage shape and place coherent

macro sketch는 room 목록보다 먼저 다음을 보여야 한다.

- start와 exit의 상대 위치
- major ascent/descent와 direction reversal
- signature landmark 또는 objective
- branch divergence와 rejoin
- combat peak, hazard peak, recovery
- stage가 왜 오르거나 내려가거나 되접히는지

Ruin, Flooded, Sanctum의 silhouette는 label을 지워도 구별돼야 한다.

## Approved Composition Patterns

| Pattern | Use | Guardrail |
| --- | --- | --- |
| Preview → Commit → Consequence → Recovery | 한 room의 기본 challenge phrase | entry에서 모든 pressure를 동시에 켜지 않는다. |
| Teach → Transform → Test → Release | stage 내 mechanic arc | test에는 아직 소개하지 않은 필수 요소를 넣지 않는다. |
| Upper risk / lower safety | vertical route choice | 실제 risk, time, reward가 달라야 한다. |
| Controlled drop and return | basin, crypt, flooded space | landing 또는 safe-drop cue와 복귀 line이 보여야 한다. |
| Forward-rejoining loop | optional reward와 exploration | rejoin이 main progress를 되돌리지 않아야 한다. |
| Mastery shortcut | 숙련자 replay와 빠른 line | baseline intention을 가리거나 우연히 초보를 함정에 넣지 않는다. |
| Crossfire with flank | tactical vertical combat | entry safe zone과 하나 이상의 cover/elevation response를 보장한다. |
| Vista/cooldown | peak 뒤 pace break | 긴 빈 복도가 아니라 전망, reward, 다음 goal 정보가 있어야 한다. |

## Rejected Anti-Patterns

- viewport-height range를 채우기 위한 긴 계단
- 이유 없이 같은 간격으로 반복되는 floating ledge
- 같은 행동을 요구하는 장식용 upper/lower split
- 모든 optional room이 하나의 중앙 hub에서 갈라지는 구조
- 적을 다른 y 좌표에 두었다는 이유만으로 multi-elevation combat이라 부르기
- 보이지 않는 landing 또는 camera 밖 dash
- safe surface와 death pit이 같은 silhouette를 갖는 blockout
- empty space를 enemy로 채워 combat density를 맞추기
- stage마다 같은 topology에 enemy palette만 교체하기
- 자동 metric pass를 최종 quality verdict로 사용하기

## Authoring Workflow

### Gate A: stage brief

- [ ] spatial thesis가 한 문장이다.
- [ ] signature verb와 teach/transform/test가 정해졌다.
- [ ] macro height profile에 의도적인 peak와 release가 있다.
- [ ] branch와 rejoin이 stage 전체에 분포한다.
- [ ] stage identity가 geometry vocabulary로 설명된다.

### Gate B: macro blockout

- [ ] baseline route가 current movement envelope로 clear된다.
- [ ] required route는 boost 없이 가능하다.
- [ ] start, exit, peak, recovery, branch가 sketch와 일치한다.
- [ ] monotonic ascent/descent라면 theme와 rhythm상 이유가 기록됐다.
- [ ] optional line은 main line과 다른 경험을 준다.

### Gate C: room composition

- [ ] 모든 room worksheet가 채워졌다.
- [ ] entry safe zone과 camera preview가 있다.
- [ ] commitment, consequence, recovery가 식별된다.
- [ ] combat room은 enemy-terrain relation 문장을 통과한다.
- [ ] reward는 route 또는 risk를 설명한다.
- [ ] 의미 없는 enemy, ledge, pickup을 제거했다.

### Gate D: sequence pass

- [ ] teach 전에 test가 나오지 않는다.
- [ ] 동일 setup이 의미 변화 없이 반복되지 않는다.
- [ ] peak 뒤 release가 있다.
- [ ] 8초 이상 movement/combat/route/reward decision vacuum이 드물다.
- [ ] stage clear까지 difficulty와 novelty의 파형을 설명할 수 있다.

### Gate E: rendered validation

- [ ] 1280×720에서 다음 commitment와 landing이 읽힌다.
- [ ] compact supported viewport에서 collision과 enemy tell이 잘리지 않는다.
- [ ] required path, optional path, reward를 debug label 없이 설명할 수 있다.
- [ ] continuous traversal에서 camera가 뒤늦게 정보를 보여주지 않는다.
- [ ] combat room을 실제 input과 real damage path로 통과했다.
- [ ] fall recovery, stage retry, room reset이 soft lock과 duplication을 만들지 않는다.

## Measurement Contract

### Automated hard gates

기존 기술 계약의 다음 검사를 유지한다.

- room/resource/socket/anchor validity
- current movement envelope 기준 critical-route reachability
- stage load fail-closed behavior
- enemy and hazard anchor compatibility
- required recovery anchor
- stage vertical range, meaningful elevation changes, enemy floors,
  multi-elevation candidate count, maximum empty-room run

추가할 diagnostic:

- cumulative ascent와 descent의 비율
- meaningful direction reversal 수
- graph portal, optional branch, forward rejoin 수
- branch divergence가 지속되는 room/screen 거리
- branch가 stage 어느 구간에 분포하는지
- required route의 distinct elevation band 방문

이 diagnostic을 하나의 합산 quality score로 만들지 않는다. 한 수치가 다른
치명적 결함을 상쇄하게 해서는 안 된다.

### Manual critical gates

다음은 자동화하지 않고 rendered evidence와 playtest note를 남긴다.

- route가 처음 보는 사람에게 읽히는가
- 높이가 실제 선택이나 response를 바꾸는가
- enemy와 terrain이 하나의 intention을 만드는가
- safe zone이 실제 threat reach 밖인가
- reward가 risk와 방향을 설명하는가
- stage silhouette와 pacing이 다른 stage와 구별되는가

## Review Rubric

각 차원을 0, 1, 2로 따로 평가한다. 합계로 pass/fail을 결정하지 않는다.

| Score | Meaning |
| --- | --- |
| 0 | 없거나 오해를 유발하며 수정 전 release 불가 |
| 1 | 존재하지만 약하거나 일부 room에서만 작동 |
| 2 | stage thesis와 room intention을 일관되게 지원 |

평가 차원:

- Structural
- Navigational
- Tactical
- Perceptual
- Rhythmic
- Thematic

reachability, no-soft-lock, critical information visibility 중 하나라도 0이면
다른 점수와 무관하게 block한다.

## Acceptance Criteria

새 stage 또는 큰 map revision은 다음을 모두 만족해야 한다.

1. 모든 required transition이 baseline Traveler로 자동 검증된다.
2. 모든 required room에 one-sentence intention, safe entry, commitment,
   consequence, recovery가 있다.
3. stage에 한 signature spatial verb와 teach/transform/test/release arc가 있다.
4. macro height profile이 theme와 pacing을 설명하며, 단순 range 충족만으로
   승인되지 않는다.
5. 모든 route split이 movement, risk, time, reward 중 최소 둘에서 다르다.
6. optional route가 시각적으로 구분되고 reward 또는 shortcut으로 비용을
   정당화한다.
7. 모든 combat room에 검증 가능한 enemy-terrain relation이 있다.
8. 다음 critical landing, threat, goal이 commitment 전에 camera에 보인다.
9. stage별 geometry vocabulary와 silhouette가 label 없이 구별된다.
10. headless validator, rendered capture, continuous baseline clear,
    real-combat playtest가 모두 통과한다.

## Related

- 근거와 current-state diagnosis:
  [2D Platformer Map Design Research](../research/2d_platformer_map_design_research_2026-07-15.md)
- 현행 세 stage 수정 순서:
  [Fixed Stage Map Enhancement ExecPlan](../../.agent/execplans/2026-07-15-fixed-stage-map-enhancement.md)
- 기술 authoring contract:
  [Map Authoring Pipeline Contract](./MAP_AUTHORING_PIPELINE_CONTRACT.md)
- enemy geometry and safety contract:
  [Enemies, Traps, and Gimmicks](./ENEMIES_TRAPS_GIMMICKS.md)
