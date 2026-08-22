---
type: plan
status: active
created: 2026-08-22
scope: Shared boss-pattern progression, rapid projectile and charge commitment, Stage 6 distance-growth proximity ordnance, segmented defense rules including Stage 10 reflection, Stage 7 and Stage 9 wall tuning, focused validation, and pull-request evidence
related:
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../scripts/bosses/vehicle_boss_patterns.gd
  - ../../scripts/bosses/vehicle_boss_runtime.gd
  - ../../scripts/bosses/vehicle_boss_shield_runtime.gd
  - ../../scripts/bosses/vehicle_late_boss_mechanics.gd
  - ../../scripts/combat/vehicle_projectile_state.gd
  - ../../scripts/vehicle/vehicle_run.gd
---

# Shared Boss Patterns and Segmented Defense Rules - Execution Contract

Cardborne will make the first three bosses teach one cumulative common attack language, retain that language for every later boss, keep common and signature mechanics explicitly separate, make fast projectile and charge attacks commit after only a brief read, complete the Stage 6 distance-growth projectile with armed proximity detonation, apply one segmented-and-cyclic rule to every boss defense including Stage 10 reflection, and reduce only the speed and damage of the Stage 7 and Stage 9 wall mechanics by thirty percent.

## Purpose

- Objective: make boss encounters teach reusable attacks early, preserve those attacks throughout the twelve-stage run, and keep later encounters distinct through existing signature mechanics instead of replacing the common language.
- Deliverable: an English implementation plan, data and runtime changes, focused validators, rendered evidence for the changed projectile and defense states, a validated Web build, and one pull request from `codex/boss-shared-pattern-defense-rules` into `master`.
- Completion state: every checkbox and named gate passes, the pull request is open, this plan is marked `done`, and the final user explanation accurately describes the implemented behavior in Korean.

## Locked Scope

### Common pattern progression

The canonical common attack families are:

1. aimed charge;
2. two-lane projectile volley;
3. fast three-row curved barrage;
4. committed radial bombardment;
5. two-lane emitted beam;
6. X-shaped emitted beam;
7. periodic squad call.

Tutorial progression is cumulative:

- Stage 1 teaches charge, two-lane projectiles, three-row barrage, radial bombardment, and the periodic squad call.
- Stage 2 retains every Stage 1 common family and adds the two-lane beam and X beam.
- Stage 3 retains every Stage 2 common family and adds segmented cyclic defense.
- Stages 4-12 retain the complete common family set and layer their existing signature pattern or state on top.

A common attack remains common when a later boss changes damage, width, lane count, affinity, cadence, or ordering. A signature mechanic must require a materially different interaction, state rule, movement constraint, summon objective, or defensive relationship. Common and signature IDs must be queryable independently in code and validation.

### Attack commitment timing

- Projectile volleys, barrages, and charges use a short target-read pause, then commit to the captured target or direction and execute quickly.
- These attacks do not continue tracking after their startup commitment.
- Large beams, radial bombardments, crossing walls, and compression walls retain their longer readable warnings. This task does not broadly speed up hard-to-avoid full-area attacks.
- Boss health, ordinary movement speed, attack movement speed, and all unrelated attack damage remain unchanged.

### Stage 6 distance-growth projectile

- The projectile begins at the same speed, size, and damage as an ordinary boss projectile. It is not deliberately weakened or slowed at launch.
- From the existing growth distance onward, speed, radius, and damage increase monotonically to the existing caps.
- After a later arming distance, the projectile detonates when the player enters its proximity trigger even without direct contact.
- Direct contact and proximity detonation are mutually exclusive damage paths.
- The current beam-like line drawn behind the projectile is removed. Growth remains visible through projectile scale and a restrained code-native armed-state cue.
- Stage 6 owns one signature ordnance mechanic; direct and autonomous scheduling must not duplicate the same volley at the same time.

### Segmented defense contract

Every boss defense, including a reflection defense, must obey all of these rules:

- it is attached to the boss body;
- it consists of separated angular segments with real attackable gaps;
- segment collision and rendered gaps use the same angles;
- the defense has a complete down window in which no segment blocks or reflects attacks;
- the defense does not derive coverage from the boss-facing direction, because bosses rapidly turn toward the player;
- attacks through a gap deal normal damage;
- the effect of a segment is data-owned: Stage 3 reduces damage and charges its counterattack, while Stage 10 reflects eligible projectiles;
- no defense creates permanent or complete invulnerability.

Stage 3 preserves its current three 80-degree segments, three 40-degree gaps, rotation, eight-second active window, two-second down window, fifteen-percent blocked damage, and counterburst charge.

Stage 10 replaces the facing-based 100-degree plate with segmented reflection coverage. It preserves the existing long exposed / short active duty cycle unless validation proves a conflict: fifteen seconds fully down, one-second cue at the end of that down period, and five seconds active. Only projectiles that hit a live segment reflect; projectiles through gaps damage the boss normally.

### Stage 7 and Stage 9 wall tuning

- Stage 7 crossing-wall speed is multiplied by `0.70`.
- Stage 7 crossing-wall damage is multiplied by `0.70`.
- Stage 9 compression-wall speed is multiplied by `0.70`.
- Stage 9 compression-wall damage is multiplied by `0.70`.
- Wall geometry, safe-gap geometry, boss health, boss movement, and unrelated attacks remain unchanged.

## Explicit Non-Goals

- No new boss raster, projectile raster, SVG, ImageGen output, UI redesign, campaign-length change, difficulty mode, player-weapon balance change, or ordinary-enemy redesign.
- No broad boss-stat nerf.
- No new signature mechanic for every boss.
- No experimental movement archetype system, reactive director, echo attacks, moving safe lanes, commander objective, or other optional follow-up idea from the preceding discussion.
- No merge to `master` and no release publication.

## Baseline Implementation Facts at Branch Creation

- Direct attacks currently advance through one stage-owned list and reorder at the 65% and 30% phase thresholds.
- Autonomous attacks currently use an independent timer and may overlap direct attacks.
- Stage 9-12 currently replace the early common lists with theme-specific aliases instead of retaining an explicit common pool.
- Boss movement currently approaches beyond 240 units, retreats inside 140 units, and strafes between those distances.
- Stage 6 currently grows projectile speed from `0.75x` to `1.35x`, radius from `1.00x` to `1.50x`, and damage from `1.00x` to `1.60x` between 360 and 880 travelled units. The launch-speed floor conflicts with this plan.
- Stage 3 already uses segmented rotating defense and is the reference implementation.
- Stage 10 currently uses a facing-based reflection plate.
- Stage 7 crossing walls and Stage 9 compression walls currently own independent movement and damage values in the world runtime.

## Ownership Decisions

- `VehicleBossPatterns` owns common-family IDs, tutorial unlocks, per-stage signature IDs, beam topology, and absolute pattern values.
- `VehicleBossRuntime` owns common/signature selection, attack commitment timing, autonomous exclusivity, and periodic squad scheduling.
- `VehicleBossProfileCatalog` owns unchanged boss statistics plus any newly required cadence values; it does not acquire stage multipliers.
- `VehicleBossShieldRuntime` owns every segmented defense profile, active/down cycle, angular hit test, blocked-damage effect, and reflection effect.
- `VehicleLateBossMechanics` retains Stage 9 compression, Stage 11 resonance, and Stage 12 overload state. Stage 10 reflection timing moves to the shared defense owner.
- `VehicleProjectileState` owns Stage 6 growth, arming, proximity trigger, and one-shot detonation state.
- `VehicleRun` owns world movement, collision, damage application, wall execution, squad materialization, and projectile retirement.
- `VehicleCombatRenderer` consumes simulation truth only and removes the non-collision beam-like Stage 6 trail.

## Visual Authority Preflight

Required authority pair:

- `docs/design/VISUAL_SYSTEM.md`
- `docs/design/cardborne-universal-art-style-reference.png`

Expected canonical PNG SHA-256:

- `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`

Completed root-task receipt:

- both canonical repository paths exist;
- expected and observed PNG SHA-256: `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`;
- final current `VISUAL_SYSTEM.md` SHA-256 after the task-owned contract update: `3ac96b5a8135f4d0e3d1fb189b0a505e2b9fcd3f582f1936a42e0e0856c11791`;
- the complete current 950-line visual specification was read after that update;
- the canonical `1448 x 1086` PNG was inspected at original detail;
- original artifact provenance remains `C:/Users/BK/.codex/generated_images/019fbfe9-857e-7453-b72d-20908d848577/exec-0b8aa606-cf55-45c1-abb3-fb3df762b080.png`, timestamp `2026-08-02 12:13:44 KST`;
- the focused authority validator copies the exact PNG and a machine-readable receipt into the workflow evidence artifact;
- no raster, SVG, or ImageGen deliverable exists in this task, so actual image-reference input is not applicable.

Task-specific visual constraints:

- gameplay collision remains authoritative;
- warnings and defense segments are code-native retained geometry;
- rendered shield gaps must exactly match angular hit-test gaps;
- Stage 6 growth must be shown without a false beam or line connection;
- the armed-state cue must be sparse, state-bearing, and readable at runtime scale;
- semantic colors come from the existing visual profile;
- no new nodes, textures, materials, or unbounded effects.

## Tasks

### Phase 0: Authority receipt and baseline closure

Goal: create a fresh, reproducible authority receipt and close the exact baseline before visual work.

- [ ] **0.1** Add a focused visual-authority preflight validator.
  - Change: verify both files exist, compute both SHA-256 values, assert the canonical PNG hash, and copy the exact PNG plus a machine-readable receipt into the CI evidence directory.
  - Accept: CI logs the two observed hashes and the evidence artifact contains the unmodified `1448x1086` canonical PNG.
- [ ] **0.2** Complete the root-task visual preflight.
  - Change: read the complete current `VISUAL_SYSTEM.md`, download the CI evidence artifact, inspect the canonical PNG at original detail, and record the observed hashes and extracted constraints in this plan.
  - Accept: the receipt contains both paths, expected and observed sheet hash, observed document hash, complete-read confirmation, original-detail inspection confirmation, provenance, and task constraints.
- [ ] **0.3** Add one focused baseline validator for the requested gameplay contract.
  - Accept: the validator demonstrates the current common/signature separation gap, Stage 6 launch-speed mismatch and missing proximity detonation, Stage 10 facing-based reflection, and current wall scale values before implementation.

Batch gate:

- document-authority validation passes;
- the focused preflight validator passes in CI;
- `git diff --check` passes in CI.

### Phase 1: Common and signature attack contract

Goal: make the tutorial progression cumulative and preserve one common language for every later boss.

- [ ] **1.1** Publish canonical common-family and signature metadata.
  - Change: define the seven common families, tutorial unlocks for Stages 1-3, the complete Stage 4-12 common pool, per-stage signatures, and explicit common/signature queries.
  - Accept: Stage 1, Stage 2, and Stage 3 have cumulative common-family sets; every Stage 4-12 profile resolves all seven common families; no common ID is reported as a signature ID.
- [ ] **1.2** Separate common and signature selection at runtime.
  - Change: replace one undifferentiated direct list with bounded common and signature cursors while preserving existing signature implementations.
  - Accept: common attacks continue throughout every encounter, signature attacks remain stage-owned, the same attack cannot be selected twice in succession, and no unsupported ID is selectable.
- [ ] **1.3** Move squad calls to the shared periodic owner.
  - Change: use a ten-second boss-owned squad timer and the existing per-stage phase packets; prevent a squad call from starting during a major signature attack.
  - Accept: every boss can call its authored squad, the call is classified as common, fixed hostile caps remain valid, and phase transitions alter packet composition without causing duplicate immediate packets.
- [ ] **1.4** Shorten only projectile and charge commitment.
  - Change: use a brief bounded startup for projectile volleys, barrages, and charges; retain the current readable startup for beams, radial attacks, and walls.
  - Accept: rapid attacks capture the player target once, execute quickly after that capture, and do not track during startup or active time; broad attacks retain collision-readable warnings.

Batch gate:

- focused pattern/runtime validators pass;
- all selectable direct, signature, autonomous, and squad routes produce one measurable bounded effect;
- existing boss health and movement values remain byte-for-byte or value-for-value unchanged.

### Phase 2: Stage 6 distance-growth proximity ordnance

Goal: complete one coherent Stage 6 signature projectile lifecycle.

- [ ] **2.1** Correct the launch and growth contract.
  - Change: start at `1.00x` speed, radius, and damage; retain monotonic growth to the existing `1.35x`, `1.50x`, and `1.60x` caps.
  - Accept: zero-distance and pre-arm samples match an ordinary boss projectile, and growth samples are monotonic through the cap.
- [ ] **2.2** Add armed proximity detonation.
  - Change: after an explicit travel distance, trigger one radial explosion when the player enters the proximity radius; share one retirement path with direct collision.
  - Accept: no detonation occurs before arming, proximity detonation works without body contact, direct collision does not add a second explosion, and one projectile can damage the player at most once.
- [ ] **2.3** Remove duplicate scheduling and the false line trail.
  - Change: give the Stage 6 signature volley one scheduler owner and remove the renderer-only beam segment behind each growth projectile.
  - Accept: one scheduled signature action emits the authored volley once, no simultaneous direct/autonomous duplicate occurs, and rendered pixels show separate growing projectiles rather than connected lines.
- [ ] **2.4** Add a restrained armed-state cue.
  - Change: use existing code-native geometry and semantic colors to show that proximity detonation is armed.
  - Accept: the cue appears only after the same distance that enables collision behavior, remains bounded to each projectile, and introduces no new texture, material, or node owner.

Batch gate:

- projectile-state, collision, renderer, fixed-cap, and Stage 6 boss validators pass;
- rendered evidence shows launch, growth, armed, proximity-trigger, and retirement states.

### Phase 3: Segmented defense and Stage 10 reflection

Goal: make every defense attackable while active and fully absent during a recurring focus-fire window.

- [ ] **3.1** Generalize defense profiles without changing Stage 3 behavior.
  - Change: move segment count, segment arc, gap arc, rotation, active/down times, blocked multiplier, and effect type into data-owned defense profiles.
  - Accept: Stage 3 reproduces its existing angular, timing, blocked-damage, and counterburst behavior exactly.
- [ ] **3.2** Move Stage 10 reflection into the shared defense owner.
  - Change: replace the facing-based plate test with segmented angular reflection; preserve the long-down/short-active cycle and reflection damage cap.
  - Accept: live segments reflect, gaps deal normal boss damage, the entire defense disappears for its down period, and boss facing cannot convert the defense into permanent frontal coverage.
- [ ] **3.3** Synchronize collision and presentation.
  - Change: publish one defense snapshot containing the exact segment and cycle truth used by both hit tests and rendering.
  - Accept: segment counts, arc lengths, gap lengths, rotation, cue, active, and down states agree in focused fixtures and rendered evidence.

Batch gate:

- shield, reflection, projectile-collision, renderer, and late-boss validators pass;
- Stage 3 and Stage 10 rendered evidence includes active segments, a projectile through a gap, a segment hit, activation cue, and full-down state.

### Phase 4: Stage 7 and Stage 9 wall tuning

Goal: reduce only the two requested wall mechanics without broad boss-stat changes.

- [ ] **4.1** Apply Stage 7 wall scales.
  - Change: multiply crossing-wall speed and damage by `0.70` at the mechanic owner.
  - Accept: every directional variant uses the same scale, geometry is unchanged, and no Stage 7 non-wall attack changes.
- [ ] **4.2** Apply Stage 9 wall scales.
  - Change: multiply compression-wall speed and damage by `0.70` at the mechanic owner.
  - Accept: every single, shifted, paired, and reversed variant uses the same scale, geometry is unchanged, and no Stage 9 non-wall attack or boss statistic changes.
- [ ] **4.3** Capture before/after-equivalent timing evidence.
  - Accept: deterministic fixtures prove exact seventy-percent travel distance and damage over the same simulation interval.

Batch gate:

- Stage 7/9 mechanic and collision validators pass;
- exact unchanged-stat assertions pass for all twelve bosses.

### Phase 5: Integration, evidence, and pull request

Goal: prove the branch as one coherent bounded change and publish it for review.

- [ ] **5.1** Synchronize English code comments, canonical product documentation, and this plan with implemented truth.
- [ ] **5.2** Run the full repository validation workflow.
  - Accept: document authority, Godot import, every production validator, native rendered capture, Web export, built-Web boot, and diff cleanliness pass.
- [ ] **5.3** Inspect the final branch diff and evidence.
  - Accept: changed files remain within the locked scope; no broad stat, UI, asset, dependency, save, or ordinary-enemy changes appear.
- [ ] **5.4** Open the pull request.
  - Title: `Refine shared boss patterns and segmented defenses`.
  - Body: explain scope, exact timing and scale changes, preserved values, rendered evidence, validation, and exclusions in English.
- [ ] **5.5** Mark this plan `done` and record final commit, pull request, validation run, and evidence artifact identifiers.

## Validation Commands and CI Gates

The branch must pass the repository workflow that executes:

- `./tools/validation/validate_document_authority.ps1`
- Godot 4.7.1 headless import
- every production `tools/validation/validate_*.gd` validator
- native 1280x720 rendered evidence capture
- Web release export
- built-Web HTTP and browser boot smoke
- evidence manifest upload

Focused validators added or updated by this task must cover:

- tutorial cumulative common-family sets;
- complete Stage 4-12 common-family coverage;
- common/signature ID separation;
- rapid target capture and non-tracking commitment;
- periodic squad timing and cap safety;
- Stage 6 normal launch, monotonic growth, arming, proximity trigger, one-shot damage, and no false line trail;
- Stage 3 unchanged segmented defense;
- Stage 10 segmented reflection, attackable gaps, and complete down window;
- exact Stage 7/9 wall `0.70` speed and damage scales;
- unchanged boss HP and movement profiles.

## Progress and Next Step

- Current phase: Phase 5 integration and validation.
- Implementation checkpoint: common/signature data and scheduling, periodic squads, rapid commitment timing, Stage 6 growth/proximity ordnance, shared segmented defenses, Stage 10 reflection, Stage 7/9 wall scales, renderer changes, canonical documentation, and focused validators are present in the working branch patch.
- Next task: commit the bounded implementation, run the complete GitHub workflow, repair any failing production validator, then archive this plan as `done` and mark pull request 5 ready for review.
- Last completed gate: fresh visual-authority receipt completed; `git diff --check`, delimiter balance, and stale-contract searches pass in the reconstructed source tree.
- Update rule: check a task only after its acceptance evidence exists, then advance this pointer in the same plan update.

## Completion and Stop Conditions

This plan is complete only when:

- all checkboxes are checked;
- the full GitHub workflow passes on the final branch commit;
- the pull request is open against `master`;
- no requested behavior remains only documented;
- the final Korean explanation identifies both changed and intentionally unchanged behavior without claiming unrun local tests.

Stop and revise the contract if implementation would require a new raster, dependency, save migration, broad boss-stat rebalance, ordinary-enemy redesign, campaign restructure, or any optional idea explicitly excluded above.
