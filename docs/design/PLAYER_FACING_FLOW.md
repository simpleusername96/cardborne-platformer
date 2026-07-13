---
type: spec
status: active
owner: BK
created: 2026-07-12
last_reviewed: 2026-07-13
canonical_for: First-run player-facing navigation, HUD, choices, rest, settings, and result behavior
source: Cardborne Game Blueprint, current production UI, progression economy spec, first-run architecture, and owner feedback through 2026-07-13
related:
  - ../product/2d_platform_action_card_game_prd.md
  - ./PLAYER_CHARACTER_SYSTEMS.md
  - ./PROGRESSION_EQUIPMENT_ECONOMY.md
  - ../architecture/FIRST_SLICE_ARCHITECTURE.md
  - ../../.agent/execplans/2026-07-12-actual-game-production-roadmap.md
---

# Player-Facing Flow

## Purpose

Define what the player can see and do from boot through run settlement. UI exposes
working game state and decisions; it does not simulate unfinished systems, mutate
domain state directly, or explain debug contracts.

## Scope

This spec owns navigation, visible state, commands, focus behavior, compact-screen
behavior, and error handling for the first complete run. Gameplay rules and values
remain owned by the linked character, progression, encounter, and architecture
specs.

## Flow Contract

```text
main menu
 -> character and loadout
 -> stage HUD
    -> level-up choice -> stage HUD
    -> pause/settings -> stage HUD
 -> stage card choice
 -> next stage
 -> Stage 2 rest/forge
 -> Stage 3
 -> boss HUD
 -> death or clear summary
 -> main menu or new run
```

- Only `RunDirector` changes the top-level flow state.
- Modal choices pause combat simulation and reject duplicate confirmation.
- Back is available before a run and in settings; mandatory run rewards cannot be
  dismissed as if accepted.
- Loading replaces the initiating command with a disabled progress state and
  exposes a recoverable error when transition fails.
- No production surface shows seed validation internals, route metrics, test
  labels, raw IDs, stack traces, or placeholder feature claims.

## UI Boundary

Each surface renders an immutable snapshot and emits an intent. It never edits
`RunState`, `ProfileState`, `PlayerBuild`, inventory, currency, or save data.

| Snapshot | Minimum fields | Intents |
| --- | --- | --- |
| `CharacterLoadoutSnapshot` | characters, selected character, unlocked/equipped items, consumable, mastery summary, validation errors | select character, equip, unequip, select consumable, open mastery, start run |
| `RunHUDSnapshot` | health, max health, skill cooldowns/charges, XP progress, coins, objective, boss state when present | pause only |
| `ChoiceOfferSnapshot` | transaction ID, choice kind, three options, compatibility, current build comparison, reroll state | inspect, choose, reroll, confirm |
| `RestSnapshot` | health, coins, consumable, equipped items, shop offers, forge choices, committed purchases | heal, buy, forge, leave |
| `SettingsSnapshot` | audio levels, screen shake, damage flash, bindings, conflict state | adjust, rebind, restore, close |
| `ResultSnapshot` | outcome, character, stage, duration, build, death source, kept materials, unlocks | new run, main menu |

Rejected intents return a short player-safe reason and leave the last valid
snapshot visible. Accepted intents publish a new snapshot before input unlocks.

## Main Menu

Commands appear in this order:

1. New Run.
2. Settings.
3. Quit.

New Run opens character/loadout selection. Settings opens above the current
backdrop and returns focus to Settings when closed. There is no developer route,
continue command without a resumable-run contract, or disabled decorative command.

## Character And Loadout

The first viewport shows all three characters, their combat promise, health, base
mobility summary, and current loadout without a separate tutorial page.

- Character selection changes the accent and loadout snapshot immediately.
- Equipment is grouped by weapon, armor, charm, relic, and consumable slots.
- Locked items show their material requirement without presenting an active equip
  command.
- Mastery opens as a focused subview and returns to the same character/loadout.
- Start Run is enabled only when the snapshot validates all equipped IDs and slot
  compatibility.
- Starting a run requires one confirmation, then disables repeated input until the
  stage transition succeeds or fails.

## Mastery

- Show the selected character's six-node graph, owned materials, prerequisites,
  active purchased-node state, and exact behavior change.
- Available, locked, affordable, purchased, and equipped states must differ by
  more than color.
- A purchase preview states cost and resulting verb change before confirmation.
- Failed purchase leaves currency unchanged and explains the missing prerequisite
  or material.
- Development respec is visibly labeled only in development builds and never
  destroys spent materials in release behavior.

## Gameplay HUD

The HUD stays compact and leaves traversal commitments visible.

- Health is continuously visible and flashes only on actual health change.
- Skill 1-3 show input, icon/name, cooldown or charges, and disabled reason when a
  state prevents use.
- XP shows current level progress; coins show the current spendable run amount.
- Objective is one concise action, updated on room or phase transition.
- Interaction prompt appears only inside a valid interaction range.
- Status messages are short, deduplicated, and expire; they never replace damage
  or objective feedback.
- Boss HUD replaces normal objective emphasis with boss name, health, phase, and
  stagger state while preserving player health and skills.

No required indicator may cover the player, active enemy, landing edge, telegraph,
or safe floor. The HUD supports 1280x720 and 1920x1080, plus a 960x540 compact
review size without clipping or overlap.

## Level-Up Choice

- Pause the world after the current hit/death transaction resolves.
- Offer exactly three valid micro-upgrades from the documented pool.
- Show the current value and resulting value for numeric choices.
- Focus starts on the first valid choice; left/right changes focus and confirm
  commits once.
- Overflow XP queues the next level after the current choice closes; it never opens
  stacked choice surfaces.
- A capped or incompatible option is replaced before presentation.
- Level-up choices cannot be skipped.

## Stage Card Reward

- Present three compatible, uncapped cards after each normal stage.
- Each option shows trigger, gameplay consequence, compatibility, and the part of
  the current kit it changes. Flavor text cannot replace the mechanical statement.
- Inspecting an option previews affected attacks/skills without mutating the build.
- Reroll is shown only when available and affordable; it commits through its own
  transaction.
- Confirm applies one card exactly once, shows the changed build summary, then
  enables Continue.
- There is no card reward after the boss.

## Optional Chest Replacement

When `Treasure Instinct` is active, opening an optional-route chest pauses gameplay
and presents the resolved normal reward beside one deterministic replacement.

- The replacement is an unseen compatible equipment item, or a free compatible
  forge affix when no unseen stage-cache equipment remains.
- Choosing the replacement discards the normal currencies, materials, and
  equipment; both options share one chest transaction ID and cannot both settle.
- The preview names duplicate-equipment salvage and an affix replacement before
  commitment. Replacement or modal failure falls back to the normal reward; if
  that transaction cannot settle, cancellation reopens the chest for retry.
- The modal has no skip path, owns keyboard/gamepad focus, and resumes gameplay
  only after one successful commit.

## Rest, Shop, And Forge

After the final Stage 2 encounter, its terminal safe room presents the stage card
and five commands: heal, buy consumable, reroll the active offer when legal, forge,
and leave for Stage 3.

- The header keeps health and coins visible while comparing costs.
- Unaffordable commands remain visible but disabled with the exact shortage.
- Purchased one-time offers cannot be bought twice.
- Forge first selects an equipped eligible item, then presents exactly three
  deterministic affixes, then requires replacement confirmation when needed.
- The preview shows the existing affix, proposed affix, affected behavior, and
  final coin balance.
- Leaving asks for confirmation only when an uncommitted forge choice is open.
- The room cannot be exited through gameplay while a committed transaction is
  still awaiting a result snapshot.

## Pause And Settings

- Pause stops gameplay but not UI input.
- Resume is the first focused command; Settings and Main Menu follow.
- Main Menu warns that run-local progress will be lost before ending an active run.
- Audio, screen shake, damage flash, and keyboard binding controls reflect real
  runtime state.
- Binding capture names the action, supports cancel, rejects disallowed conflicts,
  and preserves the previous valid binding on failure.
- Mouse and gamepad remapping remain deferred until implemented and must not appear
  as working controls.

## Death And Clear Summary

Death summary shows:

- outcome and furthest stage/room;
- run duration;
- final cards/equipment/affixes;
- lethal source and recent damage sources;
- kept materials and newly unlocked equipment;
- New Run and Main Menu.

Clear summary additionally shows Boss Core and boss unlocks. It does not imply a
post-boss reward choice. New Run returns to character/loadout with the previous
character selected; Main Menu returns to the main menu.

## Feedback And Visual Hierarchy

- Threat uses red plus shape/motion; reward uses amber; interaction uses cyan;
  recovery uses green; character identity uses its own accent.
- Color never carries a mandatory state alone.
- Gameplay feedback priority is player damage/death, enemy startup, skill result,
  objective transition, reward, then status message.
- Screen shake and damage flash honor settings and never obscure a response window.
- Choice and transaction feedback uses concise state changes, not explanatory
  paragraphs or debug logs.
- Placeholder shapes remain acceptable only while collision, threat, reward, and
  interaction classes stay visually distinct.

## Input, Focus, And Accessibility

- Every surface is fully operable by keyboard and the standard gamepad layout once
  gamepad support is credited complete.
- Focus is always visible, starts on the safest likely command, and returns to the
  invoking control after a modal closes.
- Destructive or run-ending commands require explicit text and confirmation.
- Repeated confirm input cannot spend, equip, unlock, or settle twice.
- Text fits at supported sizes; long dynamic names wrap within their region without
  moving fixed controls.
- Telegraphs, selection, locked state, and cooldown state remain understandable
  with reduced color perception and with screen shake disabled.

## Error Behavior

| Failure | Player-facing response |
| --- | --- |
| Invalid loadout | Keep selection open; identify the affected slot. |
| Approved stage load failure | Keep the player out of the broken stage and return to a stable retry/menu surface. |
| Stage load failure | Return to a stable menu/result state with Retry or Main Menu. |
| Reward conflict or duplicate | Keep current snapshot; do not grant twice; allow safe retry when unresolved. |
| Save failure | Preserve in-memory result, warn that persistence failed, and expose Retry. |
| Binding conflict | Keep old binding and identify the conflicting action. |
| Missing presentation asset | Use the declared placeholder without changing layout or gameplay. |

## Requirements

- Every visible action maps to a working intent and owner.
- Mandatory choices cannot be dismissed, duplicated, or applied partially.
- UI reads snapshots and emits intents; domain services own all state changes.
- Debug and unavailable features remain absent from production surfaces.
- Compact and standard desktop layouts preserve gameplay visibility and focus.
- Run-ending, spending, forging, and mastery actions are explicit and idempotent.

## Acceptance Criteria

- A keyboard user completes menu -> loadout -> stage -> level choice -> card reward
  -> rest/forge -> boss -> result without mouse or debug input.
- Every screen has a valid initial focus, back rule, loading state, disabled state,
  and recoverable error state where applicable.
- Choice previews match the applied build snapshot and repeated confirmation applies
  exactly once.
- 1280x720, 1920x1080, and 960x540 captures show no clipping, overlap, hidden fixed
  controls, or gameplay-obscuring HUD.
- A player can identify health, available skills, objective, costs, card behavior,
  and kept rewards without reading implementation terminology.

## Non-Goals

- Touch-first mobile UI, online profile UI, cloud conflict resolution, storefronts,
  localization layout, codex/lore menus, or final cinematic presentation.
- Decorative controls, fake settings, debug route panels, or full-screen tutorials.

## Related

- `docs/product/2d_platform_action_card_game_prd.md`
- `docs/design/PLAYER_CHARACTER_SYSTEMS.md`
- `docs/design/PROGRESSION_EQUIPMENT_ECONOMY.md`
- `docs/architecture/FIRST_SLICE_ARCHITECTURE.md`
