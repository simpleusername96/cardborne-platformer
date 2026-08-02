---
type: plan
status: active
owner: BK
created: 2026-08-02
last_reviewed: 2026-08-02
topic: 7월 31일 이후 미해결 비디자인 이슈 처리
scope: 7월 31일~8월 2일 비디자인 이슈 원장, 고밀도 전투 성능 복구, release qualification
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../semantic-v2-runtime-acceptance-evidence.md
---

# 7월 31일 이후 미해결 비디자인 이슈 처리 계획

7월 31일부터 8월 2일까지 나온 비디자인 이슈를 전수 대조했다. 해결된
항목은 회귀 검사만 유지하고, 실제 미해결인 고밀도 전투 성능을 측정 →
상위 병목 수정 → release 검증의 세 단계로 끝낸다. 디자인·에셋, 알고리즘
맵 생성, 일반 적 전략과 boss pattern은 이 계획에 포함하지 않는다.

## Purpose

- 목표: 해당 기간의 미해결 비디자인 코드 이슈를 모두 해결한 뒤에만 새
  asset 제작을 시작한다.
- 최종 산출물: 성능 개선 코드, 회귀 validator, native/Web 성능 결과,
  600초 lifecycle 결과와 갱신된 acceptance evidence.
- 완료 상태: 고밀도 전투 performance defect와 미실행 release gate가 모두
  해소된 `code_ready_for_asset_work`.

## Why / Context

이전 계획은 player craft, UI shell, map presentation과 visual inventory까지
실행 대상으로 잘못 넣었다. 최신 지시는 디자인이 아닌, 7월 31일 이후의
미해결 코드 이슈를 먼저 끝내라는 것이다.

현행 코드와 validator를 다시 확인한 결과 pickup 접촉 획득, upgrade UI
overflow, boss 무피해, boss objective 안내, source-of-truth 정리와 capture
책임 분리는 이미 해결됐다. 남은 사용자 보고 defect는 “적이 몰릴 때
렉이 걸린다”는 성능 문제 하나다. `peak_horde`와 `capacity_pressure`가
실제 release threshold를 넘고, 그 때문에 600초 lifecycle qualification도
아직 수행되지 않았다.

## Audit Coverage

| Root session | 확인한 사용자 범위 | 비디자인 판정 |
| --- | --- | --- |
| `C:/Users/BK/.codex/sessions/2026/07/31/rollout-2026-07-31T13-22-07-019fb668-756a-75f1-8038-6a28323e6b42.jsonl` | lines 10, 8419, 10876, 12276-12342 | pickup·upgrade·boss 기능은 해결, 군집 성능만 미해결, 맵 생성은 보류, 적/boss 전략은 제외 |
| `C:/Users/BK/.codex/sessions/2026/08/01/rollout-2026-08-01T23-32-12-019fbdbd-60ce-71b3-ad72-a10941855269.jsonl` | lines 9, 543, 975 | 문서 권위·capture 구조·built-Web smoke는 recovery 작업으로 완료, 미해결 성능은 evidence에 유지 |
| `C:/Users/BK/.codex/sessions/2026/08/02/rollout-2026-08-02T09-39-40-019fbfe9-857e-7453-b72d-20908d848577.jsonl` | lines 9-2126, 2638, 2648 | 2126 이전은 디자인 지시, 2126·2648이 본 계획의 비디자인 범위를 확정 |

세션의 환경/AGENTS 재주입 메시지와 “continue/proceed”는 새 이슈가 아니므로
원장 항목으로 세지 않았다.

## Pre-plan Evidence Already Verified

| Evidence | 확인 결과 | 현재 결정 |
| --- | --- | --- |
| `VEHICLE_PICKUP_CONTACT_VALIDATION_OK` | 기체 이동 경로와 item 접촉 획득 통과 | 재구현 없음 |
| `VEHICLE_UPGRADE_UI_VALIDATION_OK`, `VEHICLE_STAGE_UI_LAYOUT_VALIDATION_OK` | upgrade 기능 layout·overflow 통과 | 재구현 없음 |
| `VEHICLE_BOSS_EXAMS_VALIDATION_OK` | sealed core도 `0.20×`의 0보다 큰 피해, phase hint 통과 | 재구현 없음 |
| `VEHICLE_RUN_VALIDATION_OK` | boss strip, active objective, minimap·off-screen radar 소비 경로 통과 | 재구현 없음 |
| commits `e9efe70`, `7f9c554`, `4ffd04c`, `DOCUMENT_AUTHORITY_VALIDATION_OK`, `VEHICLE_RUN_CAPTURE_DRIVER_VALIDATION_OK` | 정본 문서, capture 책임, built-Web recovery 완료 | 기존 경계 유지 |
| `git show e9efe70^:.agents/vehicle-performance-architecture-audit.md` | external Godot 자료와 공식 Bullet Shower를 비교해 data-oriented GDScript 구조를 이미 선택·구현함 | 외부 조사를 반복하지 않고 현재 병목을 측정 |
| `.agents/semantic-v2-runtime-acceptance-evidence.md` lines 146-180 | peak/capacity 실패, lifecycle 600초 미실행 | 유일한 활성 defect와 후속 gate |
| `scripts/vehicle/vehicle_run.gd` lines 6020-6089, `scripts/performance/vehicle_performance_recorder.gd` lines 347-412 | native/Web request와 JS result publish가 이미 있음 | 새 Web bridge 생성 금지 |
| `scripts/vehicle/vehicle_run.gd` lines 3189-3405 | reusable projectile query buffer와 cell-exit early stop이 이미 있음 | 같은 최적화 재구현 금지 |

위 validator들은 2026-08-02 현재 HEAD에서 exit code 0으로 다시 실행했다.

## Complete Non-design Issue Ledger

| 이슈 | 최초 근거 | 상태 | 증거 / 처리 |
| --- | --- | --- | --- |
| 기체가 item에 닿으면 획득 | 7/31 line 10 | 해결 | pickup contact validator 통과 |
| upgrade 겹침·텍스트 layout·세로 overflow | 7/31 lines 10, 8419 | 해결 | upgrade UI와 stage layout validator 통과 |
| boss HP가 특정 조건에서 전혀 줄지 않음 | 7/31 line 10876 | 해결 | reduced damage와 threshold validator 통과 |
| 무엇을 파괴해야 boss가 약해지는지 알 수 없음 | 7/31 line 10876 | 해결 | HUD objective, minimap, radar validator 통과 |
| 적이 몰릴 때 lag가 발생함 | 7/31 line 10876 | **미해결** | peak p95/p99 `20.87/33.33 ms`, 1% low `27.04 FPS`; capacity p95/p99 `30.79/50.00 ms`, physics `13.20/16.84 ms` |
| 오래된 문서·코드·에셋으로 source of truth가 분산됨 | 8/1 line 9 | 해결 | authority recovery commit과 validator |
| capture/tooling과 gameplay orchestration 책임 혼재 | 8/1 lines 9, 975 | 해결 | capture gateway 추출과 validator |
| 프로젝트 구조가 과도한가 | 8/1 line 9 | 추가 actionable defect 없음 | 확인된 capture 집중은 제거했고, 파일 크기만으로 전면 rewrite할 근거는 없음. 성능 변경은 기존 owner에 두는 guard만 유지 |

`lifecycle_pressure` 600초 미실행은 별도 사용자 보고 defect가 아니라, 위 성능
defect를 고친 뒤 반드시 통과해야 하는 release qualification이다.

## Scope / Non-scope

### In scope

- fresh `capacity_pressure` 기준선과 세부 physics cost 측정.
- 측정상 가장 큰 owner를 한 번에 하나씩 개선.
- 성능 관련 정책과 자료구조를 기존 schedule/grid/renderer owner에 유지.
- native/Web performance matrix, 600초 lifecycle soak.
- focused/full validators, import, production Web export, built-Web smoke.
- 최종 acceptance evidence 갱신.

### Non-scope

- 새 image, repaint, asset switch, art style, UI visual 변경.
- player craft, UI shell, map surface, visual inventory 변경.
- 일반 적 전술·역할·수치, boss pattern·module·전략 변경.
- 알고리즘 map topology 또는 stage reroll.
- actor/projectile/effect 수, 해상도, 언어, visual quality나 threshold 하향.
- `VehicleRun` 전면 rewrite, engine 교체, native extension, 새 dependency.
- 이미 해결된 ledger 항목의 재구현.

Destructive action은 없다. dependency/native extension, workload 축소 또는
threshold 변경이 필요하면 현재 범위를 넘으므로 사용자 승인 전 중단한다.

## Assumptions

- 현재 HEAD의 코드와 validator가 과거 assistant 설명보다 우선한다.
- capture/doc 전용 후속 commit은 performance workload를 바꾸지 않았다.
- 비교 run은 같은 build, 1280×720, focused window, 10초 warmup + 60초
  measurement와 같은 scenario composition을 사용한다.
- 환경 편차 때문에 기준선과 변경 후 `capacity_pressure`를 각 3회 실행하고
  median p95를 비교한다.
- performance recorder가 꺼진 ordinary play에는 새 timer, sample array 또는
  Dictionary allocation을 추가하지 않는다.

## Locked Decisions

1. gameplay workload, 품질과 release threshold를 낮추지 않는다.
2. fresh 계측의 median p95가 가장 큰 owner부터 한 번에 하나만 바꾼다.
3. 동일 값이면 더 적은 owner/file을 건드리는 변경을 먼저 한다.
4. target median p95가 run-to-run 범위를 넘어 개선되고 다른 locked gate가
   악화되지 않은 변경만 commit한다. 불분명한 실험은 보존하지 않는다.
5. 현재 구현된 Web request/result path와 projectile cell-exit early stop을
   재작성하지 않는다.
6. `VehicleRun`은 호출 순서만 조정하고, 최적화 자료구조와 정책은 기존
   subsystem owner가 소유한다.
7. capacity 통과 뒤 native 전체 matrix → Web matrix → lifecycle 600초
   순서로 검증한다.
8. 모든 final gate가 통과하기 전에는 asset 제작·적용을 시작하지 않는다.

## Rejected Alternatives

| 대안 | 기각 이유 |
| --- | --- |
| 이전 기체/UI/map/inventory 단계를 유지 | 최신 비디자인 범위와 충돌 |
| workload·quality 축소 또는 threshold 완화 | defect를 숨기고 release 기준을 훼손 |
| `VehicleRun` 전면 rewrite | 성능 문제보다 회귀 범위가 커짐 |
| 구현 순서를 미리 schedule → grid → projectile로 고정 | fresh 계측 결과를 무시하고 이미 구현된 작업을 반복할 수 있음 |

## Architecture and Ownership

| 파일 / owner | 책임 | 불변조건 |
| --- | --- | --- |
| `scripts/performance/vehicle_performance_scenario.gd` | workload와 composition | actor/projectile/effect 수와 validation 유지 |
| `scripts/performance/vehicle_performance_recorder.gd` | metric, threshold, result publish | threshold와 authority 판정 유지 |
| `scripts/vehicle/vehicle_run.gd` | subsystem orchestration | gameplay state와 호출 순서 유지 |
| `scripts/enemies/vehicle_enemy_update_schedule.gd` | cadence와 worklist | per-tick 거리·timer·phase·commit semantics 유지 |
| `scripts/combat/vehicle_spatial_grid.gd` | actor membership과 broadphase query | stable slot, generation, earliest hit 유지 |
| `scripts/combat/vehicle_projectile_store.gd` | bounded projectile pool | capacity와 swap-remove identity 유지 |
| `scripts/presentation/vehicle_combat_renderer.gd` | visible actor/effect instance | 화면 안 telegraph와 화면을 가로지르는 telegraph 유지 |
| `.agents/semantic-v2-runtime-acceptance-evidence.md` | release evidence | commit, dirty state, environment, raw result path 기록 |

새 catch-all manager는 만들지 않는다.

## Proposed Design

### As-is / To-be Delta

| Concern | As-is | To-be | Acceptance |
| --- | --- | --- | --- |
| baseline | 과거 authoritative 실패와 current short smoke만 있음 | current HEAD capacity 3회 | 세 run 모두 authoritative·scenario valid |
| physics detail | enemy 세부 timing은 있으나 grid/projectile/effect 비용이 큰 합산 구간에 있음 | performance-active일 때만 physics substep을 더 분리 | recorder-off path에 새 allocation 0, key와 sample count 검증 |
| bottleneck selection | aggregate 추정으로 구현 후보를 먼저 고름 | 3-run median p95 상위 owner 한 개씩 처리 | 선택 근거와 before/after 결과 기록 |
| presentation | aggregate `presentation_ms`는 있으나 내부 breakdown은 없음 | physics 통과 뒤 presentation이 최대 비용일 때만 frame-detail API 추가 | physics recorder와 frame recorder를 섞지 않음 |
| release proof | peak/capacity 실패, lifecycle 600초 없음 | native/Web matrix와 lifecycle 모두 통과 | raw JSON과 evidence checkpoint |

### Known Candidate Map

후보는 작업 순서가 아니다. Phase 0 결과에서 해당 owner가 실제 상위
병목일 때만 사용한다.

| Measured owner | 현재 확인된 비용 후보 | 허용된 변경 경계 |
| --- | --- | --- |
| enemy budget/schedule | `rebuild()`가 live enemy를 매 tick 순회하고 조건부로 두 번 호출됨 | per-tick 거리·timer·phase·commit 계산을 유지한 채 중복 traversal/clear만 제거 |
| spatial grid write | membership 제거가 각 cell에서 `Array.erase(slot)` 사용 | cell별 reverse index와 swap된 slot의 index까지 함께 갱신하고 multi-cell/retire/reuse 검증 |
| combat/projectiles | player/hostile projectile와 effects가 한 timing에 합산됨 | 기존 buffer·cell-exit를 유지하고 새 계측이 지목한 반복 작업만 제거 |
| presentation | off-screen actor도 view-intersecting telegraph 검사를 먼저 수행함 | actor body culling과 telegraph-view intersection을 분리하되 화면에 들어오는 telegraph 보존 |

### Retention Rule

각 변경은 task-owned commit 후보로 격리한다. 변경 전후 각 3회 run의 target
median p95와 분포 범위를 비교한다. 개선이 run-to-run 변동 범위 안이거나
다른 release metric·기능 validator가 악화되면 commit 전에 해당 실험
diff만 되돌린다. 관련 사용자 변경과 겹치면 자동으로 되돌리지 않고 중단한다.

## Tasks / Milestones

### Phase 0 — Fresh baseline과 비용 순위

- [ ] current HEAD의 `capacity_pressure`를 authoritative 조건으로 3회 실행하고
  raw JSON과 median 표를 저장한다.
- [ ] `_physics_process()`의 unconditional empty timing Dictionary를 recorder가
  켜졌을 때만 만들도록 바꾸고 source contract를 validator에 추가한다.
- [ ] 기존 enemy detail을 중복하지 않고 grid writes, player projectile,
  hostile projectile, zones/trails/effects를 performance-only key로 분리한다.
- [ ] detail key가 performance run에서만 기록되고 각 key에 sample이 있는지
  `validate_vehicle_performance_scenarios.gd`로 고정한다.
- [ ] 계측이 들어간 build의 capacity 3회를 다시 실행해 median p95 owner
  순위를 확정한다.

Exit: current HEAD 기반의 재현 가능한 비용 순위가 있고 ordinary play에 새
계측 allocation이 없다.

### Phase 1 — 가장 큰 physics owner부터 반복 개선

- [ ] median p95가 가장 큰 아직 처리하지 않은 owner 하나를 선택한다.
- [ ] Known Candidate Map 경계 안에서 한 가지 변경만 구현한다.
- [ ] 해당 owner validator와 `validate_vehicle_performance_scenarios.gd`,
  `validate_vehicle_run.gd`를 통과한다.
- [ ] capacity 3회 before/after에 Retention Rule을 적용한다.
- [ ] 유지한 결과로 비용 순위를 다시 계산하고, capacity physics p95/p99
  `6/8 ms`와 전체 frame gate가 3회 모두 통과할 때까지 반복한다.

Exit: capacity 3회가 모두 통과하거나, 후보 owner를 모두 검증했는데도 남은
비용이 정확히 식별돼 있다.

### Phase 2 — 필요한 경우에만 frame/presentation 개선

- [ ] capacity physics는 통과했지만 frame gate가 실패하고
  `presentation_ms`가 가장 큰 경우에만 recorder에 별도 frame-subsystem API를
  추가한다.
- [ ] actor body visibility와 telegraph-view intersection을 별도 계측하고,
  가장 큰 쪽의 중복 준비 작업만 제거한다.
- [ ] visible telegraph와 화면 밖 actor가 화면 안으로 쏘는 telegraph fixture를
  추가한 뒤 capacity 3회에 Retention Rule을 적용한다.
- [ ] physics 또는 presentation 후보를 모두 소진해도 capacity가 실패하면
  workload·threshold를 바꾸지 않고 측정 결과와 다음 구조 선택지를 사용자에게
  제시한다.

Exit: capacity frame/physics gate 통과 또는 추가 권한이 필요한 정확한
blocking evidence가 있다.

### Phase 3 — Release qualification과 asset gate 해제

- [ ] native `production_replay`, `peak_horde`, `capacity_pressure`,
  `boss_pressure`를 모두 통과한다.
- [ ] production Web export의 visible/focused tab에서 같은 네 scenario를
  모두 통과한다.
- [ ] native `lifecycle_pressure`를 10초 warmup + 600초 measurement로
  실행해 frame/physics와 memory gate를 통과한다.
- [ ] 전체 `validate_vehicle_*.gd`, import, Web export와 built-Web
  interaction smoke를 통과한다.
- [ ] acceptance evidence에 환경, commit, dirty state, raw result와 최종
  판정을 append한다.
- [ ] durable behavior 변경이 있으면 product spec에 반영하고, 완료된 계획은
  active tree에서 삭제한다.

Exit: 모든 release threshold가 `passed=true`이고 asset 작업을 시작할 수 있다.

## Test Plan / Validation Cadence

### Focused validators

```powershell
$checks = @(
  "validate_vehicle_pickup_contact.gd",
  "validate_vehicle_upgrade_ui.gd",
  "validate_vehicle_stage_ui_layout.gd",
  "validate_vehicle_boss_exams.gd",
  "validate_vehicle_run_capture_driver.gd",
  "validate_vehicle_enemy_update_schedule.gd",
  "validate_vehicle_spatial_grid.gd",
  "validate_vehicle_primary_weapon.gd",
  "validate_vehicle_combat_renderer.gd",
  "validate_vehicle_performance_scenarios.gd",
  "validate_vehicle_run.gd"
)
foreach ($check in $checks) {
  ./tools/godot.ps1 --path . --headless --script "res://tools/validation/$check"
  if ($LASTEXITCODE -ne 0) { throw "Validation failed: $check" }
}
./tools/validation/validate_document_authority.ps1
```

### Authoritative capacity sample

Godot window를 1280×720, visible/focused 상태로 유지한다.
각 비교 batch에서 `$label`을 `baseline`, `instrumented`,
`owner-before`, `owner-after`처럼 바꿔 raw JSON을 덮어쓰지 않는다.

```powershell
$env:PERFORMANCE_COMMIT = (git rev-parse HEAD)
$env:PERFORMANCE_DIRTY = if (git status --porcelain) { "1" } else { "0" }
$label = "baseline"
1..3 | ForEach-Object {
  $output = "res://build/performance/pre-asset/native/$label-capacity-$_.json"
  ./tools/godot.ps1 --path . --rendering-method gl_compatibility --resolution 1280x720 -- `
    --performance-scenario=capacity_pressure `
    --performance-warmup=10 `
    --performance-duration=60 `
    --performance-output=$output
  if ($LASTEXITCODE -ne 0) { throw "Capacity run failed: $_" }
}
Remove-Item Env:PERFORMANCE_COMMIT, Env:PERFORMANCE_DIRTY -ErrorAction SilentlyContinue
```

### Final gates

- 모든 `tools/validation/validate_vehicle_*.gd`.
- `./tools/validation/validate_document_authority.ps1`.
- `./tools/godot.ps1 --path . --headless --import`.
- `./tools/export_web.ps1`.
- Web server 시작 전 `$npjt-port-guard`를 적용하고 fastrun manager의
  `codex` lane만 사용.
- current parser의
  `?performance_scenario=capacity_pressure&performance_warmup=10&performance_duration=60`
  형식으로 built-Web를 실행.
- `window.__cardbornePerformanceResultJson`의 scenario, authoritative,
  validation, thresholds를 검사.
- 마지막으로 native lifecycle 600초를 실행.

고정 native 1280×720 gate:

- frame median 59 FPS 이상
- frame p95 18 ms 이하, p99 25 ms 이하
- 1% low 55 FPS 이상
- 33.3 ms 초과 연속 frame 1 이하
- capacity/lifecycle physics p95 6 ms 이하, p99 8 ms 이하
- lifecycle static memory growth 8 MiB 미만
- draw-call p95 200 이하, combat batch 50 이하

## Predetermined Error Handling and Contingencies

| Trigger | Required response |
| --- | --- |
| focus/visibility 또는 scenario validation 때문에 run이 invalid | 환경을 바로잡고 같은 build를 최대 3회 재실행 |
| 기능 validator 실패 | 성능 수치와 무관하게 해당 실험을 폐기 |
| target 개선이 run-to-run 분포 안에 머묾 | inconclusive로 기록하고 commit 전 task-owned diff 제거 |
| 관련 사용자 변경과 실험 diff가 겹침 | 자동 복구하지 않고 중단 후 사용자에게 보고 |
| 모든 후보 owner 뒤에도 capacity 실패 | raw evidence와 다음 구조 선택지를 제시하고 권한 요청 |

## Rollback / Safety

- 독립 최적화마다 task-owned commit을 분리한다.
- unrelated user change를 stage, revert 또는 정리하지 않는다.
- stable slot, generation, hit order, cadence 또는 gameplay composition이
  바뀌면 성능이 좋아도 변경을 폐기한다.
- raw JSON은 `build/performance/pre-asset/`에 두고 Git에는 요약 evidence만
  기록한다.
- hard reset, history rewrite, dependency 변경이나 threshold 완화는 하지 않는다.

## Risks

| Risk | Control |
| --- | --- |
| 계측 자체가 성능을 왜곡 | 7-tick detail stride 유지, recorder-off allocation guard |
| schedule 변경이 per-tick semantics를 누락 | 거리·timer·phase·commit fixture와 replay parity |
| grid swap-remove가 multi-cell reverse index를 깨뜨림 | swapped slot 갱신, retire/reuse validator |
| projectile 작업을 중복 구현 | 기존 buffer/cell-exit contract를 먼저 검증 |
| culling이 화면을 가로지르는 telegraph를 숨김 | body visibility와 telegraph intersection을 별도 검증 |
| 구조 정리가 새 catch-all을 만듦 | 기존 owner만 변경 |

## Open Questions

없음. 새 dependency/native code, workload 또는 threshold 변경이 필요하다는
증거가 생길 때만 사용자 결정을 요청한다.

## Decision Notes

- 2026-08-02: 기존 design/asset preparation 단계를 전부 제거했다.
- 2026-08-02: 7월 31일의 “asset/UI 뒤 performance” 순서는 8월 2일의
  “모든 코드 issue를 먼저 fix한 뒤 asset” 지시로 대체됐다.
- 2026-08-02: map generation은 명시적 보류를 유지한다.
- 2026-08-02: resolved issue는 회귀 gate로만 남기고 재구현하지 않는다.
- 2026-08-02: 구현 후보의 고정 순서를 폐기하고 fresh measurement 순으로
  처리한다.

## Progress

- [x] 7/31-8/2 root 세션 전수 추출과 비디자인 issue ledger.
- [x] 현재 코드, Git 이력, evidence와 focused validator로 해결 상태 재판정.
- [x] design/strategy/deferred 항목과 active defect 분리.
- [ ] Phase 0: fresh baseline과 비용 순위.
- [ ] Phase 1: physics owner 반복 개선.
- [ ] Phase 2: 필요한 경우 frame/presentation 개선.
- [ ] Phase 3: release qualification과 asset gate 해제.

## Next Steps

1. current HEAD의 capacity 3회 기준선을 만든다.
2. 계측상 가장 큰 owner 하나씩 수정하고 3회 비교한다.
3. native → Web → lifecycle → full regression 순으로 증거를 남긴다.

## Completion Criteria

- [ ] ledger의 유일한 미해결 defect인 군집 성능이 통과 증거를 가진다.
- [ ] capacity 3회와 native/Web release matrix가 통과한다.
- [ ] lifecycle 600초 frame/physics/memory gate가 통과한다.
- [ ] pickup, upgrade UI, boss, capture 동작이 회귀하지 않는다.
- [ ] workload, 품질, threshold와 gameplay behavior가 유지된다.
- [ ] acceptance evidence와 필요한 canonical spec이 갱신된다.
- [ ] 완료된 ExecPlan이 active tree에서 제거된다.

## Stop Conditions

Complete when: 모든 final gate가 통과하고 evidence가 기록돼 asset gate가
해제됐을 때.

Escalate only when: 측정된 후보를 모두 처리해도 capacity가 실패하고 다음
선택이 dependency/native code, gameplay workload 또는 threshold 변경일 때.

Do not stop when: 한 실험이 inconclusive이거나 한 run이 invalid일 때.
Retention Rule에 따라 폐기 또는 재측정하고 다음 owner를 진행한다.

## Handoff

```text
Goal:
  7/31 이후 남은 비디자인 defect인 고밀도 전투 성능을 asset 전에 해결한다.

Read:
  이 계획, vehicle_game_spec.md, semantic-v2-runtime-acceptance-evidence.md

Run:
  Phase 0 → Phase 1 → 필요 시 Phase 2 → Phase 3

Stop:
  native/Web/lifecycle threshold가 모두 passed=true일 때
```
