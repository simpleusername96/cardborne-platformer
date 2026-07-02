---
type: plan
status: active
created: 2026-07-02
source: User request on 2026-07-02
scope: MVP-ish motion test bed miniature game implementation
related:
  - ./MOTION_TEST_BED_SPEC.md
  - ../product/2d_platform_action_card_game_prd.md
  - ../architecture/FIRST_SLICE_ARCHITECTURE.md
  - ./PLAYER_CHARACTER_SYSTEMS.md
  - ./ENEMIES_TRAPS_GIMMICKS.md
  - ./PROCEDURAL_REGION_GENERATION.md
---

# Motion Test Bed MVP-ish Implementation Plan

This plan turns `MOTION_TEST_BED_SPEC.md` into an executable checklist for the next implementation pass. The goal is not a content-complete MVP. The goal is a miniature playable testbed that proves shared contracts, character-aware platforming, combat, interaction, input visibility, and seeded random landscape generation before normal stages, shop/rest stages, boss maps, or broader content are built.

Checklist items should be completed sequentially. Do not start a later content stage to compensate for an unfinished foundation contract.

## Purpose

- Future goal: build a user-testable Godot 4.x motion testbed that behaves like a miniature game.
- Why it matters: this project depends on reliable movement, damage response, stage flow, and no-soft-lock route design before additional content can be trusted.
- Final artifact: a playable `MotionTestStage` with authored validation lanes plus a seed-driven generated landscape lane.
- Intended location: runtime work should stay in the existing Godot project under `scenes/`, `scripts/`, and `data/`; this plan stays in `docs/design/`.

## Domain Brief

- Request interpretation: the current scene proves that the project boots, but it does not yet prove map geometry, character reach, skill simulation, enemy behavior, NPC interaction, keybinding usability, or generated landscape playability.
- Likely bounded context or scope: testbed stage flow, movement calibration, player ability toggles, combat validation, enemy behavior, interaction validation, input/settings UI, and runtime landscape generation.
- Canonical terms:
  - **testbed**: the deliberately structured validation scene before production stages.
  - **miniature game**: a short generated run inside the testbed with spawn, traversal, enemies, interaction, hazards, exit, and summary.
  - **movement metric**: calculated reach values from the selected character profile and enabled abilities.
  - **authored lane**: a fixed validation section in the scene.
  - **generated landscape**: runtime-created playable terrain segments assembled from templates.
  - **critical path**: required route from generated spawn to generated exit.
  - **optional branch**: non-required route that may test stronger abilities or higher risk.
- Ownership boundaries:
  - Player movement and ability state belong under `scripts/player/`.
  - Damage delivery belongs under `scripts/combat/`.
  - Enemy behavior belongs under `scripts/enemies/`.
  - Stage/testbed flow and generated terrain assembly belong under `scripts/stages/`.
  - UI/HUD/settings presentation belongs under `scripts/ui/`.
  - Run profile, seed, and global state belong under `scripts/autoload/`.
- Public interfaces:
  - Testbed code should read effective movement stats, not raw keybindings or hard-coded character IDs.
  - Generated terrain should request segment plans from a generator and instantiate through stage helpers.
  - Enemies, hazards, and player attacks should all route damage through `DamageInfo`, `Hitbox`, and `Hurtbox`.
  - UI should observe `SignalBus` and call narrow commands instead of owning gameplay rules.
- Hidden implementation decisions: placeholder art, exact node hierarchy, collision shape dimensions, and generator internals can change if the observable contracts remain true.
- Invariants:
  - No required platforming route is placed by eye; every required gap or ledge must be tied to movement metrics.
  - The least-mobile required profile must be able to clear the main authored and generated critical paths.
  - Optional branches may require stronger profiles or debug abilities, but they must never block stage clear.
  - Seeded generation must be deterministic: same seed, profile, ability set, and generator mode produce the same route plan.
  - Invalid generated routes must be rejected, regenerated, or shown as invalid before play starts.
- State transition target: start motion test -> choose profile/ability/seed/mode -> authored validation lanes -> generated miniature run -> exit -> clear/fail summary -> replay or regenerate.
- Open decisions: whether double jump is a debug test ability or a real first-slice unlock; whether key rebinding is in-memory only for this pass or persisted in settings.
- Is this simple CRUD?: no.

## Decisions Locked With The Owner

| Topic | Decision | Source / note |
| --- | --- | --- |
| Work model | Build sequentially, with shared rules and components first. | User correction before this plan. |
| Testbed bar | The testbed must simulate character abilities, skills, enemies, NPC/object interaction, controls, and generated landscapes. | User correction before this plan. |
| Output shape | Create a detailed English checklist plan document. | User request on 2026-07-02. |
| Landscape scope | The testbed must include random landscape generation and function as a miniature game. | User request on 2026-07-02. |
| Visual scope | Placeholder shapes and simple sprites are acceptable for the MVP testbed. | Root `AGENTS.md` and PRD. |

## Assumptions And Open Decisions

| Topic | Current assumption | Why it matters | Ask / default handling |
| --- | --- | --- | --- |
| Double jump | Add it as a testbed ability flag first, unless a card/skill system lands before this pass. | The advanced movement lane must be testable even before the full card system. | Default to debug ability toggle labeled in UI. |
| Skill simulation | Simulate skills as ability/stat modifiers in the testbed, not as the full permanent skill tree. | The testbed must prove movement/combat effects without waiting for progression UI. | Use `RunState` or a small player build adapter until the full card/build system exists. |
| Keybinding persistence | In-memory rebinding or binding list is enough for this plan; persistence can be deferred. | The user needs to inspect and correct controls now. | Build shared input actions and visible binding UI first. Persist only if low-risk. |
| Generated landscape | Use segment-template assembly, not arbitrary tile noise and not the full region graph system. | The generated route must be playable and measurable immediately. | Treat `PROCEDURAL_REGION_GENERATION.md` as future map graph context only. |
| Character profiles | Keep one controller and three profile resources for this pass. | Separate controllers would multiply test surface too early. | Expand profiles/abilities, not controllers. |
| Camera and world size | Keep a compact testbed first; add camera bounds only when route width/height needs it. | A huge map can hide basic validation failures. | Build lanes/generated route in a scannable layout. |

## Progress

Landed / already true:

- [x] Godot project boots through `scenes/main/Main.tscn`.
- [x] `Game`, `RunState`, and `SignalBus` autoloads exist.
- [x] Shared input actions are created in `Game.ensure_input_map`.
- [x] One `PlayerController` reads profile-driven stats.
- [x] Three `CharacterProfile` resources exist under `data/characters/`.
- [x] `DamageInfo`, `Hitbox`, and `Hurtbox` exist.
- [x] `StageBase`, `Interactable`, and `ExitPortal` exist.
- [x] HUD and settings popup shells exist.
- [x] Current `MotionTestStage` contains placeholder platforms, one dummy, one hazard, and one exit.
- [x] `MOTION_TEST_BED_SPEC.md` defines the required testbed behavior.

Still open:

- [ ] Movement metrics are not computed or displayed from actual active profile values.
- [ ] The scene is not structured into labeled validation lanes.
- [ ] Required gaps, ledges, and jump+dash checks are not derived from character reach.
- [ ] Double jump or advanced ability simulation is not implemented.
- [ ] Combat uses a reset dummy, not a real enemy with AI, contact damage, death, and reset.
- [ ] Attack startup/active/recovery are not readable enough.
- [ ] NPC/object interaction separate from the exit is not implemented.
- [ ] Binding list/remap UI is not implemented.
- [ ] Seeded runtime landscape generation is not implemented.
- [ ] Miniature run loop, generated route validation, and seed replay are not implemented.
- [ ] Final manual QA path for the testbed is not defined in-game.

Out of scope for this plan:

- [ ] Full card reward system.
- [ ] Three normal production stages.
- [ ] Shop/rest stage implementation.
- [ ] Boss map and boss patterns.
- [ ] Full procedural region graph runtime.
- [ ] Final art, final animation, audio, localization, or save-file persistence.

## Guiding Implementation Principle

Build the testbed as a shared contract verifier, not as disposable prototype content. Static authored lanes and generated landscape segments must use the same movement metrics, damage components, interactable contract, input action names, and UI status path.

Shared owners to create, reuse, or retire:

| Concern | Desired owner | Existing owner(s) to reuse or retire |
| --- | --- | --- |
| Effective stats | `RunState` now; later player build adapter | Reuse `RunState.get_effective_stats`; avoid duplicating stats inside UI or stage code. |
| Movement metrics | New `scripts/player/MovementMetrics.gd` or `scripts/stages/MovementMetrics.gd` | Reuse `CharacterProfile` values; retire hand-placed metric notes. |
| Testbed stage flow | `scripts/stages/MotionTestStage.gd` plus `StageBase` | Reuse `StageBase`; avoid bloating `Main.gd`. |
| Runtime terrain construction | New `scripts/stages/testbed/TestbedTerrainBuilder.gd` or similar | Reuse collision layer names from `project.godot`; avoid hard-coded scattered platform creation. |
| Segment generation | New generator under `scripts/stages/testbed/` | Reuse procedural terminology; do not depend on Python tool at runtime. |
| Enemy baseline | New `EnemyBase.gd` and `WalkerEnemy.gd` | Retire `DamageDummy` as the only combat proof; keep it as optional measurement target. |
| Hazard baseline | New or shared `Hazard.gd` wrapping `Hitbox` behavior | Reuse `DamageInfo`/`Hitbox`; avoid one-off hazard script in the scene. |
| Interaction proof | New NPC/object scene extending or using `Interactable` | Reuse `Interactable`; do not treat `ExitPortal` as sufficient interaction proof. |
| Input visibility/remap | `Game.ensure_input_map` plus `SettingsPopup` or a controls panel | Reuse input action names; avoid text-only HUD controls that drift from actual bindings. |
| HUD feedback | `scripts/ui/HUD.gd` observing `SignalBus` | Reuse signal path; avoid stage scripts writing UI labels directly. |

## Current-State Map

| Concern | Owner(s) today | Evidence inspected | Observed behavior / problem | Plan handling |
| --- | --- | --- | --- | --- |
| Project entry | `project.godot`, `scenes/main/Main.tscn`, `scripts/main/Main.gd` | Main scene and autoload config | Motion test starts immediately; no menu or test mode selector. | Keep direct boot for now, add in-game testbed mode controls. |
| Input map | `scripts/autoload/Game.gd:ensure_input_map` | Action setup code | Shared actions exist, but no binding list/remap UI. | Add binding introspection and remap shell before content stages. |
| Run profile/state | `scripts/autoload/RunState.gd` | Profile loading and stat publish path | Three profiles can be selected; `Tab` cycles profile as debug shortcut. | Keep profile cycle debug-labeled, add explicit profile/ability UI later. |
| Player movement | `scripts/player/PlayerController.gd` | Movement, coyote, buffer, dash, crouch, one-way drop | Core movement exists; no double jump, metric display, or ability flags. | Add metric calculator and optional debug ability toggles. |
| Player profiles | `scripts/player/CharacterProfile.gd`, `data/characters/*.tres` | Resource fields | Stats are editor-friendly and enough for movement formulas. | Use these as the source for lane/generator passability. |
| Combat components | `scripts/combat/DamageInfo.gd`, `Hitbox.gd`, `Hurtbox.gd` | Damage delivery code | Good foundation; lacks enemy lifecycle proof. | Reuse unchanged unless enemy work exposes missing data. |
| Enemy proof | `scripts/enemies/DamageDummy.gd`, `scenes/enemies/DamageDummy.tscn` | Dummy script | Dummy resets HP but has no AI/contact/death behavior. | Keep as measurement target; add real enemy actor. |
| Stage base | `scripts/stages/StageBase.gd` | Spawn and completion code | Good base; no route gating or lane state. | Reuse and add testbed-specific controller. |
| Interaction | `scripts/stages/Interactable.gd`, `ExitPortal.gd` | Prompt and interact path | Exit proves interaction only as stage clear; no NPC/object result. | Add standalone interactable object lane. |
| HUD | `scripts/ui/HUD.gd` | Labels and panels | Shows controls, profile, HP, prompt, status; no lane, metric, seed, binding, or route status. | Extend with compact testbed debug panels. |
| Settings | `scripts/ui/SettingsPopup.gd` | Popup code | Volume/toggles only; no controls section. | Add input/binding view and optional remap. |
| Scene layout | `scenes/stages/MotionTestStage.tscn` | Placeholder platform scene | Not character-aware and not lane-based. | Rebuild or script-generate testbed lanes. |
| Procedural data | `docs/design/PROCEDURAL_REGION_GENERATION.md`, `data/design/first_slice/procedural_region_rules.json` | Existing high-level graph spec | Describes room graph planning, not runtime playable terrain. | Use terminology only; implement smaller runtime segment generator. |

## Scope

In scope:

- [ ] Keep the current foundation contracts, tightening names and signals only when required.
- [ ] Add movement metric calculation from active profile and ability flags.
- [ ] Rebuild the motion test scene into clear lanes with labels and recovery paths.
- [ ] Add a real baseline enemy and repeatable combat lane.
- [ ] Add readable attack/hit feedback.
- [ ] Add standalone interaction proof using `Interactable`.
- [ ] Add binding display and a route to remap or clearly defer remap.
- [ ] Add deterministic generated landscape assembly from segment templates.
- [ ] Add miniature game mode with seed, regenerate, replay, route validation, and clear/fail summary.
- [ ] Add targeted verification scripts or manual QA checklist where Godot automation is practical.

Out of scope:

- [ ] Full roguelike region graph runtime.
- [ ] Card reward screen and full card application.
- [ ] Shop, forge, healer, rest, and boss maps except as mocked interactable results.
- [ ] Final graphics, final animation sheets, sound, localization, and persistent settings.
- [ ] Multiple independent player controllers.

Destructive or irreversible actions:

- [ ] Do not delete existing scenes/scripts unless the replacement is already in place and the deletion is scoped.
- [ ] Do not replace project-wide input names without updating every usage and this plan.
- [ ] Do not change collision layers casually; they are already named in `project.godot`.

Requires owner/user approval before:

- [ ] Changing the canonical default controls away from PRD-style mappings.
- [ ] Adding external assets or dependencies.
- [ ] Promoting runtime procedural generation beyond segment-template testbed generation.
- [ ] Replacing the one-controller/three-profile model with separate character controllers.

## Source Map

| Source or path | Type | Verified? | Why it matters | Handling |
| --- | --- | --- | --- | --- |
| `AGENTS.md` | local policy | yes | Defines Godot/GDScript, folder ownership, PRD priority, and placeholder-asset constraint. | Obey. |
| `.agent/PLANS.md` | local policy | yes | Defines when ExecPlan-sized work is warranted. | This future work qualifies; this doc provides the checklist plan. |
| `docs/design/MOTION_TEST_BED_SPEC.md` | active spec | yes | Canonical behavior contract for the testbed. | Build toward it. |
| `docs/product/2d_platform_action_card_game_prd.md` | active product spec | yes | Defines MVP controls, movement, combat, stages, UI, and technical direction. | Preserve unless user supersedes. |
| `docs/architecture/FIRST_SLICE_ARCHITECTURE.md` | active architecture spec | yes | Defines ownership boundaries for run flow, player build, stage, encounter, and UI. | Reuse boundaries. |
| `docs/design/PLAYER_CHARACTER_SYSTEMS.md` | active design spec | yes | Defines first-slice controls, stats, skills, equipment hooks. | Use for ability/stat naming. |
| `docs/design/ENEMIES_TRAPS_GIMMICKS.md` | active design spec | yes | Defines baseline enemies, traps, and teaching roles. | Use for enemy/hazard lanes. |
| `docs/design/PROCEDURAL_REGION_GENERATION.md` | active design spec | yes | Defines high-level seeded region generation. | Reference, but do not make runtime depend on Python prototype. |
| `scripts/autoload/*.gd` | runtime code | yes | Owns global state, input map, signals. | Reuse and extend carefully. |
| `scripts/player/*.gd` | runtime code | yes | Owns profile-driven movement and stats. | Add metrics/abilities here or adjacent. |
| `scripts/combat/*.gd` | runtime code | yes | Owns damage components. | Reuse for enemies, hazards, attacks. |
| `scripts/stages/*.gd` | runtime code | yes | Owns stage flow and interaction. | Add testbed stage and generator helpers. |
| `scripts/ui/*.gd` | runtime code | yes | Owns HUD and settings popup. | Extend for guide, bindings, seed, metrics, summaries. |
| `scenes/stages/MotionTestStage.tscn` | runtime scene | yes | Current placeholder stage. | Rebuild or script-generate lanes. |

## Evidence Rules

- Source priority: user corrections in the current conversation, then `MOTION_TEST_BED_SPEC.md`, then PRD, then architecture/design docs, then current code.
- Freshness requirement: local repo state is authoritative for implementation details; no web lookup is needed for this plan.
- Citation requirement: implementation commits should reference files changed and checks run; separate evidence docs are not needed for each small batch.
- Uncertainty labels: use **locked**, **assumption**, **open**, or **deferred** in follow-up docs/commits when a decision affects scope.
- Enough evidence: each phase is done only when the named playable behavior can be tested in Godot and the relevant static checks pass.

## Tasks

### Phase 0 - Baseline Guard And Run Path

Goal: make sure future implementation starts from a known runnable baseline.

Source owners touched: `README.md`, `tools/godot.ps1`, fastrun command registry if needed, `project.godot`.

- [ ] **0.1** Run `.\tools\godot.ps1 --path . --headless --quit` or the nearest available Godot smoke command.
- [ ] **0.2** Confirm the fastrun manager command still launches `D:\npjt\cardborne-platformer` through `.\tools\godot.ps1 --path .`.
- [ ] **0.3** Record any current Godot warnings that are known baseline noise.
- [ ] **0.4** Confirm `project.godot` still lists `SignalBus`, `RunState`, and `Game` autoloads.
- [ ] **0.5** Confirm no unrelated worktree changes will be touched.

Accept:

- [ ] Project opens or headless smoke exits without missing script errors.
- [ ] Manual launch path is known before gameplay changes begin.

Guard:

- [ ] Do not start large scene edits if the baseline cannot boot.

### Phase 1 - Movement Metrics And Ability Flags

Goal: create the shared measurement layer that authored lanes and generated segments will both consume.

Source owners touched: `scripts/player/CharacterProfile.gd`, new metric helper under `scripts/player/` or `scripts/stages/`, `RunState.gd`, `SignalBus.gd`, `HUD.gd`.

- [ ] **1.1** Add a movement metric helper that computes apex height, airtime, single-jump reach, dash reach, and jump+dash reach from an effective stat dictionary.
- [ ] **1.2** Include conservative route limits for required path gaps and ledges, derived from the least-mobile required profile.
- [ ] **1.3** Add ability flags for testbed-only modifiers such as `double_jump_enabled`, `extra_dash_enabled`, or `air_dash_enabled`.
- [ ] **1.4** Decide whether ability flags live in `RunState` or a small player build adapter; keep the public API narrow.
- [ ] **1.5** Emit a signal when metrics or ability flags change.
- [ ] **1.6** Add HUD/debug display for current profile, ability flags, jump height, jump reach, dash reach, and jump+dash reach.
- [ ] **1.7** Add a static or editor-readable note in the stage describing the current least-mobile profile limits.

Accept:

- [ ] Changing the active profile updates displayed movement metrics.
- [ ] Required route limits can be read from code by both authored lanes and generator code.
- [ ] Debug ability flags are visible and cannot be confused with final progression.

Guard:

- [ ] No stage, UI, enemy, or generator code duplicates movement formulas.

### Phase 2 - Authored Lane Rebuild

Goal: replace the freeform placeholder map with a structured validation route.

Source owners touched: `scenes/stages/MotionTestStage.tscn`, new `scripts/stages/MotionTestStage.gd`, optional lane label helper scene/script.

- [ ] **2.1** Add a testbed-specific stage controller script if the scene needs lane state, labels, or gates beyond `StageBase`.
- [ ] **2.2** Split the scene into lane containers: spawn/controls, movement metrics, jump behavior, advanced movement, combat, enemy behavior, hazard/damage, NPC/object interaction, input/settings, exit, generated landscape.
- [ ] **2.3** Add visible lane labels and compact objective text that do not cover the player.
- [ ] **2.4** Build a safe flat start area for acceleration, deceleration, crouch, facing, and profile switching.
- [ ] **2.5** Add jump height markers and horizontal reach markers using metric output.
- [ ] **2.6** Add forgiving and threshold gaps for ground jump.
- [ ] **2.7** Add jump+dash gap using conservative limits.
- [ ] **2.8** Add a coyote-time ledge and a jump-buffer landing test.
- [ ] **2.9** Add one-way platform drop-through with safe recovery.
- [ ] **2.10** Add advanced movement route that is passable only when the relevant ability flag is enabled.
- [ ] **2.11** Add recovery paths under every required fall.
- [ ] **2.12** Gate exit progression so the player cannot skip all validation lanes by walking directly to the portal.

Accept:

- [ ] Warrior or the current least-mobile required profile can clear the required route.
- [ ] Archer and Assassin can clear without the route becoming trivial enough to hide control problems.
- [ ] Optional advanced route is clearly optional and visibly blocked or marked when its ability is disabled.
- [ ] No required route creates a soft lock after falling.

Guard:

- [ ] No required gap exceeds the generated metric limit unless a documented manual test proves it.

### Phase 3 - Player Control Feedback And Attack Readability

Goal: make movement and attack behavior visible enough to debug without reading logs.

Source owners touched: `scripts/player/PlayerController.gd`, `scenes/player/Player.tscn`, `scripts/combat/Hitbox.gd`, `HUD.gd`, `SignalBus.gd`.

- [ ] **3.1** Add placeholder visual states for idle, run, crouch, jump/fall, dash, hurt, and attack.
- [ ] **3.2** Add a visible attack active-frame shape or arc that matches the actual hitbox position and facing.
- [ ] **3.3** Expose attack state messages or compact HUD feedback for startup, active, recovery, cooldown, and hit confirm.
- [ ] **3.4** Verify attack facing follows the last movement direction and does not flip incorrectly during crouch or dash.
- [ ] **3.5** Add or tune hit pause, flash, or color feedback for successful hit and player damage.
- [ ] **3.6** Ensure invulnerability feedback is visible but does not hide player position.

Accept:

- [ ] A tester can tell when attack is active and why it missed or hit.
- [ ] Player hurt and invulnerability states are visible.

Guard:

- [ ] Visual attack feedback must use the same timing as the damaging `Hitbox`; do not create fake-only effects that can drift.

### Phase 4 - Real Enemy Baseline

Goal: prove combat against an actual actor, not only a dummy.

Source owners touched: new `scripts/enemies/EnemyBase.gd`, new `scripts/enemies/WalkerEnemy.gd`, new enemy scenes, `DamageDummy.gd`, `SignalBus.gd`, `HUD.gd`.

- [ ] **4.1** Add `EnemyBase` with max health, current health, contact damage, knockback response, damaged signal, defeated signal, and reset/death behavior.
- [ ] **4.2** Add `WalkerEnemy` that patrols between bounds or turns on wall/ledge.
- [ ] **4.3** Add contact damage using `DamageInfo` and the same damage path the player already understands.
- [ ] **4.4** Add enemy health feedback through label, marker, or HUD event.
- [ ] **4.5** Add repeatable reset behavior for the lane so the player can retest without restarting the whole scene.
- [ ] **4.6** Keep `DamageDummy` as optional measuring target, not as the main combat validation.
- [ ] **4.7** Add at least one safe re-entry platform after enemy damage or death.

Accept:

- [ ] Enemy moves, damages player, takes attack damage, reacts, dies or resets, and can be retested.
- [ ] Player death/reload still works after enemy contact damage.

Guard:

- [ ] Enemy AI must not directly change UI or player health outside the shared damage path.

### Phase 5 - Hazards And Damage Recovery

Goal: prove non-enemy damage without chain-hit soft locks.

Source owners touched: new or revised `scripts/stages/Hazard.gd`, `scenes/stages/MotionTestStage.tscn`, `PlayerController.gd`, `HUD.gd`.

- [ ] **5.1** Wrap hazard behavior in a named script instead of only a scene-local `Hitbox`.
- [ ] **5.2** Add spike or hazard strip with clear visual identity.
- [ ] **5.3** Add knockback direction and recovery space.
- [ ] **5.4** Add invulnerability test that prevents immediate repeated damage.
- [ ] **5.5** Add a safe reset/re-entry path after falling or taking hazard damage.
- [ ] **5.6** Add HUD/status feedback for hazard damage.

Accept:

- [ ] Player takes hazard damage once, receives readable feedback, and can recover.
- [ ] Hazard cannot trap the player in an endless damage loop.

Guard:

- [ ] Repeating hazards must have either explicit timing or player invulnerability protection.

### Phase 6 - NPC/Object Interaction Proof

Goal: prove interaction separately from stage clear.

Source owners touched: `scripts/stages/Interactable.gd`, new interactable scene/script, `HUD.gd`, `SettingsPopup.gd` only if needed.

- [ ] **6.1** Add an NPC or object that extends/uses `Interactable` and is not the exit portal.
- [ ] **6.2** Show prompt only when in range.
- [ ] **6.3** On interact, open a small panel, grant a placeholder resource, toggle a debug ability, or open a door.
- [ ] **6.4** Ensure leaving range hides prompt.
- [ ] **6.5** Ensure interaction does not permanently steal movement controls.
- [ ] **6.6** Add a reset path so the interaction can be tested repeatedly.

Accept:

- [ ] A tester can interact with a non-exit object and see a visible result.
- [ ] Exit portal still uses the shared interaction path or its documented collision rule.

Guard:

- [ ] Do not build a full shop/forge system in this phase.

### Phase 7 - Input Guide, Binding List, And Settings

Goal: make controls discoverable and prepare for rebinding without scattering shortcut text.

Source owners touched: `Game.gd`, `SettingsPopup.gd`, `HUD.gd`, `SignalBus.gd`, possible new `scripts/ui/InputBindingRow.gd`.

- [ ] **7.1** Define one canonical action list: `move_left`, `move_right`, `jump`, `attack`, `dash`, `crouch`, `interact`, `pause`, and debug-only action(s).
- [ ] **7.2** Add a function that returns display strings from the actual `InputMap`, not hard-coded HUD text.
- [ ] **7.3** Update HUD controls guide to read from the binding display function.
- [ ] **7.4** Add settings controls section listing current bindings.
- [ ] **7.5** Implement keyboard remap for at least one action, or clearly label remapping as deferred while preserving the architecture.
- [ ] **7.6** Detect or prevent duplicate bindings if remapping is implemented.
- [ ] **7.7** Label debug actions such as profile cycle or ability toggles as debug-only.

Accept:

- [ ] In-game guide matches actual `InputMap` actions.
- [ ] A tester can find every action needed by the testbed without reading external notes.
- [ ] If remap is deferred, the UI says so and the shared action path remains ready.

Guard:

- [ ] Do not add separate key names in stage or player code that bypass `InputMap`.

### Phase 8 - Segment Template Data Contract

Goal: define the small runtime generator contract before placing random terrain.

Source owners touched: new scripts/resources under `scripts/stages/testbed/` or `scripts/stages/`, optional data under `data/testbed/`.

- [ ] **8.1** Create a `SegmentTemplate` contract with ID, width, height delta, required ability, gap range, ledge range, safe landing width, enemy budget, hazard budget, interactable budget, and critical/optional eligibility.
- [ ] **8.2** Create a generated route plan data shape with seed, profile ID, ability flags, generator mode, segment IDs, placements, validation status, and failure reason.
- [ ] **8.3** Add generator profiles: `movement_only`, `combat_route`, `hazard_route`, and `mixed_mini_run`.
- [ ] **8.4** Encode initial templates: flat safe, low step, standard jump, near-limit jump, jump+dash, one-way vertical, optional advanced branch, combat pocket, hazard pocket, interaction pocket, exit.
- [ ] **8.5** Add validation rules that compare segment requirements against movement metrics and enabled abilities.
- [ ] **8.6** Add deterministic RNG from seed and generator mode.

Accept:

- [ ] Same seed/profile/ability/mode produces the same route plan.
- [ ] Invalid segment combinations report a reason before instantiation.
- [ ] Critical path templates never require disabled optional abilities.

Guard:

- [ ] Do not use arbitrary tile noise for this testbed generator.
- [ ] Do not depend on `tools/generate_region_graph.py` at runtime.

### Phase 9 - Runtime Generated Landscape Assembly

Goal: instantiate playable terrain from a validated route plan.

Source owners touched: terrain builder under `scripts/stages/testbed/`, `MotionTestStage.gd`, new generated lane container in `MotionTestStage.tscn`.

- [ ] **9.1** Add a generated-lane root node that can be cleared and rebuilt safely.
- [ ] **9.2** Add a terrain builder that creates placeholder collision and visual nodes for each segment.
- [ ] **9.3** Add spawn position and exit position from the route plan.
- [ ] **9.4** Instantiate enemy placements through enemy scenes, not custom generator-only enemies.
- [ ] **9.5** Instantiate hazard placements through shared hazard scripts.
- [ ] **9.6** Instantiate interactable placements through shared interactable scenes.
- [ ] **9.7** Add safe recovery areas and fall catch/reset behavior.
- [ ] **9.8** Add generated route labels or compact debug overlay for segment IDs and validation status.

Accept:

- [ ] Generated lane is playable from spawn to exit for valid route plans.
- [ ] Enemies, hazards, interactables, and exit all use shared runtime contracts.
- [ ] Regenerating does not leave duplicate old nodes or stale signals.

Guard:

- [ ] Generated node cleanup must be scoped to the generated-lane root only.

### Phase 10 - Miniature Game Loop

Goal: make generated landscape mode feel like a small playable run, not a static preview.

Source owners touched: `MotionTestStage.gd`, `RunState.gd`, `SignalBus.gd`, `HUD.gd`, `SettingsPopup.gd` or new testbed panel.

- [ ] **10.1** Add UI controls for generator mode, seed entry, random seed, regenerate, and replay same seed.
- [ ] **10.2** Track active seed, selected profile, ability flags, route length, segment list, enemy count, hazard count, interactable count, validation status, clear/fail status, and clear time.
- [ ] **10.3** Add route start/reset behavior that respawns the player at generated spawn.
- [ ] **10.4** Add clear condition through generated exit.
- [ ] **10.5** Add fail/death summary and replay/regenerate choices.
- [ ] **10.6** Reject invalid generation with visible reason or retry within a bounded retry count.
- [ ] **10.7** Add manual test seed list: one movement-only seed, one combat seed, one hazard seed, one mixed seed, and one intentionally invalid or edge-case seed.

Accept:

- [ ] A tester can enter a seed, generate a landscape, play it, clear or fail, replay same seed, and generate a new seed.
- [ ] Same seed reproduces the same route under the same profile/ability/mode.
- [ ] Invalid route reasons are visible and not silently spawned.

Guard:

- [ ] The miniature loop must not hide failures by auto-skipping required content.

### Phase 11 - Exit, Clear, And No-Soft-Lock Gate

Goal: lock the testbed completion path so passing it means something.

Source owners touched: `StageBase.gd`, `ExitPortal.gd`, `MotionTestStage.gd`, `HUD.gd`, `SignalBus.gd`.

- [ ] **11.1** Decide whether authored lane completion is tracked by checkpoints, area triggers, interaction results, or generated summary.
- [ ] **11.2** Prevent final exit clear until required authored validations and generated mini-run are completed or explicitly skipped in debug mode.
- [ ] **11.3** Label debug skip actions in HUD/settings if any exist.
- [ ] **11.4** Show final clear summary with profile, ability flags, seed, route mode, and required validations passed.
- [ ] **11.5** Add reset/restart route for failed validation.

Accept:

- [ ] Testbed clear implies movement, combat, interaction, input visibility, and generated route were actually exercised.
- [ ] Debug skip cannot be mistaken for normal clear.

Guard:

- [ ] Do not block the user behind a bug without a reset/reload path.

### Phase 12 - Verification, Tuning, And Handoff

Goal: prove the testbed is ready to guide Stage01/Stage02/Stage03 work.

Source owners touched: docs, optional test scripts, final scene/source changes.

- [ ] **12.1** Run Godot smoke command through `.\tools\godot.ps1`.
- [ ] **12.2** Manually test the authored route with Warrior, Archer, and Assassin.
- [ ] **12.3** Manually test the advanced route with ability off and on.
- [ ] **12.4** Manually test enemy contact damage, player attack, enemy defeat/reset, hazard damage, and player death/reload.
- [ ] **12.5** Manually test NPC/object prompt, interaction result, and prompt hiding.
- [ ] **12.6** Manually test binding guide/settings and confirm guide matches actual input map.
- [ ] **12.7** Manually test generated seeds for all generator profiles.
- [ ] **12.8** Replay one seed twice and compare route summary.
- [ ] **12.9** Run static guards: `rg` for duplicated input action strings, old dummy-only assumptions, and generator-only damage paths.
- [ ] **12.10** Update `MOTION_TEST_BED_SPEC.md` only if implementation reveals a better durable rule.
- [ ] **12.11** Commit scoped batches; do not mix unrelated work.

Accept:

- [ ] Testbed can be launched and cleared by following in-game guidance.
- [ ] No required route soft locks are found in the manual profile pass.
- [ ] Generated route validation catches invalid layouts before play.
- [ ] Worktree is clean after final commit.

Guard:

- [ ] Do not treat a single happy-path generated seed as enough validation.

## Validation Cadence

Inner-loop checks:

- [ ] Use `.\tools\godot.ps1 --path . --headless --quit` after script or scene ownership changes when practical.
- [ ] Use Godot editor/manual launch for movement feel, route dimensions, and UI visibility.
- [ ] Use targeted `rg` checks after input, generator, or damage ownership changes.
- [ ] Use one or two known seeds for fast generator iteration.

Batch gates:

- [ ] After Phase 2: manually clear authored movement route with all three profiles.
- [ ] After Phase 4: manually damage and kill/reset real enemy.
- [ ] After Phase 7: confirm binding guide displays actual input map.
- [ ] After Phase 9: regenerate the lane three times and confirm old nodes/signals do not remain.
- [ ] After Phase 10: replay the same seed twice and compare route summary.

Final gates:

- [ ] Godot smoke command through `.\tools\godot.ps1`.
- [ ] Full manual testbed clear with least-mobile required profile.
- [ ] Manual generated seed matrix: movement-only, combat, hazard, mixed, edge/invalid.
- [ ] UI check at 1280x720 and one narrower viewport if supported.
- [ ] `git diff --check`.
- [ ] Final commit with scoped changed files.

Rerun policy:

- [ ] Rerun failed narrow checks only after a concrete code or scene change.
- [ ] Rerun full manual pass only after batch gates are green or a shared foundation changes.
- [ ] Record known engine warnings instead of rediscovering them repeatedly.

Tool fallback:

- [ ] If headless Godot is insufficient for gameplay validation, use manual launch through fastrun/Godot.
- [ ] If screenshot automation fails twice for tool reasons, use targeted manual inspection and document the limitation.

## Guard Checks

- [ ] Grep/static guard: every current input action name is defined in one shared place and visible in the binding UI.
- [ ] Duplicate-owner guard: movement metric formulas exist in one helper, not repeated in stage and generator code.
- [ ] Old-path guard: `DamageDummy` is not the only enemy referenced by the combat lane.
- [ ] Generated-route guard: generator cannot mark a critical path valid if any required segment needs a disabled ability.
- [ ] Damage-path guard: enemies, hazards, and attacks all route through `DamageInfo` or a documented equivalent.
- [ ] Interaction guard: non-exit interaction exists and uses the same prompt path as other interactables.
- [ ] UI guard: HUD/settings text does not cover the player or core combat lane at 1280x720.
- [ ] Cleanup guard: regeneration removes only generated-lane nodes.
- [ ] No unrelated changes guard: commits remain scoped to the testbed plan or implementation phase.

## Error Handling

- Missing Godot runtime: use `.\tools\godot.ps1` resolution first; report the missing runtime and do not edit around it.
- Conflicting docs: prefer current user corrections, then `MOTION_TEST_BED_SPEC.md`, then PRD.
- Failed generated route validation: show the failure reason and keep the previous valid route or empty generated lane.
- Generation retry exhaustion: stop after a bounded retry count and show invalid status.
- Failed manual movement route: adjust metric limits or platform dimensions, then retest with the least-mobile profile.
- Binding conflict: reject duplicate remap or label remap as deferred.
- Scene corruption risk: make small scene edits or script-generated layout helpers, then smoke test.
- Ambiguous ability scope: implement as debug-only testbed ability and label it clearly until card/skill systems own it.

## Goal Completion Criteria

- [ ] Required artifacts exist: authored validation lanes plus generated miniature game lane.
- [ ] The HUD or settings UI explains all required controls in-game.
- [ ] Movement obstacles are tied to profile metrics.
- [ ] Real enemy combat, hazard damage, and non-exit interaction are all testable.
- [ ] Generated landscape can be created from a seed, validated, played, replayed, and regenerated.
- [ ] Same seed/profile/ability/mode produces the same route summary.
- [ ] Invalid generated routes are rejected or visibly reported.
- [ ] Exit/clear flow proves the required path was exercised.
- [ ] Required checks and manual test matrix are recorded in the final handoff.

## Goal Stop Conditions

Complete the goal when:

- [ ] The miniature testbed is playable end to end.
- [ ] All final gates pass or any skipped gate has a concrete reason.
- [ ] No required implementation work remains for this plan.

Ask the user when:

- [ ] A choice would change the product direction, such as making double jump default, changing canonical controls, adding external assets, or promoting full procedural region generation into this phase.
- [ ] A destructive cleanup would remove existing user-authored work.

Mark blocked when:

- [ ] The same runtime/tool blocker prevents meaningful progress for three consecutive goal turns and no local fallback exists.

Do not stop when:

- [ ] The work is large but still progressing.
- [ ] A validation failure points to a concrete fix.
- [ ] A later phase would benefit from more polish but the current phase has a clear next task.

## Next Steps

The next implementation session should start with Phase 0 and Phase 1:

- [ ] Confirm the Godot launch path and baseline warnings.
- [ ] Add the shared movement metric helper.
- [ ] Add visible metric and ability-flag output to HUD/debug UI.
- [ ] Only then rebuild the authored lanes.

## Handoff Prompt

Use this prompt when starting the implementation goal:

```text
Goal: Implement the MVP-ish motion testbed miniature game for Cardborne Platformer.

Read first:
- AGENTS.md
- .agent/PLANS.md
- docs/design/MOTION_TEST_BED_MVP_PLAN.md
- docs/design/MOTION_TEST_BED_SPEC.md
- docs/product/2d_platform_action_card_game_prd.md
- docs/architecture/FIRST_SLICE_ARCHITECTURE.md

Follow this checklist:
- Start at Phase 0.
- Keep changes sequential and scoped.
- Reuse shared contracts before adding content.
- Treat generated landscape as segment-template runtime terrain, not full procedural region graph runtime.

Produce:
- Playable authored validation lanes.
- Playable seeded generated miniature run.
- Verification notes in the final response or a scoped handoff if interrupted.

Stop when:
- The testbed can be launched, understood from in-game UI, cleared through required authored and generated routes, and replayed by seed.
```
