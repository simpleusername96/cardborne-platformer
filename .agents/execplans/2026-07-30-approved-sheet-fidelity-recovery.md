---
type: plan
status: active
owner: BK
created: 2026-07-30
last_reviewed: 2026-07-30
scope: Recover approved-sheet fidelity across runtime assets, deterministic map tiles, upgrade UI, and all remaining player-facing panels before the final performance gate
supersedes: ./2026-07-30-full-visual-system-redesign.md
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ./2026-07-29-horde-foundation-recovery-and-acceptance.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../docs/design/component-sheets/README.md
---

# 승인 시안 충실도 회복 및 알고리즘 맵·UI 복구 실행 계획

## Purpose

사용자가 승인한
`docs/design/component-sheets/00-general-sf-component-master-v1.png`의
기계적 실루엣, 비례, 레이어와 명암 구조를 실제 runtime asset과 모든
component sheet에 일관되게 구현한다. 기존 gameplay geometry와 collision은
유지하되, 맵 표면은 고정된 큰 판 몇 개가 아니라 layout fingerprint로부터
결정적으로 조합되는 modular tile system으로 교체한다. Upgrade UI는
Noto Sans KR를 유지하면서 읽을 수 있는 weight, 대비, 정보 계층과 실제
compact 폭에 맞는 card geometry를 복구한다.

이 계획은 이전 visual plan의 남은 visual acceptance와 final performance
gate를 대체한다. 이전 계획에서 완료한 pickup contact, engine transform,
dash afterimage, collective enemy tactic과 boss gameplay exam은 되돌리지
않는다.

## Why / Context

현재 구현은 자체 validator에는 통과했지만 승인 시안과 비교하면 다음 세
가지 authority error가 있다.

1. 승인 시안을 production target이 아니라 느슨한 seed로 취급해 player,
   ordinary enemy와 boss가 다시 generic wedge, diamond, star, octagon으로
   단순화됐다.
2. 맵은 algorithmic tile composition이 아니라 authored field 위에 몇 개의
   고정 line과 large plate를 올린 상태다.
3. Upgrade UI는 font file을 잃은 것이 아니라 body `500`, strong `650`으로
   hierarchy를 약화했고, family badge를 dark-on-dark로 그리며, compact에서
   실제로 성립하지 않는 `280 px × 3` card 계약을 사용한다.

따라서 통과 기준은 “현재 spec과 일치”가 아니라 “승인 시안과 runtime을
직접 비교했을 때 같은 visual family로 읽히고, 실제 viewport에서 텍스트와
상태가 온전히 보이는가”로 교정한다.

## Authority Order

이 작업에서 visual 판단 충돌은 다음 순서로 해소한다.

1. 사용자의 현재 피드백과 승인 시안
2. 이 계획과 교정된 `docs/design/UI_VISUAL_SYSTEM.md`
3. runtime descriptor, Theme와 component catalog
4. production component sheet와 capture
5. 이전 계획, 이전 capture와 historical implementation

승인 시안의 SHA-256은
`d91df76685480676e6695eeaab7db49e93c7de89e1950a9b3b3bc806c02ea7e7`이다.
hash가 달라지면 구현을 계속하지 않고 변경된 시안을 다시 비교한다.

## Scope

### 포함

- player hull, engine, aim mount와 state silhouette
- ordinary enemy 18종과 elite/collective state
- boss 5종의 body, detachable objective module과 vulnerable state
- projectile, telegraph, reward, pickup, facility, status와 upgrade glyph
- 세 field의 deterministic algorithmic visual tile composition
- HUD, minimap, deployment, upgrade, pause/settings, guidebook, report,
  result/garage와 boss practice panel
- production sheet 12종과 native runtime capture
- Korean/English, compact/wide, focus/selected/disabled와 reduced motion
- 모든 asset/UI가 교체된 뒤 실행하는 final native/Web performance gate

### 제외

- field walkability, collision, navigation, cover truth와 encounter socket 변경
- procedural topology/WFC와 run마다 다른 gameplay route 생성
- upgrade behavior, reward value, boss damage/HP와 enemy tactic 재설계
- 새 font, engine, production dependency 추가
- pixel chrome 또는 교체 전 raster asset 복원

## Assumptions

- 사용자의 “맵은 알고리즘 기반으로 타일이 만들어져야 한다”는 gameplay
  topology randomization이 아니라, 현재 field geometry 위의 visible floor
  tile/panel을 seed 기반으로 생성하라는 의미로 해석한다.
- 세 field의 collision fingerprint가 같으면 visual tile fingerprint도
  같고, layout fingerprint가 달라지면 허용된 variant 선택만 달라진다.
- 역할별 semantic color는 유지하되, 색을 제거해도 silhouette와
  negative space로 역할을 구분할 수 있어야 한다.

## Locked Design

### 승인 시안 충실도

- player는 mustard main hull, ivory/charcoal center spine, rear socket,
  symmetric engine pair와 cyan thrust를 유지한다.
- ordinary enemy는 approved master의 role grammar를 직접 확장한다.
  - swarm: solid chevron
  - melee: split spear/prong
  - ranged: open muzzle bracket
  - controller: twin prong + command core
  - shield: forward slab
  - artillery: long rail
  - support: open cradle
- boss는 regular star/polygon을 금지하고 asymmetric core, offset wing,
  detachable external module과 노출된 vulnerable channel을 사용한다.
- 각 component는 dark perimeter/separation, semantic main mass, secondary
  mechanical plane, restrained hard highlight 또는 inset의 3–5 filled
  plane으로 구성한다.
- soft glow, photoreal material, noise, dither와 pixel grid는 사용하지 않는다.
  Approved sheet에 보이는 hard-edged depth와 restrained highlight는
  허용하며, 무조건적인 two-plane 제한은 폐기한다.

### Algorithmic visual tile compiler

- 새 owner는
  `scripts/presentation/vehicle_field_surface_pattern_compiler.gd`다.
- 입력은 `field_id`, `layout_fingerprint`, walkable regions, void rects,
  cover rects와 player start다.
- base grid는 `288 × 288` world unit이며, `1×1`, `2×1`, `1×2`, `2×2`
  module을 deterministic hash로 배치한다.
- tile은 12-unit gutter, chamfered corner, dark inset, one restrained
  service rail을 가질 수 있다. rail과 inset은 semantic cue보다 낮은
  contrast를 사용한다.
- 모든 tile polygon은 walkable region에 clip되고 void에는 생성되지 않는다.
- module variant와 orientation은
  `hash(field_id, layout_fingerprint, cell_x, cell_y)`만 사용한다.
  frame time, global RNG와 draw order는 결과에 영향을 주지 않는다.
- field grammar:
  - Drowned Ruin: orthogonal 1×1/2×2 court grid
  - Tidal Archive: horizontal 2×1 bay rhythm
  - Storm Drydock: alternating 1×2/2×2 diagonal service rail
- compiler output은 collision node를 만들지 않고 world builder의 한 retained
  `MeshInstance2D` batch로 합쳐진다. 기존 boundary, cover와 facility batch
  budget을 포함해 world batch는 `≤12`다.

### Upgrade UI typography와 geometry

- font family는 기존 Noto Sans KR variable 하나를 유지한다.
- body weight는 `650`, strong/title weight는 `800`으로 복구한다.
- compact scale은 `13/15/17/22/30`, wide scale은
  `14/16/18/24/32/40`을 사용한다.
- family badge는 light text + family accent edge를 사용하며 dark-on-dark
  조합을 금지한다.
- compact card는 `224–244 × 286`, gap `12`; wide card는
  `304 × 330`, gap `18`이다. 세 card는 960 viewport에서 동일 폭으로
  한 줄에 들어간다.
- card 정보 순서는 family/glyph, title, one-sentence summary, 최대 2개
  stat row, optional behavior row, level pips다.
- `clip_contents`는 안전장치만 담당한다. layout validator는 label의 실제
  glyph bounds와 visible line을 확인해야 한다.
- selected, focus, disabled는 색뿐 아니라 edge thickness, corner marker와
  contrast로 구분한다.

### Other UI panels

- approved sheet 하단 panel grammar를 사용한다: dark perimeter, main surface,
  one raised inset, restrained hard highlight, one semantic rail.
- 모든 panel을 장식으로 채우지 않는다. modal은 정보 계층을 우선하고
  HUD는 sightline을 비운다.
- Upgrade를 기준 panel로 먼저 고친 뒤 나머지 panel이 같은 Theme primitive와
  typography token을 소비하도록 정렬한다.

## Responsibility Map

| 책임 | owner | 변경 |
| --- | --- | --- |
| actor/boss shape recipe | `scripts/presentation/components/vehicle_actor_mesh_recipes.gd` | approved silhouettes와 layered mesh recipe의 단일 owner |
| primitive cache | `vehicle_component_mesh_library.gd` | reusable polygon/mesh utility만 유지 |
| actor descriptor | `vehicle_actor_visual_catalog.gd` | role → recipe/state/anchor mapping |
| runtime combat provider | `vehicle_combat_visual_library.gd` | 새 recipe 결과를 batch mesh로 compile; gameplay 판단 금지 |
| floor pattern | `vehicle_field_surface_pattern_compiler.gd` | deterministic tile/module descriptor와 fingerprint |
| world presentation | `vehicle_world_mesh_builder.gd` | compiler output을 one retained batch로 compile |
| UI type/state | `art/ui/production/vehicle_stage_theme.tres` | font weight, panel/card/control primitives |
| upgrade layout | `vehicle_upgrade_choice_panel.gd`, `vehicle_upgrade_choice_card.gd` | compact/wide geometry와 readable hierarchy |
| shared upgrade glyph | `vehicle_upgrade_glyph_renderer.gd` | card와 sheet가 같은 complete glyph recipe 사용 |
| production evidence | `tools/design/vehicle_visual_sheet_canvas.gd` | runtime provider만 그리며 빈 cell 금지 |
| validation | `tools/validation/` | fidelity contract, deterministic tile, real glyph/text bounds |

## Tasks

### Milestone 0 — Authority correction

- [x] 기존 visual plan을 `superseded`로 표시한다.
- [ ] `UI_VISUAL_SYSTEM.md`에서 승인 시안을 binding reference로 올리고
  two-plane/no-bevel/large-plate-only 규칙을 제거한다.
- [ ] component sheet README와 manifest 설명에서 large plate와 느슨한
  direction-seed 표현을 교정한다.
- [ ] 승인 시안 hash와 현재 runtime comparison evidence를 기록한다.

### Milestone 1 — Player, enemy와 boss visual fidelity

- [ ] actor/boss mesh recipe owner를 분리한다.
- [ ] player hull, spine, rear socket, twin engine과 aim mount를 승인 시안
  비례로 재구성한다.
- [ ] 18 ordinary role이 approved role grammar에서 파생되도록 재구성한다.
- [ ] five boss body를 asymmetric modular machine으로 재구성하고 objective
  module과 vulnerable channel을 state별로 드러낸다.
- [ ] runtime, guidebook, minimap과 sheet가 같은 catalog/recipe를 사용한다.
- [ ] generic diamond/star/octagon fallback이 ordinary/boss production ID에
  남지 않도록 validator를 추가한다.

### Milestone 2 — Algorithmic map tiles

- [ ] deterministic surface pattern compiler와 fingerprint contract를 만든다.
- [ ] 288-unit module을 walkable geometry에 clip하고 void를 제외한다.
- [ ] 세 field grammar를 구현하고 layout seed의 동일성/차이를 검증한다.
- [ ] world builder의 fixed `FieldRhythm`/`SparseServicePlates`를 compiler
  output으로 교체한다.
- [ ] cover, boundary, facility, collision과 navigation fingerprint가
  변경되지 않았음을 확인한다.
- [ ] 3 field overview와 local 1× capture에서 tile composition을 검토한다.

### Milestone 3 — Upgrade UI와 glyph 복구

- [ ] Theme의 body/strong weight와 compact/wide type token을 복구한다.
- [ ] family badge contrast와 card state frame을 수정한다.
- [ ] 960/1280/1920에서 3-card geometry와 font scale을 정렬한다.
- [ ] 83 upgrade state 중 최대 text triplet과 ko/en worst case를 fixture로
  고정한다.
- [ ] 8개 upgrade family glyph가 card와 sheet 양쪽에서 동일하게 렌더되고
  빈 cell이 없도록 shared renderer를 구현한다.
- [ ] glyph bounds, actual text bounds, contrast와 visible line validator를
  추가한다.

### Milestone 4 — Remaining asset와 UI alignment

- [ ] projectile, reward, facility, effect와 HUD/minimap glyph를 승인 시안의
  layered mechanical grammar로 재검토하고 drift를 수정한다.
- [ ] deployment, pause/settings, guidebook, report, result/garage와
  boss-practice panel이 교정된 Theme primitive와 font hierarchy를 사용하게
  한다.
- [ ] 각 surface의 ko/en compact/wide capture에서 overflow, overlap,
  clipping, invisible state와 unreadable label을 수정한다.
- [ ] 12개 production sheet를 전부 재생성하고 누락/빈 slot 0을 확인한다.

### Milestone 5 — Runtime visual acceptance

- [ ] approved master 옆에 runtime player/role enemy/boss/reward/projectile을
  같은 scale로 놓은 comparison sheet를 생성한다.
- [ ] ko/en × 960/1280/1920 native captures를 생성한다.
- [ ] three field, peak combat, five boss, upgrade worst-triplet와 모든 modal을
  사람이 직접 비교 검토한다.
- [ ] visual failure가 있으면 asset/UI phase로 돌아가며 performance 측정을
  시작하지 않는다.

### Milestone 6 — Final performance gate

- [ ] 모든 asset와 UI가 visual acceptance를 통과한 뒤에만 시작한다.
- [ ] focused functional validators 전체를 실행한다.
- [ ] Web export와 production-style native/Web smoke를 실행한다.
- [ ] 276-enemy peak, 320-actor capacity, boss scenario에서 existing
  frame-time, draw-call, batch, lifecycle threshold를 검증한다.
- [ ] final sheet/capture manifest와 plan progress를 갱신한다.

## Progress

- 승인 시안과 current component sheets/runtime capture를 직접 비교했다.
- 맵이 authored geometry와 fixed decoration만 사용하며 algorithmic visual
  tile generation이 없음을 확인했다.
- Noto Sans KR loading은 정상이고, font weight/contrast/layout contract가
  회귀 원인임을 확인했다.
- `08-reward-upgrade-glyphs.png`에서 8개 family 중 5개 cell이 비어 있음을
  확인했다.
- 기존 plan/spec이 이 잘못된 결과를 의도적으로 허용한 authority error를
  확인했다.

## Next Steps

1. Milestone 0의 canonical spec과 sheet metadata를 교정한다.
2. Milestone 1–3을 독립 owner로 병렬 구현하되 shared Theme/catalog 변경은
   한 owner가 통합한다.
3. Milestone 4에서 나머지 surface를 같은 primitives로 정렬한다.
4. Milestone 5의 rendered comparison을 통과한 뒤 Milestone 6을 실행한다.

## Test Plan

### Focused validation

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_visual_tokens.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_component_catalogs.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_player_presentation.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_world_visuals.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_ui_theme.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_upgrade_system.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_ui_layout.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_ui_localization.gd
```

### Rendered acceptance

- component sheets: deterministic regeneration, 12 PNG, empty slot 0
- actor comparison: approved vs runtime at composition scale and gameplay 1×
- map: three field overview + local tile crop, same seed hash equality
- upgrade: worst three-card combinations, ko/en, selected/focus/disabled
- modal: all production/debug surfaces at 960/1280/1920
- accessibility: grayscale, 200% text, reduced motion

### Final-only performance

Milestone 5가 통과하기 전에는 performance replay, profile capture와 threshold
판정을 실행하지 않는다. 이후
`2026-07-29-horde-foundation-recovery-and-acceptance.md`의 authoritative
scenario와 threshold를 그대로 사용한다.

## Acceptance Criteria

- 승인 시안의 player/8 role enemy/boss silhouette와 runtime counterpart가
  같은 visual family와 proportion hierarchy로 읽힌다.
- ordinary/boss production asset에 generic star/octagon fallback이 없다.
- map floor는 288-unit deterministic module로 생성되고 동일 seed hash가
  동일하며, collision/navigation fingerprint는 변경되지 않는다.
- upgrade family badge 대비가 정상이고 ko/en worst-triplet에서 visible
  glyph/text overflow, overlap와 clipping이 0이다.
- 8개 upgrade family glyph가 card와 sheet 모두에 존재한다.
- 모든 player-facing panel이 같은 Theme font/panel primitive를 사용한다.
- 12개 production sheet와 runtime capture가 누락 없이 재생성된다.
- 모든 visual acceptance 완료 뒤 final native/Web performance gate가 기존
  threshold를 통과한다.

## Rollback / Safety

- gameplay field definition, collision, navigation과 upgrade application
  owner는 수정하지 않는다.
- actor recipe, tile compiler와 upgrade presentation을 각각 독립 commit으로
  유지해 subsystem별 revert가 가능하게 한다.
- 생성 sheet와 capture는 provider 결과이며 source owner보다 먼저 수동
  편집하지 않는다.
- unrelated user-authored change는 stage, revert 또는 cleanup하지 않는다.

## Risks

| 위험 | 조기 신호 | 대응 |
| --- | --- | --- |
| layered actor mesh가 combat batch를 늘림 | batch 50 초과 | vertex color plane을 한 mesh surface로 합치고 semantic batch는 유지 |
| tile이 다시 visual noise가 됨 | 1×에서 player보다 seam이 먼저 보임 | 288-unit scale 유지, inset/rail contrast를 낮추고 variant density 제한 |
| tile clip이 geometry 밖으로 샘 | void pixel 또는 boundary overlap | polygon clip/containment validator와 field crop 확인 |
| compact card가 다시 잘림 | glyph bounds 또는 visible line 불일치 | 224–244 폭 budget과 worst-triplet fixture를 acceptance에 고정 |
| Theme weight가 다른 panel을 과밀하게 만듦 | settings/guide report overflow | font family/weight는 공통, surface별 size/spacing token만 조정 |
| sheet가 runtime과 다시 갈라짐 | provider fingerprint/hash 불일치 | sheet-only art 금지, runtime catalog/recipe만 draw |

## Open Questions

없음. 현재 구현 범위에서 필요한 선택은 승인 시안과 사용자의 명시적
algorithmic tile 요구로 결정됐다.

## Decision Notes

- 2026-07-30: 승인 시안을 “evidence only”로 취급한 해석을 폐기하고
  silhouette/proportion/layering binding reference로 승격했다.
- 2026-07-30: procedural gameplay topology는 제외하고 deterministic
  presentation tile compiler를 선택했다.
- 2026-07-30: font dependency 교체 대신 기존 Noto Sans KR의 proven
  `650/800` hierarchy를 복구한다.
- 2026-07-30: performance 검증은 모든 asset/UI 교정과 rendered visual
  acceptance 뒤 마지막 milestone로 고정했다.
