---
type: plan
status: done
owner: BK
created: 2026-07-17
last_reviewed: 2026-07-17
topic: Correct Traveler raster locomotion and action presentation
scope: Replace unstable locomotion frames and all remaining 3D Traveler action visuals in the native 3D combat proof
related:
  - ./2026-07-17-rasterized-3d-presentation.md
  - ../../docs/product/isometric_action_rpg_product_brief.md
  - ../../art/world/flooded_works/isometric/README.md
---

# Traveler Raster Actions - Execution Plan

The current hybrid 3D proof keeps its movement, collision, targeting, hit timing,
and camera contracts. Two phases replace the unstable generated walk cycle and
the remaining 3D sword, bow-shot, and shield presentation with coherent 2D
raster states driven by authoritative gameplay timers.

## Purpose

- **Objective:** make Traveler movement visually stable and make melee, ranged,
  and guard read as one consistent sprite-based actor.
- **Final artifact:** a distance-driven two-row locomotion sheet, three two-row
  action sheets, a raster projectile, and one presentation owner wired into the
  existing `CharacterBody3D` proof.
- **Completion state:** deterministic validation, rendered state captures, Web
  export, and built-canvas smoke checks pass with no visible 3D sword or shield.

## Why / Context

The first 4x4 sheet generated sixteen largely independent figures. Adjacent
frames change foot baseline, silhouette, garment volume, and apparent facing,
so an otherwise correct movement motor looks like a character morphing or
sliding. Melee and guard captures also show a raster actor combined with small
3D equipment meshes, which contradicts the accepted sprite presentation.

## Pre-plan Evidence Already Verified

| Source or path | Verified fact | Decision affected | Freshness or recheck boundary |
| --- | --- | --- | --- |
| Root `AGENTS.md` and `.agent/PLANS.md` | The proof uses Godot 4.7, retained flat raster art, responsibility-shaped modules, and an ExecPlan for more than five files. | Engine, document, scope, and ownership. | Re-read only if project instructions change. |
| `traveler-walk-sheet-v1.png` and current captures | Frames change body proportions and foot placement; melee and guard still render 3D equipment next to the sprite. | Replace, rather than retime, the visible actor assets. | Recheck after new captures. |
| `scripts/player/traveler_3d.gd` | Movement, action timers, target resolution, hit timing, and guard truth already exist. | Presentation reads state and never owns gameplay timing. | Recheck after player integration. |
| `CombatSandbox3D.tscn` | `ActorSprite` is a 4x4 `Sprite3D`; hidden primitive body/head plus sword and shield nodes remain. | Wire four raster sheets and retire all visible equipment meshes. | Recheck after scene edits. |
| Product brief and active pivot plan | Fixed isometric camera supports two authored diagonal facings plus horizontal mirroring; melee is a sword, ranged is bow-like, and guard uses the retained shield identity. | Two authored rows, mirrored left/right, with explicit equipment in action art. | Recheck only if combat or camera contracts change. |
| Retained Traveler, sword, bow, and round-shield illustrations | The exact identity and equipment palette already exist as project-owned references. | Use them as image-generation identity inputs, not runtime UI crops. | Recheck if equipment identity changes. |

## Locked Decisions

| Topic | Final decision | Rationale / source |
| --- | --- | --- |
| Direction count | Author away-right and toward-right rows only; mirror each row horizontally for left-facing states. | Mirroring guarantees identical silhouette and halves generation drift. |
| Sheet format | Normalize every actor sheet to 2048x1024, four columns by two rows; each runtime cell is 512x512 with one grounded full-body figure. | Square cells accommodate the sword/bow without clipping and keep region math deterministic. |
| Atlas normalization | Extract the eight largest alpha-connected figures, apply one fixed 0.9 scale, center each in its exact cell, and align every foot baseline to y=482. | Generated placement is approximate; deterministic repacking prevents boundary clipping and scale drift. |
| Locomotion cadence | Advance frames from actual X/Z distance traveled; idle holds contact frame zero. | Prevents foot-rate mismatch during acceleration, guard speed, and dash. |
| Action sheets | Use separate melee, ranged, and guard sheets. Melee columns map startup/swing/contact/recovery; ranged maps ready/draw/release/recover; guard maps raise/settle/hold/hold-breath. | Each gameplay state has an explicit readable pose without animation owning damage. |
| State priority | Melee, then guard, then ranged, then locomotion. | Committed melee stays visible; held defense supersedes an older ranged recovery pose. |
| Equipment | Sword, bow, and shield are painted into their action sheets; existing 3D sword/shield nodes never become visible. | A single raster actor avoids mixed media and double equipment. |
| Projectile | Replace the procedural glowing sphere mesh with one project-owned raster bolt `Sprite3D`; retain the existing `Area3D` collision and movement. | Ranged presentation becomes raster without changing projectile truth. |
| Ownership | New `TravelerSpritePresenter3D` owns texture/frame/flip selection; `Traveler3D` supplies authoritative state and timers. | Keeps presentation logic out of combat ownership. |
| Dependencies | Use Godot built-ins and original project raster assets only. | Matches project policy and avoids licensing/runtime additions. |

## Rejected Alternatives

| Alternative | Why it was viable | Why it was rejected |
| --- | --- | --- |
| Retiming the existing 4x4 sheet | No new assets required. | Timing cannot fix changing proportions, baseline, or direction. |
| Four independently authored directional rows | Avoids mirroring asymmetry. | It recreates the identity drift that caused the defect. |
| Keep 3D sword and shield over a corrected walk sprite | Smallest code change. | It preserves the visible mixed-media defect the owner rejected. |
| Let animation callbacks fire hits/projectiles | Easy frame synchronization. | Damage and targeting must remain authoritative in gameplay code. |
| Replace the proof with a 2D scene | Sprite animation would be conventional. | It discards accepted 3D collision, cover, camera, and movement work. |

## Current State

Already true or landed:

- Movement, attack, guard, target assistance, collision, camera, and Web export
  gates pass independently of presentation.
- The retained identity and equipment reference images are project-owned.
- The old sheet remains a rollback reference and is not edited destructively.

Completed implementation:

- Four coherent actor sheets and one projectile image are generated, cleaned,
  normalized, imported, and recorded.
- One sprite presenter owns direction, mirroring, distance cadence, and action
  frame selection; visible 3D action meshes are retired and regression evidence
  covers the replacement.

## Scope / Non-scope

In scope:

- Traveler idle/walk/dash facing presentation.
- Traveler melee, ranged, and held-guard presentation.
- Traveler ranged projectile appearance.
- Current sandbox scene, validator, captures, product brief, and art evidence.

Out of scope:

- Enemy or boss sprites, new combat timings, combo expansion, new weapons,
  camera changes, map changes, UI redesign, and effects beyond the ranged bolt.

Destructive or irreversible actions:

- None. The superseded locomotion sheet remains unreferenced as rollback
  evidence; gameplay collision and action nodes are preserved.

Exact actions requiring owner/user approval:

- None. The owner explicitly requested corrected movement and sprite-based
  attack/defense; no external dependency or third-party asset is introduced.

## Assumptions

- The fixed orthographic camera and current action durations remain authoritative
  for this correction. A later camera or combat redesign requires new art timing.
- Horizontal mirroring is acceptable because no gameplay hand or equipment side
  currently carries asymmetric mechanics.

## Proposed Design

`Traveler3D` continues to resolve input and gameplay. After movement and action
updates it passes facing, actual displacement, dash state, melee progress, ranged
visual progress, and guard state to `TravelerSpritePresenter3D`. The presenter
selects one texture, one of two authored rows, horizontal mirroring, and one of
four columns. It never modifies position, velocity, targets, cooldowns, damage,
or collision. `ProofProjectile3D` retains its current physics but instantiates a
billboard raster sprite instead of a sphere mesh.

## Architecture and Ownership

| Concern | Final owner | Interface or invariant | Existing owner to reuse or retire |
| --- | --- | --- | --- |
| Gameplay state/timing | `scripts/player/traveler_3d.gd` | Supplies state/progress after authoritative updates. | Reuse all movement, hit, targeting, and guard truth. |
| Sprite selection | `scripts/player/traveler_sprite_presenter_3d.gd` | Writes only texture, frame, and `flip_h`. | Retire frame selection from `Traveler3D`. |
| Actor assets | `art/world/flooded_works/isometric/actors/` | 2048x1024, 4x2, alpha, aligned square cells and baseline. | Supersede runtime use of `traveler-walk-sheet-v1.png`. |
| Projectile appearance | `scripts/combat/proof_projectile_3d.gd` and `effects/` PNG | Sprite only; collision and speed unchanged. | Retire procedural sphere mesh. |
| Scene composition | `CombatSandbox3D.tscn` | Exports four actor textures; no visible 3D equipment. | Keep capsule collision and feedback ring. |
| Regression evidence | Existing validation and capture scripts | Assert assets, mapping, timing, and absence of 3D gear. | Extend, never weaken, current gameplay gates. |

## As-Is / To-Be Delta Map

| Concern | As-is | To-be | Acceptance check | Guard / leftover check |
| --- | --- | --- | --- | --- |
| Walk | 4x4 independent figures at fixed FPS | 4x2 two-direction sheet, mirrored, distance-driven | Adjacent frames keep identity/feet and advance with distance | No time-only walk clock or four independent direction rows |
| Melee | Static actor plus 3D box sword | Four-frame full-body sword action | Startup/contact/recovery captures use matching sprite columns | Sword mesh never becomes visible; hit time unchanged |
| Ranged | Static actor plus sphere projectile | Four-frame bow action plus raster bolt | Release capture shows bow pose and raster projectile | Cooldown, target resolution, collision, and damage unchanged |
| Guard | Static actor plus cyan 3D shield | Raise/hold full-body shield action | Hold capture shows shield integrated into actor art | Guard multiplier and movement restriction unchanged |

## Tasks

### Phase 1: Produce coherent raster states

Goal: create five runtime assets whose identity, baseline, grid, and transparency
are stable enough for deterministic region playback.

Source owners touched: `art/source/flooded_works/isometric/actors/`,
`art/world/flooded_works/isometric/actors/`, and `effects/`.

- [x] **1.1 Generate and clean the corrected locomotion sheet.**
  - As-is: sixteen independent figures morph across a 4x4 grid.
  - To-be: one 2048x1024 4x2 sheet with two right-facing rows and four coherent walk phases.
  - Accept: all eight cells contain one character, share scale and foot baseline,
    and retain the same hood, mask, coat, scarf, proportions, and palette.
  - Guard: no grid lines, text, shadows, chroma residue, weapons, or cell crossing.
- [x] **1.2 Generate and clean melee, ranged, and guard sheets.**
  - As-is: action equipment is separate 3D proof geometry.
  - To-be: three 4x2 sheets preserve the locomotion identity and include only
    the action-appropriate retained sword, bow, or round shield.
  - Accept: each row reads in the locked four-phase order with aligned feet and
    no duplicated limbs or equipment.
  - Guard: no baked hit markers, UI, targets, projectile, or gameplay state.
- [x] **1.3 Generate and clean the raster bolt.**
  - As-is: a glowing mustard sphere represents the ranged shot.
  - To-be: one small flat raster bolt with a clear silhouette and alpha.
  - Accept: transparent corners, no text, no floor shadow, and readable at the
    current camera scale.
  - Guard: no collision or size contract is inferred from image dimensions.

Batch acceptance: contact sheets and alpha checks show one stable Traveler
identity, exactly aligned 512-square cells, a shared y=482 baseline, and no
mixed-media equipment requirement.

Batch guard: generated source files remain excluded by `.gdignore`; runtime
imports contain only approved cleaned PNGs.

### Phase 2: Integrate and prove action presentation

Goal: every current Traveler movement/combat state selects the correct raster
pose without changing gameplay behavior.

Source owners touched: `traveler_3d.gd`,
`traveler_sprite_presenter_3d.gd`, `proof_projectile_3d.gd`,
`CombatSandbox3D.tscn`, and existing validation/capture scripts.

- [x] **2.1 Add the presentation owner and distance-driven locomotion.**
  - As-is: `Traveler3D` selects one of sixteen fixed-FPS frames directly.
  - To-be: the presenter maps two rows plus mirror and advances locomotion from
    actual displacement, with idle contact and dash using the same distance law.
  - Accept: movement, stop, opposite-facing, guard-speed, and dash fixtures map
    deterministically with no frame advance while stationary.
  - Guard: presenter never writes gameplay state or transform.
- [x] **2.2 Wire melee, ranged, guard, and projectile raster states.**
  - As-is: 3D sword/shield and procedural projectile mesh remain visible.
  - To-be: gameplay timers select action columns; all equipment appears only in
    the actor sheets and the projectile uses the raster bolt.
  - Accept: captures show startup/contact/recovery or hold states, and validators
    confirm existing damage, cooldown, block, cover, and target behavior.
  - Guard: no 3D sword/shield mesh becomes visible and no action callback deals damage.
- [x] **2.3 Close validation, evidence, build, and documentation.**
  - As-is: validators assert the superseded 4x4 walk contract.
  - To-be: assert 4x2 assets, two-row mirroring, distance cadence, state priority,
    action progress, raster projectile, and existing gameplay contracts.
  - Accept: Godot import, deterministic validator, native captures, Web export,
    built-canvas smoke, lifecycle audit, and diff checks complete.
  - Guard: no unrelated `.import` changes enter the scoped commit.

Batch acceptance: ready, movement, melee, ranged, guard, and edge captures read
as one coherent raster actor and all prior gameplay gates still pass.

Batch guard: a presentation defect cannot be accepted by weakening movement,
combat, collision, cover, camera, or input assertions.

## Test Plan

Inner-loop commands:

- `.\tools\godot.ps1 --headless --path . --import`
- `.\tools\godot.ps1 --headless --path . --script res://tools/validation/validate_movement_and_actions.gd`
- `git diff --check`

Batch gates:

- Run native `capture_movement_check.gd` and inspect ready, facing, melee,
  ranged, guard, and both arena-edge captures at 1280x720.
- Inspect the actor sheets at original resolution and verify alpha, occupied
  cells, shared foot baseline, and absence of chroma fringe.

Final gates:

- Full lint/type checks: Godot import plus deterministic validator.
- Full tests: existing movement/action suite with raster-action assertions.
- Production build and start: `.\tools\export_web.ps1`, then managed Codex lane.
- Manual UI/browser routes and viewport sizes: built proof at 1280x720; native
  ready captures at 960x540, 1280x720, and 1920x1080.
- Persistence/data validation: not applicable; no save data changes.
- Documentation and lifecycle validation: targeted lifecycle audit, links,
  `git diff --check`, and explicit task-owned staging review.

Rerun policy:

- Rerun a failed narrow check only after a concrete change or new hypothesis.
- Rerun full gates only after the suspected cause changed.
- Record known unrelated `.import` and protected-document findings without
  staging or rewriting them.

## Rollback / Safety

- Keep `traveler-walk-sheet-v1.png` and its source record unreferenced as the
  immediate rollback asset.
- Presentation integration is confined to scene resources, a presenter script,
  and image references; the `CharacterBody3D`, capsule, collision masks, combat
  queries, and camera remain untouched.
- Stage only paths named by this plan and never clean the existing dirty worktree.

## Risks

- Image generation can drift identity or violate equal cells. Each failed sheet
  receives one targeted retry. If the retry still drifts, use one accepted
  toward row and one accepted away row as immutable anchors, mirror left/right,
  and duplicate the closest valid contact/recoil frames rather than integrating
  malformed figures.
- Chroma removal can leave a fringe. Retry the helper once with edge contraction
  1; reject the asset if the silhouette is damaged.
- Large action poses can clip an approximate generated cell. Normalize scale and padding during
  local raster processing into 512-square cells; never move collision to fit art.

## Predetermined Error Handling and Contingencies

| Trigger | Required response | Limit / escalation point |
| --- | --- | --- |
| Empty, crossed, or inconsistent actor cell | One targeted image edit using the prior output and exact invariant list. | After one retry, use the locked valid-row fallback; do not accept malformed cells. |
| Chroma fringe | Rerun installed remover with `--edge-contract 1`. | Reject if the silhouette loses visible equipment/limb pixels. |
| Action frame does not align with gameplay timing | Adjust only normalized progress-to-column thresholds. | Never change damage, cooldown, guard, or target timings for art. |
| Sprite clips foreground or cell bounds | Adjust presenter pixel size/local Y or normalize image padding once. | Never move collision or camera to fit art. |
| Web misses a texture | Verify path case, re-import, and export once. | Do not add runtime file-loading fallbacks. |

## Decision Notes

- The defect is asset continuity plus mixed presentation, not a movement-motor
  defect; movement constants stay unchanged.
- Horizontal mirroring is the key consistency control and restores the original
  pivot plan's bounded four-facing art strategy.
- Action animation reflects gameplay progress; it cannot create gameplay events.

## Execution Evidence

- Built-in image generation produced one corrected locomotion selection, three
  action selections, and one bolt. The selected chroma sources are retained
  under `art/source/flooded_works/isometric/actors/`; runtime PNGs have alpha,
  safe cell margins, and a common y=482 foot baseline.
- `TravelerSpritePresenter3D` now maps two authored direction rows plus
  horizontal mirroring. Locomotion advances from actual X/Z displacement, while
  melee contact, ranged release, and guard hold select their dedicated atlases.
- The post-implementation quality pass found and fixed one action-overlap defect:
  ranged could begin during a committed melee. The validator now rejects that
  overlap in addition to the original same-frame precedence cases.
- Deterministic result: `PASS: raster world, distance-driven locomotion, raster
  melee/ranged/guard, raster projectile, exact input, cutaway arena, follow
  camera, targeting, cover, potion, pulse, and pause contracts`.
- Native capture inspection confirmed a stable grounded walk silhouette, a
  full-body sword contact pose, bow release plus raster bolt, and shield hold;
  no 3D sword or shield is visible.
- The managed Codex lane served the exported artifact. Chrome loaded a focused
  1280x720 Godot canvas with the new assets and no warning/error logs. Held and
  frame-exact actions remain proven by native InputEvents and captures because
  browser tap automation does not provide a reliable held-key capture.
- The final release export after the action-overlap correction succeeded with
  all four required files; `index.pck` is 36,662,548 bytes.
- `git diff --check` passed. Task-owned staging excludes all pre-existing or
  tool-refreshed unrelated `.import` changes.
- Targeted lifecycle audit leaves the active product brief as a spec and the
  art records as evidence; this completed document is now `plan + done`.

## Open Questions

No material product or technical question remains inside this correction. New
weapon sets, combo count, asymmetric equipment, and enemy art require a later
owner-approved scope.

## Progress

- [x] Phase 1: coherent raster locomotion, action, and projectile assets exist.
- [x] Phase 2: presentation integration and all regression gates pass.
- [x] Final gates and task-owned commit are complete.

## Next Steps

This correction is complete. Hit, defeat, dedicated dash, enemies, bosses, and
weapon variants remain separate future milestones rather than unfinished work
inside this plan.

## Completion Criteria

- [x] Walking no longer changes Traveler identity, scale, or foot baseline.
- [x] Melee, ranged, and guard display full-body raster action poses with no
  visible 3D sword or shield.
- [x] The ordinary ranged projectile is a raster sprite and still stops on cover.
- [x] All gameplay and presentation regression gates pass.
- [x] Asset prompts, mappings, paths, and limitations are recorded canonically.

## Stop Conditions

Complete when every completion criterion passes, the plan is `done`, and the
scoped commit is on the current branch.

Escalate only when both the targeted retry and deterministic valid-row fallback
cannot produce a readable Traveler silhouette, or the owner changes the fixed
camera, equipment identity, or action timing contract.

Do not stop because one generated sheet needs its allowed retry, local padding
normalization, or one progress threshold adjustment.

## Handoff

```text
Goal: Correct Traveler movement and convert every current action to raster art.

Read first: AGENTS.md, this plan, the completed raster presentation plan,
traveler_3d.gd, and art/world/flooded_works/isometric/README.md.

Execute exactly: produce the locked 4x2 sheets and bolt, then integrate them
through a presentation-only owner while preserving all gameplay timings.

Validate with: Godot import, validate_movement_and_actions.gd, native captures,
Web export, built-canvas smoke, lifecycle audit, and diff checks.

Stop when: all completion criteria pass and this plan is marked done.
```
