---
type: plan
status: superseded
owner: BK
created: 2026-07-28
last_reviewed: 2026-07-29
scope: Concentrate the existing Stage 1 first surge into two readable horde fronts without changing UI, enemy totals, speed, or active caps
superseded_by: ./2026-07-29-continuous-multidirectional-horde-readability.md
related:
  - ../../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/product/combat-growth-improvement-direction.md
  - ../../docs/handoffs/combat-growth-horde-boss-2026-07-28/README.md
---

# Stage 1 호드 전선 밀도 실행 계획

> 2026-07-29 사용자 결정은 기존 27대 재배치가 아니라 실제 동시 적 수 2~3배
> 증가와 four-quadrant spawn을 요구한다. 이 문서는 더 이상 실행 권한이 없으며
> 후속 계획이 `horde_front` production path를 제거한다.

## Why / Context

현재 Stage 1의 첫 surge는 이미 27대를 예약하지만, 여덟 squad가 서로 다른
anchor와 네 개의 넓은 방향군으로 분산된다. authored population과 active cap
검증은 통과해도 플레이어가 한 번에 인식하고 쓸어버릴 수 있는 적의 밀도는
낮아질 수 있다. 따라서 이번 slice는 “적 수가 정말 부족한가”와 “같은 적이
너무 넓게 흩어져 적게 느껴지는가”를 분리한다.

외부 리뷰에서 제안된 적 속도, viewport, Arc 피해, burst XP, card, terrain,
boss 변경은 서로 다른 가설이다. 첫 구현에서는 이들을 섞지 않고, 기존 27대를
두 개의 실제 진입 전선으로만 재배치한다.

## Purpose

- Stage 1 첫 surge의 기존 27대를 12명과 15명인 두 horde front로 보이게 한다.
- authored population, role multiset, quota, active cap, enemy speed를 고정해
  공간적 응집 효과만 분리한다.
- A/B/C 구조 검증으로 현재 분산형 27대, production 응집형 27대, test-only
  36대 contingency를 비교 가능하게 남긴다.
- UI 작업 중인 다른 worktree와 충돌할 파일을 건드리지 않는다.

## Scope / Non-scope

In scope:

- Stage 1의 두 번째 packet에 명시적인 `horde_front` arrival policy 부여;
- spawn allocator의 Stage 1 전용 two-front allocation;
- encounter runtime의 front당 한 번인 arrival cue;
- Stage 1 및 기존 Stage 2–5 배치 계약의 focused validators;
- 현재 동작을 반영하는 product spec 수정.

Out of scope:

- `scripts/ui/`, `localization/`, `project.godot`, UI scene/theme/art;
- `scripts/vehicle/vehicle_run.gd`;
- authored enemy count, quota, active cap, enemy/player speed, viewport;
- enemy archetype, weapon, card, XP, terrain, boss, audio, save data;
- Stage 2–5의 기존 distributed arrival policy.

## Assumptions

- Stage 1 first surge는 packet index 1이며 squad 크기는
  `3,3,3,3,3,4,4,4`, 총 27대다.
- 같은 valid offscreen anchor를 공유한 squad들은 collision truth를 바꾸지
  않고 기존 squad cohesion과 role movement로 진입 후 퍼진다.
- 현재 active cap 62는 27대 surge를 queue spill 없이 수용할 수 있다.
- UI 작업은 별도 worktree에서 진행되며 현재 `master` worktree는 이
  gameplay slice 전용으로 유지한다.

## Pre-plan Evidence Already Verified

| Evidence | Verified fact | Consequence |
| --- | --- | --- |
| `vehicle_combat_stages.gd` | Stage 1 first surge는 8 squads, 27 units다. | 총량을 올리기 전에 배치 밀도부터 검증한다. |
| `vehicle_spawn_allocator.gd` | early beat는 2-squad groups 네 개, squad마다 별도 anchor, 최대 135도 arc다. | authored 27대가 넓게 분산되는 것이 현재 계약이다. |
| `validate_vehicle_spawn_allocation.gd` | 모든 stage에 8 unique anchors와 연속 wave 14개 이상을 요구한다. | validator도 분산 동작을 의도적으로 고정하고 있다. |
| `vehicle_encounter_runtime.gd` | squad마다 cue를 만들고 같은 group은 같은 시간에 예약한다. | front로 묶을 때 cue도 front당 한 번으로 합쳐야 한다. |
| baseline focused validators | pacing, allocation, enemy expansion이 모두 통과한다. | 이번 변경은 오류 복구가 아니라 명시적인 design contract 변경이다. |

## Locked Decisions

1. Production 선택은 **B: 기존 27대, 두 horde fronts**다.
2. Stage 1 packet index 1만 `arrival_mode = horde_front`를 갖는다.
3. squad 0–3은 front 0, squad 4–7은 front 1이다. authored squad와 role
   multiset은 그대로 유지한다.
4. 한 front의 네 squad는 한 validated anchor를 공유한다. front 0은 12대,
   front 1은 15대다.
5. 두 front anchor는 서로 달라야 한다. 두 번째 anchor는 플레이어 기준
   90도 이상 떨어진 방향을 우선하지만, 필드 가장자리에서도 공정한
   offscreen 진입을 유지하기 위해 다른 offscreen anchor로 결정적으로
   fallback할 수 있다.
6. Horde anchor tier는 ring/offscreen을 recent 다양성보다 우선한다:
   ring non-recent, ring recent, any-distance offscreen non-recent,
   any-distance offscreen recent, 마지막으로 기존 공정성 fallback 순서다.
7. recent-anchor memory에는 front anchor 두 개만 기록한다.
8. runtime은 front당 cue 한 번만 내보내되 squad별 spawn, squad identity,
   completion reward, formation data는 유지한다.
9. 각 front는 하나의 semantic anchor를 공유하되, 실제 unit spawn은
   그 anchor의 검증된 clearance 안에서 16-pixel fan을 사용한다. 같은
   front의 squad formation은 11도씩 phase를 달리해 정확히 포개지지 않는다.
10. A는 test에서 `arrival_mode`를 제거한 기존 27대 분산형이다.
11. C는 test에서만 각 squad에 총 9개의 `scrap_drone`을 추가한 36대
    contingency다. production data에는 반영하지 않는다.

## Rejected Alternatives

| Alternative | Reason |
| --- | --- |
| authored population 즉시 증가 | 공간 배치 가설과 총량 가설을 동시에 바꿔 원인 판별이 불가능하다. |
| 적 속도 증가 | 난이도와 회피 공정성을 함께 바꾸며 사용자가 제기한 단순 밀도 가설을 먼저 검증하지 못한다. |
| viewport 축소 | UI/카메라 작업과 충돌하고 실제 개체 밀도를 바꾸지 않는다. |
| Stage 1의 8개 anchor를 90도 wedge 두 개에만 배치 | 방향은 모이지만 한 화면에서 12–15대의 실제 단일 전선이 되지 않으며 edge feasibility가 더 복잡하다. |
| 모든 stage를 즉시 horde mode로 전환 | later-stage ranged/denial composition과 난이도 검증 없이 범위를 확장한다. |
| `vehicle_run.gd`에서 spawn/cue를 특례 처리 | encounter scheduling owner를 침범하고 UI 세션 충돌면을 넓힌다. |

## Proposed Design / Architecture and Ownership

| Concern | Owner | Change |
| --- | --- | --- |
| authored arrival intent | `vehicle_combat_stages.gd` | Stage 1 first surge에만 mode metadata 추가 |
| spatial allocation | `vehicle_spawn_allocator.gd` | distributed와 horde-front 경로 분리 |
| timing and cues | `vehicle_encounter_runtime.gd` | group timing 유지, horde front cue 중복 제거 |
| durable behavior | `vehicle_game_spec.md` | Stage 1 exception과 고정된 불변량 기록 |
| automated evidence | `tools/validation/` | 기존 contract 갱신 및 A/B/C 전용 validator 추가 |

### Canonical terms

- **authored population:** stage data에 예약된 전체 ordinary mobile count.
- **active count:** 현재 actor store에서 활성 상태인 mobile enemy 수.
- **front population:** 같은 진입 anchor와 cue를 공유하는 surge unit 수.
- **visible/near count:** 플레이어 주변 viewport 또는 근거리에서 실제로
  동시에 읽히는 수. 이번 slice는 구조 검증 후 runtime playtest에서 판단한다.
- **attack commitment:** projectile/denial cap에 의해 실제 공격을 수행하는
  수. front population과 동일하지 않다.

## As-Is / To-Be

| Contract | As-is | To-be |
| --- | --- | --- |
| Stage 1 first surge | 27대 / 8 anchors / 4 groups / 8 cues | 27대 / 2 anchors / 2 fronts / 2 cues |
| Stage 1 front size | 3–4대 | 12대, 15대 |
| Stage 1 role totals | authored multiset | 동일 |
| Stage 2–5 surge | distributed | 동일 |
| cap/speed/quota | 현행 | 동일 |
| UI/localization/art | 현행 | 변경 없음 |

## Milestones / Tasks

### M1 — Contract and plan

- [x] Current stage, allocator, runtime, validator, CI contracts inspected.
- [x] Baseline pacing, allocation, enemy-expansion validators passed.
- [x] Production B and test-only A/C boundaries locked.
- [x] Plan lifecycle/frontmatter validation completed.

### M2 — Production horde-front implementation

- [x] Mark only Stage 1 first surge as `horde_front`.
- [x] Allocate exactly two distinct front anchors and reuse each for four squads.
- [x] Prefer a 90-degree separated second front without sacrificing offscreen fairness.
- [x] Coalesce arrival cues to exactly one per horde front.
- [x] Fan shared-anchor spawns without changing collision or field geometry truth.
- [x] Preserve distributed behavior for every unmarked packet.

### M3 — Structural evidence

- [x] Update existing pacing and allocation validators for the Stage 1 exception.
- [x] Add deterministic A/B/C validator.
- [x] Verify B keeps 27 roles and C adds only nine low-health `scrap_drone` roles.
- [x] Verify B and C keep distinct initial fan positions and equivalent front fairness.
- [x] Verify all registered fields and a bounded seed matrix.

### M4 — Handoff quality

- [x] Run focused validators and `git diff --check`.
- [x] Run Web release export.
- [x] Audit responsibility, contract drift, and forbidden-path changes.
- [x] Commit only task-owned gameplay, validation, plan, and spec files.

## Test Plan

Focused automated checks:

1. `validate_vehicle_horde_fronts.gd`
   - A: 27 units, 8 distinct anchors, 4 groups, 8 cues;
   - B: 27 units, 2 distinct anchors, 2 fronts, 2 cues, 4 squads/front;
   - C: 36 units, 2 fronts, 2 cues, exactly 9 added low-health scrap roles;
   - B/C role multiset, determinism, offscreen/ring preference, 90-degree
     separation fixtures, and unique initial fan positions;
   - registered field/seed fixtures.
2. `validate_vehicle_spawn_allocation.gd`
   - Stage 1 first surge uses two horde anchors;
   - Stage 2–5 retain eight unique anchors, broad consecutive-wave diversity,
     and existing arc rules.
3. `validate_vehicle_encounter_pacing.gd`
   - opening scout remains at 5.1/6.0 seconds;
   - Stage 1 first surge is exactly 27 units and explicitly horde mode;
   - caps and quotas do not move.
4. Existing relevant validators:
   `validate_vehicle_enemy_expansion.gd`,
   `validate_vehicle_field_layout_generation.gd`, and any validator directly
   importing the changed owners.
5. `tools/export_web.ps1` must produce non-empty Web release files.

Runtime acceptance after automated checks:

- first surge presents two recognizable arrival directions rather than eight
  isolated spawn points;
- one arrival effect/sound occurs per front;
- ordinary enemies remain fair/offscreen and the opening scout is unchanged;
- no UI, localization, art, speed, cap, quota, weapon, card, terrain, or boss
  behavior changes.

## Validation Cadence

- After allocator edit: horde-front and spawn-allocation validators.
- After runtime edit: horde-front and encounter-pacing validators.
- After spec/test completion: all focused validators above.
- Before commit: Web export, `git diff --check`, forbidden-path audit, scoped
  quality audit.

## Rollback / Safety

- The feature is data-gated by `arrival_mode`. Removing the Stage 1 metadata
  restores the distributed allocator path without deleting code.
- No schema migration, save-data mutation, dependency, asset replacement, or
  destructive filesystem action is involved.
- If the second front cannot satisfy preferred 90-degree separation, choose the
  next deterministic distinct offscreen anchor; do not increase speed, move the
  camera, or place a visible anchor merely to preserve separation.
- If count, role, cue, or determinism assertions fail, stop and repair the owner;
  do not compensate by changing active caps or combat tuning.
- If a forbidden UI/localization/`vehicle_run.gd` path appears in this worktree,
  stop and exclude it from the task rather than editing or reverting it.

## Risks

- Multiple squads still share one semantic anchor. A bounded 16-pixel spawn fan
  and per-squad phase prevent exact overlap, but runtime playtest must confirm
  the result reads as dense rather than visually collapsed.
- Two large fronts can increase perceived burst pressure even though attack
  commitment caps are unchanged.
- Edge player positions may make opposite-direction fronts impossible; offscreen
  fairness takes precedence over exact opposition.
- Structural A/B/C validation proves topology and invariants, not subjective fun.
  A later playtest may justify C or a different spacing policy, but not inside
  this slice.

## Open Questions

No material implementation choice remains open. Player acceptance of B versus
the test-only C contingency is a later playtest decision and is not delegated to
this implementation.

## Decision Notes

- 2026-07-28: Selected spatial concentration before enemy-count, speed, or
  viewport changes.
- 2026-07-28: Selected shared-anchor fronts over four distinct anchors per
  directional wedge to make 12–15 enemies form an actual arrival mass.
- 2026-07-28: Kept Stage 2–5 distributed to bound balance risk and UI-session
  conflict.
- 2026-07-28: Kept C at 36 units as test-only evidence, not shipped content.
- 2026-07-28: Post-pass audit found shared-anchor formation duplication and
  incomplete C parity checks. Added a clearance-safe spawn fan, distinct squad
  phases, and B-equivalent C topology/fairness/determinism validation.
- 2026-07-28: Built Web smoke test deployed successfully with no console
  warning/error and showed two separated dense enemy clusters on the minimap.

## Progress

- [x] Scope and forbidden paths fixed.
- [x] Current contract and baseline validator evidence collected.
- [x] Production implementation complete.
- [x] Automated validation complete.
- [x] Web export complete.
- [x] Scoped quality audit and commit complete.
- [x] Built Web runtime smoke test complete.
- [ ] User runtime density acceptance complete.

## Next Steps

1. Complete the scoped commit without staging concurrent UI/art work.
2. Play Stage 1 from the built artifact and decide whether B is sufficient
   before considering the C population increase or later growth/boss work.

## Completion Criteria

This plan remains active until production B is committed and its first-surge
runtime presentation has been accepted. Automated implementation is complete
when all M1–M4 checks pass with no forbidden-path diff.
