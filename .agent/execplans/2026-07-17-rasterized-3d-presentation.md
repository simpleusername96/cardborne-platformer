---
type: plan
status: done
owner: BK
created: 2026-07-17
last_reviewed: 2026-07-17
topic: Rasterized presentation for the native 3D combat proof
scope: Apply project-owned 2D raster art to the current 3D arena and Traveler without changing gameplay simulation
related:
  - ./2026-07-17-native-3d-isometric-foundation.md
  - ../../docs/product/isometric_action_rpg_product_brief.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../art/world/flooded_works/README.md
---

# Cardborne Rasterized 3D Presentation - Execution Plan

The completed native 3D combat proof keeps its physics, camera, targeting, and
input contracts. Two implementation phases replace only its visible surface:
project-owned flat raster art dresses the arena, and a four-direction raster
sprite presents Traveler locomotion while gameplay remains authoritative in 3D.

## Purpose

- **Objective:** make the current playable arena visibly approach the accepted
  flat-color drowned-foundry direction without rebuilding the simulation.
- **Final artifact:** the existing combat sandbox with an authored 2D backdrop,
  raster-textured 3D architecture/cover, and a camera-facing Traveler walk sheet.
- **Completion state:** native validation, rendered captures, Web export, and the
  built-artifact movement/action smoke pass all succeed.

## Pre-plan Evidence Already Verified

| Source or path | Verified fact | Decision affected | Freshness or recheck boundary |
| --- | --- | --- | --- |
| Root `AGENTS.md` and `.agent/PLANS.md` | Godot 4.7, flat-color drowned ruins, editor-friendly assets, and an ExecPlan for changes over five files are active constraints. | Engine, scope, document, and dependency contract. | Re-read only if project instructions change. |
| `scenes/testbeds/isometric_combat/CombatSandbox3D.tscn` | `CharacterBody3D`, explicit collision, a following orthographic camera, imported Kenney meshes, and primitive Traveler meshes currently own the proof. | Preserve simulation and replace presentation nodes only. | Recheck after scene edits. |
| `scripts/player/traveler_3d.gd` | Movement, facing, dash, melee, ranged, and guard state are already authoritative and expose the vectors needed to choose sprite rows/frames. | Animation reads state; it never moves the body or owns hit timing. | Recheck after player edits. |
| `art/world/flooded_works/README.md` and `docs/design/UI_VISUAL_SYSTEM.md` | Broad flat color masses, no outline, low texture noise, charcoal/blue-green/verdigris/rust/mustard, and separable gameplay props are accepted. | Raster prompt and material settings. | Recheck before any later production-art batch. |
| `art/world/flooded_works/backgrounds/panel_01.png` | The owner-reviewed 4:3 drowned-foundry panel contains no baked gameplay actors, hazards, UI, or text. | Reuse it as a dimmed far-background Canvas layer. | Replace only through a later accepted art revision. |
| `art/ui/production/illustrations/characters/traveler.png` | The retained Traveler bust establishes hood, mask, coat, scarf, and palette but is not a locomotion sprite. | Use it only as the identity/style reference for a new full-body sheet. | Recheck if Traveler identity changes. |
| Godot `Sprite3D`, `StandardMaterial3D`, and current GL Compatibility runtime | A camera-facing raster sprite and world-triplanar albedo can coexist with 3D collision and lighting without a package. | Hybrid presentation architecture and zero-dependency decision. | Recheck only if renderer or engine version changes. |

## Locked Decisions

| Topic | Final decision | Rationale / source |
| --- | --- | --- |
| Simulation | Preserve every current 3D body, collision shape, attack query, projectile, target fixture, camera vector, and arena dimension. | User asked to retain 3D objects and change their visible skin. |
| World backdrop | Render `panel_01.png` behind the 3D pass through a negative `CanvasLayer`; keep it dim and non-interactive. | Uses approved art and removes the black exterior without baking geometry into gameplay. |
| Architecture surface | Generate one original 1024-square flat raster albedo using only close charcoal/blue-green/teal values and apply it through one shared world-triplanar `StandardMaterial3D` to `Architecture` meshes and both cover meshes. | One broad same-hue texture keeps the first pass coherent, honors the owner's variation rule, and avoids UV-specific asset production. |
| Character | Generate one 4-column by 4-row full-body Traveler sheet on removable chroma key, convert it to alpha PNG, and render it with `Sprite3D`. | The portrait is not usable for locomotion; one sheet bounds identity and import cost. |
| Sprite directions | Rows are away-right, away-left, toward-right, toward-left relative to the fixed camera; columns are contact, passing, opposite-contact, settle. | Four rows cover the fixed isometric camera while keeping the generated sheet and runtime mapping explicit. |
| Animation ownership | `traveler_3d.gd` selects row from `combat_facing` in camera space and advances columns only from actual X/Z velocity. Dash increases playback rate; idle holds column zero. | Presentation reflects authoritative motion and cannot change gameplay. |
| Existing feedback | Hide primitive body/head meshes but keep the sword, guard shield, ground facing notch, target ring, projectile, and pulse feedback. | These still communicate tested gameplay states; replacing them is separate asset work. |
| Rendering | Use transparent alpha-cut sprites, a matte high-roughness lit material, no outline shader, no normal/roughness map, and no new dependency. | Matches the accepted simplified art contract and GL renderer. |

## Rejected Alternatives

| Alternative | Why it was viable | Why it was rejected |
| --- | --- | --- |
| Replace the proof with a 2D scene | Native 2D makes sprite sorting straightforward. | It discards the accepted 3D movement, collision, camera, and target work. |
| Apply the retired side-view terrain sheet directly | It is already project-owned raster art. | Its view, seams, and transparent composition are not valid surface UV content. |
| Use the existing Traveler portrait as a billboard | It already has alpha and the right palette. | It is a cropped bust and cannot communicate locomotion or facing. |
| Keep the primitive capsule and add only a portrait above it | Minimal code change. | It fails the request to make the character itself a sprite. |
| Add an outline/toon post-process | It could separate silhouettes. | Outlines are explicitly outside the accepted art direction. |

## Current State

Completed implementation:

- The current sandbox passes exact input, movement, camera, targeting, cover,
  guard, potion, pulse, pause, native capture, and Web export gates.
- The 3D architecture retains its imported geometry and collision but now uses
  one project-owned same-hue raster albedo through a shared triplanar material.
- The approved Flooded Works panel renders behind the arena as a non-interactive
  far background.
- Traveler remains a `CharacterBody3D` and capsule collider while a transparent
  4x4 `Sprite3D` sheet now presents idle, movement, facing, and dash-rate motion.
- The primitive body/head are hidden; existing weapon, guard, target, and ground
  feedback remain owned by their prior gameplay paths.

Completed verification:

- Asset dimensions, transparency, cell occupancy, sprite row/frame behavior,
  presentation nodes, and existing gameplay contracts are asserted in the
  deterministic validator.
- Native ready, movement, facing, guard, melee, and arena-edge captures were
  inspected at the supported sizes.
- The Web export loads as `Cardborne`, renders the raster presentation, accepts
  the complete action-key smoke sequence, and reports no browser console errors
  or warnings.

## Scope

In scope:

- Current combat sandbox background, architecture/cover albedo, and Traveler
  body presentation.
- Four camera-relative facings, four walk frames, idle, dash-rate animation, and
  preservation of current action feedback.
- Native and Web rendered verification at the existing supported viewports.

Out of scope:

- Enemy sprites, boss art, new map geometry, navigation, combat tuning, new
  controls, mouse/right-stick aim, effects replacement, UI redesign, and a full
  production environment kit.

Destructive or irreversible actions:

- None. Primitive body/head nodes remain in the scene hidden as a rollback path.

Exact actions requiring owner/user approval:

- None. The user explicitly authorized applying 2D assets to the current map and
  character; no external asset, package, service credential, or paid source is used.

## Architecture and Ownership

| Concern | Final owner | Interface or invariant | Existing owner to reuse or retire |
| --- | --- | --- | --- |
| Raster source assets | `art/world/flooded_works/isometric/` | PNG only; project-owned; no text or baked gameplay state. | Reuse existing backdrop and Traveler identity references. |
| Architecture material application | `scripts/presentation/raster_surface_pass_3d.gd` | Traverses only configured roots and sets one shared material override. | Does not own collision or mesh transforms. |
| Traveler sprite state | `scripts/player/traveler_3d.gd` | Reads velocity, camera basis, facing, dash, and guard; writes sprite frame only. | Reuse current player action owner. |
| Scene composition | `CombatSandbox3D.tscn` | Wires textures, material, backdrop, and sprite nodes. | Preserve all gameplay node paths required by validators. |
| Regression evidence | `tools/validation/validate_movement_and_actions.gd` and `capture_movement_check.gd` | Assert asset/node/frame contracts and capture idle/moving/action states. | Extend current proof gates. |

## As-Is / To-Be Delta Map

| Concern | As-is | To-be | Acceptance check | Guard / leftover check |
| --- | --- | --- | --- | --- |
| Exterior | Opaque dark environment | Approved 2D drowned-foundry panel behind 3D | Background visible at center and both edge captures | No baked actor or HUD image enters the world layer |
| Architecture | Kenney colormap | Shared project flat raster albedo | Every `Architecture` mesh and both covers report the project material | Collision transforms and counts remain identical |
| Traveler body | Capsule plus sphere | Alpha `Sprite3D` 4x4 sheet | Sprite visible; body/head hidden | Character remains `CharacterBody3D` with unchanged capsule |
| Locomotion | Mesh yaw only | Camera-relative row plus velocity-driven frame | Opposite directions change row; moving advances columns; idle returns to zero | Animation never changes velocity, position, facing, or attack timing |
| Feedback | 3D sword/shield/rings | Preserved over/around sprite | Shift/Z/X captures remain readable | No feedback owner is deleted or duplicated |

## Tasks

### Phase 1: Apply the raster world and actor slice

Goal: one playable room visibly uses project-owned 2D raster art while retaining
its exact 3D gameplay behavior.

Source owners touched: `art/world/flooded_works/isometric/`,
`scripts/presentation/raster_surface_pass_3d.gd`,
`scenes/testbeds/isometric_combat/CombatSandbox3D.tscn`, and
`scripts/player/traveler_3d.gd`.

- [x] **1.1 Create production-bound raster inputs.**
  - As-is: no isometric surface texture or full-body Traveler locomotion sheet exists.
  - To-be: add the locked albedo PNG and cleaned-alpha 4x4 Traveler PNG with source/prompt records.
  - Accept: both load as `Texture2D`; the character has transparent corners and non-empty content in all 16 cells.
  - Guard: do not overwrite retained references or keep chroma-key pixels in the runtime asset.
- [x] **1.2 Dress the existing world.**
  - As-is: the environment clears to charcoal and imported meshes use the vendor colormap.
  - To-be: add the approved negative-layer backdrop and apply one matte triplanar material to configured meshes.
  - Accept: runtime reports all architecture/cover meshes dressed and captures show no black exterior around the play area.
  - Guard: do not change collision shapes, room scale, camera values, or mesh transforms.
- [x] **1.3 Replace the primitive Traveler body with a sprite presenter.**
  - As-is: capsule/head meshes communicate position and yaw.
  - To-be: hide body/head, show the sheet through `Sprite3D`, and update row/column from camera-relative facing and velocity.
  - Accept: idle, four facing families, walking columns, and dash rate are deterministic and the sprite feet remain grounded.
  - Guard: keep `CharacterBody3D`, capsule collision, facing notch, sword, shield, and target feedback paths intact.

Batch acceptance: the ready and moving captures visibly read as the same 3D
arena with a 2D background, textured 3D surfaces, and a full-body Traveler
sprite; input and combat behavior remain unchanged.

Batch guard: no image contains baked UI/text, no new dependency appears, and no
retired side-view terrain is treated as collision or scale truth.

### Phase 2: Prove native and built presentation

Goal: automated state checks and rendered output demonstrate that the hybrid
presentation is stable across movement, actions, edges, and supported sizes.

Source owners touched: `tools/validation/validate_movement_and_actions.gd`,
`tools/validation/capture_movement_check.gd`, ignored `build/validation/*`, and
ignored `build/web/*`.

- [x] **2.1 Extend deterministic validation.**
  - As-is: validation asserts primitive visual facing and action state.
  - To-be: assert backdrop/material/sprite assets, hidden primitive body, 4x4 frame layout, row selection, walk advancement, idle reset, and preserved feedback.
  - Accept: validator exits 0 and names raster world and sprite presentation in its PASS line.
  - Guard: restore player position, facing, velocity, and input after every animation case.
- [x] **2.2 Extend and inspect rendered captures.**
  - As-is: captures cover three ready sizes and seven gameplay/edge states.
  - To-be: existing captures show the new presentation and add a dedicated opposite-facing sprite state when needed for row evidence.
  - Accept: no sprite cell clips, chroma fringe appears, feet float, background competes with the arena, or foreground geometry hides the actor.
  - Guard: generated evidence remains ignored under `build/validation/`.
- [x] **2.3 Export and smoke-test the built Web artifact.**
  - As-is: current proof exports through `tools/export_web.ps1`.
  - To-be: export current textures/code and run movement, Shift, Z, X, Space, pause, and reset in the managed `codex` lane.
  - Accept: the built canvas loads without resource/console errors and the sprite animates while gameplay states remain responsive.
  - Guard: do not invent a port or use an ad-hoc server under `D:\npjt`.

Batch acceptance: native captures and the built Web canvas agree on backdrop,
surface treatment, sprite grounding, direction changes, and action feedback.

Batch guard: no automated assertion is weakened merely to accept the new art.

## Validation Cadence

Inner-loop commands:

- `.\tools\godot.ps1 --headless --path . --import`
- `.\tools\godot.ps1 --headless --path . --script res://tools/validation/validate_movement_and_actions.gd`
- `git diff --check`

Batch gates:

- `.\tools\godot.ps1 --headless --path . --script res://tools/validation/inspect_kenney_3d_assets.gd`
- `.\tools\godot.ps1 --path . --script res://tools/validation/capture_movement_check.gd`
- Inspect 960x540, 1280x720, and 1920x1080 ready captures plus moving, melee, ranged, guard, both edge, and pause states.

Final gates:

- Full lint/type checks: Godot import plus the deterministic validator.
- Full tests: existing movement/action suite with raster assertions.
- Production build and start: `.\tools\export_web.ps1`, then the fastrun-manager `codex` lane.
- Manual UI/browser routes and viewport sizes: built canvas at 1280x720; native captures at all three supported sizes.
- Persistence/data validation: not applicable; this pass changes presentation only.
- Documentation and lifecycle validation: plan lifecycle audit, targeted links, `git diff --check`, and explicit task-owned staging review.

Rerun policy:

- Rerun a failed narrow check only after a concrete change or new hypothesis.
- Rerun full gates only after the suspected cause changed.
- Record known non-blocking warnings instead of rediscovering them.

## Predetermined Error Handling and Contingencies

| Trigger | Required response | Limit / escalation point |
| --- | --- | --- |
| Generated sprite sheet has chroma residue or transparent holes | Run the installed chroma remover once with soft matte/despill; if fringe remains, retry once with edge contraction 1. | If the second pass damages the silhouette, keep the generated source unreferenced and stop before runtime integration. |
| One or more 4x4 cells is empty or crosses its cell boundary | Perform one targeted image-generation retry with the same identity reference and stricter equal-cell constraints. | If the retry still fails, use the best complete directional row as a four-frame billboard and record the missing directions as a blocker; do not invent crops from unrelated art. |
| Triplanar projection makes walls or floor unreadably stretched | Adjust only the shared `uv1_scale` once within `0.035–0.08`. | Do not edit model UVs, add per-model textures, or change geometry in this pass. |
| Backdrop competes with gameplay | Reduce backdrop modulation alpha/value once and add one flat dim `ColorRect`. | Do not blur, repaint, or bake the arena into the background during implementation. |
| Sprite feet float or sink | Adjust only the `Sprite3D` local Y position and pixel size, preserving collision origin. | If more than 0.15 m correction is required, stop and recheck sprite cell padding rather than moving collision. |
| Transparent sorting hides sword/guard/marker | Adjust sprite render priority or alpha-cut mode once. | Do not remove gameplay feedback or replace collision/action owners. |
| Headless passes but Web misses a texture | Confirm imported path case and `.import` ownership, re-import, and export once. | Do not add base64/runtime file loading fallbacks. |

## Progress

- [x] Phase 1: raster world and Traveler sprite are integrated.
- [x] Phase 2: automated, rendered, and Web gates pass.
- [x] Final gates and task-owned commit are complete.

## Execution Outcome

1. Generated and retained the original raster sources, then produced a clean
   runtime albedo and transparent Traveler sheet under the canonical Flooded
   Works art paths.
2. Wired the background, material presenter, and sprite presenter without
   changing collision, transforms, camera values, or combat ownership.
3. Passed Godot import, the Kenney asset inspection, the expanded deterministic
   validator, native rendered captures, Web export, and built-canvas console and
   key smoke checks.

## Completion Criteria

- [x] The current map uses the approved 2D backdrop and a project flat-color raster surface while its 3D geometry/collision remains unchanged.
- [x] Traveler is visibly represented by a full-body 2D sprite with deterministic idle, walking, dash-rate, and four camera-relative facing states.
- [x] Existing sword, ranged, guard, direction, target, pulse, potion, pause, and reset behavior remains functional and readable.
- [x] Every regression guard and final validation gate passes.
- [x] No external dependency, unowned `.import` edit, duplicate presentation owner, chroma background, or stale primitive body remains visible.
- [x] Asset prompts, runtime paths, and validation commands are recorded in canonical project documents.

## Stop Conditions

Completed on 2026-07-17 after all completion criteria passed and the plan was
marked `done`; the scoped commit is recorded in the repository history.

Escalate only when both allowed sprite-generation/cleanup attempts fail, the
texture cannot render in GL Compatibility without corrupting geometry
readability, or the owner requests a different actor direction count or art
identity.

Do not stop merely because the first generated asset needs its permitted single
retry, a material scale needs the bounded correction, or one validator/capture
needs a task-scoped fix.

## Open Questions

No material design or technical question remains inside this pass. Enemy art,
attack-specific sprite sheets, and a production modular terrain kit require a
later owner-approved scope.

## Execution Evidence

- Deterministic validator result: `PASS: raster world, sprite locomotion, exact
  input, cutaway arena, follow camera, facing, attack-time targeting, cover,
  guard, potion, pulse, and pause contracts`.
- Web export result: `WEB_EXPORT_OK`; the exported PCK is 34,531,160 bytes.
- Browser result: the built canvas loaded at the managed Codex port with the
  expected title, one visible canvas, the full action-key smoke sequence, and no
  console error or warning entries.
- Source-only chroma and draft files are excluded with `.gdignore`; only the two
  runtime PNGs are included in the Web export.
