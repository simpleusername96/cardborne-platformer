---
type: spec
status: active
owner: BK
created: 2026-07-14
last_reviewed: 2026-07-15
canonical_for: Traveler production screens, gameplay HUD, feedback, focus, and responsive behavior
source: Implemented Godot UI scenes, owner feedback through 2026-07-15, and rendered validation at three supported resolutions
related:
  - ../product/2d_platform_action_card_game_prd.md
  - ./COMBAT_EQUIPMENT_CRAFTING.md
  - ../architecture/FIRST_SLICE_ARCHITECTURE.md
  - ../release/TRAVELER_EQUIPMENT_VERTICAL_SLICE.md
  - ../research/player_input_and_ui_followup_audit_2026-07-15.md
---

# Production UI Contract

## Purpose

Define the player-facing contract for the current one-Traveler vertical slice.
Screens expose playable decisions and results; they do not explain internal test
contracts or mutate gameplay dictionaries directly.

## Scope

This specification owns the main menu, Hero Preparation, Arsenal Trial prompts,
Forge, gameplay HUD, interaction and reward feedback, card rewards, pause and
settings, and terminal run results. Combat rules and equipment values remain owned
by `COMBAT_EQUIPMENT_CRAFTING.md` and typed runtime snapshots.

## Requirements

### Player Flow

- **Main menu:** Begin Expedition, Settings, and Exit Game are the only primary
  commands.
- **Hero Preparation:** present one Traveler and six slots: melee, ranged, shield,
  armor, Spirit Stone, and consumable. Show equipped model, blueprint/crafted
  state, current-versus-result values, costs, condition, and save state.
- **Arsenal Trial:** teach movement, contextual attack, guard, pickup/interaction,
  and exit in five fixed rooms. Skip Trial remains visible and mechanically equal
  to completion.
- **Forge:** separate melee, ranged, shield, armor, and Spirit Stone views. The
  selected model exposes one truthful primary command: craft, recraft, repair,
  equip, or its exact disabled reason.
- **Rewards:** card selection presents three compatible shared cards. Permanent
  blueprint and Spirit Stone rewards use a short non-modal receipt that states
  what changed and where it is usable.
- **Run result:** victory and defeat show final reach, duration, level, Traveler
  build, and retained materials before replay or return to menu.

### Gameplay HUD

- The top-left cluster shows Traveler health, level/XP, and armor.
- The objective or boss state occupies the top center and never competes with an
  interaction prompt or reward receipt.
- The bottom dock shows the contextual melee/ranged attack pair, guard and shield
  stability, passive Spirit Stone progress, and potion charges.
- The highlighted attack preview and committed attack use the same
  `AttackIntent`; the HUD never predicts a different tool than combat executes.
- Interaction prompts include the current input glyph and a concise verb.
- Field pickups visibly change the corresponding HP, material, ammunition, or
  consumable state and display a short receipt.

### State And Commands

- UI reads copy-safe snapshots from `RunState` and `ProfileState`.
- UI emits narrow commands through `RunDirector`, `ProfileState`, or the owning
  service. It does not edit profile, reward, equipment, or run dictionaries.
- Failed commands preserve the last valid snapshot, identify the reason, and keep
  the player on a stable screen.
- Saving, saved, and persistence-failure states are distinguishable before a run
  starts.

### Focus And Accessibility

- Every command is reachable by keyboard, and pointer-appropriate commands also
  work with the mouse. Gameplay bindings support capture, conflict rejection,
  cancel, per-action reset, and restore-all.
- Arrow keys or `WASD` move focus, `Enter` or `Space` confirms, and `Escape`
  closes the current popup or returns to the previous screen. The same meanings
  apply across preparation, Forge, rewards, results, pause, and settings.
- Focus is visible by outline and state, begins on a safe primary action, and
  returns after settings or pause closes.
- Primary targets are at least 40 px high; confirm actions target 44 px or more.
- Required state is never communicated by color alone. Labels, glyphs, borders,
  quantities, and condition text reinforce color.
- Screen shake and damage flash are independently switchable. This slice uses no
  large spatial panel transitions, so a separate reduced-motion mode is deferred.
- Ending an expedition requires a confirmation that distinguishes lost run state
  from retained persistent materials.

### Responsive Layout

- `960x540` is the compact minimum, `1280x720` is the reference viewport, and
  `1920x1080` is the large browser-viewport check.
- Text wraps or clips intentionally inside scroll regions; it never overlaps a
  neighboring command or escapes its panel.
- Large viewports constrain decision surfaces near the center instead of scaling
  typography with viewport width.
- Gameplay HUD clusters preserve the center playfield and do not cover one
  another at any supported viewport.

## Acceptance Criteria

1. Production contains no character selector, class label, active-skill slot,
   resonance gauge, temporary-affix choice, raw content ID, or debug contract text.
2. Preparation and Forge expose exact costs and current-versus-result values from
   the same progression resolver used by committed commands.
3. Interaction, field pickup, chest, blueprint, Spirit Stone, craft, repair, and
   stage-clear outcomes have visible success or failure feedback.
4. Mouse and keyboard can complete every required screen without a focus trap or
   hidden mandatory action; keyboard alone can complete the full required path.
5. Rendered captures pass at `960x540`, `1280x720`, and `1920x1080` for preparation,
   Forge, rewards, results, HUD, pause, settings, remapping, and fixed stages.
6. `validate_hero_preparation_ui.gd`, `validate_forge_screen.gd`,
   `validate_gameplay_hud.gd`, and `validate_shell_ui.gd` pass.

## Non-Goals

- A class-selection screen, combat-time inventory, weapon wheel, or active-skill
  bar.
- A global inventory grid, multiple save-slot browser, or mid-run Continue screen.
- Final commercial illustration, animation, recorded music, or localization.
- A runtime-random map preview or seed-selection interface.

## Related

- `PLAYER_UIUX_REFINEMENT_PLAN.md` is superseded research and does not define
  current implementation work.
- `../research/player_input_and_ui_followup_audit_2026-07-15.md` stores the
  keyboard-navigation and readability handoff for the separate UI branch.
- The current rendered evidence is generated under `.codex-runtime/uiux/` and is
  intentionally excluded from source control.
