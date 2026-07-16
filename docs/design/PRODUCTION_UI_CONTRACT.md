---
type: spec
status: active
owner: BK
created: 2026-07-14
last_reviewed: 2026-07-16
canonical_for: Traveler production screens, gameplay HUD, feedback, focus, and responsive behavior
source: Implemented Godot UI scenes, owner feedback through 2026-07-15, and automated validation at three supported resolutions
related:
  - ../product/2d_platform_action_card_game_prd.md
  - ./COMBAT_EQUIPMENT_CRAFTING.md
  - ../architecture/FIRST_SLICE_ARCHITECTURE.md
  - ../release/TRAVELER_EQUIPMENT_VERTICAL_SLICE.md
  - ../../.agent/execplans/2026-07-15-gameplay-validity-repair.md
---

# Production UI Contract

## Purpose

Define the player-facing contract for the current one-Traveler vertical slice.
Screens expose playable decisions and results; they do not explain internal test
contracts or mutate gameplay dictionaries directly.

## Scope

This specification owns the main menu, Hero Preparation, Arsenal Trial prompts,
safe-intermission merchant and Forge popups, gameplay HUD, interaction and reward
feedback, card rewards, pause and settings, and run results. Combat rules and
equipment values remain owned by `COMBAT_EQUIPMENT_CRAFTING.md` and typed runtime
snapshots. The implementation is present on
`codex/ui-readability-localization`; integration and served-browser review remain
owned by that plan.

## Requirements

### Player Flow

- **Main menu:** Begin Expedition and Settings are the primary commands. Do not
  expose a quit command that has no dependable browser behavior.
- **Hero Preparation:** present one Traveler and six slots: melee, ranged, shield,
  armor, Spirit Stone, and consumable. Show equipped model, blueprint/crafted
  state, current-versus-result values, costs, condition, and save state.
- **Arsenal Trial:** teach movement, contextual attack, guard, pickup/interaction,
  and exit in five fixed rooms. Skip Trial remains visible and mechanically equal
  to completion.
- **Safe intermission:** merchant and Forge NPCs open centered, bounded popups
  over the rest map instead of replacing the whole screen. The merchant supports
  potion purchase and run-salvage sale. Forge views separate melee, ranged,
  shield, armor, and Spirit Stone; the selected model exposes one truthful primary
  command: craft, recraft, repair, equip, or its exact disabled reason.
- **Rewards:** card selection presents three compatible shared cards. Permanent
  blueprint and Spirit Stone rewards use a short non-modal receipt that states
  what changed and where it is usable.
- **Death choice:** lethal damage opens a non-terminal choice before settlement:
  retry the current stage from its stage-entry snapshot or end the expedition and
  return through the main-menu path.
- **Run result:** victory or an explicitly ended expedition shows final reach,
  duration, level, Traveler build, and retained materials.

### Gameplay HUD

- The top-left cluster shows Traveler health, level/XP, and armor.
- The objective or boss state occupies the top center and never competes with an
  interaction prompt or reward receipt.
- Normal stages reserve the top-right for a compact assembled-plan minimap.
  Unvisited room envelopes are dark, visited rooms brighten, and the current
  room plus player use a distinct edge and shape. Boss, trial, and safe
  intermission screens hide this minimap.
- The minimap always shows start and exit, then reveals only the active
  checkpoint, discovered reward, and discovered gate/shortcut state. Exit
  locked/ready, reward available/claimed, and gate closed/open use shape or edge
  differences in addition to color. Ordinary enemies and hazards are never
  tracked as radar targets.
- The normal-stage objective transitions from navigation, to a terminal-room
  local blocker when one exists, to exit ready. It never copies a global
  main-route enemy count.
- The bottom dock shows the contextual melee/ranged attack pair, guard and shield
  stability, and potion charges. Passive Spirit Stone progress appears only when
  charged, triggered, or otherwise immediately relevant.
- The highlighted attack preview and committed attack use the same
  `AttackIntent`; the HUD never predicts a different tool than combat executes.
- Interaction prompts include the current input glyph and a concise verb.
- Field pickups visibly change the corresponding HP, material, ammunition, or
  consumable state and display a short receipt.

### State And Commands

- UI reads copy-safe snapshots from `RunState` and `ProfileState`.
- Gameplay navigation reads a copy-safe stage-map snapshot published by the
  active stage. The HUD never polls room nodes or collision, and same-stage
  retry preserves exploration knowledge without preserving claimed rewards or
  opened gates.
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
- Arrow keys move focus, `Enter` or `Space` confirms, and `Escape`
  closes the current popup or returns to the previous screen. The same meanings
  apply across preparation, merchant, Forge, rewards, results, pause, and settings.
- Focus is visible by outline and state, begins on a safe primary action, and
  returns after settings or pause closes.
- All primary and confirm targets are at least 48 px high.
- Required state is never communicated by color alone. Labels, glyphs, borders,
  quantities, and condition text reinforce color.
- Screen shake and damage flash are independently switchable. This slice uses no
  large spatial panel transitions, so a separate reduced-motion mode is deferred.
- Ending an expedition requires a confirmation that distinguishes lost run state
  from retained persistent materials.
- Player-facing explanations are available in concise natural Korean and English,
  with one selected language shown at a time rather than duplicate paragraphs.

### Responsive Layout

- `960x540` is the compact minimum, `1280x720` is the reference viewport, and
  `1920x1080` is the large browser-viewport check.
- Text wraps or clips intentionally inside scroll regions; it never overlaps a
  neighboring command or escapes its panel.
- Large viewports constrain decision surfaces near the center instead of scaling
  typography with viewport width.
- Core explanatory text must be redesigned for roughly 2-3x stronger perceived
  readability than the current build through larger type, shorter copy, spacing,
  and hierarchy; blind uniform scaling is not sufficient.
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
6. `tools/validate_hero_preparation_ui.gd`, `tools/validate_forge_screen.gd`,
   `tools/validate_merchant_screen.gd`,
   `scripts/ui/validation/ValidateGameplayHUD.gd`, and
   `scripts/ui/validation/ValidateShellUI.gd` pass.
7. Korean and English locale paths, centered merchant/Forge popups, arrow-key
   navigation, `Escape` close/back, and focus restoration are verified at all
   supported browser viewports.

## Non-Goals

- A class-selection screen, combat-time inventory, weapon wheel, or active-skill
  bar.
- A global inventory grid, multiple save-slot browser, or mid-run Continue screen.
- Final commercial illustration, animation, or recorded music.
- A runtime-random map preview or seed-selection interface.

## Related

- `PLAYER_UIUX_REFINEMENT_PLAN.md` is superseded research and does not define
  current implementation work.
- `../../.agent/execplans/2026-07-15-gameplay-validity-repair.md` owns the active
  implementation order and the handoff to the separate UI branch.
- Task-owned rendered evidence is generated outside source control and is not a
  substitute for the served-browser gate.
