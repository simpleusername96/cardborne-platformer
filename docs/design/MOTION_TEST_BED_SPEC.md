---
type: spec
status: active
canonical_for: motion test bed requirements before stage/content implementation
source: User correction on 2026-07-02
scope: Godot runtime test bed for movement, combat, interaction, and input validation
related:
  - ../product/2d_platform_action_card_game_prd.md
  - ./TESTBED_REIMPLEMENTATION_CONTRACT.md
  - ./PLAYER_CHARACTER_SYSTEMS.md
  - ./MAP_DATA_AND_VISUALIZATION.md
  - ./PROCEDURAL_REGION_GENERATION.md
  - ../architecture/FIRST_SLICE_ARCHITECTURE.md
---

# Motion Test Bed Spec

## Purpose

Define what the first playable test bed must prove before normal stages, shop/rest maps, boss maps, or broader content are implemented. The test bed is not just a scene that boots. It is a calibrated miniature game: a validation space for character movement, attack readability, enemy interaction, NPC interaction, input mapping, basic UI guidance, and seeded random landscape generation.

For code-disposable, full-rebuild detail, use `TESTBED_REIMPLEMENTATION_CONTRACT.md` as the stricter canonical contract.

## Scope

This spec applies to the runtime Godot test bed scene currently represented by `scenes/stages/MotionTestStage.tscn` and any replacement or expansion of that scene.

The test bed must validate:

- Per-character movement reach.
- Per-profile attack identity through data-driven attack timing, hitbox shape, range, knockback, visible motion style, and projectile behavior until separate character controllers exist.
- Ground jump, variable jump, jump buffering, coyote time, dash, crouch, fast fall, and one-way drop.
- Optional or unlockable two-step movement such as double jump or extra dash, when that mechanic exists.
- Climb traversal such as rope climbing, ladder-like climbing, wall climb, or wall slide/jump when those mechanics exist.
- Attack startup, active hitbox, recovery, facing direction, hit confirmation, cooldown, and enemy damage.
- Attack-driven destruction for breakable walls, crates, barriers, or other removable obstacles.
- Enemy contact damage and simple enemy behavior.
- NPC or object interaction through the shared `Interactable` contract.
- Input discoverability and user-adjustable or at least consistently mapped actions.
- Camera-followed multi-screen map traversal where the whole playable map is not visible at once.
- Seeded random landscape generation that produces a small playable route.
- A miniature run loop that can combine generated terrain, enemies, hazards, interactions, and exit conditions.
- Stage completion through an exit portal only after the player can traverse the intended route.

## Domain Brief

- Request interpretation: the current motion scene is too shallow; it does not prove the player can move through map geometry designed around character stats, does not prove combat against real enemies, does not prove NPC-style interaction or keybinding usability, and does not simulate generated landscape gameplay.
- Likely bounded context or scope: player movement calibration, test-bed level design, procedural landscape generation, combat validation, interaction validation, input/UI feedback, and miniature run flow.
- Canonical terms: **test bed** means a deliberately structured validation scene; **miniature game** means a small playable loop inside the test bed; **movement metric** means calculated reach from player stats; **lane** means a labeled test section inside the scene; **viewport route** means a playable route larger than the camera view; **climbable** means a rope, ladder-like surface, wall-climb surface, or wall-slide surface with explicit traversal rules; **destructible** means a world object removed or changed by attack damage; **generated landscape** means runtime-created playable terrain segments, not only a graph preview; **clear route** means the required path to the exit; **optional challenge route** means a route that proves advanced movement or unlock behavior.
- Ambiguous or overloaded terms: **character** in this test bed means a profile using the shared controller until the project explicitly implements separate character controllers; **double jump** means a testable movement ability only if the player controller exposes that ability or a debug profile enables it.
- Ownership boundaries: player scripts own movement and climb behavior; stage/test-bed design owns authored validation lanes and camera bounds; procedural generation owns seeded terrain/encounter assembly; combat scripts own hit/damage delivery; enemy scripts own enemy response; destructible world objects own their own damage response; UI/input scripts own command visibility and remapping surfaces.
- Public interfaces: the test bed should consume player effective stats, ask a landscape generator for a reproducible terrain plan, place interactables through `Interactable`, route damage and destructible object hits through `DamageInfo`, and place enemy actors through shared enemy scenes.
- Hidden implementation decisions: exact placeholder art, tile implementation, scene hierarchy, generator algorithm, room-template format, and editor tooling can change as long as the measurable validation contract remains true.
- Invariants or policies that must hold: generated and authored geometry must be derived from movement metrics; the playable route must exceed one viewport so camera follow and camera bounds are tested; bottom, side, and ceiling voids should be framed as intentional dungeon space rather than empty background; every generated critical path must be passable by the intended profile/ability set; optional generated branches must be marked as optional; combat validation requires enemies that can take and deal damage; destructible validation requires an attack-removable obstacle that changes traversal; interaction validation requires an NPC or object prompt and result; every generated seed must be reproducible.
- State transitions: spawn -> select mode/profile/seed -> movement calibration -> combat test -> hazard/damage test -> NPC/object interaction -> miniature generated run -> exit portal -> stage clear.
- Facts confirmed from code/docs/tests: current profiles expose movement stats and attack identity stats; the current test bed has measured lanes, checkpoint/fall/death recovery, Walker/Charger/Shooter enemies, destructibles, hazards, NPC interaction, a binding-list settings popup, camera-followed traversal, and runtime seeded landscape generation. Manual QA remains required before treating the test bed as fully proven.
- Inference: the next implementation should replace the current freeform layout with labeled sections and measured platform distances, then add a miniature generated-run mode before adding normal-stage content.
- Open questions: whether double jump is a default ability, a debug-only test toggle, or a future card/skill unlock; whether mouse attack should return later as an optional secondary binding after remapping/conflict handling exists.
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
   - Tests double jump, extra dash, air dash, rope climb, wall climb, wall slide, wall jump, or other unlockable movement only when those mechanics exist.
   - If double jump is not implemented, this lane must be visibly blocked or labeled as unavailable, not silently impossible.
   - When double jump exists, include one route passable only with double jump and one route passable without it.
   - When climb traversal exists, include at least one rope or ladder-like climb route and one wall-based climb or wall-jump route.
   - Climb routes must include clear entry, exit, drop/cancel behavior, and a safe recovery space below.

5. **Combat Lane**
   - Contains at least one real enemy actor with health, hurtbox, contact damage, knockback response, death/reset, and a visible damage reaction.
   - Contains a stationary target only as a secondary measurement tool, not as the only attack test.
   - Must make attack startup, active hitbox, recovery, facing, cooldown, and hit confirmation readable.
   - Profile switching must visibly change attack behavior such as heavy swing, quick slash, projectile shot, label, active time, hitbox size, range, cooldown, damage, or knockback.
   - Contains at least one destructible obstacle that can be removed by player attack and then changes the route, opens a shortcut, or reveals a small reward.

6. **Enemy Behavior Lane**
   - Contains a basic walker enemy first.
   - Contains simple charger and shooter baselines once the walker path is stable, so contact, charge, and projectile patterns can be compared without waiting for production enemy content.
   - Broader enemy variants can wait, but the first test bed must prove enemies can move, damage the player, take damage, and reset.
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

11. **Generated Landscape Lane**
    - Contains a runtime-generated miniature route built from safe terrain segments, jump gaps, vertical steps, enemies, hazards, rewards, and an exit.
    - Supports seed entry, random seed generation, regenerate, and replay current seed.
    - Displays the active seed and generator profile in the HUD or debug panel.
    - Uses the same movement metrics and passability rules as the authored lanes.
    - Guarantees a critical path from spawn to exit for the selected profile and enabled abilities.
    - Allows optional branches that require stronger abilities, but optional branches must never block completion.
    - Places enemies and hazards through the same runtime contracts used by authored stages.

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

### 5. Camera, Viewport, And Route Scale Rules

The test bed must prove that the player moves through a map, not that the whole map is a single static screen.

- The full playable map must not be visible at once in the default 1280x720 viewport.
- The camera must follow the player through authored lanes and generated landscapes.
- The stage must define camera bounds so the camera does not show empty void outside the intended map.
- Side walls, lower masonry, ceiling mass, or equivalent placeholder framing should make the map read as a dungeon even before final art exists.
- A debug overview is allowed only as an explicit debug mode; it must not be the default gameplay camera.
- Lane labels, HUD, and prompts must remain readable while the camera moves.
- Offscreen route continuation must be visually discoverable through platform placement, path framing, lighting, or small in-world markers.
- Generated landscapes must also produce a route larger than the viewport once the generator is enabled.

### 6. Seeded Landscape Generation Rules

The test bed must include a miniature landscape generator. This is different from the existing Python region graph prototype:

- The existing procedural region work defines high-level room graphs.
- The test-bed landscape generator must create playable Godot terrain at runtime.
- The generated result can be small, but it must be traversable, fightable, and repeatable.

Minimum generated landscape features:

- Deterministic seed.
- Generator profile such as `movement_only`, `combat_route`, `hazard_route`, `mixed_mini_run`.
- Spawn area.
- Critical route made from terrain segments.
- At least one jump gap or vertical step derived from movement metrics.
- At least one camera scroll segment once generated routes are enabled.
- At least one climbable segment when climb traversal is enabled.
- At least one enemy placement when using combat or mixed profiles.
- At least one hazard placement when using hazard or mixed profiles.
- At least one non-exit interactable placement when using interaction or mixed profiles.
- At least one destructible placement when using combat, mixed, or obstacle profiles.
- Exit portal or clear trigger.
- Generated route summary in UI or debug text.

The generator must not produce arbitrary tile noise. It should assemble tested segment templates:

- flat safe segment,
- low step segment,
- standard jump segment,
- near-limit jump segment,
- jump+dash segment,
- vertical one-way-platform segment,
- rope or ladder-like climb segment,
- wall climb or wall-jump segment,
- optional advanced-movement branch,
- destructible barrier or breakable wall segment,
- combat pocket,
- hazard pocket,
- NPC/object interaction pocket,
- exit segment.

Each segment template must declare:

- required movement ability,
- minimum and maximum gap width,
- minimum and maximum ledge height,
- safe landing area,
- enemy budget,
- hazard budget,
- interactable budget,
- destructible budget,
- camera scroll length or viewport span,
- whether it can appear on the critical path or only as an optional branch.

### 7. Generated Miniature Game Loop

The test bed must support a miniature game mode, separate from static validation lanes.

Required loop:

1. Pick profile and enabled ability/modifier set.
2. Pick or enter seed.
3. Generate a miniature landscape.
4. Spawn player.
5. Traverse generated terrain.
6. Fight generated enemies.
7. Use generated interactables if present.
8. Reach exit or fail/death.
9. Show clear/fail summary.
10. Allow replay same seed or generate new seed.

The miniature game loop must track:

- active seed,
- selected profile,
- enabled abilities,
- generated segment list,
- enemy count,
- hazards placed,
- interactables placed,
- destructibles placed,
- viewport spans traversed,
- route length,
- whether critical path validation passed,
- clear time or basic completion status.

Failure cases must be visible:

- invalid seed generation,
- unreachable exit,
- missing required segment type,
- enemy/hazard budget overflow,
- no safe landing after a required jump.
- route shorter than the minimum viewport-traversal requirement.

Invalid generated layouts must be rejected and regenerated, not silently spawned.

### 8. Combat And Destructible Validation Rules

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
- Can the player destroy a breakable obstacle through the same attack/damage vocabulary?
- Does the destroyed obstacle visibly change traversal, open a shortcut, or reveal a small reward?

Minimum visible feedback:

- Player attack animation or placeholder arc/rectangle during active frames.
- Projectile profiles must spawn visible projectile geometry that uses the same damage vocabulary as melee attacks.
- Enemy damage flash or hit pause.
- Enemy health marker or compact label.
- Player health change in HUD.
- Contact damage feedback.
- Destructible damage flash, crack state, or destruction frame.
- Route change after destruction.

### 9. Interaction Validation Rules

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

### 10. Input And Keybinding Rules

Input must be treated as a test-bed feature, not an afterthought.

Required immediately:

- In-game binding guide for every action currently usable.
- Current default keyboard attack binding: `F`.
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
- Climb traversal must either reuse documented movement actions or add canonical actions such as `climb_up`, `climb_down`, `climb_cancel`, or `drop_from_climb`.
- Debug-only actions must be labeled as debug-only in the HUD or settings.

Required before content stages:

- A settings/control screen that lists bindings from the actual input map.
- A path to remap at least keyboard bindings, or an explicit documented decision to defer remapping.
- Collision between bindings must be detected or prevented.

The current `Tab` profile cycle is acceptable only as a debug shortcut. It should move behind a character-select screen or debug panel before normal stage work.

### 11. UI Requirements

The test bed UI must include:

- Health.
- Active profile.
- Current lane or objective.
- Control guide.
- Interaction prompt.
- Optional current movement ability flags such as `Double Jump: Off/On`.
- Compact combat feedback when hitting or being hit.
- Active generator mode and seed when in miniature game mode.
- Generated route status such as `Valid`, `Regenerating`, or `Invalid`.
- Current camera/area objective when the route extends beyond one screen.
- Current climb ability state if rope climb, wall climb, wall slide, or wall jump is enabled.

The UI must not cover the character or combat lane in the default 1280x720 viewport.

### 12. Test Bed Authoring Order

Future implementation should proceed in this order:

1. Calculate movement metrics from the current profile data and expose them in debug UI or generated notes.
2. Rebuild the test bed as labeled lanes with safe recovery paths.
3. Add camera-followed route scale and camera bounds so the whole map is not visible at once.
4. Implement or explicitly defer double jump, rope climb, wall climb, wall slide, and wall jump, then add the advanced movement lane accordingly.
5. Replace the damage dummy-only combat check with a minimal real enemy.
6. Add attack active-frame visualization, hit feedback, and destructible obstacles.
7. Add NPC/object interaction that is separate from the exit portal.
8. Add input settings or a binding-list screen backed by the actual input map, including climb actions if they exist.
9. Add deterministic generated landscape assembly from segment templates.
10. Add miniature game mode: seed, regenerate, replay, clear/fail summary.
11. Add exit and stage-clear validation after the required test route.
12. Only then create Stage01/Stage02/Stage03 from the same movement metric constraints.

## Acceptance Criteria

- A new player can understand the test bed controls without reading chat or README instructions.
- Every required movement obstacle is passable by the least-mobile required profile.
- At least one optional obstacle clearly requires an advanced movement ability or faster profile, and it does not block stage clear.
- The default gameplay camera follows the player through a route larger than one viewport; the full playable map is not visible at once.
- The test bed includes visible markers or labels for movement metrics.
- The player can verify jump height, jump distance, dash distance, jump+dash distance, coyote time, jump buffering, crouch, fast fall, one-way drop, rope/ladder-like climb, and wall-based climb behavior when those mechanics are enabled.
- The player can attack a real enemy, see hit feedback, take enemy damage, kill or reset the enemy, and repeat the test.
- The player can destroy at least one breakable obstacle with attacks and see the route change.
- The player can interact with a non-exit NPC or object and see a visible result.
- The player can inspect current bindings in-game.
- The player can generate a miniature random landscape from a seed and replay the same seed.
- Generated critical paths are validated against the selected profile and enabled abilities before play starts.
- Generated optional branches can require stronger abilities, but generated critical paths cannot.
- Generated landscapes can place enemies, hazards, interactables, and an exit through the same contracts used by authored content.
- Generated landscapes can include climbable segments and destructible obstacles when those generator profiles or ability flags are enabled.
- Invalid generated landscapes are rejected with a visible reason or regenerated.
- The exit route cannot be cleared without passing the required movement/combat/interaction path.
- The scene has no required route soft lock.

## Non-Goals

- Final art, final animation, and final sound are not required.
- Full inventory, shop, card rewards, and boss patterns are not required inside the motion test bed.
- Multiple independent character controllers are not required unless a later accepted design explicitly needs them.
- Full mouse/gamepad remapping and input glyph polish are not required for the first correction pass, but the input architecture must not block them.
- Full production procedural world generation is not required. The test bed generator can be small and segment-template based as long as it creates playable seeded miniature routes.
- Final camera polish is not required, but the default camera must still follow the player through a route larger than one viewport.

## Current Implementation Gap

The current `MotionTestStage` is now a playable foundation, but it should still be treated as a test bed rather than production stage content.

Known remaining gaps:

- Full placeholder animation states for idle/run/jump/fall/dash/hurt remain shallow.
- Attack has only placeholder swing/projectile geometry; final character sprites and animation sets remain later work.
- Full wall traversal polish, including wall climb, wall slide, wall jump tuning, and wall-specific combat, remains deferred.
- Double jump and extra dash remain debug/testbed ability flags until progression or card systems own them.
- Destructible obstacles do not yet auto-reset for repeated combat testing without route regeneration.
- Persistent key remapping and duplicate-binding conflict handling remain deferred.
- Character selection is still a debug profile cycle, not a production character-select screen.
- Charger and Shooter are pattern baselines only; final enemy art, tuning, drops, and broad enemy variants remain later work.
- Full generated seed matrix QA and complete manual profile-route QA remain open.

## Related

- `docs/product/2d_platform_action_card_game_prd.md`
- `docs/design/PLAYER_CHARACTER_SYSTEMS.md`
- `docs/design/MAP_DATA_AND_VISUALIZATION.md`
- `docs/design/PROCEDURAL_REGION_GENERATION.md`
- `docs/architecture/FIRST_SLICE_ARCHITECTURE.md`
- `data/characters/warrior_profile.tres`
- `data/characters/archer_profile.tres`
- `data/characters/assassin_profile.tres`
