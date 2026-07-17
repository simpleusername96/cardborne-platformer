---
type: plan
status: active
owner: BK
created: 2026-07-17
last_reviewed: 2026-07-17
topic: Cardborne isometric action RPG pivot
scope: Reset baseline through the first five-to-eight-minute authored combat proof and go/no-go decision
source: Owner pivot decision, repository inspection at 7cc069c, Godot 4.7 documentation, and Supergiant developer material
related:
  - ../Documentation.md
  - ../Prompt.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../docs/design/references/README.md
---

# Cardborne Isometric Action RPG Pivot

## Purpose

Rebuild Cardborne around a short, responsive isometric action-RPG proof before
restoring the former game's broad run, economy, and content systems. Checklist
items name proposed owners and include an observable acceptance check; directories
become durable only after their first working responsibility exists.

## Why / Context

The retired side-view build proved persistence, rewards, authored stages, UI, and
release correctness but did not meet the owner's fun target. Bastion and Hades
made a different target visible: free ground-plane movement, independent attack
direction, short readable commitments, coordinated enemy pressure, room-scale
encounters, and rewards that alter the next fight.

Adapting the old player controller, platform rooms, rope traversal, contextual
attack, and platform enemy trajectories would preserve the wrong constraints.
The runtime was therefore reset. Git commit `7cc069c` is the recovery boundary;
the active tree retains art and product identity, not legacy behavior.

## Scope / Non-scope

In scope:

- one Traveler on a two-dimensional top-down collision plane;
- isometric presentation with foot-point Y-sort and explicit occluders;
- independent movement and aim for keyboard/mouse and gamepad;
- explicit primary attack, secondary/ranged attack, dash, defense experiment,
  interact, potion, and pause commands;
- one melee/ranged tool pair, three enemy roles, solid cover, projectiles, and
  minimum impact feedback;
- three authored rooms, at least two non-identical completion objectives, one
  behavior-changing reward, and a Slime King proof encounter;
- a five-to-eight-minute playable loop and direct owner go/no-go review;
- the minimum UI, save boundary, and art slice needed to judge that loop.

Out of scope until the proof passes:

- restoring the former three-stage run or its save schema;
- jumping, ropes, one-way platforms, fall recovery, or stacked gameplay floors;
- procedural room graphs, random terrain, or broad biome production;
- all eight equipment models, all cards, full crafting economy, durability,
  ammunition bookkeeping, material grades, or permanent stat trees;
- multiple heroes/classes, active-skill bars, multiplayer, live service, or
  commercial-scale narrative production;
- final art for more than the proof rooms, proof actors, and proof boss.

## Assumptions

| Assumption | Why it matters | Guard |
| --- | --- | --- |
| “Isometric” means a visual projection over 2D gameplay, not a 3D simulation. | It keeps collision, aiming, navigation, and iteration tractable in Godot 2D. | No gameplay height or stacked navigation enters the first proof. |
| The retained art direction is accepted, but old camera compositions are not. | Palette and shape language survive without forcing side-view geometry. | New world assets are reviewed in an isometric graybox before production. |
| Traveler, cards, equipment, forging, merchants, rewards, persistence, and Slime King remain recognizable product identities. | The pivot is a new game built from Cardborne's useful identity, not a nameless clone. | Rebuild contracts only after the combat proof needs them. |
| The owner needs a playable comparison more than genre vocabulary or paper metrics. | Fun cannot be accepted from a long document. | Every milestone after the baseline extends the same playable route. |
| Godot 4.7 GL Compatibility remains the target. | Existing tooling, web export, and retained UI assets already fit it. | No engine or dependency change without owner approval. |

## Research Sources

Accessed 2026-07-17. Facts below come from primary engine documentation or
developer-authored/interview material; recommendations are Cardborne-specific
inferences.

- [Godot 4.7 CharacterBody2D](https://docs.godotengine.org/en/4.7/tutorials/physics/using_character_body_2d.html): `CharacterBody2D` supports precise scripted movement; `move_and_slide()` is suitable for top-down motion, and movement belongs in the physics loop.
- [Godot 4.7 TileMaps](https://docs.godotengine.org/en/4.7/tutorials/2d/using_tilemaps.html): `TileMapLayer` can carry collision, occlusion, and navigation, but overlapping 2D navigation meshes on one map produce logical errors. Cardborne should use one gameplay plane and treat tiles as optional authoring aids, not the visual unit.
- [Godot NavigationAgents](https://docs.godotengine.org/en/4.6/tutorials/navigation/navigation_using_navigationagents.html): an agent returns path positions but never moves its actor; custom movement must call and consume path updates in the physics loop. Enemy locomotion therefore remains an explicit owner, not a black box.
- [Godot CanvasItem Y-sort](https://docs.godotengine.org/en/4.5/classes/class_canvasitem.html): children with larger Y positions render in front when Y-sort is enabled. Actor sort anchors must be located at their feet.
- [Godot 4.7 AnimationTree](https://docs.godotengine.org/en/4.7/tutorials/animation/animation_tree.html): state machines and 2D blend spaces can separate locomotion direction from action transitions.
- [Supergiant on Bastion's development](https://www.gamedeveloper.com/game-platforms/road-to-the-igf-supergiant-games-dynamically-narrated-i-bastion-i-): Bastion started from a minimal seed; its distinctive combat, presentation, and narration emerged through months of playable prototyping rather than a complete paper design.
- [Supergiant's Bastion announcement](https://www.supergiantgames.com/blog/this-is-bastion/): exploration, customizable weapons, powers, and a safe preparation home were part of the product identity, but the first public goal was a playable build.
- [Hades FAQ](https://www.supergiantgames.com/blog/hades-faq/): Hades was structured to evolve from player feedback; modularity served iteration rather than existing as an architectural goal by itself.
- [Hades High Speed update](https://www.supergiantgames.com/blog/hades-the-high-speed-update-patch-notes/): Supergiant explicitly tuned input buffering, weapon behavior, projectile interaction, and visual/effect timing to improve feel and clarity.
- [Hades Superstar update](https://www.supergiantgames.com/blog/hades-superstar-update-patch-notes/): weapon aspects and upgrade combinations expanded playstyles instead of only increasing item count.
- [Hades overview](https://www.supergiantgames.com/blog/hades-coming-soon-to-steam-early-access/): Hades intentionally combines Bastion's fast action with deeper atmosphere and run-to-run growth.

## Research Findings Applied Here

1. Build and repeatedly play one room before designing a complete run.
2. Separate the ground-plane simulation from the isometric drawing illusion.
3. Keep movement and action state explicit; animation reflects state rather than
   deciding combat results.
4. Use authored room chunks and one navigation plane. Do not rebuild a tile-heavy
   procedural map before combat is accepted.
5. Make weapon and card choices change range, timing, positioning, or target
   priority; numeric-only upgrades wait.
6. Treat input buffering, hitbox/effect alignment, solid-cover projectile
   termination, and enemy recovery as core feel work.
7. Prefer frequent playable owner review to speculative feature completion.

## Decision Notes

Locked by the owner on 2026-07-17:

- Pivot from side-view action platformer to isometric action RPG.
- Delete the old runtime while retaining art style and core product identities.
- Search external implementations and production lessons before planning.

Implementation defaults accepted by this plan unless the owner changes them:

- Use Godot 2D, not a 3D camera or 3D physics world.
- Use large authored floor/wall/cover chunks and independent props. `TileMapLayer`
  is optional for graybox authoring and must not force repetitive visible tiles.
- Use one walkable navigation plane per room during the proof.
- Aim follows the mouse or right stick independently from movement; keyboard-only
  fallback aims toward the last meaningful attack direction.
- Melee and ranged/secondary actions remain explicit. No contextual resolver may
  silently choose the other tool.
- Room completion is objective-driven. “Kill every enemy” is allowed for a
  deliberate arena, not as the universal progression rule.
- The first proof uses authored rooms and deterministic encounter fixtures.
- Meta progression waits until the room-to-room combat loop is fun.

## Open Questions

| Question | Suggested first experiment | Decision gate |
| --- | --- | --- |
| Should defense be a universal guard or a weapon-specific secondary action? | Prototype a short guard/parry window beside a no-guard dodge-only configuration. | Keep only the version that creates an understandable decision without slowing the loop. |
| How much invulnerability should dash provide? | Compare movement-only dash with a short, clearly signaled damage-avoidance window. | Select from damage traces and owner feel; never hide the window. |
| Four or eight actor directions? | Four-direction locomotion with eight-direction attack facings in graybox. | Expand only if diagonal readability materially improves. |
| Mouse aim, facing aim, or soft target assist on controller? | Mouse/right-stick aim plus a narrow controller assist cone. | No target snap may redirect an explicit attack to a different lane. |
| How much of forging belongs in the proof? | One pre-run weapon choice and one post-room modification only. | Add the Forge screen only if it changes the next room's plan. |
| Does Slime King remain the first boss identity? | Reuse the illustration and theme with entirely new ground-plane patterns. | Replace only if its silhouette cannot support readable isometric patterns. |

## Proposed Design

### Simulation and presentation

```text
RoomRoot
  GroundArt                 large clean floor chunks; no gameplay state
  NavigationRegion2D        one non-stacked walkable region
  WorldCollision            walls and cover on the ground plane
  YSortActors               player, enemies, pickups, low props; sort at feet
  Occluders                 tall wall/foreground pieces with fade policy
  ProjectilesAndEffects     explicit collision and visual-height presentation
  EncounterRuntime          objective, spawns, completion, exits
  CameraRig                 follow, bounds, restrained impulse
  CanvasUI                  live HUD and pause/reward surfaces
```

Logical position is always the actor's ground contact point. A future leap,
knock-up, or projectile arc may use a visual-height offset, but collision and
navigation remain on the ground plane unless a later spec explicitly introduces
real elevation.

### Proposed responsibility owners

| Concern | Proposed owner | Must not own |
| --- | --- | --- |
| Raw commands and device state | `scripts/player/PlayerInput.gd` | movement physics, target selection, damage |
| Ground movement and dash | `scripts/player/PlayerMotor.gd` | animation timing, rewards, enemy queries |
| Action commitment and buffers | `scripts/player/PlayerActionController.gd` | UI or save mutations |
| Aim and optional assist | `scripts/player/AimResolver.gd` | choosing melee versus ranged |
| Attack data and execution | `scripts/combat/AttackDefinition.gd`, `AttackExecutor.gd` | reward or card UI |
| Damage transaction | `scripts/combat/Hitbox.gd`, `Hurtbox.gd`, `DamageRequest.gd`, `DamageResult.gd` | actor-specific movement |
| Player presentation | `scripts/presentation/PlayerPresenter.gd`, `AnimationTree` | authoritative hit timing |
| Enemy intent | `scripts/enemies/EnemyBrain.gd` and role-specific states | room completion or rewards |
| Enemy locomotion | `scripts/enemies/EnemyMotor.gd` with optional `NavigationAgent2D` | attack selection |
| Room geometry | `scripts/rooms/RoomDefinition.gd`, authored `.tscn` | encounter win conditions |
| Encounter objective | `scripts/encounters/EncounterRuntime.gd`, typed objective resources | global run settlement |
| Run and reward state | `scripts/run/RunSession.gd`, `scripts/cards/` | rendering and scene-local collision |
| UI | snapshot presenters under `scripts/ui/` | direct domain mutation |

### First playable loop

```text
arrival / movement check
  -> mixed melee + ranged encounter
  -> choose one behavior-changing card
  -> objective room: activate or survive while combat continues
  -> Slime King proof
  -> immediate replay / exit choice
```

The proof contains no mandatory economy tour. A reward is present only to prove
that the next room is played differently.

### Minimum enemy roles

- **Pursuer:** closes space and forces movement; clear startup and recovery.
- **Shooter:** owns a sightline; projectiles stop on solid cover unless explicitly
  tagged as piercing.
- **Controller:** creates a temporary danger zone or displacement problem without
  filling the whole room.

The mixed encounter must remain readable with all three active. Enemies may
reposition, reserve attack lanes, and yield when another high-attention tell is
active; they must not behave as unrelated timers stacked together.

### Minimum build proof

Three cards are enough:

- one changes dash positioning into an offensive opportunity;
- one converts a precise defense or enemy recovery into a counter opportunity;
- one changes ranged target priority, projectile behavior, or resource recovery.

The observer should identify the changed behavior without reading damage numbers.

## Current-State Map

| Concern | Current state after reset | Plan handling |
| --- | --- | --- |
| Runtime | Intentionally empty `scenes/main/PivotRoot.tscn` | Build upward from one combat sandbox. |
| Legacy code/data | Removed; recoverable at `7cc069c` | Consult only for a specific algorithm or identity mapping after review. |
| Art | Project-owned UI/world assets and references retained | Reuse palette and shell assets; produce new isometric world/actor assets. |
| UI Theme | `art/ui/production/production_ui_theme.tres` retained | Revalidate when the first live screen lands. |
| Tooling | Godot setup/export wrappers and art-reference tools retained | Add narrow pivot validators beside implemented behavior. |
| Product spec | No replacement gameplay PRD | Milestone 0 produces a short accepted brief from the playable hypothesis. |
| Save compatibility | No active runtime or save schema | Do not promise migration until the new run data is known. |

## As-Is / To-Be Delta Map

| Concern | As-is | To-be | Acceptance check | Guard |
| --- | --- | --- | --- | --- |
| Movement | No runtime; old platform controller retired. | Normalized eight-direction ground movement with acceleration, braking, dash, and independent aim. | Circle, diagonal, wall-slide, dash-end, and device-parity fixture. | No gravity, floor checks, coyote time, rope, or one-way-platform remnants. |
| Combat intent | Old contextual attack deleted. | Explicit primary and secondary actions with visible startup/active/recovery. | Requested tool and direction match every recorded attack. | No automatic melee/ranged substitution. |
| Collision | Empty baseline. | Ground-plane bodies, solid cover, hit/hurt areas, and projectiles. | No projectile crosses solid cover unless tagged piercing. | Visual height never bypasses collision silently. |
| Enemy movement | Platform trajectories deleted. | Role-specific steering/path following with recovery and lane ownership. | Actors reach legal targets, stop at range, and recover from obstruction. | NavigationAgent never becomes the behavior owner. |
| Encounters | Former stage-clear policies deleted. | Typed objectives: arena clear plus at least one activation/survival/priority/escape objective. | Exits follow the declared objective while irrelevant enemies may remain alive. | No global `all_enemies_dead` fallback. |
| Builds | Old card runtime deleted. | Three typed, bounded effects that change behavior. | Player and observer can name what changed in the next room. | No infinite dash, projectile, defense, or resource loop. |
| Art | Side-view world art retained as reference. | New isometric floor, wall, cover, actor, telegraph, and occluder assets. | Crossing/Y-sort/occlusion captures remain readable at three viewports. | Background art never owns collision or gameplay state. |
| Run/meta | Full former run deleted. | One short deterministic proof, then minimal session/reward/save contracts. | Start, replay, exit, and restart paths are deterministic. | Do not rebuild broad economy before the go decision. |

## Milestones

1. Reset baseline and short product contract.
2. One-room movement/attack sandbox.
3. Three-role combat and impact proof.
4. Three-room objective and reward loop.
5. Slime King and integrated five-to-eight-minute run.
6. Isometric art/UI slice and production-cost check.
7. Owner go/no-go decision and only then broader production planning.

## Tasks

### Milestone 0 — Reset and product contract

- [x] Delete the platformer runtime, typed content, rooms, stage tooling, release
  validators, obsolete plans, and obsolete product documents.
- [x] Preserve project-owned art, UI Theme, visual references, font license
  evidence, Godot wrapper, and export wrapper.
- [x] Point `project.godot` at an empty loadable reset scene.
- [ ] Create `docs/product/isometric_action_rpg_product_brief.md` after reviewing
  this plan with the owner.
  - As-is: no accepted gameplay spec.
  - To-be: a short player-facing contract for the first proof only.
  - Accept: owner can describe the intended 30-second combat exchange and
    five-to-eight-minute loop without genre jargon.
  - Guard: no full-game content inventory or inherited platform behavior.

### Milestone 1 — Movement and action sandbox

- [ ] Create `scenes/testbeds/isometric_combat/CombatSandbox.tscn` with one room,
  walls, cover, a target dummy, camera bounds, and debug overlay.
- [ ] Implement `PlayerInput`, `PlayerMotor`, `AimResolver`, and
  `PlayerActionController` with keyboard/mouse and gamepad parity.
- [ ] Implement one primary melee arc, one explicit ranged/secondary shot, dash,
  and the guard-versus-dodge experiment behind a development setting.
- [ ] Add command/action trace output for requested action, aim, start frame,
  commit frame, hit, cancellation, and recovery.

*Accept:* movement feels controllable with no enemies; every action starts in the
requested direction and tool; no action is lost at a legal recovery boundary.

*Guard:* source contains no gravity, floor, jump, rope, or contextual-attack
resolver path.

### Milestone 2 — Combat exchange

- [ ] Add typed attack, hitbox, hurtbox, damage, defeat, hitstop, recoil, and
  camera-impulse owners.
- [ ] Add Pursuer, Shooter, and Controller fixtures with visible startup, active,
  recovery, and defeat states.
- [ ] Add one non-stacked `NavigationRegion2D`; implement enemy locomotion around
  cover and separation from other actors.
- [ ] Add projectile/cover collision and a separately tagged piercing fixture.
- [ ] Add readable player damage source and concise retry.

*Accept:* the player can explain every received hit; the shooter cannot fire
through ordinary cover; enemies do not remain stuck or spam overlapping
high-attention attacks.

*Guard:* animation events may request presentation but never become the only
authoritative damage rule.

### Milestone 3 — Room objectives and reward

- [ ] Create three authored room scenes from large graybox chunks.
- [ ] Add typed encounter objectives: one deliberate arena clear and one
  activation, survival, priority-target, or escape objective.
- [ ] Add room entry, objective state, exit state, and quick restart snapshots.
- [ ] Add a three-card reward with exactly the dash, counter, and ranged behavior
  changes described above.
- [ ] Record room duration, damage source, action mix, objective completion, card
  selection, and first card use locally for development review.

*Accept:* an earlier or irrelevant enemy may remain alive when a non-extermination
objective legitimately opens the exit; the chosen card visibly changes the next
room.

*Guard:* no procedural graph, currency shop, durability, crafting grade, or
permanent save is introduced here.

### Milestone 4 — Boss and integrated proof

- [ ] Rebuild Slime King as a ground-plane actor with three or four patterns:
  committed lane attack, landing/recovery attack, safe-zone pattern, and add or
  priority-target pressure.
- [ ] Give each proof card one useful conversion without allowing any card to skip
  all execution.
- [ ] Connect start, three rooms, reward, boss, result, replay, and exit.
- [ ] Add only the session state and persistence needed to restart the proof and
  remember one accepted setting/loadout choice.

*Accept:* a first successful run lasts roughly five to eight minutes; patterns are
understood after exposure; replay begins without a menu/economy tour.

*Guard:* no former save migration promise, stage index, platform checkpoint, or
three-stage settlement contract returns automatically.

### Milestone 5 — Art and UI proof

- [ ] Produce one isometric floor/wall/cover kit from the active visual contract;
  use large chunks rather than visible repeated tiles.
- [ ] Produce Traveler and three enemy proof sprites with foot pivots and enough
  facings to read movement and attacks.
- [ ] Implement occluder fading or cutaway behavior for tall foreground walls.
- [ ] Reintroduce only the required HUD, card choice, pause/settings, result, and
  input glyph surfaces using the retained Theme/assets.
- [ ] Capture 960x540, 1280x720, and 1920x1080 crossings, combat, reward, and boss
  views.

*Accept:* actors sort correctly when crossing, foreground never hides an
unavoidable threat, attack visuals match hit timing, and the game still reads as
the accepted Cardborne art family.

*Guard:* generated backgrounds do not contain actors, pickups, telegraphs,
collision edges, text, or UI state.

### Milestone 6 — Go/no-go

- [ ] Give the owner a build and one continuous capture of the same proof path.
- [ ] Ask only concrete questions: Did each button do what you intended? Which hit
  felt unfair? Which card changed your next action? Did you want to replay? Is the
  result materially closer to the Bastion/Hades appeal you identified?
- [ ] Record `Go`, `Iterate`, or `No-go` with the exact failed category.
- [ ] On `Go`, create the replacement product spec and a separate production
  plan. On `Iterate`, change only the failed slice. On `No-go`, preserve the proof
  commit and stop content expansion.

## Progress

Completed on 2026-07-17:

- Created branch `agent/isometric-arpg-pivot-plan` from local `master`.
- Inspected the former runtime owners, document authority, retained art, and Git
  state.
- Researched Godot 2D movement, navigation, Y-sort, TileMapLayer, AnimationTree,
  and Supergiant's prototyping/iteration evidence.
- Removed the platformer runtime and obsolete documentation/tooling while keeping
  art and provenance.
- Added the empty pivot boot scene and this active ExecPlan.
- Validated the reset with Godot 4.7 import and a short headless start; no deleted
  runtime reference or startup error remains.

Not started:

- replacement gameplay product brief;
- movement/combat sandbox;
- isometric world or actor production;
- new run, reward, UI, or save runtime.

## Next Steps

1. Review this plan's locked decisions and open questions with the owner.
2. Write the short product brief from accepted decisions.
3. Implement Milestone 1 as the first playable change; do not restore menus,
   catalogs, or persistence first.

## Test Plan

Inner loop:

- `./tools/godot.ps1 --path . --headless --import`
- `./tools/godot.ps1 --path . --headless --quit-after 2`
- one focused headless validator beside each new subsystem;
- a short live sandbox run after movement, action, enemy, or camera changes.

Milestone gates:

| Gate | Evidence |
| --- | --- |
| Reset | clean Godot import/start, no references to deleted runtime paths |
| Movement | normalized diagonal speed, wall slide, dash endpoint, input-device parity, action trace |
| Combat | hit timing, cover termination, defeat cleanup, no duplicate damage, source trace |
| Enemy | reachable navigation target, obstruction recovery, role spacing, attack-attention cap |
| Encounter | each objective fixture, exit policy, quick retry, irrelevant enemy remaining where legal |
| Build | bounded triggers, first-use trace, no infinite loop, observer-visible behavior change |
| Boss | each pattern, legal safe response, each build, defeat cleanup, retry/replay |
| Art/UI | Y-sort crossing, occlusion, telegraph readability, three viewports, keyboard/gamepad focus |
| Final | production Web export and owner continuous-play review |

Starting performance fixture: 1280x720, 12 ordinary enemies, and 32 simultaneous
projectiles/effects should maintain the project target frame rate on the local
reference machine. Tune the fixture after the first real actor/effect pass rather
than treating placeholder performance as final evidence.

Human acceptance is mandatory. Automated correctness cannot mark movement,
impact, card satisfaction, or replay desire as passed.

## Rollback / Safety

- Pre-pivot runtime recovery point: Git commit `7cc069c`.
- Active work stays on `agent/isometric-arpg-pivot-plan` until the reset and plan
  are reviewed; no force push or history rewrite is required.
- Project-owned art and third-party license evidence remain untouched by runtime
  deletion.
- Do not copy entire retired directories back. Recover one inspected algorithm,
  asset mapping, or text fragment only when the new owner needs it.
- Do not migrate or overwrite existing player saves during the proof. Use a new
  development-only path if persistence becomes necessary.
- Each milestone ends in a coherent commit with its own playable entry point and
  rollback boundary.

## Risks

- **The pivot imitates surface features without improving feel.** Mitigation:
  judge the movement/attack sandbox before adding rooms or meta systems.
- **Isometric art obscures ground truth.** Mitigation: feet anchors, one gameplay
  plane, explicit cover collision, occluder captures, and no baked telegraphs.
- **Navigation agents produce jitter or passive enemies.** Mitigation: custom
  motors own motion, path updates occur in physics, and obstruction recovery is a
  required fixture.
- **Independent aim is awkward on one input device.** Mitigation: test mouse,
  right stick, facing fallback, and narrow assist with identical encounters.
- **Cards become number upgrades again.** Mitigation: accept only effects whose
  changed behavior is visible in the next room.
- **The former economy is rebuilt before fun is proven.** Mitigation: meta systems
  remain out of scope until the integrated proof receives `Go`.
- **The plan becomes another abstract document.** Mitigation: Milestone 1 is the
  immediate next work and every later milestone extends the same playable path.
- **The reset removed a useful implementation.** Mitigation: `7cc069c` is a stable
  read-only recovery point; targeted recovery remains possible.

## Stop Conditions

Stop and request an owner decision when:

- the owner wants true 3D elevation or stacked walkable floors;
- a new external package or asset dependency appears necessary;
- save compatibility with the deleted runtime becomes a requirement;
- the first combat sandbox is not materially more promising after two focused
  control/feel iterations;
- expanding content is proposed before the five-to-eight-minute proof receives
  an explicit `Go`.
