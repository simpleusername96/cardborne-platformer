---
type: plan
status: done
created: 2026-07-02
source: User request on 2026-07-02
scope: Foundation contracts and motion test stage
related:
  - ../../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/2d_platform_action_card_game_prd.md
  - ../../docs/product/FIRST_SLICE_EXPANSION.md
  - ../../docs/architecture/FIRST_SLICE_ARCHITECTURE.md
---

# Foundation Contracts And Motion Test

## Purpose

Create the first sequential implementation slice for the Godot project: shared contracts, global state, reusable player controller, UI shells, and one motion test stage that proves the contracts before broader content work starts.

## Why / Context

The repository has active product and architecture specs, design data, generated map/UI references, and folder scaffolding, but no runtime gameplay scenes or scripts yet. This task should establish the foundation later stages, shops, rewards, enemies, and bosses will reuse.

## Domain Brief

- Request interpretation: build a strong first-pass foundation and one playable proof stage before adding feature content.
- Likely bounded context or scope: run flow, run state, player controller/profile, combat damage, stage lifecycle, interactables, and UI feedback.
- Canonical terms: character profile means a data resource that tunes the shared player controller; stage means a scene using `StageBase`; interactable means an `Area2D` that emits one interaction path; damage means a `DamageInfo` object handled through hitboxes/hurtboxes.
- Ambiguous or overloaded terms: "3 characters" is implemented as three motion-test profiles, not three independent controllers or final classes.
- Ownership boundaries: `Game` owns scene transitions; `RunState` owns run facts and effective stats; player scripts own movement/combat verbs; combat scripts own damage delivery; stage scripts own stage completion; UI scripts observe signals and call narrow commands.
- Public interfaces: `Game.start_motion_test`, `Game.load_stage`, `RunState.select_profile`, `RunState.get_effective_stat`, `StageBase.complete_stage`, `Interactable.interact`, `Hurtbox.receive_damage`, `Hitbox.set_active`.
- Hidden implementation decisions: exact scene node shapes, placeholder visuals, and future save/economy/card storage remain behind their owner scripts.
- Invariants or policies that must hold: all damaging gameplay should go through `DamageInfo`; profiles must not fork player movement; stage completion must be signal-driven; UI must not own gameplay rules.
- State transitions: app start -> new run -> motion test stage active -> exit portal interaction -> stage clear signal.
- Facts confirmed from code/docs/tests: repo has Godot 4.7 runtime, first-slice specs, generated map/UI data, and empty scene/script placeholders.
- Inference: a small runtime input bootstrap is safer than hand-maintaining verbose Godot input serialization during the first implementation.
- Open questions: final character identities and profile balance are placeholder-level until real character design begins.
- Is this actually simple CRUD?: no.

## Scope / Non-scope

In scope:

- Shared input action bootstrap.
- Autoloads for `Game`, `RunState`, and `SignalBus`.
- `StageBase`, `Interactable`, and `ExitPortal`.
- `DamageInfo`, `Hitbox`, and `Hurtbox`.
- One reusable player controller.
- Three character profile resources.
- HUD shell and settings popup shell.
- Motion test stage with platforming, a damage dummy, a hazard strip, and an exit portal.

Out of scope:

- Full card reward flow.
- Shop economy.
- Real enemy AI.
- Boss patterns.
- Production art/audio.
- Final character class design.

## Assumptions

- The first motion-test "characters" are profile resources attached to one controller.
- Placeholder shapes are acceptable and preferred for this MVP foundation.
- Runtime input action setup is acceptable as the first shared input contract; later editor input-map serialization can be generated once the action list settles.
- The motion test stage may boot directly from `Main.tscn`.

## Proposed Design

- `Game` registers main scene roots, bootstraps inputs, starts/reloads the motion test stage, toggles pause/settings, and clears loaded stages.
- `RunState` stores selected profile, health, simple run counters, and effective stat lookup.
- `SignalBus` centralizes UI/gameplay signals so UI and stage scripts do not directly depend on each other.
- `CharacterProfile` resources hold tuning values and placeholder visual color for Warrior, Archer, and Assassin profiles.
- `PlayerController` reads effective stats from `RunState` and owns motion, dash, crouch, attack, damage, invulnerability, and profile cycling.
- `Hitbox` and `Hurtbox` deliver `DamageInfo`; hazards and attacks use the same path.
- `StageBase` spawns the player and emits completion through `SignalBus`.
- `ExitPortal` derives from `Interactable` and calls the active stage completion contract.
- HUD and settings popup are built from Godot `Control` nodes with compact, functional shells.

## Milestones

1. Add plan and implementation skeleton.
2. Add autoloads, contracts, profiles, player, UI shells, main scene, and motion test stage.
3. Configure project main scene, autoloads, and collision layer names.
4. Validate with Godot import/runtime checks.
5. Run code quality and UI/UX gate checks, then mark this plan done.

## Tasks

- [x] Create foundation scripts and resources.
- [x] Create player, UI, exit portal, dummy, and motion test scenes.
- [x] Update `project.godot` for autoloads, main scene, and layer names.
- [x] Run Godot validation.
- [x] Run quality and UI/UX checks.
- [x] Retire this plan after completion.

## Progress

- Foundation contracts implemented.
- Motion test stage boots from the main scene.
- UI/UX gate passed after rendered desktop and narrow-width screenshots.
- Plan retired as done.

## Next Steps

- Continue with the next sequential slice: a proper main menu / character-select flow, or Stage01 built on `StageBase`.

## Test Plan

- Run `.\tools\godot.ps1 --path . --headless --import`.
- Run a short project startup check if the runtime supports it in the current environment.
- Validate scripts parse by loading the project through Godot.
- Render or otherwise inspect HUD/settings at desktop and narrow viewport sizes where possible.

Verification completed:

- `.\tools\godot.ps1 --path . --headless --import`
- `.\tools\godot.ps1 --path . --headless --quit-after 2`
- `.\tools\godot.ps1 --path . --script res://tools/capture_ui_screenshots.gd`
- UI screenshots inspected at 1280x720 and 390x720.
- UIUX gate pass recorded through `uiux_gate_mark_pass.ps1`.

## Rollback / Safety

- Changes are additive except `project.godot`.
- No external dependencies are added.
- Generated placeholder scenes can be removed without affecting design data.
- Do not overwrite unrelated user changes.

## Risks

- Manually authored `.tscn` files can fail import on small syntax mistakes.
- Headless visual checks may not fully prove UI rendering if the environment cannot create visible windows.
- Runtime input bootstrap means actions may not appear in the Godot editor input-map panel until a later project-settings pass.

## Open Questions

- Whether profile switching should remain a debug shortcut or move to a character-select screen in the next milestone.
- Whether the first profile labels should stay Warrior/Archer/Assassin or become original class names before content polish.

## Decision Notes

- Use three `CharacterProfile` resources for this task to honor the user's 3-character motion test need without violating the PRD's warning against multiple full playable characters before the MVP foundation.
