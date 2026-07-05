---
type: spec
status: active
canonical_for: full motion/combat/dungeon testbed rebuild and disposable-code implementation contract
created: 2026-07-05
source: User request on 2026-07-05 to preserve strict specs so the codebase can be erased and rebuilt
scope: Rebuild-level requirements for the playable testbed suite and miniature dungeon game
related:
  - ../product/2d_platform_action_card_game_prd.md
  - ./MOTION_TEST_BED_SPEC.md
  - ./PLAYER_CHARACTER_SYSTEMS.md
  - ./MAP_DATA_AND_VISUALIZATION.md
  - ./MAP_AUTHORING_PIPELINE_CONTRACT.md
  - ./PROCEDURAL_REGION_GENERATION.md
  - ./ENEMIES_TRAPS_GIMMICKS.md
  - ./testbed-plan/FEATURE_PRIORITY.md
  - ../research/foundation_resource_survey_2026-07-05.md
---

# Testbed Reimplementation Contract

## Purpose

This document is the strict rebuild contract for the playable testbed suite. It must be detailed enough that a future implementation can delete the current code and recreate the testbeds without reading that code.

The code is disposable. This contract is not disposable. If implementation and this document disagree, future work should either change the implementation to match this contract or explicitly revise this contract first.

The target is a decent working game foundation, not a technology demo. Placeholder art is allowed, but the play experience must already prove movement feel, map traversal, combat readability, enemy behavior, interaction, hazards, checkpoint recovery, and seeded miniature dungeon generation.

## Scope

This contract applies to:

- the motion testbed,
- character profile and ability proof,
- combat and damage proof,
- enemy, trap, gimmick, and interactable proof,
- side-view dungeon mini-run proof,
- seeded/random landscape generation proof,
- HUD, settings, and player guidance needed to test the above,
- all future rewrites of these testbeds, regardless of whether they use the current code architecture.

This contract does not require:

- final commercial art,
- final sound design,
- full story/dialogue,
- production-balanced content volume,
- final shop/card/boss implementation,
- online multiplayer,
- permanent save progression,
- a specific Godot scene tree or script layout.

The current repository target remains Godot 4.x and GDScript unless a later architecture decision explicitly changes engine. The behavioral contracts below are intentionally engine-light so they can survive a rewrite.

## Authority

This document is canonical for rebuild-level testbed behavior. Other active docs still matter, but they are more specialized:

- `MOTION_TEST_BED_SPEC.md` defines the earlier lane-level testbed intent.
- `PLAYER_CHARACTER_SYSTEMS.md` defines player and progression vocabulary.
- `ENEMIES_TRAPS_GIMMICKS.md` defines first-slice content vocabulary.
- `PROCEDURAL_REGION_GENERATION.md` defines high-level graph generation.
- This document combines those into a stricter executable contract for a complete playable testbed.

## Domain Brief

- Request interpretation: the user wants a reliable game foundation and does not care whether current code survives. The current testbed is acceptable as proof that contracts can connect, but too rough as an MVP-quality foundation.
- Likely bounded context or scope: playable testbed foundation for a 2D side-view action platform dungeon with procedural miniature-run proof.
- Canonical terms:
  - **Testbed suite**: the complete playable validation environment, not one static lane.
  - **Miniature dungeon game**: a small but real run-like stage with camera-followed rooms, traversal, enemies, hazards, checkpoint recovery, interaction, generation, and exit.
  - **Rebuild contract**: behavior-level requirements that must be enough to recreate implementation.
  - **Element**: one player ability, enemy, hazard, interactable, destructible, traversal device, or UI proof unit.
  - **Archetype**: a reusable element class with a clear role, constraints, state transitions, and acceptance tests.
  - **Critical path**: required clear route from spawn to exit for the least-mobile required profile.
  - **Optional branch**: non-required route for rewards, advanced movement, challenge, or discovery.
  - **Template**: authored reusable room or segment chunk with declared size, connections, budgets, and passability constraints.
  - **Generated pocket**: seeded template assembly inside the testbed, proving random landscape logic without pretending to be final production generation.
- Ambiguous or overloaded terms:
  - **Map** may mean design data, preview, runtime scene, authored room graph, generated route, or final art. In this contract, map means playable side-view stage space unless otherwise stated.
  - **Character** means a playable profile until separate controllers exist.
  - **Dungeon** means enclosed side-view platform-action space, not a specific art style.
  - **Random** means deterministic seeded variation inside constraints, not arbitrary tile noise.
  - **MVP** means playable and legible, not visually final.
- Ownership boundaries:
  - Player context owns input consumption, movement, attack execution, damage reception, profile application, and ability state.
  - Combat context owns damage payloads, hit detection, hurt reception, invulnerability, hit confirmation, and knockback vocabulary.
  - Stage context owns room assembly, checkpoints, fall/death recovery, exits, camera bounds, route validation, and generated route lifecycle.
  - Encounter context owns enemy and hazard archetype behavior.
  - Interaction context owns prompts, interact command handling, and action result contracts.
  - UI context owns player guidance, status, settings/remap visibility, and testbed validation reporting.
  - Resource/adoption context owns external asset/package license checks and integration decisions.
- Public interfaces:
  - Input actions by canonical action name.
  - Character profile data.
  - Movement metrics snapshot and route limits.
  - Damage payload and hit/hurt events.
  - Interactable prompt/result events.
  - Stage checkpoint/respawn/clear events.
  - Generator seed/profile/result data.
  - HUD status and validation status data.
- Hidden implementation decisions:
  - exact scene tree,
  - exact tile editor,
  - whether enemies use custom scripts, state machines, behavior trees, or an imported AI package,
  - exact placeholder art,
  - exact file names for runtime scripts,
  - whether generated routes are assembled from scenes, tilemaps, JSON, or editor-authored chunks.
- Invariants:
  - The testbed must be playable without reading docs or code because the HUD guides the player.
  - The full map must never be shown all at once during default gameplay.
  - Critical path geometry must be derived from movement metrics, not placed by eye.
  - Every damaging element must be readable before or during damage.
  - Every fall or death must recover at a checkpoint without soft-locking.
  - Every spawner must have active and lifetime caps.
  - Every generated seed must be reproducible.
  - Every testbed clear must mean required proofs were completed, not only that the exit was touched.
- State transitions:
  - run boot -> profile selected -> spawn -> authored proof route -> generated mini-run -> exit validation -> clear.
  - player normal -> attacking/dashing/climbing/hurt/dead -> recovery/respawn.
  - enemy idle/patrol -> warning/attack -> recovery/hurt/defeated/reset.
  - hazard idle/warning -> active -> cooldown.
  - generator seed selected -> plan -> validate -> instantiate -> play -> complete/fail.
- Facts confirmed from existing docs/code: current work has shared input actions, three profiles, movement metrics, damage components, checkpoints, enemies, hazards, destructibles, interactables, HUD/settings shells, camera-followed map, and seeded generation. Current quality remains prototype-level.
- Inference: the next durable work should prioritize contract quality, tile/room authoring, movement and combat feel references, and strict element specifications before further content breadth.
- Open questions:
  - Final engine remains Godot unless deliberately changed.
  - Final map editor may be Godot TileMapLayer, LDtk, Tiled, or a hybrid.
  - External packages may be copied, wrapped, or only used as reference after spike review.
- Is this simple CRUD?: no.

## Product Quality Bar

The testbed is acceptable only when it feels like a small playable game, not a checklist room.

Minimum quality bar:

- Movement is responsive enough that failures feel explainable.
- Attack timing and range are visible.
- Enemies have readable tells and recovery windows.
- The map has intentional floors, walls, ceilings, lower space, side boundaries, and route framing.
- Camera follows the player through a larger-than-screen map.
- The player can understand controls and current objective from the HUD.
- Falling or dying resumes from a nearby checkpoint.
- Seeded generation creates a playable route, not a random collection of platforms.
- Every element can be tested independently enough to debug it.

MVP placeholder art is allowed only if shape, color, motion, and label make the role obvious.

## Testbed Suite Structure

The implementation should provide one integrated testbed scene or a small suite of scenes. If a single scene is used, it must contain separate areas. If multiple scenes are used, they must share the same contracts and HUD.

Required testbed areas:

1. **Spawn and Controls Area**
   - Safe flat ground.
   - Current profile shown.
   - Full controls shown.
   - Basic movement, crouch, facing, jump, dash, attack, interact, settings, reset, seed controls visible.
   - Profile selection or profile cycle available until a production character select exists.

2. **Movement Metrics Area**
   - Labeled jump-height, jump-distance, dash-distance, and jump-plus-dash tests.
   - At least one forgiving jump and one near-threshold jump.
   - Geometry generated from route limits.
   - Recovery floor below every failed jump.

3. **Advanced Traversal Area**
   - Rope or ladder climb.
   - One-way platform drop.
   - Optional route requiring debug double jump, extra dash, wall traversal, or future upgrade.
   - If wall traversal is not implemented, show a blocked/deferred wall route so testers do not mistake it for a bug.

4. **Combat and Damage Area**
   - At least three enemy archetypes available for comparison.
   - A stationary target is allowed only as a measurement tool, not as the only combat proof.
   - Profile-specific attacks visibly differ.
   - Hit confirm and enemy knockback are visible.

5. **Destructible and Route Change Area**
   - At least one breakable object removed by attack.
   - Destruction must change traversal, open a branch, reveal a reward, or unlock a shortcut.
   - Reset must restore the object.

6. **Hazard and Recovery Area**
   - At least one immediate hazard and one timed/warning hazard.
   - Damage response, invulnerability, knockback, and HUD health update visible.
   - Recovery platform prevents damage loops.

7. **Interaction Area**
   - At least one non-exit interactable.
   - Prompt appears only in range.
   - Interaction uses shared input.
   - Result is visible and resettable.

8. **Dungeon Mini-Run Area**
   - Side-view camera-followed compact dungeon route.
   - Includes multiple rooms or room-like pockets.
   - Includes lower corridor, vertical movement, combat pocket, hazard pocket, optional branch, checkpoint, generated pocket, and exit.
   - The whole map is not visible at once.

9. **Generated Landscape Area**
   - Seeded route assembled at runtime or from generated data.
   - Seed shown in HUD.
   - Replay same seed and generate new seed supported.
   - Generator result can be inspected through debug text or summary.

10. **Exit and Clear Area**
   - Exit portal or clear trigger.
   - Clear is locked until required proofs are complete, unless an explicit debug bypass is visible.
   - Clear state reports seed and missing validation, if any.

## Canonical Input Contract

Every implementation must define these input actions by name. Bindings may be remappable, but action names must remain stable.

| Action | Default keyboard | Required behavior |
| --- | --- | --- |
| `move_left` | A, Left Arrow | Negative horizontal movement. |
| `move_right` | D, Right Arrow | Positive horizontal movement. |
| `jump` | Space | Ground jump, jump buffer, one-way drop with down. |
| `attack` | F | Primary attack. Must not default to mouse-only or J-only. |
| `dash` | K, Shift | Dash if available. May cancel climb. |
| `crouch` | S, Down Arrow | Crouch on ground, fast fall in air, one-way drop modifier. |
| `climb_up` | W, Up Arrow | Move upward on climbable. |
| `climb_down` | S, Down Arrow | Move downward on climbable. |
| `climb_cancel` | C | Dismount climbable. |
| `interact` | E, Enter | Interact with prompt target. |
| `open_build_panel` | Tab | Temporary profile/debug panel until replaced. |
| `pause` | Esc | Settings or pause shell. |
| `regenerate_landscape` | R | Generate a different seed. |
| `replay_landscape` | T | Rebuild the current seed. |
| `reset_testbed` | Backspace | Respawn at current checkpoint. |

Hard rules:

- HUD/settings must read from the actual input map.
- A future remap UI must write to the same action map.
- Gameplay input must be disabled or intentionally routed when settings/remap UI is focused.
- If remapping is not implemented, the settings UI must say so clearly.
- Gamepad support may be deferred, but action names and UI glyph slots must anticipate it.

## Character Profile Contract

Profiles define playstyle and test route reach. They must not be cosmetic-only.

Required profile fields:

| Field | Unit | Purpose |
| --- | --- | --- |
| `id` | string | Stable profile ID. |
| `display_name` | string | HUD/debug name. |
| `trait_summary` | string | Visible player-facing identity. |
| `max_health` | int | Survival tradeoff. |
| `move_speed` | px/s | Ground movement. |
| `acceleration` | px/s/s or equivalent | Ramp-up feel. |
| `deceleration` | px/s/s or equivalent | Stop feel. |
| `jump_velocity` | px/s | Jump impulse. |
| `gravity` | px/s/s | Fall and apex. |
| `dash_speed` | px/s | Dash velocity. |
| `dash_duration` | seconds | Dash travel duration. |
| `dash_cooldown` | seconds | Dash reuse delay. |
| `dash_charges` | int | Ground/air dash availability. |
| `extra_jumps` | int | Additional jumps beyond ground jump. |
| `attack_label` | string | HUD/status attack label. |
| `attack_motion_style` | enum | `heavy_swing`, `quick_slash`, `arrow_projectile`, or future style. |
| `attack_damage` | int or float | Damage payload. |
| `attack_cooldown` | seconds | Time before next attack. |
| `attack_active_time` | seconds | Damage-active window. |
| `attack_range` | px | Hitbox or projectile spawn range reference. |
| `attack_height` | px | Hitbox height. |
| `attack_offset_x` | px | Hitbox/projectile spawn offset from player center. |
| `attack_offset_y` | px | Hitbox/projectile spawn vertical offset. |
| `attack_knockback_x` | px/s or impulse | Horizontal knockback delivered. |
| `attack_knockback_y` | px/s or impulse | Vertical knockback delivered. |
| `attack_projectile_speed` | px/s | Projectile speed when relevant. |
| `attack_projectile_lifetime` | seconds | Projectile lifetime when relevant. |
| `attack_projectile_size` | px vector | Projectile collision/display size. |
| `visual_color` | color | Placeholder readability. |

Required starting profiles:

| Profile | Required identity | Required tradeoff |
| --- | --- | --- |
| Warrior | Shorter, stronger heavy melee. | More health and damage, slower recovery/cooldown, least-mobile route baseline. |
| Archer | Projectile/ranged attack. | Medium safety through range, lower melee coverage, projectile lifetime/range must matter. |
| Assassin | Fast close-range slash plus higher mobility. | Lower health, faster attacks, extra jump or extra dash, lower knockback/damage per hit. |

Hard rules:

- The critical path must be clearable by the least-mobile required profile.
- Optional branches may require Assassin mobility or future upgrades, but must not block clear.
- Every profile must have at least one visible difference in movement or attack, one stat difference, and one risk/reward difference.
- Profile switch must update HUD, attack shape/motion, movement stats, health rules, and metrics.
- If the game eventually has only one production character, the three-profile testbed may remain as calibration/debug profiles.

## Movement Contract

Required movement verbs:

- left/right walk or run,
- acceleration and deceleration,
- variable-height ground jump,
- coyote time,
- jump buffering,
- dash,
- crouch,
- fast fall,
- one-way platform drop,
- rope or ladder climb,
- optional double jump or extra dash for branch testing,
- wall traversal explicitly implemented or explicitly deferred in-world.

Movement metrics must be computed from profile stats:

```text
apex_height_px = jump_velocity^2 / (2 * gravity)
airtime_seconds = 2 * abs(jump_velocity) / gravity
single_jump_reach_px = move_speed * airtime_seconds
dash_reach_px = dash_speed * dash_duration
jump_dash_reach_px = single_jump_reach_px + dash_reach_px
```

These formulas are estimates. Final route geometry must be manually verified because acceleration, collision shape, coyote time, jump cut, ledge correction, and input timing change actual reach.

Geometry rules:

- Required single-jump gaps should use no more than 75 percent of least-mobile measured reach until manual QA proves more is fair.
- Required jump-plus-dash gaps should use no more than 85 percent of least-mobile measured jump-plus-dash reach.
- Required vertical ledges should leave safety margin under least-mobile apex.
- Optional challenge jumps may exceed those limits only if visibly optional.
- Every fall in a required route must lead to a recovery floor, checkpoint route, or fall reset.
- One-way platform drops must have safe landing/recovery below.
- Climbable entries must be reachable from stable ground.
- Climbable exits must have stable landing space.
- Movement tests must include at least one forgiving and one near-threshold version.

Feel requirements:

- Coyote and buffer windows must be large enough to feel intentional, initially around 0.10-0.20 seconds.
- Dash should have visible start/end and should not accidentally fire from menu input.
- Attack should not erase movement readability unless a profile explicitly trades movement for attack.
- Climb movement must have clear mount, climb, dismount, and fall recovery behavior.

## Combat And Damage Contract

Damage uses a payload and receiver model, regardless of implementation names.

Damage payload fields:

| Field | Purpose |
| --- | --- |
| `source` | Node/object that caused damage. |
| `source_team` | `player`, `enemy`, `hazard`, or neutral. |
| `amount` | Damage amount. |
| `knockback` | Knockback vector/impulse. |
| `hit_position` | World point or approximate source point. |
| `tags` | Optional tags such as `melee`, `projectile`, `hazard`, `poison`, `explosive`. |

Hit receiver requirements:

- Can accept or reject damage.
- Applies health loss.
- Applies knockback unless immune.
- Starts invulnerability when appropriate.
- Emits hit confirmed/defeated/reset events or equivalent.
- Prevents repeated damage from one active hit unless designed as a tick hazard.

Player attack requirements:

- Startup, active, and recovery must be visually readable.
- Facing direction must affect hit direction.
- Cooldown must prevent invisible rapid-fire unless profile explicitly supports it.
- Hitbox or projectile must be visible during attack proof.
- Hit confirmation must be visible through enemy flash, knockback, status text, particles, sound, or equivalent.
- Attack must affect enemies and destructibles through the same damage vocabulary.

Projectile requirements:

- Has spawn offset, speed, lifetime, collision size, team, damage, and knockback.
- Cleans itself on lifetime end, hit, or route reset.
- Does not persist across respawn or route regeneration.

Damage recovery requirements:

- Player has post-hit invulnerability.
- Player is never knocked into an endless damage loop without recovery input.
- Enemy hurt state must not permanently disable its reset or defeat state.

## Enemy Archetype Contract

Every enemy archetype must define:

- teaching purpose,
- activation range,
- deactivation or sleep behavior,
- health,
- contact damage or attack damage,
- warning/tell if it can burst, shoot, leap, block, summon, explode, or apply area denial,
- active attack window,
- recovery window,
- hit reaction,
- knockback response,
- defeat behavior,
- reset behavior,
- caps if it spawns projectiles or children,
- minimum safe player re-entry space.

Enemy list for the testbed suite:

| Archetype | Priority | Purpose | Required states | Strict constraints |
| --- | --- | --- | --- | --- |
| Walker | Now | Basic patrol, attack timing, contact damage. | patrol, hurt, defeated, reset | Must not leave its patrol pocket. |
| Charger | Now | Teaches warning, dodge/jump spacing, burst recovery. | idle/patrol, warning, charge, recovery, hurt, defeated | Must show tell before burst; cannot instantly re-charge. |
| Shooter | Now | Teaches projectile pressure and approach timing. | idle, aim/warning, fire, cooldown, hurt, defeated | Projectile cap required; fire lane must be avoidable. |
| Shield Guard | Now | Teaches directional defense and recovery punish. | patrol, guard/block, warning, recovery, hurt, defeated | Front block only; rear/recovery hits work; block feedback required. |
| Leaper | Now | Teaches vertical/arc pressure and pre-commit tell. | idle, windup, leap, land/recovery, hurt, defeated | Target locks at windup; no midair retarget; safe landing recovery. |
| Sentry Turret | Now | Teaches static ranged zone and projectile timing. | sleep, acquire, warning, fire, cooldown, disabled | Max active projectiles; deactivates outside range. |
| Summon Node | Now, simplified | Teaches spawn pressure and cap management. | dormant, active, spawn, cooldown, defeated | Max active children and max total spawned are mandatory. |
| Small Summoned Add | Now, as child | Weak pressure spawned by node/boss. | chase/patrol, lifetime, hurt, defeated | Lifetime cap; auto-clean on parent defeat/reset. |
| Armored Bruiser | Later | Teaches slow heavy pressure and armor break. | idle, warning, slam, recovery, armor broken | Must not require advanced movement. |
| Volatile Core | Later | Teaches delayed explosion and spacing. | idle, armed, warning, explode, cleanup | No instant explosion on spawn. |
| Hover Sentry | Later | Teaches aerial target and projectile arcs. | hover, aim, fire, reposition | Must have predictable hover bounds. |
| Ward Totem | Later | Teaches support enemies and priority target. | idle, buff pulse, cooldown, defeated | Buff radius visible; no permanent invulnerability. |

Spawner hard rules:

- No infinite spawner may exist without all of:
  - max active children,
  - max total children or explicit endless-mode label,
  - spawn interval,
  - minimum distance from player,
  - activation range,
  - cleanup on reset,
  - status/debug visibility.
- Spawned enemies may not appear directly inside the player.
- Spawned enemies may not block the only required passage unless the passage remains clearable.

## Trap, Hazard, And Gimmick Contract

Every non-enemy element must define:

- purpose,
- trigger,
- visible state,
- collision/damage state,
- reset state,
- whether it can block progress,
- whether it is required or optional,
- soft-lock prevention rule.

Required elements:

| Element | Priority | Purpose | State model | Strict constraints |
| --- | --- | --- | --- | --- |
| Solid platform/wall | Now | Basic collision and dungeon mass. | static | Must form readable floor/wall/ceiling volumes. |
| One-way platform | Now | Drop-through and vertical routing. | passable/solid by direction | Must have safe landing below if required. |
| Rope/ladder climbable | Now | Vertical traversal. | inactive, mounted, climb, dismount | Entry/exit must be readable; fall recovery below. |
| Spike row | Now | Immediate hazard. | active | Cannot cover required landing without warning/recovery. |
| Timed poison vent/floor | Now | Warning-to-active damage timing. | idle, warning, active tick, cooldown | Warning visible before damage; tick interval capped. |
| Breakable wall/barrier | Now | Attack changes map. | intact, damaged, destroyed, reset | Must show health/damage feedback; collision removed only on destroyed. |
| Crumbling platform | Now | Timed traversal pressure. | stable, shaking, disabled, respawning | Must not be only required route unless respawn is fast and safe. |
| Switch gate | Now | Interaction route change. | closed, opening, open, optional close | Switch prompt visible; gate cannot crush or soft-lock. |
| Checkpoint | Now | Recovery. | inactive, active | Respawn position safe; activates before high-risk sections. |
| Fall reset zone | Now | Pit recovery. | active | Sends player to checkpoint or safe spawn. |
| Exit portal | Now | Stage clear. | locked/unlocked, clear | Reports missing requirements if locked. |
| Chest/cache | Now, simple | Reward/interaction proof. | closed, open, reset | Reward can be debug text/item; cannot be required unless labeled. |
| Moving platform/lift | Soon | Timing and vertical traversal. | wait, move, wait, return | Safe boarding and exit; predictable path. |
| Falling block | Later | Delayed crushing hazard. | idle, warning, falling, impact, reset | Warning and safe dodge space mandatory. |
| Breakable floor | Later | Route reveal/drop control. | intact, damaged, broken | Must not strand player without recovery. |
| Locked key/gate | Later or mini-run | Basic mission graph. | key uncollected/collected, gate locked/open | Key reachable before gate; gate state persists until reset. |

Hazard damage rules:

- First-slice hazards normally deal 1 health.
- Repeating hazards must expose timing through visual state.
- If a hazard uses tick damage, tick interval and invulnerability must prevent instant death.
- Hazards must reset when stage resets or seed regenerates.

## Interactable Contract

Interactables must support:

- prompt text,
- active/inactive range,
- single-use or repeatable mode,
- interaction accepted event,
- visible result,
- reset behavior,
- optional requirement or cost,
- input lockout while settings/menu is active.

Minimum interactable types:

- NPC/scout: displays a short status/message and marks interaction proof complete.
- Switch: opens or closes a gate.
- Chest/cache: grants debug reward or visible pickup.
- Exit portal: clears stage after validation.

Prompt rules:

- Prompt appears only when the player can interact.
- Prompt uses actual binding label, not hard-coded text.
- If multiple interactables overlap, target selection must be deterministic or visibly selected.
- Interacting must not trigger exit accidentally while testing an NPC or switch.

## Map And Camera Contract

The desired map is a side-view platform dungeon with horizontal route language and vertical structure. "Side-view" must never be interpreted as a flat horizontal strip.

Map shape rules:

- Default gameplay camera shows only a portion of the map.
- Playable bounds must be larger than one 1280x720 viewport.
- Route travel should feel around 8 viewport-equivalents or more for the real mini-run target.
- Overall playable bounds should be compact: near portrait, near square, or mildly landscape. Do not hard-code only `3:4`, `4:5`, `4:3`, or `5:4`; instead enforce that the map is not a thin horizontal or vertical strip.
- Vertical rooms, shafts, ledges, dropbacks, and switchbacks are required.
- Bottom, side, and ceiling spaces must read as dungeon mass, not empty void.
- The player must move through individual rooms/pockets; a debug overview may exist but cannot be default gameplay.

Room roles required in the mini-run:

| Room role | Purpose | Required contents |
| --- | --- | --- |
| Entrance | Safe read and controls. | Spawn, checkpoint, HUD-safe space. |
| Lower corridor | Basic movement and first enemy. | Floor, wall framing, Walker or equivalent. |
| Timing chamber | Coyote/buffer/one-way practice. | Ledges, one-way platform, recovery floor. |
| Broken bridge | Jump/dash proof. | Gap, prep platform, landing, checkpoint. |
| Vertical shaft | Strong vertical identity. | Rope/ladder, one-way recoveries, side exits. |
| Optional cache | Ability-gated optional branch. | Reward/cache, optional advanced movement. |
| Combat hall | Multi-enemy proof. | At least three enemy types with safe re-entry. |
| Destructible route | Attack affects traversal. | Breakable wall/barrier/floor and route result. |
| Hazard connector | Damage/recovery proof. | Hazard, checkpoint or recovery route. |
| Interaction pocket | Non-exit interaction. | NPC/switch/chest. |
| Generated pocket | Seeded route proof. | Generated segments, summary, seed controls. |
| Exit room | Clear proof. | Exit portal and validation feedback. |

Dungeon mass requirements:

- Use collision and visual shells for side walls and lower/ceiling mass.
- Floating platforms may exist, but the surrounding room must still imply architecture.
- Large empty gaps need purpose: pit, shaft, vista, boss arena space, or future branch.
- Platform placement must guide direction through shape, light/color, arrows, item placement, or room framing.
- Camera bounds must avoid showing outside-map void.

Soft-lock rules:

- No required path may rely on a destructible, moving platform, crumbling platform, or gate state that can become permanently unavailable.
- Every one-way drop on a required path must lead to progression, recovery, or a route back.
- Generated geometry must be validated before it becomes the active clear route.
- If validation fails, the route must not become required, and the HUD must report failure.

## Procedural Generation Contract

Random landscape generation is required, but it must be controlled generation.

Generation order:

```text
seed
 -> generator profile
 -> mission/route requirements
 -> room or segment plan
 -> template selection
 -> budget placement
 -> passability validation
 -> instantiate playable route
 -> publish seed summary
```

Do not generate raw random tiles and hope they are fun.

Generator profile fields:

| Field | Purpose |
| --- | --- |
| `profile_id` | Stable generator profile name. |
| `seed` | Reproducible seed. |
| `required_profile_id` | Profile that must clear critical path. |
| `enabled_abilities` | Ability flags used for validation. |
| `route_length_target` | Expected route scale. |
| `room_count_range` | Allowed room count. |
| `critical_roles` | Required room/segment roles. |
| `optional_roles` | Optional branch roles. |
| `enemy_budget` | Enemy count/difficulty budget. |
| `hazard_budget` | Hazard count/difficulty budget. |
| `reward_budget` | Reward/cache budget. |
| `verticality_budget` | Minimum vertical route structure. |
| `retry_limit` | Max attempts before failure. |

Minimum generated mini-run roles:

- generated spawn/rejoin,
- movement segment,
- vertical/climb segment when climb is enabled,
- combat segment,
- hazard segment,
- destructible or interactable segment,
- optional branch or cache,
- exit/rejoin.

Template contract:

| Field | Purpose |
| --- | --- |
| `template_id` | Stable ID. |
| `role` | Movement, combat, hazard, interaction, exit, etc. |
| `size` | Width/height or tile bounds. |
| `entry_points` | Named entry sockets. |
| `exit_points` | Named exit sockets. |
| `required_abilities` | Abilities required for critical traversal. |
| `optional_abilities` | Abilities for side rewards. |
| `max_required_gap` | Maximum required horizontal gap. |
| `max_required_ledge` | Maximum required vertical climb/jump. |
| `safe_landing_zones` | Declared stable recovery zones. |
| `enemy_slots` | Allowed enemy placements and caps. |
| `hazard_slots` | Allowed hazard placements and warning requirements. |
| `interactable_slots` | Prompt/result placements. |
| `destructible_slots` | Attack-removable placements. |
| `camera_hint` | Suggested camera bounds/framing. |
| `reset_contract` | What resets when seed/respawn occurs. |

Validation checks:

- same seed and profile produces same plan,
- critical path connected,
- critical path clearable by required profile metrics,
- optional branch not required for clear,
- no required gap/ledge exceeds limits,
- no generated hazard creates unavoidable damage,
- every spawner has caps,
- every enemy has safe re-entry space,
- every fall has recovery or reset,
- exit reachable,
- generated route summary reports counts and failures.

Generation failure behavior:

- Stop after retry limit.
- Keep previous valid route or load a safe fallback route.
- HUD must show seed, profile, and failure reason.
- Exit must not depend on an invalid route.

## HUD, Settings, And Guidance Contract

The testbed must provide in-game guidance. It is not acceptable to require the tester to infer controls from docs.

HUD required regions:

- top-left: profile name, trait summary, health, current attack label,
- top-right or compact panel: controls and seed commands,
- status line: latest action, hit, interaction, validation, or error,
- objective line: current route objective,
- validation line: completed/missing required checks,
- prompt line: interactable prompt and binding,
- debug route line: seed, generator mode, route summary.

Settings popup required sections:

- current bindings from input map,
- remap status: implemented or deferred,
- profile/debug controls,
- seed controls,
- close/pause instructions.

UI rules:

- Text must not overlap in default desktop viewport.
- HUD must not block the player during core movement/combat tests.
- Long debug text must wrap or compact.
- Settings must pause or safely ignore gameplay input.
- Control labels must update if bindings change.

## Validation And Clear Contract

Required validation IDs:

| Validation | Completion event |
| --- | --- |
| `start` | Spawn/checkpoint start reached. |
| `timing` | Timing chamber checkpoint or equivalent reached. |
| `dash` | Required dash/jump-dash route cleared. |
| `climb` | Required climb route cleared. |
| `combat` | Required enemy defeated. |
| `destructible` | Required breakable object destroyed. |
| `hazard` | Hazard/damage response observed without soft-lock. |
| `interaction` | Non-exit interactable used. |
| `generated_start` | Generated route entered. |
| `generated_exit` | Generated route exit reached. |

Clear rules:

- Exit is locked until required validations complete.
- If locked, status must list missing checks.
- Debug skip may exist only if visibly labeled and excluded from normal acceptance.
- Regenerating route resets generated validations and generated objects.
- Respawning must not wipe completed validations unless the whole testbed resets.

## QA Matrix

Manual QA must cover all profiles:

| Test | Warrior | Archer | Assassin | Acceptance |
| --- | --- | --- | --- | --- |
| Spawn and HUD | Required | Required | Required | Profile, traits, controls visible. |
| Basic movement | Required | Required | Required | Walk, jump, dash, crouch feel stable. |
| Required route clear | Required | Required | Required | Critical path clearable. |
| Optional advanced branch | Optional fail allowed | Optional | Required or easiest | Optional branch never blocks clear. |
| Attack identity | Required | Required | Required | Heavy swing, projectile, quick slash visibly differ. |
| Enemy hit/knockback | Required | Required | Required | Enemy reacts and can reset. |
| Hazard recovery | Required | Required | Required | Damage does not loop/soft-lock. |
| Interaction | Required | Required | Required | Prompt/result works. |
| Generated seed replay | Required | Required | Required | Same seed recreates same route. |

Seed QA:

- test fixed seeds `1001`, `1002`, `1003`,
- test one random seed,
- replay latest seed,
- regenerate after death,
- validate route summary,
- confirm invalid route fallback if a forced-fail debug mode exists.

Regression checks:

- project imports/boots without missing scripts,
- no warning-as-error GDScript failures,
- input map contains all actions,
- HUD can instantiate,
- each enemy archetype can spawn, reset, and be defeated,
- each hazard can reset,
- player respawns at checkpoint after death/fall,
- generated route validates before clear.

## External Resource Adoption Contract

External packages and assets may be used if they improve the game foundation. The project must not stay attached to current code if a better foundation is proven.

Adoption gates:

- License is compatible with the project.
- Source URL and version are recorded.
- Imported code/assets are isolated so they can be upgraded or removed.
- The package passes a small local spike before production adoption.
- The package does not force a worse architecture than this contract.
- If the package owns a major system, this contract must be updated with the new public interface.

Preferred adoption modes:

1. **Reference only**: use as checklist or comparison.
2. **Isolated spike**: import into sandbox branch/folder and test.
3. **Wrapper integration**: keep package behind local contract.
4. **Replacement**: replace local implementation only after contract parity is proven.

High-value external categories:

- platformer controller reference,
- tile/room editor pipeline,
- map/room graph and metroidvania map tooling,
- UI/options/key remapping,
- AI/state machine tooling,
- dialogue/interaction tooling,
- procedural generation examples,
- CC0 coherent placeholder art,
- game-feel feedback tools.

## Acceptance Criteria

The rebuild contract is satisfied when:

- A future developer can implement the testbed suite from this document without reading old code.
- All canonical input actions exist and are visible in HUD/settings.
- Three profiles have distinct movement/combat identities.
- Movement metrics drive required geometry.
- The playable map is camera-followed and larger than one viewport.
- The map has compact side-view dungeon structure with verticality and intentional bounds.
- Required enemy, hazard, destructible, interactable, checkpoint, generated route, and exit proofs exist.
- Generated landscape uses deterministic seed/template assembly and validates passability.
- Every spawner has active/lifetime caps.
- Every required fall/death path recovers from checkpoint.
- Clear is gated by required validations.
- External resource adoption decisions are recorded before import.

## Related

- `docs/research/foundation_resource_survey_2026-07-05.md`
- `docs/design/MOTION_TEST_BED_SPEC.md`
- `docs/design/ENEMIES_TRAPS_GIMMICKS.md`
- `docs/design/MAP_AUTHORING_PIPELINE_CONTRACT.md`
- `docs/design/PROCEDURAL_REGION_GENERATION.md`
- `docs/design/testbed-plan/FEATURE_PRIORITY.md`
