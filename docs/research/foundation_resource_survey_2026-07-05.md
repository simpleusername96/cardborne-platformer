---
type: evidence
status: archived
created: 2026-07-05
last_reviewed: 2026-07-12
source: Web research and local document/code review on 2026-07-05
topic: Foundation resources, packages, templates, and reference systems for Cardborne production
scope: Evidence for deciding whether to continue current Godot implementation, replace systems, or adopt external resources
related:
  - ../references/GENRE_REFERENCES_AND_ASSETS.md
  - ../design/PROCEDURAL_REGION_GENERATION.md
  - ../architecture/FIRST_SLICE_ARCHITECTURE.md
  - ./external_codebase_deep_dive_2026-07-05.md
---

# Foundation Resource Survey - 2026-07-05

## Purpose

Record external resources and local findings that can guide a testbed rebuild. This document is evidence, not binding product scope. Promote only selected findings into specs or implementation after a spike.

The user goal is not to preserve the current codebase. The goal is to make a decent working game. If an external package, template, asset set, or workflow gives a stronger foundation, it should be evaluated seriously.

Follow-up code-level inspection is recorded in `external_codebase_deep_dive_2026-07-05.md`. Treat that later document as the stronger evidence for what to spike first because it inspects cloned source, Godot import/boot logs, and integration risks.

## Sources

### Local Sources

- `docs/product/2d_platform_action_card_game_prd.md`
- `docs/design/MOTION_TEST_BED_SPEC.md`
- `docs/design/PLAYER_CHARACTER_SYSTEMS.md`
- `docs/design/ENEMIES_TRAPS_GIMMICKS.md`
- `docs/design/MAP_DATA_AND_VISUALIZATION.md`
- `docs/design/PROCEDURAL_REGION_GENERATION.md`
- `docs/design/testbed-plan/FEATURE_PRIORITY.md`
- `docs/references/GENRE_REFERENCES_AND_ASSETS.md`
- Current Godot implementation under `scripts/`, `scenes/`, and typed catalogs under `data/`

### Godot Foundation And Template Sources

- [Godot official demo projects](https://github.com/godotengine/godot-demo-projects)
  - Official MIT demo collection.
  - Useful for baseline Godot patterns, 2D platformer demo, UI, camera, physics, and import sanity.
- [Ultimate Platformer Controller 2D](https://godotengine.org/asset-library/asset/3312)
  - MIT Godot Asset Library package.
  - Advertises coyote time, jump buffering, dash, crouch, roll, wall jump/latch/slide, and presets.
- [Maaack's Godot Game Template](https://github.com/Maaack/Godot-Game-Template)
  - MIT Godot 4.6 template/plugin.
  - Includes main menu, options menus, pause menu, loading, persistent settings, keyboard/mouse and gamepad support, global state, level loading, win/lose flow, example levels, key rebinding, audio/video controls.
- [Maaack's Input Remapping](https://godotassetlibrary.com/asset/QsvlI0/maaack%27s-input-remapping)
  - Godot 4.3+ compatible input remapping plugin.
  - Useful for persistent bindings and conflict-handling comparison.
- [Metroidvania System](https://github.com/KoBeWi/Metroidvania-System)
  - MIT Godot 4.6+ toolkit.
  - Helps with grid-based room/world map design, map presentation, collectible tracking, room scene association, object IDs, and persistence.
- [GDQuest Godot 4 Procedural Generation](https://github.com/gdquest-demos/godot-4-procedural-generation)
  - Godot PCG demos.
  - Includes RandomWalker using hand-designed chunks, BasicDungeonGenerator for rooms/corridors, ModularWeapons, and infinite-world demos.
- [LimboAI](https://github.com/limbonaut/limboai)
  - MIT Godot 4 behavior tree and hierarchical state machine plugin.
  - Includes editor, visual debugger, blackboard, demo/tutorial, GDScript task/state support.
- [Dialogic 2](https://github.com/dialogic-godot/dialogic)
  - MIT Godot dialogue/RPG/character addon, Godot 4.3+.
  - Useful later for NPC/dialogue-heavy flows, not required for current testbed.
- [Dialogue Manager for Godot](https://github.com/nathanhoad/godot_dialogue_manager)
  - Godot dialogue addon alternative.
  - Useful later if text-script dialogue is preferred over visual editing.

### Map Authoring And Level Editor Sources

- [LDtk](https://ldtk.io/)
  - Free, open-source 2D level editor from the director of Dead Cells.
  - Supports worlds, entities with custom typed properties, auto-rendering rules, platformer/top-down focus, JSON export, Aseprite support, Tiled export.
- [Godot LDtk Importer](https://godotengine.org/asset-library/asset/2181)
  - MIT Godot 4 importer.
  - Imports `.ldtk` files into scenes, auto-reloads on saved changes, supports post-import customization.
- [Tiled Map Editor Automapping](https://doc.mapeditor.org/en/stable/manual/automapping/)
  - Automapping places/replaces tiles from rules, can automate decoration and correct mistakes.
  - Supports rule files, input/output layers, random output indexes, custom properties, and dynamic automapping while drawing.
- [YATI - Yet Another Tiled Importer for Godot 4](https://github.com/Kiamo2/YATI)
  - MIT Godot 4 importer for Tiled `.tmx`/`.tmj`.
  - Supports many Tiled features, layers, objects, custom properties, collisions, animation limits, templates, and runtime packages.

### Non-Godot Engine And Builder Sources

- [Unity 2D Game Kit](https://learn.unity.com/project/2d-game-kit)
  - Official Unity learning project.
  - Presents Explorer: 2D as mechanics, tools, systems, assets, and a game example that can be hooked up without writing code.
  - Useful as a completeness benchmark for platformer components even if not adopted.
- [Corgi Engine](https://corgi-engine-docs.moremountains.com/contents-of-the-asset.html)
  - Unity 2D/2.5D platformer framework.
  - Includes character abilities, AI, weapons, health/damage, inventory, gravity, collisions, respawn, rooms, moving platforms, feedback, cameras, keys/doors/chests, loot, save/load, procedural systems, and many demos.
  - Paid and Unity-specific, so best used as a feature completeness reference unless engine migration is considered.
- [TopDown Engine](https://topdown-engine.moremountains.com/)
  - Unity top-down framework for dungeon crawlers, action-adventure, beat-em-up, and shooter games.
  - Useful for generic action-game systems such as inventory, character/AI architecture, and extensible abilities, not a direct side-view platformer fit.
- [Phaser Examples](https://phaser.io/examples)
  - Large example browser for Phaser categories including animation, camera, input, physics, plugins, scenes, tilemap, tweens, and game elements.
  - Useful for simple, isolated mechanics references.
- [GDevelop game examples and templates](https://gdevelop.io/game-example)
  - Hundreds of free and premium templates, including Platformer, Roguelite, Action Platformer Pixel, Metroidvania Template, game-feel demo, and other genres.
  - Useful for content inventory and no-code structure comparison.
- [Construct 3 Custom Controls template](https://relixes.itch.io/custom-controls-for-construct-3)
  - Template for multiple input sources, multiple controls, reassignable persistent inputs, config file, debug layout, and action-state functions.
  - Useful as a strong input abstraction checklist.
- [GameMaker first platformer tutorial](https://gamemaker.io/en/tutorials/your-first-platformer)
  - Official beginner complete-game tutorial.
  - Useful for minimal end-to-end platformer loop structure: player, hazard, goal, levels, background, room flow.

### Assets And Placeholder Art Sources

- [Kenney Pixel Platformer](https://kenney-assets.itch.io/pixel-platformer)
  - CC0 package with platformer tiles, environments, blocks, items, HUD elements, characters, enemies, over 200 sprites, tile sheets, separate sprites, and Construct 3 sample game.
- [Kenney Platformer Packs](https://kenney.nl/assets/platformer-kit)
  - CC0 assets that work across Godot, Unity, Unreal, and other engines.
  - Useful for coherent placeholder visuals.
- [OpenGameArt CC0 Tiles and Tilesets](https://opengameart.org/content/cc0-tiles-tilesets)
  - Collection of CC0 platformer tiles including temple, cave, dungeon, sci-fi, castle, and nature tilesets.
  - Requires individual asset verification before import.
- [OpenGameArt CC0 Resources](https://opengameart.org/content/cc0-resources)
  - Broader CC0 collection pool.
  - Useful for effects and UI placeholders after license verification.

## Findings

### Current Codebase

- The current implementation proves many contracts exist: input map, HUD/settings shell, profiles, movement metrics, damage payloads, enemies, hazards, destructibles, interactables, checkpoints, camera bounds, generated route, and validation clear gate.
- The current implementation is too script-built and rectangle-heavy to become a good map foundation without a level-authoring change.
- The current code's strongest parts are conceptual boundaries and quick runtime proof, not presentation, level design, animation quality, or polished feel.
- The current code can be discarded after its behavior is captured in stricter docs.

### Godot Remains Reasonable

- Godot has enough open-source examples, plugins, and asset-library entries to continue without switching engines.
- Godot-native packages cover the main weak areas:
  - platformer movement references,
  - menus/settings/remapping,
  - metroidvania room/map tooling,
  - procedural generation examples,
  - AI/state machines,
  - dialogue systems,
  - level editor import pipelines.
- Rewriting in Unity or a no-code tool may speed up some systems but would discard existing Godot docs/data/scripts and force a larger engine decision.

### Biggest Missing Foundation Pieces

The current project lacks a mature version of these common platform-action systems:

- tile/room-based map authoring pipeline,
- coherent placeholder art and tiles,
- animation-state and attack-motion pipeline,
- game-feel feedback layer: hit stop, screen shake, flash, particles, sound cues,
- persistent key remapping,
- robust enemy state machine or behavior tree tooling,
- isolated encounter lab for enemy/hazard testing,
- reusable generated room/template data model,
- license/import log for external assets,
- automated gameplay validation beyond boot/import checks.

### External Resources Should Not Be Copied Blindly

- Full frameworks can speed up work but often impose their own architecture.
- For this project, broad frameworks are best treated as:
  - feature checklists,
  - local spike candidates,
  - examples of state/data breakdown,
  - benchmark of expected completeness.
- Code should be adopted only through a wrapper or replacement plan that preserves the rebuild contract.

## Candidate Resource Matrix

| Resource | Category | License/cost signal | Fit | Recommended use |
| --- | --- | --- | --- | --- |
| Godot official demos | Godot examples | MIT | High | Reference and small code pattern checks. |
| Ultimate Platformer Controller 2D | Godot movement | MIT | High | Spike against current controller feel; possibly borrow concepts or replace. |
| Maaack Game Template | Godot menus/settings | MIT | High | Spike for settings, pause, remap, persistent config, scene loading. |
| Maaack Input Remapping | Godot input | likely MIT/Godot Asset Library listing | High | Spike for input remap instead of custom system. |
| Metroidvania System | Godot map/progression | MIT | High | Spike for room map, object IDs, persistence, map overview tools. |
| GDQuest PCG demos | Godot procedural | open source | High | Reference for chunk-based generation and dungeon generator. |
| LDtk | level editor | free/open source | High | Spike as primary side-view room authoring tool. |
| Godot LDtk Importer | Godot importer | MIT | High | Spike with one test room and entity import. |
| Tiled | level editor | free/open source | Medium-high | Compare against LDtk for tile workflow. |
| YATI | Godot Tiled importer | MIT | Medium-high | Spike if Tiled beats LDtk for authoring. |
| LimboAI | Godot AI/state | MIT | Medium | Spike if enemy complexity grows beyond simple scripts. |
| Dialogic 2 | Godot dialogue | MIT | Later | Defer until NPC/shop/dialogue needs exceed simple interactables. |
| Unity 2D Game Kit | Unity kit | Unity ecosystem | Reference only | Benchmark what a complete platformer kit includes. |
| Corgi Engine | Unity framework | paid/proprietary | Reference only now | Use as feature completeness checklist; not direct adoption. |
| TopDown Engine | Unity framework | paid/proprietary | Low direct, medium concept | Reference for inventory/AI/action-game systems. |
| Phaser examples | JS framework examples | open examples | Reference only | Isolated mechanic examples, not architecture. |
| GDevelop templates | no-code templates | mixed free/premium | Reference only | Feature inventory and quick genre comparison. |
| Construct custom controls | no-code template | name-your-price | Reference only | Strong input abstraction checklist. |
| Kenney Pixel Platformer | asset pack + sample | CC0 | High | Import candidate for coherent placeholder tiles/HUD/entities. |
| OpenGameArt CC0 tiles | asset pool | CC0 collection | Medium | Secondary asset pool after per-asset verification. |

## Recommended Next Spikes

These should be separate, small, reversible spikes. Do not merge large package imports directly into the main project before evaluating them.

### Spike 1 - Level Authoring Pipeline

Goal: decide how real maps should be authored.

Test candidates:

- Godot `TileMapLayer` only,
- LDtk + Godot LDtk Importer,
- Tiled + YATI.

Acceptance:

- Build one compact side-view dungeon room with ground, walls, one-way platforms, hazard marker, enemy marker, interactable marker, and exit marker.
- Import or instantiate it in Godot.
- Preserve custom properties for element IDs and room sockets.
- Confirm collisions and entity markers are usable.
- Confirm the workflow is faster and clearer than script-building rectangles.

Recommendation before spike: LDtk first, because it is modern, side-view/top-down focused, supports typed entities, worlds, JSON, and has a Godot 4 importer.

### Spike 2 - Movement Controller Comparison

Goal: compare current controller against a known platformer controller.

Test candidate:

- Ultimate Platformer Controller 2D.

Acceptance:

- Implement or run a small movement room with coyote, buffer, dash, crouch, wall slide/latch/jump, and corner correction.
- Compare feel and code complexity to current controller.
- Record whether to replace current controller, borrow ideas, or keep current with tuning.

Recommendation before spike: reference and compare first. Full replacement may break existing profile/damage/climb contracts unless wrapped.

### Spike 3 - Menus, Settings, And Key Remapping

Goal: stop hand-rolling settings if a mature Godot template solves it.

Test candidates:

- Maaack Game Template,
- Maaack Input Remapping.

Acceptance:

- Persistent remap works for keyboard.
- UI shows actual bindings.
- Conflict handling is acceptable.
- Pause/settings input does not leak into gameplay.
- Plugin can live isolated under `addons/` or equivalent.

Recommendation before spike: high-value adoption candidate.

### Spike 4 - Placeholder Art Baseline

Goal: replace abstract rectangles with coherent readable prototype assets.

Test candidates:

- Kenney Pixel Platformer,
- Kenney platformer/UI/input packs,
- OpenGameArt CC0 dungeon/cave/castle tiles after verification.

Acceptance:

- One tile set can represent solid ground, walls, one-way platforms, hazard, gate, destructible, enemy placeholder, player placeholder, HUD icons, and prompts.
- License and source recorded in an asset log.
- Art improves readability without forcing final art direction.

Recommendation before spike: use one Kenney CC0 source family first to avoid mismatched prototype visuals.

### Spike 5 - Enemy AI Structure

Goal: decide when simple scripts stop being enough.

Test candidates:

- local simple state scripts,
- Godot-native finite state machine pattern,
- LimboAI behavior tree/HSM.

Acceptance:

- Recreate Charger or Leaper with clear state transitions.
- Debug current state during runtime.
- Reset/respawn works.
- The implementation does not make simple enemy authoring slower.

Recommendation before spike: keep local scripts for immediate enemies; spike LimboAI only when enemy count/pattern complexity grows.

### Spike 6 - Generated Template Assembly

Goal: replace ad hoc generated route construction with reusable template data.

Test candidates:

- GDQuest RandomWalker chunk method,
- local room/segment graph generator from docs,
- LDtk-authored room templates assembled by sockets.

Acceptance:

- Same seed builds same sequence.
- Template sockets connect cleanly.
- Route passability validates against movement metrics.
- Enemy/hazard/reward budgets stay within limits.
- Invalid routes fail loudly and fall back safely.

Recommendation before spike: use local generator with GDQuest chunk-generation concepts as reference.

## Recommended Documentation Changes

Completed in this pass:

- Create `docs/design/TESTBED_REIMPLEMENTATION_CONTRACT.md` as the strict rebuild contract.
- Keep this document as evidence for resource evaluation.

Still recommended:

- Add `docs/research/asset_import_log.md` before importing assets.
- Add `docs/design/LEVEL_AUTHORING_PIPELINE.md` after the level editor spike chooses Godot TileMapLayer, LDtk, Tiled, or hybrid.
- Add `docs/design/GAME_FEEL_AND_FEEDBACK_CONTRACT.md` before implementing hit stop, screen shake, sound cues, and attack VFX.
- Add `docs/design/ENCOUNTER_LAB_SPEC.md` if enemy/hazard testing splits from the main dungeon testbed.

## Recommendations

1. Do not continue expanding the current script-built map as the main foundation.
2. Keep Godot as the default engine until an engine migration decision is explicitly made.
3. Use the current code only as a working proof and migration reference.
4. Run short external-resource spikes before importing large frameworks.
5. Prioritize level authoring and placeholder art first, because those directly address the worst current quality gap.
6. Prioritize input remapping/settings second, because it is common, user-facing, and already solved by Godot templates.
7. Keep enemy logic local until complexity justifies LimboAI or a state machine plugin.
8. Treat Unity/Corgi/GDevelop/Construct/Phaser as feature completeness benchmarks, not immediate migration targets.

## Limitations

- Sources were inspected from public pages and search results; no external packages were downloaded or run in this pass.
- Some packages may have changed versions after this survey.
- License compatibility must be checked again at import time.
- Paid/proprietary packages were not evaluated for actual code access.
- This evidence does not approve any dependency import by itself.
