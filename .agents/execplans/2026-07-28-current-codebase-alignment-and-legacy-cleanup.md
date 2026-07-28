---
type: plan
status: active
owner: BK
created: 2026-07-28
last_reviewed: 2026-07-28
scope: Current Cardborne codebase ownership, domain language, validation coverage, document lifecycle, and retirement of superseded development traces
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../../README.md
  - ../../docs/README.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/UI_VISUAL_SYSTEM.md
  - ../vehicle-performance-architecture-audit.md
  - ../vehicle-performance-stabilization-evidence.md
  - ./2026-07-23-vehicle-performance-architecture-stabilization.md
  - ./2026-07-25-stage-tactical-variation-and-ui-readability.md
  - ./2026-07-27-pixel-art-visual-recovery.md
  - ../../pixel-art-production/README.md
---

# Current Codebase Alignment and Legacy Cleanup — Execution Plan

This plan turns a repository-wide audit into a bounded cleanup and ownership
correction. The current application is already one coherent Godot 4.7 top-down
vehicle shooter: no tracked runtime GDScript is an abandoned platformer,
isometric, or 3D implementation. The remaining past-development traces are
concentrated in completed or superseded plans, finished handoff/evidence
packages, four disconnected pixel-production scripts, one ignored local probe,
and retired localization language. The implementation sequence below preserves
all current gameplay and visual contracts while removing those traces,
clarifying the domain, strengthening the cold reward boundary, and making the
full validator suite authoritative in CI.

## Purpose

- **Objective:** make the repository describe and validate only the current
  five-stage vehicle game, without deleting live runtime owners or useful
  reproducibility evidence.
- **Final artifact:** a smaller current-document surface, an exact domain
  glossary, corrected current-state documentation and localization, a bounded
  reward-transaction owner, a complete CI validation loop, and an explicit
  record of every retained or retired script and document.
- **Completion state:** current authority contains no retired field/stage/boss
  language; all approved legacy files are removed or deliberately archived;
  every runtime script remains reachable; the full local/CI contract suite and
  Web export pass; this plan is then deleted after its durable decisions have
  been integrated.
- **Compatibility promise:** manual aim, held primary fire, the one-second
  opening shot, dash, passive seekers, EMP, authored encounters, map pickups,
  card upgrades, the run-selected field, five stages, stage bosses, settings,
  guidebook progress, Korean-first localization, English parity, saves, and the
  Sunken Ceramic Fresco presentation remain behaviorally unchanged. No optional
  field-boss requirement or copy is removed before Gate A explicitly resolves
  the protected instruction conflict.

## Why and Context

The repository name still contains `platformer`, and the history contains
multiple product pivots. That makes file age and terminology unreliable signals
of current ownership. The audit therefore used the actual Godot entry graph,
resource references, validators, current specifications, and relevant git
history rather than filename intuition.

Two history points settle the major ambiguity:

1. Commit `547b805` (`refactor: keep only the current vehicle game`) removed the
   former platformer, isometric action-RPG, and native-3D implementations,
   including their scenes, scripts, rooms, testbeds, art, and tools.
2. Commit `cb40059` (`feat: rebuild vehicle campaign on one shared field`)
   removed the five old geometry-bearing stage maps and established the current
   model: one of three macro fields is selected for a run, and all five combat
   stages use tactical children of that selected field.

The live repository has since accumulated finished plans and evidence packages
that still use earlier language. Those files are not executable defects, but
they increase the chance that a future change restores a retired concept or
follows a dead validation command.

## Scope

This plan includes:

- all 80 tracked application GDScripts under `scripts/`;
- all 47 executable scripts under root `tools/`;
- all 28 PowerShell scripts in the offline pixel-production workspace;
- the runtime pixel shader as a presentation source;
- all 54 Markdown, MDX, and text documents in the tracked audit baseline outside
  generated/ignored runtime directories, including `.agents/`; this plan is the
  55th document after creation;
- Godot entry scenes, data resources, localization, project settings, export
  configuration, and CI insofar as they prove script reachability and current
  behavior;
- relevant ignored local residues when they are clearly task-created or
  development-only.

## Non-scope

- No gameplay feature, balance, encounter quota, card effect, boss pattern,
  field geometry, art direction, save schema, control, or localization wording
  is redesigned.
- The repository/folder/remote name `cardborne-platformer` is recognized as a
  legacy identifier but is not renamed. It is an external integration contract,
  not dead application code.
- Generated `.godot/`, exported `build/`, `.uid`, `.import`, binary art, audio,
  and the thousands of pixel-production intermediates are not individually
  content-reviewed by this plan. Their owning manifests, runtime references,
  scripts, and documentation were reviewed.
- Runtime hot loops are not split merely because `vehicle_run.gd` is large.
- UI layout and styling are not changed. Any later visible UI change must enter
  through the repo's UIUX gate and produce rendered evidence.
- The active difficulty/meta-progression decision study is not resolved here.
- No production dependency is added.

## Assumptions

- `docs/product/vehicle_game_spec.md` is the product-behavior authority.
- `docs/design/UI_VISUAL_SYSTEM.md` is the runtime art/UI authority.
- `pixel-art-production/README.md` is subordinate production-pipeline authority,
  not a second runtime-presentation authority.
- A literal-reference reachability graph plus current resource ownership and
  passing validators is sufficient to classify tracked runtime scripts. A
  disconnected offline tool is not called dead until its documentation,
  generated outputs, and git purpose are also checked.
- Tracked deletions remain recoverable from git history; ignored local cleanup
  does not, so local deletion has a separate approval gate.
- Approval gates below authorize only their exact manifests. They do not grant
  permission to clean unrelated worktree files.

## Audit Method and Coverage

### Evidence inspected

| Evidence | What it established |
| --- | --- |
| `AGENTS.md`, `.agents/AGENTS.md`, `.agents/PLANS.md` | Repository rules, protected-document behavior, plan lifecycle, current product constraints |
| `project.godot`, `scenes/main/GameRoot.tscn`, `scenes/run/VehicleRun.tscn` | Actual boot path, autoloads, and live scene owners |
| `scripts/**/*.gd`, `data/**/*.tres`, runtime scenes, theme, audio bus, localization | Application dependency graph and data/resource ownership |
| `docs/product/vehicle_game_spec.md` | Current five-stage run, three field choices, combat, rewards, UI, and performance contract |
| `docs/design/UI_VISUAL_SYSTEM.md` | Current flat-color Sunken Ceramic Fresco and Korean-first UI contract |
| root and pixel-production READMEs | Claimed current state and pipeline contracts |
| all `.agents` plans/evidence and all other text documents | Lifecycle status, duplicated authority, broken links, and historical traces |
| `git log`, `git show`, `git blame` around the product pivot and shared-field migration | Whether apparently old names are live concepts or development residue |
| `.github/workflows/vehicle-run-validation.yml`, `tools/validation/` | Local/CI validation coverage and version drift |
| ignored `build/object_compat_probe.gd` and `.codex-runtime/external-research/2026-07-05/` | Local residue outside tracked source |

### Quantitative coverage

| Surface | Audited amount | Result |
| --- | ---: | --- |
| Runtime GDScript | 80 files / 22,517 physical lines | All reachable and current |
| Root executable tooling | 47 scripts / 6,797 physical lines | All current; CI invokes only a subset |
| Pixel-production executable tooling | 28 PowerShell scripts plus one runtime shader / 8,254 physical lines | Four disconnected past-trace candidates; remaining tools current or evidence-owned |
| Text documents | 54 baseline files / 13,152 physical lines; this plan is file 55 | Current authority is clear; completed/superseded traces and stale active statuses remain |
| Godot data | 3 scenes, 53 `.tres` resources, theme, bus, 14 WAV files | Current and referenced |
| Localization | 603 Korean/English keys | No blank/duplicate translations; 58 retired keys and one governance-conflicted field-boss key identified |
| Pixel runtime | catalog, one atlas, three tiles, one shader, 39 catalog families | Integrated and live despite stale README wording |
| Validators | 40 scripts in `tools/validation/` | All 40 passed in the audit session; that output is session-local and must be rerun for durable implementation evidence; CI currently runs 9 |

### Reachability result

The traced boot graph is:

```text
project.godot
├── autoload SettingsStore
├── autoload VehicleGuidebookStore
└── scenes/main/GameRoot.tscn
    ├── scripts/main/game_root.gd
    └── scenes/run/VehicleRun.tscn
        └── scripts/vehicle/vehicle_run.gd
            ├── domain/state owners under scripts/{bosses,cards,combat,...}
            ├── field/stage definitions under scripts/vehicle/stages/
            ├── UI and presentation owners
            └── card/weapon/theme/audio/pixel resources
```

A breadth-first trace of scene script properties, autoload paths, literal
`preload`/`load` references, and data-resource scripts reaches every one of the
80 tracked runtime GDScripts. The validators and capture scene reach the
remaining test-only root tooling. There is therefore **no tracked application
GDScript deletion candidate**.

## Current State and Architecture Evaluation

### Architecture summary

The codebase has useful responsibility boundaries around one integration-heavy
simulation owner:

```text
GameRoot
└── VehicleRun — run composition, ordered simulation, mode/lifecycle integration
    ├── immutable definitions
    │   ├── FieldRegistry / FieldLayout / StageCatalog / StageRules
    │   ├── EnemyArchetypes / BossPatterns / UpgradeCatalog
    │   └── AttackContract / DamageSourceCatalog
    ├── mutable state owners
    │   ├── EnemyStore / ProjectileStore / ExperienceRuntime
    │   ├── EncounterRuntime / StageFlow / TerrainRuntime
    │   └── SecondaryRuntime / BossRuntime / StatusRuntime
    ├── presentation
    │   ├── CombatRenderer / PixelAssetCatalog / AudioDirector
    │   └── StageUI / HUDPresenter / dedicated modal panels
    └── persistence and diagnostics
        ├── SettingsStore / GuidebookStore
        └── PerformanceRecorder / capture and validator hooks
```

The main structural risk is responsibility concentration, not competing
implementations. Storage, immutable rules, rendering, UI panels, persistence,
and most specialist behavior already have dedicated owners.

### Hotspot findings and locked response

| File | Measured shape | Evaluation | Planned response |
| --- | ---: | --- | --- |
| `scripts/vehicle/vehicle_run.gd` | 5,547 lines / 235 functions | Oversized integration boundary. It still owns lifecycle, input, ordered combat policy, reward coordination, stage transitions, UI snapshots, audio, capture, and debug paths. | Keep the measured hot simulation order in this owner. Extract only the cold reward-transaction state and queue; do not move enemy/projectile policy without a separate performance proof. |
| `scripts/ui/vehicle_stage_ui.gd` | 1,876 lines / 73 functions | Large runtime-built UI shell. Dedicated settings, guidebook, stage-report, and upgrade panels already exist; deployment/pause/result/garage remain in the shell. | Make only the strict result-title contract correction. Do not perform a cosmetic panel split in this cleanup. |
| `scripts/presentation/vehicle_combat_renderer.gd` | 1,587 lines / 37 functions | Large but cohesive retained-batch renderer. It is presentation-only and does not own collision truth. | Retain intact. Splitting batches by visual type would increase synchronization cost without resolving a domain conflict. |
| `tools/design/generate_complete_pixel_library.gd` | 1,380 lines / 36 functions | Large current publisher/generator used by the integrated catalog and active visual-recovery plan. | Retain as the canonical runtime publisher. Separate generation recipes only when a second live publisher or change-frequency split appears. |
| `scripts/vehicle/vehicle_field_layout_generator.gd` | 814 lines | Cohesive bounded pre-run field/tactical compiler. | Retain intact. |
| `scripts/presentation/vehicle_combat_visual_library.gd` | 743 lines | Cohesive geometry/material library. | Retain intact. |

The performance evidence is decisive here. A prior attempt to move attack state
behind another cross-object runtime raised the measured frame p95 from roughly
16.95 ms to 25.34 ms. The current performance plan correctly retained bounded
hot policy loops in `VehicleRun`, but one unchecked phase still describes their
removal as a target. This plan reconciles that phase with the measured decision
instead of repeating the regression.

### Cold reward boundary to extract

`VehicleRun` currently owns these related mutable fields:

- `current_reward_source`;
- `current_reward_optional`;
- `_upgrade_offer_serial`;
- `claimed_reward_sources`;
- `pending_reward_sources`.

It also implements transaction identity, claim state, queue order, and reset
logic. Those invariants are a coherent cold-path responsibility and can be
extracted without crossing the combat hot loop.

Create `scripts/rewards/vehicle_reward_runtime.gd` as the sole owner of:

- stage-scoped transaction IDs;
- pending source order;
- the active source and whether it is optional;
- claimed/declined terminal outcomes;
- monotonically increasing offer serials;
- run-reset and stage-reset state.

Use an explicit cold-path API:

- `reset_run()` clears the active source, pending sources, terminal outcomes,
  and offer serial;
- `reset_stage()` clears only the active and pending sources while preserving
  run-scoped terminal outcomes and the run-scoped offer serial;
- `enqueue(source_id)` suppresses a duplicate pending source;
- `begin(stage_id, source_id, optional)` establishes one active transaction and
  returns the next monotonically increasing offer serial;
- `claim(stage_id)` records `claimed` only for non-`level_up` sources and clears
  the active transaction;
- `decline(stage_id)` records `declined` and clears the optional active
  transaction;
- `pop_pending()` and read-only `has_claimed(stage_id, source_id)` expose queue
  progression and the boss-reward completion gate.

There is no snapshot/restore API. The current application has no active-run
restore contract, so adding one here would be speculative.

Keep these responsibilities out of the new owner:

- building card choices;
- applying upgrade behavior;
- consuming experience levels;
- recording encounter telemetry;
- showing UI, playing audio, or changing `RunMode`;
- finalizing a stage;
- group-clear presentation/effect de-duplication.

`VehicleRun` remains the orchestrator. It asks the runtime for the next source,
builds/presents the offer, applies the selected gameplay effect through
`VehicleRunBuild`, and tells the runtime the terminal outcome. It also retains
`pending_stage_completion` and owns the one-way finalization gate: only when the
reward runtime is idle, the pending queue is empty, and the current stage's
`boss` source is claimed may `VehicleRun` call
`StageFlow.record_rewards_complete()`. This removes state ownership from the
catch-all without adding per-frame object calls or inventing a persistence
contract.

## Domain Language Alignment

### Canonical language

| Term | Canonical meaning | Owner |
| --- | --- | --- |
| **run** | One complete five-stage campaign with a fixed difficulty snapshot, one selected macro field, a persistent build, and persistent explored minimap cells. | `VehicleRun`, `VehicleRunDifficulty`, product spec |
| **field** | The macro map selected once from Drowned Ruins, Tidal Archive, or Storm Drydock for a run. | `VehicleFieldRegistry`, `VehicleFieldLayout` |
| **stage** | One of five ordered combat progressions within the selected field. A stage is not a separate map. | `VehicleCombatStages`, `VehicleStageCatalog`, `VehicleStageFlow` |
| **tactical layout** | The immutable stage-specific child of a field that varies cover, anchors, sockets, stationary threats, pickups, crates, and encounter seed. Floor, boundary, and functional terrain remain shared field-level truth. | `VehicleStageTacticalLayout`, field layout generator |
| **encounter** | Deterministic packet/squad scheduling and live-pressure coordination within a stage. | `VehicleEncounterDirector`, `VehicleEncounterRuntime` |
| **surge** | The authored eight-squad arrival event. Use `wave` only for a literal attack shape or named boss pattern, not encounter progression. | Encounter director and product spec |
| **stage boss** | The boss implemented by current code/spec and summoned by the ordinary-defeat quota for the current stage. | Stage flow and boss runtime |
| **optional field boss** | A concept still required by protected root `AGENTS.md` but absent from current product spec and executable state owners. Its status is an authority conflict, not a settled retired term. | Gate A product/governance decision |
| **upgrade** | A gameplay behavior/stat choice applied to the run build. | Upgrade definition/catalog and run build |
| **card** | The data/UI representation used to offer an upgrade. It is not the behavior owner. | Card resources and choice presentation |
| **player** | Internal simulation/input ownership or faction. | Input and simulation code |
| **ship / vehicle** | User-facing controlled actor and broad code namespace. | Korean/English copy and `vehicle_*` modules |

`player`, `ship`, and `vehicle` are not a conflict requiring a global rename.
They describe different layers. The required correction is to prevent retired
map/boss terms from masquerading as current domain concepts.

### Confirmed language drift

| Location | Drift | Exact correction |
| --- | --- | --- |
| `README.md` | Says all stages reuse “that same enlarged drowned-ruin field,” hiding the three-field run selection. | Say that a run selects one of three macro fields and reuses its authored tactical children across five stages. |
| root `AGENTS.md` | Requires “optional field bosses,” while current code/spec implement only quota-gated stage bosses. | Resolve as the explicit Gate A product/governance decision before changing the instruction or field-boss copy. |
| `scripts/ui/vehicle_stage_ui.gd` | Result UI silently falls back to retired `STAGE_FLOODED_WORKS`. | Require `stage_title_key`; make the debug result fixture provide a current field-derived stage key; remove the fallback. |
| `localization/vehicle_stage.csv` | Retains five old geometry-stage names, old objectives, removed upgrades, old result states, and one field-boss key implicated by Gate A. | Remove the 58 confirmed retired keys after the strict result contract; remove the separately listed field-boss key only if Gate A authorizes retirement of the concept. |
| `pixel-art-production/README.md` | Says the game has no runtime PNG/atlas/Sprite art and integration is future work. | Describe the live runtime atlas/catalog/tiles/shader and the renderer-owned selection model. |
| `pixel-art-production/design/visual-research/PART_GUIDELINES.md` | Claims canonical authority for runtime presentation, competing with `UI_VISUAL_SYSTEM.md`. | Narrow `canonical_for` to pixel-part production and state explicit subordination to the runtime visual spec. |

### Retired localization-key manifest

The following 58 keys have no live literal reference after the result fallback
is removed and do not conflict with protected product guidance. The audit
separately preserved 26 dynamically constructed `UPGRADE_FAMILY_*` and
`UPGRADE_STAT_*` keys; this is not a blanket “unreferenced key” deletion.

```text
UI_FLOODED_WORKS
DEPLOY_KICKER
STAGE_FLOODED_WORKS
STAGE_TIDAL_ARCHIVE
STAGE_STORM_DRYDOCK
STAGE_CORAL_SWITCHYARD
STAGE_ABYSSAL_OBSERVATORY
ENEMY_DREDGE_WARDEN
ENEMY_CURRENT_CURATOR
ENEMY_STORM_FOREMAN
ENEMY_SALVAGE_CONVOY
ENEMY_MIRROR_WARDEN
OBJECTIVE_CALIBRATE_DETAIL
OBJECTIVE_APPROACH
OBJECTIVE_APPROACH_STAGE
OBJECTIVE_APPROACH_DETAIL
OBJECTIVE_GENERATORS
OBJECTIVE_GENERATORS_DETAIL
OBJECTIVE_GENERATORS_DETAIL_GENERIC
OBJECTIVE_CACHE
OBJECTIVE_CACHE_DETAIL
OBJECTIVE_BASIN
OBJECTIVE_BASIN_STAGE
OBJECTIVE_BASIN_DETAIL
OBJECTIVE_BOSS
NOTIFY_REDEPLOYED
NOTIFY_COLOSSUS_STAGGERED
NOTIFY_DREDGE_CAPACITOR
NOTIFY_SWITCHYARD_ROUTE
NOTIFY_REFLECTOR_ROTATED
NOTIFY_MIRROR_VAULT_OPEN
NOTIFY_CONVOY_DEPARTING
NOTIFY_CONVOY_ESCAPED
NOTIFY_GENERATOR_DESTROYED
NOTIFY_EXPERIENCE_CACHE
PATTERN_STAGGER_WINDOW
PATTERN_SWITCH_CHARGE
PATTERN_CROWN_CARRIER
RESULT_RUN
RESULT_WARDEN
RESULT_DEFEATED
RESULT_BYPASSED
RESULT_NEXT_STAGE
BUFF_ATTACK
GARAGE_PASSIVE_SEEKER
UPGRADE_FAMILY_BRIDGE
UPGRADE_RICOCHET_TITLE
UPGRADE_RICOCHET_DESC
UPGRADE_CIRCUIT_HARVEST_TITLE
UPGRADE_CIRCUIT_HARVEST_DESC
UPGRADE_FIELD_CONVERTER_TITLE
UPGRADE_FIELD_CONVERTER_DESC
UPGRADE_SALVAGE_BOOSTER_TITLE
UPGRADE_SALVAGE_BOOSTER_DESC
UPGRADE_LEVEL_PREVIEW
UPGRADE_STAT_OPENING_BREACH_MULTIPLIER
UPGRADE_STAT_BARRIER_BONUS
UPGRADE_STAT_FIELD_DURATION_MULTIPLIER
```

`NOTIFY_FIELD_BOSS_SHARD` is also unreferenced by current code, but it remains
outside the retirement manifest until Gate A resolves whether optional field
bosses are a stale instruction or an unimplemented required feature. If Gate A
authorizes retirement, delete this key as the 59th row. If Gate A preserves the
feature requirement, retain the key and stop this plan before claiming domain
alignment; implementing the missing feature requires a separate product plan.

Preserve the current field-specific stage keys such as
`STAGE_DROWNED_RUINS_1`, preserve `OBJECTIVE_BOSS_STAGE` and
`OBJECTIVE_BOSS_DETAIL`, and preserve `PATTERN_CARRIER_WAVE`; those are current
and semantically distinct.

## Legacy and Historical Artifact Ledger

### Classification rules

- **Retire:** no current runtime, production, validation, or unresolved-decision
  owner remains; durable facts must first move to current authority.
- **Archive in place:** not current authority, but retains useful reproducible
  evidence or a negative design lesson. Set `status: archived`, repair its
  authority links, and keep it out of current indexes.
- **Retain current:** live runtime, active production input, active evidence, or
  a validator of a current contract.
- **Local cleanup:** ignored machine-local residue, never part of the tracked
  repository; delete only with separate approval.

### Tracked documents to retire after migration

| Path | Evidence that it is a past trace | Required migration before deletion |
| --- | --- | --- |
| `.agents/execplans/2026-07-23-single-field-campaign-secondaries-guidebook.md` | `status: superseded`; the shared-field migration is implemented and specified. | Replace incoming `related` links with the product spec or current evidence. |
| `.agents/execplans/2026-07-24-vehicle-world-combat-expansion.md` | `status: done`; 111 checked items and no remaining task. | Preserve accepted behavior in the product spec; redirect the decision-study/evidence links. |
| `.agents/execplans/2026-07-25-korean-copy-overflow-correction.md` | `status: done`; all 22 items checked. | Preserve the layout/localization rules in `UI_VISUAL_SYSTEM.md` and current validators. |
| `.agents/execplans/2026-07-25-stage-tactical-variation-and-ui-readability.md` | Feature milestones are complete; its seven remaining checks are the same rendered performance acceptance owned by the performance plan. | Move the remaining performance gate and any unique evidence link to the performance plan, then mark done and delete. |
| `pixel-art-production/PLAN.md` | `status: done`; its “40 families/no procedural art” completion statement no longer matches the live 39-family mixed renderer, and active recovery supersedes its rollout. | Move still-valid production invariants to `pixel-art-production/README.md`; update active recovery and evidence links. |
| `design-qa.md` | `status: active` but the QA checklist is fully passed and points to ignored capture outputs. | Preserve durable screen-size/overflow rules in `UI_VISUAL_SYSTEM.md` and validators. |
| `docs/design/uiux-refinement-direction/README.md` and six sibling PNGs | Implemented design-direction evidence with a link to a plan that never existed at the referenced path. | Confirm its durable layout rules are already in `UI_VISUAL_SYSTEM.md`; current capture tooling replaces the static package. |
| `docs/handoffs/repository-audit-2026-07-26/` (seven Markdown files) | Handoff `status: done`; external-review validation says accepted findings were applied. It is a completed coordination package, not current authority. | Verify every accepted finding is present in current specs/code/tests; retain no live index links to the package. |
| `pixel-art-production/design/experiment/README.md` | Explicitly documents an incorrect first interpretation. | Move the useful negative rule into the current pixel README, then delete the experiment note. |

The repository history remains the recovery mechanism for these tracked
artifacts. They are not moved into a new `archive/` catch-all because that would
preserve the same authority ambiguity under a different path.

### Tracked scripts to retire

| Path | Evidence | Retirement gate |
| --- | --- | --- |
| `pixel-art-production/tools/design/publish_pixel_runtime.ps1` | Zero incoming source/doc references; introduced for the first player slice; the active recovery plan and live catalog name `tools/design/generate_complete_pixel_library.gd` as the current publisher. | Prove the current generator covers the old script's exact contracts: shared atlas composition, region/cell-region rewriting, runtime atlas path, SHA-256/size metadata, catalog output, and post-publish catalog validation. |
| `pixel-art-production/tools/design/build_pixel_hangar_mvp_set.ps1` | Zero incoming references; one-off earlier MVP evidence generator. | Confirm its outputs are retained or reproducible from git history. |
| `pixel-art-production/tools/design/create_pixel_hangar_reference_contact_sheet.ps1` | Zero incoming references; one-off reference contact-sheet generator from the prior pixel exploration. | Confirm the resulting evidence is not an active acceptance input. |
| `pixel-art-production/tools/design/create_projectile_pixel_sheet.ps1` | Zero incoming references; produced the earlier 85-frame technical exploration that the current README labels evidence. | Preserve the relevant projectile lesson in the current pipeline spec. |

These are offline production scripts, not Godot runtime scripts. Their
retirement does not change the application graph.

### Historical documents/scripts to archive or retain deliberately

| Path or group | Disposition | Reason |
| --- | --- | --- |
| `.agents/vehicle-performance-architecture-audit.md` | Retain archived | Bounded architecture evidence and risk baseline; already `status: archived`. |
| `.agents/vehicle-world-combat-expansion-evidence.md` | Change to archived, retain | Contains useful measured A/B performance rationale; remove links to the deleted completed plan. |
| `.agents/vehicle-performance-stabilization-evidence.md` | Retain active | Still owns unfinished rendered release evidence. |
| `.agents/vehicle-difficulty-meta-progression-decision-study.md` | Retain active | Records an unresolved product decision; not a past implementation trace. |
| `.agents/execplans/2026-07-23-vehicle-performance-architecture-stabilization.md` | Retain active and reconcile | Rendered release acceptance remains incomplete. |
| `.agents/execplans/2026-07-27-pixel-art-visual-recovery.md` | Retain active | Current visual recovery work remains incomplete. |
| `pixel-art-production/design/space-hangar-research.md` | Mark archived, retain | Historical visual research; fix its stale `./UI_VISUAL_SYSTEM.md` related path. |
| `pixel-art-production/evidence/gates/01-post-sampler-capability/README.md` | Mark archived, retain with evidence | Reproducible capability gate, not runtime authority. |
| `pixel-art-production/evidence/gates/core-slice/baseline/README.md` | Mark archived, retain with evidence | Baseline evidence; replace its missing plan link with the active visual-recovery plan. |
| `pixel-art-production/evidence/pipeline-sampler/README.md`, its four prompt docs, and `build-sampler.ps1` | Mark archived, retain together | The README directly documents how the sampler script reproduces its evidence. |
| `pixel-art-production/design/experiment/single-asset-grid/README.md` | Retain active | Explicitly referenced by the active visual-recovery plan as the accepted method. |
| `pixel-art-production/design/visual-research/{README.md,REFERENCE_GALLERY.md,PART_GUIDELINES.md}` | Retain current; narrow authority | Current production research and part construction, subordinate to runtime visual authority. |
| source prompt `.md`/`.txt` files under `pixel-art-production/assets/source/candidates/` | Retain as production inputs | They are versioned source inputs, not governance documents. |
| `pixel-art-production/design/visual-research/references/.../License.txt` and `art/ui/production/fonts/NotoSansKR-OFL.txt` | Retain | License obligations, never legacy cleanup candidates while their assets remain. |

### Ignored local cleanup candidates

| Path | Classification | Action |
| --- | --- | --- |
| `build/object_compat_probe.gd` | Confirmed local residue: 311-byte standalone `SceneTree` property-access probe, ignored and unreferenced. | Delete only after local-cleanup approval. |
| `.codex-runtime/external-research/2026-07-05/` | Dated ignored Codex research cache containing third-party dialog/platformer/controller samples; never imported or exported by the game. | Optional machine-local cache cleanup after confirming no active task owns it; do not treat its third-party scripts as repository code. |

## Broken Links and Authority Drift

The cleanup must repair these exact current defects before removing history:

1. `docs/design/uiux-refinement-direction/README.md` points to missing
   `.agents/execplans/2026-07-25-rendered-uiux-refinement.md`.
2. `pixel-art-production/evidence/gates/core-slice/baseline/README.md` points to
   missing `execplans/2026-07-27-pixel-asset-production-and-integration.md`.
3. `pixel-art-production/design/space-hangar-research.md` has a stale
   `./UI_VISUAL_SYSTEM.md` related path.
4. The performance plan invokes removed
   `validate_vehicle_projectile_runtime.gd` and
   `run_all_validations.gd`; the current validator is
   `validate_vehicle_projectile_store.gd`, and the suite is a sorted
   `validate_*.gd` loop.
5. `PART_GUIDELINES.md` claims runtime-presentation authority already owned by
   `docs/design/UI_VISUAL_SYSTEM.md`.
6. Root README and root AGENTS use different generations of the field/boss
   model.

## Script Inventory and Individual Evaluation

Every executable source is listed below. A grouped verdict is used only where
all named scripts share the same current owner and evidence.

### Application scripts — 80/80 retain

#### Autoload and application root

| Script | Responsibility | Verdict |
| --- | --- | --- |
| `scripts/autoload/settings_store.gd` | Settings, locale, difficulty, and audio persistence | Retain current |
| `scripts/autoload/vehicle_guidebook_store.gd` | Guidebook discovery persistence | Retain current |
| `scripts/main/game_root.gd` | Boot/root composition and run scene ownership | Retain current |

#### Bosses

| Script | Responsibility | Verdict |
| --- | --- | --- |
| `scripts/bosses/vehicle_boss_patterns.gd` | Boss attack-pattern definitions | Retain current |
| `scripts/bosses/vehicle_boss_practice_session.gd` | Debug-only current boss-practice setup | Retain current |
| `scripts/bosses/vehicle_boss_runtime.gd` | Live stage-boss state and transitions | Retain current |

#### Cards and build

| Script | Responsibility | Verdict |
| --- | --- | --- |
| `scripts/cards/vehicle_build_snapshot_builder.gd` | Stable build snapshots for UI/reporting | Retain current |
| `scripts/cards/vehicle_cycle_runtime.gd` | Cycle/timing upgrade behavior | Retain current |
| `scripts/cards/vehicle_run_build.gd` | Applied-upgrade levels and gameplay build state | Retain current |
| `scripts/cards/vehicle_stat_modifier.gd` | Typed stat modification | Retain current |
| `scripts/cards/vehicle_upgrade_catalog.gd` | Upgrade resource catalog and offer selection | Retain current |
| `scripts/cards/vehicle_upgrade_definition.gd` | Upgrade data/resource contract | Retain current |
| `scripts/cards/vehicle_upgrade_offer_presenter.gd` | UI-safe offer snapshots | Retain current |

#### Combat

| Script | Responsibility | Verdict |
| --- | --- | --- |
| `scripts/combat/vehicle_attack_contract.gd` | Affinity, conditions, collision, warnings, and interruption semantics | Retain current domain owner |
| `scripts/combat/vehicle_attack_telegraph_builder.gd` | Attack telegraph snapshots | Retain current |
| `scripts/combat/vehicle_damage_source_catalog.gd` | Damage-source identity and metadata | Retain current |
| `scripts/combat/vehicle_projectile_state.gd` | Typed projectile state | Retain current |
| `scripts/combat/vehicle_projectile_store.gd` | Bounded projectile storage/lifecycle | Retain current |
| `scripts/combat/vehicle_spatial_grid.gd` | Broadphase spatial queries | Retain current |
| `scripts/combat/vehicle_stage_report_builder.gd` | Stage-report model construction | Retain current |
| `scripts/combat/vehicle_stage_telemetry.gd` | Stage combat metrics | Retain current |
| `scripts/combat/vehicle_status_profile.gd` | Status behavior derived from the build | Retain current |
| `scripts/combat/vehicle_status_runtime.gd` | Live stacking/timing state | Retain current |

#### Encounters

| Script | Responsibility | Verdict |
| --- | --- | --- |
| `scripts/encounters/vehicle_encounter_director.gd` | Authored packet/surge scheduling | Retain current |
| `scripts/encounters/vehicle_encounter_runtime.gd` | Live encounter pressure and reward accounting | Retain current |
| `scripts/encounters/vehicle_spawn_allocator.gd` | Fair spawn selection/clearance | Retain current |
| `scripts/encounters/vehicle_stage_flow.gd` | Ordinary → warning → boss → rewards → complete state machine | Retain current domain owner |

#### Enemies

| Script | Responsibility | Verdict |
| --- | --- | --- |
| `scripts/enemies/vehicle_elite_trait_catalog.gd` | Current elite trait definitions | Retain current |
| `scripts/enemies/vehicle_enemy_archetypes.gd` | Current enemy role definitions | Retain current |
| `scripts/enemies/vehicle_enemy_specialist_runtime.gd` | Specialist behavior state | Retain current |
| `scripts/enemies/vehicle_enemy_state.gd` | Typed live enemy state | Retain current |
| `scripts/enemies/vehicle_enemy_store.gd` | Bounded enemy storage/lifecycle | Retain current |
| `scripts/enemies/vehicle_pursuit_field.gd` | Shared pursuit/flow-field guidance | Retain current |
| `scripts/enemies/vehicle_stage_difficulty.gd` | Stage pressure scaling | Retain current |

#### Input, player, and secondaries

| Script | Responsibility | Verdict |
| --- | --- | --- |
| `scripts/input/vehicle_input_profile.gd` | Current input actions and prompts | Retain current |
| `scripts/player/vehicle_primary_weapon.gd` | Held primary fire and one-second opening-shot state | Retain current |
| `scripts/player/vehicle_secondary_definition.gd` | Secondary-weapon resource contract | Retain current |
| `scripts/player/vehicle_secondary_runtime.gd` | Passive seeker/field/blade/mine/drone behavior | Retain current |

#### Performance

| Script | Responsibility | Verdict |
| --- | --- | --- |
| `scripts/performance/vehicle_performance_recorder.gd` | Bounded frame/subsystem measurements | Retain current |
| `scripts/performance/vehicle_performance_scenario.gd` | Deterministic pressure scenarios | Retain current |

#### Presentation and audio

| Script | Responsibility | Verdict |
| --- | --- | --- |
| `scripts/presentation/vehicle_audio_director.gd` | Runtime SFX/music routing | Retain current |
| `scripts/presentation/vehicle_combat_renderer.gd` | Retained batched combat presentation | Retain current |
| `scripts/presentation/vehicle_combat_visual_library.gd` | Visual geometry/material recipes | Retain current |
| `scripts/presentation/vehicle_pixel_asset_catalog.gd` | Live pixel runtime catalog/atlas mapping | Retain current |
| `scripts/presentation/vehicle_pixel_world_mesh_builder.gd` | Pixel-world mesh construction from gameplay geometry | Retain current |

#### Progression and rewards

| Script | Responsibility | Verdict |
| --- | --- | --- |
| `scripts/progression/vehicle_experience_runtime.gd` | Experience shards and pending levels | Retain current |
| `scripts/progression/vehicle_experience_shard.gd` | Typed shard state | Retain current |
| `scripts/progression/vehicle_guidebook_catalog.gd` | Guidebook entries/current discovery catalog | Retain current |
| `scripts/rewards/vehicle_field_drop_rules.gd` | Current repair/experience/support drop rules | Retain current |

#### UI

| Script | Responsibility | Verdict |
| --- | --- | --- |
| `scripts/ui/vehicle_build_summary_panel.gd` | Build summary rendering | Retain current |
| `scripts/ui/vehicle_combat_mesh_icon.gd` | Runtime mesh-based icon | Retain current |
| `scripts/ui/vehicle_guidebook_panel.gd` | Guidebook modal | Retain current |
| `scripts/ui/vehicle_guidebook_preview.gd` | Guidebook visual preview | Retain current |
| `scripts/ui/vehicle_hud_presenter.gd` | Dirty-channel HUD snapshots | Retain current |
| `scripts/ui/vehicle_minimap_mesh_builder.gd` | Minimap geometry | Retain current |
| `scripts/ui/vehicle_settings_panel.gd` | Settings modal | Retain current |
| `scripts/ui/vehicle_stage_report_panel.gd` | Stage report modal | Retain current |
| `scripts/ui/vehicle_stage_ui.gd` | Runtime UI shell and mode surfaces | Retain; correct result-title contract |
| `scripts/ui/vehicle_status_orbit.gd` | Status orbit visualization | Retain current |
| `scripts/ui/vehicle_threat_radar.gd` | Threat radar | Retain current |
| `scripts/ui/vehicle_upgrade_choice_card.gd` | Upgrade card presentation | Retain current |
| `scripts/ui/vehicle_upgrade_choice_panel.gd` | Upgrade-choice modal | Retain current |

#### Field, stage, terrain, and run

| Script | Responsibility | Verdict |
| --- | --- | --- |
| `scripts/vehicle/stages/drowned_ruin_field.gd` | Drowned Ruins macro-field definition | Retain current |
| `scripts/vehicle/stages/tidal_archive_field.gd` | Tidal Archive macro-field definition | Retain current |
| `scripts/vehicle/stages/storm_drydock_field.gd` | Storm Drydock macro-field definition | Retain current |
| `scripts/vehicle/stages/vehicle_combat_stages.gd` | Five field-aware combat-stage profiles | Retain current |
| `scripts/vehicle/vehicle_field_geometry_snapshot.gd` | Immutable geometry snapshot | Retain current |
| `scripts/vehicle/vehicle_field_layout.gd` | Selected field plus immutable tactical children | Retain current domain owner |
| `scripts/vehicle/vehicle_field_layout_generator.gd` | Bounded pre-run layout compilation | Retain current |
| `scripts/vehicle/vehicle_field_registry.gd` | Three-field registry and selection | Retain current |
| `scripts/vehicle/vehicle_run_difficulty.gd` | Fixed per-run difficulty snapshot | Retain current domain owner |
| `scripts/vehicle/vehicle_run.gd` | Run composition and ordered simulation integration | Retain; extract only cold reward state |
| `scripts/vehicle/vehicle_stage_backdrop.gd` | Field/stage backdrop presentation | Retain current |
| `scripts/vehicle/vehicle_stage_catalog.gd` | Active-field stage-profile facade | Retain current |
| `scripts/vehicle/vehicle_stage_geometry.gd` | Geometry queries independent of presentation | Retain current |
| `scripts/vehicle/vehicle_stage_rules.gd` | Shared game constants/rules | Retain current |
| `scripts/vehicle/vehicle_stage_tactical_layout.gd` | Immutable stage tactical child | Retain current |
| `scripts/vehicle/vehicle_stage_visual_profile.gd` | Field/stage visual tokens | Retain current |
| `scripts/vehicle/vehicle_terrain_definition.gd` | Terrain definition contract | Retain current |
| `scripts/vehicle/vehicle_terrain_runtime.gd` | Live terrain state | Retain current domain owner |

### Root tools — 47/47 retain

#### Release/setup and content tools

| Script | Responsibility | Verdict |
| --- | --- | --- |
| `tools/godot.ps1` | Local Godot resolver/wrapper | Retain; patch-pin gate below |
| `tools/setup-godot.ps1` | Official local editor installer | Retain; patch-pin gate below |
| `tools/export_web.ps1` | Canonical Web export | Retain current |
| `tools/audio/generate_vehicle_sfx.py` | Deterministic current vehicle SFX generation | Retain current |
| `tools/design/generate_complete_pixel_library.gd` | Current integrated pixel publisher | Retain current |
| `tools/design/pixel_source_override_catalog.gd` | Current authored source-override mapping | Retain current |
| `tools/design/vehicle_upgrade_sheet_capture.gd` | Documented visual-QA capture scene owner | Retain current |

#### Validators and profiler

All 40 scripts below validate current product, architecture, UI, pixel, or
performance contracts. `profile_vehicle_pressure.gd` is a diagnostic
microbenchmark, not a release verdict, but it is not legacy.

```text
tools/validation/profile_vehicle_pressure.gd
tools/validation/validate_settings_store.gd
tools/validation/validate_vehicle_attack_contract.gd
tools/validation/validate_vehicle_boss_patterns.gd
tools/validation/validate_vehicle_boss_practice.gd
tools/validation/validate_vehicle_boss_runtime.gd
tools/validation/validate_vehicle_build_snapshot.gd
tools/validation/validate_vehicle_combat_renderer.gd
tools/validation/validate_vehicle_damage_feedback.gd
tools/validation/validate_vehicle_encounter_pacing.gd
tools/validation/validate_vehicle_enemy_expansion.gd
tools/validation/validate_vehicle_enemy_store.gd
tools/validation/validate_vehicle_experience.gd
tools/validation/validate_vehicle_field_layout_generation.gd
tools/validation/validate_vehicle_guidebook.gd
tools/validation/validate_vehicle_hud_presenter.gd
tools/validation/validate_vehicle_input_bindings.gd
tools/validation/validate_vehicle_navigation_clearance.gd
tools/validation/validate_vehicle_pause.gd
tools/validation/validate_vehicle_performance_scenarios.gd
tools/validation/validate_vehicle_pixel_asset_catalog.gd
tools/validation/validate_vehicle_pixel_world_renderer.gd
tools/validation/validate_vehicle_primary_weapon.gd
tools/validation/validate_vehicle_projectile_store.gd
tools/validation/validate_vehicle_rewards_ui_audio.gd
tools/validation/validate_vehicle_run.gd
tools/validation/validate_vehicle_run_difficulty.gd
tools/validation/validate_vehicle_secondary_weapons.gd
tools/validation/validate_vehicle_single_field_campaign.gd
tools/validation/validate_vehicle_spatial_grid.gd
tools/validation/validate_vehicle_spawn_allocation.gd
tools/validation/validate_vehicle_stage_layouts.gd
tools/validation/validate_vehicle_stage_report.gd
tools/validation/validate_vehicle_stage_telemetry.gd
tools/validation/validate_vehicle_stage_ui_layout.gd
tools/validation/validate_vehicle_status_stacking.gd
tools/validation/validate_vehicle_support_field_schedule.gd
tools/validation/validate_vehicle_terrain_runtime.gd
tools/validation/validate_vehicle_ui_localization.gd
tools/validation/validate_vehicle_upgrade_system.gd
```

### Pixel-production scripts — 28 classified individually

| Script | Evaluation | Verdict |
| --- | --- | --- |
| `pixel-art-production/evidence/pipeline-sampler/build-sampler.ps1` | Reproducer directly documented by its evidence README | Retain archived with evidence |
| `pixel-art-production/tools/design/author_visual_recovery_core.ps1` | Current visual-recovery core authoring entry point | Retain current |
| `pixel-art-production/tools/design/build_phase1_candidates.ps1` | Current phase-1 candidate builder | Retain while recovery plan is active |
| `pixel-art-production/tools/design/build_phase2_player_assets.ps1` | Current phase-2 player asset builder | Retain while recovery plan is active |
| `pixel-art-production/tools/design/build_pixel_asset_catalog.ps1` | Current catalog aggregation | Retain current |
| `pixel-art-production/tools/design/build_pixel_asset_review.ps1` | Current review-sheet production | Retain current |
| `pixel-art-production/tools/design/build_pixel_hangar_mvp_set.ps1` | Unreferenced earlier MVP evidence generator | Retire with approval |
| `pixel-art-production/tools/design/create_pixel_grid.ps1` | Current logical-grid authoring support | Retain current |
| `pixel-art-production/tools/design/create_pixel_hangar_reference_contact_sheet.ps1` | Unreferenced earlier research contact-sheet generator | Retire with approval |
| `pixel-art-production/tools/design/create_pixel_palette.ps1` | Current deterministic palette builder | Retain current |
| `pixel-art-production/tools/design/create_projectile_pixel_sheet.ps1` | Unreferenced earlier projectile exploration generator | Retire with approval |
| `pixel-art-production/tools/design/invoke_pixel_asset_build.ps1` | Current manifest-driven build orchestrator | Retain current |
| `pixel-art-production/tools/design/pack_pixel_asset_atlas.ps1` | Current explicit-index atlas packer | Retain current |
| `pixel-art-production/tools/design/publish_pixel_runtime.ps1` | Disconnected first-slice publisher superseded by the current Godot publisher | Retire after parity gate |
| `pixel-art-production/tools/design/raster_to_pixel_svg.ps1` | Current editable-intermediate converter | Retain current |
| `pixel-art-production/tools/design/snap_image_to_pixel_grid.ps1` | Current deterministic cleanup/snap tool | Retain current |
| `pixel-art-production/tools/design/split_pixel_asset_layers.ps1` | Current semantic-layer splitter/reassembler | Retain current |
| `pixel-art-production/tools/design/validate_pixel_asset_brief.ps1` | Current brief-schema validator | Retain current |
| `pixel-art-production/tools/design/validate_pixel_asset_inventory.ps1` | Current inventory validator | Retain current |
| `pixel-art-production/tools/design/validate_pixel_asset_manifest.ps1` | Current manifest validator | Retain current |
| `pixel-art-production/tools/validation/validate_pixel_asset_catalog.ps1` | Current catalog/hash/region validator | Retain current |
| `pixel-art-production/tools/validation/validate_pixel_asset_frame_budget.ps1` | Current frame-budget validator | Retain current |
| `pixel-art-production/tools/validation/validate_pixel_asset_import_settings.ps1` | Current Godot import-settings validator | Retain current |
| `pixel-art-production/tools/validation/validate_pixel_asset_palettes.ps1` | Current palette validator | Retain current |
| `pixel-art-production/tools/validation/validate_pixel_asset_pipeline.ps1` | Current end-to-end production validator | Retain current |
| `pixel-art-production/tools/validation/validate_pixel_asset_reviews.ps1` | Current review-artifact validator | Retain current |
| `pixel-art-production/tools/validation/validate_pixel_asset_seams.ps1` | Current connected-tile/seam validator | Retain current |
| `pixel-art-production/tools/validation/validate_pixel_source_overrides.ps1` | Current source-override validator | Retain current |

The live shader
`pixel-art-production/runtime/shaders/pixel_atlas_multimesh.gdshader` is
referenced by the current retained renderer and is not a cleanup candidate.

## Document Inventory and Lifecycle Evaluation

### Current authority and navigation — retain

```text
AGENTS.md
.agents/AGENTS.md
.agents/PLANS.md
README.md
docs/README.md
docs/product/README.md
docs/product/vehicle_game_spec.md
docs/design/UI_VISUAL_SYSTEM.md
pixel-art-production/README.md
```

`README.md` and the pixel README require the current-state corrections already
specified. The protected `AGENTS.md` correction requires approval.

### Active/archived `.agents` memory — retain or consolidate as specified

```text
.agents/vehicle-difficulty-meta-progression-decision-study.md
.agents/vehicle-performance-architecture-audit.md
.agents/vehicle-performance-stabilization-evidence.md
.agents/vehicle-world-combat-expansion-evidence.md
.agents/execplans/2026-07-23-vehicle-performance-architecture-stabilization.md
.agents/execplans/2026-07-25-stage-tactical-variation-and-ui-readability.md
.agents/execplans/2026-07-27-pixel-art-visual-recovery.md
```

The tactical plan is consolidated and retired during this execution; the other
active plans remain until their distinct stop conditions are met.

### Past-trace documents — retire as specified

```text
.agents/execplans/2026-07-23-single-field-campaign-secondaries-guidebook.md
.agents/execplans/2026-07-24-vehicle-world-combat-expansion.md
.agents/execplans/2026-07-25-korean-copy-overflow-correction.md
design-qa.md
docs/design/uiux-refinement-direction/README.md
docs/handoffs/repository-audit-2026-07-26/README.md
docs/handoffs/repository-audit-2026-07-26/current-state.md
docs/handoffs/repository-audit-2026-07-26/constraints-and-decisions.md
docs/handoffs/repository-audit-2026-07-26/source-map.md
docs/handoffs/repository-audit-2026-07-26/external-model-prompt.md
docs/handoffs/repository-audit-2026-07-26/external-review-raw.md
docs/handoffs/repository-audit-2026-07-26/external-review-validation.md
pixel-art-production/PLAN.md
pixel-art-production/design/experiment/README.md
```

The six PNGs beside the UIUX direction README are collateral evidence and follow
the same approval-gated retirement.

### Pixel research/evidence documents — keep with explicit lifecycle

```text
pixel-art-production/design/experiment/single-asset-grid/README.md
pixel-art-production/design/space-hangar-research.md
pixel-art-production/design/visual-research/README.md
pixel-art-production/design/visual-research/PART_GUIDELINES.md
pixel-art-production/design/visual-research/REFERENCE_GALLERY.md
pixel-art-production/evidence/gates/01-post-sampler-capability/README.md
pixel-art-production/evidence/gates/core-slice/baseline/README.md
pixel-art-production/evidence/pipeline-sampler/README.md
pixel-art-production/evidence/pipeline-sampler/prompts/player-interceptor.md
pixel-art-production/evidence/pipeline-sampler/prompts/repair-fixture.md
pixel-art-production/evidence/pipeline-sampler/prompts/shooter-drone.md
pixel-art-production/evidence/pipeline-sampler/prompts/thermal-heavy-shot.md
```

The accepted single-asset experiment and visual-research docs remain active.
The space-hangar, gate, baseline, and sampler documents become archived evidence
with corrected authority links.

### Versioned production prompts — retain as source

```text
pixel-art-production/assets/source/candidates/phase-1/prompts/chaser.md
pixel-art-production/assets/source/candidates/phase-1/prompts/player-breach-shot.md
pixel-art-production/assets/source/candidates/phase-1/prompts/player-primary-weapon.md
pixel-art-production/assets/source/candidates/phase-1/prompts/player-standard-shot.md
pixel-art-production/assets/source/candidates/visual-recovery/prompts/ceramic-deck-24.txt
pixel-art-production/assets/source/candidates/visual-recovery/prompts/ceramic-wall-24.txt
pixel-art-production/assets/source/candidates/visual-recovery/prompts/chaser-32.txt
pixel-art-production/assets/source/candidates/visual-recovery/prompts/cobalt-water-24.txt
pixel-art-production/assets/source/candidates/visual-recovery/prompts/player-interceptor-64.txt
pixel-art-production/assets/source/candidates/visual-recovery/prompts/repair-pickup-24.txt
```

These are asset inputs, not outdated product documentation.

### Licenses — retain

```text
art/ui/production/fonts/NotoSansKR-OFL.txt
pixel-art-production/design/visual-research/references/cc0/samples/kenney-pixel-shmup/License.txt
```

## Proposed Design

### Locked decisions

1. Retain every tracked runtime GDScript.
2. Keep `VehicleRun` as the run composer and ordered hot-loop owner.
3. Extract only reward transaction/queue state into a cold,
   presentation-independent runtime.
4. Keep gameplay behavior in upgrade/build code and card rendering in UI code.
5. Make the result screen require a current stage title; no legacy fallback.
6. Treat one run-selected macro field plus five tactical stages as the canonical
   field/stage model.
7. Use “stage boss” for the currently implemented quota boss. Do not classify
   “optional field boss” as retired until Gate A resolves the protected
   instruction conflict.
8. Preserve all dynamically referenced localization keys; delete only the
   verified 58-key manifest plus `NOTIFY_FIELD_BOSS_SHARD` if Gate A authorizes
   retirement of the field-boss requirement.
9. Make all 39 `validate_*.gd` scripts CI-authoritative; keep the pressure
   profiler separate and diagnostic.
10. Retire completed/superseded plans only after redirecting live links and
    transferring durable rules.
11. Preserve reproducible pixel evidence that still has a documented builder;
    retire disconnected one-off builders and the superseded publisher.
12. Keep the current runtime visual spec singular:
    `docs/design/UI_VISUAL_SYSTEM.md`.
13. Do not create a new archive catch-all for deleted plans/handoffs; git history
    is their archive.
14. Do not rename the repository, the `vehicle_*` namespace, or internal
    `player_*` simulation state in this work.

### Rejected alternatives

| Alternative | Reason rejected |
| --- | --- |
| Delete every script not directly loaded by the boot scene | Would erase validators, capture tooling, asset production, and reproducible evidence. |
| Remove or split `vehicle_run.gd` by line-count threshold | Size is a signal, not a responsibility boundary; prior hot-path indirection measurably regressed frame time. |
| Move enemy/projectile policy into new objects in this cleanup | No semantic conflict requires it, and measured evidence rejects it as an assumed performance improvement. |
| Split `vehicle_stage_ui.gd` into more panels now | No visible defect or ownership conflict requires a broad UI refactor; it would increase validation scope. |
| Rename all `player` terms to `vehicle` or `ship` | Those terms intentionally describe simulation, code namespace, and user-facing actor at different layers. |
| Delete all localization keys with no literal `rg` match | Dynamic upgrade-family/stat lookups make that unsafe. |
| Keep completed plans in an `archive/` directory | Repository lifecycle policy says to integrate durable decisions and delete completed plans; moving preserves authority noise. |
| Delete all pixel evidence | Some evidence is the only reproducible proof of accepted/failed production methods and is still referenced by active recovery. |
| Restore the old five named geometry-bearing stage maps | Contradicts current product spec, code, and the shared-field migration. |
| Decide the optional field-boss conflict from reachability alone | Root `AGENTS.md` is protected active authority; only Gate A may decide whether the absent feature is stale guidance or a required follow-on. |

## Approval Gates

These gates are exact and do not leave design decisions open.

### Gate A — protected current instruction

Before editing root `AGENTS.md`, request an explicit product/governance decision:
authorize treating “optional field bosses” as stale guidance and replace only
that phrase with “quota-gated stage bosses,” or preserve it as a required
unimplemented feature. If retirement is authorized, the protected edit and
`NOTIFY_FIELD_BOSS_SHARD` deletion may proceed. If the requirement is preserved,
leave the protected file/key unchanged and stop this cleanup before claiming
domain alignment; implementing the missing feature requires a separate
product/implementation plan. Do not compensate by silently changing the
product spec.

### Gate B — tracked retirement manifest

Before deletion, present the exact tracked document/script manifest from
“Tracked documents to retire” and “Tracked scripts to retire.” If approval is
denied for any item, keep that item, set lifecycle-aware documents to
`status: archived` where appropriate, add a concise non-authoritative notice,
and remove it from current indexes. Do not silently broaden the deletion list.

### Gate C — ignored local cleanup

Ask separately before deleting `build/object_compat_probe.gd` or the dated
`.codex-runtime/external-research/2026-07-05/` cache. A denial has no effect on
tracked cleanup.

### Gate D — Godot patch alignment

The CI workflow uses Godot `4.7.1-stable`; `tools/setup-godot.ps1` and
`tools/godot.ps1` resolve `4.7-stable` (4.7.0 locally). Because changing the
engine patch is a production-dependency change, request approval to standardize
local setup on `4.7.1-stable`. If approved, update both scripts and validate the
editor plus Web templates. If denied, leave both versions unchanged and
document the deliberate local/CI patch divergence in the root README.

## Delta Map

| Change | Primary files | Consumers to verify |
| --- | --- | --- |
| Correct current field/boss language | `README.md`, approved root `AGENTS.md`, product/visual indexes as needed | Humans/agents, current spec links |
| Enforce result title contract | `scripts/ui/vehicle_stage_ui.gd`, debug fixture/callers, `localization/vehicle_stage.csv` | Final result, capture mode, UI validator, Korean/English |
| Extract reward transaction state | new `scripts/rewards/vehicle_reward_runtime.gd`, `scripts/vehicle/vehicle_run.gd` | Level-up rewards, boss rewards, optional decline, stage completion, reset/retry |
| Add reward invariants | `tools/validation/validate_vehicle_rewards_ui_audio.gd` or a responsibility-shaped reward validator | Queue ordering, once-only claims, stage-scoped IDs, level-up priority |
| Make CI complete | `.github/workflows/vehicle-run-validation.yml` | All 39 current contract validators; diagnostic profiler |
| Align Godot patch if approved | `tools/setup-godot.ps1`, `tools/godot.ps1`, CI/cache docs only if required | Local import, validator suite, Web export |
| Repair pixel current state/authority | `pixel-art-production/README.md`, `PART_GUIDELINES.md`, active recovery plan | Runtime catalog, generator, renderer, visual authority |
| Reconcile performance plan | active performance plan/evidence | Hot-loop decision, real validator names, final rendered gate |
| Consolidate tactical plan | tactical plan → performance plan/spec | Remaining performance acceptance only |
| Repair lifecycle links/status | `.agents` evidence, pixel evidence, docs indexes | No broken current links |
| Retire approved history | exact manifest above | `rg` incoming references, docs indexes |
| Retire pixel one-off tools | exact four-script manifest | Current generator and all pixel validators |

## Tasks

### Milestone 0 — Reconfirm baseline and obtain scoped approvals

- [ ] Re-run `git status --short --branch`; stop if task files contain unrelated
  user changes that cannot be preserved.
- [ ] Reconfirm the boot graph and counts in this plan against the current
  commit; update the plan if implementation work has changed them.
- [ ] Obtain Gate A for the protected root instruction.
- [ ] Obtain Gate B for the exact tracked retirement manifest.
- [ ] Obtain Gate C only if local ignored cleanup is desired in the same pass.
- [ ] Obtain Gate D before changing the Godot patch pin.

**Acceptance:** every destructive/protected/dependency action has explicit,
current-conversation authority; non-approved items have the deterministic
fallback stated above.

### Milestone 1 — Correct current authority and domain language

- [x] Rewrite the root README field paragraph to say one of three macro fields
  is selected per run and its tactical children host all five stages.
- [ ] Apply the Gate-A-authorized root AGENTS phrase correction without changing
  the fixed preflight block or unrelated guidance. If Gate A preserves the
  feature requirement, stop this plan at the defined gate.
- [x] Narrow `PART_GUIDELINES.md` frontmatter to pixel-part production and state
  that runtime presentation remains governed by `UI_VISUAL_SYSTEM.md`.
- [x] Update `pixel-art-production/README.md` to describe the live runtime
  catalog, atlas, three terrain tiles, shader, 39 families, and renderer-owned
  atlas selection.
- [x] Preserve Korean-first/English parity and all current product terminology.

**Acceptance:** `run`, `field`, `stage`, `tactical layout`, `encounter`, `surge`,
`stage boss`, `upgrade`, and `card` are used consistently across current
authority; no current document claims that runtime pixel integration is future
work.

### Milestone 2 — Enforce current result/localization contracts

- [x] In `VehicleStageUI.show_result`, require a non-empty
  `stage_title_key`; fail a debug/test contract clearly instead of using
  `STAGE_FLOODED_WORKS`.
- [x] Update `debug_modal_contract("result")` to provide a current field-aware
  stage title key and the minimal valid result snapshot.
- [x] Reconfirm both runtime/capture callers already pass current keys.
- [x] Delete only the 58 localization rows in the locked manifest.
- [ ] Delete `NOTIFY_FIELD_BOSS_SHARD` only when Gate A authorizes it.
- [x] Add/adjust localization validation so current stage/result snapshots
  require both Korean and English translations.
- [x] Refresh the guidebook's persistent title/back controls after a locale
  change and cover both locales in the existing guidebook validator.
- [x] Run a post-change dynamic-key audit before committing the CSV.

**Acceptance:** no confirmed retired stage, enemy, objective, result, or upgrade
key remains; Gate A has resolved the field-boss key; all current dynamically
generated keys still resolve in both languages.

### Milestone 3 — Extract the cold reward transaction owner

- [x] Add `scripts/rewards/vehicle_reward_runtime.gd` with reset, enqueue,
  next-source, active-source, offer-serial, stage-scoped claim, decline, and
  resolution APIs.
- [x] Move only the five reward state fields and their pure
  identity/queue/terminal-outcome rules out of `VehicleRun`.
- [x] Keep card offer construction, build mutation, experience consumption,
  encounter telemetry, UI/audio, mode transitions, and stage finalization in
  their existing owners.
- [x] Preserve priority exactly: pending level-ups first, then queued encounter
  reward sources, then stage completion after the boss reward is claimed.
- [x] Preserve retry/reset semantics and the once-per-stage reward identity.
- [x] Add focused tests for duplicate enqueue suppression, claim vs decline,
  stage identity, offer serial monotonicity, reset, and priority.
- [x] Run the codebase quality audit on the new public boundary and make only
  small task-scoped corrections.

**Acceptance:** reward behavior and UI snapshots are unchanged; `VehicleRun` no
longer owns reward transaction state; no per-frame call was added.

### Milestone 4 — Complete validation authority and plan reconciliation

- [x] Change CI to discover sorted `tools/validation/validate_*.gd` files and
  execute all 39, logging each separately.
- [x] Keep `profile_vehicle_pressure.gd` in a separately named diagnostic step
  whose failure/metrics cannot be mistaken for the rendered release gate.
- [x] Update the performance plan's dead validator commands to
  `validate_vehicle_projectile_store.gd` and the sorted validator loop.
- [x] Rewrite its unchecked hot-owner extraction phase to record the measured
  decision: bounded policy loops stay in `VehicleRun` unless a separately
  approved performance experiment proves a better boundary.
- [x] Move the tactical plan's remaining rendered performance checks and unique
  evidence links to the performance plan.
- [ ] Mark the tactical plan done in the same commit that proves no unique work
  remains; include it in the approved retirement batch.
- [ ] If Gate D is approved, align local Godot setup/resolution to
  `4.7.1-stable`; otherwise document the deliberate divergence.

**Acceptance:** local and CI test manifests match; active plans do not demand a
known-regressive architecture; exactly one active plan owns rendered
performance acceptance.

### Milestone 5 — Repair lifecycle and retire approved historical documents

- [ ] Redirect incoming links away from the three completed/superseded plans
  and the completed world-combat plan.
- [x] Remove the superseded single-field plan from the `related` lists in the
  active performance plan, performance evidence, and archived architecture
  audit; each already links the current product spec and performance owners.
- [x] Remove the completed world-combat plan from the difficulty study's
  `related` list. In world-combat evidence, replace its `source` with the
  implementing git commits `dddbc00`, `fbb115c`, `7150b47`, `79fad1d`,
  `6b95c26`, `d20a25f`, and closure `51b2168`, plus the current product spec;
  remove the dead `related` entry before changing that evidence to
  `status: archived`.
- [x] Verify the completed plans' durable outcomes at their locked owners:
  selected-field/five-stage/secondary/guidebook and world-combat behavior in the
  product spec; Korean overflow/focus/layout rules in `UI_VISUAL_SYSTEM.md` and
  the localization/UI validators; performance A/B rationale in the retained
  evidence. Do not copy progress logs.
- [x] Move current pixel production invariants out of
  `pixel-art-production/PLAN.md` into the pixel README and active recovery plan.
- [x] In `.agents/execplans/2026-07-27-pixel-art-visual-recovery.md`, replace
  the `related` link to `pixel-art-production/PLAN.md` with the current pixel
  README after its durable invariants are migrated.
- [x] In
  `pixel-art-production/evidence/gates/01-post-sampler-capability/README.md`,
  replace both the frontmatter `source` link and the body “Phase 1” source
  reference to `pixel-art-production/PLAN.md` with the migrated current pixel
  README/active recovery authority.
- [x] Archive and relink the world-combat performance evidence, space-hangar
  research, pixel gate/baseline, and pipeline sampler documents.
- [x] Replace the missing core-slice plan link with the active
  `2026-07-27-pixel-art-visual-recovery.md` link.
- [x] Confirm the UIUX direction's accepted rules are present in current visual
  authority and validators.
- [ ] Delete only the Gate-B-approved document manifest and six UIUX evidence
  PNGs.
- [ ] Run a repository-relative Markdown link audit after deletion.

**Acceptance:** no current index/link points at a deleted artifact; all
remaining lifecycle documents have truthful type/status/authority; current
authority contains the durable decisions.

### Milestone 6 — Retire approved disconnected tooling and local residue

- [x] Run the current Godot pixel publisher and every pixel validator.
- [x] Compare the live catalog/atlas contract against the superseded publisher's
  exact responsibilities: shared atlas composition, region and cell-region
  offsets, runtime atlas path rewriting, atlas SHA-256/size metadata, catalog
  output, and post-publish validation. Add a missing responsibility to the
  current generator/validator before deletion; otherwise make no parity change.
- [ ] Delete only the four approved disconnected pixel scripts.
- [ ] Verify no docs, CI, manifests, or scripts reference their paths.
- [ ] If Gate C is approved, re-resolve the exact ignored paths and delete only
  `build/object_compat_probe.gd` and/or the dated external-research cache.
- [ ] Report tracked and local deletions separately, including recoverability.

**Acceptance:** current pixel generation and validation are self-contained;
tracked deletion is recoverable from git; no unrelated ignored file is touched.

### Milestone 7 — Full validation, rendered QA, and lifecycle closure

- [ ] Import with the approved Godot version.
- [ ] Execute every sorted `validate_*.gd` script and the pressure profiler.
- [ ] Execute all pixel-production validators.
- [ ] Export the Web release through `tools/export_web.ps1`.
- [ ] Before starting a `D:\npjt` server, load the repo's port-guard workflow
  and use the fastrun manager's `codex` lane.
- [ ] Boot the built Web artifact and manually verify deployment, gameplay,
  pause, result, garage, settings, guidebook, upgrade choice, stage report, and
  Korean/English switching.
- [ ] Explicitly inspect alignment, typography, spacing, padding/gaps,
  overflow, and clipping at supported desktop/mobile widths if any rendered UI
  output differs.
- [ ] Re-run the legacy-term/reference searches and link audit.
- [ ] Run `git diff --check` and the task-scoped code quality audit.
- [ ] Commit each coherent phase with only task-owned files.
- [ ] Incorporate durable outcomes, mark this plan done momentarily for final
  review, then delete it per `.agents/PLANS.md`.

**Acceptance:** all product contracts pass locally and in CI; Web export boots;
no visible behavior changed except removal of impossible legacy fallback/copy;
no approved historical artifact remains in current authority; this plan no
longer has unfinished work.

## Test Plan

### Baseline already observed on 2026-07-28

- `tools/godot.ps1 --path . --headless --import` passed.
- All 40 `tools/validation/*.gd` scripts passed in this audit session, including
  the diagnostic profiler; elapsed suite time was approximately 102 seconds.
  The output was not saved as a tracked artifact, so implementation must rerun
  the suite and retain normal CI/per-script logs rather than treating this
  observation as release evidence.
- All 603 localization rows had complete Korean and English values with no
  duplicate keys.
- The worktree was clean before the plan artifact was added.
- A Web export was not run for this read-only audit because no runtime source
  changed. It becomes mandatory for implementation handoff.

### Exact implementation commands

Import:

```powershell
.\tools\godot.ps1 --path . --headless --import
```

Run all contract validators in deterministic order:

```powershell
$validators = @(
  Get-ChildItem -LiteralPath '.\tools\validation' -Filter 'validate_*.gd' |
    Sort-Object Name
)
foreach ($validator in $validators) {
  .\tools\godot.ps1 --path . --headless `
    --script "res://tools/validation/$($validator.Name)"
  if ($LASTEXITCODE -ne 0) {
    throw "Validator failed: $($validator.Name)"
  }
}
```

Run the diagnostic profiler separately:

```powershell
.\tools\godot.ps1 --path . --headless `
  --script res://tools/validation/profile_vehicle_pressure.gd
```

Run pixel validators:

```powershell
$pixelRoot = '.\pixel-art-production\tools\validation'
$catalog = 'pixel-art-production/runtime/catalog.json'
& "$pixelRoot\validate_pixel_asset_pipeline.ps1"
& "$pixelRoot\validate_pixel_asset_catalog.ps1" -CatalogPath $catalog
& "$pixelRoot\validate_pixel_asset_frame_budget.ps1" -CatalogPath $catalog
& "$pixelRoot\validate_pixel_asset_import_settings.ps1" -RuntimeTexturePaths @(
  'pixel-art-production/runtime/atlases/cardborne-pixel-atlas.png',
  'pixel-art-production/runtime/tiles/hangar-floor.png',
  'pixel-art-production/runtime/tiles/hangar-wall.png',
  'pixel-art-production/runtime/tiles/hangar-water.png'
)
& "$pixelRoot\validate_pixel_asset_palettes.ps1"
& "$pixelRoot\validate_pixel_asset_reviews.ps1" -ReviewMetadataPaths @(
  'pixel-art-production/assets/examples/player-craft-build-v2/review.json',
  'pixel-art-production/assets/examples/projectile-proof/build/review.json'
)
& "$pixelRoot\validate_pixel_asset_seams.ps1" `
  -ManifestPath 'pixel-art-production/assets/manifests/candidates/phase-1/phase1_wall_cover_tiles.manifest.json' `
  -ProofOutputPath 'build/pixel-validation/wall-cover-seam-proof.png'
& "$pixelRoot\validate_pixel_source_overrides.ps1" -CatalogPath $catalog
```

Export:

```powershell
.\tools\export_web.ps1
```

Static residue checks:

```powershell
rg -n -uu "STAGE_FLOODED_WORKS|NOTIFY_FIELD_BOSS_SHARD|optional field bosses" `
  . -g '!.git/**' -g '!.godot/**' -g '!build/**' -g '!.codex-runtime/**'
rg -n -uu "validate_vehicle_projectile_runtime|run_all_validations" `
  .agents docs pixel-art-production -g '*.md'
rg -n -uu "publish_pixel_runtime|build_pixel_hangar_mvp_set|create_pixel_hangar_reference_contact_sheet|create_projectile_pixel_sheet" `
  . -g '!.git/**' -g '!.godot/**'
git diff --check
```

Expected exceptions must be explicit. For example, a historical archived
evidence note may discuss a retired term, but no active policy/spec/runtime
source may use it as current behavior.

## Rollback and Safety

- Make separate commits for domain/current-state corrections, reward extraction,
  validation authority, document lifecycle cleanup, and pixel-tool retirement.
- Do not stage or rewrite unrelated user changes.
- Before each tracked deletion, use `rg` to prove the path has no current
  incoming references and record the exact manifest in the commit.
- Tracked deletions can be restored from the immediately preceding commit.
- Revert the reward-runtime commit as a unit if behavior or performance differs;
  do not partially duplicate reward state in both owners.
- If localization validation fails, restore the affected rows and classify the
  missed dynamic lookup before continuing.
- If the current pixel publisher cannot reproduce a required output invariant,
  stop the publisher deletion and move that invariant into the current
  generator/validator first.
- Resolve ignored local targets to absolute paths under this workspace before
  deletion. Never delete the whole `build/`, `.codex-runtime/`, workspace root,
  home directory, or a computed broad path.
- Do not weaken lockfiles, package safeguards, action pinning, or export checks.

## Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| A live script appears unreferenced because of dynamic loading | Runtime deletion is prohibited by the locked decision; all 80 are retained. |
| Dynamic localization keys are removed | Use the exact manifest plus current dynamic-prefix whitelist and post-change validator. |
| Reward refactor changes queue priority or once-only claims | Extract state only, preserve orchestrator effects, and add focused invariant tests. |
| More indirection regresses hot-loop performance | New reward owner is cold; no per-frame calls or enemy/projectile movement occurs. |
| Historical evidence is deleted before its durable lesson moves | Gate every deletion on source-to-authority migration and incoming-link audit. |
| Archived evidence competes with current specs | Truthful `status: archived`, corrected `related`, no current index placement, and explicit non-authority language. |
| CI duration grows after running 39 validators | Current local suite is ~102 seconds and CI has 35 minutes; keep per-script logs so any future bottleneck is visible. |
| Local/CI Godot patch mismatch hides a platform difference | Gate D makes the choice explicit and validates editor plus Web templates. |
| UI result contract crashes on malformed debug data | Update all three known callers/fixtures and add a contract validator before removing the fallback. |
| Deletion scope expands through directory cleanup | Use exact manifests; collateral deletion is limited to the six named UIUX images and approved dated cache. |

## Contingencies

- **New runtime file appears before execution:** trace it from scenes/resources
  and add an individual inventory verdict before changing anything.
- **A retirement candidate gains a live reference:** remove it from the
  retirement manifest and classify its owner; do not shim the reference merely
  to preserve the deletion.
- **Gate A preserves the optional field-boss requirement:** leave root AGENTS
  and `NOTIFY_FIELD_BOSS_SHARD` untouched. Neutral README/result/pixel cleanup
  may proceed, but stop this plan before domain-alignment completion and create
  a separately approved product/implementation plan for the missing feature.
- **Tracked deletion approval is partial:** execute only approved rows and apply
  the archive-in-place fallback to denied lifecycle docs.
- **Godot 4.7.1 alignment is denied:** preserve both pins and document the
  deliberate patch split; do not change CI down or local setup up implicitly.
- **Reward extraction expands beyond the five state fields/pure rules:** stop
  and revise this plan before absorbing UI, build behavior, telemetry, or
  per-frame simulation.
- **Pixel parity is not proven:** retain `publish_pixel_runtime.ps1` and record
  the unique contract in the active recovery plan.
- **Any full validator or Web gate fails:** stop before document/tool deletion
  closure, fix only task-caused regressions, and preserve the failure log.

## Open Questions

No unresolved technical research remains. Gate A is an explicit product
decision, and Gates B–D are exact authority checks for destructive, local-only,
and dependency actions; each gate has a deterministic stop/fallback path.

## Decision Notes

- **2026-07-28 — Runtime retention:** all 80 application scripts are reachable
  from the current Godot/resource graph. No tracked runtime deletion is
  justified.
- **2026-07-28 — Product lineage:** commit `547b805` already retired the former
  platformer/isometric/3D code; commit `cb40059` retired five separate stage
  maps. Remaining old language is documentation/localization residue.
- **2026-07-28 — Field model:** use “one run-selected field across five stages,”
  not “one drowned-ruin field” and not “five maps.”
- **2026-07-28 — Boss model:** current code/spec implement quota-gated stage
  bosses; protected root guidance additionally requires optional field bosses.
  Gate A, not reachability, resolves that authority conflict.
- **2026-07-28 — Architecture:** line count alone does not justify a split.
  Extract the cold reward transaction owner; retain measured hot policy loops
  in `VehicleRun`.
- **2026-07-28 — Evidence lifecycle:** completed plans/handoffs are deleted
  after durable integration; reproducible or unresolved evidence is retained
  with truthful lifecycle status.
- **2026-07-28 — CI:** all current contract validators become authoritative;
  the pressure profiler remains diagnostic.

## Progress

- [x] Read active governance, product, visual, plan, and lifecycle authority.
- [x] Inventory all application, root tool, pixel tool, and document sources.
- [x] Trace the Godot boot/resource graph and classify all runtime scripts.
- [x] Review relevant product-pivot/shared-field history.
- [x] Audit domain language and state ownership.
- [x] Audit document lifecycle, authority overlap, and broken links.
- [x] Run Godot import and all 40 validation scripts.
- [x] Record exact retirement/retention manifests and validation strategy.
- [ ] Obtain execution approvals.
- [ ] Implement Milestones 1–6.
- [ ] Complete full rendered/Web validation.
- [ ] Integrate durable outcomes and delete this completed plan.

## Next Steps

1. BK reviews this audit outcome and, when implementation is requested, resolves
   Gate A and grants only the desired Gate B–D authorities.
2. The executor starts at Milestone 0, reconfirms the clean task scope, and
   follows the milestone order without broadening the retirement manifests.
3. Each milestone is handed off as a coherent task-owned commit; destructive
   cleanup occurs only after its source-to-authority migration and validation
   gate pass.

## Completion Criteria

This plan is complete only when:

1. Gate A authorizes retirement of the conflicting optional field-boss
   instruction, and current authority accurately describes one selected field,
   five stages, and stage bosses; otherwise this plan stops and hands the
   preserved requirement to a separate product plan;
2. all current Korean/English surfaces remain complete, the 58 confirmed
   retired keys are gone, and the field-boss key matches the Gate A decision;
3. reward transaction state has one cold-path owner with focused invariants;
4. all 39 contract validators run locally and in CI, with the profiler clearly
   diagnostic;
5. active performance guidance matches measured architecture evidence;
6. approved completed/superseded docs and disconnected scripts are removed,
   while retained evidence has truthful lifecycle status;
7. import, all validators, pixel validation, Web export, and built-app QA pass;
8. no broken current links or references to deleted paths remain;
9. coherent task-owned commits exist and no unrelated worktree change was
   staged or reverted;
10. this plan's durable decisions are in current specs/policies and the plan is
    deleted according to repository lifecycle policy.

## Stop Conditions

Stop execution and report evidence if:

- the current boot/resource graph no longer reaches a script classified current;
- a supposedly retired artifact has a live consumer or unique unresolved
  decision;
- a requested deletion or protected edit lacks the corresponding approval;
- the reward boundary requires per-frame calls or ownership of UI/build
  behavior;
- localization dynamic-key coverage cannot be proven;
- the Godot patch cannot import/export the current project;
- a task-caused validator, pixel validator, Web export, or built-app flow fails;
- unrelated user changes overlap a task-owned file and cannot be preserved.

## Handoff

The next executor should begin at Milestone 0, use the exact manifests rather
than rediscovering candidates from filenames, and preserve the central audit
finding: the current runtime is coherent. Cleanup should remove authority noise
and cold-path responsibility creep without reopening product pivots or
restructuring performance-sensitive simulation on aesthetic grounds.
