---
type: plan
status: done
owner: BK
created: 2026-08-10
last_reviewed: 2026-08-10
topic: Option 2 EMP wavefront extraction, outward release motion, exact approval, and production integration
scope: Player EMP charge/release presentation, selected authored raster evidence, focused runtime validation, and production asset promotion
related:
  - ../../AGENTS.md
  - ../../.agents/AGENTS.md
  - ../../.agents/PLANS.md
  - ./2026-08-10-non-boss-combat-and-upgrade-integrity.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/design/cardborne-universal-art-style-reference.png
  - ../../docs/design/visual-replacement-workbench/README.md
  - ../../docs/design/visual-replacement-workbench/candidates/emp-release-wavefront-v4/candidate-metadata.json
  - ../../.agents/cardborne-performance-engineering-policy.md
  - ../../.agents/research/performance/cardborne-runtime-architecture-audit.md
---

# EMP Wavefront Integration - Execution Contract

The user selected direction 2, the single octagonal compression front, from the
reference-led EMP motion sheet. This contract extracts that exact direction into a
production-shaped candidate, makes the release visibly propagate from the vehicle without
changing EMP gameplay resolution, and promotes the raster only after the isolated
AS-IS/TO-BE result receives exact approval.

## Purpose

- Objective: replace the static full-radius EMP release impression with one clear,
  system-blue octagonal wavefront that rapidly expands outward from the player.
- Deliverable: a transparent `512x512` candidate with a `256,256` pivot, comparison and
  provenance evidence, presentation-only scale/origin/color corrections, focused tests,
  and—after exact approval—the same-path production raster and built-product evidence.
- Completion state: the selected wavefront reaches full gameplay radius in the first
  `0.20s` of the existing `0.55s` release lifetime in standard motion; reduced motion
  starts at full radius and fades; gameplay damage, stun, clearing, timing, and capacity
  remain unchanged; all named gates pass and this plan is marked `done`.

## Scope and Boundaries

In scope:

- Direction 2 from `emp_wavefront_motion_sheet.png`, mechanically isolated from its
  100-percent frame without creative geometry changes.
- One centered transparent `512x512` EMP release raster, an AS-IS/TO-BE comparison, hashes,
  authority-pair evidence, and the existing workbench unit's technical ledger.
- A standard-motion radius scale from `0.15` to `1.00` during the first `0.20s`, followed
  by the remainder of the existing fade lifetime.
- A reduced-motion path that displays the final radius immediately and only fades.
- A live charge cue centered on the player's current position, and a release wave centered
  on the actual release position.
- System-blue charge presentation and unmodified authored release color.
- Focused renderer/effect/asset/workbench validation, Godot import, Web export, and one
  production-style built-product visual smoke after promotion.

Out of scope:

- EMP damage `62`, stun `2.1s`, gameplay radius `285`, projectile-clear radius `325`,
  startup `0.42s`, cooldown, input, sound, or gameplay resolution order.
- Electric Field, barriers, enemy shields, dash, Thermal Burst, Drop Mine, boss effects,
  HUD layout, upgrade behavior, enemy balance, or the separate active non-boss contract.
- Multiple rings, lightning, sparks, particle fields, persistent fills, frame animation,
  shader work, extra nodes, new asset identities, or new render batches.
- A new named science-fiction theme, production dependency, engine change, or capacity
  increase.

Constraints and invariants:

- Godot `4.7.1-stable`, GDScript, `effect/emp_release`, `512x512`, pivot `256,256`, the
  fixed 96-effect store, and the existing one-semantic-texture-draw release path remain.
- Damage, stun, and hostile-projectile clearing still resolve immediately across their
  full gameplay radii when charge completes. The expanding wave is short presentation
  feedback, not collision or delayed gameplay truth.
- The canonical visual authority pair remains
  `docs/design/VISUAL_SYSTEM.md` plus
  `docs/design/cardborne-universal-art-style-reference.png` at SHA-256
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- ImageMagick is limited to exact crop, resize, alpha handling, and comparison placement
  of already-authored pixels. It may not redraw or repair the wavefront geometry.
- The production PNG remains byte-identical until the exact isolated candidate comparison
  is approved. Candidate and preview files remain outside the production manifest.
- The renderer adds only bounded scalar arithmetic to an existing effect branch; it adds
  no allocation, node, instance, draw, batch, texture identity, or effect-store entry.

Destructive or irreversible actions:

- None. Production promotion overwrites one version-controlled PNG only after a clean
  technical preview and exact approval; Git retains the previous bytes.

Exact actions requiring owner or user approval:

- Direction 2 is approved as the design direction. The mechanically isolated transparent
  PNG is a new exact byte artifact, so replacing
  `art/visuals/production/gameplay/effects/fx_emp_release.png` requires approval of its
  AS-IS/TO-BE comparison.
- No long performance scenario is authorized by this contract. If later evidence requires
  a 60-second native/Web scenario, report its foreground impact, duration, stopping
  condition, and quiet-machine requirement before running it.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Selected direction | The v4 sheet contains five columns at about 15/55/100 percent scale; the user selected column 2. | `emp_wavefront_motion_sheet.png`, `candidate-metadata.json`, user direction on 2026-08-10 | Use only column 2's final octagonal band and preserve its silhouette through mechanical extraction. | 1.1-1.3 |
| Gameplay timing and radius | `VehicleRun` charges for `0.42s`, then immediately applies damage/stun/clear and emits a `0.55s`, radius-`285` release event. | `scripts/vehicle/vehicle_run.gd`, `_start_emp()`, `_release_emp()` | Preserve every gameplay constant and release operation. | 2.1-2.3 |
| Current release defect | `VehicleCombatRenderer._sync_effects()` draws `authored_emp` at full radius for its whole life and only applies the shared fade. | `scripts/presentation/vehicle_combat_renderer.gd`, `_sync_effects()` | Standard motion scales `0.15 -> 1.00` over elapsed `0.20s`; reduced motion uses `1.00` immediately. | 2.1, 2.3 |
| Charge/release origin | The charge event stores charge-start position; release gameplay and visual use the player's release-time position. `sync()` already receives current player position. | `VehicleRun._start_emp()`, `_release_emp()`; `VehicleCombatRenderer.sync()` | Draw `live_emp_radius` at current player position; keep release at its emitted release position. | 2.1, 2.3 |
| Authored color | Runtime currently supplies command magenta to charge and release, while the selected raster is system blue and authored-color texture drawing multiplies by the event color. | `vehicle_run.gd`; `_draw_semantic_texture()` | Charge uses `Art.SYSTEM`; release event uses `Color.WHITE` so the selected raster retains its authored blue planes. | 2.2, 2.3 |
| Asset contract | `effect/emp_release` already maps to one transparent `512x512` PNG with a centered pivot and gameplay-radius scale. | `asset-manifest.json`, semantic asset provider, workbench unit `emp_authored_replacement` | Keep path, ID, dimensions, pivot, provider ownership, and manifest entry unchanged. | 1.1, 3.1-3.3 |
| Approval boundary | The v4 sheet is reference-grounded, but its metadata says no exact asset is selected or approved and production is false. | v4 `candidate-metadata.json`, workbench README | Record direction selection now; stop production promotion until the isolated candidate comparison is approved. | 1.2, 3.1 |
| Visual authority | The full visual specification was read and the canonical sheet was inspected at original detail; its observed hash matches the required hash. | `VISUAL_SYSTEM.md`, canonical PNG, authority validator contract | Keep familiar hard-surface sci-fi, one dominant silhouette, open center, system-blue hierarchy, and grayscale readability. | 1.1-1.3, 2.4, 4.1 |
| Performance risk | The release already occupies one fixed-cap effect entry and one semantic texture draw. No clean current release-performance result exists. | performance policy, runtime audit, renderer/effect-store code | Add no new render owner or capacity; validate structural budgets and make no broad performance claim. | 2.1-2.3, 4.1-4.3 |
| Tool readiness | ImageMagick 7.1.1, the bundled alpha helper, `tools/godot.ps1`, focused validators, workbench builder, and Web exporter are present. | local command/script inspection on 2026-08-10 | Use those exact local tools; add no dependency. | All |

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership, safety, and
  validation decision is closed.
- Required tools and dependencies are available; the validation commands below match the
  active PowerShell shell and Godot wrapper.
- The sole intentional external stop is the exact raster approval before production
  promotion. Remaining pre-approval unknowns are implementation-local and cannot change
  this contract.

## Tasks

### Phase 1: Approved direction becomes an exact reviewable asset

Goal: preserve option 2 as a centered transparent production-shaped candidate with
complete review evidence and no production change.

Preconditions:

- The visual authority pair has been read/inspected and direction 2 is selected.
- The production EMP hash is recorded before any candidate processing.

Source owners: `emp-release-wavefront-v4/`, `candidate-metadata.json`,
`docs/design/VISUAL_SYSTEM.md`, workbench preview evidence

- [x] **1.1** Produce the exact transparent direction-2 candidate.
  - Change: crop the 100-percent frame with even padding, mechanically remove the dark
    sheet background, resize to `512x512`, and retain the authored octagonal pixels.
  - Accept: PNG is `512x512` RGBA, centered at `256,256`, has meaningful transparent and
    opaque coverage, contains no label/divider/neighbor pixels, and remains legible in
    grayscale at gameplay size.
  - Guard: if alpha handling damages the octagon or cannot remove the gradient cleanly,
    reject the extraction and create a new ImageGen isolation pass using the v4 sheet and
    canonical sheet as actual image references; do not use geometric repair.
- [x] **1.2** Create exact AS-IS/TO-BE evidence and update candidate metadata.
  - Change: place the current production PNG and exact candidate side by side with plain
    evidence labels; record candidate/comparison hashes, extraction steps, selected
    direction, motion contract, and `exact_user_approval=false`.
  - Accept: metadata resolves every path/hash, says `winner_selected=true`, remains
    `production_applied=false`, and distinguishes direction approval from byte approval.
- [x] **1.3** Lock the durable visual contract.
  - Change: update `VISUAL_SYSTEM.md` to name one system-blue octagonal compression front,
    standard/reduced-motion behavior, live charge centering, release centering, and the
    prohibition on persistent fields or multi-ring animation.
  - Accept: the visual authority validator passes and no gameplay value changes.

Batch gate:

- Inspect the candidate and comparison at original detail and at representative gameplay
  size. Run `./tools/validation/validate_cardborne_visual_authority.ps1`.

### Phase 2: The EMP reads as an outward wavefront

Goal: make the existing release event propagate visually from the current vehicle while
preserving instant gameplay resolution and fixed render ownership.

Preconditions:

- Phase 1 acceptance checks and batch gate pass.

Source owners: `scripts/presentation/vehicle_combat_renderer.gd`,
`scripts/vehicle/vehicle_run.gd`, `tools/validation/validate_vehicle_combat_renderer.gd`

- [x] **2.1** Add bounded EMP radius interpolation and live charge centering.
  - Change: pass the already-borrowed player position into `_sync_effects()`; use it only
    for `live_emp_radius`; scale `authored_emp` from `0.15` to `1.00` over elapsed `0.20s`
    in standard motion and keep full radius in reduced motion.
  - Accept: isolated renderer fixtures prove start, mid/full, reduced-motion, charge
    position, release position, alpha, and one semantic draw; current batch/capacity counts
    remain unchanged.
  - Guard: no new array, dictionary, node, texture lookup owner, event, batch, or draw.
- [x] **2.2** Preserve the selected authored color hierarchy.
  - Change: emit charge with `Art.SYSTEM` and authored release with `Color.WHITE`.
  - Accept: the release texture is not command-magenta multiplied; charge and release are
    distinct from arc-purple Electric Field and mint barriers without changing affinity.
- [x] **2.3** Extend focused deterministic validation.
  - Change: add exact renderer assertions for `0.15` start radius, `1.00` after `0.20s`,
    full-radius reduced motion, live charge center, stable release center, and white release
    modulation.
  - Accept: `validate_vehicle_combat_renderer.gd` and
    `validate_vehicle_effect_store.gd` pass from the Godot 4.7.1 wrapper.
- [x] **2.4** Inspect the runtime-sized motion contract.
  - Change: capture or render standard and reduced-motion EMP evidence from the current
    candidate path without switching the production manifest.
  - Accept: the standard path visibly travels outward, the cleared interior does not read
    as a persistent field, and reduced motion presents the same final radius without travel.

Batch gate:

- `./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_combat_renderer.gd`
- `./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_effect_store.gd`
- Review the exact AS-IS/TO-BE comparison with the user. Stop before Phase 3 until the
  candidate receives exact approval.

### Phase 3: The approved raster replaces production safely

Goal: promote the exact approved bytes under the existing asset identity and retain a
complete technical ledger.

Preconditions:

- Phase 1 and 2 pass.
- The user approves the exact candidate shown in the AS-IS/TO-BE comparison.

Source owners: `replacement-workbench.json`, `to-be/assets/`,
`art/visuals/production/gameplay/effects/fx_emp_release.png`, generated workbench files

- [x] **3.1** Stage the exact approved candidate for the existing switch unit.
  - Change: append the existing approval/application ledger to an immutable unit-local
    revision-history entry before changing any active field; copy only the approved
    candidate bytes into the mirrored TO-BE path; update the existing EMP unit's active
    status, approval hash, baseline commit, and authority evidence; do not add a second
    asset identity or workbench unit.
  - Accept: deterministic workbench build/check and technical promotion preview pass with
    the exact candidate hash, and the prior `d4709789...` production approval/application
    remains recoverable from the hand-authored workbench source without consulting Git.
- [x] **3.2** Promote the exact asset and record application.
  - Change: from a clean committed worktree, run the scoped promotion script with `-Apply`,
    then record the application commit/time/evidence and return the unit to `applied`.
  - Accept: production PNG hash equals the approved candidate hash; manifest path, ID,
    dimensions, pivot, and gameplay scale contract remain unchanged.
  - Guard: do not retire or delete any additional path.
- [x] **3.3** Rebuild and validate all asset projections.
  - Change: regenerate `inventory.json` and `index.html` from the one hand-authored
    workbench source.
  - Accept: workbench check, visual replacement coverage, semantic asset provider, and
    visual authority checks all pass with no candidate path in the production manifest.

Batch gate:

- `./tools/design/build_visual_replacement_workbench.ps1 -Check`
- `./tools/validation/validate_visual_replacement_workbench.ps1`
- `./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_semantic_asset_provider.gd`
- `./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_visual_replacement_coverage.gd`

### Phase 4: Production qualification and closeout

Goal: prove the imported, built product uses the approved outward wavefront and close the
contract without overstating performance evidence.

Preconditions:

- Phase 3 acceptance checks and batch gate pass.

Source owners: Godot importer, Web exporter, capture driver, this execution contract

- [x] **4.1** Run final focused source and import checks.
  - Change: run the authority/workbench/runtime validators once, then perform a full Godot
    import after the production PNG stops changing.
  - Accept: all commands exit zero; no missing resource, import, parse, or manifest error.
- [x] **4.2** Build and inspect the production-style Web artifact.
  - Change: run `./tools/export_web.ps1`, start the built artifact through the repository's
    guarded path, and inspect standard/reduced EMP release placement, clipping, and motion.
  - Accept: the built product displays one centered outward octagonal wavefront, reduced
    motion shows final radius immediately, and the current gameplay result remains intact.
- [x] **4.3** Record evidence and performance limits.
  - Change: record hashes, commands, screenshots/captures, unchanged capacity/draw
    ownership, and any known warning in this plan.
  - Accept: structural visual budgets remain within the existing contract and the report
    makes no unmeasured native/Web release-performance claim.
- [x] **4.4** Close the ExecPlan.
  - Change: update progress, incorporate durable visual behavior into its owning spec,
    mark frontmatter `done`, and commit only task-owned files.
  - Accept: no placeholder, stale approval state, untracked candidate, or required task
    remains.

Batch gate:

- Final focused validators, Godot import, Web export, and built-product visual smoke pass
  once after the approved production bytes and runtime code stop changing.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | `./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_combat_renderer.gd` | EMP renderer/test input changes | Relevant renderer or fixture input changes |
| Asset phase | Original-detail candidate/comparison inspection; `./tools/validation/validate_cardborne_visual_authority.ps1` | Candidate, metadata, or visual spec changes | A visual-authority input changes |
| Workbench phase | `./tools/design/build_visual_replacement_workbench.ps1 -Check`; `./tools/validation/validate_visual_replacement_workbench.ps1` | Workbench source or TO-BE input changes | A workbench-owned input changes |
| Integration phase | effect-store, semantic-provider, and visual-replacement coverage validators | Production runtime/asset inputs change | An integration input changes |
| Final gate | Godot import; `./tools/export_web.ps1`; built-product standard/reduced visual smoke | All phases pass and production bytes stop changing | A final-gate input changes |

Validation rules:

- Run the narrowest check that proves the current task.
- Run each named phase gate once after its owned tasks pass.
- Run import/export and built-product inspection only after production bytes stop changing.
- Rerun a failed check only after a relevant implementation change or a new hypothesis can
  produce new evidence.
- Record known non-blocking warnings once instead of rediscovering them.
- Do not infer release performance from headless validators or the structural draw guard.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| Mechanical background removal damages the selected octagon | Reject the extraction; use one ImageGen isolation edit with the v4 sheet and canonical sheet as actual references, then rebuild comparison evidence | Do not repair geometry with SVG, ImageMagick drawing, or hand-authored vector shapes |
| The exact comparison is rejected | Keep production unchanged, record the rejection, and return only to candidate isolation within direction 2 unless the user selects a different direction | Do not promote or reinterpret direction approval as byte approval |
| The workbench projection rejects unit-local revision history | Keep the old ledger intact and add a separate durable EMP revision record linked from the unit before preparing the new active ledger | Do not delete or silently overwrite the 2026-08-04 approval/application history |
| Renderer evidence shows the wave implies delayed gameplay or obscures target readability | Stop the presentation branch and present the smallest timing/alpha correction for approval | Do not change EMP gameplay timing, radius, damage, stun, or clear order |
| A validator exposes an unrelated pre-existing failure | Record and isolate it; continue only if it does not invalidate EMP evidence | Do not absorb unrelated cleanup into this contract |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain required approval before resuming | Do not let the executor choose a new product, architecture, dependency, UX, safety, or validation contract |

Implementation-local discoveries may be handled inside the locked contract when they
cannot change scope, visible behavior, ownership, architecture, safety, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Complete - production qualification and closeout passed.
- Next task: none; this plan is done. The related non-boss combat plan remains a separate
  active contract and is not advanced by this EMP closeout.
- Last completed gate: Phase 4 built-product qualification and closeout gate.
- Evidence on 2026-08-10:
  - Candidate `558a990821e4bb27422c3a3c754550e1b903500b9eecda2babe6b18b0587f896`,
    comparison `7a28b3604fbef5750b2b7ad061ba6ab43f495a3776e2c70e1b2320713f5ff133`,
    and runtime-scale preview
    `891d5032d0d9a3c8e0fa2e4fcfb1e193921a7d8eb38d34359ed360f3593528c0`
    match candidate metadata.
  - Original-detail, `285x285`, and grayscale inspection show one centered open octagon
    with no sheet label, divider, neighboring candidate, clipping, or persistent fill.
  - `validate_vehicle_combat_renderer.gd` prints
    `VEHICLE_COMBAT_RENDERER_VALIDATION_OK`.
  - `validate_vehicle_effect_store.gd` prints `VEHICLE_EFFECT_STORE_VALIDATION_OK`.
  - `validate_cardborne_visual_authority.ps1` prints
    `CARDBORNE_VISUAL_AUTHORITY_VALIDATION_OK` with the canonical sheet hash.
  - Visual asset coverage, visual replacement coverage, and semantic asset provider
    validators print their respective `..._VALIDATION_OK` receipts.
  - The deterministic workbench check and validator both pass with `units=23`,
    `current=69`, `final=69`, and `authored=67`; the candidate remains outside the
    production projection.
  - BK approved the exact comparison with `ㅇㅇ 적용` on 2026-08-10. The approved
    candidate hash is `558a990821e4bb27422c3a3c754550e1b903500b9eecda2babe6b18b0587f896`.
  - Switch-ready baseline commit `3bfbf7da89a71876ef735c573257f2b5b5b1c894`
    preserves the exact TO-BE file and the previous `d4709789...` application ledger.
    Approval ledger commit `ad56b86d` passes the scoped technical promotion preview.
  - `promote_visual_replacement_unit.ps1 -UnitId emp_authored_replacement -Apply`
    copied exactly one file. Production asset commit
    `622f3e05aee959537496994514058ea504b21c74` has the approved hash and the same
    semantic ID, `512x512` canvas, `256,256` pivot, and import contract.
  - Godot import reimported only `fx_emp_release.png`. Renderer, effect-store, capture,
    provider, visual-asset coverage, and visual-replacement coverage validators pass.
    The applied workbench returns to `applied=15` with `current=69`, `final=69`, and
    `authored=67`.
  - Final visual-authority validation passes with canonical sheet SHA-256
    `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
    `./tools/export_web.ps1` exits zero and reports
    `WEB_EXPORT_OK path=build/web/index.html files=4`.
  - The guarded built-Web smoke used Codex lane `13029`. Standard motion displays the
    centered authored octagon at its small release-start scale; reduced motion displays the
    same octagon at the final radius immediately. Both fit inside the `1280x720` game
    viewport without clipping, and Chrome reported no console warning or error. Evidence:
    `build/visual-captures/emp-wavefront-final-web/standard-release-start.png`
    (`395ff67c...`) and `reduced-motion-final-radius.png` (`52137ad4...`). The temporary
    task-owned server was positively identified and stopped; the reduced-motion setting was
    restored to off.
  - This closeout proves import, structural budgets, focused behavior, and built-product
    visual presentation only. It does not claim native or Web release performance; the
    existing release-performance gate remains unqualified and outside this contract.
- Quality audit: scale/origin logic remains in the existing effect renderer; emission
  color remains in `VehicleRun`; no new event, provider, asset ID, batch, node, capacity,
  allocation, or gameplay owner was introduced. Adding `modulate` to the existing debug
  draw dictionary is backward-compatible and used only by the focused validator.
- Update rule: after a checkpoint passes, record concise evidence, check the task, and
  advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check passes.
- Every guard, phase gate, and final gate named by this contract passes.
- No placeholder or unresolved material decision remains.
- Durable EMP presentation behavior is recorded in `VISUAL_SYSTEM.md` and exact asset
  provenance remains in candidate/workbench metadata.
- Frontmatter status is changed to `done` only after implementation and built-product
  verification are complete.

Replan when:

- A material discovery invalidates the locked contract.

Do not replan or stop for:

- Implementation-local crop bounds, alpha thresholds, fixture arrangement, or constant
  placement that preserve the locked result.
- A passing check whose relevant inputs have not changed.
