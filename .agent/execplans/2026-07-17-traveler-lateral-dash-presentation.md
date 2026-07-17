---
type: plan
status: done
owner: BK
created: 2026-07-17
last_reviewed: 2026-07-18
scope: Add authored lateral locomotion and a distinct raster dash presentation to the current 3D combat proof
related:
  - ./2026-07-17-traveler-raster-action-correction.md
  - ../../docs/product/isometric_action_rpg_product_brief.md
  - ../../art/world/flooded_works/isometric/README.md
---

# Traveler Lateral Walk and Dash - Execution Plan

The current gameplay motor, camera, collision, attacks, and action timings stay
authoritative. Two phases add one dedicated side-on walk atlas, one dedicated
dash atlas, and distance-spaced dash afterimages so left/right movement and
Space dash no longer reuse the ordinary diagonal walk presentation.

## Why / Context

`TravelerSpritePresenter3D` currently maps every camera-relative direction into
only an away or toward row and mirrors it for the opposite horizontal direction.
Consequently pure screen-left/right movement still looks diagonal. Dash has no
presentation state and advances the ordinary walk sheet from its high travel
distance, so the visual does not read as a deliberate evasive action.

## Purpose

- Objective: make lateral movement unmistakably side-on and make Space dash
  visually distinct without changing input, displacement, invulnerability, or
  action priority.
- Final artifact: two normalized 2048x1024 raster atlases, presenter direction
  and dash-state selection, short-lived raster afterimages, validation, captures,
  build evidence, and an updated art record.
- Completion state: pure left/right movement selects the lateral atlas, diagonal
  and depth movement retains the current locomotion atlas, dash selects its atlas
  and leaves stationary fading images, and every existing gameplay gate passes.

## Pre-plan Evidence Already Verified

| Source or path | Verified fact | Decision affected | Freshness or recheck boundary |
| --- | --- | --- | --- |
| Root `AGENTS.md`, `.agent/PLANS.md` | Godot 4.7, project-owned raster art, responsibility-shaped player presentation, and an ExecPlan for more than five files are required. | Engine, ownership, document, and validation route. | Re-read only if project instructions change. |
| `scripts/player/traveler_sprite_presenter_3d.gd` | The presenter has no dash state and reduces all facings to two depth rows plus mirroring. | Extend this owner instead of adding state selection to the motor. | Recheck after integration. |
| `scripts/player/traveler_3d.gd` | Dash truth is already authoritative: `14 m/s`, `0.18 s`, and existing input/action precedence. | Pass progress only; do not modify movement or combat timing. | Recheck after validator passes. |
| Existing actor atlases and rendered captures | Runtime actor sheets are 4x2, 512-square cells, alpha, baseline y=482, flat-color, outline-free. | New assets use the identical runtime contract. | Recheck after import and capture. |
| Product brief and previous completed raster plan | Space is dash, current fixed isometric camera is accepted, and animation must not own movement or damage. | Keep gameplay semantics unchanged and confine work to presentation. | Recheck only if the product spec changes. |

## Locked Decisions

| Topic | Final decision | Rationale / source |
| --- | --- | --- |
| Lateral sector | Use the lateral atlas only when the absolute camera-right component is at least `1.5x` the depth component; pure left/right qualifies while arrow-key diagonals stay on the accepted diagonal atlas. | Prevents boundary jitter and preserves the existing diagonal art for diagonal intent. |
| Lateral art | Author one four-frame right-facing profile row and mirror it for left; duplicate the normalized row into the uniform two-row runtime format. | A true profile fixes readability; deterministic duplication avoids generation drift and keeps every actor atlas 4x2. |
| Dash art | Use one 4x2 atlas: away-right and toward-right rows, mirrored for left, with compress/launch/glide/brake columns. | The fixed camera still requires depth-facing information during dash. |
| Dash effect | During the authoritative dash only, emit copies of the selected dash frame every `0.65 m`; each copy is top-level, non-colliding, teal-tinted, and fades in `0.16 s`. | Gives a readable raster motion trail without baking effects into collision or movement. |
| State priority | Melee, guard, ranged, dash, locomotion. | Existing committed action precedence remains unchanged; dash appears only when gameplay accepts it. |
| Dependencies | Use built-in image generation, the existing chroma cleanup/normalizer, and Godot built-ins only. | No external runtime asset or package is needed. |

## Rejected Alternatives

| Alternative | Why it was viable | Why it was rejected |
| --- | --- | --- |
| Continue mirroring the diagonal walk | No new art or logic. | It is the exact visual ambiguity the user rejected. |
| Author eight independent directions | Maximum directional specificity. | It multiplies identity drift and art cost before the fixed-camera proof is accepted. |
| Stretch or rotate the existing walk sprites | Fast procedural change. | It distorts the figure and still does not create a true side-on gait. |
| Add a particle plug-in for dash | Could provide a rich trail. | It adds an unnecessary dependency and a mismatched effect style. |
| Change dash speed/duration to improve feel | Might make the effect more visible. | The request is presentation-only; current physics contracts already pass. |

## Current State

Already true or landed:

- The Traveler is one `Sprite3D` driven by gameplay state and actual distance.
- Melee, ranged, and guard each use dedicated raster atlases.
- Dash input, movement, invulnerability, and cooldown have deterministic tests.

Remaining implementation:

- Generate, clean, normalize, import, and inspect lateral/dash actor sheets.
- Add lateral classification, dash selection, and distance-spaced afterimages.
- Extend deterministic tests, visual captures, build checks, and art records.

## Scope / Non-scope

In scope:

- Pure camera-left/right walk and idle presentation.
- Space dash pose and afterimage presentation.
- Current scene wiring, validation, visual evidence, and source record.

Out of scope:

- Movement tuning, dash timing, invulnerability, attack controls, enemies,
  camera, map, UI, hit/defeat states, and new external dependencies.

Destructive or irreversible actions:

- None; existing sheets and gameplay contracts remain available.

Exact actions requiring owner/user approval:

- None; the requested presentation change uses project-owned generated assets
  and does not alter external state or dependencies.

## Assumptions

- “옆으로” means pure screen-space left/right input under the fixed isometric
  camera, not every world-axis direction with a horizontal component.
- A dash-specific actor pose plus fading raster afterimages is the requested
  “different effect”; it must remain presentation-only.

## Proposed Design

`Traveler3D` supplies dash progress together with the existing facing, traveled
distance, and action progress. `TravelerSpritePresenter3D` projects facing onto
camera-right and camera-away, classifies a narrow lateral sector, selects the
appropriate texture/row/mirror, and maps dash progress to four columns. While
dash is active it accumulates actual displacement and creates top-level
`Sprite3D` snapshots of the current dash frame. Those snapshots tween alpha to
zero and free themselves; they never own transform, collision, input, or damage.

## Architecture and Ownership

| Concern | Final owner | Interface or invariant | Existing owner to reuse or retire |
| --- | --- | --- | --- |
| Dash truth | `scripts/player/traveler_3d.gd` | Supplies normalized active progress; timing and velocity remain unchanged. | Reuse current motor and precedence. |
| Direction/state art | `scripts/player/traveler_sprite_presenter_3d.gd` | Selects only texture/frame/flip and transient visual snapshots. | Extend current presentation owner. |
| Actor assets | `art/world/flooded_works/isometric/actors/` | 2048x1024, 4x2, alpha, y=482 baseline, safe cell margins. | Reuse existing atlas contract. |
| Scene wiring | `CombatSandbox3D.tscn` | Exports lateral and dash textures on `ActorSprite`. | Extend current scene resource table. |
| Evidence | Existing validator/capture scripts and art README | Assert selection, unchanged physics, afterimage lifecycle, and rendered appearance. | Extend current gates without weakening them. |

## As-Is / To-Be Delta Map

| Concern | As-is | To-be | Acceptance check | Guard / leftover check |
| --- | --- | --- | --- | --- |
| Pure lateral movement | Diagonal depth sprite, mirrored | True profile four-frame gait | Right selects lateral/right; left selects lateral/mirrored | Up/down and diagonals still select normal locomotion |
| Dash actor | Ordinary walk columns spin from distance | Dedicated four-phase dash pose | Active dash selects dash atlas and progress column | Duration, speed, cooldown, and invulnerability unchanged |
| Dash motion cue | None | Fixed-distance fading raster snapshots | At least two world-stationary afterimages appear during a clear dash | Snapshots have no collision and clean themselves up |

## Tasks

### Phase 1: Produce the lateral and dash raster atlases

Goal: create two coherent generated sources and deterministic runtime atlases.

Source owners touched: `art/source/flooded_works/isometric/actors/`,
`art/world/flooded_works/isometric/actors/`, `tools/art/normalize_sprite_sheet.py`

- [x] **1.1 Generate and normalize the lateral walk.**
  - As-is: no true profile walk exists.
  - To-be: four right-facing profile phases, duplicated into a 4x2 runtime atlas.
  - Accept: one stable full-body figure per cell, shared scale/baseline, readable
    contact/pass/opposite/pass gait, transparent background, safe margins.
  - Guard: no diagonal facing, weapon, outline, noise, shadow, text, or grid.
- [x] **1.2 Generate and normalize the dash.**
  - As-is: dash uses ordinary locomotion.
  - To-be: two depth rows with compress/launch/glide/brake phases.
  - Accept: eight coherent figures preserve Traveler identity and fit the common atlas contract.
  - Guard: no baked trail, hit marker, collision implication, extra equipment, or chroma residue.

Batch acceptance: direct image inspection and alpha/cell validators pass for both
atlases before code wiring.

Batch guard: generated chroma sources stay under the ignored source path and no
unrelated `.import` file is staged.

### Phase 2: Integrate and prove lateral/dash presentation

Goal: wire both atlases and the afterimage effect without gameplay regression.

Source owners touched: `traveler_sprite_presenter_3d.gd`, `traveler_3d.gd`,
`CombatSandbox3D.tscn`, validation/capture scripts, and the art record.

- [x] **2.1 Add deterministic lateral and dash state selection.**
  - As-is: two depth rows cover all movement; no dash state exists.
  - To-be: lateral sector selects its atlas and active dash selects its own state/progress.
  - Accept: direct presenter fixtures and real input fixtures select each expected texture/frame.
  - Guard: action priority and all authoritative action timings remain unchanged.
- [x] **2.2 Add and validate distance-spaced dash afterimages.**
  - As-is: dash has no separate effect.
  - To-be: top-level raster snapshots remain at emitted world positions and fade/free themselves.
  - Accept: a dash produces multiple snapshots and none remain after the fade window.
  - Guard: snapshots have no collision, process, gameplay signal, or transform authority.
- [x] **2.3 Close rendered evidence, build, docs, and commit.**
  - As-is: captures cover diagonal walk and combat actions only.
  - To-be: dedicated lateral and dash captures are inspected at 1280x720; native
    validator, Web export, and production-style smoke pass; plan and art record are final.
  - Accept: side walk reads as profile and dash reads as one coherent pose plus trail.
  - Guard: task commit excludes pre-existing unrelated `.import` changes.

Batch acceptance: deterministic tests, generated captures, import, and production
build show the requested presentation and retain all prior gameplay contracts.

Batch guard: `git diff --cached` contains only task-owned assets, code, evidence,
docs, and their necessary new Godot imports.

## Test Plan

Inner-loop commands:

- `./tools/godot.ps1 --path . --editor --headless --quit`
- `./tools/godot.ps1 --path . --headless --script res://tools/validation/validate_movement_and_actions.gd`

Final gates:

- Full tests: deterministic movement/action validator passes.
- Production build and start: Web export completes and the built canvas loads.
- Manual UI/browser routes and viewport sizes: inspect lateral and dash captures
  at 1280x720 plus existing 960x540, 1280x720, and 1920x1080 ready captures.
- Persistence/data validation: not applicable; no save data changes.
- Documentation and lifecycle validation: plan becomes `done`, art record lists
  prompts/assets/runtime behavior, and no duplicate active plan remains.

Rerun policy:

- Rerun a narrow failed check only after a concrete code/asset correction.
- Rerun full gates after the suspected cause changes.
- Record non-blocking engine/import warnings rather than hiding them.

## Verification

- Godot 4.7 headless import completed and imported both new actor atlases.
- `validate_movement_and_actions.gd` passed lateral selection, dash atlas
  progress, multiple distance-spaced afterimages, world-stationary placement,
  automatic cleanup, and every prior movement/action/camera/collision contract.
- Native capture generation passed. Original-size review accepted
  `movement-check-lateral-1280x720.png` and
  `movement-check-dash-1280x720.png`.
- `tools/export_web.ps1` returned `WEB_EXPORT_OK` and produced HTML, JavaScript,
  PCK, and WASM release files.
- The built artifact booted as `Cardborne` on fastrun `codex` port 13029 with no
  browser warning/error; Space input moved the Traveler/camera. The task-owned
  server and browser tabs were then closed.
- `git diff --check` passed for the task-owned text files.
- A scoped `master` commit was created with only the 14 task-owned code, asset,
  import, validation, documentation, and plan files; pre-existing unrelated
  `.import` changes remain unstaged.

## Rollback / Safety

Removing the two exported textures and the presenter branches returns runtime
selection to the current locomotion path. Existing gameplay files and old actor
atlases remain intact. Generated source and runtime images are additive.

## Risks

- Image generation may drift from the accepted identity; reject or regenerate
  rather than compensating with runtime distortion.
- Wide dash poses may cross 512px cell margins; normalize at a smaller fixed
  scale if needed rather than clipping.
- Afterimages parented normally would follow the Traveler; each snapshot must be
  top-level and its world position must be verified during movement.

## Predetermined Error Handling and Contingencies

| Trigger | Required response | Limit / escalation point |
| --- | --- | --- |
| Chroma fringe remains after cleanup | Retry once with one-pixel edge contraction and inspect at original size. | Regenerate if the subject edge is still contaminated. |
| Generated cells are inconsistent or malformed | Regenerate one targeted asset with stronger identity/grid constraints. | Do not hand-edit anatomy or ship a morphing sequence. |
| Dash pose exceeds cell safety margin | Normalize the entire atlas at one smaller fixed scale. | Do not scale individual frames differently. |
| Existing gameplay validator fails | Fix only presentation integration unless evidence proves a pre-existing failure. | Do not alter gameplay constants to make the visual test pass. |

## Open Questions

None. The scope and presentation contracts are decision-complete for this task.

## Decision Notes

- The request is interpreted as a true screen-space profile for left/right, not
  a replacement for the accepted diagonal/depth locomotion rows.
- The dash effect deliberately combines a dedicated pose with afterimages so it
  remains readable in both screenshots and motion.

## Progress

- [x] Phase 1: raster atlases generated and accepted.
- [x] Phase 2: runtime, validation, captures, build, and docs completed.
- [x] Final gates: scoped commit created with unrelated workspace changes excluded.

## Next Steps

1. No work remains in this plan. Treat any hit/defeat sprites, wider directional
   coverage, or dash gameplay tuning as a separately accepted task.

## Completion Criteria

- [x] Every user-visible requirement passes its acceptance check.
- [x] Every regression guard and final validation gate passes.
- [x] No retired owner, duplicate path, placeholder, or unresolved material decision remains.
- [x] Durable assets, prompts, and run/verify commands are recorded in the art record.

## Stop Conditions

Complete when: pure lateral movement visibly uses a profile gait, active dash
uses its own pose and fading trail, all prior movement/action tests pass, and the
scoped commit is created.

Escalate only when: generated identity cannot meet the accepted art contract
after one targeted regeneration or local Godot cannot import/build the assets.

Do not stop when: the first generated image needs cleanup, normalization,
regeneration, or a narrow code/test correction.

## Handoff

```text
Goal: Add true lateral Traveler locomotion and a distinct Space-dash raster effect.

Read first: this plan, scripts/player/traveler_sprite_presenter_3d.gd, scripts/player/traveler_3d.gd, and art/world/flooded_works/isometric/README.md.

Execute exactly: create two 4x2 atlases, wire lateral/dash state, add top-level fading dash snapshots, then extend existing evidence.

Validate with: the deterministic Godot validator, native captures, Web export, built-canvas smoke, and scoped git diff.

Stop when: all completion criteria pass and the plan is status done.
```
