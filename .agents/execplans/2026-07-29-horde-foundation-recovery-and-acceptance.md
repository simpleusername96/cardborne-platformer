---
type: plan
status: active
owner: BK
created: 2026-07-29
last_reviewed: 2026-07-29
scope: Recover workload authority and make the 276-enemy peak and 320-actor capacity technically sustainable without reducing speed, density, visual scale, or combat fidelity
supersedes:
  - ./2026-07-29-continuous-multidirectional-horde-readability.md
  - ./2026-07-23-vehicle-performance-architecture-stabilization.md
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../continuous-horde-rollout-problem-analysis.md
  - ../continuous-horde-readability-evidence.md
  - ../vehicle-performance-stabilization-evidence.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/product/combat-growth-improvement-direction.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
---

# 대규모 적군 최대 부하 안정화 실행 계획

현재 코드는 276기 Hard peak, 320 hostile capacity, 다방향 spawn, 확대된 combat
footprint, 6 pickup + 8 crate와 Stage 1–4 연속 전환을 이미 구현했다. 그러나
performance fixture가 실제 production behavior와 다르고, 280기 maximum smoke는
frame gate를 실패한다. 이 계획은 여섯 phase에서 workload authority를 먼저 고치고,
simulation cadence와 presentation salience를 각각 한 번의 bounded batch로 개선한
뒤, objective production regression과 native/Web/lifecycle gate를 완료한다.

## Purpose

- Objective: 적 수·속도·크기·전투 규칙을 되돌리지 않고 276기 peak와 320 actor
  capacity를 정해진 frame, memory와 lifecycle budget 안에서 처리한다.
- Final artifact: production-aligned workload, frequency-shaped ordinary simulation,
  salience-budgeted retained renderer, focused regression coverage, authoritative
  native/Web/lifecycle evidence와 QA용 build/diagnostic package.
- Completion state: 모든 functional, workload, native/Web performance와 lifecycle
  gate가 통과하고, 주관적 재미를 판정하지 않는 bounded evidence가 저장된다.

## Pre-plan Evidence Already Verified

| Source or path | Verified fact | Decision affected | Freshness or recheck boundary |
| --- | --- | --- | --- |
| `../continuous-horde-rollout-problem-analysis.md` | 직전 단계의 20개 문제와 다섯 core reason이 source/code/rendered evidence에 연결돼 있다. | 전체 recovery 순서 | 관련 source owner가 바뀌면 재검토 |
| `scripts/performance/vehicle_performance_scenario.gd` | `current_pressure`는 production scheduler가 아닌 340px 시작 동심원 수동 fixture다. | scenario taxonomy와 shared fixture | Phase 1에서 대체 |
| `build/performance/2026-07-29-horde/smoke-current-cached.json` | 280 active, 240 visible, near-600 267, median 42.28 FPS, frame p95 64.84ms, physics p95 15.13ms, presentation p95 8.91ms다. | simulation·renderer가 모두 필요한 이유 | Phase 1 clean baseline으로 교체 |
| `scripts/vehicle/vehicle_run.gd::_update_enemies()` | budget/status/coordination/behavior full scan과 매-tick ordinary update가 있다. | frequency-shaped workset | 해당 함수 변경 시 recheck |
| `scripts/enemies/vehicle_enemy_specialist_runtime.gd` | rammer/carrier helper가 enemy array를 반복 scan한다. | precomputed counters | Phase 2에서 hot-path consumer 제거 |
| `scripts/presentation/vehicle_combat_renderer.gd` | 모든 channel을 한 번에 reset/rebuild/upload하며 maximum fixture에서 1,184 instances를 만든다. | channel cadence와 overlay budget | Phase 3에서 교체 |
| `scripts/vehicle/vehicle_run.gd::_capture_pressure_evidence()` | maximum-pressure capture가 performance workload와 다른 수동 grid를 사용한다. | shared peak fixture | Phase 1에서 교체 |
| `docs/product/vehicle_game_spec.md` | 276 peak, 320 capacity, speed 280, camera 1, 6+8 items, continuous Stage 1–4 flow가 현재 product contract다. | 변경 금지 항목 | owner가 product spec을 바꿀 때만 |
| `docs/design/UI_VISUAL_SYSTEM.md` | collision core와 presentation envelope가 분리돼 있고 color-only 구분이 금지된다. | readability guard | visual contract 변경 시 |
| `.agents/PLANS.md`와 lifecycle registry | cross-cutting work는 하나의 active ExecPlan과 valid frontmatter를 사용해야 한다. | plan authority 정리 | policy 변경 시 |

## Locked Decisions

| Topic | Final decision | Rationale / source |
| --- | --- | --- |
| Enemy quantity | Hard peak 276, capacity 320을 유지한다. | 최신 사용자 결정과 product spec |
| Player motion | base speed 280, dash, speed cards, camera zoom 1을 유지한다. | 사용자가 감속을 명시적으로 거부 |
| Visual scale | 현재 확대된 actor, pickup, XP, projectile envelope를 유지한다. | 크기를 줄이는 것은 visibility 요구를 되돌림 |
| Collision truth | actor/projectile collision radius를 presentation optimization에 사용하지 않는다. | visual system invariant |
| Workload taxonomy | `production_replay`, `peak_horde`, `capacity_pressure`, `lifecycle_pressure`, `boss_pressure` 다섯 scenario를 사용하고 `current_pressure`를 폐기한다. | 대표/최대/용량 질문 분리 |
| Scenario loads | peak은 276 ordinary + 140/72 player/hostile shots, capacity/lifecycle은 280 ordinary + 40 auxiliary + 240/120 shots, boss는 76 ordinary + 1 boss + 140/100 shots다. Production replay는 synthetic fill 없이 actual scheduler가 만든 수를 기록한다. | load class별 질문을 수치로 고정 |
| Fixture ownership | 새 test-only `VehiclePressureFixture`가 deterministic composition/placement를 소유하고 performance와 capture가 재사용한다. | parallel truth 제거 |
| Simulation cadence | boss·startup·active·status damage는 60 Hz, ordinary decision/support/cooldown은 10 Hz, near/far locomotion은 30/20 Hz다. | 현재 병목과 existing timing contract |
| Scheduling ownership | 새 `VehicleEnemyUpdateSchedule`은 cadence/workset/counter만 소유하고 attack/collision/damage policy는 `VehicleRun`에 남긴다. | chatty cross-script policy 분산 방지 |
| Presentation cadence | combat renderer는 현재 full retained sync를 유지한다. 60/30 Hz channel split은 세 가지 구현을 측정했으나 presentation/frame p95를 악화시켜 retention rule에 따라 제거했다. | 실패한 optimization을 architecture contract로 남기지 않음 |
| Salience budget | ordinary health bars 총 12, extra priority markers 총 8이다. Aim→committed→recently damaged/priority proximity 순으로 선택한다. | 109 health-bar pair와 overlay clutter 제거 |
| Never-hidden semantics | boss cues, committed attacks, mine danger areas, projectile collision cores와 aim brackets는 salience budget으로 생략하지 않는다. | fairness/readability invariant |
| Performance thresholds | 이전 native/Web/capacity/lifecycle threshold를 완화하지 않는다. | 숫자를 낮춰 완료 처리하는 것을 방지 |
| Optimization retention | 같은 fixture의 3 × 20초 focused sample에서 target subsystem p95가 최소 10% 개선되고 frame p95가 5% 넘게 악화되지 않을 때만 batch를 유지한다. | 5초 smoke 변동성 차단 |
| UI boundary | combat renderer와 maximum-pressure capture harness만 건드린다. 일반 HUD/menu/hangar/garage/transition layout·asset은 수정하지 않는다. | concurrent UI 작업 격리 |
| Broader fun systems | 보스 재설계, 집단 적 행동, hidden mastery, unlock, terrain chain, card evolution은 이번 plan에서 구현하지 않는다. | 안정화와 신규 gameplay scope 분리 |
| Subjective QA authority | 재미, 압박감, 성장 만족도와 최종 balance는 이 plan이 판정하거나 완료 조건으로 사용하지 않는다. | 해당 판단은 사용자의 별도 QA feedback 영역 |
| Dependency/engine | Godot 4.7.1 stable, GDScript, Compatibility renderer, 현재 dependency set을 유지한다. | repo operating model |

## Rejected Alternatives

| Alternative | Why it was viable | Why it was rejected |
| --- | --- | --- |
| 적 수·크기·해상도 축소 | 가장 빠르게 frame과 clutter를 줄인다. | 최신 사용자 계약과 몰이 성장 기반을 되돌린다. |
| fixture/capture만 수정 | 실제 플레이와 evidence를 다시 연결한다. | 이미 드러난 simulation/presentation 병목을 해결하지 않는다. |
| 현재 hot function에 cache만 추가 | 작은 diff로 일부 이득이 가능하다. | decision/motion 호출 빈도와 per-actor overlay 증가라는 core cause가 남는다. |
| full ECS/C#/thread/native rewrite | 장기 headroom이 클 수 있다. | 현재 evidence가 요구하는 범위보다 비용과 parity 위험이 크고 새 승인이 필요하다. |
| 새 per-enemy Node/NavigationAgent | behavior owner를 분리하기 쉽다. | 320 actor에서 SceneTree/agent overhead와 동기화 비용을 늘린다. |
| 모든 ordinary visual을 20 Hz 이하로 낮춤 | presentation 비용을 더 크게 줄인다. | 가까운 대규모 crowd의 움직임이 끊겨 보일 위험이 크다. 30 Hz가 existing locomotion과 맞는다. |

## Current State

Already true or landed:

- hostile store와 retained renderer capacity 320;
- Hard active caps `1/124/172/224/276`;
- stage authored reserve `520/660/816/1026/1260`;
- four-quadrant, minimum four-sector production spawn;
- ranged share 최대 15%, ranged/denial commit 최대 3/2;
- player speed 280과 camera zoom 1;
- enlarged combat-object presentation;
- stage당 loose pickup 6개, crate 8개, repair 총량 245;
- Stage 1–4 XP recall, full heal, no success modal, same-position transition;
- focused validators 40개와 Web export build 성공.

Remaining implementation:

- representative, maximum, capacity fixture separation;
- production-aligned maximum-pressure capture and workload telemetry;
- enemy cadence/workset refactor;
- renderer channel cadence and salience budget;
- objective production-workload regression;
- authoritative native/Web/lifecycle gates;
- one active plan and accurate durable docs.

## Scope

In scope:

- performance scenario IDs, setup, qualification and result terminology;
- shared pressure fixture used by performance and capture;
- maximum-pressure capture correctness;
- enemy update workset, cadence accumulators and hot counter reuse;
- retained renderer channel split and bounded semantic overlays;
- focused validators for cadence, fixture, renderer and unchanged gameplay contracts;
- one fixed Stage 5 Hard production-replay workload regression;
- one 1280×720 maximum-pressure capture for structural visual regression;
- native/Web performance matrix and lifecycle soak;
- README, product/evidence lifecycle reconciliation.

Out of scope:

- active cap, authored reserve, player/enemy speed, HP, damage, projectile speed,
  telegraph time, quota or XP curve rebalance;
- camera zoom, viewport, physics rate or render resolution reduction;
- actor/projectile collision changes;
- new enemy, weapon, skill, card, boss pattern, item, terrain mechanic or unlock;
- save schema, engine, language, shader architecture or production dependency change;
- general HUD/menu/garage/hangar redesign or pixel-art asset regeneration;
- external-model handoff or external research refresh.
- 재미, 압박감, 성장 만족도, 난이도 체감 또는 가독성 선호의 판정;
- Stage 1/3/5 × Easy/Normal/Hard 주관적 비교와 사용자 승인 대기;

Destructive or irreversible actions:

- None. Retired scenario ID와 maximum-pressure manual-grid producer는 internal code
  path이며 git history에서 복구할 수 있다.
- Historical plans/evidence are preserved; they are not deleted.

Exact actions requiring owner/user approval:

- None for the locked implementation and technical validation.
- Reducing accepted density, speed, visual scale, resolution or combat fidelity
  requires a new user decision and is not an automatic contingency.
- User QA feedback may create a later balance/gameplay task, but no response or
  approval is required to complete this technical stabilization plan.

## Architecture and Ownership

| Concern | Final owner | Interface or invariant | Existing owner to reuse or retire |
| --- | --- | --- | --- |
| Deterministic pressure fixture | `scripts/performance/vehicle_pressure_fixture.gd` / `VehiclePressureFixture` | Builds production-role, production-sector test states for one declared load; no thresholds or runtime shortcuts | Replaces `_walkable_ring_points()` and duplicated capture grid |
| Scenario lifecycle | `scripts/performance/vehicle_performance_scenario.gd` | Activates exactly one named scenario, drives fixed input, exposes qualification snapshot | Retire `current_pressure` |
| Threshold/result authority | `scripts/performance/vehicle_performance_recorder.gd` | Records authored/live/active/visible/near/committed and applies existing platform gates | Preserve existing percentile definitions |
| Encounter placement | `scripts/encounters/vehicle_spawn_allocator.gd` | Production anchor and sector policy remains sole placement rule | Fixture calls it; fixture does not copy its policy |
| Enemy storage | `scripts/enemies/vehicle_enemy_store.gd` | Pool, identity, acquire/release only | Do not add cadence or attack policy |
| Per-enemy cadence state | `scripts/enemies/vehicle_enemy_state.gd` | `decision_elapsed` and `motion_elapsed` follow the actor through swap retirement and reset on reuse | Extend fixed state shape |
| Enemy work schedule | `scripts/enemies/vehicle_enemy_update_schedule.gd` / `VehicleEnemyUpdateSchedule` | One bulk build per tick; owns worklists and rammer/carrier counters, not attacks/collision/damage | New focused boundary |
| Enemy rules/orchestration | `scripts/vehicle/vehicle_run.gd` | Executes critical, decision and motion lanes in deterministic order | Split existing `_update_ordinary_enemy()` responsibilities; do not move policy into UI/store |
| Retained combat presentation | `scripts/presentation/vehicle_combat_renderer.gd` | Owns critical/crowd batch channels and deterministic overlay selection | Replace global reset/rebuild sync |
| Maximum capture orchestration | `scripts/vehicle/vehicle_run.gd::_capture_pressure_evidence()` | Invokes the shared peak fixture and emits its fingerprint; no duplicate game rules | Retire only the stale pressure grid |
| Stage flow | `scripts/encounters/vehicle_stage_flow.gd` and current Run integration | Actual Stage 1 boss clear → XP/reward/heal/banner → Stage 2 spawn | No new parallel transition |
| Durable product truth | `docs/product/vehicle_game_spec.md`, `README.md` | Product behavior and measured technical limits are stated separately | Retire stale 48–72/3+5 README text |

## As-Is / To-Be Delta Map

| Concern | As-is | To-be | Acceptance check | Guard / leftover check |
| --- | --- | --- | --- | --- |
| Load naming | `current_pressure` mixes 280 maximum with “current” | five explicit scenarios | validator rejects old ID and verifies each load class | no `current_pressure` consumer remains |
| Peak placement | 240/280 visible, 267 within 600px | active 276, visible 120–160, near-900 200–240, every sector 24–45 | scenario qualification snapshot | no manual ring/grid constructor |
| Production representation | manual fill | actual Stage 5 Hard scheduler and fixed player route | `production_replay` has scheduler-originated IDs/events | no `_fill_enemies()` call in production replay |
| Maximum capture | one-sided pressure grid | same shared `peak_horde` descriptor and fingerprint | 1280×720 peak capture + debug snapshot | item/transition/report capture paths untouched |
| Ordinary update | every actor enters combined update each physics tick | critical 60, decision 10, near/far motion 30/20 | cadence parity validator | no decision delta lost on skipped ticks |
| Specialist counts | per-enemy full scans | one workset snapshot | rammer/carrier deterministic tests | no hot call to removed scan helpers |
| Renderer sync | all channels rebuild each presented physics serial | critical 60, crowd/XP/semantics 30 | renderer snapshot and animation capture | projectiles/telegraphs never drop to 30 |
| Health/priority overlays | up to every qualifying visible actor | health 12, extra marker 8 | renderer cap assertions | boss/attack/mine cues exempt |
| Production workload proof | cap assertions only | one Stage 5 Hard replay records actual scheduler occupancy and sector distribution | workload qualification passes | no balance value changed |
| Performance proof | 5-second non-authoritative smoke | clean 3×60s native/Web + 10m lifecycle | all existing thresholds pass | slowest run retained |
| Plan authority | two overlapping active plans | this plan only | lifecycle audit | old plans preserved as superseded |

## Tasks

### Phase 1: Workload authority와 최대 부하 baseline

Goal:

대표 production workload와 인위적인 최대/capacity workload를 분리하고, 이후
최적화 전후가 같은 부하를 측정하도록 만든다.

Source owners touched:

`scripts/performance/vehicle_pressure_fixture.gd`,
`scripts/performance/vehicle_performance_scenario.gd`,
`scripts/performance/vehicle_performance_recorder.gd`,
`scripts/vehicle/vehicle_run.gd` maximum-pressure capture method,
`tools/validation/validate_vehicle_performance_scenarios.gd`

- [x] **1.1 Create `VehiclePressureFixture` as the single deterministic test-load owner.**
  - As-is: performance and capture independently invent ring/grid positions and role lists.
  - To-be: fixture receives the live `VehicleSpawnAllocator`, selected field/stage layout,
    fixed seed `12886704`, requested load class and current production role definitions.
    It returns spawn descriptors only; it does not mutate `VehicleRun`, apply thresholds or
    bypass collision/attack.
  - Accept: the same peak descriptor fingerprint is reported by performance JSON and
    capture debug output.
  - Guard: fixture contains no copied sector percentage, attack commit or difficulty
    policy; those remain in production owners.

- [x] **1.2 Replace scenario taxonomy and setup.**
  - As-is: `current_pressure`, `capacity_pressure`, `lifecycle_pressure`,
    `boss_pressure`.
  - To-be:
    - `production_replay`: real Stage 5 Hard encounter runtime, fixed layout seed,
      held primary fire, closest-priority manual aim, player start 중심
      half-extent 640×360 rectangle의 east→south→west→north waypoint를 32px
      tolerance로 시계 방향 순회하며 corner 진입 때 한 번만 dash하는 route;
    - `peak_horde`: 276 active ordinary, 140 player shots, 72 hostile shots,
      production role mix and allocator-derived eight-sector placement;
    - `capacity_pressure`: 280 ordinary + 40 auxiliary, 240 player shots와
      120 hostile shots로 320 live pool과 projectile pool을 채우는 correctness load;
    - `lifecycle_pressure`: the capacity workload plus repeated retire/reuse;
    - `boss_pressure`: 76 production-mix ordinary + Stage 5 boss 1기,
      140 player shots와 boss reserve를 포함한 100 hostile shots.
  - Accept: `VALID_SCENARIOS` contains exactly the five names; every scenario reports
    load class, scheduler/fixture origin and qualification counts.
  - Guard: `production_replay` never calls `_fill_enemies()`; `current_pressure` is
    rejected rather than aliased.

- [x] **1.3 Lock peak-horde spatial qualification.**
  - As-is: 240 visible and 267 near-600 actors pass because only total count matters.
  - To-be: `peak_horde` requires active 276, visible 120–160, near-900 200–240,
    all four quadrants, all eight sectors, 24–45 actors per sector, ranged commits ≤3
    and denial commits ≤2.
  - Accept: fixed seed passes exactly; a fixture intentionally moved to one side or
    near-600 saturation fails.
  - Guard: bounds are not reused as production spawn policy; they qualify only the
    deterministic maximum fixture.

- [x] **1.4 Align only the maximum-pressure capture with the shared fixture.**
  - As-is: `03-maximum-pressure-xp.png` is a one-sided manual grid unrelated to the
    performance fixture.
  - To-be: maximum-pressure capture calls `VehiclePressureFixture` and saves
    `03-peak-horde.png` with the same descriptor fingerprint as `peak_horde`.
  - Accept: capture debug output and performance JSON report the same fingerprint,
    active/visible/near counts and sector histogram.
  - Guard: item, transition, report and general UI capture paths are not modified by
    this technical stabilization plan.

- [ ] **1.5 Produce the clean optimization baseline.**
  - As-is: 5-second samples vary widely and the last commit field is empty.
  - To-be: from the Phase 1 commit, run `production_replay`, `peak_horde` and
    `boss_pressure` three times with 5-second warmup + 20-second sample, foreground
    native 1280×720.
  - Accept: every payload contains the exact git commit, clean state, fixture
    fingerprint, full counts and focus qualification; preserve all three samples.
  - Guard: these are development baselines, not release authority.

Batch acceptance:

- New scenario validator passes.
- 1280×720 peak capture has the same workload fingerprint as the measured fixture
  and contains no duplicated actor body or one-sided manual-grid placement.
- Phase 1 baseline payloads are reproducible enough that median target-subsystem p95
  differs by no more than 15% across the three runs. If it exceeds 15%, fix
  qualification/focus/workload stability before optimizing.

Batch guard:

- No production gameplay value changes.
- No general UI/asset file changes.
- Commit Phase 1 separately before performance work.

### Phase 2: Frequency-shaped ordinary enemy simulation

Goal:

276 active ordinary를 유지하면서 실제로 60 Hz가 필요한 상태만 60 Hz에서 처리하고,
현재 `enemy_behavior_and_motion` 비용을 같은 peak fixture에서 줄인다.

Source owners touched:

`scripts/enemies/vehicle_enemy_state.gd`,
`scripts/enemies/vehicle_enemy_update_schedule.gd`,
`scripts/enemies/vehicle_enemy_specialist_runtime.gd`,
`scripts/vehicle/vehicle_run.gd`,
`tools/validation/validate_vehicle_enemy_update_schedule.gd`,
`tools/validation/validate_vehicle_enemy_store.gd`,
existing combat/encounter validators

- [x] **2.1 Add actor-owned cadence accumulators.**
  - As-is: skipped movement multiplies current frame delta, while decision/cooldown
    logic still enters every physics tick.
  - To-be: `VehicleEnemyState` owns `decision_elapsed` and `motion_elapsed`; both
    reset in `reset_runtime_collections()` and therefore follow the actor across
    store swap retirement.
  - Accept: acquire→update→retire→reuse starts both values at zero; no elapsed time is
    inherited by another actor.
  - Guard: runtime-slot index is never used as persistent cadence identity.

- [x] **2.2 Add `VehicleEnemyUpdateSchedule`.**
  - As-is: `VehicleRun` repeatedly scans enemies and role helpers rescan the array.
  - To-be: one bulk `rebuild()` per physics tick produces reusable arrays for active,
    timer/status, boss/special, critical ordinary, decision-due, near-motion-due,
    far-motion-due and shield-support actors. It also snapshots active-cap count,
    committed threat/ranged/denial, committed rammer global/by-squad and carrier
    child counts.
  - Accept: fixed 320-state fixtures produce deterministic worklist order and exact
    counters; arrays are cleared and reused without unbounded growth.
  - Guard: schedule never calls damage, collision, attack-start, spawn or rendering.

- [x] **2.3 Split the combined ordinary update into three lanes.**
  - As-is: `_update_ordinary_enemy()` handles phase timing, support/role decisions,
    cooldown, commit and locomotion every physics tick.
  - To-be:
    - `_update_enemy_critical_state(enemy, delta)` handles startup, active,
      interrupted recovery, armed mine fuse and hit timing at 60 Hz;
    - `_update_enemy_decision(enemy, accumulated_delta, can_commit, context)` handles
      cooldown, recovery transition, target/support refresh and attack commit at
      10 Hz;
    - `_update_enemy_locomotion(enemy, accumulated_delta)` performs exact existing
      collision movement at near 30 Hz or far 20 Hz.
  - Accept: existing attack startup/active duration differs by at most one physics
    tick; noncritical commit may be delayed by at most 100ms; 1-second movement
    displacement stays within 2px of the existing path in obstacle-free fixtures.
  - Guard: boss update, committed charge/beam/projectile timing, collision geometry
    and damage values remain unchanged.

- [x] **2.4 Replace hot repeated specialist scans with schedule counters.**
  - As-is: `rammer_can_commit()` and `living_children()` can scan all enemies for
    every relevant actor.
  - To-be: `VehicleRun` reads the schedule snapshot for rammer global/squad and
    carrier child count, updating the local tick context when an attack or child
    spawn changes it. Delete the old scan helpers after all hot consumers move.
  - Accept: rammer global cap 2, squad cap 1 and carrier child cap 3 pass deterministic
    interleaving tests.
  - Guard: repair target selection continues to use the spatial-grid nearby result
    and exact line of sight.

- [x] **2.5 Reuse schedule worklists for coordination.**
  - As-is: squad/shield support collection performs separate scans.
  - To-be: existing 10 Hz coordination reads the schedule's active/support lists;
    spatial queries and exact support range checks remain unchanged.
  - Accept: shield assignment fingerprints match the pre-refactor result for fixed
    fixtures.
  - Guard: support effects are not visually or numerically reduced.

- [ ] **2.6 Measure the batch under the Phase 1 fixture.**
  - As-is: peak `enemy_behavior_and_motion` p95 is 7.39ms in the last short sample,
    but the Phase 1 baseline is the comparison authority.
  - To-be: run the same 3 × 20-second `peak_horde` and `production_replay` baseline
    protocol.
  - Accept: median `enemy_behavior_and_motion` p95 improves at least 10%, scenario
    counts remain exact, frame p95 is not more than 5% worse, and no parity validator
    fails.
  - Guard: if the retention rule fails, remove only this batch's implementation and
    keep the Phase 1 measurement/capture corrections.

Batch acceptance:

- New cadence validator and all existing enemy, combat, stage, boss and encounter
  validators pass.
- Required performance retention rule passes on both peak and production replay.
- Source review confirms `VehicleEnemyUpdateSchedule` owns only cadence/workset state.

Batch guard:

- No active-cap, speed, collision, attack, health, damage or spawn-rule change.
- No new full-array scan is added inside a per-enemy function.
- Commit Phase 2 separately.

### Phase 3: Salience-budgeted retained combat presentation

Goal:

큰 actor와 276기 crowd를 유지하되 combat-critical visual만 60 Hz로 갱신하고,
health/priority overlay가 actor 수만큼 증식하지 않게 한다.

Source owners touched:

`scripts/presentation/vehicle_combat_renderer.gd`,
`scripts/vehicle/vehicle_run.gd` renderer call site,
`tools/validation/validate_vehicle_combat_renderer.gd`,
`docs/design/UI_VISUAL_SYSTEM.md`

- [x] **3.1 Evaluate explicit retained cadence channels; remove the failed experiment.**
  - As-is: one `sync()` resets, writes and uploads every batch.
  - To-be: each `BatchHandle` belongs to `critical` or `crowd`; resetting/uploading
    one channel leaves the other channel's visible instances intact.
  - Accept: debug snapshot reports per-channel batch and upload counts.
  - Guard: fixed capacity and retained MultiMesh ownership remain; no per-entity Node
    or per-frame mesh allocation.
  - Outcome: three channel partitions increased presentation p95 to
    `10.82–13.85ms`; all channel code and duplicate batches were removed.

- [x] **3.2 Evaluate split ordinary body presentation; remove the failed experiment.**
  - As-is: all mobile actors share one 60 Hz atlas batch.
  - To-be: boss, stationary combat-critical and startup/active ordinary bodies use
    critical 60 Hz batches; non-committed mobile crowd uses a 30 Hz atlas batch.
    Moving between lanes removes the actor from the old channel on that same critical
    sync.
  - Accept: a newly committed enemy enters the 60 Hz batch within one physics tick,
    and no actor is visible in both body channels.
  - Guard: player, projectiles, attack telegraphs, mine danger areas and boss remain
    60 Hz.
  - Outcome: the critical/crowd body split created more scan, sort and upload work
    than it saved on this renderer, so the original single body owner remains.

- [x] **3.3 Apply deterministic semantic budgets.**
  - As-is: maximum fixture may draw 109 ordinary health-bar pairs and a marker for
    every visible priority actor.
  - To-be:
    - ordinary health bars: total maximum 12, including aim target;
    - extra priority markers: total maximum 8;
    - ordering: aim target, startup/active committed actor, positive
      `health_visible_timer`, priority class, then distance and stable runtime ID.
  - Accept: 276-actor renderer fixture never exceeds caps and selecting/damaging a
    new nearer target deterministically replaces the last candidate.
  - Guard: boss health/cue, aim brackets, committed attack markers, mine danger rings
    and projectile collision cores are not counted in or hidden by these caps.

- [x] **3.4 Evaluate 30 Hz crowd/XP/ordinary semantics; remove the failed experiment.**
  - As-is: XP and ordinary overlays rebuild every presented physics serial.
  - To-be: crowd body, XP and ordinary health/status/shield semantics update every
    second physics serial using current state; short critical effects and attack/world
    damage overlays remain 60 Hz.
  - Accept: 60 FPS capture shows no duplicate/stale actor and 30 FPS slow-motion
    inspection shows a maximum one-frame channel age.
  - Guard: presentation cadence is independent of unrelated UI motion settings.
  - Outcome: the measured implementation failed the retention rule and was removed;
    all retained combat semantics continue to update through the existing sync.

- [x] **3.5 Measure and visually inspect the retained semantic-budget batch.**
  - As-is: last short maximum sample presentation p95 is 8.91ms and visible instances
    are 1,184.
  - To-be: run the Phase 1 3 × 20-second protocol and regenerate the shared
    `03-peak-horde.png` capture.
  - Accept: median presentation p95 improves at least 10%, frame p95 is not more than
    5% worse, health/marker caps hold, and no required cue is absent.
  - Guard: visual scale and collision core/envelope contract remain unchanged.
  - Outcome: the overlay budget reduced peak visible instances from `1,233` to
    `964–978`, but the three-sample frame retention gate did not pass. This is
    retained as a readability contract, not claimed as a release-performance win.

- [x] **3.6 Record the bounded-overlay contract in the visual system spec.**
  - As-is: the visual spec defines salience and collision truth but not a maximum
    ordinary health/priority overlay count.
  - To-be: document the 12 health-bar, 8 extra-marker budget, deterministic selection
    order and never-hidden cue list. Do not document the rejected channel split.
  - Accept: source constants, renderer validator and visual-system wording agree.
  - Guard: do not add general UI styling or asset-direction rules.

Batch acceptance:

- Renderer validator passes exact channel/cap/never-hidden contracts.
- Peak debug snapshot contains exactly one player presentation, bounded ordinary
  health/priority overlays, committed attack cues and hostile projectile cores with
  no duplicate body instance.
- Required performance retention rule passes.

Batch guard:

- Total retained combat batches ≤50 and draw-call p95 ≤200.
- Do not modify general HUD/menu/hangar/garage layout or pixel asset recipes.
- Commit Phase 3 separately.

### Phase 4: Objective production regression과 QA package

Goal:

maximum fixture만 빠르게 만든 뒤 실제 scheduler 경로가 망가지는 것을 막고, 사용자가
원할 때 직접 QA할 수 있는 build와 객관적 진단값을 제공한다. 재미나 압박감은
판정하지 않는다.

Source owners touched:

`scripts/performance/vehicle_performance_recorder.gd`,
`scripts/performance/vehicle_performance_scenario.gd`,
`tools/validation/validate_vehicle_performance_scenarios.gd`,
`.agents/continuous-horde-readability-evidence.md`

- [x] **4.1 Qualify one fixed Stage 5 Hard production replay.**
  - As-is: active cap assertions은 있지만 actual scheduler workload와 maximum fixture가
    분리되지 않았다.
  - To-be: seed `12886704`, locked primary/build/input route와 Stage 5 highest-cap
    beat에서 authored reserve, live, active ordinary, visible ordinary, near-900,
    sector histogram, spawn rate, ranged/denial commits와 projectile counts를
    1초마다 기록한다.
  - Accept:
    - measurement window의 rolling 10-second median active ordinary가 Hard cap의
      최소 90%다;
    - spawn이 네 사분면과 최소 네 sector를 사용하고 한 sector가 35%를 넘지 않는다;
    - ranged commit ≤3, denial commit ≤2;
    - 모든 actor와 projectile count가 capacity 안에 있고 rejected capacity가 0이다.
  - Guard: 이 값은 workload qualification이며 재미, 난이도 또는 적정 밀도 판정으로
    서술하지 않는다.

- [x] **4.2 Run unchanged gameplay-contract regressions.**
  - As-is: simulation/renderer hot path를 바꾸면 stage, boss, projectile, status,
    transition과 item behavior가 간접적으로 회귀할 수 있다.
  - To-be: 기존 focused validator를 변경 없이 통과시킨다. 새 gameplay behavior,
    capture matrix 또는 balance metric을 추가하지 않는다.
  - Accept: stage flow, boss, spawn allocation, projectile, experience, item,
    upgrade와 transition validator가 모두 0으로 종료한다.
  - Guard: validator 통과를 재미나 시각적 선호의 증거로 표현하지 않는다.

- [x] **4.3 Produce a bounded QA package without an approval gate.**
  - As-is: 사용자가 실제 실행 상태를 확인할 때 workload와 frame 정보를 한 번에
    볼 수 있는 bounded handoff가 없다.
  - To-be: ignored
    `build/evidence/horde-recovery/qa-package/README.md` manifest에 production Web
    `build/web/index.html`, `03-peak-horde.png`, `production_replay-summary.json`,
    `peak_horde-summary.json`, exact 실행 명령과 overlay glossary 경로를 기록한다.
  - Accept: package에서 authored reserve, live, active, visible, near-900,
    committed와 frame-time을 구분해 읽을 수 있다.
  - Guard: 사용자의 실행, 응답, 재미 판정 또는 승인은 이 phase와 plan 완료 조건이
    아니다. 이후 feedback은 별도 balance/gameplay task의 입력이다.

Batch acceptance:

- Fixed Stage 5 Hard production workload qualification passes.
- Existing gameplay-contract validators pass without changing product values.
- QA package contains the built artifact, one peak capture and objective diagnostics.

Batch guard:

- No difficulty rebalance, new UI surface, subjective scoring or gameplay claim.
- New gameplay ideas remain outside this plan.

### Phase 5: Authoritative native/Web/lifecycle gates

Goal:

한 clean commit에서 실제 배포 경로까지 기존 threshold를 통과하고, 가장 느린 표본도
보존한다.

Source owners touched:

No product source is expected. Only a failing targeted owner may be changed within the
locked Phase 2/3 architecture. Generated JSON/Web output stays ignored. The bounded
summary updates `.agents/continuous-horde-readability-evidence.md`.

- [x] **5.1 Run all focused validators and import.**
  - Accept: every `tools/validation/validate_*.gd` exits 0 and Godot import has no
    script parse/resource error.
  - Guard: a failing validator is rerun only after its suspected cause changes.

- [x] **5.2 Build the production Web export.**
  - Accept: `.\tools\export_web.ps1` creates all required non-empty artifacts.
  - Guard: export success is build evidence only, not runtime-performance evidence.

- [ ] **5.3 Run authoritative native matrix from one clean commit.**
  - To-be: `production_replay`, `peak_horde`, `boss_pressure`, three runs each:
    - native 1280×720;
    - native 2560×1600.
  - Accept:
    - 10s warmup + 60s sample;
    - continuous foreground/focus and unthrottled scheduler;
    - 1280×720 median ≥59 FPS, 1% low ≥55, frame p95 ≤18ms, p99 ≤25ms,
      no two consecutive frames >33.3ms;
    - 2560×1600 median ≥58 FPS, 1% low ≥50, p95 ≤20ms, p99 ≤33.3ms;
    - every run passes; slowest is retained.
  - Guard: do not average away a failed run.

- [ ] **5.4 Run authoritative production Web matrix.**
  - To-be: use the production export in foreground Chrome at 1280×720 for the same
    three scenarios, three runs each.
  - Accept: median ≥58 FPS, 1% low ≥50, p95 ≤20ms, p99 ≤33.3ms, no three
    consecutive frames >33.3ms; no console error.
  - Guard: before starting a server under `D:\npjt`, load `$npjt-port-guard` and use
    the registered fastrun-manager `codex` lane. Native evidence cannot substitute.

- [ ] **5.5 Run capacity and lifecycle integrity.**
  - To-be:
    - `capacity_pressure`: simulation p95 ≤6ms, p99 ≤8ms;
    - `lifecycle_pressure`: 10s warmup + 600s sample.
  - Accept: memory growth <8MiB, zero stale resolvable ID, zero cap growth, every
    actor/projectile/shard count within fixed capacity and repeated retire/reuse
    continues.
  - Guard: capacity/lifecycle timing is not described as representative gameplay FPS.

- [x] **5.6 Apply the bounded failure rule.**
  - If one target fails, record the dominant subsystem and exact scenario.
  - A correction may change only the already selected schedule/channel/overlay
    implementation and must pass the same 3×20-second retention rule before the
    full gate is rerun.
  - After one such correction, a repeated failure stops implementation and is
    reported. It does not trigger density/speed/resolution reduction or an automatic
    engine rewrite.

Batch acceptance:

- Every required sample is authoritative and passes.
- Capacity/lifecycle integrity passes.
- Production Web was actually run, not merely exported.

Batch guard:

- One clean commit and exact environment metadata in every payload.
- No sample deletion; no threshold relaxation.

### Phase 6: Durable reconciliation and completion

Goal:

측정으로 확인된 기술 결과만 canonical docs에 남기고 plan/evidence authority를
한 개로 정리한다.

Source owners touched:

`README.md`,
`docs/product/vehicle_game_spec.md`,
`docs/design/UI_VISUAL_SYSTEM.md`,
`.agents/continuous-horde-readability-evidence.md`,
this plan and related lifecycle frontmatter

- [ ] **6.1 Reconcile product and README wording.**
  - As-is: product behavior is current but measured limits are easy to miss; root
    README previously carried stale 48–72/3+5 language.
  - To-be: describe authored reserve, active caps, item count, continuous transition
    and measured performance using the canonical glossary.
  - Accept: no stale current-pressure scenario or prior count remains in current
    reader-facing docs.
  - Guard: historical audits/plans retain historical numbers when clearly labeled.

- [x] **6.2 Finalize bounded evidence.**
  - To-be: update implementation evidence with commit, environment, fixed production
    workload qualification, peak capture path, all individual native/Web runs,
    lifecycle result와 limitations.
  - Accept: claims can be traced to payload or capture and no non-authoritative smoke
    is presented as release proof.
  - Guard: generated JSON and Web build remain ignored; only bounded summaries are
    committed.

- [ ] **6.3 Close lifecycle after technical completion.**
  - To-be: mark this plan complete after every objective checkbox passes; archive
    evidence when it becomes historical according to lifecycle rules.
  - Accept: only one active maximum-load stabilization plan exists.
  - Guard: do not delete historical plan/evidence without explicit user approval,
    even though `PLANS.md` normally retires completed plans.

Batch acceptance:

- `git diff --check` and lifecycle audit pass.
- Task-scoped quality audit finds no competing owner or stale contract.
- Final commit contains only task-owned docs/evidence reconciliation.

Batch guard:

- No claim broader than declared workload, preserved behavior and measured performance.

## Validation Cadence

### Inner-loop commands

```powershell
.\tools\godot.ps1 --path . --headless --import
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_performance_scenarios.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_enemy_update_schedule.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_combat_renderer.gd
.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_transition.gd
```

The schedule validator does not exist before Phase 2. Run only validators owned by the
current completed phase.

Development performance command shape:

```powershell
$output = Join-Path (Resolve-Path .).Path "build\performance\recovery\peak-horde-01.json"
$godotArgs = @(
  "--rendering-method", "gl_compatibility", "--",
  "--performance-scenario=peak_horde",
  "--performance-output=$output",
  "--performance-warmup=5",
  "--performance-duration=20"
)
.\tools\godot.ps1 @godotArgs
```

Capture command shape:

```powershell
$captureDir = Join-Path (Resolve-Path .).Path "build\evidence\horde-recovery"
$godotArgs = @(
  "--rendering-method", "gl_compatibility", "--",
  "--capture-all=$captureDir",
  "--capture-locale=ko",
  "--capture-size=1280x720",
  "--layout-seed=12886704"
)
.\tools\godot.ps1 @godotArgs
```

### Batch gates

- Phase 1: scenario validator, corrected peak capture, 3× baseline.
- Phase 2: schedule/enemy/combat validators, fixed-state parity, 3× retention rule.
- Phase 3: renderer validator, peak structural capture, 3× retention rule.
- Phase 4: fixed production workload qualification, unchanged gameplay regressions,
  bounded QA package.
- Phase 5: full functional suite, Web export, authoritative matrix, lifecycle soak.
- Phase 6: documentation lifecycle, diff check, task-scoped quality audit.

### Final gates

Full import and validators:

```powershell
.\tools\godot.ps1 --path . --headless --import
$validators = Get-ChildItem tools/validation -Filter 'validate_*.gd' | Sort-Object Name
foreach ($validator in $validators) {
  .\tools\godot.ps1 --path . --headless `
    --script ("res://tools/validation/" + $validator.Name)
  if ($LASTEXITCODE -ne 0) { throw "Validation failed: $($validator.Name)" }
}
```

Production build:

```powershell
.\tools\export_web.ps1
```

Production start:

- Load `$npjt-port-guard`.
- Resolve the fastrun-manager `codex` lane for this repository and reuse its assigned
  port.
- Serve only the built `build/web` output.
- The port is intentionally resolved at execution time; no fixed ad-hoc port is
  permitted by repository policy.

Rendered/runtime routes:

- Native and built Web `peak_horde` at 1280×720 for workload and duplicate/stale
  instance inspection.
- Native and built Web `production_replay` at 1280×720 for actual scheduler-path
  qualification.
- Native `peak_horde` at 2560×1600 for the declared performance matrix.

Documentation and lifecycle:

```powershell
python C:\Users\BK\.codex\skills\doc-lifecycle-steward\scripts\audit_docs.py `
  .agents\continuous-horde-rollout-problem-analysis.md `
  .agents\execplans\2026-07-29-horde-foundation-recovery-and-acceptance.md `
  .agents\continuous-horde-readability-evidence.md `
  .agents\vehicle-performance-stabilization-evidence.md
git diff --check
```

### Rerun policy

- 실패한 narrow check는 concrete change나 새 hypothesis 뒤에만 다시 실행한다.
- Full validator suite와 authoritative matrix는 suspected cause가 바뀐 뒤에만 반복한다.
- 같은 optimization batch를 유지할지 판단할 때 3개 sample을 전부 보존한다.
- 5초 smoke는 count/boot 확인에만 쓰고 optimization 선택이나 완료 claim에 쓰지 않는다.

## Predetermined Error Handling and Contingencies

| Trigger | Required response | Limit / escalation point |
| --- | --- | --- |
| Shared fixture cannot meet peak spatial qualification | Production allocator를 통해 descriptor selection을 조정하고 fixed seed validator를 다시 통과시킨다. | Production spawn percentages를 fixture 때문에 바꾸지 않는다. |
| Production replay does not reach a useful measured pressure window | Stage 5 highest-cap beat에서 measurement window를 시작하도록 scenario timing을 고친다. | 적을 수동 fill하지 않는다. |
| Schedule parity fails | accumulator consume/reset 또는 lane ordering을 고치고 parity fixture를 통과시킨다. | attack/collision rule 변경이 필요하면 중단한다. |
| Phase 2 retention rule fails | Phase 2 task-owned 변경을 제거하고 Phase 1 authority만 보존한다. | 다른 architecture를 자동 선택하지 않는다. |
| Critical visual becomes stale/duplicate | actor channel migration을 same-sync remove/add로 고친다. | critical cadence를 30 Hz로 낮추지 않는다. |
| Phase 3 retention rule fails | renderer channel과 health/marker budget 변경을 함께 제거하고 Phase 2 상태의 exact metrics를 보고한다. | 새로운 shader/engine path로 넘어가지 않는다. |
| Web focus/scheduler qualification fails | sample을 failed evidence로 보존하고 foreground activation/runner를 고친다. | native result로 대체하지 않는다. |
| One final performance target fails | dominant subsystem 안에서 schedule/channel implementation correction을 한 번 수행하고 full gate를 다시 실행한다. | 두 번째 실패 시 정확한 수치와 함께 중단한다. |
| Density/speed/resolution 감소가 필요해 보임 | 변경하지 않고 user decision을 요청한다. | 자동 fallback 금지 |
| Concurrent UI owner와 파일 충돌 | 일반 UI file 변경을 중단하고 combat-renderer/capture 경계 안에서 우회한다. 우회가 불가능하면 owner coordination을 요청한다. | unrelated UI 변경을 stage/revert하지 않는다. |
| Save/dependency/engine migration 필요 | 작업을 중단하고 별도 승인 요청 | 이번 plan authority 밖 |

## Rollback and Safety

- Phase 1 fixture/evidence, Phase 2 simulation, Phase 3 renderer, Phase 4
  regression/QA package, Phase 5 evidence를 각각 coherent commit으로 만든다.
- unrelated user/concurrent UI changes를 stage, amend, revert하지 않는다.
- `git reset --hard`, force push, broad clean을 사용하지 않는다.
- experiment가 retention rule을 실패하면 해당 phase에서 만든 task-owned edit만
  명시적으로 되돌리고 validation을 다시 실행한다.
- generated capture, performance JSON과 Web output은 ignored 경로에 둔다.
- no dependency installation, save migration, scene format migration or destructive
  data operation is authorized.

## Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| 10 Hz decision이 공격 반응을 둔하게 만든다 | commit만 최대 100ms quantization을 허용하고 startup/active/hit timing은 60 Hz parity로 잠근다. |
| 30/20 Hz movement가 충돌 결과를 바꾼다 | 누적 delta, exact existing collision geometry, obstacle-free displacement와 cover-path fixture를 함께 검사한다. |
| workset boundary가 또 다른 catch-all이 된다 | cadence/list/counter만 소유하고 attack/damage/spawn/render API를 금지한다. |
| actor channel 전환에서 한 frame 사라지거나 중복된다 | committed state 변경 frame에 critical channel을 우선 sync하고 old crowd instance를 같은 sync에 제거한다. |
| overlay cap이 중요한 상태를 숨긴다 | aim, committed, recent damage 우선순위와 never-hidden boss/attack/mine/projectile 목록을 validator로 고정한다. |
| representative replay가 bot route에 과적합된다 | production scheduler/allocator/attack/collision은 그대로 사용하고 peak/boss scenario를 별도 gate로 유지한다. |
| clean sample도 laptop scheduler에 흔들린다 | foreground/focus/scheduler qualification, 세 표본 전부 보존, 15% baseline stability gate를 먼저 통과한다. |
| full matrix가 다시 장시간 blind tuning으로 변한다 | 두 runtime batch와 final correction 1회만 허용하고 그 뒤에는 exact failure로 중단한다. |
| 276기에서 semantic overlay 수가 다시 actor 수에 비례한다 | health/priority cap과 renderer validator를 고정하고 never-hidden cue만 별도로 유지한다. |

## Assumptions

실행을 바꿀 material assumption은 없다. 다음은 이미 확인된 현재 contract다.

- Godot 4.7.1 stable과 Compatibility renderer를 사용한다.
- current product behavior는 `docs/product/vehicle_game_spec.md`가 authority다.
- generated build/evidence 경로는 ignored다.
- user/concurrent UI session의 일반 UI 변경은 이번 plan 소유가 아니다.

이 contract가 다른 owner commit에서 바뀌면 구현 전에 해당 phase만 rebase/reinspect하고,
사용자-visible behavior를 바꾸는 충돌은 임의로 해석하지 않는다.

## Open Questions

None. Product quantity, movement, visual, architecture, cadence, fixture, threshold,
UI boundary, contingency와 technical completion decision은 모두 잠겼다. 구현 중 발견되는
local defect는 이 경계 안에서 고치며, 경계를 바꾸는 발견만 Stop Conditions에 따라
escalate한다.

## Decision Notes

- 먼저 정확한 fixture를 만드는 이유는 느린 수치를 숨기기 위해서가 아니라,
  production과 capacity stress를 서로 다른 질문으로 만들기 위해서다.
- simulation과 renderer를 한 commit에서 동시에 고치지 않는다. 동일 fixture에서
  어느 변화가 어떤 subsystem을 개선했는지 보존해야 한다.
- `VehicleRun`에서 모든 enemy policy를 추출하지 않는다. 직전 performance plan에서
  chatty hot-state runtime extraction은 오히려 p95를 악화시킨 전례가 있다.
- workset은 deep scheduling boundary이고, store는 계속 storage boundary다.
- actor 크기를 유지하면서 overlay 수를 줄이는 것은 visibility 요구를 되돌리는 것이
  아니다. silhouette와 projectile core는 보존하고 중복 semantic ornament만 제한한다.
- `production_replay`는 actual scheduler workload, `peak_horde`는 최대 몰이,
  `capacity/lifecycle`은 integrity를 각각 말한다. 어떤 하나도 다른 둘의 결론을
  대신하지 않는다.
- 재미, 난이도 체감과 성장 만족도는 이 plan의 evidence나 완료 조건이 아니다.
  QA feedback이 들어오면 별도 gameplay/balance task로 다룬다.

## Progress

- [x] Prior session intent, six rollout commits, current docs and source owners inspected.
- [x] Current performance payloads and rendered captures inspected.
- [x] Problems classified and mapped to five core reasons.
- [x] Five materially different solution alternatives compared.
- [x] Final hybrid solution and all execution decisions locked.
- [x] Phase 1 workload authority, shared capture and diagnostic baseline landed.
  The planned three clean baselines were not all produced, so release authority
  is not claimed.
- [x] Phase 2 frequency-shaped enemy simulation and aggregate counters landed;
  behavior p95 improved, while the complete frame retention gate remains open.
- [x] Phase 3 semantic overlay budget landed. All failed cadence-channel variants
  were removed; the three-sample frame retention gate remains open.
- [x] Phase 4 production peak qualification, unchanged regressions and ignored QA
  package completed.
- [ ] Phase 5: import, 43 validators, Web export and built runtime smoke pass;
  native/Web authoritative timing and lifecycle gates remain blocked by measured
  peak/capacity timing failure.
- [ ] Phase 6: evidence is reconciled, but lifecycle completion waits for Phase 5.

## Next Steps

1. Profile one next architecture batch against the existing fixed peak/capacity
   payloads. Do not restore the rejected renderer channel split.
2. Keep the batch only if all three focused peak samples satisfy the existing
   subsystem and frame retention rule and capacity physics approaches the 6/8ms
   gate without changing density, speed, scale, collision or gameplay values.
3. Only after the timing gate is credible, run the complete native/Web 60-second
   matrix and 600-second lifecycle soak from one clean commit.
4. Mark this plan `done` only when those objective gates pass; subjective fun and
   balance remain a separate user-QA task.

## Completion Criteria

- [x] `current_pressure` and duplicated manual ring/grid fixtures are gone.
- [x] Performance and capture use the same peak fixture fingerprint.
- [x] `production_replay` uses the actual Stage 5 Hard scheduler and production input path.
- [x] `peak_horde` meets all active/visible/near/sector/commit qualification bounds.
- [x] Ordinary critical/decision/near/far lanes run at 60/10/30/20 Hz with parity.
- [x] No per-enemy hot helper rescans the full enemy array for rammer/carrier counts.
- [x] Failed 60/30 renderer channel experiments are removed rather than retained.
- [x] Ordinary health bars ≤12 and extra priority markers ≤8 while never-hidden cues remain.
- [x] Fixed Stage 5 Hard production replay passes occupancy, sector, commit and
  capacity qualification without synthetic enemy fill.
- [x] Existing stage, boss, projectile, experience, item, upgrade and transition
  validators pass without product-value changes.
- [x] QA package contains the production build, peak capture, workload summaries,
  run commands and glossary.
- [x] Every focused validator, Web export and production-style start passes.
- [ ] All individual native/Web authoritative samples and the lifecycle soak pass.
- [x] Durable docs use one glossary and one active authority; no invalid lifecycle status remains.
- [x] No density, speed, visual scale, resolution, collision, dependency or unrelated UI regression.

## Stop Conditions

Complete when:

- every objective completion criterion passes and bounded technical evidence is
  committed.

Escalate only when:

- preserving locked combat behavior prevents a parity or performance gate from passing;
- the one allowed final in-architecture correction still fails;
- a concurrent UI change makes the narrow combat renderer/capture integration impossible;
- save, dependency, engine, language or product-balance changes become necessary.

Do not stop when:

- one implementation detail is difficult;
- a narrow validator fails with a concrete in-scope cause;
- a single non-authoritative smoke is slow or noisy;
- cleanup remains inside the task-owned owner and does not change product scope.

## Handoff

```text
Goal:
Preserve 276-enemy density, 320 capacity, player speed 280, camera zoom 1 and
current visual scale while making the declared maximum workload technically
representative, bounded and performant.

Read first:
AGENTS.md
.agents/AGENTS.md
.agents/PLANS.md
.agents/continuous-horde-rollout-problem-analysis.md
.agents/execplans/2026-07-29-horde-foundation-recovery-and-acceptance.md
docs/product/vehicle_game_spec.md
docs/design/UI_VISUAL_SYSTEM.md

Execute exactly:
Begin at the first unchecked phase. Commit each phase separately. Do not combine
simulation and renderer optimization, and do not touch unrelated UI/assets.

Validate with:
The phase-local validators and 3×20-second retention protocol, followed by the
full validator suite, Web export, 3×60-second native/Web matrix and 10-minute
lifecycle soak.

Stop when:
All objective technical gates pass, or one declared escalation condition is reached.
Never manufacture a pass by reducing density, speed, scale, resolution or combat
fidelity. Do not wait for or claim subjective gameplay approval.
```
