---
type: plan
status: active
owner: BK
created: 2026-07-31
scope: Complete the approved general-SF runtime visual replacement for non-map gameplay assets, transient effects, semantic combat cues, HUD, and all UI chrome before final-only performance qualification
related:
  - ../../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../art/gameplay/semantic-v2/README.md
  - ../../art/gameplay/semantic-v2/SOURCE_PROMPTS.md
  - ../semantic-v2-runtime-acceptance-evidence.md
  - ./2026-07-30-semantic-visual-world-boss-performance-rework.md
  - ./2026-07-31-deferred-map-tactics-boss-follow-up.md
---

# 비맵 시각 에셋·효과·UI 이미지 전환 완결 실행 계획

현재 빌드는 기체·일반 적·보스·투사체·아이템의 상당 부분을
`semantic-v2` 이미지로 표시하지만, 효과 8종 중 5종은 런타임에 연결되지
않았고 여러 의미가 같은 원·다이아몬드·빔·충돌 효과를 공유한다. UI 패널과
컨트롤 표면은 이미지가 아니라 `StyleBoxFlat`과 직접 그린 선으로 구성돼
있다. 이 계획은 맵 생성과 적·보스 패턴을 건드리지 않고, 아홉 단계에서
남은 비맵 시각 요소를 승인된 일반 SF 이미지·애니메이션·컴포넌트로
완결한 뒤 마지막 단계에서만 성능과 Web 배포 경로를 검증한다.

## Purpose

- Objective: 플레이 중 서로 다른 물체·상태·공격·보상·UI가 색뿐 아니라
  실루엣, 무늬, 연결 구조와 모션으로 즉시 구분되게 한다.
- Final artifact:
  - 누락 없이 연결된 gameplay image/effect/cue manifest
  - 원본 수를 제한해 제작한 추가 효과·cue·UI component 이미지
  - 이미지 panel 위에 동적 text/icon/value를 배치하는 전체 UI
  - generic visual fallback과 의미가 겹치는 공용 효과가 제거된 런타임
  - ko/en 지원 viewport의 rendered acceptance matrix
  - 모든 시각 전환 뒤에만 실행한 native/Web/lifecycle 성능 evidence
- Completion state: 허용 목록에 명시된 실시간 판정·수치 지오메트리를
  제외하고 production 화면에 의미를 대신하는 기본 원·사각형·다이아몬드
  asset이 남지 않으며, 모든 semantic event와 UI surface가 전용 이미지
  또는 명시된 hybrid 표현을 사용한다.

## Why / Context

직전 `semantic-v2` 작업은 이미지 팩 제작과 일부 runtime 전환을 완료했지만
완료 판정이 실제 연결 범위보다 넓었다.

- `asset-manifest.json`에는 8개 animation family가 있지만
  `VehicleCombatRenderer._sync_effects()`는
  `muzzle_player_primary`, `impact_reflect`, `dash_start`만 선택한다.
- `impact`, `reflect`, `barrier_hit`이 같은 `impact_reflect` animation을
  사용한다.
- `emp_release`, `wake_mine_detonation`, `boss_module_disabled`,
  `hostile_summon_arrival`, `bulkhead_destroy`는 파일과 frame이 있어도
  해당 gameplay event에서 선택되지 않는다.
- `VehicleRun`은 `spawn`, `shock`, `secondary`, `destroy`, `support`처럼
  서로 다른 원인을 넓은 문자열 하나로 합치며, renderer는 알 수 없는
  event를 generic ring/beam/diamond로 표시한다.
- upgrade card를 포함한 모든 panel, button, tab, meter chrome은
  `vehicle_stage_theme.tres`의 `StyleBoxFlat` 또는 component의 `_draw()`로
  그린다. `art/ui/production/`에는 panel/frame/background 이미지가 없다.
- peak-horde capture에서는 두꺼운 mustard/red ring, health bar, target
  marker와 beam이 actor 실루엣 위에 겹쳐 target priority를 흐린다.
- boss runtime의 해결된 module state는 `resolved`지만 renderer의 disabled
  asset 선택은 `disabled`만 검사한다.

이 문서는 위 상태를 “완료된 asset switch”로 간주하지 않는다. 이미지
제작, manifest 등록, event 연결, rendered evidence를 서로 다른 완료
조건으로 관리한다.

## Pre-plan Evidence Already Verified

| Source or path | 확인된 사실 | 이 계획에서 잠근 결정 | Recheck boundary |
| --- | --- | --- | --- |
| `docs/design/UI_VISUAL_SYSTEM.md` | familiar general-SF, flat color, role readability, Noto Sans KR, ko/en, collision truth 분리가 정본이다 | 새 theme이나 pixel 제약을 만들지 않고 기존 방향을 그대로 사용 | visual contract를 변경할 때 |
| `art/gameplay/semantic-v2/asset-manifest.json` | actor, boss, secondary, projectile, state, pickup, facility, HUD glyph와 8개 effect family가 존재한다 | 정상 image-backed family는 재생성하지 않고 누락·중복 계열만 확장 | manifest schema 또는 asset path 변경 시 |
| `art/gameplay/semantic-v2/sheets/07-effect-atlases.png` | 기존 effect source는 승인 방향과 일치하지만 `impact_reflect`는 방향성 반사·보호막 곡면을 동시에 설명하지 못한다 | 일반 hit, reflect, barrier contact를 별도 family로 제작 | 새 effect frame 생성 후 |
| `scripts/presentation/vehicle_combat_renderer.gd::_sync_effects` | 8개 중 3개만 선택하고 나머지는 generic primitive fallback으로 간다 | table-driven event mapping으로 교체하고 generic fallback을 제거 | event catalog 변경 시 |
| `scripts/vehicle/vehicle_run.gd::_add_effect` | 광범위한 string event가 의미 정보를 잃는다 | gameplay owner가 구체적인 semantic event ID를 내보내게 한다 | 새 event producer 추가 시 |
| `scripts/player/vehicle_secondary_runtime.gd` | secondary result가 종류 없이 position/radius 중심으로 반환된다 | 각 secondary가 presentation event ID를 결과에 포함한다 | secondary 추가 시 |
| `scripts/bosses/vehicle_boss_exam_runtime.gd::module_state` | 해결 상태는 `resolved`다 | renderer와 HUD 모두 `resolved`를 영구 무력화 상태로 사용한다 | boss state contract 변경 시 |
| `scripts/ui/vehicle_modal_surface.gd` | modal border/rail 전체를 직접 그린다 | 해당 draw path를 image-backed 9-slice surface로 교체한다 | UI surface asset 변경 시 |
| `art/ui/production/vehicle_stage_theme.tres` | panel/card/button/tab/meter가 `StyleBoxFlat`이다 | production chrome을 `StyleBoxTexture`로 전환한다 | theme state 추가 시 |
| `scripts/ui/vehicle_upgrade_choice_card.gd` | card frame, pips, selection/focus marks가 basic draw call이다 | card frame/state와 pip를 이미지 component로 전환하고 text/value는 동적으로 유지한다 | upgrade layout 변경 시 |
| `build/captures/semantic-v2-acceptance/ko-1280-final2/03-peak-horde.png` | 높은 압력에서 overlay가 actor를 가린다 | harmful boundary는 남기고 비공간적 의미 cue를 image glyph로 축소한다 | peak capture 재생성 후 |
| `.agents/semantic-v2-runtime-acceptance-evidence.md` | native production/boss pressure는 통과했지만 peak/capacity는 실패했고 Web interactive smoke/600초 soak는 미실행이다 | 성능은 시각 전환과 acceptance가 모두 끝난 뒤 최종 단계에서만 재개한다 | final visual gate 통과 후 |

Baseline commit은
`77c0b63cf167183cbbf647eb07b083b6c9226d54`이며, 계획 작성 시작 시
worktree는 clean이었다.

## Locked Decisions

| Topic | Final decision | Rationale |
| --- | --- | --- |
| Visual direction | antialiased hard-edged flat-color general-SF를 유지한다 | 승인된 `semantic-v2`와 active visual spec |
| Pixel constraint | 사용하지 않는다 | 사용자 지시 |
| Existing good assets | player/enemy/boss/projectile/pickup 등 이미 image-backed이고 역할이 읽히는 자산은 보존한다 | 불필요한 재생성과 회귀 방지 |
| UI composition | panel/background/frame는 image-backed 9-slice, text/icon/value/focus semantics는 동적 child control이다 | 사용자 지시와 localization/responsive 요구 |
| Runtime UI image owner | `art/ui/production/semantic-v2/`의 manifest와 Theme가 surface texture를 소유한다 | gameplay manifest와 UI chrome 책임 분리 |
| Transient effect owner | `asset-manifest.json`과 새 semantic visual-event catalog가 animation ID, scale, rotation, tint policy를 소유한다 | renderer if/else와 generic fallback 제거 |
| High-count rendering | actor/projectile/effect마다 `AnimatedSprite2D`를 만들지 않고 현재 texture-capable batch/capped queue를 확장한다 | density와 기존 architecture 보존 |
| Live gameplay truth | 공격 반경, beam/charge corridor, mine damage radius, HP, cooldown, progress, target direction은 simulation-driven geometry다 | 화면과 판정 불일치 방지 |
| Hybrid styling | live geometry에는 authored pattern/edge/cap texture를 입히되 size, direction, progress와 lifecycle은 runtime 값이 결정한다 | basic shape 인상 제거와 판정 정합성 동시 충족 |
| Unknown event | debug에서는 validator/assert로 실패하고 production에서는 한 번 log 후 표시하지 않는다 | 잘못된 generic ring으로 의미를 위조하지 않음 |
| Map | floor/wall tile compiler, topology와 map generation은 이 계획에서 제외한다 | 사용자가 별도 후속 작업으로 연기 |
| Enemy/boss behavior | coordinated tactic과 boss pattern/timing/movement는 변경하지 않는다 | 별도 draft 범위 |
| Performance order | asset production, runtime switch, UI switch, full rendered acceptance 뒤에만 성능을 실행한다 | 사용자 지시 |
| Dependencies | Godot 4.7/GDScript만 사용하고 새 production dependency를 추가하지 않는다 | repository contract |

## Rejected Alternatives

| Alternative | Rejected reason |
| --- | --- |
| 모든 원·선·사각형을 고정 PNG로 교체 | beam 폭, 반경, cooldown과 실제 판정이 어긋난다 |
| 각 modal 화면을 한 장의 완성 이미지로 제작 | ko/en text, 동적 값, viewport, focus와 scroll을 지원할 수 없다 |
| panel을 계속 `StyleBoxFlat`으로 그리고 icon만 추가 | 사용자가 지시한 image panel contract를 충족하지 않는다 |
| 모든 event에 generic ring을 두고 색만 변경 | 의미 중복과 peak-combat 혼잡을 유지한다 |
| 기존 actor/projectile pack 전체 재생성 | 이미 정상 적용된 범위를 다시 흔들고 작업량만 늘린다 |
| map image switch를 함께 수행 | 명시적으로 deferred된 map generation을 다시 끌어온다 |
| visual 전환 전에 장시간 성능 matrix 실행 | 최종 asset/UI build가 아니므로 결과를 다시 측정해야 한다 |

## Current State

### 이미 구현되어 보존할 범위

- player hull, hull-owned engine, aim-owned mount
- ordinary enemy role images, five boss bodies와 boss module images
- seeker, escort drone, orbit blade, wake mine
- player/hostile projectile 9종과 affinity별 morphology
- barrier/ion-field source, enemy generator/escort shield source
- burn/poison/chill state images
- experience, repair, crate와 recall pickup
- repair/overdrive/arc/transit/bulkhead 등 non-map facility/terrain images
- minimap, action과 upgrade family glyph
- pickup swept contact와 dash-through collection
- dash danger red circle 제거
- boss sealed/open/stable damage rule과 objective guidance
- Noto Sans KR font file와 ko/en localization data

이 항목도 final coverage와 rendered regression을 다시 통과해야 하며,
“보존”은 검수 면제를 뜻하지 않는다.

### 남은 구현

- 기존 effect atlas 5종의 실제 event 연결
- hit/reflect/barrier contact 및 secondary별 impact 분리
- spawn/shock/secondary/destroy/support generic event 제거
- hull-shaped raster dash afterimage
- resolved boss module의 persistent disabled image와 one-shot effect
- priority/collective/elite/boss core/module/commit cue의 primitive 중복 제거
- mine activation 표시와 peak overlay 혼잡 교정
- image-backed modal/HUD/card/button/tab/meter/preview frame
- guidebook category glyph와 UI pip/state image
- typography token 재연결 및 card/modal overflow 재검증
- 정확한 effect/UI rendered evidence
- 마지막 native/Web/capacity/lifecycle 검증

## Scope / Non-scope

### In scope

- non-map gameplay actor/object/effect/cue의 image completeness
- player/enemy/boss/projectile/secondary/pickup/facility image mapping 회귀
- dash, EMP, hit, reflect, barrier, secondary, summon, destroy, pickup,
  support, transit와 boss-objective effect
- attack telegraph의 image-patterned edge/cap과 정확한 live geometry
- target/priority/collective/elite/boss state cue
- HUD, upgrade, deployment, pause, settings, guidebook, stage report,
  result, garage, transition과 boss practice의 image-backed chrome
- button/tab/card/toggle/slider/meter/focus/selected/disabled state
- ko/en, 960×540, 1280×720, 1920×1080, 200% text, reduced motion,
  grayscale와 peak pressure rendered acceptance
- 모든 visual/UI 완료 뒤 final-only performance와 built-Web validation
- 잘못된 이전 acceptance claim 정정과 최종 evidence 갱신

### Out of scope

- floor/wall tile compiler, neighbor mask, map topology 또는 map generation
- map의 기능 지형 위치와 collision schedule 변경
- ordinary enemy role band, formation, density steering와 coordinated strategy
- boss attack pattern, 이동, 돌진 순서, 회복 timing 또는 난이도 재설계
- card behavior, damage, spawn count, projectile count와 combat balance 변경
- collision radius, attack truth 또는 objective progression을 image/UI가 소유
- Godot engine 교체, native extension, thread rewrite와 새 dependency
- 해상도, 언어, actor/projectile capacity, quality와 성능 threshold 하향

### Destructive or irreversible actions

- 없다. 기존 source와 runtime asset은 새 mapping과 rendered acceptance가
  통과할 때까지 삭제하지 않는다.
- legacy recipe/fallback은 `rg` reference 0과 focused validator 통과 뒤
  task-owned commit에서만 삭제한다.

### Exact actions requiring separate approval

- GDExtension/C++, production dependency, engine version 변경
- map generation draft 활성화
- enemy coordinated strategy 또는 boss pattern redesign 활성화
- capacity/quality/threshold 하향

## Assumptions

- Godot 4.7 stable과 `.\tools\godot.ps1` 경로를 유지한다.
- user-approved TO-BE sheets와 `UI_VISUAL_SYSTEM.md`가 시각 방향을
  충분히 잠그므로 추가 theme 선택 단계는 없다.
- source image에는 한 named effect 또는 최대 세 semantic identity만 넣는다.
- UI texture에는 text, 수치, localization copy와 gameplay icon을 굽지 않는다.
- current map와 gameplay behavior fingerprint는 visual work 전후 동일해야 한다.
- performance 측정은 final visual commit을 기준으로 새 payload를 만든다.

## Proposed Design

### 1. Image, hybrid, procedural 경계

| Visual concern | Representation | Runtime owner |
| --- | --- | --- |
| actor, boss, module, secondary, projectile, pickup, facility | authored PNG texture | semantic asset provider + current batches |
| muzzle, hit, reflect, barrier impact, EMP release, detonation, summon, destruction | authored frame animation | visual-event catalog + capped effect queue |
| priority, elite, collective, boss/objective state | authored cue glyph/overlay image | combat renderer semantic cue batches |
| modal/HUD/card/button/tab/meter shell | authored 9-slice/state texture | UI surface manifest + Godot Theme |
| UI text, icon, value, selection semantics | dynamic Control child | existing surface owner |
| attack radius, beam/charge corridor, mine damage boundary | live mesh with authored edge/pattern texture | telegraph builder + combat renderer |
| HP/cooldown/progress/fuse amount | image backplate/fill texture clipped by live ratio | current HUD/combat owner |
| target/off-screen direction | authored bracket/arrow cap placed by live vector | combat renderer / threat radar |
| floating damage and localized instruction | dynamic text | current renderer/UI owner |
| screen dim, debug collision, invisible layout containers | untextured procedural | current debug/UI host owner |

### 2. 추가 gameplay effect pack

기존 8개 family 중 7개는 그대로 보존한다. `impact_reflect`의 source
visual은 일반 impact 전용으로 재사용하되 runtime ID/file을
`impact_damage`로 다시 export하고 이전 alias를 제거한다. reflect와
barrier contact를 포함한 14개 family는 새로 제작한다.

| Animation ID | Frames / FPS | 역할 | Direction/scale policy |
| --- | --- | --- | --- |
| `impact_damage` | 기존 5 / 20 | ordinary projectile/weapon contact | contact center, affinity tint |
| `reflect_deflection` | 5 / 20 | reflected projectile | reflected direction으로 회전 |
| `barrier_contact` | 5 / 20 | hull barrier absorb | barrier 반경의 접선 방향, curved ripple |
| `hull_hit` | 4 / 20 | 실제 hull damage | player hull center, danger tint |
| `seeker_impact` | 4 / 20 | seeker contact | target direction, pointed burst |
| `escort_drone_impact` | 4 / 20 | escort drone contact | twin-prong burst |
| `orbit_blade_impact` | 4 / 20 | blade contact | blade tangent, crescent cut |
| `enemy_destroy_light` | 5 / 15 | ordinary small/standard enemy defeat | enemy radius scale |
| `enemy_destroy_heavy` | 6 / 15 | elite/heavy/boss defeat accent | enemy radius scale; boss body는 별도 persistent state |
| `crate_destroy` | 5 / 15 | reward crate destruction | crate center |
| `pickup_intake` | 4 / 20 | pickup collection accent | 실제 pickup sprite가 hull로 수렴 |
| `support_heal` | 4 / 15 | heal/support pulse | plus topology, support color |
| `lifesteal_pulse` | 4 / 20 | victim-to-player transfer particle | live source→player path를 따라 이동 |
| `transit_shift` | 5 / 15 | transit completion | opposing chevron direction |
| `boss_reduced_hit` | 4 / 20 | sealed/stable reduced boss damage | impact direction; damage number는 동적 text |

기존 animation의 runtime contract는 다음과 같이 고정한다.

| Existing animation | Required runtime event |
| --- | --- |
| `muzzle_player_primary` | `player_primary_muzzle` |
| `dash_start` | `player_dash_start` |
| `emp_release` | `player_emp_release`와 작은 subordinate aftershock |
| `wake_mine_detonation` | `secondary_wake_mine_detonation` |
| `boss_module_disabled` | module `active/locked → resolved` transition |
| `hostile_summon_arrival` | hostile summon/arrival completion |
| `bulkhead_destroy` | collision removal이 확정된 bulkhead break event |
| 기존 `impact_reflect` file | manifest에서 `impact_damage`로 명확히 재등록 |

각 animation source는 하나의 named effect만 포함하고, runtime frame은
alpha PNG, fixed canvas, pivot, non-loop, exact FPS를 manifest에 기록한다.

### 3. Semantic visual event contract

새 `scripts/presentation/components/vehicle_visual_event_catalog.gd`가 아래
event ID를 animation, live overlay, scale, rotation과 tint policy에 연결한다.
`VehicleRun._add_effect()`와 secondary/boss/terrain owner는 이 ID만
emit한다.

| Producer event | Presentation |
| --- | --- |
| `player_primary_muzzle` | `muzzle_player_primary` |
| `player_dash_start` | `dash_start` |
| `player_dash_afterimage` | player hull texture를 이전 transform에 3–5회 fade |
| `player_hull_hit` | `hull_hit` |
| `player_barrier_hit` | `barrier_contact` |
| `player_emp_charge` | segmented live radius ring; raster release 사용 금지 |
| `player_emp_release` | actual radius + `emp_release` |
| `player_emp_aftershock` | smaller live radius + subordinate `emp_release` pass |
| `secondary_seeker_impact` | `seeker_impact` |
| `secondary_escort_impact` | `escort_drone_impact` |
| `secondary_orbit_blade_impact` | `orbit_blade_impact` |
| `secondary_wake_mine_detonation` | `wake_mine_detonation` |
| `hostile_projectile_impact` | `impact_damage` |
| `projectile_reflected` | `reflect_deflection` |
| `hostile_arrival` / `hostile_summon_arrival` | `hostile_summon_arrival` + actor appear |
| `enemy_destroy_light` / `enemy_destroy_heavy` | matching destruction animation |
| `boss_core_reduced_hit` | `boss_reduced_hit` + live damage number |
| `boss_module_resolved` | `boss_module_disabled` + persistent disabled module image |
| `pickup_experience` / `pickup_repair` / `pickup_reward` | source pickup image + `pickup_intake` |
| `support_heal` | `support_heal` |
| `lifesteal_transfer` | live source→player path + `lifesteal_pulse` particles |
| `transit_complete` | `transit_shift` |
| `bulkhead_destroy` | `bulkhead_destroy` |
| `crate_destroy` | `crate_destroy` |
| `group_clear` | localized HUD notice + restrained one-direction sweep; world ring 없음 |

`spawn`, `shock`, `secondary`, `destroy`, `support`와 같은 broad production
event ID는 최종 상태에서 허용하지 않는다.

### 4. Combat cue image set

공간 판정을 나타내지 않는 의미는 더 이상 ring/diamond/beam 조합으로
표시하지 않는다. 다음 cue glyph를 최대 세 identity 단위의 source로 만든다.

- target/priority: `target_bracket_corner`, `priority_target`,
  `ranged_startup`
- collective lifecycle: `collective_gather`, `collective_lock`,
  `collective_execute`, `collective_break`
- elite trait: `elite_armored`, `elite_overclocked`, `elite_heavy`
- boss core: `boss_core_sealed`, `boss_core_open`, `boss_core_stable`
- boss objective: `objective_active`, `objective_resolved`,
  `commit_locked`, `commit_autonomous`
- guidebook category: `guide_ship`, `guide_mobile`, `guide_stationary`,
  `guide_bosses`, `guide_objects`

이미 존재하는 boss module body와 minimap marker를 복제하지 않는다.
world cue는 module image 주변의 작고 제한된 overlay로만 사용한다.

### 5. Telegraph와 pressure readability

- projectile startup은 현재 short lead를 유지하고 authored directional
  dash/pip texture를 edge/cap에 사용한다.
- beam/charge는 live capsule/corridor를 유지하고 double-rail texture와
  endpoint latch texture를 사용한다.
- area/mine은 live radius를 유지하고 affinity별 segment/dash pattern
  texture를 circumference에 반복한다.
- dormant mine activation radius는 player가 activation band에 접근하거나
  mine이 current target일 때만 낮은 대비의 segmented boundary를 표시한다.
- armed mine의 damage radius와 countdown은 항상 표시한다.
- harmful active boundary는 overlay budget 때문에 숨기지 않는다.
- 비공간적 priority/collective/elite cue는 actor 위 작은 image glyph로
  이동하고 actor 전체를 둘러싼 thick ring을 사용하지 않는다.
- current target, boss objective, committed attacker 순서로 cue가 읽히며,
  duplicate cue는 하나의 owner만 그린다.
- peak pressure에서 fill alpha를 누적시키지 않는다. 경계가 겹치면
  interior fill을 생략하고 exact outline과 countdown만 남긴다.

### 6. UI image component pack

`art/ui/production/semantic-v2/`를 UI texture pack의 단일 root로 사용한다.

```text
art/ui/production/semantic-v2/
  ui-asset-manifest.json
  sources/
  surfaces/
  controls/
  glyphs/
  sheets/
```

UI image에는 text와 gameplay icon을 굽지 않는다. 모든 frame은 center가
조용하고 text-safe inset이 명시된 9-slice texture다.

| Component family | Runtime textures | Canvas / patch margin |
| --- | --- | --- |
| modal master | normal, compact-safe | 192×192 / 32 |
| content plate | normal, inset, summary | 96×96 / 16 |
| HUD plate | health/resource, objective/boss, minimap/target, action rail, toast | 96×96 / 16 |
| upgrade card | normal, hover, pressed, focus, selected, disabled | 128×128 / 20 |
| button | primary, secondary, danger × normal/hover/pressed/focus/disabled | 96×64 / 20 horizontal, 16 vertical |
| tab/option | normal, hover, selected, focus, disabled | 96×48 / 16 |
| toggle/slider | off/on/focus, lane/fill/grabber | 64×64 or 96×32 / 12 |
| meter | background, health, boss, resource, cooldown | 64×24 / 8 |
| preview | normal, locked, focused | 96×96 / 16 |
| small state | pip empty/available/filled, warning, disabled, selection rail | 32×32 |

Source generation은 한 이미지에 최대 세 component identity만 넣는다.
normal/hover/focus 같은 한 component의 state variation은 한 identity로
취급하지만, runtime export는 state별 독립 PNG로 분리한다.

### 7. UI composition contract

- `vehicle_stage_theme.tres`의 production panel/button/card/tab/meter style은
  `StyleBoxTexture`를 사용한다.
- `VehicleModalSurface._draw()`는 제거하고 modal image style만 사용한다.
- `VehicleUiComponentFactory`는 `modal`, `hud_health`, `hud_objective`,
  `hud_minimap`, `hud_target`, `hud_action`, `content_plate` variation을
  명시적으로 선택한다.
- upgrade card는 image frame 안에 family glyph, title, summary, 최대 두
  effect row, optional behavior와 level pip를 동적으로 배치한다.
- `clip_contents`는 safety guard로만 남고 text fit을 해결하는 수단으로
  사용하지 않는다.
- Noto Sans KR variable 하나만 사용한다. body 650, title/label 800과
  active type scale을 Theme/token에서 공급하고 panel마다 임의 font family를
  추가하지 않는다.
- category/action/upgrade/minimap glyph는 기존 semantic provider를
  재사용하며 panel background에 합성하지 않는다.
- focus, selected, disabled, warning은 color뿐 아니라 해당 image state,
  rail/notch와 accessible state로 함께 표시한다.
- settings, guidebook, report와 boss-practice의 지정 content region만
  scroll한다. upgrade card는 scroll하지 않는다.

## Architecture and Ownership

| Concern | Final owner | Interface / invariant | Retire or narrow |
| --- | --- | --- | --- |
| gameplay texture path/pivot/frame | `art/gameplay/semantic-v2/asset-manifest.json` | unique asset/event IDs, exact canvas/pivot/FPS | ambiguous `impact_reflect` ID |
| gameplay image loading | `vehicle_semantic_asset_provider.gd` | missing texture returns failure evidence | no generic mesh fallback |
| visual event mapping | new `vehicle_visual_event_catalog.gd` | event→animation/overlay/scale/rotation/tint | renderer string if/else |
| event production | `vehicle_run.gd`, secondary/boss/terrain owners | concrete semantic event ID | broad `spawn/shock/secondary/destroy/support` |
| transient rendering | `vehicle_combat_renderer.gd` | capped texture queue/batch | generic ring/beam/diamond effect fallback |
| live telegraph geometry | `vehicle_attack_telegraph_builder.gd`, renderer | collision-truth geometry + authored pattern | untextured solid interior accents |
| actor/cue priority | combat renderer | one owner per cue, harmful geometry never hidden | duplicate ring/diamond/beam semantics |
| boss module state | boss exam runtime + renderer | `resolved` is persistent disabled visual state | renderer-only `disabled` vocabulary |
| UI texture metadata | new `ui-asset-manifest.json` | path, state, 9-slice margin, safe inset | implicit flat-style geometry |
| UI surface state | `vehicle_stage_theme.tres` | StyleBoxTexture per production state | production `StyleBoxFlat` chrome |
| UI composition | current panel files | image background + dynamic content | direct decorative `_draw()` |
| localization/layout | current UI owner + Theme/tokens | ko/en and supported viewport fit | scattered arbitrary font overrides |
| validation | responsibility-shaped validators | coverage, ownership, geometry, rendering | source-presence-only acceptance |
| performance | existing performance scenario/recorder | same workload and thresholds | pre-visual or repeated unqualified runs |

`vehicle_run.gd`에는 gameplay orchestration과 semantic event emission만
남긴다. image selection, frame timing, UI layout과 visual grammar를 이 파일에
추가하지 않는다.

## As-Is / To-Be Delta Map

| Concern | As-is | To-be | Acceptance | Guard |
| --- | --- | --- | --- | --- |
| effect coverage | 8종 중 3종 선택 | 모든 producer event가 catalog mapping 보유 | unmapped producer 0 | unknown event generic 표시 0 |
| hit semantics | hit/reflect/barrier가 같은 starburst | 방향·곡면·기능별 3 family | grayscale에서도 구분 | damage/collision 변화 0 |
| secondary effect | 모두 `secondary` | four secondary별 event | 각 무기 capture에서 고유 hit | cadence/damage fingerprint 동일 |
| EMP | charge/release가 generic ring/shock | live charge ring + release atlas + subordinate aftershock | 실제 radius와 image scale 일치 | effect frame이 판정 소유 금지 |
| dash | start image + primitive afterimage | start atlas + hull texture transform history | red radial 0, 3–5 silhouette | dash timing/position 동일 |
| spawn/destroy | generic expanding ring | arrival/destruction family | actor lifecycle별 one-shot | spawn/despawn timing 동일 |
| boss module | `resolved`가 active image로 남을 수 있음 | one-shot disabled + persistent disabled asset | resolved module active texture 0 | objective state 동일 |
| combat cue | ring/diamond/beam 재사용 | semantic cue image | critical pairs shape-distinct | harmful boundary 유지 |
| pressure | opaque fill/ring 중첩 | outline-first, duplicate suppression | peak capture에서 player/target 판독 | attack truth 숨김 0 |
| modal/HUD panel | flat fill + direct line | 9-slice image surface | production panel image coverage 100% | content inset/viewport 유지 |
| upgrade card | flat style + shape pips/marks | image card states + image pips | all 83 level states fit | card behavior remains outside UI |
| controls | StyleBoxFlat state | image-backed state texture | keyboard state visible | target size ≥44 |
| typography | Theme와 local overrides 혼재 | one font/token contract | ko/en/200% clip 0 | text baked into image 0 |
| evidence | source/validator 중심으로 과대 완료 | named runtime state captures | required effect/UI capture missing 0 | build-only claim 금지 |
| performance | final strict peak/capacity fail | final visual build로 bounded recovery | native/Web/lifecycle gates | threshold/quality 하향 금지 |

## Tasks

아래 Milestone의 체크박스가 이 계획에서 허용된 전체 구현 작업이다.
Milestone 밖의 map, tactics, boss-pattern 또는 dependency 작업을 인접
수정으로 추가하지 않는다.

## Milestones

### Phase 0 — authority와 acceptance truth 정정

Goal: 새 계획을 visual correction의 유일한 active ExecPlan으로 만들고,
source-presence와 runtime-complete를 분리한다.

Source owners: `docs/design/UI_VISUAL_SYSTEM.md`,
`.agents/semantic-v2-runtime-acceptance-evidence.md`,
`art/gameplay/semantic-v2/asset-manifest.json`,
`tools/validation/validate_vehicle_visual_sheet_coverage.gd`

- [x] **0.1 UI image-panel contract를 active visual spec에 기록한다.**
  - As-is: UI panel chrome의 image-backed requirement가 정본에 충분히
    명시되지 않았다.
  - To-be: panel/frame/background image + dynamic text/icon/value contract,
    9-slice safe area와 allowed procedural list를 명시한다.
  - Accept: spec과 이 계획의 image/procedural boundary가 동일하다.
  - Guard: map, gameplay와 unapproved motif가 spec에 들어가지 않는다.
- [x] **0.2 이전 acceptance evidence의 범위를 정정한다.**
  - As-is: effect/UI integration 설명이 실제 runtime wiring보다 넓다.
  - To-be: 3/8 effect 연결, 5/8 미연결, procedural UI chrome과 final
    performance limitation을 current fact로 기록한다.
  - Accept: evidence가 source 존재와 runtime evidence를 구분한다.
  - Guard: 과거 통과 payload와 수치를 삭제하거나 바꾸지 않는다.
- [x] **0.3 manifest와 validator를 event/state coverage 기준으로 확장한다.**
  - As-is: effect file 수만 세어도 coverage가 통과한다.
  - To-be: producer event→catalog→asset→frame chain과 UI surface state
    coverage를 검사한다.
  - Accept: 현재 baseline에서 의도적으로 미통과하며 누락 목록이 정확하다.
  - Guard: 아직 생성하지 않은 파일을 placeholder로 등록하지 않는다.

Batch acceptance: 누락 목록이 이 문서의 remaining implementation과 정확히
일치한다.

Batch guard: 이 phase에서는 gameplay, UI layout, renderer와 성능을
변경하지 않는다.

### Phase 1 — 추가 effect와 combat cue 이미지 제작·패키징

Goal: runtime 연결 전에 필요한 이미지와 review sheet를 완성한다.

Source owners: `art/gameplay/semantic-v2/sources/`,
`effects/atlases/`, `effects/frames/`, `hud/`,
`asset-manifest.json`, `sheets/`

- [ ] **1.1 14개 새 animation family와 1개 분리 re-export를 한 named effect/source 규칙으로 제작한다.**
  - As-is: generic effect와 한 starburst가 여러 event를 대신한다.
  - To-be: Proposed Design 표의 frame/FPS/pivot 규격으로 독립 source,
    atlas와 frame PNG를 만든다.
  - Accept: alpha/canvas/pivot/frame count/FPS validation 통과.
  - Guard: live radius, text, attack footprint와 background를 image에 굽지 않는다.
- [ ] **1.2 22개 combat/guide cue glyph를 최대 세 identity/source로 제작한다.**
  - As-is: non-spatial state가 ring/diamond/beam을 공유한다.
  - To-be: target, collective, elite, boss/objective, guide category별
    silhouette를 만든다.
  - Accept: critical-pair grayscale sheet에서 exact silhouette collision 0.
  - Guard: 기존 minimap/action/upgrade glyph를 복제하지 않는다.
- [ ] **1.3 manifest와 runtime export를 패키징한다.**
  - As-is: 추가 family metadata가 없다.
  - To-be: path, canvas, pivot, FPS, loop, scale/rotation policy를 기록한다.
  - Accept: 모든 manifest asset load와 alpha/canvas 검증 통과.
  - Guard: high-resolution source를 runtime에서 직접 load하지 않는다.
- [ ] **1.4 review sheet를 생성한다.**
  - Output:
    - `sheets/08-effect-semantic-expansion.png`
    - `sheets/09-combat-cue-glyphs.png`
  - Accept: source, runtime frames, animation order와 label이 같은 manifest
    fingerprint를 사용한다.
  - Guard: sheet 자체를 runtime asset으로 사용하지 않는다.

Batch acceptance: “asset production complete”는 source, runtime export,
manifest와 review sheet까지를 뜻한다.

Batch guard: runtime 연결 완료라고 표시하지 않는다.

### Phase 2 — UI image component pack 제작·패키징

Goal: 모든 UI surface가 조합해 사용할 reusable image component를 만든다.

Source owners: `art/ui/production/semantic-v2/`,
`ui-asset-manifest.json`

- [ ] **2.1 modal/content/HUD/upgrade surface image를 제작한다.**
  - As-is: flat fill과 직접 그린 perimeter다.
  - To-be: 지정 canvas, patch margin, text-safe inset을 가진 9-slice PNG다.
  - Accept: 960–1920 크기로 늘려도 corner/rail 두께가 유지된다.
  - Guard: text, icon, fake control과 기능 없는 중앙 장식을 굽지 않는다.
- [ ] **2.2 button/tab/toggle/slider/meter state image를 제작한다.**
  - As-is: state는 fill/border color 차이다.
  - To-be: normal/hover/pressed/focus/selected/disabled가 notch/rail/pattern도
    달라진다.
  - Accept: grayscale에서 focus/selected/disabled가 구분된다.
  - Guard: focus semantics와 keyboard behavior는 Godot Control이 계속 소유한다.
- [ ] **2.3 pip/preview/small-state image를 제작한다.**
  - As-is: circle/arc/rect로 직접 그린다.
  - To-be: pip, warning, disabled, selection rail과 preview frame PNG를
    사용한다.
  - Accept: 13–32 px 실제 표시 크기에서 형태가 뭉개지지 않는다.
  - Guard: upgrade level 값과 locked state를 image가 소유하지 않는다.
- [ ] **2.4 UI manifest와 component sheet를 생성한다.**
  - Output:
    - `sheets/01-ui-surface-components.png`
    - `sheets/02-ui-control-states.png`
  - Accept: unique ID, path, state, margins, safe inset, alpha와 canvas 통과.
  - Guard: runtime screen screenshot을 reusable asset로 잘라 쓰지 않는다.

Batch acceptance: 모든 production UI component state에 실제 runtime PNG가
존재한다.

Batch guard: 화면별 unique background를 새로 만들어 component system을
우회하지 않는다.

### Phase 3 — semantic event와 effect runtime switch

Goal: 모든 transient event를 구체적인 image/animation 표현에 연결한다.

Source owners:
`scripts/presentation/components/vehicle_visual_event_catalog.gd`,
`vehicle_semantic_asset_provider.gd`,
`vehicle_combat_renderer.gd`,
`scripts/vehicle/vehicle_run.gd`,
`scripts/player/vehicle_secondary_runtime.gd`,
`scripts/bosses/vehicle_boss_exam_runtime.gd`

- [ ] **3.1 table-driven visual-event catalog를 추가한다.**
  - As-is: renderer의 string if/else와 fallback이 mapping을 소유한다.
  - To-be: catalog descriptor가 animation, layer, scale, direction, tint와
    reduced-motion policy를 제공한다.
  - Accept: producer event 100% mapping, duplicate semantic owner 0.
  - Guard: catalog가 damage, duration과 collision을 소유하지 않는다.
- [ ] **3.2 broad event producer를 concrete ID로 교체한다.**
  - As-is: `spawn/shock/secondary/destroy/support`가 원인을 지운다.
  - To-be: Semantic visual event contract의 event ID를 emit한다.
  - Accept: production source에서 broad event emit reference 0.
  - Guard: effect 추가 이외의 gameplay branch와 숫자는 변경하지 않는다.
- [ ] **3.3 existing effect 5종을 실제 lifecycle에 연결한다.**
  - EMP release, wake mine detonation, hostile summon arrival,
    boss module resolved, bulkhead destroy를 정확한 state transition에
    연결한다.
  - Accept: 각 named effect가 runtime capture와 event trace에 한 번 이상
    나타난다.
  - Guard: damage/activation/collision timing은 기존 authoritative event다.
- [ ] **3.4 hit/reflect/barrier/secondary effect를 분리한다.**
  - Accept: renderer mapping에서 shared `impact_reflect` alias 0.
  - Guard: projectile core와 swept collision은 변경하지 않는다.
- [ ] **3.5 dash afterimage를 player hull texture history로 교체한다.**
  - Accept: 최대 5개, 이전 hull transform, 단조 alpha 감소, red ring 0.
  - Guard: reduced motion은 한 elongated silhouette와 engine flash만 사용한다.
- [ ] **3.6 generic fallback을 제거한다.**
  - Accept: unknown event fixture는 debug failure를 내고 world ring을 만들지 않는다.
  - Guard: production은 같은 unknown event를 frame마다 log하지 않는다.

Batch acceptance: named effect capture matrix와 event coverage validator 통과.

Batch guard: UI surface와 performance optimization을 시작하지 않는다.

### Phase 4 — combat cue와 live telegraph 시각 교정

Goal: 의미 cue를 image로 분리하고 live danger geometry를 덜 혼잡한
hybrid 표현으로 교체한다.

Source owners: `vehicle_combat_renderer.gd`,
`vehicle_combat_visual_library.gd`,
`vehicle_attack_telegraph_builder.gd`,
`vehicle_threat_radar.gd`, `vehicle_status_orbit.gd`

- [ ] **4.1 priority/collective/elite/boss cue를 image batch로 교체한다.**
  - As-is: ring/diamond/beam 조합을 공유한다.
  - To-be: combat cue image set을 actor-relative anchor에 배치한다.
  - Accept: cue pair별 asset ID가 다르고 peak에서 actor silhouette를 가리지 않는다.
  - Guard: current target과 committed danger 우선순위가 유지된다.
- [ ] **4.2 boss module `resolved` visual transition을 원자적으로 처리한다.**
  - To-be: active/locked→resolved one-shot, persistent disabled body,
    HUD/minimap/target update가 같은 state snapshot을 소비한다.
  - Accept: resolved forge/segment가 active image를 사용하는 frame 0.
  - Guard: boss phase와 damage multiplier는 변경하지 않는다.
- [ ] **4.3 telegraph edge/cap에 authored pattern texture를 적용한다.**
  - Accept: projectile/beam/charge/area/support/mine가 shape와 pattern으로
    구분되고 exact geometry assertion은 유지된다.
  - Guard: frame image가 live footprint를 대신하지 않는다.
- [ ] **4.4 mine과 pressure overlay를 outline-first로 교정한다.**
  - Accept: dormant activation ring 상시 대량 표시 0, armed damage boundary
    누락 0, interior fill 중첩으로 player가 가려지는 capture 0.
  - Guard: harmful active warning을 salience budget으로 숨기지 않는다.
- [ ] **4.5 duplicate visual owner를 제거한다.**
  - As-is: `VehicleRun._draw()`와 retained renderer가 일부 state cue를
    나눠 그린다.
  - To-be: static/semantic combat cue는 combat renderer, terrain live
    footprint/progress는 terrain owner가 각각 한 번만 그린다.
  - Accept: debug ownership snapshot에서 duplicate owner 0.
  - Guard: repair tether, transit progress와 hazard boundary처럼 live state인
    draw는 allowed procedural list에 남긴다.

Batch acceptance: ordinary pressure, mine cluster, collective phases와 five-boss
objective capture가 readability blocker 없이 통과한다.

Batch guard: enemy tactic과 boss pattern fingerprint가 baseline과 동일하다.

### Phase 5 — image-backed UI foundation, HUD와 upgrade vertical slice

Goal: shared Theme 경로를 먼저 교체하고 HUD와 upgrade에서 완성된
image-panel + dynamic-content 방식을 증명한다.

Source owners: `vehicle_stage_theme.tres`,
`vehicle_ui_component_factory.gd`,
`vehicle_modal_surface.gd`,
`vehicle_gameplay_hud.gd`,
`vehicle_upgrade_choice_card.gd`,
`vehicle_upgrade_choice_panel.gd`

- [ ] **5.1 production Theme style을 `StyleBoxTexture`로 교체한다.**
  - Accept: modal/HUD/card/button/tab/meter production styles의
    `StyleBoxFlat` count 0.
  - Guard: transparent/debug style과 screen dim은 exception으로 기록한다.
- [ ] **5.2 modal surface direct chrome draw를 제거한다.**
  - Accept: `VehicleModalSurface._draw()` decorative line/rect reference 0.
  - Guard: modal host sizing, input blocking, focus order와 content inset 동일.
- [ ] **5.3 HUD panel과 action rail을 image backplate로 교체한다.**
  - Accept: health/resource, objective/boss, minimap/target, action rail,
    toast/transition 모두 image surface ID를 가진다.
  - Guard: HP/XP/cooldown/minimap marker/notification은 동적이다.
- [ ] **5.4 upgrade card와 panel을 image component로 교체한다.**
  - Accept: normal/hover/pressed/focus/selected/disabled texture state,
    image pip, family glyph와 text layer가 올바르게 겹친다.
  - Guard: exact three cards, selection/confirm behavior와 upgrade application
    ownership은 변경하지 않는다.
- [ ] **5.5 typography와 text-safe inset을 정렬한다.**
  - Accept: Noto Sans KR 650/800, title 2줄, summary 3줄, effect row 최대 2,
    optional behavior와 pips가 compact/wide에서 모두 보인다.
  - Guard: font size를 14 미만으로 줄여 overflow를 숨기지 않는다.

Batch acceptance: ko/en × 960/1280/1920의 HUD+upgrade rendered matrix,
keyboard focus와 selected/disabled states 통과.

Batch guard: 아직 남은 modal을 flat style로 되돌려 shared Theme를 우회하지 않는다.

### Phase 6 — 나머지 UI surface 전환

Goal: 모든 player-facing panel과 control을 같은 image component system으로
완결한다.

Source owners: `vehicle_deployment_panel.gd`, `vehicle_pause_panel.gd`,
`vehicle_settings_panel.gd`, `vehicle_guidebook_panel.gd`,
`vehicle_guidebook_preview.gd`, `vehicle_stage_report_panel.gd`,
`vehicle_result_panel.gd`, `vehicle_garage_panel.gd`,
`vehicle_stage_transition_banner.gd`, `vehicle_boss_practice_panel.gd`

- [ ] **6.1 deployment와 pause를 전환한다.**
  - Accept: field/control/difficulty section, pause action group와 모든
    button state가 image-backed다.
  - Guard: deployment two-column/compact flow와 primary action 수 동일.
- [ ] **6.2 settings와 build status를 전환한다.**
  - Accept: tab/option/toggle/slider/summary strip image state가 실제 값과
    focus를 표시한다.
  - Guard: binding capture, locale, audio와 reduced-motion behavior 동일.
- [ ] **6.3 guidebook과 preview를 전환한다.**
  - Accept: category/list/detail/preview frame과 five category glyph가
    image-backed다.
  - Guard: actor/boss/pickup preview는 기존 semantic provider를 재사용한다.
- [ ] **6.4 report/result/garage를 전환한다.**
  - Accept: summary band, metric/list row, report tab/column과 action surface가
    image-backed다.
  - Guard: dynamic metric, percentage, icon과 scroll behavior 동일.
- [ ] **6.5 transition과 boss practice를 전환한다.**
  - Accept: transition banner는 narrow image frame을 사용하고 practice는
    settings/form component를 재사용한다.
  - Guard: debug-only practice를 위한 별도 production theme를 만들지 않는다.
- [ ] **6.6 direct decorative shape draw를 제거한다.**
  - Accept: upgrade selection mark, guide preview frame, category icon,
    deployment hint의 replaceable primitive draw reference 0.
  - Guard: live cooldown/progress, threat direction과 debug geometry는 allowlist에 남긴다.

Batch acceptance: 모든 modal surface의 ko/en × supported viewport,
focus path, selected/disabled/error/empty/locked state와 overflow 0.

Batch guard: localization text나 value를 이미지에 굽지 않는다.

### Phase 7 — 전체 visual acceptance와 legacy retirement

Goal: source/manifest가 아니라 실제 final runtime 화면으로 전환 완료를
증명하고 obsolete visual path를 제거한다.

Source owners: `tools/validation/`, capture path,
`.agents/semantic-v2-runtime-acceptance-evidence.md`

- [ ] **7.1 asset/event/UI coverage validator를 통과한다.**
  - Required: asset ID, frame, event mapping, state texture, 9-slice margin,
    duplicate owner, generic fallback, prohibited primitive surface.
- [ ] **7.2 full rendered capture matrix를 생성한다.**
  - ko/en × 960×540, 1280×720, 1920×1080
  - normal/reduced motion
  - grayscale semantic sheet
  - safe arrival, ordinary pressure, peak horde, all pickups/secondaries
  - every named effect
  - boss sealed/open/stable와 every module active/resolved
  - every modal, upgrade worst-copy, focus/selected/disabled/locked
- [ ] **7.3 AS-IS / TO-BE 비교 sheet를 생성한다.**
  - Output:
    - `docs/design/component-sheets/semantic-rework-v2-proposal/16-effects-runtime-asis-tobe.png`
    - `docs/design/component-sheets/semantic-rework-v2-proposal/17-ui-panels-asis-tobe.png`
    - `docs/design/component-sheets/semantic-rework-v2-proposal/18-pressure-readability-asis-tobe.png`
  - Accept: 같은 viewport/locale/state에서 current baseline과 final runtime을
    나란히 배치하고, effect ID·UI surface·readability 차이를 짧게 표시한다.
  - Guard: comparison sheet를 runtime asset이나 별도 visual authority로
    사용하지 않는다.
- [ ] **7.4 visual blockers를 수정한다.**
  - blocker: clipped/overflow text, actor hidden by non-danger overlay,
    indistinguishable critical pair, wrong effect timing, missing image surface,
    duplicate cue, missing focus 또는 color-only state.
  - warning만 남은 경우 근거와 capture path를 evidence에 기록한다.
- [ ] **7.5 legacy code와 asset을 제거한다.**
  - Remove only after replacement passes:
    - generic effect fallback
    - obsolete procedural effect recipes
    - decorative modal/card/preview `_draw()` code
    - unused flat production styles
    - zero-reference obsolete source/runtime assets
  - Accept: `rg` reference 0, import와 focused validators 통과.
- [ ] **7.6 visual acceptance checkpoint를 commit한다.**
  - 이 commit이 Phase 8 performance의 유일한 baseline이다.
  - Accept: worktree clean, commit hash와 manifest fingerprint가 evidence에 기록된다.

Batch acceptance: 모든 asset/UI가 교체됐다는 문구는 이 phase가 통과한
뒤에만 사용할 수 있다.

Batch guard: visual blocker가 하나라도 있으면 performance를 시작하지 않는다.

### Phase 8 — final-only performance, Web와 lifecycle

Goal: 최종 visual build만 측정하고, 현재 알려진 peak/capacity 실패를
bounded하게 교정한 뒤 release evidence를 만든다.

Source owners: existing performance scenario/recorder, renderer hot paths,
`tools/export_web.ps1`

- [ ] **8.1 final visual commit에서 focused 20초 native smoke를 한 번 실행한다.**
  - production replay, boss pressure, peak horde와 capacity pressure를
    같은 resolution/workload로 실행한다.
  - Accept: payload qualification과 subsystem timing이 유효하다.
  - Guard: 동일 build에서 hypothesis 없이 같은 실패 run을 반복하지 않는다.
- [ ] **8.2 실패한 subsystem만 non-behavioral하게 교정한다.**
  - Allowed: texture grouping, batch write, allocation reuse, overdraw,
    query/traversal과 already-approved data layout.
  - Forbidden: actor/projectile 수, pattern, collision, resolution, quality,
    language와 threshold 하향.
  - Escalate: engine/native/dependency rewrite가 필요하면 중단하고 별도 승인 요청.
- [ ] **8.3 qualified native authoritative matrix를 실행한다.**
  - `production_replay`, `boss_pressure`, `peak_horde`,
    `capacity_pressure`를 기존 canonical duration/threshold로 실행한다.
  - Accept: product spec과 existing performance recorder의 모든 gate 통과.
- [ ] **8.4 capacity 통과 뒤에만 600초 lifecycle soak를 실행한다.**
  - Accept: memory/pool/identity bounded, stale/duplicate 0, frame/physics gate 통과.
  - Guard: capacity 실패 상태에서 긴 soak에 자원을 쓰지 않는다.
- [ ] **8.5 production Web export와 built-Web smoke를 실행한다.**
  - `.\tools\export_web.ps1`
  - built output에서 deployment→gameplay, input, pause/pointer, ko/en,
    final HUD/effect/UI image를 확인한다.
  - server가 필요하면 repository port policy의 Codex lane을 사용한다.
- [ ] **8.6 Web performance matrix와 final evidence를 기록한다.**
  - Accept: export 성공만으로 Web runtime/performance를 통과 처리하지 않는다.
  - Guard: failed payload와 limitation도 삭제하지 않고 기록한다.

Batch acceptance: native/Web/capacity/lifecycle final gate가 모두 통과한다.

Batch guard: visual acceptance commit 이후 성능 변경이 화면을 바꾸면
Phase 7의 affected capture와 validator를 다시 실행한다.

## Test Plan / Validation Cadence

### Inner-loop commands

Asset/provider:

```powershell
.\tools\godot.ps1 --path . --headless --editor --quit
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_visual_sheet_coverage.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_semantic_visual_separation.gd
```

Combat/effect:

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_actor_visuals.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_combat_renderer.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_attack_contract.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_damage_feedback.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_boss_exams.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_pickup_contact.gd
```

UI:

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_upgrade_ui.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_ui_layout.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_ui_localization.gd
```

### Batch gates

- Phase 1–2: source/runtime image, manifest, alpha, canvas, pivot, margin,
  hash와 sheet validation
- Phase 3–4: named event capture, exact telegraph geometry, boss state,
  behavior fingerprint와 peak readability
- Phase 5–6: ko/en × three viewport rendered UI, 200% text, focus path,
  selected/disabled/locked, overflow/clipping 0
- Phase 7: 모든 focused validator와 complete runtime capture matrix
- Phase 8 only: performance scenario validator, native/Web matrix와 soak

Full focused suite:

```powershell
Get-ChildItem .\tools\validation\validate_*.gd |
  Sort-Object Name |
  ForEach-Object {
    .\tools\godot.ps1 --path . --headless --script ("res://tools/validation/" + $_.Name)
    if ($LASTEXITCODE -ne 0) {
      throw "Validator failed: $($_.Name)"
    }
  }
```

Runtime capture interface:

```powershell
$captureRoot = Join-Path (Resolve-Path .).Path "build\captures\complete-visual-replacement\ko-1280"
.\tools\godot.ps1 --path . -- --capture-all=$captureRoot --capture-locale=ko --capture-size=1280x720
```

같은 interface로
`ko-960`, `ko-1920`, `en-960`, `en-1280`, `en-1920` directory도
`build/captures/complete-visual-replacement/` 아래에 생성한다.
각 directory는 각각 960×540, 1280×720, 1920×1080의 고정 matrix와
일치하며 code/config에 특정 사용자 경로를 저장하지 않는다.

### Final gates

- Godot import와 full focused validator suite
- UIUX Level 4 evidence:
  - all production screens and reachable states
  - ko/en × 960/1280/1920
  - 200% text fit
  - keyboard/controller focus
  - reduced motion
  - grayscale semantics
  - peak-combat readability
- production Web export
- built-Web gameplay/UI smoke
- native/Web/capacity/lifecycle performance
- `git diff --check`
- lifecycle frontmatter와 plan/evidence status validation

### Rerun policy

- narrow check는 concrete code/asset change 또는 새 hypothesis가 있을 때만
  다시 실행한다.
- full visual matrix는 affected phase가 통과한 뒤 한 번 실행한다.
- authoritative performance matrix는 Phase 7 clean commit에서 bounded
  smoke가 통과한 뒤에만 실행한다.
- capacity가 실패하면 600초 soak를 실행하지 않는다.

## Predetermined Error Handling and Contingencies

| Trigger | Required response | Limit / escalation |
| --- | --- | --- |
| generated source가 approved general-SF family와 다름 | 해당 named source만 다시 생성하고 다른 accepted source는 보존 | theme 전체 재생성 금지 |
| 9-slice corner/rail이 늘어남 | manifest patch margin과 export safe inset을 고치고 해당 component만 재검수 | screen-specific giant image로 우회 금지 |
| text가 image safe area를 넘음 | layout/token/inset을 교정하고 font 최소값을 유지 | copy 삭제·14 미만 축소 금지 |
| semantic event mapping 누락 | producer 또는 catalog mapping을 같은 batch에서 완성 | generic fallback 복구 금지 |
| effect frame과 gameplay timing 불일치 | visual duration/frame event를 authoritative gameplay event에 맞춤 | damage timing 변경 금지 |
| peak에서 cue가 겹침 | non-danger duplicate/interior fill을 억제하고 image cue anchor를 조정 | harmful outline 숨김 금지 |
| module resolved visual이 active로 남음 | state vocabulary와 transition emission을 원자적으로 수정 | 별도 `disabled` gameplay state 발명 금지 |
| visual acceptance 전 성능 저하 의심 | 수치 기록만 하고 Phase 8까지 장시간 profiling을 보류 | asset/UI 작업을 중단해 최적화 확장 금지 |
| Phase 8 smoke 실패 | 가장 큰 measured subsystem 한 곳만 수정 후 smoke 재실행 | 무근거 full matrix 반복 금지 |
| native rewrite/dependency 필요 | 현재 phase를 중단하고 exact evidence와 요청 범위를 사용자에게 제시 | 승인 전 실행 금지 |
| browser surface 없음 | Web export까지만 수행하고 interactive/Web performance를 미통과로 기록 | native로 대체 통과 금지 |

## Rollback / Safety

- 다음 순서의 독립 commit을 유지한다.
  1. docs/contract and coverage
  2. gameplay effect/cue art
  3. UI component art
  4. semantic event/effect integration
  5. combat cue/telegraph presentation
  6. UI Theme/HUD/upgrade
  7. remaining UI surfaces
  8. visual acceptance/legacy cleanup
  9. final performance
  10. evidence/plan closure
- asset source, runtime export, manifest와 code mapping을 같은 책임 batch로
  추적한다.
- 새 path가 rendered acceptance를 통과하기 전에 이전 working path를
  삭제하지 않는다.
- unrelated user changes를 stage/revert/commit하지 않는다.
- generated capture, Web build와 performance payload는 ignored `build/`
  아래에 둔다. repository에는 bounded evidence summary만 남긴다.
- performance change가 visual output을 바꾸면 관련 Phase 7 capture를
  다시 통과시킨다.

## Risks

| Risk | Mitigation |
| --- | --- |
| image panel 수가 과도하게 늘어남 | reusable 9-slice component family와 Theme state로 제한 |
| alpha-heavy effect가 peak overdraw를 악화 | capped queue, atlas grouping, short non-loop, outline-first acceptance |
| UI image가 localization을 가둠 | text/icon/value를 굽지 않고 safe inset + dynamic layout 유지 |
| semantic cue가 또 다른 sticker clutter가 됨 | small actor-relative cue, single owner, priority ordering, peak capture gate |
| live telegraph를 이미지로 오해해 판정이 틀어짐 | exact geometry는 runtime owner, texture는 edge/pattern만 담당 |
| 기존 정상 asset을 다시 만들어 품질이 흔들림 | remaining-only production inventory를 validator로 고정 |
| 이전 evidence가 다시 과대 완료를 선언 | named event/state runtime capture를 completion prerequisite로 고정 |
| 마지막 성능 작업이 다시 범위를 삼킴 | Phase 8까지 금지, bounded smoke→measured subsystem→matrix 순서 고정 |

## Open Questions

Material open question은 없다. 다음 항목은 change-control boundary다.

- map generation, enemy tactics, boss pattern, new dependency, native rewrite,
  quality/capacity/threshold 변경은 이 계획의 구현 판단으로 선택할 수 없다.
- approved component direction과 다른 새 visual direction이 필요해지면
  이 계획을 멈추고 사용자 결정을 받아야 한다.

## Decision Notes

- 2026-07-31: 사용자는 UI panel을 image로 만들고 그 위에 text/icon을
  배치하는 방식을 명시했다.
- 2026-07-31: 효과는 one-shot raster animation과 simulation-driven
  collision truth를 분리하는 hybrid 방식으로 확정했다.
- 2026-07-31: 기존 effect sheet는 품질 방향으로 유지하지만 runtime
  wiring과 semantic separation은 미완료로 판정했다.
- 2026-07-31: map generation은 별도 draft에 남기고 이 active plan에서
  제외한다.
- 2026-07-31: performance는 모든 asset/UI switch와 rendered acceptance
  뒤 final-only로 실행한다.

## Progress

- [x] Current visual/effect/UI implementation을 read-only로 inventory했다.
- [x] 기존 image-backed family와 remaining primitive/generic family를 분리했다.
- [x] image/hybrid/procedural 경계와 event/UI asset contract를 잠갔다.
- [x] 실행 계획서를 생성했다.
- [x] Phase 0: authority와 acceptance truth 정정
- [ ] Phase 1: 추가 effect/cue asset pack
- [ ] Phase 2: UI image component pack
- [ ] Phase 3: semantic event/effect runtime switch
- [ ] Phase 4: combat cue/live telegraph 교정
- [ ] Phase 5: UI foundation/HUD/upgrade
- [ ] Phase 6: remaining UI surfaces
- [ ] Phase 7: full visual acceptance/legacy retirement
- [ ] Phase 8: final-only performance/Web/lifecycle

## Next Steps

1. Phase 0에서 visual spec과 acceptance evidence를 실제 current state로
   정정하고 coverage validator를 누락 감지 상태로 만든다.
2. Phase 1과 2에서 gameplay effect/cue와 UI component 이미지를 각각
   독립 pack으로 제작·검수한다.
3. Phase 3–6에서 runtime event와 모든 UI surface를 순서대로 전환한다.
4. Phase 7의 full rendered matrix가 통과한 clean commit을 만든다.
5. 그 commit에서만 Phase 8 성능·Web·lifecycle gate를 실행한다.

## Completion Criteria

- [ ] 기존 정상 actor/object/projectile/pickup image mapping이 회귀하지 않는다.
- [ ] 모든 production semantic event가 unique catalog mapping을 가진다.
- [ ] 기존 8개와 추가 effect animation이 정확한 runtime event에서 재생된다.
- [ ] hit, reflect, barrier와 four secondary effect가 서로 구분된다.
- [ ] generic `spawn/shock/secondary/destroy/support` visual fallback이 없다.
- [ ] boss resolved module이 one-shot effect 뒤 persistent disabled image를 사용한다.
- [ ] harmful telegraph는 exact gameplay geometry와 일치한다.
- [ ] non-spatial combat cue가 basic ring/diamond/beam을 의미 asset으로 사용하지 않는다.
- [ ] dash red radial instance가 0이고 hull-shaped afterimage가 보인다.
- [ ] 모든 production panel/control chrome이 image-backed다.
- [ ] text/icon/value/localization이 panel image와 분리돼 동적으로 표시된다.
- [ ] ko/en × 960/1280/1920과 200% text에서 overflow/clipping/overlap 0.
- [ ] focus/selected/disabled/warning/support/affinity가 color alone에 의존하지 않는다.
- [ ] peak capture에서 player, current target, committed threat와 boss objective가 읽힌다.
- [ ] effect, UI panel과 peak pressure의 AS-IS/TO-BE comparison sheet가 final runtime evidence를 사용한다.
- [ ] map, enemy tactic과 boss pattern fingerprint가 baseline과 동일하다.
- [ ] focused validators, production Web export와 built-Web smoke가 통과한다.
- [ ] final native/Web/capacity/lifecycle performance gate가 기존 threshold로 통과한다.
- [ ] obsolete visual path, duplicate owner와 zero-reference asset이 남지 않는다.
- [ ] final evidence가 source 존재와 runtime acceptance를 구분한다.
- [ ] 완료된 durable behavior는 active spec/evidence에 반영되고 이 plan은
  repository lifecycle 규칙에 따라 retired된다.

## Stop Conditions

Complete when:

- Phase 0–8 completion criteria와 final gates가 모두 통과하고 clean commit,
  manifest fingerprint, capture path와 performance payload가 evidence에
  기록된다.

Escalate only when:

- approved direction과 충돌하는 새 product decision이 필요하다.
- in-scope Godot/GDScript 경계로 threshold를 유지할 수 없고
  engine/native/dependency 변경이 필요하다.
- map, enemy tactic 또는 boss pattern 변경 없이는 요구 결과를 낼 수 없다는
  재현 가능한 evidence가 생긴다.

Do not stop when:

- asset file만 생성됐지만 runtime에 연결되지 않았다.
- validator가 source path만 확인하고 named runtime capture가 없다.
- Web export만 성공하고 built-Web smoke/performance가 없다.
- visual acceptance 전 성능이 걱정된다는 이유만으로 Phase 8을 앞당긴다.

## Handoff

```text
Goal:
Complete every remaining non-map gameplay effect/cue and UI image switch without
changing gameplay, then run final-only performance qualification.

Read first:
AGENTS.md
.agents/PLANS.md
docs/design/UI_VISUAL_SYSTEM.md
docs/product/vehicle_game_spec.md
this plan

Execute exactly:
Phase 0 through Phase 8 in order. Do not call asset production, runtime
integration, rendered acceptance, or performance complete interchangeably.

Validate with:
The focused commands and rendered matrix in Test Plan; performance only after
the Phase 7 clean visual commit.

Stop when:
Every completion criterion passes, or an explicit escalation boundary is met.
```
