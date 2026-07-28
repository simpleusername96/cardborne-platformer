---
type: plan
status: active
owner: BK
created: 2026-07-28
last_reviewed: 2026-07-28
scope: Produce and integrate a source-backed space-hangar world and raster UI chrome while preserving Cardborne gameplay and live UI truth
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../visual-system-design-selection-plan.md
  - ./2026-07-27-pixel-art-visual-recovery.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../pixel-art-production/README.md
---

# Cardborne 우주 격납고 월드·UI 이미지 에셋 통합 실행 계획

선택된 우주 격납고 시안과 현재 1280×720 게임 화면을 기준으로, 먼저
실제 타일·구조물·소품 원본을 만들고 검토 가능한 맵 한 장을 완성한다.
승인 전 산출물은 candidate/evidence에만 두며 런타임에 연결하지 않는다.
승인 후에만 같은 에셋 계약을 월드 렌더러와 UI 9-slice chrome에 적용한다.

## Why / Context

`d2ffa2f`의 첫 프로토타입은 작은 바닥 crop을 네 색으로 양자화한 뒤
4-neighbor 전이 빈도와 강제 Wang 경계를 사용했다. 결과는 기술적으로
반복 가능했지만 승인 이미지의 패널, 벽 chassis, 설비, 소품 문법을
보존하지 못했다. 계획서가 약속한 overlapping WFC, ConvChain의 실제
`N×N` 분포, FastNoise macro weighting, 승인 raster stamp도 구현하지
않았고, 구조와 소품을 코드 선·사각형으로 대신했다.

이 프로토타입은 실패 증거로만 유지한다. production asset이나 승인된
알고리즘으로 간주하지 않는다.

## Purpose

- **Objective:** 승인 이미지에 실제로 보이는 우주 격납고 재질과 설비를
  반복 가능한 pixel asset과 별도 overlay로 만들고 현재 게임 레이아웃에
  조립한다.
- **Immediate artifact:** 네이티브 타일 확대판, source asset sheet,
  base/structure/prop 분리층, 1280×720 실제 맵 후보.
- **First runtime artifact:** 승인된 한 필드의 safe-arrival와
  maximum-pressure 실행 화면.
- **Completion state:** 월드와 UI가 승인된 raster asset을 사용하고,
  gameplay geometry·텍스트·수치·입력·상태는 기존 owner에 남는다.

## Pre-plan Evidence Already Verified

| Source | Verified fact | Locked decision |
| --- | --- | --- |
| `call_fNU2GdTyzih0wzwInUvEEC1y.png`, 1672×941 | 선택된 방향은 near-black space, 두꺼운 graphite chassis, cool blue-gray deck, cobalt rail, mint edge, 소량의 mustard 표시등을 사용한다. | 유일한 visual-direction reference로 repo-local 복사본을 보존한다. |
| `build/captures/final-ko-1280/10-field-storm-drydock-field.png`, 1280×720 | 실제 HUD, arena, side surge, cover, 중앙 전투 공간이 이미 정해져 있다. | 스타일은 바꾸되 화면 topology와 중심 가독성은 보존한다. |
| `scripts/presentation/vehicle_pixel_world_mesh_builder.gd` | 현재 월드는 geometry-fed `Polygon2D` repeat texture를 사용하며 `TileMapLayer`가 아니다. | 런타임을 WFC/TileMap으로 교체하지 않는다. |
| `pixel-art-production/runtime/tiles/hangar-*.png` | 기존 repeat texture는 안전하지만 지나치게 단순하다. | 기존 파일은 rollback 자산이며 새 후보 승인 전 교체하지 않는다. |
| `pixel-art-production/runtime/atlases/cardborne-pixel-atlas.png` | 월드 관련 64×64 frame이 있으나 floor/wall은 단순하고 일부 fixture는 `legacy_procedural`이다. | 기존 atlas frame은 geometry/scale 참고로만 사용하고 새 방향의 시각 원본으로 재사용하지 않는다. |
| `pixel-art-production/design/visual-research/reference-manifest.json` | CC0 샘플도 현재 정책상 reference-only이며 Godot import 대상이 아니다. | 외부/CC0 픽셀을 crop하여 production art로 사용하지 않는다. |
| [mxgmn/WaveFunctionCollapse](https://github.com/mxgmn/WaveFunctionCollapse) | overlapping model은 입력에 존재하는 `N×N` 패턴의 local legality를 다루며 contradiction이 가능하다. sample/tiles는 MIT 코드 라이선스에 포함되지 않는다. | 타일 그림 생성기로 채택하지 않는다. |
| [mxgmn/ConvChain](https://github.com/mxgmn/ConvChain) | 실제 알고리즘은 `N×N` pattern energy를 사용하는 MCMC이며 수렴·온도·iteration tuning이 필요하다. | 이름만 차용한 근사 구현을 금지하고 이번 production path에서 제외한다. |
| [Godot 4.7 TileSet](https://docs.godotengine.org/en/4.7/tutorials/2d/using_tilesets.html) | terrain은 이미 제작된 tilesheet의 연결 variant를 선택한다. | 기존 polygon renderer를 유지하므로 TileSet terrain을 추가하지 않는다. |
| [Tiled terrains](https://doc.mapeditor.org/en/stable/manual/terrain/) | 두 terrain edge set의 16 tile은 연결 규칙이지 미술 생성기가 아니다. | 별도 Tiled authoring/data pipeline을 추가하지 않는다. |

External sources were checked on 2026-07-28. Recheck only if the implementation
later adds an external dependency or switches renderer ownership.

## Locked Decisions

| Topic | Final decision | Rationale |
| --- | --- | --- |
| Art-first order | full-map visual target와 source asset family를 먼저 만들고, native/4× review를 통과한 뒤 compiler를 수정한다. | 첫 실패는 code-first 순서에서 발생했다. |
| Asset origin | ImageGen은 승인 reference와 current gameplay capture를 입력으로 사용해 source raster를 만든다. | 승인 이미지의 motif를 실제 픽셀 원본에 보존한다. |
| Script boundary | script는 crop, nearest resize, palette mapping, alpha cleanup, packing, hashing, placement, validation만 수행한다. `draw_line`, `fill_rect`, polygon으로 장식·소품을 창작하지 않는다. | 이미지 에셋과 배치 로직의 책임을 분리한다. |
| Base material | deck/wall/void는 각각 별도 ImageGen master에서 추출한 seam-safe variant를 사용한다. 각 24×24 tile은 2px neutral perimeter를 가지며 detail은 안쪽 20×20에만 존재한다. | 모든 variant가 방향과 무관하게 연결되며 16개 가짜 Wang signature가 필요 없다. |
| Base palettes | deck `n=3`: `#2E3945`, `#44515E`, `#596774`; wall `n=4`: `#141B24`, `#202833`, `#2E3945`, `#596774`; void `n=2`: `#141B24`, `#202833`. | canonical `pixel-hangar-v1` 안에서 재질 역할을 분리한다. |
| Variant counts | deck 12, wall 8, void 4 variants. | 1280×720 proof에서 반복 판단이 가능하면서 review surface가 과도해지지 않는다. |
| Expansion | 24px library의 seam proof는 visual cell `(x,y)` fixed integer hash로 variant/transform을 고른다. 실제 field proof는 source-derived 192px repeat master를 2× nearest로 반복해 runtime의 384 world-pixel period를 그대로 재현한다. | deterministic 확장성과 실제 renderer 일치를 함께 검증하되 WFC를 가장하지 않는다. |
| Runtime base format | compiler는 palette-mapped 256px material의 중앙 192px crop에 1px neutral perimeter를 적용한 `192×192` repeat master 세 장을 출력한다. 승인 후 기존 `hangar-floor.png`, `hangar-wall.png`, `hangar-water.png`를 교체한다. | 큰 source panel을 보존하고 현재 `Polygon2D` renderer와 `REPEAT_TILE_UV_SCALE=0.5`를 그대로 사용한다. |
| Macro structure | panel seam, chassis edge, corner, rail, service bay는 승인된 transparent structure stamps에서만 가져온다. | base texture가 topology를 가장하지 않게 한다. |
| Props | hatch, vent, console, cargo module, machinery, warning plate는 승인된 prop sheet crop만 배치한다. | 코드 사각형 소품을 금지한다. |
| Wear | 8개 이하의 승인된 low-contrast wear stamp를 96px 이상 간격으로 둔다. | speckle과 전투 정보 경쟁을 막는다. |
| Layout | arena `(156,106,968,514)`, side surge와 existing cover topology를 보존하고 center `(500,250,280,250)`는 prop/wear 금지로 둔다. | 현재 gameplay capture와 telegraph 여백을 보존한다. |
| Candidate boundary | 새 asset과 map은 user approval 전 `assets/source/candidates`와 `evidence`에만 둔다. | active visual spec과 runtime을 조용히 변경하지 않는다. |
| Runtime publication | 승인 후 기존 geometry-fed renderer에 atlas lookup/overlay batch를 추가한다. Collision truth는 변경하지 않는다. | gameplay architecture를 보존한다. |
| UI chrome | panel/button/card/tab은 같은 source kit에서 별도 raster family로 생성하고 9-slice safe inset을 검증한다. Text, number, binding, focus truth는 live `Control`이다. | 월드와 UI를 같은 이미지 문법으로 묶되 localization을 보존한다. |
| Dependencies | Godot 4.7, GDScript, 기존 ImageMagick, built-in ImageGen만 사용한다. 새 package/plugin은 추가하지 않는다. | production dependency와 supply-chain 변경을 피한다. |

## Rejected Alternatives

| Alternative | Why rejected |
| --- | --- |
| ConvChain + overlapping WFC + Wang chain | 세 개의 서로 다른 문제를 한 pipeline으로 묶고도 좋은 source art를 만들지 못한다. 현재 prototype은 실제 알고리즘도 구현하지 않았다. |
| Godot/Tiled terrain migration | 현재 map topology owner와 polygon renderer를 불필요하게 교체하며 art quality를 개선하지 않는다. |
| Runtime noise texture | 얼룩과 speckle을 만들 뿐 승인된 패널·설비 motif를 만들지 못한다. |
| Full-screen generated gameplay background | collision과 state truth에서 이탈하고 다른 map layout으로 확장되지 않는다. |
| Script-authored lines/rectangles as missing art | 첫 prototype의 실패 원인이므로 production fallback으로 금지한다. |
| Existing CC0 tile crop/recolor | reference-only 정책과 선택된 시각 방향 모두에 맞지 않는다. |

## Current State

Already true:

- 승인 방향 이미지와 현재 gameplay capture가 존재한다.
- 실패 prototype generator와 proof가 commit `d2ffa2f`에 기록되어 있다.
- world renderer의 geometry/collision separation과 rollback textures가 있다.
- `pixel-hangar-v1` palette와 pixel production pipeline이 있다.
- Gate A source family, prompt/provenance, rejected retry evidence가 생성됐다.
- Gate B compiler, schema, recipe, atlas, layer proof, final map이 생성됐다.

Remaining:

- Gate A/B 시각 승인을 받는다.
- 승인 후 runtime/UI publication을 수행한다.

## Scope / Non-scope

In scope:

- world candidate source generation, cleanup, packing, deterministic placement;
- 24×24 base variants, transparent structure/wear/prop stamps;
- current-layout 1280×720 map proof와 확대 review artifacts;
- 승인 후 one-field runtime vertical slice;
- 이후 panel/button/card/tab raster chrome와 safe-inset templates.

Out of scope until explicit visual approval:

- runtime texture replacement;
- collision, navigation, spawn, combat, balance, save data, audio, copy changes;
- canonical `UI_VISUAL_SYSTEM.md` direction replacement;
- broad UI rollout.

Destructive or irreversible actions:

- none. 기존 prototype과 runtime asset은 replacement가 승인·검증될 때까지
  삭제하지 않는다.

Exact approval gates:

- Gate A: full-map target와 deck/wall/void/structure/prop source family의
  visual approval.
- Gate B: native/4× tile atlas와 base/overlay/final map proof approval.
- Gate C: one-field live capture approval.
- Gate D: UI chrome source/9-slice candidate approval.
- Gate E: UI runtime migration and final rollout approval.

## Proposed Design / Architecture and Ownership

| Concern | Owner | Contract |
| --- | --- | --- |
| Direction reference | `pixel-art-production/evidence/design-directions/2026-07-28/space-hangar-v2/` | selected image와 current capture의 repo-local copies |
| Provider originals | `pixel-art-production/assets/source/candidates/space-hangar-v2/provider-originals/` | ImageGen native output를 byte-for-byte 보존; production에서 직접 참조 금지 |
| Normalized raw art | `pixel-art-production/assets/source/candidates/space-hangar-v2/raw/` | provider output을 nearest-resize한 고정 입력 규격; production에서 직접 참조 금지 |
| Prompt/provenance | `pixel-art-production/assets/source/candidates/space-hangar-v2/prompts/`, `pixel-art-production/assets/source/candidates/space-hangar-v2/source-manifest.json` | input roles, exact prompt, source hash, generation path |
| Clean candidate art | `pixel-art-production/evidence/space-hangar-v2/clean/` | palette/alpha/grid 정규화 후 review 대상 |
| Candidate compiler | `tools/design/build_space_hangar_candidate.gd` | crop/quantize/pack/place/validate only |
| Candidate recipe | `pixel-art-production/assets/recipes/candidates/space-hangar-v2.json` | palettes, crop cells, neutral edge, placements, seed |
| Recipe schema | `pixel-art-production/schemas/space-hangar-candidate-recipe.schema.json` | source paths, base families, stamp IDs/cells, proof layout, output contract의 machine-readable mirror; compiler validator가 실행 시 같은 fixed contract를 강제 |
| Review evidence | `pixel-art-production/evidence/space-hangar-v2/` | native atlas, 4× atlas, layer PNGs, final map, validation JSON |
| Runtime base | existing `pixel-art-production/runtime/tiles/hangar-{floor,wall,water}.png` | 승인된 192×192 masters로 교체; renderer interface 불변 |
| Runtime stamps | `pixel-art-production/runtime/atlases/space-hangar-structure-atlas.png`, `pixel-art-production/runtime/atlases/space-hangar-prop-atlas.png` | 각각 4×4 grid, 64×64 cell, nearest-filtered |
| Runtime placement | `scripts/presentation/vehicle_pixel_world_mesh_builder.gd` | candidate proof의 42개 stamp를 수용하되 필드당 최대 48개 region-enabled `Sprite2D`; wall/cover/feature/floor geometry에서만 anchor 계산 |
| UI candidate recipe | `pixel-art-production/assets/recipes/candidates/space-hangar-v2-ui.json` | file/state, native size, patch margin, content inset, Theme target |
| UI candidate schema | `pixel-art-production/schemas/space-hangar-ui-chrome.schema.json` | UI recipe의 family/state/9-slice contract 검증 |
| UI chrome validator | `tools/validation/validate_space_hangar_ui_chrome.gd` | dimensions, alpha, corner invariance, resize/text-fit proof |
| UI runtime assets | `pixel-art-production/runtime/ui/space-hangar-v2/` | Gate D에서 승인된 text-free PNG만 publish |
| UI asset factory | `scripts/ui/vehicle_ui_chrome_factory.gd` | 승인 후 PNG를 cached `StyleBoxTexture`로 만들고 semantic family/state를 제공 |
| UI consumers | existing `scripts/ui/vehicle_*.gd` screen owners | live text/state를 유지하고 factory의 semantic style만 적용 |

### Fixed candidate asset contract

ImageGen provider가 요청 크기와 다른 native bitmap을 반환하면 원본은 같은
basename으로 `provider-originals/`에 그대로 보존한다. `raw/` 파일은 art를
추가하거나 다시 그리지 않고 nearest-neighbor resize를 적용한 compiler 입력이다.
시트 전체가 cell grid에 치우친 경우에만 chroma fill을 사용한 whole-sheet integer
translation/crop을 허용하며, 셀별 이동·실루엣 수정은 금지한다. Map target은
`1280×720`, 나머지 다섯 source는 `1024×1024`다. Manifest에는 provider 원본과
normalized raw의 경로, native size, SHA-256, resize/translation operation을 모두
기록한다.

Normalized raw files:

- `pixel-art-production/assets/source/candidates/space-hangar-v2/raw/full-map-target.png`
- `pixel-art-production/assets/source/candidates/space-hangar-v2/raw/deck-material-master.png`
- `pixel-art-production/assets/source/candidates/space-hangar-v2/raw/wall-material-master.png`
- `pixel-art-production/assets/source/candidates/space-hangar-v2/raw/void-material-master.png`
- `pixel-art-production/assets/source/candidates/space-hangar-v2/raw/structure-sheet.png`
- `pixel-art-production/assets/source/candidates/space-hangar-v2/raw/prop-sheet.png`

Clean files:

- `pixel-art-production/evidence/space-hangar-v2/clean/deck-material-master.png`
- `pixel-art-production/evidence/space-hangar-v2/clean/wall-material-master.png`
- `pixel-art-production/evidence/space-hangar-v2/clean/void-material-master.png`
- `pixel-art-production/evidence/space-hangar-v2/clean/structure-atlas.png` — 4×4, 64×64 cells, 256×256
- `pixel-art-production/evidence/space-hangar-v2/clean/prop-atlas.png` — 4×4, 64×64 cells, 256×256
- `pixel-art-production/evidence/space-hangar-v2/clean/base-variant-atlas.png` — 12 columns × 2 rows, 24×24 cells, 288×48; deck is row 0 columns 0–11, wall is row 1 columns 0–7, void is row 1 columns 8–11
- `pixel-art-production/evidence/space-hangar-v2/clean/hangar-floor-master.png`
- `pixel-art-production/evidence/space-hangar-v2/clean/hangar-wall-master.png`
- `pixel-art-production/evidence/space-hangar-v2/clean/hangar-water-master.png`

The three repeat masters are each `192×192`.

Each raw material master is `1024×1024`. The compiler reduces it to a
`256×256` logical surface, palette-maps it, and extracts fixed 24×24 windows.
Void alone is Lanczos-reduced to 32px and nearest-expanded before two-color
mapping so provider micro-noise cannot become speckle:

- deck: `(104,48)`, `(136,48)`, `(104,80)`, `(136,80)`, `(112,104)`,
  `(144,104)`, `(24,96)`, `(184,64)`, `(184,184)`, `(48,144)`,
  `(104,184)`, `(200,208)`;
- wall: x `{16,80,144,208}` × y `{48,176}` = 8;
- void: x `{16,80,144,208}` × y `{116}` = 4.

Each raw structure/prop sheet is `1024×1024` with a strict 4×4 grid of
`256×256` source cells. Chroma cleanup, alpha-bound crop, palette map, and
nearest fit place structure/prop/wear silhouettes on a 64px cell with long-axis
limits `56/42/32` respectively. Proof placements may declare a target size only
to fit that same raster silhouette into an existing feature or cover rectangle;
free scaling and cell-local redrawing are forbidden. A raw file with another
size or a subject crossing its cell boundary fails Gate A.

Structure cell IDs, row-major:

`frame_h`, `frame_v`, `corner_nw`, `corner_ne`, `corner_se`, `corner_sw`,
`rail_h`, `rail_v`, `service_bay_h`, `service_bay_v`, `cover_small`,
`cover_wide`, `bulkhead_h`, `bulkhead_v`, `inner_cap_h`, `inner_cap_v`.

Prop cell IDs, row-major:

`hatch_round`, `vent_round`, `console_small`, `console_wide`, `cargo_small`,
`cargo_wide`, `machinery_small`, `machinery_tall`, `warning_plate`,
`pipe_cluster`, `cable_coil`, `terminal`, `wear_scrape_a`, `wear_scrape_b`,
`wear_chip_a`, `wear_chip_b`.

Recipe top-level keys are fixed:

`schema_version`, `seed`, `sources`, `base_families`, `structure_stamps`,
`prop_stamps`, `proof_layout`, `outputs`. Each base family declares
`palette`, `neutral_color`, `prequantize_sample_size`, `variant_count`, and
`sample_windows`. Sources declare the fixed provenance-manifest path and
`56/42/32` stamp fit contract.
Each stamp declares `id`, `cell`, `role`, and `allowed_anchor`; a proof
placement may additionally declare geometry-owned `target_size`.
`allowed_anchor` is one of `boundary`, `cover`, `bulkhead`, `feature`, or
`floor_flat`; the compiler and runtime validator reject every other value.

### Fixed UI chrome candidate contract

Candidate files live under
`pixel-art-production/assets/source/candidates/space-hangar-v2/ui/clean/`.
Every PNG is text-free RGBA, nearest-filtered, and uses transparent pixels only
outside its chrome silhouette.

| Family and state files | Native size | Patch margins L/R/T/B | Content insets L/R/T/B |
| --- | --- | --- | --- |
| `panel-normal.png` | 96×96 | 16/16/16/16 | 20/20/20/20 |
| `button-normal.png`, `button-hover.png`, `button-pressed.png`, `button-focus.png`, `button-disabled.png` | 96×32 | 12/12/8/8 | 14/14/8/8 |
| `card-normal.png`, `card-hover.png`, `card-pressed.png`, `card-focus.png`, `card-selected.png`, `card-disabled.png` | 96×128 | 16/16/16/16 | 20/20/20/20 |
| `tab-normal.png`, `tab-hovered.png`, `tab-selected.png`, `tab-focus.png` | 72×32 | 12/12/8/8 | 14/14/8/8 |
| `hud-frame-normal.png` | 128×48 | 16/16/12/12 | 18/18/14/14 |

The UI recipe is
`pixel-art-production/assets/recipes/candidates/space-hangar-v2-ui.json`;
its schema is
`pixel-art-production/schemas/space-hangar-ui-chrome.schema.json`.
Required top-level keys are `schema_version`, `source_family`, `families`,
`theme_targets`, and `proofs`. Each family declares `outputs`,
`native_size`, `patch_margins`, `content_insets`, and `states`. An undeclared
file, state, size, margin, or inset is a hard validation failure.

State-to-Godot mapping is fixed:

- `PanelContainer` background and modal surfaces use `panel-normal.png` as
  `panel`;
- `Button` uses the five button files as `normal`, `hover`, `pressed`, `focus`,
  and `disabled`;
- `UpgradeChoiceCard` maps `normal`, `hover`, `pressed`, `focus`, and
  `disabled` to the same-named card files. `SelectedUpgradeChoiceCard` maps
  `normal`/`hover`/`focus` to `card-selected.png`, `pressed` to
  `card-pressed.png`, and `disabled` to `card-disabled.png`. Guidebook/result
  card consumers use one of those two complete semantic variations rather than
  inventing screen-local state mappings;
- `TabContainer` and `TabBar` map `tab_unselected`, `tab_hovered`,
  `tab_selected`, and `tab_focus` to `tab-normal.png`, `tab-hovered.png`,
  `tab-selected.png`, and `tab-focus.png`; disabled tab truth remains live
  font/icon modulation because Godot exposes no `tab_disabled` StyleBox slot;
- HUD status groups use `hud-frame-normal.png` as `panel`.

`VehicleUiChromeFactory` is the only owner that constructs and caches
`StyleBoxTexture` objects. It sets `texture_margin_*` from the recipe patch
margins, `content_margin_*` from the declared content insets, and stretch mode
to tile only the stable center/edge bands. Screen owners retain live focus,
selection, disabled, hover, pressed, localization, number, cooldown, and
progress state; those values are never baked into PNGs.

`tools/validation/validate_space_hangar_ui_chrome.gd` validates exact file
inventory, RGBA/native size, recipe/schema agreement, equal corner pixels
across states within one family, and 9-slice proofs at 1×, 1.5×, and 2×. The
proof set includes realistic Korean and English strings at 960×540, 1280×720,
and 1920×1080 and fails on clipped content, edge distortion, or focus-state
ambiguity.

## As-Is / To-Be Delta Map

| Concern | As-is | To-be | Acceptance | Guard |
| --- | --- | --- | --- | --- |
| Base tile | near-uniform crop의 fake Wang variants | 12/8/4 authored neutral-edge variants | native와 4×에서 각 family의 variant가 구분되고 seam이 없다 | exact palette, opacity, 2px perimeter |
| Structure | code line/rectangle | transparent raster stamp sheet | wall frame, corners, rails, service bay가 source sheet와 동일 | compiler에 art drawing primitive 없음 |
| Props | code rectangles | hatch/vent/console/cargo/machinery stamps | 최소 5 silhouette family가 gameplay scale에서 구분됨 | center/no-go와 blocker legality |
| Map proof | 희소 기술 데모 | current layout의 rich hangar composite | 승인 reference의 frame/material/fixture density가 읽힘 | 중앙 전투 가독성, HUD-safe bounds |
| Algorithm claim | WFC/ConvChain 이름과 실제 구현 불일치 | neutral-edge authored variants + deterministic hash | recipe와 code가 동일한 방법을 기록 | manifest에 구현하지 않은 알고리즘 이름 없음 |
| UI | `StyleBoxFlat` | image-backed 9-slice chrome | KO/EN과 3 viewport에서 clipping 없음 | text/state baked into PNG 금지 |

## Tasks

### Phase 0 — Plan and failure-state correction

- [x] **0.1** Audit the old plan against `d2ffa2f`.
- [x] **0.2** Remove unsupported WFC/ConvChain/FastNoise/Poisson claims.
- [x] **0.3** Lock an authored-asset, neutral-edge variant architecture.
- [x] **0.4** Commit this plan repair before new asset implementation.

Acceptance: a future executor can implement without selecting an algorithm or
inventing missing-art behavior.

Guard: `d2ffa2f` remains labeled prototype evidence, not production approval.

### Phase 1 — Visual-source gate

- [x] **1.1** Copy the approved direction and current gameplay capture into the
  repo-local direction evidence folder.
- [x] **1.2** Generate one text-free 1280×720 map target preserving the current
  arena/HUD-safe layout.
- [x] **1.3** Generate one seamless deck-material master using only the locked
  blue-gray material family.
- [x] **1.4** Generate one seamless wall-material master using only the locked
  graphite material family.
- [x] **1.5** Generate one quiet void-material master using only the locked
  near-black material family.
- [x] **1.6** Generate one 4×4 isolated structure sheet on a removable chroma
  background: straight chassis, inner/outer corners, rail, service bay,
  cover shell.
- [x] **1.7** Generate one 4×4 isolated prop sheet on a removable chroma
  background: hatch, vent, console, cargo, machinery, warning plate, wear.
- [x] **1.8** Preserve provider-native outputs, nearest-normalize them to the
  fixed raw sizes, and save exact prompts, both source hashes, and the resize
  operation beside the raw outputs.
- [x] **1.9** Inspect each source at native and 4× logical scale.

Acceptance:

- source assets visibly share the approved graphite/blue-gray/cobalt/mint
  language;
- no text, UI labels, player, enemies, pickups, telegraphs, or baked shadows;
- sprite cells are isolated and crop-safe;
- map target preserves center clearance and existing side features.

Guard:

- at most two ImageGen attempts per family;
- a failed family is regenerated, never repaired with script-drawn art;
- no raw image becomes runtime input.

### Phase 2 — Candidate asset compiler

- [x] **2.1** Add the candidate recipe with exact palettes, cell crops, output
  dimensions, seed, and placement sockets.
- [x] **2.2** Add and validate
  `pixel-art-production/schemas/space-hangar-candidate-recipe.schema.json`.
- [x] **2.3** Add `build_space_hangar_candidate.gd`.
- [x] **2.4** Downsample/quantize the three material masters and publish
  12 deck, 8 wall, and
  4 void 24×24 variants with 2px neutral perimeter.
- [x] **2.5** Assemble three 192×192 repeat masters from the palette-mapped
  source centers with a 1px neutral perimeter.
- [x] **2.6** Remove chroma, crop, nearest-resize, and palette-map structure,
  prop, and wear cells without redrawing their silhouettes.
- [x] **2.7** Pack the fixed-layout native and 4× review atlases.
- [x] **2.8** Write source/output hashes and validation results.

Acceptance:

- exact counts, dimensions, opacity/alpha, palettes, and perimeter checks pass;
- 2×2, 3×3, offset 20×12 mosaics have zero edge mismatch;
- every output pixel traces to a generated source cell or declared palette map;
- no compiler function creates decorative geometry.

Guard:

- missing/invalid source family is a hard failure;
- staging/publish preserves the previous verified candidate on failure.

### Phase 3 — Current-layout map proof

- [x] **3.1** Assemble `base`, `structure`, `wear`, `props`, and `final` layers.
- [x] **3.2** Use 192px source-derived masters at 2× for the field proof and
  deterministic coordinate hash only for 24px library seam mosaics.
- [x] **3.3** Place structure/props from recipe sockets derived from current
  layout; never derive collision from asset alpha.
- [x] **3.4** Export final 1280×720, a target-vs-candidate side-by-side, and
  preserve the repo-local current gameplay capture as separate direction
  evidence.

Acceptance:

- arena/chassis, covers, two side surge bays, 6–10 fixtures, and 4 corner/edge
  landmarks are visible;
- center no-go has no prop/wear;
- base repetition is not obvious at 100% view;
- props remain distinguishable at gameplay scale;
- final map is materially richer than `d2ffa2f`, not merely more speckled.

Guard:

- no HUD or gameplay state is baked into the map;
- decoration never creates a false wall, opening, hazard, pickup, or target.

### Phase 4 — One-field runtime vertical slice

- [ ] **4.1** Publish only the approved candidate family to runtime assets.
- [ ] **4.2** Replace only the three existing 192×192 repeat masters; keep the
  current `Polygon2D` texture interface and UV scale.
- [ ] **4.3** Add the two fixed 4×4 / 64px stamp atlases.
- [ ] **4.4** Extend `VehiclePixelWorldMeshBuilder` with at most 48
  region-enabled `Sprite2D` decorations; the approved candidate currently uses
  42 (28 structure, 10 prop, 4 wear). Anchors come only from existing
  floor-boundary segments, cover rectangles, bulkheads, and feature rectangles:
  frame/rail stamps on boundaries, cover/bulkhead stamps on solid geometry,
  service-bay stamps on feature rectangles, flat hatch/wear stamps on legal
  floor. No independent collision or navigation data is added.
- [ ] **4.5** Resolve atlas regions exclusively through the fixed stamp ID table
  above; unknown IDs are hard failures in the validator.
- [ ] **4.6** Keep decorative sprite count in
  `debug_contract()["decoration_count"]` and enforce `<=48`.
- [ ] **4.7** Capture safe-arrival and maximum-pressure states in Korean and
  English at 1280×720.

Acceptance: live result matches the approved map proof closely enough that the
same wall, floor, rail, cover, and prop families are recognizable.

Guard: existing repeat textures remain the rollback path until final gate.

### Phase 5 — World rollout and UI chrome candidate

- [ ] **5.1** Apply the approved world family to all fields without changing
  stage geometry or gameplay semantics.
- [ ] **5.2** Generate panel, button, card, tab, and HUD-frame source families
  from the same visual language.
- [ ] **5.3** Add and schema-validate
  `pixel-art-production/assets/recipes/candidates/space-hangar-v2-ui.json`
  using the exact file, state, size, patch-margin, inset, and Theme mappings
  above.
- [ ] **5.4** Build the declared candidate state files under
  `pixel-art-production/assets/source/candidates/space-hangar-v2/ui/clean/`.
- [ ] **5.5** Run
  `tools/validation/validate_space_hangar_ui_chrome.gd`.
- [ ] **5.6** Render static safe-inset proofs for panel, button, card, tab, and
  HUD frame using realistic Korean and English strings at all three viewports.

Acceptance: Gate D approves the UI source family, state family, safe insets,
and text-fit proofs before any Godot Theme or screen is modified.

Guard: candidate UI PNGs contain no localized text, numbers, bindings, focus,
selection, cooldown, or progress truth.

### Phase 6 — UI runtime migration and final rollout

- [ ] **6.1** Publish the approved fixed file inventory to
  `pixel-art-production/runtime/ui/space-hangar-v2/`.
- [ ] **6.2** Add `scripts/ui/vehicle_ui_chrome_factory.gd`; construct and cache
  production `StyleBoxTexture` states exclusively from the approved recipe.
- [ ] **6.3** Migrate HUD, pause, upgrade, garage, settings, guidebook, report,
  and result screen owners to the fixed semantic mappings while preserving live
  Korean/English content and native Control state.
- [ ] **6.4** Update the canonical visual spec only after Gate E explicitly
  accepts the runtime rollout.

Acceptance: world and UI read as one game at all supported viewports without
reducing combat, focus, localization, or text-fit clarity.

## Milestones

1. Plan repair committed.
2. Gate A source assets and map target visible.
3. Gate B candidate atlas and current-layout map proof visible.
4. Gate C one-field runtime capture approved.
5. Gate D UI chrome candidates approved.
6. Gate E UI runtime migration and final rollout approved.

## Test Plan / Validation Cadence

Inner loop:

```powershell
$recipe = (Resolve-Path 'pixel-art-production/assets/recipes/candidates/space-hangar-v2.json').Path
$output = (Resolve-Path 'pixel-art-production/evidence').Path + '\space-hangar-v2'
$checkArgs = @('--path', '.', '--headless', '--script', 'res://tools/design/build_space_hangar_candidate.gd', '--', '--recipe', $recipe, '--check-only')
$buildArgs = @('--path', '.', '--headless', '--script', 'res://tools/design/build_space_hangar_candidate.gd', '--', '--recipe', $recipe, '--output', $output)
Get-Content -Raw $recipe | Test-Json -SchemaFile 'pixel-art-production/schemas/space-hangar-candidate-recipe.schema.json'
.\tools\godot.ps1 @checkArgs
.\tools\godot.ps1 @buildArgs
git diff --check
```

Candidate gates:

- image dimensions and alpha mode;
- exact material palettes and neutral perimeter;
- native/4× visual review;
- 2×2, 3×3, offset 20×12 seam mosaics;
- deterministic second-run SHA-256 equality;
- layer recomposition equality;
- center/no-go and geometry-legality checks.

Runtime gates after Phase 4 begins:

```powershell
.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_pixel_world_renderer.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_layouts.gd
.\tools\export_web.ps1
```

UIUX gate evidence:

- Surface: top-down vehicle action-shooter world, then raster UI chrome.
- Invocation depth: Level 4.
- Primary task: read floor/blocker/void, player, threats, telegraphs, rewards in
  that order.
- Viewports: 960×540, 1280×720, 1920×1080.
- States: safe arrival, maximum pressure, boss startup, pause, selected upgrade,
  garage, settings, guidebook, result.
- Localization: Korean and English.
- Blocker: any decorative asset that reads as gameplay geometry or clips live UI.

## Rollback / Safety

- Candidate assets stay outside runtime until approval.
- The candidate compiler accepts only
  `pixel-art-production/evidence/space-hangar-v2` as `--output`; it cannot
  publish directly into runtime or UI paths.
- Runtime publication is a separate scoped commit.
- Existing runtime repeat textures remain untouched through Phase 3.
- Failed generation never overwrites the last verified candidate; staging and
  atomic directory promotion are mandatory.
- No dependency, plugin, canonical spec replacement, or file deletion occurs
  without the corresponding explicit gate.

## Risks

- ImageGen may not respect exact sprite cells. Response: reject/regenerate the
  affected family; do not infer crops from overlapping subjects.
- Chroma removal may damage mint/cobalt edges. Response: use a key color absent
  from the asset family and validate transparent corners/fringe at 4×.
- Neutral-perimeter tiles can still look repetitive. Response: reject the base
  family at the 20×12 mosaic gate rather than adding noise.
- Rich props can compete with combat. Response: lower stamp count or reject the
  prop family; do not fade gameplay indicators.
- Active `UI_VISUAL_SYSTEM.md` remains canonical during candidate work.
  Response: do not claim the new direction is production until the approval gate.

## Assumptions

- The selected `call_fNU…png` remains the approved direction reference.
- Current gameplay layout and product rules remain unchanged.
- Candidate generation and proof work are authorized; runtime publication still
  requires the visual gates above.

## Open Questions

No material implementation question remains. New art-direction changes,
dependency additions, or runtime publication before Gate B require user approval
and a plan update.

## Decision Notes

- 2026-07-28: rejected the first pseudo-ConvChain/WFC prototype as production
  evidence after visual review.
- 2026-07-28: selected authored neutral-edge variants plus deterministic hash
  because it matches the current polygon renderer and makes no unsupported
  generative claim.
- 2026-07-28: locked ImageGen as source-art production and scripts as deterministic
  compilers/assemblers only.
- 2026-07-28: preserved 1254/1672px provider outputs and nearest-normalized
  fixed compiler inputs; manifest hashes and operations retain both provenance
  layers.
- 2026-07-28: rejected the first structure/prop sheets for cell-clearance
  failures, regenerated both families, then applied only a whole-sheet +9px
  alignment to the accepted prop sheet. No cell or silhouette was repaired.
- 2026-07-28: rejected the first 24px-per-cell full-map proof because its grid
  cadence and noise dominated the field. Kept 24px variants as the seam-tested
  asset library, while the map proof/runtime contract uses 192px source-derived
  masters at the renderer's 384 world-pixel repeat period.
- 2026-07-28: raised the runtime decoration cap from 16 to 48 because the
  approved-layout proof has 42 declared raster placements. This keeps the
  proof/runtime contract executable while preserving a small explicit cap.
- 2026-07-28: post-pass audit locked compiler output to the canonical evidence
  directory, aligned schema constraints with the executable validator, and
  linked exact per-asset normalization steps plus source-manifest/schema hashes
  into candidate evidence.

## Progress

- [x] Discovery and old-plan audit.
- [x] Algorithm and ownership decisions locked.
- [x] Plan repair committed.
- [x] Gate A source artifacts ready for review.
- [x] Gate B candidate map proof ready for review.
- [x] Schema/source/edge/layer validation and deterministic double build;
  `sha256.json` stayed
  `8e6f791eb57babc0c6cd67b57f57e9599b433e1dcaa59b26775c8c87cb2a2d2c`.
- [ ] Gate A/B visual approval.
- [ ] Gate C runtime vertical slice.
- [ ] Gate D UI chrome candidates.
- [ ] Gate E UI runtime migration and final rollout.

## Next Steps

1. Present the Gate A source family and Gate B current-layout map proof.
2. After explicit Gate A/B approval, execute the Phase 4 runtime vertical slice.
3. After Gate C approval, generate the Phase 5 UI chrome candidate family.

## Completion Criteria

- [ ] Every selected source family and map proof passes its visual and mechanical gate.
- [ ] No production path claims WFC, ConvChain, Poisson-disk, or other unimplemented algorithm.
- [ ] No missing art is replaced by script-authored decoration.
- [ ] Runtime and UI preserve gameplay, localization, focus, responsive layout, and collision truth.
- [ ] The canonical visual spec is updated only after explicit approval.
- [ ] The active plan is marked done and removed according to `.agents/PLANS.md` after durable decisions are incorporated.

## Stop Conditions

Complete when all completion criteria pass and durable specs own the accepted
behavior.

Escalate only when a source family fails twice, a requested change would alter
gameplay truth, a new dependency is required, or the user changes the visual
direction.

Do not stop for an implementation-local crop or placement defect that can be
fixed without changing the locked contract.

## Handoff

```text
Goal:
Create a rich current-layout space-hangar map from approved raster assets, then
publish it to runtime and UI only after visual gates.

Read first:
.agents/execplans/2026-07-28-space-hangar-world-ui-asset-integration.md
docs/design/UI_VISUAL_SYSTEM.md
pixel-art-production/README.md

Execute exactly:
Phase 1 source assets -> Phase 2 compiler -> Phase 3 map proof -> approval ->
Phase 4 runtime world -> Phase 5 UI candidates -> approval -> Phase 6 UI runtime.

Validate with:
Native/4x assets, seam mosaics, deterministic hashes, layer recomposition,
current-layout side-by-side, focused Godot validators, Web export.

Stop when:
The candidate fails a visual gate; never substitute procedural drawing.
```
