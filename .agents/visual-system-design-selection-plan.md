---
type: plan
status: active
owner: BK
created: 2026-07-28
scope: Select and approve one coherent Cardborne map, terrain, panel, and button visual direction before implementation
related:
  - ../AGENTS.md
  - ./AGENTS.md
  - ./PLANS.md
  - ./execplans/2026-07-27-pixel-art-visual-recovery.md
  - ../docs/product/vehicle_game_spec.md
  - ../docs/design/UI_VISUAL_SYSTEM.md
  - ../pixel-art-production/README.md
  - ../pixel-art-production/design/visual-research/PART_GUIDELINES.md
---

# Cardborne 맵·지형·UI 디자인 방향 결정 계획

현재 런타임의 정보 구조, 입력 흐름, 충돌·내비게이션 소유권은 유지하면서
맵, 지형지물, HUD 장식, 패널, 카드, 버튼을 하나의 Sunken Ceramic Fresco
문법으로 묶을 디자인 방향을 결정한다. 이 문서는 구현 계획이 아니라 세
시안을 같은 기준으로 비교하고 하나를 승인하기 위한 결정 계획이다. 승인
결과는 기존
`.agents/execplans/2026-07-27-pixel-art-visual-recovery.md`에 반영한 뒤
결정 완료형 실행 계획으로 사용한다.

## Purpose

- **결정 질문:** 현재 Cardborne UIUX의 기능과 배치를 보존하면서 맵,
  지형지물, 패널, 버튼을 어떤 하나의 시각 문법으로 제작할 것인가?
- **결정이 필요한 이유:** 현재 반복 텍스처와 직사각형 UI는 기능적으로
  연결되어 있지만, `sunken-ceramic-fresco.png`가 가진 큰 세라믹 질량,
  깊이 있는 경계, 희소한 랜드마크 문법을 충분히 공유하지 않는다.
- **최종 증거:** 같은 `1280x720` 일시정지 상태를 표현한 독립 시안 세 장.
  각 장은 실제 지형을 배경으로 하고 현재의 패널·버튼 계층을 그대로
  포함한다.
- **결정 소유자:** BK.

## Current Truth

검증된 현재 상태:

- `docs/design/UI_VISUAL_SYSTEM.md`는 deep-slate 보행면, cobalt
  water/void, ceramic green blocker, mustard 진행/주요 행동, coral 위험,
  magenta 보스, mint 지원, ivory UI 표면을 정한다.
- `scripts/presentation/vehicle_pixel_world_mesh_builder.gd`는
  `VehicleStageRules`와 `VehicleFieldLayout`의 폴리곤을 받아 floor,
  water, cover 반복 텍스처와 boundary batch만 그린다.
- 충돌, 내비게이션, 투사체 차단, 시야, 미니맵은
  `VehicleFieldGeometrySnapshot`, `VehicleStageRules`,
  `VehicleStageGeometry`, `VehicleRun`에 남아 있다.
- 현재 `hangar-floor.png`, `hangar-wall.png`, `hangar-water.png`는 반복
  가능하지만, 방향 연결 타일이나 큰 구조 모듈을 제공하지 않는다.
- `scripts/ui/vehicle_stage_ui.gd`가 HUD와 모달 전환을 조정하며,
  `art/ui/production/vehicle_stage_theme.tres`가 공용 패널·버튼 상태를
  소유한다.
- `VehicleUpgradeChoicePanel`은 선택·확인 흐름을,
  `VehicleUpgradeChoiceCard`는 한 장의 고정된 카드 표현만 소유한다.
- 한국어와 영어 문자열, 수치, 포커스, 선택, 쿨다운은 모두 live UI이며
  래스터 에셋에 굽지 않는다.

기준 화면:

- 맵·HUD:
  `pixel-art-production/evidence/gates/08-final-migration/gameplay-pass-3/10-field-drowned-ruin-field.png`
- 업그레이드 카드:
  `pixel-art-production/evidence/gates/08-final-migration/gameplay-pass-3/06-level-up-choice.png`
- 패널·버튼:
  `pixel-art-production/evidence/gates/08-final-migration/gameplay-pass-3/90-pause.png`
- 아트 방향:
  `docs/design/sunken-ceramic-fresco.png`

## Scope

In scope:

- 보행면, wall/cover, water/void 경계, 기능 지형, 희소한 랜드마크의
  시각 문법;
- HUD plate, modal surface, section divider, upgrade card, primary,
  secondary, danger, disabled, hover, pressed, focus, selected 상태;
- `24x24` 타일, `2x2`/`3x3` 구조 모듈, UI 9-slice corner/edge의 제작
  계약;
- 세 시안의 생성, 동일 조건 비교, 한 방향 승인.

Out of scope:

- 충돌, 내비게이션, 스폰, 전투, 카드 효과, 입력, 저장, 오디오 변경;
- 맵 토폴로지나 통과 가능한 길의 변경;
- 한국어/영어 문구, 메뉴 항목, 버튼 우선순위의 재설계;
- 생성 시안을 런타임 에셋으로 직접 사용;
- 외부 타일셋의 복사 또는 저장소 반입.

Destructive or irreversible actions:

- 없음. 시안은 증거 파일이며 기존 런타임 에셋을 덮어쓰지 않는다.

User approval required before:

- 세 방향 중 하나를 구현 대상으로 승격;
- 승인된 방향이 현재 `UI_VISUAL_SYSTEM.md`의 금지 항목을 의도적으로
  바꾸는 경우 해당 spec 수정.

## Shared Locked Design Contract

세 시안 모두 다음 계약을 지킨다.

### 맵과 지형

- 카메라는 정확한 90도 top-down이며 원근, side-view wall face, 긴
  cast shadow를 사용하지 않는다.
- 보행면은 low-frequency, low-contrast 재질장으로 유지한다. 반복되는
  격자선, 볼트, 균열, 얼룩, 패널 노이즈를 제거한다.
- solid cover는 ceramic green의 한 실루엣 언어를 사용하고, cobalt
  under-edge는 접촉 깊이만 전달한다.
- 기본 구현은 기존 `Polygon2D` 반복 fill을 유지하고, 지형에서 파생된
  visual-only 연결 레이어가 wall rim, corner, cap, water/void edge만
  추가한다.
- 연결 레이어는 collision, navigation, occlusion을 갖지 않으며
  `VehicleFieldLayout` fingerprint가 바뀔 때만 다시 만든다.
- 첫 제작 단위는 floor base 1 + 저대비 variant 3, wall 16 orthogonal
  signatures, water/void edge 16 signatures다.
- `2x2`/`3x3` 대형 모듈은 반복 장식이 아니라 안전 구역 또는
  비전투 랜드마크에 한 번만 배치한다. 역할 오인 검사에 실패하면
  floor가 아니라 wall recess나 UI ornament로 제한한다.
- functional terrain은 현재의 plus, chevron, lightning, paired opening,
  fracture 실루엣을 유지하며 정확한 범위와 타이머는 live geometry에
  남긴다.

### 패널과 section

- 패널의 기본 구조는 `cobalt under-edge → ceramic green rim → ivory
  live surface` 세 재질 역할로 통일한다.
- 가시적인 배경/테두리 중첩은 두 단계까지만 허용한다. 카드 안에 다시
  카드형 박스를 쌓지 않는다.
- modal은 24px 논리 단위로 만든 corner, straight edge, inner join을
  사용하는 9-slice frame으로 확장하되, 텍스트 영역은 Godot
  `StyleBox`와 container가 소유한다.
- section은 새 패널을 추가하기보다 spacing, alignment, type hierarchy,
  한 줄 divider로 나눈다.
- HUD plate는 opaque box를 늘리지 않고 현재 좌상단 health/XP,
  154x34 action rail, 중앙 objective, 우상단 176x108 minimap 위치를
  유지한다.

### 카드와 버튼

- upgrade는 현재의 세 장 동일 폭 카드, family, title, effect, numeric
  delta, 세 level pip 순서를 유지한다.
- 선택은 4px mustard frame + diamond, keyboard focus는 별도 rail로
  표현한다.
- primary는 mustard filled `300x48`, secondary는 ceramic green,
  tertiary danger는 ivory 위 coral text/rail을 유지한다.
- 모든 일상 command target은 최소 44px 높이이며, hover, pressed,
  focus, disabled 상태는 래스터 이미지가 아니라
  `vehicle_stage_theme.tres`의 live theme primitive로 만든다.
- Noto Sans KR medium/bold를 유지하고 한국어/영어에서 동일한 구조와
  기능을 노출한다.

### 제작 파이프라인

1. ImageGen은 전체 atlas가 아니라 하나의 material master, connected
   tile master, ornament master를 각각 독립 생성한다.
2. 승인된 master를 선언된 `24x24` grid에 snap하고
   `pixel-hangar-v1` semantic palette로 remap한다.
3. semantic mask와 layer를 분리하고 zero-diff reassembly를 검증한다.
4. SVG는 integer-grid 수정용 중간 파일로만 사용하고 PNG를 runtime
   truth로 유지한다.
5. 연결 variant와 atlas 배치는 deterministic tool이 만든다.
6. 각 tile은 `3x3` repeat, 긴 strip, 16-signature adjacency,
   nearest-filter, gutter/extrusion 검사를 통과한다.
7. `imagegen_assisted` provenance는 raw source, prompt, approved source,
   checksum, derivation을 모두 기록한다.

## Evidence Contract

| Evidence category | Source | What it must establish | Enough evidence |
| --- | --- | --- | --- |
| Existing product | 네 개의 기준 이미지와 live theme/code | 현재 정보 구조와 브랜드 인식점 | 맵, 카드, pause, fresco를 직접 대조 |
| Topology | Godot TileSet/TileMapLayer와 Tiled terrain 문서 | 16-signature 시작점과 visual-only owner | sides-only 16 및 확장 조건이 명시됨 |
| Pixel production | `pixel-art-production/README.md` | grid, palette, semantic layer, atlas 계약 | 기존 validator와 연결 가능 |
| UI quality | `UI_VISUAL_SYSTEM.md`와 현재 컴포넌트 | 한국어/영어, focus, target, overflow 보존 | 세 시안 모두 동일 기능·문구를 보임 |
| Rendered comparison | 독립 시안 세 장 | 하나의 화면에서 world와 UI가 같은 문법인지 | 각 방향이 명확히 다르고 disqualifier가 없음 |

비교 가중치:

- 전투 가독성과 false-signal 방지: 35%
- 맵·지형·UI의 시각적 일관성: 25%
- 한국어/영어 UI 명료성: 20%
- 실제 타일·9-slice 제작 가능성: 15%
- 정적 rebuild와 batching 성능 적합성: 5%

Disqualifiers:

- 길처럼 보이지만 통과할 수 없거나, 벽처럼 보이지만 통과 가능한 시안;
- 바닥 디테일이 actor, pickup, telegraph보다 먼저 읽히는 시안;
- 패널 중첩이 두 단계를 넘거나 버튼 우선순위가 바뀐 시안;
- 작은 한국어가 잘리거나 44px command target을 확보할 수 없는 시안;
- gradient, antialiasing, dithering, glow, dense microtexture가 핵심인 시안;
- 현재 Godot geometry/theme owner를 교체해야만 성립하는 시안.

## Viable Directions

### Quiet Fresco Inlay

- 맵: deep-slate deck은 거의 무문양으로 두고, 안전 지점 한 곳만
  저대비 ivory/mint `3x3` inlay로 표시한다.
- 경계: ceramic green wall top과 얇은 cobalt contact edge를 가장
  단순한 16-signature로 연결한다.
- UI: 넓은 ivory plaque, 한쪽 ceramic green focus rail, mustard
  primary를 사용한다.
- 차별점: 현재 구조에서 변화량이 가장 작고 combat floor가 가장 조용하다.

### Tidal Ceramic Rim

- 맵: cobalt water/void가 경계의 주인공이며, ivory shoreline과 deep
  green blocker rim이 층을 이룬다. 장식은 water edge에만 둔다.
- 경계: straight, inner/outer corner, cap을 더 강조하되 collision
  footprint 밖으로 시각 질량을 확장하지 않는다.
- UI: ivory face 아래 cobalt under-shadow, deep green section band,
  mustard primary를 사용한다.
- 차별점: 외곽 공간과 UI의 under-edge가 직접 연결되어 깊이감이 가장 크다.

### Structural Ceramic Relief

- 맵: floor는 조용하게 유지하고 wall, bulkhead, fixture에만 큰
  stepped relief와 original geometric motif를 넣는다.
- 경계: wall connection과 기능 지형의 큰 실루엣이 방의 랜드마크를
  담당한다.
- UI: deep green outer frame, ivory inner surface, straight divider,
  rail-based selected/focus state를 사용한다.
- 차별점: 장식을 지형지물에 집중해 전투면을 보존하면서 제작 모듈성이
  가장 높다.

## Generated Evidence

표시 순서가 선택 번호의 유일한 기준이다.

| 표시 번호 | 결과 | 직접 검수 |
| ---: | --- | --- |
| 1 | `pixel-art-production/evidence/design-directions/2026-07-28/quiet-fresco-inlay.png` | `1280x720`; 현재 pause 계층과 한국어 여섯 문자열 유지; 가장 조용한 바닥. 선택 시 inlay의 false-collision 가능성과 어두운 target contrast를 먼저 제거 |
| 2 | `pixel-art-production/evidence/design-directions/2026-07-28/tidal-ceramic-rim.png` | `1280x720`; 현재 pause 계층과 한국어 여섯 문자열 유지; cobalt water/void와 layered rim이 가장 강함. 현재 상태는 장식 밀도와 pseudo-depth가 높아 선택 시 단순화 revision 필수 |
| 3 | `pixel-art-production/evidence/design-directions/2026-07-28/structural-ceramic-relief.png` | `1280x720`; 현재 pause 계층과 한국어 여섯 문자열 유지; wall/fixture relief와 UI frame의 결속이 가장 강함. 선택 시 border depth를 평면화하고 target ring 대비를 강화 |

세 결과 모두 현재 gameplay, pause, upgrade, fresco 이미지를 실제 reference
input으로 사용했다. 생성 이미지에는 일부 soft shading이 남아 있으므로
runtime pixel asset으로 직접 사용하지 않는다. 선택된 composition과 material
hierarchy만 승인 대상으로 삼고, 실제 에셋은 공통 제작 파이프라인의
whole-cell, fixed-palette, no-antialiasing 검사를 다시 통과한다.
동일 크기 current pause/gameplay reference와 side-by-side QA한 결과, 3번이
현재 first-clear readability를 가장 잘 보존했고, 1번은 collision/contrast
정리가 필요하며, 2번은 구현 전에 한 번의 단순화 revision이 필요하다.

## Tasks

### Phase 1 — 현재 truth와 공통 계약 고정

- [x] active spec, product contract, pixel pipeline, current theme와 UI
  component owner를 확인한다.
- [x] 현재 맵, upgrade, pause, fresco 이미지를 직접 검사한다.
- [x] geometry/collision owner와 visual-only integration boundary를
  확인한다.
- [x] 외부 topology, modular kit, landmark, image-generation 자료를
  현재 프로젝트 계약으로 번역한다.

Success check:

- 세 시안이 동일한 기능·레이아웃·팔레트 의미를 사용할 수 있다.

Failure handling:

- 현재 spec과 충돌하는 장식은 floor에서 제거하고 wall recess 또는 UI
  ornament로 제한한다.

### Phase 2 — 독립 시안 세 장 생성

- [x] 네 기준 이미지를 실제 reference input으로 첨부한다.
- [x] 세 방향을 서로 독립된 ImageGen 호출로 생성한다.
- [x] 모든 시안에 `일시정지`, `계속하기`, `스테이지 다시 시작`, `설정`,
  `차고로 돌아가기`, `?`의 현재 계층을 유지한다.
- [x] 각 결과를
  `pixel-art-production/evidence/design-directions/2026-07-28/`에
  보존하고 Creative Production board에 연결한다.
- [x] 왜곡, 텍스트 오류, clipping, false geometry, palette drift를
  직접 검사한다.

Success check:

- 세 이미지가 각각 한 화면이며 서로 다른 world/UI treatment를
  명확히 보여준다.

Failure handling:

- 한 결과만 실패하면 해당 방향만 한 번 재생성한다. 두 번째도
  disqualifier를 통과하지 못하면 그 방향은 탈락으로 기록한다.

### Phase 3 — 동일 기준 비교와 사용자 선택

- [x] 세 결과를 표시된 순서대로 1, 2, 3에 고정한다.
- [ ] 사용자가 한 번호를 선택하거나 결합·수정 요구를 남긴다.
- [ ] 선택된 방향의 world, terrain, panel, button 규칙을 한 계약으로
  기록한다.

Success check:

- 구현자가 추가 스타일 선택 없이 하나의 승인된 화면을 목표로 삼을 수
  있다.

Failure handling:

- 두 안을 결합할 경우 결합 시안을 한 장 새로 생성해 다시 승인받는다.

### Phase 4 — 실행 계획 승격

- [ ] 선택된 규칙을
  `.agents/execplans/2026-07-27-pixel-art-visual-recovery.md`의 locked
  decisions, architecture, phase tasks, validation에 반영한다.
- [ ] `UI_VISUAL_SYSTEM.md` 변경이 필요한 승인 사항만 spec에 반영한다.
- [ ] 이 결정 계획을 `done`으로 바꾸고 선택 결과를 실행 계획에서
  링크한다.

Success check:

- 실행 계획에는 비교·선택·조사 작업이나 미정 디자인이 남지 않는다.

Failure handling:

- 선택이 없으면 구현 계획을 활성화하지 않고 이 문서를 active decision
  plan으로 유지한다.

## Post-selection Implementation Contract

선택 뒤 실행 계획은 다음 순서를 사용한다.

1. **World vertical slice**
   - floor 4종, wall 16-signature, water/void 16-signature, landmark
     1종을 승인된 방향으로 제작한다.
   - `VehicleWorldTileOverlay` 책임 파일을 추가하고
     `VehiclePixelWorldMeshBuilder`가 layout fingerprint와 visual-only
     tile data만 전달하게 한다.
   - 한 macro field의 safe arrival과 maximum-pressure 상태를 먼저
     통과시킨다.
2. **Functional terrain**
   - bulkhead, transit, Arc Surge, repair, overdrive, crate를 같은 wall
     relief와 semantic color 규칙으로 교체한다.
   - 실제 footprint와 open/closed state overlay를 대조한다.
3. **Theme primitives**
   - `vehicle_stage_theme.tres`에 승인된 9-slice panel, section divider,
     button/card state를 공용 primitive로 만든다.
   - `VehicleStageUI`의 local one-off `StyleBoxFlat`은 공용 primitive와
     겹치는 경우에만 제거한다.
4. **Component application**
   - HUD plates, pause, deployment, upgrade cards, settings, guidebook,
     report, result, garage 순으로 공용 primitive를 적용한다.
   - UI component의 신호, snapshot, selection, focus owner는 바꾸지
     않는다.
5. **Production QA**
   - 세 viewport, 한국어/영어, keyboard focus, reduced motion, safe
     arrival, maximum pressure, Web export를 통과한다.

## Validation

Pixel/world inner loop:

```powershell
.\pixel-art-production\tools\design\validate_pixel_asset_manifest.ps1
.\pixel-art-production\tools\design\invoke_pixel_asset_build.ps1
.\pixel-art-production\tools\validation\validate_pixel_asset_palettes.ps1
.\pixel-art-production\tools\validation\validate_pixel_asset_seams.ps1
.\pixel-art-production\tools\validation\validate_pixel_asset_catalog.ps1
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_pixel_world_renderer.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_layouts.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_navigation_clearance.gd
```

UI inner loop:

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_ui_layout.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_ui_localization.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_pause.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_rewards_ui_audio.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_report.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_guidebook.gd
```

Final gates:

- `960x540`, `1280x720`, `1920x1080`;
- Korean default and complete English parity;
- safe arrival, first contact, maximum pressure, upgrade default/selected,
  pause, settings, guidebook, report, result, garage;
- collision/opening/minimap overlay comparison;
- `.\tools\export_web.ps1` and production-style Web review;
- `git diff --check` and lifecycle/frontmatter check.

## Error Handling

| Trigger | Required response | Stop or escalation |
| --- | --- | --- |
| ImageGen changes menu hierarchy | Reject or regenerate that image | Never infer a new UX from the mockup |
| Korean text is malformed | Regenerate the affected concept with fewer exact labels | Do not approve unreadable text |
| Tile detail reads as gameplay | Remove or relocate the motif | Do not change gameplay truth |
| Visual edge disagrees with geometry | Correct the art/overlay | Collision is not changed |
| 16 signatures are insufficient | Add 47-tile mixed set only for the proven failing topology | Do not start with 47 |
| UI frame cannot scale cleanly | Reduce ornament and rebuild 9-slice proof | Never stretch pixel corners |
| Performance gate fails | Batch or cache the static overlay by fingerprint | Do not weaken workload or threshold |

## Progress

- [x] Current product, visual, pipeline, implementation, and rendered evidence
  inspected.
- [x] Shared design and production contract fixed.
- [x] Three viable directions defined with common disqualifiers.
- [x] Three referenced mockups generated and validated.
- [ ] User selection recorded.
- [ ] Selected direction promoted into the active execution plan.

## Next Steps

1. Generate and inspect the three `1280x720` referenced mockups.
2. Bind the visible results to 1, 2, 3 and receive BK's selection or revision.
3. Promote only the selected direction into the existing visual-recovery
   ExecPlan.

## Completion Criteria

- [ ] Three independent images use the actual current UIUX references.
- [ ] Every image shows a coherent map/terrain/panel/button system without a
  disqualifier.
- [ ] BK selects one direction or requests one explicitly bounded revision.
- [ ] The selected direction is recorded in the active execution plan with no
  unresolved material design choice.

## Sources

External sources were accessed on 2026-07-28:

- [Godot TileMapLayer](https://docs.godotengine.org/en/stable/classes/class_tilemaplayer.html)
- [Godot TileSet workflow](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html)
- [Tiled terrain sets](https://doc.mapeditor.org/en/stable/manual/terrain/)
- [OpenAI image prompting guide](https://developers.openai.com/cookbook/examples/multimodal/image-gen-models-prompting-guide)
- [Aseprite tiled mode](https://www.aseprite.org/docs/tiled-mode/)
- [Ceramic Dungeon](https://tinypot.itch.io/ceramic-dungeon)
- [Deepnight Dungeon Tileset](https://opengameart.org/content/deepnight-dungeon-tileset)
- [Hyper Light Drifter world design](https://blog.playstation.com/2014/03/14/creating-the-world-of-hyper-light-drifter-on-ps4-and-ps-vita/)
- [The Level Design Book — Environment Art](https://book.leveldesignbook.com/process/env-art)

## Handoff

```text
Decision:
Approve one Cardborne map, terrain, panel, and button visual direction.

Read first:
.agents/visual-system-design-selection-plan.md
docs/design/UI_VISUAL_SYSTEM.md
pixel-art-production/README.md

Compare:
The three images under
pixel-art-production/evidence/design-directions/2026-07-28/

Stop when:
One direction is selected and promoted into the active visual-recovery
execution plan, or BK requests one bounded combined revision.
```
