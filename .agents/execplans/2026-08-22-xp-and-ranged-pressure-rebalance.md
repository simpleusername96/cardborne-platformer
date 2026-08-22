---
type: plan
status: active
created: 2026-08-22
scope: XP attraction progression, ordinary Emitter and Coordinator projectile pressure, hostile projectile readability, focused validation, Web export, and itch.io release
related:
  - ../../AGENTS.md
  - ../PLANS.md
  - ../design/DESIGN.md
  - ../cardborne-performance-engineering-policy.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - 2026-08-21-onboarding-progression-and-combat-pressure.md
---

# XP Collection and Ranged Pressure Rebalance - Execution Contract

Increase the useful baseline XP attraction distance without inflating the late-run ceiling, and make the two reachable ordinary projectile families more present and readable without changing pack composition, startup warning time, collision truth, hostile capacity, or boss pressure. The current branch was pushed before implementation; the initial exact-HEAD Web export passed, while itch.io deployment is blocked by the document-authority gate described below.

## Purpose

- Objective: Improve routine XP collection and ordinary ranged pressure while preserving the existing family-pack system, fair warnings, and bounded runtime load.
- Deliverable: Tuned progression and combat contracts, a larger ordinary hostile projectile presentation envelope, updated product/design authority, focused validator and render evidence, a successful Web export, scoped commits, branch push, and itch.io deployment when its document prerequisite is authorized.
- Completion state: The new values are runtime-owned and validated, the relevant Korean gameplay capture is visually approved, the exported Web bundle passes release checks, task-owned changes are committed and pushed, and the itch.io workflow succeeds or has one explicitly recorded owner-controlled blocker.

## Scope and Boundaries

In scope:

- Base XP attraction distance, Pickup Magnet card values, and the pickup half of `fallback_operations`.
- Direct projectile attacks of the reachable Emitter (`ordinary_lane_01`) and Coordinator (`ordinary_pulse_01`) families.
- Presentation-only size of ordinary and trait hostile projectiles rendered from the existing approved hostile-bolt raster.
- Focused gameplay, visual, capacity, document, Web export, git, and deployment validation.

Out of scope:

- Enemy pack ratios, family/trait membership, tier stats, encounter quotas, active actor caps, boss attacks, artillery ground impacts, legacy specialist fixtures, and projectile collision radii.
- New raster, SVG, shader, material, effect, warning-route geometry, dependency, or presentation batch.
- Global release-performance qualification while an unrelated Godot process makes a clean sample unavailable.

Constraints and invariants:

- The normal ten-pack bag remains `4 Pursuer / 3 Charger / 3 Emitter-Defender`, with three paired rosters exposing two Emitter-primary and one Defender-primary pack and one eligible Coordinator overlay per bag.
- Projectile startup warnings remain exactly `0.62 s` for Emitter and `0.80 s` for Coordinator. Predicted projectile routes remain hidden.
- Hostile projectile collision radii remain `6 / 7.5 / 9`; presentation size must not change collision or damage.
- Stage ranged-commit caps remain `3` for stages 1-5 and `4` for stages 6-12. Hostile capacity remains 120 with 24 boss-reserved slots, leaving 96 for ordinary fire. Combat presentation remains within the existing 80-batch ceiling and reuses the one hostile-projectile retained batch.
- The approved hostile-bolt raster and the visual authority sheet remain unchanged. Ordinary and trait shots may receive a presentation-only scale; boss shots remain on the existing base envelope.
- Korean and English surfaces remain complete. No copy key is required because existing numeric card/fallback formatting reads authored values.

Destructive or irreversible actions:

- Publishing the branch build to the existing itch.io `html5` channel is an authorized external release action from the user's request.
- Removing the obsolete completed ExecPlan named below is a tracked-file deletion and is not authorized until the user explicitly approves it.

Exact actions requiring owner or user approval:

- Delete `.agents/execplans/2026-08-22-enemy-pack-traits-and-boss-pressure-correction.md`, which has `status: done`, has no repository references, and currently makes `validate_document_authority.ps1` fail. Do not delete, move, or bypass the gate without explicit approval.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Base XP collection | `VehicleRun._update_experience` supplies a literal attraction base of 92; `VehicleExperienceRuntime` attracts at 520 units/s and collects only inside radius 34 | `scripts/vehicle/vehicle_run.gd`; `scripts/progression/vehicle_experience_runtime.gd`; `tools/validation/validate_vehicle_experience.gd` | Move the attraction base into `VehicleExperienceRuntime.BASE_ATTRACTION_RADIUS = 132`; keep speed 520 and physical collection radius 34 | 1.1, 1.3 |
| Pickup upgrade curve | Pickup Magnet adds 42 per level through 252; `fallback_operations` adds 18 on each odd rank | `data/cards/vehicle/pickup_radius.tres`; `scripts/cards/vehicle_run_build.gd`; `docs/product/vehicle_game_spec.md` | Use card totals `36/72/108/144/180/216` and odd-rank fallback `+14`. Effective attraction becomes 132 baseline, 168 at L1, 240 at L3, 348 at L6, and 488 at L6 plus all ten fallback pickup ranks, versus the old 92/134/218/344/524 | 1.2, 1.3 |
| Family and pack exposure | Normal composition owns a deterministic 4:3:3 bag, atomic Emitter-Defender pairs, and one eligible Coordinator overlay; collective runtime caps pack records at 32 | `scripts/encounters/vehicle_enemy_spawn_composition.gd`; `docs/product/vehicle_game_spec.md` | Do not change composition, pack tactics, traits, or actor admission | 2.3 |
| Reachable projectile roles | Emitter uses `ordinary_lane_01`; Coordinator uses `ordinary_pulse_01`. Emitter is ranged pressure; Coordinator is a rarer support leader that may also amplify its pack | `scripts/enemies/vehicle_enemy_archetypes.gd`; `scripts/vehicle/vehicle_run.gd`; prior active pressure plan | Tune these two roles independently; do not alter artillery or compatibility-only projectile roles | 2.1, 2.2 |
| Fair warning and attack reach | Emitter uses startup 0.62, speed 500, range 620, post-active recovery 0.72 and cooldown 0.78. Coordinator uses startup 0.80, speed 420, range 620 and recovery 1.50 | `scripts/combat/vehicle_attack_contract.gd`; `scripts/vehicle/vehicle_run.gd`; `scripts/encounters/vehicle_encounter_director.gd` | Emitter: speed 560, range 700, recovery 0.64, cooldown 0.70. Coordinator: speed 470, range 660, recovery 1.32. Preserve both startup warnings and line-of-sight checks | 2.1, 2.2 |
| Projectile lifetime and saturation | Effective speeds apply the unchanged 0.82 multiplier; projectile lifetime is 2.2 s. Ranged commits are capped at 3/4, ordinary projectiles at 96, and bosses retain 24 reserved slots | `scripts/combat/vehicle_attack_contract.gd`; `scripts/encounters/vehicle_encounter_director.gd`; `scripts/combat/vehicle_projectile_store.gd`; `tools/validation/validate_vehicle_run.gd` | Keep all caps. At maximum attack range, Emitter and Coordinator still provide more than 2 seconds from startup to edge-of-range impact; the four-slot Emitter throughput remains a small fraction of the 96-shot ordinary store | 2.3, 3.1 |
| Projectile readability | Hostile shots use approved `projectile/hostile_barbed_bolt`, white opaque modulation, collision-derived 4.20 presentation scale, and one 120-instance retained batch | `scripts/presentation/vehicle_combat_renderer.gd`; `scripts/vehicle/vehicle_stage_visual_profile.gd`; `tools/validation/validate_vehicle_projectile_readability.gd` | Add a 1.16 ordinary/trait presentation multiplier through the visual profile. Keep boss shots at 4.20, texture, opacity, collision, batch count, and capacity unchanged | 2.4, 3.2 |
| Visual authority | The canonical style sheet and design document were inspected before visual decisions and refreshed after the authority edit | Sheet SHA-256 `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`; pre-edit visual document SHA-256 `c8dde49b2506d01b4ff298622b0bf31a233f141c4ea609d8a42a7a17a01fb560`; post-edit visual document SHA-256 `982094469298053576d4b62308e7ba81c051538fb400a4847a9f0138b533ec16`; both complete document forms and the original-detail sheet were inspected | Preserve danger role, opaque core/contour, code-scaled approved raster, collision/presentation separation, and no predicted route; reuse the refreshed receipt while these hashes and scope remain current | 2.4, 3.2 |
| Performance evidence | Runtime is bounded, but an unrelated Godot capture process is active, so a new sample would not qualify as clean release-performance evidence | `.agents/cardborne-performance-engineering-policy.md`; `.agents/research/performance/cardborne-runtime-architecture-audit.md`; process inspection | Make no global performance claim and run no misleading sample. Prove unchanged caps/batches statically and through focused integration checks; run one final Web export/release validation | 3.1, 3.3 |
| Remote and deployment | Branch `feat/general-uiux-refinement` was pushed. Exact-HEAD Web export and itch release-size validation passed. GitHub workflow run `32564272222` failed before upload because a done plan remains under active `execplans` | git push output; `.github/workflows/vehicle-run-validation.yml`; failed workflow log; document validator source | Finish implementation and push new commits. After deletion approval, remove the stale plan, pass document authority, dispatch `publish=true`, and require successful itch upload | 3.4 |

Rejected alternatives:

- Raising `HOSTILE_PROJECTILE_SPEED_MULTIPLIER` would also change bosses and unrelated projectile roles, so role-owned base speeds change instead.
- Raising collision radii would make visual clarity change hit fairness, so collision truth remains fixed.
- Raising ranged-commit or projectile caps would increase simultaneous pressure and load; cadence changes stay inside current limits.
- A new raster, outline batch, warning ring, or predicted route would add visual or performance scope without being needed for this request.
- Keeping the old card and fallback values on top of the larger base would over-inflate the late-run collection ceiling.

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership, safety, and validation decision is closed.
- Required tools and dependencies are available. Godot 4.7.1 is owned by `./tools/godot.ps1`; the current branch export path and itch workflow were already exercised.
- Remaining unknowns are implementation-local and cannot change this contract. The completed-plan deletion is a named deployment prerequisite, not an implementation design decision.

## Tasks

### Phase 1: XP collection curve

Goal: Make ordinary XP drops start returning to the player earlier while keeping the final card state nearly unchanged and reducing the fallback-only ceiling.

Preconditions:

- Discovery values above remain current.

Source owners: `scripts/progression/vehicle_experience_runtime.gd`, `scripts/vehicle/vehicle_run.gd`, `data/cards/vehicle/pickup_radius.tres`, `scripts/cards/vehicle_run_build.gd`, `tools/validation/validate_vehicle_experience.gd`, `tools/validation/validate_vehicle_upgrade_system.gd`, `docs/product/vehicle_game_spec.md`

- [x] **1.1** Base XP attraction starts at 132 units
  - Change: Publish the base in the progression runtime and consume it from the run owner; keep collection radius and attraction speed unchanged.
  - Accept: A shard outside the old 92-unit radius but inside 132 begins attraction, while a shard beyond 132 does not.
- [x] **1.2** Pickup upgrades use the rebalanced curve
  - Change: Author the six card totals and the +14 fallback pickup increment, including exact previews.
  - Accept: Runtime totals are 168 at L1, 240 at L3, 348 at L6, and 488 after all pickup fallback ranks; dash fallback behavior is unchanged.
- [x] **1.3** Product and validators state the same XP contract
  - Change: Update the accepted product spec and replace stale three-level assertions with the six-level curve.
  - Accept: Focused experience and upgrade validators pass with exact current values.

### Phase 2: Ordinary ranged pressure and readability

Goal: Make Emitter and Coordinator fire more credible, readable projectiles without changing family composition, warning windows, collision, boss attacks, or caps.

Preconditions:

- Phase 1 acceptance checks pass.

Source owners: `scripts/combat/vehicle_attack_contract.gd`, `scripts/vehicle/vehicle_run.gd`, `scripts/vehicle/vehicle_stage_visual_profile.gd`, `scripts/presentation/vehicle_combat_renderer.gd`, `tools/validation/validate_vehicle_attack_contract.gd`, `tools/validation/validate_vehicle_projectile_readability.gd`, `tools/validation/validate_vehicle_combat_renderer.gd`, `docs/product/vehicle_game_spec.md`, `docs/design/VISUAL_SYSTEM.md`

- [x] **2.1** Emitter and Coordinator own exact role-specific attack values
  - Change: Put range, recovery, and Emitter cooldown beside speed and startup in `VehicleAttackContract` using the locked values.
  - Accept: Emitter reports 560 speed, 700 range, 0.64 recovery, and 0.70 cooldown; Coordinator reports 470 speed, 660 range, and 1.32 recovery; startups remain 0.62/0.80.
- [x] **2.2** Runtime consumes the role-owned contract
  - Change: Remove the corresponding range/recovery/cooldown literals from `VehicleRun` and retain line-of-sight and frozen predicted aim.
  - Accept: Runtime attack eligibility changes at exactly 700/660, real shots use effective base speed, and critical startup still reaches the normal scheduled fire path.
- [x] **2.3** Pack, fairness, and capacity limits remain unchanged
  - Change: Add or tighten focused assertions for the existing bag/overlay, warning floor, commit caps, 96 ordinary projectile limit, 24 boss reserve, and 2.2-second lifetime.
  - Accept: Focused composition, attack, run, projectile-store, and renderer checks prove no cap or pack regression.
- [x] **2.4** Ordinary hostile shots render 16% larger without new load
  - Change: Add a threat-tier-aware presentation scale to the visual profile and renderer; update visual authority text and exact renderer/readability checks.
  - Accept: Ordinary and trait shots use `4.20 * 1.16`; boss shots use `4.20`; collision radii, opacity, one hostile batch, and batch capacity remain unchanged.

### Phase 3: Evidence, release, and handoff

Goal: Validate the finished behavior once at each required evidence layer, then commit, push, and deploy through the existing release path.

Preconditions:

- Phase 2 acceptance checks pass.
- The visual authority preflight is refreshed after the authority-document edit.

Source owners: `tools/validation/`, `scripts/vehicle/vehicle_run_capture_gateway.gd`, `tools/export_web.ps1`, `.github/workflows/vehicle-run-validation.yml`, this execution contract

- [x] **3.1** Focused mechanical gates pass
  - Change: Run the targeted Godot validators for experience, upgrades, attack contract, spawn composition, family traits, projectile store/readability, combat renderer, and vehicle run, plus static visual/document authority.
  - Accept: Every named focused check exits zero; failures are rerun only after a relevant correction.
- [x] **3.2** Korean gameplay capture proves projectile readability
  - Change: Run one 1280x720 full evidence capture because the existing fixture drives a real Emitter through startup, fire, flight, and hit; inspect the hostile startup/flight/hit images at original detail.
  - Accept: The live bolt is clear against the world, remains centered on collision truth, does not imply a predicted route, and does not obscure the player or source warning. Retain only task-owned evidence.
- [x] **3.3** Final Web gate and quality audit pass
  - Change: Run the task-scoped quality audit, one Web export, and `validate_itch_web_release.ps1` after all relevant inputs are stable.
  - Accept: No unresolved task-owned quality finding remains; export and release validation exit zero.
- [ ] **3.4** Changes are committed, pushed, and published
  - Change: Commit only task-owned files with explanatory bodies and push the feature branch. If the user approves stale-plan deletion, make the smallest coherent documentation cleanup, pass document authority, dispatch the itch workflow with `publish=true`, and wait for success.
  - Accept: Remote contains the implementation commit(s), and itch.io upload succeeds. If deletion approval is withheld, record that single external blocker without bypassing the gate.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | `./tools/godot.ps1 --headless --script res://tools/validation/validate_vehicle_experience.gd`; `validate_vehicle_upgrade_system.gd`; `validate_vehicle_attack_contract.gd`; `validate_vehicle_projectile_readability.gd` | Each owned progression/combat/visual batch is complete | Relevant implementation input changes |
| Phase gate | Focused composition, family, projectile-store, combat-renderer, vehicle-run, visual-authority, and document-authority validators | All Phase 1-2 task checks pass | A phase-owned input changes |
| Render gate | One Korean 1280x720 full capture; inspect only `09-effects-projectile-hostile-startup/flight/hit.png` | Authority refresh and focused mechanics pass | A rendered input changes |
| Final gate | `./tools/export_web.ps1`; `./tools/validation/validate_itch_web_release.ps1 -ReleaseDirectory ./build/web`; task-scoped quality audit; GitHub itch publish workflow | All implementation and render checks pass | A final-gate input changes |

Validation rules:

- Run the narrowest check that proves the current task.
- Run each named phase gate once after its owned tasks pass.
- The final Web export is the only broad integration gate for the completed implementation.
- Do not run a release-performance sample while unrelated Godot activity prevents clean evidence; do not label focused validators or captures as release-performance qualification.
- Rerun a failed check only after a relevant implementation change or a new hypothesis can produce new evidence.
- Record known non-blocking warnings once instead of rediscovering them.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain any required approval before resuming | Do not let implementation choose a new product, architecture, dependency, UX, safety, or validation contract |
| Larger ordinary bolts obscure source, player, or warning cues | Reduce only `ORDINARY_HOSTILE_PROJECTILE_PRESENTATION_SCALE` to the smallest visually sufficient value, update exact tests and authority text, and repeat the one affected render gate | Do not change collision, add a new asset/batch, or raise warning geometry |
| Focused capacity evidence approaches the 96-shot ordinary store or 80-batch ceiling | Stop cadence work and report the contradiction | Do not raise caps, weaken reserve, or claim the existing design remains bounded |
| Document deletion is not approved | Complete, commit, and push the implementation, then stop deployment at the documented authority failure | Do not move/delete the file or weaken/bypass the validator |
| The unrelated Godot process remains active | Skip release-performance qualification and retain only static/focused capacity evidence | Do not kill a process without positive task ownership |

Implementation-local discoveries may be handled inside the locked contract when they cannot change scope, visible behavior, ownership, architecture, safety, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 3.
- Next task: obtain explicit approval to delete the unreferenced done plan, then dispatch the existing itch workflow with `publish=true` and require success.
- Last completed gate: implementation commit `349e3390` pushed to `origin/feat/general-uiux-refinement`.
- Phase 1-2 evidence: experience, upgrade, attack, guidebook, spawn composition, family trait, route readability, projectile store/readability, combat renderer, and integrated vehicle-run validators passed. The current semantic-pack progression trace exposed a pre-existing stale expectation from the prior pack correction; production truth is 15,510 XP, level 51 after cycle 10, and level 58 after cycle 12, and only the spec/validator expectation changed.
- Phase 3 focused/render evidence: the refreshed visual-authority validator passed for sheet SHA-256 `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`. One Korean 1280x720 capture completed at `.agents/evidence/2026-08-22-xp-ranged-pressure-ko-1280`; original-detail inspection of `09-effects-projectile-hostile-startup.png`, `09-effects-projectile-hostile-flight.png`, and `09-effects-projectile-hostile-hit.png` confirmed that the enlarged bolt keeps a distinct opaque core and danger contour without obscuring the source, player, or warning cue.
- Phase 3 quality/Web evidence: the diff-scoped quality audit found stale expectations in the fallback-progression and specialist-integration validators; both now derive from their owning constants and pass. The final Web export completed with four primary files, and the itch static release validator passed with nine release files, raw size `56,359,942`, gzip size `24,706,893`, and allowance `26,949,682`.
- Phase 3 git/deployment evidence: commit `349e3390` contains only the task-owned implementation, authority, specification, plan, and validator changes and is pushed. Itch workflow run `32564272222` remains the current deployment evidence: it stopped before upload because `.agents/execplans/2026-08-22-enemy-pack-traits-and-boss-pressure-correction.md` is `status: done` but still lives in the active plan directory. No validator or deployment path has been bypassed.
- Update rule: after a checkpoint passes, record concise evidence, check the task, and advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check passes.
- Every guard, phase gate, and final gate named by this contract passes or the one approval-controlled deployment blocker is explicitly recorded.
- No placeholder or unresolved implementation decision remains.
- Durable behavior is recorded in its owning product/design document.
- Frontmatter status is changed to `done` only after implementation completion; it must then leave the active `execplans` tree through the repository's approved lifecycle workflow.

Replan when:

- A material discovery invalidates the locked XP curve, role boundaries, fairness analysis, capacity analysis, or release path.

Do not replan or stop for:

- Implementation-local mechanics already contained by this contract.
- A passing check whose relevant inputs have not changed.
