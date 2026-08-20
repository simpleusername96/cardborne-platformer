---
type: plan
status: active
owner: BK
created: 2026-08-20
last_reviewed: 2026-08-21
scope: Five-family ordinary-enemy catalog, tier scaling, pack composition, family traits, production visuals, migration, and performance-safe validation
related:
  - ../../docs/product/vehicle_game_spec.md
  - ../../docs/design/VISUAL_SYSTEM.md
  - ../../docs/design/visual-replacement-workbench/README.md
  - ../cardborne-performance-engineering-policy.md
  - ../research/performance/cardborne-runtime-architecture-audit.md
  - ../../docs/reports/2026-08-20-ordinary-enemy-branch-and-restructure-review-ko.html
  - ../../docs/reports/2026-08-20-ordinary-enemy-five-family-revision-en.html
---

# Ordinary Enemy Family and Pack Restructure - Execution Contract

Replace the 26-ID ordinary-enemy catalog with fifteen playable family-tier actors,
make every authored squad a persistent semantic pack, enforce Defender membership in
every Gunner pack, ship the ten approved family traits, and integrate the approved
five-family art without exceeding the retained renderer's 50-batch ceiling. The starting
point is `master` after visual staging commit `d64eb57a`; the remote pursuit branch is a
behavior reference only and is not merged.

## Purpose

- Objective: make ordinary enemies readable as five families with three tiers, two traits
  per family, and stable pack ownership while removing unreachable and duplicate enemy
  identities.
- Deliverable: a playable twelve-cycle implementation, production assets and semantic
  descriptors, updated Korean/English Guidebook data, canonical product/design updates,
  focused validation, and a committed migration.
- Completion state: every normal-cycle ordinary spawn uses one of fifteen family-tier IDs;
  every ordinary actor belongs to one validated pack; no retired ordinary archetype remains
  in runtime catalogs, stage rosters, Guidebook data, or production semantic assets.

## Scope and Boundaries

In scope:

- Families: Pursuer, Charger, Gunner, Defender, Coordinator.
- Tiers: T1/T2/T3 with integer `size_percent` values `100/125/150`.
- Traits: Pursuer `splitter/frenzy`; Charger `double/self_destruct`; Gunner
  `artillery/slow`; Defender `bulwark/reflector`; Coordinator `blink/pack_feed`.
- Authored pack blueprints, atomic pack admission, pack-owned shared timers/state, and the
  Gunner-plus-Defender invariant.
- Migration of useful current behavior primitives, removal of obsolete player-facing IDs,
  production integration of fifteen approved base PNGs, and retained code-native trait
  cues.
- Reclassification of the Stage 3 fixed beam summon as a boss-owned pattern actor.

Out of scope:

- Map-exploration incentives, neutral-facility competition, enemy gem growth, and
  tower-defense bases.
- New engine dependencies, threads, GDExtension, renderer rewrite, texture atlas work, or
  changes to actor/projectile/effect capacities and performance thresholds.
- A generic release-performance claim. This contract may establish focused validators,
  scenario validity, and the unchanged batch ceiling; native/Web release qualification
  remains a separately labelled final gate.

Constraints and invariants:

- All normal ordinary actors are mobile family-tier actors. Controller, Sustainer, Bomber,
  separate Artillery, global Armored, global Overclocked, and global Heavy are removed.
- A pack contains four to eight actors and has one primary family, one tier, and at most one
  pack trait. A required Defender replaces a filler; it never raises authored population,
  threat budget, or active capacity.
- Every Gunner pack contains at least one Defender. A pack with more than four Gunners
  contains two Defenders.
- Actor collision radius and projectile target radius remain gameplay-owned and do not
  scale with tier presentation. T1 uses the new shared ordinary presentation baseline;
  T2/T3 render at `125%/150%` of that family body's T1 presentation size.
- The existing `VehicleEnemyStore`, update schedule, spatial grid, projectile/effect pools,
  and retained renderer remain the capacity owners. No Node is added per actor or pack.
- Shared objective, formation, trait cadence, Blink phase, and Pack Feed stacks are stored
  once per registered pack. Health, collision, attack commitment, damage, and status remain
  per actor.
- The useful remote-branch behavior is adapted: movement focus uses the current pack
  objective, route guidance is requested only when the direct approach is blocked, and
  local separation, smoothing, speed caps, and attack-owned prediction remain. Universal
  direct pursuit and removal of long-range positioning are rejected.
- The visual authority pair is
  `docs/design/VISUAL_SYSTEM.md` SHA-256
  `2e5cf7e3f156629bcbe956da0e6cb30f6d3b608d9c20122ec5285fa1562aa006`
  and `docs/design/cardborne-universal-art-style-reference.png` SHA-256
  `96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889`,
  inspected at `1448x1086` original detail for this implementation scope.
- General SVG trait effects are prohibited by the canonical visual system. Trait cues use
  existing retained code-native disk/ring/beam/diamond primitives and actor-alpha tint
  composition; they add no raster effect, per-enemy material, per-enemy node, floating
  label, badge, or permanent detached halo.
- The user approved the staged five-family set on 2026-08-20 for temporary use. Production
  uses only its fifteen `base` row PNGs (five families x three tiers). The extra thirty
  trait-body PNGs remain review/reference material and are not indexed at runtime because
  45 actor textures would violate the 50 retained combat-batch ceiling. This preserves the
  user's intended durable model: three body assets per family plus trait presentation.

Destructive or irreversible actions:

- After every old semantic consumer is migrated, delete the twenty-one obsolete ordinary
  production PNGs and their tracked import metadata. Move the retained fixed-beam body to a
  boss-pattern path before deleting its old ordinary path. Git history remains recovery.
- Remove obsolete archetype, Guidebook, localization, fixture, renderer, and manifest
  records only in the same coherent migration that replaces their live consumers.

Exact actions requiring owner or user approval:

- The production use of the fifteen staged base PNGs and the five-family contract are
  explicitly approved by the user's 2026-08-20 instruction. No additional visual approval
  gate remains for those exact bytes.
- Any future promotion of the thirty staged trait-body PNGs, change to the 50-batch ceiling,
  product workload, collision size, native/dependency work, or weakening of a validation
  threshold requires a new explicit user decision.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Enemy identity | `VehicleEnemyArchetypes` owns 26 definitions; 18 mobile IDs are campaign-reachable and seven definitions are unreachable | `scripts/enemies/vehicle_enemy_archetypes.gd`; stage/boss roster trace | Replace normal ordinary identity with fifteen family-tier IDs; remove old player-facing identities | 1.1, 4.1 |
| Tier size | `VehicleStageVisualProfile` publishes one 48-unit mobile visual radius; projectile target radius is separately 48 | visual profile, archetype catalog, renderer | Raise the shared T1 presentation baseline to 56, then apply integer 100/125/150 at the render boundary; keep collision and hit radius unchanged | 1.1, 3.2 |
| Pack ownership | Every scheduled actor already has squad fields, but allocator redistributes a global role bag and only one squad per packet receives collective state | encounter runtime, spawn allocator, collective runtime | Preserve authored pack blueprints, register every normal pack, and admit a complete window atomically | 1.2, 2.1 |
| Gunner defense | Current allocator limits shooters but does not guarantee a shield actor | spawn allocator | Every Gunner pack replaces filler slots with one/two base Defenders according to Gunner count | 1.2 |
| Shared work and performance | Enemy store, update schedule, grid, and collective runtime are bounded; renderer currently allocates one batch per actor descriptor with a hard ceiling of 50 | performance policy/audit, renderer, performance scenarios | Extend the existing bounded pack runtime; use fifteen body textures and shared overlays; do not add per-pack Nodes or 45 actor batches | 2.1, 3.1, 5.2 |
| Trait ownership | Current elite traits are per actor and globally shared; requested traits are family-exclusive and some are pack-wide | elite catalog, user decisions | Replace the global elite catalog with one family-trait catalog and pack metadata; Coordinator traits affect its complete pack | 1.1, 2.2 |
| Trait behavior | Splitter, current mine, artillery, shield support, reflect, and death-stack prototypes contain reusable behavior seeds | specialist runtime and `VehicleRun` branches | Migrate seeds behind new family/trait terms; do not preserve their former actors | 2.2, 4.1 |
| Stage 3 fixed beam | `ordinary_fixed_beam_01` appears only as a Stage 3 boss-owned autonomous summon | boss patterns/runtime trace | Rename/reclassify it as `boss_pattern_fixed_beam_01`; it is not an ordinary family member and has no Defender requirement | 1.1, 4.1 |
| Remote branch | `origin/agent/simplify-ordinary-enemy-ai` at `bd9f72f7` is mechanically mergeable but draft/unstable and failed rendered evidence | merge-tree and branch diff recorded by prior plan revision | Do not merge; manually adapt current-objective targeting and blocked-route guidance only | 2.3 |
| Visual media | 45 approved staged PNG variants exist; renderer batch count is the total retained batch allocation | staged provenance, renderer snapshot contract, 50-batch validators | Promote fifteen base PNGs only; express traits with shared code-native cues; retain extra variants outside production | 3.1, 3.2 |
| Canonical documentation | Product spec still names rolling legacy roles, current elite modifiers, 48-unit shared visuals, and late teaching aliases | `docs/product/vehicle_game_spec.md`; `docs/design/VISUAL_SYSTEM.md` | Update both canonical documents in the migration commit before reports are regenerated | 4.2 |

Readiness statement:

- Every material product, architecture, data, visual, ownership, safety, and validation
  decision is closed.
- Godot 4.7.1 is available through `./tools/godot.ps1`; no dependency bootstrap is needed.
- External research is not repeated in this implementation turn because the active plan
  already records the relevant Godot, GDC, Riot, and local performance evidence, and the
  current code plus pinned engine are authoritative for implementation mechanics.
- Remaining unknowns are implementation-local and cannot change this contract.

## Tasks

### Phase 1: Canonical family data and authored packs

Goal: make fifteen family-tier actors and valid pack blueprints the only normal ordinary
spawn contract before changing live behavior.

Preconditions:

- Capture the pre-change focused validator results and renderer batch count from current
  `master`; do not interpret them as release performance.

Source owners: `scripts/enemies/vehicle_enemy_archetypes.gd`, new
`scripts/enemies/vehicle_enemy_family_trait_catalog.gd`,
`scripts/vehicle/stages/vehicle_combat_stages.gd`,
`scripts/encounters/vehicle_spawn_allocator.gd`,
`scripts/encounters/vehicle_encounter_runtime.gd`,
`scripts/enemies/vehicle_enemy_state.gd`

- [ ] **1.1** Fifteen family-tier definitions replace the legacy ordinary catalog.
  - Change: define family, tier, integer size percent, base combat role, stats, threat
    kind, and semantic asset ID for `ordinary_<family>_t1..t3`; add
    `boss_pattern_fixed_beam_01`; add family/trait scalar state; replace the global elite
    catalog with two allowed traits per family.
  - Accept: catalog validation reports exactly fifteen normal ordinary IDs, the
    100/125/150 ladder, two unique traits per family, no cross-family trait, explicit 48
    projectile target radius, and no legacy definition.
- [ ] **1.2** Stage packets contain validated semantic pack blueprints.
  - Change: author deterministic stage family/tier/trait rollout; preserve exact authored
    counts and 4-8 pack sizes; derive squad role arrays without allocator role-bag
    redistribution; attach family/tier/trait metadata to every spawn spec.
  - Accept: all twelve stage definitions preserve population and quota; every pack is
    valid; every Gunner pack contains the required Defender count; no pack exceeds the
    active-cap or threat-budget contract.
  - Guard: opening and reserve admission remain whole-window atomic and a failed geometry
    allocation emits no orphan actor.

Batch gate:

- `./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_twelve_cycle_catalog.gd`
- `./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_spawn_allocation.gd`

### Phase 2: Pack runtime and ten trait behaviors

Goal: make every pack share bounded coordination state and make all ten traits functional
without adding per-actor discovery or new unbounded collections.

Preconditions:

- Phase 1 acceptance checks pass.

Source owners: `scripts/encounters/vehicle_collective_tactic_catalog.gd`,
`scripts/encounters/vehicle_collective_tactic_runtime.gd`,
`scripts/enemies/vehicle_enemy_specialist_runtime.gd`,
`scripts/enemies/vehicle_enemy_movement_policy.gd`,
`scripts/enemies/vehicle_enemy_targeting_policy.gd`,
`scripts/combat/vehicle_projectile_state.gd`, `scripts/vehicle/vehicle_run.gd`

- [ ] **2.1** Every ordinary pack uses the existing bounded collective runtime.
  - Change: register all normal packs; store objective, formation, trait phase/timer, Blink
    receipt, and Pack Feed stacks once per pack; publish fixed scalar member state; keep the
    existing one-Execute/one-Gather global permissions and 32-pack bound.
  - Accept: 4-8 member packs remain deterministic; stale IDs are removed; pack state ends
    when empty; no actor or pack Node is created; debug snapshot exposes family, tier,
    trait, member count, and bounded trait state.
- [ ] **2.2** The ten family traits implement their locked counterplay.
  - Change: Splitter spawns bounded traitless T1 children; Frenzy applies bounded speed and
    cadence pressure; Double performs one warned second charge; Self-Destruct enters a
    kill-interruptible fuse then retires; Artillery substitutes the marked-impact attack;
    Slow applies one non-stacking player slow that refreshes; Bulwark periodically grows
    presentation and shields nearby same-pack members; Reflector has a normal shield and
    only reflects during a warned window; Blink warns then relocates the formation only to
    collision-safe positions; Pack Feed heals and strengthens surviving same-pack members
    with a cap, excludes summons/duplicates, and stops when the Coordinator leader dies.
  - Accept: focused trait fixtures prove timing, caps, exclusions, interruption, and
    collision-safe failure behavior; no removed trait remains reachable.
- [ ] **2.3** Pack anchors use the accepted remote-branch simplification.
  - Change: movement targets the current pack objective rather than a predicted movement
    destination; blocked direct approach may use the existing pursuit field; family attack
    standoff, formation slots, local separation, smoothing, and speed caps remain.
  - Accept: movement/targeting validators prove no movement prediction, no route request on
    a clear path, preserved attack prediction, and protected rear placement for Gunners.

Batch gate:

- `./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_collective_tactics.gd`
- `./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_enemy_family_traits.gd`
- `./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_enemy_movement_policy.gd`
- `./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_enemy_targeting_policy.gd`

### Phase 3: Production visuals and performance-safe presentation

Goal: show the five families, tiers, and active trait states with fifteen body textures and
shared retained cues.

Preconditions:

- Phase 2 acceptance checks pass and stable semantic IDs exist.

Source owners: `docs/design/visual-replacement-workbench/replacement-workbench.json`,
`docs/design/visual-replacement-workbench/to-be/assets/...`,
`art/visuals/production/gameplay/asset-manifest.json`,
`scripts/presentation/components/vehicle_actor_visual_catalog.gd`,
`scripts/presentation/vehicle_combat_renderer.gd`,
`scripts/vehicle/vehicle_stage_visual_profile.gd`

- [ ] **3.1** Promote exactly fifteen approved base PNGs through one new workbench unit.
  - Change: map staged `base` PNGs to exact 256x256 family-tier production targets, record
    hashes and authority evidence, add the boss-pattern beam move, and declare old ordinary
    assets as retirement targets after consumer migration.
  - Accept: exact workbench ledger and preview pass; manifest has fifteen ordinary family
    semantic IDs and one boss-pattern beam ID; no extra trait PNG is indexed.
- [ ] **3.2** Renderer consumes catalog asset IDs and integer tier scale.
  - Change: use actor-catalog `asset` rather than synthesized IDs; compute
    `visual_scale = size_percent / 100.0`; raise the shared T1 ordinary presentation radius
    to 56 while keeping projectile hit radius 48 and movement radius unchanged; add
    within-footprint trait marks and timing cues using existing retained overlay batches.
  - Accept: renderer snapshot stays at or below 50 batches; fifteen actor body batches are
    allocated; trait cues add no batch, node, raster effect, or collision owner; T1/T2/T3
    render at exact 100/125/150 ratios.

Batch gate:

- `./tools/design/build_visual_replacement_workbench.ps1 -Check`
- `./tools/validation/validate_visual_replacement_workbench.ps1`
- `./tools/validation/validate_cardborne_visual_authority.ps1`
- `./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_semantic_asset_provider.gd`
- `./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_combat_renderer.gd`

### Phase 4: Retire legacy identities and update canonical surfaces

Goal: remove the duplicate/unreachable system after all live consumers use the family
contract.

Preconditions:

- Phase 3 acceptance checks pass and the workbench ledger proves exact retirement targets.

Source owners: `scripts/progression/vehicle_guidebook_catalog.gd`,
`scripts/progression/vehicle_guidebook_stat_adapter.gd`,
`localization/vehicle_stage.csv`, boss add/summon owners, affected validators,
`docs/product/vehicle_game_spec.md`, `docs/design/VISUAL_SYSTEM.md`

- [ ] **4.1** Remove all legacy ordinary identity consumers and files.
  - Change: migrate boss adds to family-tier packs; reclassify fixed beam under the boss
    owner; replace Guidebook entries and localization with five families, three tiers, and
    ten traits; remove old archetype/elite entries, branches, fixtures, manifest records,
    PNGs, and tracked import files after `rg` proves no live consumer.
  - Accept: `rg` finds no legacy ordinary archetype ID outside archived reports, historical
    plans/evidence, and intentionally retained migration prose; runtime catalogs and
    production assets contain only the new ordinary identities.
- [ ] **4.2** Canonical specs describe the shipped family and visual contracts.
  - Change: replace legacy rolling-role/elite/teaching text in the product spec; record pack
    composition, traits, boss-owned fixed beam, tier scale, 56-unit T1 presentation
    baseline, code-native trait cues, and the unchanged gameplay radii/batch ceiling in the
    product and visual specs.
  - Accept: code, product spec, visual spec, Guidebook, and manifest use the same terms and
    values; reports remain derived views and are not silently regenerated in this task.

Batch gate:

- `./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_guidebook.gd`
- `./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_specialist_enemy_integration.gd`
- `./tools/godot.ps1 --headless --path . --script res://tools/validation/validate_vehicle_enemy_expansion.gd`

### Phase 5: Integration, performance boundary, and handoff

Goal: prove the coherent migration at the strongest proportionate evidence level and
record exact limitations.

Preconditions:

- Phases 1-4 pass and the implementation diff is substantially complete.

Source owners: project validation scripts, Web export preset, this execution contract

- [ ] **5.1** Run the complete focused ordinary-enemy integration set once.
  - Change: run import/parse, family/pack/trait/stage/Guidebook/semantic/renderer validators,
    then the twelve-cycle integration validator; fix only task-owned regressions.
  - Accept: every named focused check exits zero with no Godot parse/runtime error.
- [ ] **5.2** Validate the preserved performance contract without overstating it.
  - Change: run the existing performance workload-fingerprint validator and scenario
    validity checks; compare the renderer batch count with the pre-change focused baseline.
    Run native/Web release scenarios only if the environment is quiet and the active
    performance plan permits an eligible clean checkpoint.
  - Accept: workload/capacity/cadence/collision thresholds are unchanged, combat batches
    are `<=50`, and results use precise labels (`focused validator passed`, `scenario
    valid`, or exact native/Web release label). A contaminated or unavailable release run
    is recorded as unqualified, not passed or failed.
- [ ] **5.3** Audit and commit the completed migration.
  - Change: run the codebase quality audit, apply only small task-scoped corrections, mark
    this plan `done` with concise evidence, and commit only task-owned files with a body.
  - Accept: no unrelated untracked file is staged; plan status and checkboxes match actual
    evidence; `git status --short` shows only the three pre-existing unrelated untracked
    files or is cleaner.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | `./tools/godot.ps1 --headless --path . --script res://tools/validation/<phase-owner>.gd` | A phase-owned script/catalog changes | Relevant implementation input changes |
| Asset gate | Workbench build/check, visual-authority validator, semantic provider validator | Exact asset/workbench/manifest batch is complete | An asset, hash, target, manifest, or authority input changes |
| Phase gate | Commands listed under each phase | All phase tasks pass | A phase-owned input changes |
| Final focused gate | Import/parse plus the union of named family/pack/stage/Guidebook/renderer validators | All implementation phases pass | A final-gate input changes |
| Final performance boundary | Workload fingerprint and scenario-validity validators; eligible native/Web only in a quiet environment | Focused final gate passes | Runtime workload, checkpoint, instrumentation, or environment eligibility changes |

Validation rules:

- Run the narrowest check that proves the current task.
- Do not run tests solely because a report changed. This task changes runtime and production
  visuals, so only the named owner checks are authorized.
- Preserve a passing result until a relevant input changes. Rerun a failure only after a
  relevant correction or a new hypothesis.
- Keep visual promotion, gameplay migration, and performance claims in distinct commits or
  explicitly distinct evidence labels.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| Fifteen actor batches plus current retained batches exceed 50 | Stop promotion; keep approved files staged and use fewer runtime semantic textures through the locked three-assets-per-family model | Do not raise the threshold or add an atlas without user approval and render evidence |
| A complete Gunner pack cannot be placed | Delay the complete pack and retry at the existing bounded interval | Never spawn an orphan Gunner or expand geometry/capacity |
| Blink destination is invalid | Cancel that Blink cycle, keep the pack in place, and enter cooldown | Never clip, teleport into the player, or bypass collision |
| Pack runtime reaches 32 registered packs | Leave the new pack in base formation state and record the bounded rejection | Do not grow the collection during combat; replan only if normal validated workload reaches the bound |
| A legacy ID still has a live consumer | Keep its file/definition until that exact consumer migrates, then update this task's evidence | Do not delete first or retain a second player-facing authority |
| A verified material fact contradicts this contract | Stop the affected branch, update this same contract, and obtain required approval | Do not invent a new product, architecture, asset, or performance contract |

Implementation-local discoveries may be handled inside the locked contract when they do
not change scope, visible behavior, ownership, architecture, safety, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 1.
- Next task: 1.1 — fifteen family-tier definitions and the family-trait catalog.
- Last completed gate: Discovery Closure Gate.
- Update rule: after a checkpoint passes, record concise evidence, check the task, and
  advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check and named batch/final gate passes or is truthfully recorded
  as an explicitly allowed unqualified release layer.
- No placeholder or unresolved material decision remains.
- Canonical product/design documentation, Guidebook, semantic assets, and runtime use the
  same five-family vocabulary.
- Frontmatter status is `done`, all checkboxes reflect evidence, and the task-owned changes
  are committed.

Replan when:

- A material discovery invalidates the locked family, pack, visual, ownership, or
  performance contract.

Do not replan or stop for:

- Implementation-local mechanics already contained by this contract.
- A passing check whose relevant inputs have not changed.
- An unavailable quiet release-performance window; record that layer as unqualified and
  complete the behavior/asset migration if every required focused gate passes.
