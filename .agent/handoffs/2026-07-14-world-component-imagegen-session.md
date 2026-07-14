---
type: handoff
status: active
owner: BK
created: 2026-07-14
last_reviewed: 2026-07-15
topic: World-component art planning, image-generation experiments, owner corrections, and continuation state
scope: Terrain, map components, hazards, field items, temporary gallery, and the presentation-only worktree
source: Side conversation through 2026-07-14, repository state at `c820f1e`, and generated preview files listed below
related:
  - ../execplans/2026-07-13-component-ui-foundation.md
  - ../../docs/design/GAME_COMPONENT_ART_SYSTEM.md
  - ../../docs/design/WORLD_COMPONENT_IMAGE_PRODUCTION_PLAN.md
  - ../../docs/design/references/README.md
---

# World Component Imagegen Session Handoff

## Integration Note

The presentation branch was integrated into `master` as draft design evidence on
2026-07-15. Future implementation must branch from the current `master`; the worktree
and commit IDs below describe the historical experiment, not a gameplay or product
authority. This handoff remains active only because the production raster-art plan,
terrain language, and accepted component sheets are still unresolved.

## Start Here

This is the current continuation record for a new Codex session. Read it before using
the older image-production call matrix.

- Worktree: `D:\npjt\cardborne-platformer-component-ui-preproduction`
- Branch: `codex/component-ui-preproduction`
- Last committed revision before this handoff: `c820f1e docs: plan world component image production`
- Parent gameplay worktree: `D:\npjt\cardborne-platformer`
- Generated-preview root:
  `C:\Users\BK\.codex\generated_images\019f5e78-9f1b-7341-8324-f406a0c4a52f`

No generated image is accepted production art. No image was copied into `art/`, made
transparent, aligned to a real tile grid, imported into Godot, or referenced by game
code. No runtime scene, gameplay system, collision, or UI implementation changed in
this side conversation.

There is no image-generation process intentionally left running. The last interrupted
retry completed its image before the process was terminated.

## Owner Objective

The owner wants a presentation/design workstream for:

- map terrain and reusable terrain patterns;
- hazards and traversal/environment components;
- field items, chests, and material nodes;
- a temporary local HTML gallery for comparing component art;
- a production path that makes a whole map coherent, not a collection of unrelated
  polished objects.

Character, weapon, equipment, skill-tree, inventory, and combat-system work is being
handled separately in the main worktree. Do not absorb or overwrite that work from
this branch.

The owner is not familiar with formal game-UI/art production terminology. Explain the
workflow in short, concrete terms with examples before introducing specialist terms.

## Existing Branch Artifacts

The presentation branch already contains:

- `d547f69 docs: define component and UI production foundation`
- `c820f1e docs: plan world component image production`
- `docs/design/GAME_COMPONENT_ART_SYSTEM.md`
- `docs/design/UI_VISUAL_SYSTEM.md`
- `docs/design/WORLD_COMPONENT_IMAGE_PRODUCTION_PLAN.md`
- `docs/research/component_ui_foundation_research_2026-07-13.md`
- `.agent/execplans/2026-07-13-component-ui-foundation.md`
- generated direction boards under `docs/design/references/`

The high-level component boundaries and visual direction remain useful. The detailed
per-asset image-generation call matrix in
`WORLD_COMPONENT_IMAGE_PRODUCTION_PLAN.md` requires revision after the experiments
and owner feedback documented here.

## Stable Visual Direction

- Simplified steampunk plus post-apocalyptic flooded foundry.
- Charcoal, oxidized verdigris teal, restrained rust red, mustard functional accents,
  and controlled violet.
- Large readable silhouettes and broad color planes.
- Sparse surface detail; avoid pointillism, dense hatching, speckles, and AI
  micro-texture.
- Terrain is a visually filled mass below its walkable top.
- Stage skins are coherent regional kits; do not randomly mix visual modules from
  different stages.
- Terrain should remain quieter than hazards, interactables, pickups, and the player.

## First Image Experiment

### Intended Model

The first experiment interpreted one production call as one complete asset or one
complete state strip. It generated:

- one terrain source board;
- one spike row;
- one poison-vent state strip;
- one crumbling-platform state strip;
- one chest state strip;
- one material-node state strip;
- seven individually rendered field pickups.

All files are previews on a flat dark background, not transparent production sprites.

### Generated File Index

All paths below are under the generated-preview root in **Start Here**.

| File | Intended subject | Size | Status |
| --- | --- | ---: | --- |
| `exec-733470bd-3dc0-4484-a5f2-1a376fbd7074.png` | First terrain core board | 1672x941 | Rejected as production; evidence only |
| `exec-0ebc4f92-f5a3-4bd5-95b2-82d18b070080.png` | Spike row | 1619x971 | Unaccepted preview |
| `exec-87581012-1d9a-4103-bd07-f0e9b430f01a.png` | Poison vent: warning/active/cooldown | 1672x941 | Unaccepted preview |
| `exec-4b77facc-7041-4abd-b7db-9852cce3a4cb.png` | Crumbling platform states | 1672x941 | Unaccepted preview |
| `exec-fc6c36c3-89ff-4d17-a2f3-54bc1a9179c2.png` | Chest states | 1774x887 | Unaccepted; perspective drift |
| `exec-4d984602-528d-40d4-84b7-8397d2b38e4d.png` | Material node states | 1672x941 | Unaccepted; perspective drift |
| `exec-e4a98b10-aa6e-405c-9ea1-c84482cd224a.png` | Vital Shard | 1254x1254 | Unaccepted; too individually polished/detailed |
| `exec-f4ff633d-88c5-4ba7-bb3b-c8378f664dab.png` | Supply Charge | 1254x1254 | Unaccepted; too individually polished/detailed |
| `exec-77f9144f-b742-4bfb-97c8-98e64ae30051.png` | Focus Shard | 1254x1254 | Unaccepted; too individually polished/detailed |
| `exec-501cfe75-39a6-40b7-9f56-c2f532d3c16c.png` | Coin Bundle | 1254x1254 | Unaccepted; too individually polished/detailed |
| `exec-57b97b16-8d91-46fc-98dd-2b46489a801e.png` | Rusted Scrap | 1254x1254 | Unaccepted; too individually polished/detailed |
| `exec-8d23d010-a896-49ac-9169-23d48fb078ac.png` | Sky Thread | 1254x1254 | Unaccepted; too individually polished/detailed |
| `exec-aafc98fa-0311-4b51-b0f9-9cf84f04e071.png` | Slime Residue | 1254x1254 | Unaccepted; too individually polished/detailed |

### What The Experiment Proved

- Separate calls can follow the same palette but still drift in rendering, material
  density, scale, light, perspective, and edge treatment.
- Highly finished individual objects do not automatically compose into one coherent
  gameplay room.
- A generated state strip redraws the full body in every state, causing subtle shape,
  pivot, and proportion changes.
- The first terrain board showed attractive blocks but did not provide a trustworthy
  exact grid, complete connection matrix, or repeatable tile seam.
- Seven individual pickup calls created excessive generation and cleanup work before
  the shared map language had been proven.

## Owner Correction After The First Experiment

The owner rejected the production model, not merely individual pictures. The key
feedback was:

- "Using these in one map looks like it will cause problems."
- "There are too many separate element generations. Make more terrain tiles."
- "The current terrain tiles look difficult to reuse."
- "For states, generate one base image and put layers over it."
- Repeated full-body generations inevitably differ even when arranged horizontally or
  vertically.

This feedback supersedes the older assumption that every pickup or every complete
state presentation should receive its own independent final-image call.

## Corrected Production Model

### 1. Build The Map Language Before Polishing Objects

Terrain occupies most of the screen and determines whether every later component looks
like part of one world. The production order must therefore be terrain-first:

1. shared cell/grid and material grammar;
2. core semantic terrain pieces;
3. one-way, ledge, bridge, column, opening, liquid-edge, and other reusable patterns;
4. restrained variation/decor layers;
5. one representative room composition test;
6. only then, broader component and item production.

Generated terrain is source direction. A human- or tool-authored strict-grid rebuild is
still required for exact seams, atlas coordinates, collision silhouettes, and the full
inner/outer-corner matrix.

### 2. One Canonical Base, Then Independent State Layers

For a stateful component:

- generate or draw one canonical base body once;
- split movable parts when needed, such as chest body/lid/latch or material socket/core;
- keep size, pivot, support top, damage origin, and interaction footprint fixed;
- represent states with overlays, visibility, transforms, particles, shaders, or
  animation parameters;
- do not regenerate the complete body for warning, active, cooldown, disabled, or
  claimed states.

Examples:

- poison vent: fixed chassis plus warning glow, active plume, cooldown wisp;
- crumbling platform: fixed platform plus crack decal, shake transform, hidden support,
  debris layer, and respawn outline;
- chest: fixed lower body plus separately rotated lid and latch treatment;
- material node: fixed socket plus removable crystal core and depleted fragments.

### 3. Reduce Item Production Calls Through Shared Families

Do not begin by creating seven large final paintings. First define a shared pickup
grammar: optical box, edge treatment, light direction, glow allowance, material scale,
and animation allowance. Then group identity work into practical families:

- functional pickups: health, supply, focus;
- common currency: coin;
- materials: scrap, thread, residue.

The final silhouettes still need to differ, but they should derive from one coherent
family system rather than seven unrelated render jobs.

### 4. Validate A Composite Room Early

An isolated asset can look good and still fail as game art. After the first terrain kit
and one base-plus-overlay component exist, place them in one representative Flooded
Works room or a faithful static room mockup. Review:

- overall visual coherence;
- player and landing-edge readability;
- safe terrain versus hazard contrast;
- repeated seams and lighting;
- component scale relative to tile scale;
- foreground/background competition.

Do not expand the catalog until this composite passes.

## Second Four-Image Experiment

The revised demonstration was scoped as:

1. reusable Flooded Works core terrain kit;
2. reusable terrain extension/pattern kit;
3. canonical component base-part kit;
4. effects/decals-only state-overlay kit.

### Results

| File | Subject | Size | Result |
| --- | --- | ---: | --- |
| `exec-ad92a284-e991-4b57-9b6c-34c325b080cf.png` | Revised core terrain source board | 1672x941 | Generated; unaccepted evidence |
| `exec-6c9f456f-ac3a-4623-a332-47fb8c1f76e0.png` | Revised terrain extension/pattern board | 1672x941 | Generated on retry; unaccepted evidence |
| none | Component base-part kit | n/a | Not generated before interruption |
| none | State-overlay-only kit | n/a | Not generated before interruption |

The first combined four-call run produced the core terrain image, then failed while
reading the second request with HTTP 408 `Request body read timed out`. The extension
kit was retried as a smaller one-reference request. It completed, but its output only
became visible when the interrupted tool cell was explicitly terminated.

Do not assume the retry failure means the image-generation model cannot make the kit.
The failure was request/tool transport timing. Future multi-image work should use one
short, independent tool call at a time so a later timeout cannot discard the remaining
sequence or hide completed output.

### Remaining Problems In The Revised Terrain Boards

- They remain visual source boards, not exact production atlases.
- The core board still introduces multiple fill colors as separate variants rather
  than proving one locked stage material grammar.
- Apparent cell subdivisions and cut lines are not guaranteed mathematically equal.
- Inner/outer corner coverage and peering combinations remain incomplete.
- Gold cap usage may still be too dominant if repeated across an entire room.
- The extension board is closer to a reusable pattern vocabulary, but it still needs
  strict-grid reconstruction and a real tiled repetition test.

## Actual Runtime State Contracts

Future art must use the current state names rather than inventing presentation states:

- `TimedPoisonVent`: `warning`, `active`, `cooldown`;
- `CrumblingPlatform`: `stable`, `warning`, `disabled`, `respawning`;
- chest: available, temporarily disabled/pending during an optional choice, claimed;
- material node: available, claimed/depleted.

Visual-only transitions are allowed only when they do not add or change gameplay
state, timing, collision, reward settlement, or interaction behavior.

## Temporary HTML Gallery Requirement

The owner requested an inspectable temporary HTML component gallery. A static prototype
now exists under `tools/component_gallery/` and builds into the ignored
`.codex-runtime/component-gallery/` directory.

The prototype is review evidence only. Its inline SVG vent and platform demonstrate
base/overlay switching but are explicitly not production world art, and its large
background viewer is only a logical-coverage simulation. Production terrain,
interactive world components, and background art remain raster assets assembled from
approved source images.

Required role for a replacement or revision:

- compare references, generated source, cleaned result, and production candidate;
- show terrain repetition and connection samples;
- show base sprites separately from overlays;
- toggle or layer warning/active/cooldown and other applicable effects over one fixed
  base;
- inspect intended gameplay size, enlarged view, grayscale, and representative
  backgrounds;
- record `draft`, `shortlist`, `needs-revision`, `accepted`, or `rejected` status;
- remain a local review tool, not shipped game UI.

Implementation paths:

- versioned builder/source: `tools/component_gallery/`;
- generated ignored site: `.codex-runtime/component-gallery/`;
- local entry point: `.codex-runtime/component-gallery/index.html`.

The next session should replace the prototype's inline SVG world art with approved
raster candidates and revise the gallery data model to support `base_parts` and
`overlays`, not only complete state images.

## Plan Sections That Must Be Revised

`docs/design/WORLD_COMPONENT_IMAGE_PRODUCTION_PLAN.md` is still a draft. Do not execute
its old detailed call matrix unchanged. Revise at least:

- **Plain-Language Outcome**: replace "one object/state sequence at a time" with
  terrain/family/base/overlay units;
- **Expected Call Budget**: retire the 17-production-call default;
- **One-Call Sizing Rules**: add canonical-base and overlay/edit rules;
- **Existing Hazard Production Batches**: remove complete full-body state-strip
  generation;
- **Field Pickup Production Batches**: replace seven large independent paintings with
  shared-family grammar plus narrowed identity work;
- **Interactable Production Batches**: split chest and node into stable parts and
  overlays/transforms;
- **Initial Vertical Slice**: require a composite room test earlier;
- **End-To-End Checklist**: build the HTML base/overlay gallery before broad generation.

The high-level scope, stage-specific skin boundary, no-gameplay-change guards, and
temporary gallery requirement remain valid.

## Recommended New-Session Sequence

1. Open this worktree and confirm `git status --short`.
2. Read this handoff, then the component art spec and image-production draft.
3. Inspect the two revised terrain files with `view_image`; treat them as evidence,
   not accepted assets.
4. Rewrite the image-production plan around terrain-first, canonical bases, and
   overlay layers. Do not generate more images during that rewrite unless the owner
   explicitly asks.
5. Decide the exact tile grid from current room/player geometry; 32 px is only the
   existing first candidate.
6. Define the minimum exact semantic terrain matrix and pattern matrix before another
   terrain generation or redraw.
7. Update the temporary gallery contract and implementation data model for base parts
   plus overlays.
8. Choose one component for the first layered proof. Recommended: timed poison vent,
   because its chassis remains fixed and warning/active/cooldown effects naturally
   separate into layers.
9. Test the first terrain kit and layered component in a representative Flooded Works
   room before generating item families.
10. Reconcile the presentation branch with the latest clean main gameplay state before
    any Godot integration.

## Do Not Do Next

- Do not import any generated preview directly into Godot.
- Do not crop the generated terrain board into a claimed production atlas.
- Do not generate all seven pickups independently again.
- Do not regenerate a complete component body for every state.
- Do not change gameplay geometry to fit generated art.
- Do not add new hazard behavior, such as a pendulum, merely to test presentation.
- Do not touch character, weapon, equipment, skill-tree, inventory, or combat-system
  work from this branch.
- Do not run several long image-generation requests in one chained cell; use separate
  calls and inspect each result.

## Open Decisions

- Exact terrain cell size and atlas padding.
- Whether the first production source is manually redrawn from generated direction or
  created through a stricter deterministic tile drawing workflow.
- How many terrain material alternatives are allowed in one stage skin.
- Whether pickup families use one shared base/container shape or only shared optical
  and material rules.
- Which representative room becomes the first composition test after main-branch
  reconciliation.
- Whether the two revised terrain boards are useful enough to retain as documentation
  evidence; they are not currently committed.

## Handoff Completion Criteria

This handoff can become `done` after a later session:

- revises and owner-accepts the image-production plan;
- creates the base/overlay-aware temporary gallery contract or implementation;
- records an explicit decision on the two revised terrain boards;
- selects an exact terrain grid and first layered component proof;
- supersedes this continuation record with newer accepted decisions.
