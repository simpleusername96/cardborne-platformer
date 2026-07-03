---
type: plan
status: active
created: 2026-07-02
source: User request on 2026-07-02 to distinguish immediate vs later features
scope: Motion test bed feature priority boundary
related:
  - ../MOTION_TEST_BED_MVP_PLAN.md
  - ../MOTION_TEST_BED_SPEC.md
  - ./00_foundation_contracts.md
  - ./01_authored_lanes.md
  - ./02_combat_damage.md
  - ./03_interaction_input_ui.md
  - ./04_generated_landscape.md
  - ./05_qa_and_handoff.md
---

# Feature Priority Matrix

## Purpose

Separate the motion test bed features into what should be implemented in the immediate testbed pass and what can wait. The immediate pass should prove player movement, camera-followed traversal, combat/damage contracts, interaction, and seed replay with the smallest usable implementation.

## Progress

Already decided:

- [x] The testbed is a miniature game, not a static sandbox.
- [x] The default gameplay camera must not show the whole playable map at once.
- [x] Generated landscape must be segment-template based, not arbitrary tile noise.
- [x] Placeholder shapes and simple sprites are acceptable.

Resolved in the 2026-07-02 immediate implementation pass:

- [x] Climb traversal uses `climb_up`, `climb_down`, and `climb_cancel`, currently bound to W/Up, S/Down, and C.
- [x] Double jump is a debug testbed ability flag for this pass.
- [x] Keyboard remapping persistence is deferred; the settings popup lists actual `InputMap` bindings and says remap is deferred.

Resolved in the 2026-07-03 reconciliation pass:

- [x] Checkpoint and fall/death respawn recovery are implemented for the motion testbed.
- [x] Final clear is gated by required testbed checks instead of the exit portal alone.
- [x] The HUD route status reports compact validation progress and missing checks.

Resolved in the 2026-07-03 dungeon/combat identity pass:

- [x] The default keyboard attack binding is `F`, and HUD/settings read it from `InputMap`.
- [x] Warrior, Archer, and Assassin profiles now expose simple attack identity through attack label, active time, range, hitbox height, offset, and knockback values.
- [x] The combat lane includes Walker, Charger, and Shooter baselines using shared enemy/damage contracts.
- [x] Defeated enemies can auto-reset so the combat lane can be retested without regenerating the route.
- [x] The motion route has visual dungeon framing around ceiling, side, and lower empty space so the map no longer reads as floating platforms in a void.

Resolved in the 2026-07-03 player attack motion pass:

- [x] Warrior uses a visible heavy up/down melee swing during active frames.
- [x] Assassin uses a visible quick slash during active frames.
- [x] Archer fires a real arrow projectile through the shared player `Hitbox`/`DamageInfo` path.
- [x] Attack motion style and projectile values are profile data, not stage-local hard-coding.

## Tasks

### Priority Rules

- **Now** means implement in the next testbed pass because it proves a shared contract or prevents false confidence.
- **Later** means defer until the core route is playable, because it is polish, content breadth, persistence, or a deeper production system.
- **Now, simplified** means implement the smallest visible version and leave depth for later.
- **Explicitly deferred** means show the ability or feature as unavailable in-game so testers do not think it is broken.

### Feature Matrix

| Feature | Now | Later | Reason |
| --- | --- | --- | --- |
| Godot launch/run baseline | Confirm Godot launch, fastrun command, autoloads, no missing scripts. | Automated launch dashboard or broader CI. | Work should not start from an unknown runtime state. |
| Shared input actions | Keep one canonical action list and make HUD/settings read from it. | Full persistent keybinding profile and gamepad remap UI. | Input drift caused early confusion; visible controls are immediately valuable. |
| Movement metrics | Compute jump height, jump reach, dash reach, and route limits from active profile. | Perfect physics simulation of every edge case. | Map dimensions must stop being placed by eye. |
| Profile switching | Keep debug profile cycle or simple selector clearly labeled debug. | Character-select screen, separate character controllers, profile unlocks. | Three profiles are useful for calibration now; production flow can wait. |
| Basic movement | Tune/run/jump/variable jump/coyote/buffer/dash/crouch/fast fall/drop-through in authored lanes. | Wall-perfect feel polish, animation polish, advanced cancel rules. | These are the core controller proof. |
| Double jump / extra dash | Now, simplified as debug ability flags and optional route gates. | Card/skill unlock integration and balancing. | Needed to test optional route design without waiting for progression. |
| Rope or ladder climb | Now, simplified: climbable Area2D, vertical movement, mount/dismount/drop, safe recovery. | Final animation, stamina, combat while climbing, moving ropes, physics swing. | This is straightforward enough and validates vertical map language. |
| Wall traversal | Later for full version; now only explicit defer or minimal wall slide/jump if cheap after core lanes. | Wall climb, wall slide, wall jump tuning, wall-specific animation, stamina, wall attack interactions. | It changes player controller feel more deeply than rope climb. Do not block the first playable route on it. |
| Camera-followed map | Now: route larger than 1280x720, Camera2D follow, camera bounds, no default overview. | Cinematic camera zones, smoothing polish, room transitions, minimap. | User explicitly corrected this; a one-screen map is a false test. |
| Authored map lanes | Now: measured lanes, safe recovery, route gating, labels. | Final Stage01/02/03 production maps. | Authored lanes prove the rules before generation. |
| Combat attack readability | Now: visible melee swing/projectile, facing, hit confirm, cooldown/status feedback. | Full animation set, combos, charged attacks, cancel windows. | Combat cannot be validated if the hit timing or attack form is invisible. |
| Real enemy | Now: Walker, Charger, and Shooter baselines with health, contact damage or projectile damage, hit reaction, death/reset. | Elite variants, drops, final animation, and deeper AI tuning. | Enemy variety must still prove shared damage contracts before becoming content breadth. |
| Hazard/damage recovery | Now: one clear hazard, knockback, invulnerability, recovery path. | Multiple trap types, timing puzzles, crushing blocks. | Damage response is a high-risk core system. |
| Destructible obstacle | Now, simplified: breakable wall/crate/barrier with health, hit feedback, collision removal, route change/reset. | Multi-stage debris, loot tables, elemental damage, persistent destruction. | It proves attack can affect world traversal. |
| NPC/object interaction | Now: one non-exit interactable with prompt and visible result. | Full dialogue, shop, forge, healer, upgrade station flows. | Interaction must be proven separately from the exit portal. |
| HUD guide | Now: controls, profile, health, lane/objective, prompt, metrics, debug labels. | Final UI design, icons, animation, localization. | Testers need in-game guidance immediately. |
| Settings popup | Now: binding list from actual input map and clear remap-deferred message if needed. | Full persistent settings, gamepad rebinding, conflict-resolution polish. | A binding list is enough for the immediate pass; full remap can wait. |
| Generated landscape route plan | Now: deterministic route plan from seed/profile/mode, simple validation, route summary. | Full procedural region graph runtime with key/gate/shortcut mission graph. | Seed replay is part of the testbed, but full region gen is not. |
| Segment templates | Now: flat, jump, jump+dash, vertical, combat, hazard, interaction, exit, destructible, optional branch. | Large room library, biome variants, weighted difficulty curves. | Small templates are enough to test generation contracts. |
| Generated terrain assembly | Now, simplified: instantiate placeholder platforms, enemies, hazards, interactables, destructibles, exit. | Tile art, room transitions, streaming, decorative dressing. | Playable generation matters more than visual finish. |
| Generated climb segments | Later unless rope climb is already stable; otherwise explicit defer in generator profile. | Rope/wall segment library and ability-gated optional branches. | Generated traversal should not outrun stable authored traversal. |
| Generated miniature loop | Now: seed entry/random seed/regenerate/replay, clear/fail status. | Run rewards, card selection, shop/rest rooms, boss access. | Replayable seed route is the miniature-game proof. |
| Final clear gate | Now: testbed clear requires required authored checks and generated route completion unless debug skip is labeled. | Achievement-style scoring or analytics. | Clear must mean the testbed actually proved something. |
| QA matrix | Now: manual profile route, combat, interaction, camera, seed replay checks. | Automated gameplay test harness and broad regression suite. | Manual QA is enough for this MVP-ish testbed pass. |
| Final art/audio | Later. | Placeholder shapes only now. | Not needed for controller/map validation. |
| Boss, cards, shop/rest | Later. | Build after testbed contracts are trusted. | These are MVP content systems, not prerequisites for the testbed proof. |

### Immediate Implementation Boundary

The next implementation pass should include:

- [x] Runtime baseline check.
- [x] Movement metrics and ability flags.
- [x] Camera-followed authored route larger than one viewport.
- [x] Basic authored movement lanes.
- [x] Simplified rope/ladder climb if low-risk; otherwise visible deferral.
- [x] Debug double jump or extra dash route.
- [x] One real enemy.
- [x] One hazard.
- [x] One destructible obstacle.
- [x] One non-exit interactable.
- [x] Input binding list from actual `InputMap`.
- [x] Minimal generated route plan, assembly, seed replay, and clear/fail summary.
- [x] Final clear gate for required testbed checks and generated route completion.

### Deferred Boundary

The first implementation pass intentionally did not include these items. They remain later work unless the user explicitly promotes them:

- [ ] Full wall traversal polish if it destabilizes the controller.
- [ ] Full keybinding persistence.
- [ ] Full production procedural region graph.
- [ ] Stage01/Stage02/Stage03 production content.
- [ ] Card rewards, shop/rest, boss fight.
- [ ] Final animation, art, audio, localization.
- [ ] Full production enemy set beyond the Walker/Charger/Shooter baselines.

## Verification

- [x] Before implementation, confirm every current task belongs to **Now** or **Now, simplified**.
- [x] If a **Later** task becomes necessary, document why it became a blocker before implementing it.
- [x] End each implemented phase with the acceptance checks in the relevant phase doc.

## Risks

- Pulling wall traversal, full remapping, or full procedural generation into the immediate pass can stall the playable testbed.
- Deferring too much movement variety can make the generated map language too shallow.
- A feature marked **Later** must still be visibly deferred in-game when the player can encounter its lane.

## Next Steps

- [x] Use this matrix before opening `00_foundation_contracts.md`.
- [x] Keep the first implementation pass small enough to become playable.
- [x] Revisit this matrix after the first playable testbed run.
- [x] Use `05_qa_and_handoff.md` for the remaining manual QA matrix and production-readiness gaps.
