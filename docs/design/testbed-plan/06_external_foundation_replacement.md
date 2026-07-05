---
type: plan
status: active
created: 2026-07-05
source: User request on 2026-07-05 to convert external codebase deep-dive findings into a detailed implementation checklist
scope: Step-by-step partial replacement plan for the testbed foundation using selected external sources
related:
  - ../TESTBED_REIMPLEMENTATION_CONTRACT.md
  - ./FEATURE_PRIORITY.md
  - ./00_foundation_contracts.md
  - ./01_authored_lanes.md
  - ./02_combat_damage.md
  - ./03_interaction_input_ui.md
  - ./04_generated_landscape.md
  - ./05_qa_and_handoff.md
  - ../../research/external_codebase_deep_dive_2026-07-05.md
  - ../../research/foundation_resource_survey_2026-07-05.md
---

# 06 - External Foundation Replacement

## Purpose

Turn the external codebase deep dive into an executable implementation checklist.

This is a partial replacement plan, not a full codebase rebuild plan. The current code already contains useful project-specific contracts: player profiles, shared input actions, damage payloads, hitbox/hurtbox behavior, enemies, hazards, checkpoints, HUD/status reporting, and clear validation. The external research shows that the weakest foundation is the script-built map pipeline, followed by missing persistent input remap and rough movement/combat feel.

The plan therefore replaces the weak foundation slices in this order:

1. authored map pipeline,
2. imported element marker resolver,
3. imported playable dungeon route,
4. persistent input remap,
5. movement and combat refinements,
6. template-based generated pockets.

## Scope

This plan applies to the next serious foundation pass after the current prototype testbed.

In scope:

- installing or spiking Godot LDtk Importer,
- documenting LDtk/entity/map authoring contracts before broad map work,
- creating one imported side-view dungeon proof route,
- building a marker resolver that converts imported map entities into existing stage/player/enemy/combat contracts,
- preserving the current testbed as a legacy baseline until the imported route is playable,
- adding persistent remap using KoBeWi ControlsRemap or a local equivalent,
- refining local player/enemy/combat behavior using external references without replacing the project-specific contracts,
- adapting GDQuest-style template generation after authored imported rooms work,
- recording license/version/copy paths for every adopted package.

Out of scope:

- full codebase deletion,
- engine migration,
- adopting a monolithic platformer controller,
- adopting full LimboAI before simple enemy scripts are proven insufficient,
- adopting Maaack Game Template before map/controller blockers are solved,
- building final art/audio,
- implementing production cards, shop/rest, or boss content during the map pipeline spike,
- running two map editor pipelines at the same time.

## Progress

Already done before this plan:

- [x] Current testbed contracts exist in `TESTBED_REIMPLEMENTATION_CONTRACT.md`.
- [x] Feature priority matrix separates immediate and later work.
- [x] External resource survey exists.
- [x] External codebase deep dive inspected local clones, source files, logs, and license signals.
- [x] P0 source picks are identified:
  - [x] Godot LDtk Importer for authored map pipeline.
  - [x] KoBeWi ControlsRemap for persistent remap core.
  - [x] GDQuest random walker demos as procedural reference.
  - [x] Ultimate Platformer Controller as movement reference only.
  - [x] LimboAI demo components as combat/enemy reference only.

Not done yet:

- [ ] No LDtk importer is installed in this repo.
- [ ] No LDtk map source exists in this repo.
- [x] Map authoring schema exists in `docs/design/MAP_AUTHORING_PIPELINE_CONTRACT.md`.
- [ ] No marker resolver exists.
- [ ] No imported dungeon route is playable.
- [x] Persistent keyboard input remap exists through local `InputBindings`.
- [x] Third-party adoption ledger exists in `docs/research/third_party_adoption_ledger.md`.
- [ ] No generated route uses imported authored room/template descriptors.

## Strategy

Use staged replacement, not a big-bang rewrite.

Keep these existing local contracts unless a phase explicitly proves they block the replacement:

- canonical input action names,
- `CharacterProfile` resources,
- profile-aware movement metrics,
- `DamageInfo`,
- player `Hitbox`,
- combat `Hurtbox`,
- enemy base behavior and current enemy scenes,
- `StageBase` checkpoint/respawn flow,
- HUD/settings shells,
- clear validation reporting.

Replace or add these slices first:

- map source of truth moves from script-built rectangles to authored/imported map data,
- imported map entity markers become the stable authoring interface,
- runtime stage assembly becomes marker-driven,
- settings popup becomes actually remappable,
- generated routes use authored templates and passability metadata.

## External Source Policy For This Plan

- [ ] Every adopted external package must record source URL.
- [ ] Every adopted external package must record commit hash or release version.
- [ ] Every adopted external package must record license file path.
- [ ] Every copied external file or folder must be listed.
- [ ] Every adopted asset with attribution requirements must have attribution text recorded before commit.
- [ ] External code must sit behind a local wrapper, resolver, or adapter when possible.
- [ ] External editor/entity terms must not leak into player, combat, enemy, or UI code.
- [ ] If a package fails import/build validation, pause adoption and either patch locally with notes or downgrade it to reference-only.

## Tasks

### Phase 0 - Preflight And Baseline Lock

Goal: start from a known runtime and avoid confusing prototype regressions with importer problems.

- [x] **0.1** Confirm the working tree is clean or identify unrelated user changes.
- [x] **0.2** Record current commit hash before external changes.
- [x] **0.3** Run Godot version check with `.\tools\godot.ps1 --version`.
- [x] **0.4** Run baseline headless import with `.\tools\godot.ps1 --path . --headless --import`.
- [x] **0.5** Run current project boot check with the existing fastrun command or `.\tools\godot.ps1 --path .`.
- [x] **0.6** Save baseline result notes in the phase commit message or a short verification note.
- [x] **0.7** Confirm current `MotionTestStage` remains runnable before replacing map flow.
- [x] **0.8** Confirm the current HUD shows controls, profile, seed, and validation state.
- [x] **0.9** Confirm the current attack key binding is visible and still defaults to `F` unless remapped.
- [x] **0.10** Confirm no Godot/editor process remains running before package import.

Accept:

- [x] Baseline project imports without missing scripts.
- [x] Baseline stage can still be launched.
- [x] Existing testbed can remain as fallback during map pipeline work.

Stop if:

- [ ] Baseline boot is already broken for reasons unrelated to external adoption.
- [ ] The current working tree has user changes that overlap the files to be replaced and cannot be safely preserved.

### Phase 1 - Third-Party Adoption Ledger

Goal: make license/version/copy-path tracking durable before importing code.

Source owners likely touched:

- `docs/research/`
- optionally `docs/architecture/`

- [x] **1.1** Create `docs/research/third_party_adoption_ledger.md` as `type: evidence`, `status: active`.
- [x] **1.2** Add an entry template with package name, purpose, source URL, commit/release, license, copied paths, local modifications, validation commands, attribution needs, and adoption status.
- [x] **1.3** Add Godot LDtk Importer candidate entry from the deep dive.
- [x] **1.4** Add KoBeWi ControlsRemap candidate entry from the deep dive.
- [x] **1.5** Add reference-only entries for GDQuest procedural demos, Ultimate Platformer Controller, and LimboAI demo components.
- [x] **1.6** Mark Maaack Game Template, Maaack Input Remapping, Metroidvania System, YATI, and Dialogic as deferred candidates.
- [x] **1.7** For any copied package, update the ledger in the same commit that copies the package.

Accept:

- [x] A future agent can tell which external code was copied, which was only inspected, and which was only reference material.
- [x] License and attribution requirements are visible without reopening chat history.

Stop if:

- [ ] A selected package has unclear or incompatible license terms.
- [ ] A selected package includes assets with attribution requirements that cannot be tracked.

### Phase 2 - Map Authoring Pipeline Contract

Goal: define the map pipeline before code or LDtk files multiply.

Source owners likely touched:

- new `docs/design/MAP_AUTHORING_PIPELINE_CONTRACT.md`
- optional links from this plan and `TESTBED_REIMPLEMENTATION_CONTRACT.md`

- [x] **2.1** Create a map authoring pipeline contract as `type: spec`, `status: active`.
- [x] **2.2** Define the selected editor for the first spike: LDtk.
- [x] **2.3** Define fallback editor policy: YATI/Tiled is only evaluated if LDtk spike fails.
- [x] **2.4** Define map scale in pixels per tile and tile size.
- [x] **2.5** Define room bounds as ratios and viewport spans, not hard-coded absolute map sizes.
- [x] **2.6** Define supported room roles:
  - [x] `start`
  - [x] `movement`
  - [x] `vertical`
  - [x] `combat`
  - [x] `hazard`
  - [x] `interaction`
  - [x] `destructible`
  - [x] `generated_socket`
  - [x] `exit`
- [x] **2.7** Define required LDtk layers:
  - [x] `Terrain`
  - [x] `OneWay`
  - [x] `Hazards`
  - [x] `Decor`
  - [x] `Entities`
  - [x] optional `Debug`
- [x] **2.8** Define collision layer expectations for imported terrain, one-way platforms, hazards, interactables, enemies, player, and projectiles.
- [x] **2.9** Define required entity names:
  - [x] `PlayerSpawn`
  - [x] `Checkpoint`
  - [x] `CameraBounds`
  - [x] `RoomBounds`
  - [x] `EnemySpawn`
  - [x] `HazardSpawn`
  - [x] `DestructibleSpawn`
  - [x] `InteractableSpawn`
  - [x] `Climbable`
  - [x] `OneWayPlatformMarker`
  - [x] `ExitPortal`
  - [x] `GeneratedSocket`
  - [x] `ValidationGate`
- [x] **2.10** Define required fields per entity.
- [x] **2.11** Define field value enums for enemy type, hazard type, interactable type, destructible type, climbable type, required ability, room role, route role, and validation gate id.
- [x] **2.12** Define socket vocabulary:
  - [x] `left`
  - [x] `right`
  - [x] `up`
  - [x] `down`
  - [x] `branch`
  - [x] `return`
  - [x] `generated_entry`
  - [x] `generated_exit`
- [x] **2.13** Define passability rules:
  - [x] least-mobile profile can clear critical path,
  - [x] optional routes may require advanced ability flags,
  - [x] every fall has recovery or checkpoint,
  - [x] every room has camera bounds,
  - [x] no required route shows the entire map at once.
- [x] **2.14** Define marker validation output fields:
  - [x] missing required marker,
  - [x] unknown entity type,
  - [x] missing field,
  - [x] invalid enum,
  - [x] impossible route,
  - [x] duplicate id,
  - [x] spawn cap violation.
- [x] **2.15** Define what remains hidden behind the resolver:
  - [x] raw LDtk dictionaries,
  - [x] importer-specific nodes,
  - [x] external field naming quirks,
  - [x] tile editor metadata.

Accept:

- [x] A future map can be authored from the contract without reading resolver code.
- [x] A future resolver can be written from the contract without reading the LDtk file by hand.
- [x] Player/combat/enemy scripts do not need to know LDtk internals.

Stop if:

- [ ] The map contract cannot express current checkpoint, enemy, hazard, destructible, climbable, interactable, generated socket, and exit needs.

### Phase 3 - Install Godot LDtk Importer Spike

Goal: prove the selected importer works inside this repo before building serious maps.

Source owners likely touched:

- `addons/ldtk-importer/`
- `project.godot`
- adoption ledger

- [ ] **3.1** Choose exact importer source: `https://github.com/heygleeson/godot-ldtk-importer`.
- [ ] **3.2** Choose exact commit or release before copying.
- [ ] **3.3** Copy only required importer files into `addons/ldtk-importer/`.
- [ ] **3.4** Preserve the upstream `LICENSE`.
- [ ] **3.5** Enable the plugin in `project.godot`.
- [ ] **3.6** Record copied paths and commit hash in the adoption ledger.
- [ ] **3.7** Run `.\tools\godot.ps1 --path . --headless --import`.
- [ ] **3.8** Inspect import log for missing classes, parse errors, GDScript errors, or plugin warnings.
- [ ] **3.9** Run a project boot check.
- [ ] **3.10** If import fails, patch only the minimum necessary compatibility issue and record it in the ledger.
- [ ] **3.11** If import still fails after a bounded attempt, remove the copied addon and mark LDtk spike blocked.

Accept:

- [ ] Project imports with the LDtk addon enabled.
- [ ] Project boot still reaches the current main scene.
- [ ] No existing testbed script depends on LDtk yet.

Stop if:

- [ ] The plugin cannot be enabled without breaking existing project import.
- [ ] The plugin requires a dependency or engine variant outside the MVP Godot 4.x GDScript target.

### Phase 4 - Minimal LDtk Source Map

Goal: create the smallest real side-view dungeon source that exercises the marker contract.

Source owners likely touched:

- `maps/` or `data/maps/` if a source-map folder already exists or is created deliberately,
- imported generated files under the Godot project,
- map contract,
- adoption ledger if needed.

- [ ] **4.1** Create a clear folder for authored map sources.
- [ ] **4.2** Add a README in that folder explaining source vs imported output if the folder is new.
- [ ] **4.3** Create one LDtk world for the first imported route.
- [ ] **4.4** Use placeholder tiles only; do not import CC-BY art during the first spike.
- [ ] **4.5** Author at least two connected room-like areas.
- [ ] **4.6** Include a start area with safe floor.
- [ ] **4.7** Include side walls, ceiling, lower/bottom space, and enclosed dungeon framing.
- [ ] **4.8** Include a camera-followed route larger than one default viewport.
- [ ] **4.9** Include verticality through a climbable, shaft, stairs, or ledge chain.
- [ ] **4.10** Include a jump gap derived from movement metrics.
- [ ] **4.11** Include one `PlayerSpawn`.
- [ ] **4.12** Include at least one `Checkpoint`.
- [ ] **4.13** Include one `CameraBounds`.
- [ ] **4.14** Include at least two `EnemySpawn` markers using different enemy types.
- [ ] **4.15** Include one `HazardSpawn`.
- [ ] **4.16** Include one `DestructibleSpawn`.
- [ ] **4.17** Include one `InteractableSpawn`.
- [ ] **4.18** Include one `Climbable`.
- [ ] **4.19** Include one `ExitPortal`.
- [ ] **4.20** Include one `GeneratedSocket`, even if generation is not implemented yet.
- [ ] **4.21** Import the map and inspect generated scene output.
- [ ] **4.22** Confirm imported layers and entity data are accessible to scripts.
- [ ] **4.23** Commit only after import output is stable enough to diff.

Accept:

- [ ] The LDtk source is human-readable in a level editor.
- [ ] The imported scene appears in Godot.
- [ ] The imported scene has accessible entity data for every required marker.
- [ ] The imported route visually resembles a side-view dungeon rather than floating platforms.

Stop if:

- [ ] Entity fields cannot be recovered reliably from the importer.
- [ ] Imported output is too unstable or noisy to maintain in git.

### Phase 5 - Marker Resolver Contract And Runtime

Goal: convert imported markers into local gameplay scenes while hiding LDtk-specific details.

Source owners likely touched:

- `scripts/stages/`
- optional `scripts/stages/import/`
- optional `scripts/stages/map_import/`
- `scenes/stages/`
- map authoring contract

- [ ] **5.1** Create a resolver responsibility boundary before coding.
- [ ] **5.2** Name the public resolver API in project language, not LDtk language.
- [ ] **5.3** Create a `StageImportReport` or equivalent data shape.
- [ ] **5.4** Create a `StageMarker` or equivalent normalized marker shape.
- [ ] **5.5** Add marker extraction from imported entity layers.
- [ ] **5.6** Normalize positions into stage-local coordinates.
- [ ] **5.7** Normalize entity ids and field names.
- [ ] **5.8** Validate required marker types.
- [ ] **5.9** Validate required fields.
- [ ] **5.10** Validate enum values.
- [ ] **5.11** Validate duplicate ids.
- [ ] **5.12** Validate enemy/spawner caps.
- [ ] **5.13** Instantiate player spawn reference, not the player itself unless current stage flow expects it.
- [ ] **5.14** Instantiate or bind checkpoints through existing checkpoint contracts.
- [ ] **5.15** Instantiate enemies through existing enemy scenes.
- [ ] **5.16** Instantiate hazards through existing hazard scenes.
- [ ] **5.17** Instantiate destructibles through existing destructible scenes.
- [ ] **5.18** Instantiate interactables through existing interactable scenes.
- [ ] **5.19** Instantiate climbables through existing climbable scenes.
- [ ] **5.20** Instantiate exit portal through existing exit scene.
- [ ] **5.21** Apply camera bounds from imported markers.
- [ ] **5.22** Preserve existing `StageBase` checkpoint/death/fall recovery.
- [ ] **5.23** Report validation errors to HUD/debug output.
- [ ] **5.24** Add a hard failure for missing critical markers.
- [ ] **5.25** Add a soft warning path for optional unknown markers.
- [ ] **5.26** Keep raw imported node access inside resolver files only.

Accept:

- [ ] Imported markers instantiate the same kind of runtime actors as script-built prototype lanes.
- [ ] A missing critical marker blocks stage start with a readable error.
- [ ] HUD/debug status can display import validation results.
- [ ] Player, enemy, combat, and UI scripts do not parse LDtk data directly.

Stop if:

- [ ] The resolver requires broad changes to player/combat/enemy contracts before a playable route exists.
- [ ] Marker extraction is too fragile to support future maps.

### Phase 6 - Imported Dungeon Test Stage

Goal: create a playable stage that proves the imported route can replace the script-built serious map path.

Source owners likely touched:

- `scenes/stages/`
- `scripts/stages/`
- `scenes/main/` if stage selection changes,
- HUD/settings only if display hooks are needed.

- [ ] **6.1** Create a new imported test stage scene instead of destroying `MotionTestStage` immediately.
- [ ] **6.2** Attach or call the marker resolver from the imported stage.
- [ ] **6.3** Spawn the player at imported `PlayerSpawn`.
- [ ] **6.4** Apply imported camera bounds.
- [ ] **6.5** Confirm the camera follows the player and does not show the whole map.
- [ ] **6.6** Confirm checkpoint activation and respawn.
- [ ] **6.7** Confirm fall reset from a lower area.
- [ ] **6.8** Confirm enemy spawns.
- [ ] **6.9** Confirm enemy damage reception and knockback.
- [ ] **6.10** Confirm player damage reception from enemy or hazard.
- [ ] **6.11** Confirm destructible can be destroyed and route changes.
- [ ] **6.12** Confirm interactable prompt appears only in range.
- [ ] **6.13** Confirm climbable traversal works.
- [ ] **6.14** Confirm exit portal exists and can be gated by validation.
- [ ] **6.15** Add imported-route validation to HUD.
- [ ] **6.16** Add a debug way to return to the legacy testbed if stage switching exists.

Accept:

- [ ] A tester can play from imported spawn to imported exit.
- [ ] The imported route proves movement, combat, destructible, interaction, hazard, checkpoint, and climbable contracts.
- [ ] Existing script-built testbed remains available until this stage reaches parity.

Stop if:

- [ ] The imported stage cannot run without bypassing checkpoint or damage contracts.
- [ ] The imported stage requires one-off enemy/hazard/destructible code that duplicates existing systems.

### Phase 7 - Replace Serious Map Path, Keep Legacy Baseline

Goal: promote imported map pipeline to primary testbed route only after it proves parity.

Source owners likely touched:

- `scenes/main/Main.tscn`
- `scripts/main/Main.gd`
- current stage selection paths,
- docs.

- [ ] **7.1** Define which route is now primary: imported dungeon test stage.
- [ ] **7.2** Keep script-built `MotionTestStage` as `LegacyMotionTestStage` or a debug-only fallback if practical.
- [ ] **7.3** Update launch flow or fastrun command to open the imported route by default.
- [ ] **7.4** Update HUD labels so testers know they are in imported dungeon testbed.
- [ ] **7.5** Remove only obsolete script-built map assembly after imported route covers its required tests.
- [ ] **7.6** Do not delete player, combat, enemy, checkpoint, HUD, or settings contracts unless replacement is proven.
- [ ] **7.7** Mark any superseded old map docs or notes only after durable requirements are promoted.
- [ ] **7.8** Update `FEATURE_PRIORITY.md` progress when imported primary route is active.

Accept:

- [ ] Default test command opens the imported route.
- [ ] Legacy route remains available or has been safely retired with docs updated.
- [ ] No required testbed proof is lost.

Stop if:

- [ ] Imported route does not yet cover a required testbed proof.
- [ ] Removing legacy code would make debugging harder before the imported route is stable.

### Phase 8 - Persistent Input Remap

Goal: make settings popup actually edit saved bindings without importing a heavy shell UI.

Source owners likely touched:

- `addons/ControlsRemap/` if adopting KoBeWi directly,
- or `scripts/autoload/` / `scripts/ui/` if reimplementing locally,
- `scenes/ui/SettingsPopup.tscn`,
- `scripts/ui/SettingsPopup.gd`,
- `project.godot`,
- adoption ledger.

- [x] **8.1** Decide direct adopt vs local reimplementation of KoBeWi ControlsRemap pattern.
- [x] **8.2** No package was copied; KoBeWi ControlsRemap is recorded as reference-only in the adoption ledger.
- [x] **8.3** Define tracked action list from canonical project actions.
- [x] **8.4** Load saved remap at boot.
- [x] **8.5** Apply remap to `InputMap`.
- [x] **8.6** Save only changed bindings or a clear complete binding profile.
- [x] **8.7** Add restore default for all actions.
- [x] **8.8** Add restore default for one action if cheap.
- [x] **8.9** Add duplicate binding detection.
- [x] **8.10** Add visible duplicate warning in settings popup.
- [x] **8.11** Add visible "press key" capture state.
- [x] **8.12** Ensure `attack` can be remapped.
- [x] **8.13** Ensure HUD reads current binding after remap.
- [x] **8.14** Ensure settings popup reads current binding after remap.
- [x] **8.15** Ensure remap persists across project restart.
- [x] **8.16** Explicitly document unsupported device types for this pass if mouse/gamepad axes are deferred.

Accept:

- [x] Tester can change attack key from `F` to another key.
- [x] HUD updates to show the new attack key.
- [x] Restarting the game keeps the remapped key.
- [x] Restore defaults works.
- [x] Duplicate binding is blocked or clearly warned.

Stop if:

- [ ] Remap changes canonical action names.
- [ ] Remap breaks UI navigation actions.
- [ ] Remap requires adopting a full options template before map replacement is stable.

### Phase 9 - Movement Refinement From References

Goal: improve local controller feel without replacing profile-aware movement.

Source owners likely touched:

- `scripts/player/PlayerController.gd`
- `scripts/player/MovementMetrics.gd`
- `scripts/player/CharacterProfile.gd`
- profile resources under `data/characters/`
- movement test map if needed.

- [ ] **9.1** Review current movement values against imported route geometry.
- [ ] **9.2** Confirm current coyote time and jump buffer behavior.
- [ ] **9.3** Add or tune variable jump release.
- [ ] **9.4** Add or tune dash recovery and cooldown.
- [ ] **9.5** Keep dash count/style profile-driven.
- [ ] **9.6** Keep double jump as ability/profile flag.
- [ ] **9.7** Add wall slide only if the imported map has a clear wall traversal test.
- [ ] **9.8** Add wall latch only if wall slide alone does not satisfy the route.
- [ ] **9.9** Add wall jump only after wall slide/latch collision behavior is stable.
- [ ] **9.10** Add corner correction only if imported ledge geometry exposes repeated unfair misses.
- [ ] **9.11** Update `MovementMetrics` to include any new traversal capability.
- [ ] **9.12** Ensure critical path validation uses least-mobile required profile metrics.
- [ ] **9.13** Ensure optional branches declare advanced requirements.
- [ ] **9.14** Update HUD/debug movement metrics display if new abilities are active.
- [ ] **9.15** Keep animation state separate from physics logic where practical.

Accept:

- [ ] Imported critical path is clearable by the intended least-mobile profile.
- [ ] Optional advanced branch is clearable by the intended advanced ability profile.
- [ ] Movement failures feel explainable, not caused by hidden map geometry.
- [ ] Profile differences remain visible.

Stop if:

- [ ] A generic external controller would erase `CharacterProfile` or `MovementMetrics`.
- [ ] Wall traversal destabilizes core jump/dash route before map pipeline is proven.

### Phase 10 - Combat And Enemy Refinement From References

Goal: preserve current combat contracts while making hit reaction, enemy variety, and attack readability less rough.

Source owners likely touched:

- `scripts/combat/`
- `scripts/enemies/`
- `scripts/player/`
- enemy scenes under `scenes/enemies/`
- player scene and profile resources.

- [ ] **10.1** Compare current `DamageInfo`, `Hitbox`, and `Hurtbox` with LimboAI demo component separation.
- [ ] **10.2** Keep current `DamageInfo` if it already carries source, amount, knockback, and tags.
- [ ] **10.3** Add or refine enemy knockback on hit.
- [ ] **10.4** Add brief enemy AI interruption on hit.
- [ ] **10.5** Add visible hit flash or placeholder hit feedback.
- [ ] **10.6** Add death/reset behavior parity for imported enemies.
- [ ] **10.7** Keep enemy state machine simple unless a concrete enemy needs more.
- [ ] **10.8** Verify Walker, Charger, Shooter still work in imported stage.
- [ ] **10.9** Add one additional enemy only if imported map needs variety:
  - [ ] shield guard,
  - [ ] leaper,
  - [ ] turret,
  - [ ] summoner with strict active/lifetime caps.
- [ ] **10.10** Ensure every spawner has active cap and lifetime cap.
- [ ] **10.11** Ensure each damaging enemy attack has readable startup, active, and recovery states.
- [ ] **10.12** Keep Assassin, Warrior, and Archer attack identities profile-driven.
- [ ] **10.13** Ensure Archer projectile uses shared hitbox/damage path.
- [ ] **10.14** Ensure melee swing visuals match active hit frames closely enough for testing.

Accept:

- [ ] Enemies visibly react to hits.
- [ ] Enemy knockback does not push enemies through collision or soft-lock routes.
- [ ] Player can test Warrior, Assassin, and Archer attacks against real enemies.
- [ ] Summon/spawn behavior cannot grow unbounded.

Stop if:

- [ ] Enemy behavior complexity suggests full behavior tree adoption before map and combat basics are stable.
- [ ] Hit reaction requires one-off code per enemy instead of shared enemy/combat contracts.

### Phase 11 - Template-Based Generated Pocket

Goal: adapt GDQuest-style path-first chunk assembly to project-specific imported/authored templates.

Source owners likely touched:

- `scripts/stages/`
- optional `scripts/stages/generation/`
- optional data/resources under `data/`
- imported map source if generated sockets are authored there.

- [ ] **11.1** Define `RoomTemplateDescriptor` or equivalent local data shape.
- [ ] **11.2** Define template id, size, route role, sockets, required abilities, enemy budget, hazard budget, interactable budget, destructible budget, and checkpoint policy.
- [ ] **11.3** Convert one imported room or authored segment into a template descriptor.
- [ ] **11.4** Convert a second imported room or segment into a template descriptor.
- [ ] **11.5** Add deterministic RNG from seed.
- [ ] **11.6** Generate path-first route plan before instantiating anything.
- [ ] **11.7** Validate sockets before instantiating.
- [ ] **11.8** Validate movement metrics before instantiating.
- [ ] **11.9** Validate enemy/hazard/spawner budgets before instantiating.
- [ ] **11.10** Instantiate generated pocket at imported `GeneratedSocket`.
- [ ] **11.11** Connect generated entry and exit back to authored route.
- [ ] **11.12** Add side-fill or sealed boundary rules so generated area does not look empty.
- [ ] **11.13** Report seed, template ids, route span, validation result, and failure reason to HUD/debug.
- [ ] **11.14** Add replay same seed.
- [ ] **11.15** Add random seed.
- [ ] **11.16** Add bounded retry or visible invalid-route rejection.

Accept:

- [ ] Same seed and same profile/ability flags produce same generated pocket.
- [ ] Generated pocket connects cleanly to authored imported route.
- [ ] Generated pocket is camera-followed and not shown as a full overview.
- [ ] Invalid seeds fail visibly instead of silently producing broken layouts.

Stop if:

- [ ] Generated pocket requires arbitrary tile noise.
- [ ] Generated route ignores movement metrics.
- [ ] Generated route bypasses checkpoint/fall recovery contracts.

### Phase 12 - Documentation Reconciliation

Goal: keep the strict docs usable after implementation changes.

Source owners likely touched:

- this plan,
- `FEATURE_PRIORITY.md`,
- `TESTBED_REIMPLEMENTATION_CONTRACT.md`,
- map authoring contract,
- adoption ledger,
- phase docs as needed.

- [x] **12.1** Update this plan's completed checkboxes as each phase lands.
- [x] **12.2** Update `FEATURE_PRIORITY.md` progress when persistent remap is implemented.
- [ ] **12.3** Update `FEATURE_PRIORITY.md` progress when imported route becomes primary.
- [ ] **12.4** Update `04_generated_landscape.md` when generated pocket uses template descriptors.
- [x] **12.5** Add map authoring contract link to `TESTBED_REIMPLEMENTATION_CONTRACT.md`.
- [ ] **12.6** If legacy map code is retired, document what replaced it.
- [ ] **12.7** If any external package is removed, update adoption ledger.
- [ ] **12.8** If any active plan becomes complete, mark it `done` only after the work is actually done.

Accept:

- [ ] Future agents can follow active docs without relying on chat history.
- [ ] Evidence docs remain advisory and plans remain actionable.
- [ ] Specs contain durable behavior, not transient status.

Stop if:

- [ ] A plan update would falsely mark implementation done.
- [ ] A research recommendation is accidentally promoted into policy without user intent.

### Phase 13 - Final QA Gate For This Replacement

Goal: prove the replacement improved the foundation rather than only changing architecture.

- [ ] **13.1** Run `.\tools\godot.ps1 --path . --headless --import`.
- [ ] **13.2** Run the saved fastrun project command.
- [ ] **13.3** Manually play imported route as Warrior.
- [ ] **13.4** Manually play imported route as Assassin.
- [ ] **13.5** Manually play imported route as Archer.
- [ ] **13.6** Confirm profile attack differences are visible.
- [ ] **13.7** Confirm checkpoint respawn after fall.
- [ ] **13.8** Confirm death respawn after damage.
- [ ] **13.9** Confirm at least two enemy archetypes work.
- [ ] **13.10** Confirm hazard warning/active/recovery behavior.
- [ ] **13.11** Confirm destructible object can be removed by attack.
- [ ] **13.12** Confirm interactable prompt and action.
- [ ] **13.13** Confirm climbable route.
- [ ] **13.14** Confirm camera never shows whole playable map at once by default.
- [ ] **13.15** Confirm remapped attack key persists after restart.
- [ ] **13.16** Confirm generated pocket same-seed replay.
- [ ] **13.17** Confirm invalid generation path reports reason.
- [ ] **13.18** Confirm no external clone/cache/log folder is staged.
- [ ] **13.19** Run `git diff --check`.
- [ ] **13.20** Commit with a scoped message.

Accept:

- [ ] Imported map pipeline is primary or explicitly ready for promotion.
- [ ] Persistent remap works.
- [ ] Existing gameplay contracts still work.
- [ ] Generated pocket is deterministic if implemented in this pass.
- [ ] Docs and adoption ledger are updated.

## Verification

Minimum verification per phase:

- [ ] Documentation-only phases: `git diff --check`.
- [ ] Package import phases: Godot headless import plus project boot check.
- [ ] Runtime map phases: manual player route through imported stage.
- [ ] Remap phase: remap, restart, and verify HUD/settings reflect saved binding.
- [ ] Movement phase: manual movement route with all three profiles.
- [ ] Combat phase: manual hit/knockback/death/reset with all three profiles.
- [ ] Generation phase: same seed replay and invalid seed rejection.

Suggested final verification command set:

```powershell
.\tools\godot.ps1 --version
.\tools\godot.ps1 --path . --headless --import
git diff --check
git status --short
```

Manual QA remains required because the main risks are movement feel, camera framing, imported map passability, and player-facing remap behavior.

## Risks

- LDtk importer may work in isolation but generate noisy or fragile project diffs.
- Imported map collision may require more TileSet setup than expected.
- A marker resolver can become a dumping ground if entity schema is not strict.
- Persistent remap can break UI actions if it edits built-in actions carelessly.
- Movement refinements can destabilize current route if wall traversal is added too early.
- Full LimboAI adoption can add build/export complexity before enemy complexity justifies it.
- Full Maaack template adoption can distract from map and controller blockers.
- Procedural generation can regress into arbitrary tile noise if templates and sockets are skipped.
- Legacy map code can become stale if it remains primary after imported route is stable.

## Rollback And Safety

- [ ] Keep the current testbed route until imported route proves parity.
- [ ] Copy external addons in isolated commits where practical.
- [ ] If LDtk importer breaks project import, revert only the addon and `project.godot` changes from that spike commit.
- [ ] If marker resolver fails, keep the imported map source but do not promote it to primary route.
- [ ] If persistent remap breaks input, provide a restore-default path and remove saved remap file during QA.
- [ ] If wall traversal destabilizes the controller, disable wall route markers and leave wall traversal explicitly deferred.
- [ ] If generated pocket fails validation, keep generated sockets authored but block runtime generation with visible reason.

## Next Steps

Start with these tasks in order:

- [x] Create `docs/research/third_party_adoption_ledger.md`.
- [x] Create `docs/design/MAP_AUTHORING_PIPELINE_CONTRACT.md`.
- [ ] Copy and enable Godot LDtk Importer in an isolated spike.
- [ ] Build the smallest LDtk source map that contains all required marker categories.
- [ ] Build marker resolver and import report.
- [ ] Make imported dungeon route playable before procedural generation or broad movement/combat refinement.
