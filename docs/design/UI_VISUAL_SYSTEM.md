---
type: spec
status: active
owner: BK
created: 2026-07-21
last_reviewed: 2026-07-30
canonical_for: Cardborne vehicle-game art direction and UI presentation
scope: All player-facing world, combat, HUD, modal, preview, and effect surfaces
related:
  - ../product/vehicle_game_spec.md
  - ./component-sheets/README.md
  - ../../.agents/execplans/2026-07-30-approved-sheet-fidelity-recovery.md
---

# Cardborne UI 및 비주얼 시스템

## Purpose

이 문서는 Cardborne의 모든 player-facing surface에 적용되는 정본 visual
contract다. 실제 runtime truth는
`scripts/vehicle/vehicle_stage_visual_profile.gd`, 책임별 component catalog와
Godot Theme가 소유한다. 실제 provider에서 생성한 system sheet는 이 runtime
truth와 승인 시안의 충실도를 검증하는 publication artifact다.

`00-general-sf-component-master-v1.png`는 runtime asset은 아니지만,
silhouette, proportion, mechanical layering와 contrast hierarchy의
binding visual reference다. runtime descriptor와 production sheet는 이 reference를
느슨하게 재해석하지 않고 같은 visual family로 읽히도록 구현해야 한다.

## Scope

world, actor, projectile, reward, effect, HUD, modal, minimap, guidebook preview와
debug boss practice를 포함한 모든 player-facing surface에 적용한다. gameplay
rule과 collision truth는 각 기존 owner의 책임이며 이 문서는 표현만 정의한다.

## Requirements

### 디자인 방향

- 장르는 익숙한 top-down industrial/general SF다. 특정 문화, 재질, 해양,
  의례 motif를 제품 정체성으로 만들지 않는다.
- 형태는 큰 mechanical mass, 명확한 front/rear cut, 기능 module, sparse
  state accent 네 층으로 구성한다.
- 모든 형태는 antialiased hard-edged geometry를 사용한다. 고정 raster 방향
  frame, 미세 texture noise와 dither는 사용하지 않는다.
- ordinary component는 dark perimeter/separation, semantic main mass,
  secondary mechanical plane, restrained hard highlight 또는 inset의 3–5
  filled plane으로 구성한다. boss는 비대칭 body와 고유 objective module을
  최대 5개까지 가진다.
- 짧은 한 방향 shadow, hard edge highlight와 얕은 inset은 승인 시안의
  기계적 깊이를 설명할 때 사용한다. soft glow, photoreal material,
  uncontrolled glossy effect와 반복 nested outline은 사용하지 않는다.
- world는 sparse, HUD는 cockpit-compact, modal은 information-first다.
  장식은 gameplay cue나 primary action과 같은 대비를 갖지 않는다.
- motion은 이동, state change, impact와 objective만 설명한다. ambient
  pulse, 반복 flashing과 의미 없는 orbit 장식은 금지한다.

### Semantic token

`VehicleStageVisualProfile`이 아래 색과 scale의 유일한 runtime owner다.
world, combat, minimap, Theme와 sheet는 literal role color를 다시 선언하지
않고 이 token을 소비한다.

| token | 값 | 의미 |
| --- | --- | --- |
| `space_black` | `#070B11` | exterior/absolute void |
| `world_canvas` | `#101923` | walkable base |
| `surface` | `#182431` | panel과 floor plate |
| `raised` | `#243445` | cover, facility, raised UI |
| `line` | `#465A6E` | non-semantic boundary |
| `text_primary` | `#EEF3F7` | primary text/live highlight |
| `text_muted` | `#9EADBC` | secondary text |
| `player_reward` | `#F2B735` | player, progress, reward, selection |
| `danger` | `#F05A5F` | ordinary hostile/damage |
| `boss_command` | `#D43F8D` | boss, command, objective lock |
| `support` | `#72D6C4` | heal, support, safe recovery |
| `system` | `#58BFEA` | energy, movement, recall, focus |
| `thermal` | `#F47A3C` | thermal affinity |
| `toxin` | `#91B44B` | toxin affinity |
| `cryo` | `#55BFE9` | cryo affinity |
| `arc` | `#AA6DE0` | arc affinity |

색은 identity의 보조 수단이다. role, affinity, selected, locked와 support
state는 silhouette, notch, rail pattern 또는 glyph 중 하나를 함께 사용한다.
grayscale에서도 외곽선과 negative space만으로 주요 역할을 구분해야 한다.

### Component 및 catalog contract

각 visual ID는 정확히 한 catalog가 소유한다.

| owner | 책임 | 금지 |
| --- | --- | --- |
| component mesh library | immutable cached flat primitive | gameplay rule, collision |
| actor catalog | role, state, anchor, silhouette | health, AI, attack |
| projectile catalog | collision-normalized core와 non-damaging tail | damage, range, hit rule |
| reward catalog | pickup, shard, crate의 shape/glyph | spawn, value, collection |
| effect catalog | transient semantic state | timer, damage, protection rule |
| world catalog | field surface, facility, decoration | topology, collision, schedule |
| UI glyph catalog | action, upgrade, minimap, preview glyph | layout, localization, focus |

runtime, guidebook, upgrade card와 system sheet는 같은 descriptor를 재사용한다.
preview-only 대체 art를 만들지 않는다. visual geometry는 collision truth와
분리하되 projectile core boundary와 debug overlay로 그 차이를 검증한다.

### World

- field geometry, collision, navigation, cover selection, terrain schedule와
  deterministic fingerprint는 visual rework 때문에 바꾸지 않는다.
- floor는 field geometry와 layout fingerprint를 입력으로 하는 deterministic
  presentation tile compiler가 만든다. base grid는 `288×288` world unit이며
  `1×1`, `2×1`, `1×2`, `2×2` modular panel을 조합한다.
- tile은 walkable region에 clip되고 void에는 생성되지 않는다. variant와
  orientation은 `field_id`, layout fingerprint와 cell coordinate만으로
  결정하며 global RNG나 frame time을 사용하지 않는다.
- 12-unit gutter, chamfer, 낮은 대비 inset과 sparse service rail은 허용한다.
  random scratch와 combat cue보다 강한 high-frequency detail은 금지한다.
- void는 near-black mass와 sparse system edge만 가진다.
- blocker는 raised shell, floor-side light edge와 짧은 outer shadow를
  공통으로 사용한다.
- presentation-only decoration은 retained descriptor instance로 그리며
  field당 최대 24개다.
- facility는 장식보다 대비가 높고 shape가 고유하다.
  - repair: plus cut
  - transit: opposing chevron
  - overdrive: stacked forward chevron
  - arc surge: broken bolt rail
  - breakable bulkhead: split slab
- 세 field는 이름의 연상 소재가 아니라 gameplay topology에서 읽히는 panel
  rhythm으로만 구분한다.
  - Drowned Ruin: central court frame + orthogonal service plate
  - Tidal Archive: parallel bay spine + lateral corridor rail
  - Storm Drydock: basin frame + diagonal docking guide

### Actor, projectile 및 effect

- player는 이동 방향을 보여주는 hull front/rear cut과 manual-aim mount를
  분리한다.
- engine mount와 flame은 hull continuous transform의 rear child다. engine
  count는 rear socket의 좌우 배치만 바꾸며 angle을 따로 quantize하지 않는다.
- dash는 0.20초 동안 최대 5개 directional afterimage와 engine flare를
  사용한다. danger color 원, radial ring과 circular burst는 사용하지 않는다.
- reduced motion에서는 반복 afterimage 대신 0.12초 이하의 elongated
  silhouette 한 개와 engine flash를 사용한다.
- dash, hull hit, arrival, transit와 barrier를 서로 다른 semantic effect로
  표현한다. barrier만 support ring을 사용할 수 있다.
- ordinary enemy role은 외곽선과 negative space로 먼저 구분한다. command와
  boss는 boss color만으로 ordinary enemy를 재도색하지 않는다.
- projectile damaging core는 collision boundary와 일치한다. tail은 방향을
  설명하는 non-damaging cue다.
- telegraph는 gameplay이 제공한 exact live geometry를 사용하고 readiness는
  단조롭게 증가한다. warning이 뜬 뒤 origin, direction과 target을 장식
  animation으로 바꾸지 않는다.
- maximum pressure에서도 player, crosshair, committed threat, boss
  objective, pickup과 current target이 world decoration보다 먼저 읽혀야 한다.

### Typography, spacing 및 control

- font는 Noto Sans KR variable 한 family만 사용한다.
- body weight는 650, label/title는 800이다.
- compact type scale은 `13/15/17/22/30`, wide는
  `14/16/18/24/32/40`이다.
- spacing scale은 `4/8/12/16/24/32`다.
- panel inset은 compact `16`, wide `24`다.
- button, tab, toggle와 focus target의 최소 높이는 `44`다.
- body text는 `14` 미만으로 자동 축소하지 않는다.
- normal control은 1 px line, hover는 system rail, keyboard focus는 2 px
  system outline, selected는 3 px player/reward rail을 쓴다.
- destructive control은 danger text/outline을 쓰며 filled primary action과
  경쟁하지 않는다.
- surface에는 한 border와 한 semantic accent rail만 허용한다. 장식용
  corner와 중첩 frame을 반복하지 않는다.

### Responsive geometry

| viewport | outer safe margin | modal content maximum | mode |
| --- | ---: | ---: | --- |
| 960×540 | 16 | 928×508 | compact |
| 1280×720 | 24 | 1184×656 | wide |
| 1920×1080 | 32 | 1184×720 | wide centered |

- layout breakpoint는 width `1100`, guide/report three-column breakpoint는
  `1180`이다.
- upgrade card는 compact에서 `224–244×286`, gap `12`, wide에서
  `304×330`, gap `18`을 사용한다. title 2줄, summary 3줄, effect row 최대
  2개, optional behavior row와 level pip 1줄을 한 화면에 표시한다.
- upgrade card는 scroll을 사용하지 않는다. settings, guidebook, report는
  지정 content region만 scroll하고 primary action은 고정한다.
- `clip_contents`는 safety guard일 뿐 layout 해결책이 아니다.
- Korean과 English의 title, body, dynamic value, control label은 지원
  viewport에서 겹치거나 잘리거나 container 밖으로 나갈 수 없다.

### HUD

- top-left는 hull/experience와 `148×44` action rail을 묶는다. primary fire는
  rail에 넣지 않는다.
- top-center objective는 최대 `440×48`이다. boss가 active면 boss name,
  health와 one-line mechanic으로 교체하며 두 cluster를 쌓지 않는다.
- top-right minimap은 `176×108`, conditional target panel은 그 아래
  `176×60`이다.
- notification과 transition은 objective 아래 한 줄에 나타나며 crosshair를
  가리지 않는다.
- off-screen threat, status orbit, crosshair, minimap marker와 support timer는
  shape-coded retained mesh를 사용한다.

### Modal

- 모든 modal은 live HUD와 gameplay input을 차단하고 title, content,
  primary action 순서가 한 번에 읽혀야 한다.
- Deployment는 loadout/control과 difficulty/lock explanation의 two-column
  body, 한 개의 Deploy primary action을 사용한다.
- Upgrade는 세 structured card, explicit selection, Equip confirm과 optional
  decline을 사용한다. 상단과 card 안에 같은 detail을 중복하지 않는다.
- Pause는 Resume만 filled primary다. Restart/Settings는 secondary, Garage는
  restrained tertiary danger다.
- Settings는 category rail + content이며 Ship Status, audio, controls,
  motion, language 순서를 유지한다.
- Guidebook은 wide에서 category/list/detail 세 column, compact에서 category
  tab + list/detail 두 pane다. discovered preview는 runtime component,
  locked entry는 neutral silhouette를 쓴다.
- Report는 wide three-column, compact keyboard tab과 fixed bottom primary를
  사용한다.
- Result/Garage는 metric, build/loadout와 next action을 glyph로 요약한다.
- Boss Practice는 debug-only이지만 production boss descriptor와 Theme를
  재사용한다.

### 접근성 및 상태

- focus order는 visual/task order와 같고 keyboard/controller focus가 항상
  보인다.
- selected, disabled, warning, support와 affinity는 색만으로 전달하지 않는다.
- icon-only control은 localized accessible name과 동일한 input hint를 가진다.
- reduced motion은 정보량을 줄이지 않고 반복 movement만 정적 cue로 바꾼다.
- grayscale capture, text glyph bounds, focus path, 200% text fit과 supported
  viewport를 validation한다.

## Acceptance Criteria

`docs/design/component-sheets/system-v1/manifest.json`은 실제 provider
fingerprint, source commit, viewport, locale와 각 sheet SHA-256을 기록한다.
최종 12개 sheet는 foundation, world surface/facility, player, enemy, boss,
projectile/effect, reward/glyph, HUD/minimap, UI control, modal flow,
pressure/accessibility를 포함한다.

각 publication batch는 다음을 통과해야 한다.

- catalog ID coverage와 duplicate owner 0
- 같은 provider fingerprint에서 동일한 sheet hash
- approved reference와 runtime actor를 같은 scale로 비교한 sheet에서
  player, 8 role grammar와 boss proportion hierarchy가 같은 family로 판독
- ko/en × 960/1280/1920의 overflow, overlap, clipping 0
- 8개 upgrade family glyph의 card/sheet empty slot 0
- deterministic tile hash equality와 walkable/void containment
- grayscale role/affinity/state 구분
- engine 360° rear-anchor drift 0
- dash danger/radial instance 0
- combat batch ≤50, world batch ≤12, draw-call p95 ≤200
- full Godot import, focused validator, native/Web production smoke

## Non-Goals

- gameplay geometry, collision, actor count, speed, controls와 campaign flow를
  visual rework의 이유로 바꾸지 않는다.
- 특정 material/culture motif를 새 lore로 만들지 않는다.
- upgrade behavior를 UI가 해석하거나 pickup effect를 contact helper로
  이동하지 않는다.
- system sheet나 direction seed를 별도 runtime art owner로 사용하지 않는다.
