---
type: plan
status: superseded
superseded_by: ../../../.agent/execplans/2026-07-12-actual-game-production-roadmap.md
created: 2026-07-02
source: Split from docs/design/MOTION_TEST_BED_MVP_PLAN.md
scope: NPC/object interaction, input guide, binding list, and settings UI
related:
  - ../MOTION_TEST_BED_MVP_PLAN.md
  - ../MOTION_TEST_BED_SPEC.md
  - ./02_combat_damage.md
---

# 03 - Interaction, Input, And UI

## Purpose

Make the testbed understandable without chat or README instructions. This phase proves a non-exit interaction path, exposes actual input bindings, and prepares the settings UI for keybinding work.

## Progress

Already true:

- [x] `Interactable` shows prompts through `SignalBus.interaction_prompt_changed`.
- [x] `ExitPortal` extends `Interactable`.
- [x] `HUD` shows a basic control guide and interaction prompt.
- [x] `SettingsPopup` exists for volume/toggle settings.
- [x] `Game.ensure_input_map` creates the current action names.

Resolved in implementation:

- [x] The testbed includes non-exit NPC/object interaction.
- [x] HUD control text is generated from the actual `InputMap`.
- [x] Settings popup lists current bindings.
- [x] The default keyboard attack binding is `F`, and stale `J`/mouse default display text has been removed from the active input path.
- [x] Keyboard remapping persists through `InputBindings`, blocks duplicate tracked keys, and supports restore defaults.
- [x] Climb traversal inputs are displayed.
- [x] Debug shortcuts are labeled as debug-only.

Still open:

- [ ] Mouse/gamepad remapping and chord capture remain deferred.
- [ ] Manual interaction/input QA is still tracked in `05_qa_and_handoff.md`.

## Tasks

### Phase 6 - NPC/Object Interaction Proof

Source owners touched: `scripts/stages/Interactable.gd`, new interactable scene/script, `HUD.gd`, `SettingsPopup.gd` only if needed.

- [x] **6.1** Add an NPC or object that extends or uses `Interactable` and is not the exit portal.
- [x] **6.2** Show prompt only when the player is in range.
- [x] **6.3** On interact, show a visible status/color result without building a full dialogue or shop flow.
- [x] **6.4** Ensure leaving range hides the prompt.
- [x] **6.5** Ensure interaction does not permanently steal movement controls.
- [x] **6.6** Add a reset path so the interaction can be tested repeatedly.

Accept:

- [x] A tester can interact with a non-exit object and see a visible result.
- [x] Exit portal still uses the shared interaction path or its documented collision rule.

Guard:

- [x] Do not build a full shop, forge, healer, or dialogue system in this phase.

### Phase 7 - Input Guide, Binding List, And Settings

Source owners touched: `Game.gd`, `SettingsPopup.gd`, `HUD.gd`, `SignalBus.gd`, possible new `scripts/ui/InputBindingRow.gd`.

- [x] **7.1** Define one canonical action list: `move_left`, `move_right`, `jump`, `attack`, `dash`, `crouch`, `interact`, `pause`, and debug-only action(s).
- [x] **7.2** Add a function that returns display strings from the actual `InputMap`.
- [x] **7.3** Update HUD controls guide to read from that binding display function.
- [x] **7.4** Add a settings controls section listing current bindings.
- [x] **7.5** Implement keyboard remap for at least one action, or clearly label remapping as deferred while preserving the architecture.
- [x] **7.6** Detect or prevent duplicate bindings if remapping is implemented.
- [x] **7.7** Label debug actions such as profile cycle and ability toggles as debug-only.
- [x] **7.8** Add climb traversal actions to the binding list if rope climb, wall climb, wall slide, or wall jump are enabled; otherwise label them as deferred.
- [x] **7.9** Ensure settings UI does not cover critical gameplay when closed and pauses predictably when open.

Accept:

- [x] In-game guide matches actual `InputMap` actions.
- [x] A tester can find every action needed by the testbed without external notes.
- [x] Keyboard remap updates actual `InputMap` actions and persists through restart.

Guard:

- [x] Do not add separate key names in stage or player code that bypass `InputMap`.
- [x] Do not leave hard-coded HUD controls that can drift from actual bindings.

## Verification

- [ ] Manual interaction prompt appears and hides correctly.
- [ ] Manual interaction triggers visible result and does not lock movement.
- [x] Binding guide matches actual controls.
- [x] Binding guide includes climb-related controls when those abilities are enabled.
- [x] Settings controls section is readable at 1280x720.
- [x] Keyboard remap persistence, duplicate blocking, and restore defaults pass `tools/validate_input_remap.gd`.
- [x] Settings popup render check passes at 1280x720 and 390x720.
- [x] `rg` checks for duplicated hard-coded action display strings.
- [x] `git diff --check` before commit.

## Risks

- A text-only guide can go stale if it does not read from `InputMap`.
- Remap UI can grow too large; keep gamepad, mouse, and chord capture deferred until the keyboard path is stable.
- Interaction panels can steal input if pause/focus handling is not explicit.

## Next Steps

- [ ] Commit after non-exit interaction and input visibility are working.
- [ ] Move to `04_generated_landscape.md`.
