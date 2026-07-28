---
type: plan
status: active
owner: BK
created: 2026-07-28
last_reviewed: 2026-07-28
scope: Replace Cardborne's current flat world and UI presentation with the approved space-hangar image-asset system while preserving gameplay and live UI truth
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../visual-system-design-selection-plan.md
  - ./2026-07-27-pixel-art-visual-recovery.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../pixel-art-production/README.md
  - ../../pixel-art-production/assets/asset-inventory.json
---

# Cardborne 인게임·UI 이미지 에셋 통합 실행 계획

선택된 우주 격납고 시안의 재질과 화면 구성을 실제 게임에 적용한다.
월드는 `geometry truth → raster asset template → live state overlay`, UI는
`raster chrome → safe-inset template → live Control overlay`의 세 층으로
바꾼다. 기존 전투, 충돌, 카드, 입력, 한·영 텍스트는 보존하고, 스크립트가
장식 픽셀을 그리는 경로는 승인된 이미지 에셋 조립 경로로 교체한다.

## Why / Context

현재 실제 화면은 넓은 ivory 바닥과 사각형 blocker, ivory modal,
단색 `StyleBoxFlat` 버튼과 카드로 구성된다. 기능과 레이아웃은 동작하지만
선택된 우주 슈팅 시안의 near-black space, graphite chassis, cool blue-gray
deck, cobalt rail, mint inner rim이 월드와 UI에 공유되지 않는다.

승인된 방향 기준은 다음 이미지다.

`C:\Users\BK\.codex\generated_images\019fa732-bd99-7cb3-8c2b-bacadc225fae\call_fNU2GdTyzih0wzwInUvEEC1y.png`

이 이미지는 완성 런타임 배경으로 사용하지 않는다. 재질, 색, 프레임,
정보 밀도, HUD 배치의 승인 기준으로 사용하고 실제 결과는 반복 타일,
connected edge, fixture, UI chrome으로 분해해 제작한다.

## Purpose

- **Objective:** 맵, 지형지물, actor readability, HUD, modal, card, button을
  하나의 우주 격납고 이미지 에셋 문법으로 통합한다.
- **First user-visible artifact:** 실제 현재 레이아웃에 승인 후보 에셋을
  합성한 인게임, 일시정지, 업그레이드, 차고 검토 이미지 네 장.
- **First live vertical slice:** 한 필드의 safe-arrival/maximum-pressure,
  gameplay HUD, 일시정지 화면이 같은 승인 에셋을 사용하는 실행 빌드.
- **Completion state:** 모든 대상 surface가 승인된 raster asset을 사용하고,
  텍스트·수치·입력·정확한 gameplay range는 live state로 남으며,
  migrated surface에 장식용 `StyleBoxFlat` 또는 코드 도형 fallback이 없다.

## Scope / Non-scope

In scope:

- map floor, void, wall, connected edge, static prop, functional fixture,
  actor/effect presentation;
- gameplay HUD, pause, upgrade, garage, deployment, settings, guidebook,
  report, result, card, button, tab chrome;
- image-generation source, pixel cleanup, world template, UI safe-inset/state
  template, runtime publication, rendered evidence, validators;
- the user-approved screenshot-layout correction that places the four-slot
  action rail in the bottom-center outer chassis instead of the current code's
  top-left position.

Out of scope:

- combat, movement, collision, navigation, spawn, encounter, card behavior,
  balance, save data, audio, input bindings, or localization-copy changes;
- any other HUD information removal, menu action, modal flow, or information
  architecture change;
- using a generated full-screen image as gameplay geometry or a text-bearing
  image as live UI.

Destructive or irreversible actions:

- none. Each runtime replacement remains gated and recoverable through scoped
  commits.

Exact user approval still required:

- the four Phase 1 assembled images must be accepted before runtime
  publication. This is an asset-quality gate, not a new style-selection gate.

## Pre-plan Evidence Already Verified

| Source or path | Verified fact | Locked consequence | Recheck boundary |
| --- | --- | --- | --- |
| 선택 이미지 `call_fNU…png` | near-black space, graphite structure, blue-gray deck, cobalt rail, mint outline, dark HUD surface가 한 화면에 결합되어 있다. | 이 이미지를 유일한 시각 방향으로 사용한다. | 에셋 검토와 final side-by-side |
| `build/captures/final-ko-1280/10-field-storm-drydock-field.png` | 현재 화면은 ivory floor와 단순 사각형 blocker가 우세하다. | gameplay topology는 보존하고 visible material만 교체한다. | 첫 live vertical slice |
| `build/captures/final-ko-1280/90-pause.png` | pause는 큰 ivory panel과 단색 버튼이다. | 같은 기능을 dark image-backed modal과 button으로 교체한다. | pause capture |
| `build/captures/final-ko-1280/06-level-up-choice.png` | upgrade는 ivory modal과 세 장의 단색 card다. | 세 카드 정보 구조를 보존하고 image-backed card state를 적용한다. | 91-card ko/en matrix |
| `build/captures/final-ko-1280/94-garage.png` | garage는 넓은 빈 ivory surface와 긴 텍스트 흐름이다. | 기존 정보와 행동을 section plate와 dark modal로 재구성한다. | garage capture |
| `scripts/presentation/vehicle_pixel_world_mesh_builder.gd` | floor/water/cover 이미지는 gameplay geometry가 공급하는 polygon에만 적용된다. | geometry owner를 유지하고 topology-aware visual template을 추가한다. | world renderer validator |
| `scripts/vehicle/vehicle_run.gd::_draw_terrain()` | fixture asset과 장식용 코드 도형, 정확한 state geometry가 혼재한다. | 고정 몸체·장식은 raster asset, exact area/progress는 live overlay로 분리한다. | terrain validator |
| `art/ui/production/vehicle_stage_theme.tres` | modal, card, button, tab, band가 모두 `StyleBoxFlat`이다. | visible chrome을 `StyleBoxTexture`로 교체한다. | UI chrome validator |
| `scripts/ui/vehicle_stage_ui.gd` | HUD와 modal 조립, 반응형 크기, 한·영 live Control이 이미 존재한다. | 화면 흐름은 유지하고 shell factory만 분리한다. | layout/localization validators |
| `pixel-art-production/README.md` | grid snap, palette, semantic mask, exact reassembly, atlas, review 절차가 존재한다. | ImageGen 결과는 raw evidence이며 deterministic cleanup 뒤에만 runtime으로 간다. | per-asset build |
| `pixel-art-production/assets/asset-inventory.json` | `ui_frame_system`이 현재 `procedural_pixel/direct_pixel`이다. | 이를 image-generated raster chrome으로 바꾼다. | inventory validator |

## Locked Decisions

| Topic | Final decision | Rationale |
| --- | --- | --- |
| Visual direction | 선택 이미지의 space-hangar composition과 material grammar를 사용한다. | 사용자가 현 시안 중 최종 방향으로 선택했다. |
| Layout source | 현재 실제 화면의 정보와 입력 흐름을 보존한다. 사용자가 current screenshot layout을 요구하고 선택 이미지도 이를 유지했으므로, action rail의 bottom-center outer-chassis 배치만 명시적 예외로 적용한다. | 스타일이 바뀌어도 게임 사용법은 바뀌지 않으며 승인된 composition을 재현한다. |
| World ownership | gameplay geometry가 floor, void, wall, blocker, opening의 진실이다. 이미지나 alpha는 collision을 소유하지 않는다. | 기존 제품 불변 조건이다. |
| World composition | `geometry snapshot → VehicleWorldVisualTemplate → VehiclePixelWorldMeshBuilder`로 static art를 만들고, runtime state는 별도 overlay가 그린다. | 이미지와 gameplay truth를 분리한다. |
| UI ownership | PNG chrome이 외형을, Theme/factory가 safe inset과 state mapping을, Control이 text/value/input/layout을 소유한다. | 이미지와 overlay가 맞물리는 단일 계약이다. |
| UI renderer | `PanelContainer`, `Button`, `TabContainer`를 유지하고 visible style을 direct raster texture 기반 `StyleBoxTexture`로 바꾼다. | localization, focus, hit area, responsive layout을 보존한다. |
| Generation unit | 한 ImageGen 작업은 한 component family 또는 그 component의 직접 관련 state만 만든다. unrelated contact sheet는 production source가 아니다. | topology와 state drift를 제한한다. |
| Production source | 선택 이미지와 해당 current screen crop을 실제 reference input으로 사용한다. | style과 layout을 동시에 보존한다. |
| Text policy | 한국어, 영어, binding, number, cooldown, progress, selection truth를 PNG에 굽지 않는다. | 양 언어와 runtime state가 계속 변한다. |
| Script boundary | 스크립트는 crop, key removal, palette/grid cleanup, slicing, composition, hashing, seam/safe-inset validation만 한다. 장식 픽셀을 창작하지 않는다. | 사용자 승인 에셋이 외형의 유일한 출처다. |
| Missing art | 필수 asset이 없으면 publication 또는 validation이 실패한다. 코드 도형으로 조용히 대체하지 않는다. | 다시 procedural placeholder가 production에 들어오는 것을 막는다. |
| UI scaling | 9-slice `StyleBoxTexture`가 기본이다. corner/edge motif가 target size에서 깨질 때만 해당 surface에 standard/compact fixed backplate를 사용한다. | localization과 세 viewport를 우선하면서 품질 저하를 막는다. |
| Dependencies | Godot 4.7, GDScript, 기존 PowerShell/ImageMagick, built-in ImageGen만 사용한다. | production dependency 추가가 필요 없다. |

## Approved Visual Contract

### Palette and material roles

- space/background: `#070D16`
- primary graphite chassis: `#131B24`
- raised graphite edge: `#1C252D`, `#252D35`
- walkable deck family: `#3C5268`, `#465C72`, `#4A6278`
- energized cobalt rail: `#0A389C`, `#0B48A1`
- support/focus mint: `#5CAC98`, `#70A098`
- live text/highlight: existing ivory `#F3E8C9`
- player/reward/primary action: existing mustard `#D79A17`
- ordinary danger: existing coral `#C92F4E`
- boss danger: existing magenta `#962754`

Gradient, antialiasing, glow blur, dithering, dense speckle, and repeated
micro-panel noise do not survive production cleanup. Large structure, sparse
panel seams, hard pixel edges, and semantic rails do.

### In-game composition

- outer space is near-black and visually separate from the playable footprint;
- the playable deck is cool blue-gray, low-contrast, and quieter than actor,
  pickup, projectile, and telegraph art;
- wall/cover uses graphite mass, a readable top edge, dark contact shadow, and
  restrained cobalt boundary light;
- vents, consoles, crates, pipes, and structural props are image assets placed
  only at authored or deterministic visual sockets;
- decorative props never imply collision, pickup, hazard, objective, or route;
- functional fixtures have a raster body, while exact radius, timer, health,
  readiness, warning, and cooldown remain live overlays;
- player, friendly fire, reward, danger, support, and boss keep the established
  mustard/coral/mint/magenta semantic hierarchy.

### Gameplay HUD composition

- top-left: hull, level, XP;
- top-center: field/objective, replaced by boss warning/health when required;
- top-right: minimap;
- bottom-center outer chassis: four-slot primary/seeker/dash/EMP action rail;
- lower-right: current target panel only while a target exists;
- the central combat rectangle stays free of opaque UI;
- every HUD cluster uses dark navy/graphite image-backed chrome with mint inner
  line and restrained cobalt rail instead of ivory boxes.

At compact width, the same anchor order remains. Labels may shorten according
to existing localized copy, but no control or information disappears.

### Modal, section, card, and button composition

- modal: graphite outer chassis, dark navy face, cobalt structural rail, mint
  inner boundary, ivory live text;
- section: spacing and one restrained image-backed plate or divider; visible
  bordered nesting never exceeds two levels;
- upgrade card: fixed icon socket, family, title, effect, numeric delta, pips;
  selected uses a mustard asset frame/marker and keyboard focus uses a separate
  mint/ivory asset rail;
- primary button: dark body with mustard rail/frame;
- secondary button: dark body with mint/cobalt rail;
- danger button: dark body with coral rail;
- disabled state: approved dimmed texture plus live disabled semantics;
- hover, pressed, focus, selected, disabled visuals are approved raster states
  switched by the live Theme; text and hit area remain Control-owned.

## Asset and Template Contract

### World raster families

| Family | Native contract | Required output |
| --- | --- | --- |
| `space_void` | `24×24` | three sparse repeat variants |
| `deck_base` | `24×24` | three repeat variants and one sparse `2×2` patch |
| `floor_void_edge` | `24×24` | 16 orthogonal signatures |
| `wall_cover_tiles` | `24×24` | 16 signatures with separable top/side/shadow/boundary-light layers |
| `wall_rail` | `24×24` | cap, horizontal, vertical, inner/outer corner |
| static props | `48×48` or `96×96` | vent, console, cargo, conduit, structural support |
| functional fixtures | `32–64 px` | arc strip, bulkhead, gate, repair, overdrive, reward crate state frames |
| actors/combat | existing family sizes | silhouettes and effects translated into the approved palette/material grammar |

`VehicleWorldVisualTemplate` selects deterministic variants from stage ID,
layout fingerprint, and tile coordinate. It emits visual-only base regions,
edge instances, wall instances, and prop instances. It never emits collision,
navigation, spawn, line-of-sight, or attack data.

### UI chrome families

| Family | Native master | Runtime form |
| --- | ---: | --- |
| modal shell | `96×96` | 9-slice, 24 px patch margins |
| HUD shell | `48×48` | 9-slice, 12 px patch margins |
| section/card shell | `64×64` | 9-slice, 16 px patch margins |
| button shell | `96×48` | 9-slice, 16/12 px patch margins |
| tab shell | `64×32` | 9-slice, 12/8 px patch margins |
| focus/selected marker | native asset size | transparent overlay/state texture |

`pixel-art-production/schemas/ui-chrome-manifest.schema.json` owns source hash,
approval, logical size, transparent key, texture margins, content insets, axis
mode, state mapping, target sizes, and review backgrounds. UI chrome is not
packed into the combat atlas; approved PNGs are published under
`art/ui/production/chrome/` and referenced directly by the Theme.

`VehicleUISurfaceFactory` creates only `modal_surface`, `hud_surface`, and
`section_surface` containers with approved theme variations and minimum sizes.
It owns no text, gameplay state, navigation, or button behavior.

## Architecture and Ownership

| Concern | Final owner | Interface / invariant | Reuse or retire |
| --- | --- | --- | --- |
| Product/gameplay contract | `docs/product/vehicle_game_spec.md` | no gameplay/control changes; approved action-rail placement exception only | revise HUD placement line |
| Visual contract | `docs/design/UI_VISUAL_SYSTEM.md` | approved space-hangar palette, hierarchy, raster/live boundary | revise |
| Palette/role constants | `scripts/vehicle/vehicle_stage_visual_profile.gd` | shared semantic roles, no state | revise |
| Pixel production | `pixel-art-production/README.md`, manifests, validators | ImageGen source → deterministic cleanup → approval → publish | extend |
| World asset catalog | existing atlas/catalog | exact family/variant/state lookup | reuse |
| World template | `scripts/presentation/vehicle_world_visual_template.gd` | geometry-fed deterministic visual records | add |
| World renderer | `scripts/presentation/vehicle_pixel_world_mesh_builder.gd` | repeated base plus batched edges/walls/props | extend |
| Functional state | `VehicleTerrainRuntime`, `VehicleCombatRenderer` | exact area/progress/state overlay | reuse |
| Legacy terrain drawing | `VehicleRun._draw_terrain()` | retain exact live geometry; retire migrated decorative body/glyph drawing | narrow |
| UI chrome manifest | new UI chrome schema/manifest | patch margins and content insets match runtime Theme | add |
| UI visible chrome | `art/ui/production/chrome/*.png` | approved empty assets only | add |
| Theme mapping | `art/ui/production/vehicle_stage_theme.tres` | `StyleBoxTexture` state mapping, font/colors/margins | revise |
| UI surface construction | `scripts/ui/vehicle_ui_surface_factory.gd` | reusable shell creation only | add |
| HUD/modal layout | `scripts/ui/vehicle_stage_ui.gd` | existing information flow and live state | retain and apply |
| Card flow | `VehicleUpgradeChoicePanel`, `VehicleUpgradeChoiceCard` | selection and content stay live | retain; remove decorative `_draw()` parts |

## As-Is / To-Be Delta Map

| Concern | As-is | To-be | Acceptance | Guard |
| --- | --- | --- | --- | --- |
| World base | ivory repeat field | cool blue-gray deck inside near-black space | side-by-side approved composition | no floor motif reads as gameplay |
| Wall/cover | green fill and broad code rail | graphite connected tiles and cobalt boundary asset | 16-signature and collision overlay proof | art never changes geometry |
| Props | sparse generic code shapes | generated, approved socket-based raster props | deterministic placement capture | no false blocker/hazard/pickup |
| Terrain | body and exact state mixed in `_draw_terrain()` | raster fixture under exact live overlay | state-by-state captures | radius/timer/health stay live |
| HUD surface | ivory `StyleBoxFlat` boxes | image-backed dark HUD shells | all anchors and central clear zone pass | no hidden information |
| Health/action visuals | code-drawn decorative body plus live values | raster frame/icon/socket plus live fill/cooldown | value and cooldown parity | dynamic truth not baked |
| Modal | large ivory flat panel | dark graphite/navy image shell | pause/upgrade/garage captures | text remains live |
| Card | solid green box, code focus/diamond | raster state family, live content | all 91 offers ko/en | focus and selection remain distinct |
| Button/tab | flat fill generated by Theme/code | approved empty state PNGs | mouse/keyboard state matrix | 44 px minimum target |
| Missing asset | procedural fallback possible | validation/publication failure | missing-ID test | no silent code art |

## Tasks

The phases below are the implementation milestones.

### Phase 0 — Preserve the decision and correct contracts

Goal: make the approved direction and asset/live boundary the only active
implementation target.

Source owners touched:
`docs/product/vehicle_game_spec.md`, `docs/design/UI_VISUAL_SYSTEM.md`,
`pixel-art-production/README.md`,
`pixel-art-production/assets/asset-inventory.json`,
`scripts/vehicle/vehicle_stage_visual_profile.gd`, selection/recovery plans.

- [ ] Copy the exact selected image to
  `pixel-art-production/evidence/design-directions/2026-07-28/approved-space-hangar-reference.png`
  without resizing and record its SHA-256.
- [ ] Replace the active ceramic/ivory surface rules with the Approved Visual
  Contract above while retaining semantic colors and gameplay hierarchy.
- [ ] Record the approved bottom-center outer-chassis action rail as the only
  HUD placement change in the product and UI specifications.
- [ ] Add the inventory target mode `raster_texture`, then change
  `ui_frame_system` from `procedural_pixel/direct_pixel` to
  `raster_texture/imagegen_assisted`; keep `dynamic_combat_ui` as `live_ui`.
- [ ] Add UI chrome production and validation to the pixel pipeline spec.
- [ ] Update `VehicleStageVisualProfile` material constants without changing
  gameplay radii or attack semantics.

Batch acceptance:

- no active document tells an executor to hand-code visible UI chrome;
- the selected reference, palette, world layers, UI layers, and missing-art
  policy are identical across spec, inventory, and plan.

Batch guard:

- do not change gameplay geometry, strings, input, balance, save, or audio.

### Phase 1 — Produce asset masters and review assemblies

Goal: approve real source art before runtime styling work.

Source owners touched:
ImageGen evidence, world manifests, UI chrome schema/manifest,
review-build scripts, candidate/approved source folders.

- [ ] Generate world masters one family at a time using the selected image and
  current gameplay crop: void, deck, wall/edge, prop, and fixture families.
- [ ] Generate UI component families one at a time using the selected image and
  matching current modal crop: modal, HUD, section/card, button, tab, and
  focus/selected overlays.
- [ ] Snap/remap approved concepts to the locked palette and logical grids;
  remove key backgrounds; reject partial alpha, text, gradients, and off-grid
  edges.
- [ ] Add
  `pixel-art-production/schemas/ui-chrome-manifest.schema.json`,
  `pixel-art-production/assets/manifests/approved/ui/vehicle_ui_chrome.manifest.json`,
  `pixel-art-production/tools/design/build_ui_chrome_review.ps1`, and
  `pixel-art-production/tools/validation/validate_ui_chrome_assets.ps1`.
- [ ] Build native-size, enlarged, safe-inset, 9-slice target-size, and state
  review boards.
- [ ] Assemble four approval images with the real current layout and live text:
  in-game, pause, upgrade, garage.

Approval gate:

- BK approves the four assembled images before any candidate chrome or world
  master is published into runtime.

Batch guard:

- scripts may assemble and validate assets but may not draw new decorative
  pixels or repair a rejected design by inventing shapes.

### Phase 2 — Implement the combined live vertical slice

Goal: prove that the same approved assets work in the actual world, HUD, and
pause flow.

Source owners touched:
`vehicle_world_visual_template.gd`,
`vehicle_pixel_world_mesh_builder.gd`,
`vehicle_ui_surface_factory.gd`,
`vehicle_stage_theme.tres`, `vehicle_stage_ui.gd`,
new focused validators.

- [ ] Add `VehicleWorldVisualTemplate` and deterministic tile/prop selection
  keyed by stage ID, layout fingerprint, and tile coordinate.
- [ ] Keep repeat polygons for large base fills and add atlas-batched connected
  edge, wall, rail, and sparse prop instances.
- [ ] Publish approved UI PNGs to `art/ui/production/chrome/` and replace
  migrated Theme `StyleBoxFlat` resources with `StyleBoxTexture`.
- [ ] Add `VehicleUISurfaceFactory`; route
  `VehicleStageUI._modal_panel()`, `_flat_panel()`, and per-HUD margin overrides
  through the factory/theme safe-inset contract.
- [ ] Move the four-slot action rail to the bottom-center outer chassis and
  keep hull/objective/minimap/target anchors defined above.
- [ ] Replace the Health/Action decorative shells and icon fallbacks with
  approved assets while leaving hull/XP fill and cooldown arcs live.
- [ ] Apply the approved modal/button chrome to pause without changing its
  actions or transitions.
- [ ] Add `validate_vehicle_world_visual_template.gd` and
  `validate_vehicle_ui_chrome.gd`.

Batch acceptance:

- safe-arrival, maximum-pressure, and pause at `1280×720` visibly match the
  approved assemblies;
- collision/minimap overlay remains identical before and after visual
  replacement;
- no migrated surface uses a decorative code-shape fallback.

Batch guard:

- `VehicleStageUI` remains the layout/intent coordinator;
- `VehicleUISurfaceFactory` does not absorb screen-specific content or behavior.

### Phase 3 — Roll out world, terrain, and combat presentation

Goal: make every in-game object share the approved visual grammar.

- [ ] Publish deck/void/wall connected families and replace the three broad
  repeat-only materials with base fill plus topology-aware overlays.
- [ ] Add deterministic static props only at legal visual sockets.
- [ ] Convert arc, bulkhead, gate, repair, overdrive, and crate bodies to raster
  fixtures.
- [ ] Retain exact arc danger rectangle, gate radius/progress, support
  radius/timer, bulkhead health, and cooldown as live overlays.
- [ ] Retire `_draw_terrain_bolt()` and decorative chevron/body drawing only
  after matching approved asset frames exist.
- [ ] Translate player, enemy, boss, projectile, secondary, pickup, and effect
  families into the approved palette/material hierarchy in six-master batches.
- [ ] Review every batch at native size and in maximum-pressure gameplay before
  publishing the next batch.

Batch acceptance:

- floor, cover, void, player, enemies, projectiles, pickups, fixtures, and
  telegraphs remain separable at gameplay scale and in grayscale;
- all world seams, topology signatures, anchors, batching, and performance
  limits pass.

Batch guard:

- visual art never changes collision, line of sight, spawn legality, attack
  footprint, projectile radius, or minimap truth.

### Phase 4 — Roll out all UI surfaces

Goal: replace the remaining flat UI without changing flow or content.

- [ ] Apply approved card state textures to
  `VehicleUpgradeChoiceCard`; remove only its procedural selection diamond and
  focus rail after raster equivalents are active.
- [ ] Apply the system to upgrade, garage, deployment, settings, guidebook,
  stage report, result, and build-summary surfaces.
- [ ] Move settings tab `StyleBoxFlat` creation into approved Theme texture
  states.
- [ ] Preserve live icon atlas draws, level pips, meters, minimap geometry,
  text, values, focus ownership, and accessibility semantics.
- [ ] Use standard/compact fixed backplates only for a surface whose 9-slice
  proof fails; produce and validate both variants before wiring.
- [ ] Capture default, hover, pressed, focus, selected, disabled, and danger
  states in Korean and English.

Batch acceptance:

- every modal shares the approved graphite/cobalt/mint chrome;
- no text clips, no child escapes its safe inset, and no visible nesting exceeds
  two bordered/background layers;
- keyboard, mouse, controller, localization, and modal transitions are
  unchanged.

### Phase 5 — Production QA, retirement, and documentation

Goal: make the approved image/template path the only production presentation.

- [ ] Run focused pixel, world, UI, localization, pause, report, guidebook, and
  performance validators after each affected batch.
- [ ] Run deterministic captures at `960×540`, `1280×720`, and `1920×1080` in
  Korean and English.
- [ ] Export the Web build and use the registered `fastrun` codex lane for
  production-style review after loading the repo port-guard workflow.
- [ ] Remove only superseded `StyleBoxFlat`, decorative draw helpers, and
  fallback branches whose complete replacement has passed.
- [ ] Record final checksums and rendered evidence; update active specs with
  any implementation-local clarified invariant.
- [ ] Mark this plan done only after all completion criteria pass.

## Test Plan / Validation Cadence

### Asset inner loop

```powershell
.\pixel-art-production\tools\design\validate_pixel_asset_manifest.ps1
.\pixel-art-production\tools\design\invoke_pixel_asset_build.ps1
.\pixel-art-production\tools\validation\validate_pixel_asset_palettes.ps1
.\pixel-art-production\tools\validation\validate_pixel_asset_seams.ps1
.\pixel-art-production\tools\validation\validate_pixel_asset_catalog.ps1
.\pixel-art-production\tools\validation\validate_ui_chrome_assets.ps1
```

### Runtime inner loop

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_world_visual_template.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_pixel_world_renderer.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_ui_chrome.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_ui_layout.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_ui_localization.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_pause.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_rewards_ui_audio.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_report.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_guidebook.gd
```

The two new validator commands become runnable gates only after their named
Phase 1/2 tasks create the files. Existing commands remain available from
Phase 0.

### Final gates

- every repository validator under `tools/validation/`;
- `.\tools\export_web.ps1`;
- production-style Web run through the registered `fastrun` codex lane;
- Korean default and complete English parity;
- safe arrival, first contact, maximum pressure, upgrade default/selected,
  pause, settings, guidebook, report, result, garage;
- collision/opening/minimap overlay comparison;
- keyboard/controller focus, reduced motion, hover/pressed/disabled states;
- `git diff --check` and lifecycle/frontmatter review.

Rerun a failed narrow check only after a concrete asset, manifest, template,
theme, layout, or test change. Run full gates only after the suspected cause
changes.

## Predetermined Error Handling and Contingencies

| Trigger | Required response | Limit / escalation |
| --- | --- | --- |
| ImageGen adds text or changes layout | reject that source and regenerate the same component using empty-content constraints | never clean generated text into production |
| Raw asset drifts from palette/grid | one stricter edit pass, then deterministic palette/grid cleanup | reject if the silhouette or frame grammar still changes |
| Tile seam/topology fails | correct only the source family edge cells and rebuild the proof | never alter gameplay geometry |
| 9-slice corner/edge distorts | rebuild the source once with simpler repeatable edges | if it still fails, use exact standard/compact fixed backplates for that surface |
| Content crosses safe inset | correct manifest/theme content margins or screen layout | do not shrink Korean/English text below current readable sizes |
| Required raster asset is missing | fail validation/publication with its asset/state ID | no `StyleBoxFlat` or draw-shape production fallback |
| UI state is color-only | add approved shape/rail/frame distinction | focus, selected, disabled, and danger must remain distinguishable |
| World art implies false gameplay | simplify or relocate the motif | collision/navigation/telegraph truth is never changed |
| Performance threshold fails | cache by layout fingerprint or rebatch static instances | do not weaken thresholds or reduce gameplay workload |

## Rollback / Safety

- All changes are forward replacements in scoped commits; no history rewrite,
  hard reset, or unrelated cleanup is permitted.
- Candidate and rejected source art stays outside runtime publication.
- Each migrated family retains the previous runtime asset until its new native,
  seam, gameplay, localization, and performance checks pass.
- Theme conversion happens by variation family, so a failed batch can restore
  the last approved resource mapping without reverting unrelated UI behavior.
- Geometry, collision, navigation, combat, card, input, save, localization
  strings, and audio remain outside the visual migration.

## Risks

- The selected concept contains soft shading and detail that must be simplified
  at native pixel size; review boards prevent raw concept art from being treated
  as production art.
- A visually rich wall or prop can imply false collision; collision-overlay and
  first-clear reviews are mandatory.
- Korean line length can exceed a chrome safe area; safe-inset proofs and the
  existing 91-card bilingual matrix are mandatory.
- Excessive state textures can drift; all related states derive from one
  approved component master and are reviewed as one family.
- Adding a general-purpose factory could create a catch-all; the surface factory
  is limited to shell type, theme variation, safe inset, and minimum size.

## Assumptions

- The selected `call_fNU…png` image is the final visual direction.
- Existing gameplay rules, current menu actions, and Korean/English copy remain
  unchanged.
- The prior explicit request to keep the current screenshot layout, followed by
  selection of the bottom-center composition, authorizes the action-rail
  placement exception recorded in Scope.
- No material implementation choice remains unresolved. Any request to change
  gameplay topology, any other UI information architecture, dependencies, or
  copy is a separate change-control decision.

## Open Questions

No material open questions remain for execution. Asset approval is an exact
gate over the four named assembled images, not a request to choose a new style.
The action-rail placement is a recorded user-approved exception rather than an
unresolved layout choice.

## Decision Notes

- The earlier three Quiet/Tidal/Structural concepts were rejected.
- The approved space-hangar image supersedes Sunken Ceramic Fresco as the
  implementation target for world material and UI surface treatment.
- Existing semantic colors, gameplay truth, localization, accessibility, and
  retained render ownership are preserved.
- Image assets own appearance; templates own fit; live state owns meaning.

## Progress

- [x] Current screenshots, selected image, active specs, render owners, UI
  owners, pipeline, inventory, validators, and stale plans inspected.
- [x] World asset/live-overlay and UI chrome/live-Control architectures locked.
- [ ] Phase 0 complete.
- [ ] Phase 1 approved.
- [ ] Phase 2 live vertical slice accepted.
- [ ] Phases 3–4 complete.
- [ ] Phase 5 final gates complete.

## Next Steps

1. Execute Phase 0 and make the selected image plus raster/live boundary the
   active spec and inventory contract.
2. Execute Phase 1 and present the four named assembled images for the exact
   approval gate.
3. After approval, implement the combined live vertical slice before any broad
   world or UI rollout.

## Completion Criteria

- [ ] The live world, terrain, actors, HUD, and modal surfaces visibly share the
  approved space-hangar grammar.
- [ ] Every migrated visual shell is backed by an approved image source,
  checksum, and truthful production method.
- [ ] No migrated surface silently falls back to script-authored decorative
  pixels or `StyleBoxFlat`.
- [ ] Text, values, input, focus semantics, exact gameplay areas, collision,
  navigation, and minimap truth remain live and unchanged.
- [ ] Korean and English pass at all three viewports without clipping,
  overlap, hidden controls, or unsafe target sizes.
- [ ] Native, runtime, Web, readability, and performance gates pass without
  weakened thresholds.

## Stop Conditions

Complete when:

- every completion criterion passes and durable rules are present in the active
  visual and production specifications.

Escalate only when:

- a required visual result would need gameplay geometry, information
  architecture, dependencies, localization copy, or performance thresholds to
  change; or the exact approval gate rejects both the rebuilt 9-slice and its
  predetermined fixed-backplate fallback.

Do not stop when:

- an asset needs bounded regeneration, grid/palette cleanup, edge correction,
  safe-inset correction, batching, or a focused layout fix.

## Handoff

```text
Goal:
Apply the approved space-hangar world and UI direction through image assets,
templates, and live overlays without changing gameplay truth.

Read first:
.agents/execplans/2026-07-28-space-hangar-world-ui-asset-integration.md
docs/design/UI_VISUAL_SYSTEM.md
pixel-art-production/README.md

Execute exactly:
Start with the first unchecked phase. Do not publish runtime assets before the
four named assembled images pass the approval gate.

Validate with:
The asset, runtime, localization, viewport, Web, and performance gates in this
plan.

Stop when:
The completion criteria pass or a named escalation boundary requires new
authority.
```
