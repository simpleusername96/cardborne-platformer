---
type: spec
status: active
owner: BK
created: 2026-07-21
last_reviewed: 2026-08-08
canonical_for: Cardborne vehicle-game art direction and UI presentation
scope: All player-facing world, combat, HUD, modal, preview, and effect surfaces
related:
  - ../product/vehicle_game_spec.md
  - ./cardborne-universal-art-style-reference.png
  - ./visual-replacement-workbench/external-candidates/README.md
  - ../../.agents/semantic-v2-runtime-acceptance-evidence.md
---

# Cardborne 비주얼 시스템

## Purpose

이 문서는 Cardborne의 모든 player-facing surface에 적용되는 정본 visual
contract다. 실제 runtime truth는
`scripts/vehicle/vehicle_stage_visual_profile.gd`, 책임별 component catalog와
하나의 code-native Godot Theme가 소유한다. Provider-generated component and
system sheets are publication evidence for runtime coverage only; they do not own
art direction and cannot replace the authority pair below.

The mandatory visual authority is this complete text specification together with
`docs/design/cardborne-universal-art-style-reference.png`. The document owns the
binding rules; the sheet calibrates their visual application. Neither replaces
per-asset AS-IS/TO-BE review or exact approval.

## Mandatory Visual Authority Pair

Every task that creates, edits, generates, adapts, reviews, approves, promotes, or
switches a player-facing visual must use both of these sources before any visual
action:

1. Read this document completely in its current form.
2. Inspect `docs/design/cardborne-universal-art-style-reference.png` at its
   original `1448 x 1086` detail and verify SHA-256
   `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.

This preflight applies to assets, UI, HUD, world art, actors, projectiles, effects,
themes, layouts, mockups, screenshots, component/system sheets, ImageGen prompts
and outputs, workbench candidates, previews, reviews, approvals, and runtime
integration. For raster creation, editing, adaptation, or ImageGen, the canonical
PNG must be supplied to the tool as an actual image reference. A filename, text
description, palette transcription, previous inspection, or recovered copy is not
a substitute.

The sheet is **style reference only, never asset approval**. Do not crop, trace,
extract, copy, or inherit its specific objects, silhouettes, modules, glyphs, UI
shells, or layouts. In particular, its player example does not override the long,
sleek player proportions defined below. When a depicted example conflicts with
this document, the current text contract controls. Historical component sheets,
`system-v1` publications, generated previews, runtime captures, and recovered
resources are evidence at most and cannot replace either authority source.

Missing files, a sheet hash mismatch, absent visual inspection, or missing actual
image-reference evidence invalidates visual-compliance and asset-approval claims.
Record the authority paths, observed sheet hash, task-specific constraints, and
actual-reference use in the existing workbench, plan, approval, or handoff owner.

## Visual Authoring Prohibition

**SVG/ImageMagick geometric authoring is prohibited.** SVG or ImageMagick may not
draw, invent, reconstruct, repair, restyle, or complete any player-facing visual
content or review candidate. This includes silhouettes, filled planes, walls,
portal interiors, rings, arrows, markers, effect bodies, telegraphs, icons, UI
chrome, highlights, shadows, and other authored visual geometry.

ImageMagick is allowed only for mechanical operations that preserve existing
visual authorship:

- exact crop, resize, format conversion, and alpha handling of an already-authored
  raster;
- pixel comparison, dimension checks, hash verification, and other validation;
- placement of already-authored raster images and plain evidence labels in a
  contact sheet or report.

These allowed operations must not add, replace, or repair visual content. SVG is
not an accepted intermediate authoring surface or final player-facing candidate.
Historical SVG or ImageMagick-authored evidence may remain only when it is clearly
marked rejected or archived. A candidate made or repaired through the prohibited
workflow cannot receive visual approval and must be re-authored through a permitted
pipeline under the mandatory authority pair.

Existing runtime-owned code-native dynamic truth and Theme primitives keep the
ownership defined below. This prohibition does not authorize procedural world,
effect, actor, icon, or asset stand-ins.

## Scope

world, actor, projectile, reward, effect, HUD, modal, minimap, guidebook preview와
debug boss practice를 포함한 모든 player-facing surface에 적용한다. gameplay
rule과 collision truth는 각 기존 owner의 책임이며 이 문서는 표현만 정의한다.

## Requirements

### 디자인 방향

- 장르는 익숙한 top-down industrial/general SF다. 특정 문화, 재질, 해양,
  의례 motif를 제품 정체성으로 만들지 않는다.
- 월드의 고정 배경과 건축 theme는 **near-black outer space 안의 cool
  neutral-gray orbital hangar**다. 지도 기반은 장식 texture가 아니라 세 개의
  단색 역할로 먼저 읽힌다: 이동 가능한 surface는 light gray, 외곽 경계벽은
  black, 내부 구조벽은 dark gray다. 세 역할은 높이와 경계보다 색면 구분을
  우선하며 patterned panel, 어두운 HUD panel, 해저 기지나 장식성 service
  lane처럼 보이게 만들지 않는다.
- 형태는 큰 mechanical mass, 명확한 front/rear cut, 기능 module, sparse
  state accent 네 층으로 구성한다.
- 모든 형태는 antialiased hard-edged geometry를 사용한다. 고정 raster 방향
  frame, 미세 texture noise와 dither는 사용하지 않는다.
- ordinary component는 dark perimeter/separation, semantic main mass,
  secondary mechanical plane, restrained hard highlight 또는 inset의 3–5
  filled plane으로 구성한다. boss body도 같은 문법을 확대해 4–6개의 큰
  filled plane과 한 겹의 외곽선으로 제한한다. 미세 panel, 반복 lamp,
  nested outline과 greeble로 boss 등급을 표현하지 않는다.
- 모든 boss에서 방어막을 낮추는 외부 objective는 동일한 **보스 방어막
  노드** family를 재사용한다. boss마다 forge plate, segment lock, relay,
  route switch, lattice처럼 다른 장치 silhouette를 만들지 않는다. 노드는
  동일한 housing에서 `active → damaged → resolved` 상태만 바뀌며, 색뿐
  아니라 완전한 rail, 끊어진 rail, 열린 housing으로 상태를 구분한다.
- 짧은 한 방향 shadow, hard edge highlight와 얕은 inset은 승인 시안의
  기계적 깊이를 설명할 때 사용한다. soft glow, photoreal material,
  uncontrolled glossy effect와 반복 nested outline은 사용하지 않는다.
- world는 sparse, HUD는 cockpit-compact, modal은 information-first다.
  장식은 gameplay cue나 primary action과 같은 대비를 갖지 않는다.
- motion은 이동, state change, impact와 objective만 설명한다. ambient
  pulse, 반복 flashing과 의미 없는 orbit 장식은 금지한다.

#### 승인된 아트 스타일 문법

승인된 방향은 **전술적 가독성과 친근한 산업 SF 볼륨의 결합**이다.
`Into the Breach`에서는 한눈에 읽히는 큰 실루엣, 제한된 색면과 역할 대비를,
`Astroneer`에서는 둥글게 정돈된 공업 형상, 부드러운 bevel과 명확한 재질
분리를 참조한다. 두 작품의 특정 기체, 부품, 아이콘이나 UI 모양을 복제하지
않고 아래의 추상 문법만 Cardborne 고유 형상에 적용한다.

모든 asset과 UI는 다음 순서로 단순화한다.

1. gameplay 역할을 먼저 한 문장으로 고정한다.
2. 역할을 1× scale에서도 설명하는 dominant silhouette 하나를 만든다.
3. 기능을 실제로 구분하는 보조 module은 최대 두 개만 남긴다.
4. matte main mass, light plane, shadow plane, dark perimeter의 큰 색면으로
   깊이를 만들고 선으로 면을 쪼개지 않는다.
5. semantic accent는 상태나 방향을 설명하는 한 곳에만 사용한다.
6. 최종 크기와 grayscale에서 silhouette, facing과 state를 다시 검증한다.

작은 원과 rivet, 기능 없는 panel seam, 반복 lamp, 동심원, nested frame,
무작위 scratch와 설명할 수 없는 greeble은 넣지 않는다. 경계선은 서로 다른
mass를 분리하거나 실제 상태를 표시할 때만 사용하며, 이미 색면으로 구분된
영역을 다시 장식선으로 감싸지 않는다.

The canonical style-reference sheet is required evidence for proportion, plane
count, edge treatment, detail density, and contrast. Its individual silhouette,
module, glyph, icon, ornament, and layout remain non-binding examples. **Art-style
alignment is not individual asset approval.** Runtime replacement still requires
an asset-specific AS-IS/TO-BE comparison and separate exact approval.

플레이어 기체는 같은 문법 안에서도 별도 비례 규칙을 가진다. 폭보다 길고,
전방으로 수렴하며, swept-back edge와 negative space로 낮고 민첩한 인상을
만든다. 둔중한 capsule, tank 또는 toy-rover 실루엣은 사용하지 않는다.
하나의 authored craft body가 선체, 고정 engine housing과 고정 weapon housing을
함께 소유한다. craft body는 이동 방향을 설명하고 manual aim은 cursor, muzzle,
projectile 방향과 hit feedback으로 독립적으로 설명한다. dash flare와 afterimage는
수명과 transform이 다르므로 craft body에 합치지 않는 transient effect다.

### Semantic token

`VehicleStageVisualProfile`이 아래 색과 scale의 유일한 runtime owner다.
world, combat, minimap, Theme와 sheet는 literal role color를 다시 선언하지
않고 이 token을 소비한다.

| token | 값 | 의미 |
| --- | --- | --- |
| `space_black` | `#070B11` | exterior/absolute void |
| `world_canvas` | `#101923` | walkable base |
| `surface` | `#182431` | panel과 floor plate |
| `raised` | `#243445` | inner structure, facility, raised UI |
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
| `map_surface_fill` | `#9EADBC` | walkable map surface flat fill |
| `map_outer_wall_fill` | `#070B11` | outer boundary flat fill |
| `map_inner_wall_fill` | `#243445` | run-selected inner-wall flat fill |

색은 identity의 보조 수단이다. role, affinity, selected, locked와 support
state는 silhouette, notch, rail pattern 또는 glyph 중 하나를 함께 사용한다.
grayscale에서도 외곽선과 negative space만으로 주요 역할을 구분해야 한다.

### Component 및 catalog contract

각 visual ID는 정확히 한 catalog가 소유한다.

| owner | 책임 | 금지 |
| --- | --- | --- |
| gameplay cue catalog | reusable authored cue texture, pivot, and stretch/tint contract | gameplay rule, collision, live dimension |
| actor catalog | authored body role, state, anchor, silhouette | health, AI, attack |
| projectile catalog | separate authored player-primary, player-seeker, and hostile-bolt identities with pivots | damage, range, hit rule, affinity tint, and scale |
| reward catalog | authored pickup, shard, and crate visual ID plus value-scale mapping | spawn, value, collection |
| effect catalog | three buffered transients only: dash afterimage, live EMP charge radius, and authored EMP release | timer, damage, protection rule, direct actor/HUD/audio feedback |
| world catalog | authored hazard, Transit Gate, Mystery Device, reinforcement facility, and state descriptor | topology, collision, exposure, health, spawn cadence, outcome |
| secondary catalog | authored seeker, drone, blade, mine presentation identity | targeting, cadence, damage |
| defense catalog | shared authored support-ring image and localized status text recipe | protection, damage, slow, stack, timer |
| UI glyph catalog | code-native action, minimap, and preview glyph | layout, localization, focus |
| semantic asset provider | approved persistent gameplay raster texture, including upgrade content art, pivot, and attachment | collision, behavior, map topology, live descriptor |

Runtime, guidebook, upgrade card, and system sheet reuse the same semantic descriptor.
Register authored raster identities only in
`art/visuals/production/gameplay/asset-manifest.json` and the semantic asset provider.
The responsible catalog owns retained UI action/minimap/preview code-native recipes,
while upgrade content art reuses semantic PNGs. Do not create preview-only art.
Keep visual geometry separate from collision truth and verify the difference with the
projectile core boundary and debug overlay. The semantic-v2 provider also indexes shared
floor/wall presentation textures, while field geometry continues to own topology and
collision.

#### Media ownership boundary

- player, ordinary enemy, boss, secondary body, three projectile roles,
  pickup, reward crate, Transit Gate, hazard ground, Mystery Device, reinforcement
  facility, common boss
  node처럼 **게임 월드에 독립된 대상으로 등장하는 것은 완성된 authored
  PNG**를 사용한다. runtime은 이 image의 transform, scale, tint와 state
  선택만 소유한다. field topology와 정확히 같은 surface/outer-wall/inner-wall
  단색 mesh는 독립 object가 아니라 geometry truth의 retained presentation이므로
  이 raster 규칙의 예외다.
- Upgrade-card content artwork is also authored PNG content. It is one reusable
  semantic identity per shared mechanic group and is rendered by the semantic
  asset provider; the card never draws a mechanic glyph procedurally.
- HUD action glyph, minimap marker, and preview marker remain shared code-native UI geometry.
  Combat cues, target brackets, telegraph boundaries, and beam/radius corridor fixed
  visual identities use shared authored PNGs; runtime owns live position, length, width,
  radius, rotation, tint, alpha, and readiness.
- A projectile is an independent world object. Player primary, built-in Seeker,
  and hostile non-beam shots have separate authored PNG identities. The Seeker
  image is exclusive to homing Seeker shots and the hostile bolt is not reused by
  player weapons. Runtime applies facing, the reduced presentation scale, and
  selected-element tint to player-primary shots.
- barrier, ion, shield source와 burn/poison/chill은 별도 raster asset을 갖지
  않는다. 보호와 범위는 shared authored ring과 runtime tint/scale로 전달한다.
  작은 속성 actor effect와 damage number는 표시하지 않고, 필요한 지속 상태는
  localized target-status text로만 전달한다. cosmetic emitter, plate, orbit icon은
  gameplay truth가 아니므로 만들지 않는다.
- 경험치 pickup의 small/medium/large는 하나의 authored XP master PNG를
  각각 표시 반지름 `17/20/23`으로 scale/value를 표현한다. 이는 이전 표시
  크기에서 약 30% 줄인 값이다. reward crate, repair pickup과 experience recall은
  gameplay 역할과 silhouette가 다르므로 각각의 PNG를 유지한다.
- toxic bog와 lava pool은 같은 hazard-ground footprint family다. 각각 toxin과
  thermal 색을 넓은 바닥 면으로 사용하며 얇은 curtain, node, pylon 또는 벽처럼
  세우지 않는다. Mystery Device는 crate보다 큰 `intact` body와 효과가 anchor를
  필요로 할 때만 유지하는 `resolved` wreck state를 가진다. 결과 종류는 파괴
  전 image, 색, lamp, glyph로 암시하지 않는다.
- boss별 objective module art는 금지한다. 공통 node의 `active`, `damaged`,
  `resolved` authored 상태 세 개만 유지하고 module kind/index는 gameplay
  owner가 계속 보존한다.
- EMP는 유일하게 유지하는 대형 effect이며 transparent `512×512` authored
  PNG 하나를 gameplay radius에 맞춰 scale/fade한다. 나머지 작은 effect image와
  raster frame animation은 현재 production visual owner가 아니다. 필수 hit/
  state truth는 actor tint, state swap, live boundary 같은 기존 직접 피드백으로
  유지하고 별도의 suppressed cosmetic event ID도 보관하지 않는다. 미래 polish도 별도
  media-boundary 승인을 받지 않는 한 one-file-per-frame pack을 복원하지 않는다.
- 실제 consumer가 없는 image는 미래 가능성만으로 production에 보관하지
  않는다. 필요가 제품 요구사항으로 생기면 semantic contract부터 다시
  정의한다.

#### External source asset contract

- 외부 asset은 라이선스, 공식 source URL, 원본 archive hash와 선택한 source
  file hash가 기록된 경우에만 review source로 반입한다. pack 전체를 production
  tree에 복사하지 않는다.
- CC0 source라도 원본 palette, camera, outline과 detail을 그대로 runtime에
  사용하지 않는다. 필요한 silhouette만 선별한 뒤 Cardborne의 top-down facing,
  canvas/pivot, 3–5 large planes, dark perimeter와 semantic palette로 정규화한
  완성 PNG를 새 TO-BE deliverable로 만든다.
- 외부 source PNG, 3D model, preview와 contact sheet는 승인된 production asset이
  아니다. exact AS-IS/TO-BE 비교와 hash approval을 통과한 adapted PNG만
  production manifest로 승격할 수 있다.
- attribution이 의무가 아니어도 source와 license record는 repository에 남긴다.
  provider logo, pack branding과 무관한 decorative motif는 사용하지 않는다.

### Semantic categories

| 표시 역할 | 시각 계약 | gameplay/collision owner |
| --- | --- | --- |
| 이동 surface | `#9EADBC` 단색의 light-gray full-bleed 면, per-tile frame과 기능 없는 문양 없음 | field geometry |
| 외곽 경계벽 | `#070B11` 단색 black mass | field boundary와 collision |
| 내부 구조벽 | `#243445` 단색 dark-gray mass; 직선/L/T/step group을 같은 역할로 표시 | tactical layout, collision와 LOS |
| 위험 지대 | 넓고 낮은 swamp/lava ground 면; exact effect rect를 채우며 벽·curtain·작은 node처럼 보이지 않음 | hazard exposure runtime |
| 순간이동 게이트 | 완전한 원형 floor portal과 active interior | paired transit dwell/cooldown |
| 미확인 장치 | 상자보다 큰 neutral mechanical body; 파괴 전 결과를 숨기고 파괴 후 resolved state만 표시 | device health와 hidden outcome |
| 증원 조립소 | 넓은 적대 시설 body와 상시 체력 표시; 일반 적과 다른 미니맵 표식 | 별도 facility health, 가동 임계점, 소환 주기와 상한 |
| 보상 상자 | amber body, lock seam과 파손 가능한 contour | crate health와 drop |
| 픽업 | 작고 밝은 role-coded silhouette | pickup value와 collection |

별도 엄폐물, Arc Surge, Wear Collapse Tile, repair/overdrive floor pad와
Breakable Bulkhead는 현재 product category가 아니다. 증원 조립소는 승인된
별도 stationary facility category다. 내부 구조벽·위험 지대·게이트·미확인
장치·증원 조립소·보상 상자·픽업을 서로
바꿔 부르거나 같은 silhouette로 합치지 않는다.

### World

- field geometry, collision, reachability, inner-wall selection, hazard placement와
  deterministic fingerprint는 같은 layout owner를 사용한다. presentation image는
  topology, collision, exposure, health 또는 hidden outcome을 소유하지 않는다.
- walkable polygon은 `map_surface_fill` 한 색면으로 채운다. tile grid, panel
  variant, gutter, chamfer, inset, seam, scratch와 decorative rail을 표시하지 않는다.
- outer boundary segment는 `map_outer_wall_fill`, run-selected inner-wall rectangle은
  `map_inner_wall_fill`로 그린다. outline, bevel, shadow와 patterned raster를
  덧붙이지 않는다. inner wall은 straight/L/T/step shape가 달라도 같은 단색
  역할을 유지한다.
- toxic bog와 lava pool은 exact gameplay rectangle을 채우는 authored full-bleed
  ground PNG다. 네 구역의 폭은 모두 최소 480 world unit이며 얇은 beam, curtain,
  fence, lane marker 또는 작은 node로 보일 수 없다. Bog는 toxin, lava는 thermal
  large plane을 사용하지만 danger projectile보다 높은 밝기나 빠른 animation을
  갖지 않는다.
- Mystery Device는 reward crate보다 크고 neutral/dark mechanical mass가 지배하는
  exact `192×192` authored body다. 한 개의 restrained system accent만 허용하며
  파괴 전에는 네 결과의 색, glyph, 방향, animation을 노출하지 않는다. 파괴 후
  anchor가 필요한 동안만 resolved wreck를 표시하고 결과 이름은 localized text가
  전달한다.
- Transit Gate는 complete circular floor portal을 유지한다. gate는 movement-only,
  hazard는 damage ground, Mystery Device는 destructible interaction이므로 세
  silhouette를 공유하지 않는다.
- reinforcement facility는 enemy actor catalog를 재사용하지 않는 완성된
  `256×256` authored body다. 가동 중에만 world에 나타나고, 시설 체력 bar와
  two-tone diamond minimap marker가 사용자의 파괴 목표를 전달한다.
- 상자, loose pickup, hazard와 Mystery Device는 넓은 role-color 면과 dark contour를
  사용해 서로와 무기 공격을 즉시 구분한다. 작은 accent color만으로 역할을
  표시하지 않는다.
- 세 field의 시각 차이는 별도 floor pattern이 아니라 실제 walkable topology와
  run-selected wall/hazard arrangement에서만 나온다.

### Actor, projectile 및 effect

- player는 이동 방향을 보여주는 하나의 craft body와 independent manual-aim
  cue를 분리한다. 고정 engine/weapon housing은 craft body geometry에 포함하며
  별도 authored engine 또는 aim-mount texture를 사용하지 않는다.
- player craft presentation radius는 `35`이며 collision radius `24`와 분리한다.
  이는 이전 표시 크기에서 30% 줄인 값이다.
- craft body는 hull transform만 따르고 aim input으로 회전하지 않는다. cursor,
  muzzle origin/flash, projectile와 hit feedback은 aim direction을 따른다.
  idle과 일반 이동에는 flame을 표시하지 않고 dash 동안에만 rear anchor에서
  flare를 표시한다.
- dash는 0.20초 동안 directional afterimage 한 개와 engine flare를
  사용한다. danger color 원, radial ring과 circular burst는 사용하지 않는다.
- reduced motion에서도 같은 한 개의 elongated silhouette와 engine flash만
  사용하고 추가 반복 또는 폭발 장식을 만들지 않는다.
- hull hit는 actor tint, barrier hit는 기존 support ring의 짧은 밝기 변화,
  arrival과 transit는 actor/world state가 직접 표현한다. 이 항목을 transient
  effect event로 복제하지 않는다.
- ordinary enemy role은 외곽선과 negative space로 먼저 구분한다. command와
  boss는 boss color만으로 ordinary enemy를 재도색하지 않는다.
- 비-beam projectile은 player primary energy teardrop, built-in Seeker, hostile
  barbed bolt 세 identity를 사용한다. 세 identity는 서로 재사용하지 않으며,
  불투명 core와 authored contour가 small runtime scale에서도 역할을 구분한다.
- 모든 기체 탄환의 presentation length는 이전 기준의 `0.70`, thickness는 `0.50`을
  적용한다. 이 transform은 collision truth를 바꾸지 않는다. player primary는
  선택한 단일 element affinity tint를 사용하고 Seeker와 hostile bolt는 authored
  identity를 유지한다. cadence, speed, homing, collision과 damage는 gameplay code가 소유한다.
- hostile thermal/toxin/cryo/arc hue는 direct-damage affinity이며 현재 존재하지
  않는 persistent condition을 약속하지 않는다. burn/poison/chill은 별도
  projectile badge나 orbit icon 없이 실제 actor state feedback으로만 표시한다.
- projectile startup과 이미 생성된 projectile은 발사원 가시성과 관계없이
  예측 경로 또는 진입선을 표시하지 않는다. 화면 밖 발사원의 공격은 threat
  radar가 방향만 전달하고 실제 projectile body가 화면에 들어온 뒤부터 world에
  표시한다. full committed path는 beam에만 사용하고 charge는 locked endpoint
  cap만 사용한다. charge 이동 경로의 side boundary는 표시하지 않는다.
- beam은 gameplay corridor가 길이와 폭을 소유하고 shared authored beam-strip
  PNG를 그 live rectangle에 stretch한다. projectile PNG를 corridor 길이로
  늘이지 않으며, startup/end contact 같은 작은 cosmetic frame은 만들지 않는다.
- telegraph는 gameplay이 제공한 exact live geometry를 사용한다. hostile area는
  affinity와 무관한 danger outer boundary 한 개, charge는 endpoint cap, beam은 두
  corridor boundary와 endpoint cap만 유지한다. affinity별 inner ring, diamond,
  center line, tick bar와 commit marker는 만들지 않는다. readiness는
  단조롭게 증가하며 warning이 뜬 뒤 origin, direction과 target을 장식
  animation으로 바꾸지 않는다.
- threat radar는 world cue로 아직 보이지 않는 committed projectile attack,
  active boss objective와 boss arrival만 표시한다. 일반 off-screen enemy 위치는
  minimap이 소유하며 radar에서 중복하지 않는다. world 경로와 radar contact는
  같은 공격을 동시에 표시하지 않는다.
- maximum pressure에서도 player, crosshair, committed threat, boss
  objective, pickup과 current target이 world decoration보다 먼저 읽혀야 한다.
- 조준 대상, 피격 대상 또는 일시적 취약 상태라는 이유로 적 본체에 노란
  bracket, crosshair, ring 또는 route overlay를 붙이지 않는다. manual-aim cursor는
  적 상태와 독립된 system-color cue이며, 보스 OPEN 상태와 활성 objective도
  authored body, HUD와 체력 정보로 전달하고 player-reward overlay를 사용하지 않는다.
- boss body의 고유성은 전체 silhouette와 큰 mass 비율이 소유한다. 외부
  방어막 노드는 boss별 장식이 아니라 공통 gameplay 언어이므로 body와
  독립된 같은 크기·pivot·상태 family를 사용한다.
- EMP는 one-shot authored `512×512` PNG의 중심과 실제 gameplay radius를
  일치시키고 짧은 scale/fade만 적용한다. 여러 ring, spark, dot, noise와
  frame-by-frame sprite sequence를 추가하지 않는다.

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

### Shared code-native UI composition

- production UI chrome은 하나의 `vehicle_stage_theme.tres`와
  `VehicleUiComponentFactory`가 소유한다. 화면 script는 hierarchy, copy,
  signal과 state만 소유하며 local `StyleBox`나 screen-specific chrome을
  만들지 않는다.
- 공용 primitive는 Surface, TextRow, Command, Selectable, Meter와 PreviewWell
  여섯 개다. 같은 역할은 모든 HUD와 modal에서 같은 geometry, spacing과
  state skeleton을 재사용한다.
- surface는 한 flat fill, 최대 한 1 px boundary와 필요한 경우 한 semantic
  rail만 사용한다. command, selectable, meter와 preview state는
  `StyleBoxFlat`, `StyleBoxLine`, `StyleBoxEmpty`, typography와 spacing resource로
  구성한다.
- normal, hover, pressed, focus, selected와 disabled는 color뿐 아니라 2 px
  focus outline, 3 px selected rail, boundary 또는 구조 변화로 구분한다.
- craft, upgrade family, enemy, boss, object, minimap과 action imagery는
  gameplay semantic provider의 의미 있는 content로 유지한다. UI chrome PNG,
  UI image-state manifest와 별도 UI image provider는 사용하지 않는다.
- localized text, gameplay icon, dynamic value, focus target과 accessibility
  state는 Godot `Control` child가 소유한다. text, icon 또는 임의 숫자를
  background나 preview image에 굽지 않는다.
- procedural 표현은 다음 동적 truth와 단순한 code-native UI chrome에
  허용한다.
  - collision과 일치하는 attack radius, beam/charge corridor, mine boundary
  - HP, cooldown, progress와 fuse의 실제 ratio 또는 clip
  - target/off-screen vector와 floating/localized text
  - screen dim, invisible layout container와 debug collision overlay
- 의미 없는 panel seam, dot, lamp, corner, badge, pip, nested frame과 selection
  ornament를 추가하지 않는다. 이미 spacing, fill 또는 rail로 구분한 영역을
  다시 decorative line으로 감싸지 않는다.

### Responsive geometry

| viewport | outer safe margin | modal content maximum | mode |
| --- | ---: | ---: | --- |
| 960×540 | 16 | 928×508 | compact |
| 1280×720 | 24 | 1184×656 | standard |
| 1920×1080 | 32 | 1376×720 | large centered |

- layout breakpoint는 width `1100`, large upgrade breakpoint는 `1600`,
  guide/report three-column breakpoint는 `1180`이다.
- upgrade card는 compact에서 `280×378`, gap `12`, standard에서 `360×456`,
  gap `16`, large에서 `420×480`, gap `24`를 사용한다. 세 카드 container는
  사용 가능한 공간에 맞춰 확장하며 standard에서 좁은 352px 카드를 유지하지
  않는다. 순서는 centered family, title, artwork, level, 실제 effect row의
  vertical stack이다. dossier uses compact `88×88`, standard `112×112`, and large
  `128×128` centered artwork. level 아래에는 실제 효과를 요약한 localized 한 줄
  설명을 표시한다. 한국어는 공백 포함 약 10자, 영어는 2–5단어를 기준으로 하며
  supported viewport에서 한 줄을 넘지 않는다. change-kind 문장, description
  footer와 split column은 표시하지 않는다. 첫 획득만 작은 code-native unlock
  diamond로 표시한다.
  title 위 반복 image, badge와 level text를 반복하는 단계 pip는 사용하지
  않는다. Seeker와 선택형 secondary upgrade는 같은 `보조 무기 / Secondary
  Weapons` family label을 사용하고 title이 실제 subtype을 식별한다.
- upgrade card 자체는 scroll을 사용하지 않는다. 200% text scale에서만 세
  card를 담는 offer body가 하나의 outer vertical scroll을 가질 수 있으며,
  card는 `520×920`을 사용하고 Equip primary action은 fixed 상태를 유지한다.
  settings, guidebook, report는 지정 content region만 scroll하고 primary
  action은 고정한다.
- `clip_contents`는 safety guard일 뿐 layout 해결책이 아니다.
- Korean과 English의 title, body, dynamic value, control label은 지원
  viewport에서 겹치거나 잘리거나 container 밖으로 나갈 수 없다.

### HUD

- top-left는 hull/experience, top-center는 objective와 conditional boss,
  top-right는 `176×108` minimap과 conditional target을 소유한다.
- minimap의 dynamic marker는 player craft, item, enemy, boss, reinforcement facility
  다섯 역할만 사용한다.
  item/enemy/boss subtype, elite/stationary distinction, objective state와 support
  field를 별도 marker로 표시하지 않는다. explored static geometry와 fog는 유지한다.
- bottom-center에는 panel이 없는 확대 원형 EMP indicator 하나만 둔다. cooldown과
  enabled/disabled 상태만 표시하며 primary, dash, secondary slot은 만들지 않는다.
- 각 zone은 최대 한 subtle Surface만 사용한다. full-width dock,
  ornamental edge frame과 서로 다른 screen-specific panel silhouette는
  사용하지 않는다.
- notification과 transition은 objective 아래 한 줄 ToastSurface에 나타나며
  crosshair를 가리지 않는다.
- HUD off-screen threat와 다섯 종류 minimap marker는 기존 code-native retained
  mesh를 유지한다. world-space crosshair는 shared authored PNG retained textured
  batch로 배치한다. persistent-status orbit과 support timer는 사용하지 않는다.

### Modal

- 모든 modal은 live HUD와 gameplay input을 차단하고 title, content,
  primary action 순서가 한 번에 읽혀야 한다.
- Deployment는 loadout/ship preview와 complete control information의
  two-column body를 사용한다. Deploy primary, Settings secondary와 debug-only
  Boss Practice secondary는 한 개의 flat horizontal action row에 놓는다.
  difficulty selector나 lock explanation은 없다.
- Upgrade는 별도 kicker, screen title 또는 instruction header 없이 세
  structured Selectable card와 explicit selection, Equip confirm만 사용한다.
  각 card는 title 아래 관련 artwork 한 개만 가지며 Leave, Exit, Skip 또는
  decline action은 없다.
- Pause는 Resume, Restart, Settings, Garage의 equal-width vertical stack을
  사용한다. Resume만 filled primary이고 Garage는 restrained danger다.
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

각 publication batch는 다음을 통과해야 한다.

- catalog ID coverage와 duplicate owner 0
- 같은 provider fingerprint에서 동일한 sheet hash
- approved reference와 runtime actor를 같은 scale로 비교한 sheet에서
  player, 8 role grammar와 boss proportion hierarchy가 같은 family로 판독
- ko/en × 960/1280/1920의 overflow, overlap, clipping 0
- all 10 shared upgrade semantic artwork identities resolve with no missing slot,
  no image appears above a card title, and every card body has exactly one artwork
- 5개 boss body가 1× runtime scale에서 큰 silhouette와 4–6개 plane으로
  판독되고, boss-specific 방어막 장치 asset이 0이며 공통 노드의
  active/damaged/resolved 상태만 사용됨
- exact approval 뒤 final gameplay manifest가 정확히 73 PNG를 색인함. 전용
  hostile bolt와 reinforcement facility를 포함하며, candidate/intermediate는
  production manifest에 포함하지 않음
- HUD/minimap/UI PNG와 EMP 이외의 frame animation raster가 0이며, 모든
  외부-source derivative의 license/source/hash 기록이 완전함
- deterministic layout/presentation hash equality와 walkable/void containment
- grayscale role/affinity/state 구분
- 8 hull direction × 8 aim direction에서 craft-body transform drift 0,
  independent cursor/muzzle/projectile cue mismatch 0
- dash danger/radial instance 0
- combat batch ≤50, world batch ≤12, draw-call p95 ≤200
- full Godot import, focused validator, native/Web production smoke

현재 semantic-v2 runtime acceptance와 미통과 performance gate는
`.agents/semantic-v2-runtime-acceptance-evidence.md`에 기록한다. 성공한
Web export만으로 interactive built-Web smoke나 release performance를
통과한 것으로 간주하지 않는다.

### Current implementation notes

- Field topology and wall collision remain code-owned; shared surface and wall
  PNGs are fitted inside that truth and never become a
  second topology owner.
- Walkable surface, outer wall, and inner wall render as the three flat map-role
  fills without legacy patterned floor or shared-wall rasters.
- Hazard and Mystery Device gameplay and their four approved raster assets are
  integrated. Candidate and intermediate files stay outside the production
  manifest.
- Every non-beam projectile resolves one of the three exclusive player-primary,
  player-seeker, or hostile-bolt identities; runtime owns scale, rotation,
  player-primary affinity tint, collision, speed, and homing.
- The integrated player craft, XP master, four secondary bodies, three
  projectile roles, pickups, current approved facilities, five bosses, three shared
  boss-node states, EMP image, and four map assets remain the applied set.
- Manual aim remains readable through independent cursor, muzzle, projectile,
  and hit feedback. The player rear anchor is used only by transient dash
  feedback.

## Non-Goals

- gameplay geometry, collision, actor count, speed, controls와 campaign flow를
  visual rework의 이유로 바꾸지 않는다.
- 특정 material/culture motif를 새 lore로 만들지 않는다.
- upgrade behavior를 UI가 해석하거나 pickup effect를 contact helper로
  이동하지 않는다.
- system sheet나 direction seed를 별도 runtime art owner로 사용하지 않는다.
