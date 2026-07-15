---
type: evidence
status: active
created: 2026-07-15
last_reviewed: 2026-07-15
source: Primary academic work, first-party developer material, selected critical reviews, and current Cardborne code, validators, and rendered captures
topic: 2D platformer map structure, gameplay verticality, encounter composition, routing, and pacing
scope: Cross-case research and current-state diagnosis for Cardborne's three fixed normal stages
related:
  - ../product/2d_platform_action_card_game_prd.md
  - ../design/MAP_AUTHORING_PIPELINE_CONTRACT.md
  - ../design/2D_PLATFORMER_MAP_DESIGN_GUIDELINE.md
  - ../../.agent/execplans/2026-07-15-fixed-stage-map-enhancement.md
  - ./plan_validity_audit_2026-07-15.md
---

# 2D Platformer Map Design Research

## Purpose

다양한 2D platformer의 연구 문헌, 개발자 설명, 설계 이미지, 비평을
교차 검토해 다음 질문에 답한다.

1. 높낮이가 있다는 사실과 실제로 수직적인 플레이가 된다는 것은 어떻게 다른가?
2. 장르와 게임 규모가 달라도 반복해서 나타나는 맵 설계 규칙은 무엇인가?
3. 특정 게임의 맵이 좋은 평가를 받은 핵심은 무엇이며, Cardborne에 무엇을
   옮겨야 하는가?
4. 현재 Cardborne의 세 고정 스테이지는 그 기준에서 어디까지 통과하고
   어디서 실패하는가?

이 문서는 근거와 진단을 보존하는 evidence다. 향후 제작 규칙은
[2D Platformer Map Design Guideline](../design/2D_PLATFORMER_MAP_DESIGN_GUIDELINE.md),
실제 수정 순서는
[Fixed Stage Map Enhancement ExecPlan](../../.agent/execplans/2026-07-15-fixed-stage-map-enhancement.md)
이 담당한다.

## Executive Finding

핵심 결론은 한 문장으로 정리된다.

> 높이 차이가 플레이어의 경로, 전투 위치, 위험 판단, 시선, 행동 리듬 중
> 적어도 하나를 바꾸지 않는다면 그것은 수직적인 배경 또는 계단이지,
> gameplay verticality가 아니다.

현재 Cardborne은 structural verticality, 즉 총 높이 범위와 발판 변화는
확보했다. 그러나 navigational, tactical, perceptual, rhythmic verticality는
약하다. 자동 검증은 세 스테이지를 모두 통과시키지만, 경로 선택이 한 방에
집중되고, Ruin은 하강이 전혀 없는 단조로운 상승이며, 캡처에서 보이는
선택 방은 서로 다른 플레이를 만드는 두 경로보다 넓은 평지와 떠 있는
발판에 가깝다.

외부 사례가 공통으로 보여주는 해법은 맵을 더 높게 만들거나 몬스터 수만
늘리는 것이 아니다. 먼저 이동 물리를 고정하고, 각 방에 한 가지 의도를
부여한 뒤, 안전한 소개 → 변형 → 결합/시험 → 회복의 리듬을 만든다.
분기는 서로 다른 위험과 행동을 제공해야 하며, 적·보상·카메라·지형은
같은 의도를 설명해야 한다.

## Method

### Evidence hierarchy

| 우선순위 | 근거 | 이 문서에서의 용도 |
| --- | --- | --- |
| 1 | 학술 논문과 원 개발자의 설계 설명 | 공통 어휘, 제작 과정, 의도와 제약 |
| 2 | 개발 중 맵·방 이미지와 최종 플레이 이미지 | 텍스트 주장과 실제 공간 구조의 대조 |
| 3 | 전문 비평 | 어떤 결과가 플레이어 경험으로 높게 평가됐는지 확인 |
| 4 | Cardborne 코드, 리소스, validator, 캡처 | 현재 구현의 사실 확인 |

비평은 설계 의도를 증명하는 1차 자료로 사용하지 않았다. 개발자 자료에서
확인한 설계가 실제 평가에서도 장점으로 인식됐는지 보조적으로 확인하는
용도다.

### Scope controls

- 2D action platformer, precision platformer, exploration platformer,
  roguelite platformer를 함께 비교했다.
- Cardborne은 짧은 고정 스테이지이므로 Hollow Knight의 거대한 world map을
  그대로 모방하지 않는다. 연결성, 지리적 일관성, shortcut의 원리만 취한다.
- 절차 생성 사례는 Cardborne의 dormant random planner를 다시 켜기 위한
  근거가 아니다. 오히려 authored purpose와 고정 topology의 필요성을
  검토하는 데 사용했다.
- 게임패드, 콘솔 입력, 다른 플랫폼을 위한 설계는 범위가 아니다.
- 조사일은 2026-07-15다. 오래된 자료도 다루지만 분석 대상인 설계 원리는
  해당 게임과 발표 내용에 고정돼 있어 시의성 위험이 낮다.

## Working Definition: Six Dimensions of Verticality

| 차원 | 질문 | 실패 예 |
| --- | --- | --- |
| Structural | 플레이 공간에 의미 있는 높이 범위와 상승·하강이 있는가? | 긴 평지 위에 장식 발판 몇 개만 둔다. |
| Navigational | 높이 차이가 실제 경로 선택, 우회, 재합류, shortcut을 만드는가? | 위·아래 발판이 결국 같은 점프 순서와 같은 보상으로 이어진다. |
| Tactical | 고도와 지형이 공격, 방어, 회피, 적 우선순위를 바꾸는가? | 적이 다른 y 좌표에 있지만 한 줄로 다가와 같은 방식으로 죽는다. |
| Perceptual | 다음 착지점, 위협, 목표, 보상이 높이 사이에서도 읽히는가? | 카메라 밖으로 점프하거나 보이지 않는 바닥으로 떨어져야 한다. |
| Rhythmic | 상승·하강·정지·commit·recovery가 행동의 구절을 만드는가? | 같은 간격의 계단을 끝까지 반복한다. |
| Thematic | 수직 이동이 장소와 스테이지의 사건을 표현하는가? | 폐허·하수도·성소가 색만 다르고 같은 계단 실루엣을 쓴다. |

좋은 맵이 여섯 차원 모두를 같은 강도로 가질 필요는 없다. Mario식
선형 dexterity stage, Sonic식 다중 경로, Donkey Kong식 탐험은 서로 다른
비중을 갖는다. 다만 Cardborne처럼 vertical action을 명시한 게임에서
Structural만 통과하는 것은 충분하지 않다.

## Sources

모든 외부 링크는 2026-07-15에 확인했다.

| Source | 유형 | 사용한 근거 | 한계 |
| --- | --- | --- | --- |
| Smith, Cha, Whitehead, [A Framework for Analysis of 2D Platformer Levels](https://expressiveintelligence.github.io/papers/smith-sandbox-08.pdf), SIGGRAPH Sandbox 2008 | peer-reviewed framework | platform, obstacle, movement aid, collectible, trigger; rhythm group; cell과 portal | 전투 중심 현대 action platformer의 모든 세부를 다루지는 않음 |
| Khalifa, de Mesentier Silva, Togelius, [Level Design Patterns in 2D Games](https://www.gamedeveloper.com/design/level-design-patterns-in-2d-games) | 30개 이상 게임의 pattern 연구를 풀어쓴 저자 자료 | Guidance, Safe Zone, Foreshadowing, Layering, Branching, Pace Breaking | 넓은 2D 장르 공통 패턴이라 프로젝트별 조정 필요 |
| Aramini, Lanzi, Loiacono, [An Integrated Framework for AI Assisted Level Design in 2D Platformers](https://arxiv.org/abs/1804.09153) | academic paper | 이동 물리 기반 jump graph, edge difficulty와 success probability, human validation | 자동 지표가 재미·명료성까지 증명하지는 않음 |
| Nintendo, [Iwata Asks: New Super Mario Bros. Wii, Vol. 2 Page 5](https://iwataasks.nintendo.com/interviews/wii/nsmb/1/4/) | first-party developer interview | World 1-1의 실패 경우까지 종이에 시뮬레이션한 자연스러운 학습과 반복 수정 | 특정 입문 stage 사례 |
| Yacht Club Games, [Specter of Torment Level Design Deep Dive 1](https://www.yachtclubgames.com/blog/specter-of-torment-level-design-deep-dive-1-5/), [2](https://www.yachtclubgames.com/blog/specter-of-torment-level-design-deep-dive-2-5/), [3](https://www.yachtclubgames.com/blog/specter-of-torment-level-design-deep-dive-3-5), [4](https://www.yachtclubgames.com/blog/specter-of-torment-level-design-deep-dive-4-5), [5](https://www.yachtclubgames.com/blog/specter-of-torment-level-design-deep-dive-5-of-5/) | five-part first-party deep dive | thematic shape, encounter spacing, teach/transform/test, cooldown, routing language, optional difficulty, polish passes | 한 캐릭터와 화면 단위 방 구조에 최적화된 방법 |
| GDC, [Level Design Workshop: Designing Celeste](https://www.gdcvault.com/play/1024307/Level-Design-Workshop-Designing-Celeste) | first-party conference session | 300개 이상 방, area map, 암묵적 학습, reward, speedrunner 고려 | 공개 페이지는 개요 중심; 세부는 발표 영상 의존 |
| GDC, [Empowering the Player: Level Design in N++](https://www.gdcvault.com/play/1023282/Empowering-the-Player-Level-Design) | first-party conference session | 선형 목표 안의 자율성, 초보와 10년 숙련자를 같은 맵으로 지원, 대량 다양성 | 공개 페이지는 개요 중심 |
| Team Cherry interview, [How to design a great Metroidvania map](https://www.pcgamer.com/how-to-design-a-great-metroidvania-map/) | direct developer interview with development maps | central hub, wrapping regions, softened gating, shortcuts, spatial coherence, black-tile-to-place pipeline | 장편 exploration world이므로 stage 규모에 맞춘 축소 필요 |
| Team Cherry, [Hollow Knight: Then and Now](https://www.teamcherry.com.au/blog/hollow-knight-then-and-now) | first-party visual comparison | 동일 geometry에 color, depth, foreground/background context를 더해 장소성을 만든 과정 | topology보다 art dressing에 초점 |
| Sébastien Bénard, [Building the Level Design of a Procedurally Generated Metroidvania](https://www.gamedeveloper.com/design/building-the-level-design-of-a-procedurally-generated-metroidvania-a-hybrid-approach-) | Dead Cells lead designer deep dive | fixed world frame, purpose-specific authored tiles, biome graph, peak/break pacing, enemy placement constraints | 2017 개발 시점의 구조 |
| Derek Yu interview, [First Look: Spelunky 2](https://blog.playstation.com/2018/08/29/first-look-spelunky-2-gameplay-mossmouth-interview/) | first-party creator interview | room templates로 먼저 safe path 보장, 상호작용 가능한 단순 요소와 두 번째 탐험 layer | sequel preview 시점 자료 |
| [Specter of Torment review](https://www.destructoid.com/reviews/review-shovel-knight-specter-of-torment/), [Celeste review](https://www.gamespot.com/reviews/celeste-review-more-than-just-a-great-platformer/1900-6416843/), [N++ review](https://www.pcgamer.com/n-review/), [Hollow Knight review](https://www.gamespot.com/reviews/hollow-knight-review-an-exceptional-adventure/1900-6416972/) | professional criticism | movement와 room design의 결합, refined challenge, fluid movement, pacing, distinct/interlocking spaces가 실제 장점으로 인식됐는지 보조 확인 | 평가자의 주관이며 causal proof가 아님 |

## Visual Evidence

외부 이미지는 저작권 자산을 저장소에 복제하지 않고 원문 링크로만 참조했다.

| 시각 자료 | 관찰 | 설계상 의미 |
| --- | --- | --- |
| Smith et al. PDF Figures 7–8, pp. 4–5 | 바나나 화살표와 coin arc가 이동선·비밀·최적 jump·위험 보상을 동시에 표시한다. | reward는 장식이 아니라 경로 문법이 될 수 있다. |
| Smith et al. PDF Figures 10–11, p. 5 | 비슷한 발판 반복도 coin과 enemy 배치, 중간 pause에 따라 별개의 action phrase가 된다. | geometry만 세면 rhythm을 오판한다. |
| Smith et al. PDF Figure 12, p. 6 | 서로 다른 높이의 linear cell들이 portal에서 갈라지고 다시 연결된다. | 수직성은 높이 범위보다 divergence와 rejoin 구조로 읽힌다. |
| Yacht Club의 [Iron Whale concept plan](https://img2.storyblok.com/fit-in/0x800/filters%3Aformat%28svg%29/f/93161/1208x408/9282ef99b0/ironwhaleplan.png) | 해변 → 잠수 → 바닥 encounter → 선체 침투 상승 → 추격 → cooldown → boss가 큰 높이 파형과 사건 순서로 함께 그려진다. | stage silhouette가 theme, 난이도, mechanic arc를 동시에 운반한다. |
| Team Cherry의 [초기·중기 Hollow Knight map images](https://www.pcgamer.com/how-to-design-a-great-metroidvania-map/) | Crossroads를 중심으로 구역이 감싸고, 세로 shaft와 가로 corridor, side room, shortcut 후보가 다른 색·형태로 묶인다. | 방을 먼저 나열하지 않고 세계 위치와 이동 shape를 먼저 정한다. |
| [Ruin route-choice capture](../../.codex-runtime/uiux/fixed_stage/ruin_route_choice.png) | 넓은 평지, 단순한 세 개의 떠 있는 ledge, 큰 상부 공백이 보인다. 위/아래 선택의 payoff와 재합류가 한 화면에서 읽히지 않는다. | 구조적 높이는 있으나 navigational verticality가 약하다. |
| [Flooded route-choice capture](../../.codex-runtime/uiux/fixed_stage/flooded_route_choice.png) | 넓은 basin과 두 긴 수평 ledge가 있지만 경로별 행동·위험 차이가 불분명하다. | stage signature보다 평행 이동선처럼 보인다. |
| [Sanctum route-choice capture](../../.codex-runtime/uiux/fixed_stage/sanctum_route_choice.png) | 세로로 쌓인 geometry는 늘었지만 가는 bar와 큰 void 때문에 목표와 이동선이 prototype scaffold처럼 읽힌다. | structural verticality가 perceptual verticality를 보장하지 않는다. |
| [Sanctum return capture](../../.codex-runtime/uiux/fixed_stage/sanctum_reliquary_return.png) | 높이 차이와 gap은 있으나 reward, branch, return의 관계가 공간에서 드러나지 않는다. | backtracking 동선의 이유와 기억 지점이 더 필요하다. |

Cardborne 캡처는
`tools/capture_fixed_stage_screenshots.gd`가 생성하는 runtime evidence다.
파일이 없으면 같은 도구로 재생성해야 하며, 정지 화면만으로 연속 traversal을
증명할 수는 없다.

## Cross-Case Analysis

### 1. Movement envelope comes before geometry

Smith의 framework는 avatar의 horizontal/vertical control을 level component
해석의 전제로 둔다. N++는 적은 동사로도 momentum과 angle이 달라지면
수천 개 level의 행동 공간을 만들 수 있음을 보여준다. Shovel Knight는
Specter Knight의 wall-run과 dash-slash 때문에 기존 stage geometry의
대부분을 다시 만들었고, Dead Cells는 monster마다 필요한 platform width,
space, coexistence 조건을 둔다.

공통 규칙은 “예쁜 실루엣을 먼저 그리고 캐릭터를 맞춘다”가 아니다.
기본 jump, dash, recovery, camera framing을 먼저 고정하고, gap과 height를
그 envelope에 맞춰 설계해야 한다.

Cardborne은 `MovementMetrics.gd`와 conservative reachability 검증이 있어
이 기반은 비교적 강하다. 문제는 legality가 experience quality로 잘못
승격된 데 있다.

### 2. A room is an intention, not a container

Dead Cells는 treasure, merchant, combat room의 platform layout이 달라야
한다고 명시한다. Yacht Club은 방의 모든 enemy, object, gem이 한 의도를
위해 작동하는지 점검하고, 빈 곳을 채우기 위해 enemy를 놓는 것을 실패로
본다. Smith의 rhythm group도 geometry의 모음이 아니라 하나의 challenge
phrase다.

따라서 “combat room”은 적이 있는 방이라는 뜻으로는 부족하다. 예를 들어
“낮은 lane의 charger를 피하려면 위 ledge로 이동하지만, 위에는 shooter의
line of sight가 열린다”처럼 terrain과 enemy가 하나의 질문을 만들어야 한다.

### 3. Good difficulty is staged as learning and transformation

Mario World 1-1은 신규 플레이어가 mushroom을 놓치는 경우까지 예상해
pipe로 되돌려 보내며 설명문 없이 학습시킨다. Shovel Knight는 안전한
상황에서 enemy property를 보여준 뒤, pit·좁은 공간·다른 object를 차례로
겹치고 최종 test 뒤 cooldown을 둔다. Khalifa 등의 공통 패턴도
Foreshadowing과 Layering을 분리한다.

공통 sequence는 다음과 같다.

| 단계 | 플레이어 경험 | 맵의 역할 |
| --- | --- | --- |
| Preview / Teach | 새 요소를 보고 실험한다. | safe entry, 한정된 선택, 실패 비용 완화 |
| Transform | 같은 동사를 다른 높이·방향·타이밍으로 쓴다. | 지형 변화로 익숙한 행동의 의미 변경 |
| Combine / Test | 이미 배운 요소 둘 이상을 함께 해결한다. | 높은 집중, 명확한 정보, 공정한 recovery |
| Release | 긴장이 풀리고 보상·전망·shortcut을 얻는다. | 다음 rhythm group의 경계 |

난이도를 매 방 직선적으로 올리는 것은 이 원칙이 아니다. peak 뒤의 쉬운
적은 숙련을 체감시키는 보상이 될 수 있다.

### 4. Branching is meaningful only when the routes disagree

Smith의 cells/portals, Khalifa의 Branching, N++의 self-directed line,
Hollow Knight의 shortcuts는 모두 분기를 “길이 둘”이 아니라 선택의
차이로 다룬다. 좋은 upper/lower split은 다음 중 둘 이상이 다르다.

- 요구 동사: 정밀 jump, dash timing, combat clear, controlled drop
- 위험: 낙하, crossfire, hazard exposure, 회복 지점 거리
- 속도: 빠른 shortcut 대 느린 안전 경로
- 정보: 먼저 보이는 reward 또는 나중에 열리는 return
- 보상: material, heal, positional advantage, skipped encounter

두 길이 같은 점프 수와 같은 적을 거쳐 같은 위치로 즉시 합쳐지면
decorative branching이다. 어느 쪽이 main이고 어느 쪽이 optional인지도
방향, 마찰, 길이, reward clue로 일관되게 알려야 한다.

### 5. Safe zones and recovery create rhythm and trust

Smith의 rhythm group 경계, Khalifa의 Safe Zone, Dead Cells의 dramatic
peak/break, Celeste의 room restart, Shovel Knight의 safe screen entry는
모두 failure와 rest를 map structure의 일부로 취급한다.

Safe zone은 단순히 적이 없는 넓은 바닥이 아니다. 다음 위협을 볼 수 있고,
enemy line of fire나 hazard reach 밖에서 계획할 수 있으며, 방 진입 직후
강제 피해를 받지 않는 자리다. 회복 지점은 방의 climax 뒤에 와야 하고
다음 challenge의 정보를 가리지 않아야 한다.

Celeste 비평이 높은 난이도에도 실패가 불공정하지 않았다고 평가한 이유는
정교한 challenge뿐 아니라 빈번한 checkpoint와 즉시 restart가 학습 loop를
짧게 만들었기 때문이다. 이는 모든 게임이 room restart를 써야 한다는
뜻이 아니라, challenge 크기와 retry 비용을 함께 설계해야 한다는 뜻이다.

### 6. Camera, collectibles, and art are gameplay information

Shovel Knight는 착지점, pit edge, enemy tell이 화면 안에 있어야 하며,
gem으로 main route, optional risk, safe drop, secret clue를 구분한다.
Hollow Knight는 black-tile geometry에 art, audio, background context를
더해 장소를 만들지만, route와 collision의 legibility를 유지한다.

Cardborne에 필요한 것은 먼저 더 화려한 배경이 아니다.

- irreversible jump/drop 전에 landing 또는 안전 신호가 보여야 한다.
- 다음 commitment는 camera 안에 들어와야 한다.
- reward는 optional path의 비용과 방향을 설명해야 한다.
- foreground/background는 collision과 enemy tell을 가리지 않아야 한다.
- UI 가독성 개선은 별도 branch이지만 world-space readability는 map
  authoring의 책임이다.

### 7. Enemies and terrain must be co-authored

Dead Cells는 combat tile length에 따라 enemy quantity를 정하고,
enemy별 공간·platform·조합 제약을 둔다. Shovel Knight는 enemy가 stage
object와 여러 방식으로 상호작용하지 못하면 재설계하거나 옮긴다.
Hollow Knight 비평도 같은 enemy가 좁은 공간, swarm, platform scarcity에
따라 다른 route와 전투 판단을 만든다고 평가한다.

따라서 enemy 수는 pressure의 하한선일 뿐 품질 지표가 아니다. 서로 다른
높이에 enemy가 둘 있다는 것 역시 tactical verticality의 충분조건이 아니다.
두 enemy의 threat lane과 player escape route가 실제로 교차해야 한다.

### 8. Macro shape should tell the stage story

Iron Whale plan은 내려갔다가 바닥 encounter를 치르고, 선체로 상승한 뒤,
추격과 cooldown을 거쳐 boss에 도달한다. Hollow Knight는 Crossroads를
중심에 두고 주변 area가 감싸도록 배치해 location 관계를 기억하게 한다.
Yacht Club은 공중 stage는 쌓고, underground stage는 내려가도록 stage
shape와 theme를 일치시킨다.

세 Cardborne stage도 같은 계단의 색상 변형이어서는 안 된다.

- Ruin Approach: 무너진 외곽을 오르고 우회하는 broken ascent
- Flooded Works: basin으로 내려간 뒤 pump shaft를 되오르는 pressure loop
- Broken Sanctum: gate와 nave를 가로질러 되접히는 interlocked ascent

이 identity는 art 이전에 topology와 height profile에서 보여야 한다.

### 9. Metrics are guardrails, not a verdict

Aramini 등의 jump graph는 물리적으로 가능한 edge와 성공 확률을 추정할 수
있지만 human player 검증을 함께 사용한다. Cardborne의 현 validator도
reachability와 수량적 결함을 막는 데 유용하다. 그러나 현재 metric은
경로가 이해되는지, 높이가 전술을 바꾸는지, 분기가 실제로 다른지 알 수 없다.

자동화가 잘하는 질문과 사람이 답해야 하는 질문을 분리해야 한다.

| 자동화에 적합 | rendered/manual playtest가 필요한 것 |
| --- | --- |
| jump/dash reachability | 다음 landing과 goal이 읽히는가 |
| total vertical range와 ascent/descent | 높이 변화가 실제 결정을 바꾸는가 |
| enemy count와 y-span | enemy 조합이 terrain과 한 질문을 만드는가 |
| graph branch/rejoin 수와 위치 | main/optional route가 직관적으로 구분되는가 |
| empty-room run, recovery anchor 존재 | pace가 지루하거나 과밀하지 않은가 |

## What Highly Regarded Maps Do Especially Well

### Super Mario Bros. World 1-1: anticipates player mistakes

특별한 점은 첫 obstacle이 쉽다는 사실보다 설계자가 초보의 여러 결과를
미리 시뮬레이션했다는 것이다. mushroom을 놓쳐도 pipe가 되돌려 보내는
geometry는 자연스러운 학습, 보상, 실패 완화를 한 번에 해결한다.

Cardborne 적용: Ruin의 첫 elevation lesson은 설명문이 아니라 안전한 ledge,
명확한 enemy lane, 실패해도 회복되는 lower floor로 가르쳐야 한다.

### Specter of Torment: every tile serves a sequence

개별 room의 spacing, gem, enemy, pit이 명확한 intention을 공유하고,
stage 전체에서는 mechanic이 teach → complicate → layer → test → cooldown
arc를 갖는다. 작은 block 하나가 novice route를 유지하면서 expert shortcut을
열기도 한다. 전문 비평도 campaign의 movement와 level design 결합을 주요
장점으로 평가했다.

Cardborne 적용: 동일한 room 수를 유지해도 방 사이 역할과 한 방 안의
상호작용을 재작성하면 밀도와 숙련자 선택을 높일 수 있다.

### Celeste: high challenge, short and legible learning loop

GDC 설명은 300개 이상 방을 area map, 암묵적 teaching, reward, speedrunner
route와 함께 설계한 과정을 다룬다. 비평은 복잡한 action sequence,
빈번한 checkpoint, 즉시 restart 때문에 매우 많은 death가 학습으로
느껴졌다고 평가한다.

Cardborne 적용: Celeste 수준의 정밀 난이도를 복사하지 않는다. 각
challenge phrase의 크기와 retry/recovery 비용을 맞추고, optional expert
line이 baseline route를 흐리지 않게 한다.

### N++: few verbs, many player-authored lines

N++는 run, jump, switch, exit라는 매우 작은 verb set으로 초보와 veteran이
같은 level을 다르게 통과하게 만든다. 비평은 physics, fluidity, level
design, episode pacing을 함께 높게 평가했다.

Cardborne 적용: 새 movement skill을 늘리지 않고도 ledge height, approach
angle, enemy position, optional shortcut으로 여러 line을 만든다.

### Hollow Knight: connections are rewards

초기 시각 자료는 central Crossroads 주위에 area를 감싸고 side room과
shaft를 붙인 과정을 보여준다. 개발자는 procedural prefab 접근을 버리고
world location이 서로 말이 되게 만들었으며, shortcut과 relink 자체를
발견 보상으로 사용했다. 비평도 distinct space, folded shortcut,
enemy-space 조합을 장점으로 평가하면서 초반 map UX의 거친 점은 지적한다.

Cardborne 적용: 거대한 backtracking world를 만들 필요는 없다. optional
branch가 같은 hub로 즉시 되돌아오는 구조를 줄이고, 앞으로 재합류하거나
앞선 공간을 새 관점에서 보게 하는 짧은 loop를 사용한다.

### Dead Cells and Spelunky: controlled generation starts from authored purpose

Dead Cells는 완전 절차 생성의 혼란을 피하려 fixed world frame,
purpose-specific room, biome graph, enemy placement constraint를 먼저
정한다. Spelunky도 room template로 exit까지 safe path를 먼저 보장한다.

Cardborne 적용: 현재 fixed curated plan을 유지한다. 방 목적과 stage
identity가 검증되기 전에 dormant random planner를 다시 켜지 않는다.

## Common Rules Across Cases

| 공통 규칙 | 반복해서 확인된 근거 |
| --- | --- |
| 1. Movement envelope를 먼저 고정한다. | Smith, N++, Shovel Knight, Aramini |
| 2. 방마다 한 문장으로 설명 가능한 intention이 있어야 한다. | Smith rhythm group, Dead Cells, Shovel Knight |
| 3. 새 요소는 안전하게 소개하고 변형·결합한 뒤 시험한다. | Mario, Shovel Knight, Khalifa patterns |
| 4. peak 뒤에는 safe zone, reward, 전망 또는 쉬운 mastery beat가 필요하다. | Smith, Khalifa, Dead Cells, Celeste |
| 5. main route와 optional route는 방향·마찰·위험·보상 언어가 달라야 한다. | Smith, Khalifa, Shovel Knight, Hollow Knight |
| 6. 높은 길과 낮은 길은 다른 행동 또는 risk/reward를 요구해야 한다. | Sonic 분석, N++, Shovel Knight shortcuts |
| 7. enemy, hazard, reward, terrain은 같은 room intention을 지원해야 한다. | Shovel Knight, Dead Cells, Hollow Knight |
| 8. 다음 commitment와 critical information은 행동 전에 보여야 한다. | Shovel Knight, Mario, guidance pattern |
| 9. stage shape는 장소와 mechanic arc를 표현해야 한다. | Iron Whale, Hollow Knight, Dead Cells biomes |
| 10. 자동 metric은 결함을 막지만 continuous playtest를 대체하지 않는다. | Aramini, Nintendo iteration, Yacht Club passes |

## Cardborne Current-State Findings

### What is already sound

- `MovementMetrics.gd`를 기준으로 jump/dash reachability를 검증한다.
- 29개 authored room과 typed socket/anchor contract가 있다.
- 세 normal stage는 deterministic curated topology를 사용한다.
- required room에는 fall recovery anchor가 있고 stage load는 fail closed다.
- enemy archetype은 geometry contract와 pressure role을 갖는다.
- PRD는 20–60초 room과 8초 이상 decision vacuum 방지를 명시한다.

이 기반은 버릴 대상이 아니다. geometry와 sequence를 다시 저작할 수 있는
좋은 안전망이다.

### What the current validator proves

2026-07-15에 다음 명령을 다시 실행했다.

`.\tools\godot.ps1 --path . --headless --script res://tools/validate_stage_composition.gd`

| Stage | Required rooms | Enemies | Vertical range | Ascent | Descent | Elevation changes | Multi-elevation combat rooms | Empty run |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Ruin Approach | 8 | 8 | 720 px | 720 px | 0 px | 9 | 2 | 2 |
| Flooded Works | 7 | 10 | 760 px | 800 px | 40 px | 9 | 3 | 1 |
| Broken Sanctum | 9 | 12 | 740 px | 980 px | 240 px | 11 | 4 | 2 |

세 stage는 `STAGE_COMPOSITION_VALIDATION_OK`를 받았다. 이는 이전
[plan validity audit](./plan_validity_audit_2026-07-15.md)의 낮은 range와
enemy count 문제가 수치상 개선됐음을 뜻한다.

### What the current validator does not prove

`StageCompositionMetrics.gd`는 64 px 이상 support-top 변화, 96 px 이상
enemy y-span, 총 range, enemy count를 센다. 다음은 측정하지 않는다.

- ascent와 descent가 의미 있는 waveform을 만드는지
- 분기가 몇 방 동안 지속되고 어디서 재합류하는지
- 위/아래 경로가 다른 verb, risk, reward를 갖는지
- 높이 차이가 enemy response와 escape route를 바꾸는지
- safe entry에서 다음 commitment가 보이는지
- reward가 optional route를 설명하는지
- stage마다 geometry vocabulary와 silhouette가 다른지
- 정지 캡처가 아닌 연속 플레이에서 route가 이해되는지

특히 Ruin은 ascent 720 px, descent 0 px인 단조 상승인데도 range 기준을
정확히 통과한다. “한 viewport만큼 높다”와 “수직적인 경험이다”가
동일한 조건이 아니라는 직접적인 반례다.

### Topology diagnosis

`CuratedStagePlanBuilder.gd`의 current graph는 다음과 같다.

| Stage | Critical topology | Optional topology | 진단 |
| --- | --- | --- | --- |
| Ruin | 8-room linear chain | `lr_lower_upper_choice`에서 1방으로 나갔다 같은 hub로 귀환 | 분기 하나가 중앙에 집중되고 forward rejoin이 없다. |
| Flooded | 7-room linear chain | `fw_lower_upper_choice`에서 1방으로 나갔다 같은 hub로 귀환 | spatial identity는 가장 낫지만 선택 구조는 Ruin과 같다. |
| Sanctum | 9-room linear chain | 두 optional room이 모두 `bs_twin_reliquary_choice`에서 갈라져 같은 hub로 귀환 | 선택 수는 둘이지만 한 지점에 몰려 stage 전체 탐색성은 낮다. |

따라서 현재 stage는 “linear route + 중앙 side room” 구조다. 이 구조 자체가
나쁜 것은 아니지만, 수직 경로 선택과 재합류를 보여주려는 목표에는
부족하다.

### Per-stage diagnosis

#### Ruin Approach

- 강점: baseline lesson에 적합한 단순함, 8 enemies, 두 combat room의
  elevation span, 명확한 ascent theme 후보.
- 결함: 완전 단조 상승, choice room의 두 line이 읽히지 않음, 넓은 평지와
  빈 상부 공간, charger와 shooter가 지형을 두고 선택을 강제하지 않음.
- 필요한 변화: broken ascent 안에 controlled descent와 forward rejoin을
  넣고, upper exposed/fast line과 lower sheltered/slower line을 실제
  risk/reward로 구분한다.

#### Flooded Works

- 강점: 가장 큰 enemy vertical span, rope shaft와 basin이라는 좋은
  spatial vocabulary, empty run이 짧음.
- 결함: 총 descent가 40 px에 불과해 flooded basin의 내려감/탈출 서사가
  약함, choice room이 긴 수평 ledge로 보임, poison timing과 combat의
  결합이 stage-wide arc로 이어지지 않음.
- 필요한 변화: entry에서 basin으로 내려간 뒤 shaft로 회복 상승하는
  명확한 waveform, dry upper timing line과 lower hazard-management line,
  leaper/shooter/charger의 서로 다른 높이 압력을 만든다.

#### Broken Sanctum

- 강점: 가장 많은 변화와 전투 방, gate-switch·crossfire·recovery room
  이름에 맞는 역할 후보, 충분한 ascent/descent.
- 결함: 두 optional branch가 한 hub에 집중, 화면상 얇은 bar와 큰 void로
  route legibility가 떨어짐, gate loop가 기억 가능한 spatial loop로
  보이지 않음.
- 필요한 변화: 두 optional branch를 서로 다른 stage 구간에 분산하고,
  gate를 연 뒤 이전 공간을 다른 높이로 빠르게 가로지르는 shortcut,
  cover band가 있는 multi-height crossfire를 만든다.

## Findings

1. 현재 맵은 “수직 범위 부족” 단계는 벗어났지만 “수직적 의사결정 부족”
   단계에 있다.
2. 더 많은 발판, 더 높은 range, 더 많은 enemy만 추가하면 현재 metric은
   좋아져도 핵심 결함은 남는다.
3. 가장 먼저 바꿀 것은 room count가 아니라 macro height profile,
   branch distribution, room intention이다.
4. stage별 한 가지 signature spatial verb를 정하고 teach/transform/test
   sequence로 반복해야 한다.
5. combat verticality는 enemy y-span 대신 threat lane, safe zone,
   escape/re-engage route로 검토해야 한다.
6. optional route는 같은 hub 왕복보다 짧은 loop 또는 forward rejoin이
   더 적합하다.
7. automated validation은 directionality와 graph 구조를 더 측정해야 하지만,
   camera legibility와 선택의 의미는 rendered continuous playtest로
   판정해야 한다.
8. UI overhaul은 별도 작업으로 유지하되, landing, hazard, reward,
   foreground collision의 world-space clarity는 map 작업에서 해결해야 한다.

## Recommendations

1. future authoring의 canonical rule로
   [2D Platformer Map Design Guideline](../design/2D_PLATFORMER_MAP_DESIGN_GUIDELINE.md)을
   사용한다.
2. 현재 세 stage는
   [Fixed Stage Map Enhancement ExecPlan](../../.agent/execplans/2026-07-15-fixed-stage-map-enhancement.md)
   순서대로 metric 보강 → macro blockout → stage별 room pass → continuous
   traversal QA를 진행한다.
3. `StageCompositionMetrics.gd`에 direction reversal, branch distribution,
   divergence/rejoin을 추가하되 이 점수를 단일 quality score로 합치지 않는다.
4. 29개 room을 수정하기 전에 stage별 한 장짜리 macro route/height sketch와
   room intention table을 승인한다.
5. 각 combat room은 “enemy A가 terrain B 때문에 response C를 요구한다”는
   문장을 통과해야 한다. 이 문장이 없으면 enemy를 늘리지 않는다.
6. fixed curated stage가 이 기준을 통과하기 전에는 random planner를
   production으로 되돌리지 않는다.

## Limitations

- 외부 게임 전체를 직접 계측한 comparative dataset은 아니다. 공개된
  developer evidence와 대표 이미지, 비평을 질적으로 교차 분석했다.
- Celeste와 N++ GDC 공개 페이지는 session overview가 중심이라, 세부
  설계 원리는 다른 1차 자료와 현재 프로젝트에 직접 적용 가능한 범위로
  제한했다.
- Cardborne fixed-stage 이미지는 특정 지점에 teleport한 정지 캡처다.
  camera transition, 실제 이동 line, combat rhythm은 구현 단계에서
  continuous play recording으로 다시 확인해야 한다.
- 현재 Web export template 부재 때문에 served-browser production QA는
  기존 gameplay validity plan의 blocker를 공유한다. headless와 desktop
  capture만으로 Web 체감을 완전히 증명할 수 없다.
- map art와 UI visual overhaul이 완료되지 않았으므로 perceptual diagnosis
  중 일부는 placeholder presentation의 영향을 받는다. 그럼에도 collision,
  route silhouette, empty space, branch topology 문제는 art와 독립적으로
  확인된다.
