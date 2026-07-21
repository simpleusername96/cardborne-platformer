---
type: plan
status: done
owner: BK
created: 2026-07-21
topic: Sunken Ceramic Fresco vehicle-stage UIUX and visual refinement
scope: Refine the complete current vehicle Stage 1 world presentation and every reachable UI surface without changing its combat, progression, or persistence contracts
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../../docs/product/vehicle_stage_one_experimental_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../../docs/design/vehicle-stage-one-art-directions-v2/02-sunken-ceramic-fresco.png
  - ./2026-07-20-vehicle-stage-one.md
---

# Vehicle Stage 1 Sunken Ceramic Fresco UIUX Refinement Plan

The finished Stage 1 keeps the current 5,200 x 2,200 vehicle-shooter rules and route, but replaces its debug-like rectangles and small procedural symbols with one coherent Sunken Ceramic Fresco presentation across the live map, actors, pickups, combat feedback, HUD, deployment, upgrade, pause/settings, result, and garage surfaces. Six implementation phases produce a playable, buildable, rendered vertical slice without external dependencies or changes to combat behavior.

## Purpose

- Objective: make traversable space, blockers, player, enemies, installations, pickups, objectives, cooldowns, and modal decisions immediately legible while adopting the owner-selected reference style.
- Final artifact: the existing Godot `VehicleStageOne` runtime fully restyled with large flat color masses, sparse monumental motifs, role-specific silhouettes, and ceramic medallion UI.
- Completion state: gameplay validation, viewport layout validation, Web export, and rendered evidence pass; the plan is marked `done` only after those gates pass.

## Pre-plan Evidence Already Verified

| Source or path | Verified fact | Decision affected | Freshness or recheck boundary |
| --- | --- | --- | --- |
| `docs/design/vehicle-stage-one-art-directions-v2/02-sunken-ceramic-fresco.png` | Owner selected the ivory, cobalt, deep-green, coral, mint, and mustard flat-color language and requested fewer small elements. | Locks the visual direction and scale hierarchy. | Recheck only if the owner selects a replacement reference. |
| `scripts/vehicle/vehicle_stage_rules.gd` | Collision, route, landmarks, floor regions, enemy roster, pickups, and upgrades are already data-owned and validated. | Preserve simulation truth and progression; change presentation data only. | Recheck after any geometry edit. |
| `scripts/vehicle/vehicle_stage_one.gd` | One 2,817-line runtime currently draws world, actors, pickups, projectiles, effects, and aim feedback with immediate rectangles/circles/polygons. | Introduce a visual profile and replace draw grammar without rewriting combat state. | Recheck draw-order and debug contracts after each visual batch. |
| `scripts/ui/vehicle_stage_ui.gd` | All reachable UI surfaces are runtime-built and already emit intents instead of mutating domain state. | Preserve signals and snapshots; replace composition and presentation. | Recheck focus and modal behavior after every surface change. |
| `art/ui/production/production_ui_theme.tres` | The project supplies Noto Sans KR and reusable semantic variations, but current vehicle surfaces use dark rectangular panels. | Reuse the font; add a vehicle-specific theme rather than destabilizing unrelated retained screens. | Recheck if the default project theme changes. |
| `tools/validation/validate_vehicle_stage_one.gd` | Input, reachability, projectile/cover, pickups, upgrades, progression, reset, and nominal viewport minimums are automated. | Extend this validator with visual-role and detailed layout contracts. | Run after each implementation phase. |
| `docs/design/UI_VISUAL_SYSTEM.md` | Existing durable rules already require flat color, low noise, no baked interaction state, and live Controls, but its dark-dominant palette conflicts with the selected world reference. | Add a scoped vehicle-stage exception: ivory may dominate traversable world space while dark modal/UI surfaces remain secondary. | Recheck when the vehicle experiment becomes a broader product spec. |

## Locked Decisions

| Topic | Final decision | Rationale / source |
| --- | --- | --- |
| Camera and simulation | Keep the existing flat top-down 2D camera and collision model. | Independent aim, projectile truth, and route validation already depend on it. |
| Visual thesis | Use Sunken Ceramic Fresco: ivory walkable ceramic, cobalt deep water/void, deep-green collision masses, coral threats, mustard player/objectives/rewards, mint recovery/support. | Owner-selected reference. |
| Scale | At 720p: player 72-88 px, ordinary enemies 64-80 px, installations 96-128 px, field boss 150-190 px, stage boss 200-260 px, pickups 56-72 px, major floor motifs 240-500 px. | Prevents the rejected accumulation of tiny marks. |
| Map construction | Keep collision rectangles as truth; render them as grouped ceramic masonry with a consistent shallow edge band. Replace rectangular region fill with overlapping macro color fields and sparse landmark motifs. | Gives a coherent place without a baked single-map image or collision mismatch. |
| Decoration | Use at most one major motif per camera-sized combat space and no repeated dots, micro-tiles, speckles, cracks, or ornamental carpets. | Direct owner constraint and retained low-noise policy. |
| Actors | Use project-owned runtime polygon silhouettes with separate hull and turret direction; no frame-animation asset dependency. | Vehicle rotation makes stable readable silhouettes possible without humanoid sprite burden. |
| Effects | Keep live procedural effects, but use thick wedges, broad rings, and short trails. Reduce purely decorative circles and ensure warning/active/recovery remain distinct by shape and timing. | Preserves truthful combat feedback. |
| Pickups | Give all pickups a shared 64 px ceramic plinth plus a large role glyph; use color and shape together. | Prevents small floating symbols and color-only meaning. |
| HUD | Use unframed ceramic pips, a compact objective crest, an ivory minimap plaque, contextual target health, and four large bottom medallions for primary, passive, dash, and EMP. | Keeps actionable combat truth while matching the reference. |
| Modal surfaces | Retain live game under a cobalt dim layer. Use one ivory ceramic slab, large headings, concise descriptions, and 56 px+ targets; choices use large role crests and a persistent internal focus band. | Preserves focus/accessibility without ornamental card nesting. |
| Theme ownership | Add `art/ui/production/vehicle_stage_theme.tres` and apply it only to `VehicleStageUI`. | Avoids regressions to retained non-vehicle screens. |
| Dependencies and assets | Add no external dependency and do not ship the reference image as a runtime background. Reuse the project font and project-owned geometry only. | Matches the experimental spec and avoids provenance risk. |
| Responsive contract | Support 960x540, 1280x720, and 1920x1080 with stable anchors, compact 960 mode, no clipping, and 44 px minimum command targets. | Existing acceptance contract plus UIUX gate. |

## Rejected Alternatives

| Alternative | Why it was viable | Why it was rejected |
| --- | --- | --- |
| Bake the selected screenshot into one giant map texture | Fastest route to visual resemblance. | The world is larger than one viewport, gameplay geometry would not match the painting, and stateful objects could not remain truthful. |
| Palette-swap current rectangles and circles | Low implementation cost. | It would preserve the exact debug grammar the owner rejected. |
| Generate a large raster sprite sheet before runtime refinement | Could provide richer illustration. | Generated frame consistency, slicing, scale, and state coverage are unverified; the selected flat style can be established deterministically first. |
| Change back to isometric or 3D presentation | Could echo the shallow depth in the reference. | It reintroduces occlusion and aim/collision ambiguity that the accepted vehicle experiment removed. |
| Modify the shared production theme globally | One theme would be simpler operationally. | It would couple the experimental vehicle direction to retained legacy screens and assets. |

## Current State

Already true or landed:

- One continuous vehicle stage, manual aim, rapid primary, passive seeker, dash, EMP, pickups, upgrades, optional elite, boss, persistence, pause/settings, result, garage, minimap fog, and focusable choices exist.
- Gameplay progression does not require exterminating ordinary enemies.
- Projectiles and movement share the validated cover geometry.
- The selected reference image is committed under `docs/design/vehicle-stage-one-art-directions-v2/`.

Remaining implementation:

- Replace debug-like world, actors, installations, pickups, effects, HUD, and modal composition.
- Add a vehicle-specific semantic visual profile and Theme.
- Extend validation from simple modal minimum sizes to explicit visual and layout contracts.
- Produce rendered evidence and a production Web build.

## Scope

In scope:

- The complete current `VehicleStageOne` world presentation.
- Player, all enemy roles, installations, bosses, crates, cache, gate, pickups, projectiles, telegraphs, effects, aim cursor, minimap, HUD, deployment, upgrade, pause/settings, result, and garage.
- Scoped design-system documentation and exact validators.

Out of scope:

- Combat tuning, enemy behavior changes, route progression changes, new upgrades, save-schema changes, localization, touch UI, new screens, external art packs, and redesigning the retired humanoid runtime.

Destructive or irreversible actions:

- None. The implementation adds a scoped visual profile/theme and modifies current vehicle presentation owners.

Exact actions requiring owner/user approval:

- None for this implementation. No dependency, deletion, remote push, or destructive Git action is included.

## Architecture and Ownership

| Concern | Final owner | Interface or invariant | Existing owner to reuse or retire |
| --- | --- | --- | --- |
| Combat and progression | `scripts/vehicle/vehicle_stage_one.gd` | Existing dictionaries, update order, signals, and debug contracts remain stable. | Reuse without behavioral redesign. |
| Collision and authored route | `scripts/vehicle/vehicle_stage_rules.gd` | Cover and landmark coordinates remain simulation truth. | Reuse; add only presentation-friendly region metadata where needed. |
| Semantic palette, scale, motifs | `scripts/vehicle/vehicle_stage_visual_profile.gd` | Exposes named colors, visual size constants, motif and region helpers; owns no gameplay state. | New owner replacing scattered presentation literals. |
| World/actor drawing | `scripts/vehicle/vehicle_stage_one.gd` draw section | Consumes visual profile and current runtime state; never invents collision. | Replace current primitive grammar in place. |
| Vehicle-stage component styling | `art/ui/production/vehicle_stage_theme.tres` | Semantic Godot Theme variations, Noto Sans KR, stable focus/disabled/pressed states. | New scoped theme; shared font reused. |
| UI composition and state presentation | `scripts/ui/vehicle_stage_ui.gd` | Consumes snapshots, emits existing intents, owns focus and responsive composition. | Replace current dark-panel layout while preserving signals. |
| Visual/UI validation | `tools/validation/validate_vehicle_stage_one.gd` | Checks palette roles, scale constants, modal fit, targets, snapshots, and existing gameplay contracts. | Extend existing validator. |
| Durable art exception | `docs/design/UI_VISUAL_SYSTEM.md` | Records vehicle-stage world palette and scale exception without weakening global low-noise/accessibility rules. | Amend active spec. |

## As-Is / To-Be Delta Map

| Concern | As-is | To-be | Acceptance check | Guard / leftover check |
| --- | --- | --- | --- | --- |
| Ground | Five large rectangles with nearly identical dark values. | Ivory connected ceramic fields with large zone landmarks and cobalt void. | Route and zone changes read in capture without labels. | No repeated micro-pattern loop remains. |
| Cover | Dark rectangles with inset rectangles. | Deep-green masonry masses with shallow cobalt edge bands and large cap marks. | Every visible blocker matches existing cover collision. | No decorative blocker without collision. |
| Player | 64 px cyan polygon and line turret. | 80 px mustard/ivory manta-skiff with separate high-contrast turret direction. | Hull and aim direction are distinguishable at 960x540. | Collision radius stays unchanged. |
| Enemies | Small muted geometric primitives that differ weakly. | 64-260 px coral/magenta role silhouettes with distinct profiles. | Role identity survives grayscale through silhouette. | No ordinary enemy uses boss violet or reward mustard as its dominant fill. |
| Pickups | 24 px halo and small glyph. | 64 px ivory plinth with large mint/coral/mustard/cobalt glyph. | Type reads by shape and color. | Pickup bounds and collection behavior remain unchanged. |
| Feedback | Numerous thin arcs and small circles. | Broad wedges, thick rings, short trails, and state-specific fills. | Startup, active, and recovery remain visually distinct. | Effects never imply a larger damage area than gameplay. |
| HUD | Five dark rectangular panels plus explanatory filler. | Sparse pips, crest, map plaque, target strip, and four medallions. | Action readiness, cooldown, health, objective, target, buffs, and map remain visible. | No debug/filler sentence remains. |
| Modals | Large dark text panels with sentence-heavy buttons. | One ivory slab, concise hierarchy, large choice crests, and focused commands. | All flows are keyboard-operable and fit 960x540. | Existing signals and return paths remain intact. |

## Tasks

### Phase 1: Visual profile and durable contract

Goal: establish one source of truth for the selected style before changing render code.

Source owners touched: `scripts/vehicle/vehicle_stage_visual_profile.gd`, `docs/design/UI_VISUAL_SYSTEM.md`, this plan.

- [x] **1.1** Add `VehicleStageVisualProfile`.
  - As-is: palette and sizes are scattered between rules, stage, and UI.
  - To-be: named semantic colors, large-element scale constants, and sparse motif helpers are centralized.
  - Accept: validator can read every required visual role and size without instantiating UI.
  - Guard: profile contains no combat, progression, persistence, or input state.
- [x] **1.2** Record the scoped vehicle-stage exception in the durable visual system.
  - As-is: dark-dominant world guidance conflicts with the selected ivory reference.
  - To-be: ivory may dominate traversable vehicle-stage ground while low-noise, live-state, and asset-boundary rules remain authoritative.
  - Accept: the active spec names the selected reference and semantic world roles.
  - Guard: unrelated shell backgrounds and retained screens are not redefined.

Batch acceptance: profile loads headlessly and the document has valid lifecycle metadata.

Batch guard: `git diff --check` passes and no unrelated `.import` churn is staged.

### Phase 2: Complete playable-world visual slice

Goal: make map truth, player intent, enemy roles, pickups, and hazards readable during live combat.

Source owners touched: `scripts/vehicle/vehicle_stage_one.gd`, `scripts/vehicle/vehicle_stage_rules.gd`, `scripts/vehicle/vehicle_stage_visual_profile.gd`.

- [x] **2.1** Replace map fill and cover drawing.
  - As-is: rectangular dark regions and inset cover blocks.
  - To-be: ivory zone fields, cobalt water/void, deep-green ceramic masonry, shallow edge bands, and one macro motif per combat space.
  - Accept: floor, blocked cover, and exits remain distinct at all supported viewports.
  - Guard: collision and projectile-cover tests remain unchanged and pass.
- [x] **2.2** Replace player and enemy silhouettes.
  - As-is: small generic polygons, circles, and rectangles.
  - To-be: large role-specific silhouettes with separate player hull/aim direction and boss-scale hierarchy.
  - Accept: each role has a unique silhouette and follows the locked size band.
  - Guard: hit radius, movement, targeting, health, and AI state remain unchanged.
- [x] **2.3** Replace pickups, crates, cache, gate, projectiles, telegraphs, and effects.
  - As-is: small floating symbols and thin generic arcs.
  - To-be: ceramic plinths, large stateful props, thick truthful warnings, and restrained short trails.
  - Accept: pickup and threat meaning does not depend on color alone.
  - Guard: visual bounds do not exceed gameplay damage/collision truth.

Batch acceptance: existing vehicle validator passes and captured combat states show the new world grammar.

Batch guard: no large baked map texture or reference-board crop becomes a runtime dependency.

### Phase 3: HUD and minimap

Goal: expose only actionable combat truth in the selected visual language.

Source owners touched: `scripts/ui/vehicle_stage_ui.gd`, `art/ui/production/vehicle_stage_theme.tres`.

- [x] **3.1** Add the vehicle-stage Theme.
  - As-is: shared dark theme supplies rectangular panels and outline-like focus borders.
  - To-be: ivory ceramic slabs, deep-green secondary surfaces, mustard internal focus bands, coral health/threat, and large command targets.
  - Accept: normal, hover, focus, pressed, selected, and disabled states keep stable bounds and readable contrast.
  - Guard: shared production theme remains untouched.
- [x] **3.2** Rebuild health, objective, target, buff, and boss clusters.
  - As-is: boxed HUD clusters and filler copy.
  - To-be: large unframed health pips, compact crest, contextual target strip, icon-plus-duration buffs, and boss emphasis.
  - Accept: no cluster obscures the primary play lane; exact values remain available where needed.
  - Guard: all snapshot fields remain consumed or intentionally retired with validator coverage.
- [x] **3.3** Rebuild minimap and action dock.
  - As-is: small grid map and four text-heavy rectangles.
  - To-be: ivory route plaque with fog and markers plus four 76 px ceramic medallions with readiness/cooldown masks and concise bindings.
  - Accept: current location, visited space, discovered objectives, boss markers, and four action states remain legible at 960x540.
  - Guard: unexplored markers remain hidden and exact cooldown text remains visible.

Batch acceptance: HUD fits and remains legible at 960x540, 1280x720, and 1920x1080.

Batch guard: no control is smaller than 44 px and no state relies on color alone.

### Phase 4: Deployment, upgrade, pause, result, and garage

Goal: make every reachable non-combat decision concise, coherent, and keyboard-complete.

Source owners touched: `scripts/ui/vehicle_stage_ui.gd`, `art/ui/production/vehicle_stage_theme.tres`.

- [x] **4.1** Recompose deployment and upgrade choice.
  - As-is: sentence-heavy large dark buttons.
  - To-be: one ceramic slab, large role crests, compact mechanical comparison, numbered shortcuts, and obvious focused/selected state.
  - Accept: the actual weapon/card decision appears in the first viewport with no clipping.
  - Guard: selection emits exactly one existing intent and disables duplicate input.
- [x] **4.2** Recompose pause/settings.
  - As-is: generic dark modal with commands and sliders.
  - To-be: compact ivory settings slab over the live cobalt-dim game, with stable focus order and large sliders/commands.
  - Accept: resume, restart, volume controls, and abort remain functional from keyboard and mouse.
  - Guard: settings persistence continues through `SettingsStore`.
- [x] **4.3** Recompose result and garage.
  - As-is: multiline summary text and one nested loadout panel.
  - To-be: large result crest, grouped run facts, persistent reward emphasis, and a compact loadout/service slab with primary toggle and launch action.
  - Accept: result-to-garage-to-replay flow remains clear and focusable.
  - Guard: no unsupported inventory, repair cost, or new persistence state is introduced.

Batch acceptance: every modal fits 960x540, has initial focus, and completes its existing flow.

Batch guard: no nested bordered panel stack or baked interaction text appears.

### Phase 5: Validation and rendered evidence

Goal: prove that the redesign preserves gameplay while meeting visual and UI contracts.

Source owners touched: `tools/validation/validate_vehicle_stage_one.gd`, `scripts/vehicle/vehicle_stage_one.gd`, `scripts/ui/vehicle_stage_ui.gd`.

- [x] **5.1** Extend deterministic validation.
  - As-is: validator checks gameplay and only nominal modal minimum sizes.
  - To-be: add visual-role presence, scale bands, UI target sizes, compact viewport contracts, focus, and snapshot-consumption checks.
  - Accept: failures name the exact broken visual/UI contract.
  - Guard: existing gameplay checks remain and still pass.
- [x] **5.2** Repair and run capture evidence.
  - As-is: capture sequence exists; the local wrapper attempt did not complete within 120 seconds.
  - To-be: use the direct known Godot executable with bounded capture logging and exact cleanup; capture deployment, combat, installations, upgrade, field boss, stage boss, result, and garage.
  - Accept: eight nonblank PNGs show the intended states at 1280x720.
  - Guard: only positively task-owned Godot processes are stopped if capture fails.
- [x] **5.3** Run production-style build and boot.
  - As-is: Web export preset and CI workflow exist.
  - To-be: headless import/validator, Web release export, and built-app boot evidence pass locally where the environment supports them.
  - Accept: export exits zero and the built app reaches a valid first screen.
  - Guard: no ad hoc dependency or port is introduced; if a server is required, use the fastrun codex lane through `npjt-port-guard`.

Batch acceptance: deterministic checks, Web export, and rendered evidence pass or an exact environment limitation is recorded with the strongest safe substitute.

Batch guard: rerun a failed slow gate only after changing its suspected cause.

### Phase 6: Quality pass and lifecycle completion

Goal: leave a maintainable implementation and truthful project memory.

Source owners touched: all task-owned files and this plan.

- [x] **6.1** Run task-scoped code quality review.
  - As-is: the current runtime is large and presentation literals are scattered.
  - To-be: presentation constants are centralized, comments describe only non-obvious visual invariants, and no task-scoped duplication remains.
  - Accept: quality review finds no blocker or task-owned safe blocker is corrected.
  - Guard: no unrelated architecture rewrite or user-authored change is included.
- [x] **6.2** Complete the plan and commit scoped work.
  - As-is: this plan is active with unchecked tasks.
  - To-be: progress and evidence are recorded, status is `done`, and only task-owned files are committed.
  - Accept: staged-file audit contains no unrelated `.import` files and `git diff --check` passes.
  - Guard: no remote push occurs without a separate user request.

Batch acceptance: the commit is coherent, plan status is truthful, and the working tree's pre-existing unrelated changes remain untouched.

Batch guard: completed plan is not treated as ongoing authority beyond its recorded decisions.

## Validation Cadence

Inner-loop commands:

- `.\tools\godot.ps1 --path . --headless --script res://tools/validation/validate_vehicle_stage_one.gd`
- `.\tools\godot.ps1 --path . --headless --quit-after 2`
- `git diff --check`

Batch gates:

- Phase 1: headless script parse plus visual-profile contract checks.
- Phase 2: full existing vehicle validator plus one rendered combat state.
- Phase 3: validator at 960x540, 1280x720, and 1920x1080 plus HUD capture.
- Phase 4: focus and fit checks for every modal plus capture set.
- Phase 5: full validator, eight native captures, Web release export, built boot evidence where feasible.

Final gates:

- Full lint/type checks: Godot headless import and script parse with no errors.
- Full tests: `validate_vehicle_stage_one.gd` returns `VEHICLE_STAGE_VALIDATION_OK`.
- Production build and start: `.\tools\godot.ps1 --path . --headless --export-release Web build/web/index.html`, followed by a built-app boot through the canonical fastrun lane if browser verification is required.
- Manual UI/browser routes and viewport sizes: deployment, HUD, upgrade, pause, result, and garage at 960x540, 1280x720, and 1920x1080; rendered captures at 1280x720.
- Persistence/data validation: existing primary selection, clear count, relay module, and field module contracts remain unchanged.
- Documentation and lifecycle validation: `git diff --check`, frontmatter/type/status review, and staged-file audit.

Rerun policy:

- Rerun a failed narrow check only after a concrete change or new hypothesis.
- Rerun full gates only after the suspected cause changed.
- Record known non-blocking warnings instead of rediscovering them.

## Predetermined Error Handling and Contingencies

| Trigger | Required response | Limit / escalation point |
| --- | --- | --- |
| Visual element implies collision where none exists | Remove or recolor it as nonblocking decoration; never silently add gameplay collision during this task. | Escalate only if the selected style cannot preserve route readability without geometry changes. |
| New silhouette exceeds existing hit radius | Keep the larger visual body but add an inset high-contrast core showing the hittable mass; do not change combat radius. | Escalate only if playtest evidence shows systematic unfairness. |
| 960x540 modal clips | Activate compact spacing/type and reduce secondary copy; do not add scrolling to the primary decision. | Escalate only if a required control still cannot fit at 44 px minimum height. |
| Reference palette weakens threat contrast | Reserve coral/magenta exclusively for threats and reduce decorative saturation; preserve shape cues. | Escalate only if contrast remains insufficient after semantic reservation. |
| Native capture hangs | Stop only the exact task-owned Godot PIDs, save logs, then use a direct executable/headless fallback and Web build screenshot. | Stop retrying after two distinct evidence-backed methods fail. |
| Existing gameplay validator fails | Fix only the presentation-caused regression; do not weaken the test or alter gameplay to make it pass. | Escalate if the failure predates task-owned changes. |
| Godot creates `.import` churn | Leave it unstaged unless a newly added task asset requires its own import metadata. | Never stage unrelated pre-existing churn. |

## Progress

- [x] Phase 1: visual profile and durable contract. Headless project parse passed on 2026-07-21.
- [x] Phase 2: complete playable-world visual slice. Collision truth stayed unchanged while the full draw grammar was replaced.
- [x] Phase 3: HUD and minimap. Responsive contracts and all combat-state displays passed at three target widths.
- [x] Phase 4: deployment, upgrade, pause, result, and garage. Every reachable modal retained its intent and focus path.
- [x] Phase 5: validation and rendered evidence. All 87 checks passed; eight-state native capture sets passed at 960x540, 1280x720, and 1920x1080; Web export and HTTP boot returned success.
- [x] Phase 6: quality pass and lifecycle completion. Palette duplication was removed and the final scoped audit found no remaining blocker.
- [x] Final gates. `git diff --check`, native render inspection, Web release export, and canonical-port built-app boot passed on 2026-07-21.

## Completion Evidence

- Deterministic contract: `validate_vehicle_stage_one.gd` completed 87 checks with zero failures. Godot still reports the validator's known non-blocking ObjectDB cleanup warning at process exit.
- Native render evidence: eight stage states were captured at 960x540, 1280x720, and 1920x1080 under `.godot/ceramic-fresco-captures-*`; deployment, combat, upgrade, boss, result, and garage were inspected for clipping and hierarchy.
- Production build: Web release export completed successfully to `build/web/index.html`.
- Production-style boot: the exported build was served on the fastrun-manager `codex` lane port `13029`, returned HTTP 200 with the Godot loader, and the task-owned preview process was stopped after verification.
- Quality gate: the task-scoped pass confirmed presentation/state separation, preserved signals and gameplay contracts, removed duplicated HUD palette literals, and found no remaining task-owned blocker.

## Completion Criteria

- [x] Every user-visible requirement passes its acceptance check.
- [x] Every regression guard and final validation gate passes.
- [x] No retired owner, duplicate path, placeholder, or unresolved material decision remains.
- [x] Durable decisions and run/verify commands are recorded in their canonical project documents.
- [x] The stage reads as one coherent Sunken Ceramic Fresco world rather than recolored debug primitives.
- [x] Traversable ground, solid cover, player, enemies, installations, pickups, objectives, and hazards remain distinguishable without explanatory text.
- [x] All current UI flows remain functional and keyboard-complete.

## Rollback / Safety

- Revert the scoped commit to restore the prior vehicle presentation; combat and persistence schemas are not migrated.
- Do not revert, stage, or clean pre-existing `.import` changes.
- Do not push remotely without a separate user request.

## Risks

- Runtime polygon art can establish a coherent shippable style but may still benefit from later bespoke raster embellishment; this plan deliberately makes that optional rather than blocking.
- Larger visual silhouettes can feel unfair if their decorative wings imply hit area; inset cores and unchanged collision radii mitigate this.
- Ivory ground is a deliberate scoped exception to the old dark-dominant world palette and must not erase coral threat contrast.
- The local display driver may prevent native capture; deterministic validation and built Web evidence remain required substitutes.

## Open Questions

No material implementation questions remain. Changes to gameplay geometry, new screens, external asset adoption, or a replacement art reference require a new owner decision and are outside this plan.

## Decision Notes

- 2026-07-21: owner selected `02-sunken-ceramic-fresco.png` as the basis and explicitly requested minimizing small elements.
- 2026-07-21: locked a presentation-only refinement that preserves the accepted vehicle shooter mechanics, map route, collision, and persistence.
- 2026-07-21: selected a scoped vehicle Theme and visual profile instead of modifying the shared production theme or baking the reference image into the map.
- 2026-07-21: completed the implementation after 87 deterministic checks, three native viewport capture sets, Web release export, canonical-port HTTP boot, and a task-scoped quality audit.

## Stop Conditions

Complete when:

- All six phases and final gates are checked, evidence is recorded, the plan status is `done`, and task-owned changes are committed.

Escalate only when:

- A required visual outcome would require gameplay geometry, save-schema, dependency, external asset, destructive Git, or remote-push authority outside this plan.

Do not stop when:

- A visual iteration, capture-driver workaround, scoped refactor, or validation correction remains within the locked implementation contract.

## Handoff

```text
Goal: Apply the selected Sunken Ceramic Fresco direction to the complete current Vehicle Stage 1 world and UI without changing gameplay.

Read first: .agent/execplans/2026-07-21-ceramic-fresco-uiux-refinement.md, docs/design/UI_VISUAL_SYSTEM.md, docs/product/vehicle_stage_one_experimental_spec.md.

Execute exactly: phases 1 through 6 in order, preserving collision, progression, input, and persistence contracts.

Validate with: the existing vehicle validator, added visual/layout contracts, eight rendered state captures, Web release export, and staged-file audit.

Stop when: all completion criteria pass, the plan is done, and only task-owned files are committed.
```
