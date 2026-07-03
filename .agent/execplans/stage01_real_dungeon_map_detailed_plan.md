---
type: plan
status: active
created: 2026-07-03
source: User correction that the previous real-map pass did not fully capture the intended map
scope: Detailed implementation plan for a real Stage01-style dungeon map and future map-generation contract
related:
  - ../../AGENTS.md
  - ../PLANS.md
  - ./stage01_real_dungeon_map_pass.md
  - ../../docs/product/2d_platform_action_card_game_prd.md
  - ../../docs/product/FIRST_SLICE_EXPANSION.md
  - ../../docs/design/MOTION_TEST_BED_SPEC.md
  - ../../docs/design/MAP_DATA_AND_VISUALIZATION.md
  - ../../docs/design/PROCEDURAL_REGION_GENERATION.md
  - ../../docs/design/ENEMIES_TRAPS_GIMMICKS.md
  - ../../docs/design/testbed-plan/FEATURE_PRIORITY.md
  - ../../docs/design/testbed-plan/01_authored_lanes.md
  - ../../docs/design/testbed-plan/04_generated_landscape.md
  - ../../docs/design/testbed-plan/05_qa_and_handoff.md
  - ../../data/design/first_slice/stage_layouts.json
  - ../../data/design/first_slice/procedural_region_rules.json
---

# Stage01 Real Dungeon Map Detailed Plan

## Why / Context

The previous `Stage01 Real Dungeon Map Pass` made the current motion route look more enclosed and stage-like, but it still did not fully define or enforce what the user means by a "real map." It improved presentation and rough structure, but it did not yet establish a durable map-authoring contract with enough detail for future implementation.

This document exists to correct that. It translates the user's past session requirements, the active testbed specs, and the first-slice map documents into a detailed, implementation-ready plan for a real Stage01-style dungeon map.

The target is not only a prettier testbed. The target is a playable side-view dungeon map that proves:

- the map is larger than the camera view,
- the player moves through connected rooms rather than lanes,
- bottom, side, and ceiling space read as intentional dungeon mass,
- geometry is sized around character movement metrics,
- combat, hazards, destructibles, checkpoints, and interaction are spatially meaningful,
- optional routes and rewards exist without blocking the critical path,
- generated landscape logic is eventually template/room based, not random tile noise,
- the current testbed can evolve toward production Stage01 without losing foundation contracts.

## Domain Alignment Brief

### Request Interpretation

The user is not asking for only a larger rectangle, decorative walls, or a linear sequence of validation platforms. The user wants a map that feels like a miniature game stage: a side-view dungeon where the player moves from room to room, climbs, fights, breaks objects, falls and respawns, discovers branches, and reaches a meaningful exit.

The user's references to Silksong, Hollow Knight-like structure, and Maple-like structure are binding as structural inspiration, not art copying. They imply:

- side-view platform-action readability,
- vertical shafts and layered platforms,
- local rooms connected by passages,
- map space beyond the current camera,
- traversal verbs such as rope/ladder climb and later wall traversal,
- optional branches, rewards, and shortcut-like routes,
- combat pockets with enough space for enemy patterns.

### Likely Bounded Context

This plan covers the **stage/map design context** that sits between:

- player movement metrics,
- enemy/combat behavior,
- interactable/destructible object contracts,
- checkpoint and death recovery,
- camera rules,
- procedural/seeded map assembly,
- first-slice stage progression.

It is not simple CRUD.

### Canonical Terms

- **Real map**: a playable, camera-followed stage space made from rooms, corridors, shafts, branches, combat pockets, and exits, not a one-screen test lane or a visual-only backdrop.
- **Stage01 real dungeon**: the first production-leaning map target based on `Stage 01 - Lower Ruins Ascent`.
- **Room**: a local gameplay space with a job, such as entrance, movement teaching, combat, shaft, reward, safe interaction, gate, generated pocket, or exit.
- **Passage**: the connector between rooms. It must communicate continuation and avoid accidental dead ends.
- **Critical path**: the required route from spawn to exit. It must be clearable by the least-mobile required profile.
- **Optional branch**: a non-required route for reward, advanced movement, combat challenge, or discovery.
- **Traversal verb**: a movement action the map can require or test, such as jump, dash, one-way drop, rope/ladder climb, later wall traversal, or debug double jump.
- **Dungeon mass**: visual and collision framing that makes floors, walls, ceilings, pits, and offscreen boundaries feel like part of a built environment.
- **Combat pocket**: a room or sub-room shaped around enemy behavior and player attack ranges.
- **Recovery floor**: a safe platform or checkpoint route that prevents falls from becoming soft locks.
- **Generated pocket**: a seed-driven room/segment sequence that is placed after the authored route for miniature-game proof.
- **Template**: reusable authored chunk with declared size, requirements, budgets, and safe landing rules.

### Ambiguous Or Overloaded Terms

- **Map** can mean visual preview data, Godot scene geometry, generated region graph, or runtime stage. In this plan, "map" means a playable Godot stage route unless otherwise specified.
- **Dungeon** means enclosed side-view platform space, not necessarily final gothic art.
- **Character** currently means a profile on the shared `PlayerController`, not separate production character controllers.
- **Random landscape** means controlled seed/template assembly, not arbitrary tile noise.
- **Wall traversal** is still deferred unless explicitly promoted; rope/ladder climb is currently in scope.
- **Shop/rest stage** is a later room type unless this plan is extended after Stage01 route proof.

### Ownership Boundaries

- `scripts/player/` owns movement, climb mechanics, attack execution, projectile behavior, and camera-limit consumption.
- `scripts/stages/` owns stage layout orchestration, checkpoints, fall reset, exits, hazards, destructibles, interactables, generated route assembly, and map camera bounds.
- `scripts/enemies/` owns enemy behavior, health, damage, knockback, reset, and projectile pressure.
- `scripts/combat/` owns `DamageInfo`, `Hitbox`, and `Hurtbox` vocabulary.
- `docs/design/` owns durable design contracts.
- `.agent/execplans/` owns task-specific execution plans and should not become the long-term product spec.
- `data/design/first_slice/` owns design seed data and previewable map intent before it becomes production Godot scenes.

### Hidden Implementation Decisions

The following choices can change without changing the product intent:

- whether Stage01 remains script-built temporarily or moves into `Stage01.tscn`,
- exact placeholder colors/shapes,
- whether room shells are `Polygon2D`, `TileMapLayer`, scenes, or data-driven templates,
- exact local coordinates,
- whether generated terrain is built in `MotionTestStage.gd` or a dedicated builder,
- final art, animation, sound, and tile style.

### Invariants

- The full playable route must exceed one default 1280x720 viewport.
- The default camera must follow the player; no full-map overview as gameplay.
- The critical path must be clearable by Warrior or the least-mobile required profile.
- Optional branches must never be required for stage clear.
- Every required fall must have recovery or checkpoint handling.
- Every room must have an explicit purpose.
- Combat placements must prove enemy patterns and player attack readability.
- Destructible objects must alter traversal, open a branch, or reveal a reward.
- NPC/object interaction must be separate from the exit portal.
- Generated/random areas must be seed-reproducible and validated.
- Bottom, side, and ceiling voids must be framed as dungeon mass, not empty background.

### State Transitions

Recommended Stage01 real-map flow:

```text
spawn
 -> entrance safe read
 -> first movement room
 -> first enemy encounter
 -> vertical shaft / climb
 -> optional reward branch
 -> checkpoint
 -> combat pocket
 -> destructible gate / shortcut or reward access
 -> hazard trench / damage recovery
 -> NPC or cache interaction
 -> generated pocket or seed-gate proof
 -> exit portal
 -> stage clear or return to reward flow later
```

## Source Requirements Captured From User History

This plan treats the following user corrections as binding:

- A basic testbed is not enough; the map must consider jump height, jump distance, double jump or advanced movement, attack verification, enemies, and NPC interaction.
- The testbed must simulate character abilities/skills and enemies.
- Random landscape generation must be part of the miniature game.
- The desired map is individual playable maps, not a global structure diagram.
- The player moves through the map; the whole map must not be visible at once.
- Rope/ladder traversal and wall traversal should be represented, with wall traversal deferred only if explicitly shown as unavailable.
- Breakable walls or obstacles must be removed by attack.
- Falling or dying should restart from a checkpoint/save point.
- The map should feel more like a dungeon, and bottom/side areas should not be empty.
- Character-specific attack expression and enemy knockback/patterns matter.

## Current State Assessment

### Already Implemented

- Shared input map and HUD/settings binding guide.
- Attack key set to `F`.
- Shared player controller with three profiles.
- Character attack identity:
  - Warrior heavy swing,
  - Archer arrow projectile,
  - Assassin quick slash.
- Damage contracts through `DamageInfo`, `Hitbox`, and `Hurtbox`.
- Walker, Charger, and Shooter enemy baselines.
- Enemy damage reaction, defeat, and reset.
- Destructible obstacle contract.
- Hazard damage contract.
- Non-exit interaction contract.
- Checkpoint and fall/death respawn.
- Camera follow and camera bounds.
- Runtime generated route with deterministic seed, replay, regenerate, enemy/hazard/destructible/interactable/exit pieces.
- First visual dungeon framing pass.

### Still Insufficient

- The current map is still mostly a scripted line of platforms, not an authored room network.
- `MotionTestStage.gd` is absorbing too much map construction responsibility.
- Stage01 is not yet a separate production scene.
- Room intent is not encoded as data or reusable templates.
- Optional branch rewards are mostly labels or implied geometry, not real reward objects.
- The generated route is a small hard-coded sequence, not template-based room/segment assembly.
- Camera zones are global rather than room-aware.
- Map readability depends too much on text labels.
- Manual QA across all profiles is incomplete.
- Wall traversal is deferred but not implemented.
- Shop/rest/safe-room flow is not implemented.
- Key/gate/shortcut logic is not implemented in runtime.

## Desired Final Shape For This Task

The task should produce a **Stage01 Real Dungeon Map Vertical Slice**. It may still use placeholder visuals, but the gameplay structure should feel like a real stage.

### Minimum Stage01 Route

The stage should include these rooms in this order or an equivalent connected layout:

1. **Entrance Room**
   - Safe spawn.
   - Clear forward direction.
   - Camera starts local, not zoomed out.
   - Displays only minimal testbed guidance.

2. **Lower Corridor**
   - Basic movement, crouch/fast fall if useful, short ledges.
   - First coin/material placeholder can appear here later.
   - No lethal trap before player understands movement.

3. **First Combat Room**
   - At least one Walker.
   - Enough horizontal space for all three attack styles.
   - Exit should not require killing if the design wants bypass, but the testbed clear gate may require defeating at least one enemy.

4. **Timing And One-Way Room**
   - Coyote ledge.
   - Jump-buffer landing.
   - One-way platform drop with safe floor below.
   - Optional lower detour or coin cluster.

5. **Broken Bridge / Dash Gap**
   - A required jump+dash gap under conservative Warrior limits.
   - A visible safe landing.
   - Fall recovery below.

6. **Central Vertical Shaft**
   - Rope/ladder climb route.
   - One-way platforms to support descent/recovery.
   - Clear top exit and bottom fallback.
   - Visually framed as a shaft, not a floating rope.

7. **Optional High Cache**
   - Optional branch requiring debug double jump, faster profile, or later movement upgrade.
   - Must reconnect to the main route.
   - Must not block exit.
   - Should include chest/material/coin placeholder when reward systems exist.

8. **Checkpoint/Safe Ledge**
   - Checkpoint after the major vertical traversal.
   - Space to recover before combat.

9. **Combat Hall**
   - Walker + Charger + Shooter arrangement.
   - Shooter on a higher ledge or protected shelf.
   - Charger needs telegraph/readability space.
   - Player should have a retreat or safe re-entry after damage.

10. **Breakable Gate Or Wall**
    - Blocks optional route, shortcut, or reward nook.
    - Uses the shared destructible contract.
    - Must visibly change traversal after destruction.

11. **Hazard Trench**
    - Spikes or poison floor.
    - Safe landing before and after.
    - If the player falls, checkpoint/fall reset should not create a damage loop.

12. **NPC/Cache Interaction Room**
    - Non-exit interactable.
    - Prompt appears only in range.
    - Interaction produces visible result.
    - Later can become shop, forge, healer, chest, door, or upgrade station.

13. **Generated Pocket / Seed Gate**
    - Runtime generated route proof remains after authored route.
    - It should eventually be a room/pocket with a seed sign/gate, not just appended platforms.
    - It must be playable with camera follow.

14. **Exit Room**
    - Exit portal is visually framed as the end of a stage.
    - Clear gate verifies required checks.
    - Exit should not be reachable through accidental geometry skips.

## Map Shape Specification

### High-Level Shape

Use a wide, vertically layered structure:

```text
            [optional high cache]
                    |
      [upper shaft exit] -> [combat hall upper ledge]
                    |
[spawn] -> [lower corridor] -> [timing room] -> [broken bridge]
                    |                         |
              [recovery floor]          [central shaft bottom]
                    |                         |
              [lower detour] -----------[main route]
                                              |
                                      [combat hall]
                                              |
                                [breakable/hazard/NPC]
                                              |
                                  [generated pocket]
                                              |
                                           [exit]
```

This is not a strict coordinate map. It is the shape contract that implementation should satisfy.

### Camera Rules

- Default viewport: 1280x720.
- Stage width target for first real-map pass: at least 4 to 6 viewport widths.
- Stage height target: at least 1.2 to 1.7 viewport heights if vertical shaft is meaningful.
- Camera bounds must not reveal large empty void at left, right, bottom, or ceiling.
- The player should never see every major room at once.
- Offscreen route continuation should be readable through:
  - ledge direction,
  - corridor framing,
  - rope/shaft placement,
  - exit lighting or marker,
  - enemy/prop silhouettes.

### Dungeon Framing Rules

- Floors should look like thick platforms connected to walls, not floating bars.
- Side walls should exist at room boundaries.
- Ceiling mass should exist above rooms and shafts.
- Lower voids should be either pits with fall reset/recovery or masonry/background mass.
- Use columns, arches, blocks, cracks, or slabs as placeholder geometry.
- Do not let decorative shapes obscure:
  - player,
  - attack visual,
  - enemies,
  - prompts,
  - hazards,
  - landing platforms.

## Movement Metric Rules

Use current conservative values from `MOTION_TEST_BED_SPEC.md` until manual QA updates them:

- Required single-jump horizontal gap: 120-130 px max.
- Required jump+dash gap: 175-190 px max.
- Standard ledge: 48-64 px.
- Near-limit single-jump ledge: 64-72 px.
- Optional fast-profile/upgrade branch can exceed these but must be optional.
- Recovery platform after required failures.
- Critical path must be passable by Warrior.

Implementation must not place critical platforms only by visual instinct. Each required gap should be annotated in code/data or generated from a template with declared requirement.

## Room Contract

Each room or segment should eventually be represented by a data object or scene with these fields:

```text
id
display_name
room_role
critical_or_optional
entry_points
exit_points
camera_bounds
required_abilities
movement_constraints
enemy_budget
hazard_budget
interactable_budget
destructible_budget
reward_budget
checkpoint_policy
fall_recovery_policy
soft_lock_risks
validation_checks
```

### Room Roles

Allowed initial roles:

- `entrance`
- `movement_intro`
- `timing_traversal`
- `dash_gap`
- `vertical_shaft`
- `optional_reward`
- `checkpoint_safe`
- `combat_intro`
- `combat_mixed`
- `destructible_gate`
- `hazard_challenge`
- `interaction_safe`
- `generated_pocket`
- `exit`

## Procedural / Random Landscape Contract

The real map should eventually use controlled generation in two layers.

### Layer 1: Region Graph

This is the high-level structure:

```text
seed
 -> region profile
 -> mission graph
 -> room graph
 -> role assignment
 -> gate/key/shortcut validation
```

This layer answers:

- Which rooms exist?
- Which room connects to which?
- Where is the key/gate/shortcut?
- Where are safe/shop/rest rooms?
- What difficulty budget applies?

### Layer 2: Runtime Room/Segment Assembly

This is the playable Godot geometry:

```text
room graph
 -> room template selection
 -> local platform/hazard/enemy placement
 -> movement-metric validation
 -> camera bounds
 -> instantiated scenes
```

This layer answers:

- Can Warrior clear the critical path?
- Are enemies placed through shared enemy scenes?
- Are hazards/destructibles/interactables shared contracts?
- Is the route larger than the viewport?
- Does the generated seed reproduce exactly?

### Immediate Generated Pocket Goal

Do not build full region generation in the next code pass. Instead:

- Extract current hard-coded generated sequence into named templates.
- Add template metadata for requirement and budgets.
- Add validation before instantiation.
- Keep one `mixed_mini_run` mode first.
- Add seed summary and deterministic replay.

## Implementation Plan

### Phase 0 - Stop And Reframe

- [x] Accept that the previous pass was too coarse.
- [x] Create this detailed plan.
- [ ] Do not continue broad implementation until this plan is reviewed or accepted by the user.
- [ ] Treat the existing `stage01_real_dungeon_map_pass.md` as historical record, not the active implementation guide.

### Phase 1 - Authoring Contract Extraction

Goal: separate "what the map is" from low-level node creation.

Tasks:

- [ ] Create a small Stage01 route plan data shape in GDScript or JSON.
- [ ] Define rooms with IDs and roles.
- [ ] Define room connections.
- [ ] Define camera bounds per major room or area.
- [ ] Define critical path order.
- [ ] Define optional branch metadata.
- [ ] Define checkpoint locations by room.
- [ ] Define fall recovery zones.
- [ ] Define required validation checks per room.

Acceptance:

- [ ] A future implementer can read the route plan without scanning 500 lines of node creation.
- [ ] The critical path and optional branches are explicit.
- [ ] No route-critical geometry exists only as an unexplained coordinate.

### Phase 2 - Stage01 Scene Boundary

Goal: decide whether to keep extending `MotionTestStage` or create production-leaning `Stage01`.

Recommended next implementation:

- [ ] Create `scenes/stages/Stage01.tscn`.
- [ ] Create `scripts/stages/Stage01.gd`.
- [ ] Keep `MotionTestStage` for foundation validation.
- [ ] Let `Stage01` reuse `StageBase`, player spawn, checkpoints, hazards, interactables, destructibles, enemies, and exit portal.
- [ ] Add temporary debug entrypoint if needed, but do not remove motion testbed.

Acceptance:

- [ ] Motion testbed remains available.
- [ ] Stage01 can run from the current boot path or a simple debug switch.
- [ ] Shared contracts are reused, not copied.

Fallback:

- If scene split is too risky, create a `RealMapRoot` or `Stage01PreviewRoot` inside `MotionTestStage`, but keep code isolated so it can move later.

### Phase 3 - Room Geometry

Goal: build real dungeon space before adding more content.

Tasks:

- [ ] Entrance room with safe spawn.
- [ ] Lower corridor with thick floor and side mass.
- [ ] Timing traversal room.
- [ ] Broken bridge gap with recovery floor.
- [ ] Central vertical shaft with rope/ladder.
- [ ] Upper route/galleries.
- [ ] Optional high cache branch.
- [ ] Combat hall with floor, ceiling, side walls, ledges.
- [ ] Breakable gate/side room.
- [ ] Hazard trench.
- [ ] Interaction room.
- [ ] Generated pocket entrance.
- [ ] Exit room.

Acceptance:

- [ ] The map reads as rooms connected by passages.
- [ ] The map is not one long flat line.
- [ ] Bottom and sides are never visually empty.
- [ ] The full route is not visible in one screen.
- [ ] Every fall either lands safely or triggers checkpoint/fall reset.

### Phase 4 - Camera And Navigation Readability

Goal: make the map playable through normal camera view.

Tasks:

- [ ] Define stage-wide camera bounds.
- [ ] Add room-level camera hints only if needed.
- [ ] Verify left/right/upper/lower voids are not visible.
- [ ] Add route markers through geometry instead of text where possible.
- [ ] Keep labels minimal and testbed-only.
- [ ] Add visual hint for optional branch vs critical path.
- [ ] Add visual hint for generated pocket/seed gate.

Acceptance:

- [ ] A player can infer where to go without reading a plan.
- [ ] No major text panel is required to understand basic direction.
- [ ] Camera follows without showing the entire map.

### Phase 5 - Movement Validation In Real Space

Goal: make traversal proof happen inside the real map, not separate lanes.

Tasks:

- [ ] Encode or annotate critical gaps with required ability.
- [ ] Confirm single jumps are within Warrior-safe bounds.
- [ ] Confirm dash gap is within conservative jump+dash bounds.
- [ ] Rope/ladder climb must have entry, exit, cancel/drop behavior, and recovery.
- [ ] One-way platforms must have safe lower landing.
- [ ] Optional high branch must be visibly optional.
- [ ] Wall traversal remains blocked/labeled unless implemented.

Acceptance:

- [ ] Warrior clears critical path.
- [ ] Archer/Assassin clear critical path without trivializing every obstacle.
- [ ] Optional branch does not block clear.
- [ ] Movement checks still satisfy the motion testbed contract.

### Phase 6 - Combat Integration

Goal: enemy placement should be part of room design.

Tasks:

- [ ] Place Walker in first combat intro room.
- [ ] Place Charger where its windup and burst have readable distance.
- [ ] Place Shooter on a ledge or shelf that creates ranged pressure.
- [ ] Ensure Warrior melee can reach enemies in intended cases.
- [ ] Ensure Archer projectile has a useful sightline.
- [ ] Ensure Assassin quick slash feels distinct in close quarters.
- [ ] Add retreat/re-entry space after damage.
- [ ] Avoid unavoidable contact damage at room entrances.

Acceptance:

- [ ] Player can see attack startup and hit feedback.
- [ ] Enemies take damage and knock back.
- [ ] Enemies can damage player.
- [ ] Player can recover from damage without forced damage loops.
- [ ] At least one enemy defeat is required for testbed clear or stage progression proof.

### Phase 7 - Destructible, Hazard, And Interaction

Goal: make world objects alter the route meaningfully.

Tasks:

- [ ] Place a breakable wall/gate that opens a reward nook, shortcut, or safer route.
- [ ] Place hazard trench where it teaches timing, not random punishment.
- [ ] Add checkpoint before high-risk section.
- [ ] Place NPC/cache/chest-like interactable in a safe alcove.
- [ ] Make interaction result visible.
- [ ] Keep exit portal interaction separate.

Acceptance:

- [ ] Destructible removal visibly changes traversal.
- [ ] Hazard has a safe approach and recovery.
- [ ] Interaction prompt appears and hides correctly.
- [ ] Interaction does not steal controls permanently.

### Phase 8 - Generated Pocket Refactor

Goal: turn current generated sequence into a miniature controlled generation feature.

Tasks:

- [ ] Create segment/template metadata for current generated pieces.
- [ ] Move hard-coded generated segment list out of the middle of stage construction.
- [ ] Add generator mode field with at least `mixed_mini_run`.
- [ ] Add deterministic route summary.
- [ ] Validate route span > viewport.
- [ ] Validate critical path does not require disabled abilities.
- [ ] Validate landing/recovery areas.
- [ ] Add visible failure reason before play if invalid.

Acceptance:

- [ ] Same seed/mode/profile produces same route.
- [ ] Invalid generated route does not silently spawn.
- [ ] Generated pocket remains playable through camera follow.
- [ ] Generated content uses shared enemy/hazard/interactable/destructible contracts.

### Phase 9 - Reward And Resource Placeholders

Goal: support first-slice map intent without implementing full economy.

Tasks:

- [ ] Add placeholder coin cluster object or label-backed pickup.
- [ ] Add placeholder chest or material node interactable.
- [ ] Place optional reward in high cache branch.
- [ ] Place minor lower detour reward.
- [ ] Keep card reward/shop/rest out of scope unless promoted.

Acceptance:

- [ ] Optional route has a visible reason to exist.
- [ ] Rewards do not require full inventory UI.
- [ ] Reward placeholders can later connect to `RunState` economy.

### Phase 10 - Manual QA And Tuning

Goal: prove the route by playing it, not only by booting it.

Required manual checks:

- [ ] Warrior full critical-path clear.
- [ ] Archer full critical-path clear.
- [ ] Assassin full critical-path clear.
- [ ] Coyote ledge behavior.
- [ ] Jump-buffer landing behavior.
- [ ] Dash gap behavior.
- [ ] Rope/ladder mount, climb, dismount, drop/cancel.
- [ ] Optional branch off/on or pass/fail state.
- [ ] Checkpoint respawn after falling.
- [ ] Checkpoint respawn after death.
- [ ] Walker combat.
- [ ] Charger combat.
- [ ] Shooter combat.
- [ ] Warrior attack visual/hit.
- [ ] Archer arrow visual/hit.
- [ ] Assassin slash visual/hit.
- [ ] Destructible break and route change.
- [ ] Hazard damage and recovery.
- [ ] NPC/interactable prompt/result/hide.
- [ ] Generated seed replay.
- [ ] Generated random seed.
- [ ] Exit clear gate.
- [ ] Desktop screenshot visual check.
- [ ] Narrow viewport HUD sanity check, if still supported.

Automated/smoke checks:

- [ ] `.\tools\godot.ps1 --path . --headless --import`
- [ ] `.\tools\godot.ps1 --path . --headless --quit-after 3`
- [ ] `.\tools\godot.ps1 --path . --script res://tools/capture_ui_screenshots.gd`
- [ ] `git diff --check`

## Detailed Acceptance Criteria

The map is acceptable for this task only when all of the following are true:

- [ ] It is a multi-room side-view dungeon, not a linear test lane.
- [ ] The whole playable map is not visible at once.
- [ ] It has a meaningful lower route, upper route, and vertical shaft.
- [ ] Bottom, sides, and ceiling are intentionally framed.
- [ ] Critical path is clearable by Warrior.
- [ ] Optional branch exists and is non-blocking.
- [ ] Checkpoints handle fall/death recovery.
- [ ] At least three enemy patterns are testable in context.
- [ ] Character-specific attack expressions matter in combat spaces.
- [ ] Destructible object changes traversal.
- [ ] Hazard placement has readable recovery.
- [ ] Non-exit interaction is meaningful.
- [ ] Generated pocket is deterministic and replayable.
- [ ] Exit cannot be cleared without required proof checks.
- [ ] Manual QA results are recorded.

## Suggested File Changes

Preferred implementation files:

- `scenes/stages/Stage01.tscn`
- `scripts/stages/Stage01.gd`
- `scripts/stages/Stage01RouteBuilder.gd` or `scripts/stages/dungeon/` helpers if the builder grows.
- `scripts/stages/testbed/` or `scripts/stages/dungeon/` segment/template resources if generation refactor begins.
- `data/design/first_slice/stage01_route_plan.json` only if route data is better reviewed as data.
- Keep `MotionTestStage.gd` changes small after Stage01 split.

Avoid:

- expanding `StageBase.gd` with Stage01-only behavior,
- hard-coding card/economy behavior into stage geometry,
- creating final-art asset dependencies,
- removing the motion testbed before Stage01 is stable.

## Rollback / Safety

- If Stage01 scene split fails, keep the existing motion testbed boot path intact.
- If route geometry becomes unplayable, revert only Stage01 route files, not shared player/combat systems.
- If generated pocket refactor destabilizes the map, keep current generated route and document the limitation.
- Do not change movement stats just to make a bad map passable; adjust map geometry first.

## Risks

- A pretty map can hide bad traversal if not manually cleared.
- Reusing `MotionTestStage.gd` too long will make the file a catch-all.
- Full procedural region generation can swallow the Stage01 task; keep it as a later phase.
- Optional branches can accidentally become required through checkpoint, gate, or camera mistakes.
- Enemy placement can turn movement validation into unavoidable damage.
- Excessive labels can make the route feel like a testbed instead of a game map.

## Open Questions

- Should the next implementation create `Stage01.tscn` immediately, or first refactor `MotionTestStage` into reusable route builder helpers?
- Should wall traversal be implemented before production Stage01, or remain visibly deferred through the first normal stage?
- Should the generated pocket stay in Stage01, or should it remain only in MotionTestStage until full procedural region generation is ready?
- What is the first real reward placeholder: coin cluster, chest, material node, or temporary upgrade station?
- Should shop/rest be the next safe-room type after this map, or wait until card/economy flow is implemented?

## Decision Notes

- The previous `stage01_real_dungeon_map_pass.md` is a completed first attempt and should not be treated as the active plan for the next implementation.
- This document is the active plan for the next real-map work.
- The next code pass should prioritize map structure and passability over visual polish.
- The correct implementation direction is room/route structure first, then reusable room/segment contracts, then production Stage01 split, then richer procedural generation.
