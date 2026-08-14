---
type: plan
status: active
owner: BK
created: 2026-08-14
scope: Ten-stage campaign pacing, dense-enemy capacity, ordinary-enemy engagement behavior, and VehicleRun responsibility reduction after the weapon/progression migration
related:
  - ../../AGENTS.md
  - ../PLANS.md
  - ../design/DESIGN.md
  - ../cardborne-performance-engineering-policy.md
  - ../cardborne-runtime-architecture-audit.md
  - ./2026-08-13-evidence-category-slots-and-scalable-swarm.md
  - ./2026-08-14-weapon-unlocks-and-early-level-pacing.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/product/vehicle_upgrade_catalog.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/performance/2026-08-13-dense-enemy-stutter-evidence.md
  - ../../docs/performance/2026-08-13-dense-enemy-architecture-options.md
---

# Ten-Stage Pressure and VehicleRun Ownership - Execution Contract

After the focused weapon/progression migration completes, Cardborne will extend the run to ten shorter stages with the five existing bosses at pair ends, increase challenge through continuity, threat concurrency, and attrition before raising exact actor counts, and reduce `VehicleRun` one measured responsibility at a time before the campaign expansion lands.

## Purpose

- Objective: make the fixed-Hard run materially harder and longer without doubling content or hiding performance regressions, and stop new campaign/density work from further expanding the oversized run orchestrator.
- Deliverable: a real ten-stage paired campaign, proportionate difficulty changes, measured density headroom, and responsibility-shaped runtime owners behind a smaller `VehicleRun` facade.
- Completion state: one clean commit lineage passes focused gameplay/UI contracts, Korean/English rendered checks, a production Web export and interaction smoke, and the separately authorized native/Web performance gates; the final product uses ten player-facing stages and never claims a higher exact-enemy cap without same-build evidence.

## Why and Verified Starting Point

- The prerequisite contract `.agents/execplans/2026-08-14-weapon-unlocks-and-early-level-pacing.md` owns removal of default EMP/Seeker, shared weapon cards, weapon-owned curves, 17-cell build UI, and the early XP surcharge. This plan consumes that completed state and must not redesign it.
- The five-stage campaign is hard-coded across stage, difficulty, boss, tactic, Result, localization, capture, and validation owners. Quotas are `48/64/80/96/112`; authored populations are `520/660/816/1026/1260`.
- Logical authored pressure and exact live simulation are already separate. The encounter director uses logical caps `6/124/172/224/276` but exact materialized caps `6/40/48/48/48`. Stage 3 onward therefore stops increasing simultaneous exact ordinary actors.
- Historical same-checkpoint evidence passed native exact cap 48 and failed 64; the same Web cap-48 build was red. Current `HEAD` is newer, so those numbers select risk and test order but do not qualify current performance.
- `scripts/vehicle/vehicle_run.gd` is now 7,309 lines with 288 top-level functions, 224 top-level variables, 128 constants, and more than 80 preload dependencies. The earlier architecture audit recorded 6,503 lines and 251 functions, so previous extractions did not stop responsibility growth.
- The latest captures are deterministic fixtures, not normal-play difficulty evidence. `03-peak-horde.png` proves the renderer can present a dense composition, while `93-final-result.png` contains fixture totals and cannot establish normal clear time or win rate.

## Scope and Boundaries

In scope:

- Ten player-facing stages arranged as five two-stage arcs, with the five existing boss encounters at Stages 2, 4, 6, 8, and 10.
- Quota, authored reserve, item distribution, transition recovery, threat budget, stage/difficulty arrays, reports, HUD, guidebook ranges, captures, and validators required by that campaign.
- Current-HEAD native/Web performance qualification, density diagnostics, and one measured hot-owner extraction at a time.
- `VehicleRun` stage/progression/boss boundary extraction before ten-stage implementation, followed by measured simulation extraction where current evidence selects an owner.
- Ordinary-enemy first-contact behavior: collective-tactic arming, pursuit recovery readability, shield-source truth, and mobile-ranged hull contact.

Out of scope:

- A difficulty selector, adaptive difficulty, permanent progression, or a second campaign mode.
- New bosses, enemy roles, boss pattern families, maps, production dependencies, engine changes, Web threads, custom export templates, or GDExtension work.
- Weapon-card policy, default weapon state, weapon curves, upgrade/HUD slot semantics, and early XP pacing owned by the prerequisite contract.
- Raising the shipping hostile, projectile, XP, effect, render-batch, or draw-call ceilings without the declared evidence and approval gates.
- A big-bang `VehicleRun` rewrite, pass-through files created only to reduce line count, or renderer decomposition while render ownership is not measured as material.

Constraints and invariants:

- Preserve manual aim, held primary fire, Dash, the prerequisite contract's acquired automatic/active weapons, authored encounter identities, map pickups, card upgrades, quota-gated boss encounters, deterministic offers, exact earliest projectile contact, and fixed Hard.
- Korean remains default; Korean and English stay complete on every changed surface.
- Do not begin this plan until the prerequisite weapon/progression contract's functional and focused rendered gates pass.
- The ten-stage run keeps the current five bosses and current total ordinary defeat quota of 400. More stages must not silently double runtime, XP, repair supply, or boss content.
- The shipping exact ordinary cap remains 48 unless the same clean native and built-Web source passes the locked higher-cap branch.
- Player intent, damage, collision, committed attacks, boss windows, and their visible truth remain 60 Hz. No tick-rate or catch-up-ceiling change is an optimization.

Destructive or irreversible actions:

- None. Production dependencies remain stable.

Exact actions requiring owner or user approval:

- Start the broad 60-second native/Web performance matrix and capacity staircase only after the implementation and focused rendered gates are complete; report its expected duration, visible process impact, and early-stop rule first.
- Any GDExtension, custom Web template, Web threading, engine change, dependency, workload reduction, threshold change, or shipping exact cap above 64 requires a separate approval and contract revision.

## Domain Alignment and Locked Product Design

Use these terms consistently:

| Term | Meaning | Owner |
| --- | --- | --- |
| Reward offer | One frozen transaction containing one to three compatible cards | Upgrade catalog and reward runtime |
| Logical authored population | Deterministic encounter identities that may remain in virtual reserve | Combat stages and encounter runtime |
| Exact materialized actor | A live world actor with position, collision, health, status, and update work | Enemy store and simulation owners |
| Runtime pool slot | A bounded storage index; never a UI or equipment slot | Enemy/projectile/effect stores |

### Weapon/progression prerequisite

The related focused contract is the sole owner of weapon acquisition, upgrade curves, build cells, HUD weapon state, and the early XP formula. This plan starts only after that contract passes. Ten-stage XP distribution must use its `1968 XP`, Level-30, 29-upgrade, and `9/4/4/6/6` five-stage baseline rather than restoring the previous `9/5/4/5/6` distribution.

### Ten-stage decision

1. Replace five long stages with five two-stage arcs. Stages `1/3/5/7/9` end immediately when their quota is met; Stages `2/4/6/8/10` use the existing quota-warning-boss-result flow.
2. Use quotas `[24, 24, 32, 32, 40, 40, 48, 48, 56, 56]`. Their sum remains the current 400 ordinary defeats.
3. Split each current stage's authored role sequence and logical reserve deterministically across its two successor stages. The pair reuses the current field, boss, role availability, and boss pattern family; no Stage 6+ clamp may silently borrow the last array element.
4. Keep one run-selected field and continuous world/player/build/projectile/XP state. Odd-to-even transitions refresh stage-local objects but do not heal. Even-to-next-odd transitions restore 40% of missing Hull rather than full Hull.
5. Split each current stage's 14 direct pickups across its pair: each new stage gets two recalls and five repairs, preserving ten repairs and four recalls per arc and the existing total run supply rather than doubling it.
6. Keep the current minimum-quota XP total and target final level 30. Recalculate only the distribution across ten stage reports; do not double XP awards or add filler cards.
7. Interpolate the current five-stage health, damage, speed, boss, and coverage endpoints across ten entries. The new Stage 10 must equal the current Stage 5 endpoint. Difficulty growth comes first from less free healing, steadier visible pressure, and later threat concurrency, not another durability multiplier.
8. Use threat budgets `[1.0, 2.0, 3.0, 3.75, 4.5, 5.0, 5.5, 6.0, 6.5, 7.0]`. Stages 6-10 may admit at most four ranged and three denial commitments; earlier stages preserve the current three/two ceiling. Existing startup, telegraph, projectile, boss reserve, and escape-corridor rules remain.
9. Exact materialized caps start `[6, 32, 40, 40, 48, 48, 48, 48, 48, 48]`. Logical reserve and arrival continuity may grow, but normal play does not exceed exact 48 in the initial implementation.

### Density and performance decision

- Use the existing exact-near plus virtual-far reserve as the shipping architecture. More logical enemies and faster safe replenishment must not mean full offscreen AI, collision, or per-frame snapshots.
- Profile the current clean build before changing a hot path. Historical evidence makes schedule/enemy/grid/projectile work the first suspects but does not prove the current owner.
- Keep retained rendering and current batches. Godot's own guidance separates process/physics, draw calls, memory, and pipeline monitors; current evidence does not justify a renderer or MultiMesh rewrite.
- Threads and low-level servers are escalation paths, not default fixes. The active SceneTree is not thread-safe, and frequent server readback can synchronize and stall work.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| What owns weapon and early-XP changes? | The focused contract maps the complete card/runtime/UI/XP surface | Related active plan and current source audit | Consume it as a completed prerequisite; do not duplicate its work here | prerequisite |
| How can five bosses support ten stages? | Boss content and many arrays are exactly five-wide | Stage/boss catalogs and Result contracts | Five two-stage arcs; boss at each even stage | 2.1-3.5 |
| Why can the game feel easy despite large authored counts? | Exact actors stop at 48, transition heal is full, pickups are generous, and no current normal-play outcome data exists | Product spec, encounter director, captures | Increase attrition and concurrency before durability or exact cap | 3.1-3.5 |
| Can exact actor count rise safely now? | Historical cap 48 passed native while 64 and Web were red; current HEAD is unqualified | Active plan and performance evidence | Ship 48 first; remeasure and gate 64 separately | 4.1-4.5 |
| Is `VehicleRun` genuinely overloaded? | It owns orchestration plus simulation, damage, campaign, UI snapshots, persistence, capture, and performance lifecycle | 7,309 lines, 288 functions, 80+ dependencies, git history | Preserve facade; extract campaign first, then current measured hot owner | 2.1-2.4, 4.2-4.4 |
| Is an enemy spawn shield created by the arrival system? | No. New enemies initialize with `shielded = false`; shield state is later assigned by Generator/Shield Escort support or collective Lock/Execute. Independent births keep a 320-pixel hard separation while Shield Escort range is 300, so the repeated first-sight case is primarily a collective tactic that gathered offscreen. | `vehicle_run.gd`, `vehicle_spawn_allocator.gd`, shield/contact validators, Stage 3-8 captures | Keep support and tactic shields, but prevent collective Gather from arming offscreen so the player sees the transition instead of a seemingly pre-shielded spawn | 6.1-6.3 |
| Are line and circle births produced by spawn allocation? | No. Spawn allocation distributes independent positions across safe offscreen sectors. Spear/column/screen/escort/network slots are authored collective-tactic motion and currently override role movement as soon as four members exist, including offscreen. | Spawn allocator, collective runtime/catalog, `03b-collective-lock.png`, `03c-collective-break.png` | Preserve authored formations; require continuous visible eligibility before Gather | 6.1-6.3 |
| Do close-range enemies generally flee the player? | Pursuit intent points at the movement focus. Apparent fleeing can come from collective-slot priority, Chaser/Rammer recovery, engagement gates, or wall recovery. Only Chaser recovery produces an avoidant-looking reverse that is not needed for a heavy charge reset. | Movement policy, VehicleRun phase order, movement validators | Delay collective takeover; change Chaser recovery to a bounded lateral peel while preserving Rammer reverse and wall recovery | 6.1-6.3 |
| Is ranged hull overlap missing damage by accident? | No. Source, spec, and validators intentionally make ranged/support/fixed/mine hull overlap damage-inert. This also creates a close-range dead zone where a player can overlap a mobile ranged craft without hull pressure. | Contact runtime, product spec, integrated contact validator | Revise the product contract only for mobile ranged roles: low repeated swept hull damage; support, fixed structures, ordinary mines, and projectile rules remain unchanged | 6.1-6.4 |

Readiness statement:

- Campaign, performance, ownership, dependency, and initial shipping-cap decisions are closed; weapon/early-XP work is an external prerequisite with its own progress source.
- The broad performance run is an explicit approval checkpoint, not an implementation decision left to the executor.
- The only conditional branch is metric-selected and predetermined: cap 64 ships only if the named native and Web gates pass; otherwise exact 48 remains and pressure uses reserve/concurrency.

## Tasks

### External prerequisite (former Phase 1; progress is tracked only in the related contract)

Do not mirror its checkboxes here. Begin Phase 2 only after `.agents/execplans/2026-08-14-weapon-unlocks-and-early-level-pacing.md` is `done` and its final gate remains valid at the Phase-2 starting commit.

### Phase 2: Move campaign policy out of VehicleRun

Goal: give the ten-stage change one canonical campaign owner before multiplying stage branches.

Preconditions:

- The complete weapon/progression prerequisite contract passes.

Source owners: `scripts/vehicle/vehicle_run.gd` functions `_update_stage_progression` through `_ordinary_active_count`, `scripts/encounters/vehicle_stage_flow.gd`, `scripts/vehicle/vehicle_stage_transition_runtime.gd`, `scripts/bosses/vehicle_boss_runtime.gd`, `scripts/rewards/vehicle_reward_runtime.gd`, `scripts/combat/vehicle_stage_report_builder.gd`, `scripts/combat/vehicle_run_result_builder.gd`.

- [x] **2.1 Freeze the campaign command/receipt contract.**
  - Change: define typed or shape-validated commands for quota reached, boss warning/entry/defeat, stage-without-boss completion, stage continuation, terminal result, and reward queue state. `VehicleRun` remains the SceneTree/mutation facade.
  - Accept: existing five-stage deterministic traces produce identical state, report, reward, boss, and continuation receipts before and after the boundary.
- [x] **2.2 Promote existing owners instead of adding a catch-all manager.**
  - Change: move transition policy into `VehicleStageTransitionRuntime`, quota/boss eligibility into `VehicleStageFlow`, boss phase decisions into `VehicleBossRuntime`, and report/result assembly into their current builders. Remove migrated policy from `VehicleRun` in the same task.
  - Accept: no dual authority remains; each migrated invariant has one owner and `VehicleRun` only executes commands and forwards receipts.
- [x] **2.3 Replace private capture coupling for the migrated surface.**
  - Change: expose a narrow campaign fixture facade consumed by `vehicle_run_capture_gateway.gd` and validators instead of reaching new owners through arbitrary `VehicleRun` private fields.
  - Accept: existing stage continuity, report, capture, boss, and integrated-run fixtures pass without adding test-only policy to production owners.
- [x] **2.4 Audit the resulting responsibility boundary.**
  - Change: record lines/functions/dependencies only as secondary signals and review changed owners for policy duplication, pass-through APIs, and reachable partial transitions.
  - Accept: campaign policy no longer lives in `VehicleRun`; a failed receipt cannot leave both old and new owners active.

### Phase 3: Ship the paired ten-stage campaign

Goal: reach Stage 10 with the current five bosses, bounded total progression, stronger attrition, and no hidden Stage-5 fallback.

Preconditions:

- Phase 2 campaign equivalence gate passes.

Source owners: `scripts/vehicle/stages/vehicle_combat_stages.gd`, `scripts/enemies/vehicle_stage_difficulty.gd`, `scripts/encounters/vehicle_encounter_director.gd`, `scripts/encounters/vehicle_collective_tactic_catalog.gd`, boss catalogs, campaign runtime owners, field drops, experience, Result/HUD/guidebook, localization, captures, specs, and focused validators.

- [x] **3.1 Make ten-stage data complete and fail-closed.**
  - Change: add all ten IDs and exact quota/pressure/difficulty/title/boss-option entries. Odd profiles explicitly have no boss; even profiles explicitly reference one of the five existing bosses. Replace five-wide clamps with exact lookup validation.
  - Accept: all ten profiles load, every array/map has ten intentional entries where required, invalid or missing Stage 6-10 data fails validation rather than borrowing Stage 5.
- [x] **3.2 Split authored encounters and item/XP budgets.**
  - Change: deterministically split each current role sequence across its arc; implement the locked pickup distribution and preserve pair-total XP/quota economics.
  - Accept: same seed reproduces role/order/window data; ten quotas total 400; each arc retains ten repairs/four recalls; minimum path still ends at level 30.
- [x] **3.3 Implement no-boss and boss-stage completion.**
  - Change: odd quota completion performs the continuous transition without boss warning; even completion preserves warning, boss, report capture, and terminal Stage 10 Result.
  - Accept: Stage 1-9 preserve live ordinary actors, projectiles, XP, build, cooldowns, exploration, position/facing/aim, and active time; only the declared transition recovery and stage-local refresh occur.
- [x] **3.4 Apply fixed-Hard attrition and concurrency.**
  - Change: use the locked recovery, interpolation, threat-budget, commitment, and exact-cap curves. Preserve telegraph and boss/projectile reserve contracts.
  - Accept: deterministic tests prove recovery amounts, commit ceilings, startup truth, projectile reserve, escape corridor, and exact actor ceilings at every stage.
- [x] **3.5 Update every player-facing and retained consumer.**
  - Change: HUD uses `N / 10`; guidebook ranges use Stage 1-10; Result requires ten records and marks bosses only on even stages; Korean/English copy and captures remove Stage 1-5 assumptions.
  - Accept: a deterministic complete run reaches one terminal Result after Stage 10 with ten ordered records, five bosses, cumulative active time, and complete localized labels.

### Phase 4: Attribute cost, extract one measured hot owner, and gate density

Goal: improve exact-enemy headroom without guessing, changing gameplay, or further expanding VehicleRun.

Preconditions:

- Phase 3 functional/rendered source is substantially complete.
- Before any broad run, report exact scenarios, 10-second warmup, 30/60-second durations, process/window impact, early-stop rule, and request user alignment.

Source owners: performance recorder/scenario/manual trace, `scripts/vehicle/vehicle_run.gd`, enemy schedule/store/spatial grid/contact, projectile/effect stores, encounter runtime, and current performance evidence.

- [x] **4.1 Establish an eligible current-HEAD baseline.**
  - Change: from a clean, quiet machine run the same native and built-Web Stage-10 production replay with commit, dirty state, viewport, renderer, VSync, focus, warmup, duration, and process-isolation metadata.
  - Accept: workload/count/state checks are valid and frame, physics, render, enemy/grid, projectile/effect, presentation, HUD, and catch-up fields are published. A red result remains valid evidence, not a reason to weaken the workload.
- [x] **4.2 Select the owner by recorded cost.**
  - Change: compare named p95/p99 and slow-tick receipts. If enemy schedule/grid is the largest failing owner, continue with 4.3. If projectile/effects is largest, use the existing projectile/effect stores and exact-hit receipts for the equivalent narrow extraction. If neither is material, stop and revise this contract.
  - Accept: one owner and one causal diff are named before code changes; render work is not selected from visual density alone.
- [x] **4.3 Extract the selected simulation kernel.**
  - Change: move only the selected schedule/decision/motion/query or projectile/effect path behind reusable input/output buffers and semantic receipts. Preserve stable handles, deterministic ordering, exact collision, 60 Hz critical work, and existing capacity. Remove the old implementation when the new owner becomes canonical.
  - Accept: focused replay equality passes at 6/32/40/48 actors plus boss/projectile cases; no duplicate live state, capacity scan, or recurring allocation is introduced.
- [x] **4.4 Compare once, then keep or reject.**
  - Change: run one same-scenario 30-second diagnostic after the coherent candidate.
  - Accept: retain the candidate only if the selected owner and total physics tail improve without workload, behavior, memory, render, or Web regression. Otherwise remove only that candidate and preserve the baseline.
- [x] **4.5 Run the exact-density staircase with early stop.**
  - Change: after cap-48 authority passes, run 64 then 96/128 only while each preceding tier passes. Record exact, visible, near-600/900, virtual-reserve, projectile/effect, attack, and frame/physics counts.
  - Accept: shipping remains 48 unless native and built-Web 64 both pass physics p95 <= 6 ms, p99 <= 8 ms, workload truth, frame-tail, and interaction/readability gates. A failing tier stops the staircase.

### Phase 5: Final integration and handoff

Goal: prove the complete product at supported surfaces and retire temporary planning state correctly.

- [ ] **5.1 Run focused source and document gates.**
  - Change: run changed-owner validators, `./tools/validation/validate_cardborne_visual_authority.ps1`, Godot import, `git diff --check`, and active plan/schema checks.
  - Accept: all relevant focused checks pass and no spec still claims five stages or full inter-stage healing; the completed weapon/progression contract remains unchanged.
- [ ] **5.2 Capture and interact with the built product.**
  - Change: export with `./tools/export_web.ps1`, start only through the approved fastrun Codex lane, and inspect Korean/English Upgrade, HUD, odd/even transitions, boss entry, Stage 10 Result, narrow/wide layouts, 200% text, and one real complete-run path.
  - Accept: no clipping, focus loss, unsupported action, stale Stage 5 copy, or hidden transition remains; console errors are zero.
- [ ] **5.3 Record narrow verdicts and retire the plan only after implementation.**
  - Change: update product/visual/performance owners with accepted durable behavior, record exact pass/fail labels, and change this plan to `done` only when every task and gate passes.
  - Accept: no performance result is described more broadly than its evidence and no active predecessor is silently treated as current authority for this scope.

### Phase 6: Make ordinary-enemy first contact read and behave correctly

Goal: preserve authored squad tactics while removing offscreen pre-arming, avoidant-looking Chaser recovery, and the mobile-ranged overlap dead zone without adding per-enemy nodes or unbounded avoidance work.

Preconditions:

- Treat arrival, collective tactic, movement intent, contact attack, and shield assignment as separate domains. Do not fix simulation truth in the renderer.
- Preserve exact actor cap 48, 10/30/20 Hz ordinary decision/motion cadence, 60 Hz committed attacks and contact sweep, eight-neighbor overlap work, deterministic ordering, and current projectile/attack timing.

Source owners: `scripts/encounters/vehicle_collective_tactic_runtime.gd`, `scripts/encounters/vehicle_collective_tactic_catalog.gd`, `scripts/enemies/vehicle_enemy_movement_policy.gd`, `scripts/enemies/vehicle_enemy_contact_runtime.gd`, `scripts/vehicle/vehicle_run.gd` only for existing orchestration callbacks, `docs/product/vehicle_game_spec.md`, focused validators, and existing capture fixtures.

- [x] **6.1 Freeze a causal state matrix before changing behavior.**
  - Change: extend focused deterministic fixtures to distinguish independent birth, Dormant, visible eligibility, Gather, Lock, Execute, Break, ordinary Move, Chaser recovery, Rammer recovery, wall reposition, support shield, tactic shield, warned contact, and passive ranged hull contact. Record the shield source and movement reason in debug receipts; do not add player-facing debug UI.
  - Accept: fixtures prove births are independently separated, new enemies are not spawn-invulnerable, pursuit Move closes distance, and each observed non-pursuit direction maps to one named state. The pre-fix fixture reproduces offscreen Gather and damage-inert mobile-ranged overlap.
- [x] **6.2 Arm collective tactics only after readable engagement.**
  - Change: add a bounded per-squad continuous-visible eligibility timer. Dormant squads follow ordinary role movement and cannot claim the Gather permission until at least four members plus the leader have remained visible for `0.75 s`. Losing visibility before Gather resets eligibility. Existing Gather/Lock/Execute timings, one-Gather/one-active permissions, formation geometry, interruption, offscreen cancellation, tactic IDs, shield multiplier, and attack execution remain unchanged.
  - Accept: an offscreen complete squad stays Dormant and unshielded indefinitely; `0.74 s` visible is insufficient; `0.75 s` continuous visibility permits Gather; the first shield-capable Lock occurs only after the visible dwell plus authored Gather time. No additional live-enemy scan or dynamic per-frame container is introduced.
- [x] **6.3 Keep pursuit pressure during Chaser recovery.**
  - Change: replace only Chaser's mostly reverse recovery vector with a deterministic lateral peel that has no negative radial component. Keep Rammer reverse recovery, standoff retreat bands, engagement gates, wall recovery, local overlap separation, speeds, response constants, attack ranges, and cooldowns unchanged.
  - Accept: ordinary pursuit closes distance; Chaser recovery moves laterally rather than away; Rammer still creates reset distance; exact direction is deterministic for both strafe signs; speed and cadence ceilings remain unchanged.
- [x] **6.4 Give mobile ranged hull overlap a low, explicit consequence.**
  - Change: revise the contact contract so mobile `shooter`, `controller`, and `artillery_spotter` behavior roles use the existing relative swept-contact owner for `6` damage with a `1.0 s` per-enemy accepted-hit cooldown and existing player damage feedback. This includes their archetype variants such as Needle Drone through behavior-role mapping. Support roles, fixed structures, ordinary mines, ordinary Chaser movement outside its warned lunge, Rammer outside charge, and boss contact remain unchanged. A rejected hit leaves contact armed, matching persistent-contact receipt semantics.
  - Accept: endpoint, tangent, tunneling, rejected-hit, accepted-hit, cooldown, and pool-reuse fixtures pass; ranged projectile damage and commitment limits are unchanged; no duplicate contact owner or second full enemy scan appears.
- [ ] **6.5 Integrate, inspect, and record the changed contract.**
  - Change: update the product spec and focused source tests, then capture normal Stage 3/4 and Stage 7/8 first-contact sequences at Dormant -> Gather -> Lock plus one Chaser lunge/recovery and one ranged hull impact. Review standard and reduced-motion output against the existing visual system; create no new raster, ring, label, or formation overlay.
  - Accept: the player first sees ordinary movement before the formation transition; shields remain one body-attached mint boundary and never appear as a separate arrival bubble; Chaser no longer reads as sustained retreat; ranged hull impact produces normal damage feedback; Korean/English surfaces and draw/batch ceilings are unchanged.
- [ ] **6.6 Run bounded regression and quality gates.**
  - Change: run collective-tactic, movement-policy, local-steering, enemy-contact, encounter-pacing, update-schedule, actor-visual, combat-renderer, source/import, visual-authority, Web export/smoke, and `git diff --check` gates. Run one short same-workload Stage-10 performance diagnostic only if the contact/tactic diff changes measured hot-path work; do not reopen the density staircase.
  - Accept: focused behavior checks pass, no new recurring allocation or per-enemy SceneTree/NavigationAgent owner exists, cap 48 workload truth is preserved, and any performance verdict is labeled only for the exact tested build and scenario.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | One changed-owner validator plus `git diff --check` | After a coherent local change | Relevant source changes |
| Campaign equivalence | Stage continuity/transition/report/boss/reward/capture validators | Phase 2 and each Phase 3 slice pass | Campaign owner or data changes |
| Rendered flow gate | Korean/English supported sizes, 200% text, odd/even transition, Stage 10 Result | Phase 3 integration passes | UI/snapshot/theme/localization changes |
| Performance diagnostic | One 10-second warmup + 30-second same-scenario comparison | A measured candidate is coherent | Candidate or hypothesis changes |
| Native authority | Existing 10-second warmup + 60-second production replay contract | Focused implementation is complete, clean, quiet, and user-aligned | Runtime/resource/workload input changes |
| Capacity staircase | 48 then 64/96/128 with early stop | Native 48 passes and user alignment is current | Runtime/scenario input changes |
| Web final | Production export, built-Web interaction, then same-build performance gate | Native/source gates pass | Web/runtime/resource input changes |

Validation rules:

- Run the narrowest check that proves the current task.
- Do not repeat a passing broad gate merely to regain confidence.
- Treat fixture screenshots as visual/state evidence only; they do not prove normal-play difficulty.
- Treat native and Web, functional and performance, render and simulation verdicts separately.
- Stop a timing run on dirtiness, focus loss, throttling, or unrelated heavy processes.

Verified command shapes:

- Godot runtime: `./tools/godot.ps1 --version` reports `4.7.1.stable.official.a13da4feb`.
- Focused scripts use `./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_upgrade_system.gd`; substitute another verified file under `tools/validation/` only when that task names it.
- Web export: `./tools/export_web.ps1`.
- Visual authority: `./tools/validation/validate_cardborne_visual_authority.ps1`.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| Odd-stage no-boss completion leaves partial boss state | Reject the transition slice and restore the last passing campaign checkpoint | Do not add special-case cleanup in UI |
| Ten-stage total quota, XP, or pickup supply differs from the locked budget | Stop and correct data generation/spec together | Do not compensate with hidden runtime multipliers |
| Current-HEAD cap 48 fails | Keep shipping cap 48 blocked and fix only the measured owner | Do not attempt 64 or weaken thresholds |
| Native 64 passes but built-Web 64 fails | Keep shipping cap 48 and record Web as the limiting target | Do not ship native-only density in the common campaign |
| Exact 64 passes everywhere | A separate product diff may set Stages 8-10 to 64 after updating workload/readability contracts | Do not proceed to higher shipping caps automatically |
| Selected owner contradicts historical expectations | Follow current eligible evidence and revise Task 4.3 owner | Do not preserve a hypothesis because it appears in an older audit |
| Extraction requires dual simulation authorities | Stop and redesign the boundary around commands/receipts | Never ship shadow and canonical mutation together |
| Threads, servers, GDExtension, custom Web templates, or dependencies become necessary | Stop and request a new approved contract | This plan does not authorize them |

Implementation-local discoveries may be handled inside the locked contract only when they cannot change visible behavior, ownership, architecture, performance thresholds, or acceptance.

## Risks

- Ten stage labels can falsely imply twice the content. The paired structure must be communicated through pacing, not flavor text or invented stage names.
- Stronger threat concurrency can become unreadable before it becomes difficult. Startup, attack-cap, radar, and escape-corridor checks are mandatory.
- A campaign extraction can become another shallow manager. Existing domain owners must receive policy; the facade must not merely forward every private field.
- Exact-near plus virtual-far increases authored pressure without representing distant individuals as live actors. Specs and telemetry must keep those terms distinct.
- The focused weapon/progression plan intentionally precedes this contract and owns a disjoint progress source. Other active-plan overlap remains lifecycle debt and is not changed without separate approval.

## Rollback and Safety

- Commit each phase coherently and keep task-owned changes separate from unrelated work.
- Roll back one rejected performance candidate without reverting accepted product/UI phases.
- Preserve the completed prerequisite's card IDs, weapon-owned stats, build cells, HUD contract, and early-XP curve.
- Keep five-stage behavior passing until the Phase 3 ten-stage data and transition path are complete; do not maintain both campaign modes in production afterward.
- Do not delete old evidence or active plans during implementation without explicit approval.

## External Sources

- [Godot 4.7 Performance monitors](https://docs.godotengine.org/en/4.7/classes/class_performance.html): process, physics, object, draw-call, texture-memory, and pipeline monitors are separate evidence.
- [Godot 4.7 profiler](https://docs.godotengine.org/en/4.7/tutorials/scripting/debug/the_profiler.html): attribute script/physics work before optimization.
- [Godot 4.7 general optimization](https://docs.godotengine.org/en/4.7/tutorials/performance/general_optimization.html): classify sustained slowdown, spikes, loading, CPU, and GPU before changing code.
- [Godot 4.7 threads](https://docs.godotengine.org/en/4.7/tutorials/performance/using_multiple_threads.html) and [thread-safe APIs](https://docs.godotengine.org/en/4.7/tutorials/performance/thread_safe_apis.html): thread lifecycle, locks, and active SceneTree restrictions make threading an escalation path.
- [Godot low-level servers](https://docs.godotengine.org/en/stable/tutorials/performance/using_servers.html): low-level ownership can reduce abstraction overhead, but synchronous readback and manual RID lifecycle add risk and are not the first measured fix here.
- [Godot 4.7 CharacterBody movement and collision](https://docs.godotengine.org/en/4.7/tutorials/physics/using_character_body_2d.html): engine bodies provide collision response but may perform multiple collision iterations; Phase 6 keeps the current packed simulation and existing relative sweep instead of converting every ordinary enemy to a SceneTree physics body.
- [Godot 4.7 Navigation obstacles](https://docs.godotengine.org/en/4.7/tutorials/navigation/navigation_using_navigationobstacles.html): dynamic obstacle updates and agent avoidance have meaningful processing cost; Phase 6 keeps the existing bounded eight-neighbor overlap cache and does not introduce full RVO avoidance.

## Decision Notes

- 2026-08-14: split weapon/default/shared-card/early-XP work into `2026-08-14-weapon-unlocks-and-early-level-pacing.md`; this contract begins only after that plan passes.
- 2026-08-14: choose ten short stages with bosses on even stages. This reaches Stage 10 without requiring ten bosses or doubling the total defeat/XP/item budget.
- 2026-08-14: keep initial exact density at 48. Increase challenge first through attrition, continuity, and bounded attack concurrency.
- 2026-08-14: treat `VehicleRun` as a facade target, not a file-size target. Campaign ownership is extracted before ten-stage work; the current measured hot owner is extracted before any higher-cap claim.
- 2026-08-14: Phase 2 established validated command/receipt ownership in StageFlow, StageTransitionRuntime, BossRuntime, and RewardRuntime; capture-only mutation now uses VehicleCampaignFixtureFacade. Ten focused campaign/report/reward/capture validators passed. `VehicleRun` is 7,306 lines and 286 functions after removing its duplicate direct continuation path; file size remains a secondary signal for the later measured extraction.
- 2026-08-14: the visual authority pair was completed before screenshot review: `docs/design/VISUAL_SYSTEM.md` was read in full; the canonical sheet was inspected at original 1448x1086 detail; observed SHA-256 `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889` matched the required value. No raster was created or edited, so actual image-reference input is not applicable and no asset approval is claimed.
- 2026-08-15: Stage 1 uses twelve one-squad arrival windows, each bounded to six units, because its exact live cap cannot truthfully reserve a standard four-squad window atomically. Stages 2-10 retain the shared three-window/four-squad structure; the generic scheduler validator uses Stage 2 while Stage 1's special contract is checked by encounter-pacing and catalog validators.
- 2026-08-15: each stage owns two recalls and five repairs. Odd stages provide 250 Hull and even stages 240 Hull, so every pair preserves the previous 490-Hull supply without hidden transition compensation.
- 2026-08-15: Phase 3 completed all ten-stage data, paired encounter/economy, odd/even completion, attrition/concurrency, and retained-consumer migrations. Focused source checks prove ten profiles, quota 400, XP 1968, 29 upgrades/final level 30, five even-stage bosses, ten ordered Result records, recovery and cap contracts, Korean/English copy, guidebook compatibility IDs, capture fixtures, and integrated run ownership.
- 2026-08-15: Phase 4 selected enemy scheduling from eligible Stage-10 evidence rather than render work. Baseline commit `3da291a2` passed native cap 48 at physics p95/p99 `5.294/6.649 ms` but failed built Web at `8.2/9.6 ms`; Web frame, workload, viewport, focus, draw, and batch checks passed.
- 2026-08-15: commit `67b4b9ce` made `VehicleEnemyUpdateSchedule` publish reusable ordinary-work flags and deltas, removed repeated live-path due queries from `VehicleRun`, and preserved 10/30/20 Hz cadence, critical 60 Hz work, ordering, pruning, and 6/32/40/48 actor receipt equality. The 30-second native comparison improved physics p95 `5.294→3.746 ms` and enemy/grid p95 `3.356→2.392 ms`, so the candidate was retained.
- 2026-08-15: the retained candidate passed native 60-second cap-48 authority at physics p95/p99 `4.510/5.484 ms`, but built Web cap 48 still failed at `8.1/9.3 ms` with 60 FPS and valid workload. The density staircase therefore stopped before 64; shipping remains exact cap 48 and no 64/96/128 claim is made.
- 2026-08-15: Phase 5 source/import/export gates passed: the current Web export, 16 focused Godot validators, visual-authority hash/dimension validation, and `git diff --check` are green. The document-authority gate is red only because the completed predecessor remains at `.agents/execplans/2026-08-14-weapon-unlocks-and-early-level-pacing.md`; deleting that retired plan requires explicit user approval and is not performed silently.
- 2026-08-15: native rendered evidence completed at Korean 1280x720 (126 captures) plus English 1280x720, Korean 960x540 at 200% text, and English 1920x1080 (41 core captures each). Upgrade acquisition/enhancement, one active slot, three automatic slots, Stage N/10 HUD, odd/even stage fixtures, Stage 10 boss, and ten-entry Result remain readable. At 960x540/200%, offer cards deliberately use one vertical scroll viewport while the Equip action remains fixed and reachable; geometry validation proves no horizontal overflow or hidden wrapped line.
- 2026-08-15: the built Web interaction smoke completed at 1280x720 through Deployment -> gameplay -> Pause -> Abort -> Deployment, then loaded exact 960x540 and 1920x1080 canvas sizes with zero console errors. Canonical continuity/boss/result validators and the Stage 10 Result capture prove the deterministic ten-stage completion path; a human-played normal ten-stage clear was not substituted by fixture evidence and remains an explicit release-playtest item.
- 2026-08-15: durable product and performance owners now state the ten-stage paired campaign, partial transition recovery, exact cap 48, native pass, built-Web physics failure, and early stop before 64. Root operating guidance no longer identifies the current product as five stages.
- 2026-08-15: ordinary arrivals were verified as independently allocated rather than line/circle spawns. The visible formations come from collective tactic slots, and those tactics can begin Gather while offscreen. Phase 6 therefore preserves the authored formations but adds a `0.75 s` continuous-visible arming gate.
- 2026-08-15: new enemies begin unshielded. The apparent spawn shield is support or collective Lock/Execute state already active at first sight; tactic arming is corrected at the simulation owner and no new visual asset or arrival bubble is added.
- 2026-08-15: Chaser recovery changes from reverse movement to a deterministic lateral peel; Rammer reverse, ranged standoff retreat, wall recovery, engagement gates, and overlap separation remain distinct and unchanged.
- 2026-08-15: mobile ranged hull overlap changes from damage-inert to a low `6`-damage, `1.0 s` accepted-hit cooldown contract in the existing relative-sweep owner. This is an explicit product revision, not a claim that the former implementation violated its tests. Full CharacterBody/NavigationAgent conversion and RVO avoidance were rejected because Godot's collision/avoidance path adds per-agent physics/navigation work and current Web cap-48 physics already fails its release threshold.
- 2026-08-15: Tasks 6.1-6.4 are implemented in their existing owners. Seven focused validators pass: collective tactics, movement policy, local steering, enemy contact, causal diagnostics, encounter pacing, and update schedule. The post-pass caught and corrected an intermediate regression that had replaced Guard/Splitter contact; their original `12` damage and `0.8 s` cooldown remain intact beside the new ranged contract.

## Open Questions

No material implementation decision remains open. A future weapon-policy change, new boss, or shipping cap above the gated 64 branch requires a contract revision and explicit approval.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 6 ordinary-enemy first-contact correction. Phase 5 lifecycle debt remains blocked only on predecessor retirement approval and the named human complete-run release playtest.
- Next task: complete Task 6.5's tactic transition capture and trajectory/contact receipts, then run Task 6.6's bounded integration gates without reopening the density staircase.
- Last completed gate: seven focused Phase 6 behavior validators after the Guard/Splitter preservation correction.
- Update rule: after a task acceptance check passes, record concise evidence, check the task, and advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check and named guard/gate passes.
- The related weapon/progression contract is complete and remains passing.
- A deterministic run contains ten stages, five even-stage bosses, ten Result records, total quota 400, final level target 30, and the locked recovery/item budgets.
- Fixed Hard is demonstrably harder through the locked attrition/concurrency changes without an unreadable or unfair attack state.
- Shipping density has an exact native/Web evidence label and never exceeds the last passing gated cap.
- `VehicleRun` no longer owns campaign policy and no selected hot-owner implementation remains duplicated inside it.
- Durable behavior is incorporated into its owning specs and this plan becomes `done` only after implementation.

Replan when:

- Current eligible performance evidence selects an owner outside the predetermined simulation branches.
- Ten-stage play evidence shows the locked total run budget cannot meet the intended pacing without changing quota, XP, or content scope.
- A new boss, card economy, save migration, dependency, native extension, thread model, or Web template becomes necessary.

Do not replan or stop for:

- Implementation-local mechanics inside the locked owners.
- A passing check whose relevant inputs have not changed.
- A normal capacity-staircase early stop at the first failing tier.

Anti-rework rules:

- On start or resume, read this contract and inspect the worktree only enough to confirm the next unchecked task's inputs.
- Treat checked tasks and recorded passing evidence as complete unless their inputs changed.
- Rerun a failed check only after a relevant implementation change or new causal hypothesis.
- If reality contradicts a material decision, stop that branch and revise this contract instead of letting the executor redesign it ad hoc.
