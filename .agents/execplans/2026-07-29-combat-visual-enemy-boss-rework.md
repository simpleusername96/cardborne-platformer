---
type: plan
status: active
owner: BK
created: 2026-07-29
last_reviewed: 2026-07-29
scope: Replace Cardborne's player, enemy, pickup, projectile, upgrade-choice, collective-enemy, and boss presentation/behavior with a simple scalable component system while preserving the stabilized five-stage run
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ./2026-07-29-horde-foundation-recovery-and-acceptance.md
  - ./2026-07-27-pixel-art-visual-recovery.md
  - ../visual-system-design-selection-plan.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../docs/design/component-concepts/README.md
  - ../../docs/product/combat-growth-improvement-direction.md
  - ../../docs/research/hidden-techniques-collective-enemies-mastery-unlocks.md
---

# 전투 비주얼·적 전략·보스 전면 재구성 실행 계획

현재 버전의 기체, 적, 아이템, 탄환을 기존 픽셀 자산의 부분 수정으로
수습하지 않는다. Sunken Ceramic Fresco의 평면 색상과 역할별 색·형태
구분은 유지하되, 픽셀 격자와 방향별 래스터 프레임 제약을 폐기하고 같은
런타임 component 정의에서 component sheet와 실제 게임을 함께 만드는
확장 가능한 vector/parametric 체계로 교체한다.

동시에 업그레이드 선택 UI의 정보 구조와 overflow를 고치고, 아이템 접촉
판정을 기체의 이동 궤적까지 포함하도록 바꾸며, 기존 적 전략 문서의
collective tactic을 현재 4방향 대규모 horde 위에 단계적으로 올린다. 보스는
공통 탄막 primitive의 순서만 바꾸는 구조에서 벗어나 각 stage가 하나의
고유한 arena rule과 objective를 시험하도록 재구성한다.

## Purpose

- **목표:** 첫 조작 10초 안에 기체의 전후·조준·엔진·dash를 오인하지 않고,
  최대 horde에서도 적의 역할과 우선 표적을 읽을 수 있으며, 모든 upgrade
  card와 boss rule을 한국어·영어에서 한 번에 이해할 수 있는 전투를 만든다.
- **첫 사용자 확인 artifact:** 런타임 component 정의로 생성한 7개
  component sheet와 1개 최대 압력 합성 sheet다. 선택지를 다시 탐색하지
  않고 이 문서에 고정된 단일 방향을 시각적으로 검증한다.
- **첫 플레이 가능한 slice:** Stage 1에서 새 기체·engine·dash·pickup·projectile,
  수정된 upgrade modal, `Spearhead`와 `Swarm Screen`, 새 Foundry Colossus
  exam을 함께 플레이한다.
- **완료 상태:** 다섯 stage의 모든 전투 component, collective tactic과 boss
  exam이 같은 시각·행동 문법을 사용하고, 960×540부터 1920×1080까지
  한국어·영어 UI, native/Web build, 276-enemy peak, 320-actor capacity와
  lifecycle gate가 모두 통과한다.

## Why / Context

사용자 feedback은 서로 독립된 미세 결함이 아니라 세 가지 공통 원인을
가리킨다.

1. **presentation state가 gameplay state의 원인을 잃는다.**
   하나의 `player_invulnerable` timer가 dash, 피격, 입장 보호, 이동 보호를
   모두 대표하고 renderer는 원인을 알 수 없어 언제나 coral ring을 그린다.
2. **현재 pixel atlas가 continuous motion과 고밀도 역할 판독에 맞지 않는다.**
   hull은 16방향, engine module은 4방향 frame이라 서로 다른 각도로 꺾이며,
   적과 item은 작은 내부 장식이 늘어나는 대신 silhouette 차이가 줄어든다.
3. **현재 encounter와 boss는 수치·순서 중심이다.**
   대규모 horde는 구현됐지만 squad가 공동 목표를 수행하지 않고, 다섯
   boss는 공통 attack primitive의 순서와 속성만 달라 높은 damage build가
   고유 rule을 보기 전에 phase를 건너뛸 수 있다.

이 계획은 위 세 원인을 각각 typed presentation, component visual grammar,
collective tactic/boss exam state로 해결한다. 적 수, 속도, 현재 visual
footprint, manual aim, held primary fire, dash, passive seeker, EMP, pickup,
card build와 다섯 stage run은 보존한다.

## Pre-plan Evidence Already Verified

| 근거 | 확인된 현재 상태 | 계획에 반영한 결정 |
| --- | --- | --- |
| `scripts/presentation/vehicle_combat_renderer.gd` | hull·flame은 16방향 frame, engine module은 4방향 frame을 같은 중심에 별도로 그린다. | engine mount와 flame을 hull의 하나의 continuous local transform 아래에 둔다. |
| `scripts/vehicle/vehicle_run.gd`와 renderer | dash는 `DASH_DURATION + 0.08` 동안 invulnerable이며 renderer는 원인과 무관하게 모든 invulnerability에 coral ring을 그린다. 기존 afterimage도 이미 별도로 생성된다. | protection source를 분리하고 dash에는 afterimage와 engine flare만 쓴다. |
| 2026-07-29 960×540 native capture `06-level-up-choice.png` | modal의 상단 제목이 viewport 위로 잘린다. card는 `clip_contents = true`이며 선택 시 제목과 설명을 상단 detail에 다시 복제한다. | modal 전체와 모든 child rect/glyph를 검증하고 중복 detail을 제거한다. |
| upgrade source와 validator | 41개 card, 83개 level-state를 검사하지만 현재 geometry contract는 실제 capture의 modal clipping을 잡지 못한다. modifier는 card당 최대 2개이고 behavior-only card는 generic level만 크게 표시한다. | 83개 state별 짧은 summary와 최대 2개 effect row를 고정하고 screenshot oracle을 추가한다. |
| `scripts/vehicle/vehicle_run.gd` | pickup은 현재 위치의 중심 간 거리 `<= 60`만 확인한다. player collision radius는 24, pickup plinth radius는 42다. | player의 이전→현재 위치에 대한 swept circle contact `<= 24 + 42`를 사용한다. |
| `scripts/bosses/vehicle_boss_patterns.gd` | 다섯 boss가 `lanes`, `charge`, `fan`, `area`, `beam`, `cross`, `summon`을 다른 순서로 반복한다. | attack primitive와 boss 고유 exam rule을 별도 owner로 분리한다. |
| `scripts/bosses/vehicle_boss_runtime.gd` | health ratio 0.65/0.30으로 phase를 직접 계산해 큰 damage가 phase를 건너뛸 수 있다. | 순차 phase floor와 objective-complete gate를 둔다. |
| `scripts/enemies/vehicle_stage_difficulty.gd` | boss base health는 1250–1650이고 고유 objective 없이 대부분 직접 damage를 받는다. | HP 일괄 증가는 금지하고 mechanic cycle, vulnerability window와 reference clear-time으로 조정한다. |
| `scripts/vehicle/stages/vehicle_combat_stages.gd` | 4 pack × 3 squad의 multi-sector surge는 역할 순서를 분배하지만 tactic identity나 Gather/Lock/Execute/Break 상태가 없다. | 4방향 arrival은 유지하고 가시 영역에 들어온 일부 squad에 tactic recipe를 부여한다. |
| `docs/product/combat-growth-improvement-direction.md` | `Gather → Compress → Trigger → Delete → Harvest → Evolve → Boss Test` loop와 여섯 formation, boss별 arena idea를 제안한다. | 현재 horde와 충돌하는 “2–3 front 축소”는 버리고 loop와 semantic formation/boss idea를 채택한다. |
| `docs/research/hidden-techniques-collective-enemies-mastery-unlocks.md` | coordinator-owned `Gather → Lock → Execute → Break`, Spearhead·Repair Network, offscreen 제한과 global permission을 제안한다. | collective runtime과 global commit budget의 직접 근거로 사용한다. 숨은 입력·meta unlock은 제외한다. |
| `.agents/execplans/2026-07-29-horde-foundation-recovery-and-acceptance.md` | 276 peak/320 capacity와 4방향 pressure는 고정됐고 Phase 5 timing/soak gate는 아직 열려 있다. | component runtime과 collective rollout은 그 plan 완료 뒤에 merge한다. sheet, upgrade UI, pickup contact는 먼저 진행할 수 있다. |
| 2026-07-29 native/Web baseline | Web export, 1280×720 built page, canvas, 모든 request와 console은 정상이다. 기존 upgrade, localization, rewards, renderer, boss, run validator도 통과한다. | 현재 build가 깨진 것이 아니라 현재 검증이 사용자 경험 결함을 충분히 표현하지 못한다고 본다. |
| 2026-07-29 peak/boss/item capture | 최대 horde에서 적 silhouette가 magenta/coral 덩어리로 합쳐지고, repair/recall item이 비슷한 medallion이며, boss가 큰 donut/blob처럼 보인다. | 작은 장식보다 외곽 silhouette·negative space·우선 표적 cue를 먼저 설계한다. |
| `docs/design/component-concepts/README.md` | player, 12 mobile roles, structures/objectives, rewards/projectiles, five bosses와 upgrade glyph를 다룬 여섯 장의 생성형 시안이 있다. | 구현 전 형태 검토 input으로 사용한다. 이 draft는 runtime descriptor에서 생성한 deterministic approval sheet를 대신하지 않는다. |

로컬 capture와 Web smoke는 분석 근거이며 `build/` 아래 ignored evidence다. 구현
phase의 authoritative evidence는 각 phase가 새로 생성한다.

## Input Classification

### 사실

- Godot 4.7, GDScript, Compatibility renderer와 현재 dependency set을 사용한다.
- 현재 active product는 연결된 다섯 stage vehicle run이다.
- Korean이 기본이고 Korean/English가 모든 user-facing surface에서 완전해야 한다.
- 현재 horde 계약은 Hard peak 276, hostile capacity 320, 네 quadrant arrival,
  현재 player speed·visual scale·collision truth를 보존한다.
- 현재 renderer는 retained `MultiMesh`/`ArrayMesh` 구조와 50 이하 combat batch
  gate를 가진다.

### 사용자 제약

- 역할별 색과 모양을 다르게 하는 현재 기조는 유지한다.
- pixel 관련 제약은 이번 player/enemy/item/projectile 재설계에서 적용하지 않는다.
- dash의 붉은 원은 제거하고 잔상 계열 feedback을 우선한다.
- upgrade overlap, text clarity, vertical overflow를 함께 해결한다.
- boss는 더 강하고 덜 단조로워야 하며 별도 아이디어를 가진다.
- 기존 enemy strategy 문서를 분석해 단계적으로 적용한다.
- item은 기체에 닿거나 dash로 통과해도 획득한다.

### 이번 계획의 해석

- “완전히 다르게”는 기존 pixel frame의 polish가 아니라 source/runtime visual
  representation의 교체를 뜻한다.
- “component별 sheet”는 임의 concept art 모음이 아니라 실제 runtime과 같은
  descriptor로 생성되는 역할·상태별 비교표를 뜻한다.
- full map과 모든 UI chrome 재설계는 이번 시작 범위가 아니다. actor,
  projectile, reward와 upgrade modal을 먼저 고친 뒤 map은 별도 사용자
  평가에서 연다.

## Scope

### 포함

- player hull, independent aim mount, engine mount/flame, module 표시
- dash, hit, barrier, temporary protection feedback
- mobile enemy, stationary enemy, boss, boss objective component
- player/hostile projectile, damaging core, direction tail, telegraph
- field pickup, experience, crate와 pickup contact
- upgrade offer snapshot, card component, modal, Korean/English copy
- authored packet의 tactic tag, collective tactic definition/runtime/telemetry
- 다섯 boss의 objective, phase gate, finite adds, guide text, practice fixture
- component sheet 생성·보존, design/product spec 갱신
- focused validator, native capture, Web production smoke, pressure regression

### 제외

- full map, terrain tile, water, blocker와 전체 menu/HUD chrome의 재설계
- manual aim, held primary fire, dash input, passive seeker, EMP 삭제·교체
- enemy count, movement speed, camera zoom, current collision radius의 하향 조정
- 새로운 engine, production dependency, third-party vector library
- 숨은 dash input, mastery unlock, meta progression과 save schema 변경
- 새 stage, 새 field, 새 card 수, 새 enemy archetype의 무제한 추가
- audio 전면 재제작

## Assumptions

- 현재 horde recovery plan의 276/320, cadence, overlay budget, performance
  scenario가 이 계획보다 선행 authority다.
- Phase 1 component sheet와 Phase 2 upgrade/pickup work는 horde plan과 파일
  owner가 겹치지 않는 한 먼저 merge할 수 있다.
- `vehicle_combat_renderer.gd`, pressure fixture 또는 enemy hot path를 건드리는
  Phase 3 이후 work는 horde recovery plan의 Phase 5/6가 완료되고 clean
  baseline commit이 기록된 뒤 시작한다.
- current visual radius는 player 50, ordinary actor의 기존 profile 값, pickup
  plinth 42, boss 146을 유지한다. shape는 바뀌어도 gameplay collision은
  presentation과 계속 분리한다.
- 모든 boss objective는 기본 primary, dash와 EMP만으로 해결 가능해야 한다.
  특정 card는 해결을 빠르게 할 수 있지만 필수 열쇠가 될 수 없다.

## Locked Decisions

| 항목 | 최종 결정 | 이유 |
| --- | --- | --- |
| 시각 방향 | **Sunken Ceramic Components**: flat-color vector/parametric silhouette, 넓은 ceramic mass, 한두 개의 accent와 명확한 negative space를 사용한다. | 현재 theme는 보존하면서 pixel 격자와 micro-detail 문제를 제거한다. |
| Pixel 규칙 | migrated combat component에는 whole-cell, nearest-neighbor, fixed logical grid, 방향별 raster frame, dithering 금지 같은 pixel 규칙을 적용하지 않는다. antialiasing을 허용한다. | 최신 사용자 지시와 continuous motion 요구 |
| 색상 | cobalt environment, ivory neutral/UI, ceramic green structure, mustard player/reward, coral hostile danger, magenta boss/command, mint support/recovery 체계를 유지한다. | 기존 first-read 의미를 보존한다. |
| 역할 구분 | 모든 role은 color 외에 silhouette 또는 negative-space cue를 하나 이상 갖는다. color만 바꾼 복제는 금지한다. | color vision과 horde 중첩에서 판독성을 유지한다. |
| 복잡도 | ordinary component는 큰 filled mass 최대 3개와 accent 최대 2개, boss는 고유 module 최대 5개다. 미세 장식과 nested outline을 쓰지 않는다. | 실제 gameplay scale에서 보이는 정보만 남긴다. |
| Runtime | Godot `ArrayMesh` + retained `MultiMesh`를 사용하고 mesh/descriptor를 cache한다. SVG/PNG texture를 actor마다 instance하지 않는다. | 확장성과 기존 performance architecture를 함께 보존한다. |
| Sheet truth | component sheet는 실제 runtime descriptor와 palette를 불러 생성한다. sheet-only 그림과 runtime art를 따로 소유하지 않는다. | 승인 artifact와 게임의 drift를 막는다. |
| Engine | engine mount 위치와 각도는 hull continuous transform의 child다. thrust는 flame 길이·alpha만 바꾸며 anchor와 angle을 바꾸지 않는다. | 이동 중 engine이 꺾이는 원인을 제거한다. |
| Aim | primary barrel은 현재처럼 hull과 독립된 manual aim transform을 유지한다. engine과 aim transform을 묶지 않는다. | control contract 보존 |
| Dash | 0.20초 동안 최대 5개의 hull afterimage와 rear engine flare를 사용한다. coral radial ring과 원형 dash burst는 제거한다. | 방향과 속도를 직접 보여 준다. |
| Reduced motion | 여러 afterimage 대신 0.12초 이하의 단일 elongated silhouette와 engine flash를 사용한다. | 상태는 보존하고 반복 motion을 줄인다. |
| Protection cue | dash, hit, arrival, transit, barrier를 source별 window로 분리한다. hit는 coral hull flash, arrival/transit는 mint corner brackets, barrier만 mint ring을 쓴다. | 하나의 timer를 여러 의미로 오인하는 문제를 없앤다. |
| Upgrade layout | scroll, glyph clipping, body font 14 미만 자동 축소 없이 960×540에 맞춘다. card당 title 2줄, summary 3줄, effect row 최대 2개를 보장한다. | 읽지 못하는 내용을 숨기는 방식은 해결이 아니다. |
| Upgrade copy | 41개 card의 83개 next-level state가 각각 짧은 Korean/English summary key를 가진다. modifier는 최대 2개 exact before→after row로 표시하고 behavior-only card의 generic “Level 1” impact는 제거한다. | card마다 정보 구조가 달라지는 문제를 없앤다. |
| Pickup | non-blocking swept overlap을 사용한다. contact threshold는 player radius 24 + pickup body radius 42 = 66이고 segment tangent를 포함한다. | 보이는 plinth와 접촉하면 획득하고 dash tunneling을 막는다. |
| Horde macro | 네 quadrant의 multi-sector arrival, authored count, quota와 active cap을 유지한다. | 최신 product/performance contract |
| Tactic micro | 한 번에 전역 `Lock`/`Execute` tactic은 1개만 허용한다. 추가 tactic 1개는 `Gather`까지만 가능하고 offscreen에서는 `Lock`으로 진행하지 않는다. | 고밀도에서도 하나의 읽을 수 있는 공동 위협만 만든다. |
| Boss strength | HP만 일괄 증가하지 않는다. 65%와 30%에 순차 phase floor를 두고 각 고유 objective를 한 번 해결해야 다음 health band가 열린다. | burst skip을 막되 무의미한 체력 sponge를 피한다. |
| Boss adds | boss가 만든 add는 finite하며 동시에 최대 12기, 전체 320 capacity 안에 포함한다. objective cue와 기본 attack cue는 overlay budget에서 never-hidden이다. | 공정성과 performance 보존 |
| Boss difficulty | 난이도는 objective rule을 숨기거나 바꾸지 않고 read time, composition과 recovery window만 bounded하게 조정한다. | 학습 가능한 rule 유지 |
| Approval gate | 7개 component sheet와 최대 압력 sheet를 이 문서의 단일 방향으로 한 번 생성한 뒤 BK가 runtime publication을 승인한다. 선택지 재탐색은 하지 않는다. | 구현 전에 실제 scale의 시각 품질을 확인하되 계획을 다시 research로 돌리지 않는다. |

## Rejected Alternatives

| 대안 | 기각 이유 |
| --- | --- |
| 현재 pixel atlas의 engine frame과 적 sprite만 다시 그린다. | hull 16방향/module 4방향, micro-detail과 runtime/sheet 이원화를 그대로 남긴다. |
| 모든 map, terrain, HUD, menu도 동시에 전면 교체한다. | immediate combat feedback의 책임과 검증 범위를 흐리고 현재 horde recovery와 충돌한다. |
| runtime actor마다 SVG texture를 import한다. | high-count retained batching을 깨고 raster/import scale truth를 다시 만든다. |
| dash ring의 색만 cyan으로 바꾼다. | 원형 cue가 이동 방향을 설명하지 못하며 invulnerability 원인 혼합을 남긴다. |
| upgrade card 안에 `ScrollContainer`를 넣는다. | 선택 순간 모든 효과를 비교해야 하는 surface에서 정보를 숨긴다. |
| 작은 font로 자동 축소한다. | 영어·한국어와 저해상도에서 가독성을 희생한다. |
| pickup을 별도 `Area2D` node로 모두 만든다. | 현재 data-oriented run과 retained presentation에 병렬 truth를 추가한다. swept geometry helper면 충분하다. |
| 적을 2–3 front로 줄여 formation을 읽게 한다. | 현재 승인된 4방향 horde와 authored density를 되돌린다. |
| boss health를 2배로 늘린다. | 단조로운 pattern을 더 오래 반복할 뿐이며 high-output phase skip의 근본 원인을 해결하지 못한다. |
| 모든 boss에 같은 pylon objective를 붙인다. | 현재 공통 primitive 순서 변경과 같은 단조로움을 objective 층으로 옮길 뿐이다. |
| collective tactic을 enemy마다 직접 판단한다. | N개 actor가 squad와 world를 반복 scan해 현재 performance work를 되돌린다. |

## Proposed Design

### 1. Sunken Ceramic Component Grammar

모든 combat component는 다음 네 layer 중 필요한 것만 가진다.

1. **Body:** 역할을 결정하는 가장 큰 silhouette다.
2. **Facing cut:** 전후·발사 방향을 나타내는 홈, notch 또는 열린 negative space다.
3. **Function module:** shield, support, artillery, boss objective처럼 실제 행동을
   뜻하는 한두 개의 component다.
4. **Transient state:** startup, active, damaged, selected, vulnerable처럼 시간에
   따라 나타났다 사라지는 얇은 accent다.

ordinary actor의 작은 내부 pixel 무늬, 의미 없는 rivet, 여러 겹 테두리는
제거한다. 공격 범위, collision, aim, timer 같은 live truth는 기존처럼 code와
telegraph가 그리며 component art에 굽지 않는다.

형태 문법은 다음처럼 고정한다.

| 역할 | 주 silhouette | 기능 cue |
| --- | --- | --- |
| player | 전방이 열린 mustard wedge + 넓은 rear shoulder | 독립 barrel, rear engine socket |
| swarm | 작은 teardrop/chevron | 넓은 빈 중심 없이 군집으로 읽힘 |
| melee pursuer | 전방 notch가 깊은 spear | 한 개의 강한 forward point |
| ranged | 옆으로 넓은 bracket | 중앙 muzzle gap |
| controller | 분리된 twin prong | magenta command crown |
| shield | 앞이 평평한 slab | mint/green forward plate |
| artillery | 뒤가 무겁고 앞이 좁은 long body | 긴 aim rail |
| rammer | 굵은 arrowhead | charge 중 전방 coral edge |
| support | 열린 ring이 아닌 crescent cradle | mint link arms |
| stationary threat | 바닥에 잠긴 square/hex base | 회전하는 공격 module만 분리 |
| boss | stage마다 다른 outer silhouette | 파괴·활성 가능한 module이 외곽에서 바로 보임 |
| repair pickup | mint cross-shaped ceramic shard | 중앙 plus cut |
| recall pickup | cobalt/mint inward chevrons | 안쪽으로 모이는 세 방향 |
| projectile | damage core는 작고 단단한 shape | 방향 tail은 길지만 non-damaging |

### 2. Component Sheet Contract

다음 7개 sheet와 1개 합성 sheet를 `1920×1080` PNG로 생성한다.

| 파일 | 내용 | 필수 상태 |
| --- | --- | --- |
| `01-player-components.png` | hull, primary mount, 0–3 engine module, passive/active modules | idle, thrust, dash, hit, barrier, reduced motion |
| `02-mobile-enemy-roles.png` | 모든 mobile role | neutral, startup, active, priority, damaged |
| `03-structures-objectives.png` | turret, mine, interceptor, beam sentinel, generator, boss objective | idle, startup, active, broken |
| `04-boss-components.png` | 다섯 boss silhouette와 module | phase 1–3, objective locked/open, vulnerable |
| `05-rewards-pickups.png` | XP 3종, repair, recall, crate | idle, attract/contact, collected/open |
| `06-projectiles-telegraphs.png` | player/hostile projectile와 affinity | core, tail, startup, committed, impact |
| `07-upgrade-glyphs.png` | primary, element, passive, mobility, defense, utility family glyph | default, focus, selected, unavailable |
| `08-pressure-accessibility.png` | Stage 1/3/5 pressure composite | color, grayscale, reduced motion, collision-overlay debug |

각 sheet는 다음을 동시에 보여 준다.

- normalized component view와 실제 gameplay scale 1× view
- 색상 view와 grayscale view
- facing과 anchor crosshair
- production에는 보이지 않는 collision/debug overlay
- role/state label의 Korean/English pair
- sheet generator commit, palette version과 descriptor fingerprint

생성 owner는 `tools/design/capture_vehicle_component_sheets.gd`와
`tools/design/vehicle_component_sheet_capture.tscn`이다. 승인 PNG와
`component-sheet-manifest.json`은 `docs/design/component-sheets/`에 보존하고,
임시 frame과 pressure capture는 `build/validation/vehicle-component-sheets/`
아래에 둔다.

### 3. Player, Engine and Dash

`player_hull_direction`은 continuous angle을 유지한다. player component root의
local transform은 다음 계층을 가진다.

```text
player_root(hull angle)
├─ hull
├─ engine_mount_0..2(rear local offsets)
│  └─ flame(local rear axis; length/alpha only)
├─ passive/defense module
└─ aim_root(independent aim angle)
   └─ primary barrel + muzzle
```

- engine count가 바뀌어도 mount가 hull 뒤에서 좌우로만 배치되고 회전 보간을
  별도로 하지 않는다.
- idle flame은 짧고 opaque, thrust flame은 길고 밝으며 dash flare는 0.20초
  동안 길이가 증가한다.
- dash start의 현재 원형 effect asset과 coral invulnerability ring을 제거한다.
- afterimage는 dash 경로에 최대 5개, 0.04초 간격, 0.18초 lifetime으로 남고
  원본 hull과 같은 angle을 가진다.
- damage hit만 coral hull flash를 사용한다. invulnerability 자체는 danger
  color가 아니다.

`scripts/vehicle/vehicle_player_protection_windows.gd`가 `dash`, `hit`,
`arrival`, `transit`, `capture` source별 remaining time을 소유한다. gameplay
damage gate는 `is_active()`를 사용하고 presentation snapshot은 source별
remaining을 export한다. barrier는 별도 strength/timer owner를 유지한다.

### 4. Upgrade Information and Layout

#### Content model

`VehicleUpgradeDefinition`에 `summary_keys_by_level`을 추가한다. 배열 길이는
`max_level`과 같고 각 key는 “다음 level을 선택하면 실제로 무엇이 달라지는지”
한 문장으로 설명한다.

`VehicleUpgradeOfferPresenter`는 UI에 다음 immutable snapshot만 준다.

```text
id
family_key
title_key
summary_key
current_level / next_level / max_level
effect_rows[0..1] = {label_key, current, next, operation}
behavior_change = new | improve | none
```

- modifier가 있는 card는 실제 before→after row를 최대 2개 표시한다.
- modifier가 없는 behavior card는 generic level 숫자 대신 `새 동작` 또는
  `동작 강화` badge와 level별 summary를 표시한다.
- description과 stat이 같은 내용을 반복하면 summary를 더 짧게 고친다.
- 41개 card, 83개 state의 Korean/English copy를 실제 card width에서 shape한
  뒤 승인한다.

#### Geometry

| viewport | modal 최대 크기 | card | gap | 최소 body font |
| --- | --- | --- | --- | --- |
| 960×540 | 936×516 | 280×286 | 12 | 14 |
| 1280×720 | 1032×620 | 300×330 | 12 | 15 |
| 1920×1080 | 1032×620 | 300×330 | 12 | 15 |

- compact header는 kicker 1줄, title 1줄, instruction 1줄만 사용한다.
- card는 family 1줄, title 최대 2줄, summary 최대 3줄, effect row 최대 2개,
  bottom-anchored level pips로 고정한다.
- 선택 후 상단 detail은 제목·description을 복제하지 않는다. 한 줄의 선택
  상태 또는 prerequisite/element stack 경고만 표시한다.
- `clip_contents`로 정상 내용을 숨기지 않는다. production safety clip은
  허용하되 validator에서는 모든 label glyph bounds가 card에 들어와야 한다.
- keyboard 1–3, focus, selected, disabled, optional decline와 two-step confirm은
  보존한다.

### 5. Pickup Contact

새 `scripts/rewards/vehicle_pickup_contact.gd`는 presentation과 독립된 pure
geometry owner다.

```text
touches_pickup(
  player_from,
  player_to,
  player_radius = 24,
  pickup_center,
  pickup_radius = 42
) = point_segment_distance(pickup_center, player_from, player_to)
    <= player_radius + pickup_radius
```

`_physics_process`는 `_update_player()` 직전 위치를 저장하고 이동 후
`_update_pickups(player_from, player_position)`에 넘긴다. pickup은 player
movement를 막지 않으며 한 tick에 한 번만 collect된다.

필수 case는 정지 overlap, 정확한 tangent, ordinary movement 통과, full dash
통과, threshold 0.1 바깥 miss, 이미 비활성 pickup, repair와 recall 각각이다.

### 6. Collective Enemy Tactics

#### Runtime grammar

모든 tactic은 동일한 phase를 사용한다.

1. **Gather:** 지정 composition이 formation anchor로 모인다.
2. **Lock:** 1.0–1.3초 동안 formation과 공격 축을 명확히 보여 준다.
3. **Execute:** squad가 하나의 공동 행동을 수행한다.
4. **Break:** leader/objective kill, EMP, Breach, cover collision 또는 최소 인원
   미달로 tactic이 무너지고 0.8–1.2초 recovery를 준다.

offscreen squad는 `Gather`까지만 진행하며 player와 900 안, viewport-expanded
engagement rect 안에 들어와야 `Lock` permission을 요청할 수 있다. 전역
coordinator는 `Lock`/`Execute` 1개만 허용하고 ranged/denial commit cap,
pressure budget, active cap과 boss add reserve를 함께 확인한다.

#### Stage rollout

| Stage | Teach | Combine / Power Test | 사용 role | break lesson |
| --- | --- | --- | --- | --- |
| 1 | `Spearhead`: 6기 arrow/lane | `Swarm Screen`: 6 swarm + 2 shooter | scrap, needle, chaser, shooter | lead kill, EMP, cover collision |
| 2 | `Shepherd Pack`: controller가 swarm을 한쪽으로 압축 | `Shielded Column`: 2 shield + 4 pursuit + 2 shooter | controller, shield escort, swarm, shooter | controller/shield 제거, 측면 이동 |
| 3 | `Fuse Pack`: 4 minelet + 3 pursuit + 1 rammer | `Bulwark Fuse`: bulkhead가 fuse lane을 고정 | minelet, rammer, bulkhead, artillery | mine 조기 기폭, ram/cover break |
| 4 | `Repair Network`: 2 tender + escort/guards | `Crossfire Convoy`: 2 ranged anchor + 6 escort | repair tender, generator/beam anchor, bulkhead, chaser | link node 제거, EMP, 시야선 끊기 |
| 5 | 앞선 tactic의 짧은 remix | Crown이 한 번에 하나를 command | 모든 이전 학습 role | 새 규칙 없이 우선순위 종합 |

현재 packet 전체가 formation이 되지 않는다. surge마다 최대 1개 squad만 tactic
tag를 받고 나머지는 현재 horde pressure를 유지한다. `Teach → Combine →
Power Test` beat는 stage definition에 명시하고 random director가 lesson
순서를 바꾸지 못한다.

#### Ownership

- `scripts/enemies/vehicle_collective_tactic_catalog.gd`
  - composition, geometry, timing, break condition, pressure cost의 immutable truth
- `scripts/enemies/vehicle_collective_tactic_runtime.gd`
  - tactic instance, permission, phase, member/anchor와 event 생성
- `scripts/enemies/vehicle_enemy_state.gd`
  - `tactic_id`, `tactic_instance_id`, `tactic_slot`, `tactic_phase` hot fields만 추가
- `scripts/vehicle/stages/vehicle_combat_stages.gd`
  - packet/beat별 tactic tag와 lesson order
- `scripts/encounters/vehicle_encounter_runtime.gd`
  - spawn spec에 tactic identity 전달
- `scripts/vehicle/vehicle_run.gd`
  - movement/damage/query service와 tactic event 적용만 수행; recipe policy를
    흡수하지 않는다.

### 7. Boss Idea Package

모든 boss는 기존 attack primitive를 재사용할 수 있지만, 아래의 고유 exam
rule과 objective state를 반드시 가진다.

#### Stage 1 — Foundry Colossus: Forge Plate

- **실루엣:** 넓은 전방 forge plate 두 개와 작은 중앙 mustard-hot core.
- **Arena rule:** boss charge를 blocker/plate axis로 유도하거나 plate에 직접
  damage를 누적해 한쪽 plate를 파괴한다. EMP와 Breach는 빠른 해법이지
  필수 조건이 아니다.
- **Phase 1:** plate 방향과 charge lane을 가르친다.
- **65% gate:** `Spearhead` 1개를 command한다. lead를 끊거나 plate를
  파괴하면 core가 5.5초 열린다.
- **30% gate:** 남은 plate와 `Swarm Screen`을 겹치되 global tactic은 1개만
  Execute한다. 해결 후 final core가 열린다.
- **시험:** charge 유도, priority target, Stage 1 collective lesson.

#### Stage 2 — Archive Leviathan: Segment Lock

- **실루엣:** 긴 양옆 segment와 비대칭 head notch.
- **Arena rule:** wake가 지나간 방향의 side segment가 lock된다. 반대쪽으로
  이동해 segment를 깨면 그 측면 core가 5.0초 열린다.
- **65% gate:** `Shepherd Pack`이 player를 wake 쪽으로 몰지만 controller를
  끊으면 즉시 formation이 Break한다.
- **30% gate:** 두 side 중 player가 먼저 깨는 쪽이 safe route를 결정한다.
- **시험:** 측면 이동, controller priority, wake 읽기.

#### Stage 3 — Drydock Titan: Relay Polarity

- **실루엣:** 중앙 square mass와 분리된 portable relay 두 개.
- **Arena rule:** relay가 번갈아 `+/-` polarity를 표시한다. 같은 polarity를
  EMP/Arc 또는 direct damage로 overload하면 boss shield가 5.0초 꺼진다.
  polarity는 color와 plus/minus shape를 동시에 사용한다.
- **65% gate:** `Fuse Pack` 하나가 relay 사이 lane을 만든다.
- **30% gate:** 두 relay를 순서대로 overload하되 동시에 active한 collective
  Execute는 하나뿐이다.
- **시험:** 순서 기억, mine 조기 기폭, EMP timing.

#### Stage 4 — Switchyard Behemoth: Route Switch

- **실루엣:** 길고 무거운 body, 분리 가능한 rear armor car, 좌우 switch node.
- **Arena rule:** 좌우 switch 중 하나를 쏘면 다음 charge route가 그 lane으로
  잠긴다. blocker와 충돌시키면 armor car가 분리되고 5.5초 rear core가 열린다.
- **65% gate:** `Repair Network`가 armor car를 복구하려 하므로 link node가
  우선 표적이다.
- **30% gate:** `Crossfire Convoy`와 route switch를 한 번 결합한다.
- **시험:** arena 조작, attack 유도, sustain network 우선순위.

#### Stage 5 — Crown Engine: Lattice Command

- **실루엣:** 중앙 crown core와 분리된 두 outer core, 세 방향 lattice arm.
- **Arena rule:** outer core 하나를 파괴하면 해당 lattice lane이 safe corridor가
  된다. 두 outer core를 모두 처리한 뒤 central core가 열린다.
- **65% gate:** 앞선 stage tactic 중 하나를 명시적으로 이름과 shape cue로
  command한다.
- **30% gate:** 서로 다른 두 tactic을 순차 실행하되 동시 Execute하지 않는다.
- **Final:** 새로운 surprise rule 없이 지금까지 학습한 target priority,
  side choice와 break condition을 종합한다.
- **시험:** 다섯 stage 학습의 최종 조합.

#### Shared Boss Contract

- health phase는 반드시 1 → 2 → 3 순서다. 한 frame의 excess damage는 다음
  phase floor를 넘지 못한다.
- floor 도달 즉시 objective read가 시작되며 무조건 invulnerable timer를
  기다리게 하지 않는다.
- objective를 해결하면 4.5–5.5초 vulnerability window를 연다.
- objective module 하나의 health는 boss max health의 8–10% 범위에서 stage
  fixture로 고정하고, 기본 primary만으로 한 read cycle 안에 파괴 가능해야 한다.
- boss add는 cycle 종료, boss phase 전환 또는 12기 cap 도달 시 더 spawn하지
  않는다. 남은 add는 boss death 때 안전하게 정리한다.
- objective text는 HUD에 1줄, Korean/English 각 52 glyph-equivalent 이내이며
  icon/shape cue와 함께 표시한다.

Reference build는 각 stage에 다음 upgrade를 한 level씩 누적한 deterministic
fixture다.

1. Stage 1: `kinetic_rounds`, `tuned_thrusters`
2. Stage 2: 위 + `rapid_cycle`, `seeker_warhead`
3. Stage 3: 위 + `reinforced_hull`, `emp_focus`
4. Stage 4: 위 + `mass_driver`, `seeker_cycle`
5. Stage 5: 위 + `stabilizer`, `dash_capacitor`

Standard reference clear-time target은 Stage 1–2 `50–80초`, Stage 3–4
`60–95초`, Stage 5 `75–110초`다. Hard는 같은 fixture에서 Standard보다
`10–25%` 길되 `130초`를 넘지 않는다. 모든 run은 각 semantic phase를 한 번
이상 보여야 하고 objective를 정확히 해결한 player에게 즉시 damage window를
준다.

## Architecture and Ownership

`scripts/vehicle/vehicle_run.gd`는 이미 큰 orchestration owner다. 이 계획의
definition, component construction, tactic policy, boss objective policy를 그
파일에 추가하지 않는다.

| 책임 | 현재 owner | 목표 owner | 금지 경계 |
| --- | --- | --- | --- |
| mesh primitive/cache | `vehicle_combat_visual_library.gd`의 일부 | `scripts/presentation/components/vehicle_component_mesh_library.gd` | role 의미, gameplay radius를 소유하지 않음 |
| actor visual descriptor | pixel catalog + visual library + renderer 분산 | `vehicle_actor_visual_catalog.gd` | attack/damage policy를 소유하지 않음 |
| projectile visual descriptor | visual library + renderer 분산 | `vehicle_projectile_visual_catalog.gd` | damage core radius를 변경하지 않음 |
| reward visual descriptor | pixel catalog + run draw | `vehicle_reward_visual_catalog.gd` | collection policy를 소유하지 않음 |
| retained draw/upload | `vehicle_combat_renderer.gd` | 동일 | component shape 정의를 흡수하지 않음 |
| guidebook preview | pixel catalog/fallback 혼합 | 같은 actor/reward/projectile catalog 소비 | 별도 preview art 금지 |
| protection timing | `player_invulnerable` 단일 float | `vehicle_player_protection_windows.gd` | barrier strength와 hit damage를 소유하지 않음 |
| pickup contact | `vehicle_run.gd` point distance | `vehicle_pickup_contact.gd` | item effect를 소유하지 않음 |
| upgrade truth | definition/presenter/UI 혼합 | definition + presenter snapshot | UI가 behavior id를 해석하지 않음 |
| collective recipe | 없음 | `vehicle_collective_tactic_catalog.gd` | actor movement primitive를 복제하지 않음 |
| collective state | squad fields와 run loop 분산 | `vehicle_collective_tactic_runtime.gd` | full enemy array를 member마다 scan하지 않음 |
| boss attack primitive | boss patterns/runtime | 동일 | objective rule을 pattern dictionary에 넣지 않음 |
| boss exam definition/state | pylon special case와 run 분산 | `vehicle_boss_exam_catalog.gd`, `vehicle_boss_exam_runtime.gd` | renderer와 UI copy를 직접 소유하지 않음 |
| component sheet | 없음 | design capture scene/script | runtime과 다른 shape를 만들지 않음 |

`vehicle_combat_visual_library.gd`는 migration 중 compatibility facade로만
남긴다. 모든 caller가 새 catalog로 이동한 final phase에서 중복 mesh/recipe
함수를 제거하고 파일을 삭제하거나 이름에 맞는 primitive-only owner로
축소한다. 두 visual catalog가 같은 role을 동시에 소유한 상태로 완료하지 않는다.

## As-Is / To-Be Delta

| 영역 | As-is | To-be | 관찰 가능한 acceptance |
| --- | --- | --- | --- |
| engine | 16-dir hull + 4-dir centered module frame | continuous hull child mount | 360° rotation capture에서 engine anchor 오차 ≤1 px |
| dash | afterimage + coral invulnerability ring + radial asset | directional afterimage + engine flare | dash frame에 coral/radial ring instance 0 |
| protection | one float, source unknown | source windows | dash/hit/arrival/transit snapshot이 서로 구분됨 |
| actor design | pixel frame와 작은 내부 장식 | cached vector components | grayscale sheet에서 role signature 중복 0 |
| pickup | 비슷한 round medallion | plus vs inward-chevron silhouette | color 제거 후에도 repair/recall shape가 다름 |
| pickup contact | endpoint center distance 60 | swept overlap radius 66 | full dash pass-through가 정확히 1회 collect |
| upgrade modal | 960×540 상단 clipping, duplicate detail | bounded header/card/command layout | 83×2×3 matrix와 capture에서 overflow 0 |
| behavior card | generic level impact | level-specific concise summary | 모든 card가 선택 결과를 한 문장으로 설명 |
| enemy squads | role sequence만 분배 | authored tactic state | Stage별 Teach/Combine/Power Test telemetry 존재 |
| tactic permission | 없음 | 1 global Lock/Execute | 동시에 Execute 2개가 되는 frame 0 |
| boss phase | health ratio 직접 계산 | sequential objective-gated phase | phase skip 0 |
| boss identity | common primitive 순서 차이 | 5 unique arena exams | practice capture만 보고 stage/boss 식별 가능 |
| performance | pixel atlas retained batches | cached component retained batches | combat batch ≤50, draw-call p95 ≤200, horde retention gate 통과 |

## Tasks

- [ ] Phase 1에서 active visual/product authority와 component sheet를 고정한다.
- [ ] Phase 2에서 upgrade clarity와 swept pickup contact를 완료한다.
- [ ] horde recovery completion gate와 clean performance baseline을 확인한다.
- [ ] Phase 3에서 player/dash/projectile/reward를 runtime component로 옮긴다.
- [ ] Phase 4에서 enemy visual과 Stage 1 collective tactic을 연결한다.
- [ ] Phase 5에서 Foundry Colossus semantic exam vertical slice를 승인받는다.
- [ ] Phase 6에서 Stage 2–3 tactic과 boss exam을 확장한다.
- [ ] Phase 7에서 Stage 4–5 synthesis와 Crown final exam을 완료한다.
- [ ] Phase 8에서 obsolete owner를 제거하고 full production gate를 통과한다.

## Milestones

아래 phase가 이 계획의 milestone이자 commit boundary다. 앞 phase의 완료
gate를 통과하기 전에는 뒤 phase의 runtime publication을 merge하지 않는다.

### Phase 1 — Component authority and approval sheets

**목표:** runtime publication 전에 단일 새 시각 방향을 실제 scale로 고정한다.

- [ ] `docs/design/UI_VISUAL_SYSTEM.md`에서 combat component에 대한 pixel
  grid/nearest-neighbor 의무를 폐기하고 Sunken Ceramic Components section을
  추가한다. map/terrain/UI chrome의 현행 계약은 이번 phase에서 유지한다고
  명시한다.
- [ ] `docs/product/vehicle_game_spec.md`의 player/enemy/item/projectile
  presentation을 component catalog와 role silhouette contract로 갱신한다.
- [ ] mesh primitive와 actor/projectile/reward catalog를 runtime과 독립된
  경로에 구현한다. 기존 renderer에는 아직 연결하지 않는다.
- [ ] component sheet capture scene/script, manifest와 deterministic fingerprint를
  구현한다.
- [ ] 7개 component sheet와 pressure/accessibility sheet를 color/grayscale,
  1× scale, collision overlay로 생성한다.
- [ ] `docs/design/component-sheets/`에 승인 대상 PNG, manifest와 짧은 Korean
  reading guide를 저장한다.
- [ ] BK approval gate를 통과한다. 이 gate에서 허용되는 결과는 `승인` 또는
  이 문서의 grammar 안에서 한 번의 bounded shape/spacing correction뿐이다.

**검증**

- 모든 catalog id가 current player module, enemy archetype, boss, pickup,
  projectile affinity와 upgrade family를 빠짐없이 덮는다.
- descriptor fingerprint를 바꾸지 않고 sheet를 두 번 생성하면 동일 hash다.
- grayscale에서 ordinary role signature polygon이 완전히 같은 pair가 없다.
- 1× scale에서 facing cut과 priority cue가 최소 2 px-equivalent 두께를 유지한다.

**완료 gate:** 8개 sheet가 승인되고 active design/product spec이 최신 사용자
결정과 모순되지 않는다.

### Phase 2 — Upgrade clarity and pickup contact

**목표:** combat renderer와 무관한 즉시 불편을 먼저 해결한다.

- [ ] `summary_keys_by_level` schema, catalog validation과 83개 Korean/English
  summary를 추가한다.
- [ ] offer presenter가 exact 0–2 effect row와 behavior change를 export하도록
  수정한다.
- [ ] card와 panel을 고정 geometry/content budget으로 재배치하고 선택 시
  duplicate title/description을 제거한다.
- [ ] upgrade glyph는 Phase 1 catalog를 사용하되 card behavior를 UI가
  해석하지 않게 한다.
- [ ] 기존 83-state matrix에 modal child/glyph bounds, focus/selected/optional
  상태와 screenshot comparison을 추가한다.
- [ ] pure pickup contact helper를 추가하고 player movement segment를 전달한다.
- [ ] endpoint, tangent, dash pass-through, miss와 idempotency test를 추가한다.

**검증**

- `960×540`, `1280×720`, `1920×1080` × `ko/en` × 83 state × 3 slot ×
  unselected/selected에서 overflow, overlap, clipping이 0이다.
- body font는 14 미만이 아니고 scroll 없이 모든 effect가 보인다.
- repair/recall collision case가 각각 통과하고 pickup은 player movement를
  막지 않는다.
- 기존 offer determinism, input guard, two-step confirm와 localization
  validator가 그대로 통과한다.

**완료 gate:** 960×540 Korean/English capture에서 modal 전체와 세 card가
viewport 안에 있으며 dash segment를 가로지른 pickup이 한 번 획득된다.

### Inter-plan Gate — Horde recovery completion

- [ ] `.agents/execplans/2026-07-29-horde-foundation-recovery-and-acceptance.md`
  Phase 5/6와 objective completion criteria가 완료된다.
- [ ] clean commit에서 `production_replay`, `peak_horde`, `capacity_pressure`,
  `boss_pressure` baseline path와 thresholds를 기록한다.
- [ ] 새 visual runtime work가 실패한 renderer channel split이나 enemy count,
  speed, scale 감소를 다시 도입하지 않는지 확인한다.

이 gate 전에는 `vehicle_combat_renderer.gd`, pressure fixture와 enemy hot path를
merge하지 않는다.

### Phase 3 — Player, dash, projectile and reward runtime slice

**목표:** 승인 component를 실제 Stage 1의 가장 자주 보는 feedback에 연결한다.

- [ ] source-specific protection windows를 도입하고 기존 direct float assignment를
  source API로 옮긴다.
- [ ] player hull, engine mount/flame, independent aim mount를 component catalog로
  renderer에 연결한다.
- [ ] dash radial asset/ring publication을 제거하고 normal/reduced-motion
  afterimage를 연결한다.
- [ ] player projectile, hostile affinity projectile, repair, recall, XP, crate를
  새 catalog로 옮긴다.
- [ ] guidebook preview가 같은 descriptor를 사용하게 바꾼다.
- [ ] migrated pixel families를 catalog에서 deprecated로 표시하되 전체 caller
  parity 전에는 source asset을 삭제하지 않는다.

**검증**

- 360° 5° step rotation에서 engine socket의 world position이 expected hull
  transform과 1 px-equivalent 이내다.
- idle→move→dash→hit→arrival→transit→barrier state capture에 cue 혼동이 없다.
- projectile damaging core와 collision radius가 기존 validator truth와 같다.
- combat retained batch ≤50, draw-call p95 ≤200을 유지한다.
- fixed `peak_horde` 3×20초에서 presentation p95가 horde baseline보다
  10% 넘게 악화되거나 frame p95가 5% 넘게 악화되면 이 phase runtime
  publication만 제거하고 catalog/sheet는 보존한다.

**완료 gate:** Stage 1 built Web에서 engine이 hull에 고정되고 dash ring이
없으며 projectile/pickup을 color와 silhouette로 구분한다.

### Phase 4 — Enemy visual family and Stage 1 collective slice

**목표:** 새 enemy grammar와 collective tactic을 가장 단순한 두 lesson으로
검증한다.

- [ ] 모든 mobile/stationary role을 actor catalog로 migration한다.
- [ ] collective tactic catalog/runtime와 EnemyState hot fields를 추가한다.
- [ ] global permission, offscreen Gather limit, safe cancel, pressure cost와
  telemetry를 구현한다.
- [ ] Stage 1 packet에 Spearhead Teach, Swarm Screen Combine, boss 직전 Power
  Test를 author한다.
- [ ] tactic phase cue를 body silhouette accent로 표시하고 actor마다 별도
  world ring을 추가하지 않는다.
- [ ] guidebook에 두 tactic의 Korean/English break lesson을 추가한다.

**검증**

- formation composition, slot assignment, Gather/Lock/Execute/Break transition,
  lead kill/EMP/cover/min-count break를 deterministic test한다.
- offscreen Execute 0, simultaneous global Execute 1 이하, canceled tactic의
  stale member 0이다.
- 4 quadrant arrival, authored count, quota path, squad size 4–8과 active cap이
  변하지 않는다.
- Stage 1 first encounter capture에서 tactic cue가 projectile/telegraph보다
  높은 visual noise를 만들지 않는다.
- `peak_horde` 3×20초 retention rule을 통과한다.

**완료 gate:** 처음 보는 player가 Spearhead의 선두와 Swarm Screen의 shooter를
shape cue로 고를 수 있고 break 후 명확한 recovery가 보인다.

### Phase 5 — Foundry Colossus vertical slice

**목표:** 하나의 boss를 끝까지 완성해 semantic exam architecture를 검증한다.

- [ ] boss exam catalog/runtime와 sequential health floor를 구현한다.
- [ ] Foundry plate, core, objective read/open/broken component를 연결한다.
- [ ] charge collision, direct damage, EMP/Breach fast path와 vulnerability
  window를 구현한다.
- [ ] Spearhead/Swarm Screen boss command를 finite add와 global permission에
  연결한다.
- [ ] boss practice가 phase 1–3, objective locked/open, Standard/Hard와
  Korean/English를 직접 시작할 수 있게 확장한다.
- [ ] reference build clear-time fixture와 phase-skip validator를 추가한다.

**검증**

- default kit, reference build, high-output build 모두 phase 1→2→3을 순서대로
  경험한다.
- default kit으로 모든 plate/objective를 해결할 수 있다.
- add ≤12, total hostile ≤320, objective cue never-hidden이다.
- Standard reference 50–80초, Hard는 Standard의 110–125%이며 130초 이하다.
- boss death, phase transition, retry에서 plate/add/tactic state leak가 없다.

**완료 gate:** Stage 1 전체 run과 boss practice의 native/Web user QA가
고유 rule, 공정성, 강도와 시각 식별을 승인한다.

### Phase 6 — Stage 2–3 tactics and boss exams

**목표:** side control과 polarity/fuse lesson으로 grammar를 확장한다.

- [ ] Stage 2 Shepherd Pack, Shielded Column과 Teach/Combine/Power Test authoring
- [ ] Leviathan Segment Lock, wake, side vulnerability와 guide text
- [ ] Stage 3 Fuse Pack, Bulwark Fuse와 deterministic chain-break rule
- [ ] Titan Relay Polarity, plus/minus shape, shield window와 guide text
- [ ] 각 stage reference clear-time, boss pressure와 full transition 검증

**검증**

- Stage 2/3에 새 rule을 먼저 단독으로 Teach한 뒤 boss가 같은 break lesson을
  재사용한다.
- polarity는 grayscale에서도 plus/minus shape로 구분된다.
- mine chain은 collision/damage truth를 바꾸지 않고 tactic event만 조정한다.
- Stage 1 회귀, transition, reward, save와 276/320 pressure gate가 통과한다.

**완료 gate:** Stage 1–3 connected run에서 새 tactic/boss rule을 사전 설명
문서 없이 실제 cue와 한 줄 objective로 이해할 수 있다.

### Phase 7 — Stage 4–5 synthesis

**목표:** sustain, route control과 학습된 tactic remix를 최종 run에 연결한다.

- [ ] Stage 4 Repair Network, Crossfire Convoy authoring
- [ ] Behemoth Route Switch와 armor car exam
- [ ] Stage 5 prior tactic remix schedule와 새로운 hidden rule 금지 assertion
- [ ] Crown outer core, lattice corridor, central vulnerability와 command cycle
- [ ] 다섯 boss component/guide/practice/Korean/English parity 완료

**검증**

- link node, switch, outer core의 priority state가 color 외 shape로 보인다.
- simultaneous Execute는 여전히 1개 이하이고 boss adds는 12기 이하다.
- Stage 4 Standard reference 60–95초, Stage 5 75–110초, Hard ≤130초다.
- 다섯 stage connected run에서 objective state, add, tactic, pickup, offer와
  transition leak가 없다.

**완료 gate:** Stage 1–5 run이 같은 grammar를 점진적으로 가르치고 Crown은
새 surprise가 아닌 기존 lesson의 종합으로 작동한다.

### Phase 8 — Retirement, full validation and handoff

**목표:** 병렬 truth를 제거하고 production evidence로 완료를 판정한다.

- [ ] migrated player/enemy/boss/reward/projectile pixel families와 unused dash
  effect를 reference 검색 후 제거한다.
- [ ] `vehicle_combat_visual_library.gd`의 중복 owner를 제거하고 모든 runtime,
  guidebook, practice, sheet가 같은 catalog를 사용하게 한다.
- [ ] pixel-specific validator/inventory는 여전히 map/UI chrome에 필요한
  범위로 축소하고 이름·문구를 실제 scope와 맞춘다.
- [ ] product/design spec, component sheet manifest, guidebook와 localization
  authority를 최종 runtime과 맞춘다.
- [ ] task-scoped code quality audit로 catch-all expansion, competing owner,
  public snapshot contract와 hot-path scan을 확인하고 작은 안전한 수정만 한다.
- [ ] full validators, native/Web performance matrix, 600초 lifecycle soak,
  production Web smoke와 Korean/English capture를 한 clean commit에서 실행한다.
- [ ] 완료 후 이 ExecPlan을 lifecycle 규칙에 따라 `done`으로 표시하고
  `.agents/`의 current authority를 정리한다.

**완료 gate:** 아래 Completion Criteria가 모두 통과하고 task-owned commits와
evidence가 재현 가능한 명령을 가진다.

## Validation Cadence

### Inner-loop validators

```powershell
.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_upgrade_system.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_ui_layout.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_ui_localization.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_pickup_contact.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_player_presentation.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_component_visuals.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_collective_tactics.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_boss_exams.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_combat_renderer.gd
```

새 validator는 해당 owner를 구현한 phase부터 실행한다.

### Component and gameplay capture

```powershell
$sheetDir = Join-Path (Resolve-Path .).Path "build\validation\vehicle-component-sheets"
.\tools\godot.ps1 --path . -- `
  --component-sheet-output=$sheetDir `
  --component-sheet-size=1920x1080

$captureDir = Join-Path (Resolve-Path .).Path "build\validation\combat-rework-ko-960"
.\tools\godot.ps1 --path . -- `
  --capture-all=$captureDir `
  --capture-size=960x540 `
  --capture-locale=ko
```

동일 capture를 `1280×720`, `1920×1080`, `ko`, `en`, reduced-motion으로
반복한다. upgrade modal은 default/selected/third-slot/optional-decline를,
combat은 idle/move/dash/hit/pickup/peak/boss-objective를 포함한다.

### Pressure retention

```powershell
$output = Join-Path (Resolve-Path .).Path "build\performance\combat-rework\peak-horde-01.json"
$godotArgs = @(
  "--rendering-method", "gl_compatibility", "--",
  "--performance-scenario=peak_horde",
  "--performance-output=$output",
  "--performance-warmup=5",
  "--performance-duration=20"
)
.\tools\godot.ps1 @godotArgs
```

각 renderer/collective/boss batch는 같은 clean baseline에서 3회 측정한다.
target subsystem p95가 10% 넘게 악화되거나 frame p95가 5% 넘게 악화되면
해당 batch를 유지하지 않는다. existing authoritative native/Web thresholds,
batch ≤50, draw-call p95 ≤200을 약화하지 않는다.

### Final functional gate

```powershell
.\tools\godot.ps1 --path . --headless --import
$validators = Get-ChildItem tools/validation -Filter 'validate_*.gd' | Sort-Object Name
foreach ($validator in $validators) {
  .\tools\godot.ps1 --path . --headless `
    --script ("res://tools/validation/" + $validator.Name)
  if ($LASTEXITCODE -ne 0) { throw "Validation failed: $($validator.Name)" }
}
.\tools\export_web.ps1
git diff --check
```

Web handoff는 `$npjt-port-guard`로 이 repository의 fastrun-manager `codex`
lane port를 다시 확인한 뒤 `build/web`만 production-style로 serve한다.
Chrome DevTools로 다음을 확인한다.

- page, JS, PCK, WASM request 200
- console error/warning 0
- canvas가 viewport를 채우고 supported size에서 clipping이 없음
- deployment → Stage 1 → upgrade → pickup → dash → boss practice flow
- Korean/English 전환 후 missing key와 fallback text 0
- task-owned server/browser helper 정리

## Test Plan

### Automated contract tests

- component catalog coverage, deterministic mesh fingerprint, duplicate role
  signature, anchor bounds
- protection source overlap, expiry, clear/reset와 presentation snapshot
- engine transform continuity와 dash cue instance count
- pickup swept overlap의 여섯 boundary case
- 83 upgrade state의 summary completeness, max effect rows와 actual glyph bounds
- tactic composition, permission, phase, break, cancel, offscreen와 cap
- boss sequential phase floor, objective unlock, finite add, default-kit solvability
- current stage, spawn allocation, collision, projectile, reward, save, localization,
  guidebook와 transition regression

### Rendered QA

- 960×540 Korean upgrade modal 전체가 viewport에 들어오는가
- 1920×1080 English에서 card가 과도하게 비거나 줄이 깨지지 않는가
- player 360° rotation에서 engine이 rear socket에서 미끄러지거나 꺾이지 않는가
- normal/reduced-motion dash가 방향을 보이되 원형 danger cue를 만들지 않는가
- repair/recall과 projectile affinity를 grayscale에서 구분하는가
- peak horde에서 priority target, active tactic과 hostile projectile core가
  decorative layer보다 먼저 보이는가
- 다섯 boss practice capture를 label 없이도 outer silhouette와 objective
  module로 구분하는가

### Manual gameplay QA

- keyboard/mouse와 controller에서 move/aim/fire/dash가 기존처럼 반응하는가
- 기체가 pickup에 닿거나 dash로 통과할 때 즉시 한 번 획득되는가
- 모든 upgrade card를 읽고 선택 결과를 예측할 수 있는가
- tactic의 Lock 동안 대응할 시간이 있고 Break가 우연이 아니라 player
  행동의 결과로 느껴지는가
- boss objective가 한 줄 cue와 arena state만으로 이해되며 damage window가
  보상처럼 느껴지는가
- boss가 강해졌지만 invulnerability 대기나 무한 add cleanup으로 늘어지지
  않는가

## Rollback and Safety

- 각 phase는 task-scoped commit으로 끝낸다. visual, tactic, boss를 한 commit에
  섞지 않는다.
- component runtime publication은 catalog/sheet와 별도 commit으로 유지한다.
  performance gate 실패 시 publication commit만 되돌릴 수 있어야 한다.
- upgrade resource schema를 추가해도 save data에는 새 field를 직렬화하지
  않는다.
- boss objective와 tactic은 feature flag가 아니라 authored stage data에서
  존재 여부를 결정한다. incomplete stage는 기존 pattern으로 silent fallback
  하지 않고 validator에서 실패한다.
- pixel source를 제거하기 전 `rg`와 full import로 runtime/guidebook/tool
  reference 0을 확인한다.
- horde count, speed, visual radius, collision radius, lockfile, dependency와
  Godot version을 변경하지 않는다.
- unrelated user-authored changes를 stage/revert하지 않는다.

## Risks

| 위험 | 조기 신호 | 완화 |
| --- | --- | --- |
| vector component가 다시 generic polygon처럼 보임 | sheet에서 role 간 outer contour가 비슷함 | role signature test와 approval sheet에서 body/negative-space부터 수정 |
| shape layer 증가로 batch가 늘어남 | batch 50 근접, presentation p95 상승 | ordinary body layer 최대 3, shared mesh/material cache, transient overlay budget 유지 |
| engine은 고정됐지만 aim과 body가 혼동됨 | barrel과 hull facing cue가 같은 크기 | hull facing cut은 넓게, barrel은 가늘고 길게 유지 |
| source windows가 gameplay invulnerability를 바꿈 | overlapping hit/dash expiry가 조기 종료 | source별 max remaining과 overlap unit test 사용 |
| upgrade copy가 짧지만 모호함 | behavior card를 선택한 뒤 결과가 예상과 다름 | level별 summary에 trigger, target, magnitude/condition을 포함하고 실제 behavior test와 대조 |
| compact modal이 지나치게 빽빽함 | 960 capture에서 hierarchy가 사라짐 | fixed content budget을 유지하고 중복 detail/chrome만 줄임 |
| tactic coordinator가 hot path를 악화함 | coordination p95, full-array scan 증가 | member id list와 event queue를 사용하고 actor별 world scan 금지 |
| tactic이 horde를 formation 줄서기로 바꿈 | 네 quadrant occupancy나 pressure가 감소 | surge당 tactic squad 1개, 나머지 current pressure 유지 |
| boss floor가 강제 대기처럼 느껴짐 | objective read 후 player action 없이 timer만 흐름 | objective 즉시 actionable, 기본 kit 해결, fixed invulnerability wait 금지 |
| boss add와 horde가 압도적임 | active cap reserve 부족, cue overlap | finite ≤12, global tactic permission 공유, boss pressure fixture 사용 |
| prior visual spec와 새 component spec가 충돌함 | pixel validator가 migrated family를 요구 | Phase 1에서 active spec을 먼저 갱신하고 final phase에서 validator scope 축소 |

## Open Questions

없다. 시각 방향, component 수, runtime 방식, sheet, UI geometry, pickup
threshold, tactic 순서, boss rule, clear-time target, performance gate와 rollout
dependency는 모두 고정됐다.

BK approval은 여러 방향 중 하나를 고르는 research gate가 아니다. 이 문서에
정한 단일 방향의 실제-scale sheet가 runtime publication 품질에 도달했는지
확인하는 한 번의 visual acceptance gate다.

## Decision Notes

- pixel 관련 active spec 문구보다 이 대화의 최신 사용자 지시가 우선한다.
  구현 시작 시 spec을 먼저 갱신해 authority 충돌을 없앤다.
- Sunken Ceramic Fresco는 pixel technique가 아니라 flat color, recessed mass,
  semantic palette와 restrained ornament로 보존한다.
- current horde plan의 성능 미완료를 이 계획에서 다시 고치지 않는다. 그 plan의
  완료 baseline을 새 renderer/tactic의 비교점으로 사용한다.
- 기존 enemy strategy 문서의 2–3 pressure front 제안은 현재 4방향 horde보다
  오래된 가정이므로 채택하지 않았다. collective phase, formation recipe,
  global permission과 boss reuse는 채택했다.
- 첫 rollout은 repair role을 Stage 1에 억지로 조기 투입하지 않는다.
  Stage 1은 현재 role로 Spearhead/Swarm Screen을 가르치고 Repair Network는
  repair tender가 이미 등장하는 Stage 4에서 사용한다.
- boss의 강함은 반드시 더 많은 HP를 뜻하지 않는다. phase를 건너뛸 수 없고,
  arena/objective를 읽고 해결해야 하며, 성공 시 분명한 damage window를
  얻는 구조를 강함으로 정의한다.

## Progress

- [x] 사용자 feedback을 fact, constraint, preference와 scope로 분류했다.
- [x] active product/design spec, prior visual plan, horde recovery plan과
  enemy strategy/research 문서를 분석했다.
- [x] engine, dash, upgrade, pickup, encounter, enemy, boss와 renderer owner를
  source에서 확인했다.
- [x] focused validators, Web export, built page와 960×540/peak/boss/item
  rendered baseline을 확인했다.
- [x] 하나의 execution solution, rejected alternatives, architecture,
  phase order, acceptance와 stop condition을 고정했다.
- [x] 구현 전 형태 검토용 draft component sheet 6장을
  `docs/design/component-concepts/`에 만들고 component/state mapping을
  문서화했다. 이 시안은 BK 승인 전 draft이며 Phase 1의 deterministic
  runtime sheet gate를 완료한 것으로 간주하지 않는다.
- [ ] Phase 1 component authority and approval sheets
- [ ] Phase 2 upgrade clarity and pickup contact
- [ ] Horde recovery inter-plan gate
- [ ] Phase 3 player/dash/projectile/reward runtime slice
- [ ] Phase 4 enemy visual and Stage 1 collective slice
- [ ] Phase 5 Foundry Colossus vertical slice
- [ ] Phase 6 Stage 2–3 rollout
- [ ] Phase 7 Stage 4–5 synthesis
- [ ] Phase 8 retirement and final acceptance

## Next Steps

1. 여섯 draft concept sheet에서 engine 부착, dash cue, role silhouette,
   projectile core/tail, boss objective와 upgrade glyph 방향을 BK가 검토한다.
2. 승인된 형태를 Phase 1의 component catalog/runtime descriptor로 번역하고
   active design/product spec correction을 함께 적용한다.
3. 같은 runtime descriptor에서 7개 deterministic component sheet와
   pressure/accessibility sheet를 생성해 single-direction acceptance gate를
   연다.
4. correction이 필요하면 승인 grammar 안에서 silhouette, spacing, state
   cue만 한 번 수정하고 style exploration을 다시 열지 않는다.
5. 동시에 owner가 겹치지 않는 Phase 2 upgrade/pickup batch를 별도 commit으로
   진행한다.
6. combat renderer publication은 horde recovery plan 완료 뒤 Phase 3에서
   시작한다.

## Completion Criteria

- [ ] player engine은 모든 continuous hull angle에서 rigid attachment를 유지한다.
- [ ] dash에 coral/radial ring이 없고 normal/reduced-motion cue가 방향을 보인다.
- [ ] player, enemy, boss, item, projectile와 upgrade glyph가 승인 component
  sheet와 동일한 runtime descriptor를 사용한다.
- [ ] migrated combat component에 pixel grid/direction-frame 제약이 남지 않는다.
- [ ] role은 color 외 silhouette/negative-space cue를 가진다.
- [ ] 41 upgrade card, 83 state, Korean/English, 3 viewport에서 overflow,
  overlap, clipping, missing effect가 0이다.
- [ ] player가 pickup과 겹치거나 dash로 통과하면 정확히 한 번 획득한다.
- [ ] Stage 1–5의 Teach/Combine/Power Test와 tactic telemetry가 존재한다.
- [ ] offscreen Execute 0, simultaneous global Execute 1 이하, stale tactic member
  0이다.
- [ ] 다섯 boss가 서로 다른 semantic exam을 가지고 phase skip이 0이다.
- [ ] boss objective는 기본 kit으로 해결 가능하고 adds ≤12, total hostile ≤320이다.
- [ ] reference clear-time과 Hard upper bound를 만족한다.
- [ ] existing manual aim, held primary fire, dash control, passive seeker, EMP,
  authored encounter, map pickup, card upgrade, quota-gated boss와 connected run이
  회귀하지 않는다.
- [ ] full validators, native/Web build, production smoke, authoritative pressure
  matrix와 600초 lifecycle soak가 통과한다.
- [ ] retained combat batch ≤50, draw-call p95 ≤200과 horde performance
  thresholds를 약화하지 않는다.
- [ ] Korean/English, reduced motion, grayscale와 supported viewport evidence가
  저장된다.
- [ ] obsolete migrated pixel runtime owner와 competing visual truth가 제거된다.
- [ ] product/design docs, guidebook, sheet manifest와 runtime이 일치한다.

## Stop Conditions

다음이면 완료한다.

- 모든 Completion Criteria가 clean task-scoped commits와 재현 가능한 evidence로
  통과한다.

다음 경우에만 구현을 멈추고 BK에게 escalation한다.

- 승인된 component direction을 구현하려면 engine, dependency, current visual
  scale 또는 collision truth를 바꿔야 하는 경우
- horde recovery plan의 완료 baseline이 없거나 authoritative gate가 계속
  실패해 renderer/tactic 비교 자체가 불가능한 경우
- default kit으로 boss objective를 해결할 수 없고 해결을 위해 card/save
  contract 변경이 필요한 경우
- 960×540 Korean/English에서 fixed content budget을 지키려면 user-facing
  effect를 숨겨야 하는 경우
- 이 계획 밖의 full map/UI redesign 없이는 component readability를 검증할 수
  없다는 새로운 material evidence가 생긴 경우

다음은 중단 사유가 아니다.

- 한 sheet의 silhouette/spacing에 한 번의 bounded correction이 필요한 경우
- focused validator가 구체적인 in-scope defect를 찾은 경우
- 한 boss의 health나 module health가 이 문서의 clear-time 범위 안에서 조정돼야
  하는 경우
- obsolete pixel caller cleanup이 남은 경우
- 한 번의 non-authoritative smoke가 느리거나 noisy한 경우

## Handoff

```text
Goal:
Replace combat pixel-direction assets and generic encounter/boss repetition with
one runtime-owned vector component grammar, readable upgrade cards, swept pickup
contact, staged collective tactics, and five semantic boss exams.

Read first:
1. This plan
2. .agents/execplans/2026-07-29-horde-foundation-recovery-and-acceptance.md
3. docs/product/vehicle_game_spec.md
4. docs/design/UI_VISUAL_SYSTEM.md
5. docs/product/combat-growth-improvement-direction.md
6. docs/research/hidden-techniques-collective-enemies-mastery-unlocks.md

First batch:
Phase 1 only. Correct active visual/product authority, implement the component
catalog and deterministic sheet generator, produce the eight approval sheets,
and stop at the single-direction visual acceptance gate.

Do not:
- touch the combat renderer before the horde inter-plan gate;
- reduce enemy count, speed, visual scale, collision, or four-sector arrival;
- add a production dependency;
- hide upgrade content with scrolling or tiny fonts;
- treat boss HP inflation as the boss rework;
- expand VehicleRun with visual recipes, tactic definitions, or boss exam policy.

Validate:
Use tools/godot.ps1, the phase-owned validators, deterministic captures, the
horde retention rule, Web export, the npjt codex-lane production start, and
Chrome DevTools. Commit only task-owned coherent phase changes.
```
