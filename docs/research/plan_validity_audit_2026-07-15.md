---
type: evidence
status: active
owner: BK
created: 2026-07-15
last_reviewed: 2026-07-15
topic: Validity of completed implementation plans against active specs, current runtime, rendered evidence, and owner playtest feedback
scope: Death/retry, checkpoint meaning, combat input and guard, stage verticality and enemy density, Forge/rest/shop flow, UI handoff, and validation quality
source: Direct document and code review, focused Godot validators, current rendered captures, git history, owner feedback, and the web-input research reviewed on 2026-07-15
related:
  - ../product/2d_platform_action_card_game_prd.md
  - ../design/COMBAT_EQUIPMENT_CRAFTING.md
  - ../design/PRODUCTION_UI_CONTRACT.md
  - ./player_input_and_ui_followup_audit_2026-07-15.md
  - ../../.agent/execplans/2026-07-14-minimum-equipment-progression-vertical-slice.md
  - ../../.agent/execplans/2026-07-15-gameplay-validity-repair.md
---

# 구현 계획 Validity Audit - 2026-07-15

## Purpose

완료 표시된 계획과 자동 검증이 실제 플레이 경험을 얼마나 보장하는지 확인한다.
검증기가 통과했다는 사실과 제품 요구가 만족됐다는 판단을 분리하며, 사용자가 직접
확인한 문제를 코드·문서·렌더 증거로 교차검증한다.

이번 감사는 문제를 기록하고 우선순위를 정한다. UI 시각 수정과 gameplay 구현은
각각 별도 작업에서 수행한다.

## Overall Verdict

현재 빌드는 **구조적 일관성은 높지만 제품 validity는 통과하지 못했다.** 장비,
제작, 저장, 고정 스테이지 조립, terminal settlement의 내부 계약은 잘 검증돼 있다.
반면 검증기는 다음 잘못된 결과도 성공으로 고정한다.

- 사망 즉시 런 종료와 Stage 1 새 런을 `Retry`로 표시;
- 실제 중간 체크포인트가 없는 Stage 1;
- 전투 스테이지 내부의 두 Forge;
- 적이 매우 적고 주 경로가 거의 수평인 고정 Stage Plan;
- 계산상 피해를 막지만 성공을 알아볼 수 없는 방어;
- 현재 제품 범위와 무관한 고정 gamepad 입력;
- 글자가 보이기만 하면 읽기 쉽다고 간주하는 UI 캡처.

## Sources

### Current authority

- `docs/product/2d_platform_action_card_game_prd.md`
- `docs/design/COMBAT_EQUIPMENT_CRAFTING.md`
- `docs/design/PRODUCTION_UI_CONTRACT.md`
- current runtime, typed Resources, and active release matrix as implementation evidence

### Historical evidence

Completed ExecPlans explain why current code exists but do not override newer owner
decisions. Superseded specs and archived research remain history only.

## Verdict Matrix

| Priority | Area | Verdict | What the current evidence actually proves |
| --- | --- | --- | --- |
| Critical | Death and retry | Fail | Death settles and unloads the run; `Retry Expedition` starts a new Stage 1 run. |
| Critical | Save point meaning | Fail | Checkpoints return the player after a fall; they are not a death retry or saved run state. |
| P0 | Guard | Partial internally, fail player-facing | Resolver blocks damage, but production input-to-hit feedback and readability are not verified. |
| P0 | Product input scope | Fail in runtime | Active docs now use keyboard/mouse, but runtime, Settings, prompts, and validators still enforce old keys and gamepad behavior. |
| P1 | Forge/rest flow | Fail | Stage 1 Forge stations are inside combat-stage rooms; there is no consistent safe intermission flow. |
| P1 | Merchant | Missing | No merchant NPC, potion purchase, or selling command exists. |
| P1 | Enemy density | Fail | Required-route enemy counts are 6, 3, and 4 across 8, 7, and 8 required rooms. |
| P1 | Verticality | Fail | Entire required-route vertical spans are only 360px, 240px, and 200px. |
| Deferred UI branch | Readability and popups | Fail, recorded | Current SVG work is an asset catalog, not screen adoption; current UI remains small and screen-sized. |
| P1 | Web delivery evidence | Missing | No `export_presets.cfg`; editor/headless checks do not prove browser behavior. |

## Findings

### 1. Death, Retry, And Checkpoints

Current death path:

```text
player_died
 -> RunDirector.show_run_result(false)
 -> RunState.settle_run_death()
 -> RUN_DEATH
 -> unload stage
 -> Retry Expedition = start_production_run()
 -> new run, Stage 1, reset HP/XP/coins/cards
```

Evidence:

- `scripts/autoload/RunDirector.gd`: `_on_player_died`, `show_run_result`, and
  `_show_run_result_screen` settle and unload the active run.
- `scripts/autoload/RunState.gd`: `start_new_run` resets run-scoped state.
- `scripts/ui/production/RunResult.gd`: defeat offers `Retry Expedition` and
  Main Menu, but the retry signal is wired to a new expedition.
- `scripts/stages/StageBase.gd` can revive at a checkpoint, and
  `scripts/autoload/Game.gd` contains `recover_after_death`, but the production
  death path never calls them.
- `StageRuntimeContentSpawner.gd` creates one checkpoint in the terminal room.
  Stage 1 has no authored mid-stage checkpoint.

The 2026-07-12 roadmap deliberately chose “Death ends the run,” so the runtime is
not an accidental implementation error. The latest owner decision supersedes that
product premise.

The 2026-07-14 minimum plan contains two false-complete claims:

- its Stage 1 mid-Forge beat says checkpoint + Forge + recovery, but `LrBrokenBridge`
  has only a Forge;
- its checked death/re-entry item has no same-run death-retry validator. Existing
  run-result tests instead confirm terminal death.

Recommended MVP policy:

- on death, offer `Retry Stage` and `End Expedition / Main Menu`;
- `Retry Stage` keeps the run and reloads the current fixed stage from its
  stage-entry snapshot;
- enemies, hazards, pickups, rewards, health, ammunition, potion, equipment
  condition, and transaction state reset consistently to that snapshot;
- keep current checkpoints as **fall recovery points**, not save points;
- add death checkpoints only after room/encounter partial-reset rules exist.

Stage-start retry is safer than checkpoint retry now because stage and reward IDs
already prevent duplicate resolution, while Stage 1/2 have no meaningful mid-stage
checkpoint or partial-state reset policy.

### 2. Guard: Correct Math, Missing Player Proof

The core path exists:

- `Input.is_action_pressed("guard")` updates `ShieldCombatRuntime`;
- `PlayerController.receive_damage` calls `resolve_shared_defense`;
- a successful block returns before health damage;
- startup, precise window, held guard, stability, condition, angle, unblockable
  attacks, and guard break exist in the resolver.

However the feature can reasonably feel broken:

- the player visual has no distinct startup, active guard, precise guard, or break
  pose;
- HUD rendering drops the guard `phase/guarding` state and mainly shows stability;
- successful block returns before normal hurt feedback and has no equivalent
  impact cue;
- the emitted `Blocked`/`Precise guard` status has no reliable visible production
  consumer;
- `validate_shield_combat_runtime.gd` calls the isolated runtime directly;
- `validate_arsenal_trial.gd` completes the guard lesson through private method
  calls instead of a real input and enemy hit.

Therefore `SHIELD_COMBAT_RUNTIME_VALIDATION_OK` proves calculation, not that the
player can activate, see, hear, understand, or trust blocking in a stage.

Required acceptance gate:

1. send the real configured guard input to a production Traveler;
2. deliver a frontal enemy hit through the real Hitbox/DamageInfo path;
3. prove health loss for idle/startup and zero health loss for active guard;
4. prove a distinct pose/effect/sound for startup, normal block, precise block,
   guard break, and recovery;
5. capture the result in an actual combat room.

### 3. Forge, Rest, And Merchant

- Stage 1 `LrBrokenBridge` contains `MidForge`; the room has no enemy/hazard budget
  but is still part of the monster stage.
- `LrExitAscent` contains `FinalForge` and also requires two enemies.
- `validate_forge_station_flow.gd` explicitly treats both stage-internal stations
  as the successful contract.
- Stage 2 `FwRestForge` is a useful enemy/hazard-free authored safe room, but its
  Forge and Shop are only markers; no NPC or shop workflow consumes them.
- Stage transitions are inconsistent: not every normal-stage boundary visits the
  same preparation/rest space.
- Current coins are run-scoped and are spent only on card rerolls. Current active
  materials are persistent crafting currencies.

A future safe intermission map can reuse the authored Rest/Forge room shape, but it
needs an explicit flow owner:

```text
stage clear -> card reward -> safe intermission
 -> merchant / Forge / preparation / leave
 -> next stage
```

Initial merchant scope can include potion purchase. “Sell byproducts” needs a
separate domain decision: selling persistent crafting materials for temporary run
coins is not a harmless default. Either define run-only salvage or explicitly
approve which persistent material can be exchanged and how rollback works.

### 4. Enemy Density

Required rooms with non-zero encounter budget:

| Stage | Combat rooms / required rooms | Current required enemies |
| --- | ---: | ---: |
| Ruin Approach | 4 / 8 | 6 |
| Flooded Works | 2 / 7 | 3 |
| Broken Sanctum | 2 / 8 | 4 |

The counts are visible in current fixed-stage HUD captures and follow the fixed
plans in `CuratedStagePlanBuilder.gd`. A budget point is not one enemy: enemies
consume weighted pressure, so exact budget validation can succeed with very few
actors.

Current validators check that authored budgets are legal and fully spent. They do
not check:

- minimum enemy count per stage;
- maximum consecutive required rooms without combat;
- enemies per traversal distance or expected minute;
- whether enemies occupy multiple elevations;
- whether a combat room combines compatible pressure roles.

The fixed plan signature test then freezes the sparse result as approved. The
owner's “too few monsters” observation is supported by both data and captures.

### 5. Verticality

Applying the current socket-alignment formula to the critical path produces these
full required-route height ranges:

| Stage | Required rooms | Total vertical range |
| --- | ---: | ---: |
| Ruin Approach | 8 | 360px |
| Flooded Works | 7 | 240px |
| Broken Sanctum | 8 | 200px |

Each entire critical path fits inside one 720px-tall reference viewport. Optional
branches have larger drops, but required progression is predominantly horizontal.
Current fixed-stage captures show short local platforms rather than sustained
layered traversal or multi-height combat.

`StageGeometryValidator` enforces only maximum gaps, maximum height differences,
clearance, reachability, and recovery. It has no minimum vertical range, ascent /
descent count, layered route, or elevated-enemy requirement. A flat but reachable
map therefore passes.

### 6. Controls And Browser Constraints

The external source review is retained in the archived
`player_input_and_ui_followup_audit_2026-07-15.md`; the accepted recommendation
and implementation order live in the active gameplay-validity plan.

Current product recommendation:

- arrow keys, `Space`, `Left Shift` for movement;
- `X` attack, `C` guard;
- `E` for chest/NPC/altar/Forge/exit interaction;
- `A` potion;
- no active skill now; at most one future skill on `Z` if playtesting justifies it;
- keyboard/mouse menu navigation and full keyboard completion path.

Current runtime still uses `F/G/H`, fixed gamepad events, gamepad prompt switching,
and gamepad-oriented validators. This is implementation drift, not a product
requirement.

### 7. UI Work Is Saved, Not Implemented

The 2026-07-15 SVG asset catalog plan truthfully produced reusable shapes and icons
only. It explicitly says production screens have not adopted them, so it should not
be read as a UI readability completion claim.

The separate UI branch handoff remains:

- concise natural Korean and English;
- roughly 2-3x stronger core-text readability, redesigned rather than blindly
  scaling every font;
- centered NPC, merchant, and Forge popups;
- `Escape` close/back, arrow-key focus, `Enter`/`Space` confirm;
- visible focus restoration and no clipping at supported browser viewports;
- readable death choices and guard-state feedback.

## What Is Valid And Reusable

- one-Traveler contextual melee/ranged attack ownership;
- deterministic equipment, blueprints, grades, condition, repair, and profile v2;
- fixed room assembly, typed anchors, fall recovery, and fail-closed stage loading;
- idempotent rewards and terminal settlement;
- jump buffer, coyote time, jump cut, double jump, dash, and one-way drop;
- safe Stage 2 rest-room geometry as a candidate intermission-space shell;
- isolated shield resolver as a foundation, once end-to-end feedback is added.

## Recommended Work Order

1. **P0 gameplay:** replace terminal retry with same-run current-stage restart and
   define the stage-entry snapshot/rollback contract.
2. **P0 gameplay/input:** implement arrow movement plus `X/C/E/A`, remove gamepad
   product behavior, and
   add live guard E2E plus unmistakable block feedback.
3. **P1 flow:** create one consistent safe intermission map between normal stages;
   move Forge there and add a minimal merchant after the currency/salvage decision.
4. **P1 stages:** add vertical-range and combat-density targets, revise the three
   fixed plans, then capture full traversal and combat—not isolated screenshots.
5. **Separate UI branch:** apply the stored typography, bilingual, popup, focus,
   and result-screen requirements after gameplay policies are stable.

## Validation Performed

The following focused checks passed on Godot 4.7:

- `validate_shield_combat_runtime.gd`
- `validate_run_result_ui.gd`
- `validate_boss_run_flow.gd`
- `validate_forge_station_flow.gd`
- `validate_curated_stage_plans.gd`
- `validate_production_stage.gd`

Their pass status is retained as structural evidence. The failures above are
product-validity gaps and validator blind spots, not hidden command failures.

## Limitations

- Static review and captures do not measure combat fun, fatigue, discovery time,
  or perceived fairness.
- Current fixed-stage captures are teleported stills and omit continuous traversal
  and most combat rooms.
- Enemy and vertical targets require playtests; this audit proves the current
  checks are insufficient, not one universal ideal density.
