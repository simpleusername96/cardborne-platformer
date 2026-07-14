---
type: plan
status: draft
owner: BK
created: 2026-07-14
last_reviewed: 2026-07-14
topic: Image-generation batches, world-asset review, and temporary gallery workflow
scope: Terrain, hazards, traversal components, field pickups, chests, and material nodes
source: Owner direction through 2026-07-14, current runtime catalog, existing visual references, and the component art contract
related:
  - ./GAME_COMPONENT_ART_SYSTEM.md
  - ./references/README.md
  - ../research/component_ui_foundation_research_2026-07-13.md
  - ../../.agent/execplans/2026-07-13-component-ui-foundation.md
  - ../../.agent/handoffs/2026-07-14-world-component-imagegen-session.md
---

# World Component Image Production Plan

## Revision Notice

Image-generation experiments performed after this draft exposed a material problem in
the detailed call matrix: complete per-object renders and complete per-state body
renders do not reliably compose into one coherent map, and they create too many calls.

The owner's latest direction is terrain-first, with one canonical component base plus
separate state overlays/effects. Pickup work must begin from shared family rules rather
than seven unrelated finished paintings. The expected 17-call budget and detailed
production-batch sections below are therefore **not approved execution instructions**
until revised.

Read `.agent/handoffs/2026-07-14-world-component-imagegen-session.md` for the generated
file index, observed failures, corrected production model, and next-session sequence.
The stage-skin scope, no-gameplay-change guards, and gallery requirement remain valid.

## Purpose

Define exactly how Cardborne will use image generation to develop terrain, hazards,
field items, and interactable art without treating an AI output as a finished game
asset. The plan fixes three practical questions before any new image is generated:

1. What is small and coherent enough for one image-generation call?
2. How are candidates compared, accepted, revised, and converted into production art?
3. How can the owner review every family in a temporary local HTML gallery before it
   reaches a Godot scene?

This document plans the work only. It does not authorize image generation, HTML
gallery implementation, runtime integration, or broad asset replacement until the
owner accepts the plan.

## Plain-Language Outcome

The process is deliberately staged:

- First, use the existing reference boards to settle the visual family.
- Then generate one narrowly defined object or one object's state sequence at a time.
- Review the images in a local comparison page at real gameplay sizes.
- Clean or redraw accepted candidates to exact dimensions, alpha, pivots, and tile
  seams.
- Test one family in an isolated Godot scene and one real room.
- Expand only after the first room remains readable and mechanically unchanged.

The HTML gallery answers "does this art communicate the right thing?" The Godot
gallery and room test answer "does it work inside the actual game?" They are separate
gates.

## Current Planning Decisions

These are the working defaults used by this draft. P0 converts them into accepted
decisions or records the owner's revisions.

- [x] Do not generate new images until this workflow and its first batch are accepted.
- [x] Use the built-in GPT image-generation workflow as the default generator.
- [x] Treat generated images as direction or source material, not automatically as
  production-ready tiles, atlases, or sprites.
- [x] Use one generation call for one coherent visual problem.
- [x] Review candidates in a temporary static HTML gallery before Godot integration.
- [x] Keep this work on the presentation branch and separate from current character,
  weapon, equipment, skill-tree, inventory, and combat-system work.
- [x] Start with the Flooded Works stage skin because it best matches the selected
  flooded-foundry direction.
- [x] Prove the pipeline with behavior that already exists: solid terrain, one-way
  terrain, spike row, timed poison vent, crumbling platform, field pickups, chest,
  and material node.
- [x] Do not add a pendulum, saw, or another new gameplay behavior merely to test art.
- [x] Never let visual replacement change collision, traversal distance, damage area,
  timing, interaction range, reward value, or placement.

## Scope

### Included In The Initial Production Slice

- Flooded Works static terrain and one-way platform visual language.
- The existing `spike_row`, `timed_poison_vent`, and `crumbling_platform` families.
- Seven existing field pickups:
  - `vital_shard`;
  - `supply_charge`;
  - `focus_shard`;
  - `coin_bundle`;
  - `rusted_scrap_fragment`;
  - `sky_thread_wisp`;
  - `slime_residue_droplet`.
- Existing chest and material-node state families.
- Background and surface decor needed to judge the first room, kept subordinate to
  gameplay silhouettes.
- A temporary HTML review gallery and, later, an isolated Godot component gallery.

### Deferred Until The Initial Slice Passes

- Rope, moving platform, destructible blocker, switch, gate, checkpoint, and exit
  skins.
- Lower Ruins and Broken Sanctum stage-skin production.
- New hazard behaviors such as a pendulum, swinging saw, or crushing mechanism.
- Large unique set pieces and boss-room machinery.
- Broad room migration beyond the accepted representative room.

### Excluded

- Player, enemy, boss, weapon, equipment, skill, inventory, and combat HUD art.
- Changes to gameplay balance, movement, collision, room layout, reward economy, or
  procedural generation.
- Downloaded web assets or third-party packs as silent fallbacks.
- Directly slicing the current generated reference boards into runtime atlases.
- Shipping the temporary HTML gallery as part of the game.

## As-Is / To-Be Delta

| Area | As-is | To-be | Acceptance guard |
| --- | --- | --- | --- |
| Visual direction | Existing boards show palette, density, and decomposition. | Reuse them first; generate a new direction board only for an unanswered question. | No redundant generation merely to create more options. |
| Generation scope | No durable definition of one call or batch. | Every call has one batch ID, one visual problem, one output role, and one review target. | Mixed unrelated objects are rejected before generation. |
| Terrain output | Generated terrain board is illustrative and has inexact seams. | Generate source direction, then manually rebuild a strict semantic tile kit. | Repetition, corner coverage, collision silhouette, and grid alignment pass. |
| Hazard output | Reference board mixes several component ideas. | Each existing hazard gets its own coherent runtime state-set batch. | Warning, active/cooldown or disabled/respawning state, pivot, and envelope remain legible. |
| Pickup output | Current runtime pickups rely heavily on color. | Each pickup gets a distinct silhouette plus controlled family resemblance. | Types remain distinguishable without relying on hue alone. |
| Review | Images are inspected ad hoc. | Static gallery shows current, candidate, selected, scale, state, and rejection reason. | Owner explicitly marks each family accepted or needing revision. |
| Provenance | Generator output can remain outside the repository. | Every retained batch records prompt, role, references, output, decision, and cleanup. | No accepted asset exists only in the generator's temporary output folder. |
| Integration | Placeholder visuals are replaced directly in scenes. | HTML review, production cleanup, Godot gallery, then one-room proof. | Gameplay snapshots remain equal before and after skin replacement. |

## Working Terms

| Term | Simple meaning |
| --- | --- |
| **Asset family** | Closely related visuals that share one gameplay role, scale, material language, and review criteria, such as Flooded Works solid terrain. |
| **Direction board** | One image used to compare style, silhouette, palette, or decomposition. It is not production art. |
| **Production candidate** | Source image for one exact component or one state sequence that may be cleaned or redrawn into production art. |
| **State set** | Multiple runtime states of the same object with one shared scale and pivot, such as vent warning, active, and cooldown. |
| **Repair call** | A new generation or edit that changes one named defect while preserving all accepted properties. |
| **Batch** | One planned generation call plus its ID, prompt, references, outputs, and review decision. |
| **HTML gallery** | Temporary local image comparison site; it does not run gameplay. |
| **Godot gallery** | Isolated scene that runs real component states, timing, collision overlays, and scale. |

## One-Call Sizing Rules

### Rule 1 - One Call Solves One Visual Problem

Good call scopes:

- one Flooded Works terrain direction board;
- one strict visual study for the timed poison vent's four states;
- one crumbling platform state strip with a fixed support size and pivot;
- one exact pickup, shown at world-sprite and enlarged inspection scale;
- one chest state set: closed, available, open, and claimed.

Rejected call scopes:

- terrain, poison vent, chest, and pickups in one image;
- all three stage skins in one image;
- seven unrelated final pickup sprites in one production call;
- a trap, its gameplay animation, its UI icon, and an entire room background together;
- several behavior variants that require different collision envelopes.

### Rule 2 - Direction Calls May Compare A Family; Production Calls May Not

A direction board may place several family members together to answer a shared style
question. For example, a pickup silhouette board may compare all seven pickup concepts.
That board cannot be promoted directly to seven production sprites.

Production candidates are narrower:

- one terrain semantic subset;
- one component and its states;
- one pickup identity;
- one targeted correction to a previously selected candidate.

Distinct assets use distinct production calls. Multiple outputs from the same prompt,
when available, are alternatives for that one asset rather than slots for unrelated
assets.

### Rule 3 - State Sets Stay Together When Consistency Is The Problem

The same component's states may share one call when they require an identical body,
camera, scale, pivot, and lighting. Poison vent warning/active/cooldown belongs
together. Poison vent plus spike row does not.

If one state remains wrong after the set is selected, use a targeted edit or repair
call for that state. Do not regenerate accepted states without a reason.

### Rule 4 - Tile Generation Produces Source Direction, Not A Trusted Atlas

Image generation is not expected to produce exact repeatable tile seams, stable atlas
coordinates, collision polygons, or a complete peering matrix. A terrain call may
propose a small coherent kit, but production work must reconstruct it on the chosen
grid and verify every required neighbor combination.

### Rule 5 - Reuse Existing Evidence Before Generating Again

Before every direction call, record which question is not answered by:

- `references/visual-style-modular-foundry.png`;
- `references/component-guides/terrain-tile-kit.png`;
- `references/component-guides/traversal-interactable-kit.png`;
- `references/component-guides/pickup-hud-kit.png`.

If the existing board already answers the question, skip the direction call and move
to a narrow production candidate.

## Batch Plan

### Expected Call Budget

If the existing reference boards answer all direction questions, the initial slice
starts with 17 production calls:

- 5 terrain/background source calls;
- 3 existing-hazard calls;
- 7 pickup calls;
- 2 interactable calls.

Up to five direction calls are optional, not automatic. Repair calls are added only
for named defects, with at most two generation/repair attempts for the same defect
before the prompt strategy changes or the asset is manually redrawn. This is a scope
budget, not a requirement to spend every call.

### A. Optional Direction Batches

These batches are generated only when the existing boards leave the listed question
unresolved.

| ID | One-call subject | Question answered | Output role |
| --- | --- | --- | --- |
| `fw-dir-material-v01` | Flooded Works material and palette board | How stone, oxidized metal, wet masonry, poison, and safe surfaces coexist without visual noise. | Direction only |
| `fw-dir-terrain-v01` | Flooded Works terrain semantic board | How fill, top, walls, corners, underside, and one-way deck read as one family. | Direction only |
| `fw-dir-hazards-v01` | Existing hazard family silhouette board | How spike, vent, and crumble warning channels share a stage language while remaining distinct. | Direction only |
| `shared-dir-pickups-v01` | Seven pickup silhouette concepts | Which shape language separates health, utility, focus, coin, scrap, thread, and residue. | Direction only |
| `fw-dir-interactables-v01` | Chest and material-node direction board | How interactable, available, opened, and depleted objects differ from passive decor. | Direction only |

Direction gate:

- [ ] State the unresolved question before generation.
- [ ] Reuse existing reference images as explicit style references where useful.
- [ ] Compare the result against the locked palette and density rules.
- [ ] Select one direction or record why none is usable.
- [ ] Do not begin production calls while the family direction remains ambiguous.

### B. Terrain Production Batches

| Order | ID | One-call subject | Required content | Production follow-up |
| ---: | --- | --- | --- | --- |
| 1 | `fw-terrain-core-v01` | Solid terrain core | interior fill, walkable cap, left/right wall, outer/inner corners, ceiling/underside | Redraw on selected grid; complete peering matrix; match collision silhouette. |
| 2 | `fw-terrain-oneway-v01` | One-way/catwalk family | center deck, left/right ends, support bracket, underside | Lock deck thickness and readable drop-through language. |
| 3 | `fw-terrain-liquid-v01` | Water/poison visual edge | surface edge, submerged fill, corner transitions, restrained foam/mist accents | Keep damage/collision outside the art; verify foreground does not hide feet. |
| 4 | `fw-terrain-decor-v01` | Low-frequency terrain alternatives | crack, rivet, moss, pipe, mineral, stain alternatives | Remove silhouette-changing variants; cap use density. |
| 5 | `fw-background-kit-v01` | Back-wall and industrial silhouettes | masonry fill, large pipe, beam, distant machinery, void separators | Keep contrast below player, hazard, pickup, and exit. |

Terrain acceptance:

- [ ] Exact cell size, atlas padding, filtering, and source IDs are documented.
- [ ] All required top, side, inner, outer, ceiling, and underside transitions exist.
- [ ] Repeated 3x3 and long-strip samples show no accidental seams or lighting jumps.
- [ ] Solid terrain is visually filled below its support top.
- [ ] One-way platforms look thinner and mechanically distinct from solid terrain.
- [ ] Decorative alternatives do not imply false collision, hidden ledges, or hazards.
- [ ] Terrain remains quieter than active hazards and pickups.

### C. Existing Hazard Production Batches

| Order | ID | One-call subject | States/content | Fixed gameplay facts |
| ---: | --- | --- | --- | --- |
| 1 | `fw-hazard-spike-row-v01` | Spike row | safe base plus one clear damaging silhouette; optional tiling end treatment | Existing damage bounds and placement width |
| 2 | `fw-hazard-poison-vent-v01` | Timed poison vent | `warning`, `active`, `cooldown` | Existing origin, active area, warning timing, active timing, cooldown timing |
| 3 | `fw-hazard-crumble-v01` | Crumbling platform | `stable`, `warning`, `disabled`, `respawning` | Existing support top, width, warning timing, disabled timing, respawn timing |

Hazard acceptance:

- [ ] A still frame identifies the dangerous object before contact.
- [ ] Warning state is visible before the active damage or support loss.
- [ ] Active state is stronger than warning without covering the safe route.
- [ ] Cooldown/disabled/respawning state cannot be mistaken for active damage or stable support.
- [ ] Art does not extend the perceived damage or support envelope beyond gameplay.
- [ ] Every frame uses a stable pivot and consistent optical scale.
- [ ] Color is reinforcement; silhouette or motion also communicates the state.

Pendulum art remains deferred until a real pendulum behavior contract exists. It is
not part of the first production pipeline proof.

### D. Field Pickup Production Batches

Each pickup gets a separate production call because each identity must be readable
without relying only on color.

| Order | ID | Identity goal | Required visual cue |
| ---: | --- | --- | --- |
| 1 | `shared-pickup-vital-v01` | Immediate recovery | compact heart/seed/core mass; warm living center |
| 2 | `shared-pickup-supply-v01` | Consumable refill | contained charge/canister silhouette |
| 3 | `shared-pickup-focus-v01` | Cooldown relief | focused prism/clock-like energy rhythm, not a second supply canister |
| 4 | `shared-pickup-coin-v01` | General currency | unmistakable grouped coin/token mass |
| 5 | `shared-pickup-scrap-v01` | Industrial upgrade material | angular rusted plate/gear fragment |
| 6 | `shared-pickup-thread-v01` | Light rare material | looped filament/wisp silhouette |
| 7 | `shared-pickup-residue-v01` | Organic monster material | irregular viscous droplet/clump silhouette |

Each call may show the same pickup at two scales inside one review image: the exact
world-sprite intent and an enlarged detail view. It must not bake a UI frame, text,
quantity, rarity label, or pickup receipt into the image.

Pickup acceptance:

- [ ] Every type is distinguishable in grayscale and at intended world scale.
- [ ] `supply_charge` and `focus_shard` do not collapse into the same blue shape.
- [ ] Currency/material pickups do not look like healing or hazard telegraphs.
- [ ] Silhouette, glow, and motion allowance are documented separately.
- [ ] The world sprite and any later UI icon share identity but may use different
  optical simplification.
- [ ] Item art does not change pickup radius, reward amount, or placement.

### E. Interactable Production Batches

| Order | ID | One-call subject | State set | Guard |
| ---: | --- | --- | --- | --- |
| 1 | `fw-interactable-chest-v01` | Chest | available, temporarily disabled/pending, claimed/open | Interaction and exactly-once reward contract unchanged |
| 2 | `fw-interactable-material-node-v01` | Material node | available/intact, claimed/depleted | Interaction and exactly-once reward contract unchanged |

Interactable acceptance:

- [ ] Available objects stand apart from background decor before the prompt appears.
- [ ] Pending, claimed, and depleted states remain visible but no longer invite a duplicate interaction.
- [ ] State changes are readable without text.
- [ ] The interaction prompt remains UI-owned and is never baked into world art.

### F. Deferred Component Backlog

After the first slice passes, create one plan row and one production call per coherent
component/state set for:

- rope/climbable;
- moving platform;
- destructible blocker;
- switch and its linked gate;
- checkpoint;
- stage exit;
- rest/forge interaction point;
- region-specific liquid and environmental effects;
- new hazard families only after their gameplay definitions exist.

## Initial Vertical Slice

The first implementation proof should remain small:

1. Use Flooded Works as the only stage skin.
2. Build the terrain core and one-way families.
3. Build and review the crumbling-platform family.
4. Use `FwCrumbleCrossing` as the first room migration candidate because it can prove
   repeated terrain, support readability, and an existing stateful platform without
   inventing new behavior.
5. Validate the timed poison vent separately in the HTML and Godot galleries, then
   use `FwPoisonTiming` as the second integration candidate only after the first room
   passes.
6. Add the three functional pickups first (`vital`, `supply`, `focus`) to prove
   silhouette differentiation before producing all currency/material pickups.
7. Integrate chest and material node only after pickup and interaction contrast is
   stable.

The selected room remains subject to a final baseline check against the latest clean
gameplay branch. If its geometry or component ownership changed, choose another
Flooded Works room with the same contract coverage rather than forcing stale data.

## Prompt Contract

Every batch record must answer the following before a call is made:

```text
Batch ID:
Output role: direction | production-candidate | repair
Asset family and exact subject:
Gameplay use and intended display size:
Stage skin and material language:
Required states or semantic pieces:
Camera and projection:
Silhouette and composition constraints:
Palette and color-count constraints:
Reference images and the role of each reference:
Properties that must remain invariant:
Background/key color:
Explicit avoid list:
Acceptance questions:
```

Default world-asset prompt constraints:

- strict orthographic side view;
- no perspective, isometric angle, or three-quarter product view;
- simple flat shapes, large color planes, and two to four major colors per object;
- no text, numbers, UI frames, watermark, labels, or key prompts;
- no cast shadow that changes the apparent collision/support silhouette;
- no gradient background, scene mockup, or unrelated props in production candidates;
- no dense hatching, speckles, painterly noise, or tiny rivets at gameplay scale;
- generous uncropped padding around every piece;
- consistent body size, pivot, and lighting across a state set;
- stage-safe contrast: terrain quiet, interactables distinct, hazards strongest during
  warning/active states, pickups readable against both dark and light surfaces.

For source extraction, use a flat chroma-key background and remove it locally after a
candidate is accepted. Flooded Works uses teal/green materials, so magenta is the
default key candidate; switch the key when it collides with an asset's palette. Native
transparent generation is a fallback only after its limitations are reviewed and the
owner explicitly approves the change in generation path.

## Batch Records And File Flow

### During Exploration

- Generator output may begin in the tool's temporary output location.
- Copy every candidate under review into
  `.codex-runtime/component-art/<batch-id>/` so it is not lost and is not committed by
  default.
- Store a small batch record beside it with the prompt, reference roles, generation
  date, output role, review state, and rejection reason.
- Never rely on a path under `C:\Users\BK\.codex\generated_images` as the only copy of
  an accepted candidate.

### Retained References

- Keep only intentionally useful direction/evidence images under
  `docs/design/references/`.
- Update `docs/design/references/README.md` when a new retained board changes or
  clarifies the selected direction.
- Do not commit every rejected option as permanent documentation.

### Production Art

- Place only cleaned, approved runtime images under the eventual
  `art/world/<stage-skin>/<family>/` path selected during implementation.
- Record stable asset IDs, image paths, frame/pivot data, tint permission, fallback,
  and source batch in a world visual manifest.
- Keep exact tile grid, padding, atlas coordinates, source IDs, and filtering in the
  terrain manifest.
- Keep intermediate masks, rejected generations, and gallery exports outside runtime
  art paths.

## Temporary HTML Gallery Contract

### Role

The gallery is a local visual review tool. It must make defects obvious before art is
imported into Godot. It does not simulate physics, transactions, or final animation
timing.

### Planned Placement

- Versioned gallery builder/source: `tools/component_gallery/`.
- Generated, ignored review site: `.codex-runtime/component-gallery/`.
- Default entry point: `.codex-runtime/component-gallery/index.html`.
- Candidate images are copied into the generated site's local `assets/` directory.
- Review data is embedded or loaded as a normal script so the page works from a local
  file without a development server.

No web framework or production dependency is required. If a browser restriction later
forces a local server, use the repository's assigned fastrun/Codex port rather than an
ad hoc port.

### Required Views

- **Overview:** family, batch ID, status, selected candidate, and unresolved issue.
- **Current vs candidate:** current placeholder, generated candidate, cleaned result,
  and selected production image where available.
- **Scale:** 1x, 2x, 4x inspection plus intended gameplay size.
- **Backgrounds:** representative dark wall, light terrain, active hazard, and empty
  traversal background.
- **Grayscale/silhouette:** verifies that identity does not depend only on hue.
- **Terrain repetition:** 3x3 tiling, long horizontal span, inner/outer corner sample,
  one-way span, and collision-edge overlay.
- **Component states:** buttons or tabs switch real warning, active, cooldown, stable,
  disabled, respawning, available, pending, claimed, or depleted images as applicable.
- **Metadata:** prompt version, references, intended dimensions, pivot, key color,
  cleanup status, decision, and rejection reason.

### Review Statuses

Gallery asset status is separate from document lifecycle status:

- `draft`: newly generated or assembled;
- `shortlist`: worth comparing, not yet accepted;
- `needs-revision`: direction is usable but a named defect remains;
- `accepted`: approved for cleanup or integration;
- `rejected`: not to be reused without a new decision.

Only the owner can mark a family `accepted`. An agent may recommend a status and record
evidence but cannot silently promote a candidate.

### Owner Review Questions

- Can I tell safe terrain, one-way terrain, danger, reward, and background apart in one
  glance?
- Does a hazard visibly warn me before it can hurt me or remove support?
- Can I distinguish pickup types from shape, not just color?
- Does the object still read at 960x540 gameplay scale?
- Do repeated terrain pieces expose seams or repeated lighting?
- Does decoration hide feet, landing edges, prompts, exits, or hazard telegraphs?
- Does the candidate fit Flooded Works without looking like a random asset from another
  region?

### HTML Gallery Acceptance

- [ ] Opens directly from `index.html` with no server by default.
- [ ] Contains no broken local image paths.
- [ ] Shows all required states and review metadata for the active family.
- [ ] Supports at least 1280x720 and 1920x1080 without clipping or overlapping labels.
- [ ] Uses stable image boxes so changing state does not shift the layout.
- [ ] Does not contain fake controls, gameplay claims, or explanatory marketing copy.
- [ ] Records the owner's selection and a concise reason.

## End-To-End Checklist

### P0 - Accept Scope

- [ ] Owner accepts or revises the one-call sizing rules.
- [ ] Owner accepts Flooded Works as the first stage skin.
- [ ] Owner accepts the initial catalog and deferred catalog.
- [ ] Resolve the exact logical tile cell through the terrain spike; 32 px remains the
  initial candidate, not a locked fact.
- [ ] Reconcile the representative room against the latest gameplay branch.

Gate: no image call before P0 is accepted.

### P1 - Capture Baseline

- [ ] Capture current room screenshots at supported viewports.
- [ ] Record terrain support edges, component bounds, pivots, state names, and timings.
- [ ] Capture current placeholder art for gallery comparison.
- [ ] Record the current world-pickup silhouettes and colors.
- [ ] Verify existing room, hazard, pickup, and interaction validators pass before art
  work begins.

Gate: do not blame new art for an existing gameplay or validation failure.

### P2 - Settle Family Direction

- [ ] Review existing reference boards in the first gallery draft.
- [ ] List unanswered visual questions.
- [ ] Generate only the optional direction batches needed to answer those questions.
- [ ] Owner selects one Flooded Works direction.
- [ ] Record rejected directions and reasons without committing every output.

Gate: one accepted material, palette, silhouette, and density direction.

### P3 - Produce One Narrow Family

- [ ] Generate the terrain core candidate.
- [ ] Rebuild it on the selected exact grid.
- [ ] Add it to terrain repetition and background tests in the HTML gallery.
- [ ] Generate and review the crumbling-platform state set.
- [ ] Clean alpha, crop, dimensions, pivots, and color count.
- [ ] Owner accepts or rejects each family independently.

Gate: terrain core and crumbling platform pass HTML review.

### P4 - Prove In Godot

- [ ] Import accepted cleaned assets with explicit filtering settings.
- [ ] Build the isolated Godot component gallery for real states and debug bounds.
- [ ] Swap presentation without changing typed behavior or collision.
- [ ] Migrate only the selected representative room.
- [ ] Compare before/after geometry, traversal, component, and screenshot evidence.
- [ ] Obtain a human readability and traversal pass.

Gate: first room remains clearable and mechanically unchanged.

### P5 - Complete Existing Hazard Family

- [ ] Produce spike-row candidate.
- [ ] Produce timed-poison-vent state set.
- [ ] Run HTML and Godot state review.
- [ ] Integrate `FwPoisonTiming` only after its warning and safe windows are readable.

Gate: all three existing hazard families pass their state and gameplay guards.

### P6 - Complete Field Pickups

- [ ] Generate and accept `vital`, `supply`, and `focus` independently.
- [ ] Verify functional pickups are distinct in grayscale and motionless captures.
- [ ] Generate and accept `coin`, `scrap`, `thread`, and `residue` independently.
- [ ] Verify world sprite, glow/motion allowance, and later icon relationship.
- [ ] Confirm pickup transactions, quantities, and placements are unchanged.

Gate: all seven pickup identities are readable at gameplay scale.

### P7 - Complete Existing Interactables

- [ ] Produce and accept chest state set.
- [ ] Produce and accept material-node state set.
- [ ] Verify available, pending/disabled, claimed, and depleted states.
- [ ] Confirm prompts and reward receipts remain UI-owned.
- [ ] Confirm exactly-once settlement behavior is unchanged.

Gate: both interactables communicate availability and completion without text.

### P8 - Decide Expansion

- [ ] Review the first Flooded Works slice as a whole.
- [ ] Measure defects, regeneration count, manual cleanup time, and import friction.
- [ ] Decide whether to expand to deferred traversal components or revise the pipeline.
- [ ] Do not begin another stage skin until Flooded Works semantic roles and manifests
  are stable.

Gate: explicit owner decision to expand, revise, or stop.

## Regeneration And Stop Rules

Regenerate or edit when:

- camera/projection is wrong;
- a required state or semantic piece is missing;
- silhouette is ambiguous at gameplay scale;
- pieces are cropped or use inconsistent scale/pivots;
- baked lighting creates false seams or collision cues;
- micro-detail remains noisy after reduction;
- the candidate conflicts with the selected stage material language;
- a hazard warning is weaker than the active state or appears too late;
- two pickups depend on color alone to differ.

Do not regenerate the entire family when one accepted property can be preserved through
a targeted repair. Every repair call names the one intended change and the properties
that must remain invariant.

Stop after two targeted generation/repair attempts fail to improve the same defect.
At that point, revise the prompt/reference strategy or manually redraw the needed
shape. Do not keep generating options without a new hypothesis.

Reject a candidate immediately when it would require changing gameplay geometry to
make the picture believable, or when cleanup would effectively require rebuilding the
whole object without retaining useful design information.

## Validation Cadence

### Per Output

- inspect dimensions, crop, border contact, text/watermark, key-color contamination,
  alpha edge, color count, and unintended shadow;
- view at intended gameplay scale before enlarging;
- record one concise accept/reject reason.

### Per Family

- rebuild the temporary HTML gallery;
- inspect current/candidate/cleaned comparison;
- inspect scale, grayscale, backgrounds, and required states;
- obtain owner acceptance before import.

### Per Godot Integration

- run the focused room/component/pickup/interactable validator;
- compare gameplay snapshots before/after skin swap;
- capture the isolated gallery and representative room;
- check collision/support/interaction overlays;
- perform a human traversal/readability pass.

### Before Branch Handoff

- run `git diff --check`;
- run Godot headless import;
- run the relevant focused validators;
- run the full release suite only after the first room slice is complete, not after
  every generated image;
- record accepted batches, retained references, production paths, and remaining work.

## Failure Handling

- If image generation is unavailable, mark the batch blocked; do not silently replace
  it with an unlicensed web image.
- If chroma removal damages teal/green art, change to magenta or another reviewed key
  and regenerate/extract only the affected asset.
- If generation cannot produce repeatable tile seams, use the output as direction and
  manually construct the grid kit.
- If a candidate changes the perceived collision envelope, fix the art rather than the
  gameplay geometry.
- If local-file browser restrictions break the gallery, first embed review data and
  copy assets locally; start a small server only when unavoidable.
- If parent gameplay work changes IDs or state contracts, update the batch/manifest
  mapping before integration and rerun the baseline.
- Missing art must fall back to the current placeholder without disabling gameplay.

## Risks

| Risk | Consequence | Mitigation |
| --- | --- | --- |
| Calls are too broad | Inconsistent scale, style, and unusable partial output | Enforce one-call rules and batch matrix before generation. |
| Calls are too narrow too early | Many coherent-looking parts fail to form one family | Approve a direction board before production calls. |
| Generated tile sheet is trusted | Seams, missing corners, unstable atlas coordinates | Manual strict-grid reconstruction and peering tests. |
| Gallery looks good but game does not | Wrong scale, timing, or collision read | Separate HTML visual gate from Godot behavior gate. |
| Pickup types rely on hue | Poor readability and accessibility | One pickup per production call plus grayscale/silhouette gate. |
| Art expands gameplay scope | New bugs and branch conflicts | Use existing components first; defer new behaviors. |
| Too many candidates are retained | Repository noise and indecision | Commit only selected evidence and production art. |
| Main gameplay branch changes | Stale room/component assumptions | Reconcile IDs and snapshots immediately before integration. |

## Open Questions

- [ ] Does the owner accept the direction/production/repair distinction for one-call
  planning?
- [ ] Does the owner accept `FwCrumbleCrossing` as the provisional first room?
- [ ] Does the terrain spike confirm 32 px, or select 24/48 px from measured geometry?
- [ ] Which exact Flooded Works palette values survive gameplay-scale testing?
- [ ] Should accepted source art retain editable layered files, or only cleaned PNG plus
  manifest for the first slice? Recommended: keep editable source when it materially
  reduces future state/skin rework.

## Decision Notes

- 2026-07-14: Owner requested planning and review infrastructure before any additional
  image generation.
- 2026-07-14: One generation call is defined by one coherent visual problem, not by an
  arbitrary number of files or an entire mixed content category.
- 2026-07-14: Direction boards may compare a family, but distinct production assets use
  distinct calls.
- 2026-07-14: The temporary HTML gallery is the owner-facing selection gate; the Godot
  component gallery remains the runtime/state verification gate.
- 2026-07-14: Character, weapon, equipment, skill-tree, inventory, and combat-system art
  remain outside this branch's world-component image scope.
