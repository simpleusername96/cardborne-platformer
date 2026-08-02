---
type: plan
status: active
owner: BK
created: 2026-08-02
topic: Asset production 전에 끝낼 runtime·UI·report·performance 코드 안정화
scope: 단일 플레이어 기체, UI shell 축소, world presentation, inventory truth model, release performance
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../semantic-v2-runtime-acceptance-evidence.md
---

# 자산 제작 전 코드 안정화 계획

## Why / Context

새 visual asset을 더 만들기 전에, 현재 코드가 어떤 asset을 몇 개 소비하는지와
그 asset이 어떤 gameplay truth를 따라야 하는지를 먼저 고정한다. 이 계획의
완료 상태는 `asset_ready`이며, 새 PNG 생성이나 개별 TO-BE 승인·적용은 이
계획에 포함하지 않는다.

현재 확인된 실제 미해결 항목은 다음 다섯 가지다.

1. 플레이어가 hull, engine, aim mount의 세 raster와 세 render batch로
   분리돼 있다. 사용자는 플레이어 기체를 하나의 composite asset으로
   통일하기로 결정했다.
2. UI structural shell은 같은 pixel을 여러 파일과 state로 중복 소유하고,
   modal factory를 HUD toast가 사용하는 등 코드 소유권도 섞여 있다.
3. map floor/wall raster는 production manifest에 들어 있지만 runtime에서는
   제외돼 있고, 일부 기능 지형 body art는 실제 `Rect2`/radius보다 작다.
4. visual inventory는 runtime 적용 상태, review 결정, TO-BE guide 보유 여부를
   하나의 `action`으로 섞고 과거 git snapshot에 의존해 재생성된다.
5. authoritative `peak_horde`, `capacity_pressure`, `lifecycle_pressure`가 release
   성능 기준을 통과하지 못했다.

다음 작업은 이미 완료됐으므로 다시 구현하지 않는다.

- 정본 문서 정리와 capture command 추출
- projectile/telegraph producer → catalog → asset/frame 연결
- upgrade card의 ko/en, 960/1280/1920, 200% text-fit 및 overflow 대응
- production Web export와 built-Web interaction smoke

`docs/design/UI_VISUAL_SYSTEM.md`의 projectile/telegraph 및 upgrade-card 항목은
현재 코드와 acceptance evidence에 뒤처진 문서 표기다. 해당 validators를
재실행한 뒤 Known Gap에서 제거한다.

## Terminology

이 계획과 후속 구현에서는 다음 용어만 사용한다.

| 용어 | 의미 | 소유하지 않는 것 |
| --- | --- | --- |
| `player craft` | 화면에 보이는 단일 플레이어 actor raster | HP 규칙, 조준 입력, 충돌 |
| `craft_direction` | 이동으로 결정되는 기체 facing | 탄도 방향 |
| `aim_direction` | cursor, muzzle, projectile에 쓰는 manual-aim intent | 별도 mount asset |
| `thrust_anchor` | composite 뒤쪽의 transient dash VFX 원점 | engine body asset |
| `hull` | HP·피해·방어 관련 gameplay 용어 | 별도 visual layer |
| UI `shell` | modal/content/HUD의 image-backed structural frame | button, tab, meter, glyph, screen content |
| control skin | button/tab/toggle/slider/card의 interaction state image | structural shell |
| screen content | deployment/settings/guide/result 등 각 화면의 상태와 hierarchy | 공용 shell chrome |
| runtime state | 현재 파일이 실제 게임에서 소비되는 방식 | 승인 여부 |
| decision state | 현행 유지·수정·승인·보류·폐기 결정 | runtime 적용 여부 |
| guide state | TO-BE 비교 이미지가 있는지 | 승인 여부 |

## Scope

- 정본 spec을 새 단일 기체 결정과 실제 완료 상태에 맞춘다.
- 플레이어 runtime presentation을 한 actor asset과 한 batch로 통합한다.
- UI shell의 물리 파일 수와 construction API를 축소한다.
- map surface adapter와 functional-terrain footprint 계약을 asset보다 먼저
  완성한다.
- visual inventory를 현재 repo만으로 재생성하고 세 상태 축을 분리한다.
- 현재 정해진 actor/projectile/effect 수와 품질을 유지한 채 release 성능을
  통과시킨다.
- focused validation, 전체 vehicle validation, Web export, built runtime QA,
  native/Web performance matrix, 600초 lifecycle soak를 수행한다.

## Non-scope

- 새 raster 생성, 기존 raster repaint, TO-BE 개별 승인 또는 새 asset runtime
  cutover
- 일반 적의 전술·역할·수치 변경, boss pattern·module·전략 변경
- player control, manual aim, collision, damage, campaign flow 변경
- enemy/projectile/effect capacity 또는 성능 threshold 하향
- deployment/settings/result 등 screen-content class의 합병
- button, tab, toggle, slider, meter, upgrade-card state를 shell로 오인한 병합
- 미승인 map/player/UI 후보 이미지를 production runtime에 연결하는 작업
- production dependency 추가나 Godot 4.7 이외의 engine 도입

## Assumptions

- 모든 구현은 Godot 4.7 stable과 기존 GDScript 책임 경계를 사용한다.
- 새 player craft가 승인될 때까지
  `actors/player/actor_player_hull_base.png`를 `actor/player`의 임시 단일
  raster로 사용한다. engine과 aim mount는 표시하지 않는다.
- manual aim, held primary fire, dash, passive seeker, EMP, collision radius와
  muzzle origin은 현행 gameplay truth를 유지한다.
- 미승인 floor/wall 파일과 review sheet는 코드 schema를 결정하지 않는다.
- 각 milestone은 task-owned 파일만 포함한 독립 commit으로 끝낸다.

## Proposed Design

### 1. Single player-craft contract

`art/gameplay/semantic-v2/asset-manifest.json`의 `attachments` block을 없애고
`asset_sets`에 `id = "player"`, `root = "actors/player"`,
`files.player.path = "actor_player_hull_base.png"`인 한 항목을 등록한다.
`VehicleSemanticAssetProvider._index_asset_sets()`의 `&"player"` branch가 이를
`actor/player`로 색인하고 `_index_attachments()`는 삭제한다. 최종 asset
단계에서는 ID와 renderer를 바꾸지 않고 path만 승인된
`actor_player_craft.png`로 교체한다. 최종 file contract는 128×128, center
pivot `[64, 64]`, authored facing `+X`, untrimmed RGBA다.

`VehicleActorVisualCatalog`의 player descriptor는 다음만 가진다.

- `asset = &"actor/player"`
- `thrust_anchor = Vector2(-0.84, 0.0)`
- actor state와 role color

`components`, `rear_sockets`, `aim_socket`, player component recipe는 제거한다.
`VehicleCombatRenderer`는 `Player_craft` batch 한 개만 만들고 다음 규칙을
적용한다.

- craft는 `craft_direction`으로만 회전한다.
- `aim_direction`은 cursor, primary projectile, muzzle event에만 사용한다.
- persistent aim mount와 procedural barrel을 그리지 않는다.
- engine body와 상시 thrust beam을 그리지 않는다.
- dash 중에만 `thrust_anchor`에서 transient flare를 표시한다.
- dash afterimage는 `actor/player`를 재사용하며 최대 5개, danger/radial 0을
  유지한다.

`VehicleRun`의 presentation-facing `player_hull_direction`과 snapshot
`hull_direction`을 각각 `player_craft_direction`, `craft_direction`으로 원자적으로
바꾼다. `aim_direction`은 별도로 유지한다. 소비되지 않는
`hull_visual_tier`, `engine_visual_count`, `primary_visual_tier` snapshot field는
제거한다.

minimap marker는 craft asset이 아니라 UI navigation symbol로 유지한다.
semantic player marker는 `craft_direction`으로 실제 회전하고, procedural
fallback은 player component recipe 대신 local chevron geometry를 사용한다.

Runtime cutover 뒤 다음 항목을 퇴역시킨다.

- `attachment/player_hull`, `attachment/player_engine`,
  `attachment/player_aim_mount`
- engine/aim PNG와 tracked `.import` sidecar
- player component mesh/recipe API와 `player_engine_sockets()`
- `Player_hull`, `Player_engine`, `Player_primary_mount` batch
- 미사용 `_write_player_barrel()`
- 분리형 hull/aim 및 engine review sheet의 active-guide 지위

현재 hull PNG는 임시 단일 runtime asset이므로 asset-production gate를 통과할
때까지 삭제하지 않는다.

### 2. UI shell ownership and physical merge

UI 책임은 네 owner로 고정한다.

1. `VehicleStageUI`: 화면 route, visibility, dim/input gate, return state, signal
2. `VehicleModalHost`: modal centering, viewport clamp, compact dispatch,
   overflow/focus diagnostics
3. `VehicleGameplayHud`: persistent HUD cluster와 non-modal toast/banner
4. UI manifest + Theme: semantic variation과 9-slice chrome binding

각 screen panel은 content owner로 남고 위 owner로 상태나 signal을 이동하지
않는다.

동일 hash인 raster만 pixel 수정 없이 다섯 물리 파일로 합친다.

| canonical physical shell | alias하는 semantic 용도 |
| --- | --- |
| `surfaces/shell_modal.png` | modal normal, compact-safe |
| `surfaces/shell_content.png` | content normal, inset, summary |
| `surfaces/shell_hud_primary.png` | health/resource, action rail |
| `surfaces/shell_hud_auxiliary.png` | minimap/target, toast |
| `surfaces/shell_hud_objective.png` | objective/boss |

Theme variation과 content margin은 유지한다. 같은 파일을 참조한다는 이유로
layout semantics를 합치지 않는다. control skin과 glyph 파일은 이 병합에서
제외한다.

`VehicleUiComponentFactory`는 variation을 숨기는 기본값을 없앤다.

- `flat_panel()`을 필수 `variation`을 받는 `surface(variation)`으로 교체한다.
- modal frame 생성은 `VehicleModalHost`가 직접 소유한다.
- `VehicleStageTransitionBanner`는 `surface(&"HudToast")`를 사용한다.
- debug descriptor만 가진 `VehicleModalSurface` class는 삭제하고 필요한
  diagnostics를 host contract로 이동한다.

### 3. Map surface and functional-terrain contract

`VehicleWorldMeshBuilder`는 map presentation의 단일 owner로 유지한다.
`VehicleFieldSurfacePatternCompiler`는 texture path가 아니라 geometry에서
결정되는 immutable instance record를 추가로 출력한다.

- floor: `floor_base`
- closed union boundary: `wall_straight`, `wall_outer_corner`,
  `wall_inner_corner`
- 실제 open run이 있을 때만 `wall_end`

현재 geometry가 만들지 않는 T/cross junction은 durable asset slot으로 만들지
않는다. field ID와 layout fingerprint, walkable/void rect, wall segment만 hash
input으로 사용한다.

새
`scripts/presentation/components/vehicle_world_surface_asset_provider.gd`의
`VehicleWorldSurfaceAssetProvider`는 production manifest의 optional
`map_surfaces` section만 읽는다. 이 section에 들어간 path만 runtime-approved로
간주한다. 현재 미승인 8개 floor/wall file은 `world.files`에서 제거하고
inventory의 `review_only` evidence로만 남긴다. 따라서 code phase의 production
`map_surfaces`는 비어 있고 builder는 현행 procedural fallback을 사용한다.
`VehicleSemanticAssetProvider`의 filename-prefix exclusion은 함께 삭제해 map
승인 여부를 두 provider가 중복 판단하지 않게 한다.

provider의 public API는 `descriptor(surface_id)`, `texture(surface_id)`,
`validate_manifest()` 세 개다. `VehicleWorldMeshBuilder.set_surface_resolver()`는
production에서 provider의 `texture` callable을 받고 validator에서는 in-memory
resolver를 받는다.

builder는 resolver가 texture를 반환하면 같은 instance record와 UV로 raster를
그리며, 없으면 현재 vertex-color surface를 그린다. validator에서는 in-memory
texture resolver를 주입해 textured path를 검증하되 새 image file을 만들지
않는다. raster 유무는 topology, collision, navigation, socket과 fingerprint를
변경할 수 없다.

기능 지형은 새
`scripts/presentation/vehicle_functional_terrain_renderer.gd`의
`VehicleFunctionalTerrainRenderer` 한 곳으로 모은다. 이 renderer는
`VehicleTerrainRuntime.snapshot()`만 소비하고 gameplay를 계산하지 않는다.
public API는 `sync(terrain_snapshot, visible_world, reduced_motion)`과
`debug_contract()`다.

- repair/overdrive outer body는 snapshot radius 전체에 맞춘다.
- transit-gate body와 progress ring은 `GATE_RADIUS`에 맞춘다.
- arc-surge body는 snapshot `Rect2` 전체에 맞춘다.
- bulkhead body는 현행처럼 live `Rect2`에 맞춘다.
- disk, ring, readiness, cooldown, progress는 실제 ratio를 나타내는 procedural
  truth로 유지한다.
- inner core는 상태 cue일 뿐 footprint로 계산하지 않는다.

`VehicleRun._draw_terrain()`과
`VehicleCombatRenderer._sync_support_fields()`의 중복 presentation 책임은 새
renderer로 이동한 뒤 삭제한다.

### 4. Self-contained visual inventory truth model

과거 commit `9b309ce`에서 원본을 복구하는 build path를 제거한다. report는
현재 repo의 다음 source만 사용한다.

- `docs/design/visual-asset-inventory/inventory-source.json`: taxonomy,
  semantic unit, decision, guide, procedural unit
- current gameplay/UI production manifests
- `docs/design/visual-asset-inventory/report-template.html`

새 `tools/design/build_visual_asset_inventory.ps1`가 current manifests와 실제
파일을 대조해 `inventory.json`과 `index.html`을 생성한다.
`restore_visual_asset_inventory.ps1`와 overlay-only
`current-review-overrides.json`은 이 전환 뒤 삭제한다. media path 수집 helper는
current source만 읽도록 유지한다.

`docs/design/visual-asset-inventory/README.md`의 restore 명령과 historical
snapshot 설명은 current builder 명령과 source/output 책임으로 교체한다.
`report-template.html`의 단일 action filter는 runtime/decision/guide filter로
나누고, `validate_visual_asset_inventory.ps1`의 overlay 존재·candidate action·
고정 count assertion은 다음 contract assertion으로 교체한다.

- 세 상태 field와 허용값이 모든 unit에 존재함
- top-level category 5개, unit 중복/누락 0
- production queue 파생식 이외의 implicit queue 0
- current manifests의 모든 path가 ledger에 정확히 한 번 존재함
- `in_game`/`registered_only` unit의 runtime owner evidence가 존재함
- report에 embedded된 JSON과 generated `inventory.json`이 동일함

각 unit은 서로 독립적인 세 필드를 반드시 가진다.

| field | 허용값 |
| --- | --- |
| `runtime_state` | `in_game`, `registered_only`, `staged`, `review_only` |
| `decision_state` | `keep`, `needs_revision`, `hold`, `approved`, `unreviewed`, `superseded` |
| `guide_state` | `available`, `missing`, `not_required` |

`representation`은 `raster`, `procedural`, `mixed`, `font` 중 하나로 별도 기록한다.
실제 consumer가 확인된 경우만 `in_game`이며 provider index만 존재하면
`registered_only`다. 이미지가 있다는 사실은 `approved`나 `in_game`을 암시하지
않는다. 각 `in_game`/`registered_only` unit은 `runtime_owner`와 source
path/symbol evidence를 가져야 하며 builder는 source-code grep으로 draw 여부를
추측하지 않는다. validator가 명시된 owner와 manifest/provider coverage를
대조한다.

production queue는 다음 식으로만 파생한다.

```text
decision_state == approved
and guide_state == available
and runtime_state != in_game
```

현재 approved replacement는 0이므로 queue도 0이어야 한다. 기존 분리형
player hull/aim 및 engine sheet는 `decision_state=superseded`,
`guide_state=not_required` 기록을 남긴 뒤 파일을 삭제하고, player
minimap-marker sheet만 별도 UI 후보로 유지한다.

report taxonomy는 다음 다섯 top-level category와 그 하위 group만 사용한다.

1. UI: HUD/minimap, screen/card, control skin, structural shell, typography
2. Map/terrain: floor/wall, functional terrain, cover/facility
3. Player: single craft, weapon/projectile, defense/status, minimap marker
4. Enemies/bosses: actor, module, attack/telegraph
5. Rewards/effects: pickup/reward, shared combat effect

하나의 physical file은 ledger에 한 번만 나오며 여러 semantic alias는 해당
record의 `used_by`로 표시한다.

### 5. Performance stabilization

성능은 asset을 추가하기 전 현재 presentation과 capacity로 통과시킨다. 먼저
기존 performance-only sample path를 다음 substep까지 확장한다.

- schedule membership/rebuild
- timer와 activation
- coordination/status/terrain
- scheduled motion과 grid writes
- projectile cover, grid query, exact hit resolution
- combat renderer visibility/descriptor/telegraph sync

ordinary play에서는 sample array와 timer 호출을 만들지 않는다. instrumentation
후 현재 구조상 확인된 세 비용을 순서대로 제거한다.

1. `VehicleEnemyUpdateSchedule`를 stable-slot registry와 persistent cadence
   bucket으로 바꾼다. spawn/retire/activation/critical transition 때 membership을
   갱신하고, 매 physics tick 전체 live array를 rebuild하지 않는다. critical
   phase 60 Hz, ordinary decision 10 Hz, near motion 30 Hz, far motion 20 Hz는
   유지한다.
2. `VehicleSpatialGrid` membership을 reverse-indexed swap-remove로 바꿔
   `Array.erase`를 없앤다. projectile first-hit은 `hit_t`와 stable slot tie-break로
   결정해 cell 내부 순서와 무관하게 재현한다.
3. `VehicleCombatRenderer`는 visible-world test를 descriptor, semantic texture,
   telegraph preparation보다 먼저 수행한다. 화면에 보이는 warning과 off-screen
   priority cue의 선택 규칙은 유지한다.

Built Web performance를 재현하기 위해 새
`scripts/performance/vehicle_web_performance_bridge.gd`의
`VehicleWebPerformanceBridge`를 둔다. 이 class는 다음 두 책임만 가진다.

- `window.location.search`의 `performance-scenario`, `performance-warmup`,
  `performance-duration`을 pure parser로 읽어 native command-line request와 같은
  Dictionary를 반환한다.
- 완료된 recorder result 전체를
  `window.__cardbornePerformanceResultJson`에 publish한다.

`VehicleRun`은 native args가 없을 때만 Web request를 사용한다. query parser는
headless validator에서 문자열로 검증하고, 실제 Web run은 focused/visible tab과
1280×720 viewport에서 수행한다.

각 변경 뒤 native `capacity_pressure`를 다시 실행해 회귀를 즉시 분리하지만,
세 구조 개선은 모두 완료한다. 성능을 맞추기 위해 actor/projectile/effect 수,
language, quality, timing 또는 threshold를 낮추지 않는다.

## Milestones

### M0. Authority and freeze contract

- [ ] `vehicle_game_spec.md`의 rigid engine-child 문구를 single craft,
  independent aim intent, transient thrust 계약으로 교체한다.
- [ ] `UI_VISUAL_SYSTEM.md`의 분리 mount/engine 및 engine-drift acceptance를
  composite craft/pivot/thrust-anchor acceptance로 교체한다.
- [ ] 이미 해결된 projectile/telegraph 및 upgrade-card Known Gap을 재검증 후
  삭제한다.
- [ ] 이 계획의 asset-production gate를
  `docs/design/visual-asset-inventory/README.md`와
  `.agents/semantic-v2-runtime-acceptance-evidence.md`에서 링크한다.

Exit: 정본 문서에 separate engine/aim asset 요구가 0이고, 새 asset이 아직
승인되지 않았음이 명시돼 있다.

### M1. Single craft runtime migration

- [ ] manifest/provider/catalog를 `actor/player` 한 ID로 전환한다.
- [ ] renderer와 runtime snapshot을 `craft_direction`/`aim_direction`으로
  분리한다.
- [ ] engine/aim batch, component recipe, dead barrel code와 obsolete raster를
  제거한다.
- [ ] dash-only thrust, afterimage, orthogonal craft/aim fixture를 고정한다.
- [ ] minimap player marker 회전을 고친다.

Exit: player craft batch 1, player attachment 0, old player attachment reference
0, collision radius 24와 visual radius 50 및 primary muzzle offset 39 불변,
360° `thrust_anchor` drift 1 px 이하이다.

### M2. UI shell consolidation

- [ ] StageUI/ModalHost/HUD/Theme ownership contract를 validator로 먼저 고정한다.
- [ ] factory API와 StageTransitionBanner의 cross-owner 사용을 정리한다.
- [ ] `VehicleModalSurface`를 제거하고 host diagnostics를 보존한다.
- [ ] 동일 hash shell을 다섯 physical raster로 rename/deduplicate한다.
- [ ] manifest alias, Theme reference, margin과 ko/en compact layout을 검증한다.

Exit: structural shell physical file 5, duplicate shell hash 0,
HUD → modal factory reference 0, 기존 screen route/signal 변화 0이다.

### M3. World presentation readiness

- [ ] deterministic surface/wall instance contract와 optional map provider를
  구현한다.
- [ ] unapproved map file을 production manifest에서 분리한다.
- [ ] functional terrain presentation을 한 renderer로 이동한다.
- [ ] facility outer body와 live radius/rect 일치를 검증한다.

Exit: asset resolver가 비어도 current procedural world가 동일하게 동작하고,
in-memory resolver path도 같은 geometry fingerprint를 사용하며, 기능 지형
body bounds가 gameplay footprint와 일치한다.

### M4. Inventory and report truth model

- [ ] current-repo-only inventory source와 builder로 전환한다.
- [ ] runtime/decision/guide 세 축과 production-queue 파생식을 구현한다.
- [ ] player single-craft unit과 다섯 shell physical record를 반영한다.
- [ ] superseded split-player sheet를 제거하고 report hierarchy를 재생성한다.
- [ ] 모든 manifest file, procedural unit, review image가 정확히 한 ledger 또는
  intentional exclusion에 속하는지 검증한다.

Exit: report만 읽어도 현재 적용, 등록만 됨, staged, review-only, 승인, guide
유무가 서로 혼동되지 않고 과거 commit 없이 재생성된다.

### M5. Performance release gate

- [ ] fine-grained performance counters를 추가한다.
- [ ] `VehicleWebPerformanceBridge`와 query-parser validator를 추가한다.
- [ ] persistent enemy schedule, O(1) grid membership, early visibility gate를
  순서대로 구현한다.
- [ ] native production/peak/capacity/boss matrix를 통과한다.
- [ ] native 통과 뒤 built-Web matrix를 통과한다.
- [ ] 마지막으로 600초 lifecycle soak와 memory growth gate를 통과한다.

Exit: 모든 recorder threshold가 `passed=true`이고 scenario composition이
유효하다.

### M6. Asset-ready handoff

- [ ] 전체 vehicle validator, inventory validator, import, Web export를 통과한다.
- [ ] built-Web에서 gameplay와 modal/capture matrix를 수동 검토한다.
- [ ] `.agents/semantic-v2-runtime-acceptance-evidence.md`에 새 checkpoint를
  append한다.
- [ ] 정본 spec에 최종 동작을 흡수하고 이 완료된 ExecPlan을 삭제한다.

Exit: 새 image file을 만들지 않은 상태로 `asset_ready`가 증명된다. 그 다음
asset 제작은 별도 승인 batch와 별도 계획으로 시작한다.

## Test Plan

### Focused contract validation

```powershell
.\tools\godot.ps1 --path . --headless --import

$checks = @(
  "validate_vehicle_semantic_asset_provider.gd",
  "validate_vehicle_visual_asset_coverage.gd",
  "validate_vehicle_actor_visuals.gd",
  "validate_vehicle_player_presentation.gd",
  "validate_vehicle_combat_renderer.gd",
  "validate_vehicle_visual_replacement_coverage.gd",
  "validate_vehicle_primary_weapon.gd",
  "validate_vehicle_stage_transition.gd",
  "validate_vehicle_stage_ui_layout.gd",
  "validate_vehicle_pause.gd",
  "validate_vehicle_ui_localization.gd",
  "validate_vehicle_upgrade_ui.gd",
  "validate_vehicle_world_visuals.gd",
  "validate_vehicle_terrain_runtime.gd",
  "validate_vehicle_enemy_update_schedule.gd",
  "validate_vehicle_spatial_grid.gd",
  "validate_vehicle_performance_scenarios.gd",
  "validate_vehicle_performance_web_bridge.gd",
  "validate_vehicle_guidebook.gd",
  "validate_vehicle_run.gd"
)
foreach ($check in $checks) {
  .\tools\godot.ps1 --path . --headless --script "res://tools/validation/$check"
  if ($LASTEXITCODE -ne 0) { throw "Validation failed: $check" }
}

.\tools\validation\validate_visual_asset_inventory.ps1
```

M3에서 새 `validate_vehicle_functional_terrain_presentation.gd`를 위 목록에
추가하고 M5에서 새 `validate_vehicle_performance_web_bridge.gd`를 추가한다.

### Full regression and export

```powershell
$vehicleChecks = Get-ChildItem -LiteralPath tools/validation -Filter "validate_vehicle_*.gd" |
  Sort-Object Name
foreach ($check in $vehicleChecks) {
  .\tools\godot.ps1 --path . --headless --script "res://tools/validation/$($check.Name)"
  if ($LASTEXITCODE -ne 0) { throw "Validation failed: $($check.Name)" }
}

.\tools\godot.ps1 --path . --headless --quit-after 2
.\tools\export_web.ps1
```

Web server를 시작하기 전에는 `$npjt-port-guard`를 적용하고 fastrun manager의
`codex` lane을 사용한다. built export로 다음을 확인한다.

- craft right / aim down에서 craft만 right, cursor/muzzle/projectile은 down
- dash와 reduced-motion, hit tint, stage-transition facing 보존
- player minimap marker rotation
- ko/en × 960/1280/1920 및 200% text fit
- deployment, upgrade, pause/settings, guidebook, result, garage route/focus
- support/gate/arc/bulkhead footprint와 current map containment
- capture fixture `02-safe-arrival`, `03-peak-horde`, `08-player-hit-*`,
  `09-effects-player`

### Native performance matrix

```powershell
$scenarios = @(
  "production_replay",
  "peak_horde",
  "capacity_pressure",
  "boss_pressure"
)
foreach ($scenario in $scenarios) {
  $output = "res://build/performance/pre-asset/$scenario.json"
  $perfArgs = @(
    "--rendering-method", "gl_compatibility", "--",
    "--performance-scenario=$scenario",
    "--performance-warmup=10",
    "--performance-duration=60",
    "--performance-output=$output"
  )
  .\tools\godot.ps1 @perfArgs
  if ($LASTEXITCODE -ne 0) { throw "Performance run failed: $scenario" }
}
```

Native matrix가 모두 통과한 뒤 built export를 fastrun `codex` lane에서 제공하고
각 scenario를 다음 URL 형식으로 실행한다.

```text
http://127.0.0.1:<codex-port>/index.html?performance-scenario=capacity_pressure&performance-warmup=10&performance-duration=60
```

각 run에서 tab을 visible/focused 상태로 유지하고
`window.__cardbornePerformanceResultJson`이 생길 때까지 기다린다. JSON을
`build/performance/pre-asset/web/<scenario>.json`으로 저장한 뒤 다음을 모두
검사한다.

- `scenario`가 요청값과 같음
- `authoritative == true`
- `scenario_validation.valid == true`
- `thresholds.passed == true`
- viewport logical/window가 1280×720 acceptance와 일치함

Web run 순서는 `production_replay`, `peak_horde`, `capacity_pressure`,
`boss_pressure`로 고정한다. 마지막 native lifecycle command는 다음과 같다.

```powershell
$lifecycleArgs = @(
  "--rendering-method", "gl_compatibility", "--",
  "--performance-scenario=lifecycle_pressure",
  "--performance-warmup=10",
  "--performance-duration=600",
  "--performance-output=res://build/performance/pre-asset/lifecycle_pressure.json"
)
.\tools\godot.ps1 @lifecycleArgs
```

Native 1280×720 기준은 median 59 FPS 이상, p95 18 ms 이하, p99 25 ms
이하, 1% low 55 FPS 이상, 33.3 ms 초과 연속 frame 1 이하이다.
capacity/lifecycle physics는 p95 6 ms 이하, p99 8 ms 이하이며 lifecycle static
memory growth는 8 MiB 미만이다. draw-call p95 200, combat batch 50, world batch
12 상한도 유지한다. Web은 recorder가 정의한 platform gate를 그대로 사용한다.

## Asset-production Gate

다음 항목 중 하나라도 실패하면 image generation, repaint, replacement path
switch를 시작하지 않는다.

- 정본 문서에 single craft와 shell taxonomy가 반영됨
- player runtime asset 1 / attachment 0
- structural shell physical file 5 / semantic margin 보존
- map optional adapter와 functional footprint validator 통과
- inventory 세 상태 축과 current-repo-only build 통과
- native 및 built-Web performance matrix 통과
- 600초 lifecycle soak 통과
- 전체 validator, import, Web export, built runtime QA 통과
- acceptance evidence checkpoint 기록 완료

## Rollback / Safety

- milestone마다 독립 commit을 만들고 unrelated user change를 stage하지 않는다.
- binary rename/delete 전에 manifest와 runtime reference를 먼저 제거하고 focused
  validator를 통과시킨다. 삭제 파일은 git history에서 복구 가능하다.
- regression 시 hard reset이 아니라 해당 task-owned milestone commit의
  명시적 revert 또는 작은 follow-up fix를 사용한다.
- map provider는 빈 `map_surfaces`를 정상 fallback으로 취급하므로 미승인 asset
  없이 되돌릴 수 있다.
- performance optimization은 current thresholds와 content load를 보존한다.
  통과하지 못하면 plan은 active 상태로 남고 asset gate는 닫힌다.
- performance/built-Web helper는 task-owned process만 종료한다.

## Risks

| 위험 | 대응 |
| --- | --- |
| mount 제거 후 manual aim이 약하게 보임 | cursor, muzzle, projectile 방향을 orthogonal fixture와 capture로 고정 |
| 같은 shell image alias가 margin까지 합침 | physical file과 Theme variation을 별도 계약으로 검증 |
| staged map PNG가 실수로 runtime 적용됨 | production `map_surfaces`만 provider가 읽고 현재 section은 비워 둠 |
| 임시 facility raster 확대가 거칠게 보임 | footprint correctness를 먼저 고정하고 repaint는 gate 이후 별도 승인 |
| grid swap-remove가 hit order를 바꿈 | `hit_t` + stable-slot tie-break와 first-hit regression 추가 |
| schedule 변경이 attack cadence를 바꿈 | 60/10/30/20 Hz와 commit cap snapshot을 before/after fixture로 비교 |
| snapshot rename이 capture/UI를 끊음 | producer와 모든 consumer/validator를 한 milestone에서 원자적으로 변경 |
| 성능 작업이 끝나지 않음 | threshold 통과 전 plan을 완료하지 않고 asset production을 금지 |

## Open Questions

없음. 구현 중 새 사실이 이 결정과 충돌하면 추측으로 범위를 넓히지 않고 이
ExecPlan의 Decision Notes를 먼저 갱신한다.

## Decision Notes

- 2026-08-02: player visual은 한 composite actor asset으로 고정했다. 별도
  engine/aim mount asset은 퇴역하고 aim/thrust는 intent와 transient VFX다.
- 2026-08-02: UI shell은 screen 수가 아니라 structural chrome으로 정의하며,
  동일 pixel을 다섯 physical file로 합친다.
- 2026-08-02: unapproved map raster 수와 이름은 code contract가 아니다. 실제
  geometry가 생성하는 최소 topology role만 code에 둔다.
- 2026-08-02: inventory runtime, review decision, guide availability를 독립
  상태로 분리하고 `approved`만 production queue에 들어간다.
- 2026-08-02: 일반 적/boss 전략은 이 계획에서 제외하며 capacity와 cadence를
  낮추지 않고 성능을 해결한다.
- 2026-08-02: 모든 code, validation, performance gate를 통과하기 전에는 새
  asset을 만들지 않는다.

## Definition of Done

- 정본 spec과 runtime code가 single-craft 계약으로 일치한다.
- player actor는 한 raster/한 batch이고 별도 player attachment가 없다.
- UI structural shell은 다섯 physical raster이며 screen content와 control skin은
  각 owner에 남는다.
- map asset adapter는 승인 asset이 없어도 deterministic fallback으로 검증되고,
  functional terrain body가 live footprint와 일치한다.
- inventory는 current repo만으로 재생성되고 세 상태 축과 hierarchy가
  명확하며 manifest/file coverage가 완전하다.
- native/Web release performance와 600초 lifecycle gate가 모두 통과한다.
- full validation, Web export, built runtime QA와 evidence update가 끝난다.
- 이 계획을 수행하는 동안 새 visual asset file을 생성하지 않는다.
- durable 결정이 정본 spec/evidence에 흡수된 뒤 완료된 ExecPlan을 삭제한다.
