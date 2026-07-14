---
type: spec
status: active
owner: BK
created: 2026-07-12
last_reviewed: 2026-07-14
canonical_for: First-run player-facing navigation, HUD, choices, rest, settings, and result behavior
source: Cardborne Game Blueprint, current production UI, arsenal/equipment spec, first-run architecture, and owner feedback through 2026-07-14
related:
  - ../product/2d_platform_action_card_game_prd.md
  - ./ARSENAL_EQUIPMENT_PROGRESSION.md
  - ../architecture/FIRST_SLICE_ARCHITECTURE.md
  - ../../.agent/execplans/2026-07-14-single-hero-arsenal-migration.md
---

# Player-Facing Flow

## Purpose

Define what the player can see and do from boot through run settlement. UI exposes
working game state and decisions; it does not simulate unfinished systems, mutate
domain state directly, or explain debug contracts.

## Scope

This spec owns navigation, visible state, commands, focus behavior, compact-screen
behavior, and error handling for the first complete run. Gameplay rules and values
remain owned by the linked arsenal, progression, encounter, and architecture
specs.

## Flow Contract

```text
main menu
 -> selected profile: Continue / New Run / Training
 -> first profile only: Arsenal Trial or equal-reward skip
 -> Armory: two weapons and complete equipment loadout
 -> stage HUD
    -> level-up choice -> stage HUD
    -> pause/settings -> stage HUD
 -> stage card choice
 -> inter-stage Armory
 -> next stage
 -> Stage 2 Armory/rest/forge
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
| `ProfileMenuSnapshot` | three profile summaries, selected profile, valid suspend metadata, migration/save errors | select/create/delete profile, continue, new run, training, settings |
| `ArmorySnapshot` | weapon A/B, active slot, enchantments, armor, charm, relic, consumable, mastery presets, owned/locked choices, costs, next-stage pressure, validation errors | equip, compare, enhance, socket, edit mastery, start/continue stage |
| `RunHUDSnapshot` | health, active/reserve weapons, swap state, enchantment, skill cooldowns/charges, consumable, XP, coins, objective, boss state when present | swap weapon, use consumable, pause |
| `ChoiceOfferSnapshot` | transaction ID, choice kind, three options, compatibility, current build comparison, reroll state | inspect, choose, reroll, confirm |
| `RestSnapshot` | health, coins, consumable, equipped items, shop offers, forge choices, committed purchases | heal, buy, forge, leave |
| `SettingsSnapshot` | audio levels, screen shake, damage flash, bindings, conflict state | adjust, rebind, restore, close |
| `ResultSnapshot` | outcome, profile, stage, duration, weapon pair, full build, death source, kept materials, unlocks | new run, armory, main menu |

Rejected intents return a short player-safe reason and leave the last valid
snapshot visible. Accepted intents publish a new snapshot before input unlocks.

## Main Menu

Commands appear in this order:

1. Continue, only when the selected profile owns a valid suspend.
2. New Run.
3. Profiles.
4. Training.
5. Settings.
6. Quit.

New Run opens the Arsenal Trial decision for an uninitialized profile, otherwise
the Armory. When a suspend exists, New Run asks the player to Continue or explicitly
Abandon the suspended run before replacing it. Settings opens above the current
backdrop and returns focus to Settings when closed. There is no developer route or
disabled decorative command.

## Profile And Armory

Profile selection shows three local slots with play time, last safe location,
completion state, and last-used weapon pair. Empty slots offer Create. Deleting a
profile names the slot and requires hold/second confirmation; it never occurs from
a generic Back command.

- The Armory does not select a hero. It prepares the one persistent hero.
- Equipment is grouped by Weapon A, Weapon B, per-weapon enchantment, armor, charm,
  relic, and consumable slots.
- The first viewport shows both equipped weapon promises, active mastery presets,
  complete resulting stats, and the next stage's declared pressures.
- Comparison shows authored base value, current enhancement result, candidate
  result, behavior change, tradeoff, and exact material cost.
- Locked items show their material requirement without presenting an active equip
  command.
- Mastery opens for one discipline as a focused subview and returns to the same
  weapon and scroll/focus position.
- Enchanting and support-equipment changes are free only at an Armory boundary;
  permanent unlocks/enhancements commit through explicit transactions.
- Start Run is enabled only when the snapshot validates all equipped IDs and slot
  compatibility.
- Starting a run requires one confirmation, then disables repeated input until the
  stage transition succeeds or fails.

## Mastery

- Show the selected weapon discipline's six-node graph, owned materials,
  prerequisites, purchased state, equipped preset, and exact behavior change.
- Available, locked, affordable, purchased, and equipped states must differ by
  more than color.
- A purchase preview states cost and resulting verb change before confirmation.
- Failed purchase leaves currency unchanged and explains the missing prerequisite
  or material.
- Purchased nodes remain owned. Changing the bounded equipped preset is free at an
  Armory and never destroys spent materials.

## Gameplay HUD

The HUD stays compact and leaves traversal commitments visible.

- Health is continuously visible and flashes only on actual health change.
- Active and reserve weapons, swap readiness, and both enchantments remain
  distinguishable by label/icon/shape, not color alone.
- Weapon swap updates Basic, Heavy, Skill 1-3, passive state, and prompts together;
  no stale action from the reserve kit remains visible as active.
- Skill 1-3 show input, icon/name, cooldown or charges, and disabled reason when a
  state prevents use.
- The one equipped consumable shows identity, input, charge, and disabled reason.
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
  either equipped discipline it changes. Flavor text cannot replace the mechanical
  statement.
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

## Inter-Stage Armory, Rest, Shop, And Forge

After each normal-stage reward, the Armory allows loadout preparation for the next
stage. The Stage 2 terminal safe room additionally presents heal, buy consumable,
reroll the active offer when legal, temporary forge, and leave for Stage 3.

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
- Resume is the first focused command; Loadout Overview, Settings, Save & Return to
  Menu, and Abandon Run follow.
- Save & Return is enabled only at a legal safe boundary. It writes and verifies a
  checkpoint suspend before returning to the menu.
- Outside a legal boundary, the command explains the next safe save point rather
  than pretending to save exact actor state.
- Abandon Run names the progress that will be settled/lost and requires explicit
  confirmation. It is the only pause command that deletes an active suspend.
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
post-boss reward choice. New Run returns to the Armory with the previous loadout
preselected; Main Menu returns to the selected profile.

## Save And Continue

- Accepted profile commands autosave to the selected versioned profile slot.
- A profile owns at most one run suspend, written only after an authored checkpoint,
  between stages, or by Save & Return from a legal pause state.
- Continue reconstructs the approved stage at the saved checkpoint; it never
  restores arbitrary mid-air position, projectiles, animation frames, or partial
  attack windows.
- Resuming does not delete the suspend. The next safe boundary atomically replaces
  it; explicit abandon, terminal death settlement, or victory settlement deletes it.
- Save status is concise: Saving, Saved, or an actionable Retry message. Success is
  not shown before the replacement file verifies.

## Feedback And Visual Hierarchy

- Threat uses red plus shape/motion; reward uses amber; interaction uses cyan;
  recovery uses green; active weapon and enchantment use labeled silhouettes and
  restrained accents.
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
| Corrupt suspend | Recover the valid backup; otherwise offer Restart Current Stage or Abandon Run without granting rewards. |
| Incompatible suspend content | Keep profile progress, explain the version mismatch, and offer Restart Current Stage or Abandon Run. |
| Binding conflict | Keep old binding and identify the conflicting action. |
| Missing presentation asset | Use the declared placeholder without changing layout or gameplay. |

## Requirements

- Every visible action maps to a working intent and owner.
- Mandatory choices cannot be dismissed, duplicated, or applied partially.
- UI reads snapshots and emits intents; domain services own all state changes.
- Debug and unavailable features remain absent from production surfaces.
- Compact and standard desktop layouts preserve gameplay visibility and focus.
- Run-ending, spending, forging, and mastery actions are explicit and idempotent.
- Profile, tutorial skip, equipment, enhancement, save, resume, and abandon actions
  are explicit and idempotent.

## Acceptance Criteria

- A keyboard user completes profile -> Trial complete/skip -> Armory -> stage ->
  weapon swap -> level choice -> card reward -> inter-stage preparation -> boss ->
  result without mouse or debug input.
- Save & Return and Continue work from every declared legal boundary, preserve the
  last valid snapshot on failure, and do not repeat rewards.
- Tutorial complete and skip produce equal mechanical profile snapshots; replay
  produces no duplicate unlock transaction.
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
- `docs/design/ARSENAL_EQUIPMENT_PROGRESSION.md`
- `docs/architecture/FIRST_SLICE_ARCHITECTURE.md`
