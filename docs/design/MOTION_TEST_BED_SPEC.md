---
type: spec
status: active
canonical_for: motion test bed requirements before stage/content implementation
source: User correction on 2026-07-02
scope: Godot runtime test bed for movement, combat, interaction, and input validation
related:
  - ../product/2d_platform_action_card_game_prd.md
  - ./PLAYER_CHARACTER_SYSTEMS.md
  - ./MAP_DATA_AND_VISUALIZATION.md
  - ../architecture/FIRST_SLICE_ARCHITECTURE.md
---

# Motion Test Bed Spec

## Purpose

Define what the first playable test bed must prove before normal stages, shop/rest maps, boss maps, or broader content are implemented. The test bed is not just a scene that boots. It is a calibrated validation space for character movement, attack readability, enemy interaction, NPC interaction, input mapping, and basic UI guidance.

## Scope

This spec applies to the runtime Godot test bed scene currently represented by `scenes/stages/MotionTestStage.tscn` and any replacement or expansion of that scene.

The test bed must validate:

- Per-character movement reach.
- Ground jump, variable jump, jump buffering, coyote time, dash, crouch, fast fall, and one-way drop.
- Optional or unlockable two-step movement such as double jump or extra dash, when that mechanic exists.
- Attack startup, active hitbox, recovery, facing direction, hit confirmation, cooldown, and enemy damage.
- Enemy contact damage and simple enemy behavior.
- NPC or object interaction through the shared `Interactable` contract.
- Input discoverability and user-adjustable or at least consistently mapped actions.
- Stage completion through an exit portal only after the player can traverse the intended route.

## Domain Brief

- Request interpretation: the current motion scene is too shallow; it does not prove the player can move through map geometry designed around character stats, does not prove combat against real enemies, and does not prove NPC-style interaction or keybinding usability.
- Likely bounded context or scope: player movement calibration, test-bed level design, combat validation, interaction validation, and input/UI feedback.
- Canonical terms: **test bed** means a deliberately structured validation scene; **movement metric** means calculated reach from player stats; **lane** means a labeled test section inside the scene; **clear route** means the required path to the exit; **optional challenge route** means a route that proves advanced movement or unlock behavior.
- Ambiguous or overloaded terms: **character** in this test bed means a profile using the shared controller until the project explicitly implements separate character controllers; **double jump** means a testable movement ability only if the player controller exposes that ability or a debug profile enables it.
- Ownership boundaries: player scripts own movement behavior; stage/test-bed design owns obstacle dimensions; combat scripts own hit/damage delivery; enemy scripts own enemy response; UI/input scripts own command visibility and remapping surfaces.
- Public interfaces: the test bed should consume player effective stats, place interactables through `Interactable`, route damage through `DamageInfo`, and place enemy actors through shared enemy scenes.
- Hidden implementation decisions: exact placeholder art, tile implementation, scene hierarchy, and editor tooling can change as long as the measurable validation contract remains true.
- Invariants or policies that must hold: map geometry must be derived from movement metrics; every required gap must be passable by every intended profile; optional routes must be marked as optional; combat validation requires an enemy that can take and deal damage; interaction validation requires an NPC or object prompt and result.
- State transitions: spawn -> movement calibration -> combat test -> hazard/damage test -> NPC/object interaction -> exit portal -> stage clear.
- Facts confirmed from code/docs/tests: current profiles expose movement stats; current test bed has a dummy and hazard but no true enemy, no NPC, no keybinding screen, no measured jump/dash lanes, and no double-jump or advanced movement lane.
- Inference: the next implementation should replace the current freeform layout with labeled sections and measured platform distances before adding normal-stage content.
- Open questions: whether double jump is a default ability, a debug-only test toggle, or a future card/skill unlock; whether final default keybindings should remain PRD-style or move to a WASD + mouse-first layout.
- Is this actually simple CRUD?: no.

## Requirements

### 1. Test Bed Structure

The scene must be divided into labeled lanes in this order:

1. **Spawn and Controls Lane**
   - Shows the current profile, health, and complete controls.
   - Provides a safe flat area to test walk acceleration, stop distance, crouch, and facing.
   - Contains an obvious profile selector or debug profile cycle only while no character-select screen exists.

2. **Movement Metrics Lane**
   - Contains visible reference markers for jump height, jump distance, dash distance, and combined jump+dash reach.
   - Uses platform/gap dimensions derived from the active movement profile values.
   - Includes both forgiving and threshold jumps so the user can feel whether controls are reliable.

3. **Jump Behavior Lane**
   - Tests ground jump, variable jump height, coyote time, and jump buffer.
   - Must include a short ledge walk-off coyote test and a pre-landing buffered jump test.
   - Must include one-way platform drop-through with clear ground recovery below.

4. **Advanced Movement Lane**
   - Tests double jump, extra dash, air dash, or other unlockable movement only when those mechanics exist.
   - If double jump is not implemented, this lane must be visibly blocked or labeled as unavailable, not silently impossible.
   - When double jump exists, include one route passable only with double jump and one route passable without it.

5. **Combat Lane**
   - Contains at least one real enemy actor with health, hurtbox, contact damage, knockback response, death/reset, and a visible damage reaction.
   - Contains a stationary target only as a secondary measurement tool, not as the only attack test.
   - Must make attack startup, active hitbox, recovery, facing, cooldown, and hit confirmation readable.

6. **Enemy Behavior Lane**
   - Contains a basic walker enemy first.
   - Later lanes can add charger and shooter enemies, but the first test bed must at least prove one enemy can move, damage the player, take damage, and reset.
   - Enemy placements must allow the player to safely re-enter the test after failure.

7. **Hazard and Damage Response Lane**
   - Tests hazard damage, damage knockback, invulnerability frames, and health UI updates.
   - Hazards must not chain-hit the player without a visible recovery path.
   - The player must not be pushed into a soft lock or endless damage loop.

8. **NPC and Interaction Lane**
   - Contains at least one NPC or interactive object using the same `Interactable` path expected for shops, chests, doors, and upgrade stations.
   - Interaction must show a prompt, accept the input, produce a visible result, and close or reset predictably.
   - This lane must prove interaction separately from the exit portal.

9. **Input and Settings Lane**
   - Shows the current bindings in-game.
   - Must either support key rebinding or clearly document that rebinding is not implemented yet.
   - If rebinding is not implemented, the test bed must still use canonical input action names so a later keybinding UI can write to one shared map.

10. **Exit and Stage Clear Lane**
    - Exit portal must be reachable only after the user passes the required test route.
    - Exit must use the same interaction or collision rule expected for normal stages.
    - Stage clear must be visible and must not hide untested failures.

### 2. Movement Metric Contract

The test bed must not place platforms by eye. It must calculate or document the target dimensions from player stats.

For each playable profile, record at least:

- `move_speed`
- `jump_velocity`
- `gravity`
- `dash_speed`
- `dash_duration`
- `dash_charges`
- calculated single-jump apex height
- calculated approximate single-jump airtime
- calculated approximate single-jump horizontal reach
- calculated dash-only reach
- calculated jump+dash reach

Use these base formulas for initial layout estimates:

```text
apex_height_px = jump_velocity^2 / (2 * gravity)
airtime_px_window_seconds = 2 * abs(jump_velocity) / gravity
single_jump_reach_px = move_speed * airtime_px_window_seconds
dash_reach_px = dash_speed * dash_duration
jump_dash_reach_px = single_jump_reach_px + dash_reach_px
```

These are estimates. The test bed must still be manually verified because acceleration, input timing, collision shape, coyote time, dash timing, and jump cut can change reachable distances.

### 3. Current Profile Metric Baseline

The current profile resources imply these approximate values:

| Profile | Apex Height | Airtime | Single Jump Reach | Dash Reach | Jump + Dash Reach |
|---|---:|---:|---:|---:|---:|
| Warrior | 67 px | 0.66 s | 136 px | 65 px | 201 px |
| Archer | 75 px | 0.71 s | 164 px | 69 px | 233 px |
| Assassin | 76 px | 0.70 s | 180 px | 71 px | 251 px |

The required route should initially fit the least-mobile required profile, currently Warrior. Optional routes may require Archer/Assassin speed, double jump, extra dash, or future upgrades, but those routes must be labeled and must not block the exit.

### 4. Platform And Gap Rules

Use conservative dimensions until hand testing proves otherwise:

- Low ledge: 24-40 px high.
- Standard ledge: 48-64 px high.
- Near-limit single-jump ledge for current profiles: 64-72 px high.
- Single-jump required horizontal gap for all current profiles: no more than 120-130 px.
- Jump+dash required gap for all current profiles: no more than 175-190 px.
- Optional fast-profile or upgrade gap: may exceed 190 px only if clearly marked optional.
- Ceiling clearance above player should leave at least one full body height plus jump movement tolerance.
- Recovery platforms must exist after every fall in the required route.

These values should be updated whenever movement stats change.

### 5. Combat Validation Rules

The combat area must answer these questions without relying on debug logs:

- Did the attack start?
- Which direction did the attack face?
- When was the hitbox active?
- Did it hit?
- How much damage was dealt?
- Did the enemy react?
- Can the enemy damage the player?
- Does the player receive knockback and temporary invulnerability?
- Can the player kill the enemy?
- Does the enemy reset or respawn so the test can be repeated?

Minimum visible feedback:

- Player attack animation or placeholder arc/rectangle during active frames.
- Enemy damage flash or hit pause.
- Enemy health marker or compact label.
- Player health change in HUD.
- Contact damage feedback.

### 6. Interaction Validation Rules

The interaction area must include an NPC or object that is not the exit.

The first interaction can be simple, but it must prove:

- Prompt appears only in range.
- Prompt text names the action.
- Pressing interact triggers a visible result.
- Leaving range hides the prompt.
- Interaction does not steal movement controls permanently.
- Interaction can later support shop, forge, healer, chest, door, or upgrade station flows.

Acceptable first result:

- NPC opens a short modal panel.
- Chest grants a coin/material placeholder.
- Upgrade station toggles a movement debug ability such as double jump.
- Door opens or closes a nearby gate.

### 7. Input And Keybinding Rules

Input must be treated as a test-bed feature, not an afterthought.

Required immediately:

- In-game binding guide for every action currently usable.
- One shared input action list:
  - `move_left`
  - `move_right`
  - `jump`
  - `attack`
  - `dash`
  - `crouch`
  - `interact`
  - `pause`
  - `open_build_panel` or a renamed debug-only action
- Debug-only actions must be labeled as debug-only in the HUD or settings.

Required before content stages:

- A settings/control screen that lists bindings from the actual input map.
- A path to remap at least keyboard bindings, or an explicit documented decision to defer remapping.
- Collision between bindings must be detected or prevented.

The current `Tab` profile cycle is acceptable only as a debug shortcut. It should move behind a character-select screen or debug panel before normal stage work.

### 8. UI Requirements

The test bed UI must include:

- Health.
- Active profile.
- Current lane or objective.
- Control guide.
- Interaction prompt.
- Optional current movement ability flags such as `Double Jump: Off/On`.
- Compact combat feedback when hitting or being hit.

The UI must not cover the character or combat lane in the default 1280x720 viewport.

### 9. Test Bed Authoring Order

Future implementation should proceed in this order:

1. Calculate movement metrics from the current profile data and expose them in debug UI or generated notes.
2. Rebuild the test bed as labeled lanes with safe recovery paths.
3. Implement or explicitly defer double jump, then add the advanced movement lane accordingly.
4. Replace the damage dummy-only combat check with a minimal real enemy.
5. Add attack active-frame visualization and hit feedback.
6. Add NPC/object interaction that is separate from the exit portal.
7. Add input settings or a binding-list screen backed by the actual input map.
8. Add exit and stage-clear validation after the required test route.
9. Only then create Stage01/Stage02/Stage03 from the same movement metric constraints.

## Acceptance Criteria

- A new player can understand the test bed controls without reading chat or README instructions.
- Every required movement obstacle is passable by the least-mobile required profile.
- At least one optional obstacle clearly requires an advanced movement ability or faster profile, and it does not block stage clear.
- The test bed includes visible markers or labels for movement metrics.
- The player can verify jump height, jump distance, dash distance, jump+dash distance, coyote time, jump buffering, crouch, fast fall, and one-way drop.
- The player can attack a real enemy, see hit feedback, take enemy damage, kill or reset the enemy, and repeat the test.
- The player can interact with a non-exit NPC or object and see a visible result.
- The player can inspect current bindings in-game.
- The exit route cannot be cleared without passing the required movement/combat/interaction path.
- The scene has no required route soft lock.

## Non-Goals

- Final art, final animation, and final sound are not required.
- Full inventory, shop, card rewards, and boss patterns are not required inside the motion test bed.
- Multiple independent character controllers are not required unless a later accepted design explicitly needs them.
- Full keybinding persistence is not required for the first correction pass, but the input architecture must not block it.

## Current Implementation Gap

The current `MotionTestStage` should be treated as a placeholder foundation, not a satisfactory test bed.

Known gaps:

- Platforms are not derived from character movement metrics.
- No labeled movement lanes exist.
- No double-jump or advanced movement lane exists.
- Combat uses a dummy, not a real enemy.
- Attack has no readable animation or active-frame visualization beyond hitbox behavior.
- No NPC or separate object interaction exists.
- Interaction is only proven through the exit portal.
- Keybinding is not user-configurable.
- `Tab` profile switching is a debug shortcut but is not labeled as such.
- The route does not force meaningful traversal or combat before stage clear.

## Related

- `docs/product/2d_platform_action_card_game_prd.md`
- `docs/design/PLAYER_CHARACTER_SYSTEMS.md`
- `docs/design/MAP_DATA_AND_VISUALIZATION.md`
- `docs/architecture/FIRST_SLICE_ARCHITECTURE.md`
- `data/characters/warrior_profile.tres`
- `data/characters/archer_profile.tres`
- `data/characters/assassin_profile.tres`
