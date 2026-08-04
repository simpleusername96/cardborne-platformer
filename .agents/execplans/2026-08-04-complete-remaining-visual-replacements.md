---
type: plan
status: done
owner: BK
created: 2026-08-04
last_reviewed: 2026-08-04
scope: Autonomous consolidation, comparison reporting, application, retirement, and final validation for the remaining Cardborne visual replacement program
supersedes: ./2026-08-02-visual-replacement-workbench-and-runtime-switch.md
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../design/DESIGN.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/design/cardborne-universal-art-style-reference.png
  - ../../docs/design/visual-replacement-workbench/README.md
  - ../../docs/design/visual-replacement-workbench/asset-rationalization.md
  - ../../art/visuals/production/README.md
  - ../semantic-v2-runtime-acceptance-evidence.md
  - ./2026-08-02-pre-asset-code-stabilization.md
---

# Finish the 49-PNG Visual Replacement Program

## Purpose

Finish the remaining visual replacement work as one autonomous pipeline:
prepare the workbench, generate every required image in one bounded production phase,
publish one AS-IS/TO-BE report, apply the complete batch, retire exact legacy
paths, and run one final relevant integration gate. No step waits for user
approval. The user may optionally flag suspicious comparisons in the report.

Completion means exactly 49 production gameplay PNGs: 47 authored outputs and
two reused outputs. The switch must also remove 177 listed legacy PNGs and their
177 literal `.png.import` sidecars without changing gameplay truth.

## Why / Context

The superseded plan repeated counts, approval rules, and validation steps across
764 lines and paused after each visual family. The current authorization replaces
that serial process with complete-batch production and non-blocking review.

## Scope and Non-Scope

In scope:

- Make the existing workbench support autonomous exact-hash acceptance.
- Keep or generate all 47 authored PNGs under the existing TO-BE root in one phase.
- Extend the existing bilingual HTML into the single complete comparison report.
- Migrate live consumers, apply exact outputs, and retire 354 literal paths.
- Run structural guards only when their inputs change and one final integration
  gate after the complete switch.

Out of scope:

- Gameplay, collision, targeting, timing, drop value, encounter, save, or
  difficulty changes.
- Another production UI layout redesign, external asset search, direct use of
  external source pixels, or restoration of non-EMP raster effect frames.
- The known physics p95/p99 and 600-second lifecycle release gap. It remains in
  `2026-08-02-pre-asset-code-stabilization.md` and does not block this plan.

Authorization and invariants:

- Further user approvals required: **none** within this locked scope. Generation,
  technical acceptance, switching, migration, and exact retirement proceed
  automatically. Silence and optional report feedback never pause execution.
- The mandatory authority pair is `docs/design/VISUAL_SYSTEM.md` and
  `docs/design/cardborne-universal-art-style-reference.png` at SHA-256
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`.
- Every raster generation/edit passes the PNG as an **actual image reference**
  and records `visual_authority_evidence`. The sheet defines style grammar, not
  individual asset approval.
- No wildcard deletion, broad cleanup, hard reset, or unrelated worktree change.

## Assumptions

- Godot 4.7 stable, GDScript, existing responsibility owners, and the current
  product behavior remain fixed.
- Workbench truth: 16 units = 10 target units, two `keep_current`, four
  `retired`; current production = 215 gameplay PNGs.
- Agent capacity may require bounded waves, but all images belong to one Phase 7
  batch and none enters production before the whole batch passes.

## Discovery Closure

| Closed question | Verified source | Locked answer |
| --- | --- | --- |
| Visual authority | Visual system, canonical sheet, local authority skill | Use the pair for every prompt, edit, review, and evidence record |
| Final inventory | Workbench and rationalization report | Player 1; enemies 19; bosses 5; nodes 3; secondaries 4; shared projectile 1; defense/status 0; pickups/rewards 4; world/facilities 11; EMP 1 |
| Output work | Workbench deliverables | 36 in-place replacements + 11 additions + player/solid-cover reuse = 49 finals |
| Review surface | Existing template, inventory, and index | Extend it; do not create another report system |
| Acceptance | Current user authorization and workbench model | Automated exact hashes and paths; never wait for a response |
| Runtime ownership | Manifest, semantic provider, catalogs, renderers | One live owner per ID; world objects raster, dynamic HUD/cues code-native |
| Retirement | Ten target units | Remove only 177 PNGs + 177 exact sidecars after zero-consumer proof |
| Verification | Repo guidance and focused tools | Candidate guards in production; one relevant final gate at the end |

All product, UX, media, ownership, authorization, deletion, and validation
decisions needed to execute are closed. Implementation-local corrections stay
inside this plan.

## Proposed Design

1. Make the current workbench autonomous and freeze its mapping.
2. Give bounded subagent workstreams the same actual reference sheet and
   family-specific rules; produce all required raster files during one phase.
3. Regenerate only failed targets until the complete batch passes.
4. Publish all AS-IS/TO-BE evidence in the existing `index.html`. Each target
   shows files, images, actual-scale evidence, hashes, consumers, and retirements.
5. Let the user mark **Needs attention**, add a short note, filter issues, and
   Copy/Download an issue list. Browser-local flags are optional and non-blocking.
6. Record autonomous exact-hash readiness, apply the whole batch, migrate
   consumers, and retire only proved paths.
7. Freeze one final HEAD and validate the complete result once.

Keep `approved_for_switch` only as the existing exact-hash technical state so
historical BK ledgers remain valid. New ledgers may use
`approved_by=autonomous-executor`; this is not user confirmation or a wait state.

## Tasks

### Phase 6 - Prepare autonomous batch execution

- [x] **6.1 Remove the response interlock.** Update the workbench model,
  validator, promotion helper, data contract, and README to accept autonomous
  exact-hash ledgers while preserving historical BK records. Hash/path drift must
  still fail closed; no `target_required` unit may require a user response.
- [x] **6.2 Add optional anomaly controls.** Add Needs attention, note,
  issue-only filter, and Copy/Download output to the existing static KO/EN report.
  Replace user-facing approval/promotion controls with read-only Technical status;
  preserve keyboard access, visible focus, responsiveness, and reduced motion.
- [x] **6.3 Freeze the mapping.** Rebuild and record HEAD, projection fingerprint,
  and authority evidence. Require exact reconciliation: 215 current, 49 final,
  47 authored, two reused, 177 retiring PNGs, 354 literal retirement paths.

Phase gate: deterministic workbench; no candidate promoted.

### Phase 7 - Generate the initial image batch

Every workstream receives the full current visual system and canonical sheet as
an actual image reference. Produce complete world-object PNGs, not user-assembled
parts. Broad planes, sparse functional detail, one dominant silhouette, at most
two functional modules, and grayscale role separation are mandatory.
Every raster call uses image generation with the canonical sheet included in
`referenced_image_paths`. Each subagent owns exact targets and evidence only;
production/runtime writes are forbidden until the whole batch passes.

- [x] **7.1 Workstream A — initial 16 files.** Nine projectiles + seven
  defense/status candidates were generated. This output was later rejected by
  the user-directed simplification in Phase 8.4 and is not part of the final count.
- [x] **7.2 Workstream B — 12 files.** Four pickups/rewards + seven pre-wear
  world/facility outputs + one 512x512 EMP; keep solid-cover bytes. Check value
  role, footprint/boundary, state, canvas, alpha, and grayscale.
- [x] **7.3 Workstream C — 19 files.** All ordinary enemy bodies as one family.
  Each role must read at 1x/grayscale using 3–5 large planes.
- [x] **7.4 Workstream D — 15 files.** Four secondaries + three wear states +
  five bosses + three shared-node states. Preserve facing/state; bosses use 4–6
  planes; node states differ structurally, not only by color.
- [x] **7.5 Correct the batch.** Build actual-scale family sheets, grayscale
  views, projectile collision overlays, facility footprint overlays, and
  persistent comparison plates under `previews/final-batch/`. Regenerate only
  failing targets until exactly 62 candidates and evidence records pass.

Historical phase gate: the initial 62 candidates existed under `to-be/assets`;
none entered production.

### Phase 8 - Publish one report and continue automatically

- [x] **8.1 Build `inventory.json` and `index.html`.** Show all 16 units and every
  current/final target exactly once with AS-IS/TO-BE imagery, comparison plates,
  hashes, provenance, consumers, runtime changes, and retirement paths. Missing,
  invalid, or authority-ungrounded candidates must be visibly flagged.
- [x] **8.2 Expose optional issue reporting, then keep working.** Share the local
  report path in a progress update but request no response and wait for none.
  A received valid flag reopens only that target; a late flag is fixed forward.
- [x] **8.3 Record technical readiness.** After automated checks and executor
  review, write exact autonomous ledgers for all ten target units.

### Phase 8.4 - Simplify the review batch and republish the report

- [x] **8.4.1 Revise the visual contract and workbench.** Limit the minimap to
  player, item, enemy, and boss markers; remove all seven defense/status raster
  overlays; consolidate nine projectile identities into one tailless energy-
  teardrop master; make repair and overdrive complete circular floor pads; rename
  unclear report groups. Reconcile 49 final, 47 authored, two reused, and 177
  retiring PNGs before generation.
- [x] **8.4.2 Generate the complete changed image set in one stage.** Using the
  canonical sheet as the actual image reference, generate and normalize exactly
  the shared projectile, circular repair pad, and circular overdrive pad. Remove
  superseded projectile, defense/status, and overdrive-lane candidates from the
  active TO-BE tree. Preserve all unaffected approved candidates.
- [x] **8.4.3 Republish the single AS-IS/TO-BE report.** Add one code-native
  minimap diagram containing exactly four marker roles, rebuild comparison plates,
  inventory, and `index.html`, then record fresh exact-hash technical readiness.
  Validate only report/candidate contracts and rendered report layout. Stop at
  this report boundary; do not modify production assets or runtime consumers.

Phase gate: the local report exposes every current/final target exactly once,
forecasts 49 production PNGs, and is ready for optional user anomaly marking.

### Phase 9 - Apply the batch and retire legacy paths

- [x] **9.1 Switch exact candidate hashes and migrate consumers.** Update only
  existing manifest/provider/catalog/preview/EMP/effect-suppression and
  code-native HUD/minimap/combat-cue and defense/status owners. Require one live
  owner per semantic ID. All projectile consumers resolve one shared raster ID.
- [x] **9.2 Prove zero consumers, then retire.** Scan runtime, resources, manifest,
  provider, guidebook, and validators for every planned path; remove only the 177
  listed PNGs and 177 exact sidecars. No live reference or unlisted deletion.
- [x] **9.3 Rebuild evidence and make responsibility-shaped commits.** Production,
  workbench, application ledgers, and Git history must describe the same batch.

### Phase 10 - Reconcile and freeze

- [x] **10.1 Reconcile exactly 49 final PNGs** against the fixed family split;
  authored HUD/cue PNGs and non-EMP effect frames remain zero.
- [x] **10.2 Run `codebase-quality-auditor`** over changed shared owners. Fix
  task-scoped competing ownership, catch-all rendering, or gameplay leakage.
- [x] **10.3 Rebuild the deterministic report and freeze clean final HEAD.** Any
  later correction creates and records a new final HEAD before Phase 11 reruns.

### Phase 11 - Run one final relevant gate and close

- [x] **11.1 Structural/runtime gate.** Run the commands and focused validators
  named below once from frozen HEAD.
- [x] **11.2 Rendered gate.** Capture KO/EN at 960x540, 1280x720, and 1920x1080,
  plus KO/EN 960x540 at 200% text; build Web, serve it through the
  `npjt-port-guard` Codex lane, and inspect changed actors, HUD, projectiles,
  facilities, states, focus, clipping, and EMP.
- [x] **11.3 Visual performance and closure.** Run one peak-horde diagnostic;
  require draw-call p95 <= 200 and combat batches <= 50. Record commands, hashes,
  captures, metrics, commits, and anomaly dispositions. Incorporate any changed
  durable behavior into its active spec/guidance, mark this plan `done`, then
  delete it under `.agents/PLANS.md`. The separately owned known physics failure
  does not fail this visual contract.

## Test Plan

| Cadence | Check | Trigger |
| --- | --- | --- |
| Candidate guard | Projection, authority evidence, PNG canvas/pivot/alpha/hash, role comparison | Candidate or authority input changes |
| Retirement guard | Exact consumer scan for 354 literal paths | Consumer or retirement list changes |
| Final gate | Commands, focused Godot validators, capture matrix, built-Web smoke, one visual diagnostic | Frozen final HEAD changes |

Final structural commands:

```powershell
.\tools\design\build_visual_replacement_workbench.ps1
.\tools\design\build_visual_replacement_workbench.ps1 -Check
.\tools\validation\validate_cardborne_visual_authority.ps1
.\tools\validation\validate_visual_replacement_workbench.ps1
.\tools\godot.ps1 --path . --headless --import
```

Run these focused Godot validators through `tools/godot.ps1 --path . --headless
--script res://tools/validation/<name>` and stop on a nonzero exit:

`validate_vehicle_visual_asset_coverage.gd`,
`validate_vehicle_visual_replacement_coverage.gd`,
`validate_vehicle_semantic_asset_provider.gd`,
`validate_vehicle_semantic_visual_separation.gd`,
`validate_vehicle_actor_visuals.gd`, `validate_vehicle_projectile_store.gd`,
`validate_vehicle_reward_facility_visual_recipes.gd`,
`validate_vehicle_secondary_weapons.gd`, `validate_vehicle_status_stacking.gd`,
`validate_vehicle_wear_collapse_tiles.gd`, `validate_vehicle_world_visuals.gd`,
`validate_vehicle_combat_renderer.gd`, `validate_vehicle_damage_feedback.gd`,
`validate_vehicle_hud_presenter.gd`, `validate_vehicle_stage_ui_layout.gd`,
`validate_vehicle_ui_localization.gd`, `validate_vehicle_guidebook.gd`,
`validate_vehicle_upgrade_ui.gd`, `validate_vehicle_boss_runtime.gd`, and
`validate_vehicle_run_capture_driver.gd`.

Then execute the Phase 11 capture matrix and `tools/export_web.ps1`. Do not run
the complete validation corpus, repeat full validation per family, or rerun a
passing check whose relevant input did not change.

## Rollback / Safety

- Preserve pre-switch plates and the batch fingerprint; apply exact target hashes.
- Delete only sorted literal `retire_paths` after zero-consumer proof.
- Fix applied defects with forward scoped commits; never hard-reset unrelated work.
- If a consumer remains, retain that exact legacy file, fix the consumer, rebuild
  evidence, and retire it without reopening unaffected units.

## Risks

- **Parallel style drift:** one actual reference, shared family rules, and one
  consolidated review.
- **Missed anomaly:** optional issue tools help the user, while executor review
  remains responsible and non-blocking.
- **Stale consumer:** exact reference scans block only the affected retirement.
- **Batch correction cost:** persistent evidence and scoped commits support narrow
  forward fixes without restoring serial approvals.

## Open Questions

None. No material product, visual, ownership, authorization, deletion, or
validation decision remains unresolved.

## Decision Notes

- Generate all changed raster deliverables in one bounded stage using delegated
  asset workstreams and one canonical authority pair.
- User-directed simplification supersedes the initial nine-projectile and seven-
  defense/status candidate families before any production switch.
- Use the existing HTML workbench as the only AS-IS/TO-BE report.
- Treat user issue flags as optional feedback, never an approval interlock.
- Automate exact technical ledgers and retirement safety.
- Run the full relevant validation once after the complete switch.

## Progress and Next Steps

- Canonical progress is the task list above; do not mirror it elsewhere.
- Completed groundwork: corrected 215-to-64 model, authority binding, external
  source curation, and rejection of ungrounded projectile drafts.
- Completed: Phases 6-8 produced the initial report; its 64-PNG media split was
  superseded before any production switch.
- Completed: Phases 9-11 applied the 49-file batch, migrated runtime owners,
  retired the exact 354-path legacy set, reconciled the report and ledgers,
  passed all visual structural/rendered gates, and met draw-call and combat-batch
  limits. The separately owned frame/physics release gap remains recorded and
  does not block this completed visual plan.

## Completion and Stop Conditions

Complete when every task passes, the 49-file split and all owners/retirements
reconcile, the consolidated report records anomaly dispositions, the single final
gate passes, changed durable decisions are incorporated, and this completed plan
is retired under `.agents/PLANS.md`.

Replan only for a verified change to product behavior, media boundary, dependency,
external source, final count, or destructive scope. Do not stop for silence, one
failed candidate, a late anomaly flag, the separately owned physics gap, or a
contained implementation correction.
