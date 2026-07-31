---
type: plan
status: active
owner: BK
created: 2026-07-30
last_reviewed: 2026-07-31
scope: Integrate the approved semantic-v2 assets and UI, repair attack communication and boss damage/objective rules, then optimize non-behavioral hot paths after rendered acceptance
supersedes: ./2026-07-30-approved-sheet-fidelity-recovery.md
related:
  - ../../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../docs/design/component-sheets/semantic-rework-v2-proposal/README.md
  - ../../art/gameplay/semantic-v2/README.md
  - ../vehicle-performance-architecture-audit.md
  - ./2026-07-29-horde-foundation-recovery-and-acceptance.md
  - ./2026-07-31-deferred-map-tactics-boss-follow-up.md
---

# 시맨틱 에셋·UI·공격 표시·보스 목표·성능 안정화 실행 계획

## Purpose

현재 승인된 실행 범위만 완료한다.

1. 제작이 끝난 `semantic-v2` 이미지 에셋을 실제 runtime에 연결한다.
2. 전체 UI panel과 text hierarchy를 같은 시각 체계로 교체한다.
3. 투사체, 빔, 돌진, 범위, 지속 영역과 소환의 공격 표시를 실제 판정과
   일치시킨다.
4. 보스의 완전 피해 무효화를 피해 감소로 바꾸고, 현재 파괴해야 할
   objective를 일관되게 안내한다.
5. rendered asset/UI acceptance가 끝난 뒤에만 적의 행동을 바꾸지 않는
   grid, query, projectile traversal과 renderer hot-path 성능을 교정한다.
6. focused validator, Web export와 최종 성능 기준을 통과한다.

이 문서는 위 범위의 유일한 active execution authority다. 알고리즘 맵
생성, 적 합동 전략 변경과 다섯 보스의 새 pattern 설계는
`2026-07-31-deferred-map-tactics-boss-follow-up.md`에 보존하며 현재 구현
범위에 포함하지 않는다.

## Scope / Non-scope

### In scope

- runtime visual ID/state manifest와 texture/atlas provider
- player, 18 ordinary enemy, 5 boss body와 objective module
- seeker와 4 secondary, shield/barrier/field/protection source
- player/hostile projectile, 6 affinity, status와 짧은 combat effect
- pickup, reward, facility, minimap glyph와 UI icon
- HUD, objective tracker, upgrade, pause/settings, deployment, guidebook,
  report, result/garage와 boss practice panel
- shared attack commit과 lifecycle별 telegraph
- boss core damage multiplier, phase threshold와 sequential objective state
- incremental spatial membership, reusable query buffer/cache, projectile
  early exit, pre-sized render buffer와 transparent overdraw 감소
- rendered acceptance 뒤 final-only native/Web performance validation

### Out of scope

- floor/wall tile compiler, neighbor mask, map topology, map surface generation
  또는 기능 지형 재배치
- ordinary enemy의 역할별 거리대, squad angular slot, density steering,
  formation, collective tactic 또는 encounter composition 변경
- boss별 ranged/charge/reposition/nuisance/recovery pattern, pattern 순서,
  timing과 phase 조합 변경
- direct `RenderingServer`/`PhysicsServer2D` rewrite, thread-owned scene tree,
  GDExtension, C++ 또는 새 production dependency
- 적 수, projectile cap, 해상도, 언어 범위, visual quality 또는 성능
  threshold 하향

### Preserved behavior

- manual aim, held primary fire, dash, passive seeker와 EMP
- authored encounters, map pickups, card upgrades와 quota-gated stage boss
- 현재 map collision, navigation, cover, layout와 terrain schedule
- 현재 ordinary enemy와 boss pattern selection 및 movement
- swept collision과 existing capacity

## Assumptions

- Godot 4.7 stable과 GDScript를 유지한다.
- `art/gameplay/semantic-v2/asset-manifest.json`이 raster pack의 경로,
  canvas, pivot, attachment와 animation contract다.
- collision과 attack truth는 이미지나 UI가 아니라 현재 gameplay owner에
  남는다.
- 현재 구현된 pickup swept contact, hull-driven engine socket과
  directional dash afterimage는 교체 과정에서 보존할 regression guard다.
- deferred draft는 source material일 뿐 active plan이나 product spec을
  수정하지 않는다.

## Current State / Verified Evidence

### 완료된 것

- 세 AS-IS/TO-BE 비교 시안과 승인된 일반 SF 방향이 repository에 있다.
- `art/gameplay/semantic-v2/`에 다음 이미지 팩을 제작했다.
  - 고해상도 생성 원본 48장
  - 정적 runtime PNG 100개
  - 8개 효과의 독립 frame 38개와 atlas 8개
  - 검수용 family sheet 7개
  - `asset-manifest.json`
- manifest 추적 runtime PNG 146개의 alpha와 canvas 규격을 검사했다.
- 바닥 이미지 원본도 pack에 보존했지만 이번 active plan에서는 runtime
  map에 연결하지 않는다.
- pickup은 기체의 swept path와 현재 endpoint 접촉으로 획득된다.
- engine socket과 engine module rotation은 hull direction을 따른다.
- dash는 directional start effect, hull afterimage와 engine flare를
  사용하고 danger radial을 사용하지 않는 contract가 이미 있다.

### 아직 해결되지 않은 것

- runtime은 여전히 procedural `ArrayMesh`/`MultiMesh` 중심이며 새 raster
  pack을 소비하는 texture-instancing adapter가 없다.
- 일부 defense, secondary, projectile, status와 effect가 같은 geometry
  또는 색 차이에 의존한다.
- projectile, charge와 beam telegraph가 `corridor`를 공유하고 projectile은
  전체 lifetime path를 먼저 그린다.
- boss objective lock과 phase floor가 실제 damage path를 `0`으로 만든다.
- boss objective가 HUD, world arrow, radar와 minimap에서 동일한 active
  module state로 유지되지 않는다.
- upgrade card overflow와 panel typography/layout 회귀가 남아 있다.
- 보존된 `peak_horde` 3회는 적 `276`, hostile projectile `72`에서
  frame p95 `142.76–143.99 ms`, physics p95 `20.49–20.81 ms`,
  draw-call p95 `308`이었다.

## Authority Order

충돌하는 시각 판단은 다음 순서로 해소한다.

1. 사용자의 현재 피드백
2. `13-visual-taxonomy-asis-tobe.png`
3. `14-attack-telegraph-asis-tobe.png`
4. `00-general-sf-component-master-v1.png`의 hard-edged mechanical
   layering
5. `docs/design/UI_VISUAL_SYSTEM.md`
6. `art/gameplay/semantic-v2/asset-manifest.json`
7. runtime catalog와 component recipe

`15-world-layering-asis-tobe.png`는 deferred map draft의 evidence다. 현재
active 구현의 authority가 아니다. 승인하지 않은 재질·문화·해양·의례
theme, pixel 제약과 무의미한 장식 motif도 authority가 아니다.

## Pre-plan Evidence Already Verified

| Source | 확인된 사실 | 현재 결정 |
| --- | --- | --- |
| Godot 4.7 `MultiMesh` 문서와 performance guide | maximum-capacity allocation, visible instance count와 bulk buffer upload가 고밀도 rendering에 적합 | 개별 actor/effect마다 `Sprite2D`를 만들지 않고 texture-capable batch를 유지 |
| Godot Bullet Shower demo | 대량 projectile은 one-owner data와 shared render/collision shape로 관리 | 기존 projectile store와 batch owner 유지 |
| Godot GPU optimization guide | texture/material change와 겹친 transparent fill을 줄여야 함 | atlas grouping과 overdraw 축소 |
| Xbox XAG 102/103 | 중요한 대상은 색 외에도 contrast, outline과 cue가 필요 | silhouette, pattern, state를 함께 분리 |
| current telegraph builder/renderer | projectile lifetime path와 beam이 같은 corridor grammar를 공유 | projectile short lead와 beam full path 분리 |
| current boss exam runtime | objective lock은 damage allowance 0, phase floor는 damage clamp | sealed/open/stable multiplier와 phase trigger로 교체 |
| current spatial grid/run | live enemy membership을 반복 full rebuild | actor movement별 incremental membership으로 교체 |

## Locked Design

### Semantic visual grammar

모든 runtime visual은 `owner → function shape → affinity/status pattern →
state` 순서로 읽힌다. 색만 바꿔 다른 의미를 만들지 않는다.

| 의미 | 고정 identity |
| --- | --- |
| player barrier | hull-attached segmented armor plate |
| Ion Field | hull과 떨어진 segmented hex와 inward arc |
| generator shield | protected target bracket와 source tether |
| shield escort | target-facing slab와 short source link |
| repair field | floor-attached rounded square와 repair cross |
| seeker | arrowhead missile, rear fins와 short trail |
| orbit blades | 실제 crescent blade와 짧은 local orbit trail |
| wake mines | four-prong mine와 quadrant fuse |
| escort drone | enemy chevron과 다른 friendly twin-boom silhouette |
| burn / poison / chill | broken triangle / bead chain / split frost bar |
| muzzle / impact / barrier hit | forward flash / outward shard / inward shard |

모든 combat body는 같은 surface에 dark perimeter를 가진다. 별도의 밝은
outline은 committed attacker, elite, selected target와 active boss
objective 같은 우선순위 대상에만 사용하며 동시에 최대 12개다.

### Raster runtime integration

- runtime registry가 manifest ID/state를 texture region, pivot, attachment,
  animation과 batch group에 연결한다.
- high-count actor/projectile/effect는 texture-capable MultiMesh 또는
  capped pooled event batch를 사용한다.
- collision, radius와 telegraph footprint는 기존 simulation owner가
  계속 소유한다.
- hull, engine과 aim mount는 분리된 attachment다.
  - hull과 engine은 hull rotation을 따른다.
  - aim mount만 aim direction을 따른다.
  - engine flame 길이만 speed/dash state로 변하며 module 자체는 꺾이거나
    변형되지 않는다.
- dash start atlas 뒤에 hull-shaped afterimage를 재생하며 붉은 원을
  생성하지 않는다.

### Attack communication

모든 attack은 simulation과 presentation이 하나의 immutable resolved
commit을 공유한다.

```text
read/reposition
→ startup/locked telegraph
→ committed active geometry
→ recovery
```

| 공격 | startup | active | recovery |
| --- | --- | --- | --- |
| projectile/volley | muzzle, cadence pip와 최대 `0.4 s` lead capsule | 실제 projectile head/trail | 없음 |
| beam | full-path double edge와 source bracket | full-width spine | emitter cooldown plate |
| charge | tapered capsule, direction과 locked endpoint | actor/impact geometry | 실제 pattern이 제공하는 recovery 위치만 표시 |
| one-shot area | exact boundary와 inward countdown | strong boundary, minimum fill | 즉시 제거 |
| persistent zone | boundary, sparse pattern과 duration/tick | 같은 footprint 유지 | fade |
| summon/support | non-danger assembly bracket와 countdown | spawned entity | 없음 |

이 milestone은 pattern selection, timing, movement와 safe-lane scheduling을
바꾸지 않는다. 표시 우선순위만 조절하며 harmful geometry는 숨기지 않는다.

### Boss damage and objective

| 상태 | core damage multiplier |
| --- | ---: |
| `SEALED` | `0.20×` |
| `OPEN` | `1.55×` for `5.0 s` |
| `STABLE` | `1.00×` |

- objective lock early return과 `damage_allowance() == 0` clamp를 제거한다.
- phase floor는 다음 phase objective 시작 trigger이며 HP floor가 아니다.
- inactive sequential module은 target/collision candidate에서 제외하고
  projectile이 통과한다.
- reduced hit은 실제 damage number와 inward deflection feedback을 낸다.
- active module ID/state/health는 boss bar 아래 tracker, world arrow,
  threat radar와 minimap marker가 함께 소비한다.
- 이 변경은 boss pattern 목록, 순서, maneuver와 timing을 바꾸지 않는다.

### UI

- Noto Sans KR과 현재 bilingual typography contract를 유지한다.
- upgrade card는 compact/wide 모두 정해진 text region 안에서 title,
  body, tags와 footer가 겹치지 않는다.
- ko/en × 960/1280/1920과 200% text에서 overflow, clipping과 overlap이
  없어야 한다.
- HUD, minimap, objective tracker, pause/settings, deployment, guidebook,
  report, result/garage와 boss practice가 같은 token, glyph와 state
  provider를 소비한다.
- UI는 card behavior, attack truth와 boss objective progression을
  소유하지 않는다.

### Non-behavioral performance

다음 최적화는 enemy tactic이나 boss pattern을 바꾸지 않는다.

1. `VehicleSpatialGrid`는 spawn/reset 때 full initialize하고, spawn,
   movement, defeat 때 해당 runtime slot의 이전/현재 cell membership만
   갱신한다.
2. query dedup stamp와 reusable output buffer를 유지하고 support
   shield/repair assignment를 `10 Hz` cache로 재사용한다.
3. projectile grid traversal은 순서대로 cell을 방문하고 non-piercing
   projectile은 첫 contact 뒤 중단한다.
4. renderer는 entity를 한 번 순회해 pre-sized batch buffer에 쓰며
   descriptor dictionary와 temporary array를 hot path에서 만들지 않는다.
5. semantic perimeter는 actor surface에 굽고 의미 없는 translucent
   fill과 duplicate outline batch를 제거한다.
6. physics p95가 `12 ms`를 넘을 때만 hot
   position/velocity/radius/flags/phase/timer를 runtime-slot packed array로
   이동한다. authored cold data는 기존 object에 남긴다.

annular band, angular slot, density gradient, formation과 steering 값은 이
구조에 추가하지 않는다.

## Architecture And Ownership

| 책임 | owner | 변경 |
| --- | --- | --- |
| visual ID coverage | `vehicle_visual_system_registry.gd`, asset manifest | 모든 non-map runtime ID/state와 image region 연결 |
| actor/outline | actor visual catalog/mesh recipe | perimeter와 actor texture descriptor |
| secondary | 독립 secondary visual catalog | seeker와 4 secondary identity |
| defense/protection | 독립 defense visual catalog | barrier, field, shield source와 protection topology |
| projectile/status/effect | projectile/effect catalog와 recipe | affinity pattern, muzzle/impact/status 분리 |
| runtime render | `vehicle_combat_renderer.gd` | texture batch, attachment와 effect atlas 재생 |
| attack commit | attack contract와 boss/ordinary runtime owner | startup에서 resolved geometry 고정 |
| telegraph | `vehicle_attack_telegraph_builder.gd` | lifecycle별 presentation descriptor |
| boss damage/objective | `vehicle_boss_exam_runtime.gd`, damage path owner | multiplier, phase trigger와 module targetability |
| UI | 기존 panel별 owner와 shared component/token | layout, typography, glyph와 objective presentation |
| spatial membership | `vehicle_spatial_grid.gd` | incremental membership와 generation stamp |
| support query | current support assignment owner | reusable buffer와 assignment cache |
| projectile traversal | projectile collision owner | ordered cell traversal와 early exit |
| validation | `tools/validation/`의 책임별 validator | coverage, attack, boss, UI와 performance |

큰 `vehicle_run.gd`에는 orchestration만 남긴다. visual grammar, card
behavior, UI layout, boss pattern data와 새 grid implementation을 이 파일에
추가하지 않는다.

## Tasks

### Milestone 0 — authority와 runtime inventory

- [x] 이전 visual/performance recovery plan을 `superseded`로 표시했다.
- [x] AS-IS/TO-BE sheet의 hash와 authority를 기록했다.
- [x] map, enemy coordinated tactics와 boss pattern redesign을 별도
  `draft` plan으로 분리했다.
- [ ] non-map runtime visual ID/state를 manifest에 전부 등록하고 누락
  목록을 validator fixture로 고정한다.
- [ ] AS-IS `system-v1` sheet를 historical evidence로만 남기고 production
  target에서 제외한다.

### Milestone 0A — semantic-v2 이미지 제작·패키징

- [x] 고해상도 원본 48장, 정적 runtime PNG 100개, effect frame 38개와
  atlas 8개를 제작했다.
- [x] 검수용 family sheet 7개와 asset manifest를 패키징했다.
- [x] manifest 추적 PNG 146개의 alpha/canvas 규격을 검사했다.

이 milestone은 이미지 제작 완료만 뜻한다. runtime 연결과 rendered
acceptance는 아직 완료되지 않았다.

### Milestone 1 — runtime provider와 catalog

- [ ] manifest loader/provider가 texture region, pivot, attachment,
  animation과 batch group을 제공하게 한다.
- [ ] secondary와 defense catalog를 독립 owner로 만들고
  owner/function/pattern/state signature를 descriptor에 추가한다.
- [ ] runtime provider만 production sheet와 live renderer source를
  소비하게 한다.
- [ ] missing ID/state, empty texture region, exact alias와 critical-pair
  collision을 실패시키는 validator를 추가한다.

### Milestone 2 — non-map in-game asset switch

- [ ] player, 18 enemy, 5 boss body와 objective module을 runtime image
  descriptor로 교체한다.
- [ ] player Escort Drone을 enemy chevron에서 분리하고 seeker와 4
  secondary를 각각 고유 identity로 교체한다.
- [ ] shield/barrier/field/protection source를 독립 topology로 교체한다.
- [ ] player/hostile projectile, 6 affinity, status, muzzle, impact,
  reflect, dash와 barrier hit을 독립 signature로 교체한다.
- [ ] pickup, reward, facility, minimap glyph와 UI icon이 manifest
  coverage를 통과하게 한다.
- [ ] engine module이 hull에 고정되고 aim mount만 aim을 따르는지
  검증한다.
- [ ] dash danger/radial instance가 0이고 afterimage/engine flare만
  남는지 검증한다.
- [ ] pickup swept contact와 dash-through collection을 회귀하지 않는다.
- [ ] floor, wall과 world-layering asset은 runtime map에 연결하지 않는다.

### Milestone 3 — attack telegraph

- [ ] simulation/presentation shared resolved commit을 구현한다.
- [ ] projectile과 lane volley의 full-lifetime corridor를 최대 `0.4 s`
  lead와 cadence pip로 교체한다.
- [ ] beam, charge, one-shot area, persistent와 summon/support의
  lifecycle geometry를 구분한다.
- [ ] ordinary mob, terrain hazard와 current boss attack이 같은 grammar를
  소비하게 한다.
- [ ] pattern selection, timing, movement와 encounter output이 변경되지
  않았음을 regression fixture로 고정한다.

### Milestone 4 — boss damage, objective와 guidance

- [ ] phase floor damage clamp와 objective lock damage early return을
  제거한다.
- [ ] `SEALED 0.20×`, `OPEN 1.55×/5 s`, `STABLE 1.00×`를 구현한다.
- [ ] inactive sequential module을 non-targetable/pass-through로 만든다.
- [ ] boss tracker, world arrow, threat radar와 minimap marker를 같은
  active module ID/state/health에 연결한다.
- [ ] reduced hit과 objective 해결 feedback이 실제 multiplier/state를
  표시하게 한다.
- [ ] objective text hint는 state 진입 때 한 번 표시하고 같은 hint는
  `2 s` 안에 반복하지 않게 한다.
- [ ] localization의 과장되거나 구현과 다른 문구를 ko/en 모두 교정한다.
- [ ] boss pattern 목록, 순서, timing과 movement fingerprint가 변경되지
  않았음을 검증한다.

### Milestone 5 — 모든 UI panel과 text regression

- [ ] upgrade의 font, weight, line height와 compact/wide card overflow를
  교정한다.
- [ ] HUD, minimap, objective tracker, pause/settings, deployment,
  guidebook, report, result/garage와 boss practice를 shared visual
  provider로 교체한다.
- [ ] ko/en × 960/1280/1920, 200% text, selected/focus/disabled에서
  visible overflow, clipping, overlap와 invisible state를 0으로 만든다.

### Milestone 6 — rendered visual acceptance

- [ ] manifest-covered non-map production sheet에서 missing/empty cell이
  0인지 확인한다.
- [ ] `13`과 `14` v2 proposal 옆에 같은 scale의 runtime comparison을
  생성한다.
- [ ] player/engine/dash, clustered combat, secondary/defense matrix,
  projectile/status/effect, boss sealed/open/stable, worst upgrade triplet과
  모든 modal을 사람이 직접 검토한다.
- [ ] grayscale와 color-vision simulation에서 critical pair가 shape와
  pattern으로 구분되는지 확인한다.
- [ ] visual/UI failure가 하나라도 있으면 Milestone 1–5로 돌아가고
  performance milestone을 시작하지 않는다.

### Milestone 7 — final-only non-behavioral performance

- [ ] incremental grid membership와 generation-stamp consistency를
  구현한다.
- [ ] reusable support assignment cache와 projectile traversal early
  exit을 구현한다.
- [ ] renderer hot-path temporary allocation과 transparent overdraw를
  제거한다.
- [ ] enemy tactic, formation, movement와 boss pattern fingerprint가
  바뀌지 않았음을 검증한다.
- [ ] physics p95가 `12 ms`를 넘을 때만 packed hot-state contingency를
  적용한다.
- [ ] focused `3×20 s` peak/production retention을 통과한 뒤에만
  authoritative `3×60 s` native/Web matrix를 실행한다.
- [ ] 276 peak, 320 capacity, boss scenario와 lifecycle soak를 실행한다.
- [ ] density, resolution, quality, language coverage와 threshold를
  낮추지 않는다.

### Milestone 8 — publication과 closure

- [ ] Web export와 production-style built-Web smoke를 실행한다.
- [ ] asset manifest, sheet hash, capture matrix, performance payload와
  known limitations를 기록한다.
- [ ] durable implemented behavior를 UI visual system과 product spec에
  반영한다.
- [ ] acceptance가 전부 끝나면 이 plan의 durable content를 반영한 뒤
  plan lifecycle을 종료한다.

## Validation And Acceptance

### Visual uniqueness

- [ ] barrier, Ion Field, generator shield, shield escort와 repair field가
  color를 제거해도 다르다.
- [ ] seeker, orbit blade, wake mine과 escort drone이 silhouette만으로
  다르다.
- [ ] burn, poison, chill과 6 affinity가 shape/pattern으로 다르다.
- [ ] muzzle, impact, commit, objective와 pickup이 같은 exact recipe를
  공유하지 않는다.
- [ ] 모든 combat body가 dark perimeter를 가지며 bright priority
  marker는 동시에 최대 12개다.
- [ ] manifest ID/state와 non-map production cell 수가 일치한다.

### Attack and boss objective

- [ ] projectile telegraph가 `0.4 s`보다 먼 full path를 그리지 않는다.
- [ ] beam만 full path를 그린다.
- [ ] charge endpoint와 harmful geometry가 simulation commit과 동일하다.
- [ ] persistent zone은 남은 duration/tick을 표시한다.
- [ ] boss가 sealed일 때 실제 HP가 `0.20×`로 감소하고 `0` damage gate가
  없다.
- [ ] active objective가 HUD, world arrow, radar와 minimap에서 같은 ID,
  state와 health를 보인다.
- [ ] inactive sequential module은 target/collision hit을 만들지 않는다.
- [ ] objective state-entry hint는 한 번만 발생하고 동일 hint의 반복
  간격은 `≥2 s`다.
- [ ] boss pattern과 movement fingerprint는 baseline과 동일하다.

### UI

- [ ] ko/en 960/1280/1920과 200% text에서 overflow, overlap과 clipping이
  0이다.
- [ ] boss objective panel이 boss bar 때문에 숨지 않는다.
- [ ] UI 문구가 실제 구현하지 않은 mechanic을 주장하지 않는다.

### Final-only performance

- [ ] `peak_horde`가 적 `276`, hostile projectile `72`로 유효하다.
- [ ] median FPS `≥59`, 1% low `≥55`
- [ ] frame p95 `≤18 ms`, p99 `≤25 ms`
- [ ] draw-call p95 `≤200`, combat batches `≤50`
- [ ] consecutive frame `>33.3 ms`가 `≤1`
- [ ] production replay qualification이 유효하다.
- [ ] 320 capacity, boss, native/Web와 lifecycle memory 기준을 통과한다.

packed hot-state까지 적용해도 performance gate가 실패하면 dependency,
native rewrite 또는 threshold 변경으로 자동 확대하지 않는다. payload와
subsystem evidence를 보존하고 별도 권한을 요청한다.

## Test Plan

구현 중에는 변경 owner의 focused validator와 rendered crop만 실행한다.
전체 성능 측정은 Milestone 6 승인 뒤에만 시작한다.

기존 validator:

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_actor_visuals.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_combat_renderer.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_attack_contract.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_boss_exams.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_upgrade_ui.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_ui_layout.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_ui_localization.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_pickup_contact.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_spatial_grid.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_performance_scenarios.gd
```

추가할 focused validator:

```powershell
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_semantic_visual_separation.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_visual_sheet_coverage.gd
```

asset/UI와 runtime 변경이 끝나면 Web export를 실행하고 built output으로
manual capture matrix를 확인한다. performance command와 payload path는
기존 performance scenario owner의 canonical interface를 사용한다.

## Rollback / Safety

- asset provider, actor/effect integration, telegraph, boss objective, UI와
  performance를 독립 commit으로 유지한다.
- map compiler, encounter tactic, boss pattern owner는 수정하지 않는다.
- collision geometry와 visual canvas/pivot을 분리한다.
- source manifest에서 생성한 sheet/capture를 수동 PNG로만 수정하지 않는다.
- user-authored unrelated change를 stage, revert 또는 cleanup하지 않는다.
- visual/UI gate 전에는 authoritative performance run을 시작하지 않는다.

## Risks

| 위험 | 조기 신호 | 대응 |
| --- | --- | --- |
| texture integration이 batch를 폭증시킴 | combat batch `>50` | atlas grouping과 pre-sized texture-capable batch 유지 |
| outline이 군집을 sticker처럼 합침 | grayscale pressure capture에서 body 경계 소실 | dark perimeter는 같은 surface, bright marker는 12개 제한 |
| 공격 표시와 판정이 어긋남 | 같은 attack의 endpoint/width가 서로 다름 | resolved commit 하나만 simulation/presentation이 소비 |
| objective guidance가 text spam이 됨 | 같은 hint가 2초 안에 반복 | state-entry 1회와 cooldown, shape cue를 1차 정보로 사용 |
| `0.20×` damage가 objective를 무의미하게 함 | objective 전 kill time이 full damage와 비슷 | `0.20×` 고정과 `1.55×/5 s` open reward 유지 |
| UI 수정이 card behavior를 흡수함 | UI code가 upgrade effect를 해석 | card data/runtime owner로 되돌리고 UI는 presentation만 수행 |
| incremental grid membership이 stale함 | query가 dead/moved slot 반환 | generation stamp와 spawn/defeat/reset consistency validator |
| 최종 성능이 실패함 | physics p95 `>12` 또는 frame p95 `>18` | packed hot-state까지 실행한 뒤 evidence와 함께 별도 escalation |

## Progress

- runtime visual alias, sheet coverage, attack telegraph, boss damage path,
  UI layout, spatial grid와 보존된 performance payload를 감사했다.
- `semantic-v2` 이미지 에셋의 제작·분할·패키징과 기초 파일 검증을
  완료했다.
- pickup contact, hull-driven engine socket과 dash afterimage contract가
  현재 코드에 있음을 확인했다.
- 사용자 지시에 따라 map generation, enemy coordinated tactics와 boss
  pattern redesign을 별도 draft로 분리했다.
- runtime provider/adapter, 실제 image switch와 UI replacement는 아직
  시작하지 않았다.

## Next Steps

1. Milestone 0의 runtime ID/state inventory와 production exclusion을
   완료한다.
2. Milestone 1–5 순서로 provider, non-map asset, telegraph, boss
   damage/objective와 UI를 구현한다.
3. Milestone 6 rendered acceptance를 통과한다.
4. 그 뒤에만 Milestone 7의 non-behavioral performance와 final matrix를
   실행한다.
5. Web export와 documentation closure로 끝낸다.

## Open Questions

현재 active 범위에는 material open question이 없다. map, enemy tactic과
boss pattern을 다시 다루려면 deferred draft의 판단·승인 단계를 별도
사용자 지시로 시작해야 하며 이 계획의 구현을 막지 않는다.

## Decision Notes

- 2026-07-30: 색 차이만으로 다른 asset을 표현하는 방식을 폐기하고
  owner/function/pattern/state contract를 선택했다.
- 2026-07-30: player barrier, Ion Field, enemy source shield와 repair
  field를 독립 topology로 고정했다.
- 2026-07-30: boss hard immunity와 phase-floor clamp를 폐기하고
  `0.20/1.55/1.00` damage policy를 선택했다.
- 2026-07-30: 성능 측정과 최적화는 모든 asset/UI rendered acceptance
  이후 마지막 milestone로 유지한다.
- 2026-07-31: `semantic-v2` 이미지 에셋 생성·분할·패키징을 완료했다.
- 2026-07-31: 사용자의 범위 축소에 따라 map generation, enemy
  coordinated tactics와 boss pattern redesign을 active authority에서
  제거하고 별도 draft에 보존했다.
- 2026-07-31: active performance 범위는 enemy/boss behavior를 바꾸지
  않는 data structure, query, traversal, allocation과 overdraw 교정으로
  제한했다.
