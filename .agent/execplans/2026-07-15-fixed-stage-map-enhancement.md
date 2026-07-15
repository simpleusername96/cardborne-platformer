---
type: plan
status: active
owner: BK
created: 2026-07-15
last_reviewed: 2026-07-15
source: Current fixed-stage code and metrics, rendered room captures, 2D platformer map-design research, and the canonical map-design guideline
topic: Gameplay-verticality and map-composition enhancement for the three fixed normal stages
scope: Metrics, curated topology, authored room geometry, encounter placement, camera proof, and continuous traversal validation
related:
  - ../../docs/product/2d_platform_action_card_game_prd.md
  - ../../docs/design/MAP_AUTHORING_PIPELINE_CONTRACT.md
  - ../../docs/design/2D_PLATFORMER_MAP_DESIGN_GUIDELINE.md
  - ../../docs/research/2d_platformer_map_design_research_2026-07-15.md
  - ./2026-07-15-gameplay-validity-repair.md
---

# Fixed Stage Map Enhancement ExecPlan

## Purpose

현재 세 normal stage가 자동 수치상 “높은 맵”인 데서 멈추지 않고,
높이가 경로 선택, 적 대응, 위험·보상, camera 정보, 행동 리듬을 바꾸는
짧고 완결된 action-platform stage가 되도록 재저작한다.

이 plan은 실제 구현 체크리스트다. 각 milestone은 blockout → 자동 검증 →
rendered inspection → continuous play 순서로 닫는다. 이전 milestone의
acceptance가 실패하면 다음 stage로 넘어가지 않는다.

## Why / Context

2026-07-15 current validator는 세 stage 모두 통과한다.

| Stage | Required | Enemies | Range | Ascent | Descent | Elevation changes | Multi-elevation combat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Ruin Approach | 8 | 8 | 720 px | 720 px | 0 px | 9 | 2 |
| Flooded Works | 7 | 10 | 760 px | 800 px | 40 px | 9 | 3 |
| Broken Sanctum | 9 | 12 | 740 px | 980 px | 240 px | 11 | 4 |

그러나 다음 validity gap이 남아 있다.

- Ruin은 하강 없는 monotonic staircase다.
- Ruin과 Flooded optional room은 choice hub에서 나갔다 같은 hub로 돌아온다.
- Sanctum의 두 optional room은 모두 한 `bs_twin_reliquary_choice`에 몰려 있다.
- current metric은 높이가 decision을 바꾸는지, branch가 얼마나 지속되는지,
  main/optional route가 읽히는지 측정하지 않는다.
- rendered choice rooms는 넓은 평지, 단순 floating ledge, 큰 empty void가
  중심이고 route별 payoff와 threat가 약하다.
- teleported still capture는 continuous camera와 실제 traversal rhythm을
  증명하지 않는다.

[2D Platformer Map Design Research](../../docs/research/2d_platformer_map_design_research_2026-07-15.md)의
결론에 따라 range와 enemy count를 더 올리는 것만으로는 해결하지 않는다.

## Outcome

완료 시:

1. Ruin은 broken ascent 안에 controlled descent와 실제 upper/lower decision을
   갖는다.
2. Flooded는 basin으로 내려갔다 pump shaft를 되오르는 명확한 pressure
   waveform을 갖는다.
3. Sanctum은 gate loop와 두 개의 분산된 branch, forward rejoin, multi-height
   crossfire를 갖는다.
4. 모든 combat room은 enemy-terrain relation을 한 문장으로 설명할 수 있다.
5. stage topology와 height profile은 자동 진단되고, route clarity는
   continuous rendered playtest로 증명된다.
6. 기존 retry, safe intermission, Forge/merchant 분리, reward, boss flow,
   keyboard input 계약은 회귀하지 않는다.

## Scope

### In scope

- `StageCompositionMetrics.gd`와 `validate_stage_composition.gd` 진단 강화
- `CuratedStagePlanBuilder.gd`의 fixed topology와 connection 수정
- active authored room scene의 collision/platform/anchor/camera composition
- room resource socket, recovery, enemy/hazard/reward anchor 갱신
- 기존 enemy variant와 hazard의 재배치
- fixed-stage capture target과 continuous traversal evidence 추가
- 관련 validator와 product-flow regression

### Non-scope

- UI/HUD/modal/typography 변경
- gamepad 또는 다른 platform 입력
- player movement value 또는 새 movement skill 변경
- 새 enemy archetype, boss pattern, card, equipment, merchant item 추가
- moving platform처럼 현재 미구현인 gimmick의 신규 구현
- final world-art asset generation 또는 panorama 수량 결정
- procedural/random stage production 복귀
- death checkpoint 또는 save-point policy 변경
- normal stage 안에 Forge, merchant, safe-intermission NPC 재도입

## Ownership and File Boundaries

| Responsibility | Expected owner |
| --- | --- |
| stage-level diagnostics | `scripts/generation/StageCompositionMetrics.gd` |
| fixed topology | `scripts/generation/CuratedStagePlanBuilder.gd` |
| plan validity | `scripts/generation/StagePlanValidator.gd` only if graph contract requires it |
| authored geometry | `scenes/rooms/lower_ruins/`, `flooded_works/`, `broken_sanctum/` |
| sockets and content anchors | matching `data/rooms/**.tres` |
| authoring/resource validity | existing `tools/validate_room_templates.gd` and related validators |
| map composition acceptance | `tools/validate_stage_composition.gd` |
| rendered evidence | `tools/capture_fixed_stage_screenshots.gd` plus a bounded continuous-traversal capture if needed |

`RoomTemplateData.gd`에 design prose field를 바로 추가하지 않는다.
room intention은 이 plan의 matrices와 authored scene/resource가 소유한다.
향후 여러 stage에서 machine-readable intent가 반복적으로 필요하다는
증거가 생길 때만 schema 변경을 검토한다.

## Assumptions

- 현재 movement tuning과 `MovementMetrics.gd`는 유지한다.
- current active room count를 우선 유지하고 geometry와 connection을
  재작성한다. 새 room은 acceptance를 충족할 수 없다는 증거가 있을 때만
  별도 scope로 요청한다.
- current enemy floors 8/10/12와 required-room counts 8/7/9는 하한으로
  보존한다.
- optional reward resolution, stable IDs, deterministic seed behavior를
  유지한다.
- fall recovery anchor는 local traversal recovery이며 death respawn이 아니다.
- UI overhaul dirty work와 master integration plan은 이 작업이 소유하지 않는다.
- Web export template가 준비되지 않은 동안 desktop production capture를
  strongest substitute로 쓰되, release acceptance는 served Web 확인 전
  닫지 않는다.

## Proposed Design

### Shared macro rule

모든 stage는 다음 구조를 갖는다.

> safe preview → signature verb teach → first pressure peak → route/height
> transform → combat or hazard test → release → combined final test

stage마다 동일한 순서의 방을 복제하지 않고, signature geometry와
height profile을 다르게 한다.

### Ruin Approach: broken ascent

Spatial thesis:

> 무너진 외곽을 오르며 위쪽의 빠르지만 노출된 line과 아래쪽의 느리지만
> 안전한 line을 배우고, 마지막에 charger lane과 shooter elevation을
> 함께 해결한다.

Target height profile:

> safe shelf ↑ stepped climb ↑ first peak ↓ controlled broken-gallery descent
> ↗ split/rejoin ↑ final ascent

Stage-specific diagnostic target:

- current 720 px range와 8 enemies를 보존한다.
- 64 px 이상 meaningful descent를 최소 두 번 만든다.
- ascent → descent → ascent의 direction reversal을 최소 두 번 만든다.
- optional route는 출발 choice hub가 아니라 이후 critical room에
  forward-rejoin한다.
- 두 tactical combat room은 enemy y-span뿐 아니라 다른 threat/escape line을
  manual evidence로 증명한다.

### Flooded Works: descend, survive, pump upward

Spatial thesis:

> flooded entry에서 basin으로 내려가 poison timing과 leaper pressure를
> 익힌 뒤, dry upper timing line 또는 wet lower management line을 선택해
> pump gallery를 상승 탈출한다.

Target height profile:

> safe entry ↓ rope/basin descent ↓ pressure floor ↑ route split ↗ pump climb
> → shelter

Stage-specific diagnostic target:

- current 760 px range, 10 enemies, 3 multi-elevation candidate room을 보존한다.
- descent와 ascent 각각에 64 px 이상 meaningful transition을 세 번 이상
  포함한다.
- `fw_sunken_cache`는 same-hub return 대신 pump-gallery 앞 또는 안쪽에
  forward-rejoin한다.
- upper/lower line은 movement, hazard exposure, time, reward 중 최소 둘에서
  다르다.
- moving platform 신규 구현 없이 rope/one-way/static platform과 existing
  poison/crumble contract만 사용한다.

### Broken Sanctum: interlocked nave

Spatial thesis:

> gate와 nave를 서로 다른 높이에서 다시 지나며 shortcut을 열고, 분산된
> 두 optional path와 cover band를 이용해 sentry crossfire를 돌파한다.

Target height profile:

> breach ↑ shield flank ↕ gate loop ↓ lower crypt branch/rejoin ↑ nave transfer
> ↗ gallery → recovery ↗ upper reliquary branch/rejoin ↑ crossfire/final ascent

Stage-specific diagnostic target:

- current 740 px range, 12 enemies, 4 multi-elevation candidate room을 보존한다.
- `bs_material_crypt`와 `bs_reliquary_cache`의 branch origin은 critical
  route 기준 최소 두 room 떨어진 서로 다른 portal이어야 한다.
- 두 optional path 모두 same-hub return을 제거하고 다음 또는 이후 critical
  room에 forward-rejoin한다.
- `bs_twin_reliquary_choice`는 모든 optional content의 hub가 아니라
  main-route vertical transfer room으로 재정의한다.
- gate switch 뒤 이미 본 공간을 다른 높이에서 빠르게 통과하는 shortcut을
  눈으로 확인할 수 있어야 한다.

## Target Room Intention Matrices

이 표는 implementation 중 임의로 room을 채우는 것을 막는 최소 설계 계약이다.
blockout 결과가 더 나은 의도를 발견하면 Decision Notes에 이유를 남기고
표를 먼저 갱신한다.

### Ruin Approach

| Room | Rhythm role | Target intention | Required proof |
| --- | --- | --- | --- |
| `lr_start_shelf` | Preview | broken ascent의 첫 landmark와 safe landing language를 보여준다. | 첫 control frame이 안전하고 다음 ledge가 보임 |
| `lr_rise_steps` | Teach | 기본 jump/dash로 두 elevation band를 오르고 낮은 recovery shelf를 경험한다. | 실패가 death가 아닌 lower recovery로 이어짐 |
| `lr_patrol_gallery` | Transform | walker 때문에 upper/lower band를 바꾸게 한다. | 같은 floor에서 전부 처리할 수 없는 pressure |
| `lr_shooter_overlook` | First peak | upper exposure와 lower cover를 shooter line으로 구분한다. | entry safe zone과 shooter tell이 같은 frame |
| `lr_lower_upper_choice` | Route decision | 빠른 exposed line과 안전한 slower line의 비용을 먼저 보여준다. | route별 movement/risk 차이 2개 이상 |
| `lr_destructible_cache` | Optional loop | 짧은 challenge 끝 reward를 얻고 앞쪽으로 재합류한다. | reward를 challenge 중간에 banking하지 않음 |
| `lr_broken_bridge` | Release/transform | 이전 peak를 내려다보고 controlled descent 뒤 새 ascent를 시작한다. | Forge/NPC 없음, empty corridor가 아님 |
| `lr_charge_lane` | Combine | horizontal charge lane을 side ledge로 피하고 재진입한다. | escape ledge가 threat를 실제로 끊음 |
| `lr_exit_ascent` | Test | 이미 배운 elevation transfer와 enemy priority를 짧게 결합한다. | 신규 필수 mechanic 없음, exit 전 recovery |

### Flooded Works

| Room | Rhythm role | Target intention | Required proof |
| --- | --- | --- | --- |
| `fw_flooded_entry` | Preview | 아래 basin과 최종 pump landmark를 먼저 암시한다. | safe entry에서 하강 destination이 보임 |
| `fw_rope_shaft` | Teach | vertical transfer와 높이별 enemy response를 안전하게 소개한다. | 한 번에 한 pressure role부터 노출 |
| `fw_poison_timing` | Transform | safe pad 사이 timing 이동을 가르치되 기다릴 공간을 보장한다. | poison tell 전에 safe destination 표시 |
| `fw_leaper_basin` | First peak | controlled drop 뒤 leaper center pressure에서 두 exit를 판단한다. | basin entry가 blind drop이 아님 |
| `fw_lower_upper_choice` | Route decision | dry upper precision과 wet lower hazard management를 구분한다. | route별 verb/risk 차이와 reward clue |
| `fw_sunken_cache` | Optional loop | lower risk를 연장해 reward를 얻고 앞쪽으로 빠져나간다. | same-hub backtrack 제거 |
| `fw_pump_gallery` | Combine/test | shooter/leaper/charger pressure와 known timing을 상승 중 결합한다. | entry safe zone, 중간 recovery band |
| `fw_exit_shelter` | Release | stage pressure를 풀고 다음 flow로 명확히 넘긴다. | enemy/hazard 없는 짧은 전망, Forge 없음 |

### Broken Sanctum

| Room | Rhythm role | Target intention | Required proof |
| --- | --- | --- | --- |
| `bs_breach_entry` | Preview | nave landmark와 잠긴 vertical relation을 보여준다. | 첫 목표와 later return landmark가 보임 |
| `bs_shield_choke` | Teach | shield front를 피하려 side elevation으로 flank한다. | baseline line과 flank line 모두 clear |
| `bs_gate_switch_loop` | Transform | switch를 켠 뒤 다른 높이의 짧은 return route를 연다. | gate state와 opened shortcut이 같은 spatial memory를 사용 |
| `bs_material_crypt` | Early optional | controlled lower drop, reward, forward rejoin을 제공한다. | branch origin과 rejoin이 다른 critical room |
| `bs_volatile_nave` | Hazard peak | 이미 본 nave를 hazard timing으로 다시 해석한다. | safe zone과 commitment가 camera에 보임 |
| `bs_twin_reliquary_choice` | Transfer | twin optional hub 대신 main-route vertical transept가 된다. | 한 문장 main intention, ambiguous exits 없음 |
| `bs_fractured_gallery` | Combine | fractured platforms에서 enemy priority와 elevation change를 결합한다. | enemy가 빈 곳 채우기가 아닌 terrain role 보유 |
| `bs_recovery_cloister` | Release/clue | 안전한 회복과 later upper branch clue를 제공한다. | safe zone이 crossfire reach 밖 |
| `bs_reliquary_cache` | Late optional | 숙련된 upper line과 reward 뒤 crossfire 앞쪽으로 재합류한다. | early crypt와 다른 verb/risk |
| `bs_sentry_crossfire` | Tactical test | cover band 사이를 이동해 sentry line을 끊고 flank한다. | unavoidable entry hit 없음, 두 threat lane 식별 |
| `bs_exit_ascent` | Final test | gate, flank, elevation transfer를 짧게 결합한다. | 새 요소 없음, boss/next-flow 전 release |

## Tasks

- [ ] Milestone A에서 directionality와 branch topology diagnostic을 먼저
  red/green 검증한다.
- [ ] Milestone B에서 Ruin을 pilot stage로 재저작하고 continuous play로
  guideline을 증명한다.
- [ ] Milestone C에서 Flooded의 basin descent와 pump ascent를 재저작한다.
- [ ] Milestone D에서 Sanctum branch를 분산하고 gate/shortcut loop를 만든다.
- [ ] Milestone E에서 세 stage의 encounter, camera, pacing을 함께 review한다.
- [ ] Milestone F에서 자동·rendered·continuous·Web production evidence를
  합쳐 release acceptance를 닫는다.

## Milestones

### Milestone A — Baseline and diagnostic contract

Goal: 현재 결과를 보존하고 “수치상 높음”과 “의미 있는 수직성”을 분리해
검출한다.

Tasks:

- [ ] current validator JSON과 fixed-stage captures를 dated evidence 위치에
  보존하거나 재생성 명령과 hash를 기록한다.
- [ ] current critical graph를 stage별 node/edge table로 snapshot한다.
- [ ] `StageCompositionMetrics.gd`에 direction reversal을 추가한다.
- [ ] meaningful ascent와 descent transition count를 각각 추가한다.
- [ ] optional branch origin, rejoin, divergence span, stage-position
  distribution diagnostic을 추가한다.
- [ ] same-hub return과 forward rejoin을 구분한다.
- [ ] current vertical range, enemy floor, elevation-change, empty-run gate를
  제거하거나 약화하지 않는다.
- [ ] diagnostic을 단일 aggregate score로 만들지 않는다.
- [ ] validator error가 stage ID, measured value, expected condition을
  구체적으로 말하게 한다.
- [ ] current stage가 새 target에서 왜 실패하는지 red test로 먼저 확인한다.

Acceptance:

- [ ] current three-stage metrics가 이전 값과 동일하게 재현된다.
- [ ] current Ruin monotonic profile을 새 diagnostic이 검출한다.
- [ ] current four same-hub optional return edge를 graph diagnostic이 검출한다.
- [ ] reachability 또는 stable-ID validation이 회귀하지 않는다.

### Milestone B — Ruin blockout and room pass

Goal: 가장 단순한 stage에서 guideline을 먼저 증명한다.

Tasks:

- [ ] target room matrix를 실제 scene node/anchor inventory와 대조한다.
- [ ] stage macro sketch를 start/peak/descent/split/rejoin/exit로 확정한다.
- [ ] `lr_rise_steps`와 `lr_patrol_gallery`의 ascent를 두 개의 distinct
  elevation band로 정리한다.
- [ ] `lr_shooter_overlook`에 safe entry, lower cover, upper exposure를 만든다.
- [ ] `lr_lower_upper_choice`의 두 route를 movement/risk 두 항목 이상에서
  다르게 만든다.
- [ ] `lr_destructible_cache` return socket을 앞쪽 critical route로 옮긴다.
- [ ] `lr_broken_bridge`에 controlled descent와 vista/release를 만들고
  Forge/NPC가 없음을 확인한다.
- [ ] `lr_charge_lane`에 charge를 끊는 side ledge와 명확한 re-engage
  landing을 만든다.
- [ ] `lr_exit_ascent`는 known element만 결합하도록 정리한다.
- [ ] geometry 수정에 맞춰 recovery/enemy/reward/socket anchor를 갱신한다.
- [ ] 모든 changed room의 content version을 contract에 맞게 갱신한다.

Acceptance:

- [ ] range ≥ 720 px, enemies ≥ 8, required rooms = 8.
- [ ] meaningful descent transition ≥ 2.
- [ ] direction reversal ≥ 2.
- [ ] optional branch가 forward-rejoin한다.
- [ ] first-time viewer가 upper/lower route와 reward를 debug label 없이
  설명한다.
- [ ] shooter와 charger room에서 elevation change가 실제 response를 바꾼다.
- [ ] baseline continuous clear, fall recovery, stage retry가 통과한다.

### Milestone C — Flooded blockout and room pass

Goal: basin descent와 pump ascent가 stage의 장소성과 timing을 함께 표현한다.

Tasks:

- [ ] entry에서 basin 또는 pump landmark 중 하나를 먼저 보여준다.
- [ ] rope shaft를 vertical teach room으로 단순화한 뒤 pressure를 단계적으로
  추가한다.
- [ ] poison timing room에 기다릴 safe pad와 다음 destination을 보장한다.
- [ ] leaper basin의 drop을 blind fall이 아닌 previewed commitment로 만든다.
- [ ] lower/upper choice를 dry precision과 wet management로 구분한다.
- [ ] sunken cache를 same-hub return에서 forward rejoin으로 바꾼다.
- [ ] pump gallery를 known element의 vertical combine/test로 재구성한다.
- [ ] exit shelter는 짧은 release로 유지하고 facility/NPC를 넣지 않는다.
- [ ] existing hazard reset과 room retry가 새 geometry에서 결정론적으로
  동작하는지 확인한다.

Acceptance:

- [ ] range ≥ 720 px, enemies ≥ 10, required rooms = 7.
- [ ] meaningful descent sequence와 ascent sequence가 각각 3 transition 이상.
- [ ] optional branch가 forward-rejoin한다.
- [ ] upper/lower route가 movement, hazard, time, reward 중 2개 이상에서 다르다.
- [ ] poison/leaper/pump peak 사이에 safe recovery가 있다.
- [ ] moving platform 신규 구현 없이 모든 required line이 clear된다.
- [ ] baseline continuous clear와 real-hazard reset이 통과한다.

### Milestone D — Sanctum topology distribution and room pass

Goal: 한 hub에 몰린 branch를 stage 전체 loop와 shortcut으로 분산한다.

Tasks:

- [ ] material crypt branch origin을 gate-loop 또는 volatile-nave 구간으로 옮긴다.
- [ ] reliquary cache branch origin을 recovery-cloister 이후 구간으로 옮긴다.
- [ ] 두 branch의 new sockets와 forward rejoin을 authored scene/resource에
  추가한다.
- [ ] twin reliquary choice를 unambiguous main-route transfer room으로
  재작성한다.
- [ ] gate-switch loop가 opened shortcut으로 이동 시간을 줄이는지 확인한다.
- [ ] shield choke의 flank elevation과 recovery floor를 정리한다.
- [ ] fractured gallery의 enemy마다 terrain relation을 기록하고 불필요한
  enemy를 제거 또는 이동한다.
- [ ] recovery cloister를 실제 crossfire 밖 safe zone으로 만든다.
- [ ] sentry crossfire에 cover band, transfer window, flank path를 만든다.
- [ ] exit ascent에서 새 mechanic을 추가하지 않고 known element를 결합한다.

Acceptance:

- [ ] range ≥ 720 px, enemies ≥ 12, required rooms = 9.
- [ ] 두 branch origin이 critical route에서 최소 2 room 떨어져 있다.
- [ ] 두 branch 모두 forward-rejoin한다.
- [ ] gate shortcut이 시각적으로 열리고 실제 traversal을 줄인다.
- [ ] shield, fractured, sentry combat이 서로 다른 tactical verticality를 준다.
- [ ] recovery cloister 진입 시 unavoidable projectile 또는 body hit이 없다.
- [ ] baseline continuous clear, both optional loops, stage retry가 통과한다.

### Milestone E — Cross-stage encounter, camera, and pacing pass

Goal: room이 개별적으로만 괜찮은 상태를 넘어 stage sequence가 cohesive하게
작동하게 한다.

Tasks:

- [ ] 모든 active room에 one-sentence intention과 rhythm role이 남아 있는지
  target matrix를 갱신한다.
- [ ] 각 enemy anchor에 terrain relation이 없는 경우 제거, 이동, 교체한다.
- [ ] stage별 first peak와 final test 사이에 동일 setup이 반복되지 않는지
  review한다.
- [ ] 모든 room entry와 exit buffer를 실제 threat reach로 확인한다.
- [ ] irreversible jump/drop 전 camera가 landing 또는 safe cue를 보여준다.
- [ ] reward anchor가 optional line과 risk를 설명하는 위치인지 확인한다.
- [ ] 8초 이상 decision vacuum이 드문지 continuous timing note를 남긴다.
- [ ] Ruin/Flooded/Sanctum silhouette를 collision-only overview로 비교한다.
- [ ] normal stage 안에 Forge, merchant, intermission NPC가 없는지 validator와
  rendered run으로 확인한다.

Acceptance:

- [ ] 각 stage가 signature spatial verb와 teach/transform/test/release를
  한 문단으로 설명할 수 있다.
- [ ] 세 stage의 collision-only silhouette와 height waveform이 구별된다.
- [ ] 모든 combat room이 enemy-terrain relation을 통과한다.
- [ ] 모든 critical camera commitment가 first-time clear에서 읽힌다.
- [ ] safe intermission과 normal-stage facility separation이 회귀하지 않는다.

### Milestone F — Release-level validation

Goal: 자동 수치, 정지 캡처, 연속 플레이, Web production path가 같은 결과를
증명한다.

Tasks:

- [ ] Godot import와 모든 targeted validator를 실행한다.
- [ ] fixed capture 목록에 각 stage의 teach, route choice, combat peak,
  optional rejoin, release를 포함한다.
- [ ] teleport still 외에 stage start-to-exit continuous traversal evidence를
  stage별 하나씩 남긴다.
- [ ] baseline required route를 keyboard input으로 연속 clear한다.
- [ ] optional route를 각각 진입, reward, rejoin까지 연속 clear한다.
- [ ] actual enemy damage, guard, fall recovery, stage retry를 새 geometry에서
  확인한다.
- [ ] Web export template가 있으면 production Web export를 만들고 built app을
  fastrun codex lane에서 확인한다.
- [ ] Web export template가 여전히 없으면 blocker를 기존 gameplay-validity
  plan과 연결하고 desktop production capture를 임시 evidence로 남긴다.
- [ ] capture와 metric의 before/after summary를 research 또는 completion
  record에 추가한다.

Acceptance:

- [ ] 모든 automated command가 exit 0이다.
- [ ] required/optional route에서 soft lock, blind commitment, reward duplicate,
  missing recovery가 없다.
- [ ] 1280×720과 compact supported viewport에서 route와 enemy tell이 읽힌다.
- [ ] production Web path가 가능할 경우 desktop과 동작이 일치한다.
- [ ] guideline의 10개 acceptance criterion을 모두 체크했다.

## Test Plan

### Static/import and content validation

`.\tools\godot.ps1 --path . --headless --import`

`.\tools\godot.ps1 --path . --headless --script res://tools/validate_room_templates.gd`

`.\tools\godot.ps1 --path . --headless --script res://tools/validate_curated_stage_plans.gd`

`.\tools\godot.ps1 --path . --headless --script res://tools/validate_stage_composition.gd`

`.\tools\godot.ps1 --path . --headless --script res://tools/validate_production_stage.gd`

### Flow regressions

`.\tools\godot.ps1 --path . --headless --script res://tools/validate_forge_station_flow.gd`

`.\tools\godot.ps1 --path . --headless --script res://tools/validate_safe_intermission_flow.gd`

관련 gameplay-validity release matrix가 targeted command를 제공하면 같은
commit에서 재실행한다.

### Rendered evidence

`.\tools\godot.ps1 --path . --headless --script res://tools/capture_fixed_stage_screenshots.gd`

Capture minimum:

| Stage | Required views |
| --- | --- |
| Ruin | teach, shooter split, optional forward rejoin, charge test, exit release |
| Flooded | descent preview, leaper basin, upper/lower split, pump ascent, shelter |
| Sanctum | gate loop before/after, early branch, late branch, crossfire, final ascent |

### Manual continuous scenarios

1. Start a fresh run and clear each required route without equipment-dependent jump.
2. Intentionally miss one landing in every stage and confirm local recovery.
3. Take every optional path, collect reward, rejoin, then retry the stage.
4. In each tactical combat room, use both intended elevation responses.
5. Pause or hesitate at every room entry and confirm no unavoidable hit.
6. Explain the next route, optional clue, and reward without debug labels.
7. Measure any stretch longer than eight seconds without movement, combat, route,
   or reward decision.

### Web production validation

When export templates are available:

1. Run `.\tools\export_web.ps1`.
2. Load `$npjt-port-guard` before starting the built app under `D:\npjt`.
3. Use the fastrun manager's `codex` lane.
4. Inspect the built Web app, not only the editor/dev path.
5. Verify keyboard movement, jump, dash, attack, guard, interaction, pause,
   stage retry, optional branch, and camera framing.

## Progress

- [x] Current stage code, topology, metrics, and fixed captures inspected.
- [x] External research and visual-source analysis completed.
- [x] Canonical map-design guideline written.
- [x] Current metrics rerun on Godot 4.7 and recorded.
- [ ] Milestone A diagnostic contract implemented.
- [ ] Milestone B Ruin implemented and accepted.
- [ ] Milestone C Flooded implemented and accepted.
- [ ] Milestone D Sanctum implemented and accepted.
- [ ] Milestone E cross-stage pass accepted.
- [ ] Milestone F release validation accepted.

## Next Steps

1. Implement Milestone A only.
2. Produce the Ruin macro sketch and update the Ruin target matrix if blockout
   evidence requires a better sequence.
3. Complete and playtest Ruin before touching Flooded.
4. Apply the proven pattern to Flooded, then Sanctum without copying the same
   silhouette.

## Rollback / Safety

- Commit each milestone separately so one stage can be reverted without touching
  the others.
- Do not stage or commit unrelated UI, master-integration, generated import, or
  user-authored dirty files.
- Preserve stable room IDs and reward IDs. Change content version when authored
  geometry or anchor meaning changes.
- Keep current room scenes available until replacement geometry passes
  reachability, flow, and capture validation in the same milestone.
- Never weaken movement, no-soft-lock, safe-intermission, or reward-duplication
  validators to make new geometry pass.
- If a forward rejoin breaks the current graph contract, extend the validator
  explicitly; do not bypass it with hidden teleports.
- Do not add external assets or dependencies.

## Risks

| Risk | Mitigation |
| --- | --- |
| Better-looking geometry becomes harder than intended | baseline movement proof, safe entry, continuous first-clear test |
| More vertical combat produces unavoidable hits | threat-lane review, entry buffer, one pressure role introduced at a time |
| Forward rejoin breaks reward/reset determinism | stable IDs, retry test after each optional reward, graph validation |
| Metrics are gamed again | separate diagnostics, no aggregate score, manual critical gates |
| Three stages converge on the same zigzag shape | lock distinct spatial thesis and compare collision-only silhouettes |
| Camera reveals information too late | commitment-before-information capture checklist |
| Scope leaks into UI or world art | keep UI and final art in their existing plans; blockout/readability only here |
| Web QA remains blocked | preserve desktop evidence, link the exact export-template blocker, do not claim release closure |

## Open Questions

No question blocks Milestone A or Ruin blockout. The following decisions are
deferred until rendered evidence exists:

- Whether one currently inactive catalog room should replace an active room.
  Default: do not increase active room count.
- Whether continuous evidence is best stored as short video, frame sequence, or
  scripted checkpoints. Default: use the smallest artifact that proves camera and
  traversal without adding runtime code.
- Whether future authored stages need machine-readable intention metadata.
  Default: keep intention in plan/spec until repeated validator value is proven.

## Decision Notes

- 2026-07-15: Structural range alone is rejected as the definition of verticality.
- 2026-07-15: Fixed curated topology remains the production baseline.
- 2026-07-15: Current movement values, enemy catalog, stage counts, and UI branch
  remain outside the map redesign.
- 2026-07-15: Existing room count is preserved for the first pass.
- 2026-07-15: Optional paths should forward-rejoin by default; same-hub return
  requires an explicit reward and pacing justification.
- 2026-07-15: Ruin is the pilot stage. Flooded and Sanctum do not begin until
  Ruin proves the guideline through continuous play.
- 2026-07-15: World-space route readability belongs to map authoring even while
  UI readability is handled separately.
