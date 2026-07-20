---
type: record
status: active
owner: BK
created: 2026-07-21
source: Codex session 019f5f8c-1961-7fb0-950e-4adda7545294
topic: Complete owner-feedback chronology for Cardborne product pivots
related:
  - ./README.md
  - ./03-latest-product-hypothesis.md
---

# Owner Feedback History

## Context

This is a chronological record of every substantive direction in the session.
Transport-only messages such as `continue`, environment blocks, repeated
instruction injection, and push/checkout acknowledgements are not treated as
product decisions. Rejected attempts remain here because they explain why the
current direction exists.

## Decision

No single earlier phase should be read as the final product. The latest state is
a vehicle-led, manually targeted shooter hypothesis whose presentation and meta
structure are still being decided.

## Rationale

The project moved repeatedly because visual production cost, weak combat feel,
map readability, traversal failures, and unclear product identity were discovered
through implementation and owner playtesting.

## Consequences

- Earlier art and runtime work is evidence or candidate infrastructure, not an
  obligation to preserve its gameplay contract.
- The accepted drowned-ruin flat-color art direction remains valuable.
- The next implementation must be a small gameplay experiment, not another broad
  content or UI rollout.

## Chronology

### 1. UI branch and world-art direction — 2026-07-14

- The owner first asked whether the UI-only branch work had been documented and
  asked that the previously approved visual reference be used as the standard.
- Background art was to establish the overall map atmosphere, while foreground
  terrain, traps, and interactable objects had to be reusable components.
- Stateful components were expected to use image-based bases and overlays. The
  owner asked to see two actual state-overlay examples in an HTML-style report.
- The background needed to be much larger than the viewport. A single SVG or a
  viewport-sized fake panorama was explicitly rejected.
- Before further production, the owner demanded research into how comparable
  games handle large connected backgrounds, modular foregrounds, and limited
  source-image resolution.
- The owner preferred simpler art because added detail produced dot-like noise,
  repeated micro-patterns, stains, and inconsistent surfaces.
- Connected background panels were expected to be generated sequentially from
  the preceding image, with deliberately simple seams.
- Terrain should not be a tiny repeated tile grid. The discussion moved toward a
  finite set of larger terrain/chunk silhouettes that could be combined without
  obvious repetition.
- Multiple background/style and terrain-sheet explorations were requested. The
  owner rejected results that varied terrain with unrelated colors; variation
  should stay within a close color family and optional detail should be layered
  separately.
- The final stated style boundary was flat color, no outlines, minimal stains,
  minimal texture noise, and no pointillist/repeating detail.
- The owner supplied a dark drowned-ruin/foundry action-game reference and asked
  for three connected 4:3 backgrounds plus one terrain-component sheet.

### 2. UI mockups, asset boundaries, and branch integration — 2026-07-14 to 16

- Final screen mockups were requested before component implementation, covering
  the screens represented by the then-current main branch.
- The owner questioned whether every UI element needed raster art. The resulting
  boundary was: buttons, panels, frames, and simple icons are appropriate for SVG
  or legally safe reusable primitives; bespoke backgrounds, characters, bosses,
  equipment illustrations, and atmospheric art require raster assets.
- The owner asked to apply suitable assets, not merely inventory or discuss them.
- UI work needed to merge into the gameplay-centered main branch without making
  the UI branch authoritative for gameplay logic.
- A separate UI branch was created because main had concurrent work. The owner
  repeatedly checked whether visual assets, background images, and actual screens
  had been applied rather than only mocked up.
- The art style and theme were to be stored as image references plus explicit
  text guidelines and then used to create menu, preparation, settings, forge, and
  result backgrounds. Backgrounds and panels were to remain distinct asset roles.
- The owner asked for a complete list and production of assets that SVG could not
  represent well, followed by inspection of the whole game to decide which
  existing assets were usable and how many new assets were truly required.
- A Figma-board suggestion was rejected as unexplained overhead. The owner wanted
  directly usable assets applied first and a concrete list of remaining needs.
- The owner requested a master-UI overhaul plan, then implementation, completion,
  checkout of the latest branch, production build verification, and a working
  start screen. A visually unchanged build and nonfunctional buttons were
  explicitly unacceptable.

### 3. Side-view gameplay audit and retirement — 2026-07-16 to 17

- The owner reported poor maps: excessive height, hard-to-reach walls, awkward
  rope descent, unclear attack mapping, broken forge/merchant popups, only one
  potion, ineffective defense, enemy projectiles passing through terrain, idle
  enemies, and jump enemies trapped by one fixed trajectory.
- Enemy intent did not need persistent path/trajectory UI if behavior itself was
  reasonable and readable.
- Ordinary ranged enemy projectiles were required to stop on terrain.
- Moving/jumping enemies needed to choose reachable destinations and generate a
  trajectory to the destination rather than repeat one canned arc.
- Most importantly, the owner stated the game was not fun and requested analysis
  before more fixes.
- Map-related prior sessions were consulted. The owner asked for plans to be
  strengthened with those discussions and wanted a concrete explanation of what
  a rebuilt map would change.
- Universal kill gates were rejected. The owner also requested a minimap with
  player position, fog for unvisited areas, and normal useful map markers.
- A ChatGPT Pro PR containing gameplay-analysis documents was reviewed and merged
  as source material. The owner expected its cross-game analysis to be explained
  in plain language rather than simply listed.
- After watching Bastion and Hades gameplay, the owner accepted that the game
  might require a restart. The side-view implementation was retired while the
  art direction and selected product identities were retained.

### 4. Humanoid isometric action-RPG proof — 2026-07-17

- The owner requested research and a decision-complete plan for an isometric
  action RPG, then local final-screen images based on that plan.
- A playable map and basic character were requested. An early result was rejected
  because it did not resemble the approved mockup.
- The owner allowed Three.js, Godot, or appropriate external sources, leaving the
  technology choice to implementation. Godot native 3D became the runtime.
- Keyboard controls were expected around arrow keys, Shift, Space, and the lower
  left letter keys.
- The initial control implementation was judged inadequate. Facing direction was
  unclear, and the owner asked whether nearby-enemy facing assistance was a genre
  convention. The owner requested open-source/reference analysis rather than an
  ungrounded targeting system.
- The proposed humanoid binding became Shift melee, `Z` ranged, `X` guard, and
  Space dash. Movement direction needed visible world feedback.
- The arena needed to be larger than one screen. Camera-facing walls had to be
  low, absent, cut away, or transparent so the player stayed visible.
- The owner asked to keep 3D objects/collision while using 2D image textures and
  camera-facing character sprites.
- Walking, melee, ranged, guard, lateral walking, and dash presentation were all
  expected to use appropriate raster sprite states/effects.

### 5. Connected Flooded Works map and enemies — 2026-07-17 to 19

- The owner asked to extend the first room into connected same-theme maps, add
  multiple moving enemies, and later add an upgrade system using materials or
  cards from props, monsters, and bosses.
- Audio could exist but needed sensible default behavior and a settings panel.
- Map/enemy work was prioritized; progression could be documented for later.
- The requested floor design included connected rooms or door transitions,
  monster placement, attack interactions, destructible crates, healing pickups,
  loose items, and props.
- Concern about unreliable map assembly led to a Tiled workflow: Tiled authored
  the ground and sockets; 3D walls/props and image surfaces remained separate.
- Because Tiled has no built-in art library for the project, a project-owned
  modular authoring kit was created and added to the active plan.
- The generated floor then exposed concrete failures: the third-room entry was
  obstructed, one enemy could become unreachable, enemy HP was unclear, ranged
  ammo rules were unclear, and floor texturing looked like plain color.
- Entry lanes were cleared, enemy health bars and combat-state readability were
  added, and ordinary room transitions were changed so living enemies could not
  permanently block stage progress.

### 6. Sprite-production constraint and possible cancellation — 2026-07-19

- The owner observed that the 2D character changed apparent size during motion
  and asked for current, inspectable workflows for stable isometric sprites.
- A 3D-rig-to-2D-render workflow was discussed as the most stable way to keep
  scale, pivot, direction, and animation consistent across walking, attacks,
  blocking, and future skills.
- The owner did not have Blender and questioned whether the laptop and available
  resources could support that pipeline.
- The owner considered dropping the project or drifting again because even a
  minimum humanoid action-game visual set appeared expensive.
- The owner emphasized that this project had already pivoted away from a 2D
  side-view game, so returning without a stronger reason would repeat history.

### 7. Vehicle-led direction and reference analysis — 2026-07-20

- The owner proposed retaining the current camera/world direction while replacing
  the animation-heavy human with a vehicle such as a ship or tank.
- Existing humanoid systems were not assumed reusable. The owner requested a
  detailed functional/design analysis of famous references, universal enjoyable
  elements, and production concerns. The durable research was to be English and
  the explanation to the owner concise Korean.
- Three local concept images were requested to show a recommended exploration,
  combat, and boss/build direction.
- The owner asked where files were stored and requested duplicate cleanup. Exact
  repo duplicates were consolidated; external generated-image/runtime cache
  cleanup remained incomplete when shell deletion was blocked in that turn.
- Exploration and ordinary combat were expected to occur in one continuous map.
  Field bosses and dedicated stage bosses should be distinct.
- Simple collection and crate breaking were judged too shallow to justify an
  exploration pillar. Exploration puzzles were therefore deferred.
- The immediate target became one stage covering map, controls, UI/UX, level or
  equipment upgrades, and a skill system.

### 8. Latest shooter simplification — 2026-07-20 to 21

- Controls should feel like a simple shooting game.
- The primary weapon should be rapid and fired intentionally by the player.
- A secondary weapon should be passive: fire at nearby targets automatically or
  trigger on a timer.
- One powerful area skill should use a cooldown and activate with `Z`.
- A separate held defense action may be unnecessary, but **Space dash is
  required** and should support both evasion and aggressive movement.
- Field pickups should produce immediate effects: healing, attack boost, speed
  and ram damage with reduced collision damage, and a barrier that keeps enemies
  away or clears projectiles.
- The enemy roster should mix moving enemies with fixed turrets, proximity
  attackers, traps, and other dangerous map elements.
- Chests or stage completion should offer several cards that grant new equipment,
  upgrade current equipment, or change weapon behavior.
- The game should not become a Vampire Survivors clone. Its intended difference
  is manual targeting and the ability to identify and preemptively destroy the
  most dangerous map elements.
- Isometric/hybrid presentation versus flat top-down 2D remains undecided.
- A returnable base/garage was proposed for loadout changes, repairs, permanent
  upgrades, settings, and deployment, but its benefits and scope need validation.

## Related

- The repository state corresponding to this history is in
  [02-current-repository-state.md](./02-current-repository-state.md).
- The latest proposal distilled from the final discussion is in
  [03-latest-product-hypothesis.md](./03-latest-product-hypothesis.md).
