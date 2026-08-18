---
type: plan
status: active
created: 2026-08-18
scope: Persistent eight-boss field progression, late-run pressure, boss identities, primary attributes, neutral facilities, and verified Web publication
related:
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/product/vehicle_upgrade_catalog.md
  - ../../docs/product/vehicle_weapon_balance_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../research/performance/cardborne-runtime-architecture-audit.md
---

# Continuous Field Combat Evolution - Execution Contract

The shipped run will remain one continuous physical field through all eight boss cycles: boss cleanup advances only the profile used by future ordinary spawns, while live ordinary enemies, terrain, facilities, pickups, exploration, and player/combat state remain untouched. Later cycles will shift durability and bounded speed pressure, bosses will attack about 1.5 times as often, Vector Loom and Pulse Core will receive genuinely executable identity mechanics without image replacement, primary rounds will accept any two distinct attributes with a Cryo shatter payoff, and the neutral-facility roster will become Repair/Cryo/Weakpoint/Lava at the existing three-per-field placement count. After final validation, the task-owned commits will be pushed to `origin/master`; the existing pinned GitHub Actions workflow will publish the verified Web build to itch.io.

## Purpose

- Objective: Remove boss-triggered map resets and make progression change only future combat composition, while completing the requested combat, attribute, facility, and late-boss redesign.
- Deliverable: Updated canonical specs, gameplay/runtime owners, Korean/English copy, one approved Lava facility raster identity, focused validators, final Web export evidence, scoped commits, GitHub push, and successful itch.io workflow deployment.
- Completion state: All eight cycles run on one unchanged field state; requested mechanics are validated; `origin/master` contains the commits; the matching GitHub Actions run succeeds through the itch.io publication step.

## Scope and Boundaries

In scope:

- Keep the internal eight-cycle/boss order for quotas, reporting, HUD progress, boss selection, and result construction, but remove its authority to reconfigure the physical field after a boss dies.
- Preserve every live non-boss enemy across cycle advancement. Only enemies admitted after advancement use the next cycle's role pool and spawn-time stat curve.
- Replace ordinary relative health and speed curves with bounded `1.00 -> 2.00` health and `1.00 -> 1.30` speed arcs; keep early steps at or below 20% from cycle 1 and prefer health over speed.
- Preserve the current boss base health/image set and approximately current late health/speed ceiling; make attack downtime about two-thirds of current values without shortening startup warnings.
- Replace Vector Loom and Pulse Core's ineffective direct-pattern entries with executable, collision-truthful mechanics and retain their existing boss PNG identities.
- Replace damage/utility attribute ownership with two generic acquisition-order slots holding any two distinct element cards; add a three-stack Cryo shatter that consumes the stacks and applies authored bonus damage.
- Replace Barrier and Gravity facility outcomes with Lava, leaving Repair, Cryo slow, and Weakpoint vulnerability. Keep three deterministic facility placements on the persistent field.
- Make active Lava emit fixed 0.50-second neutral damage ticks to the player and all targetable enemies inside its exact radius, including bosses; it grants no quota, XP, or player damage credit.
- Update product/design contracts, guidebook/readouts, localization, manifests/catalogs, capture fixtures, and focused validators that own these behaviors.
- Build, validate, push, and monitor the repository's pinned release workflow through itch.io publication.

Out of scope:

- New stages, maps, boss images, difficulty modes, cards, attribute IDs, facility placement count, encounter capacity, input actions, save migration, or performance optimization.
- Deleting unrelated legacy raster files solely because their runtime semantic IDs are retired; removal requires a separate exact asset-retirement decision.
- Changing boss startup warning duration, player weapon damage outside Cryo shatter, or ordinary enemies that are already alive when a cycle advances.
- Requalifying global native/Web release performance. Functional and visual release checks are required; no broad performance claim will be made from them.

Constraints and invariants:

- Boss death immediately retires only boss-owned adds, projectiles, and denied zones. It must not call backdrop, tactical-layout, facility, pickup, blocker, terrain, pursuit-field, camera-limit, exploration, or player reset paths.
- `current_stage_index/current_stage_id` remain internal compatibility names until a later bounded terminology refactor; their post-boss mutation must not imply physical stage ownership.
- New ordinary enemies snapshot the current cycle's role and stat profile at creation. Existing actor state is not recomputed when the index changes.
- Ordinary curves are locked to health `[1.00, 1.10, 1.20, 1.35, 1.50, 1.65, 1.82, 2.00]` and speed `[1.00, 1.04, 1.08, 1.12, 1.17, 1.21, 1.26, 1.30]`; existing ordinary damage progression remains unchanged.
- Boss base health remains `26000`; existing boss health/damage/move/coverage arrays remain unchanged. Existing cadence scales are multiplied by `0.67`, and that scale applies to direct read gaps, direct recovery, and autonomous intervals; startup and active windows remain unchanged.
- Vector Loom identity is a collision-true crossing weave: paired translating walls with one readable gap are followed by an orthogonal pass whose gap is on a different axis. Pulse Core identity is an alternating safe-sector pulse followed by a rotating sparse radial volley. Both must run through explicit direct and autonomous handlers and keep the documented escape-margin rules.
- Attribute slots are `slot_0/slot_1` in first-acquisition order. A third distinct element is incompatible; leveling either equipped element stays compatible. Thermal, Toxin, and Cryo may form any pair.
- Cryo shatters on the third newly applied Chill stack, clears Chill, and deals `18/28/42` neutral-to-status bonus damage at Cryo levels 1/2/3 through the player-owned Cryo telemetry route without recursively applying payloads.
- Facility roster is exactly Repair, Cryo, Weakpoint, Lava. Lava uses radius `1080`, duration `12s`, tick interval `0.50s`, and `8` damage per tick. Facility count remains three and outcome selection remains deterministic.
- No SVG/ImageMagick geometry will author the Lava visual. The canonical style sheet must be passed as an actual ImageGen reference. Runtime integration is prohibited until BK approves the exact generated Lava PNG.
- Heavy checks, rendered game launch, full validator sweep, Web export, and publication run only after all implementation phases and exact Lava approval are complete. Inner-loop checks are limited to source inspection, `git diff --check`, and narrow headless validators needed to close a phase.
- No dependency, engine, workflow-threshold, encounter-capacity, or release-secret change is allowed.

Destructive or irreversible actions:

- `git push origin master` changes the shared GitHub branch and automatically starts the release workflow; that workflow publishes the verified Web artifact to itch.io. The user explicitly requested both actions in this conversation.
- No local destructive asset deletion is planned.

Exact actions requiring owner or user approval:

- BK must approve the exact generated Lava facility PNG before it is added to the production manifest or runtime catalog. Style compliance alone is not approval.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Boss death changes the visible map | `VehicleRun._configure_next_stage_world()` replaces `_active_tactical_layout`, reconfigures backdrop/facilities/blockers/pursuit, and repopulates pickups after boss cleanup. Existing ordinary actors are not cleared. | `scripts/vehicle/vehicle_run.gd`; `vehicle_stage_transition_runtime.gd` | Retain report/terminal transition sequencing but replace next-world configuration with an internal cycle-profile advance only. | 1.1-1.4 |
| Only future ordinary spawns should change | `VehicleEncounterRuntime.configure()` consumes cycle packet data; `_make_enemy()` snapshots the current curve into new actors. `_continuation_packets()` already reserves opening slots around survivors. | `vehicle_run.gd`; `vehicle_combat_stages.gd`; encounter validators | Reconfigure encounter packets against the persistent tactical layout and leave live ordinary actors untouched. | 1.2-1.4 |
| Late ordinary growth | Current runtime curve is health `1.00 -> 3.10`, speed `1.00 -> 1.07`; current product spec is stale and differs. | `vehicle_stage_difficulty.gd`; `vehicle_game_spec.md` | Use the locked health/speed arrays above and update both runtime and canonical spec. | 2.1-2.2 |
| Boss stat and cadence request | Current boss health reaches `2.05x`, speed reaches `1.276x`, and cadence scaling affects read/autonomous gaps but not direct recovery. | `vehicle_stage_difficulty.gd`; `vehicle_boss_runtime.gd` | Preserve boss stat arrays; apply the current cadence curve times `0.67` to every attack downtime owner while leaving warnings/active time intact. | 2.3-2.4 |
| Boss 7/8 lack effective direct identities | Their sequences contain `moving_walls`, `wedge_rings`, and `spiral`, but `VehicleBossRuntime.update_active()` has no direct execution branch for those kinds; only autonomous dispatch recognizes them. | `vehicle_boss_patterns.gd`; `vehicle_boss_runtime.gd`; `vehicle_run.gd` | Publish explicit services receipts for the two locked identities from both direct and autonomous sequencing, with focused execution tests. | 3.1-3.4 |
| Two unrestricted primary attributes | Build/catalog currently owns one `damage` and one `utility` slot; payload reads those separate roots. | `vehicle_run_build.gd`; `vehicle_upgrade_catalog.gd`; `vehicle_primary_payload_profile.gd` | Replace type slots with two ordered generic element slots and retain a maximum of two distinct elements. | 4.1-4.3 |
| Cryo needs offense | Chill currently only stacks slow/duration and `StatusRuntime.apply()` returns no outcome. | `vehicle_status_runtime.gd`; `cryo_slow.tres`; projectile hit route in `vehicle_run.gd` | Return an explicit shatter receipt at three stacks, clear Chill, and route fixed level damage once. | 4.4-4.5 |
| Facility effects overlap | Current five outcomes are Repair, Barrier, Gravity, Cryo, Weakpoint; three are placed per cycle and the full runtime is reset each transition. | `vehicle_mystery_device_runtime.gd`; `vehicle_world_visual_catalog.gd`; `VISUAL_SYSTEM.md` | Keep only Repair/Cryo/Weakpoint plus Lava, keep three placements for the persistent run, and tick Lava through bounded runtime events. | 5.1-5.5 |
| Lava visual authority | Facilities require one authored role symbol visible from placement. No approved Lava identity exists; repurposing Gravity/Barrier would be semantically false. | `VISUAL_SYSTEM.md`; canonical sheet hash `96ccf5...f002889`; manifest/catalog inspection | Generate one grounded raster candidate, show it for exact BK approval, then integrate only the approved bytes. | 5.2-5.4 |
| Release path | `master` push runs all validators, rendered capture, Web export/static release check, built-Web boot, then pinned Butler `v15.30.0` push to `itchioprofile1351321/iron-breakthrough:html5`. GitHub CLI is authenticated. | `.github/workflows/vehicle-run-validation.yml`; `gh auth status`; `origin` remote | Commit locally, run the declared final local gate once, push `master`, then monitor the matching Actions run and itch publish step. | 6.3-6.5 |
| External evidence | Gameplay authority and release procedure are fully repository-owned and locally pinned. Generic external design advice cannot override the user's requested behavior; external itch instructions would be weaker than the exact workflow. | Canonical specs, runtime owners, workflow | No external research is needed for this self-contained implementation. | all |

Rejected alternatives:

- Clearing or restatting survivors at boss death: violates the explicit continuity requirement.
- Keeping per-cycle facility/pickup rerolls but hiding the transition: still mutates map composition.
- Renaming an existing Gravity or Barrier PNG as Lava: breaks semantic visual truth.
- Merely reordering boss 7/8 data: does not fix the missing direct execution branch.
- Adding a third Cryo-only utility slot: preserves the restriction the user rejected.
- Reducing encounter counts or capacities to offset added mechanics: unauthorized product/performance tradeoff.

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership, safety, and validation decision is closed except the explicitly required exact Lava PNG approval gate.
- Godot 4.7.1, repository validators/export scripts, authenticated Git/GitHub access, the release workflow, and the itch.io target are available. No local Butler installation is required.
- Remaining unknowns are implementation-local and cannot change this contract.

## Tasks

### Phase 1: Make boss cycles advance combat without replacing the field

Goal: Boss cleanup changes only the future ordinary spawn profile and boss progression index.

Preconditions:

- Discovery Closure Gate passed.

Source owners: `scripts/vehicle/vehicle_run.gd`, `scripts/vehicle/vehicle_stage_transition_runtime.gd`, `scripts/encounters/vehicle_stage_flow.gd`, `scripts/vehicle/stages/vehicle_combat_stages.gd`, continuity validators

- [x] **1.1** Separate persistent field state from cycle-profile advancement.
  - Change: remove next-cycle backdrop/layout/facility/pickup/blocker/pursuit/camera reconfiguration from the boss continuation commands.
  - Accept: the field/tactical fingerprint, facility snapshot, pickup snapshot, terrain, exploration, player transform, and live ordinary IDs remain byte/value equal across advancement.
- [x] **1.2** Reconfigure future encounter admissions only.
  - Change: select next-cycle packets, role pool, quota, and boss profile using the new internal cycle index while reusing the current tactical layout and anchors.
  - Accept: a survivor keeps its role, health/max health, speed, position, and status; the first admitted post-transition enemy comes from the next cycle's packet/role contract.
- [x] **1.3** Preserve combat and reward state through advancement.
  - Change: retain projectiles, XP, build, cooldowns, facilities, pickups, exploration, player velocity/aim, and active field effects; reset only cycle telemetry/quota/boss owners.
  - Accept: focused continuity fixtures prove no disallowed owner changed and no ordinary actor was retired.
- [x] **1.4** Update canonical flow wording and regression validators.
  - Change: define cycles as combat profiles over one persistent map in product/design contracts; remove claims that facilities, pickups, or tactical arrangements refresh after boss death.
  - Accept: document authority and single-field/continuity validators agree with runtime behavior.

Batch gate:

- Run only the focused continuity, stage-flow, transition-runtime, and single-field validators once after Phase 1 code and tests settle.

### Phase 2: Bound late-run ordinary growth and increase boss attack frequency

Goal: Early actors remain near baseline while later ordinary enemies become primarily tougher, and bosses retain current stats while reducing downtime.

Preconditions:

- Phase 1 acceptance checks and batch gate pass.

Source owners: `scripts/enemies/vehicle_stage_difficulty.gd`, `scripts/enemies/vehicle_enemy_speed_profile.gd`, `scripts/bosses/vehicle_boss_runtime.gd`, difficulty/guidebook validators

- [x] **2.1** Apply the locked ordinary health/speed curves.
  - Change: replace current relative curves and their stale descriptions without changing existing ordinary damage progression or capacity.
  - Accept: cycles 1/2/3 are `1.00/1.10/1.20` health and at most `1.08` speed; cycle 8 is exactly `2.00` health and `1.30` speed.
- [x] **2.2** Prove spawn-time snapshot behavior.
  - Change: extend validators so a pre-advance survivor retains old stats and a post-advance actor receives new stats.
  - Accept: no loop mutates existing actors when the cycle index changes.
- [x] **2.3** Preserve boss stats and scale all downtime owners.
  - Change: keep current base/health/damage/speed/coverage arrays; multiply cadence scales by `0.67` and apply them to direct recovery as well as read/autonomous gaps.
  - Accept: startup and active seconds are unchanged; each boss's downtime owners are approximately two-thirds of their prior values.
- [x] **2.4** Synchronize guidebook/spec/stat tests.
  - Change: update canonical numeric contracts and effective-value adapters.
  - Accept: gameplay data, guidebook rows, and validators expose one curve set.

Batch gate:

- Run the focused difficulty, boss-runtime, boss-pattern timing, and guidebook-stat validators once.

### Phase 3: Give Vector Loom and Pulse Core executable identities

Goal: Bosses 7 and 8 use distinct, new mechanics in direct and autonomous pressure without replacing their images.

Preconditions:

- Phase 2 acceptance checks and batch gate pass.

Source owners: `scripts/bosses/vehicle_boss_patterns.gd`, `scripts/bosses/vehicle_boss_runtime.gd`, `scripts/vehicle/vehicle_run.gd`, telegraph/denied-zone presentation owners, boss validators

- [x] **3.1** Implement Vector Loom's crossing weave.
  - Change: add an explicit event/handler that commits one paired translating wall pass and a later orthogonal pass with distinct collision-true gaps.
  - Accept: both direct and autonomous sequences execute it; safe gaps and warning geometry match damage geometry; no reused Archive Cross remains in Loom's direct identity slots.
- [x] **3.2** Implement Pulse Core's alternating pulse.
  - Change: add an explicit event/handler for alternating safe-sector pulse geometry followed by a rotating sparse radial volley.
  - Accept: direct and autonomous sequences execute it; the safe sector is readable before damage and the projectile volley does not duplicate Mirror Cross.
- [x] **3.3** Preserve warning, capacity, and image contracts.
  - Change: keep boss PNG IDs, fixed stores/batches, minimum warning, escape margin, and boss-owned cleanup.
  - Accept: no new boss raster or unbounded node/projectile/zone owner is introduced.
- [x] **3.4** Add execution-level identity tests.
  - Change: validate service calls/zone receipts, sequence coverage, collision footprints, and cleanup for both bosses.
  - Accept: a test fails if either boss returns to unsupported direct kinds or generic-only identity.

Batch gate:

- Run focused boss pattern/runtime/identity/readability/eight-cycle validators once; no rendered game launch yet.

### Phase 4: Replace typed attribute slots and add Cryo shatter

Goal: Any two distinct primary attributes can coexist, and Cryo supplies both stacking control and a three-stack damage payoff.

Preconditions:

- Phase 3 acceptance checks and batch gate pass.

Source owners: `scripts/cards/vehicle_run_build.gd`, `scripts/cards/vehicle_upgrade_catalog.gd`, `scripts/cards/vehicle_upgrade_definition.gd`, `scripts/cards/vehicle_build_snapshot_builder.gd`, `scripts/combat/vehicle_primary_payload_profile.gd`, `scripts/combat/vehicle_status_runtime.gd`, `data/cards/vehicle/*.tres`, localization and upgrade/status validators

- [x] **4.1** Replace damage/utility ownership with two generic slots.
  - Change: derive equipped attributes in first-acquisition order, expose `slot_0/slot_1`, and remove slot-kind compatibility as gameplay truth.
  - Accept: Thermal+Toxin, Thermal+Cryo, and Toxin+Cryo are legal; a third distinct element is rejected; existing attributes remain levelable.
- [x] **4.2** Build multi-attribute primary payloads.
  - Change: enable Thermal, Toxin, and Cryo independently from membership in the two equipped IDs; publish hybrid affinity when two persistent conditions coexist.
  - Accept: every legal pair applies both authored effects once without changing base primary-shot uniformity.
- [x] **4.3** Keep the two-slot build UI truthful.
  - Change: map element records to acquisition-order slots and update Korean/English category/copy that implies damage/utility exclusivity.
  - Accept: snapshots, Upgrade, Result, and Ship Status show the same two records and never label their slot type.
- [x] **4.4** Add the locked Cryo shatter receipt.
  - Change: on the third new Chill stack, return one `cryo_shatter` receipt, clear Chill, and apply `18/28/42` damage through the player Cryo damage route without reapplying statuses.
  - Accept: hits 1/2 slow, hit 3 damages and clears; the next hit starts at one stack; bosses retain the existing half slow/duration resistance but receive the authored shatter damage.
- [x] **4.5** Update data, localization, telemetry, and tests.
  - Change: add the shatter damage stat to Cryo's three levels and update catalog/status/offer/readout contracts.
  - Accept: catalog count and level-state totals remain unchanged, all late-level offers remain reachable, and ko/en coverage is complete.

Batch gate:

- Run focused upgrade catalog/system/snapshot/UI, primary payload, status stacking, damage policy, and localization validators once.

### Phase 5: Consolidate neutral facilities and add Lava

Goal: The persistent field places three facilities selected from Repair, Cryo, Weakpoint, and Lava; Lava visibly and mechanically damages everyone in range.

Preconditions:

- Phase 4 acceptance checks and batch gate pass.
- Canonical visual authority document was read completely; sheet was inspected at original detail; observed SHA-256 matches `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.

Source owners: `scripts/vehicle/vehicle_mystery_device_runtime.gd`, `scripts/vehicle/vehicle_run.gd`, `scripts/presentation/components/vehicle_world_visual_catalog.gd`, `scripts/presentation/vehicle_combat_renderer.gd`, `scripts/progression/vehicle_guidebook_stat_adapter.gd`, `scripts/ui/vehicle_guidebook_preview.gd`, gameplay manifest/assets, specs/localization/capture/validators

- [x] **5.1** Replace the facility behavior roster.
  - Change: remove Barrier and Gravity outcomes from deterministic selection and runtime modifiers; add Lava while retaining exactly three placements.
  - Accept: outcome IDs are exactly Repair/Cryo/Weakpoint/Lava and every ID appears in deterministic coverage without changing placement count.
- [x] **5.2** Generate one grounded Lava facility raster candidate.
  - Change: use ImageGen with the canonical sheet as the actual image reference and the binding facility constraints; create a 192x192 transparent authored industrial-SF heat-vent symbol with one dominant silhouette, 3-5 broad planes, dark perimeter, thermal accent, and no ring/text/scene.
  - Accept: intended-size and grayscale inspection show a unique heat-vent role distinct from Repair/Cryo/Weakpoint; provenance and reference-input evidence are recorded in this plan.
- [x] **5.3** Obtain exact BK approval and integrate only those bytes.
  - Change: present the candidate inline with its hash; after explicit approval, register `world/mystery_device_lava` in the manifest/provider/catalog/renderer/guidebook and retire old runtime semantic references without deleting unrelated source files.
  - Accept: the approved hash is recorded and every runtime consumer resolves the one asset ID.
- [x] **5.4** Implement bounded Lava ticks.
  - Change: the facility runtime emits a fixed-capacity tick receipt every 0.50 seconds while active; `VehicleRun` applies 8 neutral damage to the player and every targetable enemy within radius 1080.
  - Accept: player, ordinary enemy, and boss are hit; actors outside the radius, facilities, pickups, structures excluded by targetability, and expired Lava are not; no quota/XP/player damage credit is granted.
- [x] **5.5** Update visual/product contracts, copy, fixtures, and focused tests.
  - Change: replace five-facility/Barrier/Gravity wording and imagery with the four-role persistent-field contract and Lava countdown/tick feedback.
  - Accept: visual authority, manifest/provider/world visuals, facility runtime/integration, guidebook, capture, and localization validators pass.

Batch gate:

- Run visual-authority and focused facility/manifest/provider/renderer/guidebook/localization validators once after exact asset approval and integration; no full capture or Web export yet.

### Phase 6: Final audit, release validation, push, and deployment

Goal: Validate the complete integrated result once, commit it coherently, publish it, and verify the itch.io deployment workflow.

Preconditions:

- Phases 1-5 acceptance checks and batch gates pass.
- All task-owned production bytes and docs have stopped changing.

Source owners: task diff, `tools/validation/`, `tools/export_web.ps1`, `.github/workflows/vehicle-run-validation.yml`, Git history, GitHub Actions

- [x] **6.1** Run the task-owned code quality audit.
  - Change: apply `$codebase-quality-auditor` to multi-file/shared contracts and make only small safe task-scoped corrections.
  - Accept: no competing owner, stale typed-attribute/facility path, catch-all expansion, unbounded collection, or reachable unsupported boss kind remains.
- [ ] **6.2** Run the final local functional and visual gate once.
  - Change: run Godot import, all affected focused validators, the complete headless validator sweep, one native rendered capture set for boss/facility/UI evidence, visual authority validation, Web export, itch static release validation, and one built-Web boot using the guarded `codex` lane.
  - Accept: all checks exit zero; rendered evidence confirms unchanged field across a cycle, distinct boss 7/8 patterns, two generic attribute slots, and Lava readability; report exact partial-pass labels and make no global performance claim.
- [ ] **6.3** Commit only task-owned changes.
  - Change: create coherent scoped commits with short explanatory bodies; update this plan's checkboxes/evidence and mark it `done` only after deployment succeeds.
  - Accept: worktree contains no uncommitted task-owned changes and unrelated user changes were neither staged nor altered.
- [ ] **6.4** Push `master` and monitor the matching workflow.
  - Change: push to `origin/master`; use `gh run` to follow the run for the pushed commit through validation, Web build, built-Web boot, and `Publish verified Web build to itch.io`.
  - Accept: the matching Actions run concludes `success`; if it fails, inspect the exact step, correct only task-owned causes, rerun local relevant checks, commit, and push once more.
- [ ] **6.5** Verify publication identity and hand off.
  - Change: record pushed commit, Actions run URL/ID, itch target/version, and successful publication step in this plan and final response.
  - Accept: `origin/master` equals local HEAD and the workflow summary identifies `itchioprofile1351321/iron-breakthrough:html5` for that commit.

Batch gate:

- The GitHub Actions workflow is the authoritative remote release gate; do not manually invoke Butler or publish a different local artifact.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | `git diff --check`; direct source/data inspection; one named focused headless validator needed by the current task | After a phase-owned implementation settles | Relevant implementation input changes |
| Phase gate | The focused validator groups named under each phase | Phase tasks and task-level acceptance pass | A phase-owned input changes |
| Visual gate | `tools/validation/validate_cardborne_visual_authority.ps1` plus facility/manifest/render validators | Exact Lava asset is approved and integrated | Visual asset/manifest/catalog/spec input changes |
| Final local gate | Import; affected validators; all headless validators; one native capture; Web export; itch static validation; one guarded built-Web boot | All implementation phases pass and bytes stop changing | A final-gate input changes |
| Remote release gate | Existing `Vehicle Run Validation` run for pushed HEAD | One push after local final gate | A correcting commit is pushed |

Validation rules:

- Run the narrowest check that proves the current task.
- Run each named phase gate once after its owned tasks pass.
- Do not open the game, run broad performance scenarios, execute a complete capture, export Web, or start a built server before Phase 6.
- The final native capture and built-Web boot prove functional/rendered behavior only. They do not qualify native or Web release performance.
- Rerun a failed check only after a relevant implementation change or a new hypothesis can produce new evidence.
- Record known non-blocking warnings once instead of rediscovering them.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain any required approval before resuming | Do not choose a new product, architecture, dependency, UX, safety, or release contract implicitly |
| Exact Lava candidate is not approved | Keep it outside the production manifest, generate a revised grounded candidate from the same authority pair, and show it again | Do not deploy an unapproved visual or relabel an old facility asset |
| Persistent transition needs a field mutation for correctness | Preserve the current field and redesign only the cycle-local owner | Do not reintroduce boss-triggered facility/pickup/layout reset |
| Boss pattern exceeds fixed denied-zone/projectile capacity | Reduce authored simultaneous branches while preserving the locked identity and safe corridor | Do not raise capacity or drop collision/telegraph truth without approval |
| Full validator sweep reveals unrelated pre-existing failure | Prove it is unrelated with clean local evidence and report it; continue only if release workflow can still pass | Do not edit unrelated code or weaken a validator/threshold |
| GitHub/itch credential or target check fails | Stop publication, retain verified commits, and report the exact remote blocker | Do not change secrets, project target, workflow permissions, or publish elsewhere |
| Remote workflow fails on a task-owned defect | Fix the exact owner, rerun the relevant local check, commit, and push | Do not repeatedly rerun unchanged failed workflows |

Implementation-local discoveries may be handled inside the locked contract when they cannot change scope, visible behavior, ownership, architecture, safety, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 6 final local validation.
- Next task: 6.2 Run the one declared full validator/capture/Web release gate from the settled integrated bytes.
- Last completed gate: Phase 5 behavior pre-gate passed: mystery-device runtime and live map-mechanics integration validators. The deterministic roster is exactly Repair/Cryo/Weakpoint/Lava at three placements. Active Lava emits at most one fixed receipt per facility per simulation step with a bounded catch-up count, deals exact 8-damage half-second ticks to the player and targetable ordinary/boss actors inside radius 1080, bypasses transient player invulnerability without granting a new protection window, and grants no ordinary quota, XP, defeat statistic, outgoing telemetry, or player damage credit.
- Phase 5 integration gate: Godot 4.7.1 import passed; semantic provider, visual asset coverage, world visuals, semantic separation, visual replacement coverage, combat renderer, mystery-device runtime, live map mechanics, Guidebook, UI localization, and capture-driver validators all passed. The workbench deterministic build/check and validation report `current=87`, `final=96`, `authored=94`; visual-authority validation passed with the canonical sheet hash. The production PNG and its workbench TO-BE byte both match approved SHA-256 `8cbf4661d5154f3c7a76bfe07d5273e5742748a6e96f045588a9080fe6ce40e6`.
- Phase 6.1 audit: the task diff keeps cycle continuity in transition owners, difficulty curves in difficulty owners, primary attributes/statuses in build/payload/status owners, facility timers in `VehicleMysteryDeviceRuntime`, and presentation in manifest/catalog/renderer owners. `VehicleRun` adds only orchestration and collision-owned boss/facility application hooks. Late-boss receipts remain fixed at eight weave zones, two pulse zones, and one 12-projectile activation; Lava catch-up is bounded by the 12-second active lifetime and a 24-tick application clamp. No reachable Barrier/Gravity facility semantic ID, typed damage/utility attribute slot, unsupported boss identity kind, competing rule owner, or unbounded task-owned collection remains.
- Lava candidate evidence: built-in ImageGen used the canonical sheet as the actual reference input; observed reference SHA-256 `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`. BK rejected candidate v1 as too SVG-like and requested that v2 be regenerated from the game's art style with minimal detail; both remain evidence only and are ineligible for production integration. Candidate v3 retains one broad dark mechanical mass, one upper light plane, one lower shadow plane, and a central two-plane thermal vent with no separate modules or microdetail. Only the skill's chroma removal with despill/edge contraction and non-creative Lanczos resize to 192x192 followed generation. BK explicitly authorized using v3 to finish the plan on 2026-08-18 despite noting it was not the preferred final art direction. Candidate and production path SHA-256 are both `8cbf4661d5154f3c7a76bfe07d5273e5742748a6e96f045588a9080fe6ce40e6`; the 192x192 canvas, `[96,96]` pivot, semantic ID `world/mystery_device_lava`, and 288-world-unit footprint are unchanged from the facility contract.
- Visual authority evidence: `docs/design/VISUAL_SYSTEM.md` read completely; canonical sheet visually inspected at original detail; expected and observed SHA-256 `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`; original provenance is recorded by `$cardborne-visual-authority`. The canonical PNG was supplied through built-in ImageGen's actual `referenced_image_paths` input and v3 now has exact BK approval for this release.
- Update rule: after a checkpoint passes, record its concise evidence, check the task, and advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check passes.
- Every guard, phase gate, and final gate named by this contract passes.
- BK has approved the exact integrated Lava facility PNG and its hash is recorded.
- No placeholder or unresolved material decision remains.
- Canonical product/design documents match shipped behavior.
- Task-owned commits are on `origin/master`, the matching GitHub Actions run succeeds, and its itch.io publication step names the expected target and commit.
- Frontmatter status is changed to `done` only after remote deployment succeeds.

Replan when:

- A material discovery invalidates the locked contract.

Do not replan or stop for:

- Implementation-local mechanics already contained by this contract.
- A passing check whose relevant inputs have not changed.
- The absence of a new global performance qualification, because this task makes no such claim.
