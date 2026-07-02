---
type: plan
status: active
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

Still open:

- [ ] There is no NPC/object interaction separate from exit.
- [ ] HUD control text is not generated from the actual `InputMap`.
- [ ] Settings popup does not list bindings.
- [ ] Keyboard remapping is not implemented or explicitly deferred in UI.
- [ ] Debug shortcuts are not labeled clearly enough.

## Tasks

### Phase 6 - NPC/Object Interaction Proof

Source owners touched: `scripts/stages/Interactable.gd`, new interactable scene/script, `HUD.gd`, `SettingsPopup.gd` only if needed.

- [ ] **6.1** Add an NPC or object that extends or uses `Interactable` and is not the exit portal.
- [ ] **6.2** Show prompt only when the player is in range.
- [ ] **6.3** On interact, open a small panel, grant a placeholder resource, toggle a debug ability, or open a door.
- [ ] **6.4** Ensure leaving range hides the prompt.
- [ ] **6.5** Ensure interaction does not permanently steal movement controls.
- [ ] **6.6** Add a reset path so the interaction can be tested repeatedly.

Accept:

- [ ] A tester can interact with a non-exit object and see a visible result.
- [ ] Exit portal still uses the shared interaction path or its documented collision rule.

Guard:

- [ ] Do not build a full shop, forge, healer, or dialogue system in this phase.

### Phase 7 - Input Guide, Binding List, And Settings

Source owners touched: `Game.gd`, `SettingsPopup.gd`, `HUD.gd`, `SignalBus.gd`, possible new `scripts/ui/InputBindingRow.gd`.

- [ ] **7.1** Define one canonical action list: `move_left`, `move_right`, `jump`, `attack`, `dash`, `crouch`, `interact`, `pause`, and debug-only action(s).
- [ ] **7.2** Add a function that returns display strings from the actual `InputMap`.
- [ ] **7.3** Update HUD controls guide to read from that binding display function.
- [ ] **7.4** Add a settings controls section listing current bindings.
- [ ] **7.5** Implement keyboard remap for at least one action, or clearly label remapping as deferred while preserving the architecture.
- [ ] **7.6** Detect or prevent duplicate bindings if remapping is implemented.
- [ ] **7.7** Label debug actions such as profile cycle and ability toggles as debug-only.
- [ ] **7.8** Ensure settings UI does not cover critical gameplay when closed and pauses predictably when open.

Accept:

- [ ] In-game guide matches actual `InputMap` actions.
- [ ] A tester can find every action needed by the testbed without external notes.
- [ ] If remap is deferred, the UI says so and the shared action path remains ready.

Guard:

- [ ] Do not add separate key names in stage or player code that bypass `InputMap`.
- [ ] Do not leave hard-coded HUD controls that can drift from actual bindings.

## Verification

- [ ] Manual interaction prompt appears and hides correctly.
- [ ] Manual interaction triggers visible result and does not lock movement.
- [ ] Binding guide matches actual controls.
- [ ] Settings controls section is readable at 1280x720.
- [ ] `rg` checks for duplicated hard-coded action display strings.
- [ ] `git diff --check` before commit.

## Risks

- A text-only guide can go stale if it does not read from `InputMap`.
- Remap UI can grow too large for this phase; if so, list bindings and clearly defer remapping.
- Interaction panels can steal input if pause/focus handling is not explicit.

## Next Steps

- [ ] Commit after non-exit interaction and input visibility are working.
- [ ] Move to `04_generated_landscape.md`.
