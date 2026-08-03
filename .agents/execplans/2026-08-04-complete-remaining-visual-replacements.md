---
type: plan
status: active
owner: BK
created: 2026-08-04
last_reviewed: 2026-08-04
scope: Remaining Phase 6-11 production visual replacements, runtime promotion, reconciliation, release validation, and plan retirement
supersedes: ./2026-08-02-visual-replacement-workbench-and-runtime-switch.md
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/design/visual-replacement-workbench/README.md
  - ../../art/visuals/production/README.md
  - ../semantic-v2-runtime-acceptance-evidence.md
  - ./2026-08-02-pre-asset-code-stabilization.md
---

# Complete the Remaining Visual Replacements - Execution Contract

This is the sole executable contract for the remaining visual replacement
program. It starts from the completed Phase 5 and upgrade-card follow-up at
discovery baseline `2344ebdb47db72f0b3bbf2de01083376b3166e65`, corrects the
stale Phase 6 contract, executes all still-unapplied visual units through Phase
9, reconciles the final production/workbench state in Phase 10, and completes
the native/Web release gate and plan retirement in Phase 11.

## Why / Context

Phases 0 through 5 of the superseded plan established the canonical production
root, current-only replacement workbench, normalized gameplay asset contract,
one-body player craft, and code-native zero-raster UI. The later upgrade-card
follow-up also established `Secondary Weapons` as the umbrella category,
`Seeker` as its always-equipped base family, and `hud/action_seeker` as the
Seeker card artwork.

The old Phase 6 through Phase 11 text cannot be copied literally because current
truth has moved:

- `hud/upgrade_passive` has no runtime consumer and must not be promoted;
- the workbench Korean-localized titles for `seeker`, `ion_field`, and
  `wake_mines` drift from the current product/runtime localization;
- `procedural_floor_and_walls` and `effect_atlas_retirement` are already retired
  and must not be reopened;
- `boss_hit_feedback` is a distinct unapplied boss unit and must be included;
- the current workbench validator hard-codes the starting status and PNG counts,
  so it cannot validate legal remaining-unit transitions;
- the final corrected production count is `210` gameplay PNGs, not the old
  `211`, because the legacy passive glyph is retired;
- the release suite contains `58` `validate_*.gd` validators plus one separate
  diagnostic profiler, not the historical `56 + 2` description; and
- the four applied retirement records are current negative-inventory guards
  required by validation and remain in the active ledger.

## Purpose

- **Objective:** replace all 30 current `target_required` visual units without
  changing gameplay, collision, topology, input, localization completeness, or
  the fixed general-SF art direction.
- **Deliverable:** exact deployable PNG families in production, matching
  manifest/provider/catalog ownership, a clean generated workbench, complete
  native and built-Web evidence, and durable final acceptance evidence.
- **Completion state:** `remaining_visual_replacement_program_complete` means
  all 30 units are baseline-promoted, the workbench has 32 `keep_current` and
  four `retired` units, production has exactly 210 gameplay PNGs and zero UI
  chrome PNGs, every named release gate passes, durable decisions are in their
  owning specs, and both this plan and its superseded predecessor are retired
  according to `.agents/PLANS.md`.

## Scope and Non-scope

In scope:

- Phase 6 player action, Secondary Weapons, minimap, and HUD/upgrade glyph
  packages;
- Phase 7 wear, functional world, facility, pickup, and reward-feedback
  packages;
- Phase 8 ordinary enemy, hostile projectile, defense/status, cue, arrival,
  destruction, and damage-feedback packages;
- Phase 9 boss bodies, shared boss node states, boss feedback, exact runtime
  mapping, and approved legacy module retirement;
- exact workbench metadata, generated inventory/index, manifest/provider/
  renderer changes required by structural units, focused validators, rendered
  evidence, final counts, release validation, durable handoff, and plan cleanup.

Out of scope:

- another UI layout or navigation redesign; Phase 6 changes gameplay imagery and
  existing HUD/upgrade artwork only;
- weapon balance, upgrade behavior, card behavior, manual aim, held-fire cadence,
  dash/EMP behavior, Secondary Weapons simulation ownership, collision, damage,
  target selection, enemy roster/AI, boss patterns, encounters, map topology,
  pickup values, persistence, difficulty, or localization copy changes;
- a new material, cultural, marine, ritual, or named environmental theme;
- dependencies, native extensions, engine changes, reduced workload, relaxed
  performance thresholds, or broad performance/gameplay refactors;
- redoing completed Phases 0 through 5 or restoring retired raster UI, floor/
  wall, atlas, or boss-module assets.

Constraints and invariants:

- `docs/product/vehicle_game_spec.md` owns product/gameplay truth.
- `docs/design/VISUAL_SYSTEM.md` owns art direction and presentation grammar.
- `docs/design/visual-replacement-workbench/replacement-workbench.json` is the
  sole hand-authored unit/status/mapping source. Generated files never override
  it, and it never overrides the product or visual specs.
- Production assets live only under `art/visuals/production`; TO-BE bytes live
  only under the mirrored `docs/design/visual-replacement-workbench/to-be/assets`
  path; sheets and comparisons live only under `previews`.
- Every animated deliverable keeps its declared frame count, size, pivot, fps,
  non-looping behavior, blend, event mapping, and total duration. Static units
  are not subjected to invented frame/fps checks.
- Visual geometry never becomes collision, damage, navigation, timing, target,
  or state-transition truth.
- Korean is the default locale and Korean/English remain complete.

Destructive or irreversible actions:

- retire `art/visuals/production/gameplay/hud/upgrade_passive.png` and its
  tracked `.png.import` sidecar only with an exact approval bound to the corrected
  `upgrade_family_glyphs` unit;
- retire the exact ten legacy boss-module PNGs and ten paired `.png.import`
  sidecars only with the approved `shared_boss_node` switch;
- remove generated per-unit TO-BE duplicates and completed contact sheets only
  after the corresponding applied unit becomes the verified AS-IS baseline;
- delete the three unreferenced legacy AS-IS UI preview paths in Phase 10 only
  after an exact displayed-path approval; and
- delete the two ExecPlans only after all final gates pass, durable decisions
  land, and document-deletion authority is confirmed.

Exact actions requiring BK approval:

- every unit promotion requires the exact builder-observed SHA-256 map, exact
  target map, exact `retire_paths`, and clean baseline commit;
- one approval message may cover several fully displayed independent units, but
  hashes, targets, retire paths, states, production commits, and rollback remain
  unit-specific;
- no preview, passing check, old approval, or plan wording grants byte promotion,
  runtime remapping, or deletion authority.

## Assumptions

None. External approvals and the release-performance result are explicit gates
with predetermined stop behavior, not deferred design decisions.

## Proposed Design

### Final ownership model

- Gameplay PNG identity and metadata remain in
  `art/visuals/production/gameplay/asset-manifest.json` and
  `scripts/presentation/components/vehicle_semantic_asset_provider.gd`.
- Existing presentation catalogs and renderers continue to consume the same
  semantic IDs unless a structural unit names exact `runtime_change_paths`.
- The code-native Theme and shared component factory continue to own all UI
  chrome; no Phase 6-11 task recreates raster UI chrome.
- `Secondary Weapons` remains the umbrella. `Seeker` is a distinct always-
  equipped subtype simulated by `VehicleRun`; the four optional families remain
  simulated by `VehicleSecondaryRuntime`. This internal owner split is not a
  second player-facing category.
- Seeker action and upgrade-card artwork share `hud/action_seeker`. The seven
  generic live upgrade glyphs remain in `upgrade_family_glyphs`; the unused
  `hud/upgrade_passive` file is retired rather than renamed or rebound.
- Procedural floor/wall rendering and frame-based effect animation remain the
  current runtime truth. Their four historical retirement-ledger units remain
  as absence guards and are never reopened as target work.

### Parallel work model

- Independent exact deliverable families and their contact sheets may be
  prepared in parallel by bounded subagents.
- One root executor remains the single writer for
  `replacement-workbench.json`, generated inventory/index, production manifests,
  providers, catalogs, shared renderers, validators, approvals, applications,
  deletions, and commits.
- Parallel workers may not promote production bytes, edit shared owners, delete
  files, or infer approval. Promotion and commits are sequential per unit.

### Workbench and state-machine repair

Before producing Phase 6 art, update the workbench control plane once:

1. Make `validate_visual_replacement_workbench.ps1` transition-aware: preserve
   the 36-unit and four-retirement-ledger invariants, derive ordinary status and
   production counts from the current source/filesystem, and stop hard-coding
   the discovery-baseline `keep_current=2`, `target_required=30`, and
   `gameplay_png=215` values.
2. Make `validate_vehicle_semantic_asset_provider.gd` and
   `validate_vehicle_visual_asset_coverage.gd` transition-aware before the first
   unit switch. The provider validator must compare the provider's complete ID
   set with IDs independently expanded from the current manifest, retain only
   cross-phase stable required-ID probes, and reject missing/orphan/duplicate
   mappings. The coverage validator must derive per-category expectations from
   the manifest expansion and still prove every named live consumer uses the
   provider. Neither validator may retain a fixed total of 215 or a fixed
   `boss_module=10` category count.
3. Add a `-Final` mode to the workbench validator that requires exactly 32
   `keep_current`, four `retired`,
   zero transitional states, 210 gameplay PNGs, zero UI PNGs, one font, and no
   incomplete workflow ledger data.
   The ordered production-count transitions are 215 at discovery, 214 after
   Task 6.11 retires the passive glyph, 217 after Task 7.1 adds three wear
   tiles, and 210 after Task 9.2 replaces ten boss-module PNGs with three shared
   node PNGs. Same-path replacements and frame-family replacements do not
   change these totals.
4. Keep the four existing retired units and their exact approval/application
   ledgers as validated absence guards; remove the obsolete retired-to-removed
   expectation from the remaining-work contract.
5. Normalize the three Phase 6 Korean-localized titles against the current
   product/runtime localization and correct
   `upgrade_family_glyphs` to seven deliverables plus the exact two-path legacy
   passive retirement. Declare
   `art/visuals/production/gameplay/asset-manifest.json` as that unit's only
   `runtime_change_path`, because the switch removes `upgrade_passive.png` from
   the manifest-backed `hud` set. Keep the unit ID stable and keep
   `hud/action_seeker` in the `seeker` unit.
6. Replace `shared_boss_node.runtime_change_paths` with the exhaustive 12-path
   structural list locked in Task 9.2; the current five-path declaration omits
   required provider, fallback-presentation, and validation owners.
7. Update `docs/design/visual-replacement-workbench/README.md` with the
   transition-aware and persistent-retirement-ledger rule, then rebuild and
   validate `inventory.json` and `index.html`.

### Unit switch protocol

Every replace, add, or consolidate unit follows this exact sequence:

1. Confirm a clean task baseline and record full `HEAD`. Confirm the unit is
   `target_required`, with null approval/application and no overlapping dirty
   path.
2. Create every declared target as a separate exact PNG under its mirrored
   `to-be/assets` path. Create one review contact sheet only from those exact
   deliverables under that unit's `previews/to-be/<unit-id>` path.
3. Run the workbench checks, unit metadata checks, visual review at actual scale,
   and the unit's focused validator set. Set `switch_ready` only when every file
   and state passes. Commit the complete preparation and require a clean HEAD.
4. Display the exact unit ID, baseline commit, target mapping, observed SHA-256
   map, `retire_paths`, `runtime_change_paths`, and passing evidence. Wait for
   exact BK approval. Changed bytes or mappings invalidate approval and return
   the unit to `switch_ready`.
5. Record `approved_for_switch`, preview the copy operation with
   `promote_visual_replacement_unit.ps1 -UnitId <id>`, rebuild, validate, and
   commit the approval record.
6. Run the helper with `-Apply`, apply only declared structural changes, delete
   only approved retirement paths after zero-reference proof, run focused
   checks, and create one coherent production switch commit. The copy helper
   never grants approval and never performs deletion.
7. Immediately create the ledger commit with the production switch commit and
   validation evidence. Do not hand off between the production switch and ledger
   commits.
8. After the phase rendered gate passes, baseline-promote each applied unit:
   production targets become `current_paths`; consumer mappings refresh;
   deliverables, runtime/retire/preview paths, approval, and application clear;
   duplicate TO-BE bytes and completed unit contact sheets are removed; status
   becomes `keep_current`.

If several ready units are approved in one exact report, steps 5-7 still run
and commit per unit. A failed independent unit does not invalidate another
unit's exact approval.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Active remaining scope | Workbench has 36 units: 30 `target_required`, two `keep_current`, four `retired`; no Phase 6-9 approval/application exists | `replacement-workbench.json`, generated `inventory.json` | Execute only the 30 target units; never reopen completed units | 6.1-9.3 |
| UI boundary | Production UI has zero PNG chrome and uses one Theme/component system | `docs/design/VISUAL_SYSTEM.md`, Phase 5 acceptance | Phase 6 changes imagery only; no screen-layout redesign | 6.10-6.12 |
| Secondary language | `Secondary Weapons` is the umbrella; Seeker is always equipped and maps to `hud/action_seeker` | product spec, upgrade renderer, localization | Normalize review labels; reuse action glyph; retire legacy passive glyph with approval | 6.0, 6.6, 6.11 |
| Procedural world | Procedural floor/wall raster retirement is already applied | retired workbench record, renderer/provider | Preserve procedural truth and fingerprints; do not recreate those PNGs | 7.0 |
| Effect atlases | Atlas retirement is already applied; 22 frame animation identities own 101 frames | manifest, retired workbench record | Keep frame assets; do not recreate atlases | 8.0, 10.2 |
| Boss consolidation | Ten module PNGs remain current; shared node target is three states plus four disabled-effect frames | `shared_boss_node` unit and boss runtime owners | Atomic state mapping + exact 20-path retirement; `boss_hit_feedback` remains a separate unit | 9.2-9.3 |
| Workbench progression | Current validator hard-codes discovery counts and retired ledger removal conflicts with current validation | workbench validator and model | Make validator transition-aware and retain four retirement ledgers | 6.0, 10.3 |
| Final inventory | Current 215 PNG + wear 3 - passive 1 - ten boss modules + three shared nodes = 210 | filesystem, workbench target sets | Final: 210 gameplay PNG, zero UI PNG, 22 animations/101 frames, one font, 32 keep/four retired | 10.2 |
| Validation inventory | Current release validators are 58 `validate_*.gd`; profiler is diagnostic | `tools/validation` | Enumerate dynamically, require baseline count unless contract changes, run profiler separately | 11.1 |
| Release performance | Prior capacity/peak evidence failed absolute gates; waiver allowed visual work but did not waive release | pre-asset plan and acceptance evidence | Run the complete absolute gate at the end; preserve failure evidence and do not relax workload/thresholds | 11.5 |
| Destructive authority | Promotion/deletion is exact-hash and exact-path approved | workbench spec and promotion helper | No inferred or wildcard authority; stop only the affected unit when approval is absent | all unit tasks |

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership, safety,
  and validation decision is closed.
- Godot 4.7.1, the repository wrappers, builder, validator, promotion helper,
  capture driver, Web exporter, performance scenarios, and port-guard workflow
  are present. Newly named `-Final` behavior is created and proven by Task 6.0
  before later tasks depend on it.
- Remaining unknowns are image-production mechanics or external approval/
  measured-release results and cannot change this contract without the stated
  change-control response.

## Execution Prerequisites

- Read root `AGENTS.md`, `.agents/AGENTS.md`, `.agents/PLANS.md`, this entire
  contract, the active product and visual specs, workbench README/source, and
  production README.
- Confirm the superseded plan is not treated as executable and the narrow BK
  visual-switch waiver recorded there and in the pre-asset plan remains present.
  Phase 0 is already complete; do not rerun its checked discovery tasks.
- Run `git status --short`; stop only for an overlapping unrelated change.
- Record the current branch, full HEAD, timestamp, and clean/dirty state in the
  Progress section before Task 6.0 begins.
- Confirm the 30 target units have null approval/application and no unreviewed
  TO-BE bytes. If the source contradicts this checkpoint, update the contract
  before continuing rather than replaying completed work.

## Shared Validation Sets

Run validator filenames through this repository-root PowerShell helper; a task
that names a set requires every file in that set:

```powershell
function Invoke-GodotChecks([string[]]$Names) {
  foreach ($name in $Names) {
    .\tools\godot.ps1 --headless --path . --script "res://tools/validation/$name"
    if ($LASTEXITCODE -ne 0) { throw "Validation failed: $name" }
  }
}
```

`V-WORKBENCH`:

```powershell
.\tools\design\build_visual_replacement_workbench.ps1
.\tools\design\build_visual_replacement_workbench.ps1 -Check
.\tools\validation\validate_visual_replacement_workbench.ps1
git diff --check
```

`V-CORE`:

```powershell
Invoke-GodotChecks @(
  "validate_vehicle_semantic_asset_provider.gd",
  "validate_vehicle_visual_asset_coverage.gd",
  "validate_vehicle_visual_replacement_coverage.gd",
  "validate_vehicle_semantic_visual_separation.gd"
)
```

`V-PLAYER`:

```powershell
Invoke-GodotChecks @(
  "validate_vehicle_player_presentation.gd",
  "validate_vehicle_actor_visuals.gd",
  "validate_vehicle_combat_renderer.gd",
  "validate_vehicle_primary_weapon.gd",
  "validate_vehicle_secondary_weapons.gd",
  "validate_vehicle_hud_presenter.gd"
)
```

`V-HUD-UPGRADE`:

```powershell
Invoke-GodotChecks @(
  "validate_vehicle_hud_presenter.gd",
  "validate_vehicle_stage_ui_layout.gd",
  "validate_vehicle_ui_localization.gd",
  "validate_vehicle_upgrade_ui.gd"
)
```

`V-WORLD`:

```powershell
Invoke-GodotChecks @(
  "validate_vehicle_world_visuals.gd",
  "validate_vehicle_reward_facility_visual_recipes.gd",
  "validate_vehicle_terrain_runtime.gd",
  "validate_vehicle_wear_collapse_tiles.gd",
  "validate_vehicle_destructible_terrain_flow.gd",
  "validate_vehicle_pickup_contact.gd",
  "validate_vehicle_field_layout_generation.gd",
  "validate_vehicle_stage_layouts.gd",
  "validate_vehicle_combat_renderer.gd"
)
```

`V-COMBAT`:

```powershell
Invoke-GodotChecks @(
  "validate_vehicle_actor_visuals.gd",
  "validate_vehicle_attack_contract.gd",
  "validate_vehicle_damage_feedback.gd",
  "validate_vehicle_combat_renderer.gd",
  "validate_vehicle_collective_tactics.gd",
  "validate_vehicle_guidebook.gd",
  "validate_vehicle_performance_scenarios.gd"
)
```

`V-BOSS`:

```powershell
Invoke-GodotChecks @(
  "validate_vehicle_actor_visuals.gd",
  "validate_vehicle_boss_exams.gd",
  "validate_vehicle_boss_patterns.gd",
  "validate_vehicle_boss_practice.gd",
  "validate_vehicle_boss_runtime.gd",
  "validate_vehicle_combat_renderer.gd",
  "validate_vehicle_guidebook.gd",
  "validate_vehicle_stage_transition.gd",
  "validate_vehicle_stage_report.gd"
)
```

`V-CAPTURE` is required if capture workflow/code changes and at every phase
rendered gate:

```powershell
Invoke-GodotChecks @("validate_vehicle_run_capture_driver.gd")
```

Validation-set rules:

- Every unit runs `V-WORKBENCH` and `V-CORE` plus the set named in its phase
  table after production application.
- Static units validate dimensions, pivot, provider binding, runtime-scale
  readability, grayscale distinction, and their actual UI/world state. They do
  not invent animation assertions.
- Animated units additionally validate declared frame sequence, fps, loop,
  blend, event mapping, total duration, actual event state, and reduced-motion
  presentation.
- Run the full `validate_*.gd` release suite only once in Phase 11 unless a
  later final-gate fix changes a covered input.

## Milestones and Tasks

### Phase 6 - Player actions, Secondary Weapons, minimap, and glyphs

Goal: replace all player-controlled action and Secondary Weapons imagery, then
replace the affected minimap and upgrade/HUD glyphs without changing UI layout
or gameplay.

Preconditions: Execution Prerequisites pass. All Phase 6 units are
`target_required` with null approval/application.

Source owners: `replacement-workbench.json`, gameplay asset manifest, semantic
asset provider, combat renderer, HUD presenter, upgrade glyph renderer.

#### Phase 6 unit contract

The exact ordered target paths and per-file metadata remain in the workbench
unit with the matching ID. This table is the required count/geometry summary:

| Task | Unit | Canonical English label | Exact deliverable contract | Validation |
| --- | --- | --- | --- | --- |
| 6.1 | `primary_weapon` | Primary Weapon | 4 x `48x48` muzzle frames at 20 fps, one `64x64` action glyph, two `112x64` projectiles; 7 files | CORE + PLAYER |
| 6.2 | `dash` | Dash | 3 x `96x48` start frames at 15 fps, one `64x64` action glyph; 4 files | CORE + PLAYER |
| 6.3 | `emp` | EMP | 6 x `512x512` release frames at 12 fps, one `64x64` action glyph; 7 files | CORE + PLAYER |
| 6.4 | `barrier` | Barrier | 5 x `128x128` contact frames at 20 fps, one `64x64` action glyph, one `96x128` player plate; 7 files | CORE + PLAYER |
| 6.5 | `ion_field` | Ion Field | two static `64x64` assets; 2 files | CORE + PLAYER |
| 6.6 | `seeker` | Seeker | 4 x `96x96` impact frames at 20 fps, one `64x64` action glyph, two `96x64` projectile/secondary assets; 7 files | CORE + PLAYER + HUD-UPGRADE |
| 6.7 | `orbit_blades` | Orbit Blades | 4 x `96x96` impact frames at 20 fps, one `64x32` blade; 5 files | CORE + PLAYER |
| 6.8 | `wake_mines` | Wake Mine Layer | 5 x `256x256` detonation frames at 15 fps, one `48x48` mine; 6 files | CORE + PLAYER |
| 6.9 | `escort_drone` | Escort Drone | 4 x `96x96` impact frames at 20 fps, one `64x48` drone; 5 files | CORE + PLAYER |
| 6.10 | `minimap_nonplayer_markers` | Non-player Minimap Markers | five static `48x48` markers; 5 files | CORE + HUD-UPGRADE |
| 6.11 | `upgrade_family_glyphs` | Upgrade Family Glyphs | seven live static `64x64` glyphs; exact passive PNG + sidecar retirement; Seeker reuses `hud/action_seeker` | CORE + HUD-UPGRADE |
| 6.12 | `status_orbit_support_glyph` | Status Orbit Support Glyph | one static `64x64` glyph | CORE + HUD-UPGRADE |

- [ ] **6.0 Repair and freeze the remaining-work control plane.**
  - Change: implement all seven Workbench and state-machine repair items,
    including the transition-aware workbench/provider/coverage validators,
    persistent four-retirement-ledger contract, canonical localized titles,
    corrected seven-file upgrade glyph membership, exact passive retirement
    paths, corrected 12-path shared-boss structural list, README wording, and
    regenerated workbench output.
  - Accept: `V-WORKBENCH` passes with the unchanged discovery baseline of 36
    units, 30 target/two keep/four retired, 215 current gameplay PNGs, and no
    TO-BE files; both Godot coverage validators pass against manifest-derived
    identity/category expectations; a synthetic or fixture-backed legal
    status/count transition is covered without weakening path/hash/ledger,
    missing/orphan/duplicate-ID, or consumer validation; `-Final` correctly
    rejects the starting state.
  - Guard: do not create, promote, bind, or delete an asset in this task.

- [ ] **6.1 Complete `primary_weapon` through the Unit Switch Protocol.**
  - Accept: all seven targets and actual held-primary states pass the table
    contract, `V-CORE`, and `V-PLAYER`; range, cadence, collision core, piercing,
    structure chip, and manual aim remain unchanged.

- [ ] **6.2 Complete `dash` through the Unit Switch Protocol.**
  - Accept: all four targets, ordinary and reduced-motion start states, action
    cooldown, `V-CORE`, and `V-PLAYER` pass; dash movement/timing is unchanged.

- [ ] **6.3 Complete `emp` through the Unit Switch Protocol.**
  - Accept: all seven targets, release radius/readability, action cooldown,
    `V-CORE`, and `V-PLAYER` pass; EMP timing/radius/effect is unchanged.

- [ ] **6.4 Complete `barrier` through the Unit Switch Protocol.**
  - Accept: all seven targets, plate/contact/disabled presentation, `V-CORE`,
    and `V-PLAYER` pass; barrier absorption/state truth is unchanged.

- [ ] **6.5 Complete `ion_field` through the Unit Switch Protocol.**
  - Accept: both static assets read at gameplay/HUD scale and `V-CORE` plus
    `V-PLAYER` pass; radius, cadence, and damage are unchanged.

- [ ] **6.6 Complete `seeker` through the Unit Switch Protocol.**
  - Accept: all seven targets, flight/impact/action/card artwork, `V-CORE`,
    `V-PLAYER`, and `V-HUD-UPGRADE` pass; Seeker remains always equipped and no
    `hud/upgrade_passive` runtime dependency exists.

- [ ] **6.7 Complete `orbit_blades` through the Unit Switch Protocol.**
  - Accept: all five targets, every bounded orbit count/contact state,
    `V-CORE`, and `V-PLAYER` pass without movement/damage change.

- [ ] **6.8 Complete `wake_mines` through the Unit Switch Protocol.**
  - Accept: all six targets, placement/detonation/cap states, `V-CORE`, and
    `V-PLAYER` pass without cadence, cap, trigger, or damage change.

- [ ] **6.9 Complete `escort_drone` through the Unit Switch Protocol.**
  - Accept: all five targets, movement/fire/impact states, `V-CORE`, and
    `V-PLAYER` pass without targeting, cadence, or damage change.

- [ ] **6.10 Complete `minimap_nonplayer_markers` through the Unit Switch Protocol.**
  - Accept: all five markers remain distinct at `48x48`, in grayscale, and at
    960/1280/1920 widths; `V-CORE` and `V-HUD-UPGRADE` pass.

- [ ] **6.11 Complete corrected `upgrade_family_glyphs` through the Unit Switch Protocol.**
  - Change: prepare only `upgrade_primary`, `upgrade_secondary`,
    `upgrade_defense`, `upgrade_dash`, `upgrade_skill`, `upgrade_element`, and
    `upgrade_mobility`; display and request exact approval to retire
    `art/visuals/production/gameplay/hud/upgrade_passive.png` and its exact
    tracked sidecar; include the exact manifest path as the unit's sole runtime
    change and remove `upgrade_passive.png` from the manifest `hud` set in the
    atomic switch; never create a passive replacement.
  - Accept: eight live upgrade families resolve eight semantic textures across
    the seven generic glyphs plus `hud/action_seeker`; every card has one body
    artwork and no missing slot; zero non-ledger references to passive remain;
    `V-CORE` and `V-HUD-UPGRADE` pass.
  - Guard: if the exact two-path retirement is not approved, keep this unit
    `switch_ready`, do not delete or revive the asset, and do not claim final
    inventory completion.

- [ ] **6.12 Complete `status_orbit_support_glyph` through the Unit Switch Protocol.**
  - Accept: the one glyph remains readable in every live status/support state
    and `V-CORE` plus `V-HUD-UPGRADE` pass.

Phase 6 batch gate:

- [ ] Run `V-CAPTURE`, then generate native Korean and English captures at
  `960x540`, `1280x720`, and `1920x1080`; add `1280x720` at text scale `2.0` for
  the HUD/upgrade surfaces. The capture command uses the README argument-array
  form with `--rendering-method gl_compatibility`, `--capture-all=<absolute
  build path>`, locale, size, and the fixed documented layout seed.
- [ ] Compare gameplay-scale action, projectile/effect, cooldown, minimap, and
  selected upgrade-card states against exact deliverables and the visual spec;
  require zero clipping, missing art, illegible grayscale state, or extra UI.
- [ ] Export and serve the built Web artifact on the fastrun `codex` lane after
  loading `npjt-port-guard`; smoke held primary, dash, EMP, all five Secondary
  Weapons, minimap markers, HUD glyphs, and the upgrade choice in foreground
  Chrome with zero console warnings/errors.
- [ ] Record phase evidence, then baseline-promote all applied Phase 6 units and
  require `V-WORKBENCH`, `V-CORE`, `V-PLAYER`, and `V-HUD-UPGRADE` to pass once
  on the phase baseline.

### Phase 7 - World, facilities, pickups, and reward feedback

Goal: replace functional world/reward imagery and add authored wear textures
while preserving procedural base fields, exact gameplay rectangles/radii,
topology, collision, state, values, and deterministic fingerprints.

Preconditions: Phase 6 batch gate passes. The historical
`procedural_floor_and_walls` retirement remains applied and is not target work.

Source owners: workbench world units, gameplay asset manifest, `VehicleRun`,
`VehicleCombatRenderer`, terrain/runtime/reward owners, and their focused
validators.

| Task | Unit | Exact deliverable contract |
| --- | --- | --- |
| 7.1 | `wear_tile_family` | add three `240x160` static states, pivot `120,80`; exact runtime changes in manifest, run, renderer, validator |
| 7.2 | `breakable_bulkhead` | two `192x192` states plus 5 x `256x256` destroy frames at 12 fps; 7 files |
| 7.3 | `support_facilities` | repair pad/core, overdrive lane, plus 4 x `128x128` heal frames at 15 fps; 7 files |
| 7.4 | `transit_facility` | one `192x192` gate plus 5 x `160x96` shift frames at 15 fps; 6 files |
| 7.5 | `arc_and_cover_world` | four static `192x192` functional world assets; 4 files |
| 7.6 | `pickup_family` | six static pickup/crate assets, 5 x `128x128` crate-destroy frames at 15 fps, 4 x `96x96` intake frames at 20 fps; 15 files |
| 7.7 | `lifesteal_feedback` | 4 x `64x64` frames at 20 fps |

- [ ] **7.0 Preserve the completed procedural-floor/wall boundary.**
  - Accept: the retired unit remains one of the four validated absence ledgers;
    procedural surfaces/walls remain runtime truth; fingerprints and
    walkable/void containment match the pre-phase baseline; no floor/wall PNG is
    recreated or rebound.

- [ ] **7.1 Complete `wear_tile_family` through the Unit Switch Protocol.**
  - Accept: all three state textures fit the unchanged snapshot rectangle; four
    tiles in each field show intact/cracked/collapsed immediately; wear,
    repeated damage, actor occupancy, stage persistence, and player/enemy/boss
    crossings pass `V-CORE` and `V-WORLD`.
  - Guard: image state never owns wear, damage, occupancy, or collision.

- [ ] **7.2 Complete `breakable_bulkhead` through the Unit Switch Protocol.**
  - Accept: sealed/damaged/destroy states and open-as-absence pass `V-CORE` and
    `V-WORLD`; health, reward reachability, LOS, collision, and persistence are
    unchanged.

- [ ] **7.3 Complete `support_facilities` through the Unit Switch Protocol.**
  - Accept: repair/overdrive footprints and heal animation align to runtime
    rectangles/radii and `V-CORE` plus `V-WORLD` pass without value/schedule
    changes.

- [ ] **7.4 Complete `transit_facility` through the Unit Switch Protocol.**
  - Accept: gate and shift states align to the unchanged transit footprint and
    `V-CORE` plus `V-WORLD` pass without movement/state changes.

- [ ] **7.5 Complete `arc_and_cover_world` through the Unit Switch Protocol.**
  - Accept: arc strip, breakable cover, power relay, and solid cover remain
    distinct and footprint-accurate; `V-CORE` and `V-WORLD` pass without
    topology, collision, LOS, or hazard changes.

- [ ] **7.6 Complete `pickup_family` through the Unit Switch Protocol.**
  - Accept: all 15 targets, contact collection, crate destruction, recall,
    repair, drop totals, HUD/report use, `V-CORE`, and `V-WORLD` pass; values and
    drop logic are unchanged.

- [ ] **7.7 Complete `lifesteal_feedback` through the Unit Switch Protocol.**
  - Accept: all four frames remain readable under pressure and `V-CORE` plus
    `V-WORLD` pass without sustain-value or damage-source change.

Phase 7 batch gate:

- [ ] Re-run deterministic field fingerprints and surface-pattern checks from
  the recorded pre-phase baseline.
- [ ] Capture all three fields in native and built Web at gameplay scale,
  including every wear state, bulkhead state, facility, cover/arc object, crate,
  pickup, and feedback; require visible footprints to match gameplay truth.
- [ ] Record phase evidence, baseline-promote all applied Phase 7 units, and run
  `V-WORKBENCH`, `V-CORE`, and `V-WORLD` once on the phase baseline.

### Phase 8 - Ordinary enemies, hostile attacks, and combat cues

Goal: replace the complete ordinary-enemy and hostile-threat presentation
family so role, delivery, state, and priority remain readable under maximum
combat pressure without changing any roster, AI, attack, damage, collision, or
encounter rule.

Preconditions: Phase 7 batch gate passes. The historical
`effect_atlas_retirement` remains applied and frame animation remains the only
effect-animation source of truth.

Source owners: workbench combat units, gameplay asset manifest, semantic asset
provider, actor visual catalog, combat renderer, guidebook presentation, and
their focused validators.

| Task | Unit | Exact deliverable contract |
| --- | --- | --- |
| 8.1 | `ordinary_enemy_family` | 19 static bodies: thirteen `112x112`, pivot `56,56`; six `160x160`, pivot `80,80` |
| 8.2 | `hostile_projectile_family` | six `80x80` projectiles, pivot `40,40` |
| 8.3 | `enemy_defense_states` | two `96x96` states, pivot `48,48` |
| 8.4 | `persistent_status_states` | burn, chill, and poison at `96x96`, pivot `48,48` |
| 8.5 | `combat_cue_family` | 22 static `96x96` cues, pivot `48,48` |
| 8.6 | `hostile_arrival` | 6 x `192x192` frames, pivot `96,96`, 12 fps |
| 8.7 | `enemy_destruction` | light: 5 x `160x160`, pivot `80,80`; heavy: 6 x `192x192`, pivot `96,96`; both 15 fps |
| 8.8 | `generic_damage_feedback` | impact: 5 x `64x64`; hull: 4 x `96x96`; deflection: 5 x `96x96`; all 20 fps |

- [ ] **8.0 Preserve the completed effect-atlas boundary.**
  - Accept: `effect_atlas_retirement` remains one of the four validated absence
    ledgers; no atlas or sheet becomes a runtime target; the manifest continues
    to declare 22 frame-based animation identities totaling 101 frames.

- [ ] **8.1 Complete `ordinary_enemy_family` through the Unit Switch Protocol.**
  - Prepare one identical-scale color comparison and one grayscale comparison
    containing all 19 exact targets.
  - Accept: swarm, melee, ranged, command, stationary, shield, support,
    artillery, interceptor, rammer, guard, splitter, carrier, repair, beam, and
    pylon responsibilities represented by the current roster remain
    first-clear; base, elite, and collective overlays do not erase the base
    silhouette; `V-CORE` and `V-COMBAT` pass.
  - Guard: do not add an enemy identity or rely on hue alone for role or tier.

- [ ] **8.2 Complete `hostile_projectile_family` through the Unit Switch
  Protocol.**
  - Accept: arc, cryo, hybrid, kinetic, thermal, and toxin affinities remain
    distinguishable; each damaging core matches collision truth; directional
    tails remain non-damaging; delivery, ordinary/elite/boss tier, and light/
    standard/heavy power remain readable under motion; `V-CORE` and `V-COMBAT`
    pass.

- [ ] **8.3 Complete `enemy_defense_states` through the Unit Switch Protocol.**
  - Accept: generator source and escort plate cannot be confused with health,
    status, objective, or attack cues; shield ownership and timing remain
    simulation-owned; `V-CORE` and `V-COMBAT` pass.

- [ ] **8.4 Complete `persistent_status_states` through the Unit Switch
  Protocol.**
  - Accept: burn, chill, and poison remain distinct in color and grayscale at
    gameplay scale; status duration, stacking, and damage remain unchanged;
    `V-CORE` and `V-COMBAT` pass.

- [ ] **8.5 Complete `combat_cue_family` through the Unit Switch Protocol.**
  - Accept: all 22 exact cue IDs retain meaning for boss core, collective,
    commit, elite trait, guide category, objective, priority target, ranged
    startup, and target bracket states; off-screen warnings and guidebook uses
    remain first-clear; `V-CORE` and `V-COMBAT` pass.

- [ ] **8.6 Complete `hostile_arrival` through the Unit Switch Protocol.**
  - Accept: all six exact frames pass dimensions, pivot, 12 fps, non-looping
    alpha blend, event mapping, total duration, and reduced-motion checks;
    arrival intent remains visible before the hostile becomes actionable;
    `V-CORE` and `V-COMBAT` pass.

- [ ] **8.7 Complete `enemy_destruction` through the Unit Switch Protocol.**
  - Accept: the five light and six heavy exact frames pass their separate size,
    pivot, 15 fps, non-looping alpha blend, event, duration, and reduced-motion
    checks; destruction weight is distinct without changing death timing,
    rewards, or cleanup; `V-CORE` and `V-COMBAT` pass.

- [ ] **8.8 Complete `generic_damage_feedback` through the Unit Switch
  Protocol.**
  - Accept: impact, hull hit, and reflection/deflection have distinct event
    meanings; all 14 exact frames pass their declared size, pivot, 20 fps,
    non-looping alpha blend, duration, and reduced-motion checks; damage and
    reflection truth remain simulation-owned; `V-CORE` and `V-COMBAT` pass.

Phase 8 batch gate:

- [ ] Capture identical native and built-Web `peak_horde` and
  `capacity_pressure` scenes at gameplay scale with ordinary roles, elite and
  collective overlays, projectile affinities/tiers, defenses, statuses, cues,
  arrival, destruction, and damage feedback visible.
- [ ] Require first-clear target priority and threat footprints in color and
  grayscale with no console warning/error and no lost damaging-core alignment.
- [ ] Record phase evidence, baseline-promote all applied Phase 8 units, and
  run `V-WORKBENCH`, `V-CORE`, and `V-COMBAT` once on the phase baseline.

### Phase 9 - Boss bodies, shared boss nodes, and boss feedback

Goal: replace all five boss bodies and consolidate ten boss-specific defensive
module images into a shared active/damaged/resolved presentation while
preserving every gameplay module identity, exam, pattern, target, objective,
damage gate, and resolution rule.

Preconditions: Phase 8 batch gate passes. `boss_body_family`,
`shared_boss_node`, and `boss_hit_feedback` remain independent approval and
rollback units.

Source owners: workbench boss units, gameplay asset manifest,
`VehicleCombatRenderer`, `vehicle_actor_visual_catalog.gd`,
`vehicle_visual_system_registry.gd`, boss runtime, guidebook/minimap/objective/
report presenters, and boss validators.

| Task | Unit | Exact deliverable contract |
| --- | --- | --- |
| 9.1 | `boss_body_family` | five `352x352` bodies, pivot `176,176` |
| 9.2 | `shared_boss_node` | active/damaged/resolved: three `160x160`, pivot `80,80`; disabled effect: 4 x `128x128`, pivot `64,64`, 12 fps; consolidate 14 current files to seven targets and retire 20 exact paths |
| 9.3 | `boss_hit_feedback` | 4 x `96x96` reduced-hit frames, pivot `48,48`, 20 fps |

- [ ] **9.1 Complete `boss_body_family` through the Unit Switch Protocol.**
  - Accept: Behemoth, Colossus, Crown, Leviathan, and Titan remain distinct by
    large silhouette and four to six major planes, not color alone; phase
    readability, guidebook preview, minimap, objective HUD, stage report,
    `V-CORE`, and `V-BOSS` pass without gameplay changes.

- [ ] **9.2 Prepare `shared_boss_node` as one atomic structural unit.**
  - Task 6.0 must set this exhaustive exact `runtime_change_paths` list before
    preparation or approval:
    - `art/visuals/production/gameplay/asset-manifest.json`
    - `scripts/presentation/components/vehicle_semantic_asset_provider.gd`
    - `scripts/presentation/vehicle_combat_renderer.gd`
    - `scripts/presentation/components/vehicle_actor_visual_catalog.gd`
    - `scripts/presentation/components/vehicle_actor_mesh_recipes.gd`
    - `scripts/presentation/vehicle_combat_visual_library.gd`
    - `scripts/presentation/components/vehicle_visual_system_registry.gd`
    - `tools/validation/validate_vehicle_actor_visuals.gd`
    - `tools/validation/validate_vehicle_semantic_asset_provider.gd`
    - `tools/validation/validate_vehicle_visual_asset_coverage.gd`
    - `tools/validation/validate_vehicle_combat_renderer.gd`
    - `tools/validation/validate_vehicle_boss_runtime.gd`
  - Replace the manifest/provider namespace of ten `boss_module/*` texture IDs
    with exactly `boss_node/active`, `boss_node/damaged`, and
    `boss_node/resolved`; keep all four
    `effect/boss_module_disabled/<frame>` IDs and their animation identity.
  - In presentation fallback ownership, replace module-kind-specific catalog/
    mesh selection with one shared node descriptor and one state-based fallback
    recipe. Keep gameplay module kind/index outside those presentation owners.
    Update the registry fingerprint and remove old presentation recipes only
    after their zero-reference proof.
  - Implement this exhaustive visual mapping:
    - locked modules use active node geometry plus the existing locked tint and
      `cue/commit_locked` overlay;
    - active modules with `health / max_health > 0.50` use active;
    - active modules with `health > 0` and ratio `<= 0.50` use damaged;
    - resolved state, disabled compatibility input, zero health, and every
      `resolved_boss_modules` snapshot use resolved;
    - evaluate terminal zero health before division, reject
      `max_health <= 0` for a live module, and fail an unknown state rather than
      adding a silent fallback;
    - sealed, open, and stable boss cores continue to use
      `cue/boss_core_sealed`, `cue/boss_core_open`, and
      `cue/boss_core_stable`; a boss core never selects a shared module node.
  - Preserve module kind/index in gameplay snapshots, objective text,
    localization, exam logic, targeting, and resolution. Only presentation
    asset selection becomes shared.
  - The exact retirement set to display again with hashes before approval is:
    - `art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_armor_car.png`
    - `art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_armor_car.png.import`
    - `art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_crown_lattice.png`
    - `art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_crown_lattice.png.import`
    - `art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_crown_pylon.png`
    - `art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_crown_pylon.png.import`
    - `art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_forge_plate_active.png`
    - `art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_forge_plate_active.png.import`
    - `art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_forge_plate_disabled.png`
    - `art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_forge_plate_disabled.png.import`
    - `art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_relay_negative.png`
    - `art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_relay_negative.png.import`
    - `art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_relay_positive.png`
    - `art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_relay_positive.png.import`
    - `art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_route_switch.png`
    - `art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_route_switch.png.import`
    - `art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_segment_lock_active.png`
    - `art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_segment_lock_active.png.import`
    - `art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_segment_lock_disabled.png`
    - `art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_segment_lock_disabled.png.import`
  - Stop before mapping or deletion unless approval covers the exact seven
    target hashes, exact target mappings, exact 20 retirement paths, exact 12
    runtime paths, and clean baseline. After approval, prove zero remaining
    references and land mapping, targets, provider/fallback cleanup,
    state-validation changes, and retirement in the same structural
    production-switch commit.
  - Accept: exactly three shared node states and four disabled frames render;
    all five bosses and every live/damaged/locked/resolved module/core state,
    guidebook, minimap, objective, report, and stage transition pass `V-CORE`
    and `V-BOSS`; zero boss-specific module asset ID or path remains.

- [ ] **9.3 Complete `boss_hit_feedback` through a separate Unit Switch
  Protocol.**
  - Do not include these four hashes in `shared_boss_node` approval.
  - Accept: reduced boss damage remains distinct from ordinary hull damage;
    all four frames pass `96x96`, pivot `48,48`, 20 fps, non-looping alpha
    blend, duration, event, and reduced-motion checks; damage reduction remains
    gameplay-owned; `V-CORE` and `V-BOSS` pass.

Phase 9 batch gate:

- [ ] Capture all five bosses and every core/module state in native and built
  Web, including locked, active, damaged, resolved, reduced hit, disabled
  effect, objective, minimap, guidebook, and report views.
- [ ] Run rendered `boss_pressure` in native and built Web with no console
  warning/error and confirm target priority and damaging footprints remain
  readable under pressure.
- [ ] Record phase evidence, baseline-promote all applied Phase 9 units, and
  run `V-WORKBENCH`, `V-CORE`, and `V-BOSS` once on the phase baseline.

### Phase 10 - Reconcile production and clean the workbench

Goal: turn every verified applied target into current AS-IS truth, remove only
obsolete transitional/review material, and prove one consumer and one unit own
every production medium.

Preconditions: every Phase 6-9 batch gate passes and every one of the 30 former
`target_required` units has been applied and phase-baseline promoted.

- [ ] **10.1 Close every transitional unit.**
  - Baseline-promote any verified `applied` record that was not already closed
    at a phase gate. Production targets become `current_paths`; consumer
    mappings refresh; deliverables, preview paths, retire paths,
    `runtime_change_paths`, approval, and application clear; direction becomes
    `No replacement is currently approved.`; status becomes `keep_current`.
  - Remove that unit's duplicate TO-BE files and generated contact sheet in the
    same cleanup. Git and the acceptance record own history; the active
    workbench does not retain a second copy of current truth.
  - Reject any `keep_current` unit that retains transitional data.

- [ ] **10.2 Prove the final production inventory.**
  - Require exactly 210 provider-indexed gameplay PNGs, zero production UI
    chrome PNGs, one production font plus license, 22 animation identities, 101
    frame PNGs, and zero effect atlases.
  - Require exactly one workbench unit and one declared runtime consumer for
    every production medium; require zero staged/unconsumed media and zero old
    player attachment, boss-module, workbench, historical snapshot,
    review-image, or old production-root reference.
  - Run `validate_visual_replacement_workbench.ps1 -Final`. Any count drift is
    a contract contradiction, not a reason to edit the expected count silently.

- [ ] **10.3 Preserve the four retirement ledgers.**
  - Keep `effect_atlas_retirement`, `procedural_floor_and_walls`,
    `orphan_ui_state_retirement`, and `ui_chrome_retirement` as `retired` with
    their exact historical approval/application evidence and validated absence
    paths.
  - Final workbench state must be exactly 36 units: 32 `keep_current`, four
    `retired`, and zero `target_required`, `switch_ready`,
    `approved_for_switch`, or `applied`.

- [ ] **10.4 Clean obsolete preview material under exact authority.**
  - Retain the complete
    `docs/design/visual-replacement-workbench/previews/ui-screen-direction`
    collection and its `index.html`; the workbench index links to it as durable
    user-visible direction/runtime evidence.
  - Display and request one exact deletion approval for these three currently
    unreferenced legacy paths:
    - `docs/design/visual-replacement-workbench/previews/as-is/ui/.gdignore`
    - `docs/design/visual-replacement-workbench/previews/as-is/ui/01-ui-surface-components.png`
    - `docs/design/visual-replacement-workbench/previews/as-is/ui/02-ui-control-states.png`
  - If approval is absent, preserve all three paths and stop only Phase 10
    cleanup completion. Do not delete or imply approval from this plan.

- [ ] **10.5 Rebuild the final control plane and audit broad changes.**
  - Rebuild `inventory.json` and `index.html`; confirm the index displays only
    current production AS-IS, the four negative-inventory guards, and durable
    screen-direction evidence, with no completed TO-BE binary duplicate.
  - Run the codebase quality audit because manifests, providers, catalogs,
    renderers, generators, and validators changed across modules. Apply only
    small safe task-scoped corrections; route broader findings through change
    control.

Phase 10 batch gate:

- [ ] Run `V-WORKBENCH`, the `-Final` workbench validator, `V-CORE`, Godot
  headless import, and `git diff --check` from a clean committed baseline.
- [ ] Record the exact final status/count/ownership/absence report and its
  commit before entering Phase 11.

### Phase 11 - Full release validation, evidence, and plan retirement

Goal: prove the complete visual replacement on clean committed native and built
Web artifacts, preserve auditable evidence, update only durable authorities,
and retire the two now-obsolete execution plans.

Preconditions: Phase 10 batch gate passes at a clean full HEAD. No release gate
is waived by the earlier permission to start visual replacement.

- [ ] **11.1 Run repository and engine gates from clean HEAD.**
  - Enumerate `tools/validation/validate_*.gd` dynamically, sort it, record the
    list and count, and require the discovery contract of 58 validators unless
    a task-owned change deliberately adds/removes a validator and updates this
    contract first. Run each through `tools/godot.ps1`; stop on the first
    nonzero exit.
  - Run `profile_vehicle_pressure.gd` separately as a diagnostic. Its output is
    never counted as a release validator or authoritative performance evidence.
  - Run:

```powershell
$validators = Get-ChildItem -LiteralPath "tools/validation" -Filter "validate_*.gd" -File |
  Sort-Object Name
if ($validators.Count -ne 58) {
  throw "Validator contract drift: expected 58, found $($validators.Count)"
}
foreach ($validator in $validators) {
  .\tools\godot.ps1 --headless --path . --script "res://tools/validation/$($validator.Name)"
  if ($LASTEXITCODE -ne 0) { throw "Validation failed: $($validator.Name)" }
}
.\tools\godot.ps1 --headless --path . --script `
  res://tools/validation/profile_vehicle_pressure.gd
if ($LASTEXITCODE -ne 0) { throw "Pressure diagnostic failed" }
.\tools\validation\validate_document_authority.ps1
.\tools\validation\validate_visual_replacement_workbench.ps1 -Final
.\tools\design\build_visual_replacement_workbench.ps1 -Check
.\tools\godot.ps1 --headless --path . --editor --quit
.\tools\export_web.ps1
git diff --check
```

  - Accept: every command passes, export completes, and no generated tracked
    drift remains. The Web export is necessary but not sufficient acceptance.

- [ ] **11.2 Capture native responsive/localized evidence.**
  - Use the existing capture driver with this exact locale/size/text-scale
    matrix:

```powershell
$captureRoot = Join-Path (Resolve-Path .).Path "build\captures\visual-replacement"
$captureCases = @(
  @{ Size = "960x540"; Scale = "1.0" },
  @{ Size = "1280x720"; Scale = "1.0" },
  @{ Size = "1920x1080"; Scale = "1.0" },
  @{ Size = "1280x720"; Scale = "2.0" }
)
foreach ($locale in @("ko", "en")) {
  foreach ($case in $captureCases) {
    $caseDir = Join-Path $captureRoot (
      "$locale-$($case.Size)-text-$($case.Scale.Replace('.', '-'))"
    )
    $godotArgs = @(
      "--rendering-method", "gl_compatibility", "--",
      "--capture-all=$caseDir",
      "--capture-locale=$locale",
      "--capture-size=$($case.Size)",
      "--capture-text-scale=$($case.Scale)",
      "--layout-seed=12886704"
    )
    .\tools\godot.ps1 @godotArgs
    if ($LASTEXITCODE -ne 0) {
      throw "Capture failed: $locale/$($case.Size)/$($case.Scale)"
    }
  }
}
```

  - The matrix produces Korean and English captures at `960x540`, `1280x720`,
    and `1920x1080`, plus `1280x720` at 200% text scale for both locales.
  - Accept: every gameplay/HUD/upgrade, guidebook, pause, settings, report,
    victory, and defeat surface has correct alignment, typography, spacing,
    safe insets, focus, target size, localization, and zero clipping/overflow;
    grayscale and reduced motion preserve state information.

- [ ] **11.3 Run built-Web visual and interaction smoke.**
  - Load `$npjt-port-guard` before starting a server for this repository. Serve
    `build/web` through the fastrun manager's `codex` lane, use a visible
    foreground Chrome window, and inspect the built app rather than a dev
    server.
  - Exercise movement, manual aim, uniform held primary fire, dash, EMP,
    Seeker and all four optional Secondary Weapons, pickups, every wear and
    bulkhead state, facilities, ordinary enemies, all bosses, pause, settings,
    guidebook, report, stage transition, victory, and defeat.
  - Repeat representative visual checks in Korean/English at all three
    supported resolutions and 200% text scale; verify mouse, keyboard, and
    gamepad focus, compact modal behavior, reduced motion, grayscale, and no
    console warning/error.

- [ ] **11.4 Run authoritative native performance.**
  - Keep the `1280x720` window visible, foreground, and focused. Use a clean
    commit and preserve one JSON per attempt:

```powershell
$performanceCommit = (git rev-parse HEAD).Trim()
$performanceDirty = if (git status --porcelain) { "1" } else { "0" }
$env:PERFORMANCE_COMMIT = $performanceCommit
$env:PERFORMANCE_DIRTY = $performanceDirty

foreach ($scenario in @("production_replay", "peak_horde", "capacity_pressure", "boss_pressure")) {
  for ($attempt = 1; $attempt -le 3; $attempt++) {
    .\tools\godot.ps1 --path . --rendering-method gl_compatibility --resolution 1280x720 -- `
      "--performance-scenario=$scenario" `
      "--performance-output=res://build/performance/visual-replacement/native/$scenario-final-$attempt.json" `
      --performance-warmup=10 --performance-duration=60
    if ($LASTEXITCODE -ne 0) { throw "Native performance failed: $scenario/$attempt" }
  }
}

.\tools\godot.ps1 --path . --rendering-method gl_compatibility --resolution 1280x720 -- `
  --performance-scenario=lifecycle_pressure `
  --performance-output=res://build/performance/visual-replacement/native/lifecycle-pressure-600s.json `
  --performance-warmup=10 --performance-duration=600
if ($LASTEXITCODE -ne 0) { throw "Native lifecycle soak failed" }
Remove-Item Env:PERFORMANCE_COMMIT, Env:PERFORMANCE_DIRTY -ErrorAction SilentlyContinue
```

- [ ] **11.5 Run authoritative built-Web performance.**
  - Use the same built export and visible foreground Chrome session from the
    fastrun `codex` lane. For each of `production_replay`, `peak_horde`,
    `capacity_pressure`, and `boss_pressure`, run attempts `1..3` with
    `?performance_scenario=<id>&performance_warmup=10&performance_duration=60`.
  - Read `window.__cardbornePerformanceResultJson` and save each valid payload
    to `build/performance/visual-replacement/web/<id>-final-<attempt>.json`.
    Hidden/headless/unfocused attempts are invalid. Allow at most three
    replacement attempts per scenario to obtain three valid runs; otherwise
    fail the release gate.

- [ ] **11.6 Enforce the absolute performance/lifecycle verdict.**
  - Every native and Web attempt must meet frame median `>= 59 FPS`, frame p95
    `<= 18 ms`, frame p99 `<= 25 ms`, 1% low `>= 55 FPS`, and consecutive
    frames over `33.3 ms <= 1`.
  - Capacity and lifecycle physics must meet p95/p99 `<= 6/8 ms`; lifecycle
    memory growth must be `< 8 MiB`; draw-call p95 must be `<= 200`; combat
    batches must be `<= 50`; world batches must be `<= 12`.
  - Record the worst-of-three result for every scenario/platform. If any
    attempt fails, preserve all raw evidence, stop release handoff, do not
    reduce workload or thresholds, and route a measured presentation-owner
    correction back through the pre-asset performance owner. The new plan stays
    active and cannot be claimed complete.

- [ ] **11.7 Land durable evidence and retire the plans.**
  - Append final commit, environment, clean state, exact commands, raw evidence
    paths, screenshots, metrics, and verdict to
    `.agents/semantic-v2-runtime-acceptance-evidence.md`.
  - Update `docs/product/vehicle_game_spec.md` and
    `docs/design/VISUAL_SYSTEM.md` only when final runtime behavior establishes
    a durable rule not already owned there. Do not copy transient inventory or
    progress into those authorities.
  - Edit root/local `AGENTS.md` only for genuinely durable operating guidance
    and only with explicit protected-document authority. Validate every related
    link after final renames.
  - After every final gate passes and document-deletion authority is confirmed,
    delete both
    `.agents/execplans/2026-08-02-visual-replacement-workbench-and-runtime-switch.md`
    and this completed plan according to `.agents/PLANS.md`. Commit durable
    evidence/spec changes and the two plan retirements as one coherent final
    documentation commit.

## Test Plan and Validation Cadence

| Gate | When | Required proof |
| --- | --- | --- |
| Control-plane preflight | once, Task 6.0 | transition-aware validator, corrected Phase 6 metadata, rebuilt inventory/index, discovery counts preserved |
| Unit preparation | every unit | exact target files and dimensions/pivots/animation metadata, contact sheet, actual-scale review, clean preparation commit |
| Unit application | every unit | exact approval, helper preview/apply, focused validation, production commit, ledger commit |
| Phase rendered gate | after each Phase 6-9 | native and built-Web representative capture, phase scenario where named, no console errors, phase validator sets |
| Final reconciliation | Phase 10 | 210/0/1 asset counts, 22 animations/101 frames, 32 keep/four retired, one owner and consumer per medium |
| Full release | Phase 11 | 58 validators, authority/workbench/import/export, KO/EN responsive and 200% capture, interaction smoke, native/Web performance, lifecycle soak |

Rules:

- Run the smallest named focused set while preparing and applying a unit. Do
  not defer broken asset identity, provider coverage, state mapping, collision
  alignment, or animation metadata to Phase 11.
- Run the complete `validate_*.gd` suite only once at the final gate unless a
  final-gate correction changes a covered input; then rerun the complete gate
  from the new clean commit.
- Rendered visual review is required because static structure checks cannot
  prove actual-scale readability, localization fit, state distinction, or
  visible/collision alignment.
- Phase 6-9 performance scenarios are rendered integration checks. Only the
  clean three-run native/Web matrix in Phase 11 is release-performance proof.

## Rollback and Safety

- Record the clean full HEAD before Task 6.0, every unit approval, every unit
  application, and every phase gate.
- Keep each unit's preparation, approval record, production switch, and ledger
  changes in scoped commits. Shared-boss mapping and its approved retirements
  form one atomic production-switch commit.
- Use the promotion helper without `-Apply` before every write. It may copy only
  approved bytes to exact targets and never grants deletion authority.
- If a pre-commit unit check fails, repair or remove only task-owned uncommitted
  changes. If a committed unit later fails integration, use a normal scoped
  corrective or revert commit; never hard reset or force checkout.
- Never stage, rewrite, delete, move, or absorb unrelated user work. Stop on an
  overlapping dirty path and request coordination.
- Resolve every destructive target to an absolute path beneath the intended
  repository subdirectory before deletion. Use only exact approved lists; no
  wildcard or inferred sidecar deletion.
- Tracked Git history is recovery for approved retired media. Record hashes,
  target/retire maps, approval, production commit, and ledger commit before
  closing a unit.
- `tools/export_web.ps1` normally regenerates `build/web`; this final build
  artifact regeneration is in scope. Do not delete ignored `.godot`, external
  caches, or unrelated runtime directories.

## Predetermined Contingencies and Change Control

| Condition | Required response |
| --- | --- |
| Workbench discovery counts differ before Task 6.0 | Stop, record the actual source/filesystem diff, and amend this contract before executing units; do not replay completed work |
| Exact promotion or retirement approval is absent | Leave only that unit `switch_ready`; perform no copy, runtime mapping, or deletion; continue only independent work whose prerequisites are met |
| Approved bytes, target map, runtime map, retire list, or baseline changes | Invalidate approval, return the unit to `switch_ready`, regenerate the exact report, and request new approval |
| A deliverable is a sheet/contact sheet | Reject it as a runtime deliverable; keep it under `previews` and generate every declared target as a separate PNG |
| A required state or animation frame is missing | Keep the unit `target_required`; do not partially promote |
| Promotion source/target escapes an allowed root | Abort before any write and correct the declaration/helper guard |
| Static or animated visual disagrees with collision, timing, or state | Keep simulation truth, reject the visual, and revise only the presentation target |
| Shared boss nodes lose module kind/index or core semantics | Reject the structural switch; preserve gameplay snapshots/text/targeting and correct presentation mapping only |
| A required deletion is not approved | Preserve the exact paths and stop only the affected cleanup/completion gate; never infer authority |
| Any supported locale/size/text scale clips | Reject the responsible unit or final gate and correct the existing presentation owner without deleting required information |
| A draw-call, batch, frame, physics, memory, or lifecycle threshold fails | Preserve evidence, stop release, and correct the measured presentation owner; do not lower workload, quality, or thresholds |
| A dependency, native extension, gameplay change, new art direction, or broad architecture change appears necessary | Stop and request explicit scope/change-control authority before implementation |
| An unrelated dirty change overlaps a target | Stop and request coordination; never overwrite or include it |

## Risks and Mitigations

- **Visual sameness under simplification:** require silhouette and grayscale
  comparisons at gameplay scale, not only isolated color sheets.
- **Image geometry drifting from gameplay truth:** compare pivots, rectangles,
  radii, damaging cores, telegraphs, and collision in rendered native/Web
  states while keeping simulation authoritative.
- **Approval/state drift across many units:** keep exact per-unit hashes,
  baselines, mappings, commits, and automatic invalidation; never treat a batch
  approval as a shared rollback boundary.
- **Workbench becoming a second archive:** baseline-promote completed work,
  delete duplicate TO-BE/contact sheets, retain only current AS-IS and the four
  validated absence ledgers, and put history in Git/evidence.
- **Boss visual consolidation erasing gameplay identity:** consolidate only
  presentation selection and preserve kind/index throughout gameplay,
  localization, objectives, exams, targeting, and resolution.
- **Late performance failure:** keep phase pressure captures as early signals,
  enforce existing draw/batch budgets throughout, and still require the final
  authoritative three-run matrix without waiver.

## Progress and Next Step

- [x] 2026-08-04: inspected active instructions, plan standard, document
  lifecycle rules, current specs, workbench source/generated inventory,
  production media, validators, current Git baseline, and the superseded plan.
- [x] 2026-08-04: extracted and corrected the remaining Phase 6-11 contract;
  froze the predecessor's execution while retaining completed Phase 0-5 history
  until its approved final deletion.
- [ ] Execution has not begun. The next executor starts with Execution
  Prerequisites and Task 6.0; no target image, runtime mapping, or production
  byte is changed by creation of this document.

## Completion and Stop Conditions

Complete only when all of the following are true:

- all 30 target units have passed exact approval, atomic application, phase
  rendering, and baseline promotion;
- workbench final mode proves 32 `keep_current`, four `retired`, zero
  transitional units, 210 gameplay PNGs, zero UI PNGs, one font, 22 animation
  identities, and 101 frames;
- all repository, authority, import, export, localization, accessibility,
  interaction, native/Web performance, and lifecycle gates pass at clean HEAD;
- durable evidence/spec changes are committed and both completed plans are
  removed under confirmed document-deletion authority.

Stop without claiming completion when an exact approval is missing for a
required unit/deletion, a contract count or ownership check conflicts with
current truth, a protected-document edit lacks authority, a required external
artifact is unavailable, or any final threshold fails after task-scoped
correction attempts. Preserve the exact state and evidence so execution can
resume from the named task rather than restarting the program.

## Open Questions

None. Approval messages and measured release outcomes are execution gates with
defined stop behavior, not unresolved design decisions.

## Decision Notes

- 2026-08-04: Phase 6-11 was extracted into this new sole executable plan because
  the original plan mixed completed history with stale remaining assumptions.
- 2026-08-04: the final gameplay PNG count is 210: discovery 215 plus three
  wear tiles, minus one unused passive glyph, minus ten legacy boss modules,
  plus three shared boss-node states.
- 2026-08-04: four retired records remain as validated negative-inventory
  ledgers; completed replacement units become `keep_current` rather than being
  removed.
- 2026-08-04: Seeker remains the always-equipped Secondary Weapon and reuses
  `hud/action_seeker`; the unconsumed `hud/upgrade_passive` file is an approved-
  deletion candidate, never a new runtime dependency.
- 2026-08-04: the release gate counts 58 `validate_*.gd` scripts dynamically;
  `profile_vehicle_pressure.gd` remains a separate diagnostic.
- 2026-08-04: the earlier permission to begin visual replacement did not waive
  the final native/Web absolute-performance gate.
