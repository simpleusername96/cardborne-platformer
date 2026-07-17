---
type: plan
status: active
owner: BK
created: 2026-07-17
last_reviewed: 2026-07-17
topic: Cardborne isometric action RPG pivot
scope: Empty reset baseline through one decision-complete five-to-eight-minute isometric combat proof
source: Owner pivot decision, repository state at 8124394, Godot 4.7 documentation, and inspected Supergiant development material
related:
  - ../Documentation.md
  - ../Prompt.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../docs/design/references/README.md
---

# Cardborne Isometric Action RPG Pivot — Execution Plan

Cardborne currently boots an empty Godot 4.7 scene. Five remaining implementation
phases produce one authored, five-to-eight-minute isometric action-RPG proof with
explicit melee/ranged controls, three room objectives, one card choice, Slime
King, retained visual identity, a Web build, and a recorded go/no-go outcome.

## Purpose

- **Objective:** determine through a playable build whether top-down isometric
  combat is a materially better foundation than the retired platformer.
- **Final artifact:** a deterministic start-to-result proof that can be replayed
  immediately with keyboard/mouse or gamepad.
- **Completion state:** all automated and rendered gates pass and the owner records
  `Go`, `Iterate`, or `No-go` against the continuous proof build.

## Why / Context

The retired implementation proved persistence, rewards, stages, UI, and release
flow, but it did not meet the owner's fun target. Porting its controller, ropes,
platform rooms, contextual attacks, and enemy trajectories would preserve the
wrong constraints. Commit `7cc069c` remains the read-only recovery boundary;
commit `8124394` is the clean isometric reset baseline.

The target is not a feature-by-feature Bastion or Hades clone. The applicable
lesson is to validate responsive movement, explicit attacks, readable enemy
pressure, and behavior-changing rewards in one short playable route before
rebuilding a broad economy or content catalog.

## Pre-plan Evidence Already Verified

| Source or path | Verified fact | Decision affected | Freshness or recheck boundary |
| --- | --- | --- | --- |
| Root `AGENTS.md`, `.agent/Prompt.md`, `.agent/Implement.md` | Godot 4.7 GDScript, 2D simulation, one ground plane, explicit intent, no external dependency, and combat-first delivery are active policy. | Engine, simulation model, dependency set, and work order. | Re-read before each phase; any policy edit supersedes this row. |
| Git `8124394`; `project.godot`; `scenes/main/PivotRoot.tscn` | Runtime, data, localization, and old gameplay scenes are gone; the project boots an empty `Node2D` with the retained Theme. | Build from a clean root instead of adapting old runtime. | Recheck `git status`, main scene, and project settings before Phase 1. |
| `art/ui/production/asset-manifest.json` | Stable retained IDs exist for Traveler, melee/ranged/shield/potion icons, three usable card images, Slime King, result art, and fallbacks. | Graybox UI can use retained assets without adding a package. Manifest disposition labels do not define new gameplay. | Revalidate IDs whenever the manifest changes. |
| `art/world/flooded_works/README.md`; `docs/design/UI_VISUAL_SYSTEM.md` | Flat raster color masses, no outlines, low texture noise, drowned foundry palette, separate gameplay props, and live borderless UI are accepted. | Art and UI contract. Side-view dimensions and collision are rejected as runtime truth. | Recheck before Phase 5 and every new production-asset batch. |
| Godot 4.7 runtime via `./tools/godot.ps1 --version` | `4.7.stable.official.5b4e0cb0f` is locally available; import and empty boot pass. | Pin the implementation to Godot 4.7 GDScript and GL Compatibility. | Rerun version/import checks before Phase 1 and final export. |
| [Godot CharacterBody2D](https://docs.godotengine.org/en/4.7/tutorials/physics/using_character_body_2d.html), accessed 2026-07-17 | Scripted top-down movement belongs in the physics loop and `move_and_slide()` supports it. | `PlayerMotor` and `EnemyMotor` own movement. | Recheck only if the pinned engine changes. |
| [Godot NavigationAgents](https://docs.godotengine.org/en/4.6/tutorials/navigation/navigation_using_navigationagents.html), accessed 2026-07-17 | An agent supplies path positions but does not move its parent. | `NavigationAgent2D` supplies paths; `EnemyMotor` remains authoritative. | Recheck against 4.7 docs if behavior differs locally. |
| [Godot TileMaps](https://docs.godotengine.org/en/4.7/tutorials/2d/using_tilemaps.html) and [CanvasItem Y-sort](https://docs.godotengine.org/en/4.5/classes/class_canvasitem.html), accessed 2026-07-17 | Overlapping 2D navigation maps are unsafe; higher Y draws in front when Y-sort is enabled. | One navigation plane and foot-point actor sorting. | Recheck only if real elevation enters scope. |
| [Godot AnimationTree](https://docs.godotengine.org/en/4.7/tutorials/animation/animation_tree.html), accessed 2026-07-17 | State machines and blend spaces can present directional locomotion and actions. | Presentation reflects authoritative action state. | Recheck only if the animation owner changes. |
| [Bastion development interview](https://www.gamedeveloper.com/game-platforms/road-to-the-igf-supergiant-games-dynamically-narrated-i-bastion-i-) and [Hades FAQ](https://www.supergiantgames.com/blog/hades-faq/), accessed 2026-07-17 | Supergiant used playable iteration and feedback to discover and refine the combat product. | Short proof precedes broad systems. | Historical evidence; no scheduled recheck. |
| [Hades High Speed update](https://www.supergiantgames.com/blog/hades-the-high-speed-update-patch-notes/) and [Superstar update](https://www.supergiantgames.com/blog/hades-superstar-update-patch-notes/), accessed 2026-07-17 | Input buffering, projectile/effect alignment, and playstyle-changing weapon variations were explicit refinement targets. | Buffering, collision clarity, and behavior-changing cards are first-slice requirements. | Historical evidence; no scheduled recheck. |

## Decision Notes

The owner locked the genre pivot, destructive reset, retained visual direction,
and core product identities on 2026-07-17. The remaining product and technical
choices formerly listed as experiments are now closed below so implementation
does not perform product research or choose architecture.

## Locked Decisions

| Topic | Final decision | Rationale / source |
| --- | --- | --- |
| Simulation | Use Godot 2D top-down physics with isometric raster presentation and one walkable navigation plane per room. | Active policy and Godot navigation/Y-sort evidence. |
| Delivery route | Start directly in a deterministic proof: movement room → arena room → one three-card reward → activation room → survival room → Slime King → result. | Gives one continuous user-testable path without a menu/economy tour. |
| Input | Keyboard/mouse: `WASD`, mouse aim, LMB melee, RMB ranged, Space dash, `E` interact, `Q` potion, Esc pause. Gamepad: left stick, right-stick aim, RB melee, RT ranged, south-face dash, west-face interact, north-face potion, Menu pause. | Melee and ranged never share one contextual command. |
| Aim | Mouse targets world position. Right stick supplies continuous aim and keeps the last non-zero vector. Controller assist may choose only a visible target within 12 degrees and 280 px of that vector; it cannot cross solid cover or redirect to another lane. | Preserves explicit intent while making controller aiming usable. |
| Facing | Gameplay vectors remain continuous. Locomotion art uses four diagonal facings with horizontal mirroring; attacks quantize to eight sectors and rotate hit/effect geometry to the exact sector. | Keeps the first actor-art cost bounded without losing directional combat. |
| Defense | The universal defensive action is dash/dodge. Shield guard and parry are equipment-specific systems and do not enter this proof. | A single fast universal defense keeps the control loop clear; shield identity remains preserved for later production. |
| Dash baseline | Speed `520 px/s`, duration `0.18 s`, invulnerability during the first `0.10 s`, recovery `0.12 s`, and reuse after `0.55 s` from start. Direction uses current movement, then current aim, then last facing. | Provides an explicit damage-avoidance action with visible timing. |
| Ground movement baseline | Maximum speed `220 px/s`, acceleration `1600 px/s²`, braking `2000 px/s²`, normalized diagonals, and no gravity/floor state. | Establishes a measurable first tuning point for 720p rooms. |
| Melee | A two-strike sword chain with one buffered primary input. Attack state owns startup, active, recovery, cancel window, and facing; animation never owns damage. | Minimum expressive close-range rhythm without a large combo system. |
| Ranged | A bow-like straight projectile on RMB/RT with a `0.45 s` reuse interval and no ammunition bookkeeping. Ordinary projectiles stop on `World`; only explicitly tagged boss/card projectiles may pierce. | Makes ranged combat reliably available and fixes the retired terrain-piercing failure. |
| Potion | Three charges per proof run. Each heals 35% maximum health after a `0.45 s` committed use; damage before the heal frame cancels without consuming a charge. | Multiple readable uses without adding inventory systems. |
| Enemy set | Exactly three ordinary roles: Pursuer, Shooter, Controller. All attacks have startup, active, recovery, and interruption/defeat cleanup. | Smallest mixed-pressure roster that tests spacing, cover, and attention. |
| Rooms | `FoundryApproach` is a deliberate arena clear; `PumpGallery` opens after two one-second activations even if enemies remain; `PressureVault` opens after 45 seconds even if enemies remain. | Tests extermination, activation, and survival policies explicitly. |
| Reward | After `FoundryApproach`, choose exactly one: `Dash Wake` leaves a 0.35-second once-per-enemy trail dealing 50% of first-sword-hit damage; `Perfect Punish` makes the next melee within 1.2 seconds after a successful dodge deal double stagger; `Split Focus` splits the first ranged hit into two non-splitting projectiles at ±18 degrees and 60% damage. | Each card visibly changes positioning, timing, or target handling. |
| Boss | Slime King remains the first boss. It uses four ground-plane patterns: lane charge, landing slam, poison safe bands, and two priority-target pressure nodes. | Retains a core identity while replacing all platform-era behavior. |
| UI | No main menu, Forge, merchant, loadout, minimap, or economy screen. Required surfaces are HUD, objective/boss band, three-card choice, pause/audio settings, and result replay/exit. | UI exists only where the proof needs a decision or exact state. |
| Persistence | Run/card/potion state is memory-only. `user://cardborne_pivot_settings.cfg` stores master and SFX volume only. No old-save read or migration. | Keeps the proof deterministic and prevents legacy schema pressure. |
| Art | Phases 1–4 use clear graybox shapes. Phase 5 creates a new isometric floor/wall/cover kit and actor sprites under the active visual contract; retained side-view art is palette/reference evidence only. | Combat scale and occlusion must be accepted before production art. |
| Dependencies | Use built-in Godot 4.7 nodes/resources only. No plugin, package, copied code, or third-party asset enters the proof. | Active policy and smallest controllable surface. |
| Tuning authority | Two focused tuning passes per phase may change movement/action numeric baselines by at most ±20% without changing input mapping, action ownership, objective rules, or content scope. | Allows feel refinement without reopening product decisions. |
| Final decision | The owner reviews one continuous build and records `Go`, `Iterate`, or `No-go`. `Iterate` names one failed category and permits one scoped correction cycle; a second failure becomes `No-go` for expansion. | Prevents an indefinite prototype from becoming accidental production. |

### Locked combat baselines

All time values are seconds. Phase-owned values may move only under the bounded
tuning rule; relationships and action ownership do not change.

| Actor/action | Health / damage | Startup / active / recovery | Other locked behavior |
| --- | ---: | --- | --- |
| Traveler | 100 max health | — | damage during dodge invulnerability emits `dodge_succeeded(source_id)` once per hostile activation instead of a damage result |
| Sword hit 1 | 20 damage, 20 stagger | `0.10 / 0.08 / 0.20` | hit 2 buffers during the final `0.15` of recovery; dash cancel begins after active ends |
| Sword hit 2 | 28 damage, 36 stagger | `0.08 / 0.10 / 0.28` | returns to neutral; dash cancel begins after active ends |
| Ranged shot | 16 damage, 8 stagger | `0.12 / projectile / 0.33` | speed `720 px/s`; `0.45` total reuse; dies on `World` or first hurtbox hit |
| Pursuer | 48 health; 12 hit damage | `0.35 / 0.18 / 0.45` | closes to 72 px, commits one straight lunge, then yields the attention token |
| Shooter | 36 health; 10 shot damage | `0.55 / projectile / 0.60` | holds 220–300 px; projectile speed `480 px/s`; ordinary cover terminates it |
| Controller | 56 health; 8 zone damage | `0.80 / 1.50 / 0.80` | targets the player's sampled ground point; one hit per target per zone |
| Slime King | 600 health | pattern-specific below | no contact damage outside an active pattern; defeated state clears every node/zone/projectile |

### Locked encounter fixtures

| Scene | Fixed content and timing | Completion |
| --- | --- | --- |
| `CombatSandbox` | walls, two cover blocks, dummy, one timed damage pulse | player-triggered reset/continue; no reward |
| `FoundryApproach` | wave 1: two Pursuers; wave 2 after wave 1 defeat: one Pursuer, one Shooter, one Controller | all five enemies defeated |
| `PumpGallery` | one Pursuer, one Shooter, one Controller; two pump interactions, each held for 1.0 second and interrupted by damage | both pumps active; living enemies do not block exit |
| `PressureVault` | starts with one Pursuer and one Shooter; at 15 seconds add one Pursuer and one Controller; at 30 seconds add two Pursuers and one Shooter; cap six living enemies | 45-second timer; living enemies do not block exit |

Slime King uses no overlapping major patterns and leaves at least `0.50` seconds
of neutral read time between them:

| Pattern | Startup / active / recovery | Damage and safe response |
| --- | --- | --- |
| Lane charge | `0.75 / 0.45 / 0.60` | 18 damage; telegraphed lane leaves both perpendicular sides open |
| Landing slam | `0.80 / 0.12 / 0.70` | 20 damage; ring has one dashable edge and boss remains punishable in recovery |
| Poison safe bands | `1.00 / 2.50 / 0.60` | 8 damage once per target per 0.50 seconds; at least 35% of walkable ground remains safe |
| Pressure nodes | `0.70 / 6.00 node lifetime / 0.60` | two 30-health nodes fire 8-damage marked shots; destroying both ends the pattern early |

The scheduler never repeats the same pattern twice, never starts a new pattern
before recovery plus neutral read time, and introduces pressure nodes only after
Slime King first reaches 70% health.

### Locked proof asset mapping

- Phases 1–4 use diagnostic shapes for world/actors and retained icons for live UI.
- `Dash Wake` uses `card_dash_wake`; `Perfect Punish` uses
  `card_perfect_punish`; `Split Focus` uses the `ranged` SVG fallback through
  Phase 4.
- Phase 5 adds `art/isometric_proof/cards/split_focus.png` and registers it in
  `art/isometric_proof/asset-manifest.json` without changing the card ID/effect.
- Slime King result UI uses `boss_slime_king`; gameplay sprite/telegraph art is
  new under `art/isometric_proof/`.

## Rejected Alternatives

| Alternative | Why it was viable | Why it was rejected |
| --- | --- | --- |
| True 3D scene, camera, and physics | Natural elevation and conventional 3D occlusion. | Multiplies art, collision, camera, and navigation cost before combat is proven. |
| Port the retired platformer runtime | Existing systems were broad and tested. | Gravity, ropes, contextual attacks, and stage assumptions encode the failed product. |
| Universal hold-to-guard plus dodge | Preserves shield identity immediately. | Adds a second universal defense before the basic action loop is legible. |
| Dash without invulnerability | Simpler collision behavior. | Fails to provide a dependable universal defensive response. |
| Contextual melee/ranged substitution | Reduces button count. | Directly contradicts the owner's control feedback and explicit-intent policy. |
| Eight fully authored locomotion facings | Highest sprite fidelity. | Doubles first-slice actor production before camera scale is accepted. |
| Forge, merchant, ammunition, and durability in the proof | Preserves more of the former metagame. | Adds decisions before the combat reward has proved that a next-room build matters. |
| Procedural rooms or visible tile assembly | Produces more layouts quickly. | Hides encounter-quality problems and risks repetitive map composition. |
| External behavior-tree, camera, or test plugins | Could accelerate individual systems. | Adds compatibility and ownership risk without a verified built-in limitation. |
| Reuse Flooded Works side-view terrain as runtime geometry | Assets already exist. | Their projection, collision assumptions, scale, and component states are wrong for isometric play. |

## Current State

Already true at commit `8124394`:

- `project.godot` targets Godot 4.7 GL Compatibility and names collision layers.
- `scenes/main/PivotRoot.tscn` is the only gameplay scene and boots cleanly.
- no tracked gameplay script, content resource, localization, or legacy save owner remains;
- project-owned art, UI Theme, asset manifests, font license, and wrappers remain;
- the pre-pivot implementation is recoverable at `7cc069c`.

Remaining implementation is exactly Phases 1–5 below. No product research,
technology comparison, or architecture selection remains inside those phases.

## Scope / Non-scope

In scope:

- one Traveler, fixed sword and ranged shot, dash, potion, interact, and pause;
- three ordinary enemy roles and one Slime King boss;
- three authored objective rooms plus one movement/sandbox entry and boss arena;
- one three-card behavior-changing reward;
- minimum live UI, settings persistence, new isometric proof art, Web export, and
  owner decision evidence.

Out of scope:

- jump, rope, one-way platform, falling, real elevation, or stacked navigation;
- universal guard/parry, shield runtime, other weapons, ammunition, equipment
  inventory, Forge, merchant, crafting, durability, material economy, or minimap;
- procedural generation, multiple regions, multiple heroes, narrative pipeline,
  permanent progression, profile migration, or full localization;
- final commercial art beyond the proof route.

Destructive or irreversible actions:

- none in this plan; the retired runtime remains recoverable from `7cc069c`;
- existing player-save paths are never read, migrated, or overwritten.

Exact actions requiring owner approval:

- adding any external dependency or third-party asset;
- replacing 2D simulation with true 3D/elevation;
- reading or migrating the retired save format;
- expanding content after the final result;
- merging to `master`, pushing, publishing, or deploying the build.

## Assumptions

No material product, architecture, dependency, asset-source, control, or
validation assumption remains unresolved. Numeric feel values are locked
baselines with the bounded tuning rule above, not choose-later decisions.

## Open Questions

None. New observations follow the predetermined contingencies and stop conditions
below; they do not create research work inside an implementation phase.

## Proposed Design

The heading is retained for the repository ExecPlan standard; the design is
locked for this proof.

```text
PivotRoot
  ProofRunSession          memory-only route, reward, retry, result
  RoomHost
    GroundArt              large graybox/art chunks; no gameplay state
    NavigationRegion2D     one non-stacked walkable region
    WorldCollision         walls and solid cover
    YSortActors            foot-point-sorted player, enemies, pickups
    Occluders              tall pieces with deterministic fade/cutaway
    ProjectilesAndEffects  explicit World/Hitbox collision
    EncounterRuntime       typed objective, spawns, exit state
  CameraRig                follow, bounds, restrained impulse
  CanvasUI                 HUD, reward, pause/settings, result
```

Route:

```text
CombatSandbox
  → FoundryApproach [arena clear]
  → choose Dash Wake | Perfect Punish | Split Focus
  → PumpGallery [activate two pumps; remaining enemies allowed]
  → PressureVault [survive 45 s; remaining enemies allowed]
  → SlimeKingArena
  → RunResult [Replay | Exit]
```

Logical actor position is always the ground-contact point. Visual height may
offset a sprite/effect but never changes navigation, cover, or hit ownership.

## Architecture and Ownership

| Concern | Final owner | Interface or invariant | Existing owner to reuse or retire |
| --- | --- | --- | --- |
| Input sampling | `scripts/player/PlayerInput.gd`; `PlayerCommandFrame.gd` | One immutable physics-frame command: move vector, aim vector, and pressed/held action flags. | Add InputMap entries to `project.godot`; no autoload. |
| Aim | `scripts/player/AimResolver.gd` | Returns explicit world aim and eight-sector attack direction; applies only the locked assist cone. | No target selection inside attacks. |
| Movement/dash | `scripts/player/PlayerMotor.gd` | Consumes command frame; owns velocity, collision, dash motion, invulnerability timing, and recovery. | `CharacterBody2D`; no animation-owned motion. |
| Action state | `scripts/player/PlayerActionController.gd` | Owns buffer, startup, active, recovery, cancel rules, potion commit, and action traces. | No contextual action substitution. |
| Attack data/execution | `scripts/combat/AttackDefinition.gd`; `AttackExecutor.gd`; `data/attacks/proof/*.tres` | Resource fields include timing, range, shape, damage, stagger, projectile, collision behavior, and effect ID. | No attack constants in UI or animation clips. |
| Damage | `scripts/combat/Hitbox.gd`; `Hurtbox.gd`; `DamageRequest.gd`; `DamageResult.gd` | One request produces at most one result per source/target activation; result names source and interruption. | Collision layers already exist in `project.godot`. |
| Presentation | `scripts/presentation/ActorPresenter.gd`; `CombatFeedback.gd` | Reads state/results; owns animation, tint, hitstop request, particles, sound, and bounded camera impulse. | Never creates authoritative damage. |
| Enemy decision | `scripts/enemies/EnemyBrain.gd`; role states under `scripts/enemies/states/` | Selects legal intent only when prior intent reaches recovery/interruption. | Exactly Pursuer, Shooter, Controller. |
| Enemy movement | `scripts/enemies/EnemyMotor.gd`; child `NavigationAgent2D` | Agent supplies next path point; motor supplies velocity and separation. | One room navigation map; no stacked mesh. |
| Encounter objectives | `scripts/encounters/EncounterRuntime.gd`; `objectives/*.gd`; `data/encounters/proof/*.tres` | Typed `ArenaClear`, `Activation`, and `Survival` objectives exclusively decide exits. | No global all-enemies-dead fallback. |
| Cards | `scripts/cards/CardDefinition.gd`; `CardEffect.gd`; three effects under `scripts/cards/effects/` | Stable ID plus one bounded hook: after dash, after successful dodge, or after first ranged hit. | UI reads definitions; it does not implement effects. |
| Run state | `scripts/run/ProofRunSession.gd`; `ProofRunSnapshot.gd` | In-memory route/card/potion/result snapshot; restart creates a new session. | Scene-owned by `PivotRoot`; no global profile. |
| Settings | `scripts/settings/PivotSettingsStore.gd` | `ConfigFile` keys `audio/master_volume` and `audio/sfx_volume` only. | New path `user://cardborne_pivot_settings.cfg`. |
| UI | presenters under `scripts/ui/`; scenes under `scenes/ui/proof/` | Presenters consume snapshots and emit intents; Theme and manifest IDs own visuals. | Reuse retained Theme/assets, not deleted UI runtime. |
| Art manifest | `art/isometric_proof/asset-manifest.json` | Stable IDs, source path, native size, pivot, display size, fallback, provenance. | Retained Flooded Works art remains evidence only. |

## As-Is / To-Be Delta Map

| Concern | As-is | To-be | Acceptance check | Guard / leftover check |
| --- | --- | --- | --- | --- |
| Boot | Empty `PivotRoot`. | Direct deterministic proof entry and replay. | Start, fail, replay, win, replay, and exit work without stale state. | No legacy main-menu/run director returns. |
| Input | No actions. | Locked keyboard/mouse and gamepad map with explicit melee/ranged. | Trace records requested action and direction on both devices. | No shared attack action or contextual resolver. |
| Movement | No actor. | Normalized top-down motion and locked dodge. | Diagonal speed, wall slide, dash endpoint, invulnerability, recovery, and cooldown fixtures pass. | No gravity, floor, coyote, rope, or one-way code. |
| Combat | No runtime. | Typed melee/ranged/potion/damage transactions. | Timing trace matches hit/effect frames; ordinary projectile terminates on cover. | No animation-authored hit and no ammunition owner. |
| Enemies | No runtime. | Three roles with navigation, spacing, tells, recovery, and cleanup. | Each reaches legal positions, attacks within role range, recovers from obstruction, and stops after defeat. | No fixed jump path or idle-after-first-action behavior. |
| Objectives | No room flow. | Arena, activation, and survival owners. | Pump/Survival exits open with an irrelevant living enemy. | No global extermination fallback. |
| Cards | No data. | Three exact behavior hooks and one reward. | Selection changes the next room and each hook fires once per legal trigger. | No numeric-only or recursive trigger loop. |
| Boss | Illustration only. | Four-pattern ground-plane Slime King. | Every hit has startup/active/recovery and a reachable safe response. | No platform trajectory or unavoidable full-room overlap. |
| Art/UI | Retained references and Theme. | New isometric gameplay kit plus minimal live proof UI. | Y-sort/occlusion/action timing and layout pass at three viewports. | Background never owns collision, actor, telegraph, or text. |
| Persistence | None. | Two audio settings only. | Save/load and malformed-file fallback pass. | No retired save read/write. |

## Milestones

0. **Completed reset:** commit `8124394`, empty boot, retained art/provenance.
1. **Playable controls:** direct-launch movement, dodge, melee, ranged, potion, and target dummy.
2. **Readable combat:** three enemies, cover, damage, feedback, defeat, and retry.
3. **Meaningful route:** three objective rooms and one behavior-changing card choice.
4. **Integrated proof:** Slime King, result, replay, audio settings, and full route.
5. **Production evidence:** isometric art/UI, three-viewport captures, Web build, and owner decision.

## Tasks

### Phase 1 — Playable controls

Goal: deliver a directly launchable room where movement and every locked player
action can be judged without enemy pressure.

Source owners touched: `project.godot`, `scenes/main/PivotRoot.tscn`,
`scenes/testbeds/isometric_combat/CombatSandbox.tscn`, `scripts/player/`,
`scripts/combat/`, `data/attacks/proof/`,
`tools/validation/validate_movement_and_actions.gd`,
`docs/product/isometric_action_rpg_product_brief.md`.

- [x] **1.1 Write the product brief from locked decisions.**
  - As-is: `docs/product/README.md` says no replacement gameplay spec exists.
  - To-be: create an active spec that restates the locked route, controls,
    objectives, cards, boss, scope, and completion criteria without new choices.
  - Accept: its requirements map one-to-one to this plan and its local links resolve.
  - Guard: no research section, recommendation, broader content roadmap, or
    platform-era behavior enters the spec.
- [x] **1.2 Create the command/input boundary and InputMap.**
  - As-is: no input actions or player scripts exist.
  - To-be: add the exact actions and device bindings in the decision table;
    `PlayerInput` emits one typed `PlayerCommandFrame` per physics tick.
  - Accept: keyboard/mouse and gamepad fixtures produce equivalent actions and
    explicit melee/ranged traces.
  - Guard: device code does not move the actor, select an attack, or deal damage.
- [x] **1.3 Implement motor, aim, dodge, and camera.**
  - As-is: empty room root.
  - To-be: add `CharacterBody2D`, `PlayerMotor`, `AimResolver`, bounded `Camera2D`,
    walls, cover, and the locked movement/dash values.
  - Accept: the movement validator passes normalized diagonal, wall slide, aim
    fallback, dash distance, invulnerability window, recovery, and cooldown.
  - Guard: no gravity, floor state, real height, target snap, or animation-driven
    translation exists.
- [x] **1.4 Implement actions, dummy, and action trace.**
  - As-is: no attack or potion transaction.
  - To-be: implement two-hit melee, ranged projectile, three-charge potion,
    buffer, timings, hit/hurt areas, damage result, and a resettable dummy.
  - Accept: every requested action starts in the requested sector, buffers once
    at the legal boundary, hits at most once per activation, and returns to idle.
  - Guard: ranged has no ammo and ordinary shots stop on cover.

Batch acceptance: launch `CombatSandbox`, circle the dummy, use both attacks,
dodge through its timed hit, take damage, use all three potions, and reset without
an error or lost legal buffered action.

Batch guard: no enemy AI, reward, run state, production art, or broad UI is added.

### Phase 2 — Readable combat exchange

Goal: make one mixed encounter understandable, fair, and recoverable.

Source owners touched: `scripts/enemies/`, `scripts/presentation/`,
`scenes/enemies/proof/`, `data/enemies/proof/`,
`scenes/testbeds/isometric_combat/MixedCombatFixture.tscn`,
`tools/validation/validate_combat_exchange.gd`.

- [ ] **2.1 Implement the three enemy roles and typed action states.**
  - As-is: only dummy damage exists.
  - To-be: add Pursuer, Shooter, and Controller with explicit approach/aim,
    startup, active, recovery, interrupted, and defeated states.
  - Accept: each role completes three action cycles, can be interrupted, and
    cleans all hit/effect owners on defeat.
  - Guard: no actor uses a fixed platform trajectory or attacks outside its state.
- [ ] **2.2 Add path supply, motor steering, separation, and lane attention.**
  - As-is: no navigation consumer.
  - To-be: one `NavigationRegion2D`, one agent per enemy, motor-owned movement,
    obstruction timer, separation, role range, and one high-attention tell token.
  - Accept: enemies reach legal targets around cover, stop at role range, resume
    after obstruction, and do not overlap simultaneous high-attention attacks.
  - Guard: `NavigationAgent2D` never writes actor velocity or chooses attacks.
- [ ] **2.3 Add combat feedback and concise retry.**
  - As-is: trace/dummy feedback only.
  - To-be: damage source label, hit flash, bounded hitstop, recoil, camera impulse,
    defeat cleanup, player death, and one-command fixture retry.
  - Accept: the player and trace identify every damage source; visual and damage
    frames align; retry restores deterministic initial state.
  - Guard: effect density never hides a startup or cover edge.

Batch acceptance: defeat a mixed group of two Pursuers, one Shooter, and one
Controller; Shooter shots terminate on cover and no enemy stalls for more than
one second outside an explicit recovery.

Batch guard: no rooms, cards, boss, or production art is introduced.

### Phase 3 — Authored route and behavior-changing reward

Goal: prove objective variety and a card that visibly changes the next fight.

Source owners touched: `scripts/encounters/`, `scripts/cards/`, `scripts/run/`,
`data/encounters/proof/`, `data/cards/proof/`, `scenes/rooms/proof/`,
`scenes/ui/proof/CardReward.tscn`,
`tools/validation/validate_route_and_cards.gd`.

- [ ] **3.1 Implement typed objectives and room transitions.**
  - As-is: one isolated combat fixture.
  - To-be: create exact FoundryApproach, PumpGallery, and PressureVault scenes,
    definitions, spawn sets, objective runtime, exit state, and quick restart.
  - Accept: arena exit requires defeat; pump exit requires two activations;
    survival exit opens at 45 seconds; the latter two pass with one enemy alive.
  - Guard: no shared `all_enemies_dead` fallback or procedural room graph exists.
- [ ] **3.2 Implement one in-memory proof session.**
  - As-is: fixture-local state.
  - To-be: `ProofRunSession` owns route position, health, potion charges, card,
    room entry snapshot, failure retry, and final result snapshot.
  - Accept: retry returns to the current room snapshot; Replay creates a clean
    session; Exit quits without persisting run state.
  - Guard: no profile, currency, inventory, stage index, or legacy save access.
- [ ] **3.3 Implement the exact reward and three bounded effects.**
  - As-is: no card data/UI.
  - To-be: add stable definitions/effects for Dash Wake, Perfect Punish, and Split
    Focus; show one three-choice screen after FoundryApproach.
  - Accept: each effect fires once per legal trigger, is visible in PumpGallery,
    survives the room transition, and cannot trigger itself recursively.
  - Guard: UI emits selection intent only; no effect logic lives in the card scene.

Batch acceptance: complete all three rooms with each card in separate deterministic
runs; observe the selected behavior in the next room and open non-arena exits with
an irrelevant living enemy.

Batch guard: no Forge, merchant, equipment inventory, random room, or permanent
progression enters the route.

### Phase 4 — Slime King and integrated proof

Goal: produce the complete graybox start-to-result route.

Source owners touched: `scripts/bosses/`, `scenes/bosses/SlimeKingArena.tscn`,
`data/bosses/proof/`, `scenes/ui/proof/PauseMenu.tscn`,
`scenes/ui/proof/RunResult.tscn`, `scripts/settings/PivotSettingsStore.gd`,
`tools/validation/validate_integrated_proof.gd`.

- [ ] **4.1 Implement four Slime King patterns and scheduler.**
  - As-is: retained illustration only.
  - To-be: add lane charge, landing slam, poison safe bands, and two pressure
    nodes with explicit startup/active/recovery and bounded scheduler rules.
  - Accept: every pattern exposes a reachable response; no overlapping pattern
    removes all safe ground; each card provides one useful but non-skipping response.
  - Guard: no platform jump path, unavoidable full-room damage, or animation-owned hit.
- [ ] **4.2 Connect boot, route, pause/settings, result, replay, and exit.**
  - As-is: direct sandbox/room fixtures.
  - To-be: `PivotRoot` owns `ProofRunSession` and route host; pause exposes Resume,
    Restart Room, audio Settings, and Exit; result exposes Replay and Exit.
  - Accept: start, room transitions, death/retry, boss victory, Replay, and Exit
    work twice consecutively with no stale card, potion, enemy, or objective state.
  - Guard: no main menu, loadout, Forge, merchant, or profile screen appears.
- [ ] **4.3 Persist only the two audio settings.**
  - As-is: no save owner.
  - To-be: write/read the exact `ConfigFile` path and keys; malformed or missing
    files restore defaults and log one concise warning.
  - Accept: both values survive restart; malformed input does not block boot.
  - Guard: no run, card, result, player stat, or retired save field is serialized.

Batch acceptance: one successful graybox run lasts five to eight minutes on the
reference machine, can be replayed immediately, and exposes no broken transition.

Batch guard: duration is corrected only through encounter counts/timing within
the locked route; no economy or extra room is added.

### Phase 5 — Isometric art, UI, build, and decision evidence

Goal: replace graybox presentation without changing combat truth, validate the
production-style build, and record the owner outcome.

Source owners touched: `art/isometric_proof/`, `scripts/presentation/`,
`scenes/ui/proof/`, `art/ui/production/production_ui_theme.tres`,
`tools/validation/validate_art_ui_contract.gd`,
`tools/validation/capture_proof_views.gd`, `tools/export_web.ps1`,
`.agent/Documentation.md`.

- [ ] **5.1 Produce the isometric proof asset set and manifest.**
  - As-is: accepted style references but no isometric gameplay kit.
  - To-be: create large floor, wall, cover, low-prop, occluder, Traveler, three
    enemy, Slime King, Split Focus card, projectile, impact, and telegraph raster
    assets with ground pivots and manifest metadata.
  - Accept: every asset ID resolves or uses a declared fallback; no background
    contains actors, collision edges, pickups, telegraphs, text, or UI state.
  - Guard: no side-view terrain PNG is used as runtime collision or room geometry.
- [ ] **5.2 Replace graybox visuals and implement occlusion.**
  - As-is: diagnostic shapes.
  - To-be: presenters bind state to four-facing locomotion/eight-sector attacks;
    tall foreground occluders fade to 35% opacity while between camera and player
    or an active high-attention threat, then restore over 0.15 seconds.
  - Accept: crossing actors sort at feet; every tell and cover edge remains visible
    at 960x540, 1280x720, and 1920x1080.
  - Guard: visual height never alters hit, cover, or navigation state.
- [ ] **5.3 Implement the minimum live UI with retained Theme/assets.**
  - As-is: no runtime UI.
  - To-be: HUD shows health, three potion pips, melee/ranged/dash state, objective,
    boss health, and concise damage source; reward/pause/result expose only their
    locked decisions and full keyboard/gamepad focus.
  - Accept: layout/state checks pass at all three viewports with no clipping,
    debug text, focus loss, nested ornamental frames, or baked labels.
  - Guard: presenters consume snapshots and emit intents only.
- [ ] **5.4 Run final validation, Web export, continuous review, and record outcome.**
  - As-is: only empty baseline validation exists.
  - To-be: run every validator, capture the route, export the production Web build,
    play the built artifact, and record `Go`, `Iterate`, or `No-go` plus failed
    category in `.agent/Documentation.md`.
  - Accept: all final gates pass and one decision is recorded.
  - Guard: `Go` authorizes a separate production plan, not unplanned expansion in
    this document; merge/push/publish still require explicit owner instruction.

Batch acceptance: the same built artifact supplies the continuous capture and
owner review; movement, damage, objective, reward, boss, replay, and UI remain
legible without explanation.

Batch guard: presentation replacement cannot change action timings, collision,
objective completion, card hooks, or boss scheduling.

## Test Plan

### Validation Cadence

Inner-loop commands:

- `./tools/godot.ps1 --version`
- `./tools/godot.ps1 --path . --headless --import`
- `./tools/godot.ps1 --path . --headless --quit-after 2`
- `./tools/godot.ps1 --path . --headless --script res://tools/validation/validate_movement_and_actions.gd`
- `./tools/godot.ps1 --path . --headless --script res://tools/validation/validate_combat_exchange.gd`
- `./tools/godot.ps1 --path . --headless --script res://tools/validation/validate_route_and_cards.gd`
- `./tools/godot.ps1 --path . --headless --script res://tools/validation/validate_integrated_proof.gd`
- `./tools/godot.ps1 --path . --headless --script res://tools/validation/validate_art_ui_contract.gd`

Run only validators whose owning phase has created them. Each validator exits
non-zero with a named failed invariant; it never silently skips a missing fixture.

Batch gates:

| Phase | Automated gate | Manual gate |
| --- | --- | --- |
| 1 | movement/action validator | two minutes each on keyboard/mouse and gamepad in CombatSandbox |
| 2 | combat-exchange validator | mixed encounter, cover, damage source, death/retry |
| 3 | route/card validator for all three deterministic card fixtures | three-room route with living-enemy activation/survival exits |
| 4 | integrated-proof validator twice consecutively | one uninterrupted five-to-eight-minute graybox run |
| 5 | art/UI validator and fixed captures at 960x540, 1280x720, 1920x1080 | built Web artifact, keyboard/gamepad focus, continuous owner review |

Final gates:

1. `./tools/godot.ps1 --path . --headless --import`
2. run all five validation scripts above;
3. `./tools/godot.ps1 --path . --headless --script res://tools/validation/capture_proof_views.gd`;
4. `./tools/export_web.ps1` and verify `build/web/index.html`, `.js`, `.pck`, and
   `.wasm` exist;
5. before serving a path under `D:\npjt`, load `$npjt-port-guard`, resolve the
   fastrun-manager `codex` lane, and use the command it reports. The serving port
   is intentionally not hard-coded because the manager owns that dynamic value;
6. inspect the built artifact and continuous route at the three target viewports;
7. `git diff --check`, local Markdown-link check, lifecycle check, and task-owned
   staging guard;
8. record the owner decision and exact failed category, if any.

Performance gate at 1280x720 on the local reference machine: a 30-second fixture
with 12 ordinary enemies and 32 concurrent projectile/effect nodes maintains at
least 60 average rendered FPS and 50 FPS one-percent-low. Failure blocks Phase 5
completion and is corrected without reducing tell visibility or collision truth.

Rerun policy:

- rerun a failed narrow check only after a concrete code/data change or a new
  named hypothesis;
- rerun all final gates only after the suspected cause changes;
- record known non-blocking warnings rather than rediscovering them;
- never use repeated full validation as a substitute for implementing the next
  unchecked task.

## Predetermined Error Handling and Contingencies

| Trigger | Required response | Limit / escalation point |
| --- | --- | --- |
| Missing or malformed settings file | Restore locked defaults, log one warning, and continue boot. | Any need to persist more than two audio keys is a scope change. |
| Missing retained UI asset ID | Use the manifest-declared fallback while preserving component bounds and log the ID once. | Adding a third-party replacement requires owner approval. |
| Enemy cannot reach a legal target for one second | Cancel current intent, request a fresh path, move to the nearest reachable role anchor, and re-enter decision state. | After two fixture-specific navigation fixes fail, stop Phase 2; do not switch navigation architecture silently. |
| Several enemies request high-attention attacks | Grant the token to the oldest legal request; others reposition or remain in low-attention states. | More than one simultaneous token is forbidden in the proof. |
| Card hook attempts to trigger itself | Reject the nested source ID, log the prevented cycle, and continue the action. | Any second-order card chain is out of scope. |
| Foreground art hides player or active threat | Apply the locked 35% occluder fade; if the whole silhouette remains hidden, use the authored cutaway variant. | Do not alter collision or camera projection to solve one asset. |
| Movement/action feel fails a manual gate | Change only phase-owned numeric baselines within ±20%, rerun the narrow validator, and perform at most two focused passes. | A required control/ownership change stops the phase for owner approval. |
| Full route is shorter than five or longer than eight minutes | Adjust locked-room enemy counts, activation placement, survival spawn cadence, or boss health within the same route. | Adding/removing rooms or systems is forbidden. |
| Web export templates are unavailable | Run `tools/setup-godot.ps1` only for the pinned runtime/templates, rerun export, and report the exact missing component. | No substitute build may mark the final gate passed. |
| Final owner result is `Iterate` | Change the single named failed category, rerun its batch gate and all final gates once. | A second failed continuous review records `No-go` for expansion. |
| Final owner result is `No-go` | Preserve the proof commit and evidence, mark this plan done, and stop content work. | No automatic redesign begins. |

## Progress

- [x] Reset baseline committed at `8124394`.
- [x] Relevant repository, asset, policy, engine, and external development sources inspected.
- [x] Material product/technical choices and rejected alternatives recorded.
- [x] Godot 4.7 import and empty start validated.
- [ ] Phase 1 — playable controls: implementation and automated gate pass;
  physical-gamepad and two-minute manual feel gates remain.
- [ ] Phase 2 — readable combat exchange.
- [ ] Phase 3 — authored route and behavior-changing reward.
- [ ] Phase 4 — Slime King and integrated proof.
- [ ] Phase 5 — art/UI, Web build, and owner decision.
- [ ] Final gates.

## Next Steps

1. Run the two-minute keyboard/mouse and physical-gamepad feel checks in
   `CombatSandbox`; record the result and close the Phase 1 batch gate.
2. After that gate passes, implement Phase 2 in order and do not introduce rooms,
   cards, boss content, or production art during its combat-exchange fixture.
3. Execute Phases 3–5 sequentially; no later phase starts while the prior batch
   acceptance or guard fails.

## Completion Criteria

- [ ] The direct-start proof completes movement room, three objective rooms, one
  card reward, Slime King, result, Replay, and Exit without stale state.
- [ ] Explicit melee/ranged, dodge, potion, cover, objectives, cards, boss, and
  settings satisfy their acceptance checks on both input families.
- [ ] All regression guards and final validation gates pass on the built Web artifact.
- [ ] New isometric art and live UI satisfy the active visual contract at all three viewports.
- [ ] No retired runtime owner, duplicate path, placeholder decision, unresolved
  material choice, external dependency, or legacy save access remains.
- [ ] The owner outcome and durable run/verify commands are recorded in canonical documents.

## Rollback / Safety

- Pre-pivot recovery point: `7cc069c`.
- Clean reset baseline: `8124394`.
- Recover only one inspected algorithm or identity mapping when a new owner needs
  it; never restore a retired directory wholesale.
- Do not stage or normalize pre-existing `.import` working-tree changes unless
  the owner assigns them to the current phase.
- Each phase ends in one scoped commit after its batch gate passes.
- Do not force-push, merge, push, publish, or deploy without explicit instruction.

## Risks

- **Surface imitation without better feel:** Phase 1 and Phase 2 manual gates
  block rooms and meta work; two bounded tuning passes are the maximum.
- **Isometric art hides ground truth:** foot pivots, one plane, solid cover, fixed
  occluder behavior, and three-viewport captures are mandatory.
- **Navigation jitter or passive enemies:** custom motors, obstruction recovery,
  role anchors, and the mixed fixture expose the failure before route work.
- **Cards collapse into numbers or loops:** each card owns one visible bounded hook
  and rejects nested self-sources.
- **Content expands before fun is proven:** exact room/enemy/card counts and final
  owner outcome gate all broader work.
- **Prototype cannot ship as a Web proof:** the production export and built-app
  review are completion gates, not deferred release work.

## Stop Conditions

Complete when:

- every completion criterion passes and `Go`, `Iterate`, or `No-go` is recorded;
- `No-go` also completes this proof plan because its objective is evidence for the
  foundation decision, not guaranteed production approval.

Escalate only when:

- true 3D/elevation, an external dependency/asset, retired-save migration,
  control ownership change, or content expansion becomes necessary;
- the navigation or control contingency reaches its stated limit;
- merge, push, publish, or deploy is requested.

Do not stop when:

- an implementation-local bug, validator failure, or bounded numeric tuning issue
  remains inside the active phase;
- a retained asset needs its declared fallback;
- one manual pass fails before the allowed focused correction is applied.

## Handoff

```text
Goal: Build the locked five-to-eight-minute Cardborne isometric combat proof.

Read first:
- AGENTS.md
- .agent/Prompt.md
- docs/design/UI_VISUAL_SYSTEM.md
- .agent/execplans/2026-07-17-isometric-action-rpg-pivot.md

Execute exactly:
- Start at the first unchecked task in the active phase.
- Do not introduce an item listed under Non-scope or Rejected Alternatives.
- Commit only after the phase batch acceptance and guard pass.

Validate with:
- The phase validator and manual batch gate.
- All final commands in Test Plan before completion.

Stop when:
- A stated escalation condition is reached, or
- all completion criteria and the owner decision are recorded.
```
