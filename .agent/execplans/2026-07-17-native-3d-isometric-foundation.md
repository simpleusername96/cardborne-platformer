---
type: plan
status: active
owner: BK
created: 2026-07-17
last_reviewed: 2026-07-17
topic: Cardborne native 3D movement, facing, combat input, and soft targeting
scope: Playable 3D combat room through a predictable keyboard targeting proof
source: Owner control decision after reviewing the native 3D proof and public targeting implementations
related:
  - ../Prompt.md
  - ../../docs/product/isometric_action_rpg_product_brief.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../docs/research/third_party_adoption_ledger.md
---

# Cardborne Native 3D Facing and Targeting Refinement

The native Godot 4.7 room, movement, damage fixtures, and Web route already
exist. This plan keeps that foundation and completes four executable phases:
the revised keyboard contract, explicit world-space facing feedback, bounded
attack-time soft targeting, and production-style validation. The resulting
proof must let a keyboard player predict where both melee and ranged attacks
will go without adding persistent lock-on or trajectory clutter.

## Purpose

- **Objective:** make character facing and attack selection legible with
  arrow-key movement, `Shift` melee, `Z` ranged, and held `X` guard.
- **Final artifact:** the existing `CombatSandbox3D` with deterministic attack
  direction, short-lived targeting feedback, multiple target fixtures, and
  automated plus rendered evidence.
- **Completion state:** keyboard and existing gamepad bindings execute the same
  semantic actions; movement, facing, assistance, guard precedence, cover, and
  fallback behavior pass the checks in this plan.

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

## Pre-plan Evidence Already Verified

| Source or path | Verified fact | Decision affected | Freshness or recheck boundary |
| --- | --- | --- | --- |
| Owner decision, 2026-07-17 | Keyboard actions are `Shift` melee, `Z` ranged, and `X` guard. | Replaces the current keyboard action ownership. | Recheck only if the owner changes the binding. |
| `scripts/main/pivot_root.gd::_register_input_map()` at commit `6cbf491` | Current runtime registers `Z` melee, `X` ranged, and `Shift` guard; gamepad uses RB, RT, and LB respectively. | Change keyboard events without renaming semantic actions or changing gamepad ownership. | Recheck if input registration moves out of `PivotRoot`. |
| `scripts/player/traveler_3d.gd` at commit `6cbf491` | One `facing` vector owns visual rotation, melee query placement, projectile direction, and dash fallback. It changes only on movement. | Split movement intent, persistent combat facing, and cached attack direction. | Recheck if the player controller is replaced. |
| `scenes/testbeds/isometric_combat/CombatSandbox3D.tscn` at commit `6cbf491` | Traveler is a capsule and sphere with one sword cue; the room contains one target and solid cover. | Add low-noise direction/target markers and a multi-target fixture without new art dependencies. | Recheck when a production character replaces the primitive. |
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

## Current State

Already true at commit `6cbf491`:

- Godot 4.7 native 3D, fixed orthographic camera, camera-relative normalized
  movement, dash, guard, melee, ranged projectile, potion, pause, cover, and a
  timed damage fixture run from one scene.
- Ordinary ranged projectiles collide with World and Enemy and terminate on
  solid cover.
- Existing validation sends real `InputEventKey` events and captures the proof
  at 960x540, 1280x720, and 1920x1080.
- The native 3D foundation and functional keyboard baseline are recoverable from
  commits `c18fd3d` and `6cbf491`.

Remaining implementation:

- replace the stale keyboard mapping in runtime, HUD, spec, captures, and tests;
- split movement, facing, and attack direction ownership;
- add reusable targeting and world-feedback components;
- give the dummy and test fixtures the target contract;
- add deterministic multi-target, occlusion, stickiness, and fallback checks;
- export and inspect the built Web proof.

## Scope / Non-scope

In scope:

- revised keyboard bindings and matching on-screen control text;
- explicit facing marker and short-lived target marker;
- attack-time melee and ranged target assistance with line of sight;
- three reusable target fixtures in the existing authored room;
- exact automated, rendered, and built-artifact validation;
- canonical product-brief correction for this accepted behavior.

Out of scope:

- mouse aim, right-stick aim, hard lock, target cycling, camera steering, or
  strafing mode;
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
- changing combat damage, cooldown, guard mitigation, or movement baselines.

## Architecture and Ownership

| Concern | Final owner | Interface or invariant | Existing owner to reuse or retire |
| --- | --- | --- | --- |
| Input registration | `scripts/main/pivot_root.gd::_register_input_map()` | Semantic action names remain stable; each keyboard action has exactly its accepted physical key. | Reuse `PivotRoot`; retire the three old keyboard events. |
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
| Facing | One vector silently follows last movement. | Persistent combat facing drives body and foot marker. | All eight movement sectors rotate both cues; idle retains the last sector. | No HUD arrow or independent movement marker appears. |
| Melee direction | Hit sphere is placed along stale facing. | Direction resolves and caches at melee startup. | Near/front valid target is selected; rear/occluded target is ignored. | Movement during the swing cannot bend its hit query. |
| Ranged direction | Projectile fires along stale facing. | Direction resolves once within a narrow visible cone. | Valid aligned target is selected; absent target fires straight. | Projectile cannot home or pass through World. |
| Multiple targets | One stationary dummy. | Three reusable fixtures cover competing and occluded targets. | Score and stickiness choose deterministically. | No fixture behavior leaks into production enemy ownership. |
| Feedback | Sword and temporary text are the only directional cues. | Ground front notch is persistent; target ring lasts 0.35 seconds. | Captures show both at all supported viewports without occlusion or clipping. | No marker is visible for fallback or through cover. |

## Milestones

1. Replace the keyboard and canonical product contract without changing gamepad
   semantics or unrelated combat values.
2. Separate movement, facing, and committed attack direction, then render the
   accepted world-space feedback.
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

- [ ] **1.1 Replace only the keyboard events for semantic combat actions.**
  - As-is: `melee=Z`, `ranged=X`, `guard=Shift`.
  - To-be: `melee=Shift`, `ranged=Z`, `guard=X`; keep gamepad events and all
    other keyboard events unchanged.
  - Accept: InputMap contains each accepted physical key and real events reach
    the matching action.
  - Guard: assert the three old key/action pairs are absent rather than retained
    as hidden aliases.
- [ ] **1.2 Correct every visible and canonical statement of the controls.**
  - As-is: HUD, active product brief, capture setup, and assertions state the
    old layout.
  - To-be: all state the new layout; guard capture holds X.
  - Accept: `rg` finds no active `SHIFT GUARD`, `Z MELEE`, or `X RANGED` proof
    contract.
  - Guard: historical superseded documents remain historical and are not
    rewritten merely to erase context.
- [ ] **1.3 Lock action precedence in `Traveler3D`.**
  - As-is: processing order happens to make guard and dash win but has no direct
    regression assertion.
  - To-be: held X guard, then accepted dash, then melee, then ranged is the
    explicit same-frame order.
  - Accept: simultaneous-input tests produce one action and no damage/projectile
    side effect from suppressed actions.
  - Guard: potion and pause ownership remain unchanged.

**Batch acceptance:** launch once and confirm arrows, Space, Shift, Z, X, C, Esc,
and the existing gamepad semantic actions all respond.

**Batch guard:** movement, dash invulnerability, projectile cover, potion, pulse,
and pause assertions still pass before Phase 2.

### Phase 2: Make facing visible and structurally separate

**Goal:** movement and attack facing are inspectable before assistance is added.

Source owners touched: `scripts/player/traveler_3d.gd`, new
`scripts/ui/world/combat_direction_feedback_3d.gd`, and
`scenes/testbeds/isometric_combat/CombatSandbox3D.tscn`.

- [ ] **2.1 Split direction state in `Traveler3D`.**
  - As-is: one `facing` vector serves every concern.
  - To-be: sample `move_direction`, persist normalized planar `combat_facing`,
    and cache `resolved_attack_direction` per accepted attack.
  - Accept: movement updates facing, idle preserves it, dash fallback uses it,
    and attack direction remains immutable after startup.
  - Guard: no gravity, free camera, root-motion ownership, or animation-owned
    damage enters the controller.
- [ ] **2.2 Emit presentation events instead of creating UI meshes in player code.**
  - As-is: `Traveler3D` rotates its own Visual and emits only text traces.
  - To-be: emit facing changes and short target-feedback events; keep Visual
    rotation authoritative in the player owner.
  - Accept: the world-feedback component can be removed without changing
    movement, target choice, or damage behavior.
  - Guard: UI scripts do not choose targets or mutate attack direction.
- [ ] **2.3 Build the flat world-space feedback component.**
  - As-is: no persistent front cue exists.
  - To-be: add the exact ring, notch, target ring, colors, heights, and durations
    defined above using unshaded Godot meshes.
  - Accept: the front notch remains readable against floor and cover at all
    three capture sizes; target feedback never outlives 0.35 seconds.
  - Guard: no direction text, large arrow, aim line, texture, or extra HUD panel
    is introduced.

**Batch acceptance:** an observer can identify the Traveler's attack-facing
direction while moving and while idle without reading the control hint.

**Batch guard:** hiding `CombatDirectionFeedback` changes presentation only;
headless movement and damage outcomes remain identical.

### Phase 3: Add bounded attack-time assistance

**Goal:** Shift and Z attacks select predictable visible targets while preserving
straight fallback and cover truth.

Source owners touched: new
`scripts/player/targeting/targeting_assist_3d.gd`,
`scripts/player/traveler_3d.gd`, `scripts/combat/damageable_dummy_3d.gd`, new
`scenes/testbeds/isometric_combat/TargetDummy3D.tscn`, and
`scenes/testbeds/isometric_combat/CombatSandbox3D.tscn`.

- [ ] **3.1 Implement the reusable targeting component and typed result.**
  - As-is: attacks never enumerate candidates.
  - To-be: filter the target contract, apply exact profile angles/ranges, require
    line of sight, calculate the locked score, and maintain per-family 0.45-second
    stickiness.
  - Accept: the same arrangement always returns the same target and normalized
    planar direction; no candidate returns an unassisted intended direction.
  - Guard: the component neither moves the Traveler nor applies damage.
- [ ] **3.2 Apply one resolved direction at each attack boundary.**
  - As-is: melee and projectile read mutable `facing` directly.
  - To-be: Shift melee resolves before startup and uses the cached vector for its
    hit query; Z ranged resolves once and passes the cached vector to the
    projectile.
  - Accept: movement after input cannot curve either attack; fallback behavior
    exactly matches intended direction.
  - Guard: ordinary projectiles stay non-homing and World-blocked.
- [ ] **3.3 Give proof targets the explicit target contract.**
  - As-is: one inline dummy exposes only `receive_hit()`.
  - To-be: extract one reusable target-dummy scene, add `TargetPoint`, group
    membership, and targetable health/reset state, then instantiate three
    authored arrangements for near, ranged, and cover cases.
  - Accept: dead/resetting targets are skipped and become eligible only after
    reset; the covered target is never selected.
  - Guard: target fixtures do not chase, attack, navigate, or establish a future
    enemy-AI architecture.
- [ ] **3.4 Connect targeting feedback without exposing hidden candidates.**
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

- [ ] **4.1 Extend deterministic headless cases.**
  - As-is: validation covers old keys and one forward target.
  - To-be: add all exact cases listed in Test Plan below.
  - Accept: the validator exits 0 and names input, facing, melee assist, ranged
    assist, occlusion, stickiness, fallback, guard, and cover in its PASS line.
  - Guard: test setup restores positions, health, input state, and cached targets
    between cases.
- [ ] **4.2 Capture the reachable visual states.**
  - As-is: ready, Shift guard, and pause captures exist.
  - To-be: ready at three sizes plus 1280x720 moving-facing, Shift melee assist,
    Z ranged assist, X guard, and pause captures.
  - Accept: no marker clips, z-fights, disappears under the Traveler, or reads as
    an enemy warning; control text fits every viewport.
  - Guard: generated evidence stays under ignored build paths.
- [ ] **4.3 Export, serve through the managed lane, and perform a two-minute pass.**
  - As-is: Web export and fastrun route already exist.
  - To-be: export current code, use the fastrun-manager `codex` lane, and test the
    accepted keyboard sequence in the built artifact.
  - Accept: ten rapid Shift attacks, repeated Z shots, held X guard, diagonal
    movement, target changes, cover, pause/resume, and reset remain responsive.
  - Guard: do not invent a port or run an ad-hoc server under `D:\npjt`.
- [ ] **4.4 Close documentation only after behavior passes.**
  - As-is: this plan remains active.
  - To-be: record final commands/evidence, mark tasks complete, and set this plan
    to `done` only after all gates pass.
  - Accept: canonical spec and implementation agree and no material open
    question remains.
  - Guard: do not promote tuning values into root `AGENTS.md`; they belong in
    the product spec or implementation.

**Batch acceptance:** a fresh built Web run makes the chosen target and attack
direction predictable without relying on debug text.

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
5. Inspect 960x540, 1280x720, and 1920x1080 ready captures plus the five
   1280x720 interaction-state captures.
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
- If Phase 2 fails, remove only the new feedback component and retain the accepted
  input mapping.
- If Phase 3 fails, restore straight intended-direction attacks while retaining
  split direction state and visible facing; do not restore stale key mappings.
- Commits `c18fd3d` and `6cbf491` remain historical recovery points. Do not use a
  hard reset or revert unrelated work.
- Generated captures and Web output remain under ignored `build/` paths.

## Predetermined Error Handling and Contingencies

| Trigger | Required response | Limit / escalation point |
| --- | --- | --- |
| Windows or the host intercepts rapid Shift presses | Verify with the built artifact and record the exact OS behavior; keep the code binding unchanged. | If ten rapid presses cannot reach Godot reliably, stop and request a new owner binding; do not silently remap. |
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
- A large assist cone can feel like auto-play while a narrow cone can leave gaps
  between eight keyboard directions. The fixed profiles are chosen to cover the
  input sectors without admitting rear targets.
- Multi-target fixtures validate selection mechanics, not enemy combat feel.
  Enemy AI remains the next separate milestone after this plan completes.

## Progress

- [x] Godot native 3D engine, camera, room, collision, movement, dash, guard,
  attacks, potion, pause, cover, and initial validation exist.
- [x] Public implementations were inspected and the owner selected the revised
  keyboard ownership and attack-time assistance direction.
- [ ] Phase 1: replace the input and product contract.
- [ ] Phase 2: make facing visible and structurally separate.
- [ ] Phase 3: add bounded attack-time assistance.
- [ ] Phase 4: prove the built interaction and close documentation.

## Next Steps

1. Execute Phase 1 and run the complete current validator before adding new
   targeting behavior.
2. Execute Phase 2 and approve its three-size direction-marker captures as the
   presentation baseline.
3. Execute Phase 3 against the authored three-target fixture.
4. Execute Phase 4, export Web, use the managed fastrun lane, and mark the plan
   done only after every completion criterion passes.

## Completion Criteria

- [ ] Shift performs only melee, Z performs only ranged, and held X performs
  only guard on keyboard; existing gamepad semantics remain intact.
- [ ] Movement and idle facing are visible on the actor without a HUD arrow.
- [ ] Melee and ranged assistance obey their locked cones, ranges, score,
  visibility, stickiness, commitment, and fallback contracts.
- [ ] No target is selected through cover or behind the player's intended lane.
- [ ] Target feedback is short-lived and absent for fallback attacks.
- [ ] All regression guards, exact automated cases, captures, Web export, and the
  built-artifact keyboard pass succeed.
- [ ] Active product documentation, HUD text, runtime bindings, and tests agree.
- [ ] No external dependency, unowned `.import` change, placeholder decision,
  duplicate targeting owner, or stale old-binding alias remains.

## Stop Conditions

Complete when all completion criteria pass and this plan is marked `done`.

Escalate only when the host cannot reliably deliver Shift, a required target is
not representable under the explicit target contract, or the owner requests a
different binding, aim method, or persistent lock mode.

Do not stop merely because primitive art is unfinished, a target requires normal
parameter debugging, or one automated/capture gate needs a task-scoped fix.

## Open Questions

No material design or technical question remains inside this plan. Mouse/right-
stick aim, hard lock, production character animation, combo expansion, and real
enemy AI require separate owner-approved scope and must not be decided during
execution.

## Decision Notes

- Accepted: `Shift` melee, `Z` ranged, held `X` guard for the keyboard proof.
- Accepted: current movement input, then persistent combat facing, defines attack
  intent; assistance can redirect only at attack startup within the locked
  visible cone.
- Accepted: world-space ring/notch plus short target ring; no HUD direction arrow
  or persistent reticle.
- Rejected: continuous nearest-target rotation and hard lock in this milestone.
- Preserved: Godot 4.7 native 3D, fixed orthographic camera, explicit collision,
  current gamepad semantic actions, and flat-color drowned-foundry presentation.

## Handoff

```text
Goal: Land predictable keyboard facing and attack-time targeting in the native
3D proof.

Read first: AGENTS.md, docs/product/isometric_action_rpg_product_brief.md, and
this plan.

Execute exactly: Phase 1 input/spec contract, Phase 2 direction state/feedback,
Phase 3 targeting/fixtures, then Phase 4 validation and Web proof.

Validate with: tools/validation/validate_movement_and_actions.gd,
tools/validation/capture_movement_check.gd, tools/export_web.ps1, and the managed
fastrun-manager codex lane.

Stop when: every completion criterion passes, active docs agree, task-owned
changes are committed, and this plan is marked done.
```
