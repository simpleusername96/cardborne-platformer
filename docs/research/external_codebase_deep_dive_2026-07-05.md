---
type: evidence
status: archived
created: 2026-07-05
last_reviewed: 2026-07-12
source: Local clones, Godot 4.7 headless checks, source-level inspection, and current repo contract review on 2026-07-05
topic: External Godot codebase deep dive for the Cardborne production foundation
scope: Evidence and adoption recommendations for map authoring, input remapping, movement, procedural generation, combat components, enemy AI, shell UI, and progression tooling
related:
  - ../design/PROCEDURAL_REGION_GENERATION.md
  - ../design/MAP_AUTHORING_PIPELINE_CONTRACT.md
  - ../design/ENEMIES_TRAPS_GIMMICKS.md
  - ../architecture/FIRST_SLICE_ARCHITECTURE.md
  - ./foundation_resource_survey_2026-07-05.md
---

# External Codebase Deep Dive - 2026-07-05

## Purpose

This document records the code-level inspection that follows the broader resource survey. The earlier survey listed plausible packages and references. This report checks actual cloned source code, Godot import/boot behavior where practical, license signals, architectural fit, adoption risks, and final source picks.

The goal is not to preserve the current codebase. The goal is to build a decent working Godot 4.x platform-action game foundation. The current code can be discarded if the contracts and docs are strong enough to rebuild the testbeds. External code should be adopted only when it improves that goal without burying the project under someone else's architecture.

## Executive Decision

The best path is not to replace the project with a single external framework. No inspected Godot package cleanly covers side-view authored dungeon maps, vertical traversal, profile-specific combat, deterministic generated pockets, enemy variety, checkpoint recovery, UI guidance, and card-run staging in one coherent package.

The strongest path is a selective foundation stack:

- Use an external level authoring pipeline, with LDtk plus Godot LDtk Importer as the primary spike.
- Use a lightweight persistent input remap resource, with KoBeWi ControlsRemap as the first candidate.
- Use GDQuest procedural-generation demos as algorithm references for seeded chunk assembly, not as direct map code.
- Use Ultimate Platformer Controller 2D as a movement feature checklist and formula reference, not as a drop-in controller.
- Use LimboAI demo components as reference for hitbox/hurtbox/health/knockback separation. Do not adopt the full LimboAI plugin until enemy behavior is complex enough to justify a GDExtension/editor dependency.
- Keep Maaack's Game Template and Maaack's Input Remapping as optional spikes for full menu/options polish. Do not adopt the whole template as the game foundation right now.
- Treat Metroidvania System as a later minimap/world-map/persistence candidate, not as physical level geometry.
- Treat YATI as a strong fallback only if Tiled becomes the chosen editor. LDtk fits typed side-view room entities better for this project.
- Keep Dialogic for later NPC/dialogue/shop depth. It is not a testbed foundation dependency.

The main architectural correction is this: stop hand-building serious maps entirely from GDScript rectangles. The next foundation pass should introduce a map authoring and element-marker contract so maps can be authored, inspected, iterated, and then decorated/generated under strict passability rules.

## Research Method

### Local Clone Location

External repos were cloned under:

`D:\npjt\cardborne-platformer\.codex-runtime\external-research\2026-07-05`

That path is ignored by git and is only working evidence. Durable decisions belong in this document and the design contracts, not in the clone directory.

### Validation Environment

- Engine command path: `.\tools\godot.ps1`
- Engine found locally: Godot `4.7.stable.official.5b4e0cb0f`
- Main validation attempts:
  - `--headless --path <repo> --import`
  - `--headless --path <repo> --quit-after 1`
- Logs captured under `.codex-runtime/external-research/2026-07-05/_logs/`

Some Godot editor projects do not terminate cleanly under automated headless checks on this Windows environment. For those, the report treats clean import/boot as positive evidence but does not treat headless timeout as a total rejection unless the logs show real script or parse failures.

### Source Inspection Scope

I inspected:

- `project.godot` autoloads and input maps where present.
- Plugin importers and editor scripts.
- Runtime scripts for player movement, weapon/projectile, enemy behavior, hitbox/hurtbox/health, input remapping, save/config, room map, procedural generation, and post-import hooks.
- README and license files.
- Commit hash and last commit date for traceability.

## Current Contract Fit Requirements

The external source has to be judged against the current project contract, not against generic popularity.

| Requirement from current docs | What external code must help prove | Adoption implication |
| --- | --- | --- |
| Side-view dungeon map, not one screen | Author playable rooms with camera-followed space, occluded full map, ceilings/sides/bottoms, vertical branches | Needs real map authoring pipeline, not only procedural toy rooms |
| Horizontal map with vertical aspects | Support 4:3, 5:4, 4:5-ish playable bounds through configurable dimensions, not fixed absolute values | Generator/authoring must store ratios and screen counts as constraints |
| Profile-specific characters | Make Warrior, Archer, Assassin behave differently beyond health | Movement and attack contracts stay local; no external player script should erase profiles |
| Movement proof | Jump, double jump, dash, climb, wall traversal, ledges, passability metrics | Use external movement references, but keep our profile-aware controller |
| Combat proof | Visible attack motion, projectiles, enemy hit reaction, knockback, death/reset | Reuse hitbox/hurtbox/health ideas; preserve shared `DamageInfo` style |
| Diverse enemies/obstacles | Patrol, charge, shoot, shield, leap, summon, traps, destructibles, interactables | Need archetype contracts before full AI framework |
| Random landscape generation | Deterministic seed, route validation, authored templates, active caps | Use chunk/random-walker algorithms with strict passability metadata |
| Settings and remap | Actual key remap, not only binding list | Adopt or implement persistent remap around canonical input map |
| Checkpoint recovery | Death/fall respawn at checkpoint without soft lock | Keep local stage flow and validation gates |
| Disposable code, durable docs | External adoption must be documented enough to rebuild | Every adopted package needs a wrapper contract and license record |

## Candidate Inventory

| Candidate | Remote | Local commit | Last commit | Source size inspected | License signal | Local Godot check |
| --- | --- | --- | --- | --- | --- | --- |
| Maaack Godot Game Template | https://github.com/Maaack/Godot-Game-Template.git | `1953b35` | 2026-04-07 | 104 `.gd`, 118 scenes | MIT | Import OK; boot reported example scene parse error |
| Maaack Input Remapping | https://github.com/Maaack/Godot-Input-Remapping.git | `736bb20` | 2025-12-21 | 24 `.gd`, 27 scenes | MIT | Import OK; boot produced display-server keycode warnings in headless |
| KoBeWi Godot Input Remap | https://github.com/KoBeWi/Godot-Input-Remap.git | `0d7204b` | 2026-05-01 | 2 `.gd` | MIT | Source-only plugin; no project boot |
| Ultimate Platformer Controller 2D | https://github.com/Noah-Erz/ultimate-platformer-controller-2d.git | `9ce6580` | 2024-12-28 | 1 `.gd` | MIT | Source-only script; no project boot |
| KoBeWi Metroidvania System | https://github.com/KoBeWi/Metroidvania-System.git | `d9e456d` | 2026-04-11 | 56 `.gd`, 58 scenes | MIT | Import ran; headless import warned about missing PluginRefresher and leaked editor RIDs |
| GDQuest Godot 4 Procedural Generation | https://github.com/gdquest-demos/godot-4-procedural-generation.git | `19c98ce` | 2026-06-26 | 115 `.gd`, 85 scenes | Source MIT, assets CC-BY 4.0 | Import ran; no main scene defined for boot |
| Godot LDtk Importer | https://github.com/heygleeson/godot-ldtk-importer.git | `0ecab8d` | 2025-02-02 | 26 `.gd`, 14 scenes | MIT | Import OK; boot OK |
| YATI | https://github.com/Kiamo2/YATI.git | `72a3716` | 2026-03-19 | 20 `.gd` plus C# copy | MIT | Source-only plugin; no project boot |
| LimboAI | https://github.com/limbonaut/limboai.git | `f94763e` | 2026-06-19 | 27 `.gd`, 27 scenes, large C++ source | MIT for source, demo art attribution required | Full plugin needs GDExtension/module build; source inspection only |
| Dialogic 2 | https://github.com/dialogic-godot/dialogic.git | `e127f85` | 2026-06-21 | 264 `.gd`, 83 scenes | MIT, some bundled assets/fonts have separate notices | Source inspection only |
| Godot official demo projects | https://github.com/godotengine/godot-demo-projects.git | `6ad6167` | 2026-07-03 | Sparse clone: platformer and input mapping demos | MIT | Source inspected; automated boot did not terminate cleanly under this method |

## Deep Dive: Godot LDtk Importer

### Relevant Source Inspected

- `addons/ldtk-importer/ldtk-importer.gd`
- `addons/ldtk-importer/src/world.gd`
- `addons/ldtk-importer/src/level.gd`
- `addons/ldtk-importer/src/layer.gd`
- `addons/ldtk-importer/src/tileset.gd`
- `addons/ldtk-importer/src/components/ldtk-world.gd`
- `addons/ldtk-importer/src/components/ldtk-level.gd`
- `addons/ldtk-importer/src/components/ldtk-entity-layer.gd`
- `addons/ldtk-importer/src/components/ldtk-entity.gd`
- `addons/ldtk-importer/post-import/entity-template.gd`
- `examples/gridvania/example_gridvania.ldtk`

### What The Code Actually Does

The importer is an `EditorImportPlugin` that recognizes `.ldtk` and saves imported worlds/levels as Godot scenes. It parses the LDtk world file, builds definitions, builds tilesets, then builds levels and layers.

The importer exposes import options for:

- grouping levels by world layer,
- packing levels,
- saving levels as `.scn` or `.tscn`,
- always-visible layers,
- tile custom data,
- integer grid tilesets,
- entity reference resolution,
- entity placeholders,
- tileset/entity/level/world post-import scripts,
- forced tileset reimport,
- verbose output.

The layer builder handles:

- LDtk `Entities` layers by creating `LDTKEntityLayer`,
- `IntGrid` layers as value tilemaps and optionally tile layers,
- `Tiles` and `AutoLayer` as `TileMapLayer`,
- flipped tiles and alpha variants.

The entity layer preserves:

- `iid`,
- layer definition,
- parsed entities array,
- optional placeholder nodes,
- entity fields,
- EntityRef resolution helpers.

The post-import templates are simple and useful. The entity post-import hook receives an `LDTKEntityLayer`, can iterate `entity_layer.entities`, and can instantiate project-specific nodes. This is exactly what this project needs for markers like `PlayerSpawn`, `Checkpoint`, `EnemySpawn`, `Hazard`, `Destructible`, `Climbable`, `ExitPortal`, `CameraBounds`, and `GeneratedSocket`.

### Fit For This Project

This is the strongest map authoring candidate because the testbed needs:

- authored side-view rooms,
- typed element placement,
- deterministic conversion to Godot scenes,
- designer-readable maps,
- room/entity metadata,
- import-time validation hooks,
- a path away from script-built rectangle maps.

LDtk's entity model is better aligned to the current element-contract needs than raw TileMap painting. It can store typed fields such as `enemy_type`, `requires_ability`, `socket_id`, `checkpoint_id`, `route_role`, `profile_gate`, and `spawn_cap`.

### Risks

- The importer has not been proven yet against this repo's exact `project.godot`.
- Tile collisions still need either manual TileSet collision editing or a post-import collision workflow.
- The project must define a stable entity naming and field schema before maps multiply.
- LDtk import data should be converted into local stage contracts, not allowed to leak arbitrary LDtk field names everywhere.
- Generated pockets still need runtime assembly; LDtk alone is not procedural generation.

### Recommended Adoption

Adopt as P0 spike, not a blind full migration.

The spike should:

- vendor the importer under `addons/ldtk-importer/` on a branch,
- create one `docs` contract for LDtk entity names and fields,
- create one small LDtk world with 2 or 3 side-view rooms,
- import into Godot,
- add a post-import script or runtime marker resolver that instantiates existing player/enemy/hazard/destructible/interactable scenes,
- verify one camera-followed playable route with ceilings, sides, bottom fill, a checkpoint, one climb element, one enemy, one destructible, and one exit.

Acceptance:

- a non-programmer-readable map source exists,
- the full map is not visible at once in gameplay,
- the imported scene can boot through `.\tools\godot.ps1`,
- element markers instantiate through shared contracts,
- changing a marker in LDtk changes the Godot route without manually editing generated scene internals.

## Deep Dive: YATI

### Relevant Source Inspected

- `GDScript/addons/YATI/TiledImport.gd`
- `GDScript/addons/YATI/Importer.gd`
- `GDScript/addons/YATI/TilemapCreator.gd`
- `GDScript/addons/YATI/TilesetCreator.gd`
- `GDScript/addons/YATI/DataLoader.gd`
- `GDScript/runtime/*`
- `README.md`

### What The Code Actually Does

YATI is an `EditorImportPlugin` for Tiled `.tmx` and `.tmj` maps. The importer creates a `PackedScene` from Tiled input and exposes import options for:

- default filtering,
- class metadata,
- id metadata,
- alternative tile behavior,
- Wangset-to-terrain mapping,
- custom data prefix,
- Tiled project file,
- post processor script,
- saving tilesets to resources.

It supports a broad set of Tiled features: layers, objects, orientations, visibility, opacity, tint, offsets, parallax, tile collisions, tile animations, templates, and custom properties. The README explicitly warns that Godot may freeze during import if "Use Multiple Threads" is enabled for imports, especially with multiple Tiled maps on Windows.

### Fit For This Project

YATI is a serious importer and Tiled is a mature editor. It is better than hand-building maps and would work for tile/object maps.

However, for this project's immediate problem, LDtk is still the better first spike because:

- LDtk entities and fields map cleanly to the typed element-marker contract we need.
- LDtk is often used for platformer/metroidvania-style room authoring.
- The inspected Godot LDtk importer had cleaner local import/boot behavior.
- YATI's broad Tiled feature support is useful but also increases importer complexity.

### Recommended Adoption

Keep as P1 fallback. Use it if LDtk fails the local spike, if the user prefers Tiled, or if a chosen asset pack already includes strong Tiled maps.

Do not spike LDtk and Tiled simultaneously. That would create two authoring contracts before the project has one stable map pipeline.

## Deep Dive: GDQuest Godot 4 Procedural Generation

### Relevant Source Inspected

- `godot4/random_walker/random_walker.gd`
- `godot4/basic_dungeon/03_bonus/generator.gd`
- `godot4/basic_dungeon/03_bonus/room.gd`
- `godot4/mst_dungeon/mst_dungeon.gd`

### What The Code Actually Does

The `random_walker` demo is the most relevant source. It uses hand-designed chunks or rooms, then walks semi-randomly through a grid to create a playable path. The code intentionally prevents broken path choices and backtracking issues by constraining the next step. It then fills remaining cells with side rooms and copies both tilemap data and object instances from authored room templates.

Important behavior:

- generation is seeded with a random number generator,
- route path is stored in `_state.path`,
- empty grid cells are tracked separately,
- path rooms are placed before side rooms,
- walls are placed around the full generated area,
- room objects can be filtered so the start room keeps the player but excludes enemies,
- tilemap data is copied into main and danger layers,
- a camera limit is set from generated grid bounds.

The `BasicDungeonGenerator` creates random rectangular or organic rooms and connects consecutive rooms with corridors. The `mst_dungeon` demo spreads rooms with physics and builds a minimum spanning tree, then reconnects some paths to reduce backtracking.

### Fit For This Project

The algorithms are useful, but the demos are not directly the required final map type.

The current project needs side-view platformer chunks with passability metrics, not top-down or downward dungeon rooms. The relevant idea is the structure:

- authored templates,
- route graph,
- deterministic seed,
- path-first generation,
- side-fill/optional branches,
- boundary walls,
- copied objects plus tile layers,
- camera bounds from generated map bounds.

The random walker should be adapted into a side-view template graph:

- steps should include right, up-right, down-right, vertical shaft, loop-back, optional branch, and gated pocket,
- each template must declare entry/exit sockets and required movement ability,
- route validation must use player movement metrics,
- side rooms must not block the critical path,
- spawners and hazards must obey active/lifetime caps.

### Risks

- Copying the demo directly would bias the map toward top-down/downward rooms and conflict with the user's requested horizontally crafted map with vertical aspects.
- GDQuest assets are CC-BY 4.0, so imported art/audio would need attribution. Code is MIT.
- The demo does not solve combat encounter pacing, profile-specific movement gates, or LDtk-style authoring.

### Recommended Adoption

Use as P0 algorithm reference. Do not vendor code yet.

The next procedural contract should define:

- `RoomTemplateDescriptor`,
- `SocketDescriptor`,
- `TraversalRequirement`,
- `EncounterBudget`,
- `HazardBudget`,
- `GeneratorSeedReport`,
- `RouteValidationReport`.

Then implement a local generator that follows the random-walker path-first concept but uses this project's template descriptors and movement metrics.

## Deep Dive: Ultimate Platformer Controller 2D

### Relevant Source Inspected

- `UltimatePlatformerController.gd`
- `README.md`

### What The Code Actually Does

This is a single `CharacterBody2D` script named `PlatformerController2D`. It exposes many movement features as exported values:

- max speed,
- acceleration and deceleration time,
- directional snap,
- run modifier,
- jump height,
- jump count,
- gravity scale,
- terminal velocity,
- descending gravity factor,
- variable jump height,
- coyote time,
- jump buffering,
- wall jump,
- wall kick angle,
- wall slide,
- wall latch,
- dash type,
- dash count,
- dash cancel,
- dash length,
- corner cutting using three `RayCast2D` nodes,
- crouch,
- roll,
- ground pound,
- basic animation toggles.

The script reads hard-coded input actions:

- `left`
- `right`
- `jump`
- `dash`
- `up`
- `down`
- `roll`
- `latch`
- `twirl`
- `run`

The script also mixes:

- input polling,
- physics,
- animation selection,
- collision shape adjustments,
- dash/roll timers,
- wall latch state,
- exported tuning,
- required child node references.

### Fit For This Project

The feature list is extremely useful as a movement checklist. It directly covers several issues raised in user feedback:

- coyote time,
- jump buffering,
- double/multiple jumps,
- wall jump,
- wall slide/latch,
- dash,
- corner correction,
- crouch/roll,
- ground pound.

However, it should not replace the current player controller as-is. Reasons:

- It assumes fixed action names that conflict with our canonical input contract.
- It is not profile-aware.
- It combines concerns that our docs explicitly separate.
- It ties animation behavior to expected animation names and child nodes.
- It uses broad state flags in one large file, which makes later card/skill/profile modifiers harder.

### Recommended Adoption

Use as P0 reference, not direct adoption.

Port ideas into our controller contract:

- coyote time and jump buffer should remain explicit fields,
- wall slide/latch/jump should be staged into a separate wall traversal component or clearly bounded methods,
- corner correction should be added only after route metrics expose where it matters,
- dash count and dash style should be profile/resource data,
- animation state should emit intents such as `attack_started`, `movement_state_changed`, `wall_latched`, rather than be hard-coded inside movement math.

## Deep Dive: Godot Official Platformer Demo

### Relevant Source Inspected

- `2d/platformer/player/player.gd`
- `2d/platformer/player/gun.gd`
- `2d/platformer/player/bullet.gd`
- `2d/platformer/enemy/enemy.gd`
- `2d/platformer/level/level.gd`
- `gui/input_mapping/ActionRemapButton.gd`
- `gui/input_mapping/KeyPersistence.gd`

### What The Code Actually Does

The official platformer player is intentionally small:

- `CharacterBody2D`,
- walk speed and acceleration,
- jump velocity,
- terminal velocity,
- double jump charge,
- early jump release shortening,
- input suffix for split-screen,
- sprite facing,
- gun shooting,
- animation selection.

The gun spawns a bullet scene with linear velocity and cooldown.

The enemy demo is a simple walking enemy:

- walks until a floor detector or wall condition flips direction,
- has walking/dead state,
- plays animation by state,
- exposes `destroy()`.

The input mapping demo is deliberately minimal:

- `ActionRemapButton` toggles into listening mode,
- captures one key event,
- erases old action events and adds the new one,
- `KeyPersistence` saves a dictionary to `user://keymaps.dat`.

### Fit For This Project

This is a reliable official baseline for small Godot patterns. It is useful for sanity:

- how Godot's own demo uses `CharacterBody2D`,
- simple double jump,
- simple weapon/projectile,
- simple enemy edge detection,
- simple key persistence.

It is too small to satisfy this project's foundation:

- no wall traversal,
- no profile system,
- no typed damage payload,
- no generated route,
- no interaction contract,
- no checkpoint recovery,
- no rich remap conflict handling.

### Recommended Adoption

Use as P0 sanity reference only. Do not build the architecture around the official demo.

## Deep Dive: Input Remapping Options

### KoBeWi ControlsRemap

Relevant source:

- `addons/ControlsRemap/ControlsRemap.gd`
- `addons/ControlsRemap/inputremap.gd`
- `README.md`

This is a very small `Resource`-based remapping system. It:

- reads a configured action list from `ProjectSettings`,
- stores keyboard and joypad button remaps separately,
- supports prefixes for local co-op control schemes,
- stores only non-default differences,
- applies remaps back into `InputMap`,
- restores all defaults or one action's default,
- clones/remap state for cancel/restore flows,
- detects duplicate assignments.

Limitations:

- no full UI,
- physical keycodes are not supported,
- mouse buttons and joypad motion axes are not the main model,
- each action needs keyboard and joypad events if both are expected.

Fit:

This is a strong first adoption candidate because the current project already has a settings popup shell and canonical input map. We do not need a full external settings UI if we can build our own UI around a clean resource contract.

Recommended:

- adopt or replicate this pattern as P0 for persistent remap core,
- keep our settings popup responsible for user-facing layout and Korean/English control labels,
- add duplicate detection and restore defaults,
- explicitly document unsupported input types if the first pass only supports keyboard.

### Maaack Input Remapping

Relevant source:

- `key_assignment_window.gd`
- `input_options_menu.gd`
- `input_actions_list.gd`
- `input_actions_tree.gd`
- `input_helper.gd`
- `AppSettings`/`PlayerConfig` integration from the template stack.

This is a richer UI-based system. It:

- supports list and tree remap modes,
- captures key, mouse button, joypad button, and joypad motion inputs,
- supports single/double/OK confirmation,
- shows conflict messages,
- prevents deleting the last input for an action,
- integrates input icons,
- persists via AppSettings/PlayerConfig,
- can show/hide built-in `ui_` actions.

Local validation:

- import succeeded,
- boot under headless produced repeated `DisplayServer.keyboard_get_keycode_from_physical` errors because headless display server does not support that call.

Fit:

This is useful if we want a ready-made options menu. It is heavier than KoBeWi's resource and drags in UI conventions we may not want.

Recommended:

- keep as P1 upgrade if our own settings popup takes too long,
- avoid importing the full UI until the map/player foundation is no longer the main blocker,
- if adopted, wrap action labels and action groups so our canonical input names remain authoritative.

### Official Godot Input Mapping Demo

Relevant source:

- `ActionRemapButton.gd`
- `KeyPersistence.gd`

This demo proves the simplest possible persistence approach: save a dictionary of action to input event in `user://keymaps.dat` and reapply it on startup.

Fit:

Good for learning, too bare for this project.

Recommended:

- use only as a fallback if both input plugins are rejected.

## Deep Dive: Maaack Godot Game Template

### Relevant Source Inspected

- `README.md`
- `project.godot`
- `addons/maaacks_game_template/base/nodes/autoloads/scene_loader/scene_loader.gd`
- `addons/maaacks_game_template/base/nodes/state/global_state.gd`
- `addons/maaacks_game_template/base/nodes/config/app_settings.gd`
- `addons/maaacks_game_template/base/nodes/config/player_config.gd`
- level loader and pause/options-related extras.

### What The Code Actually Does

This is a full app shell template with:

- main menu,
- options menu,
- pause menu,
- credits,
- loading screen,
- opening scene,
- persistent settings,
- global config autoload,
- keyboard/mouse/gamepad support,
- UI sound and music controllers,
- global state saving,
- level loaders,
- win/lose flow,
- example levels.

Its `project.godot` registers autoloads:

- `AppConfig`,
- `SceneLoader`,
- `ProjectMusicController`,
- `ProjectUISoundController`.

`SceneLoader` wraps threaded `ResourceLoader` loading and changes scenes through an optional loading screen.

`GlobalState` saves and loads `user://global_state.tres` as a `Resource`.

`AppSettings` captures default inputs, applies persisted input events, resets defaults, and manages audio/video settings.

Local validation:

- import succeeded,
- boot hit a parse error in an example menu scene: `main_menu_with_animations.tscn` line 317,
- this is a caution against making it the foundation without a focused spike.

### Fit For This Project

The template solves many shell-level concerns, but the user's pain is currently map, movement, combat identity, enemies, and procedural testbed quality. Replacing the current project shell first would not address that.

The best pieces are:

- settings persistence concepts,
- scene loading,
- pause/options layout,
- input remap UI from the sibling plugin.

### Recommended Adoption

Do not adopt as the project foundation now.

Revisit as P1 after the map authoring spike if:

- settings/pause/scene flow becomes a blocker,
- we need a more complete options menu quickly,
- the testbed route is stable enough that shell UI polish is the next bottleneck.

If adopted later, copy through a narrow wrapper and avoid making gameplay scripts depend on template-specific autoloads.

## Deep Dive: Metroidvania System

### Relevant Source Inspected

- `addons/MetroidvaniaSystem/Scripts/MetroidvaniaSystem.gd`
- `addons/MetroidvaniaSystem/Scripts/MapData.gd`
- `addons/MetroidvaniaSystem/Scripts/MapBuilder.gd`
- `addons/MetroidvaniaSystem/Scripts/SaveData.gd`
- `addons/MetroidvaniaSystem/Scripts/RoomInstance.gd`
- `addons/MetroidvaniaSystem/Scripts/CustomElementManager.gd`
- `addons/MetroidvaniaSystem/Template/Scripts/Modules/RoomTransitions.gd`

### What The Code Actually Does

Metroidvania System provides a map/progression singleton, grid cell data, room scene assignment, room transitions, save data, custom cell creation, map theme rendering, markers, custom elements, cell exploration, object persistence, and room-change signals.

Important concepts:

- `MetroidvaniaSystem` tracks current room, player cell, current layer, discovered cells, room changes, and map updates.
- `MapData.CellData` stores borders, colors, symbol, assigned scene, and overrides.
- `MapBuilder` creates custom cells at runtime, useful for procedural map generation at map-view level.
- `RoomTransitions` listens for room changes and loads new room scenes.
- `CustomElementManager` supports map elements too complex for normal cells, represented as rectangles with origin and data string.

Local validation:

- import ran,
- headless import warned that `PluginRefresher` plugin directory was missing,
- headless exit reported RID/ObjectDB leaks. This needs an interactive editor spike before adoption.

### Fit For This Project

Useful for:

- future minimap,
- world-map visualization,
- explored-cell state,
- room scene association,
- persistent collectible/object markers,
- custom map labels and icons.

Not useful for:

- actual side-view collision geometry,
- platformer jump distances,
- enemy placement,
- procedural physical room assembly.

### Recommended Adoption

Defer to P1/P2.

The current map blocker is the physical stage, not the minimap. Adopt LDtk/imported rooms first. Later, if rooms become metroidvania-like and need map reveal, evaluate Metroidvania System as a presentation/progression layer.

## Deep Dive: LimboAI And Its Demo

### Relevant Source Inspected

- `README.md`
- `bt/tasks/*`
- `bt/tasks/composites/*`
- `bt/tasks/decorators/*`
- `bt/tasks/scene/*`
- `demo/demo/agents/scripts/agent_base.gd`
- `demo/demo/agents/scripts/health.gd`
- `demo/demo/agents/scripts/hitbox.gd`
- `demo/demo/agents/scripts/hurtbox.gd`
- `demo/demo/ai/tasks/pursue.gd`
- demo behavior tree resources for melee, charger, ranged, skirmisher, demon, and summoner agents.

### What The Code Actually Does

LimboAI is a C++ plugin/GDExtension providing:

- behavior trees,
- hierarchical state machines,
- blackboard data,
- editor tree resources,
- visual debugger,
- built-in tasks,
- GDScript custom task support,
- demo/tutorial enemies.

The demo agent code is useful even without adopting the plugin:

- `Health` is a small node with `max_health`, current health, `damaged` signal, and `death` signal.
- `Hitbox` is an `Area2D` with damage and optional knockback, and ignores self-owner hits.
- `Hurtbox` is an `Area2D` that forwards damage to a `Health` node and records attack vector.
- `agent_base` has `move()`, facing updates, knockback over physics frames, animation-driven hurt, death disabling, projectile spawning, and summoning.
- `pursue.gd` shows a clean behavior-tree task: read target and speed from blackboard, select waypoint, move agent, return `RUNNING`/`SUCCESS`/`FAILURE`.

### Fit For This Project

Component ideas fit well. Full plugin adoption is not justified yet.

Use now:

- health/hitbox/hurtbox separation ideas,
- knockback as short physics-frame displacement,
- hit reaction temporarily disabling AI,
- enemy behaviors split into readable actions,
- blackboard-like vocabulary for future enemy state data.

Do not use now:

- full LimboAI as a dependency,
- behavior-tree editor as the first enemy foundation,
- compiled GDExtension pipeline before the testbed map/player loop is stable.

### Recommended Adoption

P0 reference for combat/enemy component refinements.

P2 full plugin candidate if:

- enemy behavior trees become hard to maintain in custom finite-state scripts,
- boss phases require reusable visual behavior authoring,
- the project accepts GDExtension dependency and export-template checks.

## Deep Dive: Dialogic 2

### Relevant Source Inspected

- `README.md`
- high-level addon structure.

### What The Code Actually Does

Dialogic 2 is a large Godot dialogue/RPG/visual-novel addon with:

- timelines,
- character management,
- editor tooling,
- runtime dialogue features,
- docs and tests.

### Fit For This Project

Not a foundation dependency for the current testbed. The testbed needs one or two prompt-based interactions and maybe a simple NPC, not a full dialogue authoring stack.

### Recommended Adoption

Defer.

Use later if:

- shops/rest/forge/NPC conversations become content-heavy,
- branching dialogue matters,
- dialogue authoring needs to be data-driven.

## Cross-Candidate Findings

### No Single Repo Solves The Testbed

The best external packages solve slices:

- map import,
- input remap,
- movement formulas,
- procedural generation ideas,
- enemy AI framework,
- shell UI.

Trying to install one large package as the new base would likely replace one rough prototype with another set of hidden assumptions.

### Map Authoring Is The Highest-Leverage Change

The current testbed is weak mainly because the map is not authored like a real side-view dungeon. External code inspection confirms that mature workflows separate:

- map authoring,
- element markers,
- imported scene generation,
- runtime behavior scripts,
- procedural assembly.

The next serious improvement should create a map pipeline, not another larger script-built stage.

### Persistent Remap Should Be Small First

The user complaint about attack key and awkward controls is concrete. Full options UI is less urgent than making controls configurable. KoBeWi's resource is small enough to adopt without changing the whole UI stack.

### Movement Should Stay Local And Profile-Aware

Ultimate Platformer Controller is feature-rich but too monolithic. The current project needs profile resources, ability flags, movement metrics, and route validation. Those are core contracts and should not be lost to an external controller with hard-coded action names.

### Procedural Generation Must Be Template-Based

GDQuest's random walker validates the direction already in our docs: generated content should assemble authored chunks/templates and validate path rules. It should not be raw tile noise.

### Enemy AI Should Grow In Layers

Current enemy scripts can support MVP archetypes if component boundaries improve. LimboAI should be a future option, not the first answer.

## Final Picked Source Set

### P0: Use In The Next Foundation Spike

1. **LDtk + Godot LDtk Importer**
   - Purpose: primary authored map and element-marker pipeline.
   - Adoption type: install/spike.
   - Why: best fit for typed side-view rooms and import-time entity conversion.

2. **KoBeWi ControlsRemap**
   - Purpose: persistent keyboard/gamepad-button remap core.
   - Adoption type: install or reimplement the small resource pattern locally.
   - Why: small, clear, compatible with existing settings popup shell.

3. **GDQuest Random Walker / Procedural Generation Demos**
   - Purpose: algorithm reference for seeded template graph generation.
   - Adoption type: reference only at first.
   - Why: confirms path-first chunk assembly, not raw noise.

4. **Ultimate Platformer Controller 2D**
   - Purpose: movement feature checklist and formulas.
   - Adoption type: reference only.
   - Why: useful features, but too monolithic and not profile-aware.

5. **LimboAI Demo Components**
   - Purpose: combat component and enemy reaction reference.
   - Adoption type: reference patterns only.
   - Why: `Health`, `Hitbox`, `Hurtbox`, knockback, and AI pause-on-hurt map well to our contracts.

### P1: Keep Ready, But Not First

1. **Maaack Input Remapping**
   - Use if our own settings popup around ControlsRemap is too slow or too weak.

2. **Maaack Godot Game Template**
   - Use if shell/menu/pause/loading/persistent settings become the next bottleneck after map and controller are stable.

3. **Metroidvania System**
   - Use for minimap/world-map/exploration state after physical rooms exist.

4. **YATI**
   - Use if LDtk is rejected and Tiled becomes the authoring editor.

### P2: Later Content Systems

1. **LimboAI full plugin**
   - Use only if enemy/boss behavior complexity outgrows simple scripts.

2. **Dialogic**
   - Use only if NPC/shop/rest/dialogue content becomes substantial.

3. **Unity/Corgi/GDevelop/Construct references from the broader survey**
   - Use as completeness benchmarks, not as engine migration candidates, unless the user explicitly reopens the engine decision.

## Recommended Next Implementation Plan

### Step 1: Write The Map Authoring Contract

Create a strict design doc for the new map pipeline. It should define:

- supported editor for the spike,
- map unit scale,
- room bounds,
- camera bounds,
- required LDtk entity names,
- required entity fields,
- socket/connection vocabulary,
- imported marker-to-scene mapping,
- collision layer rules,
- platform passability rules,
- destructible and interactable marker rules,
- enemy spawn caps,
- checkpoint/respawn marker rules,
- route validation inputs and outputs.

This must be detailed enough to rebuild the map pipeline without looking at code.

### Step 2: Install And Spike LDtk Importer

Add the Godot LDtk Importer to the project in a branch and import one minimal LDtk map.

The first map should include:

- spawn,
- checkpoint,
- camera bounds,
- floor/ceiling/side walls/bottom fill,
- jump gap,
- vertical climb,
- destructible wall or crate,
- NPC or switch interactable,
- at least two enemy spawns,
- hazard,
- exit portal.

### Step 3: Build Marker Resolver

Do not let runtime scripts know arbitrary LDtk details. Add one resolver layer:

- reads imported marker/entity nodes or entity data,
- validates required fields,
- instantiates project scenes,
- logs missing/invalid marker fields,
- emits a stage validation report.

### Step 4: Replace Script-Built Serious Map Content

Keep the current testbed as reference until the imported route is playable. Then move serious map work into imported/authored rooms.

The old script-built stage can remain as:

- emergency baseline,
- unit test scene,
- debug lane,
- or disposable legacy proof.

It should not remain the main map creation path.

### Step 5: Add Persistent Remap

Adopt or reimplement ControlsRemap-style storage:

- tracked actions are canonical project actions,
- settings popup edits actual bindings,
- default restore is available,
- duplicate conflicts are surfaced,
- attack key is configurable,
- saved bindings load at boot.

### Step 6: Movement And Enemy Refinement

Use external references to refine local systems:

- add wall slide/latch/jump as bounded local controller features,
- add corner correction only after it solves a measured route issue,
- convert attack animations/projectiles into cleaner profile-resource data,
- improve enemy hit reaction with knockback and brief AI interruption,
- keep spawner caps strict.

### Step 7: Procedural Pocket After Authored Room Works

Only after imported authored rooms work, adapt the GDQuest-style random walker:

- assemble authored template descriptors,
- validate sockets,
- use movement metrics,
- emit seed reports,
- enforce enemy/spawner/hazard budgets,
- keep generated route deterministic.

## Adoption Guardrails

- Never import a package without recording URL, commit or release version, license, and copied paths.
- External package code must sit behind a wrapper or resolver so the project contract stays ours.
- Do not let editor-specific entity names spread through player/enemy/combat scripts.
- Do not copy CC-BY art/audio without adding attribution.
- Do not adopt a GDExtension dependency before export/build implications are tested.
- Do not start two level-editor pipelines at once.
- Do not replace the profile-aware controller with a generic movement script.
- Do not let procedural generation create routes that bypass movement metric validation.

## Bottom Line

The most appropriate source at the end of this inspection is **Godot LDtk Importer**, because the project's biggest blocker is not a lack of random enemies or another controller script. The biggest blocker is that maps are not being authored through a durable, inspectable side-view dungeon pipeline.

The second most appropriate source is **KoBeWi ControlsRemap**, because control frustration is immediate and its implementation is small enough to integrate without changing the project architecture.

The third most useful source is **GDQuest's random walker procedural generation demo**, not for direct copying, but because it confirms the correct generated-map shape: hand-authored chunks, deterministic path-first assembly, filled side rooms, boundary walls, and camera limits.

Everything else should support those decisions rather than distract from them.
