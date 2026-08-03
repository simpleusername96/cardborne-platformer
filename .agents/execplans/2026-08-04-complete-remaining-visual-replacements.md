---
type: plan
status: active
owner: BK
created: 2026-08-04
last_reviewed: 2026-08-04
scope: Rationalized Phase 6-11 visual ownership migration, authored replacement production, exact retirement, reconciliation, and final release validation
supersedes: ./2026-08-02-visual-replacement-workbench-and-runtime-switch.md
related:
  - ../../AGENTS.md
  - ../AGENTS.md
  - ../PLANS.md
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/design/visual-replacement-workbench/README.md
  - ../../docs/design/visual-replacement-workbench/asset-rationalization.md
  - ../../art/visuals/production/README.md
  - ../semantic-v2-runtime-acceptance-evidence.md
---

# Finish the Rationalized Visual Replacement Program - Execution Contract

## Why / Context

Phases 0 through 5 established one production root, one-body player craft,
code-native UI chrome, the current UI layouts, and an exact-hash replacement
workbench. The former Phase 6-11 contract then treated nearly every remaining
symbol and animation frame as a separate replacement image. That would have
created more than 200 apparent art tasks and preserved the fragmentation the UI
work had just removed.

The 2026-08-04 preimplementation audit changed the remaining program:

- production contains 215 gameplay PNGs: 114 static and 101 effect frames;
- every file is accounted for, but there are no deployable TO-BE gameplay files;
- all 101 raster effect frames can leave the pack after event routing changes;
- all 43 HUD/action/upgrade/minimap/combat-cue PNGs can become shared code-native
  symbols or be retired as unused;
- projectiles, defense/status, pickups, and functional facilities are better
  owned by shared code-native recipes than one raster per identity;
- ordinary enemies, bosses, secondary bodies, shared boss nodes, solid cover,
  and wear-tile states remain authored raster because silhouette is their main
  readability channel.

The complete evidence and file-family accounting is in
[`asset-rationalization.md`](../../docs/design/visual-replacement-workbench/asset-rationalization.md).
This plan is now the sole executable Phase 6-11 contract.

## Purpose

Complete the remaining visual work with the smallest coherent ownership model:

- exactly **36 gameplay PNGs** at final reconciliation;
- 34 new authored raster outputs: 28 in-place authored-body replacements and six new
  shared/state files;
- zero raster HUD/action/upgrade/minimap/combat-cue files;
- zero raster effect frames and zero manifest animation identities;
- shared cached geometry for projectiles, defense/status, rewards/facilities,
  symbolic UI, combat cues, and readability-critical effects;
- unchanged gameplay rules, collision, timings, targeting, values, encounters,
  controls, localization, and save behavior;
- one complete native/Web release validation only after every visual switch and
  production-file change is finished.

## Scope and Non-scope

### In scope

- Rebuild the workbench schema and units around authored-raster, code-native,
  and absent result media.
- Migrate 175 current PNGs to shared code-native ownership or verified absence:
  101 effects, 43 HUD/cues, nine projectiles, seven defense/status files, six
  pickups, seven active facility/bulkhead files, and two unused world files.
- Replace 19 ordinary enemy bodies, four secondary bodies, and five boss bodies
  in place.
- Consolidate ten boss-module PNGs into three shared node-state PNGs.
- Add three Wear Collapse Tile state PNGs.
- Preserve current player-craft and solid-cover PNG bytes unless final rendered
  evidence proves a specific contract failure.
- Update the manifest, semantic provider, catalogs, renderers, guidebook/HUD
  consumers, validators, workbench, and durable documentation together.
- Produce exact approval reports, apply only approved mappings and retirements,
  reconcile the final pack, and run final release validation.

### Out of scope

- Gameplay balance, weapon behavior, enemy AI, boss rules, encounter schedules,
  difficulty selection, stage content, save schema, localization copy, audio, or
  input changes.
- Another UI layout redesign. Phase 6 changes symbol ownership and drawing only.
- A new art direction, named material/cultural theme, or photoreal rendering.
- Recreating removed effects as spritesheets, atlases, or one file per frame.
- Keeping unused images for hypothetical future features.
- Adding or upgrading production dependencies.
- Cropping, tracing, or promoting reference sheets and screen mockups.

## Assumptions

- Godot 4.7 stable and the current GDScript architecture remain authoritative.
- `docs/product/vehicle_game_spec.md` owns gameplay behavior;
  `docs/design/VISUAL_SYSTEM.md` owns visual behavior.
- `replacement-workbench.json` remains the only hand-authored unit, approval,
  and application-state source. `inventory.json` and `index.html` remain
  deterministic generated outputs.
- The current 215-file inventory and consumer audit remain valid until Task 6.0
  records the execution baseline. If files or consumers changed, Task 6.0
  re-audits and amends this plan before any switch.
- Prior exact approvals applied to prior sets only. They do not authorize any
  newly rationalized code-native or retirement unit.
- Production deletion always requires the exact displayed PNG and `.png.import`
  sidecar paths. Broad directory deletion is never inferred.
- Cheap deterministic schema/build/syntax checks may run during implementation.
  The full validator, native/Web visual, interaction, responsive, and
  performance suite runs once in Phase 11.

## Proposed Design

### Final ownership model

| Visual family | Semantic identities | Final medium | Final PNGs |
| --- | ---: | --- | ---: |
| Player craft | 1 | Authored raster, current bytes | 1 |
| Ordinary enemies | 19 | Authored raster, replaced in place | 19 |
| Stage bosses | 5 | Authored raster, replaced in place | 5 |
| Shared boss node | 3 states | Authored raster shared by all bosses | 3 |
| Secondary weapons | 4 | Authored raster, replaced in place | 4 |
| Solid cover | 1 | Authored raster, current bytes | 1 |
| Wear Collapse Tile | 3 states | Authored raster | 3 |
| Projectiles | 9 | Shared cached code-native meshes | 0 |
| Defense/status | 7 | Shared cached code-native meshes | 0 |
| Pickups/rewards | 6 | Shared cached code-native recipes | 0 |
| Facilities/bulkhead | 7 current files | Shared cached code-native recipes and state parameters | 0 |
| HUD/action/upgrade/minimap/cues | 43 | Shared code-native glyph/marker/cue recipes or absence | 0 |
| Transient effects | 22 event identities / 101 frames | Shared code-native event modes or deliberate suppression | 0 |
| **Total** | — | — | **36** |

Semantic identity does not imply a file. Gameplay and UI may still request
`projectile/hostile_arc`, `status/chill`, `pickup/repair`, or
`cue/objective_active`, but the responsible catalog returns a descriptor/recipe
rather than a raster path.

### Workbench result model

Task 6.1 extends the workbench deliberately rather than overloading old status
names:

- `result_medium` is required and is one of `authored_raster`, `code_native`, or
  `absent`.
- `switch_kind` adds `code_native` beside `replace`, `add`, `consolidate`, and
  `retire`.
- final `status` adds `code_native` for an applied semantic unit whose legacy
  raster paths are absent and whose live owner is a code recipe.
- code-native units use existing `consumer_asset_ids`, `consumer_paths`,
  `runtime_change_paths`, and `retire_paths`; they have no fake PNG deliverable.
- the generated index presents result medium, live semantic owner, runtime
  changes, rendered evidence, and retirements explicitly.
- final inventory counts are derived from the manifest/filesystem, never stored
  as an unverified fixed discovery constant.

The revised active units must partition all 215 current PNGs exactly once:

| Unit | Current PNGs | Result |
| --- | ---: | --- |
| `player_craft` | 1 | keep authored raster |
| `ordinary_enemy_family` | 19 | replace authored raster in place |
| `boss_body_family` | 5 | replace authored raster in place |
| `shared_boss_node` | 10 | consolidate to three authored raster states |
| `secondary_body_family` | 4 | replace authored raster in place |
| `solid_cover` | 1 | keep authored raster |
| `code_native_projectiles` | 9 | code-native |
| `code_native_defense_status` | 7 | code-native |
| `code_native_reward_facility` | 13 | code-native |
| `code_native_hud_symbols` | 43 | code-native or absent within one audited symbol program |
| `code_native_effects` | 101 | code-native or deliberately suppressed by event mapping |
| `unused_world_retirement` | 2 | absent |
| **Current coverage** | **215** | exact, non-overlapping |
| `wear_tile_family` | 0 current / 3 target | add authored raster |

Previously applied retirement ledgers and `ui_font` remain historical/current
workbench records without reclaiming any of the 215 gameplay PNGs above.

### Code-native rendering contract

- Reuse immutable recipe data and cached `ArrayMesh`/`MultiMesh` batches. Do not
  triangulate or rebuild geometry per actor, projectile, pickup, or frame.
- Projectiles preserve nine semantic forms, collision-normalized damaging cores,
  non-damaging tails, owner, delivery, threat tier, and affinity distinctions.
- Defense/status preserves four defense topologies and three shape-coded status
  arcs. Hue alone may not carry state identity.
- XP small/medium/large uses one shard recipe; gameplay value selects scale and
  emphasis. Reward crate, repair, and recall remain distinct descriptors.
- Facilities reuse repair, overdrive, arc-surge, transit, and bulkhead recipes.
  Bulkhead recipes must expose intact, damaged, and opened/broken presentation
  states before the two current textures retire.
- Action, upgrade, minimap, support, and combat-cue shapes have one shared owner
  per semantic family and render identically in runtime, guidebook, status orbit,
  upgrade cards, and evidence sheets.
- Each effect event is explicitly `geometry`, `state_only`, or `suppressed`.
  `geometry` must name one shared recipe; `state_only` relies on an already
  visible gameplay state change; `suppressed` is cosmetic-only. No route resolves
  an animation frame after the switch.

### Authored-raster contract

- Every body uses one dominant silhouette, at most two functional secondary
  modules, 3-5 large planes for ordinary bodies and 4-6 for bosses, one dark
  perimeter, and one restrained state accent.
- No rivets, repeated lamps, decorative seams, nested outlines, concentric
  ornaments, random scratches, or unexplained greebles.
- All 19 enemy role IDs remain distinct at gameplay scale and grayscale.
- Secondary seeker, escort drone, orbit blade, and wake mine remain distinct by
  motion role and negative space, not by label or color alone.
- Boss bodies own boss identity. The same three boss-node files serve every
  external shield objective.
- Wear tiles use exact `240x160` canvases and pivots `120,80`; art never owns
  wear, occupancy, collision, damage, or persistence.

### Approval and application protocol

For every switch unit:

1. Record the clean full repository baseline before candidate work.
2. Generate deterministic current-path, target/hash, runtime-change, semantic-ID,
   retirement-path, and rendered-evidence reports.
3. Display the exact baseline and report hashes to the user. Code-native units
   display exact runtime-change paths and all PNG/sidecar retirements even though
   there are no target PNG hashes.
4. Receive explicit approval for that exact report. A different baseline, byte,
   mapping, runtime path, or retirement path invalidates approval.
5. Preview the switch without production writes when the helper supports it.
6. Apply atomically: runtime/descriptor/manifest/validator changes first within
   the same scoped change, target promotion second, exact approved retirement
   last.
7. Rebuild deterministic workbench outputs, record application hashes, and make
   one coherent task-owned commit.
8. Promote `applied` raster units to `keep_current`, code-native units to
   `code_native`, and absence-only units to `retired` only after their local
   structural checks pass.

No approval is inferred from a family name, an older approval, a directory, a
preview, a plan, or this audit.

## Execution Prerequisites

- Worktree is clean or unrelated user changes are identified and untouched.
- Root and nearest `AGENTS.md`, `.agents/PLANS.md`, product spec, visual spec,
  workbench spec, production README, rationalization evidence, and current
  manifest/workbench are read at execution time.
- `./tools/godot.ps1 --version` reports Godot 4.7 stable.
- Production discovery still reports 215 PNGs in the audited 35/13/7/6/10/43/101
  family split and zero deployable TO-BE assets.
- Every current PNG belongs to exactly one proposed revised unit.
- No runtime server is started outside the `$npjt-port-guard` codex lane.

If any prerequisite differs, stop before changing production bytes, record the
actual evidence, and amend this plan rather than forcing old counts.

## Milestones and Tasks

### Phase 6 - Rebuild ownership and switch shared code-native families

Outcome: all symbolic, state-parametric, collision-normalized, and transient
families use shared code-native owners. Production temporarily contains 40 PNGs:
35 actors, four secondary bodies, and one solid-cover image.

#### 6.0 Freeze and revalidate the execution baseline

- [ ] Record clean full HEAD, workbench source hash, manifest hash, production
  PNG/path/hash inventory, import-sidecar inventory, and zero-TO-BE result.
- [ ] Re-run the non-mutating consumer audit for all 215 paths.
- [ ] Confirm the rationalization arithmetic and exact unit partition.
- [ ] Append the baseline and any freshness correction to Progress before edits.

Acceptance: the audit matches the plan or the plan is amended before Task 6.1.

#### 6.1 Rebuild the workbench control plane

- [ ] Add `result_medium`, `switch_kind=code_native`, and final
  `status=code_native` support to the source, builder, index template, promotion
  helper, and validator.
- [ ] Replace the old 30 one-for-one target units with the exact unit partition
  in Proposed Design while retaining completed historical ledgers.
- [ ] Remove fixed assertions for 215 discovery files, 210 final files, 22
  animations, and 101 final frames; derive current/final counts instead.
- [ ] Generate `inventory.json` and `index.html`; verify deterministic rebuild.
- [ ] Verify every current PNG and every target path has exactly one unit owner.

Acceptance: the workbench represents code-native outcomes without fake image
deliverables, partitions 215 current PNGs once, and forecasts 36 final PNGs.

#### 6.2 Consolidate HUD, action, upgrade, minimap, support, and combat cues

- [ ] Change action rail and upgrade glyph drawing to use existing normalized
  recipes for Seeker, Dash, EMP, and eight upgrade families.
- [ ] Add the missing Support recipe to the shared glyph owner.
- [ ] Centralize six minimap marker shapes and use them in gameplay HUD and
  guidebook preview; preserve player/hostile/elite/boss/active/locked identity.
- [ ] Add one responsibility-shaped combat-cue recipe catalog for the 17 live
  cue identities; switch `VehicleCombatRenderer` away from semantic textures.
- [ ] Remove all consumers of the nine verified orphan HUD/cue IDs from the
  exact audit register: `action_primary`, `action_barrier`, `action_ion_field`,
  `upgrade_passive`, `cue_guide_ship`, `cue_guide_mobile`,
  `cue_guide_stationary`, `cue_guide_bosses`, and `cue_guide_objects`.
- [ ] Preserve layout, localization, focus, input, information, and slot count.

Acceptance: all 43 former HUD/cue paths have a code-native or absent result and
no runtime, guidebook, or validator code requests their textures.

#### 6.3 Retire raster effect-frame routing

- [ ] Convert all 39 presentation event routes to explicit `geometry`,
  `state_only`, or `suppressed` modes using the 22-identity future-polish register.
- [ ] Reuse existing dash, EMP, barrier/contact, arrival, directed-transfer,
  ring, beam, hull-hit, transit, pickup/repair, and telegraph geometry where
  readability requires it.
- [ ] Remove unconditional `animation_frame_asset()` resolution from
  `_sync_effects()`.
- [ ] Preserve event IDs, transforms, timings, reduced-motion behavior, and all
  gameplay owners.
- [ ] Remove animation/frame declarations from the raster manifest and update
  coverage validators to validate event modes instead.

Acceptance: no live code resolves a raster effect frame; every one of the 39
routes resolves to a valid explicit presentation mode, every `geometry` route
resolves a valid shared recipe, and future intent remains documented.

#### 6.4 Switch all projectile rendering to cached code-native meshes

- [ ] Use the existing nine projectile descriptors and mesh recipes for player
  primary, opening breach, Seeker, and six hostile affinities.
- [ ] Replace texture-backed projectile batches with cached mesh/MultiMesh
  batches without per-frame triangulation.
- [ ] Preserve pivots, facing, damaging-core/collision comparison, tails,
  affinity, owner, threat tier, delivery, and performance capacity.
- [ ] Update report/guide/evidence consumers that still resolve projectile PNGs.

Acceptance: all nine semantic projectile IDs render from one recipe system and
no code or validator requires projectile PNG paths.

#### 6.5 Switch defense and status rendering to shared topology recipes

- [ ] Implement cached recipes for barrier plates, ion emitter, generator shield
  source, and shield-escort forward plate.
- [ ] Implement separate burn, poison, and chill arc shapes using the existing
  status topology semantics; do not reuse one shape with three hues.
- [ ] Replace texture-backed status batches and defense semantic draws.
- [ ] Preserve protection, damage, timers, attachment transforms, and visibility.

Acceptance: seven semantic identities remain shape-distinct and no consumer
requires the seven state PNGs.

#### 6.6 Switch pickups, rewards, facilities, and bulkheads to shared recipes

- [ ] Route all six pickup/reward identities through the existing reward recipe
  owner; use one XP shard geometry with value-driven scale/emphasis.
- [ ] Route repair, overdrive, arc surge, transit, and breakable bulkhead through
  shared facility recipes in runtime and guidebook.
- [ ] Add explicit intact, damaged, and opened/broken bulkhead recipe states.
- [ ] Merge repair-pad core/inset into the repair recipe.
- [ ] Preserve live footprint, radius, state, value, drop, collection, dwell,
  cooldown, collision, and reward ownership.
- [ ] Mark unused breakable-cover-slab and hazard-power-relay images absent.

Acceptance: all 13 pickup/facility PNGs and both unused world PNGs have no live
texture consumer; semantic behavior and state remain unchanged.

#### 6.7 Produce actual-scale Phase 6 review evidence

- [ ] Build one deterministic system sheet showing each code-native family at
  runtime scale, grayscale, and representative semantic colors.
- [ ] Capture the HUD action strip, minimap, upgrade card, guidebook markers,
  combat cues, maximum projectile pressure, all defense/status forms, pickups,
  facilities, bulkhead states, and each retained effect mode.
- [ ] Compare against the visual-system detail, state, collision, and hierarchy
  rules. Fix only the shared recipe owner when a family fails.
- [ ] Generate exact per-unit runtime-change and PNG/sidecar retirement reports.

Acceptance: evidence is readable at gameplay scale and every proposed deletion
has a verified replacement owner or verified absence.

#### 6.8 Approve, apply, and record Phase 6 switches

- [ ] Obtain explicit exact-report approval for every Phase 6 code-native and
  absence unit. Prior approvals do not satisfy this task.
- [ ] Apply runtime/catalog/manifest/provider/validator changes and only the exact
  approved retirements atomically.
- [ ] Rebuild the workbench, record application hashes, and create coherent
  scoped commits.
- [ ] Run deterministic workbench/schema/source-format/import checks only; defer
  the complete runtime/Web validation suite to Phase 11.

Phase gate: production has exactly 40 PNGs, zero HUD/cue PNGs, zero effect-frame
PNGs, zero manifest animations, and no duplicate medium owner.

### Phase 7 - Produce secondary bodies and Wear Collapse Tiles

Outcome: four simplified secondary bodies replace current bytes and three wear
states are added. Production contains 43 PNGs.

#### 7.1 Replace the four secondary bodies

- [ ] Produce Seeker, escort drone, orbit blade, and wake mine at their existing
  canvases/pivots and target paths.
- [ ] Use four unmistakable motion-role silhouettes: forward homing body,
  escorting drone, orbiting blade, and stationary mine.
- [ ] Limit each to one dominant body, at most two functional parts, 3-5 planes,
  and one semantic accent; remove current lamps, seams, glow, and greebles.
- [ ] Render them in live motion and in the upgrade/guidebook contexts that show
  secondary identity.

#### 7.2 Add the three wear-tile states

- [ ] Produce `wear_tile_intact`, `wear_tile_cracked`, and
  `wear_tile_collapsed` as `240x160` authored states with pivot `120,80`.
- [ ] Keep footprint and outer mass stable; use topology, not color alone, to
  distinguish state.
- [ ] Confirm gameplay continues to own wear, occupancy, collision, damage, and
  persistence.

#### 7.3 Approve and switch Phase 7

- [ ] Generate actual-scale AS-IS/TO-BE, hash, mapping, runtime-path, and import
  reports for the four replacements and three additions.
- [ ] Obtain exact approval, promote atomically, baseline-promote the units, and
  commit the scoped changes.
- [ ] Run only deterministic workbench/import/format checks.

Phase gate: seven targets are current production, no layout/gameplay behavior
changed, and production contains 43 PNGs.

### Phase 8 - Replace the 19 ordinary enemy bodies

Outcome: every ordinary role remains semantically distinct while sharing the
approved simple general-SF construction language.

#### 8.1 Produce the complete enemy family

- [ ] Produce exact replacements for `scrap_drone`, `needle_drone`,
  `spark_minelet`, `chaser`, `rammer`, `bulkhead_guard`, `shooter`, `turret`,
  `mine`, `artillery_spotter`, `controller`, `generator`, `shield_escort`,
  `repair_tender`, `drone_carrier`, `splitter_barge`, `interceptor_tower`,
  `beam_sentinel`, and `boss_pylon`.
- [ ] Preserve every existing path, canvas, pivot, anchor, role, and runtime
  mapping.
- [ ] Build identity from silhouette, front/rear cut, negative space, and at most
  two functional modules; never from color alone.
- [ ] Parallel generation may be delegated by bounded role group, but one owner
  must normalize palette, outline, scale, plane count, naming, and pivots before
  publication.

#### 8.2 Review the family under gameplay pressure

- [ ] Render all 19 at 1x gameplay scale, grayscale, mixed-role pressure, target
  priority, shield/support, stationary/mobile, and guidebook scale.
- [ ] Reject same-silhouette recolors, boss-like ordinary bodies, greeble-based
  rank, ambiguous facing, and any role pair that collapses at grayscale.
- [ ] Produce one complete family approval report; do not approve incomplete
  subsets that would leave the family in mixed visual grammar.

#### 8.3 Approve and switch Phase 8

- [ ] Obtain exact 19-file hash/mapping approval, replace in place atomically,
  rebuild/baseline-promote the workbench, and commit.
- [ ] Run only deterministic workbench/import/format checks.

Phase gate: all 19 paths contain the approved family and production remains at
43 PNGs.

### Phase 9 - Replace bosses and consolidate shared boss nodes

Outcome: five boss bodies own boss identity; all external shield objectives use
the same three-state node family. Production reaches the final 36 PNGs.

#### 9.1 Produce five boss bodies

- [ ] Produce `colossus`, `leviathan`, `titan`, `behemoth`, and `crown` at the
  existing `352x352` canvases and `176,176` pivots.
- [ ] Give each a unique dominant mass ratio and silhouette using 4-6 large
  planes and one outline; do not use repeated lamps, panels, nested frames, or
  small modules to imply scale.
- [ ] Preserve stage identity, attack anchors, health/guard presentation,
  guidebook, report, minimap, and debug practice mappings.

#### 9.2 Produce and map the three shared node states

- [ ] Produce `boss_node_active`, `boss_node_damaged`, and
  `boss_node_resolved` at `160x160`, pivot `80,80`.
- [ ] Use the same housing and scale across all states; distinguish complete
  rail, broken rail, and open housing structurally.
- [ ] Map every current boss-module kind/index to one of the three presentation
  states while preserving kind/index, objective copy, target selection, and
  gameplay resolution.
- [ ] Remove the former disabled-frame dependency; the state transition itself
  is the primary readability cue.

#### 9.3 Review, approve, and switch Phase 9

- [ ] Render all five bosses with all three shared states at gameplay,
  guidebook, minimap/objective, report, and debug-practice scale.
- [ ] Generate exact hashes/mappings for eight targets and exact retirement
  paths for ten legacy boss-module PNGs and sidecars.
- [ ] Obtain exact approval, switch atomically, rebuild/baseline-promote the
  workbench, and commit.
- [ ] Run only deterministic workbench/import/format checks.

Phase gate: no boss-specific node art remains, all 20 legacy module paths are
absent, and production contains exactly 36 PNGs.

### Phase 10 - Reconcile production and freeze the release candidate

Outcome: source, generated workbench, manifest, provider, catalogs, consumers,
and filesystem agree before the one full release test.

#### 10.1 Reconcile exact ownership

- [ ] Require exactly 36 production gameplay PNGs: player 1, ordinary enemies
  19, bosses 5, shared nodes 3, secondaries 4, solid cover 1, wear tiles 3.
- [ ] Require zero production PNGs under HUD, projectile, state, pickup,
  facility/bulkhead legacy, or effect-frame families.
- [ ] Require zero raster animation declarations and zero unresolved raster
  semantic IDs.
- [ ] Require exactly one owner for every live semantic identity and no runtime
  consumer that falls back to a removed texture.
- [ ] Require every code-native recipe to be cached/batched according to its
  renderer contract.

#### 10.2 Clean the workbench without creating an archive

- [ ] Remove completed TO-BE duplicates and generated per-unit contact sheets
  only after their bytes are current production and application evidence exists.
- [ ] Preserve current AS-IS references, screen-direction evidence, exact
  application records, and previously applied negative-inventory ledgers.
- [ ] Rebuild `inventory.json` and `index.html` and require deterministic check
  equality.
- [ ] Update rationalization evidence with actual final counts and any approved
  deviation.

#### 10.3 Freeze a clean release-candidate commit

- [ ] Review the complete task diff for unrelated changes, duplicate owners,
  responsibility creep, dead compatibility paths, and stale comments/docs.
- [ ] Run the repo-required cross-module code-quality audit and apply only small,
  safe, task-scoped corrections.
- [ ] Commit the complete reconciled candidate and record its full HEAD.
- [ ] Do not change visual bytes or mappings after this point without returning
  to the affected phase and invalidating its evidence/approval.

Phase gate: clean HEAD, deterministic workbench, exact 36-file ownership, and no
known unresolved visual migration.

### Phase 11 - Run the one complete release validation and retire the plan

Outcome: the final, already-complete visual candidate passes native and built-Web
release evidence without a mid-program full-suite run.

#### 11.1 Run structural and focused validators

- [ ] Run every repository `validate_*.gd` script dynamically through
  `./tools/godot.ps1`; do not rely on a stale hard-coded validator count.
- [ ] Run workbench, manifest/provider, visual separation, component ownership,
  actor, projectile, reward/facility, defense/status, UI layout, localization,
  accessibility, combat renderer, world, boss, and lifecycle validators.
- [ ] Require zero missing IDs, duplicate owners, stale texture paths, import
  failures, parse errors, warnings promoted by project policy, and deterministic
  mismatches.

#### 11.2 Build and test native and production Web paths

- [ ] Run the native production-style start path and complete deployment,
  combat, upgrade choice, pause, settings, guidebook, report, garage, stage
  transition, and full five-stage run smoke.
- [ ] Run `./tools/export_web.ps1`, start the built export through the canonical
  fastrun codex lane, and repeat the relevant interaction/navigation smoke.
- [ ] Verify KO/EN at 960x540, 1280x720, and 1920x1080 plus the required 200%
  text-scale surfaces: no clipping, overlap, overflow, or information loss.
- [ ] Verify player/aim/muzzle/projectile alignment, all 19 enemies, all bosses
  and node states, secondaries, projectiles, status/defense, rewards/facilities,
  minimap/cues, effects, reduced motion, and controller/keyboard focus.

#### 11.3 Run performance and stability evidence

- [ ] Run the existing native/Web pressure scenarios and lifecycle soak from a
  clean release candidate, using current repository thresholds without waiver.
- [ ] Require the existing combat/world batch, draw-call, frame, physics, memory,
  and lifecycle thresholds.
- [ ] Save large logs/captures under the existing evidence location and summarize
  only decisive results in the plan/evidence docs.

#### 11.4 Close the program

- [ ] Fix only task-scoped failures and rerun the smallest failed check plus the
  final affected gate; any visual-byte change invalidates the affected approval
  and returns to its phase.
- [ ] Record final HEAD, commands, results, counts, evidence paths, and residual
  limitations.
- [ ] Promote accepted durable decisions into active specs and operating docs.
- [ ] After completion and explicit authority for document deletion, remove this
  completed ExecPlan and the frozen predecessor as required by `.agents/PLANS.md`.
- [ ] Make the final scoped commit and confirm a clean worktree.

Phase gate: all required validation, native/Web visual and interaction smoke,
responsive/localized evidence, and performance/stability thresholds pass.

## Progress and Next Steps

- [x] 2026-08-04: audited all 215 production gameplay PNGs against the manifest,
  filesystem, direct consumers, workbench, and visual-system rules.
- [x] 2026-08-04: proved there are zero deployable TO-BE gameplay files and 12
  review-only workbench PNGs.
- [x] 2026-08-04: classified every static family and all 22/101 effect identities;
  recorded the future-effect polish register.
- [x] 2026-08-04: confirmed the 36-PNG boundary is technically feasible; the only
  incomplete shared geometry is the finite defense/status and bulkhead-state
  recipe work already specified in Phase 6.
- [x] 2026-08-04: updated the active visual-system/workbench contracts and rewrote
  Phase 6-11 around shared ownership instead of one-file replacement.
- [ ] Execution has not begun. Next task: Phase 6, Task 6.0.

Canonical progress is this checklist. Check a task only when its acceptance
evidence exists. Do not repeat completed discovery unless Task 6.0 finds a
freshness-changing repository difference.

## Test Plan

### During Phases 6-10

Run only checks needed to prevent mechanical corruption while continuing the
program:

- deterministic workbench build/check;
- JSON/schema/path/hash validation;
- GDScript formatting/parse/import checks for touched sources;
- exact target canvas/pivot/import checks;
- rendered actual-scale approval evidence;
- focused non-release diagnostics when a candidate cannot be judged otherwise.

Do not run or claim the complete release suite, full native/Web interaction
matrix, responsive/localized matrix, or authoritative performance matrix during
these phases.

### Phase 11 only

Run the complete validator corpus, native production smoke, built-Web smoke,
KO/EN responsive and 200% evidence, controller/keyboard interaction, maximum
pressure, performance, memory, and lifecycle soak against the final reconciled
HEAD.

Success requires the final 36-file pack, zero stale raster dependency, one
medium owner per semantic identity, no gameplay regression, no information
loss, and all existing release thresholds.

## Rollback and Safety

- Record full HEAD before Task 6.0 and every approved application.
- Keep each unit or coherent family in a scoped commit containing only task-owned
  changes. Never stage or rewrite unrelated user work.
- Never use hard reset, broad checkout, recursive cleanup, or directory-wide
  deletion to roll back.
- Before retirement, resolve and verify every absolute target under the intended
  production/workbench roots and delete only exact approved paths.
- A failed candidate remains unpromoted. A failed applied unit is corrected by a
  scoped forward fix or explicit commit revert, preserving evidence and user
  work.
- Gameplay state, collision, timing, values, and save data are never rollback
  levers for a presentation failure.
- Generated ignored audit media may be removed only after confirming it is
  task-owned and outside production/source authority.

## Risks

- **Renderer migration risk:** code-native conversion touches shared renderer,
  manifest, provider, and validator boundaries. Mitigation: migrate one semantic
  family at a time, cache geometry, require actual-scale evidence, and switch
  atomically.
- **Performance regression:** naive per-frame polygon construction could erase
  sprite-batch gains. Mitigation: immutable recipes and cached
  `ArrayMesh`/`MultiMesh` batches are mandatory.
- **State ambiguity:** one generic shape could collapse defense/status/bulkhead
  states. Mitigation: topology-distinct recipes and grayscale/state sheets.
- **Over-suppressed feedback:** deleting effects without a readability substitute
  could hide ownership or timing. Mitigation: explicit event modes and the future
  register; keep only evidence-backed semantic geometry.
- **Visual sameness:** aggressive simplification could make 19 enemies or five
  bosses indistinguishable. Mitigation: silhouette/negative-space family review
  at gameplay scale and grayscale.
- **Approval drift:** code and retirement paths can change after a report.
  Mitigation: baseline and exact report hashes invalidate automatically on any
  changed input.
- **Workbench dual authority:** an evidence document could be mistaken for switch
  state. Mitigation: only `replacement-workbench.json` records unit status,
  approval, and application.
- **Future content growth:** 36 is the current-run reconciliation count, not a ban
  on future product assets. New content must follow the same medium-boundary and
  no-unused-production rules.

## Completion and Stop Conditions

Complete only when:

- every Phase 6-9 unit has exact approval and application evidence;
- production contains exactly 36 indexed gameplay PNGs with the specified
  family split and zero raster HUD/effect/projectile/state/pickup/facility files;
- every live semantic identity has exactly one authored-raster or code-native
  owner and no removed-texture fallback;
- the complete Phase 11 validator/native/Web/responsive/interaction/performance
  gate passes at the clean final HEAD;
- durable specs/evidence reflect the actual result and completed plans are
  retired under the required authority.

Stop without claiming completion when an exact switch/deletion approval is
missing, baseline evidence changed, an unrelated user change overlaps a target,
gameplay behavior would need to change, a required source is unavailable, or a
release threshold still fails after safe task-scoped correction attempts.
Preserve exact evidence and resume from the named unchecked task.

## Open Questions

None. The media boundary, current/final counts, family dispositions, validation
cadence, and approval protocol are decided. Exact switch approvals and measured
release outcomes are execution gates, not design questions.

## Decision Notes

- 2026-08-04: rejected the former 210-PNG final target because it preserved 101
  transient frames and dozens of symbolic raster files as separate art tasks.
- 2026-08-04: adopted 36 final gameplay PNGs: 33 persistent authored bodies/
  objects/states plus three Wear Collapse Tile images.
- 2026-08-04: adopted 34 authored outputs: 28 replacements and six additions.
  Player craft and solid cover reuse current bytes.
- 2026-08-04: preserved all semantic gameplay identities while separating them
  from file identity; code-native does not mean gameplay removal.
- 2026-08-04: no current TO-BE image is reusable because no deployable TO-BE file
  exists. Existing code-native recipes are implementation inputs, not preapproved
  runtime appearance.
- 2026-08-04: future small-effect polish remains a documented semantic backlog
  and may not restore a frame-file production pack by default.
- 2026-08-04: full validation remains final-only; deterministic structural checks
  and rendered approval evidence continue during implementation.
