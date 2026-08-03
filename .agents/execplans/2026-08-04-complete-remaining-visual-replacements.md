---
type: plan
status: active
owner: BK
created: 2026-08-04
last_reviewed: 2026-08-04
scope: Corrected Phase 6-11 program for external-source-assisted authored PNG production, HUD/cue migration, exact retirement, reconciliation, and one final release validation
supersedes: ./2026-08-02-visual-replacement-workbench-and-runtime-switch.md
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/design/visual-replacement-workbench/README.md
  - ../../docs/design/visual-replacement-workbench/asset-rationalization.md
  - ../../docs/design/visual-replacement-workbench/external-candidates/README.md
  - ../../art/visuals/production/README.md
  - ../semantic-v2-runtime-acceptance-evidence.md
---

# Finish the 64-PNG Visual Replacement Program

## Purpose

Complete the remaining Cardborne visual replacement work with one unambiguous
media rule: every independently readable game-world object is a finished PNG;
only HUD/minimap/combat symbols and live dynamic boundaries are code-native.

The completed program must produce:

- exactly **64 production gameplay PNGs**;
- finished PNGs for actors, projectiles, defense/status objects, pickups, the
  reward crate, functional facilities, bulkhead states, wear tiles, and EMP;
- one shared XP-master PNG instead of three size files;
- one shared repair-pad PNG instead of a body/core pair;
- three shared boss-node state PNGs instead of ten boss-specific module files;
- one transparent 512 x 512 EMP PNG instead of six animation frames;
- zero HUD/minimap/combat-cue PNGs;
- zero other raster effect frames;
- complete license and provenance records for every external source used;
- one full native/Web release validation after every visual switch is complete.

## Why / Context

Phases 1-5 established the flat-color general-SF style, simplified the UI, and
created an exact-hash workbench. The first extracted Phase 6-11 plan then moved
too many meaningful world objects to code-native geometry. That reduced the
forecast to 36 PNGs, but it violated the user's product rule and would have made
bullets, pickups, crates, status devices, and facilities feel like fragmented
UI primitives instead of complete game assets.

The corrected audit establishes these facts:

- current production contains 215 gameplay PNGs: 114 static images and 101
  effect-frame images;
- no third-party gameplay/UI pack was evaluated or imported before this audit;
- six CC0 Kenney PNGs are now retained as review-only silhouette sources;
- Particle Pack and Sci-Fi RTS were inspected and rejected for style mismatch;
- the project-generated EMP review candidate is a single clean 512 x 512 PNG;
- the correct final target is 64 PNGs, not 36;
- 62 authored outputs remain: 53 in-place replacements and nine additions;
- 160 current PNGs retire only after exact consumer migration and approval.

This document is the sole executable Phase 6-11 contract. The former 36-PNG
boundary is withdrawn wherever it conflicts with this plan, the rationalization
evidence, or `VISUAL_SYSTEM.md`.

## Scope and Non-Scope

### In scope

- Rebuild the workbench units around the corrected authored-PNG boundary.
- Preserve exact current AS-IS paths and add exact final TO-BE target paths.
- Use curated external source files only as silhouette and proportion references.
- Produce complete PNG families for projectiles, defense/status, pickups/rewards,
  facilities/world states, secondaries, enemies, bosses, boss nodes, wear tiles,
  and EMP.
- Reuse the current player craft and solid-cover bytes unless actual-scale
  evidence exposes a concrete contract failure.
- Migrate 43 HUD/minimap/combat-cue images to shared code-native symbols or
  verified absence.
- Retire 101 current effect frames, replace the six EMP frames with one PNG, and
  suppress the other 21 small effect families for now.
- Update runtime consumers, guidebook/report previews, manifests, providers,
  validators, and evidence for every approved unit.
- Retire exact legacy paths and `.png.import` sidecars only after explicit
  exact-report approval.
- Run the complete release validation once at the end.

### Out of scope

- Gameplay rules, collision truth, damage, range, targeting, movement, encounter
  timing, drop values, facility behavior, or save compatibility changes.
- Another UI layout redesign. This plan changes only remaining visual ownership
  and asset presentation.
- Direct runtime use of external pack files, pack palettes, pack branding,
  isometric camera angles, or unadapted 3D models.
- Importing complete external packs into production.
- Restoring a one-file-per-frame effect pack or adding new small cosmetic effects.
- Merging semantic roles merely because two assets can share a drawing recipe.
- Re-running the complete release suite after each family.

## Assumptions

- Godot 4.7 stable and the existing GDScript architecture remain fixed.
- Korean and English user-facing content remain complete.
- Current gameplay geometry and state owners remain authoritative.
- The current player craft and solid cover remain acceptable unless rendered
  evidence proves otherwise.
- Every world-object PNG keeps a stable canvas and pivot. Runtime may rotate,
  scale, tint, fade, or select a state, but may not assemble a supposedly complete
  object from user-visible decorative parts.
- External source licenses and hashes are evidence, not approval to promote a
  visual.
- Cheap structural checks during Phases 6-10 prevent mechanical corruption; they
  are not substitutes for the one complete Phase 11 validation.
- No existing deletion approval covers the corrected 160-file retirement set.

## Proposed Design

### Final ownership model

| Family | Final PNGs | Owner and rule |
| --- | ---: | --- |
| Player craft | 1 | Authored raster; reuse current bytes. |
| Ordinary enemies | 19 | Authored raster; one complete body per gameplay role. |
| Stage bosses | 5 | Authored raster; one complete body per boss. |
| Shared boss nodes | 3 | Authored raster; shared `active`, `damaged`, `resolved`. |
| Secondary weapons | 4 | Authored raster; seeker, escort drone, orbit blade, wake mine. |
| Projectiles | 9 | Authored raster; complete core-and-tail image per semantic projectile. |
| Defense/status | 7 | Authored raster; four defense devices and three persistent statuses. |
| Pickups/rewards | 4 | Authored raster; XP master, crate, repair, recall. |
| World/facilities | 11 | Authored raster; bulkheads, repair/overdrive/arc/transit, cover, wear states. |
| EMP | 1 | Authored raster; one 512 x 512 transparent pulse. |
| HUD/minimap/combat cues | 0 | Shared code-native symbols or verified absence. |
| Other small effects | 0 | Suppressed for this pass; event intent documented only. |
| **Total** | **64** | |

### Exact reconciliation

```text
215 current
-43 HUD/minimap/combat-cue PNGs
-101 current effect-frame PNGs
-10 boss-specific module PNGs
-3 XP-size PNGs
-1 repair-pad-core PNG
-2 unused world PNGs
+3 shared boss-node PNGs
+1 XP-master PNG
+1 bulkhead-open PNG
+3 wear-tile PNGs
+1 EMP PNG
=64 final
```

### Authored PNG contract

- Each image has one dominant silhouette that communicates role at 1x gameplay
  scale and in grayscale.
- Ordinary assets use 3-5 large filled planes; bosses use 4-6.
- A functional object may have at most two visually necessary modules.
- Dark perimeter/separation, matte main mass, one light plane, one shadow plane,
  and one semantic accent are sufficient. Do not add rivets, random seams,
  repeated lights, nested outlines, ornamental dots, or greeble.
- Projectiles are complete PNGs. Their opaque damaging core matches collision;
  a restrained tail in the same canvas may communicate direction without damage.
- Facility art shows the object body; live radius, curtain, dwell, beam, or
  collision boundaries remain code-owned and must align visibly with the PNG.
- XP values share one master PNG and differ through gameplay-owned scale/emphasis.
- Repair-pad inset/core belongs inside the one pad PNG.
- Bulkhead and wear-tile states are separate authored state PNGs because their
  world-state transitions must remain visible.
- EMP is one hard-edged ring/pulse with a transparent background. Runtime ties
  its scale and fade to the real EMP radius and timing.

### External-source adaptation contract

- Only the six files registered under `external-candidates/sources/` are current
  retained external source candidates.
- Every derivative records official page, license, archive hash, selected-source
  hash, final prompt/brief, TO-BE hash, and target mapping.
- Source files remain review evidence. They never occupy production target paths.
- Redraw or re-render the selected silhouette into Cardborne's top-down camera,
  exact canvas/pivot, palette, perimeter, plane count, and semantic role.
- Reject a source when its lore, camera, texture, or detail density would require
  more correction than drawing the target directly.
- Add no further external file until a named target lacks a usable shape after
  project-authored design and the current curated sources are exhausted.

### Code-native boundary

- Shared code-native output is limited to HUD action/upgrade glyphs, minimap
  markers, combat cues, target brackets, off-screen vectors, live telegraph/
  beam/radius boundaries, progress/fuse ratios, text, focus, and debug overlays.
- A code-native renderer may not replace a persistent projectile, pickup, crate,
  defense/status device, facility, bulkhead, or EMP image.
- Shared cached geometry must have one catalog owner. Screen scripts own layout,
  copy, signals, and state only.

### Workbench result model

The rebuilt workbench must partition all 215 current PNGs exactly once:

| Unit family | Current PNGs | Final PNGs | Result type |
| --- | ---: | ---: | --- |
| Player craft | 1 | 1 | Reuse raster |
| HUD/minimap/combat cues | 43 | 0 | Code-native or absent |
| Small effects excluding EMP | 95 | 0 | Suppressed/direct feedback |
| EMP | 6 | 1 | Authored raster replacement |
| Projectiles | 9 | 9 | Authored raster replacement |
| Defense/status | 7 | 7 | Authored raster replacement |
| Pickups/rewards | 6 | 4 | Authored raster consolidation/replacement |
| World/facilities excluding wear | 10 | 8 | Reuse, authored replacement/addition, retirement |
| Secondary weapons | 4 | 4 | Authored raster replacement |
| Ordinary enemies | 19 | 19 | Authored raster replacement |
| Boss bodies/modules | 15 | 8 | Authored raster replacement/consolidation |
| Wear tiles | 0 | 3 | Authored raster addition |
| **Total** | **215** | **64** | |

Every unit records current paths, final target mappings, runtime-change paths,
retirement paths, exact SHA-256 values, rendered evidence, status, and approval.
An external source or preview cannot satisfy a TO-BE deliverable.

### Approval and application protocol

For each switch unit:

1. Freeze and record a clean baseline commit.
2. Generate or adapt the exact TO-BE files outside production.
3. Build deterministic actual-scale AS-IS/TO-BE evidence.
4. Run only structural/schema/import checks needed to trust the report.
5. Display the baseline hash, target mappings, TO-BE hashes,
   `runtime_change_paths`, and exact sorted `retire_paths`.
6. Obtain explicit approval for that exact report.
7. Preview the promotion command without writes.
8. Apply only the approved target copies, runtime changes, manifest/provider
   changes, and retirements.
9. Rebuild deterministic workbench evidence and create one scoped commit.
10. Record the applied commit and resulting hashes before starting another unit.

Any changed baseline, target hash, target mapping, runtime path, or retirement
path invalidates approval. A rejected candidate remains outside production.

## Milestones and Tasks

### Phase 6 - Correct ownership and complete world-object foundations

Outcome: all non-actor foundational world objects use finished PNGs, HUD/cues are
code-native, small effects are suppressed, EMP is one PNG, and production reaches
exactly **68 PNGs** before wear tiles and actor-family replacements.

#### 6.0 Freeze the corrected authority and execution baseline

- [x] Withdraw the former 36-PNG target.
- [x] Record the exact 64-PNG arithmetic and all current-file dispositions.
- [x] Audit prior external-asset history and confirm there was no earlier pack
  import or evaluation.
- [x] Curate six CC0 source PNGs with official URLs, licenses, archive hashes,
  source hashes, adaptation roles, and rejection reasons.
- [x] Create and validate one review-only 512 x 512 EMP PNG candidate.
- [x] Correct `VISUAL_SYSTEM.md`, production ownership guidance, workbench
  guidance, evidence, and this plan.
- [ ] Require a clean worktree and record the post-correction HEAD as the Phase 6
  execution baseline.
- [ ] Run `./tools/godot.ps1 --version` and require Godot 4.7 stable before runtime
  edits begin.

Acceptance: all active guidance agrees on 64 final PNGs and no runtime switch has
been implied by source import or candidate generation.

#### 6.1 Rebuild the workbench control plane

- [ ] Replace the old 36-PNG unit forecast with the exact partition in this plan.
- [ ] Add authored-raster units for projectiles, defense/status, pickup/reward,
  world/facility, EMP, secondaries/wear, enemies, and bosses/shared nodes.
- [ ] Keep one code-native unit for all 43 HUD/minimap/combat-cue paths.
- [ ] Keep one explicit suppression/retirement unit for the 95 non-EMP effect
  frames and one authored replacement unit for the six EMP frames.
- [ ] Model reuse, in-place replacement, consolidation, addition, runtime change,
  and exact retirement without fake PNG paths.
- [ ] Make generator and validators require license/provenance records whenever a
  TO-BE brief uses an external source.
- [ ] Rebuild `inventory.json` and `index.html` deterministically.

Acceptance: every current PNG belongs to one unit, every final target belongs to
one unit, and the generated forecast is exactly 64.

#### 6.2 Produce the nine projectile PNGs

- [ ] Preserve all nine semantic projectile identities and current target paths.
- [ ] Author complete core-and-tail PNGs at the existing canvas sizes and pivots.
- [ ] Use `laserBlue07.png` only as an optional silhouette seed for light/standard
  bolt proportion; do not reuse its pixels or palette directly.
- [ ] Differentiate faction, delivery, threat tier, and power by silhouette/core
  proportion before affinity hue.
- [ ] Render collision overlay comparisons for every projectile at 1x scale.
- [ ] Verify manual aim, muzzle origin, rotation, high-count batching, and
  non-damaging tail boundaries remain unchanged.

Acceptance: nine complete PNGs are ready for exact approval and no projectile is
assembled from visible runtime parts.

#### 6.3 Produce the seven defense/status PNGs

- [ ] Replace barrier plate, ion emitter, generator shield source, and escort
  shield plate with four complete role-readable PNGs.
- [ ] Replace burn, poison, and chill with three persistent-status PNGs that remain
  distinct in grayscale.
- [ ] Keep protection, timer, damage, attachment, and status-stacking logic in
  existing owners.
- [ ] Render attachment, orbit, overlap, grayscale, and maximum-pressure evidence.

Acceptance: all seven identities remain PNG-owned and no state is distinguished
by color alone.

#### 6.4 Consolidate pickups and rewards into four PNGs

- [ ] Add one exact XP-master target and map small/medium/large values to its
  gameplay-owned scale/emphasis.
- [ ] Replace reward crate, repair pickup, and experience recall at their current
  semantic targets.
- [ ] Use `bolt_gold.png` and `powerupYellow.png` only as optional silhouette seeds.
- [ ] Preserve drop tables, values, collection radius, recall behavior, and reward
  timing.
- [ ] Build an exact retirement report for the three old XP-size PNGs and sidecars.

Acceptance: four finished pickup/reward PNGs preserve four distinct meanings;
the three old XP files have no live consumer before retirement.

#### 6.5 Consolidate world and facilities into eight pre-wear PNGs

- [ ] Replace bulkhead `intact` and `damaged`; add `open` with one shared footprint.
- [ ] Replace the repair pad with one complete PNG and remove the separate core
  dependency.
- [ ] Replace overdrive lane, Arc Surge strip, and transit gate with complete PNGs
  aligned to their live footprints.
- [ ] Keep current solid-cover bytes.
- [ ] Use the three Space Kit source PNGs only for bulkhead/pylon/recessed-core
  proportion; rebuild all camera, palette, state, and semantic details.
- [ ] Preserve radius, curtain, dwell, cooldown, collision, topology, and map
  fingerprint ownership.
- [ ] Build exact retirement reports for repair-pad core, breakable cover slab,
  and hazard power relay.

Acceptance: the pre-wear world/facility family contains exactly eight PNGs and
every visible effect footprint agrees with gameplay geometry.

#### 6.6 Replace EMP and suppress the other small effects

- [ ] Review the project-generated EMP candidate at actual gameplay radius against
  the current six-frame AS-IS sequence.
- [ ] If accepted, adapt or copy it to the exact TO-BE target
  `effects/fx_emp_release.png`; otherwise generate one revised single-image
  candidate under the same contract.
- [ ] Bind one 512 x 512 texture to the existing EMP timer/radius with only
  scale/fade; do not add a sprite sequence or decorative particles.
- [ ] Map all 21 non-EMP effect identities to existing direct feedback or explicit
  `suppressed` state.
- [ ] Remove unconditional frame-path resolution from runtime, guidebook, manifest,
  provider, and validators.
- [ ] Produce exact retirement records for all 101 current effect PNGs and
  sidecars, including the six old EMP frames.

Acceptance: EMP has one authored PNG; all other small effect events remain
behaviorally intact without dedicated raster art.

#### 6.7 Migrate the 43 HUD/minimap/combat-cue PNGs

- [ ] Reuse shared action/upgrade glyph recipes for Seeker, Dash, EMP, and eight
  upgrade families.
- [ ] Add or consolidate one shared owner for minimap markers, target/priority,
  collective, elite, boss-core, objective, and commitment cues.
- [ ] Prove nine direct-orphan HUD/cue files have no live consumer before marking
  them absent.
- [ ] Preserve layout, slot count, localization, focus, accessibility, input, and
  information content.
- [ ] Render KO/EN actual-size evidence at supported viewports without running the
  complete final responsive suite.

Acceptance: all 43 paths have one code-native/absent result and no meaningful
world object was included in this migration.

#### 6.8 Approve and apply Phase 6 units

- [ ] Produce separate exact reports for projectiles, defense/status,
  pickups/rewards, world/facilities, EMP/effects, and HUD/cues.
- [ ] Obtain explicit approval for each exact baseline, hash map, target mapping,
  runtime path set, and retirement set.
- [ ] Apply each approved unit in one scoped commit without staging unrelated work.
- [ ] Rebuild workbench outputs and run deterministic/schema/import guards after
  each unit.
- [ ] Record applied commits and confirm production contains exactly 68 PNGs.

Phase gate: 68 production PNGs, no stale HUD/cue or old effect-frame dependency,
and no gameplay behavior change.

### Phase 7 - Replace secondaries and add Wear Collapse Tiles

Outcome: four secondary bodies are simplified and three authored wear states are
added. Production temporarily reaches **71 PNGs**.

#### 7.1 Replace four secondary bodies

- [ ] Replace seeker, escort drone, orbit blade, and wake mine at existing paths,
  canvases, pivots, and anchors.
- [ ] Give each one dominant motion-role silhouette and no more than two functional
  modules.
- [ ] Preserve homing, escort, orbit, stationary-mine behavior, cadence, damage,
  and upgrade-family naming.
- [ ] Render runtime, upgrade-card, guidebook, and maximum-pressure comparisons.

#### 7.2 Add three wear-tile states

- [ ] Add `world/wear_tile_intact.png`, `world/wear_tile_cracked.png`, and
  `world/wear_tile_collapsed.png` at 240 x 160 with pivot 120,80.
- [ ] Preserve exact runtime rect, wear timing, collision, persistence, occupancy,
  and deterministic layout fingerprint.
- [ ] Verify state progression without decorative cracks or micro-debris.

#### 7.3 Approve and apply Phase 7

- [ ] Produce and approve exact secondary and wear-tile reports.
- [ ] Apply only approved targets and runtime/manifest/provider changes.
- [ ] Commit the two coherent units and confirm exactly 71 production PNGs.

Phase gate: four distinct secondary roles and three readable wear states with no
gameplay-rule changes.

### Phase 8 - Replace the 19 ordinary enemy bodies

Outcome: every ordinary enemy keeps its gameplay role but uses the simplified
shared visual grammar. Production remains at 71 PNGs.

#### 8.1 Produce the complete enemy family

- [ ] Preserve all 19 existing semantic IDs, paths, canvases, pivots, anchors, and
  runtime roles.
- [ ] Group production briefs by movement/attack function to reuse proportions and
  modules without merging identities.
- [ ] Use one dominant silhouette, at most two functional modules, 3-5 large
  planes, one perimeter, and one restrained role accent per enemy.
- [ ] Keep ordinary, elite, command, and boss hierarchy readable without relying
  on color alone.
- [ ] Do not introduce any unapproved external source or named theme.

#### 8.2 Review under gameplay pressure

- [ ] Render one actual-scale family sheet plus crowded-combat views.
- [ ] Verify role identification, facing, target priority, overlap, grayscale,
  damage state, and maximum-pressure readability.
- [ ] Compare against the approved simple UI/world direction rather than
  presentation-sheet decoration.

#### 8.3 Approve and apply Phase 8

- [ ] Produce one exact 19-target report, or smaller coherent role-group reports
  if review requires iteration.
- [ ] Obtain exact approval, apply only approved paths, rebuild evidence, and
  commit the family.

Phase gate: all 19 enemy PNGs are approved, applied, and role-readable.

### Phase 9 - Replace bosses and consolidate shared boss nodes

Outcome: five boss bodies own boss identity and all external shield objectives
reuse three shared state images. Production reaches the final **64 PNGs**.

#### 9.1 Replace five boss bodies

- [ ] Preserve existing IDs, paths, canvases, pivots, attack anchors, health/guard
  presentation, and stage behavior.
- [ ] Build each boss from one dominant silhouette and 4-6 large filled planes.
- [ ] Express scale and hierarchy through mass proportion, not rivets, lamps,
  nested frames, or boss-specific objective decoration.
- [ ] Render same-scale comparison against player, ordinary enemies, and shared
  node states.

#### 9.2 Add three shared boss-node states

- [ ] Add `active`, `damaged`, and `resolved` node PNGs at one common canvas,
  pivot, and footprint.
- [ ] Distinguish states structurally with complete rail, broken rail, and opened
  housing rather than hue alone.
- [ ] Keep module kind/index, shield logic, sequence, and objective behavior in
  existing gameplay owners.
- [ ] Prove all ten boss-specific module paths have no live consumer.

#### 9.3 Approve and apply Phase 9

- [ ] Produce exact reports for five boss replacements, three node additions, and
  ten module retirements.
- [ ] Obtain explicit approval, apply exact paths, rebuild evidence, and commit.
- [ ] Confirm production contains exactly 64 PNGs.

Phase gate: five boss bodies, three shared node states, zero boss-specific module
art, and exact final media count.

### Phase 10 - Reconcile and freeze the release candidate

Outcome: the final visual pack, consumers, workbench, documentation, and clean
Git state agree before the one complete validation run.

#### 10.1 Reconcile exact ownership

- [ ] Require the exact final family split: 1 player, 19 ordinary enemies, five
  bosses, three shared boss nodes, four secondaries, nine projectiles, seven
  defense/status, four pickups/rewards, 11 world/facility, and one EMP.
- [ ] Require zero HUD/minimap/combat-cue PNGs and zero non-EMP effect frames.
- [ ] Require every live semantic ID to have exactly one raster or code-native
  owner, never both.
- [ ] Require every production PNG to be indexed once with correct canvas, pivot,
  import, provider, consumer, and validator coverage.
- [ ] Require complete source/license/hash records for every external-source
  derivative.

#### 10.2 Clean the active workbench

- [ ] Require no stale TO-BE deliverable after successful promotion.
- [ ] Preserve current AS-IS references, generated review UI, the curated external
  source register, and exact approval/application records.
- [ ] Remove obsolete generated previews only when they are task-owned and no
  active evidence or approval links to them.
- [ ] Run deterministic workbench build/check and path/hash validation.

#### 10.3 Audit code quality and freeze HEAD

- [ ] Run `$codebase-quality-auditor` over shared catalogs, providers, renderers,
  manifests, generators, and validators changed by Phases 6-9.
- [ ] Correct only small task-scoped ownership or contract defects found by the
  audit.
- [ ] Require a clean worktree and record the exact release-candidate commit.
- [ ] Freeze visual assets and runtime paths during Phase 11 except for fixes
  required by failed final validation.

Phase gate: clean release-candidate HEAD, deterministic workbench, exact 64-file
ownership, and no unresolved source/license or consumer ambiguity.

### Phase 11 - Run one complete validation and close the plan

Outcome: the already-complete candidate passes the full release gate once.

#### 11.1 Run structural and focused validators

- [ ] Enumerate and run the complete current validator corpus under
  `tools/validation/` through `./tools/godot.ps1`; do not rely on a stale hard-coded
  validator count.
- [ ] Require visual asset coverage, semantic provider/separation, actor,
  projectile, reward/facility, defense/status, world/wear, HUD/UI, localization,
  upgrade, pause, guidebook, boss, encounter, attack, and run validators to pass.
- [ ] Run deterministic workbench validation and final Git/path/hash reconciliation.

#### 11.2 Build and test native and production Web paths

- [ ] Run a production-style native import/start and smoke deployment, combat,
  upgrade, pause/settings, guidebook, stage transition, report/result, and the
  connected five-stage run.
- [ ] Run `./tools/export_web.ps1`.
- [ ] Load `$npjt-port-guard`, start the built Web export through the canonical
  fastrun `codex` lane, and repeat relevant navigation/interaction smoke.
- [ ] Verify player/aim/muzzle/projectile alignment, all actor families, statuses,
  pickups, crates, facilities, bulkhead/wear states, HUD/cues, one-image EMP,
  reduced motion, and keyboard/controller focus.

#### 11.3 Run visual, responsive, performance, and stability evidence

- [ ] Capture KO/EN at 960 x 540, 1280 x 720, and 1920 x 1080 plus 200% text
  scale; require zero clipping, overlap, or information loss.
- [ ] Capture grayscale and maximum-pressure evidence.
- [ ] Run existing native/Web pressure scenarios and lifecycle soak from the
  frozen candidate.
- [ ] Require existing performance, draw-call, memory, and stability thresholds.

#### 11.4 Close the program

- [ ] Fix any final-gate failure in a scoped commit, re-freeze HEAD, and rerun the
  affected check plus the complete gate when the failure could invalidate other
  results.
- [ ] Record final commands, hashes, screenshots, performance data, and commit in
  durable acceptance evidence.
- [ ] Incorporate any new durable behavior into the active product/design specs.
- [ ] Mark this plan done only after every task and release criterion passes; then
  delete it according to `.agents/PLANS.md` once durable decisions are preserved.

Phase gate: all required validators, native/Web smoke, responsive/localized
evidence, performance, and stability checks pass from the final clean HEAD.

## Test Plan

### During Phases 6-10

Run only guards needed to keep the long replacement program mechanically sound:

- deterministic workbench build/check;
- JSON/schema/path/hash validation;
- GDScript parse/import checks for touched sources;
- target canvas, pivot, alpha, and import checks;
- actual-scale rendered approval evidence;
- focused diagnostics only when a candidate cannot otherwise be judged.

Do not run or claim the complete release suite, native/Web workflow matrix,
responsive/localized matrix, or authoritative performance matrix during these
phases.

### Phase 11 only

Run the complete validator corpus, native production smoke, built-Web smoke,
KO/EN responsive and 200% evidence, keyboard/controller interaction, maximum
pressure, performance, memory, and lifecycle soak against the final reconciled
HEAD.

Success requires the exact 64-file pack, zero stale raster dependency, one owner
per semantic identity, complete license/provenance records, no gameplay
regression, no information loss, and all existing release thresholds.

## Rollback and Safety

- Record full HEAD before Phase 6 execution and before every approved application.
- Keep every unit or coherent family in a scoped commit containing only
  task-owned changes.
- Never stage, rewrite, clean, or revert unrelated user work.
- Never use hard reset, broad checkout, recursive cleanup, or directory-wide
  deletion to roll back.
- Resolve and verify every retirement path under the intended repository root;
  delete only exact approved paths and sidecars.
- Preserve external license/source records even though attribution is not
  required.
- A failed candidate remains unpromoted. Correct an applied unit with a forward
  scoped commit or revert only the exact task-owned commit when safe.
- If production, manifest, or consumer state changes outside this plan, stop the
  affected unit, rebuild its report, and obtain new approval.

## Risks

- **Art throughput:** 62 authored outputs remain. Mitigation: produce coherent
  families in parallel from one strict brief and reuse role grammar without
  merging semantic identities.
- **External-style contamination:** source palettes, gradients, cameras, and lore
  can leak into production. Mitigation: keep source files outside TO-BE and require
  full Cardborne normalization plus actual-scale review.
- **Projectile/collision mismatch:** decorative tails can imply damage. Mitigation:
  render collision overlays and keep the damaging opaque core normalized.
- **Facility-footprint mismatch:** a body image may understate a live radius or
  curtain. Mitigation: validate the PNG beside the exact dynamic boundary.
- **Suppressed-effect readability:** removing small effects may hide event
  ownership or fairness. Mitigation: preserve direct state/tint/trajectory
  feedback and reopen a named effect only from concrete gameplay evidence.
- **Workbench drift:** a wrong unit count could authorize incomplete retirement.
  Mitigation: partition all 215 current paths once and require a 64-target forecast.
- **Delayed full testing:** batching validation can accumulate regressions.
  Mitigation: run parse/schema/import guards per unit and reserve the authoritative
  end-to-end gate for Phase 11 as explicitly requested.
- **Approval drift:** any changed hash/path invalidates prior approval. Mitigation:
  regenerate and redisplay the complete exact report.

## Open Questions

No architectural question blocks execution. Each visual still requires the
defined actual-scale review and exact-hash approval. The current EMP candidate is
a proposal, not a preapproved production switch.

## Decision Notes

- 2026-08-04: preserved the user's rule that bullets, pickups, crates,
  facilities, and every other independently readable world target are complete
  PNG assets.
- 2026-08-04: withdrew the 36-PNG forecast and adopted the exact 64-PNG boundary.
- 2026-08-04: retained code-native ownership only for HUD/minimap/combat symbols
  and live dynamic truth.
- 2026-08-04: consolidated three XP files to one authored master and repair
  pad/core to one authored pad without merging gameplay semantics.
- 2026-08-04: kept EMP as the only large raster effect, represented by one
  512 x 512 image; suppressed the other 21 small effect families for now.
- 2026-08-04: confirmed no earlier external gameplay asset-pack intake existed.
- 2026-08-04: imported only six CC0 PNG sources plus license/provenance evidence;
  rejected full-pack production imports and direct runtime reuse.
- 2026-08-04: generated one non-derivative review-only EMP candidate; it still
  requires gameplay-scale review and switch approval.
- 2026-08-04: retained one complete final validation after all approved asset and
  runtime changes, with only mechanical guards during production phases.

## Progress

- [x] Corrected the governing media boundary and final count.
- [x] Completed current-file, consumer, and external-history audits.
- [x] Curated and stored six external source PNGs with two included CC0 licenses.
- [x] Stored a visual contact sheet and one validated EMP review PNG.
- [x] Revised the rationalization evidence, visual spec, workbench guidance,
  production ownership guidance, and this active plan.
- [ ] Runtime/workbench execution has not begun under the corrected boundary.

## Next Steps

1. Start Phase 6 at Task 6.0 by recording the current clean preproduction commit
   as the execution baseline and confirming Godot 4.7.
2. Execute Task 6.1 and rebuild the workbench to the exact 215-to-64 partition.
3. Begin authored production with the nine-projectile unit; do not switch or
   retire any production file before its exact report is approved.

## Completion and Stop Conditions

Mark this plan complete only when:

- every Phase 6-9 unit has exact approval and application evidence;
- production contains exactly 64 indexed gameplay PNGs in the specified split;
- HUD/minimap/combat-cue PNGs and all non-EMP effect frames are absent;
- every live semantic identity has exactly one visual owner;
- external-source derivatives have complete provenance and license records;
- gameplay rules and collision truth remain unchanged;
- the complete Phase 11 native/Web/responsive/interaction/performance gate passes;
- final evidence and durable specs are current; and
- no task, risk remediation, or required follow-up remains.

If a blocking condition repeats for three consecutive goal turns and no safe
in-scope progress remains, record exact evidence and report the blocker. Otherwise
preserve the current clean baseline and continue from the named unchecked task.
