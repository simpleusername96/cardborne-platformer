---
type: evidence
status: active
source: Web research on 2026-07-01
topic: Godot platformer RPG-lite references and asset candidates
scope: Preimplementation research for Cardborne Platformer
---

# Genre References And Asset Candidates

## Purpose

Collect implementation references, UI/UX standards, code examples, and asset candidates for a Godot 4.x 2D action platform RPG-lite. This document is evidence, not binding product scope. Promote only selected findings into active specs after review.

## Sources

### Godot Standards

- [Godot 2D movement overview](https://docs.godotengine.org/en/stable/tutorials/2d/2d_movement.html)
  - Use for input-map naming and `CharacterBody2D` movement examples.
- [Godot CharacterBody2D physics tutorial](https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html)
  - Use for `move_and_slide`, collision response, and physics-process placement.
- [Godot TileMapLayer docs](https://docs.godotengine.org/en/stable/classes/class_tilemaplayer.html)
  - Use for Godot 4.7 tile-based stage implementation. TileMapLayer replaces the older multi-layer TileMap approach.
- [Godot keyboard/controller UI navigation](https://docs.godotengine.org/en/stable/tutorials/ui/gui_navigation.html)
  - Use for menu focus, controller navigation, and avoiding gameplay input conflicts with `ui_*` actions.

### Code References

- [Official Godot 2D Platformer demo](https://github.com/godotengine/godot-demo-projects/tree/master/2d/platformer)
  - Useful for side-scrolling player controller, enemies, moving platforms, coins, camera bounds, keyboard/gamepad controls, and pause menu.
  - Repository license: MIT.
- [GDQuest beginner 2D platformer project](https://github.com/gdquest-demos/godot-3-beginner-2d-platformer)
  - Useful for connected levels, pass-through platforms, coins, enemies, title screen, pause menu, and score counter.
  - Repository license: MIT.
  - Caution: Originally Godot 3; use the Godot 4 port only as reference.
- [KidsCanCode Godot 4 platform character recipe](https://kidscancode.org/godot_recipes/4.x/2d/platform_character/index.html)
  - Useful for controller fundamentals, acceleration/friction, and `CharacterBody2D` setup.

### Procedural Generation References

- [Procedural Content Generation in Games](https://books.google.com/books/about/Procedural_Content_Generation_in_Games.html?id=-IdJDQAAQBAJ)
  - Useful taxonomy for PCG methods including grammar-based, search-based, constraint-based, dungeon, and level generation.
- [Adventures in Level Design: Generating Missions and Spaces for Action Adventure Games](https://dl.acm.org/doi/pdf/10.1145/1814256.1814257)
  - Useful for separating mission structure from spatial layout in action-adventure levels.
- [Constructive Generation Methods for Dungeons and Levels](https://antoniosliapis.com/articles/pcgbook_dungeons.php)
  - Useful summary of graph grammar approaches that first generate mission graphs, then generate spaces.
- [Graph-based Generation of Action-Adventure Dungeon Levels using Answer Set Programming](https://www.pcgworkshop.com/archive/smith2018graphbased.pdf)
  - Useful for lock/key graph constraints and validating action-adventure dungeon progression.
- [Building the Level Design of a Procedurally Generated Metroidvania](https://www.gamedeveloper.com/design/building-the-level-design-of-a-procedurally-generated-metroidvania-a-hybrid-approach-)
  - Useful production discussion of using graph instructions to control level length, biome character, labyrinthine density, and exits.

### Asset Candidates

Preferred source for first imports: Kenney CC0 packs. They have clear licensing, consistent style, and enough UI/platformer coverage for a prototype.

- [Kenney New Platformer Pack](https://kenney.nl/assets/new-platformer-pack)
  - CC0. Candidate for tiles, characters, and general 2D platformer placeholders.
- [Kenney Platformer Art Deluxe](https://kenney.nl/assets/platformer-art-deluxe)
  - CC0. Large side-scroller tile and prop set.
- [Kenney Platformer Pack Medieval](https://kenney.nl/assets/platformer-pack-medieval)
  - CC0. Strong fit for fantasy ruin/castle placeholder stages.
- [Kenney Roguelike Characters](https://kenney.nl/assets/roguelike-characters)
  - CC0. Candidate for starter class icons, NPCs, and simple enemy placeholders.
- [Kenney UI Pack](https://kenney.nl/assets/ui-pack)
  - CC0. Generic UI panels, buttons, and sliders.
- [Kenney UI Pack - Adventure](https://www.kenney.nl/assets/ui-pack-adventure)
  - CC0. Better theme fit for fantasy shop/card/rest UI.
- [Kenney Input Prompts](https://kenney.nl/assets/input-prompts)
  - CC0. Candidate for keyboard, mouse, and controller prompt glyphs.
- [Kenney Game Icons](https://kenney.nl/assets/game-icons)
  - CC0. Candidate for coins, materials, equipment slots, and card tags.
- [OpenGameArt CC0 Resources](https://opengameart.org/content/cc0-resources)
  - Collection page includes useful candidate categories such as spikes, slimes, RPG UI buttons/icons, tilesets, props, and effects.
  - Caution: verify every individual item page before import because collection pages can drift or include mixed metadata.

## Findings

- Godot official docs support the current plan to use `CharacterBody2D`, `move_and_slide`, Input Map actions, `Control` focus, and `TileMapLayer` for Godot 4.7.
- The official Godot 2D Platformer demo overlaps strongly with this project: player controller, enemies, moving platforms, coins, pause menu, camera bounds, keyboard/gamepad controls.
- Procedural metroidvania-style generation should start with mission/room graph constraints, not raw random tile placement.
- Lock/key, shortcut, and boss access constraints must be validated after generation so the map is always winnable.
- Kenney CC0 packs are the safest first asset source because they cover platformer tiles, UI, prompts, icons, and character placeholders without attribution requirements.
- OpenGameArt is useful as a broader search pool, but each asset needs individual license verification before import.
- The first slice should keep imported assets as placeholders until a durable art direction is chosen.

## Recommendations

- Do not import third-party assets directly into `art/` until a short asset-import policy and license log exists.
- Start with one coherent CC0 source family, preferably Kenney, to avoid mismatched prototype visuals.
- Use external code references as examples, not as copied architecture. Preserve this repo's responsibility split from `AGENTS.md`.
- For UI implementation, configure focus neighbors and initial focus explicitly for every modal and menu.
- For maps, use `TileMapLayer` per logical layer: solids, one-way platforms, hazards, decorative background, and markers.

## Limitations

- No assets were downloaded or committed in this pass.
- Commercial game references such as Dead Cells, Rogue Legacy, Skul, Hollow Knight, or MapleStory-style bosses are useful design inspiration but are not asset/code sources.
- This document records candidates and source guidance; it does not approve final art direction.
