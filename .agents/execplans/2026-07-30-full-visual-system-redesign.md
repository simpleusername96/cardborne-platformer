---
type: plan
status: active
owner: BK
created: 2026-07-29
last_reviewed: 2026-07-30
scope: Replace every current player-facing visual surface with one non-pixel general-SF component system while preserving the connected five-stage run and completing the requested upgrade, pickup, enemy-strategy, and boss revisions
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ./2026-07-29-horde-foundation-recovery-and-acceptance.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../docs/design/component-sheets/README.md
  - ../../docs/product/combat-growth-improvement-direction.md
  - ../../docs/research/hidden-techniques-collective-enemies-mastery-unlocks.md
---

# 전체 비주얼 시스템 전면 재구성 실행 계획

현재 런타임의 pixel world texture, image-backed UI chrome, pixel combat
atlas를 부분 보수하지 않는다. 사용자가 긍정적으로 확인한
`00-general-sf-component-master-v1.png`를 유일한 방향 seed로 삼아, 모든
player-facing visual을 익숙한 일반 SF, 큰 기능 형태, 역할별 색·실루엣,
antialiased flat component로 다시 만든다.

이 계획은 visual만 넓히는 문서가 아니다. 최초 feedback에 포함된 engine
mount, dash ring, upgrade 중복·overflow, pickup 접촉, collective enemy
strategy와 다섯 boss exam을 유지하고, map·facility·HUD·minimap·deployment·
pause/settings·guidebook·report·result·garage까지 같은 문법으로 연결한다.
총 8개 구현 phase와 하나의 성능 선행 gate로 완료한다.

## Purpose

- **목표:** 플레이 시작 10초 안에 이동 방향, 조준 방향, 위험, 보상,
  objective와 다음 행동을 오인하지 않고, 최대 horde에서도 역할과 우선
  표적을 읽으며, 모든 screen을 한국어·영어에서 clipping 없이 사용할 수
  있는 하나의 visual system을 만든다.
- **최종 artifact:** runtime descriptor와 실제 Godot control에서 생성한
  12개 system sheet, 3개 field overview, 5개 boss practice set, 모든 modal
  contact sheet, pressure/accessibility capture와 manifest다.
- **첫 playable artifact:** 새 UI foundation, 수정된 upgrade modal과 pickup
  contact를 거친 뒤, 새 player/engine/dash/projectile/reward를 Stage 1에서
  플레이하는 slice다.
- **완료 상태:** current pixel production stack과 image chrome dependency가
  runtime·tool·validator·active docs에서 제거되고, 새 world/combat/UI
  system이 native/Web, 3 viewport, ko/en, reduced motion, grayscale,
  276-enemy peak와 320-actor capacity gate를 통과한다.

## Why / Context

현재 문제는 개별 asset의 완성도가 아니라 visual ownership이 세 갈래로
분리된 데서 시작한다.

1. world는 반복 pixel texture와 42개 atlas stamp를 사용한다.
2. UI는 17개 PNG state를 `StyleBoxTexture`로 늘여 쓴다.
3. combat은 pixel atlas와 procedural mesh fallback을 동시에 유지한다.

이 구조에서는 같은 player, enemy, item과 icon이 runtime, guidebook, card,
sheet에서 서로 다른 형태를 가질 수 있다. pixel direction frame은 continuous
vehicle rotation과 맞지 않고, UI chrome의 장식 edge는 text hierarchy보다
먼저 보이며, map의 작은 반복 seam은 collision·facility·threat보다 많은
시각 정보를 소비한다.

새 master sheet는 반대로 다음을 이미 증명한다.

- player, swarm, melee, ranged, controller, shield, artillery, support,
  repair, recall, projectile와 boss를 큰 외곽선으로 구분할 수 있다.
- mustard player/reward, coral hostile, magenta command/boss, mint support,
  cyan system의 역할 체계를 일반 SF 안에서 유지할 수 있다.
- engine을 hull rear socket에 고정하고 dash를 방향성 afterimage로 보일 수
  있다.
- pixel grid 없이도 현재 field의 어두운 배경에서 gameplay scale 판독이
  가능하다.

따라서 새 sheet를 combat에만 붙이지 않고 world, effect, HUD와 UI까지 같은
component grammar로 확장한다. gameplay topology, collision, controls와
campaign flow는 visual rework를 이유로 바꾸지 않는다.

## Pre-plan Evidence Already Verified

| 근거 | 확인된 사실 | 고정한 결정 | 재확인 시점 |
| --- | --- | --- | --- |
| `docs/design/component-sheets/00-general-sf-component-master-v1.png` | 사용자가 현재 방향에 긍정적으로 응답했고 player, role enemy, pickup, projectile, boss의 새 silhouette seed가 있다. | 이 이미지를 유일한 direction seed로 사용하고 style alternative 탐색을 종료한다. | Phase 1 시작 전 file hash 확인 |
| `docs/design/UI_VISUAL_SYSTEM.md` | 일반 SF와 semantic role은 유효하지만 world/UI는 pixel, combat은 non-pixel인 과도기 계약이다. | Phase 1에서 모든 visual family를 non-pixel component system으로 통일한다. | 각 phase spec update |
| `vehicle_pixel_world_mesh_builder.gd` | floor/wall/void repeat texture, 최대 60 chunk, 42 sprite decoration과 nearest filtering을 사용한다. | geometry truth는 보존하고 texture/stamp를 ≤12 retained visual batch의 descriptor mesh로 교체한다. | Phase 4 |
| 세 field definition | `7200×4320` geometry, start clearance, cover, spawn, item, terrain socket은 이미 gameplay truth다. | map topology나 field ID는 바꾸지 않고 field별 surface rhythm만 바꾼다. | Phase 4 geometry fingerprint |
| current field/runtime captures | floor micro-seam이 넓은 화면을 점유하고 player, pickup, small enemy와 HUD chrome이 서로 다른 detail scale을 쓴다. | map은 큰 panel mass와 sparse service marking을 사용하고 combat contrast를 먼저 확보한다. | Phase 4 rendered QA |
| `vehicle_ui_chrome_factory.gd` | 17개 `space-hangar-v2` PNG를 `StyleBoxTexture`로 runtime Theme에 덮는다. | image chrome factory를 제거하고 `vehicle_stage_theme.tres`의 `StyleBoxFlat`과 한 개의 vector frame component로 교체한다. | Phase 2 |
| `vehicle_stage_ui.gd` | 1,952줄에서 HUD, deployment, practice, pause, result와 garage를 직접 만든다. | routing/signal orchestration만 남기고 surface owner를 분리한다. | Phase 7 |
| current 960/1280/1920 UI proof | dark pixel frame가 panel마다 반복되고 compact surface도 장식 inset을 유지한다. | content hierarchy가 먼저 보이는 1 border + 1 semantic rail 구조로 바꾼다. | Phase 2·7 capture |
| upgrade card/panel과 capture | card별 정보 구조가 다르고 일부 실제 state에서 duplicate text, vertical overflow와 top clipping이 발생한다. | 83 next-level state에 summary를 고정하고 card content budget과 glyph-bounds validator를 둔다. | Phase 2 |
| `vehicle_run.gd` pickup path | endpoint center distance `<=60`만 확인한다. | previous→current segment와 player/pickup radius를 사용하는 swept overlap으로 바꾼다. | Phase 2 |
| player renderer | hull/flame은 16방향, engine module은 4방향이며 모든 invulnerability에 coral ring을 그린다. | engine은 continuous hull child, dash는 afterimage/flare, protection은 source별 cue로 분리한다. | Phase 3 |
| combat renderer validator | current pixel mode는 23 retained batch, total ceiling은 50이다. | shared mesh/MultiMesh architecture와 50-batch ceiling을 유지한다. | Phase 3 이후 매 batch |
| enemy strategy 문서 | `Gather → Lock → Execute → Break`, global permission과 stage별 formation idea가 있다. | 4방향 horde는 유지하고 일부 authored squad에만 collective tactic을 단계적으로 적용한다. | Phase 5 |
| boss patterns/runtime | 5 boss가 공통 primitive 순서와 health ratio phase를 공유해 burst가 phase를 건너뛸 수 있다. | 5개 고유 arena exam, sequential phase floor와 objective gate를 사용한다. | Phase 6 |
| horde recovery ExecPlan | 기능 회귀는 통과했지만 authoritative native/Web timing과 lifecycle gate가 열려 있다. | 사용자가 지정한 최종 asset/UI build에서 동일 threshold로 실행한다. | Phase 8 final gate |
| localization/validators | ko/en, 3 viewport, guidebook, report, UI layout validator가 이미 있다. | existing behavioral coverage를 보존하고 rendered bounds/accessibility oracle을 추가한다. | 매 UI phase |

## Input Classification

### 사실

- current product는 세 field 중 하나를 고른 뒤 같은 field에서 다섯 stage를
  이어 가는 top-down vehicle run이다.
- manual aim, held primary fire, dash, passive seeker, EMP, map pickup,
  upgrade card, authored encounter와 quota-gated boss는 보존 대상이다.
- Korean이 기본이며 Korean/English가 모든 player-facing surface에서
  완전해야 한다.
- Godot 4.7, GDScript, GL Compatibility와 현재 dependency set을 사용한다.
- visual geometry와 collision truth는 분리되어야 한다.

### 사용자 제약

- 역할별 색과 모양을 다르게 하는 현재 의미 체계는 유지한다.
- pixel 관련 제약은 새 디자인에 적용하지 않는다.
- player, enemy, item, projectile뿐 아니라 현재 design element 전체를 새
  방향으로 수정한다.
- 승인하지 않은 도자·해양·의례·material/cultural theme는 사용하지 않는다.
- dash의 붉은 원을 제거하고 방향성 잔상 계열 feedback을 사용한다.
- upgrade text, overlap와 overflow를 함께 고친다.
- boss idea와 enemy strategy 적용은 visual cleanup에 묻히지 않는다.
- player가 item에 닿거나 dash로 통과하면 획득해야 한다.

### 이 계획의 해석

- “전체 design element”는 현재 플레이어가 보는 world, combat, effect, HUD,
  minimap, icon, modal과 preview 전부를 뜻한다.
- field title과 gameplay topology는 visual motif 허가가 아니며 이번 rebrand
  대상도 아니다.
- audio는 visual timing과 동기화 검증만 하며 전면 재제작하지 않는다.
- 사용자의 “좋은데?”는 master sheet를 production geometry 자체가 아니라
  새 visual direction seed로 선택한 것으로 본다.

## Locked Decisions

### Visual thesis

| 항목 | 최종 결정 |
| --- | --- |
| 장르 | 익숙한 top-down industrial/general SF다. 특정 문화·재질·해양·의례 motif를 부여하지 않는다. |
| 형태 | 큰 mechanical mass, 명확한 front/rear cut, 기능 module, sparse state accent의 네 층만 사용한다. |
| rendering | antialiasing을 허용한 flat two-plane geometry다. pixel grid, nearest-neighbor, direction raster frame, dithering, texture noise를 사용하지 않는다. |
| detail | ordinary component는 filled mass 최대 3개, function accent 최대 2개, dark separation plane 최대 1개다. boss는 고유 module 최대 5개다. |
| shadow | 형태 분리를 위한 짧은 한 방향 dark plane만 허용한다. glow, bevel, nested outline, glossy highlight는 사용하지 않는다. |
| density | combat HUD는 cockpit-compact, modal은 정보 우선, world는 sparse다. 장식이 의미 cue와 같은 대비를 갖지 않는다. |
| motion | 이동, state change, impact와 objective만 움직인다. ambient pulse, 반복 flashing과 무의미한 orbit 장식은 금지한다. |

### Semantic palette

`vehicle_stage_visual_profile.gd`가 아래 값을 sole runtime color owner로
소유한다. UI Theme, component catalog, sheet와 minimap이 같은 값을
소비한다.

| token | hex | 의미 |
| --- | --- | --- |
| `space_black` | `#070B11` | exterior/absolute void |
| `world_canvas` | `#101923` | walkable base |
| `surface` | `#182431` | panel과 floor plate |
| `raised` | `#243445` | cover/facility/raised UI |
| `line` | `#465A6E` | non-semantic boundary |
| `text_primary` | `#EEF3F7` | primary text/live highlight |
| `text_muted` | `#9EADBC` | secondary text |
| `player_reward` | `#F2B735` | player, progress, reward, selection |
| `danger` | `#F05A5F` | ordinary hostile/damage |
| `boss_command` | `#D43F8D` | boss/command/objective lock |
| `support` | `#72D6C4` | heal, support, safe recovery |
| `system` | `#58BFEA` | energy, movement, recall, focus |
| `thermal` | `#F47A3C` | thermal affinity |
| `toxin` | `#91B44B` | toxin affinity |
| `cryo` | `#55BFE9` | cryo affinity |
| `arc` | `#AA6DE0` | arc affinity |

색은 identity 보조다. role, affinity, selected, locked와 support state는 color
외에 silhouette, notch, rail pattern 또는 glyph를 반드시 하나 가진다.

### Typography, spacing and controls

- Noto Sans KR variable 한 family만 사용한다.
- body weight는 500, label/title는 650이다.
- compact/wide type scale은 각각 `12/14/16/20/28/36`과
  `13/15/17/22/32/40`이다.
- spacing token은 `4/8/12/16/24/32`, panel inset은 compact `16`,
  wide `24`다.
- button, tab, toggle와 focus target의 최소 높이는 `44`다.
- body text는 `14` 미만으로 자동 축소하지 않는다.
- normal control은 1 px line, hover는 system rail, keyboard focus는 2 px
  system outline, selected는 3 px mustard rail, destructive는 coral
  text/outline을 사용한다.
- UI surface에는 한 개의 border와 한 개의 semantic accent rail만 허용한다.
  image-backed border와 반복 corner ornament는 금지한다.

### Responsive geometry

| viewport | outer safe margin | modal content maximum | mode |
| --- | ---: | ---: | --- |
| 960×540 | 16 | 928×508 | compact |
| 1280×720 | 24 | 1184×656 | wide |
| 1920×1080 | 32 | 1184×720 | wide centered |

- layout breakpoint는 width `1100`, report/guide three-column breakpoint는
  `1180`이다.
- upgrade card는 compact에서 최소 `280×286`, gap `12`, title 2줄,
  summary 3줄, effect row 2개, level pip 1줄을 사용한다.
- upgrade는 scroll을 사용하지 않는다. settings, guidebook, report는
  지정된 content region만 scroll할 수 있고 primary action은 고정한다.
- 모든 normal content glyph bounds는 container 안에 있어야 한다.
  `clip_contents`는 safety guard일 뿐 layout 해결책이 아니다.

### World grammar

- field geometry, collision, navigation, cover selection, terrain schedule와
  deterministic fingerprint는 그대로 둔다.
- floor는 큰 plate와 lane seam 두 scale만 사용한다. repeated micro-tile,
  random scratch와 high-frequency panel grid를 제거한다.
- void는 near-black mass와 sparse system edge만 가진다.
- 모든 blocker는 같은 raised shell, floor-side light edge와 outer shadow로
  표현한다.
- presentation-only decoration은 node가 아닌 retained descriptor instance로
  그린다. field당 최대 24개이며 boundary 8–12, cover/facility 4–8,
  floor prop 4–6, wear 0–2 범위다.
- functional terrain은 decoration보다 높은 contrast와 고유 shape를 가진다:
  repair plus, transit opposing chevron, overdrive stacked forward chevron,
  arc broken bolt rail, bulkhead split slab.
- 세 field는 topology에서 읽히는 일반 SF panel rhythm만 달리한다.
  - Drowned Ruin: central court frame과 orthogonal service plate
  - Tidal Archive: parallel bay spine과 lateral corridor rail
  - Storm Drydock: basin frame과 diagonal docking guide
- 이름에서 해양·유적 motif를 추론해 조개, 파도, 도자, 의례 장식을 넣지
  않는다.

### Combat, motion and feedback

- player engine mount/flame은 hull continuous transform의 rear child다.
  engine count는 rear socket의 좌우 배치만 바꾸고 angle은 따로 quantize하지
  않는다.
- aim mount는 hull과 독립된 manual aim transform을 유지한다.
- dash는 0.20초 동안 최대 5개 afterimage와 engine flare를 사용한다.
  coral/radial ring과 circular burst는 instance 0이어야 한다.
- reduced motion은 반복 afterimage 대신 0.12초 이하의 elongated silhouette
  한 개와 engine flash를 사용한다.
- dash, hit, arrival, transit와 barrier protection source를 분리한다.
  hit는 coral hull flash, arrival/transit는 bracket, barrier만 mint ring을
  사용한다.
- projectile의 damaging core는 collision boundary와 일치하고 tail은
  non-damaging direction cue다.
- telegraph는 exact live geometry, monotonic readiness와 one-shot commitment를
  유지한다. decorative pulse를 추가하지 않는다.
- high-count effect는 retained mesh/MultiMesh를 사용하고 actor별 node를
  만들지 않는다.

### HUD hierarchy

- top-left에 hull/experience cluster와 그 아래 `154×44` action rail을 묶는다.
  primary fire는 rail에 넣지 않는다.
- top-center objective는 최대 `440×48`이고 boss가 active면 boss name,
  health와 one-line mechanic으로 교체된다. objective와 boss cluster를
  동시에 쌓지 않는다.
- top-right minimap은 `176×108`, target panel은 그 아래 conditional
  `176×60`이다.
- stage transition과 notification은 objective 아래에 한 줄로 나타나고
  crosshair를 가리지 않는다.
- off-screen threat, status orbit, crosshair와 support timer는 shape-coded
  retained mesh를 사용한다.
- 최대 pressure에서 player, crosshair, committed threat, boss objective,
  pickup과 current target이 decorative world layer보다 먼저 보인다.

### Modal composition

- **Deployment:** ship silhouette/loadout + five compact control rows와
  difficulty/lock explanation의 two-column body, 한 개의 Deploy primary.
- **Upgrade:** 세 structured card, explicit selection과 Equip confirm,
  optional decline. duplicate top detail은 제거한다.
- **Pause:** Resume만 filled primary, Restart/Settings secondary, Garage는
  restrained tertiary danger다.
- **Settings:** left category rail, right content; Ship Status first, audio,
  controls, gameplay motion, language를 유지한다.
- **Guidebook:** wide는 category/list/detail 세 column, compact는 top
  category tabs + list/detail 두 pane이다. discovered preview는 runtime
  component를 재사용하고 locked entry는 neutral silhouette만 쓴다.
- **Report:** wide three-column, compact keyboard tabs, bottom primary 고정.
- **Result/Garage:** 결과 metric, build/loadout와 next action을 component
  glyph로 요약하고 의미 없는 큰 빈 panel을 만들지 않는다.
- **Boss Practice:** debug-only 기능은 그대로 두되 production boss/component
  owner와 동일한 preview/theme를 사용한다.

## Rejected Alternatives

| 대안 | 기각 이유 |
| --- | --- |
| current pixel sprite와 chrome을 다시 그린다. | direction-frame, nearest filtering, atlas/runtime/sheet 분리를 그대로 남긴다. |
| map/UI는 pixel로 두고 combat만 non-pixel로 바꾼다. | 사용자가 요청한 전체 redesign이 아니며 detail scale 충돌이 계속된다. |
| ImageGen master sheet를 runtime PNG로 잘라 쓴다. | sheet와 gameplay scale, state, anchor, collision truth가 분리된다. |
| actor마다 SVG/PNG node를 만든다. | 276/320 horde의 retained batching과 cache contract를 깨뜨린다. |
| neon glow, glass panel, hologram noise로 SF를 강조한다. | 의미 대비를 장식이 소비하고 일반 SF라는 제한을 불필요하게 좁힌다. |
| map topology와 collision도 visual에 맞춰 다시 만든다. | gameplay scope가 바뀌고 기존 navigation/encounter acceptance를 무효화한다. |
| every screen을 `vehicle_stage_ui.gd`에서 계속 만든다. | 한 파일이 theme, layout, modal behavior와 routing을 모두 소유한다. |
| upgrade card에 scroll 또는 자동 tiny font를 넣는다. | 비교해야 할 정보를 숨기고 ko/en parity를 악화한다. |
| enemy count를 줄여 silhouette를 읽게 한다. | 승인된 four-quadrant horde와 pressure contract를 되돌린다. |
| boss HP를 일괄 배수로 늘린다. | 같은 pattern을 더 오래 반복하고 burst phase skip을 해결하지 못한다. |
| legacy pixel path를 permanent fallback으로 남긴다. | 두 visual truth가 다시 drift한다. |

## Current State

이미 완료된 것:

- 일반 SF, role-coded, non-pixel component master direction이 생성됐다.
- current product, design spec, runtime owner, three field, all modal,
  validator와 rendered evidence inventory가 완료됐다.
- engine, dash, upgrade, pickup, collective tactic, boss 문제의 code owner와
  acceptance path가 확인됐다.
- 지원되지 않은 named theme 문서와 생성 기록은 이전 cleanup에서 제거됐다.

아직 구현되지 않은 것:

- master direction을 소비하는 runtime descriptor와 full-system sheet
- non-pixel world, UI foundation와 combat publication
- upgrade summary/layout와 swept pickup
- source-specific protection, collective tactic와 five boss exam
- HUD/modal composition, legacy pixel stack retirement와 final evidence

## Scope

### 포함

- visual token, typography, spacing, icon, focus/selection/disabled state
- three field의 floor, void, wall, cover, prop, wear와 facility
- player hull, aim, engine, module, secondary와 motion state
- mobile/stationary enemy, elite cue, collective phase와 boss/objective
- projectile, telegraph, impact, damage, protection, status와 support effect
- experience, repair, recall, crate와 upgrade glyph
- HUD, action rail, objective/boss/target, minimap, radar, status, crosshair,
  notification와 stage banner
- deployment, upgrade, pause, settings, guidebook, report, result, garage와
  debug Boss Practice의 visual parity
- 83 upgrade state의 information model과 overflow
- swept pickup contact
- stage별 collective tactic와 five boss exam
- component sheet, capture, manifest, docs, validator, native/Web evidence
- migration 완료 뒤 pixel runtime/pipeline/chrome/tool/validator 삭제

### 제외

- field topology, collision radius, navigation, camera zoom와 encounter quota 변경
- control scheme, manual aim, held fire, dash input, seeker와 EMP 삭제·교체
- new card family, save schema, meta progression, currency와 new stage
- field/stage title의 naming rebrand
- audio asset 전면 재제작
- Godot 교체, production dependency 추가와 renderer backend 교체

### 파괴적 또는 되돌리기 어려운 작업

- final zero-reference gate 뒤 `pixel-art-production/`, pixel-only design tools,
  validator, tile shader와 compatibility catalog를 삭제한다.
- 삭제 전 active runtime, guidebook, capture, docs와 validation reference가
  0인지 `rg`와 full import로 확인한다.
- git history가 복구 경로다. migration 중에는 source asset을 먼저 지우지
  않는다.

### 별도 BK 승인이 필요한 작업

- 이 계획의 일반 SF grammar에서 벗어난 named theme 도입
- gameplay geometry, collision, camera, count, speed 또는 control 변경
- production dependency, engine 또는 renderer backend 변경

위 세 가지가 아니면 이 계획의 phase와 legacy deletion은 추가 선택 없이
진행한다.

## Assumptions

- horde recovery plan의 capacity, pressure, timing과 lifecycle threshold는
  final release authority다.
- 2026-07-30 사용자 지시에 따라 asset과 UI publication을 먼저 완료하고,
  그 최종 build로 horde native/Web/capacity/lifecycle gate를 실행한다.
- current visual footprint와 gameplay collision radius는 presentation
  redesign과 독립적으로 유지한다.
- boss objective는 base primary, dash와 EMP만으로 해결 가능해야 하며 특정
  card를 필수 key로 요구하지 않는다.

## Architecture and Ownership

| 책임 | 최종 owner | interface/invariant | retire 또는 축소할 owner |
| --- | --- | --- | --- |
| semantic color/scale | `scripts/vehicle/vehicle_stage_visual_profile.gd` | UI, world, combat, minimap과 sheet가 같은 token을 소비 | scattered literal color override |
| primitive/cache | `scripts/presentation/components/vehicle_component_mesh_library.gd` | immutable cached `ArrayMesh`; gameplay rule 없음 | generic recipe part of `vehicle_combat_visual_library.gd` |
| actor descriptor | `vehicle_actor_visual_catalog.gd` | role/state/anchor/silhouette only | pixel actor families |
| projectile descriptor | `vehicle_projectile_visual_catalog.gd` | collision-normalized core + non-damaging tail | pixel projectile atlas |
| reward/glyph descriptor | `vehicle_reward_visual_catalog.gd`, `vehicle_ui_glyph_catalog.gd` | pickup, XP, crate, action, upgrade family | pixel HUD/card icon families |
| effect descriptor | `vehicle_effect_visual_catalog.gd` | transient semantic state; timer/damage rule 없음 | generic ring/diamond fallback recipes |
| retained combat upload | `vehicle_combat_renderer.gd` | snapshot consumer, batch/cache owner | pixel branch와 `_pixel_enabled` |
| world descriptor | `vehicle_world_visual_catalog.gd` | field surface/stamp/facility presentation only | `vehicle_world_stamp_catalog.gd` |
| world draw | `vehicle_world_mesh_builder.gd` | immutable geometry snapshot consumer, ≤12 batches | `vehicle_pixel_world_mesh_builder.gd` |
| world orchestration | `vehicle_stage_backdrop.gd` | field/layout fingerprint 전달 | `PixelWorld` naming |
| UI theme | `art/ui/production/vehicle_stage_theme.tres` | font + `StyleBoxFlat` semantic variations | `vehicle_ui_chrome_factory.gd`, chrome recipe |
| reusable frame | `scripts/ui/vehicle_ui_accent_frame.gd` | one border, one rail, no state policy | image nine-slice panels |
| UI orchestration | `vehicle_stage_ui.gd` | modal routing, signals, snapshot distribution only | direct surface construction methods |
| HUD | `vehicle_gameplay_hud.gd` | frozen HUD snapshot render | current inline HUD construction |
| screen owners | deployment/pause/result/garage/boss-practice panel files | one surface layout and focus contract each | matching `_build_*` blocks in StageUI |
| existing screen owners | upgrade/settings/guidebook/report panel files | keep behavior boundary, replace composition | inline theme/color overrides |
| preview | actor/reward/glyph catalogs consumed by guidebook/card/sheet | no preview-only art | pixel catalog/fallback mixture |
| upgrade truth | definition + offer presenter | immutable summary/effect snapshot | UI behavior interpretation |
| pickup contact | `scripts/rewards/vehicle_pickup_contact.gd` | pure swept geometry | endpoint check in `vehicle_run.gd` |
| protection | `vehicle_player_protection_windows.gd` | source-specific windows | single `player_invulnerable` presentation meaning |
| collective recipe/state | tactic catalog/runtime | authored phase + bounded permission | actor-owned world scan |
| boss exam | boss exam catalog/runtime | objective/phase/vulnerability state | pattern-order-only identity |
| sheet generation | `tools/design/capture_vehicle_visual_system.gd` + capture scene | actual runtime provider only | sheet-only art and old pixel generators |

`vehicle_combat_visual_library.gd`는 migration facade로만 남는다. 새 catalog
caller가 모두 연결되면 primitive-only owner로 축소하거나 삭제한다.
완료 상태에서 같은 role을 두 catalog가 소유할 수 없다.

## As-Is / To-Be Delta Map

| 영역 | As-is | To-be | acceptance | leftover guard |
| --- | --- | --- | --- | --- |
| direction | pixel world/UI + pixel/procedural combat 혼합 | one general-SF component grammar | 12-sheet manifest와 runtime fingerprint 일치 | active pixel authority 문구 0 |
| map | repeating tile + 42 sprite stamp | large mesh plate + ≤24 descriptors | 3 field가 title 없이 구분되고 collision과 일치 | texture/stamp runtime ref 0 |
| UI chrome | 17 PNG nine-slice state | `StyleBoxFlat` + accent frame | all state/viewport/locale capture 통과 | `StyleBoxTexture` UI ref 0 |
| player engine | 16-dir hull + 4-dir module | continuous rear child | 360° anchor error ≤1 px-equivalent | engine direction frame ref 0 |
| dash | afterimage + coral ring + radial asset | directional afterimage/flare | radial/coral dash instance 0 | dash asset family ref 0 |
| protection | source unknown single float | source window snapshot | overlapping source expiry test | generic invulnerability ring 0 |
| pickup contact | endpoint center radius 60 | swept radius 66 | full dash pass one collect | old constant/call 0 |
| actors/items | pixel micro-detail | cached role silhouette | grayscale duplicate signature 0 | pixel family caller 0 |
| upgrade | variable hierarchy/duplicate detail | fixed summary + 0–2 effect rows | 83×2×3 bounds matrix 0 failure | UI behavior parsing 0 |
| HUD | scattered framed clusters | four-priority-zone layout | maximum pressure central safe area | duplicate objective/boss 0 |
| guidebook | text + mixed preview fallback | runtime component preview | discovered/locked parity | preview-only art 0 |
| enemies | role sequence without joint action | staged collective tactics | global Execute ≤1 | actor full-array tactic scan 0 |
| bosses | common primitive order | 5 semantic arena exams | phase skip 0, base-kit solvable | generic objective fallback 0 |
| runtime | pixel fallback remains | one owner per family | combat ≤50, world ≤12, draw p95 ≤200 | `_pixel_enabled` 0 |

## Proposed Design

### System sheet contract

`docs/design/component-sheets/system-v1/`에 다음 sheet와
`manifest.json`을 둔다. sheet는 `2048×1152` PNG이며 실제 runtime catalog,
Theme 또는 screen owner를 호출해 생성한다.

| ID | sheet | 포함 내용 |
| ---: | --- | --- |
| 01 | `01-foundation-tokens.png` | palette, type scale, spacing, border, rail, focus와 motion tokens |
| 02 | `02-world-surfaces.png` | three field plate rhythm, floor, void, wall, cover와 prop |
| 03 | `03-world-facilities.png` | repair, transit, overdrive, arc, bulkhead와 state |
| 04 | `04-player-components.png` | hull, aim, 0–3 engine, secondary, idle/move/dash/hit/barrier |
| 05 | `05-enemy-components.png` | 모든 mobile/stationary role, elite와 collective phase |
| 06 | `06-boss-components.png` | five silhouette, module, phase, objective, vulnerable |
| 07 | `07-projectile-telegraph-vfx.png` | ownership, affinity, core/tail, warning, impact, status |
| 08 | `08-reward-upgrade-glyphs.png` | XP, repair, recall, crate, action와 upgrade family |
| 09 | `09-hud-minimap-markers.png` | HUD cluster, crosshair, radar, minimap와 marker state |
| 10 | `10-ui-controls-states.png` | button, tab, card, toggle, field, panel의 full state |
| 11 | `11-modal-flow-contact-sheet.png` | seven production modal + debug practice의 compact/wide |
| 12 | `12-pressure-accessibility.png` | Stage 1/3/5 pressure, grayscale, reduced motion와 collision overlay |

각 sheet는 normalized view, gameplay/UI actual scale, grayscale, state label,
anchor와 debug collision/rect overlay를 포함한다. `manifest.json`에는 provider,
catalog/theme fingerprint, source commit, viewport, locale와 SHA-256을 기록한다.
ImageGen master sheet는 direction evidence로만 남고 production manifest에는
runtime provider로 등록하지 않는다.

### Collective enemy rollout

모든 tactic은 `Gather → Lock → Execute → Break`를 사용한다. 전역에서
`Lock/Execute`는 1개, 추가 tactic 1개는 `Gather`까지만 허용한다. offscreen
squad는 Lock permission을 받을 수 없다. 현재 four-quadrant arrival와
authored count는 유지하며 surge당 최대 1개 squad만 tactic tag를 받는다.

| Stage | Teach | Combine/Power Test | break lesson |
| ---: | --- | --- | --- |
| 1 | Spearhead | Swarm Screen | leader kill, EMP, cover collision |
| 2 | Shepherd Pack | Shielded Column | controller/shield priority, flank |
| 3 | Fuse Pack | Bulwark Fuse | early mine detonation, ram/cover break |
| 4 | Repair Network | Crossfire Convoy | link node, EMP, line-of-sight break |
| 5 | learned tactic remix | Crown sequential command | new hidden rule 없이 priority 종합 |

### Five boss exams

| Stage | boss/exam | arena objective | phase combination |
| ---: | --- | --- | --- |
| 1 | Foundry Colossus — Forge Plate | charge를 plate/blocker axis로 유도하거나 plate를 파괴해 core open | Spearhead → Swarm Screen |
| 2 | Archive Leviathan — Segment Lock | wake 반대 측면으로 이동해 locked segment를 깨고 side core open | Shepherd Pack → Shielded Column |
| 3 | Drydock Titan — Relay Polarity | `+/-` shape relay를 정해진 순서로 overload해 shield off | Fuse Pack → Bulwark Fuse |
| 4 | Switchyard Behemoth — Route Switch | switch로 charge lane을 잠그고 blocker 충돌로 armor car detach | Repair Network → Crossfire Convoy |
| 5 | Crown Engine — Lattice Command | outer core를 처리해 safe corridor를 만들고 central core open | 이전 tactic을 동시가 아닌 순차 command |

- health phase는 1→2→3 순서이며 65%/30% floor를 한 frame에 건너뛰지 않는다.
- objective 해결 뒤 vulnerability window는 `4.5–5.5초`다.
- module health는 boss max health의 `8–10%`, base primary로 한 read cycle
  안에 해결 가능하다.
- boss add는 동시에 최대 12기이며 total hostile 320 안에 포함한다.
- objective cue는 one-line ko/en과 shape icon을 함께 사용한다.
- reference clear-time은 Stage 1–2 `50–80초`, Stage 3–4 `60–95초`,
  Stage 5 `75–110초`, Hard는 `130초` 이하다.

## Tasks

- [x] Phase 1에서 active visual authority, token과 sheet harness를 고정한다.
- [x] Phase 2에서 non-pixel UI foundation, upgrade clarity와 pickup contact를
  완료한다.
- [x] Sheet-first gate에서 12개 component design sheet를 publication한다.
- [x] Phase 3에서 player/engine/dash/projectile/reward/effect를 publication한다.
- [x] Phase 4에서 three field, facility와 minimap world layer를 교체한다.
- [x] Phase 5에서 enemy visual family와 collective tactic을 적용한다.
- [x] Phase 6에서 five boss exam과 objective visual을 적용한다.
- [ ] Phase 7에서 HUD와 모든 modal composition을 같은 system으로 완성한다.
- [ ] Phase 8에서 legacy pixel stack을 제거하고 horde recovery를 포함한 final
  release gate를 통과한다.

## Milestones

### Phase 1 — Visual authority and production sheet foundation

**목표:** 선택된 방향을 active spec과 reusable descriptor contract로 바꾸되
gameplay renderer에는 아직 연결하지 않는다.

- [x] `UI_VISUAL_SYSTEM.md`를 이 계획의 full non-pixel system으로 갱신한다.
- [x] `vehicle_game_spec.md`의 presentation clause만 새 descriptor/role
  contract로 맞춘다.
- [x] `vehicle_stage_visual_profile.gd`에 locked palette를 반영하고 literal
  role color 중복 owner를 제거한다.
- [x] component mesh library와 actor/projectile/reward/effect/world/glyph
  catalog skeleton을 책임별 파일로 만든다.
- [x] `capture_vehicle_visual_system.gd`, capture scene와 manifest writer를
  구현한다.
- [x] foundation/control state sheet를 실제 token/Theme provider에서 만든다.
- [x] master seed와 새 sheet의 역할을 docs index에 명확히 기록한다.

**Batch acceptance**

- active spec에 pixel grid/nearest/direction-frame 의무가 없다.
- 모든 current visual ID가 정확히 한 target catalog에 매핑된다.
- 같은 provider fingerprint로 두 번 생성한 sheet hash가 같다.
- master sheet 밖의 named theme나 style alternative가 active input에 없다.

**Batch guard**

- gameplay renderer, collision, count, speed와 horde fixture를 건드리지 않는다.
- catalog skeleton에 attack, damage, card behavior 또는 layout policy를 넣지
  않는다.

### Phase 2 — UI foundation, upgrade clarity and pickup contact

**목표:** renderer와 독립된 사용자 불편을 먼저 없애고 image UI chrome을
runtime에서 제거한다.

- [x] `vehicle_stage_theme.tres`를 locked type/spacing/StyleBoxFlat state로
  교체한다.
- [x] `VehicleUiAccentFrame`을 추가하고 `VehicleUiChromeFactory`,
  chrome recipe와 runtime UI texture caller를 제거한다.
- [x] 모든 existing modal을 새 foundation에서 boot해 unreadable/clipped
  regression이 없게 한다. full composition은 Phase 7에서 수행한다.
- [x] upgrade definition에 level별 summary key를 추가하고 presenter가
  immutable `summary + 0..2 effect_rows + behavior_change`를 export한다.
- [x] 41 card/83 state ko/en copy를 실제 card width에 맞춘다.
- [x] upgrade panel/card를 fixed content budget으로 바꾸고 duplicate top
  detail을 제거한다.
- [x] glyph bounds, focus, selected, disabled, optional decline, input guard와
  two-step confirm validator를 확장한다.
- [x] pure `vehicle_pickup_contact.gd`와 previous→current swept circle을
  연결한다.
- [x] endpoint, tangent, normal pass, full dash pass, 0.1 outside miss,
  inactive/idempotent repair/recall case를 추가한다.

**Batch acceptance**

- `960×540`, `1280×720`, `1920×1080` × ko/en × 83 state × 3 slot에서
  upgrade overflow, overlap, clipping, missing copy가 0이다.
- body font ≥14, card scroll 0, effect row 0–2다.
- player radius 24 + pickup body radius 42 = 66 tangent를 contact로 인정하고
  dash pass-through가 정확히 한 번 collect된다.
- runtime UI `StyleBoxTexture`와 pixel HUD/card icon reference가 0이다.

**Batch guard**

- upgrade behavior/application은 UI로 이동하지 않는다.
- pickup effect, spawn와 budget은 contact helper로 이동하지 않는다.

### Deferred final gate — Horde recovery completion

- [ ] horde plan Phase 5/6와 모든 objective completion criterion이 완료된다.
- [ ] clean commit에서 native/Web `production_replay`, `peak_horde`,
  `capacity_pressure`, `boss_pressure`와 600-second lifecycle baseline이 있다.
- [ ] target subsystem/frame retention threshold와 evidence path를 이 plan
  실행 기록에 고정한다.

2026-07-30 사용자 지시에 따라 이 gate는 모든 asset과 UI publication 뒤
Phase 8 final release gate에서 실행한다. threshold, clean-commit 조건과
failure rule은 낮추지 않는다.

### Sheet-first publication gate — Complete component design set

2026-07-30 사용자가 Phase 3 draft의 player asset이 완성된 것인지 확인한 뒤,
crude generic polygon을 family별로 부분 publication하는 순서를 중단했다.
runtime 교체 전 다음 12개 sheet를 하나의 일관된 component set으로 먼저
완성한다.

- [x] `01`–`12` sheet가 모두 runtime token/catalog provider에서 생성된다.
- [x] player는 compact symmetric hull, rigid twin rear engine, independent aim
  mount로 고정한다.
- [x] enemy 18 role, boss 5종, projectile 6 affinity, reward/facility, HUD marker,
  control state와 modal 8종이 각 sheet에서 shape-first로 구분된다.
- [x] player/enemy/projectile/reward는 gameplay 1× composition strip에서
  크기와 우선순위를 확인한다.
- [x] pressure sheet는 grayscale, reduced motion, core/tail, center-clear,
  ko/en text-fit 검증 슬롯을 포함한다.
- [x] sheet hash가 연속 두 번 생성에서 동일하고 manifest가 12개 record와
  provider fingerprint를 가진다.

이 gate는 direction 탐색 단계가 아니다. accepted general-SF master를
silhouette seed로 사용하며 production geometry는 catalog와 runtime mesh가
소유한다. sheet는 inspection artifact이고 runtime texture로 잘라 쓰지 않는다.

### Phase 3 — Player, projectile, reward and feedback publication

**목표:** 최초 feedback의 engine/dash 문제를 포함한 가장 자주 보는 combat
layer를 새 component owner로 전환한다.

- [x] source-specific protection windows를 도입하고 snapshot을 분리한다.
- [x] player hull, rear engine mount/flame와 independent aim mount를 새 catalog로
  연결한다.
- [x] dash radial asset/ring을 제거하고 normal/reduced-motion cue를 연결한다.
- [x] player/hostile projectile, affinity core/tail, XP, repair, recall, crate,
  secondary와 transient effect를 새 catalog로 연결한다.
- [x] migrated family는 pixel fallback 없이 새 owner만 사용한다.
- [x] player/reward/projectile/effect sheet와 gameplay 1× capture를 생성한다.

**Batch acceptance**

- 360°를 5° step으로 돌릴 때 engine socket world error ≤1 px-equivalent다.
- dash frame에 coral/radial ring 0, afterimage ≤5다.
- protection source overlap/expiry가 gameplay invulnerability를 바꾸지 않는다.
- projectile core extent가 기존 collision radius와 일치한다.
- combat retained batch ≤50, draw-call p95 ≤200, horde baseline 대비 target
  subsystem p95 +10%/frame p95 +5%를 넘지 않는다.

**Batch guard**

- current visual/collision radius, controls와 projectile damage/range를 바꾸지
  않는다.
- family migration 뒤 silent pixel fallback을 두지 않는다.

### Phase 4 — Three-field world, facilities and minimap

**목표:** 현재 map을 큰 일반 SF surface grammar로 교체하고 collision truth를
더 명확히 보이게 한다.

- [x] world visual catalog에 three field plate rhythm, blocker, void, prop와
  facility descriptor를 구현한다.
- [x] `VehicleWorldMeshBuilder`가 immutable geometry snapshot을 vertex-colored
  mesh/MultiMesh로 그리게 한다.
- [x] decoration을 ≤24 descriptor, world visual batch를 ≤12로 제한한다.
- [x] repair, transit, overdrive, arc와 bulkhead의 idle/warning/active/cooldown/
  broken state를 새 shape로 연결한다.
- [x] minimap static geometry와 facility/marker가 같은 semantic token을
  소비한다.
- [x] three field overview와 world/facility sheet를 생성한다.
- [x] world pixel builder, stamp catalog, shader와 world-only validator를
  zero-runtime-reference 뒤 제거한다.
- [ ] raw tile texture와 pixel generator/catalog record는 remaining enemy/boss
  atlas와 함께 Phase 8에서 atomic retirement한다. 현재 runtime caller는 0이다.

**Batch acceptance**

- visible opening과 blocker가 collision/navigation truth와 일치한다.
- three field를 title 없이 overview와 local capture에서 구분할 수 있다.
- facility는 grayscale에서 shape로 구분되고 decorative prop와 혼동되지 않는다.
- world batch ≤12, decoration ≤24, decoration collision node 0이다.
- current field/layout fingerprint, exact retry와 five-stage persistence가
  변하지 않는다.

**Batch guard**

- field geometry, cover selection, terrain schedule와 spawn/item socket을
  presentation code가 소유하지 않는다.
- stage마다 world style을 갈아 끼우지 않는다.

### Phase 5 — Enemy families and collective tactics

**목표:** 모든 mobile/stationary enemy를 새 role grammar로 옮기고 existing
strategy document의 collective behavior를 단계적으로 연결한다.

- [x] actor catalog에서 ordinary, specialist, stationary와 elite silhouette를
  완성한다.
- [x] tactic catalog/runtime, enemy hot fields와 global permission을 추가한다.
- [x] Stage 1→5 Teach/Combine/Power Test beat를 authored data에 넣는다.
- [x] Lock/Execute cue는 body module/accent로 보이고 actor별 world ring을
  추가하지 않는다.
- [x] guidebook counterplay metadata와 enemy sheet를 갱신한다.

**Batch acceptance**

- grayscale role signature duplicate 0이다.
- offscreen Execute 0, simultaneous global Lock/Execute ≤1, stale member 0이다.
- four-quadrant arrival, authored count, quota, speed와 active cap이 변하지
  않는다.
- maximum pressure에서 priority target과 committed attack이 role decoration보다
  먼저 보인다.
- same performance retention rule을 통과한다.

**Batch guard**

- actor가 full enemy array를 tactic 판단마다 scan하지 않는다.
- complete horde를 formation 줄서기로 바꾸지 않고 surge당 tactic squad 1개만
  사용한다.

### Phase 6 — Five boss semantic exams

**목표:** common pattern-order boss를 five unique arena exam으로 교체한다.

- [x] boss exam catalog/runtime, sequential floor와 objective state를 구현한다.
- [x] Foundry → Leviathan → Titan → Behemoth → Crown 순서로 vertical slice를
  확장한다.
- [x] each boss의 module, one-line HUD cue, practice phase와 finite add를
  production runtime에 연결한다.
- [x] base kit, reference build와 high-output build fixture를 추가한다.
- [x] boss/objective sheet와 ko/en guide/practice capture를 생성한다.

**Batch acceptance**

- 모든 build가 phase 1→2→3을 순서대로 경험하고 phase skip이 0이다.
- base kit으로 objective를 해결할 수 있고 fixed wait invulnerability가 없다.
- add ≤12, total hostile ≤320, objective cue never-hidden이다.
- target clear-time과 Hard ≤130초를 만족한다.
- death, retry, stage transition에 module/add/tactic state leak가 없다.

**Batch guard**

- raw HP/damage inflation을 primary tuning 수단으로 쓰지 않는다.
- 다섯 boss에 같은 objective skin을 복제하지 않는다.

### Phase 7 — HUD and complete modal suite

**목표:** 모든 remaining screen을 새 component와 information hierarchy로
완성하고 `VehicleStageUI`의 catch-all layout ownership을 해체한다.

- [x] `VehicleGameplayHud`와 deployment, pause, result, garage, debug practice
  panel을 분리한다.
- [x] `VehicleStageUI`에서 direct `_build_*` screen block을 제거하고 routing,
  signal, visibility, snapshot distribution만 남긴다.
- [x] HUD를 locked four-zone hierarchy로 재배치한다.
- [x] minimap, target, radar, crosshair, status, banner와 notification을 새
  token/glyph로 완성한다.
- [x] deployment, pause/settings, guidebook, report, result, garage와 upgrade의
  compact/wide composition을 완성한다.
- [x] guidebook/card/loadout preview가 runtime catalog만 소비하게 한다.
- [x] modal flow, HUD/minimap와 controls-state sheet를 actual control에서
  생성한다.

**Batch acceptance**

- 8 surface × ko/en × 3 viewport에서 overflow, overlap, clipping,
  unreachable focus와 missing copy가 0이다.
- modal이 열리면 conflicting HUD/gameplay input이 차단되고 primary action이
  하나다.
- maximum pressure에서 central combat rectangle이 HUD로 가려지지 않는다.
- guidebook locked entry는 identity를 leak하지 않고 discovered preview는
  runtime mesh fingerprint와 같다.
- `vehicle_stage_ui.gd`에 deployment/pause/result/garage layout construction이
  남지 않는다.

**Batch guard**

- screen owner가 gameplay singleton을 query하거나 mutate하지 않는다.
- visual redesign으로 analytics-free labels, input mapping와 modal flow를
  바꾸지 않는다.

### Phase 8 — Legacy retirement and release acceptance

**목표:** competing visual truth를 제거하고 production evidence로 완료를
판정한다.

- [x] remaining pixel catalog/branch/family, generator, schema, recipe, asset,
  evidence와 old visual proof를 reference search 뒤 삭제한다.
- [x] `pixel-art-production/`, pixel-only tools/validators와
  `space_hangar_tile_variation.gdshader`를 제거한다.
- [x] active product/design spec, docs index, component manifest, guidebook와
  runtime을 최종 상태에 맞춘다.
- [x] task-scoped code quality audit로 catch-all, competing owner, public
  snapshot, hot-path scan과 dead compatibility path를 확인한다.
- [ ] full validators, native/Web matrix, production-style Web smoke,
  pressure matrix와 600-second lifecycle soak를 clean commit에서 실행한다.
- [ ] 이 ExecPlan의 durable decision을 spec에 반영하고 lifecycle 규칙대로
  완료 처리 후 제거한다.

**Batch acceptance**

- repository runtime/tool/active docs에서 pixel production reference가 0이다.
  historical git commit hash 언급은 허용한다.
- 12 sheet manifest와 runtime fingerprint가 일치한다.
- 아래 Completion Criteria가 모두 통과한다.

**Batch guard**

- unrelated user change, lockfile, dependency와 Godot version을 건드리지 않는다.
- release gate를 낮추거나 current horde/product value를 변경해 통과시키지
  않는다.

## Validation Cadence

### Inner-loop

```powershell
.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_visual_tokens.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_component_catalogs.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_ui_theme.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_ui_layout.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_ui_localization.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_pickup_contact.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_player_presentation.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_world_visuals.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_collective_tactics.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_boss_exams.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_combat_renderer.gd
```

새 validator는 해당 owner가 구현된 phase부터 실행한다. old pixel validator는
replacement validator가 같은 behavior/asset coverage를 가진 뒤에만 삭제한다.

### Sheet and rendered capture

```powershell
$sheetDir = Join-Path (Resolve-Path .).Path "build\validation\visual-system-sheets"
.\tools\godot.ps1 --path . --headless `
  --script res://tools/design/capture_vehicle_visual_system.gd -- `
  --output=$sheetDir `
  --sheet-size=2048x1152

$captureDir = Join-Path (Resolve-Path .).Path "build\validation\visual-system-ko-960"
.\tools\godot.ps1 --path . -- `
  --capture-all=$captureDir `
  --capture-size=960x540 `
  --capture-locale=ko
```

- UI: ko/en × 960×540, 1280×720, 1920×1080
- combat: idle, move, dash, hit, barrier, pickup, tactic Lock/Break,
  boss objective와 maximum pressure
- motion: normal/reduced-motion
- accessibility: color/grayscale와 collision/anchor debug overlay

### Pressure and final gates

```powershell
$output = Join-Path (Resolve-Path .).Path "build\performance\visual-system\peak-horde-01.json"
$godotArgs = @(
  "--rendering-method", "gl_compatibility", "--",
  "--performance-scenario=peak_horde",
  "--performance-output=$output",
  "--performance-warmup=5",
  "--performance-duration=20"
)
.\tools\godot.ps1 @godotArgs

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

renderer/world/enemy/boss batch는 같은 clean baseline에서 3×20초 비교한다.
target subsystem p95 +10% 또는 frame p95 +5%를 넘는 batch는 유지하지 않는다.
horde plan의 더 엄격한 authoritative native/Web threshold, combat batch ≤50,
world batch ≤12, draw-call p95 ≤200, 600-second memory growth <8 MiB를
약화하지 않는다.

Web handoff는 `$npjt-port-guard`로 fastrun-manager `codex` lane을 확인한 뒤
`build/web` production output만 serve한다. Chrome DevTools로 page/JS/PCK/WASM
200, console error/warning 0, canvas sizing, full flow와 ko/en switching을
확인하고 task-owned process를 정리한다.

## Test Plan

### Automated contract

- catalog ID coverage, deterministic fingerprint, role signature, anchor와
  component complexity budget
- world geometry/collision parity, field fingerprint, batch/decoration budget
- Theme variation/state coverage, type/spacing token, focus target와 glyph bounds
- 83 upgrade state summary/effect/layout matrix
- engine continuous transform, protection overlap와 dash instance count
- pickup swept overlap boundary/idempotency
- tactic composition, permission, phase, break, cancel, offscreen와 cap
- boss phase floor, objective unlock, finite adds와 base-kit solvability
- current stage, encounter, projectile, reward, save, guidebook, report,
  localization와 transition regression

### Rendered QA

- world→player→threat→pickup→HUD 순으로 frame이 읽히는가
- three field가 일반 SF 안에서 topology-derived rhythm으로 구분되는가
- 360° player rotation에서 engine이 rear socket에서 꺾이거나 미끄러지지 않는가
- dash가 방향을 보이되 danger ring으로 오인되지 않는가
- maximum pressure에서 role silhouette와 committed telegraph가 남는가
- 모든 modal에서 title, content, action이 한 번에 보이고 장식 frame보다
  먼저 읽히는가
- grayscale에서 enemy role, repair/recall, facility, affinity와 boss objective를
  구분하는가

### Manual gameplay QA

- keyboard/mouse와 controller control이 기존과 동일한가
- item 접촉과 dash 통과가 즉시 한 번 collect되는가
- 모든 upgrade 선택 결과를 card만 보고 예측할 수 있는가
- collective Lock 동안 대응 시간이 있고 Break가 player action 결과로 읽히는가
- boss objective가 one-line cue와 arena state만으로 이해되는가
- boss가 강하지만 fixed wait, health sponge와 infinite add cleanup이 아닌가
- Stage 1–5 connected run에서 visual style, focus, objective와 state가 끊기지
  않는가

## Rollback and Safety

- phase마다 task-scoped commit을 만들고 UI, player, world, enemy, boss와
  retirement를 한 commit에 섞지 않는다.
- descriptor/catalog commit과 runtime publication commit을 분리한다.
- migrated family publication이 성능 gate를 실패하면 publication만 제거하고
  accepted descriptor/sheet는 보존해 원인을 수정한다.
- runtime에서 한 family는 한 owner만 사용한다. permanent fallback flag를
  만들지 않는다.
- legacy source는 caller parity, `rg` zero reference, full import와 Web export
  전에는 삭제하지 않는다.
- upgrade summary는 save data에 직렬화하지 않는다.
- boss/tactic incomplete authored data는 old behavior로 silent fallback하지
  않고 validator에서 실패한다.
- unrelated user-authored change를 stage, revert 또는 cleanup하지 않는다.

## Risks

| 위험 | 조기 신호 | 정해진 대응 |
| --- | --- | --- |
| general SF가 generic polygon으로 평준화됨 | grayscale outer contour가 유사 | role signature와 1× sheet에서 body/negative space를 먼저 수정 |
| dark world/UI가 서로 합쳐짐 | HUD panel과 floor luminance가 비슷함 | UI opaque surface와 1 px line을 유지하고 world seam contrast를 낮춤 |
| 새 world가 너무 비어 보임 | local capture에 route landmark가 없음 | decoration 수가 아니라 large facility/field rhythm을 조정 |
| component layer로 batch 증가 | combat 50/world 12 근접 | ordinary mass/accents budget, shared mesh/material cache를 강제 |
| UI foundation swap이 모든 screen을 동시에 깨뜨림 | Phase 2 proof에서 old layout clipping | full 8-surface smoke를 foundation batch gate로 사용 |
| StageUI 분리 중 behavior drift | signal/focus/modal transition 차이 | public signal과 debug contract를 먼저 freeze하고 owner만 이동 |
| upgrade copy는 짧지만 모호함 | 선택 뒤 결과 예측 실패 | summary에 trigger, target, magnitude/condition을 포함 |
| tactic이 CPU hot path를 악화함 | full-array scan, coordination p95 상승 | member ID list/event queue, global coordinator 1회 update |
| tactic이 horde를 줄 세움 | four-quadrant occupancy 감소 | surge당 tagged squad 1개, 나머지 current pressure |
| boss floor가 강제 대기처럼 보임 | player action 없이 invulnerable timer 진행 | objective 즉시 actionable, fixed wait 금지 |
| legacy가 너무 일찍 삭제됨 | missing guide/tool/runtime reference | family별 zero-reference + full import 뒤 삭제 |

## Predetermined Error Handling and Contingencies

| trigger | required response | escalation |
| --- | --- | --- |
| sheet와 runtime fingerprint 불일치 | sheet publication 중단, duplicate owner 제거, 재생성 | owner가 둘 이상 필요한 경우 BK |
| UI text bounds 실패 | content hierarchy/copy/spacing 수정; font <14/scroll 금지 | effect를 숨겨야만 맞는 경우 BK |
| performance retention 실패 | 해당 publication commit 제거, batch/scan profile 후 한 bounded correction | horde contract 변경이 필요한 경우 BK |
| collision/visual mismatch | visual descriptor만 수정하고 gameplay geometry 보존 | geometry 변경 없이는 해결 불가능한 경우 BK |
| boss base-kit failure | module health/read window를 target 범위 안에서 조정 | card/save contract가 필요한 경우 BK |
| legacy reference 잔존 | deletion 중단, exact caller migration | unrelated external consumer가 확인된 경우 BK |

## Open Questions

없다. direction, palette, runtime representation, screen hierarchy, map boundary,
sheet contract, phase order, boss/tactic behavior, validation과 retirement rule은
이 문서에 고정됐다. 구현 중 correction은 같은 grammar 안의 shape, spacing,
contrast, timing과 performance 조정으로 제한한다.

## Decision Notes

- current master sheet는 accepted direction evidence지만 runtime art 정본은
  아니다. production truth는 catalog/Theme와 그것으로 생성한 sheet다.
- 기존 field title은 content identifier일 뿐 visual motif가 아니다.
- visual redesign 때문에 gameplay map, count, speed, radius와 controls를
  바꾸지 않는다.
- horde plan의 미완료 성능 gate는 사용자 지시에 따라 final asset/UI build에서
  실행하며 threshold와 evidence contract는 그대로 유지한다.
- old enemy strategy의 “2–3 front 축소”는 current four-quadrant horde와
  충돌하므로 채택하지 않고 collective phase/permission만 채택한다.
- boss strength는 HP가 아니라 phase skip 방지, unique objective, readable
  response와 earned damage window로 정의한다.
- pixel production stack은 history로 보존하지 않는다. migration 완료 뒤
  repository에서는 삭제하고 git history만 복구 경로로 남긴다.
- Phase 4의 raw tile PNG는 runtime에서 더 이상 load되지 않지만 current
  legacy catalog/generator validation이 참조한다. 세 파일만 먼저 지워
  intermediate catalog를 깨뜨리지 않고 Phase 8의 전체 pixel stack과 함께
  제거한다.

## Progress

- [x] 사용자 feedback과 “전체 design element” scope를 분류했다.
- [x] current product/design authority, ExecPlan standard와 lifecycle rule을
  확인했다.
- [x] three field, world renderer, combat renderer, UI theme, HUD와 모든 modal
  owner를 source에서 확인했다.
- [x] runtime map, pressure, UI chrome, layout proof와 accepted master sheet를
  직접 비교했다.
- [x] pixel caller, world/chrome asset, validator와 retirement boundary를
  inventory했다.
- [x] 하나의 architecture, visual grammar, phase order, gate와 acceptance를
  고정했다.
- [x] Phase 1 visual authority and sheet foundation
- [x] Phase 1 provider commit `e01cbaa`와 runtime-backed
  `01-foundation-tokens.png`, `10-ui-controls-states.png`,
  `manifest.json`을 생성했다. 39 family와 32 world stamp가 exact-one-owner
  validation을 통과했고 두 번의 sheet hash가 일치했다.
- [x] Phase 2 UI foundation, upgrade and pickup
- [x] Phase 2 implementation commit `bc31a12`에서 image-backed chrome과
  pixel HUD/card icon caller를 제거하고, 41 card/83 state의 fixed-budget
  ko/en upgrade UI와 swept pickup contact를 연결했다. `960×540`,
  `1280×720`, `1920×1080` 전수 layout validator와 native ko/en capture,
  Web export·deployment→gameplay smoke가 통과했다. Web smoke의 legacy
  ArrayMesh 초기화 경고 66건은 startup 뒤 증가하지 않았으며 Phase 3
  renderer publication의 관찰 항목으로 유지한다.
- [x] Sheet-first component design set
  - 12개 `2048×1152` sheet와 complete manifest를 runtime provider에서
    생성했다.
  - 두 output set의 12개 PNG SHA-256이 일치했다.
  - player는 twin rigid engine과 independent aim mount, boss는 5개
    body/module, pressure sheet는 gameplay 1× inspection composition을
    사용한다.
- [x] Phase 3 player/projectile/reward/feedback
  - player protection source, engine socket 360°/5°, dash non-radial,
    projectile collision extent와 migrated pixel fallback validator가 통과했다.
  - `visual-system-phase3-ko-960-sheetfirst` runtime capture에서 player,
    repair/recall/XP와 upgrade surface를 확인했다.
  - 이 phase의 performance retention 수치는 사용자 지시에 따라 Phase 8
    clean final build에서 실행한다.
- [x] Phase 4 world/facilities/minimap runtime publication
  - `VehicleWorldMeshBuilder`가 three field를 각각 orthogonal court,
    parallel bay, diagonal dock rhythm으로 그리며 world batch ≤12,
    decoration ≤24, visual collision 0 validator를 통과했다.
  - repair/overdrive/transit/arc/bulkhead state와 minimap marker를 semantic
    vector shape로 전환했다.
  - `visual-system-phase4-world-final-b` overview에서 중복 walkable region에
    의한 line clutter를 발견해 primary region rhythm으로 수정했다.
  - old world builder/stamp/shader/validator는 삭제했다. raw tile production
    file은 Phase 8 atomic legacy retirement까지 runtime-unreferenced 상태다.
  - 12 sheet 두 output hash가 일치했고 provider fingerprint와 manifest가
    일치한다. performance retention은 사용자 지시대로 Phase 8에만 실행한다.
- [x] Phase 5 enemy/tactics
  - 18개 mobile/stationary role을 pixel atlas 없이 고유 vector silhouette로
    publication했고 combat retained batch ceiling 50을 지켰다.
  - surge당 tactic squad 1개, global Gather/Lock·Execute permission,
    offscreen break, stale-member pruning과 Stage 1→5
    Teach/Combine/Power Test recipe를 production encounter에 연결했다.
  - `visual-system-phase5-enemy-final`에서 peak horde, Lock, Break와
    guidebook counterplay를 확인했다. Break의 legacy vulnerability ring은
    body-attached bracket으로 교체했다.
  - encounter/spawn/run/renderer/guidebook/localization validator와 12 sheet
    deterministic hash가 통과했다. performance retention은 사용자 지시대로
    Phase 8 최종 build에서만 실행한다.
- [x] Phase 6 bosses
  - five stage가 forge plate, segment lock, relay polarity, route switch,
    lattice command라는 서로 다른 semantic objective와 body/module silhouette를
    사용한다.
  - 65%/30% sequential floor, 9% module health, 5초 vulnerability와
    base/reference/high-output fixture에서 phase skip 0을 검증했다.
  - boss entry는 boss·module·12 add slot을 예약하고 phase 전환 때 retired
    module을 먼저 회수해 objective spawn이 hostile capacity에 막히지 않는다.
  - `visual-system-phase6-boss-final-c`의 five-boss startup/imminent/active/
    recovery/phase-two와 `visual-system-phase6-en-1280`의 English guide/HUD를
    확인했다.
  - boss/runtime/practice/renderer/layout/localization validator와 12 sheet의
    deterministic hash가 통과했다. clear-time 및 performance retention은
    사용자 지시에 따라 Phase 8 최종 build에서 측정한다.
- [x] Phase 7 HUD/modal suite
  - `VehicleStageUI`를 screen layout catch-all에서 routing·signal·visibility·
    snapshot distribution owner로 축소하고 gameplay HUD와 deployment,
    pause, result, garage, boss-practice panel을 독립 component로 분리했다.
  - shared modal host/surface가 viewport clamp, compact mode, content padding,
    focus와 one-primary-action contract를 제공한다. modal rail은 surface가
    직접 그려 content column을 침범하지 않는다.
  - 8 surface × ko/en × 960/1280/1920 matrix에서 visible non-scroll overflow,
    clipping, unreachable focus, missing copy와 conflicting HUD가 0이다.
    41 upgrade/83 state도 같은 layout validation을 통과했다.
  - guidebook preview의 pixel catalog 의존을 제거하고 discovered entry는
    runtime vector provider, locked entry는 identity-neutral glyph만 쓴다.
  - sheet 09–11은 actual runtime HUD, controls와 eight modal control에서
    생성되며 12개 published/evidence PNG hash가 모두 일치한다.
  - `visual-system-phase7-ko-960-surfacefix`에서 compact deployment,
    guidebook, upgrade, result, garage와 modal surface rail을 직접 확인했다.
    performance retention은 사용자 지시대로 Phase 8 최종 build에서만
    실행한다.
- [ ] Phase 8 retirement/final gates
  - `pixel-art-production/` 7,172개 file과 isolated catalog/generator/
    validator 16개를 exact reference audit 뒤 삭제했다. 삭제 경로를 가리키는
    runtime, tool, active design 문서 reference는 0이다.
  - `VehicleRun`의 caller 없는 texture draw helper와 catalog instance,
    renderer/world의 false-valued compatibility snapshot key와 visual
    library의 unused quad mesh를 제거했다.
  - component registry는 retired source manifest 대신 actor, projectile,
    reward, effect, world, core glyph와 upgrade glyph descriptor group을
    직접 검증한다. clean provider fingerprint는
    `d837c8cbc6a893bc6bf3af657ccda1327da792b840bc30dd2bdf2f0c01398ae4`다.
  - 12개 clean-tree sheet의 published/evidence SHA-256이 모두 일치한다.
    45개 focused validator가 통과했으며, Phase 7 extraction 뒤 남아 있던
    damage-feedback health control과 run-difficulty deployment private call은
    component-owned debug contract로 교체했다.
  - task-scoped quality audit에서 competing visual owner, dead catalog API,
    runtime hot-path 추가와 private Control leak가 0이다. native/Web,
    pressure, performance와 lifecycle soak는 이 retirement commit 뒤에만
    실행한다.
- [ ] Final horde native/Web/capacity/lifecycle gate

## Next Steps

1. Phase 8에서 raw tile을 포함한 legacy를 삭제한 최종 build로 horde recovery와 전체
   native/Web/capacity/lifecycle gate를 실행한다.

## Completion Criteria

- [ ] 모든 current player-facing visual surface가 new general-SF system을 쓴다.
- [ ] runtime/active docs에 pixel grid, nearest, direction-frame와 image chrome
  dependency가 없다.
- [ ] player engine은 continuous hull angle에서 rigid rear attachment다.
- [ ] dash coral/radial ring 0이고 normal/reduced-motion cue가 방향을 보인다.
- [ ] player, enemy, boss, facility, item, projectile, effect와 glyph가 sole
  runtime catalog를 사용한다.
- [ ] three field는 gameplay geometry를 보존하며 서로 구분되는 world
  descriptor를 사용한다.
- [ ] world batch ≤12, combat batch ≤50, draw-call p95 ≤200이다.
- [ ] 41 upgrade, 83 state, ko/en, 3 viewport에서 overflow/overlap/clipping과
  missing content가 0이다.
- [ ] player가 item에 닿거나 dash로 통과하면 정확히 한 번 획득한다.
- [ ] Stage 1–5 tactic Teach/Combine/Power Test와 telemetry가 있다.
- [ ] offscreen Execute 0, simultaneous global Execute ≤1, stale member 0이다.
- [ ] five boss가 unique semantic exam을 가지고 phase skip 0이다.
- [ ] boss objective는 base kit으로 해결 가능하고 adds ≤12, total hostile
  ≤320이다.
- [ ] every HUD/modal surface가 ko/en, 960/1280/1920, keyboard/controller focus와
  reduced motion contract를 통과한다.
- [ ] grayscale에서 role, affinity, facility, pickup과 objective를 shape로
  구분한다.
- [ ] manual aim, held fire, dash control, seeker, EMP, encounter, quota,
  transition, save와 localization이 회귀하지 않는다.
- [ ] full validators, native/Web build, production smoke, pressure matrix와
  600-second lifecycle soak가 통과한다.
- [ ] 12 sheet manifest, guidebook preview, runtime fingerprint와 active spec이
  일치한다.
- [ ] pixel production stack, compatibility branch, stale visual proof와
  competing visual owner가 repository에서 제거된다.

## Stop Conditions

완료:

- 모든 Completion Criteria가 clean task-scoped commit과 재현 가능한
  evidence로 통과한다.

다음 경우에만 BK에게 escalation:

- locked visual grammar를 구현하려면 engine, dependency, gameplay geometry,
  collision, count, speed 또는 control을 바꿔야 하는 경우
- horde authoritative baseline이 없어 renderer 비교가 불가능한 경우
- 960×540 ko/en에서 font ≥14와 full effect content를 동시에 유지할 수 없는
  경우
- base kit으로 boss objective를 해결하려면 card/save contract가 필요한 경우
- repository 밖의 확인된 consumer가 legacy pixel path를 계속 요구하는 경우

중단 사유가 아님:

- 같은 grammar 안에서 한 component의 silhouette/spacing/contrast correction
- focused validator가 찾은 in-scope defect
- target clear-time 안에서 boss module health/window 조정
- exact zero-reference cleanup이 남은 상태
- 한 번의 non-authoritative smoke noise

## Handoff

```text
Goal:
Replace every current player-facing visual with the selected non-pixel
general-SF component system while preserving gameplay truth and completing the
upgrade, pickup, collective-enemy, and boss revisions.

Read first:
1. This plan
2. .agents/execplans/2026-07-29-horde-foundation-recovery-and-acceptance.md
3. docs/product/vehicle_game_spec.md
4. docs/design/UI_VISUAL_SYSTEM.md
5. docs/design/component-sheets/README.md

Execute first:
Phase 1 only. Update authority, implement tokens/catalog boundaries and the
runtime-backed capture harness, then generate foundation/control sheets.

Do not:
- reopen style alternatives;
- publish combat/world renderer changes before the horde gate;
- change field geometry, collision, count, speed, controls, dependency or engine;
- use ImageGen sheets as runtime assets;
- add scroll/tiny text to upgrade cards;
- leave a permanent pixel fallback.

Validate:
Use tools/godot.ps1, phase-owned validators, deterministic sheet/capture hashes,
the horde retention rule, Web export, npjt codex-lane production start and
Chrome DevTools. Commit only coherent task-owned phase changes.
```
