---
type: plan
status: active
owner: BK
created: 2026-08-02
last_reviewed: 2026-08-03
topic: Production-ready visual replacement workbench and runtime asset/UI switch
scope: Current AS-IS visual roots, one TO-BE workbench, deployable replacement units, runtime promotion, validation, and retirement
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

# Visual Replacement Workbench and Runtime Switch Plan

This plan turns the current restored review report into one current-only,
production-ready AS-IS/TO-BE workbench, consolidates visual files under one
production root, and applies approved replacements as atomic switch units.
The art direction is already fixed. Execution therefore starts from the
canonical visual contract and produces deployable files, not additional style
exploration or contact-sheet-only proposals.

## Purpose

- Create one production visual root containing every current gameplay image,
  UI image, UI Theme resource, font, manifest, and production visual README.
- Rename the broad visual authority so one clearly named document owns the art
  style, visual theme, UI state rules, accessibility rules, and rendering
  constraints.
- Replace the historical snapshot report with one improvement workbench that
  contains all replacement direction, optional previews, exact deployable
  files, approval hashes, generated inventory data, and the generated
  index.html.
- Make every TO-BE deliverable directly promotable to its declared production
  path. No extraction, cropping, slicing, repainting, or conversion from a
  review sheet is allowed at promotion time.
- Consolidate fixed player craft parts into one craft-body asset, replace ten
  boss-specific module assets with one shared three-state node family, and
  remove files that are staged, generated redundantly, or declared without a
  runtime consumer.
- Preserve gameplay, collision, navigation, authored encounter, localization,
  performance, and input contracts while replacing presentation.

The completion state is visual_replacement_program_complete: the production
pack is normalized, every declared production media file has a runtime owner,
the workbench shows only current truth and active replacement work, all
approved TO-BE units are applied and promoted to the new AS-IS baseline, and
the full native/Web release checks pass.

## Why / Context

The current visual files are split between art/gameplay/semantic-v2 and
art/ui/production, while two UI review sheets sit inside the runtime UI pack.
The current docs/design/visual-asset-inventory/index.html is not a live
replacement source: it restores a 2026-08-01 snapshot from Git commit 9b309ce,
adds a current overlay, and republishes historical review media. Its TO-BE
cells can contain contact sheets or review references that cannot be copied
directly into the game.

That arrangement creates four different meanings for an image:

1. currently drawn production media;
2. provider-reachable media that may have no consumer;
3. staged media that is not runtime-connected;
4. historical or preview media that is not a deployable result.

The new workbench removes that ambiguity. AS-IS means current runtime-connected
production truth. TO-BE means exact production-ready bytes mapped to exact
target paths. Preview media remains useful for comparison, but never counts as
a deliverable or approval.

## Pre-plan Evidence Already Verified

All evidence below was checked against clean HEAD
e5dfca3b904304613636b94bc007c4d9f0c741e1 on branch master on 2026-08-02.

| Source or command | Verified fact | Plan consequence |
| --- | --- | --- |
| Root AGENTS.md, .agents/AGENTS.md, and .agents/PLANS.md | Broad visual work requires an active ExecPlan, Godot 4.7, focused validators, Web export, durable-spec handoff, and plan deletion after completion | This document uses the required lifecycle and release gates |
| docs/product/vehicle_game_spec.md | Manual aim, movement, held primary fire, dash, secondaries, EMP, encounters, pickups, upgrades, bosses, wear tiles, collision, and release thresholds are current product truth | Visual work cannot alter these owners or values |
| docs/design/VISUAL_SYSTEM.md | Flat-color, role-readable, familiar general-SF is fixed; floor/wall topology is procedural; common boss-node states are required; sheets do not authorize runtime assets | No new art-direction branch is permitted |
| .agents/execplans/2026-08-02-pre-asset-code-stabilization.md | Runtime asset/UI switching is forbidden until that plan's Phases 1 through 6 and final regression are complete | Phase 0 is a hard execution interlock |
| Active pre-asset performance evidence | Capacity physics p95/p99 is 19.22 to 20.77 / 23.86 to 26.40 ms against a 6/8 ms gate; built-Web smoke also remains open | This plan cannot claim that the switch gate is currently open |
| git ls-files for PNG media | 350 tracked PNG files: 247 gameplay, 59 UI, and 44 inventory review images | The target organization must distinguish production from workbench media |
| Gameplay manifest and provider | 239 provider-indexed gameplay images plus 8 staged floor/wall files; 22 indexed effect atlases have no renderer consumer while 101 individual frames are consumed | Remove staged floor/wall files and atlas-only duplication |
| Gameplay manifest families | 3 player attachments, 19 ordinary enemies, 5 bosses, 10 boss modules, 4 secondaries, 9 projectiles, 7 states, 6 pickups, 18 world files, 21 HUD glyphs, 22 cues, and 22 animations | The workbench unit ledger must cover every declared production identity |
| UI manifest | 13 component families and 57 state files | UI replacement must be state-family atomic |
| Theme and UI consumers | 48 UI states are Theme-bound; three small-state files are directly consumed; modal compact, tab disabled, and toggle focus can be bound; pip_empty, warning, and selection_rail have no consumer | Bind three real states and retire three orphan states |
| vehicle_combat_renderer.gd and player validators | Hull, engine, and aim mount are three batches; engine is rigid; manual aim is independent; hull_visual_tier, engine_visual_count, and primary_visual_tier are not consumed by the renderer | Replace fixed authored parts with one body while preserving independent aim semantics |
| vehicle_run.gd terrain drawing | Wear Collapse Tiles are 240 by 160 world units and currently use fallback rectangles for intact, cracked, and collapsed | Add one exact three-state production family at 240 by 160 |
| UI visual spec versus product spec | The visual spec says wear tiles are absent, but the product spec and runtime now define four tiles per field | Correct the visual authority before creating world deliverables |
| Boss visual contract | Current provider has ten boss-specific module files, while the canonical visual acceptance requires zero boss-specific defensive device assets and one shared active/damaged/resolved node family | Replace ten files with three shared files and keep gameplay module kinds separate |
| Current inventory pipeline | restore_visual_asset_inventory.ps1 reads historical Git data, applies current-review-overrides.json, writes inventory.json, and embeds it in index.html | Replace the historical restore pipeline with a current-only deterministic builder |
| Current inventory validator | It passes with ledger=305, review_items=26, actions=7/11/8, and review_images=44 | Passing proves snapshot integrity, not production readiness |
| Current workbench footprint | 49 files, including 44 PNGs totaling 25,880,357 bytes; 36 historical review images, 6 evidence images, and 2 references | Remove historical media from the active workbench after explicit deletion approval |
| Focused Godot 4.7.1 validators | Player presentation, wear tiles, semantic provider, visual asset coverage, visual replacement coverage, and stage UI layout all pass at the baseline | Preserve these results and update their assertions with the new contracts |
| Godot 4.7 TabBar and TabContainer documentation | tab_disabled is a supported StyleBox theme property | Bind tab_option/disabled instead of retaining an orphan |
| Godot 4.7 CheckButton and Button documentation | CheckButton inherits Button; Button exposes a focus StyleBox | Bind toggle/focus as CheckButton/styles/focus |
| Godot 4.7 PanelContainer documentation | PanelContainer owns one panel StyleBox and supports Theme type variations | Add ModalSurfaceCompact and select it at the existing compact breakpoint |

Official engine references checked for the UI binding decisions:

- https://docs.godotengine.org/en/4.7/classes/class_tabbar.html
- https://docs.godotengine.org/en/4.7/classes/class_tabcontainer.html
- https://docs.godotengine.org/en/4.7/classes/class_checkbutton.html
- https://docs.godotengine.org/en/4.7/classes/class_button.html
- https://docs.godotengine.org/en/4.7/classes/class_panelcontainer.html

## Source Authority and Execution Interlock

Authority order:

1. Root AGENTS.md and the nearest local AGENTS.md govern execution.
2. docs/product/vehicle_game_spec.md governs gameplay and product behavior.
3. docs/design/VISUAL_SYSTEM.md governs visual behavior. Phase 1 renamed the
   former UI-only authority filename without changing its canonical scope.
4. Production manifests, providers, Theme bindings, and current consumers
   describe current runtime connectivity.
5. The replacement workbench records current replacement status; it never
   overrides the product or visual specification.
6. Acceptance evidence records what passed; it never grants approval.

Phase 0 must evaluate the active pre-asset plan before any implementation in
this plan:

- If the pre-asset plan has completed its actual performance, built-Web, and
  lifecycle criteria and has been retired according to .agents/PLANS.md,
  execution may continue.
- If BK has explicitly amended or waived that plan's asset/UI interlock, the
  amendment must be recorded in that plan or the applicable durable authority
  before execution may continue.
- Otherwise execution stops at Phase 0. No production path migration, TO-BE
  image creation, visual binding change, or runtime switch is allowed.
- The existence of this plan does not waive the interlock.

The interlock is an external state check, not an unresolved design decision.

## Domain Language Contract

| Term | Exact meaning |
| --- | --- |
| Production visual root | art/visuals/production after Phase 1 |
| Production media | A PNG or font inside the production visual root and declared by the applicable manifest or Theme contract |
| Runtime-connected | Declared by a production manifest or Theme and connected to at least one current provider, catalog, Theme property, or concrete consumer |
| Provider-reachable | Loadable through a provider; this alone does not prove that a gameplay or UI state consumes it |
| Staged media | Tracked in a production-looking folder but not runtime-connected; staged media is not AS-IS |
| AS-IS | The current runtime-connected production file set and its current metadata, bindings, and consumer contract |
| Switch unit | The smallest group that must be technically validated, approved, promoted, and rolled back together |
| State family | All visual states required by one UI component or stateful world/actor feature |
| Preview | Optional review-only media under previews; a preview may be a contact sheet and is never deployable |
| TO-BE deliverable | A production-ready file under to-be/assets whose mirrored suffix is its exact production target path |
| Switch-ready | Every required TO-BE deliverable exists, has valid metadata, and passes unit validation; no approval is implied |
| Approved for switch | BK approved the exact SHA-256 of every deliverable and the exact retirement list |
| Applied | Approved bytes and required runtime migration are present in production and all unit checks pass in one coherent commit |
| Baseline-promoted | Applied production bytes are now AS-IS; duplicate TO-BE bytes and transitional approval state have been removed from the active workbench |
| Retired | An approved obsolete file or unit has no manifest, provider, Theme, code, documentation, or generated-index reference |

The old keep, guide, missing, approved, hold, revise, unreviewed, candidate, and
historical snapshot labels are not part of the new workbench state machine.
Historical terms may appear only in Git history, not in active generated data
or UI filters.

## Locked Decisions

1. The visual direction is fixed. No style comparison phase, new theme branch,
   or unnamed visual alternative is part of execution.
2. The three final organization anchors are:
   - current runtime visuals: art/visuals/production;
   - sole visual style authority: docs/design/VISUAL_SYSTEM.md;
   - all replacement direction and media:
     docs/design/visual-replacement-workbench.
3. The production visual root uses responsibility-shaped gameplay and UI
   subfolders. It is one common root, not one flat directory.
4. AS-IS files are referenced directly from production and are never duplicated
   into the workbench.
5. Every deployable TO-BE file lives under
   docs/design/visual-replacement-workbench/to-be/assets followed by its full
   repository-relative production target path.
6. Preview sheets live only under previews/as-is or previews/to-be. No sheet,
   montage, annotated comparison, or multi-option image may appear under
   to-be/assets.
7. replacement-workbench.json is the only hand-authored replacement-status
   source. inventory.json and index.html are generated and never edited
   manually.
8. index.html remains self-contained and usable from a file URL. It does not
   fetch inventory.json.
9. A file appearing in TO-BE does not grant approval. Approval is bound to exact
   hashes and an exact retirement list.
10. The player uses one authored craft-body asset containing the hull, fixed
    engine housing, and fixed weapon housing. The standalone hull, engine, and
    aim-mount production files and batches are retired together.
11. Manual aim remains independent in gameplay. It is communicated by the
    cursor, muzzle origin/flash, projectile direction, and attack feedback
    rather than a separately authored aim-mount texture.
12. Dash flare and directional afterimage remain transient effects because
    their lifetime and transform differ from the fixed craft body.
13. Boss gameplay module kind, index, objective text, and state remain intact,
    but presentation maps every kind to one shared active, damaged, or resolved
    node asset.
14. Procedural floor, void, structural wall, cover geometry, and deterministic
    surface compilation remain runtime truth. The eight unused floor/wall PNGs
    are retired; no new raster floor/wall system is introduced.
15. Wear Collapse Tiles receive three exact 240 by 160 state textures because
    they are current product features and currently have only fallback drawing.
16. Effect animation frames are the production contract. The 22 unused atlas
    files and atlas/grid/gutter manifest fields are retired.
17. Every declared UI state must have a Theme or code consumer. Modal compact,
    tab disabled, and toggle focus are bound. small_state/pip_empty,
    small_state/warning, and small_state/selection_rail are retired.
18. Each UI component's entire state family is one switch unit. Individual
    normal, hover, pressed, focus, selected, disabled, or semantic meter states
    are never approved or promoted alone.
19. NotoSansKR-Variable.ttf and its license remain the production font contract.
    Font replacement is outside this plan.
20. User-facing game text remains localized through controls and translation
    resources. No deployable raster contains Korean or English text.
21. Collision geometry, damage footprints, radii, timing, behavior, navigation,
    map topology, encounter counts, input, and save state never move into visual
    assets or the workbench.
22. Each implementation phase ends at a clean committed boundary after its
    acceptance checks pass. Each production switch is one task-owned atomic
    unit commit, with the narrow approval and ledger bookends defined by the
    source protocol. Unrelated user changes are never staged, reverted, or
    cleaned.

## Rejected Alternatives

| Alternative | Reason it is rejected |
| --- | --- |
| Keep the Git-restored snapshot report | It cannot describe the current repository without historical reconstruction and carries obsolete decisions |
| Copy AS-IS media into the workbench | It creates competing current truths and unnecessary binary duplication |
| Store deliverables in separate replacement roots under art | It splits improvement content across folders and risks Godot importing unapproved files |
| Treat a contact sheet as TO-BE | It requires a later extraction decision and is not directly promotable |
| Keep all player parts as independent authored textures | The engine and weapon housing are fixed presentation parts and the prior plan explicitly defers their consolidation to this switch |
| Merge manual-aim semantics into hull direction | Movement and manual aim are independent gameplay truths |
| Convert procedural floor/wall rendering to raster tiles | It adds no required product behavior and creates topology/collision drift risk |
| Preserve orphan UI states for completeness | Declared but unconsumed states make the manifest misleading |
| Preserve effect atlases alongside individual frames | Runtime consumes frames only; duplicate atlases add dead production media |
| Flatten every production file into one directory | It removes useful gameplay/UI ownership boundaries |
| Let the browser edit production state directly | A file-URL report cannot safely mutate repository or runtime state |

## Scope

### In scope

- Production visual path normalization.
- The visual-system document rename and correction of stale visual contracts.
- Gameplay and UI manifests, providers, catalogs, renderer bindings, Theme
  bindings, validators, and generated visual inventory.
- Workbench schema, deterministic builder, deterministic validator, safe
  promotion helper, generated inventory.json, generated index.html, and
  bilingual workbench interface.
- Removal of historical review media after explicit deletion approval.
- Removal of staged world PNGs, unused effect atlases, orphan UI states,
  standalone player parts, and boss-specific module visuals.
- Production-ready TO-BE generation and application for player, UI, HUD,
  world, rewards, enemies, projectiles, bosses, states, cues, and effects.
- Native and built-Web rendered evidence at supported sizes, input methods,
  languages, UI states, gameplay states, and performance pressure.
- Durable specification updates, acceptance-evidence append, and final
  ExecPlan retirement.

### Non-scope

- A new art direction, palette, named material theme, cultural theme, marine
  theme, ritual theme, or content setting.
- New gameplay systems, enemy roles, boss patterns, maps, procedural map
  generation, encounter counts, upgrade behavior, or controls.
- Collision, navigation, damage, timing, threat, persistence, save schema, or
  localization-copy redesign.
- A new engine, external production dependency, native extension, or build
  pipeline.
- Performance workload reduction or threshold relaxation.
- Font replacement.
- Audio work.
- Cleanup of ignored .codex-runtime or build media. Those paths are owned by
  separate runtime and build workflows and require separate owner-aware
  cleanup.

## Target Repository Structure

~~~text
art/
  audio/
  visuals/
    production/
      README.md
      gameplay/
        asset-manifest.json
        actors/
        effects/
        hud/
        pickups/
        states/
        weapons/
        world/
      ui/
        ui-asset-manifest.json
        vehicle_stage_theme.tres
        fonts/
        controls/
        glyphs/
        surfaces/

docs/
  design/
    VISUAL_SYSTEM.md
    visual-replacement-workbench/
      README.md
      replacement-workbench.json
      index-template.html
      inventory.json
      index.html
      previews/
        as-is/
          runtime/
          ui/
        to-be/
          <switch-unit-id>/
      to-be/
        assets/
          art/
            visuals/
              production/
                gameplay/
                ui/

tools/
  design/
    build_visual_replacement_workbench.ps1
    promote_visual_replacement_unit.ps1
    visual_replacement_workbench_model.psm1
  validation/
    validate_visual_replacement_workbench.ps1
~~~

No other active folder may own TO-BE direction, TO-BE media, or replacement
approval state. Production assets remain under art/visuals/production only.

## Proposed Design

### Current and target data flow

~~~text
docs/product/vehicle_game_spec.md
                 |
docs/design/VISUAL_SYSTEM.md
                 |
                 v
replacement-workbench.json ---- previews/as-is and previews/to-be
          |                      to-be/assets/<exact target path>
          |
          +---- current production manifests, Theme, providers, consumers
                         |
                         v
build_visual_replacement_workbench.ps1
              |                    |
              v                    v
       inventory.json       self-contained index.html
                                      |
                         BK approves exact unit hashes
                                      |
                                      v
                    promote_visual_replacement_unit.ps1
                                      |
                  exact production paths plus required code migration
                                      |
                         validators, import, Web export,
                         rendered native/Web evidence
                                      |
                                      v
                      applied commit -> AS-IS baseline promotion
~~~

### Workbench source schema

replacement-workbench.json uses schema version 1 and this exact top-level
shape:

~~~json
{
  "schema_version": 1,
  "production_root": "art/visuals/production",
  "style_authority": "docs/design/VISUAL_SYSTEM.md",
  "categories": [],
  "units": []
}
~~~

Each category contains:

| Field | Contract |
| --- | --- |
| id | Stable lowercase snake_case identifier |
| order | Unique integer display order |
| title_en | English label |
| title_ko | Korean label |

Each unit contains:

| Field | Contract |
| --- | --- |
| id | Stable lowercase snake_case identifier |
| category_id | Existing category identifier |
| order | Unique order within the category |
| title_en and title_ko | Bilingual display labels |
| owner | One of gameplay_manifest, ui_manifest, ui_theme, procedural_presentation, or composite |
| switch_kind | replace, add, consolidate, or retire |
| status | keep_current, target_required, switch_ready, approved_for_switch, applied, or retired |
| current_paths | Current production paths; empty only for add |
| consumer_paths | Exact code, Theme, manifest, or catalog owner paths |
| consumer_asset_ids | Exact provider IDs or Theme properties used by the unit |
| direction_en | A concise unit-specific delta that references, but does not restate, the visual authority |
| deliverables | Exact target metadata records |
| preview_paths | Optional review media under previews only |
| retire_paths | Exact files approved for removal by the same structural switch commit after promotion and zero-reference validation |
| runtime_change_paths | Exact non-media files that must change with a structural switch |
| acceptance_commands | Focused validator commands for this unit |
| approval | Null before approval; exact hash-bound record afterward |
| application | Null before application; commit-bound record afterward |

Each deliverable record contains:

| Field | Contract |
| --- | --- |
| target_path | Exact repository-relative production path |
| width and height | Exact source-pixel dimensions |
| pivot | Exact pixel pivot for world assets, omitted for UI StyleBox media |
| patch_margin | Exact UI patch margin when applicable |
| safe_inset | Exact left, top, right, bottom content inset when applicable |
| frame_count, fps, loop, blend | Required together for animation units |

replacement-workbench.json does not store a computed hash inside a deliverable
record. The builder never mutates this hand-authored source. Its derived
inventory.json projection adds observed_sha256 to each deliverable when a valid
TO-BE file exists and uses null otherwise. After BK approves exact bytes, the
executor copies the builder-emitted approval fragment verbatim into approval;
that immutable record is the only source-held deliverable hash map.

The builder derives a deliverable's workbench path by prefixing target_path
with:

docs/design/visual-replacement-workbench/to-be/assets/

The JSON does not store a second independently editable workbench path.

Approval has this exact shape:

~~~json
{
  "approved_by": "BK",
  "approved_at": "ISO-8601 timestamp with +09:00 offset",
  "baseline_commit": "40-character Git commit",
  "deliverable_sha256": {
    "exact/target/path": "64-character lowercase SHA-256"
  },
  "retire_paths": []
}
~~~

Application has this exact shape:

~~~json
{
  "commit": "40-character Git commit",
  "applied_at": "ISO-8601 timestamp with +09:00 offset",
  "validation_evidence": []
}
~~~

Approval and application use this exact commit protocol so no future executor
must invent a self-referential Git workflow:

1. For replace, add, and consolidate units, commit the complete TO-BE unit,
   required previews, switch_ready source state, and passing generated outputs;
   require a clean HEAD. For a retire-only unit, record the clean full HEAD,
   then prepare only its declared runtime_change_paths in a task-owned worktree.
   Set switch_ready only after that prepared worktree proves zero live
   references outside replacement-workbench.json and the files being retired.
   Do not delete or commit yet.
2. Re-run the builder and validator from that controlled state and show BK the
   exact unit ID, observed hash map, target map, retire_paths, and runtime-change
   diff. Retire-only deliverable_sha256 is an empty object.
3. Only after BK explicitly approves that exact display, copy the observed map
   and retire_paths verbatim into approval, record the clean pre-unit full HEAD
   as baseline_commit, record the +09:00 approval time, and set
   approved_for_switch. For replace, add, and consolidate, rebuild, validate,
   and make a clean approval-record commit. For retire-only, retain the approval
   record in the exact task-owned structural worktree; this approval is the
   destructive authority for the exact displayed set.
4. Start or continue the structural switch from that approved state. Copy all
   approved bytes, apply all runtime_change_paths, remove only approved
   retire_paths, run the unit acceptance commands, and create one coherent
   production switch commit. Leave source status approved_for_switch and
   application null in that commit because a Git commit cannot contain its own
   final hash.
5. Immediately create a ledger-only follow-up commit that sets status to applied
   for replacement units or retired for retire-only units, records the full
   production switch commit in application.commit, records the +09:00 time and
   validation evidence, rebuilds generated outputs, and passes -Check. Do not
   hand off between the production switch and this ledger commit.
6. After the ledger commit and applicable rendered/integration checks pass, the
   unit checklist baseline-promotes the applied unit with the atomic cleanup
   defined below. Phase 10 is the mandatory reconciliation backstop for any
   unit deliberately held in applied state for cross-unit integration and
   removes retired records. The production switch commit remains recoverable in
   Git after transitional source fields are cleared.

Approval-record and ledger-only commits are narrow workflow bookends. The
production media, runtime migration, and retirements themselves remain atomic in
one unit switch commit.

The builder rejects unknown fields so spelling mistakes cannot silently become
new workflow states.

### Legal state transitions

~~~text
keep_current
  -> target_required

target_required
  -> switch_ready

switch_ready
  -> target_required          when deliverables are rejected or revised
  -> approved_for_switch      when BK approves exact hashes and retire paths

approved_for_switch
  -> switch_ready             automatically when any approved byte or mapping changes
  -> applied                  after promotion, migration, validation, and commit
  -> retired                  for an approved retire-only unit after zero-reference validation

applied
  -> keep_current             after production becomes the new AS-IS baseline

retired
  -> removed from the active source after the generated ledger proves zero references
~~~

The target_required to switch_ready transition has two exhaustive acceptance
paths:

- replace, add, or consolidate: every declared deliverable exists, all observed
  hashes are non-null, metadata and rendered acceptance pass, and approval and
  application remain null;
- retire: deliverables is empty, current_paths is the non-empty production-media
  subset of retire_paths, retire_paths contains exactly those media files plus
  any paired tracked .import sidecars, only the declared runtime_change_paths
  are modified in the task-owned worktree, those prepared changes remove every
  live reference outside replacement-workbench.json and the retirement files,
  the zero-reference validator passes, and approval and application remain
  null.

For a retire unit, approved_for_switch to retired occurs only in the approved
structural switch commit that applies runtime_change_paths and deletes the exact
retire_paths. The copy helper performs no deletion. Any change to a deliverable
byte, target metadata, current path, consumer mapping, runtime-change path,
retire path, or acceptance command invalidates approval and returns the unit to
switch_ready.

Baseline promotion from applied to keep_current is one atomic source cleanup:
set current_paths to the applied production targets, refresh consumer mappings,
empty deliverables, retire_paths, runtime_change_paths, and preview_paths,
clear approval and application to null, remove duplicate TO-BE bytes, and set
direction_en to "No replacement is currently approved." Retain only the stable
unit identity, category, order, title, owner, current production paths, and
current consumer contract. A keep_current record may not retain transitional
hashes, approval data, application data, or completed previews.

Preview presence is independent of status. No preview-related transition
exists. The following transitions are invalid:

- keep_current directly to approved_for_switch or applied;
- target_required directly to approved_for_switch or applied;
- preview creation directly to approval;
- approved_for_switch to applied after any hash change;
- retired while any reference remains.

### Deterministic builder

build_visual_replacement_workbench.ps1 must:

1. Read only current repository files, never Git blobs from a historical
   commit.
2. Read replacement-workbench.json, both production manifests, the production
   Theme, declared consumer files, declared preview files, declared TO-BE files,
   and index-template.html.
3. Enumerate production PNG and font media deterministically.
4. Normalize every path to a forward-slash repository-relative path.
5. Reject paths outside the repository and paths containing parent traversal.
6. Derive file size, dimensions, observed_sha256, manifest identity, provider
   identity, Theme property, and declared consumer data from current files.
7. Require every production media file to belong to exactly one switch unit.
8. Require every current path, existing preview path, retire path, consumer
   path, and runtime-change path to resolve to one existing repository entry.
   Require every target path to be a unique normalized path under the production
   root and derive its unique TO-BE path. A missing TO-BE file is legal only in
   keep_current or target_required; switch_ready and later states require it.
9. Require every production media file not listed in retire_paths to have at
   least one consumer. A media file may have no consumer only when it is named
   by an explicit retire path and its unit follows the retire or structural
   retirement acceptance path.
10. Require TO-BE files to match declared format, dimensions, alpha mode, pivot,
    UI margins, and animation metadata.
11. For a retire unit, require deliverables to be empty, require current_paths
    to equal the non-sidecar production-media subset of retire_paths, allow only
    the exact paired tracked .import sidecars as additional retire paths, and
    require a generated zero-live-reference result before allowing switch_ready.
12. Reject a TO-BE image whose path or decoded dimensions indicate that it is a
    sheet, montage, or multi-option board.
13. Order output by category order, unit order, and normalized target path.
14. Write UTF-8 without BOM and normalized LF line endings.
15. Serialize one canonical compact JSON representation.
16. Write the canonical representation to inventory.json.
17. Escape ampersand, less-than, and greater-than characters before embedding
    that representation into the sole __INVENTORY_JSON__ placeholder in
    index-template.html.
18. Write the final self-contained index.html.
19. Support -Check, which compares expected bytes with inventory.json and
    index.html without changing files.
20. Fail if index-template.html contains zero or more than one placeholder.
21. Fail if the new production root, active replacement-workbench source,
    workbench tooling,
    or generated string refers to 9b309ce, semantic-v3-approval,
    current-review-overrides, review-images, or Git restoration. Append-only
    historical evidence and this active plan may preserve factual old paths
    until final plan retirement; they are not builder inputs and never satisfy
    active-workbench validation.

### Promotion helper

promote_visual_replacement_unit.ps1 must:

1. Require -UnitId and default to a non-mutating preview.
2. Require an explicit -Apply switch before copying bytes.
3. Run the workbench validator before any write.
4. Require status approved_for_switch.
5. Require a clean, committed baseline or a task-owned structural migration
   worktree whose paths exactly equal runtime_change_paths.
6. Recompute every deliverable hash and compare it with approval.
7. Refuse any source outside the workbench TO-BE asset root.
8. Refuse any target outside art/visuals/production.
9. Print the exact source-to-target map and exact retire list.
10. Copy bytes only; never resize, crop, recolor, compress, slice, or generate.
11. Never delete retire_paths automatically; a retire-only unit uses the helper
    for non-mutating validation and exact-list preview only.
12. Never edit status, manifests, Theme resources, code, or approval data.
13. Leave retirement and structural migration to the phase checklist so they
    land in the same reviewed commit.

### Generated index interface

index.html must expose:

- a current production summary derived from disk and manifests, with the final
  normalized target shown as 211 gameplay PNGs, 54 UI PNGs, and one font;
- counts for each actual status: keep_current, target_required, switch_ready,
  approved_for_switch, applied, and retired;
- a separate retire-only count and filter derived from switch_kind=retire, never
  from an invented display status;
- domain, category, status, switch-kind, and text filters;
- an AS-IS column that displays exact current production files and metadata;
- a TO-BE Deliverables column that displays every exact deployable file and
  target path;
- a separate Preview panel that is visibly labeled review-only;
- exact consumer paths, asset IDs, runtime-change paths, and retire paths;
- dimensions, pivot or UI inset metadata, bytes, and SHA-256;
- an approval block showing whether hashes match current bytes;
- a generated command block for validating and previewing promotion;
- bilingual Korean and English interface strings, defaulting to Korean;
- file-URL operation without fetch;
- lazy image loading, full-size dialog, keyboard tabs, visible focus, Escape
  close, descriptive alternative text, and no hover-only information;
- responsive layouts at 960 by 540, 1280 by 720, and 1920 by 1080 with no
  overflow, clipping, or overlap;
- restrained motion and full reduced-motion behavior.

The browser is read-only. It does not export patches and cannot change
repository files, approval, or runtime state.

## Production Contract After Structural Normalization

### Gameplay media count

The final provider-indexed gameplay media count is exactly 211:

| Category | Count | Contract |
| --- | ---: | --- |
| Player craft attachment | 1 | One craft body; no engine or aim-mount attachment |
| Ordinary enemies | 19 | Current role roster unchanged |
| Boss bodies | 5 | Current boss identities unchanged |
| Shared boss-node states | 3 | active, damaged, resolved |
| Secondaries | 4 | seeker, escort drone, orbit blade, wake mine |
| Projectiles | 9 | Three player and six hostile projectiles |
| State assets | 7 | Player defense, enemy defense, and status states |
| Pickups | 6 | Three experience sizes, crate, repair, recall |
| World assets | 13 | Existing ten connected world files plus three wear states |
| HUD assets | 21 | Current markers, actions, and upgrade families |
| Combat cues | 22 | Current semantic cue identities |
| Effect frames | 101 | Twenty-two non-looping animation families, frames only |
| Total | 211 | Exact provider count |

The count is derived from the current 239 provider entries as follows:

~~~text
239
- 22 unused effect atlases
- 10 boss-specific module files
+  3 shared boss-node state files
-  3 player attachment files
+  1 player craft-body file
+  3 wear-tile state files
= 211
~~~

The eight staged floor/wall files were never part of the 239 provider count and
are removed separately.

### UI media count

The final UI manifest count is exactly 54:

| Component | State count | Atomic state set |
| --- | ---: | --- |
| modal_master | 2 | normal, compact_safe |
| content_plate | 3 | normal, inset, summary |
| hud_plate | 5 | health_resource, objective_boss, minimap_target, action_rail, toast |
| upgrade_card | 6 | normal, hover, pressed, focus, selected, disabled |
| button_primary | 5 | normal, hover, pressed, focus, disabled |
| button_secondary | 5 | normal, hover, pressed, focus, disabled |
| button_danger | 5 | normal, hover, pressed, focus, disabled |
| tab_option | 5 | normal, hover, selected, focus, disabled |
| toggle | 3 | off, on, focus |
| slider | 3 | lane, fill, grabber |
| meter | 6 | background, health, boss, resource, cooldown, support |
| preview | 3 | normal, locked, focused |
| small_state | 3 | pip_available, pip_filled, disabled |
| Total | 54 | Every state has a Theme or concrete code consumer |

### Fixed output metadata

- Global gameplay format: PNG, sRGB, straight RGBA, authored facing +X/right,
  no trimming, linear filtering, no mipmaps, no repeat, authored near-black
  contour, and collision independent from visual alpha.
- Player craft body:
  - path:
    art/visuals/production/gameplay/actors/player/actor_player_craft_body.png;
  - canvas: 160 by 128;
  - pivot: 88,64;
  - rotation driver: hull;
  - one renderer batch and one instance;
  - manual aim uses aim_direction for cursor, muzzle, and projectile cues;
  - dash effect remains separate.
- Wear tile states:
  - paths ending wear_tile_intact.png, wear_tile_cracked.png, and
    wear_tile_collapsed.png under gameplay/world;
  - canvas: 240 by 160;
  - pivot: 120,80;
  - rendered to the exact TerrainRuntime rectangle;
  - no collision or wear-state ownership in the image.
- Shared boss node:
  - paths ending boss_node_active.png, boss_node_damaged.png, and
    boss_node_resolved.png under gameplay/actors/bosses/shared;
  - canvas: 160 by 160;
  - pivot: 80,80;
  - locked maps to active geometry with the existing locked tint and
    cue/commit_locked overlay;
  - active with health/max_health greater than 0.50 maps to active;
  - active with health/max_health greater than 0.0 and at most 0.50 maps to
    damaged;
  - resolved, disabled compatibility input, zero-health input, and every entry
    in resolved_boss_modules map to resolved;
  - sealed, open, and stable are boss-core states and continue to use the
    existing boss-core cue family, never the shared module node;
  - an unknown module state fails validation instead of silently selecting art.
  - an active module with max_health at or below zero fails validation before a
    ratio is calculated.
- UI dimensions, patch margins, and safe insets remain exactly equal to the
  current UI manifest values recorded in the UI state table and are checked
  per component before approval.
- Animation frame count, frame size, pivot, fps, loop, blend, event mapping,
  and duration remain exactly equal to the current manifest unless the visual
  specification already states a stricter value. Every animation remains
  non-looping.

## Asset Production Protocol

Apply this protocol to every target_required unit:

1. Use docs/design/VISUAL_SYSTEM.md, the unit's direction_en, its exact AS-IS
   production files, and its runtime-scale captures as the complete visual
   brief.
2. Do not perform external style discovery or introduce a second reference
   direction.
3. When AI-created or AI-edited bitmap work is used, load and follow the
   imagegen skill before creating or editing any image. Do not use Python as an
   image editor.
4. Create one transparent production image per deliverable target. Never ask
   for a sheet as the primary output.
5. Preserve exact canvas, pivot, facing, patch margins, safe insets, and
   animation metadata from the unit contract.
6. Use the fixed role palette, large-plane limits, contour rules, sparse-detail
   limits, and prohibited-theme rules from the visual authority.
7. Keep gameplay text out of every raster.
8. For a state family, derive every state from one locked base geometry so
   normal, hover, focus, disabled, active, damaged, resolved, intact, cracked,
   or collapsed states do not drift into different component shapes.
9. For an animation family, create all numbered frames together and inspect
   direction, silhouette continuity, alpha continuity, pivot stability, and
   non-looping end state.
10. Inspect every deliverable at source scale, runtime scale, grayscale, and
    over representative bright/dark gameplay backgrounds.
11. Generate any contact sheet only from the already existing exact
    deliverables and save it under previews/to-be. A preview is derived
    evidence, never the source from which production files are cut.
12. Run unit metadata and rendered validation before computing final hashes.
13. Treat any post-validation pixel change as a new deliverable revision and
    recompute its hash.

## Switch Unit Matrix

The hand-authored source explicitly lists these units. Manifest IDs shown in
parentheses are included in the same approval and promotion boundary.

### Player-controlled visual packages

| Unit | Included production identities | Structural action |
| --- | --- | --- |
| player_craft | New attachment/player_craft_body and hud/minimap_marker_player | Consolidate three player attachments into one body; retain marker as a separate scale-specific file inside the same approval unit |
| primary_weapon | projectile/player_primary, projectile/player_opening_breach, hud/action_primary, animation/muzzle_player_primary | Keep collision and held-fire cadence external |
| dash | hud/action_dash and animation/dash_start | Preserve 0.20-second directional feedback and reduced-motion variant |
| emp | hud/action_emp and animation/emp_release | Preserve gameplay radius and timing |
| barrier | state/player_barrier_plate, hud/action_barrier, animation/barrier_contact | Preserve segmented plate placement and barrier gameplay |
| ion_field | state/player_ion_emitter and hud/action_ion_field | Preserve exact effect radius and procedural field boundary |
| seeker | secondary/seeker, projectile/player_seeker, hud/action_seeker, animation/seeker_impact | Switch body, projectile, icon, and impact together |
| orbit_blades | secondary/orbit_blade and animation/orbit_blade_impact | Preserve outward facing and orbit behavior |
| wake_mines | secondary/wake_mine and animation/wake_mine_detonation | Preserve rear placement and detonation timing |
| escort_drone | secondary/escort_drone and animation/escort_drone_impact | Preserve following and target-facing behavior |

### Actor, threat, and combat packages

| Unit | Included identities | Structural action |
| --- | --- | --- |
| ordinary_enemy_family | All 19 ordinary role images in manifest order | Replace as one role-readable family |
| hostile_projectile_family | hostile_kinetic, hostile_thermal, hostile_toxin, hostile_cryo, hostile_arc, hostile_hybrid | Preserve damaging core size and delivery/tier semantics |
| enemy_defense_states | enemy_generator_shield_source and enemy_shield_escort_plate | Preserve independent activation |
| persistent_status_states | burn, poison, chill | Preserve condition ownership and stack meaning |
| combat_cue_family | All 22 combat-cue IDs | Preserve semantic event ownership and priority |
| hostile_arrival | animation/hostile_summon_arrival | Preserve cue timing and off-screen behavior |
| enemy_destruction | animations/enemy_destroy_light and enemy_destroy_heavy | Preserve light/heavy mapping |
| generic_damage_feedback | animations/impact_damage, reflect_deflection, and hull_hit | Preserve event mapping and threat visibility |
| effect_atlas_retirement | All 22 effects/atlases PNGs and paired tracked import sidecars | Retire-only cleanup; the 101 numbered frames remain owned by their behavior packages |

### Boss packages

| Unit | Included identities | Structural action |
| --- | --- | --- |
| boss_body_family | boss/colossus, leviathan, titan, behemoth, crown | Replace five bodies as one proportion-consistent family |
| shared_boss_node | New boss_node/active, damaged, resolved plus animation/boss_module_disabled | Retire all ten boss_module identities and map gameplay state to three shared visuals |
| boss_hit_feedback | animation/boss_reduced_hit | Preserve sealed/open/reduced-damage semantics |

### World and reward packages

| Unit | Included identities | Structural action |
| --- | --- | --- |
| procedural_floor_and_walls | VehicleWorldMeshBuilder and VehicleFieldSurfacePatternCompiler | Keep current procedural presentation; retire eight staged raster files |
| wear_tile_family | New world/wear_tile_intact, cracked, collapsed | Replace fallback rectangles with exact state textures |
| breakable_bulkhead | world_bulkhead_intact, world_bulkhead_damaged, animation/bulkhead_destroy | Open state remains an intentional absence after destruction |
| support_facilities | facility_repair_pad, facility_repair_pad_core, facility_overdrive_lane, animation/support_heal | Preserve exact support radii |
| transit_facility | facility_transit_gate and animation/transit_shift | Preserve paired gate dwell/cooldown |
| arc_and_cover_world | facility_arc_surge_strip, terrain_solid_cover_block, terrain_breakable_cover_slab, terrain_hazard_power_relay | Preserve exact functional footprints and procedural structural owners |
| pickup_family | All six pickup images, animation/pickup_intake, crate_destroy | Preserve values, contact collection, and drop flows |
| lifesteal_feedback | animation/lifesteal_pulse | Preserve upgrade event ownership |

### HUD and UI packages

| Unit | Included identities | Atomic boundary |
| --- | --- | --- |
| minimap_nonplayer_markers | hostile, elite, boss, objective_active, objective_locked | All five marker states |
| upgrade_family_glyphs | primary, passive, secondary, defense, dash, skill, element, mobility | All eight canonical upgrade-family glyphs |
| status_orbit_support_glyph | support | The support glyph used by the timed status orbit; its other state uses the shared defense-family glyph |
| modal_master | normal, compact_safe | Both surfaces |
| content_plate | normal, inset, summary | All three surfaces |
| hud_plate | health_resource, objective_boss, minimap_target, action_rail, toast | All five HUD surfaces |
| upgrade_card | normal, hover, pressed, focus, selected, disabled | All six card states |
| button_primary | normal, hover, pressed, focus, disabled | All five states |
| button_secondary | normal, hover, pressed, focus, disabled | All five states |
| button_danger | normal, hover, pressed, focus, disabled | All five states |
| tab_option | normal, hover, selected, focus, disabled | All five states |
| toggle | off, on, focus | All three states |
| slider | lane, fill, grabber | All three parts |
| meter | background, health, boss, resource, cooldown, support | All six semantic states |
| preview | normal, locked, focused | All three states |
| small_state | pip_available, pip_filled, disabled | All three consumed states |
| orphan_ui_state_retirement | pip_empty, warning, selection_rail and paired tracked import sidecars | Retire-only cleanup after the final consumed states are bound |
| ui_font | NotoSansKR-Variable.ttf and license | keep_current only |

The source must list every exact path. The tables above define grouping and
ownership; they do not permit a path to remain implicit.

## Responsibility and File Ownership

| Responsibility | Owner after implementation | Must not absorb |
| --- | --- | --- |
| Gameplay/product behavior | docs/product/vehicle_game_spec.md and existing gameplay owners | Art direction or binary approval |
| Visual direction and state grammar | docs/design/VISUAL_SYSTEM.md | Current task status or per-file approval |
| Production gameplay media contract | gameplay manifest and semantic asset provider | Collision, behavior, or historical review data |
| Production UI media contract | UI manifest, vehicle_stage_theme.tres, and UI provider | Screen-specific business logic |
| Replacement status and target mappings | replacement-workbench.json | Canonical product or style policy |
| Derived current ledger and page | builder-generated inventory.json and index.html | Hand-authored decisions |
| Safe byte promotion | promote_visual_replacement_unit.ps1 | Image transformation, code migration, deletion, or approval |
| Runtime presentation | existing renderer, UI, world, and catalog owners | Replacement workflow state |
| Validation | focused GDScript and PowerShell validators | Product-direction decisions |
| Historical evidence | Git history and append-only acceptance evidence | Active workbench UI |

## Milestones and Checklist

### Phase 0 — Clear the existing asset/UI interlock

AS-IS: The pre-asset stabilization plan is active. Performance and built-Web
completion criteria remain open.

TO-BE: A durable authority record proves that the pre-asset plan completed or
that BK explicitly amended its switch interlock.

- [x] Read root AGENTS.md, .agents/AGENTS.md, .agents/PLANS.md, the complete
  pre-asset plan, the product spec, and the visual spec.
- [x] Run git status --short and stop if unrelated changes overlap any planned
  path.
- [x] Record the starting branch, full HEAD, timestamp, and clean/dirty state
  in this plan's Progress section.
- [x] Check whether the pre-asset plan's performance matrix, 600-second
  lifecycle, built-Web smoke, evidence append, durable-spec handoff, and plan
  retirement are complete.
- [x] If any item remains open and no explicit BK amendment exists, stop this
  plan without creating or moving assets.
- [x] If an amendment exists, quote its exact authority path and scope in this
  plan's Decision Notes.
- [x] Confirm that no dependency, native extension, workload reduction, or
  threshold relaxation is being inferred from the amendment.

Accept: The interlock is durably cleared and the starting worktree is safe.

Guard: Do not interpret a passing export, historical Web smoke, or this plan's
existence as clearance.

### Phase 1 — Establish the three canonical locations

AS-IS: Production visuals use two unrelated roots; the full visual authority
has a UI-only filename; improvement evidence uses a historical-inventory name.

TO-BE: Current production, visual authority, and replacement workbench each
have one purpose-revealing canonical location.

- [x] Use the doc-lifecycle workflow before changing agent-relevant Markdown.
- [x] Rename the former UI-only visual-authority filename to
  docs/design/VISUAL_SYSTEM.md.
- [x] Preserve its canonical visual decisions while replacing the stale
  Wear Collapse Tile exclusion with the current intact/cracked/collapsed
  visual contract.
- [x] Replace the separate player hull/engine/aim-mount visual contract with
  one craft-body asset plus independent cursor/muzzle/projectile aim cues and
  separate transient dash feedback.
- [x] Keep the familiar general-SF, flat-color, role-readable contract
  unchanged.
- [x] Update root AGENTS.md, the product spec, active docs, scripts, validators,
  and append-only evidence with the canonical VISUAL_SYSTEM.md path.
- [x] Create art/visuals/production with gameplay and UI subfolders.
- [x] Create docs/design/visual-replacement-workbench and the
  previews/as-is/ui destination before moving either production review sheet.
- [x] Move art/gameplay/semantic-v2 contents to
  art/visuals/production/gameplay with git-aware moves.
- [x] Move art/ui/production/semantic-v2 runtime contents to
  art/visuals/production/ui with git-aware moves, excluding the two sheets.
- [x] Move vehicle_stage_theme.tres and fonts under
  art/visuals/production/ui.
- [x] Move 01-ui-surface-components.png and 02-ui-control-states.png to
  docs/design/visual-replacement-workbench/previews/as-is/ui.
- [x] Move or rewrite the gameplay pack README as
  art/visuals/production/README.md. Keep only production ownership, format,
  import, and source-of-authority guidance; do not duplicate art direction.
- [x] Move every tracked .png.import sidecar whose PNG moves, preserving the
  exact relative suffix beside its source image.
- [x] Do not mass-delete or regenerate unrelated tracked import sidecars.
- [x] Update project.godot, providers, registries, Theme external resources,
  scripts, validators, export references, docs, and generated tooling to the
  new root.
- [x] Scan runtime code, production manifests, Theme resources, project.godot,
  export inputs, validators, canonical specs, and new workbench tooling and
  require zero live references to art/gameplay/semantic-v2 or
  art/ui/production. Phase 1 explicitly excludes the legacy
  docs/design/visual-asset-inventory generated snapshot and append-only
  historical evidence because Phase 2 owns their approved cleanup.
- [x] Run Godot import and inspect only task-owned import changes.

Accept: Every production gameplay/UI image, UI Theme, font, manifest, and
production visual README is under art/visuals/production; the sole visual
authority is VISUAL_SYSTEM.md; no old-root runtime reference remains.

Guard: Audio remains under art/audio. The common production root keeps
gameplay and UI subfolder ownership.

### Phase 2 — Remove non-current media and rebuild the workbench

AS-IS: The active report restores historical data and 44 review images; two UI
sheets are mixed into production; eight world files and 22 atlases do not
represent runtime draw truth.

TO-BE: The active workbench is current-only, deterministic, self-contained,
and contains only current AS-IS evidence plus active TO-BE work.

- [x] Complete the docs/design/visual-replacement-workbench shell created in
  Phase 1 with the exact target structure in this plan.
- [x] Create replacement-workbench.json with every current media path assigned
  exactly once and all initial statuses set to keep_current or target_required
  according to the switch matrix.
- [x] Create index-template.html by preserving the useful file-URL, filter,
  lazy-image, dialog, and keyboard behavior while replacing historical states
  with the locked state machine.
- [x] Create visual_replacement_workbench_model.psm1 for schema, path,
  deterministic ordering, hash, and validation primitives only.
- [x] Create build_visual_replacement_workbench.ps1 for repository IO,
  current-ledger assembly, canonical serialization, and generated output.
- [x] Create promote_visual_replacement_unit.ps1 with the narrow copy-only
  safety contract.
- [x] Create validate_visual_replacement_workbench.ps1.
- [x] Generate inventory.json and index.html.
- [x] Confirm index.html works directly from the filesystem with networking
  disabled.
- [x] Confirm AS-IS references production bytes directly.
- [x] Confirm previews are visibly separate and never satisfy deliverable
  validation.
- [x] Confirm each TO-BE deliverable displays its exact target path and hash.
- [x] Confirm Korean and English labels are complete.
- [x] Confirm keyboard navigation, focus, dialog close, search, filters, and
  responsive layout at 960 by 540, 1280 by 720, and 1920 by 1080.
- [x] Compare the new current ledger with both production manifests, Theme,
  providers, and concrete consumers.
- [x] Request one explicit deletion approval for these exact tracked legacy
  artifacts:
  - docs/design/visual-asset-inventory/review-images, 44 PNG files;
  - docs/design/visual-asset-inventory/current-review-overrides.json;
  - docs/design/visual-asset-inventory/report-template.html;
  - docs/design/visual-asset-inventory/inventory.json;
  - docs/design/visual-asset-inventory/index.html;
  - docs/design/visual-asset-inventory/README.md;
  - tools/design/restore_visual_asset_inventory.ps1;
  - tools/design/visual_asset_inventory_model.psm1;
  - tools/validation/validate_visual_asset_inventory.ps1.
- [x] Stop before deletion if approval is absent.
- [x] After approval and new-workbench parity, remove the exact legacy
  artifacts and the now-empty old workbench folder.
- [x] After that removal, run the repository-wide old-root scan and require zero
  references outside this active plan and append-only historical evidence.
- [x] Require zero live references in production, the new workbench, canonical
  docs, and workbench tooling to 9b309ce, semantic-v3-approval,
  current-review-overrides, review-images, or
  restore_visual_asset_inventory. This active plan and append-only historical
  evidence are excluded until Phase 11 retires the plan.

Accept: The generated current-only index is the sole active improvement
workbench; the old snapshot pipeline and review binaries are absent after
approval; -Check produces no diff.

Guard: Git history remains the recovery mechanism. Do not delete ignored
.codex-runtime or build media in this phase.

### Phase 3 — Normalize the current production contract

AS-IS: Production declares unused map rasters, effect atlases, and three UI
states without consumers; three valid UI states are not bound.

TO-BE: Every declared current file has a consumer, and generated review-only or
unused production media is absent.

- [x] Resolve and print this exact Phase 3 retirement set after the Phase 1
  move. Each PNG includes its tracked .png.import sidecar in the same approval:
  - art/visuals/production/gameplay/world/world_shared_floor_00.png;
  - art/visuals/production/gameplay/world/world_shared_floor_01.png;
  - art/visuals/production/gameplay/world/world_wall_straight.png;
  - art/visuals/production/gameplay/world/world_wall_convex_corner.png;
  - art/visuals/production/gameplay/world/world_wall_concave_corner.png;
  - art/visuals/production/gameplay/world/world_wall_end_cap.png;
  - art/visuals/production/gameplay/world/world_wall_t_junction.png;
  - art/visuals/production/gameplay/world/world_wall_cross_junction.png;
  - art/visuals/production/gameplay/effects/atlases/fx_muzzle_player_primary.png;
  - art/visuals/production/gameplay/effects/atlases/fx_dash_start.png;
  - art/visuals/production/gameplay/effects/atlases/fx_emp_release.png;
  - art/visuals/production/gameplay/effects/atlases/fx_wake_mine_detonation.png;
  - art/visuals/production/gameplay/effects/atlases/fx_boss_module_disabled.png;
  - art/visuals/production/gameplay/effects/atlases/fx_hostile_summon_arrival.png;
  - art/visuals/production/gameplay/effects/atlases/fx_bulkhead_destroy.png;
  - art/visuals/production/gameplay/effects/atlases/fx_reflect_deflection.png;
  - art/visuals/production/gameplay/effects/atlases/fx_barrier_contact.png;
  - art/visuals/production/gameplay/effects/atlases/fx_hull_hit.png;
  - art/visuals/production/gameplay/effects/atlases/fx_seeker_impact.png;
  - art/visuals/production/gameplay/effects/atlases/fx_escort_drone_impact.png;
  - art/visuals/production/gameplay/effects/atlases/fx_orbit_blade_impact.png;
  - art/visuals/production/gameplay/effects/atlases/fx_enemy_destroy_light.png;
  - art/visuals/production/gameplay/effects/atlases/fx_enemy_destroy_heavy.png;
  - art/visuals/production/gameplay/effects/atlases/fx_crate_destroy.png;
  - art/visuals/production/gameplay/effects/atlases/fx_pickup_intake.png;
  - art/visuals/production/gameplay/effects/atlases/fx_support_heal.png;
  - art/visuals/production/gameplay/effects/atlases/fx_lifesteal_pulse.png;
  - art/visuals/production/gameplay/effects/atlases/fx_transit_shift.png;
  - art/visuals/production/gameplay/effects/atlases/fx_boss_reduced_hit.png;
  - art/visuals/production/gameplay/effects/atlases/fx_impact_damage.png;
  - art/visuals/production/ui/glyphs/small_state_pip_empty.png;
  - art/visuals/production/ui/glyphs/small_state_warning.png;
  - art/visuals/production/ui/glyphs/small_state_selection_rail.png.
- [x] Assign the set to exactly three retire-only units:
  procedural_floor_and_walls owns the eight world PNGs,
  effect_atlas_retirement owns the 22 atlas PNGs, and
  orphan_ui_state_retirement owns the three UI PNGs. Include every paired
  tracked import sidecar in that unit's retire_paths.
- [x] In the task-owned structural worktree, remove the exact manifest entries
  for these eight staged world files but keep the PNGs and sidecars until the
  approval gate:
  - world_shared_floor_00.png;
  - world_shared_floor_01.png;
  - world_wall_straight.png;
  - world_wall_convex_corner.png;
  - world_wall_concave_corner.png;
  - world_wall_end_cap.png;
  - world_wall_t_junction.png;
  - world_wall_cross_junction.png.
- [x] Remove MAP_SURFACE_PREFIXES and any skip logic that existed only to hide
  those files from the semantic provider.
- [x] Keep all 22 effect atlas PNGs and sidecars in place while removing atlas,
  grid, and gutter from every animation manifest entry.
- [x] Remove effect_atlas indexing from the semantic provider.
- [x] Preserve all 101 numbered frames and their frame_count, frame_size,
  pivot, fps, loop, blend, note, and event mappings.
- [x] Add TabContainer/styles/tab_disabled and
  TabBar/styles/tab_disabled using tab_option/disabled.
- [x] Add CheckButton/styles/focus using toggle/focus.
- [x] Add ModalSurfaceCompact as a PanelContainer Theme variation using
  modal_master/compact_safe.
- [x] In VehicleModalHost._apply_viewport, derive the existing compact boolean
  once, apply it to content, and select ModalSurfaceCompact or ModalSurface
  from the same boolean.
- [x] Remove small_state/pip_empty, small_state/warning, and
  small_state/selection_rail from the UI manifest, but keep the three PNGs and
  sidecars in place until the approval gate.
- [x] Preserve small_state/pip_available, pip_filled, and disabled consumers.
- [x] Update the UI provider and replacement-coverage validator so all 54
  declared UI states have a Theme or concrete consumer.
- [x] Update gameplay coverage from 239 to 217 after atlas removal, before the
  player, boss-node, and wear structural units are applied.
- [x] With only the declared runtime_change_paths modified, run the workbench
  zero-reference validator and require no live reference to any of the 33 PNGs
  outside replacement-workbench.json and the files themselves.
- [x] Set all three retire-only units to switch_ready and display the exact
  runtime-change diff, 33 PNG paths, 33 sidecar paths, and empty deliverable
  hash maps.
- [x] Request BK's explicit approval to delete exactly that displayed set and
  record the same set in the three approval records.
- [x] Stop Phase 3 before any deletion or commit if approval is absent or
  narrower than the displayed set; retain the prepared task-owned worktree.
- [x] After exact approval, delete the 33 PNGs and 33 sidecars, run the focused
  acceptance commands, and create one atomic Phase 3 production switch commit.
- [x] Immediately create the ledger-only commit that records that production
  switch commit and marks all three units retired.
- [x] Rebuild the workbench and require no staged or orphan production row.

Accept: Gameplay provider count is 217 at this intermediate state; UI state
count is 54; every declared media file is runtime-connected; no atlas or staged
map raster remains.

Guard: Do not change animation timing, UI breakpoints, localization, map
presentation, or gameplay.

### Phase 4 — Complete the player vertical slice

AS-IS: Player hull, fixed engine, and aim mount are three authored files and
three renderer batches.

TO-BE: One craft body and one scale-specific player minimap marker form the
player_craft switch unit; manual aim and dash remain readable without fixed
attachment textures.

- [x] Set player_craft to target_required.
- [x] Place the exact 160 by 128 craft-body deliverable at the mirrored TO-BE
  path for actor_player_craft_body.png.
- [x] Place the exact current-size player minimap marker deliverable at its
  mirrored TO-BE target path.
- [x] Generate one AS-IS/TO-BE runtime comparison under previews/to-be/player_craft
  from exact runtime captures; do not use it as a deliverable.
- [x] Validate +X facing, 88,64 pivot, opaque bounds, contour, role color,
  grayscale direction readability, and eight hull directions.
- [x] Validate independent aim at eight aim directions for every fixed hull
  direction using cursor, muzzle, projectile, and hit feedback.
- [x] Validate idle, movement, dash, hit, reduced-motion dash, barrier, EMP,
  and secondary-equipped states.
- [x] Validate the 14-pixel gameplay minimap marker at eight directions.
- [x] Mark switch_ready only after both exact deliverables pass.
- [x] Obtain one hash-bound approval for both deliverables and the retirement
  of:
  - art/visuals/production/gameplay/actors/player/actor_player_hull_base.png and
    its tracked .png.import sidecar;
  - art/visuals/production/gameplay/actors/player/actor_player_engine.png and its
    tracked .png.import sidecar;
  - art/visuals/production/gameplay/actors/player/actor_player_aim_mount.png and
    its tracked .png.import sidecar.
- [x] Stop the structural switch before manifest edits, batch changes, or file
  deletion unless BK explicitly approves those exact deliverable hashes and
  six retirement paths.
- [x] Promote exact approved bytes.
- [x] Replace three manifest attachments with attachment/player_craft_body.
- [x] Replace three renderer batches with one craft-body batch.
- [x] Remove the fixed engine instance and fixed aim-mount instance.
- [x] Preserve a rear anchor calculation only where transient dash feedback
  needs it.
- [x] Remove unused hull_visual_tier, engine_visual_count, and
  primary_visual_tier presentation snapshot fields if no other consumer
  exists.
- [x] Update ActorCatalog, procedural fallback recipes, provider, renderer,
  guidebook preview, visual registry, and player validators.
- [x] Remove the three approved retired files after all references are gone.
- [x] Run the player through deployment, live combat, pause, guidebook, report,
  and stage transition in Korean and English.
- [x] Record the applied commit and rendered evidence, then baseline-promote
  the unit.

Accept: Exactly one player craft-body instance renders; zero fixed player
engine/aim-mount assets or batches remain; manual aim, rear-facing craft
readability, dash direction, collision independence, and all player flows pass.

Guard: Do not rotate the hull from aim input, change movement, change the
collision radius, or make dash flare part of the static body.

### Phase 5 — Replace the UI component system

AS-IS: Current UI states are technically connected after Phase 3 but retain the
old visual bytes.

TO-BE: Every component family has an approved, directly deployable, complete
state set using the fixed visual system.

Execute in this order:

1. modal_master, content_plate, and hud_plate;
2. upgrade_card;
3. button_primary, button_secondary, and button_danger;
4. tab_option and toggle;
5. slider and meter;
6. preview and small_state.

For each component unit:

- [ ] Set only that unit to target_required.
- [ ] Create every required state as an individual deployable PNG under the
  exact mirrored target path.
- [ ] Keep canvas, patch margin, and safe inset exactly equal to the manifest.
- [ ] Create one component contact sheet from exact deliverables only under
  previews/to-be/<switch-unit-id>.
- [ ] Compare every state listed for that component in the locked UI media
  count and Switch Unit Matrix.
- [ ] Check that focus is visible without hover and that disabled is distinct
  without relying only on color.
- [ ] Check text and icon safe areas with longest Korean and English strings.
- [ ] Check 960, 1280, and 1920 widths and compact modal height.
- [ ] Check no child crosses a StyleBox content inset.
- [ ] Check mouse, keyboard, and gamepad focus order and activation.
- [ ] Check grayscale distinction and contrast against the fixed palette.
- [ ] Mark switch_ready only when the whole state family passes.
- [ ] Obtain hash-bound approval for the entire family.
- [ ] Promote every approved state in one operation.
- [ ] Run Theme/provider checks, UI layout, UI localization, upgrade UI, pause,
  settings, guidebook, deployment, report, and HUD checks.
- [ ] Record one coherent applied commit and baseline-promote the family.

Accept: All 54 UI states remain declared and connected, all component families
pass full interaction/layout coverage, and no runtime UI loads preview media.

Guard: Do not bake text into images, remove focus states, change screen
behavior, or change localization keys.

### Phase 6 — Replace player-action, HUD, and secondary packages

AS-IS: Player-related static assets, icons, projectiles, and effects can be
reviewed in unrelated rows.

TO-BE: Each player-controlled behavior is one complete visual package with all
directly deployable outputs.

Execute in this order:

1. primary_weapon;
2. dash;
3. emp;
4. barrier;
5. ion_field;
6. seeker;
7. orbit_blades;
8. wake_mines;
9. escort_drone;
10. minimap_nonplayer_markers;
11. upgrade_family_glyphs;
12. status_orbit_support_glyph.

For each unit:

- [ ] Enumerate every included static file, animation frame, icon, target path,
  and consumer in replacement-workbench.json.
- [ ] Create all exact deliverables; never place an atlas or sheet under
  to-be/assets.
- [ ] Validate frame count, size, pivot, fps, non-looping behavior, event
  mapping, and total duration.
- [ ] Validate gameplay scale and grayscale at 960, 1280, and 1920 widths.
- [ ] Validate ordinary, elite, and boss pressure where the asset can appear.
- [ ] Validate reduced motion where a transient effect is involved.
- [ ] Validate high-count batching and zero per-object AnimatedSprite2D
  creation.
- [ ] Obtain one hash-bound approval for the complete package.
- [ ] Promote and run the package's focused gameplay, renderer, HUD, guidebook,
  and report validators.
- [ ] Capture at least one native and one built-Web rendered state for each
  player-controlled package.
- [ ] Commit and baseline-promote the package.

Accept: Every player-controlled package is coherent across world, HUD, and
effects; no preview or partial family is runtime-connected.

Guard: Preserve cadence, damage, radius, cooldown, target selection, secondary
movement, and input behavior.

### Phase 7 — Replace world, facility, and reward packages

AS-IS: Base world presentation is procedural; wear tiles use fallback
rectangles; connected facility and reward assets use current bytes.

TO-BE: Procedural base world remains authoritative, while every functional
world/reward asset and wear state has an approved direct deliverable.

- [ ] Keep procedural_floor_and_walls at keep_current and show its current
  runtime capture and code owners rather than inventing TO-BE files.
- [ ] Produce the three wear_tile_family deliverables at 240 by 160.
- [ ] Replace fallback rectangle/X drawing with the exact texture selected
  from TerrainRuntime state.
- [ ] Fit the texture to the exact snapshot rectangle without changing the
  rectangle or collision.
- [ ] Validate four tiles in each of the three fields, intact to cracked to
  collapsed, stage persistence, immediate damage, repeated damage, player,
  ordinary enemy, and boss crossing.
- [ ] Produce and apply breakable_bulkhead as one intact/damaged plus destroy
  effect package; validate open as intentional absence.
- [ ] Produce and apply support_facilities, transit_facility, and
  arc_and_cover_world in that order.
- [ ] Validate every rendered boundary against its gameplay rectangle or
  radius.
- [ ] Produce and apply pickup_family and lifesteal_feedback.
- [ ] Validate pickup values, contact collection, crate destruction, recall,
  repair, drop totals, and report/HUD use.
- [ ] Run deterministic world fingerprint and surface-pattern checks before
  and after each world unit.
- [ ] Capture all three fields in native and built Web at gameplay scale.
- [ ] Commit and baseline-promote each unit.

Accept: Wear states are immediately distinct; every functional world visual
matches gameplay truth; procedural floor/wall fingerprints and all map
topology remain unchanged.

Guard: Do not add named environmental themes, decorative hazards, topology,
collision, or random presentation inputs.

### Phase 8 — Replace ordinary enemies, hostile attacks, and combat cues

AS-IS: Nineteen enemy bodies, six hostile projectile affinities, enemy defense
states, three statuses, and cue/effect families use current visuals.

TO-BE: A complete role-readable enemy/threat family uses the fixed semantic
contract at production scale and pressure.

- [ ] Produce all 19 ordinary_enemy_family deliverables before marking the
  family switch_ready.
- [ ] Compare all role silhouettes at identical scale and in grayscale.
- [ ] Validate first-clear distinction for swarm, melee, ranged, command,
  stationary, shield, support, artillery, interceptor, rammer, guard, splitter,
  carrier, repair, beam, and pylon roles represented by the current roster.
- [ ] Validate base, elite, and collective overlays without changing the base
  asset roster.
- [ ] Produce all six hostile_projectile_family deliverables.
- [ ] Validate damaging core against collision radius, non-damaging direction
  tail, delivery, affinity, ordinary/elite/boss tier, and light/standard/heavy
  power.
- [ ] Produce enemy_defense_states and persistent_status_states.
- [ ] Produce all 22 combat_cue_family deliverables.
- [ ] Produce hostile_arrival, enemy_destruction, and
  generic_damage_feedback frame families.
- [ ] Validate off-screen warnings, target priority, collective states, elite
  traits, boss objective states, commit states, and guide categories.
- [ ] Run peak_horde and capacity_pressure rendered checks after application.
- [ ] Obtain hash-bound approval, promote, commit, and baseline-promote each
  complete family.

Accept: Every current role, threat tier, delivery, state, and cue is distinct
at gameplay scale under pressure; roster, AI, attacks, damage, and collision
are unchanged.

Guard: Do not create new enemy identities or use hue alone to distinguish
role, delivery, tier, or state.

### Phase 9 — Replace bosses and consolidate shared nodes

AS-IS: Five boss bodies and ten boss-specific module visuals are selected by
module kind and index.

TO-BE: Five coherent boss bodies use one shared active/damaged/resolved node
family while all gameplay module identities remain intact.

- [ ] Produce all five boss_body_family deliverables at 352 by 352 and pivot
  176,176.
- [ ] Validate large silhouette, four to six major planes, phase readability,
  guidebook preview, minimap, objective HUD, and report views.
- [ ] Produce shared_boss_node active, damaged, and resolved deliverables at
  160 by 160 and pivot 80,80.
- [ ] Implement the locked mapping: select the shared active node while
  preserving the existing locked tint and cue/commit_locked overlay.
- [ ] Implement the live-health mapping: active with health/max_health above
  0.50 selects active; active above zero and at or below 0.50 selects damaged.
- [ ] Fail validation when an active module has max_health at or below zero;
  evaluate terminal zero health before dividing.
- [ ] Implement the terminal mapping: resolved, disabled compatibility input,
  zero health, and every resolved_boss_modules snapshot select resolved.
- [ ] Reject an unknown module state in validation; do not add a silent visual
  fallback.
- [ ] Keep boss-core sealed, open, and stable on cue/boss_core_sealed,
  cue/boss_core_open, and cue/boss_core_stable respectively; these states never
  select a shared module node.
- [ ] Replace renderer kind/index asset selection with the shared state
  mapping.
- [ ] Preserve module kind/index in gameplay snapshots, objective text,
  localization, exam logic, targeting, and resolution.
- [ ] Update actor catalog, mesh fallback recipes, provider namespace,
  renderer, guidebook, visual registry, and validators.
- [ ] Print and request explicit BK retirement approval for these exact ten PNGs
  and their ten paired tracked .png.import sidecars:
  - art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_armor_car.png;
  - art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_crown_lattice.png;
  - art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_crown_pylon.png;
  - art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_forge_plate_active.png;
  - art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_forge_plate_disabled.png;
  - art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_relay_negative.png;
  - art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_relay_positive.png;
  - art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_route_switch.png;
  - art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_segment_lock_active.png;
  - art/visuals/production/gameplay/actors/bosses/modules/actor_boss_module_segment_lock_disabled.png.
- [ ] Stop before provider, renderer, or deletion changes if the exact boss-node
  hashes and exact retirement set are not approved.
- [ ] Retire those approved files and provider IDs only after zero-reference
  validation; include deletion and state mapping in the same structural switch
  commit.
- [ ] Apply animation/boss_module_disabled only with shared_boss_node approval;
  apply animation/boss_reduced_hit only with the separate boss_hit_feedback
  approval.
- [ ] Validate all five bosses, every exam/module state, sealed/open/stable
  core, reduced damage, module resolution, stage transition, guidebook, and
  report.
- [ ] Run boss_pressure native and built-Web rendered checks.
- [ ] Commit and baseline-promote boss_body_family and shared_boss_node
  separately so either can be rolled back without affecting the other.

Accept: Five boss bodies and exactly three shared node state assets render;
zero boss-specific defensive device assets or references remain; boss gameplay
is unchanged.

Guard: Do not merge gameplay modules, alter boss patterns, alter damage gates,
or use boss color alone as identity.

### Phase 10 — Reconcile counts, finish all remaining visual units, and clean the workbench

AS-IS: Applied units may still have transitional TO-BE copies and applied
records.

TO-BE: Production is the new AS-IS baseline; the active workbench contains only
future target_required or switch_ready work and no completed binary duplicate.

- [ ] Require every one of the 22 animation identities to be owned by exactly
  one applied or keep-current switch unit.
- [ ] Require exactly 101 production effect frames and zero effect atlases.
- [ ] Require exactly 211 provider-indexed gameplay PNGs.
- [ ] Require exactly 54 UI manifest PNGs.
- [ ] Require exactly one production font and its license.
- [ ] Require zero staged production media and zero declared media without a
  consumer.
- [ ] Require zero old player attachment, old boss-module, old workbench,
  historical snapshot, review-image, or old production-root references.
- [ ] For each applied unit, verify production hash equals the approved hash
  and application.commit exists in Git.
- [ ] Baseline-promote each verified applied unit atomically: set current_paths
  to the applied production targets; refresh consumer mappings; empty
  deliverables, retire_paths, runtime_change_paths, and preview_paths; clear
  approval and application to null; set direction_en to
  "No replacement is currently approved."; and transition to keep_current.
- [ ] In that same cleanup, remove duplicate workbench TO-BE bytes and every
  completed preview. If BK explicitly requires a comparison image for durable
  evidence, move it to the append-only acceptance-evidence location rather than
  retaining it in the active workbench.
- [ ] Reject any keep_current record that retains an approval hash, application
  record, TO-BE file, retire path, completed preview, or transitional mapping.
- [ ] Remove retired units from active replacement-workbench.json after the
  generated ledger proves zero references.
- [ ] Rebuild inventory.json and index.html.
- [ ] Confirm the workbench now displays production as AS-IS and only active
  future work as TO-BE.
- [ ] Run the codebase quality audit because providers, shared UI, manifests,
  validators, and generators changed across modules.
- [ ] Correct only small, safe, task-scoped findings.

Accept: Exact counts and zero-reference checks pass; production and workbench
have no duplicate current truth; the active index contains only current and
future-useful information.

Guard: Do not preserve completed rows or media merely as an archive. Git and
acceptance evidence own history.

### Phase 11 — Full release validation, durable handoff, and plan retirement

AS-IS: Focused unit checks and intermediate commits exist.

TO-BE: The complete production pack passes repository, native, built-Web,
accessibility, localization, performance, and lifecycle gates.

- [ ] Run all 58 current tools/validation/*.gd entry points from a clean
  committed HEAD. This baseline set includes the 56 validate_vehicle_*.gd
  scripts, validate_settings_store.gd, and diagnostic
  profile_vehicle_pressure.gd; the diagnostic output is not release performance
  evidence.
- [ ] Run document authority validation.
- [ ] Run the replacement workbench validator and builder -Check.
- [ ] Run Godot headless import.
- [ ] Run production Web export.
- [ ] Load the npjt-port-guard skill before starting the built Web app.
- [ ] Use the fastrun manager codex lane, not an ad hoc or user lane port.
- [ ] Perform built-Web smoke for movement, manual aim, held primary, dash,
  EMP, all secondary families, pickups, wear tiles, bulkheads, facilities,
  ordinary enemies, all bosses, pause, settings, guidebook, report, stage
  transition, victory, and defeat.
- [ ] Repeat the visual smoke in Korean and English at 960 by 540, 1280 by 720,
  and 1920 by 1080.
- [ ] Verify mouse, keyboard, gamepad focus, compact modal, reduced motion,
  grayscale, and no clipping/overflow.
- [ ] Run authoritative native and visible foreground Web performance for
  production_replay, peak_horde, capacity_pressure, and boss_pressure three
  times each using the product-spec thresholds.
- [ ] Run the 600-second native lifecycle_pressure soak.
- [ ] Require frame median at least 59 FPS, p95 at most 18 ms, p99 at most
  25 ms, 1 percent low at least 55 FPS, consecutive frames over 33.3 ms at
  most 1, capacity/lifecycle physics p95/p99 at most 6/8 ms, lifecycle memory
  growth below 8 MiB, draw-call p95 at most 200, combat batches at most 50,
  and world batches at most 12.
- [ ] Append the final commit, environment, clean state, commands, raw evidence
  paths, screenshots, metrics, and verdict to
  .agents/semantic-v2-runtime-acceptance-evidence.md.
- [ ] Update docs/product/vehicle_game_spec.md and
  docs/design/VISUAL_SYSTEM.md with only durable final behavior.
- [ ] Update root or local AGENTS.md only for genuinely durable operating
  guidance; do not add a transient directory inventory.
- [ ] Verify all related links after final renames.
- [ ] Delete this completed ExecPlan after durable decisions have landed,
  according to .agents/PLANS.md.
- [ ] Commit the durable handoff and plan retirement as one coherent
  task-owned documentation commit.

Accept: All focused, full-suite, import, export, native, built-Web,
accessibility, localization, performance, lifecycle, authority, and workbench
checks pass from a clean commit; durable specs contain the final contract; this
completed plan is absent from the active tree.

Guard: A successful export alone is diagnostic, not release acceptance.

## Validation Cadence

### Workbench inner loop

~~~powershell
.\tools\design\build_visual_replacement_workbench.ps1
.\tools\design\build_visual_replacement_workbench.ps1 -Check
.\tools\validation\validate_visual_replacement_workbench.ps1
git diff --check
~~~

### Per-unit semantic loop

Always run:

~~~powershell
$checks = @(
  "validate_vehicle_semantic_asset_provider.gd",
  "validate_vehicle_visual_asset_coverage.gd",
  "validate_vehicle_visual_replacement_coverage.gd",
  "validate_vehicle_semantic_visual_separation.gd"
)

foreach ($check in $checks) {
  .\tools\godot.ps1 --headless --path . --script "res://tools/validation/$check"
  if ($LASTEXITCODE -ne 0) {
    throw "Validation failed: $check"
  }
}
~~~

Run every table row whose category matches the changed unit; for a unit spanning
multiple categories, run the union without duplicates:

| Changed unit | Additional focused validators |
| --- | --- |
| Player craft or player-controlled package | validate_vehicle_player_presentation.gd, validate_vehicle_actor_visuals.gd, validate_vehicle_combat_renderer.gd, validate_vehicle_primary_weapon.gd, validate_vehicle_secondary_weapons.gd, validate_vehicle_hud_presenter.gd |
| UI component | validate_vehicle_stage_ui_layout.gd, validate_vehicle_ui_localization.gd, validate_vehicle_upgrade_ui.gd, validate_vehicle_pause.gd, validate_settings_store.gd |
| World or reward | validate_vehicle_world_visuals.gd, validate_vehicle_reward_facility_visual_recipes.gd, validate_vehicle_terrain_runtime.gd, validate_vehicle_wear_collapse_tiles.gd, validate_vehicle_destructible_terrain_flow.gd, validate_vehicle_pickup_contact.gd |
| Ordinary enemy, projectile, cue, or state | validate_vehicle_actor_visuals.gd, validate_vehicle_attack_contract.gd, validate_vehicle_damage_feedback.gd, validate_vehicle_combat_renderer.gd |
| Boss | validate_vehicle_actor_visuals.gd, validate_vehicle_boss_exams.gd, validate_vehicle_boss_patterns.gd, validate_vehicle_boss_runtime.gd, validate_vehicle_combat_renderer.gd |
| Effect frames | validate_vehicle_visual_replacement_coverage.gd, validate_vehicle_damage_feedback.gd, validate_vehicle_combat_renderer.gd |

All validators named in this table exist at the verified baseline. When a
planned path or identity rename changes one of them, update that validator in
the same unit commit. Do not weaken an assertion to make a replacement pass.

### Full GDScript suite

~~~powershell
Get-ChildItem tools\validation -Filter "*.gd" |
  Sort-Object Name |
  ForEach-Object {
    .\tools\godot.ps1 --headless --path . --script ("res://tools/validation/" + $_.Name)
    if ($LASTEXITCODE -ne 0) {
      throw "Validation failed: $($_.Name)"
    }
  }
~~~

At the verified baseline this runs 58 entry points: 56 validate_vehicle_*.gd
validators, validate_settings_store.gd, and profile_vehicle_pressure.gd. The
profile script is a fast diagnostic only; authoritative rendered performance is
still the separate native/Web matrix below.

### Authority, import, and export

~~~powershell
.\tools\validation\validate_document_authority.ps1
.\tools\validation\validate_visual_replacement_workbench.ps1
.\tools\design\build_visual_replacement_workbench.ps1 -Check
.\tools\godot.ps1 --path . --headless --import
.\tools\export_web.ps1
git diff --check
~~~

### Rendered evidence matrix

| Surface | Required states |
| --- | --- |
| Deployment and modal shell | normal and compact, Korean and English, keyboard and gamepad |
| Live HUD | normal combat, boss objective, minimap targets, all action cooldowns, exceptional timed effects |
| Player | idle, moving, eight hull directions, eight independent aim directions, firing, dash, reduced-motion dash, hit, barrier, EMP |
| Secondaries | seeker flight/impact, ion active, all orbit counts, wake mine placement/detonation, escort movement/fire/impact |
| Enemies | all 19 roles, elite, collective, high pressure, every hostile projectile affinity/tier/power |
| Bosses | five bodies, shared node active/damaged/resolved, sealed/open/stable, phase changes |
| World | all three fields, wear states, bulkhead states, repair, overdrive, transit, arc surge, cover, crate, pickups |
| UI components | every declared state, long localized strings, 960/1280/1920, focus and disabled |
| Reports and guidebook | discovered/undiscovered, ship, mobile, stationary, bosses, objects, victory/defeat |

Native and built-Web evidence must use the built application for final
acceptance. Development-server screenshots are iterative only.

## Test Plan

### Structural invariants

- [ ] One production visual root and zero old-root runtime references.
- [ ] One visual authority document and zero conflicting style authority.
- [ ] One replacement workbench folder and zero active TO-BE media elsewhere.
- [ ] Every production media path belongs to exactly one switch unit.
- [ ] Every declared media file has a provider, Theme, catalog, or concrete
  consumer.
- [ ] Every TO-BE deliverable mirrors an exact target path.
- [ ] Every preview path is outside to-be/assets.
- [ ] Every approval hash equals current TO-BE bytes.
- [ ] Every applied production hash equals the approved hash.
- [ ] Every retired path has zero references.

### Visual and accessibility invariants

- [ ] Art direction matches the sole visual authority.
- [ ] Role, delivery, threat tier, state, and function remain readable without
  color.
- [ ] Focus is always visible.
- [ ] Disabled, selected, active, damaged, resolved, intact, cracked, and
  collapsed states remain distinct.
- [ ] No localized text is baked into media.
- [ ] Korean and English have no missing strings, overflow, overlap, or
  clipping.
- [ ] Reduced motion removes repeated motion without hiding state.
- [ ] All supported widths preserve safe insets and target sizes.

### Gameplay and performance invariants

- [ ] Controls and manual aim remain unchanged.
- [ ] Collision and visible damaging cores remain aligned.
- [ ] Telegraph footprints and timing remain simulation-owned.
- [ ] Enemy roster, boss logic, encounters, quotas, drops, pickups, upgrades,
  and persistence remain unchanged.
- [ ] Procedural field fingerprints remain unchanged.
- [ ] Combat batches remain at most 50.
- [ ] World batches remain at most 12.
- [ ] Draw-call p95 remains at most 200.
- [ ] All authoritative frame, physics, lifecycle, and memory thresholds pass.

## Rollback and Safety

- Record a clean full HEAD before every phase and unit.
- Keep each switch unit in one coherent task-owned commit.
- Use the promotion helper's non-mutating preview before -Apply.
- The helper may copy only approved bytes into exact production targets.
- Structural code, manifest, Theme, validation, and retirement changes land in
  the same unit commit.
- Never leave production in a partially switched state at handoff.
- If a pre-commit unit check fails, fix or remove only that unit's task-owned
  worktree changes.
- If a committed unit fails later integration, use a normal task-owned revert
  commit or a scoped corrective commit. Never use hard reset or force checkout.
- Never stage, revert, delete, or move unrelated user-authored changes.
- Before any recursive deletion or move, resolve every absolute path and prove
  it remains under the exact intended repository subdirectory.
- Delete legacy evidence only after the explicit Phase 2 approval and new
  workbench parity.
- Delete Phase 3 staged/unused production media only after the separate exact
  33-PNG plus 33-sidecar approval.
- Delete player, boss-module, or any later production media only when the
  applicable unit approval names every exact retire path and its paired tracked
  import sidecar.
- Do not delete ignored .codex-runtime, build, .godot, or external cache paths.
- Do not weaken supply-chain safeguards, add a dependency, add native code, or
  change performance thresholds without new explicit authority.
- Git history is the recovery mechanism for retired tracked media. Record
  retire lists and applied commits before deleting active workbench records.

## Predetermined Contingencies

| Condition | Required response |
| --- | --- |
| Pre-asset interlock is still active | Stop at Phase 0 and request only the authority needed to complete or amend that plan |
| Legacy evidence deletion approval is absent | Keep the exact legacy files, stop Phase 2 before cleanup, and do not claim the single-workbench target is complete |
| Phase 3 production-retirement approval is absent or incomplete | Keep the prepared task-owned runtime-change worktree, stop before deletion or commit, and retain all 33 PNGs and sidecars |
| A structural unit lacks exact hash/retire approval | Keep it switch_ready, perform no promotion, mapping change, or deletion, and continue only with an independent unit whose prerequisites are satisfied |
| A TO-BE file is a sheet or requires extraction | Reject it as a deliverable; keep it under previews and create exact target files |
| A required state is missing | Keep the unit target_required; do not approve or partially promote |
| An approved byte or mapping changes | Clear approval automatically and return the unit to switch_ready |
| Promotion source or target escapes an allowed root | Abort before any write |
| A current production file lacks a consumer | If the locked matrix or canonical specification requires it, bind the already named consumer; otherwise use the retire-unit acceptance and exact approval path before removal |
| A structural unit cannot land atomically | Stop that unit and preserve the prior production contract |
| Player consolidation obscures manual aim | Keep the one body, strengthen cursor/muzzle/projectile cues within the fixed contract, and do not restore a fixed aim attachment without change control |
| Wear texture disagrees with TerrainRuntime state or rectangle | Keep runtime state/rectangle authoritative and reject the visual |
| Boss shared node loses gameplay identity | Keep kind/index/text in gameplay snapshots and correct only the presentation mapping |
| UI state clips at any supported size/language | Keep the unit unapplied and correct image safe areas or existing layout owners without changing product copy |
| Render batch or draw-call budget regresses | Optimize the responsible presentation batch; do not reduce gameplay workload or quality |
| Native/Web frame or physics threshold fails | Stop release handoff, preserve raw evidence, and correct the measured presentation owner |
| A dependency or native extension appears necessary | Stop and request explicit scope expansion |
| The user requests a different art direction | Treat it as change control; update the visual authority and this plan before producing more assets |
| An unrelated dirty change overlaps a target | Stop and request coordination; never overwrite or absorb it |

## Risks

| Risk | Control |
| --- | --- |
| Path normalization breaks Godot imports | Use git-aware moves, update all references in one phase, run headless import, and inspect only task-owned sidecars |
| Workbench becomes another authority | Keep style and product decisions in canonical specs; workbench stores status and exact mappings only |
| Generated files drift from source | Builder -Check and byte-for-byte validator |
| Preview is mistaken for deliverable | Separate roots, labels, schema fields, and validator rejection |
| Approval survives changed bytes | SHA-256-bound approval and automatic invalidation |
| Player consolidation changes control readability | Eight-by-eight hull/aim matrix and runtime-scale capture |
| Shared boss nodes erase objective meaning | Gameplay kind/index/text retained; three visual states only |
| UI state family is partially switched | Atomic per-component approval and promotion |
| Raster art alters collision truth | Collision/radii remain in gameplay owners and focused invariants |
| Historical media remains active clutter | Approval-gated removal and Git-history recovery |
| Broad provider/Theme changes create competing owners | Responsibility-shaped files and final codebase quality audit |
| Visual changes hide performance regression | Pressure scenarios, batch budgets, draw-call budget, lifecycle, and built-Web checks |

## External Authority Dependencies

These are deliberate authority gates, not assumptions or unresolved design
questions. Execution has deterministic stop behavior at each gate:

1. Phase 0 requires a durable record that the active pre-asset stabilization
   plan completed and retired, or a BK-authored amendment that explicitly clears
   this plan's asset/UI switch scope.
2. Phase 2 requires BK's explicit approval for the exact legacy workbench and
   evidence deletion list after current-workbench parity is demonstrated.
3. Phase 3 requires a separate BK approval for the printed set of 33 unused or
   staged production PNGs and their 33 tracked import sidecars.
4. Every replace, add, or consolidate unit requires BK approval of the exact
   builder-observed deliverable hashes and exact retire paths. Every retire-only
   unit requires BK approval of its exact retire paths after zero-reference
   validation. Player and shared-boss-node structural switches use their exact
   lists in Phases 4 and 9.

No approval is inferred from this plan's existence, a preview, a generated
index, an old conversation, a passing validator, or a prior approval of
different bytes. Work may proceed on a different independent unit only when its
own prerequisites and authority are complete.

## Assumptions

None. The art direction, target folders, terminology, schema, legal
transitions, unit boundaries, player consolidation, boss-node consolidation,
UI bindings, staged-media retirement, output metadata, approval mechanism,
phase order, validators, release thresholds, and stop conditions are fixed in
this plan.

## Open Questions

None. The gates listed under External Authority Dependencies have predetermined
stop behavior and are not design questions. Any request to change scope, art
direction, gameplay,
dependencies, workload, thresholds, or the three canonical locations is change
control and requires this plan and the applicable authority to be updated
before execution continues.

## Progress

- [x] Read active repository and local instructions.
- [x] Read the ExecPlan and document-lifecycle rules.
- [x] Read the product and visual authorities.
- [x] Audited the active pre-asset plan and confirmed the switch gate is
  currently closed.
- [x] Audited tracked gameplay, UI, and workbench media distribution.
- [x] Audited gameplay and UI manifests, providers, Theme, catalogs, renderer,
  concrete consumers, and focused validators.
- [x] Audited the historical restore/build/validate inventory pipeline.
- [x] Verified official Godot 4.7 theme hooks for disabled tabs, CheckButton
  focus, and compact PanelContainer variation.
- [x] Ran the current inventory validator successfully.
- [x] Ran current player, wear, provider, coverage, replacement, and UI layout
  validators successfully.
- [x] Locked the target structure, schema, state machine, switch units,
  structural consolidations, expected counts, validation, and rollback rules.
- [x] Completed three independent read-only execution-readiness audits covering
  authority/release interlocks, runtime switch contracts/counts, and the
  workbench pipeline; incorporated every material finding.
- [x] Verified this document has no Korean characters, no deferred-decision
  markers, no missing named baseline validator, and valid lifecycle authority.
- [x] Phase 0: clear the pre-asset asset/UI interlock through the narrow
  2026-08-03 BK amendment recorded below.
- [x] Phase 1: establish the three canonical locations.
- [x] Phase 2: rebuild the current-only replacement workbench.
- [x] Phase 3: normalize the current production contract.
- [x] Phase 4: complete the player vertical slice.
- [ ] Phase 5: replace the UI component system.
  - [x] Prepare modal_master, content_plate, and hud_plate as ten exact,
    independently deployable state PNGs with three family contact sheets and
    one shared runtime-size matrix; all three units are switch_ready.
  - [x] Obtain exact hash-bound approval and apply the three foundational
    surface families without extending that approval to another UI family.
  - [x] Prepare all six upgrade_card states as exact deployable PNGs with
    contact-sheet and runtime-size evidence; upgrade_card is switch_ready.
  - [x] Obtain exact hash-bound approval and apply upgrade_card without
    extending that approval to button families.
  - [x] Prepare button_primary, button_secondary, and button_danger as fifteen
    exact deployable state PNGs with per-family contact sheets and one shared
    runtime nine-slice matrix; all three units are switch_ready.
  - [ ] Obtain exact hash-bound approval and apply the three button families
    without extending that approval to later Phase 5 component families.
  - [ ] Complete the remaining Phase 5 component families in dependency order.
- [ ] Phase 6: replace player-action, HUD, and secondary packages.
- [ ] Phase 7: replace world, facility, and reward packages.
- [ ] Phase 8: replace ordinary enemies, hostile attacks, and cues.
- [ ] Phase 9: replace bosses and shared nodes.
- [ ] Phase 10: reconcile counts and promote the new AS-IS baseline.
- [ ] Phase 11: complete release validation and retire this plan.

## Next Steps

1. Display the three button families' exact fifteen-entry target/hash map from
   a clean preparation commit.
2. Request hash-bound approval for only those three independently promotable
   units, with empty retire_paths and runtime_change_paths.
3. Promote, validate, commit, and baseline-clean only exact approved families.

## Completion Criteria

- [ ] The pre-asset switch interlock was validly cleared before implementation.
- [x] art/visuals/production is the sole current gameplay/UI visual root.
- [x] docs/design/VISUAL_SYSTEM.md is the sole visual style/theme authority.
- [x] docs/design/visual-replacement-workbench is the sole active replacement
  direction/media/status folder.
- [x] The historical restore pipeline and review media are absent after
  explicit approval.
- [x] AS-IS references current production directly and is never duplicated.
- [x] Every TO-BE deliverable is an exact target file, never a sheet.
- [ ] Every production media file has exactly one switch unit and at least one
  runtime consumer.
- [x] Player uses one craft body and no fixed engine/aim-mount asset.
- [x] Manual aim, dash, collision, and all player flows remain correct.
- [ ] Boss presentation uses five bodies and three shared node states, with
  zero boss-specific module assets.
- [ ] Procedural floor/wall truth remains unchanged and eight staged rasters
  are absent.
- [ ] Wear tiles use exact intact/cracked/collapsed textures over unchanged
  runtime rectangles.
- [ ] Effects use exactly 101 frames and zero atlases.
- [ ] Gameplay provider indexes exactly 211 PNGs.
- [ ] UI manifest declares exactly 54 connected PNG states.
- [ ] All applied production hashes match exact BK-approved hashes.
- [ ] All retired paths have zero references.
- [x] The generated index works from a file URL in Korean and English with
  complete keyboard, focus, responsive, and reduced-motion behavior.
- [ ] Full focused, full-suite, authority, workbench, import, export, native,
  built-Web, performance, and lifecycle gates pass.
- [ ] Durable product and visual specifications contain the final contract.
- [ ] Final evidence is appended with commit, environment, commands, raw paths,
  captures, metrics, and verdict.
- [ ] This completed ExecPlan is deleted from the active tree.

## Stop Conditions

Stop immediately and report the exact failed condition when:

- Phase 0 authority is absent;
- a destructive target is not exact or lacks approval;
- an unrelated worktree change overlaps scope;
- a deliverable is not directly promotable;
- a unit is incomplete or its hash changed after approval;
- runtime ownership would move into art or workbench data;
- gameplay, collision, topology, localization, input, or persistence would
  change;
- a dependency, native extension, workload change, or threshold change is
  required;
- any focused or full validation fails;
- built-Web rendered evidence cannot be obtained;
- any release performance or lifecycle threshold fails.

Do not mark a phase or this plan complete while a stop condition remains.

## Decision Notes

- 2026-08-02: Classified this as a Level 4 visual-system and cross-surface
  migration. The art direction is fixed, so execution requires system-wide
  rendered evidence rather than new style ideation.
- 2026-08-02: Defined AS-IS as runtime-connected current production, excluding
  staged and historical files.
- 2026-08-02: Defined TO-BE as exact production-ready target files, with
  previews separated from deliverables.
- 2026-08-02: Chose one production root, one visual authority document, and one
  replacement workbench folder.
- 2026-08-02: Chose a current-only deterministic builder instead of historical
  Git restoration.
- 2026-08-02: Bound approval to exact hashes and exact retirement paths.
- 2026-08-02: Made replacement-workbench.json the only hand-authored status
  owner; computed hashes live in generated inventory until copied into an exact
  approval record.
- 2026-08-02: Defined retire-only preparation, destructive approval, atomic
  production switch, follow-up application ledger, and baseline cleanup as an
  executable non-self-referential Git protocol.
- 2026-08-02: Consolidated fixed player authored parts into one craft body
  while preserving independent manual-aim cues and transient dash feedback.
- 2026-08-02: Consolidated ten boss-specific module visuals into three shared
  presentation states without changing gameplay module identity.
- 2026-08-02: Locked the boss-node truth table: locked uses active geometry plus
  its lock cue/tint; live active modules cross to damaged at 50 percent health;
  terminal/compatibility states use resolved; core states stay on core cues.
- 2026-08-02: Kept procedural floor/wall rendering and added three wear-tile
  state textures for the current product feature.
- 2026-08-02: Removed atlas-only effect duplication and UI states without
  consumers; bound all valid UI states.
- 2026-08-02: Locked final normalized counts at 211 gameplay PNGs, 54 UI PNGs,
  and one font.
- 2026-08-02: Preserved the active pre-asset plan as a hard interlock. This plan
  does not authorize runtime switching until that interlock is durably cleared.
- 2026-08-03: BK explicitly instructed, "Waive the interlock: explicitly
  authorize starting visual-replacement Phase 1 despite the failed release
  gate." This entry and the mirrored entry in
  .agents/execplans/2026-08-02-pre-asset-code-stabilization.md are the durable
  amendment record required by Phase 0. Scope is limited to starting and
  executing this visual-replacement plan. The amendment does not complete the
  failed performance, built-Web, lifecycle, durable-spec, or retirement gates;
  approve dependencies or native extensions; reduce workload; relax thresholds;
  or pre-approve any Phase 2, Phase 3, or per-unit destructive action.
- 2026-08-03: Phase 0 began from clean branch master at full HEAD
  c4bae5ea91a26c98622a5e3373bde015cf3b7fc7 at 2026-08-03T00:09:55+09:00.
- 2026-08-03: Phase 1 established docs/design/VISUAL_SYSTEM.md,
  art/visuals/production/{gameplay,ui}, and
  docs/design/visual-replacement-workbench/previews/as-is/ui. The migration
  preserved 310 production/review asset blobs byte-for-byte, imported 305
  Godot resources successfully, left zero old-root references in the live
  Phase 1 scope, passed document authority plus eleven focused visual/UI
  validators, and produced a successful Web export. The legacy
  docs/design/visual-asset-inventory pipeline, its restore tool, and historical
  append-only evidence remain intentionally present for Phase 2; no deletion
  authority was inferred from the Phase 1 waiver.
- 2026-08-03: Phase 2 groundwork created a deterministic current-only source,
  model, builder, validator, copy-only promotion helper, generated ledger, and
  bilingual self-contained index. Static validation accounts for all 247
  gameplay PNGs, 57 UI PNGs, one font, its license, 48 switch units, 265 exact
  TO-BE targets, and three retire-only units; builder -Check and the workbench
  validator pass. Automated rendered parity remains open because the connected
  browser rejected the required local file URL under its security policy and
  prohibited an alternate browser workaround. No legacy file was deleted and
  no later phase was started.
- 2026-08-03: BK manually inspected the generated index.html and accepted its
  rendered Phase 2 parity. The connected browser could not capture automated
  local-file evidence, so owner acceptance is the rendered-evidence record for
  the direct-file, bilingual, preview separation, keyboard/dialog/filter, and
  responsive checklist at this gate.
- 2026-08-03: BK explicitly instructed, "Approve deletion of the exact 52-file
  Phase 2 legacy set." The approved set resolved to 49 tracked files under
  docs/design/visual-asset-inventory, including 44 PNGs, plus the three exact
  restore/model/validator tools named in Phase 2. Git removed exactly those 52
  files. The replacement builder, deterministic check, workbench validator,
  document-authority validator, live historical-token scan, and repository
  old-root scan all passed; Git history remains the recovery mechanism.
- 2026-08-03: Phase 3 preparation began from clean full HEAD
  1accd5b34edc3e301088bb8e5bc21b2259d27367. The task-owned runtime diff now
  removes eight staged world declarations, 22 atlas declarations and provider
  indexes, and three orphan UI declarations while preserving every retirement
  file. It binds modal compact, tab disabled, and toggle focus states; keeps all
  101 effect frames and 54 connected UI states; and updates gameplay coverage
  to 217. The three retire-only units are switch_ready with empty deliverable
  hash maps. All 33 PNGs and 33 sidecars remain present and tracked, zero live
  runtime references remain, focused Godot and deterministic workbench checks
  pass, and the separate exact Phase 3 deletion approval remains absent.
- 2026-08-03: BK explicitly instructed, "Approve deletion of the exact
  displayed 33 PNG and 33 sidecar Phase 3 set." The three retire-only approval
  records bind the previously displayed 66 paths, empty deliverable hash maps,
  baseline commit 1accd5b34edc3e301088bb8e5bc21b2259d27367, and approval time
  2026-08-03T11:46:48+09:00. Git removed exactly those 33 PNGs and 33 tracked
  import sidecars. Gameplay coverage is 217, UI coverage is 54, all 101 effect
  frames remain, the five focused Godot validators pass, the workbench build
  and deterministic check pass at 272 production media, and Web export passes.
- 2026-08-03: Phase 3 production switch commit
  8c6a97a077a09cdbf667aa392276fad0e0cb6e41 contains the runtime normalization
  and exactly the approved 66 deletions. The immediate follow-up ledger records
  that full commit hash on all three retire-only units at
  2026-08-03T11:55:33+09:00 and marks them retired. The rebuilt current-only
  workbench contains 217 gameplay PNGs, 54 UI PNGs, one font, and zero staged
  or orphan production rows.
- 2026-08-03: Phase 4 produced two direct, non-sheet TO-BE files with the
  built-in image generation workflow and local chroma-key removal. The craft
  body is 160 by 128 with pivot 88,64, alpha bounds 6,15 through 153,112, and
  SHA-256 5c0343fa6840aa7f68fd367b5b636cd84a8bcf0011d45b2758a3f4fe18846a4c.
  The player minimap marker is 48 by 48 with pivot 24,24, alpha bounds 4,5
  through 43,42, and SHA-256
  e8fa4ac0f9e2a6faaf4a013fd86b44857a2142ce3fe814f7c7accd46ba5f6602.
  A Godot-generated exact-texture comparison covers eight hull directions,
  the 8 by 8 independent hull/aim matrix, the eight required player states,
  and the 14-pixel marker. The player, actor, renderer, primary, secondary,
  HUD, replacement-coverage, deterministic builder, and workbench validators
  pass. player_craft is switch_ready; its approval and application remain
  null, and production runtime files remain unchanged.
- 2026-08-03: BK explicitly instructed, "Approve the Phase 4 switch at
  baseline bcab35399d4cc797a046de0246097f819c68f8fa using the two exact
  displayed hashes and retirement of the exact displayed six paths." The
  player_craft approval record binds that baseline, the craft-body SHA-256
  5c0343fa6840aa7f68fd367b5b636cd84a8bcf0011d45b2758a3f4fe18846a4c, the
  minimap-marker SHA-256
  e8fa4ac0f9e2a6faaf4a013fd86b44857a2142ce3fe814f7c7accd46ba5f6602, and
  exactly the three legacy player PNGs plus their three tracked import
  sidecars. No broader deletion or later-unit approval is inferred.
- 2026-08-03: Phase 4 production switch commit
  9f1f8d1972df6cb488f70ccf0e09e88d78924c4c promotes the two approved bytes,
  replaces three fixed attachments and renderer batches with one craft body,
  removes exactly the six approved legacy paths, and preserves independent
  aim and transient rear-anchor dash feedback. Ledger commit
  9071ada261b40b748336dd8072c454ba2f46770d records that application. Focused
  player, actor, renderer, weapon, HUD, localization, layout, pause,
  transition, provider, coverage, workbench, authority, import, and Web-export
  checks pass. Native Korean full evidence and English core evidence are under
  build/evidence/phase4-player-craft; built Web deployment and combat smoke
  passed on codex lane port 13029 with seven successful requests and zero
  console warnings or errors. Baseline promotion makes the approved production
  bytes the current AS-IS, clears transitional ledger fields, and removes the
  two duplicate TO-BE files plus the completed comparison preview.
- 2026-08-03: Phase 5 foundational UI preparation produced the complete
  modal_master, content_plate, and hud_plate families as ten direct TO-BE PNGs
  from one built-in image-generation source board followed by deterministic
  chroma removal, exact-canvas derivation, and fixed-palette quantization. The
  three exact-deliverable contact sheets and shared 960/1280/1920 plus compact
  runtime matrix show longest Korean/English content within the locked safe
  insets. A new Godot validator checks manifest geometry, transparent corners,
  the exact visual-system palette, semantic rails outside content-safe areas,
  and grayscale structural distinction. All eleven declared UI/provider,
  layout, localization, focus-path, guidebook, deployment/reward, report, HUD,
  and settings checks pass. The three non-interactive StyleBox families do not
  own focus or activation behavior; their existing control consumers remain
  unchanged. All three units are switch_ready with null approval/application,
  no retire paths, and no production changes pending exact hash-bound approval.
- 2026-08-03: BK explicitly approved the Phase 5 foundational UI switch at
  baseline c596880961d066dbc1291dbf220f984095cf072c for modal_master,
  content_plate, and hud_plate using the ten exact target/hash mappings
  displayed from that clean commit. All three approval records bind those bytes
  at 2026-08-03T13:15:48+09:00 with empty retire_paths. The approval grants no
  runtime-change path, deletion, or authority for any later UI family.
- 2026-08-03: The approved Phase 5 foundational UI bytes were promoted as
  three atomic units. modal_master switch commit
  15ce50877615ff840f9c9363e8e34bebbeae481b and ledger d7795c9 replace two
  states; content_plate switch commit d36b2eb96c34b10e480797d50f32ef24b0ac9480
  and ledger db9d05f replace three; hud_plate switch commit
  562f5dd041616304da70d215670d8e3ec08fc996 and ledger 5388687 replace five.
  Every unit passed its twelve declared workbench, surface, provider, layout,
  localization, upgrade, pause, settings, guidebook, deployment/reward,
  report, and HUD checks. The combined Web export passed. Built-Web rendering
  on codex port 13029 covered 960, 1280, and 1920 widths, Korean and English,
  compact settings, keyboard focus, and language activation with seven
  successful requests and zero console warnings or errors. The task-owned
  server was stopped after evidence collection. Baseline cleanup now makes the
  ten production bytes current AS-IS and removes only their duplicate TO-BE and
  completed preview files.
- 2026-08-03: Phase 5 upgrade_card preparation produced normal, hover, pressed,
  focus, selected, and disabled as six direct 128 by 128 TO-BE PNGs with patch
  margin 20 and safe inset 24,22,22,22. One built-in image-generation source
  master was chroma-removed and deterministically reduced to the exact fixed
  palette; state variants use different rail positions, corner brackets,
  surface values, and disabled edge segmentation instead of color alone. The
  contact sheet is built from exact deliverables, while the runtime matrix
  checks 244 by 286 compact cards, 304 by 330 wide cards, 960/1280/1920
  contexts, and long Korean and English samples. The expanded four-family
  surface validator and all eleven UI/provider, layout, localization, upgrade,
  pause, settings, guidebook, deployment/reward, report, and HUD checks pass.
  upgrade_card is switch_ready with null approval/application, no retire paths,
  no runtime-change paths, and unchanged production bytes.
- 2026-08-03: BK explicitly approved the Phase 5 upgrade_card switch at
  baseline 14dd6ef39424d4e11e0cd0ba8fbdabeb8294a1b3 using the six exact
  target/hash mappings displayed from that clean commit. The approval record
  binds those bytes at 2026-08-03T13:46:25+09:00 with empty retire_paths and
  runtime_change_paths. This approval grants no deletion, runtime-code change,
  or authority for the subsequent button families.
- 2026-08-03: The upgrade_card production switch commit
  9ff8b987ba879e126da31f58aef1b0f7439a5d60 promoted all six approved hashes,
  and ledger commit 8c3fbba1ed0f0e38cddf38dc495a31e95f53f7a1 recorded the application after
  all twelve declared acceptance commands passed. Web export then exposed a
  pre-existing release-only resource-discovery defect: exported .tres.remap
  entries were filtered out, leaving real level-up offers empty. Corrective
  commit 1cd32bcb81b7ec4794220de7481985f6576c8d91 restores source-path loading
  for both the 41-card catalog and secondary definitions. Upgrade-system,
  secondary, upgrade-UI, and visual-coverage validators pass; the rebuilt Web
  PCK completes deterministic Korean and English capture manifests, including
  normal, selected, confirmed, and longest localization card states. Chrome
  built-Web smoke returned eight successful requests and zero console warnings
  or errors on codex port 13029, and the task-owned server was stopped. The six
  production bytes are now current AS-IS; the duplicate TO-BE files and two
  completed previews are removed, and transitional approval/application fields
  are cleared without extending authority to any button family.
- 2026-08-03: Phase 5 button preparation used one built-in image-generation
  master at
  C:/Users/BK/.codex/generated_images/019fc2a8-d5ad-7321-b0c6-961caed3c4ed/exec-a082ef0a-4ab8-44ef-83e0-3666b9bc0ab1.png.
  Local chroma removal found source alpha bounds 103,137 through 1431,879.
  Deterministic derivation then produced fifteen direct 96 by 64 PNGs for
  button_primary, button_secondary, and button_danger, all with patch margin
  16, safe inset 20,16,20,16, fixed-palette RGB, transparent exterior corners,
  and no baked text or icons. State distinctions use different rail positions,
  corner brackets, center values, and disabled edge segmentation rather than
  color alone. Three exact-deliverable contact sheets and one shared runtime
  matrix cover 220, 320, and 460 pixel nine-slice widths plus Korean and English
  label samples. The seven-family surface validator covers 31 states, and all
  twelve declared workbench, surface, coverage, layout, localization, upgrade,
  pause, settings, guidebook, deployment/reward, report, and HUD checks pass.
  All three button units are switch_ready with null approval/application,
  empty retire_paths and runtime_change_paths, and unchanged production bytes.

## Execution Handoff

Start by reading this complete plan, root AGENTS.md, .agents/AGENTS.md,
.agents/PLANS.md, the active product spec, the active visual spec, and the
pre-asset stabilization plan. Run Phase 0 exactly. If the interlock is open,
execute one checkbox and one coherent switch unit at a time, update Progress
and Decision Notes with evidence and deviations, run the specified focused
checks before every commit, and never infer a new art or gameplay decision.
