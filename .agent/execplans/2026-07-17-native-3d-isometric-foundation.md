---
type: plan
status: done
owner: BK
created: 2026-07-17
last_reviewed: 2026-07-17
topic: Cardborne native 3D arena, camera, facing, combat input, and soft targeting
scope: Playable 3D combat room through a readable moving-camera keyboard targeting proof
source: Owner control and camera/readability decisions after reviewing the native 3D proof and public targeting implementations
related:
  - ../Prompt.md
  - ../../docs/product/isometric_action_rpg_product_brief.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../docs/research/third_party_adoption_ledger.md
---

# Cardborne Native 3D Arena, Facing, and Targeting Refinement

The native Godot 4.7 room, movement, damage fixtures, and Web route already
exist. This plan keeps that foundation and completes four executable phases:
the revised keyboard/product contract, a larger cutaway arena with a following
camera and explicit facing feedback, bounded attack-time soft targeting, and
production-style validation. The resulting proof must not reveal the whole map
in one frame, must keep the Traveler visible near camera-facing boundaries, and
must let a keyboard player predict both attack directions without persistent
lock-on or trajectory clutter.

## Purpose

- **Objective:** enlarge the arena beyond one camera frame, preserve Traveler
  visibility with cutaway-height boundaries, and make facing and attack selection
  legible with arrow-key movement, `Shift` melee, `Z` ranged, and held `X` guard.
- **Final artifact:** the existing `CombatSandbox3D` with a bounded following
  orthographic camera, deterministic attack direction, short-lived targeting
  feedback, multiple target fixtures, and automated plus rendered evidence.
- **Completion state:** keyboard and existing gamepad bindings execute the same
  semantic actions; room framing, camera following, visibility, movement,
  facing, assistance, guard precedence, cover, and fallback behavior pass the
  checks in this plan.

## Why / Context

The current Traveler updates `facing` only from non-zero movement and fires both
attacks directly along that vector. Its capsule body and round head are nearly
symmetrical, so the sword is the only weak front cue. The existing room also has
only one stationary dummy, which cannot reveal target switching, occlusion, or
near-target behavior.

The owner has now selected a keyboard-first action cluster: arrow keys move,
`Shift` performs the ordinary melee attack, `Z` performs the ranged attack, and
holding `X` guards. Because that layout has no independent aim axis, attacks need
bounded assistance, but continuous nearest-enemy rotation would take control of
movement and make facing unstable. The accepted behavior is therefore an
explicit facing marker plus assistance only when an attack starts.

The current visual room spans 20×20 m but its walkable collision is 18×18 m,
while the fixed orthographic camera uses size 20.5 and shows nearly the entire
room at once. The camera does not follow the Traveler. The camera sits on the
`+X/+Z` side, so the east and south perimeter walls and the 1.8 m central tall
cover can cross the Traveler silhouette. The owner requires a slightly larger
map that cannot fit in one frame and physical cutaway visibility rather than
leaving the character hidden behind foreground geometry.

## Assumptions

- The proof retains one flat walkable ground plane, a fixed isometric camera
  angle, and no jump, elevation, or camera rotation.
- The current Kenney room is placeholder presentation; proportional X/Z scaling
  and vertical cutaway compression are acceptable for this proof.
- A small amount of exterior darkness beyond the room edge is acceptable, but
  it must not occupy the Traveler safe frame or obscure navigation.
- Physical low walls and low cover are the visibility solution. Occluder fading,
  wall transparency, silhouette shaders, and runtime mesh surgery are excluded.

## Proposed Design

- Scale `Architecture/RoomLarge` to `Vector3(1.10, 0.30, 1.10)`, increasing its
  X/Z footprint from 20×20 m to 22×22 m while reducing its 4.23 m combined wall
  height to approximately 1.27 m.
- Scale the explicit floor and perimeter collision footprint by the same 1.10
  X/Z factor and reduce boundary collision height to 1.40 m. Collision remains
  authored separately rather than generated from the imported mesh.
- Reduce `TallCover` visual and collision height from 1.80 m to 1.15 m; retain
  `LowCover` at 1.10 m. Projectile-blocking truth continues to match visuals.
- Keep the camera angle and local offset `Vector3(13, 16, 13)`, reduce
  orthographic size from `20.5` to `15.5`, and make `CameraRig` follow the
  Traveler's X/Z position with exponential speed `8.0`.
- Clamp the camera rig center independently to X/Z `[-3.5, 3.5]`, preserving the
  cutaway room inside frame near boundaries while allowing the player to reveal
  different parts of the arena through traversal.
- Keep world-space direction and target feedback attached to gameplay positions;
  camera motion does not change targeting vectors or screen-relative input.

## Pre-plan Evidence Already Verified

| Source or path | Verified fact | Decision affected | Freshness or recheck boundary |
| --- | --- | --- | --- |
| Owner decision, 2026-07-17 | Keyboard actions are `Shift` melee, `Z` ranged, and `X` guard. | Replaces the current keyboard action ownership. | Recheck only if the owner changes the binding. |
| `scripts/main/pivot_root.gd::_register_input_map()` at commit `6cbf491` | Current runtime registers `Z` melee, `X` ranged, and `Shift` guard; gamepad uses RB, RT, and LB respectively. | Change keyboard events without renaming semantic actions or changing gamepad ownership. | Recheck if input registration moves out of `PivotRoot`. |
| `scripts/player/traveler_3d.gd` at commit `6cbf491` | One `facing` vector owns visual rotation, melee query placement, projectile direction, and dash fallback. It changes only on movement. | Split movement intent, persistent combat facing, and cached attack direction. | Recheck if the player controller is replaced. |
| `scenes/testbeds/isometric_combat/CombatSandbox3D.tscn` at commit `6cbf491` | Traveler is a capsule and sphere with one sword cue; the room contains one target and solid cover. | Add low-noise direction/target markers and a multi-target fixture without new art dependencies. | Recheck when a production character replaces the primitive. |
| `CombatSandbox3D.tscn` and `scripts/presentation/isometric_camera_3d.gd`, inspected 2026-07-17 | Floor collision is 18×18 m; the imported room bounds are 20×20×4.23 m; camera offset is `(13,16,13)`, orthographic size is 20.5, and the rig only calls `look_at()` once. | Enlarge the arena, reduce camera scale, and add bounded player following. | Recheck if the room or camera scene owner changes. |
| `room-large.glb` GLTF structure and `inspect_kenney_3d_assets.gd`, inspected 2026-07-17 | `room-large.glb` is one 20×20×4.23 m mesh; individual camera-side walls cannot be hidden as child nodes. | Lower the combined room vertically instead of pretending selective wall removal is available. | Recheck only if a modular wall asset replaces this GLB. |
| `build/validation/movement-check-1280x720.png`, captured 2026-07-17 | Nearly the whole room is visible, and south/east perimeter walls plus tall center cover occupy the foreground. | Require incomplete-map framing and edge-position visibility captures. | Replace with new evidence after Phase 4. |
| `tools/validation/validate_movement_and_actions.gd` at commit `6cbf491` | The validator asserts the old keys and covers only a single forward target. | Replace stale key assertions and add angle, occlusion, stickiness, and fallback cases. | Recheck whenever an input or targeting contract changes. |
| `docs/product/isometric_action_rpg_product_brief.md`, reviewed 2026-07-17 | The active spec still states the old keys and defers assisted aiming. | Phase 1 updates the canonical proof contract before behavior lands. | No implementation may finish while this conflict remains. |
| [voganart/zeldaclone `player.gd`](https://github.com/voganart/zeldaclone/blob/94c9b530ca172b561bd8e51ab7a98de327c758f6/entities/player/player.gd), inspected 2026-07-17 | Its MIT-licensed soft lock resolves only when attacking, uses movement or current forward as intent, filters range/cone, and widens the cone at close range. | Use attack-time acquisition and a wider close-melee cone; do not continuously rotate. | Behavioral reference only; no source is copied. |
| [Cat's Godot 4 modular Souls-like targeting system](https://github.com/catprisbrey/Cats-Godot4-Modular-Souls-like-Template/blob/d8bceffc5bf4afe585a3a926fd9aa60ebd26e001/player/player_targeting_system/player_targeting_system.gd), inspected 2026-07-17 | Its Unlicense implementation separates candidate sensing, line of sight, retargeting, and reticle feedback. | Keep visibility and feedback separate from attack execution. | Behavioral reference only; hard lock is not adopted. |
| [TetraForce `entity.gd`](https://github.com/loudsmilestudios/TetraForce/blob/fa5fa7685ce56be0bc3e640496f8debf262d0ee2/entities/entity.gd), inspected 2026-07-17 | Its MIT-licensed no-assist scheme remains readable because direction selects explicit directional sprites and attacks. | The primitive Traveler needs a visible front cue before no-assist fallback is acceptable. | Behavioral reference only; no source is copied. |

## Locked Decisions

| Topic | Final decision | Rationale / source |
| --- | --- | --- |
| Keyboard mapping | Arrow keys move; `Shift` is melee; `Z` is ranged; held `X` is guard; Space dashes; `C` uses a potion; Esc pauses; `R` resets the proof. | Owner decision; preserves the right-hand movement and lower-left action cluster. |
| Gamepad mapping | Keep left-stick movement, A dash, LB guard, RB melee, RT ranged, Y potion, and Start pause. | The owner changed keyboard ownership only; existing semantic actions remain shared. |
| Input semantics | Retain action names `melee`, `ranged`, and `guard`; replace only their keyboard events. Remove the old cross-bindings rather than adding aliases. | Prevents code and UI from carrying two contradictory keyboard layouts. |
| Direction model | Maintain `move_direction`, persistent `combat_facing`, and per-attack `resolved_attack_direction`. Non-zero movement updates `combat_facing`; idle preserves it. | Movement remains direct while attacks receive an immutable direction. |
| Direction feedback | Do not add a HUD arrow. Rotate the Traveler visual and an always-visible prototype ground ring/front notch to `combat_facing`. | World-space feedback stays next to the controlled object and avoids HUD clutter. |
| Assistance timing | Resolve a target only when melee or ranged starts. Do not rotate toward enemies during ordinary movement or idle. | Preserves player intent and prevents nearest-target oscillation. |
| Intended direction | Use current non-zero camera-relative movement input; otherwise use `combat_facing`. | An actively held direction outranks stale facing without adding an aim key. |
| Target contract | Eligible nodes belong to `attack_targets`, expose a `TargetPoint: Marker3D`, and return true from `is_targetable()`. Missing contract members make the node ineligible. | Gives dummies and future enemies one explicit, testable interface. |
| Visibility | Cast from the Traveler attack origin to `TargetPoint` against World and Enemy. The first collision must be the candidate; solid cover always rejects assistance. | Assistance must not reveal or select targets through cover. |
| Candidate score | Lowest normalized score wins: `0.75 * angular_error / half_cone + 0.25 * distance / max_distance`. Ties within `0.001` resolve by instance ID for deterministic tests. | Directional intent dominates distance while remaining stable. |
| Melee profile | Maximum target-point distance `2.75 m`; full cone `110°`; candidates at or below `1.60 m` use a full `160°` close cone. | Wide nearby capture supports keyboard combat without selecting a rear target. |
| Ranged profile | Maximum target-point distance `14.0 m`; full cone `50°`. | A `25°` half-cone covers gaps between eight movement sectors without redirecting to another lane. |
| Stickiness | Cache one assisted target per attack family for `0.45 s`. Reuse it only while it remains targetable, visible, in range, and inside that attack's base cone; otherwise reacquire immediately. | Prevents flicker without preserving a target against changed intent. |
| Fallback | With no valid candidate, attack exactly along intended direction and show no target marker. | Assistance never converts a miss into an unrelated attack. |
| Attack commitment | Cache the resolved direction when the attack starts. Later movement cannot bend a melee hit or an already-created projectile. | Keeps startup and resulting hit spatially honest. |
| Feedback duration | Show the chosen target's ground ring for `0.35 s`, beginning at attack startup. Hide it immediately if the node becomes invalid. | Makes correction visible without creating persistent hard lock UI. |
| Action precedence | Held `X` guard wins over Space, `Shift`, and `Z`; an accepted Space dash wins over same-frame attacks; otherwise `Shift` melee wins over same-frame `Z` ranged. | Removes frame-order ambiguity and preserves defensive intent. |
| Guard behavior | Keep current 65% damage reduction, 45% movement speed, visible shield, and attack/dash suppression while `X` is held. | This plan changes access and legibility, not guard balance. |
| Arena footprint | Scale the combined room X/Z to `1.10`; use a 19.8×19.8 m floor collision and proportionally scaled perimeter collision. Reposition the decorative north gate/corridor by the same Z factor. | A 10% linear increase is visibly larger without turning the proof into a content map. |
| Cutaway walls | Scale the combined `RoomLarge` Y to `0.30`, producing approximately 1.27 m walls; boundary collision height is 1.40 m and remains aligned on X/Z. | The GLB is one mesh, so lowering the full perimeter is the safe physical cutaway. |
| Foreground cover | `TallCover` visual and collision height become 1.15 m at center Y 0.575 m; `LowCover` stays 1.10 m. | Both still block a projectile launched at 0.75 m while leaving the Traveler's head and torso readable. |
| Camera projection | Keep the current fixed isometric orientation and local offset; use orthographic size `15.5`. No zoom control or camera rotation is added. | The expanded map cannot fit in one frame, while combat scale stays readable. |
| Camera follow | `CameraRig` follows the Traveler on X/Z with exponential speed `8.0`, fixed look height `0.8 m`, and rig-center clamps of `[-3.5, 3.5]` on both axes. | Traversal reveals the room without exposing excessive exterior void at boundaries. |
| Camera framing | No runtime frame may show all four walkable-room corners. After one stationary second, the camera settles within 0.15 m of its clamped target. The Traveler remains within 15–85% of each viewport axis while the rig is free and within 10–90% at clamped room edges. | Makes the larger map and visibility requirement measurable. |
| Occlusion policy | Use authored cutaway height and low cover only. Do not add transparency, fade shaders, X-ray silhouettes, near-plane clipping, or imported wall assets. | Solves the observed problem without a second presentation system or dependency. |
| Assets and dependencies | Build indicators from flat unshaded Godot meshes and existing palette colors. Add no package, SVG, raster image, or runtime dependency. | Matches the proof's placeholder and flat-color constraints. |

### World-space feedback contract

- The facing marker is a thin muted-teal ring with a warm-amber front notch,
  centered at the Traveler's feet at `y = 0.03 m`.
- The ring uses `#7FA6A2` at 55% alpha; the notch uses `#D4A33F` at 85% alpha.
  Both materials are unshaded and texture-free.
- The target marker is an unshaded `#D4A33F` ring at 80% alpha, centered on
  `TargetPoint` projected to `y = 0.04 m`.
- The marker communicates facing, not velocity. Locomotion and displacement
  communicate movement; no second movement arrow is introduced.
- No persistent aim line, enemy trajectory, off-screen pointer, or global
  nearest-target marker is part of this proof.

## Rejected Alternatives

| Alternative | Why it was viable | Why it was rejected |
| --- | --- | --- |
| Last movement only with no indicator | Smallest code change and current behavior. | The symmetrical primitive does not make its front readable and misses are difficult to diagnose. |
| Continuous nearest-enemy auto-facing | Requires no independent aim input. | It overrides movement intent, can turn 180°, and flickers as distances cross. |
| Persistent hard lock and target cycling | Provides deliberate target ownership. | It adds another command, camera/strafe behavior, and persistent UI before the basic keyboard loop is proven. |
| Mouse aim or a keyboard aim cluster | Gives precise ranged direction. | It conflicts with the selected arrow-key plus lower-left-key proof and is not needed for this bounded iteration. |
| One contextual attack key | Reduces key count. | The product requires explicit melee and ranged intent. |
| Large HUD direction arrow or full attack trajectory | Extremely explicit. | It disconnects feedback from the actor and adds visual noise the owner previously rejected. |
| Keep the fixed camera and enlarge only the floor | Minimal camera work. | The Traveler would leave the frame and the user could not inspect the expanded room. |
| Zoom out to show the expanded room | Preserves a static overview. | It directly contradicts the requirement that the entire map not fit in one screen. |
| Hide only south/east wall nodes | Would preserve tall far walls. | `room-large.glb` is a single combined mesh, so those nodes do not exist. |
| Fade foreground geometry or show an X-ray silhouette | Can preserve tall architecture. | It adds transparency ordering and a second visibility language before the physical cutaway proof is tested. |

## Current State

Already true at commit `6cbf491`:

- Godot 4.7 native 3D, fixed orthographic camera, camera-relative normalized
  movement, dash, guard, melee, ranged projectile, potion, pause, cover, and a
  timed damage fixture run from one scene.
- The current camera is fixed at the room center and size 20.5; it does not
  follow the Traveler, and the nearly complete 18×18 m walkable area is visible
  in the 1280×720 baseline.
- Ordinary ranged projectiles collide with World and Enemy and terminate on
  solid cover.
- Existing validation sends real `InputEventKey` events and captures the proof
  at 960x540, 1280x720, and 1920x1080.
- The native 3D foundation and functional keyboard baseline are recoverable from
  commits `c18fd3d` and `6cbf491`.

Remaining implementation:

- replace the stale keyboard mapping in runtime, HUD, spec, captures, and tests;
- expand the room/collision footprint, lower foreground occluders, and implement
  bounded camera following without changing the fixed isometric angle;
- split movement, facing, and attack direction ownership;
- add reusable targeting and world-feedback components;
- give the dummy and test fixtures the target contract;
- add deterministic multi-target, occlusion, stickiness, and fallback checks;
- export and inspect the built Web proof.

## Scope / Non-scope

In scope:

- revised keyboard bindings and matching on-screen control text;
- 10% larger arena footprint, cutaway-height perimeter, low projectile-blocking
  cover, and a bounded following orthographic camera;
- explicit facing marker and short-lived target marker;
- attack-time melee and ranged target assistance with line of sight;
- three reusable target fixtures in the existing authored room;
- exact automated, rendered, and built-artifact validation;
- canonical product-brief correction for this accepted behavior.

Out of scope:

- mouse aim, right-stick aim, hard lock, target cycling, player-controlled camera
  steering/zoom, or strafing mode;
- full enemy AI, encounter waves, boss behavior, cards, rewards, route flow, or
  procedural rooms;
- final character model, directional animation set, final VFX, audio, or damage
  and combo-balance changes;
- changing dash, guard reduction, projectile speed, potion values, or current
  damage numbers;
- external assets or dependencies.

Destructive or irreversible actions:

- none; the work replaces key events and scene nodes in version-controlled
  files and is recoverable through scoped commits.

Exact actions requiring owner approval:

- any remap away from `Shift` melee, `Z` ranged, or `X` guard;
- adding mouse/right-stick aim, hard lock, or persistent target UI;
- importing a new asset or dependency;
- replacing the fixed isometric angle, cutaway wall approach, or locked arena
  and camera measurements;
- changing combat damage, cooldown, guard mitigation, or movement baselines.

## Architecture and Ownership

| Concern | Final owner | Interface or invariant | Existing owner to reuse or retire |
| --- | --- | --- | --- |
| Input registration | `scripts/main/pivot_root.gd::_register_input_map()` | Semantic action names remain stable; each keyboard action has exactly its accepted physical key. | Reuse `PivotRoot`; retire the three old keyboard events. |
| Arena geometry and collision | `scenes/testbeds/isometric_combat/CombatSandbox3D.tscn` | Visual room scale, explicit floor/walls, cover heights, gate/corridor placement, and target fixtures stay authored together; visual and collision X/Z extents agree. | Reuse the existing scene; do not modify the third-party GLB. |
| Camera following | `scripts/presentation/isometric_camera_3d.gd` on `CameraRig` | Fixed orientation and orthographic size; follows only clamped Traveler X/Z and never mutates player movement or targeting. | Extend the existing one-shot camera owner rather than adding camera logic to `Traveler3D`. |
| Movement and action orchestration | `scripts/player/traveler_3d.gd` | Samples movement, applies action precedence, caches resolved attack direction, and emits presentation signals; it does not score candidates or own marker meshes. | Refine current `Traveler3D` rather than replacing physics. |
| Target acquisition | New `scripts/player/targeting/targeting_assist_3d.gd` on `Traveler/TargetingAssist` | `resolve_attack(kind, origin, intended_direction)` returns a typed result containing target, direction, and assisted state. It owns filtering, score, visibility, and sticky expiry. | Extract candidate logic from attack methods; no duplicated melee/ranged searches. |
| Target result | Inner `TargetingResult` class in `targeting_assist_3d.gd` | `target: Node3D`, normalized planar `direction: Vector3`, and `assisted: bool`; fallback always contains the intended direction. | Avoid untyped Dictionaries and a premature shared data module. |
| Target eligibility | `scripts/combat/damageable_dummy_3d.gd` and future enemy owners | Group `attack_targets`, child `TargetPoint`, `is_targetable()`. Dead/resetting targets return false. | Extend the dummy contract without moving enemy behavior into player code. |
| World combat feedback | New `scripts/ui/world/combat_direction_feedback_3d.gd` on sandbox sibling `CombatDirectionFeedback` | Follows Traveler facing and target-feedback signals; owns facing and target marker meshes only. | HUD remains health/potion/control text and does not absorb world markers. |
| Test fixtures | New `scenes/testbeds/isometric_combat/TargetDummy3D.tscn` plus `CombatSandbox3D.tscn` | Three instances provide near-front, ranged, and occluded target arrangements; explicit collision remains authoritative. | Extract the current inline dummy so fixtures share one contract. |
| Automated behavior | `tools/validation/validate_movement_and_actions.gd` | Real input events verify accepted keys, direction resolution, target choice, guard precedence, and cover. | Extend the existing validator; do not add a second test runtime. |
| Render evidence | `tools/validation/capture_movement_check.gd` | Capture ready, moving-facing, melee-assist, ranged-assist, guard, and pause states. | Replace Shift guard capture with X guard and retain three viewport baselines. |
| Product contract | `docs/product/isometric_action_rpg_product_brief.md` | Lists accepted keyboard binding and attack-time assistance; no longer says assistance is deferred. | Update in Phase 1 before implementation is declared complete. |

## As-Is / To-Be Delta Map

| Concern | As-is | To-be | Acceptance check | Guard / leftover check |
| --- | --- | --- | --- | --- |
| Keyboard actions | `Z` melee, `X` ranged, Shift guard. | Shift melee, `Z` ranged, held `X` guard. | Real key events trigger exactly the intended action. | Old key/action pairs are absent from runtime, HUD, spec, captures, and tests. |
| Map framing | Nearly all of the 18×18 m walkable room fits under a fixed size-20.5 camera. | 19.8×19.8 m walkable footprint under a size-15.5 following camera. | No tested frame contains all four room corners; traversal reveals different regions. | Do not compensate by zooming back out. |
| Foreground visibility | Combined 4.23 m room walls and 1.8 m tall cover can cross the Traveler silhouette. | Approx. 1.27 m cutaway walls and 1.15 m tall cover. | South/east edge captures retain the full head and torso. | No fade shader, X-ray outline, or visual/collision cover mismatch. |
| Camera ownership | Camera aims once at the room center. | Rig follows clamped Traveler X/Z at speed 8.0 with fixed orientation. | It settles within 0.15 m after one stationary second and keeps the Traveler in the safe frame. | Camera motion cannot change input or attack world vectors. |
| Facing | One vector silently follows last movement. | Persistent combat facing drives body and foot marker. | All eight movement sectors rotate both cues; idle retains the last sector. | No HUD arrow or independent movement marker appears. |
| Melee direction | Hit sphere is placed along stale facing. | Direction resolves and caches at melee startup. | Near/front valid target is selected; rear/occluded target is ignored. | Movement during the swing cannot bend its hit query. |
| Ranged direction | Projectile fires along stale facing. | Direction resolves once within a narrow visible cone. | Valid aligned target is selected; absent target fires straight. | Projectile cannot home or pass through World. |
| Multiple targets | One stationary dummy. | Three reusable fixtures cover competing and occluded targets. | Score and stickiness choose deterministically. | No fixture behavior leaks into production enemy ownership. |
| Feedback | Sword and temporary text are the only directional cues. | Ground front notch is persistent; target ring lasts 0.35 seconds. | Captures show both at all supported viewports without occlusion or clipping. | No marker is visible for fallback or through cover. |

## Milestones

1. Replace the keyboard and canonical product contract without changing gamepad
   semantics or unrelated combat values.
2. Enlarge the cutaway arena, add bounded camera following, separate movement
   and facing, then render the accepted world-space feedback.
3. Add the reusable target contract and bounded melee/ranged assistance.
4. Pass deterministic, rendered, exported-Web, and managed-runtime gates.

## Tasks

### Phase 1: Replace the input and product contract

**Goal:** a user can launch the current proof and use the newly accepted keys
before targeting behavior changes.

Source owners touched: `scripts/main/pivot_root.gd`,
`scenes/testbeds/isometric_combat/CombatSandbox3D.tscn`,
`tools/validation/validate_movement_and_actions.gd`,
`tools/validation/capture_movement_check.gd`,
`docs/product/isometric_action_rpg_product_brief.md`.

- [x] **1.1 Replace only the keyboard events for semantic combat actions.**
  - As-is: `melee=Z`, `ranged=X`, `guard=Shift`.
  - To-be: `melee=Shift`, `ranged=Z`, `guard=X`; keep gamepad events and all
    other keyboard events unchanged.
  - Accept: InputMap contains each accepted physical key and real events reach
    the matching action.
  - Guard: assert the three old key/action pairs are absent rather than retained
    as hidden aliases.
- [x] **1.2 Correct every visible and canonical statement of the controls.**
  - As-is: HUD, active product brief, capture setup, and assertions state the
    old layout.
  - To-be: all state the new layout; guard capture holds X.
  - Accept: `rg` finds no active `SHIFT GUARD`, `Z MELEE`, or `X RANGED` proof
    contract.
  - Guard: historical superseded documents remain historical and are not
    rewritten merely to erase context.
- [x] **1.3 Lock action precedence in `Traveler3D`.**
  - As-is: processing order happens to make guard and dash win but has no direct
    regression assertion.
  - To-be: held X guard, then accepted dash, then melee, then ranged is the
    explicit same-frame order.
  - Accept: simultaneous-input tests produce one action and no damage/projectile
    side effect from suppressed actions.
  - Guard: potion and pause ownership remain unchanged.
- [x] **1.4 Record the accepted arena and camera contract in the product brief.**
  - As-is: the active spec names a fixed orthographic camera but does not require
    a map larger than one frame, player following, or cutaway visibility.
  - To-be: add the locked 10% footprint increase, size-15.5 following camera,
    low-wall/cover visibility rule, and no-full-map-frame acceptance behavior.
  - Accept: the product brief and this plan state identical camera, arena, and
    visibility behavior before Phase 2 lands.
  - Guard: do not turn proof measurements into root policy or a procedural-map
    contract.

**Batch acceptance:** launch once and confirm arrows, Space, Shift, Z, X, C, Esc,
and the existing gamepad semantic actions all respond.

**Batch guard:** movement, dash invulnerability, projectile cover, potion, pulse,
and pause assertions still pass before Phase 2.

### Phase 2: Enlarge the visible play space and make facing readable

**Goal:** traversal reveals only part of the larger room at a time, the camera
follows without changing its isometric angle, foreground geometry preserves the
Traveler silhouette, and attack facing is inspectable before assistance is added.

Source owners touched: `scenes/testbeds/isometric_combat/CombatSandbox3D.tscn`,
`scripts/presentation/isometric_camera_3d.gd`, `scripts/player/traveler_3d.gd`,
and new `scripts/ui/world/combat_direction_feedback_3d.gd`.

- [x] **2.1 Expand the authored room and explicit collision footprint.**
  - As-is: imported room scale is 1.0, floor collision is 18×18 m, and decorative
    gate/corridor placement matches the smaller footprint.
  - To-be: apply `RoomLarge` scale `(1.10,0.30,1.10)`, floor size 19.8×19.8 m,
    long-wall X/Z length 20.9 m, wall thickness 0.88 m, wall centers at ±10.34 m,
    and proportional north gate/corridor Z placement.
  - Accept: the walkable X/Z extent increases by exactly 10%, visuals and
    collision meet at every boundary, and reset/spawn/fixtures remain legal.
  - Guard: do not edit, duplicate, or destructively re-export the third-party
    GLB; retain one flat navigation plane.
- [x] **2.2 Lower physical foreground occluders.**
  - As-is: the combined imported room reaches 4.23 m and `TallCover` reaches
    1.80 m.
  - To-be: combined room height is approximately 1.27 m; perimeter collision is
    1.40 m high and centered at Y 0.70 m; `TallCover` visual/collision is 1.15 m
    high and centered at Y 0.575 m; `LowCover` remains 1.10 m.
  - Accept: the south/east boundary and both cover cases leave the Traveler head
    and torso readable while both cover shapes still block a projectile at
    launch height 0.75 m.
  - Guard: no transparent material, shader fade, silhouette outline, near-plane
    clipping trick, or visual/collision mismatch is introduced.
- [x] **2.3 Add bounded player following to `IsometricCameraRig3D`.**
  - As-is: the camera calls `look_at()` once, stays centered on the room, and
    uses orthographic size 20.5.
  - To-be: keep offset `(13,16,13)` and fixed rotation, set size 15.5, follow the
    Traveler X/Z with exponential speed 8.0, and clamp rig center X/Z to
    `[-3.5,3.5]`; retain look height 0.8 m.
  - Accept: no frame contains all four floor corners, the rig settles within
    0.15 m of its clamped target after one stationary second, and the Traveler
    stays within 15–85% of each viewport axis while free and 10–90% at clamped
    room edges.
  - Guard: camera code never changes Traveler position, input vectors, facing,
    target score, or attack direction; there is no user zoom/rotation.
- [x] **2.4 Split direction state in `Traveler3D`.**
  - As-is: one `facing` vector serves every concern.
  - To-be: sample `move_direction`, persist normalized planar `combat_facing`,
    and cache `resolved_attack_direction` per accepted attack.
  - Accept: movement updates facing, idle preserves it, dash fallback uses it,
    and attack direction remains immutable after startup.
  - Guard: no gravity, free camera, root-motion ownership, or animation-owned
    damage enters the controller.
- [x] **2.5 Emit presentation events instead of creating UI meshes in player code.**
  - As-is: `Traveler3D` rotates its own Visual and emits only text traces.
  - To-be: emit facing changes and short target-feedback events; keep Visual
    rotation authoritative in the player owner.
  - Accept: the world-feedback component can be removed without changing
    movement, target choice, or damage behavior.
  - Guard: UI scripts do not choose targets or mutate attack direction.
- [x] **2.6 Build the flat world-space feedback component.**
  - As-is: no persistent front cue exists.
  - To-be: add the exact ring, notch, target ring, colors, heights, and durations
    defined above using unshaded Godot meshes.
  - Accept: the front notch remains readable against floor and cover at all
    three capture sizes; target feedback never outlives 0.35 seconds.
  - Guard: no direction text, large arrow, aim line, texture, or extra HUD panel
    is introduced.

**Batch acceptance:** walking from room center toward all four boundaries reveals
different room regions without ever showing the complete map; an observer can
see the Traveler head/torso and identify attack-facing direction at center,
behind both cover blocks, and along the south/east cutaway walls.

**Batch guard:** the camera remains fixed-angle and collision-owned, projectiles
still stop on both cover types, and hiding `CombatDirectionFeedback` changes
presentation only; headless movement and damage outcomes remain identical.

### Phase 3: Add bounded attack-time assistance

**Goal:** Shift and Z attacks select predictable visible targets while preserving
straight fallback and cover truth.

Source owners touched: new
`scripts/player/targeting/targeting_assist_3d.gd`,
`scripts/player/traveler_3d.gd`, `scripts/combat/damageable_dummy_3d.gd`, new
`scenes/testbeds/isometric_combat/TargetDummy3D.tscn`, and
`scenes/testbeds/isometric_combat/CombatSandbox3D.tscn`.

- [x] **3.1 Implement the reusable targeting component and typed result.**
  - As-is: attacks never enumerate candidates.
  - To-be: filter the target contract, apply exact profile angles/ranges, require
    line of sight, calculate the locked score, and maintain per-family 0.45-second
    stickiness.
  - Accept: the same arrangement always returns the same target and normalized
    planar direction; no candidate returns an unassisted intended direction.
  - Guard: the component neither moves the Traveler nor applies damage.
- [x] **3.2 Apply one resolved direction at each attack boundary.**
  - As-is: melee and projectile read mutable `facing` directly.
  - To-be: Shift melee resolves before startup and uses the cached vector for its
    hit query; Z ranged resolves once and passes the cached vector to the
    projectile.
  - Accept: movement after input cannot curve either attack; fallback behavior
    exactly matches intended direction.
  - Guard: ordinary projectiles stay non-homing and World-blocked.
- [x] **3.3 Give proof targets the explicit target contract.**
  - As-is: one inline dummy exposes only `receive_hit()`.
  - To-be: extract one reusable target-dummy scene, add `TargetPoint`, group
    membership, and targetable health/reset state, then instantiate three
    authored arrangements for near, ranged, and cover cases.
  - Accept: dead/resetting targets are skipped and become eligible only after
    reset; the covered target is never selected.
  - Guard: target fixtures do not chase, attack, navigate, or establish a future
    enemy-AI architecture.
- [x] **3.4 Connect targeting feedback without exposing hidden candidates.**
  - As-is: attack traces name only the action.
  - To-be: assisted results show the chosen target ring for 0.35 seconds;
    fallback, invalidated, and occluded results show none.
  - Accept: capture and automated visibility state agree with the selected
    target.
  - Guard: no persistent reticle or off-screen marker remains after expiry.

**Batch acceptance:** in the authored target arrangement, close melee capture,
narrow ranged capture, target stickiness, straight fallback, and cover rejection
are each reproducible with the accepted keys.

**Batch guard:** no attack turns to a rear target, crosses solid cover, homes
after launch, or changes movement direction outside attack startup.

### Phase 4: Prove the built interaction

**Goal:** automated and rendered evidence demonstrate the same contract in the
editor runtime and exported Web build.

Source owners touched: `tools/validation/validate_movement_and_actions.gd`,
`tools/validation/capture_movement_check.gd`, generated ignored
`build/validation/*`, and generated ignored `build/web/*`.

- [x] **4.1 Extend deterministic headless cases.**
  - As-is: validation covers old keys and one forward target.
  - To-be: add all exact cases listed in Test Plan below.
  - Accept: the validator exits 0 and names input, arena extents, camera follow,
    facing, melee assist, ranged assist, occlusion, stickiness, fallback, guard,
    and cover in its PASS line.
  - Guard: test setup restores positions, health, input state, and cached targets
    between cases.
- [x] **4.2 Capture the reachable visual states.**
  - As-is: ready, Shift guard, and pause captures exist.
  - To-be: ready at three sizes plus 1280x720 moving-facing, Shift melee assist,
    Z ranged assist, X guard, south/east boundary visibility, north/west boundary
    visibility, and pause captures.
  - Accept: no frame shows all four room corners; no wall or cover hides the
    Traveler head/torso; no marker clips, z-fights, disappears under the
    Traveler, or reads as an enemy warning; control text fits every viewport.
  - Guard: generated evidence stays under ignored build paths.
- [x] **4.3 Export, serve through the managed lane, and perform a two-minute pass.**
  - As-is: Web export and fastrun route already exist.
  - To-be: export current code, use the fastrun-manager `codex` lane, and test the
    accepted keyboard sequence in the built artifact.
  - Accept: ten rapid Shift attacks, repeated Z shots, held X guard, diagonal
    movement, camera traversal to all boundaries, target changes, cover,
    pause/resume, and reset remain responsive.
  - Guard: do not invent a port or run an ad-hoc server under `D:\npjt`.
- [x] **4.4 Close documentation only after behavior passes.**
  - As-is: this plan remains active.
  - To-be: record final commands/evidence, mark tasks complete, and set this plan
    to `done` only after all gates pass.
  - Accept: canonical spec and implementation agree and no material open
    question remains.
  - Guard: do not promote tuning values into root `AGENTS.md`; they belong in
    the product spec or implementation.

**Batch acceptance:** a fresh built Web run reveals different arena regions as
the Traveler moves, preserves the character silhouette at foreground edges, and
makes the chosen target and attack direction predictable without debug text.

**Batch guard:** no stale old-binding text or hidden alias survives anywhere in
the active product, runtime, HUD, capture, or validation surfaces.

## Test Plan / Validation Cadence

### Inner-loop commands

1. `./tools/godot.ps1 --headless --path . --editor --quit`
2. `./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_movement_and_actions.gd`
3. `git diff --check`

Run the headless validator after each phase. Rerun it after a failure only after
the responsible input, targeting, scene, or test setup changes.

### Exact automated cases

- InputMap contains `Shift→melee`, `Z→ranged`, and `X→guard`; it does not contain
  `Z→melee`, `X→ranged`, or `Shift→guard`.
- Each arrow moves on the ground plane; diagonal distance remains within 10% of
  cardinal distance.
- The floor collision X/Z size is exactly 19.8 m, perimeter X/Z positions and
  dimensions match the locked 1.10 scale, and all fixtures remain inside legal
  walkable bounds after reset.
- Camera orthographic size is 15.5, local offset and orientation remain fixed,
  the rig follows only Traveler X/Z, and its center never exceeds ±3.5 m.
- After moving at least 4.0 m and then standing for one second, camera-center
  error is at most 0.15 m from the clamped follow target.
- At 1280×720, projecting the four floor corners proves that at least one corner
  is outside the viewport in every tested camera position; the full map never
  fits in one frame.
- At center/free-follow fixtures, the Traveler stays within 15–85% of viewport
  width and height; at all four clamped boundary fixtures it stays within
  10–90%.
- `RoomLarge` scaled visual height is at most 1.28 m, boundary collision height
  is 1.40 m, and both cover visuals and collision share their locked heights.
- Rightward input updates `combat_facing` and front-notch direction; releasing
  input preserves both.
- Shift melee damages one valid front target exactly once for the existing 20
  damage and does not damage an invalid rear or covered target.
- A candidate at 70° and `1.50 m` is eligible under the close melee cone; the
  same angle at `2.00 m` is ineligible under the normal melee cone.
- Z ranged selects a visible target at 20° and rejects one at 30° under the
  50° full cone.
- When two ranged targets qualify, the locked score selects deterministically;
  a second Z press inside 0.45 seconds retains the valid first target.
- Reversing intended direction, killing, occluding, or moving the sticky target
  out of profile invalidates it immediately.
- With no candidate, Shift hit geometry and Z projectile direction match the
  intended vector with dot product at least `0.999`.
- Movement received after attack start does not change cached melee direction or
  projectile direction.
- Held X reveals the shield, reduces 20 damage to 7, slows movement below 70% of
  normal, and suppresses Shift, Z, and Space.
- Accepted Space dash suppresses same-frame Shift and Z.
- Ordinary projectiles still terminate on solid cover and do not damage the
  target behind it.
- C potion, pulse damage, Esc pause/resume, and R reset retain their current
  contracts.

### Batch and final gates

1. `./tools/godot.ps1 --headless --path . --import`
2. `./tools/godot.ps1 --headless --path . --script res://tools/validation/inspect_kenney_3d_assets.gd`
3. `./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_movement_and_actions.gd`
4. `./tools/godot.ps1 --path . --script res://tools/validation/capture_movement_check.gd`
5. Inspect 960x540, 1280x720, and 1920x1080 ready captures plus the seven
   1280x720 interaction/edge-state captures.
6. `./tools/export_web.ps1` and verify `build/web/index.html`, `index.js`,
   `index.pck`, and `index.wasm`.
7. Before serving, load `$npjt-port-guard`, resolve this project's
   fastrun-manager `codex` lane, and use the manager-reported command and port.
   The exact port is state-owned by the manager and must not be hard-coded.
8. Perform the two-minute built-artifact keyboard pass from Phase 4.3.
9. `git diff --check`, targeted Markdown-link validation, lifecycle validation,
   and task-owned staging inspection.

## Rollback / Safety

- Make one scoped commit per completed phase or one combined commit only when all
  phases land in the same uninterrupted pass. Never include pre-existing `.import`
  modifications.
- If the arena/camera portion of Phase 2 fails, restore the prior scene scales
  and fixed camera together; do not leave expanded collision under a fixed
  overview or lowered visuals over stale collision.
- If Phase 2 fails, remove only the new feedback component and retain the accepted
  input mapping after the arena/camera pair is restored coherently.
- If Phase 3 fails, restore straight intended-direction attacks while retaining
  split direction state and visible facing; do not restore stale key mappings.
- Commits `c18fd3d` and `6cbf491` remain historical recovery points. Do not use a
  hard reset or revert unrelated work.
- Generated captures and Web output remain under ignored `build/` paths.

## Predetermined Error Handling and Contingencies

| Trigger | Required response | Limit / escalation point |
| --- | --- | --- |
| Windows or the host intercepts rapid Shift presses | Verify with the built artifact and record the exact OS behavior; keep the code binding unchanged. | If ten rapid presses cannot reach Godot reliably, stop and request a new owner binding; do not silently remap. |
| The expanded room still fits completely in a tested frame | Reduce orthographic size once from 15.5 to 14.5 and rerun camera/capture gates. | Do not enlarge the room again or change the fixed angle during this plan; escalate if all four corners still fit. |
| Exterior darkness reaches the central 70% safe frame near a boundary | Tighten both camera-center clamps once from ±3.5 m to ±3.0 m and rerun all edge captures. | Do not zoom out or add decorative filler solely to hide the void; escalate if the safe frame still fails. |
| A cutaway wall covers the Traveler head or torso in an edge capture | Reduce `RoomLarge` Y scale once from 0.30 to 0.24 and boundary collision height from 1.40 m to 1.10 m, preserving X/Z. | Do not add transparency or edit the GLB; escalate if the lower cutaway still obscures the silhouette. |
| Camera lag exceeds 0.15 m after one stationary second | Verify target/clamp math, then increase follow speed once from 8.0 to 10.0. | Do not snap the camera every frame or move camera logic into player code. |
| A target is geometrically eligible but World is the first ray hit | Treat it as occluded and use the next valid candidate or fallback. | Never bypass line of sight or change the collision mask to make the test pass. |
| `TargetPoint` is missing or `is_targetable()` is absent | Exclude the node and emit one editor/debug warning per node instance. | Fix the fixture/owner contract; do not add position fallbacks. |
| Facing or target mesh z-fights with the floor | Raise both indicators in `0.01 m` increments, keeping facing at or below `0.08 m` and target at or below `0.09 m`. | If still unreadable, stop visual completion; do not introduce a Decal or raster asset silently. |
| Sticky target becomes invalid during feedback | Clear it immediately, hide its marker, and reacquire only on the next attack input. | Do not retarget an attack already in startup/active state. |
| A test target resets while cached | `is_targetable()` remains false until reset completes, then it can be acquired by a later attack. | Never mutate dummy reset timing from targeting code. |
| Headless behavior passes but capture/built behavior differs | Treat built behavior as the blocker, isolate the presentation or input-focus difference, and rerun only the affected capture/export gate after a concrete fix. | Do not waive built-artifact verification. |

## Risks

- Shift is an OS accessibility modifier and repeated melee presses can trigger or
  be intercepted by host Sticky Keys settings; the plan has an explicit stop
  rule rather than a hidden fallback binding.
- The primitive character can make the ground notch appear like final UI. It is
  explicitly a proof cue and can be reduced only after a production model makes
  front direction equally clear.
- Transparent ground meshes can sort poorly under GL Compatibility. Heights and
  alpha are bounded above; no renderer or asset change is authorized.
- Vertically scaling the combined room also compresses its decorative wall
  details. This is an explicit proof-only cutaway compromise because the GLB has
  no separate wall nodes.
- A following isometric camera can expose exterior darkness or make edge motion
  feel abrupt. Fixed center clamps, one follow speed, and edge captures bound
  that risk without adding camera controls.
- Lower cover must remain truthful projectile cover. Every visual-height change
  has a matching collision-height assertion.
- A large assist cone can feel like auto-play while a narrow cone can leave gaps
  between eight keyboard directions. The fixed profiles are chosen to cover the
  input sectors without admitting rear targets.
- Multi-target fixtures validate selection mechanics, not enemy combat feel.
  Enemy AI remains the next separate milestone after this plan completes.

## Execution Evidence

- Godot 4.7 import completed without script or resource errors.
- `inspect_kenney_3d_assets.gd` confirmed the selected room, corridor, gate, and
  stair GLBs still load with their expected mesh counts and bounds.
- `validate_movement_and_actions.gd` exits 0 after checking exact InputMap
  ownership, action precedence, all four camera clamp quadrants, incomplete-map
  framing at three viewport sizes, facing persistence, score tie-breaking,
  close/far cones, line of sight, sticky-target invalidation, committed attack
  direction, projectile cover, held guard, potion, pulse, pause, and reset.
- `capture_movement_check.gd` produced three ready-state sizes and seven
  1280×720 interaction/edge states. Render synchronization uses
  `RenderingServer.frame_post_draw`, and visual inspection confirmed the front
  notch, assisted target ring, guard shield, low cutaway walls, camera edges,
  control text, and pause overlay remain readable.
- `tools/export_web.ps1` produced all four required Web files. The built artifact
  was served at the fastrun-manager `codex` lane port `13029`; Chrome loaded one
  active Godot canvas with no warning/error logs, and built Shift melee displayed
  the Sword trace plus assisted-target marker after rapid Shift/Z/Space input.
- Browser control exposes tap input but not a sustained key-down primitive.
  Therefore held `X` and continuous edge traversal were proved by deterministic
  Godot InputEvents and native edge/guard captures, while the identical exported
  scene and action paths received built-Web smoke coverage. No runtime workaround
  or alternate binding was added for automation.
- `git diff --check` passed. The task added no package or external asset and did
  not stage or alter the pre-existing user-owned `.import` changes.

## Progress

- [x] Godot native 3D engine, camera, room, collision, movement, dash, guard,
  attacks, potion, pause, cover, and initial validation exist.
- [x] Public implementations were inspected and the owner selected the revised
  keyboard ownership and attack-time assistance direction.
- [x] Phase 1: replace the input and product contract.
- [x] Phase 2: enlarge the cutaway arena, follow the Traveler, and make facing
  visible and structurally separate.
- [x] Phase 3: add bounded attack-time assistance.
- [x] Phase 4: prove the built interaction and close documentation.

## Outcome

The combat proof now owns the accepted keyboard layout, a larger cutaway arena,
a fixed-angle following camera, explicit world-facing feedback, three reusable
target fixtures, and attack-time soft assistance. This plan has no remaining
implementation task. Enemy AI, production character animation, mouse/right-stick
aim, and broader encounter content remain separate future milestones.

## Completion Criteria

- [x] Shift performs only melee, Z performs only ranged, and held X performs
  only guard on keyboard; existing gamepad semantics remain intact.
- [x] The playable footprint is 10% larger on X/Z and no tested frame shows all
  four walkable-room corners.
- [x] The fixed-angle camera follows and clamps to the locked contract, keeps the
  Traveler in the safe frame, and does not influence gameplay vectors.
- [x] South/east walls and both cover types preserve the Traveler head/torso
  while their collision remains visually truthful and blocks projectiles.
- [x] Movement and idle facing are visible on the actor without a HUD arrow.
- [x] Melee and ranged assistance obey their locked cones, ranges, score,
  visibility, stickiness, commitment, and fallback contracts.
- [x] No target is selected through cover or behind the player's intended lane.
- [x] Target feedback is short-lived and absent for fallback attacks.
- [x] All regression guards, exact automated cases, captures, Web export, and the
  built-artifact keyboard pass succeed.
- [x] Active product documentation, HUD text, runtime bindings, and tests agree.
- [x] No external dependency, unowned `.import` change, placeholder decision,
  duplicate targeting owner, or stale old-binding alias remains.

## Stop Conditions

Complete when all completion criteria pass and this plan is marked `done`.

Escalate only when the host cannot reliably deliver Shift, the arena remains a
complete overview or foreground geometry still hides the Traveler after its one
predetermined contingency, a required target is not representable under the
explicit target contract, or the owner requests a different binding, camera,
aim method, or persistent lock mode.

Do not stop merely because primitive art is unfinished, a target requires normal
parameter debugging, or one automated/capture gate needs a task-scoped fix.

## Open Questions

No material design or technical question remains inside this plan. Mouse/right-
stick aim, hard lock, production character animation, combo expansion, and real
enemy AI require separate owner-approved scope and must not be decided during
execution. The arena uses the locked cutaway and following-camera contract; its
executor does not choose between wall fading, wall removal, or alternate camera
systems.

## Decision Notes

- Accepted: `Shift` melee, `Z` ranged, held `X` guard for the keyboard proof.
- Accepted: current movement input, then persistent combat facing, defines attack
  intent; assistance can redirect only at attack startup within the locked
  visible cone.
- Accepted: world-space ring/notch plus short target ring; no HUD direction arrow
  or persistent reticle.
- Accepted: 10% larger X/Z arena, vertically compressed physical cutaway walls,
  low truthful cover, and a size-15.5 bounded following orthographic camera.
- Rejected: a complete-room overview, selective wall-node removal from the
  single-mesh GLB, and occlusion fade/X-ray presentation.
- Rejected: continuous nearest-target rotation and hard lock in this milestone.
- Preserved: Godot 4.7 native 3D, fixed orthographic orientation, explicit
  collision, current gamepad semantic actions, and flat-color drowned-foundry
  presentation.

## Handoff

```text
State: Completed on 2026-07-17.

Read first: AGENTS.md, docs/product/isometric_action_rpg_product_brief.md, and
this plan's Locked Decisions and Execution Evidence.

Regression commands: tools/validation/validate_movement_and_actions.gd,
tools/validation/capture_movement_check.gd, tools/export_web.ps1, and the managed
fastrun-manager codex lane.

Do not reopen this plan for enemy AI, production animation, mouse/right-stick
aim, or encounter content; create a successor spec or plan for that scope.
```
