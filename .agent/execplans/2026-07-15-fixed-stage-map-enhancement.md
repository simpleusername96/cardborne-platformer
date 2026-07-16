---
type: plan
status: active
owner: BK
created: 2026-07-15
last_reviewed: 2026-07-16
source: Current fixed-stage code and metrics, rendered room captures, 2D platformer map-design research, the canonical map-design guideline, Codex session 019f6138-03a7-73d1-8ec6-a959d2f4d935, the 2026-07-16 per-stage visual and owner-play reviews, and official Nintendo/Ubisoft navigation guidance
topic: Gameplay verticality, completion policy, exploration readability, and map composition for the three fixed normal stages
scope: Metrics, curated topology, authored room geometry, traversal comfort, stage-exit eligibility, fog-of-war minimap state, terrain-aware encounter behavior, camera proof, and continuous traversal validation
related:
  - ../../docs/product/2d_platform_action_card_game_prd.md
  - ../../docs/design/MAP_AUTHORING_PIPELINE_CONTRACT.md
  - ../../docs/design/2D_PLATFORMER_MAP_DESIGN_GUIDELINE.md
  - ../../docs/design/PRODUCTION_UI_CONTRACT.md
  - ../../docs/research/2d_platformer_map_design_research_2026-07-15.md
  - ./2026-07-15-gameplay-validity-repair.md
---

# Fixed Stage Map Enhancement ExecPlan

## Purpose

현재 세 normal stage가 자동 수치상 “높은 맵”인 데서 멈추지 않고,
높이가 경로 선택, 적 대응, 위험·보상, camera 정보, 행동 리듬을 바꾸는
짧고 완결된 action-platform stage가 되도록 재저작한다.

동시에 주 경로의 모든 적을 전역 합산해 출구를 잠그는 current rule을
제거하고, 종착점 도달과 명시적 local objective만 stage completion을
결정하게 한다. 조립된 room graph는 탐색 상태와 결합해 우상단 minimap으로
표시하며, 미방문 공간은 어둡고 현재 위치와 발견된 주요 지점은 명확하게
읽혀야 한다.

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

### 2026-07-16 visual-direction clarification

owner review에서 세 stage를 한 장에 축약한 비교 이미지는 실제 설계도로 쓰기엔
너무 단순하다고 판정했다. 목표는 각 stage가 독립된 상세 side-cutaway map으로
읽히고, 서로 연결된 방·shaft·우회로·shortcut·landmark가 전체 실루엣 안에서
기억되는 방향이다. 참고점은 *Hollow Knight*가 보여주는 촘촘한 공간 접힘과
장소 기억성이지만, 기존 map silhouette, room, icon, character, UI를 복제하지
않는다.

생성된 세 이미지는 이 방향을 확인한 visual study이지 collision 좌표나 확정
room count가 아니다. 이미지의 20여 개 numbered chamber를 그대로 구현하면
PRD의 compact vertical slice, normal-room 20–60초, stage별 6–10분 목표와
충돌할 가능성이 높다. 첫 implementation pass는 current authored template와
8/7/9 required-room baseline을 유지하되, 각 template 안을 2–4개의 명확한
gameplay beat, 여러 elevation band, side pocket, sightline, shortcut으로
세분화한다. 그 결과로도 목표 밀도와 플레이타임을 만들 수 없다는 측정
evidence가 생긴 뒤에만 room-count 변경을 별도 승인 대상으로 올린다.

### 2026-07-16 owner-play validity amendment

같은 owner가 current production path를 직접 플레이한 결과, 이전 세션의
구조적 방향만으로는 부족하고 다음 실행 조건이 추가로 확인됐다.

- required route에 반복되는 높은 단차와 벽 인접 착지가 많아, 자동
  reachability를 통과해도 이동이 불필요하게 어렵다.
- rope는 상승보다 하강이 불안정하다. current climb runtime은 one-way
  platform 하강, rope 중심 정렬, 상단 mount/dismount를 계약으로 다루지
  않으며, geometry validator는 metadata만으로 양방향 연결을 인정한다.
- basic ranged-enemy projectile가 terrain을 통과하므로 authored cover와
  lower/upper route의 tactical 의미가 무너진다.
- leaper는 encounter 안에서 landing destination을 선택하지 않고 target
  x와 한 fixed leap profile에 의존한다. 일부 mobile enemy도 wall/ledge와
  관계없이 authored patrol bound만 따르므로 멈추거나 끼일 수 있다.
- ordinary enemy의 full-range aim line 또는 synthetic jump arc는 합리적인
  movement와 local startup tell을 대신할 수 없다.
- current movement, shooter, leaper, guard, stage-composition validator가
  모두 통과해도 위 실제 플레이 문제는 검출되지 않는다.

이 amendment는 map redesign이 collision scene만 바꾸고 끝나는 것을 막는다.
map이 cover, rope, enemy lane, landing destination, camera commitment를
의도한다면 그 의도를 실제 runtime behavior와 continuous input path가
증명해야 한다.

다만 contextual attack input, shield-system redesign, consumable capacity,
Forge/Merchant modal information architecture는 map plan에 흡수하지 않는다.
그 항목은 별도 gameplay/input/economy/UI follow-up이 소유한다.

### 2026-07-16 progression and minimap amendment

current runtime audit에서 다음 원인이 확인됐다.

- `ProductionStageHost.gd`는 `required_route` room의 모든 enemy를
  `_required_enemies`로 합산하고, 그 수가 0이 될 때만 terminal
  `ExitPortal`을 연다.
- terminal scene의 `objective_requirements` metadata는 실제 unlock policy를
  선택하지 않는다. Ruin의 `final_encounter_clear`, Flooded의
  `required_encounters_clear`, Sanctum의 `broken_sanctum_clear`가 서로
  다른 문자열이어도 runtime 결과는 동일한 global kill gate다.
- `ProductionHUD.gd`도 같은 aggregate를 받아 stage 전체에 “Defeat N
  remaining”을 표시한다.
- 반면 `StagePlan`, `StageAssemblyResult`, `RoomTemplateHost`에는 minimap에
  필요한 room ID, connection, assembled position, bounds가 이미 있다.
  physics collision을 다시 훑거나 별도 수작업 node graph를 만들 필요가 없다.
- current HUD는 top-left health, top-center objective/boss, bottom combat,
  center context lane을 예약하고 있어 top-right가 normal-stage minimap의
  자연스러운 owner다.

외부 pattern도 같은 결론을 지지한다.

- Nintendo의 공식 *Metroid Dread* 안내는 이동한 위치를 map에 기록하고,
  top-right minimap, terrain outline, marker, door/station icon을 navigation
  도구로 사용한다. 같은 공식 newcomer guide는 약한 적을 모두 처치할
  필요 없이 전략적으로 피할 수 있다고 명시한다.
  ([Planet ZDR](https://metroid.nintendo.com/dread/ca/planet-zdr/),
  [newcomer guide](https://www.nintendo.com/en-gb/News/2021/September/Metroid-Dread-Report-Vol-9-Handy-tips-for-newcomers-2047809.html))
- Ubisoft의 공식 *Prince of Persia: The Lost Crown* accessibility guidance는
  자유 탐색의 즐거움과 길을 잃는 좌절을 분리하고, objective와
  available/blocked path를 선택적으로 보여 주는 navigation aid를 설명한다.
  ([Accessibility Spotlight](https://www.ubisoft.com/en-gb/game/prince-of-persia/the-lost-crown/news-updates/5nGZiBSFtcEzFd93QlTotS/prince-of-persia-the-lost-crown-accessibility-spotlight))

따라서 이 amendment는 “combat을 없앤다”가 아니라 다음 의미 경계를
고정한다.

- `required_route`는 main traversal topology다. mandatory kill이라는 뜻이
  아니다.
- `encounter clear`는 room-local combat fact다. card trigger, local reward,
  명시적 arena lock에는 사용할 수 있지만 stage 전체 출구에 암묵적으로
  전파하지 않는다.
- `stage exit eligible`은 terminal room의 authored policy가 결정한다.
- `stage clear`는 eligible exit에서 player가 상호작용했을 때만 발생한다.
- minimap discovery는 player knowledge다. combat/reward rollback과 같은
  state로 취급하지 않는다.

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
7. implementation 전에 stage별 독립 construction blueprint가 존재하며,
   room ID, 연결, height waveform, combat/recovery beat, reward, shortcut,
   camera commitment가 실제 source owner와 대응한다.
8. required traversal은 theoretical movement maximum을 반복해서 요구하지
   않고, routine transition과 intentional challenge transition이 구별된다.
9. rope, basic projectile cover, leaper landing, mobile-enemy patrol이 authored
   terrain intention과 실제 runtime에서 일치한다.
10. ordinary enemy tell은 startup과 위험 destination을 읽게 하되, full
    trajectory overlay를 합리적인 behavior의 대체물로 사용하지 않는다.
11. non-terminal enemy가 살아 있어도 player가 terminal policy를 충족하면
    stage를 끝낼 수 있고, global enemy tally가 exit 또는 HUD objective를
    소유하지 않는다.
12. normal stage의 top-right minimap이 assembled room layout, 현재 player
    위치, 미방문/방문/current room, start, exit, checkpoint, 발견된
    reward, gate/shortcut 상태를 표시한다.
13. minimap knowledge는 fall recovery와 같은-stage death retry에서
    유지되고, 새 run 또는 다른 stage 시작에서 올바르게 초기화된다.

## Scope

### In scope

- `StageCompositionMetrics.gd`와 `validate_stage_composition.gd` 진단 강화
- `CuratedStagePlanBuilder.gd`의 fixed topology와 connection 수정
- active authored room scene의 collision/platform/anchor/camera composition
- room resource socket, recovery, enemy/hazard/reward anchor 갱신
- 기존 enemy variant와 hazard의 재배치
- required-transition comfort diagnostic과 repeated near-limit sequence 제거
- rope ascent/descent, one-way crossing, mount/dismount runtime contract 보강
- existing basic projectile와 mobile enemy의 bounded terrain-interaction repair
- normal-stage camera framing 또는 geometry-with-default-camera proof
- fixed-stage capture target과 continuous traversal evidence 추가
- stage별 construction blueprint와 route/height/encounter overlay 작성
- global required-enemy gate를 authored terminal policy로 교체
- stage objective snapshot에서 global enemy count 제거
- assembled room graph 기반 exploration state와 fog-of-war minimap
- normal-stage HUD top-right minimap component, responsive layout, marker state
- same-stage retry에서 discovery knowledge 보존
- 관련 validator와 product-flow regression

### Non-scope

- minimap 외의 broad UI/HUD/modal/typography 변경
- gamepad 또는 다른 platform 입력
- player movement value 또는 새 movement skill 변경
- 새 enemy archetype, boss pattern, card, equipment, merchant item 추가
- moving platform처럼 현재 미구현인 gimmick의 신규 구현
- final world-art asset generation 또는 panorama 수량 결정
- procedural/random stage production 복귀
- death checkpoint 또는 save-point policy 변경
- normal stage 안에 Forge, merchant, safe-intermission NPC 재도입
- contextual melee/ranged input 분리 또는 key binding 재설계
- shield timing/resource redesign과 potion charge/economy 변경
- Forge/Merchant 화면의 정보 구조 또는 visual redesign
- full-screen map, zoom/pan input, player-placed marker, map station, fast travel
- ordinary enemy, projectile, 개별 hazard의 live minimap tracking
- 숨은 reward의 사전 공개 또는 모든 optional POI의 처음부터 표시
- minimap을 위해 physics collision을 runtime rasterize하거나 별도
  pathfinding/navigation framework를 도입하는 일

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
| movement envelope and comfort diagnostics | `scripts/player/MovementMetrics.gd`, `scripts/generation/StageGeometryValidator.gd`, `StageCompositionMetrics.gd` |
| rope runtime contract | `scripts/player/PlayerController.gd`, `scripts/stages/Climbable.gd` |
| projectile/cover interaction | `scripts/enemies/EnemyProjectile.gd` and the shared collision contract |
| terrain-aware existing enemy movement | matching `scripts/enemies/LeaperEnemy.gd`, walker/charger/guard owners only where a reproduced map-validity failure requires it |
| normal-stage camera behavior | `scripts/stages/production/ProductionStageHost.gd` and `PlayerController.gd` camera ownership |
| terminal completion policy | `scripts/stages/production/ProductionStageHost.gd`, a typed `ExitPortal` unlock policy, and the three terminal room scenes |
| room-local encounter facts | existing room encounter indexes and signals; they must not own global exit eligibility |
| exploration/discovery state | new responsibility-shaped owner under `scripts/stages/navigation/`, hosted by `ProductionStageHost.gd` |
| map topology snapshot | read-only projection of `StagePlan`, `StageAssemblyResult`, `RoomTemplateData.bounds`, sockets, and authored objective/reward anchors |
| retry knowledge boundary | `scripts/autoload/RunState.gd` and stage-attempt restore tests |
| minimap presentation | new component under `scripts/ui/production/components/`, mounted by `ProductionHUD.gd` / `ProductionHUD.tscn` |
| minimap layout and rendered proof | `scripts/ui/validation/ValidateGameplayHUD.gd`, `CaptureGameplayHUD.gd`, and fixed-stage captures |
| runtime validity fixtures | `tools/validate_player_movement_runtime.gd`, `validate_shooter_runtime.gd`, `validate_flooded_enemy_runtime.gd` |
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
- visual study의 numbered chamber는 확정 room count가 아니다. current room
  template 하나가 여러 gameplay beat와 sub-chamber를 소유할 수 있다.
- current enemy floors 8/10/12와 required-room counts 8/7/9는 하한으로
  보존한다.
- current movement values는 그대로 두되, 그 theoretical maximum을 routine
  required route의 반복 난도로 사용하는 것은 허용하지 않는다.
- basic ranged-enemy projectile는 authored solid terrain과 declared cover를
  관통하지 않는다. one-way surface의 projectile policy는 Milestone A에서
  명시하고 모든 room에 일관되게 적용한다.
- rope는 실제 input으로 아래→위와 위→아래 이동, one-way top crossing,
  상·하단 dismount를 모두 증명해야 양방향 edge로 인정한다.
- leaper와 mobile patrol enemy의 수정은 existing archetype가 authored
  terrain intention을 수행하는 데 필요한 최소 behavior에 한정한다.
- optional reward resolution, stable IDs, deterministic seed behavior를
  유지한다.
- fall recovery anchor는 local traversal recovery이며 death respawn이 아니다.
- `required_route`는 main-route classification으로 유지하며 exit unlock의
  kill requirement로 해석하지 않는다.
- Ruin과 Sanctum은 terminal room의 명시적 encounter/objective만 exit를
  잠글 수 있다. Flooded는 exit shelter 도달 자체가 terminal objective다.
- local encounter lock이 필요한 경우 그 room의 적만 소유하고, 한번 열린
  route를 다시 잠그지 않으며, optional/non-terminal enemy는 stage exit를
  막지 않는다.
- minimap은 room bounds와 connection을 uniform scale로 투영한다. player
  marker는 같은 transform으로 world position을 변환한다.
- approved assembled room silhouette는 stage 시작부터 어둡게 보이고,
  방문한 room은 밝아진다. optional reward marker와 세부 POI는 해당 room
  또는 branch를 발견하기 전에는 보이지 않는다.
- exit marker는 navigation을 위해 처음부터 보인다. locked/ready 상태는
  색뿐 아니라 icon shape 또는 badge로 구분한다.
- normal-stage minimap은 player, current room, start, exit, active checkpoint,
  discovered unclaimed reward, discovered gate/shortcut, current terminal
  objective만 표시한다. ordinary enemy와 개별 hazard는 표시하지 않는다.
- discovery는 같은 run의 같은 stage retry에서 유지하고 새 run/stage에서
  reset한다. fall recovery는 discovery를 바꾸지 않는다.
- first pass는 항상 보이는 minimap만 구현한다. 새 map input action이나
  full-screen map은 추가하지 않는다.
- minimap room geometry는 runtime vector drawing과 existing authored data를
  사용한다. room collision을 복제한 raster asset은 만들지 않는다.
- UI overhaul dirty work와 master integration plan은 minimap 외에는 이
  작업이 소유하지 않는다.
- Web export template가 준비되지 않은 동안 desktop production capture를
  strongest substitute로 쓰되, release acceptance는 served Web 확인 전
  닫지 않는다.

## Current-State / Target Delta

| Concern | As-is | To-be | Accept | Guard |
| --- | --- | --- | --- | --- |
| Stage drawing | 세 stage를 비교하는 저밀도 concept와 개별 room still이 분리되어 있다. | stage별 한 장의 construction blueprint가 current room ID와 runtime graph를 설명한다. | blueprint의 모든 critical/optional connection이 `CuratedStagePlanBuilder.gd` target graph와 1:1 대조된다. | concept art의 임의 room이나 route를 source에 몰래 추가하지 않는다. |
| Macro topology | required linear chain에 optional same-hub return이 붙는다. | 여러 고도에서 갈라진 route가 앞으로 재합류하고, later shortcut이 earlier landmark를 다시 연결한다. | graph diagnostic과 실제 continuous traversal이 branch, rejoin, shortcut을 모두 증명한다. | hidden teleport, unreachable socket, reward duplication이 없다. |
| Room density | 넓은 평지, 얇은 floating ledge, 큰 empty void가 action을 분리한다. | 각 room은 2–4개의 읽을 수 있는 beat와 supported mass, preview, commitment, consequence, recovery를 갖는다. | debug label 없이 first-time player가 다음 목표와 선택을 설명한다. | 장식 platform, blind drop, 8초 이상 decision vacuum을 늘리지 않는다. |
| Traversal comfort | validator가 가능한 최대 gap/ledge만 확인해 near-limit jump가 연속되어도 통과한다. | routine transition, challenge transition, optional mastery line을 구분하고 required route에 입력 여유를 남긴다. | transition difficulty ratio와 연속 near-limit 구간을 진단하고, continuous clear에서 반복 벽 충돌·edge miss가 없다. | movement stat을 올리거나 collision을 축소해 geometry 문제를 숨기지 않는다. |
| Rope transfer | metadata graph는 rope를 양방향 edge로 보지만 runtime descent가 one-way top에 막힐 수 있다. | rope 중심 정렬, 상·하단 mount/dismount, one-way crossing이 같은 input language로 동작한다. | 실제 player fixture와 Flooded continuous run이 양방향 이동을 증명한다. | teleport, hidden collision toggle, stage별 예외로 통과시키지 않는다. |
| Projectile cover | enemy projectile가 player mask만 사용해 terrain과 cover를 통과한다. | basic ranged projectile가 solid terrain과 declared cover에 막히고 shooter placement가 실제 cover decision을 만든다. | cover 뒤 player가 피해를 받지 않고 projectile가 terrain contact에서 종료된다. | 적 사거리·탄속을 낮추거나 warning line만 짧게 해 문제를 숨기지 않는다. |
| Terrain-aware enemy movement | leaper는 fixed target-x leap를 반복하고 일부 patrol enemy는 wall/ledge를 인지하지 않는다. | leaper는 encounter 안의 valid landing destination을 선택하고 mobile enemy는 authored lane에서 반복 행동 가능하다. | 여러 leap 또는 patrol cycle 뒤에도 enemy가 stuck/idle lock에 빠지지 않고 intended pressure를 유지한다. | 범용 pathfinding이나 새 enemy archetype으로 scope를 확장하지 않는다. |
| Enemy tell | full-range line과 synthetic arc가 behavior readability의 주된 근거다. | ordinary enemy는 local startup, facing/pose, destination 또는 impact cue로 읽히고 full trajectory는 꼭 필요한 경우만 남는다. | production capture에서 debug-like path 없이도 위험과 대응 공간을 설명한다. | boss의 required startup warning이나 color-independent danger cue를 제거하지 않는다. |
| Stage completion | main-route room의 모든 enemy가 하나의 global remaining count가 되어 exit를 잠근다. | terminal authored policy만 exit eligibility를 결정하고 non-terminal combat은 회피 가능한 risk/reward가 된다. | prior main-route enemy를 하나 이상 살려 둔 채 Ruin/Sanctum terminal objective 또는 Flooded arrival로 stage clear flow에 진입한다. | boss defeat와 명시적 local arena objective는 우회시키지 않는다. |
| Objective copy | HUD가 stage 전체 enemy count를 immediate objective로 표시한다. | 기본 objective는 exit navigation이며, terminal local lock이 active일 때만 그 local requirement를 표시한다. | normal-stage HUD에 global `Defeat N remaining`이 없고 lock/ready transition이 실제 exit policy와 일치한다. | hidden requirement나 stale count를 다른 label로 바꾸어 남기지 않는다. |
| Minimap topology | assembled room positions와 bounds가 runtime에 있으나 player-facing navigation surface가 없다. | StagePlan/Assembly를 하나의 copy-safe map snapshot으로 투영한다. | snapshot room/edge count와 plan이 일치하고 모든 projected bounds가 minimap content rect 안에 들어온다. | physics tree scan, duplicated hand-authored node graph, per-stage hard-coded screen coordinates를 사용하지 않는다. |
| Exploration fog | 방문 여부와 current room을 추적하지 않는다. | unvisited room은 dark silhouette, visited room은 readable fill, current room/player는 shape+accent로 구분한다. | 실제 room crossing과 같은-stage retry에서 state transition이 결정론적으로 재현된다. | color-only state, boundary flicker, retry knowledge loss가 없다. |
| Map POI | exit prompt 외에 stage navigation marker contract가 없다. | start, exit, active checkpoint, discovered reward, gate/shortcut, terminal objective만 제한적으로 표시한다. | undiscovered reward와 ordinary enemy가 노출되지 않고 claimed/open state가 stale하지 않다. | minimap이 combat radar나 collectible spoiler가 되지 않는다. |
| Vertical combat | enemy count와 y-span이 주된 자동 증거다. | threat lane, cover, escape/re-engage route가 높이에 따라 달라진다. | combat-room intention 문장과 real-damage playtest가 같은 결론을 낸다. | enemy 수만 늘려 metric을 통과하지 않는다. |
| Camera commitments | normal stage는 full-world limit와 player smoothing만 사용하고 authored `camera_id` marker는 runtime owner가 없다. | default camera로 읽히는 geometry를 우선하고, 불가능한 commitment에만 최소 camera focus/lookahead owner를 둔다. | irreversible jump/drop 전에 landing, threat, safe cue가 실제 continuous frame에 들어온다. | teleported still이나 editor viewport만으로 camera acceptance를 닫지 않는다. |
| Scale | 이미지상 많은 chamber가 넓은 metroidvania scope로 오해될 수 있다. | compact 6–10분 stage 안에서 공간을 접고 기억 가능한 landmark를 반복 노출한다. | stage clear timing과 room-duration sample이 PRD 범위에 들어온다. | 새 biome, ability gate, 장거리 backtracking campaign으로 확장하지 않는다. |

## Construction Blueprint Contract

Milestone 0에서 세 stage 각각에 다음 layer가 분리되어야 한다. 최종 visual은
`docs/design/visuals/`에 stage별 파일로 두고, 구조와 room-ID 대응표는
`docs/design/STAGE_MAP_BLUEPRINTS.md`가 소유한다.

| Layer | 반드시 보여줄 내용 | 구현 연결 |
| --- | --- | --- |
| Collision silhouette | filled terrain mass, platform, shaft, drop, climb, room boundary | `scenes/rooms/**.tscn` |
| Route graph | start, exit, critical route, optional route, forward rejoin, one-way shortcut | `CuratedStagePlanBuilder.gd`, room socket resources |
| Height waveform | elevation band, peak, descent, reversal, recovery | `StageCompositionMetrics.gd` diagnostics |
| Encounter layer | safe entry, combat zone, enemy lane, cover, escape, reward | room anchors and allocated content |
| Camera/landmark layer | pre-commit preview, landing cue, memorable landmark, revisited vista | authored camera bounds and rendered evidence |
| Rhythm layer | teach, transform, test, release and expected 20–60초 room duration | room intention matrix and continuous timing note |
| Minimap layer | room envelope, connection, unvisited/visited/current state, start/exit, checkpoint, discovered POI, gate/shortcut state | StagePlan/Assembly snapshot and HUD minimap renderer |

Blueprint acceptance is a design gate, not decorative paperwork. A future executor
must be able to name the scene/resource changed for every marked room, connection,
reward, and shortcut. If the drawing cannot be reconciled with current IDs and
movement limits, update the drawing before code.

## Proposed Design

### Shared macro rule

모든 stage는 다음 구조를 갖는다.

> safe preview → signature verb teach → first pressure peak → route/height
> transform → combat or hazard test → release → combined final test

stage마다 동일한 순서의 방을 복제하지 않고, signature geometry와
height profile을 다르게 한다.

### Completion policy: reach and resolve, not global extermination

Canonical terms:

| Term | Meaning |
| --- | --- |
| main route | start에서 terminal까지 이어지는 required traversal graph |
| local encounter clear | 한 room에 계획된 encounter가 끝났다는 combat fact |
| terminal objective | exit eligibility를 위해 terminal room이 명시적으로 요구하는 arrival, encounter, switch, or boss fact |
| exit eligible | `ExitPortal` interaction을 허용할 수 있는 상태 |
| stage clear | eligible exit에서 player interaction이 commit된 뒤 발생하는 run-flow fact |

`ProductionStageHost`는 terminal scene의 typed policy를 읽어 exit eligibility를
계산한다. free-form `objective_requirements` string을 계속 늘리지 않는다.
첫 implementation은 다음 세 mode만 허용한다.

| Policy | Behavior | Current stage use |
| --- | --- | --- |
| `arrival` | exit에 도달하면 추가 kill requirement 없이 상호작용할 수 있다. | Flooded Works |
| `terminal_encounter` | terminal room에 실제로 배치된 encounter만 clear하면 열린다. | Ruin Approach, Broken Sanctum |
| `explicit_objective` | authored switch/gate/objective fact를 요구한다. | reserved; current stage가 실제로 필요할 때만 사용 |

Stage-specific target:

- Ruin: `lr_exit_ascent`의 terminal encounter만 exit를 잠근다. 이전
  `lr_patrol_gallery`, `lr_shooter_overlook`, `lr_charge_lane` enemy가
  살아 있어도 상관없다.
- Flooded: `fw_exit_shelter`에 도달하면 exit가 ready다. rope, poison,
  leaper, pump encounter의 global clear는 요구하지 않는다.
- Sanctum: required traversal에서 gate/switch를 실제로 통과해야 하는 것은
  geometry/objective contract로 남지만, exit unlock은 `bs_exit_ascent`의
  terminal encounter만 소유한다. 이전 crossfire enemy의 전멸은 요구하지
  않는다.
- Slime Court는 이 policy를 쓰지 않는다. boss defeat가 기존 stage
  completion owner다.

Invariant:

- main-route classification, enemy reward settlement, room-clear card trigger는
  유지하되 exit eligibility 계산에서 분리한다.
- local arena lock은 명시적으로 authored된 room에만 존재하고 그 room을
  벗어난 enemy나 optional enemy를 세지 않는다.
- 열린 local route와 terminal exit는 enemy respawn 또는 stale signal로
  다시 잠기지 않는다.
- HUD의 normal-stage default objective는 `Find the exit`이고, player가
  locked terminal room에 있을 때만 local requirement와 local remaining
  count를 보여 준다. ready가 되면 `Enter the gate`로 바뀐다.
- non-terminal enemy를 회피하면 그 enemy reward/XP를 얻지 못한다. stage
  clear reward는 정상 지급되므로 combat은 risk/reward choice로 남는다.

### Runtime minimap and exploration state

Data flow:

> `StagePlan` + `StageAssemblyResult` + authored anchors
> → stage-owned exploration state
> → copy-safe map snapshot on `SignalBus`
> → `ProductionHUD` top-right minimap renderer

The stage-owned state is the only owner of `current_room_id`, visited room IDs,
and discovered POI state. HUD는 active stage tree를 직접 순회하거나 gameplay
state를 수정하지 않는다.

Minimum snapshot:

- stage ID and world bounds;
- room ID, role, assembled bounds, route requirement, discovery state;
- connection ID, route role, from/to room IDs, socket endpoints;
- player world position and current room ID;
- start, exit, active checkpoint, discovered reward, discovered gate/shortcut,
  and terminal-objective markers with resolved/locked state.

Room state:

| State | Presentation | Transition |
| --- | --- | --- |
| `unvisited` | dark filled silhouette plus low-contrast/dashed edge | initial state for every room not yet entered |
| `visited` | brighter fill and solid edge | first stable entry into room bounds |
| `current` | visited styling plus thicker accent edge and player marker | current stable containing room |

Room-boundary jitter를 막기 위해 current-room detection은 기존 room bounds를
공용 owner에서 한 번만 계산하고, socket boundary에는 이전 room 유지 또는
작은 hysteresis를 사용한다. exact margin은 runtime fixture에서 정하되
stage별 hard-coded exception은 두지 않는다.

Projection:

- `scale = min(content_width / world_width, content_height / world_height)`의
  uniform scale을 사용한다.
- world bounds의 origin을 빼고 같은 scale/offset을 room, connection,
  marker, player 모두에 적용한다.
- 남는 축은 center-letterbox한다. stage가 viewport보다 몇 배 넓거나
  높아도 crop, independent x/y stretch, camera-relative drift가 없다.
- first pass는 `RoomTemplateData.bounds`와 assembled connections를 coarse
  side-cutaway envelope로 사용한다. rendered evidence에서 rectangle만으로
  route가 오해되는 room이 확인될 때만 small authored map-cell schema를
  추가하며, physics collision을 runtime 복제하지 않는다.

Marker contract:

| Marker | Reveal/state rule |
| --- | --- |
| player | always visible inside the current room; distinct filled shape, not color alone |
| start | visible after stage begins |
| exit | visible from stage start; locked/ready badge follows terminal policy |
| active checkpoint | visible after activation; previous checkpoint becomes inactive or disappears |
| gate/shortcut | hidden until its room is visited; closed/open state uses shape plus line style |
| reward/cache/material node | hidden until its room is visited; unclaimed only, then resolved/dimmed |
| terminal objective | shown only while it is the active blocker |

Ordinary enemy, projectile, temporary hazard, every loose pickup, off-screen
damage source는 minimap marker가 아니다. minimap은 radar가 아니라 navigation
surface다.

Presentation:

- normal-stage only, anchored top-right.
- starting layout target is approximately 240×148 at 1280×720 and 190×118 at
  960×540 with 16 px outer margin; responsive validation may reduce these values
  but cannot overlap health, objective/boss, context lane, or combat dock.
- reuse `ProductionUIStyles.gd` surfaces and limited palette. unvisited/visited/
  current, locked/ready must differ by fill, edge, and icon shape rather than hue
  alone.
- room geometry is drawn as runtime vector primitives. existing semantic SVGs
  such as exit/cache may be reused; only missing player/checkpoint/gate glyphs
  receive small UI SVG assets.
- hidden during Arsenal Trial, Safe Intermission, and Slime Court unless a later
  explicit design requires it.

Persistence:

- entering a room records knowledge immediately after stable containment.
- fall recovery preserves visited rooms and POI discovery.
- same-stage death retry restores mechanical stage-entry state but merges forward
  the defeated attempt's discovery knowledge.
- a new run or a different stage starts with a fresh discovery set.
- discovery is keyed by run, stage index, and approved plan/content signature so
  stale room IDs cannot leak across a changed map version.

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
| `lr_rise_steps` | Teach | 기본 jump/dash로 두 elevation band를 오르고 낮은 recovery shelf를 경험한다. | 실패가 death가 아닌 lower recovery로 이어지고 near-limit wall jump가 연속되지 않음 |
| `lr_patrol_gallery` | Transform | walker 때문에 upper/lower band를 바꾸게 한다. | 같은 floor에서 전부 처리할 수 없는 pressure |
| `lr_shooter_overlook` | First peak | upper exposure와 lower cover를 shooter line으로 구분한다. | entry safe zone과 shooter tell이 같은 frame이고 lower cover가 실제 projectile를 막음 |
| `lr_lower_upper_choice` | Route decision | 빠른 exposed line과 안전한 slower line의 비용을 먼저 보여준다. | route별 movement/risk 차이 2개 이상 |
| `lr_destructible_cache` | Optional loop | 짧은 challenge 끝 reward를 얻고 앞쪽으로 재합류한다. | reward를 challenge 중간에 banking하지 않음 |
| `lr_broken_bridge` | Release/transform | 이전 peak를 내려다보고 controlled descent 뒤 새 ascent를 시작한다. | Forge/NPC 없음, empty corridor가 아님 |
| `lr_charge_lane` | Combine | horizontal charge lane을 side ledge로 피하고 재진입한다. | escape ledge가 threat를 실제로 끊음 |
| `lr_exit_ascent` | Test | 이미 배운 elevation transfer와 enemy priority를 짧게 결합한다. | 신규 필수 mechanic 없음, exit 전 recovery |

### Flooded Works

| Room | Rhythm role | Target intention | Required proof |
| --- | --- | --- | --- |
| `fw_flooded_entry` | Preview | 아래 basin과 최종 pump landmark를 먼저 암시한다. | safe entry에서 하강 destination이 보임 |
| `fw_rope_shaft` | Teach | vertical transfer와 높이별 enemy response를 안전하게 소개한다. | 실제 input으로 rope 상·하행, one-way top crossing, 양 끝 dismount가 자연스럽게 동작 |
| `fw_poison_timing` | Transform | safe pad 사이 timing 이동을 가르치되 기다릴 공간을 보장한다. | poison tell 전에 safe destination 표시 |
| `fw_leaper_basin` | First peak | controlled drop 뒤 leaper center pressure에서 두 exit를 판단한다. | basin entry가 blind drop이 아니고 leaper가 둘 이상의 valid landing destination 사이에서 반복 이동 |
| `fw_lower_upper_choice` | Route decision | dry upper precision과 wet lower hazard management를 구분한다. | route별 verb/risk 차이와 reward clue |
| `fw_sunken_cache` | Optional loop | lower risk를 연장해 reward를 얻고 앞쪽으로 빠져나간다. | same-hub backtrack 제거 |
| `fw_pump_gallery` | Combine/test | shooter/leaper/charger pressure와 known timing을 상승 중 결합한다. | entry safe zone, projectile-blocking cover, 중간 recovery band, 반복 cycle 뒤 stuck enemy 없음 |
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
| `bs_fractured_gallery` | Combine | fractured platforms에서 enemy priority와 elevation change를 결합한다. | enemy가 빈 곳 채우기가 아닌 terrain role을 갖고 wall/ledge에서 idle lock에 빠지지 않음 |
| `bs_recovery_cloister` | Release/clue | 안전한 회복과 later upper branch clue를 제공한다. | safe zone이 crossfire reach 밖 |
| `bs_reliquary_cache` | Late optional | 숙련된 upper line과 reward 뒤 crossfire 앞쪽으로 재합류한다. | early crypt와 다른 verb/risk |
| `bs_sentry_crossfire` | Tactical test | cover band 사이를 이동해 sentry line을 끊고 flank한다. | unavoidable entry hit 없음, 두 threat lane 식별, declared cover가 projectile를 실제로 차단 |
| `bs_exit_ascent` | Final test | gate, flank, elevation transfer를 짧게 결합한다. | 새 요소 없음, boss/next-flow 전 release |

## Tasks

- [x] Milestone 0에서 visual study를 current room graph와 movement envelope에
  맞는 stage별 construction blueprint로 번역하고 owner review를 받는다.
- [x] Milestone A에서 completion policy, minimap state, directionality,
  traversal comfort, rope, projectile cover, terrain-aware enemy behavior를
  먼저 red/green 검증한다.
- [x] Milestone B에서 Ruin을 pilot stage로 재저작하고 continuous play로
  guideline을 증명한다.
- [ ] Milestone C에서 Flooded의 basin descent와 pump ascent를 재저작한다.
- [ ] Milestone D에서 Sanctum branch를 분산하고 gate/shortcut loop를 만든다.
- [ ] Milestone E에서 세 stage의 encounter, camera, pacing을 함께 review한다.
- [ ] Milestone F에서 자동·rendered·continuous·Web production evidence를
  합쳐 release acceptance를 닫는다.

## Milestones

### Milestone 0 — Design translation and scope lock

Goal: visual direction을 implementation 가능한 room graph와 construction
blueprint로 바꾸고, 이미지의 분위기와 실제 production scope를 분리한다.

Tasks:

- [x] `docs/design/STAGE_MAP_BLUEPRINTS.md`에 Ruin, Flooded, Sanctum의 current
  node/edge table과 target node/edge table을 나란히 기록한다.
- [x] `docs/design/visuals/`에 stage별 독립 map blueprint를 한 장씩 만든다.
  비교용 composite 한 장으로 대체하지 않는다.
- [x] 모든 blueprint에 current room ID 경계, start/exit, critical route,
  optional route, forward rejoin, shortcut, safe/combat/reward zone을 표시한다.
- [x] 각 blueprint에 terminal unlock policy, terminal local objective,
  minimap room envelope, marker reveal point를 별도 layer로 표시한다.
- [x] 각 required room을 2–4개의 gameplay beat로 나누되 이것을 새 runtime
  room 또는 새 stable ID로 자동 승격하지 않는다.
- [x] 각 stage의 height waveform과 teach → transform → test → release 순서를
  blueprint 아래에 기록한다.
- [x] stage별 landmark 3개 이상을 정하고, later route에서 earlier landmark를
  다른 높이 또는 방향으로 다시 보게 할 위치를 표시한다.
- [x] current `MovementMetrics.gd` envelope로 critical jump/drop/climb을
  검토하고, 불확실한 gap에는 수치를 적지 말고 blockout 검증 대상으로 남긴다.
- [x] room당 20–60초, Ruin 6–8분, Flooded 7–9분, Sanctum 8–10분의 timing
  budget을 작성한다.
- [x] existing template로 목표를 만족할 수 없는 후보를 별도 목록화하되,
  새 room 제작이나 active-room-count 증가는 이 milestone에서 승인하지 않는다.
- [x] owner review에서 세 blueprint의 구조적 방향과 Ruin pilot 범위를
  확인한다.

Acceptance:

- [x] 세 stage가 각각 독립 이미지와 source-linked room graph를 가진다.
- [x] first-time reviewer가 각 stage의 start, exit, main route, optional route,
  forward rejoin, shortcut, combat peak, recovery를 설명할 수 있다.
- [x] reviewer가 stage별 exit unlock requirement와 minimap의 unvisited,
  visited, current, locked/ready state를 source owner와 연결해 설명할 수 있다.
- [x] Ruin/Flooded/Sanctum의 silhouette와 height waveform이 서로 다르다.
- [x] blueprint의 모든 확정 항목이 current source owner에 대응하고, visual
  study의 임의 요소가 requirement로 승격되지 않았다.
- [x] estimated timing이 PRD 범위에 있으며, room-count 확대는 evidence와
  owner approval 없이는 다음 milestone에 들어가지 않는다.

### Milestone A — Progression, navigation, diagnostic, and shared terrain contract

Goal: 현재 결과를 보존하면서 “수치상 가능함”과 “실제로 편안하고 지형과
상호작용함”을 분리해 검출하고, room redesign이 의존할 공용 runtime
contract를 먼저 고정한다. global extermination gate와 missing minimap도
geometry pass 전에 해결해 이후 stage review가 target flow를 사용하게 한다.

Tasks:

- [x] current validator JSON과 fixed-stage captures를 dated evidence 위치에
  보존하거나 재생성 명령과 hash를 기록한다.
- [x] current critical graph를 stage별 node/edge table로 snapshot한다.
- [x] current exit fixtures가 main-route enemy를 모두 죽여야 unlock되는 것을
  red evidence로 보존하고, `required_route`와 mandatory combat의 의미를
  분리한다.
- [x] terminal room에 typed unlock policy를 추가하고 free-form
  `objective_requirements` metadata를 제거하거나 migration한다.
- [x] `ProductionStageHost.gd`의 exit eligibility가 global
  `_required_enemies`/`get_remaining_enemy_count()`에 의존하지 않게 한다.
- [x] Ruin/Sanctum은 terminal-room encounter index만, Flooded는 arrival
  policy만 사용하도록 stage-specific fixture를 작성한다.
- [x] prior main-route enemy를 살려 둔 채 exit가 열리고 stage-clear reward
  flow가 한 번만 commit되는 regression을 추가한다.
- [x] room-local clear signal, Second Wind card trigger, NPC/reward unlock이
  global exit gate 제거 뒤에도 유지되는지 검증한다.
- [x] normal-stage objective snapshot을 `navigate_to_exit`,
  `terminal_objective`, `exit_ready` state로 바꾸고 global enemy count copy를
  제거한다.
- [x] `StagePlan`, `StageAssemblyResult`, room hosts에서 room bounds,
  connections, start/exit, objective/reward anchors를 읽는 copy-safe map
  snapshot contract를 만든다.
- [x] responsibility-shaped exploration-state owner를
  `scripts/stages/navigation/` 아래에 추가하고 current/visited/discovered
  state를 `ProductionStageHost`가 host한다.
- [x] room crossing, socket-boundary hysteresis, player projection,
  checkpoint/reward/gate state update를 semantic change에만 publish하도록
  한다. HUD가 stage scene tree를 poll하지 않는다.
- [x] `SignalBus`에 stage-map snapshot channel을 추가하고 detached HUD가
  next-stage event를 받지 않도록 connect/disconnect lifecycle을 검증한다.
- [x] `ProductionHUD.tscn` top-right에 reusable minimap scene을 mount하고
  runtime vector renderer, fog state, marker contract, normal-stage visibility를
  구현한다.
- [x] `docs/design/PRODUCTION_UI_CONTRACT.md`의 Gameplay HUD contract에
  normal-stage top-right minimap, visibility, fog, marker boundary를 반영한다.
- [x] 960×540, 1280×720, 1920×1080에서 minimap이 health, objective/boss,
  context lane, combat dock과 겹치지 않는 layout fixture를 추가한다.
- [x] unvisited/visited/current, locked/ready, claimed/open 상태가 color 외
  shape/edge 차이로 읽히는 rendered fixture를 추가한다.
- [x] same-stage retry가 discovery를 보존하고 new run/stage가 reset하는
  RunState regression을 추가한다.
- [x] baseline player fixture에서 full/short/late jump input과 landing 오차를
  측정해 routine, challenge, optional mastery transition의 comfort band를
  근거와 함께 정한다.
- [x] critical transition을 movement maximum 대비 ratio로 보고하고,
  near-limit required transition이 연속되는 구간을 stage/room ID와 함께
  진단한다.
- [x] `StageCompositionMetrics.gd`에 direction reversal을 추가한다.
- [x] meaningful ascent와 descent transition count를 각각 추가한다.
- [x] optional branch origin, rejoin, divergence span, stage-position
  distribution diagnostic을 추가한다.
- [x] same-hub return과 forward rejoin을 구분한다.
- [x] current vertical range, enemy floor, elevation-change, empty-run gate를
  제거하거나 약화하지 않는다.
- [x] diagnostic을 단일 aggregate score로 만들지 않는다.
- [x] validator error가 stage ID, measured value, expected condition을
  구체적으로 말하게 한다.
- [x] current stage가 새 target에서 왜 실패하는지 red test로 먼저 확인한다.
- [x] `validate_player_movement_runtime.gd`에 rope 하단 진입, 상승, one-way
  top 통과, 위에서 하강 진입, 하단 dismount fixture를 추가하고 current
  descent failure를 red test로 재현한다.
- [x] rope runtime을 stage별 예외 없이 공용 owner에서 수정하고, rope
  중심 정렬과 collision-mask 복구가 dash/jump/respawn에서도 안전한지
  검증한다.
- [x] `validate_shooter_runtime.gd`에 solid cover fixture를 추가하고,
  projectile가 player까지 진행하는 current behavior를 red test로 남긴 뒤
  shared projectile terrain collision을 구현한다.
- [x] one-way platform의 projectile-blocking policy를 명시하고 room마다
  같은 collision rule을 사용한다.
- [x] `validate_flooded_enemy_runtime.gd`에 둘 이상의 landing surface를 가진
  leaper fixture를 추가하고, repeated cycle에서 destination 선택, 실제
  landing, alternate retry, no-stuck을 검증한다.
- [x] walker/charger/shield-guard 중 current authored geometry에서 stuck이
  재현되는 mobile archetype에만 wall/ledge response fixture와 최소 공용
  behavior repair를 추가한다.
- [x] normal enemy validator에서 full-range line 또는 synthetic arc 길이를
  product acceptance로 고정한 assertion을 제거하고, startup visibility,
  facing/destination cue, recovery readability로 교체한다.
- [x] normal-stage `camera_id` metadata를 실제로 소비할지 제거할지 결정한다.
  default camera로 commitment를 읽게 만드는 geometry를 우선하고, 부족한
  경우에만 최소 focus/lookahead owner를 구현한다.

Acceptance:

- [x] current three-stage metrics가 이전 값과 동일하게 재현된다.
- [x] global main-route kill tally 없이 stage별 typed terminal policy가
  exit eligibility를 결정한다.
- [x] Ruin/Sanctum은 이전 room enemy를 최소 하나 살려 두고 terminal
  encounter만 clear해 exit를 열 수 있고, Flooded는 required enemy를
  살려 둔 채 shelter exit를 사용할 수 있다.
- [x] room-local encounter clear, card/reward, enemy-drop settlement은
  regression 없이 유지된다.
- [x] HUD default objective에 global `Defeat N remaining`이 없고
  navigate → local terminal blocker → ready transition이 policy와 일치한다.
- [x] minimap snapshot의 room/connection 수와 bounds가 current StagePlan과
  assembly에 일치한다.
- [x] player가 두 room을 이동하면 start/previous/current state와 player
  marker가 올바르게 갱신되고 socket boundary에서 flicker하지 않는다.
- [x] exit는 처음부터 표시되고 undiscovered reward와 ordinary enemy는
  표시되지 않는다. checkpoint, reward claim, gate/shortcut state가 stale하지
  않다.
- [x] same-stage retry 뒤 visited room은 유지되고 new run/stage에서는
  초기 dark state로 돌아간다.
- [x] supported viewport와 en/ko locale에서 minimap이 기존 HUD region과
  겹치거나 잘리지 않는다.
- [x] current Ruin monotonic profile을 새 diagnostic이 검출한다.
- [x] current four same-hub optional return edge를 graph diagnostic이 검출한다.
- [x] comfort band가 임의 상수가 아니라 runtime input fixture와 owner review로
  기록되고, current near-limit chain 위치가 식별된다.
- [x] player fixture가 같은 rope를 실제 input으로 양방향 통과하고 collision
  mask가 모든 exit path에서 원복된다.
- [x] basic shooter projectile가 solid cover contact에서 종료되고 cover 뒤
  player에게 damage를 전달하지 않는다.
- [x] leaper가 둘 이상의 reachable destination을 사용해 여러 cycle을
  완료하며 하나의 고정 궤적 뒤 idle lock에 빠지지 않는다.
- [x] product validator가 full trajectory overlay의 존재나 길이를 필수
  계약으로 요구하지 않는다.
- [x] normal-stage camera acceptance의 runtime owner와 evidence method가
  하나로 정해지고 dead `camera_id` metadata가 남지 않는다.
- [x] reachability 또는 stable-ID validation이 회귀하지 않는다.

### Milestone B — Ruin blockout and room pass

Goal: 가장 단순한 stage에서 guideline을 먼저 증명한다.

Tasks:

- [x] target room matrix를 실제 scene node/anchor inventory와 대조한다.
- [x] stage macro sketch를 start/peak/descent/split/rejoin/exit로 확정한다.
- [x] `lr_rise_steps`와 `lr_patrol_gallery`의 ascent를 두 개의 distinct
  elevation band로 정리한다.
- [x] required route의 near-limit transition이 연속되지 않게 wall clearance,
  landing width, recovery floor를 조정한다.
- [x] `lr_shooter_overlook`에 safe entry, projectile-blocking lower cover,
  upper exposure를 만든다.
- [x] `lr_lower_upper_choice`의 두 route를 movement/risk 두 항목 이상에서
  다르게 만든다.
- [x] `lr_destructible_cache` return socket을 앞쪽 critical route로 옮긴다.
- [x] `lr_broken_bridge`에 controlled descent와 vista/release를 만들고
  Forge/NPC가 없음을 확인한다.
- [x] `lr_charge_lane`에 charge를 끊는 side ledge와 명확한 re-engage
  landing을 만든다.
- [x] `lr_exit_ascent`는 known element만 결합하고, 이 room의 encounter만
  terminal exit를 잠그도록 정리한다.
- [x] geometry 수정에 맞춰 recovery/enemy/reward/socket anchor를 갱신한다.
- [x] 모든 changed room의 content version을 contract에 맞게 갱신한다.
- [x] default camera 또는 approved focus behavior로 broken descent와
  re-engage landing이 commitment 전에 보이는지 확인한다.
- [x] shooter/walker/charger를 여러 behavior cycle 관찰해 wall 또는
  platform edge에서 pressure가 소멸하지 않는지 확인한다.
- [x] Ruin minimap에서 broken descent, upper/lower split, optional forward
  rejoin이 assembled vertical offset와 일치하고 current-room state가
  continuous run 중 올바르게 이동하는지 확인한다.

Acceptance:

- [x] range ≥ 720 px, enemies ≥ 8, required rooms = 8.
- [x] meaningful descent transition ≥ 2.
- [x] direction reversal ≥ 2.
- [x] optional branch가 forward-rejoin한다.
- [x] first-time viewer가 upper/lower route와 reward를 debug label 없이
  설명한다.
- [x] routine required transition에 입력 여유가 있고 repeated wall collision,
  edge miss, near-limit chain이 없다.
- [x] shooter cover가 실제 projectile를 막고 elevation change가 실제
  response를 바꾼다.
- [x] ordinary enemy의 full trajectory line 없이도 startup, threat lane,
  recovery를 설명할 수 있다.
- [x] patrol/shooter/charge enemy를 하나 이상 살려 둔 채 exit-ascent local
  encounter만 clear하고 stage를 끝낼 수 있다.
- [x] Ruin minimap의 unvisited silhouette, visited path, current player,
  exit lock/ready, discovered optional reward가 실제 route와 일치한다.
- [x] baseline continuous clear, fall recovery, stage retry가 통과한다.

### Milestone C — Flooded blockout and room pass

Goal: basin descent와 pump ascent가 stage의 장소성과 timing을 함께 표현한다.

Tasks:

- [ ] entry에서 basin 또는 pump landmark 중 하나를 먼저 보여준다.
- [ ] rope shaft를 vertical teach room으로 단순화한 뒤 pressure를 단계적으로
  추가한다.
- [ ] rope shaft의 모든 required rope를 위→아래, 아래→위로 직접 통과하고
  one-way top mount/dismount와 horizontal drift를 조정한다.
- [ ] poison timing room에 기다릴 safe pad와 다음 destination을 보장한다.
- [ ] leaper basin의 drop을 blind fall이 아닌 previewed commitment로 만들고,
  leaper가 encounter 안의 valid landing destination을 바꿔가며 이동하게 한다.
- [ ] lower/upper choice를 dry precision과 wet management로 구분한다.
- [ ] sunken cache를 same-hub return에서 forward rejoin으로 바꾼다.
- [ ] pump gallery를 known element의 vertical combine/test로 재구성한다.
- [ ] pump gallery의 declared cover가 shooter projectile를 막고, leaper와
  mobile patrol enemy가 여러 cycle 뒤에도 stuck되지 않는지 확인한다.
- [ ] exit shelter는 짧은 release로 유지하고 facility/NPC를 넣지 않으며,
  arrival policy로 global combat clear 없이 출구를 사용할 수 있게 한다.
- [ ] existing hazard reset과 room retry가 새 geometry에서 결정론적으로
  동작하는지 확인한다.
- [ ] Flooded minimap에서 basin descent, optional lower branch, pump ascent,
  shelter가 실제 assembled y-position과 일치하는지 확인한다.

Acceptance:

- [ ] range ≥ 720 px, enemies ≥ 10, required rooms = 7.
- [ ] meaningful descent sequence와 ascent sequence가 각각 3 transition 이상.
- [ ] optional branch가 forward-rejoin한다.
- [ ] upper/lower route가 movement, hazard, time, reward 중 2개 이상에서 다르다.
- [ ] poison/leaper/pump peak 사이에 safe recovery가 있다.
- [ ] 모든 required rope가 actual input으로 자연스럽게 양방향 통과된다.
- [ ] leaper가 하나의 synthetic arc 반복이 아니라 reachable destination
  이동으로 basin pressure를 유지한다.
- [ ] rope/leaper/pump enemy를 하나 이상 살려 둔 채 shelter에 도달해
  stage를 끝낼 수 있다.
- [ ] Flooded minimap이 current room, active checkpoint, discovered cache,
  shelter exit를 올바르게 표시한다.
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
- [ ] fractured gallery의 mobile enemy가 wall/ledge에서 멈추는 배치를
  제거하거나 공용 terrain response로 해결한다.
- [ ] recovery cloister를 실제 crossfire 밖 safe zone으로 만든다.
- [ ] sentry crossfire에 projectile-blocking cover band, transfer window,
  flank path를 만든다.
- [ ] exit ascent에서 새 mechanic을 추가하지 않고 known element를 결합하며,
  이 room의 encounter만 terminal exit를 잠그게 한다.
- [ ] Sanctum minimap에서 gate closed/open, opened shortcut, early/late branch,
  active checkpoint, exit lock/ready marker를 실제 state와 연결한다.

Acceptance:

- [ ] range ≥ 720 px, enemies ≥ 12, required rooms = 9.
- [ ] 두 branch origin이 critical route에서 최소 2 room 떨어져 있다.
- [ ] 두 branch 모두 forward-rejoin한다.
- [ ] gate shortcut이 시각적으로 열리고 실제 traversal을 줄인다.
- [ ] shield, fractured, sentry combat이 서로 다른 tactical verticality를 준다.
- [ ] sentry projectile가 declared cover를 관통하지 않고, ordinary enemy
  tell이 full-screen trajectory overlay 없이 읽힌다.
- [ ] recovery cloister 진입 시 unavoidable projectile 또는 body hit이 없다.
- [ ] shield/fractured/crossfire enemy를 하나 이상 살려 둔 채 exit-ascent
  local encounter만 clear하고 stage를 끝낼 수 있다.
- [ ] gate/shortcut와 두 optional branch의 minimap marker/reveal state가
  stale하거나 reward를 사전 공개하지 않는다.
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
- [ ] 실제 normal-stage camera owner가 authored focus/lookahead를 소비하거나,
  해당 marker를 제거하고 default camera로 읽히는 geometry를 증명한다.
- [ ] reward anchor가 optional line과 risk를 설명하는 위치인지 확인한다.
- [ ] 8초 이상 decision vacuum이 드문지 continuous timing note를 남긴다.
- [ ] stage별 repeated near-limit transition, failed wall approach, rope reversal,
  stuck enemy, projectile-through-cover 횟수를 continuous note에 기록한다.
- [ ] ordinary enemy의 full-range Line2D/arc를 전수 검토하고, 합리적인
  behavior와 local startup/destination cue로 대체 가능한 것은 제거한다.
- [ ] global enemy remaining count를 참조하는 exit, HUD, validator, terminal
  scene copy가 남아 있지 않은지 전수 검색한다.
- [ ] normal-stage minimap marker set을 전수 검토하고 enemy radar, hidden
  reward spoiler, stale checkpoint/gate state가 없는지 확인한다.
- [ ] minimap이 three-stage silhouette 차이를 보존하고 wide/tall map을
  independent axis stretch 없이 fit하는지 비교한다.
- [ ] Ruin/Flooded/Sanctum silhouette를 collision-only overview로 비교한다.
- [ ] normal stage 안에 Forge, merchant, intermission NPC가 없는지 validator와
  rendered run으로 확인한다.

Acceptance:

- [ ] 각 stage가 signature spatial verb와 teach/transform/test/release를
  한 문단으로 설명할 수 있다.
- [ ] 세 stage의 collision-only silhouette와 height waveform이 구별된다.
- [ ] 모든 combat room이 enemy-terrain relation을 통과한다.
- [ ] required traversal, rope, cover, mobile enemy가 shared terrain contract를
  동일하게 사용하며 room별 예외가 없다.
- [ ] 모든 critical camera commitment가 first-time clear에서 읽힌다.
- [ ] owner before/after run에서 route 기억, 불필요한 climb friction, enemy
  stuck, unfair projectile에 대한 개선이 확인된다.
- [ ] owner before/after run에서 non-terminal combat을 회피하는 선택과
  minimap의 위치/미방문/목표 정보가 과도한 안내 없이 이해된다.
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
- [ ] 각 stage에서 non-terminal enemy를 최소 하나 남기고 terminal policy로
  clear한 continuous evidence를 남긴다.
- [ ] 각 stage에서 최소 세 room과 optional branch를 방문해 fog transition,
  player marker, checkpoint/reward/gate state를 continuous evidence로 남긴다.
- [ ] every required rope reversal, shooter/sentry cover interaction, repeated
  leaper destination, mobile patrol cycle을 actual stage에서 확인한다.
- [ ] production capture에는 debug route label과 불필요한 full trajectory
  overlay가 없고, 필요한 danger startup은 color 외 cue와 함께 남는다.
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
- [ ] skipped enemy가 stage clear를 막지 않고, terminal local objective와
  boss requirement만 의도대로 block한다.
- [ ] minimap state가 new run, room crossing, fall recovery, death retry,
  reward claim, checkpoint, gate open에서 결정론적으로 맞다.
- [ ] 1280×720과 compact supported viewport에서 route, enemy tell,
  minimap fog/marker가 읽힌다.
- [ ] production Web path가 가능할 경우 desktop과 동작이 일치한다.
- [ ] guideline의 10개 acceptance criterion을 모두 체크했다.

## Test Plan

### Static/import and content validation

`.\tools\godot.ps1 --path . --headless --import`

`.\tools\godot.ps1 --path . --headless --script res://tools/validate_room_templates.gd`

`.\tools\godot.ps1 --path . --headless --script res://tools/validate_curated_stage_plans.gd`

`.\tools\godot.ps1 --path . --headless --script res://tools/validate_stage_composition.gd`

`.\tools\godot.ps1 --path . --headless --script res://tools/validate_production_stage.gd`

`.\tools\godot.ps1 --path . --headless --script res://tools/validate_stage_progression_policy.gd`

`.\tools\godot.ps1 --path . --headless --script res://tools/validate_stage_minimap_runtime.gd`

`.\tools\godot.ps1 --path . --headless --script res://tools/validate_gameplay_hud.gd`

`.\tools\godot.ps1 --path . --headless --script res://tools/validate_player_movement_runtime.gd`

`.\tools\godot.ps1 --path . --headless --script res://tools/validate_shooter_runtime.gd`

`.\tools\godot.ps1 --path . --headless --script res://tools/validate_flooded_enemy_runtime.gd`

The runtime validators above are not accepted unchanged. Their fixtures must
cover non-terminal enemy bypass, stage-specific terminal policy, room crossing
and fog state, same-stage retry discovery, rope descent through a one-way top,
projectile contact with authored cover, repeated leaper destination selection,
and reproduced mobile-enemy stuck cases before they can close Milestone A.

### Flow regressions

`.\tools\godot.ps1 --path . --headless --script res://tools/validate_forge_station_flow.gd`

`.\tools\godot.ps1 --path . --headless --script res://tools/validate_safe_intermission_flow.gd`

`.\tools\godot.ps1 --path . --headless --script res://tools/validate_stage_attempt_retry.gd`

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

Every normal-stage capture includes the minimap. Additional isolated HUD captures
cover:

- initial dark map with start/current/exit;
- partially explored map with current player and active checkpoint;
- discovered optional reward before and after claim;
- closed/open gate or shortcut;
- locked/ready terminal exit;
- compact 960×540 and normal 1280×720 overlap proof in both locales.

### Manual continuous scenarios

1. Start a fresh run and clear each required route without equipment-dependent jump.
2. Intentionally miss one landing in every stage and confirm local recovery.
3. Take every optional path, collect reward, rejoin, then retry the stage.
4. In each tactical combat room, use both intended elevation responses.
5. Pause or hesitate at every room entry and confirm no unavoidable hit.
6. Explain the next route, optional clue, and reward without debug labels.
7. Measure any stretch longer than eight seconds without movement, combat, route,
   or reward decision.
8. Climb every required rope in both directions, reverse once near the top and
   bottom, and dismount without repeated collision or corrective jumping.
9. Stand behind every declared shooter/sentry cover surface and confirm the
   projectile terminates on terrain rather than damaging through it.
10. Observe every leaper and mobile patrol encounter for multiple cycles and
    record any idle lock, wall push, repeated unreachable landing, or lane exit.
11. Repeat representative routine jumps with early release and imperfect
    approach; required navigation must not depend on theoretical maximum input.
12. In each stage, leave at least one non-terminal main-route enemy alive and
    complete only the authored terminal policy. Confirm the stage clears once.
13. In Ruin and Sanctum, reach the terminal room while its local encounter is
    alive, confirm the exit is locked, then clear only that local encounter.
14. In Flooded, reach the shelter with earlier enemies alive and confirm arrival
    is sufficient.
15. Cross at least three room boundaries while watching the minimap; current,
    visited, unvisited, and player position must update without flicker.
16. Activate a checkpoint, discover and claim an optional reward, and open the
    Sanctum gate/shortcut; confirm each marker changes once and does not expose
    undiscovered content.
17. Die after exploring multiple rooms, retry the same stage, and confirm map
    knowledge persists while mechanical/reward state restores to stage entry.
18. Start a new run and enter the next stage; confirm prior discovery does not
    leak.

### Web production validation

When export templates are available:

1. Run `.\tools\export_web.ps1`.
2. Load `$npjt-port-guard` before starting the built app under `D:\npjt`.
3. Use the fastrun manager's `codex` lane.
4. Inspect the built Web app, not only the editor/dev path.
5. Verify keyboard movement, jump, dash, attack, guard, interaction, pause,
   stage retry, optional branch, non-terminal enemy bypass, minimap fog/markers,
   and camera framing.

## Progress

- [x] Current stage code, topology, metrics, and fixed captures inspected.
- [x] External research and visual-source analysis completed.
- [x] Canonical map-design guideline written.
- [x] Current metrics rerun on Godot 4.7 and recorded.
- [x] Per-stage detailed visual studies generated and reviewed as direction probes.
- [x] Owner production-path feedback and code/validator blind spots audited for
  traversal comfort, rope descent, projectile cover, leaper/patrol behavior,
  trajectory overlays, and normal-stage camera ownership.
- [x] Global required-route enemy gate, unused terminal requirement metadata,
  assembled room-position data, retry boundary, and top-right HUD capacity audited.
- [x] Official Nintendo/Ubisoft navigation patterns reviewed for enemy bypass,
  visited-space mapping, minimap placement, markers, and blocked/available path
  guidance.
- [x] Milestone 0 construction blueprints reconciled with current room IDs and approved.
- [x] Milestone A completion, minimap, diagnostic, and shared terrain-interaction
  contract implemented.
- [x] Milestone B Ruin implemented and accepted.
- [ ] Milestone C Flooded implemented and accepted.
- [ ] Milestone D Sanctum implemented and accepted.
- [ ] Milestone E cross-stage pass accepted.
- [ ] Milestone F release validation accepted.

## Next Steps

1. Complete Milestone 0 only; do not edit gameplay geometry yet.
2. Add terminal policy and minimap layers to the three source-linked blueprints,
   then lock the Ruin pilot boundary.
3. Add Milestone A red fixtures for global enemy gating, terminal local policy,
   map room crossing/fog/retry, comfort chains, rope descent, terrain-blocked
   projectiles, repeated leaper destinations, mobile-enemy stuck behavior, and
   camera commitments before changing runtime behavior.
4. Implement the shared Milestone A completion/navigation/terrain contracts, then
   rerun the same fixtures green.
5. Complete and playtest Ruin before touching Flooded, including enemy bypass and
   minimap evidence.
6. Apply the proven pattern to Flooded, then Sanctum without copying the same
   silhouette.

## Rollback / Safety

- Commit each milestone separately so one stage can be reverted without touching
  the others.
- Do not stage or commit unrelated UI, master-integration, generated import, or
  user-authored dirty files.
- Preserve stable room IDs and reward IDs. Change content version when authored
  geometry or anchor meaning changes.
- Preserve room-local encounter clear facts and reward settlement while removing
  their accidental global exit authority.
- Do not make the exit permanently open as a shortcut around a terminal local
  objective; change only the authored policy for that stage.
- Keep minimap geometry derived from StagePlan/Assembly. Do not hand-maintain a
  second per-stage graph or rasterized collision map.
- Preserve exploration knowledge separately from retry-restored mechanical and
  reward state.
- Keep current room scenes available until replacement geometry passes
  reachability, flow, and capture validation in the same milestone.
- Never weaken movement, no-soft-lock, safe-intermission, or reward-duplication
  validators to make new geometry pass.
- Do not change player movement values, collision body size, enemy range, or
  projectile speed merely to make authored geometry easier.
- Fix rope, projectile collision, and reproduced existing-enemy terrain behavior
  in their shared owners; do not add per-room exception branches.
- Keep previous full-path telegraph behavior available until the replacement
  startup/destination cue passes production readability review in the same
  milestone.
- If a forward rejoin breaks the current graph contract, extend the validator
  explicitly; do not bypass it with hidden teleports.
- Do not add external assets or dependencies.

## Risks

| Risk | Mitigation |
| --- | --- |
| Better-looking geometry becomes harder than intended | baseline movement proof, safe entry, continuous first-clear test |
| More vertical combat produces unavoidable hits | threat-lane review, entry buffer, one pressure role introduced at a time |
| Comfort diagnostic becomes another arbitrary number | derive bands from runtime input fixtures, report ratios separately, keep owner continuous-play gate |
| Rope descent fix breaks one-way drop or leaves collision mask disabled | bidirectional fixture, jump/dash/respawn exit coverage, mask restoration assertion |
| Projectile collision makes existing ranged encounters inert | review every declared cover lane, preserve exposed attack windows, change placement before weakening collision |
| Terrain-aware enemy repair grows into a navigation rewrite | limit changes to reproduced existing-archetype failures and authored encounter bounds |
| Removing full trajectories makes attacks unreadable | retain local startup, facing/pose, destination or impact cue and verify without color-only dependence |
| Removing the global kill gate makes every stage a trivial dash-through | retain traversal, hazards, local terminal objectives, and enemy reward opportunity; validate bypass as a choice rather than mandatory combat |
| Legacy `required_*` names silently regain exit authority | define main-route/local-encounter/exit-eligibility terms and search for aggregate exit/HUD consumers |
| Terminal policy becomes free-form metadata drift | use one typed policy with validator coverage and remove dead requirement strings |
| Minimap duplicates or disagrees with the stage | project StagePlan/Assembly data, compare room/edge counts, and avoid runtime physics rasterization |
| Fog flickers at room seams | single current-room owner, deterministic overlap rule, boundary hysteresis fixture |
| Minimap spoils optional rewards or becomes enemy radar | reveal POI only after room discovery and exclude ordinary enemy/hazard tracking |
| Discovery is lost or duplicated on retry | treat it as knowledge, merge it forward across same-stage restore, reset by run/stage/content signature |
| Top-right minimap overlaps compact boss/objective UI | normal-stage-only visibility plus 960×540/1280×720/1920×1080 layout assertions and captures |
| Color-only fog or lock state is inaccessible | combine fill, edge, icon shape, and text-free badge state |
| Forward rejoin breaks reward/reset determinism | stable IDs, retry test after each optional reward, graph validation |
| Metrics are gamed again | separate diagnostics, no aggregate score, manual critical gates |
| Three stages converge on the same zigzag shape | lock distinct spatial thesis and compare collision-only silhouettes |
| Camera reveals information too late | commitment-before-information capture checklist |
| Detailed concept is mistaken for a mandate to build a large metroidvania | keep PRD timing budget, current template baseline, and explicit room-count approval gate |
| A beautiful blueprint cannot be mapped to runtime owners | require room IDs, sockets, anchors, and source paths on the construction version before geometry work |
| Scope leaks into broader UI or world art | keep only the normal-stage minimap here; all other UI redesign and final art stay in their existing plans |
| Web QA remains blocked | preserve desktop evidence, link the exact export-template blocker, do not claim release closure |

## Open Questions

No question blocks Milestone A or Ruin blockout. The following decisions are
deferred until rendered evidence exists:

- Whether one currently inactive catalog room should replace an active room.
  Default: do not increase active room count.
- Whether one stage needs an additional runtime room after dense blockout and
  timing validation. Default: first create sub-chambers/gameplay beats inside
  existing templates; request owner approval only with measured evidence.
- Whether continuous evidence is best stored as short video, frame sequence, or
  scripted checkpoints. Default: use the smallest artifact that proves camera and
  traversal without adding runtime code.
- Whether future authored stages need machine-readable intention metadata.
  Default: keep intention in plan/spec until repeated validator value is proven.
- Whether one-way platforms block basic enemy projectiles. Default: a surface
  presented and documented as cover blocks them; non-cover one-way surfaces must
  use one consistent declared policy rather than room-specific exceptions.
- Whether leaper landing candidates come from support surfaces or authored local
  markers. Default: derive from existing support geometry first; add local markers
  only when the intended destination cannot be expressed reliably without a new
  global schema.
- Whether normal-stage camera commitments need a focus/lookahead consumer.
  Default: first reshape geometry for the existing camera; add the smallest
  runtime owner only where continuous evidence still reveals information late.
- Whether coarse room bounds are sufficient minimap geometry after the denser
  blockout. Default: ship StagePlan/Assembly bounds first; add a small authored
  map-cell schema only for rooms that rendered evidence proves misleading.
- Whether resolved reward markers disappear or remain dimmed. Default: dim within
  the current stage so the player can remember the visited POI without confusing
  it with an available reward.
- Whether the active checkpoint marker shows only the current point or checkpoint
  history. Default: show only the active checkpoint.
- Whether a full-screen map and user markers are valuable after the minimap ships.
  Default: defer; do not allocate an input binding in this plan.

## Decision Notes

- 2026-07-15: Structural range alone is rejected as the definition of verticality.
- 2026-07-15: Fixed curated topology remains the production baseline.
- 2026-07-15: Current movement values, enemy catalog, stage counts, and the broad
  UI branch beyond the later-approved minimap remain outside the map redesign.
- 2026-07-15: Existing room count is preserved for the first pass.
- 2026-07-15: Optional paths should forward-rejoin by default; same-hub return
  requires an explicit reward and pacing justification.
- 2026-07-15: Ruin is the pilot stage. Flooded and Sanctum do not begin until
  Ruin proves the guideline through continuous play.
- 2026-07-15: World-space route readability belongs to map authoring even while
  UI readability is handled separately.
- 2026-07-16: Each stage needs its own detailed construction blueprint; a
  three-stage comparison image is insufficient implementation evidence.
- 2026-07-16: The approved visual direction is dense, folded, landmark-driven
  side-view exploration, not a copy of another game's map or an expansion into
  a full metroidvania campaign.
- 2026-07-16: Visual-study chamber count is illustrative. Existing authored
  templates and PRD timing remain the first-pass scope until play evidence
  justifies an explicit room-count decision.
- 2026-07-16: Session `019f6138-03a7-73d1-8ec6-a959d2f4d935` is source evidence
  for the separated stage blueprints, folded-space direction, room-boundary
  explanation, and staged rollout; session imagery is not collision authority.
- 2026-07-16: Automated reachability and isolated runtime validators do not close
  map validity without actual rope descent, cover collision, repeated enemy
  behavior, camera, and continuous traversal evidence.
- 2026-07-16: The map plan owns bounded shared runtime repairs only where authored
  terrain intention otherwise cannot function. Contextual attack input, shield
  redesign, potion economy, and intermission UI remain separate follow-ups.
- 2026-07-16: Full-range ordinary-enemy trajectory overlays are not a substitute
  for rational terrain-aware behavior. Required startup and danger readability
  remain, especially for boss attacks.
- 2026-07-16: `required_route` is a topology term, not a global mandatory-kill
  contract. Normal-stage completion is owned by typed terminal policy.
- 2026-07-16: Ruin and Sanctum require only their terminal local objective;
  Flooded requires arrival at its shelter. Non-terminal and optional enemies may
  be bypassed.
- 2026-07-16: The normal-stage minimap uses assembled world coordinates, not a
  duplicate hand-authored screen map. Unvisited rooms are dark, visited rooms
  brighten, and current player/room are shape-plus-accent states.
- 2026-07-16: Exit, active checkpoint, discovered reward, and discovered
  gate/shortcut are the initial POI set. Ordinary enemy and hazard tracking is
  intentionally excluded.
- 2026-07-16: Exploration knowledge persists across same-stage retry but resets
  across new run/stage/content signature.
